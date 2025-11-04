local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")

local Fluent = {}
Fluent.__index = Fluent

-- Utility Functions
local function Tween(object, properties, duration, style)
	local tweenInfo = TweenInfo.new(duration or 0.3, style or Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
	local tween = TweenService:Create(object, tweenInfo, properties)
	tween:Play()
	return tween
end

local function AddGlow(parent, color)
	local Glow = Instance.new("ImageLabel")
	Glow.Name = "Glow"
	Glow.Parent = parent
	Glow.BackgroundTransparency = 1
	Glow.Position = UDim2.new(0, -15, 0, -15)
	Glow.Size = UDim2.new(1, 30, 1, 30)
	Glow.ZIndex = 0
	Glow.Image = "rbxassetid://16300778179"
	Glow.ImageColor3 = color or Color3.fromRGB(120, 80, 255)
	Glow.ImageTransparency = 0.7
	Glow.ScaleType = Enum.ScaleType.Slice
	Glow.SliceCenter = Rect.new(10, 10, 118, 118)
	return Glow
end

local function MakeDraggable(frame, dragHandle)
	local dragging, dragInput, dragStart, startPos
	
	dragHandle.InputBegan:Connect(function(input)
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
	
	dragHandle.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			dragInput = input
		end
	end)
	
	UserInputService.InputChanged:Connect(function(input)
		if input == dragInput and dragging then
			local delta = input.Position - dragStart
			Tween(frame, {
				Position = UDim2.new(
					startPos.X.Scale, 
					startPos.X.Offset + delta.X, 
					startPos.Y.Scale, 
					startPos.Y.Offset + delta.Y
				)
			}, 0.15, Enum.EasingStyle.Sine)
		end
	end)
end

-- Create Window
function Fluent:CreateWindow(config)
	config = config or {}
	local WindowName = config.Title or "Fluent UI"
	local WindowVersion = config.Version or "v1.0.0"
	local WindowSubtitle = config.Subtitle or "Modern UI Library"
	
	-- ScreenGui
	local FluentUI = Instance.new("ScreenGui")
	FluentUI.Name = "FluentUI"
	FluentUI.Parent = CoreGui
	FluentUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	FluentUI.ResetOnSpawn = false
	
	-- Main Frame
	local MainFrame = Instance.new("Frame")
	MainFrame.Name = "MainFrame"
	MainFrame.Parent = FluentUI
	MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	MainFrame.Size = UDim2.new(0, 0, 0, 0)
	MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
	MainFrame.BorderSizePixel = 0
	MainFrame.ClipsDescendants = true
	
	local MainCorner = Instance.new("UICorner")
	MainCorner.CornerRadius = UDim.new(0, 16)
	MainCorner.Parent = MainFrame
	
	local MainStroke = Instance.new("UIStroke")
	MainStroke.Color = Color3.fromRGB(80, 60, 120)
	MainStroke.Thickness = 1.5
	MainStroke.Transparency = 0.5
	MainStroke.Parent = MainFrame
	
	-- Animated gradient stroke
	local StrokeGradient = Instance.new("UIGradient")
	StrokeGradient.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.fromRGB(120, 80, 255)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(80, 120, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(120, 80, 255))
	}
	StrokeGradient.Parent = MainStroke
	
	spawn(function()
		while MainFrame.Parent do
			for i = 0, 360, 2 do
				if not MainFrame.Parent then break end
				StrokeGradient.Rotation = i
				RunService.RenderStepped:Wait()
			end
		end
	end)
	
	-- Enhanced Shadow
	local Shadow = Instance.new("ImageLabel")
	Shadow.Name = "Shadow"
	Shadow.Parent = MainFrame
	Shadow.BackgroundTransparency = 1
	Shadow.Position = UDim2.new(0, -25, 0, -25)
	Shadow.Size = UDim2.new(1, 50, 1, 50)
	Shadow.ZIndex = 0
	Shadow.Image = "rbxassetid://6014261993"
	Shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
	Shadow.ImageTransparency = 0.3
	Shadow.ScaleType = Enum.ScaleType.Slice
	Shadow.SliceCenter = Rect.new(49, 49, 450, 450)
	
	-- Glow Effect
	AddGlow(MainFrame, Color3.fromRGB(100, 70, 200))
	
	-- Background Gradient
	local BgGradient = Instance.new("UIGradient")
	BgGradient.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.fromRGB(15, 15, 20)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 15, 25))
	}
	BgGradient.Rotation = 135
	BgGradient.Parent = MainFrame
	
	-- Header
	local Header = Instance.new("Frame")
	Header.Name = "Header"
	Header.Parent = MainFrame
	Header.Size = UDim2.new(1, 0, 0, 60)
	Header.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
	Header.BackgroundTransparency = 0.2
	Header.BorderSizePixel = 0
	
	local HeaderCorner = Instance.new("UICorner")
	HeaderCorner.CornerRadius = UDim.new(0, 16)
	HeaderCorner.Parent = Header
	
	local HeaderGradient = Instance.new("UIGradient")
	HeaderGradient.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.fromRGB(25, 20, 35)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 20, 28))
	}
	HeaderGradient.Rotation = 90
	HeaderGradient.Parent = Header
	
	local HeaderBottom = Instance.new("Frame")
	HeaderBottom.Parent = Header
	HeaderBottom.Position = UDim2.new(0, 0, 1, -16)
	HeaderBottom.Size = UDim2.new(1, 0, 0, 16)
	HeaderBottom.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
	HeaderBottom.BackgroundTransparency = 0.2
	HeaderBottom.BorderSizePixel = 0
	
	-- Accent Line
	local AccentLine = Instance.new("Frame")
	AccentLine.Name = "AccentLine"
	AccentLine.Parent = Header
	AccentLine.Position = UDim2.new(0, 0, 1, -2)
	AccentLine.Size = UDim2.new(1, 0, 0, 2)
	AccentLine.BorderSizePixel = 0
	
	local AccentGradient = Instance.new("UIGradient")
	AccentGradient.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.fromRGB(120, 80, 255)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(80, 120, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(120, 80, 255))
	}
	AccentGradient.Parent = AccentLine
	
	-- Logo with animation
	local Logo = Instance.new("Frame")
	Logo.Name = "Logo"
	Logo.Parent = Header
	Logo.Position = UDim2.new(0, 20, 0.5, -18)
	Logo.Size = UDim2.new(0, 36, 0, 36)
	Logo.BackgroundColor3 = Color3.fromRGB(120, 80, 255)
	Logo.BorderSizePixel = 0
	
	local LogoCorner = Instance.new("UICorner")
	LogoCorner.CornerRadius = UDim.new(0, 10)
	LogoCorner.Parent = Logo
	
	local LogoGradient = Instance.new("UIGradient")
	LogoGradient.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.fromRGB(140, 90, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 140, 255))
	}
	LogoGradient.Rotation = 45
	LogoGradient.Parent = Logo
	
	-- Logo Icon
	local LogoIcon = Instance.new("ImageLabel")
	LogoIcon.Parent = Logo
	LogoIcon.BackgroundTransparency = 1
	LogoIcon.Size = UDim2.new(0.7, 0, 0.7, 0)
	LogoIcon.Position = UDim2.new(0.15, 0, 0.15, 0)
	LogoIcon.Image = "rbxassetid://10723407389"
	LogoIcon.ImageColor3 = Color3.fromRGB(255, 255, 255)
	
	-- Pulse animation for logo
	spawn(function()
		while Logo.Parent do
			Tween(Logo, {Size = UDim2.new(0, 38, 0, 38)}, 0.8, Enum.EasingStyle.Sine)
			wait(0.8)
			Tween(Logo, {Size = UDim2.new(0, 36, 0, 36)}, 0.8, Enum.EasingStyle.Sine)
			wait(0.8)
		end
	end)
	
	-- Title Container
	local TitleContainer = Instance.new("Frame")
	TitleContainer.Parent = Header
	TitleContainer.Position = UDim2.new(0, 65, 0, 10)
	TitleContainer.Size = UDim2.new(0, 250, 1, -20)
	TitleContainer.BackgroundTransparency = 1
	
	local Title = Instance.new("TextLabel")
	Title.Name = "Title"
	Title.Parent = TitleContainer
	Title.Size = UDim2.new(1, 0, 0, 22)
	Title.BackgroundTransparency = 1
	Title.Text = WindowName
	Title.TextColor3 = Color3.fromRGB(255, 255, 255)
	Title.TextSize = 17
	Title.Font = Enum.Font.GothamBold
	Title.TextXAlignment = Enum.TextXAlignment.Left
	Title.TextTransparency = 0
	
	local TitleGradient = Instance.new("UIGradient")
	TitleGradient.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 200, 255))
	}
	TitleGradient.Parent = Title
	
	local Subtitle = Instance.new("TextLabel")
	Subtitle.Name = "Subtitle"
	Subtitle.Parent = TitleContainer
	Subtitle.Position = UDim2.new(0, 0, 0, 22)
	Subtitle.Size = UDim2.new(1, 0, 0, 16)
	Subtitle.BackgroundTransparency = 1
	Subtitle.Text = WindowSubtitle
	Subtitle.TextColor3 = Color3.fromRGB(150, 150, 180)
	Subtitle.TextSize = 12
	Subtitle.Font = Enum.Font.Gotham
	Subtitle.TextXAlignment = Enum.TextXAlignment.Left
	
	local Version = Instance.new("TextLabel")
	Version.Name = "Version"
	Version.Parent = TitleContainer
	Version.Position = UDim2.new(0, 0, 1, -16)
	Version.Size = UDim2.new(1, 0, 0, 14)
	Version.BackgroundTransparency = 1
	Version.Text = "⚡ " .. WindowVersion
	Version.TextColor3 = Color3.fromRGB(120, 80, 255)
	Version.TextSize = 11
	Version.Font = Enum.Font.GothamBold
	Version.TextXAlignment = Enum.TextXAlignment.Left
	
	-- Close Button
	local CloseButton = Instance.new("TextButton")
	CloseButton.Name = "CloseButton"
	CloseButton.Parent = Header
	CloseButton.AnchorPoint = Vector2.new(1, 0.5)
	CloseButton.Position = UDim2.new(1, -15, 0.5, 0)
	CloseButton.Size = UDim2.new(0, 35, 0, 35)
	CloseButton.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	CloseButton.BorderSizePixel = 0
	CloseButton.Text = ""
	CloseButton.AutoButtonColor = false
	
	local CloseCorner = Instance.new("UICorner")
	CloseCorner.CornerRadius = UDim.new(0, 10)
	CloseCorner.Parent = CloseButton
	
	local CloseIcon = Instance.new("ImageLabel")
	CloseIcon.Parent = CloseButton
	CloseIcon.BackgroundTransparency = 1
	CloseIcon.Size = UDim2.new(0, 16, 0, 16)
	CloseIcon.Position = UDim2.new(0.5, -8, 0.5, -8)
	CloseIcon.Image = "rbxassetid://10747384394"
	CloseIcon.ImageColor3 = Color3.fromRGB(255, 255, 255)
	
	CloseButton.MouseEnter:Connect(function()
		Tween(CloseButton, {BackgroundColor3 = Color3.fromRGB(255, 60, 70)}, 0.2)
		Tween(CloseButton, {Size = UDim2.new(0, 37, 0, 37)}, 0.2, Enum.EasingStyle.Back)
	end)
	
	CloseButton.MouseLeave:Connect(function()
		Tween(CloseButton, {BackgroundColor3 = Color3.fromRGB(30, 30, 40)}, 0.2)
		Tween(CloseButton, {Size = UDim2.new(0, 35, 0, 35)}, 0.2)
	end)
	
	CloseButton.MouseButton1Click:Connect(function()
		Tween(CloseButton, {BackgroundColor3 = Color3.fromRGB(200, 40, 50)}, 0.1)
		Tween(MainFrame, {Size = UDim2.new(0, 0, 0, 0)}, 0.4, Enum.EasingStyle.Back)
		wait(0.4)
		FluentUI:Destroy()
	end)
	
	-- Minimize Button
	local MinimizeButton = Instance.new("TextButton")
	MinimizeButton.Name = "MinimizeButton"
	MinimizeButton.Parent = Header
	MinimizeButton.AnchorPoint = Vector2.new(1, 0.5)
	MinimizeButton.Position = UDim2.new(1, -55, 0.5, 0)
	MinimizeButton.Size = UDim2.new(0, 35, 0, 35)
	MinimizeButton.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	MinimizeButton.BorderSizePixel = 0
	MinimizeButton.Text = ""
	MinimizeButton.AutoButtonColor = false
	
	local MinimizeCorner = Instance.new("UICorner")
	MinimizeCorner.CornerRadius = UDim.new(0, 10)
	MinimizeCorner.Parent = MinimizeButton
	
	local MinimizeIcon = Instance.new("ImageLabel")
	MinimizeIcon.Parent = MinimizeButton
	MinimizeIcon.BackgroundTransparency = 1
	MinimizeIcon.Size = UDim2.new(0, 16, 0, 16)
	MinimizeIcon.Position = UDim2.new(0.5, -8, 0.5, -8)
	MinimizeIcon.Image = "rbxassetid://10734896958"
	MinimizeIcon.ImageColor3 = Color3.fromRGB(255, 255, 255)
	
	MinimizeButton.MouseEnter:Connect(function()
		Tween(MinimizeButton, {BackgroundColor3 = Color3.fromRGB(50, 50, 70)}, 0.2)
		Tween(MinimizeButton, {Size = UDim2.new(0, 37, 0, 37)}, 0.2, Enum.EasingStyle.Back)
	end)
	
	MinimizeButton.MouseLeave:Connect(function()
		Tween(MinimizeButton, {BackgroundColor3 = Color3.fromRGB(30, 30, 40)}, 0.2)
		Tween(MinimizeButton, {Size = UDim2.new(0, 35, 0, 35)}, 0.2)
	end)
	
	local minimized = false
	MinimizeButton.MouseButton1Click:Connect(function()
		minimized = not minimized
		if minimized then
			Tween(MainFrame, {Size = UDim2.new(0, 580, 0, 60)}, 0.4, Enum.EasingStyle.Quint)
			Tween(MinimizeIcon, {Rotation = 180}, 0.3)
		else
			Tween(MainFrame, {Size = UDim2.new(0, 580, 0, 450)}, 0.4, Enum.EasingStyle.Quint)
			Tween(MinimizeIcon, {Rotation = 0}, 0.3)
		end
	end)
	
	-- Tab Container
	local TabContainer = Instance.new("Frame")
	TabContainer.Name = "TabContainer"
	TabContainer.Parent = MainFrame
	TabContainer.Position = UDim2.new(0, 0, 0, 60)
	TabContainer.Size = UDim2.new(0, 160, 1, -60)
	TabContainer.BackgroundColor3 = Color3.fromRGB(12, 12, 18)
	TabContainer.BorderSizePixel = 0
	
	local TabBg = Instance.new("UIGradient")
	TabBg.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.fromRGB(12, 12, 18)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(18, 15, 25))
	}
	TabBg.Rotation = 90
	TabBg.Parent = TabContainer
	
	local TabList = Instance.new("UIListLayout")
	TabList.Parent = TabContainer
	TabList.SortOrder = Enum.SortOrder.LayoutOrder
	TabList.Padding = UDim.new(0, 6)
	
	local TabPadding = Instance.new("UIPadding")
	TabPadding.Parent = TabContainer
	TabPadding.PaddingTop = UDim.new(0, 12)
	TabPadding.PaddingLeft = UDim.new(0, 12)
	TabPadding.PaddingRight = UDim.new(0, 12)
	TabPadding.PaddingBottom = UDim.new(0, 12)
	
	-- Content Container
	local ContentContainer = Instance.new("Frame")
	ContentContainer.Name = "ContentContainer"
	ContentContainer.Parent = MainFrame
	ContentContainer.Position = UDim2.new(0, 160, 0, 60)
	ContentContainer.Size = UDim2.new(1, -160, 1, -60)
	ContentContainer.BackgroundTransparency = 1
	ContentContainer.BorderSizePixel = 0
	
	-- Make draggable
	MakeDraggable(MainFrame, Header)
	
	-- Animate opening
	Tween(MainFrame, {Size = UDim2.new(0, 580, 0, 450)}, 0.6, Enum.EasingStyle.Back)
	
	local Window = {}
	Window.Tabs = {}
	Window.CurrentTab = nil
	
	function Window:AddTab(config)
		config = config or {}
		local TabName = config.Name or "Tab"
		local TabIcon = config.Icon or "rbxassetid://10723407389"
		
		-- Tab Button
		local TabButton = Instance.new("TextButton")
		TabButton.Name = TabName
		TabButton.Parent = TabContainer
		TabButton.Size = UDim2.new(1, 0, 0, 42)
		TabButton.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
		TabButton.BorderSizePixel = 0
		TabButton.Text = ""
		TabButton.AutoButtonColor = false
		
		local TabCorner = Instance.new("UICorner")
		TabCorner.CornerRadius = UDim.new(0, 10)
		TabCorner.Parent = TabButton
		
		local TabStroke = Instance.new("UIStroke")
		TabStroke.Color = Color3.fromRGB(40, 40, 50)
		TabStroke.Thickness = 1
		TabStroke.Transparency = 0.8
		TabStroke.Parent = TabButton
		
		-- Tab Icon
		local TabIconFrame = Instance.new("ImageLabel")
		TabIconFrame.Parent = TabButton
		TabIconFrame.Position = UDim2.new(0, 12, 0.5, -10)
		TabIconFrame.Size = UDim2.new(0, 20, 0, 20)
		TabIconFrame.BackgroundTransparency = 1
		TabIconFrame.Image = TabIcon
		TabIconFrame.ImageColor3 = Color3.fromRGB(150, 150, 180)
		
		-- Tab Label
		local TabLabel = Instance.new("TextLabel")
		TabLabel.Parent = TabButton
		TabLabel.Position = UDim2.new(0, 42, 0, 0)
		TabLabel.Size = UDim2.new(1, -50, 1, 0)
		TabLabel.BackgroundTransparency = 1
		TabLabel.Text = TabName
		TabLabel.TextColor3 = Color3.fromRGB(150, 150, 180)
		TabLabel.TextSize = 13
		TabLabel.Font = Enum.Font.GothamMedium
		TabLabel.TextXAlignment = Enum.TextXAlignment.Left
		
		-- Selection Indicator
		local SelectionIndicator = Instance.new("Frame")
		SelectionIndicator.Name = "SelectionIndicator"
		SelectionIndicator.Parent = TabButton
		SelectionIndicator.AnchorPoint = Vector2.new(0, 0.5)
		SelectionIndicator.Position = UDim2.new(0, 0, 0.5, 0)
		SelectionIndicator.Size = UDim2.new(0, 0, 0, 25)
		SelectionIndicator.BackgroundColor3 = Color3.fromRGB(120, 80, 255)
		SelectionIndicator.BorderSizePixel = 0
		
		local IndicatorCorner = Instance.new("UICorner")
		IndicatorCorner.CornerRadius = UDim.new(0, 4)
		IndicatorCorner.Parent = SelectionIndicator
		
		local IndicatorGradient = Instance.new("UIGradient")
		IndicatorGradient.Color = ColorSequence.new{
			ColorSequenceKeypoint.new(0, Color3.fromRGB(120, 80, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 140, 255))
		}
		IndicatorGradient.Rotation = 90
		IndicatorGradient.Parent = SelectionIndicator
		
		-- Tab Content
		local TabContent = Instance.new("ScrollingFrame")
		TabContent.Name = TabName .. "Content"
		TabContent.Parent = ContentContainer
		TabContent.Size = UDim2.new(1, 0, 1, 0)
		TabContent.BackgroundTransparency = 1
		TabContent.BorderSizePixel = 0
		TabContent.ScrollBarThickness = 6
		TabContent.ScrollBarImageColor3 = Color3.fromRGB(120, 80, 255)
		TabContent.ScrollBarImageTransparency = 0.5
		TabContent.Visible = false
		TabContent.CanvasSize = UDim2.new(0, 0, 0, 0)
		
		local ContentList = Instance.new("UIListLayout")
		ContentList.Parent = TabContent
		ContentList.SortOrder = Enum.SortOrder.LayoutOrder
		ContentList.Padding = UDim.new(0, 10)
		
		local ContentPadding = Instance.new("UIPadding")
		ContentPadding.Parent = TabContent
		ContentPadding.PaddingTop = UDim.new(0, 15)
		ContentPadding.PaddingLeft = UDim.new(0, 20)
		ContentPadding.PaddingRight = UDim.new(0, 20)
		ContentPadding.PaddingBottom = UDim.new(0, 15)
		
		ContentList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			TabContent.CanvasSize = UDim2.new(0, 0, 0, ContentList.AbsoluteContentSize.Y + 30)
		end)
		
		TabButton.MouseEnter:Connect(function()
			if Window.CurrentTab ~= TabContent then
				Tween(TabButton, {BackgroundColor3 = Color3.fromRGB(25, 25, 35)}, 0.2)
				Tween(TabIconFrame, {ImageColor3 = Color3.fromRGB(200, 200, 220)}, 0.2)
				Tween(TabLabel, {TextColor3 = Color3.fromRGB(200, 200, 220)}, 0.2)
			end
		end)
		
		TabButton.MouseLeave:Connect(function()
			if Window.CurrentTab ~= TabContent then
				Tween(TabButton, {BackgroundColor3 = Color3.fromRGB(20, 20, 28)}, 0.2)
				Tween(TabIconFrame, {ImageColor3 = Color3.fromRGB(150, 150, 180)}, 0.2)
				Tween(TabLabel, {TextColor3 = Color3.fromRGB(150, 150, 180)}, 0.2)
			end
		end)
		
		TabButton.MouseButton1Click:Connect(function()
			for _, tab in pairs(Window.Tabs) do
				Tween(tab.Button, {BackgroundColor3 = Color3.fromRGB(20, 20, 28)}, 0.3)
				Tween(tab.Icon, {ImageColor3 = Color3.fromRGB(150, 150, 180)}, 0.3)
				Tween(tab.Label, {TextColor3 = Color3.fromRGB(150, 150, 180)}, 0.3)
				Tween(tab.Indicator, {Size = UDim2.new(0, 0, 0, 25)}, 0.3)
				Tween(tab.Stroke, {Transparency = 0.8}, 0.3)
				tab.Content.Visible = false
			end
			
			Tween(TabButton, {BackgroundColor3 = Color3.fromRGB(30, 25, 40)}, 0.3)
			Tween(TabIconFrame, {ImageColor3 = Color3.fromRGB(120, 80, 255)}, 0.3)
			Tween(TabLabel, {TextColor3 = Color3.fromRGB(255, 255, 255)}, 0.3)
			Tween(SelectionIndicator, {Size = UDim2.new(0, 4, 0, 25)}, 0.3, Enum.EasingStyle.Back)
			Tween(TabStroke, {Transparency = 0.3}, 0.3)
			TabContent.Visible = true
			Window.CurrentTab = TabContent
		end)
		
		local Tab = {}
		Tab.Button = TabButton
		Tab.Content = TabContent
		Tab.Icon = TabIconFrame
		Tab.Label = TabLabel
		Tab.Indicator = SelectionIndicator
		Tab.Stroke = TabStroke
		
		function Tab:AddButton(config)
			config = config or {}
			local ButtonName = config.Name or "Button"
			local ButtonDesc = config.Description
			local Callback = config.Callback or function() end
			
			local ButtonFrame = Instance.new("Frame")
			ButtonFrame.Name = ButtonName
			ButtonFrame.Parent = TabContent
			ButtonFrame.Size = UDim2.new(1, 0, 0, ButtonDesc and 60 or 45)
			ButtonFrame.BackgroundColor	end)
	
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
