# FUACS Attendance Testing Guide

## Overview

This guide provides test endpoints and scenarios for the FUACS attendance system using the test data configured in `db.sql`.

## Test Data Summary

### Test Users

- **Lecturer**: `testlec001` / `testlec001@fpt.edu.vn` (ID: 9001)
- **Data Operator**: `testdop001` / `testdop001@fpt.edu.vn` (ID: 9002)
- **Students**: `TEST000001` to `TEST000010` (IDs: 9010-9019)
- **Password**: `password123` (for all test users)

### Test Classes

- **Class 901**: TPRF192_TEST01 (Students 9010-9014)
- **Class 902**: TPRO192_TEST01 (Students 9015-9019)

### Test Slots

- **Slot 9001**: Currently Active (LECTURE) - Class 901
- **Slot 9002**: Ended but Not Finalized (LECTURE_WITH_PT) - Class 902
- **Slot 9003**: Finalized (LECTURE) - Class 901
- **Slot 9004**: Future Final Exam

## Authentication Endpoints

### Login

```http
POST /api/auth/login
Content-Type: application/json

{
  "username": "testlec001",
  "password": "password123"
}
```

## Attendance Management Endpoints

### 1. Get Lecturer's Schedule

```http
GET /api/slots/lecturer/{lecturerId}
Authorization: Bearer {token}

# Example: Get schedule for testlec001 (ID: 9001)
GET /api/slots/lecturer/9001
```

### 2. Get Active Slot Details

```http
GET /api/slots/{slotId}
Authorization: Bearer {token}

# Example: Get currently active slot
GET /api/slots/9001
```

### 3. Get Attendance Roster for Slot

```http
GET /api/attendance-records/slot/{slotId}
Authorization: Bearer {token}

# Example: Get attendance for active slot
GET /api/attendance-records/slot/9001
```

### 4. Start Slot Session (Begin Attendance)

```http
POST /api/slots/{slotId}/start
Authorization: Bearer {token}

# Example: Start attendance for slot 9001
POST /api/slots/9001/start
```

### 5. Manual Attendance Update

```http
PUT /api/attendance-records/{recordId}
Authorization: Bearer {token}
Content-Type: application/json

{
  "status": "present",
  "method": "manual"
}
```

### 6. Finalize Slot

```http
POST /api/slots/{slotId}/finalize
Authorization: Bearer {token}

# Example: Finalize ended slot 9002
POST /api/slots/9002/finalize
```

### 7. Add Attendance Remark

```http
POST /api/regular-attendance-remarks
Authorization: Bearer {token}
Content-Type: application/json

{
  "attendanceRecordId": 1,
  "remark": "Student was late due to traffic"
}
```

## Face Recognition Endpoints

### 8. Face Recognition Detection

```http
POST /api/recognition/detect
Authorization: Bearer {token}
Content-Type: multipart/form-data

# Form data:
# - image: [image file]
# - slotId: 9001
```

### 9. Get Face Embeddings for Student

```http
GET /api/face-embeddings/student/{studentId}
Authorization: Bearer {token}

# Example: Get embeddings for TEST000001 (ID: 9010)
GET /api/face-embeddings/student/9010
```

## Exam Attendance Endpoints

### 10. Get Exam Attendance for Slot

```http
GET /api/exam-attendance/slot/{slotId}
Authorization: Bearer {token}

# Example: Get exam attendance for progress test slot
GET /api/exam-attendance/slot/9002
```

### 11. Update Exam Attendance

```http
PUT /api/exam-attendance/{examAttendanceId}
Authorization: Bearer {token}
Content-Type: application/json

{
  "status": "present",
  "method": "manual"
}
```

### 12. Add Exam Attendance Remark

```http
POST /api/exam-attendance-remarks
Authorization: Bearer {token}
Content-Type: application/json

{
  "examAttendanceId": 1,
  "remark": "Technical issue resolved, manually verified"
}
```

## Student Endpoints

### 13. Get Student's Own Attendance History

```http
GET /api/attendance-records/student/{studentId}
Authorization: Bearer {student_token}

# Example: Student TEST000001 checking own attendance
GET /api/attendance-records/student/9010
```

### 14. Get Student's Schedule

```http
GET /api/slots/student/{studentId}
Authorization: Bearer {student_token}

# Example: Get schedule for student 9010
GET /api/slots/student/9010
```

## Reporting Endpoints

### 15. Get Class Attendance Summary

```http
GET /api/reports/class/{classId}/attendance
Authorization: Bearer {token}

# Example: Get summary for class 901
GET /api/reports/class/901/attendance
```

### 16. Export Attendance Report

```http
GET /api/reports/slot/{slotId}/export
Authorization: Bearer {token}

# Example: Export report for finalized slot
GET /api/reports/slot/9003/export
```

## Test Scenarios

### Scenario 1: Active Lecture Session

1. Login as `testlec001`
2. Get slot 9001 details (currently active)
3. Get attendance roster for slot 9001
4. Simulate face recognition for students 9010-9014
5. Manually update any missed detections
6. Add remarks if needed

### Scenario 2: Finalize Ended Session

1. Login as `testlec001`
2. Get slot 9002 details (ended but not finalized)
3. Review attendance and exam attendance
4. Add any final remarks
5. Finalize the slot

### Scenario 3: Student Self-Service

1. Login as `TEST000001` (student 9010)
2. Get own schedule
3. Check attendance history
4. View upcoming slots

### Scenario 4: Data Operator Management

1. Login as `testdop001`
2. Get system-wide attendance reports
3. Manage user enrollments
4. Review audit logs

## Expected Response Codes

- **200**: Success
- **201**: Created
- **400**: Bad Request (validation errors)
- **401**: Unauthorized (invalid token)
- **403**: Forbidden (insufficient permissions)
- **404**: Not Found
- **409**: Conflict (duplicate data)

## Notes

- All timestamps in the test data are relative to current time
- Face embeddings are pre-generated with random vectors
- Test data includes various attendance statuses for comprehensive testing
- Use the verification queries at the end of `db.sql` to check data integrity
