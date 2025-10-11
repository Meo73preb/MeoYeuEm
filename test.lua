-- AutoFarm single-file minified
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Workspace=game:GetService("Workspace")
local TweenService=game:GetService("TweenService")
local RunService=game:GetService("RunService")
local player=Players.LocalPlayer
local playerGui=player:WaitForChild("PlayerGui")
_G.AutoFarm=_G.AutoFarm or false
_G.BringEnabled=_G.BringEnabled or false
_G.AutoAttack=_G.AutoAttack or true
local DEBUG=true
local function dbg(...) if DEBUG then print("[AF]",...) end end
local function warn(...) if DEBUG then warn("[AF]",...) end end

-- find registers
local function findRegisters()
  local ra,rh
  for _,v in pairs(ReplicatedStorage:GetDescendants()) do
    if (v.Name=="RE/RegisterAttack" or v.Name=="RegisterAttack") and (v:IsA("RemoteEvent") or v:IsA("RemoteFunction")) then ra=ra or v end
    if (v.Name=="RE/RegisterHit" or v.Name=="RegisterHit") and (v:IsA("RemoteEvent") or v:IsA("RemoteFunction")) then rh=rh or v end
  end
  return ra,rh
end
local RegisterAttack,RegisterHit=findRegisters()
dbg("RegisterAttack:",tostring(RegisterAttack),"RegisterHit:",tostring(RegisterHit))

-- load Quests module
local function loadQuestsModule()
  local q=ReplicatedStorage:FindFirstChild("Quests")
  if q and q:IsA("ModuleScript") then local ok,res=pcall(require,q) if ok then return res end end
  for _,v in pairs(ReplicatedStorage:GetDescendants()) do if v:IsA("ModuleScript") and v.Name=="Quests" then local ok,res=pcall(require,v) if ok then return res end end end
  return nil
end
local QuestsModule=loadQuestsModule()
if QuestsModule then dbg("Quests module loaded") else warn("Quests module not found") end

-- helpers
local function getLevel()
  local lvl
  pcall(function() if player:FindFirstChild("Data") and player.Data:FindFirstChild("Level") then lvl=player.Data.Level.Value end end)
  if not lvl then pcall(function() if player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("Level") then lvl=player.leaderstats.Level.Value end end) end
  if not lvl then lvl=player:GetAttribute("Level") end
  return lvl
end

local function parseModuleForBest(lvl)
  if not QuestsModule then return nil end
  local bestKey,bestEntry
  for key,arr in pairs(QuestsModule) do
    for _,entry in ipairs(arr) do
      if entry.LevelReq and entry.LevelReq<= (lvl or 0) then
        if not bestEntry or entry.LevelReq>bestEntry.LevelReq then bestKey,bestEntry=key,entry end
      end
    end
  end
  if bestEntry and bestKey then for mob,c in pairs(bestEntry.Task or {}) do return bestKey,tostring(mob),tonumber(c) end end
  return nil
end

local function findNearestMobByName(name,maxDist)
  if not name then return nil,{} end
  local myPos=player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character.HumanoidRootPart.Position or Vector3.new()
  local cand={}
  for _,m in pairs(Workspace:GetDescendants()) do
    if m:IsA("Model") and m:FindFirstChildWhichIsA("Humanoid") and m:FindFirstChild("HumanoidRootPart") then
      if m.Name:lower():find(name:lower()) then
        local d=(m.HumanoidRootPart.Position-myPos).Magnitude
        if (not maxDist) or d<=maxDist then table.insert(cand,{m=m,d=d}) end
      end
    end
  end
  if #cand==0 then return nil,{} end
  table.sort(cand,function(a,b) return a.d<b.d end)
  local list={}
  for _,v in ipairs(cand) do table.insert(list,v.m) end
  return list[1],list
end

-- smart move / tween + teleport
local TP_THRESHOLD=250
local TP_TWEEN_SPEED=900
local function smartMoveTo(pos)
  if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return end
  local hrp=player.Character.HumanoidRootPart
  local start=hrp.Position
  local dist=(pos-start).Magnitude
  if dist<=TP_THRESHOLD then pcall(function() hrp.CFrame=CFrame.new(pos+Vector3.new(0,3,0)) end) return end
  local dir=(pos-start).Unit
  local near=pos-dir*(TP_THRESHOLD-10)
  local dur=math.max(0.15,dist/TP_TWEEN_SPEED)
  local ok,tween=pcall(function() return TweenService:Create(hrp,TweenInfo.new(dur,Enum.EasingStyle.Linear),{CFrame=CFrame.new(near+Vector3.new(0,3,0))}) end)
  if ok and tween then pcall(function() tween:Play() end) task.wait(dur+0.05) end
  pcall(function() hrp.CFrame=CFrame.new(pos+Vector3.new(0,3,0)) end)
end

-- equip via Combat:EquipEvent fallback
local function tryCombatEquipEvent()
  local obj=(player.Character and player.Character:FindFirstChild("Combat")) or (player:FindFirstChild("Backpack") and player.Backpack:FindFirstChild("Combat"))
  if obj and obj:FindFirstChild("EquipEvent") then pcall(function() obj.EquipEvent:FireServer(true) end) dbg("Fired Combat:EquipEvent(true)") return true end
  return false
end

-- fire tool or RegisterHit/Attack
local function fireToolOrRegister(tool,targetPart)
  if tool then
    for _,v in pairs(tool:GetDescendants()) do
      local n=v.Name:lower()
      if (v:IsA("RemoteEvent") or v:IsA("RemoteFunction")) and n:find("fire") then
        pcall(function() if v:IsA("RemoteFunction") then v:InvokeServer(targetPart) else v:FireServer(targetPart) end end)
        return
      end
    end
  end
  if RegisterAttack and _G.AutoAttack then pcall(function() RegisterAttack:FireServer() end) end
  if RegisterHit and targetPart and _G.AutoAttack then pcall(function() RegisterHit:FireServer(targetPart) end) end
end

-- ensure equip (try event, then backpack)
local function ensureEquip()
  tryCombatEquipEvent()
  task.wait(0.12)
  local tool=player.Character and player.Character:FindFirstChildOfClass("Tool")
  if tool then return tool end
  if player:FindFirstChild("Backpack") then
    local tb=player.Backpack:FindFirstChildOfClass("Tool")
    if tb then
      local humanoid=player.Character and player.Character:FindFirstChildWhichIsA("Humanoid")
      if humanoid then for i=1,4 do pcall(function() humanoid:EquipTool(tb) end) task.wait(0.08) if tb.Parent==player.Character then return tb end end end
    end
  end
  return nil
end

-- bring group up to limit
local BRING_LIMIT=2
local BRING_DISTANCE=520
local function bringGroup(mobName)
  if not _G.BringEnabled then return end
  if not Workspace:FindFirstChild("Enemies") then return end
  local myHRP=player.Character and player.Character:FindFirstChild("HumanoidRootPart") if not myHRP then return end
  local got=0
  for _,m in pairs(Workspace.Enemies:GetChildren()) do
    if got>=BRING_LIMIT then break end
    if m and m:FindFirstChildWhichIsA("Humanoid") and m:FindFirstChild("HumanoidRootPart") and m.Name:lower():find((mobName or ""):lower()) then
      local hum=m:FindFirstChildWhichIsA("Humanoid"); local hrp=m:FindFirstChild("HumanoidRootPart")
      if hum and hrp and hum.Health>0 and (hrp.Position-myHRP.Position).Magnitude<=BRING_DISTANCE then
        pcall(function()
          if not m:GetAttribute("Bring_isBrought") then m:SetAttribute("Bring_prevWalkSpeed",hum.WalkSpeed or 0); m:SetAttribute("Bring_prevJumpPower",hum.JumpPower or 0); m:SetAttribute("Bring_isBrought",true) end
          hum.WalkSpeed=0; hum.JumpPower=0; hum.PlatformStand=true; hrp.CanCollide=false; if m:FindFirstChild("Head") then m.Head.CanCollide=false end
          hrp.CFrame=myHRP.CFrame*CFrame.new(0,-20,0)
        end)
        got=got+1
      end
    end
  end
end

-- small status UI + main GUI
local function buildUI()
  local sg=Instance.new("ScreenGui",playerGui); sg.Name="AutoFarm_MinUI"; sg.ResetOnSpawn=false
  local f=Instance.new("Frame",sg); f.Size=UDim2.new(0,320,0,180); f.Position=UDim2.new(0.01,0,0.04,0); f.BackgroundColor3=Color3.fromRGB(20,20,20); f.BackgroundTransparency=0.08
  local layout=Instance.new("UIListLayout",f); layout.Padding=UDim.new(0,8); layout.HorizontalAlignment=Enum.HorizontalAlignment.Center
  local function L(t) local l=Instance.new("TextLabel",f); l.Size=UDim2.new(0.95,0,0,24); l.Text=t; l.TextScaled=true; l.BackgroundTransparency=1; l.TextColor3=Color3.new(1,1,1); return l end
  local function B(t) local b=Instance.new("TextButton",f); b.Size=UDim2.new(0.95,0,0,34); b.Text=t; b.TextScaled=true; b.BackgroundColor3=Color3.fromRGB(60,60,60); b.TextColor3=Color3.fromRGB(1,1,1); return b end
  local lblLevel=L("Level: ?"); local lblQuest=L("Quest: -"); local lblProg=L("Progress: 0/0")
  local btnAuto=B("AutoFarm: OFF"); local btnBring=B("Bring: OFF"); local btnAttack=B("AutoAttack: ON")
  btnAuto.MouseButton1Click:Connect(function() _G.AutoFarm=not _G.AutoFarm; btnAuto.Text=_G.AutoFarm and "AutoFarm: ON" or "AutoFarm: OFF"; btnAuto.BackgroundColor3=_G.AutoFarm and Color3.fromRGB(60,120,60) or Color3.fromRGB(60,60,60) end)
  btnBring.MouseButton1Click:Connect(function() _G.BringEnabled=not _G.BringEnabled; btnBring.Text=_G.BringEnabled and "Bring: ON" or "Bring: OFF"; btnBring.BackgroundColor3=_G.BringEnabled and Color3.fromRGB(60,120,60) or Color3.fromRGB(60,60,60) end)
  btnAttack.MouseButton1Click:Connect(function() _G.AutoAttack=not _G.AutoAttack; btnAttack.Text=_G.AutoAttack and "AutoAttack: ON" or "AutoAttack: OFF"; btnAttack.BackgroundColor3=_G.AutoAttack and Color3.fromRGB(60,120,60) or Color3.fromRGB(60,60,60) end)
  return {sg=sg, lblLevel=lblLevel, lblQuest=lblQuest, lblProg=lblProg}
end

local UI=buildUI()

-- small status box
local function makeStatus()
  local sg=Instance.new("ScreenGui",playerGui); sg.Name="AF_Status"; sg.ResetOnSpawn=false
  local f=Instance.new("Frame",sg); f.Size=UDim2.new(0,240,0,90); f.Position=UDim2.new(0.015,0,0.28,0); f.BackgroundColor3=Color3.fromRGB(18,18,18); f.BackgroundTransparency=0.08
  local layout=Instance.new("UIListLayout",f); layout.Padding=UDim.new(0,6)
  local k=Instance.new("TextLabel",f); k.Size=UDim2.new(0.95,0,0,20); k.TextScaled=true; k.Text="Quest: -"; k.BackgroundTransparency=1; k.TextColor3=Color3.new(1,1,1)
  local m=Instance.new("TextLabel",f); m.Size=UDim2.new(0.95,0,0,20); m.TextScaled=true; m.Text="Mob: -"; m.BackgroundTransparency=1; m.TextColor3=Color3.new(1,1,1)
  local p=Instance.new("TextLabel",f); p.Size=UDim2.new(0.95,0,0,20); p.TextScaled=true; p.Text="Prog: 0/0"; p.BackgroundTransparency=1; p.TextColor3=Color3.new(1,1,1)
  return {gui=sg,k=k,m=m,p=p}
end
local Status=makeStatus()

-- watchers
local active={key=nil,mob=nil,need=0,progress=0,started=false}
local deathConns={}
local function clearDeathConns() for _,c in pairs(deathConns) do pcall(function() c:Disconnect() end) end deathConns={} end
local function watchDeaths(mobName)
  clearDeathConns(); active.progress=0
  local en=Workspace:FindFirstChild("Enemies") if not en then return end
  for _,m in pairs(en:GetChildren()) do
    if m and m:FindFirstChildWhichIsA("Humanoid") and m.Name:lower():find(mobName:lower()) then local h=m:FindFirstChildWhichIsA("Humanoid") if h then table.insert(deathConns,h.Died:Connect(function() active.progress=active.progress+1 end)) end end
  end
  if en then table.insert(deathConns,en.ChildAdded:Connect(function(ch) if ch and ch:FindFirstChildWhichIsA("Humanoid") and ch.Name:lower():find(mobName:lower()) then local h=ch:FindFirstChildWhichIsA("Humanoid") if h then table.insert(deathConns,h.Died:Connect(function() active.progress=active.progress+1 end)) end end end)) end
end

local function refreshProgressFromServer(qKey)
  if not qKey then return end
  local data=player:FindFirstChild("Data") if not data then return end
  pcall(function() if data:FindFirstChild("Quests") and data.Quests:FindFirstChild(qKey) then local qf=data.Quests[qKey]; if qf:FindFirstChild("Progress") then active.progress=qf.Progress.Value end; if qf:FindFirstChild("Required") then active.need=qf.Required.Value end end end)
end

local QuestsLookup={BanditQuest1={questPos=Vector3.new(1059,17,1546)},DesertQuest={questPos=Vector3.new(897,6,4389)}}
local function safeStartQuest(qKey)
  if not qKey then return end
  local pos=(QuestsLookup[qKey] and QuestsLookup[qKey].questPos) and QuestsLookup[qKey].questPos or nil
  local origin=player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character.HumanoidRootPart.CFrame or nil
  if pos then smartMoveTo(pos) task.wait(0.08) end
  pcall(function() for _,v in pairs(ReplicatedStorage:GetDescendants()) do if v.Name=="CommF_" or v.Name=="CommF" then if v:IsA("RemoteFunction") and v.InvokeServer then v:InvokeServer("StartQuest",qKey,1) end; if v:IsA("RemoteEvent") and v.FireServer then v:FireServer("StartQuest",qKey,1) end; break end end end)
  task.wait(0.08) if origin then smartMoveTo(origin.Position) end
end

-- main loop
task.spawn(function()
  dbg("AutoFarm loaded")
  while task.wait(0.5) do
    -- update level label
    UI.lblLevel.Text="Level: "..tostring(getLevel() or "?")
    -- proceed
    if not _G.AutoFarm or not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then continue end
    local lvl=getLevel() if not lvl then task.wait(0.6) continue end
    local key,mobName,need=parseModuleForBest(lvl)
    if not key then task.wait(0.8) continue end
    if active.key~=key then active.key=key; active.mob=mobName; active.need=need or 0; active.progress=0; active.started=false; Status.k.Text="Quest: "..tostring(active.key); Status.m.Text="Mob: "..tostring(active.mob); Status.p.Text="Prog: 0/"..tostring(active.need) end
    if active.key and not active.started then safeStartQuest(active.key) task.wait(0.12) watchDeaths(active.mob) refreshProgressFromServer(active.key) active.started=true end
    refreshProgressFromServer(active.key)
    if active.need>0 and active.progress>=active.need then dbg("Quest complete -> clearing"); active={key=nil,mob=nil,need=0,progress=0,started=false}; clearDeathConns(); Status.k.Text="Quest: -"; Status.m.Text="Mob: -"; Status.p.Text="Prog: 0/0"; task.wait(0.6); continue end
    -- find nearest
    local CLOSE=220; local FAR=1200
    local mob,list=findNearestMobByName(active.mob,CLOSE)
    if not mob then local far,fl=findNearestMobByName(active.mob,FAR) if far then dbg("Far mob found -> move"); smartMoveTo(far.HumanoidRootPart.Position); task.wait(0.4); mob,list=findNearestMobByName(active.mob,CLOSE) else dbg("No mobs"),task.wait(1); continue end end
    if _G.BringEnabled and active.mob then bringGroup(active.mob) task.wait(0.08) end
    mob=findNearestMobByName(active.mob,1000)
    if not mob or not mob.HumanoidRootPart then task.wait(0.3) continue end
    local h=mob:FindFirstChildWhichIsA("Humanoid"); local hrp=mob:FindFirstChild("HumanoidRootPart")
    if not h or not hrp or h.Health<=0 then task.wait(0.2) continue end
    local tool=ensureEquip()
    local stop=false
    local co=coroutine.create(function() while not stop and h and h.Health>0 and _G.AutoFarm do if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then local my=player.Character.HumanoidRootPart; pcall(function() my.AssemblyLinearVelocity=Vector3.new(0,0,0); my.Velocity=Vector3.new(0,0,0); my.CFrame=CFrame.new(hrp.Position+Vector3.new(0,20,0)); local ph=player.Character:FindFirstChildWhichIsA("Humanoid"); if ph then ph.PlatformStand=true end end) end task.wait(0.06) end pcall(function() if player.Character and player.Character:FindFirstChildWhichIsA("Humanoid") then player.Character:FindFirstChildWhichIsA("Humanoid").PlatformStand=false end end) end)
    coroutine.resume(co)
    while h and h.Health>0 and _G.AutoFarm do fireToolOrRegister(tool,hrp) task.wait(0.12) end
    stop=true
    task.wait(0.15)
    refreshProgressFromServer(active.key)
    Status.p.Text=string.format("Prog: %d / %d",active.progress or 0,active.need or 0)
  end
end)
print("[AF] loaded")
