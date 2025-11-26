# Regular Attendance Module - Tài Liệu Kỹ Thuật

> **Mục đích tài liệu**: Giúp người đọc hiểu hệ thống điểm danh thường (Regular Attendance) cho các buổi học LECTURE và LECTURE_WITH_PT trong FUACS.

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

### 1.1 Regular Attendance là gì?

**Regular Attendance** (Điểm danh thường) là hệ thống ghi nhận sự có mặt của sinh viên trong các buổi học lý thuyết (LECTURE) và buổi học có bài kiểm tra tiến độ (LECTURE_WITH_PT).

Khác với Exam Attendance (điểm danh thi), Regular Attendance:

- Áp dụng cho **tất cả sinh viên enrolled trong lớp**
- Ghi nhận tự động qua **nhận diện khuôn mặt** hoặc thủ công
- Có thể có **nhiều lần quét** trong một buổi học
- Hỗ trợ **RESCAN** để kiểm tra lại những sinh viên chưa được nhận diện

### 1.2 Vai trò trong Hệ thống

| Vai trò        | Mô tả                                          |
| -------------- | ---------------------------------------------- |
| **Tracking**   | Ghi nhận lịch sử điểm danh cho từng buổi học   |
| **Automation** | Tự động điểm danh qua face recognition         |
| **Evidence**   | Lưu trữ hình ảnh bằng chứng (evidence image)   |
| **Review**     | Đánh dấu records cần xem xét lại (needsReview) |
| **Remarks**    | Cho phép ghi chú cho từng bản ghi              |

### 1.3 Mối Quan Hệ với Các Module Khác

```
┌─────────────────┐       ┌─────────────────┐
│     SLOT        │       │  ACADEMIC_CLASS │
│ (LECTURE/       │       │  (Lớp học)      │
│  LECTURE_WITH_  │       └────────┬────────┘
│  PT)            │                │
└────────┬────────┘                │ Enrollment
         │                         ▼
         │ 1:N              ┌─────────────────┐
         │                  │    STUDENT      │
         ▼                  │   (Sinh viên)   │
┌─────────────────┐         └────────┬────────┘
│   ATTENDANCE    │                  │
│    RECORD       │◄─────────────────┘
│                 │         N:1 (student_user_id)
├─────────────────┤
│ id              │
│ student_user_id │
│ slot_id         │
│ status          │──────────────────┐
│ method          │                  │
│ recorded_at     │                  ▼
│ remark          │         ┌─────────────────┐
│ needs_review    │         │   EVIDENCE      │
└────────┬────────┘         │ (Hình ảnh       │
         │                  │  bằng chứng)    │
         │ 1:N              └─────────────────┘
         ▼
┌─────────────────┐
│    REMARKS      │
│ (Ghi chú từ     │
│  nhiều người)   │
└─────────────────┘
```

### 1.4 Attendance Status Flow

```
┌──────────────────────────────────────────────────────────────────────┐
│                    ATTENDANCE STATUS LIFECYCLE                        │
├──────────────────────────────────────────────────────────────────────┤
│                                                                       │
│    ┌─────────┐                                                        │
│    │ NOT_YET │◄──────── Initial state (khi tạo slot)                 │
│    └────┬────┘                                                        │
│         │                                                             │
│    ┌────┴────────────────────────────────────────┐                   │
│    │                                             │                   │
│    ▼                                             ▼                   │
│ ┌─────────┐                                 ┌─────────┐              │
│ │ PRESENT │◄─── Face recognized             │ ABSENT  │◄─── Manual   │
│ │         │     OR Manual update            │         │     OR       │
│ └────┬────┘                                 └────┬────┘    Finalize  │
│      │                                           │                   │
│      │         ┌─────────────────────────────────┘                   │
│      │         │                                                     │
│      │         ▼                                                     │
│      │    RESCAN Mode:                                               │
│      │    ┌─────────────────────────────────────────────────────┐   │
│      │    │ ABSENT + detected → Keep ABSENT + needsReview=true  │   │
│      │    │ PRESENT + NOT detected → Keep PRESENT + needsReview │   │
│      │    └─────────────────────────────────────────────────────┘   │
│      │                                                               │
│      └─────────────────────────────────────────────────────────────►│
│                                                                       │
│    FINALIZE (khi stop session):                                      │
│    - Tất cả NOT_YET → ABSENT (method=SYSTEM_FINALIZE)                │
│                                                                       │
└──────────────────────────────────────────────────────────────────────┘
```

---

## 2. Kiến Trúc Hệ Thống

### 2.1 Tổng Quan Kiến Trúc

```
┌─────────────────────────────────────────────────────────────────────┐
│                         FRONTEND (Next.js)                          │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │               ROSTER VIEW (Admin/Lecturer)                     │  │
│  │  ┌─────────────────────────────────────────────────────────┐  │  │
│  │  │  Session Controls: [Start] [Stop] [Rescan] [Submit]     │  │  │
│  │  │                                                          │  │  │
│  │  │  Student List (Real-time via SSE):                      │  │  │
│  │  │  ┌────────────────────────────────────────────────────┐ │  │  │
│  │  │  │ Name     │ Roll │ Status  │ Method │ Evidence     │ │  │  │
│  │  │  │──────────│──────│─────────│────────│──────────────│ │  │  │
│  │  │  │ Nguyen A │ SE01 │ PRESENT │ AUTO   │ [View Image] │ │  │  │
│  │  │  │ Tran B   │ SE02 │ ABSENT  │ MANUAL │     -        │ │  │  │
│  │  │  │ Le C     │ SE03 │ NOT_YET │   -    │     -        │ │  │  │
│  │  │  └────────────────────────────────────────────────────┘ │  │  │
│  │  └─────────────────────────────────────────────────────────┘  │  │
│  └───────────────────────────────────────────────────────────────┘  │
│                              │                                       │
│              ┌───────────────┴───────────────┐                       │
│              │  useSlotRoster + useSlotSSE   │                       │
│              └───────────────┬───────────────┘                       │
└──────────────────────────────┼──────────────────────────────────────┘
                               │ REST + SSE
                               ▼
┌─────────────────────────────────────────────────────────────────────┐
│                      BACKEND (Spring Boot)                          │
│                                                                      │
│  ┌──────────────────┐    ┌──────────────────┐    ┌───────────────┐  │
│  │ SlotController   │    │ Attendance       │    │  SseHub       │  │
│  │ /slots/{id}/     │    │ RecordController │    │ (Real-time)   │  │
│  │ roster, start,   │    │ /{id}            │    │               │  │
│  │ stop, rescan     │    │                  │    │ attendance.   │  │
│  └────────┬─────────┘    └────────┬─────────┘    │ update event  │  │
│           │                       │               └───────┬───────┘  │
│           ▼                       ▼                       │          │
│  ┌────────────────────────────────────────────────────────┘          │
│  │                        SERVICES                                   │
│  │  SlotSessionService ← Orchestrates face recognition session      │
│  │  AttendanceRecordService ← Process recognition callbacks         │
│  └────────────────────────────────────────────────────────┬─────────┘
│                                                            │
└────────────────────────────────────────────────────────────┼─────────┘
                                                             │ HTTP
                   ┌─────────────────────────────────────────┴──────┐
                   │            Python Recognition Service          │
                   │  - Face detection (InsightFace)                │
                   │  - RTSP camera streaming                       │
                   │  - Evidence image generation                   │
                   │  - Callback với recognition results            │
                   └────────────────────────────────────────────────┘
```

### 2.2 Cấu Trúc Thư Mục

**Backend:**

```
backend/src/main/java/com/fuacs/backend/
├── entity/
│   ├── AttendanceRecord.java           # Main entity
│   ├── RegularAttendanceRemark.java    # Remarks (soft-deleted, audited)
│   └── RegularAttendanceEvidence.java  # Evidence images (1:1)
├── dto/
│   ├── request/
│   │   ├── AttendanceRecordSearchRequest.java
│   │   ├── AttendanceRecordUpdateRequest.java
│   │   └── SlotAttendanceSubmissionRequest.java
│   └── response/
│       ├── AttendanceRecordDTO.java
│       └── SlotRosterItemDTO.java
├── repository/
│   ├── AttendanceRecordRepository.java
│   └── RegularAttendanceRemarkRepository.java
├── service/
│   ├── AttendanceRecordService.java    # CRUD + recognition callback
│   └── SlotSessionService.java         # Session lifecycle
├── controller/
│   ├── AttendanceRecordController.java # Direct record operations
│   └── SlotController.java             # roster, session endpoints
└── realtime/
    └── SseHub.java                     # SSE broadcasting
```

**Frontend:**

```
frontend-web/
├── app/
│   ├── admin/slots/[id]/roster/page.tsx
│   └── lecturer/slots/[id]/roster/page.tsx
├── components/admin/slots/
│   ├── slot-roster-table.tsx           # Attendance marking table
│   ├── session-controls.tsx            # Start/Stop/Rescan buttons
│   ├── evidence-viewer-dialog.tsx      # View evidence images
│   └── finalize-slot-dialog.tsx        # Confirm NOT_YET resolution
├── hooks/
│   ├── api/
│   │   ├── useSlotRoster.ts            # Get roster data
│   │   ├── useAttendanceRecords.ts     # CRUD attendance records
│   │   ├── useSlotSession.ts           # Start/Stop/Rescan mutations
│   │   └── useSubmitAttendance.ts      # Batch submit
│   └── realtime/
│       └── useSlotRosterSSE.ts         # Real-time updates
└── types/
    └── index.ts                        # AttendanceRecord, SlotRosterItem
```

---

## 3. Backend Implementation

### 3.1 Database Schema

**Bảng `attendance_records`:**

```sql
CREATE TABLE attendance_records (
    id BIGSERIAL PRIMARY KEY,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- Core fields
    student_user_id INTEGER NOT NULL,
    slot_id INTEGER NOT NULL,
    recorded_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- Status
    status VARCHAR(20) NOT NULL DEFAULT 'not_yet'
        CHECK (status IN ('not_yet', 'present', 'absent')),
    method VARCHAR(20)
        CHECK (method IN ('auto', 'manual', 'system_finalize')),

    -- Review & Remark
    remark TEXT,
    needs_review BOOLEAN NOT NULL DEFAULT FALSE,

    -- Foreign Keys
    FOREIGN KEY (student_user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (slot_id) REFERENCES slots(id) ON DELETE CASCADE
);

-- Unique constraint: 1 record per student per slot
CREATE UNIQUE INDEX idx_attendance_records_student_slot
    ON attendance_records(student_user_id, slot_id);

-- Performance indexes
CREATE INDEX idx_attendance_records_slot_id ON attendance_records(slot_id);
CREATE INDEX idx_attendance_records_status ON attendance_records(status);
```

**Bảng `regular_attendance_evidences`:**

```sql
CREATE TABLE regular_attendance_evidences (
    id BIGSERIAL PRIMARY KEY,
    attendance_record_id BIGINT NOT NULL UNIQUE,
    image_url VARCHAR(255) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (attendance_record_id)
        REFERENCES attendance_records(id) ON DELETE CASCADE
);
```

**Bảng `regular_attendance_remarks`:**

```sql
CREATE TABLE regular_attendance_remarks (
    id BIGSERIAL PRIMARY KEY,
    attendance_record_id BIGINT NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by_user_id INTEGER NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    remark TEXT NOT NULL,

    FOREIGN KEY (attendance_record_id)
        REFERENCES attendance_records(id) ON DELETE CASCADE,
    FOREIGN KEY (created_by_user_id) REFERENCES users(id)
);
```

### 3.2 Entity Classes

**AttendanceRecord.java:**

```java
@EntityListeners(AuditingEntityListener.class)
@Entity
@Table(name = "attendance_records",
    uniqueConstraints = {
        @UniqueConstraint(name = "idx_attendance_records_student_slot",
                         columnNames = {"student_user_id", "slot_id"})
    },
    indexes = {
        @Index(name = "idx_attendance_records_slot_id", columnList = "slot_id"),
        @Index(name = "idx_attendance_records_status", columnList = "status")
    }
)
public class AttendanceRecord {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @CreatedDate
    @Column(name = "created_at", updatable = false, nullable = false)
    private Instant createdAt;

    @LastModifiedDate
    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    @Column(name = "recorded_at", nullable = false)
    private Instant recordedAt;

    // === RELATIONSHIPS ===

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "student_user_id", nullable = false)
    private User student;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "slot_id", nullable = false)
    private Slot slot;

    // === STATUS ===

    @Convert(converter = AttendanceStatusConverter.class)
    @Column(name = "status", nullable = false, length = 20)
    private AttendanceStatus status = AttendanceStatus.NOT_YET;

    @Convert(converter = AttendanceMethodConverter.class)
    @Column(name = "method", length = 20)
    private AttendanceMethod method;

    // === REVIEW & REMARK ===

    @Column(name = "remark", columnDefinition = "TEXT")
    private String remark;

    @Column(name = "needs_review", nullable = false)
    private Boolean needsReview = false;

    @PrePersist
    public void prePersist() {
        if (this.recordedAt == null) {
            this.recordedAt = Instant.now();
        }
    }
}
```

**RegularAttendanceEvidence.java:**

```java
@Entity
@Table(name = "regular_attendance_evidences")
public class RegularAttendanceEvidence {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "attendance_record_id", nullable = false, unique = true)
    private AttendanceRecord attendanceRecord;

    @Column(name = "image_url", nullable = false, length = 255)
    private String imageUrl;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt = Instant.now();
}
```

### 3.3 REST API Endpoints

**SlotController - Session & Roster:**

| Method | Endpoint                        | Permission                        | Mô tả                            |
| ------ | ------------------------------- | --------------------------------- | -------------------------------- |
| GET    | `/slots/{id}/roster`            | `ATTENDANCE_ROSTER_READ`          | Danh sách sinh viên + attendance |
| POST   | `/slots/{id}/start-session`     | `SLOT_SESSION_START`              | Bắt đầu face recognition         |
| POST   | `/slots/{id}/stop-session`      | `SLOT_SESSION_FINALIZE`           | Dừng session + finalize          |
| POST   | `/slots/{id}/rescan`            | `SLOT_SESSION_RESCAN`             | Quét lại sinh viên absent        |
| POST   | `/slots/{id}/submit-attendance` | `ATTENDANCE_STATUS_UPDATE_MANUAL` | Submit batch attendance          |

**AttendanceRecordController:**

| Method | Endpoint                   | Permission                        | Mô tả                     |
| ------ | -------------------------- | --------------------------------- | ------------------------- |
| GET    | `/attendance-records`      | `ATTENDANCE_ROSTER_READ`          | Search attendance records |
| GET    | `/attendance-records/{id}` | `ATTENDANCE_ROSTER_READ`          | Chi tiết record           |
| PUT    | `/attendance-records/{id}` | `ATTENDANCE_STATUS_UPDATE_MANUAL` | Update status manually    |

**Internal Endpoint (từ Python service):**

| Method | Endpoint                                | Auth      | Mô tả                |
| ------ | --------------------------------------- | --------- | -------------------- |
| POST   | `/api/v1/attendance/recognition-result` | X-API-Key | Recognition callback |

### 3.4 Request/Response DTOs

**SlotRosterItemDTO:**

```java
public class SlotRosterItemDTO {
    private StudentProfileDTO student;
    private SubjectDTO subject;  // null for regular slots
    private AttendanceStatusDTO regularAttendance;
    private AttendanceStatusDTO examAttendance;  // null for LECTURE
}

public class AttendanceStatusDTO {
    private Long recordId;
    private String status;       // not_yet, present, absent
    private String method;       // auto, manual, system_finalize
    private String evidenceImageUrl;
    private String remark;
    private Boolean needsReview;
}
```

**SlotAttendanceSubmissionRequest:**

```java
public class SlotAttendanceSubmissionRequest {
    private String attendanceType;  // "REGULAR", "EXAM", or null (both)

    @Size(max = 100)
    private List<AttendanceSubmissionItem> submissions;

    private NotYetResolution notYetResolution;  // MARK_AS_ABSENT or MARK_AS_PRESENT
}

public class AttendanceSubmissionItem {
    @NotNull
    private Integer studentUserId;

    @NotNull
    private AttendanceStatus status;

    @Size(max = 1000)
    private String remark;
}
```

**AttendanceRecordUpdateRequest:**

```java
public class AttendanceRecordUpdateRequest {
    @NotNull
    private AttendanceStatus status;  // PRESENT or ABSENT only

    @NotBlank(message = "Remark is required for manual attendance updates")
    @Size(max = 1000)
    private String remark;
}
```

### 3.5 Service Layer

**SlotSessionService - Session Management:**

| Method                  | Input   | Output                | Mô tả                     |
| ----------------------- | ------- | --------------------- | ------------------------- |
| `startSession(slotId)`  | Integer | SessionStatusResponse | Bắt đầu face recognition  |
| `stopSession(slotId)`   | Integer | SessionStatusResponse | Dừng + finalize NOT_YET   |
| `rescanSession(slotId)` | Integer | SessionStatusResponse | Quét lại sinh viên absent |

**AttendanceRecordService - Attendance Logic:**

| Method                                        | Input                    | Output                  | Mô tả                  |
| --------------------------------------------- | ------------------------ | ----------------------- | ---------------------- |
| `findBySlotId(slotId)`                        | Integer                  | List<SlotRosterItemDTO> | Roster with attendance |
| `updateStatus(id, request)`                   | Long, UpdateRequest      | AttendanceRecordDTO     | Manual update          |
| `processRecognitionResults(request)`          | RecognitionResultRequest | Map<String, Object>     | Handle Python callback |
| `applyRescanReviewFlags(slotId, detectedIds)` | Integer, Set<Integer>    | void                    | Apply review flags     |

**Recognition Callback Processing:**

```java
public Map<String, Object> processInitialRecognitionResults(
    RecognitionResultRequest request,
    Slot slot
) {
    int successCount = 0;
    int keptPresentCount = 0;
    int skippedCount = 0;

    for (RecognitionResult recognition : request.getRecognitions()) {
        AttendanceRecord record = findOrCreate(slot, recognition.getStudentUserId());

        if (record.getStatus() == AttendanceStatus.NOT_YET) {
            // Auto-update: NOT_YET → PRESENT
            record.setStatus(AttendanceStatus.PRESENT);
            record.setMethod(AttendanceMethod.AUTO);
            record.setRecordedAt(Instant.now());

            // Save evidence
            saveEvidence(record, recognition.getEvidence());

            // Broadcast SSE
            publishAttendanceUpdate(slot.getId(), recognition, record);

            successCount++;
        } else if (record.getStatus() == AttendanceStatus.PRESENT) {
            // Already PRESENT - update evidence only
            updateEvidence(record, recognition.getEvidence());
            keptPresentCount++;
        } else {
            // ABSENT - skip (don't override manual entries)
            skippedCount++;
        }
    }

    return Map.of(
        "successCount", successCount,
        "keptPresentCount", keptPresentCount,
        "skippedCount", skippedCount
    );
}
```

---

## 4. Frontend Implementation

### 4.1 Roster Page

**Route:** `/admin/slots/[id]/roster` hoặc `/lecturer/slots/[id]/roster`

**UI Layout:**

```
┌──────────────────────────────────────────────────────────────────┐
│  Slot Roster - PRO192 Lecture #1                                 │
│  Room: 301 | Staff: lecturer1 | Time: 08:00 - 09:30             │
├──────────────────────────────────────────────────────────────────┤
│                                                                   │
│  Session Status: [●] RUNNING    Scan Count: 15                   │
│                                                                   │
│  [Start Session] [Stop Session] [Rescan] [Submit All]            │
│                                                                   │
├──────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌─ Filters ───────────────────────────────────────────────────┐ │
│  │ Status: [All ▼]  Search: [____________]                     │ │
│  └─────────────────────────────────────────────────────────────┘ │
│                                                                   │
│  ┌─ Roster Table ──────────────────────────────────────────────┐ │
│  │ # │ Roll    │ Name      │ Status   │ Method │ Avatar │ Evid │ │
│  │───│─────────│───────────│──────────│────────│────────│──────│ │
│  │ 1 │ SE18001 │ Nguyen A  │ ◉PRESENT │ AUTO   │ [img]  │[img] │ │
│  │ 2 │ SE18002 │ Tran B    │ ◯ABSENT  │ MANUAL │ [img]  │  -   │ │
│  │ 3 │ SE18003 │ Le C      │ ○NOT_YET │   -    │ [img]  │  -   │ │
│  │ 4 │ SE18004 │ Pham D⚠️  │ ◉PRESENT │ AUTO   │ [img]  │[img] │ │
│  │   │         │           │ needs    │        │        │      │ │
│  │   │         │           │ review   │        │        │      │ │
│  └─────────────────────────────────────────────────────────────┘ │
│                                                                   │
│  Showing 1-4 of 30                           [< 1 2 3 ... 8 >]   │
│                                                                   │
└──────────────────────────────────────────────────────────────────┘
```

### 4.2 Component Structure

```
SlotRosterPage
├── SlotInfo (header with slot details)
├── SessionControls
│   ├── SessionStatusBadge (NOT_STARTED | RUNNING | STOPPED)
│   ├── ScanCountDisplay
│   ├── StartSessionButton
│   ├── StopSessionButton
│   ├── RescanButton
│   └── SubmitAllButton
├── RosterFilters
│   ├── StatusFilter (All | Present | Absent | Not Yet | Needs Review)
│   └── SearchInput
├── SlotRosterTable
│   ├── TableHeader (sortable columns)
│   └── TableBody
│       └── RosterRow (per student)
│           ├── IndexCell
│           ├── RollNumberCell
│           ├── NameCell (+ needsReview indicator)
│           ├── StatusRadioGroup (PRESENT | ABSENT | NOT_YET)
│           ├── MethodBadge
│           ├── AvatarCell
│           ├── EvidenceCell (click to view)
│           └── RemarkInput
├── EvidenceViewerDialog
├── FinalizeDialog (NOT_YET resolution)
└── RosterPagination
```

### 4.3 React Query Hooks

**useSlotRoster.ts:**

```typescript
// Get roster data
export const useGetSlotRoster = (slotId: number) => {
  return useQuery<SlotRosterResponse, Error>({
    queryKey: QUERY_KEYS.slots.roster(slotId),
    queryFn: async () => {
      const response = await api.get(API_ENDPOINTS.slots.roster(slotId));
      return slotRosterResponseSchema.parse(response);
    },
    staleTime: 2 * 60 * 1000, // 2 minutes
  });
};
```

**useSlotSession.ts:**

```typescript
// Start session
export const useStartSession = () => {
  return useMutation<SessionStatusResponse, Error, number>({
    mutationFn: async (slotId) => {
      const response = await api.post(API_ENDPOINTS.slots.startSession(slotId));
      return sessionStatusResponseSchema.parse(response);
    },
    onSuccess: (data, slotId) => {
      toast.success(`Session started with ${data.activeCameras} cameras`);
      queryClient.invalidateQueries({
        queryKey: QUERY_KEYS.slots.detail(slotId),
      });
      queryClient.invalidateQueries({
        queryKey: QUERY_KEYS.slots.roster(slotId),
      });
    },
  });
};

// Stop session
export const useStopSession = () => {
  return useMutation<SessionStatusResponse, Error, number>({
    mutationFn: async (slotId) => {
      const response = await api.post(API_ENDPOINTS.slots.stopSession(slotId));
      return sessionStatusResponseSchema.parse(response);
    },
    onSuccess: (data, slotId) => {
      toast.success(
        `Session stopped. Total recognitions: ${data.totalRecognitions}`
      );
      // Invalidate queries...
    },
  });
};

// Rescan
export const useRescanSession = () => {
  return useMutation<SessionStatusResponse, Error, number>({
    mutationFn: async (slotId) => {
      const response = await api.post(API_ENDPOINTS.slots.rescan(slotId));
      return sessionStatusResponseSchema.parse(response);
    },
    // Similar to startSession...
  });
};
```

**useSlotRosterSSE.ts - Real-time Updates:**

```typescript
export const useSlotRosterSSE = (slotId: number) => {
  const [isConnected, setIsConnected] = useState(false);
  const [hasError, setHasError] = useState<string | null>(null);

  useEffect(() => {
    const token = getAuthToken();
    const eventSource = new EventSource(
      `${API_BASE_URL}/slots/${slotId}/events?token=${token}`
    );

    eventSource.onopen = () => {
      setIsConnected(true);
      setHasError(null);
    };

    eventSource.addEventListener("attendance.update", (event) => {
      const data: AttendanceUpdateEvent = JSON.parse(event.data);

      // Update local cache
      queryClient.setQueryData<SlotRosterResponse>(
        QUERY_KEYS.slots.roster(slotId),
        (prev) => {
          if (!prev) return prev;
          return prev.map((item) => {
            if (item.student.userId !== data.studentUserId) return item;

            // Update regularAttendance
            return {
              ...item,
              regularAttendance: {
                recordId: data.recordId,
                status: data.status,
                method: data.method,
                evidenceImageUrl: data.evidenceImageUrl,
                remark: item.regularAttendance?.remark ?? null,
                needsReview: data.needsReview ?? false,
              },
            };
          });
        }
      );
    });

    eventSource.onerror = () => {
      setIsConnected(false);
      setHasError("Connection lost");
    };

    return () => eventSource.close();
  }, [slotId]);

  return { isConnected, hasError };
};
```

### 4.4 TypeScript Types

```typescript
interface SlotRosterItem {
  student: {
    userId: number;
    fullName: string;
    rollNumber: string | null;
    email: string | null;
    photoUrl: string | null;
  };
  subject?: {
    id: number;
    name: string;
    code: string;
  } | null;
  regularAttendance?: AttendanceStatus | null;
  examAttendance?: AttendanceStatus | null;
}

interface AttendanceStatus {
  recordId: number;
  status: "not_yet" | "present" | "absent";
  method?: "auto" | "manual" | "system_finalize" | null;
  evidenceImageUrl: string | null;
  remark: string | null;
  needsReview?: boolean;
}

type SlotRosterResponse = SlotRosterItem[];

interface AttendanceUpdateEvent {
  slotId: number;
  studentUserId: number;
  kind: "regular" | "exam";
  recordId: number;
  status: "not_yet" | "present" | "absent";
  method: "auto" | "manual" | "system_finalize";
  recordedAt: string;
  evidenceImageUrl: string | null;
  needsReview: boolean;
}
```

---

## 5. Luồng Xử Lý Nghiệp Vụ

### 5.1 Luồng Start Session → Recognition → Update

```
┌──────┐    ┌──────────┐    ┌─────────┐    ┌─────────┐    ┌────────────┐
│Staff │    │ Frontend │    │ Backend │    │ Python  │    │  Cameras   │
└──┬───┘    └────┬─────┘    └────┬────┘    │ Service │    │  (RTSP)    │
   │             │               │         └────┬────┘    └─────┬──────┘
   │             │               │              │                │
   │ 1. Click    │               │              │                │
   │    Start    │               │              │                │
   │─────────────>               │              │                │
   │             │               │              │                │
   │             │ 2. POST       │              │                │
   │             │    /start-    │              │                │
   │             │    session    │              │                │
   │             │──────────────>│              │                │
   │             │               │              │                │
   │             │               │ 3. Get students │             │
   │             │               │    with embeddings             │
   │             │               │              │                │
   │             │               │ 4. Get cameras │              │
   │             │               │    for room   │               │
   │             │               │              │                │
   │             │               │ 5. POST      │                │
   │             │               │    /process- │                │
   │             │               │    session   │                │
   │             │               │─────────────>│                │
   │             │               │              │                │
   │             │               │              │ 6. Connect     │
   │             │               │              │    to cameras  │
   │             │               │              │───────────────>│
   │             │               │              │<───────────────│
   │             │               │              │                │
   │             │               │ 7. Return    │                │
   │             │               │    session   │                │
   │             │               │    started   │                │
   │             │               │<─────────────│                │
   │             │               │              │                │
   │             │ 8. Update UI  │              │                │
   │             │    session=   │              │                │
   │             │    RUNNING    │              │                │
   │             │<──────────────│              │                │
   │             │               │              │                │
   │             │               │              │ [LOOP]         │
   │             │               │              │ 9. Capture     │
   │             │               │              │    frame       │
   │             │               │              │<───────────────│
   │             │               │              │                │
   │             │               │              │ 10. Detect     │
   │             │               │              │     faces      │
   │             │               │              │                │
   │             │               │              │ 11. Match with │
   │             │               │              │     embeddings │
   │             │               │              │                │
   │             │               │              │ 12. Save       │
   │             │               │              │     evidence   │
   │             │               │              │                │
   │             │               │ 13. Callback │                │
   │             │               │     with     │                │
   │             │               │     results  │                │
   │             │               │<─────────────│                │
   │             │               │              │                │
   │             │               │ 14. Process  │                │
   │             │               │     results: │                │
   │             │               │     NOT_YET  │                │
   │             │               │     →PRESENT │                │
   │             │               │              │                │
   │             │               │ 15. Publish  │                │
   │             │ SSE Event     │     SSE      │                │
   │             │ attendance.   │              │                │
   │             │ update        │              │                │
   │             │<──────────────│              │                │
   │             │               │              │                │
   │ 16. UI      │               │              │                │
   │     updates │               │              │                │
   │     real-   │               │              │                │
   │     time    │               │              │                │
   │<────────────│               │              │                │
```

### 5.2 Luồng Manual Attendance Update

```
┌──────┐      ┌──────────┐      ┌─────────┐      ┌────────┐
│Staff │      │ Frontend │      │ Backend │      │   DB   │
└──┬───┘      └────┬─────┘      └────┬────┘      └────┬───┘
   │               │                 │                │
   │ 1. Click      │                 │                │
   │    ABSENT     │                 │                │
   │    for        │                 │                │
   │    student    │                 │                │
   │──────────────>│                 │                │
   │               │                 │                │
   │               │ 2. Mark as     │                │
   │               │    dirty       │                │
   │               │    (amber bg)  │                │
   │               │                 │                │
   │               │ 3. Enter       │                │
   │               │    remark      │                │
   │──────────────>│    (required)  │                │
   │               │                 │                │
   │ 4. Click      │                 │                │
   │    Submit     │                 │                │
   │──────────────>│                 │                │
   │               │                 │                │
   │               │ 5. PUT         │                │
   │               │    /attendance-│                │
   │               │    records/{id}│                │
   │               │────────────────>│                │
   │               │                 │                │
   │               │                 │ 6. Validate   │
   │               │                 │    edit       │
   │               │                 │    window     │
   │               │                 │                │
   │               │                 │ 7. Check      │
   │               │                 │    staff      │
   │               │                 │    assigned   │
   │               │                 │                │
   │               │                 │ 8. Update     │
   │               │                 │    record     │
   │               │                 │    method=    │
   │               │                 │    MANUAL     │
   │               │                 │───────────────>│
   │               │                 │<───────────────│
   │               │                 │                │
   │               │ 9. Return      │                │
   │               │    updated     │                │
   │               │<────────────────│                │
   │               │                 │                │
   │ 10. Toast +   │                 │                │
   │     Update UI │                 │                │
   │<──────────────│                 │                │
```

### 5.3 Luồng Submit All (Batch)

```
┌──────┐      ┌──────────┐      ┌─────────┐      ┌────────┐
│Staff │      │ Frontend │      │ Backend │      │   DB   │
└──┬───┘      └────┬─────┘      └────┬────┘      └────┬───┘
   │               │                 │                │
   │ 1. Click      │                 │                │
   │    Submit All │                 │                │
   │──────────────>│                 │                │
   │               │                 │                │
   │               │ 2. Check       │                │
   │               │    dirty rows  │                │
   │               │    + NOT_YET   │                │
   │               │    students    │                │
   │               │                 │                │
   │               │ 3. Show        │                │
   │               │    NOT_YET     │                │
   │ 4. Select     │    resolution  │                │
   │    MARK_AS_   │    dialog      │                │
   │    ABSENT     │                 │                │
   │──────────────>│                 │                │
   │               │                 │                │
   │               │ 5. POST /slots │                │
   │               │    /{id}/      │                │
   │               │    submit-     │                │
   │               │    attendance  │                │
   │               │                 │                │
   │               │    {           │                │
   │               │      "notYet   │                │
   │               │       Resolu-  │                │
   │               │       tion":   │                │
   │               │       "MARK_   │                │
   │               │        AS_     │                │
   │               │        ABSENT",│                │
   │               │      "submis-  │                │
   │               │       sions":  │                │
   │               │       [...]    │                │
   │               │    }           │                │
   │               │────────────────>│                │
   │               │                 │                │
   │               │                 │ 6. Process    │
   │               │                 │    each       │
   │               │                 │    submission │
   │               │                 │               ┌┴┐
   │               │                 │    For each   │ │
   │               │                 │    student:   │ │
   │               │                 │    - Validate │ │
   │               │                 │    - Update   │ │
   │               │                 │      DB       │ │
   │               │                 │──────────────>│ │
   │               │                 │               └┬┘
   │               │                 │                │
   │               │                 │ 7. Apply      │
   │               │                 │    NOT_YET    │
   │               │                 │    resolution │
   │               │                 │───────────────>│
   │               │                 │<───────────────│
   │               │                 │                │
   │               │ 8. Return      │                │
   │               │    results     │                │
   │               │    {success:30,│                │
   │               │     failure:0} │                │
   │               │<────────────────│                │
   │               │                 │                │
   │ 9. Toast      │                 │                │
   │<──────────────│                 │                │
```

---

## 6. Business Rules & Validation

### 6.1 Attendance Status Rules

| Transition        | Allowed | Method          | Condition                        |
| ----------------- | ------- | --------------- | -------------------------------- |
| NOT_YET → PRESENT | Yes     | AUTO            | Face recognized                  |
| NOT_YET → PRESENT | Yes     | MANUAL          | Staff update                     |
| NOT_YET → ABSENT  | Yes     | MANUAL          | Staff update                     |
| NOT_YET → ABSENT  | Yes     | SYSTEM_FINALIZE | Stop session                     |
| PRESENT → ABSENT  | Yes     | MANUAL          | Staff override (requires remark) |
| ABSENT → PRESENT  | Yes     | MANUAL          | Staff override (requires remark) |
| Any → NOT_YET     | **No**  | -               | Cannot revert to NOT_YET         |

### 6.2 Edit Window Rules

```
Edit Window: [slot.startTime, 23:59:59 Vietnam time on slot date]

BEFORE slot.startTime:
   → 400 EDIT_BEFORE_SLOT_START
   → "Cannot update attendance before slot starts"

AFTER 23:59:59 on slot date:
   → Check if user has DATA_OPERATOR role
   → If yes: Allow (extended edit window)
   → If no: 400 EDIT_WINDOW_EXPIRED

Staff Assignment:
   → Only assigned staff can update attendance
   → Others: 403 NOT_ASSIGNED_TO_SLOT
```

### 6.3 RESCAN Mode Logic

| Current Status | Detected in RESCAN | Result       | needsReview   |
| -------------- | ------------------ | ------------ | ------------- |
| PRESENT        | Yes                | Keep PRESENT | Clear (false) |
| PRESENT        | No                 | Keep PRESENT | Set (true)    |
| ABSENT         | Yes                | Keep ABSENT  | Set (true)    |
| ABSENT         | No                 | Keep ABSENT  | Keep current  |
| NOT_YET        | Yes                | → PRESENT    | false         |
| NOT_YET        | No                 | Keep NOT_YET | false         |

**Lý do:**

- PRESENT + not detected: Có thể sinh viên đã rời khỏi sớm, cần kiểm tra
- ABSENT + detected: Có thể sinh viên đến trễ, cần xem xét cho phép

### 6.4 Validation Rules

| Field           | Rule                               | Error               |
| --------------- | ---------------------------------- | ------------------- |
| `status`        | NOT_YET, PRESENT, or ABSENT        | 400                 |
| `remark`        | Required for MANUAL updates        | 400 REMARK_REQUIRED |
| `remark`        | Max 1000 characters                | 400                 |
| `studentUserId` | Must be enrolled in slot's class   | 400                 |
| `slotId`        | Must be LECTURE or LECTURE_WITH_PT | 400                 |

### 6.5 Error Codes Reference

| Code                          | HTTP | Mô tả                     |
| ----------------------------- | ---- | ------------------------- |
| `ATTENDANCE_RECORD_NOT_FOUND` | 404  | Record không tồn tại      |
| `EDIT_BEFORE_SLOT_START`      | 400  | Chưa đến giờ slot         |
| `EDIT_WINDOW_EXPIRED`         | 400  | Đã quá thời hạn edit      |
| `NOT_ASSIGNED_TO_SLOT`        | 403  | Không phải staff của slot |
| `REMARK_REQUIRED`             | 400  | Manual update cần remark  |
| `INVALID_STATUS_TRANSITION`   | 400  | Không thể chuyển status   |
| `SESSION_ALREADY_RUNNING`     | 400  | Session đang chạy         |
| `SESSION_NOT_RUNNING`         | 400  | Session chưa bắt đầu      |
| `NO_CAMERAS_AVAILABLE`        | 400  | Phòng không có camera     |

---

## 7. Hướng Dẫn Phát Triển

### 7.1 Danh Sách File Quan Trọng

**Backend:**
| # | File | Mô tả |
|---|------|-------|
| 1 | `entity/AttendanceRecord.java` | Main entity |
| 2 | `service/AttendanceRecordService.java` | Business logic |
| 3 | `service/SlotSessionService.java` | Session management |
| 4 | `controller/AttendanceRecordController.java` | REST API |
| 5 | `realtime/SseHub.java` | SSE broadcasting |
| 6 | `dto/realtime/AttendanceUpdateEvent.java` | SSE event format |

**Frontend:**
| # | File | Mô tả |
|---|------|-------|
| 1 | `app/admin/slots/[id]/roster/page.tsx` | Roster page |
| 2 | `components/admin/slots/slot-roster-table.tsx` | Main table |
| 3 | `hooks/api/useSlotRoster.ts` | Roster data |
| 4 | `hooks/api/useSlotSession.ts` | Session mutations |
| 5 | `hooks/realtime/useSlotRosterSSE.ts` | Real-time updates |
| 6 | `hooks/api/useSubmitAttendance.ts` | Batch submit |

### 7.2 So Sánh Regular vs Exam Attendance

| Đặc tính            | Regular Attendance           | Exam Attendance                         |
| ------------------- | ---------------------------- | --------------------------------------- |
| **Table**           | attendance_records           | exam_attendance                         |
| **Slot Types**      | LECTURE, LECTURE_WITH_PT     | LECTURE_WITH_PT, FINAL_EXAM             |
| **Students Source** | Class enrollment             | ExamSlotParticipant                     |
| **callbackType**    | "REGULAR"                    | "EXAM"                                  |
| **Session Fields**  | sessionStatus, scanCount     | examSessionStatus, examScanCount        |
| **RESCAN Override** | No (keep ABSENT)             | Yes (ABSENT → PRESENT for late arrival) |
| **Evidence Table**  | regular_attendance_evidences | exam_attendance_evidences               |

### 7.3 Real-time SSE Integration

**SseHub Event Format:**

```java
public void publishAttendanceUpdate(Integer slotId, AttendanceUpdateEvent payload) {
    Set<SseEmitter> emitters = slotEmitters.get(slotId);
    for (SseEmitter emitter : emitters) {
        SseEmitter.SseEventBuilder event = SseEmitter.event()
            .name("attendance.update")
            .data(payload, MediaType.APPLICATION_JSON);
        emitter.send(event);
    }
}
```

**Frontend SSE Connection:**

```typescript
const eventSource = new EventSource(
  `/api/v1/slots/${slotId}/events?token=${jwt}`
);

eventSource.addEventListener("attendance.update", (event) => {
  const data = JSON.parse(event.data);
  // Update React Query cache...
});
```

### 7.4 FAQ - Câu Hỏi Thường Gặp

**Q: Tại sao NOT_YET không thể revert về được?**

> A: NOT_YET là trạng thái ban đầu, việc revert có thể làm mất dữ liệu điểm danh đã ghi nhận. Nếu cần reset, phải delete và tạo lại record.

**Q: Evidence image lưu ở đâu?**

> A: Python service lưu tại `./uploads/evidence/{slot_id}/{user_id}_{roll_number}.jpg`. URL được trả về trong callback và lưu vào DB.

**Q: Tại sao RESCAN không override ABSENT thành PRESENT?**

> A: Đây là design choice để bảo vệ quyết định của staff. Nếu staff đã mark ABSENT, RESCAN chỉ flag để review, không tự động override.

**Q: Làm sao biết record nào cần review?**

> A: Check `needsReview = true`. Frontend highlight những rows này (red background).

**Q: SSE connection bị mất thì sao?**

> A: Frontend có error handler, hiển thị warning. User cần refresh page để reconnect.

### 7.5 Các Bước Khi Trình Bày Hội Đồng

1. **Giới thiệu module**: Regular Attendance cho LECTURE slots
2. **Demo roster view**: Hiển thị danh sách sinh viên với status
3. **Start session**: Demo face recognition bắt đầu
4. **Real-time updates**: Show SSE events cập nhật UI
5. **Manual update**: Demo click change status với remark
6. **RESCAN mode**: Giải thích logic review flags
7. **Submit all**: Demo batch submission với NOT_YET resolution
8. **Evidence viewer**: Show hình ảnh bằng chứng

### 7.6 Tài Liệu Liên Quan

- [SLOT.md](./SLOT.md) - Slot entity và 3 loại slot
- [EXAM_SLOT.md](./EXAM_SLOT.md) - Exam attendance (khác biệt với Regular)
- [FACE_RECOGNITION.md](./FACE_RECOGNITION.md) - Python Recognition Service
- [STUDENT.md](./STUDENT.md) - Student entity và face embeddings
