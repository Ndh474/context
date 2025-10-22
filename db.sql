-- =====================================================
-- FUACS Database Schema - Complete SQL Script
-- FU Attendance Checking Smart System
-- Version: 1.0
-- Generated: 2025-10-22
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

-- Drop extensions if needed (uncomment to fully reset)
-- DROP EXTENSION IF EXISTS pgvector CASCADE;

-- =====================================================
-- SECTION 2: CREATE EXTENSIONS
-- =====================================================

CREATE EXTENSION IF NOT EXISTS pgvector;

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
-- SECTION 4: INSERT SAMPLE DATA
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
-- Identity Management
('IDENTITY_SUBMISSION_READ_QUEUE', TRUE),
('IDENTITY_SUBMISSION_READ_DETAIL', TRUE),
('IDENTITY_SUBMISSION_APPROVE', TRUE),
('IDENTITY_SUBMISSION_REJECT', TRUE),
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
-- Infrastructure Management
('ROOM_CREATE', TRUE),
('ROOM_READ', TRUE),
('ROOM_UPDATE', TRUE),
('ROOM_DELETE_HARD', TRUE),
('CAMERA_CREATE', TRUE),
('CAMERA_READ', TRUE),
('CAMERA_UPDATE', TRUE),
('CAMERA_DELETE_HARD', TRUE),
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
('OWN_IDENTITY_SUBMIT', TRUE),
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
    'USER_UPDATE_STATUS', 'USER_ASSIGN_ROLES', 'IDENTITY_SUBMISSION_READ_QUEUE',
    'IDENTITY_SUBMISSION_READ_DETAIL', 'IDENTITY_SUBMISSION_APPROVE', 'IDENTITY_SUBMISSION_REJECT',
    'SEMESTER_CREATE', 'SEMESTER_READ', 'SEMESTER_UPDATE', 'MAJOR_CREATE', 'MAJOR_READ',
    'MAJOR_UPDATE', 'SUBJECT_CREATE', 'SUBJECT_READ', 'SUBJECT_UPDATE', 'CLASS_CREATE',
    'CLASS_READ', 'CLASS_UPDATE', 'SLOT_CREATE', 'SLOT_READ', 'SLOT_UPDATE',
    'ENROLLMENT_MANAGE', 'SLOT_CREATE_FINAL_EXAM', 'SLOT_UPDATE_FINAL_EXAM',
    'SLOT_DELETE_HARD_FINAL_EXAM', 'ATTENDANCE_STATUS_UPDATE_MANUAL', 'ROOM_CREATE',
    'ROOM_READ', 'ROOM_UPDATE', 'CAMERA_CREATE', 'CAMERA_READ', 'CAMERA_UPDATE',
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
    'OWN_SCHEDULE_READ', 'OWN_ATTENDANCE_HISTORY_READ', 'OWN_IDENTITY_SUBMIT',
    'OWN_PROFILE_READ', 'OWN_PASSWORD_UPDATE', 'ROOM_READ', 'SEMESTER_READ',
    'CLASS_READ', 'MAJOR_READ', 'SLOT_READ', 'SUBJECT_READ'
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
('Business Administration', 'BA', TRUE);

-- -----------------------------------------------------
-- Insert Semesters
-- -----------------------------------------------------
INSERT INTO semesters (name, code, start_date, end_date, is_active) VALUES
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
('Digital Marketing', 'MKT301', TRUE);

-- -----------------------------------------------------
-- Insert Subject-Major Mappings
-- -----------------------------------------------------
INSERT INTO subject_majors (subject_id, major_id) VALUES
-- Software Engineering subjects
(1, 1), (2, 1), (3, 1), (4, 1), (5, 1), (6, 1), (7, 1), (9, 1), (10, 1),
-- Information Assurance subjects
(1, 2), (2, 2), (3, 2), (4, 2), (9, 2), (10, 2), (11, 2), (12, 2),
-- Artificial Intelligence subjects
(1, 3), (2, 3), (3, 3), (4, 3), (8, 3), (10, 3),
-- Internet of Things subjects
(1, 4), (2, 4), (3, 4), (9, 4), (10, 4), (12, 4),
-- Business Administration subjects
(13, 6), (14, 6), (15, 6);

-- -----------------------------------------------------
-- Insert Users (Password: $2a$12$aSEiCWX1/2jbK5LLgQCwo.Ql4NDzvjYhX6KD0bAtk8eWhSv3X.O3O)
-- -----------------------------------------------------

-- System Admin (1 user)
INSERT INTO users (username, email, full_name, password_hash, is_active) VALUES
('admin001', 'admin001@fpt.edu.vn', 'Nguyen Van Admin', '$2a$12$aSEiCWX1/2jbK5LLgQCwo.Ql4NDzvjYhX6KD0bAtk8eWhSv3X.O3O', TRUE);

-- Data Operators (3 users)
INSERT INTO users (username, email, full_name, password_hash, is_active) VALUES
('dop001', 'dop001@fpt.edu.vn', 'Tran Thi Data Operator', '$2a$12$aSEiCWX1/2jbK5LLgQCwo.Ql4NDzvjYhX6KD0bAtk8eWhSv3X.O3O', TRUE),
('dop002', 'dop002@fpt.edu.vn', 'Le Van Operations', '$2a$12$aSEiCWX1/2jbK5LLgQCwo.Ql4NDzvjYhX6KD0bAtk8eWhSv3X.O3O', TRUE),
('dop003', 'dop003@fpt.edu.vn', 'Pham Thi Manager', '$2a$12$aSEiCWX1/2jbK5LLgQCwo.Ql4NDzvjYhX6KD0bAtk8eWhSv3X.O3O', TRUE);

-- Lecturers (8 users)
INSERT INTO users (username, email, full_name, password_hash, is_active) VALUES
('lec001', 'lec001@fpt.edu.vn', 'Dr. Nguyen Van Lecturer', '$2a$12$aSEiCWX1/2jbK5LLgQCwo.Ql4NDzvjYhX6KD0bAtk8eWhSv3X.O3O', TRUE),
('lec002', 'lec002@fpt.edu.vn', 'Dr. Tran Thi Professor', '$2a$12$aSEiCWX1/2jbK5LLgQCwo.Ql4NDzvjYhX6KD0bAtk8eWhSv3X.O3O', TRUE),
('lec003', 'lec003@fpt.edu.vn', 'MSc. Le Van Teacher', '$2a$12$aSEiCWX1/2jbK5LLgQCwo.Ql4NDzvjYhX6KD0bAtk8eWhSv3X.O3O', TRUE),
('lec004', 'lec004@fpt.edu.vn', 'Dr. Pham Thi Instructor', '$2a$12$aSEiCWX1/2jbK5LLgQCwo.Ql4NDzvjYhX6KD0bAtk8eWhSv3X.O3O', TRUE),
('lec005', 'lec005@fpt.edu.vn', 'MSc. Hoang Van Educator', '$2a$12$aSEiCWX1/2jbK5LLgQCwo.Ql4NDzvjYhX6KD0bAtk8eWhSv3X.O3O', TRUE),
('lec006', 'lec006@fpt.edu.vn', 'Dr. Vo Thi Academic', '$2a$12$aSEiCWX1/2jbK5LLgQCwo.Ql4NDzvjYhX6KD0bAtk8eWhSv3X.O3O', TRUE),
('lec007', 'lec007@fpt.edu.vn', 'MSc. Dang Van Faculty', '$2a$12$aSEiCWX1/2jbK5LLgQCwo.Ql4NDzvjYhX6KD0bAtk8eWhSv3X.O3O', TRUE),
('lec008', 'lec008@fpt.edu.vn', 'Dr. Bui Thi Scholar', '$2a$12$aSEiCWX1/2jbK5LLgQCwo.Ql4NDzvjYhX6KD0bAtk8eWhSv3X.O3O', TRUE);

-- Supervisors (4 users)
INSERT INTO users (username, email, full_name, password_hash, is_active) VALUES
('sup001', 'sup001@fpt.edu.vn', 'Nguyen Van Supervisor', '$2a$12$aSEiCWX1/2jbK5LLgQCwo.Ql4NDzvjYhX6KD0bAtk8eWhSv3X.O3O', TRUE),
('sup002', 'sup002@fpt.edu.vn', 'Tran Thi Proctor', '$2a$12$aSEiCWX1/2jbK5LLgQCwo.Ql4NDzvjYhX6KD0bAtk8eWhSv3X.O3O', TRUE),
('sup003', 'sup003@fpt.edu.vn', 'Le Van Monitor', '$2a$12$aSEiCWX1/2jbK5LLgQCwo.Ql4NDzvjYhX6KD0bAtk8eWhSv3X.O3O', TRUE),
('sup004', 'sup004@fpt.edu.vn', 'Pham Thi Examiner', '$2a$12$aSEiCWX1/2jbK5LLgQCwo.Ql4NDzvjYhX6KD0bAtk8eWhSv3X.O3O', TRUE);

-- Students (40 users - diverse across majors)
INSERT INTO users (username, email, full_name, password_hash, is_active) VALUES
-- SE Students (12)
('HE180001', 'he180001@fpt.edu.vn', 'Nguyen Van An', '$2a$12$aSEiCWX1/2jbK5LLgQCwo.Ql4NDzvjYhX6KD0bAtk8eWhSv3X.O3O', TRUE),
('HE180002', 'he180002@fpt.edu.vn', 'Tran Thi Binh', '$2a$12$aSEiCWX1/2jbK5LLgQCwo.Ql4NDzvjYhX6KD0bAtk8eWhSv3X.O3O', TRUE),
('HE180003', 'he180003@fpt.edu.vn', 'Le Van Cuong', '$2a$12$aSEiCWX1/2jbK5LLgQCwo.Ql4NDzvjYhX6KD0bAtk8eWhSv3X.O3O', TRUE),
('HE180004', 'he180004@fpt.edu.vn', 'Pham Thi Dung', '$2a$12$aSEiCWX1/2jbK5LLgQCwo.Ql4NDzvjYhX6KD0bAtk8eWhSv3X.O3O', TRUE),
('HE180005', 'he180005@fpt.edu.vn', 'Hoang Van Em', '$2a$12$aSEiCWX1/2jbK5LLgQCwo.Ql4NDzvjYhX6KD0bAtk8eWhSv3X.O3O', TRUE),
('HE180006', 'he180006@fpt.edu.vn', 'Vo Thi Phuong', '$2a$12$aSEiCWX1/2jbK5LLgQCwo.Ql4NDzvjYhX6KD0bAtk8eWhSv3X.O3O', TRUE),
('HE180007', 'he180007@fpt.edu.vn', 'Dang Van Giang', '$2a$12$aSEiCWX1/2jbK5LLgQCwo.Ql4NDzvjYhX6KD0bAtk8eWhSv3X.O3O', TRUE),
('HE180008', 'he180008@fpt.edu.vn', 'Bui Thi Hoa', '$2a$12$aSEiCWX1/2jbK5LLgQCwo.Ql4NDzvjYhX6KD0bAtk8eWhSv3X.O3O', TRUE),
('HE180009', 'he180009@fpt.edu.vn', 'Ngo Van Hung', '$2a$12$aSEiCWX1/2jbK5LLgQCwo.Ql4NDzvjYhX6KD0bAtk8eWhSv3X.O3O', TRUE),
('HE180010', 'he180010@fpt.edu.vn', 'Do Thi Khanh', '$2a$12$aSEiCWX1/2jbK5LLgQCwo.Ql4NDzvjYhX6KD0bAtk8eWhSv3X.O3O', TRUE),
('HE180011', 'he180011@fpt.edu.vn', 'Vu Van Linh', '$2a$12$aSEiCWX1/2jbK5LLgQCwo.Ql4NDzvjYhX6KD0bAtk8eWhSv3X.O3O', TRUE),
('HE180012', 'he180012@fpt.edu.vn', 'Truong Thi Mai', '$2a$12$aSEiCWX1/2jbK5LLgQCwo.Ql4NDzvjYhX6KD0bAtk8eWhSv3X.O3O', TRUE),
-- IA Students (10)
('HS180001', 'hs180001@fpt.edu.vn', 'Nguyen Van Nam', '$2a$12$aSEiCWX1/2jbK5LLgQCwo.Ql4NDzvjYhX6KD0bAtk8eWhSv3X.O3O', TRUE),
('HS180002', 'hs180002@fpt.edu.vn', 'Tran Thi Oanh', '$2a$12$aSEiCWX1/2jbK5LLgQCwo.Ql4NDzvjYhX6KD0bAtk8eWhSv3X.O3O', TRUE),
('HS180003', 'hs180003@fpt.edu.vn', 'Le Van Phong', '$2a$12$aSEiCWX1/2jbK5LLgQCwo.Ql4NDzvjYhX6KD0bAtk8eWhSv3X.O3O', TRUE),
('HS180004', 'hs180004@fpt.edu.vn', 'Pham Thi Quynh', '$2a$12$aSEiCWX1/2jbK5LLgQCwo.Ql4NDzvjYhX6KD0bAtk8eWhSv3X.O3O', TRUE),
('HS180005', 'hs180005@fpt.edu.vn', 'Hoang Van Rong', '$2a$12$aSEiCWX1/2jbK5LLgQCwo.Ql4NDzvjYhX6KD0bAtk8eWhSv3X.O3O', TRUE),
('HS180006', 'hs180006@fpt.edu.vn', 'Vo Thi Son', '$2a$12$aSEiCWX1/2jbK5LLgQCwo.Ql4NDzvjYhX6KD0bAtk8eWhSv3X.O3O', TRUE),
('HS180007', 'hs180007@fpt.edu.vn', 'Dang Van Tuan', '$2a$12$aSEiCWX1/2jbK5LLgQCwo.Ql4NDzvjYhX6KD0bAtk8eWhSv3X.O3O', TRUE),
('HS180008', 'hs180008@fpt.edu.vn', 'Bui Thi Uyen', '$2a$12$aSEiCWX1/2jbK5LLgQCwo.Ql4NDzvjYhX6KD0bAtk8eWhSv3X.O3O', TRUE),
('HS180009', 'hs180009@fpt.edu.vn', 'Ngo Van Vinh', '$2a$12$aSEiCWX1/2jbK5LLgQCwo.Ql4NDzvjYhX6KD0bAtk8eWhSv3X.O3O', TRUE),
('HS180010', 'hs180010@fpt.edu.vn', 'Do Thi Xuan', '$2a$12$aSEiCWX1/2jbK5LLgQCwo.Ql4NDzvjYhX6KD0bAtk8eWhSv3X.O3O', TRUE),
-- AI Students (8)
('HA180001', 'ha180001@fpt.edu.vn', 'Nguyen Van Yen', '$2a$12$aSEiCWX1/2jbK5LLgQCwo.Ql4NDzvjYhX6KD0bAtk8eWhSv3X.O3O', TRUE),
('HA180002', 'ha180002@fpt.edu.vn', 'Tran Thi Anh', '$2a$12$aSEiCWX1/2jbK5LLgQCwo.Ql4NDzvjYhX6KD0bAtk8eWhSv3X.O3O', TRUE),
('HA180003', 'ha180003@fpt.edu.vn', 'Le Van Bao', '$2a$12$aSEiCWX1/2jbK5LLgQCwo.Ql4NDzvjYhX6KD0bAtk8eWhSv3X.O3O', TRUE),
('HA180004', 'ha180004@fpt.edu.vn', 'Pham Thi Cam', '$2a$12$aSEiCWX1/2jbK5LLgQCwo.Ql4NDzvjYhX6KD0bAtk8eWhSv3X.O3O', TRUE),
('HA180005', 'ha180005@fpt.edu.vn', 'Hoang Van Dat', '$2a$12$aSEiCWX1/2jbK5LLgQCwo.Ql4NDzvjYhX6KD0bAtk8eWhSv3X.O3O', TRUE),
('HA180006', 'ha180006@fpt.edu.vn', 'Vo Thi Nga', '$2a$12$aSEiCWX1/2jbK5LLgQCwo.Ql4NDzvjYhX6KD0bAtk8eWhSv3X.O3O', TRUE),
('HA180007', 'ha180007@fpt.edu.vn', 'Dang Van Phuc', '$2a$12$aSEiCWX1/2jbK5LLgQCwo.Ql4NDzvjYhX6KD0bAtk8eWhSv3X.O3O', TRUE),
('HA180008', 'ha180008@fpt.edu.vn', 'Bui Thi Thao', '$2a$12$aSEiCWX1/2jbK5LLgQCwo.Ql4NDzvjYhX6KD0bAtk8eWhSv3X.O3O', TRUE),
-- IOT Students (6)
('HI180001', 'hi180001@fpt.edu.vn', 'Nguyen Van Minh', '$2a$12$aSEiCWX1/2jbK5LLgQCwo.Ql4NDzvjYhX6KD0bAtk8eWhSv3X.O3O', TRUE),
('HI180002', 'hi180002@fpt.edu.vn', 'Tran Thi Lan', '$2a$12$aSEiCWX1/2jbK5LLgQCwo.Ql4NDzvjYhX6KD0bAtk8eWhSv3X.O3O', TRUE),
('HI180003', 'hi180003@fpt.edu.vn', 'Le Van Kien', '$2a$12$aSEiCWX1/2jbK5LLgQCwo.Ql4NDzvjYhX6KD0bAtk8eWhSv3X.O3O', TRUE),
('HI180004', 'hi180004@fpt.edu.vn', 'Pham Thi Huong', '$2a$12$aSEiCWX1/2jbK5LLgQCwo.Ql4NDzvjYhX6KD0bAtk8eWhSv3X.O3O', TRUE),
('HI180005', 'hi180005@fpt.edu.vn', 'Hoang Van Tien', '$2a$12$aSEiCWX1/2jbK5LLgQCwo.Ql4NDzvjYhX6KD0bAtk8eWhSv3X.O3O', TRUE),
('HI180006', 'hi180006@fpt.edu.vn', 'Vo Thi Nhi', '$2a$12$aSEiCWX1/2jbK5LLgQCwo.Ql4NDzvjYhX6KD0bAtk8eWhSv3X.O3O', TRUE),
-- BA Students (4)
('HB180001', 'hb180001@fpt.edu.vn', 'Nguyen Van Duc', '$2a$12$aSEiCWX1/2jbK5LLgQCwo.Ql4NDzvjYhX6KD0bAtk8eWhSv3X.O3O', TRUE),
('HB180002', 'hb180002@fpt.edu.vn', 'Tran Thi Hanh', '$2a$12$aSEiCWX1/2jbK5LLgQCwo.Ql4NDzvjYhX6KD0bAtk8eWhSv3X.O3O', TRUE),
('HB180003', 'hb180003@fpt.edu.vn', 'Le Van Tai', '$2a$12$aSEiCWX1/2jbK5LLgQCwo.Ql4NDzvjYhX6KD0bAtk8eWhSv3X.O3O', TRUE),
('HB180004', 'hb180004@fpt.edu.vn', 'Pham Thi Ly', '$2a$12$aSEiCWX1/2jbK5LLgQCwo.Ql4NDzvjYhX6KD0bAtk8eWhSv3X.O3O', TRUE);

-- -----------------------------------------------------
-- Insert User Roles
-- -----------------------------------------------------

-- System Admin
INSERT INTO user_roles (user_id, role_id) VALUES (1, 1);

-- Data Operators
INSERT INTO user_roles (user_id, role_id) VALUES (2, 2), (3, 2), (4, 2);

-- Lecturers
INSERT INTO user_roles (user_id, role_id) VALUES (5, 3), (6, 3), (7, 3), (8, 3), (9, 3), (10, 3), (11, 3), (12, 3);

-- Supervisors
INSERT INTO user_roles (user_id, role_id) VALUES (13, 4), (14, 4), (15, 4), (16, 4);

-- Students (IDs 17-56)
INSERT INTO user_roles (user_id, role_id)
SELECT id, 5 FROM users WHERE id >= 17 AND id <= 56;

-- -----------------------------------------------------
-- Insert Staff Profiles
-- -----------------------------------------------------
INSERT INTO staff_profiles (user_id, staff_code) VALUES
(2, 'DOP001'), (3, 'DOP002'), (4, 'DOP003'),
(5, 'LEC001'), (6, 'LEC002'), (7, 'LEC003'), (8, 'LEC004'),
(9, 'LEC005'), (10, 'LEC006'), (11, 'LEC007'), (12, 'LEC008'),
(13, 'SUP001'), (14, 'SUP002'), (15, 'SUP003'), (16, 'SUP004');

-- -----------------------------------------------------
-- Insert Student Profiles
-- -----------------------------------------------------
-- SE Students
INSERT INTO student_profiles (user_id, major_id, roll_number) VALUES
(17, 1, 'HE180001'), (18, 1, 'HE180002'), (19, 1, 'HE180003'), (20, 1, 'HE180004'),
(21, 1, 'HE180005'), (22, 1, 'HE180006'), (23, 1, 'HE180007'), (24, 1, 'HE180008'),
(25, 1, 'HE180009'), (26, 1, 'HE180010'), (27, 1, 'HE180011'), (28, 1, 'HE180012');

-- IA Students
INSERT INTO student_profiles (user_id, major_id, roll_number) VALUES
(29, 2, 'HS180001'), (30, 2, 'HS180002'), (31, 2, 'HS180003'), (32, 2, 'HS180004'),
(33, 2, 'HS180005'), (34, 2, 'HS180006'), (35, 2, 'HS180007'), (36, 2, 'HS180008'),
(37, 2, 'HS180009'), (38, 2, 'HS180010');

-- AI Students
INSERT INTO student_profiles (user_id, major_id, roll_number) VALUES
(39, 3, 'HA180001'), (40, 3, 'HA180002'), (41, 3, 'HA180003'), (42, 3, 'HA180004'),
(43, 3, 'HA180005'), (44, 3, 'HA180006'), (45, 3, 'HA180007'), (46, 3, 'HA180008');

-- IOT Students
INSERT INTO student_profiles (user_id, major_id, roll_number) VALUES
(47, 4, 'HI180001'), (48, 4, 'HI180002'), (49, 4, 'HI180003'),
(50, 4, 'HI180004'), (51, 4, 'HI180005'), (52, 4, 'HI180006');

-- BA Students
INSERT INTO student_profiles (user_id, major_id, roll_number) VALUES
(53, 6, 'HB180001'), (54, 6, 'HB180002'), (55, 6, 'HB180003'), (56, 6, 'HB180004');

-- -----------------------------------------------------
-- Insert Rooms
-- -----------------------------------------------------
INSERT INTO rooms (name, location, is_active) VALUES
('Room 101', 'Building Alpha - Floor 1', TRUE),
('Room 102', 'Building Alpha - Floor 1', TRUE),
('Room 201', 'Building Alpha - Floor 2', TRUE),
('Room 202', 'Building Alpha - Floor 2', TRUE),
('Room 301', 'Building Beta - Floor 3', TRUE),
('Room 302', 'Building Beta - Floor 3', TRUE),
('Lab 401', 'Building Beta - Floor 4', TRUE),
('Lab 402', 'Building Beta - Floor 4', TRUE),
('Auditorium A', 'Building Gamma - Ground Floor', TRUE),
('Auditorium B', 'Building Gamma - Ground Floor', TRUE);

-- -----------------------------------------------------
-- Insert Cameras
-- -----------------------------------------------------
INSERT INTO cameras (room_id, name, rtsp_url, is_active) VALUES
(1, 'CAM-101-FRONT', 'rtsp://192.168.1.101:554/stream1', TRUE),
(1, 'CAM-101-BACK', 'rtsp://192.168.1.102:554/stream1', TRUE),
(2, 'CAM-102-FRONT', 'rtsp://192.168.1.103:554/stream1', TRUE),
(2, 'CAM-102-BACK', 'rtsp://192.168.1.104:554/stream1', TRUE),
(3, 'CAM-201-FRONT', 'rtsp://192.168.1.105:554/stream1', TRUE),
(3, 'CAM-201-BACK', 'rtsp://192.168.1.106:554/stream1', TRUE),
(4, 'CAM-202-FRONT', 'rtsp://192.168.1.107:554/stream1', TRUE),
(5, 'CAM-301-FRONT', 'rtsp://192.168.1.108:554/stream1', TRUE),
(5, 'CAM-301-BACK', 'rtsp://192.168.1.109:554/stream1', TRUE),
(6, 'CAM-302-FRONT', 'rtsp://192.168.1.110:554/stream1', TRUE),
(7, 'CAM-LAB401-1', 'rtsp://192.168.1.111:554/stream1', TRUE),
(7, 'CAM-LAB401-2', 'rtsp://192.168.1.112:554/stream1', TRUE),
(7, 'CAM-LAB401-3', 'rtsp://192.168.1.113:554/stream1', TRUE),
(8, 'CAM-LAB402-1', 'rtsp://192.168.1.114:554/stream1', TRUE),
(8, 'CAM-LAB402-2', 'rtsp://192.168.1.115:554/stream1', TRUE),
(9, 'CAM-AUDA-FRONT', 'rtsp://192.168.1.116:554/stream1', TRUE),
(9, 'CAM-AUDA-BACK', 'rtsp://192.168.1.117:554/stream1', TRUE),
(9, 'CAM-AUDA-LEFT', 'rtsp://192.168.1.118:554/stream1', TRUE),
(10, 'CAM-AUDB-FRONT', 'rtsp://192.168.1.119:554/stream1', TRUE),
(10, 'CAM-AUDB-BACK', 'rtsp://192.168.1.120:554/stream1', TRUE);

-- -----------------------------------------------------
-- Insert Classes (Fall 2024 - Current Semester)
-- -----------------------------------------------------
INSERT INTO classes (subject_id, semester_id, code, is_active) VALUES
-- PRF192 classes
(1, 3, 'SE1801', TRUE),
(1, 3, 'SE1802', TRUE),
(1, 3, 'AI1801', TRUE),
-- PRO192 classes
(2, 3, 'SE1803', TRUE),
(2, 3, 'SE1804', TRUE),
-- CSD201 classes
(3, 3, 'SE1805', TRUE),
(3, 3, 'AI1802', TRUE),
-- DBI202 classes
(4, 3, 'SE1806', TRUE),
(4, 3, 'IA1801', TRUE),
-- SWP391 classes
(5, 3, 'SE1807', TRUE),
-- MLA301 classes
(8, 3, 'AI1803', TRUE),
-- NWC203 classes
(9, 3, 'SE1808', TRUE),
(9, 3, 'IOT1801', TRUE),
-- SEC301 classes
(11, 3, 'IA1802', TRUE),
-- BIN301 classes
(13, 3, 'BA1801', TRUE);

-- -----------------------------------------------------
-- Insert Enrollments
-- -----------------------------------------------------

-- PRF192 SE1801 (Class ID 1) - 8 students
INSERT INTO enrollments (class_id, student_user_id, is_enrolled) VALUES
(1, 17, TRUE), (1, 18, TRUE), (1, 19, TRUE), (1, 20, TRUE),
(1, 21, TRUE), (1, 22, TRUE), (1, 23, TRUE), (1, 24, TRUE);

-- PRF192 SE1802 (Class ID 2) - 4 students
INSERT INTO enrollments (class_id, student_user_id, is_enrolled) VALUES
(2, 25, TRUE), (2, 26, TRUE), (2, 27, TRUE), (2, 28, TRUE);

-- PRF192 AI1801 (Class ID 3) - 6 students
INSERT INTO enrollments (class_id, student_user_id, is_enrolled) VALUES
(3, 39, TRUE), (3, 40, TRUE), (3, 41, TRUE), (3, 42, TRUE), (3, 43, TRUE), (3, 44, TRUE);

-- PRO192 SE1803 (Class ID 4) - 6 students
INSERT INTO enrollments (class_id, student_user_id, is_enrolled) VALUES
(4, 17, TRUE), (4, 18, TRUE), (4, 19, TRUE), (4, 20, TRUE), (4, 21, TRUE), (4, 22, TRUE);

-- PRO192 SE1804 (Class ID 5) - 4 students
INSERT INTO enrollments (class_id, student_user_id, is_enrolled) VALUES
(5, 23, TRUE), (5, 24, TRUE), (5, 25, TRUE), (5, 26, TRUE);

-- CSD201 SE1805 (Class ID 6) - 5 students
INSERT INTO enrollments (class_id, student_user_id, is_enrolled) VALUES
(6, 17, TRUE), (6, 18, TRUE), (6, 19, TRUE), (6, 20, TRUE), (6, 21, TRUE);

-- CSD201 AI1802 (Class ID 7) - 4 students
INSERT INTO enrollments (class_id, student_user_id, is_enrolled) VALUES
(7, 39, TRUE), (7, 40, TRUE), (7, 41, TRUE), (7, 42, TRUE);

-- DBI202 SE1806 (Class ID 8) - 6 students
INSERT INTO enrollments (class_id, student_user_id, is_enrolled) VALUES
(8, 17, TRUE), (8, 18, TRUE), (8, 19, TRUE), (8, 20, TRUE), (8, 21, TRUE), (8, 22, TRUE);

-- DBI202 IA1801 (Class ID 9) - 5 students
INSERT INTO enrollments (class_id, student_user_id, is_enrolled) VALUES
(9, 29, TRUE), (9, 30, TRUE), (9, 31, TRUE), (9, 32, TRUE), (9, 33, TRUE);

-- SWP391 SE1807 (Class ID 10) - 4 students
INSERT INTO enrollments (class_id, student_user_id, is_enrolled) VALUES
(10, 17, TRUE), (10, 18, TRUE), (10, 19, TRUE), (10, 20, TRUE);

-- MLA301 AI1803 (Class ID 11) - 5 students
INSERT INTO enrollments (class_id, student_user_id, is_enrolled) VALUES
(11, 39, TRUE), (11, 40, TRUE), (11, 41, TRUE), (11, 42, TRUE), (11, 43, TRUE);

-- NWC203 SE1808 (Class ID 12) - 4 students
INSERT INTO enrollments (class_id, student_user_id, is_enrolled) VALUES
(12, 23, TRUE), (12, 24, TRUE), (12, 25, TRUE), (12, 26, TRUE);

-- NWC203 IOT1801 (Class ID 13) - 4 students
INSERT INTO enrollments (class_id, student_user_id, is_enrolled) VALUES
(13, 47, TRUE), (13, 48, TRUE), (13, 49, TRUE), (13, 50, TRUE);

-- SEC301 IA1802 (Class ID 14) - 5 students
INSERT INTO enrollments (class_id, student_user_id, is_enrolled) VALUES
(14, 29, TRUE), (14, 30, TRUE), (14, 31, TRUE), (14, 32, TRUE), (14, 33, TRUE);

-- BIN301 BA1801 (Class ID 15) - 4 students
INSERT INTO enrollments (class_id, student_user_id, is_enrolled) VALUES
(15, 53, TRUE), (15, 54, TRUE), (15, 55, TRUE), (15, 56, TRUE);

-- -----------------------------------------------------
-- Insert Slots (Diverse scenarios)
-- -----------------------------------------------------

-- Regular LECTURE slots (finalized)
INSERT INTO slots (class_id, semester_id, room_id, staff_user_id, slot_category, start_time, end_time, finalized_at, title, is_active) VALUES
(1, 3, 1, 5, 'LECTURE', '2024-10-01 08:00:00', '2024-10-01 10:00:00', '2024-10-01 10:30:00', 'Introduction to Programming', TRUE),
(1, 3, 1, 5, 'LECTURE', '2024-10-03 08:00:00', '2024-10-03 10:00:00', '2024-10-03 10:30:00', 'Variables and Data Types', TRUE),
(1, 3, 1, 5, 'LECTURE', '2024-10-08 08:00:00', '2024-10-08 10:00:00', '2024-10-08 10:30:00', 'Control Structures', TRUE),
(4, 3, 2, 6, 'LECTURE', '2024-10-02 13:00:00', '2024-10-02 15:00:00', '2024-10-02 15:30:00', 'OOP Concepts', TRUE),
(4, 3, 2, 6, 'LECTURE', '2024-10-04 13:00:00', '2024-10-04 15:00:00', '2024-10-04 15:30:00', 'Classes and Objects', TRUE),
(8, 3, 3, 7, 'LECTURE', '2024-10-05 08:00:00', '2024-10-05 10:00:00', '2024-10-05 10:30:00', 'Database Fundamentals', TRUE),
(8, 3, 3, 7, 'LECTURE', '2024-10-07 08:00:00', '2024-10-07 10:00:00', '2024-10-07 10:30:00', 'SQL Basics', TRUE);

-- LECTURE_WITH_PT slots (finalized)
INSERT INTO slots (class_id, semester_id, room_id, staff_user_id, slot_category, start_time, end_time, finalized_at, title, is_active) VALUES
(1, 3, 1, 5, 'LECTURE_WITH_PT', '2024-10-10 08:00:00', '2024-10-10 10:00:00', '2024-10-10 10:30:00', 'Progress Test 1', TRUE),
(4, 3, 2, 6, 'LECTURE_WITH_PT', '2024-10-09 13:00:00', '2024-10-09 15:00:00', '2024-10-09 15:30:00', 'Midterm Progress Test', TRUE),
(8, 3, 3, 7, 'LECTURE_WITH_PT', '2024-10-12 08:00:00', '2024-10-12 10:00:00', '2024-10-12 10:30:00', 'SQL Quiz', TRUE);

-- Upcoming LECTURE slots (not finalized yet)
INSERT INTO slots (class_id, semester_id, room_id, staff_user_id, slot_category, start_time, end_time, finalized_at, title, is_active) VALUES
(1, 3, 1, 5, 'LECTURE', '2024-10-24 08:00:00', '2024-10-24 10:00:00', NULL, 'Functions and Methods', TRUE),
(1, 3, 1, 5, 'LECTURE', '2024-10-29 08:00:00', '2024-10-29 10:00:00', NULL, 'Arrays and Collections', TRUE),
(4, 3, 2, 6, 'LECTURE', '2024-10-25 13:00:00', '2024-10-25 15:00:00', NULL, 'Inheritance', TRUE),
(4, 3, 2, 6, 'LECTURE', '2024-10-30 13:00:00', '2024-10-30 15:00:00', NULL, 'Polymorphism', TRUE),
(8, 3, 3, 7, 'LECTURE', '2024-10-26 08:00:00', '2024-10-26 10:00:00', NULL, 'Advanced SQL', TRUE),
(11, 3, 5, 8, 'LECTURE', '2024-10-27 10:00:00', '2024-10-27 12:00:00', NULL, 'Neural Networks', TRUE),
(11, 3, 5, 8, 'LECTURE', '2024-11-01 10:00:00', '2024-11-01 12:00:00', NULL, 'Deep Learning', TRUE);

-- FINAL_EXAM slots (class_id is NULL, semester_id required)
INSERT INTO slots (class_id, semester_id, room_id, staff_user_id, slot_category, start_time, end_time, finalized_at, title, is_active) VALUES
(NULL, 3, 9, 13, 'FINAL_EXAM', '2024-12-10 08:00:00', '2024-12-10 10:00:00', NULL, 'Final Exam Slot 1', TRUE),
(NULL, 3, 9, 13, 'FINAL_EXAM', '2024-12-10 13:00:00', '2024-12-10 15:00:00', NULL, 'Final Exam Slot 2', TRUE),
(NULL, 3, 10, 14, 'FINAL_EXAM', '2024-12-11 08:00:00', '2024-12-11 10:00:00', NULL, 'Final Exam Slot 3', TRUE),
(NULL, 3, 10, 14, 'FINAL_EXAM', '2024-12-12 08:00:00', '2024-12-12 10:00:00', NULL, 'Final Exam Slot 4', TRUE);

-- -----------------------------------------------------
-- Insert Exam Slot Subjects (for FINAL_EXAM slots)
-- -----------------------------------------------------

-- Final Exam Slot 1 (Slot ID 18) - PRF192 and PRO192
INSERT INTO exam_slot_subjects (slot_id, subject_id) VALUES
(18, 1), -- PRF192
(18, 2); -- PRO192

-- Final Exam Slot 2 (Slot ID 19) - DBI202 and CSD201
INSERT INTO exam_slot_subjects (slot_id, subject_id) VALUES
(19, 4), -- DBI202
(19, 3); -- CSD201

-- Final Exam Slot 3 (Slot ID 20) - MLA301 and NWC203
INSERT INTO exam_slot_subjects (slot_id, subject_id) VALUES
(20, 8), -- MLA301
(20, 9); -- NWC203

-- Final Exam Slot 4 (Slot ID 21) - SEC301 and BIN301
INSERT INTO exam_slot_subjects (slot_id, subject_id) VALUES
(21, 11), -- SEC301
(21, 13); -- BIN301

-- -----------------------------------------------------
-- Insert Exam Slot Participants
-- -----------------------------------------------------

-- Slot 18 - PRF192 participants (exam_slot_subject_id 1)
INSERT INTO exam_slot_participants (exam_slot_subject_id, student_user_id, is_enrolled) VALUES
(1, 17, TRUE), (1, 18, TRUE), (1, 19, TRUE), (1, 20, TRUE),
(1, 21, TRUE), (1, 22, TRUE), (1, 39, TRUE), (1, 40, TRUE);

-- Slot 18 - PRO192 participants (exam_slot_subject_id 2)
INSERT INTO exam_slot_participants (exam_slot_subject_id, student_user_id, is_enrolled) VALUES
(2, 17, TRUE), (2, 18, TRUE), (2, 19, TRUE), (2, 20, TRUE), (2, 23, TRUE), (2, 24, TRUE);

-- Slot 19 - DBI202 participants (exam_slot_subject_id 3)
INSERT INTO exam_slot_participants (exam_slot_subject_id, student_user_id, is_enrolled) VALUES
(3, 17, TRUE), (3, 18, TRUE), (3, 19, TRUE), (3, 29, TRUE), (3, 30, TRUE), (3, 31, TRUE);

-- Slot 19 - CSD201 participants (exam_slot_subject_id 4)
INSERT INTO exam_slot_participants (exam_slot_subject_id, student_user_id, is_enrolled) VALUES
(4, 17, TRUE), (4, 18, TRUE), (4, 19, TRUE), (4, 39, TRUE), (4, 40, TRUE);

-- Slot 20 - MLA301 participants (exam_slot_subject_id 5)
INSERT INTO exam_slot_participants (exam_slot_subject_id, student_user_id, is_enrolled) VALUES
(5, 39, TRUE), (5, 40, TRUE), (5, 41, TRUE), (5, 42, TRUE);

-- Slot 20 - NWC203 participants (exam_slot_subject_id 6)
INSERT INTO exam_slot_participants (exam_slot_subject_id, student_user_id, is_enrolled) VALUES
(6, 23, TRUE), (6, 24, TRUE), (6, 47, TRUE), (6, 48, TRUE);

-- Slot 21 - SEC301 participants (exam_slot_subject_id 7)
INSERT INTO exam_slot_participants (exam_slot_subject_id, student_user_id, is_enrolled) VALUES
(7, 29, TRUE), (7, 30, TRUE), (7, 31, TRUE), (7, 32, TRUE);

-- Slot 21 - BIN301 participants (exam_slot_subject_id 8)
INSERT INTO exam_slot_participants (exam_slot_subject_id, student_user_id, is_enrolled) VALUES
(8, 53, TRUE), (8, 54, TRUE), (8, 55, TRUE), (8, 56, TRUE);

-- -----------------------------------------------------
-- Insert Attendance Records (for finalized LECTURE slots)
-- -----------------------------------------------------

-- Slot 1 attendance (8 students)
INSERT INTO attendance_records (student_user_id, slot_id, status, method, recorded_at) VALUES
(17, 1, 'present', 'auto', '2024-10-01 08:15:00'),
(18, 1, 'present', 'auto', '2024-10-01 08:16:00'),
(19, 1, 'present', 'auto', '2024-10-01 08:17:00'),
(20, 1, 'absent', 'system_finalize', '2024-10-01 10:30:00'),
(21, 1, 'present', 'auto', '2024-10-01 08:20:00'),
(22, 1, 'present', 'manual', '2024-10-01 09:00:00'),
(23, 1, 'present', 'auto', '2024-10-01 08:25:00'),
(24, 1, 'absent', 'system_finalize', '2024-10-01 10:30:00');

-- Slot 2 attendance
INSERT INTO attendance_records (student_user_id, slot_id, status, method, recorded_at) VALUES
(17, 2, 'present', 'auto', '2024-10-03 08:10:00'),
(18, 2, 'present', 'auto', '2024-10-03 08:12:00'),
(19, 2, 'absent', 'manual', '2024-10-03 09:30:00'),
(20, 2, 'present', 'manual', '2024-10-03 09:00:00'),
(21, 2, 'present', 'auto', '2024-10-03 08:15:00'),
(22, 2, 'present', 'auto', '2024-10-03 08:18:00'),
(23, 2, 'present', 'auto', '2024-10-03 08:20:00'),
(24, 2, 'present', 'auto', '2024-10-03 08:22:00');

-- Slot 3 attendance
INSERT INTO attendance_records (student_user_id, slot_id, status, method, recorded_at) VALUES
(17, 3, 'present', 'auto', '2024-10-08 08:05:00'),
(18, 3, 'present', 'auto', '2024-10-08 08:08:00'),
(19, 3, 'present', 'auto', '2024-10-08 08:10:00'),
(20, 3, 'present', 'auto', '2024-10-08 08:12:00'),
(21, 3, 'absent', 'system_finalize', '2024-10-08 10:30:00'),
(22, 3, 'present', 'auto', '2024-10-08 08:15:00'),
(23, 3, 'present', 'auto', '2024-10-08 08:18:00'),
(24, 3, 'present', 'auto', '2024-10-08 08:20:00');

-- Slot 4 attendance (PRO192 class)
INSERT INTO attendance_records (student_user_id, slot_id, status, method, recorded_at) VALUES
(17, 4, 'present', 'auto', '2024-10-02 13:05:00'),
(18, 4, 'present', 'auto', '2024-10-02 13:08:00'),
(19, 4, 'present', 'auto', '2024-10-02 13:10:00'),
(20, 4, 'absent', 'system_finalize', '2024-10-02 15:30:00'),
(21, 4, 'present', 'auto', '2024-10-02 13:15:00'),
(22, 4, 'present', 'auto', '2024-10-02 13:18:00');

-- Slot 5 attendance
INSERT INTO attendance_records (student_user_id, slot_id, status, method, recorded_at) VALUES
(17, 5, 'present', 'auto', '2024-10-04 13:05:00'),
(18, 5, 'present', 'auto', '2024-10-04 13:08:00'),
(19, 5, 'present', 'auto', '2024-10-04 13:10:00'),
(20, 5, 'present', 'manual', '2024-10-04 14:00:00'),
(21, 5, 'present', 'auto', '2024-10-04 13:15:00'),
(22, 5, 'present', 'auto', '2024-10-04 13:18:00');

-- Slot 6 attendance (DBI202 class)
INSERT INTO attendance_records (student_user_id, slot_id, status, method, recorded_at) VALUES
(17, 6, 'present', 'auto', '2024-10-05 08:05:00'),
(18, 6, 'present', 'auto', '2024-10-05 08:08:00'),
(19, 6, 'absent', 'manual', '2024-10-05 09:30:00'),
(20, 6, 'present', 'auto', '2024-10-05 08:12:00'),
(21, 6, 'present', 'auto', '2024-10-05 08:15:00'),
(22, 6, 'present', 'auto', '2024-10-05 08:18:00');

-- Slot 7 attendance
INSERT INTO attendance_records (student_user_id, slot_id, status, method, recorded_at) VALUES
(17, 7, 'present', 'auto', '2024-10-07 08:05:00'),
(18, 7, 'present', 'auto', '2024-10-07 08:08:00'),
(19, 7, 'present', 'auto', '2024-10-07 08:10:00'),
(20, 7, 'present', 'auto', '2024-10-07 08:12:00'),
(21, 7, 'present', 'auto', '2024-10-07 08:15:00'),
(22, 7, 'absent', 'system_finalize', '2024-10-07 10:30:00');

-- -----------------------------------------------------
-- Insert Exam Attendance (for LECTURE_WITH_PT slots)
-- -----------------------------------------------------

-- Slot 8 exam attendance (LECTURE_WITH_PT - Progress Test 1)
INSERT INTO exam_attendance (student_user_id, slot_id, status, method, recorded_at) VALUES
(17, 8, 'present', 'auto', '2024-10-10 08:10:00'),
(18, 8, 'present', 'auto', '2024-10-10 08:12:00'),
(19, 8, 'present', 'auto', '2024-10-10 08:15:00'),
(20, 8, 'absent', 'system_finalize', '2024-10-10 10:30:00'),
(21, 8, 'present', 'auto', '2024-10-10 08:18:00'),
(22, 8, 'present', 'manual', '2024-10-10 09:00:00'),
(23, 8, 'present', 'auto', '2024-10-10 08:22:00'),
(24, 8, 'present', 'auto', '2024-10-10 08:25:00');

-- Slot 9 exam attendance (LECTURE_WITH_PT - Midterm Progress Test)
INSERT INTO exam_attendance (student_user_id, slot_id, status, method, recorded_at) VALUES
(17, 9, 'present', 'auto', '2024-10-09 13:05:00'),
(18, 9, 'present', 'auto', '2024-10-09 13:08:00'),
(19, 9, 'present', 'auto', '2024-10-09 13:10:00'),
(20, 9, 'present', 'manual', '2024-10-09 14:00:00'),
(21, 9, 'present', 'auto', '2024-10-09 13:15:00'),
(22, 9, 'present', 'auto', '2024-10-09 13:18:00');

-- Slot 10 exam attendance (LECTURE_WITH_PT - SQL Quiz)
INSERT INTO exam_attendance (student_user_id, slot_id, status, method, recorded_at) VALUES
(17, 10, 'present', 'auto', '2024-10-12 08:05:00'),
(18, 10, 'present', 'auto', '2024-10-12 08:08:00'),
(19, 10, 'absent', 'manual', '2024-10-12 09:30:00'),
(20, 10, 'present', 'auto', '2024-10-12 08:12:00'),
(21, 10, 'present', 'auto', '2024-10-12 08:15:00'),
(22, 10, 'present', 'auto', '2024-10-12 08:18:00');

-- Note: For LECTURE_WITH_PT slots, both attendance_records and exam_attendance exist
-- Insert corresponding regular attendance for these slots

INSERT INTO attendance_records (student_user_id, slot_id, status, method, recorded_at) VALUES
-- Slot 8 regular attendance
(17, 8, 'present', 'auto', '2024-10-10 08:10:00'),
(18, 8, 'present', 'auto', '2024-10-10 08:12:00'),
(19, 8, 'present', 'auto', '2024-10-10 08:15:00'),
(20, 8, 'absent', 'system_finalize', '2024-10-10 10:30:00'),
(21, 8, 'present', 'auto', '2024-10-10 08:18:00'),
(22, 8, 'present', 'manual', '2024-10-10 09:00:00'),
(23, 8, 'present', 'auto', '2024-10-10 08:22:00'),
(24, 8, 'present', 'auto', '2024-10-10 08:25:00'),
-- Slot 9 regular attendance
(17, 9, 'present', 'auto', '2024-10-09 13:05:00'),
(18, 9, 'present', 'auto', '2024-10-09 13:08:00'),
(19, 9, 'present', 'auto', '2024-10-09 13:10:00'),
(20, 9, 'present', 'manual', '2024-10-09 14:00:00'),
(21, 9, 'present', 'auto', '2024-10-09 13:15:00'),
(22, 9, 'present', 'auto', '2024-10-09 13:18:00'),
-- Slot 10 regular attendance
(17, 10, 'present', 'auto', '2024-10-12 08:05:00'),
(18, 10, 'present', 'auto', '2024-10-12 08:08:00'),
(19, 10, 'absent', 'manual', '2024-10-12 09:30:00'),
(20, 10, 'present', 'auto', '2024-10-12 08:12:00'),
(21, 10, 'present', 'auto', '2024-10-12 08:15:00'),
(22, 10, 'present', 'auto', '2024-10-12 08:18:00');

-- -----------------------------------------------------
-- Insert Attendance Remarks (diverse scenarios)
-- -----------------------------------------------------

-- Remark for manual status change
INSERT INTO regular_attendance_remarks (attendance_record_id, created_by_user_id, remark, is_active) VALUES
(4, 5, 'Student was sick, provided medical certificate later', TRUE),
(9, 6, 'Late arrival due to traffic, marked absent initially', TRUE),
(19, 7, 'Student left early for family emergency', TRUE),
(20, 6, 'Corrected attendance after reviewing evidence', TRUE);

-- Exam attendance remarks
INSERT INTO exam_attendance_remarks (exam_attendance_id, created_by_user_id, remark, is_active) VALUES
(4, 5, 'Student was absent due to illness, will take makeup exam', TRUE),
(9, 7, 'Technical issue with camera, manually verified attendance', TRUE);

-- -----------------------------------------------------
-- Insert Attendance Evidence (sample URLs)
-- -----------------------------------------------------

-- Regular attendance evidences
INSERT INTO regular_attendance_evidences (attendance_record_id, image_url, created_at) VALUES
(1, '/evidence/regular/slot1_student17_20241001_081500.jpg', '2024-10-01 08:15:00'),
(2, '/evidence/regular/slot1_student18_20241001_081600.jpg', '2024-10-01 08:16:00'),
(3, '/evidence/regular/slot1_student19_20241001_081700.jpg', '2024-10-01 08:17:00'),
(5, '/evidence/regular/slot1_student21_20241001_082000.jpg', '2024-10-01 08:20:00'),
(7, '/evidence/regular/slot1_student23_20241001_082500.jpg', '2024-10-01 08:25:00'),
(9, '/evidence/regular/slot2_student17_20241003_081000.jpg', '2024-10-03 08:10:00'),
(10, '/evidence/regular/slot2_student18_20241003_081200.jpg', '2024-10-03 08:12:00');

-- Exam attendance evidences
INSERT INTO exam_attendance_evidences (exam_attendance_id, image_url, created_at) VALUES
(1, '/evidence/exam/slot8_student17_20241010_081000.jpg', '2024-10-10 08:10:00'),
(2, '/evidence/exam/slot8_student18_20241010_081200.jpg', '2024-10-10 08:12:00'),
(3, '/evidence/exam/slot8_student19_20241010_081500.jpg', '2024-10-10 08:15:00'),
(5, '/evidence/exam/slot8_student21_20241010_081800.jpg', '2024-10-10 08:18:00'),
(7, '/evidence/exam/slot8_student23_20241010_082200.jpg', '2024-10-10 08:22:00');

-- -----------------------------------------------------
-- Insert Identity Submissions (diverse scenarios)
-- -----------------------------------------------------

-- Approved initial submissions
INSERT INTO identity_submissions (student_user_id, reviewed_by_user_id, status, submission_type, reviewed_at, rejection_reason) VALUES
(17, 2, 'approved', 'initial', '2024-09-15 10:00:00', NULL),
(18, 2, 'approved', 'initial', '2024-09-15 11:00:00', NULL),
(19, 2, 'approved', 'initial', '2024-09-15 14:00:00', NULL),
(20, 3, 'approved', 'initial', '2024-09-16 09:00:00', NULL),
(21, 3, 'approved', 'initial', '2024-09-16 10:00:00', NULL),
(22, 3, 'approved', 'initial', '2024-09-16 11:00:00', NULL),
(23, 2, 'approved', 'initial', '2024-09-17 09:00:00', NULL),
(24, 2, 'approved', 'initial', '2024-09-17 10:00:00', NULL),
(29, 3, 'approved', 'initial', '2024-09-18 09:00:00', NULL),
(30, 3, 'approved', 'initial', '2024-09-18 10:00:00', NULL);

-- Pending submissions
INSERT INTO identity_submissions (student_user_id, reviewed_by_user_id, status, submission_type, reviewed_at, rejection_reason) VALUES
(39, NULL, 'pending', 'initial', NULL, NULL),
(40, NULL, 'pending', 'initial', NULL, NULL),
(41, NULL, 'pending', 'update', NULL, NULL);

-- Rejected submission
INSERT INTO identity_submissions (student_user_id, reviewed_by_user_id, status, submission_type, reviewed_at, rejection_reason) VALUES
(42, 2, 'rejected', 'initial', '2024-09-20 14:00:00', 'Photo quality is too low, please retake with better lighting'),
(43, 3, 'rejected', 'update', '2024-10-15 10:00:00', 'Video does not show face clearly, please record again');

-- -----------------------------------------------------
-- Insert Identity Assets
-- -----------------------------------------------------

-- Assets for approved submissions
INSERT INTO identity_assets (submission_id, asset_type, storage_url, is_active) VALUES
(1, 'face_photo', '/identity/student17_photo_20240915.jpg', TRUE),
(1, 'face_video', '/identity/student17_video_20240915.mp4', TRUE),
(2, 'face_photo', '/identity/student18_photo_20240915.jpg', TRUE),
(2, 'face_video', '/identity/student18_video_20240915.mp4', TRUE),
(3, 'face_photo', '/identity/student19_photo_20240915.jpg', TRUE),
(3, 'face_video', '/identity/student19_video_20240915.mp4', TRUE),
(4, 'face_photo', '/identity/student20_photo_20240916.jpg', TRUE),
(4, 'face_video', '/identity/student20_video_20240916.mp4', TRUE),
(5, 'face_photo', '/identity/student21_photo_20240916.jpg', TRUE),
(5, 'face_video', '/identity/student21_video_20240916.mp4', TRUE),
(6, 'face_photo', '/identity/student22_photo_20240916.jpg', TRUE),
(6, 'face_video', '/identity/student22_video_20240916.mp4', TRUE),
(7, 'face_photo', '/identity/student23_photo_20240917.jpg', TRUE),
(7, 'face_video', '/identity/student23_video_20240917.mp4', TRUE),
(8, 'face_photo', '/identity/student24_photo_20240917.jpg', TRUE),
(8, 'face_video', '/identity/student24_video_20240917.mp4', TRUE),
(9, 'face_photo', '/identity/student29_photo_20240918.jpg', TRUE),
(9, 'face_video', '/identity/student29_video_20240918.mp4', TRUE),
(10, 'face_photo', '/identity/student30_photo_20240918.jpg', TRUE),
(10, 'face_video', '/identity/student30_video_20240918.mp4', TRUE);

-- Assets for pending submissions
INSERT INTO identity_assets (submission_id, asset_type, storage_url, is_active) VALUES
(11, 'face_photo', '/identity/student39_photo_20241020.jpg', TRUE),
(11, 'face_video', '/identity/student39_video_20241020.mp4', TRUE),
(12, 'face_photo', '/identity/student40_photo_20241020.jpg', TRUE),
(12, 'face_video', '/identity/student40_video_20241020.mp4', TRUE),
(13, 'face_video', '/identity/student41_video_update_20241021.mp4', TRUE);

-- Assets for rejected submissions
INSERT INTO identity_assets (submission_id, asset_type, storage_url, is_active) VALUES
(14, 'face_photo', '/identity/student42_photo_rejected_20240920.jpg', FALSE),
(14, 'face_video', '/identity/student42_video_rejected_20240920.mp4', FALSE),
(15, 'face_video', '/identity/student43_video_rejected_20241015.mp4', FALSE);

-- -----------------------------------------------------
-- Insert Face Embeddings (sample vectors - in production these would be real 512-dim vectors)
-- -----------------------------------------------------

-- Note: Using random vectors for demonstration. In production, these would be generated by the ML model.
INSERT INTO face_embeddings (student_user_id, generated_from_asset_id, version, is_active, embedding_vector) VALUES
(17, 2, 1, TRUE, array_fill(0.1, ARRAY[512])::vector),
(18, 4, 1, TRUE, array_fill(0.2, ARRAY[512])::vector),
(19, 6, 1, TRUE, array_fill(0.3, ARRAY[512])::vector),
(20, 8, 1, TRUE, array_fill(0.4, ARRAY[512])::vector),
(21, 10, 1, TRUE, array_fill(0.5, ARRAY[512])::vector),
(22, 12, 1, TRUE, array_fill(0.6, ARRAY[512])::vector),
(23, 14, 1, TRUE, array_fill(0.7, ARRAY[512])::vector),
(24, 16, 1, TRUE, array_fill(0.8, ARRAY[512])::vector),
(29, 18, 1, TRUE, array_fill(0.9, ARRAY[512])::vector),
(30, 20, 1, TRUE, array_fill(0.15, ARRAY[512])::vector);

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

-- -----------------------------------------------------
-- Insert Notification Deliveries
-- -----------------------------------------------------

-- Identity rejection notifications
INSERT INTO notification_deliveries (notification_id, recipient_user_id, read_at, is_active) VALUES
(1, 42, '2024-09-20 15:00:00', TRUE),
(1, 43, NULL, TRUE); -- Unread

-- Identity approval notifications
INSERT INTO notification_deliveries (notification_id, recipient_user_id, read_at, is_active) VALUES
(2, 17, '2024-09-15 11:00:00', TRUE),
(2, 18, '2024-09-15 12:00:00', TRUE),
(2, 19, '2024-09-15 15:00:00', TRUE),
(2, 20, '2024-09-16 10:00:00', TRUE),
(2, 21, '2024-09-16 11:00:00', TRUE);

-- Absence warning notifications
INSERT INTO notification_deliveries (notification_id, recipient_user_id, read_at, is_active) VALUES
(3, 20, '2024-10-10 12:00:00', TRUE),
(4, 19, NULL, TRUE); -- Unread warning

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
-- Insert Operational Audit Logs
-- -----------------------------------------------------

-- Slot finalization logs
INSERT INTO operational_audit_logs (actor_user_id, action_type, target_entity, target_id, changes) VALUES
(5, 'FINALIZE', 'slot', 1, '{"finalized_at": {"before": null, "after": "2024-10-01T10:30:00Z"}, "attendance_updates": [{"student_id": 20, "status": {"before": "not_yet", "after": "absent"}}, {"student_id": 24, "status": {"before": "not_yet", "after": "absent"}}]}'::jsonb),
(5, 'FINALIZE', 'slot', 2, '{"finalized_at": {"before": null, "after": "2024-10-03T10:30:00Z"}}'::jsonb),
(5, 'FINALIZE', 'slot', 3, '{"finalized_at": {"before": null, "after": "2024-10-08T10:30:00Z"}, "attendance_updates": [{"student_id": 21, "status": {"before": "not_yet", "after": "absent"}}]}'::jsonb),
(6, 'FINALIZE', 'slot', 4, '{"finalized_at": {"before": null, "after": "2024-10-02T15:30:00Z"}, "attendance_updates": [{"student_id": 20, "status": {"before": "not_yet", "after": "absent"}}]}'::jsonb),
(6, 'FINALIZE', 'slot', 5, '{"finalized_at": {"before": null, "after": "2024-10-04T15:30:00Z"}}'::jsonb),
(7, 'FINALIZE', 'slot', 6, '{"finalized_at": {"before": null, "after": "2024-10-05T10:30:00Z"}}'::jsonb),
(7, 'FINALIZE', 'slot', 7, '{"finalized_at": {"before": null, "after": "2024-10-07T10:30:00Z"}, "attendance_updates": [{"student_id": 22, "status": {"before": "not_yet", "after": "absent"}}]}'::jsonb);

-- Attendance manual updates
INSERT INTO operational_audit_logs (actor_user_id, action_type, target_entity, target_id, changes) VALUES
(5, 'UPDATE', 'attendance_record', 4, '{"status": {"before": "absent", "after": "present"}, "method": {"before": "system_finalize", "after": "manual"}, "reason": "Student provided medical certificate"}'::jsonb),
(6, 'UPDATE', 'attendance_record', 9, '{"status": {"before": "absent", "after": "present"}, "method": {"before": "auto", "after": "manual"}, "reason": "Late arrival, verified manually"}'::jsonb),
(7, 'UPDATE', 'attendance_record', 19, '{"status": {"before": "present", "after": "absent"}, "method": {"before": "auto", "after": "manual"}, "reason": "Student left early for family emergency"}'::jsonb);

-- Identity submission approvals
INSERT INTO operational_audit_logs (actor_user_id, action_type, target_entity, target_id, changes) VALUES
(2, 'APPROVE', 'identity_submission', 1, '{"status": {"before": "pending", "after": "approved"}, "reviewed_at": "2024-09-15T10:00:00Z"}'::jsonb),
(2, 'APPROVE', 'identity_submission', 2, '{"status": {"before": "pending", "after": "approved"}, "reviewed_at": "2024-09-15T11:00:00Z"}'::jsonb),
(2, 'APPROVE', 'identity_submission', 3, '{"status": {"before": "pending", "after": "approved"}, "reviewed_at": "2024-09-15T14:00:00Z"}'::jsonb),
(3, 'APPROVE', 'identity_submission', 4, '{"status": {"before": "pending", "after": "approved"}, "reviewed_at": "2024-09-16T09:00:00Z"}'::jsonb);

-- Identity submission rejections
INSERT INTO operational_audit_logs (actor_user_id, action_type, target_entity, target_id, changes) VALUES
(2, 'REJECT', 'identity_submission', 14, '{"status": {"before": "pending", "after": "rejected"}, "reviewed_at": "2024-09-20T14:00:00Z", "reason": "Photo quality is too low, please retake with better lighting"}'::jsonb),
(3, 'REJECT', 'identity_submission', 15, '{"status": {"before": "pending", "after": "rejected"}, "reviewed_at": "2024-10-15T10:00:00Z", "reason": "Video does not show face clearly, please record again"}'::jsonb);

-- User creation logs
INSERT INTO operational_audit_logs (actor_user_id, action_type, target_entity, target_id, changes) VALUES
(2, 'CREATE', 'user', 17, '{"username": "HE180001", "email": "he180001@fpt.edu.vn", "full_name": "Nguyen Van An", "roles": ["STUDENT"]}'::jsonb),
(2, 'CREATE', 'user', 18, '{"username": "HE180002", "email": "he180002@fpt.edu.vn", "full_name": "Tran Thi Binh", "roles": ["STUDENT"]}'::jsonb),
(3, 'CREATE', 'user', 5, '{"username": "lec001", "email": "lec001@fpt.edu.vn", "full_name": "Dr. Nguyen Van Lecturer", "roles": ["LECTURER"]}'::jsonb);

-- Class creation logs
INSERT INTO operational_audit_logs (actor_user_id, action_type, target_entity, target_id, changes) VALUES
(2, 'CREATE', 'class', 1, '{"subject_id": 1, "semester_id": 3, "code": "SE1801"}'::jsonb),
(2, 'CREATE', 'class', 2, '{"subject_id": 1, "semester_id": 3, "code": "SE1802"}'::jsonb),
(3, 'CREATE', 'class', 4, '{"subject_id": 2, "semester_id": 3, "code": "SE1803"}'::jsonb);

-- Slot creation logs
INSERT INTO operational_audit_logs (actor_user_id, action_type, target_entity, target_id, changes) VALUES
(2, 'CREATE', 'slot', 1, '{"class_id": 1, "semester_id": 3, "room_id": 1, "staff_user_id": 5, "slot_category": "LECTURE", "start_time": "2024-10-01T08:00:00Z", "end_time": "2024-10-01T10:00:00Z"}'::jsonb),
(2, 'CREATE', 'slot', 8, '{"class_id": 1, "semester_id": 3, "room_id": 1, "staff_user_id": 5, "slot_category": "LECTURE_WITH_PT", "start_time": "2024-10-10T08:00:00Z", "end_time": "2024-10-10T10:00:00Z"}'::jsonb);

-- System configuration updates
INSERT INTO operational_audit_logs (actor_user_id, action_type, target_entity, target_id, changes) VALUES
(1, 'UPDATE', 'system_config', 2, '{"key": "attendance.max_absence_percentage", "value": {"before": "15", "after": "20"}}'::jsonb),
(1, 'UPDATE', 'system_config', 1, '{"key": "face_recognition.similarity_threshold", "value": {"before": "0.80", "after": "0.85"}}'::jsonb);

-- Enrollment management logs
INSERT INTO operational_audit_logs (actor_user_id, action_type, target_entity, target_id, changes) VALUES
(2, 'CREATE', 'enrollment', 1, '{"class_id": 1, "student_user_id": 17, "is_enrolled": true}'::jsonb),
(3, 'UPDATE', 'enrollment', 5, '{"class_id": 1, "student_user_id": 21, "is_enrolled": {"before": true, "after": false}, "reason": "Student withdrew from course"}'::jsonb);

-- =====================================================
-- SECTION 5: VERIFICATION QUERIES
-- =====================================================

-- Verify table counts
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
ORDER BY table_name;

-- =====================================================
-- SECTION 6: USEFUL SAMPLE QUERIES
-- =====================================================

-- Query 1: Get all students in a class with their attendance summary
-- SELECT 
--     u.username,
--     u.full_name,
--     COUNT(ar.id) as total_slots,
--     SUM(CASE WHEN ar.status = 'present' THEN 1 ELSE 0 END) as present_count,
--     SUM(CASE WHEN ar.status = 'absent' THEN 1 ELSE 0 END) as absent_count,
--     ROUND(100.0 * SUM(CASE WHEN ar.status = 'absent' THEN 1 ELSE 0 END) / NULLIF(COUNT(ar.id), 0), 2) as absence_percentage
-- FROM users u
-- JOIN enrollments e ON u.id = e.student_user_id
-- JOIN slots s ON e.class_id = s.class_id
-- LEFT JOIN attendance_records ar ON u.id = ar.student_user_id AND s.id = ar.slot_id
-- WHERE e.class_id = 1 AND e.is_enrolled = TRUE AND s.slot_category IN ('LECTURE', 'LECTURE_WITH_PT')
-- GROUP BY u.id, u.username, u.full_name
-- ORDER BY u.username;

-- Query 2: Get pending identity submissions
-- SELECT 
--     is_sub.id,
--     u.username,
--     u.full_name,
--     is_sub.submission_type,
--     is_sub.created_at,
--     COUNT(ia.id) as asset_count
-- FROM identity_submissions is_sub
-- JOIN users u ON is_sub.student_user_id = u.id
-- LEFT JOIN identity_assets ia ON is_sub.id = ia.submission_id
-- WHERE is_sub.status = 'pending'
-- GROUP BY is_sub.id, u.username, u.full_name, is_sub.submission_type, is_sub.created_at
-- ORDER BY is_sub.created_at;

-- Query 3: Get lecturer schedule for a specific date
-- SELECT 
--     s.id,
--     s.slot_category,
--     s.title,
--     s.start_time,
--     s.end_time,
--     r.name as room_name,
--     c.code as class_code,
--     sub.name as subject_name,
--     COUNT(DISTINCT e.student_user_id) as enrolled_students
-- FROM slots s
-- JOIN rooms r ON s.room_id = r.id
-- LEFT JOIN classes c ON s.class_id = c.id
-- LEFT JOIN subjects sub ON c.subject_id = sub.id
-- LEFT JOIN enrollments e ON c.id = e.class_id AND e.is_enrolled = TRUE
-- WHERE s.staff_user_id = 5 
--   AND DATE(s.start_time) = '2024-10-01'
-- GROUP BY s.id, s.slot_category, s.title, s.start_time, s.end_time, r.name, c.code, sub.name
-- ORDER BY s.start_time;

-- Query 4: Get students eligible for final exam in a class
-- SELECT 
--     u.username,
--     u.full_name,
--     ROUND(100.0 * SUM(CASE WHEN ar.status = 'absent' THEN 1 ELSE 0 END) / NULLIF(COUNT(ar.id), 0), 2) as absence_percentage,
--     CASE 
--         WHEN ROUND(100.0 * SUM(CASE WHEN ar.status = 'absent' THEN 1 ELSE 0 END) / NULLIF(COUNT(ar.id), 0), 2) <= 20 
--         THEN 'Eligible' 
--         ELSE 'Ineligible' 
--     END as exam_eligibility
-- FROM users u
-- JOIN enrollments e ON u.id = e.student_user_id
-- JOIN slots s ON e.class_id = s.class_id
-- LEFT JOIN attendance_records ar ON u.id = ar.student_user_id AND s.id = ar.slot_id
-- WHERE e.class_id = 1 
--   AND e.is_enrolled = TRUE 
--   AND s.slot_category IN ('LECTURE', 'LECTURE_WITH_PT')
--   AND s.finalized_at IS NOT NULL
-- GROUP BY u.id, u.username, u.full_name
-- ORDER BY absence_percentage DESC;

-- Query 5: Get exam slot participants with subjects
-- SELECT 
--     s.id as slot_id,
--     s.title as slot_title,
--     s.start_time,
--     sub.code as subject_code,
--     sub.name as subject_name,
--     u.username,
--     u.full_name,
--     esp.is_enrolled
-- FROM slots s
-- JOIN exam_slot_subjects ess ON s.id = ess.slot_id
-- JOIN subjects sub ON ess.subject_id = sub.id
-- JOIN exam_slot_participants esp ON ess.id = esp.exam_slot_subject_id
-- JOIN users u ON esp.student_user_id = u.id
-- WHERE s.slot_category = 'FINAL_EXAM' AND s.id = 18
-- ORDER BY sub.code, u.username;

-- =====================================================
-- END OF SCRIPT
-- =====================================================

-- Script execution summary
SELECT 
    'Database initialization completed successfully!' as status,
    NOW() as completed_at;
