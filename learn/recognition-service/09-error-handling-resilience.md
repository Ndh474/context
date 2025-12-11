# Recognition Service - Error Handling & Resilience

## Overview

Service được thiết kế để handle failures gracefully và tiếp tục hoạt động khi có lỗi partial.

## Camera Failure Handling

### Read Failure Detection

```python
# In _process_camera()
ret, frame = cap.read()

if not ret or frame is None:
    logger.warning(f"CAMERA_READ_FAIL | slot={slot_id} camera={camera.id}")
    
    # Release current connection
    if cap:
        cap.release()
    
    # Try reconnect
    cap = await self._try_reconnect(camera)
    
    if cap is None:
        # Reconnect failed → handle failure
        await self._handle_camera_failure(slot_id, camera, config)
        return  # Exit this camera's task
    
    continue  # Reconnect OK → continue loop
```

### Reconnect Logic

```python
async def _try_reconnect(self, camera, max_retries=3, delay=2.0, timeout=5):
    for attempt in range(1, max_retries + 1):
        logger.warning(f"CAMERA_RECONNECT | camera={camera.id} attempt={attempt}/{max_retries}")
        
        await asyncio.sleep(delay)
        
        try:
            cap = await asyncio.wait_for(
                loop.run_in_executor(None, _sync_connect, camera.rtspUrl),
                timeout=timeout + 2
            )
            
            if cap is not None:
                logger.info(f"CAMERA_RECONNECT_OK | camera={camera.id}")
                return cap
                
        except asyncio.TimeoutError:
            logger.warning(f"CAMERA_RECONNECT_TIMEOUT | camera={camera.id}")
        except Exception as e:
            logger.error(f"CAMERA_RECONNECT_ERROR | camera={camera.id} error={e}")
    
    return None  # All retries failed
```

### Camera Death Handling

```python
async def _handle_camera_failure(self, slot_id, camera, config):
    # Mark camera dead
    has_remaining = await session_manager.mark_camera_dead(slot_id, camera.id)
    
    if not has_remaining:
        # ALL cameras dead → stop session
        logger.error(f"ALL_CAMERAS_DEAD | slot={slot_id}")
        
        await callback_service.send_session_status(
            callback_url=config.callbackUrl,
            slot_id=slot_id,
            status="STOPPED",
            reason="ALL_CAMERAS_FAILED",
            ...
        )
        
        # Cleanup
        await session_manager.remove_session(slot_id)
        self.recognized_students.pop(slot_id, None)
        self.active_tasks.pop(slot_id, None)
        # ...
    else:
        # Some cameras still active → notify and continue
        logger.warning(f"CAMERA_DEAD | slot={slot_id} camera={camera.id}")
        
        await callback_service.send_session_status(
            callback_url=config.callbackUrl,
            slot_id=slot_id,
            status="CAMERA_DISCONNECTED",
            reason="CAMERA_FAILURE",
            camera_id=camera.id,
            camera_name=camera.name
        )
```

---

## Callback Failure Handling

### Retry Logic

```python
async def send_recognition(self, callback_url, slot_id, recognition, mode, callback_type):
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
                    else:
                        logger.warning(f"Callback failed: status={response.status}")
                        
        except asyncio.TimeoutError:
            logger.warning(f"Callback timeout: attempt={attempt + 1}")
        except Exception as e:
            logger.warning(f"Callback error: {e}")
        
        # Exponential backoff: 1s, 2s, 4s
        if attempt < self.retry_attempts - 1:
            await asyncio.sleep(self.retry_delay * (2 ** attempt))
    
    logger.error(f"All callback attempts failed: slot={slot_id}")
    return False
```

### Auto-Stop on Backend Unresponsive

```python
# Thresholds
MAX_CONSECUTIVE_FAILURES = 10   # 10 consecutive failures
MAX_FAILURE_DURATION = 120      # 2 minutes without success

# Tracking
self.callback_failures: Dict[int, int] = {}
self.last_success_time: Dict[int, datetime] = {}

# Check
async def _should_auto_stop(self, slot_id, max_failures, max_duration):
    failures = self.callback_failures.get(slot_id, 0)
    if failures >= max_failures:
        return True
    
    last_success = self.last_success_time.get(slot_id)
    if last_success:
        duration = (datetime.now(vn_tz) - last_success).seconds
        if duration >= max_duration:
            return True
    
    return False

# Update tracking
if success:
    self.callback_failures[slot_id] = 0
    self.last_success_time[slot_id] = datetime.now(vn_tz)
else:
    self.callback_failures[slot_id] += 1
```

---

## Session Validation

### Duplicate Session Prevention

```python
async def start_session(self, request):
    slot_id = request.slotId
    
    # Check existing session
    existing = await session_manager.get_session(slot_id)
    if existing:
        logger.warning(f"SESSION_EXISTS | slot={slot_id}")
        raise ValueError(f"Session already exists for slot {slot_id}")
```

### Session Not Found

```python
async def stop_session(self, slot_id):
    session = await session_manager.get_session(slot_id)
    if not session:
        return None  # Caller handles 404
```

### External Session Stop Detection

```python
# In background loop
while True:
    session = await session_manager.get_session(slot_id)
    if not session:
        logger.info(f"Session stopped externally: slot={slot_id}")
        break
```

---

## Task Cancellation

### Graceful Cancellation

```python
# In background loop
while True:
    if asyncio.current_task().cancelled():
        break
    # ... processing ...

# Cleanup in finally
finally:
    if cap:
        cap.release()
    logger.info(f"CAMERA_STOP | slot={slot_id} camera={camera.id}")
```

### Stop Session Cleanup

```python
async def stop_session(self, slot_id):
    # Cancel all tasks
    if slot_id in self.active_tasks:
        for task in self.active_tasks[slot_id]:
            if not task.done():
                task.cancel()
        
        # Wait for cancellation
        await asyncio.gather(*self.active_tasks[slot_id], return_exceptions=True)
        del self.active_tasks[slot_id]
    
    # Stop via task_manager
    if slot_id in self.task_ids:
        for task_id in self.task_ids[slot_id]:
            await task_manager.stop_task(task_id)
        del self.task_ids[slot_id]
    
    # Cleanup session
    await session_manager.remove_session(slot_id)
    
    # Cleanup tracking
    self.recognized_students.pop(slot_id, None)
    self.callback_failures.pop(slot_id, None)
    self.last_success_time.pop(slot_id, None)
```

---

## Model Loading Failure

```python
@asynccontextmanager
async def lifespan(app: FastAPI):
    try:
        await load_insightface_model()
    except Exception as e:
        logger.error(f"Failed to load InsightFace model: {e}")
        logger.warning("Service starting without model - recognition endpoints will fail")
    
    yield
```

### Runtime Check

```python
class FaceRecognizer:
    async def process_frame(self, frame, ...):
        if self.face_app is None:
            logger.error("Face model not initialized")
            return []
```

---

## Frame Processing Errors

```python
async def process_frame(self, frame, students, ...):
    try:
        # Validate frame
        if frame is None or frame.size == 0:
            logger.warning("Invalid frame received")
            return []
        
        # Detect faces
        faces = self.face_app.get(frame)
        
        # Process each face
        for face in faces:
            # ... matching logic ...
            
    except Exception as e:
        logger.error(f"Error processing frame: {e}", exc_info=True)
    
    return recognitions
```

---

## Embedding Generation Errors

### Custom Exceptions

```python
class FaceNotDetectedError(Exception):
    def __init__(self, message: str, code: str):
        super().__init__(message)
        self.code = code

class LowQualityError(Exception):
    def __init__(self, quality: float):
        super().__init__(f"Quality too low: {quality}")
        self.quality = quality
```

### Error Handling in Endpoint

```python
@router.post("/embeddings/generate")
async def generate_embedding(photo: UploadFile, submissionId: int):
    try:
        result = await get_embedding_generator().generate_embedding_from_photo(...)
        return EmbeddingGenerateResponse(status=200, data=result)
        
    except FaceNotDetectedError as e:
        return EmbeddingGenerateResponse(status=400, message=str(e), code=e.code)
        
    except LowQualityError as e:
        return EmbeddingGenerateResponse(
            status=400,
            message=f"Face quality too low (score: {e.quality:.2f})",
            code="LOW_QUALITY_FACE"
        )
        
    except Exception as e:
        logger.error(f"Embedding generation failed: {e}", exc_info=True)
        return EmbeddingGenerateResponse(
            status=500,
            message=f"Failed to process photo: {str(e)}",
            code="IMAGE_PROCESSING_FAILED"
        )
    
    finally:
        # Always cleanup temp file
        if os.path.exists(temp_path):
            os.remove(temp_path)
```

---

## Request Validation Errors

### Custom Handler

```python
@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request: Request, exc: RequestValidationError):
    # Log detailed debug info
    logger.error("REQUEST VALIDATION ERROR")
    logger.error(f"Method: {request.method}")
    logger.error(f"URL: {request.url}")
    logger.error(f"Headers: {dict(request.headers)}")
    
    # Try to log body
    try:
        body = await request.body()
        logger.error(f"Raw body: {body.decode('utf-8')}")
    except Exception as e:
        logger.error(f"Failed to read body: {e}")
    
    logger.error(f"Validation errors: {exc.errors()}")
    
    return JSONResponse(
        status_code=422,
        content={
            "detail": exc.errors(),
            "message": "Request validation failed"
        }
    )
```

---

## Shutdown Cleanup

```python
@asynccontextmanager
async def lifespan(app: FastAPI):
    # ... startup ...
    
    yield
    
    # SHUTDOWN
    logger.info("Shutting down service...")
    
    try:
        stopped_tasks = await task_manager.stop_all_tasks()
        active_count = session_manager.active_sessions_count
        session_manager._sessions.clear()
        logger.info(f"Cleanup complete: {stopped_tasks} tasks, {active_count} sessions")
    except Exception as e:
        logger.error(f"Error during cleanup: {e}")
    
    logger.info("Service shutdown complete")
```

---

## Error Response Codes

### HTTP Status Codes

- `200` - Success
- `400` - Bad request (validation, no face, low quality)
- `401` - Unauthorized (missing/invalid API key)
- `404` - Not found (session not found)
- `409` - Conflict (session already exists)
- `422` - Validation error
- `500` - Internal server error
- `501` - Not implemented (cameraId lookup)

### Application Error Codes

- `PHOTO_FILE_REQUIRED`
- `INVALID_FILE_FORMAT`
- `PHOTO_FILE_NOT_FOUND`
- `NO_FACE_IN_PHOTO`
- `MULTIPLE_FACES_DETECTED`
- `LOW_QUALITY_FACE`
- `IMAGE_PROCESSING_FAILED`
- `SESSION_ALREADY_EXISTS`
- `ALL_CAMERAS_FAILED`
- `SESSION_NOT_FOUND`
- `STOP_SESSION_FAILED`
- `INTERNAL_ERROR`
