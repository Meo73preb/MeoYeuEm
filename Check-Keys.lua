-- Check-Keys.lua - Vicat Hub Key System v3.0
-- Support both UI and Direct mode

repeat wait() until game:IsLoaded() and game.Players.LocalPlayer
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local HWID = game:GetService("RbxAnalyticsService"):GetClientId()
local CoreGui = game:GetService("CoreGui")
local StarterGui = game:GetService("StarterGui")
local API_URL = "https://vicat-hub-keys.onrender.com"
local player = Players.LocalPlayer
local function isRobloxEnvironment()
    return game and game.PlaceId and game.PlaceId ~= 0
end

if not isRobloxEnvironment() then
    error("This script can only run inside Roblox!")
    return
end

-- Notification function
local function Notify(title, text, duration)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title,
            Text = text,
            Duration = duration or 5
        })
    end)
end

-- Functions
local function CheckKeyStatus(key)
    local success, response = pcall(function()
        return HttpService:RequestAsync({
            Url = API_URL .. "/check-key",
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = HttpService:JSONEncode({ key = key })
        })
    end)
    
    if not success or response.StatusCode ~= 200 then
        return false, "Connection error"
    end
    
    local data = HttpService:JSONDecode(response.Body)
    return data.valid, data
end

local function VerifyKey(key)
    local success, response = pcall(function()
        return HttpService:RequestAsync({
            Url = API_URL .. "/verify",
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = HttpService:JSONEncode({ key = key, hwid = HWID })
        })
    end)
    
    if not success or response.StatusCode ~= 200 then
        return false, "Connection error"
    end
    
    local data = HttpService:JSONDecode(response.Body)
    
    if data.status == true then
        return true, data.token
    else
        local messages = {
            no_key = "No key provided",
            invalid = "Invalid key",
            expired = "Key has expired",
            hwid_mismatch = "Key is bound to another HWID",
            blacklisted = "Key has been blacklisted"
        }
        return false, messages[data.reason] or data.reason
    end
end

local function LoadScript(token)
    local success, response = pcall(function()
        return HttpService:RequestAsync({
            Url = API_URL .. "/script?token=" .. HttpService:UrlEncode(token),
            Method = "GET",
            Headers = { ["Content-Type"] = "text/plain" }
        })
    end)
    
    if not success or response.StatusCode ~= 200 then
        return false, "Failed to download script"
    end
    
    local scriptContent = response.Body
    
    -- Remove comment header
    local cleanScript = scriptContent:match("%-%-.-\n\n(.*)") or scriptContent
    
    -- Execute script
    local loadSuccess, loadError = pcall(function()
        local func, err = loadstring(cleanScript)
        if not func then
            error("Failed to compile: " .. tostring(err))
        end
        func()
    end)
    
    if loadSuccess then
        return true, "Script loaded successfully"
    else
        return false, "Script execution error: " .. tostring(loadError)
    end
end

-- Check for direct key mode
if _G.Keys and type(_G.Keys) == "string" and #_G.Keys > 0 then
    print("🔑 Direct Key Mode")
    print("📋 Key:", _G.Keys)
    print("🆔 HWID:", HWID)
    
    Notify("Vicat Hub", "Checking key...", 3)
    
    -- Check key status first
    local isValid, keyData = CheckKeyStatus(_G.Keys)
    
    if isValid then
        print("✅ Key is valid!")
        if keyData.timeLeft then
            print(string.format("⏰ Time left: %d hours, %d minutes", 
                keyData.timeLeft.hours, keyData.timeLeft.minutes))
        end
    else
        print("❌ Key check failed:", keyData)
    end
    
    -- Verify and load
    print("🔄 Verifying key...")
    local success, result = VerifyKey(_G.Keys)
    
    if success then
        print("✅ Key verified!")
        Notify("Success", "Loading script...", 3)
        
        -- Save key
        if writefile then
            writefile("vicat_key.txt", _G.Keys)
        end
        
        -- Load script
        wait(1)
        local loadSuccess, loadResult = LoadScript(result)
        
        if loadSuccess then
            print("🎉 Script loaded successfully!")
            Notify("Vicat Hub", "Welcome!", 5)
        else
            print("❌ " .. loadResult)
            Notify("Error", loadResult, 5)
        end
    else
        print("❌ Verification failed:", result)
        Notify("Error", result, 5)
    end
    
    return
end

-- UI Mode - Load saved key or show GUI
local savedKey = nil
if readfile and isfile and isfile("vicat_key.txt") then
    savedKey = readfile("vicat_key.txt")
end

if savedKey and #savedKey > 0 then
    print("💾 Saved key found, attempting auto-login...")
    
    local isValid, keyData = CheckKeyStatus(savedKey)
    
    if isValid then
        print("✅ Saved key is valid!")
        
        local success, result = VerifyKey(savedKey)
        
        if success then
            Notify("Vicat Hub", "Loading script...", 3)
            wait(1)
            
            local loadSuccess, loadResult = LoadScript(result)
            
            if loadSuccess then
                print("🎉 Script loaded!")
                Notify("Vicat Hub", "Welcome back!", 5)
                return
            end
        end
    else
        print("⚠️ Saved key is invalid, showing GUI...")
        if delfile then
            delfile("vicat_key.txt")
        end
    end
end

-- Show GUI if no valid key
print("🎨 Loading Key System GUI...")

-- Create GUI
local ScreenGui = Instance.new("ScreenGui")
local MainFrame = Instance.new("Frame")
local UICorner = Instance.new("UICorner")
local TitleLabel = Instance.new("TextLabel")
local KeyBox = Instance.new("TextBox")
local KeyBoxCorner = Instance.new("UICorner")
local SubmitButton = Instance.new("TextButton")
local SubmitCorner = Instance.new("UICorner")
local GetKeyButton = Instance.new("TextButton")
local GetKeyCorner = Instance.new("UICorner")
local CheckKeyButton = Instance.new("TextButton")
local CheckKeyCorner = Instance.new("UICorner")
local ResetHWIDButton = Instance.new("TextButton")
local ResetHWIDCorner = Instance.new("UICorner")
local StatusLabel = Instance.new("TextLabel")
local CloseButton = Instance.new("TextButton")
local HWIDLabel = Instance.new("TextLabel")
local CopyHWIDButton = Instance.new("TextButton")

ScreenGui.Name = "VicatKeySystemV3"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- Main Frame
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
MainFrame.Position = UDim2.new(0.5, -220, 0.5, -200)
MainFrame.Size = UDim2.new(0, 440, 0, 400)
MainFrame.Active = true
MainFrame.Draggable = true

UICorner.Parent = MainFrame
UICorner.CornerRadius = UDim.new(0, 12)

-- Title
TitleLabel.Parent = MainFrame
TitleLabel.BackgroundTransparency = 1
TitleLabel.Position = UDim2.new(0, 0, 0, 10)
TitleLabel.Size = UDim2.new(1, 0, 0, 40)
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.Text = "VICAT KEY SYSTEM V3"
TitleLabel.TextColor3 = Color3.fromRGB(255, 51, 51)
TitleLabel.TextSize = 24

-- HWID Display
HWIDLabel.Parent = MainFrame
HWIDLabel.BackgroundTransparency = 1
HWIDLabel.Position = UDim2.new(0, 15, 0, 55)
HWIDLabel.Size = UDim2.new(0.7, 0, 0, 20)
HWIDLabel.Font = Enum.Font.GothamMedium
HWIDLabel.Text = "HWID: " .. HWID:sub(1, 20) .. "..."
HWIDLabel.TextColor3 = Color3.fromRGB(120, 120, 120)
HWIDLabel.TextSize = 10
HWIDLabel.TextXAlignment = Enum.TextXAlignment.Left

-- Copy HWID Button
CopyHWIDButton.Parent = MainFrame
CopyHWIDButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
CopyHWIDButton.Position = UDim2.new(0.75, 0, 0, 53)
CopyHWIDButton.Size = UDim2.new(0.2, 0, 0, 24)
CopyHWIDButton.Font = Enum.Font.GothamBold
CopyHWIDButton.Text = "📋 COPY"
CopyHWIDButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CopyHWIDButton.TextSize = 11
CopyHWIDButton.AutoButtonColor = false

local CopyHWIDCorner = Instance.new("UICorner", CopyHWIDButton)
CopyHWIDCorner.CornerRadius = UDim.new(0, 6)

-- Key Input Box
KeyBox.Parent = MainFrame
KeyBox.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
KeyBox.Position = UDim2.new(0.08, 0, 0.24, 0)
KeyBox.Size = UDim2.new(0.84, 0, 0, 42)
KeyBox.Font = Enum.Font.Gotham
KeyBox.PlaceholderText = "Enter your key: XXXX-XXXX-XXXX-XXXX"
KeyBox.Text = savedKey or ""
KeyBox.TextColor3 = Color3.fromRGB(255, 255, 255)
KeyBox.TextSize = 15

KeyBoxCorner.Parent = KeyBox
KeyBoxCorner.CornerRadius = UDim.new(0, 8)

-- Submit Button
SubmitButton.Parent = MainFrame
SubmitButton.BackgroundColor3 = Color3.fromRGB(194, 3, 38)
SubmitButton.Position = UDim2.new(0.08, 0, 0.44, 0)
SubmitButton.Size = UDim2.new(0.84, 0, 0, 42)
SubmitButton.Font = Enum.Font.GothamBold
SubmitButton.Text = "🔓 SUBMIT KEY"
SubmitButton.TextColor3 = Color3.fromRGB(255, 255, 255)
SubmitButton.TextSize = 17
SubmitButton.AutoButtonColor = false

SubmitCorner.Parent = SubmitButton
SubmitCorner.CornerRadius = UDim.new(0, 8)

-- Button Row 1
GetKeyButton.Parent = MainFrame
GetKeyButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
GetKeyButton.Position = UDim2.new(0.08, 0, 0.62, 0)
GetKeyButton.Size = UDim2.new(0.4, 0, 0, 36)
GetKeyButton.Font = Enum.Font.GothamBold
GetKeyButton.Text = "🔑 GET KEY"
GetKeyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
GetKeyButton.TextSize = 14
GetKeyButton.AutoButtonColor = false

GetKeyCorner.Parent = GetKeyButton
GetKeyCorner.CornerRadius = UDim.new(0, 8)

CheckKeyButton.Parent = MainFrame
CheckKeyButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
CheckKeyButton.Position = UDim2.new(0.52, 0, 0.62, 0)
CheckKeyButton.Size = UDim2.new(0.4, 0, 0, 36)
CheckKeyButton.Font = Enum.Font.GothamBold
CheckKeyButton.Text = "✅ CHECK KEY"
CheckKeyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CheckKeyButton.TextSize = 14
CheckKeyButton.AutoButtonColor = false

CheckKeyCorner.Parent = CheckKeyButton
CheckKeyCorner.CornerRadius = UDim.new(0, 8)

-- Reset HWID Button
ResetHWIDButton.Parent = MainFrame
ResetHWIDButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
ResetHWIDButton.Position = UDim2.new(0.08, 0, 0.75, 0)
ResetHWIDButton.Size = UDim2.new(0.84, 0, 0, 36)
ResetHWIDButton.Font = Enum.Font.GothamBold
ResetHWIDButton.Text = "🔄 RESET HWID (Need Login)"
ResetHWIDButton.TextColor3 = Color3.fromRGB(255, 200, 100)
ResetHWIDButton.TextSize = 13
ResetHWIDButton.AutoButtonColor = false

ResetHWIDCorner.Parent = ResetHWIDButton
ResetHWIDCorner.CornerRadius = UDim.new(0, 8)

-- Status Label
StatusLabel.Parent = MainFrame
StatusLabel.BackgroundTransparency = 1
StatusLabel.Position = UDim2.new(0, 15, 0.88, 0)
StatusLabel.Size = UDim2.new(1, -30, 0, 42)
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.Text = "Ready. Enter your key to continue."
StatusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
StatusLabel.TextSize = 12
StatusLabel.TextWrapped = true
StatusLabel.TextYAlignment = Enum.TextYAlignment.Top

-- Close Button
CloseButton.Parent = MainFrame
CloseButton.BackgroundTransparency = 1
CloseButton.Position = UDim2.new(0.93, 0, 0, 8)
CloseButton.Size = UDim2.new(0, 28, 0, 28)
CloseButton.Font = Enum.Font.GothamBold
CloseButton.Text = "✕"
CloseButton.TextColor3 = Color3.fromRGB(255, 51, 51)
CloseButton.TextSize = 20
CloseButton.AutoButtonColor = false

-- Functions
local function UpdateStatus(text, color)
    StatusLabel.Text = text
    StatusLabel.TextColor3 = color or Color3.fromRGB(200, 200, 200)
end

-- Button Actions
CopyHWIDButton.MouseButton1Click:Connect(function()
    if setclipboard then
        setclipboard(HWID)
        Notify("Copied", "HWID copied to clipboard!", 3)
        UpdateStatus("📋 HWID copied!", Color3.fromRGB(51, 255, 51))
    end
end)

GetKeyButton.MouseButton1Click:Connect(function()
    local url = API_URL .. "/docs"
    if setclipboard then
        setclipboard(url)
        Notify("Copied!", "Docs link copied!", 3)
        UpdateStatus("📋 Link copied: " .. url, Color3.fromRGB(51, 255, 51))
    else
        UpdateStatus("🔗 Visit: " .. url, Color3.fromRGB(255, 200, 0))
    end
end)

CheckKeyButton.MouseButton1Click:Connect(function()
    local key = KeyBox.Text:gsub("%s+", "")
    if key == "" then
        UpdateStatus("❌ Please enter a key!", Color3.fromRGB(255, 51, 51))
        return
    end
    
    UpdateStatus("🔄 Checking key status...", Color3.fromRGB(255, 200, 0))
    
    local isValid, data = CheckKeyStatus(key)
    
    if isValid then
        local statusText = string.format(
            "✅ Key is VALID!\n⏰ Time left: %d hours, %d minutes\n🔒 HWID: %s",
            data.timeLeft.hours,
            data.timeLeft.minutes,
            data.boundTo or "Not bound yet"
        )
        UpdateStatus(statusText, Color3.fromRGB(51, 255, 51))
        Notify("Key Valid", "Key is ready to use! ✅", 5)
    else
        UpdateStatus("❌ " .. data, Color3.fromRGB(255, 51, 51))
        Notify("Key Invalid", data, 5)
    end
end)

SubmitButton.MouseButton1Click:Connect(function()
    local key = KeyBox.Text:gsub("%s+", "")
    if key == "" then
        UpdateStatus("❌ Please enter a key!", Color3.fromRGB(255, 51, 51))
        return
    end
    
    UpdateStatus("🔄 Verifying key...", Color3.fromRGB(255, 200, 0))
    Notify("Vicat Hub", "Verifying...", 3)
    
    local success, result = VerifyKey(key)
    
    if success then
        UpdateStatus("✅ Verified! Loading script...", Color3.fromRGB(51, 255, 51))
        
        if writefile then
            writefile("vicat_key.txt", key)
        end
        
        wait(1)
        local loadSuccess, loadResult = LoadScript(result)
        
        if loadSuccess then
            Notify("Success", "Script loaded!", 5)
            wait(2)
            ScreenGui:Destroy()
        else
            UpdateStatus("❌ " .. loadResult, Color3.fromRGB(255, 51, 51))
            Notify("Error", loadResult, 5)
        end
    else
        UpdateStatus("❌ " .. result, Color3.fromRGB(255, 51, 51))
        Notify("Error", result, 5)
    end
end)

ResetHWIDButton.MouseButton1Click:Connect(function()
    UpdateStatus("⚠️ HWID reset requires user login. Visit docs for info.", Color3.fromRGB(255, 200, 0))
    Notify("Info", "Visit docs page to login and reset HWID", 5)
end)

CloseButton.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

-- Add to GUI
pcall(function()
    ScreenGui.Parent = CoreGui
end)

if not ScreenGui.Parent then
    ScreenGui.Parent = player:WaitForChild("PlayerGui")
end

print("✅ Vicat Key System GUI loaded!")
Notify("Vicat Hub", "Key System Ready", 3)
