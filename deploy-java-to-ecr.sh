#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
JAVA_APP_DIR="$SCRIPT_DIR/java-app"

AWS_REGION="ap-northeast-1"
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_REPOSITORY_NAME="tsaeki-java-ecr"
ECR_REPOSITORY_URL="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPOSITORY_NAME}"

IMAGE_TAG="${1:-latest}"

echo "=========================================="
echo "Java Application Docker Image Deployment"
echo "=========================================="
echo "AWS Region: $AWS_REGION"
echo "AWS Account ID: $AWS_ACCOUNT_ID"
echo "ECR Repository: $ECR_REPOSITORY_NAME"
echo "Image Tag: $IMAGE_TAG"
echo "=========================================="

echo "Checking prerequisites..."
command -v aws >/dev/null 2>&1 || { echo "AWS CLI is required but not installed. Aborting." >&2; exit 1; }
command -v docker >/dev/null 2>&1 || { echo "Docker is required but not installed. Aborting." >&2; exit 1; }

echo "Authenticating Docker to ECR..."
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REPOSITORY_URL

echo "Building Docker image..."
cd "$JAVA_APP_DIR"
docker build -t ${ECR_REPOSITORY_NAME}:${IMAGE_TAG} .

echo "Tagging Docker image..."
docker tag ${ECR_REPOSITORY_NAME}:${IMAGE_TAG} ${ECR_REPOSITORY_URL}:${IMAGE_TAG}

echo "Pushing Docker image to ECR..."
docker push ${ECR_REPOSITORY_URL}:${IMAGE_TAG}

echo "=========================================="
echo "Deployment completed successfully!"
echo "Image: ${ECR_REPOSITORY_URL}:${IMAGE_TAG}"
echo "=========================================="

read -p "Do you want to clean up local Docker images? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Cleaning up local images..."
    docker rmi ${ECR_REPOSITORY_NAME}:${IMAGE_TAG} || true
    docker rmi ${ECR_REPOSITORY_URL}:${IMAGE_TAG} || true
    echo "Cleanup completed."
fi
