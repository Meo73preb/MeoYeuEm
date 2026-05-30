local UIS = game:GetService("UserInputService")
local TS = game:GetService("TweenService")
local CG = (game:GetService("CoreGui") or game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui"))

local TCH = {}

-- Chức năng kéo thả (Dựa trên source cũ)
function TCH:MakeDraggable(gui)
    local dragging, dragStart, startPos
    gui.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = gui.Position
        end
    end)
    UIS.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            TS:Create(gui, TweenInfo.new(0.15), {Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)}):Play()
        end
    end)
    UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

function TCH:Window(cfg)
    local screen = Instance.new("ScreenGui", CG)
    local main = Instance.new("Frame", screen)
    main.Size = UDim2.new(0, 450, 0, 300)
    main.Position = UDim2.new(0.5, -225, 0.5, -150)
    main.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    Instance.new("UICorner", main).CornerRadius = UDim.new(0, 8)
    TCH:MakeDraggable(main)

    local top = Instance.new("Frame", main)
    top.Size = UDim2.new(1, 0, 0, 40)
    top.BackgroundColor3 = cfg.Color or Color3.fromRGB(0, 255, 128)
    Instance.new("UICorner", top).CornerRadius = UDim.new(0, 8)
    
    local title = Instance.new("TextLabel", top)
    title.Text = (cfg.Title or "Tea Cat Hub") .. " " .. (cfg.SubTitle or "")
    title.Size = UDim2.new(1, 0, 1, 0)
    title.BackgroundTransparency = 1
    title.TextColor3 = Color3.new(1, 1, 1)
    title.Font = Enum.Font.GothamBold

    local container = Instance.new("ScrollingFrame", main)
    container.Size = UDim2.new(1, -20, 1, -60)
    container.Position = UDim2.new(0, 10, 0, 50)
    container.BackgroundTransparency = 1
    Instance.new("UIListLayout", container).Padding = UDim.new(0, 10)

    local wnd = {}
    function wnd:Tab(name)
        local tab = {}
        function tab:Label(txt) Instance.new("TextLabel", container).Text = txt end
        function tab:Toggle(txt, def, cb)
            local btn = Instance.new("TextButton", container)
            btn.Size = UDim2.new(1, 0, 0, 30)
            btn.Text = txt .. ": " .. tostring(def)
            btn.MouseButton1Click:Connect(function()
                def = not def
                btn.Text = txt .. ": " .. tostring(def)
                cb(def)
            end)
        end
        function tab:Slider(txt, min, max, def, cb)
            local box = Instance.new("TextBox", container)
            box.Size = UDim2.new(1, 0, 0, 30)
            box.Text = txt .. ": " .. tostring(def)
            box.FocusLost:Connect(function() cb(tonumber(box.Text) or def) end)
        end
        function tab:Dropdown(txt, list, multi, cb)
            local btn = Instance.new("TextButton", container)
            btn.Size = UDim2.new(1, 0, 0, 30)
            btn.Text = "Chọn: " .. txt
            btn.MouseButton1Click:Connect(function() cb(list[1]) end)
        end
        return tab
    end
    return wnd
end

function TCH:Notify(t, d, s)
    print("Thông báo: " .. t .. " - " .. d)
end

return TCH
