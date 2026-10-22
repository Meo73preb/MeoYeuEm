import os
import sys
import time
import json
import sqlite3
import subprocess
import requests

# Path Configurations
TERMUX_DOWNLOAD_DIR = "/sdcard/Download"
COOKIE_FILE_PATH = os.path.join(TERMUX_DOWNLOAD_DIR, "cookie.txt")
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))

WORK_DIR = os.path.join(SCRIPT_DIR, "vibi_data")
os.makedirs(WORK_DIR, exist_ok=True)

SERVER_LINKS_FILE = os.path.join(WORK_DIR, "server-links.json")
CONFIG_FILE = os.path.join(WORK_DIR, "config.json")

# Executor workspace locations for heartbeat monitoring
EXECUTORS = {
    'Fluxus': '/storage/emulated/0/FluxusZ/',
    'Neutron': '/storage/emulated/0/Neutron/',
    'JJsploit': '/storage/emulated/0/JJsploit/',
    'Delta': '/storage/emulated/0/Delta/',
    'Codex': '/storage/emulated/0/Codex/',
    'Arceus X': '/storage/emulated/0/Arceus X/',
    'Cryptic': '/storage/emulated/0/Cryptic/',
    'KRNL': '/storage/emulated/0/PunkX/',
    'Trigon': '/storage/emulated/0/Trigon/',
    'FrostWare': '/storage/emulated/0/FrostWare/',
    'Evon': '/storage/emulated/0/Evon/'
}

WORKSPACE_PATHS = [os.path.join(path, "workspace") for path in EXECUTORS.values()] + \
                  [os.path.join(path, "Workspace") for path in EXECUTORS.values()]

class ConfigManager:
    @staticmethod
    def load_config():
        if os.path.exists(CONFIG_FILE):
            try:
                with open(CONFIG_FILE, "r", encoding="utf-8") as f:
                    return json.load(f)
            except Exception:
                pass
        return {"package_prefix": "com.roblox"}

    @staticmethod
    def save_config(config):
        with open(CONFIG_FILE, "w", encoding="utf-8") as f:
            json.dump(config, f, indent=4)

class SystemUtils:
    @staticmethod
    def run_root_cmd(cmd):
        """Execute terminal command with elevated root privileges"""
        try:
            res = subprocess.run(f"su -c '{cmd}'", shell=True, capture_output=True, text=True)
            return res.stdout.strip()
        except Exception as e:
            print(f"[!] Root command error: {e}")
            return ""

    @staticmethod
    def fix_permissions(package_name):
        """Fix app directory ownership so Roblox can access SQLite DBs"""
        uid = SystemUtils.run_root_cmd(f"stat -c '%u:%g' /data/data/{package_name}")
        if uid:
            SystemUtils.run_root_cmd(f"chown -R {uid} /data/data/{package_name}/files")
            SystemUtils.run_root_cmd(f"chown -R {uid} /data/data/{package_name}/app_webview")

class RobloxManager:
    @staticmethod
    def get_installed_packages(prefix=None):
        """Get all matching Roblox package clones installed on device"""
        if not prefix:
            config = ConfigManager.load_config()
            prefix = config.get("package_prefix", "com.roblox")

        packages = []
        out = SystemUtils.run_root_cmd(f"pm list packages {prefix}")
        for line in out.splitlines():
            line = line.strip().replace("package:", "")
            if line:
                packages.append(line)
        return packages if packages else ["com.roblox.client"]

    @staticmethod
    def kill_package(package_name):
        """Force stop specific package instance"""
        SystemUtils.run_root_cmd(f"am force-stop {package_name}")

    @staticmethod
    def launch_game(package_name, place_or_link):
        """Launch Roblox game instance via Intent"""
        RobloxManager.kill_package(package_name)
        time.sleep(1)

        if place_or_link.startswith("roblox://"):
            intent_url = place_or_link
        elif place_or_link.isdigit():
            intent_url = f"roblox://placeID={place_or_link}"
        else:
            intent_url = place_or_link

        print(f"[*] Launching {package_name} -> {intent_url}")
        
        # Primary protocol launch
        cmd = f"am start -a android.intent.action.VIEW -n '{package_name}/com.roblox.client.ActivityProtocolLaunch' -d '{intent_url}'"
        res = SystemUtils.run_root_cmd(cmd)

        if "Error" in res or not res:
            # Secondary fallback
            cmd_alt = f"am start -a android.intent.action.VIEW -d '{intent_url}' -p {package_name}"
            SystemUtils.run_root_cmd(cmd_alt)

class SessionInjector:
    @staticmethod
    def validate_cookie(cookie):
        """Check .ROBLOSECURITY validity via Roblox Users API"""
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
        except Exception as e:
            print(f"[!] Cookie validation network error: {e}")
        return None, None

    @staticmethod
    def inject_single_package(package_name, cookie):
        """Inject cookie & appStorage, then boot with monkey launcher to register session state"""
        user_id, username = SessionInjector.validate_cookie(cookie)
        if not user_id:
            print(f"[!] Cookie for {package_name} is invalid or expired.")
            return False

        print(f"[+] Authenticated: {username} (ID: {user_id}) for package: {package_name}")
        RobloxManager.kill_package(package_name)

        # Target paths
        target_appstorage_dir = f"/data/data/{package_name}/files/appData/LocalStorage"
        target_cookies_dir = f"/data/data/{package_name}/app_webview/Default"
        target_appstorage = f"{target_appstorage_dir}/appStorage.json"
        target_cookies_db = f"{target_cookies_dir}/Cookies"

        # 1. Temp appStorage.json
        app_data = {"UserId": str(user_id), "Username": str(username), "IsUnder13": "false"}
        temp_json = os.path.join(SCRIPT_DIR, "temp_appStorage.json")
        with open(temp_json, "w", encoding="utf-8") as f:
            json.dump(app_data, f)

        # 2. Temp Cookies.db
        temp_db = os.path.join(SCRIPT_DIR, "temp_Cookies.db")
        template_db = os.path.join(SCRIPT_DIR, "Cookies.db")

        if os.path.exists(template_db):
            subprocess.run(f"cp '{template_db}' '{temp_db}'", shell=True)
            try:
                conn = sqlite3.connect(temp_db)
                cursor = conn.cursor()
                cursor.execute("UPDATE cookies SET value=? WHERE host_key='.roblox.com' AND name='.ROBLOSECURITY'", (cookie,))
                conn.commit()
                conn.close()
            except Exception as e:
                print(f"[!] SQLite update error: {e}")

        # 3. Write data using Root
        SystemUtils.run_root_cmd(f"mkdir -p '{target_appstorage_dir}'")
        SystemUtils.run_root_cmd(f"mkdir -p '{target_cookies_dir}'")
        SystemUtils.run_root_cmd(f"cp '{temp_json}' '{target_appstorage}'")
        if os.path.exists(temp_db):
            SystemUtils.run_root_cmd(f"cp '{temp_db}' '{target_cookies_db}'")

        SystemUtils.run_root_cmd(f"chmod 666 '{target_appstorage}'")
        SystemUtils.run_root_cmd(f"chmod 666 '{target_cookies_db}'")
        SystemUtils.fix_permissions(package_name)

        # Cleanup temp files
        if os.path.exists(temp_json): os.remove(temp_json)
        if os.path.exists(temp_db): os.remove(temp_db)

        # 4. Critical Launch Step: Trigger launcher activity so Roblox registers and persists session
        print(f"[*] Booting {package_name} via Launcher activity to commit session state...")
        SystemUtils.run_root_cmd(f"monkey -p {package_name} -c android.intent.category.LAUNCHER 1")
        time.sleep(12)
        RobloxManager.kill_package(package_name)
        print(f"[+] Session registered successfully for {package_name}.")
        return True

    @staticmethod
    def handle_login():
        """Interactive cookie login handler with multi-package selection support"""
        if not os.path.exists(COOKIE_FILE_PATH):
            print(f"[!] Cookie file missing: {COOKIE_FILE_PATH}")
            return

        with open(COOKIE_FILE_PATH, "r", encoding="utf-8") as f:
            lines = [line.strip() for line in f if line.strip()]

        if not lines:
            print(f"[!] {COOKIE_FILE_PATH} is empty. Please add cookies.")
            return

        packages = RobloxManager.get_installed_packages()
        print(f"\n[*] Detected {len(packages)} target package(s):")
        for idx, pkg in enumerate(packages, 1):
            print(f"  [{idx}] {pkg}")

        if len(packages) > 1:
            print("\nSelect target package option:")
            print("  [0] Inject unique cookie to EACH package sequentially")
            print("  [1-N] Select specific package number")
            
            choice = input("Enter choice: ").strip()
            if choice == "0":
                for i, pkg in enumerate(packages):
                    if i < len(lines):
                        raw = lines[i]
                        cookie = raw.split(":")[2] + raw.split(":")[3] if ":" in raw and len(raw.split(":")) >= 3 else raw
                        SessionInjector.inject_single_package(pkg, cookie)
                    else:
                        print(f"[!] Not enough cookies in cookie.txt for package {pkg}. Skipping.")
            elif choice.isdigit() and 1 <= int(choice) <= len(packages):
                target_pkg = packages[int(choice) - 1]
                raw = lines[0]
                cookie = raw.split(":")[2] + raw.split(":")[3] if ":" in raw and len(raw.split(":")) >= 3 else raw
                SessionInjector.inject_single_package(target_pkg, cookie)
            else:
                print("[!] Invalid selection.")
        else:
            raw = lines[0]
            cookie = raw.split(":")[2] + raw.split(":")[3] if ":" in raw and len(raw.split(":")) >= 3 else raw
            SessionInjector.inject_single_package(packages[0], cookie)

class ExecutorHeartbeat:
    @staticmethod
    def setup_lua_script():
        """Writes executor check script that drops active user flag in workspace"""
        lua_code = 'task.spawn(function() local a=tostring(game.Players.LocalPlayer.UserId)..".main" while true do pcall(function() if not isfile(a) then writefile(a, "active") end end) task.wait(1) end end)'
        found = False
        for path in WORKSPACE_PATHS:
            if os.path.exists(path):
                autoexec_dir = os.path.join(os.path.dirname(path), "Autoexec")
                os.makedirs(autoexec_dir, exist_ok=True)
                with open(os.path.join(autoexec_dir, "vibi_check.lua"), "w") as f:
                    f.write(lua_code)
                found = True
        if found:
            print("[+] Executor heartbeat hook placed in Autoexec paths.")
        else:
            print("[*] No active executor workspaces found. Heartbeat step skipped.")

    @staticmethod
    def has_active_executors():
        """Check if any supported executor workspace exists"""
        return any(os.path.exists(path) for path in WORKSPACE_PATHS)

def main_menu():
    config = ConfigManager.load_config()
    current_prefix = config.get("package_prefix", "com.roblox")

    print("\n==================================")
    print("   VIBI REJOIN TOOL (V2 UPGRADED)  ")
    print(f"   Current Prefix: {current_prefix}")
    print("==================================")
    print("1. Start Auto Rejoin Loop")
    print("2. Login with Cookie (Package Selection)")
    print("3. Configure Package Prefix & Scan Packages")
    print("0. Exit")

    choice = input("\nSelect Option: ").strip()

    if choice == "1":
        place_id = input("Enter Place ID / Server Link: ").strip()
        if not place_id:
            return
        
        packages = RobloxManager.get_installed_packages()
        print(f"[*] Target package(s): {', '.join(packages)}")
        
        # Check executor presence; skip setup if none found
        if ExecutorHeartbeat.has_active_executors():
            print("[*] Executor environment detected. Initializing heartbeat hook...")
            ExecutorHeartbeat.setup_lua_script()
        else:
            print("[*] No executor detected. Proceeding directly with game launch...")

        # Main Rejoin Loop
        try:
            while True:
                for pkg in packages:
                    RobloxManager.launch_game(pkg, place_id)
                    time.sleep(15)
                
                print("[*] Instances running... Monitoring interval active.")
                time.sleep(60)
        except KeyboardInterrupt:
            print("\n[*] Auto Rejoin stopped.")

    elif choice == "2":
        SessionInjector.handle_login()

    elif choice == "3":
        new_prefix = input("Enter package prefix to scan (e.g. vip.tab or com.roblox): ").strip()
        if new_prefix:
            config["package_prefix"] = new_prefix
            ConfigManager.save_config(config)
            print(f"[+] Saved prefix: '{new_prefix}'")
            
            scanned = RobloxManager.get_installed_packages(new_prefix)
            print(f"[*] Scanned {len(scanned)} package(s) matching prefix:")
            for pkg in scanned:
                print(f"  - {pkg}")

    elif choice == "0":
        sys.exit(0)

if __name__ == "__main__":
    while True:
        main_menu()
