#!/data/data/com.termux/files/usr/bin/bash

echo -e "\033[1;32m[*] Bắt đầu quá trình thiết lập tự động từ A-Z...\033[0m"
export DEBIAN_FRONTEND=noninteractive

echo -e "\033[1;34m[*] Yêu cầu quyền truy cập bộ nhớ internal storage...\033[0m"
termux-setup-storage

echo -e "\033[1;34m[*] Đang cập nhật hệ thống và cài đặt các gói cần thiết...\033[0m"
pkg update -y -o Dpkg::Options::="--force-confold"
pkg upgrade -y -o Dpkg::Options::="--force-confold"

echo -e "\033[1;34m[*] Đang cài đặt python, sqlite, tsu, git, curl, wget...\033[0m"
pkg install python sqlite tsu git curl wget -y

echo -e "\033[1;34m[*] Đang cài đặt và cập nhật các thư viện Python (requests, websocket-client)...\033[0m"
pip install --upgrade pip
pip install requests websocket-client

TARGET_DIR="$HOME/vibi-tool"
echo -e "\033[1;34m[*] Tạo thư mục làm việc tại: $TARGET_DIR\033[0m"
mkdir -p "$TARGET_DIR"
cd "$TARGET_DIR" || exit 1

RAW_GITHUB_URL="https://raw.githubusercontent.com/Meo73preb/MeoYeuEm/main/vibi-rejoin.py"
echo -e "\033[1;34m[*] Đang tải vibi-rejoin.py...\033[0m"
curl -s -L "$RAW_GITHUB_URL" -o vibi-rejoin.py

if [ ! -s vibi-rejoin.py ]; then
    echo -e "\033[1;31m[!] Tải file thất bại hoặc file rỗng! Vui lòng kiểm tra lại link GitHub.\033[0m"
fi

if [ ! -f "appStorage.json" ]; then
    echo -e "\033[1;34m[*] Đang khởi tạo file mẫu appStorage.json...\033[0m"
    cat << 'EOF' > appStorage.json
{
"UserId": "",
"Username": "",
"IsUnder13": "false"
}
EOF
fi

# Tạo file SQLite Cookies.db nếu chưa tồn tại [Quan Trọng!]
if [ ! -f "Cookies.db" ]; then
    echo -e "\033[1;34m[*] Đang tạo cơ sở dữ liệu Cookies.db mẫu...\033[0m"
    sqlite3 Cookies.db << 'EOF'
CREATE TABLE cookies (
creation_utc INTEGER NOT NULL,
host_key TEXT NOT NULL,
top_frame_site_key TEXT NOT NULL,
name TEXT NOT NULL,
value TEXT NOT NULL,
encrypted_value BLOB NOT NULL,
comment TEXT NOT NULL,
path TEXT NOT NULL,
expires_utc INTEGER NOT NULL,
is_secure INTEGER NOT NULL,
is_httponly INTEGER NOT NULL,
last_access_utc INTEGER NOT NULL,
has_expires INTEGER NOT NULL,
is_persistent INTEGER NOT NULL,
priority INTEGER NOT NULL,
samesite INTEGER NOT NULL,
source_scheme INTEGER NOT NULL,
source_port INTEGER NOT NULL,
is_same_party INTEGER NOT NULL,
last_update_utc INTEGER NOT NULL
);
INSERT INTO cookies VALUES(
13300000000000000,
'.roblox.com',
'',
'.ROBLOSECURITY',
'',
'',
'',
'/',
17000000000000000,
1,
1,
13300000000000000,
1,
1,
1,
-1,
2,
443,
0,
13300000000000000
);
EOF
fi

DOWNLOAD_DIR="/sdcard/Download"
mkdir -p "$DOWNLOAD_DIR"
if [ ! -f "$DOWNLOAD_DIR/cookie.txt" ]; then
    touch "$DOWNLOAD_DIR/cookie.txt"
    echo -e "\033[1;34m[*] Đã tạo file rỗng tại: $DOWNLOAD_DIR/cookie.txt\033[0m"
fi

if [ ! -f "$DOWNLOAD_DIR/discord_token.txt" ]; then
    touch "$DOWNLOAD_DIR/discord_token.txt"
    echo -e "\033[1;34m[*] Đã tạo file rỗng tại: $DOWNLOAD_DIR/discord_token.txt\033[0m"
fi

echo -e "\033[1;32m[✓] HOÀN TẤT CÀI ĐẶT TỰ ĐỘNG A-Z!\033[0m"
echo -e "\033[1;33mBây giờ bạn chỉ cần chạy lệnh sau để dùng tool:\033[0m"
echo -e "\033[1;36m  cd ~/vibi-tool && python vibi-rejoin.py\033[0m"