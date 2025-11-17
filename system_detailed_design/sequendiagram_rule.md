# Quy Tắc Vẽ Sequence Diagram Chuẩn UML

**Document Version:** 1.0
**Last Updated:** 2025-11-17
**Reference Implementation:** [01_sign_in_with_username_and_password/sequence_diagram.puml](01_sign_in_with_username_and_password/sequence_diagram.puml)

---

## Mục Lục

1. [Nguyên Tắc Chung](#nguyên-tắc-chung)
2. [Lifeline (Đường Sống)](#lifeline-đường-sống)
3. [Messages (Thông Điệp)](#messages-thông-điệp)
4. [Reply Messages (Phản Hồi)](#reply-messages-phản-hồi)
5. [Combined Fragments](#combined-fragments)
6. [Exception Handling](#exception-handling)
7. [PlantUML Best Practices](#plantuml-best-practices)
8. [Common Mistakes](#common-mistakes)
9. [Checklist](#checklist)

---

## Nguyên Tắc Chung

### Mục Đích

Sequence diagram tập trung vào **tương tác giữa các thành phần** (interactions), không phải logic nội bộ của từng thành phần.

### Độ Chi Tiết

- **Vẽ:** Interactions giữa các layers (Controller → Service → Repository → Database)
- **KHÔNG vẽ:** Internal implementation details (method private, logic bên trong method)

### Phong Cách

- Ngắn gọn, trực tiếp
- Không over-complicated
- Không có comments dư thừa
- Focus vào main flow và error cases chính

---

## Lifeline (Đường Sống)

### Định Nghĩa

Lifeline đại diện cho một thành phần tham gia (instance) trong tương tác.

### Cú Pháp Chuẩn UML

```
[instanceName] : [ClassName]
```

### Quy Ước Sử Dụng

#### ✅ ĐÚNG: Anonymous Instance (Được khuyến nghị)

```plantuml
participant ":AuthenticationController" as Controller
participant ":AuthenticationService" as Service
participant ":UserRepository" as Repository
participant ":Database" as DB
```

**Giải thích:** Dùng `:[ClassName]` để biểu diễn "một instance bất kỳ" của class đó. Đây là cách phổ biến và đủ rõ ràng cho hầu hết các trường hợp.

#### ✅ ĐÚNG: Named Instance (Khi cần phân biệt)

```plantuml
participant "mainController:CourtController" as MainCtrl
participant "backupController:CourtController" as BackupCtrl
```

**Khi dùng:** Khi có nhiều instances của cùng một class trong cùng một diagram.

#### ❌ SAI: Thiếu dấu hai chấm

```plantuml
participant "AuthenticationController" as Controller
database "PostgreSQL" as DB  // Không nhất quán
```

### Participant Types

| Keyword | Hình Dạng | Khi Dùng |
|---------|-----------|----------|
| `actor` | Hình người | User/external system |
| `participant` | Hình chữ nhật | Classes, Services, Components |
| `database` | Hình cylinder | ❌ TRÁNH: Không nhất quán với participant khác |

**Khuyến nghị:** Dùng `participant` cho tất cả components (kể cả Database) để nhất quán về mặt hình dạng.

---

## Messages (Thông Điệp)

### Nguyên Tắc Đặt Tên

Messages phải mô tả **chính xác hành động hoặc phương thức** được gọi.

### 1. Actor → Controller

#### ✅ ĐÚNG: HTTP method + endpoint

```plantuml
Client -> Controller: POST /api/v1/auth/login\n{username, password}
```

#### ❌ SAI: Mô tả dạng request

```plantuml
Client -> Controller: View court request
Client -> Controller: Login request
```

**Lý do:** Bản thân mũi tên đã là một request, không cần thêm từ "request".

### 2. Controller → Service / Service → Repository

#### ✅ ĐÚNG: Tên method chính xác

```plantuml
Controller -> Service: login(request)
Service -> Repository: findByUsername(username)
Service -> Encoder: matches(password, passwordHash)
```

#### ❌ SAI: Thêm tiền tố thừa

```plantuml
Controller -> Service: Call Login()
Service -> Repository: Call GetUserByUsername()
```

**Lý do:** Mũi tên đồng bộ (solid arrow) đã ngụ ý đây là "lời gọi method". Từ "Call" là thừa.

### 3. Repository → Database

#### ✅ ĐÚNG: SQL query thực tế

```plantuml
Repository -> DB: SELECT * FROM users\nWHERE username = ?
```

#### ✅ ĐÚNG: JPQL (nếu cần thể hiện JPA layer)

```plantuml
Repository -> DB: SELECT u FROM User u\nWHERE u.username = :username
```

#### ❌ SAI: Mô tả tiếng Anh

```plantuml
Repository -> DB: Get list of court
Repository -> DB: Retrieve user data
```

**Lý do:** Database chỉ hiểu query language (SQL/JPQL), không hiểu tiếng Anh. Đây là lỗi logic nghiêm trọng.

**Lưu ý:** Với Spring Data JPA derived query methods (ví dụ: `findByUsername`), nên dùng **SQL native** vì đó là query thực tế được execute ở database level.

---

## Reply Messages (Phản Hồi)

### Nguyên Tắc Đặt Tên

Reply message phải là **giá trị trả về (return value)** hoặc **dữ liệu**, KHÔNG phải hành động hay trạng thái.

### Cú Pháp Chuẩn

```
variableName:Type
```

### Ví Dụ

#### ✅ ĐÚNG: Tên biến và kiểu dữ liệu

```plantuml
DB --> Repository: userRecord
Repository --> Service: userOpt:Optional<User>
Encoder --> Service: isPasswordValid:boolean
TokenProvider --> Service: accessToken:String
Service --> Controller: TokenResponse
```

#### ❌ SAI: Thêm từ "Return"

```plantuml
Repository --> Service: Return Optional<User>
Service --> Controller: Return list of court
```

**Lý do:** Mũi tên nét đứt (dashed arrow) đã có nghĩa là "return". Từ "Return" là thừa.

#### ❌ SAI: Thông báo trạng thái

```plantuml
Repository --> Service: Get list court successful
TokenProvider --> Service: Token created successfully
```

**Lý do:** Việc nhận được phản hồi (thay vì exception) đã ngụ ý sự thành công. Không cần nói lại.

### Special Cases

#### Database Return Values

```plantuml
✅ ĐÚNG: DB --> Repository: userRecord
✅ ĐÚNG: DB --> Repository: resultSet
❌ SAI:  DB --> Repository: User row
```

**Lý do:** "User row" là mô tả tiếng Anh, không phải tên đối tượng dữ liệu.

---

## Combined Fragments

### 1. `alt` (Alternative) - If-Else Logic

#### Ý Nghĩa

Toán tử UML chuẩn cho logic **if-else** (có nhiều nhánh).

#### Cú Pháp

```plantuml
alt [condition1]
    // Path 1
else [condition2]
    // Path 2
else
    // Default path
end
```

#### Ví Dụ

```plantuml
alt userOpt.isEmpty()
    Service -->> Controller: <<throw>> ResourceNotFoundException
    Controller --> Client: HTTP 404
end

alt !isPasswordValid
    Service -->> Controller: <<throw>> BadCredentialsException
    Controller --> Client: HTTP 401
end
```

#### Khi Dùng

- Có **2+ nhánh** logic rõ ràng
- Cần thể hiện **mutually exclusive paths** (chọn 1 trong nhiều)

### 2. `opt` (Optional) - If-Then Logic

#### Ý Nghĩa

Toán tử UML chuẩn cho logic **if-then** (chỉ 1 nhánh, không có else).

#### Cú Pháp

```plantuml
opt [condition]
    // Execute if condition is true
end
```

#### Ví Dụ

```plantuml
opt !user.isActive
    Service -->> Controller: <<throw>> AccessDeniedException
    Controller --> Client: HTTP 403
end
```

#### Khi Dùng

- Chỉ có **1 nhánh** điều kiện
- Nếu điều kiện false → không làm gì, tiếp tục flow bình thường

### 3. Guard Conditions (Điều Kiện Bảo Vệ)

#### Nguyên Tắc Quan Trọng

**Guard condition phải tự nó có ý nghĩa (self-explanatory).**

#### ✅ ĐÚNG: Điều kiện với biến/giá trị rõ ràng

```plantuml
alt userOpt.isEmpty()
opt !user.isActive
alt !isPasswordValid
```

**Giải thích:**

- `userOpt.isEmpty()`: Kiểm tra biến `userOpt` có empty không
- `!user.isActive`: Kiểm tra field `isActive` của object `user`
- `!isPasswordValid`: Kiểm tra biến boolean `isPasswordValid`

#### ❌ SAI: Điều kiện không rõ ràng

```plantuml
alt [== false]
opt [isActive]  // Biến "isActive" chưa được định nghĩa là của ai?
```

**Vấn đề:** "Cái gì" bằng false? Điều kiện này không thể tự giải thích được.

#### ✅ ĐÚNG: Đảm bảo biến đã được định nghĩa

```plantuml
Service -> Encoder: matches(password, passwordHash)
Encoder --> Service: isPasswordValid:boolean

alt !isPasswordValid  // ✅ Biến isPasswordValid đã được return ở trên
    ...
end
```

### 4. Vị Trí Logic Check

#### ❌ SAI: Check trước khi có dữ liệu

```plantuml
alt [list is empty]  // ❌ list chưa tồn tại!
    ...
end

Service -> Repository: getList()
Repository --> Service: list
```

#### ✅ ĐÚNG: Check sau khi nhận dữ liệu

```plantuml
Service -> Repository: getList()
Repository --> Service: list:List<Item>

alt list.isEmpty()  // ✅ list đã được return
    ...
end
```

---

## Exception Handling

### Nguyên Tắc

Exception **không phải** là một thông điệp đồng bộ. Nó là một **sự kiện làm ngắt luồng** (interrupt event).

### ✅ ĐÚNG: Sử dụng stereotype `<<throw>>`

```plantuml
Service -->> Controller: <<throw>> ResourceNotFoundException
Controller --> Client: HTTP 404\n{status, message, code}
```

**Đặc điểm:**

- Dùng **mũi tên nét đứt** (`-->>`) không phải solid arrow (`->`)
- Thêm **stereotype** `<<throw>>`
- Exception name chính xác

### ❌ SAI: Dùng synchronous message

```plantuml
Service -> Controller: throw ResourceNotFoundException
Service --> Controller: Exception occurred
```

**Vấn đề:**

- Mũi tên solid (`->`) ngụ ý method call, không phải exception
- Thiếu stereotype `<<throw>>`

### Kết Hợp Với Fragment

```plantuml
alt userOpt.isEmpty()
    Service -->> Controller: <<throw>> ResourceNotFoundException
    Controller --> Client: HTTP 404\n{status, message, code}
end
```

---

## PlantUML Best Practices

### 1. Theme và Styling

#### Tắt Syntax Highlighting

```plantuml
@startuml
!theme plain
```

**Lý do:** Tránh PlantUML tự động tô màu method calls trong guard conditions (trông như link HTML).

#### Ẩn Footer

```plantuml
@startuml
!theme plain
hide footbox
```

**Lý do:** Actor và participant headers không cần xuất hiện lại ở cuối diagram.

### 2. Complete Template

```plantuml
@startuml Feature Name
!theme plain
hide footbox

actor Client
participant ":Controller" as Ctrl
participant ":Service" as Svc
participant ":Repository" as Repo
participant ":Database" as DB

Client -> Ctrl: someAction()
activate Ctrl

Ctrl -> Svc: processAction()
activate Svc

Svc -> Repo: findData()
activate Repo

Repo -> DB: SELECT * FROM table
activate DB
DB --> Repo: resultSet
deactivate DB

Repo --> Svc: data:Optional<Entity>
deactivate Repo

alt data.isEmpty()
    Svc -->> Ctrl: <<throw>> NotFoundException
    Ctrl --> Client: HTTP 404
end

Svc --> Ctrl: ResponseDTO
deactivate Svc

Ctrl --> Client: HTTP 200 OK\n{data}
deactivate Ctrl

@enduml
```

---

## Common Mistakes

### 1. ❌ Leak Implementation Details

#### SAI - Ví dụ 1: Internal Logic

```plantuml
Service -> TokenProvider: createAccessToken(user, permissions)
activate TokenProvider
TokenProvider -> TokenProvider: build JWT claims
TokenProvider -> TokenProvider: sign with HS256
TokenProvider --> Service: String
deactivate TokenProvider
```

**Vấn đề:** Self-messages `build JWT claims` và `sign with HS256` là internal logic của TokenProvider, không phải interactions.

#### SAI - Ví dụ 2: Validation Logic

```plantuml
Client -> Controller: GET /api/v1/semesters?page=1
activate Controller
Controller -> Controller: validate @Valid SemesterSearchRequest
Controller -> Service: search(request)
```

**Vấn đề:** Validation (`@Valid`) là internal implementation detail được Spring tự động xử lý, không phải interaction giữa các components.

#### ĐÚNG

```plantuml
Service -> TokenProvider: createAccessToken(user, permissions)
activate TokenProvider
TokenProvider --> Service: accessToken:String
deactivate TokenProvider
```

```plantuml
Client -> Controller: GET /api/v1/semesters?page=1
activate Controller
Controller -> Service: search(request)
```

**Giải thích:** Chỉ vẽ interactions giữa các components, không vẽ internal logic hay framework mechanisms.

### 2. ❌ Redundancy: Method Call + Alt Fragment

#### SAI

```plantuml
Service -> Service: validateUserActive(user)

alt !user.isActive
    Service -->> Controller: <<throw>> AccessDeniedException
end
```

**Vấn đề:** Method `validateUserActive` ĐÃ CHỨA logic check và throw exception. Không cần vẽ lại alt fragment.

#### ĐÚNG - Option 1: Chỉ alt fragment

```plantuml
opt !user.isActive
    Service -->> Controller: <<throw>> AccessDeniedException
    Controller --> Client: HTTP 403
end
```

#### ĐÚNG - Option 2: Chỉ method call + note

```plantuml
Service -> Service: validateUserActive(user)
note right: throws AccessDeniedException\nif user is inactive
```

### 3. ❌ Inconsistent Naming

#### SAI

```plantuml
participant ":AuthenticationController" as Controller
participant ":AuthenticationService" as Service
database "PostgreSQL" as DB  // ❌ Không có dấu :, khác type
```

#### ĐÚNG

```plantuml
participant ":AuthenticationController" as Controller
participant ":AuthenticationService" as Service
participant ":Database" as DB  // ✅ Nhất quán
```

### 4. ❌ Vague Return Values

#### SAI

```plantuml
DB --> Repository: User row
Repository --> Service: Optional<User>
Encoder --> Service: boolean
```

#### ĐÚNG

```plantuml
DB --> Repository: userRecord
Repository --> Service: userOpt:Optional<User>
Encoder --> Service: isPasswordValid:boolean
```

### 5. ❌ Wrong Fragment Type

#### SAI: Dùng `alt` cho single-branch condition

```plantuml
alt !user.isActive
    Service -->> Controller: <<throw>> AccessDeniedException
end
```

**Vấn đề:** `alt` ngụ ý có else branch. Nếu không có else, dùng `opt`.

#### ĐÚNG

```plantuml
opt !user.isActive
    Service -->> Controller: <<throw>> AccessDeniedException
end
```

---

## Checklist

### Pre-Drawing Phase

- [ ] Xác định các participants (Controller, Service, Repository, Database)
- [ ] Xác định main flow (success path)
- [ ] Xác định error flows (exception cases)
- [ ] Xác định tên methods chính xác từ source code

### During Drawing

- [ ] Lifelines dùng format `:ClassName`
- [ ] Messages dùng tên method chính xác, không thêm "Call", "Request"
- [ ] Database queries dùng SQL/JPQL thực tế, không dùng mô tả tiếng Anh
- [ ] Reply messages dùng format `variableName:Type`
- [ ] Reply messages không có "Return", "successful"
- [ ] Guard conditions có biến/giá trị cụ thể
- [ ] Logic check xảy ra SAU khi dữ liệu đã available
- [ ] Exceptions dùng `<<throw>>` stereotype với dashed arrow
- [ ] Không vẽ internal implementation details (self-messages cho private logic)
- [ ] Dùng `opt` cho if-then, `alt` cho if-else

### PlantUML Specifics

- [ ] Có `!theme plain` ở đầu file
- [ ] Có `hide footbox` để ẩn footer
- [ ] Participants dùng `participant` type (không dùng `database` để nhất quán)
- [ ] Activate/deactivate đúng thứ tự

### Post-Drawing Review

- [ ] Diagram không over-complicated
- [ ] Tất cả messages đều có ý nghĩa rõ ràng
- [ ] Không có redundancy (method call + fragment làm cùng một việc)
- [ ] Exception flows được handle đúng cách
- [ ] Return values có tên biến cụ thể

---

## File Naming Convention

### Quy Tắc Đặt Tên File

**Format Chuẩn**: `sequence_diagram_[feature_name].puml`

### Nguyên Tắc

1. **Prefix cố định**: Luôn bắt đầu bằng `sequence_diagram_`
2. **Feature name**: Tên chức năng phải match với use case, sử dụng snake_case (lowercase with underscores)
3. **Extension**: Kết thúc bằng `.puml`

### Ví Dụ

#### ✅ ĐÚNG

```
sequence_diagram_sign_in_with_username_and_password.puml
sequence_diagram_sign_in_with_google.puml
sequence_diagram_change_password.puml
sequence_diagram_forgot_password.puml
sequence_diagram_reset_password.puml
sequence_diagram_view_list_semester.puml
```

#### ❌ SAI

```
sequence_diagram.puml                    // Thiếu feature name
seq_diagram_login.puml                   // Sai prefix
SequenceDiagramLogin.puml                // Sai naming style (PascalCase)
login_sequence_diagram.puml              // Sai thứ tự
sequence-diagram-login.puml              // Sai delimiter (dùng - thay vì _)
```

### Lợi Ích

- **Dễ tìm kiếm**: Tất cả sequence diagrams được group lại khi sort alphabetically
- **Consistency**: Format thống nhất trong toàn bộ dự án
- **Self-documenting**: Tên file đã mô tả rõ nội dung
- **Tool-friendly**: Dễ dàng cho automation scripts và build tools

---

## Reference

### Completed Example

Xem file: [01_sign_in_with_username_and_password/sequence_diagram_sign_in_with_username_and_password.puml](01_sign_in_with_username_and_password/sequence_diagram_sign_in_with_username_and_password.puml)

### UML Specification

- [UML 2.5 Specification - Sequence Diagrams](https://www.omg.org/spec/UML/2.5/)

### PlantUML Documentation

- [PlantUML Sequence Diagram](https://plantuml.com/sequence-diagram)
- [PlantUML Themes](https://plantuml.com/theme)

---

**Document End**
