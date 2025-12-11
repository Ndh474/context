# Recognition Service - Data Models (Pydantic DTOs)

## Request Models

### Recognition Requests

**File**: `models/recognition_requests.py`

#### ScanMode Enum

```python
class ScanMode(str, Enum):
    INITIAL = "INITIAL"  # First scan
    RESCAN = "RESCAN"    # Scan lại cho students chưa có mặt
```

#### StudentEmbeddingDTO

```python
class StudentEmbeddingDTO(BaseModel):
    userId: int
    fullName: str
    rollNumber: str
    embeddingVector: List[float] = Field(..., min_length=512, max_length=512)
    embeddingVersion: int
```

#### CameraDTO

```python
class CameraDTO(BaseModel):
    id: int
    name: str
    rtspUrl: str
```

#### SessionConfigDTO

```python
class SessionConfigDTO(BaseModel):
    similarityThreshold: float = Field(default=0.85, ge=0.0, le=1.0)
    scanInterval: float = Field(default=1.5, ge=0.5, le=60)  # Seconds
    callbackUrl: str
```

#### StartSessionRequest

```python
class StartSessionRequest(BaseModel):
    slotId: int
    roomId: int
    mode: ScanMode = ScanMode.INITIAL
    students: List[StudentEmbeddingDTO] = Field(..., min_length=1)
    cameras: List[CameraDTO] = Field(..., min_length=1)
    config: SessionConfigDTO
    callbackType: str = "REGULAR"  # "REGULAR" or "EXAM"
```

#### StopSessionRequest

```python
class StopSessionRequest(BaseModel):
    slotId: int
```

---

## Response Models

### Recognition Responses

**File**: `models/recognition_responses.py`

#### SessionDataDTO

```python
class SessionDataDTO(BaseModel):
    slotId: int
    roomId: int
    mode: str = "INITIAL"
    totalStudents: int
    totalCameras: int
    activeCameras: int
    failedCameras: int
    sessionStartedAt: Optional[str] = None
    sessionStoppedAt: Optional[str] = None
    sessionDuration: Optional[int] = None  # seconds
    totalRecognitions: Optional[int] = None
    recognizedStudentIds: Optional[List[int]] = None  # For RESCAN mode
```

#### RecognitionResponse

```python
class RecognitionResponse(BaseModel):
    status: int
    message: str
    data: Optional[SessionDataDTO] = None
    code: Optional[str] = None  # Error code
```

---

### General Responses

**File**: `models/responses.py`

#### HealthData

```python
class HealthData(BaseModel):
    service: str
    version: str
    status: str  # "healthy", "degraded", "unhealthy"
    uptime: int  # seconds
    activeSessions: int
    timestamp: str  # ISO 8601
    error: Optional[str] = None
```

#### HealthResponse

```python
class HealthResponse(BaseModel):
    status: int
    message: str
    data: HealthData
```

#### CameraResolution

```python
class CameraResolution(BaseModel):
    width: int
    height: int
```

#### CameraTestData

```python
class CameraTestData(BaseModel):
    rtspUrl: str
    connected: bool
    frameRate: Optional[float] = None
    resolution: Optional[CameraResolution] = None
    latency: Optional[int] = None  # milliseconds
    stability: Optional[str] = None  # "stable", "unstable"
    error: Optional[str] = None
    testedAt: str
```

#### CameraTestResponse

```python
class CameraTestResponse(BaseModel):
    status: int
    message: str
    data: CameraTestData
```

#### FrameCaptureData

```python
class FrameCaptureData(BaseModel):
    cameraId: Optional[int] = None
    rtspUrl: str
    format: str  # "base64" or "file"
    image: Optional[str] = None      # base64 data
    filePath: Optional[str] = None   # file path
    fileUrl: Optional[str] = None    # URL to access file
    resolution: CameraResolution
    capturedAt: str
```

#### FrameCaptureResponse

```python
class FrameCaptureResponse(BaseModel):
    status: int
    message: str
    data: FrameCaptureData
```

#### EmbeddingGenerateData

```python
class EmbeddingGenerateData(BaseModel):
    submissionId: int
    embeddingVector: list[float] = Field(..., min_length=512, max_length=512)
    quality: float = Field(..., ge=0.0, le=1.0)
    faceDetected: bool
    processingTime: float  # seconds
```

#### EmbeddingGenerateResponse

```python
class EmbeddingGenerateResponse(BaseModel):
    status: int
    message: str
    data: Optional[EmbeddingGenerateData] = None
    code: Optional[str] = None  # Error code
```

---

## Internal Models

### SessionState (Dataclass)

**File**: `services/session_manager.py`

```python
@dataclass
class SessionState:
    slot_id: int
    room_id: int
    mode: str = "INITIAL"
    callback_type: str = "REGULAR"
    total_students: int = 0
    total_cameras: int = 0
    active_cameras: int = 0
    failed_cameras: int = 0
    started_at: datetime = field(default_factory=datetime.now)
    recognition_count: int = 0
    active_camera_ids: set = field(default_factory=set)
    failed_camera_ids: set = field(default_factory=set)
```

---

## Callback Payloads (Dict, not Pydantic)

### Recognition Callback

```python
{
    "slotId": int,
    "mode": str,           # "INITIAL" or "RESCAN"
    "callbackType": str,   # "REGULAR" or "EXAM"
    "recognitions": [
        {
            "studentUserId": int,
            "confidence": float,
            "timestamp": str,  # "2024-11-06T10:30:00Z"
            "cameraId": int,
            "evidence": {
                "regularImageUrl": Optional[str],
                "examImageUrl": Optional[str]
            }
        }
    ]
}
```

### Session Status Callback

```python
{
    "type": "SESSION_STATUS",
    "slotId": int,
    "status": str,         # "STOPPED" or "CAMERA_DISCONNECTED"
    "reason": str,         # "ALL_CAMERAS_FAILED" or "CAMERA_FAILURE"
    "timestamp": str,
    # Optional fields:
    "activeCameras": int,
    "failedCameras": int,
    "failedCameraIds": List[int],
    "cameraId": int,
    "cameraName": str
}
```

---

## Validation Rules

### Embedding Vector

- Must be exactly 512 floats
- Validated via `Field(..., min_length=512, max_length=512)`

### Similarity Threshold

- Range: 0.0 - 1.0
- Validated via `Field(ge=0.0, le=1.0)`

### Scan Interval

- Range: 0.5 - 60 seconds
- Validated via `Field(ge=0.5, le=60)`

### Required Lists

- `students`: At least 1 student
- `cameras`: At least 1 camera
- Validated via `Field(..., min_length=1)`

---

## Error Codes

### Embedding Generation

- `PHOTO_FILE_REQUIRED` - No photo uploaded
- `INVALID_FILE_FORMAT` - Not JPG/PNG
- `PHOTO_FILE_NOT_FOUND` - File not found
- `NO_FACE_IN_PHOTO` - No face detected
- `MULTIPLE_FACES_DETECTED` - More than 1 face
- `LOW_QUALITY_FACE` - Quality < threshold
- `IMAGE_PROCESSING_FAILED` - General processing error

### Recognition Session

- `SESSION_ALREADY_EXISTS` - Session đang chạy cho slot
- `ALL_CAMERAS_FAILED` - Không connect được camera nào
- `SESSION_NOT_FOUND` - Không có session cho slot
- `STOP_SESSION_FAILED` - Lỗi khi stop session
- `INTERNAL_ERROR` - General error
