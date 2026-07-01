#!/usr/bin/env bash
# Shared image coordinates for deploy.sh and dev-deploy.sh. This file is SOURCED, not run.
# Single source of truth for the region and the repo/function name.
REGION="us-west-2"
REPO="containerized-lambda"
ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
REGISTRY="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"
