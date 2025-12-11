# Recognition Service - Singleton Services

## Overview

Service sử dụng singleton pattern cho các shared resources để tránh overhead và đảm bảo consistency.

## Singleton Instances

### 1. face_recognizer

**File**: `services/face_recognizer.py`

```python
class FaceRecognizer:
    def __init__(self):
        self.face_app = None
        self._init_model()
    
    def _init_model(self):
        providers = get_onnx_providers()
        ctx_id = get_insightface_ctx_id()
        
        self.face_app = FaceAnalysis(name="buffalo_l", providers=providers)
        self.face_app.prepare(ctx_id=ctx_id, det_size=(640, 640))
    
    async def process_frame(self, frame, students, threshold, ...) -> List[Dict]:
        # Face detection and matching
        pass

# Singleton instance
face_recognizer = FaceRecognizer()
```

**Usage**:
```python
from recognition_service.services.face_recognizer import face_recognizer

recognitions = await face_recognizer.process_frame(frame, students, 0.55, ...)
```

**Memory**: ~600MB (InsightFace model)

---

### 2. session_manager

**File**: `services/session_manager.py`

```python
class SessionManager:
    def __init__(self):
        self._sessions: Dict[int, SessionState] = {}
        self._lock = asyncio.Lock()
    
    async def add_session(self, slot_id: int, state: SessionState) -> None:
        async with self._lock:
            if slot_id in self._sessions:
                raise ValueError(f"Session already exists for slot {slot_id}")
            self._sessions[slot_id] = state
    
    async def remove_session(self, slot_id: int) -> Optional[SessionState]:
        async with self._lock:
            return self._sessions.pop(slot_id, None)
    
    async def get_session(self, slot_id: int) -> Optional[SessionState]:
        async with self._lock:
            return self._sessions.get(slot_id)
    
    async def increment_recognition_count(self, slot_id: int) -> None:
        async with self._lock:
            if slot_id in self._sessions:
                self._sessions[slot_id].recognition_count += 1
    
    async def mark_camera_dead(self, slot_id: int, camera_id: int) -> bool:
        async with self._lock:
            session = self._sessions.get(slot_id)
            if not session:
                return False
            
            session.active_camera_ids.discard(camera_id)
            session.failed_camera_ids.add(camera_id)
            session.active_cameras = len(session.active_camera_ids)
            session.failed_cameras = len(session.failed_camera_ids)
            
            return len(session.active_camera_ids) > 0
    
    @property
    def active_sessions_count(self) -> int:
        return len(self._sessions)

# Singleton instance
session_manager = SessionManager()
```

**Usage**:
```python
from recognition_service.services.session_manager import session_manager

await session_manager.add_session(slot_id, state)
session = await session_manager.get_session(slot_id)
await session_manager.remove_session(slot_id)
```

**Thread Safety**: `asyncio.Lock()` cho tất cả operations

**Limitation**: In-memory storage, lost on restart

---

### 3. task_manager

**File**: `services/task_manager.py`

```python
class TaskManager:
    def __init__(self):
        self._tasks: Dict[str, asyncio.Task] = {}
        self._lock = asyncio.Lock()
    
    async def start_task(self, task_id: str, coro) -> asyncio.Task:
        async with self._lock:
            if task_id in self._tasks:
                raise ValueError(f"Task {task_id} already exists")
            
            task = asyncio.create_task(coro)
            self._tasks[task_id] = task
            return task
    
    async def stop_task(self, task_id: str) -> bool:
        async with self._lock:
            if task_id not in self._tasks:
                return False
            
            task = self._tasks[task_id]
            if not task.done():
                task.cancel()
                try:
                    await task
                except asyncio.CancelledError:
                    pass
            
            del self._tasks[task_id]
            return True
    
    async def stop_all_tasks(self) -> int:
        async with self._lock:
            count = 0
            for task in self._tasks.values():
                if not task.done():
                    task.cancel()
                    count += 1
            
            if self._tasks:
                await asyncio.gather(*self._tasks.values(), return_exceptions=True)
            
            self._tasks.clear()
            return count
    
    @property
    def active_tasks_count(self) -> int:
        return len([t for t in self._tasks.values() if not t.done()])

# Singleton instance
task_manager = TaskManager()
```

**Usage**:
```python
from recognition_service.services.task_manager import task_manager

task = await task_manager.start_task("slot_123_camera_1", coro)
await task_manager.stop_task("slot_123_camera_1")
await task_manager.stop_all_tasks()
```

**Task ID Format**: `slot_{slot_id}_camera_{camera_id}`

---

### 4. callback_service

**File**: `services/callback_service.py`

```python
class CallbackService:
    def __init__(self):
        self.batch_size = 100
        self.retry_attempts = 3
        self.retry_delay = 1
    
    async def send_recognition(self, callback_url, slot_id, recognition, mode, callback_type) -> bool:
        # Send recognition callback with retry
        pass
    
    async def send_session_status(self, callback_url, slot_id, status, reason, ...) -> bool:
        # Send session status callback
        pass

# Singleton instance
callback_service = CallbackService()
```

**Usage**:
```python
from recognition_service.services.callback_service import callback_service

success = await callback_service.send_recognition(url, slot_id, recognition, mode, type)
```

---

### 5. recognition_service

**File**: `services/recognition_service.py`

```python
class RecognitionService:
    def __init__(self):
        self.active_tasks: Dict[int, List[asyncio.Task]] = {}
        self.task_ids: Dict[int, List[str]] = {}
        self.recognized_students: Dict[int, set] = {}
        self.callback_failures: Dict[int, int] = {}
        self.last_success_time: Dict[int, datetime] = {}
    
    async def start_session(self, request: StartSessionRequest) -> SessionDataDTO:
        # Start recognition session
        pass
    
    async def stop_session(self, slot_id: int) -> Optional[SessionDataDTO]:
        # Stop recognition session
        pass

# Singleton instance
recognition_service = RecognitionService()
```

**Usage**:
```python
from recognition_service.services.recognition_service import recognition_service

session_data = await recognition_service.start_session(request)
session_data = await recognition_service.stop_session(slot_id)
```

---

### 6. metrics_collector

**File**: `services/metrics_collector.py`

```python
class MetricsCollector:
    def __init__(self):
        self.service_start_time = datetime.now(pytz.timezone('Asia/Ho_Chi_Minh'))
        # ... other metrics ...

# Singleton instance
metrics_collector = MetricsCollector()
```

**Usage**:
```python
from recognition_service.services.metrics_collector import metrics_collector

uptime = (datetime.now(vn_tz) - metrics_collector.service_start_time).total_seconds()
```

---

## Lazy Loading Pattern

### FaceEncoder

**File**: `services/face_encoder.py`

```python
class FaceEncoder:
    def __init__(self):
        self.app: Optional[FaceAnalysis] = None
    
    def _ensure_model_loaded(self):
        if self.app is None:
            self.app = get_face_app()  # Get from model_loader
    
    def detect_faces(self, frame: np.ndarray) -> list:
        self._ensure_model_loaded()
        return self.app.get(frame)
```

### EmbeddingGenerator

**File**: `api/v1/embeddings.py`

```python
embedding_generator = None

def get_embedding_generator() -> EmbeddingGenerator:
    global embedding_generator
    if embedding_generator is None:
        embedding_generator = EmbeddingGenerator()
    return embedding_generator
```

---

## Model Loading (Lifespan)

**File**: `main.py`

```python
@asynccontextmanager
async def lifespan(app: FastAPI):
    # STARTUP
    try:
        await load_insightface_model()
    except Exception as e:
        logger.error(f"Failed to load model: {e}")
        logger.warning("Service starting without model")
    
    yield  # Application runs
    
    # SHUTDOWN
    stopped_tasks = await task_manager.stop_all_tasks()
    session_manager._sessions.clear()
```

**File**: `services/model_loader.py`

```python
_face_app = None

async def load_insightface_model():
    global _face_app
    
    providers = get_onnx_providers()
    ctx_id = get_insightface_ctx_id()
    
    _face_app = FaceAnalysis(name='buffalo_l', providers=providers)
    _face_app.prepare(ctx_id=ctx_id, det_size=(640, 640))

def get_face_app() -> FaceAnalysis:
    if _face_app is None:
        raise RuntimeError("Model not loaded")
    return _face_app
```

---

## Thread Safety

### asyncio.Lock Usage

Tất cả shared state operations sử dụng `asyncio.Lock()`:

```python
class SessionManager:
    def __init__(self):
        self._lock = asyncio.Lock()
    
    async def add_session(self, slot_id, state):
        async with self._lock:
            # Critical section
            self._sessions[slot_id] = state
```

### Concurrent Sessions

- Multiple sessions có thể chạy đồng thời (different slot_ids)
- Mỗi session có multiple camera tasks (parallel processing)
- Shared resources (face_app, session_manager) được protect bởi locks

---

## Memory Considerations

- **InsightFace model**: ~600MB (loaded once, reused globally)
- **Session state**: In-memory (lost on restart)
- **Evidence images**: Stored on disk (can grow large)
- **Recognized students**: In-memory set per session

---

## Cleanup on Shutdown

```python
# In lifespan shutdown
stopped_tasks = await task_manager.stop_all_tasks()
session_manager._sessions.clear()
```

Ensures:
- All background tasks cancelled
- All sessions cleared
- Resources released
