/**
 * Script: Uptolink Auto-Quest Driver
 * File: auto-uptolink.js (Bản v1.5 - Tự bốc link Quest, Giữ Session, Ép F5 thông minh)
 */

(function() {
    'use strict';

    if (window.UptolinkMasterExecuted) return;

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
            console.log(`[Ghost] Click lệch tâm thành công: X=${clientX.toFixed(1)}, Y=${clientY.toFixed(1)}`);
        } catch (err) {
            console.error("[Ghost] Lỗi kích hoạt click:", err);
        }
    };

    // 2. CORE LOGIC XỬ LÝ THEO QUY TRÌNH THỰC TẾ
    const mainDriver = () => {
        if (window.UptolinkMasterExecuted) return;

        const currentURL = window.location.href;

        // BƯỚC A: KIỂM TRA TRANG HƯỚNG DẪN (linkhuongdan.online)
        if (currentURL.includes('linkhuongdan.online')) {
            
            // 1. Check lỗi hết mã (No Traffic)
            if (currentURL.includes('qq=notraffic')) {
                window.UptolinkMasterExecuted = true;
                clearInterval(masterScanner);
                alert("🚨 UPTOLINK HẾT MÃ (No Traffic)! Vui lòng bỏ camp này.");
                return;
            }

            // 2. Nếu trạng thái hợp lệ (qq=complete) -> Tự động bốc từ khóa Quest để đi làm nhiệm vụ
            if (currentURL.includes('qq=complete')) {
                // Quét tìm từ khóa màu đỏ (Ví dụ: UY88) như trong ảnh bạn chụp
                const redElements = document.querySelectorAll('[style*="color: red"], [style*="color: #ff0000"], [style*="color:#ff0000"]');
                let keyword = "";
                
                for (let elem of redElements) {
                    const text = elem.innerText.trim();
                    if (text && text.length < 15) { // Từ khóa nhà cái thường ngắn
                        keyword = text;
                        break;
                    }
                }

                if (keyword && !window.HasAlertedQuest) {
                    window.HasAlertedQuest = true;
                    console.log(`[Ghost] Đã tìm thấy từ khóa Quest: ${keyword}`);
                    // Hiển thị thông báo nhắc bạn từ khóa để bạn vào thẳng trang web đó cho nhanh, đỡ phải gõ Google
                    // Ví dụ: Tìm chữ UY88 thì bạn gõ thẳng uy88vnn.com hoặc uy88.com trên tab đó luôn
                    alert(`🎯 TỪ KHÓA LẤY MÃ: ${keyword}\n Hãy truy cập thẳng vào trang web của từ khóa này để lấy mã nhé!`);
                }
                return;
            }
        }

        // BƯỚC B: XỬ LÝ TRÊN TRANG ĐÍCH NHIỆM VỤ (Ví dụ: meobet-88, uy88...)
        const targetBtn = document.getElementById('countdownBtn');
        if (!targetBtn) return;

        const btnText = targetBtn.innerText.toUpperCase();
        const matchSecond = btnText.match(/(\d+)\s*S/);

        // Trường hợp đang đếm giây
        if (matchSecond) {
            const seconds = parseInt(matchSecond[1], 10);
            console.log(`[Ghost] Đang theo dõi đếm giây: ${seconds}s`);
            return; // Để yên cho giây chạy ngầm
        }

        // TRƯỜNG HỢP 1: Đợi hết giây dài (>50s) và xuất hiện chữ bắt Click Link để F5 sang Bước 2
        if (btnText.includes("NHẤN LINK") || btnText.includes("CLICK LINK") || document.body.innerText.toUpperCase().includes("NHẤN LINK BẤT KỲ")) {
            console.log("[Ghost] Trạng thái chờ click link quảng cáo để F5.");
            
            // Lắng nghe hành vi khi bạn click vào màn hình (bấm quảng cáo)
            window.addEventListener('blur', () => {
                window.UptolinkMasterExecuted = true;
                clearInterval(masterScanner);
                setTimeout(() => {
                    console.log("[Ghost] Ép F5 tự động để nạp Bước 2...");
                    location.reload();
                }, 1200);
            }, { once: true });
            return;
        }

        // TRƯỜNG HỢP 2: NÚT SẴN SÀNG BẤM PHÁT QUYẾT ĐỊNH (STEP 1, STEP 2, LẤY MÃ...)
        if (btnText.includes('STEP') || btnText.includes('BƯỚC') || btnText.includes('LẤY MÃ') || btnText.includes('CLICK')) {
            window.UptolinkMasterExecuted = true;
            clearInterval(masterScanner);

            // Tạo độ trễ ngẫu nhiên mô phỏng tay người thật (1.2s - 2.2s)
            const randomDelay = getRandomInt(1200, 2200);
            console.log(`[Ghost] Nút đã sẵn sàng! Bấm sau ${randomDelay}ms...`);

            setTimeout(() => {
                simulateHumanClick(targetBtn);
                
                // Mở khóa lại sau 4 giây đề phòng hệ thống phản hồi chậm hoặc có Step tiếp theo
                setTimeout(() => {
                    window.UptolinkMasterExecuted = false;
                    if (!window.location.href.includes('finish')) {
                        masterScanner = setInterval(mainDriver, 1200);
                    }
                }, 4000);

            }, randomDelay);
        }
    };

    // Kích hoạt bộ quét thưa siêu nhẹ máy
    let masterScanner = setInterval(mainDriver, 1200);

})();
