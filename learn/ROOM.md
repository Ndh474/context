# Room Module - Tài Liệu Kỹ Thuật

> **Mục đích tài liệu**: Giúp người đọc hiểu và làm việc với module Room (Phòng học/thi) trong hệ thống FUACS - Hệ thống Điểm danh Tự động sử dụng Nhận diện Khuôn mặt.

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

### 1.1 Room là gì?

**Room (Phòng)** là đơn vị cơ sở vật chất trong hệ thống FUACS, đại diện cho không gian vật lý nơi diễn ra các buổi học hoặc kỳ thi. Mỗi phòng có thể được lắp đặt camera để nhận diện khuôn mặt sinh viên khi điểm danh.

**Đặc điểm chính:**

- Mã phòng (name) là duy nhất trong hệ thống
- Một phòng có thể có nhiều camera
- Một phòng có thể có nhiều slot (buổi học/thi) được phân công

### 1.2 Các Loại Phòng trong Hệ thống

| Loại phòng           | Số lượng (seed) | Ví dụ                             |
| -------------------- | --------------- | --------------------------------- |
| **Phòng học thường** | 15 phòng        | Room 101, 201, 301, B101, B201... |
| **Phòng Lab**        | 7 phòng         | Lab 401, Lab B401, Lab C101...    |
| **Phòng Thi**        | 3 phòng         | Exam Hall 1, 2, 3                 |

> **Lưu ý**: Mỗi phòng trong seed data được cấu hình với 2 camera sẵn.

### 1.3 Mối Quan Hệ với Các Module Khác

```
                    ┌─────────────────┐
                    │      ROOM       │
                    │   (Phòng học)   │
                    └────────┬────────┘
                             │
            ┌────────────────┼────────────────┐
            │                │                │
            ▼                ▼                ▼
   ┌─────────────────┐  ┌─────────────┐  ┌─────────────────┐
   │     CAMERA      │  │    SLOT     │  │  (Thống kê)     │
   │  (Camera giám   │  │ (Buổi học/  │  │  totalCameras   │
   │   sát trong     │  │   thi)      │  │  activeCameras  │
   │   phòng)        │  │             │  │  usageCount     │
   └────────┬────────┘  └──────┬──────┘  └─────────────────┘
            │                  │
            ▼                  ▼
   ┌─────────────────┐  ┌─────────────────┐
   │   RECOGNITION   │  │   ATTENDANCE    │
   │  (Nhận diện     │  │   (Điểm danh)   │
   │   khuôn mặt)    │  │                 │
   └─────────────────┘  └─────────────────┘
```

**Giải thích quan hệ:**

- **Room → Camera**: 1:N - Mỗi phòng có thể có nhiều camera
- **Room → Slot**: 1:N - Mỗi phòng có thể có nhiều buổi học/thi được phân công
- **Camera → Recognition**: Camera capture khuôn mặt để nhận diện
- **Slot → Attendance**: Mỗi slot chứa danh sách điểm danh sinh viên

---

## 2. Kiến Trúc Hệ Thống

### 2.1 Tổng Quan Kiến Trúc

```
┌─────────────────────────────────────────────────────────────────┐
│                        FRONTEND (Next.js)                       │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │                 Admin Portal (/admin/*)                    │  │
│  │  ┌─────────────────────────────────────────────────────┐  │  │
│  │  │          Rooms Management (/admin/rooms)             │  │  │
│  │  │  - List/Search/Filter rooms                          │  │  │
│  │  │  - Create/Edit/Delete rooms                          │  │  │
│  │  │  - Import from CSV                                   │  │  │
│  │  │  - View cameras per room                             │  │  │
│  │  └─────────────────────────────────────────────────────┘  │  │
│  └───────────────────────────────────────────────────────────┘  │
│                              │                                   │
│              ┌───────────────┴───────────────┐                   │
│              │     React Query Hooks         │                   │
│              │        useRooms               │                   │
│              └───────────────┬───────────────┘                   │
└──────────────────────────────┼──────────────────────────────────┘
                               │ REST API
                               ▼
┌─────────────────────────────────────────────────────────────────┐
│                      BACKEND (Spring Boot)                      │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │                    RoomController                          │  │
│  │                  /api/v1/rooms/*                           │  │
│  └─────────────────────────┬─────────────────────────────────┘  │
│                            ▼                                     │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │                     RoomService                            │  │
│  │   CRUD + CSV Import + Camera Stats + Slot Management      │  │
│  └─────────────────────────┬─────────────────────────────────┘  │
│                            ▼                                     │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │                   RoomRepository                           │  │
│  │        JPA + Custom Queries + Search Implementation       │  │
│  └─────────────────────────┬─────────────────────────────────┘  │
└─────────────────────────────┼───────────────────────────────────┘
                              │
                              ▼
                    ┌─────────────────┐
                    │   PostgreSQL    │
                    │     rooms       │
                    │    cameras      │
                    │     slots       │
                    └─────────────────┘
```

### 2.2 Cấu Trúc Thư Mục

**Backend:**

```
backend/src/main/java/com/fuacs/backend/
├── entity/
│   ├── Room.java                 # Entity chính
│   ├── Camera.java               # Entity camera (FK to Room)
│   └── Slot.java                 # Entity slot (FK to Room)
├── dto/
│   ├── request/
│   │   ├── RoomCreateRequest.java
│   │   ├── RoomUpdateRequest.java
│   │   ├── RoomSearchRequest.java
│   │   └── RoomCsvRow.java
│   └── response/
│       ├── RoomDTO.java
│       ├── RoomCamerasResponse.java
│       ├── RoomSlotsResponse.java
│       └── ImportResultDTO.java
├── repository/
│   ├── RoomRepository.java
│   ├── custom/
│   │   └── CustomRoomRepository.java
│   └── impl/
│       └── RoomRepositoryImpl.java
├── service/
│   └── RoomService.java
├── controller/
│   └── RoomController.java
└── dto/mapper/
    └── RoomMapper.java
```

**Frontend:**

```
frontend-web/
├── app/admin/rooms/
│   └── page.tsx                  # Trang quản lý Room
├── components/admin/rooms/
│   ├── room-table.tsx            # Bảng danh sách
│   ├── room-columns.tsx          # Định nghĩa cột
│   ├── room-form-dialog.tsx      # Dialog tạo/sửa
│   ├── room-pagination.tsx       # Pagination
│   └── delete-room-dialog.tsx    # Dialog xóa
├── hooks/api/
│   └── useRooms.ts               # React Query hooks
├── lib/
│   ├── constants.ts              # Query keys, API endpoints
│   └── zod-schemas.ts            # Validation schemas
└── types/
    └── index.ts                  # TypeScript types
```

---

## 3. Backend Implementation

### 3.1 Database Schema

**Bảng `rooms`:**

```sql
CREATE TABLE rooms (
    id SMALLSERIAL PRIMARY KEY,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    name VARCHAR(150) NOT NULL UNIQUE,
    location VARCHAR(255) NULL
);
```

**Bảng `cameras` (liên quan):**

```sql
CREATE TABLE cameras (
    id SMALLSERIAL PRIMARY KEY,
    room_id SMALLINT NOT NULL,
    serial_number VARCHAR(100) NOT NULL UNIQUE,
    rtsp_url VARCHAR(255) NOT NULL UNIQUE,
    location VARCHAR(255),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    FOREIGN KEY (room_id) REFERENCES rooms(id)
);
```

**Bảng `slots` (liên quan):**

```sql
CREATE TABLE slots (
    id SERIAL PRIMARY KEY,
    room_id SMALLINT NOT NULL,
    start_time TIMESTAMP NOT NULL,
    end_time TIMESTAMP NOT NULL,
    slot_category VARCHAR(50) NOT NULL,
    ...
    FOREIGN KEY (room_id) REFERENCES rooms(id)
);

CREATE INDEX idx_slots_room_id ON slots(room_id);
```

**Sơ đồ ER:**

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│     rooms       │     │    cameras      │     │     slots       │
├─────────────────┤     ├─────────────────┤     ├─────────────────┤
│ id (PK)         │◄───┤│ room_id (FK)    │     │ room_id (FK)   │├──►│
│ name (UNIQUE)   │     │ serial_number   │     │ start_time     │
│ location        │     │ rtsp_url        │     │ end_time       │
│ is_active       │     │ location        │     │ slot_category  │
│ created_at      │     │ is_active       │     │ staff_user_id  │
│ updated_at      │     └─────────────────┘     │ is_active      │
└─────────────────┘                             └─────────────────┘
```

### 3.2 Entity Class

**Room.java:**

```java
@Entity
@Table(name = "rooms")
public class Room extends BaseEntity {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Short id;                    // PK: 1-32767

    @Column(name = "name", length = 150, nullable = false, unique = true)
    private String name;                 // Unique: "301", "Lab-A1"

    @Column(name = "location", length = 255)
    private String location;             // Optional: "Tòa A, Tầng 3"

    @OneToMany(mappedBy = "room", fetch = FetchType.LAZY)
    private Set<Camera> cameras;         // Cameras trong phòng

    @OneToMany(mappedBy = "room", fetch = FetchType.LAZY)
    private Set<Slot> slots;             // Slots trong phòng
}
```

**BaseEntity (kế thừa):**

```java
@MappedSuperclass
@EntityListeners(AuditingEntityListener.class)
public class BaseEntity {
    @CreatedDate
    @Column(name = "created_at", updatable = false, nullable = false)
    protected Instant createdAt;

    @LastModifiedDate
    @Column(name = "updated_at", nullable = false)
    protected Instant updatedAt;

    @Column(name = "is_active", nullable = false)
    protected Boolean isActive = true;
}
```

### 3.3 REST API Endpoints

**Base URL:** `/api/v1/rooms`

| Method | Endpoint        | Mô tả                   | Permission       |
| ------ | --------------- | ----------------------- | ---------------- |
| POST   | `/`             | Tạo mới room            | ROOM_CREATE      |
| POST   | `/import`       | Import từ CSV           | ROOM_IMPORT      |
| GET    | `/`             | Tìm kiếm với pagination | ROOM_READ        |
| GET    | `/{id}`         | Lấy chi tiết            | ROOM_READ        |
| PUT    | `/{id}`         | Cập nhật                | ROOM_UPDATE      |
| DELETE | `/{id}`         | Xóa (hard delete)       | ROOM_DELETE_HARD |
| GET    | `/{id}/cameras` | Cameras của room        | ROOM_READ        |
| GET    | `/{id}/slots`   | Slots của room          | ROOM_READ        |

**Ví dụ Request/Response:**

**Tạo mới Room:**

```http
POST /api/v1/rooms
Content-Type: application/json

{
  "name": "305",
  "location": "Tòa A, Tầng 3"
}
```

```json
// Response 201 Created
{
  "status": "success",
  "data": {
    "id": 26,
    "name": "305",
    "location": "Tòa A, Tầng 3",
    "isActive": true,
    "totalCameras": 0,
    "activeCameras": 0,
    "createdAt": "2025-01-15T10:30:00Z",
    "updatedAt": "2025-01-15T10:30:00Z"
  }
}
```

**Tìm kiếm Room:**

```http
GET /api/v1/rooms?search=30&isActive=true&hasCamera=true&page=1&pageSize=10&sortBy=name&sort=asc
```

```json
// Response 200 OK
{
  "status": "success",
  "data": {
    "items": [
      {
        "id": 1,
        "name": "301",
        "location": "Tòa A, Tầng 3",
        "isActive": true,
        "totalCameras": 2,
        "activeCameras": 2
      }
    ],
    "totalPages": 5,
    "currentPage": 1,
    "pageSize": 10,
    "totalItems": 45
  }
}
```

### 3.4 Data Transfer Objects (DTOs)

**RoomCreateRequest:**

```java
public class RoomCreateRequest {
    @NotBlank(message = "Name must not be blank")
    @Size(max = 150)
    @Pattern(regexp = "^[A-Za-z0-9\\-]+( [A-Za-z0-9\\-]+)*$")
    private String name;

    @Size(max = 255)
    private String location;  // Optional
}
```

**RoomUpdateRequest:**

```java
public class RoomUpdateRequest extends BaseRequest {
    @NotBlank
    @Size(max = 150)
    @Pattern(regexp = "^[A-Za-z0-9\\-]+( [A-Za-z0-9\\-]+)*$")
    private String name;

    @Size(max = 255)
    private String location;
    // + isActive từ BaseRequest
}
```

**RoomSearchRequest:**

```java
public class RoomSearchRequest extends PagedRequest {
    private Boolean hasCamera;       // Filter: có/không có camera active
    private Short semesterId;        // Filter: staff-scoped only
    private String startDate;        // Format: YYYY-MM-DD (staff-scoped)
    private String endDate;          // Format: YYYY-MM-DD (staff-scoped)
}
```

**RoomDTO (Response):**

```java
@JsonInclude(JsonInclude.Include.NON_NULL)
public class RoomDTO extends BaseDTO {
    private Short id;
    private String name;
    private String location;

    // Camera statistics
    private Integer totalCameras;        // All cameras
    private Integer activeCameras;       // Only isActive = true

    // Staff-scoped usage statistics
    private Long usageCount;             // Số slot của staff tại phòng
    private Instant lastUsedAt;          // Thời điểm slot cuối kết thúc
    private List<SlotDTO> upcomingSlots; // 3 slot sắp tới
}
```

### 3.5 Service Layer

**RoomService** - Các phương thức chính:

| Phương thức                         | Mô tả                           |
| ----------------------------------- | ------------------------------- |
| `search(request)`                   | Tìm kiếm với camera stats       |
| `count(request)`                    | Đếm tổng số (cho pagination)    |
| `searchByStaffId(staffId, request)` | Phòng của staff với usage stats |
| `findById(id)`                      | Lấy chi tiết                    |
| `create(request)`                   | Tạo mới                         |
| `update(id, request)`               | Cập nhật                        |
| `delete(id)`                        | Xóa (hard delete)               |
| `importFromCsv(file, mode)`         | Import hàng loạt                |

**Đặc điểm quan trọng:**

- **Camera Statistics**: Trả về totalCameras và activeCameras cho mỗi room
- **Staff-scoped Search**: Tìm phòng có slot của staff với usageCount và 3 upcoming slots
- **Partial Success Pattern**: Import CSV không rollback toàn bộ nếu 1 dòng lỗi
- **Transaction Isolation**: Mỗi dòng CSV xử lý trong transaction riêng (`REQUIRES_NEW`)

### 3.6 Repository Layer

**RoomRepository - Query Methods:**

```java
boolean existsByName(String name);
boolean existsByNameAndIdNot(String name, Short id);
Room findByName(String name);

@Query("SELECT COUNT(c.id) FROM Camera c WHERE c.room.id = :roomId AND c.isActive = true")
long countActiveCamerasByRoomId(Short roomId);

@Query("SELECT COUNT(c.id) FROM Camera c WHERE c.room.id = :roomId")
long countAllCamerasByRoomId(Short roomId);

@Query("SELECT COUNT(s.id) FROM Slot s WHERE s.room.id = :roomId AND s.startTime >= :now AND s.isActive = true")
long countActiveSlotsByRoomId(Short roomId, LocalDateTime now);

@Query("SELECT COUNT(s.id) FROM Slot s WHERE s.room.id = :roomId AND s.startTime > :now AND s.isActive = true")
long countFutureSlotsByRoomId(Short roomId, LocalDateTime now);
```

**Sortable Fields:**

- `name` → `r.name`
- `location` → `r.location`
- Default: `r.id ASC`

---

## 4. Frontend Implementation

### 4.1 Trang Quản Lý Room

| Route          | Component | Mô tả                 | Role          |
| -------------- | --------- | --------------------- | ------------- |
| `/admin/rooms` | RoomsPage | Quản lý phòng học/thi | DATA_OPERATOR |

**Features:**

- **Tìm kiếm**: Search theo name/location (debounced 500ms)
- **Lọc**: Status (All/Active/Inactive), HasCamera (All/Yes/No)
- **Sắp xếp**: Name, Location (Asc/Desc)
- **Phân trang**: Default 10 items/page
- **Actions**: Create, Edit, Delete, Import CSV, View Cameras

### 4.2 Component Structure

```
RoomsPage (Wrapper with Suspense)
└── RoomsContent (Main logic)
    ├── Search Input (debounced)
    ├── Filter Controls
    │   ├── Status Select (All/Active/Inactive)
    │   ├── HasCamera Select (All/Yes/No)
    │   └── Sort Controls (Name/Location + Asc/Desc)
    ├── Action Buttons
    │   ├── Import Button (CSV)
    │   └── Create Button
    ├── RoomTable
    │   ├── Columns: Name | Location | Cameras | Status | Actions
    │   └── RoomPagination
    ├── RoomFormDialog (Create/Edit)
    ├── DeleteRoomDialog
    └── GenericImportDialog
```

### 4.3 React Query Hooks

**File:** `hooks/api/useRooms.ts`

| Hook                                | Mục đích                 | Cache Time |
| ----------------------------------- | ------------------------ | ---------- |
| `useGetRooms(params)`               | Danh sách với pagination | 5 phút     |
| `useGetRoomById(id)`                | Chi tiết một room        | 5 phút     |
| `useCreateRoom()`                   | Mutation tạo mới         | -          |
| `useUpdateRoom()`                   | Mutation cập nhật        | -          |
| `useDeleteRoom()`                   | Mutation xóa             | -          |
| `useGetRoomCameras(roomId, params)` | Cameras của room         | 5 phút     |
| `useGetRoomSlots(roomId, params)`   | Slots của room           | 5 phút     |
| `useImportRooms()`                  | Import từ CSV            | -          |

**Query Keys:**

```typescript
rooms: {
  all: ["rooms"],
  detail: (id: number) => ["rooms", id],
  cameras: (id: number) => ["rooms", id, "cameras"],
  slots: (id: number) => ["rooms", id, "slots"],
}
```

**API Endpoints:**

```typescript
rooms: {
  all: "/rooms",
  byId: (id: number | string) => `/rooms/${id}`,
  cameras: (id: number | string) => `/rooms/${id}/cameras`,
  slots: (id: number | string) => `/rooms/${id}/slots`,
  import: "/rooms/import",
}
```

### 4.4 TypeScript Types

```typescript
// Room type
interface Room {
  id: number;
  name: string;
  location: string | null;
  totalCameras: number; // Default: 0
  activeCameras: number; // Default: 0
  isActive: boolean;
  createdAt: string;
  updatedAt: string;
}

// Query parameters
interface RoomQueryParams {
  page?: number;
  pageSize?: number;
  sort?: "asc" | "desc";
  sortBy?: "name" | "location";
  search?: string;
  isActive?: boolean;
  hasCamera?: boolean;
}

// Create payload
interface CreateRoomPayload {
  name: string;
  location?: string;
}

// Update payload
interface UpdateRoomPayload {
  name: string;
  location?: string;
  isActive: boolean;
}
```

### 4.5 Zod Validation Schemas

```typescript
// Room Schema
export const roomSchema = z.object({
  id: z.number(),
  name: z.string(),
  location: z
    .string()
    .nullish()
    .transform((v) => (v === "" || !v ? null : v)),
  totalCameras: z
    .number()
    .nullish()
    .transform((v) => v ?? 0),
  activeCameras: z
    .number()
    .nullish()
    .transform((v) => v ?? 0),
  isActive: z.boolean(),
  createdAt: z.string(),
  updatedAt: z.string(),
});

// Create validation
export const createRoomPayloadSchema = z.object({
  name: z
    .string()
    .min(1, "Room name is required")
    .max(150, "Room name must not exceed 150 characters")
    .regex(
      /^[A-Za-z0-9-]+( [A-Za-z0-9-]+)*$/,
      "Only letters, numbers, and hyphens with single spaces between words"
    ),
  location: z
    .union([
      z.string().max(255, "Location must not exceed 255 characters"),
      z.literal(""),
    ])
    .optional(),
});

// Update validation
export const updateRoomPayloadSchema = z.object({
  name: z
    .string()
    .min(1)
    .max(150)
    .regex(/^[A-Za-z0-9-]+( [A-Za-z0-9-]+)*$/),
  location: z.union([z.string().max(255), z.literal("")]).optional(),
  isActive: z.boolean(),
});
```

---

## 5. Luồng Xử Lý Nghiệp Vụ

### 5.1 Luồng Tạo Mới Room

```
┌──────┐      ┌──────────┐      ┌─────────┐      ┌────────┐
│ User │      │ Frontend │      │ Backend │      │   DB   │
└──┬───┘      └────┬─────┘      └────┬────┘      └────┬───┘
   │               │                 │                │
   │ 1. Fill form  │                 │                │
   │   (name,      │                 │                │
   │    location)  │                 │                │
   │──────────────>│                 │                │
   │               │                 │                │
   │               │ 2. Validate     │                │
   │               │    (Zod)        │                │
   │               │    - name regex │                │
   │               │    - max length │                │
   │               │                 │                │
   │               │ 3. POST /rooms  │                │
   │               │────────────────>│                │
   │               │                 │                │
   │               │                 │ 4. Check unique│
   │               │                 │    name        │
   │               │                 │───────────────>│
   │               │                 │<───────────────│
   │               │                 │                │
   │               │                 │ 5. Insert room │
   │               │                 │───────────────>│
   │               │                 │<───────────────│
   │               │                 │                │
   │               │ 6. Return DTO   │                │
   │               │    (201 Created)│                │
   │               │<────────────────│                │
   │               │                 │                │
   │ 7. Toast +    │                 │                │
   │    Refresh    │                 │                │
   │    list       │                 │                │
   │<──────────────│                 │                │
```

### 5.2 Luồng Import Room từ CSV

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
   │               │                 │    by name     │
   │               │                 │    (keep first)│
   │               │                 │                │
   │               │                 │ ┌─────────────┐│
   │               │                 │ │ For each row││
   │               │                 │ │ (NEW TX)    ││
   │               │                 │ │             ││
   │               │                 │ │ 5. Validate ││
   │               │                 │ │    name     ││
   │               │                 │ │             ││
   │               │                 │ │ 6. Check    ││
   │               │                 │ │    mode     ││
   │               │                 │ │    ADD_ONLY/││
   │               │                 │ │    ADD_AND_ ││
   │               │                 │ │    UPDATE   ││
   │               │                 │ │             ││
   │               │                 │ │ 7. Insert/  ││
   │               │                 │ │    Update   ││
   │               │                 │ │─────────────>│
   │               │                 │ │             ││
   │               │                 │ │ 8. Log error││
   │               │                 │ │    if fail  ││
   │               │                 │ └─────────────┘│
   │               │                 │                │
   │               │ 9. Return       │                │
   │               │    ImportResult │                │
   │               │    (success/    │                │
   │               │     failure     │                │
   │               │     counts)     │                │
   │               │<────────────────│                │
   │               │                 │                │
   │ 10. Show      │                 │                │
   │     result    │                 │                │
   │<──────────────│                 │                │
```

### 5.3 Luồng Xóa Room

```
┌──────┐      ┌──────────┐      ┌─────────┐      ┌────────┐
│ User │      │ Frontend │      │ Backend │      │   DB   │
└──┬───┘      └────┬─────┘      └────┬────┘      └────┬───┘
   │               │                 │                │
   │ 1. Click      │                 │                │
   │    Delete     │                 │                │
   │──────────────>│                 │                │
   │               │                 │                │
   │               │ 2. Show confirm │                │
   │               │    dialog       │                │
   │               │                 │                │
   │ 3. Confirm    │                 │                │
   │──────────────>│                 │                │
   │               │                 │                │
   │               │ 4. DELETE       │                │
   │               │    /rooms/{id}  │                │
   │               │────────────────>│                │
   │               │                 │                │
   │               │                 │ 5. Check       │
   │               │                 │    cameras     │
   │               │                 │───────────────>│
   │               │                 │<───────────────│
   │               │                 │                │
   │               │                 │ 6. Check       │
   │               │                 │    future      │
   │               │                 │    slots       │
   │               │                 │───────────────>│
   │               │                 │<───────────────│
   │               │                 │                │
   │               │                 │ 7. If has      │
   │               │                 │    constraints │
   │               │                 │    → 400 Error │
   │               │                 │                │
   │               │                 │ 8. Delete room │
   │               │                 │───────────────>│
   │               │                 │<───────────────│
   │               │                 │                │
   │               │ 9. Success/     │                │
   │               │    Error        │                │
   │               │<────────────────│                │
   │               │                 │                │
   │ 10. Toast +   │                 │                │
   │     Refresh   │                 │                │
   │<──────────────│                 │                │
```

### 5.4 Luồng Deactivate Room

```
┌──────┐      ┌──────────┐      ┌─────────┐      ┌────────┐
│ User │      │ Frontend │      │ Backend │      │   DB   │
└──┬───┘      └────┬─────┘      └────┬────┘      └────┬───┘
   │               │                 │                │
   │ 1. Edit form  │                 │                │
   │    isActive   │                 │                │
   │    = false    │                 │                │
   │──────────────>│                 │                │
   │               │                 │                │
   │               │ 2. PUT          │                │
   │               │    /rooms/{id}  │                │
   │               │────────────────>│                │
   │               │                 │                │
   │               │                 │ 3. Check       │
   │               │                 │    active      │
   │               │                 │    cameras     │
   │               │                 │    (isActive   │
   │               │                 │     = true)    │
   │               │                 │───────────────>│
   │               │                 │<───────────────│
   │               │                 │                │
   │               │                 │ 4. Check       │
   │               │                 │    active      │
   │               │                 │    slots       │
   │               │                 │    (startTime  │
   │               │                 │     >= now)    │
   │               │                 │───────────────>│
   │               │                 │<───────────────│
   │               │                 │                │
   │               │                 │ 5. If has      │
   │               │                 │    active      │
   │               │                 │    → 400 Error │
   │               │                 │                │
   │               │ 6. Error msg    │                │
   │               │<────────────────│                │
   │               │                 │                │
   │ 7. Show error │                 │                │
   │    "Cannot    │                 │                │
   │    deactivate │                 │                │
   │    room with  │                 │                │
   │    active     │                 │                │
   │    cameras/   │                 │                │
   │    slots"     │                 │                │
   │<──────────────│                 │                │
```

---

## 6. Business Rules & Validation

### 6.1 Quy Tắc Validation

| Field      | Rule                                          | HTTP Status |
| ---------- | --------------------------------------------- | ----------- |
| `name`     | Required, unique, 1-150 chars                 | 400/409     |
| `name`     | Pattern: `^[A-Za-z0-9\-]+( [A-Za-z0-9\-]+)*$` | 400         |
| `location` | Optional, max 255 chars                       | 400         |
| `isActive` | Boolean (update only)                         | 400         |

### 6.2 Quy Tắc Nghiệp Vụ

| Quy tắc                   | Mô tả                                             |
| ------------------------- | ------------------------------------------------- |
| **Unique Name**           | Mỗi phòng có mã định danh duy nhất                |
| **Deactivate Protection** | Không thể tắt phòng có camera/slot active         |
| **Delete Protection**     | Không thể xóa phòng có camera hoặc slot tương lai |
| **Cascade None**          | Không có cascade delete - kiểm tra thủ công       |
| **ID Type**               | Short (1-32767) - đủ cho quy mô trường học        |

**Chi tiết Delete Protection:**

- Kiểm tra **tất cả cameras** (kể cả inactive): `countAllCamerasByRoomId()`
- Kiểm tra **future slots**: `startTime > now AND isActive = true`

**Chi tiết Deactivate Protection:**

- Kiểm tra **active cameras**: `isActive = true`
- Kiểm tra **active slots**: `startTime >= now AND isActive = true`

### 6.3 CSV Import Rules

**Format CSV:**

```csv
name,location[,isActive]
301,Tòa A Tầng 3
Lab-A1,Tòa B Phòng Lab 1
402,
403,Tòa A Tầng 4,true
404,Tòa A Tầng 4,false
```

**Import Modes:**
| Mode | Hành vi |
|------|---------|
| `ADD_ONLY` | Chỉ thêm mới, lỗi nếu name đã tồn tại |
| `ADD_AND_UPDATE` | Thêm mới hoặc cập nhật nếu đã tồn tại |

**Constraints:**

- Encoding: UTF-8
- Deduplicate: Theo name (giữ dòng đầu tiên)
- Default isActive: `true` nếu không cung cấp
- Partial success: Dòng lỗi không ảnh hưởng dòng khác

### 6.4 Error Codes

| Code                               | Mô tả                                   | HTTP Status |
| ---------------------------------- | --------------------------------------- | ----------- |
| `ROOM_NOT_FOUND`                   | Không tìm thấy phòng                    | 404         |
| `ROOM_NAME_EXISTS`                 | Tên phòng đã tồn tại                    | 409         |
| `ROOM_HAS_ACTIVE_CAMERAS`          | Không thể deactivate - có camera active | 400         |
| `ROOM_HAS_ACTIVE_SLOTS`            | Không thể deactivate - có slot active   | 400         |
| `ROOM_HAS_CAMERAS`                 | Không thể xóa - có camera liên kết      | 400         |
| `ROOM_HAS_SCHEDULED_SLOTS`         | Không thể xóa - có slot tương lai       | 400         |
| `FOREIGN_KEY_CONSTRAINT_VIOLATION` | Vi phạm ràng buộc FK                    | 409         |
| `INVALID_IMPORT_MODE`              | Mode import không hợp lệ                | 400         |
| `FILE_PROCESSING_ERROR`            | Lỗi xử lý file                          | 400         |
| `INVALID_FIELD_FORMAT`             | Format field không hợp lệ               | 400         |

---

## 7. Hướng Dẫn Phát Triển

### 7.1 Danh Sách File Quan Trọng

| File                                                  | Mô tả               |
| ----------------------------------------------------- | ------------------- |
| `backend/.../entity/Room.java`                        | Entity chính        |
| `backend/.../service/RoomService.java`                | Business logic      |
| `backend/.../controller/RoomController.java`          | REST API            |
| `backend/.../repository/impl/RoomRepositoryImpl.java` | Custom queries      |
| `backend/.../dto/request/RoomCreateRequest.java`      | Validation rules    |
| `frontend-web/app/admin/rooms/page.tsx`               | Trang quản lý       |
| `frontend-web/hooks/api/useRooms.ts`                  | React Query hooks   |
| `frontend-web/components/admin/rooms/*.tsx`           | UI components       |
| `frontend-web/lib/zod-schemas.ts`                     | Frontend validation |

### 7.2 So Sánh Room với Các Entity Khác

| Đặc tính               | Room           | Subject     | Major              |
| ---------------------- | -------------- | ----------- | ------------------ |
| **ID Type**            | Short          | Short       | Short              |
| **Extends BaseEntity** | Có             | Có          | Có                 |
| **Unique Field**       | name           | subjectCode | majorCode          |
| **Location Info**      | Có             | Không       | Không              |
| **Has Children**       | cameras, slots | classes     | students, subjects |
| **CSV Import**         | Có             | Có          | Có                 |
| **Soft Delete**        | isActive       | isActive    | isActive           |

### 7.3 Seed Data Reference

**25 phòng được tạo sẵn:**

| Loại      | Phòng          | Vị trí         |
| --------- | -------------- | -------------- |
| Phòng học | 101, 102, 103  | Tòa A - Tầng 1 |
| Phòng học | 201, 202, 203  | Tòa A - Tầng 2 |
| Phòng học | 301, 302, 303  | Tòa A - Tầng 3 |
| Phòng học | B101, B102     | Tòa B - Tầng 1 |
| Phòng học | B201, B202     | Tòa B - Tầng 2 |
| Phòng học | B301, B302     | Tòa B - Tầng 3 |
| Lab       | 401, 402, 403  | Tòa A - Tầng 4 |
| Lab       | B401, B402     | Tòa B - Tầng 4 |
| Lab       | C101, C102     | Tòa C - Tầng 1 |
| Phòng thi | Exam Hall 1, 2 | Tòa C - Tầng 2 |
| Phòng thi | Exam Hall 3    | Tòa C - Tầng 3 |

### 7.4 FAQ - Câu Hỏi Thường Gặp

**Q: Sao ID của Room là Short thay vì Integer?**

> A: Short (1-32767) đủ cho quy mô trường học và tiết kiệm bộ nhớ. Một trường đại học thường có vài trăm phòng.

**Q: Xóa phòng có cascade delete không?**

> A: Không. Phải xóa cameras và không có future slots trước khi xóa phòng.

**Q: Deactivate khác Delete thế nào?**

> A: Deactivate (isActive=false) là soft delete - vẫn giữ data. Delete là hard delete - xóa hoàn toàn khỏi DB.

**Q: Tại sao import CSV dùng partial success?**

> A: Để không mất dữ liệu đã import thành công nếu có lỗi ở một vài dòng. Mỗi dòng xử lý trong transaction riêng.

**Q: Làm sao biết phòng có camera active?**

> A: Dùng `hasCamera` filter trong search hoặc xem `activeCameras` field trong response.

### 7.5 Tóm Tắt Điểm Chính

1. **Room = Cơ sở vật chất** - Phòng học, lab, phòng thi
2. **Room → Camera**: 1:N - Mỗi phòng có nhiều camera giám sát
3. **Room → Slot**: 1:N - Mỗi phòng có nhiều buổi học/thi
4. **Protection**: Không thể xóa/deactivate phòng có camera/slot
5. **Unique name**: Mã phòng duy nhất trong hệ thống
6. **CSV Import**: Partial success với REQUIRES_NEW transaction
7. **Frontend**: Chỉ DATA_OPERATOR được truy cập trang quản lý

### 7.6 Các Bước Khi Trình Bày Hội Đồng

1. **Giới thiệu module**: Room là gì, vai trò trong hệ thống điểm danh
2. **Show database**: rooms table, relationship với cameras và slots
3. **Demo tạo mới**: Form validation, unique name check
4. **Demo import CSV**: Partial success, error handling
5. **Show camera view**: Click "View Cameras" từ room table
6. **Giải thích protection**: Tại sao không xóa được room có camera
7. **Show slot assignment**: Room được sử dụng trong slot scheduling
