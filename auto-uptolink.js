/**
 * Script: Uptolink Ghost Session Keeper
 * File: auto-uptolink.js (Bản v1.9 - Chống đóng băng tab & Né bẫy 404 Timeout)
 */

(function() {
    'use strict';

    if (window.UptolinkV14_2Executed) return;

    // Lưu mốc thời gian lúc bắt đầu nạp trang
    const pageLoadTime = Date.now();

    // 1. GIẢ LẬP NGƯỜI THẬT CLICK LỆCH TÂM
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
        } catch (err) {}
    };

    // 2. CHỐNG ĐÓNG BĂNG TAB KHI OUT NỀN (KEEP-ALIVE)
    // Đè lên cơ chế check ẩn tab của tụi nó, luôn báo cáo là người dùng đang nhìn vào màn hình
    Object.defineProperty(document, 'visibilityState', { get: () => 'visible', configurable: true });
    Object.defineProperty(document, 'hidden', { get: () => false, configurable: true });

    const masterDriver = () => {
        if (window.UptolinkV14_2Executed) return;

        const currentURL = window.location.href;

        // KIỂM TRA BẪY TIMEOUT (Nếu ngâm tab quá 3 phút, tự F5 nạp lại Token mới cho an toàn)
        if (Date.now() - pageLoadTime > 180000) {
            window.UptolinkV14_2Executed = true;
            clearInterval(engineScanner);
            console.log("[Ghost v14.2] Tab ngâm quá lâu, tự động F5 để tránh bẫy 404...");
            location.reload();
            return;
        }

        // TRANG HƯỚNG DẪN (TỰ BỐC TỪ KHÓA)
        if (currentURL.includes('linkhuongdan.online')) {
            if (currentURL.includes('qq=notraffic')) {
                window.UptolinkV14_2Executed = true;
                clearInterval(engineScanner);
                alert("🚨 HỆ THỐNG BÁO: UPTOLINK ĐÃ HẾT MÃ (No Traffic)!");
                return;
            }

            if (currentURL.includes('qq=complete') && !window.HasAlertedQuest) {
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
                    alert(`🎯 TỪ KHÓA NHIỆM VỤ: ${keyword}\n-> Hãy vào web của từ khóa này để lấy mã!`);
                }
                return;
            }
        }

        // TRANG ĐÍCH NHIỆM VỤ (.countdown bọc trong #countdownBtn)
        const targetSpan = document.querySelector('.countdown');
        const targetBtn = document.getElementById('countdownBtn');
        
        if (!targetSpan || !targetBtn) return;

        const spanText = targetSpan.innerText.toUpperCase().trim();
        
        // Đang đếm giây hoặc đang loading thì bỏ qua
        const matchSecond = spanText.match(/(\d+)/);
        if (matchSecond && (spanText.includes('S') || spanText.length <= 3 || targetBtn.className.includes('loading'))) {
            return;
        }

        // Chờ click link quảng cáo để F5
        if (spanText.includes("NHẤN LINK") || spanText.includes("CLICK LINK") || document.body.innerText.toUpperCase().includes("NHẤN LINK BẤT KỲ")) {
            window.addEventListener('blur', () => {
                window.UptolinkV14_2Executed = true;
                clearInterval(engineScanner);
                setTimeout(() => { location.reload(); }, 1200);
            }, { once: true });
            return;
        }

        // NÚT SẴN SÀNG CLICK
        if (spanText.includes('LẤY MÃ') || spanText.includes('STEP') || spanText.includes('BƯỚC') || spanText.includes('NHẤN') || spanText.includes('TIẾP TỤC')) {
            window.UptolinkV14_2Executed = true;
            clearInterval(engineScanner);

            const randomDelay = getRandomInt(1200, 2000);
            console.log(`%c[✓] Click bọc sườn kích hoạt sau ${randomDelay}ms...`, "color: #00ff00");

            setTimeout(() => {
                simulateHumanClick(targetSpan);
                setTimeout(() => {
                    simulateHumanClick(targetBtn);
                }, 50);
                
                setTimeout(() => {
                    window.UptolinkV14_2Executed = false;
                    if (!window.location.href.includes('finish')) {
                        engineScanner = setInterval(masterDriver, 1200);
                    }
                }, 4000);

            }, randomDelay);
        }
    };

    let engineScanner = setInterval(masterDriver, 1200);

})();
