local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local Fluent = {}
Fluent.__index = Fluent

-- Utility Functions
local function Tween(object, properties, duration, style)
	local tweenInfo = TweenInfo.new(duration or 0.1, style or Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local tween = TweenService:Create(object, tweenInfo, properties)
	tween:Play()
	return tween
end

local function MakeDraggable(frame)
	local dragging, dragInput, dragStart, startPos
	
	frame.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			dragStart = input.Position
			startPos = frame.Position
			
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)
	
	frame.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			dragInput = input
		end
	end)
	
	UserInputService.InputChanged:Connect(function(input)
		if input == dragInput and dragging then
			local delta = input.Position - dragStart
			Tween(frame, {Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)}, 0.1)
		end
	end)
end

-- Create Window
function Fluent:CreateWindow(config)
	config = config or {}
	local WindowName = config.Title or "Fluent UI"
	local WindowVersion = config.Version or "v1.0.0"
	
	-- ScreenGui
	local FluentUI = Instance.new("ScreenGui")
	FluentUI.Name = "FluentUI"
	FluentUI.Parent = CoreGui
	FluentUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	
	-- Main Frame
	local MainFrame = Instance.new("Frame")
	MainFrame.Name = "MainFrame"
	MainFrame.Parent = FluentUI
	MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	MainFrame.Size = UDim2.new(0, 0, 0, 0)
	MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
	MainFrame.BorderSizePixel = 0
	MainFrame.ClipsDescendants = true
	
	local MainCorner = Instance.new("UICorner")
	MainCorner.CornerRadius = UDim.new(0, 12)
	MainCorner.Parent = MainFrame
	
	local MainStroke = Instance.new("UIStroke")
	MainStroke.Color = Color3.fromRGB(60, 60, 70)
	MainStroke.Thickness = 1
	MainStroke.Parent = MainFrame
	
	-- Shadow Effect
	local Shadow = Instance.new("ImageLabel")
	Shadow.Name = "Shadow"
	Shadow.Parent = MainFrame
	Shadow.BackgroundTransparency = 1
	Shadow.Position = UDim2.new(0, -15, 0, -15)
	Shadow.Size = UDim2.new(1, 30, 1, 30)
	Shadow.ZIndex = 0
	Shadow.Image = "rbxassetid://6014261993"
	Shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
	Shadow.ImageTransparency = 0.5
	Shadow.ScaleType = Enum.ScaleType.Slice
	Shadow.SliceCenter = Rect.new(49, 49, 450, 450)
	
	-- Header
	local Header = Instance.new("Frame")
	Header.Name = "Header"
	Header.Parent = MainFrame
	Header.Size = UDim2.new(1, 0, 0, 50)
	Header.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
	Header.BorderSizePixel = 0
	
	local HeaderCorner = Instance.new("UICorner")
	HeaderCorner.CornerRadius = UDim.new(0, 12)
	HeaderCorner.Parent = Header
	
	local HeaderBottom = Instance.new("Frame")
	HeaderBottom.Parent = Header
	HeaderBottom.Position = UDim2.new(0, 0, 1, -12)
	HeaderBottom.Size = UDim2.new(1, 0, 0, 12)
	HeaderBottom.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
	HeaderBottom.BorderSizePixel = 0
	
	-- Logo
	local Logo = Instance.new("Frame")
	Logo.Name = "Logo"
	Logo.Parent = Header
	Logo.Position = UDim2.new(0, 15, 0.5, -15)
	Logo.Size = UDim2.new(0, 30, 0, 30)
	Logo.BackgroundColor3 = Color3.fromRGB(120, 80, 255)
	Logo.BorderSizePixel = 0
	
	local LogoCorner = Instance.new("UICorner")
	LogoCorner.CornerRadius = UDim.new(0, 8)
	LogoCorner.Parent = Logo
	
	local LogoGradient = Instance.new("UIGradient")
	LogoGradient.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.fromRGB(120, 80, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 120, 255))
	}
	LogoGradient.Rotation = 45
	LogoGradient.Parent = Logo
	
	-- Title
	local Title = Instance.new("TextLabel")
	Title.Name = "Title"
	Title.Parent = Header
	Title.Position = UDim2.new(0, 55, 0, 8)
	Title.Size = UDim2.new(0, 200, 0, 20)
	Title.BackgroundTransparency = 1
	Title.Text = WindowName
	Title.TextColor3 = Color3.fromRGB(255, 255, 255)
	Title.TextSize = 16
	Title.Font = Enum.Font.GothamBold
	Title.TextXAlignment = Enum.TextXAlignment.Left
	
	local Version = Instance.new("TextLabel")
	Version.Name = "Version"
	Version.Parent = Header
	Version.Position = UDim2.new(0, 55, 0, 28)
	Version.Size = UDim2.new(0, 200, 0, 14)
	Version.BackgroundTransparency = 1
	Version.Text = WindowVersion
	Version.TextColor3 = Color3.fromRGB(150, 150, 160)
	Version.TextSize = 11
	Version.Font = Enum.Font.Gotham
	Version.TextXAlignment = Enum.TextXAlignment.Left
	
	-- Close Button
	local CloseButton = Instance.new("TextButton")
	CloseButton.Name = "CloseButton"
	CloseButton.Parent = Header
	CloseButton.AnchorPoint = Vector2.new(1, 0.5)
	CloseButton.Position = UDim2.new(1, -10, 0.5, 0)
	CloseButton.Size = UDim2.new(0, 30, 0, 30)
	CloseButton.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
	CloseButton.BorderSizePixel = 0
	CloseButton.Text = "✕"
	CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	CloseButton.TextSize = 16
	CloseButton.Font = Enum.Font.GothamBold
	
	local CloseCorner = Instance.new("UICorner")
	CloseCorner.CornerRadius = UDim.new(0, 8)
	CloseCorner.Parent = CloseButton
	
	CloseButton.MouseEnter:Connect(function()
		Tween(CloseButton, {BackgroundColor3 = Color3.fromRGB(255, 50, 50)}, 0.2)
	end)
	
	CloseButton.MouseLeave:Connect(function()
		Tween(CloseButton, {BackgroundColor3 = Color3.fromRGB(35, 35, 40)}, 0.2)
	end)
	
	CloseButton.MouseButton1Click:Connect(function()
		Tween(MainFrame, {Size = UDim2.new(0, 0, 0, 0)}, 0.3, Enum.EasingStyle.Back)
		wait(0.3)
		FluentUI:Destroy()
	end)
	
	-- Minimize Button
	local MinimizeButton = Instance.new("TextButton")
	MinimizeButton.Name = "MinimizeButton"
	MinimizeButton.Parent = Header
	MinimizeButton.AnchorPoint = Vector2.new(1, 0.5)
	MinimizeButton.Position = UDim2.new(1, -45, 0.5, 0)
	MinimizeButton.Size = UDim2.new(0, 30, 0, 30)
	MinimizeButton.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
	MinimizeButton.BorderSizePixel = 0
	MinimizeButton.Text = "—"
	MinimizeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	MinimizeButton.TextSize = 16
	MinimizeButton.Font = Enum.Font.GothamBold
	
	local MinimizeCorner = Instance.new("UICorner")
	MinimizeCorner.CornerRadius = UDim.new(0, 8)
	MinimizeCorner.Parent = MinimizeButton
	
	MinimizeButton.MouseEnter:Connect(function()
		Tween(MinimizeButton, {BackgroundColor3 = Color3.fromRGB(50, 50, 60)}, 0.2)
	end)
	
	MinimizeButton.MouseLeave:Connect(function()
		Tween(MinimizeButton, {BackgroundColor3 = Color3.fromRGB(35, 35, 40)}, 0.2)
	end)
	
	local minimized = false
	MinimizeButton.MouseButton1Click:Connect(function()
		minimized = not minimized
		if minimized then
			Tween(MainFrame, {Size = UDim2.new(0, 550, 0, 50)}, 0.3)
		else
			Tween(MainFrame, {Size = UDim2.new(0, 550, 0, 400)}, 0.3)
		end
	end)
	
	-- Tab Container
	local TabContainer = Instance.new("Frame")
	TabContainer.Name = "TabContainer"
	TabContainer.Parent = MainFrame
	TabContainer.Position = UDim2.new(0, 0, 0, 50)
	TabContainer.Size = UDim2.new(0, 140, 1, -50)
	TabContainer.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
	TabContainer.BorderSizePixel = 0
	
	local TabList = Instance.new("UIListLayout")
	TabList.Parent = TabContainer
	TabList.SortOrder = Enum.SortOrder.LayoutOrder
	TabList.Padding = UDim.new(0, 5)
	
	local TabPadding = Instance.new("UIPadding")
	TabPadding.Parent = TabContainer
	TabPadding.PaddingTop = UDim.new(0, 10)
	TabPadding.PaddingLeft = UDim.new(0, 10)
	TabPadding.PaddingRight = UDim.new(0, 10)
	
	-- Content Container
	local ContentContainer = Instance.new("Frame")
	ContentContainer.Name = "ContentContainer"
	ContentContainer.Parent = MainFrame
	ContentContainer.Position = UDim2.new(0, 140, 0, 50)
	ContentContainer.Size = UDim2.new(1, -140, 1, -50)
	ContentContainer.BackgroundTransparency = 1
	ContentContainer.BorderSizePixel = 0
	
	-- Make draggable
	MakeDraggable(Header)
	
	-- Animate opening
	Tween(MainFrame, {Size = UDim2.new(0, 550, 0, 400)}, 0.5, Enum.EasingStyle.Back)
	
	local Window = {}
	Window.Tabs = {}
	Window.CurrentTab = nil
	
	function Window:AddTab(config)
		config = config or {}
		local TabName = config.Name or "Tab"
		local TabIcon = config.Icon or "📋"
		
		-- Tab Button
		local TabButton = Instance.new("TextButton")
		TabButton.Name = TabName
		TabButton.Parent = TabContainer
		TabButton.Size = UDim2.new(1, 0, 0, 35)
		TabButton.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
		TabButton.BorderSizePixel = 0
		TabButton.Text = "  " .. TabIcon .. "  " .. TabName
		TabButton.TextColor3 = Color3.fromRGB(180, 180, 190)
		TabButton.TextSize = 13
		TabButton.Font = Enum.Font.GothamMedium
		TabButton.TextXAlignment = Enum.TextXAlignment.Left
		
		local TabCorner = Instance.new("UICorner")
		TabCorner.CornerRadius = UDim.new(0, 8)
		TabCorner.Parent = TabButton
		
		local TabPadding = Instance.new("UIPadding")
		TabPadding.Parent = TabButton
		TabPadding.PaddingLeft = UDim.new(0, 10)
		
		-- Tab Content
		local TabContent = Instance.new("ScrollingFrame")
		TabContent.Name = TabName .. "Content"
		TabContent.Parent = ContentContainer
		TabContent.Size = UDim2.new(1, 0, 1, 0)
		TabContent.BackgroundTransparency = 1
		TabContent.BorderSizePixel = 0
		TabContent.ScrollBarThickness = 4
		TabContent.ScrollBarImageColor3 = Color3.fromRGB(120, 80, 255)
		TabContent.Visible = false
		
		local ContentList = Instance.new("UIListLayout")
		ContentList.Parent = TabContent
		ContentList.SortOrder = Enum.SortOrder.LayoutOrder
		ContentList.Padding = UDim.new(0, 8)
		
		local ContentPadding = Instance.new("UIPadding")
		ContentPadding.Parent = TabContent
		ContentPadding.PaddingTop = UDim.new(0, 10)
		ContentPadding.PaddingLeft = UDim.new(0, 15)
		ContentPadding.PaddingRight = UDim.new(0, 15)
		ContentPadding.PaddingBottom = UDim.new(0, 10)
		
		ContentList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			TabContent.CanvasSize = UDim2.new(0, 0, 0, ContentList.AbsoluteContentSize.Y + 20)
		end)
		
		TabButton.MouseEnter:Connect(function()
			if Window.CurrentTab ~= TabContent then
				Tween(TabButton, {BackgroundColor3 = Color3.fromRGB(30, 30, 35)}, 0.2)
			end
		end)
		
		TabButton.MouseLeave:Connect(function()
			if Window.CurrentTab ~= TabContent then
				Tween(TabButton, {BackgroundColor3 = Color3.fromRGB(25, 25, 30)}, 0.2)
			end
		end)
		
		TabButton.MouseButton1Click:Connect(function()
			for _, tab in pairs(Window.Tabs) do
				tab.Button.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
				tab.Button.TextColor3 = Color3.fromRGB(180, 180, 190)
				tab.Content.Visible = false
			end
			
			TabButton.BackgroundColor3 = Color3.fromRGB(120, 80, 255)
			TabButton.TextColor3 = Color3.fromRGB(255, 255, 255)
			TabContent.Visible = true
			Window.CurrentTab = TabContent
		end)
		
		local Tab = {}
		Tab.Button = TabButton
		Tab.Content = TabContent
		
		function Tab:AddButton(config)
			config = config or {}
			local ButtonName = config.Name or "Button"
			local Callback = config.Callback or function() end
			
			local Button = Instance.new("TextButton")
			Button.Name = ButtonName
			Button.Parent = TabContent
			Button.Size = UDim2.new(1, 0, 0, 35)
			Button.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
			Button.BorderSizePixel = 0
			Button.Text = ButtonName
			Button.TextColor3 = Color3.fromRGB(255, 255, 255)
			Button.TextSize = 13
			Button.Font = Enum.Font.GothamMedium
			
			local ButtonCorner = Instance.new("UICorner")
			ButtonCorner.CornerRadius = UDim.new(0, 8)
			ButtonCorner.Parent = Button
			
			Button.MouseEnter:Connect(function()
				Tween(Button, {BackgroundColor3 = Color3.fromRGB(120, 80, 255)}, 0.2)
			end)
			
			Button.MouseLeave:Connect(function()
				Tween(Button, {BackgroundColor3 = Color3.fromRGB(30, 30, 35)}, 0.2)
			end)
			
			Button.MouseButton1Click:Connect(function()
				Button.TextSize = 11
				wait(0.1)
				Button.TextSize = 13
				Callback()
			end)
			
			return Button
		end
		
		function Tab:AddToggle(config)
			config = config or {}
			local ToggleName = config.Name or "Toggle"
			local Default = config.Default or false
			local Callback = config.Callback or function() end
			
			local ToggleFrame = Instance.new("Frame")
			ToggleFrame.Name = ToggleName
			ToggleFrame.Parent = TabContent
			ToggleFrame.Size = UDim2.new(1, 0, 0, 35)
			ToggleFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
			ToggleFrame.BorderSizePixel = 0
			
			local ToggleCorner = Instance.new("UICorner")
			ToggleCorner.CornerRadius = UDim.new(0, 8)
			ToggleCorner.Parent = ToggleFrame
			
			local ToggleLabel = Instance.new("TextLabel")
			ToggleLabel.Parent = ToggleFrame
			ToggleLabel.Position = UDim2.new(0, 10, 0, 0)
			ToggleLabel.Size = UDim2.new(1, -60, 1, 0)
			ToggleLabel.BackgroundTransparency = 1
			ToggleLabel.Text = ToggleName
			ToggleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
			ToggleLabel.TextSize = 13
			ToggleLabel.Font = Enum.Font.GothamMedium
			ToggleLabel.TextXAlignment = Enum.TextXAlignment.Left
			
			local ToggleButton = Instance.new("TextButton")
			ToggleButton.Parent = ToggleFrame
			ToggleButton.AnchorPoint = Vector2.new(1, 0.5)
			ToggleButton.Position = UDim2.new(1, -10, 0.5, 0)
			ToggleButton.Size = UDim2.new(0, 40, 0, 20)
			ToggleButton.BackgroundColor3 = Default and Color3.fromRGB(120, 80, 255) or Color3.fromRGB(50, 50, 60)
			ToggleButton.BorderSizePixel = 0
			ToggleButton.Text = ""
			
			local ToggleButtonCorner = Instance.new("UICorner")
			ToggleButtonCorner.CornerRadius = UDim.new(1, 0)
			ToggleButtonCorner.Parent = ToggleButton
			
			local ToggleCircle = Instance.new("Frame")
			ToggleCircle.Parent = ToggleButton
			ToggleCircle.Position = Default and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
			ToggleCircle.Size = UDim2.new(0, 16, 0, 16)
			ToggleCircle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			ToggleCircle.BorderSizePixel = 0
			
			local CircleCorner = Instance.new("UICorner")
			CircleCorner.CornerRadius = UDim.new(1, 0)
			CircleCorner.Parent = ToggleCircle
			
			local toggled = Default
			
			ToggleButton.MouseButton1Click:Connect(function()
				toggled = not toggled
				
				if toggled then
					Tween(ToggleButton, {BackgroundColor3 = Color3.fromRGB(120, 80, 255)}, 0.2)
					Tween(ToggleCircle, {Position = UDim2.new(1, -18, 0.5, -8)}, 0.2)
				else
					Tween(ToggleButton, {BackgroundColor3 = Color3.fromRGB(50, 50, 60)}, 0.2)
					Tween(ToggleCircle, {Position = UDim2.new(0, 2, 0.5, -8)}, 0.2)
				end
				
				Callback(toggled)
			end)
			
			return ToggleFrame
		end
		
		function Tab:AddSlider(config)
			config = config or {}
			local SliderName = config.Name or "Slider"
			local Min = config.Min or 0
			local Max = config.Max or 100
			local Default = config.Default or 50
			local Callback = config.Callback or function() end
			
			local SliderFrame = Instance.new("Frame")
			SliderFrame.Name = SliderName
			SliderFrame.Parent = TabContent
			SliderFrame.Size = UDim2.new(1, 0, 0, 50)
			SliderFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
			SliderFrame.BorderSizePixel = 0
			
			local SliderCorner = Instance.new("UICorner")
			SliderCorner.CornerRadius = UDim.new(0, 8)
			SliderCorner.Parent = SliderFrame
			
			local SliderLabel = Instance.new("TextLabel")
			SliderLabel.Parent = SliderFrame
			SliderLabel.Position = UDim2.new(0, 10, 0, 5)
			SliderLabel.Size = UDim2.new(1, -20, 0, 15)
			SliderLabel.BackgroundTransparency = 1
			SliderLabel.Text = SliderName
			SliderLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
			SliderLabel.TextSize = 13
			SliderLabel.Font = Enum.Font.GothamMedium
			SliderLabel.TextXAlignment = Enum.TextXAlignment.Left
			
			local SliderValue = Instance.new("TextLabel")
			SliderValue.Parent = SliderFrame
			SliderValue.Position = UDim2.new(1, -50, 0, 5)
			SliderValue.Size = UDim2.new(0, 40, 0, 15)
			SliderValue.BackgroundTransparency = 1
			SliderValue.Text = tostring(Default)
			SliderValue.TextColor3 = Color3.fromRGB(120, 80, 255)
			SliderValue.TextSize = 13
			SliderValue.Font = Enum.Font.GothamBold
			SliderValue.TextXAlignment = Enum.TextXAlignment.Right
			
			local SliderBar = Instance.new("Frame")
			SliderBar.Parent = SliderFrame
			SliderBar.Position = UDim2.new(0, 10, 0, 30)
			SliderBar.Size = UDim2.new(1, -20, 0, 6)
			SliderBar.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
			SliderBar.BorderSizePixel = 0
			
			local SliderBarCorner = Instance.new("UICorner")
			SliderBarCorner.CornerRadius = UDim.new(1, 0)
			SliderBarCorner.Parent = SliderBar
			
			local SliderFill = Instance.new("Frame")
			SliderFill.Parent = SliderBar
			SliderFill.Size = UDim2.new((Default - Min) / (Max - Min), 0, 1, 0)
			SliderFill.BackgroundColor3 = Color3.fromRGB(120, 80, 255)
			SliderFill.BorderSizePixel = 0
			
			local SliderFillCorner = Instance.new("UICorner")
			SliderFillCorner.CornerRadius = UDim.new(1, 0)
			SliderFillCorner.Parent = SliderFill
			
			local SliderButton = Instance.new("TextButton")
			SliderButton.Parent = SliderBar
			SliderButton.Size = UDim2.new(1, 0, 1, 0)
			SliderButton.BackgroundTransparency = 1
			SliderButton.Text = ""
			
			local dragging = false
			
			SliderButton.MouseButton1Down:Connect(function()
				dragging = true
			end)
			
			UserInputService.InputEnded:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 then
					dragging = false
				end
			end)
			
			SliderButton.MouseMoved:Connect(function(x, y)
				if dragging then
					local percentage = math.clamp((x - SliderBar.AbsolutePosition.X) / SliderBar.AbsoluteSize.X, 0, 1)
					local value = math.floor(Min + (Max - Min) * percentage)
					
					SliderValue.Text = tostring(value)
					Tween(SliderFill, {Size = UDim2.new(percentage, 0, 1, 0)}, 0.1)
					Callback(value)
				end
			end)
			
			return SliderFrame
		end
		
		function Tab:AddLabel(text)
			local Label = Instance.new("TextLabel")
			Label.Parent = TabContent
			Label.Size = UDim2.new(1, 0, 0, 25)
			Label.BackgroundTransparency = 1
			Label.Text = text or "Label"
			Label.TextColor3 = Color3.fromRGB(200, 200, 210)
			Label.TextSize = 13
			Label.Font = Enum.Font.Gotham
			Label.TextXAlignment = Enum.TextXAlignment.Left
			
			return Label
		end
		
		table.insert(Window.Tabs, Tab)
		
		if #Window.Tabs == 1 then
			TabButton.BackgroundColor3 = Color3.fromRGB(120, 80, 255)
			TabButton.TextColor3 = Color3.fromRGB(255, 255, 255)
			TabContent.Visible = true
			Window.CurrentTab = TabContent
		end
		
		return Tab
	end
	
	return Window
end

return Fluent
