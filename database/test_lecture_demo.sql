-- ============================================================================
-- TEST DATA SCRIPT: LECTURE Demo (lecturer01)
-- ============================================================================
-- Purpose: Create LECTURE slot for demo with 5 SE students
--          Includes: yesterday slot, today slot (active), tomorrow slot
--
-- IDEMPOTENT: Safe to run multiple times
-- Strategy: Delete old test data (both LECTURE and EXAM), then create LECTURE data
--
-- Prerequisites:
--   - Room 102 must exist with Camera
--   - 5 SE students must exist (hieundhe180314, vuongvt181386, anhtd180577, tuanpa171369, baodn182129)
--   - Face embeddings must exist
--   - lecturer01 user must exist with LECTURER role
-- ============================================================================

-- ============================================================================
-- PHASE 1: CLEANUP - Remove ALL old test data (both LECTURE and EXAM)
-- ============================================================================

-- Delete old exam_attendance for FINAL_EXAM slots
DELETE FROM exam_attendance
WHERE slot_id IN (
    SELECT id FROM slots
    WHERE title LIKE 'PRO192 - Final Exam Test%'
      AND slot_category = 'FINAL_EXAM'
);

-- Delete old attendance_records for SE999 LECTURE slots
DELETE FROM attendance_records
WHERE slot_id IN (
    SELECT s.id FROM slots s
    JOIN classes c ON s.class_id = c.id
    WHERE c.code = 'SE999'
      AND c.semester_id = (SELECT id FROM semesters WHERE code = 'FA25')
      AND c.subject_id = (SELECT id FROM subjects WHERE code = 'PRO192')
);

-- Delete old exam slot participants
DELETE FROM exam_slot_participants
WHERE exam_slot_subject_id IN (
    SELECT ess.id FROM exam_slot_subjects ess
    JOIN slots s ON ess.slot_id = s.id
    WHERE s.title LIKE 'PRO192 - Final Exam Test%'
      AND s.slot_category = 'FINAL_EXAM'
);

-- Delete old exam slot subjects
DELETE FROM exam_slot_subjects
WHERE slot_id IN (
    SELECT id FROM slots
    WHERE title LIKE 'PRO192 - Final Exam Test%'
      AND slot_category = 'FINAL_EXAM'
);

-- Delete old FINAL_EXAM slots
DELETE FROM slots
WHERE title LIKE 'PRO192 - Final Exam Test%'
  AND slot_category = 'FINAL_EXAM';

-- Delete old slots for SE999 class (LECTURE slots)
DELETE FROM slots
WHERE class_id = (
    SELECT id FROM classes
    WHERE code = 'SE999'
      AND semester_id = (SELECT id FROM semesters WHERE code = 'FA25')
      AND subject_id = (SELECT id FROM subjects WHERE code = 'PRO192')
);

-- Delete old SE999 class (CASCADE deletes enrollments)
DELETE FROM classes
WHERE code = 'SE999'
  AND semester_id = (SELECT id FROM semesters WHERE code = 'FA25')
  AND subject_id = (SELECT id FROM subjects WHERE code = 'PRO192');

-- ============================================================================
-- PHASE 2: CREATE CLASS AND ENROLLMENTS
-- ============================================================================

-- Create new class SE999 for FA25 semester
INSERT INTO classes (subject_id, semester_id, is_active, code)
VALUES (
    (SELECT id FROM subjects WHERE code = 'PRO192'),
    (SELECT id FROM semesters WHERE code = 'FA25'),
    true,
    'SE999'
);

-- Enroll 5 SE students to SE999 class
INSERT INTO enrollments (student_user_id, class_id, is_enrolled)
VALUES
    ((SELECT id FROM users WHERE username = 'hieundhe180314'), (SELECT id FROM classes WHERE code = 'SE999'), true),
    ((SELECT id FROM users WHERE username = 'vuongvt181386'), (SELECT id FROM classes WHERE code = 'SE999'), true),
    ((SELECT id FROM users WHERE username = 'anhtd180577'), (SELECT id FROM classes WHERE code = 'SE999'), true),
    ((SELECT id FROM users WHERE username = 'tuanpa171369'), (SELECT id FROM classes WHERE code = 'SE999'), true),
    ((SELECT id FROM users WHERE username = 'baodn182129'), (SELECT id FROM classes WHERE code = 'SE999'), true);

-- ============================================================================
-- PHASE 3: CREATE LECTURE SLOTS (3 slots: yesterday, today, tomorrow)
-- ============================================================================

-- Slot 1: YESTERDAY (completed)
INSERT INTO slots (start_time, end_time, class_id, semester_id, room_id, staff_user_id, slot_category, title, description, is_active, session_status, scan_count)
VALUES (
    ((NOW() AT TIME ZONE 'Asia/Ho_Chi_Minh') - INTERVAL '1 day')::date + TIME '08:00',
    ((NOW() AT TIME ZONE 'Asia/Ho_Chi_Minh') - INTERVAL '1 day')::date + TIME '10:00',
    (SELECT id FROM classes WHERE code = 'SE999'),
    (SELECT id FROM semesters WHERE code = 'FA25'),
    (SELECT id FROM rooms WHERE name = 'Room 102'),
    (SELECT id FROM users WHERE username = 'lecturer01'),
    'LECTURE',
    'PRO192 - OOP Test Class (Yesterday)',
    'Test class - Yesterday slot (Room 102)',
    true,
    'NOT_STARTED',
    0
);

-- Slot 2: TODAY (active - for demo)
INSERT INTO slots (start_time, end_time, class_id, semester_id, room_id, staff_user_id, slot_category, title, description, is_active, session_status, scan_count)
VALUES (
    (NOW() AT TIME ZONE 'Asia/Ho_Chi_Minh') - INTERVAL '1 hour',
    (NOW() AT TIME ZONE 'Asia/Ho_Chi_Minh') + INTERVAL '1 hour',
    (SELECT id FROM classes WHERE code = 'SE999'),
    (SELECT id FROM semesters WHERE code = 'FA25'),
    (SELECT id FROM rooms WHERE name = 'Room 102'),
    (SELECT id FROM users WHERE username = 'lecturer01'),
    'LECTURE',
    'PRO192 - OOP Test Class',
    'Test class for 5 SE students - Real-time Attendance Demo (Room 102)',
    true,
    'NOT_STARTED',
    0
);

-- Slot 3: TOMORROW (upcoming)
INSERT INTO slots (start_time, end_time, class_id, semester_id, room_id, staff_user_id, slot_category, title, description, is_active, session_status, scan_count)
VALUES (
    ((NOW() AT TIME ZONE 'Asia/Ho_Chi_Minh') + INTERVAL '1 day')::date + TIME '08:00',
    ((NOW() AT TIME ZONE 'Asia/Ho_Chi_Minh') + INTERVAL '1 day')::date + TIME '10:00',
    (SELECT id FROM classes WHERE code = 'SE999'),
    (SELECT id FROM semesters WHERE code = 'FA25'),
    (SELECT id FROM rooms WHERE name = 'Room 102'),
    (SELECT id FROM users WHERE username = 'lecturer01'),
    'LECTURE',
    'PRO192 - OOP Test Class (Tomorrow)',
    'Test class - Tomorrow slot (Room 102)',
    true,
    'NOT_STARTED',
    0
);

-- ============================================================================
-- PHASE 4: CREATE ATTENDANCE RECORDS
-- ============================================================================

-- Yesterday slot: Random PRESENT/ABSENT (completed session)
INSERT INTO attendance_records (student_user_id, slot_id, status, method, recorded_at, created_at, updated_at)
SELECT 
    u.id,
    s.id,
    CASE WHEN random() > 0.5 THEN 'present' ELSE 'absent' END,
    'auto',
    s.start_time + INTERVAL '30 minutes',
    s.start_time + INTERVAL '30 minutes',
    s.start_time + INTERVAL '30 minutes'
FROM users u
CROSS JOIN (
    SELECT id, start_time FROM slots 
    WHERE title = 'PRO192 - OOP Test Class (Yesterday)' 
      AND slot_category = 'LECTURE'
) s
WHERE u.username IN ('hieundhe180314', 'vuongvt181386', 'anhtd180577', 'tuanpa171369', 'baodn182129');

-- Update yesterday slot to STOPPED (completed)
UPDATE slots 
SET session_status = 'STOPPED'
WHERE title = 'PRO192 - OOP Test Class (Yesterday)' 
  AND slot_category = 'LECTURE';

-- Tomorrow slot: All NOT_YET (upcoming session)
INSERT INTO attendance_records (student_user_id, slot_id, status, method, recorded_at, created_at, updated_at)
SELECT 
    u.id,
    s.id,
    'not_yet',
    'auto',
    NOW(),
    NOW(),
    NOW()
FROM users u
CROSS JOIN (
    SELECT id FROM slots 
    WHERE title = 'PRO192 - OOP Test Class (Tomorrow)' 
      AND slot_category = 'LECTURE'
) s
WHERE u.username IN ('hieundhe180314', 'vuongvt181386', 'anhtd180577', 'tuanpa171369', 'baodn182129');

-- ============================================================================
-- PHASE 5: VERIFICATION QUERIES
-- ============================================================================

SELECT '========== LECTURE DEMO (lecturer01) ==========' as section;

SELECT 'Class created' as status,
       c.id as class_id,
       c.code as class_code,
       s.code as semester,
       sub.code as subject,
       sub.name as subject_name
FROM classes c
JOIN semesters s ON c.semester_id = s.id
JOIN subjects sub ON c.subject_id = sub.id
WHERE c.code = 'SE999';

SELECT 'Students enrolled' as status,
       COUNT(*) as count,
       STRING_AGG(u.username, ', ') as students
FROM enrollments e
JOIN users u ON e.student_user_id = u.id
WHERE class_id = (SELECT id FROM classes WHERE code = 'SE999');

SELECT 'LECTURE Slots created' as status,
       sl.id as slot_id,
       sl.title,
       sl.start_time,
       sl.end_time,
       r.name as room,
       u.username as staff,
       sl.session_status
FROM slots sl
JOIN classes c ON sl.class_id = c.id
JOIN rooms r ON sl.room_id = r.id
JOIN users u ON sl.staff_user_id = u.id
WHERE c.code = 'SE999'
ORDER BY sl.start_time;

SELECT 'Yesterday attendance (random)' as status,
       u.username,
       ar.status,
       ar.method
FROM attendance_records ar
JOIN users u ON ar.student_user_id = u.id
JOIN slots s ON ar.slot_id = s.id
WHERE s.title = 'PRO192 - OOP Test Class (Yesterday)'
ORDER BY u.username;

SELECT 'Tomorrow attendance (all not_yet)' as status,
       u.username,
       ar.status,
       ar.method
FROM attendance_records ar
JOIN users u ON ar.student_user_id = u.id
JOIN slots s ON ar.slot_id = s.id
WHERE s.title = 'PRO192 - OOP Test Class (Tomorrow)'
ORDER BY u.username;

SELECT 'Room 102 Camera info' as status,
       r.name as room,
       cam.name as camera,
       cam.rtsp_url as camera_url
FROM rooms r
LEFT JOIN cameras cam ON cam.room_id = r.id AND cam.is_active = true
WHERE r.name = 'Room 102';

SELECT 'Face embeddings available' as status,
       COUNT(*) as count,
       STRING_AGG(u.username, ', ') as students_with_embeddings
FROM face_embeddings fe
JOIN users u ON fe.student_user_id = u.id
WHERE fe.student_user_id IN (
    SELECT id FROM users
    WHERE username IN ('hieundhe180314', 'vuongvt181386', 'anhtd180577', 'tuanpa171369', 'baodn182129')
) AND fe.is_active = true;

SELECT '============================================' as separator;
SELECT 'LECTURE DEMO READY!' as status;
SELECT 'Room: Room 102' as room;
SELECT 'Staff: lecturer01' as staff;
SELECT '3 slots: Yesterday, Today (active), Tomorrow' as slots;
SELECT '============================================' as separator;
