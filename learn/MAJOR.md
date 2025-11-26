# Major Module - Tài Liệu Kỹ Thuật

> **Mục đích tài liệu**: Giúp người đọc hiểu và làm việc với module Major (Ngành học) trong hệ thống FUACS - Hệ thống Điểm danh Tự động sử dụng Nhận diện Khuôn mặt.

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

### 1.1 Major là gì?

**Major (Ngành học)** là đơn vị phân loại chuyên ngành đào tạo trong hệ thống quản lý giáo dục đại học. Mỗi sinh viên thuộc về một ngành học cụ thể, và mỗi ngành học có một tập hợp các môn học liên quan.

### 1.2 Vai trò trong hệ thống FUACS

Trong hệ thống FUACS, **Major Module** đóng vai trò **classification module** với các chức năng:

| Vai trò                | Mô tả                                  | Ví dụ                             |
| ---------------------- | -------------------------------------- | --------------------------------- |
| **Student Classifier** | Phân loại sinh viên theo ngành đào tạo | SV Nguyễn Văn A thuộc ngành SE    |
| **Subject Organizer**  | Nhóm các môn học theo chuyên ngành     | Ngành SE có môn OOP, DSA, Web Dev |
| **Academic Reference** | Tham chiếu trong báo cáo, thống kê     | Thống kê điểm danh theo ngành     |

### 1.3 Mối Quan Hệ với Các Module Khác

```
                              ┌─────────────────┐
                              │      MAJOR      │
                              │   (Ngành học)   │
                              └────────┬────────┘
                                       │
                    ┌──────────────────┼──────────────────┐
                    │                  │                  │
                    ▼                  ▼                  ▼
           ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐
           │     SUBJECT     │ │ STUDENT PROFILE │ │  ACADEMIC CLASS │
           │   (Môn học)     │ │  (Hồ sơ SV)     │ │    (Lớp học)    │
           └────────┬────────┘ └────────┬────────┘ └────────┬────────┘
                    │                   │                   │
                    ▼                   ▼                   ▼
           ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐
           │  ACADEMIC CLASS │ │      USER       │ │   ENROLLMENT    │
           │   (Lớp học)     │ │  (Tài khoản)    │ │  (Đăng ký học)  │
           └─────────────────┘ └─────────────────┘ └─────────────────┘
```

**Giải thích mối quan hệ**:

- **Major ↔ Subject**: Quan hệ ManyToMany - Một ngành có nhiều môn, một môn có thể thuộc nhiều ngành
- **Major → StudentProfile**: Quan hệ OneToMany - Một ngành có nhiều sinh viên
- **Subject → AcademicClass**: Môn học được mở thành các lớp học cụ thể

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
│  │  /admin/    │  │   major-    │  │   useGet    │                 │
│  │   majors    │──│  table.tsx  │──│   Majors    │                 │
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
│   └── MajorController.java           # REST API endpoints (7 endpoints)
├── service/
│   └── MajorService.java              # Business logic & validation
├── entity/
│   └── Major.java                     # JPA Entity - ánh xạ table
├── repository/
│   ├── MajorRepository.java           # JPA Repository interface
│   ├── custom/
│   │   └── CustomMajorRepository.java # Interface cho custom queries
│   └── impl/
│       └── MajorRepositoryImpl.java   # Implementation custom queries
├── dto/
│   ├── request/
│   │   ├── MajorCreateRequest.java    # Validation cho tạo mới
│   │   ├── MajorUpdateRequest.java    # Validation cho cập nhật
│   │   ├── MajorSearchRequest.java    # Params tìm kiếm
│   │   └── MajorCsvRow.java           # Dữ liệu CSV import
│   ├── response/
│   │   └── MajorDTO.java              # Response trả về client
│   └── mapper/
│       ├── MajorMapper.java           # MapStruct - chuyển đổi DTO/Entity
│       └── MajorSimpleMapper.java     # Mapper cho nested objects
```

**Frontend** (`frontend-web/`):

```
├── app/admin/majors/
│   └── page.tsx                       # Trang quản lý chính (Client Component)
├── components/admin/majors/
│   ├── major-table.tsx                # Component bảng dữ liệu
│   ├── major-form-dialog.tsx          # Dialog form tạo/sửa
│   ├── major-columns.tsx              # Định nghĩa cột cho table
│   ├── major-pagination.tsx           # Component phân trang
│   └── delete-major-dialog.tsx        # Dialog xác nhận xóa
├── hooks/api/
│   └── useMajors.ts                   # Custom hooks gọi API (React Query)
├── types/
│   └── index.ts                       # TypeScript type definitions
└── lib/
    └── zod-schemas.ts                 # Zod validation schemas
```

---

## 3. Backend Implementation

### 3.1 Database Schema

**Table: `majors`**

```sql
CREATE TABLE majors (
    id SMALLSERIAL PRIMARY KEY,
    name VARCHAR(150) NOT NULL UNIQUE,
    code VARCHAR(20) NOT NULL UNIQUE,
    is_active BOOLEAN DEFAULT true NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
```

**Bảng liên kết: `subject_majors`** (ManyToMany với Subject)

```sql
CREATE TABLE subject_majors (
    subject_id SMALLINT NOT NULL,
    major_id SMALLINT NOT NULL,
    PRIMARY KEY (subject_id, major_id),
    FOREIGN KEY (subject_id) REFERENCES subjects(id) ON DELETE CASCADE,
    FOREIGN KEY (major_id) REFERENCES majors(id) ON DELETE CASCADE
);
```

**Entity Class**: `backend/.../entity/Major.java`

| Field             | Type                  | Constraints     | Mô tả                                  |
| ----------------- | --------------------- | --------------- | -------------------------------------- |
| `id`              | Short                 | PK, Auto        | ID tự động tăng (SMALLSERIAL)          |
| `name`            | String(150)           | Unique, NotNull | Tên ngành (VD: "Software Engineering") |
| `code`            | String(20)            | Unique, NotNull | Mã ngành (VD: "SE")                    |
| `isActive`        | Boolean               | Default: true   | Trạng thái hoạt động                   |
| `createdAt`       | Instant               | Auto            | Thời gian tạo record                   |
| `updatedAt`       | Instant               | Auto            | Thời gian cập nhật cuối                |
| `subjects`        | Set\<Subject\>        | ManyToMany      | Các môn học thuộc ngành                |
| `studentProfiles` | Set\<StudentProfile\> | OneToMany       | Sinh viên thuộc ngành                  |

### 3.2 REST API Endpoints

**Base Path**: `/api/v1/majors`

| Method | Endpoint         | Permission        | Mô tả                      | Request Body  |
| ------ | ---------------- | ----------------- | -------------------------- | ------------- |
| GET    | `/`              | MAJOR_READ        | Lấy danh sách (phân trang) | Query params  |
| GET    | `/{id}`          | MAJOR_READ        | Lấy chi tiết theo ID       | -             |
| POST   | `/`              | MAJOR_CREATE      | Tạo major mới              | CreateRequest |
| PUT    | `/{id}`          | MAJOR_UPDATE      | Cập nhật major             | UpdateRequest |
| DELETE | `/{id}`          | MAJOR_DELETE_HARD | Xóa vĩnh viễn              | -             |
| POST   | `/import`        | MAJOR_IMPORT      | Import từ file CSV         | FormData      |
| GET    | `/{id}/subjects` | SUBJECT_READ      | Lấy danh sách môn học      | Query params  |

### 3.3 Data Transfer Objects (DTOs)

**Request DTOs:**

```java
// MajorCreateRequest - Dùng khi tạo mới
{
  "name": "Software Engineering",  // Bắt buộc, tối đa 150 ký tự
  "code": "SE"                     // Bắt buộc, tối đa 20 ký tự, chỉ chữ và số
}

// MajorUpdateRequest - Dùng khi cập nhật
{
  "name": "Software Engineering",
  "code": "SE",
  "isActive": true                 // Có thể thay đổi trạng thái
}

// MajorSearchRequest - Query params cho tìm kiếm
?page=0&pageSize=10&sort=ASC&sortBy=name&search=Engineering&isActive=true
```

**Response DTO:**

```java
// MajorDTO - Response trả về client
{
  "id": 1,
  "name": "Software Engineering",
  "code": "SE",
  "totalSubject": 12,              // Tính toán từ số môn học
  "isActive": true,
  "createdAt": "2024-01-15T10:30:00Z",
  "updatedAt": "2024-01-15T10:30:00Z"
}
```

### 3.4 Service Layer

**File**: `backend/.../service/MajorService.java`

| Method                      | Input                   | Output           | Mô tả                                            |
| --------------------------- | ----------------------- | ---------------- | ------------------------------------------------ |
| `search(request)`           | SearchRequest           | List\<MajorDTO\> | Tìm kiếm với filter, sort, pagination            |
| `count(request)`            | SearchRequest           | Long             | Đếm tổng số records thỏa điều kiện               |
| `findById(id)`              | Short id                | MajorDTO         | Lấy chi tiết, throw exception nếu không tìm thấy |
| `create(request)`           | CreateRequest           | MajorDTO         | Tạo mới với đầy đủ validation                    |
| `update(id, request)`       | Short id, UpdateRequest | MajorDTO         | Cập nhật với kiểm tra dependencies               |
| `delete(id)`                | Short id                | void             | Xóa, kiểm tra ràng buộc với subjects/students    |
| `importFromCsv(file, mode)` | MultipartFile, String   | ImportResultDTO  | Import hàng loạt từ CSV                          |

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
long countSubjectsByMajorId(Short majorId);
// → Đếm số môn học thuộc ngành

long countStudentsByMajorId(Short majorId);
// → Đếm số sinh viên thuộc ngành

long countActiveSubjectsByMajorId(Short majorId);
// → Đếm số môn học active (dùng khi deactivate)

long countActiveStudentsByMajorId(Short majorId);
// → Đếm số sinh viên active (dùng khi deactivate)

// === Query với tính toán totalSubject ===
@Query("SELECT NEW MajorDTO(m.id, m.name, m.code, m.isActive,
        m.createdAt, m.updatedAt, COUNT(s.id))
       FROM Major m LEFT JOIN m.subjects s
       WHERE m.id = :id
       GROUP BY m.id, m.name, m.code, m.isActive, m.createdAt, m.updatedAt")
Optional<MajorDTO> findMajorDTOById(Short id);
```

---

## 4. Frontend Implementation

### 4.1 Trang Quản Lý Major

**Route**: `/admin/majors`
**Quyền truy cập**: DATA_OPERATOR (Admin)
**File chính**: `frontend-web/app/admin/majors/page.tsx`

**Giao diện người dùng:**

```
┌─────────────────────────────────────────────────────────────────────┐
│  Major Management                                                    │
│  Create, manage, and organize academic majors.                      │
├─────────────────────────────────────────────────────────────────────┤
│  [Search...]  [Status ▼]  [Sort By ▼]  [↑↓]  [Import] [+ Create]    │
├─────────────────────────────────────────────────────────────────────┤
│  Code  │      Name              │  Subjects  │ Status │ Actions     │
│────────┼────────────────────────┼────────────┼────────┼─────────────│
│   SE   │  Software Engineering  │     12     │ Active │     ⋮       │
│   AI   │  Artificial Intel...   │      8     │ Active │     ⋮       │
│   DS   │  Data Science          │     10     │Inactive│     ⋮       │
├─────────────────────────────────────────────────────────────────────┤
│  Showing 1 - 10 of 15 items              ◀ [1] [2] ▶                │
└─────────────────────────────────────────────────────────────────────┘
```

**Tính năng:**
| Tính năng | Mô tả |
|-----------|-------|
| Tìm kiếm | Theo tên hoặc mã ngành (debounced 500ms) |
| Lọc | Theo trạng thái Active/Inactive/All |
| Sắp xếp | Theo Name hoặc Code |
| Phân trang | 10 items/trang |
| Import CSV | Hỗ trợ 2 mode: AddOnly, AddAndUpdate |
| View Subjects | Chuyển đến trang Subjects với filter theo Major |

### 4.2 Component Structure

```
page.tsx (Main Page Component)
│
├── major-table.tsx ────────────── Bảng hiển thị dữ liệu (10 rows cố định)
│   ├── major-columns.tsx ──────── Định nghĩa 5 cột
│   │   ├── Code (centered, bold)
│   │   ├── Name (centered)
│   │   ├── Total Subjects (centered, muted)
│   │   ├── Status (Badge: green/red)
│   │   └── Actions (Dropdown: Edit, View Subjects)
│   └── major-pagination.tsx ───── Phân trang
│
├── major-form-dialog.tsx ──────── Form tạo/sửa major
│   └── AlertDialog ────────────── Xác nhận khi đổi Code
│
├── delete-major-dialog.tsx ────── Dialog xác nhận xóa
│
└── GenericImportDialog ────────── Dialog import CSV
```

### 4.3 API Hooks (React Query)

**File**: `frontend-web/hooks/api/useMajors.ts`

Sử dụng **React Query** để quản lý server state với caching và automatic invalidation.

| Hook                   | Loại     | Chức năng                   | Caching                       |
| ---------------------- | -------- | --------------------------- | ----------------------------- |
| `useGetMajors(params)` | Query    | Lấy danh sách có phân trang | staleTime: 5 phút             |
| `useGetMajorById(id)`  | Query    | Lấy chi tiết một major      | staleTime: 5 phút             |
| `useCreateMajor()`     | Mutation | Tạo mới                     | Auto invalidate list          |
| `useUpdateMajor()`     | Mutation | Cập nhật                    | Auto invalidate list + detail |
| `useDeleteMajor()`     | Mutation | Xóa                         | Auto invalidate list          |
| `useImportMajors()`    | Mutation | Import từ CSV               | Auto invalidate list          |

**Query Keys:**

```typescript
majors: {
  all: ["majors"],                     // Danh sách
  detail: (id) => ["majors", id],      // Chi tiết
}
```

### 4.4 TypeScript Type Definitions

**File**: `frontend-web/types/index.ts`

```typescript
// Core type - đại diện cho một ngành học
type Major = {
  id: number;
  name: string; // Tên ngành: "Software Engineering"
  code: string; // Mã ngành: "SE"
  isActive: boolean; // Trạng thái hoạt động
  totalSubject: number; // Số môn trong ngành (calculated)
  createdAt: string; // ISO timestamp
  updatedAt: string; // ISO timestamp
};

// Payload khi tạo mới
type CreateMajorPayload = {
  name: string; // 1-150 ký tự
  code: string; // 1-20 ký tự, alphanumeric only
};

// Payload khi cập nhật
type UpdateMajorPayload = CreateMajorPayload & {
  isActive: boolean;
};

// Response phân trang
type PaginatedMajorResponse = {
  items: Major[];
  totalPages: number;
  currentPage: number;
  pageSize: number;
  totalItems: number;
};

// Query params
interface MajorQueryParams {
  page?: number;
  pageSize?: number;
  sort?: "asc" | "desc";
  sortBy?: "name" | "code";
  search?: string;
  isActive?: boolean;
}
```

### 4.5 Form Validation (Zod Schema)

**File**: `frontend-web/components/admin/majors/major-form-dialog.tsx`

| Field      | Validation Rules                                                     | Error Message                                             |
| ---------- | -------------------------------------------------------------------- | --------------------------------------------------------- |
| `name`     | Bắt buộc, 1-150 ký tự, pattern: `^[A-Za-z0-9&-]+( [A-Za-z0-9&-]+)*$` | "Name must contain only letters, digits, spaces, & and -" |
| `code`     | Bắt buộc, 1-20 ký tự, pattern: `^[A-Za-z0-9]+$`                      | "Code must contain only letters and digits (no spaces)"   |
| `isActive` | Boolean (chỉ Edit mode)                                              | -                                                         |

**Đặc biệt**: Khi edit Major và thay đổi Code → Hiện AlertDialog xác nhận trước khi submit.

### 4.6 Internationalization (i18n)

Hệ thống hỗ trợ đa ngôn ngữ với **next-intl**:

- English: `frontend-web/messages/en.json` (namespace: `major`)
- Vietnamese: `frontend-web/messages/vi.json`

---

## 5. Luồng Xử Lý Nghiệp Vụ

### 5.1 Luồng Tạo Major Mới

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
     │   name: "SE"        │                         │                     │
     │   code: "Software   │                         │                     │
     │         Engineering"│                         │                     │
     │────────────────────>│                         │                     │
     │                     │                         │                     │
     │                     │ 4. Zod Validation       │                     │
     │                     │ (client-side)           │                     │
     │                     │                         │                     │
     │                     │ 5. POST /majors         │                     │
     │                     │────────────────────────>│                     │
     │                     │                         │                     │
     │                     │                         │ 6. Validate:        │
     │                     │                         │ - Code unique       │
     │                     │                         │ - Name unique       │
     │                     │                         │                     │
     │                     │                         │ 7. INSERT           │
     │                     │                         │────────────────────>│
     │                     │                         │                     │
     │                     │ 8. Return MajorDTO      │<────────────────────│
     │                     │<────────────────────────│                     │
     │                     │                         │                     │
     │                     │ 9. Invalidate cache     │                     │
     │                     │    Toast success        │                     │
     │<────────────────────│                         │                     │
```

### 5.2 Luồng Cập Nhật Major

```
Bước 1: User click Edit
    │
    ▼
Bước 2: Frontend gọi GET /majors/{id}
    │
    ▼
Bước 3: Hiển thị form với dữ liệu hiện tại
    │
    ▼
Bước 4: User thay đổi thông tin
    │
    ├─── Nếu thay đổi CODE ────> Hiện AlertDialog xác nhận
    │                                    │
    │                                    ├─── User xác nhận ───> Tiếp tục
    │                                    │
    │                                    └─── User hủy ────────> Quay lại form
    │
    ├─── Nếu thay đổi isActive = false ────> Backend kiểm tra:
    │                                         │
    │                                         ├─── Có active subjects? ───> Lỗi
    │                                         ├─── Có active students? ───> Lỗi
    │                                         └─── Không có ──────────────> OK
    │
    ▼
Bước 5: Frontend validation (Zod)
    │
    ▼
Bước 6: PUT /majors/{id}
    │
    ▼
Bước 7: Backend validation
    │
    ├─── Code unique (exclude current)?
    ├─── Name unique (exclude current)?
    └─── Dependencies check (nếu deactivate)?
    │
    ▼
Bước 8: UPDATE database
    │
    ▼
Bước 9: Invalidate cache → Refresh UI
```

### 5.3 Luồng Xóa Major

```
User click Delete
    │
    ▼
Hiện Confirmation Dialog
    │
    ├─── User xác nhận ───────────────────────────────────┐
    │                                                      │
    │                                                      ▼
    │                                          DELETE /majors/{id}
    │                                                      │
    │                                                      ▼
    │                                          Backend kiểm tra:
    │                                          Major có dependencies?
    │                                                      │
    │                       ┌──────────────────────────────┼──────────────────────────┐
    │                       │                              │                          │
    │                       ▼                              ▼                          │
    │              CÓ subjects/students           KHÔNG có dependency               │
    │                       │                              │                          │
    │                       ▼                              ▼                          │
    │            Return Error:                    DELETE from DB                      │
    │         MAJOR_HAS_DEPENDENCIES                       │                          │
    │                       │                              ▼                          │
    │                       ▼                      Return Success                     │
    │              Toast Error                             │                          │
    │         "Cannot delete major.                        ▼                          │
    │          Found subjects and               Toast Success                         │
    │          students..."                     Refresh list                          │
    │                                                                                 │
    └─── User hủy ──────────────────────────────────────────────────────> Đóng dialog
```

---

## 6. Business Rules & Validation

### 6.1 Validation Rules

| Rule                | Mô tả                                            | Error Code                      | HTTP Status |
| ------------------- | ------------------------------------------------ | ------------------------------- | ----------- |
| Unique Code         | Mã ngành phải unique                             | `MAJOR_CODE_EXISTS`             | 409         |
| Unique Name         | Tên ngành phải unique                            | `MAJOR_NAME_EXISTS`             | 409         |
| Has Dependencies    | Không xóa nếu có subjects/students               | `MAJOR_HAS_DEPENDENCIES`        | 409         |
| Active Dependencies | Không deactivate nếu có active subjects/students | `MAJOR_HAS_ACTIVE_DEPENDENCIES` | 409         |
| Not Found           | Major không tồn tại                              | `MAJOR_NOT_FOUND`               | 404         |

### 6.2 Quy Tắc Dependencies

**Không thể XÓA Major nếu:**

- Có bất kỳ Subject nào liên kết (qua bảng `subject_majors`)
- Có bất kỳ StudentProfile nào thuộc Major này

**Không thể DEACTIVATE Major nếu:**

- Có Subject đang active liên kết
- Có StudentProfile của User đang active

**Giải pháp khi có dependencies:**

1. Chuyển students sang Major khác
2. Xóa liên kết subjects (không xóa subject, chỉ bỏ liên kết)
3. Sau đó mới có thể xóa Major

### 6.3 CSV Import Feature

**Endpoint**: `POST /api/v1/majors/import`

**Modes:**

| Mode           | Mô tả                | Khi code tồn tại      |
| -------------- | -------------------- | --------------------- |
| `AddOnly`      | Chỉ thêm records mới | Skip, báo lỗi         |
| `AddAndUpdate` | Thêm hoặc cập nhật   | Update record hiện có |

**CSV Format:**

```csv
code,name,status
SE,Software Engineering,true
AI,Artificial Intelligence,true
DS,Data Science,false
```

**Xử lý lỗi:**

- Mỗi row được xử lý trong transaction riêng (REQUIRES_NEW)
- Row lỗi được ghi nhận, không ảnh hưởng row khác (Partial Success)
- Deduplication: Nếu có duplicate code trong file → Giữ lại row đầu tiên
- Response trả về: successCount, failureCount, errorDetails[]

---

## 7. Hướng Dẫn Phát Triển

### 7.1 Danh Sách File Quan Trọng

**Backend** (theo thứ tự nên đọc):

| #   | File                      | Mô tả            | Đường dẫn                   |
| --- | ------------------------- | ---------------- | --------------------------- |
| 1   | `Major.java`              | Entity structure | `backend/.../entity/`       |
| 2   | `MajorDTO.java`           | Response format  | `backend/.../dto/response/` |
| 3   | `MajorCreateRequest.java` | Input validation | `backend/.../dto/request/`  |
| 4   | `MajorService.java`       | Business logic   | `backend/.../service/`      |
| 5   | `MajorRepository.java`    | Custom queries   | `backend/.../repository/`   |
| 6   | `MajorController.java`    | API endpoints    | `backend/.../controller/`   |

**Frontend** (theo thứ tự nên đọc):

| #   | File                    | Mô tả             | Đường dẫn                               |
| --- | ----------------------- | ----------------- | --------------------------------------- |
| 1   | `types/index.ts`        | Type definitions  | `frontend-web/types/`                   |
| 2   | `useMajors.ts`          | API hooks         | `frontend-web/hooks/api/`               |
| 3   | `page.tsx`              | Main page         | `frontend-web/app/admin/majors/`        |
| 4   | `major-form-dialog.tsx` | Form & validation | `frontend-web/components/admin/majors/` |
| 5   | `major-table.tsx`       | Table display     | `frontend-web/components/admin/majors/` |

### 7.2 FAQ - Câu Hỏi Thường Gặp

**Q1: Làm sao để thêm field mới cho Major?**

```
Backend:
1. Thêm field vào Major.java entity
2. Tạo migration script (ALTER TABLE)
3. Cập nhật MajorDTO.java
4. Cập nhật Create/UpdateRequest.java
5. Cập nhật MajorMapper.java

Frontend:
6. Cập nhật type trong types/index.ts
7. Cập nhật form trong major-form-dialog.tsx
8. Cập nhật columns trong major-columns.tsx (nếu hiển thị)
```

**Q2: Major selector trong form khác hoạt động như thế nào?**

- Sử dụng hook `useGetMajors()` để fetch danh sách
- Thường filter: `isActive: true`
- Hiển thị format: `{code} - {name}`
- Component tham khảo: StudentProfileForm, SubjectForm

**Q3: Tại sao không xóa được Major?**

- Kiểm tra Major có subjects không: `GET /majors/{id}/subjects`
- Kiểm tra có students không: Check trong student_profiles table
- Nếu có → phải reassign hoặc xóa dependencies trước
- Error: `MAJOR_HAS_DEPENDENCIES`

**Q4: Khác biệt giữa Semester và Major?**

| Aspect             | Semester             | Major                      |
| ------------------ | -------------------- | -------------------------- |
| Vai trò            | Time container       | Classification             |
| Relationships      | AcademicClass, Slot  | Subject, StudentProfile    |
| Lifecycle          | Có startDate/endDate | Không có thời gian         |
| Dependencies check | Has Classes          | Has Subjects, Has Students |

### 7.3 Error Codes Reference

| Error Code                      | HTTP | Mô tả                       | Xử lý                         |
| ------------------------------- | ---- | --------------------------- | ----------------------------- |
| `MAJOR_NOT_FOUND`               | 404  | ID không tồn tại            | Kiểm tra lại ID               |
| `MAJOR_CODE_EXISTS`             | 409  | Code đã tồn tại             | Đổi code khác                 |
| `MAJOR_NAME_EXISTS`             | 409  | Name đã tồn tại             | Đổi name khác                 |
| `MAJOR_HAS_DEPENDENCIES`        | 409  | Có subjects/students        | Xóa dependencies trước        |
| `MAJOR_HAS_ACTIVE_DEPENDENCIES` | 409  | Có active subjects/students | Deactivate dependencies trước |

---

## Tóm Tắt

### Điểm Chính Cần Nhớ

1. **Major là classification module** - Phân loại sinh viên và nhóm môn học theo chuyên ngành

2. **Validation đơn giản hơn Semester**:

   - Code unique (alphanumeric, max 20)
   - Name unique (alphanumeric + spaces + & + -, max 150)
   - Không có date range hay overlap check

3. **Quan hệ ManyToMany với Subject**:

   - Một Major có nhiều Subject
   - Một Subject có thể thuộc nhiều Major
   - Bảng liên kết: `subject_majors`

4. **Quan hệ OneToMany với StudentProfile**:

   - Một Major có nhiều sinh viên
   - Mỗi sinh viên thuộc một Major

5. **Xóa có điều kiện nghiêm ngặt**:
   - Không thể xóa nếu có ANY subject liên kết
   - Không thể xóa nếu có ANY student thuộc Major
   - Phải reassign tất cả dependencies trước

### Khi Trình Bày Hội Đồng

- **Giải thích vai trò**: Major như "nhãn phân loại" cho sinh viên và môn học
- **Demo CRUD**: Tạo → Sửa → Tìm kiếm → Import CSV → Xóa
- **Nhấn mạnh validation**: Unique constraints cho code và name
- **Business rules**: Dependencies check khi xóa/deactivate
- **Integration**: Liên kết với Subject (ManyToMany) và StudentProfile (OneToMany)
- **So sánh với Semester**: Semester = time-based, Major = category-based
