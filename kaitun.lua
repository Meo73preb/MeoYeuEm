--[[
    ═══════════════════════════════════════════════════════════
    Mate Cat Kaitun — workflow automation assistant (Blox Fruits)
    Mục đích: cá nhân & học tập Lua automation.
    UI: Mate-Cat-Library | Rejoin 2 lớp: Lua (TeleportReconnect)
        + handoff file cho Python tool (vibi-rejoin.py)
    ═══════════════════════════════════════════════════════════
]]

-- ═════════════════════════════════════════════
-- GLOBALS (chỉ helper mới được local)
-- ═════════════════════════════════════════════
Players    = game:GetService("Players")
LP         = Players.LocalPlayer
PG         = LP:WaitForChild("PlayerGui")
RS         = game:GetService("ReplicatedStorage")
WS         = game:GetService("Workspace")
RunService = game:GetService("RunService")
LogService = game:GetService("LogService")
VIM        = game:GetService("VirtualUser")

-- CoreGui có thể không truy cập được tuỳ môi trường chạy script
do
    local okCore, coreGui = pcall(function()
        return game:GetService("CoreGui")
    end)
    CoreGui = okCore and coreGui or nil
end

-- ═════════════════════════════════════════════
-- FARM — static config cho 3 task
-- ═════════════════════════════════════════════
FARM = {
    Tyrant = {
        Level   = 2575,
        Quest   = "TikiQuest3",
        Boss    = "Tyrant of the Skies",
        Mob     = "Sky Bandit",
        Eyes    = { "Eye1", "Eye2", "Eye3", "Eye4" },
        MapPath = { "Map", "TikiOutpost", "IslandModel" },
    },
    Katakuri = {
        Level = 2275,
        Quest = "CakeQuest2",
        Boss  = "Cake Prince",
        Mob   = "Katakuri",
    },
    Bones = {
        Level = 2050,
        Quest = "HauntedQuest2",
        Mob   = "Reborn Skeleton",
        Item  = "Bones",
    },
}

_ps = {
    -- Attack
    AttackDelay        = 0.35,
    AttackRange        = 60,
    HitPlayers         = false,
    NoAnim             = false,

    -- Priority
    Priority           = "Auto",   -- Auto | Tyrant | Katakuri | Bones
    BonesThreshold     = 5000,
    TyrantEyeThreshold = 2,
    AutoQuest          = true,

    -- Fruit
    AutoPickupFruit    = true,
    FruitPickupRadius  = 5,

    -- Movement
    TweenSpeed         = 220,
    AntiAFKWaterWalk   = true,     -- WaterWalk part chống AFK dưới nước

    -- Random NPC rotate
    RandomNPCs         = {},       -- { {Name=..., Pos=CFrame.new(...)} }
    RotateInterval     = 7200,     -- 2h
    RotateJitter       = { 60, 180 },
    NextRandomNPC      = 0,

    -- Control
    StopAll            = false,    -- tắt toàn bộ farm, user tự chơi

    -- Rejoin strategy
    AutoRejoinSelf     = true,     -- Lua tự rejoin 2 lần đầu
    MaxSelfRejoin      = 2,        -- số lần tự rejoin trước khi handoff Python
    RejoinCooldown     = 60,       -- giây tối thiểu giữa 2 lần kick (tránh đếm trùng)
    HandoffToPython    = true,     -- ghi HANDOFF|python khi hết quota

    -- Status file (Python tool đọc)
    StatusFile         = "vibi_status.txt",
    StatusMaxLines     = 200,      -- auto-trim để file không phình
}

ST = {
    RejoinAttempts = 0,
    LastJobId      = nil,
    LastKickAt     = nil,
    Task           = nil,
    StartTime      = os.clock(),
    BonesCache     = 0,
}

TS = {
    SNAP   = 55,    -- khoảng cách đủ gần → snap tới đích
    BACK   = 40,    -- bị đẩy lùi quá ngưỡng này → giảm cap
    CHUNK  = 1500,  -- chặn bước di chuyển tối đa mỗi lần
    Active = false,
}

ATK = {
    Combo          = 0,
    ComboWeapon    = nil,
    ComboTime      = 0,
    Cancel         = false,
    Busy           = false,
    BusyTool       = nil,
    FruitChain     = 0,
    FruitChainTool = nil,
    FruitLastFire  = 0,
    FruitCD        = 0.05,
    ComboWindow    = 0.3,
}

-- Forward-declare: HandleKickDetected dùng StopTopos trước khi Topos được định nghĩa
StopTopos = StopTopos or function() end

-- Duyệt path dạng chuỗi "Map.TikiOutpost.IslandModel" từ root
function Resolve(root, path)
    local cur = root
    for token in string.gmatch(tostring(path), "[^%.]+") do
        if not cur then
            return nil
        end
        cur = cur:FindFirstChild(token)
    end
    return cur
end

-- Tìm mob theo tên (substring, lowercase) trong folder Enemies, ưu tiên gần nhất
function FindMob(name)
    local char = LP.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local enemies = WS:FindFirstChild("Enemies")
    if not enemies then
        return nil
    end
    local low = string.lower(name)
    local best, bestDis = nil, math.huge
    for _, mob in ipairs(enemies:GetChildren()) do
        if string.find(string.lower(mob.Name), low, 1, true) then
            local part = mob.PrimaryPart or mob:FindFirstChildWhichIsA("BasePart")
            if part then
                local dis = 0
                if hrp then
                    dis = (part.Position - hrp.Position).Magnitude
                end
                if dis < bestDis then
                    best, bestDis = mob, dis
                end
            end
        end
    end
    return best
end

-- Đếm mob theo tên (substring)
function CountMob(name)
    local enemies = WS:FindFirstChild("Enemies")
    if not enemies then
        return 0
    end
    local count = 0
    local low = string.lower(name)
    for _, mob in ipairs(enemies:GetChildren()) do
        if string.find(string.lower(mob.Name), low, 1, true) then
            count = count + 1
        end
    end
    return count
end

-- Đếm mắt Tyrant còn chưa lấy (Transparency == 0 nghĩa là vẫn đang hiển thị)
function TyrantEyesCount()
    local count = 0
    local cfg = FARM.Tyrant
    local island = Resolve(WS, table.concat(cfg.MapPath, "."))
    if island then
        for _, eyeName in ipairs(cfg.Eyes) do
            local eye = island:FindFirstChild(eyeName, true)
            if eye and eye:IsA("BasePart") and eye.Transparency == 0 then
                count = count + 1
            end
        end
    end
    return count
end

-- Quest panel có đang hiển thị không
function QuestVisible()
    local ok, visible = pcall(function()
        return PG.Main.Quest.Visible
    end)
    return ok and visible == true
end

-- Target gần nhất trong phạm vi (mặc định là mob, tuỳ chọn thêm player)
function FindNearestTarget(range, hitPlayers)
    local char = LP.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then
        return nil
    end
    local best, bestDis = nil, range
    local enemies = WS:FindFirstChild("Enemies")
    if enemies then
        for _, mob in ipairs(enemies:GetChildren()) do
            local part = mob.PrimaryPart or mob:FindFirstChildWhichIsA("BasePart")
            if part then
                local dis = (part.Position - hrp.Position).Magnitude
                if dis < bestDis then
                    best, bestDis = part, dis
                end
            end
        end
    end
    if hitPlayers then
        for _, other in ipairs(Players:GetPlayers()) do
            if other ~= LP then
                local oc = other.Character
                local op = oc and oc:FindFirstChild("HumanoidRootPart")
                if op then
                    local dis = (op.Position - hrp.Position).Magnitude
                    if dis < bestDis then
                        best, bestDis = op, dis
                    end
                end
            end
        end
    end
    return best
end


-- Ghi 1 dòng status vào file để Python tool phân tích
function LogStatus(kind, reason)
    warn("[KAITUN-" .. tostring(kind) .. "] " .. tostring(reason))
    -- Chỉ ghi khi môi trường có filesystem API
    if type(writefile) ~= "function" or type(readfile) ~= "function" then
        return
    end
    pcall(function()
        local content = ""
        if type(isfile) == "function" and isfile(_ps.StatusFile) then
            content = tostring(readfile(_ps.StatusFile) or "")
        end
        local lines = {}
        for line in content:gmatch("[^\r\n]+") do
            table.insert(lines, line)
        end
        -- ⚠ gsub trả về 2 giá trị → phải bọc ngoặc để string.format không vỡ
        local safeReason = tostring(reason):gsub("[\r\n|]", " ")
        table.insert(lines, string.format(
            "%s|%s|%s|%s|%s",
            os.date("%Y-%m-%d %H:%M:%S"),
            tostring(kind),
            tostring(safeReason),
            LP.Name,
            game.JobId or "?"
        ))
        -- Auto-trim: giữ tối đa StatusMaxLines dòng cuối
        while #lines > _ps.StatusMaxLines do
            table.remove(lines, 1)
        end
        local newContent = table.concat(lines, "\n") .. "\n"
        writefile(_ps.StatusFile, newContent)
    end)
end

-- Đọc & parse status file → đếm kicks / prompts / handoffs
function ReadStatusFile()
    local out = { kicks = 0, prompts = 0, handoffs = 0, lines = {} }
    if type(readfile) ~= "function" then
        return out
    end
    local ok, content = pcall(function()
        return readfile(_ps.StatusFile)
    end)
    if not ok or type(content) ~= "string" then
        return out
    end
    for line in content:gmatch("[^\r\n]+") do
        table.insert(out.lines, line)
        if string.find(line, "KICK|", 1, true) then
            out.kicks = out.kicks + 1
        end
        if string.find(line, "PROMPT|", 1, true) then
            out.prompts = out.prompts + 1
        end
        if string.find(line, "HANDOFF|python", 1, true) then
            out.handoffs = out.handoffs + 1
        end
    end
    return out
end

-- Logic chính khi phát hiện kick
function HandleKickDetected(kind, reason)
    -- Dedup: cùng kick trong khoảng RejoinCooldown giây → bỏ qua
    local now = os.time()
    if kind ~= "BANNED" and ST.LastKickAt and (now - ST.LastKickAt < _ps.RejoinCooldown) then
        return
    end
    ST.LastKickAt = now

    -- 1. Log
    LogStatus(kind, reason)

    -- Bị ban → không rejoin, dừng toàn bộ automation
    if kind == "BANNED" then
        _ps.StopAll = true
        StopTopos()
        if Window then
            Window:Notify("BANNED", "Dừng toàn bộ automation.", 10)
        end
        return
    end

    -- 2. Tăng counter
    ST.RejoinAttempts = (ST.RejoinAttempts or 0) + 1

    -- 3. Quyết định
    if not _ps.AutoRejoinSelf then
        -- User tắt auto → chỉ log, không làm gì
        return
    end

    if ST.RejoinAttempts <= _ps.MaxSelfRejoin then
        -- Lớp 1: tự rejoin qua TeleportReconnect
        LogStatus("SELF_REJOIN",
            "attempt " .. tostring(ST.RejoinAttempts) .. "/" .. tostring(_ps.MaxSelfRejoin))
        task.delay(2, function()
            pcall(function()
                game:GetService("TeleportService"):TeleportReconnect()
            end)
        end)
    else
        -- Lớp 2: hết quota → handoff cho Python tool
        _ps.StopAll = true
        StopTopos()
        if _ps.HandoffToPython then
            LogStatus("HANDOFF", "python")
        end
        if Window then
            Window:Notify("Handoff Python", "Hết quota rejoin, chờ Python relaunch.", 8)
        end
    end
end

-- Join server mới thành công (JobId đổi) → reset counter
function ResetRejoinCounterIfNewJob()
    local job = game.JobId or "?"
    if ST.LastJobId == nil then
        ST.LastJobId = job
        return
    end
    if ST.LastJobId ~= job then
        ST.LastJobId = job
        ST.RejoinAttempts = 0
        ST.LastKickAt = nil
        LogStatus("REJOIN_OK", "jobId=" .. job)
    end
end

-- Listener 1: LogService — phát hiện kick qua log
LogService.MessageOut:Connect(function(msg)
    if type(msg) ~= "string" then
        return
    end
    local low = msg:lower()
    -- Banned → xử lý riêng, KHÔNG tự rejoin
    if string.find(low, "account banned", 1, true) then
        HandleKickDetected("BANNED", msg)
        return
    end
    local triggers = {
        "security kick",
        "you have been kicked",
        "error code: 267",
        "kicked for inactivity",
    }
    for _, key in ipairs(triggers) do
        if string.find(low, key, 1, true) then
            HandleKickDetected("KICK", msg)
            return
        end
    end
end)

-- Listener 2: CoreGui ErrorPrompt watcher
task.spawn(function()
    if not CoreGui then
        return
    end
    local prompt
    pcall(function()
        local pg = CoreGui:WaitForChild("RobloxPromptGui", 10)
        if pg then
            prompt = pg:WaitForChild("promptOverlay", 10)
        end
    end)
    if not prompt then
        return
    end
    prompt.ChildAdded:Connect(function(child)
        if child.Name == "ErrorPrompt" then
            local title = "unknown"
            pcall(function()
                if child:FindFirstChild("Title") then
                    title = child.Title.Text
                end
            end)
            HandleKickDetected("PROMPT", title)
        end
    end)
end)

-- Anti-AFK: bắt sự kiện idle + WaterWalk part vô hình theo nhân vật
LP.Idled:Connect(function()
    pcall(function()
        VIM:CaptureController()
        VIM:ClickButton2(Vector2.new())
    end)
end)

task.spawn(function()
    -- Tận dụng part WaterWalk nếu đã có, không thì tạo mới
    local part = WS:FindFirstChild("WaterWalk")
    if not part or not part:IsA("BasePart") then
        if part then
            part:Destroy()
        end
        part = Instance.new("Part")
    end
    part.Name = "WaterWalk"
    part.Size = Vector3.new(math.huge, 1, math.huge)
    part.Transparency = 1
    part.Anchored = true
    part.CanCollide = false
    part.Parent = WS

    while task.wait() do
        if not _ps.AntiAFKWaterWalk then
            part.CanCollide = false
        else
            local char = LP.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hrp and hum and not hum.Sit
                and hrp.Position.Y <= 0 and hrp.Position.Y >= -120 then
                part.CanCollide = true
                part.Position = Vector3.new(hrp.Position.X, -5, hrp.Position.Z)
            else
                part.CanCollide = false
            end
        end
    end
end)

do
    -- cv: velocity hiện tại | tg: đích | st: mốc thời gian adaptive cap
    -- cp: cap tốc độ | nr: thời điểm nghỉ xong | lp: vị trí cũ | ld: khoảng cách cũ
    local cv, tg, st, cp, nr, lp, ld
    local ToposThread = nil

    function StopTopos()
        TS.Active = false
        tg = nil
        local th = ToposThread
        ToposThread = nil
        if th then
            pcall(function()
                coroutine.close(th)
            end)
        end
    end

    function Topos(targetCFrame)
        if typeof(targetCFrame) ~= "CFrame" then
            return false
        end
        tg = targetCFrame
        if TS.Active then
            return true -- đang bay rồi → chỉ cập nhật đích mới
        end

        local char = LP.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then
            return false
        end

        TS.Active = true
        st = os.clock()
        cp = _ps.TweenSpeed or 190
        nr = 0
        lp = hrp.Position
        ld = (tg.Position - lp).Magnitude

        ToposThread = task.spawn(function()
            while TS.Active do
                RunService.Heartbeat:Wait()
                if not TS.Active then
                    break
                end
                local c = LP.Character
                local root = c and c:FindFirstChild("HumanoidRootPart")
                local hum = c and c:FindFirstChildOfClass("Humanoid")
                if not root or not tg then
                    break
                end

                -- fixSit: đang ngồi thì đứng dậy
                if hum and hum.Sit then
                    hum.Sit = false
                end

                -- Zero velocity mỗi frame
                pcall(function()
                    cv = Vector3.zero
                    root.AssemblyLinearVelocity = cv
                    root.AssemblyAngularVelocity = cv
                end)

                local pos = root.Position
                local targetPos = tg.Position
                local dis = (targetPos - pos).Magnitude

                -- Backward detection: bị đẩy lùi xa hơn lần trước → giảm cap, nghỉ 3s
                if dis > ld + TS.BACK then
                    cp = math.max(60, cp * 0.7)
                    nr = os.clock() + 3
                end

                -- Progress detection: tiến gần được >= 5 studs → đánh dấu tiến bộ
                if ld - dis >= 5 then
                    st = os.clock()
                    lp = pos
                end

                -- Adaptive cap: mỗi 1.5s tăng cap 8%, tối đa 1000
                if os.clock() - st >= 1.5 then
                    st = os.clock()
                    cp = math.min(cp * 1.08, 1000)
                end

                -- Đang trong thời gian nghỉ (sau backward) → bỏ qua frame này
                if os.clock() < nr then
                    ld = dis
                else
                    -- Snap: đủ gần thì kết thúc
                    if dis <= TS.SNAP then
                        root.CFrame = tg
                        break
                    end

                    -- Chunk: không vượt quá CHUNK studs mỗi bước
                    if dis > 0 then
                        local dir = (targetPos - pos).Unit
                        local moveDist = math.min(cp * (dis / math.max(dis, 1)), dis, TS.CHUNK)
                        moveDist = math.min(math.max(cp, 60) * 0.033, moveDist)
                        root.CFrame = CFrame.new(pos + dir * moveDist)
                    end
                    ld = dis
                end
            end

            TS.Active = false
            ToposThread = nil
        end)
        return true
    end
end

-- Init: mở rộng mặt nước để WaterWalk hoạt động ổn định dưới đảo
pcall(function()
    local waterPlane = Resolve(WS, "Map.WaterBase-Plane")
    if waterPlane then
        waterPlane.Size = Vector3.new(1000, 112, 1000)
    end
end)

CBU = nil -- CombatUtil module (cache)

-- Lấy CombatUtil từ PlayerScripts
-- ⚠ Giả định path chuẩn Blox Fruits: PlayerScripts.Combat (hoặc CombatUtil). Không chắc chắn → pcall.
function GetCBU()
    if CBU then
        return CBU
    end
    pcall(function()
        local ps = LP:FindFirstChild("PlayerScripts")
        if ps then
            local mod = ps:FindFirstChild("Combat") or ps:FindFirstChild("CombatUtil")
            if mod and mod:IsA("ModuleScript") then
                CBU = require(mod)
            elseif mod then
                local sub = mod:FindFirstChild("CombatUtil")
                if sub and sub:IsA("ModuleScript") then
                    CBU = require(sub)
                end
            end
        end
    end)
    return CBU
end

-- Lấy remote RegisterAttack
-- ⚠ Giả định path chuẩn Blox Fruits: ReplicatedStorage.Remotes.RegisterAttack. pcall + nil-check.
function GetRegisterAttack()
    local remote = nil
    pcall(function()
        local remotes = RS:FindFirstChild("Remotes")
        if remotes then
            remote = remotes:FindFirstChild("RegisterAttack")
        end
    end)
    return remote
end

-- M1 cho fruit đang cầm (cooldown + chain reset khi đổi tool)
function UseFruitM1(tool, range)
    local target = FindNearestTarget(range, _ps.HitPlayers)
    local fired = false
    pcall(function()
        -- Ưu tiên remote nằm ngay trong tool
        local remote = tool:FindFirstChildWhichIsA("RemoteEvent")
        if remote then
            remote:FireServer(target and target.Position or nil)
            fired = true
        end
    end)
    if not fired then
        -- Fallback: activate tool trực tiếp
        pcall(function()
            tool:Activate()
            fired = true
        end)
    end
    return fired
end

-- Melee / Sword: fire combo qua remote + animation + CombatUtil
function AttackMelee(tool, combo, range, hitPlayers)
    if not tool then
        return
    end
    -- Busy guard theo tool
    if ATK.BusyTool and ATK.BusyTool ~= tool then
        return
    end
    ATK.BusyTool = tool

    -- CanAttack attribute (tuỳ tool, có thể không tồn tại)
    local canAttack = true
    pcall(function()
        local attr = tool:GetAttribute("CanAttack")
        if attr == false then
            canAttack = false
        end
    end)
    if not canAttack then
        return
    end

    -- Cooldown scale (function của tool, có thể không tồn tại)
    local cooldownScale = 1
    pcall(function()
        if type(tool.getWeaponCooldownScale) == "function" then
            cooldownScale = tool:getWeaponCooldownScale() or 1
        end
    end)

    -- Độ dài animation từ animCache trong tool
    local len = 0
    pcall(function()
        local animCache = tool:FindFirstChild("animCache")
        if animCache and animCache.Length then
            len = animCache.Length
        end
    end)

    local registerAttack = GetRegisterAttack()

    if _ps.NoAnim then
        -- Không phát animation: fire với len = 0
        pcall(function()
            if registerAttack then
                registerAttack:FireServer(0, combo)
            end
        end)
    else
        pcall(function()
            if registerAttack then
                registerAttack:FireServer(len * cooldownScale, combo)
            end
        end)
        -- Play animation nếu có
        pcall(function()
            local anim = tool:FindFirstChildWhichIsA("Animation")
            local animator = LP.Character
                and LP.Character:FindFirstChildOfClass("Humanoid")
                and LP.Character:FindFirstChildOfClass("Humanoid"):FindFirstChildOfClass("Animator")
            if anim and animator then
                animator:LoadAnimation(anim):Play()
            end
        end)
    end

    -- CombatUtil hit detection (không chắc chắn tồn tại → pcall từng bước)
    local cbu = GetCBU()
    pcall(function()
        if cbu and type(cbu.AttackStart) == "function" then
            cbu:AttackStart()
        end
    end)
    pcall(function()
        if cbu and type(cbu.RunHitDetection) == "function" then
            cbu:RunHitDetection()
        end
    end)
end

function Attack(range, hitPlayers)
    range = tonumber(range) or _ps.AttackRange
    hitPlayers = (hitPlayers ~= nil and hitPlayers) or _ps.HitPlayers
    if _ps.StopAll then
        return
    end

    local char = LP.Character
    if not char then
        return
    end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then
        return
    end

    -- Guard Stun: attribute game có thể đặt lên character
    local okStun, stunVal = pcall(function()
        return char:GetAttribute("Stun")
    end)
    if okStun and type(stunVal) == "number" and stunVal > 0 then
        return
    end

    -- Busy guard
    if ATK.Busy then
        return
    end
    ATK.Busy = true

    local equipped = char:FindFirstChildOfClass("Tool")

    if equipped and string.find(equipped.Name:lower(), "fruit", 1, true) then
        -- ⭐ Fruit M1 path
        if ATK.FruitChainTool ~= equipped then
            ATK.FruitChain = 0
            ATK.FruitChainTool = equipped
        end
        if os.clock() - ATK.FruitLastFire >= _ps.AttackDelay + ATK.FruitCD then
            ATK.FruitLastFire = os.clock()
            UseFruitM1(equipped, range)
            ATK.FruitChain = (ATK.FruitChain + 1) % 5
        end
    elseif equipped then
        -- ⭐ Melee / Sword path
        if ATK.ComboWeapon ~= equipped or (os.clock() - ATK.ComboTime) > ATK.ComboWindow then
            ATK.Combo = 0
            ATK.ComboWeapon = equipped
        end
        ATK.ComboTime = os.clock()
        ATK.Combo = (ATK.Combo % 5) + 1
        AttackMelee(equipped, ATK.Combo, range, hitPlayers)
    end

    ATK.Busy = false
end

-- List toàn bộ inventory qua CommF_ "getInventory"
-- ⚠ Giả định remote chuẩn Blox Fruits: ReplicatedStorage.Remotes.CommF_ → pcall.
function ListInventory()
    local out = {}
    local ok, inv = pcall(function()
        local remotes = RS:FindFirstChild("Remotes")
        local commf = remotes and remotes:FindFirstChild("CommF_")
        if not commf then
            return nil
        end
        return commf:InvokeServer("getInventory")
    end)
    if ok and type(inv) == "table" then
        for _, item in ipairs(inv) do
            table.insert(out, {
                Name   = item.Name,
                Count  = item.Count or 1,
                ItemId = item.Id or item.ItemId,
                UID    = item.UID,
            })
        end
    end
    return out
end

function GetItemCount(name)
    local count = 0
    local inv = ListInventory()
    for _, item in ipairs(inv) do
        if item.Name == name then
            count = count + (tonumber(item.Count) or 1)
        end
    end
    return count
end

function CheckCountItem(name, min)
    return GetItemCount(name) >= (tonumber(min) or 0)
end

-- Tool fruit đang có (character hoặc backpack) — có Handle
function GetPathFruit()
    local char = LP.Character
    if char then
        for _, tool in ipairs(char:GetChildren()) do
            if tool:IsA("Tool")
                and string.find(tool.Name:lower(), "fruit", 1, true)
                and tool:FindFirstChild("Handle") then
                return tool
            end
        end
    end
    local backpack = LP:FindFirstChild("Backpack")
    if backpack then
        for _, tool in ipairs(backpack:GetChildren()) do
            if tool:IsA("Tool")
                and string.find(tool.Name:lower(), "fruit", 1, true)
                and tool:FindFirstChild("Handle") then
                return tool
            end
        end
    end
    return nil
end

-- Nhặt fruit rơi: trong radius thì nhấn, ngoài radius thì bay tới
function PickupFruit()
    if not _ps.AutoPickupFruit then
        return false
    end
    local char = LP.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then
        return false
    end
    for _, obj in ipairs(WS:GetChildren()) do
        local isFruit = (obj:IsA("Model") or obj:IsA("Tool") or obj:IsA("BasePart"))
            and string.find(obj.Name:lower(), "fruit", 1, true)
        if isFruit and obj ~= GetPathFruit() then
            local handle = obj:FindFirstChild("Handle")
                or (obj:IsA("BasePart") and obj)
                or obj:FindFirstChildWhichIsA("BasePart")
            if handle then
                local dis = (handle.Position - hrp.Position).Magnitude
                if dis <= _ps.FruitPickupRadius then
                    -- Ưu tiên fire ProximityPrompt nếu có
                    local prompt = obj:FindFirstChildWhichIsA("ProximityPrompt", true)
                    local done = false
                    if prompt then
                        pcall(function()
                            fireproximityprompt(prompt)
                            done = true
                        end)
                    end
                    if not done then
                        -- Fallback: nhấn Space qua VirtualInputManager (có thể không được phép)
                        pcall(function()
                            local vimService = game:GetService("VirtualInputManager")
                            vimService:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
                            task.wait(0.1)
                            vimService:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
                        end)
                    end
                    return true
                elseif dis <= 300 then
                    Topos(handle.CFrame)
                    return true
                end
            end
        end
    end
    return false
end

-- Tự nhận quest khi đạt level và chưa có quest hiển thị
-- ⚠ Giả định remote chuẩn Blox Fruits: CommF_:"StartQuest". pcall.
function TryAutoQuest(taskName)
    if not _ps.AutoQuest then
        return false
    end
    local cfg = FARM[taskName]
    if not cfg or not cfg.Quest then
        return false
    end

    local level = 0
    pcall(function()
        level = LP.Data.Level.Value
    end)
    if (tonumber(level) or 0) < (cfg.Level or 0) then
        return false
    end
    if QuestVisible() then
        return false
    end

    local started = false
    pcall(function()
        local remotes = RS:FindFirstChild("Remotes")
        local commf = remotes and remotes:FindFirstChild("CommF_")
        if commf then
            commf:InvokeServer("StartQuest", cfg.Quest, 1)
            started = true
        end
    end)
    return started
end

-- Tiếp cận mob + đánh
function Engage(name, isBoss)
    local mob = FindMob(name)
    if not mob then
        return false
    end
    local part = mob.PrimaryPart or mob:FindFirstChildWhichIsA("BasePart")
    if not part then
        return false
    end
    local range = isBoss and (_ps.AttackRange * 1.5) or _ps.AttackRange
    if not _ps.StopAll then
        Topos(part.CFrame)
        Attack(range, _ps.HitPlayers)
    end
    return true
end

function DoRandomRotate()
    local list = _ps.RandomNPCs
    if type(list) == "table" and #list > 0 then
        local entry = list[math.random(1, #list)]
        if entry and entry.Pos then
            Topos(entry.Pos)
            ST.Task = "Rotate: " .. tostring(entry.Name or "?")
        end
    end
    -- Lên lịch lần rotate kế tiếp (kể cả khi list rỗng, để không spam)
    local jitterMin = _ps.RotateJitter[1] or 60
    local jitterMax = _ps.RotateJitter[2] or 180
    _ps.NextRandomNPC = os.time() + _ps.RotateInterval + math.random(jitterMin, jitterMax)
    return true
end

function PickTask()
    if _ps.Priority ~= "Auto" then
        return _ps.Priority
    end
    if TyrantEyesCount() >= _ps.TyrantEyeThreshold then
        return "Tyrant"
    end
    if CheckCountItem("Bones", _ps.BonesThreshold) then
        return "Katakuri"
    end
    return "Bones"
end

function FarmTick()
    if _ps.StopAll then
        return
    end
    if PickupFruit() then
        return
    end
    if os.time() >= _ps.NextRandomNPC then
        if DoRandomRotate() then
            return
        end
    end

    local task_ = PickTask()
    ST.Task = task_
    if TryAutoQuest(task_) then
        return
    end

    if task_ == "Tyrant" then
        local cfg = FARM.Tyrant
        if not Engage(cfg.Boss, true) then
            if TyrantEyesCount() >= _ps.TyrantEyeThreshold then
                -- Boss chưa spawn nhưng mắt còn → bay tới island chứa mắt
                local island = Resolve(WS, table.concat(cfg.MapPath, "."))
                if island then
                    local base = island:IsA("BasePart") and island
                        or island:FindFirstChildWhichIsA("BasePart", true)
                    if base then
                        Topos(base.CFrame)
                    end
                end
            else
                Engage(cfg.Mob, false)
            end
        end
    elseif task_ == "Katakuri" then
        local cfg = FARM.Katakuri
        if not Engage(cfg.Boss, true) then
            Engage(cfg.Mob, false)
        end
    elseif task_ == "Bones" then
        local cfg = FARM.Bones
        if CheckCountItem(cfg.Item, _ps.BonesThreshold) then
            -- Đủ ngưỡng bones → bỏ quest, đợi PickTask chuyển sang Katakuri
            pcall(function()
                local remotes = RS:FindFirstChild("Remotes")
                local commf = remotes and remotes:FindFirstChild("CommF_")
                if commf then
                    commf:InvokeServer("AbandonQuest")
                end
            end)
            ST.Task = nil
        else
            Engage(cfg.Mob, false)
        end
    end
end

task.spawn(function()
    while true do
        local ok, err = pcall(FarmTick)
        if not ok then
            warn("[KAITUN] FarmTick error: " .. tostring(err))
        end
        pcall(ResetRejoinCounterIfNewJob)
        task.wait(_ps.AttackDelay)
    end
end)

Window = nil
GUIR = {}

local okLib, Lib = pcall(function()
    return loadstring(game:HttpGet(
        "https://raw.githubusercontent.com/Meo73preb/MeoYeuEm/refs/heads/main/Mate-Cat-Library.lua"
    ))()
end)

if okLib and Lib then
    Window = Lib:Window({
        Title = "Mate Cat Kaitun",
        Color = Color3.fromRGB(0, 220, 130),
    })
    local Tab = Window:Tab("Status")

    -- ⚠ Control
    Tab:Label("Control")
    Tab:Toggle("Stop All Farm", _ps.StopAll, function(state)
        _ps.StopAll = state
        if state then
            StopTopos()
        end
        Window:Notify("Control", state and "Da tat farm." or "Farm tiep tuc.", 3)
    end)
    Tab:Toggle("Auto Rejoin Self", _ps.AutoRejoinSelf, function(state)
        _ps.AutoRejoinSelf = state
        Window:Notify("Rejoin", state and "Lua tu rejoin." or "Chi log, khong rejoin.", 3)
    end)

    -- Current Activity
    Tab:Label("Current Activity")
    GUIR.taskLabel = Tab:Label("Task: Idle")
    GUIR.bonesLabel = Tab:Label("Bones: 0")
    GUIR.fruitLabel = Tab:Label("Fruit: None")
    GUIR.uptimeLabel = Tab:Label("Uptime: 00:00:00")
    GUIR.rotateLabel = Tab:Label("Rotate: --")

    -- Rejoin & Session
    Tab:Label("Rejoin & Session")
    GUIR.rejoinLabel = Tab:Label("Attempts: 0/2")
    GUIR.jobLabel = Tab:Label("JobId: ?")
    GUIR.kickFileLabel = Tab:Label("Kicks in file: 0")

    Tab:Button("Reset Rejoin Counter", function()
        ST.RejoinAttempts = 0
        ST.LastKickAt = nil
        Window:Notify("Rejoin", "Da reset counter.", 3)
    end)

    Tab:Button("Open Status File", function()
        if type(readfile) ~= "function" then
            warn("[KAITUN] readfile khong kha dung trong moi truong nay.")
            return
        end
        pcall(function()
            local content = tostring(readfile(_ps.StatusFile) or "")
            local lines = {}
            for line in content:gmatch("[^\r\n]+") do
                table.insert(lines, line)
            end
            local startIdx = math.max(1, #lines - 19)
            for i = startIdx, #lines do
                print("[STATUS] " .. lines[i])
            end
            Window:Notify("Status File", "In 20 dong cuoi ra console.", 3)
        end)
    end)

    -- Priority
    Tab:Label("Priority")
    Tab:Button("Force Tyrant", function()
        _ps.Priority = "Tyrant"
        Window:Notify("Priority", "Tyrant", 2)
    end)
    Tab:Button("Force Katakuri", function()
        _ps.Priority = "Katakuri"
        Window:Notify("Priority", "Katakuri", 2)
    end)
    Tab:Button("Force Bones", function()
        _ps.Priority = "Bones"
        Window:Notify("Priority", "Bones", 2)
    end)
    Tab:Button("Force Auto", function()
        _ps.Priority = "Auto"
        Window:Notify("Priority", "Auto", 2)
    end)

    -- Utility
    Tab:Label("Utility")
    Tab:Button("Stop Topos", function()
        StopTopos()
        Window:Notify("Topos", "Da dung.", 2)
    end)
    Tab:Button("Refresh Bones", function()
        pcall(function()
            GUIR.bonesLabel:Set("Bones: " .. tostring(GetItemCount("Bones")))
        end)
    end)
    Tab:Button("Refresh Kicks", function()
        pcall(function()
            local status = ReadStatusFile()
            GUIR.kickFileLabel:Set("Kicks in file: " .. tostring(status.kicks + status.prompts))
        end)
    end)

    Window:Notify("Loaded!", "Automation assistant san sang. Console: _ps.xxx = value", 5)
else
    warn("[KAITUN] Khong tai duoc Mate-Cat-Library — automation van chay khong GUI.")
end

-- GUI update loop
task.spawn(function()
    local lastBones = 0
    local lastBonesAt = 0
    local lastKicksText = "0"
    local lastKicksAt = 0

    while true do
        task.wait(1)
        if Window and GUIR.taskLabel then
            local okGui, guiErr = pcall(function()
                local stopped = _ps.StopAll and "[STOPPED]" or ""
                GUIR.taskLabel:Set(string.format(
                    "%s | Prio: %s %s",
                    tostring(ST.Task or "Idle"),
                    tostring(_ps.Priority),
                    stopped
                ))

                -- Bones cache 5s
                if os.clock() - lastBonesAt >= 5 then
                    lastBonesAt = os.clock()
                    pcall(function()
                        lastBones = GetItemCount("Bones")
                    end)
                end
                GUIR.bonesLabel:Set("Bones: " .. tostring(lastBones))

                -- Fruit live
                local fruit = GetPathFruit()
                GUIR.fruitLabel:Set("Fruit: " .. (fruit and fruit.Name or "None"))

                -- Uptime
                local up = math.floor(os.clock() - ST.StartTime)
                local h = math.floor(up / 3600)
                local m = math.floor((up % 3600) / 60)
                local s = up % 60
                GUIR.uptimeLabel:Set(string.format("Uptime: %02d:%02d:%02d", h, m, s))

                -- Rotate countdown
                local remain = _ps.NextRandomNPC - os.time()
                if remain < 0 then
                    remain = 0
                end
                GUIR.rotateLabel:Set("Rotate: " .. tostring(remain) .. "s")

                -- Rejoin info
                GUIR.rejoinLabel:Set(string.format(
                    "Attempts: %d/%d",
                    ST.RejoinAttempts or 0,
                    _ps.MaxSelfRejoin
                ))
                local job = tostring(game.JobId or "?")
                GUIR.jobLabel:Set("JobId: " .. string.sub(job, 1, 8))

                -- Kick file count (cache 10s)
                if os.clock() - lastKicksAt >= 10 then
                    lastKicksAt = os.clock()
                    pcall(function()
                        local status = ReadStatusFile()
                        lastKicksText = tostring(status.kicks + status.prompts)
                    end)
                end
                GUIR.kickFileLabel:Set("Kicks in file: " .. lastKicksText)
            end)
            if not okGui then
                warn("[KAITUN] GUI update error: " .. tostring(guiErr))
            end
        end
    end
end)
