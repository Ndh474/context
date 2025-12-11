# Recognition Service - Configuration

## Environment Variables

**File**: `core/config.py`

Configuration loaded từ `.env` file via Pydantic Settings.

### Service Configuration

```bash
SERVICE_NAME=FUACS Face Recognition Service
SERVICE_VERSION=1.0.0
```

### Security

```bash
# API key for authentication (shared with Java backend)
API_KEY=python-service-secret-key-12345
```

### Java Backend Integration

```bash
# Java backend URL for callbacks
JAVA_BACKEND_URL=http://localhost:8080
```

### InsightFace Model

```bash
# Model name (buffalo_l recommended)
MODEL_NAME=buffalo_l

# Local path to store models
MODEL_PATH=./src/recognition_service/models/insightface
```

### Server Configuration

```bash
# Bind address (0.0.0.0 = all interfaces)
HOST=0.0.0.0

# Server port
PORT=8000

# Public hostname for URL generation (evidence images)
# Use 'localhost' for dev, server IP/domain for production
PUBLIC_HOST=localhost

# Logging level: DEBUG, INFO, WARNING, ERROR
LOG_LEVEL=INFO
```

### Session Configuration

```bash
# Maximum concurrent recognition sessions
MAX_CONCURRENT_SESSIONS=10
```

### Recognition Configuration

```bash
# Default face matching threshold (0.0-1.0)
# Lower = more permissive, Higher = more strict
DEFAULT_SIMILARITY_THRESHOLD=0.55

# Maximum seconds between face scans
MAX_SCAN_INTERVAL=60

# Days to keep evidence images
EVIDENCE_RETENTION_DAYS=30

# Callback timeout in seconds
CALLBACK_TIMEOUT=30

# Number of callback retry attempts
CALLBACK_RETRY_ATTEMPTS=3
```

### Embedding Configuration

```bash
# Photo-video similarity threshold (for validation)
EMBEDDING_VALIDATION_THRESHOLD=0.90

# Minimum acceptable embedding quality
EMBEDDING_QUALITY_THRESHOLD=0.50

# Maximum video upload size in MB
MAX_VIDEO_SIZE_MB=50

# Temporary directory for file processing
TEMP_DIR=./temp

# Seconds between frames (for embedding generation)
VIDEO_SAMPLE_INTERVAL=0.5

# Seconds between frames (for validation)
VALIDATION_SAMPLE_INTERVAL=1.0
```

## Settings Class

```python
from pydantic_settings import BaseSettings
from functools import lru_cache

class Settings(BaseSettings):
    # Service Information
    SERVICE_NAME: str = "FUACS Face Recognition Service"
    SERVICE_VERSION: str = "1.0.0"
    
    # Security
    API_KEY: str = "python-service-secret-key-12345"
    
    # Java Backend
    JAVA_BACKEND_URL: str = "http://localhost:8080"
    
    # InsightFace
    MODEL_NAME: str = "buffalo_l"
    MODEL_PATH: str = "./src/recognition_service/models/insightface"
    
    # Server
    HOST: str = "0.0.0.0"
    PORT: int = 8000
    PUBLIC_HOST: str = "localhost"
    LOG_LEVEL: str = "INFO"
    
    # Session
    MAX_CONCURRENT_SESSIONS: int = 10
    
    # Recognition
    DEFAULT_SIMILARITY_THRESHOLD: float = 0.55
    MAX_SCAN_INTERVAL: int = 60
    EVIDENCE_RETENTION_DAYS: int = 30
    CALLBACK_TIMEOUT: int = 30
    CALLBACK_RETRY_ATTEMPTS: int = 3
    
    # Embedding
    EMBEDDING_VALIDATION_THRESHOLD: float = 0.90
    EMBEDDING_QUALITY_THRESHOLD: float = 0.50
    MAX_VIDEO_SIZE_MB: int = 50
    TEMP_DIR: str = "./temp"
    VIDEO_SAMPLE_INTERVAL: float = 0.5
    VALIDATION_SAMPLE_INTERVAL: float = 1.0
    
    # Development
    RELOAD: bool = False
    WORKERS: int = 1
    
    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"
        case_sensitive = True

@lru_cache
def get_settings() -> Settings:
    """Get cached settings instance (Singleton)"""
    return Settings()
```

## Usage

```python
from recognition_service.core.config import get_settings

settings = get_settings()
print(settings.API_KEY)
print(settings.DEFAULT_SIMILARITY_THRESHOLD)
```

## Per-Session Override

Một số config có thể override per-session qua request body:

```json
{
  "config": {
    "similarityThreshold": 0.60,  // Override DEFAULT_SIMILARITY_THRESHOLD
    "scanInterval": 2.0,          // Seconds between scans
    "callbackUrl": "http://..."   // Callback endpoint
  }
}
```

## Timezone

**CRITICAL**: Service sử dụng `Asia/Ho_Chi_Minh` timezone.

```python
import pytz

vn_tz = pytz.timezone('Asia/Ho_Chi_Minh')
timestamp = datetime.now(vn_tz)
```

**NEVER use**:
- `datetime.utcnow()` - No timezone info
- `datetime.now()` - System timezone

## Logging Configuration

**File**: `core/logging_config.py`

```python
def setup_logging(log_level: str):
    logging.basicConfig(
        level=getattr(logging, log_level.upper()),
        format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
    )
```

### Log Levels

- `DEBUG`: Detailed info for debugging (similarity scores, frame processing)
- `INFO`: General operational info (session start/stop, recognitions)
- `WARNING`: Potential issues (camera reconnect, callback retry)
- `ERROR`: Errors that need attention (all cameras failed, model not loaded)

### Log Patterns

```
# Session lifecycle
SESSION_START | slot=123 room=456 cameras=2 students=30 mode=INITIAL
SESSION_STOP | slot=123 duration=1800s recognitions=25

# Recognition
RECOGNITION | slot=123 camera=1 student=SE123456 confidence=0.87 mode=INITIAL
BATCH_SENT | slot=123 camera=1 count=3

# Camera
CAMERA_START | slot=123 camera=1
CAMERA_STOP | slot=123 camera=1
CAMERA_READ_FAIL | slot=123 camera=1 frame=100
CAMERA_RECONNECT | camera=1 attempt=1/3
CAMERA_RECONNECT_OK | camera=1
CAMERA_RECONNECT_FAILED | camera=1 after 3 attempts
CAMERA_DEAD | slot=123 camera=1
ALL_CAMERAS_DEAD | slot=123

# Callback
CALLBACK_OK | slot=123 student=456
SESSION_STATUS_SENT | slot=123 status=STOPPED reason=ALL_CAMERAS_FAILED
```

## Hardware Configuration

**File**: `core/hardware.py`

Auto-detected, không cần config:

```python
# GPU system
{
    "device_type": "gpu",
    "providers": ["CUDAExecutionProvider", "CPUExecutionProvider"],
    "ctx_id": 0,
    "device_name": "GPU (CUDA)"
}

# CPU system
{
    "device_type": "cpu",
    "providers": ["CPUExecutionProvider"],
    "ctx_id": -1,
    "device_name": "CPU"
}
```

## Directory Structure

```
recognition-service/
├── .env                    # Environment config (gitignored)
├── .env.example            # Template for .env
├── uploads/
│   └── evidence/           # Face evidence images
│       └── {slot_id}/
│           └── {user_id}_{roll_number}.jpg
├── temp/                   # Temporary files
└── ~/.insightface/
    └── models/
        └── buffalo_l/      # InsightFace model (auto-downloaded)
```

## Production Considerations

1. **PUBLIC_HOST**: Set to actual server IP/domain
2. **API_KEY**: Use strong, unique key
3. **LOG_LEVEL**: Use INFO or WARNING
4. **Evidence cleanup**: Implement cleanup policy based on EVIDENCE_RETENTION_DAYS
5. **Disk space**: Monitor uploads/ directory size
