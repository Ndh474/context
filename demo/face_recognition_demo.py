"""
FUACS Face Recognition Demo với Anti-Spoofing
- Face Detection: InsightFace buffalo_l
- Anti-Spoofing: Silent-Face (MiniFASNet)
- Hỗ trợ: Webcam và RTSP camera

Cách chạy:
    python face_recognition_demo.py
"""

import cv2
import threading
import tkinter as tk
from tkinter import Label, Button, Frame, messagebox, Checkbutton, BooleanVar
from PIL import Image, ImageTk
import time
import numpy as np
import os
import json

# ============================================
# CẤU HÌNH - THAY ĐỔI Ở ĐÂY
# ============================================
USE_WEBCAM = False  # True = webcam laptop, False = RTSP camera
# RTSP_URL = "rtsp://C200C_FUACS:12345678@192.168.0.113:554/stream1"
RTSP_URL = "rtsp://admin:admin@192.168.0.228:8554/live"
WEBCAM_INDEX = 0  # 0 = webcam mặc định

# Đường dẫn
ANTISPOOF_DIR = os.path.join(os.path.dirname(__file__), "anti_spoof")
FACE_DATABASE_PATH = os.path.join(os.path.dirname(__file__), "face_database.json")

# Face Recognition config
RECOGNITION_THRESHOLD = 0.5  # Cosine similarity threshold (0.5 = 50%)
DET_SIZE = (1280, 1280)  # Detection size: (640, 640), (1280, 1280), (1920, 1920)

# ============================================
# IMPORTS
# ============================================
INSIGHTFACE_AVAILABLE = False
ANTISPOOF_AVAILABLE = False

try:
    from insightface.app import FaceAnalysis
    INSIGHTFACE_AVAILABLE = True
except ImportError:
    print("⚠️ Chưa cài insightface")

try:
    from anti_spoof.models import MiniFASNetV1, MiniFASNetV2, MiniFASNetV1SE, MiniFASNetV2SE
    from anti_spoof.utils import parse_model_name, get_kernel, CropImage
    from anti_spoof.transform import Compose, ToTensor
    ANTISPOOF_AVAILABLE = True
    print("✅ Anti-Spoofing: Silent-Face ✓")
except ImportError as e:
    print(f"⚠️ Không thể import anti_spoof: {e}")


class RTSPVideoStream:
    """Đọc video stream trong thread riêng"""
    def __init__(self, src=0):
        self.src = src
        self.stream = None
        self.grabbed = False
        self.frame = None
        self.stop_event = False
        self.lock = threading.Lock()
        
    def start(self):
        threading.Thread(target=self.update, daemon=True).start()
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


def load_face_database(path):
    """Load face database từ JSON file"""
    if not os.path.exists(path):
        print(f"⚠️ Không tìm thấy face database: {path}")
        return []
    
    try:
        with open(path, 'r', encoding='utf-8') as f:
            data = json.load(f)
        persons = data.get('persons', [])
        # Convert embedding list to numpy array
        for p in persons:
            p['embedding'] = np.array(p['embedding'], dtype=np.float32)
        print(f"✅ Loaded {len(persons)} persons from face database")
        return persons
    except Exception as e:
        print(f"❌ Lỗi load face database: {e}")
        return []


def cosine_similarity(emb1, emb2):
    """Tính cosine similarity giữa 2 embedding vectors"""
    dot = np.dot(emb1, emb2)
    norm1 = np.linalg.norm(emb1)
    norm2 = np.linalg.norm(emb2)
    if norm1 == 0 or norm2 == 0:
        return 0.0
    return dot / (norm1 * norm2)


def recognize_face(embedding, database, threshold=RECOGNITION_THRESHOLD):
    """
    So sánh embedding với database, trả về person match nhất
    Returns: (person_id, person_name, similarity) hoặc (None, "Unknown", best_sim)
    """
    if not database:
        return None, "No DB", 0.0
    
    best_match = None
    best_sim = -1.0
    
    for person in database:
        sim = cosine_similarity(embedding, person['embedding'])
        if sim > best_sim:
            best_sim = sim
            best_match = person
    
    if best_sim >= threshold and best_match:
        return best_match['id'], best_match['name'], best_sim
    
    return None, "Unknown", best_sim


def is_frontal_face(kps, threshold=0.25):
    """
    Kiểm tra mặt có đang nhìn chính diện không dựa trên keypoints.
    kps: 5 keypoints [left_eye, right_eye, nose, left_mouth, right_mouth]
    threshold: tỷ lệ chênh lệch cho phép (0.25 = 25%)
    Returns: (is_frontal, yaw_ratio)
    """
    if kps is None or len(kps) < 5:
        return True, 0.0
    
    left_eye, right_eye, nose = kps[0], kps[1], kps[2]
    
    # Tính khoảng cách từ mũi đến 2 mắt
    dist_left = np.sqrt((nose[0] - left_eye[0])**2 + (nose[1] - left_eye[1])**2)
    dist_right = np.sqrt((nose[0] - right_eye[0])**2 + (nose[1] - right_eye[1])**2)
    
    # Tỷ lệ chênh lệch
    if max(dist_left, dist_right) == 0:
        return True, 0.0
    
    ratio = abs(dist_left - dist_right) / max(dist_left, dist_right)
    is_frontal = ratio < threshold
    
    return is_frontal, ratio


class AntiSpoofEngine:
    """Engine quản lý Silent-Face anti-spoofing"""
    
    def __init__(self, device_id=0):
        self.device_id = device_id
        self.device = None
        self.models = {}
        self.image_cropper = None
        self.available = False
        
    def load(self):
        """Tải models"""
        if not ANTISPOOF_AVAILABLE:
            return False
            
        import torch
        
        self.device = torch.device(f"cuda:{self.device_id}" if torch.cuda.is_available() else "cpu")
        print(f"🔄 Device: {self.device}")
        
        try:
            print("🔄 Đang tải Silent-Face models...")
            
            model_files = [f for f in os.listdir(ANTISPOOF_DIR) 
                          if f.endswith('.pth') and 'MiniFAS' in f]
            MODEL_MAPPING = {
                'MiniFASNetV1': MiniFASNetV1, 'MiniFASNetV2': MiniFASNetV2,
                'MiniFASNetV1SE': MiniFASNetV1SE, 'MiniFASNetV2SE': MiniFASNetV2SE
            }
            
            for model_name in model_files:
                h_input, w_input, model_type, scale = parse_model_name(model_name)
                kernel_size = get_kernel(h_input, w_input)
                
                model = MODEL_MAPPING[model_type](conv6_kernel=kernel_size).to(self.device)
                model_path = os.path.join(ANTISPOOF_DIR, model_name)
                
                state_dict = torch.load(model_path, map_location=self.device, weights_only=True)
                if list(state_dict.keys())[0].startswith('module.'):
                    from collections import OrderedDict
                    state_dict = OrderedDict((k[7:], v) for k, v in state_dict.items())
                
                model.load_state_dict(state_dict)
                model.eval()
                
                self.models[model_name] = {
                    'model': model, 'h_input': h_input, 'w_input': w_input, 'scale': scale
                }
                print(f"   ✓ {model_name}")
            
            self.image_cropper = CropImage()
            self.available = len(self.models) > 0
            print("✅ Silent-Face đã sẵn sàng!")
            return self.available
            
        except Exception as e:
            print(f"❌ Lỗi tải Silent-Face: {e}")
            return False
    
    def check(self, frame, bbox):
        """
        Kiểm tra liveness
        Returns: (is_real, score, label)
        """
        if not self.available:
            return True, 0.5, "N/A"
            
        import torch
        import torch.nn.functional as F
        
        x1, y1, x2, y2 = [int(v) for v in bbox]
        image_bbox = [x1, y1, x2 - x1, y2 - y1]
        if image_bbox[2] <= 0 or image_bbox[3] <= 0:
            return True, 0.5, "N/A"
        
        prediction = np.zeros((1, 3))
        test_transform = Compose([ToTensor()])
        
        for model_info in self.models.values():
            param = {
                "org_img": frame, "bbox": image_bbox,
                "scale": model_info['scale'],
                "out_w": model_info['w_input'], "out_h": model_info['h_input'],
                "crop": model_info['scale'] is not None,
            }
            img = self.image_cropper.crop(**param)
            img_tensor = test_transform(img).unsqueeze(0).to(self.device)
            
            with torch.no_grad():
                result = model_info['model'](img_tensor)
                result = F.softmax(result, dim=1).cpu().numpy()
            prediction += result
        
        num_models = len(self.models)
        prediction = prediction / num_models
        
        # Log chi tiết 3 classes
        fake1, real, fake2 = prediction[0]
        label_idx = np.argmax(prediction)
        score = prediction[0][label_idx]
        is_real = label_idx == 1
        
        print(f"[SF] fake1={fake1:.3f}, real={real:.3f}, fake2={fake2:.3f} → {'REAL' if is_real else 'FAKE'} {score:.3f}")
        
        return is_real, float(score), "REAL" if is_real else "FAKE"


class App:
    def __init__(self, root, camera_source):
        self.root = root
        self.root.title("FUACS Demo - Face Recognition + Anti-Spoofing")
        self.root.geometry("1150x780")
        self.root.configure(bg="#2c3e50")

        self.camera_source = camera_source
        self.is_playing = True
        
        # --- AI Models ---
        self.face_detection_enabled = BooleanVar(value=False)
        self.anti_spoof_enabled = BooleanVar(value=False)
        self.face_recognition_enabled = BooleanVar(value=False)
        self.face_model = None
        self.anti_spoof = AntiSpoofEngine(device_id=0)
        self.face_database = []
        
        # --- Statistics ---
        self.stats = {"real": 0, "fake": 0, "total": 0}
        
        # ============================================
        # GUI LAYOUT
        # ============================================
        
        # Control Panel (Bottom)
        self.control_frame = Frame(root, bg="#34495e", height=140)
        self.control_frame.pack(side=tk.BOTTOM, fill=tk.X)
        
        # Video Frame (Top)
        self.main_frame = Frame(root, bg="#2c3e50")
        self.main_frame.pack(side=tk.TOP, fill=tk.BOTH, expand=True, padx=10, pady=10)
        
        self.video_label = Label(self.main_frame, bg="black", 
                                  text="Đang khởi tạo...", fg="white", font=("Arial", 14))
        self.video_label.pack(fill=tk.BOTH, expand=True)
        
        # --- Row 1: Checkboxes ---
        row1 = Frame(self.control_frame, bg="#34495e")
        row1.pack(fill=tk.X, pady=5)
        
        Checkbutton(row1, text="🔍 Face Detection", variable=self.face_detection_enabled,
                    bg="#34495e", fg="white", selectcolor="#2c3e50", font=("Arial", 10, "bold"),
                    activebackground="#34495e", activeforeground="white",
                    state=tk.NORMAL if INSIGHTFACE_AVAILABLE else tk.DISABLED
        ).pack(side=tk.LEFT, padx=15)
        
        Checkbutton(row1, text="🛡️ Anti-Spoofing", variable=self.anti_spoof_enabled,
                    bg="#34495e", fg="white", selectcolor="#2c3e50", font=("Arial", 10, "bold"),
                    activebackground="#34495e", activeforeground="white",
                    state=tk.NORMAL if ANTISPOOF_AVAILABLE else tk.DISABLED
        ).pack(side=tk.LEFT, padx=15)
        
        Checkbutton(row1, text="👤 Face Recognition", variable=self.face_recognition_enabled,
                    bg="#34495e", fg="white", selectcolor="#2c3e50", font=("Arial", 10, "bold"),
                    activebackground="#34495e", activeforeground="white",
                    state=tk.NORMAL if INSIGHTFACE_AVAILABLE else tk.DISABLED
        ).pack(side=tk.LEFT, padx=15)
        
        self.lbl_status = Label(row1, text="Status: Đang tải...", 
                                 bg="#34495e", fg="#f39c12", font=("Arial", 10))
        self.lbl_status.pack(side=tk.RIGHT, padx=20)
        
        # --- Row 2: Stats ---
        row2 = Frame(self.control_frame, bg="#34495e")
        row2.pack(fill=tk.X, pady=5)
        
        self.lbl_stats = Label(row2, text="Real: 0 | Fake: 0 | Total: 0", 
                                bg="#34495e", fg="#3498db", font=("Arial", 10, "bold"))
        self.lbl_stats.pack(side=tk.LEFT, padx=20)
        
        Button(row2, text="🔄 Reset", command=self.reset_stats,
               bg="#9b59b6", fg="white", font=("Arial", 9)).pack(side=tk.LEFT, padx=10)
        
        self.lbl_model_info = Label(row2, text="", bg="#34495e", fg="#95a5a6", font=("Arial", 9))
        self.lbl_model_info.pack(side=tk.RIGHT, padx=20)
        
        # --- Row 3: Buttons ---
        row3 = Frame(self.control_frame, bg="#34495e")
        row3.pack(fill=tk.X, pady=5)
        
        Button(row3, text="📸 Chụp Ảnh", command=self.snapshot,
               bg="#27ae60", fg="white", font=("Arial", 10, "bold"),
               padx=15, pady=5).pack(side=tk.LEFT, padx=20)
        
        Button(row3, text="❌ Thoát", command=self.on_close,
               bg="#c0392b", fg="white", font=("Arial", 10, "bold"),
               padx=15, pady=5).pack(side=tk.RIGHT, padx=20)
        
        cam_type = "Webcam" if USE_WEBCAM else "RTSP"
        Label(row3, text=f"📹 {cam_type}: {camera_source}", 
              bg="#34495e", fg="#95a5a6", font=("Arial", 9)).pack(side=tk.RIGHT, padx=20)
        
        # ============================================
        # START
        # ============================================
        self.video_stream = RTSPVideoStream(self.camera_source).start()
        threading.Thread(target=self.init_models, daemon=True).start()
        self.update_video()
    
    def init_models(self):
        """Tải models"""
        status_parts = []
        
        try:
            if INSIGHTFACE_AVAILABLE:
                print("🔄 Đang tải Face Detection...")
                self.face_model = FaceAnalysis(name='buffalo_l',
                    providers=['CUDAExecutionProvider', 'CPUExecutionProvider'])
                self.face_model.prepare(ctx_id=0, det_size=DET_SIZE)
                status_parts.append("Face ✓")
            else:
                status_parts.append("Face ✗")
            
            if ANTISPOOF_AVAILABLE:
                if self.anti_spoof.load():
                    status_parts.append("AntiSpoof ✓")
                else:
                    status_parts.append("AntiSpoof ✗")
            
            # Load face database
            self.face_database = load_face_database(FACE_DATABASE_PATH)
            if self.face_database:
                status_parts.append(f"DB: {len(self.face_database)}")
            else:
                status_parts.append("DB ✗")
            
            status_text = " | ".join(status_parts)
            self.root.after(0, lambda: self.lbl_status.configure(text=f"Status: {status_text}", fg="#27ae60"))
            
        except Exception as e:
            print(f"❌ Lỗi: {e}")
            self.root.after(0, lambda: self.lbl_status.configure(text=f"Error: {str(e)[:30]}", fg="#e74c3c"))
    
    def reset_stats(self):
        self.stats = {"real": 0, "fake": 0, "total": 0}
        self.lbl_stats.configure(text="Real: 0 | Fake: 0 | Total: 0")
    
    def update_video(self):
        if not self.is_playing:
            return

        frame = self.video_stream.read()
        
        if frame is not None:
            display_frame = frame.copy()
            
            if self.face_detection_enabled.get() and self.face_model is not None:
                try:
                    faces = self.face_model.get(frame)
                    
                    for face in faces:
                        bbox = face.bbox.astype(int)
                        
                        # Anti-Spoofing check (chỉ kiểm tra frontal khi bật anti-spoof)
                        if self.anti_spoof_enabled.get():
                            # Kiểm tra mặt có nhìn thẳng không
                            is_frontal, yaw_ratio = is_frontal_face(face.kps, threshold=0.25)
                            
                            if not is_frontal:
                                # Mặt nghiêng → skip anti-spoof
                                color = (0, 255, 255)  # Yellow
                                display_label = f"TURN {yaw_ratio:.2f}"
                                cv2.rectangle(display_frame, (bbox[0], bbox[1]), (bbox[2], bbox[3]), color, 2)
                                cv2.putText(display_frame, display_label, (bbox[0], bbox[1] - 10),
                                            cv2.FONT_HERSHEY_SIMPLEX, 0.7, color, 2)
                                if face.kps is not None:
                                    for kp in face.kps.astype(int):
                                        cv2.circle(display_frame, (kp[0], kp[1]), 2, (255, 0, 0), -1)
                                continue
                            is_real, spoof_score, spoof_label = self.anti_spoof.check(frame, face.bbox)
                            
                            # Update stats
                            self.stats["total"] += 1
                            if is_real:
                                self.stats["real"] += 1
                            else:
                                self.stats["fake"] += 1
                                color = (0, 0, 255)  # Red for FAKE
                                display_label = f"FAKE {spoof_score:.2f}"
                                cv2.rectangle(display_frame, (bbox[0], bbox[1]), (bbox[2], bbox[3]), color, 2)
                                cv2.putText(display_frame, display_label, (bbox[0], bbox[1] - 10),
                                            cv2.FONT_HERSHEY_SIMPLEX, 0.7, color, 2)
                                if face.kps is not None:
                                    for kp in face.kps.astype(int):
                                        cv2.circle(display_frame, (kp[0], kp[1]), 2, (255, 0, 0), -1)
                                self.lbl_stats.configure(
                                    text=f"Real: {self.stats['real']} | Fake: {self.stats['fake']} | Total: {self.stats['total']}")
                                continue
                            
                            self.lbl_stats.configure(
                                text=f"Real: {self.stats['real']} | Fake: {self.stats['fake']} | Total: {self.stats['total']}")
                        
                        # Face Recognition
                        if self.face_recognition_enabled.get() and face.embedding is not None:
                            person_id, person_name, similarity = recognize_face(
                                face.embedding, self.face_database, RECOGNITION_THRESHOLD)
                            
                            if person_id:
                                color = (0, 255, 0)  # Green - recognized
                                display_label = f"{person_id} ({similarity:.2f})"
                                self.lbl_model_info.configure(text=f"{person_name} | sim={similarity:.3f}")
                            else:
                                color = (0, 165, 255)  # Orange - unknown
                                display_label = f"Unknown ({similarity:.2f})"
                                self.lbl_model_info.configure(text=f"Unknown | best_sim={similarity:.3f}")
                        else:
                            color = (0, 255, 0)
                            display_label = f"{face.det_score:.2f}"
                        
                        cv2.rectangle(display_frame, (bbox[0], bbox[1]), (bbox[2], bbox[3]), color, 2)
                        cv2.putText(display_frame, display_label, (bbox[0], bbox[1] - 10),
                                    cv2.FONT_HERSHEY_SIMPLEX, 0.7, color, 2)
                        
                        if face.kps is not None:
                            for kp in face.kps.astype(int):
                                cv2.circle(display_frame, (kp[0], kp[1]), 2, (255, 0, 0), -1)
                                
                except Exception as e:
                    print(f"Error: {e}")
            
            cv2image = cv2.cvtColor(display_frame, cv2.COLOR_BGR2RGB)
            img = Image.fromarray(cv2image)
            
            win_w, win_h = self.video_label.winfo_width(), self.video_label.winfo_height()
            if win_w > 1 and win_h > 1:
                img = img.resize((win_w, win_h), Image.Resampling.LANCZOS)
            
            imgtk = ImageTk.PhotoImage(image=img)
            self.video_label.imgtk = imgtk
            self.video_label.configure(image=imgtk, text="")
        else:
            self.video_label.configure(text="📹 Đang kết nối...", fg="white")
        
        self.root.after(15, self.update_video)
    
    def snapshot(self):
        """
        Chụp ảnh với logic:
        - REAL: crop mặt + padding 50px (như recognition-service)
        - FAKE: wide crop (padding 200px) để thấy context xung quanh
        - Không có mặt hoặc không bật anti-spoof: full frame
        """
        frame = self.video_stream.read()
        if frame is None:
            messagebox.showwarning("Cảnh báo", "Chưa có video!")
            return
        
        timestamp = int(time.time())
        h, w = frame.shape[:2]
        
        # Nếu không bật face detection hoặc anti-spoof → lưu full frame
        if not self.face_detection_enabled.get() or self.face_model is None:
            filename = f"snapshot_full_{timestamp}.jpg"
            cv2.imwrite(filename, frame)
            messagebox.showinfo("Thông báo", f"Đã lưu full frame: {filename}")
            return
        
        # Detect faces
        faces = self.face_model.get(frame)
        if len(faces) == 0:
            filename = f"snapshot_noface_{timestamp}.jpg"
            cv2.imwrite(filename, frame)
            messagebox.showinfo("Thông báo", f"Không có mặt, lưu full frame: {filename}")
            return
        
        saved_files = []
        
        for i, face in enumerate(faces):
            bbox = face.bbox.astype(int)
            x1, y1, x2, y2 = bbox
            
            # Kiểm tra anti-spoof nếu bật
            if self.anti_spoof_enabled.get() and self.anti_spoof.available:
                is_real, score, label = self.anti_spoof.check(frame, face.bbox)
                
                if is_real:
                    # REAL → crop nhỏ như recognition-service (padding 50px)
                    padding = 50
                    crop_x1 = max(0, x1 - padding)
                    crop_y1 = max(0, y1 - padding)
                    crop_x2 = min(w, x2 + padding)
                    crop_y2 = min(h, y2 + padding)
                    
                    face_crop = frame[crop_y1:crop_y2, crop_x1:crop_x2]
                    filename = f"snapshot_REAL_{score:.2f}_{timestamp}_{i}.jpg"
                    cv2.imwrite(filename, face_crop)
                    saved_files.append(f"✅ {filename}")
                else:
                    # FAKE → wide crop (padding 200px) để thấy iPad/điện thoại
                    wide_padding = 200
                    crop_x1 = max(0, x1 - wide_padding)
                    crop_y1 = max(0, y1 - wide_padding)
                    crop_x2 = min(w, x2 + wide_padding)
                    crop_y2 = min(h, y2 + wide_padding)
                    
                    wide_crop = frame[crop_y1:crop_y2, crop_x1:crop_x2]
                    filename = f"snapshot_FAKE_{score:.2f}_{timestamp}_{i}.jpg"
                    cv2.imwrite(filename, wide_crop)
                    saved_files.append(f"🚨 {filename}")
                    
                    # Bonus: lưu thêm full frame cho FAKE
                    full_filename = f"snapshot_FAKE_FULL_{timestamp}_{i}.jpg"
                    cv2.imwrite(full_filename, frame)
                    saved_files.append(f"🚨 {full_filename} (full)")
            else:
                # Không bật anti-spoof → crop bình thường
                padding = 50
                crop_x1 = max(0, x1 - padding)
                crop_y1 = max(0, y1 - padding)
                crop_x2 = min(w, x2 + padding)
                crop_y2 = min(h, y2 + padding)
                
                face_crop = frame[crop_y1:crop_y2, crop_x1:crop_x2]
                filename = f"snapshot_face_{timestamp}_{i}.jpg"
                cv2.imwrite(filename, face_crop)
                saved_files.append(filename)
        
        messagebox.showinfo("Đã lưu", "\n".join(saved_files))
    
    def on_close(self):
        self.is_playing = False
        self.video_stream.stop()
        self.root.destroy()


if __name__ == "__main__":
    camera_source = WEBCAM_INDEX if USE_WEBCAM else RTSP_URL
    
    print("=" * 50)
    print("FUACS Face Recognition Demo")
    print("=" * 50)
    print(f"Camera: {'Webcam' if USE_WEBCAM else 'RTSP'} ({camera_source})")
    print(f"InsightFace: {'✓' if INSIGHTFACE_AVAILABLE else '✗'}")
    print(f"Silent-Face: {'✓' if ANTISPOOF_AVAILABLE else '✗'}")
    print("=" * 50)
    
    root = tk.Tk()
    app = App(root, camera_source)
    root.protocol("WM_DELETE_WINDOW", app.on_close)
    root.mainloop()
