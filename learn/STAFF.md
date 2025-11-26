# Staff Module - Tài Liệu Kỹ Thuật

> **Mục đích tài liệu**: Giúp người đọc hiểu và làm việc với module Staff (Nhân viên) trong hệ thống FUACS - Hệ thống Điểm danh Tự động sử dụng Nhận diện Khuôn mặt.

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

### 1.1 Staff là gì?

**Staff (Nhân viên)** là người dùng hệ thống có vai trò quản lý, giảng dạy hoặc giám sát trong FUACS. Mỗi nhân viên được định danh bằng mã nhân viên (staff code) và có thể có một hoặc nhiều vai trò.

**StaffProfile** là bản ghi mở rộng của User, chứa thông tin đặc thù của nhân viên như mã nhân viên. Khác với StudentProfile, StaffProfile không có thêm các trường khác ngoài `staffCode`.

### 1.2 Các Loại Staff trong Hệ thống

| Vai trò           | Mô tả                                         | Ví dụ                                 |
| ----------------- | --------------------------------------------- | ------------------------------------- |
| **DATA_OPERATOR** | Nhân viên nhập liệu, quản lý dữ liệu hệ thống | operator01 quản lý sinh viên, lớp học |
| **LECTURER**      | Giảng viên, phụ trách giảng dạy các lớp học   | lecturer01 dạy lớp SE1234             |
| **SUPERVISOR**    | Giám sát viên, phụ trách giám sát kỳ thi      | supervisor01 giám sát phòng thi A101  |

> **Lưu ý**: Một nhân viên có thể có nhiều vai trò cùng lúc (ví dụ: vừa là LECTURER vừa là SUPERVISOR).

### 1.3 Mối Quan Hệ với Các Module Khác

```
                         ┌─────────────────┐
                         │      USER       │
                         │  (Tài khoản)    │
                         └────────┬────────┘
                                  │ 1:1
                                  ▼
                         ┌─────────────────┐
                         │  STAFF PROFILE  │
                         │  (Hồ sơ NV)     │
                         └────────┬────────┘
                                  │
         ┌────────────────────────┼────────────────────────┐
         │                        │                        │
         ▼                        ▼                        ▼
┌─────────────────┐      ┌─────────────────┐      ┌─────────────────┐
│      SLOT       │      │ ACADEMIC CLASS  │      │      ROOM       │
│  (Buổi học/thi) │      │   (Lớp học)     │      │   (Phòng học)   │
└─────────────────┘      └─────────────────┘      └─────────────────┘
         │                        │
         ▼                        ▼
┌─────────────────┐      ┌─────────────────┐
│   ATTENDANCE    │      │   ENROLLMENT    │
│  (Điểm danh)    │      │  (Đăng ký lớp)  │
└─────────────────┘      └─────────────────┘
```

**Giải thích quan hệ:**

- **User ↔ StaffProfile**: 1:1 qua `@MapsId` (shared primary key)
- **Staff → Slot**: Staff được gán làm người phụ trách buổi học/thi (`staff_user_id`)
- **Staff → AcademicClass**: Giảng viên được gán cho lớp học
- **Staff → Room**: Giám sát viên được phân công phòng thi
- **Staff → Attendance**: Staff xác nhận điểm danh

---

## 2. Kiến Trúc Hệ Thống

### 2.1 Tổng Quan Kiến Trúc

```
┌─────────────────────────────────────────────────────────────────┐
│                        FRONTEND (Next.js)                       │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────────┐  │
│  │   Admin     │  │ Supervisor  │  │       Lecturer          │  │
│  │ /admin/*    │  │/supervisor/*│  │     /lecturer/*         │  │
│  └──────┬──────┘  └──────┬──────┘  └───────────┬─────────────┘  │
│         │                │                      │                │
│         └────────────────┼──────────────────────┘                │
│                          ▼                                       │
│              ┌─────────────────────┐                             │
│              │   React Query Hooks │                             │
│              │  useStaffProfiles   │                             │
│              └──────────┬──────────┘                             │
└─────────────────────────┼───────────────────────────────────────┘
                          │ REST API
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│                      BACKEND (Spring Boot)                      │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │               StaffProfileController                       │  │
│  │            /api/v1/staff-profiles/*                        │  │
│  └─────────────────────────┬─────────────────────────────────┘  │
│                            ▼                                     │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │                StaffProfileService                         │  │
│  │   CRUD + CSV Import + Role Validation + Slot Assignment   │  │
│  └─────────────────────────┬─────────────────────────────────┘  │
│                            ▼                                     │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │              StaffProfileRepository                        │  │
│  │     JPA + Custom Queries + Search Implementation          │  │
│  └─────────────────────────┬─────────────────────────────────┘  │
└─────────────────────────────┼───────────────────────────────────┘
                              │
                              ▼
                    ┌─────────────────┐
                    │   PostgreSQL    │
                    │  staff_profiles │
                    │     users       │
                    │   user_roles    │
                    └─────────────────┘
```

### 2.2 Cấu Trúc Thư Mục

**Backend:**

```
backend/src/main/java/com/fuacs/backend/
├── entity/
│   ├── StaffProfile.java          # Entity chính
│   └── User.java                  # Entity User (base)
├── dto/
│   ├── request/
│   │   ├── StaffProfileCreateRequest.java
│   │   ├── StaffProfileUpdateRequest.java
│   │   ├── StaffProfileSearchRequest.java
│   │   └── StaffProfileCsvRow.java
│   └── response/
│       ├── StaffProfileDTO.java
│       └── ImportResultDTO.java
├── repository/
│   ├── StaffProfileRepository.java
│   └── impl/
│       └── StaffProfileRepositoryImpl.java
├── service/
│   └── StaffProfileService.java
├── controller/
│   └── StaffProfileController.java
└── dto/mapper/
    └── StaffProfileMapper.java
```

**Frontend:**

```
frontend-web/
├── app/
│   ├── admin/users-roles/
│   │   └── page.tsx               # Trang quản lý Staff (Tab)
│   └── supervisor/
│       ├── dashboard/page.tsx     # Dashboard giám sát
│       ├── schedule/page.tsx      # Lịch giám sát
│       ├── slots/
│       │   ├── page.tsx           # Danh sách slot
│       │   └── [id]/attendance/   # Điểm danh
│       ├── reports/               # Báo cáo
│       └── profile/page.tsx       # Hồ sơ cá nhân
├── components/admin/users-roles/
│   ├── staff-table.tsx            # Bảng danh sách Staff
│   ├── staff-columns.tsx          # Định nghĩa cột
│   ├── staff-form-dialogs.tsx     # Dialog tạo/sửa
│   ├── multi-select-roles.tsx     # Chọn nhiều vai trò
│   ├── staff-class-summary-view.tsx   # Chi tiết lớp (Lecturer)
│   └── staff-slot-summary-view.tsx    # Chi tiết slot (Supervisor)
├── hooks/api/
│   └── useStaffProfiles.ts        # React Query hooks
└── lib/
    ├── constants.ts               # Query keys, API endpoints
    └── zod-schemas.ts             # Validation schemas
```

---

## 3. Backend Implementation

### 3.1 Database Schema

**Bảng `staff_profiles`:**

```sql
CREATE TABLE staff_profiles (
    user_id INTEGER PRIMARY KEY,
    staff_code VARCHAR(20) NOT NULL UNIQUE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
```

**Bảng `users` (liên quan):**

```sql
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(128) NOT NULL UNIQUE,
    full_name VARCHAR(150) NOT NULL,
    password_hash VARCHAR(255),
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);
```

**Bảng `user_roles` (Many-to-Many):**

```sql
CREATE TABLE user_roles (
    user_id INTEGER REFERENCES users(id),
    role_id SMALLINT REFERENCES roles(id),
    PRIMARY KEY (user_id, role_id)
);
```

**Sơ đồ ER:**

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│     users       │     │  staff_profiles │     │   user_roles    │
├─────────────────┤     ├─────────────────┤     ├─────────────────┤
│ id (PK)         │◄───┤│ user_id (PK,FK)│     │ user_id (FK)    │
│ username        │     │ staff_code      │     │ role_id (FK)    │
│ email           │     └─────────────────┘     └─────────────────┘
│ full_name       │                                     │
│ password_hash   │                                     ▼
│ is_active       │                             ┌─────────────────┐
│ created_at      │                             │     roles       │
│ updated_at      │                             ├─────────────────┤
└─────────────────┘                             │ id (PK)         │
                                                │ name            │
                                                └─────────────────┘
```

### 3.2 REST API Endpoints

**Base URL:** `/api/v1/staff-profiles`

| Method | Endpoint         | Mô tả                   | Permission       |
| ------ | ---------------- | ----------------------- | ---------------- |
| POST   | `/`              | Tạo mới staff           | USER_CREATE      |
| GET    | `/`              | Tìm kiếm với pagination | USER_READ_LIST   |
| GET    | `/{id}`          | Lấy chi tiết            | USER_READ_DETAIL |
| PUT    | `/{id}`          | Cập nhật                | USER_UPDATE_INFO |
| DELETE | `/{id}`          | Xóa (hard delete)       | USER_DELETE_HARD |
| POST   | `/import`        | Import từ CSV           | STAFF_IMPORT     |
| GET    | `/{id}/classes`  | Lớp học của staff       | CLASS_READ       |
| GET    | `/{id}/subjects` | Môn học của staff       | SUBJECT_READ     |
| GET    | `/{id}/rooms`    | Phòng của staff         | ROOM_READ        |
| GET    | `/{id}/slots`    | Buổi học/thi của staff  | SLOT_READ        |

**Ví dụ Request/Response:**

```http
POST /api/v1/staff-profiles
Content-Type: application/json

{
  "fullName": "Nguyễn Văn A",
  "email": "nguyenvana@fpt.edu.vn",
  "staffCode": "NVA001",
  "username": "nguyenvana",
  "password": "optional123",
  "roles": ["LECTURER", "SUPERVISOR"]
}
```

```json
// Response 201 Created
{
  "status": 201,
  "data": {
    "userId": 15,
    "fullName": "Nguyễn Văn A",
    "email": "nguyenvana@fpt.edu.vn",
    "username": "nguyenvana",
    "staffCode": "NVA001",
    "roles": ["LECTURER", "SUPERVISOR"],
    "isActive": true,
    "createdAt": "2025-01-15T10:30:00Z",
    "updatedAt": "2025-01-15T10:30:00Z"
  }
}
```

### 3.3 Data Transfer Objects (DTOs)

**StaffProfileCreateRequest:**

```java
public class StaffProfileCreateRequest {
    @NotBlank @Size(max = 150)
    private String fullName;

    @NotBlank @Email @Size(max = 128)
    private String email;

    @NotBlank @Size(max = 20) @Pattern(regexp = "^[A-Za-z0-9]+$")
    private String staffCode;

    @NotBlank @Size(min = 3, max = 50) @Pattern(regexp = "^[A-Za-z0-9_]+$")
    private String username;

    @Size(min = 8)
    private String password;  // Optional

    private Set<String> roles;
}
```

**StaffProfileDTO (Response):**

```java
public class StaffProfileDTO extends BaseDTO {
    private Integer userId;
    private String fullName;
    private String email;
    private String username;
    private String staffCode;
    private List<String> roles;
    // Kế thừa: isActive, createdAt, updatedAt
}
```

### 3.4 Service Layer

**StaffProfileService** - Các phương thức chính:

| Phương thức                 | Mô tả                    |
| --------------------------- | ------------------------ |
| `create(request)`           | Tạo mới staff + user     |
| `update(id, request)`       | Cập nhật thông tin       |
| `delete(id)`                | Xóa (kiểm tra ràng buộc) |
| `findById(id)`              | Lấy chi tiết             |
| `search(request)`           | Tìm kiếm với pagination  |
| `importFromCsv(file, mode)` | Import hàng loạt         |

**Đặc điểm quan trọng:**

- **Partial Success Pattern**: Import CSV không rollback toàn bộ nếu 1 dòng lỗi
- **Transaction Isolation**: Mỗi dòng CSV xử lý trong transaction riêng (`REQUIRES_NEW`)
- **Role Validation**: Không được gán role STUDENT cho staff

### 3.5 Repository Layer

**Custom Search Implementation:**

```java
// StaffProfileRepositoryImpl.java
public Page<StaffProfile> search(StaffProfileSearchRequest request, Pageable pageable) {
    // Tìm kiếm theo: fullName, staffCode, email, username
    // Lọc theo: isActive, roleIds, excludeRoles
    // JOIN FETCH để tối ưu N+1
}
```

**Sortable Fields:**

- `fullName` → `u.fullName`
- `staffCode` → `sp.staffCode`
- `email` → `u.email`

---

## 4. Frontend Implementation

### 4.1 Các Trang Quản Lý Staff

| Route                               | Component  | Mô tả                   | Role          |
| ----------------------------------- | ---------- | ----------------------- | ------------- |
| `/admin/users-roles?tab=staffs`     | StaffsTab  | Quản lý danh sách staff | DATA_OPERATOR |
| `/supervisor/dashboard`             | Dashboard  | Tổng quan giám sát      | SUPERVISOR    |
| `/supervisor/schedule`              | Schedule   | Lịch giám sát kỳ thi    | SUPERVISOR    |
| `/supervisor/slots`                 | MySlots    | Danh sách slot được gán | SUPERVISOR    |
| `/supervisor/slots/{id}/attendance` | Attendance | Điểm danh kỳ thi        | SUPERVISOR    |
| `/supervisor/profile`               | Profile    | Hồ sơ cá nhân           | SUPERVISOR    |

### 4.2 Component Structure

```
AdminUsersRolesPage
├── Tabs
│   ├── StudentsTab
│   └── StaffsTab ◄── Quản lý Staff
│       ├── Filters (search, roles, status)
│       ├── StaffTable
│       │   └── Columns: Code | Name | Email | Roles | Status | Actions
│       ├── CreateStaffDialog
│       ├── EditStaffDialog
│       ├── StaffClassSummaryView (cho LECTURER)
│       └── StaffSlotSummaryView (cho SUPERVISOR)
└── ImportDialog (CSV Import)
```

### 4.3 React Query Hooks

**File:** `hooks/api/useStaffProfiles.ts`

| Hook                          | Mục đích                 |
| ----------------------------- | ------------------------ |
| `useGetStaffProfiles(params)` | Danh sách với pagination |
| `useGetStaffProfile(id)`      | Chi tiết một staff       |
| `useCreateStaffProfile()`     | Mutation tạo mới         |
| `useUpdateStaffProfile()`     | Mutation cập nhật        |
| `useDeleteStaffProfile()`     | Mutation xóa             |
| `useImportStaffProfiles()`    | Import từ CSV            |
| `useGetStaffClasses(id)`      | Lớp học của staff        |
| `useGetStaffSubjects(id)`     | Môn học của staff        |
| `useGetStaffRooms(id)`        | Phòng của staff          |
| `useGetStaffSlots(id)`        | Slot của staff           |

**Query Keys:**

```typescript
staffProfiles: {
  all: ["staff-profiles"],
  detail: (id) => ["staff-profiles", id],
  classes: (id) => ["staff-profiles", id, "classes"],
  subjects: (id) => ["staff-profiles", id, "subjects"],
  rooms: (id) => ["staff-profiles", id, "rooms"],
  slots: (id) => ["staff-profiles", id, "slots"],
}
```

### 4.4 TypeScript Types

```typescript
// StaffProfile type
interface StaffProfile {
  userId: number;
  fullName: string;
  email: string;
  username: string;
  staffCode: string;
  roles: ("LECTURER" | "SUPERVISOR" | "DATA_OPERATOR")[];
  isActive: boolean;
  createdAt: string;
  updatedAt: string;
}

// Query parameters
interface StaffProfileQueryParams {
  page?: number;
  pageSize?: number;
  sort?: "asc" | "desc";
  sortBy?: "fullName" | "staffCode" | "email";
  search?: string;
  roleIds?: number[];
  excludeRoles?: string[];
  isActive?: boolean;
}
```

### 4.5 Zod Validation Schemas

```typescript
// Create validation
const createStaffProfilePayloadSchema = z.object({
  fullName: z.string().min(1).max(150),
  email: z.string().email().max(255),
  username: z
    .string()
    .min(1)
    .max(50)
    .regex(/^[A-Za-z0-9_]+$/),
  staffCode: z
    .string()
    .min(1)
    .max(20)
    .regex(/^[A-Za-z0-9]+$/),
  roles: z
    .array(z.enum(["LECTURER", "SUPERVISOR", "DATA_OPERATOR"]))
    .min(1, "At least one role is required"),
});

// Update validation
const updateStaffProfilePayloadSchema = createStaffProfilePayloadSchema.extend({
  isActive: z.boolean(),
});
```

---

## 5. Luồng Xử Lý Nghiệp Vụ

### 5.1 Luồng Tạo Mới Staff

```
┌──────┐      ┌──────────┐      ┌─────────┐      ┌────────┐
│ User │      │ Frontend │      │ Backend │      │   DB   │
└──┬───┘      └────┬─────┘      └────┬────┘      └────┬───┘
   │               │                 │                │
   │ 1. Fill form  │                 │                │
   │──────────────>│                 │                │
   │               │                 │                │
   │               │ 2. Validate     │                │
   │               │    (Zod)        │                │
   │               │                 │                │
   │               │ 3. POST /staff-profiles          │
   │               │────────────────>│                │
   │               │                 │                │
   │               │                 │ 4. Check unique│
   │               │                 │    username,   │
   │               │                 │    email,      │
   │               │                 │    staffCode   │
   │               │                 │───────────────>│
   │               │                 │<───────────────│
   │               │                 │                │
   │               │                 │ 5. Validate    │
   │               │                 │    roles       │
   │               │                 │    (no STUDENT)│
   │               │                 │                │
   │               │                 │ 6. Create User │
   │               │                 │───────────────>│
   │               │                 │                │
   │               │                 │ 7. Create      │
   │               │                 │    StaffProfile│
   │               │                 │───────────────>│
   │               │                 │                │
   │               │                 │ 8. Assign Roles│
   │               │                 │───────────────>│
   │               │                 │<───────────────│
   │               │                 │                │
   │               │ 9. Return DTO   │                │
   │               │<────────────────│                │
   │               │                 │                │
   │ 10. Toast +   │                 │                │
   │     Refresh   │                 │                │
   │<──────────────│                 │                │
```

### 5.2 Luồng Import Staff từ CSV

```
┌──────┐      ┌──────────┐      ┌─────────┐      ┌────────┐
│ User │      │ Frontend │      │ Backend │      │   DB   │
└──┬───┘      └────┬─────┘      └────┬────┘      └────┬───┘
   │               │                 │                │
   │ 1. Upload CSV │                 │                │
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
   │               │                 │    by staffCode│
   │               │                 │                │
   │               │                 │ ┌─────────────┐│
   │               │                 │ │ For each row││
   │               │                 │ │ (NEW TX)    ││
   │               │                 │ │             ││
   │               │                 │ │ 5. Validate ││
   │               │                 │ │    row      ││
   │               │                 │ │             ││
   │               │                 │ │ 6. Create/  ││
   │               │                 │ │    Update   ││
   │               │                 │ │─────────────>│
   │               │                 │ │             ││
   │               │                 │ │ 7. Log error││
   │               │                 │ │    if fail  ││
   │               │                 │ └─────────────┘│
   │               │                 │                │
   │               │ 8. Return       │                │
   │               │    ImportResult │                │
   │               │<────────────────│                │
   │               │                 │                │
   │ 9. Show result│                 │                │
   │    (success/  │                 │                │
   │     errors)   │                 │                │
   │<──────────────│                 │                │
```

### 5.3 Luồng Supervisor Điểm Danh Kỳ Thi

```
┌────────────┐      ┌──────────┐      ┌─────────┐      ┌─────────────┐
│ Supervisor │      │ Frontend │      │ Backend │      │ Recognition │
└─────┬──────┘      └────┬─────┘      └────┬────┘      └──────┬──────┘
      │                  │                 │                   │
      │ 1. Open slot     │                 │                   │
      │     attendance   │                 │                   │
      │─────────────────>│                 │                   │
      │                  │                 │                   │
      │                  │ 2. GET slot     │                   │
      │                  │    roster       │                   │
      │                  │────────────────>│                   │
      │                  │<────────────────│                   │
      │                  │                 │                   │
      │ 3. Start exam    │                 │                   │
      │    session       │                 │                   │
      │─────────────────>│                 │                   │
      │                  │ 4. POST start   │                   │
      │                  │────────────────>│                   │
      │                  │                 │ 5. Notify camera  │
      │                  │                 │──────────────────>│
      │                  │                 │                   │
      │                  │                 │                   │
      │                  │ 6. SSE: Real-time updates           │
      │                  │<─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─│
      │                  │                 │                   │
      │ 7. Manual update │                 │                   │
      │    (if needed)   │                 │                   │
      │─────────────────>│                 │                   │
      │                  │ 8. PUT          │                   │
      │                  │    attendance   │                   │
      │                  │────────────────>│                   │
      │                  │                 │                   │
      │ 9. Submit final  │                 │                   │
      │─────────────────>│                 │                   │
      │                  │ 10. POST submit │                   │
      │                  │────────────────>│                   │
```

### 5.4 Luồng Xem Chi Tiết Staff (Class/Slot Summary)

```
┌──────┐      ┌──────────┐      ┌─────────┐
│Admin │      │ Frontend │      │ Backend │
└──┬───┘      └────┬─────┘      └────┬────┘
   │               │                 │
   │ 1. Click      │                 │
   │    "Class     │                 │
   │    Summary"   │                 │
   │──────────────>│                 │
   │               │                 │
   │               │ 2. Open Dialog  │
   │               │                 │
   │               │ 3. GET semesters│
   │               │    + classes    │
   │               │────────────────>│
   │               │<────────────────│
   │               │                 │
   │ 4. Select     │                 │
   │    semester   │                 │
   │──────────────>│                 │
   │               │                 │
   │               │ 5. Filter       │
   │               │    classes      │
   │               │                 │
   │ 6. Click      │                 │
   │    "View"     │                 │
   │    class      │                 │
   │──────────────>│                 │
   │               │                 │
   │               │ 7. GET class    │
   │               │    summary      │
   │               │────────────────>│
   │               │<────────────────│
   │               │                 │
   │ 8. View       │                 │
   │    attendance │                 │
   │    matrix     │                 │
   │<──────────────│                 │
```

---

## 6. Business Rules & Validation

### 6.1 Quy Tắc Validation

| Field       | Rule                                          | HTTP Status     |
| ----------- | --------------------------------------------- | --------------- |
| `staffCode` | Unique, 1-20 chars, alphanumeric              | 409 CONFLICT    |
| `username`  | Unique, 3-50 chars, alphanumeric + underscore | 409 CONFLICT    |
| `email`     | Unique, valid email format                    | 409 CONFLICT    |
| `fullName`  | Required, 1-150 chars                         | 400 BAD_REQUEST |
| `roles`     | Min 1 role, không được có STUDENT             | 400 BAD_REQUEST |
| `password`  | Min 8 chars (optional khi create)             | 400 BAD_REQUEST |

### 6.2 Quy Tắc Nghiệp Vụ

| Quy tắc                 | Mô tả                                                   |
| ----------------------- | ------------------------------------------------------- |
| **Role Restriction**    | Staff KHÔNG được có role STUDENT                        |
| **Delete Protection**   | Không thể xóa staff đang có slot assignments            |
| **Username Immutable**  | Username không thể thay đổi sau khi tạo                 |
| **Password Generation** | Nếu không cung cấp password, hệ thống sinh UUID         |
| **Multiple Roles**      | Một staff có thể có nhiều roles (LECTURER + SUPERVISOR) |
| **Cascade Delete**      | Xóa User tự động xóa StaffProfile                       |

### 6.3 CSV Import Rules

**Format CSV:**

```csv
full_name,email,staff_code,roles[,status,password]
Nguyễn Văn A,a@fpt.edu.vn,NVA001,LECTURER
Trần Thị B,b@fpt.edu.vn,TTB002,"LECTURER,SUPERVISOR",true
```

**Import Modes:**

- `AddOnly`: Chỉ thêm mới, báo lỗi nếu staffCode đã tồn tại
- `AddAndUpdate`: Thêm mới hoặc cập nhật nếu đã tồn tại

**Constraints:**

- Max file size: 5MB
- Max rows: 10,000
- Encoding: UTF-8
- Partial success: Dòng lỗi không ảnh hưởng dòng khác

### 6.4 Error Codes

| Code                               | Mô tả                         | HTTP Status |
| ---------------------------------- | ----------------------------- | ----------- |
| `EMAIL_EXISTS`                     | Email đã tồn tại              | 409         |
| `USERNAME_EXISTS`                  | Username đã tồn tại           | 409         |
| `STAFF_CODE_EXISTS`                | Staff code đã tồn tại         | 409         |
| `STAFF_PROFILE_NOT_FOUND`          | Không tìm thấy staff          | 404         |
| `INVALID_ROLE`                     | Role không hợp lệ             | 400         |
| `ROLES_REQUIRED`                   | Cần ít nhất một role          | 400         |
| `INVALID_IMPORT_MODE`              | Mode import không hợp lệ      | 400         |
| `INVALID_CSV_FORMAT`               | Format CSV sai                | 400         |
| `FOREIGN_KEY_CONSTRAINT_VIOLATION` | Không thể xóa vì có ràng buộc | 409         |

---

## 7. Hướng Dẫn Phát Triển

### 7.1 Danh Sách File Quan Trọng

| File                                                          | Mô tả              |
| ------------------------------------------------------------- | ------------------ |
| `backend/.../entity/StaffProfile.java`                        | Entity chính       |
| `backend/.../entity/User.java`                                | Entity User (base) |
| `backend/.../service/StaffProfileService.java`                | Business logic     |
| `backend/.../controller/StaffProfileController.java`          | REST API           |
| `backend/.../repository/impl/StaffProfileRepositoryImpl.java` | Custom queries     |
| `frontend-web/app/admin/users-roles/page.tsx`                 | Trang quản lý      |
| `frontend-web/hooks/api/useStaffProfiles.ts`                  | React Query hooks  |
| `frontend-web/components/admin/users-roles/staff-*.tsx`       | UI components      |
| `frontend-web/lib/zod-schemas.ts`                             | Validation schemas |

### 7.2 So Sánh StaffProfile vs StudentProfile

| Đặc tính               | StaffProfile                      | StudentProfile            |
| ---------------------- | --------------------------------- | ------------------------- |
| **Unique Field**       | staffCode                         | rollNumber                |
| **Extends BaseEntity** | Không                             | Có                        |
| **Audit Fields**       | Không (từ User)                   | Có (createdAt, updatedAt) |
| **FK to Major**        | Không                             | Có (ManyToOne)            |
| **Additional Fields**  | Không                             | baseUrl (photo URL)       |
| **Face Embedding**     | Không                             | Có (face recognition)     |
| **Role**               | LECTURER/SUPERVISOR/DATA_OPERATOR | STUDENT                   |

### 7.3 FAQ - Câu Hỏi Thường Gặp

**Q: Sao StaffProfile không có createdAt, updatedAt?**

> A: StaffProfile không extends BaseEntity. Thông tin audit được lấy từ User entity thông qua relationship.

**Q: Làm sao phân biệt Lecturer và Supervisor?**

> A: Qua roles trong User. Một staff có thể có cả hai roles.

**Q: Staff có face recognition không?**

> A: Không. Chỉ Student mới có face embedding cho điểm danh tự động.

**Q: Xóa staff có ảnh hưởng gì không?**

> A: Không thể xóa nếu staff còn được gán slot. Phải remove assignments trước.

**Q: Import CSV có rollback không?**

> A: Không. Dùng partial success pattern - mỗi dòng xử lý riêng biệt.

### 7.4 Tóm Tắt Điểm Chính

1. **Staff = User + StaffProfile** (1:1 qua @MapsId)
2. **3 loại staff**: DATA_OPERATOR, LECTURER, SUPERVISOR
3. **Staff có thể có nhiều roles** cùng lúc
4. **Không có face recognition** cho staff (chỉ student)
5. **Delete protection**: Kiểm tra slot assignments
6. **CSV Import**: Partial success với REQUIRES_NEW transaction
7. **Frontend**: Tab trong Users & Roles page

### 7.5 Các Bước Khi Trình Bày Hội Đồng

1. **Giới thiệu module**: Staff là gì, phân biệt 3 loại
2. **Demo tạo mới**: Form validation, role selection
3. **Demo import CSV**: Partial success, error handling
4. **Show database**: users + staff_profiles tables, relationship
5. **Show slot assignment**: Lecturer → Class, Supervisor → Exam
6. **Demo điểm danh**: Supervisor workflow cho kỳ thi
