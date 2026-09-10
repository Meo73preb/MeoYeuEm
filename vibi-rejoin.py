import os
import sys
import json
import time
import sqlite3
import subprocess
import requests

ROBLOX_PKG = "com.roblox.client"
DATA_DIR = f"/data/data/{ROBLOX_PKG}"
COOKIES_DB = f"{DATA_DIR}/app_webview/Default/Cookies"
APP_STORAGE = f"{DATA_DIR}/files/appData/LocalStorage/appStorage.json"

def run_cmd(cmd):
    """Thực thi lệnh shell với quyền Root"""
    try:
        result = subprocess.run(f"su -c '{cmd}'", shell=True, capture_output=True, text=True, timeout=10)
        return result.stdout.strip()
    except Exception as e:
        return ""

def kill_roblox():
    """Tắt hoàn toàn Roblox"""
    run_cmd(f"am force-stop {ROBLOX_PKG}")
    time.sleep(1)

# ==================== 1. GET COOKIE ====================
def get_cookie():
    print("\n[*] Đang trích xuất Cookie từ Roblox App...")
    if not os.path.exists(COOKIES_DB):
        # Coppy tạm DB ra tmp để đọc tránh bị khóa file
        run_cmd(f"cp {COOKIES_DB} /sdcard/Cookies_tmp.db")
        db_path = "/sdcard/Cookies_tmp.db"
    else:
        db_path = COOKIES_DB

    try:
        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()
        cursor.execute("SELECT value FROM cookies WHERE name='.ROBLOSECURITY'")
        row = cursor.fetchone()
        conn.close()
        
        if os.path.exists("/sdcard/Cookies_tmp.db"):
            os.remove("/sdcard/Cookies_tmp.db")

        if row and row[0]:
            cookie = row[0]
            print(f"\n[+] Lấy Cookie thành công!")
            print(f"Cookie: {cookie}\n")
            
            # Lưu vào file cookie.txt
            with open("cookie.txt", "w") as f:
                f.write(cookie)
            print("[+] Đã lưu vào file 'cookie.txt'")
            return cookie
        else:
            print("[-] Không tìm thấy Cookie .ROBLOSECURITY. Hãy đăng nhập tài khoản trên App trước.")
    except Exception as e:
        print(f"[-] Lỗi khi lấy Cookie: {e}")
    return None

# ==================== 2. LOGIN COOKIE ====================
def login_cookie(cookie_input=None):
    if not cookie_input:
        cookie_input = input("\nNhập chuỗi Cookie (.ROBLOSECURITY): ").strip()
    
    if not cookie_input:
        print("[-] Cookie không được để trống!")
        return

    # Kiểm tra cookie hợp lệ qua API
    print("[*] Đang xác thực Cookie với Roblox...")
    headers = {'Cookie': f'.ROBLOSECURITY={cookie_input}'}
    try:
        res = requests.get('https://users.roblox.com/v1/users/authenticated', headers=headers, timeout=5)
        if res.status_code != 200:
            print("[-] Cookie không hợp lệ hoặc đã hết hạn!")
            return
        
        user_data = res.json()
        user_id = user_data.get('id')
        username = user_data.get('name')
        print(f"[+] Cookie hợp lệ! Username: {username} (ID: {user_id})")

    except Exception as e:
        print(f"[-] Lỗi kết nối API: {e}")
        return

    print("[*] Đang ghi Cookie vào Roblox App...")
    kill_roblox()

    # Cập nhật SQLite Cookies DB
    sql_cmd = f"UPDATE cookies SET value='{cookie_input}' WHERE name='.ROBLOSECURITY';"
    run_cmd(f"sqlite3 {COOKIES_DB} \"{sql_cmd}\"")

    # Cập nhật appStorage.json
    try:
        run_cmd(f"chmod 777 {APP_STORAGE}")
        storage_str = run_cmd(f"cat {APP_STORAGE}")
        if storage_str:
            data = json.loads(storage_str)
        else:
            data = {}

        data['UserId'] = str(user_id)
        data['Username'] = str(username)

        # Ghi lại dữ liệu mới vào appStorage
        json_str = json.dumps(data).replace('"', '\\"')
        run_cmd(f'echo "{json_str}" > {APP_STORAGE}')
        
        print("[+] Đăng nhập Cookie vào App THÀNH CÔNG! Đã cập nhật Session.")
    except Exception as e:
        print(f"[-] Lỗi ghi dữ liệu App Storage: {e}")

# ==================== 3. REJOIN / AUTO LAUNCH ====================
def launch_game(place_id, job_id=None):
    """Mở game Roblox bằng Intent DeepLink"""
    if job_id:
        url = f"roblox://placeID={place_id}&gameInstanceId={job_id}"
    else:
        url = f"roblox://placeID={place_id}"

    cmd = f"am start -a android.intent.action.VIEW -d \"{url}\" {ROBLOX_PKG}"
    run_cmd(cmd)

def auto_rejoin():
    place_id = input("\nNhập Place ID của Game: ").strip()
    if not place_id:
        print("[-] Place ID không hợp lệ!")
        return
    
    check_interval = input("Nhập thời gian kiểm tra Rejoin (giây, mặc định 30): ").strip()
    check_interval = int(check_interval) if check_interval.isdigit() else 30

    print(f"\n[*] Đã kích hoạt Auto Rejoin cho Place ID: {place_id}")
    print("[*] Đang khởi động Game...")
    
    launch_game(place_id)
    time.sleep(15)

    while True:
        try:
            # Kiểm tra xem Roblox process có đang chạy không
            pgrep_out = run_cmd(f"pgrep -f {ROBLOX_PKG}")
            
            if not pgrep_out:
                print(f"[!] Roblox đã bị văng hoặc đóng. Đang Rejoin lại game (Place ID: {place_id})...")
                launch_game(place_id)
                time.sleep(15)
            else:
                # Kiểm tra trạng thái User Presence qua API để xác nhận có trong game không
                # Nối tiếp kiểm tra process sống
                pass

        except KeyboardInterrupt:
            print("\n[-] Đã dừng Auto Rejoin.")
            break
        except Exception as e:
            print(f"[-] Lỗi Rejoin: {e}")

        time.sleep(check_interval)

# ==================== MENU CHÍNH ====================
def menu():
    while True:
        print("\n================ ROBLOX TOOL MANAGER ================")
        print("1. Get Cookie (Lấy Cookie từ App)")
        print("2. Login Cookie (Đăng nhập Cookie vào App)")
        print("3. Auto Rejoin / Auto Launch Game")
        print("0. Thoát")
        print("=====================================================")
        
        choice = input("Chọn chức năng (0-3): ").strip()
        
        if choice == '1':
            get_cookie()
        elif choice == '2':
            login_cookie()
        elif choice == '3':
            auto_rejoin()
        elif choice == '0':
            print("Đã thoát Tool.")
            break
        else:
            print("Lựa chọn không hợp lệ!")

if __name__ == "__main__":
    menu()
