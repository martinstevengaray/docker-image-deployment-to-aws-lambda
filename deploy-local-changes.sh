#!/usr/bin/env bash
# Fast dev loop: build the CURRENT working tree (committed or not), push a mutable `dev`
# tag, and force the already-deployed Lambda to pull it — no commit, no Terraform.
#
# Use ./deploy.sh for real, committed/release deploys. This script intentionally BYPASSES
# Terraform, so it creates drift: the Lambda temporarily runs an image Terraform doesn't
# know about. The next ./deploy.sh reconciles it back to the committed release image.
#
# Prerequisite: the Lambda must already exist — run ./deploy.sh at least once first.
set -euo pipefail

cd "$(dirname "$0")"
source ./deploy-env.sh

TAG="dev"   # mutable, deliberately overwritten every run (for shared accounts use "${USER}-dev")
IMAGE_URI="${REGISTRY}/${REPO}:${TAG}"

echo "Deploying working tree to: ${IMAGE_URI}"

# ---- build & push (overwrites the mutable :dev tag; requires ECR image_tag_mutability = MUTABLE) ----
aws ecr get-login-password --region "$REGION" \
  | docker login --username AWS --password-stdin "$REGISTRY"
docker build --platform linux/arm64 -t "$IMAGE_URI" .
docker push "$IMAGE_URI"

# ---- force the Lambda to re-pull: update-function-code re-resolves :dev to the new digest ----
aws lambda update-function-code \
  --function-name "$REPO" \
  --image-uri "$IMAGE_URI" \
  --region "$REGION" >/dev/null

# ---- wait until the new code is live ----
aws lambda wait function-updated --function-name "$REPO" --region "$REGION"

echo "Done — the Lambda is now running your working-tree image."
