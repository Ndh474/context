-- =====================================================
-- XÓA TẤT CẢ DỮ LIỆU CỦA ỨNG DỤNG (FUACS)
-- Sử dụng TRUNCATE TABLE để xóa nhanh và đặt lại ID.
-- KHÔNG XÓA BẢNG flyway_schema_history
-- =====================================================

TRUNCATE TABLE 
    attendance_records,         -- Bản ghi tham dự
    face_embeddings,            -- Vector nhúng khuôn mặt
    enrollments,                -- Đăng ký lớp học
    slots,                      -- Slots giảng dạy/thi

    classes,                    -- Lớp học
    subject_majors,             -- Ánh xạ Môn học - Ngành
    subjects,                   -- Môn học

    student_profiles,           -- Hồ sơ sinh viên
    staff_profiles,             -- Hồ sơ nhân viên
    user_roles,                 -- Vai trò người dùng

    users,                      -- Người dùng
    majors,                     -- Ngành học
    semesters,                  -- Kỳ học

    cameras,                    -- Camera
    rooms,                      -- Phòng học
    role_permissions,           -- Phân quyền Role-Permission
    permissions,                -- Quyền hạn
    roles,                      -- Vai trò (nếu không muốn giữ các ID cố định)
    system_notifications        -- Thông báo hệ thống
RESTART IDENTITY CASCADE;

-- LƯU Ý: Nếu bạn KHÔNG muốn đặt lại ID (sequence) của các bảng, 
-- hãy bỏ từ khóa RESTART IDENTITY và CASCADE.
-- Tuy nhiên, RESTART IDENTITY được khuyến nghị khi re-seed data.

SELECT 'Data reset completed. All application tables truncated and sequences restarted.' AS status;


-- =====================================================
-- FUACS Seed Data Script
-- Comprehensive test data for development and testing
-- Compatible with Flyway migrations V1 and V2
-- UPDATED: 180 Classes, 3780 Slots, 18 Active Semesters
-- =====================================================

-- Password for all users: "password123"
-- Hash: $2a$12$7mndAdNMDa2v0rzNZo/zAeSyizvL0s0gcYmrJU0jEvm8lla8buOza

-- =====================================================
-- SECTION 1: MASTER DATA (Fixed IDs)
-- =====================================================

-- Insert Roles (Fixed IDs - won't change)
INSERT INTO roles (id, name, is_active) VALUES
(1, 'DATA_OPERATOR', TRUE),
(2, 'LECTURER', TRUE),
(3, 'SUPERVISOR', TRUE),
(4, 'STUDENT', TRUE)
ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, is_active = EXCLUDED.is_active;

-- Insert Permissions (No ID specified - auto-generated)
INSERT INTO permissions (name, is_active) VALUES
('USER_CREATE', TRUE),
('USER_READ_LIST', TRUE),
('USER_READ_DETAIL', TRUE),
('USER_UPDATE_INFO', TRUE),
('USER_UPDATE_STATUS', TRUE),
('USER_DELETE_HARD', TRUE),
('USER_ASSIGN_ROLES', TRUE),
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
('ROOM_CREATE', TRUE),
('ROOM_READ', TRUE),
('ROOM_UPDATE', TRUE),
('CAMERA_CREATE', TRUE),
('CAMERA_READ', TRUE),
('CAMERA_UPDATE', TRUE),
('OWN_SCHEDULE_READ', TRUE),
('SLOT_SESSION_START', TRUE),
('SLOT_SESSION_RESCAN', TRUE),
('ATTENDANCE_ROSTER_READ', TRUE),
('ATTENDANCE_STATUS_UPDATE_MANUAL', TRUE),
('ATTENDANCE_REMARK_MANAGE', TRUE),
('OWN_ATTENDANCE_HISTORY_READ', TRUE),
('OWN_PROFILE_READ', TRUE),
('OWN_PASSWORD_UPDATE', TRUE)
ON CONFLICT (name) DO NOTHING;

-- Role-Permission Mappings
-- DATA_OPERATOR (role_id = 1)
INSERT INTO role_permissions (role_id, permission_id)
SELECT 1, id FROM permissions WHERE name IN (
    'USER_CREATE', 'USER_READ_LIST', 'USER_UPDATE_INFO', 'SEMESTER_CREATE', 'SEMESTER_READ',
    'MAJOR_CREATE', 'MAJOR_READ', 'SUBJECT_CREATE', 'SUBJECT_READ', 'CLASS_CREATE', 'CLASS_READ',
    'SLOT_CREATE', 'SLOT_READ', 'ENROLLMENT_MANAGE', 'ROOM_CREATE', 'ROOM_READ',
    'CAMERA_CREATE', 'CAMERA_READ', 'ATTENDANCE_ROSTER_READ', 'ATTENDANCE_STATUS_UPDATE_MANUAL'
) ON CONFLICT DO NOTHING;

-- LECTURER (role_id = 2)
INSERT INTO role_permissions (role_id, permission_id)
SELECT 2, id FROM permissions WHERE name IN (
    'OWN_SCHEDULE_READ', 'SLOT_SESSION_START', 'SLOT_SESSION_RESCAN', 'ATTENDANCE_ROSTER_READ',
    'ATTENDANCE_STATUS_UPDATE_MANUAL', 'ATTENDANCE_REMARK_MANAGE', 'ROOM_READ', 'CAMERA_READ'
) ON CONFLICT DO NOTHING;

-- SUPERVISOR (role_id = 3)
INSERT INTO role_permissions (role_id, permission_id)
SELECT 3, id FROM permissions WHERE name IN (
    'OWN_SCHEDULE_READ', 'SLOT_SESSION_START', 'ATTENDANCE_ROSTER_READ', 'ROOM_READ'
) ON CONFLICT DO NOTHING;

-- STUDENT (role_id = 4)
INSERT INTO role_permissions (role_id, permission_id)
SELECT 4, id FROM permissions WHERE name IN (
    'OWN_SCHEDULE_READ', 'OWN_ATTENDANCE_HISTORY_READ', 'OWN_PROFILE_READ', 'OWN_PASSWORD_UPDATE'
) ON CONFLICT DO NOTHING;

-- =====================================================
-- SECTION 2: SEMESTERS (18 KỲ - 2020-2025, TẤT CẢ ĐỀU ACTIVE)
-- =====================================================

INSERT INTO semesters (name, code, start_date, end_date, is_active) VALUES
-- 2020
('Spring 2020', 'SP20', '2020-01-01', '2020-04-30', TRUE),
('Summer 2020', 'SU20', '2020-05-01', '2020-08-31', TRUE),
('Fall 2020', 'FA20', '2020-09-01', '2020-12-31', TRUE),
-- 2021
('Spring 2021', 'SP21', '2021-01-01', '2021-04-30', TRUE),
('Summer 2021', 'SU21', '2021-05-01', '2021-08-31', TRUE),
('Fall 2021', 'FA21', '2021-09-01', '2021-12-31', TRUE),
-- 2022
('Spring 2022', 'SP22', '2022-01-01', '2022-04-30', TRUE),
('Summer 2022', 'SU22', '2022-05-01', '2022-08-31', TRUE),
('Fall 2022', 'FA22', '2022-09-01', '2022-12-31', TRUE),
-- 2023
('Spring 2023', 'SP23', '2023-01-01', '2023-04-30', TRUE),
('Summer 2023', 'SU23', '2023-05-01', '2023-08-31', TRUE),
('Fall 2023', 'FA23', '2023-09-01', '2023-12-31', TRUE),
-- 2024
('Spring 2024', 'SP24', '2024-01-01', '2024-04-30', TRUE),
('Summer 2024', 'SU24', '2024-05-01', '2024-08-31', TRUE),
('Fall 2024', 'FA24', '2024-09-01', '2024-12-31', TRUE),
-- 2025
('Spring 2025', 'SP25', '2025-01-01', '2025-04-30', TRUE),
('Summer 2025', 'SU25', '2025-05-01', '2025-08-31', TRUE),
('Fall 2025', 'FA25', '2025-09-01', '2025-12-31', TRUE)
ON CONFLICT (code) DO NOTHING;

-- =====================================================
-- SECTION 3: MAJORS
-- =====================================================

INSERT INTO majors (name, code, is_active) VALUES
('Software Engineering', 'SE', TRUE),
('Information Assurance', 'IA', TRUE),
('Artificial Intelligence', 'AI', TRUE),
('Internet of Things', 'IOT', TRUE),
('Digital Art Design', 'DAD', TRUE),
('Business Administration', 'BA', TRUE)
ON CONFLICT (code) DO NOTHING;

-- =====================================================
-- SECTION 4: SUBJECTS
-- =====================================================

INSERT INTO subjects (name, code, is_active) VALUES
-- Core subjects (multiple majors)
('Programming Fundamentals', 'PRF192', TRUE),
('Object-Oriented Programming', 'PRO192', TRUE),
('Data Structures and Algorithms', 'CSD201', TRUE),
('Database Management Systems', 'DBI202', TRUE),
-- SE specific
('Software Engineering', 'SWE201', TRUE),
('Web Development', 'SWP391', TRUE),
('Mobile Application Development', 'PRM392', TRUE),
-- IA specific
('Information Security', 'SEC301', TRUE),
('Network Security', 'NWS301', TRUE),
('Cryptography', 'CRY301', TRUE),
-- AI specific
('Machine Learning', 'MLA301', TRUE),
('Deep Learning', 'DLP301', TRUE),
('Natural Language Processing', 'NLP301', TRUE),
-- IOT specific
('Embedded Systems', 'EMB301', TRUE),
('Wireless Networks', 'WNW301', TRUE),
-- DAD specific
('UI/UX Design', 'UIX301', TRUE),
('Graphic Design', 'GRD301', TRUE),
-- BA specific
('Business Management', 'BMG301', TRUE),
('Marketing Fundamentals', 'MKT301', TRUE)
ON CONFLICT (code) DO NOTHING;

-- Subject-Major Mappings
INSERT INTO subject_majors (subject_id, major_id)
SELECT s.id, m.id FROM subjects s, majors m
WHERE (s.code = 'PRF192' AND m.code IN ('SE', 'AI', 'IOT'))
   OR (s.code = 'PRO192' AND m.code IN ('SE', 'AI', 'IOT'))
   OR (s.code = 'CSD201' AND m.code IN ('SE', 'AI'))
   OR (s.code = 'DBI202' AND m.code IN ('SE', 'IA'))
   OR (s.code = 'SWE201' AND m.code = 'SE')
   OR (s.code = 'SWP391' AND m.code = 'SE')
   OR (s.code = 'PRM392' AND m.code = 'SE')
   OR (s.code = 'SEC301' AND m.code = 'IA')
   OR (s.code = 'NWS301' AND m.code = 'IA')
   OR (s.code = 'CRY301' AND m.code = 'IA')
   OR (s.code = 'MLA301' AND m.code = 'AI')
   OR (s.code = 'DLP301' AND m.code = 'AI')
   OR (s.code = 'NLP301' AND m.code = 'AI')
   OR (s.code = 'EMB301' AND m.code = 'IOT')
   OR (s.code = 'WNW301' AND m.code = 'IOT')
   OR (s.code = 'UIX301' AND m.code = 'DAD')
   OR (s.code = 'GRD301' AND m.code = 'DAD')
   OR (s.code = 'BMG301' AND m.code = 'BA')
   OR (s.code = 'MKT301' AND m.code = 'BA')
ON CONFLICT DO NOTHING;

-- =====================================================
-- SECTION 5: ROOMS AND CAMERAS (20 Rooms, 40 Cameras)
-- =====================================================

INSERT INTO rooms (name, location, is_active) VALUES
-- Building Alpha - 5 rooms
('Room 101', 'Building Alpha - Floor 1', TRUE),
('Room 102', 'Building Alpha - Floor 1', TRUE),
('Room 103', 'Building Alpha - Floor 1', TRUE),
('Room 104', 'Building Alpha - Floor 1', TRUE),
('Room 105', 'Building Alpha - Floor 1', TRUE),
-- Building Beta - 5 rooms
('Room 201', 'Building Beta - Floor 2', TRUE),
('Room 202', 'Building Beta - Floor 2', TRUE),
('Room 203', 'Building Beta - Floor 2', TRUE),
('Room 204', 'Building Beta - Floor 2', TRUE),
('Room 205', 'Building Beta - Floor 2', TRUE),
-- Building Gamma - 5 labs
('Lab 301', 'Building Gamma - Floor 3', TRUE),
('Lab 302', 'Building Gamma - Floor 3', TRUE),
('Lab 303', 'Building Gamma - Floor 3', TRUE),
('Lab 304', 'Building Gamma - Floor 3', TRUE),
('Lab 305', 'Building Gamma - Floor 3', TRUE),
-- Building Delta - 5 rooms
('Room 401', 'Building Delta - Floor 4', TRUE),
('Room 402', 'Building Delta - Floor 4', TRUE),
('Room 403', 'Building Delta - Floor 4', TRUE),
('Room 404', 'Building Delta - Floor 4', TRUE),
('Room 405', 'Building Delta - Floor 4', TRUE)
ON CONFLICT (name) DO NOTHING;

-- Cameras (2 cameras per room: FRONT and BACK)
INSERT INTO cameras (room_id, name, rtsp_url, is_active)
SELECT r.id, 'CAM-' || r.name || '-FRONT', 
       CASE 
           WHEN r.name = 'Room 101' THEN 'rtsp://C200C_FUACS2:12345678@192.168.1.80:554/stream1'
           ELSE 'rtsp://192.168.1.' || (80 + (r.id % 100)) || ':554/stream1'
       END,
       TRUE
FROM rooms r
ON CONFLICT (name) DO NOTHING;

INSERT INTO cameras (room_id, name, rtsp_url, is_active)
SELECT r.id, 'CAM-' || r.name || '-BACK', 
       'rtsp://192.168.1.' || (180 + (r.id % 100)) || ':554/stream2',
       TRUE
FROM rooms r
ON CONFLICT (name) DO NOTHING;

-- =====================================================
-- SECTION 6: USERS (Data Operator, 5 Supervisors, 10 Lecturers, ~150 Students)
-- =====================================================

-- Data Operator
INSERT INTO users (username, email, full_name, password_hash, is_active) VALUES
('dop001', 'dop001@fpt.edu.vn', 'Nguyen Van Data Operator', '$2a$12$7mndAdNMDa2v0rzNZo/zAeSyizvL0s0gcYmrJU0jEvm8lla8buOza', TRUE)
ON CONFLICT (username) DO NOTHING;

INSERT INTO staff_profiles (user_id, staff_code)
SELECT u.id, 'DOP001'
FROM users u
WHERE u.username = 'dop001'
ON CONFLICT (user_id) DO NOTHING;

INSERT INTO user_roles (user_id, role_id)
SELECT u.id, 1
FROM users u
WHERE u.username = 'dop001'
ON CONFLICT DO NOTHING;

-- Supervisors (5 supervisors for exam supervision)
DO $$
DECLARE
    v_supervisor_names TEXT[] := ARRAY[
        'Mr. Nguyen Van Supervisor', 'Ms. Tran Thi Supervisor', 'Mr. Le Van Supervisor',
        'Ms. Pham Thi Supervisor', 'Mr. Hoang Van Supervisor'
    ];
    v_user_id INT;
    i INT;
BEGIN
    FOR i IN 1..5 LOOP
        INSERT INTO users (username, email, full_name, password_hash, is_active)
        VALUES (
            'sup' || LPAD(i::TEXT, 3, '0'),
            'sup' || LPAD(i::TEXT, 3, '0') || '@fpt.edu.vn',
            v_supervisor_names[i],
            '$2a$12$7mndAdNMDa2v0rzNZo/zAeSyizvL0s0gcYmrJU0jEvm8lla8buOza',
            TRUE
        )
        ON CONFLICT (username) DO NOTHING
        RETURNING id INTO v_user_id;
        
        IF v_user_id IS NOT NULL THEN
            INSERT INTO staff_profiles (user_id, staff_code)
            VALUES (v_user_id, 'SUP' || LPAD(i::TEXT, 3, '0'))
            ON CONFLICT (user_id) DO NOTHING;
            
            INSERT INTO user_roles (user_id, role_id)
            VALUES (v_user_id, 3)
            ON CONFLICT DO NOTHING;
        END IF;
    END LOOP;
END $$;

-- Lecturers (10 lecturers)
DO $$
DECLARE
    v_lecturer_names TEXT[] := ARRAY[
        'Dr. Nguyen Van Anh', 'MSc. Tran Thi Binh', 'Prof. Le Van Cuong',
        'Dr. Pham Thi Dung', 'MSc. Hoang Van Em', 'Dr. Vu Thi Phuong',
        'Prof. Vo Van Giang', 'MSc. Dang Thi Hoa', 'Dr. Bui Van Hung',
        'Prof. Do Thi Khanh'
    ];
    v_user_id INT;
    i INT;
BEGIN
    FOR i IN 1..10 LOOP
        INSERT INTO users (username, email, full_name, password_hash, is_active)
        VALUES (
            'lec' || LPAD(i::TEXT, 3, '0'),
            'lec' || LPAD(i::TEXT, 3, '0') || '@fpt.edu.vn',
            v_lecturer_names[i],
            '$2a$12$7mndAdNMDa2v0rzNZo/zAeSyizvL0s0gcYmrJU0jEvm8lla8buOza',
            TRUE
        )
        ON CONFLICT (username) DO NOTHING
        RETURNING id INTO v_user_id;
        
        IF v_user_id IS NOT NULL THEN
            INSERT INTO staff_profiles (user_id, staff_code)
            VALUES (v_user_id, 'LEC' || LPAD(i::TEXT, 3, '0'))
            ON CONFLICT (user_id) DO NOTHING;
            
            INSERT INTO user_roles (user_id, role_id)
            VALUES (v_user_id, 2)
            ON CONFLICT DO NOTHING;
        END IF;
    END LOOP;
END $$;

-- Special Test Student: Nguyen Doan Hieu (HE180314)
INSERT INTO users (username, email, full_name, password_hash, is_active) VALUES
('HE180314', 'he180314@fpt.edu.vn', 'Nguyen Doan Hieu', '$2a$12$7mndAdNMDa2v0rzNZo/zAeSyizvL0s0gcYmrJU0jEvm8lla8buOza', TRUE)
ON CONFLICT (username) DO NOTHING;

INSERT INTO student_profiles (user_id, major_id, roll_number, base_photo_url)
SELECT u.id, m.id, 'HE180314', '9010_profile.jpg'
FROM users u, majors m
WHERE u.username = 'HE180314' AND m.code = 'SE'
ON CONFLICT (user_id) DO NOTHING;

INSERT INTO user_roles (user_id, role_id)
SELECT u.id, 4
FROM users u
WHERE u.username = 'HE180314'
ON CONFLICT DO NOTHING;

INSERT INTO face_embeddings (student_user_id, version, is_active, embedding_vector)
SELECT u.id, 1, TRUE, array_fill(RANDOM()::REAL, ARRAY[512])::vector
FROM users u
WHERE u.username = 'HE180314'
ON CONFLICT (student_user_id) WHERE is_active = true DO NOTHING;

-- Students (150 students - 25 per major for 6 majors)
DO $$
DECLARE
    v_major_codes TEXT[] := ARRAY['SE', 'IA', 'AI', 'IOT', 'DAD', 'BA'];
    v_major_prefixes TEXT[] := ARRAY['HE', 'HS', 'HA', 'HI', 'HD', 'HB'];
    v_first_names TEXT[] := ARRAY['Nguyen', 'Tran', 'Le', 'Pham', 'Hoang', 'Vu', 'Vo', 'Dang', 'Bui', 'Do'];
    v_middle_names TEXT[] := ARRAY['Van', 'Thi', 'Minh', 'Thanh', 'Duc'];
    v_last_names TEXT[] := ARRAY['An', 'Binh', 'Cuong', 'Dung', 'Em', 'Phuong', 'Giang', 'Hoa', 'Hung', 'Khanh',
                                  'Linh', 'Mai', 'Nam', 'Oanh', 'Phong', 'Quynh', 'Son', 'Tuan', 'Uyen', 'Vinh',
                                  'Xuan', 'Yen', 'Anh', 'Bao', 'Chi'];
    v_user_id INT;
    v_major_id INT;
    v_username TEXT;
    v_full_name TEXT;
    i INT;
    j INT;
BEGIN
    FOR i IN 1..6 LOOP -- 6 majors
        SELECT id INTO v_major_id FROM majors WHERE code = v_major_codes[i];
        
        FOR j IN 1..25 LOOP -- 25 students per major
            v_username := v_major_prefixes[i] || '18' || LPAD(((i-1)*25 + j)::TEXT, 4, '0');
            
            -- Skip HE180314 as it's already created
            CONTINUE WHEN v_username = 'HE180314';
            
            v_full_name := v_first_names[1 + (j % 10)] || ' ' || 
                          v_middle_names[1 + (j % 5)] || ' ' ||
                          v_last_names[j];
            
            INSERT INTO users (username, email, full_name, password_hash, is_active)
            VALUES (
                v_username,
                LOWER(v_username) || '@fpt.edu.vn',
                v_full_name,
                '$2a$12$7mndAdNMDa2v0rzNZo/zAeSyizvL0s0gcYmrJU0jEvm8lla8buOza',
                TRUE
            )
            ON CONFLICT (username) DO NOTHING
            RETURNING id INTO v_user_id;
            
            IF v_user_id IS NOT NULL THEN
                INSERT INTO student_profiles (user_id, major_id, roll_number, base_photo_url)
                VALUES (v_user_id, v_major_id, v_username, '/photos/' || LOWER(v_username) || '.jpg')
                ON CONFLICT (user_id) DO NOTHING;
                
                INSERT INTO user_roles (user_id, role_id)
                VALUES (v_user_id, 4)
                ON CONFLICT DO NOTHING;
                
                -- Face embeddings
                INSERT INTO face_embeddings (student_user_id, version, is_active, embedding_vector)
                VALUES (v_user_id, 1, TRUE, array_fill(RANDOM()::REAL, ARRAY[512])::vector)
                ON CONFLICT (student_user_id) WHERE is_active = true DO NOTHING;
            END IF;
        END LOOP;
    END LOOP;
END $$;

-- =====================================================
-- SECTION 7: CLASSES (10 classes per semester for ALL 18 semesters)
-- Total classes: 18 * 10 = 180 classes
-- CẬP NHẬT: Lặp qua TẤT CẢ 18 semesters (thay vì chỉ 2)
-- =====================================================

DO $$
DECLARE
    v_subject_codes TEXT[] := ARRAY['PRF192', 'PRO192', 'CSD201', 'DBI202', 'SWE201', 
                                     'SWP391', 'SEC301', 'MLA301', 'EMB301', 'UIX301'];
    v_semester_record RECORD;
    v_subject_id INT;
    v_class_id INT;
    j INT;
BEGIN
    -- Lặp qua TẤT CẢ các semester
    FOR v_semester_record IN (SELECT id, code, start_date FROM semesters ORDER BY start_date) LOOP
        -- Tạo 10 classes cho MỖI semester (Đúng yêu cầu)
        FOR j IN 1..10 LOOP 
            SELECT id INTO v_subject_id FROM subjects WHERE code = v_subject_codes[j];
            
            INSERT INTO classes (subject_id, semester_id, code, is_active)
            -- Tạo mã lớp: SEMESTERCODE-SUBJECTCODE-ClassIndex (e.g., SP20-PRF192-01)
            VALUES (v_subject_id, v_semester_record.id, v_semester_record.code || '-' || v_subject_codes[j] || '-' || LPAD(j::TEXT, 2, '0'), TRUE)
            ON CONFLICT DO NOTHING
            RETURNING id INTO v_class_id;
        END LOOP;
    END LOOP;
END $$;

-- =====================================================
-- SECTION 8: ENROLLMENTS (20 students per class - matching major and subject)
-- TỰ ĐỘNG xử lý 180 classes mới tạo
-- =====================================================

DO $$
DECLARE
    v_class_record RECORD;
    v_student_ids INT[];
    v_student_id INT;
    v_major_ids INT[];
BEGIN
    FOR v_class_record IN (
        SELECT c.id as class_id, c.subject_id
        FROM classes c
    ) LOOP
        -- Get majors that can take this subject
        SELECT ARRAY_AGG(DISTINCT sm.major_id)
        INTO v_major_ids
        FROM subject_majors sm
        WHERE sm.subject_id = v_class_record.subject_id;
        
        -- If no specific majors, allow all students
        IF v_major_ids IS NULL OR array_length(v_major_ids, 1) IS NULL THEN
            SELECT ARRAY_AGG(u.id ORDER BY RANDOM())
            INTO v_student_ids
            FROM users u
            JOIN user_roles ur ON u.id = ur.user_id
            WHERE ur.role_id = 4
            LIMIT 20;
        ELSE
            -- Get 20 students from matching majors
            SELECT ARRAY_AGG(u.id ORDER BY RANDOM())
            INTO v_student_ids
            FROM users u
            JOIN user_roles ur ON u.id = ur.user_id
            JOIN student_profiles sp ON u.id = sp.user_id
            WHERE ur.role_id = 4 
              AND sp.major_id = ANY(v_major_ids)
            LIMIT 20;
        END IF;
        
        -- Enroll students
        IF v_student_ids IS NOT NULL THEN
            FOREACH v_student_id IN ARRAY v_student_ids LOOP
                INSERT INTO enrollments (class_id, student_user_id, is_enrolled)
                VALUES (v_class_record.class_id, v_student_id, TRUE)
                ON CONFLICT DO NOTHING;
            END LOOP;
        END IF;
    END LOOP;
END $$;

-- =====================================================
-- SECTION 9: SLOTS (20 lecture slots + 1 exam slot per class)
-- Tổng slots: 180 classes * 20 lecture + 180 exam = 3,780 slots
-- CẬP NHẬT: Tự động lặp qua TẤT CẢ 180 classes
-- =====================================================

DO $$
DECLARE
    v_class_record RECORD;
    v_lecturer_id INT;
    v_supervisor_id INT; -- Thêm biến cho supervisor
    v_room_ids INT[];
    v_room_id INT;
    v_semester_start DATE;
    v_semester_end DATE;
    v_slot_date DATE;
    v_start_time TIMESTAMP;
    v_end_time TIMESTAMP;
    v_slot_id INT;
    v_day_of_week INT;
    v_slot_count INT := 0;
    v_week INT := 0;
    v_time_slot INT;
    v_time_slots TIME[] := ARRAY['07:30:00'::TIME, '10:00:00'::TIME, '12:50:00'::TIME, '15:20:00'::TIME];
    v_duration INTERVAL := '2 hours 20 minutes'::INTERVAL;
    i INT;
BEGIN
    -- Get room IDs (use all 20 rooms)
    SELECT ARRAY_AGG(id) INTO v_room_ids FROM rooms;
    
    FOR v_class_record IN (
        SELECT c.id as class_id, c.semester_id, s.start_date, s.end_date, s.code as sem_code
        FROM classes c
        JOIN semesters s ON c.semester_id = s.id
        ORDER BY s.start_date, c.id
    ) LOOP
        -- Get random lecturer for lecture slots
        SELECT u.id INTO v_lecturer_id
        FROM users u
        JOIN user_roles ur ON u.id = ur.user_id
        WHERE ur.role_id = 2
        ORDER BY RANDOM()
        LIMIT 1;

        -- Get random supervisor for exam slots
        SELECT u.id INTO v_supervisor_id
        FROM users u
        JOIN user_roles ur ON u.id = ur.user_id
        WHERE ur.role_id = 3
        ORDER BY RANDOM()
        LIMIT 1;
        
        v_semester_start := v_class_record.start_date;
        v_semester_end := v_class_record.end_date;
        v_slot_count := 0;
        v_week := 0;
        
        -- Create 20 lecture slots 
        WHILE v_slot_count < 20 LOOP
            -- Lặp qua các ngày trong tuần (Thứ Hai, Thứ Tư, Thứ Sáu)
            FOREACH v_day_of_week IN ARRAY ARRAY[1, 3, 5] LOOP 
                EXIT WHEN v_slot_count >= 20;
                
                v_slot_date := v_semester_start + (v_week * 7 + v_day_of_week) * INTERVAL '1 day';
                -- Giới hạn ngày tạo slots để chừa chỗ cho Exam (30 ngày cuối kỳ)
                EXIT WHEN v_slot_date > v_semester_end - INTERVAL '30 days'; 
                
                -- Cycle through 4 time slots
                v_time_slot := (v_slot_count % 4) + 1;
                v_start_time := v_slot_date + v_time_slots[v_time_slot];
                v_end_time := v_start_time + v_duration;
                
                -- Cycle through all available rooms
                v_room_id := v_room_ids[1 + (v_slot_count % array_length(v_room_ids, 1))];
                
                INSERT INTO slots (
                    class_id, semester_id, room_id, staff_user_id, slot_category,
                    start_time, end_time, title, session_status, is_active
                )
                VALUES (
                    v_class_record.class_id,
                    v_class_record.semester_id,
                    v_room_id,
                    v_lecturer_id,
                    'LECTURE',
                    v_start_time,
                    v_end_time,
                    'Lecture Session ' || (v_slot_count + 1),
                    CASE 
                        WHEN v_end_time < CURRENT_TIMESTAMP THEN 'STOPPED'
                        WHEN v_start_time <= CURRENT_TIMESTAMP AND v_end_time >= CURRENT_TIMESTAMP THEN 'RUNNING'
                        ELSE 'NOT_STARTED'
                    END,
                    TRUE
                )
                RETURNING id INTO v_slot_id;
                
                v_slot_count := v_slot_count + 1;
                
                -- Create attendance records ONLY for completed slots (end_time < now)
                IF v_end_time < CURRENT_TIMESTAMP THEN
                    INSERT INTO attendance_records (student_user_id, slot_id, status, method, recorded_at)
                    SELECT 
                        e.student_user_id,
                        v_slot_id,
                        CASE WHEN RANDOM() < 0.85 THEN 'present' ELSE 'absent' END,
                        'auto',
                        v_start_time + INTERVAL '15 minutes'
                    FROM enrollments e
                    WHERE e.class_id = v_class_record.class_id AND e.is_enrolled = TRUE
                    ON CONFLICT DO NOTHING;
                END IF;
            END LOOP;
            
            v_week := v_week + 1;
        END LOOP;
        
        -- Create exam slot
        v_slot_date := CASE 
            WHEN v_class_record.sem_code LIKE 'SP%' THEN 
                DATE_TRUNC('year', v_semester_end) + INTERVAL '3 months 15 days'
            ELSE 
                DATE_TRUNC('year', v_semester_end) + INTERVAL '11 months 15 days'
        END;
        
        v_start_time := v_slot_date + INTERVAL '9 hours';
        v_end_time := v_start_time + INTERVAL '2 hours';
        
        INSERT INTO slots (
            class_id, semester_id, room_id, staff_user_id, slot_category,
            start_time, end_time, title, session_status, is_active
        )
        VALUES (
            v_class_record.class_id,
            v_class_record.semester_id,
            v_room_ids[1 + (v_class_record.class_id % array_length(v_room_ids, 1))],
            v_supervisor_id, -- Use supervisor for exam slots
            'FINAL_EXAM',
            v_start_time,
            v_end_time,
            'Final Exam',
            CASE 
                WHEN v_end_time < CURRENT_TIMESTAMP THEN 'STOPPED'
                WHEN v_start_time <= CURRENT_TIMESTAMP AND v_end_time >= CURRENT_TIMESTAMP THEN 'RUNNING'
                ELSE 'NOT_STARTED'
            END,
            TRUE
        );
    END LOOP;
END $$;

-- =====================================================
-- SECTION 10: TEST SLOTS (ONGOING NOW)
-- Create 1 lecture slot + 1 exam slot happening RIGHT NOW
-- Both slots include student HE180314 (Nguyen Doan Hieu)
-- Current date: November 1, 2025 -> Fall 2025 (FA25)
-- =====================================================

DO $$
DECLARE
    v_test_class_id INT;
    v_test_semester_id INT;
    v_test_lecturer_id INT;
    v_test_room_id INT;
    v_test_student_id INT;
    v_lecture_slot_id INT;
    v_exam_slot_id INT;
    v_now TIMESTAMP := CURRENT_TIMESTAMP;
    v_start_time TIMESTAMP;
    v_end_time TIMESTAMP;
BEGIN
    -- Get test data IDs (FA25 - Fall 2025)
    SELECT c.id, c.semester_id INTO v_test_class_id, v_test_semester_id
    FROM classes c
    JOIN semesters s ON c.semester_id = s.id
    WHERE s.code = 'FA25' AND c.code LIKE 'FA25-PRF192%'
    LIMIT 1;
    
    SELECT u.id INTO v_test_lecturer_id
    FROM users u
    JOIN user_roles ur ON u.id = ur.user_id
    WHERE ur.role_id = 2
    LIMIT 1;
    
    SELECT id INTO v_test_room_id FROM rooms WHERE name = 'Room 101';
    
    SELECT u.id INTO v_test_student_id FROM users u WHERE u.username = 'HE180314';
    
    -- Ensure HE180314 is enrolled in the test class
    INSERT INTO enrollments (class_id, student_user_id, is_enrolled)
    VALUES (v_test_class_id, v_test_student_id, TRUE)
    ON CONFLICT DO NOTHING;
    
    -- Create ONGOING LECTURE SLOT (started 30 minutes ago, ends in 1h50m)
    v_start_time := v_now - INTERVAL '30 minutes';
    v_end_time := v_start_time + INTERVAL '2 hours 20 minutes';
    
    INSERT INTO slots (
        class_id, semester_id, room_id, staff_user_id, slot_category,
        start_time, end_time, title, session_status, is_active
    )
    VALUES (
        v_test_class_id,
        v_test_semester_id,
        v_test_room_id,
        v_test_lecturer_id,
        'LECTURE',
        v_start_time,
        v_end_time,
        'TEST LECTURE - ONGOING NOW (FA25)',
        'RUNNING',
        TRUE
    )
    ON CONFLICT DO NOTHING
    RETURNING id INTO v_lecture_slot_id;
    
    -- Create attendance records for ongoing lecture (status: not_yet for testing)
    INSERT INTO attendance_records (student_user_id, slot_id, status, method, recorded_at)
    SELECT 
        e.student_user_id,
        v_lecture_slot_id,
        'not_yet',
        'auto',
        v_start_time + INTERVAL '5 minutes'
    FROM enrollments e
    WHERE e.class_id = v_test_class_id AND e.is_enrolled = TRUE
    ON CONFLICT DO NOTHING;
    
    -- Create ONGOING EXAM SLOT (started 45 minutes ago, ends in 1h15m)
    v_start_time := v_now - INTERVAL '45 minutes';
    v_end_time := v_start_time + INTERVAL '2 hours';
    
    INSERT INTO slots (
        class_id, semester_id, room_id, staff_user_id, slot_category,
        start_time, end_time, title, session_status, is_active
    )
    VALUES (
        v_test_class_id,
        v_test_semester_id,
        v_test_room_id,
        v_test_lecturer_id,
        'FINAL_EXAM',
        v_start_time,
        v_end_time,
        'TEST FINAL EXAM - ONGOING NOW (FA25)',
        'RUNNING',
        TRUE
    )
    ON CONFLICT DO NOTHING
    RETURNING id INTO v_exam_slot_id;
    
    -- Create attendance records for ongoing exam (status: not_yet for testing)
    INSERT INTO attendance_records (student_user_id, slot_id, status, method, recorded_at)
    SELECT 
        e.student_user_id,
        v_exam_slot_id,
        'not_yet',
        'auto',
        v_start_time + INTERVAL '5 minutes'
    FROM enrollments e
    WHERE e.class_id = v_test_class_id AND e.is_enrolled = TRUE
    ON CONFLICT DO NOTHING;
    
    RAISE NOTICE 'Created test slots: Lecture ID=%, Exam ID=% (both ONGOING with HE180314 in FA25)', v_lecture_slot_id, v_exam_slot_id;
END $$;

-- =====================================================
-- SECTION 11: SYSTEM NOTIFICATIONS
-- =====================================================

INSERT INTO system_notifications (notification_type, title, content, is_active) VALUES
('identity_approved', 'Identity Verified', 'Your identity has been verified successfully.', TRUE),
('absence_warning_10', 'Absence Warning - 10%', 'You have reached 10% absence rate.', TRUE),
('absence_warning_20', 'Absence Warning - 20%', 'You have reached 20% absence rate.', TRUE),
('slot_cancelled', 'Slot Cancelled', 'A scheduled slot has been cancelled.', TRUE),
('slot_rescheduled', 'Slot Rescheduled', 'A slot has been rescheduled.', TRUE)
ON CONFLICT DO NOTHING;

-- =====================================================
-- VERIFICATION
-- =====================================================

SELECT 'Data seeding completed successfully!' as status;

SELECT 
    'users' as table_name, COUNT(*) as count FROM users
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
