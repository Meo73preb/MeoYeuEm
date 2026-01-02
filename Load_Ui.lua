-- Vicat Hub - Fully Optimized Version
-- Improved with: Error handling, Config system, Memory management, Mobile support

-- ==================== CONFIGURATION ====================
local Config = {
	UI = {
		Spacing = {
			Padding = 15,
			ButtonGap = 20,
			TabContentGap = 25,
			ComponentGap = 8
		},
		Sizes = {
			TopBarHeight = 40,
			TabWidth = 150,
			ButtonSize = 20,
			RoundedCorner = {
				Small = 3,
				Medium = 5,
				Large = 12,
				ExtraLarge = 15
			}
		},
		Animation = {
			Fast = 0.15,
			Normal = 0.3,
			Slow = 0.4
		},
		ZIndex = {
			Background = 1,
			Content = 5,
			Overlay = 10,
			Settings = 11,
			SettingsContent = 12
		}
	},
	Colors = {
		Primary = Color3.fromRGB(100, 100, 100),
		Dark = Color3.fromRGB(22, 22, 26),
		Accent = Color3.fromRGB(255, 0, 0),
		Background = {
			Dark = Color3.fromRGB(24, 24, 26),
			Darker = Color3.fromRGB(20, 20, 25),
			Overlay = Color3.fromRGB(10, 10, 10)
		},
		Text = {
			Primary = Color3.fromRGB(255, 255, 255),
			Secondary = Color3.fromRGB(200, 200, 200),
			Disabled = Color3.fromRGB(150, 150, 150)
		}
	},
	Storage = {
		FolderName = "Vicat Hub",
		LibraryPath = "Vicat Hub/Library/"
	},
	Settings = {
		SaveSettings = true,
		PageAnimation = true
	}
}

-- Set global colors for backward compatibility
_G.Primary = Config.Colors.Primary
_G.Dark = Config.Colors.Dark
_G.Third = Config.Colors.Accent

-- ==================== SERVICES ====================
local Services = {
	CoreGui = game:GetService("CoreGui"),
	UserInputService = game:GetService("UserInputService"),
	TweenService = game:GetService("TweenService"),
	RunService = game:GetService("RunService"),
	Players = game:GetService("Players"),
	HttpService = game:GetService("HttpService"),
	TextService = game:GetService("TextService")
}

-- ==================== CONNECTION MANAGER ====================
local ConnectionManager = {}
ConnectionManager.__index = ConnectionManager

function ConnectionManager.new()
	local self = setmetatable({}, ConnectionManager)
	self.connections = {}
	return self
end

function ConnectionManager:Add(connection)
	table.insert(self.connections, connection)
	return connection
end

function ConnectionManager:DisconnectAll()
	for _, conn in ipairs(self.connections) do
		if conn and conn.Disconnect then
			pcall(function() conn:Disconnect() end)
		end
	end
	self.connections = {}
end

-- Global connection manager
local GlobalConnections = ConnectionManager.new()

-- ==================== CLEANUP EXISTING UI ====================
local function CleanupExistingUI()
	for _, name in ipairs({"VicatHub", "ScreenGui", "NotificationFrame"}) do
		local existing = Services.CoreGui:FindFirstChild(name)
		if existing then
			pcall(function() existing:Destroy() end)
		end
	end
end

CleanupExistingUI()

-- ==================== UTILITY FUNCTIONS ====================
local Utilities = {}

function Utilities.CreateRounded(parent, size)
	local rounded = Instance.new("UICorner")
	rounded.Name = "Rounded"
	rounded.CornerRadius = UDim.new(0, size)
	rounded.Parent = parent
	return rounded
end

function Utilities.SafeTween(object, tweenInfo, properties)
	return pcall(function()
		local tween = Services.TweenService:Create(object, tweenInfo, properties)
		tween:Play()
		return tween
	end)
end

function Utilities.MakeDraggable(topbar, object, connectionManager)
	local dragging, dragInput, dragStart, startPos
	
	local function update(input)
		local delta = input.Position - dragStart
		local pos = UDim2.new(
			startPos.X.Scale, startPos.X.Offset + delta.X,
			startPos.Y.Scale, startPos.Y.Offset + delta.Y
		)
		Utilities.SafeTween(object, TweenInfo.new(Config.UI.Animation.Fast), {Position = pos})
	end
	
	connectionManager:Add(topbar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or 
		   input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = object.Position
			
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end))
	
	connectionManager:Add(topbar.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or 
		   input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end))
	
	connectionManager:Add(Services.UserInputService.InputChanged:Connect(function(input)
		if input == dragInput and dragging then
			update(input)
		end
	end))
end

function Utilities.GetTextSize(text, textSize, font)
	return Services.TextService:GetTextSize(text, textSize, font, Vector2.new(math.huge, math.huge))
end

function Utilities.IsMobile()
	return Services.UserInputService.TouchEnabled and not Services.UserInputService.KeyboardEnabled
end

-- ==================== CONFIG MANAGEMENT ====================
local ConfigManager = {}

function ConfigManager.GetPath(filename)
	return Config.Storage.LibraryPath .. filename
end

function ConfigManager.Load()
	if not (readfile and writefile and isfile and isfolder) then
		warn("Executor doesn't support file system")
		return false
	end
	
	pcall(function()
		if not isfolder(Config.Storage.FolderName) then 
			makefolder(Config.Storage.FolderName) 
		end
		if not isfolder(Config.Storage.LibraryPath) then 
			makefolder(Config.Storage.LibraryPath) 
		end
		
		local configPath = ConfigManager.GetPath(Services.Players.LocalPlayer.Name .. ".json")
		
		if not isfile(configPath) then
			writefile(configPath, Services.HttpService:JSONEncode(Config.Settings))
		else
			local decoded = Services.HttpService:JSONDecode(readfile(configPath))
			for key, value in pairs(decoded) do
				Config.Settings[key] = value
			end
		end
		
		print("✅ Vicat Hub Config Loaded!")
	end)
	
	return true
end

function ConfigManager.Save()
	if not (writefile and isfile and isfolder) then return false end
	
	return pcall(function()
		local configPath = ConfigManager.GetPath(Services.Players.LocalPlayer.Name .. ".json")
		writefile(configPath, Services.HttpService:JSONEncode(Config.Settings))
	end)
end

function ConfigManager.Reset()
	return pcall(function()
		if isfolder(Config.Storage.FolderName) then
			delfolder(Config.Storage.FolderName)
		end
	end)
end

-- Initialize config
ConfigManager.Load()

getgenv().LoadConfig = ConfigManager.Load
getgenv().SaveConfig = ConfigManager.Save

-- ==================== NOTIFICATION SYSTEM ====================
local NotificationSystem = {}
local notificationFrame = Instance.new("ScreenGui")
notificationFrame.Name = "NotificationFrame"
notificationFrame.Parent = Services.CoreGui
notificationFrame.ZIndexBehavior = Enum.ZIndexBehavior.Global

local notificationList = {}

local function RemoveOldestNotification()
	if #notificationList > 0 then
		local removed = table.remove(notificationList, 1)
		pcall(function()
			removed[1]:TweenPosition(
				UDim2.new(0.5, 0, -0.2, 0), 
				"Out", "Quad", Config.UI.Animation.Slow, true, 
				function()
					removed[1]:Destroy()
				end
			)
		end)
	end
end

task.spawn(function()
	while task.wait() do
		if #notificationList > 0 then
			task.wait(2)
			RemoveOldestNotification()
		end
	end
end)

function NotificationSystem.Notify(desc)
	pcall(function()
		local outline = Instance.new("Frame")
		outline.Name = "OutlineFrame"
		outline.Parent = notificationFrame
		outline.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
		outline.BackgroundTransparency = 0.4
		outline.AnchorPoint = Vector2.new(0.5, 1)
		outline.Position = UDim2.new(0.5, 0, -0.2, 0)
		outline.Size = UDim2.new(0, 412, 0, 72)
		Utilities.CreateRounded(outline, Config.UI.Sizes.RoundedCorner.Large)
		
		local frame = Instance.new("Frame")
		frame.Parent = outline
		frame.AnchorPoint = Vector2.new(0.5, 0.5)
		frame.Position = UDim2.new(0.5, 0, 0.5, 0)
		frame.Size = UDim2.new(0, 400, 0, 60)
		frame.BackgroundColor3 = Config.Colors.Dark
		frame.BackgroundTransparency = 0.1
		Utilities.CreateRounded(frame, Config.UI.Sizes.RoundedCorner.Medium)
		
		local icon = Instance.new("ImageLabel")
		icon.Parent = frame
		icon.BackgroundTransparency = 1
		icon.Position = UDim2.new(0, 8, 0, 8)
		icon.Size = UDim2.new(0, 45, 0, 45)
		icon.Image = "rbxassetid://13940080072"
		
		local title = Instance.new("TextLabel")
		title.Parent = frame
		title.BackgroundTransparency = 1
		title.Position = UDim2.new(0, 55, 0, 14)
		title.Size = UDim2.new(0, 10, 0, 20)
		title.Font = Enum.Font.GothamBold
		title.Text = "Vicat Hub"
		title.TextColor3 = Config.Colors.Text.Primary
		title.TextSize = 16
		title.TextXAlignment = Enum.TextXAlignment.Left
		
		local descLabel = Instance.new("TextLabel")
		descLabel.Parent = frame
		descLabel.BackgroundTransparency = 1
		descLabel.Position = UDim2.new(0, 55, 0, 33)
		descLabel.Size = UDim2.new(0, 10, 0, 10)
		descLabel.Font = Enum.Font.GothamSemibold
		descLabel.Text = desc
		descLabel.TextColor3 = Config.Colors.Text.Secondary
		descLabel.TextSize = 12
		descLabel.TextTransparency = 0.3
		descLabel.TextXAlignment = Enum.TextXAlignment.Left
		
		outline:TweenPosition(
			UDim2.new(0.5, 0, 0.1 + (#notificationList * 0.1), 0), 
			"Out", "Quad", Config.UI.Animation.Slow, true
		)
		
		table.insert(notificationList, {outline})
	end)
end

-- ==================== LOADING SCREEN ====================
-- Removed - Not needed anymore

local LoadingScreen = {
	Show = function() end,
	Complete = function() end
}

-- ==================== TOGGLE BUTTON ====================
local function CreateToggleButton()
	local connections = ConnectionManager.new()
	
	local screenGui = Instance.new("ScreenGui")
	screenGui.Parent = Services.CoreGui
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	
	local outline = Instance.new("Frame")
	outline.Name = "OutlineButton"
	outline.Parent = screenGui
	outline.BackgroundColor3 = Config.Colors.Dark
	outline.Position = UDim2.new(0, 10, 0, 10)
	outline.Size = UDim2.new(0, 50, 0, 50)
	Utilities.CreateRounded(outline, Config.UI.Sizes.RoundedCorner.Large)
	
	local button = Instance.new("ImageButton")
	button.Parent = outline
	button.AnchorPoint = Vector2.new(0.5, 0.5)
	button.Position = UDim2.new(0.5, 0, 0.5, 0)
	button.Size = UDim2.new(0, 40, 0, 40)
	button.BackgroundColor3 = Config.Colors.Dark
	button.Image = "rbxassetid://13940080072"
	button.ImageColor3 = Color3.fromRGB(250, 250, 250)
	Utilities.CreateRounded(button, Config.UI.Sizes.RoundedCorner.Medium)
	
	Utilities.MakeDraggable(button, outline, connections)
	
	connections:Add(button.MouseButton1Click:Connect(function()
		local hub = Services.CoreGui:FindFirstChild("VicatHub")
		if hub then 
			hub.Enabled = not hub.Enabled 
		end
	end))
	
	return connections
end

local toggleConnections = CreateToggleButton()

-- ==================== MAIN UI LIBRARY ====================
local Update = {}

Update.Notify = NotificationSystem.Notify

function Update:SaveSettings()
	return Config.Settings.SaveSettings
end

function Update:LoadAnimation()
	-- Deprecated - Always returns false
	return false
end

function Update:PageAnimation()
	return Config.Settings.PageAnimation
end

function Update:Window(windowConfig)
	assert(windowConfig.SubTitle, "SubTitle is required")
	
	local windowData = {
		Size = windowConfig.Size,
		TabWidth = windowConfig.TabWidth or Config.UI.Sizes.TabWidth,
		Connections = ConnectionManager.new()
	}
	
	-- Create main UI
	local vicatHub = Instance.new("ScreenGui")
	vicatHub.Name = "VicatHub"
	vicatHub.Parent = Services.CoreGui
	vicatHub.DisplayOrder = 999
	
	local outlineMain = Instance.new("Frame")
	outlineMain.Name = "OutlineMain"
	outlineMain.Parent = vicatHub
	outlineMain.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	outlineMain.BackgroundTransparency = 0.4
	outlineMain.AnchorPoint = Vector2.new(0.5, 0.5)
	outlineMain.Position = UDim2.new(0.5, 0, 0.45, 0)
	outlineMain.Size = UDim2.new(0, 0, 0, 0)
	Utilities.CreateRounded(outlineMain, Config.UI.Sizes.RoundedCorner.ExtraLarge)
	
	local main = Instance.new("Frame")
	main.Name = "Main"
	main.Parent = outlineMain
	main.BackgroundColor3 = Config.Colors.Background.Dark
	main.AnchorPoint = Vector2.new(0.5, 0.5)
	main.Position = UDim2.new(0.5, 0, 0.5, 0)
	main.Size = windowData.Size
	Utilities.CreateRounded(main, Config.UI.Sizes.RoundedCorner.Large)
	
	outlineMain:TweenSize(
		UDim2.new(0, windowData.Size.X.Offset + Config.UI.Spacing.Padding, 0, windowData.Size.Y.Offset + Config.UI.Spacing.Padding),
		"Out", "Quad", Config.UI.Animation.Slow, true
	)
	
	-- Top Bar
	local top = Instance.new("Frame")
	top.Name = "Top"
	top.Parent = main
	top.BackgroundTransparency = 1
	top.Size = UDim2.new(1, 0, 0, Config.UI.Sizes.TopBarHeight)
	Utilities.CreateRounded(top, Config.UI.Sizes.RoundedCorner.Medium)
	
	-- Title
	local nameHub = Instance.new("TextLabel")
	nameHub.Parent = top
	nameHub.BackgroundTransparency = 1
	nameHub.Position = UDim2.new(0, Config.UI.Spacing.Padding, 0.5, 0)
	nameHub.AnchorPoint = Vector2.new(0, 0.5)
	nameHub.Font = Enum.Font.GothamBold
	nameHub.Text = "Vicat Hub"
	nameHub.TextSize = 20
	nameHub.TextColor3 = Config.Colors.Text.Primary
	nameHub.TextXAlignment = Enum.TextXAlignment.Left
	nameHub.ZIndex = Config.UI.ZIndex.Content
	nameHub.Size = UDim2.new(0, 0, 0, 25)
	
	local nameSize = Utilities.GetTextSize(nameHub.Text, nameHub.TextSize, nameHub.Font)
	nameHub.Size = UDim2.new(0, nameSize.X, 0, 25)
	
	-- Subtitle
	local subTitle = Instance.new("TextLabel")
	subTitle.Parent = top
	subTitle.BackgroundTransparency = 1
	subTitle.Position = UDim2.new(0, Config.UI.Spacing.Padding + nameSize.X + 8, 0.5, 0)
	subTitle.AnchorPoint = Vector2.new(0, 0.5)
	subTitle.Font = Enum.Font.Cartoon
	subTitle.Text = windowConfig.SubTitle
	subTitle.TextSize = 15
	subTitle.TextColor3 = Config.Colors.Text.Disabled
	subTitle.ZIndex = Config.UI.ZIndex.Content
	subTitle.Size = UDim2.new(0, 0, 0, 25)
	
	local subTitleSize = Utilities.GetTextSize(subTitle.Text, subTitle.TextSize, subTitle.Font)
	subTitle.Size = UDim2.new(0, subTitleSize.X, 0, 25)
	
	-- Settings Panel (create first for reference)
	local backgroundSettings = Instance.new("Frame")
	backgroundSettings.Name = "BackgroundSettings"
	backgroundSettings.Parent = outlineMain
	backgroundSettings.Active = true
	backgroundSettings.BackgroundColor3 = Config.Colors.Background.Overlay
	backgroundSettings.BackgroundTransparency = 0.3
	backgroundSettings.Size = UDim2.new(1, 0, 1, 0)
	backgroundSettings.Visible = false
	backgroundSettings.ZIndex = Config.UI.ZIndex.Overlay
	Utilities.CreateRounded(backgroundSettings, Config.UI.Sizes.RoundedCorner.ExtraLarge)
	
	local settingsFrame = Instance.new("Frame")
	settingsFrame.Name = "SettingsFrame"
	settingsFrame.Parent = backgroundSettings
	settingsFrame.BackgroundColor3 = Config.Colors.Background.Dark
	settingsFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	settingsFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	settingsFrame.Size = UDim2.new(0.7, 0, 0.7, 0)
	settingsFrame.ZIndex = Config.UI.ZIndex.Settings
	Utilities.CreateRounded(settingsFrame, Config.UI.Sizes.RoundedCorner.ExtraLarge)
	
	local closeSettings = Instance.new("ImageButton")
	closeSettings.Parent = settingsFrame
	closeSettings.BackgroundTransparency = 1
	closeSettings.AnchorPoint = Vector2.new(1, 0)
	closeSettings.Position = UDim2.new(1, -Config.UI.Spacing.ButtonGap, 0, Config.UI.Spacing.Padding)
	closeSettings.Size = UDim2.new(0, Config.UI.Sizes.ButtonSize, 0, Config.UI.Sizes.ButtonSize)
	closeSettings.Image = "rbxassetid://10747384394"
	closeSettings.ImageColor3 = Config.Colors.Text.Primary
	closeSettings.ZIndex = Config.UI.ZIndex.SettingsContent
	Utilities.CreateRounded(closeSettings, Config.UI.Sizes.RoundedCorner.Small)
	
	windowData.Connections:Add(closeSettings.MouseButton1Click:Connect(function()
		backgroundSettings.Visible = false
	end))
	
	local titleSettings = Instance.new("TextLabel")
	titleSettings.Parent = settingsFrame
	titleSettings.BackgroundTransparency = 1
	titleSettings.Position = UDim2.new(0, Config.UI.Spacing.ButtonGap, 0, Config.UI.Spacing.Padding)
	titleSettings.Size = UDim2.new(1, 0, 0, Config.UI.Sizes.ButtonSize)
	titleSettings.Font = Enum.Font.GothamBold
	titleSettings.Text = "Library Settings"
	titleSettings.TextSize = 20
	titleSettings.TextColor3 = Config.Colors.Text.Primary
	titleSettings.TextXAlignment = Enum.TextXAlignment.Left
	titleSettings.ZIndex = Config.UI.ZIndex.SettingsContent
	
	local settingsMenuList = Instance.new("Frame")
	settingsMenuList.Parent = settingsFrame
	settingsMenuList.BackgroundTransparency = 1
	settingsMenuList.Position = UDim2.new(0, 0, 0, 50)
	settingsMenuList.Size = UDim2.new(1, 0, 1, -70)
	settingsMenuList.ZIndex = Config.UI.ZIndex.Settings
	Utilities.CreateRounded(settingsMenuList, Config.UI.Sizes.RoundedCorner.ExtraLarge)
	
	local scrollSettings = Instance.new("ScrollingFrame")
	scrollSettings.Parent = settingsMenuList
	scrollSettings.BackgroundTransparency = 1
	scrollSettings.Size = UDim2.new(1, 0, 1, 0)
	scrollSettings.ScrollBarThickness = 3
	scrollSettings.ZIndex = Config.UI.ZIndex.Settings
	
	local settingsListLayout = Instance.new("UIListLayout")
	settingsListLayout.Parent = scrollSettings
	settingsListLayout.Padding = UDim.new(0, Config.UI.Spacing.ComponentGap)
	
	local paddingScroll = Instance.new("UIPadding")
	paddingScroll.Parent = scrollSettings
	paddingScroll.PaddingLeft = UDim.new(0, Config.UI.Spacing.ButtonGap)
	paddingScroll.PaddingRight = UDim.new(0, Config.UI.Spacing.ButtonGap)
	
	-- Settings Functions
	local function CreateCheckbox(title, state, callback)
		return pcall(function()
			local checked = state or false
			
			local background = Instance.new("Frame")
			background.Parent = scrollSettings
			background.BackgroundTransparency = 1
			background.Size = UDim2.new(1, 0, 0, 20)
			background.ZIndex = Config.UI.ZIndex.Settings
			
			local titleLabel = Instance.new("TextLabel")
			titleLabel.Parent = background
			titleLabel.BackgroundTransparency = 1
			titleLabel.Position = UDim2.new(0, 60, 0.5, 0)
			titleLabel.AnchorPoint = Vector2.new(0, 0.5)
			titleLabel.Size = UDim2.new(1, -60, 0, 20)
			titleLabel.Font = Enum.Font.Code
			titleLabel.Text = title or ""
			titleLabel.TextSize = 15
			titleLabel.TextColor3 = Config.Colors.Text.Secondary
			titleLabel.TextXAlignment = Enum.TextXAlignment.Left
			titleLabel.ZIndex = Config.UI.ZIndex.SettingsContent
			
			local checkbox = Instance.new("ImageButton")
			checkbox.Parent = background
			checkbox.BackgroundColor3 = checked and Config.Colors.Accent or Config.Colors.Primary
			checkbox.AnchorPoint = Vector2.new(0, 0.5)
			checkbox.Position = UDim2.new(0, 30, 0.5, 0)
			checkbox.Size = UDim2.new(0, 20, 0, 20)
			checkbox.Image = "rbxassetid://10709790644"
			checkbox.ImageTransparency = checked and 0 or 1
			checkbox.ImageColor3 = Config.Colors.Text.Primary
			checkbox.ZIndex = Config.UI.ZIndex.SettingsContent
			Utilities.CreateRounded(checkbox, Config.UI.Sizes.RoundedCorner.Medium)
			
			windowData.Connections:Add(checkbox.MouseButton1Click:Connect(function()
				checked = not checked
				checkbox.BackgroundColor3 = checked and Config.Colors.Accent or Config.Colors.Primary
				checkbox.ImageTransparency = checked and 0 or 1
				pcall(callback, checked)
			end))
			
			pcall(callback, checked)
		end)
	end
	
	local function CreateButton(title, callback)
		return pcall(function()
			local background = Instance.new("Frame")
			background.Parent = scrollSettings
			background.BackgroundTransparency = 1
			background.Size = UDim2.new(1, 0, 0, 30)
			background.ZIndex = Config.UI.ZIndex.Settings
			
			local button = Instance.new("TextButton")
			button.Parent = background
			button.BackgroundColor3 = Config.Colors.Accent
			button.Size = UDim2.new(0.8, 0, 0, 30)
			button.Font = Enum.Font.Code
			button.Text = title or "Button"
			button.AnchorPoint = Vector2.new(0.5, 0)
			button.Position = UDim2.new(0.5, 0, 0, 0)
			button.TextColor3 = Config.Colors.Text.Primary
			button.TextSize = 15
			button.AutoButtonColor = false
			button.ZIndex = Config.UI.ZIndex.SettingsContent
			Utilities.CreateRounded(button, Config.UI.Sizes.RoundedCorner.Medium)
			
			windowData.Connections:Add(button.MouseButton1Click:Connect(function()
				pcall(callback)
			end))
		end)
	end
	
	-- Add settings options
	CreateCheckbox("Save Settings", Config.Settings.SaveSettings, function(state)
		Config.Settings.SaveSettings = state
		ConfigManager.Save()
	end)
	
	CreateCheckbox("Page Animation", Config.Settings.PageAnimation, function(state)
		Config.Settings.PageAnimation = state
		ConfigManager.Save()
	end)
	
	CreateButton("Reset Config", function()
		if ConfigManager.Reset() then
			NotificationSystem.Notify("Config has been reset!")
		end
	end)
	
	-- Auto-resize settings canvas
	windowData.Connections:Add(Services.RunService.Heartbeat:Connect(function()
		pcall(function()
			scrollSettings.CanvasSize = UDim2.new(0, 0, 0, settingsListLayout.AbsoluteContentSize.Y)
		end)
	end))
	
	-- Top bar buttons
	local closeButton = Instance.new("ImageButton")
	closeButton.Parent = top
	closeButton.BackgroundTransparency = 1
	closeButton.AnchorPoint = Vector2.new(1, 0.5)
	closeButton.Position = UDim2.new(1, -Config.UI.Spacing.Padding, 0.5, 0)
	closeButton.Size = UDim2.new(0, Config.UI.Sizes.ButtonSize, 0, Config.UI.Sizes.ButtonSize)
	closeButton.Image = "rbxassetid://7743878857"
	closeButton.ImageColor3 = Config.Colors.Text.Primary
	closeButton.ZIndex = Config.UI.ZIndex.Content
	Utilities.CreateRounded(closeButton, Config.UI.Sizes.RoundedCorner.Small)
	
	windowData.Connections:Add(closeButton.MouseButton1Click:Connect(function()
		vicatHub.Enabled = not vicatHub.Enabled
	end))
	
	local resizeButton = Instance.new("ImageButton")
	resizeButton.Parent = top
	resizeButton.BackgroundTransparency = 1
	resizeButton.AnchorPoint = Vector2.new(1, 0.5)
	resizeButton.Position = UDim2.new(1, -Config.UI.Sizes.ButtonSize * 2.5, 0.5, 0)
	resizeButton.Size = UDim2.new(0, Config.UI.Sizes.ButtonSize, 0, Config.UI.Sizes.ButtonSize)
	resizeButton.Image = "rbxassetid://10734886735"
	resizeButton.ImageColor3 = Config.Colors.Text.Primary
	resizeButton.ZIndex = Config.UI.ZIndex.Content
	Utilities.CreateRounded(resizeButton, Config.UI.Sizes.RoundedCorner.Small)
	
	local settingsButton = Instance.new("ImageButton")
	settingsButton.Parent = top
	settingsButton.BackgroundTransparency = 1
	settingsButton.AnchorPoint = Vector2.new(1, 0.5)
	resizeButton.Position = UDim2.new(1, -Config.UI.Sizes.ButtonSize * 2.5, 0.5, 0)
	settingsButton.Position = UDim2.new(1, -Config.UI.Sizes.ButtonSize * 4.25, 0.5, 0)
	settingsButton.Size = UDim2.new(0, Config.UI.Sizes.ButtonSize, 0, Config.UI.Sizes.ButtonSize)
	settingsButton.Image = "rbxassetid://10734950020"
	settingsButton.ImageColor3 = Config.Colors.Text.Primary
	settingsButton.ZIndex = Config.UI.ZIndex.Content
	Utilities.CreateRounded(settingsButton, Config.UI.Sizes.RoundedCorner.Small)
	
	windowData.Connections:Add(settingsButton.MouseButton1Click:Connect(function()
		backgroundSettings.Visible = true
	end))
	
	-- Resize functionality with improved performance
	local defaultSize = true
	local resizeConnection
	
	windowData.Connections:Add(resizeButton.MouseButton1Click:Connect(function()
		pcall(function()
			if resizeConnection then
				resizeConnection:Disconnect()
			end
			
			if defaultSize then
				defaultSize = false
				
				-- Calculate target sizes
				local screenSize = workspace.CurrentCamera.ViewportSize
				local targetMainSize = UDim2.new(0, screenSize.X - 20, 0, screenSize.Y - 20)
				
				outlineMain:TweenPosition(UDim2.new(0.5, 0, 0.5, 0), "Out", "Quad", 0.2, true)
				outlineMain:TweenSize(UDim2.new(0, screenSize.X - 10, 0, screenSize.Y - 10), "Out", "Quad", Config.UI.Animation.Slow, true)
				
				Utilities.SafeTween(main, TweenInfo.new(Config.UI.Animation.Slow, Enum.EasingStyle.Quad), {
					Size = targetMainSize
				})
				
				resizeButton.Image = "rbxassetid://10734895698"
				
				-- Update children sizes dynamically
				local startTime = tick()
				resizeConnection = Services.RunService.RenderStepped:Connect(function()
					local elapsed = tick() - startTime
					if elapsed > 0.5 then
						if resizeConnection then
							resizeConnection:Disconnect()
							resizeConnection = nil
						end
					end
					
					pcall(function()
						local newPageWidth = main.AbsoluteSize.X - tab.AbsoluteSize.X - Config.UI.Spacing.TabContentGap
						local newPageHeight = main.AbsoluteSize.Y - Config.UI.Sizes.TopBarHeight - 10
						local newTabHeight = main.AbsoluteSize.Y - Config.UI.Sizes.TopBarHeight - 10
						
						page.Size = UDim2.new(0, newPageWidth, 0, newPageHeight)
						tab.Size = UDim2.new(0, windowData.TabWidth, 0, newTabHeight)
					end)
				end)
				
			else
				defaultSize = true
				
				outlineMain:TweenSize(
					UDim2.new(0, windowData.Size.X.Offset + Config.UI.Spacing.Padding, 0, windowData.Size.Y.Offset + Config.UI.Spacing.Padding), 
					"Out", "Quad", Config.UI.Animation.Slow, true
				)
				outlineMain:TweenPosition(UDim2.new(0.5, 0, 0.45, 0), "Out", "Quad", 0.2, true)
				
				Utilities.SafeTween(main, TweenInfo.new(Config.UI.Animation.Slow, Enum.EasingStyle.Quad), {
					Size = windowData.Size
				})
				
				resizeButton.Image = "rbxassetid://10734886735"
				
				-- Update children sizes dynamically
				local startTime = tick()
				resizeConnection = Services.RunService.RenderStepped:Connect(function()
					local elapsed = tick() - startTime
					if elapsed > 0.5 then
						if resizeConnection then
							resizeConnection:Disconnect()
							resizeConnection = nil
						end
					end
					
					pcall(function()
						local newPageWidth = main.AbsoluteSize.X - tab.AbsoluteSize.X - Config.UI.Spacing.TabContentGap
						local newPageHeight = main.AbsoluteSize.Y - Config.UI.Sizes.TopBarHeight - 10
						local newTabHeight = main.AbsoluteSize.Y - Config.UI.Sizes.TopBarHeight - 10
						
						page.Size = UDim2.new(0, newPageWidth, 0, newPageHeight)
						tab.Size = UDim2.new(0, windowData.TabWidth, 0, newTabHeight)
					end)
				end)
			end
		end)
	end))
	
	Utilities.MakeDraggable(top, outlineMain, windowData.Connections)
	
	-- Toggle UI with Insert key
	windowData.Connections:Add(Services.UserInputService.InputBegan:Connect(function(input)
		if input.KeyCode == Enum.KeyCode.Insert then
			vicatHub.Enabled = not vicatHub.Enabled
		end
	end))
	
	-- Tab Container
	local tab = Instance.new("Frame")
	tab.Name = "Tab"
	tab.Parent = main
	tab.BackgroundTransparency = 1
	tab.Position = UDim2.new(0, Config.UI.Spacing.ComponentGap, 0, top.Size.Y.Offset)
	tab.Size = UDim2.new(0, windowData.TabWidth, 0, windowData.Size.Y.Offset - top.Size.Y.Offset - Config.UI.Spacing.ComponentGap)
	Utilities.CreateRounded(tab, Config.UI.Sizes.RoundedCorner.Medium)
	
	local scrollTab = Instance.new("ScrollingFrame")
	scrollTab.Parent = tab
	scrollTab.BackgroundTransparency = 1
	scrollTab.Size = UDim2.new(1, 0, 1, 0)
	scrollTab.ScrollBarThickness = 0
	
	local tabListLayout = Instance.new("UIListLayout")
	tabListLayout.Parent = scrollTab
	tabListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	tabListLayout.Padding = UDim.new(0, 2)
	
	-- Page Container
	local page = Instance.new("Frame")
	page.Name = "Page"
	page.Parent = main
	page.BackgroundTransparency = 1
	page.Position = UDim2.new(0, tab.Size.X.Offset + 18, 0, top.Size.Y.Offset)
	page.Size = UDim2.new(0, windowData.Size.X.Offset - tab.Size.X.Offset - Config.UI.Spacing.TabContentGap, 0, windowData.Size.Y.Offset - top.Size.Y.Offset - Config.UI.Spacing.ComponentGap)
	page.ClipsDescendants = true
	Utilities.CreateRounded(page, Config.UI.Sizes.RoundedCorner.Small)
	
	local mainPage = Instance.new("Frame")
	mainPage.Parent = page
	mainPage.BackgroundTransparency = 1
	mainPage.Size = UDim2.new(1, 0, 1, 0)
	mainPage.ClipsDescendants = true
	
	local pageList = Instance.new("Folder")
	pageList.Name = "PageList"
	pageList.Parent = mainPage
	
	-- Auto-resize canvas
	windowData.Connections:Add(Services.RunService.Heartbeat:Connect(function()
		pcall(function()
			scrollTab.CanvasSize = UDim2.new(0, 0, 0, tabListLayout.AbsoluteContentSize.Y)
		end)
	end))
	
	local uitab = {}
	local abc = false
	local tabIndex = 0
	local currentTabIndex = 0
	
	function uitab:Tab(text, img)
		return pcall(function()
			local tabButton = Instance.new("TextButton")
			tabButton.Name = text .. "Unique"
			tabButton.Parent = scrollTab
			tabButton.Text = ""
			tabButton.BackgroundColor3 = Config.Colors.Primary
			tabButton.BackgroundTransparency = 1
			tabButton.Size = UDim2.new(1, 0, 0, 35)
			tabButton.LayoutOrder = tabIndex
			Utilities.CreateRounded(tabButton, Config.UI.Sizes.RoundedCorner.Medium)
			
			local thisTabIndex = tabIndex
			tabIndex = tabIndex + 1
			
			local selectedTab = Instance.new("Frame")
			selectedTab.Name = "SelectedTab"
			selectedTab.Parent = tabButton
			selectedTab.BackgroundColor3 = Config.Colors.Accent
			selectedTab.Size = UDim2.new(0, 3, 0, 0)
			selectedTab.Position = UDim2.new(0, 0, 0.5, 0)
			selectedTab.AnchorPoint = Vector2.new(0, 0.5)
			Utilities.CreateRounded(selectedTab, 100)
			
			local title = Instance.new("TextLabel")
			title.Name = "Title"
			title.Parent = tabButton
			title.BackgroundTransparency = 1
			title.Position = UDim2.new(0, 30, 0.5, 0)
			title.AnchorPoint = Vector2.new(0, 0.5)
			title.Size = UDim2.new(0, 100, 0, 30)
			title.Font = Enum.Font.Roboto
			title.Text = text
			title.TextColor3 = Config.Colors.Text.Primary
			title.TextTransparency = 0.4
			title.TextSize = 14
			title.TextXAlignment = Enum.TextXAlignment.Left
			
			local icon = Instance.new("ImageLabel")
			icon.Name = "IDK"
			icon.Parent = tabButton
			icon.BackgroundTransparency = 1
			icon.Position = UDim2.new(0, 7, 0.5, 0)
			icon.AnchorPoint = Vector2.new(0, 0.5)
			icon.Size = UDim2.new(0, 15, 0, 15)
			icon.Image = img
			icon.ImageTransparency = 0.3
			
			-- Main Frame Page
			local mainFramePage = Instance.new("ScrollingFrame")
			mainFramePage.Name = text .. "_Page"
			mainFramePage.Parent = pageList
			mainFramePage.BackgroundTransparency = 1
			mainFramePage.Size = UDim2.new(1, 0, 1, 0)
			mainFramePage.ScrollBarThickness = 0
			mainFramePage.BorderSizePixel = 0
			mainFramePage.Visible = false
			mainFramePage.ClipsDescendants = true
			
			local uiListLayout = Instance.new("UIListLayout")
			uiListLayout.Parent = mainFramePage
			uiListLayout.Padding = UDim.new(0, Config.UI.Spacing.ComponentGap)
			uiListLayout.SortOrder = Enum.SortOrder.LayoutOrder
			
			local uiPadding = Instance.new("UIPadding")
			uiPadding.Parent = mainFramePage
			
			-- Tab Click Handler with smooth animation
			windowData.Connections:Add(tabButton.MouseButton1Click:Connect(function()
				local clickedIndex = thisTabIndex
				
				if clickedIndex == currentTabIndex then
					return
				end
				
				for _, v in pairs(scrollTab:GetChildren()) do
					if v:IsA("TextButton") then
						Utilities.SafeTween(v, TweenInfo.new(0.2), {BackgroundTransparency = 1})
						Utilities.SafeTween(v.SelectedTab, TweenInfo.new(0.2), {Size = UDim2.new(0, 3, 0, 0)})
						Utilities.SafeTween(v.IDK, TweenInfo.new(0.2), {ImageTransparency = 0.4})
						Utilities.SafeTween(v.Title, TweenInfo.new(0.2), {TextTransparency = 0.4})
					end
				end
				
				for _, v in pairs(pageList:GetChildren()) do
					if v:IsA("ScrollingFrame") then
						v.Visible = false
					end
				end
				
				mainFramePage.Visible = true
				
				Utilities.SafeTween(tabButton, TweenInfo.new(0.2), {BackgroundTransparency = 0.8})
				Utilities.SafeTween(selectedTab, TweenInfo.new(0.2), {Size = UDim2.new(0, 3, 0, 15)})
				Utilities.SafeTween(icon, TweenInfo.new(0.2), {ImageTransparency = 0})
				Utilities.SafeTween(title, TweenInfo.new(0.2), {TextTransparency = 0})
				
				if Config.Settings.PageAnimation then
					-- Smooth slide animation
					local animTime = 0.25
					if clickedIndex > currentTabIndex then
						-- Slide up from bottom
						mainFramePage.Position = UDim2.new(0, 0, 1, 0)
						mainFramePage:TweenPosition(
							UDim2.new(0, 0, 0, 0), 
							"Out", 
							"Sine", 
							animTime, 
							true
						)
					else
						-- Slide down from top
						mainFramePage.Position = UDim2.new(0, 0, -1, 0)
						mainFramePage:TweenPosition(
							UDim2.new(0, 0, 0, 0), 
							"Out", 
							"Sine", 
							animTime, 
							true
						)
					end
				else
					mainFramePage.Position = UDim2.new(0, 0, 0, 0)
				end
				
				currentTabIndex = clickedIndex
			end))
			
			if not abc then
				mainFramePage.Visible = true
				mainFramePage.Position = UDim2.new(0, 0, 0, 0)
				
				Utilities.SafeTween(tabButton, TweenInfo.new(0.2), {BackgroundTransparency = 0.8})
				Utilities.SafeTween(selectedTab, TweenInfo.new(0.2), {Size = UDim2.new(0, 3, 0, 15)})
				Utilities.SafeTween(icon, TweenInfo.new(0.2), {ImageTransparency = 0})
				Utilities.SafeTween(title, TweenInfo.new(0.2), {TextTransparency = 0})
				
				currentTabIndex = 0
				abc = true
			end
			
			windowData.Connections:Add(Services.RunService.Heartbeat:Connect(function()
				pcall(function()
					mainFramePage.CanvasSize = UDim2.new(0, 0, 0, uiListLayout.AbsoluteContentSize.Y + 10)
				end)
			end))
			
			local main = {}
			
			-- Button Component
			function main:Button(text, callback)
				return pcall(function()
					local button = Instance.new("Frame")
					button.Name = "Button"
					button.Parent = mainFramePage
					button.BackgroundTransparency = 1
					button.Size = UDim2.new(1, 0, 0, 40)
					Utilities.CreateRounded(button, Config.UI.Sizes.RoundedCorner.Medium)
					
					local textLabel = Instance.new("TextLabel")
					textLabel.Parent = button
					textLabel.BackgroundTransparency = 1
					textLabel.Position = UDim2.new(0, Config.UI.Spacing.ButtonGap, 0.5, 0)
					textLabel.AnchorPoint = Vector2.new(0, 0.5)
					textLabel.Size = UDim2.new(1, -70, 1, 0)
					textLabel.Font = Enum.Font.Cartoon
					textLabel.Text = text
					textLabel.TextColor3 = Config.Colors.Text.Primary
					textLabel.TextSize = 15
					textLabel.TextXAlignment = Enum.TextXAlignment.Left
					
					local textButton = Instance.new("TextButton")
					textButton.Parent = button
					textButton.BackgroundColor3 = Config.Colors.Background.Darker
					textButton.BackgroundTransparency = 0
					textButton.AnchorPoint = Vector2.new(1, 0.5)
					textButton.Position = UDim2.new(1, -5, 0.5, 0)
					textButton.Size = UDim2.new(0, 30, 0, 30)
					textButton.Text = ""
					Utilities.CreateRounded(textButton, Config.UI.Sizes.RoundedCorner.Small)
					
					local imageLabel = Instance.new("ImageLabel")
					imageLabel.Parent = textButton
					imageLabel.BackgroundTransparency = 1
					imageLabel.AnchorPoint = Vector2.new(0.5, 0.5)
					imageLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
					imageLabel.Size = UDim2.new(0, 18, 0, 18)
					imageLabel.Image = "rbxassetid://10734898355"
					imageLabel.ImageColor3 = Config.Colors.Text.Primary
					
					windowData.Connections:Add(textButton.MouseButton1Click:Connect(function()
						pcall(callback)
						
						-- Click feedback animation
						Utilities.SafeTween(textButton, TweenInfo.new(0.1), {
							BackgroundColor3 = Config.Colors.Accent
						})
						task.wait(0.1)
						Utilities.SafeTween(textButton, TweenInfo.new(0.1), {
							BackgroundColor3 = Config.Colors.Background.Darker
						})
					end))
				end) and {} or {}
			end
			
			-- Toggle Component
			function main:Toggle(text, config, desc, callback)
				config = config or false
				local toggled = config
				
				return pcall(function()
					local button = Instance.new("TextButton")
					button.Name = "Toggle"
					button.Parent = mainFramePage
					button.BackgroundColor3 = Config.Colors.Primary
					button.BackgroundTransparency = 0.8
					button.AutoButtonColor = false
					button.Text = ""
					button.Size = UDim2.new(1, 0, 0, desc and 46 or 36)
					Utilities.CreateRounded(button, Config.UI.Sizes.RoundedCorner.Medium)
					
					local title = Instance.new("TextLabel")
					title.Parent = button
					title.BackgroundTransparency = 1
					title.Size = UDim2.new(1, 0, 0, 35)
					title.Font = Enum.Font.Cartoon
					title.Text = text
					title.TextColor3 = Config.Colors.Text.Primary
					title.TextSize = 15
					title.TextXAlignment = Enum.TextXAlignment.Left
					title.AnchorPoint = Vector2.new(0, 0.5)
					title.Position = UDim2.new(0, 15, 0.5, desc and -5 or 0)
					
					if desc then
						local descLabel = Instance.new("TextLabel")
						descLabel.Parent = title
						descLabel.BackgroundTransparency = 1
						descLabel.Position = UDim2.new(0, 0, 0, 22)
						descLabel.Size = UDim2.new(0, 280, 0, 16)
						descLabel.Font = Enum.Font.Gotham
						descLabel.Text = desc
						descLabel.TextColor3 = Config.Colors.Text.Disabled
						descLabel.TextSize = 10
						descLabel.TextXAlignment = Enum.TextXAlignment.Left
					end
					
					local toggleFrame = Instance.new("Frame")
					toggleFrame.Parent = button
					toggleFrame.BackgroundTransparency = 1
					toggleFrame.Position = UDim2.new(1, -10, 0.5, 0)
					toggleFrame.Size = UDim2.new(0, 35, 0, 20)
					toggleFrame.AnchorPoint = Vector2.new(1, 0.5)
					Utilities.CreateRounded(toggleFrame, 10)
					
					local toggleImage = Instance.new("TextButton")
					toggleImage.Parent = toggleFrame
					toggleImage.BackgroundColor3 = toggled and Config.Colors.Accent or Color3.fromRGB(200, 200, 200)
					toggleImage.BackgroundTransparency = toggled and 0 or 0.8
					toggleImage.Size = UDim2.new(1, 0, 1, 0)
					toggleImage.Text = ""
					toggleImage.AutoButtonColor = false
					Utilities.CreateRounded(toggleImage, 10)
					
					local circle = Instance.new("Frame")
					circle.Parent = toggleImage
					circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
					circle.Position = UDim2.new(0, toggled and 17 or 3, 0.5, 0)
					circle.Size = UDim2.new(0, 14, 0, 14)
					circle.AnchorPoint = Vector2.new(0, 0.5)
					Utilities.CreateRounded(circle, 10)
					
					windowData.Connections:Add(toggleImage.MouseButton1Click:Connect(function()
						toggled = not toggled
						
						if toggled then
							circle:TweenPosition(UDim2.new(0, 17, 0.5, 0), "Out", "Sine", 0.2, true)
							Utilities.SafeTween(toggleImage, TweenInfo.new(0.4, Enum.EasingStyle.Quad), {
								BackgroundColor3 = Config.Colors.Accent,
								BackgroundTransparency = 0
							})
						else
							circle:TweenPosition(UDim2.new(0, 3, 0.5, 0), "Out", "Sine", 0.2, true)
							Utilities.SafeTween(toggleImage, TweenInfo.new(0.4, Enum.EasingStyle.Quad), {
								BackgroundColor3 = Color3.fromRGB(200, 200, 200),
								BackgroundTransparency = 0.8
							})
						end
						
						pcall(callback, toggled)
					end))
					
					if config then
						pcall(callback, toggled)
					end
				end) and {} or {}
			end
			
			-- Label Component
			function main:Label(text)
				local labelfunc = {}
				
				pcall(function()
					local frame = Instance.new("Frame")
					frame.Name = "Label"
					frame.Parent = mainFramePage
					frame.BackgroundTransparency = 1
					frame.Size = UDim2.new(1, 0, 0, 30)
					
					local label = Instance.new("TextLabel")
					label.Parent = frame
					label.BackgroundTransparency = 1
					label.Position = UDim2.new(0, 30, 0.5, 0)
					label.AnchorPoint = Vector2.new(0, 0.5)
					label.Size = UDim2.new(1, -30, 0, 30)
					label.Font = Enum.Font.Nunito
					label.Text = text
					label.TextColor3 = Config.Colors.Text.Secondary
					label.TextSize = 15
					label.TextXAlignment = Enum.TextXAlignment.Left
					
					local imageLabel = Instance.new("ImageLabel")
					imageLabel.Parent = frame
					imageLabel.BackgroundTransparency = 1
					imageLabel.Position = UDim2.new(0, 10, 0.5, 0)
					imageLabel.AnchorPoint = Vector2.new(0, 0.5)
					imageLabel.Size = UDim2.new(0, 14, 0, 14)
					imageLabel.Image = "rbxassetid://10723415903"
					imageLabel.ImageColor3 = Config.Colors.Text.Secondary
					
					function labelfunc:Set(newtext)
						label.Text = newtext
					end
				end)
				
				return labelfunc
			end
			
			-- Separator Component
			function main:Seperator(text)
				return pcall(function()
					local seperator = Instance.new("Frame")
					seperator.Name = "Seperator"
					seperator.Parent = mainFramePage
					seperator.BackgroundTransparency = 1
					seperator.Size = UDim2.new(1, 0, 0, 36)
					
					local sep1 = Instance.new("TextLabel")
					sep1.Parent = seperator
					sep1.BackgroundTransparency = 1
					sep1.Position = UDim2.new(0, 0, 0.5, 0)
					sep1.AnchorPoint = Vector2.new(0, 0.5)
					sep1.Size = UDim2.new(0, 20, 0, 36)
					sep1.Font = Enum.Font.GothamBold
					sep1.RichText = true
					sep1.Text = '《<font color="rgb(255, 0, 0)">《</font>'
					sep1.TextColor3 = Config.Colors.Text.Primary
					sep1.TextSize = 14
					
					local sep2 = Instance.new("TextLabel")
					sep2.Parent = seperator
					sep2.BackgroundTransparency = 1
					sep2.Position = UDim2.new(0.5, 0, 0.5, 0)
					sep2.AnchorPoint = Vector2.new(0.5, 0.5)
					sep2.Size = UDim2.new(1, 0, 0, 36)
					sep2.Font = Enum.Font.GothamBold
					sep2.Text = text
					sep2.TextColor3 = Config.Colors.Text.Primary
					sep2.TextSize = 14
					
					local sep3 = Instance.new("TextLabel")
					sep3.Parent = seperator
					sep3.BackgroundTransparency = 1
					sep3.Position = UDim2.new(1, 0, 0.5, 0)
					sep3.AnchorPoint = Vector2.new(1, 0.5)
					sep3.Size = UDim2.new(0, 20, 0, 36)
					sep3.Font = Enum.Font.GothamBold
					sep3.RichText = true
					sep3.Text = '<font color="rgb(255, 0, 0)">》</font>》'
					sep3.TextColor3 = Config.Colors.Text.Primary
					sep3.TextSize = 14
				end) and {} or {}
			end
			
			-- Line Component
			function main:Line()
				return pcall(function()
					local linee = Instance.new("Frame")
					linee.Name = "Line"
					linee.Parent = mainFramePage
					linee.BackgroundTransparency = 1
					linee.Size = UDim2.new(1, 0, 0, 20)
					
					local line = Instance.new("Frame")
					line.Parent = linee
					line.BackgroundColor3 = Color3.fromRGB(125, 125, 125)
					line.BorderSizePixel = 0
					line.Position = UDim2.new(0, 0, 0, 10)
					line.Size = UDim2.new(1, 0, 0, 1)
					
					local gradient = Instance.new("UIGradient")
					gradient.Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0, Config.Colors.Dark),
						ColorSequenceKeypoint.new(0.4, Config.Colors.Primary),
						ColorSequenceKeypoint.new(0.5, Config.Colors.Primary),
						ColorSequenceKeypoint.new(0.6, Config.Colors.Primary),
						ColorSequenceKeypoint.new(1, Config.Colors.Dark)
					})
					gradient.Parent = line
				end) and {} or {}
			end
			
			return main
		end) and {} or {}
	end
	
	-- Cleanup on destroy
	vicatHub.AncestryChanged:Connect(function(_, parent)
		if not parent then
			windowData.Connections:DisconnectAll()
		end
	end)
	
	return uitab
end

return Update
