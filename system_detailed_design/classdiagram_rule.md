# **Class Diagram Rules - PlantUML (Architectural Standard)**

Triết lý: Vẽ để THIẾT KẾ (Design), không phải để MÔ TẢ LẠI CODE (Document).

Nếu biểu đồ chứa quá nhiều chi tiết kỹ thuật mà Business không hiểu -> XÓA BỎ CHI TIẾT ĐÓ.

## **1. Quick Start (Template Chuẩn)**

Copy đoạn code này vào đầu mọi file .puml.

```puml
@startuml [Feature_Name]
!theme plain
hide circle
skinparam classAttributeIconSize 0

' --- CẤU HÌNH "ORTHO" (BẮT BUỘC) ---
skinparam linetype ortho
skinparam nodesep 60
skinparam ranksep 60

' --- SAMPLE LAYOUT HINT ---
' Controller -down-> Service
' Service -down-> Repository
' Repository .down.> Entity

@enduml
```

## **2. Nguyên Tắc Cốt Lõi (Core Principles)**

### **A. Luật "Tứ Trụ" (The Four Pillars) - QUAN TRỌNG**

Biểu đồ Class **CHỈ ĐƯỢC PHÉP** chứa 4 loại component sau đây. Mọi thứ khác đều là nhiễu.

#### **✅ ĐƯỢC VẼ (Allowed)**

1. **Controller:** Đầu mối tiếp nhận request.
   - _Hiển thị:_ Public methods (create, update...).
2. **Service:** Chứa logic nghiệp vụ.
   - _Hiển thị:_ Business methods.
3. **Repository:** Giao tiếp dữ liệu.
   - _Hiển thị:_ Query methods được dùng trong Use Case.
4. **Entity:** Dữ liệu cốt lõi.
   - _Hiển thị:_ Fields quan trọng.

#### **❌ KHÔNG VẼ (Forbidden)**

- **Utility / Helpers** (PasswordEncoder, DateUtils...): Bỏ qua.
- **Mappers** (UserMapper...): Bỏ qua.
- **DTOs** (Request/Response): Tuyệt đối không vẽ.
- **Configuration / Constants**: Bỏ qua.

### **B. Luật "Trừu Tượng Hóa Kiểu Dữ Liệu" (Type Abstraction)**

Design quan tâm đến cấu trúc dữ liệu trừu tượng, không quan tâm implementation.

#### **✅ NÊN (Do)**

- Dùng Interface cho Collection: List<User>, Set<Role>, Map.
- Dùng kiểu chung chung: String, Integer, Date.

#### **❌ KHÔNG NÊN (Don't)**

- Ghi class cụ thể: ArrayList, HashSet, java.sql.Timestamp.

### **C. Luật "Đơn Giản Hóa Repository" (Repository Simplification) - QUAN TRỌNG**

Ở mức High-Level Design, **không cần vẽ** chi tiết implementation pattern của Repository.

#### **✅ NÊN (Do) - Gọn gàng**

Chỉ vẽ 1 interface đại diện cho toàn bộ Data Access Layer:

```puml
interface SemesterRepository <<interface>> {
  + findById(id) : Optional<Semester>
  + save(semester) : Semester
  + search(request) : List<Semester>
  + count(request) : Long
}
```

Trong code có thể có: `JpaRepository`, `CustomSemesterRepository`, `SemesterRepositoryImpl` → **Nhưng trong diagram chỉ cần 1 Repository interface**.

#### **❌ KHÔNG NÊN (Don't) - Rối rắm**

```puml
interface SemesterRepository <<interface>> {
  + findById(id) : Optional<Semester>
  + save(semester) : Semester
}

interface CustomSemesterRepository <<interface>> {
  + search(request) : List<Semester>
  + count(request) : Long
}

class SemesterRepositoryImpl {
  - entityManager : EntityManager
  + search(request) : List<Semester>
  + count(request) : Long
}
```

#### **Lý do:**

- Architect chỉ quan tâm **Repository có khả năng gì** (search, count, save...).
- **Không quan tâm** việc code implement bằng Spring Data JPA pattern hay custom query.
- Tách interface là **implementation detail**, không phải **design decision**.
- Vẽ nhiều Repository gây rối, làm mất focus vào business logic.

#### **Ví dụ thực tế:**

**❌ SAI (3 components cho 1 Data Access Layer):**
```
Service --> JpaRepository
Service --> CustomRepository
CustomRepository <|.. RepositoryImpl
```

**✅ ĐÚNG (1 component, clean & clear):**
```
Service --> Repository
Repository ..> Entity
```

## **3. Layout & Thẩm Mỹ (Aesthetics)**

### **Luật "Vuông Góc" (Ortho Layout)**

#### **✅ NÊN (Do)**

- Luôn dùng skinparam linetype ortho.
- **Chủ động điều hướng:**
  - -down->: Luồng chính (Controller -> Service -> Repo).
  - -right-> / -left->: Dàn Entity sang ngang.

#### **❌ KHÔNG NÊN (Don't)**

- Để PlantUML tự sắp xếp.
- Dùng left to right direction.

## **4. Các Loại Quan Hệ (Relationships)**

### **A. Dependency Injection (Association)**

- **Ký hiệu:** --> (Nét liền)

#### **✅ NÊN (Do)**

- **Controller --> Service**
- **Service --> Repository**

#### **❌ KHÔNG NÊN (Don't)**

- Dùng nét đứt ..> cho Injection.
- Ghi nhãn injects, uses.

### **B. Entity Relationship (Ownership)**

- **Ký hiệu:** o-- (Aggregation - Ưu tiên) hoặc \*-- (Composition).

#### **✅ NÊN (Do)**

- **Aggregation (o--):** Cho quan hệ tham chiếu (User - Role).
- **Composition (\*--):** Cho quan hệ cha-con sống chết có nhau (Invoice - InvoiceDetail).
- Dùng -right- / -left- để dàn trang Entity.

### **C. Dependency (Usage)**

- **Ký hiệu:** ..> (Nét đứt)

#### **✅ NÊN (Do)**

- **Repository ..> Entity**: Repo trả về Entity.

## **5. Hướng Dẫn Mapping (Simplified)**

| Thành phần     | Loại UML  | Ký hiệu               | Ghi chú                |
| :------------- | :-------- | :-------------------- | :--------------------- |
| **Controller** | Class     | class MajorController | Chỉ vẽ public method   |
| **Service**    | Class     | class MajorService    | Chỉ vẽ business method |
| **Repository** | Interface | interface MajorRepo   | Vẽ method query        |
| **Entity**     | Class     | class Major           | Vẽ fields              |
| **Relations**  | Arrow     | --> / o--             | Vuông góc, không chéo  |

## **6. Checklist Trước Khi Commit**

1. [ ] **Scope:** Chỉ có 4 loại class (Controller, Service, Repo, Entity) chưa? Đã xóa hết Utils/Mapper chưa?
2. [ ] **Clean:** Đã xóa hết DTO chưa?
3. [ ] **Repository:** Chỉ có 1 Repository interface chưa? Đã gộp Custom + Impl vào 1 interface chưa?
4. [ ] **Abstract:** Đã thay ArrayList bằng List chưa?
5. [ ] **Style:** Đã thêm skinparam linetype ortho chưa?
6. [ ] **Layout:** Đường nối có vuông vức không? Có bị đường chéo cắt ngang logic không?
7. [ ] **Naming:** Tên file có đúng format class_diagram\_[feature_name].puml không?
