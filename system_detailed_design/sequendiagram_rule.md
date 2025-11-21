# **Sequence Diagram Rules - PlantUML (Logical Style)**

Triết lý: Vẽ để THIẾT KẾ (Design), không phải để MÔ TẢ LẠI CODE (Document).

Nếu biểu đồ chứa quá nhiều chi tiết kỹ thuật mà Business không hiểu -> XÓA BỎ CHI TIẾT ĐÓ.

## **1. Quick Start (Template Chuẩn)**

Copy đoạn code này vào đầu mọi file .puml. Đây là style "Phác thảo Logic" (Draw.io style), tập trung vào luồng đi của dữ liệu hơn là cú pháp code.

1.  @startuml [Feature_Name]
2.  !theme plain
3.  hide footbox
4.
5.  actor Client
6.  participant ":Controller" as Ctrl
7.  participant ":Service" as Svc
8.  participant ":Repository" as Repo
9.  ' Dùng participant cho DB để đồng bộ hình dạng (hình chữ nhật)
10. participant "Database" as DB
11.
12. ' --- MAIN FLOW ---
13. Client -> Ctrl: POST /api/resource
14. activate Ctrl
15.
16. Ctrl -> Svc: process(request)
17. activate Svc
18.
19. Svc -> Repo: findData()
20. activate Repo
21.
22.     ' Database interaction: Mô tả logic, không cần SQL phức tạp
23.     Repo -> DB: Query Data by ID
24.     activate DB
25.     DB --> Repo: Record / Null
26.     deactivate DB
27.
28. Repo --> Svc: Optional<Data>
29. deactivate Repo
30.
31. ' --- LOGIC BRANCHES ---
32. alt data not found
33.     Svc -->> Ctrl: <<throw>> NotFoundException
34.     Ctrl --> Client: 404 Not Found
35. end
36.
37. ' --- INTERNAL LOGIC GROUPING ---
38. group Complex Calculation
39.     Svc -> Svc: validate logic
40.     Svc -> Svc: transform data
41. end
42.
43. Svc --> Ctrl: Response
44. deactivate Svc
45.
46. Ctrl --> Client: 200 OK
47. deactivate Ctrl
48.
49. @enduml

## **2. Nguyên Tắc Cốt Lõi (Core Principles)**

### **Tư Duy "Logic Flow > Implementation Detail"**

Sequence Diagram dùng để giao tiếp về **Luồng xử lý**, không phải để review code từng dòng.

#### **✅ NÊN (Do)**

- Tập trung thể hiện **Logic**: "Lấy user từ DB", "Kiểm tra mật khẩu", "Tạo Token".
- Sử dụng ngôn ngữ tự nhiên (Natural Language) cho các bước tương tác hạ tầng (Database, External API).
- Dùng **Group** để gom các bước xử lý nội bộ phức tạp.

#### **❌ KHÔNG NÊN (Don't)**

- Viết câu SQL dài dòng (SELECT \* FROM ... JOIN ...).
- Viết chính xác kiểu dữ liệu trả về (ResponseEntity<Map<String, Object>>). Chỉ cần ghi 200 OK hoặc Response.
- Vẽ quá chi tiết các hàm private nhỏ nhặt (Self-calls rối rắm).

## **3. Thành Phần Tham Gia (Participants)**

### **Đồng Bộ Hình Dạng (Consistency)**

Để biểu đồ nhìn "sạch" và giống bản vẽ tay logic (Draw.io style), chúng ta thống nhất hình dạng.

| Thành phần     | Keyword PlantUML | Hình dạng    | Ghi chú                                                                      |
| :------------- | :--------------- | :----------- | :--------------------------------------------------------------------------- |
| **User**       | actor            | Người        | Người dùng hoặc hệ thống ngoài.                                              |
| **Code Class** | participant      | Chữ nhật     | Controller, Service, Repo, Utils.                                            |
| **Database**   | participant      | **Chữ nhật** | **QUAN TRỌNG:** Không dùng database (hình trụ). Đặt tên chung là "Database". |

#### **Ví dụ chuẩn:**

participant ":AuthenticationService" as Service
participant "Database" as DB

### **Đơn Giản Hóa Repository (Repository Simplification) - QUAN TRỌNG**

Ở mức High-Level Design, **không cần vẽ** chi tiết implementation pattern của Repository.

#### **✅ NÊN (Do) - Gọn gàng**

Chỉ vẽ 1 participant đại diện cho toàn bộ Data Access Layer:

```
participant ":SemesterRepository" as Repository
```

Trong code có thể có: `JpaRepository`, `CustomSemesterRepository`, `SemesterRepositoryImpl` → **Nhưng trong diagram chỉ cần 1 Repository**.

#### **❌ KHÔNG NÊN (Don't) - Rối rắm**

```
participant ":SemesterRepository" as Repo1
participant ":CustomSemesterRepository" as Repo2
participant ":SemesterRepositoryImpl" as Impl
```

#### **Lý do:**

- Architect chỉ quan tâm **Repository có khả năng gì** (search, count, save...).
- **Không quan tâm** việc code implement bằng Spring Data JPA pattern hay custom query.
- Tách interface là **implementation detail**, không phải **design decision**.

#### **Ví dụ thực tế:**

**❌ SAI (quá chi tiết):**
```
Service -> JpaRepository: findById(id)
Service -> CustomRepository: search(request)
Service -> CustomRepository: count(request)
```

**✅ ĐÚNG (đơn giản):**
```
Service -> Repository: findById(id)
Service -> Repository: search(request)
Service -> Repository: count(request)
```

## **4. Thông Điệp & Tương Tác (Messages)**

### **A. Code Interaction (Controller -> Service -> Repo)**

Giữ nguyên tên method nếu ngắn gọn.

- **Call:** Service -> Repository: findByUsername(username)
- **Return:** Repository --> Service: User Record (hoặc Optional<User>)

### **B. Database Interaction (Repo -> DB)**

Ưu tiên mô tả hành động logic.

- **✅ ĐÚNG:**

52. Repo -> DB: Query User by Username
53. DB --> Repo: User Record

-
- **❌ SAI (Quá kỹ thuật/Rối):**

54. Repo -> DB: SELECT u.\* FROM users u WHERE u.username = ?
55. DB --> Repo: ResultSet row 1

-

### **C. Return Values**

Không cần đúng cú pháp Java, chỉ cần người đọc hiểu trả về cái gì.

- **✅ ĐÚNG:** Token, User Info, True/False, 200 OK
- **❌ SAI:** ResponseEntity<TokenResponse>, java.lang.Boolean

## **5. Cấu Trúc Logic (Logic Structures)**

### **A. Xử Lý Lỗi (Exceptions)**

Sử dụng alt hoặc opt kết hợp với stereotype <<throw>>.

56. alt User not found
57.     Service -->> Controller: <<throw>> ResourceNotFoundException
58.     Controller --> Client: 404 Not Found
59. end

### **B. Logic Nội Bộ (Grouping) - QUAN TRỌNG**

#### **KHI NÀO DÙNG `group`**

Dùng `group` **CHỈ KHI** gom nhiều external interactions (calls to other services/components) vào một sub-flow logic.

**✅ NÊN (Do) - Có nhiều external calls:**

```puml
group Token Generation
    Service -> TokenProvider: createAccessToken()
    Service -> TokenProvider: createRefreshToken()
    Service -> RedisCache: storeTokens()
end
```

**Lý do:** Gom 3 external calls (TokenProvider x2, RedisCache) thành 1 logical unit.

---

#### **KHI NÀO KHÔNG DÙNG `group`**

**❌ KHÔNG NÊN (Don't) - Chỉ có self-calls:**

```puml
' SAI: Vẽ implementation details
group Business Rules Validation
    Service -> Service: validate date range
    Service -> Service: check code uniqueness
    Service -> Service: check name uniqueness
    Service -> Service: check date overlap
end
```

**Lý do:** Đây là **implementation detail** (code nội bộ), không phải design decision. Architect chỉ quan tâm "Service validate business rules", không quan tâm validate bao nhiêu rules.

**✅ ĐÚNG - Bỏ group, dùng comment hoặc note:**

```puml
' Validation logic (internal)

alt Validation failed
    Service -->> Controller: <<throw>> ValidationException
    Controller --> Client: 400 Bad Request
end
```

**HOẶC nếu cần làm rõ:**

```puml
note right of Service
    Validate business rules:
    date range, uniqueness, overlap
end note

alt Validation failed
    Service -->> Controller: <<throw>> ValidationException
end
```

---

#### **So Sánh: Khi Nào Dùng vs Không Dùng**

| Tình huống | Dùng `group`? | Lý do |
|------------|---------------|-------|
| **Multiple external calls** (Service → Provider, Cache, Queue) | ✅ CÓ | Gom sub-flow logic với external dependencies |
| **Self-calls validation** (Service → Service x5) | ❌ KHÔNG | Implementation detail, không phải design |
| **Single operation** (Service → Service: applyChanges) | ❌ KHÔNG | Thừa, chỉ là step trước save() |
| **Loop with external calls** | ✅ CÓ (dùng `loop`) | Cần thể hiện iteration pattern |
| **Conditional logic** | ❌ KHÔNG (dùng `alt`/`opt`) | Đã có cấu trúc branching rồi |

---

#### **Ví Dụ Thực Tế: Update Semester**

**❌ SAI (Over-engineering):**

```puml
group Business Rules Validation
    Service -> Service: validate date range (start < end)
    Service -> Service: check code uniqueness (if changed)
    Service -> Service: check name uniqueness (if changed)
    Service -> Service: check date overlap (if changed)
end

alt Validation failed
    Service -->> Controller: <<throw>> ValidationException
end

group Update Semester
    Service -> Service: apply changes to semester entity
end

Service -> Repository: save(semester)
```

**✅ ĐÚNG (High-level design):**

```puml
' Validation logic (internal)

alt Validation failed
    Service -->> Controller: <<throw>> ValidationException
    Controller --> Client: 400 Bad Request
end

Service -> Repository: save(semester)
activate Repository
Repository -> DB: Update Semester
...
```

**Giải thích:**
- Bỏ `group Business Rules Validation` → chỉ giữ `alt` cho error handling
- Bỏ `group Update Semester` → thừa, giống như save() bên dưới
- Kết quả: Gọn gàng, focus vào design flow, không rối bởi implementation details

---

### **C. Vòng Lặp (Loops) - MỚI**

Đừng bê nguyên vòng for/while của code vào. Hãy mô tả ý nghĩa của việc lặp.

#### **✅ NÊN (Do)**

64. loop For each Student in Class
65.     Service -> Repository: calculateGPA(studentId)
66. end

#### **❌ KHÔNG NÊN (Don't)**

- Ghi cú pháp code: loop for (int i = 0; i < students.size(); i++).

## **6. Checklist Trước Khi Commit**

1. [ ] **Visual:** Database có phải là hình chữ nhật (participant) không? (Không dùng hình trụ).
2. [ ] **Flow:** Database query có dễ đọc không? (Tránh SQL dài).
3. [ ] **Repository:** Chỉ có 1 Repository participant chưa? Đã gộp Custom + Impl vào 1 participant chưa?
4. [ ] **Group Usage:** `group` chỉ dùng cho external calls, KHÔNG dùng cho self-calls validation hay single operations.
5. [ ] **Over-Engineering:** Đã bỏ các `group` cho validation logic (Service -> Service) chưa? Chỉ giữ `alt`/`opt` cho branching.
6. [ ] **Logic:** Vòng lặp (loop) có mô tả nghiệp vụ thay vì cú pháp code không?
7. [ ] **Naming:** Tên file có đúng format sequence_diagram\_[feature].puml không?
