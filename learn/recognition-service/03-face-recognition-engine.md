# Recognition Service - Face Recognition Engine

## InsightFace Model

### Model Details

- **Model Name**: buffalo_l
- **Detection**: SCRFD (640x640 input)
- **Recognition**: ArcFace ResNet100
- **Embedding Dimension**: 512 (float32)
- **Model Size**: ~600MB
- **Download Path**: `~/.insightface/models/buffalo_l/`

### Model Loading

**File**: `services/model_loader.py`

```python
from insightface.app import FaceAnalysis

# Load với hardware auto-detection
face_app = FaceAnalysis(name='buffalo_l', providers=onnx_providers)
face_app.prepare(ctx_id=ctx_id, det_size=(640, 640))
```

- Model loaded once trong `lifespan` manager
- Reused globally qua singleton pattern
- ~600MB RAM usage

### Hardware Auto-Detection

**File**: `core/hardware.py`

```python
class HardwareDetector:
    @staticmethod
    def detect_nvidia_gpu() -> bool:
        # Check nvidia-smi command
        
    @staticmethod
    def detect_cuda() -> bool:
        # Check CUDA_PATH env or nvcc command
        
    @classmethod
    def get_optimal_config(cls) -> Dict:
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

**Helper Functions**:
- `get_onnx_providers()` → List of ONNX providers
- `get_insightface_ctx_id()` → Context ID for InsightFace
- `get_device_info()` → Human-readable device name

## Face Detection & Matching

### FaceRecognizer Class

**File**: `services/face_recognizer.py`

```python
class FaceRecognizer:
    def __init__(self):
        self.face_app = None
        self._init_model()
    
    async def process_frame(
        self,
        frame: np.ndarray,
        students: List[StudentDTO],
        similarity_threshold: float,
        slot_id: int,
        camera_id: int,
        recognized_students: set,
        callback_type: str = "REGULAR"
    ) -> List[Dict]:
        # 1. Detect faces
        faces = self.face_app.get(frame)
        
        # 2. For each face, find best match
        for face in faces:
            face_embedding = face.normed_embedding  # 512-dim
            best_match = self._find_best_match(face_embedding, students, threshold)
            
            if best_match and student_id not in recognized_students:
                # Crop face, save evidence, return result
```

### Cosine Similarity

**Formula**: `similarity = dot(vec1, vec2) / (norm(vec1) * norm(vec2))`

```python
def _cosine_similarity(self, vec1: np.ndarray, vec2: np.ndarray) -> float:
    dot_product = np.dot(vec1, vec2)
    norm1 = np.linalg.norm(vec1)
    norm2 = np.linalg.norm(vec2)
    
    if norm1 == 0 or norm2 == 0:
        return 0.0
    
    return dot_product / (norm1 * norm2)
```

### Matching Strategy

```python
def _find_best_match(self, face_embedding, students, threshold) -> Optional[Dict]:
    best_match = None
    best_similarity = 0
    
    for student in students:
        student_embedding = np.array(student.embeddingVector)
        similarity = self._cosine_similarity(face_embedding, student_embedding)
        
        if similarity > best_similarity:
            best_similarity = similarity
            if similarity >= threshold:
                best_match = {
                    "userId": student.userId,
                    "fullName": student.fullName,
                    "rollNumber": student.rollNumber,
                    "similarity": float(similarity),
                }
    
    return best_match
```

**Threshold Configuration**:
- Default: 0.55 (from .env `DEFAULT_SIMILARITY_THRESHOLD`)
- Per-session override: passed in `config.similarityThreshold`
- Lower = more permissive, Higher = more strict

## Evidence Image Handling

### Face Cropping

```python
# Get bounding box
bbox = face.bbox.astype(int)
x1, y1, x2, y2 = bbox

# Add padding (50px) for better context
padding = 50
h, w = frame.shape[:2]
x1 = max(0, x1 - padding)
y1 = max(0, y1 - padding)
x2 = min(w, x2 + padding)
y2 = min(h, y2 + padding)

face_crop = frame[y1:y2, x1:x2]

# Ensure minimum size 300x300
min_size = 300
if crop_h < min_size or crop_w < min_size:
    scale = max(min_size / crop_h, min_size / crop_w)
    face_crop = cv2.resize(face_crop, (new_w, new_h), interpolation=cv2.INTER_LANCZOS4)
```

### Evidence Storage

```python
def _save_evidence(self, face_crop, slot_id, user_id, roll_number, callback_type):
    # Filename based on callback type
    if callback_type == "EXAM":
        filename = f"{user_id}_{roll_number}_exam.jpg"
    else:
        filename = f"{user_id}_{roll_number}.jpg"
    
    # Directory: ./uploads/evidence/{slot_id}/
    evidence_dir = f"./uploads/evidence/{slot_id}"
    os.makedirs(evidence_dir, exist_ok=True)
    
    filepath = os.path.join(evidence_dir, filename)
    
    # Save with max quality
    cv2.imwrite(filepath, face_crop, [cv2.IMWRITE_JPEG_QUALITY, 100])
    
    # Return full URL
    base_url = f"http://{settings.PUBLIC_HOST}:{settings.PORT}"
    return f"{base_url}/uploads/evidence/{slot_id}/{filename}"
```

**Evidence URL Format**:
- `http://{PUBLIC_HOST}:{PORT}/uploads/evidence/{slot_id}/{user_id}_{roll_number}.jpg`
- `http://{PUBLIC_HOST}:{PORT}/uploads/evidence/{slot_id}/{user_id}_{roll_number}_exam.jpg`

## Embedding Generation

### EmbeddingGenerator Class

**File**: `services/embedding_generator.py`

```python
class EmbeddingGenerator:
    def __init__(self):
        self.face_encoder = FaceEncoder()
        self.quality_analyzer = QualityAnalyzer()
        self.file_handler = FileHandler()
    
    async def generate_embedding_from_photo(self, photo_path, submission_id) -> Dict:
        # 1. Load photo
        photo_frame = await self.file_handler.load_image(photo_path)
        
        # 2. Detect faces
        faces = self.face_encoder.detect_faces(photo_frame)
        
        # 3. Validate
        if len(faces) == 0:
            raise FaceNotDetectedError("NO_FACE_IN_PHOTO")
        if len(faces) > 1:
            raise FaceNotDetectedError("MULTIPLE_FACES_DETECTED")
        
        # 4. Extract embedding
        embedding = faces[0].embedding  # 512-dim
        
        # 5. Calculate quality
        metrics = self.quality_analyzer.calculate_metrics(photo_frame, faces[0])
        quality = self.quality_analyzer.calculate_overall_quality(metrics)
        
        # 6. Validate quality
        if quality < EMBEDDING_QUALITY_THRESHOLD:
            raise LowQualityError(quality)
        
        return {
            "submissionId": submission_id,
            "embeddingVector": embedding.tolist(),
            "quality": round(quality, 2),
            "faceDetected": True,
        }
```

### Quality Metrics

**File**: `services/quality_analyzer.py`

4 metrics được tính:

1. **Face Size** (30% weight):
   - % of frame occupied by face
   - Target: >= 20% of frame
   
2. **Clarity** (25% weight):
   - Laplacian variance for sharpness
   - Threshold: 500 is good
   
3. **Lighting** (25% weight):
   - Brightness (ideal: 100-150/255)
   - Contrast (ideal: > 40)
   
4. **Face Angle** (20% weight):
   - Detection confidence as proxy
   - Higher det_score = more frontal

```python
def calculate_overall_quality(self, metrics: dict) -> float:
    weights = {
        "faceSize": 0.3,
        "clarity": 0.25,
        "lighting": 0.25,
        "faceAngle": 0.2
    }
    return sum(metrics[k] * weights[k] for k in weights)
```

**Quality Threshold**: 0.50 (from .env `EMBEDDING_QUALITY_THRESHOLD`)

## Custom Exceptions

```python
class FaceNotDetectedError(Exception):
    def __init__(self, message: str, code: str):
        super().__init__(message)
        self.code = code  # "NO_FACE_IN_PHOTO", "MULTIPLE_FACES_DETECTED"

class LowQualityError(Exception):
    def __init__(self, quality: float):
        super().__init__(f"Quality too low: {quality}")
        self.quality = quality
```
