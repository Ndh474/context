# Face Recognition Service Documentation

## 1. Giới Thiệu

### 1.1. Recognition Service là gì?

**Recognition Service** là Python FastAPI service cung cấp khả năng nhận diện khuôn mặt cho hệ thống FUACS. Service này:

- Xử lý video streams từ IP cameras (RTSP)
- Phát hiện và nhận diện khuôn mặt sinh viên
- Gửi kết quả về Java backend qua callbacks

### 1.2. Core Technologies

| Technology                  | Vai trò                            |
| --------------------------- | ---------------------------------- |
| **FastAPI**                 | Async web framework                |
| **InsightFace (buffalo_l)** | Face detection & recognition model |
| **OpenCV**                  | RTSP stream processing             |
| **NumPy**                   | Vector operations                  |
| **aiohttp**                 | Async HTTP client (callbacks)      |
| **Poetry**                  | Dependency management              |

### 1.3. Vai trò trong Hệ Thống

```
┌─────────────────────────────────────────────────────────────────┐
│                     JAVA BACKEND                                │
│                                                                 │
│  SlotSessionService                                             │
│  1. User triggers "Start Session"                               │
│  2. Call Python service with student embeddings                 │
│  3. Receive recognition callbacks                               │
│  4. Update attendance records                                   │
└────────────────────────────┬────────────────────────────────────┘
                             │ HTTP (X-API-Key)
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│               RECOGNITION SERVICE (Python)                      │
│                                                                 │
│  1. Receive start session request                               │
│  2. Connect to RTSP cameras                                     │
│  3. Capture frames continuously                                 │
│  4. Detect faces using InsightFace                              │
│  5. Match with student embeddings (cosine similarity)           │
│  6. Send callbacks to Java backend                              │
│  7. Store evidence images                                       │
└────────────────────────────┬────────────────────────────────────┘
                             │ RTSP
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                     IP CAMERAS                                  │
│                                                                 │
│  Room cameras providing video streams                           │
└─────────────────────────────────────────────────────────────────┘
```

---

## 2. Kiến Trúc Hệ Thống

### 2.1. Folder Structure

```
recognition-service/
├── src/recognition_service/
│   ├── main.py                      # FastAPI app initialization
│   ├── api/v1/                      # API endpoints
│   │   ├── health.py               # Health check (public)
│   │   ├── metrics.py              # Performance metrics
│   │   ├── cameras.py              # Camera testing
│   │   ├── embeddings.py           # Embedding generation
│   │   └── recognition.py          # Session management
│   ├── services/                    # Business logic (singletons)
│   │   ├── recognition_service.py  # Session orchestration
│   │   ├── session_manager.py      # In-memory session state
│   │   ├── face_recognizer.py      # Face detection & matching
│   │   ├── embedding_generator.py  # Generate embeddings
│   │   ├── rtsp_handler.py         # RTSP stream handling
│   │   ├── callback_service.py     # Callbacks to Java
│   │   ├── task_manager.py         # Background task management
│   │   └── model_loader.py         # InsightFace model loading
│   ├── models/                      # Pydantic request/response DTOs
│   ├── core/                        # Infrastructure
│   │   ├── config.py               # Settings (from .env)
│   │   ├── security.py             # API key authentication
│   │   ├── hardware.py             # GPU/CPU detection
│   │   └── logging_config.py       # Structured logging
│   └── utils/                       # Utilities
├── uploads/                         # Evidence images storage
├── pyproject.toml                   # Poetry dependencies
└── .env                             # Environment configuration
```

### 2.2. Key Design Patterns

**Singleton Services:**

- `face_recognizer` - Face detection & matching
- `session_manager` - Session state tracking
- `task_manager` - Background task management
- `callback_service` - HTTP callbacks to Java

**Async/Await Throughout:**

- All I/O operations (cameras, callbacks, files) are async
- Non-blocking background processing

**Lazy Model Loading:**

- InsightFace model loaded once during startup
- ~600MB in RAM, reused globally

### 2.3. Service Communication

```
┌──────────────────────────────────────────────────────────────┐
│                     API Layer                                │
│  recognition.py → POST /api/v1/recognition/process-session   │
│                 → POST /api/v1/recognition/stop-session      │
└──────────────────────────────┬───────────────────────────────┘
                               │
                               ▼
┌──────────────────────────────────────────────────────────────┐
│                 RecognitionService                           │
│  - Orchestrates session lifecycle                            │
│  - Manages background tasks per camera                       │
│  - Tracks recognized students for deduplication              │
└──────────────────────────────┬───────────────────────────────┘
                               │
          ┌────────────────────┼────────────────────┐
          ▼                    ▼                    ▼
┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐
│ SessionManager  │  │ FaceRecognizer  │  │ CallbackService │
│ - In-memory     │  │ - InsightFace   │  │ - HTTP POST     │
│ - Session state │  │ - Cosine match  │  │ - Retry logic   │
│ - Statistics    │  │ - Evidence save │  │ - Batching      │
└─────────────────┘  └─────────────────┘  └─────────────────┘
```

---

## 3. Implementation Details

### 3.1. API Endpoints

#### Health Check (Public)

```
GET /api/v1/health
```

No authentication required. Returns service status.

#### Recognition Session (Protected)

```
POST /api/v1/recognition/process-session
POST /api/v1/recognition/stop-session
```

Requires `X-API-Key` header.

#### Embeddings (Protected)

```
POST /api/v1/embeddings/generate
POST /api/v1/embeddings/validate
```

For generating and validating face embeddings from photos.

#### Cameras (Protected)

```
GET /api/v1/cameras/test-connection
GET /api/v1/cameras/capture-frame
```

For testing camera connectivity.

### 3.2. Start Session Request

**Endpoint:** `POST /api/v1/recognition/process-session`

**Headers:**

```
X-API-Key: {API_KEY}
Content-Type: application/json
```

**Request Body:**

```json
{
  "slotId": 123,
  "roomId": 45,
  "mode": "INITIAL",
  "callbackType": "REGULAR",
  "cameras": [
    {
      "id": 1,
      "name": "Camera 1",
      "rtspUrl": "rtsp://admin:password@192.168.1.100:554/stream"
    }
  ],
  "students": [
    {
      "userId": 456,
      "fullName": "Nguyen Van A",
      "rollNumber": "SE160001",
      "embeddingVector": [0.123, -0.456, ...]  // 512 floats
    }
  ],
  "config": {
    "scanInterval": 5,
    "similarityThreshold": 0.55,
    "callbackUrl": "http://localhost:8080/api/internal/recognition/callback"
  }
}
```

**Key Parameters:**

| Parameter                    | Type   | Description                             |
| ---------------------------- | ------ | --------------------------------------- |
| `slotId`                     | int    | Slot ID for this session                |
| `roomId`                     | int    | Room ID containing cameras              |
| `mode`                       | string | `INITIAL` or `RESCAN`                   |
| `callbackType`               | string | `REGULAR` or `EXAM`                     |
| `cameras`                    | array  | List of camera configs with RTSP URLs   |
| `students`                   | array  | Students with 512-dim embedding vectors |
| `config.scanInterval`        | int    | Seconds between frame captures          |
| `config.similarityThreshold` | float  | Matching threshold (0.0-1.0)            |
| `config.callbackUrl`         | string | Java backend callback endpoint          |

**Response:**

```json
{
  "status": 200,
  "message": "Face recognition session started successfully",
  "data": {
    "slotId": 123,
    "roomId": 45,
    "mode": "INITIAL",
    "totalStudents": 30,
    "totalCameras": 2,
    "activeCameras": 2,
    "failedCameras": 0,
    "sessionStartedAt": "2024-11-15T08:00:00Z"
  }
}
```

### 3.3. Stop Session Request

**Endpoint:** `POST /api/v1/recognition/stop-session`

**Request Body:**

```json
{
  "slotId": 123
}
```

**Response:**

```json
{
  "status": 200,
  "message": "Face recognition session stopped successfully",
  "data": {
    "slotId": 123,
    "roomId": 45,
    "mode": "INITIAL",
    "totalStudents": 30,
    "totalCameras": 2,
    "activeCameras": 2,
    "failedCameras": 0,
    "sessionStoppedAt": "2024-11-15T09:30:00Z",
    "sessionDuration": 5400,
    "totalRecognitions": 28,
    "recognizedStudentIds": [456, 457, 458, ...]
  }
}
```

### 3.4. Callback Format (Python → Java)

**Endpoint:** `POST {callbackUrl}` (e.g., `/api/internal/recognition/callback`)

**Headers:**

```
X-API-Key: {API_KEY}
Content-Type: application/json
```

**Request Body:**

```json
{
  "slotId": 123,
  "mode": "INITIAL",
  "callbackType": "REGULAR",
  "recognitions": [
    {
      "studentUserId": 456,
      "confidence": 0.87,
      "timestamp": "2024-11-15T08:05:00Z",
      "cameraId": 1,
      "evidence": {
        "regularImageUrl": "http://localhost:8000/uploads/evidence/123/456_SE160001.jpg",
        "examImageUrl": null
      }
    }
  ]
}
```

**Routing Logic:**

- `callbackType: "REGULAR"` → Java routes to `AttendanceRecordService.processRecognitionResults()`
- `callbackType: "EXAM"` → Java routes to `ExamAttendanceService.processRecognitionResults()`

### 3.5. InsightFace Model

**Model:** `buffalo_l` (Large Buffalo model)

**Components:**

- Detection: SCRFD (640x640 input)
- Recognition: ArcFace ResNet100
- Embedding dimension: **512 floats**
- Model size: ~600MB

**Loading:**

```python
from insightface.app import FaceAnalysis

face_app = FaceAnalysis(name='buffalo_l', providers=onnx_providers)
face_app.prepare(ctx_id=ctx_id, det_size=(640, 640))
```

**Hardware Auto-Detection:**

```python
# core/hardware.py
if has_nvidia_gpu():
    onnx_providers = ["CUDAExecutionProvider", "CPUExecutionProvider"]
    ctx_id = 0  # GPU
else:
    onnx_providers = ["CPUExecutionProvider"]
    ctx_id = -1  # CPU
```

### 3.6. Face Recognition Logic

**File:** `services/face_recognizer.py`

**process_frame() Flow:**

```python
async def process_frame(frame, students, similarity_threshold, slot_id, camera_id,
                        recognized_students, callback_type):
    """
    1. Validate frame (not None/empty)
    2. Detect faces using InsightFace
    3. For each detected face:
       a. Extract 512-dim embedding
       b. Find best match in students list
       c. Check threshold (default 0.55)
       d. Check deduplication (skip if already recognized)
       e. Crop face from frame
       f. Save evidence image
       g. Build recognition result
    4. Return list of recognitions
    """
```

**Cosine Similarity:**

```python
def _cosine_similarity(vec1, vec2):
    """
    similarity = dot(vec1, vec2) / (||vec1|| * ||vec2||)

    Range: -1.0 to 1.0
    - 1.0 = identical vectors
    - 0.0 = orthogonal (unrelated)
    - -1.0 = opposite directions

    For face recognition:
    - >= 0.55 = likely same person
    - < 0.55 = different person
    """
    dot_product = np.dot(vec1, vec2)
    norm1 = np.linalg.norm(vec1)
    norm2 = np.linalg.norm(vec2)
    return dot_product / (norm1 * norm2)
```

**Matching Strategy:**

```python
def _find_best_match(face_embedding, students, threshold):
    """
    1. Compare face embedding with ALL student embeddings
    2. Calculate cosine similarity for each
    3. Find highest similarity score
    4. Accept if similarity >= threshold (default 0.55)
    5. Return best match or None

    Debug: Log top 3 matches for troubleshooting
    """
```

### 3.7. Deduplication Logic

**Problem:** Một sinh viên có thể xuất hiện nhiều lần trong camera

**Solution:** In-memory tracking per session

```python
# RecognitionService
self.recognized_students: Dict[int, set] = {}  # slot_id -> set(student_ids)

# In process_camera() loop:
if slot_id not in self.recognized_students:
    self.recognized_students[slot_id] = set()

# In face_recognizer.process_frame():
if student_id in recognized_students:
    logger.debug(f"Student {student_id} already recognized, skipping")
    continue

# After successful recognition:
self.recognized_students[slot_id].add(student_id)
```

**Result:** Mỗi sinh viên chỉ được callback **1 lần** per session

### 3.8. Evidence Image Storage

**Directory Structure:**

```
uploads/
└── evidence/
    └── {slot_id}/
        ├── {user_id}_{roll_number}.jpg      # REGULAR
        ├── {user_id}_{roll_number}_exam.jpg # EXAM
        └── ...
```

**URL Format:**

```
http://{PUBLIC_HOST}:{PORT}/uploads/evidence/{slot_id}/{filename}
```

**Image Processing:**

```python
def _save_evidence(face_crop, slot_id, user_id, roll_number, callback_type):
    """
    1. Add 50px padding around face
    2. Ensure minimum 300x300 size (upscale if needed)
    3. Save as JPEG with quality=100
    4. Return full URL for Java backend to download
    """
```

### 3.9. Session Management

**File:** `services/session_manager.py`

**SessionState:**

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
    recognition_count: int = 0
```

**In-Memory Storage:**

```python
class SessionManager:
    sessions: Dict[int, SessionState] = {}  # slot_id -> state
```

**Limitations:**

- Sessions lost on service restart
- Not suitable for multi-instance deployment
- Consider Redis for production scaling

### 3.10. Background Task Management

**File:** `services/task_manager.py`

**Task Lifecycle:**

```python
# Start task for each camera
task_id = f"slot_{slot_id}_camera_{camera.id}"
task = await task_manager.start_task(task_id, coro)

# Store for cleanup
self.task_ids[slot_id] = task_ids

# Stop all tasks on session stop
for task_id in self.task_ids[slot_id]:
    await task_manager.stop_task(task_id)
```

**Camera Processing Loop:**

```python
async def _process_camera(slot_id, camera, students, config):
    """
    while True:
        1. Check if cancelled
        2. Flush old frames from buffer (reduce lag)
        3. Read latest frame
        4. Check scan interval (e.g., every 5 seconds)
        5. Process frame for recognition
        6. Send callbacks for recognized faces
        7. Small delay (0.1s) to prevent CPU overload
    """
```

---

## 4. Integration với Java Backend

### 4.1. Java → Python (Start Session)

**Java Service:** `SlotSessionService.java`

```java
// SlotSessionService.startSession()
public SessionStartResponse startSession(Integer slotId) {
    Slot slot = slotRepository.findById(slotId).orElseThrow(...);

    // Build request for Python
    RecognitionSessionRequest request = RecognitionSessionRequest.builder()
        .slotId(slotId)
        .roomId(slot.getRoom().getId())
        .mode(ScanMode.INITIAL)
        .callbackType(slot.getSlotCategory() == FINAL_EXAM ? "EXAM" : "REGULAR")
        .cameras(getCamerasForRoom(slot.getRoom()))
        .students(getStudentsWithEmbeddings(slot))
        .config(getSessionConfig())
        .build();

    // Call Python service
    return recognitionClient.startSession(request);
}
```

### 4.2. Python → Java (Callback)

**Java Controller:** `RecognitionCallbackController.java`

```java
@PostMapping("/api/internal/recognition/callback")
public ResponseEntity<?> handleRecognitionCallback(
        @RequestBody RecognitionResultRequest request,
        @RequestHeader("X-API-Key") String apiKey) {

    // Verify API key
    if (!apiKey.equals(expectedApiKey)) {
        return ResponseEntity.status(401).build();
    }

    // Route based on callbackType
    if ("EXAM".equals(request.getCallbackType())) {
        examAttendanceService.processRecognitionResults(request);
    } else {
        attendanceRecordService.processRecognitionResults(request);
    }

    return ResponseEntity.ok().build();
}
```

### 4.3. Callback Processing (Java)

**AttendanceRecordService:**

```java
// REGULAR attendance
if (currentStatus == NOT_YET) {
    record.setStatus(PRESENT);
    record.setMethod(AUTO);
    // Store evidence image URL
}
```

**ExamAttendanceService:**

```java
// EXAM attendance - Override ABSENT for late arrival
if (currentStatus == NOT_YET || currentStatus == ABSENT) {
    record.setStatus(PRESENT);
    record.setMethod(AUTO);
}
```

### 4.4. SSE Real-time Updates

After processing callback, Java backend publishes SSE event:

```java
// SseHub.publishAttendanceUpdate()
AttendanceUpdateEvent event = new AttendanceUpdateEvent(
    slotId,
    studentUserId,
    "regular",  // or "exam"
    recordId,
    "present",
    "auto",
    recordedAt,
    evidenceImageUrl
);
sseHub.publishAttendanceUpdate(slotId, event);
```

Frontend receives via `useSlotRosterSSE` hook and updates UI in real-time.

---

## 5. Luồng Xử Lý

### 5.1. Start Recognition Session

```
┌─────────────────────────────────────────────────────────────────┐
│  User clicks "Start Session" button                             │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│  Frontend: POST /api/v1/slot-session/{slotId}/start             │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│  Java SlotSessionService.startSession()                         │
│  1. Validate slot (active, not already started)                 │
│  2. Get cameras for room                                        │
│  3. Get students with embeddings (from enrollments)             │
│  4. Build request payload                                       │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│  Python POST /api/v1/recognition/process-session                │
│  1. Check no existing session                                   │
│  2. Test camera connections (parallel)                          │
│  3. Create session state                                        │
│  4. Start background tasks (one per camera)                     │
│  5. Return immediately                                          │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│  Java updates Slot                                              │
│  - sessionStatus = ACTIVE (or examSessionStatus for EXAM)       │
│  - scanCount++                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### 5.2. Face Recognition Loop (per Camera)

```
┌─────────────────────────────────────────────────────────────────┐
│  Background Task: _process_camera()                             │
│                                                                 │
│  while session_active:                                          │
│      ┌─────────────────────────────────────────────────────────┐│
│      │  1. Flush old frames (reduce lag)                       ││
│      │  2. Read latest frame from RTSP                         ││
│      │  3. Check scan interval (e.g., 5 seconds)               ││
│      │     → Skip if not enough time passed                    ││
│      │  4. Detect faces using InsightFace                      ││
│      │     → Get 512-dim embeddings                            ││
│      │  5. Match with student embeddings (cosine similarity)   ││
│      │     → Threshold: 0.55 default                           ││
│      │  6. Deduplication check                                 ││
│      │     → Skip if student already recognized                ││
│      │  7. Save evidence image                                 ││
│      │  8. Send callback to Java backend                       ││
│      │  9. Small delay (0.1s)                                  ││
│      └─────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────────┘
```

### 5.3. Recognition Callback Processing

```
┌─────────────────────────────────────────────────────────────────┐
│  Python CallbackService.send_recognition()                      │
│  POST {callbackUrl} with recognition data                       │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│  Java RecognitionCallbackController                             │
│  Route based on callbackType:                                   │
│  - REGULAR → AttendanceRecordService                            │
│  - EXAM → ExamAttendanceService                                 │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│  AttendanceRecordService.processRecognitionResults()            │
│  1. Find attendance record by slotId + studentUserId            │
│  2. Update status: NOT_YET → PRESENT                            │
│  3. Set method: AUTO                                            │
│  4. Download evidence image from Python                         │
│  5. Store locally in uploads/evidence/{slotId}/                 │
│  6. Publish SSE event                                           │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│  Frontend receives SSE event                                    │
│  Update roster table in real-time                               │
└─────────────────────────────────────────────────────────────────┘
```

### 5.4. Stop Session

```
┌─────────────────────────────────────────────────────────────────┐
│  User clicks "Stop Session" button                              │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│  Frontend: POST /api/v1/slot-session/{slotId}/stop              │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│  Java SlotSessionService.stopSession()                          │
│  1. Call Python stop-session                                    │
│  2. Get statistics (totalRecognitions, recognizedStudentIds)    │
│  3. Finalize attendance records                                 │
│     - NOT_YET → ABSENT (if not recognized)                      │
│  4. Update slot status                                          │
│     - sessionStatus = STOPPED                                   │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│  Python recognition_service.stop_session()                      │
│  1. Cancel all background tasks                                 │
│  2. Release camera resources                                    │
│  3. Get recognized student IDs (for RESCAN mode)                │
│  4. Remove session from memory                                  │
│  5. Return statistics                                           │
└─────────────────────────────────────────────────────────────────┘
```

---

## 6. Configuration & Deployment

### 6.1. Environment Variables

```bash
# Service Identity
SERVICE_NAME=FUACS Face Recognition Service
SERVICE_VERSION=1.0.0

# Security
API_KEY=python-service-secret-key-12345

# Java Backend Integration
JAVA_BACKEND_URL=http://localhost:8080

# InsightFace Model
MODEL_NAME=buffalo_l
MODEL_PATH=./src/recognition_service/models/insightface

# Server
HOST=0.0.0.0
PORT=8000
PUBLIC_HOST=localhost  # For URL generation in callbacks

# Recognition Settings
DEFAULT_SIMILARITY_THRESHOLD=0.55
MAX_SCAN_INTERVAL=60
EVIDENCE_RETENTION_DAYS=30

# Callback Settings
CALLBACK_TIMEOUT=30
CALLBACK_RETRY_ATTEMPTS=3

# Embedding Generation
EMBEDDING_QUALITY_THRESHOLD=0.50
MAX_VIDEO_SIZE_MB=50
```

### 6.2. Running the Service

**Development:**

```bash
# Install dependencies
poetry install

# Hardware auto-configuration
python scripts/setup.py

# Run with auto-reload
poetry run uvicorn src.recognition_service.main:app --reload --port 8000
```

**Production:**

```bash
poetry run uvicorn src.recognition_service.main:app --host 0.0.0.0 --port 8000
```

### 6.3. Docker Deployment

```dockerfile
FROM python:3.10-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    libgl1-mesa-glx \
    libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

# Install Poetry
RUN pip install poetry

# Copy project files
COPY pyproject.toml poetry.lock ./
COPY src/ ./src/

# Install dependencies
RUN poetry install --no-dev

# Create uploads directory
RUN mkdir -p ./uploads/evidence

# Expose port
EXPOSE 8000

# Run service
CMD ["poetry", "run", "uvicorn", "src.recognition_service.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

**Docker Compose:**

```yaml
recognition-service:
  build: ./recognition-service
  ports:
    - "8000:8000"
  volumes:
    - ./uploads:/app/uploads # Persist evidence images
  environment:
    - API_KEY=${RECOGNITION_API_KEY}
    - JAVA_BACKEND_URL=http://backend:8080
    - PUBLIC_HOST=recognition-service
  deploy:
    resources:
      reservations:
        devices:
          - driver: nvidia
            count: 1
            capabilities: [gpu]
```

### 6.4. GPU vs CPU

**GPU (Recommended):**

- NVIDIA CUDA support
- 10x faster than CPU
- Required for production with multiple cameras

**CPU:**

- Works without GPU
- Slower but functional
- Suitable for development/testing

**Auto-Detection:**

```python
# scripts/setup.py automatically detects and configures
# - onnxruntime-gpu for NVIDIA GPUs
# - onnxruntime for CPU-only
```

---

## 7. Hướng Dẫn Phát Triển

### 7.1. Adding New API Endpoint

1. Create route in `api/v1/{module}.py`:

```python
@router.post("/new-endpoint")
async def new_endpoint(
    request: NewRequest,
    api_key: str = Depends(verify_api_key)
):
    return await service.process(request)
```

2. Define request/response models in `models/`:

```python
class NewRequest(BaseModel):
    field1: str
    field2: int
```

3. Implement logic in `services/`:

```python
async def process(request: NewRequest):
    # Business logic here
    pass
```

### 7.2. Modifying Recognition Logic

**File:** `services/face_recognizer.py`

**Change similarity threshold:**

```python
# Update DEFAULT_SIMILARITY_THRESHOLD in .env
DEFAULT_SIMILARITY_THRESHOLD=0.60  # Higher = stricter
```

**Change matching algorithm:**

```python
def _find_best_match(face_embedding, students, threshold):
    # Modify matching logic here
    pass
```

### 7.3. Changing Callback Format

**Files:**

- `services/callback_service.py` - Request body construction
- `models/recognition_responses.py` - Response models

```python
# callback_service.py
body = {
    "slotId": slot_id,
    "mode": mode,
    "callbackType": callback_type,
    "recognitions": [recognition],
    "newField": "new_value"  # Add new field
}
```

**Note:** Coordinate with Java backend team when changing callback format.

### 7.4. Testing

```bash
# Run all tests
poetry run pytest

# Specific file
poetry run pytest tests/test_cameras.py -v

# Pattern matching
poetry run pytest -k test_requires_api_key
```

### 7.5. Common Issues

**1. Timezone Mistakes:**

```python
# ❌ WRONG
timestamp = datetime.now()

# ✅ CORRECT
vn_tz = pytz.timezone('Asia/Ho_Chi_Minh')
timestamp = datetime.now(vn_tz)
```

**2. Model Not Loaded:**

```python
# Always check before using
if self.face_app is None:
    raise RuntimeError("Model not loaded")
```

**3. RTSP Stream Not Closing:**

```python
# Always release camera
try:
    cap = cv2.VideoCapture(rtsp_url)
    # ... use cap ...
finally:
    if cap:
        cap.release()
```

**4. Session Cleanup:**

```python
# Always cleanup on stop
await task_manager.cancel_tasks(slot_id)
session_manager.remove_session(slot_id)
```

---

## Appendix: API Reference

### Public Endpoints

```
GET  /                          # Service info
GET  /api/v1/health            # Health check
GET  /docs                      # Swagger UI
GET  /redoc                     # ReDoc UI
```

### Protected Endpoints (X-API-Key required)

```
GET  /api/v1/metrics                           # Performance metrics
GET  /api/v1/cameras/test-connection           # Test camera
GET  /api/v1/cameras/capture-frame             # Capture frame
POST /api/v1/embeddings/validate               # Validate photo quality
POST /api/v1/embeddings/generate               # Generate embedding
POST /api/v1/recognition/process-session       # Start recognition
POST /api/v1/recognition/stop-session          # Stop recognition
```

### Static Files

```
GET  /uploads/evidence/{slot_id}/{filename}    # Evidence images
```
