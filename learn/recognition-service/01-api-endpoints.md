# Recognition Service - API Endpoints

## Authentication

Tất cả protected endpoints yêu cầu header:
```
X-API-Key: {API_KEY from .env}
```

## Endpoints Summary

### Public Endpoints
- `GET /api/v1/health` → Health check

### Protected Endpoints
- `GET /api/v1/metrics` → Performance metrics
- `GET /api/v1/cameras/test-connection` → Test RTSP camera
- `GET /api/v1/cameras/capture-frame` → Capture single frame
- `POST /api/v1/embeddings/generate` → Generate face embedding
- `POST /api/v1/recognition/process-session` → Start recognition session
- `POST /api/v1/recognition/stop-session` → Stop recognition session

---

## GET /api/v1/health

**File**: `api/v1/health.py`
**Auth**: None (public)

**Response**:
```json
{
  "status": 200,
  "message": "Service is healthy",
  "data": {
    "service": "FUACS Face Recognition Service",
    "version": "1.0.0",
    "status": "healthy",
    "uptime": 3600,
    "activeSessions": 2,
    "timestamp": "2024-10-28T10:00:00Z"
  }
}
```

---

## GET /api/v1/cameras/test-connection

**File**: `api/v1/cameras.py`
**Auth**: Required

**Query Params**:
- `rtspUrl` (required): RTSP stream URL (must start with `rtsp://`)
- `timeout` (optional): 1-30 seconds, default 10

**Response**:
```json
{
  "status": 200,
  "message": "Camera connection successful",
  "data": {
    "rtspUrl": "rtsp://...",
    "connected": true,
    "frameRate": 25.5,
    "resolution": {"width": 1920, "height": 1080},
    "latency": 45,
    "stability": "stable",
    "testedAt": "2024-10-28T10:00:00Z"
  }
}
```

---

## GET /api/v1/cameras/capture-frame

**File**: `api/v1/cameras.py`
**Auth**: Required

**Query Params**:
- `rtspUrl` (required): RTSP stream URL
- `format`: "base64" (default) hoặc "file"
- `timeout`: 1-30 seconds, default 10

**Response** (format=base64):
```json
{
  "status": 200,
  "message": "Frame captured successfully",
  "data": {
    "rtspUrl": "rtsp://...",
    "format": "base64",
    "image": "data:image/jpeg;base64,...",
    "resolution": {"width": 1920, "height": 1080},
    "capturedAt": "2024-10-28T10:00:00Z"
  }
}
```

---

## POST /api/v1/embeddings/generate

**File**: `api/v1/embeddings.py`
**Auth**: Required
**Content-Type**: multipart/form-data

**Form Fields**:
- `photo` (file, required): Face photo (JPG/PNG)
- `submissionId` (int, required): Identity submission ID

**Success Response**:
```json
{
  "status": 200,
  "message": "Face embedding generated successfully",
  "data": {
    "submissionId": 123,
    "embeddingVector": [0.123, -0.456, ...],  // 512 floats
    "quality": 0.85,
    "faceDetected": true,
    "processingTime": 1.23
  }
}
```

**Error Codes**:
- `PHOTO_FILE_REQUIRED` → No photo uploaded
- `INVALID_FILE_FORMAT` → Not JPG/PNG
- `NO_FACE_IN_PHOTO` → No face detected
- `MULTIPLE_FACES_DETECTED` → More than 1 face
- `LOW_QUALITY_FACE` → Quality < threshold (0.50)

---

## POST /api/v1/recognition/process-session

**File**: `api/v1/recognition.py`
**Auth**: Required

**Request Body**:
```json
{
  "slotId": 123,
  "roomId": 456,
  "mode": "INITIAL",  // or "RESCAN"
  "callbackType": "REGULAR",  // or "EXAM"
  "students": [
    {
      "userId": 1,
      "fullName": "Nguyen Van A",
      "rollNumber": "SE123456",
      "embeddingVector": [0.123, -0.456, ...],  // 512 floats
      "embeddingVersion": 1
    }
  ],
  "cameras": [
    {
      "id": 1,
      "name": "Camera 1",
      "rtspUrl": "rtsp://192.168.1.100:554/stream"
    }
  ],
  "config": {
    "similarityThreshold": 0.55,
    "scanInterval": 1.5,
    "callbackUrl": "http://localhost:8080/api/internal/recognition/callback"
  }
}
```

**Success Response**:
```json
{
  "status": 200,
  "message": "Face recognition session started successfully",
  "data": {
    "slotId": 123,
    "roomId": 456,
    "mode": "INITIAL",
    "totalStudents": 30,
    "totalCameras": 2,
    "activeCameras": 2,
    "failedCameras": 0,
    "sessionStartedAt": "2024-10-28T10:00:00Z"
  }
}
```

**Error Codes**:
- `SESSION_ALREADY_EXISTS` (409) → Session đang chạy cho slot này
- `ALL_CAMERAS_FAILED` (500) → Không connect được camera nào

---

## POST /api/v1/recognition/stop-session

**File**: `api/v1/recognition.py`
**Auth**: Required

**Request Body**:
```json
{
  "slotId": 123
}
```

**Success Response**:
```json
{
  "status": 200,
  "message": "Face recognition session stopped successfully",
  "data": {
    "slotId": 123,
    "roomId": 456,
    "mode": "INITIAL",
    "totalStudents": 30,
    "totalCameras": 2,
    "activeCameras": 2,
    "failedCameras": 0,
    "sessionStoppedAt": "2024-10-28T10:30:00Z",
    "sessionDuration": 1800,
    "totalRecognitions": 25,
    "recognizedStudentIds": [1, 2, 3, ...]  // For RESCAN mode
  }
}
```

**Error Codes**:
- `SESSION_NOT_FOUND` (404) → Không có session nào cho slot này
