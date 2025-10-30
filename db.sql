-- =====================================================
-- FUACS Database Schema - Complete SQL Script
-- FU Attendance Checking Smart System
-- Version: 2.0 - Enhanced with 50+ records per table
-- Generated: 2025-01-24
-- =====================================================

-- =====================================================
-- SECTION 1: DROP EXISTING OBJECTS
-- =====================================================

-- Drop tables in reverse dependency order
DROP TABLE IF EXISTS exam_attendance_remarks CASCADE;
DROP TABLE IF EXISTS exam_slot_participants CASCADE;
DROP TABLE IF EXISTS exam_slot_subjects CASCADE;
DROP TABLE IF EXISTS exam_attendance CASCADE;
DROP TABLE IF EXISTS exam_attendance_evidences CASCADE;
DROP TABLE IF EXISTS regular_attendance_evidences CASCADE;
DROP TABLE IF EXISTS regular_attendance_remarks CASCADE;
DROP TABLE IF EXISTS attendance_records CASCADE;
DROP TABLE IF EXISTS slots CASCADE;
DROP TABLE IF EXISTS notification_deliveries CASCADE;
DROP TABLE IF EXISTS system_notifications CASCADE;
DROP TABLE IF EXISTS operational_audit_logs CASCADE;
DROP TABLE IF EXISTS system_configurations CASCADE;
DROP TABLE IF EXISTS face_embeddings CASCADE;
DROP TABLE IF EXISTS cameras CASCADE;
DROP TABLE IF EXISTS rooms CASCADE;
DROP TABLE IF EXISTS enrollments CASCADE;
DROP TABLE IF EXISTS classes CASCADE;
DROP TABLE IF EXISTS subject_majors CASCADE;
DROP TABLE IF EXISTS subjects CASCADE;
DROP TABLE IF EXISTS semesters CASCADE;
DROP TABLE IF EXISTS staff_profiles CASCADE;
DROP TABLE IF EXISTS student_profiles CASCADE;
DROP TABLE IF EXISTS majors CASCADE;
DROP TABLE IF EXISTS role_permissions CASCADE;
DROP TABLE IF EXISTS user_roles CASCADE;
DROP TABLE IF EXISTS permissions CASCADE;
DROP TABLE IF EXISTS roles CASCADE;
DROP TABLE IF EXISTS password_reset_tokens CASCADE;
DROP TABLE IF EXISTS users CASCADE;

-- =====================================================
-- SECTION 2: CREATE EXTENSIONS
-- =====================================================

CREATE EXTENSION IF NOT EXISTS vector;

-- =====================================================
-- SECTION 3: CREATE TABLES
-- =====================================================

-- -----------------------------------------------------
-- Table: users
-- -----------------------------------------------------
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(128) NOT NULL UNIQUE,
    full_name VARCHAR(150) NOT NULL,
    password_hash VARCHAR(255) NULL
);

-- -----------------------------------------------------
-- Table: password_reset_tokens
-- -----------------------------------------------------
CREATE TABLE password_reset_tokens (
    id SERIAL PRIMARY KEY,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP NOT NULL,
    email VARCHAR(128) NOT NULL,
    token_hash VARCHAR(100) NOT NULL UNIQUE
);

-- -----------------------------------------------------
-- Table: roles
-- -----------------------------------------------------
CREATE TABLE roles (
    id SMALLSERIAL PRIMARY KEY,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    name VARCHAR(100) NOT NULL UNIQUE
);

-- -----------------------------------------------------
-- Table: permissions
-- -----------------------------------------------------
CREATE TABLE permissions (
    id SMALLSERIAL PRIMARY KEY,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    name VARCHAR(100) NOT NULL UNIQUE
);

-- -----------------------------------------------------
-- Table: user_roles
-- -----------------------------------------------------
CREATE TABLE user_roles (
    user_id INTEGER NOT NULL,
    role_id SMALLINT NOT NULL,
    PRIMARY KEY (user_id, role_id),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE CASCADE
);

-- -----------------------------------------------------
-- Table: role_permissions
-- -----------------------------------------------------
CREATE TABLE role_permissions (
    role_id SMALLINT NOT NULL,
    permission_id SMALLINT NOT NULL,
    PRIMARY KEY (role_id, permission_id),
    FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE CASCADE,
    FOREIGN KEY (permission_id) REFERENCES permissions(id) ON DELETE CASCADE
);

-- -----------------------------------------------------
-- Table: majors
-- -----------------------------------------------------
CREATE TABLE majors (
    id SMALLSERIAL PRIMARY KEY,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    name VARCHAR(150) NOT NULL UNIQUE,
    code VARCHAR(20) NOT NULL UNIQUE
);

-- -----------------------------------------------------
-- Table: student_profiles
-- -----------------------------------------------------
CREATE TABLE student_profiles (
    user_id INTEGER PRIMARY KEY,
    major_id SMALLINT NOT NULL,
    roll_number VARCHAR(20) NOT NULL UNIQUE,
    base_photo_url VARCHAR(255) NULL,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (major_id) REFERENCES majors(id)
);

-- -----------------------------------------------------
-- Table: staff_profiles
-- -----------------------------------------------------
CREATE TABLE staff_profiles (
    user_id INTEGER PRIMARY KEY,
    staff_code VARCHAR(20) NOT NULL UNIQUE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- -----------------------------------------------------
-- Table: semesters
-- -----------------------------------------------------
CREATE TABLE semesters (
    id SMALLSERIAL PRIMARY KEY,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    name VARCHAR(20) NOT NULL UNIQUE,
    code VARCHAR(10) NOT NULL UNIQUE,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL
);

-- -----------------------------------------------------
-- Table: subjects
-- -----------------------------------------------------
CREATE TABLE subjects (
    id SMALLSERIAL PRIMARY KEY,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    name VARCHAR(150) NOT NULL,
    code VARCHAR(20) NOT NULL UNIQUE
);

-- -----------------------------------------------------
-- Table: subject_majors
-- -----------------------------------------------------
CREATE TABLE subject_majors (
    subject_id SMALLINT NOT NULL,
    major_id SMALLINT NOT NULL,
    PRIMARY KEY (subject_id, major_id),
    FOREIGN KEY (subject_id) REFERENCES subjects(id) ON DELETE CASCADE,
    FOREIGN KEY (major_id) REFERENCES majors(id) ON DELETE CASCADE
);

-- -----------------------------------------------------
-- Table: classes
-- -----------------------------------------------------
CREATE TABLE classes (
    id SMALLSERIAL PRIMARY KEY,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    subject_id SMALLINT NOT NULL,
    semester_id SMALLINT NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    code VARCHAR(20) NOT NULL,
    FOREIGN KEY (subject_id) REFERENCES subjects(id),
    FOREIGN KEY (semester_id) REFERENCES semesters(id)
);

CREATE UNIQUE INDEX idx_classes_subject_semester_code ON classes(subject_id, semester_id, code);
CREATE INDEX idx_classes_semester_id ON classes(semester_id);
CREATE INDEX idx_classes_subject_id ON classes(subject_id);

-- -----------------------------------------------------
-- Table: enrollments
-- -----------------------------------------------------
CREATE TABLE enrollments (
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    class_id SMALLINT NOT NULL,
    student_user_id INTEGER NOT NULL,
    is_enrolled BOOLEAN NOT NULL DEFAULT TRUE,
    PRIMARY KEY (class_id, student_user_id),
    FOREIGN KEY (class_id) REFERENCES classes(id) ON DELETE CASCADE,
    FOREIGN KEY (student_user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX idx_enrollments_class_id_enrolled ON enrollments(class_id, is_enrolled);
CREATE INDEX idx_enrollments_student_user_id ON enrollments(student_user_id);

-- -----------------------------------------------------
-- Table: rooms
-- -----------------------------------------------------
CREATE TABLE rooms (
    id SMALLSERIAL PRIMARY KEY,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    name VARCHAR(150) NOT NULL UNIQUE,
    location VARCHAR(255) NULL
);

-- -----------------------------------------------------
-- Table: cameras
-- -----------------------------------------------------
CREATE TABLE cameras (
    id SMALLSERIAL PRIMARY KEY,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    room_id SMALLINT NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    name VARCHAR(150) NOT NULL UNIQUE,
    rtsp_url VARCHAR(512) NOT NULL UNIQUE,
    FOREIGN KEY (room_id) REFERENCES rooms(id)
);

-- -----------------------------------------------------
-- Table: slots
-- -----------------------------------------------------
CREATE TABLE slots (
    id SERIAL PRIMARY KEY,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    start_time TIMESTAMP NOT NULL,
    end_time TIMESTAMP NOT NULL,
    class_id SMALLINT NULL,
    semester_id SMALLINT NOT NULL,
    room_id SMALLINT NOT NULL,
    staff_user_id INTEGER NOT NULL,
    slot_category VARCHAR(20) NOT NULL CHECK (slot_category IN ('LECTURE', 'LECTURE_WITH_PT', 'FINAL_EXAM')),
    title VARCHAR(255) NULL,
    description TEXT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    FOREIGN KEY (class_id) REFERENCES classes(id),
    FOREIGN KEY (semester_id) REFERENCES semesters(id),
    FOREIGN KEY (room_id) REFERENCES rooms(id),
    FOREIGN KEY (staff_user_id) REFERENCES users(id)
);

CREATE INDEX idx_slots_class_id ON slots(class_id);
CREATE INDEX idx_slots_semester_id ON slots(semester_id);
CREATE INDEX idx_slots_staff_user_id ON slots(staff_user_id);
CREATE INDEX idx_slots_room_id ON slots(room_id);
CREATE INDEX idx_slots_start_time ON slots(start_time);

-- -----------------------------------------------------
-- Table: attendance_records
-- -----------------------------------------------------
CREATE TABLE attendance_records (
    id BIGSERIAL PRIMARY KEY,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    recorded_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    student_user_id INTEGER NOT NULL,
    slot_id INTEGER NOT NULL,
    status VARCHAR(20) NOT NULL CHECK (status IN ('not_yet', 'present', 'absent')),
    method VARCHAR(20) NOT NULL CHECK (method IN ('auto', 'manual', 'system_finalize')),
    FOREIGN KEY (student_user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (slot_id) REFERENCES slots(id) ON DELETE CASCADE
);

CREATE UNIQUE INDEX idx_attendance_records_student_slot ON attendance_records(student_user_id, slot_id);
CREATE INDEX idx_attendance_records_slot_id ON attendance_records(slot_id);
CREATE INDEX idx_attendance_records_status ON attendance_records(status);

-- -----------------------------------------------------
-- Table: regular_attendance_remarks
-- -----------------------------------------------------
CREATE TABLE regular_attendance_remarks (
    id BIGSERIAL PRIMARY KEY,
    attendance_record_id BIGINT NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by_user_id INTEGER NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    remark TEXT NOT NULL,
    FOREIGN KEY (attendance_record_id) REFERENCES attendance_records(id) ON DELETE CASCADE,
    FOREIGN KEY (created_by_user_id) REFERENCES users(id)
);

CREATE INDEX idx_regular_attendance_remarks_record_id ON regular_attendance_remarks(attendance_record_id);
CREATE INDEX idx_regular_attendance_remarks_created_by ON regular_attendance_remarks(created_by_user_id);
CREATE INDEX idx_regular_attendance_remarks_created_at ON regular_attendance_remarks(created_at);

-- -----------------------------------------------------
-- Table: regular_attendance_evidences
-- -----------------------------------------------------
CREATE TABLE regular_attendance_evidences (
    id BIGSERIAL PRIMARY KEY,
    attendance_record_id BIGINT NOT NULL UNIQUE,
    image_url VARCHAR(255) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (attendance_record_id) REFERENCES attendance_records(id) ON DELETE CASCADE
);

-- -----------------------------------------------------
-- Table: exam_attendance
-- -----------------------------------------------------
CREATE TABLE exam_attendance (
    id BIGSERIAL PRIMARY KEY,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    recorded_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    student_user_id INTEGER NOT NULL,
    slot_id INTEGER NOT NULL,
    status VARCHAR(20) NOT NULL CHECK (status IN ('not_yet', 'present', 'absent')),
    method VARCHAR(20) NOT NULL CHECK (method IN ('auto', 'manual', 'system_finalize')),
    FOREIGN KEY (student_user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (slot_id) REFERENCES slots(id) ON DELETE CASCADE
);

CREATE UNIQUE INDEX idx_exam_attendance_student_slot ON exam_attendance(student_user_id, slot_id);
CREATE INDEX idx_exam_attendance_slot_id ON exam_attendance(slot_id);
CREATE INDEX idx_exam_attendance_status ON exam_attendance(status);

-- -----------------------------------------------------
-- Table: exam_slot_subjects
-- -----------------------------------------------------
CREATE TABLE exam_slot_subjects (
    id BIGSERIAL PRIMARY KEY,
    slot_id INTEGER NOT NULL,
    subject_id SMALLINT NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deactivated_at TIMESTAMP,
    deactivated_by_user_id INTEGER,
    FOREIGN KEY (slot_id) REFERENCES slots(id) ON DELETE CASCADE,
    FOREIGN KEY (subject_id) REFERENCES subjects(id),
    CONSTRAINT fk_exam_slot_subjects_deactivated_by FOREIGN KEY (deactivated_by_user_id) REFERENCES users(id)
);

CREATE UNIQUE INDEX idx_exam_slot_subjects_slot_subject ON exam_slot_subjects(slot_id, subject_id);
CREATE INDEX idx_exam_slot_subjects_slot_id ON exam_slot_subjects(slot_id);
CREATE INDEX idx_exam_slot_subjects_active ON exam_slot_subjects(slot_id, is_active) WHERE is_active = true;

COMMENT ON COLUMN exam_slot_subjects.is_active IS 'Soft delete flag - false means logically deleted but data preserved for audit';
COMMENT ON COLUMN exam_slot_subjects.deactivated_at IS 'Timestamp when subject was removed from exam slot';
COMMENT ON COLUMN exam_slot_subjects.deactivated_by_user_id IS 'User ID who removed the subject (for audit trail)';

-- -----------------------------------------------------
-- Table: exam_slot_participants
-- -----------------------------------------------------
CREATE TABLE exam_slot_participants (
    id BIGSERIAL PRIMARY KEY,
    exam_slot_subject_id BIGINT NOT NULL,
    student_user_id INTEGER NOT NULL,
    is_enrolled BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (exam_slot_subject_id) REFERENCES exam_slot_subjects(id) ON DELETE CASCADE,
    FOREIGN KEY (student_user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE UNIQUE INDEX idx_exam_participants_slot_subject_student ON exam_slot_participants(exam_slot_subject_id, student_user_id);
CREATE INDEX idx_exam_participants_student_user_id ON exam_slot_participants(student_user_id);

-- -----------------------------------------------------
-- Table: exam_attendance_remarks
-- -----------------------------------------------------
CREATE TABLE exam_attendance_remarks (
    id BIGSERIAL PRIMARY KEY,
    exam_attendance_id BIGINT NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by_user_id INTEGER NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    remark TEXT NOT NULL,
    FOREIGN KEY (exam_attendance_id) REFERENCES exam_attendance(id) ON DELETE CASCADE,
    FOREIGN KEY (created_by_user_id) REFERENCES users(id)
);

CREATE INDEX idx_exam_attendance_remarks_exam_id ON exam_attendance_remarks(exam_attendance_id);
CREATE INDEX idx_exam_attendance_remarks_created_by ON exam_attendance_remarks(created_by_user_id);
CREATE INDEX idx_exam_attendance_remarks_created_at ON exam_attendance_remarks(created_at);

-- -----------------------------------------------------
-- Table: exam_attendance_evidences
-- -----------------------------------------------------
CREATE TABLE exam_attendance_evidences (
    id BIGSERIAL PRIMARY KEY,
    exam_attendance_id BIGINT NOT NULL UNIQUE,
    image_url VARCHAR(255) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (exam_attendance_id) REFERENCES exam_attendance(id) ON DELETE CASCADE
);

-- -----------------------------------------------------
-- Table: face_embeddings
-- -----------------------------------------------------
CREATE TABLE face_embeddings (
    id SERIAL PRIMARY KEY,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    student_user_id INTEGER NOT NULL,
    version INTEGER NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT FALSE,
    embedding_vector vector(512) NOT NULL,
    FOREIGN KEY (student_user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE UNIQUE INDEX idx_face_embeddings_student_active ON face_embeddings(student_user_id) WHERE is_active = true;
CREATE INDEX idx_face_embeddings_vector ON face_embeddings USING ivfflat (embedding_vector vector_cosine_ops) WITH (lists = 100);

-- -----------------------------------------------------
-- Table: system_notifications
-- -----------------------------------------------------
CREATE TABLE system_notifications (
    id BIGSERIAL PRIMARY KEY,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    notification_type VARCHAR(50) NOT NULL,
    title VARCHAR(255) NOT NULL,
    content TEXT NOT NULL
);

CREATE INDEX idx_system_notifications_type ON system_notifications(notification_type);

-- -----------------------------------------------------
-- Table: notification_deliveries
-- -----------------------------------------------------
CREATE TABLE notification_deliveries (
    id BIGSERIAL PRIMARY KEY,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    read_at TIMESTAMP NULL,
    notification_id BIGINT NOT NULL,
    recipient_user_id INTEGER NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    FOREIGN KEY (notification_id) REFERENCES system_notifications(id) ON DELETE CASCADE,
    FOREIGN KEY (recipient_user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX idx_notification_deliveries_recipient_unread ON notification_deliveries(recipient_user_id, read_at);
CREATE INDEX idx_notification_deliveries_recipient_created ON notification_deliveries(recipient_user_id, created_at);

-- -----------------------------------------------------
-- Table: system_configurations
-- -----------------------------------------------------
CREATE TABLE system_configurations (
    id SERIAL PRIMARY KEY,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    key VARCHAR(255) NOT NULL UNIQUE,
    value TEXT NOT NULL,
    description TEXT NULL
);

-- -----------------------------------------------------
-- Table: operational_audit_logs
-- -----------------------------------------------------
CREATE TABLE operational_audit_logs (
    id BIGSERIAL PRIMARY KEY,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    actor_user_id INTEGER NOT NULL,
    action_type VARCHAR(20) NOT NULL CHECK (action_type IN ('CREATE', 'UPDATE', 'DELETE', 'REOPEN', 'APPROVE', 'REJECT', 'ACTIVATE', 'DEACTIVATE')),
    target_entity VARCHAR(50) NOT NULL CHECK (target_entity IN ('user', 'role', 'permission', 'semester', 'major', 'subject', 'class', 'slot', 'enrollment', 'attendance_record', 'exam_attendance', 'room', 'camera', 'system_config')),
    target_id BIGINT NOT NULL,
    changes JSONB NULL,
    FOREIGN KEY (actor_user_id) REFERENCES users(id)
);

CREATE INDEX idx_audit_logs_actor_user_id ON operational_audit_logs(actor_user_id);
CREATE INDEX idx_audit_logs_target_entity_id ON operational_audit_logs(target_entity, target_id);
CREATE INDEX idx_audit_logs_created_at ON operational_audit_logs(created_at);
CREATE INDEX idx_audit_logs_action_type ON operational_audit_logs(action_type);

-- =====================================================
-- SECTION 4: TEST DATA FOR ATTENDANCE SYSTEM (PRIORITY)
-- =====================================================

-- Test Roles (required for user role assignments)
INSERT INTO roles (id, name, is_active) VALUES
(1, 'SYSTEM_ADMIN', TRUE),
(2, 'DATA_OPERATOR', TRUE),
(3, 'LECTURER', TRUE),
(4, 'SUPERVISOR', TRUE),
(5, 'STUDENT', TRUE)
ON CONFLICT (id) DO UPDATE SET 
    name = EXCLUDED.name,
    is_active = EXCLUDED.is_active;

-- Test Majors (required for student profiles)
INSERT INTO majors (id, name, code, is_active) VALUES
(1, 'Software Engineering', 'SE', TRUE),
(2, 'Information Assurance', 'IA', TRUE),
(3, 'Artificial Intelligence', 'AI', TRUE)
ON CONFLICT (id) DO UPDATE SET 
    name = EXCLUDED.name,
    code = EXCLUDED.code,
    is_active = EXCLUDED.is_active;

-- Test Subjects (required for classes)
INSERT INTO subjects (id, name, code, is_active) VALUES
(9901, 'Test Programming Fundamentals', 'TPRF192', TRUE),
(9902, 'Test Programming Techniques', 'TPRO192', TRUE)
ON CONFLICT (id) DO UPDATE SET 
    name = EXCLUDED.name,
    code = EXCLUDED.code,
    is_active = EXCLUDED.is_active;

-- Add test semester for attendance testing (Spring 2025)
INSERT INTO semesters (id, name, code, start_date, end_date, is_active) VALUES
(99, 'Spring 2025 TEST', 'SP25T', '2025-01-06', '2025-05-09', TRUE)
ON CONFLICT (id) DO UPDATE SET 
    name = EXCLUDED.name,
    code = EXCLUDED.code,
    start_date = EXCLUDED.start_date,
    end_date = EXCLUDED.end_date,
    is_active = EXCLUDED.is_active;

-- Test Users with explicit IDs
INSERT INTO users (id, username, email, full_name, password_hash, is_active) VALUES
-- Test Lecturer (ID: 9001)
(9001, 'testlec001', 'testlec001@fpt.edu.vn', 'Dr. Test Lecturer', '$2a$12$aSEiCWX1/2jbK5LLgQCwo.Ql4NDzvjYhX6KD0bAtk8eWhSv3X.O3O', TRUE),
-- Test Data Operator (ID: 9002)
(9002, 'testdop001', 'testdop001@fpt.edu.vn', 'Test Data Operator', '$2a$12$aSEiCWX1/2jbK5LLgQCwo.Ql4NDzvjYhX6KD0bAtk8eWhSv3X.O3O', TRUE),
-- Test Students (IDs: 9010-9019)
(9010, 'hieundhe180314', 'hieundhe180314@fpt.edu.vn', 'Nguyen Doan Hieu', '$2a$12$aSEiCWX1/2jbK5LLgQCwo.Ql4NDzvjYhX6KD0bAtk8eWhSv3X.O3O', TRUE),
(9011, 'TEST000002', 'test000002@fpt.edu.vn', 'Test Student 2', '$2a$12$aSEiCWX1/2jbK5LLgQCwo.Ql4NDzvjYhX6KD0bAtk8eWhSv3X.O3O', TRUE),
(9012, 'TEST000003', 'test000003@fpt.edu.vn', 'Test Student 3', '$2a$12$aSEiCWX1/2jbK5LLgQCwo.Ql4NDzvjYhX6KD0bAtk8eWhSv3X.O3O', TRUE),
(9013, 'TEST000004', 'test000004@fpt.edu.vn', 'Test Student 4', '$2a$12$aSEiCWX1/2jbK5LLgQCwo.Ql4NDzvjYhX6KD0bAtk8eWhSv3X.O3O', TRUE),
(9014, 'TEST000005', 'test000005@fpt.edu.vn', 'Test Student 5', '$2a$12$aSEiCWX1/2jbK5LLgQCwo.Ql4NDzvjYhX6KD0bAtk8eWhSv3X.O3O', TRUE),
(9015, 'TEST000006', 'test000006@fpt.edu.vn', 'Test Student 6', '$2a$12$aSEiCWX1/2jbK5LLgQCwo.Ql4NDzvjYhX6KD0bAtk8eWhSv3X.O3O', TRUE),
(9016, 'TEST000007', 'test000007@fpt.edu.vn', 'Test Student 7', '$2a$12$aSEiCWX1/2jbK5LLgQCwo.Ql4NDzvjYhX6KD0bAtk8eWhSv3X.O3O', TRUE),
(9017, 'TEST000008', 'test000008@fpt.edu.vn', 'Test Student 8', '$2a$12$aSEiCWX1/2jbK5LLgQCwo.Ql4NDzvjYhX6KD0bAtk8eWhSv3X.O3O', TRUE),
(9018, 'TEST000009', 'test000009@fpt.edu.vn', 'Test Student 9', '$2a$12$aSEiCWX1/2jbK5LLgQCwo.Ql4NDzvjYhX6KD0bAtk8eWhSv3X.O3O', TRUE),
(9019, 'TEST000010', 'test000010@fpt.edu.vn', 'Test Student 10', '$2a$12$aSEiCWX1/2jbK5LLgQCwo.Ql4NDzvjYhX6KD0bAtk8eWhSv3X.O3O', TRUE)
ON CONFLICT (id) DO UPDATE SET 
    username = EXCLUDED.username,
    email = EXCLUDED.email,
    full_name = EXCLUDED.full_name,
    password_hash = EXCLUDED.password_hash,
    is_active = EXCLUDED.is_active;

-- Test Staff Profiles
INSERT INTO staff_profiles (user_id, staff_code) VALUES
(9001, 'TESTLEC001'),
(9002, 'TESTDOP001')
ON CONFLICT (user_id) DO UPDATE SET staff_code = EXCLUDED.staff_code;

-- Test Student Profiles (SE major = 1)
INSERT INTO student_profiles (user_id, major_id, roll_number, base_photo_url) VALUES
(9010, 1, 'HE180314', '/photos/test_student_1.jpg'),
(9011, 1, 'TEST000002', '/photos/test_student_2.jpg'),
(9012, 1, 'TEST000003', '/photos/test_student_3.jpg'),
(9013, 1, 'TEST000004', '/photos/test_student_4.jpg'),
(9014, 1, 'TEST000005', '/photos/test_student_5.jpg'),
(9015, 1, 'TEST000006', '/photos/test_student_6.jpg'),
(9016, 1, 'TEST000007', '/photos/test_student_7.jpg'),
(9017, 1, 'TEST000008', '/photos/test_student_8.jpg'),
(9018, 1, 'TEST000009', '/photos/test_student_9.jpg'),
(9019, 1, 'TEST000010', '/photos/test_student_10.jpg')
ON CONFLICT (user_id) DO UPDATE SET 
    major_id = EXCLUDED.major_id,
    roll_number = EXCLUDED.roll_number,
    base_photo_url = EXCLUDED.base_photo_url;

-- Test Infrastructure
INSERT INTO rooms (id, name, location, is_active) VALUES
(901, 'Test Room 101', 'Test Building - Floor 1', TRUE)
ON CONFLICT (id) DO UPDATE SET 
    name = EXCLUDED.name,
    location = EXCLUDED.location,
    is_active = EXCLUDED.is_active;

INSERT INTO cameras (id, room_id, name, rtsp_url, is_active) VALUES
(9001, 901, 'TEST-CAM-101-FRONT', 'rtsp://192.168.1.101:554/stream1', FALSE),
(9002, 901, 'TEST-CAM-101-BACK', 'rtsp://C200C_FUACS2:12345678@192.168.1.80:554/stream1', TRUE)
ON CONFLICT (id) DO UPDATE SET 
    room_id = EXCLUDED.room_id,
    name = EXCLUDED.name,
    rtsp_url = EXCLUDED.rtsp_url,
    is_active = EXCLUDED.is_active;

-- Test Classes (using test subjects TPRF192=9901, TPRO192=9902)
INSERT INTO classes (id, subject_id, semester_id, code, is_active) VALUES
(901, 9901, 99, 'TEST01', TRUE),  -- TPRF192_TEST01
(902, 9902, 99, 'TEST01', TRUE)   -- TPRO192_TEST01
ON CONFLICT (id) DO UPDATE SET 
    subject_id = EXCLUDED.subject_id,
    semester_id = EXCLUDED.semester_id,
    code = EXCLUDED.code,
    is_active = EXCLUDED.is_active;

-- Test Enrollments
INSERT INTO enrollments (class_id, student_user_id, is_enrolled) VALUES
-- Class 901 (TPRF192): Students 1-5
(901, 9010, TRUE), (901, 9011, TRUE), (901, 9012, TRUE), (901, 9013, TRUE), (901, 9014, TRUE),
-- Class 902 (TPRO192): Students 6-10
(902, 9015, TRUE), (902, 9016, TRUE), (902, 9017, TRUE), (902, 9018, TRUE), (902, 9019, TRUE)
ON CONFLICT (class_id, student_user_id) DO UPDATE SET is_enrolled = EXCLUDED.is_enrolled;

-- Test Slots with Dynamic Timing
INSERT INTO slots (id, class_id, semester_id, room_id, staff_user_id, slot_category, start_time, end_time, title, is_active) VALUES
-- Slot 9001: CURRENTLY ACTIVE (started 1 hour ago, ends in 1 hour)
(9001, 901, 99, 901, 9001, 'LECTURE',
 CURRENT_TIMESTAMP - INTERVAL '1 hour',
 CURRENT_TIMESTAMP + INTERVAL '1 hour',
 'TEST: Active Lecture Session', TRUE),

-- Slot 9002: ENDED (ended 30 minutes ago)
(9002, 902, 99, 901, 9001, 'LECTURE_WITH_PT',
 CURRENT_TIMESTAMP - INTERVAL '2 hours 30 minutes',
 CURRENT_TIMESTAMP - INTERVAL '30 minutes',
 'TEST: Ended Lecture with Progress Test', TRUE),

-- Slot 9003: ENDED (ended yesterday)
(9003, 901, 99, 901, 9001, 'LECTURE',
 CURRENT_TIMESTAMP - INTERVAL '1 day 2 hours',
 CURRENT_TIMESTAMP - INTERVAL '1 day',
 'TEST: Ended Lecture Session', TRUE),

-- Slot 9004: FUTURE FINAL EXAM (tomorrow)
(9004, NULL, 99, 901, 9001, 'FINAL_EXAM',
 CURRENT_TIMESTAMP + INTERVAL '1 day',
 CURRENT_TIMESTAMP + INTERVAL '1 day 2 hours',
 'TEST: Final Exam Session', TRUE)
ON CONFLICT (id) DO UPDATE SET 
    class_id = EXCLUDED.class_id,
    semester_id = EXCLUDED.semester_id,
    room_id = EXCLUDED.room_id,
    staff_user_id = EXCLUDED.staff_user_id,
    slot_category = EXCLUDED.slot_category,
    start_time = EXCLUDED.start_time,
    end_time = EXCLUDED.end_time,
    title = EXCLUDED.title,
    is_active = EXCLUDED.is_active;

-- Test Attendance Records for Ended Slot (9003)
INSERT INTO attendance_records (student_user_id, slot_id, status, method, recorded_at) VALUES
(9010, 9003, 'present', 'auto', CURRENT_TIMESTAMP - INTERVAL '23 hours 45 minutes'),
(9011, 9003, 'present', 'auto', CURRENT_TIMESTAMP - INTERVAL '23 hours 45 minutes'),
(9012, 9003, 'present', 'auto', CURRENT_TIMESTAMP - INTERVAL '23 hours 45 minutes'),
(9013, 9003, 'absent', 'manual', CURRENT_TIMESTAMP - INTERVAL '23 hours 45 minutes'),
(9014, 9003, 'not_yet', 'manual', CURRENT_TIMESTAMP - INTERVAL '23 hours 45 minutes')
ON CONFLICT (student_user_id, slot_id) DO NOTHING;

-- Test Attendance Records for Ended Slot (9002) - Partial
INSERT INTO attendance_records (student_user_id, slot_id, status, method, recorded_at) VALUES
(9015, 9002, 'present', 'auto', CURRENT_TIMESTAMP - INTERVAL '45 minutes'),
(9016, 9002, 'present', 'auto', CURRENT_TIMESTAMP - INTERVAL '45 minutes'),
(9017, 9002, 'present', 'auto', CURRENT_TIMESTAMP - INTERVAL '45 minutes')
ON CONFLICT (student_user_id, slot_id) DO NOTHING;

-- Test Exam Attendance for LECTURE_WITH_PT Slot (9002)
INSERT INTO exam_attendance (student_user_id, slot_id, status, method, recorded_at) VALUES
(9015, 9002, 'present', 'auto', CURRENT_TIMESTAMP - INTERVAL '45 minutes'),
(9016, 9002, 'present', 'auto', CURRENT_TIMESTAMP - INTERVAL '45 minutes'),
(9017, 9002, 'present', 'auto', CURRENT_TIMESTAMP - INTERVAL '45 minutes'),
(9018, 9002, 'not_yet', 'auto', CURRENT_TIMESTAMP - INTERVAL '45 minutes'),
(9019, 9002, 'not_yet', 'auto', CURRENT_TIMESTAMP - INTERVAL '45 minutes')
ON CONFLICT (student_user_id, slot_id) DO NOTHING;

-- Test Final Exam Setup
INSERT INTO exam_slot_subjects (id, slot_id, subject_id) VALUES
(9001, 9004, 9901)  -- TPRF192 in Final Exam Slot
ON CONFLICT (id) DO UPDATE SET 
    slot_id = EXCLUDED.slot_id,
    subject_id = EXCLUDED.subject_id;

INSERT INTO exam_slot_participants (exam_slot_subject_id, student_user_id, is_enrolled) VALUES
(9001, 9010, TRUE), (9001, 9011, TRUE), (9001, 9012, TRUE), (9001, 9013, TRUE), (9001, 9014, TRUE)
ON CONFLICT (exam_slot_subject_id, student_user_id) DO UPDATE SET is_enrolled = EXCLUDED.is_enrolled;

-- Test Face Embeddings
INSERT INTO face_embeddings (student_user_id, version, is_active, embedding_vector) VALUES
(9010, 1, TRUE, ARRAY[-0.5835024118423462, 0.50245201587677, 0.896336019039154, -0.4407934546470642, -1.9964419603347778, -0.1779630035161972, -0.9335520267486572, 0.27253052592277527, 0.3581202030181885, 0.65994793176651, 1.2679443359375, -1.0593444108963013, 0.7842183709144592, 0.22208116948604584, 1.294180154800415, -0.05545070767402649, 0.7957504391670227, 1.1108888387680054, 0.6504064202308655, -0.34720754623413086, -0.5341433882713318, 0.3759872615337372, -0.8300740122795105, -1.831863284111023, -1.5724132061004639, -0.48108428716659546, 0.32831117510795593, -0.6501279473304749, 0.49532103538513184, -1.2343041896820068, -0.6424176096916199, -0.29717662930488586, -0.6108628511428833, -0.778894305229187, -0.6118712425231934, 0.13406933844089508, 0.5675441026687622, 0.07385426759719849, -1.3753172159194946, 0.09902298450469971, 1.05400812625885, -1.7693382501602173, -1.0790029764175415, 1.1572657823562622, -0.14480304718017578, 0.6331146359443665, 0.5548997521400452, 2.7912120819091797, 0.3576892614364624, 1.0424304008483887, -0.6512094736099243, -1.516672968864441, -0.8158175945281982, -0.46724608540534973, -0.22461174428462982, -0.014742468483746052, -1.9899412393569946, 1.5871895551681519, 1.2279646396636963, -1.1328203678131104, 1.0587209463119507, 0.08166331052780151, -0.6956900358200073, 0.8282143473625183, -1.4051395654678345, 0.29317373037338257, -1.363294005393982, 1.07673180103302, 0.3736633360385895, -0.5777919292449951, -0.5983853936195374, -1.806923270225525, -0.2691883146762848, -0.5023587346076965, 0.8527482151985168, 1.2797232866287231, 0.23180273175239563, 0.3165859878063202, -1.7301478385925293, -0.08017369359731674, -0.15126867592334747, -1.6313940286636353, 1.7660109996795654, -1.2429536581039429, 0.3138302266597748, 0.25363990664482117, -0.06860806047916412, -1.863006591796875, -0.23312529921531677, 1.2934502363204956, -0.7646347880363464, 1.1975066661834717, 0.19569003582000732, -1.541773796081543, 1.1820456981658936, 2.49164080619812, -1.1238162517547607, -1.7963005304336548, 0.41003215312957764, -0.5080172419548035, -0.35857900977134705, 1.9245818853378296, -0.48720619082450867, 0.9734317064285278, 2.2935991287231445, -0.5729565620422363, -1.2379646301269531, 0.2479037195444107, 0.7791087031364441, 0.28965508937835693, -0.26095178723335266, 0.6694138050079346, -1.2034119367599487, -0.3984949588775635, -0.5126281380653381, -0.9566653966903687, -0.22143620252609253, -0.5887079834938049, -0.4078473746776581, -0.5306024551391602, -1.6394739151000977, -0.7918188571929932, -1.3315277099609375, 0.0968419685959816, 0.5604592561721802, 0.2345477193593979, -0.2461806982755661, 0.4487711787223816, -0.9418860077857971, 0.5577585697174072, 0.28001150488853455, 0.8880125880241394, -0.3792753219604492, 0.46747395396232605, 0.6187987327575684, 0.2727481424808502, -1.1440598964691162, 0.152540922164917, -0.24359486997127533, 1.6300947666168213, 0.8014504313468933, -0.03196791931986809, 0.26315656304359436, -0.4210026264190674, -1.0930061340332031, -0.15907305479049683, 0.024641506373882294, 0.5318843722343445, -2.43587064743042, -0.8865798711776733, -0.6559662818908691, -0.5703712701797485, -0.3097209632396698, 0.044856127351522446, 1.7414871454238892, -1.1234763860702515, 0.34495455026626587, -0.11425122618675232, 0.799609363079071, -0.5103648900985718, 0.6725770235061646, -0.4366903305053711, -0.4012583792209625, 0.25081777572631836, -1.6459720134735107, 0.2581835389137268, -0.8645505905151367, -0.8166513442993164, 0.35941582918167114, -0.25321444869041443, 1.4386440515518188, 0.5628817081451416, -0.3090774118900299, 0.9332335591316223, -1.6619974374771118, -0.25400876998901367, 0.2606370747089386, -0.4300847053527832, 0.7948266863822937, 0.3772152066230774, -1.3536876440048218, -0.31252026557922363, 0.7570120096206665, 0.5610584020614624, 0.1522192358970642, -0.9739643931388855, 1.140436053276062, -0.5630074143409729, 0.9754299521446228, -0.032403454184532166, -0.0940241888165474, 1.7051359415054321, 0.13352812826633453, 0.43734264373779297, 0.6565631031990051, -0.6991981863975525, 0.535983681678772, 0.7845455408096313, -0.5570648908615112, 0.252849280834198, -1.0463565587997437, -0.80745530128479, 1.1812127828598022, 0.9324499368667603, -0.25409698486328125, -0.3081766366958618, -0.5611456632614136, -0.7354682087898254, 0.7852334976196289, 0.3076976537704468, -0.24840375781059265, -0.08129724115133286, -0.7237866520881653, -0.2273525893688202, 0.5897196531295776, 1.95318603515625, 0.9712434411048889, 0.5000068545341492, 1.552878499031067, -1.498424768447876, 0.15445013344287872, 2.0381979942321777, -1.1655683517456055, 0.6688051819801331, -0.3246212899684906, 0.05523146316409111, 0.6569308042526245, 1.0505380630493164, 0.4477135241031647, 2.5677738189697266, 0.017575759440660477, -0.7723966240882874, 0.8445420265197754, 1.170422077178955, 0.4605233669281006, 2.416849136352539, 2.1762611865997314, 0.55464106798172, -0.04560256004333496, -1.485606074333191, 1.328011393547058, 0.8332991600036621, -1.02935791015625, 0.482141375541687, -1.0127041339874268, -1.2041393518447876, -0.27893540263175964, 1.4014101028442383, 1.0658702850341797, 0.27288323640823364, -2.267483711242676, -0.8401522636413574, 1.2556371688842773, -0.14725470542907715, 1.8225661516189575, 0.723011314868927, -0.07344374060630798, 0.5773366093635559, 0.030994419008493423, -0.12077634781599045, -0.6457744240760803, 0.14005644619464874, -2.1362080574035645, 0.9990038275718689, -0.10293599218130112, -0.05420013889670372, 0.08810614049434662, 1.0172948837280273, 1.7248601913452148, 0.5678285956382751, 1.607657551765442, 0.49113717675209045, 1.4261858463287354, 0.3250066339969635, 0.18199209868907928, -2.556363344192505, -1.1215966939926147, 0.2656436860561371, 1.436308741569519, -0.6740546822547913, -0.6359946131706238, 0.3387722373008728, -0.0757516548037529, 0.3295116722583771, 0.6038289666175842, 0.25763556361198425, -1.6198588609695435, -0.8728083372116089, 0.6368581652641296, -0.5591431260108948, -0.6393990516662598, -0.4724821448326111, 0.04629553109407425, -0.4812885522842407, -1.2221659421920776, 1.2057830095291138, 1.8363230228424072, -1.1433966159820557, -0.1412484347820282, -0.23367221653461456, -0.2762207090854645, 0.7195333242416382, 0.8945049047470093, 0.4412629008293152, 0.5091768503189087, 0.5287696123123169, 0.12075760215520859, -0.536771833896637, 0.4867432713508606, 0.2239300161600113, -1.1218852996826172, -0.17157217860221863, -1.2475873231887817, 1.783782720565796, -1.0665197372436523, 1.3387013673782349, 0.2809651494026184, -0.016510646790266037, -0.053519107401371, 0.034280601888895035, 0.9605094194412231, 0.12127147614955902, 0.31341251730918884, 0.506597638130188, -1.1122376918792725, 1.9742838144302368, -0.2526107430458069, -1.8984991312026978, 0.6240314245223999, -0.7209300994873047, 1.1168673038482666, -1.6313402652740479, 0.7160075306892395, -0.4907272756099701, -0.9944823384284973, 0.4790540337562561, -0.6490978002548218, -1.5190798044204712, -1.0993858575820923, -1.387501835823059, -1.3601468801498413, 1.0002456903457642, 0.8965207934379578, 0.8573675155639648, -1.090453863143921, 0.7695137858390808, 0.21686014533042908, 0.026581600308418274, 0.6620240807533264, 0.28250935673713684, 0.0031117629259824753, 0.2953852713108063, 0.5389810800552368, -0.3199141025543213, 0.06745747476816177, -0.2670612931251526, -1.034650444984436, 1.2931110858917236, -0.20183013379573822, 0.9656556248664856, -0.9316796660423279, -0.3259674906730652, 1.7124758958816528, -1.2566107511520386, -0.05827361345291138, -0.08412758260965347, 0.6519262194633484, 1.034407138824463, 0.587497353553772, 0.34033530950546265, 2.1067981719970703, 0.23402686417102814, -0.9947364330291748, 0.9288806319236755, 1.079174518585205, -0.025600677356123924, -1.4098807573318481, -0.564993679523468, -0.14211037755012512, -0.38853007555007935, -0.3173966705799103, 0.05996549874544144, 0.9362522959709167, -0.8211536407470703, 0.30098918080329895, -0.024328429251909256, 0.7738460302352905, -1.90152907371521, -1.3355598449707031, 0.651940643787384, 1.240555763244629, 0.34020549058914185, -0.6226027607917786, 0.8479859828948975, -0.36996662616729736, 1.0257292985916138, -0.1789209395647049, 2.085878610610962, -0.613822877407074, 1.3612583875656128, 0.7040590643882751, -1.6573878526687622, -0.12924079596996307, -0.7799963355064392, -1.4222949743270874, -1.55934476852417, -0.49501413106918335, -1.391198992729187, -0.2942439615726471, 0.006118989549577236, -0.7331206798553467, -0.8087881803512573, 0.09375712275505066, -1.3470406532287598, -0.6667678356170654, -1.1274006366729736, 0.3648098409175873, -0.5650971531867981, -0.7806481719017029, -0.041021108627319336, -0.9639521837234497, 0.35185176134109497, -0.2211449146270752, -0.2869942784309387, -1.435455560684204, 0.6645557880401611, -1.649644374847412, 0.8679008483886719, 0.5100522041320801, -1.1200066804885864, 1.8665004968643188, 0.20341278612613678, 0.31843316555023193, -2.1051762104034424, 0.9088919162750244, -0.881277859210968, -1.7573215961456299, -0.3028319180011749, 1.0871202945709229, 1.7775617837905884, 0.401559978723526, 0.2944221496582031, 0.46668505668640137, 0.4961373209953308, -2.0124378204345703, -0.06571869552135468, -1.785636067390442, -0.16479536890983582, -1.4276951551437378, 1.1123303174972534, 0.1592852622270584, 0.3712882399559021, -0.3790637254714966, -0.1423787772655487, 0.6396015882492065, -0.15686087310314178, -0.474960058927536, 0.40407341718673706, 0.3075273931026459, -0.3033602237701416, -0.19573268294334412, 0.03354117274284363, 0.4943251311779022, -0.01636572554707527, 1.9831600189208984, 0.710787296295166, -0.8139164447784424, -1.2208391427993774, 0.5595974326133728, -0.5528544783592224, -0.5470572113990784, 0.9773487448692322, 0.06145768240094185, 3.057204008102417, -0.9854753613471985, -0.7820608019828796, -0.5881623029708862, 0.6811593770980835, 2.0526580810546875, 1.1838443279266357, 1.9728189706802368, -0.26811814308166504, 0.7842233777046204, -0.7970166206359863, 0.8099263906478882, 0.8731174468994141, -1.1556392908096313, -1.0837302207946777, 0.7202556133270264, 0.5564387440681458, -1.54757821559906, 0.03836432099342346, 0.11420989781618118, -0.7683001756668091, -0.3351735770702362, -0.2435094565153122, -0.37619641423225403, 0.4372188150882721, 0.9415102005004883, 0.15764039754867554, 0.19614842534065247, -0.08063381910324097, 0.07038944959640503, -0.18410667777061462, 0.5617995858192444, 1.1207817792892456, 0.45661696791648865, -0.04566505551338196, -1.1893222332000732, 0.12343109399080276, -1.315894603729248, -0.3770480453968048]::vector),
(9011, 1, TRUE, array_fill(0.2::REAL, ARRAY[512])::vector),
(9012, 1, TRUE, array_fill(0.3::REAL, ARRAY[512])::vector),
(9013, 1, TRUE, array_fill(0.4::REAL, ARRAY[512])::vector),
(9014, 1, TRUE, array_fill(0.5::REAL, ARRAY[512])::vector),
(9015, 1, TRUE, array_fill(0.6::REAL, ARRAY[512])::vector),
(9016, 1, TRUE, array_fill(0.7::REAL, ARRAY[512])::vector),
(9017, 1, TRUE, array_fill(0.8::REAL, ARRAY[512])::vector),
(9018, 1, TRUE, array_fill(0.9::REAL, ARRAY[512])::vector),
(9019, 1, TRUE, array_fill(1.0::REAL, ARRAY[512])::vector)
ON CONFLICT (student_user_id) WHERE is_active = true DO NOTHING;

-- Test User Role Assignments (must be after roles are created)
INSERT INTO user_roles (user_id, role_id) VALUES
-- Lecturer role
(9001, 3),
-- Data Operator role  
(9002, 2),
-- Student roles
(9010, 5), (9011, 5), (9012, 5), (9013, 5), (9014, 5),
(9015, 5), (9016, 5), (9017, 5), (9018, 5), (9019, 5)
ON CONFLICT DO NOTHING;

-- =====================================================
-- SECTION 5: INSERT FIXED DATA (Roles, Permissions, Majors, etc.)
-- =====================================================

-- -----------------------------------------------------
-- Insert Roles (using ON CONFLICT to handle test data)
-- -----------------------------------------------------
INSERT INTO roles (id, name, is_active) VALUES
(1, 'SYSTEM_ADMIN', TRUE),
(2, 'DATA_OPERATOR', TRUE),
(3, 'LECTURER', TRUE),
(4, 'SUPERVISOR', TRUE),
(5, 'STUDENT', TRUE)
ON CONFLICT (id) DO UPDATE SET 
    name = EXCLUDED.name,
    is_active = EXCLUDED.is_active;

-- -----------------------------------------------------
-- Insert Permissions (Master Catalog)
-- -----------------------------------------------------
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
-- Academic Catalog Management
('SEMESTER_CREATE', TRUE),
('SEMESTER_READ', TRUE),
('SEMESTER_UPDATE', TRUE),
('SEMESTER_DELETE_HARD', TRUE),
('MAJOR_CREATE', TRUE),
('MAJOR_READ', TRUE),
('MAJOR_UPDATE', TRUE),
('MAJOR_DELETE_HARD', TRUE),
('SUBJECT_CREATE', TRUE),
('SUBJECT_READ', TRUE),
('SUBJECT_UPDATE', TRUE),
('SUBJECT_DELETE_HARD', TRUE),
('CLASS_CREATE', TRUE),
('CLASS_READ', TRUE),
('CLASS_UPDATE', TRUE),
('CLASS_DELETE_HARD', TRUE),
('SLOT_CREATE', TRUE),
('SLOT_READ', TRUE),
('SLOT_UPDATE', TRUE),
('SLOT_DELETE_HARD', TRUE),
('ENROLLMENT_MANAGE', TRUE),
('SLOT_UPDATE_CATEGORY', TRUE),
('SLOT_CREATE_FINAL_EXAM', TRUE),
('SLOT_UPDATE_FINAL_EXAM', TRUE),
('SLOT_DELETE_HARD_FINAL_EXAM', TRUE),
('MAJOR_IMPORT', TRUE),
('SUBJECT_IMPORT', TRUE),
('SEMESTER_IMPORT', TRUE),
('CLASS_IMPORT', TRUE),
('SLOT_IMPORT', TRUE),
-- Infrastructure Management
('ROOM_CREATE', TRUE),
('ROOM_READ', TRUE),
('ROOM_UPDATE', TRUE),
('ROOM_DELETE_HARD', TRUE),
('ROOM_IMPORT', TRUE),
('CAMERA_CREATE', TRUE),
('CAMERA_READ', TRUE),
('CAMERA_UPDATE', TRUE),
('CAMERA_DELETE_HARD', TRUE),
('CAMERA_IMPORT', TRUE),
-- Attendance Management
('OWN_SCHEDULE_READ', TRUE),
('SLOT_SESSION_START', TRUE),
('SLOT_SESSION_RESCAN', TRUE),
('ATTENDANCE_ROSTER_READ', TRUE),
('ATTENDANCE_STATUS_UPDATE_MANUAL', TRUE),
('ATTENDANCE_REMARK_MANAGE', TRUE),
-- Reporting and Data
('REPORT_READ_OWN_SLOT', TRUE),
('REPORT_EXPORT_OWN_SLOT', TRUE),
('REPORT_READ_CLASS_SUMMARY', TRUE),
('REPORT_READ_SYSTEM_WIDE', TRUE),
('REPORT_EXPORT_ACADEMIC_DATA', TRUE),
('AUDIT_LOG_READ', TRUE),
-- System Administration
('SYSTEM_CONFIG_READ', TRUE),
('SYSTEM_CONFIG_UPDATE', TRUE),
('ROLE_PERMISSION_MAPPING_READ', TRUE),
('ROLE_PERMISSION_MAPPING_UPDATE', TRUE),
('SYSTEM_LOG_READ', TRUE),
('ROLE_CREATE', TRUE),
('ROLE_UPDATE', TRUE),
('ROLE_DELETE_HARD', TRUE),
('PERMISSION_CREATE', TRUE),
('PERMISSION_UPDATE', TRUE),
('PERMISSION_DELETE_HARD', TRUE),
-- Student Permissions
('OWN_ATTENDANCE_HISTORY_READ', TRUE),
-- General Permissions
('OWN_PROFILE_READ', TRUE),
('OWN_PASSWORD_UPDATE', TRUE);

-- -----------------------------------------------------
-- Insert Role-Permission Mappings
-- -----------------------------------------------------

-- SYSTEM_ADMIN permissions
INSERT INTO role_permissions (role_id, permission_id)
SELECT 1, id FROM permissions WHERE name IN (
    'SYSTEM_CONFIG_READ', 'SYSTEM_CONFIG_UPDATE', 'ROLE_PERMISSION_MAPPING_READ',
    'ROLE_PERMISSION_MAPPING_UPDATE', 'SYSTEM_LOG_READ', 'OWN_PROFILE_READ',
    'OWN_PASSWORD_UPDATE', 'ROLE_CREATE', 'ROLE_READ', 'ROLE_UPDATE', 'ROLE_DELETE_HARD',
    'PERMISSION_CREATE', 'PERMISSION_UPDATE', 'PERMISSION_DELETE_HARD'
);

-- DATA_OPERATOR permissions
INSERT INTO role_permissions (role_id, permission_id)
SELECT 2, id FROM permissions WHERE name IN (
    'USER_CREATE', 'USER_READ_LIST', 'USER_READ_DETAIL', 'USER_UPDATE_INFO',
    'USER_UPDATE_STATUS', 'USER_ASSIGN_ROLES', 'SEMESTER_CREATE', 'SEMESTER_READ',
    'SEMESTER_UPDATE', 'SEMESTER_IMPORT', 'MAJOR_CREATE', 'MAJOR_READ', 'MAJOR_UPDATE',
    'MAJOR_IMPORT', 'SUBJECT_CREATE', 'SUBJECT_READ', 'SUBJECT_UPDATE', 'SUBJECT_IMPORT',
    'CLASS_CREATE', 'CLASS_READ', 'CLASS_UPDATE', 'CLASS_IMPORT', 'SLOT_CREATE',
    'SLOT_READ', 'SLOT_UPDATE', 'SLOT_IMPORT', 'ENROLLMENT_MANAGE',
    'SLOT_CREATE_FINAL_EXAM', 'SLOT_UPDATE_FINAL_EXAM', 'SLOT_DELETE_HARD_FINAL_EXAM',
    'ATTENDANCE_ROSTER_READ', 'ATTENDANCE_STATUS_UPDATE_MANUAL', 'ATTENDANCE_REMARK_MANAGE',
    'ROOM_CREATE', 'ROOM_READ', 'ROOM_UPDATE', 'ROOM_IMPORT',
    'CAMERA_CREATE', 'CAMERA_READ', 'CAMERA_UPDATE', 'CAMERA_IMPORT',
    'REPORT_READ_SYSTEM_WIDE', 'REPORT_EXPORT_ACADEMIC_DATA', 'AUDIT_LOG_READ',
    'OWN_PROFILE_READ', 'OWN_PASSWORD_UPDATE', 'ROLE_READ'
);

-- LECTURER permissions
INSERT INTO role_permissions (role_id, permission_id)
SELECT 3, id FROM permissions WHERE name IN (
    'OWN_SCHEDULE_READ', 'SLOT_SESSION_START', 'SLOT_SESSION_RESCAN',
    'ATTENDANCE_ROSTER_READ', 'ATTENDANCE_STATUS_UPDATE_MANUAL', 'ATTENDANCE_REMARK_MANAGE',
    'REPORT_READ_OWN_SLOT', 'REPORT_EXPORT_OWN_SLOT', 'REPORT_READ_CLASS_SUMMARY',
    'REPORT_READ_SYSTEM_WIDE', 'OWN_PROFILE_READ', 'OWN_PASSWORD_UPDATE', 'ROOM_READ',
    'CAMERA_READ', 'SEMESTER_READ', 'CLASS_READ', 'MAJOR_READ', 'SLOT_READ',
    'SUBJECT_READ', 'SLOT_UPDATE_CATEGORY', 'ROLE_READ'
);

-- SUPERVISOR permissions
INSERT INTO role_permissions (role_id, permission_id)
SELECT 4, id FROM permissions WHERE name IN (
    'OWN_SCHEDULE_READ', 'SLOT_SESSION_START', 'SLOT_SESSION_RESCAN',
    'ATTENDANCE_ROSTER_READ', 'ATTENDANCE_STATUS_UPDATE_MANUAL', 'ATTENDANCE_REMARK_MANAGE',
    'REPORT_READ_OWN_SLOT', 'REPORT_EXPORT_OWN_SLOT', 'REPORT_READ_SYSTEM_WIDE',
    'OWN_PROFILE_READ', 'OWN_PASSWORD_UPDATE', 'ROOM_READ', 'CAMERA_READ',
    'SEMESTER_READ', 'CLASS_READ', 'MAJOR_READ', 'SLOT_READ', 'SUBJECT_READ', 'ROLE_READ'
);

-- STUDENT permissions
INSERT INTO role_permissions (role_id, permission_id)
SELECT 5, id FROM permissions WHERE name IN (
    'OWN_SCHEDULE_READ', 'OWN_ATTENDANCE_HISTORY_READ', 'OWN_PROFILE_READ',
    'OWN_PASSWORD_UPDATE', 'ROOM_READ', 'SEMESTER_READ', 'CLASS_READ',
    'MAJOR_READ', 'SLOT_READ', 'SUBJECT_READ', 'ROLE_READ'
);

-- -----------------------------------------------------
-- Insert Majors (IDs 4+ to avoid conflict with test data)
-- -----------------------------------------------------
INSERT INTO majors (id, name, code, is_active) VALUES
(4, 'Internet of Things', 'IOT', TRUE),
(5, 'Digital Art Design', 'DAD', TRUE),
(6, 'Business Administration', 'BA', TRUE),
(7, 'Multimedia Communications', 'MC', TRUE),
(8, 'Mobile and Web Technology', 'MWT', TRUE)
ON CONFLICT (id) DO UPDATE SET 
    name = EXCLUDED.name,
    code = EXCLUDED.code,
    is_active = EXCLUDED.is_active;

-- -----------------------------------------------------
-- Insert Semesters
-- -----------------------------------------------------
INSERT INTO semesters (name, code, start_date, end_date, is_active) VALUES
('Spring 2023', 'SP23', '2023-01-09', '2023-05-12', TRUE),
('Summer 2023', 'SU23', '2023-05-22', '2023-09-01', TRUE),
('Fall 2023', 'FA23', '2023-09-04', '2023-12-22', TRUE),
('Spring 2024', 'SP24', '2024-01-08', '2024-05-10', TRUE),
('Summer 2024', 'SU24', '2024-05-20', '2024-08-30', TRUE),
('Fall 2024', 'FA24', '2024-09-02', '2024-12-20', TRUE),
('Spring 2025', 'SP25', '2025-01-06', '2025-05-09', TRUE),
('Summer 2025', 'SU25', '2025-05-19', '2025-08-29', TRUE),
('Fall 2025', 'FA25', '2025-09-01', '2025-12-19', TRUE);

-- -----------------------------------------------------
-- Insert Subjects
-- -----------------------------------------------------
INSERT INTO subjects (name, code, is_active) VALUES
('Programming Fundamentals', 'PRF192', TRUE),
('Object-Oriented Programming', 'PRO192', TRUE),
('Data Structures and Algorithms', 'CSD201', TRUE),
('Database Management Systems', 'DBI202', TRUE),
('Web Development', 'SWP391', TRUE),
('Software Engineering', 'SWE201', TRUE),
('Mobile Application Development', 'PRM392', TRUE),
('Machine Learning', 'MLA301', TRUE),
('Computer Networks', 'NWC203', TRUE),
('Operating Systems', 'OSG202', TRUE),
('Information Security', 'SEC301', TRUE),
('Cloud Computing', 'CLD201', TRUE),
('Business Intelligence', 'BIN301', TRUE),
('Project Management', 'PMG302', TRUE),
('Digital Marketing', 'MKT301', TRUE),
('Advanced Java', 'JPD123', TRUE),
('Python Programming', 'PYF101', TRUE),
('DevOps Practices', 'DOP301', TRUE),
('Cybersecurity Fundamentals', 'CSF201', TRUE),
('UI/UX Design', 'UIX301', TRUE);

-- -----------------------------------------------------
-- Insert Subject-Major Mappings
-- -----------------------------------------------------
INSERT INTO subject_majors (subject_id, major_id) VALUES
-- Software Engineering subjects
(1, 1), (2, 1), (3, 1), (4, 1), (5, 1), (6, 1), (7, 1), (9, 1), (10, 1), (16, 1), (17, 1), (18, 1),
-- Information Assurance subjects
(1, 2), (2, 2), (3, 2), (4, 2), (9, 2), (10, 2), (11, 2), (12, 2), (19, 2),
-- Artificial Intelligence subjects
(1, 3), (2, 3), (3, 3), (4, 3), (8, 3), (10, 3), (17, 3),
-- Internet of Things subjects
(1, 4), (2, 4), (3, 4), (9, 4), (10, 4), (12, 4),
-- Digital Art Design subjects
(20, 5), (15, 5),
-- Business Administration subjects
(13, 6), (14, 6), (15, 6),
-- Multimedia Communications subjects
(20, 7), (15, 7), (5, 7),
-- Mobile and Web Technology subjects
(1, 8), (2, 8), (5, 8), (7, 8), (17, 8);

-- -----------------------------------------------------
-- Insert System Configurations
-- -----------------------------------------------------
INSERT INTO system_configurations (key, value, description, is_active) VALUES
('face_recognition.similarity_threshold', '0.85', 'Minimum similarity score for face recognition matches (0.0 to 1.0)', TRUE),
('attendance.max_absence_percentage', '20', 'Maximum allowed absence percentage before student becomes ineligible for final exam', TRUE),
('attendance.evidence_retention_days', '30', 'Number of days to retain attendance evidence images before cleanup', TRUE),
('attendance.edit_window_hours', '24', 'Hours after slot end time during which lecturer can edit attendance (within same day)', TRUE),
('notification.email_enabled', 'true', 'Whether to send email notifications in addition to in-app notifications', TRUE),
('notification.push_enabled', 'true', 'Whether to send push notifications to mobile devices', TRUE),
('system.maintenance_mode', 'false', 'System maintenance mode flag', TRUE),
('face_recognition.model_version', 'v2.1.0', 'Current face recognition model version in use', TRUE),
('face_recognition.min_face_size', '80', 'Minimum face size in pixels for detection', TRUE);

-- -----------------------------------------------------
-- Insert System Notifications
-- -----------------------------------------------------
INSERT INTO system_notifications (notification_type, title, content, is_active) VALUES
('identity_rejected', 'Identity Verification Rejected', 'Your identity verification request has been rejected. Please review the reason and submit again.', TRUE),
('identity_approved', 'Identity Verification Approved', 'Your identity verification has been approved. You can now use the attendance system.', TRUE),
('absence_warning_10', 'Absence Warning - 10%', 'You have reached 10% absence rate. Please be aware of the attendance policy.', TRUE),
('absence_warning_20', 'Absence Warning - 20%', 'You have reached 20% absence rate. You are at risk of being ineligible for the final exam.', TRUE),
('absence_critical', 'Critical Absence Alert', 'You have exceeded the maximum allowed absence rate and are now ineligible for the final exam.', TRUE),
('slot_cancelled', 'Slot Cancelled', 'A scheduled slot has been cancelled. Please check your schedule for updates.', TRUE),
('slot_rescheduled', 'Slot Rescheduled', 'A slot has been rescheduled. Please check the new time and location.', TRUE);

-- =====================================================
-- SECTION 5: GENERATE DATA USING PL/pgSQL (50+ records per table)
-- =====================================================

DO $$
DECLARE
    v_password_hash VARCHAR(255) := '$2a$12$aSEiCWX1/2jbK5LLgQCwo.Ql4NDzvjYhX6KD0bAtk8eWhSv3X.O3O'; -- Password: "password123"
    v_user_id INT;
    v_student_count INT := 0;
    v_lecturer_count INT := 0;
    v_dop_count INT := 0;
    v_supervisor_count INT := 0;
    v_class_id INT;
    v_slot_id INT;
    v_exam_slot_subject_id BIGINT;
    v_semester_id INT := 6; -- FA24 (avoid conflict with test semester 99)
    v_room_count INT;
    v_class_number INT;
    
    -- Vietnamese first names
    v_first_names TEXT[] := ARRAY['Nguyen', 'Tran', 'Le', 'Pham', 'Hoang', 'Vu', 'Vo', 'Dang', 'Bui', 'Do', 'Ngo', 'Duong', 'Ly'];
    v_middle_names TEXT[] := ARRAY['Van', 'Thi', 'Minh', 'Hoang', 'Thanh', 'Quoc', 'Anh', 'Duc', 'Khanh', 'Duy'];
    v_last_names TEXT[] := ARRAY['An', 'Binh', 'Cuong', 'Dung', 'Em', 'Phuong', 'Giang', 'Hoa', 'Hung', 'Khanh', 'Linh', 'Mai', 'Nam', 'Oanh', 'Phong', 'Quynh', 'Son', 'Tuan', 'Uyen', 'Vinh', 'Xuan', 'Yen', 'Anh', 'Bao', 'Chi', 'Dat', 'Huy', 'Long', 'Quan', 'Tam', 'Thao', 'Trang'];
    
    v_full_name TEXT;
    v_username TEXT;
    v_email TEXT;
    v_major_id INT;
    v_subject_id INT;
    v_staff_id INT;
    v_room_id INT;
    v_start_time TIMESTAMP;
    v_end_time TIMESTAMP;
    v_slot_category TEXT;

    i INT;
    j INT;
    k INT;
BEGIN
    RAISE NOTICE 'Starting data generation...';
    
    -- =====================================================
    -- 1. GENERATE USERS (100+ total: 80 students, 15 lecturers, 5 DOPs, 5 supervisors)
    -- =====================================================
    RAISE NOTICE 'Generating users...';
    
    -- System Admin (1 user) - Use ID 1000+ to avoid conflict with test data
    INSERT INTO users (id, username, email, full_name, password_hash, is_active)
    VALUES (1000, 'admin001', 'admin001@fpt.edu.vn', 'Nguyen Van Admin', v_password_hash, TRUE)
    ON CONFLICT (id) DO NOTHING;
    
    -- God User with all permissions (Super Admin) - Use ID 1001
    INSERT INTO users (id, username, email, full_name, password_hash, is_active)
    VALUES (1001, 'god000', 'god000@fpt.edu.vn', 'God Super Admin', v_password_hash, TRUE)
    ON CONFLICT (id) DO NOTHING
    RETURNING id INTO v_user_id;
    
    INSERT INTO staff_profiles (user_id, staff_code)
    VALUES (1001, 'GOD000')
    ON CONFLICT (user_id) DO NOTHING;
    
    -- Assign SYSTEM_ADMIN role
    INSERT INTO user_roles (user_id, role_id) VALUES (1001, 1) ON CONFLICT DO NOTHING;
    
    -- Additionally assign all other roles for complete access
    INSERT INTO user_roles (user_id, role_id) 
    SELECT 1001, id FROM roles WHERE id > 1 ON CONFLICT DO NOTHING;
    
    -- Data Operators (5 users) - Use IDs 1010-1014 to avoid conflict
    FOR i IN 1..5 LOOP
        v_full_name := v_first_names[1 + (i % array_length(v_first_names, 1))] || ' ' || 
                       v_middle_names[1 + (i % array_length(v_middle_names, 1))] || ' DOP' || i;
        v_username := 'dop' || LPAD(i::TEXT, 3, '0');
        v_email := v_username || '@fpt.edu.vn';
        v_user_id := 1009 + i; -- IDs 1010-1014
        
        INSERT INTO users (id, username, email, full_name, password_hash, is_active)
        VALUES (v_user_id, v_username, v_email, v_full_name, v_password_hash, TRUE)
        ON CONFLICT (id) DO NOTHING;
        
        INSERT INTO staff_profiles (user_id, staff_code)
        VALUES (v_user_id, 'DOP' || LPAD(i::TEXT, 3, '0'))
        ON CONFLICT (user_id) DO NOTHING;
        
        INSERT INTO user_roles (user_id, role_id) VALUES (v_user_id, 2) ON CONFLICT DO NOTHING; -- DATA_OPERATOR role
        
        v_dop_count := v_dop_count + 1;
    END LOOP;
    
    -- Lecturers (15 users) - Use IDs 1020-1034 to avoid conflict
    FOR i IN 1..15 LOOP
        v_full_name := CASE 
            WHEN i % 3 = 0 THEN 'Dr. '
            WHEN i % 3 = 1 THEN 'MSc. '
            ELSE 'Prof. '
        END || v_first_names[1 + (i % array_length(v_first_names, 1))] || ' ' || 
               v_middle_names[1 + (i % array_length(v_middle_names, 1))] || ' ' ||
               v_last_names[1 + (i % array_length(v_last_names, 1))];
        v_username := 'lec' || LPAD(i::TEXT, 3, '0');
        v_email := v_username || '@fpt.edu.vn';
        v_user_id := 1019 + i; -- IDs 1020-1034
        
        INSERT INTO users (id, username, email, full_name, password_hash, is_active)
        VALUES (v_user_id, v_username, v_email, v_full_name, v_password_hash, TRUE)
        ON CONFLICT (id) DO NOTHING;
        
        INSERT INTO staff_profiles (user_id, staff_code)
        VALUES (v_user_id, 'LEC' || LPAD(i::TEXT, 3, '0'))
        ON CONFLICT (user_id) DO NOTHING;
        
        INSERT INTO user_roles (user_id, role_id) VALUES (v_user_id, 3) ON CONFLICT DO NOTHING; -- LECTURER role
        
        v_lecturer_count := v_lecturer_count + 1;
    END LOOP;
    
    -- Supervisors (5 users)
    FOR i IN 1..5 LOOP
        v_full_name := v_first_names[1 + (i % array_length(v_first_names, 1))] || ' ' || 
                       v_middle_names[1 + (i % array_length(v_middle_names, 1))] || ' Supervisor' || i;
        v_username := 'sup' || LPAD(i::TEXT, 3, '0');
        v_email := v_username || '@fpt.edu.vn';
        
        INSERT INTO users (username, email, full_name, password_hash, is_active)
        VALUES (v_username, v_email, v_full_name, v_password_hash, TRUE)
        RETURNING id INTO v_user_id;
        
        INSERT INTO staff_profiles (user_id, staff_code)
        VALUES (v_user_id, 'SUP' || LPAD(i::TEXT, 3, '0'));
        
        INSERT INTO user_roles (user_id, role_id) VALUES (v_user_id, 4); -- SUPERVISOR role
        
        v_supervisor_count := v_supervisor_count + 1;
    END LOOP;
    
    -- Students (80 users, distributed across majors)
    FOR i IN 1..80 LOOP
        v_major_id := 1 + ((i - 1) % 8); -- Distribute across 8 majors
        
        v_full_name := v_first_names[1 + (i % array_length(v_first_names, 1))] || ' ' || 
                       v_middle_names[1 + ((i * 3) % array_length(v_middle_names, 1))] || ' ' ||
                       v_last_names[1 + ((i * 7) % array_length(v_last_names, 1))];
        
        -- Generate username based on major
        v_username := CASE v_major_id
            WHEN 1 THEN 'HE' -- SE
            WHEN 2 THEN 'HS' -- IA
            WHEN 3 THEN 'HA' -- AI
            WHEN 4 THEN 'HI' -- IOT
            WHEN 5 THEN 'HD' -- DAD
            WHEN 6 THEN 'HB' -- BA
            WHEN 7 THEN 'HM' -- MC
            ELSE 'HW' -- MWT
        END || '18' || LPAD(i::TEXT, 4, '0');
        
        v_email := LOWER(v_username) || '@fpt.edu.vn';
        
        INSERT INTO users (username, email, full_name, password_hash, is_active)
        VALUES (v_username, v_email, v_full_name, v_password_hash, TRUE)
        RETURNING id INTO v_user_id;
        
        INSERT INTO student_profiles (user_id, major_id, roll_number, base_photo_url)
        VALUES (v_user_id, v_major_id, v_username, '/photos/' || LOWER(v_username) || '_base.jpg');
        
        INSERT INTO user_roles (user_id, role_id) VALUES (v_user_id, 5); -- STUDENT role
        
        v_student_count := v_student_count + 1;
    END LOOP;
    
    RAISE NOTICE 'Generated % students, % lecturers, % DOPs, % supervisors', 
                  v_student_count, v_lecturer_count, v_dop_count, v_supervisor_count;
    
    -- =====================================================
    -- 2. GENERATE ROOMS AND CAMERAS (50+ rooms, 100+ cameras)
    -- =====================================================
    RAISE NOTICE 'Generating rooms and cameras...';
    
    FOR i IN 1..60 LOOP
        v_room_id := (SELECT id FROM rooms ORDER BY id DESC LIMIT 1) + 1;
        
        INSERT INTO rooms (name, location, is_active)
        VALUES (
            CASE 
                WHEN i <= 30 THEN 'Room ' || (100 + i)
                WHEN i <= 45 THEN 'Lab ' || (400 + i - 30)
                ELSE 'Auditorium ' || CHR(64 + i - 45)
            END,
            CASE 
                WHEN i <= 15 THEN 'Building Alpha - Floor ' || ((i - 1) / 5 + 1)
                WHEN i <= 30 THEN 'Building Beta - Floor ' || ((i - 16) / 5 + 1)
                WHEN i <= 45 THEN 'Building Gamma - Floor ' || ((i - 31) / 5 + 1)
                ELSE 'Building Delta - Ground Floor'
            END,
            TRUE
        )
        RETURNING id INTO v_room_id;
        
        -- Each room gets 2-3 cameras
        FOR j IN 1..(2 + (i % 2)) LOOP
            INSERT INTO cameras (room_id, name, rtsp_url, is_active)
            VALUES (
                v_room_id,
                'CAM-' || v_room_id || '-' || CASE j 
                    WHEN 1 THEN 'FRONT'
                    WHEN 2 THEN 'BACK'
                    ELSE 'SIDE'
                END,
                'rtsp://192.168.' || ((v_room_id - 1) / 250 + 1) || '.' || 
                ((v_room_id - 1) % 250 + 1) || ':554/stream' || j,
                TRUE
            );
        END LOOP;
    END LOOP;
    
    SELECT COUNT(*) INTO v_room_count FROM rooms;
    RAISE NOTICE 'Generated % rooms with cameras', v_room_count;
    
    -- =====================================================
    -- 3. GENERATE CLASSES (60+ classes in FA24)
    -- =====================================================
    RAISE NOTICE 'Generating classes...';

    FOR i IN 1..60 LOOP
        v_subject_id := 1 + ((i - 1) % 20); -- Cycle through 20 subjects

        -- Calculate unique class number per subject (3 classes per subject = 60 total / 20 subjects)
        v_class_number := 1 + FLOOR((i - 1) / 20);

        INSERT INTO classes (subject_id, semester_id, code, is_active)
        VALUES (
            v_subject_id,
            v_semester_id,
            (SELECT code FROM subjects WHERE id = v_subject_id) ||
            LPAD(v_class_number::TEXT, 2, '0'),
            TRUE
        )
        ON CONFLICT (subject_id, semester_id, code) DO NOTHING;
    END LOOP;
    
    RAISE NOTICE 'Generated % classes', (SELECT COUNT(*) FROM classes WHERE semester_id = v_semester_id);
    
    -- =====================================================
    -- 4. GENERATE ENROLLMENTS (1000+ enrollments, ~15-20 students per class)
    -- =====================================================
    RAISE NOTICE 'Generating enrollments...';
    
    FOR v_class_id IN (SELECT id FROM classes WHERE semester_id = v_semester_id) LOOP
        -- Enroll 15-20 random students in each class
        FOR j IN 1..(15 + (v_class_id % 6)) LOOP
            -- Pick a random student
            v_user_id := (SELECT u.id FROM users u 
                         JOIN user_roles ur ON u.id = ur.user_id 
                         WHERE ur.role_id = 5 
                         ORDER BY RANDOM() 
                         LIMIT 1);
            
            -- Check if not already enrolled
            IF NOT EXISTS (SELECT 1 FROM enrollments WHERE class_id = v_class_id AND student_user_id = v_user_id) THEN
                INSERT INTO enrollments (class_id, student_user_id, is_enrolled)
                VALUES (v_class_id, v_user_id, TRUE);
            END IF;
        END LOOP;
    END LOOP;
    
    RAISE NOTICE 'Generated % enrollments', (SELECT COUNT(*) FROM enrollments);
    
    -- =====================================================
    -- 5. GENERATE SLOTS (100+ slots: LECTURE, LECTURE_WITH_PT, FINAL_EXAM)
    -- =====================================================
    RAISE NOTICE 'Generating slots...';
    
    -- Generate LECTURE and LECTURE_WITH_PT slots for each class
    FOR v_class_id IN (SELECT id FROM classes WHERE semester_id = v_semester_id ORDER BY id LIMIT 50) LOOP
        -- Get a random lecturer
        v_staff_id := (SELECT u.id FROM users u 
                      JOIN user_roles ur ON u.id = ur.user_id 
                      WHERE ur.role_id = 3 
                      ORDER BY RANDOM() 
                      LIMIT 1);
        
        -- Get a random room
        v_room_id := (SELECT id FROM rooms ORDER BY RANDOM() LIMIT 1);
        
        -- Generate 4-6 slots per class (starting from 60 days ago to ensure past slots for test data)
        FOR j IN 1..(4 + (v_class_id % 3)) LOOP
            v_start_time := (CURRENT_TIMESTAMP - INTERVAL '60 days')::DATE::TIMESTAMP + INTERVAL '08:00:00' +
                           (((v_class_id - 1) * 7 + (j - 1) * 2) || ' days')::INTERVAL +
                           ((j % 3) * 2 || ' hours')::INTERVAL;
            v_end_time := v_start_time + '2 hours'::INTERVAL;
            
            -- Determine slot category
            v_slot_category := CASE
                WHEN j = (4 + (v_class_id % 3)) THEN 'LECTURE_WITH_PT' -- Last slot is progress test
                ELSE 'LECTURE'
            END;

            INSERT INTO slots (class_id, semester_id, room_id, staff_user_id, slot_category,
                             start_time, end_time, title, is_active)
            VALUES (
                v_class_id,
                v_semester_id,
                v_room_id,
                v_staff_id,
                v_slot_category,
                v_start_time,
                v_end_time,
                CASE v_slot_category
                    WHEN 'LECTURE_WITH_PT' THEN 'Progress Test ' || j
                    ELSE 'Lecture Session ' || j
                END,
                TRUE
            );
        END LOOP;
    END LOOP;
    
    -- Generate FINAL_EXAM slots (20 slots, starting from 10 days ago)
    FOR i IN 1..20 LOOP
        v_staff_id := (SELECT u.id FROM users u
                      JOIN user_roles ur ON u.id = ur.user_id
                      WHERE ur.role_id = 4 -- Supervisor
                      ORDER BY RANDOM()
                      LIMIT 1);

        v_room_id := (SELECT id FROM rooms WHERE name LIKE 'Auditorium%' ORDER BY RANDOM() LIMIT 1);

        v_start_time := (CURRENT_TIMESTAMP - INTERVAL '10 days')::DATE::TIMESTAMP + INTERVAL '08:00:00' +
                       ((i - 1) * 12 || ' hours')::INTERVAL;
        v_end_time := v_start_time + '2 hours'::INTERVAL;
        
        INSERT INTO slots (class_id, semester_id, room_id, staff_user_id, slot_category,
                         start_time, end_time, title, is_active)
        VALUES (
            NULL, -- FINAL_EXAM has no class_id
            v_semester_id,
            v_room_id,
            v_staff_id,
            'FINAL_EXAM',
            v_start_time,
            v_end_time,
            'Final Exam Slot ' || i,
            TRUE
        );
    END LOOP;
    
    RAISE NOTICE 'Generated % slots', (SELECT COUNT(*) FROM slots);
    
    -- =====================================================
    -- 6. GENERATE EXAM_SLOT_SUBJECTS AND EXAM_SLOT_PARTICIPANTS
    -- =====================================================
    RAISE NOTICE 'Generating exam slot subjects and participants...';
    
    FOR v_slot_id IN (SELECT id FROM slots WHERE slot_category = 'FINAL_EXAM') LOOP
        -- Each exam slot has 2-3 subjects
        FOR j IN 1..(2 + (v_slot_id % 2)) LOOP
            v_subject_id := 1 + ((v_slot_id + j - 1) % 20);
            
            INSERT INTO exam_slot_subjects (slot_id, subject_id)
            VALUES (v_slot_id, v_subject_id)
            ON CONFLICT DO NOTHING
            RETURNING id INTO v_exam_slot_subject_id;
            
            IF v_exam_slot_subject_id IS NOT NULL THEN
                -- Add 10-15 students to this exam
                FOR k IN 1..(10 + (v_slot_id % 6)) LOOP
                    v_user_id := (SELECT u.id FROM users u 
                                 JOIN user_roles ur ON u.id = ur.user_id 
                                 WHERE ur.role_id = 5 
                                 ORDER BY RANDOM() 
                                 LIMIT 1);
                    
                    INSERT INTO exam_slot_participants (exam_slot_subject_id, student_user_id, is_enrolled)
                    VALUES (v_exam_slot_subject_id, v_user_id, TRUE)
                    ON CONFLICT DO NOTHING;
                END LOOP;
            END IF;
        END LOOP;
    END LOOP;
    
    RAISE NOTICE 'Generated % exam slot subjects and % participants', 
                 (SELECT COUNT(*) FROM exam_slot_subjects),
                 (SELECT COUNT(*) FROM exam_slot_participants);
    
    -- =====================================================
    -- 7. GENERATE ATTENDANCE_RECORDS FOR PAST SLOTS
    -- =====================================================
    RAISE NOTICE 'Generating attendance records...';
    
    FOR v_slot_id IN (SELECT id FROM slots
                     WHERE slot_category IN ('LECTURE', 'LECTURE_WITH_PT')) LOOP

        -- Get class_id for this slot
        SELECT class_id INTO v_class_id FROM slots WHERE id = v_slot_id;
        
        -- Create attendance for all enrolled students
        FOR v_user_id IN (SELECT student_user_id FROM enrollments WHERE class_id = v_class_id AND is_enrolled = TRUE) LOOP
            INSERT INTO attendance_records (student_user_id, slot_id, status, method, recorded_at)
            VALUES (
                v_user_id,
                v_slot_id,
                CASE 
                    WHEN RANDOM() < 0.85 THEN 'present'
                    ELSE 'absent'
                END,
                CASE 
                    WHEN RANDOM() < 0.9 THEN 'auto'
                    ELSE 'manual'
                END,
                (SELECT start_time FROM slots WHERE id = v_slot_id) + ((10 + (RANDOM() * 20)::INT) || ' minutes')::INTERVAL
            )
            ON CONFLICT (student_user_id, slot_id) DO NOTHING;
        END LOOP;
    END LOOP;
    
    RAISE NOTICE 'Generated % attendance records', (SELECT COUNT(*) FROM attendance_records);
    
    -- =====================================================
    -- 8. GENERATE EXAM_ATTENDANCE FOR PAST LECTURE_WITH_PT SLOTS
    -- =====================================================
    RAISE NOTICE 'Generating exam attendance records...';
    
    FOR v_slot_id IN (SELECT id FROM slots
                     WHERE slot_category = 'LECTURE_WITH_PT') LOOP

        SELECT class_id INTO v_class_id FROM slots WHERE id = v_slot_id;
        
        FOR v_user_id IN (SELECT student_user_id FROM enrollments WHERE class_id = v_class_id AND is_enrolled = TRUE) LOOP
            INSERT INTO exam_attendance (student_user_id, slot_id, status, method, recorded_at)
            VALUES (
                v_user_id,
                v_slot_id,
                CASE 
                    WHEN RANDOM() < 0.88 THEN 'present'
                    ELSE 'absent'
                END,
                CASE 
                    WHEN RANDOM() < 0.92 THEN 'auto'
                    ELSE 'manual'
                END,
                (SELECT start_time FROM slots WHERE id = v_slot_id) + ((15 + (RANDOM() * 25)::INT) || ' minutes')::INTERVAL
            )
            ON CONFLICT (student_user_id, slot_id) DO NOTHING;
        END LOOP;
    END LOOP;
    
    RAISE NOTICE 'Generated % exam attendance records', (SELECT COUNT(*) FROM exam_attendance);
    
    -- =====================================================
    -- 9. GENERATE FACE_EMBEDDINGS
    -- =====================================================
    RAISE NOTICE 'Generating face embeddings...';
    
    FOR v_user_id IN (SELECT u.id FROM users u 
                     JOIN user_roles ur ON u.id = ur.user_id 
                     WHERE ur.role_id = 5 
                     LIMIT 75) LOOP
        
        -- Generate face embedding for students
        INSERT INTO face_embeddings (student_user_id, version, is_active, embedding_vector)
        VALUES (
            v_user_id,
            1,
            TRUE,
            array_fill(RANDOM()::REAL, ARRAY[512])::vector
        )
        ON CONFLICT (student_user_id) WHERE is_active = true DO NOTHING;
        
        -- Update student profile with base photo URL
        UPDATE student_profiles 
        SET base_photo_url = '/identity/student_' || v_user_id || '_photo.jpg'
        WHERE user_id = v_user_id;
    END LOOP;
    
    RAISE NOTICE 'Generated % face embeddings', 
                 (SELECT COUNT(*) FROM face_embeddings);
    
    -- =====================================================
    -- 10. GENERATE ATTENDANCE EVIDENCES
    -- =====================================================
    RAISE NOTICE 'Generating attendance evidences...';
    
    -- Regular attendance evidences
    FOR v_user_id IN (SELECT id FROM attendance_records WHERE status = 'present' AND method = 'auto' LIMIT 200) LOOP
        INSERT INTO regular_attendance_evidences (attendance_record_id, image_url, created_at)
        VALUES (
            v_user_id,
            '/evidence/regular/attendance_' || v_user_id || '_' || 
            TO_CHAR((SELECT recorded_at FROM attendance_records WHERE id = v_user_id), 'YYYYMMDD_HH24MISS') || '.jpg',
            (SELECT recorded_at FROM attendance_records WHERE id = v_user_id)
        );
    END LOOP;
    
    -- Exam attendance evidences
    FOR v_user_id IN (SELECT id FROM exam_attendance WHERE status = 'present' AND method = 'auto' LIMIT 100) LOOP
        INSERT INTO exam_attendance_evidences (exam_attendance_id, image_url, created_at)
        VALUES (
            v_user_id,
            '/evidence/exam/exam_' || v_user_id || '_' || 
            TO_CHAR((SELECT recorded_at FROM exam_attendance WHERE id = v_user_id), 'YYYYMMDD_HH24MISS') || '.jpg',
            (SELECT recorded_at FROM exam_attendance WHERE id = v_user_id)
        );
    END LOOP;
    
    RAISE NOTICE 'Generated % regular evidences and % exam evidences',
                 (SELECT COUNT(*) FROM regular_attendance_evidences),
                 (SELECT COUNT(*) FROM exam_attendance_evidences);
    
    -- =====================================================
    -- 11. GENERATE REMARKS
    -- =====================================================
    RAISE NOTICE 'Generating remarks...';
    
    DECLARE
        v_remarks TEXT[] := ARRAY[
            'Student was late due to traffic',
            'Medical certificate provided',
            'Family emergency',
            'Technical issue with camera, manually verified',
            'Student left early with permission',
            'Attendance corrected after review'
        ];
    BEGIN
        -- Regular attendance remarks
        FOR i IN 1..50 LOOP
            INSERT INTO regular_attendance_remarks (attendance_record_id, created_by_user_id, remark, is_active)
            SELECT 
                ar.id,
                s.staff_user_id,
                v_remarks[1 + (i % array_length(v_remarks, 1))],
                TRUE
            FROM attendance_records ar
            JOIN slots s ON ar.slot_id = s.id
            WHERE ar.method = 'manual'
            ORDER BY RANDOM()
            LIMIT 1;
        END LOOP;
        
        -- Exam attendance remarks (for both manual and auto methods)
        FOR i IN 1..50 LOOP
            INSERT INTO exam_attendance_remarks (exam_attendance_id, created_by_user_id, remark, is_active)
            SELECT
                ea.id,
                s.staff_user_id,
                v_remarks[1 + (i % array_length(v_remarks, 1))],
                TRUE
            FROM exam_attendance ea
            JOIN slots s ON ea.slot_id = s.id
            WHERE NOT EXISTS (
                SELECT 1 FROM exam_attendance_remarks ear
                WHERE ear.exam_attendance_id = ea.id
            )
            ORDER BY RANDOM()
            LIMIT 1;
        END LOOP;
    END;
    
    RAISE NOTICE 'Generated % regular remarks and % exam remarks',
                 (SELECT COUNT(*) FROM regular_attendance_remarks),
                 (SELECT COUNT(*) FROM exam_attendance_remarks);
    
    -- =====================================================
    -- 12. GENERATE NOTIFICATION DELIVERIES
    -- =====================================================
    RAISE NOTICE 'Generating notification deliveries...';
    
    FOR i IN 1..100 LOOP
        INSERT INTO notification_deliveries (notification_id, recipient_user_id, read_at, is_active)
        SELECT 
            (SELECT id FROM system_notifications ORDER BY RANDOM() LIMIT 1),
            (SELECT u.id FROM users u JOIN user_roles ur ON u.id = ur.user_id WHERE ur.role_id = 5 ORDER BY RANDOM() LIMIT 1),
            CASE WHEN RANDOM() < 0.7 THEN CURRENT_TIMESTAMP - ((RANDOM() * 10)::INT || ' days')::INTERVAL ELSE NULL END,
            TRUE
        ON CONFLICT DO NOTHING;
    END LOOP;
    
    RAISE NOTICE 'Generated % notification deliveries', (SELECT COUNT(*) FROM notification_deliveries);
    
    -- =====================================================
    -- 13. GENERATE OPERATIONAL AUDIT LOGS
    -- =====================================================
    RAISE NOTICE 'Generating operational audit logs...';

    -- User creation logs
    FOR v_user_id IN (SELECT id FROM users ORDER BY id DESC LIMIT 50) LOOP
        INSERT INTO operational_audit_logs (actor_user_id, action_type, target_entity, target_id, changes, created_at)
        VALUES (
            2, -- DOP001
            'CREATE',
            'user',
            v_user_id,
            jsonb_build_object('username', (SELECT username FROM users WHERE id = v_user_id)),
            (SELECT created_at FROM users WHERE id = v_user_id)
        );
    END LOOP;
    
    RAISE NOTICE 'Generated % audit logs', (SELECT COUNT(*) FROM operational_audit_logs);
    
    RAISE NOTICE 'Data generation completed successfully!';
END $$;




-- =====================================================
-- SECTION 7: VERIFICATION QUERIES
-- =====================================================

SELECT 'users' as table_name, COUNT(*) as record_count FROM users
UNION ALL
SELECT 'roles', COUNT(*) FROM roles
UNION ALL
SELECT 'permissions', COUNT(*) FROM permissions
UNION ALL
SELECT 'majors', COUNT(*) FROM majors
UNION ALL
SELECT 'semesters', COUNT(*) FROM semesters
UNION ALL
SELECT 'subjects', COUNT(*) FROM subjects
UNION ALL
SELECT 'classes', COUNT(*) FROM classes
UNION ALL
SELECT 'enrollments', COUNT(*) FROM enrollments
UNION ALL
SELECT 'rooms', COUNT(*) FROM rooms
UNION ALL
SELECT 'cameras', COUNT(*) FROM cameras
UNION ALL
SELECT 'slots', COUNT(*) FROM slots
UNION ALL
SELECT 'attendance_records', COUNT(*) FROM attendance_records
UNION ALL
SELECT 'exam_attendance', COUNT(*) FROM exam_attendance
UNION ALL
SELECT 'exam_slot_subjects', COUNT(*) FROM exam_slot_subjects
UNION ALL
SELECT 'exam_slot_participants', COUNT(*) FROM exam_slot_participants
UNION ALL
SELECT 'face_embeddings', COUNT(*) FROM face_embeddings
UNION ALL
SELECT 'system_notifications', COUNT(*) FROM system_notifications
UNION ALL
SELECT 'notification_deliveries', COUNT(*) FROM notification_deliveries
UNION ALL
SELECT 'system_configurations', COUNT(*) FROM system_configurations
UNION ALL
SELECT 'operational_audit_logs', COUNT(*) FROM operational_audit_logs
UNION ALL
SELECT 'regular_attendance_remarks', COUNT(*) FROM regular_attendance_remarks
UNION ALL
SELECT 'exam_attendance_remarks', COUNT(*) FROM exam_attendance_remarks
UNION ALL
SELECT 'regular_attendance_evidences', COUNT(*) FROM regular_attendance_evidences
UNION ALL
SELECT 'exam_attendance_evidences', COUNT(*) FROM exam_attendance_evidences
ORDER BY table_name;

-- =====================================================
-- END OF SCRIPT
-- =====================================================

SELECT 
    'Database initialization completed successfully!' as status,
    NOW() as completed_at;
