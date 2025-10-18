# FUACS - System Context Documentation

**Project Code:** FUACS  
**Project Name:** FU Attendance Checking Smart  

---

## Project Overview

### Background

An independent attendance and academic management system. FUACS serves as the Single Source of Record for all data related to classes, students, lecturers, and attendance results.

### Goal

Support login via Google and system accounts (username/password), class schedules, exam schedules, and smart attendance to assist lecturers.

---

## Platform Definitions

### Platform Types

- **MOBILE_APP**: Mobile platform for iOS and Android
- **GENERAL_WEB**: Web platform
- **ADMIN_PORTAL**: Web platform (Admin Portal)

### Role-Platform Mapping

- **Student**: MOBILE_APP
- **Lecturer**: GENERAL_WEB
- **Supervisor**: GENERAL_WEB
- **Data Operator**: ADMIN_PORTAL
- **System Admin**: ADMIN_PORTAL

---

## Authentication and Role Mapping

### Mapping Method

System Native

Users are created and role-managed directly in the system by Data Operators. The primary login identifier (username) is defined as the Student ID or Employee ID. The system supports Google login (for email verification) and direct login using username/password. The system uses specialized profiles (student_profiles, staff_profiles) to manage specific attributes.

### Role Assignment Rules

SUPERVISOR or LECTURER roles cannot be assigned to users with the STUDENT role.

### Access Control

- **On Missing User**: deny_access_403
- **On Inactive Status**: deny_access_403

---

## Master Permission Catalog

### USER_MANAGEMENT

- **USER_CREATE**: Create a new user account.
- **USER_READ_LIST**: View the list of all users.
- **USER_READ_DETAIL**: View detailed information of a user.
- **USER_UPDATE_INFO**: Update user personal information (name, email).
- **USER_UPDATE_STATUS**: Deactivate or activate user account (soft delete).
- **USER_DELETE_HARD**: Permanently delete user account (dangerous action, requires consideration).
- **USER_ASSIGN_ROLES**: Assign or revoke roles from a user.
- **CREATE_SYSTEM_ADMIN**: Create an account with System Admin role (extremely sensitive permission, only for system setup purposes).

### IDENTITY_MANAGEMENT

- **IDENTITY_SUBMISSION_READ_QUEUE**: View the list of pending identity verification requests.
- **IDENTITY_SUBMISSION_READ_DETAIL**: View details of an identity verification request (video, ID card).
- **IDENTITY_SUBMISSION_APPROVE**: Approve an identity verification request.
- **IDENTITY_SUBMISSION_REJECT**: Reject an identity verification request.

### ACADEMIC_CATALOG_MANAGEMENT

- **SEMESTER_CREATE**: Create a new semester.
- **SEMESTER_READ**: View the list and details of semesters.
- **SEMESTER_UPDATE**: Update semester information.
- **SEMESTER_DELETE**: Deactivate a semester.
- **MAJOR_CREATE**: Create a new major.
- **MAJOR_READ**: View the list and details of majors.
- **MAJOR_UPDATE**: Update major information.
- **MAJOR_DELETE**: Deactivate a major.
- **SUBJECT_CREATE**: Create a new subject.
- **SUBJECT_READ**: View the list and details of subjects.
- **SUBJECT_UPDATE**: Update subject information.
- **SUBJECT_DELETE**: Deactivate a subject.
- **CLASS_CREATE**: Create a new class.
- **CLASS_READ**: View the list and details of classes.
- **CLASS_UPDATE**: Update class information.
- **CLASS_DELETE**: Deactivate a class.
- **SLOT_CREATE**: Create a new lecture/exam slot.
- **SLOT_READ**: View the list and details of lecture/exam slots.
- **SLOT_UPDATE**: Update lecture/exam slot information.
- **SLOT_DELETE**: Cancel a lecture/exam slot.
- **ENROLLMENT_MANAGE**: Add or remove students from a class.

### INFRASTRUCTURE_MANAGEMENT

- **ROOM_CREATE**: Create a new room.
- **ROOM_READ**: View the list and details of rooms.
- **ROOM_UPDATE**: Update room information.
- **ROOM_DELETE**: Delete a room.
- **CAMERA_CREATE**: Create a new camera and assign it to a room.
- **CAMERA_READ**: View the list and details of cameras.
- **CAMERA_UPDATE**: Update camera information.
- **CAMERA_DELETE**: Delete a camera.

### ATTENDANCE_MANAGEMENT

- **OWN_SCHEDULE_READ**: View personal schedule (teaching/exam/learning).
- **SLOT_SESSION_START**: Start an automated attendance session for a slot.
- **SLOT_SESSION_RESCAN**: Trigger a re-scan for attendance.
- **SLOT_SESSION_FINALIZE**: Finalize and complete the attendance session.
- **ATTENDANCE_ROSTER_READ**: View the roster and real-time attendance status of a slot.
- **ATTENDANCE_STATUS_UPDATE_MANUAL**: Manually update attendance status for students.
- **ATTENDANCE_REMARK_MANAGE**: Add, edit, delete attendance remarks.
- **SLOT_ANNOUNCEMENT_MANAGE**: Manage (create/delete) slot announcements.
- **PRE_SLOT_MESSAGE_READ**: Read pre-slot messages sent by students.
- **PRE_SLOT_MESSAGE_ACKNOWLEDGE**: Mark student messages as read/acknowledged.

### REPORTING_AND_DATA

- **REPORT_READ_OWN_SLOT**: View attendance reports for slots under own responsibility.
- **REPORT_EXPORT_OWN_SLOT**: Export report files for slots under own responsibility.
- **REPORT_READ_CLASS_SUMMARY**: View comprehensive attendance summary report for a class.
- **REPORT_READ_SYSTEM_WIDE**: View system-wide summary reports.
- **REPORT_EXPORT_ACADEMIC_DATA**: Export academic data (class lists, attendance results, etc.).
- **AUDIT_LOG_READ**: View audit logs of important business data changes.

### SYSTEM_ADMINISTRATION

- **SYSTEM_CONFIG_READ**: View system configurations.
- **SYSTEM_CONFIG_UPDATE**: Modify system configurations.
- **ROLE_PERMISSION_MAPPING_READ**: View role-permission mapping matrix.
- **ROLE_PERMISSION_MAPPING_UPDATE**: Edit role-permission mapping matrix.
- **SYSTEM_LOG_READ**: View technical system activity logs.
- **NOTIFICATION_TEMPLATE_MANAGE**: Manage system notification templates.

### STUDENT_PERMISSIONS

- **OWN_ATTENDANCE_HISTORY_READ**: View own attendance history.
- **OWN_IDENTITY_SUBMIT**: Submit identity registration or update request.
- **PRE_SLOT_MESSAGE_CREATE**: Send pre-slot message to lecturer.

### GENERAL_PERMISSIONS

- **OWN_PROFILE_READ**: View own personal profile information.
- **OWN_PASSWORD_UPDATE**: Change own password.

---

## Role Definitions

### SYSTEM_ADMIN

**Role Name**: System Administrator

**Description**: The highest technical role, responsible for defining policies, system configuration, and managing the permission structure of roles. Does not manage user accounts or intervene in daily operations.

**Platform**: ADMIN_PORTAL

**Permissions**: SYSTEM_CONFIG_READ, SYSTEM_CONFIG_UPDATE, ROLE_PERMISSION_MAPPING_READ, ROLE_PERMISSION_MAPPING_UPDATE, SYSTEM_LOG_READ, NOTIFICATION_TEMPLATE_MANAGE, OWN_PROFILE_READ, OWN_PASSWORD_UPDATE

### DATA_OPERATOR

**Role Name**: Data Operations Staff

**Description**: The main operational role, responsible for all academic data and user account lifecycle management.

**Platform**: ADMIN_PORTAL

**Permissions**: USER_CREATE, USER_READ_LIST, USER_READ_DETAIL, USER_UPDATE_INFO, USER_UPDATE_STATUS, USER_ASSIGN_ROLES, IDENTITY_SUBMISSION_READ_QUEUE, IDENTITY_SUBMISSION_READ_DETAIL, IDENTITY_SUBMISSION_APPROVE, IDENTITY_SUBMISSION_REJECT, SEMESTER_CREATE, SEMESTER_READ, SEMESTER_UPDATE, SEMESTER_DELETE, MAJOR_CREATE, MAJOR_READ, MAJOR_UPDATE, MAJOR_DELETE, SUBJECT_CREATE, SUBJECT_READ, SUBJECT_UPDATE, SUBJECT_DELETE, CLASS_CREATE, CLASS_READ, CLASS_UPDATE, CLASS_DELETE, SLOT_CREATE, SLOT_READ, SLOT_UPDATE, SLOT_DELETE, ENROLLMENT_MANAGE, ROOM_CREATE, ROOM_READ, ROOM_UPDATE, ROOM_DELETE, CAMERA_CREATE, CAMERA_READ, CAMERA_UPDATE, CAMERA_DELETE, REPORT_READ_SYSTEM_WIDE, REPORT_EXPORT_ACADEMIC_DATA, AUDIT_LOG_READ, OWN_PROFILE_READ, OWN_PASSWORD_UPDATE

### LECTURER

**Role Name**: Lecturer

**Description**: Responsible for managing lecture sessions, monitoring class rosters, and finalizing attendance results.

**Platform**: GENERAL_WEB

**Permissions**: OWN_SCHEDULE_READ, SLOT_SESSION_START, SLOT_SESSION_RESCAN, SLOT_SESSION_FINALIZE, ATTENDANCE_ROSTER_READ, ATTENDANCE_STATUS_UPDATE_MANUAL, ATTENDANCE_REMARK_MANAGE, SLOT_ANNOUNCEMENT_MANAGE, PRE_SLOT_MESSAGE_READ, PRE_SLOT_MESSAGE_ACKNOWLEDGE, REPORT_READ_OWN_SLOT, REPORT_EXPORT_OWN_SLOT, REPORT_READ_CLASS_SUMMARY, OWN_PROFILE_READ, OWN_PASSWORD_UPDATE

### SUPERVISOR

**Role Name**: Exam Supervisor

**Description**: Responsible for supervising exam sessions, initiating and finalizing attendance results for exams.

**Platform**: GENERAL_WEB

**Permissions**: OWN_SCHEDULE_READ, SLOT_SESSION_START, SLOT_SESSION_RESCAN, SLOT_SESSION_FINALIZE, ATTENDANCE_ROSTER_READ, ATTENDANCE_STATUS_UPDATE_MANUAL, ATTENDANCE_REMARK_MANAGE, REPORT_READ_OWN_SLOT, REPORT_EXPORT_OWN_SLOT, OWN_PROFILE_READ, OWN_PASSWORD_UPDATE

### STUDENT

**Role Name**: Student

**Description**: Uses the system to track schedules, view attendance history, and send notifications.

**Platform**: MOBILE_APP

**Permissions**: OWN_SCHEDULE_READ, OWN_ATTENDANCE_HISTORY_READ, OWN_IDENTITY_SUBMIT, PRE_SLOT_MESSAGE_CREATE, OWN_PROFILE_READ, OWN_PASSWORD_UPDATE

---

## Function Catalog

### Common Functions

- Role-based access control
- Import/Export data
- System notifications
- Search & filter
- Role-based dashboard
- Activity logs
- Reports & file export

### Student Functions

- Send pre-slot message (text + URL) to lecturer/TA before T0

### Lecturer Functions

- Attach announcements to slots
- View & mark pre-slot messages from students as read
- View comprehensive attendance reports by class/semester

### Data Operator Functions

- Manage Semesters
- Manage academic catalogs
- Receive and export attendance reports
- Query & reconcile data
- Manage & Review identity registration submissions
- Manage user accounts
- Manage slot enrollment
- Export academic data
- Manage Camera and Room catalogs
- View operational activity logs
- Manage Majors

### System Admin Functions

- Configure system (AI model, similarity threshold, etc.)
- Monitor logs and anomalous data
- Manage permission catalog & Role-Permission mapping
- Manage system notification templates

---

## Screen Catalog

### Mobile Student Screens

#### SCR-STUDENT-LOGIN - Login Screen

**Features**:

- Google login
- Username and Password login form
- 'Forgot Password?' link

#### SCR-STUDENT-DASHBOARD - Home Screen/Dashboard

**Features**:

- View upcoming lecture/exam slots
- Shortcuts to main functions

#### SCR-STUDENT-SCHEDULE - Schedule Screen

**Features**:

- Semester selector
- Filter Lecture/Exam schedule
- View schedule in week/month format

#### SCR-STUDENT-SLOT-DETAILS - Slot Details Screen

**Features**:

- View detailed slot information (including slot type: LECTURE or EXAM)
- View notes from lecturer (read-only)
- Form to 'Send pre-slot message (text + URL) to lecturer/TA' (only available for slot_type = LECTURE and before T0)
- Note: Pre-slot message does NOT change attendance status; it is only a communication channel before T0. The system will display a warning about this before sending.

#### SCR-STUDENT-IDENTITY-REG - Identity Registration Screens

**Features**:

- Identity registration instructions
- Face video recording interface
- ID card photo capture interface
- Waiting screen/approval result notification

#### SCR-STUDENT-PROFILE - Profile Screen

**Features**:

- 'Request Identity Update' button
- 'Change Password' function

#### SCR-STUDENT-NOTIFICATIONS - Notifications Inbox

**Features**:

- Combined feed: System notifications + Slot announcements (from lecturer) + Tab to view 'Messages you sent'
- Filters: All | System notifications | Slot notifications (from lecturer) | Messages you sent | Identity requests
- Unread indicator at notification level and filter level
- View notification details

#### SCR-STUDENT-FORGOT-PASSWORD - Forgot Password Screen

**Features**:

- Email input form to receive reset link
- 'Send Request' button

#### SCR-STUDENT-RESET-PASSWORD - Reset Password Screen

**Features**:

- New password and confirm password input form
- 'Reset Password' button

### Web Lecturer Screens

#### SCR-LECTURER-LOGIN - Login Screen

**Features**:

- Google login
- Username and Password login form
- 'Forgot Password?' link

#### SCR-LECTURER-SCHEDULE - Schedule & Slots

**Features**:

- View teaching schedule and exam supervision schedule by semester on a unified interface
- Advanced filters to filter lecture/exam slots by multiple criteria, including 'Type' (slot_type: LECTURE, EXAM)
- Open/Close/Finalize slot

#### SCR-LECTURER-ROSTER - Roster & Attendance

**Features**:

- Interface displays appropriate functions based on role (Lecturer, Supervisor) and slot type (LECTURE, EXAM)
- Display camera name and connection status of the room assigned to the slot
- Interface updates attendance status in real-time from recognition service results
- Review/edit status
- Add/Edit attendance remarks for each student
- Update student notification status (acknowledge/read) (only for Lecturer & LECTURE slot)
- 'Pre-slot Inbox' tab (view/search, mark as read/ack) (only for Lecturer & LECTURE slot)
- Multi-state 'Start Attendance / Re-scan' button to trigger scan sessions
- Detail window displays attendance history (timeline) for each student when requested
- Manual attendance edit window, requires mandatory reason (remark) input when changing status
- 'Finalization Rules Setup' screen displays when finalizing slot to batch process undetermined statuses

#### SCR-LECTURER-SLOT-DETAILS - Slot Details

**Features**:

- 'Announcements' tab (create/edit/delete announcements attached to slot) (only for Lecturer & LECTURE slot)

#### SCR-LECTURER-REPORTS - Slot Reports

**Features**:

- View/Export reports by slot/class
- Includes pre-slot message log (reference) separated from attendance table

#### SCR-LECTURER-CLASS-REPORT - Class Attendance Report Screen

**Features**:

- Filter to select Semester and Class
- Display summary report in table (matrix) format: students by rows, slots by columns
- Display attendance status (Present/Absent/Not Yet) in table cells
- Function to export summary report to file (CSV, Excel)

### Web Admin Portal Screens

#### SCR-ADMIN-LOGIN - Login Screen

**Features**:

- Google login
- Username and Password login form
- 'Forgot Password?' link

#### SCR-ADMIN-DASHBOARD - Admin Dashboard

**Features**:

- Overview charts
- Semester filter
- Permission-based display

#### SCR-ADMIN-EXPORT - Data Export Screen (Data Operator)

**Features**:

- Interface to configure and execute academic data export (CSV, JSON, etc.)
- View export history

#### SCR-ADMIN-CRUD-ACADEMIC - CRUD Screens (Data Operator)

**Features**:

- Manage Classes, Subjects, Lecture/Exam Schedules (including slot_type and room_id attributes)
- Add/Remove students from a class (Roster Management)
- Manage Majors

#### SCR-ADMIN-REPORTING - Reporting & Lookup Screen (Data Operator)

**Features**:

- Advanced search filters
- View and export custom reports

#### SCR-ADMIN-AUDIT-LOGS - Operational Audit Log Viewer (Data Operator)

**Features**:

- View history of business data changes (who, what, when)
- Filter by actor, action type, and time range

#### SCR-ADMIN-IDENTITY-QUEUE - Identity Registration Approval Queue (Data Operator)

**Features**:

- List of pending identity registration/update requests
- Interface to compare information (new photo, old photo, ID card)
- Approve/Reject buttons (with reason)

#### SCR-ADMIN-USER-MGMT - User & Role Management (Data Operator)

**Features**:

- Add/Edit/Delete accounts
- Assign one or more roles to users (LECTURER, SUPERVISOR, STUDENT); includes constraint check to not assign SUPERVISOR/LECTURER to STUDENT
- Does NOT edit permission catalog or Role-Permission mapping
- Create specialized profiles (Student/Staff)

#### SCR-ADMIN-INFRA-MGMT - Camera & Room Management (Data Operator)

**Features**:

- Add/Edit/Delete room information
- Add/Edit/Delete camera information (Name, RTSP connection string, Status)
- Assign a camera to a room
- View list of all cameras and rooms in the system

#### SCR-SYSADMIN-CONFIG - System Configuration (System Admin)

**Features**:

- Configure AI model
- Manage permission catalog & Role-Permission mapping

#### SCR-SYSADMIN-LOGS - System Logs Viewer (System Admin)

**Features**:

- View and filter system logs

#### SCR-SYSADMIN-NOTIF-TEMPLATES - Notification Template Management (System Admin)

**Features**:

- CRUD system notification templates

---

## Complex Component Catalog

### COMPLEX-SEMESTER-DATATABLE - Semester Data Table

**Description**: A reusable data table for displaying and managing semesters. Includes sorting, filtering, and pagination.

**Required Features**:

- CRUD operations on Semester data

---

## Attendance System

### Attendance Mode

The only attendance mode, activated by Lecturer (for lecture slots) or Supervisor (for exam slots). The system uses IP cameras pre-installed in classrooms to automatically recognize and record student presence. A Python middleware service processes video streams and sends results back to the system.

### Face Recognition

**Decision Flow Summary**: Face scan has 2 possible outcomes only

**Outcomes**:

- match => set attendance = present
- no_match => no-op (person in charge marks attendance manually)

### Attendance Statuses

- not_yet
- present
- absent
- Absent After Present

### Status Notes

The system does not distinguish between 'excused absence' and 'unexcused absence' at the status level. All absences are recorded as 'absent'. Lecturers or Supervisors can use the remark function to provide context when necessary.

### Slot Control

**Open By**: Lecturer/Supervisor

**Finalize By**: Lecturer/Supervisor

**Finalization Logic**: When a lecturer finalizes a slot, the system displays a 'Finalization Rules Setup' screen. This screen allows the lecturer to batch decide how students with intermediate statuses (Not Yet, Absent After Present) will be converted to final statuses (Present or Absent).

**Editability Rules**: After the first finalization (first_submission), Lecturer/Supervisor can edit attendance results until 23:59:59 of that day. After this time, the data will be locked for them. Exception cases need to be handled by Data Operator.

**Finalization Audit Trail Note**: Information about the user who performed the finalization action (finalize_by) is comprehensively recorded in the 'operational_audit_logs' table. This design adheres to the Single Source of Truth principle, avoids data duplication, and provides complete history of actions (finalize, reopen, re-finalize) instead of just storing the final state in the 'slots' table.

### Lecturer UI Rules

**Description**: Rules on the lecturer/supervisor attendance screen.

**Real-time Update**: Attendance status is updated in real-time as soon as the recognition service sends successful results.

**Finalization Confirmation**: The system must display a warning dialog and request confirmation if the user finalizes a lecture/exam slot while there are still students in 'not_yet' status.

---

## Technical Flows

### Identity Registration Flow

A one-time process for students to register their identity. Students record a face video and take an ID card photo. The data is then sent to Data Operator for manual approval. Approved data becomes the base image.

### Identity Re-registration Flow

Students can submit a request to update their identity photo (only need to record face video, no ID card needed). This request also requires Data Operator approval. During the waiting period, the system still uses the old photo for attendance.

### Identity Submission Rejection Flow

When Data Operator rejects an identity registration/update request, the system automatically sends a system notification to the student. This notification includes the rejection reason and will appear in the student's Notification Inbox.

### Face Identification Flow

When a lecturer starts a scan session, the system retrieves the student list and assigned cameras. The Python service processes video streams and calls the Backend API to record results. For each scan, the system adds a new event to the student's history record and updates the displayed status on the interface based on the latest result. This process does not overwrite old data.

### Data Export Flow

This is a manual flow performed by Data Operator. The user accesses the 'Data Export' screen on the Admin Portal, selects data type (e.g., attendance results), file format (CSV, JSON), and necessary filters. The system then generates the file and allows the user to download it for import into external systems like SIS/LMS.

### Authentication Flow

Users on all platforms (Web, Mobile) can log in with Google. Upon successful authentication, Google provides an email address. The FUACS system uses this email address to directly look up the corresponding user account that already exists in the system. If an active account with a matching email is found, the system grants a session token with the permissions assigned to that user. This flow is entirely based on email matching.

### System Notification Flow

When a business event occurs (e.g., identity rejection), the system finds an appropriate notification template, creates a delivery record for the target user, and sends a push notification.

### Username Password Auth Flow

User enters username and password. Backend finds user by username, then uses a hashing algorithm (e.g., bcrypt) to compare the entered password with the password_hash stored in the database. If matched, grants session token.

### Password Reset Flow

User enters email. System creates a unique, time-limited reset token, saves it to the database, and sends an email containing the reset link. When the user accesses the link, the system validates the token, allows them to enter a new password, hashes and updates the password_hash, then invalidates the used token.

---

## Information Flows

- Student ↔ System: view schedule/slots; send messages to lecturer; view status
- Lecturer ↔ System: open/finalize slots; start automated attendance session; read/ack pre-slot messages from students; review/edit status before finalizing
- Supervisor ↔ System: open/finalize exam slots; start automated attendance session; review/edit status
- System → External systems (SIS/LMS): export academic data and attendance results on demand
- System ↔ Python Recognition Service: send session start request; receive attendance results
- System ↔ Data Operations Staff: attendance reports, catalog management and data synchronization; approve identity registrations; manage user accounts; manage rooms and cameras; review activity history
- System ↔ System Administrator: monitor and configure system
- System ↔ Google: login & basic profile

---

## Integrations

### Outbound Integrations

**Description**: FUACS shares data with external systems via manual export. API integration is a planned item for the future.

**Methods**:

#### Manual Export

- **Formats**: CSV, JSON
- **Data Scopes**: attendance_summary, full_roster, academic_catalogs

#### API

- **Status**: planned
- **Endpoints**: get_roster, get_attendance_by_class

### Integration Points

- Dedicated IP camera system in classrooms (receive video stream via RTSP)
- Python recognition service (communicate via API)
- Google: login and basic profile
- External systems (if any): Receive data from FUACS (currently export; API planned)

### Integration Method

The system operates independently and is the source of original data. Data is shared with other systems via export function; API integration is planned for the future.

---

## Data Policies

### Conflict Resolution

**Strategy**: Last-Write-Wins

**Granularity**: field-level

**Description**: The later updated value (by import or in-system operation) wins for each field. Priority rules between FUACS data and external systems will be discussed in detail later.

---

## Data Model

### Slot Entity Definition

**Description**: Additional definition for the Slot entity to support business classification.

**Fields**:

#### slot_type

- **Type**: Varchar
- **Required**: true
- **Description**: Classifies a slot as a lecture ('LECTURE') or exam ('EXAM'). The value is stored directly in the slots table to simplify the data model, adhering to the current database schema.

#### room_id

- **Type**: Reference
- **Target Entity**: Room
- **Required**: true
- **Description**: ID of the room where this slot takes place. Used to determine which camera to use.

### Enrollment Entity Definition

**Description**: Definition of enrollment record.

**Fields**:

#### status

- **Type**: Boolean
- **Default**: true
- **Description**: Acts as a 'soft delete switch'. When a student withdraws from a course, this field is updated to 'false'. This hides the student from future slots but preserves all enrollment and attendance history data for reporting and audit purposes.

---

## Idempotency Policies

### Unique Constraints

- enrollments: (class_id, student_user_id) is unique
- attendance_records: (student_user_id, slot_id) is unique

### Keys

- **slot_enrollment**: class_id + student_user_id
- **attendance**: student_user_id + slot_id
- **slot_announcement**: id (bigint)
- **pre_slot_message**: id (bigint)

---

## Assumptions

- **Reconciliation Report**: true
- **Idempotency Key**: slot_id + student_id
- **Base Image Quality**: The system assumes that students will provide identity video/photos with sufficient quality for recognition. The system does not have input quality enforcement mechanisms.
- **Single Slot Assignment**: In the current version, each slot is assigned to one and only one staff member (Lecturer or Supervisor).

---

## Terminology Notes

### Principles

- UI uses Vietnamese as primary; first occurrence in each screen/section may include English terminology in parentheses
- Permissions use UPPER_SNAKE_CASE; concepts use snake_case

### Dictionary

#### Slot

- **UI Label**: Buổi học/thi (Slot)
- **Concept Key**: slot
- **Description**: A unit of lecture or exam session in the schedule.

#### Roster

- **UI Label**: Danh sách lớp (Roster)
- **Concept Key**: roster
- **Description**: Student list of a slot used to monitor and review attendance status.

#### Supervisor

- **UI Label**: Giám thị (Supervisor)
- **Concept Key**: supervisor
- **Description**: Person responsible for supervising and taking attendance for an exam slot.

#### Pre-slot Message

- **UI Label**: Tin nhắn trước buổi học (Pre-slot Message)
- **Concept Key**: pre_slot_message
- **Description**: Student sends privately to lecturer/TA of the slot (text + URL), only before T0. This function does not affect attendance status in any form and is only for providing reference information to the lecturer.

#### Slot Announcement

- **UI Label**: Thông báo của buổi học (Slot Announcement)
- **Concept Key**: slot_announcement
- **Description**: Announcement (title + text) attached to a slot by lecturer/TA; displayed to all students enrolled in the slot; can be pinned.

#### System Notification

- **UI Label**: Thông báo hệ thống (System Notification)
- **Concept Key**: system_notification
- **Description**: Notification issued by the system to target users.

#### Automated Attendance

- **UI Label**: Điểm danh tự động (Automated Attendance)
- **Description**: System automatically takes attendance via IP cameras.

#### Attendance Status Values

- **UI Label**: Trạng thái điểm danh (Attendance Statuses)
- **Values**: not_yet, present, absent

### Mappings

- **UI Label**: Update student notification status → **Permission**: ACKNOWLEDGE_STUDENT_NOTIFICATION
- **UI Label**: Send message to lecturer → **Concept**: pre_slot_message
- **UI Label**: Slot announcement → **Concept**: slot_announcement
- **UI Label**: System notification → **Concept**: system_notification

---

## Tech Stack

### Frontend

#### Web

- **Description**: Web platform for Lecturers, Supervisors, and Admin
- **Technology**: Next.js
- **UI Library**: shadcn/ui

#### Mobile App

- **Description**: Mobile application for Students
- **Technology**: React Native

### Backend

#### Main Service

- **Description**: Main service handling business logic
- **Technology**: Java (Spring Boot)
- **Runtime**: JDK 21+

#### Recognition Service

- **Description**: Service handling face recognition
- **Technology**: Python (FastAPI)

### Database

#### Primary Database

- **Technology**: PostgreSQL
- **Extensions**: pgvector

---

## To Be Discussed or Backlog

- **Dashboard Design**: Finalize KPIs displayed for each role
- **Standardize reasons/forms**: If upgrading 'Slot Announcement' to a standardized approval (request) flow in the future
- **API Integration**: Define scope/security/throttling/response format for planned endpoints
- **Conflict resolution with external systems (SIS/LMS)**: Priority rules for data overwrite when importing
- **Identity Re-registration details**: Consider policy 'only 1 pending request per type' and related UX
- **Mobile for Lecturers**: Evaluate needs and scope if expanding
- **Upgrade Backend-Service communication mechanism**: Research and transition communication mechanism from 'Direct API Call' to 'Message Queue' (e.g., RabbitMQ) to increase reliability and scalability of the system when deployed at large scale

---

## Notes

- All data is managed and filtered by Semester
- The primary platform for Lecturers & Supervisors is Web. Mobile app development for these roles is being considered to optimize experience
- User accounts are created and managed directly in the system by Data Operator. Google login is used for email verification

---

## In-Scope Functions

### Slot Interactions

Lecturers/TAs add remarks & attach announcements to slots; Students view announcements/remarks from lecturers and can send pre-slot messages (text + URL) up to T0.
