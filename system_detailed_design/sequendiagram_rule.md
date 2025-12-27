# **Sequence Diagram Rules - PlantUML (COMET Method)**

Triết lý: Vẽ để THIẾT KẾ (Design), không phải để MÔ TẢ LẠI CODE (Document).

Áp dụng phương pháp COMET (Concurrent Object Modeling and Architectural Design Method) của Hassan Gomaa.

---

## **1. Nguyên Tắc Cốt Lõi**

### **Tư Duy "Logic Flow > Implementation Detail"**

Sequence Diagram dùng để giao tiếp về **Luồng xử lý**, không phải để review code từng dòng.

#### **✅ NÊN (Do)**

- Tập trung thể hiện **Logic nghiệp vụ**: "Validate input", "Check uniqueness", "Save entity"
- Sử dụng **Stereotypes** để phân loại rõ vai trò của từng component
- Thể hiện đầy đủ luồng từ **User → UI → Backend → Database**

#### **❌ KHÔNG NÊN (Don't)**

- Viết câu SQL chi tiết
- Viết chính xác kiểu dữ liệu trả về (`ResponseEntity<Map<String, Object>>`)
- Vẽ quá chi tiết các hàm private/internal

---

## **2. Stereotypes (Phân loại theo COMET)**

### **Bảng Stereotypes chuẩn**

| Stereotype           | Vai trò                                      | Ví dụ trong project   |
| -------------------- | -------------------------------------------- | --------------------- |
| `«user interaction»` | Giao diện người dùng (FE component)          | `:SemesterFormDialog` |
| `«control»`          | Điều phối request, không chứa business logic | `:SemesterController` |
| `«service»`          | Chứa business logic, validation              | `:SemesterService`    |
| `«database wrapper»` | Truy xuất dữ liệu, bao bọc DB operations     | `:SemesterRepository` |
| `«entity»`           | Domain object, thực thể dữ liệu              | `:Semester`           |

### **Cấu trúc Lifelines chuẩn**

```
Actor → «user interaction» → «control» → «service» → «database wrapper» → «entity»
```

### **Lưu ý quan trọng**

- **KHÔNG** có lane `Database` vật lý. `«database wrapper»` (Repository) là đại diện cho việc tương tác với DB.
- **Repository**: Chỉ dùng 1 participant, không tách `CustomRepository`, `RepositoryImpl`.
- **Entity lane**: Chỉ thêm khi có tạo/cập nhật entity (create, update). Với các flow chỉ đọc dữ liệu (view list, view details), không cần Entity lane.

---

## **3. Arrow Types (Loại mũi tên)**

Theo chuẩn UML 2.5 và COMET method:

### **Bảng quy ước mũi tên**

| Loại                  | PlantUML | Đường    | Đầu mũi tên  | Khi nào dùng                            |
| --------------------- | -------- | -------- | ------------ | --------------------------------------- |
| **Synchronous call**  | `->`     | Liền     | Đặc (filled) | Gọi method, HTTP request (đợi response) |
| **Asynchronous call** | `->>`    | Liền     | Hở (open)    | Fire-and-forget, message queue          |
| **Reply message**     | `-->>`   | Đứt đoạn | Hở (open)    | Trả về kết quả, exception               |

### **Ví dụ**

```plantuml
' Synchronous call (đợi response)
Controller -> Service: create(request)

' Reply message
Service -->> Controller: SemesterDTO

' Exception (vẫn là reply)
Service -->> Controller: <<throw>> ValidationException
```

### **Lưu ý**

- Trong context REST API + Spring Boot, hầu hết đều là **synchronous** (`->`)
- **Exception** cũng là reply message, dùng `-->>` với stereotype `<<throw>>`

---

## **4. Template Chuẩn**

Copy đoạn code này làm khung cho mọi sequence diagram:

```plantuml
@startuml [feature_name]
!theme plain
hide footbox

actor [ActorName]

participant "«user interaction»\n:[UIComponent]" as UI
participant "«control»\n:[Controller]" as Controller
participant "«service»\n:[Service]" as Service
participant "«database wrapper»\n:[Repository]" as Repository
participant "«entity»\n:[Entity]" as Entity

' === MAIN FLOW ===
[ActorName] -> UI: [User action]
activate UI

UI -> Controller: [HTTP Method] [Endpoint]
activate Controller

Controller -> Service: [method(params)]
activate Service

' === VALIDATION ===
alt [validation condition]
    Service -->> Controller: <<throw>> [Exception]
    Controller -->> UI: [HTTP Status]
    UI -->> [ActorName]: [Error message]
end

' === DATABASE OPERATIONS ===
Service -> Repository: [query method]
activate Repository
Repository -->> Service: [result]
deactivate Repository

' === CREATE/UPDATE ENTITY ===
Service -> Entity: new [Entity](data)
activate Entity
Entity -->> Service: [entity]
deactivate Entity

Service -> Repository: save([entity])
activate Repository
Repository -->> Service: [savedEntity]
deactivate Repository

' === RESPONSE ===
Service -->> Controller: [DTO]
deactivate Service

Controller -->> UI: [HTTP Status]
deactivate Controller

UI -->> [ActorName]: [Success message]
deactivate UI

@enduml
```

---

## **5. Cấu Trúc Logic**

### **A. Xử Lý Lỗi (Exceptions)**

Sử dụng `alt` với stereotype `<<throw>>`:

```plantuml
alt startDate >= endDate
    Service -->> Controller: <<throw>> InvalidDateException
    Controller -->> UI: 400 Bad Request
    UI -->> [ActorName]: Show error message
end
```

### **B. Điều kiện (Conditional)**

```plantuml
alt [condition A]
    ' Flow A
else [condition B]
    ' Flow B
end
```

### **C. Optional Flow**

```plantuml
opt [condition]
    ' Optional flow
end
```

### **D. Vòng Lặp (Loops)**

Mô tả ý nghĩa nghiệp vụ, không viết cú pháp code:

```plantuml
loop For each Student in Class
    Service -> Repository: updateAttendance(studentId)
end
```

### **E. Group - Khi nào dùng**

**CHỈ DÙNG** khi gom nhiều **external calls** vào một sub-flow logic:

```plantuml
' ✅ ĐÚNG - Gom nhiều external calls
group Token Generation
    Service -> TokenProvider: createAccessToken()
    Service -> TokenProvider: createRefreshToken()
    Service -> RedisCache: storeTokens()
end

' ❌ SAI - Chỉ có self-calls (validation logic)
group Business Rules Validation
    Service -> Service: validate date range
    Service -> Service: check uniqueness
end
```

---

## **6. Quy Trình Vẽ Diagram**

### **Bước 1: Nghiên cứu Frontend**

Scan codebase `frontend-web/` để xác định:

- **Page component**: `app/admin/[feature]/page.tsx`
- **Form/Dialog component**: `components/admin/[feature]/[feature]-form-dialog.tsx`
- **API hooks**: `hooks/api/use[Feature].ts`
- **User interactions**: Click, Submit, Input...

### **Bước 2: Nghiên cứu Backend**

Scan codebase `backend/src/main/java/com/fuacs/backend/` để xác định:

- **Controller**: `controller/[Feature]Controller.java` → Endpoints, HTTP methods
- **Service**: `service/[Feature]Service.java` → Business logic, validation rules
- **Repository**: `repository/[Feature]Repository.java` → Database operations
- **Entity**: `entity/[Feature].java` → Domain model
- **DTOs**: `dto/request/`, `dto/response/` → Request/Response structures

### **Bước 3: Xác định luồng chính**

1. Actor là ai? (Admin, Lecturer, Student...)
2. User action là gì? (Click button, Submit form...)
3. API endpoint nào được gọi?
4. Service method nào xử lý?
5. Validation rules nào cần check?
6. Database operations nào được thực hiện?
7. Response trả về là gì?

### **Bước 4: Vẽ diagram**

1. Tạo file `sequence_diagram_[action]_[feature].puml`
2. Copy template từ section 4
3. Điền thông tin từ bước 1-3
4. Thêm các `alt` blocks cho error handling
5. Review theo checklist section 8

### **Ví dụ quy trình cho Create Semester**

```
1. FE: app/admin/semesters/page.tsx
   → SemesterFormDialog (components/admin/semesters/semester-form-dialog.tsx)
   → useCreateSemester hook

2. BE: SemesterController.create()
   → SemesterService.create()
   → Validations: date range, code unique, name unique, date overlap
   → SemesterRepository.save()
   → Return SemesterDTO

3. Diagram: sequence_diagram_create_semester.puml
```

---

## **7. Ví Dụ Tham Khảo**

Xem các diagram mẫu của module Semester:

| Use Case     | File                                                                   |
| ------------ | ---------------------------------------------------------------------- |
| View List    | `08_create_semester/sequence_diagram_create_semester.puml`             |
| View List    | `05_view_list_semester/sequence_diagram_view_list_semester.puml`       |
| View Details | `06_view_semester_details/sequence_diagram_view_semester_details.puml` |
| Update       | `07_update_semester/sequence_diagram_update_semester.puml`             |
| Delete       | `09_delete_semester/sequence_diagram_delete_semester.puml`             |
| Import CSV   | `10_import_csv_semester/sequence_diagram_import_csv_semester.puml`     |

---

## **8. Checklist Trước Khi Commit**

- [ ] **Flow đầy đủ**: Actor → UI → Controller → Service → Repository → Entity

---

## **9. Quy Tắc Đồng Bộ (Class vs Sequence Consistency)**

### **Nguyên tắc "1-1 Mapping"**

Sequence Diagram và Class Diagram phải nhất quán về các thành phần tham gia (Participants).

1.  **Class Diagram là "Luật"**: Nếu Class Diagram của Feature đó KHÔNG vẽ mối quan hệ với một Repository/Service khác (ví dụ: `ClassService` không có dây nối sang `SubjectRepository`), thì Sequence Diagram cũng **KHÔNG ĐƯỢC** vẽ participant đó.
2.  **Ẩn chi tiết Implementation**:
    - Trong code thực tế, `ClassService` có thể gọi `SubjectRepository` để check tồn tại.
    - Nhưng nếu Class Diagram muốn ẩn chi tiết này (để gọn), Sequence Diagram phải tuân thủ bằng cách dùng **Internal Call**.
3.  **Có trong Class thì phải có trong Sequence**: Nếu Class Diagram vẽ một class/service (ví dụ: `CsvParserService`), thì Sequence Diagram **BẮT BUỘC** phải có participant tương ứng và thể hiện interaction với nó.

### **Ví dụ minh họa**

**Code thực tế:**

```java
class ClassService {
    create() {
        subjectRepo.findById(); // Dependency
        semesterRepo.findById(); // Dependency
        classRepo.save();
    }
}
```

**Class Diagram (Design):**
Chỉ vẽ: `ClassService` --> `ClassRepository`. (Ẩn SubjectRepo/SemesterRepo).

**Sequence Diagram (ĐÚNG):**

```plantuml
' ❌ SAI: Vẽ SubjectRepository tham gia vào flow
' Service -> SubjectRepository: findById()

' ✅ ĐÚNG: Ẩn vào internal call
Service -> Service: validateAndGetReferences(subjectId, semesterId)
note right: Check Subject/Semester existence
Service -> ClassRepository: save()
```
