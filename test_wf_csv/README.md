# Test CSV Files cho Import Workflow

## Tổng quan

Thư mục này chứa các file CSV để test chức năng import trong hệ thống FUACS. Các file được tạo để test workflow hoàn chỉnh:
- Tạo room mới và camera
- Tạo 2 classes thuộc FA25 cho 2 môn SE
- Đăng ký 5 sinh viên vào 2 classes
- Tạo 40 slots học trong 10 tuần

## Chi tiết dữ liệu

### Semester: FA25
- **Mã**: FA25 (Fall 2025)
- **Thời gian**: 2025-09-01 đến 2025-12-31

### Room và Camera
- **Room**: Room Test 99 (Test Location)
- **Cameras**:
  - Camera Test-A (192.168.1.130)
  - Camera Test-B (192.168.1.131)

### Classes
**1. SE-PRF192-FA25** (Programming Fundamentals)
- Môn: PRF192
- Lịch học:
  - Thứ 2: 07:30-09:50
  - Thứ 4: 09:50-12:20

**2. SE-SWE201-FA25** (Introduction to Software Engineering)
- Môn: SWE201
- Lịch học:
  - Thứ 2: 09:50-12:20
  - Thứ 4: 07:30-09:50

### Sinh viên (5 students)
- HE180314 - Nguyen Doan Hieu
- HE181386 - Vu Tien Vuong
- HE180577 - Tran Duc Anh
- HE171369 - Phung Anh Tuan
- HE182129 - Dang Nguyen Bao

### Slots
- **Tổng số**: 40 slots
- **Thời gian**: 10 tuần (bắt đầu 2025-09-01)
- **Phân bổ**: 20 slots/class (2 slots/tuần)
- **Giảng viên**: lecturer01 (Tran Thi Lecturer 01)
- **Phòng học**: Room Test 99

### Final Exam
- **Ngày thi**: 2025-11-10 (Thứ 2 sau khi kết thúc 10 tuần học)
- **Thời gian**: 09:00-11:30 (2.5 giờ)
- **Phòng thi**: Room Test 99
- **Giám thị**: supervisor01 (Cao Van Supervisor 01)
- **Môn thi**: PRF192 và SWE201 (cùng 1 exam slot)
- **Thí sinh**: 5 sinh viên thi cả 2 môn (10 registrations)

## Cách Import

### Option 1: SQL Script (Khuyến nghị)

Chạy file SQL để import tất cả dữ liệu một lần:

```bash
# Windows (Git Bash hoặc WSL)
docker exec -i <container_id> psql -U postgres -d fuacs_dev < import_data_fa25.sql

# Linux/Mac
docker exec -i <container_id> psql -U postgres -d fuacs_dev < import_data_fa25.sql

# Hoặc kết nối vào container
docker exec -it <container_id> bash
psql -U postgres -d fuacs_dev -f /path/to/import_data_fa25.sql
```

### Option 2: CSV Import qua API

Import từng file theo thứ tự (nếu cần test chức năng CSV import):

1. **Import Room**: `POST /api/v1/rooms/import` (File: 1_rooms.csv)
2. **Import Cameras**: `POST /api/v1/cameras/import` (File: 2_cameras.csv)
3. **Import Classes**: `POST /api/v1/classes/import` (File: 3_classes.csv)
4. **Import Enrollments**: `POST /api/v1/enrollments/import` (File: 4_enrollments.csv)
5. **Import Slots**: `POST /api/v1/slots/import` (File: 5_slots.csv)
6. **Import Exam Slots**: `POST /api/v1/slots/import-exams` (File: 6_exam_slots.csv)
7. **Import Exam Participants**: `POST /api/v1/exam-slot-participants/import` (File: 7_exam_participants.csv)

## Kết quả mong đợi

Sau khi import thành công:
- ✅ 1 room mới (Room Test 99)
- ✅ 2 cameras cho room
- ✅ 2 classes thuộc FA25
- ✅ 10 enrollments (5 students x 2 classes)
- ✅ 40 slots học (20 slots/class trong 10 tuần)
- ✅ 1 exam slot (Final Exam cho 2 môn)
- ✅ 10 exam participants (5 students x 2 subjects)

## Lịch học chi tiết (10 tuần)

| Tuần | Thứ 2 | Thứ 4 |
|------|--------|--------|
| 1 | 2025-09-01 | 2025-09-03 |
| 2 | 2025-09-08 | 2025-09-10 |
| 3 | 2025-09-15 | 2025-09-17 |
| 4 | 2025-09-22 | 2025-09-24 |
| 5 | 2025-09-29 | 2025-10-01 |
| 6 | 2025-10-06 | 2025-10-08 |
| 7 | 2025-10-13 | 2025-10-15 |
| 8 | 2025-10-20 | 2025-10-22 |
| 9 | 2025-10-27 | 2025-10-29 |
| 10 | 2025-11-03 | 2025-11-05 |

### Thời khóa biểu chi tiết

**Thứ 2:**
- 07:30-09:50: PRF192 (SE-PRF192-FA25)
- 09:50-12:20: SWE201 (SE-SWE201-FA25)

**Thứ 4:**
- 07:30-09:50: SWE201 (SE-SWE201-FA25)
- 09:50-12:20: PRF192 (SE-PRF192-FA25)

## Lưu ý

1. **Dependency**: Đảm bảo các entity cần thiết đã tồn tại:
   - Semester FA25 ✓
   - Subjects PRF192, SWE201 ✓
   - Staff lecturer01 ✓
   - Students HE180314, HE181386, HE180577, HE171369, HE182129 ✓

2. **Import Mode**: Tất cả dùng `AddOnly` để tránh overwrite dữ liệu hiện có

3. **Error Handling**: Hệ thống sử dụng "Partial Success Strategy" - một số row lỗi không ảnh hưởng các row khác

4. **Validation**: CSV files đã follow đúng format và validation rules:
   - DateTime format: `yyyy-MM-dd'T'HH:mm:ss` (Vietnam timezone)
   - Status: `true`/`false`
   - Encoding: UTF-8

## Cleanup (nếu cần test lại)

Để xóa dữ liệu test và import lại, uncomment phần CLEANUP SECTION trong file `import_data_fa25.sql` và chạy lại:

```bash
# Edit file import_data_fa25.sql, uncomment phần cleanup (bỏ /* và */)
# Sau đó chạy:
docker exec -i <container_id> psql -U postgres -d fuacs_dev < import_data_fa25.sql
```

Hoặc chạy trực tiếp các lệnh SQL:

```sql
BEGIN;
DELETE FROM exam_slot_participants WHERE exam_slot_subject_id IN (
  SELECT id FROM exam_slot_subjects WHERE exam_slot_id IN (
    SELECT id FROM slots WHERE title = 'Final Exam SE-FA25'
  )
);
DELETE FROM exam_slot_subjects WHERE exam_slot_id IN (
  SELECT id FROM slots WHERE title = 'Final Exam SE-FA25'
);
DELETE FROM slots WHERE title = 'Final Exam SE-FA25';
DELETE FROM slots WHERE class_id IN (SELECT id FROM classes WHERE code LIKE 'SE-%-FA25');
DELETE FROM enrollments WHERE class_id IN (SELECT id FROM classes WHERE code LIKE 'SE-%-FA25');
DELETE FROM classes WHERE code LIKE 'SE-%-FA25';
DELETE FROM cameras WHERE room_id = (SELECT id FROM rooms WHERE name = 'Room Test 99');
DELETE FROM rooms WHERE name = 'Room Test 99';
COMMIT;
```

## Support

Nếu gặp lỗi khi import, check:
1. ImportResultDTO trong response (successCount, failureCount, errors)
2. Backend logs để xem chi tiết lỗi
3. Đảm bảo đã import đúng thứ tự
4. Kiểm tra dependencies đã tồn tại

---

**Generated**: 2025-11-13
**Purpose**: Test CSV Import Workflow
**Status**: Ready for testing
