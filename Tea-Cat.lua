-- Tea Cat GUI Library - Beta v2.0 (Fix all bug or add bug :>)
-- [FIX v14] Khuyến nghị dùng TCH.SafeSet(instance, prop, value) khi update UI trong callback
-- (đặc biệt trong job của TCH:Loop) để tránh crash khi tab/element đã bị destroy.
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")

local TCH = {}

local activeWindow
local activeGui
local _math = math
local _task = task
local _coroutine = coroutine
local _table = table

-- [FIX v2] Đồng hồ wall-clock dùng chung cho TCH:Loop.
-- Trên Roblox, os.clock() là CPU time nên không dùng để đo interval (cộng dồn dt sẽ drift).
-- tick() là wall-clock và có trên mọi executor phổ biến; os.clock chỉ là fallback cuối.
local _rawClock = (type(tick) == "function" and tick) or function()
    return os.clock()
end
local function wallClock()
    local ok, value = pcall(_rawClock)
    if ok and type(value) == "number" then return value end
    return os.clock()
end

local function clamp(value, minimum, maximum)
    value = tonumber(value) or minimum
    return _math.max(minimum, _math.min(maximum, value))
end

local function getTargetParent()
    -- Có thể đọc CoreGui nhưng không được ghi, nên kiểm tra quyền parent thực tế.
    local canUseCoreGui = pcall(function()
        local probe = Instance.new("ScreenGui")
        probe.Name = "TeaCatPermissionProbe"
        probe.Parent = CoreGui
        probe:Destroy()
    end)
    if canUseCoreGui then return CoreGui end

    local player = Players.LocalPlayer
    if player then return player:WaitForChild("PlayerGui") end
    return CoreGui
end

local TargetParent = getTargetParent()

local function newMaid()
    local maid = { tasks = {}, destroyed = false }

    function maid:Add(resource)
        if resource == nil then return resource end
        if self.destroyed then
            self:_cleanupOne(resource)
            return resource
        end
        _table.insert(self.tasks, resource)
        return resource
    end

    function maid:Remove(resource)
        for index = #self.tasks, 1, -1 do
            if self.tasks[index] == resource then
                _table.remove(self.tasks, index)
                return true
            end
        end
        return false
    end

    function maid:_cleanupOne(resource)
        local resourceType = type(resource)
        if resourceType == "function" then
            pcall(resource)
        elseif resourceType == "thread" then
            pcall(_task.cancel, resource)
        elseif resourceType == "table" then
            if type(resource.Cleanup) == "function" then
                pcall(function() resource:Cleanup() end)
            elseif type(resource.Disconnect) == "function" then
                pcall(function() resource:Disconnect() end)
            elseif type(resource.Destroy) == "function" then
                pcall(function() resource:Destroy() end)
            elseif type(resource.Cancel) == "function" then
                pcall(function() resource:Cancel() end)
            end
        elseif resourceType == "userdata" then
            pcall(function()
                if resource.Disconnect then
                    resource:Disconnect()
                elseif resource.Cancel then
                    resource:Cancel()
                elseif resource.Destroy then
                    resource:Destroy()
                end
            end)
        end
    end

    function maid:Cleanup()
        if self.destroyed then return end
        self.destroyed = true
        local tasks = self.tasks
        self.tasks = {}
        for index = #tasks, 1, -1 do
            self:_cleanupOne(tasks[index])
            tasks[index] = nil
        end
    end

    return maid
end

local function create(className, properties)
    local instance = Instance.new(className)
    local parent
    for key, value in pairs(properties or {}) do
        if key == "Parent" then
            parent = value
        elseif type(key) ~= "number" then
            instance[key] = value
        end
    end
    for key, value in pairs(properties or {}) do
        if type(key) == "number" and typeof(value) == "Instance" then
            value.Parent = instance
        end
    end
    if parent ~= nil then instance.Parent = parent end
    return instance
end

local function safeCallback(callback, ...)
    if type(callback) ~= "function" then return true end
    local ok, err = pcall(callback, ...)
    if not ok then
        warn("Tea GUI callback error: " .. tostring(err))
    end
    return ok
end

local function normalizeBoolean(value, fallback)
    if type(value) == "boolean" then
        return value
    end
    return fallback == true
end

-- Config store: giữ false là giá trị hợp lệ, không dùng pattern `value or fallback`.
function TCH:Config(options)
    options = type(options) == "table" and options or {}
    local store = {
        source = type(options.source) == "table" and options.source or {},
        defaults = type(options.defaults) == "table" and options.defaults or {},
        path = type(options.path) == "string" and options.path or nil,
        namespace = tostring(options.namespace or "TeaCat"),
        api = type(options.api) == "table" and options.api or nil,
    }

    local function backend(name)
        if store.api and type(store.api[name]) == "function" then
            return store.api[name]
        end

        local environments, seen = {}, {}
        local function addEnvironment(environment)
            if type(environment) == "table" and not seen[environment] then
                seen[environment] = true
                environments[#environments + 1] = environment
            end
        end

        addEnvironment(_G)
        local ok, environment = pcall(function()
            if type(getgenv) == "function" then return getgenv() end
        end)
        if ok then addEnvironment(environment) end

        ok, environment = pcall(function() return shared end)
        if ok then addEnvironment(environment) end

        if type(getfenv) == "function" then
            ok, environment = pcall(getfenv, 0)
            if ok then addEnvironment(environment) end
            ok, environment = pcall(getfenv, 1)
            if ok then addEnvironment(environment) end
        end

        for _, candidate in ipairs(environments) do
            local lookupOk, value = pcall(function() return candidate[name] end)
            if lookupOk and type(value) == "function" then return value end
        end
        return nil
    end

    function store:SetSource(source)
        if type(source) == "table" then self.source = source end
        return self
    end

    function store:UseGlobal(globalTable, namespace)
        if type(globalTable) ~= "table" then return self end
        if namespace and namespace ~= "" then
            globalTable[namespace] = type(globalTable[namespace]) == "table" and globalTable[namespace] or {}
            self.source = globalTable[namespace]
        else
            self.source = globalTable
        end
        return self
    end

    function store:SetPath(folder, fileName)
        if type(folder) ~= "string" or folder == "" then return self end
        if type(fileName) ~= "string" or fileName == "" then return self end
        self.path = folder .. "/" .. fileName
        return self
    end

    function store:Get(key, fallback)
        local value = self.source[key]
        if value == nil then value = self.defaults[key] end
        if value == nil then value = fallback end
        return value
    end

    function store:GetBoolean(key, fallback)
        return normalizeBoolean(self:Get(key, nil), fallback)
    end

    function store:Set(key, value)
        self.source[key] = value
        return value
    end

    function store:Reset(key)
        if key == nil then
            for name in pairs(self.source) do self.source[name] = nil end
        else
            self.source[key] = nil
        end
        return self
    end

    function store:Exists()
        if not self.path then return false end
        local isfile = backend("isfile")
        if not isfile then return false end
        local ok, exists = pcall(isfile, self.path)
        return ok and exists == true
    end

    function store:Delete()
        if not self.path then return true end
        local delfile = backend("delfile")
        if not delfile then return false, "delfile API unavailable" end
        if not self:Exists() then return true end
        local ok, err = pcall(delfile, self.path)
        return ok, ok and nil or err
    end

    function store:Load()
        if not self.path then return true end
        local isfile, readfile = backend("isfile"), backend("readfile")
        if not isfile or not readfile then return false, "filesystem API unavailable" end
        local okFile, exists = pcall(isfile, self.path)
        if not okFile then return false, exists end
        if not exists then
            return self:Save()
        end
        local okRead, content = pcall(readfile, self.path)
        if not okRead then return false, content end
        local okDecode, decoded = pcall(function() return HttpService:JSONDecode(content) end)
        if not okDecode or type(decoded) ~= "table" then return false, decoded end
        for key, value in pairs(decoded) do self.source[key] = value end
        return true
    end

    function store:Save()
        if not self.path then return true end
        local writefile = backend("writefile")
        if not writefile then return false, "writefile API unavailable" end
        local folder = self.path:match("^(.*)/[^/]+$")
        if folder and folder ~= "" then
            local isfolder, makefolder = backend("isfolder"), backend("makefolder")
            if not isfolder or not makefolder then
                return false, "folder API unavailable"
            end
            local current = folder:sub(1, 1) == "/" and "/" or ""
            for part in folder:gmatch("[^/]+") do
                if current == "" then
                    current = part
                elseif current == "/" then
                    current = current .. part
                else
                    current = current .. "/" .. part
                end
                local okFolder, exists = pcall(isfolder, current)
                if not okFolder then return false, exists end
                if not exists then
                    local okMake, err = pcall(makefolder, current)
                    if not okMake then return false, err end
                end
            end
        end
        local okEncode, encoded = pcall(function() return HttpService:JSONEncode(self.source) end)
        if not okEncode then return false, encoded end
        local okWrite, err = pcall(writefile, self.path, encoded)
        return okWrite, okWrite and nil or err
    end

    function store:SaveDebounced(delaySeconds)
        if self._saveThread then pcall(_task.cancel, self._saveThread) end
        self._saveThread = _task.delay(tonumber(delaySeconds) or 0.5, function()
            self._saveThread = nil
            local ok, err = self:Save()
            if not ok then warn("Tea Config save failed: " .. tostring(err)) end
        end)
        return self
    end

    function store:Destroy()
        if self._saveThread then pcall(_task.cancel, self._saveThread) end
        self._saveThread = nil
        self.source, self.defaults = {}, {}
    end

    return store
end

-- [FIX v1] Buffer module-level tái sử dụng: KHÔNG tạo table trong Heartbeat.
local _loopBuf = {}
-- [FIX v1] buffer tham chiếu job, xả sau mỗi frame

local LOOP_WARN_INTERVAL = 5      -- [FIX v3] tối đa 1 warn / 5s / job
local LOOP_MAX_ERRORS = 60        -- [FIX v3] kill job sau 60 lỗi liên tiếp
local LOOP_OVERRUN_LIMIT = 0.05   -- [FIX v6] 50ms
local LOOP_OVERRUN_WARN = 10      -- [FIX v6] tối đa 1 warn block / 10s / job

local function loopDisconnectIfEmpty(manager)
    if manager.jobCount <= 0 and manager.connection then
        manager.connection:Disconnect()
        manager.connection = nil
    end
end

local function loopRemoveJob(manager, job)
    if not job or job.dead then return end
    job.dead = true
    job.active = false
    if manager.jobs[job.id] == job then
        manager.jobs[job.id] = nil
        manager.jobCount = manager.jobCount - 1
    end
    manager.orderDirty = true -- [FIX v5] dọn id khỏi jobOrder ở cuối frame
    loopDisconnectIfEmpty(manager)
end

-- [FIX v5] Compact jobOrder SAU khi duyệt xong: không sửa array đang lặp.
local function loopCompactOrder(manager)
    if not manager.orderDirty then return end
    manager.orderDirty = false
    local order, write = manager.jobOrder, 1
    for read = 1, #order do
        local id = order[read]
        local job = manager.jobs[id]
        if job and not job.dead then
            order[write] = id
            write = write + 1
        end
    end
    for index = #order, write, -1 do
        order[index] = nil
    end
end

local function loopStep(manager, dt)
    local order, jobs = manager.jobOrder, manager.jobs
    local count = #order

    -- [FIX v1] Chỉ copy tham chiếu job vào buffer có sẵn (không alloc table mới).
    local buf = _loopBuf
    for index = 1, count do
        buf[index] = jobs[order[index]]
    end

    -- [FIX v2] Wall-clock 1 lần / frame, không cộng dồn dt → không drift.
    local now = wallClock()

    for index = 1, count do
        local job = buf[index]
        if job and not job.dead and job.active and jobs[job.id] == job then
            local interval = job.interval
            if interval <= 0 or now >= job.nextRun then
                -- [FIX v2] Reschedule TRƯỚC khi gọi callback:
                -- callback lỗi hay tự Disconnect cũng không bị double-run.
                if interval > 0 then
                    job.nextRun = now + interval
                else
                    job.nextRun = now
                end

                local cpuStart = os.clock() -- [FIX v6] CPU time: không false-positive khi callback yield
                local ok, err = pcall(job.callback, dt)
                local blocked = os.clock() - cpuStart

                if ok then
                    job.warnCount = 0 -- [FIX v3] chạy được thì reset bộ đếm lỗi
                else
                    job.warnCount = job.warnCount + 1
                    if job.warnCount > LOOP_MAX_ERRORS then
                        -- [FIX v3] auto-kill job zombie để không block cả manager
                        loopRemoveJob(manager, job)
                        warn(string.format("[TeaLoop] Đã kill job #%d sau %d lỗi liên tiếp: %s",
                            job.id, job.warnCount - 1, tostring(err)))
                    elseif now - job.warnLast >= LOOP_WARN_INTERVAL then
                        job.warnLast = now
                        warn(string.format("[TeaLoop] job #%d lỗi (%d liên tiếp): %s",
                            job.id, job.warnCount, tostring(err)))
                    end
                end

                -- [FIX v6] Watchdog: chỉ warn, KHÔNG kill (kill giữa callback không an toàn).
                if not job.dead and blocked > LOOP_OVERRUN_LIMIT
                    and now - job.overrunLast >= LOOP_OVERRUN_WARN then
                    job.overrunLast = now
                    warn(string.format("[TeaLoop] job #%d chạy %dms (>50ms) — có thể block các job khác",
                        job.id, _math.floor(blocked * 1000)))
                end
            end
        end
    end

    -- [FIX v1] Xả buffer để không giữ reference tới job/window đã chết.
    for index = 1, count do
        buf[index] = nil
    end

    loopCompactOrder(manager)
end

local loopManagers = {}
function TCH:Loop(signalName)
    signalName = signalName == "RenderStepped" and "RenderStepped" or "Heartbeat"
    local manager = loopManagers[signalName]
    if not manager then
        manager = {
            jobs = {},
            jobOrder = {},  -- [FIX v5] array id, duyệt theo thứ tự Connect
            jobCount = 0,
            nextId = 0,
            orderDirty = false,
            connection = nil,
        }
        loopManagers[signalName] = manager
    end
    local signal = RunService[signalName]
    local api = {}
    function api:Connect(callbackOrOptions)
        local callback, interval
        if type(callbackOrOptions) == "function" then
            callback = callbackOrOptions
        elseif type(callbackOrOptions) == "table" then
            callback = callbackOrOptions.callback
            interval = tonumber(callbackOrOptions.interval)
        end
        if type(callback) ~= "function" then return nil end

        manager.nextId = manager.nextId + 1
        interval = (interval and interval > 0) and interval or 0

        local job = {
            id = manager.nextId,
            orderId = manager.nextId,                                -- [FIX v5]
            callback = callback,
            interval = interval,
            nextRun = interval > 0 and (wallClock() + interval) or 0, -- [FIX v2]
            active = true,
            dead = false,
            warnLast = 0,     -- [FIX v3]
            warnCount = 0,    -- [FIX v3]
            overrunLast = 0,  -- [FIX v6]
        }

        manager.jobs[job.id] = job
        manager.jobCount = manager.jobCount + 1

        local order = manager.jobOrder
        order[#order + 1] = job.id
        -- [FIX v5] id luôn tăng dần nên array gần như luôn đã sort;
        -- chỉ sort khi thật sự lệch (rẻ hơn sort mỗi lần Connect).
        if #order > 1 and order[#order - 1] > order[#order] then
            _table.sort(order)
        end

        if not manager.connection then
            manager.connection = signal:Connect(function(dt)
                loopStep(manager, dt)
            end)
        end

        local handle = {}

        function handle:Disconnect()
            loopRemoveJob(manager, job)
        end

        function handle:Destroy()
            handle:Disconnect()
        end

        -- [FIX v4] Đổi interval runtime, không cần Disconnect/Connect lại.
        function handle:SetInterval(newInterval)
            newInterval = tonumber(newInterval)
            if not newInterval or newInterval < 0 then return job.interval end
            job.interval = newInterval > 0 and newInterval or 0
            job.nextRun = job.interval > 0 and (wallClock() + job.interval) or 0
            return job.interval
        end

        -- [FIX v4] Pause/resume không mất state; resume chạy lại ngay frame kế tiếp.
        function handle:SetActive(isActive)
            if job.dead then return false end
            local value = (isActive ~= false and isActive ~= nil)
            job.active = value
            if value then
                job.nextRun = wallClock()
            end
            return value
        end

        function handle:IsActive()
            return job.active and not job.dead
        end

        function handle:GetInterval()
            return job.interval
        end

        function handle:GetId()
            return job.id
        end

        -- [FIX v15] Job tạo trong lúc window đang mở sẽ bị ngắt khi window:Destroy().
        if activeWindow and not activeWindow.destroyed and activeWindow.trackLoopHandle then
            activeWindow:trackLoopHandle(handle)
        end

        return handle
    end
    return api
end

local function makeDraggable(maid, dragObject, moveObject)
    local dragging = false
    local dragInput
    local startInputPosition
    local startGuiPosition
    local dragEndConnection

    maid:Add(function()
        if dragEndConnection then
            dragEndConnection:Disconnect()
            dragEndConnection = nil
        end
    end)

    maid:Add(dragObject.InputBegan:Connect(function(input)
        local inputType = input.UserInputType
        if inputType ~= Enum.UserInputType.MouseButton1
            and inputType ~= Enum.UserInputType.Touch then
            return
        end
        dragging = true
        startInputPosition = input.Position
        startGuiPosition = moveObject.Position
        if dragEndConnection then dragEndConnection:Disconnect() end
        dragEndConnection = input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
                dragInput = nil -- [FIX v8] xả tham chiếu input cũ
                dragEndConnection:Disconnect()
                dragEndConnection = nil
            end
        end)
    end))

    maid:Add(dragObject.InputChanged:Connect(function(input)
        local inputType = input.UserInputType
        if inputType == Enum.UserInputType.MouseMovement
            or inputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end))

    -- [FIX v8] Guard sớm (đã có) + connection được maid cleanup → giữ nguyên, không gộp shared.
    maid:Add(UserInputService.InputChanged:Connect(function(input)
        if not dragging or input ~= dragInput then return end
        local delta = input.Position - startInputPosition
        moveObject.Position = UDim2.new(
            startGuiPosition.X.Scale,
            startGuiPosition.X.Offset + delta.X,
            startGuiPosition.Y.Scale,
            startGuiPosition.Y.Offset + delta.Y
        )
    end))
end

-- [FIX v7] Shared slider manager: chỉ 2 connection UserInputService cho TẤT CẢ slider.
local _sliderActive = nil
local _sliderSharedReady = false
local function ensureSliderShared()
    if _sliderSharedReady then return end
    _sliderSharedReady = true

    UserInputService.InputChanged:Connect(function(input)
        local active = _sliderActive
        if not active or not active.isSliding then return end
        local inputType = input.UserInputType
        if inputType == Enum.UserInputType.MouseMovement
            or inputType == Enum.UserInputType.Touch then
            active.update(input)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        local active = _sliderActive
        if not active then return end
        local inputType = input.UserInputType
        if inputType == Enum.UserInputType.MouseButton1
            or inputType == Enum.UserInputType.Touch then
            _sliderActive = nil
            active.stop()
        end
    end)
end

local function addTween(maid, instance, info, properties)
    local tween = TweenService:Create(instance, info, properties)
    maid:Add(tween)
    local completedConnection
    completedConnection = tween.Completed:Connect(function()
        if completedConnection then
            completedConnection:Disconnect()
            completedConnection = nil
        end
        maid:Remove(tween)
    end)
    tween:Play()
    return tween
end

-- [FIX v10] Thay AutomaticCanvasSize: chỉ set CanvasSize khi AbsoluteContentSize đổi.
-- Trước đây mỗi create() trong page làm ScrollingFrame recalc canvas → bulk-add 50 element
-- = 50 recalc. Vẫn update khi content đổi nên scroll không hỏng (bắt buộc giữ).
local function bindCanvasSize(maid, frame, layout, extraY)
    if not frame or not layout then return end
    local padding = tonumber(extraY) or 0
    local function apply()
        if not frame.Parent then return end
        local content = layout.AbsoluteContentSize
        frame.CanvasSize = UDim2.new(0, content.X, 0, content.Y + padding)
    end
    maid:Add(layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(apply))
    apply()
    -- Trả về hàm apply để tab có thể refresh lúc switch (page ẩn lúc build).
    return apply
end

-- [FIX v12] Giới hạn notification: tối đa 8 cái, vượt thì destroy cái cũ nhất.
local MAX_NOTIFICATIONS = 8
local function trimNotifications(window)
    local container = window.notificationContainer
    if not container then return end
    local frames = {}
    for _, child in ipairs(container:GetChildren()) do
        if child:IsA("Frame") then frames[#frames + 1] = child end
    end
    local overflow = #frames - MAX_NOTIFICATIONS + 1
    for index = 1, overflow do
        local oldest = frames[index]
        if oldest and oldest.Parent then
            oldest:Destroy()
            window.maid:Remove(oldest)
        end
    end
end

local function buildNotification(window, title, description, duration)
    trimNotifications(window) -- [FIX v12] container luôn <= 8 cái
    local notification = create("Frame", {
        BackgroundColor3 = Color3.fromRGB(20, 20, 20),
        Size = UDim2.new(1, 0, 0, 60),
        Parent = window.notificationContainer,
        create("UICorner", { CornerRadius = UDim.new(0, 4) }),
        create("UIStroke", { Color = window.ThemeCol, Thickness = 1 }),
        create("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 10, 0, 5),
            Size = UDim2.new(1, -20, 0, 20),
            Text = tostring(title or "Thông báo"),
            TextColor3 = window.ThemeCol,
            Font = Enum.Font.GothamBold,
            TextSize = 16,
            TextXAlignment = Enum.TextXAlignment.Left,
        }),
        create("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 10, 0, 25),
            Size = UDim2.new(1, -20, 0, 30),
            Text = tostring(description or ""),
            TextColor3 = Color3.fromRGB(200, 200, 200),
            Font = Enum.Font.Gotham,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextWrapped = true,
        }),
    })
    window.maid:Add(notification)
    -- [FIX v13] Delay thread vẫn được maid:Add (đúng pattern) và guard notification.Parent
    -- nên nếu V12 destroy notification trước thì delay vẫn vô hại.
    local delayThread
    delayThread = _task.delay(_math.max(0, tonumber(duration) or 3), function()
        if notification.Parent then notification:Destroy() end
        window.maid:Remove(notification)
        if delayThread then window.maid:Remove(delayThread) end
    end)
    window.maid:Add(delayThread)
end

local function createWindow(library, config)
    config = type(config) == "table" and config or {}
    local windowMaid = newMaid()
    local themeColor = typeof(config.Color) == "Color3"
        and config.Color or Color3.fromRGB(0, 255, 128)
    local window = {
        Title = tostring(config.Title or "Tea Cat Hub"),
        ThemeCol = themeColor,
        Tabs = {},
        CurrentTab = nil,
        maid = windowMaid,
        destroyed = false,
        notificationContainer = nil,
        loopHandles = {}, -- [FIX v15]
    }
    library.ThemeCol = window.ThemeCol

    -- [FIX v15] Job TCH:Loop tạo trong lúc window sống → bị ngắt khi window:Destroy().
    function window:trackLoopHandle(handle)
        if self.destroyed then
            pcall(function() handle:Disconnect() end)
            return handle
        end
        self.loopHandles[#self.loopHandles + 1] = handle
        return handle
    end

    local gui = create("ScreenGui", {
        Name = "TCHub",
        Parent = TargetParent,
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    })
    window.gui = gui
    windowMaid:Add(gui)

    local main = create("Frame", {
        BackgroundColor3 = Color3.fromRGB(18, 18, 18),
        Size = UDim2.new(0, 500, 0, 350),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Parent = gui,
        ClipsDescendants = true,
        create("UICorner", { CornerRadius = UDim.new(0, 4) }),
        create("UIStroke", { Color = window.ThemeCol, Thickness = 1 }),
    })

    local floatButton = create("ImageButton", {
        BackgroundColor3 = Color3.fromRGB(15, 15, 15),
        Size = UDim2.new(0, 45, 0, 45),
        Position = UDim2.new(0, 10, 0, 10),
        Parent = gui,
        AutoButtonColor = false,
        create("UICorner", { CornerRadius = UDim.new(1, 0) }),
        create("UIStroke", { Color = window.ThemeCol, Thickness = 2 }),
        create("ImageLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(0, 25, 0, 25),
            Position = UDim2.new(0.5, 0, 0.5, 0),
            AnchorPoint = Vector2.new(0.5, 0.5),
            Image = "rbxassetid://13940080072",
        }),
    })
    makeDraggable(windowMaid, floatButton, floatButton)
    windowMaid:Add(floatButton.MouseButton1Click:Connect(function()
        if not window.destroyed then main.Visible = not main.Visible end
    end))

    local top = create("Frame", {
        BackgroundColor3 = Color3.fromRGB(12, 12, 12),
        Size = UDim2.new(1, 0, 0, 35),
        Parent = main,
        create("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -10, 1, 0),
            Position = UDim2.new(0, 10, 0, 0),
            Text = window.Title,
            TextColor3 = window.ThemeCol,
            Font = Enum.Font.GothamBold,
            TextSize = 16,
            TextXAlignment = Enum.TextXAlignment.Left,
        }),
        create("Frame", {
            BackgroundColor3 = window.ThemeCol,
            Size = UDim2.new(1, 0, 0, 1),
            Position = UDim2.new(0, 0, 1, 0),
            BorderSizePixel = 0,
        }),
    })
    makeDraggable(windowMaid, top, main)

    -- [FIX v10] Tắt AutomaticCanvasSize, tự quản CanvasSize qua listener AbsoluteContentSize.
    local tabLayout = create("UIListLayout", { Padding = UDim.new(0, 2) })
    local tabContainer = create("ScrollingFrame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 120, 1, -36),
        Position = UDim2.new(0, 0, 0, 36),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.None,
        ScrollBarThickness = 0,
        Parent = main,
        tabLayout,
        create("UIPadding", {
            PaddingTop = UDim.new(0, 5),
            PaddingLeft = UDim.new(0, 5),
            PaddingRight = UDim.new(0, 5),
        }),
    })
    bindCanvasSize(windowMaid, tabContainer, tabLayout, 5) -- [FIX v10]
    local pageContainer = create("Frame", {
        BackgroundColor3 = Color3.fromRGB(22, 22, 22),
        Size = UDim2.new(1, -120, 1, -36),
        Position = UDim2.new(0, 120, 0, 36),
        Parent = main,
    })

    local notificationGui = create("ScreenGui", {
        Name = "TCHub_Noti",
        Parent = TargetParent,
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    })
    local notificationContainer = create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 300, 1, -40),
        Position = UDim2.new(1, -15, 0, 20),
        AnchorPoint = Vector2.new(1, 0),
        Parent = notificationGui,
        create("UIListLayout", {
            Padding = UDim.new(0, 10),
            VerticalAlignment = Enum.VerticalAlignment.Bottom,
            HorizontalAlignment = Enum.HorizontalAlignment.Right,
        }),
    })
    window.notificationContainer = notificationContainer
    windowMaid:Add(notificationGui)

    function window:Notify(title, description, duration)
        if not self.destroyed then
            buildNotification(self, title, description, duration)
        end
    end

    function window:Tab(name)
        if window.destroyed then return nil end
        local tabMaid = newMaid()
        windowMaid:Add(tabMaid)
        local tab = { Elements = {}, maid = tabMaid, destroyed = false }
        local tabButton = create("TextButton", {
            BackgroundColor3 = Color3.fromRGB(25, 25, 25),
            Size = UDim2.new(1, 0, 0, 30),
            Text = tostring(name or "Tab"),
            TextColor3 = Color3.fromRGB(200, 200, 200),
            Font = Enum.Font.Gotham,
            TextSize = 14,
            AutoButtonColor = false,
            Parent = tabContainer,
            create("UICorner", { CornerRadius = UDim.new(0, 4) }),
        })
        -- [FIX v10] page: AutomaticCanvasSize = None, CanvasSize do bindCanvasSize quản lý.
        local pageLayout = create("UIListLayout", {
            Padding = UDim.new(0, 6),
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
        })
        local page = create("ScrollingFrame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.None,
            ScrollBarThickness = 2,
            ScrollBarImageColor3 = window.ThemeCol,
            Visible = false,
            Parent = pageContainer,
            pageLayout,
            create("UIPadding", {
                PaddingTop = UDim.new(0, 8),
                PaddingBottom = UDim.new(0, 8),
            }),
        })
        local pageRefresh = bindCanvasSize(tabMaid, page, pageLayout, 16) -- [FIX v10] +16 = padding top + bottom
        tabMaid:Add(tabButton)
        tabMaid:Add(page)

        local function selectTab()
            if window.destroyed then return end
            if window.CurrentTab then
                window.CurrentTab.Button.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
                window.CurrentTab.Button.TextColor3 = Color3.fromRGB(200, 200, 200)
                window.CurrentTab.Page.Visible = false
            end
            window.CurrentTab = { Button = tabButton, Page = page }
            tabButton.BackgroundColor3 = window.ThemeCol
            tabButton.TextColor3 = Color3.fromRGB(0, 0, 0)
            page.Visible = true
            -- [FIX v10] Recalc 1 lần khi tab hiện ra: page ẩn lúc build nên
            -- AbsoluteContentSize có thể chưa cập nhật → scroll vẫn đúng.
            if pageRefresh then pageRefresh() end
        end
        tabMaid:Add(tabButton.MouseButton1Click:Connect(selectTab))
        _table.insert(window.Tabs, tab)
        if not window.CurrentTab then selectTab() end

        function tab:Label(text)
            local section = create("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, -16, 0, 28),
                Parent = page,
            })
            local label = create("TextLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 1, -4),
                Text = string.upper(tostring(text or "")),
                TextColor3 = window.ThemeCol,
                Font = Enum.Font.GothamBold,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = section,
            })
            create("Frame", {
                BackgroundColor3 = window.ThemeCol,
                Size = UDim2.new(1, 0, 0, 1),
                Position = UDim2.new(0, 0, 1, -2),
                BorderSizePixel = 0,
                Parent = section,
            })
            tabMaid:Add(section)
            return { Set = function(_, newText)
                if label.Parent then label.Text = string.upper(tostring(newText or "")) end
            end }
        end

        function tab:Button(text, callback)
            local button = create("TextButton", {
                BackgroundColor3 = Color3.fromRGB(30, 30, 30),
                Size = UDim2.new(1, -16, 0, 35),
                Text = tostring(text or "Button"),
                TextColor3 = Color3.fromRGB(220, 220, 220),
                Font = Enum.Font.Gotham,
                TextSize = 14,
                AutoButtonColor = false,
                Parent = page,
                create("UICorner", { CornerRadius = UDim.new(0, 4) }),
                create("UIStroke", { Color = Color3.fromRGB(50, 50, 50), Thickness = 1 }),
            })
            tabMaid:Add(button)
            tabMaid:Add(button.MouseButton1Click:Connect(function()
                if tab.destroyed then return end
                addTween(tabMaid, button, TweenInfo.new(0.1), { BackgroundColor3 = window.ThemeCol })
                local delayThread
                delayThread = _task.delay(0.1, function()
                    if button.Parent then
                        addTween(tabMaid, button, TweenInfo.new(0.1), { BackgroundColor3 = Color3.fromRGB(30, 30, 30) })
                    end
                    if delayThread then tabMaid:Remove(delayThread) end
                end)
                tabMaid:Add(delayThread)
                safeCallback(callback)
            end))
            return button
        end

        function tab:Toggle(text, default, callback, fallback)
            local controlMaid = newMaid()
            tabMaid:Add(controlMaid)
            -- Truyền trực tiếp `luu["key"]`; nil mới dùng fallback, còn false được giữ nguyên.
            local state = normalizeBoolean(default, fallback == nil and true or fallback)
            local destroyed = false

            local toggle = create("TextButton", {
                BackgroundColor3 = Color3.fromRGB(30, 30, 30),
                Size = UDim2.new(1, -16, 0, 35),
                Text = "",
                AutoButtonColor = false,
                Parent = page,
                create("UICorner", { CornerRadius = UDim.new(0, 4) }),
                create("UIStroke", { Color = Color3.fromRGB(50, 50, 50), Thickness = 1 }),
                create("TextLabel", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, -50, 1, 0),
                    Position = UDim2.new(0, 10, 0, 0),
                    Text = tostring(text or "Toggle"),
                    TextColor3 = Color3.fromRGB(220, 220, 220),
                    Font = Enum.Font.Gotham,
                    TextSize = 14,
                    TextXAlignment = Enum.TextXAlignment.Left,
                }),
            })
            local check = create("Frame", {
                BackgroundColor3 = state and window.ThemeCol or Color3.fromRGB(50, 50, 50),
                Size = UDim2.new(0, 20, 0, 20),
                Position = UDim2.new(1, -30, 0.5, -10),
                Parent = toggle,
                create("UICorner", { CornerRadius = UDim.new(0, 4) }),
            })
            controlMaid:Add(toggle)

            local function setState(value, emit)
                if destroyed then return end
                local nextState = value == true
                local changed = state ~= nextState
                state = nextState
                check.BackgroundColor3 = state and window.ThemeCol or Color3.fromRGB(50, 50, 50)
                if changed and emit then safeCallback(callback, state) end
            end

            local function destroyControl()
                if destroyed then return end
                destroyed = true
                controlMaid:Cleanup()
            end
            -- Đánh dấu destroyed trước khi Maid dọn các resource còn lại.
            controlMaid:Add(function() destroyed = true end)
            controlMaid:Add(toggle.MouseButton1Click:Connect(function()
                if destroyed then return end
                setState(not state, true)
            end))
            local api = {
                Set = function(_, value) setState(value, true) end,
                Get = function()
                    if destroyed then return nil end
                    return state
                end,
                Destroy = destroyControl,
                IsDestroyed = function() return destroyed end,
            }
            _table.insert(tab.Elements, api)
            return api
        end

        function tab:Dropdown(text, options, default, callback)
            options = type(options) == "table" and options or {}
            local selected = default
            local open = false
            local controlMaid = newMaid()
            tabMaid:Add(controlMaid)
            local function contains(value)
                for _, option in ipairs(options) do
                    if option == value then return true end
                end
                return false
            end
            if not contains(selected) then selected = options[1] or "Chưa chọn" end
            local dropdown = create("Frame", {
                BackgroundColor3 = Color3.fromRGB(30, 30, 30),
                Size = UDim2.new(1, -16, 0, 35),
                Parent = page,
                ClipsDescendants = true,
                create("UICorner", { CornerRadius = UDim.new(0, 4) }),
                create("UIStroke", { Color = Color3.fromRGB(50, 50, 50), Thickness = 1 }),
            })
            local dropdownButton = create("TextButton", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 35),
                Text = "",
                Parent = dropdown,
                create("TextLabel", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(0.5, 0, 1, 0),
                    Position = UDim2.new(0, 10, 0, 0),
                    Text = tostring(text or "Dropdown"),
                    TextColor3 = Color3.fromRGB(220, 220, 220),
                    Font = Enum.Font.Gotham,
                    TextSize = 14,
                    TextXAlignment = Enum.TextXAlignment.Left,
                }),
            })
            local valueLabel = create("TextLabel", {
                Name = "Val",
                BackgroundTransparency = 1,
                Size = UDim2.new(0.5, -15, 1, 0),
                Position = UDim2.new(0.5, 0, 0, 0),
                Text = tostring(selected),
                TextColor3 = window.ThemeCol,
                Font = Enum.Font.GothamBold,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Right,
                TextTruncate = Enum.TextTruncate.AtEnd,
                Parent = dropdownButton,
            })
            -- [FIX v10] list cũng bỏ AutomaticCanvasSize
            local listLayout = create("UIListLayout", { Padding = UDim.new(0, 2) })
            local list = create("ScrollingFrame", {
                BackgroundColor3 = Color3.fromRGB(20, 20, 20),
                Size = UDim2.new(1, -10, 0, 100),
                Position = UDim2.new(0, 5, 0, 40),
                CanvasSize = UDim2.new(0, 0, 0, 0),
                AutomaticCanvasSize = Enum.AutomaticSize.None,
                ScrollBarThickness = 2,
                Parent = dropdown,
                listLayout,
                create("UICorner", { CornerRadius = UDim.new(0, 4) }),
            })
            bindCanvasSize(controlMaid, list, listLayout, 0) -- [FIX v10]
            controlMaid:Add(dropdown)

            -- [FIX v9] Cache item button: build 1 lần (lần mở đầu tiên),
            -- render() chỉ đổi BackgroundColor3/TextColor3 thay vì destroy + create lại.
            local itemButtons = {}   -- index -> TextButton
            local itemsBuilt = false
            local itemMaid = newMaid()
            controlMaid:Add(function() itemMaid:Cleanup() end)

            local choose
            local render

            local function buildItems()
                if itemsBuilt then return end
                itemsBuilt = true
                for index = 1, #options do
                    local option = options[index]
                    local item = create("TextButton", {
                        BackgroundColor3 = Color3.fromRGB(25, 25, 25),
                        Size = UDim2.new(1, 0, 0, 25),
                        Text = tostring(option),
                        TextColor3 = Color3.fromRGB(200, 200, 200),
                        Font = Enum.Font.Gotham,
                        TextSize = 13,
                        AutoButtonColor = false,
                        Parent = list,
                        create("UICorner", { CornerRadius = UDim.new(0, 2) }),
                    })
                    itemMaid:Add(item)
                    -- Connection chỉ tạo 1 lần, closure đọc `option` từ cache.
                    itemMaid:Add(item.MouseButton1Click:Connect(function() choose(option) end))
                    itemButtons[index] = item
                end
            end

            choose = function(option)
                selected, open = option, false
                dropdown.Size = UDim2.new(1, -16, 0, 35)
                valueLabel.Text = tostring(selected)
                render()
                safeCallback(callback, selected)
            end

            render = function()
                if not itemsBuilt then return end
                for index = 1, #options do
                    local button = itemButtons[index]
                    if button and button.Parent then
                        local isSelected = selected == options[index]
                        button.BackgroundColor3 = isSelected and window.ThemeCol or Color3.fromRGB(25, 25, 25)
                        button.TextColor3 = isSelected and Color3.fromRGB(0, 0, 0) or Color3.fromRGB(200, 200, 200)
                    end
                end
            end

            controlMaid:Add(dropdownButton.MouseButton1Click:Connect(function()
                open = not open
                if open then
                    buildItems() -- [FIX v9] build 1 lần duy nhất
                    render()
                end
                dropdown.Size = UDim2.new(1, -16, 0, open and 145 or 35)
            end))
            render()
            return {
                Set = function(_, option) if contains(option) then choose(option) end end,
                Get = function() return selected end,
                Destroy = function() controlMaid:Cleanup() end,
            }
        end

        function tab:Slider(text, minimum, maximum, default, callback)
            minimum = tonumber(minimum) or 0
            maximum = tonumber(maximum) or 100
            if maximum < minimum then minimum, maximum = maximum, minimum end
            if maximum == minimum then maximum = minimum + 1 end
            local value = _math.floor(clamp(default, minimum, maximum))
            local controlMaid = newMaid()
            tabMaid:Add(controlMaid)
            local slider = create("Frame", {
                BackgroundColor3 = Color3.fromRGB(30, 30, 30),
                Size = UDim2.new(1, -16, 0, 50),
                Parent = page,
                create("UICorner", { CornerRadius = UDim.new(0, 4) }),
                create("UIStroke", { Color = Color3.fromRGB(50, 50, 50), Thickness = 1 }),
                create("TextLabel", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, -60, 0, 25),
                    Position = UDim2.new(0, 10, 0, 0),
                    Text = tostring(text or "Slider"),
                    TextColor3 = Color3.fromRGB(220, 220, 220),
                    Font = Enum.Font.Gotham,
                    TextSize = 14,
                    TextXAlignment = Enum.TextXAlignment.Left,
                }),
            })
            local box = create("TextBox", {
                BackgroundColor3 = Color3.fromRGB(15, 15, 15),
                Size = UDim2.new(0, 40, 0, 20),
                Position = UDim2.new(1, -50, 0, 2),
                Text = tostring(value),
                TextColor3 = window.ThemeCol,
                Font = Enum.Font.GothamBold,
                TextSize = 13,
                Parent = slider,
                create("UICorner", { CornerRadius = UDim.new(0, 4) }),
            })
            local track = create("Frame", {
                BackgroundColor3 = Color3.fromRGB(15, 15, 15),
                Size = UDim2.new(1, -20, 0, 8),
                Position = UDim2.new(0, 10, 0, 32),
                Parent = slider,
                create("UICorner", { CornerRadius = UDim.new(1, 0) }),
            })
            local fill = create("Frame", {
                BackgroundColor3 = window.ThemeCol,
                Size = UDim2.new((value - minimum) / (maximum - minimum), 0, 1, 0),
                Parent = track,
                create("UICorner", { CornerRadius = UDim.new(1, 0) }),
            })
            controlMaid:Add(slider)
            local lastCallback = 0
            local function setValue(newValue, invokeCallback, forceCallback)
                local previousValue = value
                value = _math.floor(clamp(newValue, minimum, maximum))
                local percent = (value - minimum) / (maximum - minimum)
                fill.Size = UDim2.new(percent, 0, 1, 0)
                box.Text = tostring(value)

                local now = os.clock()
                if invokeCallback and value ~= previousValue
                    and (forceCallback or now - lastCallback >= 0.1) then
                    lastCallback = now
                    safeCallback(callback, value)
                end
            end
            local function updateFromInput(input)
                if track.AbsoluteSize.X <= 0 then return end
                local percent = clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
                setValue(minimum + (maximum - minimum) * percent, true)
            end
            -- [FIX v7] Không còn 2 connection global / slider.
            -- Mọi slider dùng chung đúng 2 connection UserInputService (ensureSliderShared).
            local sliderState = {
                isSliding = false,
                update = updateFromInput,
                stop = function()
                    sliderState.isSliding = false
                    safeCallback(callback, value)
                end,
            }
            ensureSliderShared()
            controlMaid:Add(track.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1
                    or input.UserInputType == Enum.UserInputType.Touch then
                    sliderState.isSliding = true
                    _sliderActive = sliderState -- [FIX v7] đăng ký slider đang drag
                    updateFromInput(input)
                end
            end))
            -- [FIX v7] Dọn con trỏ shared nếu slider bị destroy ngay giữa lúc drag.
            controlMaid:Add(function()
                if _sliderActive == sliderState then _sliderActive = nil end
                sliderState.isSliding = false
            end)
            controlMaid:Add(box.FocusLost:Connect(function()
                local number = tonumber(box.Text)
                if number then setValue(number, true, true) else box.Text = tostring(value) end
            end))
            return {
                Set = function(_, newValue) setValue(newValue, true, true) end,
                Get = function() return value end,
                Destroy = function() controlMaid:Cleanup() end,
            }
        end
        return tab
    end

    function window:Destroy()
        if self.destroyed then return end
        self.destroyed = true
        -- [FIX v15] Ngắt mọi job TCH:Loop được tạo trong lúc window còn sống
        -- → destroy window là không còn connection/job sống.
        local handles = self.loopHandles
        self.loopHandles = {}
        for index = #handles, 1, -1 do
            local handle = handles[index]
            handles[index] = nil
            if type(handle) == "table" and type(handle.Disconnect) == "function" then
                pcall(function() handle:Disconnect() end)
            end
        end
        if activeWindow == self then
            activeWindow = nil
            activeGui = nil
        end
        self.maid:Cleanup()
    end

    activeWindow = window
    activeGui = gui
    return window
end

function TCH:Notify(title, description, duration)
    if activeWindow and not activeWindow.destroyed then
        activeWindow:Notify(title, description, duration)
    end
end

function TCH:Window(config)
    if activeWindow and not activeWindow.destroyed then
        activeWindow:Destroy()
    end
    local oldGui = TargetParent:FindFirstChild("TCHub")
    if oldGui then oldGui:Destroy() end
    local oldNoti = TargetParent:FindFirstChild("TCHub_Noti")
    if oldNoti then oldNoti:Destroy() end

    local ok, result = xpcall(function()
        return createWindow(self, config)
    end, function(err)
        return tostring(err)
    end)
    if ok then return result end

    warn("Tea GUI load failed: " .. tostring(result))
    local stub = {}
    local noop = function() return stub end
    setmetatable(stub, { __index = function() return noop end })
    stub.Error = result
    return stub
end

-- [FIX v14] Helper set property an toàn: bỏ qua khi instance không còn sống.
-- Khuyến nghị dùng khi update UI trong callback để tránh crash khi tab bị destroy.
function TCH.SafeSet(instance, property, value)
    if typeof(instance) ~= "Instance" then return false end
    if instance.Parent == nil then return false end
    return (pcall(function()
        instance[property] = value
    end))
end

return TCH
