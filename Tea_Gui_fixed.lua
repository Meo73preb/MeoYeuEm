-- Tea GUI Library
-- Cleaned and repaired version.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")

local function clamp(value, minimum, maximum)
    return math.max(minimum, math.min(maximum, value))
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

-- Lifecycle được lưu theo target parent để các lần load lại cùng dùng chung trạng thái.
local Lifecycle = {
    Status = "idle", -- idle, loading, active, failed
    Window = nil,
    Gui = nil,
}

local TCH = {}

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
    if type(callback) ~= "function" then
        return
    end

    local ok, err = pcall(callback, ...)
    if not ok then
        warn("Tea GUI callback error: " .. tostring(err))
    end
end

local function makeDraggable(dragObject, moveObject)
    local dragging = false
    local dragInput
    local startInputPosition
    local startGuiPosition

    dragObject.InputBegan:Connect(function(input)
        local inputType = input.UserInputType
        if inputType ~= Enum.UserInputType.MouseButton1
            and inputType ~= Enum.UserInputType.Touch then
            return
        end

        dragging = true
        startInputPosition = input.Position
        startGuiPosition = moveObject.Position

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end)

    dragObject.InputChanged:Connect(function(input)
        local inputType = input.UserInputType
        if inputType == Enum.UserInputType.MouseMovement
            or inputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if not dragging or input ~= dragInput then
            return
        end

        local delta = input.Position - startInputPosition
        moveObject.Position = UDim2.new(
            startGuiPosition.X.Scale,
            startGuiPosition.X.Offset + delta.X,
            startGuiPosition.Y.Scale,
            startGuiPosition.Y.Offset + delta.Y
        )
    end)
end

local NotificationGui
local NotificationContainer

local function getNotificationContainer()
    if NotificationContainer and NotificationContainer.Parent then
        return NotificationContainer
    end

    NotificationGui = create("ScreenGui", {
        Name = "TCHub_Noti",
        ResetOnSpawn = false,
        Parent = TargetParent,
    })
    NotificationContainer = create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 300, 1, -40),
        Position = UDim2.new(1, -15, 0, 20),
        AnchorPoint = Vector2.new(1, 0),
        Parent = NotificationGui,
        create("UIListLayout", {
            Padding = UDim.new(0, 10),
            VerticalAlignment = Enum.VerticalAlignment.Bottom,
            HorizontalAlignment = Enum.HorizontalAlignment.Right,
        }),
    })
    return NotificationContainer
end

function TCH:Notify(title, description, duration)
    local notificationContainer = getNotificationContainer()
    local theme = self.ThemeCol or Color3.fromRGB(0, 255, 128)
    local notification = create("Frame", {
        BackgroundColor3 = Color3.fromRGB(20, 20, 20),
        Size = UDim2.new(1, 0, 0, 60),
        Parent = notificationContainer,
        create("UICorner", { CornerRadius = UDim.new(0, 4) }),
        create("UIStroke", { Color = theme, Thickness = 1 }),
        create("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 10, 0, 5),
            Size = UDim2.new(1, -20, 0, 20),
            Text = tostring(title or "Thông báo"),
            TextColor3 = theme,
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

    task.delay(tonumber(duration) or 3, function()
        if notification and notification.Parent then
            notification:Destroy()
        end
    end)
end

local function createWindow(library, config)
    config = config or {}

    local window = {
        Title = tostring(config.Title or "Tea Cat Hub"),
        ThemeCol = config.Color or Color3.fromRGB(0, 255, 128),
        Tabs = {},
        CurrentTab = nil,
    }

    library.ThemeCol = window.ThemeCol

    local gui = create("ScreenGui", {
        Name = "TCHub",
        Parent = TargetParent,
        ResetOnSpawn = false,
    })

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

    makeDraggable(floatButton, floatButton)
    floatButton.MouseButton1Click:Connect(function()
        main.Visible = not main.Visible
    end)

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

    makeDraggable(top, main)

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

    function window:Tab(name)
        local tab = { Elements = {} }
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

        local function selectTab()
            if window.CurrentTab then
                window.CurrentTab.Button.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
                window.CurrentTab.Button.TextColor3 = Color3.fromRGB(200, 200, 200)
                window.CurrentTab.Page.Visible = false
            end

            window.CurrentTab = {
                Button = tabButton,
                Page = page,
            }
            tabButton.BackgroundColor3 = window.ThemeCol
            tabButton.TextColor3 = Color3.fromRGB(0, 0, 0)
            page.Visible = true
        end

        tabButton.MouseButton1Click:Connect(selectTab)
        table.insert(window.Tabs, tab)

        if not window.CurrentTab then
            selectTab()
        end

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

            return {
                Set = function(_, newText)
                    label.Text = string.upper(tostring(newText or ""))
                end,
            }
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

            button.MouseButton1Click:Connect(function()
                TweenService:Create(button, TweenInfo.new(0.1), {
                    BackgroundColor3 = window.ThemeCol,
                }):Play()
                task.delay(0.1, function()
                    if button and button.Parent then
                        TweenService:Create(button, TweenInfo.new(0.1), {
                            BackgroundColor3 = Color3.fromRGB(30, 30, 30),
                        }):Play()
                    end
                end)
                safeCallback(callback)
            end)

            return button
        end

        function tab:Toggle(text, default, callback)
            local state = default == true
            local loopThread
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

            local function stopLoop()
                if loopThread then
                    task.cancel(loopThread)
                    loopThread = nil
                end
            end

            local function updateState(newState)
                state = newState == true
                check.BackgroundColor3 = state and window.ThemeCol or Color3.fromRGB(50, 50, 50)
                stopLoop()
                if state and type(callback) == "function" then
                    loopThread = task.spawn(function()
                        while state and toggle.Parent do
                            safeCallback(callback)
                            task.wait()
                        end
                    end)
                end
            end

            toggle.MouseButton1Click:Connect(function()
                updateState(not state)
            end)

            if state then
                updateState(true)
            end

            return {
                Set = function(_, value) updateState(value) end,
                Get = function() return state end,
            }
        end

        function tab:Dropdown(text, options, default, callback)
            options = type(options) == "table" and options or {}
            local selected = default
            local open = false

            local function contains(value)
                for _, option in ipairs(options) do
                    if option == value then return true end
                end
                return false
            end

            if not contains(selected) then
                selected = options[1] or "Chưa chọn"
            end

            local dropdown = create("Frame", {
                BackgroundColor3 = Color3.fromRGB(30, 30, 30),
                Size = UDim2.new(1, -16, 0, 35),
                Parent = page,
                ClipsDescendants = true,
                create("UICorner", { CornerRadius = UDim.new(0, 4) }),
                create("UIStroke", { Color = Color3.fromRGB(50, 50, 50), Thickness = 1 }),
            })
            local valueLabel
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
            valueLabel = create("TextLabel", {
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

            local render
            local function choose(option)
                selected = option
                open = false
                dropdown.Size = UDim2.new(1, -16, 0, 35)
                valueLabel.Text = tostring(selected)
                render()
                safeCallback(callback, selected)
            end

            render = function()
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
                    item.MouseButton1Click:Connect(function() choose(option) end)
                end
            end

            dropdownButton.MouseButton1Click:Connect(function()
                open = not open
                dropdown.Size = UDim2.new(1, -16, 0, open and 145 or 35)
            end)
            render()

            return {
                Set = function(_, newOption)
                    if contains(newOption) then choose(newOption) end
                end,
                Get = function() return selected end,
            }
        end

        function tab:Slider(text, minimum, maximum, default, callback)
            minimum = tonumber(minimum) or 0
            maximum = tonumber(maximum) or 100
            if maximum < minimum then minimum, maximum = maximum, minimum end
            if maximum == minimum then maximum = minimum + 1 end

            local value = clamp(tonumber(default) or minimum, minimum, maximum)
            value = math.floor(value)
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

            local function setValue(newValue, invokeCallback)
                value = math.floor(clamp(tonumber(newValue) or value, minimum, maximum))
                local percent = (value - minimum) / (maximum - minimum)
                fill.Size = UDim2.new(percent, 0, 1, 0)
                box.Text = tostring(value)
                if invokeCallback then safeCallback(callback, value) end
            end

            local function updateFromInput(input)
                if track.AbsoluteSize.X <= 0 then return end
                local percent = clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
                setValue(minimum + (maximum - minimum) * percent, true)
            end

            local sliding = false
            track.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1
                    or input.UserInputType == Enum.UserInputType.Touch then
                    sliding = true
                    updateFromInput(input)
                end
            end)
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1
                    or input.UserInputType == Enum.UserInputType.Touch then
                    sliding = false
                end
            end)
            UserInputService.InputChanged:Connect(function(input)
                if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement
                    or input.UserInputType == Enum.UserInputType.Touch) then
                    updateFromInput(input)
                end
            end)
            box.FocusLost:Connect(function()
                local number = tonumber(box.Text)
                if number then setValue(number, true) else box.Text = tostring(value) end
            end)

            return {
                Set = function(_, newValue) setValue(newValue, true) end,
                Get = function() return value end,
            }
        end

        return tab
    end

    function window:Destroy()
        if Lifecycle.Window ~= window then
            return
        end

        if gui and gui.Parent then
            gui:Destroy()
        end
        if NotificationGui and NotificationGui.Parent then
            NotificationGui:Destroy()
        end

        NotificationGui = nil
        NotificationContainer = nil
        Lifecycle.Window = nil
        Lifecycle.Gui = nil
        Lifecycle.Status = "idle"
    end

    Lifecycle.Window = window
    Lifecycle.Gui = gui
    Lifecycle.Status = "active"
    return window
end

local function createFailureWindow(errorMessage)
    Lifecycle.Status = "failed"

    local failureGui = create("ScreenGui", {
        Name = "TCHub_Failure",
        ResetOnSpawn = false,
        Parent = TargetParent,
    })
    local failureLabel = create("TextLabel", {
        BackgroundColor3 = Color3.fromRGB(25, 25, 25),
        Size = UDim2.new(0, 420, 0, 60),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Text = "Vui lòng tạo lại vì Gui gặp sự cố!",
        TextColor3 = Color3.fromRGB(255, 180, 80),
        Font = Enum.Font.GothamBold,
        TextSize = 16,
        TextWrapped = true,
        Parent = failureGui,
        create("UICorner", { CornerRadius = UDim.new(0, 6) }),
        create("UIStroke", { Color = Color3.fromRGB(255, 180, 80), Thickness = 1 }),
    })

    warn("Tea GUI load failed: " .. tostring(errorMessage))

    return {
        Destroy = function()
            if failureGui and failureGui.Parent then
                failureGui:Destroy()
            end
            Lifecycle.Status = "idle"
        end,
        Label = failureLabel,
    }
end

function TCH:Window(config)
    if Lifecycle.Status == "loading" then
        warn("dupe Gui?")
        return nil
    end

    if Lifecycle.Status == "active" or TargetParent:FindFirstChild("TCHub") then
        warn("Lỗi đã có Gui đang hoạt động!")
        return nil
    end

    local previousFailure = TargetParent:FindFirstChild("TCHub_Failure")
    if previousFailure then
        previousFailure:Destroy()
    end

    Lifecycle.Status = "loading"
    local ok, result = xpcall(function()
        return createWindow(self, config)
    end, debug.traceback)

    if ok then
        return result
    end

    if Lifecycle.Gui and Lifecycle.Gui.Parent then
        Lifecycle.Gui:Destroy()
    end
    Lifecycle.Gui = nil
    Lifecycle.Window = nil
    return createFailureWindow(result)
end

return TCH
