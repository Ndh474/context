-- =====================================================
-- SCRIPT CHÈN DỮ LIỆU CỐT LÕI (CORE DATA) - PHIÊN BẢN 2
-- Đã loại bỏ chèn ID thủ công cho các bảng SERIAL (users, majors)
-- Sử dụng DO/RETURNING để đảm bảo tính toàn vẹn của Foreign Key.
-- Mật khẩu cho tất cả user: (hash của "password123")
-- =====================================================

DO $$
DECLARE
    -- Biến lưu trữ ID của Major
    v_se_major_id INT;
    
    -- Biến lưu trữ ID của các User
    v_sysadmin_id INT;
    v_dop_id INT;
    v_lecturer_id INT;
    v_supervisor_id INT;
    v_student_id INT;
BEGIN

    -- -----------------------------------------------------
    -- PHẦN 1: CHÈN DỮ LIỆU ROLES CỐT LÕI (ID CỐ ĐỊNH)
    -- -----------------------------------------------------
    INSERT INTO roles (id, name, is_active) VALUES
    (1, 'SYSTEM_ADMIN', TRUE),
    (2, 'DATA_OPERATOR', TRUE),
    (3, 'LECTURER', TRUE),
    (4, 'SUPERVISOR', TRUE),
    (5, 'STUDENT', TRUE)
    ON CONFLICT (id) DO NOTHING;

    -- -----------------------------------------------------
    -- PHẦN 2: CHÈN DỮ LIỆU PERMISSIONS CỐT LÕI (TỪ CORE_CONTEXT)
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
    ('OWN_PASSWORD_UPDATE', TRUE)
    ON CONFLICT (name) DO NOTHING;

    -- -----------------------------------------------------
    -- PHẦN 3: CHÈN DỮ LIỆU ROLE-PERMISSION MAPPINGS (TỪ CORE_CONTEXT)
    -- -----------------------------------------------------

    -- SYSTEM_ADMIN (Role ID 1)
    INSERT INTO role_permissions (role_id, permission_id)
    SELECT 1, id FROM permissions WHERE name IN (
        'SYSTEM_CONFIG_READ', 'SYSTEM_CONFIG_UPDATE', 'ROLE_PERMISSION_MAPPING_READ',
        'ROLE_PERMISSION_MAPPING_UPDATE', 'SYSTEM_LOG_READ', 'OWN_PROFILE_READ',
        'OWN_PASSWORD_UPDATE', 'ROLE_CREATE', 'ROLE_UPDATE', 'ROLE_DELETE_HARD',
        'PERMISSION_CREATE', 'PERMISSION_UPDATE', 'PERMISSION_DELETE_HARD'
    ) ON CONFLICT DO NOTHING;

    -- DATA_OPERATOR (Role ID 2)
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
        'REPORT_READ_SYSTEM_WIDE', 'REPORT_EXPORT_ACADEMIC_DATA',
        'OWN_PROFILE_READ', 'OWN_PASSWORD_UPDATE'
    ) ON CONFLICT DO NOTHING;

    -- LECTURER (Role ID 3)
    INSERT INTO role_permissions (role_id, permission_id)
    SELECT 3, id FROM permissions WHERE name IN (
        'OWN_SCHEDULE_READ', 'SLOT_SESSION_START', 'SLOT_SESSION_RESCAN',
        'SLOT_SESSION_FINALIZE', 'ATTENDANCE_ROSTER_READ', 'ATTENDANCE_STATUS_UPDATE_MANUAL',
        'ATTENDANCE_REMARK_MANAGE', 'REPORT_READ_OWN_SLOT', 'REPORT_EXPORT_OWN_SLOT',
        'REPORT_READ_CLASS_SUMMARY', 'REPORT_READ_SYSTEM_WIDE', 'OWN_PROFILE_READ',
        'OWN_PASSWORD_UPDATE', 'ROOM_READ', 'CAMERA_READ', 'SEMESTER_READ', 'CLASS_READ',
        'MAJOR_READ', 'SLOT_READ', 'SUBJECT_READ', 'SLOT_UPDATE_CATEGORY'
    ) ON CONFLICT DO NOTHING;

    -- SUPERVISOR (Role ID 4)
    INSERT INTO role_permissions (role_id, permission_id)
    SELECT 4, id FROM permissions WHERE name IN (
        'OWN_SCHEDULE_READ', 'SLOT_SESSION_START', 'SLOT_SESSION_RESCAN',
        'SLOT_SESSION_FINALIZE', 'ATTENDANCE_ROSTER_READ', 'ATTENDANCE_STATUS_UPDATE_MANUAL',
        'ATTENDANCE_REMARK_MANAGE', 'REPORT_READ_OWN_SLOT', 'REPORT_EXPORT_OWN_SLOT',
        'REPORT_READ_SYSTEM_WIDE', 'OWN_PROFILE_READ', 'OWN_PASSWORD_UPDATE',
        'ROOM_READ', 'CAMERA_READ', 'SEMESTER_READ', 'CLASS_READ', 'MAJOR_READ',
        'SLOT_READ', 'SUBJECT_READ'
    ) ON CONFLICT DO NOTHING;

    -- STUDENT (Role ID 5)
    INSERT INTO role_permissions (role_id, permission_id)
    SELECT 5, id FROM permissions WHERE name IN (
        'OWN_SCHEDULE_READ', 'OWN_ATTENDANCE_HISTORY_READ', 'OWN_PROFILE_READ',
        'OWN_PASSWORD_UPDATE', 'ROOM_READ', 'SEMESTER_READ', 'CLASS_READ',
        'MAJOR_READ', 'SLOT_READ', 'SUBJECT_READ'
    ) ON CONFLICT DO NOTHING;

    -- -----------------------------------------------------
    -- PHẦN 4: CHÈN DỮ LIỆU PHỤ THUỘC (MAJOR MẪU)
    -- -----------------------------------------------------
    INSERT INTO majors (name, code, is_active) VALUES
    ('Software Engineering', 'SE', TRUE)
    ON CONFLICT (code) DO NOTHING
    RETURNING id INTO v_se_major_id;

    -- Nếu v_se_major_id vẫn là NULL (do CONFLICT), thử lấy ID đã có
    IF v_se_major_id IS NULL THEN
        SELECT id INTO v_se_major_id FROM majors WHERE code = 'SE';
    END IF;


    -- -----------------------------------------------------
    -- PHẦN 5: CHÈN 5 USER MẪU (Không chèn ID)
    -- -----------------------------------------------------
    INSERT INTO users (username, email, full_name, password_hash, is_active) VALUES
    ('sysadmin01', 'sysadmin01@fuacs.edu.vn', 'System Admin', '$2a$12$5GT82ZOlPRp1CevjrpVMW.1qNqdYA.aDK2Tyy.0X9etJR.E9EEMHq', TRUE)
    ON CONFLICT (username) DO NOTHING
    RETURNING id INTO v_sysadmin_id;

    INSERT INTO users (username, email, full_name, password_hash, is_active) VALUES
    ('dop01', 'dop01@fuacs.edu.vn', 'Data Operator', '$2a$12$5GT82ZOlPRp1CevjrpVMW.1qNqdYA.aDK2Tyy.0X9etJR.E9EEMHq', TRUE)
    ON CONFLICT (username) DO NOTHING
    RETURNING id INTO v_dop_id;

    INSERT INTO users (username, email, full_name, password_hash, is_active) VALUES
    ('lecturer01', 'lecturer01@fuacs.edu.vn', 'Lecturer FUACS', '$2a$12$5GT82ZOlPRp1CevjrpVMW.1qNqdYA.aDK2Tyy.0X9etJR.E9EEMHq', TRUE)
    ON CONFLICT (username) DO NOTHING
    RETURNING id INTO v_lecturer_id;

    INSERT INTO users (username, email, full_name, password_hash, is_active) VALUES
    ('supervisor01', 'supervisor01@fuacs.edu.vn', 'Supervisor FUACS', '$2a$12$5GT82ZOlPRp1CevjrpVMW.1qNqdYA.aDK2Tyy.0X9etJR.E9EEMHq', TRUE)
    ON CONFLICT (username) DO NOTHING
    RETURNING id INTO v_supervisor_id;

    INSERT INTO users (username, email, full_name, password_hash, is_active) VALUES
    ('student01', 'student01@fuacs.edu.vn', 'Student FUACS', '$2a$12$5GT82ZOlPRp1CevjrpVMW.1qNqdYA.aDK2Tyy.0X9etJR.E9EEMHq', TRUE)
    ON CONFLICT (username) DO NOTHING
    RETURNING id INTO v_student_id;

    -- -----------------------------------------------------
    -- PHẦN 6: CHÈN PROFILES CHO USER MẪU (Sử dụng Biến ID)
    -- -----------------------------------------------------
    
    -- Lấy lại ID nếu user đã tồn tại (do CONFLICT)
    IF v_sysadmin_id IS NULL THEN SELECT id INTO v_sysadmin_id FROM users WHERE username = 'sysadmin01'; END IF;
    IF v_dop_id IS NULL THEN SELECT id INTO v_dop_id FROM users WHERE username = 'dop01'; END IF;
    IF v_lecturer_id IS NULL THEN SELECT id INTO v_lecturer_id FROM users WHERE username = 'lecturer01'; END IF;
    IF v_supervisor_id IS NULL THEN SELECT id INTO v_supervisor_id FROM users WHERE username = 'supervisor01'; END IF;
    IF v_student_id IS NULL THEN SELECT id INTO v_student_id FROM users WHERE username = 'student01'; END IF;

    -- Chèn Staff Profiles
    IF v_sysadmin_id IS NOT NULL THEN
        INSERT INTO staff_profiles (user_id, staff_code) VALUES (v_sysadmin_id, 'SYSADMIN01') ON CONFLICT (user_id) DO NOTHING;
    END IF;
    IF v_dop_id IS NOT NULL THEN
        INSERT INTO staff_profiles (user_id, staff_code) VALUES (v_dop_id, 'DOP01') ON CONFLICT (user_id) DO NOTHING;
    END IF;
    IF v_lecturer_id IS NOT NULL THEN
        INSERT INTO staff_profiles (user_id, staff_code) VALUES (v_lecturer_id, 'LEC01') ON CONFLICT (user_id) DO NOTHING;
    END IF;
    IF v_supervisor_id IS NOT NULL THEN
        INSERT INTO staff_profiles (user_id, staff_code) VALUES (v_supervisor_id, 'SUP01') ON CONFLICT (user_id) DO NOTHING;
    END IF;

    -- Chèn Student Profile
    IF v_student_id IS NOT NULL AND v_se_major_id IS NOT NULL THEN
        INSERT INTO student_profiles (user_id, major_id, roll_number) VALUES
        (v_student_id, v_se_major_id, 'HE180001') -- Gán cho major_id đã lấy ở trên
        ON CONFLICT (user_id) DO NOTHING;
    END IF;

    -- -----------------------------------------------------
    -- PHẦN 7: GÁN VAI TRÒ (ROLE) CHO USER MẪU (Sử dụng Biến ID)
    -- -----------------------------------------------------
    IF v_sysadmin_id IS NOT NULL THEN
        INSERT INTO user_roles (user_id, role_id) VALUES (v_sysadmin_id, 1) ON CONFLICT DO NOTHING; -- SYSTEM_ADMIN
    END IF;
    IF v_dop_id IS NOT NULL THEN
        INSERT INTO user_roles (user_id, role_id) VALUES (v_dop_id, 2) ON CONFLICT DO NOTHING; -- DATA_OPERATOR
    END IF;
    IF v_lecturer_id IS NOT NULL THEN
        INSERT INTO user_roles (user_id, role_id) VALUES (v_lecturer_id, 3) ON CONFLICT DO NOTHING; -- LECTURER
    END IF;
    IF v_supervisor_id IS NOT NULL THEN
        INSERT INTO user_roles (user_id, role_id) VALUES (v_supervisor_id, 4) ON CONFLICT DO NOTHING; -- SUPERVISOR
    END IF;
    IF v_student_id IS NOT NULL THEN
        INSERT INTO user_roles (user_id, role_id) VALUES (v_student_id, 5) ON CONFLICT DO NOTHING; -- STUDENT
    END IF;

END $$;

