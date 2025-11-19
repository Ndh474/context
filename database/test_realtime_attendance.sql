-- ============================================================================
-- TEST DATA SCRIPT: Real-time Attendance Testing
-- ============================================================================
-- Purpose: Create test environment for real-time attendance with 5 SE students
--
-- IDEMPOTENT: Safe to run multiple times
-- Strategy: Delete old test data first, then create fresh data
--
-- Prerequisites:
--   - Room 101 must exist
--   - Camera 101-A must exist in Room 101
--   - 5 SE students must exist (hieundhe180314, vuongvt181386, anhtd180577, tuanpa171369, baodn182129)
--   - Face embeddings must exist in V18__Seed_face_embeddings.sql migration
-- ============================================================================

-- ============================================================================
-- PHASE 1: CLEANUP - Remove old test data
-- ============================================================================

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

-- Create slot for SE999 class
-- Note: Uses existing Room 101 and Camera 101-A
-- Note: Timestamps are fixed for easy editing - change as needed for your test
INSERT INTO slots (start_time, end_time, class_id, semester_id, room_id, staff_user_id, slot_category, title, description, is_active, session_status, scan_count)
VALUES (
    '2025-11-06T23:00:00.977724+00:00',  -- Edit this timestamp as needed
    '2025-11-07T01:00:00.977724+00:00',  -- Edit this timestamp as needed
    (SELECT id FROM classes WHERE code = 'SE999'),
    (SELECT id FROM semesters WHERE code = 'FA25'),
    (SELECT id FROM rooms WHERE name = 'Room 101'),  -- Using existing Room 101
    (SELECT id FROM users WHERE username = 'lecturer01'),
    'LECTURE',
    'PRO192 - OOP Test Class',
    'Test class for 5 SE students - Real-time Attendance Testing',
    true,
    'NOT_STARTED',
    0
);

-- ============================================================================
-- PHASE 3: VERIFICATION QUERIES
-- ============================================================================

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

SELECT 'Slot created' as status,
       sl.id as slot_id,
       sl.start_time,
       sl.end_time,
       c.code as class,
       r.name as room,
       cam.name as camera,
       cam.rtsp_url as camera_url,
       sl.session_status
FROM slots sl
JOIN classes c ON sl.class_id = c.id
JOIN rooms r ON sl.room_id = r.id
LEFT JOIN cameras cam ON cam.room_id = r.id AND cam.is_active = true
WHERE c.code = 'SE999';

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
SELECT '============================================' as separator;
