# Class Module (Bao gồm Enrollment) - Tài Liệu Kỹ Thuật

> **Mục đích tài liệu**: Giúp người đọc hiểu và làm việc với module Class (Lớp học) và Enrollment (Đăng ký) trong hệ thống FUACS - Hệ thống Điểm danh Tự động sử dụng Nhận diện Khuôn mặt.

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

### 1.1 Class và Enrollment là gì?

**AcademicClass (Lớp học)** là đơn vị tổ chức học tập cụ thể trong một học kỳ. Mỗi lớp học được mở cho một môn học trong một học kỳ nhất định, có mã lớp riêng biệt.

**Enrollment (Đăng ký học)** là bản ghi liên kết giữa sinh viên và lớp học, theo dõi trạng thái đăng ký (đang học/đã rút).

### 1.2 Vai trò trong hệ thống FUACS

Trong hệ thống FUACS, **Class Module** đóng vai trò **core operational module** với các chức năng:

| Vai trò             | Mô tả                       | Ví dụ                                  |
| ------------------- | --------------------------- | -------------------------------------- |
| **Teaching Unit**   | Đơn vị giảng dạy thực tế    | Lớp SE1234 cho môn PRO192 kỳ Fall 2024 |
| **Slot Container**  | Chứa các buổi học/điểm danh | Lớp có 15 slot lecture + 1 slot exam   |
| **Student Group**   | Nhóm sinh viên cùng học     | 30 sinh viên enrolled trong lớp        |
| **Attendance Base** | Cơ sở để điểm danh          | Điểm danh theo từng slot của lớp       |

### 1.3 Mối Quan Hệ với Các Module Khác

```
                    ┌─────────────────┐
                    │    SEMESTER     │
                    │   (Học kỳ)      │
                    └────────┬────────┘
                             │
              ┌──────────────┼──────────────┐
              │              │              │
              ▼              │              ▼
     ┌─────────────────┐     │     ┌─────────────────┐
     │     SUBJECT     │     │     │      ROOM       │
     │   (Môn học)     │     │     │    (Phòng)      │
     └────────┬────────┘     │     └────────┬────────┘
              │              │              │
              └──────────────┼──────────────┘
                             │
                             ▼
                    ┌─────────────────┐
                    │ ACADEMIC CLASS  │
                    │   (Lớp học)     │
                    └────────┬────────┘
                             │
         ┌───────────────────┼───────────────────┐
         │                   │                   │
         ▼                   ▼                   ▼
┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐
│   ENROLLMENT    │ │      SLOT       │ │      STAFF      │
│ (Đăng ký học)   │ │  (Buổi học)     │ │  (Giảng viên)   │
└────────┬────────┘ └────────┬────────┘ └─────────────────┘
         │                   │
         ▼                   ▼
┌─────────────────┐ ┌─────────────────┐
│     STUDENT     │ │   ATTENDANCE    │
│  (Sinh viên)    │ │   (Điểm danh)   │
└─────────────────┘ └─────────────────┘
```

**Giải thích mối quan hệ**:

- **Subject → Class**: Quan hệ OneToMany - Một môn có nhiều lớp học
- **Semester → Class**: Quan hệ OneToMany - Một học kỳ có nhiều lớp học
- **Class → Enrollment**: Quan hệ OneToMany - Một lớp có nhiều bản ghi enrollment
- **Class → Slot**: Quan hệ OneToMany - Một lớp có nhiều buổi học
- **Enrollment ↔ Student**: Quan hệ ManyToOne - Mỗi enrollment thuộc một sinh viên

---

## 2. Kiến Trúc Hệ Thống

### 2.1 Tổng Quan Kiến Trúc

```
┌─────────────────────────────────────────────────────────────────────┐
│                          FRONTEND (Next.js)                         │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐                 │
│  │    Pages    │  │ Components  │  │   Hooks     │                 │
│  │  /admin/    │  │  class-     │  │   useGet    │                 │
│  │  classes    │──│  table.tsx  │──│  Classes    │                 │
│  └─────────────┘  └─────────────┘  └──────┬──────┘                 │
│                                           │                         │
│  ┌─────────────┐  ┌─────────────┐         │                        │
│  │ /classes/   │  │  student-   │         │                        │
│  │ [id]/       │──│  table.tsx  │─────────┘                        │
│  │ students    │  └─────────────┘                                  │
│  └─────────────┘                                                    │
└────────────────────────────────────────────┼────────────────────────┘
                                             │ HTTP/REST
                                             ▼
┌─────────────────────────────────────────────────────────────────────┐
│                        BACKEND (Spring Boot)                        │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌───────────┐  │
│  │ Controller  │  │   Service   │  │ Repository  │  │  Entity   │  │
│  │  Class +    │──│  Class +    │──│  Class +    │──│ Academic  │  │
│  │ Enrollment  │  │ Enrollment  │  │ Enrollment  │  │  Class    │  │
│  └─────────────┘  └─────────────┘  └──────┬──────┘  └───────────┘  │
└────────────────────────────────────────────┼────────────────────────┘
                                             │ JDBC
                                             ▼
                              ┌───────────────────────────┐
                              │       PostgreSQL          │
                              │  classes + enrollments    │
                              └───────────────────────────┘
```

### 2.2 Cấu Trúc Thư Mục

**Backend** (`backend/src/main/java/com/fuacs/backend/`):

```
├── controller/
│   ├── ClassController.java          # REST API cho Class (7 endpoints)
│   └── EnrollmentController.java     # REST API cho Enrollment (6 endpoints)
├── service/
│   ├── ClassService.java             # Business logic Class
│   └── EnrollmentService.java        # Business logic Enrollment
├── entity/
│   ├── AcademicClass.java            # JPA Entity - Lớp học
│   ├── Enrollment.java               # JPA Entity - Đăng ký
│   └── EnrollmentId.java             # Composite Key cho Enrollment
├── repository/
│   ├── ClassRepository.java          # JPA Repository
│   ├── EnrollmentRepository.java     # JPA Repository
│   ├── custom/
│   │   ├── CustomClassRepository.java
│   │   └── CustomEnrollmentRepository.java
│   └── impl/
│       ├── ClassRepositoryImpl.java
│       └── EnrollmentRepositoryImpl.java
├── dto/
│   ├── request/
│   │   ├── ClassCreateRequest.java
│   │   ├── ClassUpdateRequest.java
│   │   ├── ClassSearchRequest.java
│   │   ├── ClassCsvRow.java
│   │   ├── EnrollmentCreateRequest.java
│   │   ├── EnrollmentUpdateRequest.java
│   │   └── EnrollmentCsvRow.java
│   ├── response/
│   │   ├── ClassDTO.java
│   │   └── EnrollmentDTO.java
│   └── mapper/
│       ├── ClassMapper.java
│       └── EnrollmentMapper.java
```

**Frontend** (`frontend-web/`):

```
├── app/admin/classes/
│   ├── page.tsx                        # Trang quản lý lớp học
│   └── [id]/students/
│       └── page.tsx                    # Trang danh sách sinh viên
├── components/admin/classes/
│   ├── class-table.tsx                 # Bảng danh sách lớp
│   ├── class-columns.tsx               # Định nghĩa cột
│   ├── class-pagination.tsx            # Phân trang
│   ├── class-form-dialog.tsx           # Form tạo/sửa lớp
│   ├── delete-class-dialog.tsx         # Dialog xóa lớp
│   ├── class-students-table.tsx        # Bảng sinh viên trong lớp
│   ├── add-student-dialog.tsx          # Dialog thêm sinh viên
│   ├── view-student-dialog.tsx         # Dialog xem chi tiết SV
│   ├── withdraw-student-dialog.tsx     # Dialog rút khỏi lớp
│   ├── re-enroll-student-dialog.tsx    # Dialog đăng ký lại
│   └── delete-student-dialog.tsx       # Dialog xóa enrollment
├── hooks/api/
│   ├── useClasses.ts                   # React Query hooks cho Class
│   └── useEnrollments.ts               # React Query hooks cho Enrollment
├── types/
│   └── index.ts                        # TypeScript types
└── lib/
    └── zod-schemas.ts                  # Zod validation schemas
```

---

## 3. Backend Implementation

### 3.1 Database Schema

**Table: `classes`**

```sql
CREATE TABLE classes (
    id SMALLSERIAL PRIMARY KEY,
    code VARCHAR(20) NOT NULL,
    subject_id SMALLINT NOT NULL,
    semester_id SMALLINT NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (subject_id) REFERENCES subjects(id),
    FOREIGN KEY (semester_id) REFERENCES semesters(id),
    UNIQUE (subject_id, semester_id, code)
);

CREATE INDEX idx_classes_semester_id ON classes(semester_id);
CREATE INDEX idx_classes_subject_id ON classes(subject_id);
```

**Table: `enrollments`**

```sql
CREATE TABLE enrollments (
    class_id SMALLINT NOT NULL,
    student_user_id INTEGER NOT NULL,
    is_enrolled BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (class_id, student_user_id),
    FOREIGN KEY (class_id) REFERENCES classes(id) ON DELETE CASCADE,
    FOREIGN KEY (student_user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX idx_enrollments_class_id_enrolled ON enrollments(class_id, is_enrolled);
CREATE INDEX idx_enrollments_student_user_id ON enrollments(student_user_id);
```

**Entity Class**: `AcademicClass.java`

| Field         | Type              | Constraints        | Mô tả                 |
| ------------- | ----------------- | ------------------ | --------------------- |
| `id`          | Short             | PK, Auto           | ID tự động tăng       |
| `code`        | String(20)        | NotNull            | Mã lớp (VD: "SE1234") |
| `subject`     | Subject           | ManyToOne, NotNull | Môn học               |
| `semester`    | Semester          | ManyToOne, NotNull | Học kỳ                |
| `isActive`    | Boolean           | Default: true      | Trạng thái            |
| `enrollments` | Set\<Enrollment\> | OneToMany          | Danh sách đăng ký     |
| `slots`       | Set\<Slot\>       | OneToMany          | Danh sách buổi học    |

**Entity Class**: `Enrollment.java` (Composite Key)

| Field           | Type          | Constraints    | Mô tả                       |
| --------------- | ------------- | -------------- | --------------------------- |
| `id`            | EnrollmentId  | PK (Composite) | classId + studentUserId     |
| `academicClass` | AcademicClass | ManyToOne      | Lớp học                     |
| `student`       | User          | ManyToOne      | Sinh viên                   |
| `isEnrolled`    | Boolean       | Default: true  | true=Đang học, false=Đã rút |
| `createdAt`     | Instant       | Auto           | Ngày đăng ký                |
| `updatedAt`     | Instant       | Auto           | Ngày cập nhật               |

### 3.2 REST API Endpoints

**Class Controller** - Base Path: `/api/v1/classes`

| Method | Endpoint            | Permission        | Mô tả                      | Request       |
| ------ | ------------------- | ----------------- | -------------------------- | ------------- |
| GET    | `/`                 | CLASS_READ        | Danh sách lớp (phân trang) | Query params  |
| GET    | `/{id}`             | CLASS_READ        | Chi tiết lớp               | -             |
| POST   | `/`                 | CLASS_CREATE      | Tạo lớp mới                | CreateRequest |
| PUT    | `/{id}`             | CLASS_UPDATE      | Cập nhật lớp               | UpdateRequest |
| DELETE | `/{id}`             | CLASS_DELETE_HARD | Xóa lớp                    | -             |
| POST   | `/import`           | CLASS_IMPORT      | Import từ CSV              | FormData      |
| GET    | `/{id}/enrollments` | CLASS_READ        | Danh sách SV trong lớp     | Query params  |

**Enrollment Controller** - Base Path: `/api/v1/enrollments`

| Method | Endpoint                     | Permission        | Mô tả                      | Request       |
| ------ | ---------------------------- | ----------------- | -------------------------- | ------------- |
| GET    | `/`                          | CLASS_READ        | Danh sách enrollments      | Query params  |
| GET    | `/{classId}/{studentUserId}` | CLASS_READ        | Chi tiết enrollment        | -             |
| POST   | `/`                          | ENROLLMENT_MANAGE | Thêm SV vào lớp            | CreateRequest |
| PUT    | `/{classId}/{studentUserId}` | ENROLLMENT_MANAGE | Cập nhật (rút/đăng ký lại) | UpdateRequest |
| DELETE | `/{classId}/{studentUserId}` | ENROLLMENT_MANAGE | Xóa enrollment             | -             |
| POST   | `/import`                    | ENROLLMENT_MANAGE | Import từ CSV              | FormData      |

### 3.3 Data Transfer Objects (DTOs)

**Class Request DTOs:**

```java
// ClassCreateRequest - Tạo lớp mới
{
  "code": "SE1234",           // Bắt buộc, max 20, UPPERCASE + số
  "subjectId": 1,             // Bắt buộc
  "semesterId": 1             // Bắt buộc
}

// ClassUpdateRequest - Cập nhật
{
  "code": "SE1234",
  "subjectId": 1,
  "semesterId": 1,
  "isActive": true            // Có thể deactivate (nếu lớp đã kết thúc)
}

// ClassSearchRequest - Query params
?page=0&pageSize=10&sort=asc&sortBy=code&search=SE&isActive=true&semesterId=1&subjectId=1
```

**Class Response DTO:**

```java
// ClassDTO - Response trả về
{
  "id": 1,
  "code": "SE1234",
  "semester": {
    "id": 1, "name": "Fall 2024", "code": "FA24",
    "startDate": "2024-09-01", "endDate": "2024-12-31", "isActive": true
  },
  "subject": {
    "id": 1, "name": "OOP", "code": "PRO192", "isActive": true,
    "majors": [{"id": 1, "name": "Software Engineering", "code": "SE"}]
  },
  "totalStudent": 30,           // Tổng số enrollment
  "totalEnrolledStudent": 28,   // Số đang học (isEnrolled=true)
  "totalSlot": 16,              // Tổng số slot
  "totalActiveSlot": 15,        // Số slot active
  "isActive": true,
  "createdAt": "2024-01-15T10:30:00Z",
  "updatedAt": "2024-01-15T10:30:00Z"
}
```

**Enrollment Request DTOs:**

```java
// EnrollmentCreateRequest - Thêm SV vào lớp
{
  "classId": 1,
  "studentUserId": 5
}

// EnrollmentUpdateRequest - Rút/Đăng ký lại
{
  "classId": 1,
  "studentUserId": 5,
  "isEnrolled": false         // false = rút, true = đăng ký lại
}
```

**Enrollment Response DTO:**

```java
// EnrollmentDTO
{
  "classId": 1,
  "studentUserId": 5,
  "student": {
    "userId": 5,
    "fullName": "Nguyen Van A",
    "rollNumber": "SE123456",
    "email": "a@fpt.edu.vn",
    "major": {"name": "Software Engineering", "code": "SE"}
  },
  "class": { "id": 1, "code": "SE1234", ... },
  "isEnrolled": true,
  "createdAt": "2024-01-15T10:30:00Z",
  "updatedAt": "2024-01-15T10:30:00Z"
}
```

### 3.4 Service Layer

**ClassService Methods:**

| Method                          | Input                     | Output           | Mô tả                           |
| ------------------------------- | ------------------------- | ---------------- | ------------------------------- |
| `search(request)`               | ClassSearchRequest        | List\<ClassDTO\> | Tìm kiếm với filter, pagination |
| `count(request)`                | ClassSearchRequest        | Long             | Đếm tổng records                |
| `findById(id)`                  | Short                     | ClassDTO         | Lấy chi tiết lớp                |
| `create(request)`               | ClassCreateRequest        | ClassDTO         | Tạo mới với validation          |
| `update(id, request)`           | Short, ClassUpdateRequest | ClassDTO         | Cập nhật, kiểm tra deactivate   |
| `delete(id)`                    | Short                     | void             | Xóa, kiểm tra dependencies      |
| `importFromCsv(file, mode)`     | MultipartFile, String     | ImportResultDTO  | Import hàng loạt                |
| `searchClassBySemesterId(...)`  | Short, SearchRequest      | List\<ClassDTO\> | Lọc theo semester               |
| `searchClassBySubjectId(...)`   | Short, SearchRequest      | List\<ClassDTO\> | Lọc theo subject                |
| `searchClassesByStudentId(...)` | Integer, SearchRequest    | List\<ClassDTO\> | Lớp của sinh viên               |
| `searchClassesByStaffId(...)`   | Integer, SearchRequest    | List\<ClassDTO\> | Lớp của giảng viên              |

**EnrollmentService Methods:**

| Method                            | Input                   | Output                    | Mô tả                  |
| --------------------------------- | ----------------------- | ------------------------- | ---------------------- |
| `create(request)`                 | EnrollmentCreateRequest | EnrollmentDTO             | Đăng ký SV vào lớp     |
| `update(request)`                 | EnrollmentUpdateRequest | EnrollmentDTO             | Rút/Đăng ký lại        |
| `delete(classId, studentUserId)`  | Short, Integer          | void                      | Xóa hoàn toàn          |
| `findByClassId(classId, request)` | Short, SearchRequest    | List\<StudentProfileDTO\> | Danh sách SV trong lớp |
| `importFromCsv(file, mode)`       | MultipartFile, String   | ImportResultDTO           | Import hàng loạt       |

### 3.5 Repository Layer

**ClassRepository - Custom Queries:**

```java
// === Kiểm tra unique constraint ===
boolean existsByCodeAndSubjectIdAndSemesterId(String code, Short subjectId, Short semesterId);
boolean existsByCodeAndSubjectIdAndSemesterIdAndIdNot(...);

// === Lookup ===
AcademicClass findByCodeAndSubjectIdAndSemesterId(...);
AcademicClass findByCodeAndSubjectCodeAndSemesterCode(...);

// === Count dependencies ===
long countAllSlotsByClassId(Short classId);
long countAllStudentsByClassId(Short classId);
long countActiveSlotsByClassId(Short classId);
long countEnrolledStudentsByClassId(Short classId);

// === Deactivation check ===
LocalDateTime findLastActiveSlotEndTimeByClassId(Short classId);

// === Dashboard ===
Integer countTotalClassesBySemester(Short semesterId);
Integer countActiveClassesBySemester(Short semesterId);
```

**EnrollmentRepository - Custom Queries:**

```java
// === Kiểm tra duplicate ===
boolean existsByStudentAndSubjectAndSemesterAndEnrolled(...);

// === Lookup ===
List<Enrollment> findAllByAcademicClassId(Short classId);

// === Count ===
long countByClassId(Short classId);
long countEnrolledByClassId(Short classId);
long countWithdrawnByClassId(Short classId);
```

---

## 4. Frontend Implementation

### 4.1 Trang Quản Lý Class

**Route**: `/admin/classes`
**Quyền truy cập**: DATA_OPERATOR (Admin)
**File chính**: `frontend-web/app/admin/classes/page.tsx`

**Giao diện người dùng:**

```
┌─────────────────────────────────────────────────────────────────────┐
│  Class Management                                                    │
│  Create, manage, and organize academic classes.                     │
├─────────────────────────────────────────────────────────────────────┤
│  [Search...]  [Status ▼]  [Sort ▼]  [↑↓]  [Semester ▼]  [Subject ▼] │
│                                              [Import ▼] [+ Create]   │
├─────────────────────────────────────────────────────────────────────┤
│  Code    │ Semester │ Subject │ Students │ Slots │ Status │ Action  │
│──────────┼──────────┼─────────┼──────────┼───────┼────────┼─────────│
│  SE1234  │   FA24   │  PRO192 │    28    │  15   │ Active │   ⋮     │
│  SE1235  │   FA24   │  PRO192 │    30    │  16   │ Active │   ⋮     │
│  AI2001  │   FA24   │  DSA201 │    25    │  14   │Inactive│   ⋮     │
├─────────────────────────────────────────────────────────────────────┤
│  Showing 1 - 10 of 45 items              ◀ [1] [2] [3] ... [5] ▶    │
└─────────────────────────────────────────────────────────────────────┘
```

**Tính năng:**
| Tính năng | Mô tả |
|-----------|-------|
| Tìm kiếm | Theo mã lớp (debounced 500ms) |
| Lọc Status | Active/Inactive/All |
| Lọc Semester | Searchable popover, hiển thị code + name |
| Lọc Subject | Searchable popover, hiển thị code + name |
| Sắp xếp | Theo Code |
| Import | Classes CSV hoặc Enrollments CSV |
| Phân trang | 10 items/trang |

**Action Menu:**

- Edit - Mở form chỉnh sửa
- View Students - Chuyển đến trang danh sách SV
- View Slots - Chuyển đến trang quản lý slot

### 4.2 Trang Quản Lý Sinh Viên Trong Lớp

**Route**: `/admin/classes/[id]/students`
**File chính**: `frontend-web/app/admin/classes/[id]/students/page.tsx`

**Giao diện người dùng:**

```
┌─────────────────────────────────────────────────────────────────────┐
│  ← Back to Classes                                                  │
│  Class: SE1234 - OOP (Fall 2024)                                    │
├─────────────────────────────────────────────────────────────────────┤
│  [Search...]  [Status ▼]  [Sort By ▼]  [↑↓]         [+ Add Student] │
├─────────────────────────────────────────────────────────────────────┤
│  │ Enrolled: 28 │ Withdrawn: 2 │ Active Slots: 15 │                 │
├─────────────────────────────────────────────────────────────────────┤
│ STT│ Roll Number │ Full Name │ Email │ Major │ Enrolled │ Status │⋮ │
│────┼─────────────┼───────────┼───────┼───────┼──────────┼────────┼──│
│  1 │  SE123456   │ Nguyen A  │  ...  │  SE   │ 01/09/24 │ Active │⋮ │
│  2 │  SE123457   │ Tran B    │  ...  │  SE   │ 01/09/24 │Withdraw│⋮ │
├─────────────────────────────────────────────────────────────────────┤
│  Showing 1 - 10 of 30 items              ◀ [1] [2] [3] ▶            │
└─────────────────────────────────────────────────────────────────────┘
```

**Action Menu (theo trạng thái):**

| Trạng thái    | Actions                                                           |
| ------------- | ----------------------------------------------------------------- |
| **Active**    | View Details, Withdraw (red), Delete (red - chỉ khi chưa có slot) |
| **Withdrawn** | View Details, Re-enroll (green)                                   |

**Add Student Dialog:**

- Search theo tên, mã SV, email
- Chỉ hiển thị SV có major thuộc subject's majors
- Exclude SV đã enrolled

### 4.3 Component Structure

```
ClassesPage (page.tsx)
│
├── Controls Section
│   ├── Search Input (debounced)
│   ├── Status Select
│   ├── Sort Select + Order
│   ├── Semester Popover (searchable)
│   ├── Subject Popover (searchable)
│   ├── Import Popover (2 options)
│   └── Create Button
│
├── ClassTable
│   ├── class-columns.tsx (7 columns)
│   │   ├── Code (text, centered)
│   │   ├── Semester (badge + tooltip)
│   │   ├── Subject (badge + tooltip)
│   │   ├── Students (number)
│   │   ├── Slots (number)
│   │   ├── Status (badge)
│   │   └── Action (dropdown menu)
│   └── ClassPagination
│
├── ClassFormDialog (Create/Edit)
│   ├── Code Input (auto-uppercase)
│   ├── Semester Popover (searchable)
│   ├── Subject Popover (searchable)
│   └── Active Switch (edit mode only)
│
├── DeleteClassDialog
├── GenericImportDialog (Classes)
└── GenericImportDialog (Enrollments)

ClassStudentsPage ([id]/students/page.tsx)
│
├── Controls Section
│   ├── Search Input
│   ├── Status Select (Active/Withdrawn)
│   ├── Sort Select + Order
│   └── Add Student Button
│
├── Stats Card
│   ├── Total Enrolled
│   ├── Withdrawn
│   └── Active Slots
│
├── ClassStudentsTable (8 columns)
│   └── Action Menu (context-aware)
│
├── AddStudentDialog
├── ViewStudentDialog
├── WithdrawStudentDialog
├── ReEnrollStudentDialog
└── DeleteStudentDialog
```

### 4.4 API Hooks (React Query)

**File**: `frontend-web/hooks/api/useClasses.ts`

| Hook                    | Loại     | Chức năng                  | Caching                  |
| ----------------------- | -------- | -------------------------- | ------------------------ |
| `useGetClasses(params)` | Query    | Danh sách lớp (phân trang) | staleTime: 5 phút        |
| `useGetClassById(id)`   | Query    | Chi tiết lớp               | staleTime: 5 phút        |
| `useCreateClass()`      | Mutation | Tạo lớp mới                | Invalidate list          |
| `useUpdateClass()`      | Mutation | Cập nhật lớp               | Invalidate list + detail |
| `useDeleteClass()`      | Mutation | Xóa lớp                    | Invalidate list          |
| `useImportClasses()`    | Mutation | Import từ CSV              | Invalidate list          |
| `useGetClassSlots(id)`  | Query    | Danh sách slot             | staleTime: 5 phút        |

**File**: `frontend-web/hooks/api/useEnrollments.ts`

| Hook                              | Loại     | Chức năng              | Caching                |
| --------------------------------- | -------- | ---------------------- | ---------------------- |
| `useGetClassEnrollments(classId)` | Query    | Danh sách SV trong lớp | staleTime: 5 phút      |
| `useCreateEnrollment()`           | Mutation | Thêm SV vào lớp        | Invalidate enrollments |
| `useUpdateEnrollment()`           | Mutation | Rút/Đăng ký lại        | Invalidate enrollments |
| `useDeleteEnrollment()`           | Mutation | Xóa enrollment         | Invalidate enrollments |
| `useImportEnrollments()`          | Mutation | Import từ CSV          | Invalidate enrollments |

**Query Keys:**

```typescript
classes: {
  all: ["classes"],
  detail: (id) => ["classes", id],
  slots: (id) => ["classes", id, "slots"],
}

enrollments: {
  all: ["enrollments"],
  byClass: (classId) => ["enrollments", "class", classId],
  detail: (classId, studentUserId) => ["enrollments", classId, studentUserId],
}
```

### 4.5 TypeScript Type Definitions

**File**: `frontend-web/types/index.ts`

```typescript
// Core type - Lớp học
type Class = {
  id: number;
  code: string; // Mã lớp: "SE1234"
  semester: {
    id: number;
    name: string;
    code: string;
    startDate?: string;
    endDate?: string;
    isActive: boolean;
  };
  subject: {
    id: number;
    name: string;
    code: string;
    isActive: boolean;
    majors?: Array<{
      // Dùng để filter sinh viên
      id: number;
      name: string;
      code: string;
      isActive: boolean;
    }>;
  };
  totalStudent: number; // Tổng enrollment
  totalEnrolledStudent: number; // Số đang học
  totalSlot: number; // Tổng slot
  totalActiveSlot: number; // Slot active
  isActive: boolean;
  createdAt: string;
  updatedAt: string;
};

// Payload tạo lớp
type CreateClassPayload = {
  code: string; // UPPERCASE + digits, max 20
  semesterId: number;
  subjectId: number;
};

// Payload cập nhật
type UpdateClassPayload = CreateClassPayload & {
  isActive: boolean;
};

// Enrollment trong lớp
type ClassEnrollment = {
  userId: number;
  studentUserId: number;
  fullName: string;
  rollNumber: string;
  email: string;
  major: { name: string; code: string };
  isEnrolled: boolean;
  enrolledAt: string; // Ngày đăng ký (createdAt)
  updatedAt: string;
};
```

### 4.6 Form Validation (Zod Schema)

**Class Form:**

| Field        | Validation                                   | Error Message                                         |
| ------------ | -------------------------------------------- | ----------------------------------------------------- |
| `code`       | Bắt buộc, 1-20 ký tự, pattern: `^[A-Z0-9]+$` | "Code must contain only UPPERCASE letters and digits" |
| `semesterId` | Bắt buộc, min 1                              | "Semester is required"                                |
| `subjectId`  | Bắt buộc, min 1                              | "Subject is required"                                 |
| `isActive`   | Boolean (chỉ Edit mode)                      | -                                                     |

**Đặc biệt:**

- Code field tự động chuyển UPPERCASE khi nhập
- Semester/Subject dropdowns: Searchable, only active items (+ current inactive if editing)

---

## 5. Luồng Xử Lý Nghiệp Vụ

### 5.1 Luồng Tạo Lớp Học Mới

```
┌──────────┐      ┌──────────────────┐      ┌──────────────────┐      ┌──────────┐
│   User   │      │     Frontend     │      │     Backend      │      │ Database │
└────┬─────┘      └────────┬─────────┘      └────────┬─────────┘      └────┬─────┘
     │                     │                         │                     │
     │ 1. Click Create     │                         │                     │
     │────────────────────>│                         │                     │
     │                     │                         │                     │
     │                     │ 2. Hiện Form Dialog     │                     │
     │<────────────────────│                         │                     │
     │                     │                         │                     │
     │ 3. Điền form        │                         │                     │
     │   code: "SE1234"    │                         │                     │
     │   semester: FA24    │                         │                     │
     │   subject: PRO192   │                         │                     │
     │────────────────────>│                         │                     │
     │                     │                         │                     │
     │                     │ 4. Zod Validation       │                     │
     │                     │ (uppercase check)       │                     │
     │                     │                         │                     │
     │                     │ 5. POST /classes        │                     │
     │                     │────────────────────────>│                     │
     │                     │                         │                     │
     │                     │                         │ 6. Validate:        │
     │                     │                         │ - Subject exists?   │
     │                     │                         │ - Semester exists?  │
     │                     │                         │ - Both active?      │
     │                     │                         │ - Unique combo?     │
     │                     │                         │                     │
     │                     │                         │ 7. INSERT           │
     │                     │                         │────────────────────>│
     │                     │                         │                     │
     │                     │ 8. Return ClassDTO      │<────────────────────│
     │                     │<────────────────────────│                     │
     │                     │                         │                     │
     │                     │ 9. Invalidate cache     │                     │
     │                     │    Toast success        │                     │
     │<────────────────────│                         │                     │
```

### 5.2 Luồng Thêm Sinh Viên Vào Lớp

```
Bước 1: Admin click "Add Student"
    │
    ▼
Bước 2: Hiện AddStudentDialog
    │   - Fetch SV theo majors của subject
    │   - Exclude SV đã enrolled
    │
    ▼
Bước 3: Admin search và chọn SV
    │
    ▼
Bước 4: Click "Add"
    │
    ▼
Bước 5: POST /enrollments
    │   {classId: 1, studentUserId: 5}
    │
    ▼
Bước 6: Backend validation
    │
    ├─── Lớp học active?
    │         └── KHÔNG → Error: INACTIVE_CLASS_NOT_ALLOWED
    │
    ├─── Sinh viên active & có profile?
    │         └── KHÔNG → Error: USER_NOT_FOUND
    │
    ├─── Major của SV thuộc subject's majors?
    │         └── KHÔNG → Error: MAJOR_MISMATCH
    │
    ├─── Học kỳ chưa kết thúc?
    │         └── ĐÃ KẾT THÚC → Error: SEMESTER_ENDED
    │
    └─── Đã enrolled trước đó?
              │
              ├── Đang enrolled (isEnrolled=true)
              │        └── Error: ALREADY_ENROLLED
              │
              └── Đã rút (isEnrolled=false)
                       └── UPDATE isEnrolled=true (re-enroll)
    │
    ▼
Bước 7: INSERT/UPDATE enrollment
    │
    ▼
Bước 8: Invalidate cache → Refresh danh sách
```

### 5.3 Luồng Deactivate Lớp Học

```
Admin click Edit → Tắt Active switch
    │
    ▼
PUT /classes/{id}
    │   {isActive: false, ...}
    │
    ▼
Backend kiểm tra: Lớp đã kết thúc chưa?
    │
    ├─── Lấy lastActiveSlotEndTime
    │
    ├─── So sánh với current time (VN timezone)
    │
    ├─── current < lastEndTime?
    │         │
    │         ├── TRUE (chưa kết thúc)
    │         │     └── Error: CLASS_NOT_FINISHED
    │         │        "Cannot deactivate class that hasn't finished.
    │         │         Last slot ends at: 2024-12-15 17:00"
    │         │
    │         └── FALSE (đã kết thúc)
    │               └── OK, cho phép deactivate
    │
    ▼
UPDATE is_active = false
    │
    ▼
Return updated ClassDTO
```

### 5.4 Luồng Xóa Lớp Học

```
User click Delete
    │
    ▼
Hiện Confirmation Dialog
    │
    ├─── User xác nhận ───────────────────────────────────┐
    │                                                      │
    │                                                      ▼
    │                                          DELETE /classes/{id}
    │                                                      │
    │                                                      ▼
    │                                          Backend kiểm tra:
    │                                          ┌────────────────────────┐
    │                                          │ countAllSlotsByClassId │
    │                                          │ countAllStudentsByClassId │
    │                                          └────────────────────────┘
    │                                                      │
    │                  ┌───────────────────────────────────┼──────────────────────────┐
    │                  │                                   │                          │
    │                  ▼                                   ▼                          │
    │           CÓ slots hoặc                       KHÔNG có gì                       │
    │           enrollments                              │                            │
    │                  │                                  ▼                           │
    │                  ▼                          DELETE from DB                      │
    │       Return Error:                                │                            │
    │    CLASS_HAS_DEPENDENCIES                         ▼                            │
    │    "Cannot delete class.                  Return Success                        │
    │     Found X slots and Y                          │                              │
    │     enrollments"                                 ▼                              │
    │                  │                       Toast Success                          │
    │                  ▼                       Refresh list                           │
    │           Toast Error                                                           │
    │                                                                                 │
    └─── User hủy ──────────────────────────────────────────────────────> Đóng dialog
```

---

## 6. Business Rules & Validation

### 6.1 Class Validation Rules

| Rule              | Mô tả                                   | Error Code                       | HTTP |
| ----------------- | --------------------------------------- | -------------------------------- | ---- |
| Unique Combo      | (code + subject + semester) phải unique | `CLASS_EXISTS`                   | 409  |
| Code Pattern      | UPPERCASE + digits only (A-Z, 0-9)      | `INVALID_FIELD_FORMAT`           | 400  |
| Subject Required  | subjectId phải tồn tại                  | `SUBJECT_NOT_FOUND`              | 404  |
| Semester Required | semesterId phải tồn tại                 | `SEMESTER_NOT_FOUND`             | 404  |
| Active References | Subject và Semester phải active         | `INACTIVE_REFERENCE_NOT_ALLOWED` | 400  |
| Has Dependencies  | Không xóa nếu có slots hoặc enrollments | `CLASS_HAS_DEPENDENCIES`         | 409  |
| Not Finished      | Không deactivate nếu lớp chưa kết thúc  | `CLASS_NOT_FINISHED`             | 409  |
| Not Found         | Class không tồn tại                     | `CLASS_NOT_FOUND`                | 404  |

### 6.2 Enrollment Validation Rules

| Rule                | Mô tả                                    | Error Code                   | HTTP |
| ------------------- | ---------------------------------------- | ---------------------------- | ---- |
| Class Active        | Lớp học phải active                      | `INACTIVE_CLASS_NOT_ALLOWED` | 400  |
| Student Active      | Sinh viên phải active và có profile      | `USER_NOT_FOUND`             | 404  |
| Major Match         | Major của SV phải thuộc subject's majors | `MAJOR_MISMATCH`             | 400  |
| Semester Active     | Học kỳ chưa kết thúc                     | `SEMESTER_ENDED`             | 400  |
| Already Enrolled    | Không đăng ký lại nếu đang enrolled      | `ALREADY_ENROLLED`           | 409  |
| Delete Before Start | Chỉ xóa enrollment nếu lớp chưa bắt đầu  | `CANNOT_DELETE_AFTER_START`  | 400  |

### 6.3 CSV Import Features

**Class CSV Import:**

Endpoint: `POST /api/v1/classes/import`

```csv
code,subject_code,semester_code[,status]
SE1234,PRO192,FA24,true
SE1235,PRO192,FA24
AI2001,DSA201,FA24,false
```

| Mode           | Mô tả                | Khi đã tồn tại       |
| -------------- | -------------------- | -------------------- |
| `AddOnly`      | Chỉ thêm records mới | Skip, báo lỗi        |
| `AddAndUpdate` | Thêm hoặc cập nhật   | Update status nếu có |

**Enrollment CSV Import:**

Endpoint: `POST /api/v1/enrollments/import`

```csv
student_id,class_code,semester_code
SE123456,SE1234,FA24
SE123457,SE1234,FA24
```

**Xử lý lỗi:**

- Mỗi row xử lý trong transaction riêng (REQUIRES_NEW)
- Partial success: Row lỗi không ảnh hưởng row khác
- Deduplication: Duplicate rows bị loại
- Response: successCount, failureCount, errors[]

### 6.4 Quy Tắc Dependencies

**Không thể XÓA Class nếu:**

- Có bất kỳ Slot nào (totalSlots > 0)
- Có bất kỳ Enrollment nào (totalEnrollments > 0)
- Phải xóa tất cả slots và enrollments trước

**Không thể DEACTIVATE Class nếu:**

- Lớp chưa kết thúc (current time < last slot end time)
- Chỉ được deactivate sau khi tất cả slots đã kết thúc

**Không thể DELETE Enrollment nếu:**

- Lớp đã bắt đầu (có slot đầu tiên đã diễn ra)
- Chỉ cho phép WITHDRAW (soft delete: isEnrolled=false)

---

## 7. Hướng Dẫn Phát Triển

### 7.1 Danh Sách File Quan Trọng

**Backend** (theo thứ tự nên đọc):

| #   | File                      | Mô tả                    | Đường dẫn                   |
| --- | ------------------------- | ------------------------ | --------------------------- |
| 1   | `AcademicClass.java`      | Entity structure         | `backend/.../entity/`       |
| 2   | `Enrollment.java`         | Entity với composite key | `backend/.../entity/`       |
| 3   | `ClassDTO.java`           | Response format          | `backend/.../dto/response/` |
| 4   | `EnrollmentDTO.java`      | Response format          | `backend/.../dto/response/` |
| 5   | `ClassCreateRequest.java` | Input validation         | `backend/.../dto/request/`  |
| 6   | `ClassService.java`       | Business logic           | `backend/.../service/`      |
| 7   | `EnrollmentService.java`  | Business logic           | `backend/.../service/`      |
| 8   | `ClassRepository.java`    | Custom queries           | `backend/.../repository/`   |
| 9   | `ClassController.java`    | API endpoints            | `backend/.../controller/`   |

**Frontend** (theo thứ tự nên đọc):

| #   | File                     | Mô tả             | Đường dẫn                                |
| --- | ------------------------ | ----------------- | ---------------------------------------- |
| 1   | `types/index.ts`         | Type definitions  | `frontend-web/types/`                    |
| 2   | `useClasses.ts`          | API hooks         | `frontend-web/hooks/api/`                |
| 3   | `useEnrollments.ts`      | API hooks         | `frontend-web/hooks/api/`                |
| 4   | `page.tsx`               | Main page         | `frontend-web/app/admin/classes/`        |
| 5   | `[id]/students/page.tsx` | Students page     | `frontend-web/app/admin/classes/`        |
| 6   | `class-form-dialog.tsx`  | Form & validation | `frontend-web/components/admin/classes/` |
| 7   | `add-student-dialog.tsx` | Add student       | `frontend-web/components/admin/classes/` |

### 7.2 FAQ - Câu Hỏi Thường Gặp

**Q1: Khác biệt giữa Class, Subject, Semester?**

| Aspect       | Class                 | Subject               | Semester       |
| ------------ | --------------------- | --------------------- | -------------- |
| Vai trò      | Teaching unit         | Curriculum item       | Time container |
| Đặc điểm     | Cụ thể, có sinh viên  | Trừu tượng, có majors | Có date range  |
| Dependencies | Slots, Enrollments    | Classes               | Classes        |
| Unique key   | code+subject+semester | code alone            | code alone     |

**Q2: Tại sao không xóa được Class?**

- Kiểm tra: `GET /classes/{id}` → xem totalSlot, totalStudent
- Nếu > 0 → phải xóa slots và withdraws tất cả students trước
- Error: `CLASS_HAS_DEPENDENCIES`

**Q3: Tại sao không thêm được sinh viên?**

Kiểm tra:

1. Class active? (`isActive = true`)
2. Semester chưa kết thúc? (`endDate >= today`)
3. Major của SV thuộc subject's majors?
4. SV chưa enrolled? (nếu đã enrolled → không thể add lại)

**Q4: Soft delete vs Hard delete cho Enrollment?**

| Operation     | Điều kiện                | Kết quả                              |
| ------------- | ------------------------ | ------------------------------------ |
| **Withdraw**  | Bất kỳ lúc nào trong kỳ  | `isEnrolled = false`, giữ lại record |
| **Re-enroll** | Đã withdraw trước đó     | `isEnrolled = true`                  |
| **Delete**    | Chỉ khi lớp chưa bắt đầu | Xóa hoàn toàn record                 |

**Q5: Class selector trong form khác hoạt động thế nào?**

- Hook: `useGetClasses()` với filter `isActive: true`
- Thường kết hợp với `semesterId` filter
- Component tham khảo: SlotFormDialog, AttendanceFilter

### 7.3 Error Codes Reference

| Error Code                       | HTTP | Mô tả                                  | Xử lý              |
| -------------------------------- | ---- | -------------------------------------- | ------------------ |
| `CLASS_NOT_FOUND`                | 404  | ID không tồn tại                       | Kiểm tra ID        |
| `CLASS_EXISTS`                   | 409  | Combo code+subject+semester đã tồn tại | Đổi code           |
| `CLASS_HAS_DEPENDENCIES`         | 409  | Có slots hoặc enrollments              | Xóa dependencies   |
| `CLASS_NOT_FINISHED`             | 409  | Lớp chưa kết thúc                      | Chờ hết slots      |
| `INACTIVE_CLASS_NOT_ALLOWED`     | 400  | Lớp không active                       | Activate lớp       |
| `INACTIVE_REFERENCE_NOT_ALLOWED` | 400  | Subject/Semester inactive              | Chọn active        |
| `ALREADY_ENROLLED`               | 409  | SV đã đăng ký                          | Không cần add      |
| `MAJOR_MISMATCH`                 | 400  | Major không phù hợp                    | Chọn SV đúng major |
| `SEMESTER_ENDED`                 | 400  | Học kỳ đã kết thúc                     | Không thể modify   |
| `CANNOT_DELETE_AFTER_START`      | 400  | Lớp đã bắt đầu                         | Dùng withdraw      |

---

## Tóm Tắt

### Điểm Chính Cần Nhớ

1. **Class là teaching unit** - Đơn vị giảng dạy thực tế, kết hợp Subject + Semester

2. **Unique constraint ba trường**:

   - (code + subject_id + semester_id) phải unique
   - Không thể có 2 lớp cùng code cho cùng subject trong cùng semester

3. **Enrollment có composite key**:

   - Primary Key: (class_id, student_user_id)
   - Một SV chỉ enrolled một lần trong một lớp

4. **Soft delete cho Enrollment**:

   - Withdraw: `isEnrolled = false` (giữ record)
   - Re-enroll: `isEnrolled = true`
   - Hard delete: Chỉ khi lớp chưa bắt đầu

5. **Deactivate Class có điều kiện**:

   - Phải chờ lớp kết thúc (last slot end time < now)
   - VN timezone: Asia/Ho_Chi_Minh

6. **Major validation cho Enrollment**:
   - SV chỉ được enroll nếu major thuộc subject's majors
   - Subject có relationship ManyToMany với Major

### Khi Trình Bày Hội Đồng

- **Giải thích vai trò**: Class như "lớp học thực tế" - nơi sinh viên và giảng viên gặp nhau
- **Demo CRUD**: Tạo lớp → Thêm sinh viên → Xem danh sách → Withdraw → Re-enroll
- **Nhấn mạnh validation**: Unique constraint, major matching, semester deadline
- **Business rules**: Deactivate condition, delete restrictions
- **Integration**: Liên kết với Subject, Semester, Slot, Attendance
- **So sánh**: Class vs Subject - cụ thể vs trừu tượng
