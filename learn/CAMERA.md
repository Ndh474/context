# Camera Module - Tài Liệu Kỹ Thuật

> **Mục đích tài liệu**: Giúp người đọc hiểu và làm việc với module Camera trong hệ thống FUACS - Hệ thống Điểm danh Tự động sử dụng Nhận diện Khuôn mặt.

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

### 1.1 Camera là gì?

**Camera** là thiết bị quan trọng nhất trong hệ thống FUACS, chịu trách nhiệm capture khuôn mặt sinh viên để nhận diện và điểm danh tự động. Mỗi camera được gắn với một phòng cụ thể và có RTSP URL để kết nối stream video.

**Đặc điểm chính:**
- Mỗi camera có tên (name) duy nhất trong hệ thống
- Mỗi camera có RTSP URL duy nhất để stream video
- Một camera chỉ thuộc về **một phòng duy nhất**
- Camera có thể được test connection trực tiếp từ giao diện

### 1.2 Vai trò trong Hệ thống Điểm danh

| Vai trò | Mô tả |
|---------|-------|
| **Capture** | Chụp/stream video khuôn mặt sinh viên |
| **Recognition** | Gửi frame tới Python Recognition Service để nhận diện |
| **Real-time** | Xử lý nhận diện theo thời gian thực trong slot |
| **Multi-camera** | Hỗ trợ nhiều camera cho một phòng lớn |

> **Lưu ý**: Mỗi phòng trong seed data có 2 camera sẵn (ví dụ: Camera 101-A, Camera 101-B cho phòng 101).

### 1.3 Mối Quan Hệ với Các Module Khác

```
                          ┌─────────────────┐
                          │      ROOM       │
                          │   (Phòng học)   │
                          └────────┬────────┘
                                   │
                                   │ 1:N (ManyToOne)
                                   │
                          ┌────────▼────────┐
                          │     CAMERA      │
                          │ (Camera giám    │
                          │  sát trong      │
                          │  phòng)         │
                          └────────┬────────┘
                                   │
                     ┌─────────────┼─────────────┐
                     │             │             │
                     ▼             ▼             ▼
         ┌───────────────┐ ┌─────────────┐ ┌───────────────┐
         │    RTSP       │ │ RECOGNITION │ │    SLOT       │
         │  (Video       │ │ SERVICE     │ │ (Buổi học/    │
         │   Stream)     │ │ (Python)    │ │  thi - qua    │
         │               │ │             │ │  Room)        │
         └───────────────┘ └──────┬──────┘ └───────────────┘
                                  │
                                  ▼
                          ┌─────────────────┐
                          │   ATTENDANCE    │
                          │   (Điểm danh)   │
                          └─────────────────┘
```

**Giải thích quan hệ:**
- **Room → Camera**: 1:N - Một phòng có nhiều camera
- **Camera → Room**: N:1 - Mỗi camera thuộc đúng một phòng (bắt buộc)
- **Camera → Recognition**: Camera gửi RTSP stream tới Python service
- **Room → Slot**: Slot được tạo cho Room, camera trong Room đó thực hiện điểm danh

---

## 2. Kiến Trúc Hệ Thống

### 2.1 Tổng Quan Kiến Trúc

```
┌─────────────────────────────────────────────────────────────────┐
│                        FRONTEND (Next.js)                       │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │                 Admin Portal (/admin/*)                    │  │
│  │  ┌─────────────────────────────────────────────────────┐  │  │
│  │  │        Cameras Management (/admin/cameras)          │  │  │
│  │  │  - List/Search/Filter cameras                       │  │  │
│  │  │  - Create/Edit/Delete cameras                       │  │  │
│  │  │  - Test RTSP connection                             │  │  │
│  │  │  - Import from CSV                                  │  │  │
│  │  └─────────────────────────────────────────────────────┘  │  │
│  └───────────────────────────────────────────────────────────┘  │
│                              │                                   │
│              ┌───────────────┴───────────────┐                   │
│              │     React Query Hooks         │                   │
│              │       useCameras              │                   │
│              └───────────────┬───────────────┘                   │
└──────────────────────────────┼──────────────────────────────────┘
                               │ REST API
                               ▼
┌─────────────────────────────────────────────────────────────────┐
│                      BACKEND (Spring Boot)                      │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │                   CameraController                         │  │
│  │                 /api/v1/cameras/*                          │  │
│  └─────────────────────────┬─────────────────────────────────┘  │
│                            ▼                                     │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │                    CameraService                           │  │
│  │   CRUD + CSV Import + Test Connection + Room Linking      │  │
│  └─────────────────────────┬─────────────────────────────────┘  │
│                            │                                     │
│            ┌───────────────┼───────────────┐                     │
│            ▼               ▼               ▼                     │
│  ┌──────────────┐ ┌────────────────┐ ┌──────────────────┐       │
│  │ CameraRepo   │ │ RoomRepository │ │ PythonBackend    │       │
│  │              │ │ (Room lookup)  │ │ Client           │       │
│  └──────────────┘ └────────────────┘ └──────────────────┘       │
└─────────────────────────────┼───────────────────────────────────┘
                              │
              ┌───────────────┴───────────────┐
              ▼                               ▼
    ┌─────────────────┐             ┌─────────────────┐
    │   PostgreSQL    │             │ Python Service  │
    │     cameras     │             │ (Recognition)   │
    │     rooms       │             │ Test Connection │
    └─────────────────┘             └─────────────────┘
```

### 2.2 Cấu Trúc Thư Mục

**Backend:**
```
backend/src/main/java/com/fuacs/backend/
├── entity/
│   ├── Camera.java                  # Entity chính
│   └── Room.java                    # Entity Room (FK)
├── dto/
│   ├── request/
│   │   ├── CameraCreateRequest.java
│   │   ├── CameraUpdateRequest.java
│   │   ├── CameraSearchBaseRequest.java
│   │   └── CameraCsvRow.java
│   └── response/
│       ├── CameraDTO.java
│       ├── CameraConnectionTestResponse.java
│       └── ImportResultDTO.java
├── repository/
│   ├── CameraRepository.java
│   ├── custom/
│   │   └── CustomCameraRepository.java
│   └── impl/
│       └── CameraRepositoryImpl.java
├── service/
│   └── CameraService.java
├── controller/
│   └── CameraController.java
├── client/
│   └── PythonBackendClient.java     # Test connection
└── dto/mapper/
    └── CameraMapper.java
```

**Frontend:**
```
frontend-web/
├── app/admin/cameras/
│   └── page.tsx                     # Trang quản lý Camera
├── components/admin/cameras/
│   ├── camera-table.tsx             # Bảng danh sách
│   ├── camera-columns.tsx           # Định nghĩa cột
│   ├── camera-form-dialog.tsx       # Dialog tạo/sửa + test connection
│   ├── camera-pagination.tsx        # Pagination
│   └── delete-camera-dialog.tsx     # Dialog xóa
├── hooks/api/
│   └── useCameras.ts                # React Query hooks
├── lib/
│   ├── constants.ts                 # Query keys, API endpoints
│   └── zod-schemas.ts               # Validation schemas
└── types/
    └── index.ts                     # TypeScript types
```

---

## 3. Backend Implementation

### 3.1 Database Schema

**Bảng `cameras`:**
```sql
CREATE TABLE cameras (
    id SMALLSERIAL PRIMARY KEY,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    room_id SMALLINT NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    name VARCHAR(150) NOT NULL UNIQUE,
    rtsp_url VARCHAR(512) NOT NULL UNIQUE,
    FOREIGN KEY (room_id) REFERENCES rooms(id)
);
```

**Sơ đồ ER:**
```
┌─────────────────┐           ┌─────────────────┐
│     rooms       │           │    cameras      │
├─────────────────┤           ├─────────────────┤
│ id (PK)         │◄─────────┤│ room_id (FK)    │
│ name (UNIQUE)   │    1:N    │ id (PK)         │
│ location        │           │ name (UNIQUE)   │
│ is_active       │           │ rtsp_url (UNIQ) │
│ created_at      │           │ is_active       │
│ updated_at      │           │ created_at      │
└─────────────────┘           │ updated_at      │
                              └─────────────────┘
```

### 3.2 Entity Class

**Camera.java:**
```java
@Entity
@Table(name = "cameras")
public class Camera extends BaseEntity {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Short id;                    // PK: 1-32767

    @Column(name = "name", length = 150, nullable = false, unique = true)
    private String name;                 // Unique: "Camera 101-A"

    @Column(name = "rtsp_url", length = 512, nullable = false, unique = true)
    private String rtspUrl;              // Unique: "rtsp://admin:admin123@192.168.1.80:554/stream1"

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "room_id", nullable = false)
    private Room room;                   // Bắt buộc: Mỗi camera thuộc một phòng
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

**Base URL:** `/api/v1/cameras`

| Method | Endpoint | Mô tả | Permission |
|--------|----------|-------|------------|
| POST | `/` | Tạo mới camera | CAMERA_CREATE |
| POST | `/import` | Import từ CSV | CAMERA_IMPORT |
| GET | `/` | Tìm kiếm với pagination | CAMERA_READ |
| GET | `/test-connection` | Test RTSP connection | CAMERA_READ |
| GET | `/{id}` | Lấy chi tiết | CAMERA_READ |
| PUT | `/{id}` | Cập nhật | CAMERA_UPDATE |
| DELETE | `/{id}` | Xóa (hard delete) | CAMERA_DELETE_HARD |

**Ví dụ Request/Response:**

**Tạo mới Camera:**
```http
POST /api/v1/cameras
Content-Type: application/json

{
  "name": "Camera 305-Front",
  "rtspUrl": "rtsp://admin:admin123@192.168.1.105:554/stream1",
  "roomId": 10
}
```

```json
// Response 201 Created
{
  "status": "success",
  "data": {
    "id": 51,
    "name": "Camera 305-Front",
    "rtspUrl": "rtsp://admin:admin123@192.168.1.105:554/stream1",
    "isActive": true,
    "createdAt": "2025-01-15T10:30:00Z",
    "updatedAt": "2025-01-15T10:30:00Z",
    "room": {
      "id": 10,
      "name": "305",
      "location": "Tòa A, Tầng 3"
    }
  }
}
```

**Test Connection:**
```http
GET /api/v1/cameras/test-connection?rtspUrl=rtsp://192.168.1.105:554/stream1&timeout=10
```

```json
// Response 200 OK
{
  "status": "success",
  "data": {
    "rtspUrl": "rtsp://192.168.1.105:554/stream1",
    "connected": true,
    "frameRate": 30.5,
    "resolution": { "width": 1920, "height": 1080 },
    "latency": 150,
    "stability": "GOOD",
    "testedAt": "2025-01-15T10:35:00Z"
  }
}
```

**Tìm kiếm Camera:**
```http
GET /api/v1/cameras?search=305&isActive=true&roomId=10&page=1&pageSize=10&sortBy=name&sort=asc
```

```json
// Response 200 OK
{
  "status": "success",
  "data": {
    "items": [
      {
        "id": 51,
        "name": "Camera 305-Front",
        "rtspUrl": "rtsp://admin:admin123@192.168.1.105:554/stream1",
        "isActive": true,
        "room": {
          "id": 10,
          "name": "305",
          "location": "Tòa A, Tầng 3"
        }
      }
    ],
    "totalPages": 1,
    "currentPage": 1,
    "pageSize": 10,
    "totalItems": 1
  }
}
```

### 3.4 Data Transfer Objects (DTOs)

**CameraCreateRequest:**
```java
public class CameraCreateRequest {
    @NotBlank(message = "Name must not be blank")
    @Size(max = 150)
    @Pattern(regexp = "^[A-Za-z0-9\\-]+( [A-Za-z0-9\\-]+)*$")
    private String name;

    @NotBlank(message = "RTSP URL must not be blank")
    @Size(max = 512)
    private String rtspUrl;

    @NotNull(message = "Room ID is required")
    private Short roomId;
}
```

**CameraUpdateRequest:**
```java
public class CameraUpdateRequest extends BaseRequest {
    @NotBlank
    @Size(max = 150)
    @Pattern(regexp = "^[A-Za-z0-9\\-]+( [A-Za-z0-9\\-]+)*$")
    private String name;

    @NotBlank
    @Size(max = 512)
    private String rtspUrl;

    @NotNull
    private Short roomId;
    // + isActive từ BaseRequest
}
```

**CameraSearchBaseRequest:**
```java
public class CameraSearchBaseRequest extends PagedRequest {
    private Short roomId;            // Filter theo phòng
    // + search, isActive, page, pageSize, sort, sortBy từ PagedRequest
}
```

**CameraDTO (Response):**
```java
@JsonInclude(JsonInclude.Include.NON_NULL)
public class CameraDTO extends BaseDTO {
    private Short id;
    private String name;
    private String rtspUrl;
    private RoomDTO room;            // Nested room info
}
```

**CameraConnectionTestResponse:**
```java
public class CameraConnectionTestResponse {
    private String rtspUrl;
    private Boolean connected;
    private Double frameRate;        // FPS
    private Resolution resolution;   // { width, height }
    private Integer latency;         // milliseconds
    private String stability;        // "GOOD", "POOR"
    private String error;            // null nếu connected
    private Instant testedAt;
}
```

### 3.5 Service Layer

**CameraService** - Các phương thức chính:

| Phương thức | Mô tả |
|-------------|-------|
| `search(request)` | Tìm kiếm với room info |
| `count(request)` | Đếm tổng số (cho pagination) |
| `findById(id)` | Lấy chi tiết với room info |
| `findByRoomId(roomId)` | Tất cả cameras của một phòng |
| `create(request)` | Tạo mới (check room exists, name/rtspUrl unique) |
| `update(id, request)` | Cập nhật (check unique khi đổi name/rtspUrl) |
| `delete(id)` | Xóa (check active slots) |
| `testConnection(rtspUrl, timeout)` | Test RTSP qua Python service |
| `importFromCsv(file, mode)` | Import hàng loạt |

**Đặc điểm quan trọng:**
- **Dual Unique Check**: Cả `name` và `rtspUrl` đều unique
- **Room Linking**: Camera bắt buộc phải thuộc một Room
- **Test Connection**: Gọi Python Recognition Service qua `PythonBackendClient`
- **Partial Success Pattern**: Import CSV không rollback toàn bộ nếu 1 dòng lỗi
- **Transaction Isolation**: Mỗi dòng CSV xử lý trong transaction riêng (`REQUIRES_NEW`)

### 3.6 Repository Layer

**CameraRepository - Query Methods:**
```java
// Existence checks
boolean existsByName(String name);
boolean existsByRtspUrl(String rtspUrl);
boolean existsByNameAndIdNot(String name, Short id);
boolean existsByRtspUrlAndIdNot(String rtspUrl, Short id);

// Find methods
Camera findByName(String name);                    // Cho CSV import
List<Camera> findByRoom_Id(Short roomId);          // Cameras của room

// Active slots check (cho delete protection)
@Query("SELECT COUNT(s.id) FROM Slot s
        WHERE s.room.id IN (SELECT c.room.id FROM Camera c WHERE c.id = :cameraId)
        AND s.startTime >= :now AND s.isActive = true")
long countActiveSlotsByCameraId(Short cameraId, LocalDateTime now);
```

**Sortable Fields:**
- `name` → `c.name`
- Default: `c.id ASC`

---

## 4. Frontend Implementation

### 4.1 Trang Quản Lý Camera

**Route**: `/admin/cameras`
**Quyền truy cập**: DATA_OPERATOR only
**File chính**: `app/admin/cameras/page.tsx`

**Giao diện người dùng:**

```
┌──────────────────────────────────────────────────────────────┐
│  Cameras Management                                          │
├──────────────────────────────────────────────────────────────┤
│ [Search...] [Status▼] [Room▼] [Sort▼] [Order▼]  [Import][+] │
├──────────────────────────────────────────────────────────────┤
│ Name          │ RTSP URL        │ Room    │ Status │ Action │
├──────────────────────────────────────────────────────────────┤
│ Camera 101-A  │ rtsp://192...   │ 101     │ Active │   ✏️   │
│ Camera 101-B  │ rtsp://192...   │ 101     │ Active │   ✏️   │
│ Camera 102-A  │ rtsp://192...   │ 102     │Inactive│   ✏️   │
│ ...           │ ...             │ ...     │ ...    │  ...   │
├──────────────────────────────────────────────────────────────┤
│              ◀ 1 2 3 ... 10 ▶                                │
└──────────────────────────────────────────────────────────────┘
```

**Tính năng:**

| Tính năng | Mô tả |
|-----------|-------|
| **Search** | Tìm theo name hoặc RTSP URL (debounced 500ms) |
| **Status Filter** | All / Active / Inactive |
| **Room Filter** | Lọc theo phòng (dropdown với search) |
| **Sort** | Sort by name (Asc/Desc) |
| **Pagination** | 10 items/page |
| **Create** | Dialog form với test connection |
| **Edit** | Dialog form với test connection + delete button |
| **Delete** | Confirmation dialog |
| **Import** | Upload CSV với mode selection |
| **Test Connection** | Button trong form dialog để test RTSP |

### 4.2 Component Structure

```
CamerasPage (Wrapper with Suspense)
└── CamerasContent (Main logic)
    ├── Search Input (debounced)
    ├── Filter Controls
    │   ├── Status Select (All/Active/Inactive)
    │   ├── Room Filter (Popover Combobox)
    │   └── Sort Controls (Name + Asc/Desc)
    ├── Action Buttons
    │   ├── Import Button (CSV)
    │   └── Create Button
    ├── CameraTable
    │   ├── Columns: Name | RTSP URL | Room | Status | Action
    │   └── CameraPagination
    ├── CameraFormDialog (Create/Edit + Test Connection)
    ├── DeleteCameraDialog
    └── GenericImportDialog
```

### 4.3 React Query Hooks

**File:** `hooks/api/useCameras.ts`

| Hook | Mục đích | Cache Time |
|------|----------|------------|
| `useGetCameras(params)` | Danh sách với pagination | 5 phút |
| `useGetCameraById(id)` | Chi tiết một camera | 5 phút |
| `useCreateCamera()` | Mutation tạo mới | - |
| `useUpdateCamera()` | Mutation cập nhật | - |
| `useDeleteCamera()` | Mutation xóa | - |
| `useImportCameras()` | Import từ CSV | - |
| `useTestCameraConnection()` | Test RTSP connection | - |

**Query Keys:**
```typescript
cameras: {
  all: ["cameras"],
  detail: (id: number) => ["cameras", id],
}
```

**API Endpoints:**
```typescript
cameras: {
  all: "/cameras",
  byId: (id: number | string) => `/cameras/${id}`,
  import: "/cameras/import",
  testConnection: "/cameras/test-connection",
}
```

**Invalidation Strategy:**
- Create/Update/Delete camera → Invalidate `cameras.all` + `rooms.all`
- Update specific camera → Also invalidate `cameras.detail(id)`

### 4.4 TypeScript Types

```typescript
// Camera type
interface Camera {
  id: number;
  name: string;
  rtspUrl: string;
  room: {
    id: number;
    name: string;
    location: string | null;
    isActive?: boolean;
  };
  isActive: boolean;
  createdAt: string;
  updatedAt: string;
}

// Connection test result
interface CameraConnectionTestResult {
  rtspUrl: string;
  connected: boolean;
  frameRate?: number | null;
  resolution?: { width: number; height: number } | null;
  latency?: number | null;
  stability?: string | null;
  error?: string | null;
  testedAt?: string | null;
}

// Query parameters
interface CameraQueryParams {
  page?: number;
  pageSize?: number;
  sort?: "asc" | "desc";
  sortBy?: "name";
  search?: string;
  isActive?: boolean;
  roomId?: number;
}

// Create payload
interface CreateCameraPayload {
  name: string;
  rtspUrl: string;
  roomId: number;
}

// Update payload
interface UpdateCameraPayload {
  name: string;
  rtspUrl: string;
  roomId: number;
  isActive: boolean;
}
```

### 4.5 Zod Validation Schemas

```typescript
// Camera Schema
export const cameraSchema = z.object({
  id: z.number(),
  name: z.string(),
  rtspUrl: z.string(),
  room: z.object({
    id: z.number(),
    name: z.string(),
    location: z.string().nullable(),
    isActive: z.boolean().optional(),
  }),
  isActive: z.boolean(),
  createdAt: z.string(),
  updatedAt: z.string(),
});

// Create validation
export const createCameraPayloadSchema = z.object({
  name: z
    .string()
    .min(1, "Camera name is required")
    .max(150, "Camera name must not exceed 150 characters")
    .regex(
      /^[A-Za-z0-9-]+( [A-Za-z0-9-]+)*$/,
      "Only letters, numbers, and hyphens with single spaces"
    ),
  rtspUrl: z
    .string()
    .min(1, "RTSP URL is required")
    .max(512, "RTSP URL must not exceed 512 characters")
    .regex(/^rtsp:\/\//, "RTSP URL must start with rtsp://"),
  roomId: z.number().min(1, "Room is required"),
});

// Update validation
export const updateCameraPayloadSchema = createCameraPayloadSchema.extend({
  isActive: z.boolean(),
});
```

### 4.6 Camera Form Dialog Features

**Form Fields:**
- **Camera Name** (required) - Text input với validation
- **RTSP URL** (required) - Monospace text input
- **Room** (required) - Popover combobox với search
- **Is Active** (edit only) - Toggle switch

**Test Connection Feature:**
```
┌──────────────────────────────────────────────────────────┐
│ RTSP URL: [rtsp://192.168.1.105:554/stream1        ]    │
│                                                          │
│ [Test Connection]                                        │
│                                                          │
│ ✅ Connected                                             │
│    Frame Rate: 30.5 FPS                                 │
│    Resolution: 1920x1080                                │
│    Latency: 150ms                                       │
│    Stability: GOOD                                      │
└──────────────────────────────────────────────────────────┘
```

- **Timeout**: 10 giây (configurable 1-30s)
- **Icons**: CheckCircle2 (xanh) nếu thành công, XCircle (đỏ) nếu thất bại
- **Cancel**: Support abort signal để cancel request

---

## 5. Luồng Xử Lý Nghiệp Vụ

### 5.1 Luồng Tạo Mới Camera

```
┌──────┐      ┌──────────┐      ┌─────────┐      ┌────────┐
│ User │      │ Frontend │      │ Backend │      │   DB   │
└──┬───┘      └────┬─────┘      └────┬────┘      └────┬───┘
   │               │                 │                │
   │ 1. Fill form  │                 │                │
   │   name,       │                 │                │
   │   rtspUrl,    │                 │                │
   │   roomId      │                 │                │
   │──────────────>│                 │                │
   │               │                 │                │
   │               │ 2. Validate     │                │
   │               │    (Zod)        │                │
   │               │    - name regex │                │
   │               │    - rtsp://    │                │
   │               │                 │                │
   │               │ 3. POST         │                │
   │               │    /cameras     │                │
   │               │────────────────>│                │
   │               │                 │                │
   │               │                 │ 4. Check room  │
   │               │                 │    exists      │
   │               │                 │───────────────>│
   │               │                 │<───────────────│
   │               │                 │                │
   │               │                 │ 5. Check name  │
   │               │                 │    unique      │
   │               │                 │───────────────>│
   │               │                 │<───────────────│
   │               │                 │                │
   │               │                 │ 6. Check       │
   │               │                 │    rtspUrl     │
   │               │                 │    unique      │
   │               │                 │───────────────>│
   │               │                 │<───────────────│
   │               │                 │                │
   │               │                 │ 7. Insert      │
   │               │                 │    camera      │
   │               │                 │───────────────>│
   │               │                 │<───────────────│
   │               │                 │                │
   │               │ 8. Return DTO   │                │
   │               │    (201 Created)│                │
   │               │<────────────────│                │
   │               │                 │                │
   │ 9. Toast +    │                 │                │
   │    Invalidate │                 │                │
   │    cameras +  │                 │                │
   │    rooms      │                 │                │
   │<──────────────│                 │                │
```

### 5.2 Luồng Test RTSP Connection

```
┌──────┐      ┌──────────┐      ┌─────────┐      ┌─────────────┐
│ User │      │ Frontend │      │ Backend │      │   Python    │
└──┬───┘      └────┬─────┘      └────┬────┘      │   Service   │
   │               │                 │           └──────┬──────┘
   │               │                 │                  │
   │ 1. Click Test │                 │                  │
   │    Connection │                 │                  │
   │──────────────>│                 │                  │
   │               │                 │                  │
   │               │ 2. GET /test-   │                  │
   │               │    connection   │                  │
   │               │    ?rtspUrl=... │                  │
   │               │    &timeout=10  │                  │
   │               │────────────────>│                  │
   │               │                 │                  │
   │               │                 │ 3. Call Python  │
   │               │                 │    testCamera   │
   │               │                 │    Connection   │
   │               │                 │─────────────────>│
   │               │                 │                  │
   │               │                 │                  │ 4. Connect
   │               │                 │                  │    RTSP
   │               │                 │                  │    stream
   │               │                 │                  │
   │               │                 │                  │ 5. Analyze
   │               │                 │                  │    frame
   │               │                 │                  │    rate,
   │               │                 │                  │    resolution
   │               │                 │                  │
   │               │                 │ 6. Return       │
   │               │                 │    result       │
   │               │                 │<─────────────────│
   │               │                 │                  │
   │               │ 7. Return       │                  │
   │               │    connection   │                  │
   │               │    result       │                  │
   │               │<────────────────│                  │
   │               │                 │                  │
   │ 8. Show       │                 │                  │
   │    status     │                 │                  │
   │    icon +     │                 │                  │
   │    details    │                 │                  │
   │<──────────────│                 │                  │
```

### 5.3 Luồng Xóa Camera

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
   │               │    /cameras/{id}│                │
   │               │────────────────>│                │
   │               │                 │                │
   │               │                 │ 5. Check       │
   │               │                 │    active      │
   │               │                 │    slots in    │
   │               │                 │    camera's    │
   │               │                 │    room        │
   │               │                 │───────────────>│
   │               │                 │<───────────────│
   │               │                 │                │
   │               │                 │ 6. If has      │
   │               │                 │    active      │
   │               │                 │    slots       │
   │               │                 │    → 400 Error │
   │               │                 │                │
   │               │                 │ 7. Delete      │
   │               │                 │    camera      │
   │               │                 │───────────────>│
   │               │                 │<───────────────│
   │               │                 │                │
   │               │ 8. Success      │                │
   │               │<────────────────│                │
   │               │                 │                │
   │ 9. Toast +    │                 │                │
   │    Invalidate │                 │                │
   │    cameras +  │                 │                │
   │    rooms      │                 │                │
   │<──────────────│                 │                │
```

### 5.4 Luồng Import Camera từ CSV

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
   │               │                 │ │    name,    ││
   │               │                 │ │    rtspUrl  ││
   │               │                 │ │             ││
   │               │                 │ │ 6. Lookup   ││
   │               │                 │ │    room by  ││
   │               │                 │ │    name     ││
   │               │                 │ │             ││
   │               │                 │ │ 7. Check    ││
   │               │                 │ │    mode     ││
   │               │                 │ │             ││
   │               │                 │ │ 8. Insert/  ││
   │               │                 │ │    Update   ││
   │               │                 │ │─────────────>│
   │               │                 │ │             ││
   │               │                 │ │ 9. Log error││
   │               │                 │ │    if fail  ││
   │               │                 │ └─────────────┘│
   │               │                 │                │
   │               │ 10. Return      │                │
   │               │    ImportResult │                │
   │               │<────────────────│                │
   │               │                 │                │
   │ 11. Show      │                 │                │
   │     result    │                 │                │
   │<──────────────│                 │                │
```

---

## 6. Business Rules & Validation

### 6.1 Quy Tắc Validation

| Field | Rule | HTTP Status |
|-------|------|-------------|
| `name` | Required, unique, 1-150 chars | 400/409 |
| `name` | Pattern: `^[A-Za-z0-9\-]+( [A-Za-z0-9\-]+)*$` | 400 |
| `rtspUrl` | Required, unique, 1-512 chars | 400/409 |
| `rtspUrl` | Must start with `rtsp://` (frontend) | 400 |
| `roomId` | Required, room must exist | 400/404 |
| `isActive` | Boolean (update only) | 400 |

### 6.2 Quy Tắc Nghiệp Vụ

| Quy tắc | Mô tả |
|---------|-------|
| **Unique Name** | Mỗi camera có tên duy nhất (ví dụ: "Camera 101-A") |
| **Unique RTSP URL** | Mỗi camera có RTSP URL riêng biệt |
| **Room Required** | Camera bắt buộc phải thuộc một Room |
| **Room Changeable** | Có thể đổi Room khi update |
| **Delete Protection** | Không thể xóa nếu phòng có active slots |
| **No Cascade** | Không có cascade delete từ Room |
| **ID Type** | Short (1-32767) - đủ cho quy mô trường học |

**Chi tiết Delete Protection:**
- Kiểm tra **active slots** trong phòng chứa camera: `startTime >= now AND isActive = true`
- Timezone: `Asia/Ho_Chi_Minh`
- Nếu có active slots → 400 `CAMERA_HAS_ACTIVE_SLOTS`

### 6.3 CSV Import Rules

**Format CSV:**
```csv
name,rtspUrl,room_name[,isActive]
Camera 305-Front,rtsp://192.168.1.105:554/stream1,305
Camera 305-Back,rtsp://192.168.1.106:554/stream1,305
Camera Lab401-A,rtsp://192.168.1.110:554/stream1,Lab 401,true
Camera Lab401-B,rtsp://192.168.1.111:554/stream1,Lab 401,false
```

**Import Modes:**
| Mode | Hành vi |
|------|---------|
| `ADD_ONLY` | Chỉ thêm mới, skip nếu name đã tồn tại |
| `ADD_AND_UPDATE` | Thêm mới hoặc cập nhật nếu đã tồn tại |

**Constraints:**
- Encoding: UTF-8
- Deduplicate: Theo name (giữ dòng đầu tiên)
- Room lookup: Tìm room theo `room_name` từ CSV
- Default isActive: `true` nếu không cung cấp
- Partial success: Dòng lỗi không ảnh hưởng dòng khác
- RTSP URL unique check: Cho cả create và update

### 6.4 Error Codes

| Code | Mô tả | HTTP Status |
|------|-------|-------------|
| `CAMERA_NOT_FOUND` | Không tìm thấy camera | 404 |
| `CAMERA_NAME_EXISTS` | Tên camera đã tồn tại | 409 |
| `RTSP_URL_EXISTS` | RTSP URL đã tồn tại | 409 |
| `ROOM_NOT_FOUND` | Room không tồn tại | 404 |
| `CAMERA_HAS_ACTIVE_SLOTS` | Không thể xóa - phòng có active slots | 400 |
| `FOREIGN_KEY_CONSTRAINT_VIOLATION` | Vi phạm ràng buộc FK | 409 |
| `FILE_PROCESSING_ERROR` | Lỗi xử lý CSV file | 400 |
| `INVALID_FIELD_FORMAT` | Format field không hợp lệ | 400 |
| `CAMERA_NAME_REQUIRED` | Thiếu tên camera | 400 |
| `CAMERA_RTSP_URL_REQUIRED` | Thiếu RTSP URL | 400 |

---

## 7. Hướng Dẫn Phát Triển

### 7.1 Danh Sách File Quan Trọng

| File | Mô tả |
|------|-------|
| `backend/.../entity/Camera.java` | Entity chính |
| `backend/.../service/CameraService.java` | Business logic + test connection |
| `backend/.../controller/CameraController.java` | REST API |
| `backend/.../repository/impl/CameraRepositoryImpl.java` | Custom queries |
| `backend/.../dto/request/CameraCreateRequest.java` | Validation rules |
| `backend/.../client/PythonBackendClient.java` | Test RTSP connection |
| `frontend-web/app/admin/cameras/page.tsx` | Trang quản lý |
| `frontend-web/hooks/api/useCameras.ts` | React Query hooks |
| `frontend-web/components/admin/cameras/*.tsx` | UI components |
| `frontend-web/lib/zod-schemas.ts` | Frontend validation |

### 7.2 So Sánh Camera với Room

| Đặc tính | Camera | Room |
|----------|--------|------|
| **ID Type** | Short | Short |
| **Extends BaseEntity** | Có | Có |
| **Unique Fields** | name, rtspUrl | name |
| **Parent Entity** | Room (ManyToOne) | None |
| **Has Children** | None | cameras, slots |
| **CSV Import** | Có (lookup room by name) | Có |
| **Test Connection** | Có (RTSP) | Không |
| **Delete Check** | Active slots in room | Cameras + future slots |

### 7.3 Seed Data Reference

**50 cameras được tạo sẵn (2 camera/phòng × 25 phòng):**

| Phòng | Camera A | Camera B |
|-------|----------|----------|
| 101 | Camera 101-A | Camera 101-B |
| 102 | Camera 102-A | Camera 102-B (inactive) |
| 201 | Camera 201-A | Camera 201-B |
| Lab 401 | Camera Lab401-A | Camera Lab401-B |
| Exam Hall 1 | Camera ExamHall1-A | Camera ExamHall1-B |
| ... | ... | ... |

> **Lưu ý**: Camera 102-B được set `is_active = false` trong seed data để demo inactive state.

### 7.4 FAQ - Câu Hỏi Thường Gặp

**Q: Tại sao cả name và rtspUrl đều unique?**
> A: `name` để admin nhận diện camera (ví dụ: "Camera 101-A"), `rtspUrl` vì mỗi camera vật lý chỉ có một đường stream duy nhất.

**Q: Xóa camera có cascade delete không?**
> A: Không. Nhưng phải check không có active slots trong phòng chứa camera.

**Q: Test connection hoạt động như thế nào?**
> A: Backend gọi Python Recognition Service qua `PythonBackendClient.testCameraConnection()`. Python connect tới RTSP stream, đo frame rate, resolution, latency và trả về kết quả.

**Q: Camera có thể đổi phòng không?**
> A: Có. Khi update camera có thể đổi `roomId` sang phòng khác (phòng mới phải tồn tại).

**Q: Tại sao import CSV lookup room by name thay vì ID?**
> A: Vì admin không biết room ID khi chuẩn bị CSV file. Dùng room name (ví dụ: "301", "Lab 401") trực quan hơn.

### 7.5 Tóm Tắt Điểm Chính

1. **Camera = Thiết bị nhận diện** - Capture khuôn mặt sinh viên
2. **Camera → Room**: N:1 - Mỗi camera thuộc đúng một phòng (bắt buộc)
3. **Room → Camera**: 1:N - Mỗi phòng có nhiều camera
4. **Dual Unique**: Cả `name` và `rtspUrl` đều unique
5. **Test Connection**: Kiểm tra RTSP stream trước khi save
6. **Delete Protection**: Không thể xóa nếu phòng có active slots
7. **CSV Import**: Partial success, lookup room by name
8. **Frontend**: Chỉ DATA_OPERATOR được truy cập trang quản lý

### 7.6 Các Bước Khi Trình Bày Hội Đồng

1. **Giới thiệu module**: Camera là gì, vai trò trong hệ thống điểm danh
2. **Show database**: cameras table, relationship với rooms
3. **Demo tạo mới**: Form validation, room selection, unique checks
4. **Demo test connection**: Test RTSP URL trực tiếp trong form
5. **Show import CSV**: Partial success, room lookup by name
6. **Giải thích protection**: Tại sao không xóa được camera khi có slots
7. **Demo recognition flow**: Camera gửi stream → Python service → Nhận diện → Điểm danh
