"""
FUACS Face Recognition Demo với Anti-Spoofing
- Face Detection: InsightFace buffalo_l
- Anti-Spoofing: Silent-Face-Anti-Spoofing (MiniFASNet)
- Hỗ trợ: Webcam và RTSP camera

Cách chạy:
    python face_recognition_demo.py
"""

import cv2
import threading
import tkinter as tk
from tkinter import Label, Button, Frame, messagebox, Checkbutton, BooleanVar, Scale
from PIL import Image, ImageTk
import time
import numpy as np
import os
import sys

# ============================================
# CẤU HÌNH - THAY ĐỔI Ở ĐÂY
# ============================================
USE_WEBCAM = True  # True = webcam laptop, False = RTSP camera
RTSP_URL = "rtsp://admin:admin@192.168.0.228:8554/live"
WEBCAM_INDEX = 0  # 0 = webcam mặc định

# Đường dẫn tới anti_spoof module
ANTISPOOF_DIR = os.path.join(os.path.dirname(__file__), "anti_spoof")

# ============================================
# IMPORT INSIGHTFACE
# ============================================
try:
    from insightface.app import FaceAnalysis
    INSIGHTFACE_AVAILABLE = True
except ImportError:
    INSIGHTFACE_AVAILABLE = False
    print("⚠️ Chưa cài insightface. Chạy: pip install insightface onnxruntime-gpu")

# ============================================
# IMPORT ANTI-SPOOFING MODULE
# ============================================
ANTISPOOF_AVAILABLE = False

try:
    from anti_spoof.models import MiniFASNetV1, MiniFASNetV2, MiniFASNetV1SE, MiniFASNetV2SE
    from anti_spoof.utils import parse_model_name, get_kernel, CropImage
    from anti_spoof.transform import Compose, ToTensor
    ANTISPOOF_AVAILABLE = True
    print("✅ Anti-Spoofing module đã sẵn sàng!")
except ImportError as e:
    print(f"⚠️ Không thể import anti_spoof: {e}")
    print("💡 Cài đặt: pip install torch torchvision")


class RTSPVideoStream:
    """Đọc video stream trong thread riêng để tránh lag GUI"""
    
    def __init__(self, src=0):
        self.src = src
        self.stream = None
        self.grabbed = False
        self.frame = None
        self.stop_event = False
        self.lock = threading.Lock()
        
    def start(self):
        t = threading.Thread(target=self.update, daemon=True)
        t.start()
        return self

    def update(self):
        print(f"📹 Đang kết nối camera: {self.src}...")
        self.stream = cv2.VideoCapture(self.src)
        
        if self.stream.isOpened():
            self.stream.set(cv2.CAP_PROP_BUFFERSIZE, 1)
            print("✅ Kết nối camera thành công!")
        else:
            print("❌ Không thể kết nối camera!")
            self.stop_event = True
            return

        while not self.stop_event:
            if not self.stream.isOpened():
                break
            grabbed, frame = self.stream.read()
            with self.lock:
                self.grabbed = grabbed
                self.frame = frame
            time.sleep(0.005)
        
        self.stream.release()

    def read(self):
        with self.lock:
            return self.frame.copy() if self.grabbed and self.frame is not None else None

    def stop(self):
        self.stop_event = True


class SilentFaceAntiSpoof:
    """
    Wrapper cho Anti-Spoofing module
    Sử dụng 2 model: MiniFASNetV2 và MiniFASNetV1SE
    """
    
    def __init__(self, device_id=0):
        self.available = False
        self.model_dir = ANTISPOOF_DIR
        self.device_id = device_id
        self.device = None
        self.models = {}  # Cache loaded models
        self.image_cropper = None
        self.threshold = 0.5
        
    def load(self):
        """Tải model anti-spoofing"""
        if not ANTISPOOF_AVAILABLE:
            print("❌ Anti-Spoof module không khả dụng")
            return False
            
        try:
            import torch
            print("🔄 Đang tải Anti-Spoof models...")
            
            # Setup device
            self.device = torch.device(f"cuda:{self.device_id}" if torch.cuda.is_available() else "cpu")
            print(f"   Device: {self.device}")
            
            # Kiểm tra model files
            model_files = [f for f in os.listdir(self.model_dir) if f.endswith('.pth')]
            print(f"   Models: {model_files}")
            
            # Model mapping
            MODEL_MAPPING = {
                'MiniFASNetV1': MiniFASNetV1,
                'MiniFASNetV2': MiniFASNetV2,
                'MiniFASNetV1SE': MiniFASNetV1SE,
                'MiniFASNetV2SE': MiniFASNetV2SE
            }
            
            for model_name in model_files:
                h_input, w_input, model_type, scale = parse_model_name(model_name)
                kernel_size = get_kernel(h_input, w_input)
                
                model = MODEL_MAPPING[model_type](conv6_kernel=kernel_size).to(self.device)
                model_path = os.path.join(self.model_dir, model_name)
                
                state_dict = torch.load(model_path, map_location=self.device, weights_only=True)
                # Handle 'module.' prefix from DataParallel
                if list(state_dict.keys())[0].startswith('module.'):
                    from collections import OrderedDict
                    new_state_dict = OrderedDict()
                    for key, value in state_dict.items():
                        new_state_dict[key[7:]] = value
                    state_dict = new_state_dict
                
                model.load_state_dict(state_dict)
                model.eval()
                
                self.models[model_name] = {
                    'model': model,
                    'h_input': h_input,
                    'w_input': w_input,
                    'scale': scale
                }
                print(f"   ✓ Loaded {model_name}")
            
            # Image cropper
            self.image_cropper = CropImage()
            
            self.available = True
            print("✅ Anti-Spoof models đã sẵn sàng!")
            return True
            
        except Exception as e:
            print(f"❌ Lỗi tải Anti-Spoof: {e}")
            import traceback
            traceback.print_exc()
            return False
    
    def check(self, frame, bbox=None):
        """
        Kiểm tra liveness của khuôn mặt
        
        Args:
            frame: BGR image (numpy array)
            bbox: [x1, y1, x2, y2] từ InsightFace
            
        Returns:
            (is_real, score, label): 
                - is_real: True nếu là khuôn mặt thật
                - score: điểm số từ 0-1
                - label: "REAL" hoặc "FAKE"
        """
        if not self.available or not self.models:
            return True, 0.5, "N/A"
        
        if bbox is None:
            return True, 0.5, "N/A"
            
        try:
            import torch
            import torch.nn.functional as F
            
            # Convert bbox từ [x1, y1, x2, y2] sang [x, y, w, h]
            x1, y1, x2, y2 = [int(v) for v in bbox]
            image_bbox = [x1, y1, x2 - x1, y2 - y1]
            
            if image_bbox[2] <= 0 or image_bbox[3] <= 0:
                return True, 0.5, "N/A"
            
            # Chạy prediction với tất cả models
            prediction = np.zeros((1, 3))
            test_transform = Compose([ToTensor()])
            
            for model_name, model_info in self.models.items():
                model = model_info['model']
                h_input = model_info['h_input']
                w_input = model_info['w_input']
                scale = model_info['scale']
                
                param = {
                    "org_img": frame,
                    "bbox": image_bbox,
                    "scale": scale,
                    "out_w": w_input,
                    "out_h": h_input,
                    "crop": True,
                }
                
                if scale is None:
                    param["crop"] = False
                    
                img = self.image_cropper.crop(**param)
                
                # Transform và predict
                img_tensor = test_transform(img)
                img_tensor = img_tensor.unsqueeze(0).to(self.device)
                
                with torch.no_grad():
                    result = model(img_tensor)
                    result = F.softmax(result, dim=1).cpu().numpy()
                
                prediction += result
            
            # Tính kết quả (chia cho số models)
            num_models = len(self.models)
            label_idx = np.argmax(prediction)
            score = prediction[0][label_idx] / num_models
            
            if label_idx == 1:
                is_real = True
                label = "REAL"
            else:
                is_real = False
                label = "FAKE"
                
            return is_real, float(score), label
            
        except Exception as e:
            print(f"Anti-spoof error: {e}")
            return True, 0.5, "ERR"


class App:
    def __init__(self, root, camera_source):
        self.root = root
        self.root.title("FUACS Demo - Face Recognition + Anti-Spoofing")
        self.root.geometry("1100x750")
        self.root.configure(bg="#2c3e50")

        self.camera_source = camera_source
        self.is_playing = True
        
        # --- AI Models ---
        self.face_detection_enabled = BooleanVar(value=False)
        self.anti_spoof_enabled = BooleanVar(value=False)
        self.face_model = None
        self.anti_spoof = SilentFaceAntiSpoof(device_id=0)
        
        # --- Smoothing buffer (lấy trung bình N frame gần nhất) ---
        self.spoof_history = []  # List of (is_real, score)
        self.SMOOTH_FRAMES = 5  # Số frame để lấy trung bình
        
        # --- Statistics ---
        self.stats = {"real": 0, "fake": 0, "total": 0}
        
        # ============================================
        # GUI LAYOUT
        # ============================================
        
        # Control Panel (Bottom)
        self.control_frame = Frame(root, bg="#34495e", height=120)
        self.control_frame.pack(side=tk.BOTTOM, fill=tk.X)
        
        # Video Frame (Top)
        self.main_frame = Frame(root, bg="#2c3e50")
        self.main_frame.pack(side=tk.TOP, fill=tk.BOTH, expand=True, padx=10, pady=10)
        
        # Video Label
        self.video_label = Label(self.main_frame, bg="black", 
                                  text="Đang khởi tạo...", fg="white", font=("Arial", 14))
        self.video_label.pack(fill=tk.BOTH, expand=True)
        
        # --- Control Row 1: Checkboxes ---
        row1 = Frame(self.control_frame, bg="#34495e")
        row1.pack(fill=tk.X, pady=5)
        
        # Face Detection checkbox
        self.chk_face = Checkbutton(
            row1, text="🔍 Face Detection", 
            variable=self.face_detection_enabled,
            bg="#34495e", fg="white", selectcolor="#2c3e50",
            font=("Arial", 10, "bold"),
            activebackground="#34495e", activeforeground="white",
            state=tk.NORMAL if INSIGHTFACE_AVAILABLE else tk.DISABLED
        )
        self.chk_face.pack(side=tk.LEFT, padx=20)
        
        # Anti-Spoof checkbox
        self.chk_antispoof = Checkbutton(
            row1, text="🛡️ Anti-Spoofing", 
            variable=self.anti_spoof_enabled,
            bg="#34495e", fg="white", selectcolor="#2c3e50",
            font=("Arial", 10, "bold"),
            activebackground="#34495e", activeforeground="white",
            state=tk.NORMAL if ANTISPOOF_AVAILABLE else tk.DISABLED
        )
        self.chk_antispoof.pack(side=tk.LEFT, padx=20)
        
        # Status label
        self.lbl_status = Label(row1, text="Status: Đang tải model...", 
                                 bg="#34495e", fg="#f39c12", font=("Arial", 10))
        self.lbl_status.pack(side=tk.RIGHT, padx=20)
        
        # --- Control Row 2: Stats ---
        row2 = Frame(self.control_frame, bg="#34495e")
        row2.pack(fill=tk.X, pady=5)
        
        # Stats labels
        self.lbl_stats = Label(row2, text="Real: 0 | Fake: 0 | Total: 0", 
                                bg="#34495e", fg="#3498db", font=("Arial", 10, "bold"))
        self.lbl_stats.pack(side=tk.LEFT, padx=20)
        
        # Reset stats button
        Button(row2, text="🔄 Reset Stats", command=self.reset_stats,
               bg="#9b59b6", fg="white", font=("Arial", 9)).pack(side=tk.LEFT, padx=10)
        
        # --- Control Row 3: Buttons ---
        row3 = Frame(self.control_frame, bg="#34495e")
        row3.pack(fill=tk.X, pady=5)
        
        Button(row3, text="📸 Chụp Ảnh", command=self.snapshot,
               bg="#27ae60", fg="white", font=("Arical", 10, "bold"),
               padx=15, pady=5).pack(side=tk.LEFT, padx=20)
        
        Button(row3, text="❌ Thoát", command=self.on_close,
               bg="#c0392b", fg="white", font=("Arial", 10, "bold"),
               padx=15, pady=5).pack(side=tk.RIGHT, padx=20)
        
        # Camera info
        cam_type = "Webcam" if USE_WEBCAM else "RTSP"
        Label(row3, text=f"📹 {cam_type}: {camera_source}", 
              bg="#34495e", fg="#95a5a6", font=("Arial", 9)).pack(side=tk.RIGHT, padx=20)
        
        # ============================================
        # START THREADS
        # ============================================
        
        # Start video stream
        self.video_stream = RTSPVideoStream(self.camera_source).start()
        
        # Load AI models in background
        threading.Thread(target=self.init_models, daemon=True).start()
        
        # Start video update loop
        self.update_video()
    
    def init_models(self):
        """Tải các model AI trong background thread"""
        status_parts = []
        
        try:
            # 1. Face Detection model
            if INSIGHTFACE_AVAILABLE:
                print("🔄 Đang tải Face Detection model (buffalo_l)...")
                self.face_model = FaceAnalysis(
                    name='buffalo_l',
                    providers=['CUDAExecutionProvider', 'CPUExecutionProvider']
                )
                self.face_model.prepare(ctx_id=0, det_size=(640, 640))
                print("✅ Face Detection model đã sẵn sàng!")
                status_parts.append("Face ✓")
            else:
                status_parts.append("Face ✗")
            
            # 2. Anti-Spoof model
            if ANTISPOOF_AVAILABLE:
                if self.anti_spoof.load():
                    status_parts.append("AntiSpoof ✓")
                else:
                    status_parts.append("AntiSpoof ✗")
            else:
                status_parts.append("AntiSpoof ✗")
            
            # Update status
            status_text = "Status: " + " | ".join(status_parts)
            self.root.after(0, lambda: self.lbl_status.configure(
                text=status_text, fg="#27ae60"
            ))
            
        except Exception as e:
            print(f"❌ Lỗi tải model: {e}")
            import traceback
            traceback.print_exc()
            self.root.after(0, lambda: self.lbl_status.configure(
                text=f"Status: Error - {str(e)[:30]}", fg="#e74c3c"
            ))
    
    def reset_stats(self):
        """Reset thống kê"""
        self.stats = {"real": 0, "fake": 0, "total": 0}
        self.lbl_stats.configure(text="Real: 0 | Fake: 0 | Total: 0")
    
    def update_video(self):
        """Main video update loop"""
        if not self.is_playing:
            return

        frame = self.video_stream.read()
        
        if frame is not None:
            display_frame = frame.copy()
            
            # Face Detection + Anti-Spoofing
            if self.face_detection_enabled.get() and self.face_model is not None:
                try:
                    faces = self.face_model.get(frame)
                    
                    for face in faces:
                        bbox = face.bbox.astype(int)
                        
                        # Anti-Spoofing check
                        if self.anti_spoof_enabled.get():
                            if not self.anti_spoof.available:
                                # Debug: model chưa sẵn sàng
                                color = (255, 165, 0)  # Orange = loading
                                display_label = "LOADING..."
                            else:
                                is_real, score, label = self.anti_spoof.check(frame, face.bbox)
                                
                                # Smoothing: lưu kết quả và lấy trung bình
                                self.spoof_history.append((1 if is_real else 0, score))
                                if len(self.spoof_history) > self.SMOOTH_FRAMES:
                                    self.spoof_history.pop(0)
                                
                                # Tính trung bình
                                avg_real = sum(h[0] for h in self.spoof_history) / len(self.spoof_history)
                                avg_score = sum(h[1] for h in self.spoof_history) / len(self.spoof_history)
                                
                                # Quyết định dựa trên majority vote
                                is_real_smoothed = avg_real >= 0.5
                                
                                # Update stats (chỉ đếm khi đủ frames)
                                if len(self.spoof_history) >= self.SMOOTH_FRAMES:
                                    self.stats["total"] += 1
                                    if is_real_smoothed:
                                        self.stats["real"] += 1
                                        color = (0, 255, 0)  # Green = Real
                                        label = "REAL"
                                    else:
                                        self.stats["fake"] += 1
                                        color = (0, 0, 255)  # Red = Fake
                                        label = "FAKE"
                                else:
                                    color = (255, 165, 0)  # Orange = collecting
                                    label = "..."
                                
                                display_label = f"{label} {avg_score:.2f}"
                                
                                # Update stats label (throttled)
                                if self.stats["total"] % 5 == 0:
                                    self.lbl_stats.configure(
                                        text=f"Real: {self.stats['real']} | Fake: {self.stats['fake']} | Total: {self.stats['total']}"
                                    )
                        else:
                            color = (0, 255, 0)
                            display_label = f"{face.det_score:.2f}"
                        
                        # Draw bounding box
                        cv2.rectangle(display_frame, 
                                      (bbox[0], bbox[1]), (bbox[2], bbox[3]), 
                                      color, 2)
                        
                        # Draw label
                        cv2.putText(display_frame, display_label, 
                                    (bbox[0], bbox[1] - 10),
                                    cv2.FONT_HERSHEY_SIMPLEX, 0.7, color, 2)
                        
                        # Draw landmarks
                        if face.kps is not None:
                            for kp in face.kps.astype(int):
                                cv2.circle(display_frame, (kp[0], kp[1]), 2, (255, 0, 0), -1)
                                
                except Exception as e:
                    print(f"Detection error: {e}")
            
            # Convert to Tkinter image
            cv2image = cv2.cvtColor(display_frame, cv2.COLOR_BGR2RGB)
            img = Image.fromarray(cv2image)
            
            # Resize to fit window
            win_w = self.video_label.winfo_width()
            win_h = self.video_label.winfo_height()
            if win_w > 1 and win_h > 1:
                img = img.resize((win_w, win_h), Image.Resampling.LANCZOS)
            
            imgtk = ImageTk.PhotoImage(image=img)
            self.video_label.imgtk = imgtk
            self.video_label.configure(image=imgtk, text="")
        else:
            self.video_label.configure(text="📹 Đang kết nối camera...", fg="white")
        
        self.root.after(15, self.update_video)
    
    def snapshot(self):
        """Chụp và lưu ảnh"""
        frame = self.video_stream.read()
        if frame is not None:
            filename = f"snapshot_{int(time.time())}.jpg"
            cv2.imwrite(filename, frame)
            messagebox.showinfo("Thông báo", f"Đã lưu: {filename}")
        else:
            messagebox.showwarning("Cảnh báo", "Chưa có tín hiệu video!")
    
    def on_close(self):
        """Đóng ứng dụng"""
        self.is_playing = False
        self.video_stream.stop()
        self.root.destroy()


if __name__ == "__main__":
    # Chọn nguồn camera
    camera_source = WEBCAM_INDEX if USE_WEBCAM else RTSP_URL
    
    print("=" * 50)
    print("FUACS Face Recognition Demo")
    print("=" * 50)
    print(f"Camera: {'Webcam' if USE_WEBCAM else 'RTSP'}")
    print(f"Source: {camera_source}")
    print(f"InsightFace: {'✓' if INSIGHTFACE_AVAILABLE else '✗'}")
    print(f"AntiSpoof: {'✓' if ANTISPOOF_AVAILABLE else '✗'}")
    print("=" * 50)
    
    root = tk.Tk()
    app = App(root, camera_source)
    root.protocol("WM_DELETE_WINDOW", app.on_close)
    root.mainloop()
