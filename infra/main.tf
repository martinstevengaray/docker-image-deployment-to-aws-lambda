data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  project_root  = "${path.module}/.."
  registry      = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com"
  docker_platform = var.architecture == "arm64" ? "linux/arm64" : "linux/amd64"

  # Hash of everything baked into the image so we rebuild/push (and update the Lambda)
  # whenever the handler, build, or Dockerfile changes.
  source_files = setunion(
    fileset(local.project_root, "src/**"),
    toset(["Dockerfile", "build.gradle", "settings.gradle"]),
  )
  source_hash = substr(sha1(join("", [for f in local.source_files : filesha256("${local.project_root}/${f}")])), 0, 12)
  image_uri   = "${aws_ecr_repository.containerized_lambda_ecr_repository.repository_url}:${local.source_hash}"
}

resource "aws_ecr_repository" "containerized_lambda_ecr_repository" {
  name                 = var.function_name
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }
}

# Build the image (multi-stage Dockerfile) and push it to ECR. Re-runs when source_hash changes.
resource "null_resource" "build_push" {
  triggers = {
    source_hash = local.source_hash
    image_uri   = local.image_uri
  }

  provisioner "local-exec" {
    working_dir = local.project_root
    interpreter = ["/bin/bash", "-c"]
    command     = <<-EOT
      set -euo pipefail
      aws ecr get-login-password --region ${data.aws_region.current.name} \
        | docker login --username AWS --password-stdin ${local.registry}
      docker build --platform ${local.docker_platform} -t ${local.image_uri} .
      docker push ${local.image_uri}
    EOT
  }

  depends_on = [aws_ecr_repository.containerized_lambda_ecr_repository]
}

# ---- IAM execution role ----
data "aws_iam_policy_document" "assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda" {
  name               = "${var.function_name}-role"
  assume_role_policy = data.aws_iam_policy_document.assume.json
}

resource "aws_iam_role_policy_attachment" "basic" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# ---- Lambda (container image) ----
resource "aws_lambda_function" "containerized_lambda_function" {
  function_name = var.function_name
  role          = aws_iam_role.lambda.arn
  package_type  = "Image"
  image_uri     = local.image_uri
  architectures = [var.architecture]
  memory_size   = var.memory_size
  timeout       = var.timeout

  depends_on = [
    null_resource.build_push,
    aws_iam_role_policy_attachment.basic,
  ]
}

# ---- Public Function URL ----
resource "aws_lambda_function_url" "containerized_lambda_function_url" {
  function_name      = aws_lambda_function.containerized_lambda_function.function_name
  authorization_type = "NONE"
}

resource "aws_lambda_permission" "public_url" {
  statement_id           = "FunctionURLAllowPublicAccess"
  action                 = "lambda:InvokeFunctionUrl"
  function_name          = aws_lambda_function.containerized_lambda_function.function_name
  principal              = "*"
  function_url_auth_type = "NONE"
}
