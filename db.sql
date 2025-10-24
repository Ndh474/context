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
DROP TABLE IF EXISTS identity_assets CASCADE;
DROP TABLE IF EXISTS identity_submissions CASCADE;
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
    finalized_at TIMESTAMP NULL,
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
CREATE INDEX idx_slots_finalized_at ON slots(finalized_at);

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
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (slot_id) REFERENCES slots(id) ON DELETE CASCADE,
    FOREIGN KEY (subject_id) REFERENCES subjects(id)
);

CREATE UNIQUE INDEX idx_exam_slot_subjects_slot_subject ON exam_slot_subjects(slot_id, subject_id);
CREATE INDEX idx_exam_slot_subjects_slot_id ON exam_slot_subjects(slot_id);

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
-- Table: identity_submissions
-- -----------------------------------------------------
CREATE TABLE identity_submissions (
    id SERIAL PRIMARY KEY,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    reviewed_at TIMESTAMP NULL,
    student_user_id INTEGER NOT NULL,
    reviewed_by_user_id INTEGER NULL,
    status VARCHAR(20) NOT NULL CHECK (status IN ('pending', 'approved', 'rejected')),
    submission_type VARCHAR(20) NOT NULL CHECK (submission_type IN ('initial', 'update')),
    rejection_reason TEXT NULL,
    FOREIGN KEY (student_user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (reviewed_by_user_id) REFERENCES users(id)
);

CREATE INDEX idx_identity_submissions_status ON identity_submissions(status);
CREATE INDEX idx_identity_submissions_student_user_id ON identity_submissions(student_user_id);
CREATE INDEX idx_identity_submissions_reviewed_at ON identity_submissions(reviewed_at);

-- -----------------------------------------------------
-- Table: identity_assets
-- -----------------------------------------------------
CREATE TABLE identity_assets (
    id SERIAL PRIMARY KEY,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    submission_id INTEGER NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    asset_type VARCHAR(20) NOT NULL CHECK (asset_type IN ('face_video', 'face_photo')),
    storage_url VARCHAR(255) NOT NULL,
    FOREIGN KEY (submission_id) REFERENCES identity_submissions(id) ON DELETE CASCADE
);

CREATE INDEX idx_identity_assets_submission_id ON identity_assets(submission_id);
CREATE INDEX idx_identity_assets_asset_type ON identity_assets(asset_type);
CREATE INDEX idx_identity_assets_submission_type ON identity_assets(submission_id, asset_type);

-- -----------------------------------------------------
-- Table: face_embeddings
-- -----------------------------------------------------
CREATE TABLE face_embeddings (
    id SERIAL PRIMARY KEY,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    student_user_id INTEGER NOT NULL,
    generated_from_asset_id INTEGER NOT NULL,
    version INTEGER NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT FALSE,
    embedding_vector vector(512) NOT NULL,
    FOREIGN KEY (student_user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (generated_from_asset_id) REFERENCES identity_assets(id)
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
    action_type VARCHAR(20) NOT NULL CHECK (action_type IN ('CREATE', 'UPDATE', 'DELETE', 'FINALIZE', 'REOPEN', 'APPROVE', 'REJECT', 'ACTIVATE', 'DEACTIVATE')),
    target_entity VARCHAR(50) NOT NULL CHECK (target_entity IN ('user', 'role', 'permission', 'semester', 'major', 'subject', 'class', 'slot', 'enrollment', 'attendance_record', 'exam_attendance', 'identity_submission', 'room', 'camera', 'system_config')),
    target_id BIGINT NOT NULL,
    changes JSONB NULL,
    FOREIGN KEY (actor_user_id) REFERENCES users(id)
);

CREATE INDEX idx_audit_logs_actor_user_id ON operational_audit_logs(actor_user_id);
CREATE INDEX idx_audit_logs_target_entity_id ON operational_audit_logs(target_entity, target_id);
CREATE INDEX idx_audit_logs_created_at ON operational_audit_logs(created_at);
CREATE INDEX idx_audit_logs_action_type ON operational_audit_logs(action_type);

-- =====================================================
-- SECTION 4: INSERT FIXED DATA (Roles, Permissions, Majors, etc.)
-- =====================================================

-- -----------------------------------------------------
-- Insert Roles
-- -----------------------------------------------------
INSERT INTO roles (name, is_active) VALUES
('SYSTEM_ADMIN', TRUE),
('DATA_OPERATOR', TRUE),
('LECTURER', TRUE),
('SUPERVISOR', TRUE),
('STUDENT', TRUE);

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
('SLOT_SESSION_FINALIZE', TRUE),
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
    'OWN_PASSWORD_UPDATE', 'ROLE_CREATE', 'ROLE_UPDATE', 'ROLE_DELETE_HARD',
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
    'ATTENDANCE_STATUS_UPDATE_MANUAL', 'ROOM_CREATE', 'ROOM_READ', 'ROOM_UPDATE',
    'ROOM_IMPORT', 'CAMERA_CREATE', 'CAMERA_READ', 'CAMERA_UPDATE', 'CAMERA_IMPORT',
    'REPORT_READ_SYSTEM_WIDE', 'REPORT_EXPORT_ACADEMIC_DATA', 'AUDIT_LOG_READ',
    'OWN_PROFILE_READ', 'OWN_PASSWORD_UPDATE'
);

-- LECTURER permissions
INSERT INTO role_permissions (role_id, permission_id)
SELECT 3, id FROM permissions WHERE name IN (
    'OWN_SCHEDULE_READ', 'SLOT_SESSION_START', 'SLOT_SESSION_RESCAN', 'SLOT_SESSION_FINALIZE',
    'ATTENDANCE_ROSTER_READ', 'ATTENDANCE_STATUS_UPDATE_MANUAL', 'ATTENDANCE_REMARK_MANAGE',
    'REPORT_READ_OWN_SLOT', 'REPORT_EXPORT_OWN_SLOT', 'REPORT_READ_CLASS_SUMMARY',
    'REPORT_READ_SYSTEM_WIDE', 'OWN_PROFILE_READ', 'OWN_PASSWORD_UPDATE', 'ROOM_READ',
    'CAMERA_READ', 'SEMESTER_READ', 'CLASS_READ', 'MAJOR_READ', 'SLOT_READ',
    'SUBJECT_READ', 'SLOT_UPDATE_CATEGORY'
);

-- SUPERVISOR permissions
INSERT INTO role_permissions (role_id, permission_id)
SELECT 4, id FROM permissions WHERE name IN (
    'OWN_SCHEDULE_READ', 'SLOT_SESSION_START', 'SLOT_SESSION_RESCAN', 'SLOT_SESSION_FINALIZE',
    'ATTENDANCE_ROSTER_READ', 'ATTENDANCE_STATUS_UPDATE_MANUAL', 'ATTENDANCE_REMARK_MANAGE',
    'REPORT_READ_OWN_SLOT', 'REPORT_EXPORT_OWN_SLOT', 'REPORT_READ_SYSTEM_WIDE',
    'OWN_PROFILE_READ', 'OWN_PASSWORD_UPDATE', 'ROOM_READ', 'CAMERA_READ',
    'SEMESTER_READ', 'CLASS_READ', 'MAJOR_READ', 'SLOT_READ', 'SUBJECT_READ'
);

-- STUDENT permissions
INSERT INTO role_permissions (role_id, permission_id)
SELECT 5, id FROM permissions WHERE name IN (
    'OWN_SCHEDULE_READ', 'OWN_ATTENDANCE_HISTORY_READ', 'OWN_PROFILE_READ',
    'OWN_PASSWORD_UPDATE', 'ROOM_READ', 'SEMESTER_READ', 'CLASS_READ',
    'MAJOR_READ', 'SLOT_READ', 'SUBJECT_READ'
);

-- -----------------------------------------------------
-- Insert Majors
-- -----------------------------------------------------
INSERT INTO majors (name, code, is_active) VALUES
('Software Engineering', 'SE', TRUE),
('Information Assurance', 'IA', TRUE),
('Artificial Intelligence', 'AI', TRUE),
('Internet of Things', 'IOT', TRUE),
('Digital Art Design', 'DAD', TRUE),
('Business Administration', 'BA', TRUE),
('Multimedia Communications', 'MC', TRUE),
('Mobile and Web Technology', 'MWT', TRUE);

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
('attendance.edit_window_hours', '24', 'Hours after finalization during which lecturer can edit attendance (within same day)', TRUE),
('notification.email_enabled', 'true', 'Whether to send email notifications in addition to in-app notifications', TRUE),
('notification.push_enabled', 'true', 'Whether to send push notifications to mobile devices', TRUE),
('system.maintenance_mode', 'false', 'System maintenance mode flag', TRUE),
('face_recognition.model_version', 'v2.1.0', 'Current face recognition model version in use', TRUE),
('face_recognition.min_face_size', '80', 'Minimum face size in pixels for detection', TRUE),
('attendance.auto_finalize_enabled', 'false', 'Whether to automatically finalize slots after a certain period', TRUE);

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
    v_semester_id INT := 6; -- FA24
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
    v_finalized_at TIMESTAMP;
    
    i INT;
    j INT;
    k INT;
BEGIN
    RAISE NOTICE 'Starting data generation...';
    
    -- =====================================================
    -- 1. GENERATE USERS (100+ total: 80 students, 15 lecturers, 5 DOPs, 5 supervisors)
    -- =====================================================
    RAISE NOTICE 'Generating users...';
    
    -- System Admin (1 user)
    INSERT INTO users (username, email, full_name, password_hash, is_active)
    VALUES ('admin001', 'admin001@fpt.edu.vn', 'Nguyen Van Admin', v_password_hash, TRUE);
    
    -- Data Operators (5 users)
    FOR i IN 1..5 LOOP
        v_full_name := v_first_names[1 + (i % array_length(v_first_names, 1))] || ' ' || 
                       v_middle_names[1 + (i % array_length(v_middle_names, 1))] || ' DOP' || i;
        v_username := 'dop' || LPAD(i::TEXT, 3, '0');
        v_email := v_username || '@fpt.edu.vn';
        
        INSERT INTO users (username, email, full_name, password_hash, is_active)
        VALUES (v_username, v_email, v_full_name, v_password_hash, TRUE)
        RETURNING id INTO v_user_id;
        
        INSERT INTO staff_profiles (user_id, staff_code)
        VALUES (v_user_id, 'DOP' || LPAD(i::TEXT, 3, '0'));
        
        INSERT INTO user_roles (user_id, role_id) VALUES (v_user_id, 2); -- DATA_OPERATOR role
        
        v_dop_count := v_dop_count + 1;
    END LOOP;
    
    -- Lecturers (15 users)
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
        
        INSERT INTO users (username, email, full_name, password_hash, is_active)
        VALUES (v_username, v_email, v_full_name, v_password_hash, TRUE)
        RETURNING id INTO v_user_id;
        
        INSERT INTO staff_profiles (user_id, staff_code)
        VALUES (v_user_id, 'LEC' || LPAD(i::TEXT, 3, '0'));
        
        INSERT INTO user_roles (user_id, role_id) VALUES (v_user_id, 3); -- LECTURER role
        
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
        
        -- Generate 4-6 slots per class
        FOR j IN 1..(4 + (v_class_id % 3)) LOOP
            v_start_time := '2024-09-02 08:00:00'::TIMESTAMP + (((v_class_id - 1) * 7 + (j - 1) * 2) || ' days')::INTERVAL + 
                           ((j % 3) * 2 || ' hours')::INTERVAL;
            v_end_time := v_start_time + '2 hours'::INTERVAL;
            
            -- Determine slot category
            v_slot_category := CASE 
                WHEN j = (4 + (v_class_id % 3)) THEN 'LECTURE_WITH_PT' -- Last slot is progress test
                ELSE 'LECTURE'
            END;
            
            -- Finalize past slots
            v_finalized_at := CASE 
                WHEN v_start_time < CURRENT_TIMESTAMP - INTERVAL '7 days' THEN v_end_time + '30 minutes'::INTERVAL
                ELSE NULL
            END;
            
            INSERT INTO slots (class_id, semester_id, room_id, staff_user_id, slot_category, 
                             start_time, end_time, finalized_at, title, is_active)
            VALUES (
                v_class_id,
                v_semester_id,
                v_room_id,
                v_staff_id,
                v_slot_category,
                v_start_time,
                v_end_time,
                v_finalized_at,
                CASE v_slot_category
                    WHEN 'LECTURE_WITH_PT' THEN 'Progress Test ' || j
                    ELSE 'Lecture Session ' || j
                END,
                TRUE
            );
        END LOOP;
    END LOOP;
    
    -- Generate FINAL_EXAM slots (20 slots)
    FOR i IN 1..20 LOOP
        v_staff_id := (SELECT u.id FROM users u 
                      JOIN user_roles ur ON u.id = ur.user_id 
                      WHERE ur.role_id = 4 -- Supervisor
                      ORDER BY RANDOM() 
                      LIMIT 1);
        
        v_room_id := (SELECT id FROM rooms WHERE name LIKE 'Auditorium%' ORDER BY RANDOM() LIMIT 1);
        
        v_start_time := '2024-12-10 08:00:00'::TIMESTAMP + ((i - 1) * 12 || ' hours')::INTERVAL;
        v_end_time := v_start_time + '2 hours'::INTERVAL;
        
        INSERT INTO slots (class_id, semester_id, room_id, staff_user_id, slot_category, 
                         start_time, end_time, finalized_at, title, is_active)
        VALUES (
            NULL, -- FINAL_EXAM has no class_id
            v_semester_id,
            v_room_id,
            v_staff_id,
            'FINAL_EXAM',
            v_start_time,
            v_end_time,
            NULL, -- Not finalized yet
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
    -- 7. GENERATE ATTENDANCE_RECORDS FOR FINALIZED SLOTS
    -- =====================================================
    RAISE NOTICE 'Generating attendance records...';
    
    FOR v_slot_id IN (SELECT id FROM slots 
                     WHERE slot_category IN ('LECTURE', 'LECTURE_WITH_PT') 
                     AND finalized_at IS NOT NULL) LOOP
        
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
            );
        END LOOP;
    END LOOP;
    
    RAISE NOTICE 'Generated % attendance records', (SELECT COUNT(*) FROM attendance_records);
    
    -- =====================================================
    -- 8. GENERATE EXAM_ATTENDANCE FOR FINALIZED LECTURE_WITH_PT SLOTS
    -- =====================================================
    RAISE NOTICE 'Generating exam attendance records...';
    
    FOR v_slot_id IN (SELECT id FROM slots 
                     WHERE slot_category = 'LECTURE_WITH_PT' 
                     AND finalized_at IS NOT NULL) LOOP
        
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
            );
        END LOOP;
    END LOOP;
    
    RAISE NOTICE 'Generated % exam attendance records', (SELECT COUNT(*) FROM exam_attendance);
    
    -- =====================================================
    -- 9. GENERATE IDENTITY_SUBMISSIONS AND FACE_EMBEDDINGS
    -- =====================================================
    RAISE NOTICE 'Generating identity submissions and embeddings...';
    
    FOR v_user_id IN (SELECT u.id FROM users u 
                     JOIN user_roles ur ON u.id = ur.user_id 
                     WHERE ur.role_id = 5 
                     LIMIT 75) LOOP
        
        DECLARE
            v_submission_id INT;
            v_asset_id INT;
            v_status TEXT;
        BEGIN
            v_status := CASE 
                WHEN RANDOM() < 0.85 THEN 'approved'
                WHEN RANDOM() < 0.95 THEN 'pending'
                ELSE 'rejected'
            END;
            
            INSERT INTO identity_submissions (student_user_id, reviewed_by_user_id, status, submission_type, reviewed_at, rejection_reason)
            VALUES (
                v_user_id,
                CASE WHEN v_status != 'pending' THEN 2 ELSE NULL END,
                v_status,
                'initial',
                CASE WHEN v_status != 'pending' THEN CURRENT_TIMESTAMP - ((1 + RANDOM() * 30)::INT || ' days')::INTERVAL ELSE NULL END,
                CASE WHEN v_status = 'rejected' THEN 'Photo quality too low, please retake' ELSE NULL END
            )
            RETURNING id INTO v_submission_id;
            
            -- Add photo asset
            INSERT INTO identity_assets (submission_id, asset_type, storage_url, is_active)
            VALUES (v_submission_id, 'face_photo', '/identity/student_' || v_user_id || '_photo.jpg', v_status = 'approved');
            
            -- Add video asset and get its ID
            INSERT INTO identity_assets (submission_id, asset_type, storage_url, is_active)
            VALUES (v_submission_id, 'face_video', '/identity/student_' || v_user_id || '_video.mp4', v_status = 'approved')
            RETURNING id INTO v_asset_id;
            
            -- Generate face embedding for approved submissions
            IF v_status = 'approved' THEN
                INSERT INTO face_embeddings (student_user_id, generated_from_asset_id, version, is_active, embedding_vector)
                VALUES (
                    v_user_id,
                    v_asset_id,
                    1,
                    TRUE,
                    array_fill(RANDOM()::REAL, ARRAY[512])::vector
                );
                
                -- Update student profile with base photo URL
                UPDATE student_profiles 
                SET base_photo_url = '/identity/student_' || v_user_id || '_photo.jpg'
                WHERE user_id = v_user_id;
            END IF;
        END;
    END LOOP;
    
    RAISE NOTICE 'Generated % identity submissions and % face embeddings', 
                 (SELECT COUNT(*) FROM identity_submissions),
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
        
        -- Exam attendance remarks
        FOR i IN 1..30 LOOP
            INSERT INTO exam_attendance_remarks (exam_attendance_id, created_by_user_id, remark, is_active)
            SELECT 
                ea.id,
                s.staff_user_id,
                v_remarks[1 + (i % array_length(v_remarks, 1))],
                TRUE
            FROM exam_attendance ea
            JOIN slots s ON ea.slot_id = s.id
            WHERE ea.method = 'manual'
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
    
    -- Slot finalization logs
    FOR v_slot_id IN (SELECT id FROM slots WHERE finalized_at IS NOT NULL LIMIT 50) LOOP
        INSERT INTO operational_audit_logs (actor_user_id, action_type, target_entity, target_id, changes)
        SELECT 
            staff_user_id,
            'FINALIZE',
            'slot',
            id,
            jsonb_build_object(
                'finalized_at', jsonb_build_object(
                    'before', NULL,
                    'after', finalized_at
                )
            )
        FROM slots WHERE id = v_slot_id;
    END LOOP;
    
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
-- SECTION 6: VERIFICATION QUERIES
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
SELECT 'identity_submissions', COUNT(*) FROM identity_submissions
UNION ALL
SELECT 'identity_assets', COUNT(*) FROM identity_assets
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
