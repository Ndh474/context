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


def generate_markdown_report(filename="api_test_report_cameras.md"):
    """Tạo tệp Markdown từ dữ liệu đã lưu trữ."""
    print_info(f"Đang tạo báo cáo Markdown: {filename}")
    try:
        with open(filename, "w", encoding="utf-8") as f:
            f.write(
                f"# Báo cáo Kiểm thử API - Cameras ({time.strftime('%Y-%m-%d %H:%M:%S')})\n\n"
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


def test_create_camera(suffix="", room_id=1):
    """2. Kiểm thử POST /api/v1/cameras (Tạo Camera)"""
    print_info(f"Đang thử tạo Camera mới{' ' + suffix if suffix else ''}...")
    url = f"{BASE_URL}/api/v1/cameras"
    headers = get_auth_headers()
    if not headers:
        return None, None, None

    ts = int(time.time() * 1000)
    unique_name = f"Test Camera {ts}"
    unique_rtsp = f"rtsp://192.168.1.{ts % 255}:554/stream{ts}"
    if suffix:
        unique_name = f"Test Camera {suffix} {ts}"

    payload = {
        "name": unique_name,
        "rtspUrl": unique_rtsp,
        "roomId": room_id,
    }

    response_data = None
    status_code = 0

    try:
        response = requests.post(url, headers=headers, json=payload)
        status_code = response.status_code
        response_data = response.json()

        if response.status_code == 201:
            camera_id = response_data.get("data", {}).get("id")
            print_success(f"Tạo Camera '{unique_name}' thành công. ID mới: {camera_id}")
            log_api_call("POST", url, payload, status_code, response_data)
            return camera_id, unique_name, unique_rtsp
        else:
            print_error(
                f"Tạo Camera thất bại. Mã trạng thái: {response.status_code}",
                response_data,
            )
            log_api_call("POST", url, payload, status_code, response_data)
            return None, None, None
    except Exception as e:
        print_error(f"Lỗi không xác định khi tạo camera: {e}")
        log_api_call("POST", url, payload, 500, {"error": str(e)})
        return None, None, None


def test_get_camera_by_id(camera_id):
    """3. Kiểm thử GET /api/v1/cameras/{id} (Lấy Camera theo ID)"""
    print_info(f"Đang thử lấy Camera theo ID: {camera_id}")
    url = f"{BASE_URL}/api/v1/cameras/{camera_id}"
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
            print_success(f"Lấy Camera {camera_id} thành công.")
        else:
            print_error(
                f"Lấy Camera {camera_id} thất bại. Mã trạng thái: {response.status_code}",
                response_data,
            )
    except Exception as e:
        print_error(f"Lỗi không xác định khi lấy camera {camera_id}: {e}")
        status_code = 500
        response_data = {"error": str(e)}
    finally:
        log_api_call("GET", url, None, status_code, response_data)


def test_update_camera(camera_id, name, rtsp_url, room_id=1):
    """4. Kiểm thử PUT /api/v1/cameras/{id} (Cập nhật Camera)"""
    print_info(f"Đang thử cập nhật Camera ID: {camera_id}")
    url = f"{BASE_URL}/api/v1/cameras/{camera_id}"
    headers = get_auth_headers()
    if not headers:
        return

    new_name = f"Updated {name}"[:150]
    new_rtsp_url = f"{rtsp_url}-updated"[:512]

    payload = {
        "name": new_name,
        "rtspUrl": new_rtsp_url,
        "roomId": room_id,
        "isActive": True,
    }

    response_data = None
    status_code = 0
    try:
        response = requests.put(url, headers=headers, json=payload)
        status_code = response.status_code
        response_data = response.json()

        if response.status_code == 200:
            print_success(f"Cập nhật Camera {camera_id} thành công.")
        else:
            print_error(
                f"Cập nhật Camera {camera_id} thất bại. Mã trạng thái: {response.status_code}",
                response_data,
            )
    except Exception as e:
        print_error(f"Lỗi không xác định khi cập nhật camera {camera_id}: {e}")
        status_code = 500
        response_data = {"error": str(e)}
    finally:
        log_api_call("PUT", url, payload, status_code, response_data)


def test_get_all_cameras():
    """5. Kiểm thử GET /api/v1/cameras (Lấy danh sách Camera)"""
    print_info("Đang thử lấy danh sách Camera (sort desc, pageSize 10)")
    url = f"{BASE_URL}/api/v1/cameras?sort=desc&pageSize=10"
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
            print_success(f"Lấy danh sách Camera thành công. Tìm thấy: {count} camera.")
        else:
            print_error(
                f"Lấy danh sách Camera thất bại. Mã trạng thái: {response.status_code}",
                response_data,
            )
    except Exception as e:
        print_error(f"Lỗi không xác định khi lấy danh sách camera: {e}")
        status_code = 500
        response_data = {"error": str(e)}
    finally:
        log_api_call("GET", url, None, status_code, response_data)


# --- Bắt đầu các hàm kiểm thử lỗi ---


def test_create_camera_errors():
    """6. Kiểm thử các trường hợp lỗi của POST /api/v1/cameras (không bao gồm trùng lặp)"""
    print_info("Bắt đầu kiểm thử các trường hợp TẠO LỖI (dự kiến 400)")
    url = f"{BASE_URL}/api/v1/cameras"
    headers = get_auth_headers()
    if not headers:
        return

    test_cases = [
        (
            "Tên rỗng (CAMERA_NAME_REQUIRED)",
            {"name": "", "rtspUrl": "rtsp://test.com/stream", "roomId": 1},
        ),
        (
            "Tên sai định dạng (INVALID_FIELD_FORMAT - dấu cách thừa)",
            {"name": "  Bad Name  ", "rtspUrl": "rtsp://test.com/stream", "roomId": 1},
        ),
        (
            "RTSP URL rỗng (CAMERA_RTSP_URL_REQUIRED)",
            {"name": "Test Camera", "rtspUrl": "", "roomId": 1},
        ),
        (
            "Room ID không tồn tại (ROOM_NOT_FOUND)",
            {
                "name": "Test Camera",
                "rtspUrl": "rtsp://test.com/stream",
                "roomId": 32000,
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


def test_duplicate_name_creation():
    """7. Tự kiểm thử lỗi tạo trùng tên (CAMERA_NAME_EXISTS)"""
    print_info("Bắt đầu kiểm thử lỗi TẠO TRÙNG TÊN (CAMERA_NAME_EXISTS)")

    # Bước 1: Tạo một camera duy nhất để làm cơ sở
    camera_id, camera_name, rtsp_url = test_create_camera("For-Name-Dup-Test")
    if not camera_id:
        print_error("Không thể tạo camera ban đầu. Bỏ qua test trùng lặp tên.")
        return

    # Bước 2: Cố gắng tạo lại camera với cùng tên (nhưng RTSP URL khác)
    print_info(f"Tạo lại camera '{camera_name}' (dự kiến lỗi 400)...")
    url = f"{BASE_URL}/api/v1/cameras"
    headers = get_auth_headers()
    payload = {
        "name": camera_name,
        "rtspUrl": "rtsp://different.url/stream",
        "roomId": 1,
    }

    try:
        response = requests.post(url, headers=headers, json=payload)
        if response.status_code == 400:
            print_success(
                f"Kiểm thử lỗi 'CAMERA_NAME_EXISTS' thành công. Nhận mã trạng thái: 400"
            )
        else:
            print_error(
                f"Kiểm thử lỗi 'CAMERA_NAME_EXISTS' THẤT BẠI. Dự kiến 400 nhưng nhận được {response.status_code}",
                response.json(),
            )
        log_api_call("POST", url, payload, response.status_code, response.json())
    except Exception as e:
        print_error(f"Lỗi không xác định khi kiểm thử trùng tên: {e}")
        log_api_call("POST", url, payload, 500, {"error": str(e)})


def test_duplicate_rtsp_creation():
    """8. Tự kiểm thử lỗi tạo trùng RTSP URL (RTSP_URL_EXISTS)"""
    print_info("Bắt đầu kiểm thử lỗi TẠO TRÙNG RTSP URL (RTSP_URL_EXISTS)")

    # Bước 1: Tạo một camera duy nhất để làm cơ sở
    camera_id, camera_name, rtsp_url = test_create_camera("For-RTSP-Dup-Test")
    if not camera_id:
        print_error("Không thể tạo camera ban đầu. Bỏ qua test trùng lặp RTSP.")
        return

    # Bước 2: Cố gắng tạo lại camera với cùng RTSP URL (nhưng tên khác)
    print_info(f"Tạo lại camera với RTSP URL '{rtsp_url}' (dự kiến lỗi 400)...")
    url = f"{BASE_URL}/api/v1/cameras"
    headers = get_auth_headers()
    payload = {"name": "Different Camera Name", "rtspUrl": rtsp_url, "roomId": 1}

    try:
        response = requests.post(url, headers=headers, json=payload)
        if response.status_code == 400:
            print_success(
                f"Kiểm thử lỗi 'RTSP_URL_EXISTS' thành công. Nhận mã trạng thái: 400"
            )
        else:
            print_error(
                f"Kiểm thử lỗi 'RTSP_URL_EXISTS' THẤT BẠI. Dự kiến 400 nhưng nhận được {response.status_code}",
                response.json(),
            )
        log_api_call("POST", url, payload, response.status_code, response.json())
    except Exception as e:
        print_error(f"Lỗi không xác định khi kiểm thử trùng RTSP: {e}")
        log_api_call("POST", url, payload, 500, {"error": str(e)})


def test_update_camera_errors():
    """9. Tự kiểm thử lỗi cập nhật trùng tên (CAMERA_NAME_EXISTS)"""
    print_info("Bắt đầu kiểm thử lỗi CẬP NHẬT TRÙNG TÊN (CAMERA_NAME_EXISTS)")

    # Bước 1: Tạo hai camera riêng biệt
    camera1_id, camera1_name, camera1_rtsp = test_create_camera("A-For-Update-Test")
    camera2_id, camera2_name, camera2_rtsp = test_create_camera("B-For-Update-Test")

    if not (camera1_id and camera2_id):
        print_error("Không thể tạo đủ camera để test lỗi cập nhật. Bỏ qua.")
        return

    # Bước 2: Cố gắng cập nhật camera 2 để có tên giống camera 1
    print_info(
        f"Cập nhật camera '{camera2_name}' thành '{camera1_name}' (dự kiến lỗi 400)..."
    )
    url = f"{BASE_URL}/api/v1/cameras/{camera2_id}"
    headers = get_auth_headers()
    payload = {
        "name": camera1_name,
        "rtspUrl": camera2_rtsp,
        "roomId": 1,
        "isActive": True,
    }

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


def test_get_camera_by_id_errors():
    """10. Kiểm thử các trường hợp lỗi của GET /api/v1/cameras/{id}"""
    print_info("Bắt đầu kiểm thử các trường hợp LẤY LỖI (dự kiến 400/404)")
    headers = get_auth_headers()
    if not headers:
        return

    test_cases = [
        (
            "ID không tồn tại (CAMERA_NOT_FOUND)",
            f"{BASE_URL}/api/v1/cameras/32000",
            404,
        ),
        (
            "ID sai định dạng (INVALID_FIELD_TYPE)",
            f"{BASE_URL}/api/v1/cameras/abc",
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
    new_id, new_name, new_rtsp = test_create_camera()

    if new_id:
        print("-" * 30)
        test_get_camera_by_id(new_id)
        print("-" * 30)
        test_update_camera(new_id, new_name, new_rtsp)
    else:
        print_error(
            "Không thể tạo Camera. Bỏ qua các bài kiểm thử phụ thuộc 'Happy Path'."
        )

    print("=" * 30)

    # 3. Chạy các bài kiểm thử lỗi
    print_info("Bắt đầu chạy các bài kiểm thử lỗi (Error Cases)")
    test_create_camera_errors()
    print("-" * 30)
    test_duplicate_name_creation()
    print("-" * 30)
    test_duplicate_rtsp_creation()
    print("-" * 30)
    test_update_camera_errors()
    print("-" * 30)
    test_get_camera_by_id_errors()

    print("=" * 30)

    # 4. Kiểm thử API Lấy Danh sách
    test_get_all_cameras()
    print("=" * 30)

    print_info("Tất cả các bài kiểm thử đã hoàn tất.")

    # 5. TẠO BÁO CÁO
    generate_markdown_report()


if __name__ == "__main__":
    main()
