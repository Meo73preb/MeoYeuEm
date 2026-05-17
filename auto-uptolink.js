/**
 * Script: Uptolink Multi-Step Optimizer
 * File: auto-uptolink.js (Bản v12.0 - Tấn công hệ thống Class Countdown mới)
 */

(function() {
    'use strict';

    if (window.UptolinkV12Executed) return;

    // 1. GIẢ LẬP NGƯỜI THẬT (CLICK LỆCH PIXEL)
    const getRandomInt = (min, max) => Math.floor(Math.random() * (max - min + 1)) + min;

    const simulateHumanClick = (element) => {
        try {
            const rect = element.getBoundingClientRect();
            const clientX = (rect.left + rect.width / 2) + getRandomInt(-5, 5);
            const clientY = (rect.top + rect.height / 2) + getRandomInt(-5, 5);

            const pointerEvents = ['pointerdown', 'mousedown', 'pointerup', 'mouseup', 'click'];
            pointerEvents.forEach(eventType => {
                element.dispatchEvent(new MouseEvent(eventType, {
                    bubbles: true, cancelable: true, view: window,
                    clientX: clientX, clientY: clientY
                }));
            });
            console.log(`%c[Ghost v12] Click lệch tâm thành công vào thẻ countdown!`, "color: #00ff00");
        } catch (err) {
            console.error("[Ghost v12] Lỗi click:", err);
        }
    };

    // 2. BỘ NÃO ĐIỀU KHIỂN CHÍNH
    const monitorCountdownClass = () => {
        if (window.UptolinkV12Executed) return;

        const currentURL = window.location.href;

        // KIỂM TRA TRANG HƯỚNG DẪN (NÉ LỖI HẾT MÃ)
        if (currentURL.includes('linkhuongdan.online') && currentURL.includes('qq=notraffic')) {
            window.UptolinkV12Executed = true;
            clearInterval(classScanner);
            alert("🚨 HỆ THỐNG BÁO: UPTOLINK ĐÃ HẾT MÃ (No Traffic)!");
            return;
        }

        // TÌM THẺ COUNTDOWN THEO PHÁT HIỆN MỚI CỦA BẠN
        const targetSpan = document.querySelector('.countdown');
        if (!targetSpan) return;

        const spanText = targetSpan.innerText.toUpperCase().trim();
        
        // Đọc số giây đang chạy ngầm trong thẻ span (ví dụ: "VUI LÒNG ĐỢI 45S" hoặc "45")
        const matchSecond = spanText.match(/(\d+)/);

        if (matchSecond && (spanText.includes('S') || spanText.length <= 3)) {
            const seconds = parseInt(matchSecond[1], 10);
            console.log(`[Ghost v12] Thẻ .countdown đang nhảy giây: ${seconds}s`);
            return; // Giữ im lặng cho giây chạy xong mượt mà
        }

        // TRƯỜNG HỢP 1: Chờ click link nhiệm vụ để kích hoạt F5 (Áp dụng khi chữ bắt đầu đổi)
        if (spanText.includes("NHẤN LINK") || spanText.includes("CLICK LINK") || document.body.innerText.toUpperCase().includes("NHẤN LINK BẤT KỲ")) {
            console.log("[Ghost v12] Đang chờ bạn tương tác link quảng cáo để F5 sang Bước 2...");
            
            window.addEventListener('blur', () => {
                window.UptolinkV12Executed = true;
                clearInterval(classScanner);
                setTimeout(() => {
                    console.log("[Ghost v12] Tự động F5 để kích hoạt Bước tiếp theo...");
                    location.reload();
                }, 1200);
            }, { once: true });
            return;
        }

        // TRƯỜNG HỢP 2: NÚT ĐÃ SẴN SÀNG ĐỂ BẤM (NHẤN ĐỂ TIẾP TỤC, CLICK HERE, STEP 1, LẤY MÃ...)
        if (spanText.includes('NHẤN') || spanText.includes('TIẾP TỤC') || spanText.includes('STEP') || spanText.includes('BƯỚC') || spanText.includes('CLICK')) {
            window.UptolinkV12Executed = true;
            clearInterval(classScanner);

            // Phản xạ delay ngẫu nhiên cực chuẩn con người (1s - 2s)
            const randomDelay = getRandomInt(1000, 2000);
            console.log(`[Ghost v12] Đã bắt được chữ '${spanText}'. Sẽ tự động bấm sau ${randomDelay}ms...`);

            setTimeout(() => {
                simulateHumanClick(targetSpan);
                
                // Mở khóa lại sau 4 giây đề phòng hệ thống yêu cầu nhiều Step liên tiếp
                setTimeout(() => {
                    window.UptolinkV12Executed = false;
                    if (!window.location.href.includes('finish')) {
                        classScanner = setInterval(monitorCountdownClass, 1200);
                    }
                }, 4000);

            }, randomDelay);
        }
    };

    // Quét liên tục mỗi 1.2 giây để bám sát trạng thái thẻ span (.countdown)
    let classScanner = setInterval(monitorCountdownClass, 1200);

})();
