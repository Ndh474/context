-- ============================================================================
-- TEST DATA SCRIPT: Real-time Attendance Testing
-- ============================================================================
-- Purpose: Create test environment for real-time attendance with 5 SE students
--          Includes both LECTURE slot (lecturer01) and FINAL_EXAM slot (supervisor01)
--
-- IDEMPOTENT: Safe to run multiple times
-- Strategy: Delete old test data first, then create fresh data
--
-- Prerequisites:
--   - Room 102 must exist with Camera 102-A (rtsp://hieund99:hieund99@192.168.0.122:9999/h264_ulaw.sdp)
--   - Room 103 must exist with Camera 103-A (rtsp://admin:admin@192.168.0.137:8554/live)
--   - 5 SE students must exist (hieundhe180314, vuongvt181386, anhtd180577, tuanpa171369, baodn182129)
--   - Face embeddings must exist in V18__Seed_face_embeddings.sql migration
--   - supervisor01 user must exist with SUPERVISOR role
--
-- Note: LECTURE (Room 102) and FINAL_EXAM (Room 103) can run at the same time since different rooms
-- ============================================================================

-- ============================================================================
-- PHASE 1: CLEANUP - Remove old test data
-- ============================================================================

-- Delete old exam slot participants (for test FINAL_EXAM slot)
DELETE FROM exam_slot_participants
WHERE exam_slot_subject_id IN (
    SELECT ess.id FROM exam_slot_subjects ess
    JOIN slots s ON ess.slot_id = s.id
    WHERE s.title = 'PRO192 - Final Exam Test'
      AND s.slot_category = 'FINAL_EXAM'
);

-- Delete old exam slot subjects
DELETE FROM exam_slot_subjects
WHERE slot_id IN (
    SELECT id FROM slots
    WHERE title = 'PRO192 - Final Exam Test'
      AND slot_category = 'FINAL_EXAM'
);

-- Delete old test FINAL_EXAM slot
DELETE FROM slots
WHERE title = 'PRO192 - Final Exam Test'
  AND slot_category = 'FINAL_EXAM';

-- Delete old slots for SE999 class
-- This will CASCADE delete attendance_records (slots FK has ON DELETE CASCADE to attendance_records)
DELETE FROM slots
WHERE class_id = (
    SELECT id FROM classes
    WHERE code = 'SE999'
      AND semester_id = (SELECT id FROM semesters WHERE code = 'FA25')
      AND subject_id = (SELECT id FROM subjects WHERE code = 'PRO192')
);

-- Delete old SE999 class
-- This will CASCADE delete enrollments (classes FK has ON DELETE CASCADE to enrollments)
-- Note: slots must be deleted first because slots.class_id FK does NOT have ON DELETE CASCADE
DELETE FROM classes
WHERE code = 'SE999'
  AND semester_id = (SELECT id FROM semesters WHERE code = 'FA25')
  AND subject_id = (SELECT id FROM subjects WHERE code = 'PRO192');

-- ============================================================================
-- PHASE 2: CREATE NEW TEST DATA
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

-- Create LECTURE slot for SE999 class
-- Note: Uses Room 102 with Camera 102-A
-- Note: Same time as FINAL_EXAM slot (different rooms = OK)
INSERT INTO slots (start_time, end_time, class_id, semester_id, room_id, staff_user_id, slot_category, title, description, is_active, session_status, scan_count)
VALUES (
    NOW() - INTERVAL '1 hour',  -- Same time as exam (different room)
    NOW() + INTERVAL '1 hour',  -- Same time as exam (different room)
    (SELECT id FROM classes WHERE code = 'SE999'),
    (SELECT id FROM semesters WHERE code = 'FA25'),
    (SELECT id FROM rooms WHERE name = 'Room 102'),  -- Room 102 with Camera 102-A
    (SELECT id FROM users WHERE username = 'lecturer01'),
    'LECTURE',
    'PRO192 - OOP Test Class',
    'Test class for 5 SE students - Real-time Attendance Testing (Room 102)',
    true,
    'NOT_STARTED',
    0
);

-- ============================================================================
-- PHASE 3: CREATE FINAL_EXAM SLOT (supervisor01)
-- ============================================================================

-- Create FINAL_EXAM slot (NO class_id - exam slots don't link to class directly)
-- Note: Uses Room 103 with Camera 103-A
-- Note: Same time as LECTURE slot (different rooms = OK)
INSERT INTO slots (start_time, end_time, class_id, semester_id, room_id, staff_user_id, slot_category, title, description, is_active, session_status, scan_count, exam_session_status, exam_scan_count)
VALUES (
    NOW() - INTERVAL '1 hour',  -- Same time as lecture (different room)
    NOW() + INTERVAL '1 hour',  -- Same time as lecture (different room)
    NULL,  -- IMPORTANT: FINAL_EXAM slots don't link to class
    (SELECT id FROM semesters WHERE code = 'FA25'),
    (SELECT id FROM rooms WHERE name = 'Room 103'),  -- Room 103 with Camera 103-A
    (SELECT id FROM users WHERE username = 'supervisor01'),
    'FINAL_EXAM',
    'PRO192 - Final Exam Test',
    'Test exam slot for 5 SE students - Real-time Attendance Testing (Room 103)',
    true,
    'NOT_STARTED',
    0,
    'NOT_STARTED',
    0
);

-- Create exam_slot_subjects entry to link the slot to PRO192 subject
INSERT INTO exam_slot_subjects (slot_id, subject_id, is_active, created_at)
VALUES (
    (SELECT id FROM slots WHERE title = 'PRO192 - Final Exam Test' AND slot_category = 'FINAL_EXAM'),
    (SELECT id FROM subjects WHERE code = 'PRO192'),
    true,
    NOW()
);

-- Add 5 SE students as exam participants
INSERT INTO exam_slot_participants (exam_slot_subject_id, student_user_id, is_enrolled, created_at, updated_at)
VALUES
    (
        (SELECT id FROM exam_slot_subjects WHERE slot_id = (SELECT id FROM slots WHERE title = 'PRO192 - Final Exam Test' AND slot_category = 'FINAL_EXAM') AND subject_id = (SELECT id FROM subjects WHERE code = 'PRO192')),
        (SELECT id FROM users WHERE username = 'hieundhe180314'),
        true, NOW(), NOW()
    ),
    (
        (SELECT id FROM exam_slot_subjects WHERE slot_id = (SELECT id FROM slots WHERE title = 'PRO192 - Final Exam Test' AND slot_category = 'FINAL_EXAM') AND subject_id = (SELECT id FROM subjects WHERE code = 'PRO192')),
        (SELECT id FROM users WHERE username = 'vuongvt181386'),
        true, NOW(), NOW()
    ),
    (
        (SELECT id FROM exam_slot_subjects WHERE slot_id = (SELECT id FROM slots WHERE title = 'PRO192 - Final Exam Test' AND slot_category = 'FINAL_EXAM') AND subject_id = (SELECT id FROM subjects WHERE code = 'PRO192')),
        (SELECT id FROM users WHERE username = 'anhtd180577'),
        true, NOW(), NOW()
    ),
    (
        (SELECT id FROM exam_slot_subjects WHERE slot_id = (SELECT id FROM slots WHERE title = 'PRO192 - Final Exam Test' AND slot_category = 'FINAL_EXAM') AND subject_id = (SELECT id FROM subjects WHERE code = 'PRO192')),
        (SELECT id FROM users WHERE username = 'tuanpa171369'),
        true, NOW(), NOW()
    ),
    (
        (SELECT id FROM exam_slot_subjects WHERE slot_id = (SELECT id FROM slots WHERE title = 'PRO192 - Final Exam Test' AND slot_category = 'FINAL_EXAM') AND subject_id = (SELECT id FROM subjects WHERE code = 'PRO192')),
        (SELECT id FROM users WHERE username = 'baodn182129'),
        true, NOW(), NOW()
    );

-- ============================================================================
-- PHASE 4: VERIFICATION QUERIES
-- ============================================================================

SELECT '========== LECTURE SLOT (lecturer01) ==========' as section;

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

SELECT 'LECTURE Slot created' as status,
       sl.id as slot_id,
       sl.title,
       sl.slot_category,
       sl.start_time,
       sl.end_time,
       c.code as class,
       r.name as room,
       u.username as staff,
       sl.session_status
FROM slots sl
JOIN classes c ON sl.class_id = c.id
JOIN rooms r ON sl.room_id = r.id
JOIN users u ON sl.staff_user_id = u.id
WHERE c.code = 'SE999';

SELECT '========== FINAL_EXAM SLOT (supervisor01) ==========' as section;

SELECT 'FINAL_EXAM Slot created' as status,
       sl.id as slot_id,
       sl.title,
       sl.slot_category,
       sl.start_time,
       sl.end_time,
       r.name as room,
       u.username as staff,
       sl.session_status,
       sl.exam_session_status
FROM slots sl
JOIN rooms r ON sl.room_id = r.id
JOIN users u ON sl.staff_user_id = u.id
WHERE sl.title = 'PRO192 - Final Exam Test' AND sl.slot_category = 'FINAL_EXAM';

SELECT 'Exam subjects assigned' as status,
       ess.id as exam_slot_subject_id,
       sub.code as subject_code,
       sub.name as subject_name
FROM exam_slot_subjects ess
JOIN subjects sub ON ess.subject_id = sub.id
WHERE ess.slot_id = (SELECT id FROM slots WHERE title = 'PRO192 - Final Exam Test' AND slot_category = 'FINAL_EXAM')
  AND ess.is_active = true;

SELECT 'Exam participants enrolled' as status,
       COUNT(*) as count,
       STRING_AGG(u.username, ', ') as students
FROM exam_slot_participants esp
JOIN users u ON esp.student_user_id = u.id
JOIN exam_slot_subjects ess ON esp.exam_slot_subject_id = ess.id
WHERE ess.slot_id = (SELECT id FROM slots WHERE title = 'PRO192 - Final Exam Test' AND slot_category = 'FINAL_EXAM')
  AND esp.is_enrolled = true;

SELECT '========== SHARED INFO ==========' as section;

SELECT 'Room 102 Camera info (LECTURE)' as status,
       r.name as room,
       cam.name as camera,
       cam.rtsp_url as camera_url
FROM rooms r
LEFT JOIN cameras cam ON cam.room_id = r.id AND cam.is_active = true
WHERE r.name = 'Room 102';

SELECT 'Room 103 Camera info (FINAL_EXAM)' as status,
       r.name as room,
       cam.name as camera,
       cam.rtsp_url as camera_url
FROM rooms r
LEFT JOIN cameras cam ON cam.room_id = r.id AND cam.is_active = true
WHERE r.name = 'Room 103';

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
SELECT 'TEST ENVIRONMENT READY!' as status;
SELECT 'LECTURE slot: Room 102 (Camera 102-A) - lecturer01' as slot1;
SELECT 'FINAL_EXAM slot: Room 103 (Camera 103-A) - supervisor01' as slot2;
SELECT 'Both slots run at SAME TIME (05:00-07:00 UTC) - different rooms!' as note;
SELECT '============================================' as separator;
