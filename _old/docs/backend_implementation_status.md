# FUACS - Backend Service Implementation Status

**Project Name**: backend  
**Last Updated**: 2025-10-15T20:00:00Z  
**Description**: FUACS - Backend Service Implementation Manifest

---

## Technology Stack

### Runtime

- **Framework**: Spring Boot
- **Version**: 3.5.6
- **Language**: Java 21
- **Build Tool**: Maven

### Libraries

#### Web

- spring-boot-starter-web

#### Security

- spring-boot-starter-security
- spring-boot-starter-oauth2-authorization-server

#### Data

- spring-boot-starter-data-jpa
- postgresql

#### Validation

- hibernate-validator
- jakarta.validation-api

#### Mapping

- mapstruct

#### External Integrations

- google-api-client
- google-http-client-jackson2
- spring-boot-starter-mail
- resilience4j-spring-boot3
- spring-dotenv

#### Documentation

- springdoc-openapi-starter-webmvc-ui

### Testing

#### Unit Testing

- spring-boot-starter-test
- spring-security-test

#### Integration Testing

- testcontainers-junit-jupiter
- testcontainers-postgresql

### Containerization

- **Builder Image**: maven:3.9-eclipse-temurin-21
- **Runtime Image**: eclipse-temurin:21-jre-alpine
- **Entrypoint**: java -jar app.jar

---

## Architecture Patterns

### REST API Layer

**Description**: Controllers expose REST endpoints under /api/v1/* using Spring MVC annotations

**Conventions**:

- Use @RestController and @RequestMapping for base path
- Return Response or PagingResponse wrapper for consistent API responses
- Apply @PreAuthorize for method-level security with granular permissions
- Use @Valid for request body validation with Jakarta validation

### Service Layer

**Description**: Services encapsulate business logic, orchestrating repositories and utilities before returning DTOs

**Conventions**:

- Use @Service annotation
- Apply @Transactional for write operations
- Apply @Transactional(readOnly = true) for read operations
- Throw domain-specific exceptions (ResourceNotFoundException, ResourceConflictException, InvalidDateRangeException)
- Return DTOs, never entities
- Perform business rule validation before persistence

### Security Pipeline

**Description**: Stateless JWT resource server with custom authentication filter and method security permission evaluator

**Conventions**:

- JWT tokens contain user claims and permissions
- Access tokens expire in 60 minutes (see TokenProviderUtil#createAccessToken)
- Refresh tokens expire in 1 day
- Method security uses granular permissions (USER_CREATE, SEMESTER_READ, etc.) but many endpoints still lack @PreAuthorize annotations
- Password reset tokens expire in 15 minutes

### DTO Mapping

**Description**: MapStruct mappers convert between entities and DTO payloads

**Conventions**:

- Use @Mapper(componentModel = "spring")
- Extend DTOMapper base interface
- Provide toEntity(CreateRequest) for create operations
- Provide update methods with @MappingTarget for update operations

### Exception Handling

**Description**: Global exception handler provides consistent error responses

**Conventions**:

- Use @ControllerAdvice for global exception handling
- Return Response with appropriate status and message
- Map specific exceptions to HTTP status codes
- Include validation error details for MethodArgumentNotValidException

### Data Access

**Description**: JPA repositories with Spring Data JPA

**Conventions**:

- Extend JpaRepository (Entity, ID)
- Use custom @Query (JPQL or native) for search/count operations
- Use @Modifying for UPDATE/DELETE queries where soft delete is required
- Prefer soft delete via `is_active` column (exposed to API as `active`) over hard delete

---

## Coding Standards

### DTO Pattern

**Type**: classes

**Description**: Use regular Java classes with getters/setters, NOT records

#### Request DTO

- **Location**: com.fuacs.backend.dto.request
- **Naming Conventions**:
  - **Standard CRUD**: `{Entity}Request` - Used for both create and update operations (e.g., SemesterRequest, MajorRequest, SubjectRequest)
  - **Specific Actions**: `{Prefix}{Action}Request` - Used when multiple request types exist for same entity (e.g., PasswordForgotRequest, PasswordResetRequest, PasswordUpdateRequest)
  - **Authentication**: `Login{Variant}Request` - For authentication variants (e.g., LoginRequest, LoginGoogleRequest)
  - **Search/Filtering**: `{Entity}SearchRequest` - For search and pagination (e.g., SemesterSearchRequest, UserSearchRequest)
- **Validation**: Use jakarta.validation.constraints annotations (@NotBlank, @NotNull, @Size, @Email, @Pattern)

#### Response DTO

- **Location**: com.fuacs.backend.dto.response
- **Naming**: {Entity}Response or {Entity}DTO (e.g., SemesterResponse, UserDTO, TokenResponse)
- **Annotation**: @JsonInclude(JsonInclude.Include.NON_NULL)

### Mapper Pattern

- **Framework**: MapStruct
- **Base Interface**: DTOMapper<ResponseDTO, Entity>
- **Component Model**: spring
- **Conventions**:
  - Extend DTOMapper for standard CRUD mappers
  - Provide toEntity(CreateRequest) for create operations
  - Provide update methods with @MappingTarget for updates

### Response Wrapper

- **Standard**: Response (generic type T)
- **Paginated**: PagingResponse (generic type T)
- **Status Codes**:
  - success: 200
  - created: 201
  - bad_request: 400
  - unauthorized: 401
  - forbidden: 403
  - not_found: 404
  - conflict: 409
  - internal_server_error: 500

### Entity Layer

- **Base Class**: BaseEntity provides createdAt, updatedAt timestamps and isActive flag
- **Naming**: Entity class names are singular (User, Role, Semester)
- **Table Naming**: Table names are plural lowercase (users, roles, semesters)
- **ID Strategy**: Use @GeneratedValue(strategy = GenerationType.IDENTITY)
- **ID Types**: Integer for most entities, Short for lookup tables
- **Soft Delete**: Use isActive Boolean field for soft delete capability

### Service Layer Standards

- **Transaction Management**: Use @Transactional for writes, @Transactional(readOnly = true) for reads
- **Error Handling**: Throw domain-specific exceptions, never return null
- **Validation**: Perform business rule validation before persistence
- **Return Types**: Always return DTOs, never entities

### Controller Layer Standards

- **Response Wrapper**: Use Response for single items, PagingResponse for paginated lists
- **Security**: Apply @PreAuthorize with granular permissions
- **Validation**: Use @Valid for request body validation
- **Path Variables**: Use appropriate types (Short, Integer, Long) for path variables

---

## Data Models

### Entities

#### User

- **Table**: users
- **Description**: System account with login credentials and activation state
- **Fields**: id (Integer), username, email, full_name, is_active, password_hash
- **Relationships**: Many-to-many with Role via user_roles
- **Notes**: Extends BaseEntity for created_at/updated_at/is_active

#### Role

- **Table**: roles
- **Description**: Aggregates permissions and is assigned to users
- **Fields**: id (Short), name, is_active
- **Relationships**: Many-to-many with User, Many-to-many with Permission via role_permissions
- **Notes**: Extends BaseEntity

#### Permission

- **Table**: permissions
- **Description**: Fine-grained capability toggled by roles
- **Fields**: id (Short), name, is_active
- **Relationships**: Many-to-many with Role
- **Notes**: Extends BaseEntity

#### PasswordResetToken

- **Table**: password_reset_tokens
- **Description**: Temporary token for password reset flow with expiration
- **Fields**: id (Integer), email, token_hash, created_at, expires_at
- **Relationships**: None
- **Notes**: Tokens expire after 15 minutes. Upsert strategy: existing tokens are updated when a new reset request is made for the same email

#### Semester

- **Table**: semesters
- **Description**: Academic semester with start and end dates
- **Fields**: id (Short), name, code, start_date, end_date, is_active
- **Relationships**: One-to-many with StudyClass
- **Notes**: Extends BaseEntity for created_at/updated_at/is_active

#### Major

- **Table**: majors
- **Description**: Academic major/program for student specialization
- **Fields**: id (Short), name, code, is_active
- **Relationships**: One-to-many with Subject, One-to-many with StudentProfile
- **Notes**: Extends BaseEntity for created_at/updated_at/is_active

#### Subject

- **Table**: subjects
- **Description**: Academic subject/course within a major
- **Fields**: id (Short), name, code, major_id, is_active
- **Relationships**: Many-to-one with Major, One-to-many with StudyClass
- **Notes**: Extends BaseEntity for created_at/updated_at/is_active

#### StudyClass

- **Table**: classes
- **Description**: Class instance linking subject and semester (named StudyClass to avoid Java keyword conflict)
- **Fields**: id (Short), name, subject_id, semester_id, is_active
- **Relationships**: Many-to-one with Subject, Many-to-one with Semester, One-to-many with Slot
- **Notes**: Extends BaseEntity for created_at/updated_at/is_active

#### Room

- **Table**: rooms
- **Description**: Physical classroom or examination room
- **Fields**: id (Short), name, location, is_active
- **Relationships**: One-to-many with Camera, One-to-many with Slot
- **Notes**: Extends BaseEntity for created_at/updated_at/is_active

#### Camera

- **Table**: cameras
- **Description**: IP camera assigned to rooms for attendance monitoring
- **Fields**: id (Short), name, rtsp_url, room_id, is_active
- **Relationships**: Many-to-one with Room, Many-to-many with Slot via slot_cameras
- **Notes**: Extends BaseEntity for created_at/updated_at/is_active

#### Slot

- **Table**: slots
- **Description**: Lecture or exam session with time and location details
- **Fields**: id (Integer), start_time, end_time, finalized_at, slot_type, class_id, room_id, staff_user_id, is_active
- **Relationships**: Many-to-one with StudyClass, Many-to-one with Room, Many-to-one with User (staff), Many-to-many with Camera via slot_cameras
- **Notes**: Extends BaseEntity for created_at/updated_at/is_active. SlotType enum: LECTURE, EXAM

#### IdentitySubmission

- **Table**: identity_submissions
- **Description**: Student identity registration and update requests for facial recognition
- **Fields**: id (Integer), student_user_id, reviewed_by_user_id, status, submission_type, rejection_reason, reviewed_at, created_at, updated_at
- **Relationships**: Many-to-one with User (student), Many-to-one with User (reviewer)
- **Notes**: Does not extend BaseEntity. Has own timestamp fields

### Auditing

- **Base Class**: BaseEntity
- **Description**: Provides created_at and updated_at timestamps via Spring Data JPA auditing plus isActive flag
- **Fields**: createdAt (Instant), updatedAt (Instant), isActive (Boolean)

---

## Codebase Inventory

### Entity Implementations

#### User Entity

- **File**: com/fuacs/backend/entity/User.java
- **Class**: User
- **Extends**: BaseEntity
- **Table**: users
- **Primary Key**: Integer id
- **Purpose**: JPA entity mapping for user accounts with authentication credentials

#### Role Entity

- **File**: com/fuacs/backend/entity/Role.java
- **Class**: Role
- **Extends**: BaseEntity
- **Table**: roles
- **Primary Key**: Short id
- **Purpose**: JPA entity for role-based access control

#### Permission Entity

- **File**: com/fuacs/backend/entity/Permission.java
- **Class**: Permission
- **Extends**: BaseEntity
- **Table**: permissions
- **Primary Key**: Short id
- **Purpose**: JPA entity for granular permissions

#### PasswordResetToken Entity

- **File**: com/fuacs/backend/entity/PasswordResetToken.java
- **Class**: PasswordResetToken
- **Extends**: None
- **Table**: password_reset_tokens
- **Primary Key**: Integer id
- **Purpose**: Temporary token storage for password reset flow

#### BaseEntity Base Class

- **File**: com/fuacs/backend/entity/BaseEntity.java
- **Class**: BaseEntity
- **Type**: @MappedSuperclass
- **Purpose**: Base class providing automatic timestamp auditing and soft delete capability for all entities

#### Semester Entity

- **File**: com/fuacs/backend/entity/Semester.java
- **Class**: Semester
- **Extends**: BaseEntity
- **Table**: semesters
- **Primary Key**: Short id
- **Purpose**: JPA entity for academic semester management

#### Major Entity

- **File**: com/fuacs/backend/entity/Major.java
- **Class**: Major
- **Extends**: BaseEntity
- **Table**: majors
- **Primary Key**: Short id
- **Purpose**: JPA entity for academic major/program management

#### Subject Entity

- **File**: com/fuacs/backend/entity/Subject.java
- **Class**: Subject
- **Extends**: BaseEntity
- **Table**: subjects
- **Primary Key**: Short id
- **Purpose**: JPA entity for academic subject/course management

#### StudyClass Entity

- **File**: com/fuacs/backend/entity/StudyClass.java
- **Class**: StudyClass
- **Extends**: BaseEntity
- **Table**: classes
- **Primary Key**: Short id
- **Purpose**: JPA entity for class management (named StudyClass to avoid Java keyword conflict)

#### Room Entity

- **File**: com/fuacs/backend/entity/Room.java
- **Class**: Room
- **Extends**: BaseEntity
- **Table**: rooms
- **Primary Key**: Short id
- **Purpose**: JPA entity for physical room management

#### Camera Entity

- **File**: com/fuacs/backend/entity/Camera.java
- **Class**: Camera
- **Extends**: BaseEntity
- **Table**: cameras
- **Primary Key**: Short id
- **Purpose**: JPA entity for IP camera management

#### Slot Entity

- **File**: com/fuacs/backend/entity/Slot.java
- **Class**: Slot
- **Extends**: BaseEntity
- **Table**: slots
- **Primary Key**: Integer id
- **Purpose**: JPA entity for lecture/exam slot scheduling

#### IdentitySubmission Entity

- **File**: com/fuacs/backend/entity/IdentitySubmission.java
- **Class**: IdentitySubmission
- **Extends**: None
- **Table**: identity_submissions
- **Primary Key**: Integer id
- **Purpose**: JPA entity for identity registration and verification requests

#### StudentProfile Entity

- **File**: com/fuacs/backend/entity/StudentProfile.java
- **Class**: StudentProfile
- **Extends**: None (intentionally does not extend BaseEntity)
- **Table**: student_profiles
- **Primary Key**: Integer userId (shared with User via @MapsId)
- **Purpose**: JPA entity for student-specific profile data with major assignment
- **Notes**:
  - Uses one-to-one relationship with User entity, sharing the same primary key via @MapsId
  - Does NOT extend BaseEntity by design - lifecycle management (timestamps, soft delete) is handled through the parent User entity
  - No separate created_at/updated_at/is_active fields since these are tracked in the associated User entity
  - This design ensures data consistency and avoids duplication of audit fields

### Repositories

#### UserRepository

- **File**: com/fuacs/backend/repository/UserRepository.java
- **Interface**: UserRepository
- **Extends**: JpaRepository<User, Integer>
- **Purpose**: Data access layer for User entity
- **Custom Methods**: searchStaffs, countAllStaffs, findByUsername, findByEmail, deactivateUserById, existsByEmailOrUsername, findByIdAndIsActiveTrue

#### RoleRepository

- **File**: com/fuacs/backend/repository/RoleRepository.java
- **Interface**: RoleRepository
- **Extends**: JpaRepository<Role, Short>
- **Purpose**: Data access layer for Role entity
- **Custom Methods**: searchRoles, countAllRoles, deactivateById, existsByName, findUpdatableRoleById, findByIdIn, findByName

#### PermissionRepository

- **File**: com/fuacs/backend/repository/PermissionRepository.java
- **Interface**: PermissionRepository
- **Extends**: JpaRepository<Permission, Short>
- **Purpose**: Data access layer for Permission entity
- **Custom Methods**: findByNameLike, countAll, deactivatePermissionById, existsByName

#### PasswordResetTokenRepository

- **File**: com/fuacs/backend/repository/PasswordResetTokenRepository.java
- **Interface**: PasswordResetTokenRepository
- **Extends**: JpaRepository<PasswordResetToken, Integer>
- **Purpose**: Data access layer for PasswordResetToken entity
- **Custom Methods**: updateToken, findByTokenHash

#### SemesterRepository

- **File**: com/fuacs/backend/repository/SemesterRepository.java
- **Interface**: SemesterRepository
- **Extends**: JpaRepository<Semester, Short>
- **Purpose**: Data access layer for Semester entity
- **Custom Methods**: searchSemesters, count, existsByCode, existsByName, findByIdAndIsActiveTrue

#### MajorRepository

- **File**: com/fuacs/backend/repository/MajorRepository.java
- **Interface**: MajorRepository
- **Extends**: JpaRepository<Major, Short>
- **Purpose**: Data access layer for Major entity
- **Custom Methods**: searchMajors, countAll, existsByCode, existsByName, findByIdAndIsActiveTrue

#### SubjectRepository

- **File**: com/fuacs/backend/repository/SubjectRepository.java
- **Interface**: SubjectRepository
- **Extends**: JpaRepository<Subject, Short>
- **Purpose**: Data access layer for Subject entity
- **Custom Methods**: searchSubjects, countAllSubjects, findByMajorId, countAllByMajorId, existsByCode, existsByName, findByIdAndIsActiveTrue

#### ClassRepository

- **File**: com/fuacs/backend/repository/ClassRepository.java
- **Interface**: ClassRepository
- **Extends**: JpaRepository<StudyClass, Short>
- **Purpose**: Data access layer for StudyClass entity
- **Custom Methods**: searchClasses, countAll, findBySemesterId, countAllBySemesterId, findByIdAndIsActiveTrue

#### RoomRepository

- **File**: com/fuacs/backend/repository/RoomRepository.java
- **Interface**: RoomRepository
- **Extends**: JpaRepository<Room, Short>
- **Purpose**: Data access layer for Room entity
- **Custom Methods**: searchRooms, countAll, findByIdAndIsActiveTrue

#### CameraRepository

- **File**: com/fuacs/backend/repository/CameraRepository.java
- **Interface**: CameraRepository
- **Extends**: JpaRepository<Camera, Short>
- **Purpose**: Data access layer for Camera entity
- **Custom Methods**: searchCameras, countAll, existsByName, existsByRtspUrl, findByIdAndIsActiveTrue

#### SlotRepository

- **File**: com/fuacs/backend/repository/SlotRepository.java
- **Interface**: SlotRepository
- **Extends**: JpaRepository<Slot, Integer>
- **Purpose**: Data access layer for Slot entity
- **Custom Methods**: findByPage, countAll, findByClassId, countAllByClassId

#### IdentitySubmissionRepository

- **File**: com/fuacs/backend/repository/IdentitySubmissionRepository.java
- **Interface**: IdentitySubmissionRepository
- **Extends**: JpaRepository<IdentitySubmission, Integer>
- **Purpose**: Data access layer for IdentitySubmission entity
- **Custom Methods**: searchSubmissions, countAll

#### StudentProfileRepository

- **File**: com/fuacs/backend/repository/StudentProfileRepository.java
- **Interface**: StudentProfileRepository
- **Extends**: JpaRepository<StudentProfile, Integer>
- **Purpose**: Data access layer for StudentProfile entity
- **Custom Methods**: searchStudents, countAllStudents

### Services

#### AuthenticationService

- **File**: com/fuacs/backend/service/AuthenticationService.java
- **Class**: AuthenticationService
- **Dependencies**: RoleRepository, UserRepository, TokenProviderUtil, PasswordEncoder, PermissionRepository, EmailService, PasswordResetTokenRepository
- **Purpose**: Business logic for authentication and password management
- **Key Methods**: login, googleLogin, refreshToken, forgotPassword, resetPassword, updatePassword, buildTokenResponse, validateUserActive

#### StaffService

- **File**: com/fuacs/backend/service/StaffService.java
- **Class**: StaffService
- **Dependencies**: StudentProfileRepository, UserRepository, UserMapper, PasswordEncoder, RoleRepository, EmailService
- **Purpose**: Business logic for staff profile CRUD operations
- **Key Methods**: create, findAllStaff, countAllStaffs, findStaffByUserId, update, delete
- **Notes**: Uses UserMapper instead of a dedicated StaffMapper since StaffDTO extends UserDTO

#### EmailService

- **File**: com/fuacs/backend/service/EmailService.java
- **Class**: EmailService
- **Dependencies**: JavaMailSender
- **Purpose**: Send transactional emails asynchronously
- **Key Methods**: sendPasswordResetEmail, sendPassword

#### SemesterService

- **File**: com/fuacs/backend/service/SemesterService.java
- **Class**: SemesterService
- **Dependencies**: SemesterRepository, SemesterMapper
- **Purpose**: Business logic for semester CRUD operations
- **Key Methods**: create, findAll, countAll, findById, update, deactivate

#### MajorService

- **File**: com/fuacs/backend/service/MajorService.java
- **Class**: MajorService
- **Dependencies**: MajorRepository, MajorMapper
- **Purpose**: Business logic for major CRUD operations
- **Key Methods**: create, findAll, countAll, findById, update, deactivate

#### SubjectService

- **File**: com/fuacs/backend/service/SubjectService.java
- **Class**: SubjectService
- **Dependencies**: SubjectRepository, SubjectMapper, MajorRepository
- **Purpose**: Business logic for subject CRUD operations
- **Key Methods**: create, findAll, countAll, findById, update, delete (soft deactivate), findAllByMajor, countAllByMajor

#### ClassService

- **File**: com/fuacs/backend/service/ClassService.java
- **Class**: ClassService
- **Dependencies**: ClassRepository, SemesterRepository, SubjectRepository, StudyClassMapper
- **Purpose**: Business logic for class CRUD operations
- **Key Methods**: create, findAll, countAll, findById, update, deactivate, findAllBySemesterId, countAllBySemesterId

#### RoomService

- **File**: com/fuacs/backend/service/RoomService.java
- **Class**: RoomService
- **Dependencies**: RoomRepository, RoomMapper
- **Purpose**: Business logic for room CRUD operations
- **Key Methods**: create, findAll, countAll, findById, update, deactivate

#### CameraService

- **File**: com/fuacs/backend/service/CameraService.java
- **Class**: CameraService
- **Dependencies**: CameraRepository, RoomRepository, CameraMapper
- **Purpose**: Business logic for camera CRUD operations
- **Key Methods**: create, findAll, countAll, findById, update, deactivate

#### SlotService

- **File**: com/fuacs/backend/service/SlotService.java
- **Class**: SlotService
- **Dependencies**: SlotRepository, ClassRepository, RoomRepository, UserRepository, SlotMapper
- **Purpose**: Business logic for slot CRUD operations
- **Key Methods**: create, findAll, countAll, findById, update, deactivate, findAllByClassId, countAllByClassId

#### RoleService

- **File**: com/fuacs/backend/service/RoleService.java
- **Class**: RoleService
- **Dependencies**: RoleRepository, PermissionRepository, RoleMapper
- **Purpose**: Business logic for role management and role-permission mapping
- **Key Methods**: create, findAll, countAll, findById, update, deactivate

#### PermissionService

- **File**: com/fuacs/backend/service/PermissionService.java
- **Class**: PermissionService
- **Dependencies**: PermissionRepository, PermissionMapper
- **Purpose**: Business logic for permission CRUD operations
- **Key Methods**: create, findAll, countAll, findById, update, deactivate

#### IdentitySubmissionService

- **File**: com/fuacs/backend/service/IdentitySubmissionService.java
- **Class**: IdentitySubmissionService
- **Dependencies**: IdentitySubmissionRepository, UserRepository, IdentitySubmissionMapper
- **Purpose**: Business logic for identity submission management (enforces reviewer assignments and PENDING->APPROVED/REJECTED transitions)
- **Key Methods**: create (defaults to PENDING), findAll, countAll, findById, review (requires reviewerId and rejectionReason when REJECTED)

#### StudentProfileService

- **File**: com/fuacs/backend/service/StudentProfileService.java
- **Class**: StudentProfileService
- **Dependencies**: StudentProfileRepository, MajorRepository, UserMapper, PasswordEncoder, EmailService, RoleRepository, UserRepository
- **Purpose**: Business logic for student profile management (provisions User accounts, assigns STUDENT role, sends generated password)
- **Key Methods**: create, findAllStudent, countAllStudents, findStudentByUserId, update, delete

### Controllers

#### AuthenticationController

- **File**: com/fuacs/backend/controller/AuthenticationController.java
- **Class**: AuthenticationController
- **Base Path**: /api/v1
- **Dependencies**: AuthenticationService
- **Purpose**: REST endpoints for authentication and password management
- **Endpoints**: /auth/login, /auth/google/login, /auth/refresh-token, /auth/forgot-password, /auth/reset-password, /users/{id}/update-password

#### StaffController

- **File**: com/fuacs/backend/controller/StaffController.java
- **Class**: StaffController
- **Base Path**: /api/v1/staffs
- **Dependencies**: StaffService
- **Purpose**: REST endpoints for staff profile CRUD operations
- **Endpoints**: GET /, GET /{userId}, POST /, PUT /{userId}, DELETE /{userId}

#### SemesterController

- **File**: com/fuacs/backend/controller/SemesterController.java
- **Class**: SemesterController
- **Base Path**: /api/v1/semesters
- **Dependencies**: SemesterService, ClassService
- **Purpose**: REST endpoints for semester CRUD operations
- **Endpoints**: GET /, GET /{id}, POST /, PUT /{id}, DELETE /{id}, GET /{semesterId}/classes

#### MajorController

- **File**: com/fuacs/backend/controller/MajorController.java
- **Class**: MajorController
- **Base Path**: /api/v1/majors
- **Dependencies**: MajorService, SubjectService
- **Purpose**: REST endpoints for major CRUD operations
- **Endpoints**: GET /, GET /{id}, POST /, PUT /{id}, DELETE /{id}, GET /{majorId}/subjects

#### SubjectController

- **File**: com/fuacs/backend/controller/SubjectController.java
- **Class**: SubjectController
- **Base Path**: /api/v1/subjects
- **Dependencies**: SubjectService
- **Purpose**: REST endpoints for subject CRUD operations
- **Endpoints**: GET /, GET /{id}, POST /, PUT /{id}, DELETE /{id}

#### ClassController

- **File**: com/fuacs/backend/controller/ClassController.java
- **Class**: ClassController
- **Base Path**: /api/v1/classes
- **Dependencies**: ClassService, SlotService
- **Purpose**: REST endpoints for class CRUD operations
- **Endpoints**: GET /, GET /{id}, POST /, PUT /{id}, DELETE /{id}, GET /{classId}/slots

#### RoomController

- **File**: com/fuacs/backend/controller/RoomController.java
- **Class**: RoomController
- **Base Path**: /api/v1/rooms
- **Dependencies**: RoomService
- **Purpose**: REST endpoints for room CRUD operations
- **Endpoints**: GET /, GET /{id}, POST /, PUT /{id}, DELETE /{id}

#### CameraController

- **File**: com/fuacs/backend/controller/CameraController.java
- **Class**: CameraController
- **Base Path**: /api/v1/cameras
- **Dependencies**: CameraService
- **Purpose**: REST endpoints for camera CRUD operations
- **Endpoints**: GET /, GET /{id}, POST /, PUT /{id}, DELETE /{id}

#### SlotController

- **File**: com/fuacs/backend/controller/SlotController.java
- **Class**: SlotController
- **Base Path**: /api/v1/slots
- **Dependencies**: SlotService
- **Purpose**: REST endpoints for slot CRUD operations
- **Endpoints**: GET /, GET /{id}, POST /, PUT /{id}, DELETE /{id}

#### RoleController

- **File**: com/fuacs/backend/controller/RoleController.java
- **Class**: RoleController
- **Base Path**: /api/v1/roles
- **Dependencies**: RoleService
- **Purpose**: REST endpoints for role CRUD operations
- **Endpoints**: GET /, GET /{id}, POST /, PUT /{id}, DELETE /{id}

#### PermissionController

- **File**: com/fuacs/backend/controller/PermissionController.java
- **Class**: PermissionController
- **Base Path**: /api/v1/permissions
- **Dependencies**: PermissionService
- **Purpose**: REST endpoints for permission CRUD operations
- **Endpoints**: GET /, GET /{id}, POST /, PUT /{id}, DELETE /{id}

#### IdentitySubmissionController

- **File**: com/fuacs/backend/controller/IdentitySubmissionController.java
- **Class**: IdentitySubmissionController
- **Base Path**: /api/v1/identity-submissions
- **Dependencies**: IdentitySubmissionService
- **Purpose**: REST endpoints for identity submission management
- **Endpoints**: GET /, GET /{id}, POST /, PUT /{id}/review

#### StudentProfileController

- **File**: com/fuacs/backend/controller/StudentProfileController.java
- **Class**: StudentProfileController
- **Base Path**: /api/v1/students
- **Dependencies**: StudentProfileService
- **Purpose**: REST endpoints for student profile management
- **Endpoints**: GET /, GET /{id}, POST /, PUT /{id}, DELETE /{id}

### DTOs

#### Request DTOs

- **LoginRequest**: Login credentials (username, password)
- **GoogleLoginRequest**: Google authentication token
- **RefreshTokenRequest**: Refresh token for token renewal
- **ForgotPasswordRequest**: Email for password reset
- **ResetPasswordRequest**: Reset password with token (token, newPassword, confirmPassword)
- **UpdatePasswordRequest**: Update password for authenticated user (oldPassword, newPassword, confirmPassword)
- **UserRequest**: Create/update user (username, email, fullName)
- **UserSearchRequest**: Search and pagination for users (search, page, pageSize, sort/sortBy, roleNames filter)
- **SemesterRequest**: Create/update semester (name, code, startDate, endDate)
- **SemesterSearchRequest**: Search and pagination for semesters (search, page, pageSize)
- **MajorRequest**: Create/update major (name, code)
- **MajorSearchRequest**: Search and pagination for majors (search, page, pageSize)
- **SubjectRequest**: Create/update subject (name, code, majorId)
- **SubjectSearchRequest**: Search and pagination for subjects (search, page, pageSize)
- **ClassRequest**: Create/update class (name, subjectId, semesterId)
- **ClassSearchRequest**: Search and pagination for classes (search, page, pageSize)
- **RoomRequest**: Create/update room (name, location)
- **RoomSearchRequest**: Search and pagination for rooms (search, page, pageSize)
- **CameraRequest**: Create/update camera (name, rtspUrl, roomId)
- **CameraSearchRequest**: Search and pagination for cameras (search, page, pageSize)
- **SlotRequest**: Create/update slot (startTime, endTime, classId, roomId, staffUserId, slotType)
- **SlotSearchRequest**: Search and pagination for slots (search, page, pageSize)
- **RoleRequest**: Create/update role (name, permissionIds)
- **RoleSearchRequest**: Search and pagination for roles (search, page, pageSize)
- **PermissionRequest**: Create/update permission (name)
- **PermissionSearchRequest**: Search and pagination for permissions (search, page, pageSize)
- **IdentitySubmissionCreationRequest**: Create identity submission (studentUserId, submissionType)
- **IdentitySubmissionReviewRequest**: Review identity submission (status, rejectionReason, reviewerId)
- **IdentitySubmissionSearchRequest**: Search and pagination for identity submissions (status, studentUserId, page, pageSize, sort/sortBy)
- **StudentProfileRequest**: Create/update student profile (username, email, fullName, majorId)
- **StudentProfileSearchRequest**: Search and pagination for student profiles (search, page, pageSize, sort/sortBy)

#### Response DTOs

- **TokenResponse**: Authentication token response (accessToken, refreshToken, tokenType, fullName, username, roles)
- **UserDTO**: User information response (id, username, email, fullName, active, createdAt, updatedAt)
- **RoleDTO**: Role information response (id, code, name, permissions, active, createdAt, updatedAt)
- **PermissionDTO**: Permission information response (id, name)
- **SemesterDTO**: Semester information response (id, name, code, active, createdAt, updatedAt)
- **MajorDTO**: Major information response (id, name, code, active, createdAt, updatedAt)
- **SubjectDTO**: Subject information response (id, name, code, major, active, createdAt, updatedAt)
- **ClassDTO**: Class information response (id, name, semester, active, createdAt, updatedAt)
- **RoomDTO**: Room information response (id, name, location, active, createdAt, updatedAt)
- **CameraDTO**: Camera information response (id, name, rtspUrl, room, active, createdAt, updatedAt)
- **SlotDTO**: Slot information response (id, startTime, endTime, slotType, studyClass, room, staffUser, active, createdAt, updatedAt)
- **IdentitySubmissionDTO**: Identity submission response (id, studentUserId, reviewedByUserId, status, submissionType, rejectionReason, reviewedAt, active, createdAt, updatedAt)
- **StudentProfileDTO**: Student profile response (UserDTO fields plus major)
- **Response**: Standard API response wrapper (status, message, data) - generic type T
- **PagingResponse**: Paginated API response wrapper (extends Response with items, currentPage, pageSize, totalItems, totalPages) - generic type T
- **BaseDTO**: Base response DTO with audit fields (active, createdAt, updatedAt)

### Mappers

#### DTOMapper Base Interface

- **File**: com/fuacs/backend/dto/mapper/DTOMapper.java
- **Interface**: DTOMapper (generic types D, E)
- **Purpose**: Base interface for all MapStruct mappers
- **Methods**: toDTO, toEntity (single and list conversions)

#### UserMapper Implementation

- **File**: com/fuacs/backend/dto/mapper/UserMapper.java
- **Interface**: UserMapper
- **Extends**: DTOMapper (UserDTO, User)
- **Annotation**: @Mapper(componentModel = "spring")
- **Purpose**: Map between User entity and UserDTO

#### RoleMapper Implementation

- **File**: com/fuacs/backend/dto/mapper/RoleMapper.java
- **Interface**: RoleMapper
- **Extends**: DTOMapper (RoleDTO, Role)
- **Annotation**: @Mapper(componentModel = "spring")
- **Purpose**: Map between Role entity and RoleDTO

### Utilities

#### TokenProviderUtil

- **File**: com/fuacs/backend/util/TokenProviderUtil.java
- **Class**: TokenProviderUtil
- **Annotation**: @Component
- **Dependencies**: PasswordResetTokenRepository
- **Purpose**: JWT token generation and validation
- **Key Methods**: createAccessToken, createRefreshToken, createResetPasswordToken, isValidRefreshToken, signToken, verifySignature, isExpired

### Exceptions

#### Custom Exceptions

- **ResourceNotFoundException**: 404 NOT_FOUND - Thrown when requested resource does not exist
- **ResourceConflictException**: 409 CONFLICT - Thrown when resource creation/update conflicts with existing data
- **InvalidDateRangeException**: 400 BAD_REQUEST - Thrown when date range validation fails

#### GlobalExceptionHandler

- **File**: com/fuacs/backend/exception/GlobalExceptionHandler.java
- **Class**: GlobalExceptionHandler
- **Annotation**: @ControllerAdvice
- **Purpose**: Global exception handler for consistent error responses
- **Handles**: ResourceNotFoundException, InvalidDateRangeException, ResourceConflictException, InsufficientAuthenticationException, InvalidBearerTokenException, IllegalArgumentException, BadCredentialsException, AccessDeniedException, MethodArgumentNotValidException, Exception

---

## Feature Status

### BE-FEAT-AUTH - Authentication Core

**Status**: implemented (90% complete)

**Components**: AuthenticationController, AuthenticationService, TokenProviderUtil, EmailService, PasswordResetTokenRepository

**Description**: Complete authentication flow with username/password, Google Sign-In, JWT tokens, and password reset

**Missing**: Ownership validation for password updates (TODO noted in code)

### BE-FEAT-AUTHZ - Authorization & Security

**Status**: partially implemented (70% complete)

**Components**: Method Security, PermissionEvaluator, JWT Filter, @PreAuthorize annotations

**Description**: Granular permission-based authorization with method-level security

**Missing**: Full permission coverage for all endpoints (many endpoints lack @PreAuthorize annotations)

### BE-FEAT-USER-MGMT - User Management CRUD

**Status**: partially implemented (60% complete)

**Components**: StaffController, StaffService, UserRepository, UserMapper, AuthenticationService

**Description**: User management through staff profiles and authentication endpoints

**Missing**: Dedicated UserController for general user CRUD operations, comprehensive user management beyond staff profiles

### BE-FEAT-ROLE-PERMISSION - Role & Permission Management

**Status**: implemented (80% complete)

**Components**: RoleController, PermissionController, RoleService, PermissionService and related repositories

**Description**: Role and permission CRUD with role-permission mapping

**Missing**: Advanced role assignment constraints and validation

### BE-FEAT-ACADEMIC-CATALOG - Academic Catalog Management

**Status**: implemented (85% complete)

**Components**: SemesterController, MajorController, SubjectController, ClassController and related services

**Description**: Complete CRUD operations for semesters, majors, subjects, and classes with hierarchical relationships

**Missing**: Advanced search and filtering capabilities, bulk import/export

### BE-FEAT-INFRASTRUCTURE - Infrastructure Management

**Status**: implemented (75% complete)

**Components**: RoomController, CameraController, SlotController and related services

**Description**: Room, camera, and slot management with proper associations

**Missing**: Slot-camera associations management, camera status monitoring

### BE-FEAT-IDENTITY-MGMT - Identity Management System

**Status**: partially implemented (40% complete)

**Components**: IdentitySubmissionController, IdentitySubmissionService and related infrastructure

**Description**: Identity registration and verification request management

**Missing**: Identity asset management (file upload/storage), face embedding processing, notification integration

### BE-FEAT-STUDENT-PROFILES - Student Profile Management

**Status**: partially implemented (30% complete)

**Components**: StudentProfileController, StudentProfileService

**Description**: Basic student profile management

**Missing**: Integration with User entity, major assignment, enrollment management

### BE-FEAT-ATTENDANCE - Attendance System

**Status**: not implemented (0% complete)

**Components**: None

**Description**: Core attendance tracking and management system

**Missing**: AttendanceRecord entities, slot session management, real-time attendance updates, finalization workflows

### BE-FEAT-SLOT-INTERACTION - Slot Communication System

**Status**: not implemented (0% complete)

**Components**: None

**Description**: Slot announcements and pre-slot messaging system

**Missing**: SlotAnnouncement entities, PreSlotMessage handling, lecturer-student communication

### BE-FEAT-NOTIFICATIONS - Notification System

**Status**: not implemented (0% complete)

**Components**: None

**Description**: System notifications and announcements

**Missing**: SystemNotification infrastructure, NotificationDelivery mechanism, push notification integration

### BE-FEAT-REPORTING - Reporting & Analytics

**Status**: not implemented (0% complete)

**Components**: None

**Description**: Attendance reports and analytics

**Missing**: Report generation, data export, attendance analytics

### BE-FEAT-SYSTEM-ADMIN - System Administration

**Status**: not implemented (0% complete)

**Components**: None

**Description**: System configuration and audit logging

**Missing**: SystemConfiguration management, OperationalAuditLog tracking, system monitoring APIs

---

## Testing Status

**Summary**: The committed source currently contains only a single Spring Boot context smoke test. Historical Surefire reports under `target/surefire-reports/` reference broader coverage, but the associated test sources are no longer present in `src/test/java`.

**Current Test Coverage**:

- Application context loading: ✅ Implemented (`BackendApplicationTests`)
- Service layer unit tests: ❌ Missing
- Controller integration tests: ❌ Missing
- Repository tests: ❌ Missing
- Security tests: ❌ Missing

**Test Files Present (in repo)**:

- `src/test/java/com/fuacs/backend/BackendApplicationTests.java`: Loads the Spring context against a PostgreSQL Testcontainers instance.

**Historical Evidence**:

- Surefire reports dated 2025-10-14 list 27 executed tests (Semester service/controller) with zero failures. Those classes (`SemesterServiceTest`, `SemesterControllerIntegrationTest`) are not in the current tree and should be considered missing artifacts.

**Gap Analysis**:

- Domain-specific service logic (authentication, catalog, identity, staff/student) has no automated coverage.
- REST controller behaviour (validation, security, pagination) is untested.
- Repository queries (especially native search/count implementations) lack verification.
- Security flows (JWT, permissions) have no regression tests.

**Frameworks Available**:

- Unit: JUnit 5, Mockito
- Integration: Spring Boot Test, Testcontainers (PostgreSQL)

**Test Debt**: High — Reinstate deleted modules or rebuild the suite across services, controllers, repositories, and security.

**Action Items**:

1. Recover or recreate Semester test suites referenced in Surefire history.
2. Establish service-layer unit tests for each domain (using mocks where appropriate).
3. Add controller integration tests covering validation, permission checks, and pagination contracts.
4. Create repository tests to validate native/JPQL search queries.
5. Implement security-focused tests for JWT authentication/authorization flows.

## Implementation Gaps

### Critical Missing Components

#### Attendance Management System

- AttendanceRecord entity and tracking logic
- AttendanceSession management  
- Real-time attendance updates
- Attendance finalization workflows

#### Slot Interaction System

- SlotAnnouncement management
- PreSlotMessage handling
- Slot-student communication channels

#### Notification System

- SystemNotification infrastructure
- NotificationDelivery mechanism
- Push notification integration
- Email notification templates

#### System Administration

- SystemConfiguration management
- OperationalAuditLog tracking
- System monitoring and configuration APIs

### Technical Debt

#### Security Coverage

- Many endpoints lack @PreAuthorize annotations
- Inconsistent permission naming (USER_CREATE vs ROLES_READ)
- Missing ownership validation in operations

#### Testing Infrastructure

- Zero unit test coverage for business logic
- Missing integration test scenarios
- No security test coverage

#### Integration Points

- Identity asset file storage not implemented
- Camera status monitoring not implemented
- Slot-camera association management incomplete

---

## CI/CD Pipeline

### Stages

1. **test**: Run mvn test inside Alpine image with cached Maven repo
2. **build_and_push**: Build Docker image and push with branch and commit tags
3. **deploy**: SSH to target host, render .env, docker compose pull & restart (staging/main)
