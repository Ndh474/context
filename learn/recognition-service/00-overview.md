# Recognition Service - Overview

## Service Identity

- **Name**: FUACS Face Recognition Service
- **Language**: Python 3.10+
- **Framework**: FastAPI 0.110.0 (async)
- **Package Manager**: Poetry
- **Port**: 8000 (default)

## Purpose

Python microservice cung cấp face recognition capabilities cho FUACS system:
1. **Face Recognition Sessions**: Xử lý video streams từ IP cameras, detect và match faces với student embeddings
2. **Embedding Generation**: Tạo 512-dim face embeddings từ photos cho identity submission

## Tech Stack

- **FastAPI**: Async web framework
- **InsightFace**: Face detection & recognition (buffalo_l model, 512-dim embeddings)
- **OpenCV**: RTSP stream processing, image manipulation
- **ONNX Runtime**: ML inference (auto-detect GPU/CPU)
- **aiohttp**: Async HTTP client cho callbacks
- **Pydantic**: Request/response validation

## Directory Structure

```
recognition-service/
├── src/recognition_service/
│   ├── main.py                 # FastAPI app entry point
│   ├── api/v1/                 # Route handlers
│   ├── services/               # Business logic (singletons)
│   ├── models/                 # Pydantic DTOs
│   ├── core/                   # Config, security, hardware
│   └── utils/                  # Utilities
├── tests/                      # pytest tests
├── uploads/evidence/           # Face evidence images
├── pyproject.toml              # Poetry dependencies
└── .env                        # Environment config
```

## Key Files

- `main.py` → FastAPI app, lifespan manager, CORS, routers
- `core/config.py` → Pydantic Settings từ .env
- `core/security.py` → X-API-Key authentication
- `core/hardware.py` → GPU/CPU auto-detection
- `services/recognition_service.py` → Session orchestration
- `services/face_recognizer.py` → Face detection & matching

## Inter-Service Communication

- **Java Backend → Python**: HTTP POST với X-API-Key header
- **Python → Java Backend**: HTTP callbacks với recognition results
- **Evidence Images**: Served via FastAPI StaticFiles, Java downloads via HTTP GET

## Build Commands

```bash
# Install dependencies
poetry install

# Development (with auto-reload)
poetry run uvicorn src.recognition_service.main:app --reload --port 8000

# Production
poetry run uvicorn src.recognition_service.main:app --host 0.0.0.0 --port 8000

# Tests
poetry run pytest

# Format & Lint
poetry run black src/
poetry run ruff check src/
```
