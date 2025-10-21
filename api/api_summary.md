# FUACS API Endpoints Summary

**Last Updated**: 2024-10-21  
**Project**: FU Attendance Checking Smart (FUACS)

---

## 📊 Overview

| Service | Completed | Remaining | Total | Progress |
|---------|-----------|-----------|-------|----------|
| **Java Backend** | 18 groups (104 endpoints) | 5 groups (12 endpoints) | 116 | 90% |
| **Python Backend** | 1 group (8 endpoints) | 0 groups (0 endpoints) | 8 | 100% |
| **TOTAL** | 112 endpoints | 12 endpoints | 124 | 90% |

---

## 🟢 JAVA BACKEND - COMPLETED

### ✅ 1. Majors (`/majors`)

- [x] `POST /majors` - Create major
- [x] `GET /majors` - List majors (paginated, searchable)
- [x] `GET /majors/{id}` - Get major by ID
- [x] `PUT /majors/{id}` - Update major
- [x] `DELETE /majors/{id}` - Hard delete major
- [x] `GET /majors/{id}/subjects` - Get subjects by major

### ✅ 2. Semesters (`/semesters`)

- [x] `POST /semesters` - Create semester
- [x] `GET /semesters` - List semesters (paginated, searchable)
- [x] `GET /semesters/{id}` - Get semester by ID
- [x] `PUT /semesters/{id}` - Update semester
- [x] `DELETE /semesters/{id}` - Hard delete semester
- [x] `GET /semesters/{id}/classes` - Get classes by semester

### ✅ 3. Subjects (`/subjects`)

- [x] `POST /subjects` - Create subject (with major assignment)
- [x] `GET /subjects` - List subjects (paginated, searchable)
- [x] `GET /subjects/{id}` - Get subject by ID
- [x] `PUT /subjects/{id}` - Update subject (with major reassignment)
- [x] `DELETE /subjects/{id}` - Hard delete subject
- [x] `GET /subjects/{id}/classes` - Get classes by subject

### ✅ 4. Classes (`/classes`)

- [x] `POST /classes` - Create class
- [x] `GET /classes` - List classes (paginated, searchable, filterable)
- [x] `GET /classes/{id}` - Get class by ID
- [x] `PUT /classes/{id}` - Update class
- [x] `DELETE /classes/{id}` - Hard delete class
- [x] `GET /classes/{id}/slots` - Get slots by class

### ✅ 5. Rooms (`/rooms`)

- [x] `POST /rooms` - Create room
- [x] `GET /rooms` - List rooms (paginated, searchable)
- [x] `GET /rooms/{id}` - Get room by ID
- [x] `PUT /rooms/{id}` - Update room
- [x] `DELETE /rooms/{id}` - Hard delete room
- [x] `GET /rooms/{id}/cameras` - Get cameras by room

### ✅ 6. Cameras (`/cameras`)

- [x] `POST /cameras` - Create camera (with room assignment)
- [x] `GET /cameras` - List cameras (paginated, searchable, filterable)
- [x] `GET /cameras/{id}` - Get camera by ID
- [x] `PUT /cameras/{id}` - Update camera (with room reassignment)
- [x] `DELETE /cameras/{id}` - Hard delete camera

### ✅ 7. Slots (`/slots`)

- [x] `POST /slots` - Create slot (LECTURE, LECTURE_WITH_PT, FINAL_EXAM)
- [x] `GET /slots` - List slots (paginated, searchable, filterable)
- [x] `GET /slots/{id}` - Get slot by ID
- [x] `PUT /slots/{id}` - Update slot (full update or category only)
- [x] `DELETE /slots/{id}` - Hard delete slot
- [x] `GET /slots/{id}/roster` - Get slot roster with attendance status
- [x] `POST /slots/{id}/start-session` - Start attendance session
- [x] `POST /slots/{id}/rescan` - Trigger re-scan
- [x] `POST /slots/{id}/finalize` - Finalize attendance session

### ✅ 8. Student Profiles (`/student-profiles`)

- [x] `POST /student-profiles` - Create student profile
- [x] `GET /student-profiles` - List student profiles (paginated, searchable)
- [x] `GET /student-profiles/{id}` - Get student profile by ID
- [x] `PUT /student-profiles/{id}` - Update student profile
- [x] `DELETE /student-profiles/{id}` - Hard delete student profile
- [x] `GET /student-profiles/{id}/classes` - Get classes by student
- [x] `GET /student-profiles/{id}/attendance-history` - Get attendance history by student (UC-10)

### ✅ 9. Staff Profiles (`/staff-profiles`)

- [x] `POST /staff-profiles` - Create staff profile
- [x] `GET /staff-profiles` - List staff profiles (paginated, searchable)
- [x] `GET /staff-profiles/{id}` - Get staff profile by ID
- [x] `PUT /staff-profiles/{id}` - Update staff profile
- [x] `DELETE /staff-profiles/{id}` - Hard delete staff profile
- [x] `GET /staff-profiles/{id}/classes` - Get classes by staff

### ✅ 10. Authentication & User Management

- [x] `POST /auth/login` - Login with username/password (UC-01)
- [x] `POST /auth/google` - Login with Google OAuth (UC-01)
- [x] `POST /auth/logout` - Logout (UC-02)
- [x] `POST /auth/forgot-password` - Request password reset (UC-04)
- [x] `POST /auth/reset-password` - Reset password with token (UC-05)
- [x] `POST /auth/change-password` - Change own password (UC-06)
- [x] `GET /auth/me` - Get current user info (UC-03, UC-09)

### ✅ 11. Roles & Permissions

- [x] `GET /roles` - List roles
- [x] `GET /roles/{id}` - Get role by ID
- [x] `POST /roles` - Create role
- [x] `PUT /roles/{id}` - Update role
- [x] `DELETE /roles/{id}` - Hard delete role
- [x] `GET /permissions` - List permissions
- [x] `GET /role-permissions` - Get role-permission mapping (UC-82)
- [x] `PUT /role-permissions` - Update role-permission mapping (UC-83)

### ✅ 12. Enrollments

- [x] `POST /enrollments` - Add student to class (UC-62)
- [x] `GET /enrollments` - List enrollments (paginated, filterable)
- [x] `GET /enrollments/{classId}/{studentUserId}` - Get enrollment by composite key
- [x] `PUT /enrollments/{classId}/{studentUserId}` - Update enrollment (withdraw/re-enroll) (UC-63)
- [x] `POST /enrollments/bulk` - Bulk enrollment from CSV (UC-77) - PARTIAL SUCCESS strategy
- [x] `GET /enrollments/bulk/template` - Download CSV template
- [x] `GET /classes/{classId}/enrollments` - Get enrollments by class (roster management)

### ✅ 13. Attendance Records

- [x] `GET /attendance-records` - List attendance records (paginated, filterable)
- [x] `GET /attendance-records/{id}` - Get attendance record by ID
- [x] `PUT /attendance-records/{id}` - Manual update attendance status (UC-19, UC-30)
- [x] `POST /attendance/recognition-result` - Receive recognition result from Python (callback)

### ✅ 14. Regular Attendance Remarks

- [x] `POST /attendance-records/{attendanceRecordId}/remarks` - Add remark to regular attendance (UC-20)
- [x] `GET /attendance-records/{attendanceRecordId}/remarks` - Get remarks for regular attendance
- [x] `PUT /attendance-records/remarks/{remarkId}` - Update regular attendance remark
- [x] `DELETE /attendance-records/remarks/{remarkId}` - Soft delete regular attendance remark

### ✅ 15. Identity Management

- [x] `POST /identity-submissions` - Submit identity registration/update (UC-12, UC-13)
- [x] `GET /identity-submissions` - List submissions (approval queue) (UC-39)
- [x] `GET /identity-submissions/{id}` - Get submission details (UC-39)
- [x] `PUT /identity-submissions/{id}/approve` - Approve submission (UC-40)
- [x] `PUT /identity-submissions/{id}/reject` - Reject submission (UC-41)
- [x] `GET /identity-submissions/my-submissions` - Get own submissions (student)

### ✅ 16. Exam Attendance

- [x] `GET /exam-attendance` - List exam attendance records (paginated, filterable)
- [x] `GET /exam-attendance/{id}` - Get exam attendance by ID
- [x] `PUT /exam-attendance/{id}` - Manual update exam attendance status (UC-31)

### ✅ 17. Exam Attendance Remarks

- [x] `POST /exam-attendance/{examAttendanceId}/remarks` - Add remark to exam attendance (UC-31)
- [x] `GET /exam-attendance/{examAttendanceId}/remarks` - Get remarks for exam attendance
- [x] `PUT /exam-attendance/remarks/{remarkId}` - Update exam attendance remark
- [x] `DELETE /exam-attendance/remarks/{remarkId}` - Soft delete exam attendance remark

### ✅ 18. Bulk Import/Export

- [x] `POST /import/students` - Bulk import students from CSV (UC-70)
- [x] `POST /import/staff` - Bulk import staff from CSV (UC-71)
- [x] `POST /import/classes` - Bulk import classes from CSV
- [x] `POST /import/slots` - Bulk import slots from CSV
- [x] `GET /import/templates/{type}` - Download CSV template (types: students, staff, classes, slots, enrollments)
- [x] `GET /export/students` - Export students to CSV (UC-72)
- [x] `GET /export/staff` - Export staff to CSV
- [x] `GET /export/classes` - Export classes to CSV
- [x] `GET /export/attendance` - Export attendance records to CSV (UC-73)

---

## 🔴 JAVA BACKEND - REMAINING

### ❌ 1. Notifications (Priority: LOW - Near End)

- [ ] `GET /notifications` - List user notifications (UC-11)
- [ ] `GET /notifications/{id}` - Get notification details
- [ ] `PUT /notifications/{id}/read` - Mark notification as read
- [ ] `PUT /notifications/read-all` - Mark all notifications as read

### ❌ 2. Reports & Analytics (Priority: LOW - Near End)

- [ ] `GET /reports/slot/{slotId}` - Export slot attendance report (UC-22, UC-33)
- [ ] `GET /reports/class/{classId}/summary` - Class attendance summary (UC-23)
- [ ] `GET /reports/system-wide` - System-wide reports (UC-74)

### ❌ 3. System Configuration (Priority: LOW - Near End)

- [ ] `GET /system-configurations` - List system configs (UC-78)
- [ ] `GET /system-configurations/{key}` - Get config by key
- [ ] `PUT /system-configurations/{key}` - Update config (UC-79)

### ❌ 4. Audit Logs (Priority: LOW - Near End)

- [ ] `GET /audit-logs` - List operational audit logs (UC-76)
- [ ] `GET /audit-logs/{id}` - Get audit log details

### ❌ 5. Schedule & Dashboard (Priority: LOW - Near End)

- [ ] `GET /schedules/my-schedule` - Get personal schedule (UC-07, UC-14, UC-27)
- [ ] `GET /dashboard/stats` - Get dashboard statistics (UC-03)

---

## 🟢 PYTHON BACKEND - COMPLETED

### ✅ 1. Face Recognition Service (FastAPI)

***Face Recognition Processing***

- [x] `POST /api/v1/recognition/process-session` - Start face recognition session (UC-16, UC-28)
- [x] `POST /api/v1/recognition/stop-session` - Stop recognition session

***Face Embedding Generation***

- [x] `POST /api/v1/embeddings/generate` - Generate face embedding from video (UC-12, UC-13)
- [x] `POST /api/v1/embeddings/validate` - Validate face video quality (UC-12, UC-13)

***Camera Management***

- [x] `GET /api/v1/cameras/test-connection` - Test RTSP camera connection (UC-50)
- [x] `GET /api/v1/cameras/capture-frame` - Capture preview frame from camera (UC-50)

***Health Check & Monitoring***

- [x] `GET /api/v1/health` - Health check endpoint
- [x] `GET /api/v1/metrics` - Performance metrics (processing time, accuracy)

---

**Generated by**: Kiro AI Assistant  
**Last Updated**: 2024-10-21

---

## ⚠️ NEED REVIEW IN FUTURE

### 🔍 Endpoints Marked as "Completed" - Need Verification

These endpoints are marked as completed but should be reviewed/tested to ensure full implementation:

#### Authentication & User Management

- [ ] **Review**: Google OAuth integration - verify token validation and user creation flow
- [ ] **Review**: Password reset email sending - check email service integration
- [ ] **Review**: JWT token refresh mechanism - may need additional endpoint

#### Roles & Permissions

- [ ] **Review**: Role-permission mapping update - verify cascade effects on active users
- [ ] **Review**: Permission enforcement middleware - test all permission checks

#### Slots

- [ ] **Review**: `/slots/{id}/start-session` - verify Python service integration
- [ ] **Review**: `/slots/{id}/finalize` - test finalization rules and batch status updates
- [ ] **Review**: `/slots/{id}/roster` - verify real-time attendance status updates

#### Student/Staff Profiles

- [ ] **Review**: Bulk operations performance - test with large datasets
- [ ] **Review**: Profile deletion - verify cascade delete behavior with enrollments/attendance

#### Classes

- [ ] **Review**: `/classes/{id}/slots` - verify filtering and sorting work correctly
- [ ] **Review**: Class deactivation - test constraint checks for active slots/enrollments

### 🔧 Implementation Notes

#### Attendance Remarks - Separated by Type

- **Regular Attendance Remarks**: For LECTURE and LECTURE_WITH_PT slots
  - Endpoints: `/attendance-records/{attendanceRecordId}/remarks`
  - Table: `regular_attendance_remarks`
  
- **Exam Attendance Remarks**: For FINAL_EXAM slots  
  - Endpoints: `/exam-attendance/{examAttendanceId}/remarks`
  - Table: `exam_attendance_remarks`

#### Slot Management - Implicit Endpoints

- **Slot Reopen**: No dedicated endpoint - handled via `PUT /slots/{id}` by clearing `finalized_at`
  - Note: Same-day only restriction enforced in business logic

#### Enrollment Management - Multiple Access Patterns

- `GET /enrollments?classId={classId}` - List all enrollments for a class
- `GET /classes/{classId}/enrollments` - Get roster with student details (optimized for roster view)
