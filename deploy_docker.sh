#!/bin/bash

# Set strict mode for script execution to catch errors and undefined variables
set -euo pipefail

# Fetch and print environment variables securely without exposing them in logs
echo "Fetching environment variables..."
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
AWS_REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/region)
ECR_URI="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
REPO_NAME="my-fastapi-app"

# Normalize the repository name to lowercase
REPO_NAME=$(echo $REPO_NAME | awk '{print tolower($0)}')

# Secure login to Amazon ECR without exposing sensitive info
echo "Logging into Amazon ECR..."
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_URI > /dev/null

# Ensure no other process is using port 80
echo "Ensuring port 80 is available..."
if sudo lsof -i :80; then
    echo "Port 80 is busy, attempting to free it..."
    sudo lsof -t -i :80 | xargs sudo kill -9
else
    echo "Port 80 is free."
fi

# Stop and remove any existing container safely
echo "Ensuring no previous containers are running..."
docker stop $REPO_NAME || true
docker rm $REPO_NAME || true

# Pull the latest Docker image securely
echo "Pulling the latest Docker image..."
docker pull $ECR_URI/$REPO_NAME:latest > /dev/null

# Run the new Docker container
echo "Running the new Docker container on port 80..."
docker run -d --name $REPO_NAME -p 80:8000 $ECR_URI/$REPO_NAME:latest > /dev/null

echo "Deployment script completed successfully."
