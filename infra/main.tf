# ---- ECR repository (holds the container image built & pushed by deploy.sh / CI) ----
resource "aws_ecr_repository" "containerized_lambda_ecr_repository" {
  name                 = var.function_name
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }
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
  image_uri     = var.image_uri
  architectures = [var.architecture]
  memory_size   = var.memory_size
  timeout       = var.timeout

  depends_on = [aws_iam_role_policy_attachment.basic]
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

# NOTE: This does NOT affect Function URL access — the URL auth layer only checks
# lambda:InvokeFunctionUrl (granted above). Added for completeness / experimentation.
resource "aws_lambda_permission" "public_invoke" {
  statement_id  = "AllowPublicInvokeFunction"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.containerized_lambda_function.function_name
  principal     = "*"
}
