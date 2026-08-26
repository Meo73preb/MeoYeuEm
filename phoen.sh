# 1. Làm sạch môi trường và gỡ bỏ hoàn toàn mọi rác mạng/Docker cũ
pkill cloudflared
pkill socat
docker rm -f $(docker ps -a -q) 2>/dev/null
echo "{}" > /etc/docker/daemon.json

# 2. Cập nhật hệ thống và cài đặt Docker bản chính thức
apt update && apt install -y curl wget git apt-transport-https ca-certificates gnupg lsb-release screen socat
curl -fsSL https://get.docker.com -o get-docker.sh && sh get-docker.sh

# 3. Vá lỗi ulimit hệ thống để khởi động Docker Daemon thành công trên Container
sed -i 's/ulimit -Hn/# ulimit -Hn/g' /etc/init.d/docker
sed -i 's/ulimit -Sn/# ulimit -Sn/g' /etc/init.d/docker

# 4. Kích nổ chạy ngầm Dockerd độc lập không qua systemctl lỗi
pkill dockerd
sleep 1
dockerd --iptables=false --ip6tables=false > /var/log/docker.log 2>&1 &
sleep 3

# 5. Khởi chạy Android ReDroid 11 Web siêu nhẹ (Tận dụng 2 vCPU, 5GB RAM, ăn chưa tới 1.5GB đĩa)
docker run -d \
  --name=roblox-android \
  --privileged \
  --memory="5000m" \
  --cpus="2.0" \
  -p 8080:8080 \
  --restart=always \
  remote-android/redroid-web:11.0.0-latest \
  androidboot.hardware=redroid \
  redroid.width=800 \
  redroid.height=600 \
  redroid.fps=15 \
  redroid.gpu.mode=guest

# 6. Cài đặt và cấu hình Cloudflare Tunnel ghim thẳng vào cổng web 8080
curl -L --output cloudflared.deb https://github.com
dpkg -i cloudflared.deb
screen -dmS cftunnel cloudflared tunnel --url http://127.0.0.1:8080

# 7. Đợi 5 giây để đường truyền từ máy chủ ổn định hẳn
sleep 5

# 8. Xuất đường link truy cập sạch sẽ duy nhất lên màn hình
echo "=========================================================="
echo "ĐƯỜNG LINK TRUY CẬP GIẢ LẬP ANDROID ROBLOX CỦA BẠN:"
echo "=========================================================="
curl -s http://127.0.0 | grep -oE "https://[a-zA-Z0-9.-]+\.trycloudflare\.com" | uniq
