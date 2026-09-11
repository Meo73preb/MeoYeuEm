import os
import sys
import json
import sqlite3
import time
import datetime
import threading
import shutil
import random
import traceback
import base64
import subprocess
from urllib.parse import urlparse, parse_qs

# Tự động cài đặt/kiểm tra thư viện phụ thuộc
try:
    import requests
    import psutil
except ImportError:
    print("[+] Đang cài đặt thư viện cần thiết (requests, psutil)...")
    subprocess.run([sys.executable, "-m", "pip", "install", "requests", "psutil"], check=True)
    import requests
    import psutil

# Đường dẫn thư mục làm việc
SCRIPT_DIR = os.path.dirname(os.path.realpath(__file__))
CONFIG_FILE = os.path.join(SCRIPT_DIR, 'config.json')

DEFAULT_CONFIG = {
    'placeid': '17017769292',
    'check_delay': 20,
    'loop_delay': 60,
    'vip_server_link': '',
    'open_home_menu_bf_launch_game': False,
    'open_home_menu_bf_launch_game delay [S]': 30,
    'double_heartbeat_check': True,
    'low_server': False,
    'auto_get_key_fluxus': False,
    'fluxus_get_key_link': '',
    'fluxus_get_key_delay [M]': 15,
    'auto_get_key_delta': False,
    'delta_get_key_delay [M]': 15,
    'webhook_link': '',
    'ugphone_name': 'Ugphone 1',
    'webhook_delay_send [M]': 15,
    'restart_roblox': False,
    'delay_restart_roblox [H]': 3,
    'open_original_roblox': False
}

# Terminal Formatting Colors
RED = '\033[91m'
GREEN = '\033[92m'
YELLOW = '\033[93m'
BLUE = '\033[94m'
MAGENTA = '\033[95m'
CYAN = '\033[96m'
RESET = '\033[0m'

user_data_set = set()
logged_in_usernames = set()
zxcihas = []
lockss = threading.Lock()
predefined_setss = set()

def run_su_command(cmd):
    """Thực thi câu lệnh Root/Shell thông qua 'su' trên Termux/Android."""
    try:
        result = subprocess.run(
            ['su', '-c', cmd],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            timeout=10
        )
        return result.stdout.strip()
    except Exception as e:
        return None

def extract_hwid(input_str):
    try:
        if 'http' in input_str:
            parsed_url = urlparse(input_str)
            query_params = parse_qs(parsed_url.query)
            return query_params.get('id', query_params.get('HWID', [input_str]))[0]
        return input_str
    except Exception:
        return input_str

def decodebase64(link):
    try:
        parsed_url = urlparse(link)
        query_params = parse_qs(parsed_url.query)
        if 'r' in query_params:
            base64_encoded_str = query_params['r'][0]
            decoded_str = base64.b64decode(base64_encoded_str).decode('utf-8')
            decoded_url = urlparse(decoded_str)
            decoded_query_params = parse_qs(decoded_url.query)
            if 'tk' in decoded_query_params:
                return decoded_query_params['tk'][0]
    except Exception:
        pass
    return None

def deltakey(delaygetkey):
    session = requests.Session()
    while True:
        try:
            for xck in zxcihas:
                session.get(f"https://gateway.platoboost.com/v1/authenticators/8/{xck}")
        except Exception:
            pass
        time.sleep(delaygetkey * 60)

def capture_screenshot(filepath):
    """Chụp ảnh màn hình Android sử dụng quyền Root."""
    run_su_command(f"screencap -p {filepath}")

def get_system_info(ugphonename):
    svmem = psutil.virtual_memory()
    description = (
        f"Device Name: {ugphonename}\n"
        f"CPU Cores: {psutil.cpu_count(logical=True)}\n"
        f"CPU Usage: {psutil.cpu_percent()}%\n"
        f"RAM Used: {svmem.used / 1024 ** 3:.2f} GB / {svmem.total / 1024 ** 3:.2f} GB ({svmem.percent}%)"
    )
    return description

def send_webhook(webhooklink, webhookdelaysend, ugphonename):
    while True:
        try:
            try:
                hehe = get_system_info(ugphonename)
            except Exception:
                hehe = 'System Info Not Found'

            img_path = '/storage/emulated/0/download/image.png'
            capture_screenshot(img_path)
            
            timestamp = time.strftime('%Y-%m-%dT%H:%M:%SZ', time.gmtime())
            embed = {
                'title': 'UGPHONE STATUS',
                'description': hehe,
                'author': {'name': ugphonename, 'url': webhooklink},
                'image': {'url': 'attachment://image.png'},
                'footer': {'text': '| UGPhone Auto Launcher |'},
                'timestamp': timestamp,
                'color': 5793266
            }
            payload = {'embeds': [embed]}

            if os.path.exists(img_path):
                with open(img_path, 'rb') as f:
                    files = {
                        'file': ('image.png', f),
                        'payload_json': (None, json.dumps(payload))
                    }
                    requests.post(webhooklink, files=files, timeout=15)
                os.remove(img_path)
        except Exception as e:
            print(f"Webhook Error: {e}")
        
        time.sleep(webhookdelaysend * 60)

def load_config():
    if not os.path.isfile(CONFIG_FILE):
        print(f"[!] Config file not found. Creating default {CONFIG_FILE}")
        with open(CONFIG_FILE, 'w') as f:
            json.dump(DEFAULT_CONFIG, f, indent=4)
        return DEFAULT_CONFIG
    try:
        with open(CONFIG_FILE, 'r') as file:
            return json.load(file)
    except json.JSONDecodeError:
        print(f"[!] Error decoding {CONFIG_FILE}. Using defaults.")
        return DEFAULT_CONFIG

def find_roblox_data_paths():
    base_path = '/data/data'
    paths = []
    config = load_config()
    openoriginal = config.get('open_original_roblox', DEFAULT_CONFIG['open_original_roblox'])
    
    try:
        folders = os.listdir(base_path)
    except PermissionError:
        # Nếu Termux chưa cấp quyền root truy cập /data/data trực tiếp
        out = run_su_command("ls /data/data")
        folders = out.split() if out else []

    for folder in folders:
        if openoriginal:
            if folder.startswith('com.roblox.'):
                path = os.path.join(base_path, folder, 'files/appData/LocalStorage/appStorage.json')
                if os.path.isfile(path) or run_su_command(f"test -f {path} && echo 1") == "1":
                    paths.append(path)
        elif folder.startswith('com.roblox.') and folder != 'com.roblox.client':
            path = os.path.join(base_path, folder, 'files/appData/LocalStorage/appStorage.json')
            if os.path.isfile(path) or run_su_command(f"test -f {path} && echo 1") == "1":
                paths.append(path)
    return paths

def autogetkey(hwid, delaytime):
    session = requests.Session()
    while True:
        print('[+] Fetching Fluxus Key...')
        common_headers = {
            'User-Agent': 'Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Mobile Safari/537.36',
            'Referer': 'https://linkvertise.com/'
        }
        try:
            session.get(f"https://flux.li/android/external/start.php?HWID={hwid}", headers=common_headers, timeout=10)
            session.get('https://flux.li/android/external/check1.php?hash=UXOHeW7XJz4HJrn5im8RtmEed42zfQeK6mti7hPANA41iJbpjcXspnz7eguFDh', headers=common_headers, timeout=10)
            session.get('https://flux.li/android/external/main.php?hash=mlhmSnL1AMay0Q9uPmyKOU2FdsbJz82z8S55K6fV43123oU0W5qyy05U8hiOBDQ', headers=common_headers, timeout=10)
        except Exception as e:
            print(f"[-] Fluxus Key Error: {e}")
        time.sleep(delaytime * 60)

def read_roblox_data(data_path, retries=3):
    attempt = 0
    while attempt < retries:
        try:
            # Đọc file thông qua Root nếu chạy trực tiếp gặp lỗi permission
            content = run_su_command(f"cat {data_path}")
            if content:
                data = json.loads(content)
                user_id = data.get('UserId')
                username = data.get('Username')
                if user_id and username:
                    return (user_id, username)
        except Exception:
            pass
        attempt += 1
        time.sleep(1)
    return (False, False)

def check_cookie():
    global user_data_set
    try:
        COOKIE_FILE = os.path.join(SCRIPT_DIR, 'cookie.txt')
        if not os.path.isfile(COOKIE_FILE):
            return
        with open(COOKIE_FILE, 'r') as file:
            cookies = file.readlines()
        for cookie in cookies:
            cookie_str = cookie.strip()
            if ':' in cookie_str and len(cookie_str.split(':')) >= 3:
                parts = cookie_str.split(':')
                cookien = parts[2] + parts[3]
            else:
                cookien = cookie_str
            
            res = requests.get('https://users.roblox.com/v1/users/authenticated', cookies={'.ROBLOSECURITY': cookien}, timeout=5)
            if res.status_code == 200:
                username = res.json().get('name')
                user_data_set.add((username, cookien))
    except Exception as e:
        print(f"Cookie Check Exception: {e}")

def post_requests(userid, username):
    global user_data_set
    if not user_data_set:
        check_cookie()
    
    headers = {'Content-Type': 'application/json'}
    for user, cookien in user_data_set:
        if user == username:
            headers['Cookie'] = f".ROBLOSECURITY={cookien.strip()}"
            break

    data = {'userIds': [userid]}
    try:
        response = requests.post('https://presence.roblox.com/v1/presence/users', data=json.dumps(data), headers=headers, timeout=5)
        ress = response.json()
        if 'userPresences' in ress and len(ress['userPresences']) > 0:
            if ress['userPresences'][0].get('lastLocation') == 'Website':
                return True
        return False
    except Exception:
        return False

def extract_private_server_code(link):
    try:
        parsed_url = urlparse(link)
        query_params = parse_qs(parsed_url.query)
        if 'share' in parsed_url.path and 'code' in query_params:
            return query_params['code'][0]
        if 'privateServerLinkCode' in query_params:
            return query_params['privateServerLinkCode'][0]
        return link
    except Exception:
        return None

def fetch_servers(PLACE_ID, FOUND_ANYTHING=''):
    try:
        url = f"https://games.roblox.com/v1/games/{PLACE_ID}/servers/0?sortOrder=2&excludeFullGames=true"
        if FOUND_ANYTHING:
            url += f"&cursor={FOUND_ANYTHING}"
        response = requests.get(url, timeout=5)
        data = response.json()
        return (data.get('data', []), data.get('nextPageCursor', ''))
    except Exception:
        return ([], '')

def select_server(servers):
    eligible_servers = [s for s in servers if s['id'] not in predefined_setss]
    if not eligible_servers:
        return None
    random_number = random.randint(2, 6)
    low_player_servers = [s for s in eligible_servers if 2 <= s.get('playing', 0) <= random_number]
    if low_player_servers:
        return sorted(low_player_servers, key=lambda x: x['playing'])[0]['id']
    return None

def fetch_and_choose_server(PLACE_ID):
    cursor = ''
    while True:
        servers, cursor = fetch_servers(PLACE_ID, cursor)
        if servers:
            chosen_id = select_server(servers)
            if chosen_id:
                with lockss:
                    predefined_setss.add(chosen_id)
                return chosen_id
        if not cursor:
            break
    return None

def force_roblox(package_name):
    """Buộc dừng ứng dụng Roblox bằng lệnh am force-stop qua Root."""
    run_su_command(f"am force-stop {package_name}")

def killallroblox():
    roblox_paths = find_roblox_data_paths()
    if not roblox_paths:
        return
    for data_path in roblox_paths:
        roblox_package = data_path.split(os.sep)[3]
        force_roblox(roblox_package)
        time.sleep(1)

def launch_roblox(roblox_package, placeid, check_delay, psserver, open_home_menu_bf_launch_game, lowserver, username, delayopenhomemenu):
    force_roblox(roblox_package)
    time.sleep(2)
    
    if open_home_menu_bf_launch_game:
        run_su_command(f"monkey -p {roblox_package} -c android.intent.category.LAUNCHER 1")
        time.sleep(delayopenhomemenu)

    if psserver != '':
        pslink = extract_private_server_code(psserver)
        viplink = f"roblox://placeID={placeid}&linkCode={pslink}"
        launch_cmd = f"am start -a android.intent.action.VIEW -d \"{viplink}\" {roblox_package}"
    elif lowserver:
        chosen_server_id = fetch_and_choose_server(placeid)
        viplink = f"roblox://gameInstances.roblox.com/v1/games/placeId={placeid}/serverInstanceId={chosen_server_id}"
        launch_cmd = f"am start -a android.intent.action.VIEW -d \"{viplink}\" {roblox_package}"
    else:
        viplink = f"roblox://placeID={placeid}"
        launch_cmd = f"am start -a android.intent.action.VIEW -d \"{viplink}\" {roblox_package}"
    
    run_su_command(launch_cmd)
    time.sleep(check_delay)

def main():
    os.system('clear')
    print('[+] Loading config.json file...')
    config = load_config()
    placeid = config.get('placeid', DEFAULT_CONFIG['placeid'])
    check_delay = config.get('check_delay', DEFAULT_CONFIG['check_delay'])
    loop_delay = config.get('loop_delay', DEFAULT_CONFIG['loop_delay'])
    psserver = config.get('vip_server_link', DEFAULT_CONFIG['vip_server_link'])
    double_heartbeat_check = config.get('double_heartbeat_check', DEFAULT_CONFIG['double_heartbeat_check'])
    open_home_menu_bf_launch_game = config.get('open_home_menu_bf_launch_game', DEFAULT_CONFIG['open_home_menu_bf_launch_game'])
    open_home_menu_bf_launch_gamedelay = config.get('open_home_menu_bf_launch_game delay [S]', DEFAULT_CONFIG['open_home_menu_bf_launch_game delay [S]'])
    fluxus_get_key_link = config.get('fluxus_get_key_link', DEFAULT_CONFIG['fluxus_get_key_link'])
    auto_get_key_fluxus = config.get('auto_get_key_fluxus', DEFAULT_CONFIG['auto_get_key_fluxus'])
    auto_get_key_delta = config.get('auto_get_key_delta', DEFAULT_CONFIG['auto_get_key_delta'])
    fluxusgetkeydelay = config.get('fluxus_get_key_delay [M]', DEFAULT_CONFIG['fluxus_get_key_delay [M]'])
    deltagetkeydelay = config.get('delta_get_key_delay [M]', DEFAULT_CONFIG['delta_get_key_delay [M]'])
    lowserver = config.get('low_server', DEFAULT_CONFIG['low_server'])
    webhooklink = config.get('webhook_link', DEFAULT_CONFIG['webhook_link'])
    webhookdelay = config.get('webhook_delay_send [M]', DEFAULT_CONFIG['webhook_delay_send [M]'])
    ugphone_name = config.get('ugphone_name', DEFAULT_CONFIG['ugphone_name'])
    restart_roblox = config.get('restart_roblox', DEFAULT_CONFIG['restart_roblox'])
    delayrestart = config.get('delay_restart_roblox [H]', DEFAULT_CONFIG['delay_restart_roblox [H]'])

    if auto_get_key_fluxus and fluxus_get_key_link:
        hwid = extract_hwid(fluxus_get_key_link)
        threading.Thread(target=autogetkey, args=(hwid, fluxusgetkeydelay), daemon=True).start()

    if webhooklink:
        threading.Thread(target=send_webhook, args=(webhooklink, webhookdelay, ugphone_name), daemon=True).start()

    if restart_roblox:
        threading.Thread(target=killrobloxh, args=(delayrestart,), daemon=True).start()

    if auto_get_key_delta:
        roblox_paths = find_roblox_data_paths()
        for data_path in roblox_paths:
            userid, _ = read_roblox_data(data_path)
            if userid:
                zxcihas.append(userid)
        threading.Thread(target=deltakey, args=(deltagetkeydelay,), daemon=True).start()

    while True:
        roblox_paths = find_roblox_data_paths()
        if not roblox_paths:
            print('[-] No Roblox accounts/packages found.')
            time.sleep(loop_delay)
            continue

        for data_path in roblox_paths:
            userid, username = read_roblox_data(data_path)
            if userid and username:
                print(f"{GREEN}[+] Checking user: {YELLOW}{username}{RESET}")
                status = post_requests(userid, username)
                if double_heartbeat_check:
                    time.sleep(15)
                    status = post_requests(userid, username)
                
                current_time = datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')
                if status:
                    print(f"{RED}[!] Disconnected/Offline: {YELLOW}{username}{RESET} at {CYAN}{current_time}{RESET} -> Relaunching")
                    roblox_package = data_path.split(os.sep)[3]
                    launch_roblox(roblox_package, placeid, check_delay, psserver, open_home_menu_bf_launch_game, lowserver, username, open_home_menu_bf_launch_gamedelay)
                else:
                    print(f"{GREEN}[+] Active/Online: {YELLOW}{username}{RESET} at {CYAN}{current_time}{RESET}")

        time.sleep(loop_delay)

def killrobloxh(delay):
    while True:
        time.sleep(delay * 3600)
        killallroblox()

def logout_roblox():
    roblox_paths = find_roblox_data_paths()
    if not roblox_paths:
        print('[-] No Roblox accounts found.')
        return

    accounts = []
    print('\nAvailable Roblox accounts:')
    for i, data_path in enumerate(roblox_paths, start=1):
        userid, username = read_roblox_data(data_path)
        if userid and username:
            accounts.append((userid, username, data_path))
            print(f"{i}. {username} (ID: {userid})")

    if not accounts:
        print('[-] No active Roblox sessions found.')
        return

    choice = input("\nEnter account number to logout, '0' for ALL, or 'q' to quit: ").strip()
    if choice.lower() == 'q':
        return

    if choice == '0':
        for userid, username, data_path in accounts:
            pkg = data_path.split(os.sep)[3]
            force_roblox(pkg)
            run_su_command(f"rm -f {data_path}")
            print(f"[+] Logged out {username}")
    else:
        try:
            idx = int(choice) - 1
            if 0 <= idx < len(accounts):
                userid, username, data_path = accounts[idx]
                pkg = data_path.split(os.sep)[3]
                force_roblox(pkg)
                run_su_command(f"rm -f {data_path}")
                print(f"[+] Logged out {username}")
        except ValueError:
            print("[-] Invalid selection.")
    time.sleep(3)

def update_cookies_db(cookie_value):
    try:
        db_path = os.path.join(SCRIPT_DIR, 'Cookies.db')
        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()
        cursor.execute("UPDATE Cookies SET value=? WHERE name='.ROBLOSECURITY'", (cookie_value.strip(),))
        conn.commit()
        conn.close()
    except Exception as e:
        print(f"[-] SQLite Update Error: {e}")

def login_roblox():
    COOKIE_FILE = os.path.join(SCRIPT_DIR, 'cookie.txt')
    if not os.path.isfile(COOKIE_FILE):
        print("[-] cookie.txt not found in script directory!")
        return

    with open(COOKIE_FILE, 'r') as f:
        cookies = [line.strip() for line in f if line.strip()]

    base_path = '/data/data'
    out = run_su_command("ls /data/data")
    folders = out.split() if out else []

    roblox_pkgs = [f for f in folders if f.startswith('com.roblox.') and f != 'com.roblox.client']
    
    for i, pkg in enumerate(roblox_pkgs):
        if i >= len(cookies):
            print("[-] Run out of cookies in cookie.txt")
            break

        cookie = cookies[i]
        if ':' in cookie and len(cookie.split(':')) >= 3:
            parts = cookie.split(':')
            cookie = parts[2] + parts[3]

        # Kiểm tra cookie
        res = requests.get('https://users.roblox.com/v1/users/authenticated', cookies={'.ROBLOSECURITY': cookie}, timeout=5)
        if res.status_code != 200:
            print(f"[-] Invalid cookie for index {i}")
            continue

        user_info = res.json()
        username = user_info['name']
        userid = user_info['id']

        force_roblox(pkg)

        # Cập nhật Cookies.db và copy sang app_webview
        update_cookies_db(cookie)
        target_db = f"/data/data/{pkg}/app_webview/Default/Cookies"
        run_su_command(f"cp -f {os.path.join(SCRIPT_DIR, 'Cookies.db')} {target_db}")
        run_su_command(f"chmod 660 {target_db}")

        # Cập nhật appStorage.json
        appstorage_target = f"/data/data/{pkg}/files/appData/LocalStorage/appStorage.json"
        appstorage_template = os.path.join(SCRIPT_DIR, 'appStorage.json')

        if os.path.exists(appstorage_template):
            run_su_command(f"cp -f {appstorage_template} {appstorage_target}")
            
            # Cập nhật thông tin UserId/Username trong appStorage.json qua root
            json_data = json.dumps({"UserId": str(userid), "Username": str(username)})
            run_su_command(f"echo '{json_data}' > {appstorage_target}")
            run_su_command(f"chmod 660 {appstorage_target}")

        print(f"[+] Successfully logged into package {pkg} as {username}")

    time.sleep(3)

def setup_autoexec_folder():
    source_autoexec = os.path.join(SCRIPT_DIR, 'autoexec')
    if not os.path.exists(source_autoexec):
        print("[-] 'autoexec' folder missing in script directory.")
        return

    target_dirs = []
    base_android_data = '/storage/emulated/0/Android/data'
    
    if os.path.exists(base_android_data):
        for folder in os.listdir(base_android_data):
            if folder.startswith('com.roblox.'):
                for sub in ['files/Fluxus/Autoexec', 'files/Delta/autoexec']:
                    full_p = os.path.join(base_android_data, folder, sub)
                    if os.path.exists(full_p):
                        target_dirs.append(full_p)

    print("\nFound Autoexec paths:")
    for idx, path in enumerate(target_dirs, 1):
        print(f"{idx}. {path}")

    choice = input("\nEnter number to copy files to (0 for ALL): ").strip()
    if choice == '0':
        for t_dir in target_dirs:
            for file in os.listdir(source_autoexec):
                shutil.copy(os.path.join(source_autoexec, file), t_dir)
        print("[+] Copied to all autoexec folders.")
    elif choice.isdigit() and 0 < int(choice) <= len(target_dirs):
        t_dir = target_dirs[int(choice) - 1]
        for file in os.listdir(source_autoexec):
            shutil.copy(os.path.join(source_autoexec, file), t_dir)
        print(f"[+] Copied to {t_dir}")
    time.sleep(3)

def menu():
    while True:
        try:
            print("\n==================================")
            print("   UGPHONE ROBLOX AUTO LAUNCHER   ")
            print("==================================")
            print("1. Start Auto Launcher Loop")
            print("2. Logout Roblox Accounts")
            print("3. Login Roblox Accounts from cookie.txt")
            print("4. Setup AutoExec Folder")
            print("5. Kill All Roblox Instances")
            print("6. Exit")
            
            choice = input("\nSelect option [1-6]: ").strip()
            if choice == '1':
                main()
            elif choice == '2':
                logout_roblox()
            elif choice == '3':
                login_roblox()
            elif choice == '4':
                setup_autoexec_folder()
            elif choice == '5':
                killallroblox()
                print("[+] All Roblox apps stopped.")
            elif choice == '6':
                sys.exit(0)
            else:
                print("[-] Invalid choice.")
        except Exception:
            traceback.print_exc()
            time.sleep(3)

if __name__ == '__main__':
    menu()
