-- ============================================
-- Import Test Data for FA25 Semester
-- ============================================
-- This script imports all test data including:
-- - 1 Room (Room Test 99)
-- - 2 Cameras
-- - 2 Classes (PRF192, SWE201)
-- - 10 Enrollments (5 students x 2 classes)
-- - 40 Lecture Slots (10 weeks)
-- - 1 Final Exam Slot
-- - 10 Exam Participants
-- ============================================

BEGIN;

-- ============================================
-- STEP 1: Insert Room
-- ============================================
INSERT INTO rooms (name, location, is_active, created_at, updated_at)
VALUES ('Room Test 99', 'Test Location', true, NOW(), NOW());

-- Get room_id for later use
DO $$
DECLARE
    v_room_id INTEGER;
    v_semester_id INTEGER := 18;  -- FA25
    v_subject_prf192_id INTEGER := 1;  -- PRF192
    v_subject_swe201_id INTEGER := 3;  -- SWE201
    v_lecturer_id INTEGER := 2;  -- lecturer01
    v_supervisor_id INTEGER := 17;  -- supervisor01
    v_class_prf192_id INTEGER;
    v_class_swe201_id INTEGER;
    v_exam_slot_id INTEGER;
    v_exam_subject_prf192_id INTEGER;
    v_exam_subject_swe201_id INTEGER;
BEGIN

    -- Get the room ID we just inserted
    SELECT id INTO v_room_id FROM rooms WHERE name = 'Room Test 99';

    -- ============================================
    -- STEP 2: Insert Cameras
    -- ============================================
    INSERT INTO cameras (name, rtsp_url, room_id, is_active, created_at, updated_at)
    VALUES
        ('Camera Test-A', 'rtsp://admin:admin123@192.168.1.130:554/stream1', v_room_id, true, NOW(), NOW()),
        ('Camera Test-B', 'rtsp://admin:admin123@192.168.1.131:554/stream1', v_room_id, true, NOW(), NOW());

    -- ============================================
    -- STEP 3: Insert Classes
    -- ============================================
    INSERT INTO classes (code, subject_id, semester_id, is_active, created_at, updated_at)
    VALUES
        ('SE-PRF192-FA25', v_subject_prf192_id, v_semester_id, true, NOW(), NOW()),
        ('SE-SWE201-FA25', v_subject_swe201_id, v_semester_id, true, NOW(), NOW())
    RETURNING id INTO v_class_prf192_id;

    -- Get the second class ID
    SELECT id INTO v_class_swe201_id FROM classes WHERE code = 'SE-SWE201-FA25';

    -- ============================================
    -- STEP 4: Insert Enrollments
    -- ============================================
    -- 5 students enrolling in PRF192 class
    INSERT INTO enrollments (class_id, student_id, enrollment_date)
    VALUES
        (v_class_prf192_id, 37, CURRENT_DATE),  -- HE180314
        (v_class_prf192_id, 38, CURRENT_DATE),  -- HE181386
        (v_class_prf192_id, 39, CURRENT_DATE),  -- HE180577
        (v_class_prf192_id, 40, CURRENT_DATE),  -- HE171369
        (v_class_prf192_id, 41, CURRENT_DATE);  -- HE182129

    -- 5 students enrolling in SWE201 class
    INSERT INTO enrollments (class_id, student_id, enrollment_date)
    VALUES
        (v_class_swe201_id, 37, CURRENT_DATE),  -- HE180314
        (v_class_swe201_id, 38, CURRENT_DATE),  -- HE181386
        (v_class_swe201_id, 39, CURRENT_DATE),  -- HE180577
        (v_class_swe201_id, 40, CURRENT_DATE),  -- HE171369
        (v_class_swe201_id, 41, CURRENT_DATE);  -- HE182129

    -- ============================================
    -- STEP 5: Insert Lecture Slots (40 slots)
    -- ============================================
    -- Week 1: 2025-09-01 (Monday), 2025-09-03 (Wednesday)
    INSERT INTO slots (title, start_time, end_time, slot_category, class_id, semester_id, room_id, assigned_staff_id, is_active, created_at, updated_at)
    VALUES
        -- PRF192 Week 1
        ('PRF192 Lecture Week 1', '2025-09-01 07:30:00', '2025-09-01 09:50:00', 'LECTURE', v_class_prf192_id, v_semester_id, v_room_id, v_lecturer_id, true, NOW(), NOW()),
        ('PRF192 Lecture Week 1', '2025-09-03 09:50:00', '2025-09-03 12:20:00', 'LECTURE', v_class_prf192_id, v_semester_id, v_room_id, v_lecturer_id, true, NOW(), NOW()),
        -- SWE201 Week 1
        ('SWE201 Lecture Week 1', '2025-09-01 09:50:00', '2025-09-01 12:20:00', 'LECTURE', v_class_swe201_id, v_semester_id, v_room_id, v_lecturer_id, true, NOW(), NOW()),
        ('SWE201 Lecture Week 1', '2025-09-03 07:30:00', '2025-09-03 09:50:00', 'LECTURE', v_class_swe201_id, v_semester_id, v_room_id, v_lecturer_id, true, NOW(), NOW()),

        -- Week 2: 2025-09-08, 2025-09-10
        ('PRF192 Lecture Week 2', '2025-09-08 07:30:00', '2025-09-08 09:50:00', 'LECTURE', v_class_prf192_id, v_semester_id, v_room_id, v_lecturer_id, true, NOW(), NOW()),
        ('PRF192 Lecture Week 2', '2025-09-10 09:50:00', '2025-09-10 12:20:00', 'LECTURE', v_class_prf192_id, v_semester_id, v_room_id, v_lecturer_id, true, NOW(), NOW()),
        ('SWE201 Lecture Week 2', '2025-09-08 09:50:00', '2025-09-08 12:20:00', 'LECTURE', v_class_swe201_id, v_semester_id, v_room_id, v_lecturer_id, true, NOW(), NOW()),
        ('SWE201 Lecture Week 2', '2025-09-10 07:30:00', '2025-09-10 09:50:00', 'LECTURE', v_class_swe201_id, v_semester_id, v_room_id, v_lecturer_id, true, NOW(), NOW()),

        -- Week 3: 2025-09-15, 2025-09-17
        ('PRF192 Lecture Week 3', '2025-09-15 07:30:00', '2025-09-15 09:50:00', 'LECTURE', v_class_prf192_id, v_semester_id, v_room_id, v_lecturer_id, true, NOW(), NOW()),
        ('PRF192 Lecture Week 3', '2025-09-17 09:50:00', '2025-09-17 12:20:00', 'LECTURE', v_class_prf192_id, v_semester_id, v_room_id, v_lecturer_id, true, NOW(), NOW()),
        ('SWE201 Lecture Week 3', '2025-09-15 09:50:00', '2025-09-15 12:20:00', 'LECTURE', v_class_swe201_id, v_semester_id, v_room_id, v_lecturer_id, true, NOW(), NOW()),
        ('SWE201 Lecture Week 3', '2025-09-17 07:30:00', '2025-09-17 09:50:00', 'LECTURE', v_class_swe201_id, v_semester_id, v_room_id, v_lecturer_id, true, NOW(), NOW()),

        -- Week 4: 2025-09-22, 2025-09-24
        ('PRF192 Lecture Week 4', '2025-09-22 07:30:00', '2025-09-22 09:50:00', 'LECTURE', v_class_prf192_id, v_semester_id, v_room_id, v_lecturer_id, true, NOW(), NOW()),
        ('PRF192 Lecture Week 4', '2025-09-24 09:50:00', '2025-09-24 12:20:00', 'LECTURE', v_class_prf192_id, v_semester_id, v_room_id, v_lecturer_id, true, NOW(), NOW()),
        ('SWE201 Lecture Week 4', '2025-09-22 09:50:00', '2025-09-22 12:20:00', 'LECTURE', v_class_swe201_id, v_semester_id, v_room_id, v_lecturer_id, true, NOW(), NOW()),
        ('SWE201 Lecture Week 4', '2025-09-24 07:30:00', '2025-09-24 09:50:00', 'LECTURE', v_class_swe201_id, v_semester_id, v_room_id, v_lecturer_id, true, NOW(), NOW()),

        -- Week 5: 2025-09-29, 2025-10-01
        ('PRF192 Lecture Week 5', '2025-09-29 07:30:00', '2025-09-29 09:50:00', 'LECTURE', v_class_prf192_id, v_semester_id, v_room_id, v_lecturer_id, true, NOW(), NOW()),
        ('PRF192 Lecture Week 5', '2025-10-01 09:50:00', '2025-10-01 12:20:00', 'LECTURE', v_class_prf192_id, v_semester_id, v_room_id, v_lecturer_id, true, NOW(), NOW()),
        ('SWE201 Lecture Week 5', '2025-09-29 09:50:00', '2025-09-29 12:20:00', 'LECTURE', v_class_swe201_id, v_semester_id, v_room_id, v_lecturer_id, true, NOW(), NOW()),
        ('SWE201 Lecture Week 5', '2025-10-01 07:30:00', '2025-10-01 09:50:00', 'LECTURE', v_class_swe201_id, v_semester_id, v_room_id, v_lecturer_id, true, NOW(), NOW()),

        -- Week 6: 2025-10-06, 2025-10-08
        ('PRF192 Lecture Week 6', '2025-10-06 07:30:00', '2025-10-06 09:50:00', 'LECTURE', v_class_prf192_id, v_semester_id, v_room_id, v_lecturer_id, true, NOW(), NOW()),
        ('PRF192 Lecture Week 6', '2025-10-08 09:50:00', '2025-10-08 12:20:00', 'LECTURE', v_class_prf192_id, v_semester_id, v_room_id, v_lecturer_id, true, NOW(), NOW()),
        ('SWE201 Lecture Week 6', '2025-10-06 09:50:00', '2025-10-06 12:20:00', 'LECTURE', v_class_swe201_id, v_semester_id, v_room_id, v_lecturer_id, true, NOW(), NOW()),
        ('SWE201 Lecture Week 6', '2025-10-08 07:30:00', '2025-10-08 09:50:00', 'LECTURE', v_class_swe201_id, v_semester_id, v_room_id, v_lecturer_id, true, NOW(), NOW()),

        -- Week 7: 2025-10-13, 2025-10-15
        ('PRF192 Lecture Week 7', '2025-10-13 07:30:00', '2025-10-13 09:50:00', 'LECTURE', v_class_prf192_id, v_semester_id, v_room_id, v_lecturer_id, true, NOW(), NOW()),
        ('PRF192 Lecture Week 7', '2025-10-15 09:50:00', '2025-10-15 12:20:00', 'LECTURE', v_class_prf192_id, v_semester_id, v_room_id, v_lecturer_id, true, NOW(), NOW()),
        ('SWE201 Lecture Week 7', '2025-10-13 09:50:00', '2025-10-13 12:20:00', 'LECTURE', v_class_swe201_id, v_semester_id, v_room_id, v_lecturer_id, true, NOW(), NOW()),
        ('SWE201 Lecture Week 7', '2025-10-15 07:30:00', '2025-10-15 09:50:00', 'LECTURE', v_class_swe201_id, v_semester_id, v_room_id, v_lecturer_id, true, NOW(), NOW()),

        -- Week 8: 2025-10-20, 2025-10-22
        ('PRF192 Lecture Week 8', '2025-10-20 07:30:00', '2025-10-20 09:50:00', 'LECTURE', v_class_prf192_id, v_semester_id, v_room_id, v_lecturer_id, true, NOW(), NOW()),
        ('PRF192 Lecture Week 8', '2025-10-22 09:50:00', '2025-10-22 12:20:00', 'LECTURE', v_class_prf192_id, v_semester_id, v_room_id, v_lecturer_id, true, NOW(), NOW()),
        ('SWE201 Lecture Week 8', '2025-10-20 09:50:00', '2025-10-20 12:20:00', 'LECTURE', v_class_swe201_id, v_semester_id, v_room_id, v_lecturer_id, true, NOW(), NOW()),
        ('SWE201 Lecture Week 8', '2025-10-22 07:30:00', '2025-10-22 09:50:00', 'LECTURE', v_class_swe201_id, v_semester_id, v_room_id, v_lecturer_id, true, NOW(), NOW()),

        -- Week 9: 2025-10-27, 2025-10-29
        ('PRF192 Lecture Week 9', '2025-10-27 07:30:00', '2025-10-27 09:50:00', 'LECTURE', v_class_prf192_id, v_semester_id, v_room_id, v_lecturer_id, true, NOW(), NOW()),
        ('PRF192 Lecture Week 9', '2025-10-29 09:50:00', '2025-10-29 12:20:00', 'LECTURE', v_class_prf192_id, v_semester_id, v_room_id, v_lecturer_id, true, NOW(), NOW()),
        ('SWE201 Lecture Week 9', '2025-10-27 09:50:00', '2025-10-27 12:20:00', 'LECTURE', v_class_swe201_id, v_semester_id, v_room_id, v_lecturer_id, true, NOW(), NOW()),
        ('SWE201 Lecture Week 9', '2025-10-29 07:30:00', '2025-10-29 09:50:00', 'LECTURE', v_class_swe201_id, v_semester_id, v_room_id, v_lecturer_id, true, NOW(), NOW()),

        -- Week 10: 2025-11-03, 2025-11-05
        ('PRF192 Lecture Week 10', '2025-11-03 07:30:00', '2025-11-03 09:50:00', 'LECTURE', v_class_prf192_id, v_semester_id, v_room_id, v_lecturer_id, true, NOW(), NOW()),
        ('PRF192 Lecture Week 10', '2025-11-05 09:50:00', '2025-11-05 12:20:00', 'LECTURE', v_class_prf192_id, v_semester_id, v_room_id, v_lecturer_id, true, NOW(), NOW()),
        ('SWE201 Lecture Week 10', '2025-11-03 09:50:00', '2025-11-03 12:20:00', 'LECTURE', v_class_swe201_id, v_semester_id, v_room_id, v_lecturer_id, true, NOW(), NOW()),
        ('SWE201 Lecture Week 10', '2025-11-05 07:30:00', '2025-11-05 09:50:00', 'LECTURE', v_class_swe201_id, v_semester_id, v_room_id, v_lecturer_id, true, NOW(), NOW());

    -- ============================================
    -- STEP 6: Insert Final Exam Slot
    -- ============================================
    INSERT INTO slots (title, start_time, end_time, slot_category, class_id, semester_id, room_id, assigned_staff_id, is_active, created_at, updated_at)
    VALUES ('Final Exam SE-FA25', '2025-11-10 09:00:00', '2025-11-10 11:30:00', 'FINAL_EXAM', NULL, v_semester_id, v_room_id, v_supervisor_id, true, NOW(), NOW())
    RETURNING id INTO v_exam_slot_id;

    -- ============================================
    -- STEP 7: Link Exam Slot with Subjects
    -- ============================================
    INSERT INTO exam_slot_subjects (exam_slot_id, subject_id, is_active, created_at)
    VALUES
        (v_exam_slot_id, v_subject_prf192_id, true, NOW()),
        (v_exam_slot_id, v_subject_swe201_id, true, NOW())
    RETURNING id INTO v_exam_subject_prf192_id;

    -- Get the second exam subject ID
    SELECT id INTO v_exam_subject_swe201_id
    FROM exam_slot_subjects
    WHERE exam_slot_id = v_exam_slot_id AND subject_id = v_subject_swe201_id;

    -- ============================================
    -- STEP 8: Insert Exam Participants
    -- ============================================
    -- 5 students taking both PRF192 and SWE201 exams
    INSERT INTO exam_slot_participants (exam_slot_subject_id, student_id)
    VALUES
        -- PRF192 exam participants
        (v_exam_subject_prf192_id, 37),  -- HE180314
        (v_exam_subject_prf192_id, 38),  -- HE181386
        (v_exam_subject_prf192_id, 39),  -- HE180577
        (v_exam_subject_prf192_id, 40),  -- HE171369
        (v_exam_subject_prf192_id, 41),  -- HE182129
        -- SWE201 exam participants
        (v_exam_subject_swe201_id, 37),  -- HE180314
        (v_exam_subject_swe201_id, 38),  -- HE181386
        (v_exam_subject_swe201_id, 39),  -- HE180577
        (v_exam_subject_swe201_id, 40),  -- HE171369
        (v_exam_subject_swe201_id, 41);  -- HE182129

    RAISE NOTICE 'Import completed successfully!';
    RAISE NOTICE 'Room ID: %', v_room_id;
    RAISE NOTICE 'Class PRF192 ID: %', v_class_prf192_id;
    RAISE NOTICE 'Class SWE201 ID: %', v_class_swe201_id;
    RAISE NOTICE 'Exam Slot ID: %', v_exam_slot_id;

END $$;

COMMIT;

-- ============================================
-- VERIFICATION QUERIES
-- ============================================
SELECT 'Import Summary:' AS info;
SELECT
    (SELECT COUNT(*) FROM rooms WHERE name = 'Room Test 99') AS rooms_created,
    (SELECT COUNT(*) FROM cameras WHERE name LIKE 'Camera Test-%') AS cameras_created,
    (SELECT COUNT(*) FROM classes WHERE code LIKE 'SE-%-FA25') AS classes_created,
    (SELECT COUNT(*) FROM enrollments WHERE class_id IN (SELECT id FROM classes WHERE code LIKE 'SE-%-FA25')) AS enrollments_created,
    (SELECT COUNT(*) FROM slots WHERE class_id IN (SELECT id FROM classes WHERE code LIKE 'SE-%-FA25')) AS lecture_slots_created,
    (SELECT COUNT(*) FROM slots WHERE title = 'Final Exam SE-FA25') AS exam_slots_created,
    (SELECT COUNT(*) FROM exam_slot_participants WHERE exam_slot_subject_id IN (
        SELECT id FROM exam_slot_subjects WHERE exam_slot_id IN (
            SELECT id FROM slots WHERE title = 'Final Exam SE-FA25'
        )
    )) AS exam_participants_created;

-- ============================================
-- CLEANUP SECTION (commented by default)
-- ============================================
-- Uncomment and run this section to delete all test data
-- WARNING: This will delete all data created by this script!

/*
BEGIN;

-- Step 1: Delete Exam Participants
DELETE FROM exam_slot_participants
WHERE exam_slot_subject_id IN (
    SELECT id FROM exam_slot_subjects
    WHERE exam_slot_id IN (
        SELECT id FROM slots WHERE title = 'Final Exam SE-FA25'
    )
);

-- Step 2: Delete Exam Slot Subjects
DELETE FROM exam_slot_subjects
WHERE exam_slot_id IN (
    SELECT id FROM slots WHERE title = 'Final Exam SE-FA25'
);

-- Step 3: Delete Exam Slot
DELETE FROM slots WHERE title = 'Final Exam SE-FA25';

-- Step 4: Delete Lecture Slots
DELETE FROM slots
WHERE class_id IN (
    SELECT id FROM classes WHERE code IN ('SE-PRF192-FA25', 'SE-SWE201-FA25')
);

-- Step 5: Delete Enrollments
DELETE FROM enrollments
WHERE class_id IN (
    SELECT id FROM classes WHERE code IN ('SE-PRF192-FA25', 'SE-SWE201-FA25')
);

-- Step 6: Delete Classes
DELETE FROM classes
WHERE code IN ('SE-PRF192-FA25', 'SE-SWE201-FA25');

-- Step 7: Delete Cameras
DELETE FROM cameras
WHERE room_id = (SELECT id FROM rooms WHERE name = 'Room Test 99');

-- Step 8: Delete Room
DELETE FROM rooms WHERE name = 'Room Test 99';

COMMIT;

SELECT 'Cleanup completed successfully!' AS status;
*/
