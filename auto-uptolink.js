/**
 * Script: Uptolink Ghost Dynamic Target
 * File: auto-uptolink.js (Bản v1.8 - Click bọc hai tầng, Tự bốc từ khóa Quest)
 */

(function() {
    'use strict';

    if (window.UptolinkV14Executed) return;

    // 1. GIẢ LẬP NGƯỜI THẬT (CLICK LỆCH TÂM NGẪU NHIÊN)
    const getRandomInt = (min, max) => Math.floor(Math.random() * (max - min + 1)) + min;

    const simulateHumanClick = (element) => {
        try {
            const rect = element.getBoundingClientRect();
            const clientX = (rect.left + rect.width / 2) + getRandomInt(-4, 4);
            const clientY = (rect.top + rect.height / 2) + getRandomInt(-4, 4);

            const pointerEvents = ['pointerdown', 'mousedown', 'pointerup', 'mouseup', 'click'];
            pointerEvents.forEach(eventType => {
                element.dispatchEvent(new MouseEvent(eventType, {
                    bubbles: true, cancelable: true, view: window,
                    clientX: clientX, clientY: clientY
                }));
            });
        } catch (err) {
            console.error("[Ghost v14] Lỗi click phần tử:", err);
        }
    };

    // 2. CORE LOGIC ĐIỀU KHIỂN
    const masterDriver = () => {
        if (window.UptolinkV14Executed) return;

        const currentURL = window.location.href;

        // ================= BƯỚC A: XỬ LÝ TRÊN TRANG HƯỚNG DẪN =================
        if (currentURL.includes('linkhuongdan.online')) {
            if (currentURL.includes('qq=notraffic')) {
                window.UptolinkV14Executed = true;
                clearInterval(engineScanner);
                alert("🚨 HỆ THỐNG BÁO: UPTOLINK ĐÃ HẾT MÃ (No Traffic)!");
                return;
            }

            if (currentURL.includes('qq=complete') && !window.HasAlertedQuest) {
                // Quét tìm chính xác thẻ màu đỏ chứa từ khóa lấy mã (như chữ UY88 trong ảnh)
                const redElements = document.querySelectorAll('[style*="color: red"], [style*="color: #ff0000"], [style*="color:#ff0000"]');
                let keyword = "";
                for (let elem of redElements) {
                    const text = elem.innerText.trim();
                    if (text && text.length < 15) {
                        keyword = text;
                        break;
                    }
                }
                if (keyword) {
                    window.HasAlertedQuest = true;
                    console.log(`%c[Ghost v14] Đã bắt được từ khóa: ${keyword}`, "color: #00ffff");
                    alert(`🎯 TỪ KHÓA NHIỆM VỤ: ${keyword}\n-> Hãy vào web của từ khóa này để lấy mã!`);
                }
                return;
            }
        }

        // ================= BƯỚC B: XỬ LÝ TRÊN TRANG ĐÍCH NHIỆM VỤ =================
        const targetSpan = document.querySelector('.countdown');
        const targetBtn = document.getElementById('countdownBtn');
        
        // Nếu không có nút lấy mã thì bỏ qua
        if (!targetSpan || !targetBtn) return;

        const spanText = targetSpan.innerText.toUpperCase().trim();
        
        // Kiểm tra xem nút có đang ở trạng thái đếm giây hay không
        const matchSecond = spanText.match(/(\d+)/);
        if (matchSecond && (spanText.includes('S') || spanText.length <= 3 || targetBtn.className.includes('loading'))) {
            console.log(`[Ghost v14] Hệ thống đang đếm giây ngầm hoặc đang loading: ${spanText}`);
            return; // Đứng im chờ đợi dữ liệu nạp xong
        }

        // TRƯỜNG HỢP 1: Chờ click link quảng cáo để F5 (Khi hết giây dài)
        if (spanText.includes("NHẤN LINK") || spanText.includes("CLICK LINK") || document.body.innerText.toUpperCase().includes("NHẤN LINK BẤT KỲ")) {
            console.log("[Ghost v14] Phát hiện trạng thái chờ tương tác để F5...");
            window.addEventListener('blur', () => {
                window.UptolinkV14Executed = true;
                clearInterval(engineScanner);
                setTimeout(() => {
                    location.reload();
                }, 1200);
            }, { once: true });
            return;
        }

        // TRƯỜNG HỢP 2: NÚT SẴN SÀNG (LẤY MÃ STEP 1, NHẤN ĐỂ TIẾP TỤC...)
        if (spanText.includes('LẤY MÃ') || spanText.includes('STEP') || spanText.includes('BƯỚC') || spanText.includes('NHẤN') || spanText.includes('TIẾP TỤC')) {
            window.UptolinkV14Executed = true;
            clearInterval(engineScanner);

            const randomDelay = getRandomInt(1200, 2000);
            console.log(`%c[✓] NHẮM TRÚNG MỤC TIÊU: "${spanText}". Kích nổ sau ${randomDelay}ms...`, "color: #00ff00");

            setTimeout(() => {
                // TẤN CÔNG ĐA TẦNG: Click cả thẻ cha lẫn thẻ con để không thể thoát được sự kiện
                simulateHumanClick(targetSpan);
                setTimeout(() => {
                    simulateHumanClick(targetBtn);
                    console.log("[Ghost v14] Đã nạp thành công cú click bọc sườn!");
                }, 50);
                
                // Mở khóa lại sau 4 giây phòng trường hợp nhiều Step liên tục
                setTimeout(() => {
                    window.UptolinkV14Executed = false;
                    if (!window.location.href.includes('finish')) {
                        engineScanner = setInterval(masterDriver, 1200);
                    }
                }, 4000);

            }, randomDelay);
        }
    };

    // Khởi chạy bộ quét kiểm soát trận địa
    let engineScanner = setInterval(masterDriver, 1200);

})();
