-- Anti-duplicate check
if _G.VicatRunning then
    warn("⚠️ Vicat-Chest đang chạy rồi! Vui lòng không bật nữa!")
    return
end
_G.VicatRunning = true

-- Game Check
local allowedPlaceIds = {2753915549, 4442272183, 7449423635}
local currentPlaceId = game.PlaceId
local isValidGame = false

for _, placeId in pairs(allowedPlaceIds) do
    if currentPlaceId == placeId then
        isValidGame = true
        break
    end
end

if not isValidGame then
    warn("❌ PlaceId hiện tại: " .. currentPlaceId)
    wait(1)
    kick("❌ SCRIPT CHỈ HOẠT ĐỘNG TRONG BLOX FRUITS!")
    return
end

local q = game.Players.LocalPlayer
local S = q
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")

-- Create folder for settings
local folderName = "Vicat Hub"
if not isfolder(folderName) then
    makefolder(folderName)
end

-- File paths
local settingsFile = folderName.."/ChestSettings.json"
local serverListFile = folderName.."/ServerList.json"

-- Settings
local settings = {
    FarmChestBypass = false,
    FarmChestTween = false,
    AutoSummonDarkbeard = false,
    Team = "Marines",
    InvisibleCharacter = false,
    ClearMap = false,
    AutoCleanLag = false,
    AutoHopChestCount = false,
    ChestCountToHop = 35
}

-- Get current date key for server list (GMT+8)
local function GetDateKey()
    local timestamp = os.time() + (8 * 3600) -- GMT+8
    local date = os.date("*t", timestamp)
    return string.format("%04d-%02d-%02d", date.year, date.month, date.day)
end

-- Server List Management
local serverList = {}

local function LoadServerList()
    if isfile and readfile and isfile(serverListFile) then
        local success, data = pcall(function()
            return HttpService:JSONDecode(readfile(serverListFile))
        end)
        if success and data then
            local currentDate = GetDateKey()
            -- Only load today's data
            if data[currentDate] then
                serverList = data[currentDate]
            else
                serverList = {}
            end
        end
    end
end

local function SaveServerList()
    if writefile then
        local currentDate = GetDateKey()
        local allData = {}
        
        -- Load existing data
        if isfile(serverListFile) then
            pcall(function()
                allData = HttpService:JSONDecode(readfile(serverListFile))
            end)
        end
        
        -- Save only today's data, remove old dates
        allData = {[currentDate] = serverList}
        
        writefile(serverListFile, HttpService:JSONEncode(allData))
    end
end

local function BlacklistServer(serverId)
    serverList[serverId] = true
    SaveServerList()
end

local function IsServerBlacklisted(serverId)
    return serverList[serverId] == true
end

LoadServerList()

-- Load/Save Settings
local function LoadSettings()
    if isfile and readfile and isfile(settingsFile) then
        local success, data = pcall(function()
            return HttpService:JSONDecode(readfile(settingsFile))
        end)
        if success then
            for k, v in pairs(data) do
                settings[k] = v
            end
        end
    end
end

local function SaveSettings()
    if writefile then
        writefile(settingsFile, HttpService:JSONEncode(settings))
    end
end

LoadSettings()

-- Set Team
local function SetTeam()
    pcall(function()
        ReplicatedStorage.Remotes.CommF_:InvokeServer("SetTeam", settings.Team)
    end)
end

if not q.Character then
    SetTeam()
    q.CharacterAdded:Wait()
end

-- Load UI
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local Window = Fluent:CreateWindow({
    Title = "Vicat Hub - Chest Farm",
    SubTitle = "By Meo_Curse",
    TabWidth = 160,
    Theme = "Dark",
    Acrylic = false,
    Size = UDim2.fromOffset(500, 350),
    MinimizeKey = Enum.KeyCode.End
})

local Tabs = {
    Main = Window:AddTab({Title = "Main Features"}),
    Visual = Window:AddTab({Title = "Visual"}),
    Settings = Window:AddTab({Title = "Settings"})
}

-- Variables
local IsFightingDarkbeard = false
local ChestSkipList = {}
local AutoJumpEnabled = false
local AutoResetEnabled = false
local G = false -- Invisible Character state
local CurrentTween = nil -- Store current tween
local ChestCollectedCount = 0 -- Chest counter

-- Clean Lag Function
local function cleanlag()
    if _G.Fixlag then
        warn("⚠️ Giảm Lag đã chạy rồi! Vui lòng không bật nữa!")
        return
    end
    _G.Fixlag = true
    
    spawn(function()
        for v1392, v1393 in pairs(workspace:GetDescendants()) do
            if ((v1393.ClassName == "Part") or (v1393.ClassName == "SpawnLocation") or (v1393.ClassName == "WedgePart") or (v1393.ClassName == "Terrain")) then
                v1393.Material = "Plastic"
            end
        end
        for v1394, v1395 in pairs(game:GetDescendants()) do
            if v1395:IsA("Texture") then
                v1395.Texture = ""
            elseif v1395:IsA("BasePart") then
                v1395.Material = "Plastic"
            end
        end
        for v1396, v1397 in pairs(game.Players.LocalPlayer.PlayerScripts:GetDescendants()) do
            local v1398 = {
                "RecordMode",
                "Fireflies",
                "Wind",
                "WindShake",
                "WindLines",
                "WaterBlur",
                "WaterEffect",
                "wave",
                "WaterColorCorrection",
                "WaterCFrame",
                "MirageFog",
                "MobileButtonTransparency",
                "WeatherStuff",
                "AnimateEntrance",
                "Particle",
                "AccessoryInvisible"
            }
            if table.find(v1398, v1397.Name) then
                v1397:Destroy()
            end
        end
        print("✅ Clean Lag hoàn tất!")
    end)
end

-- Invisible Character Function
local function t(isInvisible)
    if S.Character then
        for _, f in ipairs(S.Character:GetDescendants()) do
            if f:IsA("BasePart") or f:IsA("Decal") then
                f.LocalTransparencyModifier = isInvisible and 1 or 0
            end
        end
    end
end

S.CharacterAdded:Connect(function(char)
    char:WaitForChild("HumanoidRootPart")
    task.wait(.2)
    if G then
        t(true)
    end
    -- Tự động bật Invisible Character sau khi respawn nếu đã bật
    if settings.InvisibleCharacter then
        t(true)
    end
end)

-- Clear Map Function
local function UN(isClear)
    for _, f in ipairs(workspace:GetDescendants()) do
        if f:IsA("BasePart") or f:IsA("Decal") then
            if not f:IsDescendantOf(S.Character) then
                f.LocalTransparencyModifier = isClear and 1 or 0
            end
        end
    end
end

-- Attack System
if not _G.AutoAttackRunning then
    _G.AutoAttackRunning = true
    
    local Enemies = workspace:WaitForChild("Enemies")
    local Modules = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Net")
    local RegisterAttack = Modules:FindFirstChild("RE/RegisterAttack") or Modules:FindFirstChild("RegisterAttack")
    local RegisterHit = Modules:FindFirstChild("RE/RegisterHit") or Modules:FindFirstChild("RegisterHit")
    
    _G.AutoClickInterval = 0.5
    _G.AutoM1Enabled = true
    
    local function HasWeaponEquipped()
        if not q.Character then return false end
        for _, child in pairs(q.Character:GetChildren()) do
            if child:IsA("Tool") then
                return true
            end
        end
        return false
    end
    
    local function HitEnemies()
        if not HasWeaponEquipped() then return end
        if not IsFightingDarkbeard and not Enemies:FindFirstChild("Darkbeard") then return end
        
        local hitTargets = {}
        for _, npc in pairs(Enemies:GetChildren()) do
            if npc:FindFirstChild("Humanoid") and npc.Humanoid.Health > 0 then
                local targetPart = npc:FindFirstChild("HumanoidRootPart") or npc:FindFirstChildWhichIsA("BasePart")
                if targetPart then
                    table.insert(hitTargets, {npc, targetPart})
                end
            end
        end
        
        if #hitTargets > 0 and RegisterHit then
            pcall(function()
                RegisterHit:FireServer(hitTargets[1][2], hitTargets, "default_code")
            end)
        end
    end
    
    task.spawn(function()
        while _G.AutoAttackRunning and task.wait(0.075) do
            HitEnemies()
        end
    end)
    
    task.spawn(function()
        while _G.AutoAttackRunning do
            if _G.AutoM1Enabled and RegisterAttack and HasWeaponEquipped() and (IsFightingDarkbeard or Enemies:FindFirstChild("Darkbeard")) then
                pcall(function()
                    RegisterAttack:FireServer()
                end)
            end
            task.wait(tonumber(_G.AutoClickInterval) or 0.5)
        end
    end)
end

-- Auto Jump
task.spawn(function()
    while task.wait(0.55) do
        if AutoJumpEnabled and not IsFightingDarkbeard and q.Character and q.Character:FindFirstChildOfClass("Humanoid") then
            q.Character:FindFirstChildOfClass("Humanoid"):ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)

-- Auto Reset
task.spawn(function()
    while task.wait(13) do
        if AutoResetEnabled and not IsFightingDarkbeard and q.Character and q.Character:FindFirstChild("Humanoid") then
            q.Character.Humanoid.Health = 0
        end
    end
end)

-- Set Team Loop
task.spawn(function()
    while task.wait(5) do
        if settings.FarmChestBypass and not IsFightingDarkbeard then
            SetTeam()
        end
    end
end)

-- Green Highlight (chỉ bật khi có farm hoạt động)
local function ApplyHighlight(char)
    if not char then return end
    if char:FindFirstChild("GreenAura") then char.GreenAura:Destroy() end
    
    -- Chỉ tạo highlight nếu có tính năng farm đang bật
    if not (settings.FarmChestBypass or settings.FarmChestTween or settings.AutoSummonDarkbeard) then
        return
    end
    
    local h = Instance.new("Highlight")
    h.Name = "GreenAura"
    h.FillColor = Color3.fromRGB(255, 255, 0)
    h.OutlineColor = Color3.fromRGB(255, 255, 100)
    h.FillTransparency = .3
    h.OutlineTransparency = 0
    h.Parent = char
end

local function UpdateHighlight()
    if q.Character then
        ApplyHighlight(q.Character)
    end
end

if q.Character then ApplyHighlight(q.Character) end
q.CharacterAdded:Connect(function(char)
    char:WaitForChild("HumanoidRootPart")
    task.wait(1)
    ApplyHighlight(char)
end)

-- Tween Function (Fix camera)
local function Tween(targetCFrame, speed)
    speed = speed or 350
    if not q.Character or not q.Character:FindFirstChild("HumanoidRootPart") then return end
    
    local hrp = q.Character.HumanoidRootPart
    local distance = (targetCFrame.Position - hrp.Position).Magnitude
    local duration = distance / speed
    
    local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear)
    local tween = TweenService:Create(hrp, tweenInfo, {CFrame = targetCFrame})
    
    -- Fix camera bị tuột
    hrp.CFrame = CFrame.new(hrp.Position, targetCFrame.Position)
    
    CurrentTween = tween -- Store tween
    tween:Play()
    return tween
end

-- Chest Functions
local function GetCharacter()
    if not q.Character then q.CharacterAdded:Wait() end
    q.Character:WaitForChild("HumanoidRootPart")
    return q.Character
end

local function SortChestsByDistance(chestList)
    local hrp = GetCharacter().HumanoidRootPart
    table.sort(chestList, function(a, b)
        return (hrp.Position - a.Position).Magnitude < (hrp.Position - b.Position).Magnitude
    end)
end

local chestCache, cacheBuilt = {}, false
local function GetActiveChests()
    if not cacheBuilt then
        cacheBuilt = true
        for _, obj in pairs(game:GetDescendants()) do
            if obj.Name:find("Chest") and obj.ClassName == "Part" then
                table.insert(chestCache, obj)
            end
        end
    end
    
    local activeChests = {}
    for _, chest in pairs(chestCache) do
        if chest:FindFirstChild("TouchInterest") and not ChestSkipList[chest] then
            table.insert(activeChests, chest)
        end
    end
    SortChestsByDistance(activeChests)
    return activeChests
end

task.spawn(function()
    while task.wait(5) do
        ChestSkipList = {}
    end
end)

local function DisableCollision(state)
    for _, part in pairs(GetCharacter():GetChildren()) do
        if part:IsA("BasePart") then
            part.CanCollide = not state
        end
    end
end

-- Farm Chest Bypass
local function FarmChestBypass(targetCFrame, targetChest)
    -- Kiểm tra nếu có Fist of Darkness và boss tồn tại
    if HasFistOfDarkness() then
        if settings.AutoSummonDarkbeard and DarkbeardExists() then
            warn("🔥 Phát hiện Darkbeard! Chuyển sang đánh boss...")
            IsFightingDarkbeard = true
            return true
        end
        
        -- Nếu có Fist nhưng chưa triệu hồi
        if settings.AutoSummonDarkbeard and not DarkbeardExists() then
            warn("⚡ Phát hiện Fist of Darkness! Bắt đầu triệu hồi...")
            IsFightingDarkbeard = true
            SummonDarkbeard()
            IsFightingDarkbeard = false
            return true
        end
    end
    
    local hrp = GetCharacter().HumanoidRootPart
    DisableCollision(true)
    
    -- TP liên tục mỗi 0.1s để tránh lệch vị trí
    local waitStartTime = tick()
    local maxWaitTime = 5
    local initialTouch = targetChest:FindFirstChild("TouchInterest")
    
    while tick() - waitStartTime < maxWaitTime do
        -- Kiểm tra boss spawn trong lúc farm
        if settings.AutoSummonDarkbeard and DarkbeardExists() then
            warn("🔥 Darkbeard xuất hiện! Chuyển sang đánh boss...")
            DisableCollision(false)
            IsFightingDarkbeard = true
            return true
        end
        
        -- TP liên tục đến chest
        hrp.CFrame = targetCFrame + Vector3.new(0, 3, 0)
        
        -- Kiểm tra chest đã biến mất chưa
        if not targetChest:FindFirstChild("TouchInterest") or not targetChest.Parent then
            DisableCollision(false)
            
            -- Chỉ đếm nếu chest thực sự biến mất (đã nhặt)
            if initialTouch then
                ChestCollectedCount = ChestCollectedCount + 1
                warn("📦 Chest collected: " .. ChestCollectedCount .. "/" .. settings.ChestCountToHop)
                
                -- Check hop condition
                if settings.AutoHopChestCount and ChestCollectedCount >= settings.ChestCountToHop then
                    warn("✅ Đã nhặt đủ " .. settings.ChestCountToHop .. " chest! Đang hop server...")
                    ChestCollectedCount = 0
                    task.wait(1)
                    HopServer()
                end
            end
            
            return true
        end
        
        task.wait(0.1)
    end
    
    DisableCollision(false)
    return false
end

-- Farm Chest Tween
local function FarmChestTween(targetCFrame, targetChest)
    -- Kiểm tra nếu có Fist of Darkness và boss tồn tại
    if HasFistOfDarkness() and settings.AutoSummonDarkbeard and DarkbeardExists() then
        warn("🔥 Phát hiện Darkbeard! Chuyển sang đánh boss...")
        IsFightingDarkbeard = true
        return true
    end
    
    local hrp = GetCharacter().HumanoidRootPart
    local distance = (targetCFrame.Position - hrp.Position).Magnitude
    local tpDistance = 250
    local initialTouch = targetChest:FindFirstChild("TouchInterest")
    
    if distance <= tpDistance then
        -- TP liên tục mỗi 0.5s để tránh lệch vị trí
        local waitStartTime = tick()
        local maxWaitTime = 5
        
        while tick() - waitStartTime < maxWaitTime do
            -- Kiểm tra boss spawn trong lúc farm
            if settings.AutoSummonDarkbeard and DarkbeardExists() then
                warn("🔥 Darkbeard xuất hiện! Chuyển sang đánh boss...")
                IsFightingDarkbeard = true
                return true
            end
            
            -- TP liên tục đến chest
            hrp.CFrame = targetCFrame + Vector3.new(0, 3, 0)
            
            -- Kiểm tra chest đã biến mất chưa
            if not targetChest:FindFirstChild("TouchInterest") or not targetChest.Parent then
                -- Chỉ đếm nếu chest thực sự biến mất
                if initialTouch then
                    ChestCollectedCount = ChestCollectedCount + 1
                    warn("📦 Chest collected: " .. ChestCollectedCount .. "/" .. settings.ChestCountToHop)
                    
                    if settings.AutoHopChestCount and ChestCollectedCount >= settings.ChestCountToHop then
                        warn("✅ Đã nhặt đủ " .. settings.ChestCountToHop .. " chest! Đang hop server...")
                        ChestCollectedCount = 0
                        task.wait(1)
                        HopServer()
                    end
                end
                return true
            end
            
            task.wait(0.5)
        end
    else
        local tween = Tween(targetCFrame, 350)
        
        while true do
            -- Kiểm tra boss spawn trong lúc tween
            if settings.AutoSummonDarkbeard and DarkbeardExists() then
                if tween then tween:Cancel() end
                warn("🔥 Darkbeard xuất hiện! Chuyển sang đánh boss...")
                IsFightingDarkbeard = true
                return true
            end
            
            local currentDist = (hrp.Position - targetCFrame.Position).Magnitude
            if currentDist <= tpDistance then
                if tween then tween:Cancel() end
                
                -- TP liên tục mỗi 0.5s sau khi đến gần
                local waitStartTime = tick()
                local maxWaitTime = 5
                
                while tick() - waitStartTime < maxWaitTime do
                    -- Kiểm tra boss spawn
                    if settings.AutoSummonDarkbeard and DarkbeardExists() then
                        warn("🔥 Darkbeard xuất hiện! Chuyển sang đánh boss...")
                        IsFightingDarkbeard = true
                        return true
                    end
                    
                    hrp.CFrame = targetCFrame + Vector3.new(0, 3, 0)
                    
                    if not targetChest:FindFirstChild("TouchInterest") or not targetChest.Parent then
                        -- Chỉ đếm nếu chest thực sự biến mất
                        if initialTouch then
                            ChestCollectedCount = ChestCollectedCount + 1
                            warn("📦 Chest collected: " .. ChestCollectedCount .. "/" .. settings.ChestCountToHop)
                            
                            if settings.AutoHopChestCount and ChestCollectedCount >= settings.ChestCountToHop then
                                warn("✅ Đã nhặt đủ " .. settings.ChestCountToHop .. " chest! Đang hop server...")
                                ChestCollectedCount = 0
                                task.wait(1)
                                HopServer()
                            end
                        end
                        return true
                    end
                    
                    task.wait(0.5)
                end
                
                break
            end
            
            if not targetChest:FindFirstChild("TouchInterest") or not targetChest.Parent then
                if tween then tween:Cancel() end
                -- Chỉ đếm nếu chest thực sự biến mất
                if initialTouch then
                    ChestCollectedCount = ChestCollectedCount + 1
                    warn("📦 Chest collected: " .. ChestCollectedCount .. "/" .. settings.ChestCountToHop)
                    
                    if settings.AutoHopChestCount and ChestCollectedCount >= settings.ChestCountToHop then
                        warn("✅ Đã nhặt đủ " .. settings.ChestCountToHop .. " chest! Đang hop server...")
                        ChestCollectedCount = 0
                        task.wait(1)
                        HopServer()
                    end
                end
                return true
            end
            
            task.wait(0.1)
        end
    end
    
    return false
end

-- Main Farm Loops
local function StartFarmBypass()
    task.spawn(function()
        while task.wait() do
            if settings.FarmChestBypass and not IsFightingDarkbeard then
                local chests = GetActiveChests()
                if #chests > 0 then
                    FarmChestBypass(chests[1].CFrame, chests[1])
                else
                    HopServer()
                    break
                end
            end
        end
    end)
end

local function StartFarmTween()
    task.spawn(function()
        while task.wait() do
            if settings.FarmChestTween and not IsFightingDarkbeard then
                local chests = GetActiveChests()
                if #chests > 0 then
                    FarmChestTween(chests[1].CFrame, chests[1])
                else
                    break
                end
            end
        end
    end)
end

-- Server Hop
local s = game.PlaceId
local u, O = {}, ""
local currentServerId = game.JobId

BlacklistServer(currentServerId)

function HopServer()
    if IsFightingDarkbeard then return end
    
    local serverData
    if O == "" then
        serverData = HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/"..s.."/servers/Public?sortOrder=Asc&limit=100"))
    else
        serverData = HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/"..s.."/servers/Public?sortOrder=Asc&limit=100&cursor="..O))
    end
    if serverData.nextPageCursor and serverData.nextPageCursor ~= "null" then
        O = serverData.nextPageCursor
    end
    for _, server in pairs(serverData.data) do
        local serverId = tostring(server.id)
        if tonumber(server.playing) < tonumber(server.maxPlayers) and not IsServerBlacklisted(serverId) then
            local isUsed = false
            for _, usedId in pairs(u) do
                if serverId == tostring(usedId) then
                    isUsed = true
                    break
                end
            end
            if not isUsed then
                table.insert(u, serverId)
                pcall(function()
                    task.wait(3)
                    game:GetService("TeleportService"):TeleportToPlaceInstance(s, serverId, q)
                end)
                task.wait(4)
            end
        end
    end
end

-- Darkbeard System
local function CheckAndSummonDarkbeard()
    task.spawn(function()
        while task.wait(2) do
            if settings.AutoSummonDarkbeard then
                local bp = q.Backpack
                local char = q.Character
                local darkbeard = workspace.Enemies:FindFirstChild("Darkbeard")
                
                if darkbeard and darkbeard:FindFirstChild("Humanoid") and darkbeard.Humanoid.Health > 0 then
                    IsFightingDarkbeard = true
                    
                    repeat
                        task.wait()
                        if char and char:FindFirstChild("HumanoidRootPart") and darkbeard.Parent then
                            for _, tool in pairs(bp:GetChildren()) do
                                if tool:IsA("Tool") and tool.ToolTip == "Melee" then
                                    tool.Parent = char
                                    break
                                end
                            end
                            
                            local targetPos = darkbeard.HumanoidRootPart.CFrame * CFrame.new(0, 15, 0)
                            Tween(targetPos, 350)
                        end
                    until not darkbeard.Parent or darkbeard.Humanoid.Health <= 0 or not settings.AutoSummonDarkbeard
                    
                    task.wait(2)
                    
                    -- Chỉ hop khi Darkbeard chết 100%
                    if darkbeard.Parent and darkbeard:FindFirstChild("Humanoid") and darkbeard.Humanoid.Health <= 0 then
                        warn("✅ Darkbeard đã chết! Đang hop server...")
                        task.wait(1)
                        IsFightingDarkbeard = false
                        HopServer()
                    elseif not char or not char:FindFirstChild("Humanoid") or char.Humanoid.Health <= 0 then
                        warn("❌ Bạn đã chết khi đánh Darkbeard! Blacklist server hôm nay.")
                        BlacklistServer(currentServerId)
                        IsFightingDarkbeard = false
                        HopServer()
                    else
                        IsFightingDarkbeard = false
                    end
                    
                elseif (bp and bp:FindFirstChild("Fist of Darkness")) or (char and char:FindFirstChild("Fist of Darkness")) then
                    IsFightingDarkbeard = true
                    
                    if bp:FindFirstChild("Fist of Darkness") then
                        bp:FindFirstChild("Fist of Darkness").Parent = char
                    end
                    
                    if game.PlaceId == 4442272183 then
                        local summonPos = CFrame.new(3777.13, 24.97, -3499.81)
                        if char and char:FindFirstChild("HumanoidRootPart") then
                            Tween(summonPos, 350)
                            task.wait(2)
                            
                            game:GetService("VirtualInputManager"):SendMouseButtonEvent(0, 0, 0, true, game, 0)
                            task.wait(0.1)
                            game:GetService("VirtualInputManager"):SendMouseButtonEvent(0, 0, 0, false, game, 0)
                            
                            task.wait(3)
                        end
                    end
                    
                    IsFightingDarkbeard = false
                end
            end
        end
    end)
end

-- GUI
Tabs.Main:AddDropdown("TeamSelect", {
    Title = "Select Team",
    Values = {"Marines", "Pirates"},
    Default = settings.Team,
    Callback = function(Value)
        settings.Team = Value
        SaveSettings()
        SetTeam()
    end
})

Tabs.Main:AddToggle("FarmBypass", {
    Title = "Farm Chest (Bypass)",
    Description = "TP liên tục tới chest",
    Default = settings.FarmChestBypass,
    Callback = function(Value)
        settings.FarmChestBypass = Value
        if Value then
            settings.FarmChestTween = false
            AutoJumpEnabled = true
            AutoResetEnabled = true
            StartFarmBypass()
        else
            AutoJumpEnabled = false
            AutoResetEnabled = false
        end
        UpdateHighlight()
        SaveSettings()
    end
})

Tabs.Main:AddToggle("FarmTween", {
    Title = "Farm Chest (Tween)",
    Description = "Tween tới chest",
    Default = settings.FarmChestTween,
    Callback = function(Value)
        settings.FarmChestTween = Value
        if Value then
            settings.FarmChestBypass = false
            AutoJumpEnabled = true
            StartFarmTween()
        else
            AutoJumpEnabled = false
        end
        UpdateHighlight()
        SaveSettings()
    end
})

Tabs.Main:AddToggle("AutoDarkbeard", {
    Title = "Auto Summon & Farm Darkbeard",
    Description = "Tự động triệu hồi và đánh boss",
    Default = settings.AutoSummonDarkbeard,
    Callback = function(Value)
        settings.AutoSummonDarkbeard = Value
        UpdateHighlight()
        SaveSettings()
        if Value then CheckAndSummonDarkbeard() end
    end
})

-- Visual Tab
Tabs.Visual:AddToggle("InvisibleChar", {
    Title = "Invisible Character",
    Description = "Làm nhân vật trong suốt (chỉ bạn thấy)",
    Default = settings.InvisibleCharacter,
    Callback = function(Value)
        settings.InvisibleCharacter = Value
        G = Value
        t(Value)
        SaveSettings()
    end
})

Tabs.Visual:AddToggle("ClearMap", {
    Title = "Clear Map",
    Description = "Làm map trong suốt (chỉ bạn thấy)",
    Default = settings.ClearMap,
    Callback = function(Value)
        settings.ClearMap = Value
        UN(Value)
        SaveSettings()
    end
})

Tabs.Visual:AddButton({
    Title = "Clean Lag",
    Description = "Xóa hiệu ứng & texture để giảm lag",
    Callback = function()
        cleanlag()
    end
})

Tabs.Visual:AddToggle("AutoCleanLag", {
    Title = "Auto Clean Lag (On Hop)",
    Description = "Tự động clean lag khi hop server",
    Default = settings.AutoCleanLag,
    Callback = function(Value)
        settings.AutoCleanLag = Value
        SaveSettings()
    end
})

Tabs.Visual:AddButton({
    Title = "Stop Tween",
    Description = "Dừng tween đang chạy",
    Callback = function()
        if CurrentTween then
            CurrentTween:Cancel()
            warn("⏹️ Đã dừng tween!")
        else
            warn("⚠️ Không có tween nào đang chạy!")
        end
    end
})

-- Settings Tab
Tabs.Settings:AddToggle("AutoHopChest", {
    Title = "Auto Hop After X Chests",
    Description = "Tự động hop khi nhặt đủ số chest",
    Default = settings.AutoHopChestCount,
    Callback = function(Value)
        settings.AutoHopChestCount = Value
        if not Value then
            ChestCollectedCount = 0
        end
        SaveSettings()
    end
})

Tabs.Settings:AddInput("ChestCount", {
    Title = "Chest Count to Hop",
    Description = "Số chest cần nhặt trước khi hop",
    Default = tostring(settings.ChestCountToHop),
    Placeholder = "35",
    Numeric = true,
    Finished = true,
    Callback = function(Value)
        local num = tonumber(Value)
        if num and num > 0 then
            settings.ChestCountToHop = num
            SaveSettings()
            warn("✅ Đã set chest count: " .. num)
        end
    end
})

Tabs.Settings:AddButton({
    Title = "Reset Chest Counter",
    Description = "Reset bộ đếm chest về 0",
    Callback = function()
        ChestCollectedCount = 0
        warn("✅ Đã reset chest counter!")
    end
})

Tabs.Settings:AddButton({
    Title = "Reset Settings",
    Callback = function()
        settings.FarmChestBypass = false
        settings.FarmChestTween = false
        settings.AutoSummonDarkbeard = false
        settings.InvisibleCharacter = false
        settings.ClearMap = false
        AutoJumpEnabled = false
        AutoResetEnabled = false
        G = false
        t(false)
        UN(false)
        UpdateHighlight()
        if delfile then
            if isfile(settingsFile) then delfile(settingsFile) end
            if isfile(serverListFile) then delfile(serverListFile) end
        end
        warn("✅ Settings đã được reset!")
    end
})

Tabs.Settings:AddParagraph({
    Title = "Thông tin",
    Content = "- Luôn ưu tiên chest GẦN NHẤT\n- Server blacklist THEO NGÀY (GMT+8)\n- Darkbeard chết 100% mới hop\n- Chết khi đánh: blacklist cả ngày\n- Bypass: TP 0.1s liên tục\n- Tween: TP 0.5s liên tục khi gần\n- Tốc độ: 350 studs/s | TP: 300 studs\n- GreenAura: Chỉ bật khi farm\n- Auto detect Fist & Boss\n- Auto hop sau X chest (mặc định 35)"
})

-- Auto start
if settings.FarmChestBypass then
    AutoJumpEnabled = true
    AutoResetEnabled = true
    StartFarmBypass()
end
if settings.FarmChestTween then
    AutoJumpEnabled = true
    StartFarmTween()
end
if settings.AutoSummonDarkbeard then
    CheckAndSummonDarkbeard()
end
if settings.InvisibleCharacter then
    G = true
    t(true)
end
if settings.ClearMap then
    UN(true)
end
if settings.AutoCleanLag then
    task.wait(2)
    cleanlag()
end

q.CharacterAdded:Connect(function()
    task.wait()
    -- Auto clean lag nếu bật
    if settings.AutoCleanLag then
        task.wait(2)
        cleanlag()
    end
    if settings.FarmChestBypass and not IsFightingDarkbeard then StartFarmBypass() end
    if settings.FarmChestTween and not IsFightingDarkbeard then StartFarmTween() end
end)

repeat task.wait(2) until game:IsLoaded()
print("✅ Vicat Hub loaded successfully!")
