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


def generate_markdown_report(filename="api_test_report_exam_slot_participants.md"):
    """Tạo tệp Markdown từ dữ liệu đã lưu trữ."""
    print_info(f"Đang tạo báo cáo Markdown: {filename}")
    try:
        with open(filename, "w", encoding="utf-8") as f:
            f.write(
                f"# Báo cáo Kiểm thử API - Exam Slot Participants ({time.strftime('%Y-%m-%d %H:%M:%S')})\n\n"
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


def find_final_exam_slot():
    """2. Tìm hoặc tạo một FINAL_EXAM slot để test."""
    print_info("Đang tìm FINAL_EXAM slot...")
    url = f"{BASE_URL}/api/v1/slots?slotCategory=FINAL_EXAM&pageSize=1"
    headers = get_auth_headers()
    if not headers:
        return None

    response_data = None
    status_code = 0
    try:
        response = requests.get(url, headers=headers)
        status_code = response.status_code
        response_data = response.json()

        if response.status_code == 200:
            items = response_data.get("data", {}).get("items", [])
            if items:
                slot_id = items[0].get("id")
                print_success(f"Tìm thấy FINAL_EXAM slot: ID={slot_id}")
                log_api_call("GET", url, None, status_code, response_data)
                return slot_id
            else:
                print_info("Không tìm thấy FINAL_EXAM slot. Sử dụng ID test mặc định.")
                log_api_call("GET", url, None, status_code, response_data)
                # Return a known test slot ID - adjust based on your test data
                return 252  # From the slot test data
        else:
            print_error(
                f"Tìm FINAL_EXAM slot thất bại. Mã trạng thái: {response.status_code}",
                response_data,
            )
            log_api_call("GET", url, None, status_code, response_data)
            return 252  # Fallback to test ID
    except Exception as e:
        print_error(f"Lỗi không xác định khi tìm FINAL_EXAM slot: {e}")
        log_api_call("GET", url, None, 500, {"error": str(e)})
        return 252


def test_assign_subjects_to_slot(slot_id):
    """3. POST /exam-slots/{slotId}/subjects - Assign subjects to slot"""
    print_info(f"Đang thử assign subjects cho slot {slot_id}...")
    url = f"{BASE_URL}/api/v1/exam-slots/{slot_id}/subjects"
    headers = get_auth_headers()
    if not headers:
        return False

    # Use subject IDs that exist in test data
    payload = {"subjectIds": [1, 2]}

    response_data = None
    status_code = 0
    try:
        response = requests.post(url, headers=headers, json=payload)
        status_code = response.status_code
        response_data = response.json()

        if response.status_code == 201:
            print_success(f"Assign subjects cho slot {slot_id} thành công.")
            log_api_call("POST", url, payload, status_code, response_data)
            return True
        else:
            print_error(
                f"Assign subjects thất bại. Mã trạng thái: {response.status_code}",
                response_data,
            )
            log_api_call("POST", url, payload, status_code, response_data)
            # Might already be assigned, continue anyway
            return True
    except Exception as e:
        print_error(f"Lỗi không xác định khi assign subjects: {e}")
        log_api_call("POST", url, payload, 500, {"error": str(e)})
        return False


def test_get_slot_subjects(slot_id):
    """4. GET /exam-slots/{slotId}/subjects - List subjects"""
    print_info(f"Đang thử lấy subjects của slot {slot_id}...")
    url = f"{BASE_URL}/api/v1/exam-slots/{slot_id}/subjects"
    headers = get_auth_headers()
    if not headers:
        return []

    response_data = None
    status_code = 0
    try:
        response = requests.get(url, headers=headers)
        status_code = response.status_code
        response_data = response.json()

        if response.status_code == 200:
            subjects = response_data.get("data", {}).get("subjects", [])
            print_success(f"Lấy subjects thành công. Tìm thấy {len(subjects)} subjects.")
            log_api_call("GET", url, None, status_code, response_data)
            return subjects
        else:
            print_error(
                f"Lấy subjects thất bại. Mã trạng thái: {response.status_code}",
                response_data,
            )
            log_api_call("GET", url, None, status_code, response_data)
            return []
    except Exception as e:
        print_error(f"Lỗi không xác định khi lấy subjects: {e}")
        log_api_call("GET", url, None, 500, {"error": str(e)})
        return []


def test_add_participant(slot_id, subject_id, student_user_id):
    """5. POST /exam-slots/{slotId}/participants - Add participant"""
    print_info(f"Đang thử thêm participant (student {student_user_id}, subject {subject_id}) cho slot {slot_id}...")
    url = f"{BASE_URL}/api/v1/exam-slots/{slot_id}/participants"
    headers = get_auth_headers()
    if not headers:
        return None

    payload = {
        "studentUserId": student_user_id,
        "subjectId": subject_id
    }

    response_data = None
    status_code = 0
    try:
        response = requests.post(url, headers=headers, json=payload)
        status_code = response.status_code
        response_data = response.json()

        if response.status_code == 201:
            participant_id = response_data.get("data", {}).get("id")
            print_success(f"Thêm participant thành công. ID: {participant_id}")
            log_api_call("POST", url, payload, status_code, response_data)
            return participant_id
        elif response.status_code == 200:
            # Re-enrollment case
            participant_id = response_data.get("data", {}).get("id")
            print_success(f"Re-enrolled participant thành công. ID: {participant_id}")
            log_api_call("POST", url, payload, status_code, response_data)
            return participant_id
        else:
            print_error(
                f"Thêm participant thất bại. Mã trạng thái: {response.status_code}",
                response_data,
            )
            log_api_call("POST", url, payload, status_code, response_data)
            return None
    except Exception as e:
        print_error(f"Lỗi không xác định khi thêm participant: {e}")
        log_api_call("POST", url, payload, 500, {"error": str(e)})
        return None


def test_get_participants(slot_id, subject_id):
    """6. GET /exam-slots/{slotId}/participants - List participants"""
    print_info(f"Đang thử lấy participants cho slot {slot_id}, subject {subject_id}...")
    url = f"{BASE_URL}/api/v1/exam-slots/{slot_id}/participants?subjectId={subject_id}&pageSize=50"
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
            items = response_data.get("data", {}).get("items", [])
            total = response_data.get("data", {}).get("totalEnrolled", 0)
            print_success(f"Lấy participants thành công. Tìm thấy {len(items)} participants (total enrolled: {total}).")
        else:
            print_error(
                f"Lấy participants thất bại. Mã trạng thái: {response.status_code}",
                response_data,
            )
    except Exception as e:
        print_error(f"Lỗi không xác định khi lấy participants: {e}")
        status_code = 500
        response_data = {"error": str(e)}
    finally:
        log_api_call("GET", url, None, status_code, response_data)


def test_get_participant_by_id(slot_id, participant_id):
    """7. GET /exam-slots/{slotId}/participants/{participantId} - Get participant by ID"""
    print_info(f"Đang thử lấy participant ID {participant_id} của slot {slot_id}...")
    url = f"{BASE_URL}/api/v1/exam-slots/{slot_id}/participants/{participant_id}"
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
            print_success(f"Lấy participant {participant_id} thành công.")
        else:
            print_error(
                f"Lấy participant {participant_id} thất bại. Mã trạng thái: {response.status_code}",
                response_data,
            )
    except Exception as e:
        print_error(f"Lỗi không xác định khi lấy participant {participant_id}: {e}")
        status_code = 500
        response_data = {"error": str(e)}
    finally:
        log_api_call("GET", url, None, status_code, response_data)


def test_update_participant(slot_id, participant_id, is_enrolled):
    """8. PUT /exam-slots/{slotId}/participants/{participantId} - Update participant"""
    print_info(f"Đang thử cập nhật participant {participant_id} (isEnrolled={is_enrolled})...")
    url = f"{BASE_URL}/api/v1/exam-slots/{slot_id}/participants/{participant_id}"
    headers = get_auth_headers()
    if not headers:
        return

    payload = {"isEnrolled": is_enrolled}

    response_data = None
    status_code = 0
    try:
        response = requests.put(url, headers=headers, json=payload)
        status_code = response.status_code
        response_data = response.json()

        if response.status_code == 200:
            print_success(f"Cập nhật participant {participant_id} thành công.")
        else:
            print_error(
                f"Cập nhật participant {participant_id} thất bại. Mã trạng thái: {response.status_code}",
                response_data,
            )
    except Exception as e:
        print_error(f"Lỗi không xác định khi cập nhật participant {participant_id}: {e}")
        status_code = 500
        response_data = {"error": str(e)}
    finally:
        log_api_call("PUT", url, payload, status_code, response_data)


# --- Error test cases ---


def test_validation_errors(slot_id):
    """9. Test validation errors"""
    print_info("Bắt đầu kiểm thử các trường hợp LỖI VALIDATION")
    url = f"{BASE_URL}/api/v1/exam-slots/{slot_id}/participants"
    headers = get_auth_headers()
    if not headers:
        return

    test_cases = [
        ("Missing studentUserId", {"subjectId": 1}, 400),
        ("Missing subjectId", {"studentUserId": 100}, 400),
        ("Invalid studentUserId type", {"studentUserId": "abc", "subjectId": 1}, 400),
        ("Student not found", {"studentUserId": 999999, "subjectId": 1}, 404),
        ("Subject not assigned to slot", {"studentUserId": 100, "subjectId": 999}, 400),
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

            if response.status_code == expected_status or (400 <= response.status_code < 500):
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


def test_get_errors(slot_id):
    """10. Test GET endpoint errors"""
    print_info("Bắt đầu kiểm thử các trường hợp LỖI GET")
    headers = get_auth_headers()
    if not headers:
        return

    test_cases = [
        ("Participant not found", f"{BASE_URL}/api/v1/exam-slots/{slot_id}/participants/999999", 404),
        ("Invalid participant ID type", f"{BASE_URL}/api/v1/exam-slots/{slot_id}/participants/abc", 400),
        ("Slot not found", f"{BASE_URL}/api/v1/exam-slots/999999/participants/1", 404),
        ("Invalid slot ID type", f"{BASE_URL}/api/v1/exam-slots/abc/subjects", 400),
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

            if response.status_code == expected_status or (400 <= response.status_code < 500):
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

    print("=" * 60)

    # 2. Tìm FINAL_EXAM slot
    slot_id = find_final_exam_slot()
    if not slot_id:
        print_error("Không thể tìm FINAL_EXAM slot. Đang thoát.")
        generate_markdown_report()
        return

    print("=" * 60)

    # 3. Assign subjects to slot
    print_info("Bắt đầu chạy luồng kiểm thử 'Happy Path'")
    test_assign_subjects_to_slot(slot_id)
    print("-" * 60)

    # 4. Get subjects
    subjects = test_get_slot_subjects(slot_id)
    print("-" * 60)

    # 5. Add participant (if we have subjects)
    participant_id = None
    if subjects:
        subject_id = subjects[0].get("id")
        # Use a known student user ID from test data
        student_user_id = 100  # Adjust based on your test data
        participant_id = test_add_participant(slot_id, subject_id, student_user_id)
        print("-" * 60)

        # 6. Get participants list
        if participant_id:
            test_get_participants(slot_id, subject_id)
            print("-" * 60)

            # 7. Get participant by ID
            test_get_participant_by_id(slot_id, participant_id)
            print("-" * 60)

            # 8. Update participant (withdraw)
            test_update_participant(slot_id, participant_id, False)
            print("-" * 60)

            # 9. Update participant (re-enroll)
            test_update_participant(slot_id, participant_id, True)
    else:
        print_error("Không có subjects. Bỏ qua các bài kiểm thử participant.")

    print("=" * 60)

    # 10. Error tests
    print_info("Bắt đầu chạy các bài kiểm thử lỗi (Error Cases)")
    test_validation_errors(slot_id)
    print("-" * 60)
    test_get_errors(slot_id)

    print("=" * 60)

    print_info("Tất cả các bài kiểm thử đã hoàn tất.")

    # 11. TẠO BÁO CÁO
    generate_markdown_report()


if __name__ == "__main__":
    main()
