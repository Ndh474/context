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


def generate_markdown_report(filename="api_test_report_permissions.md"):
    """Tạo tệp Markdown từ dữ liệu đã lưu trữ."""
    print_info(f"Đang tạo báo cáo Markdown: {filename}")
    try:
        with open(filename, "w", encoding="utf-8") as f:
            f.write(
                f"# Báo cáo Kiểm thử API - Permissions ({time.strftime('%Y-%m-%d %H:%M:%S')})\n\n"
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


def test_create_permission(suffix=""):
    """2. Kiểm thử POST /api/v1/permissions (Tạo Permission)"""
    print_info(f"Đang thử tạo Permission mới{' ' + suffix if suffix else ''}...")
    url = f"{BASE_URL}/api/v1/permissions"
    headers = get_auth_headers()
    if not headers:
        return None, None

    ts = int(time.time() * 1000)  # Use milliseconds for higher uniqueness
    unique_name = f"TEST_PERMISSION_{ts}"
    if suffix:
        unique_name = f"TEST_PERMISSION_{suffix}_{ts}"

    payload = {"name": unique_name}

    response_data = None
    status_code = 0

    try:
        response = requests.post(url, headers=headers, json=payload)
        status_code = response.status_code
        response_data = response.json()

        if response.status_code == 201:
            permission_id = response_data.get("data", {}).get("id")
            print_success(
                f"Tạo Permission '{unique_name}' thành công. ID mới: {permission_id}"
            )
            log_api_call("POST", url, payload, status_code, response_data)
            return permission_id, unique_name
        else:
            print_error(
                f"Tạo Permission thất bại. Mã trạng thái: {response.status_code}",
                response_data,
            )
            log_api_call("POST", url, payload, status_code, response_data)
            return None, None
    except Exception as e:
        print_error(f"Lỗi không xác định khi tạo permission: {e}")
        log_api_call("POST", url, payload, 500, {"error": str(e)})
        return None, None


def test_get_permission_by_id(permission_id):
    """3. Kiểm thử GET /api/v1/permissions/{id} (Lấy Permission theo ID)"""
    print_info(f"Đang thử lấy Permission theo ID: {permission_id}")
    url = f"{BASE_URL}/api/v1/permissions/{permission_id}"
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
            print_success(f"Lấy Permission {permission_id} thành công.")
        else:
            print_error(
                f"Lấy Permission {permission_id} thất bại. Mã trạng thái: {response.status_code}",
                response_data,
            )
    except Exception as e:
        print_error(f"Lỗi không xác định khi lấy permission {permission_id}: {e}")
        status_code = 500
        response_data = {"error": str(e)}
    finally:
        log_api_call("GET", url, None, status_code, response_data)


def test_update_permission(permission_id, name):
    """4. Kiểm thử PUT /api/v1/permissions/{id} (Cập nhật Permission)"""
    print_info(f"Đang thử cập nhật Permission ID: {permission_id}")
    url = f"{BASE_URL}/api/v1/permissions/{permission_id}"
    headers = get_auth_headers()
    if not headers:
        return

    new_name = f"UPDATED_{name}"[:255]

    payload = {
        "name": new_name,
        "isActive": True,
    }

    response_data = None
    status_code = 0
    try:
        response = requests.put(url, headers=headers, json=payload)
        status_code = response.status_code
        response_data = response.json()

        if response.status_code == 200:
            print_success(f"Cập nhật Permission {permission_id} thành công.")
        else:
            print_error(
                f"Cập nhật Permission {permission_id} thất bại. Mã trạng thái: {response.status_code}",
                response_data,
            )
    except Exception as e:
        print_error(f"Lỗi không xác định khi cập nhật permission {permission_id}: {e}")
        status_code = 500
        response_data = {"error": str(e)}
    finally:
        log_api_call("PUT", url, payload, status_code, response_data)


def test_delete_permission(permission_id):
    """5. Kiểm thử DELETE /api/v1/permissions/{id} (Xóa Permission)"""
    print_info(f"Đang thử xóa Permission ID: {permission_id}")
    url = f"{BASE_URL}/api/v1/permissions/{permission_id}"
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
            print_success(f"Xóa Permission {permission_id} thành công.")
        else:
            print_error(
                f"Xóa Permission {permission_id} thất bại. Mã trạng thái: {response.status_code}",
                response_data,
            )
    except Exception as e:
        print_error(f"Lỗi không xác định khi xóa permission {permission_id}: {e}")
        status_code = 500
        response_data = {"error": str(e)}
    finally:
        log_api_call("DELETE", url, None, status_code, response_data)


def test_get_all_permissions():
    """6. Kiểm thử GET /api/v1/permissions (Lấy danh sách Permission)"""
    print_info("Đang thử lấy danh sách Permission (sort desc, pageSize 10)")
    url = f"{BASE_URL}/api/v1/permissions?sort=desc&pageSize=10"
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
                f"Lấy danh sách Permission thành công. Tìm thấy: {count} permission."
            )
        else:
            print_error(
                f"Lấy danh sách Permission thất bại. Mã trạng thái: {response.status_code}",
                response_data,
            )
    except Exception as e:
        print_error(f"Lỗi không xác định khi lấy danh sách permission: {e}")
        status_code = 500
        response_data = {"error": str(e)}
    finally:
        log_api_call("GET", url, None, status_code, response_data)


# --- Bắt đầu các hàm kiểm thử lỗi ---


def test_create_permission_errors():
    """7. Kiểm thử các trường hợp lỗi của POST /api/v1/permissions (không bao gồm trùng lặp)"""
    print_info("Bắt đầu kiểm thử các trường hợp TẠO LỖI (dự kiến 400)")
    url = f"{BASE_URL}/api/v1/permissions"
    headers = get_auth_headers()
    if not headers:
        return

    test_cases = [
        ("Tên rỗng (NAME_REQUIRED)", {"name": ""}),
        ("Tên null", {}),
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
    """8. Tự kiểm thử lỗi tạo trùng lặp (PERMISSION_NAME_EXISTS)"""
    print_info("Bắt đầu kiểm thử lỗi TẠO TRÙNG LẶP (PERMISSION_NAME_EXISTS)")

    # Bước 1: Tạo một permission duy nhất để làm cơ sở
    permission_id, permission_name = test_create_permission("For-Dup-Test")
    if not permission_id:
        print_error("Không thể tạo permission ban đầu. Bỏ qua test trùng lặp.")
        return

    # Bước 2: Cố gắng tạo lại permission với cùng tên
    print_info(f"Tạo lại permission '{permission_name}' (dự kiến lỗi 400)...")
    url = f"{BASE_URL}/api/v1/permissions"
    headers = get_auth_headers()
    payload = {"name": permission_name}

    try:
        response = requests.post(url, headers=headers, json=payload)
        if response.status_code == 400:
            print_success(
                f"Kiểm thử lỗi 'PERMISSION_NAME_EXISTS' thành công. Nhận mã trạng thái: 400"
            )
        else:
            print_error(
                f"Kiểm thử lỗi 'PERMISSION_NAME_EXISTS' THẤT BẠI. Dự kiến 400 nhưng nhận được {response.status_code}",
                response.json(),
            )
        log_api_call("POST", url, payload, response.status_code, response.json())
    except Exception as e:
        print_error(f"Lỗi không xác định khi kiểm thử trùng lặp: {e}")
        log_api_call("POST", url, payload, 500, {"error": str(e)})


def test_update_permission_errors():
    """9. Tự kiểm thử lỗi cập nhật trùng tên (PERMISSION_NAME_EXISTS)"""
    print_info("Bắt đầu kiểm thử lỗi CẬP NHẬT TRÙNG TÊN (PERMISSION_NAME_EXISTS)")

    # Bước 1: Tạo hai permission riêng biệt
    permission1_id, permission1_name = test_create_permission("A-For-Update-Test")
    permission2_id, permission2_name = test_create_permission("B-For-Update-Test")

    if not (permission1_id and permission2_id):
        print_error("Không thể tạo đủ permission để test lỗi cập nhật. Bỏ qua.")
        return

    # Bước 2: Cố gắng cập nhật permission 2 để có tên giống permission 1
    print_info(
        f"Cập nhật permission '{permission2_name}' thành '{permission1_name}' (dự kiến lỗi 400)..."
    )
    url = f"{BASE_URL}/api/v1/permissions/{permission2_id}"
    headers = get_auth_headers()
    payload = {"name": permission1_name, "isActive": True}

    try:
        response = requests.put(url, headers=headers, json=payload)
        if response.status_code == 400:
            print_success(
                f"Kiểm thử lỗi cập nhật trùng tên thành công. Nhận mã trạng thái: 400"
            )
        else:
            print_error(
                f"Kiểm thử lỗi cập nhật trùng tên THẤT BẠI. Dự kiến 400 nhưng nhận được {response.status_code}",
                response.json(),
            )
        log_api_call("PUT", url, payload, response.status_code, response.json())
    except Exception as e:
        print_error(f"Lỗi không xác định khi kiểm thử cập nhật trùng tên: {e}")
        log_api_call("PUT", url, payload, 500, {"error": str(e)})


def test_get_permission_by_id_errors():
    """10. Kiểm thử các trường hợp lỗi của GET /api/v1/permissions/{id}"""
    print_info("Bắt đầu kiểm thử các trường hợp LẤY LỖI (dự kiến 400/404)")
    headers = get_auth_headers()
    if not headers:
        return

    test_cases = [
        (
            "ID không tồn tại (PERMISSION_NOT_FOUND)",
            f"{BASE_URL}/api/v1/permissions/32000",
            404,
        ),
        (
            "ID sai định dạng (INVALID_FIELD_TYPE)",
            f"{BASE_URL}/api/v1/permissions/abc",
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


def test_update_permission_not_found():
    """11. Kiểm thử lỗi cập nhật permission không tồn tại"""
    print_info("Đang thử cập nhật permission không tồn tại (dự kiến 404)")
    url = f"{BASE_URL}/api/v1/permissions/32000"
    headers = get_auth_headers()
    if not headers:
        return

    payload = {"name": "NONEXISTENT_PERMISSION", "isActive": True}
    response_data = None
    status_code = 0

    try:
        response = requests.put(url, headers=headers, json=payload)
        status_code = response.status_code
        response_data = response.json()

        if response.status_code == 404:
            print_success(
                f"Kiểm thử lỗi 'PERMISSION_NOT_FOUND' (UPDATE) thành công. Nhận mã trạng thái: 404"
            )
        else:
            print_error(
                f"Kiểm thử lỗi 'PERMISSION_NOT_FOUND' (UPDATE) THẤT BẠI. Dự kiến 404 nhưng nhận được {status_code}",
                response_data,
            )
    except Exception as e:
        print_error(f"Lỗi không xác định khi kiểm thử update not found: {e}")
        status_code = 500
        response_data = {"error": str(e)}
    finally:
        log_api_call("PUT", url, payload, status_code, response_data)


def test_delete_permission_not_found():
    """12. Kiểm thử lỗi xóa permission không tồn tại"""
    print_info("Đang thử xóa permission không tồn tại (dự kiến 404)")
    url = f"{BASE_URL}/api/v1/permissions/32000"
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

        if response.status_code == 404:
            print_success(
                f"Kiểm thử lỗi 'PERMISSION_NOT_FOUND' (DELETE) thành công. Nhận mã trạng thái: 404"
            )
        else:
            print_error(
                f"Kiểm thử lỗi 'PERMISSION_NOT_FOUND' (DELETE) THẤT BẠI. Dự kiến 404 nhưng nhận được {status_code}",
                response_data,
            )
    except Exception as e:
        print_error(f"Lỗi không xác định khi kiểm thử delete not found: {e}")
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
    new_id, new_name = test_create_permission()

    if new_id:
        print("-" * 30)
        test_get_permission_by_id(new_id)
        print("-" * 30)
        test_update_permission(new_id, new_name)
        print("-" * 30)
        # Delete the created permission at the end
        test_delete_permission(new_id)
    else:
        print_error(
            "Không thể tạo Permission. Bỏ qua các bài kiểm thử phụ thuộc 'Happy Path'."
        )

    print("=" * 30)

    # 3. Chạy các bài kiểm thử lỗi
    print_info("Bắt đầu chạy các bài kiểm thử lỗi (Error Cases)")
    test_create_permission_errors()
    print("-" * 30)
    test_duplicate_creation()
    print("-" * 30)
    test_update_permission_errors()
    print("-" * 30)
    test_get_permission_by_id_errors()
    print("-" * 30)
    test_update_permission_not_found()
    print("-" * 30)
    test_delete_permission_not_found()

    print("=" * 30)

    # 4. Kiểm thử API Lấy Danh sách
    test_get_all_permissions()
    print("=" * 30)

    print_info("Tất cả các bài kiểm thử đã hoàn tất.")

    # 5. TẠO BÁO CÁO
    generate_markdown_report()


if __name__ == "__main__":
    main()
