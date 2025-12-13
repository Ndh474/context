-- ============================================================================
-- TEST DATA SCRIPT: FINAL_EXAM Demo (supervisor01)
-- ============================================================================
-- Purpose: Create FINAL_EXAM slot for demo with 5 SE students
--          Includes: yesterday slot, today slot (active), tomorrow slot
--
-- IDEMPOTENT: Safe to run multiple times
-- Strategy: Delete old test data (both LECTURE and EXAM), then create EXAM data
--
-- Prerequisites:
--   - Room 102 must exist with Camera
--   - 6 SE students must exist (hieundhe180314, vuongvt181386, anhtd180577, tuanpa171369, baodn182129, nghiadt181793)
--   - Face embeddings must exist
--   - supervisor01 user must exist with SUPERVISOR role
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
-- PHASE 2: CREATE FINAL_EXAM SLOTS (3 slots: yesterday, today, tomorrow)
-- ============================================================================

-- Slot 1: YESTERDAY (completed)
INSERT INTO slots (start_time, end_time, class_id, semester_id, room_id, staff_user_id, slot_category, title, description, is_active, session_status, scan_count, exam_session_status, exam_scan_count)
VALUES (
    ((NOW() AT TIME ZONE 'Asia/Ho_Chi_Minh') - INTERVAL '1 day')::date + TIME '08:00',
    ((NOW() AT TIME ZONE 'Asia/Ho_Chi_Minh') - INTERVAL '1 day')::date + TIME '10:00',
    NULL,
    (SELECT id FROM semesters WHERE code = 'FA25'),
    (SELECT id FROM rooms WHERE name = 'Room 102'),
    (SELECT id FROM users WHERE username = 'supervisor01'),
    'FINAL_EXAM',
    'PRO192 - Final Exam Test (Yesterday)',
    'Test exam - Yesterday slot (Room 102)',
    true,
    'NOT_STARTED',
    0,
    'NOT_STARTED',
    0
);

-- Slot 2: TODAY (active - for demo)
INSERT INTO slots (start_time, end_time, class_id, semester_id, room_id, staff_user_id, slot_category, title, description, is_active, session_status, scan_count, exam_session_status, exam_scan_count)
VALUES (
    (NOW() AT TIME ZONE 'Asia/Ho_Chi_Minh') - INTERVAL '1 hour',
    (NOW() AT TIME ZONE 'Asia/Ho_Chi_Minh') + INTERVAL '1 hour',
    NULL,
    (SELECT id FROM semesters WHERE code = 'FA25'),
    (SELECT id FROM rooms WHERE name = 'Room 102'),
    (SELECT id FROM users WHERE username = 'supervisor01'),
    'FINAL_EXAM',
    'PRO192 - Final Exam Test',
    'Test exam for 5 SE students - Real-time Attendance Demo (Room 102)',
    true,
    'NOT_STARTED',
    0,
    'NOT_STARTED',
    0
);

-- Slot 3: TOMORROW (upcoming)
INSERT INTO slots (start_time, end_time, class_id, semester_id, room_id, staff_user_id, slot_category, title, description, is_active, session_status, scan_count, exam_session_status, exam_scan_count)
VALUES (
    ((NOW() AT TIME ZONE 'Asia/Ho_Chi_Minh') + INTERVAL '1 day')::date + TIME '08:00',
    ((NOW() AT TIME ZONE 'Asia/Ho_Chi_Minh') + INTERVAL '1 day')::date + TIME '10:00',
    NULL,
    (SELECT id FROM semesters WHERE code = 'FA25'),
    (SELECT id FROM rooms WHERE name = 'Room 102'),
    (SELECT id FROM users WHERE username = 'supervisor01'),
    'FINAL_EXAM',
    'PRO192 - Final Exam Test (Tomorrow)',
    'Test exam - Tomorrow slot (Room 102)',
    true,
    'NOT_STARTED',
    0,
    'NOT_STARTED',
    0
);

-- ============================================================================
-- PHASE 3: CREATE EXAM SLOT SUBJECTS AND PARTICIPANTS
-- ============================================================================

-- Create exam_slot_subjects entries for all 3 slots
INSERT INTO exam_slot_subjects (slot_id, subject_id, is_active, created_at)
SELECT s.id, (SELECT id FROM subjects WHERE code = 'PRO192'), true, NOW()
FROM slots s
WHERE s.title LIKE 'PRO192 - Final Exam Test%'
  AND s.slot_category = 'FINAL_EXAM';

-- Add 5 SE students as exam participants for all 3 slots
INSERT INTO exam_slot_participants (exam_slot_subject_id, student_user_id, is_enrolled, created_at, updated_at)
SELECT 
    ess.id,
    u.id,
    true,
    NOW(),
    NOW()
FROM exam_slot_subjects ess
JOIN slots s ON ess.slot_id = s.id
CROSS JOIN (
    SELECT id FROM users WHERE username IN ('hieundhe180314', 'vuongvt181386', 'anhtd180577', 'tuanpa171369', 'baodn182129', 'nghiadt181793')
) u
WHERE s.title LIKE 'PRO192 - Final Exam Test%'
  AND s.slot_category = 'FINAL_EXAM';

-- ============================================================================
-- PHASE 4: CREATE EXAM ATTENDANCE RECORDS
-- ============================================================================

-- Yesterday slot: Random PRESENT/ABSENT (completed session)
INSERT INTO exam_attendance (student_user_id, slot_id, status, method, recorded_at, created_at, updated_at)
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
    WHERE title = 'PRO192 - Final Exam Test (Yesterday)' 
      AND slot_category = 'FINAL_EXAM'
) s
WHERE u.username IN ('hieundhe180314', 'vuongvt181386', 'anhtd180577', 'tuanpa171369', 'baodn182129', 'nghiadt181793');

-- Update yesterday slot to STOPPED (completed)
UPDATE slots 
SET session_status = 'STOPPED', exam_session_status = 'STOPPED'
WHERE title = 'PRO192 - Final Exam Test (Yesterday)' 
  AND slot_category = 'FINAL_EXAM';

-- Tomorrow slot: All NOT_YET (upcoming session)
INSERT INTO exam_attendance (student_user_id, slot_id, status, method, recorded_at, created_at, updated_at)
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
    WHERE title = 'PRO192 - Final Exam Test (Tomorrow)' 
      AND slot_category = 'FINAL_EXAM'
) s
WHERE u.username IN ('hieundhe180314', 'vuongvt181386', 'anhtd180577', 'tuanpa171369', 'baodn182129', 'nghiadt181793');

-- ============================================================================
-- PHASE 5: VERIFICATION QUERIES
-- ============================================================================

SELECT '========== FINAL_EXAM DEMO (supervisor01) ==========' as section;

SELECT 'FINAL_EXAM Slots created' as status,
       sl.id as slot_id,
       sl.title,
       sl.start_time,
       sl.end_time,
       r.name as room,
       u.username as staff,
       sl.exam_session_status
FROM slots sl
JOIN rooms r ON sl.room_id = r.id
JOIN users u ON sl.staff_user_id = u.id
WHERE sl.title LIKE 'PRO192 - Final Exam Test%'
  AND sl.slot_category = 'FINAL_EXAM'
ORDER BY sl.start_time;

SELECT 'Exam subjects assigned' as status,
       ess.id as exam_slot_subject_id,
       s.title as slot_title,
       sub.code as subject_code
FROM exam_slot_subjects ess
JOIN slots s ON ess.slot_id = s.id
JOIN subjects sub ON ess.subject_id = sub.id
WHERE s.title LIKE 'PRO192 - Final Exam Test%'
  AND s.slot_category = 'FINAL_EXAM'
  AND ess.is_active = true
ORDER BY s.start_time;

SELECT 'Exam participants per slot' as status,
       s.title as slot_title,
       COUNT(esp.id) as participant_count
FROM slots s
JOIN exam_slot_subjects ess ON ess.slot_id = s.id
JOIN exam_slot_participants esp ON esp.exam_slot_subject_id = ess.id
WHERE s.title LIKE 'PRO192 - Final Exam Test%'
  AND s.slot_category = 'FINAL_EXAM'
  AND esp.is_enrolled = true
GROUP BY s.id, s.title
ORDER BY s.start_time;

SELECT 'Yesterday exam attendance (random)' as status,
       u.username,
       ea.status,
       ea.method
FROM exam_attendance ea
JOIN users u ON ea.student_user_id = u.id
JOIN slots s ON ea.slot_id = s.id
WHERE s.title = 'PRO192 - Final Exam Test (Yesterday)'
ORDER BY u.username;

SELECT 'Tomorrow exam attendance (all not_yet)' as status,
       u.username,
       ea.status,
       ea.method
FROM exam_attendance ea
JOIN users u ON ea.student_user_id = u.id
JOIN slots s ON ea.slot_id = s.id
WHERE s.title = 'PRO192 - Final Exam Test (Tomorrow)'
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
    WHERE username IN ('hieundhe180314', 'vuongvt181386', 'anhtd180577', 'tuanpa171369', 'baodn182129', 'nghiadt181793')
) AND fe.is_active = true;

SELECT '============================================' as separator;
SELECT 'FINAL_EXAM DEMO READY!' as status;
SELECT 'Room: Room 102' as room;
SELECT 'Staff: supervisor01' as staff;
SELECT '3 slots: Yesterday, Today (active), Tomorrow' as slots;
SELECT '============================================' as separator;
