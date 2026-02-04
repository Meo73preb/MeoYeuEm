-- Stealth Auto Attack Script
-- Mỗi attack chỉ random 1 part cho tất cả enemies

_G.FastAttackEnabled = true

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()

-- Config
local AttackConfig = {
    Cooldown = 0.05,
    MaxDistance = 60,
    RandomDelay = true,
}

local lastAttackTime = 0

-- Safely get modules
local function SafeGet(parent, ...)
    local current = parent
    for _, name in ipairs({...}) do
        if not current then return nil end
        current = current:FindFirstChild(name)
    end
    return current
end

-- Modules và Remotes
local Net = SafeGet(ReplicatedStorage, "Modules", "Net")
if not Net then
    warn("Cannot find Net module!")
    return
end

local RegisterAttack = SafeGet(Net, "RE/RegisterAttack")
local RegisterHit = SafeGet(Net, "RE/RegisterHit")

if not RegisterAttack or not RegisterHit then
    warn("Cannot find attack remotes!")
    return
end

-- Tìm encrypted remote
local encryptedRemote, encryptedId
local hasEncrypted = false

local function FindEncryptedRemote()
    local folders = {
        SafeGet(ReplicatedStorage, "Util"),
        SafeGet(ReplicatedStorage, "Common"),
        SafeGet(ReplicatedStorage, "Remotes"),
        SafeGet(ReplicatedStorage, "Assets"),
        SafeGet(ReplicatedStorage, "FX")
    }
    
    for _, folder in ipairs(folders) do
        if folder then
            for _, child in ipairs(folder:GetChildren()) do
                if child:IsA("RemoteEvent") and child:GetAttribute("Id") then
                    encryptedRemote = child
                    encryptedId = child:GetAttribute("Id")
                    hasEncrypted = true
                    return true
                end
            end
            
            folder.ChildAdded:Connect(function(child)
                task.wait(0.1)
                if child:IsA("RemoteEvent") and child:GetAttribute("Id") then
                    encryptedRemote = child
                    encryptedId = child:GetAttribute("Id")
                    hasEncrypted = true
                end
            end)
        end
    end
    return false
end

FindEncryptedRemote()

-- Hàm tạo unique ID
local function GenerateUniqueId()
    local userId = tostring(Player.UserId):sub(2, 4)
    local coroutineId = tostring(coroutine.running()):sub(11, 15)
    return userId .. coroutineId
end

-- Hàm kiểm tra character sống
local function IsAlive(char)
    if not char then return false end
    local humanoid = char:FindFirstChild("Humanoid")
    return humanoid and humanoid.Health > 0
end

-- Danh sách parts hợp lệ để random
local VALID_PARTS = {
    "Head", 
    "UpperTorso", 
    "LowerTorso",
    "RightUpperArm", 
    "RightLowerArm", 
    "RightHand",
    "LeftUpperArm", 
    "LeftLowerArm", 
    "LeftHand",
    "RightUpperLeg", 
    "RightLowerLeg", 
    "RightFoot",
    "LeftUpperLeg", 
    "LeftLowerLeg", 
    "LeftFoot"
}

-- Hàm random 1 part name
local function GetRandomPartName()
    return VALID_PARTS[math.random(1, #VALID_PARTS)]
end

-- Hàm kiểm tra max enemies dựa vào HumanoidRootPart size
local function GetMaxEnemies()
    local root = Character and Character:FindFirstChild("HumanoidRootPart")
    if not root then return 2 end
    
    -- Nếu HumanoidRootPart > 25 studs, có thể hit 12 enemies (Buddha form, v.v.)
    local size = root.Size
    local maxSize = math.max(size.X, size.Y, size.Z)
    
    if maxSize > 25 then
        return 12
    else
        return 2
    end
end

-- Hàm debug info
local function GetDebugInfo()
    local root = Character and Character:FindFirstChild("HumanoidRootPart")
    if not root then 
        return {
            maxEnemies = 2,
            rootSize = "N/A",
            largeForm = false
        }
    end
    
    local size = root.Size
    local maxSize = math.max(size.X, size.Y, size.Z)
    
    return {
        maxEnemies = maxSize > 25 and 12 or 2,
        rootSize = string.format("%.1f x %.1f x %.1f", size.X, size.Y, size.Z),
        maxDimension = string.format("%.1f", maxSize),
        largeForm = maxSize > 25
    }
end

-- Hàm lấy enemies gần
local function GetNearbyEnemies(maxDistance)
    local root = Character and Character:FindFirstChild("HumanoidRootPart")
    if not root then return {} end
    
    local enemies = {}
    local maxEnemies = GetMaxEnemies()
    
    for _, folder in ipairs({workspace.Enemies, workspace.Characters}) do
        if not folder then continue end
        
        for _, enemy in ipairs(folder:GetChildren()) do
            if enemy == Character then continue end
            
            local enemyRoot = enemy:FindFirstChild("HumanoidRootPart")
            local enemyHumanoid = enemy:FindFirstChild("Humanoid")
            
            if enemyRoot and enemyHumanoid and enemyHumanoid.Health > 0 then
                local distance = (root.Position - enemyRoot.Position).Magnitude
                
                if distance <= maxDistance then
                    table.insert(enemies, {
                        enemy = enemy,
                        distance = distance
                    })
                end
            end
        end
    end
    
    -- Sort by distance
    table.sort(enemies, function(a, b)
        return a.distance < b.distance
    end)
    
    -- Giới hạn số lượng enemies (2 hoặc 12)
    local limitedEnemies = {}
    for i = 1, math.min(#enemies, maxEnemies) do
        table.insert(limitedEnemies, enemies[i])
    end
    
    return limitedEnemies
end

-- Hàm kiểm tra weapon
local function IsValidWeapon()
    if not Character then return false end
    local tool = Character:FindFirstChildOfClass("Tool")
    if not tool then return false end
    local weaponType = tool:GetAttribute("WeaponType")
    return weaponType == "Melee" or weaponType == "Sword"
end

-- Main attack function
local function PerformAttack()
    if not _G.FastAttackEnabled then return end
    if not IsAlive(Character) then return end
    if not IsValidWeapon() then return end
    
    -- Check cooldown
    local currentTime = tick()
    local cooldown = AttackConfig.Cooldown
    
    if AttackConfig.RandomDelay then
        cooldown = cooldown + (math.random(0, 50) / 1000)
    end
    
    if currentTime - lastAttackTime < cooldown then
        return
    end
    
    local enemies = GetNearbyEnemies(AttackConfig.MaxDistance)
    if #enemies == 0 then return end
    
    -- QUAN TRỌNG: Random 1 part name cho lần attack này
    local randomPartName = GetRandomPartName()
    
    -- Build parts array với CÙNG 1 part name cho tất cả enemies
    local parts = {}
    local mainTarget = nil
    
    for _, enemyData in ipairs(enemies) do
        local enemy = enemyData.enemy
        local part = enemy:FindFirstChild(randomPartName)
        
        -- Nếu enemy không có part này, thử Head
        if not part then
            part = enemy:FindFirstChild("Head")
        end
        
        -- Nếu vẫn không có, thử HumanoidRootPart
        if not part then
            part = enemy:FindFirstChild("HumanoidRootPart")
        end
        
        if part then
            table.insert(parts, {enemy, part})
            if not mainTarget then
                mainTarget = part
            end
        end
    end
    
    if not mainTarget or #parts == 0 then return end
    
    local uniqueId = GenerateUniqueId()
    
 remote
                local encryptedName = string.gsub("RE/RegisterHit", ".", function(c)
                    return string.char(
                        bit32.bxor(
                            string.byte(c),
                            math.floor(workspace:GetServerTimeNow() / 10 % 10) + 1
                        )
                    )
                end)
                
                local encryptedIdValue = bit32.bxor(encryptedId + 909090, seed * 2)
                
                -- CHỈ fire encrypted remote
                encryptedRemote:FireServer(
                    encryptedName,
                    encryptedIdValue,
                    mainTarget,
                    parts
                )
            end
        else
            -- Game KHÔNG dùng encrypted, dùng RegisterHit bình thường
            RegisterAttack:FireServer()
            RegisterHit:FireServer(mainTarget, parts, {}, uniqueId)
        end
    end)
    
    if success then
        lastAttackTime = currentTime
    end
end

-- Attack loop
RunService.Heartbeat:Connect(function()
    if _G.FastAttackEnabled then
        PerformAttack()
    end
end)

-- Update character reference
Player.CharacterAdded:Connect(function(newChar)
    Character = newChar
    newChar:WaitForChild("HumanoidRootPart")
end)

-- Auto reconnect remotes khi server thay đổi
task.spawn(function()
    while true do
        task.wait(5)
        
        -- Kiểm tra encrypted remote
        if not hasEncrypted then
            hasEncrypted = FindEncryptedRemote()
        end
        
        if encryptedRemote and not encryptedRemote.Parent then
            encryptedRemote = nil
            encryptedId = nil
            hasEncrypted = false
            FindEncryptedRemote()
        end
        
        -- Kiểm tra RegisterHit
        if not RegisterHit or not RegisterHit.Parent then
            local success = pcall(function()
                RegisterHit = Net:WaitForChild("RE/RegisterHit", 5)
            end)
            if not success then
                warn("Cannot find RegisterHit!")
            end
        end
        
        -- Kiểm tra RegisterAttack
        if not RegisterAttack or not RegisterAttack.Parent then
            local success = pcall(function()
                RegisterAttack = Net:WaitForChild("RE/RegisterAttack", 5)
            end)
            if not success then
                warn("Cannot find RegisterAttack!")
            end
        end
    end
end)

-- Commands
_G.ToggleFastAttack = function()
    _G.FastAttackEnabled = not _G.FastAttackEnabled
    print("Fast Attack:", _G.FastAttackEnabled and "ENABLED ✓" or "DISABLED ✗")
end

_G.SetAttackConfig = function(config)
    for key, value in pairs(config) do
        if AttackConfig[key] ~= nil then
            AttackConfig[key] = value
            print(key .. " set to:", value)
        end
    end
end

_G.GetAttackConfig = function()
    local debugInfo = GetDebugInfo()
    print("═══════════════════════════════════")
    print("Current Config:")
    for key, value in pairs(AttackConfig) do
        print("  " .. key .. ":", tostring(value))
    end
    print("\nGame Detection:")
    print("  Method:", hasEncrypted and "Encrypted Remote" or "Normal RegisterHit")
    print("  Encrypted Remote:", encryptedRemote and encryptedRemote.Name or "None")
    print("\nCharacter Info:")
    print("  Root Size:", debugInfo.rootSize)
    print("  Max Dimension:", debugInfo.maxDimension)
    print("  Max Enemies:", debugInfo.maxEnemies, debugInfo.largeForm and "(Large Form)" or "(Normal)")
    print("═══════════════════════════════════")
end

local function GetStartupInfo()
    local debugInfo = GetDebugInfo()
    local lines = {
        "═══════════════════════════════════",
        "Stealth Attack Script Loaded!",
        "═══════════════════════════════════",
        "Status: " .. (_G.FastAttackEnabled and "ENABLED ✓" or "DISABLED ✗"),
        "Method: " .. (hasEncrypted and "Encrypted" or "Normal"),
        "Max Enemies: " .. tostring(debugInfo.maxEnemies) .. " " .. (debugInfo.largeForm and "(Large Form)" or "(Normal)"),
        "",
        "Commands:",
        "  _G.ToggleFastAttack()",
        "  _G.GetAttackConfig()",
        "  _G.SetAttackConfig({MaxDistance = 30})",
        "═══════════════════════════════════"
    }
    
    for _, line in ipairs(lines) do
        print(line)
    end
end

GetStartupInfo()
