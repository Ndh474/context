# Recognition Service - Common Pitfalls & Best Practices

## 1. Timezone Mistakes

### Problem

```python
# ❌ WRONG - depends on system timezone
timestamp = datetime.now()

# ❌ WRONG - no timezone info
timestamp = datetime.utcnow()

# ❌ WRONG - wrong format for Java
timestamp = datetime.now(pytz.UTC).isoformat()  # Has milliseconds
```

### Solution

```python
import pytz

# ✅ CORRECT - explicit Vietnam timezone for internal use
vn_tz = pytz.timezone('Asia/Ho_Chi_Minh')
timestamp = datetime.now(vn_tz)

# ✅ CORRECT - UTC for Java backend callbacks
from recognition_service.utils import get_utc_timestamp_for_java
timestamp = get_utc_timestamp_for_java()  # "2024-11-06T10:30:00Z"
```

### Java Timestamp Format

Java expects: `yyyy-MM-dd'T'HH:mm:ss'Z'` (no milliseconds)

```python
def get_utc_timestamp_for_java() -> str:
    now = datetime.now(pytz.UTC)
    return now.strftime('%Y-%m-%dT%H:%M:%SZ')
```

---

## 2. Model Not Loaded

### Problem

```python
# ❌ WRONG - model not initialized
face_app.get(img)  # Crashes if model not loaded
```

### Solution

```python
# ✅ CORRECT - check model loaded
class FaceRecognizer:
    async def process_frame(self, frame, ...):
        if self.face_app is None:
            logger.error("Face model not initialized")
            return []
        
        # Safe to use
        faces = self.face_app.get(frame)
```

### Lazy Loading Pattern

```python
class FaceEncoder:
    def __init__(self):
        self.app = None
    
    def _ensure_model_loaded(self):
        if self.app is None:
            self.app = get_face_app()
    
    def detect_faces(self, frame):
        self._ensure_model_loaded()
        return self.app.get(frame)
```

---

## 3. Session Cleanup

### Problem

```python
# ❌ WRONG - session state không được cleanup
# Leads to memory leaks and stale data

async def stop_session(self, slot_id):
    # Just cancel tasks, forget cleanup
    for task in self.active_tasks[slot_id]:
        task.cancel()
```

### Solution

```python
# ✅ CORRECT - always cleanup on stop
async def stop_session(self, slot_id):
    # 1. Cancel tasks
    if slot_id in self.active_tasks:
        for task in self.active_tasks[slot_id]:
            if not task.done():
                task.cancel()
        await asyncio.gather(*self.active_tasks[slot_id], return_exceptions=True)
        del self.active_tasks[slot_id]
    
    # 2. Stop via task_manager
    if slot_id in self.task_ids:
        for task_id in self.task_ids[slot_id]:
            await task_manager.stop_task(task_id)
        del self.task_ids[slot_id]
    
    # 3. Remove session
    await session_manager.remove_session(slot_id)
    
    # 4. Cleanup tracking
    self.recognized_students.pop(slot_id, None)
    self.callback_failures.pop(slot_id, None)
    self.last_success_time.pop(slot_id, None)
```

---

## 4. RTSP Stream Not Closing

### Problem

```python
# ❌ WRONG - stream không release
cap = cv2.VideoCapture(rtsp_url)
# ... use cap ...
# Forget to release → resource leak
```

### Solution

```python
# ✅ CORRECT - use try/finally
try:
    cap = cv2.VideoCapture(rtsp_url)
    # ... use cap ...
finally:
    if cap:
        cap.release()

# ✅ CORRECT - use context manager
with RTSPHandler(rtsp_url) as handler:
    frame = handler.capture_single_frame()
# Automatically released
```

---

## 5. FFmpeg Timeout Not Working

### Problem

```python
# ❌ WRONG - CAP_PROP_OPEN_TIMEOUT_MSEC doesn't work with FFmpeg
cap = cv2.VideoCapture(rtsp_url)
cap.set(cv2.CAP_PROP_OPEN_TIMEOUT_MSEC, 5000)  # Ignored!
```

### Solution

```python
# ✅ CORRECT - set via environment variable BEFORE creating VideoCapture
def _set_ffmpeg_timeout(timeout_seconds: int):
    timeout_us = timeout_seconds * 1_000_000
    os.environ["OPENCV_FFMPEG_CAPTURE_OPTIONS"] = (
        f"rtsp_transport;tcp|"
        f"stimeout;{timeout_us}|"
        f"timeout;{timeout_us}"
    )

# Then create capture
_set_ffmpeg_timeout(5)
cap = cv2.VideoCapture(rtsp_url, cv2.CAP_FFMPEG)
```

---

## 6. Stale Frames from Buffer

### Problem

```python
# ❌ WRONG - reading buffered (old) frames
ret, frame = cap.read()  # May be several seconds old
```

### Solution

```python
# ✅ CORRECT - flush buffer first
for _ in range(3):
    cap.grab()  # Discard old frames

ret, frame = cap.read()  # Now get latest frame
```

---

## 7. Blocking Sync Code in Async Context

### Problem

```python
# ❌ WRONG - blocking call in async function
async def test_camera(rtsp_url):
    cap = cv2.VideoCapture(rtsp_url)  # Blocks event loop!
    ret, frame = cap.read()
```

### Solution

```python
# ✅ CORRECT - run in executor
async def test_camera(rtsp_url):
    def _sync_test():
        cap = cv2.VideoCapture(rtsp_url)
        ret, frame = cap.read()
        cap.release()
        return ret, frame
    
    loop = asyncio.get_event_loop()
    ret, frame = await loop.run_in_executor(None, _sync_test)
```

---

## 8. Missing Deduplication

### Problem

```python
# ❌ WRONG - same student recognized multiple times
for face in faces:
    match = find_match(face, students)
    if match:
        send_callback(match)  # Sends duplicate callbacks!
```

### Solution

```python
# ✅ CORRECT - track recognized students
if slot_id not in self.recognized_students:
    self.recognized_students[slot_id] = set()

for face in faces:
    match = find_match(face, students)
    if match:
        student_id = match['userId']
        
        # Skip if already recognized
        if student_id in self.recognized_students[slot_id]:
            continue
        
        # Mark as recognized
        self.recognized_students[slot_id].add(student_id)
        
        send_callback(match)
```

---

## 9. Temp File Cleanup

### Problem

```python
# ❌ WRONG - temp file not cleaned on error
async def generate_embedding(photo):
    temp_path = save_temp_file(photo)
    result = process(temp_path)  # May raise exception
    os.remove(temp_path)  # Never reached if exception
    return result
```

### Solution

```python
# ✅ CORRECT - cleanup in finally
async def generate_embedding(photo):
    temp_path = save_temp_file(photo)
    try:
        result = process(temp_path)
        return result
    finally:
        if os.path.exists(temp_path):
            os.remove(temp_path)
```

---

## 10. PUBLIC_HOST vs HOST

### Problem

```python
# ❌ WRONG - using HOST (0.0.0.0) in URLs
base_url = f"http://{settings.HOST}:{settings.PORT}"
# Results in: http://0.0.0.0:8000/... (not routable!)
```

### Solution

```python
# ✅ CORRECT - use PUBLIC_HOST for external URLs
base_url = f"http://{settings.PUBLIC_HOST}:{settings.PORT}"
# Results in: http://localhost:8000/... or http://192.168.1.100:8000/...
```

---

## 11. Concurrent Session Access

### Problem

```python
# ❌ WRONG - race condition
class SessionManager:
    def add_session(self, slot_id, state):
        if slot_id in self._sessions:
            raise ValueError("Exists")
        self._sessions[slot_id] = state  # Race condition!
```

### Solution

```python
# ✅ CORRECT - use asyncio.Lock
class SessionManager:
    def __init__(self):
        self._lock = asyncio.Lock()
    
    async def add_session(self, slot_id, state):
        async with self._lock:
            if slot_id in self._sessions:
                raise ValueError("Exists")
            self._sessions[slot_id] = state
```

---

## 12. Callback Without Retry

### Problem

```python
# ❌ WRONG - single attempt, no retry
async def send_callback(url, data):
    async with aiohttp.ClientSession() as session:
        await session.post(url, json=data)
```

### Solution

```python
# ✅ CORRECT - retry with exponential backoff
async def send_callback(url, data):
    for attempt in range(3):
        try:
            async with aiohttp.ClientSession() as session:
                async with session.post(url, json=data, timeout=10) as resp:
                    if resp.status == 200:
                        return True
        except Exception as e:
            logger.warning(f"Attempt {attempt + 1} failed: {e}")
        
        if attempt < 2:
            await asyncio.sleep(1 * (2 ** attempt))  # 1s, 2s
    
    return False
```

---

## 13. Embedding Vector Validation

### Problem

```python
# ❌ WRONG - no validation
class StudentDTO(BaseModel):
    embeddingVector: List[float]  # Could be any length!
```

### Solution

```python
# ✅ CORRECT - validate exactly 512 dimensions
class StudentEmbeddingDTO(BaseModel):
    embeddingVector: List[float] = Field(..., min_length=512, max_length=512)
```

---

## 14. Logging Sensitive Data

### Problem

```python
# ❌ WRONG - logging full embedding vectors
logger.info(f"Student embedding: {student.embeddingVector}")  # 512 floats!
```

### Solution

```python
# ✅ CORRECT - log only relevant info
logger.info(f"Student {student.userId} ({student.rollNumber}): similarity={similarity:.4f}")
```

---

## Best Practices Summary

1. **Always use explicit timezone** (Asia/Ho_Chi_Minh or UTC)
2. **Check model loaded** before using
3. **Cleanup all resources** on session stop
4. **Release camera streams** in finally block
5. **Set FFmpeg timeout** via environment variable
6. **Flush buffer** before reading frames
7. **Run sync code in executor** for async context
8. **Deduplicate recognitions** per session
9. **Cleanup temp files** in finally block
10. **Use PUBLIC_HOST** for external URLs
11. **Use asyncio.Lock** for shared state
12. **Retry callbacks** with exponential backoff
13. **Validate embedding dimensions** (512)
14. **Don't log sensitive data** (embeddings, full frames)
