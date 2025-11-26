# Student Module - Tài Liệu Kỹ Thuật

> **Mục đích tài liệu**: Giúp người đọc hiểu và làm việc với module Student (Sinh viên) trong hệ thống FUACS - Hệ thống Điểm danh Tự động sử dụng Nhận diện Khuôn mặt.

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

### 1.1 Student là gì?

**Student (Sinh viên)** là đối tượng người dùng chính trong hệ thống FUACS. Mỗi sinh viên được định danh bằng mã sinh viên (roll number), thuộc một chuyên ngành (major), và có thể đăng ký vào nhiều lớp học.

**StudentProfile** là bản ghi mở rộng của User, chứa thông tin đặc thù của sinh viên như mã sinh viên, chuyên ngành, và URL ảnh đại diện dùng cho nhận diện khuôn mặt.

### 1.2 Vai trò trong hệ thống FUACS

| Vai trò                    | Mô tả                                | Ví dụ                                    |
| -------------------------- | ------------------------------------ | ---------------------------------------- |
| **Identity Subject**       | Đối tượng được nhận diện khuôn mặt   | Sinh viên SE123456 được camera nhận diện |
| **Enrollment Participant** | Tham gia đăng ký lớp học             | Đăng ký lớp SE1234 cho môn PRO192        |
| **Attendance Target**      | Đối tượng điểm danh                  | Được đánh dấu có mặt/vắng trong slot     |
| **System User**            | Người dùng hệ thống với role STUDENT | Xem lịch học, lịch sử điểm danh          |

### 1.3 Mối Quan Hệ với Các Module Khác

```
                         ┌─────────────────┐
                         │      USER       │
                         │  (Tài khoản)    │
                         └────────┬────────┘
                                  │ 1:1
                                  ▼
                         ┌─────────────────┐
                         │ STUDENT PROFILE │
                         │  (Hồ sơ SV)     │
                         └────────┬────────┘
                                  │
         ┌────────────────────────┼────────────────────────┐
         │                        │                        │
         ▼                        ▼                        ▼
┌─────────────────┐      ┌─────────────────┐      ┌─────────────────┐
│      MAJOR      │      │   ENROLLMENT    │      │ FACE EMBEDDING  │
│  (Chuyên ngành) │      │  (Đăng ký lớp)  │      │ (Vector khuôn)  │
└─────────────────┘      └────────┬────────┘      └─────────────────┘
                                  │
                                  ▼
                         ┌─────────────────┐
                         │ ACADEMIC CLASS  │
                         │   (Lớp học)     │
                         └────────┬────────┘
                                  │
                                  ▼
                         ┌─────────────────┐
                         │   ATTENDANCE    │
                         │   (Điểm danh)   │
                         └─────────────────┘
```

**Giải thích mối quan hệ**:

- **User ↔ StudentProfile**: Quan hệ OneToOne - Mỗi tài khoản sinh viên có một hồ sơ
- **StudentProfile → Major**: Quan hệ ManyToOne - Nhiều sinh viên thuộc cùng chuyên ngành
- **StudentProfile → Enrollment**: Quan hệ OneToMany - Sinh viên đăng ký nhiều lớp
- **StudentProfile → FaceEmbedding**: Quan hệ OneToMany - Sinh viên có nhiều version embedding

---

## 2. Kiến Trúc Hệ Thống

### 2.1 Tổng Quan Kiến Trúc

```
┌─────────────────────────────────────────────────────────────────────┐
│                          FRONTEND (Next.js)                         │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │  ADMIN VIEWS                    STUDENT VIEWS               │   │
│  │  ┌─────────────────┐            ┌─────────────────┐        │   │
│  │  │ /admin/         │            │ /student/       │        │   │
│  │  │ users-roles     │            │ dashboard       │        │   │
│  │  │ (Students tab)  │            │ profile         │        │   │
│  │  └────────┬────────┘            │ schedule        │        │   │
│  │           │                     │ attendance      │        │   │
│  │  ┌────────▼────────┐            └────────┬────────┘        │   │
│  │  │ /admin/classes/ │                     │                 │   │
│  │  │ [id]/students   │                     │                 │   │
│  │  └────────┬────────┘                     │                 │   │
│  └───────────┼──────────────────────────────┼─────────────────┘   │
│              │                              │                      │
│              └──────────────┬───────────────┘                      │
│                             │ React Query Hooks                    │
└─────────────────────────────┼──────────────────────────────────────┘
                              │ HTTP/REST
                              ▼
┌─────────────────────────────────────────────────────────────────────┐
│                        BACKEND (Spring Boot)                        │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────────┐ │
│  │ StudentProfile  │  │ StudentProfile  │  │  StudentProfile     │ │
│  │   Controller    │──│    Service      │──│    Repository       │ │
│  └─────────────────┘  └────────┬────────┘  └─────────────────────┘ │
│                                │                                    │
│                       ┌────────┼────────┐                          │
│                       ▼        ▼        ▼                          │
│               ┌───────────┐ ┌───────┐ ┌───────────────┐            │
│               │ Enrollment│ │ Email │ │ FaceEmbedding │            │
│               │  Service  │ │Service│ │   Service     │            │
│               └───────────┘ └───────┘ └───────────────┘            │
└─────────────────────────────────┼──────────────────────────────────┘
                                  │ JDBC
                                  ▼
                   ┌───────────────────────────┐
                   │       PostgreSQL          │
                   │ users + student_profiles  │
                   │     + face_embeddings     │
                   └───────────────────────────┘
```

### 2.2 Cấu Trúc Thư Mục

**Backend** (`backend/src/main/java/com/fuacs/backend/`):

```
├── controller/
│   ├── StudentProfileController.java   # REST API (11 endpoints)
│   └── StudentsController.java         # Student-specific endpoints
├── service/
│   ├── StudentProfileService.java      # Business logic
│   └── FaceEmbeddingService.java       # Face embedding management
├── entity/
│   ├── User.java                       # Base user entity
│   ├── StudentProfile.java             # Student profile (1:1 with User)
│   └── FaceEmbedding.java              # Face embedding vectors
├── repository/
│   ├── StudentProfileRepository.java   # JPA Repository
│   ├── FaceEmbeddingRepository.java    # Embedding queries
│   ├── custom/
│   │   └── CustomStudentProfileRepository.java
│   └── impl/
│       └── StudentProfileRepositoryImpl.java
├── dto/
│   ├── request/
│   │   ├── StudentProfileCreateRequest.java
│   │   ├── StudentProfileUpdateRequest.java
│   │   ├── StudentProfileSearchRequest.java
│   │   └── StudentProfileCsvRow.java
│   ├── response/
│   │   └── StudentProfileDTO.java
│   └── mapper/
│       └── StudentProfileMapper.java
```

**Frontend** (`frontend-web/`):

```
├── app/
│   ├── admin/
│   │   ├── users-roles/
│   │   │   └── page.tsx                  # Students tab management
│   │   └── classes/[id]/students/
│   │       └── page.tsx                  # Class enrollments
│   └── student/
│       ├── dashboard/page.tsx            # Student dashboard
│       ├── profile/page.tsx              # View own profile
│       ├── schedule/page.tsx             # Weekly schedule
│       └── attendance/history/page.tsx   # Attendance history
├── components/admin/
│   ├── users-roles/
│   │   ├── student-table.tsx             # Student list table
│   │   ├── student-columns.tsx           # Column definitions
│   │   ├── student-dialogs.tsx           # Create/Edit dialogs
│   │   └── student-attendance-history-view.tsx
│   └── classes/
│       ├── add-student-dialog.tsx        # Add to class
│       ├── class-students-table.tsx      # Enrollment table
│       └── view-student-dialog.tsx       # View details
├── hooks/api/
│   ├── useStudentProfiles.ts             # Main student hooks
│   ├── useStudentDashboard.ts            # Dashboard data
│   ├── useStudentAttendanceHistory.ts    # Attendance history
│   ├── useStudentRecentAttendance.ts     # Recent records
│   └── useStudentSubjects.ts             # Enrolled subjects
├── types/
│   └── index.ts                          # TypeScript definitions
└── lib/
    ├── zod-schemas.ts                    # Validation schemas
    └── adapters/
        └── student-profile-adapter.ts    # API to UI mapping
```

---

## 3. Backend Implementation

### 3.1 Database Schema

**Table: `users`** (Base table)

```sql
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(128) NOT NULL UNIQUE,
    full_name VARCHAR(150) NOT NULL,
    password_hash VARCHAR(255) NULL
);
```

**Table: `student_profiles`**

```sql
CREATE TABLE student_profiles (
    user_id INTEGER PRIMARY KEY,
    major_id SMALLINT NOT NULL,
    roll_number VARCHAR(20) NOT NULL UNIQUE,
    base_photo_url VARCHAR(255) NULL,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (major_id) REFERENCES majors(id)
);

CREATE UNIQUE INDEX idx_student_profiles_roll_number ON student_profiles(roll_number);
```

**Table: `face_embeddings`**

```sql
CREATE TABLE face_embeddings (
    id SERIAL PRIMARY KEY,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    student_user_id INTEGER NOT NULL,
    version INTEGER NOT NULL,
    embedding_vector vector(512) NOT NULL,
    FOREIGN KEY (student_user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Chỉ 1 embedding active per student
CREATE UNIQUE INDEX idx_face_embeddings_student_active
    ON face_embeddings(student_user_id) WHERE is_active = true;

-- Vector similarity search
CREATE INDEX idx_face_embeddings_vector
    ON face_embeddings USING ivfflat (embedding_vector vector_cosine_ops)
    WITH (lists = 100);
```

**Entity Class**: `StudentProfile.java`

| Field        | Type        | Constraints        | Mô tả              |
| ------------ | ----------- | ------------------ | ------------------ |
| `userId`     | Integer     | PK, FK→users       | ID từ bảng users   |
| `user`       | User        | OneToOne, MapsId   | Liên kết tài khoản |
| `major`      | Major       | ManyToOne, NotNull | Chuyên ngành       |
| `rollNumber` | String(20)  | Unique, NotNull    | Mã sinh viên       |
| `baseUrl`    | String(255) | Nullable           | URL ảnh đại diện   |

**Entity Class**: `FaceEmbedding.java`

| Field             | Type       | Constraints        | Mô tả                       |
| ----------------- | ---------- | ------------------ | --------------------------- |
| `id`              | Integer    | PK, Auto           | ID tự động tăng             |
| `student`         | User       | ManyToOne, NotNull | Sinh viên sở hữu            |
| `version`         | Integer    | NotNull            | Version number (1, 2, 3...) |
| `embeddingVector` | float[512] | NotNull            | Vector 512 chiều            |
| `isActive`        | Boolean    | Default: true      | Chỉ 1 active per student    |

### 3.2 REST API Endpoints

**StudentProfileController** - Base Path: `/api/v1/student-profiles`

| Method | Endpoint                         | Permission                           | Mô tả                            |
| ------ | -------------------------------- | ------------------------------------ | -------------------------------- |
| GET    | `/`                              | USER_READ_LIST                       | Danh sách sinh viên (phân trang) |
| GET    | `/{id}`                          | USER_READ_DETAIL or OWN_PROFILE_READ | Chi tiết sinh viên               |
| POST   | `/`                              | USER_CREATE                          | Tạo sinh viên mới                |
| PUT    | `/{id}`                          | USER_UPDATE_INFO                     | Cập nhật sinh viên               |
| DELETE | `/{id}`                          | USER_DELETE_HARD                     | Xóa sinh viên                    |
| POST   | `/import`                        | STUDENT_IMPORT                       | Import từ CSV                    |
| POST   | `/bulk-upload-photos-embeddings` | STUDENT_IMPORT                       | Upload ảnh + embeddings          |
| GET    | `/{id}/classes`                  | CLASS_READ                           | Lớp học của sinh viên            |
| GET    | `/{id}/subjects`                 | OWN_SUBJECT_READ                     | Môn học trong kỳ                 |
| GET    | `/{id}/slots`                    | SLOT_READ                            | Lịch học của sinh viên           |
| GET    | `/{id}/attendance-history`       | -                                    | Lịch sử điểm danh                |

**StudentsController** - Base Path: `/api/v1/students`

| Method | Endpoint                 | Permission       | Mô tả                         |
| ------ | ------------------------ | ---------------- | ----------------------------- |
| GET    | `/me/attendance-recent`  | -                | 10 records điểm danh gần nhất |
| GET    | `/{studentId}/semesters` | USER_READ_DETAIL | Danh sách kỳ học đã đăng ký   |

### 3.3 Data Transfer Objects (DTOs)

**Create Request:**

```java
// StudentProfileCreateRequest
{
  "username": "se123456",           // Bắt buộc, unique, max 50
  "email": "se123456@fpt.edu.vn",   // Bắt buộc, unique, valid email
  "fullName": "Nguyen Van A",       // Bắt buộc, max 150
  "rollNumber": "SE123456",         // Bắt buộc, unique, pattern ^[A-Z0-9]+$
  "majorId": 1                      // Bắt buộc, FK to majors
}
```

**Update Request:**

```java
// StudentProfileUpdateRequest
{
  "username": "se123456",           // KHÔNG thể thay đổi
  "email": "newemail@fpt.edu.vn",   // Có thể thay đổi
  "fullName": "Nguyen Van B",       // Có thể thay đổi
  "rollNumber": "SE123456",         // Có thể thay đổi (nếu unique)
  "majorId": 2,                     // Có thể thay đổi
  "isActive": true                  // Trạng thái hoạt động
}
```

**Response DTO:**

```java
// StudentProfileDTO
{
  "userId": 5,
  "username": "se123456",
  "email": "se123456@fpt.edu.vn",
  "fullName": "Nguyen Van A",
  "rollNumber": "SE123456",
  "major": {
    "id": 1,
    "name": "Software Engineering",
    "code": "SE",
    "isActive": true
  },
  "roles": ["STUDENT"],
  "baseUrl": "/photos/se123456.jpg",
  "photoUrl": "https://storage.../se123456.jpg",
  "hasActiveEmbedding": true,
  "canUseFaceRecognition": true,
  "isActive": true,
  "createdAt": "2024-01-15T10:30:00Z",
  "updatedAt": "2024-01-15T10:30:00Z"
}
```

### 3.4 Service Layer

**StudentProfileService Methods:**

| Method                      | Input                       | Output                     | Mô tả               |
| --------------------------- | --------------------------- | -------------------------- | ------------------- |
| `search(request)`           | StudentProfileSearchRequest | List\<StudentProfileDTO\>  | Tìm kiếm với filter |
| `count(request)`            | StudentProfileSearchRequest | Long                       | Đếm tổng            |
| `findById(id)`              | Integer                     | StudentProfileDTO          | Lấy chi tiết        |
| `create(request)`           | StudentProfileCreateRequest | StudentProfileDTO          | Tạo mới + gửi email |
| `update(id, request)`       | Integer, UpdateRequest      | StudentProfileDTO          | Cập nhật            |
| `delete(id)`                | Integer                     | void                       | Xóa (cascade)       |
| `importFromCsv(file, mode)` | MultipartFile, String       | ImportResultDTO            | Import hàng loạt    |
| `searchBySemesterId(...)`   | Short, SearchRequest        | List\<StudentSemesterDTO\> | SV trong kỳ         |

**FaceEmbeddingService Methods:**

| Method                          | Input                        | Output                    | Mô tả                 |
| ------------------------------- | ---------------------------- | ------------------------- | --------------------- |
| `generateAndSaveEmbedding(...)` | userId, photoPath, videoPath | FaceEmbedding             | Tạo từ ảnh/video      |
| `saveEmbedding(userId, vector)` | Integer, float[]             | FaceEmbedding             | Lưu trực tiếp         |
| `getActiveEmbedding(userId)`    | Integer                      | Optional\<FaceEmbedding\> | Lấy embedding active  |
| `hasActiveEmbedding(userId)`    | Integer                      | boolean                   | Kiểm tra có embedding |

### 3.5 Repository Layer

**StudentProfileRepository - Custom Queries:**

```java
// === Kiểm tra unique ===
boolean existsByRollNumber(String rollNumber);
boolean existsByRollNumberAndUserIdNot(String rollNumber, Integer userId);

// === Lookup ===
StudentProfile findByRollNumber(String rollNumber);
StudentProfile findByRollNumberWithUserAndMajor(String rollNumber);

// === Search ===
List<StudentProfile> searchStudents(String search, Pageable pageable);
Long countAllStudents(String search);

// === Semester statistics ===
Integer countTotalStudentsBySemester(Short semesterId);
Integer countActiveStudentsBySemester(Short semesterId);
Double calculateAverageStudentsPerClassBySemester(Short semesterId);

// === Batch operations ===
List<StudentProfile> findAllByUserIdsWithMajor(Collection<Integer> userIds);
```

**FaceEmbeddingRepository:**

```java
Optional<FaceEmbedding> findByStudentIdAndIsActiveTrue(Integer studentId);
List<FaceEmbedding> findByStudentIdOrderByVersionDesc(Integer studentId);
void deactivateByStudentId(Integer studentId);  // @Modifying query
boolean existsByStudentIdAndIsActiveTrue(Integer studentId);
```

---

## 4. Frontend Implementation

### 4.1 Trang Quản Lý Sinh Viên (Admin)

**Route**: `/admin/users-roles` (Tab Students)
**Quyền truy cập**: DATA_OPERATOR
**File chính**: `frontend-web/app/admin/users-roles/page.tsx`

**Giao diện người dùng:**

```
┌─────────────────────────────────────────────────────────────────────┐
│  Users & Roles                                                       │
│  Manage user accounts and their roles                               │
├─────────────────────────────────────────────────────────────────────┤
│  [ Students ]  [ Staffs ]                                           │
├─────────────────────────────────────────────────────────────────────┤
│  [Search...]  [Status ▼]  [Major ▼]  [Sort ▼]  [↑↓]                 │
│                                         [Import ▼] [+ Create]       │
├─────────────────────────────────────────────────────────────────────┤
│  Roll#    │ Name     │ Email     │ Major │ Role    │ Status │ ⋮    │
│───────────┼──────────┼───────────┼───────┼─────────┼────────┼──────│
│  SE123456 │ Nguyen A │ a@fpt...  │  SE   │ Student │ Active │ ⋮    │
│  SE123457 │ Tran B   │ b@fpt...  │  AI   │ Student │ Active │ ⋮    │
│  SE123458 │ Le C     │ c@fpt...  │  SE   │ Student │Inactive│ ⋮    │
├─────────────────────────────────────────────────────────────────────┤
│  Showing 1 - 10 of 150 items            ◀ [1] [2] [3] ... [15] ▶   │
└─────────────────────────────────────────────────────────────────────┘
```

**Tính năng:**

| Tính năng  | Mô tả                                       |
| ---------- | ------------------------------------------- |
| Tìm kiếm   | Theo tên, mã SV, email (debounced 500ms)    |
| Lọc Status | Active/Inactive/All                         |
| Lọc Major  | Searchable dropdown, multi-select           |
| Sắp xếp    | Full Name, Roll Number, Email, Major        |
| Import     | Student Profiles CSV hoặc Photos+Embeddings |
| Phân trang | 10 items/trang                              |

**Action Menu:**

- Edit Profile - Mở dialog chỉnh sửa
- View Attendance - Xem lịch sử điểm danh

### 4.2 Trang Profile Sinh Viên

**Route**: `/student/profile`
**Quyền truy cập**: STUDENT (own profile only)
**File chính**: `frontend-web/app/student/profile/page.tsx`

**Giao diện:**

```
┌─────────────────────────────────────────────────────────────────────┐
│  ┌─────────┐                                                        │
│  │  Avatar │   Nguyen Van A                                         │
│  │         │   SE123456                                              │
│  └─────────┘   Student                                               │
├─────────────────────────────────────────────────────────────────────┤
│  [ Personal Info ]  [ Security ]                                     │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  Full Name:     Nguyen Van A                                         │
│  Roll Number:   SE123456                                             │
│  Username:      se123456                                             │
│  Email:         se123456@fpt.edu.vn                                  │
│                                                                      │
│  Major Code:    SE                                                   │
│  Major Name:    [Software Engineering]                               │
│                                                                      │
│  ⓘ Student profile is managed by administrators                     │
│                                                                      │
│  Created:       Jan 15, 2024                                         │
│  Last Updated:  Jan 20, 2024                                         │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

**Tabs:**

- **Personal Info**: Thông tin cá nhân (read-only)
- **Security**: Đổi mật khẩu

### 4.3 Trang Lịch Học

**Route**: `/student/schedule`
**File chính**: `frontend-web/app/student/schedule/page.tsx`

**Tính năng:**

- Xem lịch tuần (Thứ 2 - Chủ Nhật)
- Điều hướng: Previous/Next/Today
- Click slot xem chi tiết
- URL lưu ngày tham chiếu: `?date=yyyy-MM-dd`

### 4.4 Trang Lịch Sử Điểm Danh

**Route**: `/student/attendance/history`
**File chính**: `frontend-web/app/student/attendance/history/page.tsx`

**Giao diện:**

```
┌─────────────────────────────────────────────────────────────────────┐
│  Attendance History                                                  │
├─────────────────────────────────────────────────────────────────────┤
│  [Semester ▼]  [Subject ▼]                                          │
├─────────────────────────────────────────────────────────────────────┤
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐                    │
│  │ Total: 45   │ │ Present: 42 │ │ Absent: 3   │                    │
│  └─────────────┘ └─────────────┘ └─────────────┘                    │
├─────────────────────────────────────────────────────────────────────┤
│  Date       │ Subject  │ Class  │ Room  │ Status  │ Method         │
│─────────────┼──────────┼────────┼───────┼─────────┼────────────────│
│  01/09/24   │ PRO192   │ SE1234 │  A101 │ Present │ Face Recognition│
│  02/09/24   │ PRO192   │ SE1234 │  A101 │ Present │ Manual          │
│  03/09/24   │ DSA201   │ AI2001 │  B202 │ Absent  │ -               │
└─────────────────────────────────────────────────────────────────────┘
```

### 4.5 Component Structure

```
AdminUsersRolesPage
│
├── Tabs
│   ├── Students Tab
│   │   ├── Controls Section
│   │   │   ├── Search Input (debounced)
│   │   │   ├── Status Select
│   │   │   ├── Major Popover (searchable)
│   │   │   ├── Sort Select + Order
│   │   │   ├── Import Popover (2 options)
│   │   │   └── Create Button
│   │   │
│   │   ├── StudentTable
│   │   │   ├── student-columns.tsx (7 columns)
│   │   │   └── Pagination
│   │   │
│   │   ├── CreateStudentDialog
│   │   │   ├── Full Name Input
│   │   │   ├── Roll Number Input (auto-uppercase)
│   │   │   ├── Username Input
│   │   │   ├── Email Input
│   │   │   └── Major Popover
│   │   │
│   │   ├── EditStudentDialog
│   │   │   ├── Roll Number (disabled)
│   │   │   ├── Username (disabled)
│   │   │   ├── Email Input
│   │   │   ├── Full Name Input
│   │   │   ├── Major Popover
│   │   │   └── Active Switch
│   │   │
│   │   └── AttendanceHistoryDialog
│   │
│   └── Staffs Tab (...)
│
ClassStudentsPage (/admin/classes/[id]/students)
│
├── Class Info Header
├── Stats Cards (Enrolled, Withdrawn, Active Slots)
├── Controls (Search, Status, Sort)
├── ClassStudentsTable
│   └── Action Menu (View, Withdraw, Re-enroll, Delete)
├── AddStudentDialog
├── ViewStudentDialog
├── WithdrawStudentDialog
├── ReEnrollStudentDialog
└── DeleteStudentDialog
```

### 4.6 API Hooks (React Query)

**File**: `frontend-web/hooks/api/useStudentProfiles.ts`

| Hook                                 | Loại     | Chức năng           | Caching                  |
| ------------------------------------ | -------- | ------------------- | ------------------------ |
| `useGetStudentProfiles(params)`      | Query    | Danh sách sinh viên | 5 phút                   |
| `useGetStudentProfile(id)`           | Query    | Chi tiết sinh viên  | 5 phút                   |
| `useCreateStudentProfile()`          | Mutation | Tạo mới             | Invalidate list          |
| `useUpdateStudentProfile()`          | Mutation | Cập nhật            | Invalidate list + detail |
| `useDeleteStudentProfile()`          | Mutation | Xóa                 | Invalidate list          |
| `useGetStudentClasses(id, params)`   | Query    | Lớp học             | 5 phút                   |
| `useGetStudentSlots(id, params)`     | Query    | Lịch học            | 5 phút                   |
| `useGetStudentAttendanceHistory(id)` | Query    | Điểm danh           | 2 phút                   |
| `useImportStudentProfiles()`         | Mutation | Import CSV          | Invalidate list          |
| `useImportPhotosEmbeddings()`        | Mutation | Import ảnh          | Invalidate list          |

**Các hooks bổ sung:**

| Hook                                        | File                           | Chức năng           |
| ------------------------------------------- | ------------------------------ | ------------------- |
| `useStudentDashboard(semesterId)`           | useStudentDashboard.ts         | Dashboard data      |
| `useStudentRecentAttendance(limit)`         | useStudentRecentAttendance.ts  | 10 records gần nhất |
| `useStudentSubjects(studentId, semesterId)` | useStudentSubjects.ts          | Môn học trong kỳ    |
| `useStudentAttendanceHistory(...)`          | useStudentAttendanceHistory.ts | Lịch sử chi tiết    |

**Query Keys:**

```typescript
studentProfiles: {
  all: ["student-profiles"],
  detail: (id) => ["student-profiles", id],
  classes: (id) => ["student-profiles", id, "classes"],
  attendanceHistory: (id) => ["student-profiles", id, "attendance-history"],
  subjects: (id) => ["student-profiles", id, "subjects"],
  slots: (id) => ["student-profiles", id, "slots"],
}
```

### 4.7 TypeScript Type Definitions

```typescript
// Core Student Type
interface StudentProfile {
  userId: number;
  username: string;
  email: string;
  fullName: string;
  rollNumber: string;
  major: {
    id: number;
    name: string;
    code: string;
    isActive: boolean;
  };
  roles: string[];
  baseUrl: string | null;
  photoUrl: string | null;
  hasActiveEmbedding: boolean;
  canUseFaceRecognition: boolean;
  isActive: boolean;
  createdAt: string;
  updatedAt: string;
}

// UI Table Row Type
interface StudentUserRow {
  id: number; // userId
  rollNumber: string;
  username: string;
  fullName: string;
  email: string;
  major: string; // major.code
  majorId?: number;
  isActive: boolean;
  createdAt: string;
  lastActiveAt?: string;
}

// Create Payload
interface CreateStudentProfilePayload {
  username: string;
  email: string;
  fullName: string;
  rollNumber: string;
  majorId: number;
}

// Update Payload
interface UpdateStudentProfilePayload extends CreateStudentProfilePayload {
  isActive: boolean;
}
```

### 4.8 Form Validation (Zod Schema)

**Create Student Form:**

| Field        | Validation                              | Error Message                       |
| ------------ | --------------------------------------- | ----------------------------------- |
| `fullName`   | Required                                | "Full name is required"             |
| `rollNumber` | Required, pattern `^[A-Z0-9]+$`, max 20 | "Only uppercase letters and digits" |
| `username`   | Required, max 50                        | "Username is required"              |
| `email`      | Required, valid email, max 128          | "Invalid email format"              |
| `majorId`    | Required, min 1                         | "Major is required"                 |

**Edit Student Form:**

| Field        | Validation     | Editable      |
| ------------ | -------------- | ------------- |
| `rollNumber` | Same as create | No (disabled) |
| `username`   | Same as create | No (disabled) |
| `email`      | Same as create | Yes           |
| `fullName`   | Same as create | Yes           |
| `majorId`    | Same as create | Yes           |
| `isActive`   | Boolean        | Yes           |

---

## 5. Luồng Xử Lý Nghiệp Vụ

### 5.1 Luồng Tạo Sinh Viên Mới

```
┌──────────┐      ┌──────────────────┐      ┌──────────────────┐      ┌──────────┐
│  Admin   │      │     Frontend     │      │     Backend      │      │ Database │
└────┬─────┘      └────────┬─────────┘      └────────┬─────────┘      └────┬─────┘
     │                     │                         │                     │
     │ 1. Click Create     │                         │                     │
     │────────────────────>│                         │                     │
     │                     │                         │                     │
     │ 2. Fill form        │                         │                     │
     │   fullName          │                         │                     │
     │   rollNumber        │                         │                     │
     │   username          │                         │                     │
     │   email             │                         │                     │
     │   majorId           │                         │                     │
     │────────────────────>│                         │                     │
     │                     │                         │                     │
     │                     │ 3. Zod Validation       │                     │
     │                     │                         │                     │
     │                     │ 4. POST /student-profiles                     │
     │                     │────────────────────────>│                     │
     │                     │                         │                     │
     │                     │                         │ 5. Validate:        │
     │                     │                         │ - username unique?  │
     │                     │                         │ - email unique?     │
     │                     │                         │ - rollNumber unique?│
     │                     │                         │ - major exists?     │
     │                     │                         │                     │
     │                     │                         │ 6. Generate password│
     │                     │                         │    UUID.randomUUID()│
     │                     │                         │                     │
     │                     │                         │ 7. Create User      │
     │                     │                         │────────────────────>│
     │                     │                         │                     │
     │                     │                         │ 8. Create Profile   │
     │                     │                         │────────────────────>│
     │                     │                         │                     │
     │                     │                         │ 9. Assign STUDENT   │
     │                     │                         │    role             │
     │                     │                         │────────────────────>│
     │                     │                         │                     │
     │                     │                         │ 10. Send email      │
     │                     │                         │     with password   │
     │                     │                         │                     │
     │                     │ 11. Return DTO          │                     │
     │                     │<────────────────────────│                     │
     │                     │                         │                     │
     │ 12. Toast success   │                         │                     │
     │     Refresh list    │                         │                     │
     │<────────────────────│                         │                     │
```

### 5.2 Luồng Import Sinh Viên từ CSV

```
Admin upload CSV file
    │
    ▼
POST /student-profiles/import
    │   file: MultipartFile
    │   mode: "AddOnly" | "AddAndUpdate"
    │
    ▼
Parse CSV headers:
    │   full_name, email, username, roll_number, major_code[, status, password]
    │
    ▼
Deduplicate by roll_number (first occurrence wins)
    │
    ▼
For each row (REQUIRES_NEW transaction):
    │
    ├─── Validate row data
    │         │
    │         ├── Invalid format? → Add to errors, continue
    │         │
    │         └── Valid → Continue processing
    │
    ├─── Lookup major by code
    │         │
    │         └── Not found? → Error: MAJOR_NOT_FOUND
    │
    ├─── Check if student exists (by roll_number)
    │         │
    │         ├── EXISTS + mode="AddOnly"
    │         │         └── Error: ROLL_NUMBER_EXISTS
    │         │
    │         ├── EXISTS + mode="AddAndUpdate"
    │         │         └── Update existing student
    │         │
    │         └── NOT EXISTS
    │                   └── Create new student
    │                       (no email sent if password provided)
    │
    └─── Commit row transaction

    ▼
Return ImportResultDTO:
    {
      "successCount": 95,
      "failureCount": 5,
      "errors": [
        {"rowNumber": 10, "errorCode": "ROLL_NUMBER_EXISTS", "message": "..."},
        {"rowNumber": 25, "errorCode": "MAJOR_NOT_FOUND", "message": "..."}
      ]
    }
```

### 5.3 Luồng Face Embedding

```
Admin upload photos + CSV mapping
    │
    ▼
POST /bulk-upload-photos-embeddings
    │   csvFile: roll_number, image_filename
    │   zipFile: containing image files
    │   mode: "AddOnly" | "AddAndUpdate"
    │
    ▼
For each row:
    │
    ├─── Find student by roll_number
    │         │
    │         └── Not found? → Error, continue
    │
    ├─── Extract image from ZIP
    │         │
    │         └── Not found? → Error, continue
    │
    ├─── Call Python backend
    │         │   POST /api/generate-embedding
    │         │   body: { image: base64 }
    │         │
    │         └── Response: { embedding: float[512] }
    │
    ├─── Validate embedding dimension == 512
    │
    ├─── Deactivate old embeddings (if any)
    │         │   UPDATE face_embeddings
    │         │   SET is_active = false
    │         │   WHERE student_user_id = ?
    │
    └─── Insert new embedding
              │   version = max(version) + 1
              │   is_active = true

    ▼
Return result with success/failure counts
```

### 5.4 Luồng Xem Lịch Sử Điểm Danh (Student)

```
Student navigate to /student/attendance/history
    │
    ▼
Auto-select current semester
    │
    ▼
GET /student-profiles/{id}/subjects?semesterId=X
    │   → List of enrolled subjects
    │
    ▼
Student selects subject (optional)
    │
    ▼
GET /student-profiles/{id}/attendance-history
    │   ?semesterId=X
    │   &subjectId=Y (optional)
    │
    ▼
Response:
    {
      "items": [
        {
          "slotId": 1,
          "slotDate": "2024-09-01",
          "slotCategory": "LECTURE",
          "className": "SE1234",
          "subjectCode": "PRO192",
          "attendanceStatus": "present",
          "method": "auto"  // face recognition
        },
        ...
      ],
      "summary": {
        "overall": {
          "totalSlots": 45,
          "presentCount": 42,
          "absentCount": 3,
          "attendanceRate": 93.33
        }
      }
    }
```

---

## 6. Business Rules & Validation

### 6.1 Student Profile Validation Rules

| Rule               | Mô tả                                   | Error Code                   | HTTP |
| ------------------ | --------------------------------------- | ---------------------------- | ---- |
| Username Unique    | Username phải duy nhất trong hệ thống   | `USERNAME_EXISTS`            | 409  |
| Email Unique       | Email phải duy nhất                     | `EMAIL_EXISTS`               | 409  |
| Roll Number Unique | Mã SV phải duy nhất                     | `ROLL_NUMBER_EXISTS`         | 409  |
| Roll Number Format | Chỉ UPPERCASE + digits (A-Z, 0-9)       | `INVALID_ROLL_NUMBER_FORMAT` | 400  |
| Major Required     | Phải có chuyên ngành                    | `MAJOR_NOT_FOUND`            | 404  |
| Username Immutable | Không thể thay đổi username sau khi tạo | `OPERATION_NOT_ALLOWED`      | 403  |

### 6.2 Face Embedding Rules

| Rule              | Mô tả                                     |
| ----------------- | ----------------------------------------- |
| Vector Dimension  | Embedding phải có đúng 512 dimensions     |
| One Active        | Chỉ 1 embedding active per student        |
| Version Increment | Mỗi lần update, version tăng (1, 2, 3...) |
| Deactivate Old    | Khi tạo mới, tất cả cũ bị deactivate      |

### 6.3 Enrollment Major Validation

Khi thêm sinh viên vào lớp:

```
Student.major.id MUST BE IN Subject.majors.map(m => m.id)
```

Ví dụ:

- Sinh viên có major = SE (Software Engineering)
- Lớp SE1234 thuộc môn PRO192
- Môn PRO192 có majors = [SE, AI]
- → OK, cho phép enroll

### 6.4 CSV Import Features

**Student Profiles CSV:**

```csv
full_name,email,username,roll_number,major_code[,status,password]
Nguyen Van A,a@fpt.edu.vn,se123456,SE123456,SE,true
Tran Van B,b@fpt.edu.vn,se123457,SE123457,AI,true,hashedpwd123
```

| Column      | Required | Format                 | Note                                |
| ----------- | -------- | ---------------------- | ----------------------------------- |
| full_name   | Yes      | Letters + spaces       | Pattern: `^[A-Za-z]+( [A-Za-z]+)*$` |
| email       | Yes      | Valid email            | Pattern: standard email             |
| username    | Yes      | Any string             | Max 50 chars                        |
| roll_number | Yes      | Uppercase alphanumeric | Pattern: `^[A-Z0-9]+$`              |
| major_code  | Yes      | Existing major code    | Must exist in majors table          |
| status      | No       | true/false             | Default: true                       |
| password    | No       | Pre-hashed             | If provided, no email sent          |

**Import Modes:**

| Mode           | Khi đã tồn tại | Khi chưa tồn tại |
| -------------- | -------------- | ---------------- |
| `AddOnly`      | Skip + Error   | Create new       |
| `AddAndUpdate` | Update         | Create new       |

### 6.5 Quy Tắc Cascade Delete

```
DELETE Student:
    │
    ├─── DELETE student_profiles (user_id = ?)
    │
    ├─── DELETE face_embeddings (student_user_id = ?)
    │
    ├─── DELETE enrollments (student_user_id = ?)
    │
    └─── DELETE users (id = ?)
```

**Lưu ý:**

- Không thể xóa nếu có attendance records
- Cần kiểm tra foreign key constraints

---

## 7. Hướng Dẫn Phát Triển

### 7.1 Danh Sách File Quan Trọng

**Backend** (theo thứ tự nên đọc):

| #   | File                                           | Mô tả                 |
| --- | ---------------------------------------------- | --------------------- |
| 1   | `entity/User.java`                             | Base user entity      |
| 2   | `entity/StudentProfile.java`                   | Student profile (1:1) |
| 3   | `entity/FaceEmbedding.java`                    | Face vectors          |
| 4   | `dto/response/StudentProfileDTO.java`          | Response format       |
| 5   | `dto/request/StudentProfileCreateRequest.java` | Input validation      |
| 6   | `service/StudentProfileService.java`           | Business logic        |
| 7   | `service/FaceEmbeddingService.java`            | Embedding logic       |
| 8   | `repository/StudentProfileRepository.java`     | Queries               |
| 9   | `controller/StudentProfileController.java`     | API endpoints         |

**Frontend** (theo thứ tự nên đọc):

| #   | File                                               | Mô tả                  |
| --- | -------------------------------------------------- | ---------------------- |
| 1   | `types/index.ts`                                   | TypeScript definitions |
| 2   | `hooks/api/useStudentProfiles.ts`                  | Main API hooks         |
| 3   | `app/admin/users-roles/page.tsx`                   | Admin management       |
| 4   | `components/admin/users-roles/student-table.tsx`   | Table component        |
| 5   | `components/admin/users-roles/student-dialogs.tsx` | Create/Edit forms      |
| 6   | `app/student/profile/page.tsx`                     | Student own view       |
| 7   | `lib/adapters/student-profile-adapter.ts`          | API→UI mapping         |

### 7.2 FAQ - Câu Hỏi Thường Gặp

**Q1: Student khác User như thế nào?**

| Aspect  | User                       | StudentProfile             |
| ------- | -------------------------- | -------------------------- |
| Vai trò | Tài khoản đăng nhập        | Thông tin mở rộng          |
| Quan hệ | 1 User có thể có 1 Profile | Profile thuộc 1 User       |
| Fields  | username, email, password  | rollNumber, major, baseUrl |
| Role    | Có thể có nhiều roles      | Luôn có role STUDENT       |

**Q2: Tại sao không thay đổi được username?**

- Username là định danh đăng nhập
- Thay đổi sẽ ảnh hưởng đến audit logs, history
- Error: `OPERATION_NOT_ALLOWED`

**Q3: Face embedding hoạt động thế nào?**

1. Ảnh sinh viên được upload
2. Python backend (InsightFace buffalo_l) tạo vector 512 chiều
3. Vector được lưu vào PostgreSQL với extension pgvector
4. Khi điểm danh: camera → face → vector → cosine similarity search

**Q4: Tại sao có 2 biến hasActiveEmbedding và canUseFaceRecognition?**

| Field                   | Ý nghĩa                                  |
| ----------------------- | ---------------------------------------- |
| `hasActiveEmbedding`    | Có vector khuôn mặt active không         |
| `canUseFaceRecognition` | hasActiveEmbedding && isActive && có ảnh |

**Q5: Import CSV với password?**

- Nếu cột password có giá trị → dùng giá trị đó (pre-hashed)
- Không gửi email
- Dùng cho migration data từ hệ thống khác

### 7.3 Error Codes Reference

| Error Code                    | HTTP | Mô tả                      | Xử lý            |
| ----------------------------- | ---- | -------------------------- | ---------------- |
| `USER_NOT_FOUND`              | 404  | User ID không tồn tại      | Kiểm tra ID      |
| `STUDENT_PROFILE_NOT_FOUND`   | 404  | Profile không tồn tại      | Kiểm tra ID      |
| `ROLL_NUMBER_EXISTS`          | 409  | Mã SV đã tồn tại           | Đổi mã khác      |
| `USERNAME_EXISTS`             | 409  | Username đã tồn tại        | Đổi username     |
| `EMAIL_EXISTS`                | 409  | Email đã tồn tại           | Đổi email        |
| `INVALID_ROLL_NUMBER_FORMAT`  | 400  | Mã SV không hợp lệ         | Dùng A-Z, 0-9    |
| `MAJOR_NOT_FOUND`             | 404  | Chuyên ngành không tồn tại | Chọn major khác  |
| `OPERATION_NOT_ALLOWED`       | 403  | Thao tác không được phép   | Kiểm tra quyền   |
| `FOREIGN_KEY_CONSTRAINT`      | 409  | Còn dữ liệu liên quan      | Xóa dependencies |
| `EMBEDDING_GENERATION_FAILED` | 500  | Không tạo được embedding   | Kiểm tra ảnh     |

---

## Tóm Tắt

### Điểm Chính Cần Nhớ

1. **Student = User + StudentProfile**:

   - User chứa thông tin đăng nhập
   - StudentProfile mở rộng với rollNumber, major, photoUrl

2. **OneToOne với MapsId**:

   - StudentProfile.userId = User.id
   - Cùng primary key

3. **Face Embedding versioning**:

   - Mỗi student có nhiều versions
   - Chỉ 1 version active tại một thời điểm
   - Version tự động increment

4. **Username immutable**:

   - Không thể thay đổi sau khi tạo
   - Là định danh duy nhất cho audit

5. **Major validation trong enrollment**:

   - Student.major PHẢI thuộc Subject.majors
   - Check trước khi cho phép đăng ký lớp

6. **CSV import với partial success**:
   - Mỗi row xử lý trong transaction riêng
   - Row lỗi không ảnh hưởng row khác

### Khi Trình Bày Hội Đồng

- **Giải thích kiến trúc**: User-Profile separation, Face embedding
- **Demo CRUD**: Tạo SV → Import CSV → Upload ảnh → Xem profile
- **Face recognition flow**: Ảnh → Vector → Similarity search → Attendance
- **Nhấn mạnh validation**: Unique constraints, major matching
- **Security**: Password generation, email notification, role-based access
- **Integration**: Enrollment, Attendance, Dashboard
