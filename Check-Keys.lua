-- Vicat Key System GUI (Standalone)
-- This is loaded when no valid key is found

repeat wait() until game:IsLoaded() and game.Players.LocalPlayer

local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local CoreGui = game:GetService("CoreGui")
local StarterGui = game:GetService("StarterGui")

-- Configuration
local API_URL = "https://vicat-hub-keys.onrender.com"
local SCRIPT_URL = API_URL .. "/script"

-- Create GUI
local ScreenGui = Instance.new("ScreenGui")
local MainFrame = Instance.new("Frame")
local UICorner = Instance.new("UICorner")
local TitleLabel = Instance.new("TextLabel")
local SubtitleLabel = Instance.new("TextLabel")
local KeyBox = Instance.new("TextBox")
local KeyBoxCorner = Instance.new("UICorner")
local SubmitButton = Instance.new("TextButton")
local SubmitCorner = Instance.new("UICorner")
local GetKeyButton = Instance.new("TextButton")
local GetKeyCorner = Instance.new("UICorner")
local CheckKeyButton = Instance.new("TextButton")
local CheckKeyCorner = Instance.new("UICorner")
local StatusLabel = Instance.new("TextLabel")
local CloseButton = Instance.new("TextButton")

-- Setup GUI Properties
ScreenGui.Name = "VicatKeySystem"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- Main Frame
MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
MainFrame.Position = UDim2.new(0.5, -200, 0.5, -180)
MainFrame.Size = UDim2.new(0, 400, 0, 360)
MainFrame.Active = true
MainFrame.Draggable = true

UICorner.Parent = MainFrame
UICorner.CornerRadius = UDim.new(0, 10)

-- Title
TitleLabel.Name = "TitleLabel"
TitleLabel.Parent = MainFrame
TitleLabel.BackgroundTransparency = 1
TitleLabel.Position = UDim2.new(0, 0, 0, 10)
TitleLabel.Size = UDim2.new(1, 0, 0, 35)
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.Text = "VICAT KEY SYSTEM"
TitleLabel.TextColor3 = Color3.fromRGB(255, 51, 51)
TitleLabel.TextSize = 24

-- Subtitle
SubtitleLabel.Name = "SubtitleLabel"
SubtitleLabel.Parent = MainFrame
SubtitleLabel.BackgroundTransparency = 1
SubtitleLabel.Position = UDim2.new(0, 0, 0, 45)
SubtitleLabel.Size = UDim2.new(1, 0, 0, 20)
SubtitleLabel.Font = Enum.Font.Gotham
SubtitleLabel.Text = "Secure Script Protection"
SubtitleLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
SubtitleLabel.TextSize = 12

-- Key Input Box
KeyBox.Name = "KeyBox"
KeyBox.Parent = MainFrame
KeyBox.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
KeyBox.Position = UDim2.new(0.1, 0, 0.28, 0)
KeyBox.Size = UDim2.new(0.8, 0, 0, 40)
KeyBox.Font = Enum.Font.Gotham
KeyBox.PlaceholderText = "Enter your key here..."
KeyBox.Text = ""
KeyBox.TextColor3 = Color3.fromRGB(255, 255, 255)
KeyBox.TextSize = 16

KeyBoxCorner.Parent = KeyBox
KeyBoxCorner.CornerRadius = UDim.new(0, 8)

-- Submit Button
SubmitButton.Name = "SubmitButton"
SubmitButton.Parent = MainFrame
SubmitButton.BackgroundColor3 = Color3.fromRGB(194, 3, 38)
SubmitButton.Position = UDim2.new(0.1, 0, 0.47, 0)
SubmitButton.Size = UDim2.new(0.8, 0, 0, 40)
SubmitButton.Font = Enum.Font.GothamBold
SubmitButton.Text = "SUBMIT KEY"
SubmitButton.TextColor3 = Color3.fromRGB(255, 255, 255)
SubmitButton.TextSize = 18
SubmitButton.AutoButtonColor = false

SubmitCorner.Parent = SubmitButton
SubmitCorner.CornerRadius = UDim.new(0, 8)

-- Get Key Button
GetKeyButton.Name = "GetKeyButton"
GetKeyButton.Parent = MainFrame
GetKeyButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
GetKeyButton.Position = UDim2.new(0.1, 0, 0.64, 0)
GetKeyButton.Size = UDim2.new(0.37, 0, 0, 35)
GetKeyButton.Font = Enum.Font.GothamBold
GetKeyButton.Text = "GET KEY"
GetKeyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
GetKeyButton.TextSize = 14
GetKeyButton.AutoButtonColor = false
local HWID = game:GetService("RbxAnalyticsService"):GetClientId()
GetKeyCorner.Parent = GetKeyButton
GetKeyCorner.CornerRadius = UDim.new(0, 8)

-- Check Key Button
CheckKeyButton.Name = "CheckKeyButton"
CheckKeyButton.Parent = MainFrame
CheckKeyButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
CheckKeyButton.Position = UDim2.new(0.53, 0, 0.64, 0)
CheckKeyButton.Size = UDim2.new(0.37, 0, 0, 35)
CheckKeyButton.Font = Enum.Font.GothamBold
CheckKeyButton.Text = "CHECK KEY"
CheckKeyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CheckKeyButton.TextSize = 14
CheckKeyButton.AutoButtonColor = false

CheckKeyCorner.Parent = CheckKeyButton
CheckKeyCorner.CornerRadius = UDim.new(0, 8)

-- Status Label
StatusLabel.Name = "StatusLabel"
StatusLabel.Parent = MainFrame
StatusLabel.BackgroundTransparency = 1
StatusLabel.Position = UDim2.new(0, 10, 0.8, 0)
StatusLabel.Size = UDim2.new(1, -20, 0, 50)
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.Text = "Please enter your key to continue"
StatusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
StatusLabel.TextSize = 12
StatusLabel.TextWrapped = true
StatusLabel.TextYAlignment = Enum.TextYAlignment.Top

-- Close Button
CloseButton.Name = "CloseButton"
CloseButton.Parent = MainFrame
CloseButton.BackgroundTransparency = 1
CloseButton.Position = UDim2.new(0.92, 0, 0, 5)
CloseButton.Size = UDim2.new(0, 25, 0, 25)
CloseButton.Font = Enum.Font.GothamBold
CloseButton.Text = "✕"
CloseButton.TextColor3 = Color3.fromRGB(255, 51, 51)
CloseButton.TextSize = 18
CloseButton.AutoButtonColor = false

-- Functions
local function UpdateStatus(text, color)
    StatusLabel.Text = text
    StatusLabel.TextColor3 = color or Color3.fromRGB(200, 200, 200)
end

local function SendNotification(title, text, duration)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title,
            Text = text,
            Duration = duration or 5
        })
    end)
end

local function AnimateButton(button)
    button.MouseEnter:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.2), {
            BackgroundColor3 = Color3.fromRGB(math.min(button.BackgroundColor3.R * 255 + 20, 255), 
                                             math.min(button.BackgroundColor3.G * 255 + 20, 255), 
                                             math.min(button.BackgroundColor3.B * 255 + 20, 255))
        }):Play()
    end)
    
    button.MouseLeave:Connect(function()
        local originalColor = button.Name == "SubmitButton" and Color3.fromRGB(194, 3, 38) or Color3.fromRGB(60, 60, 60)
        TweenService:Create(button, TweenInfo.new(0.2), {
            BackgroundColor3 = originalColor
        }):Play()
    end)
end

local function CheckKeyStatus(key)
    UpdateStatus("Checking key status...", Color3.fromRGB(255, 200, 0))
    
    local success, response = pcall(function()
        return HttpService:RequestAsync({
            Url = API_URL .. "/check-key",
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json"
            },
            Body = HttpService:JSONEncode({
                key = key
            })
        })
    end)
    
    if not success then
        UpdateStatus("Connection error!", Color3.fromRGB(255, 51, 51))
        SendNotification("Error", "Failed to connect to server")
        return
    end
    
    local data = HttpService:JSONDecode(response.Body)
    
    if data.valid then
        local statusText = string.format(
            "✅ Key is VALID!\n" ..
            "⏰ Time left: %d hours, %d minutes\n" ..
            "🔒 HWID: %s\n" ..
            "📅 Expires: %s",
            data.timeLeft.hours,
            data.timeLeft.minutes,
            data.boundTo or "Not bound yet",
            data.formatted.expires
        )
        UpdateStatus(statusText, Color3.fromRGB(51, 255, 51))
        SendNotification("Key Status", "Key is valid! ✅")
    else
        local messages = {
            no_key = "No key provided",
            invalid = "Key does not exist or is invalid",
            expired = "Key has expired",
            revoked = "Key has been revoked"
        }
        local displayMsg = messages[data.reason] or data.message
        UpdateStatus("❌ " .. displayMsg, Color3.fromRGB(255, 51, 51))
        SendNotification("Key Status", displayMsg)
    end
end

local function VerifyKey(key)
    UpdateStatus("Verifying key with HWID...", Color3.fromRGB(255, 200, 0))
    
    local success, response = pcall(function()
        return HttpService:RequestAsync({
            Url = API_URL .. "/verify",
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json"
            },
            Body = HttpService:JSONEncode({
                key = key,
                hwid = HWID
            })
        })
    end)
    
    if not success then
        UpdateStatus("Connection error!", Color3.fromRGB(255, 51, 51))
        SendNotification("Error", "Failed to connect to server")
        return false
    end
    
    local data = HttpService:JSONDecode(response.Body)
    
    if data.status == true then
        UpdateStatus("✅ Key verified! Loading script...", Color3.fromRGB(51, 255, 51))
        SendNotification("Success", "Key verified successfully!")
        return data.token
    else
        local errorMsg = data.reason or "Unknown error"
        local messages = {
            no_key = "No key provided",
            invalid = "Invalid key",
            expired = "Key has expired",
            hwid_mismatch = "Key is bound to another HWID"
        }
        
        local displayMsg = messages[errorMsg] or errorMsg
        UpdateStatus("❌ Verification failed: " .. displayMsg, Color3.fromRGB(255, 51, 51))
        SendNotification("Error", displayMsg)
        return false
    end
end

local function LoadScript(token)
    local success, response = pcall(function()
        return HttpService:RequestAsync({
            Url = SCRIPT_URL .. "?token=" .. HttpService:UrlEncode(token),
            Method = "GET",
            Headers = {
                ["Content-Type"] = "text/plain"
            }
        })
    end)
    
    if success and response.StatusCode == 200 then
        local scriptContent = response.Body
        local cleanScript = scriptContent:match("%-%-.-\n(.*)") or scriptContent
        
        local loadSuccess, loadError = pcall(function()
            local func, err = loadstring(cleanScript)
            if not func then
                error("Failed to compile script: " .. tostring(err))
            end
            func()
        end)
        
        if loadSuccess then
            UpdateStatus("✅ Script loaded successfully!", Color3.fromRGB(51, 255, 51))
            SendNotification("Success", "Script executed!")
            wait(2)
            ScreenGui:Destroy()
        else
            UpdateStatus("❌ Failed to load script!", Color3.fromRGB(255, 51, 51))
            SendNotification("Error", "Script error: " .. tostring(loadError))
        end
    else
        local errorMsg = success and ("HTTP " .. response.StatusCode) or "Connection failed"
        UpdateStatus("❌ Failed to download script!", Color3.fromRGB(255, 51, 51))
        SendNotification("Error", errorMsg)
    end
end

-- Button Animations
AnimateButton(SubmitButton)
AnimateButton(GetKeyButton)
AnimateButton(CheckKeyButton)

-- Button Functions
SubmitButton.MouseButton1Click:Connect(function()
    local key = KeyBox.Text:gsub("%s+", "")
    
    if key == "" then
        UpdateStatus("❌ Please enter a key!", Color3.fromRGB(255, 51, 51))
        return
    end
    
    local token = VerifyKey(key)
    if token then
        if writefile then
            writefile("vicat_key.txt", key)
        end
        wait(1)
        LoadScript(token)
    end
end)

GetKeyButton.MouseButton1Click:Connect(function()
    local keyUrl = API_URL .. "/docs"
    if setclipboard then
        setclipboard(keyUrl)
        SendNotification("Copied!", "Key link copied to clipboard!")
        UpdateStatus("📋 Link copied: " .. keyUrl, Color3.fromRGB(51, 255, 51))
    else
        SendNotification("Get Key", "Visit: " .. keyUrl)
        UpdateStatus("🔗 Get key at: " .. keyUrl, Color3.fromRGB(255, 200, 0))
    end
end)

CheckKeyButton.MouseButton1Click:Connect(function()
    local key = KeyBox.Text:gsub("%s+", "")
    
    if key == "" then
        UpdateStatus("❌ Please enter a key to check!", Color3.fromRGB(255, 51, 51))
        return
    end
    
    CheckKeyStatus(key)
end)

CloseButton.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

-- Auto-load saved key
if readfile and isfile and isfile("vicat_key.txt") then
    local savedKey = readfile("vicat_key.txt")
    KeyBox.Text = savedKey
    UpdateStatus("💾 Saved key loaded", Color3.fromRGB(51, 255, 51))
    
    wait(0.5)
    local token = VerifyKey(savedKey)
    if token then
        wait(1)
        LoadScript(token)
    end
end

-- Add to GUI
pcall(function()
    ScreenGui.Parent = CoreGui
end)

if not ScreenGui.Parent then
    ScreenGui.Parent = player:WaitForChild("PlayerGui")

end
