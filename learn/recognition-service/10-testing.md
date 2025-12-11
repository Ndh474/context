# Recognition Service - Testing

## Test Framework

- **pytest**: Test runner
- **pytest-asyncio**: Async test support
- **httpx**: HTTP client for FastAPI TestClient
- **FastAPI TestClient**: API endpoint testing

## Test Structure

```
tests/
├── __init__.py
├── test_cameras.py         # Camera endpoint tests
├── test_embeddings.py      # Embedding generation tests
├── test_task_manager.py    # Background task tests
└── test_camera_direct.py   # Direct camera hardware tests (integration)
```

## Running Tests

```bash
# All tests
poetry run pytest

# Specific file with verbose output
poetry run pytest tests/test_cameras.py -v

# Run tests matching pattern
poetry run pytest -k test_requires_api_key

# Skip integration tests (require hardware)
poetry run pytest -m "not integration"

# Run only fast unit tests
poetry run pytest -k "not direct"

# With coverage
poetry run pytest --cov=src/recognition_service
```

## Test Patterns

### FastAPI TestClient

```python
from fastapi.testclient import TestClient
from recognition_service.main import app

client = TestClient(app)

def test_health_check():
    response = client.get("/api/v1/health")
    assert response.status_code == 200
    data = response.json()
    assert data["data"]["status"] == "healthy"
```

### API Key Authentication Tests

```python
def test_requires_api_key():
    """Test endpoint requires API key"""
    response = client.get("/api/v1/cameras/test-connection?rtspUrl=rtsp://test")
    assert response.status_code == 401

def test_invalid_api_key():
    """Test invalid API key rejected"""
    response = client.get(
        "/api/v1/cameras/test-connection?rtspUrl=rtsp://test",
        headers={"X-API-Key": "wrong-key"}
    )
    assert response.status_code == 401

def test_valid_api_key():
    """Test valid API key accepted"""
    response = client.get(
        "/api/v1/cameras/test-connection?rtspUrl=rtsp://test",
        headers={"X-API-Key": "python-service-secret-key-12345"}
    )
    # May fail due to invalid RTSP, but not 401
    assert response.status_code != 401
```

### Async Tests

```python
import pytest

@pytest.mark.asyncio
async def test_task_manager_start_stop():
    from recognition_service.services.task_manager import TaskManager
    
    manager = TaskManager()
    
    async def dummy_task():
        await asyncio.sleep(10)
    
    task = await manager.start_task("test_task", dummy_task())
    assert manager.active_tasks_count == 1
    
    stopped = await manager.stop_task("test_task")
    assert stopped is True
    assert manager.active_tasks_count == 0
```

### Fixtures

```python
import pytest

@pytest.fixture
def api_headers():
    return {"X-API-Key": "python-service-secret-key-12345"}

@pytest.fixture
def sample_student():
    return {
        "userId": 1,
        "fullName": "Test Student",
        "rollNumber": "SE123456",
        "embeddingVector": [0.1] * 512,
        "embeddingVersion": 1
    }

@pytest.fixture
def sample_camera():
    return {
        "id": 1,
        "name": "Test Camera",
        "rtspUrl": "rtsp://192.168.1.100:554/stream"
    }
```

### Skip Integration Tests

```python
import pytest

@pytest.mark.skip(reason="Requires real camera hardware")
def test_real_camera_connection():
    """Integration test with real camera"""
    pass

@pytest.mark.skipif(
    not os.environ.get("RTSP_URL"),
    reason="RTSP_URL environment variable not set"
)
def test_camera_with_env():
    """Test with camera from environment"""
    pass
```

### Mocking

```python
from unittest.mock import Mock, patch, AsyncMock

def test_face_detection_mocked():
    with patch('recognition_service.services.face_recognizer.FaceRecognizer') as mock:
        mock_instance = Mock()
        mock_instance.process_frame = AsyncMock(return_value=[])
        mock.return_value = mock_instance
        
        # Test code that uses face_recognizer
```

## Test Files Detail

### test_cameras.py

```python
"""Camera endpoint tests"""

def test_test_connection_requires_api_key():
    response = client.get("/api/v1/cameras/test-connection?rtspUrl=rtsp://test")
    assert response.status_code == 401

def test_test_connection_invalid_url():
    response = client.get(
        "/api/v1/cameras/test-connection?rtspUrl=http://invalid",
        headers=api_headers
    )
    assert response.status_code == 400
    assert "rtsp://" in response.json()["detail"]

def test_capture_frame_requires_rtsp_or_camera_id():
    response = client.get(
        "/api/v1/cameras/capture-frame",
        headers=api_headers
    )
    assert response.status_code == 400
```

### test_embeddings.py

```python
"""Embedding generation tests"""
import io

def test_generate_embedding_requires_photo():
    response = client.post(
        "/api/v1/embeddings/generate",
        headers=api_headers,
        data={"submissionId": 1}
        # No photo file
    )
    assert response.status_code == 422

def test_generate_embedding_invalid_format():
    # Create fake text file
    file_content = b"not an image"
    files = {"photo": ("test.txt", io.BytesIO(file_content), "text/plain")}
    
    response = client.post(
        "/api/v1/embeddings/generate",
        headers=api_headers,
        data={"submissionId": 1},
        files=files
    )
    assert response.status_code == 400
    assert response.json()["code"] == "INVALID_FILE_FORMAT"
```

### test_task_manager.py

```python
"""Task manager tests"""
import pytest
import asyncio

@pytest.mark.asyncio
async def test_start_task():
    manager = TaskManager()
    
    async def dummy():
        await asyncio.sleep(100)
    
    task = await manager.start_task("test", dummy())
    assert "test" in manager._tasks
    
    await manager.stop_task("test")

@pytest.mark.asyncio
async def test_duplicate_task_raises():
    manager = TaskManager()
    
    async def dummy():
        await asyncio.sleep(100)
    
    await manager.start_task("test", dummy())
    
    with pytest.raises(ValueError):
        await manager.start_task("test", dummy())
    
    await manager.stop_all_tasks()

@pytest.mark.asyncio
async def test_stop_all_tasks():
    manager = TaskManager()
    
    async def dummy():
        await asyncio.sleep(100)
    
    await manager.start_task("task1", dummy())
    await manager.start_task("task2", dummy())
    
    count = await manager.stop_all_tasks()
    assert count == 2
    assert manager.active_tasks_count == 0
```

### test_camera_direct.py

```python
"""Direct camera hardware tests (integration)"""
import pytest
import os

RTSP_URL = os.environ.get("TEST_RTSP_URL")

@pytest.mark.skipif(not RTSP_URL, reason="TEST_RTSP_URL not set")
def test_real_camera_connection():
    from recognition_service.services.rtsp_handler import RTSPHandler
    
    with RTSPHandler(RTSP_URL, timeout=10) as handler:
        width, height = handler.get_resolution()
        assert width > 0
        assert height > 0
        
        frame = handler.capture_single_frame()
        assert frame is not None
        assert frame.shape[0] > 0

@pytest.mark.skipif(not RTSP_URL, reason="TEST_RTSP_URL not set")
@pytest.mark.asyncio
async def test_async_camera_test():
    from recognition_service.services.rtsp_handler import test_rtsp_connection
    
    result = await test_rtsp_connection(RTSP_URL, timeout=10)
    assert result["connected"] is True
    assert result["frameRate"] > 0
```

## Test Configuration

### pytest.ini / pyproject.toml

```toml
[tool.pytest.ini_options]
asyncio_mode = "auto"
testpaths = ["tests"]
python_files = ["test_*.py"]
python_functions = ["test_*"]
markers = [
    "integration: marks tests as integration tests (require hardware)",
    "slow: marks tests as slow",
]
```

## Common Test Scenarios

### 1. Health Check

- Service healthy
- Uptime calculation
- Active sessions count

### 2. Authentication

- Missing API key → 401
- Invalid API key → 401
- Valid API key → proceed

### 3. Camera Operations

- Invalid RTSP URL format → 400
- Connection timeout → 500
- Successful connection → 200

### 4. Embedding Generation

- No photo → 422
- Invalid format → 400
- No face detected → 400
- Multiple faces → 400
- Low quality → 400
- Success → 200 with 512-dim vector

### 5. Recognition Session

- Session already exists → 409
- All cameras failed → 500
- Success → 200 with session data
- Stop non-existent → 404
- Stop success → 200 with statistics

### 6. Task Management

- Start task
- Stop task
- Duplicate task ID
- Stop all tasks
- Task cancellation
