# Exam Slot Module Documentation

## 1. Giới Thiệu

### 1.1. Exam Slot là gì?

**Exam Slot** là các slot thi cử trong hệ thống FUACS, bao gồm:

- **FINAL_EXAM**: Slot thi cuối kỳ thuần túy (chỉ dùng cho điểm danh thi)
- **LECTURE_WITH_PT**: Slot học có phần thi thực hành (hỗ trợ cả điểm danh thường và exam)

### 1.2. Sự khác biệt với Regular Slot

| Đặc điểm       | Regular Slot (LECTURE) | Exam Slot                 |
| -------------- | ---------------------- | ------------------------- |
| Loại điểm danh | `sessionStatus`        | `examSessionStatus`       |
| Bảng dữ liệu   | `attendance_records`   | `exam_attendance`         |
| Đơn vị quản lý | AcademicClass          | ExamSlotSubject           |
| Roster         | Class enrollments      | ExamSlotParticipants      |
| RESCAN mode    | Keep status + flag     | Override ABSENT → PRESENT |
| Portal chính   | Admin, Lecturer        | Supervisor                |

### 1.3. Entity Structure Overview

```
Slot (FINAL_EXAM)
  │
  ├── ExamSlotSubject ── Subject (môn thi)
  │         │
  │         └── ExamSlotParticipant ── User (sinh viên thi)
  │
  └── ExamAttendance ── User (record điểm danh)
```

### 1.4. Quyền hạn theo Role

| Role          | Quyền                                      |
| ------------- | ------------------------------------------ |
| DATA_OPERATOR | CRUD subjects, participants, attendance    |
| SUPERVISOR    | Xem slots, quản lý exam session, điểm danh |
| STUDENT       | Xem lịch thi của mình                      |

---

## 2. Kiến Trúc Hệ Thống

### 2.1. Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                     FRONTEND (Next.js)                          │
│                                                                 │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────────┐  │
│  │   Admin     │  │  Supervisor │  │       Data Operator     │  │
│  │  Portal     │  │   Portal    │  │         Portal          │  │
│  │ (/admin)    │  │(/supervisor)│  │       (/admin)          │  │
│  └──────┬──────┘  └──────┬──────┘  └───────────┬─────────────┘  │
│         │                │                      │                │
│  ┌──────┴────────────────┴──────────────────────┴──────────────┐│
│  │                    React Query Hooks                        ││
│  │  useExamSlotSubjects, useExamSlotParticipants,              ││
│  │  useExamAttendance, useExamSession                          ││
│  └──────────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ REST API
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    BACKEND (Spring Boot)                        │
│                                                                 │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │                      Controllers                           │ │
│  │    ExamSlotController    ExamAttendanceController          │ │
│  │    /api/v1/exam-slots    /api/v1/exam-attendance           │ │
│  └────────────────────────────────────────────────────────────┘ │
│                              │                                  │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │                       Services                             │ │
│  │    ExamSlotService       ExamAttendanceService             │ │
│  │    SlotSessionService    ExamSlotImportService             │ │
│  └────────────────────────────────────────────────────────────┘ │
│                              │                                  │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │                       Entities                             │ │
│  │    Slot (FINAL_EXAM)     ExamSlotSubject                   │ │
│  │    ExamSlotParticipant   ExamAttendance                    │ │
│  │    ExamAttendanceEvidence                                  │ │
│  └────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ Callback
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│               RECOGNITION SERVICE (Python)                      │
│                                                                 │
│  callbackType: EXAM → exam_attendance table                     │
└─────────────────────────────────────────────────────────────────┘
```

### 2.2. Data Flow

```
1. Tạo Exam Slot (FINAL_EXAM)
   Admin → SlotController.create() → Slot entity

2. Gán môn thi vào slot
   Admin → ExamSlotController.assignSubjects() → ExamSlotSubject

3. Thêm sinh viên thi
   Admin → ExamSlotController.addParticipant() → ExamSlotParticipant + ExamAttendance

4. Start exam session
   Supervisor → SlotSessionController.startExamSession()

5. Face recognition
   Python → RecognitionCallback → ExamAttendanceService.processRecognitionResults()

6. Điểm danh auto → ExamAttendance (PRESENT/ABSENT)
```

---

## 3. Backend Implementation

### 3.1. Database Schema

#### exam_slot_subjects

```sql
CREATE TABLE exam_slot_subjects (
    id                     BIGSERIAL PRIMARY KEY,
    slot_id                INTEGER NOT NULL REFERENCES slots(id),
    subject_id             INTEGER NOT NULL REFERENCES subjects(id),
    created_at             TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- Soft delete
    is_active              BOOLEAN NOT NULL DEFAULT TRUE,
    deactivated_at         TIMESTAMP,
    deactivated_by_user_id INTEGER REFERENCES users(id),

    CONSTRAINT idx_exam_slot_subjects_slot_subject UNIQUE (slot_id, subject_id)
);

CREATE INDEX idx_exam_slot_subjects_slot_id ON exam_slot_subjects(slot_id);
```

#### exam_slot_participants

```sql
CREATE TABLE exam_slot_participants (
    id                   BIGSERIAL PRIMARY KEY,
    exam_slot_subject_id BIGINT NOT NULL REFERENCES exam_slot_subjects(id),
    student_user_id      INTEGER NOT NULL REFERENCES users(id),
    is_enrolled          BOOLEAN NOT NULL DEFAULT TRUE,
    created_at           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT idx_exam_participants_slot_subject_student
        UNIQUE (exam_slot_subject_id, student_user_id)
);

CREATE INDEX idx_exam_participants_student_user_id
    ON exam_slot_participants(student_user_id);
```

#### exam_attendance

```sql
CREATE TABLE exam_attendance (
    id              BIGSERIAL PRIMARY KEY,
    student_user_id INTEGER NOT NULL REFERENCES users(id),
    slot_id         INTEGER NOT NULL REFERENCES slots(id),
    status          VARCHAR(10) NOT NULL,      -- NOT_YET, PRESENT, ABSENT
    method          VARCHAR(20) NOT NULL,      -- AUTO, MANUAL
    recorded_at     TIMESTAMP NOT NULL,
    remark          TEXT,
    needs_review    BOOLEAN NOT NULL DEFAULT FALSE,
    created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT idx_exam_attendance_student_slot UNIQUE (student_user_id, slot_id)
);

CREATE INDEX idx_exam_attendance_slot_id ON exam_attendance(slot_id);
CREATE INDEX idx_exam_attendance_status ON exam_attendance(status);
```

#### exam_attendance_evidences

```sql
CREATE TABLE exam_attendance_evidences (
    id                  BIGSERIAL PRIMARY KEY,
    exam_attendance_id  BIGINT NOT NULL UNIQUE REFERENCES exam_attendance(id),
    image_url           VARCHAR(500) NOT NULL,
    created_at          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
```

### 3.2. Entity Classes

#### ExamSlotSubject.java

```
backend/src/main/java/com/fuacs/backend/entity/ExamSlotSubject.java
```

**Quan hệ:**

- `@ManyToOne Slot` - Slot exam
- `@ManyToOne Subject` - Môn thi

**Key fields:**

- `isActive` - Soft delete flag
- `deactivatedAt`, `deactivatedByUser` - Audit thông tin xóa

**Business logic:**

- 1 slot có thể có nhiều môn thi (multiple subjects per slot)
- UniqueConstraint: `(slot_id, subject_id)` - 1 môn chỉ được gán 1 lần vào slot

#### ExamSlotParticipant.java

```
backend/src/main/java/com/fuacs/backend/entity/ExamSlotParticipant.java
```

**Quan hệ:**

- `@ManyToOne ExamSlotSubject` - Liên kết với môn thi trong slot
- `@ManyToOne User (studentUser)` - Sinh viên tham gia

**Key fields:**

- `isEnrolled` - Trạng thái đăng ký (true = active, false = withdrawn)

**Business logic:**

- UniqueConstraint: `(exam_slot_subject_id, student_user_id)` - 1 sinh viên chỉ đăng ký 1 lần cho 1 môn thi

#### ExamAttendance.java

```
backend/src/main/java/com/fuacs/backend/entity/ExamAttendance.java
```

**Quan hệ:**

- `@ManyToOne User (student)` - Sinh viên
- `@ManyToOne Slot` - Slot thi

**Key fields:**

- `status` - `NOT_YET` | `PRESENT` | `ABSENT`
- `method` - `AUTO` | `MANUAL`
- `recordedAt` - Thời điểm ghi nhận
- `remark` - Ghi chú (inline, không qua Remark entity)
- `needsReview` - Cờ cần review (sau RESCAN)

**Business logic:**

- UniqueConstraint: `(student_user_id, slot_id)` - 1 sinh viên chỉ có 1 record điểm danh cho 1 slot
- **Khác với Regular**: Không phân biệt theo subject, mỗi student có 1 record cho toàn bộ exam slot

### 3.3. Controller Endpoints

#### ExamSlotController (`/api/v1/exam-slots`)

```
backend/src/main/java/com/fuacs/backend/controller/ExamSlotController.java
```

| Method | Endpoint                         | Permission        | Mô tả                                  |
| ------ | -------------------------------- | ----------------- | -------------------------------------- |
| POST   | `/{slotId}/subjects`             | ENROLLMENT_MANAGE | Gán môn thi vào slot                   |
| GET    | `/{slotId}/subjects`             | SLOT_READ         | Lấy danh sách môn thi                  |
| DELETE | `/{slotId}/subjects/{subjectId}` | ENROLLMENT_MANAGE | Xóa môn thi                            |
| POST   | `/{slotId}/participants`         | ENROLLMENT_MANAGE | Thêm sinh viên thi                     |
| GET    | `/{slotId}/participants`         | SLOT_READ         | Lấy danh sách theo subject             |
| GET    | `/{slotId}/all-participants`     | SLOT_READ         | Lấy tất cả sinh viên (across subjects) |
| GET    | `/{slotId}/participants/{id}`    | SLOT_READ         | Lấy chi tiết participant               |
| PUT    | `/{slotId}/participants/{id}`    | ENROLLMENT_MANAGE | Cập nhật participant                   |
| DELETE | `/{slotId}/participants/{id}`    | ENROLLMENT_MANAGE | Xóa participant                        |
| GET    | `/{slotId}/attendance-report`    | SLOT_READ         | Lấy báo cáo điểm danh                  |

#### ExamAttendanceController (`/api/v1/exam-attendance`)

```
backend/src/main/java/com/fuacs/backend/controller/ExamAttendanceController.java
```

| Method | Endpoint | Permission                      | Mô tả                  |
| ------ | -------- | ------------------------------- | ---------------------- |
| GET    | `/`      | ATTENDANCE_ROSTER_READ          | Search exam attendance |
| GET    | `/{id}`  | ATTENDANCE_ROSTER_READ          | Lấy chi tiết record    |
| PUT    | `/{id}`  | ATTENDANCE_STATUS_UPDATE_MANUAL | Cập nhật status        |

### 3.4. Service Classes

#### ExamSlotService

```
backend/src/main/java/com/fuacs/backend/service/ExamSlotService.java
```

**Chức năng chính:**

1. **assignSubjectsToSlot()**: Gán môn thi vào exam slot

   - Validate slot là FINAL_EXAM hoặc LECTURE_WITH_PT
   - Validate subject tồn tại và active
   - Tạo ExamSlotSubject records

2. **addParticipant()**: Thêm sinh viên vào exam

   - Validate student enrolled trong subject (qua Enrollment)
   - Tạo ExamSlotParticipant
   - **Tự động tạo ExamAttendance** với status `NOT_YET`

3. **removeParticipant()**: Xóa sinh viên khỏi exam
   - Set `isEnrolled = false` (soft delete)
   - **Không xóa ExamAttendance** (giữ history)

#### ExamAttendanceService

```
backend/src/main/java/com/fuacs/backend/service/ExamAttendanceService.java
```

**Chức năng chính:**

1. **findAll()**: Search exam attendance với filters

2. **updateStatus()**: Cập nhật status thủ công

   - Validate edit window (before 23:59:59 của ngày slot)
   - Validate assigned staff
   - Set `method = MANUAL`

3. **processRecognitionResults()**: Xử lý callback từ Python

   - **INITIAL mode**:
     - NOT_YET → PRESENT
     - ABSENT → PRESENT (override)
   - **RESCAN mode**:
     - ABSENT → PRESENT (late arrival override)
     - PRESENT detected → Update evidence
     - PRESENT not detected → Keep PRESENT (trust exam completion)

4. **applyRescanReviewFlags()**: Xử lý sau RESCAN
   - PRESENT + detected → Clear `needsReview`
   - **Khác Regular**: Không set `needsReview` cho PRESENT not detected

### 3.5. RESCAN Mode Logic (Exam vs Regular)

**Đây là điểm khác biệt quan trọng nhất:**

```
┌──────────────────────────────────────────────────────────────┐
│                    REGULAR ATTENDANCE                        │
├──────────────────────────────────────────────────────────────┤
│ PRESENT + detected  → Keep PRESENT, clear needsReview        │
│ PRESENT + NOT detected → Keep PRESENT + needsReview=TRUE     │
│ ABSENT + detected   → Keep ABSENT + needsReview=TRUE         │
│                       (student cần review - rời sớm?)        │
└──────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────┐
│                    EXAM ATTENDANCE                           │
├──────────────────────────────────────────────────────────────┤
│ PRESENT + detected  → Keep PRESENT, clear needsReview        │
│ PRESENT + NOT detected → Keep PRESENT (trust exam completion)│
│ ABSENT + detected   → Override to PRESENT (late arrival OK)  │
│                       (sinh viên đến muộn vẫn được thi)      │
└──────────────────────────────────────────────────────────────┘
```

**Lý do:**

- **Regular**: Nếu ABSENT nhưng detected trong RESCAN → Sinh viên có thể rời sớm, cần review
- **Exam**: Nếu ABSENT nhưng detected trong RESCAN → Sinh viên đến muộn, cho phép thi, override thành PRESENT

---

## 4. Frontend Implementation

### 4.1. Routes

```
/supervisor/slots                    → Danh sách exam slots (table view)
/supervisor/schedule                 → Calendar view của exam slots
/supervisor/reports/slots            → Báo cáo điểm danh exam
/supervisor/reports/slots/[slotId]   → Chi tiết điểm danh 1 slot
```

### 4.2. React Query Hooks

#### useExamSlotSubjects.ts

```
frontend-web/hooks/api/useExamSlotSubjects.ts
```

Hook quản lý môn thi trong exam slot:

- `useGetExamSlotSubjects(slotId)` - Lấy danh sách môn thi
- `useAssignExamSlotSubjects()` - Gán môn thi vào slot
- `useRemoveExamSlotSubject()` - Xóa môn thi

#### useExamSlotParticipants.ts

```
frontend-web/hooks/api/useExamSlotParticipants.ts
```

Hook quản lý sinh viên thi:

- `useImportExamSlotParticipants()` - Import từ CSV

**CSV format:**

```csv
semester_code,start_time,room_name,subject_code,roll_number
FA24,2024-12-20T08:00:00,301,PRN212,SE160001
FA24,2024-12-20T08:00:00,301,PRN212,SE160002
```

#### useExamAttendance.ts

```
frontend-web/hooks/api/useExamAttendance.ts
```

Hook quản lý điểm danh thi:

- `useGetExamAttendanceRecords(params)` - Lấy danh sách với filters
- `useGetExamAttendanceRecord(id)` - Lấy chi tiết record
- `useUpdateExamAttendance(slotId)` - Cập nhật status thủ công

#### useExamSession.ts

```
frontend-web/hooks/api/useExamSession.ts
```

Hook quản lý exam session:

- `useStartExamSession(slotId)` - Bắt đầu session điểm danh
- `useStopExamSession(slotId)` - Kết thúc session
- `useRescanExamSession(slotId)` - Bắt đầu RESCAN mode

### 4.3. Components Structure

```
frontend-web/components/supervisor/
├── slots/
│   ├── supervisor-slot-table.tsx       # Bảng danh sách exam slots
│   ├── supervisor-slot-columns.tsx     # Column definitions
│   └── supervisor-exam-detail-dialog.tsx  # Dialog chi tiết exam
├── schedule/
│   ├── schedule-container.tsx          # Calendar wrapper
│   ├── schedule-header.tsx             # Header với filters
│   ├── schedule-filters.tsx            # Semester, date filters
│   ├── calendar-week-container.tsx     # Week view calendar
│   └── slot-detail-dialog.tsx          # Dialog xem slot từ calendar
└── reports/
    ├── slot-reports-container.tsx      # Container chính
    ├── slot-semester-filter.tsx        # Filter theo semester
    ├── slot-accordion-list.tsx         # List slots accordion
    ├── slot-accordion-item.tsx         # Single slot accordion
    ├── slot-detail-container.tsx       # Chi tiết 1 slot
    ├── slot-attendance-table.tsx       # Bảng điểm danh
    ├── slot-stats-summary.tsx          # Thống kê tổng hợp
    ├── exam-slot-info.tsx              # Thông tin exam slot
    ├── exam-slot-statistics.tsx        # Thống kê exam
    ├── exam-subjects-list.tsx          # Danh sách môn thi
    ├── exam-students-list.tsx          # Danh sách sinh viên thi
    └── multi-slot-export-dialog.tsx    # Export nhiều slots
```

### 4.4. Key Component: supervisor-exam-detail-dialog.tsx

```
frontend-web/components/supervisor/slots/supervisor-exam-detail-dialog.tsx
```

**Chức năng:**

- Hiển thị thông tin chi tiết exam slot
- Subjects list (môn thi)
- Time, location, student count
- Supervisor info
- Exam status (Upcoming/Ongoing/Completed)

**Props:**

```typescript
interface SupervisorExamDetailDialogProps {
  slot: Slot;
  open: boolean;
  onClose: () => void;
}
```

### 4.5. Zod Schemas

```
frontend-web/lib/zod-schemas.ts
```

```typescript
// Exam Attendance Record
export const examAttendanceRecordSchema = z.object({
  id: z.number(),
  student: studentProfileSchema,
  slot: slotSchema.partial(),
  subjectInfo: z
    .object({
      id: z.number(),
      code: z.string(),
      name: z.string(),
    })
    .nullable(),
  status: attendanceStatusSchema,
  method: attendanceMethodSchema,
  recordedAt: z.string(),
  remark: z.string().nullable(),
  needsReview: z.boolean(),
});

// Exam Slot Participant
export const examSlotParticipantSchema = z.object({
  id: z.number(),
  studentUserId: z.number(),
  studentFullName: z.string(),
  studentUsername: z.string(),
  rollNumber: z.string().nullable(),
  subjectCode: z.string(),
  subjectName: z.string(),
  isEnrolled: z.boolean(),
});
```

---

## 5. Luồng Xử Lý

### 5.1. Tạo Exam Slot và Gán Subjects

```
┌─────────────────────────────────────────────────────────────┐
│  Admin tạo Slot (category = FINAL_EXAM)                     │
│  POST /api/v1/slots                                         │
└────────────────────────────┬────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────┐
│  Admin gán môn thi vào slot                                 │
│  POST /api/v1/exam-slots/{slotId}/subjects                  │
│  Body: { subjectIds: [1, 2, 3] }                            │
└────────────────────────────┬────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────┐
│  ExamSlotService.assignSubjectsToSlot()                     │
│  - Validate slot exists & is FINAL_EXAM                     │
│  - Validate subjects exist & active                         │
│  - Create ExamSlotSubject records                           │
└─────────────────────────────────────────────────────────────┘
```

### 5.2. Thêm Sinh Viên Thi (Import CSV)

```
┌─────────────────────────────────────────────────────────────┐
│  Admin upload CSV file                                      │
│  POST /api/v1/exam-slot-participants/import                 │
│                                                             │
│  CSV: semester,start_time,room,subject_code,roll_number     │
│       FA24,2024-12-20T08:00,301,PRN212,SE160001             │
└────────────────────────────┬────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────┐
│  ExamSlotImportService.importParticipants()                 │
│  For each row:                                              │
│    1. Find slot by (semester, start_time, room)             │
│    2. Find ExamSlotSubject by subject_code                  │
│    3. Find student by roll_number                           │
│    4. Validate student enrolled in subject                  │
│    5. Create ExamSlotParticipant                            │
│    6. Create ExamAttendance (status = NOT_YET)              │
└─────────────────────────────────────────────────────────────┘
```

### 5.3. Exam Session & Face Recognition

```
┌─────────────────────────────────────────────────────────────┐
│  Supervisor start exam session                              │
│  POST /api/v1/slot-session/{slotId}/start-exam              │
└────────────────────────────┬────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────┐
│  SlotSessionService.startExamSession()                      │
│  - Set examSessionStatus = ACTIVE                           │
│  - Call Python recognition-service/process-session          │
│  - Camera begins capturing frames                           │
└────────────────────────────┬────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────┐
│  Python Recognition Service                                 │
│  - Detect faces from RTSP stream                            │
│  - Match with student embeddings                            │
│  - Send callback to Java backend                            │
│                                                             │
│  POST /api/v1/recognition-callback                          │
│  { callbackType: "EXAM", slotId, recognitions: [...] }      │
└────────────────────────────┬────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────┐
│  RecognitionCallbackController routes to ExamAttendance     │
│                                                             │
│  ExamAttendanceService.processRecognitionResults()          │
│  - NOT_YET/ABSENT detected → Update to PRESENT              │
│  - PRESENT detected → Keep PRESENT (update evidence)        │
│  - Store evidence image                                     │
│  - Publish SSE event                                        │
└─────────────────────────────────────────────────────────────┘
```

### 5.4. RESCAN Mode (Late Arrival)

```
┌─────────────────────────────────────────────────────────────┐
│  Supervisor trigger RESCAN                                  │
│  POST /api/v1/slot-session/{slotId}/rescan-exam             │
│                                                             │
│  Use case: Sinh viên đến muộn sau khi session đã stop       │
└────────────────────────────┬────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────┐
│  SlotSessionService.rescanExamSession()                     │
│  - Set mode = RESCAN                                        │
│  - Call Python với mode=RESCAN                              │
└────────────────────────────┬────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────┐
│  ExamAttendanceService.processRecognitionResults(RESCAN)    │
│                                                             │
│  KEY DIFFERENCE vs Regular:                                 │
│  - ABSENT + detected → Override to PRESENT (late arrival)   │
│  - PRESENT + not detected → Keep PRESENT (exam finished)    │
│                                                             │
│  After RESCAN stops:                                        │
│  - applyRescanReviewFlags() clears needsReview              │
└─────────────────────────────────────────────────────────────┘
```

### 5.5. Manual Status Update

```
┌─────────────────────────────────────────────────────────────┐
│  Supervisor manual update                                   │
│  PUT /api/v1/exam-attendance/{id}                           │
│  Body: { status: "present", remark: "Late with approval" }  │
└────────────────────────────┬────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────┐
│  ExamAttendanceService.updateStatus()                       │
│  Validations:                                               │
│    1. Slot is active                                        │
│    2. Current user is assigned supervisor                   │
│    3. Edit window: slot start → 23:59:59 slot date          │
│  Update:                                                    │
│    - Set new status                                         │
│    - Set method = MANUAL                                    │
│    - Set remark (inline)                                    │
└─────────────────────────────────────────────────────────────┘
```

---

## 6. Business Rules

### 6.1. Slot Constraints

| Rule                   | Description                                            |
| ---------------------- | ------------------------------------------------------ |
| Subject Assignment     | Subject phải được gán trước khi thêm participants      |
| Slot Category          | Chỉ FINAL_EXAM và LECTURE_WITH_PT hỗ trợ exam features |
| One Record Per Student | Mỗi student chỉ có 1 ExamAttendance record cho 1 slot  |
| Multi-Subject          | Student có thể thi nhiều môn trong cùng 1 slot         |

### 6.2. Participant Constraints

| Rule                   | Description                                               |
| ---------------------- | --------------------------------------------------------- |
| Enrollment Required    | Student phải enrolled trong subject để tham gia exam      |
| Unique Per Subject     | Student chỉ được đăng ký 1 lần cho mỗi subject trong slot |
| Soft Delete            | Xóa participant chỉ set `isEnrolled = false`              |
| Auto Create Attendance | Thêm participant tự động tạo ExamAttendance (NOT_YET)     |

### 6.3. Attendance Status Flow

```
Initial State: NOT_YET (khi participant được thêm)

┌──────────┐                    ┌──────────┐
│ NOT_YET  │───── Auto/Manual ──▶│ PRESENT  │
│          │                    │          │
└──────────┘                    └──────────┘
     │                               ▲
     │ Finalize (session stop)       │ RESCAN (late arrival)
     ▼                               │
┌──────────┐                         │
│  ABSENT  │────────────────────────-┘
│          │
└──────────┘
```

**Status Transitions:**

- `NOT_YET → PRESENT`: Auto detection hoặc manual
- `NOT_YET → ABSENT`: Session finalize (không detected)
- `ABSENT → PRESENT`: RESCAN mode (late arrival - **exam specific**)
- `PRESENT → ABSENT`: Manual only (by supervisor)

### 6.4. Edit Window

```
┌─────────────────────────────────────────────────────────────┐
│  Edit Window: slot.startTime → 23:59:59 (slot date, VN TZ)  │
│                                                             │
│  Before slot start: Cannot edit                             │
│  During slot: Supervisor/Data Operator can edit             │
│  After 23:59:59: Only Data Operator can edit                │
└─────────────────────────────────────────────────────────────┘
```

### 6.5. Permission Matrix

| Action              | DATA_OPERATOR | SUPERVISOR    | LECTURER |
| ------------------- | ------------- | ------------- | -------- |
| Assign subjects     | ✅            | ❌            | ❌       |
| Add participants    | ✅            | ❌            | ❌       |
| Import participants | ✅            | ❌            | ❌       |
| Start exam session  | ✅            | ✅ (assigned) | ❌       |
| Update attendance   | ✅            | ✅ (assigned) | ❌       |
| View attendance     | ✅            | ✅            | ❌       |
| Export reports      | ✅            | ✅            | ❌       |

---

## 7. Hướng Dẫn Phát Triển

### 7.1. Thêm Field vào ExamAttendance

1. **Database**: Add column to `exam_attendance` table
2. **Entity**: Add field to `ExamAttendance.java`
3. **DTO**: Add to `ExamAttendanceDTO.java`
4. **Mapper**: Update `ExamAttendanceMapper` if using MapStruct
5. **Frontend**: Add to `examAttendanceRecordSchema` in zod-schemas.ts

### 7.2. Thêm API Endpoint

**Backend:**

```java
// ExamSlotController.java
@GetMapping("/{slotId}/new-feature")
@PreAuthorize("hasPermission(null,'SLOT_READ')")
public Response<NewFeatureDTO> newFeature(@PathVariable Integer slotId) {
    return Response.ok(examSlotService.newFeature(slotId));
}
```

**Frontend:**

```typescript
// useExamSlotNewFeature.ts
export const useExamSlotNewFeature = (slotId: number) => {
  return useQuery({
    queryKey: ["examSlots", slotId, "new-feature"],
    queryFn: async () => {
      const response = await api.get(`/exam-slots/${slotId}/new-feature`);
      return newFeatureSchema.parse(response);
    },
  });
};
```

### 7.3. Modify RESCAN Logic

**File:** `ExamAttendanceService.java`

```java
// processRecognitionResults() method
// Modify the RESCAN condition:
if (currentStatus == AttendanceStatus.ABSENT) {
    // Current: Override to PRESENT (late arrival)
    // To change behavior, modify this block
}
```

### 7.4. Thêm Supervisor Component

1. Create component in `components/supervisor/slots/`
2. Add translations to `messages/en.json` and `messages/vi.json`
3. Use existing hooks (`useExamSlotSubjects`, `useExamAttendance`)
4. Follow existing patterns (Dialog, DataTable, etc.)

### 7.5. Testing Checklist

- [ ] Assign subjects to exam slot
- [ ] Import participants CSV
- [ ] Start/Stop exam session
- [ ] Face recognition callback processing
- [ ] RESCAN mode late arrival override
- [ ] Manual attendance update
- [ ] Edit window validation
- [ ] Permission checks (Supervisor vs Data Operator)
- [ ] SSE real-time updates
- [ ] Export attendance report

---

## Appendix: API Reference

### ExamSlotController Endpoints

```
POST   /api/v1/exam-slots/{slotId}/subjects
GET    /api/v1/exam-slots/{slotId}/subjects
DELETE /api/v1/exam-slots/{slotId}/subjects/{subjectId}
POST   /api/v1/exam-slots/{slotId}/participants
GET    /api/v1/exam-slots/{slotId}/participants
GET    /api/v1/exam-slots/{slotId}/all-participants
GET    /api/v1/exam-slots/{slotId}/participants/{participantId}
PUT    /api/v1/exam-slots/{slotId}/participants/{participantId}
DELETE /api/v1/exam-slots/{slotId}/participants/{participantId}
GET    /api/v1/exam-slots/{slotId}/attendance-report
```

### ExamAttendanceController Endpoints

```
GET    /api/v1/exam-attendance
GET    /api/v1/exam-attendance/{id}
PUT    /api/v1/exam-attendance/{id}
```

### Exam Session Endpoints (via SlotSessionController)

```
POST   /api/v1/slot-session/{slotId}/start-exam
POST   /api/v1/slot-session/{slotId}/stop-exam
POST   /api/v1/slot-session/{slotId}/rescan-exam
GET    /api/v1/slot-session/{slotId}/exam-status
```

### Import Endpoints

```
POST   /api/v1/exam-slot-participants/import
       Content-Type: multipart/form-data
       file: CSV file
       mode: AddOnly | AddAndUpdate
```
