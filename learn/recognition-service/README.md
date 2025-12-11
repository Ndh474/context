# Recognition Service Documentation

## Purpose

Documentation chi tiết cho Python Face Recognition Service của FUACS system. Được viết cho AI/LLM đọc để có kiến thức ngay lập tức khi bắt đầu session mới.

## Quick Reference

- **Service**: Python FastAPI microservice
- **Port**: 8000
- **Auth**: X-API-Key header
- **Model**: InsightFace buffalo_l (512-dim embeddings)
- **Communication**: HTTP callbacks to Java backend

## Documentation Files

### Core Understanding

1. **[00-overview.md](./00-overview.md)** - Service identity, tech stack, directory structure
2. **[01-api-endpoints.md](./01-api-endpoints.md)** - All API endpoints với request/response formats
3. **[02-recognition-session-flow.md](./02-recognition-session-flow.md)** - Core workflow: start session → process → callbacks → stop

### Technical Deep Dive

4. **[03-face-recognition-engine.md](./03-face-recognition-engine.md)** - InsightFace model, face detection, matching, evidence handling
5. **[04-rtsp-camera-handling.md](./04-rtsp-camera-handling.md)** - RTSP streams, OpenCV, reconnection logic
6. **[05-callback-integration.md](./05-callback-integration.md)** - Java backend callbacks, retry logic, auto-stop

### Configuration & Models

7. **[06-configuration.md](./06-configuration.md)** - Environment variables, settings, logging
8. **[07-data-models.md](./07-data-models.md)** - Pydantic DTOs, request/response schemas
9. **[08-singleton-services.md](./08-singleton-services.md)** - Service instances, lifecycle, thread safety

### Quality & Operations

10. **[09-error-handling-resilience.md](./09-error-handling-resilience.md)** - Error handling, camera failures, auto-recovery
11. **[10-testing.md](./10-testing.md)** - pytest, test patterns, fixtures
12. **[11-common-pitfalls.md](./11-common-pitfalls.md)** - Common mistakes và best practices
13. **[12-deployment.md](./12-deployment.md)** - Docker, production config, CI/CD

## Key Concepts

### Session Lifecycle

```
Java Backend                    Python Service
     |                                |
     |-- POST /process-session ------>|
     |                                |-- Test cameras
     |                                |-- Start background tasks
     |<-- Response -------------------|
     |                                |
     |                                |== Background Loop ==
     |<-- Callback (recognition) -----|   - Capture frame
     |<-- Callback (recognition) -----|   - Detect faces
     |                                |   - Match embeddings
     |-- POST /stop-session --------->|   - Send callbacks
     |<-- Response (statistics) ------|
```

### Deduplication

Mỗi student chỉ recognized 1 lần per session (tracked in-memory set).

### Callback Types

- `REGULAR` → Điểm danh lecture → `regularImageUrl`
- `EXAM` → Điểm danh thi → `examImageUrl`

### Scan Modes

- `INITIAL` → First scan
- `RESCAN` → Scan lại cho students chưa có mặt

## Critical Configuration

```bash
# Must set correctly for production
PUBLIC_HOST=actual-server-ip-or-domain
API_KEY=strong-unique-key
JAVA_BACKEND_URL=http://backend:8080
DEFAULT_SIMILARITY_THRESHOLD=0.55
```

## Common Commands

```bash
# Development
poetry run uvicorn src.recognition_service.main:app --reload --port 8000

# Tests
poetry run pytest

# Format
poetry run black src/
poetry run ruff check src/
```

## File Locations

- **Entry point**: `src/recognition_service/main.py`
- **Config**: `src/recognition_service/core/config.py`
- **Session logic**: `src/recognition_service/services/recognition_service.py`
- **Face detection**: `src/recognition_service/services/face_recognizer.py`
- **Callbacks**: `src/recognition_service/services/callback_service.py`
- **Evidence**: `./uploads/evidence/{slot_id}/`

## Integration Points

### Java Backend → Python

- `POST /api/v1/recognition/process-session` - Start session
- `POST /api/v1/recognition/stop-session` - Stop session
- `POST /api/v1/embeddings/generate` - Generate embedding

### Python → Java Backend

- `POST {callbackUrl}` - Recognition results
- `POST {callbackUrl.replace('/recognition-result', '/session-status')}` - Session status

## Timezone

**CRITICAL**: Service uses `Asia/Ho_Chi_Minh` timezone internally, UTC for Java callbacks.

```python
# Internal
vn_tz = pytz.timezone('Asia/Ho_Chi_Minh')
timestamp = datetime.now(vn_tz)

# For Java callbacks
from recognition_service.utils import get_utc_timestamp_for_java
timestamp = get_utc_timestamp_for_java()  # "2024-11-06T10:30:00Z"
```
