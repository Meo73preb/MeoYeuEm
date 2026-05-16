/**
 * Script: Uptolink Ultra Stealth & Minimalist GUI
 * File: auto-uptolink.js (Dành cho kho GitHub của bạn)
 * Tính năng: Dọn trang siêu đẹp, click lệch pixel giả lập người thật, GUI thông báo trạng thái.
 */

(function() {
    'use strict';

    // Tuyệt đối không chạy nếu đã click rồi
    if (window.UptolinkGhostExecuted) return;

    console.log("%c[Ghost] Khởi động hệ thống ẩn mình...", "color: #00ffff");

    // ==========================================
    // 1. HÀM TIỆN ÍCH (UTILITIES)
    // ==========================================
    
    // Tạo số ngẫu nhiên trong khoảng [min, max]
    const getRandomInt = (min, max) => Math.floor(Math.random() * (max - min + 1)) + min;

    // Giả lập click chuột của người thật (Lệch tâm vài pixel)
    const simulateHumanClick = (element) => {
        const rect = element.getBoundingClientRect();
        
        // Lấy tâm của nút
        const centerX = rect.left + rect.width / 2;
        const centerY = rect.top + rect.height / 2;
        
        // Làm lệch tâm ngẫu nhiên từ -8px đến +8px (người thật không bao giờ bấm trúng 100% tâm)
        const clientX = centerX + getRandomInt(-8, 8);
        const clientY = centerY + getRandomInt(-8, 8);

        // Tạo chuỗi sự kiện click chuẩn xác như chuột thật
        const pointerEvents = ['pointerdown', 'mousedown', 'pointerup', 'mouseup', 'click'];
        
        pointerEvents.forEach(eventType => {
            const ev = new MouseEvent(eventType, {
                bubbles: true,
                cancelable: true,
                view: window,
                clientX: clientX,
                clientY: clientY,
                screenX: clientX + window.screenX,
                screenY: clientY + window.screenY,
                button: 0,
                buttons: 1
            });
            element.dispatchEvent(ev);
        });
        
        console.log(`%c[Human Click] Đã click tại tọa độ lệch: X=${clientX.toFixed(1)}, Y=${clientY.toFixed(1)}`, "color: #ff00ff");
    };

    // ==========================================
    // 2. GIAO DIỆN GUI & DỌN TRANG ĐẸP (UI/UX)
    // ==========================================
    
    let guiStatusText;

    const createMinimalistGUI = (buttonBox) => {
        // Xóa sạch sẽ đống rác quảng cáo ngầm
        document.body.innerHTML = '';
        
        // Tạo Container chính siêu đẹp (Cyberpunk Dark Mode)
        const container = document.createElement('div');
        container.style.cssText = `
            display: flex;
            flex-direction: column;
            justify-content: center;
            align-items: center;
            height: 100vh;
            background: radial-gradient(circle, #1e1e24 0%, #0f0f12 100%);
            font-family: 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
            margin: 0;
            overflow: hidden;
        `;

        // Thanh thông báo GUI trạng thái ở phía trên nút
        const guiBox = document.createElement('div');
        guiBox.style.cssText = `
            background: rgba(255, 255, 255, 0.03);
            border: 1px solid rgba(255, 255, 255, 0.1);
            border-radius: 12px;
            padding: 12px 24px;
            margin-bottom: 30px;
            box-shadow: 0 8px 32px 0 rgba(0, 0, 0, 0.37);
            backdrop-filter: blur(4px);
            text-align: center;
            min-width: 250px;
            transition: all 0.3s ease;
        `;

        guiStatusText = document.createElement('span');
        guiStatusText.innerText = "ĐANG ĐỢI HỆ THỐNG ỔN ĐỊNH...";
        guiStatusText.style.cssText = `
            color: #00ffcc;
            font-size: 14px;
            font-weight: 600;
            letter-spacing: 1px;
            text-shadow: 0 0 8px rgba(0, 255, 204, 0.4);
        `;
        guiBox.appendChild(guiStatusText);

        // Định dạng lại cái hộp chứa nút bấm gốc để nó "nhập gia tùy tục" với giao diện mới
        buttonBox.style.cssText = `
            transform: scale(1.1);
            box-shadow: 0 10px 30px rgba(0,0,0,0.5);
            border-radius: 8px;
            overflow: hidden;
            transition: all 0.3s ease;
        `;

        // Thêm mọi thứ vào màn hình
        container.appendChild(guiBox);
        container.appendChild(buttonBox);
        document.body.appendChild(container);
    };

    // Update thông báo trên GUI nhanh chóng
    const updateGUI = (text, color) => {
        if (guiStatusText) {
            guiStatusText.innerText = text.toUpperCase();
            guiStatusText.style.color = color;
            guiStatusText.style.textShadow = `0 0 8px ${color}66`;
        }
    };

    // ==========================================
    // 3. CORE LOGIC & ẨN THÂN (STEALTH ENGINE)
    // ==========================================
    
    const processStep1 = () => {
        if (window.UptolinkGhostExecuted) return true;

        const targetBtn = document.getElementById('countdownBtn');
        const countdownBox = document.getElementById('qq-countdown');
        
        if (targetBtn && countdownBox) {
            const btnText = targetBtn.innerText.toUpperCase();
            
            // Điều kiện kích hoạt: Khi chữ trên nút chuyển trạng thái thành công
            if (btnText.includes('STEP 1') || btnText.includes('BƯỚC 1') || btnText.includes('LẤY MÃ')) {
                
                // Khóa ngay lập tức chống click trùng lặp/DDoS
                window.UptolinkGhostExecuted = true;
                clearInterval(pageScanner);

                // 1. Thổi bay trang cũ, đưa giao diện tối giản, sang chảnh lên
                createMinimalistGUI(countdownBox);

                // 2. Tạo delay ngẫu nhiên (1000ms đến 2000ms) để che mắt AI chống bot
                const randomDelay = getRandomInt(1000, 1999);
                updateGUI(`Giả lập người thật (Delay: ${randomDelay}ms)...`, "#ffaa00");

                // 3. Thực hiện phát bấm quyết định
                setTimeout(() => {
                    updateGUI("Đang tiến hành ấn nút...", "#00ff00");
                    simulateHumanClick(targetBtn);
                }, randomDelay);
                
                return true;
            }
        }
        return false;
    };

    // Chặn bẻ gãy các hàm truy vết Tool của Web
    try {
        window.console.clear = () => {};
        window.open = () => null;
    } catch(e) {}

    // Bộ quét thưa cực kỳ nhẹ máy (1.2 giây/lần), an toàn tuyệt đối cho RAM
    const pageScanner = setInterval(() => {
        processStep1();
    }, 1200);

    // Tự động giải phóng hoàn toàn bộ nhớ sau 30 giây nếu không tìm thấy nút hợp lệ
    setTimeout(() => {
        if (!window.UptolinkGhostExecuted) {
            clearInterval(pageScanner);
        }
    }, 20000);

})();
