import requests
import json
import time
import sys
import codecs

# Sửa lỗi UnicodeEncodeError trên Windows Console
sys.stdout = codecs.getwriter("utf-8")(sys.stdout.buffer)

# --- CẤU HÌNH ---
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


def generate_markdown_report(filename="api_test_report_enrollments.md"):
    """Tạo tệp Markdown từ dữ liệu đã lưu trữ."""
    print_info(f"Đang tạo báo cáo Markdown: {filename}")
    try:
        with open(filename, "w", encoding="utf-8") as f:
            f.write(
                f"# Báo cáo Kiểm thử API - Enrollments ({time.strftime('%Y-%m-%d %H:%M:%S')})\n\n"
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


def get_available_student_id(class_id=1):
    """Query for a student who is not yet enrolled in the specified class."""
    print_info(f"Đang tìm student profile chưa enrolled trong class {class_id}...")
    headers = get_auth_headers()
    if not headers:
        return None

    try:
        # Get ALL students (increase page size to capture all)
        students_url = f"{BASE_URL}/api/v1/student-profiles?pageSize=500"
        students_response = requests.get(students_url, headers=headers)
        if students_response.status_code != 200:
            return None

        all_students = students_response.json().get("data", {}).get("items", [])
        if not all_students:
            return None

        # Get ALL enrolled students in class (increase page size)
        enrollments_url = (
            f"{BASE_URL}/api/v1/classes/{class_id}/enrollments?pageSize=500"
        )
        enrollments_response = requests.get(enrollments_url, headers=headers)
        enrolled_student_ids = set()
        if enrollments_response.status_code == 200:
            enrolled_students = (
                enrollments_response.json().get("data", {}).get("items", [])
            )
            enrolled_student_ids = {s.get("userId") for s in enrolled_students}
            print_info(f"Tìm thấy {len(enrolled_student_ids)} students đã enrolled")

        # Find a student not yet enrolled
        for student in all_students:
            student_id = student.get("userId")
            if student_id and student_id not in enrolled_student_ids:
                print_info(
                    f"Tìm thấy student chưa enrolled - ID: {student_id} ({student.get('rollNumber')})"
                )
                return student_id

        print_error("Không tìm thấy student nào chưa enrolled")
        return None

    except Exception as e:
        print_error(f"Lỗi khi tìm student: {e}")
        return None


def get_enrolled_student_id(class_id=1):
    """Get a student who is already enrolled in the specified class."""
    print_info(f"Đang tìm student đã enrolled trong class {class_id}...")
    url = f"{BASE_URL}/api/v1/classes/{class_id}/enrollments?pageSize=1"
    headers = get_auth_headers()
    if not headers:
        return None

    try:
        response = requests.get(url, headers=headers)
        if response.status_code == 200:
            students = response.json().get("data", {}).get("items", [])
            if students:
                student_id = students[0].get("userId")
                print_info(f"Tìm thấy enrolled student ID: {student_id}")
                return student_id
    except Exception as e:
        print_error(f"Lỗi khi tìm enrolled student: {e}")

    return None


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


def test_create_enrollment(class_id=1, student_user_id=None, suffix=""):
    """2. Kiểm thử POST /api/v1/enrollments (Tạo Enrollment)"""
    print_info(f"Đang thử tạo Enrollment mới{' ' + suffix if suffix else ''}...")
    url = f"{BASE_URL}/api/v1/enrollments"
    headers = get_auth_headers()
    if not headers:
        return None, None, None

    if student_user_id is None:
        print_error("student_user_id không được để trống")
        return None, None, None

    payload = {
        "classId": class_id,
        "studentUserId": student_user_id,
    }

    response_data = None
    status_code = 0

    try:
        response = requests.post(url, headers=headers, json=payload)
        status_code = response.status_code
        response_data = response.json()

        if response.status_code in [201, 200]:
            enrollment_class_id = response_data.get("data", {}).get("classId")
            enrollment_student_id = response_data.get("data", {}).get("studentUserId")
            status_msg = "Tạo" if status_code == 201 else "Re-enroll"
            print_success(
                f"{status_msg} Enrollment thành công. ClassID: {enrollment_class_id}, StudentID: {enrollment_student_id}"
            )
            log_api_call("POST", url, payload, status_code, response_data)
            return enrollment_class_id, enrollment_student_id, status_code
        else:
            print_error(
                f"Tạo Enrollment thất bại. Mã trạng thái: {response.status_code}",
                response_data,
            )
            log_api_call("POST", url, payload, status_code, response_data)
            return None, None, None
    except Exception as e:
        print_error(f"Lỗi không xác định khi tạo enrollment: {e}")
        log_api_call("POST", url, payload, 500, {"error": str(e)})
        return None, None, None


def test_get_enrollment_by_key(class_id, student_user_id):
    """3. Kiểm thử GET /api/v1/enrollments/{classId}/{studentUserId}"""
    print_info(
        f"Đang thử lấy Enrollment theo ClassID: {class_id}, StudentID: {student_user_id}"
    )
    url = f"{BASE_URL}/api/v1/enrollments/{class_id}/{student_user_id}"
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
            print_success(f"Lấy Enrollment thành công.")
        else:
            print_error(
                f"Lấy Enrollment thất bại. Mã trạng thái: {response.status_code}",
                response_data,
            )
    except Exception as e:
        print_error(f"Lỗi không xác định khi lấy enrollment: {e}")
        status_code = 500
        response_data = {"error": str(e)}
    finally:
        log_api_call("GET", url, None, status_code, response_data)


def test_update_enrollment(class_id, student_user_id, is_enrolled):
    """4. Kiểm thử PUT /api/v1/enrollments/{classId}/{studentUserId}"""
    print_info(
        f"Đang thử cập nhật Enrollment ClassID: {class_id}, StudentID: {student_user_id}"
    )
    url = f"{BASE_URL}/api/v1/enrollments/{class_id}/{student_user_id}"
    headers = get_auth_headers()
    if not headers:
        return

    payload = {
        "isEnrolled": is_enrolled,
    }

    response_data = None
    status_code = 0
    try:
        response = requests.put(url, headers=headers, json=payload)
        status_code = response.status_code
        response_data = response.json()

        if response.status_code == 200:
            print_success(f"Cập nhật Enrollment thành công.")
        else:
            print_error(
                f"Cập nhật Enrollment thất bại. Mã trạng thái: {response.status_code}",
                response_data,
            )
    except Exception as e:
        print_error(f"Lỗi không xác định khi cập nhật enrollment: {e}")
        status_code = 500
        response_data = {"error": str(e)}
    finally:
        log_api_call("PUT", url, payload, status_code, response_data)


def test_get_all_enrollments():
    """5. Kiểm thử GET /api/v1/enrollments (Lấy danh sách Enrollment)"""
    print_info("Đang thử lấy danh sách Enrollment (sort desc, pageSize 10)")
    url = f"{BASE_URL}/api/v1/enrollments?sort=desc&pageSize=10"
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
                f"Lấy danh sách Enrollment thành công. Tìm thấy: {count} enrollment."
            )
        else:
            print_error(
                f"Lấy danh sách Enrollment thất bại. Mã trạng thái: {response.status_code}",
                response_data,
            )
    except Exception as e:
        print_error(f"Lỗi không xác định khi lấy danh sách enrollment: {e}")
        status_code = 500
        response_data = {"error": str(e)}
    finally:
        log_api_call("GET", url, None, status_code, response_data)


def test_get_class_roster(class_id):
    """6. Kiểm thử GET /api/v1/classes/{classId}/enrollments (Lấy roster)"""
    print_info(f"Đang thử lấy roster của Class ID: {class_id}")
    url = f"{BASE_URL}/api/v1/classes/{class_id}/enrollments"
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
            total_enrolled = response_data.get("data", {}).get("totalEnrolled", 0)
            print_success(
                f"Lấy roster thành công. Tìm thấy: {count} students, Total enrolled: {total_enrolled}"
            )
        else:
            print_error(
                f"Lấy roster thất bại. Mã trạng thái: {response.status_code}",
                response_data,
            )
    except Exception as e:
        print_error(f"Lỗi không xác định khi lấy roster: {e}")
        status_code = 500
        response_data = {"error": str(e)}
    finally:
        log_api_call("GET", url, None, status_code, response_data)


# --- Bắt đầu các hàm kiểm thử lỗi ---


def test_create_enrollment_errors():
    """7. Kiểm thử các trường hợp lỗi của POST /api/v1/enrollments"""
    print_info("Bắt đầu kiểm thử các trường hợp TẠO LỖI (dự kiến 400/404)")
    url = f"{BASE_URL}/api/v1/enrollments"
    headers = get_auth_headers()
    if not headers:
        return

    test_cases = [
        (
            "Class ID không tồn tại (CLASS_NOT_FOUND)",
            {"classId": 32000, "studentUserId": 1},
            404,
        ),
        (
            "Student ID không tồn tại (USER_NOT_FOUND)",
            {"classId": 1, "studentUserId": 999999},
            404,
        ),
        (
            "Class ID sai kiểu (INVALID_FIELD_TYPE)",
            {"classId": "abc", "studentUserId": 1},
            400,
        ),
        (
            "Student ID sai kiểu (INVALID_FIELD_TYPE)",
            {"classId": 1, "studentUserId": "xyz"},
            400,
        ),
    ]

    for description, payload, expected_status in test_cases:
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


def test_already_enrolled_error():
    """8. Kiểm thử lỗi ALREADY_ENROLLED (400)"""
    print_info("Bắt đầu kiểm thử lỗi ALREADY_ENROLLED (400)")

    # Get a student who is already enrolled
    student_id = get_enrolled_student_id(class_id=1)
    if not student_id:
        print_error("Không tìm thấy student đã enrolled. Bỏ qua test ALREADY_ENROLLED.")
        return

    # Try to enroll the same student again (should get 400)
    class_id = 1
    print_info(
        f"Tạo lại enrollment ClassID: {class_id}, StudentID: {student_id} (dự kiến lỗi 400)..."
    )
    url = f"{BASE_URL}/api/v1/enrollments"
    headers = get_auth_headers()
    payload = {"classId": class_id, "studentUserId": student_id}

    try:
        response = requests.post(url, headers=headers, json=payload)
        if response.status_code == 400:
            print_success(
                f"Kiểm thử lỗi 'ALREADY_ENROLLED' thành công. Nhận mã trạng thái: 400"
            )
        else:
            print_error(
                f"Kiểm thử lỗi 'ALREADY_ENROLLED' THẤT BẠI. Dự kiến 400 nhưng nhận được {response.status_code}",
                response.json(),
            )
        log_api_call("POST", url, payload, response.status_code, response.json())
    except Exception as e:
        print_error(f"Lỗi không xác định khi kiểm thử ALREADY_ENROLLED: {e}")
        log_api_call("POST", url, payload, 500, {"error": str(e)})


def test_get_enrollment_errors():
    """9. Kiểm thử các trường hợp lỗi của GET /api/v1/enrollments/{classId}/{studentUserId}"""
    print_info("Bắt đầu kiểm thử các trường hợp LẤY LỖI (dự kiến 400/404)")
    headers = get_auth_headers()
    if not headers:
        return

    test_cases = [
        (
            "Enrollment không tồn tại (ENROLLMENT_NOT_FOUND)",
            f"{BASE_URL}/api/v1/enrollments/1/999999",
            404,
        ),
        (
            "Class ID sai định dạng (INVALID_FIELD_TYPE)",
            f"{BASE_URL}/api/v1/enrollments/abc/1",
            400,
        ),
        (
            "Student ID sai định dạng (INVALID_FIELD_TYPE)",
            f"{BASE_URL}/api/v1/enrollments/1/xyz",
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


def test_update_enrollment_errors():
    """10. Kiểm thử các trường hợp lỗi của PUT /api/v1/enrollments/{classId}/{studentUserId}"""
    print_info("Bắt đầu kiểm thử các trường hợp CẬP NHẬT LỖI (dự kiến 400/404)")
    headers = get_auth_headers()
    if not headers:
        return

    # Test enrollment not found
    print_info("Đang thử lỗi: Enrollment không tồn tại (ENROLLMENT_NOT_FOUND)")
    url = f"{BASE_URL}/api/v1/enrollments/1/999999"
    payload = {"isEnrolled": False}
    response_data = None
    status_code = 0
    try:
        response = requests.put(url, headers=headers, json=payload)
        status_code = response.status_code
        try:
            response_data = response.json()
        except json.JSONDecodeError:
            response_data = {"raw_response": response.text}

        if response.status_code == 404:
            print_success(
                f"Kiểm thử lỗi 'ENROLLMENT_NOT_FOUND' thành công. Nhận mã trạng thái: 404"
            )
        else:
            print_error(
                f"Kiểm thử lỗi 'ENROLLMENT_NOT_FOUND' THẤT BẠI. Dự kiến 404 nhưng nhận được {status_code}",
                response_data,
            )
    except Exception as e:
        print_error(f"Lỗi không xác định khi kiểm thử ENROLLMENT_NOT_FOUND: {e}")
        status_code = 500
        response_data = {"error": str(e)}
    finally:
        log_api_call("PUT", url, payload, status_code, response_data)


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

    # Get an available student who is not yet enrolled
    available_student_id = get_available_student_id(class_id=1)
    if not available_student_id:
        print_error("Không tìm thấy student chưa enrolled để test. Bỏ qua Happy Path.")
        class_id, student_id = None, None
    else:
        class_id, student_id, status_code = test_create_enrollment(
            1, available_student_id
        )

    if class_id:
        print("-" * 30)
        test_get_enrollment_by_key(class_id, student_id)
        print("-" * 30)
        test_update_enrollment(class_id, student_id, False)
        print("-" * 30)
        test_get_enrollment_by_key(class_id, student_id)
        print("-" * 30)
        test_update_enrollment(class_id, student_id, True)
    else:
        print_error(
            "Không thể tạo Enrollment. Bỏ qua các bài kiểm thử phụ thuộc 'Happy Path'."
        )

    print("=" * 30)

    # 3. Chạy các bài kiểm thử lỗi
    print_info("Bắt đầu chạy các bài kiểm thử lỗi (Error Cases)")
    test_create_enrollment_errors()
    print("-" * 30)
    test_already_enrolled_error()
    print("-" * 30)
    test_get_enrollment_errors()
    print("-" * 30)
    test_update_enrollment_errors()

    print("=" * 30)

    # 4. Kiểm thử API Lấy Danh sách và Roster
    test_get_all_enrollments()
    print("-" * 30)
    test_get_class_roster(1)
    print("=" * 30)

    print_info("Tất cả các bài kiểm thử đã hoàn tất.")

    # 5. TẠO BÁO CÁO
    generate_markdown_report()


if __name__ == "__main__":
    main()
