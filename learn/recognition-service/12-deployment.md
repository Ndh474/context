# Recognition Service - Deployment

## Docker Deployment

### Dockerfile (GPU)

**File**: `Dockerfile`

```dockerfile
FROM nvidia/cuda:11.8-cudnn8-runtime-ubuntu22.04

# Install Python
RUN apt-get update && apt-get install -y \
    python3.10 \
    python3-pip \
    libgl1-mesa-glx \
    libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

# Install Poetry
RUN pip install poetry

WORKDIR /app

# Copy dependency files
COPY pyproject.toml poetry.lock ./

# Install dependencies
RUN poetry config virtualenvs.create false \
    && poetry install --no-dev --no-interaction --no-ansi

# Copy source code
COPY src/ ./src/

# Create directories
RUN mkdir -p uploads/evidence temp

# Expose port
EXPOSE 8000

# Run
CMD ["uvicorn", "src.recognition_service.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

### Dockerfile (CPU)

**File**: `Dockerfile.cpu`

```dockerfile
FROM python:3.10-slim

# Install system dependencies
RUN apt-get update && apt-get install -y \
    libgl1-mesa-glx \
    libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

# Install Poetry
RUN pip install poetry

WORKDIR /app

# Copy dependency files
COPY pyproject.toml poetry.lock ./

# Install dependencies (CPU version)
RUN poetry config virtualenvs.create false \
    && poetry install --no-dev --no-interaction --no-ansi

# Copy source code
COPY src/ ./src/

# Create directories
RUN mkdir -p uploads/evidence temp

EXPOSE 8000

CMD ["uvicorn", "src.recognition_service.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

### Docker Build

```bash
# GPU version
docker build -t fuacs-recognition:gpu .

# CPU version
docker build -f Dockerfile.cpu -t fuacs-recognition:cpu .
```

### Docker Run

```bash
# GPU version (requires nvidia-docker)
docker run -d \
    --name recognition-service \
    --gpus all \
    -p 8000:8000 \
    -v $(pwd)/uploads:/app/uploads \
    -v $(pwd)/.env:/app/.env \
    fuacs-recognition:gpu

# CPU version
docker run -d \
    --name recognition-service \
    -p 8000:8000 \
    -v $(pwd)/uploads:/app/uploads \
    -v $(pwd)/.env:/app/.env \
    fuacs-recognition:cpu
```

---

## Docker Compose

```yaml
version: '3.8'

services:
  recognition-service:
    build:
      context: ./recognition-service
      dockerfile: Dockerfile
    ports:
      - "8000:8000"
    volumes:
      - ./recognition-service/uploads:/app/uploads
      - ./recognition-service/.env:/app/.env
    environment:
      - JAVA_BACKEND_URL=http://backend:8080
      - PUBLIC_HOST=recognition-service
    networks:
      - fuacs-network
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: 1
              capabilities: [gpu]

networks:
  fuacs-network:
    driver: bridge
```

---

## Environment Configuration

### Production .env

```bash
# Service
SERVICE_NAME=FUACS Face Recognition Service
SERVICE_VERSION=1.0.0

# Security - USE STRONG KEY!
API_KEY=your-secure-api-key-here

# Java Backend
JAVA_BACKEND_URL=http://backend:8080

# Server
HOST=0.0.0.0
PORT=8000
PUBLIC_HOST=recognition.fuacs.example.com  # Or server IP
LOG_LEVEL=INFO

# Recognition
DEFAULT_SIMILARITY_THRESHOLD=0.55
CALLBACK_TIMEOUT=30
CALLBACK_RETRY_ATTEMPTS=3

# Embedding
EMBEDDING_QUALITY_THRESHOLD=0.50
```

### Key Production Settings

1. **PUBLIC_HOST**: Set to actual server IP/domain (not localhost)
2. **API_KEY**: Use strong, unique key
3. **LOG_LEVEL**: INFO or WARNING (not DEBUG)
4. **JAVA_BACKEND_URL**: Internal Docker network URL or actual backend URL

---

## Volume Mounts

### Required Volumes

```bash
# Evidence images (persistent)
-v /data/fuacs/evidence:/app/uploads/evidence

# Temp files (can be tmpfs)
-v /tmp/fuacs-temp:/app/temp

# InsightFace models (cache)
-v /data/fuacs/models:/root/.insightface/models
```

### Volume Permissions

```bash
# Ensure write permissions
chmod -R 777 /data/fuacs/evidence
chmod -R 777 /tmp/fuacs-temp
```

---

## Health Checks

### Docker Health Check

```dockerfile
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8000/api/v1/health || exit 1
```

### Kubernetes Probes

```yaml
livenessProbe:
  httpGet:
    path: /api/v1/health
    port: 8000
  initialDelaySeconds: 60
  periodSeconds: 30
  timeoutSeconds: 10

readinessProbe:
  httpGet:
    path: /api/v1/health
    port: 8000
  initialDelaySeconds: 30
  periodSeconds: 10
  timeoutSeconds: 5
```

---

## Resource Requirements

### GPU Deployment

- **GPU**: NVIDIA GPU with CUDA support
- **VRAM**: 2GB+ (for buffalo_l model)
- **RAM**: 4GB+
- **CPU**: 2+ cores

### CPU Deployment

- **RAM**: 4GB+ (model loaded in RAM)
- **CPU**: 4+ cores (inference is CPU-intensive)

### Disk Space

- **Model**: ~600MB (downloaded on first run)
- **Evidence**: Varies (depends on sessions)
- **Logs**: Configure rotation

---

## Scaling Considerations

### Single Instance Limitations

- In-memory session state (lost on restart)
- Not suitable for horizontal scaling
- Single point of failure

### Production Recommendations

1. **Session Persistence**: Consider Redis for session state
2. **Load Balancing**: Sticky sessions if multiple instances
3. **Evidence Storage**: Use shared storage (NFS, S3)
4. **Model Caching**: Pre-download models in Docker image

---

## Monitoring

### Metrics Endpoint

```
GET /api/v1/metrics
```

### Key Metrics

- Active sessions count
- Recognition count per session
- Callback success/failure rate
- Camera connection status

### Logging

```bash
# View logs
docker logs -f recognition-service

# Log rotation (Docker)
docker run ... --log-opt max-size=100m --log-opt max-file=3 ...
```

---

## Security

### Network Security

- Run in private network (not exposed to internet)
- Use reverse proxy (nginx) for SSL termination
- Firewall: Only allow backend to access

### API Security

- Strong API key
- Rate limiting (via reverse proxy)
- Input validation (Pydantic)

### Evidence Security

- Evidence images contain faces
- Restrict access to uploads directory
- Consider encryption at rest

---

## Troubleshooting

### Model Download Fails

```bash
# Pre-download model
docker exec -it recognition-service python -c "
from insightface.app import FaceAnalysis
app = FaceAnalysis(name='buffalo_l')
app.prepare(ctx_id=-1)
"
```

### GPU Not Detected

```bash
# Check NVIDIA driver
nvidia-smi

# Check Docker GPU access
docker run --gpus all nvidia/cuda:11.8-base nvidia-smi
```

### Camera Connection Issues

```bash
# Test RTSP from container
docker exec -it recognition-service python -c "
import cv2
cap = cv2.VideoCapture('rtsp://...')
print('Connected:', cap.isOpened())
cap.release()
"
```

### High Memory Usage

- InsightFace model: ~600MB (normal)
- Check for memory leaks in sessions
- Monitor with `docker stats`

---

## CI/CD Pipeline

### GitLab CI Example

**File**: `.gitlab-ci.yml`

```yaml
stages:
  - test
  - build
  - deploy

test:
  stage: test
  image: python:3.10
  script:
    - pip install poetry
    - poetry install
    - poetry run pytest
  only:
    - merge_requests
    - develop

build:
  stage: build
  image: docker:latest
  services:
    - docker:dind
  script:
    - docker build -t $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA .
    - docker push $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA
  only:
    - develop
    - main

deploy:
  stage: deploy
  script:
    - ssh $DEPLOY_HOST "docker pull $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA"
    - ssh $DEPLOY_HOST "docker-compose up -d"
  only:
    - main
  environment:
    name: production
```
