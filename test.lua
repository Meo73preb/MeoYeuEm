-- Script A: AutoFarm Core (small, paste first)
-- Provides functions on _G.AutoFarmCore

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer

if not _G then _G = {} end
_G.AutoFarm = _G.AutoFarm or false
_G.BringEnabled = _G.BringEnabled or false
_G.AutoAttack = _G.AutoAttack or true

local AF = {}
AF.DEBUG = true
local function dbg(...) if AF.DEBUG then print("[AF]", ...) end end
local function warn(...) if AF.DEBUG then warn("[AF]", ...) end end

-- find register remotes robustly
local function findRegisters()
    local ra, rh
    for _,v in ipairs(ReplicatedStorage:GetDescendants()) do
        local n = v.Name
        if (n == "RE/RegisterAttack" or n == "RegisterAttack") and (v:IsA("RemoteEvent") or v:IsA("RemoteFunction")) then ra = ra or v end
        if (n == "RE/RegisterHit" or n == "RegisterHit") and (v:IsA("RemoteEvent") or v:IsA("RemoteFunction")) then rh = rh or v end
    end
    return ra, rh
end

AF.RegisterAttack, AF.RegisterHit = findRegisters()
dbg("Registers:", AF.RegisterAttack and AF.RegisterAttack:GetFullName() or "nil", AF.RegisterHit and AF.RegisterHit:GetFullName() or "nil")

-- load Quests module if present
local function loadQuestsModule()
    local qmod = ReplicatedStorage:FindFirstChild("Quests")
    if qmod and qmod:IsA("ModuleScript") then
        local ok,res = pcall(require, qmod)
        if ok then return res end
    end
    for _,v in ipairs(ReplicatedStorage:GetDescendants()) do
        if v:IsA("ModuleScript") and v.Name == "Quests" then
            local ok,res = pcall(require, v)
            if ok then return res end
        end
    end
    return nil
end
AF.QuestsModule = loadQuestsModule()
if AF.QuestsModule then dbg("Quests module loaded") else warn("Quests module not found") end

-- helpers
local function getLevel()
    local lvl
    pcall(function()
        if player:FindFirstChild("Data") and player.Data:FindFirstChild("Level") then lvl = player.Data.Level.Value end
    end)
    if not lvl then
        pcall(function()
            if player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("Level") then lvl = player.leaderstats.Level.Value end
        end)
    end
    if not lvl then lvl = player:GetAttribute("Level") end
    return lvl
end

local function findNearestMobByName(name, maxDist)
    if not name then return nil end
    local myPos = player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character.HumanoidRootPart.Position or Vector3.new()
    local cand = {}
    for _,m in ipairs(Workspace:GetDescendants()) do
        if m:IsA("Model") and m:FindFirstChildWhichIsA("Humanoid") and m:FindFirstChild("HumanoidRootPart") then
            if m.Name:lower():find(name:lower()) then
                local pos = m.HumanoidRootPart.Position
                local d = (pos - myPos).Magnitude
                if not maxDist or d <= maxDist then table.insert(cand, {m = m, d = d}) end
            end
        end
    end
    if #cand == 0 then return nil, {} end
    table.sort(cand, function(a,b) return a.d < b.d end)
    local list = {}
    for _,v in ipairs(cand) do table.insert(list, v.m) end
    return list[1], list
end

-- smart move / tween + teleport helper
local TP_THRESHOLD = 250
local TP_TWEEN_SPEED = 900
local function smartMoveTo(pos)
    if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return end
    local hrp = player.Character.HumanoidRootPart
    local start = hrp.Position
    local dist = (pos - start).Magnitude
    if dist <= TP_THRESHOLD then
        pcall(function() hrp.CFrame = CFrame.new(pos + Vector3.new(0,3,0)) end)
        return
    end
    local dir = (pos - start).Unit
    local near = pos - dir * (TP_THRESHOLD - 10)
    local dur = math.max(0.15, dist / TP_TWEEN_SPEED)
    local ok, tween = pcall(function()
        return TweenService:Create(hrp, TweenInfo.new(dur, Enum.EasingStyle.Linear), {CFrame = CFrame.new(near + Vector3.new(0,3,0))})
    end)
    if ok and tween then
        pcall(function() tween:Play() end)
        task.wait(dur + 0.05)
    else
        pcall(function() hrp.CFrame = CFrame.new(near + Vector3.new(0,3,0)) end)
    end
    pcall(function() hrp.CFrame = CFrame.new(pos + Vector3.new(0,3,0)) end)
end

-- equip helpers (include Combat:EquipEvent)
local function tryCombatEquipEvent()
    local obj = (player.Character and player.Character:FindFirstChild("Combat")) or (player:FindFirstChild("Backpack") and player.Backpack:FindFirstChild("Combat"))
    if obj and obj:FindFirstChild("EquipEvent") then
        pcall(function() obj.EquipEvent:FireServer(true) end)
        return true
    end
    return false
end

-- fire attack: try tool remotes else RegisterHit/Attack
local function fireToolOrRegister(tool, targetPart)
    if tool then
        for _,v in ipairs(tool:GetDescendants()) do
            if (v:IsA("RemoteEvent") or v:IsA("RemoteFunction")) and v.Name:lower():find("fire") then
                pcall(function()
                    if v:IsA("RemoteFunction") then v:InvokeServer(targetPart) else v:FireServer(targetPart) end
                end)
                return
            end
        end
    end
    -- fallback: RegisterAttack/RegisterHit
    if AF.RegisterAttack and _G.AutoAttack then pcall(function() AF.RegisterAttack:FireServer() end) end
    if AF.RegisterHit and targetPart and _G.AutoAttack then
        pcall(function()
            -- minimal payload: pass targetPart
            AF.RegisterHit:FireServer(targetPart)
        end)
    end
end

-- parse QuestsModule entry -> mob name & required
local function parseModuleForBest(lvl)
    if not AF.QuestsModule then return nil end
    local bestKey, bestEntry = nil, nil
    for key,arr in pairs(AF.QuestsModule) do
        for _,entry in ipairs(arr) do
            if entry.LevelReq and entry.LevelReq <= (lvl or 0) then
                if not bestEntry or entry.LevelReq > bestEntry.LevelReq then
                    bestKey, bestEntry = key, entry
                end
            end
        end
    end
    if bestEntry and bestKey then
        for mobName, cnt in pairs(bestEntry.Task or {}) do
            return bestKey, tostring(mobName), tonumber(cnt)
        end
    end
    return nil
end

-- expose to _G
_G.AutoFarmCore = {
    dbg = dbg,
    warn = warn,
    getLevel = getLevel,
    findNearestMobByName = findNearestMobByName,
    smartMoveTo = smartMoveTo,
    tryCombatEquipEvent = tryCombatEquipEvent,
    fireToolOrRegister = fireToolOrRegister,
    parseModuleForBest = parseModuleForBest,
}

dbg("[AF] Core loaded")

task.wait(1)

-- Script B1: UI (Delta X safe)
local AF = _G.AutoFarmCore
if not AF then error("AutoFarmCore not loaded") end
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

_G.AutoFarm = _G.AutoFarm or false
_G.BringEnabled = _G.BringEnabled or false
_G.AutoAttack = _G.AutoAttack or true

local screen = Instance.new("ScreenGui", playerGui)
screen.Name = "AF_UI_v2"
screen.ResetOnSpawn = false
local frame = Instance.new("Frame", screen)
frame.Size = UDim2.new(0, 320, 0, 180)
frame.Position = UDim2.new(0.01, 0, 0.04, 0)
frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
frame.BackgroundTransparency = 0.08

local layout = Instance.new("UIListLayout", frame)
layout.Padding = UDim.new(0, 8)
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.VerticalAlignment = Enum.VerticalAlignment.Top

local function makeLabel(txt)
    local l = Instance.new("TextLabel", frame)
    l.Size = UDim2.new(0.95, 0, 0, 24)
    l.Text = txt
    l.TextScaled = true
    l.BackgroundTransparency = 1
    l.TextColor3 = Color3.new(1, 1, 1)
    return l
end

local function makeButton(txt)
    local b = Instance.new("TextButton", frame)
    b.Size = UDim2.new(0.95, 0, 0, 34)
    b.Text = txt
    b.TextScaled = true
    b.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    b.TextColor3 = Color3.new(1, 1, 1)
    return b
end

_G.AF_UI = {
    frame = frame,
    makeLabel = makeLabel,
    makeButton = makeButton,
}
print("[AF] UI1 loaded")

task.wait(1)

-- Script B2: logic & loop (paste after B1)
local AF = _G.AutoFarmCore
local UI = _G.AF_UI
if not AF or not UI then error("Need B1 & Core first") end

local frame = UI.frame
local lblLevel = UI.makeLabel("Level: ?")
local lblQuest = UI.makeLabel("Quest: -")
local lblProg = UI.makeLabel("Progress: 0/0")
local btnAuto = UI.makeButton("AutoFarm: OFF")
local btnBring = UI.makeButton("Bring: OFF")
local btnAttack = UI.makeButton("AutoAttack: ON")

btnAuto.MouseButton1Click:Connect(function()
    _G.AutoFarm = not _G.AutoFarm
    btnAuto.Text = _G.AutoFarm and "AutoFarm: ON" or "AutoFarm: OFF"
    btnAuto.BackgroundColor3 = _G.AutoFarm and Color3.fromRGB(60,120,60) or Color3.fromRGB(60,60,60)
end)

btnBring.MouseButton1Click:Connect(function()
    _G.BringEnabled = not _G.BringEnabled
    btnBring.Text = _G.BringEnabled and "Bring: ON" or "Bring: OFF"
    btnBring.BackgroundColor3 = _G.BringEnabled and Color3.fromRGB(60,120,60) or Color3.fromRGB(60,60,60)
end)

btnAttack.MouseButton1Click:Connect(function()
    _G.AutoAttack = not _G.AutoAttack
    btnAttack.Text = _G.AutoAttack and "AutoAttack: ON" or "AutoAttack: OFF"
    btnAttack.BackgroundColor3 = _G.AutoAttack and Color3.fromRGB(60,120,60) or Color3.fromRGB(60,60,60)
end)

-- Simple check loop (rút gọn cho Delta)
task.spawn(function()
    AF.dbg("Loop start")
    while task.wait(1) do
        if _G.AutoFarm then
            local lvl = AF.getLevel() or 0
            lblLevel.Text = "Level: "..lvl
        else
            lblLevel.Text = "Level: OFF"
        end
    end
end)
print("[AF] UI/Loop loaded")

task.wait(1)
-- Script B3: AutoFarm logic (bring/attack/quest) - paste & run AFTER Script A and B1/B2
local AF = _G.AutoFarmCore
if not AF then error("AutoFarmCore missing. Run Script A first.") end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local player = Players.LocalPlayer

-- params (tweak if cần)
local CLOSE_RADIUS = 220       -- nếu quái trong radius này thì dùng trực tiếp
local FAR_SCAN = 1200          -- tìm quái trong radius này nếu không thấy gần
local BRING_LIMIT = 2          -- game chỉ cho đánh 2 mục tiêu cùng lúc
local BRING_DISTANCE = 520
local FOLLOW_OFFSET = Vector3.new(0,20,0)
local FOLLOW_UPDATE_RATE = 0.06
local ATTACK_WAIT = 0.12

-- small status UI (separate so B2 labels không cần thay đổi)
local function makeStatusUI()
    local pg = player:WaitForChild("PlayerGui")
    local sg = Instance.new("ScreenGui", pg)
    sg.Name = "AF_StatusSmall"
    sg.ResetOnSpawn = false
    local f = Instance.new("Frame", sg)
    f.Size = UDim2.new(0,240,0,90)
    f.Position = UDim2.new(0.015,0,0.28,0)
    f.BackgroundColor3 = Color3.fromRGB(18,18,18)
    f.BackgroundTransparency = 0.08
    local layout = Instance.new("UIListLayout", f); layout.Padding = UDim.new(0,6)
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    local lblKey = Instance.new("TextLabel", f); lblKey.Size = UDim2.new(0.95,0,0,20); lblKey.TextScaled=true; lblKey.Text="Quest: -"; lblKey.BackgroundTransparency=1; lblKey.TextColor3 = Color3.new(1,1,1)
    local lblMob = Instance.new("TextLabel", f); lblMob.Size = UDim2.new(0.95,0,0,20); lblMob.TextScaled=true; lblMob.Text="Mob: -"; lblMob.BackgroundTransparency=1; lblMob.TextColor3 = Color3.new(1,1,1)
    local lblProg = Instance.new("TextLabel", f); lblProg.Size = UDim2.new(0.95,0,0,20); lblProg.TextScaled=true; lblProg.Text="Prog: 0/0"; lblProg.BackgroundTransparency=1; lblProg.TextColor3 = Color3.new(1,1,1)
    return {gui=sg, lblKey=lblKey, lblMob=lblMob, lblProg=lblProg}
end

local StatusUI = makeStatusUI()

-- active quest state
local active = {key=nil, mobName=nil, need=0, progress=0, started=false}
local deathConns = {}

local function clearDeathConns()
    for _,c in pairs(deathConns) do pcall(function() c:Disconnect() end) end
    deathConns = {}
end

local function watchDeaths(mobName)
    clearDeathConns()
    active.progress = 0
    local en = Workspace:FindFirstChild("Enemies")
    if not en then return end
    for _,m in ipairs(en:GetChildren()) do
        if m and m:FindFirstChildWhichIsA("Humanoid") and (m.Name:lower():find(mobName:lower())) then
            local hum = m:FindFirstChildWhichIsA("Humanoid")
            if hum then
                table.insert(deathConns, hum.Died:Connect(function()
                    active.progress = active.progress + 1
                end))
            end
        end
    end
    -- listen new spawns
    if en then
        table.insert(deathConns, en.ChildAdded:Connect(function(ch)
            if ch and ch:FindFirstChildWhichIsA("Humanoid") and ch.Name:lower():find(mobName:lower()) then
                local hum = ch:FindFirstChildWhichIsA("Humanoid")
                if hum then
                    table.insert(deathConns, hum.Died:Connect(function() active.progress = active.progress + 1 end))
                end
            end
        end))
    end
end

-- refresh server-side progress if possible (player.Data patterns)
local function refreshProgressFromServer(qKey)
    if not qKey then return end
    local data = player:FindFirstChild("Data")
    if not data then return end
    pcall(function()
        if data:FindFirstChild("Quests") and data.Quests:FindFirstChild(qKey) then
            local qf = data.Quests[qKey]
            if qf:FindFirstChild("Progress") then active.progress = qf.Progress.Value end
            if qf:FindFirstChild("Required") then active.need = qf.Required.Value end
        end
    end)
end

-- safe start quest (uses CommF_ if found), teleport to quest NPC if QuestsLookup exists
local QuestsLookup = { BanditQuest1 = {questPos = Vector3.new(1059,17,1546)}, DesertQuest = {questPos = Vector3.new(897,6,4389)} }
local function safeStartQuest(qKey)
    if not qKey then return end
    -- teleport to NPC if known
    local pos = (QuestsLookup[qKey] and QuestsLookup[qKey].questPos) and QuestsLookup[qKey].questPos or nil
    local origin = player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character.HumanoidRootPart.CFrame or nil
    if pos then AF.smartMoveTo(pos) task.wait(0.08) end
    -- find CommF_ and call StartQuest
    pcall(function()
        for _,v in ipairs(ReplicatedStorage:GetDescendants()) do
            if v.Name == "CommF_" or v.Name == "CommF" then
                if v:IsA("RemoteFunction") and v.InvokeServer then v:InvokeServer("StartQuest", qKey, 1) end
                if v:IsA("RemoteEvent") and v.FireServer then v:FireServer("StartQuest", qKey, 1) end
                break
            end
        end
    end)
    task.wait(0.08)
    if origin then AF.smartMoveTo(origin.Position) end
end

-- bring group (limit BRING_LIMIT) for mobName
local function bringGroup(mobName)
    if not _G.BringEnabled then return end
    if not Workspace:FindFirstChild("Enemies") then return end
    local myHRP = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not myHRP then return end
    local got = 0
    for _,m in ipairs(Workspace.Enemies:GetChildren()) do
        if got >= BRING_LIMIT then break end
        if m and m:FindFirstChildWhichIsA("Humanoid") and m:FindFirstChild("HumanoidRootPart") then
            if m.Name:lower():find((mobName or ""):lower()) then
                local hum = m:FindFirstChildWhichIsA("Humanoid")
                local hrp = m:FindFirstChild("HumanoidRootPart")
                if hum and hrp and hum.Health > 0 and (hrp.Position - myHRP.Position).Magnitude <= BRING_DISTANCE then
                    pcall(function()
                        if not m:GetAttribute("Bring_isBrought") then
                            m:SetAttribute("Bring_prevWalkSpeed", hum.WalkSpeed or 0)
                            m:SetAttribute("Bring_prevJumpPower", hum.JumpPower or 0)
                            m:SetAttribute("Bring_isBrought", true)
                        end
                        hum.WalkSpeed = 0; hum.JumpPower = 0; hum.PlatformStand = true
                        hrp.CanCollide = false
                        hrp.CFrame = myHRP.CFrame * CFrame.new(0, -20, 0)
                    end)
                    got = got + 1
                end
            end
        end
    end
end

-- equip helper: try Combat:EquipEvent then check tool
local function ensureEquip()
    -- try Combat equip event
    AF.tryCombatEquipEvent()
    task.wait(0.12)
    -- if still no tool, try to find in Backpack/Character (the core has helper but we use try)
    local tool = player.Character and player.Character:FindFirstChildOfClass("Tool")
    if tool then return tool end
    if player:FindFirstChild("Backpack") then
        local tb = player.Backpack:FindFirstChildOfClass("Tool")
        if tb then
            local humanoid = player.Character and player.Character:FindFirstChildWhichIsA("Humanoid")
            if humanoid then
                for i=1,4 do
                    pcall(function() humanoid:EquipTool(tb) end)
                    task.wait(0.08)
                    if tb.Parent == player.Character then return tb end
                end
            end
        end
    end
    return nil
end

-- main loop (uses AF.parseModuleForBest, AF.findNearestMobByName, AF.smartMoveTo, AF.fireToolOrRegister)
task.spawn(function()
    AF.dbg("B3 main loop started")
    while true do
        task.wait(0.5)
        if not _G.AutoFarm then task.wait(0.4) goto cont end
        if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then task.wait(0.5) goto cont end

        local lvl = AF.getLevel()
        if not lvl then task.wait(0.6) goto cont end

        -- pick best quest from module
        local key, mobName, need = AF.parseModuleForBest(lvl)
        if not key then task.wait(0.8) goto cont end

        -- set active when changed
        if active.key ~= key then
            active.key = key; active.mobName = mobName; active.need = need or 0; active.progress = 0; active.started = false
            StatusUI.lblKey.Text = "Quest: "..tostring(active.key)
            StatusUI.lblMob.Text = "Mob: "..tostring(active.mobName or "-")
            StatusUI.lblProg.Text = string.format("Prog: %d / %d", active.progress, active.need)
            AF.dbg("Active quest set:", key, mobName, need)
        end

        -- start quest once
        if active.key and not active.started then
            safeStartQuest(active.key)
            task.wait(0.12)
            watchDeaths(active.mobName)
            refreshProgressFromServer(active.key)
            active.started = true
        end

        -- check complete from server/local
        refreshProgressFromServer(active.key)
        if active.need > 0 and active.progress >= active.need then
            AF.dbg("Quest complete. Clearing active")
            active = {key=nil, mobName=nil, need=0, progress=0, started=false}
            clearDeathConns()
            StatusUI.lblKey.Text = "Quest: -"; StatusUI.lblMob.Text = "Mob: -"; StatusUI.lblProg.Text = "Prog: 0/0"
            task.wait(0.6)
            goto cont
        end

        -- try find nearest mob: prefer close then far
        local mob, list = AF.findNearestMobByName(active.mobName, CLOSE_RADIUS)
        if not mob then
            local farMob, farList = AF.findNearestMobByName(active.mobName, FAR_SCAN)
            if farMob then
                AF.dbg("Far mob found -> moving near")
                AF.smartMoveTo(farMob.HumanoidRootPart.Position)
                task.wait(0.4)
                mob, list = AF.findNearestMobByName(active.mobName, CLOSE_RADIUS)
            else
                AF.dbg("No mobs spawned for", active.mobName)
                task.wait(1)
                goto cont
            end
        end

        -- bring group if needed
        if _G.BringEnabled and active.mobName then
            bringGroup(active.mobName)
            task.wait(0.08)
        end

        -- reselect mob (nearest) and attack
        mob = AF.findNearestMobByName(active.mobName, 1000)
        if not mob or not mob.HumanoidRootPart then task.wait(0.3) goto cont end
        local h = mob:FindFirstChildWhichIsA("Humanoid")
        local hrp = mob:FindFirstChild("HumanoidRootPart")
        if not h or not hrp or h.Health <= 0 then task.wait(0.2) goto cont end

        -- ensure equip
        local tool = ensureEquip()

        -- follow above while attacking
        local stopFollow = false
        local co = coroutine.create(function()
            while not stopFollow and h and h.Health > 0 and _G.AutoFarm do
                if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                    local myHRP = player.Character.HumanoidRootPart
                    pcall(function()
                        myHRP.AssemblyLinearVelocity = Vector3.new(0,0,0)
                        myHRP.Velocity = Vector3.new(0,0,0)
                        myHRP.CFrame = CFrame.new(hrp.Position + FOLLOW_OFFSET)
                        local ph = player.Character:FindFirstChildWhichIsA("Humanoid")
                        if ph then ph.PlatformStand = true end
                    end)
                end
                task.wait(FOLLOW_UPDATE_RATE)
            end
            pcall(function() if player.Character and player.Character:FindFirstChildWhichIsA("Humanoid") then player.Character:FindFirstChildWhichIsA("Humanoid").PlatformStand = false end end)
        end)
        coroutine.resume(co)

        -- attack loop
        while h and h.Health > 0 and _G.AutoFarm do
            AF.fireToolOrRegister(tool and tool or hrp, hrp)
            task.wait(ATTACK_WAIT)
        end

        stopFollow = true
        task.wait(0.15)

        -- after kill, update UI progress
        refreshProgressFromServer(active.key)
        StatusUI.lblProg.Text = string.format("Prog: %d / %d", active.progress or 0, active.need or 0)

        ::cont::
    end
end)

print("[AF] B3 loaded - logic running. Toggle _G.AutoFarm/_G.BringEnabled/_G.AutoAttack or use GUI.")
