# Recognition Service - Session Flow

## Overview

Recognition session là core workflow để điểm danh tự động. Java backend gọi Python service để start session, Python xử lý video streams và gửi callbacks về Java khi recognize được students.

## Session Lifecycle

```
[Java Backend]                    [Python Service]
     |                                  |
     |-- POST /process-session -------->|
     |                                  |-- Test cameras (parallel)
     |                                  |-- Create session state
     |                                  |-- Start background tasks
     |<-- Response (session info) ------|
     |                                  |
     |                                  |== Background Loop ==
     |                                  |   for each camera:
     |                                  |   - Capture frame
     |                                  |   - Detect faces
     |                                  |   - Match embeddings
     |                                  |   - Deduplicate
     |<-- Callback (recognition) -------|   - Send callback
     |<-- Callback (recognition) -------|   - Save evidence
     |                                  |
     |-- POST /stop-session ----------->|
     |                                  |-- Cancel tasks
     |                                  |-- Cleanup resources
     |<-- Response (statistics) --------|
```

## Key Components

### 1. RecognitionService (`services/recognition_service.py`)

Singleton orchestrator cho sessions:

```python
class RecognitionService:
    active_tasks: Dict[int, List[asyncio.Task]]  # slot_id -> camera tasks
    task_ids: Dict[int, List[str]]               # slot_id -> task IDs
    recognized_students: Dict[int, set]          # slot_id -> set(user_ids)
    callback_failures: Dict[int, int]            # slot_id -> failure count
```

**Methods**:
- `start_session(request)` → Test cameras, create state, start tasks
- `stop_session(slot_id)` → Cancel tasks, cleanup, return stats
- `_process_camera(...)` → Background loop per camera
- `_try_reconnect(camera)` → Reconnect logic với retry
- `_handle_camera_failure(...)` → Notify backend khi camera chết

### 2. SessionManager (`services/session_manager.py`)

In-memory session state storage:

```python
@dataclass
class SessionState:
    slot_id: int
    room_id: int
    mode: str                    # "INITIAL" or "RESCAN"
    callback_type: str           # "REGULAR" or "EXAM"
    total_students: int
    total_cameras: int
    active_cameras: int
    failed_cameras: int
    started_at: datetime
    recognition_count: int
    active_camera_ids: set
    failed_camera_ids: set
```

**Thread-safe operations** với `asyncio.Lock`:
- `add_session()`, `remove_session()`, `get_session()`
- `increment_recognition_count()`
- `mark_camera_dead()` → Returns True nếu còn cameras active

### 3. FaceRecognizer (`services/face_recognizer.py`)

Face detection và matching:

```python
async def process_frame(
    frame: np.ndarray,
    students: List[StudentDTO],
    similarity_threshold: float,
    slot_id: int,
    camera_id: int,
    recognized_students: set,    # For deduplication
    callback_type: str           # "REGULAR" or "EXAM"
) -> List[Dict]:
```

**Process**:
1. Validate frame
2. `face_app.get(frame)` → Detect faces
3. For each face:
   - Extract 512-dim embedding
   - Compare với all student embeddings (cosine similarity)
   - Find best match >= threshold
   - **Deduplication**: Skip nếu student đã recognized
   - Crop face, save evidence image
   - Return recognition result

### 4. CallbackService (`services/callback_service.py`)

Send results to Java backend:

```python
async def send_recognition(
    callback_url: str,
    slot_id: int,
    recognition: Dict,
    mode: str,           # "INITIAL" or "RESCAN"
    callback_type: str   # "REGULAR" or "EXAM"
) -> bool:
```

**Callback Payload**:
```json
{
  "slotId": 123,
  "mode": "INITIAL",
  "callbackType": "REGULAR",
  "recognitions": [{
    "studentUserId": 456,
    "confidence": 0.87,
    "timestamp": "2024-11-06T10:30:00Z",
    "cameraId": 1,
    "evidence": {
      "regularImageUrl": "http://host:8000/uploads/evidence/123/456_SE123456.jpg",
      "examImageUrl": null
    }
  }]
}
```

**Retry Logic**: 3 attempts với exponential backoff (1s, 2s, 4s)

## Background Processing Loop

```python
# Trong _process_camera()
while True:
    # 1. Check cancellation
    if asyncio.current_task().cancelled():
        break
    
    # 2. Check session exists
    session = await session_manager.get_session(slot_id)
    if not session:
        break
    
    # 3. Check auto-stop (callback failures)
    if await self._should_auto_stop(slot_id, MAX_FAILURES, MAX_DURATION):
        await self.stop_session(slot_id)
        break
    
    # 4. Flush buffer, read latest frame
    for _ in range(3):
        cap.grab()
    ret, frame = cap.read()
    
    # 5. Handle read failure → reconnect
    if not ret:
        cap = await self._try_reconnect(camera)
        if cap is None:
            await self._handle_camera_failure(slot_id, camera, config)
            return
        continue
    
    # 6. Check scan interval
    if (now - last_scan).total_seconds() < scan_interval:
        await asyncio.sleep(0.1)
        continue
    
    # 7. Process frame
    recognitions = await face_recognizer.process_frame(...)
    
    # 8. Send callbacks
    for recognition in recognitions:
        success = await callback_service.send_recognition(...)
        # Track success/failure for auto-stop
    
    await asyncio.sleep(0.1)
```

## Deduplication

Mỗi student chỉ recognized **1 lần** per session:

```python
# In RecognitionService
self.recognized_students: Dict[int, set] = {}  # slot_id -> set(user_ids)

# In process_frame
if student_id in recognized_students:
    logger.debug(f"Student {student_id} already recognized, skipping")
    continue

# After successful recognition
self.recognized_students[slot_id].add(student_id)
```

## Scan Modes

- **INITIAL**: First scan, recognize all students
- **RESCAN**: Scan lại cho students chưa có mặt (Java backend gửi filtered list)

## Callback Types

- **REGULAR**: Điểm danh lecture → `regularImageUrl` in evidence
- **EXAM**: Điểm danh thi → `examImageUrl` in evidence

Evidence filename format:
- REGULAR: `{user_id}_{roll_number}.jpg`
- EXAM: `{user_id}_{roll_number}_exam.jpg`

## Auto-Stop Mechanism

Session tự động stop khi backend unresponsive:

```python
MAX_CONSECUTIVE_FAILURES = 10   # 10 callback failures liên tiếp
MAX_FAILURE_DURATION = 120      # 2 phút không có successful callback
```

## Camera Failure Handling

1. Read frame fail → Try reconnect (3 attempts, 2s delay)
2. Reconnect fail → Mark camera dead
3. Check remaining cameras:
   - Còn cameras → Continue với remaining
   - All dead → Send `SESSION_STATUS` callback, stop session

**Session Status Callback**:
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
