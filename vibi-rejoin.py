import os
import sys
import time
import json
import sqlite3
import subprocess
import requests
import gc
from threading import Lock, Event

# Path Configurations
TERMUX_DOWNLOAD_DIR = "/sdcard/Download"
COOKIE_FILE_PATH = os.path.join(TERMUX_DOWNLOAD_DIR, "cookie.txt")
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))

WORK_DIR = os.path.join(SCRIPT_DIR, "vibi_data")
os.makedirs(WORK_DIR, exist_ok=True)

SERVER_LINKS_FILE = os.path.join(WORK_DIR, "server-links.json")
ACCOUNTS_FILE = os.path.join(WORK_DIR, "accounts.json")
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
    def get_installed_packages(prefix="com.roblox"):
        """Get all matching Roblox package clones installed on device"""
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
    def kill_all_roblox(prefix="com.roblox"):
        """Force stop all running Roblox instances"""
        for pkg in RobloxManager.get_installed_packages(prefix):
            RobloxManager.kill_package(pkg)

    @staticmethod
    def launch_game(package_name, place_or_link):
        """Launch Roblox game instance via Intent"""
        RobloxManager.kill_package(package_name)
        time.sleep(1)

        # Process URI link or raw place ID
        if place_or_link.startswith("roblox://"):
            intent_url = place_or_link
        elif place_or_link.isdigit():
            intent_url = f"roblox://placeID={place_or_link}"
        else:
            intent_url = place_or_link

        print(f"[*] Launching {package_name} -> {intent_url}")
        
        # Method 1: Protocol Launch Activity
        cmd = f"am start -a android.intent.action.VIEW -n '{package_name}/com.roblox.client.ActivityProtocolLaunch' -d '{intent_url}'"
        res = SystemUtils.run_root_cmd(cmd)

        if "Error" in res or not res:
            # Fallback 2: General View Action
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
    def inject_all_packages():
        """Inject cookie & session data across all detected Roblox packages"""
        if not os.path.exists(COOKIE_FILE_PATH):
            print(f"[!] Missing cookie file: {COOKIE_FILE_PATH}")
            return

        with open(COOKIE_FILE_PATH, "r", encoding="utf-8") as f:
            raw_cookie = f.read().strip()

        if ":" in raw_cookie and len(raw_cookie.split(":")) >= 3:
            parts = raw_cookie.split(":")
            cookie = parts[2] + parts[3]
        else:
            cookie = raw_cookie

        user_id, username = SessionInjector.validate_cookie(cookie)
        if not user_id:
            print("[!] Cookie is invalid or expired.")
            return

        print(f"[+] Authenticated User: {username} (ID: {user_id})")
        packages = RobloxManager.get_installed_packages()

        for pkg in packages:
            print(f"[*] Injecting session into {pkg}...")
            RobloxManager.kill_package(pkg)

            # Paths
            target_appstorage_dir = f"/data/data/{pkg}/files/appData/LocalStorage"
            target_cookies_dir = f"/data/data/{pkg}/app_webview/Default"
            target_appstorage = f"{target_appstorage_dir}/appStorage.json"
            target_cookies_db = f"{target_cookies_dir}/Cookies"

            # Prepare temp appStorage.json
            app_data = {"UserId": str(user_id), "Username": str(username), "IsUnder13": "false"}
            temp_json = os.path.join(SCRIPT_DIR, "temp_appStorage.json")
            with open(temp_json, "w", encoding="utf-8") as f:
                json.dump(app_data, f)

            # Prepare temp Cookies.db
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
                    print(f"[!] SQLite Update error: {e}")

            # Push files via Root
            SystemUtils.run_root_cmd(f"mkdir -p '{target_appstorage_dir}'")
            SystemUtils.run_root_cmd(f"mkdir -p '{target_cookies_dir}'")
            SystemUtils.run_root_cmd(f"cp '{temp_json}' '{target_appstorage}'")
            if os.path.exists(temp_db):
                SystemUtils.run_root_cmd(f"cp '{temp_db}' '{target_cookies_db}'")

            SystemUtils.run_root_cmd(f"chmod 666 '{target_appstorage}'")
            SystemUtils.run_root_cmd(f"chmod 666 '{target_cookies_db}'")
            SystemUtils.fix_permissions(pkg)

            # Cleanup temp files
            if os.path.exists(temp_json): os.remove(temp_json)
            if os.path.exists(temp_db): os.remove(temp_db)

        print("[+] Session injection completed for all packages.")

class ExecutorHeartbeat:
    @staticmethod
    def setup_lua_script():
        """Writes executor check file that creates user heartbeat flag in workspace"""
        lua_code = 'task.spawn(function() local a=tostring(game.Players.LocalPlayer.UserId)..".main" while true do pcall(function() if not isfile(a) then writefile(a, "active") end end) task.wait(1) end end)'
        for path in WORKSPACE_PATHS:
            if os.path.exists(path):
                autoexec_dir = os.path.join(os.path.dirname(path), "Autoexec")
                os.makedirs(autoexec_dir, exist_ok=True)
                with open(os.path.join(autoexec_dir, "vibi_check.lua"), "w") as f:
                    f.write(lua_code)

    @staticmethod
    def is_executor_active(user_id):
        """Check if executor dropped the active user file flag"""
        filename = f"{user_id}.main"
        for ws in WORKSPACE_PATHS:
            if os.path.exists(os.path.join(ws, filename)):
                return True
        return False

    @staticmethod
    def clear_executor_flag(user_id):
        """Remove heartbeat flag on rejoin trigger"""
        filename = f"{user_id}.main"
        for ws in WORKSPACE_PATHS:
            filepath = os.path.join(ws, filename)
            if os.path.exists(filepath):
                try:
                    os.remove(filepath)
                except Exception:
                    pass

def main_menu():
    print("\n==================================")
    print("   VIBI REJOIN TOOL (V2 UPGRADED)  ")
    print("==================================")
    print("1. Start Auto Rejoin Loop")
    print("2. Multi-Package Session Login (cookie.txt)")
    print("3. Install Executor Heartbeat Hook")
    print("0. Exit")

    choice = input("\nSelect Option: ").strip()

    if choice == "1":
        place_id = input("Enter Place ID / Server Link: ").strip()
        if not place_id:
            return
        
        packages = RobloxManager.get_installed_packages()
        print(f"[*] Found {len(packages)} Roblox package(s): {', '.join(packages)}")
        
        # Main Rejoin Loop
        try:
            while True:
                for pkg in packages:
                    RobloxManager.launch_game(pkg, place_id)
                    time.sleep(15)
                
                print("[*] Monitoring instances... Sleeping 60s")
                time.sleep(60)
        except KeyboardInterrupt:
            print("\n[*] Auto Rejoin stopped.")

    elif choice == "2":
        SessionInjector.inject_all_packages()

    elif choice == "3":
        ExecutorHeartbeat.setup_lua_script()
        print("[+] Executor auto-check hook written to workspace/Autoexec paths.")

    elif choice == "0":
        sys.exit(0)

if __name__ == "__main__":
    while True:
        main_menu()