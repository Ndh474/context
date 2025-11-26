# Semester Module - Tài Liệu Kỹ Thuật

> **Mục đích tài liệu**: Giúp người đọc hiểu và làm việc với module Semester trong hệ thống FUACS - Hệ thống Điểm danh Tự động sử dụng Nhận diện Khuôn mặt.

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

### 1.1 Semester là gì?

**Semester (Học kỳ)** là đơn vị thời gian cơ bản trong hệ thống quản lý đào tạo đại học. Mỗi năm học thường có 2-3 học kỳ, và tất cả các hoạt động giảng dạy, thi cử đều được tổ chức theo học kỳ.

### 1.2 Vai trò trong hệ thống FUACS

Trong hệ thống FUACS, **Semester Module** đóng vai trò **foundation module** với các chức năng:

| Vai trò             | Mô tả                                    | Ví dụ                              |
| ------------------- | ---------------------------------------- | ---------------------------------- |
| **Time Container**  | Xác định khoảng thời gian của kỳ học     | Fall 2024: 01/09/2024 - 31/12/2024 |
| **Data Organizer**  | Nhóm các lớp học, môn học theo kỳ        | Kỳ Fall 2024 có 45 lớp học         |
| **Reference Point** | Các buổi học/thi tham chiếu đến semester | Slot điểm danh thuộc kỳ nào        |

### 1.3 Mối Quan Hệ với Các Module Khác

```
                              ┌─────────────────┐
                              │    SEMESTER     │
                              │   (Học kỳ)      │
                              └────────┬────────┘
                                       │
            ┌──────────────────────────┼──────────────────────────┐
            │                          │                          │
            ▼                          ▼                          ▼
   ┌─────────────────┐       ┌─────────────────┐       ┌─────────────────┐
   │ ACADEMIC CLASS  │       │      SLOT       │       │     SUBJECT     │
   │   (Lớp học)     │       │  (Buổi học/thi) │       │   (Môn học)     │
   └────────┬────────┘       └────────┬────────┘       └─────────────────┘
            │                         │
            ▼                         ▼
   ┌─────────────────┐       ┌─────────────────┐
   │   ENROLLMENT    │       │   ATTENDANCE    │
   │(Đăng ký học)    │       │   (Điểm danh)   │
   └─────────────────┘       └─────────────────┘
```

**Giải thích mối quan hệ**:

- **Semester → AcademicClass**: Một học kỳ chứa nhiều lớp học (1:N)
- **Semester → Slot**: Các buổi thi độc lập (exam) tham chiếu trực tiếp đến semester
- **AcademicClass → Slot**: Các buổi học thường thuộc về lớp học cụ thể
- **Slot → Attendance**: Mỗi buổi học/thi có danh sách điểm danh

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
│  │  /admin/    │  │  semester-  │  │   useGet    │                 │
│  │  semesters  │──│  table.tsx  │──│  Semesters  │                 │
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
│   └── SemesterController.java          # REST API endpoints (10 endpoints)
├── service/
│   └── SemesterService.java             # Business logic & validation
├── entity/
│   └── Semester.java                    # JPA Entity - ánh xạ table
├── repository/
│   ├── SemesterRepository.java          # JPA Repository interface
│   ├── custom/
│   │   └── CustomSemesterRepository.java  # Interface cho custom queries
│   └── impl/
│       └── SemesterRepositoryImpl.java  # Implementation custom queries
├── dto/
│   ├── request/
│   │   ├── SemesterCreateRequest.java   # Validation cho tạo mới
│   │   ├── SemesterUpdateRequest.java   # Validation cho cập nhật
│   │   ├── SemesterSearchRequest.java   # Params tìm kiếm
│   │   └── SemesterCsvRow.java          # Dữ liệu CSV import
│   ├── response/
│   │   └── SemesterDTO.java             # Response trả về client
│   └── mapper/
│       └── SemesterMapper.java          # MapStruct - chuyển đổi DTO/Entity
```

**Frontend** (`frontend-web/`):

```
├── app/admin/semesters/
│   └── page.tsx                         # Trang quản lý chính (Server Component)
├── components/admin/semesters/
│   ├── semester-table.tsx               # Component bảng dữ liệu
│   ├── semester-form-dialog.tsx         # Dialog form tạo/sửa
│   ├── semester-columns.tsx             # Định nghĩa cột cho table
│   ├── semester-pagination.tsx          # Component phân trang
│   └── delete-semester-dialog.tsx       # Dialog xác nhận xóa
├── hooks/api/
│   └── useSemesters.ts                  # Custom hooks gọi API (React Query)
├── types/
│   └── index.ts                         # TypeScript type definitions
└── lib/
    └── zod-schemas.ts                   # Zod validation schemas
```

---

## 3. Backend Implementation

### 3.1 Database Schema

**Table: `semesters`**

```sql
CREATE TABLE semesters (
    id SMALLINT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(20) NOT NULL UNIQUE,
    code VARCHAR(10) NOT NULL UNIQUE,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    is_active BOOLEAN DEFAULT true NOT NULL,
    created_at TIMESTAMP NOT NULL,
    updated_at TIMESTAMP NOT NULL
);
```

**Entity Class**: `backend/.../entity/Semester.java`

| Field       | Type       | Constraints     | Mô tả                        |
| ----------- | ---------- | --------------- | ---------------------------- |
| `id`        | Short      | PK, Auto        | ID tự động tăng              |
| `name`      | String(20) | Unique, NotNull | Tên học kỳ (VD: "Fall 2024") |
| `code`      | String(10) | Unique, NotNull | Mã học kỳ (VD: "FA2024")     |
| `startDate` | LocalDate  | NotNull         | Ngày bắt đầu kỳ học          |
| `endDate`   | LocalDate  | NotNull         | Ngày kết thúc kỳ học         |
| `isActive`  | Boolean    | Default: true   | Trạng thái hoạt động         |
| `createdAt` | Instant    | Auto            | Thời gian tạo record         |
| `updatedAt` | Instant    | Auto            | Thời gian cập nhật cuối      |

### 3.2 REST API Endpoints

**Base Path**: `/api/v1/semesters`

| Method | Endpoint         | Permission           | Mô tả                      | Request Body  |
| ------ | ---------------- | -------------------- | -------------------------- | ------------- |
| GET    | `/`              | SEMESTER_READ        | Lấy danh sách (phân trang) | Query params  |
| GET    | `/{id}`          | SEMESTER_READ        | Lấy chi tiết theo ID       | -             |
| POST   | `/`              | SEMESTER_CREATE      | Tạo semester mới           | CreateRequest |
| PUT    | `/{id}`          | SEMESTER_UPDATE      | Cập nhật semester          | UpdateRequest |
| DELETE | `/{id}`          | SEMESTER_DELETE_HARD | Xóa vĩnh viễn              | -             |
| POST   | `/import`        | SEMESTER_IMPORT      | Import từ file CSV         | FormData      |
| GET    | `/{id}/classes`  | CLASS_READ           | Lấy danh sách lớp          | Query params  |
| GET    | `/{id}/subjects` | SUBJECT_READ         | Lấy danh sách môn          | Query params  |
| GET    | `/{id}/students` | USER_READ_LIST       | Lấy danh sách sinh viên    | Query params  |

### 3.3 Data Transfer Objects (DTOs)

**Request DTOs:**

```java
// SemesterCreateRequest - Dùng khi tạo mới
{
  "name": "Fall 2024",        // Bắt buộc, tối đa 20 ký tự
  "code": "FA2024",           // Bắt buộc, tối đa 10 ký tự, chỉ chữ và số
  "startDate": "2024-09-01",  // Bắt buộc, format: YYYY-MM-DD
  "endDate": "2024-12-31"     // Bắt buộc, phải sau startDate
}

// SemesterUpdateRequest - Dùng khi cập nhật
{
  "name": "Fall 2024",
  "code": "FA2024",
  "startDate": "2024-09-01",
  "endDate": "2024-12-31",
  "isActive": true            // Có thể thay đổi trạng thái
}

// SemesterSearchRequest - Query params cho tìm kiếm
?page=0&pageSize=10&sort=ASC&sortBy=name&search=Fall&isActive=true
```

**Response DTO:**

```java
// SemesterDTO - Response trả về client
{
  "id": 1,
  "name": "Fall 2024",
  "code": "FA2024",
  "startDate": "2024-09-01",
  "endDate": "2024-12-31",
  "totalClass": 45,           // Tính toán từ số lớp học
  "isActive": true,
  "createdAt": "2024-01-15T10:30:00Z",
  "updatedAt": "2024-01-15T10:30:00Z"
}
```

### 3.4 Service Layer

**File**: `backend/.../service/SemesterService.java`

| Method                      | Input                   | Output              | Mô tả                                            |
| --------------------------- | ----------------------- | ------------------- | ------------------------------------------------ |
| `search(request)`           | SearchRequest           | List\<SemesterDTO\> | Tìm kiếm với filter, sort, pagination            |
| `count(request)`            | SearchRequest           | Long                | Đếm tổng số records thỏa điều kiện               |
| `findById(id)`              | Short id                | SemesterDTO         | Lấy chi tiết, throw exception nếu không tìm thấy |
| `create(request)`           | CreateRequest           | SemesterDTO         | Tạo mới với đầy đủ validation                    |
| `update(id, request)`       | Short id, UpdateRequest | SemesterDTO         | Cập nhật với kiểm tra ongoing                    |
| `delete(id)`                | Short id                | void                | Xóa, kiểm tra ràng buộc với lớp học              |
| `importFromCsv(file, mode)` | MultipartFile, String   | ImportResultDTO     | Import hàng loạt từ CSV                          |

### 3.5 Repository Layer

**Custom Queries quan trọng:**

```java
// === Kiểm tra trùng lặp (dùng khi tạo mới) ===
boolean existsByCode(String code);
boolean existsByName(String name);
boolean existsByDateRangeOverlap(LocalDate startDate, LocalDate endDate);

// === Kiểm tra trùng lặp loại trừ ID (dùng khi update) ===
boolean existsByCodeAndIdNot(String code, Short id);
boolean existsByNameAndIdNot(String name, Short id);
boolean existsByDateRangeOverlapAndIdNot(LocalDate startDate, LocalDate endDate, Short id);

// === Dashboard & Navigation queries ===
List<Semester> findCurrentSemesters();
// → Trả về semester có ngày hiện tại nằm trong [startDate, endDate]

List<Semester> findSemestersWithSlotsByLecturerId(Integer lecturerId);
// → Trả về semester mà giảng viên có buổi dạy

long countClassesBySemesterId(Short semesterId);
// → Đếm số lớp học trong kỳ
```

---

## 4. Frontend Implementation

### 4.1 Trang Quản Lý Semester

**Route**: `/admin/semesters`
**Quyền truy cập**: DATA_OPERATOR (Admin)
**File chính**: `frontend-web/app/admin/semesters/page.tsx`

**Giao diện người dùng:**

```
┌─────────────────────────────────────────────────────────────────────┐
│  Semester Management                                                 │
│  Create, manage, and organize academic semesters.                   │
├─────────────────────────────────────────────────────────────────────┤
│  [Search...]  [Status ▼]  [Sort By ▼]  [↑↓]  [Import] [+ Create]    │
├─────────────────────────────────────────────────────────────────────┤
│  Code   │   Name       │  Start Date  │  End Date   │ Classes │ Status │ ⋮ │
│─────────┼──────────────┼──────────────┼─────────────┼─────────┼────────┼───│
│  FA24   │  Fall 2024   │  01/09/2024  │  31/12/2024 │   45    │ Active │ ⋮ │
│  SP25   │  Spring 2025 │  15/01/2025  │  31/05/2025 │   38    │ Active │ ⋮ │
├─────────────────────────────────────────────────────────────────────┤
│  Showing 1 - 10 of 25 items              ◀ [1] [2] [3] ... [5] ▶    │
└─────────────────────────────────────────────────────────────────────┘
```

**Tính năng:**
| Tính năng | Mô tả |
|-----------|-------|
| Tìm kiếm | Theo tên hoặc mã học kỳ (debounced 500ms) |
| Lọc | Theo trạng thái Active/Inactive/All |
| Sắp xếp | Theo Name, Code, Start Date, End Date |
| Phân trang | 10 items/trang, smart pagination |
| Import CSV | Hỗ trợ 2 mode: AddOnly, AddAndUpdate |

### 4.2 Component Structure

```
page.tsx (Main Page Component)
│
├── semester-table.tsx ──────────── Bảng hiển thị dữ liệu
│   ├── semester-columns.tsx ────── Định nghĩa các cột
│   └── semester-pagination.tsx ─── Phân trang
│
├── semester-form-dialog.tsx ────── Form tạo/sửa semester
│   └── DatePicker, Calendar ────── Components chọn ngày
│
└── delete-semester-dialog.tsx ──── Dialog xác nhận xóa
```

### 4.3 API Hooks (React Query)

**File**: `frontend-web/hooks/api/useSemesters.ts`

Sử dụng **React Query** để quản lý server state với caching và automatic invalidation.

| Hook                         | Loại     | Chức năng                   | Caching           |
| ---------------------------- | -------- | --------------------------- | ----------------- |
| `useGetSemesters(params)`    | Query    | Lấy danh sách có phân trang | staleTime: 5 phút |
| `useGetSemesterById(id)`     | Query    | Lấy chi tiết một semester   | staleTime: 5 phút |
| `useCreateSemester()`        | Mutation | Tạo mới                     | Auto invalidate   |
| `useUpdateSemester()`        | Mutation | Cập nhật                    | Auto invalidate   |
| `useDeleteSemester()`        | Mutation | Xóa                         | Auto invalidate   |
| `useImportSemesters()`       | Mutation | Import từ CSV               | Auto invalidate   |
| `useGetSemesterClasses(id)`  | Query    | Lớp học trong kỳ            | staleTime: 5 phút |
| `useGetSemesterSubjects(id)` | Query    | Môn học trong kỳ            | staleTime: 5 phút |
| `useGetSemesterStudents(id)` | Query    | Sinh viên trong kỳ          | staleTime: 5 phút |

### 4.4 TypeScript Type Definitions

**File**: `frontend-web/types/index.ts`

```typescript
// Core type - đại diện cho một học kỳ
type Semester = {
  id: number;
  name: string; // Tên học kỳ: "Fall 2024"
  code: string; // Mã học kỳ: "FA2024"
  startDate: string; // Format: "YYYY-MM-DD"
  endDate: string; // Format: "YYYY-MM-DD"
  isActive: boolean; // Trạng thái hoạt động
  totalClass: number; // Số lớp trong kỳ (calculated)
  createdAt: string; // ISO timestamp
  updatedAt: string; // ISO timestamp
};

// Payload khi tạo mới
type CreateSemesterPayload = {
  name: string;
  code: string;
  startDate: string;
  endDate: string;
};

// Payload khi cập nhật (có thêm isActive)
type UpdateSemesterPayload = CreateSemesterPayload & {
  isActive: boolean;
};

// Response phân trang
type PaginatedSemesterResponse = {
  items: Semester[];
  totalPages: number;
  currentPage: number;
  pageSize: number;
  totalItems: number;
};
```

### 4.5 Form Validation (Zod Schema)

**File**: `frontend-web/components/admin/semesters/semester-form-dialog.tsx`

| Field       | Create Mode                           | Edit Mode                   |
| ----------- | ------------------------------------- | --------------------------- |
| `name`      | Bắt buộc, max 20 ký tự, chữ/số/space  | Giống Create                |
| `code`      | Bắt buộc, max 10 ký tự, chỉ chữ và số | Giống Create                |
| `startDate` | Bắt buộc, >= ngày hiện tại            | Bắt buộc (cho phép quá khứ) |
| `endDate`   | Bắt buộc, > startDate                 | Bắt buộc, > startDate       |
| `isActive`  | Không có                              | Optional boolean            |

### 4.6 Internationalization (i18n)

Hệ thống hỗ trợ đa ngôn ngữ với **next-intl**:

- English: `frontend-web/messages/en.json`
- Vietnamese: `frontend-web/messages/vi.json`

---

## 5. Luồng Xử Lý Nghiệp Vụ

### 5.1 Luồng Tạo Semester Mới

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
     │────────────────────>│                         │                     │
     │                     │                         │                     │
     │                     │ 4. Zod Validation       │                     │
     │                     │ (client-side)           │                     │
     │                     │                         │                     │
     │                     │ 5. POST /semesters      │                     │
     │                     │────────────────────────>│                     │
     │                     │                         │                     │
     │                     │                         │ 6. Validate:        │
     │                     │                         │ - Date range        │
     │                     │                         │ - Uniqueness        │
     │                     │                         │ - Overlap check     │
     │                     │                         │                     │
     │                     │                         │ 7. INSERT           │
     │                     │                         │────────────────────>│
     │                     │                         │                     │
     │                     │ 8. Return SemesterDTO   │<────────────────────│
     │                     │<────────────────────────│                     │
     │                     │                         │                     │
     │                     │ 9. Invalidate cache     │                     │
     │                     │    Toast success        │                     │
     │<────────────────────│                         │                     │
     │                     │                         │                     │
```

### 5.2 Luồng Cập Nhật Semester

```
Bước 1: User click Edit
    │
    ▼
Bước 2: Frontend gọi GET /semesters/{id}
    │
    ▼
Bước 3: Hiển thị form với dữ liệu hiện tại
    │
    ▼
Bước 4: User thay đổi thông tin
    │
    ├─── Nếu thay đổi CODE ────> Hiện Confirmation Dialog
    │                                    │
    │                                    ├─── User xác nhận ───> Tiếp tục
    │                                    │
    │                                    └─── User hủy ────────> Quay lại form
    │
    ▼
Bước 5: Frontend validation (Zod)
    │
    ▼
Bước 6: PUT /semesters/{id}
    │
    ▼
Bước 7: Backend validation
    │
    ├─── Semester đang diễn ra (ongoing)?
    │         │
    │         ├─── CÓ: Chỉ cho phép đổi name/code
    │         │        Từ chối thay đổi dates/status
    │         │
    │         └─── KHÔNG: Cho phép đổi tất cả
    │
    ▼
Bước 8: UPDATE database
    │
    ▼
Bước 9: Invalidate cache → Refresh UI
```

### 5.3 Luồng Xóa Semester

```
User click Delete
    │
    ▼
Hiện Confirmation Dialog
    │
    ├─── User xác nhận ───────────────────────────────────┐
    │                                                      │
    │                                                      ▼
    │                                          DELETE /semesters/{id}
    │                                                      │
    │                                                      ▼
    │                                          Backend kiểm tra:
    │                                          Semester có lớp học?
    │                                                      │
    │                       ┌──────────────────────────────┼──────────────────────────┐
    │                       │                              │                          │
    │                       ▼                              ▼                          │
    │                 CÓ lớp học                    KHÔNG có lớp                      │
    │                       │                              │                          │
    │                       ▼                              ▼                          │
    │            Return Error:                    DELETE from DB                      │
    │         SEMESTER_HAS_CLASSES                         │                          │
    │                       │                              ▼                          │
    │                       ▼                      Return Success                     │
    │              Toast Error                             │                          │
    │                                                      ▼                          │
    │                                              Toast Success                      │
    │                                              Refresh list                       │
    │                                                                                 │
    └─── User hủy ──────────────────────────────────────────────────────> Đóng dialog
```

---

## 6. Business Rules & Validation

### 6.1 Validation Rules

| Rule        | Mô tả                               | Error Code                    | HTTP Status |
| ----------- | ----------------------------------- | ----------------------------- | ----------- |
| Date Range  | startDate phải trước endDate        | `SEMESTER_INVALID_DATE_RANGE` | 400         |
| Unique Code | Mã học kỳ phải unique               | `SEMESTER_CODE_EXISTS`        | 409         |
| Unique Name | Tên học kỳ phải unique              | `SEMESTER_NAME_EXISTS`        | 409         |
| No Overlap  | Thời gian không trùng semester khác | `SEMESTER_DATE_RANGE_EXISTS`  | 409         |
| Has Classes | Không xóa nếu có lớp học            | `SEMESTER_HAS_CLASSES`        | 409         |
| Not Found   | Semester không tồn tại              | `SEMESTER_NOT_FOUND`          | 404         |

### 6.2 Quy Tắc Semester Đang Diễn Ra (Ongoing)

**Định nghĩa**: Semester được coi là "ongoing" khi ngày hiện tại nằm trong khoảng [startDate, endDate].

```java
boolean isOngoing = !today.isBefore(startDate) && !today.isAfter(endDate);
```

**Hạn chế khi ongoing**:

| Field       | Cho phép thay đổi? | Lý do                    |
| ----------- | ------------------ | ------------------------ |
| `name`      | Có                 | Không ảnh hưởng logic    |
| `code`      | Có                 | Không ảnh hưởng logic    |
| `startDate` | Không              | Ảnh hưởng dữ liệu đã tạo |
| `endDate`   | Không              | Ảnh hưởng lịch đã lên    |
| `isActive`  | Không              | Ảnh hưởng toàn hệ thống  |

### 6.3 CSV Import Feature

**Endpoint**: `POST /api/v1/semesters/import`

**Modes:**

| Mode           | Mô tả                | Khi code tồn tại      |
| -------------- | -------------------- | --------------------- |
| `AddOnly`      | Chỉ thêm records mới | Skip, báo lỗi         |
| `AddAndUpdate` | Thêm hoặc cập nhật   | Update record hiện có |

**CSV Format:**

```csv
code,name,start_date,end_date,status
FA24,Fall 2024,2024-09-01,2024-12-31,true
SP25,Spring 2025,2025-01-15,2025-05-31,true
SU25,Summer 2025,2025-06-01,2025-08-31,false
```

**Xử lý lỗi:**

- Mỗi row được xử lý trong transaction riêng (partial success)
- Row lỗi được ghi nhận, không ảnh hưởng row khác
- Response trả về: successCount, failureCount, errorDetails[]

### 6.4 Scheduled Tasks Liên Quan

**AttendanceFinalizeScheduler**:

- Tự động finalize attendance cuối ngày cho các slot trong semester
- Chạy 23:59 (Vietnam time) cho lecture slots
- Chạy mỗi phút để check exam slots hết hạn (+ 10 phút grace period)

---

## 7. Hướng Dẫn Phát Triển

### 7.1 Danh Sách File Quan Trọng

**Backend** (theo thứ tự nên đọc):

| #   | File                         | Mô tả            | Đường dẫn                   |
| --- | ---------------------------- | ---------------- | --------------------------- |
| 1   | `Semester.java`              | Entity structure | `backend/.../entity/`       |
| 2   | `SemesterDTO.java`           | Response format  | `backend/.../dto/response/` |
| 3   | `SemesterCreateRequest.java` | Input validation | `backend/.../dto/request/`  |
| 4   | `SemesterService.java`       | Business logic   | `backend/.../service/`      |
| 5   | `SemesterRepository.java`    | Custom queries   | `backend/.../repository/`   |
| 6   | `SemesterController.java`    | API endpoints    | `backend/.../controller/`   |

**Frontend** (theo thứ tự nên đọc):

| #   | File                       | Mô tả             | Đường dẫn                                  |
| --- | -------------------------- | ----------------- | ------------------------------------------ |
| 1   | `types/index.ts`           | Type definitions  | `frontend-web/types/`                      |
| 2   | `useSemesters.ts`          | API hooks         | `frontend-web/hooks/api/`                  |
| 3   | `page.tsx`                 | Main page         | `frontend-web/app/admin/semesters/`        |
| 4   | `semester-form-dialog.tsx` | Form & validation | `frontend-web/components/admin/semesters/` |
| 5   | `semester-table.tsx`       | Table display     | `frontend-web/components/admin/semesters/` |

### 7.2 FAQ - Câu Hỏi Thường Gặp

**Q1: Làm sao để thêm field mới cho Semester?**

```
Backend:
1. Thêm field vào Semester.java entity
2. Tạo migration script (nếu cần)
3. Cập nhật SemesterDTO.java
4. Cập nhật Create/UpdateRequest.java
5. Cập nhật SemesterMapper.java

Frontend:
6. Cập nhật type trong types/index.ts
7. Cập nhật form trong semester-form-dialog.tsx
8. Cập nhật columns trong semester-columns.tsx
```

**Q2: Semester selector trong form khác hoạt động như thế nào?**

- Sử dụng hook `useGetSemesters()` để fetch danh sách
- Auto-select semester hiện tại dựa trên date range
- Hiển thị format: `{code} - {name}`
- Component tham khảo: `SlotSemesterFilter` (supervisor/reports)

**Q3: Làm sao biết semester nào đang diễn ra?**

```java
// Backend: SemesterRepository.java
List<Semester> findCurrentSemesters();
// Query: WHERE CURRENT_DATE BETWEEN startDate AND endDate
```

**Q4: Tại sao không xóa được semester?**

- Kiểm tra semester có lớp học không
- Nếu có → phải xóa/chuyển lớp học trước
- Error: `SEMESTER_HAS_CLASSES`

### 7.3 Error Codes Reference

| Error Code                            | HTTP | Mô tả                | Xử lý                |
| ------------------------------------- | ---- | -------------------- | -------------------- |
| `SEMESTER_NOT_FOUND`                  | 404  | ID không tồn tại     | Kiểm tra lại ID      |
| `SEMESTER_CODE_EXISTS`                | 409  | Code đã tồn tại      | Đổi code khác        |
| `SEMESTER_NAME_EXISTS`                | 409  | Name đã tồn tại      | Đổi name khác        |
| `SEMESTER_DATE_RANGE_EXISTS`          | 409  | Thời gian trùng lặp  | Chọn date range khác |
| `SEMESTER_INVALID_DATE_RANGE`         | 400  | endDate <= startDate | Sửa lại dates        |
| `SEMESTER_ONGOING_CANNOT_BE_MODIFIED` | 409  | Đang trong kỳ học    | Chỉ đổi name/code    |
| `SEMESTER_HAS_CLASSES`                | 409  | Có lớp học liên kết  | Xóa lớp học trước    |

---

## Tóm Tắt

### Điểm Chính Cần Nhớ

1. **Semester là foundation module** - Tất cả lớp học, buổi học đều tham chiếu đến semester

2. **Validation chặt chẽ**:

   - Date range hợp lệ (start < end)
   - Code, name unique
   - Không overlap với semester khác

3. **Quy tắc Ongoing**:

   - Semester đang diễn ra → Hạn chế thay đổi
   - Chỉ cho phép đổi name và code

4. **Kiến trúc rõ ràng**:

   - Backend: Controller → Service → Repository → Entity
   - Frontend: Page → Components → Hooks → API

5. **Xóa có điều kiện**:
   - Không thể xóa semester có lớp học
   - Phải xóa dependencies trước

### Khi Trình Bày Hội Đồng

- **Giải thích vai trò**: Semester như "container" chứa toàn bộ hoạt động học kỳ
- **Demo CRUD**: Tạo → Sửa → Tìm kiếm → Import CSV → Xóa
- **Nhấn mạnh validation**: Unique constraints, date overlap check
- **Business rules**: Ongoing semester restrictions
- **Integration**: Liên kết với Class, Slot, Attendance modules
