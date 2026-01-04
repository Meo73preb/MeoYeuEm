-- Vicat Hub UI Library - Optimized Version
-- Cleanup existing UI
if game:GetService("CoreGui"):FindFirstChild("VicatHub") then
	game:GetService("CoreGui").VicatHub:Destroy()
end
if game:GetService("CoreGui"):FindFirstChild("ScreenGui") then
	game:GetService("CoreGui").ScreenGui:Destroy()
end

-- Theme Colors
_G.Primary = Color3.fromRGB(100, 100, 100)
_G.Dark = Color3.fromRGB(22, 22, 26)
_G.Third = Color3.fromRGB(255, 0, 0)

-- Utility Functions
local function CreateRounded(Parent, Size)
	local Rounded = Instance.new("UICorner")
	Rounded.Name = "Rounded"
	Rounded.Parent = Parent
	Rounded.CornerRadius = UDim.new(0, Size)
	return Rounded
end

local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local function MakeDraggable(topbarobject, object)
	local Dragging, DragInput, DragStart, StartPosition
	
	local function Update(input)
		local Delta = input.Position - DragStart
		local pos = UDim2.new(StartPosition.X.Scale, StartPosition.X.Offset + Delta.X, StartPosition.Y.Scale, StartPosition.Y.Offset + Delta.Y)
		TweenService:Create(object, TweenInfo.new(0.15), {Position = pos}):Play()
	end
	
	topbarobject.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			Dragging = true
			DragStart = input.Position
			StartPosition = object.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					Dragging = false
				end
			end)
		end
	end)
	
	topbarobject.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			DragInput = input
		end
	end)
	
	UserInputService.InputChanged:Connect(function(input)
		if input == DragInput and Dragging then
			Update(input)
		end
	end)
end

-- Toggle Button
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Parent = game.CoreGui
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local OutlineButton = Instance.new("Frame")
OutlineButton.Name = "OutlineButton"
OutlineButton.Parent = ScreenGui
OutlineButton.ClipsDescendants = true
OutlineButton.BackgroundColor3 = _G.Dark
OutlineButton.Position = UDim2.new(0, 10, 0, 10)
OutlineButton.Size = UDim2.new(0, 50, 0, 50)
CreateRounded(OutlineButton, 12)

local ImageButton = Instance.new("ImageButton")
ImageButton.Parent = OutlineButton
ImageButton.Position = UDim2.new(0.5, 0, 0.5, 0)
ImageButton.Size = UDim2.new(0, 40, 0, 40)
ImageButton.AnchorPoint = Vector2.new(0.5, 0.5)
ImageButton.BackgroundColor3 = _G.Dark
ImageButton.ImageColor3 = Color3.fromRGB(250, 250, 250)
ImageButton.Image = "rbxassetid://13940080072"
ImageButton.AutoButtonColor = false
CreateRounded(ImageButton, 10)
MakeDraggable(ImageButton, OutlineButton)

ImageButton.MouseButton1Click:Connect(function()
	local hub = game.CoreGui:FindFirstChild("VicatHub")
	if hub then
		hub.Enabled = not hub.Enabled
	end
end)

-- Notification System (Optimized)
local NotificationFrame = Instance.new("ScreenGui")
NotificationFrame.Name = "NotificationFrame"
NotificationFrame.Parent = game.CoreGui
NotificationFrame.ZIndexBehavior = Enum.ZIndexBehavior.Global

local NotificationList = {}

local function UpdateNotificationPositions()
	for i, notifData in ipairs(NotificationList) do
		local frame = notifData[1]
		if frame and frame.Parent then
			frame:TweenPosition(
				UDim2.new(0.5, 0, 0.1 + (i - 1) * 0.1, 0),
				"Out", "Quad", 0.3, true
			)
		end
	end
end

local function RemoveNotification(notifData)
	for i, data in ipairs(NotificationList) do
		if data == notifData then
			table.remove(NotificationList, i)
			break
		end
	end
	
	local frame = notifData[1]
	if frame and frame.Parent then
		frame:TweenPosition(UDim2.new(0.5, 0, -0.2, 0), "Out", "Quad", 0.3, true, function()
			frame:Destroy()
		end)
	end
	
	UpdateNotificationPositions()
end

local Update = {}

function Update:Notify(desc)
	local OutlineFrame = Instance.new("Frame")
	OutlineFrame.Name = "OutlineFrame"
	OutlineFrame.Parent = NotificationFrame
	OutlineFrame.ClipsDescendants = true
	OutlineFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	OutlineFrame.AnchorPoint = Vector2.new(0.5, 1)
	OutlineFrame.BackgroundTransparency = 0.4
	OutlineFrame.Position = UDim2.new(0.5, 0, -0.2, 0)
	OutlineFrame.Size = UDim2.new(0, 412, 0, 72)
	CreateRounded(OutlineFrame, 12)
	
	local Frame = Instance.new("Frame")
	Frame.Name = "Frame"
	Frame.Parent = OutlineFrame
	Frame.ClipsDescendants = true
	Frame.AnchorPoint = Vector2.new(0.5, 0.5)
	Frame.BackgroundColor3 = _G.Dark
	Frame.BackgroundTransparency = 0.1
	Frame.Position = UDim2.new(0.5, 0, 0.5, 0)
	Frame.Size = UDim2.new(0, 400, 0, 60)
	CreateRounded(Frame, 10)
	
	local Image = Instance.new("ImageLabel")
	Image.Name = "Icon"
	Image.Parent = Frame
	Image.BackgroundTransparency = 1
	Image.Position = UDim2.new(0, 8, 0, 8)
	Image.Size = UDim2.new(0, 45, 0, 45)
	Image.Image = "rbxassetid://13940080072"
	
	local Title = Instance.new("TextLabel")
	Title.Parent = Frame
	Title.BackgroundTransparency = 1
	Title.Position = UDim2.new(0, 55, 0, 14)
	Title.Size = UDim2.new(0, 10, 0, 20)
	Title.Font = Enum.Font.GothamBold
	Title.Text = "Vicat Hub"
	Title.TextColor3 = Color3.fromRGB(255, 255, 255)
	Title.TextSize = 16
	Title.TextXAlignment = Enum.TextXAlignment.Left
	
	local Desc = Instance.new("TextLabel")
	Desc.Parent = Frame
	Desc.BackgroundTransparency = 1
	Desc.Position = UDim2.new(0, 55, 0, 33)
	Desc.Size = UDim2.new(0, 10, 0, 10)
	Desc.Font = Enum.Font.GothamSemibold
	Desc.TextTransparency = 0.3
	Desc.Text = desc
	Desc.TextColor3 = Color3.fromRGB(200, 200, 200)
	Desc.TextSize = 12
	Desc.TextXAlignment = Enum.TextXAlignment.Left
	
	local notifData = {OutlineFrame, desc}
	table.insert(NotificationList, notifData)
	
	OutlineFrame:TweenPosition(
		UDim2.new(0.5, 0, 0.1 + (#NotificationList - 1) * 0.1, 0),
		"Out", "Quad", 0.4, true
	)
	
	-- Auto remove after 3 seconds
	delay(3, function()
		RemoveNotification(notifData)
	end)
end

-- Config System
local SettingsLib = {
	SaveSettings = true
}

getgenv().LoadConfig = function()
	if readfile and writefile and isfile and isfolder then
		if not isfolder("Vicat Hub") then
			makefolder("Vicat Hub")
		end
		if not isfolder("Vicat Hub/Library/") then
			makefolder("Vicat Hub/Library/")
		end
		local configPath = "Vicat Hub/Library/" .. game.Players.LocalPlayer.Name .. ".json"
		if not isfile(configPath) then
			writefile(configPath, game:GetService("HttpService"):JSONEncode(SettingsLib))
		else
			local Decode = game:GetService("HttpService"):JSONDecode(readfile(configPath))
			for i, v in pairs(Decode) do
				SettingsLib[i] = v
			end
		end
		print("Library Loaded!")
	else
		warn("Status : Undetected Executor")
	end
end

getgenv().SaveConfig = function()
	if readfile and writefile and isfile and isfolder then
		local configPath = "Vicat Hub/Library/" .. game.Players.LocalPlayer.Name .. ".json"
		if not isfile(configPath) then
			getgenv().LoadConfig()
		else
			writefile(configPath, game:GetService("HttpService"):JSONEncode(SettingsLib))
		end
	else
		warn("Status : Undetected Executor")
	end
end

getgenv().LoadConfig()

function Update:SaveSettings()
	return SettingsLib.SaveSettings
end

function Update:Window(Config)
	assert(Config.SubTitle, "v4")
	
	local WindowConfig = {
		Size = Config.Size,
		TabWidth = Config.TabWidth
	}
	
	local currentpage = ""
	local abc = false
	
	local VicatHub = Instance.new("ScreenGui")
	VicatHub.Name = "VicatHub"
	VicatHub.Parent = game.CoreGui
	VicatHub.DisplayOrder = 999
	
	local OutlineMain = Instance.new("Frame")
	OutlineMain.Name = "OutlineMain"
	OutlineMain.Parent = VicatHub
	OutlineMain.ClipsDescendants = true
	OutlineMain.AnchorPoint = Vector2.new(0.5, 0.5)
	OutlineMain.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	OutlineMain.BackgroundTransparency = 0.4
	OutlineMain.Position = UDim2.new(0.5, 0, 0.45, 0)
	OutlineMain.Size = UDim2.new(0, 0, 0, 0)
	CreateRounded(OutlineMain, 15)
	
	local Main = Instance.new("Frame")
	Main.Name = "Main"
	Main.Parent = OutlineMain
	Main.ClipsDescendants = true
	Main.AnchorPoint = Vector2.new(0.5, 0.5)
	Main.BackgroundColor3 = Color3.fromRGB(24, 24, 26)
	Main.Position = UDim2.new(0.5, 0, 0.5, 0)
	Main.Size = WindowConfig.Size
	CreateRounded(Main, 12)
	
	OutlineMain:TweenSize(
		UDim2.new(0, WindowConfig.Size.X.Offset + 15, 0, WindowConfig.Size.Y.Offset + 15),
		"Out", "Quad", 0.4, true
	)
	
	local Top = Instance.new("Frame")
	Top.Name = "Top"
	Top.Parent = Main
	Top.BackgroundTransparency = 1
	Top.Size = UDim2.new(1, 0, 0, 40)
	CreateRounded(Top, 5)
	
	local NameHub = Instance.new("TextLabel")
	NameHub.Name = "NameHub"
	NameHub.Parent = Top
	NameHub.BackgroundTransparency = 1
	NameHub.Position = UDim2.new(0, 15, 0.5, 0)
	NameHub.AnchorPoint = Vector2.new(0, 0.5)
	NameHub.Size = UDim2.new(0, 1, 0, 25)
	NameHub.Font = Enum.Font.GothamBold
	NameHub.Text = "Vicat Hub"
	NameHub.TextSize = 20
	NameHub.TextColor3 = Color3.fromRGB(255, 255, 255)
	NameHub.TextXAlignment = Enum.TextXAlignment.Left
	
	local nameHubSize = game:GetService("TextService"):GetTextSize(NameHub.Text, NameHub.TextSize, NameHub.Font, Vector2.new(math.huge, math.huge))
	NameHub.Size = UDim2.new(0, nameHubSize.X, 0, 25)
	
	local SubTitle = Instance.new("TextLabel")
	SubTitle.Name = "SubTitle"
	SubTitle.Parent = NameHub
	SubTitle.BackgroundTransparency = 1
	SubTitle.Position = UDim2.new(0, nameHubSize.X + 8, 0.5, 0)
	SubTitle.Size = UDim2.new(0, 1, 0, 20)
	SubTitle.Font = Enum.Font.Cartoon
	SubTitle.AnchorPoint = Vector2.new(0, 0.5)
	SubTitle.Text = Config.SubTitle
	SubTitle.TextSize = 15
	SubTitle.TextColor3 = Color3.fromRGB(150, 150, 150)
	
	local SubTitleSize = game:GetService("TextService"):GetTextSize(SubTitle.Text, SubTitle.TextSize, SubTitle.Font, Vector2.new(math.huge, math.huge))
	SubTitle.Size = UDim2.new(0, SubTitleSize.X, 0, 25)
	
	-- Close Button
	local CloseButton = Instance.new("ImageButton")
	CloseButton.Name = "CloseButton"
	CloseButton.Parent = Top
	CloseButton.BackgroundTransparency = 1
	CloseButton.AnchorPoint = Vector2.new(1, 0.5)
	CloseButton.Position = UDim2.new(1, -15, 0.5, 0)
	CloseButton.Size = UDim2.new(0, 20, 0, 20)
	CloseButton.Image = "rbxassetid://7743878857"
	CloseButton.ImageColor3 = Color3.fromRGB(245, 245, 245)
	CreateRounded(CloseButton, 3)
	
	CloseButton.MouseButton1Click:Connect(function()
		VicatHub.Enabled = not VicatHub.Enabled
	end)
	
	-- Resize Button
	local ResizeButton = Instance.new("ImageButton")
	ResizeButton.Name = "ResizeButton"
	ResizeButton.Parent = Top
	ResizeButton.BackgroundTransparency = 1
	ResizeButton.AnchorPoint = Vector2.new(1, 0.5)
	ResizeButton.Position = UDim2.new(1, -50, 0.5, 0)
	ResizeButton.Size = UDim2.new(0, 20, 0, 20)
	ResizeButton.Image = "rbxassetid://10734886735"
	ResizeButton.ImageColor3 = Color3.fromRGB(245, 245, 245)
	CreateRounded(ResizeButton, 3)
	
	-- Settings System
	local BackgroundSettings = Instance.new("Frame")
	BackgroundSettings.Name = "BackgroundSettings"
	BackgroundSettings.Parent = OutlineMain
	BackgroundSettings.ClipsDescendants = true
	BackgroundSettings.Active = true
	BackgroundSettings.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
	BackgroundSettings.BackgroundTransparency = 0.3
	BackgroundSettings.Size = UDim2.new(1, 0, 1, 0)
	BackgroundSettings.Visible = false
	CreateRounded(BackgroundSettings, 15)
	
	local SettingsFrame = Instance.new("Frame")
	SettingsFrame.Name = "SettingsFrame"
	SettingsFrame.Parent = BackgroundSettings
	SettingsFrame.ClipsDescendants = true
	SettingsFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	SettingsFrame.BackgroundColor3 = Color3.fromRGB(24, 24, 26)
	SettingsFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	SettingsFrame.Size = UDim2.new(0.7, 0, 0.7, 0)
	CreateRounded(SettingsFrame, 15)
	
	local CloseSettings = Instance.new("ImageButton")
	CloseSettings.Name = "CloseSettings"
	CloseSettings.Parent = SettingsFrame
	CloseSettings.BackgroundTransparency = 1
	CloseSettings.AnchorPoint = Vector2.new(1, 0)
	CloseSettings.Position = UDim2.new(1, -20, 0, 15)
	CloseSettings.Size = UDim2.new(0, 20, 0, 20)
	CloseSettings.Image = "rbxassetid://10747384394"
	CloseSettings.ImageColor3 = Color3.fromRGB(245, 245, 245)
	CreateRounded(CloseSettings, 3)
	
	CloseSettings.MouseButton1Click:Connect(function()
		BackgroundSettings.Visible = false
	end)
	
	local SettingsButton = Instance.new("ImageButton")
	SettingsButton.Name = "SettingsButton"
	SettingsButton.Parent = Top
	SettingsButton.BackgroundTransparency = 1
	SettingsButton.AnchorPoint = Vector2.new(1, 0.5)
	SettingsButton.Position = UDim2.new(1, -85, 0.5, 0)
	SettingsButton.Size = UDim2.new(0, 20, 0, 20)
	SettingsButton.Image = "rbxassetid://10734950020"
	SettingsButton.ImageColor3 = Color3.fromRGB(245, 245, 245)
	CreateRounded(SettingsButton, 3)
	
	SettingsButton.MouseButton1Click:Connect(function()
		BackgroundSettings.Visible = true
	end)
	
	local TitleSettings = Instance.new("TextLabel")
	TitleSettings.Name = "TitleSettings"
	TitleSettings.Parent = SettingsFrame
	TitleSettings.BackgroundTransparency = 1
	TitleSettings.Position = UDim2.new(0, 20, 0, 15)
	TitleSettings.Size = UDim2.new(1, 0, 0, 20)
	TitleSettings.Font = Enum.Font.GothamBold
	TitleSettings.Text = "Library Settings"
	TitleSettings.TextSize = 20
	TitleSettings.TextColor3 = Color3.fromRGB(245, 245, 245)
	TitleSettings.TextXAlignment = Enum.TextXAlignment.Left
	
	local SettingsMenuList = Instance.new("Frame")
	SettingsMenuList.Name = "SettingsMenuList"
	SettingsMenuList.Parent = SettingsFrame
	SettingsMenuList.ClipsDescendants = true
	SettingsMenuList.BackgroundTransparency = 1
	SettingsMenuList.Position = UDim2.new(0, 0, 0, 50)
	SettingsMenuList.Size = UDim2.new(1, 0, 1, -70)
	CreateRounded(SettingsMenuList, 15)
	
	local ScrollSettings = Instance.new("ScrollingFrame")
	ScrollSettings.Name = "ScrollSettings"
	ScrollSettings.Parent = SettingsMenuList
	ScrollSettings.Active = true
	ScrollSettings.BackgroundTransparency = 1
	ScrollSettings.Size = UDim2.new(1, 0, 1, 0)
	ScrollSettings.ScrollBarThickness = 3
	ScrollSettings.ScrollingDirection = Enum.ScrollingDirection.Y
	
	local SettingsListLayout = Instance.new("UIListLayout")
	SettingsListLayout.Parent = ScrollSettings
	SettingsListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	SettingsListLayout.Padding = UDim.new(0, 8)
	
	local PaddingScroll = Instance.new("UIPadding")
	PaddingScroll.Parent = ScrollSettings
	
	-- Settings Functions
	local function CreateCheckbox(title, state, callback)
		local checked = state or false
		
		local Background = Instance.new("Frame")
		Background.Name = "Background"
		Background.Parent = ScrollSettings
		Background.BackgroundTransparency = 1
		Background.Size = UDim2.new(1, 0, 0, 20)
		
		local Title = Instance.new("TextLabel")
		Title.Parent = Background
		Title.BackgroundTransparency = 1
		Title.Position = UDim2.new(0, 60, 0.5, 0)
		Title.Size = UDim2.new(1, -60, 0, 20)
		Title.Font = Enum.Font.Code
		Title.AnchorPoint = Vector2.new(0, 0.5)
		Title.Text = title or ""
		Title.TextSize = 15
		Title.TextColor3 = Color3.fromRGB(200, 200, 200)
		Title.TextXAlignment = Enum.TextXAlignment.Left
		
		local Checkbox = Instance.new("ImageButton")
		Checkbox.Parent = Background
		Checkbox.BackgroundColor3 = checked and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(100, 100, 100)
		Checkbox.AnchorPoint = Vector2.new(0, 0.5)
		Checkbox.Position = UDim2.new(0, 30, 0.5, 0)
		Checkbox.Size = UDim2.new(0, 20, 0, 20)
		Checkbox.Image = "rbxassetid://10709790644"
		Checkbox.ImageTransparency = checked and 0 or 1
		Checkbox.ImageColor3 = Color3.fromRGB(245, 245, 245)
		CreateRounded(Checkbox, 5)
		
		Checkbox.MouseButton1Click:Connect(function()
			checked = not checked
			Checkbox.ImageTransparency = checked and 0 or 1
			Checkbox.BackgroundColor3 = checked and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(100, 100, 100)
			pcall(callback, checked)
		end)
		
		pcall(callback, checked)
	end
	
	local function CreateButton(title, callback)
		local Background = Instance.new("Frame")
		Background.Parent = ScrollSettings
		Background.BackgroundTransparency = 1
		Background.Size = UDim2.new(1, 0, 0, 30)
		
		local Button = Instance.new("TextButton")
		Button.Parent = Background
		Button.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
		Button.Size = UDim2.new(0.8, 0, 0, 30)
		Button.Font = Enum.Font.Code
		Button.Text = title or "Button"
		Button.AnchorPoint = Vector2.new(0.5, 0)
		Button.Position = UDim2.new(0.5, 0, 0, 0)
		Button.TextColor3 = Color3.fromRGB(255, 255, 255)
		Button.TextSize = 15
		Button.AutoButtonColor = false
		CreateRounded(Button, 5)
		
		Button.MouseButton1Click:Connect(callback)
	end
	
	CreateCheckbox("Save Settings", SettingsLib.SaveSettings, function(state)
		SettingsLib.SaveSettings = state
		getgenv().SaveConfig()
	end)
	
	CreateButton("Reset Config", function()
		if isfolder("VicatHub") then
			delfolder("VicatHub")
		end
		Update:Notify("Config has been reset!")
	end)
	
	-- Tab System
	local Tab = Instance.new("Frame")
	Tab.Name = "Tab"
	Tab.Parent = Main
	Tab.BackgroundTransparency = 1
	Tab.Position = UDim2.new(0, 8, 0, Top.Size.Y.Offset)
	Tab.Size = UDim2.new(0, WindowConfig.TabWidth, Config.Size.Y.Scale, Config.Size.Y.Offset - Top.Size.Y.Offset - 8)
	CreateRounded(Tab, 5)
	
	local ScrollTab = Instance.new("ScrollingFrame")
	ScrollTab.Name = "ScrollTab"
	ScrollTab.Parent = Tab
	ScrollTab.Active = true
	ScrollTab.BackgroundTransparency = 1
	ScrollTab.Size = UDim2.new(1, 0, 1, 0)
	ScrollTab.ScrollBarThickness = 0
	ScrollTab.ScrollingDirection = Enum.ScrollingDirection.Y
	
	local TabListLayout = Instance.new("UIListLayout")
	TabListLayout.Parent = ScrollTab
	TabListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	TabListLayout.Padding = UDim.new(0, 2)
	
	local PPD = Instance.new("UIPadding")
	PPD.Parent = ScrollTab
	
	local Page = Instance.new("Frame")
	Page.Name = "Page"
	Page.Parent = Main
	Page.BackgroundTransparency = 1
	Page.Position = UDim2.new(0, Tab.Size.X.Offset + 18, 0, Top.Size.Y.Offset)
	Page.Size = UDim2.new(Config.Size.X.Scale, Config.Size.X.Offset - Tab.Size.X.Offset - 25, Config.Size.Y.Scale, Config.Size.Y.Offset - Top.Size.Y.Offset - 8)
	CreateRounded(Page, 3)
	
	local MainPage = Instance.new("Frame")
	MainPage.Name = "MainPage"
	MainPage.Parent = Page
	MainPage.ClipsDescendants = true
	MainPage.BackgroundTransparency = 1
	MainPage.Size = UDim2.new(1, 0, 1, 0)
	
	local PageList = Instance.new("Folder")
	PageList.Name = "PageList"
	PageList.Parent = MainPage
	
	local UIPageLayout = Instance.new("UIPageLayout")
	UIPageLayout.Parent = PageList
	UIPageLayout.SortOrder = Enum.SortOrder.LayoutOrder
	UIPageLayout.EasingDirection = Enum.EasingDirection.InOut
	UIPageLayout.EasingStyle = Enum.EasingStyle.Quad
	UIPageLayout.TweenTime = 0
	UIPageLayout.GamepadInputEnabled = false
	UIPageLayout.ScrollWheelInputEnabled = false
	UIPageLayout.TouchInputEnabled = false
	
	MakeDraggable(Top, OutlineMain)
	
	-- Toggle UI with Insert key
	UserInputService.InputBegan:Connect(function(input)
		if input.KeyCode == Enum.KeyCode.Insert then
			VicatHub.Enabled = not VicatHub.Enabled
		end
	end)
	
	-- Resize functionality
	local Dragging = false
	local DragButton = Instance.new("Frame")
	DragButton.Name = "DragButton"
	DragButton.Parent = Main
	DragButton.Position = UDim2.new(1, 5, 1, 5)
	DragButton.AnchorPoint = Vector2.new(1, 1)
	DragButton.Size = UDim2.new(0, 15, 0, 15)
	DragButton.BackgroundTransparency = 1
	DragButton.ZIndex = 10
	CreateRounded(DragButton, 99)
	
	DragButton.InputBegan:Connect(function(Input)
		if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
			Dragging = true
		end
	end)
	
	UserInputService.InputEnded:Connect(function(Input)
		if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
			Dragging = false
		end
	end)
	
	UserInputService.InputChanged:Connect(function(Input)
		if Dragging and (Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch) then
			OutlineMain.Size = UDim2.new(0, math.clamp(Input.Position.X - Main.AbsolutePosition.X + 15, WindowConfig.Size.X.Offset + 15, math.huge), 0, math.clamp(Input.Position.Y - Main.AbsolutePosition.Y + 15, WindowConfig.Size.Y.Offset + 15, math.huge))
			Main.Size = UDim2.new(0, math.clamp(Input.Position.X - Main.AbsolutePosition.X, WindowConfig.Size.X.Offset, math.huge), 0, math.clamp(Input.Position.Y - Main.AbsolutePosition.Y, WindowConfig.Size.Y.Offset, math.huge))
			Page.Size = UDim2.new(0, math.clamp(Input.Position.X - Page.AbsolutePosition.X - 8, WindowConfig.Size.X.Offset - Tab.Size.X.Offset - 25, math.huge), 0, math.clamp(Input.Position.Y - Page.AbsolutePosition.Y - 8, WindowConfig.Size.Y.Offset - Top.Size.Y.Offset - 10, math.huge))
			Tab.Size = UDim2.new(0, WindowConfig.TabWidth, 0, math.clamp(Input.Position.Y - Tab.AbsolutePosition.Y - 8, WindowConfig.Size.Y.Offset - Top.Size.Y.Offset - 10, math.huge))
		end
	end)
	
	-- Fullscreen toggle
	local defaultSize = true
	ResizeButton.MouseButton1Click:Connect(function()
		if defaultSize then
			defaultSize = false
			OutlineMain:TweenPosition(UDim2.new(0.5, 0, 0.45, 0), "Out", "Quad", 0.2, true)
			Main:TweenSize(UDim2.new(1, 0, 1, 0), "Out", "Quad", 0.4, true, function()
				Page:TweenSize(UDim2.new(0, Main.AbsoluteSize.X - Tab.AbsoluteSize.X - 25, 0, Main.AbsoluteSize.Y - Top.AbsoluteSize.Y - 10), "Out", "Quad", 0.4, true)
				Tab:TweenSize(UDim2.new(0, WindowConfig.TabWidth, 0, Main.AbsoluteSize.Y - Top.AbsoluteSize.Y - 10), "Out", "Quad", 0.4, true)
			end)
			OutlineMain:TweenSize(UDim2.new(1, -10, 1, -10), "Out", "Quad", 0.4, true)
			ResizeButton.Image = "rbxassetid://10734895698"
		else
			defaultSize = true
			Main:TweenSize(UDim2.new(0, WindowConfig.Size.X.Offset, 0, WindowConfig.Size.Y.Offset), "Out", "Quad", 0.4, true, function()
				Page:TweenSize(UDim2.new(0, Main.AbsoluteSize.X - Tab.AbsoluteSize.X - 25, 0, Main.AbsoluteSize.Y - Top.AbsoluteSize.Y - 10), "Out", "Quad", 0.4, true)
				Tab:TweenSize(UDim2.new(0, WindowConfig.TabWidth, 0, Main.AbsoluteSize.Y - Top.AbsoluteSize.Y - 10), "Out", "Quad", 0.4, true)
			end)
			OutlineMain:TweenSize(UDim2.new(0, WindowConfig.Size.X.Offset + 15, 0, WindowConfig.Size.Y.Offset + 15), "Out", "Quad", 0.4, true)
			ResizeButton.Image = "rbxassetid://10734886735"
		end
	end)
	
	-- Canvas size update
	game:GetService("RunService").Stepped:Connect(function()
		pcall(function()
			ScrollTab.CanvasSize = UDim2.new(0, 0, 0, TabListLayout.AbsoluteContentSize.Y)
			ScrollSettings.CanvasSize = UDim2.new(0, 0, 0, SettingsListLayout.AbsoluteContentSize.Y)
		end)
	end)
	
	local uitab = {}
	
	function uitab:Tab(text, img)
		local TabButton = Instance.new("TextButton")
		TabButton.Parent = ScrollTab
		TabButton.Name = text .. "Unique"
		TabButton.Text = ""
		TabButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
		TabButton.BackgroundTransparency = 1
		TabButton.Size = UDim2.new(1, 0, 0, 35)
		TabButton.Font = Enum.Font.Nunito
		TabButton.TextColor3 = Color3.fromRGB(255, 255, 255)
		TabButton.TextSize = 12
		CreateRounded(TabButton, 6)
		
		local SelectedTab = Instance.new("Frame")
		SelectedTab.Name = "SelectedTab"
		SelectedTab.Parent = TabButton
		SelectedTab.BackgroundColor3 = _G.Third
		SelectedTab.Size = UDim2.new(0, 3, 0, 0)
		SelectedTab.Position = UDim2.new(0, 0, 0.5, 0)
		SelectedTab.AnchorPoint = Vector2.new(0, 0.5)
		CreateRounded(SelectedTab, 100)
		
		local Title = Instance.new("TextLabel")
		Title.Name = "Title"
		Title.Parent = TabButton
		Title.BackgroundTransparency = 1
		Title.Position = UDim2.new(0, 30, 0.5, 0)
		Title.Size = UDim2.new(0, 100, 0, 30)
		Title.Font = Enum.Font.Roboto
		Title.Text = text
		Title.AnchorPoint = Vector2.new(0, 0.5)
		Title.TextColor3 = Color3.fromRGB(255, 255, 255)
		Title.TextTransparency = 0.4
		Title.TextSize = 14
		Title.TextXAlignment = Enum.TextXAlignment.Left
		
		local IDK = Instance.new("ImageLabel")
		IDK.Name = "IDK"
		IDK.Parent = TabButton
		IDK.BackgroundTransparency = 1
		IDK.ImageTransparency = 0.3
		IDK.Position = UDim2.new(0, 7, 0.5, 0)
		IDK.Size = UDim2.new(0, 15, 0, 15)
		IDK.AnchorPoint = Vector2.new(0, 0.5)
		IDK.Image = img
		
		local MainFramePage = Instance.new("ScrollingFrame")
		MainFramePage.Name = text .. "_Page"
		MainFramePage.Parent = PageList
		MainFramePage.Active = true
		MainFramePage.BackgroundTransparency = 1
		MainFramePage.Size = UDim2.new(1, 0, 1, 0)
		MainFramePage.ScrollBarThickness = 0
		MainFramePage.ScrollingDirection = Enum.ScrollingDirection.Y
		
		local UIListLayout = Instance.new("UIListLayout")
		UIListLayout.Padding = UDim.new(0, 3)
		UIListLayout.Parent = MainFramePage
		UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
		
		local UIPadding = Instance.new("UIPadding")
		UIPadding.Parent = MainFramePage
		
		TabButton.MouseButton1Click:Connect(function()
			for i, v in next, ScrollTab:GetChildren() do
				if v:IsA("TextButton") then
					TweenService:Create(v, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 1}):Play()
					TweenService:Create(v.SelectedTab, TweenInfo.new(0, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(0, 3, 0, 0)}):Play()
					TweenService:Create(v.IDK, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {ImageTransparency = 0.4}):Play()
					TweenService:Create(v.Title, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 0.4}):Play()
				end
			end
			
			TweenService:Create(TabButton, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0.8}):Play()
			TweenService:Create(SelectedTab, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(0, 3, 0, 15)}):Play()
			TweenService:Create(IDK, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {ImageTransparency = 0}):Play()
			TweenService:Create(Title, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 0}):Play()
			
			currentpage = string.gsub(TabButton.Name, "Unique", "") .. "_Page"
			for i, v in next, PageList:GetChildren() do
				if v.Name == currentpage then
					UIPageLayout:JumpTo(v)
				end
			end
		end)
		
		if abc == false then
			for i, v in next, ScrollTab:GetChildren() do
				if v:IsA("TextButton") then
					TweenService:Create(v, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 1}):Play()
					TweenService:Create(v.SelectedTab, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(0, 3, 0, 15)}):Play()
					TweenService:Create(v.IDK, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {ImageTransparency = 0.4}):Play()
					TweenService:Create(v.Title, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 0.4}):Play()
				end
			end
			
			TweenService:Create(TabButton, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0.8}):Play()
			TweenService:Create(SelectedTab, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(0, 3, 0, 15)}):Play()
			TweenService:Create(IDK, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {ImageTransparency = 0}):Play()
			TweenService:Create(Title, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 0}):Play()
			
			UIPageLayout:JumpToIndex(1)
			abc = true
		end
		
		game:GetService("RunService").Stepped:Connect(function()
			pcall(function()
				MainFramePage.CanvasSize = UDim2.new(0, 0, 0, UIListLayout.AbsoluteContentSize.Y)
			end)
		end)
		
		local main = {}
		
		function main:Button(text, callback)
			local Button = Instance.new("Frame")
			Button.Name = "Button"
			Button.Parent = MainFramePage
			Button.BackgroundTransparency = 1
			Button.Size = UDim2.new(1, 0, 0, 36)
			CreateRounded(Button, 5)
			
			local TextLabel = Instance.new("TextLabel")
			TextLabel.Parent = Button
			TextLabel.BackgroundTransparency = 1
			TextLabel.AnchorPoint = Vector2.new(0, 0.5)
			TextLabel.Position = UDim2.new(0, 20, 0.5, 0)
			TextLabel.Size = UDim2.new(1, -50, 1, 0)
			TextLabel.Font = Enum.Font.Cartoon
			TextLabel.RichText = true
			TextLabel.Text = text
			TextLabel.TextXAlignment = Enum.TextXAlignment.Left
			TextLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
			TextLabel.TextSize = 15
			TextLabel.ClipsDescendants = true
			
			local TextButton = Instance.new("TextButton")
			TextButton.Parent = Button
			TextButton.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
			TextButton.BackgroundTransparency = 0.8
			TextButton.AnchorPoint = Vector2.new(1, 0.5)
			TextButton.Position = UDim2.new(1, -1, 0.5, 0)
			TextButton.Size = UDim2.new(0, 25, 0, 25)
			TextButton.Font = Enum.Font.Nunito
			TextButton.Text = ""
			TextButton.TextColor3 = Color3.fromRGB(255, 255, 255)
			TextButton.TextSize = 15
			CreateRounded(TextButton, 4)
			
			local ImageLabel = Instance.new("ImageLabel")
			ImageLabel.Parent = TextButton
			ImageLabel.BackgroundTransparency = 1
			ImageLabel.AnchorPoint = Vector2.new(0.5, 0.5)
			ImageLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
			ImageLabel.Size = UDim2.new(0, 15, 0, 15)
			ImageLabel.Image = "rbxassetid://10734898355"
			ImageLabel.ImageColor3 = Color3.fromRGB(255, 255, 255)
			
			local ArrowRight = Instance.new("ImageLabel")
			ArrowRight.Parent = Button
			ArrowRight.BackgroundTransparency = 1
			ArrowRight.AnchorPoint = Vector2.new(0, 0.5)
			ArrowRight.Position = UDim2.new(0, 0, 0.5, 0)
			ArrowRight.Size = UDim2.new(0, 15, 0, 15)
			ArrowRight.Image = "rbxassetid://10709768347"
			ArrowRight.ImageColor3 = Color3.fromRGB(255, 255, 255)
			
			TextButton.MouseButton1Click:Connect(callback)
		end
		
		function main:Toggle(text, config, desc, callback)
			config = config or false
			local toggled = config
			
			local Button = Instance.new("TextButton")
			Button.Name = "Button"
			Button.Parent = MainFramePage
			Button.BackgroundColor3 = _G.Primary
			Button.BackgroundTransparency = 0.8
			Button.AutoButtonColor = false
			Button.Font = Enum.Font.SourceSans
			Button.Text = ""
			Button.TextSize = 11
			CreateRounded(Button, 5)
			
			local Title2 = Instance.new("TextLabel")
			Title2.Parent = Button
			Title2.BackgroundTransparency = 1
			Title2.Size = UDim2.new(1, 0, 0, 35)
			Title2.Font = Enum.Font.Cartoon
			Title2.Text = text
			Title2.TextColor3 = Color3.fromRGB(255, 255, 255)
			Title2.TextSize = 15
			Title2.TextXAlignment = Enum.TextXAlignment.Left
			
			local Desc = Instance.new("TextLabel")
			Desc.Parent = Title2
			Desc.BackgroundTransparency = 1
			Desc.Position = UDim2.new(0, 0, 0, 22)
			Desc.Size = UDim2.new(0, 280, 0, 16)
			Desc.Font = Enum.Font.Gotham
			Desc.Text = desc or ""
			Desc.TextColor3 = Color3.fromRGB(150, 150, 150)
			Desc.TextSize = 10
			Desc.TextXAlignment = Enum.TextXAlignment.Left
			
			if desc then
				Title2.Position = UDim2.new(0, 15, 0.5, -5)
				Button.Size = UDim2.new(1, 0, 0, 46)
			else
				Title2.Position = UDim2.new(0, 15, 0.5, 0)
				Desc.Visible = false
				Button.Size = UDim2.new(1, 0, 0, 36)
			end
			
			local ToggleFrame = Instance.new("Frame")
			ToggleFrame.Name = "ToggleFrame"
			ToggleFrame.Parent = Button
			ToggleFrame.BackgroundTransparency = 1
			ToggleFrame.Position = UDim2.new(1, -10, 0.5, 0)
			ToggleFrame.Size = UDim2.new(0, 35, 0, 20)
			ToggleFrame.AnchorPoint = Vector2.new(1, 0.5)
			CreateRounded(ToggleFrame, 10)
			
			local ToggleImage = Instance.new("TextButton")
			ToggleImage.Name = "ToggleImage"
			ToggleImage.Parent = ToggleFrame
			ToggleImage.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
			ToggleImage.BackgroundTransparency = 0.8
			ToggleImage.Size = UDim2.new(1, 0, 1, 0)
			ToggleImage.Text = ""
			ToggleImage.AutoButtonColor = false
			CreateRounded(ToggleImage, 10)
			
			local Circle = Instance.new("Frame")
			Circle.Name = "Circle"
			Circle.Parent = ToggleImage
			Circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			Circle.Position = UDim2.new(0, 3, 0.5, 0)
			Circle.Size = UDim2.new(0, 14, 0, 14)
			Circle.AnchorPoint = Vector2.new(0, 0.5)
			CreateRounded(Circle, 10)
			
			ToggleImage.MouseButton1Click:Connect(function()
				toggled = not toggled
				if toggled then
					Circle:TweenPosition(UDim2.new(0, 17, 0.5, 0), "Out", "Sine", 0.2, true)
					TweenService:Create(ToggleImage, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
						BackgroundColor3 = _G.Third,
						BackgroundTransparency = 0
					}):Play()
				else
					Circle:TweenPosition(UDim2.new(0, 4, 0.5, 0), "Out", "Sine", 0.2, true)
					TweenService:Create(ToggleImage, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
						BackgroundColor3 = Color3.fromRGB(200, 200, 200),
						BackgroundTransparency = 0.8
					}):Play()
				end
				pcall(callback, toggled)
			end)
			
			if config == true then
				toggled = true
				Circle:TweenPosition(UDim2.new(0, 17, 0.5, 0), "Out", "Sine", 0.4, true)
				TweenService:Create(ToggleImage, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					BackgroundColor3 = _G.Third,
					BackgroundTransparency = 0
				}):Play()
				pcall(callback, toggled)
			end
		end
		
		function main:Dropdown(text, option, var, callback)
			local isdropping = false
			local activeItem = var
			
			local Dropdown = Instance.new("Frame")
			Dropdown.Name = "Dropdown"
			Dropdown.Parent = MainFramePage
			Dropdown.BackgroundColor3 = _G.Primary
			Dropdown.BackgroundTransparency = 0.8
			Dropdown.ClipsDescendants = false
			Dropdown.Size = UDim2.new(1, 0, 0, 40)
			CreateRounded(Dropdown, 5)
			
			local DropTitle = Instance.new("TextLabel")
			DropTitle.Parent = Dropdown
			DropTitle.BackgroundTransparency = 1
			DropTitle.Size = UDim2.new(1, 0, 0, 30)
			DropTitle.Font = Enum.Font.Cartoon
			DropTitle.Text = text
			DropTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
			DropTitle.TextSize = 15
			DropTitle.TextXAlignment = Enum.TextXAlignment.Left
			DropTitle.Position = UDim2.new(0, 15, 0, 5)
			
			local SelectItems = Instance.new("TextButton")
			SelectItems.Name = "SelectItems"
			SelectItems.Parent = Dropdown
			SelectItems.BackgroundColor3 = Color3.fromRGB(24, 24, 26)
			SelectItems.TextColor3 = Color3.fromRGB(255, 255, 255)
			SelectItems.Position = UDim2.new(1, -5, 0, 5)
			SelectItems.Size = UDim2.new(0, 100, 0, 30)
			SelectItems.AnchorPoint = Vector2.new(1, 0)
			SelectItems.Font = Enum.Font.GothamMedium
			SelectItems.AutoButtonColor = false
			SelectItems.TextSize = 9
			SelectItems.ClipsDescendants = true
			SelectItems.Text = "   Select Items"
			SelectItems.TextXAlignment = Enum.TextXAlignment.Left
			CreateRounded(SelectItems, 5)
			
			local ArrowDown = Instance.new("ImageLabel")
			ArrowDown.Parent = Dropdown
			ArrowDown.BackgroundTransparency = 1
			ArrowDown.AnchorPoint = Vector2.new(1, 0)
			ArrowDown.Position = UDim2.new(1, -110, 0, 10)
			ArrowDown.Size = UDim2.new(0, 20, 0, 20)
			ArrowDown.Image = "rbxassetid://10709790948"
			ArrowDown.ImageColor3 = Color3.fromRGB(255, 255, 255)
			
			local DropdownFrameScroll = Instance.new("Frame")
			DropdownFrameScroll.Name = "DropdownFrameScroll"
			DropdownFrameScroll.Parent = Dropdown
			DropdownFrameScroll.BackgroundColor3 = Color3.fromRGB(24, 24, 26)
			DropdownFrameScroll.ClipsDescendants = true
			DropdownFrameScroll.Size = UDim2.new(1, 0, 0, 100)
			DropdownFrameScroll.Position = UDim2.new(0, 5, 0, 40)
			DropdownFrameScroll.Visible = false
			CreateRounded(DropdownFrameScroll, 5)
			
			local DropScroll = Instance.new("ScrollingFrame")
			DropScroll.Name = "DropScroll"
			DropScroll.Parent = DropdownFrameScroll
			DropScroll.ScrollingDirection = Enum.ScrollingDirection.Y
			DropScroll.Active = true
			DropScroll.BackgroundTransparency = 1
			DropScroll.BorderSizePixel = 0
			DropScroll.Position = UDim2.new(0, 0, 0, 10)
			DropScroll.Size = UDim2.new(1, 0, 0, 80)
			DropScroll.ClipsDescendants = true
			DropScroll.ScrollBarThickness = 3
			DropScroll.ZIndex = 3
			
			local UIListLayout = Instance.new("UIListLayout")
			UIListLayout.Parent = DropScroll
			UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
			UIListLayout.Padding = UDim.new(0, 1)
			
			local PaddingDrop = Instance.new("UIPadding")
			PaddingDrop.PaddingLeft = UDim.new(0, 10)
			PaddingDrop.PaddingRight = UDim.new(0, 10)
			PaddingDrop.Parent = DropScroll
			
			for i, v in next, option do
				local Item = Instance.new("TextButton")
				Item.Name = "Item"
				Item.Parent = DropScroll
				Item.BackgroundColor3 = _G.Primary
				Item.BackgroundTransparency = 1
				Item.Size = UDim2.new(1, 0, 0, 30)
				Item.Font = Enum.Font.Nunito
				Item.Text = tostring(v)
				Item.TextColor3 = Color3.fromRGB(255, 255, 255)
				Item.TextSize = 13
				Item.TextTransparency = 0.5
				Item.TextXAlignment = Enum.TextXAlignment.Left
				Item.ZIndex = 4
				CreateRounded(Item, 5)
				
				local ItemPadding = Instance.new("UIPadding")
				ItemPadding.Parent = Item
				ItemPadding.PaddingLeft = UDim.new(0, 8)
				
				local SelectedItems = Instance.new("Frame")
				SelectedItems.Name = "SelectedItems"
				SelectedItems.Parent = Item
				SelectedItems.BackgroundColor3 = _G.Third
				SelectedItems.BackgroundTransparency = 1
				SelectedItems.Size = UDim2.new(0, 3, 0.4, 0)
				SelectedItems.Position = UDim2.new(0, -8, 0.5, 0)
				SelectedItems.AnchorPoint = Vector2.new(0, 0.5)
				SelectedItems.ZIndex = 4
				CreateRounded(SelectedItems, 999)
				
				if var and tostring(v) == tostring(var) then
					Item.BackgroundTransparency = 0.8
					Item.TextTransparency = 0
					SelectedItems.BackgroundTransparency = 0
					SelectItems.Text = "   " .. var
					pcall(callback, var)
				end
				
				Item.MouseButton1Click:Connect(function()
					callback(Item.Text)
					activeItem = Item.Text
					SelectItems.Text = "   " .. Item.Text
					
					for i, v in next, DropScroll:GetChildren() do
						if v:IsA("TextButton") then
							local SelectedItems = v:FindFirstChild("SelectedItems")
							if v.Text == activeItem then
								v.BackgroundTransparency = 0.8
								v.TextTransparency = 0
								if SelectedItems then
									SelectedItems.BackgroundTransparency = 0
								end
							else
								v.BackgroundTransparency = 1
								v.TextTransparency = 0.5
								if SelectedItems then
									SelectedItems.BackgroundTransparency = 1
								end
							end
						end
					end
				end)
			end
			
			DropScroll.CanvasSize = UDim2.new(0, 0, 0, UIListLayout.AbsoluteContentSize.Y)
			
			SelectItems.MouseButton1Click:Connect(function()
				isdropping = not isdropping
				if isdropping then
					TweenService:Create(DropdownFrameScroll, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
						Size = UDim2.new(1, -10, 0, 100),
						Visible = true
					}):Play()
					TweenService:Create(Dropdown, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
						Size = UDim2.new(1, 0, 0, 145)
					}):Play()
					TweenService:Create(ArrowDown, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
						Rotation = 180
					}):Play()
				else
					TweenService:Create(DropdownFrameScroll, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
						Size = UDim2.new(1, -10, 0, 0),
						Visible = false
					}):Play()
					TweenService:Create(Dropdown, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
						Size = UDim2.new(1, 0, 0, 40)
					}):Play()
					TweenService:Create(ArrowDown, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
						Rotation = 0
					}):Play()
				end
			end)
			
			local dropfunc = {}
			
			function dropfunc:Add(t)
				local Item = Instance.new("TextButton")
				Item.Name = "Item"
				Item.Parent = DropScroll
				Item.BackgroundColor3 = _G.Primary
				Item.BackgroundTransparency = 1
				Item.Size = UDim2.new(1, 0, 0, 30)
				Item.Font = Enum.Font.Nunito
				Item.Text = tostring(t)
				Item.TextColor3 = Color3.fromRGB(255, 255, 255)
				Item.TextSize = 13
				Item.TextTransparency = 0.5
				Item.TextXAlignment = Enum.TextXAlignment.Left
				Item.ZIndex = 4
				CreateRounded(Item, 5)
				
				local ItemPadding = Instance.new("UIPadding")
				ItemPadding.Parent = Item
				ItemPadding.PaddingLeft = UDim.new(0, 8)
				
				local SelectedItems = Instance.new("Frame")
				SelectedItems.Name = "SelectedItems"
				SelectedItems.Parent = Item
				SelectedItems.BackgroundColor3 = _G.Third
				SelectedItems.BackgroundTransparency = 1
				SelectedItems.Size = UDim2.new(0, 3, 0.4, 0)
				SelectedItems.Position = UDim2.new(0, -8, 0.5, 0)
				SelectedItems.AnchorPoint = Vector2.new(0, 0.5)
				SelectedItems.ZIndex = 4
				CreateRounded(SelectedItems, 999)
				
				Item.MouseButton1Click:Connect(function()
					callback(Item.Text)
					activeItem = Item.Text
					SelectItems.Text = "   " .. Item.Text
					
					for i, v in next, DropScroll:GetChildren() do
						if v:IsA("TextButton") then
							local SelectedItems = v:FindFirstChild("SelectedItems")
							if v.Text == activeItem then
								v.BackgroundTransparency = 0.8
								v.TextTransparency = 0
								if SelectedItems then
									SelectedItems.BackgroundTransparency = 0
								end
							else
								v.BackgroundTransparency = 1
								v.TextTransparency = 0.5
								if SelectedItems then
									SelectedItems.BackgroundTransparency = 1
								end
							end
						end
					end
				end)
			end
			
			function dropfunc:Clear()
				SelectItems.Text = "   Select Items"
				isdropping = false
				DropdownFrameScroll.Visible = false
				for i, v in next, DropScroll:GetChildren() do
					if v:IsA("TextButton") then
						v:Destroy()
					end
				end
			end
			
			return dropfunc
		end
		
		function main:Slider(text, min, max, set, callback)
			local Value = set
			
			local Slider = Instance.new("Frame")
			Slider.Name = "Slider"
			Slider.Parent = MainFramePage
			Slider.BackgroundTransparency = 1
			Slider.Size = UDim2.new(1, 0, 0, 35)
			CreateRounded(Slider, 5)
			
			local sliderr = Instance.new("Frame")
			sliderr.Name = "sliderr"
			sliderr.Parent = Slider
			sliderr.BackgroundColor3 = _G.Primary
			sliderr.BackgroundTransparency = 0.8
			sliderr.Size = UDim2.new(1, 0, 0, 35)
			CreateRounded(sliderr, 5)
			
			local Title = Instance.new("TextLabel")
			Title.Parent = sliderr
			Title.BackgroundTransparency = 1
			Title.Position = UDim2.new(0, 15, 0.5, 0)
			Title.Size = UDim2.new(1, 0, 0, 30)
			Title.Font = Enum.Font.Cartoon
			Title.Text = text
			Title.AnchorPoint = Vector2.new(0, 0.5)
			Title.TextColor3 = Color3.fromRGB(255, 255, 255)
			Title.TextSize = 15
			Title.TextXAlignment = Enum.TextXAlignment.Left
			
			local bar = Instance.new("Frame")
			bar.Name = "bar"
			bar.Parent = sliderr
			bar.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
			bar.Size = UDim2.new(0, 100, 0, 4)
			bar.Position = UDim2.new(1, -10, 0.5, 0)
			bar.BackgroundTransparency = 0.8
			bar.AnchorPoint = Vector2.new(1, 0.5)
			CreateRounded(bar, 5)
			
			local ValueText = Instance.new("TextLabel")
			ValueText.Parent = bar
			ValueText.BackgroundTransparency = 1
			ValueText.Position = UDim2.new(0, -38, 0.5, 0)
			ValueText.Size = UDim2.new(0, 30, 0, 30)
			ValueText.Font = Enum.Font.GothamMedium
			ValueText.Text = set
			ValueText.AnchorPoint = Vector2.new(0, 0.5)
			ValueText.TextColor3 = Color3.fromRGB(255, 255, 255)
			ValueText.TextSize = 12
			ValueText.TextXAlignment = Enum.TextXAlignment.Right
			
			local bar1 = Instance.new("Frame")
			bar1.Name = "bar1"
			bar1.Parent = bar
			bar1.BackgroundColor3 = _G.Third
			bar1.Size = UDim2.new(set / max, 0, 0, 4)
			CreateRounded(bar1, 5)
			
			local circlebar = Instance.new("Frame")
			circlebar.Name = "circlebar"
			circlebar.Parent = bar1
			circlebar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			circlebar.Position = UDim2.new(1, 0, 0, -5)
			circlebar.AnchorPoint = Vector2.new(0.5, 0)
			circlebar.Size = UDim2.new(0, 13, 0, 13)
			CreateRounded(circlebar, 100)
			
			local Dragging = false
			
			circlebar.InputBegan:Connect(function(Input)
				if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
					Dragging = true
				end
			end)
			
			bar.InputBegan:Connect(function(Input)
				if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
					Dragging = true
				end
			end)
			
			UserInputService.InputEnded:Connect(function(Input)
				if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
					Dragging = false
				end
			end)
			
			UserInputService.InputChanged:Connect(function(Input)
				if Dragging and (Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch) then
					Value = math.floor((tonumber(max) - tonumber(min)) / 100 * bar1.AbsoluteSize.X + tonumber(min)) or 0
					pcall(function()
						callback(Value)
					end)
					ValueText.Text = Value
					bar1.Size = UDim2.new(0, math.clamp(Input.Position.X - bar1.AbsolutePosition.X, 0, 100), 0, 4)
					circlebar.Position = UDim2.new(0, math.clamp(Input.Position.X - bar1.AbsolutePosition.X - 5, 0, 100), 0, -5)
				end
			end)
		end
		
		function main:Textbox(text, disappear, callback)
			local Textbox = Instance.new("Frame")
			Textbox.Name = "Textbox"
			Textbox.Parent = MainFramePage
			Textbox.BackgroundColor3 = _G.Primary
			Textbox.BackgroundTransparency = 0.8
			Textbox.Size = UDim2.new(1, 0, 0, 35)
			CreateRounded(Textbox, 5)
			
			local TextboxLabel = Instance.new("TextLabel")
			TextboxLabel.Name = "TextboxLabel"
			TextboxLabel.Parent = Textbox
			TextboxLabel.BackgroundTransparency = 1
			TextboxLabel.Position = UDim2.new(0, 15, 0.5, 0)
			TextboxLabel.Text = text
			TextboxLabel.Size = UDim2.new(1, 0, 0, 35)
			TextboxLabel.Font = Enum.Font.Nunito
			TextboxLabel.AnchorPoint = Vector2.new(0, 0.5)
			TextboxLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
			TextboxLabel.TextSize = 15
			TextboxLabel.TextXAlignment = Enum.TextXAlignment.Left
			
			local RealTextbox = Instance.new("TextBox")
			RealTextbox.Name = "RealTextbox"
			RealTextbox.Parent = Textbox
			RealTextbox.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
			RealTextbox.BackgroundTransparency = 0.8
			RealTextbox.Position = UDim2.new(1, -5, 0.5, 0)
			RealTextbox.AnchorPoint = Vector2.new(1, 0.5)
			RealTextbox.Size = UDim2.new(0, 80, 0, 25)
			RealTextbox.Font = Enum.Font.Gotham
			RealTextbox.Text = ""
			RealTextbox.TextColor3 = Color3.fromRGB(225, 225, 225)
			RealTextbox.TextSize = 11
			RealTextbox.ClipsDescendants = true
			CreateRounded(RealTextbox, 5)
			
			RealTextbox.FocusLost:Connect(function()
				callback(RealTextbox.Text)
			end)
		end
		
		function main:Label(text)
			local Frame = Instance.new("Frame")
			Frame.Name = "Frame"
			Frame.Parent = MainFramePage
			Frame.BackgroundTransparency = 1
			Frame.Size = UDim2.new(1, 0, 0, 30)
			
			local Label = Instance.new("TextLabel")
			Label.Name = "Label"
			Label.Parent = Frame
			Label.BackgroundTransparency = 1
			Label.Size = UDim2.new(1, -30, 0, 30)
			Label.Font = Enum.Font.Nunito
			Label.Position = UDim2.new(0, 30, 0.5, 0)
			Label.AnchorPoint = Vector2.new(0, 0.5)
			Label.TextColor3 = Color3.fromRGB(225, 225, 225)
			Label.TextSize = 15
			Label.Text = text
			Label.TextXAlignment = Enum.TextXAlignment.Left
			
			local ImageLabel = Instance.new("ImageLabel")
			ImageLabel.Name = "ImageLabel"
			ImageLabel.Parent = Frame
			ImageLabel.BackgroundTransparency = 1
			ImageLabel.ImageTransparency = 0.3
			ImageLabel.Position = UDim2.new(0, 10, 0.5, 0)
			ImageLabel.Size = UDim2.new(0, 14, 0, 14)
			ImageLabel.AnchorPoint = Vector2.new(0, 0.5)
			ImageLabel.Image = "rbxassetid://10723415903"
			ImageLabel.ImageColor3 = Color3.fromRGB(200, 200, 200)
			
			local labelfunc = {}
			
			function labelfunc:Set(newtext)
				Label.Text = newtext
			end
			
			return labelfunc
		end
		
		function main:Seperator(text)
			local Seperator = Instance.new("Frame")
			Seperator.Name = "Seperator"
			Seperator.Parent = MainFramePage
			Seperator.BackgroundTransparency = 1
			Seperator.Size = UDim2.new(1, 0, 0, 36)
			
			local Sep1 = Instance.new("TextLabel")
			Sep1.Name = "Sep1"
			Sep1.Parent = Seperator
			Sep1.BackgroundTransparency = 1
			Sep1.AnchorPoint = Vector2.new(0, 0.5)
			Sep1.Position = UDim2.new(0, 0, 0.5, 0)
			Sep1.Size = UDim2.new(0, 20, 0, 36)
			Sep1.Font = Enum.Font.GothamBold
			Sep1.RichText = true
			Sep1.Text = "《<font color=\"rgb(255, 0, 0)\">《</font>"
			Sep1.TextColor3 = Color3.fromRGB(255, 255, 255)
			Sep1.TextSize = 14
			
			local Sep2 = Instance.new("TextLabel")
			Sep2.Name = "Sep2"
			Sep2.Parent = Seperator
			Sep2.BackgroundTransparency = 1
			Sep2.AnchorPoint = Vector2.new(0.5, 0.5)
			Sep2.Position = UDim2.new(0.5, 0, 0.5, 0)
			Sep2.Size = UDim2.new(1, 0, 0, 36)
			Sep2.Font = Enum.Font.GothamBold
			Sep2.Text = text
			Sep2.TextColor3 = Color3.fromRGB(255, 255, 255)
			Sep2.TextSize = 14
			
			local Sep3 = Instance.new("TextLabel")
			Sep3.Name = "Sep3"
			Sep3.Parent = Seperator
			Sep3.BackgroundTransparency = 1
			Sep3.AnchorPoint = Vector2.new(1, 0.5)
			Sep3.Position = UDim2.new(1, 0, 0.5, 0)
			Sep3.Size = UDim2.new(0, 20, 0, 36)
			Sep3.Font = Enum.Font.GothamBold
			Sep3.RichText = true
			Sep3.Text = "<font color=\"rgb(255, 0, 0)\">》</font>》"
			Sep3.TextColor3 = Color3.fromRGB(255, 255, 255)
			Sep3.TextSize = 14
		end
		
		function main:Line()
			local Linee = Instance.new("Frame")
			Linee.Name = "Linee"
			Linee.Parent = MainFramePage
			Linee.BackgroundTransparency = 1
			Linee.Size = UDim2.new(1, 0, 0, 20)
			
			local Line = Instance.new("Frame")
			Line.Name = "Line"
			Line.Parent = Linee
			Line.BackgroundColor3 = Color3.new(125, 125, 125)
			Line.BorderSizePixel = 0
			Line.Position = UDim2.new(0, 0, 0, 10)
			Line.Size = UDim2.new(1, 0, 0, 1)
			
			local UIGradient = Instance.new("UIGradient")
			UIGradient.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, _G.Dark),
				ColorSequenceKeypoint.new(0.4, _G.Primary),
				ColorSequenceKeypoint.new(0.5, _G.Primary),
				ColorSequenceKeypoint.new(0.6, _G.Primary),
				ColorSequenceKeypoint.new(1, _G.Dark)
			})
			UIGradient.Parent = Line
		end
		
		return main
	end
	
	return uitab
end

return Update
