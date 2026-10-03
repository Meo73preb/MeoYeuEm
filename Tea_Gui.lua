-- Tea Cat GUI Library - Beta v1.0
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")

local TCH = {}

local Registry = {
    nextId = 998,
    entries = {},
}

function Registry:Create(kind, handlers)
    self.nextId = self.nextId + 1
    local id = string.format("%s:%x", tostring(kind or "control"), self.nextId)
    self.entries[id] = {
        kind = kind,
        handlers = handlers or {},
    }
    return id
end

function Registry:Invoke(id, action, ...)
    local entry = self.entries[id]
    if not entry then return nil end
    local handler = entry.handlers[action]
    if type(handler) ~= "function" then return nil end
    return handler(...)
end

function Registry:Remove(id)
    self.entries[id] = nil
end

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
    maid:Add(function()
        pcall(function() tween:Cancel() end)
    end)
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

        function tab:Toggle(text, default, callback, interval)
            local controlMaid = newMaid()
            tabMaid:Add(controlMaid)
            local state = default == true
            local worker
            local destroyed = false
            local running = false
            local tickInterval = _math.max(0.05, tonumber(interval) or 0.15)

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

            local function stop()
                running = false
                if worker then
                    pcall(_task.cancel, worker)
                    worker = nil
                end
            end

            local function start()
                stop()
                if not state or destroyed or type(callback) ~= "function" then return end
                running = true
                worker = _task.spawn(function()
                    while running and state and not destroyed and toggle.Parent do
                        safeCallback(callback, state)
                        _task.wait(tickInterval)
                    end
                end)
                controlMaid:Add(worker)
            end

            local function setState(value, emit)
                if destroyed then return end
                local nextState = value == true
                local changed = state ~= nextState
                state = nextState
                check.BackgroundColor3 = state and window.ThemeCol or Color3.fromRGB(50, 50, 50)
                if changed and emit then safeCallback(callback, state) end
                if state then start() else stop() end
            end

            local id
            id = Registry:Create("toggle", {
                set = function(value) setState(value, true) end,
                get = function() return state end,
                stop = stop,
                destroy = function()
                    if destroyed then return end
                    destroyed = true
                    stop()
                    controlMaid:Cleanup()
                    Registry:Remove(id)
                end,
            })
            controlMaid:Add(function()
                if Registry.entries[id] then Registry:Invoke(id, "destroy") end
            end)
            controlMaid:Add(toggle.MouseButton1Click:Connect(function()
                Registry:Invoke(id, "set", not Registry:Invoke(id, "get"))
            end))
            if state then Registry:Invoke(id, "set", true) end

            local api = {
                Set = function(_, value) Registry:Invoke(id, "set", value) end,
                Get = function() return Registry:Invoke(id, "get") end,
                Stop = function() Registry:Invoke(id, "stop") end,
                Destroy = function() Registry:Invoke(id, "destroy") end,
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
                    sliding = false
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
        warn("Tea GUI: window đã tồn tại")
        return nil
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
    return {
        Destroy = function() end,
        Label = nil,
        Error = result,
    }
end

return TCH
