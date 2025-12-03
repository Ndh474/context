import cv2
import threading
import tkinter as tk
from tkinter import Label, Button, Frame, messagebox, Checkbutton, BooleanVar
from PIL import Image, ImageTk
import time
import numpy as np

# Thử import insightface, nếu chưa cài thì sẽ báo lỗi nhẹ nhàng
try:
    import insightface
    from insightface.app import FaceAnalysis
    INSIGHTFACE_AVAILABLE = True
except ImportError:
    INSIGHTFACE_AVAILABLE = False
    print("Cảnh báo: Chưa cài đặt thư viện 'insightface'. Tính năng AI sẽ không hoạt động.")

class RTSPVideoStream:
    """
    Class này xử lý việc đọc luồng video trong một luồng (thread) riêng biệt.
    Điều này cực kỳ quan trọng đối với RTSP để tránh việc GUI bị đơ
    và giảm độ trễ (latency) do bộ đệm (buffer) tích tụ.
    """
    def __init__(self, src=0):
        self.src = src
        self.stream = None
        self.grabbed = False
        self.frame = None
        self.stop_event = False
        self.lock = threading.Lock()
        
    def start(self):
        t = threading.Thread(target=self.update, args=())
        t.daemon = True 
        t.start()
        return self

    def update(self):
        print(f"Luồng phụ: Đang bắt đầu kết nối tới {self.src}...")
        # Thử kết nối với backend ffmpeg (mặc định)
        self.stream = cv2.VideoCapture(self.src)
        
        if self.stream.isOpened():
            self.stream.set(cv2.CAP_PROP_BUFFERSIZE, 1)
            print("Luồng phụ: Kết nối thành công!")
        else:
            print("Luồng phụ: Không thể kết nối tới nguồn RTSP.")
            self.stop_event = True
            return

        while not self.stop_event:
            if not self.stream.isOpened():
                break
            
            (grabbed, frame) = self.stream.read()
            
            with self.lock:
                self.grabbed = grabbed
                self.frame = frame
            
            # Nghỉ cực ngắn để giảm tải CPU, nhưng đủ nhanh để clear buffer
            time.sleep(0.005) 
        
        self.stream.release()

    def read(self):
        with self.lock:
            return self.frame if self.grabbed else None

    def stop(self):
        self.stop_event = True

class App:
    def __init__(self, root, rtsp_url):
        self.root = root
        self.root.title("RTSP Camera Viewer - Face Recognition (Buffalo_L)")
        self.root.geometry("1000x700")
        self.root.configure(bg="#2c3e50")

        self.rtsp_url = rtsp_url
        self.is_playing = True
        
        # --- Cấu hình AI ---
        self.ai_enabled = BooleanVar(value=False)
        self.face_model = None
        
        if INSIGHTFACE_AVAILABLE:
            # Khởi tạo model trong luồng riêng để không treo GUI lúc mở app
            threading.Thread(target=self.init_insightface, daemon=True).start()

        # --- Giao diện (GUI) - SỬA LỖI LAYOUT ---
        # 1. Tạo và Pack thanh điều khiển TRƯỚC (để đảm bảo nó luôn nằm ở đáy)
        self.control_frame = Frame(root, bg="#34495e", height=60)
        self.control_frame.pack(side=tk.BOTTOM, fill=tk.X)

        # 2. Tạo và Pack khung video SAU (để nó chiếm phần không gian CÒN LẠI)
        self.main_frame = Frame(root, bg="#2c3e50")
        self.main_frame.pack(side=tk.TOP, fill=tk.BOTH, expand=True, padx=10, pady=10)

        # Label hiển thị video nằm trong main_frame
        self.video_label = Label(self.main_frame, bg="black", text="Đang khởi tạo kết nối...", fg="white", font=("Arial", 14))
        self.video_label.pack(fill=tk.BOTH, expand=True)

        # --- Các nút điều khiển trong control_frame ---
        # Nút Snapshot
        self.btn_snapshot = Button(self.control_frame, text="📸 Chụp Ảnh", command=self.snapshot, 
                                   bg="#27ae60", fg="white", font=("Arial", 10, "bold"), padx=15, pady=5)
        self.btn_snapshot.pack(side=tk.LEFT, padx=20, pady=10)

        # Checkbox bật tắt AI
        if INSIGHTFACE_AVAILABLE:
            self.chk_ai = Checkbutton(self.control_frame, text="Bật Quét Khuôn Mặt (Buffalo_L)", 
                                      variable=self.ai_enabled, bg="#34495e", fg="white", 
                                      selectcolor="#2c3e50", font=("Arial", 10, "bold"),
                                      activebackground="#34495e", activeforeground="white")
            self.chk_ai.pack(side=tk.LEFT, padx=20, pady=10)
        else:
            lbl_err = Label(self.control_frame, text="(Chưa cài insightface)", bg="#34495e", fg="yellow")
            lbl_err.pack(side=tk.LEFT, padx=20)

        # Nút Thoát
        self.btn_quit = Button(self.control_frame, text="Thoát", command=self.on_close, 
                               bg="#c0392b", fg="white", font=("Arial", 10, "bold"), padx=15, pady=5)
        self.btn_quit.pack(side=tk.RIGHT, padx=20, pady=10)

        # --- Bắt đầu luồng video ---
        print(f"Giao diện chính: Đã khởi chạy...")
        self.video_stream = RTSPVideoStream(self.rtsp_url).start()
        self.update_video()

    def init_insightface(self):
        """Tải model buffalo_l (có thể mất thời gian lần đầu để download)"""
        print("AI: Đang tải model buffalo_l...")
        try:
            # ctx_id=0 dùng GPU, ctx_id=-1 dùng CPU. 
            # det_size=(640, 640) cố định kích thước detect để tối ưu tốc độ.
            self.face_model = FaceAnalysis(name='buffalo_l', providers=['CUDAExecutionProvider', 'CPUExecutionProvider'])
            self.face_model.prepare(ctx_id=0, det_size=(640, 640))
            print("AI: Model buffalo_l đã sẵn sàng!")
        except Exception as e:
            print(f"AI: Lỗi tải model: {e}")

    def update_video(self):
        if not self.is_playing:
            return

        frame = self.video_stream.read()
        
        if frame is not None:
            # --- Xử lý AI nếu được bật ---
            if self.ai_enabled.get() and self.face_model is not None:
                try:
                    # Copy frame để không ảnh hưởng luồng gốc (tùy chọn)
                    display_frame = frame.copy()
                    
                    # Detect khuôn mặt
                    faces = self.face_model.get(display_frame)
                    
                    # Vẽ khung chữ nhật và landmarks
                    for face in faces:
                        # Bounding box
                        bbox = face.bbox.astype(int)
                        cv2.rectangle(display_frame, (bbox[0], bbox[1]), (bbox[2], bbox[3]), (0, 255, 0), 2)
                        
                        # Landmarks (Mắt, mũi, miệng) - 5 điểm
                        if face.kps is not None:
                            kps = face.kps.astype(int)
                            for kp in kps:
                                cv2.circle(display_frame, (kp[0], kp[1]), 2, (0, 0, 255), -1)
                                
                        # Hiển thị độ tin cậy (Score)
                        score = face.det_score
                        cv2.putText(display_frame, f"{score:.2f}", (bbox[0], bbox[1] - 10), 
                                    cv2.FONT_HERSHEY_SIMPLEX, 0.5, (0, 255, 0), 2)

                    frame = display_frame
                except Exception as e:
                    print(f"Lỗi AI detect: {e}")

            # --- Chuyển đổi để hiển thị ---
            cv2image = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
            img = Image.fromarray(cv2image)
            
            # Resize thông minh
            win_width = self.video_label.winfo_width()
            win_height = self.video_label.winfo_height()
            if win_width > 1 and win_height > 1:
                img = img.resize((win_width, win_height), Image.Resampling.LANCZOS)

            imgtk = ImageTk.PhotoImage(image=img)
            self.video_label.imgtk = imgtk 
            self.video_label.configure(image=imgtk, text="")
        else:
            self.video_label.configure(text="Đang kết nối tới Camera...\n(Vui lòng chờ)", fg="white")
        
        # Gọi lại sau 10ms
        self.root.after(10, self.update_video)

    def snapshot(self):
        frame = self.video_stream.read()
        if frame is not None:
            filename = f"snapshot_{int(time.time())}.jpg"
            # Nếu đang bật AI, ta có thể muốn lưu cả ảnh gốc chưa vẽ box
            # Code hiện tại lưu ảnh gốc từ stream (không có box xanh)
            cv2.imwrite(filename, frame)
            messagebox.showinfo("Thông báo", f"Đã lưu ảnh gốc: {filename}")
        else:
            messagebox.showwarning("Cảnh báo", "Chưa có tín hiệu video!")

    def on_close(self):
        self.is_playing = False
        self.video_stream.stop()
        self.root.destroy()

if __name__ == "__main__":
    # --- CẤU HÌNH ---
    RTSP_URL = "rtsp://admin:admin@192.168.0.228:8554/live"

    root = tk.Tk()
    app = App(root, RTSP_URL)
    root.protocol("WM_DELETE_WINDOW", app.on_close)
    root.mainloop()