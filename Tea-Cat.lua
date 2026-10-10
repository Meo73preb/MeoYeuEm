-- Tea Cat GUI Library - Beta v1.0
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

local function clamp(value, minimum, maximum)
    value = tonumber(value) or minimum
    return _math.max(minimum, _math.min(maximum, value))
end

local function getTargetParent()
    local ok = pcall(function()
        return CoreGui.Name
    end)
    if ok then
        return CoreGui
    end
    return Players.LocalPlayer:WaitForChild("PlayerGui")
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

    function maid:_cleanupOne(resource)
        local resourceType = type(resource)
        if resourceType == "function" then
            pcall(resource)
        elseif resourceType == "thread" then
            pcall(_task.cancel, resource)
        elseif resourceType == "table" and type(resource.Destroy) == "function" then
            pcall(function() resource:Destroy() end)
        elseif resourceType == "userdata" then
            pcall(function()
                if resource.Disconnect then
                    resource:Disconnect()
                elseif resource.Destroy then
                    resource:Destroy()
                end
            end)
        end
    end

    function maid:Cleanup()
        if self.destroyed then return end
        self.destroyed = true
        for index = #self.tasks, 1, -1 do
            self:_cleanupOne(self.tasks[index])
            self.tasks[index] = nil
        end
    end

    return maid
end

local function create(className, properties)
    local instance = Instance.new(className)
    for key, value in pairs(properties or {}) do
        if type(key) == "number" then
            if typeof(value) == "Instance" then
                value.Parent = instance
            end
        else
            instance[key] = value
        end
    end
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
    }

    local function backend(name)
        local value = rawget(_G, name)
        return type(value) == "function" and value or nil
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
        local writefile, isfolder, makefolder = backend("writefile"), backend("isfolder"), backend("makefolder")
        if not writefile or not isfolder or not makefolder then return false, "filesystem API unavailable" end
        local folder = self.path:match("^(.*)/[^/]+$")
        if folder and folder ~= "" then
            local current = ""
            for part in folder:gmatch("[^/]+") do
                current = current == "" and part or current .. "/" .. part
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
        self._saveThread = _task.delay(tonumber(delaySeconds) or 0.25, function()
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

local loopManagers = {}
function TCH:Loop(signalName)
    signalName = signalName == "RenderStepped" and "RenderStepped" or "Heartbeat"
    local manager = loopManagers[signalName]
    if not manager then
        manager = { jobs = {}, nextId = 0, connection = nil }
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
        local id, elapsed, active = manager.nextId, 0, true
        manager.jobs[id] = function(dt)
            if not active then return end
            elapsed = elapsed + (tonumber(dt) or 0)
            if interval and interval > 0 and elapsed < interval then return end
            elapsed = 0
            safeCallback(callback, dt)
        end
        if not manager.connection then
            manager.connection = signal:Connect(function(dt)
                for _, job in pairs(manager.jobs) do job(dt) end
            end)
        end
        return {
            Disconnect = function()
                if not active then return end
                active = false
                manager.jobs[id] = nil
                if next(manager.jobs) == nil and manager.connection then
                    manager.connection:Disconnect()
                    manager.connection = nil
                end
            end,
            Destroy = function(self) self:Disconnect() end,
        }
    end
    return api
end

local function makeDraggable(maid, dragObject, moveObject)
    local dragging = false
    local dragInput
    local startInputPosition
    local startGuiPosition

    maid:Add(dragObject.InputBegan:Connect(function(input)
        local inputType = input.UserInputType
        if inputType ~= Enum.UserInputType.MouseButton1
            and inputType ~= Enum.UserInputType.Touch then
            return
        end
        dragging = true
        startInputPosition = input.Position
        startGuiPosition = moveObject.Position
        maid:Add(input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end))
    end))

    maid:Add(dragObject.InputChanged:Connect(function(input)
        local inputType = input.UserInputType
        if inputType == Enum.UserInputType.MouseMovement
            or inputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end))

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

local function addTween(maid, instance, info, properties)
    local tween = TweenService:Create(instance, info, properties)
    tween:Play()
    return tween
end

local function buildNotification(window, title, description, duration)
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
    local delayThread = _task.delay(_math.max(0, tonumber(duration) or 3), function()
        if notification.Parent then notification:Destroy() end
    end)
    window.maid:Add(delayThread)
end

local function createWindow(library, config)
    config = config or {}
    local windowMaid = newMaid()
    local window = {
        Title = tostring(config.Title or "Tea Cat Hub"),
        ThemeCol = config.Color or Color3.fromRGB(0, 255, 128),
        Tabs = {},
        CurrentTab = nil,
        maid = windowMaid,
        destroyed = false,
        notificationContainer = nil,
    }
    library.ThemeCol = window.ThemeCol

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

    local tabContainer = create("ScrollingFrame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 120, 1, -36),
        Position = UDim2.new(0, 0, 0, 36),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 0,
        Parent = main,
        create("UIListLayout", { Padding = UDim.new(0, 2) }),
        create("UIPadding", {
            PaddingTop = UDim.new(0, 5),
            PaddingLeft = UDim.new(0, 5),
            PaddingRight = UDim.new(0, 5),
        }),
    })
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
        local page = create("ScrollingFrame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ScrollBarThickness = 2,
            ScrollBarImageColor3 = window.ThemeCol,
            Visible = false,
            Parent = pageContainer,
            create("UIListLayout", {
                Padding = UDim.new(0, 6),
                HorizontalAlignment = Enum.HorizontalAlignment.Center,
            }),
            create("UIPadding", {
                PaddingTop = UDim.new(0, 8),
                PaddingBottom = UDim.new(0, 8),
            }),
        })
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
                local delayThread = _task.delay(0.1, function()
                    if button.Parent then
                        addTween(tabMaid, button, TweenInfo.new(0.1), { BackgroundColor3 = Color3.fromRGB(30, 30, 30) })
                    end
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
                Get = function() return destroyed and nil or state end,
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
            local list = create("ScrollingFrame", {
                BackgroundColor3 = Color3.fromRGB(20, 20, 20),
                Size = UDim2.new(1, -10, 0, 100),
                Position = UDim2.new(0, 5, 0, 40),
                CanvasSize = UDim2.new(0, 0, 0, 0),
                AutomaticCanvasSize = Enum.AutomaticSize.Y,
                ScrollBarThickness = 2,
                Parent = dropdown,
                create("UIListLayout", { Padding = UDim.new(0, 2) }),
                create("UICorner", { CornerRadius = UDim.new(0, 4) }),
            })
            controlMaid:Add(dropdown)
            local render
            local itemMaid = newMaid()
            controlMaid:Add(function() itemMaid:Cleanup() end)
            local function choose(option)
                selected, open = option, false
                dropdown.Size = UDim2.new(1, -16, 0, 35)
                valueLabel.Text = tostring(selected)
                render()
                safeCallback(callback, selected)
            end
            render = function()
                itemMaid:Cleanup()
                itemMaid = newMaid()
                for _, child in ipairs(list:GetChildren()) do
                    if child:IsA("TextButton") then child:Destroy() end
                end
                for _, option in ipairs(options) do
                    local isSelected = selected == option
                    local item = create("TextButton", {
                        BackgroundColor3 = isSelected and window.ThemeCol or Color3.fromRGB(25, 25, 25),
                        Size = UDim2.new(1, 0, 0, 25),
                        Text = tostring(option),
                        TextColor3 = isSelected and Color3.fromRGB(0, 0, 0) or Color3.fromRGB(200, 200, 200),
                        Font = Enum.Font.Gotham,
                        TextSize = 13,
                        AutoButtonColor = false,
                        Parent = list,
                        create("UICorner", { CornerRadius = UDim.new(0, 2) }),
                    })
                    itemMaid:Add(item)
                    itemMaid:Add(item.MouseButton1Click:Connect(function() choose(option) end))
                end
            end
            controlMaid:Add(dropdownButton.MouseButton1Click:Connect(function()
                open = not open
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
            local function setValue(newValue, invokeCallback)
                value = _math.floor(clamp(newValue, minimum, maximum))
                local percent = (value - minimum) / (maximum - minimum)
                fill.Size = UDim2.new(percent, 0, 1, 0)
                box.Text = tostring(value)

                if invokeCallback and os.clock() - lastCallback >= 0.1 then
                    lastCallback = os.clock()
                    safeCallback(callback, value)
                end
            end
            local function updateFromInput(input)
                if track.AbsoluteSize.X <= 0 then return end
                local percent = clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
                setValue(minimum + (maximum - minimum) * percent, true)
            end
            local sliding = false
            controlMaid:Add(track.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1
                    or input.UserInputType == Enum.UserInputType.Touch then
                    sliding = true
                    updateFromInput(input)
                end
            end))
            controlMaid:Add(UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1
                    or input.UserInputType == Enum.UserInputType.Touch then
                    if sliding then
                        sliding = false
                        safeCallback(callback, value)
                    end
                end
            end))
            controlMaid:Add(UserInputService.InputChanged:Connect(function(input)
                if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement
                    or input.UserInputType == Enum.UserInputType.Touch) then
                    updateFromInput(input)
                end
            end))
            controlMaid:Add(box.FocusLost:Connect(function()
                local number = tonumber(box.Text)
                if number then setValue(number, true) else box.Text = tostring(value) end
            end))
            return {
                Set = function(_, newValue) setValue(newValue, true) end,
                Get = function() return value end,
                Destroy = function() controlMaid:Cleanup() end,
            }
        end
        return tab
    end

    function window:Destroy()
        if self.destroyed then return end
        self.destroyed = true
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

return TCH
