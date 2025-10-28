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

# Prerequisites (will be fetched)
semester_id = None
class_id = None
room_id = None
staff_user_id = None


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


def generate_markdown_report(filename="api_test_report_slots.md"):
    """Tạo tệp Markdown từ dữ liệu đã lưu trữ."""
    print_info(f"Đang tạo báo cáo Markdown: {filename}")
    try:
        with open(filename, "w", encoding="utf-8") as f:
            f.write(
                f"# Báo cáo Kiểm thử API - Slots ({time.strftime('%Y-%m-%d %H:%M:%S')})\n\n"
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


def generate_future_times(days_ahead=7, duration_hours=2):
    """Tạo startTime và endTime trong tương lai để tránh lỗi 'slot in past'."""
    start = datetime.utcnow() + timedelta(days=days_ahead)
    end = start + timedelta(hours=duration_hours)
    return (
        start.strftime("%Y-%m-%dT%H:%M:%S"),
        end.strftime("%Y-%m-%dT%H:%M:%S"),
    )


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


def fetch_prerequisites():
    """2. Lấy các prerequisite cần thiết (semester, class, room, staff)."""
    global semester_id, class_id, room_id, staff_user_id

    print_info("Đang lấy các dữ liệu tiên quyết (prerequisites)...")
    headers = get_auth_headers()
    if not headers:
        return False

    # Fetch Class first (to ensure we have a class with a valid semester)
    try:
        url = f"{BASE_URL}/api/v1/classes?pageSize=1&isActive=true"
        response = requests.get(url, headers=headers)
        if response.status_code == 200:
            items = response.json().get("data", {}).get("items", [])
            if items:
                class_id = items[0]["id"]
                # Extract semester ID from class data
                class_semester = items[0].get("semester", {})
                semester_id = class_semester.get("id")
                if semester_id:
                    print_success(f"Đã lấy Class ID: {class_id}")
                    print_success(f"Đã lấy Semester ID: {semester_id} (từ class)")
                else:
                    print_error("Không thể lấy semester ID từ class response.")
                    return False
            else:
                print_error("Không tìm thấy class nào trong database.")
                return False
        else:
            print_error(f"Không thể lấy class. Status: {response.status_code}")
            return False
    except Exception as e:
        print_error(f"Lỗi khi lấy class: {e}")
        return False

    # Fetch Room
    try:
        url = f"{BASE_URL}/api/v1/rooms?pageSize=1&isActive=true"
        response = requests.get(url, headers=headers)
        if response.status_code == 200:
            items = response.json().get("data", {}).get("items", [])
            if items:
                room_id = items[0]["id"]
                print_success(f"Đã lấy Room ID: {room_id}")
            else:
                print_error("Không tìm thấy room nào trong database.")
                return False
        else:
            print_error(f"Không thể lấy room. Status: {response.status_code}")
            return False
    except Exception as e:
        print_error(f"Lỗi khi lấy room: {e}")
        return False

    # Fetch Staff User (need to find a user with LECTURER or SUPERVISOR role)
    try:
        url = f"{BASE_URL}/api/v1/staff-profiles?pageSize=1&excludeRoles=DATA_OPERATOR,SYSTEM_ADMIN"
        response = requests.get(url, headers=headers)
        if response.status_code == 200:
            items = response.json().get("data", {}).get("items", [])
            if items:
                # Get first staff user (filtered to exclude DATA_OPERATOR and SYSTEM_ADMIN)
                staff_user_id = items[0]["userId"]
                print_success(f"Đã lấy Staff User ID: {staff_user_id}")
            else:
                print_error("Không tìm thấy user nào trong database.")
                return False
        else:
            print_error(f"Không thể lấy user. Status: {response.status_code}")
            return False
    except Exception as e:
        print_error(f"Lỗi khi lấy staff user: {e}")
        return False

    return True


def test_get_all_slots():
    """3. Kiểm thử GET /api/v1/slots (Lấy danh sách Slots)"""
    print_info("Đang thử lấy danh sách Slots (sort asc, pageSize 10)")
    url = f"{BASE_URL}/api/v1/slots?sort=asc&pageSize=10"
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
            print_success(f"Lấy danh sách Slots thành công. Tìm thấy: {count} slot.")
        else:
            print_error(
                f"Lấy danh sách Slots thất bại. Mã trạng thái: {response.status_code}",
                response_data,
            )
    except Exception as e:
        print_error(f"Lỗi không xác định khi lấy danh sách slots: {e}")
        status_code = 500
        response_data = {"error": str(e)}
    finally:
        log_api_call("GET", url, None, status_code, response_data)


def test_create_lecture_slot():
    """4. Kiểm thử POST /api/v1/slots (Tạo LECTURE Slot)"""
    print_info("Đang thử tạo LECTURE Slot mới...")
    url = f"{BASE_URL}/api/v1/slots"
    headers = get_auth_headers()
    if not headers:
        return None

    start_time, end_time = generate_future_times(days_ahead=7, duration_hours=2)

    payload = {
        "title": f"Test Lecture Slot {int(time.time())}",
        "description": "Test description for lecture slot",
        "startTime": start_time,
        "endTime": end_time,
        "slotCategory": "LECTURE",
        "classId": class_id,
        "semesterId": semester_id,
        "roomId": room_id,
        "staffUserId": staff_user_id,
    }

    response_data = None
    status_code = 0

    try:
        response = requests.post(url, headers=headers, json=payload)
        status_code = response.status_code
        response_data = response.json()

        if response.status_code == 201:
            slot_id = response_data.get("data", {}).get("id")
            print_success(f"Tạo LECTURE Slot thành công. ID mới: {slot_id}")
            log_api_call("POST", url, payload, status_code, response_data)
            return slot_id
        else:
            print_error(
                f"Tạo LECTURE Slot thất bại. Mã trạng thái: {response.status_code}",
                response_data,
            )
            log_api_call("POST", url, payload, status_code, response_data)
            return None
    except Exception as e:
        print_error(f"Lỗi không xác định khi tạo slot: {e}")
        log_api_call("POST", url, payload, 500, {"error": str(e)})
        return None


def test_get_slot_by_id(slot_id):
    """5. Kiểm thử GET /api/v1/slots/{id} (Lấy Slot theo ID)"""
    print_info(f"Đang thử lấy Slot theo ID: {slot_id}")
    url = f"{BASE_URL}/api/v1/slots/{slot_id}"
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
            print_success(f"Lấy Slot {slot_id} thành công.")
        else:
            print_error(
                f"Lấy Slot {slot_id} thất bại. Mã trạng thái: {response.status_code}",
                response_data,
            )
    except Exception as e:
        print_error(f"Lỗi không xác định khi lấy slot {slot_id}: {e}")
        status_code = 500
        response_data = {"error": str(e)}
    finally:
        log_api_call("GET", url, None, status_code, response_data)


def test_update_slot(slot_id):
    """6. Kiểm thử PUT /api/v1/slots/{id} (Cập nhật Slot)"""
    print_info(f"Đang thử cập nhật Slot ID: {slot_id}")
    url = f"{BASE_URL}/api/v1/slots/{slot_id}"
    headers = get_auth_headers()
    if not headers:
        return

    start_time, end_time = generate_future_times(days_ahead=7, duration_hours=2)

    payload = {
        "title": f"Updated Test Slot {int(time.time())}",
        "description": "Updated description",
        "startTime": start_time,
        "endTime": end_time,
        "slotCategory": "LECTURE",
        "classId": class_id,
        "semesterId": semester_id,
        "roomId": room_id,
        "staffUserId": staff_user_id,
        "isActive": True,
    }

    response_data = None
    status_code = 0
    try:
        response = requests.put(url, headers=headers, json=payload)
        status_code = response.status_code
        response_data = response.json()

        if response.status_code == 200:
            print_success(f"Cập nhật Slot {slot_id} thành công.")
        else:
            print_error(
                f"Cập nhật Slot {slot_id} thất bại. Mã trạng thái: {response.status_code}",
                response_data,
            )
    except Exception as e:
        print_error(f"Lỗi không xác định khi cập nhật slot {slot_id}: {e}")
        status_code = 500
        response_data = {"error": str(e)}
    finally:
        log_api_call("PUT", url, payload, status_code, response_data)


def test_get_slot_roster(slot_id):
    """7. Kiểm thử GET /api/v1/slots/{id}/roster (Lấy Roster của Slot)"""
    print_info(f"Đang thử lấy roster của Slot ID: {slot_id}")
    url = f"{BASE_URL}/api/v1/slots/{slot_id}/roster"
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
                f"Lấy roster của Slot {slot_id} thành công. Tìm thấy: {count} student."
            )
        else:
            print_error(
                f"Lấy roster của Slot {slot_id} thất bại. Mã trạng thái: {response.status_code}",
                response_data,
            )
    except Exception as e:
        print_error(f"Lỗi không xác định khi lấy roster của slot {slot_id}: {e}")
        status_code = 500
        response_data = {"error": str(e)}
    finally:
        log_api_call("GET", url, None, status_code, response_data)


def test_create_lecture_with_pt_slot():
    """8. Kiểm thử POST /api/v1/slots (Tạo LECTURE_WITH_PT Slot)"""
    print_info("Đang thử tạo LECTURE_WITH_PT Slot mới...")
    url = f"{BASE_URL}/api/v1/slots"
    headers = get_auth_headers()
    if not headers:
        return None

    start_time, end_time = generate_future_times(days_ahead=14, duration_hours=2)

    payload = {
        "title": f"Test Progress Test Slot {int(time.time())}",
        "description": "Test description for lecture with progress test",
        "startTime": start_time,
        "endTime": end_time,
        "slotCategory": "LECTURE_WITH_PT",
        "classId": class_id,
        "semesterId": semester_id,
        "roomId": room_id,
        "staffUserId": staff_user_id,
    }

    response_data = None
    status_code = 0

    try:
        response = requests.post(url, headers=headers, json=payload)
        status_code = response.status_code
        response_data = response.json()

        if response.status_code == 201:
            slot_id = response_data.get("data", {}).get("id")
            print_success(f"Tạo LECTURE_WITH_PT Slot thành công. ID mới: {slot_id}")
            log_api_call("POST", url, payload, status_code, response_data)
            return slot_id
        else:
            print_error(
                f"Tạo LECTURE_WITH_PT Slot thất bại. Mã trạng thái: {response.status_code}",
                response_data,
            )
            log_api_call("POST", url, payload, status_code, response_data)
            return None
    except Exception as e:
        print_error(f"Lỗi không xác định khi tạo LECTURE_WITH_PT slot: {e}")
        log_api_call("POST", url, payload, 500, {"error": str(e)})
        return None


def test_create_final_exam_slot():
    """9. Kiểm thử POST /api/v1/slots (Tạo FINAL_EXAM Slot với classId=null)"""
    print_info("Đang thử tạo FINAL_EXAM Slot mới (classId=null)...")
    url = f"{BASE_URL}/api/v1/slots"
    headers = get_auth_headers()
    if not headers:
        return None

    start_time, end_time = generate_future_times(days_ahead=21, duration_hours=3)

    payload = {
        "title": f"Test Final Exam Slot {int(time.time())}",
        "description": "Test description for final exam",
        "startTime": start_time,
        "endTime": end_time,
        "slotCategory": "FINAL_EXAM",
        "classId": None,  # BR-34: FINAL_EXAM must have classId = null
        "semesterId": semester_id,
        "roomId": room_id,
        "staffUserId": staff_user_id,
    }

    response_data = None
    status_code = 0

    try:
        response = requests.post(url, headers=headers, json=payload)
        status_code = response.status_code
        response_data = response.json()

        if response.status_code == 201:
            slot_id = response_data.get("data", {}).get("id")
            print_success(f"Tạo FINAL_EXAM Slot thành công. ID mới: {slot_id}")
            log_api_call("POST", url, payload, status_code, response_data)
            return slot_id
        else:
            print_error(
                f"Tạo FINAL_EXAM Slot thất bại. Mã trạng thái: {response.status_code}",
                response_data,
            )
            log_api_call("POST", url, payload, status_code, response_data)
            return None
    except Exception as e:
        print_error(f"Lỗi không xác định khi tạo FINAL_EXAM slot: {e}")
        log_api_call("POST", url, payload, 500, {"error": str(e)})
        return None


# --- Bắt đầu các hàm kiểm thử lỗi ---


def test_create_slot_validation_errors():
    """10. Kiểm thử các trường hợp lỗi validation của POST /api/v1/slots"""
    print_info("Bắt đầu kiểm thử các trường hợp TẠO LỖI VALIDATION (dự kiến 400/404)")
    url = f"{BASE_URL}/api/v1/slots"
    headers = get_auth_headers()
    if not headers:
        return

    start_time, end_time = generate_future_times(days_ahead=7, duration_hours=2)
    # Generate invalid times for specific tests
    start_time_short, end_time_short = generate_future_times(
        days_ahead=7, duration_hours=0.4
    )  # 24 mins
    start_time_long, end_time_long = generate_future_times(
        days_ahead=7, duration_hours=5
    )  # 5 hours

    test_cases = [
        (
            "Missing startTime (SLOT_START_TIME_REQUIRED)",
            {
                "endTime": end_time,
                "slotCategory": "LECTURE",
                "classId": class_id,
                "semesterId": semester_id,
                "roomId": room_id,
                "staffUserId": staff_user_id,
            },
        ),
        (
            "Missing endTime (SLOT_END_TIME_REQUIRED)",
            {
                "startTime": start_time,
                "slotCategory": "LECTURE",
                "classId": class_id,
                "semesterId": semester_id,
                "roomId": room_id,
                "staffUserId": staff_user_id,
            },
        ),
        (
            "Missing slotCategory (SLOT_CATEGORY_REQUIRED)",
            {
                "startTime": start_time,
                "endTime": end_time,
                "classId": class_id,
                "semesterId": semester_id,
                "roomId": room_id,
                "staffUserId": staff_user_id,
            },
        ),
        (
            "Missing roomId (SLOT_ROOM_ID_REQUIRED)",
            {
                "startTime": start_time,
                "endTime": end_time,
                "slotCategory": "LECTURE",
                "classId": class_id,
                "semesterId": semester_id,
                "staffUserId": staff_user_id,
            },
        ),
        (
            "Missing staffUserId (SLOT_STAFF_USER_ID_REQUIRED)",
            {
                "startTime": start_time,
                "endTime": end_time,
                "slotCategory": "LECTURE",
                "classId": class_id,
                "semesterId": semester_id,
                "roomId": room_id,
            },
        ),
        (
            "Invalid slotCategory (INVALID_SLOT_CATEGORY)",
            {
                "startTime": start_time,
                "endTime": end_time,
                "slotCategory": "INVALID_CATEGORY",
                "classId": class_id,
                "semesterId": semester_id,
                "roomId": room_id,
                "staffUserId": staff_user_id,
            },
        ),
        (
            "End time before start time (INVALID_TIME_RANGE)",
            {
                "startTime": end_time,  # Swapped
                "endTime": start_time,  # Swapped
                "slotCategory": "LECTURE",
                "classId": class_id,
                "semesterId": semester_id,
                "roomId": room_id,
                "staffUserId": staff_user_id,
            },
        ),
        (
            "Duration < 30 minutes (INVALID_SLOT_DURATION)",
            {
                "startTime": start_time_short,
                "endTime": end_time_short,
                "slotCategory": "LECTURE",
                "classId": class_id,
                "semesterId": semester_id,
                "roomId": room_id,
                "staffUserId": staff_user_id,
            },
        ),
        (
            "Duration > 4 hours (INVALID_SLOT_DURATION)",
            {
                "startTime": start_time_long,
                "endTime": end_time_long,
                "slotCategory": "LECTURE",
                "classId": class_id,
                "semesterId": semester_id,
                "roomId": room_id,
                "staffUserId": staff_user_id,
            },
        ),
        (
            "Non-existent classId (CLASS_NOT_FOUND - 404)",
            {
                "startTime": start_time,
                "endTime": end_time,
                "slotCategory": "LECTURE",
                "classId": 32000,
                "semesterId": semester_id,
                "roomId": room_id,
                "staffUserId": staff_user_id,
            },
        ),
        (
            "Non-existent roomId (ROOM_NOT_FOUND - 404)",
            {
                "startTime": start_time,
                "endTime": end_time,
                "slotCategory": "LECTURE",
                "classId": class_id,
                "semesterId": semester_id,
                "roomId": 32000,
                "staffUserId": staff_user_id,
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


def test_get_slot_by_id_errors():
    """11. Kiểm thử các trường hợp lỗi của GET /api/v1/slots/{id}"""
    print_info("Bắt đầu kiểm thử các trường hợp LẤY LỖI (dự kiến 400/404)")
    headers = get_auth_headers()
    if not headers:
        return

    test_cases = [
        ("ID không tồn tại (SLOT_NOT_FOUND)", f"{BASE_URL}/api/v1/slots/32000", 404),
        ("ID sai định dạng (INVALID_FIELD_TYPE)", f"{BASE_URL}/api/v1/slots/abc", 400),
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


def test_update_slot_errors():
    """12. Kiểm thử các trường hợp lỗi của PUT /api/v1/slots/{id}"""
    print_info("Bắt đầu kiểm thử các trường hợp CẬP NHẬT LỖI (dự kiến 400/404)")
    headers = get_auth_headers()
    if not headers:
        return

    start_time, end_time = generate_future_times(days_ahead=7, duration_hours=2)

    valid_payload = {
        "title": "Test Update",
        "startTime": start_time,
        "endTime": end_time,
        "slotCategory": "LECTURE",
        "classId": class_id,
        "roomId": room_id,
        "staffUserId": staff_user_id,
        "isActive": True,
    }

    test_cases = [
        (
            "ID không tồn tại (SLOT_NOT_FOUND)",
            f"{BASE_URL}/api/v1/slots/32000",
            valid_payload,
            404,
        ),
        (
            "ID sai định dạng (INVALID_FIELD_TYPE)",
            f"{BASE_URL}/api/v1/slots/abc",
            valid_payload,
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


def test_delete_slot(slot_id):
    """13. Kiểm thử DELETE /api/v1/slots/{id}"""
    if not slot_id:
        print_info("Không có slot ID để xóa. Bỏ qua test DELETE.")
        return

    print_info(f"Đang thử xóa Slot ID: {slot_id}")
    url = f"{BASE_URL}/api/v1/slots/{slot_id}"
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
            print_success(f"Xóa Slot {slot_id} thành công.")
        else:
            print_error(
                f"Xóa Slot {slot_id} thất bại. Mã trạng thái: {response.status_code}",
                response_data,
            )
    except Exception as e:
        print_error(f"Lỗi không xác định khi xóa slot {slot_id}: {e}")
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

    # 2. Lấy Prerequisites
    if not fetch_prerequisites():
        print_error("Không thể lấy prerequisites. Đang thoát.")
        generate_markdown_report()
        return

    print("=" * 30)

    # 3. Chạy chu trình "Happy Path"
    print_info("Bắt đầu chạy luồng kiểm thử 'Happy Path'")

    test_get_all_slots()
    print("-" * 30)

    lecture_slot_id = test_create_lecture_slot()
    if lecture_slot_id:
        print("-" * 30)
        test_get_slot_by_id(lecture_slot_id)
        print("-" * 30)
        test_update_slot(lecture_slot_id)
        print("-" * 30)
        test_get_slot_roster(lecture_slot_id)
    else:
        print_error("Không thể tạo LECTURE Slot. Bỏ qua các bài kiểm thử phụ thuộc.")

    print("-" * 30)
    test_create_lecture_with_pt_slot()

    print("-" * 30)
    test_create_final_exam_slot()

    print("=" * 30)

    # 4. Chạy các bài kiểm thử lỗi
    print_info("Bắt đầu chạy các bài kiểm thử lỗi (Error Cases)")
    test_create_slot_validation_errors()

    print("-" * 30)
    test_get_slot_by_id_errors()

    print("-" * 30)
    test_update_slot_errors()

    print("=" * 30)

    # 5. Xóa slot đã tạo (nếu có)
    if lecture_slot_id:
        test_delete_slot(lecture_slot_id)
        print("=" * 30)

    print_info("Tất cả các bài kiểm thử đã hoàn tất.")

    # 6. TẠO BÁO CÁO
    generate_markdown_report()


if __name__ == "__main__":
    main()
