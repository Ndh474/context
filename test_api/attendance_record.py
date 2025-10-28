import requests
import json
import time
import sys
import codecs
from datetime import datetime, timedelta

# Sửa lỗi UnicodeEncodeError trên Windows Console
# Buộc stdout sử dụng mã hóa UTF-8
sys.stdout = codecs.getwriter("utf-8")(sys.stdout.buffer)

# --- CẤU HÌNH ---
# TODO: THAY ĐỔI GIÁ TRỊ NÀY thành URL máy chủ của bạn
BASE_URL = "http://localhost:8080"
USERNAME = "dop001"
PASSWORD = "12345678"
# ----------------

# Biến toàn cục
access_token = None
report_data = []


# --- Các hàm trợ giúp (Helpers) ---
def print_success(message):
    """In thông báo thành công (màu xanh lá)."""
    print(f"\033[92m[THÀNH CÔNG] {message}\033[0m")


def print_error(message, data=None):
    """In thông báo lỗi (màu đỏ)."""
    print(f"\033[91m[LỖI] {message}\033[0m")
    if data:
        # Đảm bảo in JSON tiếng Việt đúng
        print(f"\033[91m      {json.dumps(data, indent=2, ensure_ascii=False)}\033[0m")


def print_info(message):
    """In thông báo thông tin (màu xanh dương)."""
    print(f"\033[94m[THÔNG TIN] {message}\033[0m")


def log_api_call(method, url, request_payload, response_status, response_body):
    """Lưu trữ chi tiết cuộc gọi API để tạo báo cáo."""
    report_data.append(
        {
            "method": method,
            "url": url,
            "request_payload": request_payload,
            "response_status": response_status,
            "response_body": response_body,
        }
    )


def generate_markdown_report(filename="api_test_report_attendance_records.md"):
    """Tạo tệp Markdown từ dữ liệu đã lưu trữ."""
    print_info(f"Đang tạo báo cáo Markdown: {filename}")
    try:
        with open(filename, "w", encoding="utf-8") as f:
            f.write(
                f"# Báo cáo Kiểm thử API - Attendance Records ({time.strftime('%Y-%m-%d %H:%M:%S')})\n\n"
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
    """Trả về headers 'Authorization' đã được định dạng."""
    if not access_token:
        print_error("Chưa đăng nhập. Không thể lấy headers.")
        return None
    return {
        "Authorization": f"Bearer {access_token}",
        "Content-Type": "application/json",
    }


# --- Các hàm Kiểm thử (Test Functions) ---


def test_login():
    """1. Đăng nhập để lấy Access Token."""
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


def test_get_all_attendance_records():
    """2. Kiểm thử GET /api/v1/attendance-records (Lấy danh sách Attendance Records)"""
    print_info("Đang thử lấy danh sách Attendance Records (sort desc, pageSize 10)")
    url = f"{BASE_URL}/api/v1/attendance-records?sort=desc&pageSize=10"
    headers = get_auth_headers()
    if not headers:
        return None

    response_data = None
    status_code = 0
    first_record_id = None
    try:
        response = requests.get(url, headers=headers)
        status_code = response.status_code
        response_data = response.json()

        if response.status_code == 200:
            items = response_data.get("data", {}).get("items", [])
            count = len(items)
            print_success(
                f"Lấy danh sách Attendance Records thành công. Tìm thấy: {count} records."
            )
            # Get first record ID if available
            if items and len(items) > 0:
                first_record_id = items[0].get("id")
        else:
            print_error(
                f"Lấy danh sách Attendance Records thất bại. Mã trạng thái: {response.status_code}",
                response_data,
            )
    except Exception as e:
        print_error(f"Lỗi không xác định khi lấy danh sách attendance records: {e}")
        status_code = 500
        response_data = {"error": str(e)}
    finally:
        log_api_call("GET", url, None, status_code, response_data)

    return first_record_id


def test_get_attendance_record_by_id(record_id):
    """3. Kiểm thử GET /api/v1/attendance-records/{id} (Lấy Attendance Record theo ID)"""
    print_info(f"Đang thử lấy Attendance Record theo ID: {record_id}")
    url = f"{BASE_URL}/api/v1/attendance-records/{record_id}"
    headers = get_auth_headers()
    if not headers:
        return None

    response_data = None
    status_code = 0
    try:
        response = requests.get(url, headers=headers)
        status_code = response.status_code
        response_data = response.json()

        if response.status_code == 200:
            print_success(f"Lấy Attendance Record {record_id} thành công.")
            # Return the record data for update test (logging handled in finally block)
            return response_data.get("data")
        else:
            print_error(
                f"Lấy Attendance Record {record_id} thất bại. Mã trạng thái: {response.status_code}",
                response_data,
            )
    except Exception as e:
        print_error(f"Lỗi không xác định khi lấy attendance record {record_id}: {e}")
        status_code = 500
        response_data = {"error": str(e)}
    finally:
        log_api_call("GET", url, None, status_code, response_data)

    return None


def test_update_attendance_record(record_id):
    """4. Kiểm thử PUT /api/v1/attendance-records/{id} (Cập nhật Attendance Record)"""
    print_info(f"Đang thử cập nhật Attendance Record ID: {record_id}")
    url = f"{BASE_URL}/api/v1/attendance-records/{record_id}"
    headers = get_auth_headers()
    if not headers:
        return

    payload = {
        "status": "present",
        "remark": "Cập nhật thủ công để kiểm thử API - Student arrived late but provided valid reason",
    }

    response_data = None
    status_code = 0
    try:
        response = requests.put(url, headers=headers, json=payload)
        status_code = response.status_code
        response_data = response.json()

        if response.status_code == 200:
            print_success(f"Cập nhật Attendance Record {record_id} thành công.")
        else:
            print_error(
                f"Cập nhật Attendance Record {record_id} thất bại. Mã trạng thái: {response.status_code}",
                response_data,
            )
    except Exception as e:
        print_error(
            f"Lỗi không xác định khi cập nhật attendance record {record_id}: {e}"
        )
        status_code = 500
        response_data = {"error": str(e)}
    finally:
        log_api_call("PUT", url, payload, status_code, response_data)


def test_get_attendance_with_filters():
    """5. Kiểm thử GET /api/v1/attendance-records với các filters"""
    print_info("Đang thử lấy Attendance Records với filters (status=present)")
    url = f"{BASE_URL}/api/v1/attendance-records?status=present&pageSize=10"
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
                f"Lấy Attendance Records với filter thành công. Tìm thấy: {count} records."
            )
        else:
            print_error(
                f"Lấy Attendance Records với filter thất bại. Mã trạng thái: {response.status_code}",
                response_data,
            )
    except Exception as e:
        print_error(f"Lỗi không xác định khi lấy attendance records với filter: {e}")
        status_code = 500
        response_data = {"error": str(e)}
    finally:
        log_api_call("GET", url, None, status_code, response_data)


# --- Bắt đầu các hàm kiểm thử lỗi ---


def test_get_attendance_record_errors():
    """6. Kiểm thử các trường hợp lỗi của GET /api/v1/attendance-records/{id}"""
    print_info("Bắt đầu kiểm thử các trường hợp LẤY LỖI (dự kiến 400/404)")
    headers = get_auth_headers()
    if not headers:
        return

    test_cases = [
        (
            "ID không tồn tại (ATTENDANCE_RECORD_NOT_FOUND)",
            f"{BASE_URL}/api/v1/attendance-records/999999999",
            404,
        ),
        (
            "ID sai định dạng (INVALID_FIELD_TYPE)",
            f"{BASE_URL}/api/v1/attendance-records/abc",
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


def test_update_attendance_record_errors():
    """7. Kiểm thử các trường hợp lỗi của PUT /api/v1/attendance-records/{id}"""
    print_info("Bắt đầu kiểm thử các trường hợp CẬP NHẬT LỖI (dự kiến 400)")

    # First get a valid record ID
    print_info("Lấy một attendance record để test lỗi...")
    url_list = f"{BASE_URL}/api/v1/attendance-records?pageSize=1"
    headers = get_auth_headers()
    if not headers:
        return

    valid_record_id = None
    try:
        response = requests.get(url_list, headers=headers)
        if response.status_code == 200:
            items = response.json().get("data", {}).get("items", [])
            if items:
                valid_record_id = items[0].get("id")
    except:
        pass

    if not valid_record_id:
        print_error("Không thể lấy record ID hợp lệ để test lỗi. Bỏ qua.")
        return

    url = f"{BASE_URL}/api/v1/attendance-records/{valid_record_id}"

    test_cases = [
        ("Status rỗng (STATUS_REQUIRED)", {"remark": "Test remark"}),
        ("Remark rỗng (REMARK_REQUIRED)", {"status": "present", "remark": ""}),
        (
            "Status không hợp lệ (INVALID_STATUS_VALUE)",
            {"status": "invalid_status", "remark": "Test remark"},
        ),
        ("Thiếu remark (REMARK_REQUIRED)", {"status": "absent"}),
    ]

    for description, payload in test_cases:
        print_info(f"Đang thử lỗi: {description}")
        response_data = None
        status_code = 0
        try:
            response = requests.put(url, headers=headers, json=payload)
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
            log_api_call("PUT", url, payload, status_code, response_data)


def test_search_with_invalid_params():
    """8. Kiểm thử search với parameters không hợp lệ"""
    print_info("Bắt đầu kiểm thử SEARCH với parameters không hợp lệ (dự kiến 400)")
    headers = get_auth_headers()
    if not headers:
        return

    test_cases = [
        ("Page âm (INVALID_PAGE)", f"{BASE_URL}/api/v1/attendance-records?page=-1"),
        (
            "Sort không hợp lệ (INVALID_SORT)",
            f"{BASE_URL}/api/v1/attendance-records?sort=invalid&pageSize=10",
        ),
        (
            "Status không hợp lệ (INVALID_STATUS)",
            f"{BASE_URL}/api/v1/attendance-records?status=invalid_status&pageSize=10",
        ),
    ]

    for description, url in test_cases:
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

            if response.status_code == 400:
                print_success(
                    f"Kiểm thử lỗi '{description}' thành công. Nhận mã trạng thái: 400"
                )
            else:
                print_error(
                    f"Kiểm thử lỗi '{description}' THẤT BẠI. Dự kiến 400 nhưng nhận được {status_code}",
                    response_data,
                )
        except Exception as e:
            print_error(f"Lỗi không xác định khi kiểm thử '{description}': {e}")
            status_code = 500
            response_data = {"error": str(e)}
        finally:
            log_api_call("GET", url, None, status_code, response_data)


# --- Hàm chính (Main) ---


def main():
    """Chạy chu trình kiểm thử."""

    # 1. Đăng nhập
    if not test_login():
        print_error("Không thể tiếp tục nếu không đăng nhập. Đang thoát.")
        generate_markdown_report()
        return

    print("=" * 30)

    # 2. Chạy chu trình "Happy Path"
    print_info("Bắt đầu chạy luồng kiểm thử 'Happy Path'")

    # Get list of attendance records
    first_record_id = test_get_all_attendance_records()

    if first_record_id:
        print("-" * 30)
        # Get specific record by ID
        record_data = test_get_attendance_record_by_id(first_record_id)

        if record_data:
            print("-" * 30)
            # Update the record
            test_update_attendance_record(first_record_id)
    else:
        print_error(
            "Không có attendance records để test. Bỏ qua các bài kiểm thử 'Happy Path'."
        )

    print("-" * 30)
    # Test with filters
    test_get_attendance_with_filters()

    print("=" * 30)

    # 3. Chạy các bài kiểm thử lỗi
    print_info("Bắt đầu chạy các bài kiểm thử lỗi (Error Cases)")
    test_get_attendance_record_errors()
    print("-" * 30)
    test_update_attendance_record_errors()
    print("-" * 30)
    test_search_with_invalid_params()

    print("=" * 30)

    print_info("Tất cả các bài kiểm thử đã hoàn tất.")

    # 4. TẠO BÁO CÁO
    generate_markdown_report()


if __name__ == "__main__":
    main()
