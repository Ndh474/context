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


def generate_markdown_report(filename="api_test_report_regular_attendance_remarks.md"):
    """Tạo tệp Markdown từ dữ liệu đã lưu trữ."""
    print_info(f"Đang tạo báo cáo Markdown: {filename}")
    try:
        with open(filename, "w", encoding="utf-8") as f:
            f.write(
                f"# Báo cáo Kiểm thử API - Regular Attendance Remarks ({time.strftime('%Y-%m-%d %H:%M:%S')})\n\n"
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


def get_attendance_record_id():
    """Lấy một attendance record ID để test."""
    print_info("Đang lấy một attendance record ID để test remarks...")
    url = f"{BASE_URL}/api/v1/attendance-records?pageSize=1"
    headers = get_auth_headers()
    if not headers:
        return None

    try:
        response = requests.get(url, headers=headers)
        if response.status_code == 200:
            items = response.json().get("data", {}).get("items", [])
            if items:
                record_id = items[0].get("id")
                print_success(f"Đã lấy attendance record ID: {record_id}")
                return record_id
    except Exception as e:
        print_error(f"Lỗi khi lấy attendance record ID: {e}")

    return None


def test_create_remark(attendance_record_id):
    """2. Kiểm thử POST /api/v1/attendance-records/{attendanceRecordId}/remarks (Tạo remark)"""
    print_info(f"Đang thử tạo remark cho attendance record ID: {attendance_record_id}")
    url = f"{BASE_URL}/api/v1/attendance-records/{attendance_record_id}/remarks"
    headers = get_auth_headers()
    if not headers:
        return None

    payload = {
        "remark": "Student arrived 10 minutes late but was allowed to attend - Test remark creation"
    }

    response_data = None
    status_code = 0
    remark_id = None
    try:
        response = requests.post(url, headers=headers, json=payload)
        status_code = response.status_code
        response_data = response.json()

        if response.status_code == 201:
            remark_id = response_data.get("data", {}).get("id")
            print_success(f"Tạo remark thành công. Remark ID: {remark_id}")
            return remark_id
        else:
            print_error(
                f"Tạo remark thất bại. Mã trạng thái: {response.status_code}",
                response_data,
            )
    except Exception as e:
        print_error(f"Lỗi không xác định khi tạo remark: {e}")
        status_code = 500
        response_data = {"error": str(e)}
    finally:
        log_api_call("POST", url, payload, status_code, response_data)

    return None


def test_get_remarks(attendance_record_id):
    """3. Kiểm thử GET /api/v1/attendance-records/{attendanceRecordId}/remarks (Lấy danh sách remarks)"""
    print_info(f"Đang thử lấy danh sách remarks cho attendance record ID: {attendance_record_id}")
    url = f"{BASE_URL}/api/v1/attendance-records/{attendance_record_id}/remarks"
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
            items = response_data.get("data", {}).get("items", [])
            count = len(items)
            print_success(
                f"Lấy danh sách remarks thành công. Tìm thấy: {count} remarks."
            )
        else:
            print_error(
                f"Lấy danh sách remarks thất bại. Mã trạng thái: {response.status_code}",
                response_data,
            )
    except Exception as e:
        print_error(f"Lỗi không xác định khi lấy danh sách remarks: {e}")
        status_code = 500
        response_data = {"error": str(e)}
    finally:
        log_api_call("GET", url, None, status_code, response_data)


def test_update_remark(remark_id):
    """4. Kiểm thử PUT /api/v1/attendance-records/remarks/{remarkId} (Cập nhật remark)"""
    print_info(f"Đang thử cập nhật remark ID: {remark_id}")
    url = f"{BASE_URL}/api/v1/attendance-records/remarks/{remark_id}"
    headers = get_auth_headers()
    if not headers:
        return

    payload = {
        "remark": "Student arrived 15 minutes late (updated) - Test remark update"
    }

    response_data = None
    status_code = 0
    try:
        response = requests.put(url, headers=headers, json=payload)
        status_code = response.status_code
        response_data = response.json()

        if response.status_code == 200:
            print_success(f"Cập nhật remark {remark_id} thành công.")
        else:
            print_error(
                f"Cập nhật remark {remark_id} thất bại. Mã trạng thái: {response.status_code}",
                response_data,
            )
    except Exception as e:
        print_error(f"Lỗi không xác định khi cập nhật remark {remark_id}: {e}")
        status_code = 500
        response_data = {"error": str(e)}
    finally:
        log_api_call("PUT", url, payload, status_code, response_data)


def test_delete_remark(remark_id):
    """5. Kiểm thử DELETE /api/v1/attendance-records/remarks/{remarkId} (Xóa remark)"""
    print_info(f"Đang thử xóa remark ID: {remark_id}")
    url = f"{BASE_URL}/api/v1/attendance-records/remarks/{remark_id}"
    headers = get_auth_headers()
    if not headers:
        return

    response_data = None
    status_code = 0
    try:
        response = requests.delete(url, headers=headers)
        status_code = response.status_code
        try:
            response_data = response.json()
        except json.JSONDecodeError:
            response_data = {"raw_response": response.text}

        if response.status_code == 200:
            print_success(f"Xóa remark {remark_id} thành công.")
        else:
            print_error(
                f"Xóa remark {remark_id} thất bại. Mã trạng thái: {response.status_code}",
                response_data,
            )
    except Exception as e:
        print_error(f"Lỗi không xác định khi xóa remark {remark_id}: {e}")
        status_code = 500
        response_data = {"error": str(e)}
    finally:
        log_api_call("DELETE", url, None, status_code, response_data)


# --- Bắt đầu các hàm kiểm thử lỗi ---


def test_create_remark_errors():
    """6. Kiểm thử các trường hợp lỗi của POST /api/v1/attendance-records/{attendanceRecordId}/remarks"""
    print_info("Bắt đầu kiểm thử các trường hợp TẠO REMARK LỖI (dự kiến 400/404)")
    headers = get_auth_headers()
    if not headers:
        return

    # Get a valid attendance record ID
    attendance_record_id = get_attendance_record_id()
    if not attendance_record_id:
        print_error("Không thể lấy attendance record ID. Bỏ qua test lỗi.")
        return

    test_cases = [
        (
            "Remark rỗng (REMARK_REQUIRED)",
            f"{BASE_URL}/api/v1/attendance-records/{attendance_record_id}/remarks",
            {},
            400,
        ),
        (
            "Remark là chuỗi trống (REMARK_CANNOT_BE_EMPTY)",
            f"{BASE_URL}/api/v1/attendance-records/{attendance_record_id}/remarks",
            {"remark": ""},
            400,
        ),
        (
            "Remark là chuỗi chỉ chứa khoảng trắng (REMARK_CANNOT_BE_EMPTY)",
            f"{BASE_URL}/api/v1/attendance-records/{attendance_record_id}/remarks",
            {"remark": "   "},
            400,
        ),
        (
            "Attendance record không tồn tại (ATTENDANCE_RECORD_NOT_FOUND)",
            f"{BASE_URL}/api/v1/attendance-records/999999999/remarks",
            {"remark": "Test remark"},
            404,
        ),
        (
            "Attendance record ID sai định dạng (INVALID_FIELD_TYPE)",
            f"{BASE_URL}/api/v1/attendance-records/abc/remarks",
            {"remark": "Test remark"},
            400,
        ),
    ]

    for description, url, payload, expected_status in test_cases:
        print_info(f"Đang thử lỗi: {description}")
        response_data = None
        status_code = 0
        try:
            response = requests.post(url, headers=headers, json=payload)
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
            log_api_call("POST", url, payload, status_code, response_data)


def test_get_remarks_errors():
    """7. Kiểm thử các trường hợp lỗi của GET /api/v1/attendance-records/{attendanceRecordId}/remarks"""
    print_info("Bắt đầu kiểm thử các trường hợp LẤY REMARKS LỖI (dự kiến 400/404)")
    headers = get_auth_headers()
    if not headers:
        return

    test_cases = [
        (
            "Attendance record không tồn tại (ATTENDANCE_RECORD_NOT_FOUND)",
            f"{BASE_URL}/api/v1/attendance-records/999999999/remarks",
            404,
        ),
        (
            "Attendance record ID sai định dạng (INVALID_FIELD_TYPE)",
            f"{BASE_URL}/api/v1/attendance-records/abc/remarks",
            400,
        ),
        (
            "Page âm (INVALID_PAGE)",
            f"{BASE_URL}/api/v1/attendance-records/1/remarks?page=-1",
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


def test_update_remark_errors():
    """8. Kiểm thử các trường hợp lỗi của PUT /api/v1/attendance-records/remarks/{remarkId}"""
    print_info("Bắt đầu kiểm thử các trường hợp CẬP NHẬT REMARK LỖI (dự kiến 400/404)")
    headers = get_auth_headers()
    if not headers:
        return

    test_cases = [
        (
            "Remark rỗng (REMARK_REQUIRED)",
            f"{BASE_URL}/api/v1/attendance-records/remarks/1",
            {},
            400,
        ),
        (
            "Remark là chuỗi trống (REMARK_CANNOT_BE_EMPTY)",
            f"{BASE_URL}/api/v1/attendance-records/remarks/1",
            {"remark": ""},
            400,
        ),
        (
            "Remark ID không tồn tại (REMARK_NOT_FOUND)",
            f"{BASE_URL}/api/v1/attendance-records/remarks/999999999",
            {"remark": "Test remark"},
            404,
        ),
        (
            "Remark ID sai định dạng (INVALID_FIELD_TYPE)",
            f"{BASE_URL}/api/v1/attendance-records/remarks/abc",
            {"remark": "Test remark"},
            400,
        ),
    ]

    for description, url, payload, expected_status in test_cases:
        print_info(f"Đang thử lỗi: {description}")
        response_data = None
        status_code = 0
        try:
            response = requests.put(url, headers=headers, json=payload)
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
            log_api_call("PUT", url, payload, status_code, response_data)


def test_delete_remark_errors():
    """9. Kiểm thử các trường hợp lỗi của DELETE /api/v1/attendance-records/remarks/{remarkId}"""
    print_info("Bắt đầu kiểm thử các trường hợp XÓA REMARK LỖI (dự kiến 400/404)")
    headers = get_auth_headers()
    if not headers:
        return

    test_cases = [
        (
            "Remark ID không tồn tại (REMARK_NOT_FOUND)",
            f"{BASE_URL}/api/v1/attendance-records/remarks/999999999",
            404,
        ),
        (
            "Remark ID sai định dạng (INVALID_FIELD_TYPE)",
            f"{BASE_URL}/api/v1/attendance-records/remarks/abc",
            400,
        ),
    ]

    for description, url, expected_status in test_cases:
        print_info(f"Đang thử lỗi: {description}")
        response_data = None
        status_code = 0
        try:
            response = requests.delete(url, headers=headers)
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
            log_api_call("DELETE", url, None, status_code, response_data)


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

    # Get an attendance record ID
    attendance_record_id = get_attendance_record_id()

    if attendance_record_id:
        print("-" * 30)
        # Create a remark
        remark_id = test_create_remark(attendance_record_id)

        if remark_id:
            print("-" * 30)
            # Get remarks for the attendance record
            test_get_remarks(attendance_record_id)

            print("-" * 30)
            # Update the remark
            test_update_remark(remark_id)

            print("-" * 30)
            # Get remarks again to verify update
            test_get_remarks(attendance_record_id)

            print("-" * 30)
            # Delete the remark
            test_delete_remark(remark_id)

            print("-" * 30)
            # Get remarks again to verify deletion
            test_get_remarks(attendance_record_id)
        else:
            print_error("Không thể tạo remark. Bỏ qua các bài kiểm thử 'Happy Path'.")
    else:
        print_error(
            "Không có attendance records để test. Bỏ qua các bài kiểm thử 'Happy Path'."
        )

    print("=" * 30)

    # 3. Chạy các bài kiểm thử lỗi
    print_info("Bắt đầu chạy các bài kiểm thử lỗi (Error Cases)")
    test_create_remark_errors()
    print("-" * 30)
    test_get_remarks_errors()
    print("-" * 30)
    test_update_remark_errors()
    print("-" * 30)
    test_delete_remark_errors()

    print("=" * 30)

    print_info("Tất cả các bài kiểm thử đã hoàn tất.")

    # 4. TẠO BÁO CÁO
    generate_markdown_report()


if __name__ == "__main__":
    main()
