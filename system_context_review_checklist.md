# System Context Review Checklist

**Last Updated:** 2025-01-07
**Purpose:** Track progress of reviewing and updating `docs/system_context.yaml` against current codebase

---

## Progress Overview

- [x] **Section 1:** project_info & project_overview ✅
- [x] **Section 2:** platform_definitions ✅
- [x] **Section 3:** authentication_and_role_mapping ✅
- [x] **Section 4:** master_permission_catalog ✅
- [x] **Section 5:** role_definitions ✅
- [x] **Section 6:** function_catalog ✅
- [x] **Section 7:** screen_catalog - common_screens & web_student_screens ✅
- [x] **Section 8:** screen_catalog - web_lecturer_screens ✅
- [x] **Section 8b:** screen_catalog - web_supervisor_screens ✅
- [x] **Section 9:** screen_catalog - web_admin_portal_screens ✅
- [x] **Section 10:** complex_component_catalog ✅ (REMOVED)
- [x] **Section 11:** attendance_system ✅
- [x] **Section 12:** technical_flows ✅
- [x] **Section 13:** information_flows ✅
- [x] **Section 14:** integrations ✅
- [x] **Section 15:** data_policies ✅
- [x] **Section 16:** data_model ✅ (DELETED)
- [x] **Section 17:** idempotency_policies ✅ (DELETED)
- [x] **Section 18:** assumptions ✅ (DELETED)
- [x] **Section 19:** terminology_notes ✅ (DELETED)
- [x] **Section 20:** tech_stack ✅
- [x] **Section 21:** implementation_decisions ✅
- [x] **Section 22:** to_be_discussed_or_backlog ✅
- [ ] **Section 23:** notes
- [ ] **Section 24:** in_scope_functions

---

## Detailed Review

### Section 1: project_info & project_overview

**Section Path:** `system_context.project_info` & `system_context.project_overview`

**Current Content:**

```yaml
project_info:
  project_code: "FUACS"
  project_name: "FU Attendance Checking Smart"

project_overview:
  background: "An independent attendance and academic management system. FUACS serves as the Single Source of Record for all data related to classes, students, lecturers, and attendance results."
  goal: "Support login via Google and system accounts (username/password), class schedules, exam schedules, and smart attendance to assist lecturers."
```

**Status:** ✅ COMPLETED

**User Feedback:**

- Project name and code: OK
- Background: OK
- Goal: OK

**Updates Needed:**

- None

**Notes:**

- All information is accurate and up to date

---

### Section 2: platform_definitions

**Section Path:** `system_context.platform_definitions`

**Current Content:**

```yaml
platform_types:
  MOBILE_APP: "Mobile platform for iOS and Android"
  GENERAL_WEB: "Web platform"
  ADMIN_PORTAL: "Web platform (Admin Portal)"

role_platform_mapping:
  Student: "GENERAL_WEB"
  Lecturer: "GENERAL_WEB"
  Supervisor: "GENERAL_WEB"
  Data_Operator: "ADMIN_PORTAL"
```

**Status:** ✅ COMPLETED

**User Feedback:**

- MOBILE_APP không sử dụng nữa → đã xóa
- role_platform_mapping: OK (tất cả roles đều dùng web platform)

**Updates Needed:**

- ✅ Removed MOBILE_APP from platform_types
- ✅ Removed mobile_app comment from tech_stack section

**Notes:**

- All roles now use web platforms only (GENERAL_WEB or ADMIN_PORTAL)
- No mobile app support in current version

---

### Section 3: authentication_and_role_mapping

**Section Path:** `system_context.authentication_and_role_mapping`

**Current Content:**

```yaml
mapping_method: "System Native"
description: "Users are created and role-managed directly in the system by Data Operators..."
role_assignment_rules: "SUPERVISOR or LECTURER roles cannot be assigned to users with the STUDENT role."
access_control:
  on_missing_user: "deny_access_403"
  on_inactive_status: "deny_access_403"
```

**Status:** ✅ COMPLETED

**User Feedback:**

- mapping_method: OK
- Removed "login identifier = Student ID/Employee ID" (không cần thiết)
- Clarified Google login as "email-based authentication"
- Added restriction: DOP cannot create other DOP accounts or create new roles
- role_assignment_rules: OK
- access_control: OK

**Updates Needed:**

- ✅ Removed mention of Student ID/Employee ID as login identifier
- ✅ Changed "for email verification" to "for email-based authentication"
- ✅ Added: "Data Operators cannot create other Data Operator accounts or create new roles - they can only assign existing roles to user accounts"

**Notes:**

- Google login flow: User logs in with Google → Google returns email → System finds existing user by email → Grant session token
- All authentication and role management is native to the system

---

### Section 4: master_permission_catalog

**Section Path:** `system_context.master_permission_catalog`

**Current Content:**

- USER_MANAGEMENT (15 permissions: 6 STUDENT_\* + 9 STAFF_\*)
- ACADEMIC_CATALOG_MANAGEMENT (37 permissions)
- INFRASTRUCTURE_MANAGEMENT (12 permissions)
- ATTENDANCE_MANAGEMENT (7 permissions)
- REPORTING_AND_DATA (5 permissions)
- STUDENT_PERMISSIONS (1 permission)
- GENERAL_PERMISSIONS (2 permissions)

**Total:** ~79 permissions

**Status:** ✅ COMPLETED

**User Feedback:**

#### USER_MANAGEMENT

- ✅ Restructured into STUDENT_\* and STAFF_\* permissions
- Old structure (7 generic USER_\* permissions) replaced with:
  - **STUDENT permissions (6)**: CREATE, READ_LIST, READ_DETAIL, UPDATE, DELETE, IMPORT
  - **STAFF permissions (9)**: CREATE, READ_LIST, READ_DETAIL, UPDATE, DELETE, IMPORT, SLOTS, CLASSES, SUBJECTS
- UPDATE permissions consolidate: info updates, soft delete (activate/deactivate), and role assignment
- DELETE permissions are hard delete operations
- STAFF_SLOTS/CLASSES/SUBJECTS: View staff's assigned entities (accessible by DOP and staff member themselves)

#### ACADEMIC_CATALOG_MANAGEMENT

- ✅ Split READ permissions into READ_LIST and READ_DETAIL for all entities (SEMESTER, MAJOR, SUBJECT, CLASS, SLOT, ENROLLMENT)
- ✅ Changed all \*_DELETE_HARD to \*_DELETE for consistency
- ✅ Removed session management permissions (SLOT_SESSION_START/STOP/RESCAN) - moved to ATTENDANCE_MANAGEMENT where they logically belong
- ✅ Removed separate FINAL_EXAM permissions (SLOT_CREATE_FINAL_EXAM, SLOT_UPDATE_FINAL_EXAM, SLOT_DELETE_FINAL_EXAM) - these are now covered by the generic SLOT_CREATE/UPDATE/DELETE permissions
- ✅ Expanded ENROLLMENT from single MANAGE permission to full CRUD + IMPORT operations
- Structure per entity:
  - **SEMESTER (6)**: CREATE, READ_LIST, READ_DETAIL, UPDATE, DELETE, IMPORT
  - **MAJOR (6)**: CREATE, READ_LIST, READ_DETAIL, UPDATE, DELETE, IMPORT
  - **SUBJECT (6)**: CREATE, READ_LIST, READ_DETAIL, UPDATE, DELETE, IMPORT
  - **CLASS (6)**: CREATE, READ_LIST, READ_DETAIL, UPDATE, DELETE, IMPORT
  - **SLOT (7)**: CREATE, READ_LIST, READ_DETAIL, UPDATE, DELETE, IMPORT, UPDATE_CATEGORY
  - **ENROLLMENT (6)**: CREATE, READ_LIST, READ_DETAIL, UPDATE, DELETE, IMPORT

#### INFRASTRUCTURE_MANAGEMENT

- ✅ Split READ permissions into READ_LIST and READ_DETAIL for all entities (ROOM, CAMERA)
- ✅ Changed all \*_DELETE_HARD to \*_DELETE for consistency
- Structure per entity:
  - **ROOM (6)**: CREATE, READ_LIST, READ_DETAIL, UPDATE, DELETE, IMPORT
  - **CAMERA (6)**: CREATE, READ_LIST, READ_DETAIL, UPDATE, DELETE, IMPORT
- Updated all 4 roles (DATA_OPERATOR, LECTURER, SUPERVISOR, STUDENT) with new split permissions
- Note: STUDENT does not have CAMERA permissions (only ROOM permissions)

#### ATTENDANCE_MANAGEMENT

- ✅ Added SLOT_SESSION_STOP to complete the session lifecycle (START → STOP → RESCAN)
- ✅ Updated descriptions for SLOT_SESSION_START and SLOT_SESSION_RESCAN to clarify they handle both regular and exam sessions
- Total: 7 permissions (OWN_SCHEDULE_READ, SLOT_SESSION_START, SLOT_SESSION_STOP, SLOT_SESSION_RESCAN, ATTENDANCE_ROSTER_READ, ATTENDANCE_STATUS_UPDATE_MANUAL, ATTENDANCE_REMARK_MANAGE)

#### REPORTING_AND_DATA

- ✅ No changes needed - permissions are functional/action-based, not entity-based
- Total: 5 permissions (REPORT_READ_OWN_SLOT, REPORT_EXPORT_OWN_SLOT, REPORT_READ_CLASS_SUMMARY, REPORT_READ_SYSTEM_WIDE, REPORT_EXPORT_ACADEMIC_DATA)

#### STUDENT_PERMISSIONS

- ✅ No changes needed - single functional permission
- Total: 1 permission (OWN_ATTENDANCE_HISTORY_READ)

#### GENERAL_PERMISSIONS

- ✅ No changes needed - functional permissions for profile management
- Total: 2 permissions (OWN_PROFILE_READ, OWN_PASSWORD_UPDATE)

**Updates Completed:**

- ✅ Replaced USER_MANAGEMENT permissions with STUDENT_\* and STAFF_\* structure
- ✅ Restructured ACADEMIC_CATALOG_MANAGEMENT with READ_LIST/READ_DETAIL split and DELETE naming consistency
- ✅ Expanded ENROLLMENT_MANAGE to 6 separate permissions (CREATE, READ_LIST, READ_DETAIL, UPDATE, DELETE, IMPORT)
- ✅ Removed separate FINAL_EXAM permissions from ACADEMIC_CATALOG_MANAGEMENT
- ✅ Added SLOT_SESSION_STOP to ATTENDANCE_MANAGEMENT
- ✅ Restructured INFRASTRUCTURE_MANAGEMENT with READ_LIST/READ_DETAIL split and DELETE naming consistency
- ✅ Updated DATA_OPERATOR role:
  - All academic catalog and infrastructure permissions now use READ_LIST/READ_DETAIL
  - All permissions use DELETE (not DELETE_HARD)
  - ENROLLMENT permissions expanded to 5 permissions (excluding DELETE)
  - Session management permissions (SLOT_SESSION_START/STOP/RESCAN) removed - these are for LECTURER/SUPERVISOR only
- ✅ Updated LECTURER role: Added READ_LIST/READ_DETAIL for all entities (academic + infrastructure) + SLOT_SESSION_STOP
- ✅ Updated SUPERVISOR role: Added READ_LIST/READ_DETAIL for all entities (academic + infrastructure) + SLOT_SESSION_STOP
- ✅ Updated STUDENT role: Added READ_LIST/READ_DETAIL for all entities (academic + room)

**Notes:**

- STUDENT_DELETE and STAFF_DELETE are NOT assigned to DATA_OPERATOR for safety (hard delete operations)
- System uses student_profiles and staff_profiles, not generic user management
- Session management permissions (SLOT_SESSION_START/STOP/RESCAN) belong to ATTENDANCE_MANAGEMENT and are only assigned to LECTURER and SUPERVISOR roles (not DATA_OPERATOR)
- All entity DELETE permissions (SEMESTER_DELETE, MAJOR_DELETE, ENROLLMENT_DELETE, ROOM_DELETE, CAMERA_DELETE, etc.) are NOT assigned to any role for safety - soft delete via UPDATE is preferred
- SLOT_CREATE/UPDATE/DELETE permissions apply to ALL slot categories (LECTURE, LECTURE_WITH_PT, FINAL_EXAM) - no separate permissions needed for FINAL_EXAM operations
- ENROLLMENT expanded from single MANAGE permission to full CRUD operations for more granular control
- STUDENT role has ROOM permissions but not CAMERA permissions (students need to know room locations but don't need camera details)

---

### Section 5: role_definitions

**Section Path:** `system_context.role_definitions`

**Current Content:**

- DATA_OPERATOR (59 permissions)
- LECTURER (28 permissions)
- SUPERVISOR (26 permissions)
- STUDENT (16 permissions)

**Status:** ✅ COMPLETED

**User Feedback:**

- All role definitions have been updated through Section 4 work
- Permission assignments align with role descriptions

**Updates Completed:**

- ✅ Updated DATA_OPERATOR: 59 permissions including all academic catalog, infrastructure, enrollment, attendance management, and reporting permissions (excludes DELETE and session management operations)
- ✅ Updated LECTURER: 28 permissions including session management (START/STOP/RESCAN), attendance management, reporting, and read access to all catalog entities
- ✅ Updated SUPERVISOR: 26 permissions similar to LECTURER but without SLOT_UPDATE_CATEGORY (focused on exam supervision)
- ✅ Updated STUDENT: 16 permissions including own schedule/attendance, read access to academic catalog and room entities

**Notes:**

- Permission counts increased due to READ → READ_LIST + READ_DETAIL splits
- LECTURER has SLOT_UPDATE_CATEGORY but SUPERVISOR doesn't (lecturers manage lecture slots, supervisors focus on exam sessions)
- Session management permissions (START/STOP/RESCAN) only assigned to LECTURER and SUPERVISOR
- DELETE permissions not assigned to any role for safety

---

### Section 6: function_catalog

**Section Path:** `system_context.function_catalog`

**Current Content:**

- common_functions (6 items)
- student_functions (4 items)
- lecturer_functions (7 items)
- supervisor_functions (6 items) ← NEW SECTION
- data_operator_functions (14 items)

**Status:** ✅ COMPLETED

**User Feedback:**

- Student có thể xem lịch học, lịch sử điểm danh của mình
- Lecturer và supervisor thì có thể xem lịch dạy, lịch thi, thực hiện điểm danh, xem các báo cáo các lớp, slot của mình
- DOP thì nên ghi rõ ra: quản lý kỳ học, ngành, lớp, môn, slot, camera, room, sinh viên, staff (mấy cái import nữa)

**Updates Needed:**

- ✅ Expanded student_functions from empty array to 4 specific items
- ✅ Expanded lecturer_functions from 1 to 7 specific items
- ✅ Added new supervisor_functions section with 6 items
- ✅ Restructured data_operator_functions from 11 generic items to 14 specific, detailed items

**Notes:**

- student_functions: Added view schedule, attendance history, slot details, notifications
- lecturer_functions: Added teaching schedule, session management, manual attendance, remarks, reports
- supervisor_functions: Similar to lecturer but focused on exam supervision
- data_operator_functions: Now explicitly lists all manageable entities with CRUD + import operations

---

### Section 7: screen_catalog - web_student_screens

**Section Path:** `system_context.screen_catalog.web_student_screens`

**Current Content:**

- SCR_STUDENT_DASHBOARD
- SCR_STUDENT_SCHEDULE (Calendar)
- SCR_STUDENT_ATTENDANCE_HISTORY
- SCR_STUDENT_PROFILE

**Total:** 4 screens (common screens moved to common_screens section)

**Status:** ✅ COMPLETED

**User Feedback:**

- Tạo common_screens để gộp các màn hình chung (LOGIN, FORGOT_PASSWORD, RESET_PASSWORD)
- Student có: dashboard, lịch học (calendar), lịch sử điểm danh, quản lý profile

**Updates Needed:**

- ✅ Created new common_screens section with 3 screens (SCR_LOGIN, SCR_FORGOT_PASSWORD, SCR_RESET_PASSWORD)
- ✅ Removed duplicate login/forgot/reset screens from student screens
- ✅ Simplified from 8 screens to 4 screens
- ✅ Added SCR_STUDENT_ATTENDANCE_HISTORY (new)
- ✅ Enhanced SCR_STUDENT_SCHEDULE with click-to-view-details
- ✅ Enhanced SCR_STUDENT_PROFILE with more details
- ✅ Removed SCR_STUDENT_SLOT_DETAILS (can view from schedule)
- ✅ Removed SCR_STUDENT_NOTIFICATIONS (not required)

**Notes:**

- common_screens applies to all platforms (Student Web, Lecturer Web, Admin Portal)
- Student screens now focus on core functionality: dashboard, schedule, attendance history, profile

---

### Section 8: screen_catalog - web_lecturer_screens

**Section Path:** `system_context.screen_catalog.web_lecturer_screens`

**Current Content:**

- SCR_LECTURER_DASHBOARD
- SCR_LECTURER_SCHEDULE_CALENDAR
- SCR_LECTURER_SCHEDULE_TABLE
- SCR_LECTURER_ATTENDANCE
- SCR_LECTURER_CLASS_SUMMARY
- SCR_LECTURER_PROFILE

**Total:** 6 screens

**Status:** ✅ COMPLETED

**User Feedback:**

- Lecturer có: dashboard, lịch học (calendar), lịch học (table - có thể update LECTURE ↔ LECTURE_WITH_PT), màn hình điểm danh, class summary, quản lý profile
- Lecturer không nhắc tới FINAL_EXAM (chỉ quản lý LECTURE/LECTURE_WITH_PT)
- Màn hình điểm danh có thể vào từ 2 màn hình lịch

**Updates Needed:**

- ✅ Removed SCR_LECTURER_LOGIN (moved to common_screens)
- ✅ Added SCR_LECTURER_DASHBOARD (new)
- ✅ Split SCR_LECTURER_SCHEDULE into Calendar and Table views
- ✅ Renamed SCR_LECTURER_ROSTER → SCR_LECTURER_ATTENDANCE
- ✅ Removed all references to FINAL_EXAM and exam supervision
- ✅ Added note: Attendance screen accessed from both Calendar and Table screens
- ✅ Renamed SCR_LECTURER_CLASS_REPORT → SCR_LECTURER_CLASS_SUMMARY
- ✅ Added SCR_LECTURER_PROFILE (new)
- ✅ Removed SCR_LECTURER_SLOT_DETAILS
- ✅ Removed SCR_LECTURER_REPORTS

**Notes:**

- Lecturer only manages LECTURE and LECTURE_WITH_PT slots (no FINAL_EXAM)
- Can update slot category between LECTURE ↔ LECTURE_WITH_PT in Table view
- Attendance screen is the main screen for conducting attendance during class

---

### Section 8b: screen_catalog - web_supervisor_screens

**Section Path:** `system_context.screen_catalog.web_supervisor_screens`

**Current Content:**

- SCR_SUPERVISOR_DASHBOARD
- SCR_SUPERVISOR_SCHEDULE_CALENDAR
- SCR_SUPERVISOR_SCHEDULE_TABLE
- SCR_SUPERVISOR_ATTENDANCE
- SCR_SUPERVISOR_EXAM_SUMMARY
- SCR_SUPERVISOR_PROFILE

**Total:** 6 screens

**Status:** ✅ COMPLETED

**User Feedback:**

- Supervisor tương tự lecturer nhưng chỉ quản lý FINAL_EXAM slots, không phải class

**Updates Needed:**

- ✅ Created new web_supervisor_screens section
- ✅ Added SCR_SUPERVISOR_DASHBOARD
- ✅ Added SCR_SUPERVISOR_SCHEDULE_CALENDAR (only FINAL_EXAM slots)
- ✅ Added SCR_SUPERVISOR_SCHEDULE_TABLE (only FINAL_EXAM slots)
- ✅ Added SCR_SUPERVISOR_ATTENDANCE (loads roster from exam_slot_participants)
- ✅ Added SCR_SUPERVISOR_EXAM_SUMMARY (slot-based, not class-based)
- ✅ Added SCR_SUPERVISOR_PROFILE

**Notes:**

- Supervisor only manages FINAL_EXAM slots
- Roster loaded from exam_slot_participants (not class enrollments)
- Has subject filter dropdown in attendance and summary screens
- Similar structure to lecturer but focused on exam supervision instead of teaching

---

### Section 9: screen_catalog - web_admin_portal_screens

**Section Path:** `system_context.screen_catalog.web_admin_portal_screens`

**Current Content:**

- SCR_ADMIN_DASHBOARD
- SCR_ADMIN_SEMESTER_MGMT
- SCR_ADMIN_MAJOR_MGMT
- SCR_ADMIN_SUBJECT_MGMT
- SCR_ADMIN_CLASS_MGMT
- SCR_ADMIN_CLASS_ENROLLMENT (sub-screen)
- SCR_ADMIN_CLASS_SLOT_MGMT
- SCR_ADMIN_SLOT_ATTENDANCE_ROSTER (sub-screen)
- SCR_ADMIN_EXAM_SLOT_MGMT
- SCR_ADMIN_EXAM_SLOT_PARTICIPANTS (sub-screen)
- SCR_ADMIN_EXAM_SLOT_ATTENDANCE_ROSTER (sub-screen)
- SCR_ADMIN_ROOM_MGMT
- SCR_ADMIN_CAMERA_MGMT
- SCR_ADMIN_USER_MGMT (2 tabs: Student, Staff)

**Total:** 14 screens (including 4 sub-screens)

**Status:** ✅ COMPLETED

**User Feedback:**

- DOP screens: dashboard, quản lý semester/major/subject/class (trong class dẫn đến screen quản lý sinh viên), quản lý slot của class (dẫn đến screen quản lý attendance roster), quản lý exam slot (dẫn đến screen quản lý exam participants và attendance roster riêng), quản lý room/camera, quản lý user (2 tabs: student và staff)
- Bulk identity import được tích hợp vào User Management

**Updates Needed:**

- ✅ Removed SCR_ADMIN_LOGIN (moved to common_screens)
- ✅ Split SCR_ADMIN_CRUD_ACADEMIC into 4 separate screens (Semester, Major, Subject, Class)
- ✅ Added SCR_ADMIN_CLASS_ENROLLMENT as sub-screen
- ✅ Split Slot Management into Class Slots and Exam Slots
- ✅ Added SCR_ADMIN_SLOT_ATTENDANCE_ROSTER as sub-screen for class slots
- ✅ Split Exam Slot management into Participants and Attendance Roster (2 sub-screens)
- ✅ Split SCR_ADMIN_INFRA_MGMT into Room and Camera screens
- ✅ Enhanced SCR_ADMIN_USER_MGMT with 2 tabs and integrated bulk identity import
- ✅ Removed SCR_ADMIN_EXPORT (integrated into entity management screens)
- ✅ Removed SCR_ADMIN_REPORTING (integrated into entity management screens)
- ✅ Removed SCR_ADMIN_BULK_ENROLLMENT (integrated into Class Enrollment screen)
- ✅ Removed SCR_ADMIN_BULK_IDENTITY_IMPORT (integrated into User Management tabs)

**Notes:**

- Each entity (Semester, Major, Subject, Class, etc.) now has its own dedicated management screen
- Sub-screens provide drill-down functionality for enrollment and attendance management
- Bulk import/export functionality is integrated into each entity management screen
- User Management has 2 tabs: Student tab includes student identity import, Staff tab includes staff identity import

---

### Section 10: complex_component_catalog

**Section Path:** `system_context.complex_component_catalog`

**Current Content:**

- (REMOVED - Section deleted)

**Status:** ✅ COMPLETED

**User Feedback:**

- Không cần phần này, xóa đi

**Updates Needed:**

- ✅ Removed entire complex_component_catalog section

**Notes:**

- Section was deemed unnecessary and removed from system_context.yaml
- Complex UI components will be documented in frontend codebase if needed

---

### Section 11: attendance_system

**Section Path:** `system_context.attendance_system`

**Current Content:**

- attendance_mode
- face_recognition (start_session_logic, rescan_logic_regular, rescan_logic_exam, key_difference, future_consideration)
- attendance_statuses (not_yet, present, absent)
- status_notes
- slot_control
- lecturer_ui_rules
- session_management (regular_sessions, exam_sessions, independence_principle, use_cases, scan_behavior_difference)

**Status:** ✅ COMPLETED

**User Feedback:**

- Cần clear logic điểm danh: có 2 chế độ (điểm danh thường và điểm danh thi)
- Start session (lần 1) giống nhau cho cả 2 chế độ
- Rescan có sự khác biệt: Regular sessions - not_yet students scanned vẫn giữ not_yet (manual approve); Exam sessions - not_yet students scanned tự động lên present
- Present students không quét được: Regular → xuống not_yet + giữ ảnh cũ; Exam → vẫn present

**Updates Needed:**

- ✅ Completely rewrote face_recognition section with new logic
- ✅ Added start_session_logic (same for both regular and exam)
- ✅ Added rescan_logic_regular (manual approval required)
- ✅ Added rescan_logic_exam (automatic promotion to present)
- ✅ Added key_difference to highlight the main distinction
- ✅ Added future_consideration for evidence image update policy
- ✅ Added scan_behavior_difference to session_management
- ✅ Updated face_identification_flow in technical_flows section (cross-reference)

**Notes:**

- The main difference is in rescan behavior: regular sessions require manual approval for not_yet→present, exam sessions automatically promote
- Evidence images are kept from first successful scan (policy may change in future)
- Dual-session management allows LECTURE_WITH_PT slots to track both regular and exam attendance independently

---

### Section 12: technical_flows

**Section Path:** `system_context.technical_flows`

**Current Content:**

- evidence_cleanup_flow
- face_identification_flow
- data_export_flow
- authentication_flow
- system_notification_flow
- username_password_auth_flow
- password_reset_flow
- daily_absence_calculation_flow
- bulk_identity_import_flow
- bulk_catalog_import_flow

**Total:** 10 flows

**Status:** ✅ COMPLETED

**User Feedback:**

- Review all technical flows for correctness and consistency

**Updates Needed:**

- ✅ Updated face_identification_flow to reflect new scan logic (done in Section 11 update)
- ✅ Updated bulk_identity_import_flow to fix screen reference:
  - Changed from 'SCR_ADMIN_BULK_IDENTITY_IMPORT' to 'SCR_ADMIN_USER_MGMT'
  - Updated description to clarify it works for both students and staff
  - Updated steps to reference Student tab and Staff tab
  - Added examples for both student IDs (HE180001) and staff IDs (EMP001)
  - Updated reporting step to reference SCR_ADMIN_USER_MGMT
- ✅ Verified remaining 8 flows are correct and up-to-date

**Notes:**

- face_identification_flow now references attendance_system.face_recognition section for complete scan logic
- bulk_identity_import_flow is now integrated into User Management tabs (no longer a separate screen)
- All flows use proper screen references after screen catalog restructuring

---

### Section 13: information_flows

**Section Path:** `system_context.information_flows`

**Current Content:**

- Student ↔ System
- Lecturer ↔ System
- Supervisor ↔ System
- System → External systems (SIS/LMS)
- System ↔ Python Recognition Service
- System ↔ Data Operations Staff (DOP)
- System ↔ Google

**Total:** 7 flows

**Status:** ✅ COMPLETED

**User Feedback:**

- Review all information flows for completeness and accuracy

**Updates Needed:**

- ✅ Updated Lecturer ↔ System flow:
  - Added: view teaching schedule
  - Changed "open/close slots" → "cancel/activate slots"
  - Expanded: start/stop/rescan attendance sessions (not just start)
  - Added: update slot category (LECTURE ↔ LECTURE_WITH_PT)
  - Added: manually update attendance status
  - Added: add attendance remarks
  - Added: view and export attendance reports

- ✅ Updated Supervisor ↔ System flow:
  - Added: view exam supervision schedule
  - Changed "open/close exam slots" → "cancel/activate exam slots"
  - Expanded: start/stop/rescan exam attendance sessions
  - Added: manually update attendance status
  - Added: add attendance remarks
  - Added: view and export exam attendance reports

- ✅ Updated System ↔ Data Operations Staff flow:
  - Added "(DOP)" clarification
  - Removed: "approve identity registrations" (no longer exists)
  - Expanded to list specific catalog management: semesters, majors, subjects, classes, slots
  - Expanded infrastructure: rooms, cameras
  - Expanded user management: students, staff
  - Added: manage enrollments and exam participants
  - Added: bulk import data via CSV
  - Added: view and export attendance reports
  - Added: manually update attendance for exception cases

- ✅ Verified remaining 4 flows are correct

**Notes:**

- All flows now accurately reflect the features and screens defined in screen_catalog
- Lecturer and Supervisor flows are clearly distinguished (regular vs exam)
- DOP flow now covers all management responsibilities

---

### Section 14: integrations

**Section Path:** `system_context.integrations`

**Current Content:**

- outbound_integrations (manual_export, api planned)
- integration_points (4 points: IP cameras via RTSP, Python recognition service via API, Google login, External systems via export)
- integration_method

**Status:** ✅ COMPLETED

**User Feedback:**

- Có vẻ OK rồi đấy

**Updates Needed:**

- ✅ No changes needed - all content is accurate and complete

**Notes:**

- Outbound integrations clearly describe manual export (CSV/JSON) with planned API endpoints
- Integration points accurately list 4 external system integrations
- Integration method correctly describes FUACS as source of truth with data sharing via export

---

### Section 15: data_policies

**Section Path:** `system_context.data_policies`

**Current Content:**

- import_policies (add_only, add_and_update modes)

**Status:** ✅ COMPLETED

**User Feedback:**

- Hệ thống có 2 import modes: add_only (skip existing, return error) và add_and_update (update existing records)
- Viết ở mức high-level, không cần quá chi tiết
- Bỏ conflict_resolution đi, không cần

**Updates Needed:**

- ✅ Added import_policies section with two modes:
  - add_only: Add new records only, skip existing and return as errors
  - add_and_update: Add new + update existing, uses Last-Write-Wins
- ✅ Deleted conflict_resolution section (not needed)

**Notes:**

- Written at high-level as requested, without excessive detail
- Both import modes skip invalid rows and collect them as errors for review

---

### Section 16: data_model

**Section Path:** `system_context.data_model`

**Current Content:**

- (REMOVED - Section deleted)

**Status:** ✅ COMPLETED

**User Feedback:**

- Không cần phần này khi mà đã có các file yaml trong docs/database/ rồi
- Xóa đi để tránh duplication

**Updates Needed:**

- ✅ Deleted entire data_model section including:
  - slot_entity_definition (with all field definitions)
  - enrollment_entity_definition

**Notes:**

- Section was redundant with docs/database/ schema files
- Removed to maintain single source of truth for database schema
- All database schema information should reference docs/database/ instead

---

### Section 17: idempotency_policies

**Section Path:** `system_context.idempotency_policies`

**Current Content:**

- (REMOVED - Section deleted)

**Status:** ✅ COMPLETED

**User Feedback:**

- Xóa luôn section này đi

**Updates Needed:**

- ✅ Deleted entire idempotency_policies section including:
  - unique_constraints (enrollments, attendance_records)
  - keys (slot_enrollment, attendance, slot_announcement, pre_slot_message)

**Notes:**

- Section was deemed unnecessary and removed
- Database constraints are documented in schema files

---

### Section 18: assumptions

**Section Path:** `system_context.assumptions`

**Current Content:**

- (REMOVED - Section deleted)

**Status:** ✅ COMPLETED

**User Feedback:**

- Xóa luôn section này đi

**Updates Needed:**

- ✅ Deleted entire assumptions section including:
  - reconciliation_report
  - idempotency_key
  - base_image_quality
  - single_slot_assignment

**Notes:**

- Section was deemed unnecessary and removed
- Business assumptions are implicit in the implementation

---

### Section 19: terminology_notes

**Section Path:** `system_context.terminology_notes`

**Current Content:**

- (REMOVED - Section deleted)

**Status:** ✅ COMPLETED

**User Feedback:**

- Xóa section này đi, nó liên quan đến database và đã có trong docs/database/ rồi

**Updates Needed:**

- ✅ Deleted entire terminology_notes section including:
  - principles (2 items)
  - dictionary (5 terms: slot, roster, supervisor, system_notification, automated_attendance, attendance_status_values)
  - mappings (1 mapping)

**Notes:**

- Section was deemed redundant and removed to avoid duplication
- Terminology can be inferred from code and schema files

---

### Section 20: tech_stack

**Section Path:** `system_context.tech_stack`

**Current Content:**

- frontend.web (Next.js, shadcn/ui)
- backend.main_service (Java Spring Boot, JDK 21+)
- backend.recognition_service (Python FastAPI)
- database.primary_database (PostgreSQL with pgvector)

**Status:** ✅ COMPLETED

**User Feedback:**

- OK đấy, không cần thay đổi gì

**Updates Needed:**

- ✅ No changes needed

**Notes:**

- All tech stack information is accurate and current
- Mobile app references already removed in Section 2

---

### Section 21: implementation_decisions

**Section Path:** `system_context.implementation_decisions`

**Current Content:**

- backend_validation_only (2 decisions)
- explicitly_not_implemented (5 decisions)
- slot_management_clarifications (1 decision)
- validation_and_constraints_clarifications (3 decisions)
- timezone_and_scheduling_clarifications (1 decision)

**Total:** 12 documented decisions

**Status:** ✅ COMPLETED

**User Feedback:**

- Xóa "Identity Submission Retry Limit" - không còn feature này
- Xóa "Link Password to Google Account" - không implement
- Xóa "Attendance History Table" - không còn operational_audit_logs table
- Xóa "System Admin Role/Permission Management Use Cases" - không document
- Update timezone thành Vietnam timezone only (ICT/Asia/Ho_Chi_Minh, UTC+7)

**Updates Needed:**

- ✅ Deleted "Identity Submission Retry Limit" from explicitly_not_implemented
- ✅ Deleted "Link Password to Google Account" from explicitly_not_implemented
- ✅ Deleted "Attendance History Table" from explicitly_not_implemented
- ✅ Deleted "System Admin Role/Permission Management Use Cases" from explicitly_not_implemented
- ✅ Updated timezone_and_scheduling_clarifications:
  - Changed item name from "Daily Absence Calculation Job Timezone" to "System Timezone"
  - Updated decision to "Vietnam timezone only (ICT/Asia/Ho_Chi_Minh, UTC+7)"
  - Updated reason to clarify system is designed for Vietnam market only
  - Changed status to "FINAL - System operates in Vietnam timezone"

**Notes:**

- Reduced from 15 to 12 decisions after removing 4 obsolete items
- explicitly_not_implemented now has 5 items (was 9)
- Timezone clarification now explicitly states Vietnam timezone only

---

### Section 22: to_be_discussed_or_backlog

**Section Path:** `system_context.to_be_discussed_or_backlog`

**Current Content:**

- Dashboard Design
- API Integration
- Conflict resolution with external systems
- Upgrade Backend-Service communication mechanism

**Total:** 4 backlog items

**Status:** ✅ COMPLETED

**User Feedback:**

- Xóa "Identity Re-registration details" - không cần
- Xóa "Mobile for Lecturers" - không cần
- Xóa "Standardize reasons/forms" - không cần

**Updates Needed:**

- ✅ Deleted "Standardize reasons/forms: If upgrading 'Slot Announcement' to a standardized approval (request) flow in the future"
- ✅ Deleted "Identity Re-registration details: Consider policy 'only 1 pending request per type' and related UX"
- ✅ Deleted "Mobile for Lecturers: Evaluate needs and scope if expanding"

**Notes:**

- Reduced from 7 to 4 backlog items
- Remaining items focus on integration, architecture, and dashboard design

---

### Section 23: notes

**Section Path:** `system_context.notes`

**Current Content:**

- All data is managed and filtered by Semester
- Primary platform for Lecturers & Supervisors is Web
- User accounts are created and managed directly in the system by Data Operator

**Total:** 3 notes

**Status:** ⏳ PENDING REVIEW

**User Feedback:**

- (to be filled during review)

**Updates Needed:**

- (to be filled if changes required)

**Notes:**

- (to be filled with any additional context)

---

### Section 24: in_scope_functions

**Section Path:** `system_context.in_scope_functions`

**Current Content:**

- slot_interactions: "Lecturers/TAs add remarks to attendance records; Students view slot information."

**Status:** ⏳ PENDING REVIEW

**User Feedback:**

- (to be filled during review)

**Updates Needed:**

- (to be filled if changes required)

**Notes:**

- (to be filled with any additional context)

---

## Review Guidelines

1. **For each section:**
   - Read current content carefully
   - Answer user's verification questions
   - If correct → mark as ✅ and move to next section
   - If incorrect → document what needs to be updated
   - If unsure → investigate codebase to verify

2. **When investigating codebase:**
   - Backend: Check entities, enums, services in `backend/src/main/java/com/fuacs/backend/`
   - Frontend: Check pages, components in relevant directories
   - Database: Check migrations in `backend/src/main/resources/db/migration/`

3. **Update documentation:**
   - Fill in "User Feedback" with verification results
   - Fill in "Updates Needed" if changes are required
   - Add any important notes in "Notes" section
   - Mark section as ✅ when complete

4. **Context management:**
   - This checklist allows continuing work across multiple sessions
   - Always check which sections are already ✅ before resuming
   - Update "Last Updated" date when making changes
