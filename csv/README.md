# CSV Files cho Demo Import

## Thứ tự Import (theo dependencies)

1. `01_semesters.csv` - Không phụ thuộc
2. `02_majors.csv` - Không phụ thuộc
3. `03_subjects.csv` - Phụ thuộc Major
4. `04_rooms.csv` - Không phụ thuộc
5. `05_cameras.csv` - Phụ thuộc Room
6. `06_staff_profiles.csv` - Không phụ thuộc
7. `07_student_profiles.csv` - Phụ thuộc Major
8. `08_classes.csv` - Phụ thuộc Subject + Semester
9. `09_enrollments.csv` - Phụ thuộc Student + Class
10. `10_slots_lecture.csv` - Phụ thuộc Class + Room + Staff
11. `11_slots_exam.csv` - Phụ thuộc Semester + Room + Staff + Subject
12. `12_exam_participants.csv` - Phụ thuộc Exam Slot + Student + Subject

## CSV Format

### Staff Profile (06_staff_profiles.csv)
```
full_name,email,staff_code,username,roles,status,password
```
- `username` là optional - nếu để trống sẽ mặc định = `staff_code`
- `roles` có thể là: LECTURER, SUPERVISOR (không cho phép DATA_OPERATOR)
- `status` và `password` là optional

### Student Profile (07_student_profiles.csv)
```
full_name,email,username,roll_number,major_code,status,password
```
- `username` là required
- `status` và `password` là optional

## Import Modes

- **AddOnly**: Chỉ thêm mới, skip nếu đã tồn tại
- **AddAndUpdate**: Thêm mới + cập nhật nếu đã tồn tại

## Test Cases

Mỗi file CSV chứa:
- Records cũ (đã có trong DB) → test skip/update behavior
- Records mới (SP26 data) → test add behavior

## API Endpoints

- `POST /api/v1/semesters/import?mode=AddOnly`
- `POST /api/v1/majors/import?mode=AddOnly`
- `POST /api/v1/subjects/import?mode=AddOnly`
- `POST /api/v1/rooms/import?mode=AddOnly`
- `POST /api/v1/cameras/import?mode=AddOnly`
- `POST /api/v1/staff-profiles/import?mode=AddOnly`
- `POST /api/v1/student-profiles/import?mode=AddOnly`
- `POST /api/v1/classes/import?mode=AddOnly`
- `POST /api/v1/enrollments/import?mode=AddOnly`
- `POST /api/v1/slots/import?mode=AddOnly`
- `POST /api/v1/slots/import-exam?mode=AddOnly`
- `POST /api/v1/exam-slot-import/participants?mode=AddOnly`
