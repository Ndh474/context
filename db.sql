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

CREATE EXTENSION IF NOT EXISTS vector;

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

CREATE TABLE password_reset_tokens (
    id SERIAL PRIMARY KEY,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP NOT NULL,
    email VARCHAR(128) NOT NULL,
    token_hash VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE roles (
    id SMALLSERIAL PRIMARY KEY,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    name VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE permissions (
    id SMALLSERIAL PRIMARY KEY,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    name VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE user_roles (
    user_id INTEGER NOT NULL,
    role_id SMALLINT NOT NULL,
    PRIMARY KEY (user_id, role_id),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE CASCADE
);

CREATE TABLE role_permissions (
    role_id SMALLINT NOT NULL,
    permission_id SMALLINT NOT NULL,
    PRIMARY KEY (role_id, permission_id),
    FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE CASCADE,
    FOREIGN KEY (permission_id) REFERENCES permissions(id) ON DELETE CASCADE
);

CREATE TABLE majors (
    id SMALLSERIAL PRIMARY KEY,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    name VARCHAR(150) NOT NULL UNIQUE,
    code VARCHAR(20) NOT NULL UNIQUE
);

CREATE TABLE student_profiles (
    user_id INTEGER PRIMARY KEY,
    major_id SMALLINT NOT NULL,
    roll_number VARCHAR(20) NOT NULL UNIQUE,
    base_photo_url VARCHAR(255) NULL,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (major_id) REFERENCES majors(id)
);

CREATE TABLE staff_profiles (
    user_id INTEGER PRIMARY KEY,
    staff_code VARCHAR(20) NOT NULL UNIQUE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

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

CREATE TABLE subjects (
    id SMALLSERIAL PRIMARY KEY,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    name VARCHAR(150) NOT NULL,
    code VARCHAR(20) NOT NULL UNIQUE
);

CREATE TABLE subject_majors (
    subject_id SMALLINT NOT NULL,
    major_id SMALLINT NOT NULL,
    PRIMARY KEY (subject_id, major_id),
    FOREIGN KEY (subject_id) REFERENCES subjects(id) ON DELETE CASCADE,
    FOREIGN KEY (major_id) REFERENCES majors(id) ON DELETE CASCADE
);

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

CREATE TABLE rooms (
    id SMALLSERIAL PRIMARY KEY,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    name VARCHAR(150) NOT NULL UNIQUE,
    location VARCHAR(255) NULL
);

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
    -- Session metadata for face recognition workflow
    session_status VARCHAR(20) NOT NULL DEFAULT 'NOT_STARTED' CHECK (session_status IN ('NOT_STARTED', 'RUNNING', 'STOPPED')),
    scan_count INTEGER NOT NULL DEFAULT 0,
    last_session_stopped_at TIMESTAMP NULL,
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
CREATE INDEX idx_slots_session_status ON slots(session_status);

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

CREATE TABLE regular_attendance_evidences (
    id BIGSERIAL PRIMARY KEY,
    attendance_record_id BIGINT NOT NULL UNIQUE,
    image_url VARCHAR(255) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (attendance_record_id) REFERENCES attendance_records(id) ON DELETE CASCADE
);

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

CREATE TABLE exam_attendance_evidences (
    id BIGSERIAL PRIMARY KEY,
    exam_attendance_id BIGINT NOT NULL UNIQUE,
    image_url VARCHAR(255) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (exam_attendance_id) REFERENCES exam_attendance(id) ON DELETE CASCADE
);

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

CREATE TABLE system_configurations (
    id SERIAL PRIMARY KEY,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    key VARCHAR(255) NOT NULL UNIQUE,
    value TEXT NOT NULL,
    description TEXT NULL
);
