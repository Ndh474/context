# 🎓 RECOGNITION SERVICE - CÂU HỎI & TRẢ LỜI CHO BẢO VỆ

> Tài liệu này tổng hợp các câu hỏi hội đồng có thể hỏi về Recognition Service,
> kèm theo cách giải thích đơn giản, dễ hiểu cho sinh viên.

---

## MỤC LỤC

1. [Face Recognition cơ bản](#1-face-recognition-cơ-bản)
2. [Kiến trúc hệ thống](#2-kiến-trúc-hệ-thống)
3. [Xử lý video stream](#3-xử-lý-video-stream)
4. [Tình huống thực tế](#4-tình-huống-thực-tế)
5. [Xử lý lỗi](#5-xử-lý-lỗi)
6. [Deduplication và Consistency](#6-deduplication-và-consistency)
7. [Hiệu năng](#7-hiệu-năng)
8. [Scalability](#8-scalability)
9. [Bảo mật](#9-bảo-mật)
10. [Accuracy và Quality](#10-accuracy-và-quality)
11. [Business Logic](#11-business-logic)
12. [Integration](#12-integration)

---

## 1. FACE RECOGNITION CƠ BẢN

### Q1.1: Embedding là gì? Tại sao lại là 512 chiều?

**Trả lời đơn giản:**

Embedding là cách "số hóa" khuôn mặt thành một dãy số để máy tính có thể so sánh.

**Hình dung như sau:**

- Mỗi khuôn mặt được chuyển thành **512 con số** (gọi là vector)
- Mỗi con số đại diện cho một "đặc điểm" nào đó của khuôn mặt
- Ví dụ đơn giản: số thứ 1 có thể liên quan đến khoảng cách 2 mắt, số thứ 2 liên quan đến độ cao mũi...
- (Thực tế AI tự học các đặc điểm này, con người không biết chính xác mỗi số nghĩa là gì)

**Tại sao 512?**

- Quá ít (VD: 128) → không đủ để phân biệt nhiều người
- Quá nhiều (VD: 2048) → tính toán chậm, tốn bộ nhớ
- 512 là con số **cân bằng** được các nhà nghiên cứu tìm ra qua thực nghiệm
- Với 512 chiều, có thể phân biệt được **hàng triệu người** khác nhau

**Ví dụ minh họa:**

```
Nguyễn Văn A: [0.123, -0.456, 0.789, ..., 0.234]  ← 512 số
Trần Thị B:   [0.234, -0.567, 0.890, ..., 0.345]  ← 512 số
```

---

### Q1.2: Cosine Similarity hoạt động như thế nào? Tại sao chọn cosine thay vì Euclidean distance?

**Trả lời đơn giản:**

**Cosine Similarity** đo **góc** giữa 2 vectors, không quan tâm đến độ dài.

**Hình dung:**

- Tưởng tượng 2 mũi tên xuất phát từ cùng 1 điểm
- Nếu 2 mũi tên **cùng hướng** → góc = 0° → similarity = 1 (giống nhau)
- Nếu 2 mũi tên **vuông góc** → góc = 90° → similarity = 0 (không liên quan)
- Nếu 2 mũi tên **ngược hướng** → góc = 180° → similarity = -1 (ngược nhau)

```
Cùng hướng (similarity = 1):     Vuông góc (similarity = 0):
        ↗                              ↑
       ↗                               →
      A,B                             A  B
```

**Tại sao không dùng Euclidean (khoảng cách thông thường)?**

- **Euclidean** đo khoảng cách giữa 2 điểm trong không gian
- Vấn đề: Nếu 2 vectors có **cùng hướng** nhưng **khác độ dài**, Euclidean sẽ cho kết quả khác nhau
- **Cosine** chỉ quan tâm **hướng**, không quan tâm độ dài
- Embeddings từ InsightFace đã được **normalize** (chuẩn hóa độ dài = 1), nên Cosine phù hợp hơn

**Ví dụ thực tế:**

```
Sinh viên A (trong DB):     [0.5, 0.5, 0.5, ...]
Sinh viên A (từ camera):    [0.51, 0.49, 0.52, ...]  ← Hơi khác do ánh sáng, góc chụp

Cosine similarity = 0.98 → Rất giống → MATCH!
```

---

### Q1.3: Ngưỡng similarity 0.55 có ý nghĩa gì? Làm sao chọn được con số này?

**Trả lời đơn giản:**

**Ngưỡng (threshold)** là "điểm cắt" để quyết định có phải cùng 1 người hay không.

**Ý nghĩa:**

- Similarity >= 0.55 → **MATCH** (cùng 1 người)
- Similarity < 0.55 → **KHÔNG MATCH** (khác người)

**Tại sao là 0.55?**

Đây là kết quả của việc **thử nghiệm thực tế**:

```
Ngưỡng thấp (0.40):
├── Ưu điểm: Ít bỏ sót (sinh viên dễ được điểm danh)
└── Nhược điểm: Dễ nhận nhầm người khác

Ngưỡng cao (0.70):
├── Ưu điểm: Rất chính xác, không nhận nhầm
└── Nhược điểm: Dễ bỏ sót (sinh viên không được điểm danh dù có mặt)

Ngưỡng 0.55:
└── Cân bằng giữa 2 yếu tố trên
```

**Cách chọn trong thực tế:**

- **Điểm danh thường**: 0.55 (cân bằng)
- **Thi cử**: 0.60-0.65 (nghiêm ngặt hơn, tránh gian lận)
- **Ánh sáng kém**: 0.50 (nới lỏng vì chất lượng ảnh giảm)

---

### Q1.4: ArcFace là gì? Tại sao model này tốt cho face recognition?

**Trả lời đơn giản:**

**ArcFace** là một **thuật toán học sâu (deep learning)** được thiết kế đặc biệt cho nhận diện khuôn mặt.

**Tại sao tốt?**

1. **Tách biệt rõ ràng**: ArcFace được train để đảm bảo:

   - Embeddings của **cùng 1 người** → gần nhau
   - Embeddings của **khác người** → xa nhau

2. **State-of-the-art**: Đạt độ chính xác cao nhất trên các benchmark (LFW, CFP-FP, AgeDB)

3. **Đã được train sẵn**: Model `buffalo_l` đã được train trên **hàng triệu khuôn mặt**, chúng ta chỉ cần sử dụng

**Hình dung:**

```
Trước khi train:                    Sau khi train (ArcFace):
    A1  B1  A2  B2                      A1 A2    B1 B2
     •   •   •   •                       • •      • •
    (lộn xộn)                         (cùng người gần nhau)
```

**Trong hệ thống FUACS:**

- Sử dụng model **buffalo_l** (đã train sẵn)
- Không cần train lại
- Chỉ cần gọi API để lấy embedding

---

### Q1.5: Sự khác nhau giữa Face Detection và Face Recognition?

**Trả lời đơn giản:**

| Khái niệm            | Nhiệm vụ                       | Output                       |
| -------------------- | ------------------------------ | ---------------------------- |
| **Face Detection**   | Tìm vị trí khuôn mặt trong ảnh | Tọa độ (x, y, width, height) |
| **Face Recognition** | Xác định đây là AI             | Tên/ID của người đó          |

**Ví dụ:**

```
Ảnh đầu vào: [Ảnh lớp học có 30 sinh viên]

Face Detection:
└── Output: "Có 30 khuôn mặt tại vị trí (x1,y1), (x2,y2), ..."

Face Recognition:
└── Output: "Khuôn mặt 1 là Nguyễn Văn A, khuôn mặt 2 là Trần Thị B, ..."
```

**Trong hệ thống FUACS:**

1. **Detection** (SCRFD): Tìm tất cả khuôn mặt trong frame camera
2. **Recognition** (ArcFace): So khớp từng khuôn mặt với database sinh viên

```
Frame từ camera
      │
      ▼
┌─────────────┐
│  Detection  │ → Tìm được 5 khuôn mặt
└─────────────┘
      │
      ▼
┌─────────────┐
│ Recognition │ → Khuôn mặt 1 = SE171234, khuôn mặt 2 = SE171235, ...
└─────────────┘
```

---

## 2. KIẾN TRÚC HỆ THỐNG

### Q2.1: Tại sao tách Recognition Service thành microservice riêng thay vì tích hợp vào Java Backend?

**Trả lời đơn giản:**

**Lý do chính:**

1. **Ngôn ngữ phù hợp:**

   - AI/ML libraries (InsightFace, OpenCV) chủ yếu viết bằng **Python**
   - Java có thể gọi Python nhưng phức tạp và chậm
   - Tách riêng → mỗi service dùng ngôn ngữ phù hợp nhất

2. **Tài nguyên độc lập:**

   - Face recognition cần **GPU** và **nhiều RAM** (model ~600MB)
   - Nếu gộp chung → khi recognition bận, cả backend bị ảnh hưởng
   - Tách riêng → có thể scale độc lập

3. **Dễ bảo trì:**

   - Team AI có thể làm việc độc lập với team Backend
   - Cập nhật model không ảnh hưởng đến backend
   - Dễ test và debug riêng

4. **Fault isolation:**
   - Nếu Recognition Service crash → Backend vẫn hoạt động bình thường
   - Các chức năng khác (xem lịch, quản lý lớp) không bị ảnh hưởng

```
Kiến trúc Microservice:
┌─────────────┐     ┌─────────────┐     ┌─────────────────┐
│  Frontend   │────▶│   Backend   │────▶│ Recognition Svc │
│  (Next.js)  │     │   (Java)    │     │    (Python)     │
└─────────────┘     └─────────────┘     └─────────────────┘
                          │
                    Nếu Recognition
                    crash, Backend
                    vẫn chạy bình thường
```

---

### Q2.2: Tại sao chọn Python/FastAPI thay vì Java cho service này?

**Trả lời đơn giản:**

**Lý do chọn Python:**

1. **Hệ sinh thái AI/ML:**

   - InsightFace, OpenCV, NumPy đều là thư viện Python
   - Không có tương đương tốt trong Java
   - Cộng đồng AI/ML chủ yếu dùng Python

2. **Dễ prototype:**
   - Python code ngắn gọn, dễ đọc
   - Thử nghiệm nhanh các thuật toán

**Lý do chọn FastAPI:**

1. **Async native:**

   - Xử lý nhiều cameras cùng lúc mà không block
   - Phù hợp với I/O-bound tasks (đọc camera, gửi callback)

2. **Performance:**

   - Nhanh nhất trong các Python web frameworks
   - Gần bằng Node.js và Go

3. **Auto documentation:**

   - Tự động tạo Swagger UI
   - Dễ test API

4. **Type hints:**
   - Pydantic validation
   - Dễ maintain code

```
So sánh:
┌────────────┬─────────────────────────────────────┐
│ Framework  │ Đặc điểm                            │
├────────────┼─────────────────────────────────────┤
│ Flask      │ Đơn giản nhưng sync, chậm           │
│ Django     │ Quá nặng cho microservice           │
│ FastAPI    │ Async, nhanh, auto docs ← CHỌN      │
└────────────┴─────────────────────────────────────┘
```

---

### Q2.3: Callback pattern là gì? Tại sao không dùng request-response thông thường?

**Trả lời đơn giản:**

**Request-Response thông thường:**

```
Client gửi request → Server xử lý → Server trả response → Client nhận
(Client phải đợi cho đến khi xong)
```

**Callback pattern:**

```
Client gửi request → Server nhận, trả "OK, tôi đã nhận" → Client tiếp tục làm việc khác
                     Server xử lý xong → Server GỌI LẠI (callback) cho Client
```

**Tại sao dùng Callback cho điểm danh?**

1. **Xử lý lâu:**

   - Điểm danh có thể kéo dài 5-10 phút
   - Không thể giữ HTTP connection lâu như vậy

2. **Kết quả liên tục:**

   - Mỗi khi nhận diện được 1 sinh viên → gửi callback ngay
   - Không phải đợi hết buổi mới có kết quả

3. **Non-blocking:**
   - Java Backend gọi "Bắt đầu điểm danh" → nhận response ngay
   - Recognition Service chạy background, gửi callback khi có kết quả

```
Luồng thực tế:

Java Backend                    Recognition Service
     │                                  │
     │ POST /start-session              │
     │─────────────────────────────────▶│
     │                                  │
     │ Response: "OK, đã bắt đầu"       │
     │◀─────────────────────────────────│
     │                                  │
     │ (Backend tiếp tục xử lý          │ (Recognition chạy background)
     │  request khác)                   │
     │                                  │
     │ Callback: "Nhận diện được A"     │
     │◀─────────────────────────────────│
     │                                  │
     │ Callback: "Nhận diện được B"     │
     │◀─────────────────────────────────│
     │                                  │
     │ ... (tiếp tục)                   │
```

---

### Q2.4: Session được lưu ở đâu? Điều gì xảy ra khi service restart?

**Trả lời đơn giản:**

**Session lưu ở đâu?**

- Lưu trong **RAM** (in-memory) của Recognition Service
- Sử dụng Python dictionary: `{slot_id: SessionState}`

**Khi service restart:**

- **Tất cả sessions bị mất**
- Các buổi điểm danh đang chạy sẽ bị dừng đột ngột
- Cần bắt đầu lại từ đầu

**Tại sao chấp nhận được?**

1. **Use case phù hợp:**

   - Điểm danh thường chỉ kéo dài 5-10 phút
   - Service hiếm khi restart trong giờ học

2. **Performance:**

   - Đọc/ghi RAM cực nhanh (nanoseconds)
   - Không cần query database mỗi frame

3. **Simplicity:**
   - Code đơn giản, dễ maintain
   - Không cần setup Redis/database riêng

**Nếu muốn cải thiện (production):**

```
Hiện tại:                       Cải thiện:
┌─────────────────┐             ┌─────────────────┐
│ Recognition Svc │             │ Recognition Svc │
│  ┌───────────┐  │             │                 │
│  │  Session  │  │             │                 │
│  │  (RAM)    │  │             └────────┬────────┘
│  └───────────┘  │                      │
└─────────────────┘                      ▼
                                ┌─────────────────┐
                                │     Redis       │
                                │  (Session DB)   │
                                └─────────────────┘
```

---

## 3. XỬ LÝ VIDEO STREAM

### Q3.1: RTSP là gì? Tại sao dùng RTSP thay vì HTTP streaming?

**Trả lời đơn giản:**

**RTSP (Real Time Streaming Protocol):**

- Giao thức truyền video **thời gian thực** từ IP cameras
- Được thiết kế đặc biệt cho video surveillance

**So sánh:**

```
┌──────────────┬─────────────────────────────────────────────┐
│ Giao thức    │ Đặc điểm                                    │
├──────────────┼─────────────────────────────────────────────┤
│ HTTP         │ - Phổ biến, dễ dùng                         │
│ Streaming    │ - Độ trễ cao (2-10 giây)                    │
│              │ - Tốn bandwidth (phải encode lại)           │
├──────────────┼─────────────────────────────────────────────┤
│ RTSP         │ - Độ trễ thấp (< 1 giây)                    │
│              │ - Truyền trực tiếp từ camera                │
│              │ - Hầu hết IP cameras đều hỗ trợ             │
│              │ - Có thể chọn TCP hoặc UDP                  │
└──────────────┴─────────────────────────────────────────────┘
```

**URL RTSP điển hình:**

```
rtsp://admin:password@192.168.1.100:554/Streaming/Channels/101
       └─────┬─────┘ └──────┬──────┘└┬┘ └──────────┬─────────┘
         Username      IP camera   Port      Stream path
         Password
```

**Trong hệ thống FUACS:**

- Dùng **RTSP over TCP** (ổn định hơn UDP)
- OpenCV đọc RTSP stream trực tiếp
- Độ trễ ~200-500ms (chấp nhận được cho điểm danh)

---

### Q3.2: Scan interval là gì? Tại sao không xử lý mọi frame?

**Trả lời đơn giản:**

**Scan interval** là khoảng thời gian giữa 2 lần xử lý frame.

**Ví dụ:** Scan interval = 3 giây

```
Timeline:
0s ──── 3s ──── 6s ──── 9s ──── 12s
│       │       │       │       │
▼       ▼       ▼       ▼       ▼
Scan    Scan    Scan    Scan    Scan
```

**Tại sao không xử lý mọi frame?**

1. **Camera thường 25-30 FPS:**

   - 30 frames/giây = 1800 frames/phút
   - Xử lý hết → tốn rất nhiều CPU/GPU

2. **Không cần thiết:**

   - Sinh viên không di chuyển liên tục
   - Xử lý 1 frame/3 giây là đủ để nhận diện

3. **Tiết kiệm tài nguyên:**

   ```
   Xử lý mọi frame (30 FPS):     Scan interval 3s:
   - 1800 lần xử lý/phút         - 20 lần xử lý/phút
   - CPU/GPU 100%                - CPU/GPU ~5%
   - Nóng máy, tốn điện          - Mát máy, tiết kiệm
   ```

4. **Đủ nhanh cho use case:**
   - Sinh viên vào lớp → ngồi xuống → 3 giây sau được điểm danh
   - Hoàn toàn chấp nhận được

**Cấu hình trong hệ thống:**

- Mặc định: 1.5 - 3 giây
- Có thể điều chỉnh qua `config.scanInterval`

---

### Q3.3: Buffer flushing là gì? Tại sao cần flush buffer trước khi đọc frame?

**Trả lời đơn giản:**

**Vấn đề:**

- Camera RTSP có **buffer** (bộ đệm) chứa các frames
- Nếu không xử lý kịp, frames cũ tích tụ trong buffer
- Khi đọc frame → có thể đọc frame **cũ** thay vì frame **mới nhất**

**Hình dung:**

```
Camera gửi liên tục:
Frame 1 → Frame 2 → Frame 3 → Frame 4 → Frame 5 → ...

Buffer (nếu không flush):
┌─────────────────────────────────────┐
│ Frame 1 │ Frame 2 │ Frame 3 │ ...   │  ← Frames cũ tích tụ
└─────────────────────────────────────┘
                                    ↑
                              Đọc frame cũ!

Buffer (sau khi flush):
┌─────────────────────────────────────┐
│                           │ Frame 5 │  ← Chỉ còn frame mới nhất
└─────────────────────────────────────┘
                                    ↑
                              Đọc frame mới!
```

**Hậu quả nếu không flush:**

- Sinh viên A vào lớp lúc 8:00
- Hệ thống đọc frame từ 7:55 (trong buffer)
- Không thấy sinh viên A → không điểm danh được!

**Cách flush trong code:**

```python
# Bỏ qua 3 frames cũ trong buffer
for _ in range(3):
    cap.grab()  # Đọc nhưng không xử lý

# Giờ mới đọc frame thật sự
ret, frame = cap.read()  # Frame mới nhất
```

**Cấu hình bổ sung:**

```python
cap.set(cv2.CAP_PROP_BUFFERSIZE, 1)  # Buffer chỉ giữ 1 frame
```

---

## 4. TÌNH HUỐNG THỰC TẾ

### Q4.1: Nếu sinh viên đeo kính/khẩu trang thì sao?

**Trả lời đơn giản:**

**Đeo kính:**

- **Kính thường**: Hầu như không ảnh hưởng, model đã được train với nhiều ảnh đeo kính
- **Kính râm đen**: Có thể giảm accuracy vì che mất vùng mắt (quan trọng cho nhận diện)

**Đeo khẩu trang:**

- **Ảnh hưởng đáng kể**: Che mất 50% khuôn mặt (mũi, miệng, cằm)
- **Similarity giảm**: Có thể từ 0.85 xuống còn 0.50-0.60
- **Giải pháp**:
  - Hạ ngưỡng similarity (nhưng tăng risk nhận nhầm)
  - Yêu cầu sinh viên tháo khẩu trang khi điểm danh
  - Kết hợp với phương pháp khác (thẻ sinh viên)

```
Độ chính xác ước tính:
┌─────────────────────┬──────────────┐
│ Tình huống          │ Accuracy     │
├─────────────────────┼──────────────┤
│ Không đeo gì        │ ~98%         │
│ Đeo kính thường     │ ~95%         │
│ Đeo kính râm        │ ~80%         │
│ Đeo khẩu trang      │ ~60-70%      │
│ Kính râm + khẩu trang│ ~40%        │
└─────────────────────┴──────────────┘
```

---

### Q4.2: Nếu ánh sáng trong phòng kém thì hệ thống xử lý như thế nào?

**Trả lời đơn giản:**

**Ảnh hưởng của ánh sáng kém:**

- Ảnh bị **tối**, **nhiễu** (noise)
- Face detection có thể **không tìm thấy** khuôn mặt
- Embedding quality **giảm** → similarity giảm

**Hệ thống xử lý:**

1. **Không có xử lý đặc biệt trong code:**

   - Hệ thống dựa vào khả năng của model InsightFace
   - Model đã được train với nhiều điều kiện ánh sáng khác nhau

2. **Giải pháp thực tế:**

   - **Hạ ngưỡng similarity** (VD: từ 0.55 xuống 0.50)
   - **Tăng scan interval** để có thời gian chờ ánh sáng tốt hơn
   - **Cải thiện phần cứng**: Dùng camera có IR (hồng ngoại), đèn chiếu sáng

3. **Quality check khi đăng ký:**
   - Khi sinh viên đăng ký khuôn mặt, hệ thống kiểm tra **lighting score**
   - Nếu ảnh quá tối → yêu cầu chụp lại

```
Lighting score trong Quality Analyzer:
- Brightness: Độ sáng trung bình (ideal: 100-150/255)
- Contrast: Độ tương phản (ideal: > 40)

Nếu lighting_score < 0.5 → Cảnh báo "Ánh sáng không đủ"
```

---

### Q4.3: Nếu có 2 sinh viên giống nhau (sinh đôi) thì sao?

**Trả lời đơn giản:**

**Thực tế:**

- Sinh đôi **cùng trứng** có khuôn mặt rất giống nhau
- Similarity giữa 2 người có thể lên đến **0.70-0.85**
- Hệ thống **có thể nhận nhầm**

**Ví dụ:**

```
Sinh đôi A và B:
- Embedding A: [0.5, 0.3, 0.2, ...]
- Embedding B: [0.52, 0.31, 0.19, ...]  ← Rất giống!
- Similarity(A, B) = 0.78

Khi B vào lớp:
- So với A trong DB: similarity = 0.78 > 0.55 → MATCH với A!
- So với B trong DB: similarity = 0.95 > 0.55 → MATCH với B!

Hệ thống chọn best match → B (0.95 > 0.78) → Đúng!
```

**Khi nào nhận nhầm?**

- Nếu chỉ có A trong lớp (B học lớp khác)
- B vào nhầm lớp → Hệ thống điểm danh cho A!

**Giải pháp:**

1. **Tăng ngưỡng similarity** (0.65-0.70) cho lớp có sinh đôi
2. **Kết hợp yếu tố khác**: Vị trí ngồi, thẻ sinh viên
3. **Manual verification**: Giảng viên xác nhận thủ công

---

### Q4.4: Nếu sinh viên đứng xa camera, mặt quá nhỏ thì sao?

**Trả lời đơn giản:**

**Vấn đề:**

- Khuôn mặt quá nhỏ → Ít pixels → Ít thông tin
- Face detection có thể **không phát hiện** được
- Nếu phát hiện được → Embedding **kém chính xác**

**Ngưỡng kích thước:**

```
Model InsightFace (SCRFD):
- Input size: 640x640 pixels
- Minimum face size: ~20x20 pixels (có thể detect)
- Recommended face size: >= 80x80 pixels (accuracy tốt)

Ví dụ với camera 1080p (1920x1080):
- Khuôn mặt chiếm 5% frame = 96x54 pixels → OK
- Khuôn mặt chiếm 1% frame = 19x11 pixels → Quá nhỏ!
```

**Hệ thống xử lý:**

1. **Detection tự động bỏ qua** mặt quá nhỏ
2. **Quality check** khi đăng ký: `faceSize` score phải >= 20% frame

**Giải pháp thực tế:**

- Đặt camera ở vị trí phù hợp (không quá xa)
- Dùng camera có zoom
- Bố trí nhiều cameras trong phòng lớn

---

### Q4.5: Nếu sinh viên quay lưng hoặc nghiêng mặt thì sao?

**Trả lời đơn giản:**

**Khả năng của model:**

```
┌─────────────────────┬──────────────┬─────────────┐
│ Góc nghiêng         │ Detection    │ Recognition │
├─────────────────────┼──────────────┼─────────────┤
│ Chính diện (0°)     │ ✅ Tốt       │ ✅ Tốt      │
│ Nghiêng nhẹ (15°)   │ ✅ Tốt       │ ✅ Tốt      │
│ Nghiêng vừa (30°)   │ ✅ OK        │ ⚠️ Giảm     │
│ Nghiêng nhiều (45°) │ ⚠️ Có thể    │ ❌ Kém      │
│ Profile (90°)       │ ❌ Khó       │ ❌ Không    │
│ Quay lưng (180°)    │ ❌ Không     │ ❌ Không    │
└─────────────────────┴──────────────┴─────────────┘
```

**Hệ thống xử lý:**

1. **Face detection** sẽ không phát hiện nếu không thấy mặt
2. **faceAngle score** trong quality check đánh giá độ chính diện
3. **Scan liên tục**: Chờ sinh viên quay mặt lại

**Thực tế:**

- Sinh viên ngồi trong lớp thường **hướng về phía bảng**
- Camera đặt **phía trước lớp** → Sinh viên tự nhiên nhìn về camera
- Scan interval 3 giây → Có nhiều cơ hội bắt được lúc nhìn thẳng

---

## 5. XỬ LÝ LỖI

### Q5.1: Nếu camera bị ngắt kết nối giữa chừng thì sao?

**Trả lời đơn giản:**

**Tình huống:**

- Đang điểm danh, camera đột ngột mất kết nối (mạng lỗi, camera hỏng, mất điện)

**Hệ thống xử lý:**

1. **Phát hiện lỗi:**

   ```python
   ret, frame = cap.read()
   if not ret or frame is None:
       # Không đọc được frame → Camera có vấn đề
   ```

2. **Không crash, tiếp tục thử:**

   - Log warning
   - Đợi 1 giây
   - Thử đọc lại
   - Nếu camera reconnect → tiếp tục bình thường

3. **Các cameras khác vẫn chạy:**
   - Mỗi camera là 1 task độc lập
   - Camera 1 lỗi không ảnh hưởng Camera 2

```
Ví dụ: Phòng có 2 cameras

Camera 1: ✅ Đang chạy bình thường
Camera 2: ❌ Mất kết nối lúc 8:05

Kết quả:
- Camera 1 tiếp tục điểm danh
- Camera 2 cố gắng reconnect
- Sinh viên vẫn được điểm danh qua Camera 1
```

**Giới hạn:**

- Nếu camera mất kết nối vĩnh viễn → Task đó sẽ loop vô hạn (cố đọc frame)
- Cải thiện: Thêm timeout, sau N lần fail thì dừng task đó

---

### Q5.2: Nếu Java Backend không phản hồi callback thì sao?

**Trả lời đơn giản:**

**Tình huống:**

- Recognition Service nhận diện được sinh viên
- Gửi callback về Java Backend
- Java Backend không phản hồi (down, quá tải, network lỗi)

**Hệ thống xử lý:**

1. **Retry với Exponential Backoff:**

   ```
   Lần 1: Gửi → Fail → Đợi 1 giây
   Lần 2: Gửi → Fail → Đợi 2 giây
   Lần 3: Gửi → Fail → Bỏ cuộc
   ```

2. **Auto-stop mechanism:**

   - Nếu **10 callbacks liên tiếp** fail → Tự động dừng session
   - Nếu **2 phút** không có callback thành công → Tự động dừng session
   - Lý do: Không có ý nghĩa tiếp tục nếu backend không nhận được kết quả

3. **Log để debug:**
   ```
   WARNING: Callback failed: slot=123 attempt=1/3
   WARNING: Callback failed: slot=123 attempt=2/3
   ERROR: All callback attempts failed: slot=123 student=1001
   ```

**Hậu quả:**

- Sinh viên được nhận diện nhưng **không được ghi vào database**
- Cần điểm danh lại hoặc giảng viên điểm danh thủ công

**Cải thiện có thể:**

- Lưu callback vào queue (Redis/RabbitMQ)
- Retry sau khi backend recover

---

### Q5.3: Nếu có người lạ (không phải sinh viên trong lớp) xuất hiện trong camera?

**Trả lời đơn giản:**

**Tình huống:**

- Giảng viên, khách, hoặc sinh viên lớp khác đi ngang qua camera

**Hệ thống xử lý:**

1. **So khớp với danh sách sinh viên:**

   - Hệ thống chỉ so khớp với **sinh viên trong lớp đó**
   - Người lạ không có trong danh sách → Không match

2. **Best match không vượt ngưỡng:**

   ```
   Người lạ xuất hiện:
   - So với SV A: similarity = 0.35
   - So với SV B: similarity = 0.28
   - So với SV C: similarity = 0.41

   Best match = 0.41 < 0.55 (ngưỡng)
   → Không match với ai → Bỏ qua
   ```

3. **Không có hành động nào:**
   - Không gửi callback
   - Không log (tránh spam)
   - Tiếp tục scan bình thường

**Rủi ro:**

- Nếu người lạ **giống** một sinh viên trong lớp (similarity > 0.55)
- → Có thể điểm danh nhầm cho sinh viên đó!
- Giải pháp: Tăng ngưỡng, giảng viên kiểm tra evidence

---

### Q5.4: Nếu giảng viên bấm "Bắt đầu" 2 lần liên tiếp thì sao?

**Trả lời đơn giản:**

**Tình huống:**

- Giảng viên bấm "Bắt đầu điểm danh"
- Chưa thấy phản hồi, bấm lại lần nữa

**Hệ thống xử lý:**

1. **Kiểm tra session tồn tại:**

   ```python
   existing_session = await session_manager.get_session(slot_id)
   if existing_session:
       raise ValueError("Session already exists")
   ```

2. **Trả về lỗi HTTP 409 Conflict:**

   ```json
   {
     "status": 409,
     "code": "SESSION_ALREADY_EXISTS",
     "message": "Session already exists for slot 123"
   }
   ```

3. **Frontend hiển thị thông báo:**
   - "Buổi điểm danh đã được bắt đầu"
   - Không tạo session mới

**Kết quả:**

- Chỉ có **1 session** cho mỗi slot
- Không bị duplicate
- Session đầu tiên tiếp tục chạy bình thường

---

### Q5.5: Nếu tất cả cameras đều không kết nối được?

**Trả lời đơn giản:**

**Tình huống:**

- Giảng viên bấm "Bắt đầu điểm danh"
- Tất cả cameras trong phòng đều không kết nối được

**Hệ thống xử lý:**

1. **Test tất cả cameras song song:**

   ```python
   camera_results = await self._test_cameras(request.cameras)
   active_cameras = sum(1 for r in camera_results if r["connected"])
   ```

2. **Kiểm tra có camera nào OK không:**

   ```python
   if active_cameras == 0:
       raise RuntimeError("All cameras failed to connect")
   ```

3. **Trả về lỗi HTTP 500:**

   ```json
   {
     "status": 500,
     "code": "ALL_CAMERAS_FAILED",
     "message": "Failed to connect to any camera. Cannot start session."
   }
   ```

4. **Frontend hiển thị:**
   - "Không thể kết nối với camera. Vui lòng kiểm tra lại."
   - Không bắt đầu session

**Lưu ý:**

- Nếu **ít nhất 1 camera** OK → Vẫn bắt đầu session
- Cameras fail được log để admin kiểm tra

---

## 6. DEDUPLICATION VÀ CONSISTENCY

### Q6.1: Làm sao tránh điểm danh trùng khi sinh viên xuất hiện nhiều lần?

**Trả lời đơn giản:**

**Vấn đề:**

- Sinh viên ngồi trong lớp suốt buổi học
- Camera scan mỗi 3 giây
- Buổi học 90 phút = 1800 lần scan
- Nếu không xử lý → Gửi 1800 callbacks cho cùng 1 sinh viên!

**Giải pháp: Deduplication bằng Set**

```python
# Mỗi session có 1 Set lưu student IDs đã nhận diện
recognized_students = {
    slot_123: {1001, 1002, 1003},  # Đã điểm danh 3 sinh viên
    slot_124: {2001, 2002},         # Đã điểm danh 2 sinh viên
}
```

**Luồng xử lý:**

```
Frame 1: Phát hiện sinh viên 1001
├── Kiểm tra: 1001 có trong Set chưa? → KHÔNG
├── Gửi callback
└── Thêm 1001 vào Set

Frame 2: Phát hiện sinh viên 1001 (lần 2)
├── Kiểm tra: 1001 có trong Set chưa? → CÓ
└── Bỏ qua, không gửi callback

Frame 3: Phát hiện sinh viên 1002
├── Kiểm tra: 1002 có trong Set chưa? → KHÔNG
├── Gửi callback
└── Thêm 1002 vào Set
```

**Kết quả:**

- Mỗi sinh viên chỉ được điểm danh **1 lần** per session
- Tiết kiệm bandwidth và database operations
- Set được clear khi session kết thúc

---

### Q6.2: Nếu sinh viên được nhận diện bởi 2 cameras cùng lúc thì sao?

**Trả lời đơn giản:**

**Tình huống:**

- Phòng có 2 cameras
- Sinh viên ngồi ở vị trí cả 2 cameras đều thấy
- Cả 2 cameras cùng nhận diện được sinh viên đó

**Hệ thống xử lý:**

1. **Shared Set giữa các cameras:**

   - Tất cả cameras trong cùng session dùng chung 1 Set
   - `recognized_students[slot_id]` là shared

2. **Race condition handling:**

   ```
   Camera 1: Nhận diện SV 1001 → Kiểm tra Set → Chưa có → Gửi callback → Thêm vào Set
   Camera 2: Nhận diện SV 1001 → Kiểm tra Set → ĐÃ CÓ → Bỏ qua
   ```

3. **Thực tế:**
   - Các cameras chạy **async** nhưng **không hoàn toàn đồng thời**
   - Camera nào xử lý xong trước sẽ thêm vào Set trước
   - Camera còn lại sẽ thấy đã có trong Set → Bỏ qua

**Worst case:**

- Nếu 2 cameras xử lý **cực kỳ đồng thời** (hiếm)
- Có thể gửi 2 callbacks cho cùng 1 sinh viên
- Java Backend cần handle duplicate (idempotent)

---

### Q6.3: Nếu callback gửi thành công nhưng Java Backend xử lý fail?

**Trả lời đơn giản:**

**Tình huống:**

- Recognition Service gửi callback
- Java Backend nhận được (HTTP 200)
- Nhưng khi lưu database bị lỗi

**Vấn đề:**

- Recognition Service nghĩ đã thành công → Thêm vào Set
- Java Backend không lưu được → Sinh viên không được điểm danh
- Sinh viên không được điểm danh lại (đã trong Set)

**Hiện tại hệ thống:**

- **Không xử lý** trường hợp này
- Giả định: Nếu HTTP 200 → Backend đã xử lý thành công

**Giải pháp cải thiện:**

1. **Backend trả về chi tiết hơn:**

   ```json
   {
     "status": 200,
     "saved": true,
     "studentId": 1001
   }
   ```

2. **Recognition Service kiểm tra:**

   ```python
   if response.status == 200 and response.json()["saved"]:
       recognized_students.add(student_id)
   else:
       # Không thêm vào Set → Sẽ thử lại lần sau
   ```

3. **Idempotent ở Backend:**
   - Backend kiểm tra trước khi insert
   - Nếu đã có record → Update thay vì insert
   - Tránh duplicate trong database

---

## 7. HIỆU NĂNG

### Q7.1: GPU vs CPU: Khác nhau như thế nào về tốc độ?

**Trả lời đơn giản:**

**So sánh thực tế:**

```
┌─────────────┬─────────────────┬─────────────────┐
│ Thao tác    │ GPU (CUDA)      │ CPU             │
├─────────────┼─────────────────┼─────────────────┤
│ Load model  │ ~5 giây         │ ~10 giây        │
│ Detection   │ ~20ms/frame     │ ~200ms/frame    │
│ Recognition │ ~30ms/frame     │ ~300ms/frame    │
│ Tổng        │ ~50-100ms/frame │ ~500-1000ms/frame│
└─────────────┴─────────────────┴─────────────────┘

GPU nhanh hơn ~10 lần!
```

**Tại sao GPU nhanh hơn?**

1. **Parallel processing:**

   - CPU: 4-16 cores, xử lý tuần tự
   - GPU: Hàng nghìn cores, xử lý song song

2. **Deep learning operations:**
   - Chủ yếu là phép nhân ma trận
   - GPU được thiết kế đặc biệt cho việc này

**Ảnh hưởng đến hệ thống:**

```
Với scan interval = 3 giây:

GPU: 50ms xử lý + 2950ms nghỉ = OK, CPU rảnh 98%
CPU: 500ms xử lý + 2500ms nghỉ = OK, CPU rảnh 83%

Với scan interval = 0.5 giây:

GPU: 50ms xử lý + 450ms nghỉ = OK, CPU rảnh 90%
CPU: 500ms xử lý + 0ms nghỉ = KHÔNG KỊP! Bị lag
```

**Khuyến nghị:**

- **Production**: Nên dùng GPU
- **Development/Testing**: CPU OK nếu scan interval đủ lớn

---

### Q7.2: Với lớp 50 sinh viên, mỗi lần so khớp mất bao lâu?

**Trả lời đơn giản:**

**Phân tích:**

1. **Mỗi lần so khớp 1 face với 1 student:**

   - Tính cosine similarity giữa 2 vectors 512 chiều
   - Thời gian: ~0.01ms (rất nhanh)

2. **Với 50 sinh viên:**

   - 50 × 0.01ms = **0.5ms** cho việc so khớp
   - Rất nhanh, không phải bottleneck

3. **Bottleneck thực sự:**
   - **Face Detection**: ~20-200ms (tùy GPU/CPU)
   - **Embedding extraction**: ~30-300ms (tùy GPU/CPU)

**Tổng thời gian xử lý 1 frame (50 sinh viên):**

```
GPU:
├── Detection: 20ms
├── Embedding: 30ms
├── Matching: 0.5ms
└── Tổng: ~50ms

CPU:
├── Detection: 200ms
├── Embedding: 300ms
├── Matching: 0.5ms
└── Tổng: ~500ms
```

**Kết luận:**

- Số lượng sinh viên **ít ảnh hưởng** đến tốc độ
- 50 hay 100 sinh viên → Thời gian matching vẫn < 1ms
- Bottleneck là Detection và Embedding extraction

---

### Q7.3: Nếu có 100 lớp điểm danh cùng lúc thì hệ thống có chịu được không?

**Trả lời đơn giản:**

**Phân tích:**

1. **Mỗi lớp có:**

   - 1-2 cameras
   - 1 session
   - 1-2 background tasks

2. **100 lớp = 100-200 cameras = 100-200 tasks**

**Giới hạn của 1 Recognition Service instance:**

```
┌─────────────────┬─────────────────────────────────┐
│ Tài nguyên      │ Giới hạn                        │
├─────────────────┼─────────────────────────────────┤
│ RAM             │ Model ~600MB + sessions ~100MB  │
│                 │ = ~1GB cho 100 sessions         │
├─────────────────┼─────────────────────────────────┤
│ GPU             │ 1 GPU xử lý tuần tự             │
│                 │ 100 tasks × 50ms = 5000ms/round │
│                 │ = Mỗi camera chờ 5 giây!        │
├─────────────────┼─────────────────────────────────┤
│ Network         │ 100-200 RTSP connections        │
│                 │ Có thể quá tải network card     │
└─────────────────┴─────────────────────────────────┘
```

**Kết luận:**

- **1 instance KHÔNG thể** xử lý 100 lớp cùng lúc
- Cần **scale horizontally** (nhiều instances)

**Giải pháp scale:**

```
                    ┌─────────────────┐
                    │  Load Balancer  │
                    └────────┬────────┘
           ┌─────────────────┼─────────────────┐
           ▼                 ▼                 ▼
┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐
│ Recognition #1  │ │ Recognition #2  │ │ Recognition #3  │
│ (30-35 lớp)     │ │ (30-35 lớp)     │ │ (30-35 lớp)     │
└─────────────────┘ └─────────────────┘ └─────────────────┘
```

---

### Q7.4: Model InsightFace chiếm bao nhiêu RAM?

**Trả lời đơn giản:**

**Chi tiết model buffalo_l:**

```
┌─────────────────────┬─────────────┐
│ Component           │ Size        │
├─────────────────────┼─────────────┤
│ Detection (SCRFD)   │ ~30MB       │
│ Recognition (ArcFace)│ ~250MB     │
│ Landmarks           │ ~10MB       │
│ Other               │ ~10MB       │
├─────────────────────┼─────────────┤
│ Tổng (on disk)      │ ~300MB      │
│ Tổng (in RAM)       │ ~600MB      │
└─────────────────────┴─────────────┘
```

**Tại sao RAM > disk?**

- Model được decompress khi load
- Thêm buffers cho inference
- GPU memory (nếu dùng GPU): Thêm ~500MB VRAM

**RAM usage của toàn service:**

```
┌─────────────────────┬─────────────┐
│ Component           │ RAM         │
├─────────────────────┼─────────────┤
│ Python runtime      │ ~50MB       │
│ FastAPI + libs      │ ~100MB      │
│ InsightFace model   │ ~600MB      │
│ OpenCV buffers      │ ~50MB       │
│ Sessions (10 lớp)   │ ~10MB       │
├─────────────────────┼─────────────┤
│ Tổng                │ ~800MB-1GB  │
└─────────────────────┴─────────────┘
```

**Khuyến nghị:**

- Server cần ít nhất **2GB RAM** cho Recognition Service
- Nếu dùng GPU: Cần GPU với **2GB+ VRAM**

---

## 8. SCALABILITY

### Q8.1: Làm sao scale Recognition Service khi số lượng phòng tăng?

**Trả lời đơn giản:**

**Vấn đề:**

- 1 instance có giới hạn (CPU, RAM, GPU, network)
- Khi số phòng tăng → Cần nhiều instances

**Chiến lược scale:**

**1. Horizontal Scaling (thêm instances):**

```
                         ┌─────────────────┐
                         │  Java Backend   │
                         └────────┬────────┘
                                  │
                    ┌─────────────┼─────────────┐
                    ▼             ▼             ▼
          ┌─────────────┐ ┌─────────────┐ ┌─────────────┐
          │ Instance 1  │ │ Instance 2  │ │ Instance 3  │
          │ Building A  │ │ Building B  │ │ Building C  │
          └─────────────┘ └─────────────┘ └─────────────┘
```

**2. Phân chia theo building/khu vực:**

- Mỗi instance phụ trách 1 building
- Cameras trong building đó → Route đến instance tương ứng
- Giảm network latency (cameras gần server)

**3. Load balancing:**

- Java Backend quyết định gửi request đến instance nào
- Dựa trên: Building, số sessions đang chạy, health check

**Thay đổi cần thiết:**

```
Hiện tại:
- Session lưu in-memory
- 1 instance = 1 point of failure

Cần thay đổi:
- Session lưu Redis (shared)
- Health check endpoint
- Instance ID trong logs
```

---

### Q8.2: Session lưu in-memory có phải bottleneck không? Giải pháp thay thế?

**Trả lời đơn giản:**

**In-memory có phải bottleneck?**

**Không phải bottleneck về performance:**

- Đọc/ghi RAM cực nhanh (nanoseconds)
- Session data rất nhỏ (~1KB/session)

**Nhưng là bottleneck về scalability:**

- Không thể share giữa các instances
- Mất data khi restart
- Không thể failover

**Giải pháp thay thế:**

**1. Redis (Recommended):**

```
┌─────────────┐     ┌─────────────┐
│ Instance 1  │────▶│             │
└─────────────┘     │    Redis    │
┌─────────────┐────▶│  (Sessions) │
│ Instance 2  │     │             │
└─────────────┘     └─────────────┘

Ưu điểm:
- Shared giữa instances
- Persist data (optional)
- Rất nhanh (in-memory database)
- Hỗ trợ TTL (auto cleanup)
```

**2. PostgreSQL:**

```
Ưu điểm:
- Đã có sẵn trong hệ thống
- Durable (không mất data)

Nhược điểm:
- Chậm hơn Redis
- Cần query mỗi frame → Overhead
```

**3. Hybrid approach:**

```
- In-memory cho hot data (current frame processing)
- Redis cho session state (shared)
- PostgreSQL cho audit log (durable)
```

---

### Q8.3: Nếu muốn deploy nhiều instances thì cần thay đổi gì?

**Trả lời đơn giản:**

**Checklist thay đổi:**

**1. Session Storage → Redis:**

```python
# Hiện tại
sessions: Dict[int, SessionState] = {}  # In-memory

# Thay đổi
import redis
redis_client = redis.Redis(host='redis', port=6379)

async def add_session(slot_id, state):
    redis_client.set(f"session:{slot_id}", state.json(), ex=3600)
```

**2. Recognized Students → Redis Set:**

```python
# Hiện tại
recognized_students: Dict[int, set] = {}

# Thay đổi
async def is_recognized(slot_id, student_id):
    return redis_client.sismember(f"recognized:{slot_id}", student_id)

async def mark_recognized(slot_id, student_id):
    redis_client.sadd(f"recognized:{slot_id}", student_id)
```

**3. Evidence Storage → Shared Storage:**

```python
# Hiện tại
evidence_dir = "./uploads/evidence/"  # Local filesystem

# Thay đổi
# Option 1: NFS mount (shared folder)
# Option 2: S3/MinIO (object storage)
# Option 3: Serve từ Java Backend
```

**4. Health Check Endpoint:**

```python
@router.get("/health")
async def health():
    return {
        "status": "healthy",
        "instance_id": os.environ.get("INSTANCE_ID"),
        "active_sessions": session_manager.active_sessions_count,
        "model_loaded": face_app is not None
    }
```

**5. Logging với Instance ID:**

```python
logger.info(f"[{INSTANCE_ID}] Recognition: slot={slot_id} student={student_id}")
```

**6. Graceful Shutdown:**

```python
@app.on_event("shutdown")
async def shutdown():
    # Chuyển sessions sang instance khác hoặc
    # Đánh dấu sessions cần restart
    for slot_id in session_manager.active_sessions:
        redis_client.set(f"session:{slot_id}:needs_restart", "true")
```

---

## 9. BẢO MẬT

### Q9.1: Làm sao bảo vệ API không bị gọi trái phép?

**Trả lời đơn giản:**

**Cơ chế bảo vệ: API Key Authentication**

```
Request từ Java Backend:
┌─────────────────────────────────────────────────┐
│ POST /api/v1/recognition/process-session        │
│                                                 │
│ Headers:                                        │
│   Content-Type: application/json                │
│   X-API-Key: python-service-secret-key-12345   │ ← API Key
│                                                 │
│ Body: {...}                                     │
└─────────────────────────────────────────────────┘
```

**Code kiểm tra:**

```python
async def verify_api_key(api_key: str = Security(api_key_header)) -> str:
    settings = get_settings()

    if not api_key:
        raise HTTPException(status_code=401, detail="Missing API key")

    if api_key != settings.API_KEY:
        raise HTTPException(status_code=401, detail="Invalid API key")

    return api_key
```

**Endpoints được bảo vệ:**

- `/api/v1/recognition/*` - Điểm danh
- `/api/v1/embeddings/*` - Tạo embedding
- `/api/v1/cameras/*` - Test camera
- `/api/v1/metrics` - Metrics

**Endpoints public:**

- `/api/v1/health` - Health check
- `/docs`, `/redoc` - API documentation

**Cải thiện cho production:**

1. **Rotate API key định kỳ**
2. **Dùng HTTPS** (encrypt traffic)
3. **IP whitelist** (chỉ cho phép từ Java Backend)
4. **Rate limiting** (giới hạn số request/giây)

---

### Q9.2: Embedding vector có thể bị đánh cắp và sử dụng lại không?

**Trả lời đơn giản:**

**Embedding có thể bị đánh cắp?**

- **Có**, nếu attacker truy cập được database hoặc network traffic

**Embedding có thể sử dụng lại?**

- **Có**, embedding là "fingerprint" của khuôn mặt
- Nếu có embedding của ai đó → Có thể giả mạo người đó

**Rủi ro:**

```
Attacker có embedding của sinh viên A
     │
     ▼
Gửi request giả với embedding A
     │
     ▼
Hệ thống nghĩ sinh viên A có mặt
     │
     ▼
Điểm danh sai!
```

**Tuy nhiên, trong hệ thống FUACS:**

- Embedding được gửi từ **Java Backend** (trusted)
- Recognition Service **không nhận embedding từ client**
- Attacker cần hack được Java Backend trước

**Biện pháp bảo vệ:**

1. **Encrypt embeddings trong database:**

   ```sql
   -- Thay vì lưu plaintext
   embedding_vector VECTOR(512)

   -- Lưu encrypted
   embedding_encrypted BYTEA
   ```

2. **HTTPS cho tất cả traffic:**

   - Encrypt data in transit
   - Attacker không thể sniff network

3. **Access control:**

   - Chỉ Java Backend mới có quyền đọc embeddings
   - Audit log cho mọi truy cập

4. **Embedding versioning:**
   - Nếu nghi ngờ bị leak → Re-generate embeddings mới
   - Embeddings cũ không còn valid

---

### Q9.3: Nếu ai đó dùng ảnh in ra để "lừa" camera thì sao? (Spoofing attack)

**Trả lời đơn giản:**

**Spoofing attack là gì?**

- Attacker dùng **ảnh in**, **video**, hoặc **mặt nạ 3D** để giả mạo người khác
- Mục đích: Điểm danh thay cho người vắng mặt

**Hệ thống FUACS có chống spoofing không?**

- **KHÔNG** - Model buffalo_l không có tính năng anti-spoofing
- Hệ thống chỉ so khớp embedding, không kiểm tra "đây có phải người thật không"

**Các loại spoofing:**

```
┌─────────────────┬─────────────────┬─────────────────┐
│ Loại           │ Độ khó          │ Hiệu quả        │
├─────────────────┼─────────────────┼─────────────────┤
│ Ảnh in giấy    │ Dễ              │ Có thể lừa được │
│ Ảnh trên điện  │ Dễ              │ Có thể lừa được │
│ thoại          │                 │                 │
│ Video playback │ Trung bình      │ Có thể lừa được │
│ Mặt nạ 3D      │ Khó             │ Rất khó phát    │
│                │                 │ hiện            │
└─────────────────┴─────────────────┴─────────────────┘
```

**Giải pháp nếu cần chống spoofing:**

1. **Liveness Detection:**

   - Yêu cầu người dùng **nháy mắt**, **quay đầu**, **mỉm cười**
   - Ảnh/video không thể làm được

2. **Depth camera:**

   - Camera có cảm biến độ sâu (như Face ID của iPhone)
   - Phát hiện mặt phẳng (ảnh) vs mặt 3D (người thật)

3. **IR camera:**

   - Camera hồng ngoại
   - Ảnh in không phản xạ IR như da người

4. **Giám sát của giảng viên:**
   - Giảng viên có mặt trong lớp
   - Phát hiện hành vi bất thường

**Trong context FUACS:**

- Đây là hệ thống điểm danh trong lớp học
- Có giảng viên giám sát
- Risk của spoofing thấp hơn so với hệ thống tự động hoàn toàn

---

### Q9.4: Evidence images được lưu trữ và bảo vệ như thế nào?

**Trả lời đơn giản:**

**Evidence images là gì?**

- Ảnh crop khuôn mặt khi nhận diện thành công
- Dùng làm bằng chứng điểm danh
- Giảng viên có thể xem để verify

**Lưu trữ:**

```
uploads/
└── evidence/
    ├── 123/                          # slot_id
    │   ├── 1001_SE171234.jpg        # user_id_rollNumber.jpg
    │   └── 1002_SE171235.jpg
    └── 124/
        └── ...
```

**Bảo vệ hiện tại:**

1. **Không public trực tiếp:**

   - URL chứa slot_id và user_id
   - Khó đoán nếu không biết thông tin

2. **Serve qua FastAPI:**
   ```python
   app.mount("/uploads", StaticFiles(directory="uploads"))
   ```
   - Có thể thêm authentication nếu cần

**Cải thiện cho production:**

1. **Thêm authentication:**

   ```python
   @router.get("/evidence/{slot_id}/{filename}")
   async def get_evidence(slot_id: int, filename: str, api_key: str = Depends(verify_api_key)):
       # Kiểm tra quyền truy cập
       # Trả về file
   ```

2. **Signed URLs:**

   - URL có chữ ký và thời hạn
   - Hết hạn sau 1 giờ

3. **Encryption at rest:**

   - Encrypt files trên disk
   - Decrypt khi serve

4. **Retention policy:**
   - Tự động xóa sau 30 ngày
   - Tuân thủ quy định về dữ liệu cá nhân

---

## 10. ACCURACY VÀ QUALITY

### Q10.1: Làm sao đo lường độ chính xác của hệ thống?

**Trả lời đơn giản:**

**Các metrics quan trọng:**

1. **True Positive (TP):** Nhận diện đúng người đúng
2. **False Positive (FP):** Nhận nhầm (người A nhưng điểm danh cho B)
3. **False Negative (FN):** Bỏ sót (người A có mặt nhưng không nhận diện được)
4. **True Negative (TN):** Đúng khi không nhận diện (người lạ, không match)

**Công thức:**

```
                    TP
Precision = ─────────────── = Trong số người được điểm danh, bao nhiêu % đúng?
              TP + FP

                 TP
Recall = ─────────────── = Trong số người có mặt, bao nhiêu % được điểm danh?
           TP + FN

                    2 × Precision × Recall
F1 Score = ─────────────────────────────── = Cân bằng giữa Precision và Recall
                  Precision + Recall
```

**Cách đo trong thực tế:**

1. **Test set:**

   - Chuẩn bị 100 sinh viên với ảnh đăng ký
   - Cho từng người đi qua camera
   - Ghi nhận kết quả

2. **So sánh:**

   ```
   Sinh viên A đi qua camera:
   - Hệ thống nhận diện: A → TP ✅
   - Hệ thống nhận diện: B → FP ❌
   - Hệ thống không nhận diện → FN ❌
   ```

3. **Tính metrics:**

   ```
   Ví dụ kết quả test 100 người:
   - TP = 95 (nhận đúng)
   - FP = 2 (nhận nhầm)
   - FN = 3 (bỏ sót)

   Precision = 95/(95+2) = 97.9%
   Recall = 95/(95+3) = 96.9%
   F1 = 2×0.979×0.969/(0.979+0.969) = 97.4%
   ```

---

### Q10.2: False Positive và False Negative là gì? Cái nào nguy hiểm hơn?

**Trả lời đơn giản:**

**False Positive (FP) - Nhận nhầm:**

```
Thực tế: Sinh viên B có mặt
Hệ thống: Điểm danh cho sinh viên A

Hậu quả:
- A được điểm danh dù không có mặt (gian lận)
- B không được điểm danh dù có mặt (thiệt thòi)
```

**False Negative (FN) - Bỏ sót:**

```
Thực tế: Sinh viên A có mặt
Hệ thống: Không nhận diện được A

Hậu quả:
- A không được điểm danh dù có mặt
- Cần điểm danh thủ công
```

**Cái nào nguy hiểm hơn?**

```
┌─────────────────┬─────────────────────────────────────────┐
│ Loại lỗi       │ Hậu quả                                 │
├─────────────────┼─────────────────────────────────────────┤
│ False Positive │ - Gian lận điểm danh                    │
│ (Nhận nhầm)    │ - Ảnh hưởng đến tính công bằng          │
│                │ - Khó phát hiện                         │
│                │ → NGUY HIỂM HƠN trong context điểm danh │
├─────────────────┼─────────────────────────────────────────┤
│ False Negative │ - Sinh viên phải điểm danh lại          │
│ (Bỏ sót)       │ - Gây phiền phức                        │
│                │ - Dễ phát hiện và sửa                   │
│                │ → Ít nguy hiểm hơn                      │
└─────────────────┴─────────────────────────────────────────┘
```

**Cách giảm thiểu:**

- **Giảm FP:** Tăng ngưỡng similarity (0.55 → 0.60)
- **Giảm FN:** Giảm ngưỡng similarity (0.55 → 0.50)
- **Trade-off:** Giảm FP thường làm tăng FN và ngược lại

**Trong FUACS:**

- Ưu tiên **giảm FP** (tránh gian lận)
- Chấp nhận một số FN (giảng viên có thể điểm danh thủ công)

---

### Q10.3: Quality metrics khi đăng ký khuôn mặt gồm những gì?

**Trả lời đơn giản:**

**4 metrics chính:**

**1. Face Size (30% weight):**

```
Đo: Tỷ lệ khuôn mặt so với frame
Target: >= 20% diện tích frame
Lý do: Mặt quá nhỏ → ít pixels → embedding kém chính xác

Ví dụ:
- Mặt chiếm 25% frame → Score = 1.0 ✅
- Mặt chiếm 10% frame → Score = 0.5 ⚠️
- Mặt chiếm 5% frame → Score = 0.25 ❌
```

**2. Clarity (25% weight):**

```
Đo: Độ sắc nét (Laplacian variance)
Target: Variance >= 500
Lý do: Ảnh mờ → mất chi tiết → embedding kém

Ví dụ:
- Ảnh sắc nét, variance = 600 → Score = 1.0 ✅
- Ảnh hơi mờ, variance = 300 → Score = 0.6 ⚠️
- Ảnh rất mờ, variance = 100 → Score = 0.2 ❌
```

**3. Lighting (25% weight):**

```
Đo: Độ sáng + Độ tương phản
Target: Brightness 100-150, Contrast > 40
Lý do: Quá tối/sáng → mất chi tiết

Ví dụ:
- Ánh sáng tốt → Score = 0.9 ✅
- Hơi tối → Score = 0.6 ⚠️
- Ngược sáng → Score = 0.3 ❌
```

**4. Face Angle (20% weight):**

```
Đo: Độ chính diện (dùng detection confidence)
Target: Nhìn thẳng vào camera
Lý do: Nghiêng mặt → embedding khác với khi nhìn thẳng

Ví dụ:
- Nhìn thẳng → Score = 0.95 ✅
- Nghiêng 15° → Score = 0.8 ⚠️
- Nghiêng 45° → Score = 0.5 ❌
```

**Overall Quality:**

```
Quality = 0.30×FaceSize + 0.25×Clarity + 0.25×Lighting + 0.20×FaceAngle

Ngưỡng chấp nhận: >= 0.50
```

---

### Q10.4: Tại sao cần validate chất lượng ảnh khi đăng ký?

**Trả lời đơn giản:**

**Nguyên tắc: "Garbage in, garbage out"**

Nếu ảnh đăng ký kém chất lượng → Embedding kém → Nhận diện kém

**Ví dụ thực tế:**

```
Sinh viên A đăng ký với ảnh mờ, tối:
- Embedding chất lượng kém
- Khi điểm danh (ảnh từ camera tốt hơn):
  - Similarity với embedding kém = 0.45
  - Dưới ngưỡng 0.55 → Không match!
  - A có mặt nhưng không được điểm danh

Sinh viên B đăng ký với ảnh tốt:
- Embedding chất lượng cao
- Khi điểm danh:
  - Similarity = 0.85
  - Trên ngưỡng → Match!
  - B được điểm danh bình thường
```

**Lợi ích của quality validation:**

1. **Đảm bảo accuracy:**

   - Chỉ chấp nhận ảnh đủ tốt
   - Embedding chất lượng cao

2. **User experience:**

   - Feedback ngay khi đăng ký
   - "Ảnh quá tối, vui lòng chụp lại"
   - Không phải đợi đến khi điểm danh mới biết có vấn đề

3. **Giảm support:**
   - Ít trường hợp "tôi có mặt nhưng không được điểm danh"
   - Tiết kiệm thời gian xử lý khiếu nại

---

## 11. BUSINESS LOGIC

### Q11.1: INITIAL vs RESCAN mode khác nhau như thế nào?

**Trả lời đơn giản:**

**INITIAL Mode (Lần đầu):**

```
Mục đích: Điểm danh ban đầu cho cả lớp
Input: Tất cả sinh viên trong lớp (VD: 30 người)
Output: Danh sách sinh viên có mặt

Timeline:
8:00 - Giảng viên bấm "Bắt đầu điểm danh" (INITIAL)
8:05 - Kết quả: 25/30 sinh viên có mặt
```

**RESCAN Mode (Quét lại):**

```
Mục đích: Cho sinh viên đến muộn cơ hội điểm danh
Input: CHỈ những sinh viên chưa có mặt (VD: 5 người)
Output: Danh sách sinh viên mới có mặt

Timeline:
8:10 - Giảng viên bấm "Quét lại" (RESCAN)
       Java Backend gửi 5 sinh viên chưa có mặt
8:12 - Kết quả: Thêm 3 sinh viên
       Tổng: 28/30 sinh viên có mặt
```

**Tại sao cần RESCAN?**

1. **Sinh viên đến muộn:**

   - Không có mặt lúc INITIAL
   - Cần cơ hội điểm danh sau

2. **Tiết kiệm tài nguyên:**

   - RESCAN chỉ so khớp với 5 người thay vì 30
   - Nhanh hơn, ít tính toán hơn

3. **Flexibility:**
   - Giảng viên quyết định khi nào RESCAN
   - Có thể RESCAN nhiều lần

**Trong code:**

```python
class ScanMode(str, Enum):
    INITIAL = "INITIAL"
    RESCAN = "RESCAN"

# Request body
{
    "mode": "RESCAN",
    "students": [/* chỉ 5 sinh viên chưa có mặt */]
}
```

---

### Q11.2: REGULAR vs EXAM callback type dùng khi nào?

**Trả lời đơn giản:**

**REGULAR (Điểm danh thường):**

```
Dùng cho: Buổi học bình thường
Callback route: Bảng lecture_attendance
Evidence: regularImageUrl

Đặc điểm:
- Ngưỡng similarity: 0.55 (mặc định)
- Cho phép RESCAN
- Giảng viên có thể override
```

**EXAM (Điểm danh thi):**

```
Dùng cho: Buổi thi
Callback route: Bảng exam_attendance
Evidence: examImageUrl

Đặc điểm:
- Ngưỡng similarity: Cao hơn (0.60-0.65)
- Nghiêm ngặt hơn
- Supervisor quản lý
```

**Tại sao cần phân biệt?**

1. **Database khác nhau:**

   - Điểm danh học và điểm danh thi lưu riêng
   - Quy trình xử lý khác nhau

2. **Mức độ nghiêm ngặt:**

   - Thi cử cần chính xác hơn
   - Tránh gian lận

3. **Người quản lý khác:**
   - REGULAR: Giảng viên (Lecturer)
   - EXAM: Giám thị (Supervisor)

**Trong callback:**

```json
{
  "slotId": 123,
  "callbackType": "EXAM",
  "recognitions": [
    {
      "studentUserId": 1001,
      "evidence": {
        "regularImageUrl": null,
        "examImageUrl": "http://.../1001_SE171234_exam.jpg"
      }
    }
  ]
}
```

---

### Q11.3: Tại sao cần lưu evidence image? Dùng để làm gì?

**Trả lời đơn giản:**

**Evidence image là gì?**

- Ảnh crop khuôn mặt tại thời điểm nhận diện
- Lưu làm bằng chứng điểm danh

**Mục đích sử dụng:**

1. **Verification (Xác minh):**

   ```
   Sinh viên: "Tôi có mặt nhưng không được điểm danh!"
   Giảng viên: Xem evidence → Thấy ảnh sinh viên khác
              → "Hệ thống nhận diện đúng, bạn không có mặt"
   ```

2. **Audit (Kiểm toán):**

   ```
   Nghi ngờ gian lận:
   - Xem evidence của sinh viên A
   - Phát hiện ảnh là người khác giả mạo
   - Xử lý kỷ luật
   ```

3. **Dispute Resolution (Giải quyết tranh chấp):**

   ```
   Sinh viên khiếu nại điểm danh sai:
   - Evidence cho thấy đúng là sinh viên đó
   - Hoặc cho thấy hệ thống nhận nhầm
   - Có cơ sở để quyết định
   ```

4. **Quality Improvement:**
   ```
   Phân tích evidence của các trường hợp fail:
   - Ánh sáng kém?
   - Góc nghiêng?
   - Khuôn mặt bị che?
   → Cải thiện setup camera
   ```

**Thông tin trong evidence:**

```
Filename: 1001_SE171234.jpg
         └─┬─┘ └───┬───┘
       user_id  roll_number

Metadata (có thể thêm):
- Timestamp
- Camera ID
- Confidence score
- Slot ID
```

---

### Q11.4: Giảng viên có thể override kết quả điểm danh không?

**Trả lời đơn giản:**

**Có, giảng viên có thể override.**

**Các trường hợp cần override:**

1. **False Negative (Bỏ sót):**

   ```
   Sinh viên có mặt nhưng không được điểm danh
   → Giảng viên điểm danh thủ công
   → Status: PRESENT (manual)
   ```

2. **False Positive (Nhận nhầm):**

   ```
   Sinh viên không có mặt nhưng được điểm danh (hiếm)
   → Giảng viên xem evidence, phát hiện sai
   → Đổi status: ABSENT
   ```

3. **Late arrival:**

   ```
   Sinh viên đến muộn, sau khi kết thúc điểm danh
   → Giảng viên điểm danh thủ công
   → Status: LATE
   ```

4. **Excused absence:**
   ```
   Sinh viên vắng có phép (ốm, việc gia đình)
   → Giảng viên cập nhật
   → Status: EXCUSED
   ```

**Trong hệ thống:**

```
Recognition Service: Tự động điểm danh
                          │
                          ▼
Java Backend: Lưu kết quả với source = "AUTO"
                          │
                          ▼
Giảng viên: Có thể override qua UI
            → source = "MANUAL"
            → Ghi chú lý do
```

**Audit trail:**

- Mọi thay đổi đều được log
- Ai thay đổi, khi nào, từ gì sang gì
- Đảm bảo accountability

---

## 12. INTEGRATION

### Q12.1: Java Backend gửi gì cho Recognition Service khi bắt đầu điểm danh?

**Trả lời đơn giản:**

**Endpoint:** `POST /api/v1/recognition/process-session`

**Request body:**

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
            "embeddingVector": [0.123, -0.456, ...],  // 512 số
            "embeddingVersion": 1
        },
        {
            "userId": 1002,
            "fullName": "Trần Thị B",
            "rollNumber": "SE171235",
            "embeddingVector": [0.234, -0.567, ...],
            "embeddingVersion": 1
        }
        // ... tất cả sinh viên trong lớp
    ],

    "cameras": [
        {
            "id": 1,
            "name": "Camera Trước",
            "rtspUrl": "rtsp://admin:pass@192.168.1.100:554/stream"
        },
        {
            "id": 2,
            "name": "Camera Sau",
            "rtspUrl": "rtsp://admin:pass@192.168.1.101:554/stream"
        }
    ],

    "config": {
        "similarityThreshold": 0.55,
        "scanInterval": 3.0,
        "callbackUrl": "http://localhost:8080/api/internal/recognition/callback"
    }
}
```

**Giải thích từng phần:**

1. **slotId, roomId:** Định danh buổi học và phòng
2. **mode:** INITIAL hoặc RESCAN
3. **callbackType:** REGULAR hoặc EXAM
4. **students:** Danh sách sinh viên với embeddings (đã lưu trong DB)
5. **cameras:** Danh sách cameras trong phòng
6. **config:** Cấu hình cho session này

---

### Q12.2: Recognition Service gửi gì về khi nhận diện được sinh viên?

**Trả lời đơn giản:**

**Endpoint:** `POST {callbackUrl}` (do Java Backend cung cấp)

**Request body:**

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

**Giải thích từng field:**

1. **slotId:** Để Java Backend biết cập nhật cho buổi nào
2. **mode:** INITIAL hay RESCAN (để xử lý khác nhau nếu cần)
3. **callbackType:** Route đến bảng nào (lecture_attendance hay exam_attendance)
4. **recognitions:** Danh sách sinh viên được nhận diện
   - **studentUserId:** ID sinh viên
   - **confidence:** Độ tin cậy (similarity score)
   - **timestamp:** Thời điểm nhận diện
   - **cameraId:** Camera nào nhận diện được
   - **evidence:** URL ảnh bằng chứng

**Lưu ý:**

- Mỗi callback chứa **1 recognition** (gửi ngay khi nhận diện)
- Có thể batch nhiều recognitions nếu cần tối ưu

---

### Q12.3: Làm sao frontend biết được sinh viên vừa được điểm danh? (Realtime)

**Trả lời đơn giản:**

**Luồng realtime:**

```
┌─────────────┐     ┌─────────────┐     ┌─────────────────┐
│  Frontend   │◀────│   Backend   │◀────│ Recognition Svc │
│  (Next.js)  │ SSE │   (Java)    │ HTTP│    (Python)     │
└─────────────┘     └─────────────┘     └─────────────────┘
```

**Cơ chế: Server-Sent Events (SSE)**

1. **Frontend subscribe:**

   ```javascript
   const eventSource = new EventSource("/api/attendance/stream?slotId=123");

   eventSource.onmessage = (event) => {
     const data = JSON.parse(event.data);
     // Cập nhật UI: Sinh viên X vừa được điểm danh
   };
   ```

2. **Backend nhận callback từ Recognition Service:**

   ```java
   @PostMapping("/api/internal/recognition/callback")
   public void handleCallback(@RequestBody RecognitionCallback callback) {
       // Lưu vào database
       attendanceService.markPresent(callback);

       // Push event đến frontend
       sseEmitter.send(SseEmitter.event()
           .name("recognition")
           .data(callback));
   }
   ```

3. **Frontend nhận event và cập nhật UI:**

   ```
   Trước: [Danh sách 25/30 sinh viên có mặt]

   Event: { studentId: 1026, name: "Lê Văn C", confidence: 0.89 }

   Sau: [Danh sách 26/30 sinh viên có mặt]
         + Animation highlight sinh viên mới
   ```

**Tại sao dùng SSE thay vì WebSocket?**

1. **Đơn giản hơn:**

   - SSE là HTTP, không cần protocol riêng
   - Tự động reconnect

2. **Phù hợp use case:**

   - Chỉ cần server → client (one-way)
   - Không cần client → server realtime

3. **Firewall friendly:**
   - Dùng HTTP port 80/443
   - Không bị block như WebSocket

---

## 13. TÓM TẮT - ĐIỂM QUAN TRỌNG KHI BẢO VỆ

### Những điểm cần nhớ:

**1. Về Face Recognition:**

- Embedding 512 chiều, đủ để phân biệt hàng triệu người
- Cosine similarity đo góc giữa vectors
- Ngưỡng 0.55 là cân bằng giữa accuracy và recall
- InsightFace/ArcFace là state-of-the-art, đã train sẵn

**2. Về Kiến trúc:**

- Microservice riêng vì Python tốt cho AI/ML
- Callback pattern vì xử lý lâu, kết quả liên tục
- Session in-memory vì đơn giản, nhanh (trade-off: mất khi restart)

**3. Về Xử lý lỗi:**

- Deduplication bằng Set để tránh điểm danh trùng
- Retry với exponential backoff cho callbacks
- Auto-stop khi backend không phản hồi

**4. Về Bảo mật:**

- API Key authentication
- Không có anti-spoofing (cần giám sát của giảng viên)
- Evidence images cần bảo vệ thêm cho production

**5. Về Scalability:**

- 1 instance có giới hạn
- Scale bằng cách thêm instances + Redis cho shared state

### Câu trả lời ngắn gọn cho câu hỏi khó:

**"Sinh đôi thì sao?"**
→ Có thể nhận nhầm. Giải pháp: Tăng ngưỡng hoặc kết hợp yếu tố khác.

**"Spoofing attack?"**
→ Không có anti-spoofing. Dựa vào giám sát của giảng viên.

**"Scale 100 lớp?"**
→ Cần nhiều instances + Redis. 1 instance không đủ.

**"Tại sao 512 chiều?"**
→ Cân bằng giữa accuracy và performance. Kết quả nghiên cứu của ArcFace.

**"False Positive vs False Negative?"**
→ FP nguy hiểm hơn (gian lận). Ưu tiên giảm FP, chấp nhận một số FN.

---

_Tài liệu này được tạo để hỗ trợ sinh viên chuẩn bị bảo vệ đồ án._
_Nội dung tập trung vào nguyên lý hoạt động và use cases thực tế._


---

## 14. MẪU CÂU TRẢ LỜI THỰC TẾ (PHONG CÁCH TỰ NHIÊN)

> Phần này tổng hợp các câu trả lời theo phong cách tự nhiên, trung thực,
> phù hợp khi trình bày trước hội đồng.

---

### 14.1. Tại sao cần convert ảnh thành vector số (embedding)?

**Cách trả lời:**

> "Dạ, vì AI không thể thực sự "nhìn" thấy ảnh như con người, mà chỉ có thể xử lý các con số. Vì vậy việc convert ảnh khuôn mặt thành một dãy số (vector) để AI có thể so sánh và nhận diện là hợp lý và bắt buộc.
>
> Còn việc convert như thế nào thì đó là chức năng của thư viện InsightFace mà nhóm em sử dụng. Thư viện này đã được train sẵn trên hàng triệu khuôn mặt, nên em chỉ cần gọi API để lấy embedding, không cần tự implement thuật toán."

---

### 14.2. Cosine similarity hoạt động như thế nào?

**Cách trả lời:**

> "Dạ, về cơ bản, nếu như 1 ảnh của 1 người được convert thành vector 2 lần thì sẽ có 2 vector gần như giống nhau. Trong toán học, 2 vector giống nhau được coi là cùng hướng, và cosine của góc giữa chúng bằng 1.
>
> Sử dụng nguyên lý này, nhóm em áp dụng cho nhận diện khuôn mặt:
> - Nếu cosine similarity gần 1 → 2 khuôn mặt giống nhau → Cùng 1 người
> - Nếu cosine similarity thấp → 2 khuôn mặt khác nhau → Khác người
>
> Nhóm em đặt ngưỡng 0.55, tức là nếu similarity >= 0.55 thì coi như match."

---

### 14.3. Tại sao chọn model buffalo_l?

**Cách trả lời:**

> "Dạ, về việc sử dụng model buffalo_l, nhóm em đã nghiên cứu và tìm hiểu các model face recognition hiện có trên mạng. Nhóm nhận thấy model này được cộng đồng đánh giá khá cao về độ chính xác.
>
> Đồng thời nhóm em cũng đã thử nghiệm với nhiều trường hợp trong các điều kiện môi trường, ánh sáng, chất lượng camera khác nhau. Kết quả cho thấy model này cho chất lượng từ mức OK trở lên, phù hợp với yêu cầu của hệ thống điểm danh."

---

### 14.4. Session lưu trong RAM, nếu service crash thì sao?

**Cách trả lời:**

> "Dạ, hiện tại các session điểm danh ở bên Python đang được lưu trong RAM, tức là khi service crash và khởi động lại thì session sẽ mất.
>
> Tuy nhiên em thấy đây là phần chấp nhận được vì:
> - Thường 1 phiên điểm danh chỉ kéo dài tầm 5 đến 10 phút
> - Service hiếm khi crash trong khoảng thời gian ngắn như vậy
>
> Nếu muốn thực sự chặt chẽ hơn, nhóm em có thể tạo thêm các table trong database để lưu session state. Như vậy dù service bị crash thì vẫn có nơi lưu trữ riêng biệt và có thể recover được."

---

### 14.5. Sinh viên đeo kính/khẩu trang thì sao?

**Cách trả lời:**

> "Dạ, trong trường hợp đeo kính:
> - Nếu là kính trắng như em và các bạn đang đeo thì model hoàn toàn có thể xử lý được. Nhóm em đã test case này nhiều lần và kết quả tốt.
> - Nhưng với kính đen hoặc khẩu trang thì độ chính xác có thể giảm đáng kể.
>
> Lý do là vì mắt, mũi, miệng là những đặc điểm quan trọng để model nhận diện một người. Khi bị che thì model mất đi nhiều thông tin.
>
> Vì vậy em xin đề xuất: Giáo viên cần yêu cầu sinh viên bỏ khẩu trang, kính đen hoặc những vật che mặt tương tự khi quét mặt để có kết quả tốt nhất. Đây cũng là vì lợi ích điểm danh của chính sinh viên ạ."

---

### 14.6. Ánh sáng trong phòng kém thì sao?

**Cách trả lời:**

> "Dạ, nhóm em cũng đã test trong một vài điều kiện hơi tối nhẹ, và kết quả thì cũng ở tỉ lệ khá ổn.
>
> Tuy nhiên nếu thực sự muốn đảm bảo chất lượng tốt, em đề xuất sử dụng camera tốt hơn, có hỗ trợ IR (hồng ngoại) hoặc cải thiện ánh sáng trong phòng.
>
> Tức là đây không phải là vấn đề của hệ thống phần mềm, mà là vấn đề phần cứng. Phần mềm chỉ có thể xử lý tốt khi input (ảnh từ camera) có chất lượng đủ tốt."

---

### 14.7. Trường hợp sinh đôi thì sao?

**Cách trả lời:**

> "Dạ, case sinh đôi được coi là giới hạn không chỉ của hệ thống em mà còn của nhiều hệ thống nhận diện khuôn mặt khác trên thế giới.
>
> Vì căn bản 2 người sinh đôi cùng trứng thì gần như giống hệt nhau. Dù có khác thì chênh lệch rất nhỏ, khó phân biệt bằng AI.
>
> Vì vậy nhóm em đề xuất: Giáo viên cần kiểm tra kỹ case này nếu trong lớp có sinh đôi. Có thể kết hợp thêm các phương pháp khác như kiểm tra thẻ sinh viên hoặc vị trí ngồi."

---

### 14.8. Sinh viên đứng xa camera thì sao?

**Cách trả lời:**

> "Dạ, camera mà nhóm em test có thể quét được từ khoảng 5-7 mét.
>
> Như em đã nói, đây là vấn đề phần cứng. Chúng ta có thể khắc phục bằng cách:
> - Sử dụng camera có độ phân giải cao hơn, có zoom
> - Hoặc sử dụng nhiều camera trong 1 phòng để cover được nhiều góc và khoảng cách hơn
>
> Hệ thống của em đã hỗ trợ nhiều camera cho 1 phòng, nên việc mở rộng này hoàn toàn khả thi."

---

### 14.9. Spoofing attack (dùng ảnh giả) thì sao?

**Cách trả lời:**

> "Dạ, thành thật mà nói, model buffalo_l mà nhóm em sử dụng không có tính năng anti-spoofing, tức là không phát hiện được ảnh giả hay video.
>
> Tuy nhiên trong context của hệ thống điểm danh lớp học:
> - Có giáo viên giám sát trực tiếp trong lớp
> - Nếu sinh viên cầm ảnh hoặc điện thoại để giả mạo thì giáo viên sẽ phát hiện được
>
> Nếu muốn chống spoofing hoàn toàn, cần thêm tính năng Liveness Detection (yêu cầu nháy mắt, quay đầu) hoặc dùng camera có cảm biến độ sâu. Đây là hướng phát triển trong tương lai nếu có yêu cầu."

---

### 14.10. Tại sao tách Recognition Service riêng?

**Cách trả lời:**

> "Dạ, nhóm em tách Recognition Service thành microservice riêng vì:
>
> 1. **Ngôn ngữ phù hợp:** Các thư viện AI/ML như InsightFace, OpenCV chủ yếu viết bằng Python. Nếu gộp vào Java Backend sẽ rất phức tạp.
>
> 2. **Tài nguyên độc lập:** Face recognition cần GPU và nhiều RAM. Tách riêng thì khi recognition bận, backend vẫn hoạt động bình thường.
>
> 3. **Dễ scale:** Nếu cần xử lý nhiều phòng cùng lúc, có thể chạy nhiều instances của Recognition Service mà không ảnh hưởng đến backend.
>
> 4. **Fault isolation:** Nếu Recognition Service crash, các chức năng khác của hệ thống vẫn hoạt động bình thường."

---

### 14.11. Làm sao đảm bảo không điểm danh trùng?

**Cách trả lời:**

> "Dạ, nhóm em sử dụng cơ chế deduplication bằng Set trong Python.
>
> Cụ thể, mỗi session điểm danh có 1 Set lưu danh sách student ID đã được nhận diện. Trước khi gửi callback về backend, hệ thống kiểm tra:
> - Nếu student ID chưa có trong Set → Gửi callback và thêm vào Set
> - Nếu student ID đã có trong Set → Bỏ qua, không gửi callback
>
> Như vậy dù sinh viên xuất hiện trong camera 100 lần thì cũng chỉ được điểm danh 1 lần duy nhất."

---

### 14.12. Nếu backend không phản hồi callback thì sao?

**Cách trả lời:**

> "Dạ, nhóm em có implement cơ chế retry với exponential backoff:
> - Lần 1 fail → Đợi 1 giây → Thử lại
> - Lần 2 fail → Đợi 2 giây → Thử lại
> - Lần 3 fail → Bỏ cuộc
>
> Ngoài ra còn có cơ chế auto-stop: Nếu 10 callbacks liên tiếp fail hoặc 2 phút không có callback thành công, hệ thống sẽ tự động dừng session.
>
> Lý do là vì nếu backend không nhận được kết quả thì việc tiếp tục scan cũng không có ý nghĩa."

---

## 15. TIPS KHI TRẢ LỜI HỘI ĐỒNG

### 15.1. Nguyên tắc chung

1. **Trung thực:** Nếu không biết hoặc hệ thống có giới hạn, hãy nói thẳng
2. **Đề xuất giải pháp:** Sau khi nêu giới hạn, đề xuất cách khắc phục
3. **Phân biệt software vs hardware:** Nhiều vấn đề là do phần cứng, không phải phần mềm
4. **Nói về thực tế test:** "Nhóm em đã test..." tạo độ tin cậy

### 15.2. Các cụm từ hữu ích

- "Dạ, về vấn đề này..."
- "Nhóm em đã nghiên cứu và nhận thấy..."
- "Nhóm em đã test trong nhiều điều kiện..."
- "Đây là giới hạn không chỉ của hệ thống em mà còn của..."
- "Em xin đề xuất..."
- "Nếu muốn cải thiện, chúng em có thể..."
- "Đây là vấn đề phần cứng, không phải phần mềm..."

### 15.3. Khi không biết câu trả lời

> "Dạ, câu hỏi này em chưa nghiên cứu sâu. Nhưng theo hiểu biết của em thì... Em xin phép tìm hiểu thêm và bổ sung sau ạ."

### 15.4. Khi bị hỏi về giới hạn

> "Dạ, đây đúng là giới hạn của hệ thống hiện tại. Tuy nhiên nhóm em đã nhận thức được vấn đề này và có hướng giải quyết trong tương lai là..."

---

*Chúc bạn bảo vệ thành công! 🎓*
