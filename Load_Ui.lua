-- Vicat Hub - Fully Optimized Version 19
-- ============================================
-- Mobile & PC Support
-- Clean Code Architecture
-- ============================================

-- Cleanup existing instances
local coreGui = game:GetService("CoreGui")
for _, item in pairs(coreGui:GetChildren()) do
	if item.Name == "VicatHub" or item.Name == "ScreenGui" or item.Name == "NotificationFrame" then
		item:Destroy()
	end
end

-- Services (cached once)
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TextService = game:GetService("TextService")

-- Constants
local CONSTANTS = {
	-- Colors
	PRIMARY = Color3.fromRGB(100, 100, 100),
	DARK = Color3.fromRGB(22, 22, 26),
	ACCENT = Color3.fromRGB(255, 0, 0),
	BACKGROUND_DARK = Color3.fromRGB(24, 24, 26),
	SLIDER_TEXT_BG = Color3.fromRGB(20, 20, 25),
	
	-- Spacing
	PADDING = {
		SMALL = 5,
		MEDIUM = 10,
		LARGE = 15,
		XLARGE = 20
	},
	
	-- Sizes
	BUTTON_SIZE = 20,
	ICON_SIZE = 15,
	TAB_HEIGHT = 35,
	TOP_BAR_HEIGHT = 40,
	
	-- Animations
	TWEEN_TIME = {
		FAST = 0.15,
		NORMAL = 0.3,
		SLOW = 0.4
	},
	
	-- Folders
	CONFIG_FOLDER = "Vicat Hub",
	CONFIG_SUB_FOLDER = "Vicat Hub/Library/",
	
	-- Notification
	NOTIF_DURATION = 5,
	MAX_NOTIFICATIONS = 6
}

-- Global color references
_G.Primary = CONSTANTS.PRIMARY
_G.Dark = CONSTANTS.DARK
_G.Third = CONSTANTS.ACCENT

-- Connection manager for cleanup
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
		if conn and conn.Connected then
			conn:Disconnect()
		end
	end
	self.connections = {}
end

local globalConnections = ConnectionManager.new()

-- Utility Functions
local Utils = {}

function Utils.CreateRounded(parent, size)
	local rounded = Instance.new("UICorner")
	rounded.CornerRadius = UDim.new(0, size)
	rounded.Parent = parent
	return rounded
end

function Utils.CreatePadding(parent, left, right, top, bottom)
	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, left or 0)
	padding.PaddingRight = UDim.new(0, right or 0)
	padding.PaddingTop = UDim.new(0, top or 0)
	padding.PaddingBottom = UDim.new(0, bottom or 0)
	padding.Parent = parent
	return padding
end

function Utils.Tween(instance, props, duration, style, direction)
	duration = duration or CONSTANTS.TWEEN_TIME.NORMAL
	style = style or Enum.EasingStyle.Quad
	direction = direction or Enum.EasingDirection.Out
	
	local tween = TweenService:Create(instance, TweenInfo.new(duration, style, direction), props)
	tween:Play()
	return tween
end

function Utils.MakeDraggable(topbar, object)
	local dragging, dragInput, dragStart, startPos
	
	local function update(input)
		local delta = input.Position - dragStart
		local pos = UDim2.new(
			startPos.X.Scale, startPos.X.Offset + delta.X,
			startPos.Y.Scale, startPos.Y.Offset + delta.Y
		)
		Utils.Tween(object, {Position = pos}, CONSTANTS.TWEEN_TIME.FAST)
	end
	
	globalConnections:Add(topbar.InputBegan:Connect(function(input)
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
	
	globalConnections:Add(topbar.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or 
		   input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end))
	
	globalConnections:Add(UserInputService.InputChanged:Connect(function(input)
		if input == dragInput and dragging then
			update(input)
		end
	end))
end

function Utils.GetTextSize(text, textSize, font)
	return TextService:GetTextSize(text, textSize, font, Vector2.new(math.huge, math.huge))
end

function Utils.SafeCall(func, ...)
	local success, result = pcall(func, ...)
	if not success then
		warn("[Vicat Hub Error]:", result)
	end
	return success, result
end

-- Settings Manager
local SettingsManager = {}
SettingsManager.__index = SettingsManager

function SettingsManager.new()
	local self = setmetatable({}, SettingsManager)
	self.settings = {
		SaveSettings = true,
		LoadAnimation = true,
		PageAnimation = true
	}
	self:Load()
	return self
end

function SettingsManager:Load()
	if not (readfile and writefile and isfile and isfolder) then
		warn("[Vicat Hub] Executor doesn't support file system")
		return false
	end
	
	Utils.SafeCall(function()
		if not isfolder(CONSTANTS.CONFIG_FOLDER) then
			makefolder(CONSTANTS.CONFIG_FOLDER)
		end
		if not isfolder(CONSTANTS.CONFIG_SUB_FOLDER) then
			makefolder(CONSTANTS.CONFIG_SUB_FOLDER)
		end
		
		local path = CONSTANTS.CONFIG_SUB_FOLDER .. Players.LocalPlayer.Name .. ".json"
		if not isfile(path) then
			writefile(path, HttpService:JSONEncode(self.settings))
		else
			local data = HttpService:JSONDecode(readfile(path))
			for key, value in pairs(data) do
				self.settings[key] = value
			end
		end
	end)
	
	return true
end

function SettingsManager:Save()
	if not (writefile and isfile and isfolder) then return false end
	
	return Utils.SafeCall(function()
		local path = CONSTANTS.CONFIG_SUB_FOLDER .. Players.LocalPlayer.Name .. ".json"
		writefile(path, HttpService:JSONEncode(self.settings))
	end)
end

function SettingsManager:Get(key)
	return self.settings[key]
end

function SettingsManager:Set(key, value)
	self.settings[key] = value
	self:Save()
end

function SettingsManager:Reset()
	if isfolder(CONSTANTS.CONFIG_FOLDER) then
		delfolder(CONSTANTS.CONFIG_FOLDER)
	end
	self.settings = {
		SaveSettings = true,
		LoadAnimation = true,
		PageAnimation = true
	}
end

local settingsManager = SettingsManager.new()

-- Expose global functions for compatibility
getgenv().LoadConfig = function() return settingsManager:Load() end
getgenv().SaveConfig = function() return settingsManager:Save() end

-- Toggle Button Creator
local function CreateToggleButton()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Parent = coreGui
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.ResetOnSpawn = false
	
	local outline = Instance.new("Frame")
	outline.Name = "OutlineButton"
	outline.Parent = screenGui
	outline.BackgroundColor3 = CONSTANTS.DARK
	outline.Position = UDim2.new(0, CONSTANTS.PADDING.MEDIUM, 0, CONSTANTS.PADDING.MEDIUM)
	outline.Size = UDim2.new(0, 50, 0, 50)
	Utils.CreateRounded(outline, 12)
	
	local button = Instance.new("ImageButton")
	button.Parent = outline
	button.AnchorPoint = Vector2.new(0.5, 0.5)
	button.Position = UDim2.new(0.5, 0, 0.5, 0)
	button.Size = UDim2.new(0, 40, 0, 40)
	button.BackgroundColor3 = CONSTANTS.DARK
	button.Image = "rbxassetid://13940080072"
	button.ImageColor3 = Color3.fromRGB(250, 250, 250)
	Utils.CreateRounded(button, 10)
	
	Utils.MakeDraggable(button, outline)
	
	return button, outline
end

-- Notification System
local NotificationSystem = {}
NotificationSystem.__index = NotificationSystem

function NotificationSystem.new()
	local self = setmetatable({}, NotificationSystem)
	
	self.gui = Instance.new("ScreenGui")
	self.gui.Name = "NotificationFrame"
	self.gui.Parent = coreGui
	self.gui.ZIndexBehavior = Enum.ZIndexBehavior.Global
	self.gui.ResetOnSpawn = false
	
	self.notifications = {}
	self.isRunning = true
	
	-- Cleanup task
	task.spawn(function()
		while self.isRunning do
			task.wait(CONSTANTS.NOTIF_DURATION)
			if #self.notifications > 0 then
				self:RemoveOldest()
			end
		end
	end)
	
	return self
end

function NotificationSystem:RemoveOldest()
	if #self.notifications == 0 then return end
	
	local oldest = table.remove(self.notifications, 1)
	if oldest and oldest.Parent then
		Utils.Tween(oldest, {Position = UDim2.new(0.5, 0, -0.2, 0)}, CONSTANTS.TWEEN_TIME.SLOW)
		task.delay(CONSTANTS.TWEEN_TIME.SLOW, function()
			if oldest then oldest:Destroy() end
		end)
	end
end

function NotificationSystem:Notify(message)
	-- Limit notifications
	while #self.notifications >= CONSTANTS.MAX_NOTIFICATIONS do
		self:RemoveOldest()
	end
	
	local frame = Instance.new("Frame")
	frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	frame.BackgroundTransparency = 0.4
	frame.AnchorPoint = Vector2.new(0.5, 1)
	frame.Position = UDim2.new(0.5, 0, -0.2, 0)
	frame.Size = UDim2.new(0, 412, 0, 72)
	frame.Parent = self.gui
	Utils.CreateRounded(frame, 12)
	
	local inner = Instance.new("Frame")
	inner.Parent = frame
	inner.AnchorPoint = Vector2.new(0.5, 0.5)
	inner.Position = UDim2.new(0.5, 0, 0.5, 0)
	inner.Size = UDim2.new(0, 400, 0, 60)
	inner.BackgroundColor3 = CONSTANTS.DARK
	inner.BackgroundTransparency = 0.1
	Utils.CreateRounded(inner, 10)
	
	local icon = Instance.new("ImageLabel")
	icon.Parent = inner
	icon.BackgroundTransparency = 1
	icon.Position = UDim2.new(0, 8, 0, 8)
	icon.Size = UDim2.new(0, 45, 0, 45)
	icon.Image = "rbxassetid://13940080072"
	
	local title = Instance.new("TextLabel")
	title.Parent = inner
	title.BackgroundTransparency = 1
	title.Position = UDim2.new(0, 55, 0, 14)
	title.Size = UDim2.new(0, 300, 0, 20)
	title.Font = Enum.Font.GothamBold
	title.Text = "Vicat Hub"
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextSize = 16
	title.TextXAlignment = Enum.TextXAlignment.Left
	
	local desc = Instance.new("TextLabel")
	desc.Parent = inner
	desc.BackgroundTransparency = 1
	desc.Position = UDim2.new(0, 55, 0, 33)
	desc.Size = UDim2.new(0, 300, 0, 20)
	desc.Font = Enum.Font.GothamSemibold
	desc.Text = message
	desc.TextColor3 = Color3.fromRGB(200, 200, 200)
	desc.TextSize = 12
	desc.TextTransparency = 0.3
	desc.TextXAlignment = Enum.TextXAlignment.Left
	desc.TextTruncate = Enum.TextTruncate.AtEnd
	
	frame:TweenPosition(
		UDim2.new(0.5, 0, 0.1 + (#self.notifications * 0.1), 0),
		Enum.EasingDirection.Out,
		Enum.EasingStyle.Quad,
		CONSTANTS.TWEEN_TIME.SLOW,
		true
	)
	
	table.insert(self.notifications, frame)
end

function NotificationSystem:Destroy()
	self.isRunning = false
	if self.gui then
		self.gui:Destroy()
	end
end

local notificationSystem = NotificationSystem.new()

-- Loading Screen
local LoadingScreen = {}

function LoadingScreen.Show()
	if not settingsManager:Get("LoadAnimation") then return end
	
	local loader = Instance.new("ScreenGui")
	loader.Parent = coreGui
	loader.ZIndexBehavior = Enum.ZIndexBehavior.Global
	loader.DisplayOrder = 1000
	loader.ResetOnSpawn = false
	
	local bg = Instance.new("Frame")
	bg.Parent = loader
	bg.BackgroundColor3 = Color3.fromRGB(5, 5, 5)
	bg.Size = UDim2.new(1.5, 0, 1.5, 0)
	bg.AnchorPoint = Vector2.new(0.5, 0.5)
	bg.Position = UDim2.new(0.5, 0, 0.5, 0)
	bg.BorderSizePixel = 0
	
	local container = Instance.new("Frame")
	container.Parent = bg
	container.BackgroundTransparency = 1
	container.AnchorPoint = Vector2.new(0.5, 0.5)
	container.Position = UDim2.new(0.5, 0, 0.5, 0)
	container.Size = UDim2.new(0.5, 0, 0.5, 0)
	
	local title = Instance.new("TextLabel")
	title.Parent = container
	title.Text = "Vicat Hub"
	title.Font = Enum.Font.FredokaOne
	title.TextSize = 50
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.BackgroundTransparency = 1
	title.AnchorPoint = Vector2.new(0.5, 0.5)
	title.Position = UDim2.new(0.5, 0, 0.3, 0)
	title.Size = UDim2.new(0.8, 0, 0.2, 0)
	
	local status = Instance.new("TextLabel")
	status.Parent = container
	status.Text = "Loading"
	status.Font = Enum.Font.Gotham
	status.TextSize = 15
	status.TextColor3 = Color3.fromRGB(255, 255, 255)
	status.BackgroundTransparency = 1
	status.AnchorPoint = Vector2.new(0.5, 0.5)
	status.Position = UDim2.new(0.5, 0, 0.6, 0)
	status.Size = UDim2.new(0.8, 0, 0.2, 0)
	
	local barBg = Instance.new("Frame")
	barBg.Parent = container
	barBg.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	barBg.AnchorPoint = Vector2.new(0.5, 0.5)
	barBg.Position = UDim2.new(0.5, 0, 0.7, 0)
	barBg.Size = UDim2.new(0.7, 0, 0.05, 0)
	barBg.ClipsDescendants = true
	barBg.BorderSizePixel = 0
	Utils.CreateRounded(barBg, 20)
	
	local bar = Instance.new("Frame")
	bar.Parent = barBg
	bar.BackgroundColor3 = CONSTANTS.ACCENT
	bar.Size = UDim2.new(0, 0, 1, 0)
	bar.BorderSizePixel = 0
	Utils.CreateRounded(bar, 20)
	
	local running = true
	local dotCount = 0
	
	-- Animate dots
	task.spawn(function()
		while running do
			dotCount = (dotCount + 1) % 4
			status.Text = "Please wait" .. string.rep(".", dotCount)
			task.wait(0.5)
		end
	end)
	
	-- Animate bar
	local tween1 = Utils.Tween(bar, {Size = UDim2.new(0.25, 0, 1, 0)}, 0.5, Enum.EasingStyle.Linear)
	
	tween1.Completed:Connect(function()
		local tween2 = Utils.Tween(bar, {Size = UDim2.new(1, 0, 1, 0)}, 1, Enum.EasingStyle.Linear)
		tween2.Completed:Connect(function()
			task.wait(0.5)
			running = false
			status.Text = "Loaded!"
			task.wait(0.5)
			loader:Destroy()
		end)
	end)
end

-- Main Library
local Update = {}

Update.Notify = function(_, message)
	notificationSystem:Notify(message)
end

Update.StartLoad = function(_)
	LoadingScreen.Show()
end

function Update:Window(config)
	assert(config.SubTitle, "SubTitle is required")
	
	local windowConfig = {
		Size = config.Size or UDim2.new(0, 600, 0, 400),
		TabWidth = config.TabWidth or 150
	}
	
	-- Main GUI
	local gui = Instance.new("ScreenGui")
	gui.Name = "VicatHub"
	gui.Parent = coreGui
	gui.DisplayOrder = 999
	gui.ResetOnSpawn = false
	
	-- Outline
	local outline = Instance.new("Frame")
	outline.Name = "OutlineMain"
	outline.Parent = gui
	outline.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	outline.BackgroundTransparency = 0.4
	outline.AnchorPoint = Vector2.new(0.5, 0.5)
	outline.Position = UDim2.new(0.5, 0, 0.45, 0)
	outline.Size = UDim2.new(0, 0, 0, 0)
	Utils.CreateRounded(outline, 15)
	
	-- Main Frame
	local main = Instance.new("Frame")
	main.Name = "Main"
	main.Parent = outline
	main.BackgroundColor3 = CONSTANTS.BACKGROUND_DARK
	main.AnchorPoint = Vector2.new(0.5, 0.5)
	main.Position = UDim2.new(0.5, 0, 0.5, 0)
	main.Size = windowConfig.Size
	Utils.CreateRounded(main, 12)
	
	outline:TweenSize(
		UDim2.new(0, windowConfig.Size.X.Offset + 15, 0, windowConfig.Size.Y.Offset + 15),
		Enum.EasingDirection.Out,
		Enum.EasingStyle.Quad,
		CONSTANTS.TWEEN_TIME.SLOW,
		true
	)
	
	-- Top Bar
	local top = Instance.new("Frame")
	top.Name = "Top"
	top.Parent = main
	top.BackgroundTransparency = 1
	top.Size = UDim2.new(1, 0, 0, CONSTANTS.TOP_BAR_HEIGHT)
	Utils.CreateRounded(top, 5)
	
	-- Title
	local nameHub = Instance.new("TextLabel")
	nameHub.Parent = top
	nameHub.BackgroundTransparency = 1
	nameHub.Position = UDim2.new(0, CONSTANTS.PADDING.LARGE, 0.5, 0)
	nameHub.AnchorPoint = Vector2.new(0, 0.5)
	nameHub.Font = Enum.Font.GothamBold
	nameHub.Text = "Vicat Hub"
	nameHub.TextSize = 20
	nameHub.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameHub.TextXAlignment = Enum.TextXAlignment.Left
	nameHub.ZIndex = 5
	
	local nameSize = Utils.GetTextSize(nameHub.Text, nameHub.TextSize, nameHub.Font)
	nameHub.Size = UDim2.new(0, nameSize.X, 0, 25)
	
	-- Subtitle
	local subTitle = Instance.new("TextLabel")
	subTitle.Parent = top
	subTitle.BackgroundTransparency = 1
	subTitle.Position = UDim2.new(0, CONSTANTS.PADDING.LARGE + nameSize.X + 8, 0.5, 0)
	subTitle.AnchorPoint = Vector2.new(0, 0.5)
	subTitle.Font = Enum.Font.Cartoon
	subTitle.Text = config.SubTitle
	subTitle.TextSize = 15
	subTitle.TextColor3 = Color3.fromRGB(150, 150, 150)
	subTitle.ZIndex = 5
	
	local subSize = Utils.GetTextSize(subTitle.Text, subTitle.TextSize, subTitle.Font)
	subTitle.Size = UDim2.new(0, subSize.X, 0, 25)
	
	-- Settings Panel (create first for reference)
	local settingsPanel = CreateSettingsPanel(outline, settingsManager)
	
	-- Buttons
	CreateTopBarButtons(top, gui, outline, main, windowConfig, settingsPanel)
	
	-- Tab Container
	local tabContainer = Instance.new("Frame")
	tabContainer.Name = "Tab"
	tabContainer.Parent = main
	tabContainer.BackgroundTransparency = 1
	tabContainer.Position = UDim2.new(0, 8, 0, CONSTANTS.TOP_BAR_HEIGHT)
	tabContainer.Size = UDim2.new(0, windowConfig.TabWidth, 0, windowConfig.Size.Y.Offset - CONSTANTS.TOP_BAR_HEIGHT - 8)
	Utils.CreateRounded(tabContainer, 5)
	
	local scrollTab = Instance.new("ScrollingFrame")
	scrollTab.Parent = tabContainer
	scrollTab.BackgroundTransparency = 1
	scrollTab.Size = UDim2.new(1, 0, 1, 0)
	scrollTab.ScrollBarThickness = 0
	scrollTab.BorderSizePixel = 0
	
	local tabLayout = Instance.new("UIListLayout")
	tabLayout.Parent = scrollTab
	tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
	tabLayout.Padding = UDim.new(0, 2)
	
	Utils.CreatePadding(scrollTab, 0, 0, 0, 0)
	
	-- Page Container
	local page = Instance.new("Frame")
	page.Name = "Page"
	page.Parent = main
	page.BackgroundTransparency = 1
	page.Position = UDim2.new(0, windowConfig.TabWidth + 18, 0, CONSTANTS.TOP_BAR_HEIGHT)
	page.Size = UDim2.new(0, windowConfig.Size.X.Offset - windowConfig.TabWidth - 25, 0, windowConfig.Size.Y.Offset - CONSTANTS.TOP_BAR_HEIGHT - 8)
	page.ClipsDescendants = true
	Utils.CreateRounded(page, 3)
	
	local mainPage = Instance.new("Frame")
	mainPage.Parent = page
	mainPage.BackgroundTransparency = 1
	mainPage.Size = UDim2.new(1, 0, 1, 0)
	mainPage.ClipsDescendants = true
	
	local pageList = Instance.new("Folder")
	pageList.Name = "PageList"
	pageList.Parent = mainPage
	
	-- Auto-resize canvas
	globalConnections:Add(RunService.Heartbeat:Connect(function()
		Utils.SafeCall(function()
			scrollTab.CanvasSize = UDim2.new(0, 0, 0, tabLayout.AbsoluteContentSize.Y)
		end)
	end))
	
	Utils.MakeDraggable(top, outline)
	
	-- Toggle with Insert key
	globalConnections:Add(UserInputService.InputBegan:Connect(function(input)
		if input.KeyCode == Enum.KeyCode.Insert then
			gui.Enabled = not gui.Enabled
		end
	end))
	
	-- Tab System
	local tabSystem = CreateTabSystem(scrollTab, pageList, settingsManager)
	
	return tabSystem
end

-- Settings Panel Creator
function CreateSettingsPanel(parent, settingsManager)
	local bg = Instance.new("Frame")
	bg.Name = "BackgroundSettings"
	bg.Parent = parent
	bg.Active = true
	bg.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
	bg.BackgroundTransparency = 0.3
	bg.Size = UDim2.new(1, 0, 1, 0)
	bg.Visible = false
	bg.ZIndex = 10
	Utils.CreateRounded(bg, 15)
	
	local frame = Instance.new("Frame")
	frame.Parent = bg
	frame.BackgroundColor3 = CONSTANTS.BACKGROUND_DARK
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = UDim2.new(0.5, 0, 0.5, 0)
	frame.Size = UDim2.new(0.7, 0, 0.7, 0)
	frame.ZIndex = 11
	Utils.CreateRounded(frame, 15)
	
	local closeBtn = Instance.new("ImageButton")
	closeBtn.Parent = frame
	closeBtn.BackgroundTransparency = 1
	closeBtn.AnchorPoint = Vector2.new(1, 0)
	closeBtn.Position = UDim2.new(1, -CONSTANTS.PADDING.LARGE, 0, CONSTANTS.PADDING.LARGE)
	closeBtn.Size = UDim2.new(0, CONSTANTS.BUTTON_SIZE, 0, CONSTANTS.BUTTON_SIZE)
	closeBtn.Image = "rbxassetid://10747384394"
	closeBtn.ImageColor3 = Color3.fromRGB(245, 245, 245)
	closeBtn.ZIndex = 12
	Utils.CreateRounded(closeBtn, 3)
	
	closeBtn.MouseButton1Click:Connect(function()
		bg.Visible = false
	end)
	
	local title = Instance.new("TextLabel")
	title.Parent = frame
	title.BackgroundTransparency = 1
	title.Position = UDim2.new(0, CONSTANTS.PADDING.XLARGE, 0, CONSTANTS.PADDING.LARGE)
	title.Size = UDim2.new(1, 0, 0, CONSTANTS.BUTTON_SIZE)
	title.Font = Enum.Font.GothamBold
	title.Text = "Library Settings"
	title.TextSize = 20
	title.TextColor3 = Color3.fromRGB(245, 245, 245)
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.ZIndex = 12
	
	local scroll = Instance.new("ScrollingFrame")
	scroll.Parent = frame
	scroll.BackgroundTransparency = 1
	scroll.Position = UDim2.new(0, 0, 0, 50)
	scroll.Size = UDim2.new(1, 0, 1, -70)
	scroll.ScrollBarThickness = 3
	scroll.ZIndex = 11
	scroll.BorderSizePixel = 0
	
	local layout = Instance.new("UIListLayout")
	layout.Parent = scroll
	layout.Padding = UDim.new(0, 8)
	
	Utils.CreatePadding(scroll, CONSTANTS.PADDING.XLARGE, CONSTANTS.PADDING.XLARGE, 0, 0)
	
	-- Add settings options
	local function CreateCheckbox(title, state, callback)
		local checked = state
		
		local container = Instance.new("Frame")
		container.Parent = scroll
		container.BackgroundTransparency = 1
		container.Size = UDim2.new(1, 0, 0, 20)
		container.ZIndex = 11
		
		local label = Instance.new("TextLabel")
		label.Parent = container
		label.BackgroundTransparency = 1
		label.Position = UDim2.new(0, 60, 0.5, 0)
		label.AnchorPoint = Vector2.new(0, 0.5)
		label.Size = UDim2.new(1, -60, 0, 20)
		label.Font = Enum.Font.Code
		label.Text = title
		label.TextSize = 15
		label.TextColor3 = Color3.fromRGB(200, 200, 200)
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.ZIndex = 12
		
		local checkbox = Instance.new("ImageButton")
		checkbox.Parent = container
		checkbox.BackgroundColor3 = checked and CONSTANTS.ACCENT or CONSTANTS.PRIMARY
		checkbox.AnchorPoint = Vector2.new(0, 0.5)
		checkbox.Position = UDim2.new(0, 30, 0.5, 0)
		checkbox.Size = UDim2.new(0, 20, 0, 20)
		checkbox.Image = "rbxassetid://10709790644"
		checkbox.ImageTransparency = checked and 0 or 1
		checkbox.ImageColor3 = Color3.fromRGB(245, 245, 245)
		checkbox.ZIndex = 12
		Utils.CreateRounded(checkbox, 5)
		
		checkbox.MouseButton1Click:Connect(function()
			checked = not checked
			Utils.Tween(checkbox, {
				BackgroundColor3 = checked and CONSTANTS.ACCENT or CONSTANTS.PRIMARY,
				ImageTransparency = checked and 0 or 1
			}, CONSTANTS.TWEEN_TIME.FAST)
			Utils.SafeCall(callback, checked)
		end)
		
		Utils.SafeCall(callback, checked)
	end
	
	local function CreateButton(title, callback)
		local container = Instance.new("Frame")
		container.Parent = scroll
		container.BackgroundTransparency = 1
		container.Size = UDim2.new(1, 0, 0, 30)
		container.ZIndex = 11
		
		local btn = Instance.new("TextButton")
		btn.Parent = container
		btn.BackgroundColor3 = CONSTANTS.ACCENT
		btn.Size = UDim2.new(0.8, 0, 0, 30)
		btn.Font = Enum.Font.Code
		btn.Text = title
		btn.AnchorPoint = Vector2.new(0.5, 0)
		btn.Position = UDim2.new(0.5, 0, 0, 0)
		btn.TextColor3 = Color3.fromRGB(255, 255, 255)
		btn.TextSize = 15
		btn.AutoButtonColor = false
		btn.ZIndex = 12
		Utils.CreateRounded(btn, 5)
		
		btn.MouseButton1Click:Connect(function()
			Utils.SafeCall(callback)
		end)
	end
	
	CreateCheckbox("Save Settings", settingsManager:Get("SaveSettings"), function(state)
		settingsManager:Set("SaveSettings", state)
	end)
	
	CreateCheckbox("Loading Animation", settingsManager:Get("LoadAnimation"), function(state)
		settingsManager:Set("LoadAnimation", state)
	end)
	
	CreateCheckbox("Page Animation", settingsManager:Get("PageAnimation"), function(state)
		settingsManager:Set("PageAnimation", state)
	end)
	
	CreateButton("Reset Config", function()
		settingsManager:Reset()
		notificationSystem:Notify("Config has been reset!")
	end)
	
	-- Auto-resize
	globalConnections:Add(RunService.Heartbeat:Connect(function()
		Utils.SafeCall(function()
			scroll.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y)
		end)
	end))
	
	return bg
end

-- Top Bar Buttons Creator
function CreateTopBarButtons(top, gui, outline, main, windowConfig, settingsPanel)
	local buttonSpacing = 35
	
	-- Close Button
	local closeBtn = Instance.new("ImageButton")
	closeBtn.Parent = top
	closeBtn.BackgroundTransparency = 1
	closeBtn.AnchorPoint = Vector2.new(1, 0.5)
	closeBtn.Position = UDim2.new(1, -CONSTANTS.PADDING.LARGE, 0.5, 0)
	closeBtn.Size = UDim2.new(0, CONSTANTS.BUTTON_SIZE, 0, CONSTANTS.BUTTON_SIZE)
	closeBtn.Image = "rbxassetid://7743878857"
	closeBtn.ImageColor3 = Color3.fromRGB(245, 245, 245)
	closeBtn.ZIndex = 5
	Utils.CreateRounded(closeBtn, 3)
	
	closeBtn.MouseButton1Click:Connect(function()
		gui.Enabled = not gui.Enabled
	end)
	
	-- Resize Button
	local resizeBtn = Instance.new("ImageButton")
	resizeBtn.Parent = top
	resizeBtn.BackgroundTransparency = 1
	resizeBtn.AnchorPoint = Vector2.new(1, 0.5)
	resizeBtn.Position = UDim2.new(1, -CONSTANTS.PADDING.LARGE - buttonSpacing, 0.5, 0)
	resizeBtn.Size = UDim2.new(0, CONSTANTS.BUTTON_SIZE, 0, CONSTANTS.BUTTON_SIZE)
	resizeBtn.Image = "rbxassetid://10734886735"
	resizeBtn.ImageColor3 = Color3.fromRGB(245, 245, 245)
	resizeBtn.ZIndex = 5
	Utils.CreateRounded(resizeBtn, 3)
	
	local isFullscreen = false
	local resizeConnection
	
	resizeBtn.MouseButton1Click:Connect(function()
		if resizeConnection then
			resizeConnection:Disconnect()
			resizeConnection = nil
		end
		
		isFullscreen = not isFullscreen
		
		local tweenTime = CONSTANTS.TWEEN_TIME.SLOW
		
		if isFullscreen then
			outline:TweenPosition(UDim2.new(0.5, 0, 0.5, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, tweenTime * 0.5, true)
			outline:TweenSize(UDim2.new(1, -10, 1, -10), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, tweenTime, true)
			Utils.Tween(main, {Size = UDim2.new(1, -20, 1, -20)}, tweenTime)
			resizeBtn.Image = "rbxassetid://10734895698"
		else
			outline:TweenSize(UDim2.new(0, windowConfig.Size.X.Offset + 15, 0, windowConfig.Size.Y.Offset + 15), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, tweenTime, true)
			outline:TweenPosition(UDim2.new(0.5, 0, 0.45, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, tweenTime * 0.5, true)
			Utils.Tween(main, {Size = windowConfig.Size}, tweenTime)
			resizeBtn.Image = "rbxassetid://10734886735"
		end
		
		-- Update children dynamically
		local page = main:FindFirstChild("Page")
		local tab = main:FindFirstChild("Tab")
		
		if page and tab then
			resizeConnection = globalConnections:Add(RunService.RenderStepped:Connect(function()
				Utils.SafeCall(function()
					local newPageWidth = main.AbsoluteSize.X - tab.AbsoluteSize.X - 25
					local newPageHeight = main.AbsoluteSize.Y - CONSTANTS.TOP_BAR_HEIGHT - 10
					
					page.Size = UDim2.new(0, newPageWidth, 0, newPageHeight)
					tab.Size = UDim2.new(0, windowConfig.TabWidth, 0, newPageHeight)
				end)
			end))
			
			task.delay(tweenTime + 0.1, function()
				if resizeConnection then
					resizeConnection:Disconnect()
					resizeConnection = nil
				end
			end)
		end
	end)
	
	-- Settings Button
	local settingsBtn = Instance.new("ImageButton")
	settingsBtn.Parent = top
	settingsBtn.BackgroundTransparency = 1
	settingsBtn.AnchorPoint = Vector2.new(1, 0.5)
	settingsBtn.Position = UDim2.new(1, -CONSTANTS.PADDING.LARGE - buttonSpacing * 2, 0.5, 0)
	settingsBtn.Size = UDim2.new(0, CONSTANTS.BUTTON_SIZE, 0, CONSTANTS.BUTTON_SIZE)
	settingsBtn.Image = "rbxassetid://10734950020"
	settingsBtn.ImageColor3 = Color3.fromRGB(245, 245, 245)
	settingsBtn.ZIndex = 5
	Utils.CreateRounded(settingsBtn, 3)
	
	settingsBtn.MouseButton1Click:Connect(function()
		settingsPanel.Visible = true
	end)
end

-- Tab System Creator
function CreateTabSystem(scrollTab, pageList, settingsManager)
	local uitab = {}
	local tabIndex = 0
	local currentTabIndex = 0
	local firstTab = true
	
	function uitab:Tab(text, img)
		local thisTabIndex = tabIndex
		tabIndex = tabIndex + 1
		
		local tabButton = Instance.new("TextButton")
		tabButton.Name = text .. "Tab"
		tabButton.Parent = scrollTab
		tabButton.Text = ""
		tabButton.BackgroundColor3 = CONSTANTS.PRIMARY
		tabButton.BackgroundTransparency = 1
		tabButton.Size = UDim2.new(1, 0, 0, CONSTANTS.TAB_HEIGHT)
		tabButton.LayoutOrder = thisTabIndex
		Utils.CreateRounded(tabButton, 6)
		
		local selectedTab = Instance.new("Frame")
		selectedTab.Name = "SelectedTab"
		selectedTab.Parent = tabButton
		selectedTab.BackgroundColor3 = CONSTANTS.ACCENT
		selectedTab.Size = UDim2.new(0, 3, 0, 0)
		selectedTab.Position = UDim2.new(0, 0, 0.5, 0)
		selectedTab.AnchorPoint = Vector2.new(0, 0.5)
		Utils.CreateRounded(selectedTab, 100)
		
		local icon = Instance.new("ImageLabel")
		icon.Name = "Icon"
		icon.Parent = tabButton
		icon.BackgroundTransparency = 1
		icon.Position = UDim2.new(0, 7, 0.5, 0)
		icon.AnchorPoint = Vector2.new(0, 0.5)
		icon.Size = UDim2.new(0, CONSTANTS.ICON_SIZE, 0, CONSTANTS.ICON_SIZE)
		icon.Image = img
		icon.ImageTransparency = 0.3
		
		local title = Instance.new("TextLabel")
		title.Name = "Title"
		title.Parent = tabButton
		title.BackgroundTransparency = 1
		title.Position = UDim2.new(0, 30, 0.5, 0)
		title.AnchorPoint = Vector2.new(0, 0.5)
		title.Size = UDim2.new(0, 100, 0, 30)
		title.Font = Enum.Font.Roboto
		title.Text = text
		title.TextColor3 = Color3.fromRGB(255, 255, 255)
		title.TextTransparency = 0.4
		title.TextSize = 14
		title.TextXAlignment = Enum.TextXAlignment.Left
		
		-- Page
		local mainFramePage = Instance.new("ScrollingFrame")
		mainFramePage.Name = text .. "_Page"
		mainFramePage.Parent = pageList
		mainFramePage.BackgroundTransparency = 1
		mainFramePage.Size = UDim2.new(1, 0, 1, 0)
		mainFramePage.ScrollBarThickness = 0
		mainFramePage.BorderSizePixel = 0
		mainFramePage.Visible = false
		mainFramePage.ClipsDescendants = true
		mainFramePage.Position = UDim2.new(0, 0, 0, 0)
		
		local uiListLayout = Instance.new("UIListLayout")
		uiListLayout.Parent = mainFramePage
		uiListLayout.Padding = UDim.new(0, 3)
		uiListLayout.SortOrder = Enum.SortOrder.LayoutOrder
		
		Utils.CreatePadding(mainFramePage, 0, 0, 0, 0)
		
		-- Tab Click Handler
		tabButton.MouseButton1Click:Connect(function()
			if thisTabIndex == currentTabIndex then return end
			
			-- Deselect all tabs
			for _, v in pairs(scrollTab:GetChildren()) do
				if v:IsA("TextButton") then
					Utils.Tween(v, {BackgroundTransparency = 1}, CONSTANTS.TWEEN_TIME.FAST)
					Utils.Tween(v.SelectedTab, {Size = UDim2.new(0, 3, 0, 0)}, CONSTANTS.TWEEN_TIME.FAST)
					Utils.Tween(v.Icon, {ImageTransparency = 0.4}, CONSTANTS.TWEEN_TIME.FAST)
					Utils.Tween(v.Title, {TextTransparency = 0.4}, CONSTANTS.TWEEN_TIME.FAST)
				end
			end
			
			-- Hide all pages
			for _, v in pairs(pageList:GetChildren()) do
				if v:IsA("ScrollingFrame") then
					v.Visible = false
				end
			end
			
			-- Show selected page
			mainFramePage.Visible = true
			
			-- Highlight selected tab
			Utils.Tween(tabButton, {BackgroundTransparency = 0.8}, CONSTANTS.TWEEN_TIME.FAST)
			Utils.Tween(selectedTab, {Size = UDim2.new(0, 3, 0, 15)}, CONSTANTS.TWEEN_TIME.FAST)
			Utils.Tween(icon, {ImageTransparency = 0}, CONSTANTS.TWEEN_TIME.FAST)
			Utils.Tween(title, {TextTransparency = 0}, CONSTANTS.TWEEN_TIME.FAST)
			
			-- Page animation
			if settingsManager:Get("PageAnimation") then
				if thisTabIndex > currentTabIndex then
					-- Slide down
					mainFramePage.Position = UDim2.new(0, 0, 1, 0)
					mainFramePage:TweenPosition(UDim2.new(0, 0, 0, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, CONSTANTS.TWEEN_TIME.NORMAL, true)
				else
					-- Slide up
					mainFramePage.Position = UDim2.new(0, 0, -1, 0)
					mainFramePage:TweenPosition(UDim2.new(0, 0, 0, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, CONSTANTS.TWEEN_TIME.NORMAL, true)
				end
			else
				mainFramePage.Position = UDim2.new(0, 0, 0, 0)
			end
			
			currentTabIndex = thisTabIndex
		end)
		
		-- Select first tab
		if firstTab then
			mainFramePage.Visible = true
			mainFramePage.Position = UDim2.new(0, 0, 0, 0)
			
			Utils.Tween(tabButton, {BackgroundTransparency = 0.8}, CONSTANTS.TWEEN_TIME.FAST)
			Utils.Tween(selectedTab, {Size = UDim2.new(0, 3, 0, 15)}, CONSTANTS.TWEEN_TIME.FAST)
			Utils.Tween(icon, {ImageTransparency = 0}, CONSTANTS.TWEEN_TIME.FAST)
			Utils.Tween(title, {TextTransparency = 0}, CONSTANTS.TWEEN_TIME.FAST)
			
			currentTabIndex = 0
			firstTab = false
		end
		
		-- Auto-resize canvas
		globalConnections:Add(RunService.Heartbeat:Connect(function()
			Utils.SafeCall(function()
				mainFramePage.CanvasSize = UDim2.new(0, 0, 0, uiListLayout.AbsoluteContentSize.Y)
			end)
		end))
		
		-- Components
		local components = CreateComponents(mainFramePage, settingsManager)
		return components
	end
	
	return uitab
end

-- Components Creator
function CreateComponents(parent, settingsManager)
	local components = {}
	
	-- Button Component
	function components:Button(text, callback)
		local button = Instance.new("Frame")
		button.Name = "Button"
		button.Parent = parent
		button.BackgroundTransparency = 1
		button.Size = UDim2.new(1, 0, 0, 36)
		Utils.CreateRounded(button, 5)
		
		local label = Instance.new("TextLabel")
		label.Parent = button
		label.BackgroundTransparency = 1
		label.Position = UDim2.new(0, CONSTANTS.PADDING.XLARGE, 0.5, 0)
		label.AnchorPoint = Vector2.new(0, 0.5)
		label.Size = UDim2.new(1, -50, 1, 0)
		label.Font = Enum.Font.Cartoon
		label.Text = text
		label.TextColor3 = Color3.fromRGB(255, 255, 255)
		label.TextSize = 15
		label.TextXAlignment = Enum.TextXAlignment.Left
		
		local btn = Instance.new("TextButton")
		btn.Parent = button
		btn.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
		btn.BackgroundTransparency = 0.8
		btn.AnchorPoint = Vector2.new(1, 0.5)
		btn.Position = UDim2.new(1, -1, 0.5, 0)
		btn.Size = UDim2.new(0, 25, 0, 25)
		btn.Text = ""
		Utils.CreateRounded(btn, 4)
		
		local img = Instance.new("ImageLabel")
		img.Parent = btn
		img.BackgroundTransparency = 1
		img.AnchorPoint = Vector2.new(0.5, 0.5)
		img.Position = UDim2.new(0.5, 0, 0.5, 0)
		img.Size = UDim2.new(0, CONSTANTS.ICON_SIZE, 0, CONSTANTS.ICON_SIZE)
		img.Image = "rbxassetid://10734898355"
		img.ImageColor3 = Color3.fromRGB(255, 255, 255)
		
		btn.MouseButton1Click:Connect(function()
			Utils.SafeCall(callback)
		end)
	end
	
	-- Toggle Component
	function components:Toggle(text, config, desc, callback)
		local toggled = config or false
		
		local button = Instance.new("TextButton")
		button.Name = "Toggle"
		button.Parent = parent
		button.BackgroundColor3 = CONSTANTS.PRIMARY
		button.BackgroundTransparency = 0.8
		button.AutoButtonColor = false
		button.Text = ""
		button.Size = UDim2.new(1, 0, 0, desc and 46 or 36)
		Utils.CreateRounded(button, 5)
		
		local titleLabel = Instance.new("TextLabel")
		titleLabel.Parent = button
		titleLabel.BackgroundTransparency = 1
		titleLabel.Size = UDim2.new(1, 0, 0, 35)
		titleLabel.Font = Enum.Font.Cartoon
		titleLabel.Text = text
		titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		titleLabel.TextSize = 15
		titleLabel.TextXAlignment = Enum.TextXAlignment.Left
		titleLabel.AnchorPoint = Vector2.new(0, 0.5)
		titleLabel.Position = UDim2.new(0, CONSTANTS.PADDING.LARGE, 0.5, desc and -5 or 0)
		
		if desc then
			local descLabel = Instance.new("TextLabel")
			descLabel.Parent = titleLabel
			descLabel.BackgroundTransparency = 1
			descLabel.Position = UDim2.new(0, 0, 0, 22)
			descLabel.Size = UDim2.new(0, 280, 0, 16)
			descLabel.Font = Enum.Font.Gotham
			descLabel.Text = desc
			descLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
			descLabel.TextSize = 10
			descLabel.TextXAlignment = Enum.TextXAlignment.Left
		end
		
		local toggleFrame = Instance.new("Frame")
		toggleFrame.Parent = button
		toggleFrame.BackgroundTransparency = 1
		toggleFrame.Position = UDim2.new(1, -CONSTANTS.PADDING.MEDIUM, 0.5, 0)
		toggleFrame.Size = UDim2.new(0, 35, 0, 20)
		toggleFrame.AnchorPoint = Vector2.new(1, 0.5)
		Utils.CreateRounded(toggleFrame, 10)
		
		local toggleBg = Instance.new("TextButton")
		toggleBg.Parent = toggleFrame
		toggleBg.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
		toggleBg.BackgroundTransparency = 0.8
		toggleBg.Size = UDim2.new(1, 0, 1, 0)
		toggleBg.Text = ""
		toggleBg.AutoButtonColor = false
		Utils.CreateRounded(toggleBg, 10)
		
		local circle = Instance.new("Frame")
		circle.Parent = toggleBg
		circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		circle.Position = UDim2.new(0, 3, 0.5, 0)
		circle.Size = UDim2.new(0, 14, 0, 14)
		circle.AnchorPoint = Vector2.new(0, 0.5)
		Utils.CreateRounded(circle, 10)
		
		toggleBg.MouseButton1Click:Connect(function()
			toggled = not toggled
			
			if toggled then
				circle:TweenPosition(UDim2.new(0, 17, 0.5, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Sine, 0.2, true)
				Utils.Tween(toggleBg, {
					BackgroundColor3 = CONSTANTS.ACCENT,
					BackgroundTransparency = 0
				}, CONSTANTS.TWEEN_TIME.SLOW)
			else
				circle:TweenPosition(UDim2.new(0, 4, 0.5, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Sine, 0.2, true)
				Utils.Tween(toggleBg, {
					BackgroundColor3 = Color3.fromRGB(200, 200, 200),
					BackgroundTransparency = 0.8
				}, CONSTANTS.TWEEN_TIME.SLOW)
			end
			
			Utils.SafeCall(callback, toggled)
		end)
		
		if config then
			circle.Position = UDim2.new(0, 17, 0.5, 0)
			toggleBg.BackgroundColor3 = CONSTANTS.ACCENT
			toggleBg.BackgroundTransparency = 0
			Utils.SafeCall(callback, toggled)
		end
	end
	
	-- Slider Component
	function components:Slider(text, min, max, set, callback)
		local value = set or min
		
		local slider = Instance.new("Frame")
		slider.Name = "Slider"
		slider.Parent = parent
		slider.BackgroundTransparency = 1
		slider.Size = UDim2.new(1, 0, 0, 50)
		
		local sliderr = Instance.new("Frame")
		sliderr.Parent = slider
		sliderr.BackgroundColor3 = CONSTANTS.PRIMARY
		sliderr.BackgroundTransparency = 0.8
		sliderr.Size = UDim2.new(1, 0, 1, 0)
		Utils.CreateRounded(sliderr, 5)
		
		local title = Instance.new("TextLabel")
		title.Parent = sliderr
		title.BackgroundTransparency = 1
		title.Position = UDim2.new(0, CONSTANTS.PADDING.LARGE, 0, 8)
		title.Size = UDim2.new(1, -100, 0, 20)
		title.Font = Enum.Font.Cartoon
		title.Text = text
		title.TextColor3 = Color3.fromRGB(255, 255, 255)
		title.TextSize = 15
		title.TextXAlignment = Enum.TextXAlignment.Left
		
		-- TextBox for value input
		local valueBox = Instance.new("TextBox")
		valueBox.Parent = sliderr
		valueBox.BackgroundColor3 = CONSTANTS.SLIDER_TEXT_BG
		valueBox.BorderSizePixel = 0
		valueBox.Position = UDim2.new(1, -65, 0, 5)
		valueBox.Size = UDim2.new(0, 55, 0, 22)
		valueBox.Font = Enum.Font.GothamBold
		valueBox.Text = tostring(set)
		valueBox.TextColor3 = Color3.fromRGB(255, 255, 255)
		valueBox.TextSize = 13
		valueBox.ClearTextOnFocus = false
		Utils.CreateRounded(valueBox, 4)
		
		local barContainer = Instance.new("Frame")
		barContainer.Parent = sliderr
		barContainer.BackgroundTransparency = 1
		barContainer.Position = UDim2.new(0, CONSTANTS.PADDING.LARGE, 1, -20)
		barContainer.Size = UDim2.new(1, -30, 0, 15)
		
		local bar = Instance.new("Frame")
		bar.Parent = barContainer
		bar.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
		bar.BackgroundTransparency = 0.8
		bar.Position = UDim2.new(0, 0, 0.5, 0)
		bar.AnchorPoint = Vector2.new(0, 0.5)
		bar.Size = UDim2.new(1, 0, 0, 4)
		Utils.CreateRounded(bar, 5)
		
		local bar1 = Instance.new("Frame")
		bar1.Parent = bar
		bar1.BackgroundColor3 = CONSTANTS.ACCENT
		bar1.Size = UDim2.new((set - min) / (max - min), 0, 1, 0)
		Utils.CreateRounded(bar1, 5)
		
		local circlebar = Instance.new("Frame")
		circlebar.Parent = bar1
		circlebar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		circlebar.Position = UDim2.new(1, 0, 0.5, 0)
		circlebar.AnchorPoint = Vector2.new(0.5, 0.5)
		circlebar.Size = UDim2.new(0, 15, 0, 15)
		Utils.CreateRounded(circlebar, 100)
		
		local function updateValue(newValue)
			newValue = math.clamp(tonumber(newValue) or min, min, max)
			value = newValue
			valueBox.Text = tostring(value)
			local percentage = (value - min) / (max - min)
			bar1.Size = UDim2.new(percentage, 0, 1, 0)
			Utils.SafeCall(callback, value)
		end
		
		valueBox.FocusLost:Connect(function()
			local inputValue = tonumber(valueBox.Text)
			if inputValue then
				updateValue(inputValue)
			else
				valueBox.Text = tostring(value)
			end
		end)
		
		local dragging = false
		
		circlebar.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or 
			   input.UserInputType == Enum.UserInputType.Touch then
				dragging = true
			end
		end)
		
		bar.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or 
			   input.UserInputType == Enum.UserInputType.Touch then
				dragging = true
			end
		end)
		
		globalConnections:Add(UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or 
			   input.UserInputType == Enum.UserInputType.Touch then
				dragging = false
			end
		end))
		
		globalConnections:Add(UserInputService.InputChanged:Connect(function(input)
			if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or 
			   input.UserInputType == Enum.UserInputType.Touch) then
				local percentage = math.clamp((input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
				local newValue = math.floor(min + (max - min) * percentage)
				updateValue(newValue)
			end
		end))
	end
	
	-- Dropdown Component
	function components:Dropdown(text, options, var, callback)
		local isdropping = false
		local activeItem = var
		
		local dropdown = Instance.new("Frame")
		dropdown.Name = "Dropdown"
		dropdown.Parent = parent
		dropdown.BackgroundColor3 = CONSTANTS.PRIMARY
		dropdown.BackgroundTransparency = 0.8
		dropdown.Size = UDim2.new(1, 0, 0, 40)
		Utils.CreateRounded(dropdown, 5)
		
		local dropTitle = Instance.new("TextLabel")
		dropTitle.Parent = dropdown
		dropTitle.BackgroundTransparency = 1
		dropTitle.Position = UDim2.new(0, CONSTANTS.PADDING.LARGE, 0, 5)
		dropTitle.Size = UDim2.new(1, 0, 0, 30)
		dropTitle.Font = Enum.Font.Cartoon
		dropTitle.Text = text
		dropTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
		dropTitle.TextSize = 15
		dropTitle.TextXAlignment = Enum.TextXAlignment.Left
		
		local selectItems = Instance.new("TextButton")
		selectItems.Parent = dropdown
		selectItems.BackgroundColor3 = CONSTANTS.BACKGROUND_DARK
		selectItems.Position = UDim2.new(1, -5, 0, 5)
		selectItems.AnchorPoint = Vector2.new(1, 0)
		selectItems.Size = UDim2.new(0, 100, 0, 30)
		selectItems.Font = Enum.Font.GothamMedium
		selectItems.Text = "   " .. (var or "Select Items")
		selectItems.TextColor3 = Color3.fromRGB(255, 255, 255)
		selectItems.TextSize = 9
		selectItems.TextXAlignment = Enum.TextXAlignment.Left
		Utils.CreateRounded(selectItems, 5)
		
		local arrowDown = Instance.new("ImageLabel")
		arrowDown.Parent = dropdown
		arrowDown.BackgroundTransparency = 1
		arrowDown.Position = UDim2.new(1, -110, 0, 10)
		arrowDown.AnchorPoint = Vector2.new(1, 0)
		arrowDown.Size = UDim2.new(0, 20, 0, 20)
		arrowDown.Image = "rbxassetid://10709790948"
		arrowDown.ImageColor3 = Color3.fromRGB(255, 255, 255)
		
		local dropdownFrameScroll = Instance.new("Frame")
		dropdownFrameScroll.Parent = dropdown
		dropdownFrameScroll.BackgroundColor3 = CONSTANTS.BACKGROUND_DARK
		dropdownFrameScroll.Position = UDim2.new(0, 5, 0, 40)
		dropdownFrameScroll.Size = UDim2.new(1, -10, 0, 0)
		dropdownFrameScroll.Visible = false
		dropdownFrameScroll.ClipsDescendants = true
		Utils.CreateRounded(dropdownFrameScroll, 5)
		
		local dropScroll = Instance.new("ScrollingFrame")
		dropScroll.Parent = dropdownFrameScroll
		dropScroll.BackgroundTransparency = 1
		dropScroll.Position = UDim2.new(0, 0, 0, 10)
		dropScroll.Size = UDim2.new(1, 0, 0, 80)
		dropScroll.ScrollBarThickness = 3
		dropScroll.BorderSizePixel = 0
		
		local uiListLayout = Instance.new("UIListLayout")
		uiListLayout.Parent = dropScroll
		uiListLayout.Padding = UDim.new(0, 1)
		
		Utils.CreatePadding(dropScroll, CONSTANTS.PADDING.MEDIUM, CONSTANTS.PADDING.MEDIUM, 0, 0)
		
		for _, v in pairs(options) do
			local item = Instance.new("TextButton")
			item.Parent = dropScroll
			item.BackgroundColor3 = CONSTANTS.PRIMARY
			item.BackgroundTransparency = 1
			item.Size = UDim2.new(1, 0, 0, 30)
			item.Font = Enum.Font.Nunito
			item.Text = tostring(v)
			item.TextColor3 = Color3.fromRGB(255, 255, 255)
			item.TextSize = 13
			item.TextTransparency = 0.5
			item.TextXAlignment = Enum.TextXAlignment.Left
			Utils.CreateRounded(item, 5)
			
			Utils.CreatePadding(item, 8, 0, 0, 0)
			
			local selectedItems = Instance.new("Frame")
			selectedItems.Name = "SelectedItems"
			selectedItems.Parent = item
			selectedItems.BackgroundColor3 = CONSTANTS.ACCENT
			selectedItems.BackgroundTransparency = 1
			selectedItems.Size = UDim2.new(0, 3, 0.4, 0)
			selectedItems.Position = UDim2.new(0, -8, 0.5, 0)
			selectedItems.AnchorPoint = Vector2.new(0, 0.5)
			Utils.CreateRounded(selectedItems, 999)
			
			if var and tostring(v) == var then
				item.BackgroundTransparency = 0.8
				item.TextTransparency = 0
				selectedItems.BackgroundTransparency = 0
			end
			
			item.MouseButton1Click:Connect(function()
				Utils.SafeCall(callback, item.Text)
				activeItem = item.Text
				selectItems.Text = "   " .. item.Text
				
				for _, child in pairs(dropScroll:GetChildren()) do
					if child:IsA("TextButton") then
						local sel = child:FindFirstChild("SelectedItems")
						if child.Text == activeItem then
							Utils.Tween(child, {BackgroundTransparency = 0.8, TextTransparency = 0}, CONSTANTS.TWEEN_TIME.FAST)
							if sel then Utils.Tween(sel, {BackgroundTransparency = 0}, CONSTANTS.TWEEN_TIME.FAST) end
						else
							Utils.Tween(child, {BackgroundTransparency = 1, TextTransparency = 0.5}, CONSTANTS.TWEEN_TIME.FAST)
							if sel then Utils.Tween(sel, {BackgroundTransparency = 1}, CONSTANTS.TWEEN_TIME.FAST) end
						end
					end
				end
			end)
		end
		
		dropScroll.CanvasSize = UDim2.new(0, 0, 0, uiListLayout.AbsoluteContentSize.Y)
		
		selectItems.MouseButton1Click:Connect(function()
			isdropping = not isdropping
			
			if isdropping then
				Utils.Tween(dropdownFrameScroll, {Size = UDim2.new(1, -10, 0, 100)}, CONSTANTS.TWEEN_TIME.NORMAL)
				dropdownFrameScroll.Visible = true
				Utils.Tween(dropdown, {Size = UDim2.new(1, 0, 0, 145)}, CONSTANTS.TWEEN_TIME.NORMAL)
				Utils.Tween(arrowDown, {Rotation = 180}, CONSTANTS.TWEEN_TIME.NORMAL)
			else
				Utils.Tween(dropdownFrameScroll, {Size = UDim2.new(1, -10, 0, 0)}, CONSTANTS.TWEEN_TIME.NORMAL)
				task.delay(CONSTANTS.TWEEN_TIME.NORMAL, function()
					dropdownFrameScroll.Visible = false
				end)
				Utils.Tween(dropdown, {Size = UDim2.new(1, 0, 0, 40)}, CONSTANTS.TWEEN_TIME.NORMAL)
				Utils.Tween(arrowDown, {Rotation = 0}, CONSTANTS.TWEEN_TIME.NORMAL)
			end
		end)
		
		local dropfunc = {}
		
		function dropfunc:Add(t)
			local item = Instance.new("TextButton")
			item.Parent = dropScroll
			item.BackgroundColor3 = CONSTANTS.PRIMARY
			item.BackgroundTransparency = 1
			item.Size = UDim2.new(1, 0, 0, 30)
			item.Font = Enum.Font.Nunito
			item.Text = tostring(t)
			item.TextColor3 = Color3.fromRGB(255, 255, 255)
			item.TextSize = 13
			item.TextTransparency = 0.5
			item.TextXAlignment = Enum.TextXAlignment.Left
			Utils.CreateRounded(item, 5)
			
			Utils.CreatePadding(item, 8, 0, 0, 0)
			
			local selectedItems = Instance.new("Frame")
			selectedItems.Name = "SelectedItems"
			selectedItems.Parent = item
			selectedItems.BackgroundColor3 = CONSTANTS.ACCENT
			selectedItems.BackgroundTransparency = 1
			selectedItems.Size = UDim2.new(0, 3, 0.4, 0)
			selectedItems.Position = UDim2.new(0, -8, 0.5, 0)
			selectedItems.AnchorPoint = Vector2.new(0, 0.5)
			Utils.CreateRounded(selectedItems, 999)
			
			item.MouseButton1Click:Connect(function()
				Utils.SafeCall(callback, item.Text)
				activeItem = item.Text
				selectItems.Text = "   " .. item.Text
				
				for _, child in pairs(dropScroll:GetChildren()) do
					if child:IsA("TextButton") then
						local sel = child:FindFirstChild("SelectedItems")
						if child.Text == activeItem then
							Utils.Tween(child, {BackgroundTransparency = 0.8, TextTransparency = 0}, CONSTANTS.TWEEN_TIME.FAST)
							if sel then Utils.Tween(sel, {BackgroundTransparency = 0}, CONSTANTS.TWEEN_TIME.FAST) end
						else
							Utils.Tween(child, {BackgroundTransparency = 1, TextTransparency = 0.5}, CONSTANTS.TWEEN_TIME.FAST)
							if sel then Utils.Tween(sel, {BackgroundTransparency = 1}, CONSTANTS.TWEEN_TIME.FAST) end
						end
					end
				end
			end)
		end
		
		function dropfunc:Clear()
			selectItems.Text = "   Select Items"
			isdropping = false
			dropdownFrameScroll.Visible = false
			
			for _, v in pairs(dropScroll:GetChildren()) do
				if v:IsA("TextButton") then
					v:Destroy()
				end
			end
		end
		
		return dropfunc
	end
	
	-- Textbox Component
	function components:Textbox(text, disappear, callback)
		local textbox = Instance.new("Frame")
		textbox.Name = "Textbox"
		textbox.Parent = parent
		textbox.BackgroundColor3 = CONSTANTS.PRIMARY
		textbox.BackgroundTransparency = 0.8
		textbox.Size = UDim2.new(1, 0, 0, 35)
		Utils.CreateRounded(textbox, 5)
		
		local textboxLabel = Instance.new("TextLabel")
		textboxLabel.Parent = textbox
		textboxLabel.BackgroundTransparency = 1
		textboxLabel.Position = UDim2.new(0, CONSTANTS.PADDING.LARGE, 0.5, 0)
		textboxLabel.AnchorPoint = Vector2.new(0, 0.5)
		textboxLabel.Size = UDim2.new(1, 0, 0, 35)
		textboxLabel.Font = Enum.Font.Nunito
		textboxLabel.Text = text
		textboxLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		textboxLabel.TextSize = 15
		textboxLabel.TextXAlignment = Enum.TextXAlignment.Left
		
		local realTextbox = Instance.new("TextBox")
		realTextbox.Parent = textbox
		realTextbox.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
		realTextbox.BackgroundTransparency = 0.8
		realTextbox.Position = UDim2.new(1, -5, 0.5, 0)
		realTextbox.AnchorPoint = Vector2.new(1, 0.5)
		realTextbox.Size = UDim2.new(0, 80, 0, 25)
		realTextbox.Font = Enum.Font.Gotham
		realTextbox.Text = ""
		realTextbox.TextColor3 = Color3.fromRGB(225, 225, 225)
		realTextbox.TextSize = 11
		realTextbox.ClipsDescendants = true
		Utils.CreateRounded(realTextbox, 5)
		
		realTextbox.FocusLost:Connect(function()
			Utils.SafeCall(callback, realTextbox.Text)
		end)
	end
	
	-- Label Component
	function components:Label(text)
		local frame = Instance.new("Frame")
		frame.Name = "Label"
		frame.Parent = parent
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
		label.TextColor3 = Color3.fromRGB(225, 225, 225)
		label.TextSize = 15
		label.TextXAlignment = Enum.TextXAlignment.Left
		
		local imageLabel = Instance.new("ImageLabel")
		imageLabel.Parent = frame
		imageLabel.BackgroundTransparency = 1
		imageLabel.Position = UDim2.new(0, CONSTANTS.PADDING.MEDIUM, 0.5, 0)
		imageLabel.AnchorPoint = Vector2.new(0, 0.5)
		imageLabel.Size = UDim2.new(0, 14, 0, 14)
		imageLabel.Image = "rbxassetid://10723415903"
		imageLabel.ImageColor3 = Color3.fromRGB(200, 200, 200)
		
		local labelfunc = {}
		
		function labelfunc:Set(newtext)
			label.Text = newtext
		end
		
		return labelfunc
	end
	
	-- Separator Component
	function components:Seperator(text)
		local seperator = Instance.new("Frame")
		seperator.Name = "Seperator"
		seperator.Parent = parent
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
		sep1.TextColor3 = Color3.fromRGB(255, 255, 255)
		sep1.TextSize = 14
		
		local sep2 = Instance.new("TextLabel")
		sep2.Parent = seperator
		sep2.BackgroundTransparency = 1
		sep2.Position = UDim2.new(0.5, 0, 0.5, 0)
		sep2.AnchorPoint = Vector2.new(0.5, 0.5)
		sep2.Size = UDim2.new(1, 0, 0, 36)
		sep2.Font = Enum.Font.GothamBold
		sep2.Text = text
		sep2.TextColor3 = Color3.fromRGB(255, 255, 255)
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
		sep3.TextColor3 = Color3.fromRGB(255, 255, 255)
		sep3.TextSize = 14
	end
	
	-- Line Component
	function components:Line()
		local linee = Instance.new("Frame")
		linee.Name = "Line"
		linee.Parent = parent
		linee.BackgroundTransparency = 1
		linee.Size = UDim2.new(1, 0, 0, 20)
		
		local line = Instance.new("Frame")
		line.Parent = linee
		line.BackgroundColor3 = Color3.new(0.49, 0.49, 0.49)
		line.BorderSizePixel = 0
		line.Position = UDim2.new(0, 0, 0, 10)
		line.Size = UDim2.new(1, 0, 0, 1)
		
		local gradient = Instance.new("UIGradient")
		gradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, CONSTANTS.DARK),
			ColorSequenceKeypoint.new(0.4, CONSTANTS.PRIMARY),
			ColorSequenceKeypoint.new(0.5, CONSTANTS.PRIMARY),
			ColorSequenceKeypoint.new(0.6, CONSTANTS.PRIMARY),
			ColorSequenceKeypoint.new(1, CONSTANTS.DARK)
		})
		gradient.Parent = line
	end
	
	return components
end

-- Initialize toggle button
local toggleBtn = CreateToggleButton()
toggleBtn.MouseButton1Click:Connect(function()
	local hub = coreGui:FindFirstChild("VicatHub")
	if hub then hub.Enabled = not hub.Enabled end
end)

-- Cleanup on script unload
game:GetService("Players").LocalPlayer.CharacterRemoving:Connect(function()
	globalConnections:DisconnectAll()
	notificationSystem:Destroy()
end)

-- Return library
return Update
