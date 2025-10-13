#!/bin/bash
set -e

AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
AWS_REGION="ap-northeast-1"

REPO_NAME="tsaeki-dev-activemq"
ECR_REPO="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${REPO_NAME}"

echo "Building ActiveMQ image..."
cd activemq
docker build -t ${REPO_NAME}:latest .
docker tag ${REPO_NAME}:latest ${ECR_REPO}:latest

echo "Logging in to ECR..."
aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com

echo "Pushing image to ECR..."
docker push ${ECR_REPO}:latest

echo "ActiveMQ image pushed successfully to ${ECR_REPO}:latest"
