# ECS Node.js Application

Simple Node.js application for ECS deployment with Express.js framework.

## Prerequisites

- Node.js 20.x or later
- Docker (for containerized testing)

## Local Development

### 1. Install Dependencies

```bash
cd src
npm install
```

### 2. Run Application

```bash
# Development mode with nodemon (auto-restart)
npm run dev

# Production mode
npm start
```

The application will start on http://localhost:3000

### 3. Test Endpoints

Open your browser or use curl to test the endpoints:

```bash
# Root endpoint - returns 200
curl http://localhost:3000/

# Health check endpoint - returns 200
curl http://localhost:3000/health

# Error endpoint - returns 500
curl http://localhost:3000/500
```

## Docker Testing

### 1. Build Docker Image

```bash
cd src
docker build -t ecs-node-app .
```

### 2. Run Container

```bash
docker run -p 3000:3000 ecs-node-app
```

### 3. Test Container

```bash
# Test all endpoints
curl http://localhost:3000/
curl http://localhost:3000/health
curl http://localhost:3000/500
```

### 4. Stop Container

```bash
# Find container ID
docker ps

# Stop container
docker stop <container-id>
```

## API Endpoints

| Endpoint | Method | Status | Description |
|----------|--------|--------|-------------|
| `/` | GET | 200 | Root endpoint |
| `/health` | GET | 200 | Health check for ECS |
| `/500` | GET | 500 | Error endpoint |

## Environment Variables

- `PORT`: Server port (default: 3000)
- `NODE_ENV`: Environment mode (default: development)

## ECR Deployment

### Deploy to ECR

Use the deployment script to build and push to ECR:

```bash
# Deploy with latest tag
./deploy-to-ecr.sh

# Deploy with specific tag
./deploy-to-ecr.sh v1.0.0

# Deploy with timestamp tag
./deploy-to-ecr.sh $(date +%Y%m%d-%H%M%S)
```

The script will:
1. Check prerequisites (AWS CLI, Docker)
2. Authenticate Docker to ECR
3. Build Docker image
4. Tag and push to ECR
5. Clean up local images (optional)

### Prerequisites for ECR Deployment

- AWS CLI configured with appropriate permissions
- Docker installed and running
- ECR repository created (via Terraform)

## ECS Deployment

This application is designed to run on AWS ECS with:
- Health checks on `/health` endpoint
- Graceful shutdown handling
- Container logging to CloudWatch
- ALB integration on port 3000

After ECR deployment, deploy to ECS:

```bash
terraform apply
```