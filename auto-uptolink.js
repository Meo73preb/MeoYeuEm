/**
 * Script: Uptolink Multi-Step Optimizer
 * File: auto-uptolink.js (Bản v1.2 - Đợi hết giây dài -> Chờ chữ xuất hiện -> F5 sang Bước 2)
 */

(function() {
    'use strict';

    if (window.UptolinkStepExecuted) return;

    // 1. GIẢ LẬP NGƯỜI THẬT (CLICK LỆCH PIXEL)
    const getRandomInt = (min, max) => Math.floor(Math.random() * (max - min + 1)) + min;

    const simulateHumanClick = (element) => {
        const rect = element.getBoundingClientRect();
        const clientX = (rect.left + rect.width / 2) + getRandomInt(-8, 8);
        const clientY = (rect.top + rect.height / 2) + getRandomInt(-8, 8);

        const pointerEvents = ['pointerdown', 'mousedown', 'pointerup', 'mouseup', 'click'];
        pointerEvents.forEach(eventType => {
            element.dispatchEvent(new MouseEvent(eventType, {
                bubbles: true, cancelable: true, view: window,
                clientX: clientX, clientY: clientY
            }));
        });
        console.log(`[Ghost] Click lệch tâm: X=${clientX.toFixed(1)}, Y=${clientY.toFixed(1)}`);
    };

    // 2. GIAO DIỆN CYBERPUNK TOÂN GIẢN
    let guiStatusText;

    const createMinimalistGUI = (buttonBox) => {
        // Chỉ dọn trang khi không ở trạng thái đợi chữ để F5
        if (document.getElementById('gui-active')) return;
        
        document.body.innerHTML = '';
        
        const container = document.createElement('div');
        container.style.cssText = `
            display: flex; flex-direction: column; justify-content: center;
            align-items: center; height: 100vh; margin: 0; overflow: hidden;
            background: radial-gradient(circle, #1a1c23 0%, #0d0e12 100%);
            font-family: 'Segoe UI', Roboto, sans-serif;
        `;

        const guiBox = document.createElement('div');
        guiBox.style.cssText = `
            background: rgba(255, 255, 255, 0.02); border: 1px solid rgba(0, 255, 204, 0.2);
            border-radius: 16px; padding: 15px 30px; margin-bottom: 25px;
            box-shadow: 0 0 20px rgba(0, 255, 204, 0.1); text-align: center;
        `;

        const title = document.createElement('div');
        title.innerText = "UPTOLINK STEP CONTROLLER V8.0";
        title.style.cssText = `color: #ffffff; font-size: 11px; font-weight: 700; letter-spacing: 2px; margin-bottom: 6px; opacity: 0.6;`;

        guiStatusText = document.createElement('div');
        guiStatusText.innerText = "HỆ THỐNG ĐANG THEO DÕI...";
        guiStatusText.style.cssText = `color: #00ffcc; font-size: 15px; font-weight: 700; letter-spacing: 1px; text-shadow: 0 0 10px rgba(0, 255, 204, 0.5);`;

        guiBox.appendChild(title);
        guiBox.appendChild(guiStatusText);
        
        buttonBox.style.cssText = `transform: scale(1.1); box-shadow: 0 10px 30px rgba(0,0,0,0.6); border-radius: 8px;`;

        container.appendChild(guiBox);
        container.appendChild(buttonBox);
        document.body.appendChild(container);
        
        countdownBox.id = 'gui-active';
    };

    const updateGUI = (text, color) => {
        if (guiStatusText) {
            guiStatusText.innerText = text.toUpperCase();
            guiStatusText.style.color = color;
            guiStatusText.style.textShadow = `0 0 10px ${color}88`;
        }
    };

    // 3. LOGIC THEO QUY TRÌNH THỰC TẾ
    const monitorSteps = () => {
        if (window.UptolinkStepExecuted) return;

        const targetBtn = document.getElementById('countdownBtn');
        const countdownBox = document.getElementById('qq-countdown');

        if (!targetBtn || !countdownBox) return;

        const btnText = targetBtn.innerText.toUpperCase();
        
        // Đọc số giây đang chạy trên nút
        const matchSecond = btnText.match(/(\d+)\s*S/);
        
        // TRƯỜNG HỢP 1: Nút đang đếm ngược giây
        if (matchSecond) {
            const seconds = parseInt(matchSecond[1], 10);

            if (seconds > 20) {
                // Nếu giây lớn hơn 20s (bước đếm dài ban đầu), KHÔNG dọn trang để bạn nhìn thấy bài viết mà click link quảng cáo
                console.log(`[Ghost] Đang đợi hết giây dài: ${seconds}s...`);
                return; 
            }

            if (seconds <= 20) {
                // Nếu giây nhỏ hơn hoặc bằng 20s (thường là ở Bước 2), dọn sạch trang cho nhẹ máy và coi số giây lùi
                createMinimalistGUI(countdownBox);
                updateGUI(`Đang đếm ngược bước 2: ${seconds}s`, "#00ffcc");
                return;
            }
        }

        // TRƯỜNG HỢP 2: Giây đã chạy hết và xuất hiện chữ "NHẤN LINK BẤT KỲ..."
        if (btnText.includes("NHẤN LINK") || btnText.includes("CLICK LINK") || document.body.innerText.toUpperCase().includes("NHẤN LINK BẤT KỲ")) {
            // Chúng ta không dọn trang khúc này để giữ nguyên các link quảng cáo cho bạn nhấn
            console.log("[Ghost] Đã xuất hiện yêu cầu nhấn link quảng cáo!");
            
            // Script sẽ tạo một bộ kiểm tra: Khi bạn vừa click vào cái gì đó trên trang hoặc sau khi bạn làm nhiệm vụ xong
            // Nó sẽ canh để F5 tải lại trang nhằm kích hoạt Bước 2
            window.addEventListener('blur', () => {
                // Khi bạn click vào quảng cáo, trình duyệt thường bị mất focus (blur) vì nhảy tab hoặc mở link
                // Lúc này là thời điểm vàng để F5 trang gốc nhằm nạp Bước 2
                setTimeout(() => {
                    console.log("[Ghost] Phát hiện tương tác quảng cáo! Đang F5 để sang Bước 2...");
                    location.reload();
                }, 1000);
            });
            return;
        }

        // TRƯỜNG HỢP 3: NÚT ĐÃ SẴN SÀNG ĐỂ BẤM (STEP 1, STEP 2, BƯỚC 1, BƯỚC 2, LẤY MÃ)
        if (btnText.includes('STEP') || btnText.includes('BƯỚC') || btnText.includes('LẤY MÃ') || btnText.includes('CLICK')) {
            window.UptolinkStepExecuted = true;
            clearInterval(pageScanner);

            // Dọn sạch trang rác trước khi bấm phát quyết định
            createMinimalistGUI(countdownBox);

            // Delay ngẫu nhiên 1s - 2s giả lập tay người
            const randomDelay = getRandomInt(1000, 2000);
            updateGUI(`Chuẩn bị ấn (${randomDelay}ms)...`, "#ffaa00");

            setTimeout(() => {
                updateGUI("Đã ấn thành công!", "#00ff00");
                simulateHumanClick(targetBtn);
                
                // Mở khóa lại sau 3 giây đề phòng trang không chuyển hướng ngay (để quét tiếp bước sau)
                setTimeout(() => {
                    window.UptolinkStepExecuted = false;
                    if (!window.location.href.includes('finish')) {
                        pageScanner = setInterval(monitorSteps, 1200);
                    }
                }, 3000);

            }, randomDelay);
        }
    };

    // Chặn popup đè lung tung
    try { window.open = () => null; } catch(e) {}

    // Kích hoạt bộ quét thưa
    let pageScanner = setInterval(monitorSteps, 1200);

})();
