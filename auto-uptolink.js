/**
 * Script: Uptolink Advanced Class Deep Scanner
 * File: auto-uptolink.js (Bản v1.7 - Khắc phục triệt để lỗi không nhận class countdown)
 */

(function() {
    'use strict';

    if (window.UptolinkV13Executed) return;

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
            console.log(`%c[Ghost v13] Đã kích nổ cú click vào mục tiêu!`, "color: #00ff00");
        } catch (err) {
            console.error("[Ghost v13] Lỗi click:", err);
        }
    };

    // 2. CORE LOGIC PHÂN TÍCH CHỮ TRÊN THẺ
    const checkAndAct = (targetElement) => {
        if (window.UptolinkV13Executed) return;

        const text = targetElement.innerText.toUpperCase().trim();
        if (!text) return;

        console.log(`[Ghost v13] Đang phân tích text: "${text}"`);

        // TRƯỜNG HỢP 1: Đang đếm ngược giây (Ví dụ có số và chữ S, hoặc chỉ có số ngắn)
        const matchSecond = text.match(/(\d+)/);
        if (matchSecond && (text.includes('S') || text.length <= 3)) {
            console.log(`[Ghost v13] Trạng thái: Đang đếm giây (${matchSecond[1]}s) -> Bỏ qua chờ đợi.`);
            return;
        }

        // TRƯỜNG HỢP 2: Chờ click link quảng cáo để F5 (Nếu có chữ yêu cầu trên màn hình)
        if (text.includes("NHẤN LINK") || text.includes("CLICK LINK") || document.body.innerText.toUpperCase().includes("NHẤN LINK BẤT KỲ")) {
            window.addEventListener('blur', () => {
                window.UptolinkV13Executed = true;
                setTimeout(() => {
                    location.reload();
                }, 1200);
            }, { once: true });
            return;
        }

        // TRƯỜNG HỢP 3: NÚT ĐÃ SẴN SÀNG (LẤY MÃ STEP 1, NHẤN ĐỂ TIẾP TỤC, CLICK HERE...)
        if (text.includes('LẤY MÃ') || text.includes('STEP') || text.includes('BƯỚC') || text.includes('NHẤN') || text.includes('TIẾP TỤC')) {
            window.UptolinkV13Executed = true;

            const randomDelay = getRandomInt(1200, 2200);
            console.log(`%c[✓] BẮT ĐƯỢC MỤC TIÊU SẴN SÀNG! Sẽ bấm sau ${randomDelay}ms...`, "color: #00ffff");

            setTimeout(() => {
                simulateHumanClick(targetElement);
                
                // Mở khóa lại sau 4 giây để quét tiếp các step sau
                setTimeout(() => {
                    window.UptolinkV13Executed = false;
                }, 4000);
            }, randomDelay);
        }
    };

    // 3. BỘ GIÁM SÁT ĐỘNG (MUTATION OBSERVER) - CHỐNG TRỄ DOM
    const startObserver = () => {
        // Quét nhanh lần đầu tiên ngay khi script chạy
        const initialElements = document.querySelectorAll('.countdown');
        initialElements.forEach(el => checkAndAct(el));

        // Cấu hình bộ giám sát sự thay đổi của trang web
        const observer = new MutationObserver((mutations) => {
            if (window.UptolinkV13Executed) return;

            // Tìm lại tất cả các phần tử có class countdown khi trang web thay đổi cấu trúc
            const elements = document.querySelectorAll('.countdown');
            elements.forEach(el => checkAndAct(el));
        });

        observer.observe(document.body, {
            childList: true,
            subtree: true,
            characterData: true
        });
    };

    // Kiểm tra link hết mã trước khi kích hoạt bộ quét
    if (window.location.href.includes('linkhuongdan.online') && window.location.href.includes('qq=notraffic')) {
        alert("🚨 HỆ THỐNG BÁO: UPTOLINK ĐÃ HẾT MÃ (No Traffic)!");
        return;
    }

    // Khởi chạy hệ thống cảm biến
    if (document.body) {
        startObserver();
    } else {
        window.addEventListener('DOMContentLoaded', startObserver);
    }

})();
