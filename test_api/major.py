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


def generate_markdown_report(filename="api_test_report_majors.md"):
    """Creates a Markdown file from the stored API call data."""
    print_info(f"Đang tạo báo cáo Markdown: {filename}")
    try:
        with open(filename, "w", encoding="utf-8") as f:
            f.write(
                f"# Báo cáo Kiểm thử API - Majors ({time.strftime('%Y-%m-%d %H:%M:%S')})\n\n"
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


def test_create_major():
    """2. Test POST /api/v1/majors (Create Major)"""
    print_info("Đang thử tạo Chuyên ngành mới...")
    url = f"{BASE_URL}/api/v1/majors"
    headers = get_auth_headers()
    if not headers:
        return None, None, None

    # Create unique data using timestamp
    ts = int(time.time())
    unique_suffix = ts % 10000
    unique_code = f"M{unique_suffix}"  # Example: M1234
    unique_name = f"Major Test {unique_suffix}"

    payload = {"name": unique_name, "code": unique_code}

    response_data = None
    status_code = 0

    try:
        response = requests.post(url, headers=headers, json=payload)
        status_code = response.status_code
        response_data = response.json()

        if response.status_code == 201:
            major_id = response_data.get("data", {}).get("id")
            print_success(f"Tạo Chuyên ngành thành công. ID mới: {major_id}")
            log_api_call("POST", url, payload, status_code, response_data)
            # Return unique values for duplicate error testing
            return major_id, unique_code, unique_name
        else:
            print_error(
                f"Tạo Chuyên ngành thất bại. Mã trạng thái: {response.status_code}",
                response_data,
            )
            log_api_call("POST", url, payload, status_code, response_data)
            return None, None, None
    except Exception as e:
        print_error(f"Lỗi không xác định khi tạo chuyên ngành: {e}")
        log_api_call("POST", url, payload, 500, {"error": str(e)})
        return None, None, None


def test_get_major_by_id(major_id):
    """3. Test GET /api/v1/majors/{id} (Get Major by ID)"""
    print_info(f"Đang thử lấy Chuyên ngành theo ID: {major_id}")
    url = f"{BASE_URL}/api/v1/majors/{major_id}"
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
            print_success(f"Lấy Chuyên ngành {major_id} thành công.")
        else:
            print_error(
                f"Lấy Chuyên ngành {major_id} thất bại. Mã trạng thái: {response.status_code}",
                response_data,
            )
    except Exception as e:
        print_error(f"Lỗi không xác định khi lấy chuyên ngành {major_id}: {e}")
        status_code = 500
        response_data = {"error": str(e)}
    finally:
        log_api_call("GET", url, None, status_code, response_data)


def test_update_major(major_id, code):
    """4. Test PUT /api/v1/majors/{id} (Update Major)"""
    print_info(f"Đang thử cập nhật Chuyên ngành ID: {major_id}")
    url = f"{BASE_URL}/api/v1/majors/{major_id}"
    headers = get_auth_headers()
    if not headers:
        return

    # Update only the name
    payload = {
        "name": f"Updated Major {code}",
        "code": code,
        "isActive": True,  # Keep it active
    }

    response_data = None
    status_code = 0
    try:
        response = requests.put(url, headers=headers, json=payload)
        status_code = response.status_code
        response_data = response.json()

        if response.status_code == 200:
            print_success(f"Cập nhật Chuyên ngành {major_id} thành công.")
        else:
            print_error(
                f"Cập nhật Chuyên ngành {major_id} thất bại. Mã trạng thái: {response.status_code}",
                response_data,
            )
    except Exception as e:
        print_error(f"Lỗi không xác định khi cập nhật chuyên ngành {major_id}: {e}")
        status_code = 500
        response_data = {"error": str(e)}
    finally:
        log_api_call("PUT", url, payload, status_code, response_data)


def test_get_major_subjects(major_id):
    """5. Test GET /api/v1/majors/{id}/subjects (Get Subjects of Major)"""
    print_info(f"Đang thử lấy các môn học của Chuyên ngành ID: {major_id}")
    # Comply with request: sort=desc & pageSize=10
    url = f"{BASE_URL}/api/v1/majors/{major_id}/subjects?sort=desc&pageSize=10"
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
                f"Lấy các môn học của Chuyên ngành {major_id} thành công. Tìm thấy: {count} môn."
            )
        else:
            print_error(
                f"Lấy các môn học của Chuyên ngành {major_id} thất bại. Mã trạng thái: {response.status_code}",
                response_data,
            )
    except Exception as e:
        print_error(
            f"Lỗi không xác định khi lấy các môn học của chuyên ngành {major_id}: {e}"
        )
        status_code = 500
        response_data = {"error": str(e)}
    finally:
        log_api_call("GET", url, None, status_code, response_data)


def test_get_all_majors():
    """6. Test GET /api/v1/majors (Get list of Majors)"""
    print_info("Đang thử lấy danh sách Chuyên ngành (sort desc, pageSize 10)")
    # Comply with request: sort=desc & pageSize=10
    url = f"{BASE_URL}/api/v1/majors?sort=desc&pageSize=10"
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
                f"Lấy danh sách Chuyên ngành thành công. Tìm thấy: {count} chuyên ngành."
            )
        else:
            print_error(
                f"Lấy danh sách Chuyên ngành thất bại. Mã trạng thái: {response.status_code}",
                response_data,
            )
    except Exception as e:
        print_error(f"Lỗi không xác định khi lấy danh sách chuyên ngành: {e}")
        status_code = 500
        response_data = {"error": str(e)}
    finally:
        log_api_call("GET", url, None, status_code, response_data)


# --- Start Error Test Functions ---


def test_create_major_errors(existing_code, existing_name):
    """7. Test error cases for POST /api/v1/majors"""
    print_info("Bắt đầu kiểm thử các trường hợp TẠO LỖI (dự kiến 400)")
    url = f"{BASE_URL}/api/v1/majors"
    headers = get_auth_headers()
    if not headers:
        return

    test_cases = [
        ("Tên rỗng (MAJOR_NAME_REQUIRED)", {"name": "", "code": "ERRM01"}),
        ("Code rỗng (MAJOR_CODE_REQUIRED)", {"name": "Test Major", "code": ""}),
        # Ensure existing_code is not None before using it
        (
            "Code đã tồn tại (MAJOR_CODE_EXISTS)",
            {"name": "Test Major Dup Code", "code": existing_code or "SE"},
        ),
        # Ensure existing_name is not None before using it
        (
            "Tên đã tồn tại (MAJOR_NAME_EXISTS)",
            {"name": existing_name or "Software Engineering", "code": "ERRM02"},
        ),
        (
            "Code sai định dạng (INVALID_FIELD_FORMAT - chứa khoảng trắng)",
            {"name": "Test Major Bad Code", "code": "BAD CODE"},
        ),
        (
            "Tên sai định dạng (INVALID_FIELD_FORMAT - khoảng trắng thừa)",
            {"name": "  Test Major Bad Name  ", "code": "ERRM03"},
        ),
        (
            "Tên chứa ký tự không hợp lệ",
            {"name": "Major @!#", "code": "ERRM04"},
        ),  # Based on pattern ^[A-Za-z0-9&-]+( [A-Za-z0-9&-]+)*$
    ]

    for description, payload in test_cases:
        print_info(f"Đang thử lỗi: {description}")
        response_data = None
        status_code = 0
        try:
            response = requests.post(url, headers=headers, json=payload)
            status_code = response.status_code
            response_data = response.json()

            if 400 <= response.status_code < 500:  # Expect 400
                print_success(
                    f"Kiểm thử lỗi '{description}' thành công. Nhận mã trạng thái: {status_code}"
                )
            else:
                # Print payload when error test fails for debugging
                print_error(
                    f"Kiểm thử lỗi '{description}' THẤT BẠI. Dự kiến 4xx nhưng nhận được {status_code}. Payload: {payload}",
                    response_data,
                )
        except json.JSONDecodeError:
            print_error(
                f"Kiểm thử lỗi '{description}' THẤT BẠI. Không thể giải mã JSON từ phản hồi. Status: {status_code}. Raw response: {response.text}"
            )
            response_data = {"raw_response": response.text}
        except Exception as e:
            print_error(f"Lỗi không xác định khi kiểm thử '{description}': {e}")
            status_code = 500
            response_data = {"error": str(e)}
        finally:
            log_api_call("POST", url, payload, status_code, response_data)


def test_get_major_by_id_errors():
    """8. Test error cases for GET /api/v1/majors/{id}"""
    print_info("Bắt đầu kiểm thử các trường hợp LẤY LỖI (dự kiến 400/404)")
    headers = get_auth_headers()
    if not headers:
        return

    test_cases = [
        ("ID không tồn tại (MAJOR_NOT_FOUND)", f"{BASE_URL}/api/v1/majors/9999", 404),
        ("ID sai định dạng (INVALID_FIELD_TYPE)", f"{BASE_URL}/api/v1/majors/abc", 400),
    ]

    for description, url, expected_status in test_cases:
        print_info(f"Đang thử lỗi: {description}")
        response_data = None
        status_code = 0
        try:
            response = requests.get(url, headers=headers)
            status_code = response.status_code
            # GET 400 errors might not return valid JSON
            try:
                response_data = response.json()
            except json.JSONDecodeError:
                response_data = {"raw_response": response.text}  # Log raw response

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
        generate_markdown_report("api_test_report_majors.md")
        return

    print("-" * 30)

    # 2. Run Create -> Get -> Update -> Get related resources cycle
    new_id, new_code, new_name = test_create_major()

    if new_id:
        print("-" * 30)
        test_get_major_by_id(new_id)
        print("-" * 30)
        test_update_major(new_id, new_code)
        print("-" * 30)
        test_get_major_subjects(new_id)

        # Run error tests (need values from successful creation)
        print("=" * 30)
        print_info("Bắt đầu chạy các bài kiểm thử lỗi (Error Cases)")
        # Make sure values are not None before passing
        if all([new_code, new_name]):
            test_create_major_errors(new_code, new_name)
        else:
            print_error(
                "Thiếu dữ liệu (code, name) từ lần tạo thành công, không thể chạy kiểm thử lỗi tạo."
            )
            # Run with default placeholder values if creation failed but we want error tests anyway
            test_create_major_errors("SE", "Software Engineering")

        print("-" * 30)
        test_get_major_by_id_errors()

    else:
        print_error("Không thể tạo Chuyên ngành. Bỏ qua các bài kiểm thử phụ thuộc.")
        # Still run error tests (both create and get) with placeholder/default values
        print("=" * 30)
        print_info(
            "Bắt đầu chạy các bài kiểm thử lỗi (Error Cases) với giá trị giả lập"
        )
        test_create_major_errors("SE", "Software Engineering")  # Use placeholder values
        print("-" * 30)
        test_get_major_by_id_errors()

    print("=" * 30)

    # 3. Test Get List API (runs independently)
    test_get_all_majors()
    print("=" * 30)

    print_info("Tất cả các bài kiểm thử đã hoàn tất.")

    # 4. GENERATE REPORT
    generate_markdown_report("api_test_report_majors.md")


if __name__ == "__main__":
    main()
