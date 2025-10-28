import requests
import json
import time
import sys
import codecs

# Sửa lỗi UnicodeEncodeError trên Windows Console
# Buộc stdout sử dụng mã hóa UTF-8
sys.stdout = codecs.getwriter("utf-8")(sys.stdout.buffer)

# --- CẤU HÌNH ---
# TODO: THAY ĐỔI GIÁ TRỊ NÀY thành URL máy chủ của bạn
BASE_URL = "http://localhost:8080"
USERNAME = "god000"
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


def generate_markdown_report(filename="api_test_report_staff.md"):
    """Tạo tệp Markdown từ dữ liệu đã lưu trữ."""
    print_info(f"Đang tạo báo cáo Markdown: {filename}")
    try:
        with open(filename, "w", encoding="utf-8") as f:
            f.write(
                f"# Báo cáo Kiểm thử API - Staff Profiles ({time.strftime('%Y-%m-%d %H:%M:%S')})\n\n"
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


def test_create_staff_profile():
    """2. Kiểm thử POST /api/v1/staff-profiles (Tạo Hồ sơ Nhân viên)"""
    print_info("Đang thử tạo Hồ sơ Nhân viên mới...")
    url = f"{BASE_URL}/api/v1/staff-profiles"
    headers = get_auth_headers()
    if not headers:
        return None, None, None

    # Tạo dữ liệu duy nhất bằng timestamp
    ts = int(time.time())
    unique_code = f"EMP{ts % 1000000}"  # EMP + 6 số
    unique_email = f"staff{ts}@fpt.edu.vn"

    payload = {
        "fullName": f"Test Staff {unique_code}",
        "email": unique_email,
        "staffCode": unique_code,
        "password": "defaultPassword123",
        "roles": ["LECTURER"],  # Vai trò mặc định khi tạo
    }

    response_data = None
    status_code = 0

    try:
        response = requests.post(url, headers=headers, json=payload)
        status_code = response.status_code
        response_data = response.json()

        if response.status_code == 201:
            user_id = response_data.get("data", {}).get("userId")
            print_success(f"Tạo Hồ sơ NV thành công. ID mới: {user_id}")
            log_api_call("POST", url, payload, status_code, response_data)
            # Trả về các giá trị duy nhất để kiểm thử lỗi trùng lặp
            return user_id, unique_code, unique_email
        else:
            print_error(
                f"Tạo Hồ sơ NV thất bại. Mã trạng thái: {response.status_code}",
                response_data,
            )
            log_api_call("POST", url, payload, status_code, response_data)
            return None, None, None
    except Exception as e:
        print_error(f"Lỗi không xác định khi tạo hồ sơ NV: {e}")
        log_api_call("POST", url, payload, 500, {"error": str(e)})
        return None, None, None


def test_get_staff_profile_by_id(user_id):
    """3. Kiểm thử GET /api/v1/staff-profiles/{id} (Lấy Hồ sơ NV theo ID)"""
    print_info(f"Đang thử lấy Hồ sơ NV theo ID: {user_id}")
    url = f"{BASE_URL}/api/v1/staff-profiles/{user_id}"
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
            print_success(f"Lấy Hồ sơ NV {user_id} thành công.")
        else:
            print_error(
                f"Lấy Hồ sơ NV {user_id} thất bại. Mã trạng thái: {response.status_code}",
                response_data,
            )
    except Exception as e:
        print_error(f"Lỗi không xác định khi lấy hồ sơ NV {user_id}: {e}")
        status_code = 500
        response_data = {"error": str(e)}
    finally:
        log_api_call("GET", url, None, status_code, response_data)


def test_update_staff_profile(user_id, staff_code, email):
    """4. Kiểm thử PUT /api/v1/staff-profiles/{id} (Cập nhật Hồ sơ NV)"""
    print_info(f"Đang thử cập nhật Hồ sơ NV ID: {user_id}")
    url = f"{BASE_URL}/api/v1/staff-profiles/{user_id}"
    headers = get_auth_headers()
    if not headers:
        return

    # Cập nhật tên và thêm vai trò "SUPERVISOR"
    payload = {
        "fullName": f"Test Staff {staff_code} Updated",
        "email": email,
        "staffCode": staff_code,
        "roles": ["LECTURER", "SUPERVISOR"],  # Cập nhật vai trò
        "isActive": True,
    }

    response_data = None
    status_code = 0
    try:
        response = requests.put(url, headers=headers, json=payload)
        status_code = response.status_code
        response_data = response.json()

        if response.status_code == 200:
            print_success(f"Cập nhật Hồ sơ NV {user_id} thành công.")
        else:
            print_error(
                f"Cập nhật Hồ sơ NV {user_id} thất bại. Mã trạng thái: {response.status_code}",
                response_data,
            )
    except Exception as e:
        print_error(f"Lỗi không xác định khi cập nhật hồ sơ NV {user_id}: {e}")
        status_code = 500
        response_data = {"error": str(e)}
    finally:
        log_api_call("PUT", url, payload, status_code, response_data)


def test_get_staff_classes(user_id):
    """5. Kiểm thử GET /api/v1/staff-profiles/{id}/classes (Lấy Lớp học của NV)"""
    print_info(f"Đang thử lấy các lớp học của NV ID: {user_id}")
    # Tuân thủ yêu cầu: sort=desc & pageSize=10
    url = f"{BASE_URL}/api/v1/staff-profiles/{user_id}/classes?sort=desc&pageSize=10"
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
                f"Lấy các lớp học của NV {user_id} thành công. Tìm thấy: {count} lớp."
            )
        else:
            print_error(
                f"Lấy các lớp học của NV {user_id} thất bại. Mã trạng thái: {response.status_code}",
                response_data,
            )
    except Exception as e:
        print_error(f"Lỗi không xác định khi lấy các lớp học của NV {user_id}: {e}")
        status_code = 500
        response_data = {"error": str(e)}
    finally:
        log_api_call("GET", url, None, status_code, response_data)


def test_get_staff_subjects(user_id):
    """6. Kiểm thử GET /api/v1/staff-profiles/{id}/subjects (Lấy Môn học của NV)"""
    print_info(f"Đang thử lấy các môn học của NV ID: {user_id}")
    # Tuân thủ yêu cầu: sort=desc & pageSize=10
    url = f"{BASE_URL}/api/v1/staff-profiles/{user_id}/subjects?sort=desc&pageSize=10"
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
                f"Lấy các môn học của NV {user_id} thành công. Tìm thấy: {count} môn."
            )
        else:
            print_error(
                f"Lấy các môn học của NV {user_id} thất bại. Mã trạng thái: {response.status_code}",
                response_data,
            )
    except Exception as e:
        print_error(f"Lỗi không xác định khi lấy các môn học của NV {user_id}: {e}")
        status_code = 500
        response_data = {"error": str(e)}
    finally:
        log_api_call("GET", url, None, status_code, response_data)


def test_get_staff_rooms(user_id):
    """7. Kiểm thử GET /api/v1/staff-profiles/{id}/rooms (Lấy Phòng học của NV)"""
    print_info(f"Đang thử lấy các phòng học của NV ID: {user_id}")
    # Tuân thủ yêu cầu: sort=desc & pageSize=10
    url = f"{BASE_URL}/api/v1/staff-profiles/{user_id}/rooms?sort=desc&pageSize=10"
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
                f"Lấy các phòng học của NV {user_id} thành công. Tìm thấy: {count} phòng."
            )
        else:
            print_error(
                f"Lấy các phòng học của NV {user_id} thất bại. Mã trạng thái: {response.status_code}",
                response_data,
            )
    except Exception as e:
        print_error(f"Lỗi không xác định khi lấy các phòng học của NV {user_id}: {e}")
        status_code = 500
        response_data = {"error": str(e)}
    finally:
        log_api_call("GET", url, None, status_code, response_data)


def test_get_all_staff_profiles():
    """8. Kiểm thử GET /api/v1/staff-profiles (Lấy danh sách Hồ sơ NV)"""
    print_info("Đang thử lấy danh sách Hồ sơ NV (sort desc, pageSize 10)")
    # Tuân thủ yêu cầu: sort=desc & pageSize=10
    url = f"{BASE_URL}/api/v1/staff-profiles?sort=desc&pageSize=10"
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
                f"Lấy danh sách Hồ sơ NV thành công. Tìm thấy: {count} hồ sơ."
            )
        else:
            print_error(
                f"Lấy danh sách Hồ sơ NV thất bại. Mã trạng thái: {response.status_code}",
                response_data,
            )
    except Exception as e:
        print_error(f"Lỗi không xác định khi lấy danh sách hồ sơ NV: {e}")
        status_code = 500
        response_data = {"error": str(e)}
    finally:
        log_api_call("GET", url, None, status_code, response_data)


# --- Bắt đầu các hàm kiểm thử lỗi ---


def test_create_staff_profile_errors(existing_code, existing_email):
    """9. Kiểm thử các trường hợp lỗi của POST /api/v1/staff-profiles"""
    print_info("Bắt đầu kiểm thử các trường hợp TẠO LỖI (dự kiến 400/409)")
    url = f"{BASE_URL}/api/v1/staff-profiles"
    headers = get_auth_headers()
    if not headers:
        return

    test_cases = [
        (
            "Tên rỗng (FULL_NAME_REQUIRED)",
            {
                "fullName": "",
                "email": "err1@fpt.edu.vn",
                "staffCode": "ERR001",
                "roles": ["LECTURER"],
            },
        ),
        (
            "Email rỗng (EMAIL_REQUIRED)",
            {
                "fullName": "Test Name",
                "email": "",
                "staffCode": "ERR002",
                "roles": ["LECTURER"],
            },
        ),
        (
            "StaffCode rỗng (STAFF_CODE_REQUIRED)",
            {
                "fullName": "Test Name",
                "email": "err3@fpt.edu.vn",
                "staffCode": "",
                "roles": ["LECTURER"],
            },
        ),
        (
            "Roles rỗng (ROLES_REQUIRED)",
            {
                "fullName": "Test Name",
                "email": "err4@fpt.edu.vn",
                "staffCode": "ERR004",
                "roles": [],
            },
        ),
        (
            "Email đã tồn tại (EMAIL_EXISTS)",
            {
                "fullName": "Test Name Dup",
                "email": existing_email,
                "staffCode": "ERR005",
                "roles": ["LECTURER"],
            },
        ),
        (
            "StaffCode đã tồn tại (STAFF_CODE_EXISTS)",
            {
                "fullName": "Test Name Dup",
                "email": "err6@fpt.edu.vn",
                "staffCode": existing_code,
                "roles": ["LECTURER"],
            },
        ),
        (
            "Email sai định dạng (INVALID_EMAIL_FORMAT)",
            {
                "fullName": "Test Name",
                "email": "bademail",
                "staffCode": "ERR007",
                "roles": ["LECTURER"],
            },
        ),
        (
            "Vai trò không hợp lệ (INVALID_ROLE)",
            {
                "fullName": "Test Name",
                "email": "err8@fpt.edu.vn",
                "staffCode": "ERR008",
                "roles": ["STUDENT"],
            },
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

            if 400 <= response.status_code < 500:  # 400 hoặc 409
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


def test_get_staff_profile_by_id_errors():
    """10. Kiểm thử các trường hợp lỗi của GET /api/v1/staff-profiles/{id}"""
    print_info("Bắt đầu kiểm thử các trường hợp LẤY LỖI (dự kiến 400/404)")
    headers = get_auth_headers()
    if not headers:
        return

    test_cases = [
        (
            "ID không tồn tại (STAFF_PROFILE_NOT_FOUND)",
            f"{BASE_URL}/api/v1/staff-profiles/99999",
            404,
        ),
        (
            "ID sai định dạng (INVALID_FIELD_TYPE)",
            f"{BASE_URL}/api/v1/staff-profiles/abc",
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


# --- Hàm chính (Main) ---


def main():
    """Chạy chu trình kiểm thử."""

    # 1. Đăng nhập
    if not test_login():
        print_error("Không thể tiếp tục nếu không đăng nhập. Đang thoát.")
        generate_markdown_report("api_test_report_staff.md")
        return

    print("-" * 30)

    # 2. Chạy chu trình Tạo -> Lấy -> Cập nhật -> Lấy các tài nguyên liên quan
    new_user_id, new_code, new_email = test_create_staff_profile()

    if new_user_id:
        print("-" * 30)
        test_get_staff_profile_by_id(new_user_id)
        print("-" * 30)
        test_update_staff_profile(new_user_id, new_code, new_email)
        print("-" * 30)
        test_get_staff_classes(new_user_id)
        print("-" * 30)
        test_get_staff_subjects(new_user_id)
        print("-" * 30)
        test_get_staff_rooms(new_user_id)

        # Chạy các bài kiểm thử lỗi
        print("=" * 30)
        print_info("Bắt đầu chạy các bài kiểm thử lỗi (Error Cases)")
        test_create_staff_profile_errors(new_code, new_email)
        print("-" * 30)
        test_get_staff_profile_by_id_errors()

    else:
        print_error("Không thể tạo Hồ sơ NV. Bỏ qua các bài kiểm thử phụ thuộc.")
        # Vẫn chạy kiểm thử lỗi GET (không phụ thuộc)
        print("=" * 30)
        test_get_staff_profile_by_id_errors()

    print("=" * 30)

    # 3. Kiểm thử API Lấy Danh sách (chạy riêng)
    test_get_all_staff_profiles()
    print("=" * 30)

    print_info("Tất cả các bài kiểm thử đã hoàn tất.")

    # 4. TẠO BÁO CÁO
    generate_markdown_report("api_test_report_staff.md")


if __name__ == "__main__":
    main()
