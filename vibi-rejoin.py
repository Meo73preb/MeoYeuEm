import os
import sys
import time
import json
import sqlite3
import subprocess
import requests
import threading
import websocket # Cần cài đặt: pip install websocket-client

# Các đường dẫn mặc định
TERMUX_DOWNLOAD_DIR = "/sdcard/Download"
COOKIE_FILE_PATH = os.path.join(TERMUX_DOWNLOAD_DIR, "cookie.txt")
DISCORD_TOKEN_PATH = os.path.join(TERMUX_DOWNLOAD_DIR, "discord_token.txt")
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
APPSTORAGE_TEMPLATE = os.path.join(SCRIPT_DIR, "appStorage.json")
COOKIES_DB_TEMPLATE = os.path.join(SCRIPT_DIR, "Cookies.db")

ROBLOX_PACKAGE = "com.roblox.client"
TARGET_APPSTORAGE = f"/data/data/{ROBLOX_PACKAGE}/files/appData/LocalStorage/appStorage.json"
TARGET_COOKIES_DB = f"/data/data/{ROBLOX_PACKAGE}/app_webview/Default/Cookies"

# ID Application Discord mặc định cho Roblox RPC
DROIDBLOX_APP_ID = "1379313837169311825"

def run_root_cmd(cmd):
    """Chạy lệnh Shell dưới quyền Root (su)"""
    try:
        result = subprocess.run(f"su -c '{cmd}'", shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
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

    if ":" in cookie and len(cookie.split(":")) >= 3:
        parts = cookie.split(":")
        cookie = parts[2] + parts[3]
        
    return cookie

def validate_cookie(cookie):
    """Kiểm tra Cookie qua API Roblox và lấy UserID, Username"""
    url = "https://users.roblox.com/v1/users/authenticated"
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

    run_root_cmd(f"chmod 666 '{TARGET_APPSTORAGE}'")
    run_root_cmd(f"chmod 666 '{TARGET_COOKIES_DB}'")

    if os.path.exists(temp_appstorage): os.remove(temp_appstorage)
    if os.path.exists(temp_cookies_db): os.remove(temp_cookies_db)

    print("[*] Đang khởi chạy Roblox...")
    time.sleep(2)
    run_root_cmd(f"monkey -p {ROBLOX_PACKAGE} -c android.intent.category.LAUNCHER 1")
    time.sleep(5)

def rejoin_roblox():
    """Chức năng Rejoin vào Game Roblox (Đã sửa lỗi URI Intent)"""
    place_id = input("Nhập Place ID (Game ID) muốn vào: ").strip()
    if not place_id.isdigit():
        print("[!] Place ID phải là dãy số.")
        return

    kill_roblox()
    print(f"[*] Đang vào lại game (Place ID: {place_id})...")
    
    # Sửa lỗi: Sử dụng URI scheme intent chuẩn cho Roblox Android
    intent_url = f"roblox://placeID={place_id}"
    cmd = f"am start -a android.intent.action.VIEW -d '{intent_url}' {ROBLOX_PACKAGE}"
    
    res = run_root_cmd(cmd)
    
    # Backup method nếu intent trực tiếp không khởi động được
    if "Error" in res or not res:
        print("[!] Thử phương thức khởi chạy dự phòng...")
        cmd_alt = f"am start -W -a android.intent.action.VIEW -d 'roblox://navigation/game_details?gameId={place_id}' {ROBLOX_PACKAGE}"
        run_root_cmd(cmd_alt)
        
    print("[+] Đã gửi lệnh Rejoin Roblox thành công.")

def get_discord_token():
    """Đọc Discord Token từ file hoặc nhập mới"""
    if not os.path.exists(DISCORD_TOKEN_PATH):
        token = input("Nhập Discord User Token: ").strip()
        if token:
            with open(DISCORD_TOKEN_PATH, "w", encoding="utf-8") as f:
                f.write(token)
            return token
        return None
    with open(DISCORD_TOKEN_PATH, "r", encoding="utf-8") as f:
        return f.read().strip()

def start_discord_rpc(token, game_name="Roblox", details="Playing Roblox Mobile"):
    """Kết nối Discord Gateway và cập nhật Rich Presence (Status đang chơi)"""
    ws_url = "wss://gateway.discord.gg/?v=9&encoding=json"
    
    def on_message(ws, message):
        data = json.loads(message)
        op = data.get("op")
        
        # OP 10: Hello -> Gửi Identify payload kèm Presence
        if op == 10:
            heartbeat_interval = data["d"]["heartbeat_interval"] / 1000
            
            # Start Heartbeat thread
            def heartbeat():
                while True:
                    time.sleep(heartbeat_interval)
                    ws.send(json.dumps({"op": 1, "d": None}))
            
            threading.Thread(target=heartbeat, daemon=True).start()
            
            # Identify payload với Rich Presence
            payload = {
                "op": 2,
                "d": {
                    "token": token,
                    "properties": {
                        "$os": "android",
                        "$browser": "DroidBlox",
                        "$device": "mobile"
                    },
                    "presence": {
                        "activities": [{
                            "name": game_name,
                            "type": 0, # 0 = Playing
                            "details": details,
                            "state": "In-Game via Termux",
                            "application_id": DROIDBLOX_APP_ID,
                            "timestamps": {
                                "start": int(time.time() * 1000)
                            },
                            "assets": {
                                "large_image": "roblox",
                                "large_text": "Roblox Mobile"
                            }
                        }],
                        "status": "online",
                        "afk": False
                    }
                }
            }
            ws.send(json.dumps(payload))
            print("\n[+] Đã cập nhật trạng thái Discord: Đang chơi Roblox!")

    def on_error(ws, error):
        print(f"\n[!] Lỗi kết nối Discord RPC: {error}")

    def on_close(ws, close_status_code, close_msg):
        print("\n[*] Kết nối Discord RPC đã đóng.")

    ws = websocket.WebSocketApp(ws_url, on_message=on_message, on_error=on_error, on_close=on_close)
    ws_thread = threading.Thread(target=ws.run_forever, daemon=True)
    ws_thread.start()

def discord_login_rpc():
    """Chức năng Lệnh 3: Discord Login & Live Presence"""
    token = get_discord_token()
    if not token:
        print("[!] Không tìm thấy Discord Token!")
        return
        
    # Kiểm tra Token bằng API
    headers = {"Authorization": token}
    res = requests.get("https://discord.com/api/v9/users/@me", headers=headers)
    if res.status_code != 200:
        print(f"[!] Token Discord không hợp lệ (Status: {res.status_code})")
        if os.path.exists(DISCORD_TOKEN_PATH):
            os.remove(DISCORD_TOKEN_PATH)
        return
        
    user_info = res.json()
    username = user_info.get("username", "Unknown")
    print(f"[+] Đã đăng nhập Discord: {username}")
    
    game_details = input("Nhập tên Game/Chi tiết đang chơi (Bấm Enter để mặc định 'Roblox Mobile'): ").strip()
    if not game_details:
        game_details = "Roblox Mobile"
        
    start_discord_rpc(token, game_name="Roblox", details=game_details)

def main_menu():
	os.system('clear')
    print("\n=== Vibi-Rejoin Tool ===")
    print("1. Rejoin Roblox Mobile")
    print("2. Login bằng Cookie (từ download/cookie.txt)")
    print("3. Discord Login & Live (Hiện trạng thái đang chơi)")
    print("0. Thoát")
    
    try:
        choice = input("Chọn chức năng (0-3): ").strip()
        if choice == "1":
            rejoin_roblox()
        elif choice == "2":
            login_with_cookie()
        elif choice == "3":
            discord_login_rpc()
        elif choice == "0":
            print("Tạm biệt!")
            sys.exit(0)
        else:
            print("[!] Lựa chọn không hợp lệ, thử lại.")
            
    except Exception as e:
        print(f"[!] Đã xảy ra lỗi: {e}")
    
    except KeyboardInterrupt:
        print("\n[!] Đã tắt chương trình bằng phím tắt.")
        sys.exit(0)

    time.sleep(1)
    main_menu()

if __name__ == "__main__":
    main_menu()
