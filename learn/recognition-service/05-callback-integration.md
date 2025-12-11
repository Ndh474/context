# Recognition Service - Callback Integration with Java Backend

## Overview

Python service gửi recognition results về Java backend qua HTTP callbacks. Java backend xử lý và update attendance records.

## Callback Service

**File**: `services/callback_service.py`

```python
class CallbackService:
    def __init__(self):
        self.batch_size = 100
        self.retry_attempts = 3
        self.retry_delay = 1  # seconds
```

## Recognition Callback

### Endpoint

Java backend endpoint (từ `config.callbackUrl`):
```
POST {JAVA_BACKEND_URL}/api/internal/recognition/callback
```

### Request Format

```python
async def send_recognition(
    callback_url: str,
    slot_id: int,
    recognition: Dict,
    mode: str = "INITIAL",
    callback_type: str = "REGULAR"
) -> bool:
```

**Headers**:
```
Content-Type: application/json
X-API-Key: {API_KEY}
```

**Body**:
```json
{
  "slotId": 123,
  "mode": "INITIAL",
  "callbackType": "REGULAR",
  "recognitions": [
    {
      "studentUserId": 456,
      "confidence": 0.87,
      "timestamp": "2024-11-06T10:30:00Z",
      "cameraId": 1,
      "evidence": {
        "regularImageUrl": "http://localhost:8000/uploads/evidence/123/456_SE123456.jpg",
        "examImageUrl": null
      }
    }
  ]
}
```

### Field Descriptions

- `slotId`: Slot ID của session
- `mode`: Scan mode
  - `INITIAL`: First scan
  - `RESCAN`: Scan lại cho students chưa có mặt
- `callbackType`: Routing type
  - `REGULAR`: Điểm danh lecture → update `attendance_record` table
  - `EXAM`: Điểm danh thi → update `exam_attendance` table
- `recognitions[]`: Array of recognition results
  - `studentUserId`: User ID của student
  - `confidence`: Similarity score (0.0-1.0)
  - `timestamp`: UTC timestamp (ISO 8601, no milliseconds)
  - `cameraId`: Camera ID đã capture
  - `evidence.regularImageUrl`: URL ảnh evidence (for REGULAR)
  - `evidence.examImageUrl`: URL ảnh evidence (for EXAM)

### Retry Logic

```python
for attempt in range(self.retry_attempts):  # 3 attempts
    try:
        async with aiohttp.ClientSession() as session:
            async with session.post(
                callback_url,
                json=body,
                headers=headers,
                timeout=aiohttp.ClientTimeout(total=10)
            ) as response:
                if response.status == 200:
                    return True
    except asyncio.TimeoutError:
        logger.warning(f"Callback timeout: attempt={attempt + 1}")
    except Exception as e:
        logger.warning(f"Callback error: {e}")
    
    # Exponential backoff: 1s, 2s, 4s
    if attempt < self.retry_attempts - 1:
        await asyncio.sleep(self.retry_delay * (2 ** attempt))

return False  # All attempts failed
```

## Session Status Callback

### Endpoint

```
POST {JAVA_BACKEND_URL}/api/internal/recognition/session-status
```

(Derived from callback_url by replacing `/recognition-result` with `/session-status`)

### Request Format

```python
async def send_session_status(
    callback_url: str,
    slot_id: int,
    status: str,
    reason: str,
    active_cameras: int = None,
    failed_cameras: int = None,
    failed_camera_ids: list = None,
    camera_id: int = None,
    camera_name: str = None
) -> bool:
```

**Body (All Cameras Failed)**:
```json
{
  "type": "SESSION_STATUS",
  "slotId": 123,
  "status": "STOPPED",
  "reason": "ALL_CAMERAS_FAILED",
  "timestamp": "2024-11-06T10:30:00Z",
  "activeCameras": 0,
  "failedCameras": 2,
  "failedCameraIds": [1, 2]
}
```

**Body (Single Camera Disconnected)**:
```json
{
  "type": "SESSION_STATUS",
  "slotId": 123,
  "status": "CAMERA_DISCONNECTED",
  "reason": "CAMERA_FAILURE",
  "timestamp": "2024-11-06T10:30:00Z",
  "cameraId": 1,
  "cameraName": "Camera 1"
}
```

### Status Values

- `STOPPED`: Session đã dừng (all cameras failed)
- `CAMERA_DISCONNECTED`: Một camera bị disconnect

### Reason Values

- `ALL_CAMERAS_FAILED`: Tất cả cameras đều fail
- `CAMERA_FAILURE`: Một camera cụ thể fail

## Timestamp Format

**CRITICAL**: Java backend expects specific format.

```python
# File: utils/__init__.py

def get_utc_timestamp_for_java() -> str:
    """
    Generate UTC timestamp compatible with Java backend.
    
    Java expects: @JsonFormat(pattern = "yyyy-MM-dd'T'HH:mm:ss'Z'")
    No milliseconds!
    """
    now = datetime.now(pytz.UTC)
    return now.strftime('%Y-%m-%dT%H:%M:%SZ')
```

**Examples**:
- ✅ `2024-11-06T10:30:00Z`
- ❌ `2024-11-06T10:30:00.123Z` (has milliseconds)
- ❌ `2024-11-06T10:30:00+00:00` (wrong timezone format)

## Evidence Image URLs

### URL Format

```
http://{PUBLIC_HOST}:{PORT}/uploads/evidence/{slot_id}/{filename}
```

**Filename patterns**:
- REGULAR: `{user_id}_{roll_number}.jpg`
- EXAM: `{user_id}_{roll_number}_exam.jpg`

**Examples**:
- `http://localhost:8000/uploads/evidence/123/456_SE123456.jpg`
- `http://localhost:8000/uploads/evidence/123/456_SE123456_exam.jpg`

### Static File Serving

```python
# In main.py
from fastapi.staticfiles import StaticFiles

uploads_dir = "./uploads"
os.makedirs(uploads_dir, exist_ok=True)
app.mount("/uploads", StaticFiles(directory=uploads_dir), name="uploads")
```

### Java Backend Download

Java backend downloads evidence images via HTTP GET from these URLs.

**Important**: `PUBLIC_HOST` must be set correctly in .env:
- Development: `localhost`
- Production: Server's public IP or domain

## Auto-Stop on Callback Failures

### Tracking

```python
# In RecognitionService
self.callback_failures: Dict[int, int] = {}      # slot_id -> consecutive failures
self.last_success_time: Dict[int, datetime] = {} # slot_id -> last success time
```

### Thresholds

```python
MAX_CONSECUTIVE_FAILURES = 10   # 10 consecutive callback failures
MAX_FAILURE_DURATION = 120      # 2 minutes without successful callback
```

### Check Logic

```python
async def _should_auto_stop(self, slot_id, max_failures, max_duration) -> bool:
    # Check consecutive failures
    failures = self.callback_failures.get(slot_id, 0)
    if failures >= max_failures:
        return True
    
    # Check duration since last success
    last_success = self.last_success_time.get(slot_id)
    if last_success:
        duration = (datetime.now(vn_tz) - last_success).seconds
        if duration >= max_duration:
            return True
    
    return False
```

### Update Tracking

```python
# After callback
if success:
    self.callback_failures[slot_id] = 0
    self.last_success_time[slot_id] = datetime.now(vn_tz)
else:
    self.callback_failures[slot_id] = self.callback_failures.get(slot_id, 0) + 1
```

## Batch Callback (Future)

```python
async def batch_send_recognitions(
    callback_url: str,
    recognitions: List[Dict]
) -> bool:
    """Send multiple recognitions in batch"""
    
    # Split into batches of 100
    for i in range(0, len(recognitions), self.batch_size):
        batch = recognitions[i:i + self.batch_size]
        
        body = {
            "recognitions": batch,
            "timestamp": get_utc_timestamp_for_java()
        }
        
        # ... send with retry logic ...
```

## Error Handling

### Callback Failures

- Log warning for each failed attempt
- Log error when all attempts exhausted
- Continue processing (don't block recognition)
- Track failures for auto-stop mechanism

### Network Issues

- Timeout: 10 seconds per request
- Retry: 3 attempts with exponential backoff
- Graceful degradation: recognition continues even if callbacks fail
