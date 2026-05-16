/**
 * Script: Uptolink Ghost Bypass - Premium Stealth & Traffic Detector
 * File: auto-uptolink.js (Bản v1.4 - Nhận diện hết mã NoTraffic & Chống spam)
 */

(function() {
    'use strict';

    // 1. KIỂM TRA LINK "NO TRAFFIC" (HẾT MÃ) TRƯỚC TIÊN
    const currentURL = window.location.href;
    
    // Check xem URL có chứa cả "linkhuongdan.online" và "qq=notraffic" hay không
    if (currentURL.includes('linkhuongdan.online') && currentURL.includes('qq=notraffic')) {
        console.log("%c[Ghost Detector] Phát hiện hệ thống Uptolink đã HẾT MÃ (No Traffic)!", "color: #ff3333; font-size: 16px; font-weight: bold;");
        
        // Tạo một thông báo GUI khẩn cấp đè lên màn hình để bạn dễ thấy
        const alertBox = document.createElement('div');
        alertBox.style.cssText = `
            position: fixed; top: 0; left: 0; width: 100vw; height: 100vh;
            background: rgba(15, 15, 18, 0.95); display: flex; flex-direction: column;
            justify-content: center; align-items: center; z-index: 999999;
            font-family: 'Segoe UI', Roboto, sans-serif; color: #ffffff;
        `;
        
        alertBox.innerHTML = `
            <div style="background: rgba(255, 51, 51, 0.1); border: 2px solid #ff3333; padding: 30px; border-radius: 16px; text-align: center; box-shadow: 0 0 30px rgba(255, 51, 51, 0.3);">
                <h1 style="margin: 0 0 10px 0; color: #ff3333; font-size: 24px; letter-spacing: 1px;">UPTOLINK HẾT MÃ</h1>
                <p style="margin: 0; color: #cccccc; font-size: 15px;">Chiến dịch này đã cạn traffic (qq=notraffic).<br>Vui lòng đóng tab và đổi camp mới!</p>
            </div>
        `;
        document.documentElement.appendChild(alertBox);
        return; // Dừng chạy toàn bộ đoạn code phía dưới
    }

    // Nếu không dính lỗi hết mã, hệ thống ẩn thân v9.0 cũ sẽ tiếp tục kích hoạt ngầm bình thường
    if (window.UptolinkPureStealthExecuted) return;

    // GIẢ LẬP NGƯỜI THẬT (CLICK LỆCH TÂM NGẪU NHIÊN)
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
            console.log(`[Ghost] Click thành công tại tọa độ lệch: X=${clientX.toFixed(1)}, Y=${clientY.toFixed(1)}`);
        } catch (err) {
            console.error("[Ghost] Lỗi click:", err);
        }
    };

    // LOGIC THEO DÕI NGẦM
    const monitorStepsSilently = () => {
        if (window.UptolinkPureStealthExecuted) return;

        const targetBtn = document.getElementById('countdownBtn');
        if (!targetBtn) return;

        const btnText = targetBtn.innerText.toUpperCase();
        const matchSecond = btnText.match(/(\d+)\s*S/);
        
        if (matchSecond) {
            return; // Đang đếm giây thì giữ im lặng
        }

        // TRƯỜNG HỢP 1: Chờ click link để F5
        if (btnText.includes("NHẤN LINK") || btnText.includes("CLICK LINK") || document.body.innerText.toUpperCase().includes("NHẤN LINK BẤT KỲ")) {
            window.addEventListener('blur', () => {
                window.UptolinkPureStealthExecuted = true;
                clearInterval(pageScanner);
                setTimeout(() => {
                    location.reload();
                }, 1500);
            }, { once: true });
            return;
        }

        // TRƯỜNG HỢP 2: NÚT SẴN SÀNG ĐỂ BẤM
        if (btnText.includes('STEP') || btnText.includes('BƯỚC') || btnText.includes('LẤY MÃ') || btnText.includes('CLICK')) {
            window.UptolinkPureStealthExecuted = true;
            clearInterval(pageScanner);

            const randomDelay = getRandomInt(1200, 2200);
            console.log(`[Ghost] Nút sẵn sàng, bấm sau ${randomDelay}ms...`);

            setTimeout(() => {
                simulateHumanClick(targetBtn);
                
                setTimeout(() => {
                    window.UptolinkPureStealthExecuted = false;
                    if (!window.location.href.includes('finish')) {
                        pageScanner = setInterval(monitorStepsSilently, 1500);
                    }
                }, 4000);

            }, randomDelay);
        }
    };

    try {
        window.open = () => null;
        console.clear = () => {};
    } catch(e) {}

    let pageScanner = setInterval(monitorStepsSilently, 1500);

})();
