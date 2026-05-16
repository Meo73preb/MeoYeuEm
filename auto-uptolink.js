// ==UserScript==
// @name         Uptolink - Clean Page & Random Click Step 1
// @namespace    http://tampermonkey.net/
// @version      1.0
// @description  Xóa sạch rác trên web chỉ chừa lại nút, random thời gian delay từ 1s - 2s trước khi ấn để giả lập người thật.
// @author       meo_2k11
// @match        *://*/*
// @exclude      https://uptolink.one/*
// @exclude      https://*.uptolink.one/*
// @exclude      https://khodonglanh.io.vn/*
// @exclude      https://*.google.com/*
// @exclude      https://google.com/*
// @grant        none
// @run-at       document-idle
// ==/UserScript==

(function() {
    'use strict';

    console.log("[Minimalist] Đang quét tìm nút và dọn dẹp không gian...");

    let hasClicked = false;

    // Hàm tạo thời gian ngẫu nhiên từ min đến max (mili-giây)
    const getRandomDelay = (min, max) => {
        return Math.floor(Math.random() * (max - min + 1)) + min;
    };

    // Hàm dọn dẹp: Xóa sạch mọi thứ, giữ lại đúng cái hộp chứa nút
    const cleanPageAndKeepButton = (buttonBox) => {
        // Đưa cái hộp chứa nút ra ngoài body để làm "trung tâm vũ trụ"
        document.body.innerHTML = '';
        document.body.appendChild(buttonBox);
        
        // Định dạng lại trang cho siêu nhẹ và dễ nhìn trên điện thoại
        document.body.style.backgroundColor = '#121212'; // Màu nền tối cho dịu mắt
        document.body.style.display = 'flex';
        document.body.style.justifyContent = 'center';
        document.body.style.alignItems = 'center';
        document.body.style.height = '100vh';
        document.body.style.margin = '0';
        
        console.log("[Minimalist] Đã thổi bay toàn bộ quảng cáo và rác trên web!");
    };

    const processStep1 = () => {
        if (hasClicked) return true;

        const targetBtn = document.getElementById('countdownBtn');
        const countdownBox = document.getElementById('qq-countdown'); // Hộp chứa nút
        
        if (targetBtn && countdownBox) {
            const btnText = targetBtn.innerText.toUpperCase();
            
            // CHỈ ẤN KHI: Nút đã sẵn sàng (chuyển sang STEP 1 hoặc BƯỚC 1 hoặc LẤY MÃ)
            if (btnText.includes('STEP 1') || btnText.includes('BƯỚC 1') || btnText.includes('LẤY MÃ')) {
                
                hasClicked = true;
                clearInterval(pageScanner); // Tắt bộ quét ngầm ngay lập tức

                // 1. DỌN SẠCH TRANG: Giữ lại đúng cái hộp chứa nút cho nhẹ máy
                cleanPageAndKeepButton(countdownBox);

                // 2. TẠO DELAY NGẪU NHIÊN: Từ 1000ms đến 2000ms
                const randomTime = getRandomDelay(1000, 2000);
                console.log(`[Minimalist] Giả lập người thật: Sẽ ấn sau ${randomTime}ms...`);
                
                // 3. ẤN PHÁT QUYẾT ĐỊNH RỒI TỰ HỦY SCRIPT
                setTimeout(() => {
                    targetBtn.click();
                    console.log("[Minimalist] Đã ấn! Toàn bộ script đã dừng.");
                }, randomTime);
                
                return true;
            }
        }
        return false;
    };

    // Quét thưa để tìm nút (1.5 giây/lần)
    const pageScanner = setInterval(() => {
        processStep1();
    }, 1500);

    // Tự động dừng quét sau 25 giây để giải phóng RAM nếu trang không có nút
    setTimeout(() => clearInterval(pageScanner), 20000);

})();
