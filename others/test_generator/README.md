# Test Generator Tools

Generate Excel test case documents and DOCX evidence reports from Java test files.

## Tools Overview

| Tool               | Description                              | Input         | Output        |
| ------------------ | ---------------------------------------- | ------------- | ------------- |
| `json_to_excel.py` | Generate Excel test case sheets          | JSON file     | Excel (.xlsx) |
| `code_to_image.py` | Render Java test methods as images       | Java file     | PNG images    |
| `image_to_docx.py` | Generate DOCX with images and references | Images + JSON | DOCX file     |
| `merge_docx.py`    | Merge multiple DOCX files into one       | DOCX files    | DOCX file     |

## Installation

```bash
pip install openpyxl pygments pillow python-docx
```

## Quick Start

### 1. Generate Excel Test Cases

```bash
# Create new Excel file
python json_to_excel.py --json test_json/my_test.json

# Add sheets to existing Excel file
python json_to_excel.py --json test_json/my_test.json --add-sheet Report5.1_UnitTest.xlsx
```

### 2. Generate Code Images

```bash
# Generate images for all test methods
python code_to_image.py --file path/to/MyServiceTest.java --output test_images/MST --no-line-numbers

# Generate image for specific method
python code_to_image.py --file path/to/MyServiceTest.java --output test_images/MST --method myTestMethod --no-line-numbers
```

### 3. Generate DOCX Evidence Report

```bash
# Create new DOCX
python image_to_docx.py --images test_images/MST --json test_json/my_test.json --output test_output/MyServiceTest.docx --title "MyServiceTest"

# Append to existing DOCX
python image_to_docx.py --images test_images/MST --json test_json/my_test.json --output test_output/Report.docx --append test_output/Report.docx --title "MyServiceTest"
```

## JSON Structure

### Metadata (Required)

```json
{
  "metadata": {
    "code_module": "MyService",
    "method": "myMethod",
    "created_by": "Developer",
    "executed_by": "Developer",
    "executed_date": "2025-01-01",
    "test_requirement": "Test description",
    "sheet_name": "MST_myMethod"
  }
}
```

**Default Values:**

- `created_by`: "Developer" (or specify team member name)
- `executed_by`: "Developer" (or specify team member name)
- `executed_date`: Current date in YYYY-MM-DD format

**Important Rules:**

- JSON must cover ALL test methods in the Java file (unless user explicitly specifies subset)
- Each test method = 1 test case in JSON
- Generated images must match 1:1 with test cases in JSON
- `note` field in test_cases should match the Java method name for image-to-docx mapping

### Sheet Naming Convention

Format: `{PREFIX}_{methodName}`

**Constraint: Sheet name must be ≤ 31 characters** (Excel limitation). If longer, truncate or abbreviate the method name.

Examples:

- `SemesterServiceTest` → `SST_search`, `SST_create`
- `AttendanceRecordServiceTest` → `ARST_updateStatus`, `ARST_processInitial`

### Test Case IDs

Format: `TCXX` (2 digits, no prefix)

```json
"test_cases": [
  {"id": "TC01", "type": "N", "passed_failed": "Passed", ...},
  {"id": "TC02", "type": "A", "passed_failed": "Passed", ...}
]
```

**Test Types:**

- `N` = Normal
- `A` = Abnormal
- `B` = Boundary

### Complete JSON Example

```json
[
  {
    "metadata": {
      "code_module": "MyService",
      "method": "search",
      "created_by": "Developer",
      "executed_by": "Developer",
      "executed_date": "2025-01-01",
      "test_requirement": "Test search functionality",
      "sheet_name": "MST_search"
    },
    "statistics": {
      "passed": 3,
      "failed": 0,
      "untested": 0,
      "type_counts": { "N": 1, "A": 2, "B": 0 },
      "total_test_cases": 3
    },
    "preconditions": [
      { "description": "Can connect to server" },
      { "description": "Send request to MyService.search" },
      { "description": "MyRepository is mocked" }
    ],
    "inputs": [
      {
        "header": "param1",
        "items": [
          { "description": "valid value", "applicable_to": ["TC01"] },
          { "description": "null", "applicable_to": ["TC02", "TC03"] }
        ]
      }
    ],
    "confirm_groups": [
      {
        "header": "Return Values",
        "items": [{ "description": "List<MyDTO>", "applicable_to": ["TC01"] }]
      },
      {
        "header": "Exceptions",
        "items": [
          {
            "description": "ResourceNotFoundException",
            "applicable_to": ["TC02"]
          },
          { "description": "BadRequestException", "applicable_to": ["TC03"] }
        ]
      },
      {
        "header": "Log Messages",
        "items": [{ "description": "", "applicable_to": [] }]
      }
    ],
    "test_cases": [
      {
        "id": "TC01",
        "type": "N",
        "passed_failed": "Passed",
        "executed_date": "2025-01-01",
        "defect_id": "",
        "note": "search_Success"
      },
      {
        "id": "TC02",
        "type": "A",
        "passed_failed": "Passed",
        "executed_date": "2025-01-01",
        "defect_id": "",
        "note": "search_NotFound"
      },
      {
        "id": "TC03",
        "type": "A",
        "passed_failed": "Passed",
        "executed_date": "2025-01-01",
        "defect_id": "",
        "note": "search_InvalidParam"
      }
    ]
  }
]
```

## CLI Reference

### json_to_excel.py

| Option        | Required | Description                               |
| ------------- | -------- | ----------------------------------------- |
| `--json`      | Yes      | Path to JSON input file                   |
| `--add-sheet` | No       | Path to existing Excel file to add sheets |

### code_to_image.py

| Option              | Required | Description                       |
| ------------------- | -------- | --------------------------------- |
| `--file`            | Yes      | Path to Java test file            |
| `--output`          | Yes      | Output directory for images       |
| `--method`          | No       | Generate only specific method     |
| `--font-size`       | No       | Font size (default: 14)           |
| `--style`           | No       | Pygments style (default: monokai) |
| `--no-line-numbers` | No       | Disable line numbers              |

### image_to_docx.py

| Option     | Required | Description                      |
| ---------- | -------- | -------------------------------- |
| `--images` | Yes      | Directory containing test images |
| `--json`   | Yes      | JSON file with test case mapping |
| `--output` | Yes      | Output DOCX file path            |
| `--append` | No       | Append to existing DOCX file     |
| `--title`  | No       | Document/section title           |

### merge_docx.py

| Option     | Required | Description                          |
| ---------- | -------- | ------------------------------------ |
| `--files`  | No*      | List of DOCX files to merge          |
| `--dir`    | No*      | Directory containing DOCX files      |
| `--output` | Yes      | Output merged DOCX file              |

*Either `--files` or `--dir` is required.

```bash
# Merge specific files
python merge_docx.py --files Service1Test.docx Service2Test.docx --output Report5.1_Evidence.docx

# Merge all DOCX files in a directory
python merge_docx.py --dir test_output --output Report5.1_Evidence.docx
```

## Directory Structure

```
test_generator/
├── json_to_excel.py      # JSON → Excel
├── code_to_image.py      # Java → PNG
├── image_to_docx.py      # Images → DOCX
├── README.md
├── test_json/            # JSON test data files
├── test_images/          # Generated PNG images
│   └── {PREFIX}/         # Per-service folder
└── test_output/          # Generated Excel/DOCX files
```

## Workflow Example

```bash
# 1. Create JSON for your test file (manually or with AI assistance)
# Save to test_json/my_service_test.json

# 2. Generate Excel sheets
python json_to_excel.py --json test_json/my_service_test.json --add-sheet test_output/Report5.1_UnitTest.xlsx

# 3. Generate code images
python code_to_image.py --file ../../backend/src/test/java/.../MyServiceTest.java --output test_images/MST --no-line-numbers

# 4. Generate DOCX evidence
python image_to_docx.py --images test_images/MST --json test_json/my_service_test.json --output test_output/MyServiceTest.docx --title "MyServiceTest"
```
