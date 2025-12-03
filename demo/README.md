# FUACS Face Recognition Demo

Demo cho giảng viên xem màn hình nhận diện khuôn mặt trực tiếp từ camera.

## Cài đặt

### 1. Tạo virtual environment

```bash
cd docs/demo
python -m venv venv

# Windows
venv\Scripts\activate

# Linux/Mac
source venv/bin/activate
```

### 2. Cài đặt dependencies

```bash
pip install -r requirements.txt
```

### 3. Tải model InsightFace (buffalo_l)

Model sẽ tự động tải khi chạy lần đầu. Hoặc tải thủ công:

```bash
# Tạo folder
mkdir -p models

# Model sẽ được tải vào models/buffalo_l/ khi chạy
```

**Lưu ý:** Model buffalo_l khoảng 300MB, cần internet để tải lần đầu.

### 4. Cấu hình camera

Sửa `RTSP_URL` trong file `face_recognition_demo.py`:

```python
RTSP_URL = "rtsp://admin:password@192.168.1.100:554/stream1"
```

## Chạy demo

```bash
python face_recognition_demo.py
```

## Controls

| Phím | Chức năng |
|------|-----------|
| `d` | Bật/tắt face detection |
| `q` | Thoát |

## Màn hình demo

- **Bounding box xanh lá**: Detection score > 0.8 (tốt)
- **Bounding box vàng**: Detection score 0.6-0.8 (trung bình)
- **Bounding box đỏ**: Detection score < 0.6 (thấp)
- **Chấm tím**: Facial landmarks (mắt, mũi, miệng)

## Troubleshooting

### Không kết nối được camera
- Kiểm tra RTSP URL đúng chưa
- Kiểm tra camera có online không
- Kiểm tra username/password

### Model không load được
- Kiểm tra internet để tải model
- Kiểm tra folder `models/` có quyền ghi

### Lag/chậm
- Giảm `det_size` trong code (640 → 320)
- Tăng `detection_interval` (0.5 → 1.0)
