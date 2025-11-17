# Class Diagram Rules - PlantUML

## Mục Lục

1. [Nguyên Tắc Chung](#nguyên-tắc-chung)
2. [Cấu Trúc Class](#cấu-trúc-class)
3. [Nguyên Tắc Encapsulation](#nguyên-tắc-encapsulation)
4. [Các Loại Quan Hệ](#các-loại-quan-hệ)
5. [Biểu Diễn Interface](#biểu-diễn-interface)
6. [PlantUML Best Practices](#plantuml-best-practices)
7. [Common Mistakes](#common-mistakes)
8. [Hướng Dẫn Cho Spring Framework](#hướng-dẫn-cho-spring-framework)
9. [Ví Dụ Hoàn Chỉnh](#ví-dụ-hoàn-chỉnh)
10. [Checklist](#checklist)
11. [References](#references)

---

## Nguyên Tắc Chung

### Mục Đích

Class diagram tập trung vào **cấu trúc tĩnh** của hệ thống: classes, attributes, methods, và relationships giữa chúng.

### Độ Chi Tiết

- **Vẽ:** Các class chính, fields quan trọng, public methods, relationships
- **KHÔNG vẽ:** Tất cả getters/setters, implementation details quá chi tiết

### Encapsulation

**NGUYÊN TẮC VÀNG**: Fields PHẢI là private (`-`), methods public interface là public (`+`).

### Phong Cách

- Rõ ràng, dễ đọc
- Tuân thủ chuẩn UML
- Sử dụng text symbols cho visibility, không dùng hình học
- Tránh layout thủ công, để PlantUML tự động xử lý

---

## Cấu Trúc Class

### 1. Ba Compartments (Ngăn)

Mỗi class có 3 phần:

1. **Tên Class** (trên cùng)
2. **Attributes/Fields** (giữa)
3. **Methods/Operations** (dưới cùng)

```plantuml
class ClassName {
  - field1 : Type
  - field2 : Type
  + method1(param : Type) : ReturnType
  + method2() : void
}
```

### 2. Visibility Modifiers

| Ký Hiệu | Ý Nghĩa | Khi Dùng |
|---------|---------|----------|
| `+` | Public | Methods của public interface |
| `-` | Private | Fields, helper methods |
| `#` | Protected | Kế thừa trong cùng package |
| `~` | Package/Default | Package-private access |

### 3. Sử Dụng Text Symbols

**QUAN TRỌNG**: Luôn dùng **text symbols** (`+`, `-`, `#`, `~`), KHÔNG dùng hình học (ô vuông, ô tròn).

Để đảm bảo text symbols trong PlantUML:

```plantuml
skinparam classAttributeIconSize 0
```

---

## Nguyên Tắc Encapsulation

### Quy Tắc 1: Fields Phải Private

**TẤT CẢ fields/attributes PHẢI là private (`-`) trừ khi có lý do đặc biệt.**

#### ✅ ĐÚNG

```plantuml
class User {
  - id : Integer
  - username : String
  - passwordHash : String
}
```

#### ❌ SAI: Public Fields

```plantuml
class User {
  + id : Integer          ' SAI - fields không được public
  + username : String     ' SAI
}
```

**Lý do:** Vi phạm nguyên tắc encapsulation. Fields phải được ẩn và chỉ truy cập qua methods.

### Quy Tắc 2: Methods Có Thể Public

Methods thuộc public interface của class nên dùng `+`.

Helper methods nội bộ nên dùng `-`.

```plantuml
class AuthenticationService {
  - userRepository : UserRepository
  + login(request : LoginRequest) : TokenResponse
  - buildTokenResponse(user : User) : TokenResponse
  - validateUserActive(user : User) : void
}
```

---

## Các Loại Quan Hệ

### 1. Association (Nét Liền Với Mũi Tên `-->`)

#### Khi Dùng

Quan hệ **bền vững**, được biểu diễn bằng **instance field**.

#### Ý Nghĩa

Class A "có một" hoặc "biết về" Class B dưới dạng field/member variable.

#### Ví Dụ

```plantuml
class AuthenticationController {
  - authenticationService : AuthenticationService
}

AuthenticationController --> AuthenticationService
```

#### Khi Nào Dùng

- Khi một class có class khác làm **field/member variable**
- Quan hệ tồn tại suốt vòng đời của object
- Dependency injection (Spring `@Autowired`, constructor injection)

---

### 2. Dependency (Nét Đứt Với Mũi Tên `..>`)

#### Khi Dùng

Quan hệ **tạm thời**, method parameters, return types, hoặc local variables.

#### Ý Nghĩa

Class A "sử dụng" hoặc "phụ thuộc vào" Class B một cách tạm thời.

#### Ví Dụ

```plantuml
class AuthenticationController {
  + login(request : LoginRequest) : ResponseEntity<TokenResponse>
}

AuthenticationController ..> LoginRequest : <<use>>
AuthenticationController ..> TokenResponse : <<use>>
```

#### Khi Nào Dùng

- Method **parameters**
- Method **return types**
- Local variables trong methods
- Sử dụng tạm thời, không lưu trữ làm fields

---

### 3. Composition (Nét Liền Với Kim Cương Đặc `*--`)

#### Khi Dùng

Quan hệ sở hữu mạnh, "part-of" relationship.

#### Ý Nghĩa

Class A sở hữu Class B. Nếu A bị hủy, B cũng bị hủy.

#### Ví Dụ

```plantuml
class User {
  - roles : Set<Role>
}

User *-- Role
```

#### Khi Nào Dùng

- Phụ thuộc vòng đời mạnh
- Phần không thể tồn tại mà không có tổng thể
- Quan hệ entity trong domain models

---

### 4. Aggregation (Nét Liền Với Kim Cương Rỗng `o--`)

#### Khi Dùng

Quan hệ sở hữu yếu, "has-a" relationship.

#### Ý Nghĩa

Class A chứa Class B, nhưng B có thể tồn tại độc lập.

#### Khi Nào Dùng (hiếm trong Spring applications)

- Sở hữu chia sẻ
- Phần có thể tồn tại mà không cần tổng thể

---

### 5. Realization/Implementation (Nét Đứt Với Tam Giác Rỗng `<|..`)

#### Khi Dùng

Interface implementation.

#### Ví Dụ

```plantuml
interface UserRepository <<interface>>
class UserRepositoryImpl

UserRepository <|.. UserRepositoryImpl
```

#### Lưu Ý Về Spring

- Spring Data JPA repositories (extends `JpaRepository`) được **auto-implemented** bởi Spring tại runtime
- Không cần vẽ explicit implementation classes cho Spring Data repositories
- Tập trung vào việc hiển thị interface và các relationships của nó

---

### 6. Inheritance/Generalization (Nét Liền Với Tam Giác Rỗng `<|--`)

#### Khi Dùng

Kế thừa class (extends).

#### Ví Dụ

```plantuml
class Animal
class Dog

Animal <|-- Dog
```

---

## Tổng Hợp So Sánh

| Loại Quan Hệ | Ký Hiệu | Khi Dùng | Ví Dụ |
|---------------|---------|----------|-------|
| **Association** | `-->` | Instance field | Controller có Service field |
| **Dependency** | `..>` | Parameter, return type | Controller dùng DTO |
| **Composition** | `*--` | Strong ownership | User có Roles |
| **Aggregation** | `o--` | Weak ownership | Hiếm dùng |
| **Realization** | `<\|..` | Implements interface | Class impl Interface |
| **Inheritance** | `<\|--` | Extends class | Dog extends Animal |

---

## Biểu Diễn Interface

### Khai Báo Interface Đúng Cách

```plantuml
interface InterfaceName <<interface>> {
  + method1(param : Type) : ReturnType
  + method2() : void
}
```

### Lưu Ý

- Interfaces KHÔNG nên có fields (hoặc tất cả fields là constants)
- Tất cả methods ngầm định là public
- Sử dụng stereotype `<<interface>>`

### Ẩn Ký Tự C, I

PlantUML có thể thêm ký tự C (class), I (interface) vào headers. Để loại bỏ chúng mà vẫn giữ tên:

```plantuml
hide circle
skinparam circledCharacterRadius 0
```

**QUAN TRỌNG**: KHÔNG chỉ dùng `hide circle` vì nó sẽ ẩn cả tên interface. Luôn kết hợp với `skinparam circledCharacterRadius 0`.

---

## PlantUML Best Practices

### 1. Essential Directives

```plantuml
@startuml ClassName - Class Diagram
!theme plain
skinparam classAttributeIconSize 0
hide circle
skinparam circledCharacterRadius 0

' Your classes and relationships here

@enduml
```

### 2. Styling Guidelines

- Dùng `!theme plain` cho giao diện sạch, chuyên nghiệp
- Đặt `skinparam classAttributeIconSize 0` để dùng text symbols cho visibility
- Dùng `hide circle` + `skinparam circledCharacterRadius 0` để loại bỏ ký tự C/I

### 3. Layout Considerations

- **Tránh** dùng `left to right direction` trừ khi thực sự cần
- Layout mặc định của PlantUML thường là tối ưu nhất
- Manual layout tweaks thường làm diagram xấu đi
- Để PlantUML tự động xử lý positioning

---

## Common Mistakes

### ❌ Lỗi 1: Public Fields

```plantuml
class User {
  + id : Integer          ' SAI - fields phải private
  + username : String     ' SAI
}
```

### ✅ Đúng

```plantuml
class User {
  - id : Integer          ' ĐÚNG - private fields
  - username : String     ' ĐÚNG
}
```

**Giải thích:** Tất cả fields phải private để tuân thủ encapsulation.

---

### ❌ Lỗi 2: Dùng Sai Loại Quan Hệ

```plantuml
class AuthenticationController {
  + login(request : LoginRequest) : ResponseEntity<TokenResponse>
}

' SAI - LoginRequest là parameter, không phải field
AuthenticationController --> LoginRequest
```

### ✅ Đúng

```plantuml
' ĐÚNG - Dùng Dependency cho parameters/return types
AuthenticationController ..> LoginRequest : <<use>>
AuthenticationController ..> TokenResponse : <<use>>
```

**Giải thích:**

- Association (`-->`) chỉ dùng cho **fields**
- Dependency (`..>`) dùng cho **parameters và return types**

---

### ❌ Lỗi 3: Thiếu Visibility Modifiers

```plantuml
class User {
  id : Integer            ' SAI - không có visibility modifier
  username : String       ' SAI
}
```

### ✅ Đúng

```plantuml
class User {
  - id : Integer          ' ĐÚNG - visibility rõ ràng
  - username : String     ' ĐÚNG
}
```

---

### ❌ Lỗi 4: Realization Không Cần Thiết Cho Spring Data

```plantuml
interface UserRepository <<interface>>
class UserRepositoryImpl

UserRepository <|.. UserRepositoryImpl    ' KHÔNG CẦN cho Spring Data JPA
```

### ✅ Đúng

```plantuml
' Chỉ cần hiển thị interface - Spring tự động implement
interface UserRepository <<interface>> {
  + findByUsername(username : String) : Optional<User>
}
```

**Giải thích:** Spring Data JPA tự động tạo implementation tại runtime. Không cần vẽ implementation class.

---

### ❌ Lỗi 5: Chỉ Dùng `hide circle`

```plantuml
hide circle    ' Điều này sẽ ẩn cả tên interface!
```

### ✅ Đúng

```plantuml
hide circle
skinparam circledCharacterRadius 0    ' Giữ tên vẫn hiển thị
```

**Giải thích:** `hide circle` đơn thuần sẽ ẩn cả tên. Phải kết hợp với `skinparam circledCharacterRadius 0`.

---

## Hướng Dẫn Cho Spring Framework

### 1. Dependency Injection

Khi một class sử dụng Spring dependency injection (qua `@Autowired`, constructor injection, v.v.), hiển thị nó như **Association** (mũi tên nét liền):

```plantuml
class AuthenticationController {
  - authenticationService : AuthenticationService
}

AuthenticationController --> AuthenticationService
```

**Lý do:** Injected dependency là một **field** của class, không phải temporary usage.

### 2. Spring Data JPA Repositories

- Hiển thị repositories dưới dạng **interfaces**
- Không cần hiển thị implementation classes
- Sử dụng stereotype `<<interface>>`
- Methods có thể là derived query methods

```plantuml
interface UserRepository <<interface>> {
  + findByUsername(username : String) : Optional<User>
  + findByEmail(email : String) : Optional<User>
}
```

### 3. DTOs (Data Transfer Objects)

- DTOs thường chỉ có private fields
- Có thể có getters/setters (có thể bỏ qua trong diagram cho ngắn gọn)
- Dùng quan hệ **Dependency** với controllers/services

```plantuml
class LoginRequest {
  - username : String
  - password : String
}

AuthenticationController ..> LoginRequest : <<use>>
```

**Lý do:** DTOs được truyền vào như parameters, không lưu trữ làm fields.

---

## Ví Dụ Hoàn Chỉnh

Xem diagram tham khảo:
[01_sign_in_with_username_and_password/class_diagram_sign_in_with_username_and_password.puml](01_sign_in_with_username_and_password/class_diagram_sign_in_with_username_and_password.puml)

### Các Điểm Quan Trọng

- Tất cả fields đều private (`-`)
- Public methods dùng `+`, private helper methods dùng `-`
- Association (`-->`) cho injected dependencies
- Dependency (`..>`) cho method parameters/return types
- Composition (`*--`) cho entity relationships
- Interface representation đúng cách với `<<interface>>`
- Styling sạch với các skinparams cần thiết

---

## Checklist

### Pre-Drawing Phase

- [ ] Xác định các classes chính trong feature
- [ ] Xác định fields quan trọng của mỗi class
- [ ] Xác định public methods của mỗi class
- [ ] Xác định relationships giữa các classes

### During Drawing

- [ ] Tất cả fields dùng visibility modifiers (ưu tiên `-` cho private)
- [ ] Methods có visibility phù hợp (`+` cho public, `-` cho private)
- [ ] Association (`-->`) dùng cho fields/member variables
- [ ] Dependency (`..>`) dùng cho parameters/return types
- [ ] Composition (`*--`) dùng cho strong ownership (entities)
- [ ] Interfaces được khai báo với stereotype `<<interface>>`
- [ ] Không có public fields (trừ constants)
- [ ] Không vẽ tất cả getters/setters (giữ diagram ngắn gọn)

### PlantUML Specifics

- [ ] Có `!theme plain` ở đầu file
- [ ] Có `skinparam classAttributeIconSize 0`
- [ ] Có `hide circle`
- [ ] Có `skinparam circledCharacterRadius 0`
- [ ] Không dùng manual layout directives trừ khi cần thiết

### Post-Drawing Review

- [ ] Visibility symbols hiển thị dưới dạng text (`+`, `-`) không phải shapes
- [ ] Tên class/interface hiển thị (ký tự C, I đã bị loại bỏ)
- [ ] Relationships phản ánh chính xác code structure
- [ ] Không có implementation classes không cần thiết cho Spring Data repositories
- [ ] DTOs chỉ hiển thị private fields
- [ ] Diagram rõ ràng, dễ đọc, không quá phức tạp

---

## File Naming Convention

### Quy Tắc Đặt Tên File

**Format Chuẩn**: `class_diagram_[feature_name].puml`

### Nguyên Tắc

1. **Prefix cố định**: Luôn bắt đầu bằng `class_diagram_`
2. **Feature name**: Tên chức năng phải match với use case, sử dụng snake_case (lowercase with underscores)
3. **Extension**: Kết thúc bằng `.puml`

### Ví Dụ

#### ✅ ĐÚNG

```
class_diagram_sign_in_with_username_and_password.puml
class_diagram_sign_in_with_google.puml
class_diagram_change_password.puml
class_diagram_forgot_password.puml
class_diagram_view_list_semester.puml
```

#### ❌ SAI

```
class_diagram.puml                       // Thiếu feature name
cls_diagram_login.puml                   // Sai prefix
ClassDiagramLogin.puml                   // Sai naming style (PascalCase)
login_class_diagram.puml                 // Sai thứ tự
class-diagram-login.puml                 // Sai delimiter (dùng - thay vì _)
class_diagram_login.puml.puml            // Double extension
```

### Lợi Ích

- **Dễ tìm kiếm**: Tất cả class diagrams được group lại khi sort alphabetically
- **Consistency**: Format thống nhất trong toàn bộ dự án
- **Self-documenting**: Tên file đã mô tả rõ nội dung
- **Pair với Sequence Diagram**: Dễ dàng tìm cặp class/sequence diagram của cùng một feature

---

## References

### UML Specification

- [UML 2.5 Specification - Class Diagrams](https://www.omg.org/spec/UML/2.5/)

### PlantUML Documentation

- [PlantUML Class Diagram](https://plantuml.com/class-diagram)
- [PlantUML Themes](https://plantuml.com/theme)

### Related Documents

- [sequendiagram_rule.md](sequendiagram_rule.md) - Quy tắc vẽ Sequence Diagram

---

**Document End**
