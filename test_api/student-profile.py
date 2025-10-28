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
    print(f"\033[92m[THÀNH CÔNG] {message}\033[0m")


def print_error(message, data=None):
    print(f"\033[91m[LỖI] {message}\033[0m")
    if data:
        print(f"\033[91m      {json.dumps(data, indent=2, ensure_ascii=False)}\033[0m")


def print_info(message):
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


def generate_markdown_report(filename="api_test_report_students.md"):
    """Tạo tệp Markdown từ dữ liệu đã lưu trữ."""
    print_info(f"Đang tạo báo cáo Markdown: {filename}")
    try:
        with open(filename, "w", encoding="utf-8") as f:
            f.write(
                f"# Báo cáo Kiểm thử API - Student Profiles ({time.strftime('%Y-%m-%d %H:%M:%S')})\n\n"
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


def test_create_student_profile():
    """2. Kiểm thử POST /api/v1/student-profiles (Tạo Hồ sơ Sinh viên)"""
    print_info("Đang thử tạo Hồ sơ Sinh viên mới...")
    url = f"{BASE_URL}/api/v1/student-profiles"
    headers = get_auth_headers()
    if not headers:
        return None, None, None, None

    # Tạo dữ liệu duy nhất bằng timestamp
    ts = int(time.time())
    unique_roll = f"HE{ts % 1000000}"  # HE + 6 số
    unique_user = f"user{ts}"
    unique_email = f"user{ts}@fpt.edu.vn"

    payload = {
        "fullName": f"Test Student {unique_roll}",
        "email": unique_email,
        "username": unique_user,
        "rollNumber": unique_roll,
        "majorId": 1,  # Giả định major ID 1 tồn tại
    }

    response_data = None
    status_code = 0

    try:
        response = requests.post(url, headers=headers, json=payload)
        status_code = response.status_code
        response_data = response.json()

        if response.status_code == 201:
            user_id = response_data.get("data", {}).get("userId")
            print_success(f"Tạo Hồ sơ SV thành công. ID mới: {user_id}")
            log_api_call("POST", url, payload, status_code, response_data)
            # Trả về các giá trị duy nhất để kiểm thử lỗi trùng lặp
            return user_id, unique_roll, unique_user, unique_email
        else:
            print_error(
                f"Tạo Hồ sơ SV thất bại. Mã trạng thái: {response.status_code}",
                response_data,
            )
            log_api_call("POST", url, payload, status_code, response_data)
            return None, None, None, None
    except Exception as e:
        print_error(f"Lỗi không xác định khi tạo hồ sơ SV: {e}")
        log_api_call("POST", url, payload, 500, {"error": str(e)})
        return None, None, None, None


def test_get_student_profile_by_id(user_id):
    """3. Kiểm thử GET /api/v1/student-profiles/{id} (Lấy Hồ sơ SV theo ID)"""
    print_info(f"Đang thử lấy Hồ sơ SV theo ID: {user_id}")
    url = f"{BASE_URL}/api/v1/student-profiles/{user_id}"
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
            print_success(f"Lấy Hồ sơ SV {user_id} thành công.")
        else:
            print_error(
                f"Lấy Hồ sơ SV {user_id} thất bại. Mã trạng thái: {response.status_code}",
                response_data,
            )
    except Exception as e:
        print_error(f"Lỗi không xác định khi lấy hồ sơ SV {user_id}: {e}")
        status_code = 500
        response_data = {"error": str(e)}
    finally:
        log_api_call("GET", url, None, status_code, response_data)


def test_update_student_profile(user_id, roll_number, username, email):
    """4. Kiểm thử PUT /api/v1/student-profiles/{id} (Cập nhật Hồ sơ SV)"""
    print_info(f"Đang thử cập nhật Hồ sơ SV ID: {user_id}")
    url = f"{BASE_URL}/api/v1/student-profiles/{user_id}"
    headers = get_auth_headers()
    if not headers:
        return

    # Chỉ cập nhật tên, giữ nguyên các giá trị duy nhất
    payload = {
        "fullName": f"Test Student {roll_number} Updated",
        "email": email,
        "username": username,
        "rollNumber": roll_number,
        "majorId": 1,
        "isActive": True,
    }

    response_data = None
    status_code = 0
    try:
        response = requests.put(url, headers=headers, json=payload)
        status_code = response.status_code
        response_data = response.json()

        if response.status_code == 200:
            print_success(f"Cập nhật Hồ sơ SV {user_id} thành công.")
        else:
            print_error(
                f"Cập nhật Hồ sơ SV {user_id} thất bại. Mã trạng thái: {response.status_code}",
                response_data,
            )
    except Exception as e:
        print_error(f"Lỗi không xác định khi cập nhật hồ sơ SV {user_id}: {e}")
        status_code = 500
        response_data = {"error": str(e)}
    finally:
        log_api_call("PUT", url, payload, status_code, response_data)


def test_get_student_classes(user_id):
    """5. Kiểm thử GET /api/v1/student-profiles/{id}/classes (Lấy Lớp học của SV)"""
    print_info(f"Đang thử lấy các lớp học của SV ID: {user_id}")
    url = f"{BASE_URL}/api/v1/student-profiles/{user_id}/classes"
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
                f"Lấy các lớp học của SV {user_id} thành công. Tìm thấy: {count} lớp."
            )
        else:
            print_error(
                f"Lấy các lớp học của SV {user_id} thất bại. Mã trạng thái: {response.status_code}",
                response_data,
            )
    except Exception as e:
        print_error(f"Lỗi không xác định khi lấy các lớp học của SV {user_id}: {e}")
        status_code = 500
        response_data = {"error": str(e)}
    finally:
        log_api_call("GET", url, None, status_code, response_data)


def test_get_student_attendance_history(user_id):
    """6. Kiểm thử GET /.../attendance-history (Lấy Lịch sử điểm danh)"""
    print_info(f"Đang thử lấy lịch sử điểm danh của SV ID: {user_id}")
    # Tuân thủ yêu cầu: sort=desc & pageSize=10
    url = f"{BASE_URL}/api/v1/student-profiles/{user_id}/attendance-history?sort=desc&pageSize=10"
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
                f"Lấy lịch sử điểm danh của SV {user_id} thành công. Tìm thấy: {count} bản ghi."
            )
        else:
            print_error(
                f"Lấy lịch sử điểm danh của SV {user_id} thất bại. Mã trạng thái: {response.status_code}",
                response_data,
            )
    except Exception as e:
        print_error(
            f"Lỗi không xác định khi lấy lịch sử điểm danh của SV {user_id}: {e}"
        )
        status_code = 500
        response_data = {"error": str(e)}
    finally:
        log_api_call("GET", url, None, status_code, response_data)


def test_get_all_student_profiles():
    """7. Kiểm thử GET /api/v1/student-profiles (Lấy danh sách Hồ sơ SV)"""
    print_info("Đang thử lấy danh sách Hồ sơ SV (sort desc, pageSize 10)")
    # Tuân thủ yêu cầu: sort=desc & pageSize=10
    url = f"{BASE_URL}/api/v1/student-profiles?sort=desc&pageSize=10"
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
                f"Lấy danh sách Hồ sơ SV thành công. Tìm thấy: {count} hồ sơ."
            )
        else:
            print_error(
                f"Lấy danh sách Hồ sơ SV thất bại. Mã trạng thái: {response.status_code}",
                response_data,
            )
    except Exception as e:
        print_error(f"Lỗi không xác định khi lấy danh sách hồ sơ SV: {e}")
        status_code = 500
        response_data = {"error": str(e)}
    finally:
        log_api_call("GET", url, None, status_code, response_data)


# --- Bắt đầu các hàm kiểm thử lỗi ---


def test_create_student_profile_errors(existing_roll, existing_user, existing_email):
    """8. Kiểm thử các trường hợp lỗi của POST /api/v1/student-profiles"""
    print_info("Bắt đầu kiểm thử các trường hợp TẠO LỖI (dự kiến 400/404)")
    url = f"{BASE_URL}/api/v1/student-profiles"
    headers = get_auth_headers()
    if not headers:
        return

    test_cases = [
        (
            "Tên rỗng (FULL_NAME_REQUIRED)",
            {
                "fullName": "",
                "email": "err1@fpt.edu.vn",
                "username": "err1",
                "rollNumber": "HE999001",
                "majorId": 1,
            },
        ),
        (
            "Email rỗng (EMAIL_REQUIRED)",
            {
                "fullName": "Test Name",
                "email": "",
                "username": "err2",
                "rollNumber": "HE999002",
                "majorId": 1,
            },
        ),
        (
            "RollNumber rỗng (ROLL_NUMBER_REQUIRED)",
            {
                "fullName": "Test Name",
                "email": "err3@fpt.edu.vn",
                "username": "err3",
                "rollNumber": "",
                "majorId": 1,
            },
        ),
        (
            "MajorId rỗng (MAJOR_ID_REQUIRED)",
            {
                "fullName": "Test Name",
                "email": "err4@fpt.edu.vn",
                "username": "err4",
                "rollNumber": "HE999004",
                "majorId": None,
            },
        ),
        (
            "Major không tồn tại (MAJOR_NOT_FOUND)",
            {
                "fullName": "Test Name",
                "email": "err5@fpt.edu.vn",
                "username": "err5",
                "rollNumber": "HE999005",
                "majorId": 9999,
            },
        ),
        (
            "Email đã tồn tại (EMAIL_EXISTS)",
            {
                "fullName": "Test Name Dup",
                "email": existing_email,
                "username": "err6",
                "rollNumber": "HE999006",
                "majorId": 1,
            },
        ),
        (
            "Username đã tồn tại (USERNAME_EXISTS)",
            {
                "fullName": "Test Name Dup",
                "email": "err7@fpt.edu.vn",
                "username": existing_user,
                "rollNumber": "HE999007",
                "majorId": 1,
            },
        ),
        (
            "RollNumber đã tồn tại (ROLL_NUMBER_EXISTS)",
            {
                "fullName": "Test Name Dup",
                "email": "err8@fpt.edu.vn",
                "username": "err8",
                "rollNumber": existing_roll,
                "majorId": 1,
            },
        ),
        (
            "RollNumber sai định dạng (INVALID_ROLL_NUMBER_FORMAT)",
            {
                "fullName": "Test Name",
                "email": "err9@fpt.edu.vn",
                "username": "err9",
                "rollNumber": "HE12345",
                "majorId": 1,
            },
        ),
        (
            "Email sai định dạng (INVALID_EMAIL_FORMAT)",
            {
                "fullName": "Test Name",
                "email": "bademail",
                "username": "err10",
                "rollNumber": "HE999010",
                "majorId": 1,
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


def test_get_student_profile_by_id_errors():
    """9. Kiểm thử các trường hợp lỗi của GET /api/v1/student-profiles/{id}"""
    print_info("Bắt đầu kiểm thử các trường hợp LẤY LỖI (dự kiến 400/404)")
    headers = get_auth_headers()
    if not headers:
        return

    test_cases = [
        (
            "ID không tồn tại (STUDENT_PROFILE_NOT_FOUND)",
            f"{BASE_URL}/api/v1/student-profiles/99999",
            404,
        ),
        (
            "ID sai định dạng (INVALID_FIELD_TYPE)",
            f"{BASE_URL}/api/v1/student-profiles/abc",
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
        generate_markdown_report("api_test_report_students.md")
        return

    print("-" * 30)

    # 2. Chạy chu trình Tạo -> Lấy -> Cập nhật -> Lấy Lớp học/Lịch sử
    new_user_id, new_roll, new_user, new_email = test_create_student_profile()

    if new_user_id:
        print("-" * 30)
        test_get_student_profile_by_id(new_user_id)
        print("-" * 30)
        test_update_student_profile(new_user_id, new_roll, new_user, new_email)
        print("-" * 30)
        test_get_student_classes(new_user_id)
        print("-" * 30)
        test_get_student_attendance_history(new_user_id)

        # Chạy các bài kiểm thử lỗi
        print("=" * 30)
        print_info("Bắt đầu chạy các bài kiểm thử lỗi (Error Cases)")
        test_create_student_profile_errors(new_roll, new_user, new_email)
        print("-" * 30)
        test_get_student_profile_by_id_errors()

    else:
        print_error("Không thể tạo Hồ sơ SV. Bỏ qua các bài kiểm thử phụ thuộc.")
        # Vẫn chạy kiểm thử lỗi GET (không phụ thuộc)
        print("=" * 30)
        test_get_student_profile_by_id_errors()

    print("=" * 30)

    # 3. Kiểm thử API Lấy Danh sách (chạy riêng)
    test_get_all_student_profiles()
    print("=" * 30)

    print_info("Tất cả các bài kiểm thử đã hoàn tất.")

    # 4. TẠO BÁO CÁO
    generate_markdown_report("api_test_report_students.md")


if __name__ == "__main__":
    main()
