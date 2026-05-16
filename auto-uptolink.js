/**
 * Script: Uptolink Ghost Bypass - Pure Stealth
 * File: auto-uptolink.js (Bản v1.3 - Chạy ngầm hoàn toàn, chống Cloudflare quét 520)
 */

(function() {
    'use strict';

    if (window.UptolinkPureStealthExecuted) return;

    // 1. GIẢ LẬP NGƯỜI THẬT (CLICK LỆCH TÂM NGẪU NHIÊN)
    const getRandomInt = (min, max) => Math.floor(Math.random() * (max - min + 1)) + min;

    const simulateHumanClick = (element) => {
        try {
            const rect = element.getBoundingClientRect();
            const clientX = (rect.left + rect.width / 2) + getRandomInt(-6, 6);
            const clientY = (rect.top + rect.height / 2) + getRandomInt(-6, 6);

            const pointerEvents = ['pointerdown', 'mousedown', 'pointerup', 'mouseup', 'click'];
            pointerEvents.forEach(eventType => {
                element.dispatchEvent(new MouseEvent(eventType, {
                    bubbles: true, cancelable: true, view: window,
                    clientX: clientX, clientY: clientY
                }));
            });
            console.log(`%c[Ghost] Click thành công tại tọa độ lệch: X=${clientX.toFixed(1)}, Y=${clientY.toFixed(1)}`, "color: #00ff00");
        } catch (err) {
            console.error("[Ghost] Lỗi click:", err);
        }
    };

    // 2. LOGIC THEO DÕI NGẦM (KHÔNG ĐỤNG VÀO UI)
    const monitorStepsSilently = () => {
        if (window.UptolinkPureStealthExecuted) return;

        const targetBtn = document.getElementById('countdownBtn');
        if (!targetBtn) return;

        const btnText = targetBtn.innerText.toUpperCase();
        
        // Đọc số giây đang chạy trên nút
        const matchSecond = btnText.match(/(\d+)\s*S/);
        
        if (matchSecond) {
            const seconds = parseInt(matchSecond[1], 10);
            console.log(`[Ghost] Hệ thống đang đếm ngược ngầm: ${seconds}s`);
            return; // Đang đếm giây thì im lặng để yên cho web chạy
        }

        // TRƯỜNG HỢP 1: Xuất hiện yêu cầu bắt nhấn link quảng cáo mới F5
        if (btnText.includes("NHẤN LINK") || btnText.includes("CLICK LINK") || document.body.innerText.toUpperCase().includes("NHẤN LINK BẤT KỲ")) {
            console.log("%c[Ghost] Phát hiện trạng thái chờ click link để F5!", "color: #ffaa00");
            
            // Lắng nghe tương tác của bạn, khi bạn bấm vào bất kỳ đâu trên màn hình (thường là bấm quảng cáo)
            // Trang web sẽ tự động F5 sau 1.5 giây để kích hoạt Bước 2
            window.addEventListener('blur', () => {
                window.UptolinkPureStealthExecuted = true;
                clearInterval(pageScanner);
                setTimeout(() => {
                    console.log("[Ghost] Tự động F5 sang Bước 2...");
                    location.reload();
                }, 1500);
            }, { once: true });
            return;
        }

        // TRƯỜNG HỢP 2: NÚT SẴN SÀNG ĐỂ BẤM (STEP 1, STEP 2, BƯỚC 1, BƯỚC 2, LẤY MÃ...)
        if (btnText.includes('STEP') || btnText.includes('BƯỚC') || btnText.includes('LẤY MÃ') || btnText.includes('CLICK')) {
            window.UptolinkPureStealthExecuted = true;
            clearInterval(pageScanner);

            // Tạo độ trễ ngẫu nhiên mô phỏng phản xạ của con người (1.2s - 2.2s)
            const randomDelay = getRandomInt(1200, 2200);
            console.log(`%c[Ghost] Nút đã sẵn sàng. Sẽ bấm sau ${randomDelay}ms...`, "color: #00ffff");

            setTimeout(() => {
                simulateHumanClick(targetBtn);
                
                // Mở khóa lại sau 4 giây đề phòng web phản hồi chậm
                setTimeout(() => {
                    window.UptolinkPureStealthExecuted = false;
                    if (!window.location.href.includes('finish')) {
                        pageScanner = setInterval(monitorStepsSilently, 1500);
                    }
                }, 4000);

            }, randomDelay);
        }
    };

    // Khóa các hàm phát hiện debug của hệ thống quảng cáo
    try {
        window.open = () => null;
        console.clear = () => {};
    } catch(e) {}

    // Quét thưa an toàn (1.5 giây/lần) không tốn tài nguyên, không bị tính là spam requests
    let pageScanner = setInterval(monitorStepsSilently, 1500);

})();
