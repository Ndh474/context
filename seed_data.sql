-- =====================================================
-- FUACS Seed Data Script
-- Test data for development and testing
-- Compatible with Flyway migrations V1 and V2
-- =====================================================

-- Password for all test users: "password123"
-- Hash: $2a$12$aSEiCWX1/2jbK5LLgQCwo.Ql4NDzvjYhX6KD0bAtk8eWhSv3X.O3O

-- =====================================================
-- SECTION 1: MASTER DATA (Roles, Permissions, Majors)
-- =====================================================

-- Insert Roles
INSERT INTO roles (id, name, is_active) VALUES
(1, 'SYSTEM_ADMIN', TRUE),
(2, 'DATA_OPERATOR', TRUE),
(3, 'LECTURER', TRUE),
(4, 'SUPERVISOR', TRUE),
(5, 'STUDENT', TRUE)
ON CONFLICT (id) DO UPDATE SET 
    name = EXCLUDED.name,
    is_active = EXCLUDED.is_active;

-- Insert Permissions
INSERT INTO permissions (name, is_active) VALUES
-- User Management
('USER_CREATE', TRUE),
('USER_READ_LIST', TRUE),
('USER_READ_DETAIL', TRUE),
('USER_UPDATE_INFO', TRUE),
('USER_UPDATE_STATUS', TRUE),
('USER_DELETE_HARD', TRUE),
('USER_ASSIGN_ROLES', TRUE),
('CREATE_SYSTEM_ADMIN', TRUE),
-- Academic Management
('SEMESTER_CREATE', TRUE),
('SEMESTER_READ', TRUE),
('SEMESTER_UPDATE', TRUE),
('MAJOR_CREATE', TRUE),
('MAJOR_READ', TRUE),
('MAJOR_UPDATE', TRUE),
('SUBJECT_CREATE', TRUE),
('SUBJECT_READ', TRUE),
('SUBJECT_UPDATE', TRUE),
('CLASS_CREATE', TRUE),
('CLASS_READ', TRUE),
('CLASS_UPDATE', TRUE),
('SLOT_CREATE', TRUE),
('SLOT_READ', TRUE),
('SLOT_UPDATE', TRUE),
('ENROLLMENT_MANAGE', TRUE),
-- Infrastructure
('ROOM_CREATE', TRUE),
('ROOM_READ', TRUE),
('ROOM_UPDATE', TRUE),
('CAMERA_CREATE', TRUE),
('CAMERA_READ', TRUE),
('CAMERA_UPDATE', TRUE),
-- Attendance
('OWN_SCHEDULE_READ', TRUE),
('SLOT_SESSION_START', TRUE),
('SLOT_SESSION_RESCAN', TRUE),
('ATTENDANCE_ROSTER_READ', TRUE),
('ATTENDANCE_STATUS_UPDATE_MANUAL', TRUE),
('ATTENDANCE_REMARK_MANAGE', TRUE),
-- Student
('OWN_ATTENDANCE_HISTORY_READ', TRUE),
('OWN_PROFILE_READ', TRUE),
('OWN_PASSWORD_UPDATE', TRUE)
ON CONFLICT (name) DO NOTHING;

-- Role-Permission Mappings
INSERT INTO role_permissions (role_id, permission_id)
SELECT 1, id FROM permissions WHERE name IN (
    'USER_CREATE', 'USER_READ_LIST', 'USER_ASSIGN_ROLES', 'CREATE_SYSTEM_ADMIN'
) ON CONFLICT DO NOTHING;

INSERT INTO role_permissions (role_id, permission_id)
SELECT 2, id FROM permissions WHERE name IN (
    'USER_CREATE', 'USER_READ_LIST', 'USER_UPDATE_INFO', 'SEMESTER_CREATE', 'SEMESTER_READ',
    'MAJOR_CREATE', 'MAJOR_READ', 'SUBJECT_CREATE', 'SUBJECT_READ', 'CLASS_CREATE', 'CLASS_READ',
    'SLOT_CREATE', 'SLOT_READ', 'ENROLLMENT_MANAGE', 'ROOM_CREATE', 'ROOM_READ',
    'CAMERA_CREATE', 'CAMERA_READ', 'ATTENDANCE_ROSTER_READ', 'ATTENDANCE_STATUS_UPDATE_MANUAL'
) ON CONFLICT DO NOTHING;

INSERT INTO role_permissions (role_id, permission_id)
SELECT 3, id FROM permissions WHERE name IN (
    'OWN_SCHEDULE_READ', 'SLOT_SESSION_START', 'SLOT_SESSION_RESCAN', 'ATTENDANCE_ROSTER_READ',
    'ATTENDANCE_STATUS_UPDATE_MANUAL', 'ATTENDANCE_REMARK_MANAGE', 'ROOM_READ', 'CAMERA_READ'
) ON CONFLICT DO NOTHING;

INSERT INTO role_permissions (role_id, permission_id)
SELECT 4, id FROM permissions WHERE name IN (
    'OWN_SCHEDULE_READ', 'SLOT_SESSION_START', 'ATTENDANCE_ROSTER_READ', 'ROOM_READ'
) ON CONFLICT DO NOTHING;

INSERT INTO role_permissions (role_id, permission_id)
SELECT 5, id FROM permissions WHERE name IN (
    'OWN_SCHEDULE_READ', 'OWN_ATTENDANCE_HISTORY_READ', 'OWN_PROFILE_READ', 'OWN_PASSWORD_UPDATE'
) ON CONFLICT DO NOTHING;

-- Insert Majors
INSERT INTO majors (id, name, code, is_active) VALUES
(1, 'Software Engineering', 'SE', TRUE),
(2, 'Information Assurance', 'IA', TRUE),
(3, 'Artificial Intelligence', 'AI', TRUE),
(4, 'Internet of Things', 'IOT', TRUE),
(5, 'Digital Art Design', 'DAD', TRUE)
ON CONFLICT (id) DO UPDATE SET 
    name = EXCLUDED.name,
    code = EXCLUDED.code,
    is_active = EXCLUDED.is_active;

-- Insert Semesters
INSERT INTO semesters (name, code, start_date, end_date, is_active) VALUES
('Fall 2024', 'FA24', '2024-09-02', '2024-12-20', TRUE),
('Spring 2025', 'SP25', '2025-01-06', '2025-05-09', TRUE),
('Summer 2025', 'SU25', '2025-05-19', '2025-08-29', FALSE)
ON CONFLICT (code) DO NOTHING;

-- Insert Subjects
INSERT INTO subjects (name, code, is_active) VALUES
('Programming Fundamentals', 'PRF192', TRUE),
('Object-Oriented Programming', 'PRO192', TRUE),
('Data Structures and Algorithms', 'CSD201', TRUE),
('Database Management Systems', 'DBI202', TRUE),
('Web Development', 'SWP391', TRUE)
ON CONFLICT (code) DO NOTHING;

-- Subject-Major Mappings
INSERT INTO subject_majors (subject_id, major_id)
SELECT s.id, m.id
FROM subjects s
CROSS JOIN majors m
WHERE s.code IN ('PRF192', 'PRO192', 'CSD201', 'DBI202', 'SWP391')
  AND m.code IN ('SE', 'AI', 'IOT')
ON CONFLICT DO NOTHING;

-- =====================================================
-- SECTION 2: TEST USERS
-- =====================================================

-- System Admin
INSERT INTO users (id, username, email, full_name, password_hash, is_active) VALUES
(1000, 'admin001', 'admin001@fpt.edu.vn', 'System Administrator', '$2a$12$aSEiCWX1/2jbK5LLgQCwo.Ql4NDzvjYhX6KD0bAtk8eWhSv3X.O3O', TRUE)
ON CONFLICT (id) DO NOTHING;

INSERT INTO staff_profiles (user_id, staff_code) VALUES
(1000, 'ADMIN001')
ON CONFLICT (user_id) DO NOTHING;

INSERT INTO user_roles (user_id, role_id) VALUES (1000, 1) ON CONFLICT DO NOTHING;

-- Data Operators (3 users)
INSERT INTO users (id, username, email, full_name, password_hash, is_active) VALUES
(1010, 'dop001', 'dop001@fpt.edu.vn', 'Nguyen Van DOP', '$2a$12$aSEiCWX1/2jbK5LLgQCwo.Ql4NDzvjYhX6KD0bAtk8eWhSv3X.O3O', TRUE),
(1011, 'dop002', 'dop002@fpt.edu.vn', 'Tran Thi DOP', '$2a$12$aSEiCWX1/2jbK5LLgQCwo.Ql4NDzvjYhX6KD0bAtk8eWhSv3X.O3O', TRUE),
(1012, 'dop003', 'dop003@fpt.edu.vn', 'Le Van DOP', '$2a$12$aSEiCWX1/2jbK5LLgQCwo.Ql4NDzvjYhX6KD0bAtk8eWhSv3X.O3O', TRUE)
ON CONFLICT (id) DO NOTHING;

INSERT INTO staff_profiles (user_id, staff_code) VALUES
(1010, 'DOP001'),
(1011, 'DOP002'),
(1012, 'DOP003')
ON CONFLICT (user_id) DO NOTHING;

INSERT INTO user_roles (user_id, role_id) VALUES 
(1010, 2), (1011, 2), (1012, 2) 
ON CONFLICT DO NOTHING;

-- Lecturers (5 users)
INSERT INTO users (id, username, email, full_name, password_hash, is_active) VALUES
(1020, 'lec001', 'lec001@fpt.edu.vn', 'Dr. Nguyen Van Lecturer', '$2a$12$aSEiCWX1/2jbK5LLgQCwo.Ql4NDzvjYhX6KD0bAtk8eWhSv3X.O3O', TRUE),
(1021, 'lec002', 'lec002@fpt.edu.vn', 'MSc. Tran Thi Lecturer', '$2a$12$aSEiCWX1/2jbK5LLgQCwo.Ql4NDzvjYhX6KD0bAtk8eWhSv3X.O3O', TRUE),
(1022, 'lec003', 'lec003@fpt.edu.vn', 'Prof. Le Van Lecturer', '$2a$12$aSEiCWX1/2jbK5LLgQCwo.Ql4NDzvjYhX6KD0bAtk8eWhSv3X.O3O', TRUE),
(1023, 'lec004', 'lec004@fpt.edu.vn', 'Dr. Pham Thi Lecturer', '$2a$12$aSEiCWX1/2jbK5LLgQCwo.Ql4NDzvjYhX6KD0bAtk8eWhSv3X.O3O', TRUE),
(1024, 'lec005', 'lec005@fpt.edu.vn', 'MSc. Hoang Van Lecturer', '$2a$12$aSEiCWX1/2jbK5LLgQCwo.Ql4NDzvjYhX6KD0bAtk8eWhSv3X.O3O', TRUE)
ON CONFLICT (id) DO NOTHING;

INSERT INTO staff_profiles (user_id, staff_code) VALUES
(1020, 'LEC001'),
(1021, 'LEC002'),
(1022, 'LEC003'),
(1023, 'LEC004'),
(1024, 'LEC005')
ON CONFLICT (user_id) DO NOTHING;

INSERT INTO user_roles (user_id, role_id) VALUES 
(1020, 3), (1021, 3), (1022, 3), (1023, 3), (1024, 3)
ON CONFLICT DO NOTHING;

-- Supervisors (2 users)
INSERT INTO users (id, username, email, full_name, password_hash, is_active) VALUES
(1030, 'sup001', 'sup001@fpt.edu.vn', 'Nguyen Van Supervisor', '$2a$12$aSEiCWX1/2jbK5LLgQCwo.Ql4NDzvjYhX6KD0bAtk8eWhSv3X.O3O', TRUE),
(1031, 'sup002', 'sup002@fpt.edu.vn', 'Tran Thi Supervisor', '$2a$12$aSEiCWX1/2jbK5LLgQCwo.Ql4NDzvjYhX6KD0bAtk8eWhSv3X.O3O', TRUE)
ON CONFLICT (id) DO NOTHING;

INSERT INTO staff_profiles (user_id, staff_code) VALUES
(1030, 'SUP001'),
(1031, 'SUP002')
ON CONFLICT (user_id) DO NOTHING;

INSERT INTO user_roles (user_id, role_id) VALUES 
(1030, 4), (1031, 4)
ON CONFLICT DO NOTHING;

-- Students (20 users - SE major)
INSERT INTO users (id, username, email, full_name, password_hash, is_active) VALUES
(2001, 'HE180001', 'he180001@fpt.edu.vn', 'Nguyen Van An', '$2a$12$aSEiCWX1/2jbK5LLgQCwo.Ql4NDzvjYhX6KD0bAtk8eWhSv3X.O3O', TRUE),
(2002, 'HE180002', 'he180002@fpt.edu.vn', 'Tran Thi Binh', '$2a$12$aSEiCWX1/2jbK5LLgQCwo.Ql4NDzvjYhX6KD0bAtk8eWhSv3X.O3O', TRUE),
(2003, 'HE180003', 'he180003@fpt.edu.vn', 'Le Van Cuong', '$2a$12$aSEiCWX1/2jbK5LLgQCwo.Ql4NDzvjYhX6KD0bAtk8eWhSv3X.O3O', TRUE),
(2004, 'HE180004', 'he180004@fpt.edu.vn', 'Pham Thi Dung', '$2a$12$aSEiCWX1/2jbK5LLgQCwo.Ql4NDzvjYhX6KD0bAtk8eWhSv3X.O3O', TRUE),
(2005, 'HE180005', 'he180005@fpt.edu.vn', 'Hoang Van Em', '$2a$12$aSEiCWX1/2jbK5LLgQCwo.Ql4NDzvjYhX6KD0bAtk8eWhSv3X.O3O', TRUE),
(2006, 'HE180006', 'he180006@fpt.edu.vn', 'Vu Thi Phuong', '$2a$12$aSEiCWX1/2jbK5LLgQCwo.Ql4NDzvjYhX6KD0bAtk8eWhSv3X.O3O', TRUE),
(2007, 'HE180007', 'he180007@fpt.edu.vn', 'Vo Van Giang', '$2a$12$aSEiCWX1/2jbK5LLgQCwo.Ql4NDzvjYhX6KD0bAtk8eWhSv3X.O3O', TRUE),
(2008, 'HE180008', 'he180008@fpt.edu.vn', 'Dang Thi Hoa', '$2a$12$aSEiCWX1/2jbK5LLgQCwo.Ql4NDzvjYhX6KD0bAtk8eWhSv3X.O3O', TRUE),
(2009, 'HE180009', 'he180009@fpt.edu.vn', 'Bui Van Hung', '$2a$12$aSEiCWX1/2jbK5LLgQCwo.Ql4NDzvjYhX6KD0bAtk8eWhSv3X.O3O', TRUE),
(2010, 'HE180010', 'he180010@fpt.edu.vn', 'Do Thi Khanh', '$2a$12$aSEiCWX1/2jbK5LLgQCwo.Ql4NDzvjYhX6KD0bAtk8eWhSv3X.O3O', TRUE),
(2011, 'HE180011', 'he180011@fpt.edu.vn', 'Ngo Van Linh', '$2a$12$aSEiCWX1/2jbK5LLgQCwo.Ql4NDzvjYhX6KD0bAtk8eWhSv3X.O3O', TRUE),
(2012, 'HE180012', 'he180012@fpt.edu.vn', 'Duong Thi Mai', '$2a$12$aSEiCWX1/2jbK5LLgQCwo.Ql4NDzvjYhX6KD0bAtk8eWhSv3X.O3O', TRUE),
(2013, 'HE180013', 'he180013@fpt.edu.vn', 'Ly Van Nam', '$2a$12$aSEiCWX1/2jbK5LLgQCwo.Ql4NDzvjYhX6KD0bAtk8eWhSv3X.O3O', TRUE),
(2014, 'HE180014', 'he180014@fpt.edu.vn', 'Nguyen Thi Oanh', '$2a$12$aSEiCWX1/2jbK5LLgQCwo.Ql4NDzvjYhX6KD0bAtk8eWhSv3X.O3O', TRUE),
(2015, 'HE180015', 'he180015@fpt.edu.vn', 'Tran Van Phong', '$2a$12$aSEiCWX1/2jbK5LLgQCwo.Ql4NDzvjYhX6KD0bAtk8eWhSv3X.O3O', TRUE),
(2016, 'HE180016', 'he180016@fpt.edu.vn', 'Le Thi Quynh', '$2a$12$aSEiCWX1/2jbK5LLgQCwo.Ql4NDzvjYhX6KD0bAtk8eWhSv3X.O3O', TRUE),
(2017, 'HE180017', 'he180017@fpt.edu.vn', 'Pham Van Son', '$2a$12$aSEiCWX1/2jbK5LLgQCwo.Ql4NDzvjYhX6KD0bAtk8eWhSv3X.O3O', TRUE),
(2018, 'HE180018', 'he180018@fpt.edu.vn', 'Hoang Thi Tuan', '$2a$12$aSEiCWX1/2jbK5LLgQCwo.Ql4NDzvjYhX6KD0bAtk8eWhSv3X.O3O', TRUE),
(2019, 'HE180019', 'he180019@fpt.edu.vn', 'Vu Van Uyen', '$2a$12$aSEiCWX1/2jbK5LLgQCwo.Ql4NDzvjYhX6KD0bAtk8eWhSv3X.O3O', TRUE),
(2020, 'HE180020', 'he180020@fpt.edu.vn', 'Vo Thi Vinh', '$2a$12$aSEiCWX1/2jbK5LLgQCwo.Ql4NDzvjYhX6KD0bAtk8eWhSv3X.O3O', TRUE)
ON CONFLICT (id) DO NOTHING;

INSERT INTO student_profiles (user_id, major_id, roll_number, base_photo_url) VALUES
(2001, 1, 'HE180001', '/photos/he180001.jpg'),
(2002, 1, 'HE180002', '/photos/he180002.jpg'),
(2003, 1, 'HE180003', '/photos/he180003.jpg'),
(2004, 1, 'HE180004', '/photos/he180004.jpg'),
(2005, 1, 'HE180005', '/photos/he180005.jpg'),
(2006, 1, 'HE180006', '/photos/he180006.jpg'),
(2007, 1, 'HE180007', '/photos/he180007.jpg'),
(2008, 1, 'HE180008', '/photos/he180008.jpg'),
(2009, 1, 'HE180009', '/photos/he180009.jpg'),
(2010, 1, 'HE180010', '/photos/he180010.jpg'),
(2011, 1, 'HE180011', '/photos/he180011.jpg'),
(2012, 1, 'HE180012', '/photos/he180012.jpg'),
(2013, 1, 'HE180013', '/photos/he180013.jpg'),
(2014, 1, 'HE180014', '/photos/he180014.jpg'),
(2015, 1, 'HE180015', '/photos/he180015.jpg'),
(2016, 1, 'HE180016', '/photos/he180016.jpg'),
(2017, 1, 'HE180017', '/photos/he180017.jpg'),
(2018, 1, 'HE180018', '/photos/he180018.jpg'),
(2019, 1, 'HE180019', '/photos/he180019.jpg'),
(2020, 1, 'HE180020', '/photos/he180020.jpg')
ON CONFLICT (user_id) DO NOTHING;

INSERT INTO user_roles (user_id, role_id)
SELECT id, 5 FROM users WHERE id BETWEEN 2001 AND 2020
ON CONFLICT DO NOTHING;

-- =====================================================
-- SECTION 3: INFRASTRUCTURE
-- =====================================================

-- Rooms
INSERT INTO rooms (id, name, location, is_active) VALUES
(101, 'Room 101', 'Building Alpha - Floor 1', TRUE),
(102, 'Room 102', 'Building Alpha - Floor 1', TRUE),
(103, 'Room 103', 'Building Alpha - Floor 1', TRUE),
(201, 'Lab 201', 'Building Beta - Floor 2', TRUE),
(202, 'Lab 202', 'Building Beta - Floor 2', TRUE),
(301, 'Auditorium A', 'Building Gamma - Ground Floor', TRUE)
ON CONFLICT (id) DO NOTHING;

-- Cameras
INSERT INTO cameras (room_id, name, rtsp_url, is_active) VALUES
(101, 'CAM-101-FRONT', 'rtsp://192.168.1.101:554/stream1', TRUE),
(101, 'CAM-101-BACK', 'rtsp://192.168.1.102:554/stream1', TRUE),
(102, 'CAM-102-FRONT', 'rtsp://192.168.1.103:554/stream1', TRUE),
(103, 'CAM-103-FRONT', 'rtsp://192.168.1.104:554/stream1', TRUE),
(201, 'CAM-201-FRONT', 'rtsp://192.168.1.201:554/stream1', TRUE),
(202, 'CAM-202-FRONT', 'rtsp://192.168.1.202:554/stream1', TRUE),
(301, 'CAM-301-FRONT', 'rtsp://192.168.1.301:554/stream1', TRUE),
(301, 'CAM-301-BACK', 'rtsp://192.168.1.302:554/stream1', TRUE)
ON CONFLICT (name) DO NOTHING;

-- =====================================================
-- SECTION 4: ACADEMIC DATA
-- =====================================================

-- Classes (Spring 2025)
INSERT INTO classes (subject_id, semester_id, code, is_active)
SELECT s.id, sem.id, s.code || '01', TRUE
FROM subjects s
CROSS JOIN semesters sem
WHERE sem.code = 'SP25' AND s.code IN ('PRF192', 'PRO192', 'CSD201')
ON CONFLICT DO NOTHING;

-- Enrollments (10 students per class)
INSERT INTO enrollments (class_id, student_user_id, is_enrolled)
SELECT c.id, u.id, TRUE
FROM classes c
CROSS JOIN users u
WHERE u.id BETWEEN 2001 AND 2010
  AND c.code LIKE 'PRF192%'
ON CONFLICT DO NOTHING;

INSERT INTO enrollments (class_id, student_user_id, is_enrolled)
SELECT c.id, u.id, TRUE
FROM classes c
CROSS JOIN users u
WHERE u.id BETWEEN 2011 AND 2020
  AND c.code LIKE 'PRO192%'
ON CONFLICT DO NOTHING;

-- Slots (Past, Current, Future)
INSERT INTO slots (class_id, semester_id, room_id, staff_user_id, slot_category, start_time, end_time, title, session_status, is_active)
SELECT 
    c.id,
    c.semester_id,
    101,
    1020,
    'LECTURE',
    CURRENT_TIMESTAMP - INTERVAL '7 days' + (ROW_NUMBER() OVER () * INTERVAL '2 days'),
    CURRENT_TIMESTAMP - INTERVAL '7 days' + (ROW_NUMBER() OVER () * INTERVAL '2 days') + INTERVAL '2 hours',
    'Lecture Session ' || ROW_NUMBER() OVER (),
    'STOPPED',
    TRUE
FROM classes c
WHERE c.code LIKE 'PRF192%'
LIMIT 3
ON CONFLICT DO NOTHING;

-- Current slot (running now)
INSERT INTO slots (class_id, semester_id, room_id, staff_user_id, slot_category, start_time, end_time, title, session_status, is_active)
SELECT 
    c.id,
    c.semester_id,
    102,
    1021,
    'LECTURE',
    CURRENT_TIMESTAMP - INTERVAL '30 minutes',
    CURRENT_TIMESTAMP + INTERVAL '90 minutes',
    'Current Lecture Session',
    'RUNNING',
    TRUE
FROM classes c
WHERE c.code LIKE 'PRO192%'
LIMIT 1
ON CONFLICT DO NOTHING;

-- Future slots
INSERT INTO slots (class_id, semester_id, room_id, staff_user_id, slot_category, start_time, end_time, title, session_status, is_active)
SELECT 
    c.id,
    c.semester_id,
    103,
    1022,
    'LECTURE',
    CURRENT_TIMESTAMP + INTERVAL '2 days' + (ROW_NUMBER() OVER () * INTERVAL '2 days'),
    CURRENT_TIMESTAMP + INTERVAL '2 days' + (ROW_NUMBER() OVER () * INTERVAL '2 days') + INTERVAL '2 hours',
    'Future Lecture ' || ROW_NUMBER() OVER (),
    'NOT_STARTED',
    TRUE
FROM classes c
WHERE c.code LIKE 'CSD201%'
LIMIT 2
ON CONFLICT DO NOTHING;

-- =====================================================
-- SECTION 5: ATTENDANCE DATA
-- =====================================================

-- Attendance records for past slots
INSERT INTO attendance_records (student_user_id, slot_id, status, method, recorded_at)
SELECT 
    e.student_user_id,
    s.id,
    CASE WHEN RANDOM() < 0.9 THEN 'present' ELSE 'absent' END,
    'auto',
    s.start_time + INTERVAL '15 minutes'
FROM slots s
JOIN classes c ON s.class_id = c.id
JOIN enrollments e ON c.id = e.class_id
WHERE s.session_status = 'STOPPED'
  AND e.is_enrolled = TRUE
ON CONFLICT (student_user_id, slot_id) DO NOTHING;

-- Face embeddings for students
INSERT INTO face_embeddings (student_user_id, version, is_active, embedding_vector)
SELECT 
    id,
    1,
    TRUE,
    array_fill(RANDOM()::REAL, ARRAY[512])::vector
FROM users
WHERE id BETWEEN 2001 AND 2020
ON CONFLICT (student_user_id) WHERE is_active = true DO NOTHING;

-- System notifications
INSERT INTO system_notifications (notification_type, title, content, is_active) VALUES
('identity_approved', 'Identity Verified', 'Your identity has been verified successfully.', TRUE),
('absence_warning_10', 'Absence Warning', 'You have reached 10% absence rate.', TRUE),
('slot_cancelled', 'Slot Cancelled', 'A scheduled slot has been cancelled.', TRUE)
ON CONFLICT DO NOTHING;

-- =====================================================
-- VERIFICATION
-- =====================================================

SELECT 'Data seeding completed!' as status;

SELECT 'users' as table_name, COUNT(*) as count FROM users
UNION ALL SELECT 'roles', COUNT(*) FROM roles
UNION ALL SELECT 'permissions', COUNT(*) FROM permissions
UNION ALL SELECT 'majors', COUNT(*) FROM majors
UNION ALL SELECT 'semesters', COUNT(*) FROM semesters
UNION ALL SELECT 'subjects', COUNT(*) FROM subjects
UNION ALL SELECT 'classes', COUNT(*) FROM classes
UNION ALL SELECT 'enrollments', COUNT(*) FROM enrollments
UNION ALL SELECT 'rooms', COUNT(*) FROM rooms
UNION ALL SELECT 'cameras', COUNT(*) FROM cameras
UNION ALL SELECT 'slots', COUNT(*) FROM slots
UNION ALL SELECT 'attendance_records', COUNT(*) FROM attendance_records
UNION ALL SELECT 'face_embeddings', COUNT(*) FROM face_embeddings
ORDER BY table_name;
