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
BASE_URL = "http://localhost:8080"
OUTPUT_FILE = "api_test_report_exam_attendance.md"
USERNAME = "dop001"
PASSWORD = "12345678"
# ----------------

# Biến toàn cục
access_token = None
test_results = []


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


def add_test_result(test_name, method, url, status_code, request_body=None, response_body=None, params=None):
    """Lưu trữ chi tiết cuộc gọi API để tạo báo cáo."""
    test_results.append({
        'test_name': test_name,
        'method': method,
        'url': url,
        'status_code': status_code,
        'request_body': request_body,
        'response_body': response_body,
        'params': params
    })


def generate_markdown_report():
    """Tạo tệp Markdown từ dữ liệu đã lưu trữ."""
    print_info(f"Đang tạo báo cáo Markdown: {OUTPUT_FILE}")
    try:
        with open(OUTPUT_FILE, 'w', encoding='utf-8') as f:
            f.write(f"# Báo cáo Kiểm thử API - Exam Attendance ({datetime.now().strftime('%Y-%m-%d %H:%M:%S')})\n\n")

            for idx, result in enumerate(test_results, 1):
                f.write(f"## {idx}. {result['method']} {result['url']}\n\n")
                f.write(f"**Trạng thái Phản hồi:** `{result['status_code']}`\n\n")

                # Write query parameters if present
                if result.get('params'):
                    f.write(f"**Query Parameters:**\n```json\n{json.dumps(result['params'], indent=2, ensure_ascii=False)}\n```\n\n")

                # Write request body if present
                if result['request_body']:
                    f.write(f"**Request Payload (Nội dung Gửi đi):**\n```json\n{json.dumps(result['request_body'], indent=2, ensure_ascii=False)}\n```\n\n")

                # Write response body
                if result['response_body']:
                    f.write(f"**Response Body (Nội dung Nhận về):**\n```json\n{json.dumps(result['response_body'], indent=2, ensure_ascii=False)}\n```\n\n")

                f.write("---\n\n")
        print_success(f"Tạo báo cáo {OUTPUT_FILE} thành công.")
    except Exception as e:
        print_error(f"Không thể ghi tệp báo cáo: {e}")


def get_auth_headers():
    """Trả về headers 'Authorization' đã được định dạng."""
    if not access_token:
        print_error("Chưa đăng nhập. Không thể lấy headers.")
        return None
    return {
        'Authorization': f'Bearer {access_token}',
        'Content-Type': 'application/json'
    }


# --- Các hàm Kiểm thử (Test Functions) ---

def login():
    """1. Đăng nhập để lấy Access Token"""
    global access_token
    print_info("Đang thử đăng nhập với user: " + USERNAME)
    url = f"{BASE_URL}/api/v1/auth/login"
    payload = {"username": USERNAME, "password": PASSWORD}

    try:
        response = requests.post(url, json=payload)
        response_data = response.json()
        add_test_result("Login", "POST", url, response.status_code, payload, response_data)

        if response.status_code == 200:
            access_token = response_data.get('accessToken')
            if access_token:
                print_success("Đăng nhập thành công. Đã lấy Access Token.")
                return True
            else:
                print_error("Đăng nhập thành công nhưng không tìm thấy 'accessToken'.", response_data)
                return False
        else:
            print_error(f"Đăng nhập thất bại. Mã trạng thái: {response.status_code}", response_data)
            return False
    except requests.exceptions.ConnectionError:
        print_error(f"Không thể kết nối đến {BASE_URL}. Hãy đảm bảo máy chủ đang chạy.")
        return False
    except Exception as e:
        print_error(f"Lỗi không xác định khi đăng nhập: {e}")
        return False


def get_exam_attendance_id():
    """Lấy một exam attendance ID để test"""
    print_info("Đang lấy một exam attendance ID để test...")
    url = f"{BASE_URL}/api/v1/exam-attendance"
    params = {'pageSize': 1, 'sort': 'desc'}

    try:
        response = requests.get(url, headers=get_auth_headers(), params=params)
        if response.status_code == 200:
            data = response.json()
            items = data.get('data', {}).get('items', [])
            if items:
                exam_attendance_id = items[0]['id']
                print_success(f"  ✓ Đã lấy exam attendance ID: {exam_attendance_id}")
                return exam_attendance_id

        # Strategy 2: Try filtering by status
        print_info("  Cách 1: Không tìm thấy dữ liệu, thử lọc theo status...")
        url_with_filter = f"{BASE_URL}/api/v1/exam-attendance"
        params_filter = {'pageSize': 10, 'status': 'present'}
        response = requests.get(url_with_filter, headers=get_auth_headers(), params=params_filter)
        if response.status_code == 200:
            data = response.json()
            items = data.get('data', {}).get('items', [])
            if items:
                exam_attendance_id = items[0]['id']
                print_success(f"  ✓ Đã lấy exam attendance ID (lọc theo status): {exam_attendance_id}")
                return exam_attendance_id

        # Strategy 3: Try without any filters
        print_info("  Cách 2: Thử truy vấn không có bộ lọc...")
        response = requests.get(f"{BASE_URL}/api/v1/exam-attendance", headers=get_auth_headers(), params={'pageSize': 10})
        if response.status_code == 200:
            data = response.json()
            items = data.get('data', {}).get('items', [])
            if items:
                exam_attendance_id = items[0]['id']
                print_success(f"  ✓ Đã lấy exam attendance ID (không bộ lọc): {exam_attendance_id}")
                return exam_attendance_id

        print_error("⚠️  KHÔNG TÌM THẤY EXAM ATTENDANCE RECORDS!")
        print_info("📝 Lưu ý: Database có thể có dữ liệu cũ hoặc chưa khởi tạo")
        print_info("   - Exam attendance records tồn tại nhưng không được trả về")
        print_info("   - Có thể do lỗi SQL query hoặc dữ liệu không khớp với bộ lọc")
        return None

    except Exception as e:
        print_error(f"Lỗi khi lấy exam attendance ID: {str(e)}")
        return None


def test_get_exam_attendance_list():
    """2. Kiểm thử GET /api/v1/exam-attendance - Lấy danh sách exam attendance"""
    print_info("Đang thử lấy danh sách exam attendance records...")
    url = f"{BASE_URL}/api/v1/exam-attendance"
    params = {'sort': 'desc', 'pageSize': 10}

    try:
        response = requests.get(url, headers=get_auth_headers(), params=params)
        response_data = response.json()
        add_test_result("GET exam attendance list", "GET", url, response.status_code, params=params, response_body=response_data)

        if response.status_code == 200:
            total_items = response_data.get('data', {}).get('totalItems', 0)
            print_success(f"Lấy danh sách thành công. Tổng số: {total_items} records")
            return True
        else:
            print_error(f"Lấy danh sách thất bại. Mã trạng thái: {response.status_code}", response_data)
            return False
    except Exception as e:
        print_error(f"Lỗi không xác định: {e}")
        return False


def test_get_exam_attendance_by_id(exam_attendance_id):
    """3. Kiểm thử GET /api/v1/exam-attendance/{id} - Lấy exam attendance theo ID"""
    print_info(f"Đang thử lấy exam attendance với ID: {exam_attendance_id}")
    url = f"{BASE_URL}/api/v1/exam-attendance/{exam_attendance_id}"

    try:
        response = requests.get(url, headers=get_auth_headers())
        response_data = response.json()
        add_test_result("GET exam attendance by ID", "GET", url, response.status_code, response_body=response_data)

        if response.status_code == 200:
            print_success(f"Lấy exam attendance thành công")
            return True
        else:
            print_error(f"Lấy exam attendance thất bại. Mã trạng thái: {response.status_code}", response_data)
            return False
    except Exception as e:
        print_error(f"Lỗi không xác định: {e}")
        return False


def test_update_exam_attendance(exam_attendance_id):
    """4. Kiểm thử PUT /api/v1/exam-attendance/{id} - Cập nhật trạng thái exam attendance"""
    print_info(f"Đang thử cập nhật exam attendance với ID: {exam_attendance_id}")
    url = f"{BASE_URL}/api/v1/exam-attendance/{exam_attendance_id}"
    payload = {
        "status": "present",
        "remark": "Cập nhật thủ công để kiểm thử API - Student completed the exam"
    }

    try:
        response = requests.put(url, headers=get_auth_headers(), json=payload)
        response_data = response.json()
        add_test_result("PUT update exam attendance", "PUT", url, response.status_code, request_body=payload, response_body=response_data)

        if response.status_code == 200:
            print_success(f"Cập nhật exam attendance thành công")
            return True
        else:
            print_error(f"Cập nhật thất bại. Mã trạng thái: {response.status_code}", response_data)
            return False
    except Exception as e:
        print_error(f"Lỗi không xác định: {e}")
        return False


def test_get_exam_attendance_with_filter():
    """5. Kiểm thử GET với bộ lọc status"""
    print_info("Đang thử lấy danh sách với bộ lọc status=present...")
    url = f"{BASE_URL}/api/v1/exam-attendance"
    params = {'status': 'present', 'pageSize': 10}

    try:
        response = requests.get(url, headers=get_auth_headers(), params=params)
        response_data = response.json()
        add_test_result("GET exam attendance with filter", "GET", url, response.status_code, params=params, response_body=response_data)

        if response.status_code == 200:
            total_items = response_data.get('data', {}).get('totalItems', 0)
            print_success(f"Lấy danh sách với bộ lọc thành công. Tổng số: {total_items} records")
            return True
        else:
            print_error(f"Lấy danh sách thất bại. Mã trạng thái: {response.status_code}", response_data)
            return False
    except Exception as e:
        print_error(f"Lỗi không xác định: {e}")
        return False


# --- Các hàm kiểm thử lỗi (Error validation tests) ---

def test_get_nonexistent_exam_attendance():
    """6. Kiểm thử GET với ID không tồn tại - Dự kiến 404"""
    print_info("Đang thử lấy exam attendance với ID không tồn tại (999999999)...")
    url = f"{BASE_URL}/api/v1/exam-attendance/999999999"

    try:
        response = requests.get(url, headers=get_auth_headers())
        response_data = response.json()
        add_test_result("GET non-existent exam attendance", "GET", url, response.status_code, response_body=response_data)

        if response.status_code == 404:
            print_success(f"Kiểm thử lỗi thành công. Nhận mã: {response.status_code}")
            return True
        else:
            print_error(f"Kiểm thử lỗi thất bại. Dự kiến 404 nhưng nhận được {response.status_code}", response_data)
            return False
    except Exception as e:
        print_error(f"Lỗi không xác định: {e}")
        return False


def test_get_invalid_id_type():
    """7. Kiểm thử GET với ID sai định dạng - Dự kiến 400"""
    print_info("Đang thử lấy exam attendance với ID sai định dạng (abc)...")
    url = f"{BASE_URL}/api/v1/exam-attendance/abc"

    try:
        response = requests.get(url, headers=get_auth_headers())
        response_data = response.json()
        add_test_result("GET with invalid ID type", "GET", url, response.status_code, response_body=response_data)

        if response.status_code == 400:
            print_success(f"Kiểm thử lỗi thành công. Nhận mã: {response.status_code}")
            return True
        else:
            print_error(f"Kiểm thử lỗi thất bại. Dự kiến 400 nhưng nhận được {response.status_code}", response_data)
            return False
    except Exception as e:
        print_error(f"Lỗi không xác định: {e}")
        return False


def test_update_without_status(exam_attendance_id):
    """8. Kiểm thử PUT thiếu trường status - Dự kiến 400"""
    if not exam_attendance_id:
        print_info("Bỏ qua test (không có exam attendance ID)")
        return False

    print_info("Đang thử cập nhật không có trường status...")
    url = f"{BASE_URL}/api/v1/exam-attendance/{exam_attendance_id}"
    payload = {"remark": "Test remark"}

    try:
        response = requests.put(url, headers=get_auth_headers(), json=payload)
        response_data = response.json()
        add_test_result("PUT without status field", "PUT", url, response.status_code, request_body=payload, response_body=response_data)

        if response.status_code == 400:
            print_success(f"Kiểm thử lỗi thành công. Nhận mã: {response.status_code}")
            return True
        else:
            print_error(f"Kiểm thử lỗi thất bại. Dự kiến 400 nhưng nhận được {response.status_code}", response_data)
            return False
    except Exception as e:
        print_error(f"Lỗi không xác định: {e}")
        return False


def test_update_with_empty_remark(exam_attendance_id):
    """9. Kiểm thử PUT với remark rỗng - Dự kiến 400"""
    if not exam_attendance_id:
        print_info("Bỏ qua test (không có exam attendance ID)")
        return False

    print_info("Đang thử cập nhật với remark rỗng...")
    url = f"{BASE_URL}/api/v1/exam-attendance/{exam_attendance_id}"
    payload = {"status": "present", "remark": ""}

    try:
        response = requests.put(url, headers=get_auth_headers(), json=payload)
        response_data = response.json()
        add_test_result("PUT with empty remark", "PUT", url, response.status_code, request_body=payload, response_body=response_data)

        if response.status_code == 400:
            print_success(f"Kiểm thử lỗi thành công. Nhận mã: {response.status_code}")
            return True
        else:
            print_error(f"Kiểm thử lỗi thất bại. Dự kiến 400 nhưng nhận được {response.status_code}", response_data)
            return False
    except Exception as e:
        print_error(f"Lỗi không xác định: {e}")
        return False


def test_update_with_invalid_status(exam_attendance_id):
    """10. Kiểm thử PUT với giá trị status không hợp lệ - Dự kiến 400"""
    if not exam_attendance_id:
        print_info("Bỏ qua test (không có exam attendance ID)")
        return False

    print_info("Đang thử cập nhật với status không hợp lệ...")
    url = f"{BASE_URL}/api/v1/exam-attendance/{exam_attendance_id}"
    payload = {"status": "invalid_status", "remark": "Test remark"}

    try:
        response = requests.put(url, headers=get_auth_headers(), json=payload)
        response_data = response.json()
        add_test_result("PUT with invalid status value", "PUT", url, response.status_code, request_body=payload, response_body=response_data)

        if response.status_code == 400:
            print_success(f"Kiểm thử lỗi thành công. Nhận mã: {response.status_code}")
            return True
        else:
            print_error(f"Kiểm thử lỗi thất bại. Dự kiến 400 nhưng nhận được {response.status_code}", response_data)
            return False
    except Exception as e:
        print_error(f"Lỗi không xác định: {e}")
        return False


def test_update_without_remark(exam_attendance_id):
    """11. Kiểm thử PUT thiếu trường remark - Dự kiến 400"""
    if not exam_attendance_id:
        print_info("Bỏ qua test (không có exam attendance ID)")
        return False

    print_info("Đang thử cập nhật không có trường remark...")
    url = f"{BASE_URL}/api/v1/exam-attendance/{exam_attendance_id}"
    payload = {"status": "absent"}

    try:
        response = requests.put(url, headers=get_auth_headers(), json=payload)
        response_data = response.json()
        add_test_result("PUT without remark field", "PUT", url, response.status_code, request_body=payload, response_body=response_data)

        if response.status_code == 400:
            print_success(f"Kiểm thử lỗi thành công. Nhận mã: {response.status_code}")
            return True
        else:
            print_error(f"Kiểm thử lỗi thất bại. Dự kiến 400 nhưng nhận được {response.status_code}", response_data)
            return False
    except Exception as e:
        print_error(f"Lỗi không xác định: {e}")
        return False


def test_get_with_invalid_page():
    """12. Kiểm thử GET với tham số page không hợp lệ - Dự kiến 400"""
    print_info("Đang thử lấy danh sách với page=-1...")
    url = f"{BASE_URL}/api/v1/exam-attendance"
    params = {'page': -1}

    try:
        response = requests.get(url, headers=get_auth_headers(), params=params)
        response_data = response.json()
        add_test_result("GET with invalid page", "GET", url, response.status_code, params=params, response_body=response_data)

        if response.status_code == 400:
            print_success(f"Kiểm thử lỗi thành công. Nhận mã: {response.status_code}")
            return True
        else:
            print_error(f"Kiểm thử lỗi thất bại. Dự kiến 400 nhưng nhận được {response.status_code}", response_data)
            return False
    except Exception as e:
        print_error(f"Lỗi không xác định: {e}")
        return False


def test_get_with_invalid_sort():
    """13. Kiểm thử GET với tham số sort không hợp lệ - Dự kiến 400"""
    print_info("Đang thử lấy danh sách với sort=invalid...")
    url = f"{BASE_URL}/api/v1/exam-attendance"
    params = {'sort': 'invalid', 'pageSize': 10}

    try:
        response = requests.get(url, headers=get_auth_headers(), params=params)
        response_data = response.json()
        add_test_result("GET with invalid sort", "GET", url, response.status_code, params=params, response_body=response_data)

        if response.status_code == 400:
            print_success(f"Kiểm thử lỗi thành công. Nhận mã: {response.status_code}")
            return True
        else:
            print_error(f"Kiểm thử lỗi thất bại. Dự kiến 400 nhưng nhận được {response.status_code}", response_data)
            return False
    except Exception as e:
        print_error(f"Lỗi không xác định: {e}")
        return False


def test_get_with_invalid_status_filter():
    """14. Kiểm thử GET với bộ lọc status không hợp lệ - Dự kiến 400"""
    print_info("Đang thử lấy danh sách với status=invalid_status...")
    url = f"{BASE_URL}/api/v1/exam-attendance"
    params = {'status': 'invalid_status', 'pageSize': 10}

    try:
        response = requests.get(url, headers=get_auth_headers(), params=params)
        response_data = response.json()
        add_test_result("GET with invalid status filter", "GET", url, response.status_code, params=params, response_body=response_data)

        if response.status_code == 400:
            print_success(f"Kiểm thử lỗi thành công. Nhận mã: {response.status_code}")
            return True
        else:
            print_error(f"Kiểm thử lỗi thất bại. Dự kiến 400 nhưng nhận được {response.status_code}", response_data)
            return False
    except Exception as e:
        print_error(f"Lỗi không xác định: {e}")
        return False


# --- Hàm chính (Main) ---

def main():
    """Chạy chu trình kiểm thử."""
    print("=" * 80)
    print("KIỂM THỬ API - EXAM ATTENDANCE")
    print("=" * 80)

    # 1. Đăng nhập
    if not login():
        print_error("Không thể tiếp tục nếu không đăng nhập. Đang thoát.")
        generate_markdown_report()
        return

    print("\n" + "=" * 80)
    print("CÁC KIỂM THỬ HAPPY PATH")
    print("=" * 80)

    # Lấy exam attendance ID cho các bài test
    exam_attendance_id = get_exam_attendance_id()

    # Happy path tests
    test_get_exam_attendance_list()

    if exam_attendance_id:
        print("-" * 30)
        test_get_exam_attendance_by_id(exam_attendance_id)
        print("-" * 30)
        test_update_exam_attendance(exam_attendance_id)
        print("-" * 30)
        test_get_exam_attendance_with_filter()
    else:
        print_error("⚠️  KHÔNG TÌM THẤY EXAM ATTENDANCE DATA!")
        print_info("📝 Các bài kiểm thử GET by ID và PUT update đã bị bỏ qua.")
        print_info("📝 Điều này có thể do database có dates cũ hoặc không có exam attendance records.")

    print("\n" + "=" * 80)
    print("CÁC KIỂM THỬ VALIDATION LỖI")
    print("=" * 80)

    # Error validation tests
    test_get_nonexistent_exam_attendance()
    print("-" * 30)
    test_get_invalid_id_type()
    print("-" * 30)
    test_update_without_status(exam_attendance_id)
    print("-" * 30)
    test_update_with_empty_remark(exam_attendance_id)
    print("-" * 30)
    test_update_with_invalid_status(exam_attendance_id)
    print("-" * 30)
    test_update_without_remark(exam_attendance_id)
    print("-" * 30)
    test_get_with_invalid_page()
    print("-" * 30)
    test_get_with_invalid_sort()
    print("-" * 30)
    test_get_with_invalid_status_filter()

    # Tạo báo cáo
    print("\n" + "=" * 80)
    generate_markdown_report()
    print("=" * 80)
    print_info("TẤT CẢ CÁC BÀI KIỂM THỬ ĐÃ HOÀN TẤT")
    print("=" * 80)


if __name__ == "__main__":
    main()
