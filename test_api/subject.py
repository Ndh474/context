import requests
import json
import time
import sys
import codecs

# NEW: Sửa lỗi UnicodeEncodeError trên Windows Console
# Buộc stdout sử dụng mã hóa UTF-8
sys.stdout = codecs.getwriter("utf-8")(sys.stdout.buffer)

# Đã xóa 'import os' và 'import csv' vì không còn cần thiết

# --- CẤU HÌNH ---
# TODO: THAY ĐỔI GIÁ TRỊ NÀY thành URL máy chủ của bạn
BASE_URL = "http://localhost:8080"
USERNAME = "god000"
PASSWORD = "12345678"
# ----------------

# Biến toàn cục để lưu trữ token
access_token = None

# NEW: Biến toàn cục để lưu trữ dữ liệu báo cáo
report_data = []


# Hàm trợ giúp để in màu
def print_success(message):
    print(f"\033[92m[THÀNH CÔNG] {message}\033[0m")


def print_error(message, data=None):
    print(f"\033[91m[LỖI] {message}\033[0m")
    if data:
        # Đảm bảo in JSON tiếng Việt đúng
        print(f"\033[91m      {json.dumps(data, indent=2, ensure_ascii=False)}\033[0m")


def print_info(message):
    print(f"\033[94m[THÔNG TIN] {message}\033[0m")


# NEW: Hàm trợ giúp để ghi lại các cuộc gọi API
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


# NEW: Hàm tạo báo cáo Markdown
def generate_markdown_report(filename="api_test_report.md"):
    """Tạo tệp Markdown từ dữ liệu đã lưu trữ trong report_data."""
    print_info(f"Đang tạo báo cáo Markdown: {filename}")
    try:
        with open(filename, "w", encoding="utf-8") as f:
            f.write(
                f"# Báo cáo Kiểm thử API - Subjects ({time.strftime('%Y-%m-%d %H:%M:%S')})\n\n"
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


def test_create_subject():
    """2. Kiểm thử POST /api/v1/subjects (Tạo Subject)"""
    print_info("Đang thử tạo Subject mới...")
    url = f"{BASE_URL}/api/v1/subjects"
    headers = get_auth_headers()
    if not headers:
        return None, None

    # Tạo một mã code duy nhất bằng cách sử dụng timestamp
    unique_code = f"TESTAPI{int(time.time()) % 10000}"

    payload = {
        "name": f"Test Subject {unique_code}",
        "code": unique_code,
        "majorIds": [1, 2],  # Giả định rằng major ID 1 và 2 tồn tại
    }

    response_data = None
    status_code = 0

    try:
        response = requests.post(url, headers=headers, json=payload)
        status_code = response.status_code
        response_data = response.json()

        if response.status_code == 201:
            subject_id = response_data.get("data", {}).get("id")
            subject_code = response_data.get("data", {}).get("code")
            print_success(f"Tạo Subject thành công. ID mới: {subject_id}")
            log_api_call("POST", url, payload, status_code, response_data)
            return subject_id, subject_code
        else:
            print_error(
                f"Tạo Subject thất bại. Mã trạng thái: {response.status_code}",
                response_data,
            )
            log_api_call("POST", url, payload, status_code, response_data)
            return None, None
    except Exception as e:
        print_error(f"Lỗi không xác định khi tạo subject: {e}")
        log_api_call("POST", url, payload, 500, {"error": str(e)})
        return None, None


def test_get_subject_by_id(subject_id):
    """3. Kiểm thử GET /api/v1/subjects/{id} (Lấy Subject theo ID)"""
    print_info(f"Đang thử lấy Subject theo ID: {subject_id}")
    url = f"{BASE_URL}/api/v1/subjects/{subject_id}"
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
            print_success(f"Lấy Subject {subject_id} thành công.")
        else:
            print_error(
                f"Lấy Subject {subject_id} thất bại. Mã trạng thái: {response.status_code}",
                response_data,
            )
    except Exception as e:
        print_error(f"Lỗi không xác định khi lấy subject {subject_id}: {e}")
        status_code = 500
        response_data = {"error": str(e)}
    finally:
        log_api_call("GET", url, None, status_code, response_data)


def test_update_subject(subject_id, subject_code):
    """4. Kiểm thử PUT /api/v1/subjects/{id} (Cập nhật Subject)"""
    print_info(f"Đang thử cập nhật Subject ID: {subject_id}")
    url = f"{BASE_URL}/api/v1/subjects/{subject_id}"
    headers = get_auth_headers()
    if not headers:
        return

    payload = {
        "name": f"Test Subject {subject_code} Updated",
        "code": subject_code,  # Code không thể thay đổi theo logic thông thường, nhưng API yêu cầu
        "majorIds": [1],  # Thay đổi từ [1, 2] thành [1]
        "isActive": True,
    }

    response_data = None
    status_code = 0
    try:
        response = requests.put(url, headers=headers, json=payload)
        status_code = response.status_code
        response_data = response.json()

        if response.status_code == 200:
            print_success(f"Cập nhật Subject {subject_id} thành công.")
        else:
            print_error(
                f"Cập nhật Subject {subject_id} thất bại. Mã trạng thái: {response.status_code}",
                response_data,
            )
    except Exception as e:
        print_error(f"Lỗi không xác định khi cập nhật subject {subject_id}: {e}")
        status_code = 500
        response_data = {"error": str(e)}
    finally:
        log_api_call("PUT", url, payload, status_code, response_data)


def test_get_classes_by_subject(subject_id):
    """5. Kiểm thử GET /api/v1/subjects/{id}/classes (Lấy Lớp học theo Subject)"""
    print_info(f"Đang thử lấy các lớp học của Subject ID: {subject_id}")
    url = f"{BASE_URL}/api/v1/subjects/{subject_id}/classes"
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
                f"Lấy các lớp học của Subject {subject_id} thành công. Tìm thấy: {count} lớp."
            )
        else:
            print_error(
                f"Lấy các lớp học của Subject {subject_id} thất bại. Mã trạng thái: {response.status_code}",
                response_data,
            )
    except Exception as e:
        print_error(
            f"Lỗi không xác định khi lấy các lớp học của subject {subject_id}: {e}"
        )
        status_code = 500
        response_data = {"error": str(e)}
    finally:
        log_api_call("GET", url, None, status_code, response_data)


# REMOVED: test_delete_subject()


def test_get_all_subjects():
    """6. Kiểm thử GET /api/v1/subjects (Lấy danh sách Subjects)"""
    print_info("Đang thử lấy danh sách Subjects (page 1, pageSize 5)")
    url = f"{BASE_URL}/api/v1/subjects?page=1&pageSize=5"
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
                f"Lấy danh sách Subjects thành công. Tìm thấy: {count} subjects."
            )
        else:
            print_error(
                f"Lấy danh sách Subjects thất bại. Mã trạng thái: {response.status_code}",
                response_data,
            )
    except Exception as e:
        print_error(f"Lỗi không xác định khi lấy danh sách subjects: {e}")
        status_code = 500
        response_data = {"error": str(e)}
    finally:
        log_api_call("GET", url, None, status_code, response_data)


# REMOVED: create_dummy_csv()
# REMOVED: test_import_subjects()

# --- NEW: Bắt đầu các hàm kiểm thử lỗi ---


def test_create_subject_errors(existing_subject_code):
    """7. Kiểm thử các trường hợp lỗi của POST /api/v1/subjects"""
    print_info("Bắt đầu kiểm thử các trường hợp TẠO LỖI (dự kiến 400/404)")
    url = f"{BASE_URL}/api/v1/subjects"
    headers = get_auth_headers()
    if not headers:
        return

    test_cases = [
        (
            "Tên rỗng (SUBJECT_NAME_REQUIRED)",
            {"name": "", "code": "ERR001", "majorIds": [1]},
        ),
        (
            "Code rỗng (SUBJECT_CODE_REQUIRED)",
            {"name": "Test Name", "code": "", "majorIds": [1]},
        ),
        (
            "MajorIds rỗng (SUBJECT_MAJOR_IDS_EMPTY)",
            {"name": "Test Name", "code": "ERR002", "majorIds": []},
        ),
        (
            "Major không tồn tại (MAJOR_NOT_FOUND)",
            {"name": "Test Name", "code": "ERR003", "majorIds": [9999]},
        ),
        (
            "Code đã tồn tại (SUBJECT_CODE_EXISTS)",
            {
                "name": "Test Name Duplicate",
                "code": existing_subject_code,
                "majorIds": [1],
            },
        ),
        (
            "Code sai định dạng (INVALID_FIELD_FORMAT)",
            {"name": "Test Name", "code": "err 004", "majorIds": [1]},
        ),
        (
            "Tên sai định dạng (INVALID_FIELD_FORMAT)",
            {"name": "  Test Name ", "code": "ERR005", "majorIds": [1]},
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
                    f"Kiểm thử lỗi '{description}' THẤT BẠI. Dự kiến 4xx nhưng nhận được {status_code}",
                    response_data,
                )
        except Exception as e:
            print_error(f"Lỗi không xác định khi kiểm thử '{description}': {e}")
            status_code = 500
            response_data = {"error": str(e)}
        finally:
            log_api_call("POST", url, payload, status_code, response_data)


def test_get_subject_by_id_errors():
    """8. Kiểm thử các trường hợp lỗi của GET /api/v1/subjects/{id}"""
    print_info("Bắt đầu kiểm thử các trường hợp LẤY LỖI (dự kiến 400/404)")
    headers = get_auth_headers()
    if not headers:
        return

    test_cases = [
        (
            "ID không tồn tại (SUBJECT_NOT_FOUND)",
            f"{BASE_URL}/api/v1/subjects/9999",
            404,
        ),
        (
            "ID sai định dạng (INVALID_FIELD_TYPE)",
            f"{BASE_URL}/api/v1/subjects/abc",
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
            response_data = response.json()

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


# --- Kết thúc các hàm kiểm thử lỗi ---


def main():
    """Chạy chu trình kiểm thử."""

    # 1. Đăng nhập
    if not test_login():
        print_error("Không thể tiếp tục nếu không đăng nhập. Đang thoát.")
        # Vẫn tạo báo cáo ngay cả khi đăng nhập thất bại
        generate_markdown_report("api_test_report.md")
        return

    print("-" * 30)

    # 2. Chạy chu trình Tạo -> Lấy -> Cập nhật -> Lấy Lớp học
    # (Tập lệnh này sẽ tạo một subject mới mỗi khi chạy và không xóa nó)
    new_subject_id, new_subject_code = test_create_subject()

    if new_subject_id:
        print("-" * 30)
        test_get_subject_by_id(new_subject_id)
        print("-" * 30)
        test_update_subject(new_subject_id, new_subject_code)
        print("-" * 30)
        test_get_classes_by_subject(new_subject_id)

        # --- NEW: Chạy các bài kiểm thử lỗi ---
        print("=" * 30)
        print_info("Bắt đầu chạy các bài kiểm thử lỗi (Error Cases)")
        test_create_subject_errors(
            new_subject_code
        )  # Sử dụng code vừa tạo để kiểm thử trùng lặp
        print("-" * 30)
        test_get_subject_by_id_errors()
        # --- Kết thúc kiểm thử lỗi ---

    else:
        print_error("Không thể tạo subject. Bỏ qua các bài kiểm thử phụ thuộc.")

    print("=" * 30)

    # 3. Kiểm thử API Lấy Danh sách (chạy riêng)
    test_get_all_subjects()
    print("=" * 30)

    # Đã xóa lệnh gọi test_import_subjects()

    print_info("Tất cả các bài kiểm thử đã hoàn tất.")

    # 4. TẠO BÁO CÁO
    generate_markdown_report("api_test_report.md")


if __name__ == "__main__":
    main()
