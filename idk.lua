print("[25ms Dumper]: Đang thiết lập môi trường giả lập Sandbox...")

-- 1. Khởi tạo hàng đợi lưu trữ mã nguồn thu được
local CapturedScripts = {}
local LogFileName = "Captured_Source_" .. tostring(os.time()) .. ".lua"

-- Hàm bổ trợ kiểm tra và ghi nhận mã nguồn sạch
local function LogCapturedScript(sourceCode, callSource)
    if type(sourceCode) ~= "string" or #sourceCode < 50 then return end
    
    -- Kiểm tra tránh trùng lặp nếu hàm bị gọi lại nhiều lần trong vòng lặp
    for _, captured in ipairs(CapturedScripts) do
        if captured == sourceCode then return end
    end
    
    table.insert(CapturedScripts, sourceCode)
    
    warn("\n=======================================================")
    warn("[DUMPED SUCCESS] ĐÃ BẮT ĐƯỢC MÃ NGUỒN TỪ: " .. tostring(callSource))
    warn("Độ dài file: " .. tostring(#sourceCode) .. " ký tự.")
    warn("=======================================================\n")
    
    -- Ghi trực tiếp ra file trong thư mục workspace của Executor
    if writefile then
        local success, err = pcall(function()
            writefile(LogFileName, sourceCode)
        end)
        if success then
            print("[IO]: Đã lưu mã nguồn sạch vào file: " .. LogFileName)
        end
    end
 end

-- 2. TIẾN HÀNH HOOK (GHI ĐÈ) CÁC HÀM CỔNG VÀO NGUỒN RÕ

-- A. Hook hàm loadstring toàn cục (Nơi thực thi Bytecode/Code từ Server gửi về)
local oldLoadstring
oldLoadstring = hookfunction(loadstring, function(source, chunkname)
    if type(source) == "string" then
        LogCapturedScript(source, "loadstring()")
    end
    return oldLoadstring(source, chunkname)
end)

-- B. Hook phương thức HttpGet (Bắt link API sạch trước khi Loader tải)
local oldHttpGet
oldHttpGet = hookfunction(game.HttpGet, function(self, url, ...)
    if type(url) == "string" then
        warn("[HTTP LOG]: Phát hiện Loader đang gọi tới API: " .. url)
    end
    return oldHttpGet(self, url, ...)
end)

-- C. Thiết lập bảo vệ biến môi trường (Giả mạo môi trường sạch tránh Anti-Dump)
local orgEnv = getfenv(0)
local fakeEnv = setmetatable({}, {
    __index = function(t, key)
        if key == "loadstring" then
            return function(src, name)
                if type(src) == "string" then LogCapturedScript(src, "Injected Environment loadstring") end
                return oldLoadstring(src, name)
            end
        end
        return orgEnv[key]
    end,
    __newindex = function(t, key, value)
        orgEnv[key] = value
    end
})
setfenv(0, fakeEnv)

print("[25ms Dumper]: Môi trường đã sẵn sàng! Bây giờ bạn hãy bấm chạy (Execute) file Maru Hub hoặc Banana Cat để bắt code.")
