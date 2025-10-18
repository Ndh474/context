# Database Schema - FUACS

**Schema Name:** FUACS_Schema  
**Version:** 1.0  
**Description:** A detailed representation of the FUACS PostgreSQL database schema.

---

## Table of Contents

1. [users](#users)
2. [password_reset_tokens](#password_reset_tokens)
3. [roles](#roles)
4. [permissions](#permissions)
5. [user_roles](#user_roles)
6. [role_permissions](#role_permissions)
7. [majors](#majors)
8. [student_profiles](#student_profiles)
9. [staff_profiles](#staff_profiles)
10. [semesters](#semesters)
11. [subjects](#subjects)
12. [classes](#classes)
13. [rooms](#rooms)
14. [slots](#slots)
15. [cameras](#cameras)
16. [slot_cameras](#slot_cameras)
17. [enrollments](#enrollments)
18. [attendance_records](#attendance_records)
19. [attendance_remarks](#attendance_remarks)
20. [identity_submissions](#identity_submissions)
21. [identity_assets](#identity_assets)
22. [face_embeddings](#face_embeddings)
23. [slot_announcements](#slot_announcements)
24. [pre_slot_messages](#pre_slot_messages)
25. [system_notifications](#system_notifications)
26. [notification_deliveries](#notification_deliveries)
27. [system_configurations](#system_configurations)
28. [operational_audit_logs](#operational_audit_logs)

---

## users

**Primary Key:** id

**Columns:**

- `created_at` - timestamp, NOT NULL, Default: now()
- `updated_at` - timestamp, NOT NULL
- `id` - INT, NOT NULL, Primary Key, Auto-generated
- `is_active` - boolean, NOT NULL, Default: true
- `username` - varchar(50), NOT NULL, Unique
- `email` - varchar(128), NOT NULL, Unique
- `full_name` - varchar(150), NOT NULL
- `password_hash` - varchar(255), NULL

## password_reset_tokens

**Primary Key:** id

**Columns:**

- `expires_at` - timestamp, NOT NULL
- `created_at` - timestamp, NOT NULL, Default: now()
- `id` - INT, NOT NULL, Primary Key, Auto-generated
- `email` - varchar(128), NOT NULL
- `token_hash` - varchar(100), NOT NULL, Unique

## roles

**Primary Key:** id

**Columns:**

- `created_at` - timestamp, NOT NULL, Default: now()
- `updated_at` - timestamp, NOT NULL
- `id` - SMALLINT, NOT NULL, Primary Key, Auto-generated
- `is_active` - boolean, NOT NULL, Default: true
- `name` - varchar(100), NOT NULL, Unique

## permissions

**Primary Key:** id

**Columns:**

- `created_at` - timestamp, NOT NULL, Default: now()
- `updated_at` - timestamp, NOT NULL
- `id` - SMALLINT, NOT NULL, Primary Key, Auto-generated
- `is_active` - boolean, NOT NULL, Default: true
- `name` - varchar(100), NOT NULL, Unique

## user_roles

**Primary Key:** (user_id, role_id)

**Columns:**

- `user_id` - int, NOT NULL, Primary Key, Foreign Key → users(id)
- `role_id` - smallint, NOT NULL, Primary Key, Foreign Key → roles(id)

## role_permissions

**Primary Key:** (role_id, permission_id)

**Columns:**

- `role_id` - smallint, NOT NULL, Primary Key, Foreign Key → roles(id)
- `permission_id` - smallint, NOT NULL, Primary Key, Foreign Key → permissions(id)

## majors

**Primary Key:** id

**Columns:**

- `created_at` - timestamp, NOT NULL, Default: now()
- `updated_at` - timestamp, NOT NULL
- `id` - SMALLINT, NOT NULL, Primary Key, Auto-generated
- `is_active` - boolean, NOT NULL, Default: true
- `name` - varchar(150), NOT NULL, Unique
- `code` - varchar(20), NOT NULL, Unique

## student_profiles

**Primary Key:** user_id

**Columns:**

- `user_id` - int, NOT NULL, Primary Key, Foreign Key → users(id)
- `major_id` - smallint, NOT NULL, Foreign Key → majors(id)

## staff_profiles

**Primary Key:** user_id

**Columns:**

- `user_id` - int, NOT NULL, Primary Key, Foreign Key → users(id)

## semesters

**Primary Key:** id

**Columns:**

- `created_at` - timestamp, NOT NULL, Default: now()
- `updated_at` - timestamp, NOT NULL
- `id` - SMALLINT, NOT NULL, Primary Key, Auto-generated
- `start_date` - date, NOT NULL
- `end_date` - date, NOT NULL
- `is_active` - boolean, NOT NULL, Default: true
- `name` - varchar(150), NOT NULL, Unique
- `code` - varchar(20), NOT NULL, Unique

## subjects

**Primary Key:** id

**Columns:**

- `created_at` - timestamp, NOT NULL, Default: now()
- `updated_at` - timestamp, NOT NULL
- `id` - SMALLINT, NOT NULL, Primary Key, Auto-generated
- `major_id` - smallint, NOT NULL, Foreign Key → majors(id)
- `is_active` - boolean, NOT NULL, Default: true
- `name` - varchar(150), NOT NULL
- `code` - varchar(20), NOT NULL, Unique

## classes

**Primary Key:** id

**Columns:**

- `created_at` - timestamp, NOT NULL, Default: now()
- `updated_at` - timestamp, NOT NULL
- `id` - SMALLINT, NOT NULL, Primary Key, Auto-generated
- `subject_id` - smallint, NOT NULL, Foreign Key → subjects(id)
- `semester_id` - smallint, NOT NULL, Foreign Key → semesters(id)
- `is_active` - boolean, NOT NULL, Default: true
- `name` - varchar(150), NOT NULL

**Indexes:**

- `classes_subject_id_semester_id_name_idx` (subject_id, semester_id, name) - Unique

## rooms

**Primary Key:** id

**Columns:**

- `created_at` - timestamp, NOT NULL, Default: now()
- `updated_at` - timestamp, NOT NULL
- `id` - SMALLINT, NOT NULL, Primary Key, Auto-generated
- `is_active` - boolean, NOT NULL, Default: true
- `name` - varchar(150), NOT NULL, Unique
- `location` - varchar(255), NULL

## slots

**Primary Key:** id  
**Comment:** slot_type can be 'LECTURE' or 'EXAM'

**Columns:**

- `start_time` - timestamp, NOT NULL
- `end_time` - timestamp, NOT NULL
- `finalized_at` - timestamp, NULL
- `created_at` - timestamp, NOT NULL, Default: now()
- `updated_at` - timestamp, NOT NULL
- `id` - INT, NOT NULL, Primary Key, Auto-generated
- `class_id` - smallint, NOT NULL, Foreign Key → classes(id)
- `room_id` - smallint, NOT NULL, Foreign Key → rooms(id)
- `staff_user_id` - int, NOT NULL, Foreign Key → users(id)
- `slot_type` - varchar(20), NOT NULL
- `is_active` - boolean, NOT NULL, Default: true

## cameras

**Primary Key:** id

**Columns:**

- `created_at` - timestamp, NOT NULL, Default: now()
- `updated_at` - timestamp, NOT NULL
- `id` - SMALLINT, NOT NULL, Primary Key, Auto-generated
- `room_id` - smallint, NOT NULL, Foreign Key → rooms(id)
- `is_active` - boolean, NOT NULL, Default: true
- `name` - varchar(150), NOT NULL, Unique
- `rtsp_url` - varchar(512), NOT NULL, Unique

## slot_cameras

**Primary Key:** (slot_id, camera_id)

**Columns:**

- `slot_id` - int, NOT NULL, Primary Key, Foreign Key → slots(id)
- `camera_id` - smallint, NOT NULL, Primary Key, Foreign Key → cameras(id)

## enrollments

**Primary Key:** (class_id, student_user_id)

**Columns:**

- `created_at` - timestamp, NOT NULL, Default: now()
- `updated_at` - timestamp, NOT NULL
- `class_id` - smallint, NOT NULL, Primary Key, Foreign Key → classes(id)
- `student_user_id` - int, NOT NULL, Primary Key, Foreign Key → users(id)
- `is_active` - boolean, NOT NULL, Default: true

## attendance_records

**Primary Key:** id  
**Comments:**

- status: 'not_yet', 'present', 'absent', 'absent_after_present'
- method: 'auto', 'manual', 'system_finalize'

**Columns:**

- `id` - BIGINT, NOT NULL, Primary Key, Auto-generated
- `recorded_at` - timestamp, NOT NULL, Default: now()
- `created_at` - timestamp, NOT NULL, Default: now()
- `updated_at` - timestamp, NOT NULL
- `student_user_id` - int, NOT NULL, Foreign Key → users(id)
- `slot_id` - int, NOT NULL, Foreign Key → slots(id)
- `status` - varchar(30), NOT NULL
- `method` - varchar(20), NOT NULL
- `history` - jsonb, NULL

**Indexes:**

- `attendance_records_student_user_id_slot_id_idx` (student_user_id, slot_id) - Unique

## attendance_remarks

**Primary Key:** id

**Columns:**

- `id` - BIGINT, NOT NULL, Primary Key, Auto-generated
- `attendance_record_id` - bigint, NOT NULL, Foreign Key → attendance_records(id)
- `created_at` - timestamp, NOT NULL, Default: now()
- `updated_at` - timestamp, NOT NULL
- `created_by_user_id` - int, NOT NULL, Foreign Key → users(id)
- `is_active` - boolean, NOT NULL, Default: true
- `remark` - text, NOT NULL

## identity_submissions

**Primary Key:** id  
**Comments:**

- status: 'pending', 'approved', 'rejected'
- submission_type: 'initial', 'update'

**Columns:**

- `reviewed_at` - timestamp, NULL
- `created_at` - timestamp, NOT NULL, Default: now()
- `updated_at` - timestamp, NOT NULL
- `id` - INT, NOT NULL, Primary Key, Auto-generated
- `student_user_id` - int, NOT NULL, Foreign Key → users(id)
- `reviewed_by_user_id` - int, NULL, Foreign Key → users(id)
- `status` - varchar(20), NOT NULL
- `submission_type` - varchar(20), NOT NULL
- `rejection_reason` - text, NULL

## identity_assets

**Primary Key:** id  
**Comment:** asset_type can be 'face_video' or 'id_card'

**Columns:**

- `created_at` - timestamp, NOT NULL, Default: now()
- `updated_at` - timestamp, NOT NULL
- `id` - INT, NOT NULL, Primary Key, Auto-generated
- `submission_id` - int, NOT NULL, Foreign Key → identity_submissions(id)
- `is_active` - boolean, NOT NULL, Default: true
- `asset_type` - varchar(20), NOT NULL
- `storage_url` - varchar(255), NOT NULL

## face_embeddings

**Primary Key:** id  
**Comment:** Requires pgvector extension

**Columns:**

- `created_at` - timestamp, NOT NULL, Default: now()
- `updated_at` - timestamp, NOT NULL
- `id` - INT, NOT NULL, Primary Key, Auto-generated
- `student_user_id` - int, NOT NULL, Foreign Key → users(id)
- `generated_from_asset_id` - int, NOT NULL, Foreign Key → identity_assets(id)
- `version` - int, NOT NULL
- `is_active` - boolean, NOT NULL, Default: false
- `embedding_vector` - vector(512), NOT NULL

## slot_announcements

**Primary Key:** id

**Columns:**

- `created_at` - timestamp, NOT NULL, Default: now()
- `updated_at` - timestamp, NOT NULL
- `id` - INT, NOT NULL, Primary Key, Auto-generated
- `slot_id` - int, NOT NULL, Foreign Key → slots(id)
- `created_by_user_id` - int, NOT NULL, Foreign Key → users(id)
- `is_active` - boolean, NOT NULL, Default: true
- `title` - varchar(255), NOT NULL
- `content` - text, NOT NULL

## pre_slot_messages

**Primary Key:** id

**Columns:**

- `id` - BIGINT, NOT NULL, Primary Key, Auto-generated
- `acknowledged_at` - timestamp, NULL
- `created_at` - timestamp, NOT NULL, Default: now()
- `updated_at` - timestamp, NOT NULL
- `slot_id` - int, NOT NULL, Foreign Key → slots(id)
- `student_user_id` - int, NOT NULL, Foreign Key → users(id)
- `content` - text, NOT NULL
- `url` - varchar(2048), NULL

## system_notifications

**Primary Key:** id

**Columns:**

- `id` - BIGINT, NOT NULL, Primary Key, Auto-generated
- `created_at` - timestamp, NOT NULL, Default: now()
- `updated_at` - timestamp, NOT NULL
- `is_active` - boolean, NOT NULL, Default: true
- `notification_type` - varchar(50), NOT NULL
- `title` - varchar(255), NOT NULL
- `content` - text, NOT NULL

## notification_deliveries

**Primary Key:** id

**Columns:**

- `id` - BIGINT, NOT NULL, Primary Key, Auto-generated
- `notification_id` - bigint, NOT NULL, Foreign Key → system_notifications(id)
- `read_at` - timestamp, NULL
- `created_at` - timestamp, NOT NULL, Default: now()
- `updated_at` - timestamp, NOT NULL
- `recipient_user_id` - int, NOT NULL, Foreign Key → users(id)
- `is_active` - boolean, NOT NULL, Default: true

## system_configurations

**Primary Key:** id

**Columns:**

- `created_at` - timestamp, NOT NULL, Default: now()
- `updated_at` - timestamp, NOT NULL
- `id` - INT, NOT NULL, Primary Key, Auto-generated
- `is_active` - boolean, NOT NULL, Default: true
- `key` - varchar(255), NOT NULL, Unique
- `value` - text, NOT NULL
- `description` - text, NULL

## operational_audit_logs

**Primary Key:** id

**Columns:**

- `id` - BIGINT, NOT NULL, Primary Key, Auto-generated
- `target_id` - BIGINT, NOT NULL
- `created_at` - timestamp, NOT NULL, Default: now()
- `actor_user_id` - int, NOT NULL, Foreign Key → users(id)
- `action_type` - varchar(50), NOT NULL
- `target_entity` - varchar(50), NOT NULL
- `changes` - jsonb, NULL

---

## Database Extensions Required

- **pgvector**: Required for the `face_embeddings` table to store vector embeddings for facial recognition.

---

## Summary

**Total Tables:** 28

The database schema follows a logical structure with proper relationships and constraints to support the FUACS attendance management system.
