# Subject Module - Tài Liệu Kỹ Thuật

> **Mục đích tài liệu**: Giúp người đọc hiểu và làm việc với module Subject (Môn học) trong hệ thống FUACS - Hệ thống Điểm danh Tự động sử dụng Nhận diện Khuôn mặt.

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

### 1.1 Subject là gì?

**Subject (Môn học)** là đơn vị học thuật cơ bản trong hệ thống quản lý giáo dục đại học. Mỗi môn học có mã riêng biệt và có thể thuộc về nhiều ngành học khác nhau. Các lớp học (AcademicClass) được mở dựa trên môn học.

### 1.2 Vai trò trong hệ thống FUACS

Trong hệ thống FUACS, **Subject Module** đóng vai trò **curriculum module** với các chức năng:

| Vai trò                | Mô tả                               | Ví dụ                                    |
| ---------------------- | ----------------------------------- | ---------------------------------------- |
| **Class Foundation**   | Cơ sở để mở các lớp học             | Môn PRO192 → Mở 5 lớp trong kỳ Fall 2024 |
| **Major Connector**    | Kết nối nhiều ngành học             | PRO192 thuộc cả SE, AI, IS               |
| **Academic Reference** | Tham chiếu trong điểm danh, báo cáo | Thống kê điểm danh theo môn              |

### 1.3 Mối Quan Hệ với Các Module Khác

```
                              ┌─────────────────┐
                              │     SUBJECT     │
                              │   (Môn học)     │
                              └────────┬────────┘
                                       │
            ┌──────────────────────────┼──────────────────────────┐
            │                          │                          │
            ▼                          ▼                          ▼
   ┌─────────────────┐       ┌─────────────────┐       ┌─────────────────┐
   │      MAJOR      │       │ ACADEMIC CLASS  │       │ EXAM SLOT       │
   │   (Ngành học)   │       │   (Lớp học)     │       │  SUBJECT        │
   └─────────────────┘       └────────┬────────┘       └─────────────────┘
                                      │
                    ┌─────────────────┼─────────────────┐
                    │                 │                 │
                    ▼                 ▼                 ▼
           ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐
           │   ENROLLMENT    │ │      SLOT       │ │   ATTENDANCE    │
           │(Đăng ký học)    │ │  (Buổi học)     │ │   (Điểm danh)   │
           └─────────────────┘ └─────────────────┘ └─────────────────┘
```

**Giải thích mối quan hệ**:

- **Subject ↔ Major**: Quan hệ ManyToMany - Một môn có thể thuộc nhiều ngành, một ngành có nhiều môn
- **Subject → AcademicClass**: Quan hệ OneToMany - Một môn có nhiều lớp học
- **Subject → ExamSlotSubject**: Quan hệ OneToMany - Một môn có thể trong nhiều ca thi (soft delete tracked)

---

## 2. Kiến Trúc Hệ Thống

### 2.1 Tổng Quan Kiến Trúc

Hệ thống FUACS sử dụng kiến trúc **Client-Server** với:

- **Backend**: Spring Boot (Java) - RESTful API
- **Frontend**: Next.js (TypeScript/React) - Single Page Application

```
┌─────────────────────────────────────────────────────────────────────┐
│                          FRONTEND (Next.js)                         │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐                 │
│  │    Pages    │  │ Components  │  │   Hooks     │                 │
│  │  /admin/    │  │  subject-   │  │   useGet    │                 │
│  │  subjects   │──│  table.tsx  │──│  Subjects   │                 │
│  └─────────────┘  └─────────────┘  └──────┬──────┘                 │
└────────────────────────────────────────────┼────────────────────────┘
                                             │ HTTP/REST
                                             ▼
┌─────────────────────────────────────────────────────────────────────┐
│                        BACKEND (Spring Boot)                        │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌───────────┐  │
│  │ Controller  │  │   Service   │  │ Repository  │  │  Entity   │  │
│  │ REST API    │──│  Business   │──│    JPA      │──│   JPA     │  │
│  │ Endpoints   │  │   Logic     │  │  Queries    │  │  Models   │  │
│  └─────────────┘  └─────────────┘  └──────┬──────┘  └───────────┘  │
└────────────────────────────────────────────┼────────────────────────┘
                                             │ JDBC
                                             ▼
                                    ┌─────────────────┐
                                    │   PostgreSQL    │
                                    │    Database     │
                                    └─────────────────┘
```

### 2.2 Cấu Trúc Thư Mục

**Backend** (`backend/src/main/java/com/fuacs/backend/`):

```
├── controller/
│   └── SubjectController.java          # REST API endpoints (7 endpoints)
├── service/
│   └── SubjectService.java             # Business logic & validation
├── entity/
│   └── Subject.java                    # JPA Entity - ánh xạ table
├── repository/
│   ├── SubjectRepository.java          # JPA Repository interface
│   ├── custom/
│   │   └── CustomSubjectRepository.java  # Interface cho custom queries
│   └── impl/
│       └── SubjectRepositoryImpl.java  # Implementation custom queries
├── dto/
│   ├── request/
│   │   ├── SubjectCreateRequest.java   # Validation cho tạo mới
│   │   ├── SubjectUpdateRequest.java   # Validation cho cập nhật
│   │   ├── SubjectSearchRequest.java   # Params tìm kiếm
│   │   └── SubjectCsvRow.java          # Dữ liệu CSV import
│   ├── response/
│   │   └── SubjectDTO.java             # Response trả về client
│   └── mapper/
│       └── SubjectMapper.java          # MapStruct - chuyển đổi DTO/Entity
```

**Frontend** (`frontend-web/`):

```
├── app/admin/subjects/
│   └── page.tsx                        # Trang quản lý chính
├── components/admin/subjects/
│   ├── subject-table.tsx               # Component bảng dữ liệu
│   ├── subject-form-dialog.tsx         # Dialog form tạo/sửa
│   ├── subject-columns.tsx             # Định nghĩa cột cho table
│   ├── subject-pagination.tsx          # Component phân trang
│   ├── delete-subject-dialog.tsx       # Dialog xác nhận xóa
│   └── multi-select-majors.tsx         # Multi-select chọn ngành
├── hooks/api/
│   └── useSubjects.ts                  # Custom hooks gọi API (React Query)
├── types/
│   └── index.ts                        # TypeScript type definitions
└── lib/
    └── zod-schemas.ts                  # Zod validation schemas
```

---

## 3. Backend Implementation

### 3.1 Database Schema

**Table: `subjects`**

```sql
CREATE TABLE subjects (
    id SMALLSERIAL PRIMARY KEY,
    name VARCHAR(150) NOT NULL,
    code VARCHAR(20) NOT NULL UNIQUE,
    is_active BOOLEAN DEFAULT true NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
```

**Bảng liên kết: `subject_majors`** (ManyToMany với Major)

```sql
CREATE TABLE subject_majors (
    subject_id SMALLINT NOT NULL,
    major_id SMALLINT NOT NULL,
    PRIMARY KEY (subject_id, major_id),
    FOREIGN KEY (subject_id) REFERENCES subjects(id) ON DELETE CASCADE,
    FOREIGN KEY (major_id) REFERENCES majors(id) ON DELETE CASCADE
);
```

**Entity Class**: `backend/.../entity/Subject.java`

| Field             | Type                 | Constraints     | Mô tả                                           |
| ----------------- | -------------------- | --------------- | ----------------------------------------------- |
| `id`              | Short                | PK, Auto        | ID tự động tăng (SMALLSERIAL)                   |
| `name`            | String(150)          | NotNull         | Tên môn học (VD: "Object-Oriented Programming") |
| `code`            | String(20)           | Unique, NotNull | Mã môn học (VD: "PRO192")                       |
| `isActive`        | Boolean              | Default: true   | Trạng thái hoạt động                            |
| `createdAt`       | Instant              | Auto            | Thời gian tạo record                            |
| `updatedAt`       | Instant              | Auto            | Thời gian cập nhật cuối                         |
| `majors`          | Set\<Major\>         | ManyToMany      | Các ngành học chứa môn này                      |
| `academicClasses` | Set\<AcademicClass\> | OneToMany       | Các lớp học của môn                             |

### 3.2 REST API Endpoints

**Base Path**: `/api/v1/subjects`

| Method | Endpoint        | Permission          | Mô tả                      | Request Body  |
| ------ | --------------- | ------------------- | -------------------------- | ------------- |
| GET    | `/`             | SUBJECT_READ        | Lấy danh sách (phân trang) | Query params  |
| GET    | `/{id}`         | SUBJECT_READ        | Lấy chi tiết theo ID       | -             |
| POST   | `/`             | SUBJECT_CREATE      | Tạo subject mới            | CreateRequest |
| PUT    | `/{id}`         | SUBJECT_UPDATE      | Cập nhật subject           | UpdateRequest |
| DELETE | `/{id}`         | SUBJECT_DELETE_HARD | Xóa vĩnh viễn              | -             |
| POST   | `/import`       | SUBJECT_IMPORT      | Import từ file CSV         | FormData      |
| GET    | `/{id}/classes` | CLASS_READ          | Lấy danh sách lớp học      | Query params  |

### 3.3 Data Transfer Objects (DTOs)

**Request DTOs:**

```java
// SubjectCreateRequest - Dùng khi tạo mới
{
  "name": "Object-Oriented Programming",  // Bắt buộc, tối đa 150 ký tự
  "code": "PRO192",                        // Bắt buộc, tối đa 20 ký tự, CHỈ IN HOA + số
  "majorIds": [1, 2, 3]                    // Bắt buộc, ít nhất 1 major
}

// SubjectUpdateRequest - Dùng khi cập nhật
{
  "name": "Object-Oriented Programming",
  "code": "PRO192",
  "majorIds": [1, 2, 3],
  "isActive": true                         // Có thể thay đổi trạng thái
}

// SubjectSearchRequest - Query params cho tìm kiếm
?page=0&pageSize=10&sort=ASC&sortBy=name&search=Programming&isActive=true&majorId=1
```

**Response DTO:**

```java
// SubjectDTO - Response trả về client
{
  "id": 1,
  "name": "Object-Oriented Programming",
  "code": "PRO192",
  "majors": [
    {"id": 1, "name": "Software Engineering", "code": "SE", "isActive": true},
    {"id": 2, "name": "Artificial Intelligence", "code": "AI", "isActive": true}
  ],
  "totalClass": 5,                        // Tổng số lớp
  "totalActiveClass": 4,                  // Số lớp đang active
  "isActive": true,
  "createdAt": "2024-01-15T10:30:00Z",
  "updatedAt": "2024-01-15T10:30:00Z"
}
```

### 3.4 Service Layer

**File**: `backend/.../service/SubjectService.java`

| Method                                    | Input                   | Output             | Mô tả                                            |
| ----------------------------------------- | ----------------------- | ------------------ | ------------------------------------------------ |
| `search(request)`                         | SearchRequest           | List\<SubjectDTO\> | Tìm kiếm với filter, sort, pagination            |
| `count(request)`                          | SearchRequest           | Long               | Đếm tổng số records thỏa điều kiện               |
| `findById(id)`                            | Short id                | SubjectDTO         | Lấy chi tiết, throw exception nếu không tìm thấy |
| `searchByMajorId(majorId, request)`       | Short, SearchRequest    | List\<SubjectDTO\> | Tìm subjects theo Major                          |
| `searchBySemesterId(semesterId, request)` | Short, SearchRequest    | List\<SubjectDTO\> | Tìm subjects theo Semester                       |
| `searchByStaffId(staffId, request)`       | Integer, SearchRequest  | List\<SubjectDTO\> | Tìm subjects theo Staff (với role)               |
| `create(request)`                         | CreateRequest           | SubjectDTO         | Tạo mới với đầy đủ validation                    |
| `update(id, request)`                     | Short id, UpdateRequest | SubjectDTO         | Cập nhật với kiểm tra dependencies               |
| `delete(id)`                              | Short id                | void               | Xóa, kiểm tra ràng buộc với classes              |
| `importFromCsv(file, mode)`               | MultipartFile, String   | ImportResultDTO    | Import hàng loạt từ CSV                          |

### 3.5 Repository Layer

**Custom Queries quan trọng:**

```java
// === Kiểm tra trùng lặp (dùng khi tạo mới) ===
boolean existsByCode(String code);
boolean existsByName(String name);

// === Kiểm tra trùng lặp loại trừ ID (dùng khi update) ===
boolean existsByCodeAndIdNot(String code, Short id);
boolean existsByNameAndIdNot(String name, Short id);

// === Dependency checks (dùng khi delete/deactivate) ===
long countAllClassesBySubjectId(Short subjectId);
// → Đếm tổng số lớp học của môn

long countActiveClassesBySubjectId(Short subjectId);
// → Đếm số lớp học active (dùng khi deactivate)

// === Dashboard query ===
@Query("SELECT COUNT(DISTINCT c.subject) FROM AcademicClass c
        WHERE c.semester.id = :semesterId")
Integer countSubjectsBySemester(Short semesterId);
// → Đếm số môn học trong một kỳ
```

---

## 4. Frontend Implementation

### 4.1 Trang Quản Lý Subject

**Route**: `/admin/subjects`
**Quyền truy cập**: DATA_OPERATOR (Admin)
**File chính**: `frontend-web/app/admin/subjects/page.tsx`

**Giao diện người dùng:**

```
┌─────────────────────────────────────────────────────────────────────┐
│  Subject Management                                                  │
│  Create, manage, and organize subjects.                             │
├─────────────────────────────────────────────────────────────────────┤
│  [Search...]  [Status ▼]  [Sort By ▼]  [↑↓]  [Major ▼]              │
│                                              [Import] [+ Create]     │
├─────────────────────────────────────────────────────────────────────┤
│  Code   │     Name                │ Majors │ Classes │ Status │ ⋮   │
│─────────┼─────────────────────────┼────────┼─────────┼────────┼─────│
│  PRO192 │ Object-Oriented Prog... │   3    │    5    │ Active │ ✏️  │
│  DSA201 │ Data Structures and...  │   2    │    4    │ Active │ ✏️  │
│  WEB301 │ Web Development         │   1    │    3    │Inactive│ ✏️  │
├─────────────────────────────────────────────────────────────────────┤
│  Showing 1 - 10 of 20 items              ◀ [1] [2] ▶                │
└─────────────────────────────────────────────────────────────────────┘
```

**Tính năng:**
| Tính năng | Mô tả |
|-----------|-------|
| Tìm kiếm | Theo tên hoặc mã môn (debounced 500ms) |
| Lọc Status | Theo trạng thái Active/Inactive/All |
| Lọc Major | Theo ngành học (searchable popover) |
| Sắp xếp | Theo Name hoặc Code |
| Phân trang | 10 items/trang |
| Import CSV | Hỗ trợ 2 mode: AddOnly, AddAndUpdate |

### 4.2 Component Structure

```
page.tsx (Main Page Component)
│
├── subject-table.tsx ────────────── Bảng hiển thị dữ liệu (10 rows cố định)
│   ├── subject-columns.tsx ──────── Định nghĩa 6 cột
│   │   ├── Code (centered, font-medium)
│   │   ├── Name (centered)
│   │   ├── Majors (Badge + Tooltip với danh sách majors)
│   │   ├── Classes (centered, muted - totalClass)
│   │   ├── Status (Badge: green/red)
│   │   └── Actions (Edit button với tooltip)
│   └── subject-pagination.tsx ───── Phân trang thông minh
│
├── subject-form-dialog.tsx ──────── Form tạo/sửa subject
│   ├── Name Input ───────────────── Max 150 chars
│   ├── Code Input ───────────────── Auto-uppercase, max 20 chars
│   ├── multi-select-majors.tsx ──── Multi-select với badges
│   └── Active Toggle ────────────── Chỉ hiện ở Edit mode
│
├── delete-subject-dialog.tsx ────── Dialog xác nhận xóa
│
└── GenericImportDialog ──────────── Dialog import CSV
```

### 4.3 API Hooks (React Query)

**File**: `frontend-web/hooks/api/useSubjects.ts`

| Hook                     | Loại     | Chức năng                   | Caching                       |
| ------------------------ | -------- | --------------------------- | ----------------------------- |
| `useGetSubjects(params)` | Query    | Lấy danh sách có phân trang | staleTime: 5 phút             |
| `useGetSubjectById(id)`  | Query    | Lấy chi tiết một subject    | staleTime: 5 phút             |
| `useCreateSubject()`     | Mutation | Tạo mới                     | Auto invalidate list          |
| `useUpdateSubject()`     | Mutation | Cập nhật                    | Auto invalidate list + detail |
| `useDeleteSubject()`     | Mutation | Xóa                         | Auto invalidate list          |
| `useImportSubjects()`    | Mutation | Import từ CSV               | Auto invalidate list          |

**Query Keys:**

```typescript
subjects: {
  all: ["subjects"],                     // Danh sách
  detail: (id) => ["subjects", id],      // Chi tiết
  classes: (id) => ["subjects", id, "classes"],  // Lớp học
}
```

### 4.4 TypeScript Type Definitions

**File**: `frontend-web/types/index.ts`

```typescript
// Core type - đại diện cho một môn học
type Subject = {
  id: number;
  name: string; // Tên môn: "Object-Oriented Programming"
  code: string; // Mã môn: "PRO192"
  majors: Array<{
    // Các ngành liên quan
    id: number;
    name: string;
    code: string;
    isActive: boolean;
  }>;
  totalClass: number; // Tổng số lớp (calculated)
  totalActiveClass: number; // Số lớp active (calculated)
  isActive: boolean; // Trạng thái hoạt động
  createdAt: string; // ISO timestamp
  updatedAt: string; // ISO timestamp
};

// Payload khi tạo mới
type CreateSubjectPayload = {
  name: string; // 1-150 ký tự, letters + digits + spaces
  code: string; // 1-20 ký tự, UPPERCASE + digits only
  majorIds: number[]; // Tối thiểu 1 major
};

// Payload khi cập nhật
type UpdateSubjectPayload = CreateSubjectPayload & {
  isActive: boolean;
};

// Query params
interface SubjectQueryParams {
  page?: number;
  pageSize?: number;
  sort?: "asc" | "desc";
  sortBy?: "name" | "code";
  search?: string;
  isActive?: boolean;
  majorId?: number; // Filter theo ngành
}
```

### 4.5 Form Validation (Zod Schema)

**File**: `frontend-web/components/admin/subjects/subject-form-dialog.tsx`

| Field      | Validation Rules                                                 | Error Message                                               |
| ---------- | ---------------------------------------------------------------- | ----------------------------------------------------------- |
| `name`     | Bắt buộc, 1-150 ký tự, pattern: `^[A-Za-z0-9]+( [A-Za-z0-9]+)*$` | "Name must contain only letters, digits, and single spaces" |
| `code`     | Bắt buộc, 1-20 ký tự, pattern: `^[A-Z0-9]+$`                     | "Code must contain only UPPERCASE letters and digits"       |
| `majorIds` | Array, min 1 item                                                | "At least one major must be selected"                       |
| `isActive` | Boolean (chỉ Edit mode)                                          | -                                                           |

**Đặc biệt**:

- Code field tự động chuyển thành UPPERCASE khi nhập
- Multi-select majors chỉ hiển thị các majors đang active

### 4.6 Internationalization (i18n)

Hệ thống hỗ trợ đa ngôn ngữ với **next-intl**:

- English: `frontend-web/messages/en.json` (namespace: `subject`)
- Vietnamese: `frontend-web/messages/vi.json`

---

## 5. Luồng Xử Lý Nghiệp Vụ

### 5.1 Luồng Tạo Subject Mới

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
     │   name: "OOP"       │                         │                     │
     │   code: "PRO192"    │                         │                     │
     │   majorIds: [1,2]   │                         │                     │
     │────────────────────>│                         │                     │
     │                     │                         │                     │
     │                     │ 4. Zod Validation       │                     │
     │                     │ (client-side)           │                     │
     │                     │                         │                     │
     │                     │ 5. POST /subjects       │                     │
     │                     │────────────────────────>│                     │
     │                     │                         │                     │
     │                     │                         │ 6. Validate:        │
     │                     │                         │ - Code unique       │
     │                     │                         │ - Name unique       │
     │                     │                         │ - All majors exist  │
     │                     │                         │ - All majors active │
     │                     │                         │                     │
     │                     │                         │ 7. INSERT + JOIN    │
     │                     │                         │────────────────────>│
     │                     │                         │                     │
     │                     │ 8. Return SubjectDTO    │<────────────────────│
     │                     │<────────────────────────│                     │
     │                     │                         │                     │
     │                     │ 9. Invalidate cache     │                     │
     │                     │    Toast success        │                     │
     │<────────────────────│                         │                     │
```

### 5.2 Luồng Cập Nhật Subject

```
Bước 1: User click Edit
    │
    ▼
Bước 2: Frontend gọi GET /subjects/{id}
    │
    ▼
Bước 3: Hiển thị form với dữ liệu hiện tại
    │
    ▼
Bước 4: User thay đổi thông tin
    │
    ├─── Nếu thay đổi isActive = false ────> Backend kiểm tra:
    │                                         │
    │                                         ├─── Có active classes? ───> Lỗi
    │                                         │   SUBJECT_HAS_ACTIVE_CLASSES
    │                                         │
    │                                         └─── Không có ──────────────> OK
    │
    ├─── Thay đổi majorIds ────> Backend kiểm tra:
    │                            - All majors exist?
    │                            - All majors active?
    │
    ▼
Bước 5: Frontend validation (Zod)
    │
    ▼
Bước 6: PUT /subjects/{id}
    │
    ▼
Bước 7: Backend validation
    │
    ├─── Code unique (exclude current)?
    ├─── Name unique (exclude current)?
    └─── Major validation
    │
    ▼
Bước 8: UPDATE database + subject_majors
    │
    ▼
Bước 9: Invalidate cache → Refresh UI
```

### 5.3 Luồng Xóa Subject

```
User click Delete
    │
    ▼
Hiện Confirmation Dialog
    │
    ├─── User xác nhận ───────────────────────────────────┐
    │                                                      │
    │                                                      ▼
    │                                          DELETE /subjects/{id}
    │                                                      │
    │                                                      ▼
    │                                          Backend kiểm tra:
    │                                          Subject có classes?
    │                                                      │
    │                       ┌──────────────────────────────┼──────────────────────────┐
    │                       │                              │                          │
    │                       ▼                              ▼                          │
    │                 CÓ classes                    KHÔNG có classes                  │
    │                       │                              │                          │
    │                       ▼                              ▼                          │
    │            Return Error:                    DELETE from DB                      │
    │         SUBJECT_HAS_DEPENDENCIES            (CASCADE to subject_majors)        │
    │                       │                              │                          │
    │                       ▼                              ▼                          │
    │              Toast Error                     Return Success                     │
    │         "Cannot delete subject.                      │                          │
    │          Found X classes."                          ▼                          │
    │                                              Toast Success                      │
    │                                              Refresh list                       │
    │                                                                                 │
    └─── User hủy ──────────────────────────────────────────────────────> Đóng dialog
```

---

## 6. Business Rules & Validation

### 6.1 Validation Rules

| Rule               | Mô tả                                  | Error Code                   | HTTP Status |
| ------------------ | -------------------------------------- | ---------------------------- | ----------- |
| Unique Code        | Mã môn học phải unique                 | `SUBJECT_CODE_EXISTS`        | 409         |
| Unique Name        | Tên môn học phải unique                | `SUBJECT_NAME_EXISTS`        | 409         |
| Major Required     | Phải có ít nhất 1 ngành                | `SUBJECT_MAJOR_IDS_EMPTY`    | 400         |
| Major Exists       | Tất cả major IDs phải tồn tại          | `MAJOR_NOT_FOUND`            | 404         |
| Active Major Only  | Chỉ được gán cho major đang active     | `INACTIVE_MAJOR_NOT_ALLOWED` | 400         |
| Has Dependencies   | Không xóa nếu có classes               | `SUBJECT_HAS_DEPENDENCIES`   | 409         |
| Has Active Classes | Không deactivate nếu có active classes | `SUBJECT_HAS_ACTIVE_CLASSES` | 409         |
| Not Found          | Subject không tồn tại                  | `SUBJECT_NOT_FOUND`          | 404         |

### 6.2 Quy Tắc Dependencies

**Không thể XÓA Subject nếu:**

- Có bất kỳ AcademicClass nào tham chiếu đến Subject
- Phải xóa tất cả classes trước khi xóa subject

**Không thể DEACTIVATE Subject nếu:**

- Có AcademicClass đang active tham chiếu đến Subject
- Phải deactivate tất cả classes trước

**Quan hệ với Major:**

- Khi tạo/update: Tất cả majors phải tồn tại và đang active
- Cascade delete: Khi xóa subject, tự động xóa records trong `subject_majors`

### 6.3 CSV Import Feature

**Endpoint**: `POST /api/v1/subjects/import`

**CSV Format:**

```csv
code,name,major_codes[,status]
PRO192,Object-Oriented Programming,SE AI IS,true
DSA201,Data Structures and Algorithms,SE CS,true
WEB301,Web Development,SE,false
```

**Modes:**

| Mode           | Mô tả                | Khi code tồn tại      |
| -------------- | -------------------- | --------------------- |
| `AddOnly`      | Chỉ thêm records mới | Skip, báo lỗi         |
| `AddAndUpdate` | Thêm hoặc cập nhật   | Update record hiện có |

**Major Codes Resolution:**

- Tách bằng dấu cách hoặc phẩy
- Lookup major by code (không phải ID)
- Tất cả major codes phải tồn tại và active

**Xử lý lỗi:**

- Mỗi row được xử lý trong transaction riêng (REQUIRES_NEW)
- Row lỗi được ghi nhận, không ảnh hưởng row khác (Partial Success)
- Deduplication: Nếu có duplicate code trong file → Giữ lại row đầu tiên
- Response trả về: successCount, failureCount, errorDetails[]

---

## 7. Hướng Dẫn Phát Triển

### 7.1 Danh Sách File Quan Trọng

**Backend** (theo thứ tự nên đọc):

| #   | File                         | Mô tả            | Đường dẫn                      |
| --- | ---------------------------- | ---------------- | ------------------------------ |
| 1   | `Subject.java`               | Entity structure | `backend/.../entity/`          |
| 2   | `SubjectDTO.java`            | Response format  | `backend/.../dto/response/`    |
| 3   | `SubjectCreateRequest.java`  | Input validation | `backend/.../dto/request/`     |
| 4   | `SubjectService.java`        | Business logic   | `backend/.../service/`         |
| 5   | `SubjectRepository.java`     | Standard queries | `backend/.../repository/`      |
| 6   | `SubjectRepositoryImpl.java` | Custom queries   | `backend/.../repository/impl/` |
| 7   | `SubjectController.java`     | API endpoints    | `backend/.../controller/`      |

**Frontend** (theo thứ tự nên đọc):

| #   | File                      | Mô tả             | Đường dẫn                                 |
| --- | ------------------------- | ----------------- | ----------------------------------------- |
| 1   | `types/index.ts`          | Type definitions  | `frontend-web/types/`                     |
| 2   | `useSubjects.ts`          | API hooks         | `frontend-web/hooks/api/`                 |
| 3   | `page.tsx`                | Main page         | `frontend-web/app/admin/subjects/`        |
| 4   | `subject-form-dialog.tsx` | Form & validation | `frontend-web/components/admin/subjects/` |
| 5   | `subject-table.tsx`       | Table display     | `frontend-web/components/admin/subjects/` |
| 6   | `multi-select-majors.tsx` | Major selector    | `frontend-web/components/admin/subjects/` |

### 7.2 FAQ - Câu Hỏi Thường Gặp

**Q1: Làm sao để thêm field mới cho Subject?**

```
Backend:
1. Thêm field vào Subject.java entity
2. Tạo migration script (ALTER TABLE)
3. Cập nhật SubjectDTO.java
4. Cập nhật Create/UpdateRequest.java
5. Cập nhật SubjectMapper.java

Frontend:
6. Cập nhật type trong types/index.ts
7. Cập nhật zod schema trong lib/zod-schemas.ts
8. Cập nhật form trong subject-form-dialog.tsx
9. Cập nhật columns trong subject-columns.tsx (nếu hiển thị)
```

**Q2: Subject selector trong form khác hoạt động như thế nào?**

- Sử dụng hook `useGetSubjects()` để fetch danh sách
- Thường filter: `isActive: true`
- Hiển thị format: `{code} - {name}`
- Component tham khảo: AcademicClassForm, ExamSlotForm

**Q3: Tại sao không xóa được Subject?**

- Kiểm tra Subject có classes không: `GET /subjects/{id}/classes`
- Nếu có → phải xóa/chuyển classes trước
- Error: `SUBJECT_HAS_DEPENDENCIES`

**Q4: Khác biệt giữa Subject và Major?**

| Aspect             | Subject                  | Major                        |
| ------------------ | ------------------------ | ---------------------------- |
| Vai trò            | Curriculum item          | Classification               |
| Relationships      | Major (M:N), Class (1:N) | Subject (M:N), Student (1:N) |
| Dependencies check | Has Classes              | Has Subjects, Has Students   |
| Ownership          | Thuộc về nhiều Major     | Sở hữu nhiều Subject         |

**Q5: Khác biệt giữa Subject và Semester?**

| Aspect             | Subject                  | Semester             |
| ------------------ | ------------------------ | -------------------- |
| Vai trò            | Curriculum item          | Time container       |
| Relationships      | Major (M:N), Class (1:N) | Class (1:N), Slot    |
| Lifecycle          | Không có thời gian       | Có startDate/endDate |
| Dependencies check | Has Classes              | Has Classes          |

### 7.3 Error Codes Reference

| Error Code                   | HTTP | Mô tả                  | Xử lý                    |
| ---------------------------- | ---- | ---------------------- | ------------------------ |
| `SUBJECT_NOT_FOUND`          | 404  | ID không tồn tại       | Kiểm tra lại ID          |
| `SUBJECT_CODE_EXISTS`        | 409  | Code đã tồn tại        | Đổi code khác            |
| `SUBJECT_NAME_EXISTS`        | 409  | Name đã tồn tại        | Đổi name khác            |
| `SUBJECT_MAJOR_IDS_EMPTY`    | 400  | Không chọn major       | Chọn ít nhất 1 major     |
| `SUBJECT_HAS_DEPENDENCIES`   | 409  | Có classes liên kết    | Xóa classes trước        |
| `SUBJECT_HAS_ACTIVE_CLASSES` | 409  | Có active classes      | Deactivate classes trước |
| `MAJOR_NOT_FOUND`            | 404  | Major ID không tồn tại | Kiểm tra major IDs       |
| `INACTIVE_MAJOR_NOT_ALLOWED` | 400  | Major không active     | Chọn major đang active   |

---

## Tóm Tắt

### Điểm Chính Cần Nhớ

1. **Subject là curriculum module** - Đơn vị học thuật cơ bản, cơ sở để mở lớp học

2. **Quan hệ ManyToMany với Major**:

   - Một Subject có thể thuộc nhiều Major
   - Một Major có nhiều Subject
   - Bảng liên kết: `subject_majors`

3. **Quan hệ OneToMany với AcademicClass**:

   - Một Subject có nhiều lớp học
   - Foreign key: `classes.subject_id`

4. **Validation chặt chẽ**:

   - Code unique (UPPERCASE + digits, max 20)
   - Name unique (letters + digits + spaces, max 150)
   - Phải có ít nhất 1 active major

5. **Xóa có điều kiện nghiêm ngặt**:

   - Không thể xóa nếu có ANY class liên kết
   - Phải xóa tất cả classes trước

6. **CSV Import với Major Codes**:
   - Lookup major bằng code (không phải ID)
   - Tất cả major codes phải tồn tại và active

### Khi Trình Bày Hội Đồng

- **Giải thích vai trò**: Subject như "đơn vị học thuật" - cơ sở để mở lớp học
- **Demo CRUD**: Tạo → Sửa → Tìm kiếm → Import CSV → Xóa
- **Nhấn mạnh validation**: Unique constraints, major requirements
- **Business rules**: Dependencies check khi xóa/deactivate
- **Integration**: Liên kết với Major (ManyToMany) và AcademicClass (OneToMany)
- **So sánh**: Subject vs Semester vs Major - giải thích rõ vai trò khác nhau
