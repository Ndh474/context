# Recognition Service - RTSP Camera Handling

## Overview

Service sử dụng OpenCV với FFmpeg backend để xử lý RTSP streams từ IP cameras.

## RTSP Configuration

### FFmpeg Timeout Setup

**File**: `services/rtsp_handler.py`

```python
def _set_ffmpeg_timeout(timeout_seconds: int):
    """
    Set FFmpeg timeout via environment variable.
    
    Note: CAP_PROP_OPEN_TIMEOUT_MSEC doesn't work reliably with FFmpeg backend.
    Must set timeout via OPENCV_FFMPEG_CAPTURE_OPTIONS environment variable.
    """
    timeout_us = timeout_seconds * 1_000_000  # Convert to microseconds
    os.environ["OPENCV_FFMPEG_CAPTURE_OPTIONS"] = (
        f"rtsp_transport;tcp|"      # Force TCP (more reliable than UDP)
        f"stimeout;{timeout_us}|"   # Socket timeout
        f"timeout;{timeout_us}"     # Connection timeout
    )
```

**IMPORTANT**: Phải set environment variable TRƯỚC khi tạo `cv2.VideoCapture`.

### VideoCapture Setup

```python
import cv2

# Set timeout first
_set_ffmpeg_timeout(5)

# Create capture with FFmpeg backend
cap = cv2.VideoCapture(rtsp_url, cv2.CAP_FFMPEG)

# Minimize buffer to get latest frame (reduce lag)
cap.set(cv2.CAP_PROP_BUFFERSIZE, 1)

# Verify connection
ret, frame = cap.read()
if not ret or frame is None:
    raise RTSPConnectionError("Failed to read frame")
```

## RTSPHandler Class

**File**: `services/rtsp_handler.py`

```python
class RTSPHandler:
    def __init__(self, rtsp_url: str, timeout: int = 5):
        self.rtsp_url = rtsp_url
        self.timeout = timeout
        self.cap: Optional[cv2.VideoCapture] = None
        self._is_connected = False
    
    def connect(self) -> bool:
        """Establish RTSP connection"""
        _set_ffmpeg_timeout(self.timeout)
        self.cap = cv2.VideoCapture(self.rtsp_url, cv2.CAP_FFMPEG)
        self.cap.set(cv2.CAP_PROP_BUFFERSIZE, 1)
        
        ret, frame = self.cap.read()
        if not ret:
            raise RTSPConnectionError("Failed to read frame")
        
        self._is_connected = True
        return True
    
    def capture_frames(self, count: int = 10) -> Tuple[List[np.ndarray], float]:
        """Capture multiple frames and calculate FPS"""
        frames = []
        start_time = time.time()
        
        for i in range(count):
            ret, frame = self.cap.read()
            if ret and frame is not None:
                frames.append(frame)
        
        elapsed = time.time() - start_time
        fps = len(frames) / elapsed if elapsed > 0 else 0.0
        return frames, fps
    
    def capture_single_frame(self) -> np.ndarray:
        """Capture one frame"""
        ret, frame = self.cap.read()
        if not ret:
            raise RTSPConnectionError("Failed to capture frame")
        return frame
    
    def get_resolution(self) -> Tuple[int, int]:
        """Get video resolution (width, height)"""
        width = int(self.cap.get(cv2.CAP_PROP_FRAME_WIDTH))
        height = int(self.cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
        return width, height
    
    def calculate_latency(self) -> int:
        """Calculate approximate latency in milliseconds"""
        start = time.time()
        self.capture_single_frame()
        return int((time.time() - start) * 1000)
    
    def release(self):
        """Release resources"""
        if self.cap:
            self.cap.release()
            self._is_connected = False
    
    # Context manager support
    def __enter__(self):
        self.connect()
        return self
    
    def __exit__(self, exc_type, exc_val, exc_tb):
        self.release()
```

## Connection Testing

### Async Test Function

```python
async def test_rtsp_connection(rtsp_url: str, timeout: int = 5) -> dict:
    """
    Test RTSP connection and return result dictionary.
    Uses asyncio.wait_for as backup timeout.
    """
    def _sync_test():
        with RTSPHandler(rtsp_url, timeout) as handler:
            width, height = handler.get_resolution()
            frames, fps = handler.capture_frames(5)
            latency = handler.calculate_latency()
            
            return {
                "connected": True,
                "frameRate": fps,
                "resolution": {"width": width, "height": height},
                "latency": latency,
                "stability": "stable" if fps > 10 else "unstable"
            }
    
    try:
        loop = asyncio.get_event_loop()
        result = await asyncio.wait_for(
            loop.run_in_executor(None, _sync_test),
            timeout=timeout + 2  # Buffer for FFmpeg timeout
        )
        return result
    except asyncio.TimeoutError:
        return {"connected": False, "error": f"Connection timeout after {timeout}s"}
    except Exception as e:
        return {"connected": False, "error": str(e)}
```

## Frame Capture in Recognition Loop

### Buffer Flushing

RTSP streams có buffer, cần flush để lấy frame mới nhất:

```python
# Flush old frames from buffer (3 frames)
for _ in range(3):
    cap.grab()

# Now read the latest frame
ret, frame = cap.read()
```

### Scan Interval

```python
scan_interval = config.scanInterval  # e.g., 1.5 seconds
last_scan = datetime.now(vn_tz)

while True:
    # ... capture frame ...
    
    # Check scan interval
    now = datetime.now(vn_tz)
    if (now - last_scan).total_seconds() < scan_interval:
        await asyncio.sleep(0.1)
        continue
    
    last_scan = now
    
    # Process frame for recognition
    recognitions = await face_recognizer.process_frame(frame, ...)
```

## Camera Reconnection

### Reconnect Logic

**File**: `services/recognition_service.py`

```python
async def _try_reconnect(self, camera, max_retries: int = 3, delay: float = 2.0, timeout: int = 5):
    """
    Try to reconnect to camera with retry logic.
    """
    def _sync_connect(rtsp_url: str):
        _set_ffmpeg_timeout(timeout)
        cap = cv2.VideoCapture(rtsp_url, cv2.CAP_FFMPEG)
        cap.set(cv2.CAP_PROP_BUFFERSIZE, 1)
        
        if cap.isOpened():
            ret, frame = cap.read()
            if ret and frame is not None:
                return cap
        
        if cap:
            cap.release()
        return None
    
    for attempt in range(1, max_retries + 1):
        logger.warning(f"CAMERA_RECONNECT | camera={camera.id} attempt={attempt}/{max_retries}")
        
        await asyncio.sleep(delay)
        
        try:
            loop = asyncio.get_event_loop()
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
    
    logger.error(f"CAMERA_RECONNECT_FAILED | camera={camera.id} after {max_retries} attempts")
    return None
```

### Failure Handling

```python
async def _handle_camera_failure(self, slot_id: int, camera, config):
    """Handle camera failure: notify backend, check if all cameras dead."""
    
    # Mark camera dead and check remaining
    has_remaining = await session_manager.mark_camera_dead(slot_id, camera.id)
    
    if not has_remaining:
        # All cameras dead → notify backend and stop session
        logger.error(f"ALL_CAMERAS_DEAD | slot={slot_id}")
        
        await callback_service.send_session_status(
            callback_url=config.callbackUrl,
            slot_id=slot_id,
            status="STOPPED",
            reason="ALL_CAMERAS_FAILED",
            active_cameras=0,
            failed_cameras=session.failed_cameras,
            failed_camera_ids=list(session.failed_camera_ids),
        )
        
        # Cleanup session
        await session_manager.remove_session(slot_id)
        # ... cleanup other resources ...
    else:
        # Some cameras still active → just notify about this camera
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

## CameraService

**File**: `services/camera_service.py`

Wrapper service cho camera operations (test connection, capture frame):

```python
class CameraService:
    async def test_connection(self, rtsp_url: str, timeout: int) -> dict:
        """Test RTSP connection"""
        return await test_rtsp_connection(rtsp_url, timeout)
    
    async def capture_frame(self, rtsp_url: str, format: str, camera_id: int, timeout: int) -> dict:
        """Capture single frame and return as base64 or file"""
        # ... implementation ...
```

## Common Issues

### 1. Connection Timeout

- FFmpeg timeout không hoạt động đúng với `CAP_PROP_OPEN_TIMEOUT_MSEC`
- **Solution**: Set `OPENCV_FFMPEG_CAPTURE_OPTIONS` environment variable

### 2. Stale Frames

- RTSP buffer giữ frames cũ
- **Solution**: Flush buffer với `cap.grab()` trước khi `cap.read()`

### 3. Resource Leak

```python
# ❌ WRONG - stream không release
cap = cv2.VideoCapture(rtsp_url)
# ... use cap ...
# Forget to release → resource leak

# ✅ CORRECT - use try/finally or context manager
try:
    cap = cv2.VideoCapture(rtsp_url)
    # ... use cap ...
finally:
    if cap:
        cap.release()
```

### 4. TCP vs UDP

- UDP (default): Faster but less reliable
- TCP: More reliable, recommended for production
- **Config**: `rtsp_transport;tcp` in FFmpeg options
