#!/usr/bin/env bash
# Build the container image and deploy it to AWS Lambda.
#
# This is the local stand-in for a CI pipeline: it owns building & pushing the image
# (Terraform no longer does that), then hands Terraform the resulting image URI as a variable.
# Extra args are forwarded to the final `terraform apply`, e.g. ./deploy.sh -auto-approve
set -euo pipefail

cd "$(dirname "$0")"

# ---- image coordinates (shared with dev.sh) ----
source ./deploy-env.sh

VERSION="$(./gradlew -q printVersion)"   # app version (source of truth: build.gradle)
GIT_SHA="$(git rev-parse --short HEAD)"  # unique per commit => the Lambda actually updates
TAG="${VERSION}-${GIT_SHA}"
IMAGE_URI="${REGISTRY}/${REPO}:${TAG}"

echo "Deploying image: ${IMAGE_URI}"

# ---- 0. initialize Terraform (idempotent; makes fresh clones / CI runners work) ----
terraform -chdir=infra init -input=false

# ---- 1. ensure the ECR repo exists (still Terraform-managed) ----
terraform -chdir=infra apply \
  -target=aws_ecr_repository.containerized_lambda_ecr_repository \
  -var="region=${REGION}" -var="function_name=${REPO}" -var="image_uri=${IMAGE_URI}" -auto-approve

# ---- 2. build & push the image ----
aws ecr get-login-password --region "$REGION" \
  | docker login --username AWS --password-stdin "$REGISTRY"
docker build --platform linux/arm64 -t "$IMAGE_URI" .
docker push "$IMAGE_URI"

# ---- 3. apply the rest, pointing the Lambda at the pushed image ----
terraform -chdir=infra apply -var="region=${REGION}" -var="function_name=${REPO}" -var="image_uri=${IMAGE_URI}" "$@"
