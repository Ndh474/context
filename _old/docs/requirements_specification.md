# Requirements Specification

## Use Cases

### UC-01: Authenticate to System

**Primary Actors:** All Users  
**Secondary Actor:** None  
**Description:** Allows a user to log in using either their Username/Password or a linked Google account. The system validates the credentials before granting access.

### UC-02: Logout

**Primary Actors:** All Authenticated Users  
**Secondary Actor:** None  
**Description:** Allows an authenticated user to securely end their session and return to the Login screen.

### UC-03: View Role-Specific Dashboard

**Primary Actors:** All Authenticated Users  
**Secondary Actor:** None  
**Description:** After login, the system displays a personalized dashboard with key information and shortcuts relevant to the user's role.

### UC-04: Request Password Reset

**Primary Actors:** All Users  
**Secondary Actor:** None  
**Description:** Allows a user to initiate the password reset process by submitting their registered email address from the Login screen to receive a reset link.

### UC-05: Reset Password using Token

**Primary Actors:** All Users  
**Secondary Actor:** None  
**Description:** Allows a user to set a new password by following the secure link sent to their email and successfully validating the reset token.

### UC-06: Change Own Password

**Primary Actors:** All Authenticated Users  
**Secondary Actor:** None  
**Description:** Allows a logged-in user to change their current password by providing their old password and a new one, typically via their Profile screen.

### UC-07: View Personal Schedule

**Primary Actors:** Student  
**Secondary Actor:** None  
**Description:** Allows a student to view their personal class and exam schedule for a selected semester.

### UC-08: View Slot Details

**Primary Actors:** Student  
**Secondary Actor:** None  
**Description:** Allows a student to view detailed information for a specific slot from their schedule, including announcements.

### UC-09: Send Pre-Slot Message

**Primary Actors:** Student  
**Secondary Actor:** Lecturer  
**Description:** Allows a student to send a one-way message to the lecturer of a specific class slot.

### UC-10: View Attendance History

**Primary Actors:** Student  
**Secondary Actor:** None  
**Description:** Allows a student to view their own attendance history for past slots.

### UC-11: View Notifications

**Primary Actors:** Student  
**Secondary Actor:** None  
**Description:** Allows a student to view a feed of notifications, including system alerts and slot-specific announcements.

### UC-12: Initiate Identity Registration

**Primary Actors:** Student  
**Secondary Actor:** Data Operator  
**Description:** Allows a new student to submit their identity credentials (facial video, ID card) for verification by a Data Operator.

### UC-13: Request Identity Update

**Primary Actors:** Student  
**Secondary Actor:** Data Operator  
**Description:** Allows a student to submit a request to update their identity profile, which is routed to a Data Operator for approval.

### UC-14: View Teaching Schedule

**Primary Actors:** Lecturer  
**Secondary Actor:** None  
**Description:** Allows a lecturer to view their personal teaching and supervision schedule for a selected semester.

### UC-15: Initiate Attendance Session

**Primary Actors:** Lecturer, Supervisor  
**Secondary Actor:** None  
**Description:** Allows the assigned staff to start the first automated attendance scan for a slot. This action activates the assigned camera(s) and the on-screen button will subsequently change to "Re-scan".

### UC-16: Perform Re-scan during Session

**Primary Actors:** Lecturer, Supervisor  
**Secondary Actor:** None  
**Description:** Allows the assigned staff to trigger a new attendance scan while a session is active. The system will update student statuses based on the latest recognition results and record the event.

### UC-17: Monitor Real-Time Roster

**Primary Actors:** Lecturer  
**Secondary Actor:** None  
**Description:** Allows a lecturer to view the class roster for an active session, where statuses are updated in real-time based on results from all assigned cameras.

### UC-18: View Detailed Attendance History

**Primary Actors:** Lecturer, Supervisor  
**Secondary Actor:** None  
**Description:** Allows the assigned staff to view the detailed, timestamped attendance history for a specific student within a slot. The history is displayed as a timeline of all automated scans and manual edits.

### UC-19: Manually Update Attendance Status

**Primary Actors:** Lecturer  
**Secondary Actor:** None  
**Description:** Allows a lecturer to manually override a student's attendance status for a slot before finalization. A non-empty remark explaining the reason for the change is mandatory.

### UC-20: Add/Edit Attendance Remark

**Primary Actors:** Lecturer  
**Secondary Actor:** None  
**Description:** Allows a lecturer to add or modify a remark for a student's attendance record within a slot.

### UC-21: Finalize Attendance Session

**Primary Actors:** Lecturer  
**Secondary Actor:** None  
**Description:** Allows a lecturer to end the attendance session. The system will display a "Finalization Rules Setup" screen for the lecturer to make bulk decisions on converting intermediate statuses (e.g., Not Yet) to a final status (Present or Absent).

### UC-22: Create Slot Announcement

**Primary Actors:** Lecturer  
**Secondary Actor:** Student  
**Description:** Allows a lecturer to create and publish an announcement for a specific lecture slot.

### UC-23: View Slot Announcements

**Primary Actors:** Lecturer  
**Secondary Actor:** None  
**Description:** Allows a lecturer to view all announcements they have created for a specific lecture slot.

### UC-24: Delete Slot Announcement

**Primary Actors:** Lecturer  
**Secondary Actor:** Student  
**Description:** Allows a lecturer to remove an existing announcement from a lecture slot.

### UC-25: View Pre-Slot Messages

**Primary Actors:** Lecturer  
**Secondary Actor:** Student  
**Description:** Allows a lecturer to view a list of pre-slot messages sent by students for a specific lecture slot.

### UC-26: Acknowledge Pre-Slot Message

**Primary Actors:** Lecturer  
**Secondary Actor:** Student  
**Description:** Allows a lecturer to mark a student's pre-slot message as 'read' or 'acknowledged'.

### UC-27: Export Slot Attendance Report

**Primary Actors:** Lecturer  
**Secondary Actor:** None  
**Description:** Allows a lecturer to export a detailed attendance report for a finalized lecture slot.

### UC-28: View Class Attendance Summary Report

**Primary Actors:** Lecturer  
**Secondary Actor:** None  
**Description:** Allows a lecturer to view and export a summary attendance report for an entire class over a semester.

### UC-29: View Supervision Schedule

**Primary Actors:** Supervisor  
**Secondary Actor:** None  
**Description:** Allows a supervisor to view their personal supervision schedule for assigned exam slots.

### UC-30: Initiate Attendance Session

**Primary Actors:** Supervisor  
**Secondary Actor:** None  
**Description:** Allows a supervisor to start the first automated attendance scan for an exam slot. This action activates the assigned camera(s) and the on-screen button will subsequently change to "Re-scan".

### UC-31: Monitor Real-Time Roster

**Primary Actors:** Supervisor  
**Secondary Actor:** None  
**Description:** Allows a supervisor to view the exam roster for an active session, where statuses are updated in real-time based on results from all assigned cameras.

### UC-32: Manually Update Attendance Status

**Primary Actors:** Supervisor  
**Secondary Actor:** None  
**Description:** Allows a supervisor to manually override a candidate's attendance status for an exam slot before finalization. A non-empty remark explaining the reason for the change is mandatory.

### UC-33: Add/Edit Attendance Remark

**Primary Actors:** Supervisor  
**Secondary Actor:** None  
**Description:** Allows a supervisor to add or modify a remark for a candidate's attendance record within an exam slot.

### UC-34: Finalize Attendance Session

**Primary Actors:** Supervisor  
**Secondary Actor:** None  
**Description:** Allows a supervisor to end the attendance session. The system will display a "Finalization Rules Setup" screen for the supervisor to make bulk decisions on converting intermediate statuses (e.g., Not Yet) to a final status (Present or Absent).

### UC-35: Export Exam Slot Attendance Report

**Primary Actors:** Supervisor  
**Secondary Actor:** None  
**Description:** Allows a supervisor to export a detailed attendance report for a finalized exam slot.

### UC-36: Create User Account

**Primary Actors:** Data Operator  
**Secondary Actor:** None  
**Description:** Allows the DOP to create a new user by providing core details (username, email, full name). The operator must then create a specialized profile (Student or Staff) for the user to define their specific attributes and assign their base role.

### UC-37: View User Accounts

**Primary Actors:** Data Operator  
**Secondary Actor:** None  
**Description:** Allows the DOP to view and search a list of all user accounts in the system.

### UC-38: Update User Account Details

**Primary Actors:** Data Operator  
**Secondary Actor:** None  
**Description:** Allows the DOP to edit the information of an existing user account.

### UC-39: Update User Role Assignment

**Primary Actors:** Data Operator  
**Secondary Actor:** None  
**Description:** Allows the DOP to change the role assigned to a user, subject to system constraints.

### UC-40: Disable/Enable User Account

**Primary Actors:** Data Operator  
**Secondary Actor:** None  
**Description:** Allows the DOP to change the status of a user account to active or inactive.

### UC-41: View Pending Identity Submissions

**Primary Actors:** Data Operator  
**Secondary Actor:** Student  
**Description:** Allows the DOP to view a queue of all identity registration and update requests that are awaiting manual review.

### UC-42: Approve Identity Submission

**Primary Actors:** Data Operator  
**Secondary Actor:** Student  
**Description:** Allows the DOP to review the details of an identity submission (facial video, ID card) and approve it.

### UC-43: Reject Identity Submission

**Primary Actors:** Data Operator  
**Secondary Actor:** Student  
**Description:** Allows the DOP to reject an identity submission, providing a reason for the rejection that is sent to the student.

### UC-44: Create Major

**Primary Actors:** Data Operator  
**Secondary Actor:** None  
**Description:** Allows the DOP to add a new academic Major to the system-wide catalog.

### UC-45: View Majors

**Primary Actors:** Data Operator  
**Secondary Actor:** None  
**Description:** Allows the DOP to view a list of all Majors in the system.

### UC-46: Update Major

**Primary Actors:** Data Operator  
**Secondary Actor:** None  
**Description:** Allows the DOP to edit the details of an existing Major.

### UC-47: Delete Major

**Primary Actors:** Data Operator  
**Secondary Actor:** None  
**Description:** Allows the DOP to disable a Major from the catalog.

### UC-48: Create Semester

**Primary Actors:** Data Operator  
**Secondary Actor:** None  
**Description:** Allows the DOP to create a new academic semester with a name, code, start date, and end date.

### UC-49: View Semesters

**Primary Actors:** Data Operator  
**Secondary Actor:** None  
**Description:** Allows the DOP to view a list of all semesters in the system.

### UC-50: Update Semester

**Primary Actors:** Data Operator  
**Secondary Actor:** None  
**Description:** Allows the DOP to edit the details of an existing semester.

### UC-51: Delete Semester

**Primary Actors:** Data Operator  
**Secondary Actor:** None  
**Description:** Allows the DOP to disable a semester.

### UC-52: Create Subject

**Primary Actors:** Data Operator  
**Secondary Actor:** None  
**Description:** Allows the DOP to add a new academic Subject to the catalog, linking it to a Major.

### UC-53: View Subjects

**Primary Actors:** Data Operator  
**Secondary Actor:** None  
**Description:** Allows the DOP to view a list of all Subjects in the system.

### UC-54: Update Subject

**Primary Actors:** Data Operator  
**Secondary Actor:** None  
**Description:** Allows the DOP to edit the details of an existing Subject.

### UC-55: Delete Subject

**Primary Actors:** Data Operator  
**Secondary Actor:** None  
**Description:** Allows the DOP to disable a Subject from the catalog.

### UC-56: Create Class

**Primary Actors:** Data Operator  
**Secondary Actor:** None  
**Description:** Allows the DOP to create a new class, linking it to a subject and semester.

### UC-57: View Classes

**Primary Actors:** Data Operator  
**Secondary Actor:** None  
**Description:** Allows the DOP to view a list of all classes for a selected semester.

### UC-58: Update Class

**Primary Actors:** Data Operator  
**Secondary Actor:** None  
**Description:** Allows the DOP to edit the details of an existing class.

### UC-59: Delete Class

**Primary Actors:** Data Operator  
**Secondary Actor:** None  
**Description:** Allows the DOP to disable a class.

### UC-60: Create Schedule/Slot

**Primary Actors:** Data Operator  
**Secondary Actor:** None  
**Description:** Allows the DOP to create a new schedule slot for a class. After selecting the room, the operator must select one or more cameras from the list of available cameras in that room to be used for the session.

### UC-61: View Schedules

**Primary Actors:** Data Operator  
**Secondary Actor:** None  
**Description:** Allows the DOP to view the complete schedule for a class or semester.

### UC-62: Update Schedule/Slot

**Primary Actors:** Data Operator  
**Secondary Actor:** None  
**Description:** Allows the DOP to edit the details of a scheduled slot, including changing the assigned cameras.

### UC-63: Delete Schedule/Slot

**Primary Actors:** Data Operator  
**Secondary Actor:** None  
**Description:** Allows the DOP to cancel a scheduled slot.

### UC-64: Add Student to Roster

**Primary Actors:** Data Operator  
**Secondary Actor:** None  
**Description:** Allows the DOP to enroll a student into a specific class.

### UC-65: Remove Student from Roster

**Primary Actors:** Data Operator  
**Secondary Actor:** None  
**Description:** Allows the DOP to unenroll a student from a class.

### UC-66: Create Room

**Primary Actors:** Data Operator  
**Secondary Actor:** None  
**Description:** Allows the DOP to add a new physical room to the system.

### UC-67: View Rooms

**Primary Actors:** Data Operator  
**Secondary Actor:** None  
**Description:** Allows the DOP to view a list of all rooms in the system.

### UC-68: Update Room

**Primary Actors:** Data Operator  
**Secondary Actor:** None  
**Description:** Allows the DOP to edit the details of an existing room.

### UC-69: Delete Room

**Primary Actors:** Data Operator  
**Secondary Actor:** None  
**Description:** Allows the DOP to disable a room.

### UC-70: Create Camera

**Primary Actors:** Data Operator  
**Secondary Actor:** None  
**Description:** Allows the DOP to register a new IP camera by providing its details and assigning it to a specific room.

### UC-71: View Cameras

**Primary Actors:** Data Operator  
**Secondary Actor:** None  
**Description:** Allows the DOP to view a list of all registered cameras.

### UC-72: Update Camera

**Primary Actors:** Data Operator  
**Secondary Actor:** None  
**Description:** Allows the DOP to edit the details of an existing camera, including re-assigning it to a different room.

### UC-73: Delete Camera

**Primary Actors:** Data Operator  
**Secondary Actor:** None  
**Description:** Allows the DOP to delete a camera.

### UC-74: Import Academic Data

**Primary Actors:** Data Operator  
**Secondary Actor:** None  
**Description:** Allows the DOP to bulk-upload academic data (schedules, rosters) for a semester.

### UC-75: Export Finalized Attendance Results

**Primary Actors:** Data Operator  
**Secondary Actor:** None  
**Description:** Allows the DOP to export system-wide, finalized attendance results for a selected period.

### UC-76: View System-Wide Reports

**Primary Actors:** Data Operator  
**Secondary Actor:** None  
**Description:** Allows the DOP to generate and view aggregate reports on attendance data across various dimensions.

### UC-77: Search/Lookup Attendance Data

**Primary Actors:** Data Operator  
**Secondary Actor:** None  
**Description:** Allows the DOP to perform advanced searches for specific attendance records using a variety of filters.

### UC-78: View Operational Audit Logs

**Primary Actors:** Data Operator  
**Secondary Actor:** None  
**Description:** Allows the DOP to view a historical log of business data changes, which includes detailed before-and-after values for updates.

### UC-79: Create Notification Template

**Primary Actors:** System Admin  
**Secondary Actor:** None  
**Description:** Allows the System Admin to create new system notification templates (e.g., for password resets, identity rejections).

### UC-80: View Notification Templates

**Primary Actors:** System Admin  
**Secondary Actor:** None  
**Description:** Allows the System Admin to view and manage all system notification templates.

### UC-81: Update Notification Template

**Primary Actors:** System Admin  
**Secondary Actor:** None  
**Description:** Allows the System Admin to edit the content and properties of an existing notification template.

### UC-82: View System Configuration

**Primary Actors:** System Admin  
**Secondary Actor:** None  
**Description:** Allows the System Admin to view all global, system-level settings.

### UC-83: Update System Configuration

**Primary Actors:** System Admin  
**Secondary Actor:** None  
**Description:** Allows the System Admin to modify core system-level configurations to fine-tune system behavior.

### UC-84: View System Logs

**Primary Actors:** System Admin  
**Secondary Actor:** None  
**Description:** Allows the System Admin to view a comprehensive stream of system-wide activity logs for monitoring and troubleshooting.

### UC-85: Export System Logs

**Primary Actors:** System Admin  
**Secondary Actor:** None  
**Description:** Allows the System Admin to export system logs for a specified time period for offline analysis or archival.

### UC-86: View Role-Permission Mappings

**Primary Actors:** System Admin  
**Secondary Actor:** None  
**Description:** Allows the System Admin to view the current matrix that defines which permissions are granted to each user role.

### UC-87: Update Role-Permission Mappings

**Primary Actors:** System Admin  
**Secondary Actor:** None  
**Description:** Allows the System Admin to grant or revoke specific permissions for each role, controlling access to system functions.

---

## Business Rules

### BR-01

The primary login identifier username for a user must be their Student ID (for Students) or Staff ID (for Staff).

### BR-02

When a user logs in via Google, the system must use the email address provided by Google to look up the corresponding user account.

### BR-03

If a user account is found but is inactive (is_active = false), access must be denied.

### BR-04

Each username and email must be unique across the entire system.

### BR-05

A user with the STUDENT role cannot be concurrently assigned the LECTURER or SUPERVISOR role.

### BR-06

A password reset token must be unique, have an expiration time, and must be invalidated immediately after successful use.

### BR-07

A new user account must be linked to a specialized profile (student_profiles or staff_profiles) to define its specific attributes.

### BR-08

A student's initial identity registration request must include a facial video and a national ID card image.

### BR-09

All identity registration or update requests must be manually approved by a user with the appropriate permissions (e.g., IDENTITY_SUBMISSION_APPROVE).

### BR-10

While an identity update request is pending approval, the system must continue to use the previously approved identity data for attendance checking.

### BR-11

When an identity submission is rejected, the system must automatically send a system notification to the student, stating the reason for rejection.

### BR-12

Each Major, Subject, and Class must have a unique identifier (code or name).

### BR-13

A student can only be enrolled in a specific class once.

### BR-14

When a student is unenrolled from a class (enrollments.is_active = false), they must not appear in the roster for future slots of that class, but their past attendance history must be preserved.

### BR-15

Each lecture/exam slot must be associated with a specific slot type and room.

### BR-16

When creating or updating a slot, the selected cameras must belong to the list of cameras registered for that slot's assigned room.

### BR-17

Each lecture/exam slot must be assigned to one and only one staff member (Lecturer or Supervisor) at a time.

### BR-18

An automated attendance session can only be initiated by the staff member assigned to that slot who has the SLOT_SESSION_START permission.

### BR-19

When a face is recognized, the system updates the student's status based on the latest scan result (e.g., PRESENT for a new arrival, ABSENT_AFTER_PRESENT for a departure). This action is recorded as a new event in the attendance history.

### BR-20

If a face is not recognized, the system takes no action, and the student's attendance status remains unchanged during that scan.

### BR-21

When finalizing a slot, the system must display a 'Finalization Rules Setup' screen. The lecturer must then make a bulk decision for each group of students with an intermediate status (e.g., NOT_YET, ABSENT_AFTER_PRESENT) to convert their final status to either PRESENT or ABSENT.

### BR-22

The assigned Lecturer/Supervisor can manually edit the attendance results for a slot until 23:59:59 on the day of the slot.

### BR-23

After 23:59:59 on the day of the slot, only a user with permissions such as ATTENDANCE_STATUS_UPDATE_MANUAL can edit the attendance results, typically a Data Operator.

### BR-24

An attendance record for a student in a specific slot must be unique.

### BR-25

A student can only send a "Pre-slot Message" to the Lecturer before the slot's official start_time.

### BR-26

A "Pre-slot Message" serves as a reference and must not automatically alter a student's attendance status.

### BR-27

Only the assigned Lecturer for a lecture slot (slot_type = LECTURE) can create, edit, or delete a "Slot Announcement".

### BR-28

A "Slot Announcement" must be visible to all students enrolled in that slot.

### BR-29

Actions to modify core system configurations and manage role-permission mappings must be protected by distinct permissions (e.g., SYSTEM_CONFIG_UPDATE, ROLE_PERMISSION_MAPPING_UPDATE). By default, these permissions are granted only to the SYSTEM_ADMIN role.

### BR-30

User account management (creating, updating, assigning roles, etc.) must be controlled by a granular set of permissions (e.g., USER_CREATE, USER_UPDATE_STATUS, USER_ASSIGN_ROLES). By default, these permissions are granted to the DATA_OPERATOR role.

### BR-31

Critical business data changes (e.g., finalizing attendance, updating student information) must be logged in the operational audit trail (operational_audit_logs).

### BR-32

All attendance status changes for a student within a slot, whether automated by the camera or performed manually, must be recorded as a timestamped event in the history. The event must include the new status and the method of change (Auto, Manual, System Finalize).

### BR-33

Any manual edit of a student's attendance status requires a non-empty remark explaining the reason for the change. The system must prevent saving the change if the remark is empty.

### BR-34

After a slot is finalized, the primary status for all attendance records must be either PRESENT or ABSENT.
