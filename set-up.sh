#!/data/data/com.termux/files/usr/bin/bash

# ==========================================
# AUTO SETUP ENVIRONMENT FOR TERMUX (ROOT)
# ==========================================

echo -e "\033[1;32m[*] Bắt đầu quá trình thiết lập tự động từ A-Z...\033[0m"

# 1. Tự động chuyển đổi phản hồi sang 'Yes' mặc định cho apt/pkg
export DEBIAN_FRONTEND=noninteractive

# 2. Cấp quyền truy cập bộ nhớ SDCard
echo -e "\033[1;34m[*] Yêu cầu quyền truy cập bộ nhớ internal storage...\033[0m"
termux-setup-storage

# 3. Cập nhật hệ thống và cài đặt các gói bắt buộc
echo -e "\033[1;34m[*] Đang cập nhật hệ thống và cài đặt các gói cần thiết...\033[0m"
pkg update -y -o Dpkg::Options::="--force-confold"
pkg upgrade -y -o Dpkg::Options::="--force-confold"

echo -e "\033[1;34m[*] Đang cài đặt python, sqlite, tsu, git, curl, wget...\033[0m"
pkg install python sqlite tsu git curl wget -y

# Cài đặt thư viện Python
echo -e "\033[1;34m[*] Đang cài đặt các thư viện Python...\033[0m"
pip install --upgrade pip
pip install requests

# 4. Tạo thư mục chứa Tool
TARGET_DIR="$HOME/vibi-tool"
echo -e "\033[1;34m[*] Tạo thư mục làm việc tại: $TARGET_DIR\033[0m"
mkdir -p "$TARGET_DIR"
cd "$TARGET_DIR" || exit 1

# 5. Tải file vibi-rejoin.py từ Github (sử dụng link raw)
RAW_GITHUB_URL="https://raw.githubusercontent.com/Meo73preb/MeoYeuEm/main/vibi-rejoin.py"
echo -e "\033[1;34m[*] Đang tải vibi-rejoin.py từ GitHub...\033[0m"
curl -s -L "$RAW_GITHUB_URL" -o vibi-rejoin.py

# Check xem file tải về có thành công không
if [ ! -s vibi-rejoin.py ]; then
    echo -e "\033[1;31m[!] Tải file thất bại hoặc file rỗng! Vui lòng kiểm tra lại link GitHub.\033[0m"
fi

# 6. Tự động tạo file mẫu appStorage.json nếu chưa tồn tại
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

# 7. Tự động tạo file SQLite Cookies.db nếu chưa tồn tại
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

# 8. Khởi tạo file cookie.txt ở bộ nhớ ngoài (/sdcard/Download)
DOWNLOAD_DIR="/sdcard/Download"
mkdir -p "$DOWNLOAD_DIR"
if [ ! -f "$DOWNLOAD_DIR/cookie.txt" ]; then
    touch "$DOWNLOAD_DIR/cookie.txt"
    echo -e "\033[1;34m[*] Đã tạo file rỗng tại: $DOWNLOAD_DIR/cookie.txt\033[0m"
fi

echo -e "\033[1;32m==================================================\033[0m"
echo -e "\033[1;32m[✓] HOÀN TẤT CÀI ĐẶT TỰ ĐỘNG A-Z!\033[0m"
echo -e "\033[1;33mĐể bắt đầu sử dụng, hãy nhập các lệnh sau:\033[0m"
echo -e "\033[1;36m  cd ~/vibi-tool && su -c 'python vibi-rejoin.py'\033[0m"
echo -e "\033[1;32m==================================================\033[0m"
