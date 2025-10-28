import requests
import json
import time
import sys
import codecs
from datetime import datetime, timedelta

# Fix UnicodeEncodeError on Windows Console
# Force stdout to use UTF-8 encoding
sys.stdout = codecs.getwriter("utf-8")(sys.stdout.buffer)

# --- CONFIGURATION ---
# TODO: CHANGE THIS VALUE to your actual server URL
BASE_URL = "http://localhost:8080"
USERNAME = "god000"
PASSWORD = "12345678"

# --- ASSUMPTIONS ---
# Script assumes that a subject with ID=1 and a semester with ID=1 exist in the database.
EXISTING_SUBJECT_ID = 1
EXISTING_SEMESTER_ID = 1
# --------------------

# Global variables
access_token = None
report_data = []

# --- Helper Functions ---


def print_success(message):
    """Prints a success message in green."""
    print(f"\033[92m[THÀNH CÔNG] {message}\033[0m")


def print_error(message, data=None):
    """Prints an error message in red."""
    print(f"\033[91m[LỖI] {message}\033[0m")
    if data:
        # Ensure correct printing of Vietnamese JSON
        print(f"\033[91m      {json.dumps(data, indent=2, ensure_ascii=False)}\033[0m")


def print_info(message):
    """Prints an informational message in blue."""
    print(f"\033[94m[THÔNG TIN] {message}\033[0m")


def log_api_call(method, url, request_payload, response_status, response_body):
    """Stores API call details for report generation."""
    report_data.append(
        {
            "method": method,
            "url": url,
            "request_payload": request_payload,
            "response_status": response_status,
            "response_body": response_body,
        }
    )


def generate_markdown_report(filename="api_test_report_classes.md"):
    """Creates a Markdown file from the stored API call data."""
    print_info(f"Đang tạo báo cáo Markdown: {filename}")
    try:
        with open(filename, "w", encoding="utf-8") as f:
            f.write(
                f"# Báo cáo Kiểm thử API - Classes ({time.strftime('%Y-%m-%d %H:%M:%S')})\n\n"
            )

            for i, call in enumerate(report_data):
                f.write(f"## {i + 1}. {call['method']} {call['url']}\n\n")
                f.write(f"**Trạng thái Phản hồi:** `{call['response_status']}`\n\n")

                if call["request_payload"]:
                    f.write("**Request Payload (Nội dung Gửi đi):**\n")
                    f.write("```json\n")
                    f.write(
                        json.dumps(
                            call["request_payload"], indent=2, ensure_ascii=False
                        )
                    )
                    f.write("\n```\n\n")

                if call["response_body"]:
                    f.write("**Response Body (Nội dung Nhận về):**\n")
                    f.write("```json\n")
                    f.write(
                        json.dumps(call["response_body"], indent=2, ensure_ascii=False)
                    )
                    f.write("\n```\n\n")

                f.write("---\n\n")
        print_success(f"Tạo báo cáo {filename} thành công.")
    except Exception as e:
        print_error(f"Không thể ghi tệp báo cáo: {e}")


def get_auth_headers():
    """Returns formatted 'Authorization' headers."""
    if not access_token:
        print_error("Chưa đăng nhập. Không thể lấy headers.")
        return None
    return {
        "Authorization": f"Bearer {access_token}",
        "Content-Type": "application/json",
    }


# --- Test Functions ---


def test_login():
    """1. Login to get Access Token."""
    global access_token
    print_info("Đang thử đăng nhập với user: " + USERNAME)
    url = f"{BASE_URL}/api/v1/auth/login"
    payload = {"username": USERNAME, "password": PASSWORD}
    response_data = None
    status_code = 0
    try:
        response = requests.post(url, json=payload)
        status_code = response.status_code
        response_data = response.json()

        if response.status_code == 200:
            access_token = response_data.get("accessToken")
            if access_token:
                print_success("Đăng nhập thành công. Đã lấy Access Token.")
                log_api_call("POST", url, payload, status_code, response_data)
                return True
            else:
                print_error(
                    "Đăng nhập thành công nhưng không tìm thấy 'accessToken'.",
                    response_data,
                )
                log_api_call("POST", url, payload, status_code, response_data)
                return False
        else:
            print_error(
                f"Đăng nhập thất bại. Mã trạng thái: {response.status_code}",
                response_data,
            )
            log_api_call("POST", url, payload, status_code, response_data)
            return False

    except requests.exceptions.ConnectionError:
        print_error(f"Không thể kết nối đến {BASE_URL}. Hãy đảm bảo máy chủ đang chạy.")
        log_api_call("POST", url, payload, 503, {"error": "ConnectionError"})
        return False
    except Exception as e:
        print_error(f"Lỗi không xác định khi đăng nhập: {e}")
        log_api_call("POST", url, payload, 500, {"error": str(e)})
        return False


def test_create_class():
    """2. Test POST /api/v1/classes (Create Class)"""
    print_info("Đang thử tạo Lớp học mới...")
    url = f"{BASE_URL}/api/v1/classes"
    headers = get_auth_headers()
    if not headers:
        return None, None

    # Create unique data using timestamp
    ts = int(time.time())
    unique_suffix = ts % 10000
    unique_code = f"CL{unique_suffix}"  # Example: CL1234

    payload = {
        "code": unique_code,
        "subjectId": EXISTING_SUBJECT_ID,
        "semesterId": EXISTING_SEMESTER_ID,
    }

    response_data = None
    status_code = 0

    try:
        response = requests.post(url, headers=headers, json=payload)
        status_code = response.status_code
        response_data = response.json()

        if response.status_code == 201:
            class_id = response_data.get("data", {}).get("id")
            print_success(f"Tạo Lớp học thành công. ID mới: {class_id}")
            log_api_call("POST", url, payload, status_code, response_data)
            return class_id, unique_code
        else:
            print_error(
                f"Tạo Lớp học thất bại. Mã trạng thái: {response.status_code}",
                response_data,
            )
            log_api_call("POST", url, payload, status_code, response_data)
            return None, None
    except Exception as e:
        print_error(f"Lỗi không xác định khi tạo lớp học: {e}")
        log_api_call("POST", url, payload, 500, {"error": str(e)})
        return None, None


def test_get_class_by_id(class_id):
    """3. Test GET /api/v1/classes/{id} (Get Class by ID)"""
    print_info(f"Đang thử lấy Lớp học theo ID: {class_id}")
    url = f"{BASE_URL}/api/v1/classes/{class_id}"
    headers = get_auth_headers()
    if not headers:
        return

    response_data = None
    status_code = 0
    try:
        response = requests.get(url, headers=headers)
        status_code = response.status_code
        response_data = response.json()

        if response.status_code == 200:
            print_success(f"Lấy Lớp học {class_id} thành công.")
        else:
            print_error(
                f"Lấy Lớp học {class_id} thất bại. Mã trạng thái: {response.status_code}",
                response_data,
            )
    except Exception as e:
        print_error(f"Lỗi không xác định khi lấy lớp học {class_id}: {e}")
        status_code = 500
        response_data = {"error": str(e)}
    finally:
        log_api_call("GET", url, None, status_code, response_data)


def test_update_class(class_id, code):
    """4. Test PUT /api/v1/classes/{id} (Update Class)"""
    print_info(f"Đang thử cập nhật Lớp học ID: {class_id}")
    url = f"{BASE_URL}/api/v1/classes/{class_id}"
    headers = get_auth_headers()
    if not headers:
        return

    # Update semesterId and keep other fields
    payload = {
        "code": code,
        "subjectId": EXISTING_SUBJECT_ID,
        "semesterId": EXISTING_SEMESTER_ID + 1,  # Assuming semester 2 exists
        "isActive": True,
    }

    response_data = None
    status_code = 0
    try:
        response = requests.put(url, headers=headers, json=payload)
        status_code = response.status_code
        response_data = response.json()

        if response.status_code == 200:
            print_success(f"Cập nhật Lớp học {class_id} thành công.")
        else:
            print_error(
                f"Cập nhật Lớp học {class_id} thất bại. Mã trạng thái: {response.status_code}",
                response_data,
            )
    except Exception as e:
        print_error(f"Lỗi không xác định khi cập nhật lớp học {class_id}: {e}")
        status_code = 500
        response_data = {"error": str(e)}
    finally:
        log_api_call("PUT", url, payload, status_code, response_data)


def test_get_class_slots(class_id):
    """5. Test GET /api/v1/classes/{id}/slots (Get Slots of a Class)"""
    print_info(f"Đang thử lấy các slot của Lớp học ID: {class_id}")
    url = f"{BASE_URL}/api/v1/classes/{class_id}/slots?sort=desc&pageSize=10"
    headers = get_auth_headers()
    if not headers:
        return

    response_data = None
    status_code = 0
    try:
        response = requests.get(url, headers=headers)
        status_code = response.status_code
        response_data = response.json()

        if response.status_code == 200:
            count = len(response_data.get("data", {}).get("items", []))
            print_success(
                f"Lấy các slot của Lớp học {class_id} thành công. Tìm thấy: {count} slot."
            )
        else:
            print_error(
                f"Lấy các slot của Lớp học {class_id} thất bại. Mã trạng thái: {response.status_code}",
                response_data,
            )
    except Exception as e:
        print_error(f"Lỗi không xác định khi lấy các slot của lớp học {class_id}: {e}")
        status_code = 500
        response_data = {"error": str(e)}
    finally:
        log_api_call("GET", url, None, status_code, response_data)


def test_get_all_classes():
    """6. Test GET /api/v1/classes (Get list of Classes)"""
    print_info("Đang thử lấy danh sách Lớp học (sort desc, pageSize 10)")
    url = f"{BASE_URL}/api/v1/classes?sort=desc&pageSize=10"
    headers = get_auth_headers()
    if not headers:
        return

    response_data = None
    status_code = 0
    try:
        response = requests.get(url, headers=headers)
        status_code = response.status_code
        response_data = response.json()

        if response.status_code == 200:
            count = len(response_data.get("data", {}).get("items", []))
            print_success(
                f"Lấy danh sách Lớp học thành công. Tìm thấy: {count} lớp học."
            )
        else:
            print_error(
                f"Lấy danh sách Lớp học thất bại. Mã trạng thái: {response.status_code}",
                response_data,
            )
    except Exception as e:
        print_error(f"Lỗi không xác định khi lấy danh sách lớp học: {e}")
        status_code = 500
        response_data = {"error": str(e)}
    finally:
        log_api_call("GET", url, None, status_code, response_data)


# --- Start Error Test Functions ---


def test_create_class_errors():
    """7. Test error cases for POST /api/v1/classes (excluding duplication)"""
    print_info("Bắt đầu kiểm thử các trường hợp TẠO LỖI (dự kiến 400/404)")
    url = f"{BASE_URL}/api/v1/classes"
    headers = get_auth_headers()
    if not headers:
        return

    test_cases = [
        ("Code rỗng (CLASS_CODE_REQUIRED)", {"subjectId": 1, "semesterId": 1}),
        (
            "Subject ID rỗng (CLASS_SUBJECT_ID_REQUIRED)",
            {"code": "ERRC01", "semesterId": 1},
        ),
        (
            "Semester ID rỗng (CLASS_SEMESTER_ID_REQUIRED)",
            {"code": "ERRC01", "subjectId": 1},
        ),
        (
            "Code sai định dạng (INVALID_FIELD_FORMAT - chứa khoảng trắng)",
            {"code": "BAD CODE", "subjectId": 1, "semesterId": 1},
        ),
        (
            "Subject không tồn tại (SUBJECT_NOT_FOUND)",
            {"code": "ERRC02", "subjectId": 9999, "semesterId": 1},
        ),
        (
            "Semester không tồn tại (SEMESTER_NOT_FOUND)",
            {"code": "ERRC03", "subjectId": 1, "semesterId": 9999},
        ),
    ]

    for description, payload in test_cases:
        print_info(f"Đang thử lỗi: {description}")
        response_data = None
        status_code = 0
        try:
            response = requests.post(url, headers=headers, json=payload)
            status_code = response.status_code
            response_data = response.json()

            if 400 <= response.status_code < 500:
                print_success(
                    f"Kiểm thử lỗi '{description}' thành công. Nhận mã trạng thái: {status_code}"
                )
            else:
                print_error(
                    f"Kiểm thử lỗi '{description}' THẤT BẠI. Dự kiến 4xx nhưng nhận được {status_code}. Payload: {payload}",
                    response_data,
                )
        except json.JSONDecodeError:
            print_error(
                f"Kiểm thử lỗi '{description}' THẤT BẠI. Không thể giải mã JSON. Status: {status_code}. Raw: {response.text}"
            )
            response_data = {"raw_response": response.text}
        except Exception as e:
            print_error(f"Lỗi không xác định khi kiểm thử '{description}': {e}")
            status_code = 500
            response_data = {"error": str(e)}
        finally:
            log_api_call("POST", url, payload, status_code, response_data)


def test_duplicate_creation():
    """NEW: Self-contained test for duplicate creation (CLASS_EXISTS)"""
    print_info("Bắt đầu kiểm thử lỗi TẠO TRÙNG LẶP (CLASS_EXISTS)")
    url = f"{BASE_URL}/api/v1/classes"
    headers = get_auth_headers()
    if not headers:
        return

    # Create a unique code for this specific test
    ts = int(time.time())
    unique_code = f"DUP{ts % 10000}"
    payload = {
        "code": unique_code,
        "subjectId": EXISTING_SUBJECT_ID,
        "semesterId": EXISTING_SEMESTER_ID,
    }

    # Step 1: Create the class for the first time (should succeed)
    print_info(f"Tạo lớp '{unique_code}' lần đầu...")
    try:
        response1 = requests.post(url, headers=headers, json=payload)
        if response1.status_code != 201:
            print_error(
                f"Không thể tạo lớp ban đầu để kiểm thử trùng lặp. Bỏ qua.",
                response1.json(),
            )
            log_api_call("POST", url, payload, response1.status_code, response1.json())
            return
        print_success(f"Tạo lớp '{unique_code}' lần đầu thành công.")
        log_api_call("POST", url, payload, response1.status_code, response1.json())
    except Exception as e:
        print_error(f"Lỗi khi tạo lớp ban đầu: {e}")
        log_api_call("POST", url, payload, 500, {"error": str(e)})
        return

    # Step 2: Try to create the exact same class again (should fail)
    print_info(f"Tạo lớp '{unique_code}' lần hai (dự kiến lỗi)...")
    response_data = None
    status_code = 0
    try:
        response2 = requests.post(url, headers=headers, json=payload)
        status_code = response2.status_code
        response_data = response2.json()

        if status_code == 400:
            print_success(
                f"Kiểm thử lỗi 'CLASS_EXISTS' thành công. Nhận mã trạng thái: {status_code}"
            )
        else:
            print_error(
                f"Kiểm thử lỗi 'CLASS_EXISTS' THẤT BẠI. Dự kiến 400 nhưng nhận được {status_code}",
                response_data,
            )
    except Exception as e:
        print_error(f"Lỗi không xác định khi kiểm thử trùng lặp: {e}")
        status_code = 500
        response_data = {"error": str(e)}
    finally:
        log_api_call("POST", url, payload, status_code, response_data)


def test_get_class_by_id_errors():
    """8. Test error cases for GET /api/v1/classes/{id}"""
    print_info("Bắt đầu kiểm thử các trường hợp LẤY LỖI (dự kiến 400/404)")
    headers = get_auth_headers()
    if not headers:
        return

    test_cases = [
        # CORRECTED: Use an ID within the Short range but likely non-existent
        ("ID không tồn tại (CLASS_NOT_FOUND)", f"{BASE_URL}/api/v1/classes/32000", 404),
        (
            "ID sai định dạng (INVALID_FIELD_TYPE)",
            f"{BASE_URL}/api/v1/classes/abc",
            400,
        ),
    ]

    for description, url, expected_status in test_cases:
        print_info(f"Đang thử lỗi: {description}")
        response_data = None
        status_code = 0
        try:
            response = requests.get(url, headers=headers)
            status_code = response.status_code
            try:
                response_data = response.json()
            except json.JSONDecodeError:
                response_data = {"raw_response": response.text}

            if response.status_code == expected_status:
                print_success(
                    f"Kiểm thử lỗi '{description}' thành công. Nhận mã trạng thái: {status_code}"
                )
            else:
                print_error(
                    f"Kiểm thử lỗi '{description}' THẤT BẠI. Dự kiến {expected_status} nhưng nhận được {status_code}",
                    response_data,
                )
        except Exception as e:
            print_error(f"Lỗi không xác định khi kiểm thử '{description}': {e}")
            status_code = 500
            response_data = {"error": str(e)}
        finally:
            log_api_call("GET", url, None, status_code, response_data)


# --- Main Function ---


def main():
    """Runs the test cycle."""

    # 1. Login
    if not test_login():
        print_error("Không thể tiếp tục nếu không đăng nhập. Đang thoát.")
        generate_markdown_report()
        return

    print("=" * 30)

    # 2. Run "Happy Path" cycle: Create -> Get -> Update
    print_info("Bắt đầu chạy luồng kiểm thử 'Happy Path'")
    new_id, new_code = test_create_class()

    if new_id:
        print("-" * 30)
        test_get_class_by_id(new_id)
        print("-" * 30)
        test_update_class(new_id, new_code)
        print("-" * 30)
        test_get_class_slots(new_id)
    else:
        print_error(
            "Không thể tạo Lớp học. Bỏ qua các bài kiểm thử phụ thuộc 'Happy Path'."
        )

    print("=" * 30)

    # 3. Run "Error Cases" tests
    print_info("Bắt đầu chạy các bài kiểm thử lỗi (Error Cases)")
    test_create_class_errors()  # Test basic creation errors
    print("-" * 30)
    test_duplicate_creation()  # NEW: Test duplication in isolation
    print("-" * 30)
    test_get_class_by_id_errors()  # Test GET errors

    print("=" * 30)

    # 4. Test Get List API (runs independently)
    test_get_all_classes()
    print("=" * 30)

    print_info("Tất cả các bài kiểm thử đã hoàn tất.")

    # 5. GENERATE REPORT
    generate_markdown_report()


if __name__ == "__main__":
    main()
