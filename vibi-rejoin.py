import os
import sys
import time
import json
import sqlite3
import subprocess
import requests

# Các đường dẫn mặc định
TERMUX_DOWNLOAD_DIR = "/sdcard/Download"
COOKIE_FILE_PATH = os.path.join(TERMUX_DOWNLOAD_DIR, "cookie.txt")
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
APPSTORAGE_TEMPLATE = os.path.join(SCRIPT_DIR, "appStorage.json")
COOKIES_DB_TEMPLATE = os.path.join(SCRIPT_DIR, "Cookies.db")

ROBLOX_PACKAGE = "com.roblox.client"
TARGET_APPSTORAGE = f"/data/data/{ROBLOX_PACKAGE}/files/appData/LocalStorage/appStorage.json"
TARGET_COOKIES_DB = f"/data/data/{ROBLOX_PACKAGE}/app_webview/Default/Cookies"

def run_root_cmd(cmd):
    """Chạy lệnh Shell dưới quyền Root (su)"""
    try:
        result = subprocess.run(f"su -c \"{cmd}\"", shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        return result.stdout.strip()
    except Exception as e:
        print(f"[!] Lỗi khi chạy lệnh root: {e}")
        return ""

def kill_roblox():
    """Tắt ứng dụng Roblox nếu đang chạy"""
    print("[*] Đang tắt Roblox...")
    run_root_cmd(f"am force-stop {ROBLOX_PACKAGE}")
    time.sleep(1)

def get_cookie():
    """Đọc cookie từ thư mục Download hoặc tạo file mới nếu chưa có"""
    if not os.path.exists(COOKIE_FILE_PATH):
        try:
            with open(COOKIE_FILE_PATH, "w", encoding="utf-8") as f:
                f.write("")
        except Exception as e:
            print(f"[!] Lỗi khi tạo file cookie: {e}")
        print(f"[!] File cookie.txt chưa có nội dung. Vui lòng nhập cookie tại: {COOKIE_FILE_PATH}")
        return None

    with open(COOKIE_FILE_PATH, "r", encoding="utf-8") as f:
        cookie = f.read().strip()

    if not cookie:
        print(f"[!] Vui lòng nhập cookie tại file {COOKIE_FILE_PATH}")
        return None

    # Lọc chuỗi cookie nếu dạng user:pass:cookie
    if ":" in cookie and len(cookie.split(":")) >= 3:
        parts = cookie.split(":")
        cookie = parts[2] + parts[3]
        
    return cookie

def validate_cookie(cookie):
    """Kiểm tra Cookie qua API Roblox và lấy UserID, Username"""
    url = "https://roblox.com"
    headers = {
        "User-Agent": "Mozilla/5.0 (Android; Mobile)",
        "Cookie": f".ROBLOSECURITY={cookie}"
    }
    try:
        res = requests.get(url, headers=headers, timeout=10)
        if res.status_code == 200:
            data = res.json()
            return str(data.get("id")), data.get("name")
        else:
            print(f"[!] Cookie không hợp lệ hoặc đã hết hạn (Status code: {res.status_code})")
            return None, None
    except Exception as e:
        print(f"[!] Lỗi kết nối API Roblox: {e}")
        return None, None

def login_with_cookie():
    """Chức năng Login Roblox bằng Cookie"""
    kill_roblox()
    
    cookie = get_cookie()
    if not cookie:
        return

    print("[*] Đang xác thực cookie...")
    user_id, username = validate_cookie(cookie)
    if not user_id or not username:
        return

    print(f"[+] Xác thực thành công: {username} (ID: {user_id})")
    
    time.sleep(1)
    # 1. Tạo và Cập nhật file appStorage.json tạm thời
    temp_appstorage = os.path.join(SCRIPT_DIR, "temp_appStorage.json")
    if os.path.exists(APPSTORAGE_TEMPLATE):
        with open(APPSTORAGE_TEMPLATE, "r", encoding="utf-8") as f:
            app_data = json.load(f)
    else:
        app_data = {}

    app_data["UserId"] = str(user_id)
    app_data["Username"] = str(username)
    
    with open(temp_appstorage, "w", encoding="utf-8") as f:
        json.dump(app_data, f)

    # 2. Tạo và Cập nhật file Cookies.db tạm thời
    temp_cookies_db = os.path.join(SCRIPT_DIR, "temp_Cookies.db")
    if os.path.exists(COOKIES_DB_TEMPLATE):
        subprocess.run(f"cp '{COOKIES_DB_TEMPLATE}' '{temp_cookies_db}'", shell=True)
        try:
            conn = sqlite3.connect(temp_cookies_db)
            cursor = conn.cursor()
            cursor.execute("UPDATE cookies SET value=? WHERE name='.ROBLOSECURITY'", (cookie,))
            conn.commit()
            conn.close()
        except Exception as e:
            print(f"[!] Lỗi ghi đè SQLite DB: {e}")

    # 3. Chép đè vào hệ thống bằng quyền root
    print("[*] Đang nạp dữ liệu đăng nhập vào hệ thống Roblox...")
    run_root_cmd(f"mkdir -p /data/data/{ROBLOX_PACKAGE}/files/appData/LocalStorage")
    run_root_cmd(f"mkdir -p /data/data/{ROBLOX_PACKAGE}/app_webview/Default")
    
    run_root_cmd(f"cp '{temp_appstorage}' '{TARGET_APPSTORAGE}'")
    if os.path.exists(temp_cookies_db):
        run_root_cmd(f"cp '{temp_cookies_db}' '{TARGET_COOKIES_DB}'")

    # Phân quyền cho file để Roblox có thể đọc/ghi
    run_root_cmd(f"chmod 666 '{TARGET_APPSTORAGE}'")
    run_root_cmd(f"chmod 666 '{TARGET_COOKIES_DB}'")

    # Dọn dẹp file tạm
    if os.path.exists(temp_appstorage): os.remove(temp_appstorage)
    if os.path.exists(temp_cookies_db): os.remove(temp_cookies_db)

    # 4. Mở Roblox và đưa về giao diện Home
    print("[*] Đang khởi chạy Roblox...")
    time.sleep(1)
    run_root_cmd(f"monkey -p {ROBLOX_PACKAGE} -c android.intent.category.LAUNCHER 1")
    time.sleep(30)
    kill_roblox()
    print("[+] Đăng nhập thành công! Hãy đợi Roblox load xong dữ liệu.")

def rejoin_roblox():
    """Chức năng Rejoin vào Game Roblox (Hỗ trợ cả Server Thường và Server VIP)"""
    print("\n--- CHỌN CHẾ ĐỘ REJOIN ---")
    print("1. Vào Server Thường (Dùng Place ID)")
    print("2. Vào Server VIP (Dùng Private/VIP Link)")
    mode = input("Lựa chọn (1-2): ").strip()

    if mode == "1":
        place_id = input("Nhập Place ID (Game ID): ").strip()
        if not place_id.isdigit():
            print("[!] Place ID phải là dãy số.")
            return
        deep_link = f"https://roblox.com{place_id}"
        print(f"[*] Đang chuẩn bị vào Server Thường (ID: {place_id})...")

    elif mode == "2":
        vip_link = input("Nhập/Dán link Server VIP: ").strip()
        if "roblox.com" not in vip_link:
            print("[!] Link không hợp lệ. Phải chứa đường dẫn roblox.com")
            return
        
        # Nếu là link dạng share code cũ hoặc mới, Android Intent sẽ tự phân tách và điều hướng mở app
        deep_link = vip_link
        print(f"[*] Đang chuẩn bị vào Server VIP qua liên kết...")

    else:
        print("[!] Lựa chọn không hợp lệ.")
        return

    kill_roblox()
    time.sleep(1)
    
    # Thực hiện lệnh gọi deep-link để mở thẳng game
    cmd = f"am start -a android.intent.action.VIEW -d '{deep_link}' {ROBLOX_PACKAGE}"
    run_root_cmd(cmd)
    print("[+] Đã gửi lệnh Rejoin Roblox thành công.")

def main_menu():
    while True:
        print("\n=== ROBLOX TOOL FOR TERMUX (ROOT) ===")
        print("1. Rejoin Roblox Mobile (Thường & VIP)")
        print("2. Login bằng Cookie (từ download/cookie.txt)")
        print("0. Thoát")
        
        choice = input("Chọn chức năng (0-2): ").strip()
        if choice == "1":
            os.system('clear')
            rejoin_roblox()
        elif choice == "2":
            login_with_cookie()
            os.system('clear')
        elif choice == "0":
            print("Tạm biệt!")
            sys.exit(0)
        else:
            print("[!] Lựa chọn không hợp lệ, thử lại.")

if __name__ == "__main__":
    main_menu()
