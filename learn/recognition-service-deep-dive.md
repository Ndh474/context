# 🎯 RECOGNITION SERVICE - HƯỚNG DẪN CHI TIẾT LUỒNG ĐIỂM DANH

## Mục lục

1. [Tổng quan kiến trúc](#1-tổng-quan-kiến-trúc)
2. [Luồng điểm danh chính](#2-luồng-điểm-danh-chính)
3. [Chi tiết từng bước xử lý](#3-chi-tiết-từng-bước-xử-lý)
4. [Thuật toán nhận diện khuôn mặt](#4-thuật-toán-nhận-diện-khuôn-mặt)
5. [Các chế độ điểm danh](#5-các-chế-độ-điểm-danh)
6. [Xử lý lỗi và Edge Cases](#6-xử-lý-lỗi-và-edge-cases)
7. [Cấu hình và tham số](#7-cấu-hình-và-tham-số)

---

## 1. Tổng quan kiến trúc

### 1.1. Vị trí trong hệ thống

Recognition Service là microservice Python/FastAPI, đóng vai trò **"bộ não AI"** của hệ thống FUACS:

```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────────┐
│  Frontend Web   │────▶│   Java Backend   │────▶│ Recognition Service │
│   (Next.js)     │     │  (Spring Boot)   │     │    (FastAPI)        │
│   Port: 3000    │     │   Port: 8080     │     │    Port: 8000       │
└─────────────────┘     └──────────────────┘     └─────────────────────┘
                               │                         │
                               │                         ▼
                               │                  ┌──────────────┐
                               │                  │  IP Cameras  │
                               │                  │   (RTSP)     │
                               ▼                  └──────────────┘
                        ┌──────────────┐
                        │  PostgreSQL  │
                        │  + pgvector  │
                        └──────────────┘
```

### 1.2. Nhiệm vụ chính

- **Nhận diện khuôn mặt** từ video stream IP cameras
- **So khớp** với database embeddings của sinh viên
- **Gửi kết quả** về Java Backend qua callback API
- **Lưu bằng chứng** (ảnh crop khuôn mặt)


---

## 2. Luồng điểm danh chính

### 2.1. Sequence Diagram tổng quan

```
┌──────────┐     ┌──────────────┐     ┌───────────────────┐     ┌───────────┐
│ Lecturer │     │ Java Backend │     │ Recognition Svc   │     │ IP Camera │
└────┬─────┘     └──────┬───────┘     └─────────┬─────────┘     └─────┬─────┘
     │                  │                       │                     │
     │ 1. Bấm "Bắt đầu  │                       │                     │
     │    điểm danh"    │                       │                     │
     │─────────────────▶│                       │                     │
     │                  │                       │                     │
     │                  │ 2. POST /process-session                    │
     │                  │   (students, cameras, config)               │
     │                  │──────────────────────▶│                     │
     │                  │                       │                     │
     │                  │                       │ 3. Test RTSP        │
     │                  │                       │────────────────────▶│
     │                  │                       │◀────────────────────│
     │                  │                       │                     │
     │                  │ 4. Response: OK       │                     │
     │                  │◀──────────────────────│                     │
     │                  │                       │                     │
     │ 5. UI: "Đang     │                       │ ┌─────────────────┐ │
     │    điểm danh..." │                       │ │ BACKGROUND LOOP │ │
     │◀─────────────────│                       │ │                 │ │
     │                  │                       │ │ 6. Capture frame│◀┤
     │                  │                       │ │ 7. Detect faces │ │
     │                  │                       │ │ 8. Match student│ │
     │                  │                       │ │ 9. Save evidence│ │
     │                  │ 10. Callback:         │ │                 │ │
     │                  │     recognition       │ │                 │ │
     │                  │◀──────────────────────│ │                 │ │
     │                  │                       │ └─────────────────┘ │
     │ 11. Realtime     │                       │                     │
     │     update UI    │                       │                     │
     │◀─────────────────│                       │                     │
     │                  │                       │                     │
     │ 12. Bấm "Dừng"   │                       │                     │
     │─────────────────▶│                       │                     │
     │                  │ 13. POST /stop-session│                     │
     │                  │──────────────────────▶│                     │
     │                  │                       │ 14. Cancel tasks    │
     │                  │ 15. Statistics        │     Cleanup         │
     │                  │◀──────────────────────│                     │
     │ 16. Hiển thị     │                       │                     │
     │     kết quả      │                       │                     │
     │◀─────────────────│                       │                     │
```

### 2.2. Mô tả ngắn gọn

1. **Giảng viên** bấm nút "Bắt đầu điểm danh" trên giao diện web
2. **Java Backend** gọi API `/process-session` đến Recognition Service, gửi kèm:
   - Danh sách sinh viên (kèm embedding vectors)
   - Danh sách cameras trong phòng
   - Cấu hình (ngưỡng similarity, scan interval, callback URL)
3. **Recognition Service** test kết nối tất cả cameras
4. Nếu ít nhất 1 camera OK → bắt đầu **background tasks** (1 task/camera)
5. Mỗi task chạy **vòng lặp liên tục**:
   - Capture frame từ camera
   - Detect faces trong frame
   - So khớp với embeddings sinh viên
   - Nếu match → gửi callback về Java Backend
6. **Java Backend** cập nhật database và push realtime đến frontend
7. Khi giảng viên bấm "Dừng" → gọi `/stop-session` để cleanup


---

## 3. Chi tiết từng bước xử lý

### 3.1. Bước 1: Nhận request từ Java Backend

**Endpoint**: `POST /api/v1/recognition/process-session`

**Request body** (từ Java Backend):

```json
{
  "slotId": 123,
  "roomId": 5,
  "mode": "INITIAL",
  "callbackType": "REGULAR",
  "students": [
    {
      "userId": 1001,
      "fullName": "Nguyễn Văn A",
      "rollNumber": "SE171234",
      "embeddingVector": [0.123, -0.456, 0.789, ...],  // 512 số thực
      "embeddingVersion": 1
    },
    {
      "userId": 1002,
      "fullName": "Trần Thị B",
      "rollNumber": "SE171235",
      "embeddingVector": [0.234, -0.567, 0.890, ...],
      "embeddingVersion": 1
    }
  ],
  "cameras": [
    {
      "id": 1,
      "name": "Camera Trước",
      "rtspUrl": "rtsp://admin:password@192.168.1.100:554/stream1"
    },
    {
      "id": 2,
      "name": "Camera Sau",
      "rtspUrl": "rtsp://admin:password@192.168.1.101:554/stream1"
    }
  ],
  "config": {
    "similarityThreshold": 0.55,
    "scanInterval": 3.0,
    "callbackUrl": "http://localhost:8080/api/internal/recognition/callback"
  }
}
```

**Code xử lý** (file `api/v1/recognition.py`):

```python
@router.post("/process-session", response_model=RecognitionResponse)
async def start_recognition_session(
    request: StartSessionRequest, 
    api_key: str = Depends(verify_api_key)  # Bắt buộc có API key
):
    try:
        # Gọi service để bắt đầu session
        session_data = await recognition_service.start_session(request)
        
        return RecognitionResponse(
            status=200, 
            message="Face recognition session started successfully", 
            data=session_data
        )
    except ValueError as e:
        # Session đã tồn tại cho slot này
        raise HTTPException(status_code=409, detail={
            "code": "SESSION_ALREADY_EXISTS",
            "message": f"Session already exists for slot {request.slotId}"
        })
    except RuntimeError as e:
        # Tất cả cameras đều fail
        raise HTTPException(status_code=500, detail={
            "code": "ALL_CAMERAS_FAILED",
            "message": "Failed to connect to any camera"
        })
```

### 3.2. Bước 2: Khởi tạo Session

**Code** (file `services/recognition_service.py`):

```python
async def start_session(self, request: StartSessionRequest) -> SessionDataDTO:
    slot_id = request.slotId

    # 1. Kiểm tra session đã tồn tại chưa
    existing_session = await session_manager.get_session(slot_id)
    if existing_session:
        raise ValueError(f"Session already exists for slot {slot_id}")

    # 2. Test kết nối tất cả cameras song song
    camera_results = await self._test_cameras(request.cameras)

    # 3. Đếm cameras thành công/thất bại
    active_cameras = sum(1 for r in camera_results if r["connected"])
    failed_cameras = len(camera_results) - active_cameras

    # 4. Nếu TẤT CẢ cameras fail → báo lỗi
    if active_cameras == 0:
        raise RuntimeError("All cameras failed to connect")

    # 5. Tạo thư mục lưu evidence
    evidence_dir = f"./uploads/evidence/{slot_id}"
    os.makedirs(evidence_dir, exist_ok=True)

    # 6. Tạo session state
    session_state = SessionState(
        slot_id=slot_id,
        room_id=request.roomId,
        mode=request.mode.value,
        callback_type=request.callbackType,
        total_students=len(request.students),
        active_cameras=active_cameras,
        started_at=datetime.now(pytz.timezone('Asia/Ho_Chi_Minh')),
        recognition_count=0
    )

    # 7. Lưu session vào memory
    await session_manager.add_session(slot_id, session_state)

    # 8. Khởi động background tasks cho mỗi camera đã kết nối
    for i, camera in enumerate(request.cameras):
        if camera_results[i]["connected"]:
            task_id = f"slot_{slot_id}_camera_{camera.id}"
            coro = self._process_camera(
                slot_id=slot_id,
                camera=camera,
                students=request.students,
                config=request.config
            )
            await task_manager.start_task(task_id, coro)

    return SessionDataDTO(...)
```

**Giải thích**:
- Session được lưu **in-memory** (mất khi restart service)
- Mỗi camera chạy **1 async task riêng biệt** → xử lý song song
- Chỉ cần **1 camera** kết nối thành công là có thể bắt đầu


### 3.3. Bước 3: Test kết nối Camera (RTSP)

**Code** (file `services/rtsp_handler.py`):

```python
async def test_rtsp_connection(rtsp_url: str, timeout: int = 5) -> dict:
    """
    Test kết nối RTSP và trả về thông tin camera
    """
    try:
        with RTSPHandler(rtsp_url, timeout) as handler:
            # Lấy độ phân giải
            width, height = handler.get_resolution()
            
            # Capture 5 frames để tính FPS
            frames, fps = handler.capture_frames(5)
            
            # Đo độ trễ
            latency = handler.calculate_latency()
            
            return {
                "connected": True,
                "frameRate": fps,
                "resolution": {"width": width, "height": height},
                "latency": latency,
                "stability": "stable" if fps > 10 else "unstable"
            }
    except Exception as e:
        return {
            "connected": False,
            "error": str(e)
        }
```

**RTSPHandler class**:

```python
class RTSPHandler:
    def __init__(self, rtsp_url: str, timeout: int = 5):
        self.rtsp_url = rtsp_url
        self.timeout = timeout
        self.cap = None

    def connect(self) -> bool:
        # Sử dụng OpenCV để kết nối RTSP
        self.cap = cv2.VideoCapture(self.rtsp_url, cv2.CAP_FFMPEG)
        self.cap.set(cv2.CAP_PROP_OPEN_TIMEOUT_MSEC, self.timeout * 1000)
        self.cap.set(cv2.CAP_PROP_BUFFERSIZE, 1)  # Buffer nhỏ để lấy frame mới nhất
        
        # Verify bằng cách đọc 1 frame
        ret, frame = self.cap.read()
        if not ret:
            raise RTSPConnectionError("Failed to read frame")
        
        return True
```

**Lưu ý quan trọng**:
- Sử dụng **TCP transport** cho RTSP (ổn định hơn UDP)
- Buffer size = 1 để luôn lấy **frame mới nhất** (tránh lag)
- Timeout 5 giây cho mỗi camera

### 3.4. Bước 4: Background Processing Loop

Đây là **trái tim** của hệ thống - vòng lặp xử lý liên tục cho mỗi camera:

**Code** (file `services/recognition_service.py`):

```python
async def _process_camera(self, slot_id: int, camera, students, config):
    """
    Background task xử lý 1 camera
    Chạy liên tục cho đến khi bị cancel
    """
    try:
        # Mở kết nối camera
        cap = cv2.VideoCapture(camera.rtspUrl)
        cap.set(cv2.CAP_PROP_BUFFERSIZE, 1)
        
        if not cap.isOpened():
            logger.error(f"Failed to open camera {camera.id}")
            return

        scan_interval = config.scanInterval  # VD: 3 giây
        last_scan = datetime.now(pytz.timezone('Asia/Ho_Chi_Minh'))

        while True:
            # Kiểm tra task bị cancel chưa
            if asyncio.current_task().cancelled():
                break
            
            # Kiểm tra session còn tồn tại không
            session_state = await session_manager.get_session(slot_id)
            if not session_state:
                break

            # ===== FLUSH BUFFER =====
            # Bỏ qua các frame cũ trong buffer để lấy frame mới nhất
            for _ in range(3):
                cap.grab()

            # Đọc frame
            ret, frame = cap.read()
            if not ret or frame is None:
                await asyncio.sleep(1)
                continue

            # ===== KIỂM TRA SCAN INTERVAL =====
            now = datetime.now(pytz.timezone('Asia/Ho_Chi_Minh'))
            if (now - last_scan).total_seconds() < scan_interval:
                await asyncio.sleep(0.1)
                continue

            last_scan = now

            # ===== XỬ LÝ FRAME =====
            recognitions = await face_recognizer.process_frame(
                frame=frame,
                students=students,
                similarity_threshold=config.similarityThreshold,
                slot_id=slot_id,
                camera_id=camera.id,
                recognized_students=self.recognized_students[slot_id],
                callback_type=session.callback_type
            )

            # ===== GỬI CALLBACK =====
            if recognitions:
                for recognition in recognitions:
                    student_id = recognition['studentUserId']
                    
                    # Thêm vào set đã nhận diện (deduplication)
                    self.recognized_students[slot_id].add(student_id)
                    
                    # Gửi callback về Java Backend
                    await callback_service.send_recognition(
                        callback_url=config.callbackUrl,
                        slot_id=slot_id,
                        recognition=recognition,
                        mode=session.mode,
                        callback_type=session.callback_type
                    )
                    
                    # Tăng counter
                    await session_manager.increment_recognition_count(slot_id)

            # Nghỉ ngắn để không chiếm CPU
            await asyncio.sleep(0.1)

    except asyncio.CancelledError:
        logger.info(f"Camera task cancelled: slot={slot_id}")
    finally:
        if cap:
            cap.release()  # Giải phóng camera
```

**Giải thích chi tiết**:

1. **Flush buffer**: Camera RTSP có buffer, nếu không flush sẽ xử lý frame cũ
2. **Scan interval**: Không xử lý mọi frame, chỉ xử lý theo khoảng thời gian (VD: 3 giây/lần)
3. **Deduplication**: Mỗi sinh viên chỉ được nhận diện 1 lần per session
4. **Graceful shutdown**: Khi cancel, giải phóng tài nguyên đúng cách


### 3.5. Bước 5: Nhận diện khuôn mặt trong Frame

**Code** (file `services/face_recognizer.py`):

```python
async def process_frame(
    self, 
    frame: np.ndarray,           # Ảnh BGR từ OpenCV
    students: List[Any],          # Danh sách sinh viên với embeddings
    similarity_threshold: float,  # Ngưỡng match (VD: 0.55)
    slot_id: int,
    camera_id: int,
    recognized_students: set,     # Set sinh viên đã nhận diện (deduplication)
    callback_type: str = "REGULAR"
) -> List[Dict]:
    """
    Xử lý 1 frame để nhận diện khuôn mặt
    
    Returns: Danh sách các recognition results
    """
    recognitions = []

    # ===== 1. DETECT FACES =====
    # InsightFace trả về list các face objects
    faces = self.face_app.get(frame)

    if not faces:
        return []  # Không có mặt nào trong frame

    # ===== 2. XỬ LÝ TỪNG KHUÔN MẶT =====
    for face in faces:
        # Lấy embedding 512 chiều (đã normalize)
        face_embedding = face.normed_embedding

        # ===== 3. TÌM BEST MATCH =====
        best_match = self._find_best_match(
            face_embedding, 
            students, 
            similarity_threshold
        )

        if best_match:
            student_id = best_match['userId']

            # ===== 4. DEDUPLICATION CHECK =====
            if student_id in recognized_students:
                continue  # Đã nhận diện rồi, bỏ qua

            # ===== 5. CROP VÀ LƯU EVIDENCE =====
            bbox = face.bbox.astype(int)
            x1, y1, x2, y2 = bbox
            
            # Thêm padding để ảnh đẹp hơn
            padding = 50
            h, w = frame.shape[:2]
            x1 = max(0, x1 - padding)
            y1 = max(0, y1 - padding)
            x2 = min(w, x2 + padding)
            y2 = min(h, y2 + padding)
            
            face_crop = frame[y1:y2, x1:x2]
            
            # Resize nếu quá nhỏ (tối thiểu 300x300)
            min_size = 300
            if face_crop.shape[0] < min_size or face_crop.shape[1] < min_size:
                scale = max(min_size / face_crop.shape[0], min_size / face_crop.shape[1])
                face_crop = cv2.resize(face_crop, None, fx=scale, fy=scale)

            # Lưu evidence
            evidence_path = self._save_evidence(
                face_crop, slot_id, student_id, 
                best_match["rollNumber"], callback_type
            )

            # ===== 6. TẠO RECOGNITION RESULT =====
            recognition = {
                "studentUserId": student_id,
                "confidence": best_match["similarity"],
                "timestamp": get_utc_timestamp_for_java(),
                "cameraId": camera_id,
                "evidence": {
                    "regularImageUrl": evidence_path if callback_type == "REGULAR" else None,
                    "examImageUrl": evidence_path if callback_type == "EXAM" else None
                }
            }
            recognitions.append(recognition)

    return recognitions
```

**Giải thích**:
- **InsightFace** detect tất cả khuôn mặt trong frame
- Mỗi face có `normed_embedding` (vector 512 chiều đã chuẩn hóa)
- So sánh với **TẤT CẢ** sinh viên để tìm best match
- Crop khuôn mặt + padding để lưu làm bằng chứng


---

## 4. Thuật toán nhận diện khuôn mặt

### 4.1. InsightFace và Model buffalo_l

**InsightFace** là thư viện face recognition mã nguồn mở, sử dụng deep learning.

**Model buffalo_l** bao gồm:
- **Detection**: SCRFD (Sample and Computation Redistribution for Face Detection)
  - Input: 640x640 pixels
  - Output: Bounding boxes + landmarks
- **Recognition**: ArcFace với backbone ResNet100
  - Output: Vector 512 chiều (embedding)

**Cách load model**:

```python
from insightface.app import FaceAnalysis

# Khởi tạo với auto-detect GPU/CPU
face_app = FaceAnalysis(
    name='buffalo_l',           # Tên model
    providers=['CUDAExecutionProvider', 'CPUExecutionProvider']  # GPU trước, fallback CPU
)

# Chuẩn bị model
face_app.prepare(
    ctx_id=0,           # 0 = GPU, -1 = CPU
    det_size=(640, 640) # Kích thước detection
)
```

### 4.2. Cosine Similarity - Thuật toán so khớp

**Công thức**:

```
                    A · B
similarity = ─────────────────
              ||A|| × ||B||
```

Trong đó:
- `A · B` = dot product (tích vô hướng)
- `||A||` = norm (độ dài vector)

**Ý nghĩa**:
- Kết quả từ -1 đến 1
- 1 = hoàn toàn giống nhau (cùng hướng)
- 0 = không liên quan (vuông góc)
- -1 = hoàn toàn ngược nhau

**Code implementation**:

```python
def _cosine_similarity(self, vec1: np.ndarray, vec2: np.ndarray) -> float:
    """Tính cosine similarity giữa 2 vectors"""
    dot_product = np.dot(vec1, vec2)      # Tích vô hướng
    norm1 = np.linalg.norm(vec1)          # Độ dài vector 1
    norm2 = np.linalg.norm(vec2)          # Độ dài vector 2

    if norm1 == 0 or norm2 == 0:
        return 0.0

    return dot_product / (norm1 * norm2)
```

### 4.3. Tìm Best Match

**Code**:

```python
def _find_best_match(
    self, 
    face_embedding: np.ndarray,  # Embedding từ camera (512-dim)
    students: List[Any],          # Danh sách sinh viên
    threshold: float              # Ngưỡng (VD: 0.55)
) -> Optional[Dict]:
    """
    Tìm sinh viên khớp nhất với khuôn mặt detected
    """
    best_match = None
    best_similarity = 0

    # So sánh với TẤT CẢ sinh viên
    for student in students:
        student_embedding = np.array(student.embeddingVector)

        # Kiểm tra dimension
        if face_embedding.shape[0] != student_embedding.shape[0]:
            continue  # Skip nếu không khớp dimension

        # Tính similarity
        similarity = self._cosine_similarity(face_embedding, student_embedding)

        # Cập nhật best match
        if similarity > best_similarity:
            best_similarity = similarity
            
            # Chỉ chấp nhận nếu vượt ngưỡng
            if similarity >= threshold:
                best_match = {
                    "userId": student.userId,
                    "fullName": student.fullName,
                    "rollNumber": student.rollNumber,
                    "similarity": float(similarity),
                }

    return best_match
```

### 4.4. Ngưỡng Similarity (Threshold)

**Ý nghĩa các mức ngưỡng**:

```
┌─────────────┬─────────────────────────────────────────────────────┐
│   Ngưỡng    │                      Ý nghĩa                        │
├─────────────┼─────────────────────────────────────────────────────┤
│    0.40     │ Rất thấp - nhiều false positive (nhận nhầm)         │
│    0.50     │ Thấp - có thể nhận nhầm người giống nhau            │
│    0.55     │ Mặc định - cân bằng giữa accuracy và recall         │
│    0.60     │ Cao - ít false positive, có thể miss một số người   │
│    0.70     │ Rất cao - chỉ match khi rất chắc chắn               │
└─────────────┴─────────────────────────────────────────────────────┘
```

**Cách chọn ngưỡng**:
- **Điểm danh thường**: 0.55 (cân bằng)
- **Thi cử**: 0.60-0.65 (nghiêm ngặt hơn)
- **Môi trường ánh sáng kém**: 0.50 (nới lỏng)


---

## 5. Các chế độ điểm danh

### 5.1. Scan Mode: INITIAL vs RESCAN

**INITIAL** (Lần đầu):
- Quét tất cả sinh viên trong lớp
- Mục đích: Điểm danh ban đầu

**RESCAN** (Quét lại):
- Chỉ quét những sinh viên **chưa có mặt** từ lần INITIAL
- Mục đích: Cho sinh viên đến muộn cơ hội điểm danh

```python
class ScanMode(str, Enum):
    INITIAL = "INITIAL"
    RESCAN = "RESCAN"
```

**Luồng sử dụng**:

```
1. Giảng viên bắt đầu điểm danh (INITIAL)
   → Quét 5 phút
   → Kết quả: 25/30 sinh viên có mặt

2. Giảng viên bấm "Quét lại" (RESCAN)
   → Java Backend gửi request với mode=RESCAN
   → Chỉ gửi 5 sinh viên chưa có mặt
   → Quét thêm 2 phút
   → Kết quả: Thêm 3 sinh viên
```

### 5.2. Callback Type: REGULAR vs EXAM

**REGULAR** (Điểm danh thường):
- Dùng cho buổi học bình thường
- Callback route đến bảng `lecture_attendance`
- Evidence lưu vào `regularImageUrl`

**EXAM** (Điểm danh thi):
- Dùng cho buổi thi
- Callback route đến bảng `exam_attendance`
- Evidence lưu vào `examImageUrl`
- Thường có ngưỡng similarity cao hơn

```python
# Trong recognition result
recognition = {
    "studentUserId": student_id,
    "confidence": 0.87,
    "evidence": {
        # Chỉ 1 trong 2 có giá trị, tùy callback_type
        "regularImageUrl": "http://.../evidence/123/1001_SE171234.jpg",
        "examImageUrl": None
    }
}
```

### 5.3. Callback Format gửi về Java Backend

**Endpoint**: `POST {callbackUrl}` (VD: `http://localhost:8080/api/internal/recognition/callback`)

**Headers**:
```
Content-Type: application/json
X-API-Key: python-service-secret-key-12345
```

**Request Body**:

```json
{
  "slotId": 123,
  "mode": "INITIAL",
  "callbackType": "REGULAR",
  "recognitions": [
    {
      "studentUserId": 1001,
      "confidence": 0.87,
      "timestamp": "2024-12-08T10:30:00Z",
      "cameraId": 1,
      "evidence": {
        "regularImageUrl": "http://localhost:8000/uploads/evidence/123/1001_SE171234.jpg",
        "examImageUrl": null
      }
    }
  ]
}
```

**Code gửi callback**:

```python
async def send_recognition(
    self,
    callback_url: str,
    slot_id: int,
    recognition: Dict[str, Any],
    mode: str = "INITIAL",
    callback_type: str = "REGULAR"
) -> bool:
    headers = {
        "Content-Type": "application/json",
        "X-API-Key": settings.API_KEY
    }

    body = {
        "slotId": slot_id,
        "mode": mode,
        "callbackType": callback_type,
        "recognitions": [recognition]
    }

    # Retry logic với exponential backoff
    for attempt in range(3):
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
        except Exception as e:
            logger.warning(f"Callback failed: attempt {attempt + 1}")
        
        # Exponential backoff: 1s, 2s, 4s
        await asyncio.sleep(self.retry_delay * (2 ** attempt))

    return False
```


---

## 6. Xử lý lỗi và Edge Cases

### 6.1. Camera Connection Failures

**Tình huống**: Một số cameras không kết nối được

**Xử lý**:
- Test tất cả cameras **song song** (parallel)
- Nếu **ít nhất 1 camera** OK → bắt đầu session
- Nếu **TẤT CẢ cameras** fail → báo lỗi, không bắt đầu

```python
async def _test_cameras(self, cameras) -> List[Dict]:
    """Test tất cả cameras song song"""
    tasks = [test_rtsp_connection(cam.rtspUrl) for cam in cameras]
    results = await asyncio.gather(*tasks, return_exceptions=True)
    
    camera_results = []
    for i, result in enumerate(results):
        if isinstance(result, Exception):
            camera_results.append({"connected": False, "error": str(result)})
            logger.warning(f"Camera {cameras[i].name} failed: {result}")
        else:
            camera_results.append(result)
    
    return camera_results
```

### 6.2. Callback Failures và Auto-Stop

**Tình huống**: Java Backend không phản hồi (down, network issue)

**Xử lý**:
- Retry 3 lần với exponential backoff (1s → 2s → 4s)
- Nếu **10 callbacks liên tiếp** fail → auto-stop session
- Nếu **2 phút** không có callback thành công → auto-stop session

```python
# Trong _process_camera()
MAX_CONSECUTIVE_FAILURES = 10
MAX_FAILURE_DURATION = 120  # 2 phút

async def _should_auto_stop(self, slot_id: int) -> bool:
    # Kiểm tra số lần fail liên tiếp
    failures = self.callback_failures.get(slot_id, 0)
    if failures >= MAX_CONSECUTIVE_FAILURES:
        return True
    
    # Kiểm tra thời gian từ lần thành công cuối
    last_success = self.last_success_time.get(slot_id)
    if last_success:
        duration = (datetime.now() - last_success).seconds
        if duration >= MAX_FAILURE_DURATION:
            return True
    
    return False
```

### 6.3. Deduplication - Tránh điểm danh trùng

**Tình huống**: Sinh viên xuất hiện nhiều lần trong camera

**Xử lý**:
- Mỗi session có 1 **Set** lưu student IDs đã nhận diện
- Trước khi gửi callback, kiểm tra student đã trong Set chưa
- Nếu đã có → skip, không gửi callback

```python
# Khởi tạo
self.recognized_students: Dict[int, set] = {}  # slot_id -> set(student_ids)

# Trong process_frame()
if student_id in recognized_students:
    logger.debug(f"Student {student_id} already recognized, skipping")
    continue

# Sau khi gửi callback thành công
self.recognized_students[slot_id].add(student_id)
```

### 6.4. Session Already Exists

**Tình huống**: Gọi start session khi session đã đang chạy

**Xử lý**: Trả về HTTP 409 Conflict

```python
existing_session = await session_manager.get_session(slot_id)
if existing_session:
    raise HTTPException(
        status_code=409,
        detail={
            "code": "SESSION_ALREADY_EXISTS",
            "message": f"Session already exists for slot {slot_id}"
        }
    )
```

### 6.5. Frame Capture Failures

**Tình huống**: Camera bị ngắt kết nối giữa chừng

**Xử lý**:
- Log warning và retry sau 1 giây
- Không crash task, tiếp tục vòng lặp

```python
ret, frame = cap.read()
if not ret or frame is None:
    logger.warning(f"Failed to read frame from camera {camera.id}")
    await asyncio.sleep(1)
    continue  # Thử lại
```

### 6.6. No Face Detected

**Tình huống**: Frame không có khuôn mặt nào

**Xử lý**: Đơn giản return empty list, không log (tránh spam)

```python
faces = self.face_app.get(frame)
if not faces:
    return []  # Không có mặt, return rỗng
```


---

## 7. Cấu hình và tham số

### 7.1. Environment Variables

File `.env` trong `recognition-service/`:

```bash
# ===== SERVICE IDENTITY =====
SERVICE_NAME=FUACS Face Recognition Service
SERVICE_VERSION=1.0.0

# ===== SECURITY =====
# API Key dùng chung giữa Java Backend và Python Service
API_KEY=python-service-secret-key-12345

# ===== JAVA BACKEND INTEGRATION =====
JAVA_BACKEND_URL=http://localhost:8080

# ===== INSIGHTFACE MODEL =====
MODEL_NAME=buffalo_l
MODEL_PATH=./src/recognition_service/models/insightface

# ===== SERVER =====
HOST=0.0.0.0          # Bind tất cả interfaces
PORT=8000
PUBLIC_HOST=localhost  # Hostname cho URL generation (evidence images)
LOG_LEVEL=INFO

# ===== RECOGNITION SETTINGS =====
DEFAULT_SIMILARITY_THRESHOLD=0.55   # Ngưỡng match mặc định
MAX_SCAN_INTERVAL=60                # Tối đa 60 giây giữa các scan
EVIDENCE_RETENTION_DAYS=30          # Giữ evidence 30 ngày

# ===== CALLBACK SETTINGS =====
CALLBACK_TIMEOUT=30                 # Timeout 30 giây
CALLBACK_RETRY_ATTEMPTS=3           # Retry 3 lần

# ===== EMBEDDING GENERATION =====
EMBEDDING_QUALITY_THRESHOLD=0.50    # Ngưỡng chất lượng tối thiểu
```

### 7.2. Request Parameters chi tiết

#### StartSessionRequest

```python
class StartSessionRequest(BaseModel):
    slotId: int                    # ID của slot (buổi học/thi)
    roomId: int                    # ID phòng học
    mode: ScanMode                 # INITIAL hoặc RESCAN
    callbackType: str              # "REGULAR" hoặc "EXAM"
    students: List[StudentDTO]     # Danh sách sinh viên (min 1)
    cameras: List[CameraDTO]       # Danh sách cameras (min 1)
    config: SessionConfigDTO       # Cấu hình session
```

#### SessionConfigDTO

```python
class SessionConfigDTO(BaseModel):
    similarityThreshold: float = 0.55   # Ngưỡng match (0.0 - 1.0)
    scanInterval: float = 1.5           # Giây giữa các scan (0.5 - 60)
    callbackUrl: str                    # URL callback về Java Backend
```

**Giải thích các tham số**:

- **similarityThreshold**: 
  - Giá trị từ 0.0 đến 1.0
  - Càng cao → càng nghiêm ngặt, ít false positive nhưng có thể miss
  - Càng thấp → càng dễ match, nhiều false positive
  - Recommend: 0.55 cho điểm danh thường, 0.60-0.65 cho thi

- **scanInterval**:
  - Khoảng thời gian (giây) giữa các lần xử lý frame
  - Giá trị nhỏ (0.5s) → phản hồi nhanh, tốn CPU/GPU
  - Giá trị lớn (5s) → tiết kiệm tài nguyên, phản hồi chậm
  - Recommend: 1.5-3 giây cho điểm danh thường

- **callbackUrl**:
  - URL endpoint của Java Backend để nhận kết quả
  - Format: `http://{host}:{port}/api/internal/recognition/callback`

#### StudentEmbeddingDTO

```python
class StudentEmbeddingDTO(BaseModel):
    userId: int                              # ID user trong database
    fullName: str                            # Họ tên đầy đủ
    rollNumber: str                          # Mã số sinh viên (VD: SE171234)
    embeddingVector: List[float]             # Vector 512 chiều
    embeddingVersion: int                    # Version của embedding
```

#### CameraDTO

```python
class CameraDTO(BaseModel):
    id: int                    # ID camera trong database
    name: str                  # Tên camera (VD: "Camera Trước")
    rtspUrl: str               # URL RTSP stream
```

**Format RTSP URL**:
```
rtsp://{username}:{password}@{ip}:{port}/{path}

Ví dụ:
rtsp://admin:Admin123@192.168.1.100:554/Streaming/Channels/101
```

### 7.3. Response Format

#### Khi start session thành công

```json
{
  "status": 200,
  "message": "Face recognition session started successfully",
  "data": {
    "slotId": 123,
    "roomId": 5,
    "mode": "INITIAL",
    "totalStudents": 30,
    "totalCameras": 2,
    "activeCameras": 2,
    "failedCameras": 0,
    "sessionStartedAt": "2024-12-08T10:00:00Z"
  }
}
```

#### Khi stop session

```json
{
  "status": 200,
  "message": "Face recognition session stopped successfully",
  "data": {
    "slotId": 123,
    "roomId": 5,
    "mode": "INITIAL",
    "totalStudents": 30,
    "totalCameras": 2,
    "activeCameras": 2,
    "failedCameras": 0,
    "sessionStartedAt": "2024-12-08T10:00:00Z",
    "sessionStoppedAt": "2024-12-08T10:15:00Z",
    "sessionDuration": 900,
    "totalRecognitions": 28,
    "recognizedStudentIds": [1001, 1002, 1003, ...]
  }
}
```

### 7.4. Hardware Auto-Detection

Service tự động detect GPU/CPU và cấu hình phù hợp:

```python
class HardwareDetector:
    @staticmethod
    def detect_nvidia_gpu() -> bool:
        """Kiểm tra có NVIDIA GPU không"""
        try:
            result = subprocess.run(["nvidia-smi"], capture_output=True)
            return result.returncode == 0
        except FileNotFoundError:
            return False

    @staticmethod
    def detect_cuda() -> bool:
        """Kiểm tra CUDA có sẵn không"""
        cuda_path = os.environ.get("CUDA_PATH")
        return cuda_path and os.path.exists(cuda_path)

    @classmethod
    def get_optimal_config(cls) -> Dict:
        has_gpu = cls.detect_nvidia_gpu()
        has_cuda = cls.detect_cuda()

        if has_gpu and has_cuda:
            return {
                "device_type": "gpu",
                "providers": ["CUDAExecutionProvider", "CPUExecutionProvider"],
                "ctx_id": 0,  # GPU device 0
            }
        else:
            return {
                "device_type": "cpu",
                "providers": ["CPUExecutionProvider"],
                "ctx_id": -1,  # CPU
            }
```

**Hiệu năng**:
- **GPU (CUDA)**: ~50-100ms per frame
- **CPU**: ~500-1000ms per frame
- GPU nhanh hơn **~10 lần**


---

## 8. Luồng đăng ký khuôn mặt (Embedding Generation)

### 8.1. Tổng quan

Trước khi điểm danh được, sinh viên cần **đăng ký khuôn mặt** để tạo embedding vector lưu vào database.

```
┌──────────┐     ┌──────────────┐     ┌───────────────────┐
│ Student  │     │ Java Backend │     │ Recognition Svc   │
└────┬─────┘     └──────┬───────┘     └─────────┬─────────┘
     │                  │                       │
     │ 1. Upload ảnh    │                       │
     │─────────────────▶│                       │
     │                  │                       │
     │                  │ 2. POST /embeddings/generate
     │                  │    (photo file)       │
     │                  │──────────────────────▶│
     │                  │                       │
     │                  │                       │ 3. Detect face
     │                  │                       │ 4. Extract embedding
     │                  │                       │ 5. Calculate quality
     │                  │                       │
     │                  │ 6. Response:          │
     │                  │    embedding vector   │
     │                  │◀──────────────────────│
     │                  │                       │
     │                  │ 7. Save to PostgreSQL │
     │                  │    (pgvector)         │
     │                  │                       │
     │ 8. Success       │                       │
     │◀─────────────────│                       │
```

### 8.2. API Endpoint

**Endpoint**: `POST /api/v1/embeddings/generate`

**Request**: `multipart/form-data`
- `photo`: File ảnh (JPG/PNG)
- `submissionId`: ID của identity submission

**Response**:

```json
{
  "status": 200,
  "message": "Face embedding generated successfully",
  "data": {
    "submissionId": 456,
    "embeddingVector": [0.123, -0.456, 0.789, ...],  // 512 số
    "quality": 0.85,
    "faceDetected": true,
    "processingTime": 0.45
  }
}
```

### 8.3. Quality Metrics

Hệ thống tính **4 metrics** để đánh giá chất lượng ảnh:

```python
class QualityAnalyzer:
    def calculate_metrics(self, frame, face) -> dict:
        # 1. FACE SIZE (30% weight)
        # Tỷ lệ khuôn mặt so với frame
        # Target: >= 20% diện tích frame
        face_area = (x2 - x1) * (y2 - y1)
        frame_area = frame_h * frame_w
        face_size_score = min(face_area / frame_area / 0.20, 1.0)

        # 2. CLARITY (25% weight)
        # Độ sắc nét (Laplacian variance)
        gray = cv2.cvtColor(face_crop, cv2.COLOR_BGR2GRAY)
        laplacian_var = cv2.Laplacian(gray, cv2.CV_64F).var()
        clarity_score = min(laplacian_var / 500.0, 1.0)

        # 3. LIGHTING (25% weight)
        # Độ sáng + contrast
        brightness = np.mean(gray)  # Ideal: 100-150
        contrast = np.std(gray)     # Ideal: > 40
        brightness_score = 1.0 - abs(brightness - 125) / 125
        contrast_score = min(contrast / 50.0, 1.0)
        lighting_score = (brightness_score + contrast_score) / 2

        # 4. FACE ANGLE (20% weight)
        # Độ chính diện (dùng detection confidence)
        face_angle_score = min(face.det_score, 1.0)

        return {
            "faceSize": face_size_score,
            "clarity": clarity_score,
            "lighting": lighting_score,
            "faceAngle": face_angle_score
        }

    def calculate_overall_quality(self, metrics) -> float:
        weights = {
            "faceSize": 0.30,
            "clarity": 0.25,
            "lighting": 0.25,
            "faceAngle": 0.20
        }
        return sum(metrics[k] * weights[k] for k in weights)
```

**Ngưỡng chất lượng**: `>= 0.50` (có thể cấu hình)

### 8.4. Các lỗi có thể xảy ra

```python
# 1. Không detect được mặt
class FaceNotDetectedError(Exception):
    code = "NO_FACE_IN_PHOTO"
    message = "No face detected in the provided photo."

# 2. Nhiều hơn 1 mặt
class FaceNotDetectedError(Exception):
    code = "MULTIPLE_FACES_DETECTED"
    message = "Multiple faces detected. Please ensure only one person is in the photo."

# 3. Chất lượng quá thấp
class LowQualityError(Exception):
    code = "LOW_QUALITY_FACE"
    message = "Face quality too low. Please take photo in better lighting."
```

---

## 9. Evidence Storage (Lưu bằng chứng)

### 9.1. Cấu trúc thư mục

```
uploads/
└── evidence/
    ├── 123/                          # slot_id
    │   ├── 1001_SE171234.jpg        # user_id_rollNumber.jpg
    │   ├── 1002_SE171235.jpg
    │   └── 1003_SE171236_exam.jpg   # Có postfix _exam cho thi
    └── 124/
        └── ...
```

### 9.2. URL Format

```
http://{PUBLIC_HOST}:{PORT}/uploads/evidence/{slot_id}/{user_id}_{roll_number}.jpg

Ví dụ:
http://localhost:8000/uploads/evidence/123/1001_SE171234.jpg
```

### 9.3. Code lưu evidence

```python
def _save_evidence(self, face_crop, slot_id, user_id, roll_number, callback_type):
    # Tạo filename
    if callback_type == "EXAM":
        filename = f"{user_id}_{roll_number}_exam.jpg"
    else:
        filename = f"{user_id}_{roll_number}.jpg"

    # Tạo thư mục
    evidence_dir = f"./uploads/evidence/{slot_id}"
    os.makedirs(evidence_dir, exist_ok=True)

    # Lưu ảnh với chất lượng cao nhất
    filepath = os.path.join(evidence_dir, filename)
    cv2.imwrite(filepath, face_crop, [cv2.IMWRITE_JPEG_QUALITY, 100])

    # Trả về URL đầy đủ
    settings = get_settings()
    base_url = f"http://{settings.PUBLIC_HOST}:{settings.PORT}"
    return f"{base_url}/uploads/evidence/{slot_id}/{filename}"
```

---

## 10. Tổng kết - Điểm quan trọng khi bảo vệ

### 10.1. Kiến trúc
- Microservice độc lập, giao tiếp qua REST API
- Async/await cho tất cả I/O operations
- Singleton pattern cho các services

### 10.2. Thuật toán
- **InsightFace** với model **buffalo_l** (ArcFace + SCRFD)
- Embedding **512 chiều**
- **Cosine similarity** để so khớp
- Ngưỡng mặc định **0.55**

### 10.3. Xử lý song song
- Mỗi camera chạy **1 async task riêng**
- Test cameras **parallel** khi start session
- Không block main thread

### 10.4. Độ tin cậy
- **Deduplication**: Mỗi sinh viên chỉ điểm danh 1 lần/session
- **Retry logic**: 3 lần với exponential backoff
- **Auto-stop**: Tự dừng khi backend không phản hồi
- **Graceful shutdown**: Cleanup đúng cách khi stop

### 10.5. Bảo mật
- **API Key authentication** cho tất cả protected endpoints
- Shared secret giữa Java Backend và Python Service

### 10.6. Hiệu năng
- **GPU**: ~50-100ms/frame (recommend)
- **CPU**: ~500-1000ms/frame
- Scan interval có thể điều chỉnh (0.5s - 60s)

---

## 11. Câu hỏi thường gặp khi bảo vệ

**Q: Tại sao chọn InsightFace thay vì các thư viện khác?**
- Open source, miễn phí
- Accuracy cao (state-of-the-art)
- Hỗ trợ cả GPU và CPU
- Model buffalo_l đã được train trên dataset lớn

**Q: Cosine similarity hoạt động như thế nào?**
- Đo góc giữa 2 vectors trong không gian 512 chiều
- Giá trị 1 = hoàn toàn giống, 0 = không liên quan
- Không phụ thuộc vào độ dài vector (đã normalize)

**Q: Làm sao xử lý khi nhiều sinh viên xuất hiện cùng lúc?**
- InsightFace detect TẤT CẢ faces trong frame
- Xử lý từng face một cách độc lập
- Mỗi face được so khớp với toàn bộ database

**Q: Tại sao cần deduplication?**
- Sinh viên có thể xuất hiện nhiều lần trong camera
- Tránh gửi nhiều callbacks cho cùng 1 người
- Tiết kiệm bandwidth và database operations

**Q: Làm sao đảm bảo lấy frame mới nhất từ camera?**
- Set buffer size = 1
- Flush buffer trước khi đọc frame
- Sử dụng TCP transport cho RTSP (ổn định hơn UDP)

**Q: Tại sao session lưu in-memory thay vì database?**
- Performance: Không cần query database mỗi frame
- Simplicity: Không cần sync state
- Trade-off: Mất session khi restart (acceptable cho use case này)
