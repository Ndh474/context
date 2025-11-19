# Excel Test Case Generator

Generate Excel test case documents from JSON data with strict naming conventions and validation.

## 📋 Table of Contents

- [Installation](#installation)
- [Quick Start](#quick-start)
- [Naming Conventions](#naming-conventions)
- [JSON Structure](#json-structure)
- [Common Mistakes](#common-mistakes)
- [Checklist](#checklist)
- [Usage](#usage)
- [Examples](#examples)

---

## Installation

```bash
pip install openpyxl
```

## Quick Start

1. Copy `template.json` to your project
2. Fill in your test data following the conventions below
3. Verify using the checklist
4. Generate Excel file:

```bash
python main.py --json your_test.json
```

---

## Naming Conventions

### ✅ Test Case IDs

**Format**: `TCXX` (2 digits, no underscore, no prefix)

```json
✅ CORRECT: "TC01", "TC02", "TC15"
❌ WRONG: "TC_SS_01", "TC_1", "search_TC01"
```

### ✅ Sheet Names

**Format**: `{module}_{method}` (snake_case, with module prefix)

```json
✅ CORRECT: "semester_search", "semester_create", "user_login"
❌ WRONG: "search", "SemesterSearch", "semester-search"
```

### ✅ Method Names

**Format**: Method name only (no parameters, no type signatures)

```json
✅ CORRECT: "search", "findById", "create"
❌ WRONG: "search(SemesterSearchRequest request)", "findById(Short id)"
```

---

## JSON Structure

### 1. Metadata (all required)

```json
"metadata": {
    "code_module": "SemesterService",
    "method": "search",                    // NO parameters!
    "created_by": "Your Name",
    "executed_by": "JUnit",
    "executed_date": "2025-01-15",         // YYYY-MM-DD
    "test_requirement": "Description",
    "sheet_name": "semester_search"        // module_method format
}
```

### 2. Preconditions

**ALWAYS include these standard preconditions first**:

```json
"preconditions": [
    {"description": "Can connect to server"},
    {"description": "Send request to SemesterService.search"},
    {"description": "SemesterRepository is mocked"},
    {"description": "(additional preconditions if needed)"}
]
```

### 3. Inputs

**⚠️ CRITICAL**: ONE input group per parameter (not per test case!)

```json
"inputs": [
    {
        "header": "page",        // Parameter 1 (separate group)
        "items": [
            {"description": "1", "applicable_to": ["TC01", "TC02"]},
            {"description": "null", "applicable_to": ["TC03"]}
        ]
    },
    {
        "header": "size",        // Parameter 2 (separate group)
        "items": [
            {"description": "10", "applicable_to": ["TC01"]},
            {"description": "20", "applicable_to": ["TC02"]}
        ]
    }
]

// ❌ WRONG: Don't group all params together!
"inputs": [
    {
        "header": "request",
        "items": [{"description": "page=1, size=10, sortBy=name", ...}]
    }
]
```

### 4. Confirm Groups

**ALWAYS include ALL 3 groups** (even if empty):

```json
"confirm_groups": [
    {
        "header": "Return Values",
        "items": [
            {"description": "Page<SemesterDTO> with 4 items", "applicable_to": ["TC01"]}
        ]
    },
    {
        "header": "Exceptions",
        "items": [
            {"description": "ResourceNotFoundException", "applicable_to": ["TC02"]},
            {"description": "", "applicable_to": []}  // At least 1 item (can be empty)
        ]
    },
    {
        "header": "Log Messages",
        "items": [
            {"description": "Semester not found: 999", "applicable_to": ["TC02"]},
            {"description": "", "applicable_to": []}  // At least 1 item (can be empty)
        ]
    }
]
```

**Important**:
- **Exceptions**: Class name ONLY (e.g., "ResourceNotFoundException")
- **Log Messages**: Detailed descriptions (e.g., "Semester not found: 999")
- **At least 1 item** per group (use empty description if no items)

### 5. Test Cases

```json
"test_cases": [
    {
        "id": "TC01",                    // MUST be TCXX format!
        "type": "N",                     // N = Normal, A = Abnormal, B = Boundary
        "result": "Passed",              // Passed/Failed/Untested
        "executed_date": "2025-11-19",
        "defect_id": "",                 // Optional
        "note": ""                       // Optional
    }
]
```

---

## Common Mistakes

### ❌ Mistake 1: Missing Module Prefix in Sheet Name
```json
❌ WRONG: "sheet_name": "search"
✅ CORRECT: "sheet_name": "semester_search"
```

### ❌ Mistake 2: Including Parameters in Method Name
```json
❌ WRONG: "method": "search(SemesterSearchRequest request)"
✅ CORRECT: "method": "search"
```

### ❌ Mistake 3: Missing Standard Preconditions
```json
❌ WRONG:
"preconditions": [
    {"description": "SemesterRepository is mocked"}
]

✅ CORRECT:
"preconditions": [
    {"description": "Can connect to server"},
    {"description": "Send request to SemesterService.search"},
    {"description": "SemesterRepository is mocked"}
]
```

### ❌ Mistake 4: Grouping All Parameters in One Input
```json
❌ WRONG:
"inputs": [
    {
        "header": "request",
        "items": [{"description": "page=1, size=10, sortBy=name", ...}]
    }
]

✅ CORRECT:
"inputs": [
    {"header": "page", "items": [{"description": "1", ...}]},
    {"header": "size", "items": [{"description": "10", ...}]},
    {"header": "sortBy", "items": [{"description": "name", ...}]}
]
```

### ❌ Mistake 5: Missing Exceptions or Log Messages Groups
```json
❌ WRONG:
"confirm_groups": [
    {"header": "Return Values", "items": [...]}
]

✅ CORRECT:
"confirm_groups": [
    {"header": "Return Values", "items": [...]},
    {"header": "Exceptions", "items": [{"description": "", "applicable_to": []}]},
    {"header": "Log Messages", "items": [{"description": "", "applicable_to": []}]}
]
```

### ❌ Mistake 6: Putting Detailed Messages in Exceptions
```json
❌ WRONG:
"Exceptions": [
    {"description": "ResourceNotFoundException with message 'Not found: 999'", ...}
]

✅ CORRECT:
"Exceptions": [
    {"description": "ResourceNotFoundException", "applicable_to": ["TC02"]}
],
"Log Messages": [
    {"description": "Semester not found: 999", "applicable_to": ["TC02"]}
]
```

### ❌ Mistake 7: Using Underscores in Test Case IDs
```json
❌ WRONG: "id": "TC_SS_01", "id": "TC_CR_02"
✅ CORRECT: "id": "TC01", "id": "TC02"
```

---

## Checklist

Before running the script, verify:

- [ ] Test case IDs: TCXX format (no underscores, no prefixes)
- [ ] Sheet name: module_method format (e.g., "semester_search")
- [ ] Method name: No parameters (e.g., "search" not "search(request)")
- [ ] Preconditions: Include standard ones (Can connect, Send request)
- [ ] Inputs: One group per parameter (not grouped together)
- [ ] Confirm groups: All 3 present (Return Values, Exceptions, Log Messages)
- [ ] Exceptions: Short names only (e.g., "ResourceNotFoundException")
- [ ] Log Messages: Detailed descriptions (e.g., "Semester not found: 999")
- [ ] At least 1 item in Exceptions/Log Messages (can be empty description)

---

## Usage

### Basic Commands

```bash
# Create new Excel file from JSON
python main.py --json test_data.json

# Add sheet to existing Excel file
python main.py --json test_data.json --add-sheet existing.xlsx
```

### Command-Line Options

| Option        | Required | Description                                 |
| ------------- | -------- | ------------------------------------------- |
| `--json`      | ✅ Yes   | Path to JSON input file                     |
| `--add-sheet` | ❌ No    | Path to existing Excel file to add sheet to |

### Single vs Multiple Scenarios

**Single Scenario** (creates 1 sheet):
```json
{
    "metadata": {...},
    "preconditions": [...],
    "inputs": [...],
    "confirm_groups": [...],
    "test_cases": [...]
}
```

**Multiple Scenarios** (creates multiple sheets):
```json
[
    {
        "metadata": {"sheet_name": "semester_search"},
        "preconditions": [...],
        "inputs": [...],
        "confirm_groups": [...],
        "test_cases": [...]
    },
    {
        "metadata": {"sheet_name": "semester_create"},
        "preconditions": [...],
        "inputs": [...],
        "confirm_groups": [...],
        "test_cases": [...]
    }
]
```

---

## Examples

### Example 1: Real-World Service Tests

```bash
python main.py --json semester_test.json
```

Output: `semester_test_output.xlsx` with 6 sheets

```
[OK] 6 sheets created file 'semester_test_output.xlsx' successfully!
  - semester_search: 4 test cases
  - semester_findById: 2 test cases
  - semester_create: 7 test cases
  - semester_update: 15 test cases
  - semester_delete: 4 test cases
  - semester_count: 3 test cases
Total: 35 test cases
```

### Example 2: Simple Template

```bash
python main.py --json template.json
```

Output: `template_output.xlsx` with 1 sheet

```
[OK] Sheet 'module_method' created file 'template_output.xlsx' successfully!
     Test Cases: 3
     Preconditions: 4 items
     Input Groups: 2 (6 items)
     Confirm Groups: 3 (6 items)
```

### Example 3: Add to Existing File

```bash
python main.py --json auth_tests.json --add-sheet project_tests.xlsx
```

Result: Adds new sheet(s) to `project_tests.xlsx` (replaces if sheet name exists)

---

## Output Format

The script generates Excel files with:

- **Header Section**: Module info, method, authors, dates, requirements
- **Test Cases Section**: TC01, TC02, etc. with test types (N/A/B)
- **Preconditions**: Listed without "O" marking
- **Input Section**: Grouped inputs with "O" marking
- **Confirmation Section**: Grouped confirmations with "O" marking
- **Result Section**: Test results, executed date, defect IDs, notes

---

## Reference Files

- **`template.json`** - Basic template to start your own test files
- **`semester_test.json`** - Real-world example with 35 test cases across 6 methods

---

## License

MIT
