#!/bin/bash

# ECR Deployment Script for ECS Node.js Application
# This script builds and pushes Docker image to AWS ECR

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration - Update these values as needed
AWS_REGION="ap-northeast-1"
ECR_REPOSITORY_NAME="tsaeki-test-ecr"
IMAGE_TAG="${1:-latest}"  # Use first argument or default to 'latest'
APP_DIR="src"

# Functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check if AWS CLI is installed
    if ! command -v aws &> /dev/null; then
        log_error "AWS CLI is not installed. Please install it first."
        exit 1
    fi
    
    # Check if Docker is installed
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed. Please install it first."
        exit 1
    fi
    
    # Check if Docker daemon is running
    if ! docker info &> /dev/null; then
        log_error "Docker daemon is not running. Please start Docker."
        exit 1
    fi
    
    # Check if src directory exists
    if [ ! -d "$APP_DIR" ]; then
        log_error "Application directory '$APP_DIR' not found."
        exit 1
    fi
    
    # Check if Dockerfile exists
    if [ ! -f "$APP_DIR/Dockerfile" ]; then
        log_error "Dockerfile not found in '$APP_DIR' directory."
        exit 1
    fi
    
    log_success "All prerequisites met."
}

# Get AWS account ID
get_aws_account_id() {
    log_info "Getting AWS account ID..."
    AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    if [ -z "$AWS_ACCOUNT_ID" ]; then
        log_error "Failed to get AWS account ID. Check your AWS credentials."
        exit 1
    fi
    log_success "AWS Account ID: $AWS_ACCOUNT_ID"
}

# Authenticate Docker to ECR
authenticate_docker() {
    log_info "Authenticating Docker to ECR..."
    aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com
    if [ $? -eq 0 ]; then
        log_success "Docker authenticated to ECR."
    else
        log_error "Failed to authenticate Docker to ECR."
        exit 1
    fi
}

# Build Docker image
build_image() {
    log_info "Building Docker image..."
    cd $APP_DIR
    
    # Build the Docker image
    docker build -t $ECR_REPOSITORY_NAME:$IMAGE_TAG .
    
    if [ $? -eq 0 ]; then
        log_success "Docker image built successfully: $ECR_REPOSITORY_NAME:$IMAGE_TAG"
    else
        log_error "Failed to build Docker image."
        exit 1
    fi
    
    cd ..
}

# Tag image for ECR
tag_image() {
    log_info "Tagging image for ECR..."
    ECR_URI="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPOSITORY_NAME:$IMAGE_TAG"
    
    docker tag $ECR_REPOSITORY_NAME:$IMAGE_TAG $ECR_URI
    
    if [ $? -eq 0 ]; then
        log_success "Image tagged: $ECR_URI"
    else
        log_error "Failed to tag image."
        exit 1
    fi
}

# Push image to ECR
push_image() {
    log_info "Pushing image to ECR..."
    
    docker push $ECR_URI
    
    if [ $? -eq 0 ]; then
        log_success "Image pushed successfully to ECR: $ECR_URI"
    else
        log_error "Failed to push image to ECR."
        exit 1
    fi
}

# Clean up local images (optional)
cleanup() {
    log_info "Cleaning up local images..."
    
    read -p "Do you want to remove local Docker images? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        docker rmi $ECR_REPOSITORY_NAME:$IMAGE_TAG $ECR_URI 2>/dev/null || true
        log_success "Local images cleaned up."
    else
        log_info "Skipping cleanup."
    fi
}

# Show image information
show_image_info() {
    log_success "=== Deployment Complete ==="
    echo
    log_info "ECR Repository URI: $ECR_URI"
    log_info "Image Tag: $IMAGE_TAG"
    log_info "Region: $AWS_REGION"
    echo
    log_info "You can now deploy this image to ECS using:"
    log_info "  terraform apply"
    echo
    log_info "Or update existing ECS service with the new image tag."
}

# Main execution
main() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}    ECR Deployment Script${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo
    
    log_info "Starting deployment process..."
    log_info "Image tag: $IMAGE_TAG"
    log_info "ECR Repository: $ECR_REPOSITORY_NAME"
    log_info "AWS Region: $AWS_REGION"
    echo
    
    check_prerequisites
    get_aws_account_id
    authenticate_docker
    build_image
    tag_image
    push_image
    cleanup
    show_image_info
    
    log_success "Deployment completed successfully!"
}

# Script usage
show_usage() {
    echo "Usage: $0 [IMAGE_TAG]"
    echo
    echo "Arguments:"
    echo "  IMAGE_TAG    Docker image tag (default: latest)"
    echo
    echo "Examples:"
    echo "  $0              # Deploy with 'latest' tag"
    echo "  $0 v1.0.0       # Deploy with 'v1.0.0' tag"
    echo "  $0 \$(date +%Y%m%d-%H%M%S)  # Deploy with timestamp tag"
}

# Handle help flag
if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    show_usage
    exit 0
fi

# Run main function
main