# Slot Module - Tài Liệu Kỹ Thuật

> **Mục đích tài liệu**: Giúp người đọc hiểu và làm việc với module Slot trong hệ thống FUACS - Hệ thống Điểm danh Tự động sử dụng Nhận diện Khuôn mặt.

## Mục Lục

1. [Giới Thiệu Module](#1-giới-thiệu-module)
2. [Kiến Trúc Hệ Thống](#2-kiến-trúc-hệ-thống)
3. [Backend Implementation](#3-backend-implementation)
4. [Frontend Implementation](#4-frontend-implementation)
5. [Luồng Xử Lý Nghiệp Vụ](#5-luồng-xử-lý-nghiệp-vụ)
6. [Business Rules & Validation](#6-business-rules--validation)
7. [Hướng Dẫn Phát Triển](#7-hướng-dẫn-phát-triển)

---

## 1. Giới Thiệu Module

### 1.1 Slot là gì?

**Slot** đại diện cho một **buổi học hoặc buổi thi** trong hệ thống FUACS. Mỗi slot có thời gian bắt đầu, kết thúc, được gán cho một phòng cụ thể và một giảng viên/giám thị phụ trách.

Slot là **đơn vị cơ bản để điểm danh** - tất cả attendance records (điểm danh thường) và exam attendance (điểm danh thi) đều được ghi nhận theo từng slot.

### 1.2 Ba Loại Slot (SlotCategory)

| Loại                | Mô tả                                            | Điểm danh                                   |
| ------------------- | ------------------------------------------------ | ------------------------------------------- |
| **LECTURE**         | Buổi học lý thuyết thông thường                  | Chỉ có điểm danh thường (Regular)           |
| **LECTURE_WITH_PT** | Buổi học có bài kiểm tra tiến độ (Progress Test) | Có CẢ HAI: điểm danh thường + điểm danh thi |
| **FINAL_EXAM**      | Buổi thi cuối kỳ                                 | Chỉ có điểm danh thi (Exam)                 |

**Lưu ý quan trọng:**

- `LECTURE` và `LECTURE_WITH_PT` **bắt buộc** phải có `classId` (thuộc một lớp học cụ thể)
- `FINAL_EXAM` **không có** `classId`, thay vào đó gán các môn học (subjects) riêng biệt

### 1.3 Vai trò trong Hệ thống Điểm danh

| Vai trò               | Mô tả                                                               |
| --------------------- | ------------------------------------------------------------------- |
| **Container**         | Chứa tất cả thông tin về buổi học/thi: thời gian, phòng, giảng viên |
| **Session Manager**   | Quản lý phiên nhận diện khuôn mặt (start/stop/rescan)               |
| **Attendance Anchor** | Điểm neo cho tất cả bản ghi điểm danh                               |
| **Access Control**    | Phân quyền theo role (Admin, Lecturer, Supervisor)                  |

### 1.4 Mối Quan Hệ với Các Module Khác

```
                          ┌─────────────────┐
                          │    SEMESTER     │
                          │   (Học kỳ)      │
                          └────────┬────────┘
                                   │ 1:N
                                   ▼
┌─────────────────┐       ┌─────────────────┐       ┌─────────────────┐
│  ACADEMIC_CLASS │◄──────│      SLOT       │──────►│      ROOM       │
│  (Lớp học)      │  N:1  │  (Buổi học/thi) │  N:1  │   (Phòng)       │
│  (cho LECTURE)  │       │                 │       │                 │
└─────────────────┘       └────────┬────────┘       └────────┬────────┘
                                   │                         │
                     ┌─────────────┼─────────────┐          │
                     │             │             │          │
                     ▼             ▼             ▼          ▼
            ┌────────────┐ ┌────────────┐ ┌────────────┐ ┌────────────┐
            │   STAFF    │ │ ATTENDANCE │ │   EXAM     │ │   CAMERA   │
            │ (Giảng     │ │  RECORD    │ │ ATTENDANCE │ │ (Nhận      │
            │  viên/GS)  │ │ (Điểm danh │ │ (Điểm danh │ │  diện)     │
            │            │ │  thường)   │ │  thi)      │ │            │
            └────────────┘ └────────────┘ └────────────┘ └────────────┘
```

**Giải thích quan hệ:**

- **Semester → Slot**: 1:N - Một học kỳ có nhiều slots
- **AcademicClass → Slot**: 1:N - Một lớp có nhiều buổi học (chỉ LECTURE/LECTURE_WITH_PT)
- **Room → Slot**: 1:N - Một phòng được dùng cho nhiều slots
- **Staff → Slot**: 1:N - Một giảng viên phụ trách nhiều slots
- **Slot → AttendanceRecord**: 1:N - Mỗi slot có nhiều bản ghi điểm danh thường
- **Slot → ExamAttendance**: 1:N - Mỗi slot có nhiều bản ghi điểm danh thi

### 1.5 Dual Session Architecture

Slot entity có **hai bộ session fields riêng biệt** để quản lý hai loại điểm danh:

```
┌─────────────────────────────────────────────────────────────┐
│                         SLOT                                │
├─────────────────────────────┬───────────────────────────────┤
│   REGULAR SESSION           │   EXAM SESSION                │
│   (Điểm danh thường)        │   (Điểm danh thi)             │
├─────────────────────────────┼───────────────────────────────┤
│ sessionStatus               │ examSessionStatus             │
│ scanCount                   │ examScanCount                 │
│ lastSessionStoppedAt        │ lastExamSessionStoppedAt      │
├─────────────────────────────┼───────────────────────────────┤
│ → attendance_records table  │ → exam_attendance table       │
└─────────────────────────────┴───────────────────────────────┘
```

**Khi nào sử dụng session nào?**

- `LECTURE`: Chỉ dùng Regular Session
- `LECTURE_WITH_PT`: Dùng CẢ HAI (học + bài kiểm tra)
- `FINAL_EXAM`: Chỉ dùng Exam Session

---

## 2. Kiến Trúc Hệ Thống

### 2.1 Tổng Quan Kiến Trúc

```
┌─────────────────────────────────────────────────────────────────────┐
│                         FRONTEND (Next.js)                          │
│  ┌─────────────────────────────────────────────────────────────────┐│
│  │                    3 PORTAL VIEWS                               ││
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────┐  ││
│  │  │    ADMIN     │  │   LECTURER   │  │     SUPERVISOR       │  ││
│  │  │ /admin/slots │  │/lecturer/    │  │ /supervisor/slots    │  ││
│  │  │              │  │  slots       │  │ /supervisor/reports/ │  ││
│  │  │  LECTURE     │  │              │  │  slots               │  ││
│  │  │  LECTURE_    │  │  Own slots   │  │                      │  ││
│  │  │  WITH_PT     │  │  only        │  │  FINAL_EXAM only     │  ││
│  │  └──────────────┘  └──────────────┘  └──────────────────────┘  ││
│  └─────────────────────────────────────────────────────────────────┘│
│                              │ REST API + SSE                       │
└──────────────────────────────┼──────────────────────────────────────┘
                               │
┌──────────────────────────────┼──────────────────────────────────────┐
│                         BACKEND (Spring Boot)                       │
│  ┌────────────────────────────────────────────────────────────────┐ │
│  │                      CONTROLLERS                                │ │
│  │  SlotController │ ExamSlotController │ AttendanceControllers   │ │
│  └────────────────────────────┬───────────────────────────────────┘ │
│                               ▼                                      │
│  ┌────────────────────────────────────────────────────────────────┐ │
│  │                        SERVICES                                 │ │
│  │  SlotService │ ExamSlotService │ SlotSessionService │ ...      │ │
│  └────────────────────────────┬───────────────────────────────────┘ │
│                               │                                      │
│  ┌────────────────────────────┼───────────────────────────────────┐ │
│  │ SseHub (Real-time)         │         PythonBackendClient       │ │
│  └────────────────────────────┼───────────────────────────────────┘ │
└───────────────────────────────┼─────────────────────────────────────┘
                                │
          ┌─────────────────────┴─────────────────────┐
          ▼                                           ▼
┌─────────────────────┐                   ┌─────────────────────┐
│    PostgreSQL       │                   │  Python Recognition │
│    - slots          │                   │  Service            │
│    - attendance_    │◄──────────────────│  - Face detection   │
│      records        │    callbacks      │  - RTSP streaming   │
│    - exam_          │                   │  - Evidence images  │
│      attendance     │                   │                     │
└─────────────────────┘                   └─────────────────────┘
```

### 2.2 Cấu Trúc Thư Mục

**Backend:**

```
backend/src/main/java/com/fuacs/backend/
├── entity/
│   ├── Slot.java                      # Core entity
│   ├── AttendanceRecord.java          # Regular attendance
│   ├── ExamAttendance.java            # Exam attendance
│   ├── ExamSlotSubject.java           # Junction: Slot → Subject
│   └── ExamSlotParticipant.java       # Junction: ExamSlotSubject → Student
├── dto/
│   ├── request/
│   │   ├── SlotCreateRequest.java
│   │   ├── SlotUpdateRequest.java
│   │   ├── SlotSearchRequest.java
│   │   └── SlotCategoryUpdateRequest.java
│   └── response/
│       ├── SlotDTO.java
│       └── SessionStatusResponse.java
├── repository/
│   ├── SlotRepository.java
│   ├── AttendanceRecordRepository.java
│   └── ExamAttendanceRepository.java
├── service/
│   ├── SlotService.java               # CRUD + import
│   ├── ExamSlotService.java           # Exam-specific logic
│   ├── SlotSessionService.java        # Face recognition sessions
│   ├── AttendanceRecordService.java   # Regular attendance
│   └── ExamAttendanceService.java     # Exam attendance
├── controller/
│   ├── SlotController.java            # Main slot endpoints
│   ├── ExamSlotController.java        # Exam slot endpoints
│   ├── AttendanceRecordController.java
│   ├── ExamAttendanceController.java
│   └── SlotSseController.java         # Real-time events
└── realtime/
    └── SseHub.java                    # SSE broadcasting
```

**Frontend:**

```
frontend-web/
├── app/
│   ├── admin/slots/
│   │   ├── page.tsx                   # Admin slot management
│   │   └── [id]/roster/page.tsx       # Attendance roster
│   ├── lecturer/slots/
│   │   ├── page.tsx                   # Lecturer's slots
│   │   └── [id]/roster/page.tsx
│   └── supervisor/
│       ├── slots/page.tsx             # Exam slots (FINAL_EXAM)
│       └── reports/slots/page.tsx     # Exam reports
├── components/
│   ├── admin/slots/
│   │   ├── slot-table.tsx
│   │   ├── slot-form-dialog.tsx
│   │   ├── slot-roster-table.tsx
│   │   └── exam-session-controls.tsx
│   ├── lecturer/slots/
│   │   └── lecturer-slot-*.tsx
│   └── supervisor/slots/
│       ├── supervisor-slot-table.tsx
│       └── supervisor-exam-detail-dialog.tsx
├── hooks/
│   ├── api/
│   │   ├── useSlots.ts
│   │   ├── useSlotRoster.ts
│   │   ├── useSlotSession.ts
│   │   └── useExamSlot*.ts
│   └── realtime/
│       └── useSlotRosterSSE.ts        # Real-time attendance updates
└── types/
    └── index.ts                       # Slot, Attendance types
```

---

## 3. Backend Implementation

### 3.1 Database Schema

**Bảng `slots`:**

```sql
CREATE TABLE slots (
    id SERIAL PRIMARY KEY,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,

    -- Core fields
    title VARCHAR(255),
    description TEXT,
    start_time TIMESTAMP NOT NULL,
    end_time TIMESTAMP NOT NULL,
    slot_category VARCHAR(20) NOT NULL
        CHECK (slot_category IN ('LECTURE', 'LECTURE_WITH_PT', 'FINAL_EXAM')),

    -- Relationships
    class_id SMALLINT,                           -- NULL for FINAL_EXAM
    semester_id SMALLINT NOT NULL,
    room_id SMALLINT NOT NULL,
    staff_user_id INTEGER NOT NULL,

    -- Regular Session Fields
    session_status VARCHAR(20) NOT NULL DEFAULT 'NOT_STARTED'
        CHECK (session_status IN ('NOT_STARTED', 'RUNNING', 'STOPPED')),
    scan_count INTEGER NOT NULL DEFAULT 0,
    last_session_stopped_at TIMESTAMP,

    -- Exam Session Fields
    exam_session_status VARCHAR(20) NOT NULL DEFAULT 'NOT_STARTED'
        CHECK (exam_session_status IN ('NOT_STARTED', 'RUNNING', 'STOPPED')),
    exam_scan_count INTEGER NOT NULL DEFAULT 0,
    last_exam_session_stopped_at TIMESTAMP,

    -- Foreign Keys
    FOREIGN KEY (class_id) REFERENCES classes(id),
    FOREIGN KEY (semester_id) REFERENCES semesters(id),
    FOREIGN KEY (room_id) REFERENCES rooms(id),
    FOREIGN KEY (staff_user_id) REFERENCES users(id)
);

-- Indexes cho performance
CREATE INDEX idx_slots_class_id ON slots(class_id);
CREATE INDEX idx_slots_semester_id ON slots(semester_id);
CREATE INDEX idx_slots_staff_user_id ON slots(staff_user_id);
CREATE INDEX idx_slots_room_id ON slots(room_id);
CREATE INDEX idx_slots_start_time ON slots(start_time);
CREATE INDEX idx_slots_session_status ON slots(session_status);
```

**Sơ đồ ER:**

```
┌─────────────┐           ┌──────────────────┐           ┌─────────────┐
│  classes    │           │      slots       │           │    rooms    │
├─────────────┤           ├──────────────────┤           ├─────────────┤
│ id (PK)     │◄─────────┤│ class_id (FK)    │           │ id (PK)     │
│ code        │    1:N    │ id (PK)          │───────────►│ name        │
│ subject_id  │           │ title            │    N:1    │ location    │
│ semester_id │           │ start_time       │           └─────────────┘
└─────────────┘           │ end_time         │
                          │ slot_category    │           ┌─────────────┐
┌─────────────┐           │ semester_id (FK) │───────────►│ semesters   │
│   users     │           │ room_id (FK)     │    N:1    ├─────────────┤
├─────────────┤           │ staff_user_id FK │           │ id (PK)     │
│ id (PK)     │◄─────────┤│                  │           │ name        │
│ full_name   │    1:N    │ session_status   │           │ code        │
│ username    │           │ scan_count       │           └─────────────┘
└─────────────┘           │ exam_session_... │
                          │ is_active        │
                          └──────────────────┘
```

### 3.2 Entity Class

**Slot.java:**

```java
@Entity
@Table(name = "slots", indexes = {
    @Index(name = "idx_slots_class_id", columnList = "class_id"),
    @Index(name = "idx_slots_semester_id", columnList = "semester_id"),
    @Index(name = "idx_slots_staff_user_id", columnList = "staff_user_id"),
    @Index(name = "idx_slots_room_id", columnList = "room_id"),
    @Index(name = "idx_slots_start_time", columnList = "start_time"),
})
public class Slot extends BaseEntity {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @Column(name = "title", length = 255)
    private String title;

    @Column(name = "description", columnDefinition = "TEXT")
    private String description;

    @Enumerated(EnumType.STRING)
    @Column(name = "slot_category", nullable = false, length = 20)
    private SlotCategory slotCategory;

    @Column(name = "start_time", nullable = false)
    private LocalDateTime startTime;

    @Column(name = "end_time", nullable = false)
    private LocalDateTime endTime;

    // === RELATIONSHIPS ===

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "class_id")
    private AcademicClass academicClass;  // NULL for FINAL_EXAM

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "semester_id", nullable = false)
    private Semester semester;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "room_id", nullable = false)
    private Room room;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "staff_user_id", nullable = false)
    private User staff;  // Giảng viên hoặc giám thị

    // === REGULAR SESSION FIELDS ===

    @Enumerated(EnumType.STRING)
    @Column(name = "session_status", nullable = false, length = 20)
    private SessionStatus sessionStatus = SessionStatus.NOT_STARTED;

    @Column(name = "scan_count", nullable = false)
    private Integer scanCount = 0;

    @Column(name = "last_session_stopped_at")
    private Instant lastSessionStoppedAt;

    // === EXAM SESSION FIELDS ===

    @Enumerated(EnumType.STRING)
    @Column(name = "exam_session_status", nullable = false, length = 20)
    private SessionStatus examSessionStatus = SessionStatus.NOT_STARTED;

    @Column(name = "exam_scan_count", nullable = false)
    private Integer examScanCount = 0;

    @Column(name = "last_exam_session_stopped_at")
    private Instant lastExamSessionStoppedAt;

    // === COLLECTIONS ===

    @OneToMany(mappedBy = "slot", fetch = FetchType.LAZY)
    private Set<AttendanceRecord> attendanceRecords;

    @OneToMany(mappedBy = "slot", fetch = FetchType.LAZY)
    private Set<ExamAttendance> examAttendances;
}
```

**Enums:**

```java
public enum SlotCategory {
    LECTURE,           // Buổi học thường
    LECTURE_WITH_PT,   // Buổi học có Progress Test
    FINAL_EXAM         // Buổi thi cuối kỳ
}

public enum SessionStatus {
    NOT_STARTED,   // Chưa bắt đầu
    RUNNING,       // Đang chạy nhận diện
    STOPPED        // Đã dừng
}

public enum AttendanceStatus {
    PRESENT("present"),      // Có mặt
    ABSENT("absent"),        // Vắng mặt
    NOT_YET("not_yet")       // Chưa điểm danh
}

public enum AttendanceMethod {
    AUTO("auto"),                      // Tự động (face recognition)
    MANUAL("manual"),                  // Thủ công
    SYSTEM_FINALIZE("system_finalize") // Hệ thống tự động khi hết giờ
}
```

### 3.3 REST API Endpoints

**Base URL:** `/api/v1/slots`

**SlotController - Endpoints chính:**

| Method | Endpoint         | Permission                                  | Mô tả                                     |
| ------ | ---------------- | ------------------------------------------- | ----------------------------------------- |
| GET    | `/`              | `SLOT_READ`                                 | Danh sách slots với pagination và filters |
| GET    | `/{id}`          | `SLOT_READ`                                 | Chi tiết một slot                         |
| POST   | `/`              | `SLOT_CREATE` hoặc `SLOT_CREATE_FINAL_EXAM` | Tạo slot mới                              |
| PUT    | `/{id}`          | `SLOT_UPDATE` hoặc `SLOT_UPDATE_FINAL_EXAM` | Cập nhật slot                             |
| DELETE | `/{id}`          | `SLOT_DELETE_HARD`                          | Xóa slot                                  |
| PUT    | `/{id}/category` | `SLOT_UPDATE_CATEGORY`                      | Cập nhật loại slot (Lecturer)             |
| POST   | `/import`        | `SLOT_IMPORT`                               | Import LECTURE/LECTURE_WITH_PT từ CSV     |
| POST   | `/import-exams`  | `SLOT_IMPORT`                               | Import FINAL_EXAM từ CSV                  |

**Session Management Endpoints:**

| Method | Endpoint                   | Permission              | Mô tả                       |
| ------ | -------------------------- | ----------------------- | --------------------------- |
| POST   | `/{id}/start-session`      | `SLOT_SESSION_START`    | Bắt đầu nhận diện (Regular) |
| POST   | `/{id}/stop-session`       | `SLOT_SESSION_FINALIZE` | Dừng nhận diện (Regular)    |
| POST   | `/{id}/rescan`             | `SLOT_SESSION_RESCAN`   | Quét lại (Regular)          |
| POST   | `/{id}/start-exam-session` | `SLOT_SESSION_START`    | Bắt đầu nhận diện (Exam)    |
| POST   | `/{id}/stop-exam-session`  | `SLOT_SESSION_FINALIZE` | Dừng nhận diện (Exam)       |
| POST   | `/{id}/rescan-exam`        | `SLOT_SESSION_RESCAN`   | Quét lại (Exam)             |

**Attendance Endpoints:**

| Method | Endpoint                       | Permission                        | Mô tả                            |
| ------ | ------------------------------ | --------------------------------- | -------------------------------- |
| GET    | `/{id}/roster`                 | `ATTENDANCE_ROSTER_READ`          | Danh sách sinh viên + attendance |
| POST   | `/{id}/submit-attendance`      | `ATTENDANCE_STATUS_UPDATE_MANUAL` | Submit điểm danh batch           |
| GET    | `/{id}/has-attendance-records` | `SLOT_READ`                       | Check có records chưa            |

### 3.4 Request/Response DTOs

**SlotCreateRequest:**

```java
public class SlotCreateRequest {
    @Size(max = 255)
    private String title;                          // Optional, auto-generate nếu null

    @Size(max = 1000)
    private String description;                    // Optional

    @NotNull(message = "Start time is required")
    private LocalDateTime startTime;

    @NotNull(message = "End time is required")
    private LocalDateTime endTime;

    @NotNull(message = "Slot category is required")
    private SlotCategory slotCategory;

    private Short classId;                         // Required for LECTURE/LECTURE_WITH_PT

    @NotNull(message = "Semester is required")
    private Short semesterId;

    @NotNull(message = "Room is required")
    private Short roomId;

    @NotNull(message = "Staff is required")
    private Integer staffUserId;

    private List<Short> subjectIds;                // For FINAL_EXAM only
}
```

**SlotSearchRequest:**

```java
public class SlotSearchRequest extends PagedRequest {
    private List<SlotCategory> slotCategory;       // Multi-select filter
    private Short classId;
    private Short subjectId;
    private Integer staffUserId;
    private Integer studentUserId;
    private Short roomId;
    private Short semesterId;
    private LocalDate startTimeFrom;
    private LocalDate startTimeTo;
}
```

**SlotDTO (Response):**

```java
public class SlotDTO extends BaseDTO {
    private Integer id;
    private String title;
    private String description;
    private String startTime;
    private String endTime;
    private SlotCategory slotCategory;

    // Nested objects
    private ClassDTO class;                        // null for FINAL_EXAM
    private List<SubjectDTO> subjects;             // For FINAL_EXAM only
    private SemesterDTO semester;
    private RoomDTO room;
    private UserDTO staffUser;

    // Attendance statistics (computed)
    private Integer totalStudent;
    private Integer totalPresentStudent;
    private Integer totalAbsentStudent;
    private Integer totalNotYetStudent;

    // Session status
    private SessionStatus sessionStatus;
    private Integer scanCount;
    private Instant lastSessionStoppedAt;
    private SessionStatus examSessionStatus;
    private Integer examScanCount;
    private Instant lastExamSessionStoppedAt;

    // Student-specific (optional)
    private AttendanceStatus studentAttendanceStatus;
}
```

### 3.5 Service Layer

**SlotService - Các phương thức chính:**

| Phương thức                      | Input                              | Output                  | Mô tả                                 |
| -------------------------------- | ---------------------------------- | ----------------------- | ------------------------------------- |
| `findAll(request)`               | SlotSearchRequest                  | PagingResponse<SlotDTO> | Search với filters + attendance stats |
| `findById(id)`                   | Integer                            | SlotDTO                 | Chi tiết slot                         |
| `create(request)`                | SlotCreateRequest                  | SlotDTO                 | Tạo mới + validate                    |
| `update(id, request)`            | Integer, SlotUpdateRequest         | SlotDTO                 | Cập nhật                              |
| `delete(id)`                     | Integer                            | void                    | Xóa (nếu chưa có attendance)          |
| `updateCategory(id, request)`    | Integer, SlotCategoryUpdateRequest | SlotDTO                 | Chỉ đổi category                      |
| `importFromCsv(file, mode)`      | MultipartFile, ImportMode          | ImportResultDTO         | Import regular slots                  |
| `importExamsFromCsv(file, mode)` | MultipartFile, ImportMode          | ImportResultDTO         | Import exam slots                     |

**Validation Logic:**

```java
// Time validation
if (endTime <= startTime) throw BAD_REQUEST("INVALID_TIME_RANGE");
if (duration < 30 minutes || duration > 4 hours) throw BAD_REQUEST("INVALID_SLOT_DURATION");
if (startTime outside semester date range) throw BAD_REQUEST("SLOT_OUTSIDE_SEMESTER_RANGE");

// Category-specific validation
if (category == FINAL_EXAM && classId != null) throw BAD_REQUEST("FINAL_EXAM_CANNOT_HAVE_CLASS");
if (category != FINAL_EXAM && classId == null) throw BAD_REQUEST("CLASS_REQUIRED_FOR_LECTURE");

// Conflict detection
if (room has overlapping slot) throw BAD_REQUEST("ROOM_TIME_CONFLICT");
if (staff has overlapping slot) throw BAD_REQUEST("STAFF_TIME_CONFLICT");
```

---

## 4. Frontend Implementation

### 4.1 Route Overview - 3 Portals

**Admin Portal (`/admin/slots`):**

- **Role**: DATA_OPERATOR
- **Slot Types**: LECTURE, LECTURE_WITH_PT
- **Actions**: Create, Edit, Delete, Import CSV
- **Features**: Full CRUD, semester filter required

**Lecturer Portal (`/lecturer/slots`):**

- **Role**: LECTURER
- **Slot Types**: LECTURE, LECTURE_WITH_PT (own slots only)
- **Actions**: View, Update Category only
- **Features**: Read-only except category change

**Supervisor Portal (`/supervisor/slots`):**

- **Role**: SUPERVISOR
- **Slot Types**: FINAL_EXAM only
- **Actions**: View, Manage Attendance
- **Features**: Exam detail dialog, attendance management

### 4.2 Component Structure

**Admin Slots Page:**

```
SlotsContent
├── Filters
│   ├── Semester Select (required)
│   ├── Class Filter (popover)
│   ├── Subject Filter (popover)
│   ├── Room Filter (popover)
│   ├── Staff Filter (popover)
│   ├── Date Range (calendar)
│   └── Sort Controls
├── Action Buttons
│   ├── Import CSV
│   └── Create Slot
├── SlotTable
│   ├── Columns: Title | Time | Category | Class | Room | Staff | Status | Actions
│   └── Row Actions: Edit | Delete | View Roster
├── SlotFormDialog (Create/Edit)
├── DeleteSlotDialog
└── SlotPagination
```

**Supervisor Exam Detail Dialog:**

```
SupervisorExamDetailDialog
├── Slot Info Card
│   ├── Title, Time, Room
│   └── Staff info
├── Statistics
│   ├── Total Students
│   ├── Present Count
│   ├── Absent Count
│   └── Pending Count
├── Subjects List (for FINAL_EXAM)
├── Students List with Attendance Status
└── Manage Attendance Button
```

### 4.3 React Query Hooks

**File:** `hooks/api/useSlots.ts`

| Hook                            | Type     | Mô tả                          |
| ------------------------------- | -------- | ------------------------------ |
| `useGetSlots(params)`           | Query    | Danh sách slots với pagination |
| `useGetSlot(id)`                | Query    | Chi tiết một slot              |
| `useCreateSlot()`               | Mutation | Tạo slot mới                   |
| `useUpdateSlot()`               | Mutation | Cập nhật slot                  |
| `useUpdateSlotCategory()`       | Mutation | Cập nhật category (Lecturer)   |
| `useDeleteSlot()`               | Mutation | Xóa slot                       |
| `useImportSlots()`              | Mutation | Import regular slots           |
| `useImportExamSlots()`          | Mutation | Import exam slots              |
| `useCheckSlotHasAttendance(id)` | Query    | Check có attendance records    |

**Query Keys:**

```typescript
QUERY_KEYS.slots = {
  all: ["slots"],
  detail: (id: number) => ["slots", id],
  roster: (id: number) => ["slots", id, "roster"],
  hasAttendance: (id: number) => ["slots", id, "hasAttendance"],
};
```

### 4.4 TypeScript Types

```typescript
interface Slot {
  id: number;
  title: string | null;
  description: string | null;
  startTime: string;
  endTime: string;
  slotCategory: "LECTURE" | "LECTURE_WITH_PT" | "FINAL_EXAM";

  room: { id: number; name: string; location: string | null };
  staffUser?: { id: number; fullName: string; username: string };
  semester?: { id: number; name: string; code: string };
  class?: {
    id: number;
    code: string;
    subject: { id: number; name: string; code: string };
    semester: { id: number; name: string; code: string };
  } | null;
  subjects?: Array<{ id: number; name: string; code: string }>;

  // Statistics
  totalStudent: number;
  totalPresentStudent: number;
  totalAbsentStudent: number;
  totalNotYetStudent: number;

  // Session status
  sessionStatus: "NOT_STARTED" | "RUNNING" | "STOPPED";
  scanCount: number;
  lastSessionStoppedAt?: string;
  examSessionStatus: "NOT_STARTED" | "RUNNING" | "STOPPED";
  examScanCount: number;
  lastExamSessionStoppedAt?: string;

  isActive: boolean;
  createdAt: string;
  updatedAt: string;
}

interface SlotQueryParams {
  page?: number;
  pageSize?: number;
  sort?: "asc" | "desc";
  sortBy?: "startTime" | "endTime" | "slotCategory";
  slotCategory?: ("LECTURE" | "LECTURE_WITH_PT" | "FINAL_EXAM")[];
  classId?: number;
  subjectId?: number;
  staffUserId?: number;
  roomId?: number;
  semesterId?: number;
  startTimeFrom?: string;
  startTimeTo?: string;
  isActive?: boolean;
}
```

### 4.5 Zod Validation Schema

```typescript
export const slotSchema = z.object({
  id: z.number(),
  title: z.string().nullish(),
  description: z.string().nullish(),
  startTime: z.string(),
  endTime: z.string(),
  slotCategory: z.enum(["LECTURE", "LECTURE_WITH_PT", "FINAL_EXAM"]),
  room: z.object({
    id: z.number(),
    name: z.string(),
    location: z.string().nullable(),
  }),
  staffUser: z.object({
    id: z.number(),
    username: z.string(),
    fullName: z.string(),
  }).nullable().optional(),
  semester: z.object({
    id: z.number(),
    name: z.string(),
    code: z.string(),
  }).nullable().optional(),
  class: z.object({
    id: z.number(),
    code: z.string(),
    subject: z.object({...}),
    semester: z.object({...}),
  }).nullable().optional(),
  subjects: z.array(z.object({
    id: z.number(),
    name: z.string(),
    code: z.string(),
  })).optional(),

  // Statistics with default 0
  totalStudent: z.number().nullish().transform(v => v ?? 0),
  totalPresentStudent: z.number().nullish().transform(v => v ?? 0),
  totalAbsentStudent: z.number().nullish().transform(v => v ?? 0),
  totalNotYetStudent: z.number().nullish().transform(v => v ?? 0),

  // Session status with defaults
  sessionStatus: z.enum(["NOT_STARTED", "RUNNING", "STOPPED"]).default("NOT_STARTED"),
  scanCount: z.number().default(0),
  examSessionStatus: z.enum(["NOT_STARTED", "RUNNING", "STOPPED"]).default("NOT_STARTED"),
  examScanCount: z.number().default(0),

  isActive: z.boolean(),
  createdAt: z.string(),
  updatedAt: z.string(),
});
```

---

## 5. Luồng Xử Lý Nghiệp Vụ

### 5.1 Luồng Tạo Slot Mới

```
┌──────┐      ┌──────────┐      ┌─────────┐      ┌────────┐
│ User │      │ Frontend │      │ Backend │      │   DB   │
└──┬───┘      └────┬─────┘      └────┬────┘      └────┬───┘
   │               │                 │                │
   │ 1. Fill form  │                 │                │
   │   - title     │                 │                │
   │   - time      │                 │                │
   │   - category  │                 │                │
   │   - class/    │                 │                │
   │     subjects  │                 │                │
   │──────────────>│                 │                │
   │               │                 │                │
   │               │ 2. Validate     │                │
   │               │    (Zod)        │                │
   │               │                 │                │
   │               │ 3. POST /slots  │                │
   │               │────────────────>│                │
   │               │                 │                │
   │               │                 │ 4. Validate:   │
   │               │                 │ - Time range   │
   │               │                 │ - Duration     │
   │               │                 │ - Semester     │
   │               │                 │ - Category     │
   │               │                 │   rules        │
   │               │                 │                │
   │               │                 │ 5. Check       │
   │               │                 │    conflicts   │
   │               │                 │───────────────>│
   │               │                 │<───────────────│
   │               │                 │                │
   │               │                 │ 6. Create slot │
   │               │                 │───────────────>│
   │               │                 │                │
   │               │                 │ 7. Create      │
   │               │                 │    initial     │
   │               │                 │    attendance  │
   │               │                 │    records     │
   │               │                 │───────────────>│
   │               │                 │<───────────────│
   │               │                 │                │
   │               │ 8. Return DTO   │                │
   │               │<────────────────│                │
   │               │                 │                │
   │ 9. Toast +    │                 │                │
   │    Invalidate │                 │                │
   │<──────────────│                 │                │
```

**Lưu ý:** Khi tạo slot, hệ thống tự động tạo `AttendanceRecord` với status `NOT_YET` cho tất cả sinh viên enrolled trong class (nếu LECTURE/LECTURE_WITH_PT).

### 5.2 Luồng Import Slots từ CSV

**CSV Format cho LECTURE/LECTURE_WITH_PT:**

```csv
title,start_time,end_time,slot_category,class_code,semester_code,room_name,staff_username
Lý thuyết PRO192 - Slot 1,2025-01-20T08:00:00,2025-01-20T09:30:00,LECTURE,PRO192-SE1801,FA25,301,lecturer1
```

**CSV Format cho FINAL_EXAM:**

```csv
title,start_time,end_time,slot_category,semester_code,room_name,staff_username,subject_codes
Final Exam PRO192,2025-01-25T08:00:00,2025-01-25T10:00:00,FINAL_EXAM,FA25,Exam Hall 1,supervisor1,PRO192|CSI101
```

```
┌──────┐      ┌──────────┐      ┌─────────┐      ┌────────┐
│ User │      │ Frontend │      │ Backend │      │   DB   │
└──┬───┘      └────┬─────┘      └────┬────┘      └────┬───┘
   │               │                 │                │
   │ 1. Upload CSV │                 │                │
   │    + mode     │                 │                │
   │──────────────>│                 │                │
   │               │                 │                │
   │               │ 2. POST /import │                │
   │               │    multipart    │                │
   │               │────────────────>│                │
   │               │                 │                │
   │               │                 │ 3. Parse CSV   │
   │               │                 │    (UTF-8)     │
   │               │                 │                │
   │               │                 │ 4. Deduplicate │
   │               │                 │    by time +   │
   │               │                 │    room        │
   │               │                 │                │
   │               │                 │ ┌─────────────┐│
   │               │                 │ │ For each row││
   │               │                 │ │ (REQUIRES_  ││
   │               │                 │ │  NEW TX)    ││
   │               │                 │ │             ││
   │               │                 │ │ 5. Validate ││
   │               │                 │ │    + lookup ││
   │               │                 │ │    entities ││
   │               │                 │ │             ││
   │               │                 │ │ 6. Check    ││
   │               │                 │ │    conflicts││
   │               │                 │ │             ││
   │               │                 │ │ 7. Create   ││
   │               │                 │ │    slot     ││
   │               │                 │ │─────────────>│
   │               │                 │ │             ││
   │               │                 │ └─────────────┘│
   │               │                 │                │
   │               │ 8. Return       │                │
   │               │    ImportResult │                │
   │               │<────────────────│                │
   │               │                 │                │
   │ 9. Show       │                 │                │
   │    result     │                 │                │
   │<──────────────│                 │                │
```

---

## 6. Business Rules & Validation

### 6.1 Quy Tắc Validation

| Field         | Rule                                  | Error Code                     |
| ------------- | ------------------------------------- | ------------------------------ |
| `title`       | Max 255 chars, optional               | `TITLE_TOO_LONG`               |
| `description` | Max 1000 chars, optional              | `DESCRIPTION_TOO_LONG`         |
| `startTime`   | Required, format ISO 8601             | `START_TIME_REQUIRED`          |
| `endTime`     | Required, > startTime                 | `INVALID_TIME_RANGE`           |
| Duration      | 30 phút - 4 giờ                       | `INVALID_SLOT_DURATION`        |
| Time range    | Trong phạm vi semester                | `SLOT_OUTSIDE_SEMESTER_RANGE`  |
| `classId`     | Required cho LECTURE/LECTURE_WITH_PT  | `CLASS_REQUIRED_FOR_LECTURE`   |
| `classId`     | NULL cho FINAL_EXAM                   | `FINAL_EXAM_CANNOT_HAVE_CLASS` |
| `semesterId`  | Required, phải active                 | `SEMESTER_NOT_FOUND`           |
| `roomId`      | Required, phải active                 | `ROOM_NOT_FOUND`               |
| `staffUserId` | Required, có LECTURER/SUPERVISOR role | `STAFF_NOT_FOUND`              |

### 6.2 Conflict Detection

**Room Time Conflict:**

```sql
SELECT COUNT(*) FROM slots
WHERE room_id = :roomId
  AND id != :excludeSlotId
  AND is_active = true
  AND (
    (start_time <= :newStart AND end_time > :newStart) OR
    (start_time < :newEnd AND end_time >= :newEnd) OR
    (start_time >= :newStart AND end_time <= :newEnd)
  )
```

**Staff Time Conflict:**

```sql
SELECT COUNT(*) FROM slots
WHERE staff_user_id = :staffId
  AND id != :excludeSlotId
  AND is_active = true
  AND (-- same overlap logic --)
```

### 6.3 Category-Specific Rules

| Rule                  | LECTURE            | LECTURE_WITH_PT | FINAL_EXAM          |
| --------------------- | ------------------ | --------------- | ------------------- |
| `classId`             | Required           | Required        | NOT ALLOWED         |
| `subjects` assignment | N/A                | N/A             | Via ExamSlotSubject |
| Regular Session       | Yes                | Yes             | No                  |
| Exam Session          | No                 | Yes             | Yes                 |
| Attendance Table      | attendance_records | Both tables     | exam_attendance     |
| Delete Check          | No records         | No records      | No participants     |

### 6.4 CSV Import Rules

**Import Modes:**
| Mode | Hành vi |
|------|---------|
| `ADD_ONLY` | Chỉ thêm mới, skip nếu conflict |
| `ADD_AND_UPDATE` | Thêm mới hoặc update existing |

**Constraints:**

- Encoding: UTF-8
- DateTime format: `yyyy-MM-dd'T'HH:mm:ss` (Vietnam timezone, không có 'Z')
- Deduplicate by: `(start_time, room_name)` - keep first row
- Partial success: Mỗi row trong transaction riêng

### 6.5 Error Codes Reference

| Code                           | HTTP | Mô tả                              |
| ------------------------------ | ---- | ---------------------------------- |
| `SLOT_NOT_FOUND`               | 404  | Slot không tồn tại                 |
| `INVALID_TIME_RANGE`           | 400  | End time <= Start time             |
| `INVALID_SLOT_DURATION`        | 400  | Duration < 30m hoặc > 4h           |
| `SLOT_OUTSIDE_SEMESTER_RANGE`  | 400  | Thời gian ngoài semester           |
| `ROOM_TIME_CONFLICT`           | 400  | Phòng đã có slot khác              |
| `STAFF_TIME_CONFLICT`          | 400  | Staff đã có slot khác              |
| `CLASS_REQUIRED_FOR_LECTURE`   | 400  | LECTURE cần classId                |
| `FINAL_EXAM_CANNOT_HAVE_CLASS` | 400  | FINAL_EXAM không được có classId   |
| `SEMESTER_NOT_FOUND`           | 404  | Semester không tồn tại             |
| `ROOM_NOT_FOUND`               | 404  | Room không tồn tại                 |
| `STAFF_NOT_FOUND`              | 404  | Staff không tồn tại                |
| `SLOT_HAS_ATTENDANCE_RECORDS`  | 400  | Không thể xóa slot đã có điểm danh |

---

## 7. Hướng Dẫn Phát Triển

### 7.1 Danh Sách File Quan Trọng

**Backend:**
| # | File | Mô tả |
|---|------|-------|
| 1 | `entity/Slot.java` | Core entity với dual session fields |
| 2 | `service/SlotService.java` | CRUD + import logic |
| 3 | `controller/SlotController.java` | REST API endpoints |
| 4 | `repository/impl/SlotRepositoryImpl.java` | Custom search queries |
| 5 | `dto/request/SlotCreateRequest.java` | Validation rules |
| 6 | `dto/response/SlotDTO.java` | Response format |

**Frontend:**
| # | File | Mô tả |
|---|------|-------|
| 1 | `app/admin/slots/page.tsx` | Admin slot management |
| 2 | `app/lecturer/slots/page.tsx` | Lecturer view |
| 3 | `app/supervisor/slots/page.tsx` | Supervisor exam view |
| 4 | `hooks/api/useSlots.ts` | React Query hooks |
| 5 | `components/admin/slots/slot-form-dialog.tsx` | Create/Edit form |
| 6 | `lib/zod-schemas.ts` | Validation schemas |

### 7.2 So Sánh 3 Loại Slot

| Đặc tính            | LECTURE          | LECTURE_WITH_PT | FINAL_EXAM       |
| ------------------- | ---------------- | --------------- | ---------------- |
| **Class**           | Required         | Required        | NOT ALLOWED      |
| **Subjects**        | Via class        | Via class       | ExamSlotSubject  |
| **Regular Session** | Yes              | Yes             | No               |
| **Exam Session**    | No               | Yes             | Yes              |
| **Attendance**      | AttendanceRecord | Both            | ExamAttendance   |
| **Portal**          | Admin/Lecturer   | Admin/Lecturer  | Admin/Supervisor |
| **Delete Check**    | No records       | No records      | No participants  |

### 7.3 Seed Data Reference

**Seed slots được tạo:**

- ~50 LECTURE slots cho các lớp học
- ~20 LECTURE_WITH_PT slots (có Progress Test)
- ~10 FINAL_EXAM slots

### 7.4 FAQ - Câu Hỏi Thường Gặp

**Q: Tại sao Slot có 2 bộ session fields?**

> A: Để hỗ trợ LECTURE_WITH_PT có cả điểm danh thường (trong giờ học) và điểm danh thi (khi làm bài kiểm tra). Hai session hoạt động độc lập.

**Q: FINAL_EXAM khác LECTURE như thế nào?**

> A: FINAL_EXAM không thuộc một lớp cụ thể (`classId = null`), thay vào đó gán nhiều môn học qua `ExamSlotSubject`. Một buổi thi có thể có nhiều môn.

**Q: Làm sao biết slot nào đang nhận diện?**

> A: Check `sessionStatus` hoặc `examSessionStatus` = `RUNNING`. Scan count tăng mỗi lần camera quét.

**Q: Edit window là gì?**

> A: Khoảng thời gian được phép cập nhật attendance. Thường từ `startTime` đến `23:59:59 Vietnam time` cùng ngày.

**Q: CSV import có hỗ trợ update không?**

> A: Có, với mode `ADD_AND_UPDATE`. Hệ thống match bằng `(start_time, room)` để update existing slots.

### 7.5 Các Bước Khi Trình Bày Hội Đồng

1. **Giới thiệu Slot**: Giải thích slot là đơn vị buổi học/thi
2. **Show 3 loại**: LECTURE, LECTURE_WITH_PT, FINAL_EXAM và khác biệt
3. **Demo tạo slot**: Form với validation, conflict detection
4. **Show dual session**: Giải thích tại sao có 2 bộ session fields
5. **Demo 3 portals**: Admin, Lecturer, Supervisor views
6. **Import CSV**: Demo partial success pattern
7. **Giới thiệu liên kết**: Attendance records, Recognition service

### 7.6 Tài Liệu Liên Quan

- [REGULAR_ATTENDANCE.md](./REGULAR_ATTENDANCE.md) - Điểm danh thường cho LECTURE/LECTURE_WITH_PT
- [EXAM_SLOT.md](./EXAM_SLOT.md) - Chi tiết về FINAL_EXAM và điểm danh thi
- [FACE_RECOGNITION.md](./FACE_RECOGNITION.md) - Python Recognition Service integration
- [ROOM.md](./ROOM.md) - Room module (nơi slot diễn ra)
- [CLASS_ENROLLMENT.md](./CLASS_ENROLLMENT.md) - Class và Enrollment (nguồn sinh viên)
