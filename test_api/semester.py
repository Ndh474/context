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


def generate_markdown_report(filename="api_test_report_semesters.md"):
    """Tạo tệp Markdown từ dữ liệu đã lưu trữ."""
    print_info(f"Đang tạo báo cáo Markdown: {filename}")
    try:
        with open(filename, "w", encoding="utf-8") as f:
            f.write(
                f"# Báo cáo Kiểm thử API - Semesters ({time.strftime('%Y-%m-%d %H:%M:%S')})\n\n"
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


def test_create_semester():
    """2. Kiểm thử POST /api/v1/semesters (Tạo Học kỳ)"""
    print_info("Đang thử tạo Học kỳ mới...")
    url = f"{BASE_URL}/api/v1/semesters"
    headers = get_auth_headers()
    if not headers:
        return None, None, None, None

    # Tạo dữ liệu duy nhất
    ts = int(time.time())
    year = 2025 + (ts % 50)  # Tạo năm ngẫu nhiên từ 2025-2074
    unique_suffix = ts % 1000

    unique_code = f"FA{year}{unique_suffix}"
    unique_name = f"Fall {year} {unique_suffix}"[:20]  # Đảm bảo tên không quá 20 ký tự

    start_date = datetime(year, 9, 1)
    end_date = datetime(year, 12, 31)
    start_date_str = start_date.strftime("%Y-%m-%d")
    end_date_str = end_date.strftime("%Y-%m-%d")

    payload = {
        "name": unique_name,
        "code": unique_code,
        "startDate": start_date_str,
        "endDate": end_date_str,
    }

    response_data = None
    status_code = 0

    try:
        response = requests.post(url, headers=headers, json=payload)
        status_code = response.status_code
        response_data = response.json()

        if response.status_code == 201:
            semester_id = response_data.get("data", {}).get("id")
            print_success(f"Tạo Học kỳ thành công. ID mới: {semester_id}")
            log_api_call("POST", url, payload, status_code, response_data)
            return semester_id, unique_code, start_date_str, end_date_str
        else:
            print_error(
                f"Tạo Học kỳ thất bại. Mã trạng thái: {response.status_code}",
                response_data,
            )
            log_api_call("POST", url, payload, status_code, response_data)
            return None, None, None, None
    except Exception as e:
        print_error(f"Lỗi không xác định khi tạo học kỳ: {e}")
        log_api_call("POST", url, payload, 500, {"error": str(e)})
        return None, None, None, None


def test_get_semester_by_id(semester_id):
    """3. Kiểm thử GET /api/v1/semesters/{id} (Lấy Học kỳ theo ID)"""
    print_info(f"Đang thử lấy Học kỳ theo ID: {semester_id}")
    url = f"{BASE_URL}/api/v1/semesters/{semester_id}"
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
            print_success(f"Lấy Học kỳ {semester_id} thành công.")
        else:
            print_error(
                f"Lấy Học kỳ {semester_id} thất bại. Mã trạng thái: {response.status_code}",
                response_data,
            )
    except Exception as e:
        print_error(f"Lỗi không xác định khi lấy học kỳ {semester_id}: {e}")
        status_code = 500
        response_data = {"error": str(e)}
    finally:
        log_api_call("GET", url, None, status_code, response_data)


def test_update_semester(semester_id, code, start_date, end_date):
    """4. Kiểm thử PUT /api/v1/semesters/{id} (Cập nhật Học kỳ)"""
    print_info(f"Đang thử cập nhật Học kỳ ID: {semester_id}")
    url = f"{BASE_URL}/api/v1/semesters/{semester_id}"
    headers = get_auth_headers()
    if not headers:
        return

    new_name = f"Upd {code}"[:20]

    payload = {
        "name": new_name,
        "code": code,
        "startDate": start_date,
        "endDate": end_date,
        "isActive": True,
    }

    response_data = None
    status_code = 0
    try:
        response = requests.put(url, headers=headers, json=payload)
        status_code = response.status_code
        response_data = response.json()

        if response.status_code == 200:
            print_success(f"Cập nhật Học kỳ {semester_id} thành công.")
        else:
            print_error(
                f"Cập nhật Học kỳ {semester_id} thất bại. Mã trạng thái: {response.status_code}",
                response_data,
            )
    except Exception as e:
        print_error(f"Lỗi không xác định khi cập nhật học kỳ {semester_id}: {e}")
        status_code = 500
        response_data = {"error": str(e)}
    finally:
        log_api_call("PUT", url, payload, status_code, response_data)


def test_get_semester_classes(semester_id):
    """5. Kiểm thử GET /api/v1/semesters/{id}/classes (Lấy Lớp học của Học kỳ)"""
    print_info(f"Đang thử lấy các lớp học của Học kỳ ID: {semester_id}")
    url = f"{BASE_URL}/api/v1/semesters/{semester_id}/classes?sort=desc&pageSize=10"
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
                f"Lấy các lớp học của Học kỳ {semester_id} thành công. Tìm thấy: {count} lớp."
            )
        else:
            print_error(
                f"Lấy các lớp học của Học kỳ {semester_id} thất bại. Mã trạng thái: {response.status_code}",
                response_data,
            )
    except Exception as e:
        print_error(
            f"Lỗi không xác định khi lấy các lớp học của học kỳ {semester_id}: {e}"
        )
        status_code = 500
        response_data = {"error": str(e)}
    finally:
        log_api_call("GET", url, None, status_code, response_data)


def test_get_semester_subjects(semester_id):
    """6. Kiểm thử GET /api/v1/semesters/{id}/subjects (Lấy Môn học của Học kỳ)"""
    print_info(f"Đang thử lấy các môn học của Học kỳ ID: {semester_id}")
    url = f"{BASE_URL}/api/v1/semesters/{semester_id}/subjects?sort=desc&pageSize=10"
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
                f"Lấy các môn học của Học kỳ {semester_id} thành công. Tìm thấy: {count} môn."
            )
        else:
            print_error(
                f"Lấy các môn học của Học kỳ {semester_id} thất bại. Mã trạng thái: {response.status_code}",
                response_data,
            )
    except Exception as e:
        print_error(
            f"Lỗi không xác định khi lấy các môn học của học kỳ {semester_id}: {e}"
        )
        status_code = 500
        response_data = {"error": str(e)}
    finally:
        log_api_call("GET", url, None, status_code, response_data)


def test_get_semester_students(semester_id):
    """7. Kiểm thử GET /api/v1/semesters/{id}/students (Lấy Sinh viên của Học kỳ)"""
    print_info(f"Đang thử lấy sinh viên của Học kỳ ID: {semester_id}")
    url = f"{BASE_URL}/api/v1/semesters/{semester_id}/students?sort=desc&pageSize=10"
    headers = get_auth_headers()
    if not headers:
        return

    response_data = None
    status_code = 0
    try:
        response = requests.get(url, headers=headers)
        status_code = response.status_code
        try:
            response_data = response.json()
        except json.JSONDecodeError:
            print_error(
                f"Phản hồi không phải JSON hợp lệ. Raw response: {response.text}"
            )
            response_data = {"raw_response": response.text}

        if response.status_code == 200:
            count = len(response_data.get("data", {}).get("items", []))
            print_success(
                f"Lấy sinh viên của Học kỳ {semester_id} thành công. Tìm thấy: {count} SV."
            )
        else:
            print_error(
                f"Lấy sinh viên của Học kỳ {semester_id} thất bại. Mã trạng thái: {response.status_code}",
                response_data,
            )
    except Exception as e:
        print_error(
            f"Lỗi không xác định khi lấy sinh viên của học kỳ {semester_id}: {e}"
        )
        status_code = 500
        response_data = {"error": str(e)}
    finally:
        log_api_call("GET", url, None, status_code, response_data)


def test_get_all_semesters():
    """8. Kiểm thử GET /api/v1/semesters (Lấy danh sách Học kỳ)"""
    print_info("Đang thử lấy danh sách Học kỳ (sort desc, pageSize 10)")
    url = f"{BASE_URL}/api/v1/semesters?sort=desc&pageSize=10"
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
            print_success(f"Lấy danh sách Học kỳ thành công. Tìm thấy: {count} học kỳ.")
        else:
            print_error(
                f"Lấy danh sách Học kỳ thất bại. Mã trạng thái: {response.status_code}",
                response_data,
            )
    except Exception as e:
        print_error(f"Lỗi không xác định khi lấy danh sách học kỳ: {e}")
        status_code = 500
        response_data = {"error": str(e)}
    finally:
        log_api_call("GET", url, None, status_code, response_data)


# --- Bắt đầu các hàm kiểm thử lỗi ---


def test_create_semester_errors():
    """9. Kiểm thử các trường hợp lỗi của POST /api/v1/semesters (không bao gồm trùng lặp)"""
    print_info("Bắt đầu kiểm thử các trường hợp TẠO LỖI (dự kiến 400)")
    url = f"{BASE_URL}/api/v1/semesters"
    headers = get_auth_headers()
    if not headers:
        return

    test_cases = [
        (
            "Tên rỗng (SEMESTER_NAME_REQUIRED)",
            {
                "name": "",
                "code": "ERR01",
                "startDate": "2090-01-01",
                "endDate": "2090-04-30",
            },
        ),
        (
            "Code rỗng (SEMESTER_CODE_REQUIRED)",
            {
                "name": "Test Sem",
                "code": "",
                "startDate": "2090-01-01",
                "endDate": "2090-04-30",
            },
        ),
        (
            "Ngày bắt đầu sau ngày kết thúc (SEMESTER_INVALID_DATE_RANGE)",
            {
                "name": "Test Sem Invalid Range",
                "code": "ERR06",
                "startDate": "2090-01-01",
                "endDate": "2089-12-31",
            },
        ),
        (
            "Định dạng ngày sai (INVALID_START/END_DATE_FORMAT)",
            {
                "name": "Test Sem Bad Format",
                "code": "ERR07",
                "startDate": "01-01-2090",
                "endDate": "30-04-2090",
            },
        ),
        (
            "Code sai định dạng (INVALID_FIELD_FORMAT)",
            {
                "name": "Test Sem",
                "code": "FA 24",
                "startDate": "2090-01-01",
                "endDate": "2090-04-30",
            },
        ),
        (
            "Tên sai định dạng (INVALID_FIELD_FORMAT - Dấu cách thừa)",
            {
                "name": " Fall 2090 ",
                "code": "ERR08",
                "startDate": "2090-01-01",
                "endDate": "2090-04-30",
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
    """NEW: Tự kiểm thử các lỗi trùng lặp một cách độc lập"""
    print_info("Bắt đầu kiểm thử các lỗi TẠO TRÙNG LẶP")
    url = f"{BASE_URL}/api/v1/semesters"
    headers = get_auth_headers()
    if not headers:
        return

    # Tạo dữ liệu duy nhất cho bài test này
    ts = int(time.time())
    year = 2080 + (ts % 10)
    unique_suffix = ts % 1000

    unique_code = f"DUP{year}{unique_suffix}"
    # SỬA LỖI: Tạo tên ngắn hơn để không vi phạm ràng buộc độ dài
    unique_name = f"Dup Test {unique_code}"[:20]
    start_date_str = f"{year}-01-01"
    end_date_str = f"{year}-05-31"

    payload = {
        "name": unique_name,
        "code": unique_code,
        "startDate": start_date_str,
        "endDate": end_date_str,
    }

    # Bước 1: Tạo lần đầu (phải thành công)
    print_info(f"Tạo học kỳ '{unique_code}' lần đầu...")
    try:
        response1 = requests.post(url, headers=headers, json=payload)
        if response1.status_code != 201:
            print_error(
                "Không thể tạo học kỳ ban đầu. Bỏ qua test trùng lặp.", response1.json()
            )
            log_api_call("POST", url, payload, response1.status_code, response1.json())
            return
        print_success("Tạo học kỳ ban đầu thành công.")
        log_api_call("POST", url, payload, response1.status_code, response1.json())
    except Exception as e:
        print_error(f"Lỗi khi tạo học kỳ ban đầu: {e}")
        return

    # Bước 2: Kiểm tra các trường hợp trùng lặp
    test_cases = [
        (
            "Code đã tồn tại (SEMESTER_CODE_EXISTS)",
            {
                **payload,
                "name": "New Name",
                "startDate": "2099-01-01",
                "endDate": "2099-05-31",
            },
        ),
        (
            "Tên đã tồn tại (SEMESTER_NAME_EXISTS)",
            {
                **payload,
                "code": "NEWCODE",
                "startDate": "2099-01-01",
                "endDate": "2099-05-31",
            },
        ),
        (
            "Khoảng ngày đã tồn tại (SEMESTER_DATE_RANGE_EXISTS)",
            {**payload, "name": "New Name 2", "code": "NEWCODE2"},
        ),
    ]

    for description, error_payload in test_cases:
        print_info(f"Đang thử lỗi: {description}")
        try:
            response = requests.post(url, headers=headers, json=error_payload)
            if response.status_code == 400:
                print_success(
                    f"Kiểm thử lỗi '{description}' thành công. Nhận mã trạng thái: 400"
                )
            else:
                print_error(
                    f"Kiểm thử lỗi '{description}' THẤT BẠI. Dự kiến 400 nhưng nhận được {response.status_code}",
                    response.json(),
                )
            log_api_call(
                "POST", url, error_payload, response.status_code, response.json()
            )
        except Exception as e:
            print_error(f"Lỗi không xác định khi kiểm thử '{description}': {e}")
            log_api_call("POST", url, error_payload, 500, {"error": str(e)})


def test_get_semester_by_id_errors():
    """10. Kiểm thử các trường hợp lỗi của GET /api/v1/semesters/{id}"""
    print_info("Bắt đầu kiểm thử các trường hợp LẤY LỖI (dự kiến 400/404)")
    headers = get_auth_headers()
    if not headers:
        return

    test_cases = [
        (
            "ID không tồn tại (SEMESTER_NOT_FOUND)",
            f"{BASE_URL}/api/v1/semesters/32000",
            404,
        ),
        (
            "ID sai định dạng (INVALID_FIELD_TYPE)",
            f"{BASE_URL}/api/v1/semesters/abc",
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
    new_id, new_code, new_start, new_end = test_create_semester()

    if new_id:
        print("-" * 30)
        test_get_semester_by_id(new_id)
        print("-" * 30)
        test_update_semester(new_id, new_code, new_start, new_end)
        print("-" * 30)
        test_get_semester_classes(new_id)
        print("-" * 30)
        test_get_semester_subjects(new_id)
        print("-" * 30)
        test_get_semester_students(new_id)
    else:
        print_error(
            "Không thể tạo Học kỳ. Bỏ qua các bài kiểm thử phụ thuộc 'Happy Path'."
        )

    print("=" * 30)

    # 3. Chạy các bài kiểm thử lỗi
    print_info("Bắt đầu chạy các bài kiểm thử lỗi (Error Cases)")
    test_create_semester_errors()
    print("-" * 30)
    test_duplicate_creation()
    print("-" * 30)
    test_get_semester_by_id_errors()

    print("=" * 30)

    # 4. Kiểm thử API Lấy Danh sách
    test_get_all_semesters()
    print("=" * 30)

    print_info("Tất cả các bài kiểm thử đã hoàn tất.")

    # 5. TẠO BÁO CÁO
    generate_markdown_report()


if __name__ == "__main__":
    main()
