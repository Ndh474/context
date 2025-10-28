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


def generate_markdown_report(filename="api_test_report_rooms.md"):
    """Tạo tệp Markdown từ dữ liệu đã lưu trữ."""
    print_info(f"Đang tạo báo cáo Markdown: {filename}")
    try:
        with open(filename, "w", encoding="utf-8") as f:
            f.write(
                f"# Báo cáo Kiểm thử API - Rooms ({time.strftime('%Y-%m-%d %H:%M:%S')})\n\n"
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


def test_create_room(suffix=""):
    """2. Kiểm thử POST /api/v1/rooms (Tạo Phòng học)"""
    print_info(f"Đang thử tạo Phòng học mới{' ' + suffix if suffix else ''}...")
    url = f"{BASE_URL}/api/v1/rooms"
    headers = get_auth_headers()
    if not headers:
        return None, None

    ts = int(time.time() * 1000)  # Use milliseconds for higher uniqueness
    unique_name = f"Test Room {ts}"
    if suffix:
        unique_name = f"Test Room {suffix} {ts}"

    payload = {
        "name": unique_name,
        "location": f"Building T{ts % 100}, Floor {ts % 10}",
    }

    response_data = None
    status_code = 0

    try:
        response = requests.post(url, headers=headers, json=payload)
        status_code = response.status_code
        response_data = response.json()

        if response.status_code == 201:
            room_id = response_data.get("data", {}).get("id")
            print_success(
                f"Tạo Phòng học '{unique_name}' thành công. ID mới: {room_id}"
            )
            log_api_call("POST", url, payload, status_code, response_data)
            return room_id, unique_name
        else:
            print_error(
                f"Tạo Phòng học thất bại. Mã trạng thái: {response.status_code}",
                response_data,
            )
            log_api_call("POST", url, payload, status_code, response_data)
            return None, None
    except Exception as e:
        print_error(f"Lỗi không xác định khi tạo phòng học: {e}")
        log_api_call("POST", url, payload, 500, {"error": str(e)})
        return None, None


def test_get_room_by_id(room_id):
    """3. Kiểm thử GET /api/v1/rooms/{id} (Lấy Phòng học theo ID)"""
    print_info(f"Đang thử lấy Phòng học theo ID: {room_id}")
    url = f"{BASE_URL}/api/v1/rooms/{room_id}"
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
            print_success(f"Lấy Phòng học {room_id} thành công.")
        else:
            print_error(
                f"Lấy Phòng học {room_id} thất bại. Mã trạng thái: {response.status_code}",
                response_data,
            )
    except Exception as e:
        print_error(f"Lỗi không xác định khi lấy phòng học {room_id}: {e}")
        status_code = 500
        response_data = {"error": str(e)}
    finally:
        log_api_call("GET", url, None, status_code, response_data)


def test_update_room(room_id, name):
    """4. Kiểm thử PUT /api/v1/rooms/{id} (Cập nhật Phòng học)"""
    print_info(f"Đang thử cập nhật Phòng học ID: {room_id}")
    url = f"{BASE_URL}/api/v1/rooms/{room_id}"
    headers = get_auth_headers()
    if not headers:
        return

    new_name = f"Updated {name}"[:150]
    new_location = f"Updated Location for {name}"[:255]

    payload = {
        "name": new_name,
        "location": new_location,
        "isActive": True,
    }

    response_data = None
    status_code = 0
    try:
        response = requests.put(url, headers=headers, json=payload)
        status_code = response.status_code
        response_data = response.json()

        if response.status_code == 200:
            print_success(f"Cập nhật Phòng học {room_id} thành công.")
        else:
            print_error(
                f"Cập nhật Phòng học {room_id} thất bại. Mã trạng thái: {response.status_code}",
                response_data,
            )
    except Exception as e:
        print_error(f"Lỗi không xác định khi cập nhật phòng học {room_id}: {e}")
        status_code = 500
        response_data = {"error": str(e)}
    finally:
        log_api_call("PUT", url, payload, status_code, response_data)


def test_get_room_cameras(room_id):
    """5. Kiểm thử GET /api/v1/rooms/{id}/cameras (Lấy Camera của Phòng)"""
    print_info(f"Đang thử lấy các camera của Phòng học ID: {room_id}")
    url = f"{BASE_URL}/api/v1/rooms/{room_id}/cameras"
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
                f"Lấy camera của Phòng học {room_id} thành công. Tìm thấy: {count} camera."
            )
        else:
            print_error(
                f"Lấy camera của Phòng học {room_id} thất bại. Mã trạng thái: {response.status_code}",
                response_data,
            )
    except Exception as e:
        print_error(f"Lỗi không xác định khi lấy camera của phòng học {room_id}: {e}")
        status_code = 500
        response_data = {"error": str(e)}
    finally:
        log_api_call("GET", url, None, status_code, response_data)


def test_get_room_slots(room_id):
    """6. Kiểm thử GET /api/v1/rooms/{id}/slots (Lấy Slot của Phòng)"""
    print_info(f"Đang thử lấy các slot của Phòng học ID: {room_id}")
    url = f"{BASE_URL}/api/v1/rooms/{room_id}/slots"
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
                f"Lấy slot của Phòng học {room_id} thành công. Tìm thấy: {count} slot."
            )
        else:
            print_error(
                f"Lấy slot của Phòng học {room_id} thất bại. Mã trạng thái: {response.status_code}",
                response_data,
            )
    except Exception as e:
        print_error(f"Lỗi không xác định khi lấy slot của phòng học {room_id}: {e}")
        status_code = 500
        response_data = {"error": str(e)}
    finally:
        log_api_call("GET", url, None, status_code, response_data)


def test_get_all_rooms():
    """7. Kiểm thử GET /api/v1/rooms (Lấy danh sách Phòng học)"""
    print_info("Đang thử lấy danh sách Phòng học (sort desc, pageSize 10)")
    url = f"{BASE_URL}/api/v1/rooms?sort=desc&pageSize=10"
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
                f"Lấy danh sách Phòng học thành công. Tìm thấy: {count} phòng."
            )
        else:
            print_error(
                f"Lấy danh sách Phòng học thất bại. Mã trạng thái: {response.status_code}",
                response_data,
            )
    except Exception as e:
        print_error(f"Lỗi không xác định khi lấy danh sách phòng học: {e}")
        status_code = 500
        response_data = {"error": str(e)}
    finally:
        log_api_call("GET", url, None, status_code, response_data)


# --- Bắt đầu các hàm kiểm thử lỗi ---


def test_create_room_errors():
    """8. Kiểm thử các trường hợp lỗi của POST /api/v1/rooms (không bao gồm trùng lặp)"""
    print_info("Bắt đầu kiểm thử các trường hợp TẠO LỖI (dự kiến 400)")
    url = f"{BASE_URL}/api/v1/rooms"
    headers = get_auth_headers()
    if not headers:
        return

    test_cases = [
        ("Tên rỗng (NAME_REQUIRED)", {"name": "", "location": "Test Location"}),
        (
            "Tên sai định dạng (INVALID_FIELD_FORMAT - dấu cách thừa)",
            {"name": "  Bad Name  ", "location": "Test Location"},
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
    """9. Tự kiểm thử lỗi tạo trùng lặp (ROOM_NAME_EXISTS)"""
    print_info("Bắt đầu kiểm thử lỗi TẠO TRÙNG LẶP (ROOM_NAME_EXISTS)")

    # Bước 1: Tạo một phòng học duy nhất để làm cơ sở
    room_id, room_name = test_create_room("For-Dup-Test")
    if not room_id:
        print_error("Không thể tạo phòng ban đầu. Bỏ qua test trùng lặp.")
        return

    # Bước 2: Cố gắng tạo lại phòng với cùng tên
    print_info(f"Tạo lại phòng '{room_name}' (dự kiến lỗi 400)...")
    url = f"{BASE_URL}/api/v1/rooms"
    headers = get_auth_headers()
    payload = {"name": room_name, "location": "Duplicate Location"}

    try:
        response = requests.post(url, headers=headers, json=payload)
        # SỬA LỖI: Mong đợi 400 theo docs
        if response.status_code == 400:
            print_success(
                f"Kiểm thử lỗi 'ROOM_NAME_EXISTS' thành công. Nhận mã trạng thái: 400"
            )
        else:
            print_error(
                f"Kiểm thử lỗi 'ROOM_NAME_EXISTS' THẤT BẠI. Dự kiến 400 nhưng nhận được {response.status_code}",
                response.json(),
            )
        log_api_call("POST", url, payload, response.status_code, response.json())
    except Exception as e:
        print_error(f"Lỗi không xác định khi kiểm thử trùng lặp: {e}")
        log_api_call("POST", url, payload, 500, {"error": str(e)})


def test_update_room_errors():
    """10. Tự kiểm thử lỗi cập nhật trùng tên (ROOM_NAME_EXISTS)"""
    print_info("Bắt đầu kiểm thử lỗi CẬP NHẬT TRÙNG TÊN (ROOM_NAME_EXISTS)")

    # Bước 1: Tạo hai phòng học riêng biệt
    room1_id, room1_name = test_create_room("A-For-Update-Test")
    room2_id, room2_name = test_create_room("B-For-Update-Test")

    if not (room1_id and room2_id):
        print_error("Không thể tạo đủ phòng để test lỗi cập nhật. Bỏ qua.")
        return

    # Bước 2: Cố gắng cập nhật phòng 2 để có tên giống phòng 1
    print_info(
        f"Cập nhật phòng '{room2_name}' thành '{room1_name}' (dự kiến lỗi 400)..."
    )
    url = f"{BASE_URL}/api/v1/rooms/{room2_id}"
    headers = get_auth_headers()
    payload = {"name": room1_name, "location": "Updated Location", "isActive": True}

    try:
        response = requests.put(url, headers=headers, json=payload)
        # SỬA LỖI: Mong đợi 400 theo docs
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


def test_get_room_by_id_errors():
    """11. Kiểm thử các trường hợp lỗi của GET /api/v1/rooms/{id}"""
    print_info("Bắt đầu kiểm thử các trường hợp LẤY LỖI (dự kiến 400/404)")
    headers = get_auth_headers()
    if not headers:
        return

    test_cases = [
        ("ID không tồn tại (ROOM_NOT_FOUND)", f"{BASE_URL}/api/v1/rooms/32000", 404),
        ("ID sai định dạng (INVALID_FIELD_TYPE)", f"{BASE_URL}/api/v1/rooms/abc", 400),
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
    new_id, new_name = test_create_room()

    if new_id:
        print("-" * 30)
        test_get_room_by_id(new_id)
        print("-" * 30)
        test_update_room(new_id, new_name)
        print("-" * 30)
        test_get_room_cameras(new_id)
        print("-" * 30)
        test_get_room_slots(new_id)
    else:
        print_error(
            "Không thể tạo Phòng học. Bỏ qua các bài kiểm thử phụ thuộc 'Happy Path'."
        )

    print("=" * 30)

    # 3. Chạy các bài kiểm thử lỗi
    print_info("Bắt đầu chạy các bài kiểm thử lỗi (Error Cases)")
    test_create_room_errors()
    print("-" * 30)
    test_duplicate_creation()
    print("-" * 30)
    test_update_room_errors()
    print("-" * 30)
    test_get_room_by_id_errors()

    print("=" * 30)

    # 4. Kiểm thử API Lấy Danh sách
    test_get_all_rooms()
    print("=" * 30)

    print_info("Tất cả các bài kiểm thử đã hoàn tất.")

    # 5. TẠO BÁO CÁO
    generate_markdown_report()


if __name__ == "__main__":
    main()
