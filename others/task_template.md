# Task Template

## 1. METADATA

### Task Title
<!-- (Required) A concise title for the task. Example: "Implement User Authentication Endpoint" -->

### Priority
<!-- (Required) High / Medium / Low -->

---

## 2. CONTEXT & OBJECTIVES

### Current State
<!-- (Required) Describe the current state of the relevant system part(s). -->

### What Is Missing
<!-- (Required) Describe the problem, bug, or missing feature to be addressed. -->

### Task Objective
<!-- (Required) What is the specific, completed goal of this task? Example: "Create 2 endpoints: GET /users and POST /users". -->

### Scope (In & Out)
<!-- (Required) Clearly define the scope of work. -->

**IN SCOPE:**

* <!-- (List what the agent MUST do) -->

**OUT OF SCOPE:**

* <!-- (List what the agent MUST NOT do. Example: "Do not change DB schema", "Do not refactor unrelated code") -->

### Common Issues & Solutions
<!-- (Optional) List anticipated errors/issues and how to handle them. -->

### Future Enhancements
<!-- (Optional) Long-term context/future improvements so the agent can make better design decisions. -->

---

## 3. ARCHITECTURE & DESIGN

### Architecture Overview
<!-- (Required) Briefly describe the architecture that will be impacted. -->

### Component Interaction
<!-- (Optional but Recommended) Describe how components/services/classes interact. (Text description or Mermaid diagrams are fine). -->

### Database Schema
<!-- (Optional) Provide relevant database schema(s) (existing or new). -->

```sql
/* (Paste SQL schema if applicable) */
```

### API Changes (Before/After)
<!-- (Optional) Describe API changes (if this task is API-related). -->

**Before:**

```text
/* (Current API) */
```

**After:**

```text
/* (New/Modified API) */
```

---

## 4. REFERENCE PATTERNS (CODE SNIPPETS)
<!-- (Required) Provide REAL CODE SNIPPETS from the codebase as reference templates. -->

### Example 1: (Pattern Description, e.g., "Controller Pattern")
<!-- (Paste real code snippet from the codebase) -->

```text
/* (Paste reference code here) */
```

### Example 2: (Pattern Description, e.g., "Service Pattern")
<!-- (Paste real code snippet from the codebase) -->

```text
/* (Paste reference code here) */
```

---

## 5. IMPLEMENTATION SCRIPT

### Summary of Changes
<!-- (Required) List all files that will be created [NEW] or modified [MODIFY]. -->

* `[NEW]` path/to/new/file.ext
* `[MODIFY]` path/to/existing/file.ext

<!-- (Repeat the "Task" blocks below for EVERY file in the SummaryOfChanges) -->

### Task 5.1: Create New File `path/to/new/file.ext`
<!-- (Required for [NEW] files) Provide the FULL source code for the new file. -->

```text
/* (Paste the complete source code for the new file here) */
```

### Task 5.2: Modify Existing File `path/to/existing/file.ext`
<!-- (Required for [MODIFY] files) Provide clear instructions OR the full code/diff. -->

**Changes:**

1. <!-- (Describe Change 1. Example: "Add these 3 constants to ErrorCode.java") -->

   ```java
   /* (Paste code to be added) */
   ```

2. <!-- (Describe Change 2. Example: "Replace the xyz() function with the following:") -->

   ```java
   /* (Paste replacement code) */
   ```

---

## 6. VERIFICATION STRATEGY

### Expected Outcome / After Change
<!-- (Required) Describe the expected result after the task is complete. -->

### Acceptance Criteria
<!-- (Required) A checklist of specific conditions that must be met to be "done". -->

* [ ] (Condition 1)
* [ ] (Condition 2)

### Unit Tests (Code Snippet)
<!-- (Optional but Recommended) Provide the code (or skeleton) for Unit Tests. -->

```text
/* (Paste Unit Test code here) */
```

### Manual Test Steps (Postman/cURL)
<!-- (Optional but Recommended) Provide cURL commands or Postman scenarios for manual testing. -->

#### 1. (Describe Step 1)
<!-- (Paste cURL command or Postman description) -->

```http
POST http://localhost:8080/api/v1/...
Authorization: Bearer ...
```

**Expected Response:**

```json
/* (Paste expected JSON response) */
```
