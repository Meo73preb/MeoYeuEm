-- Vicat Hub - Optimized Version
-- Kiểm tra và xóa UI cũ
local coreGui = game:GetService("CoreGui")
if coreGui:FindFirstChild("VicatHub") then coreGui.VicatHub:Destroy() end
if coreGui:FindFirstChild("ScreenGui") then coreGui.ScreenGui:Destroy() end

-- Cấu hình màu sắc toàn cục
_G.Primary = Color3.fromRGB(100, 100, 100)
_G.Dark = Color3.fromRGB(22, 22, 26)
_G.Third = Color3.fromRGB(255, 0, 0)

-- Services
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

-- Utility Functions
local function CreateRounded(parent, size)
	local rounded = Instance.new("UICorner")
	rounded.Name = "Rounded"
	rounded.CornerRadius = UDim.new(0, size)
	rounded.Parent = parent
	return rounded
end

local function MakeDraggable(topbar, object)
	local dragging, dragInput, dragStart, startPos
	
	local function update(input)
		local delta = input.Position - dragStart
		local pos = UDim2.new(
			startPos.X.Scale, startPos.X.Offset + delta.X,
			startPos.Y.Scale, startPos.Y.Offset + delta.Y
		)
		TweenService:Create(object, TweenInfo.new(0.15), {Position = pos}):Play()
	end
	
	topbar.InputBegan:Connect(function(input)
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
	end)
	
	topbar.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or 
		   input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)
	
	UserInputService.InputChanged:Connect(function(input)
		if input == dragInput and dragging then
			update(input)
		end
	end)
end

-- Tạo nút mở/đóng
local screenGui = Instance.new("ScreenGui")
screenGui.Parent = coreGui
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local outlineButton = Instance.new("Frame")
outlineButton.Name = "OutlineButton"
outlineButton.Parent = screenGui
outlineButton.BackgroundColor3 = _G.Dark
outlineButton.Position = UDim2.new(0, 10, 0, 10)
outlineButton.Size = UDim2.new(0, 50, 0, 50)
CreateRounded(outlineButton, 12)

local imageButton = Instance.new("ImageButton")
imageButton.Parent = outlineButton
imageButton.AnchorPoint = Vector2.new(0.5, 0.5)
imageButton.Position = UDim2.new(0.5, 0, 0.5, 0)
imageButton.Size = UDim2.new(0, 40, 0, 40)
imageButton.BackgroundColor3 = _G.Dark
imageButton.Image = "rbxassetid://13940080072"
imageButton.ImageColor3 = Color3.fromRGB(250, 250, 250)
CreateRounded(imageButton, 10)

MakeDraggable(imageButton, outlineButton)

imageButton.MouseButton1Click:Connect(function()
	local hub = coreGui:FindFirstChild("VicatHub")
	if hub then hub.Enabled = not hub.Enabled end
end)

-- Hệ thống thông báo
local notificationFrame = Instance.new("ScreenGui")
notificationFrame.Name = "NotificationFrame"
notificationFrame.Parent = coreGui
notificationFrame.ZIndexBehavior = Enum.ZIndexBehavior.Global

local notificationList = {}

local function RemoveOldestNotification()
	if #notificationList > 0 then
		local removed = table.remove(notificationList, 1)
		removed[1]:TweenPosition(UDim2.new(0.5, 0, -0.2, 0), "Out", "Quad", 0.4, true, function()
			removed[1]:Destroy()
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

local Update = {}

function Update:Notify(desc)
	local outlineFrame = Instance.new("Frame")
	outlineFrame.Name = "OutlineFrame"
	outlineFrame.Parent = notificationFrame
	outlineFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	outlineFrame.BackgroundTransparency = 0.4
	outlineFrame.AnchorPoint = Vector2.new(0.5, 1)
	outlineFrame.Position = UDim2.new(0.5, 0, -0.2, 0)
	outlineFrame.Size = UDim2.new(0, 412, 0, 72)
	CreateRounded(outlineFrame, 12)
	
	local frame = Instance.new("Frame")
	frame.Parent = outlineFrame
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = UDim2.new(0.5, 0, 0.5, 0)
	frame.Size = UDim2.new(0, 400, 0, 60)
	frame.BackgroundColor3 = _G.Dark
	frame.BackgroundTransparency = 0.1
	CreateRounded(frame, 10)
	
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
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextSize = 16
	title.TextXAlignment = Enum.TextXAlignment.Left
	
	local descLabel = Instance.new("TextLabel")
	descLabel.Parent = frame
	descLabel.BackgroundTransparency = 1
	descLabel.Position = UDim2.new(0, 55, 0, 33)
	descLabel.Size = UDim2.new(0, 10, 0, 10)
	descLabel.Font = Enum.Font.GothamSemibold
	descLabel.Text = desc
	descLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	descLabel.TextSize = 12
	descLabel.TextTransparency = 0.3
	descLabel.TextXAlignment = Enum.TextXAlignment.Left
	
	outlineFrame:TweenPosition(
		UDim2.new(0.5, 0, 0.1 + (#notificationList * 0.1), 0), 
		"Out", "Quad", 0.4, true
	)
	
	table.insert(notificationList, {outlineFrame})
end

-- Loading Screen tối ưu
function Update:StartLoad()
	local loader = Instance.new("ScreenGui")
	loader.Parent = coreGui
	loader.ZIndexBehavior = Enum.ZIndexBehavior.Global
	loader.DisplayOrder = 1000
	
	local loaderFrame = Instance.new("Frame")
	loaderFrame.Parent = loader
	loaderFrame.BackgroundColor3 = Color3.fromRGB(5, 5, 5)
	loaderFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	loaderFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	loaderFrame.Size = UDim2.new(1.5, 0, 1.5, 0)
	loaderFrame.BorderSizePixel = 0
	
	local mainFrame = Instance.new("Frame")
	mainFrame.Parent = loaderFrame
	mainFrame.BackgroundTransparency = 1
	mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	mainFrame.Size = UDim2.new(0.5, 0, 0.5, 0)
	
	local titleLoader = Instance.new("TextLabel")
	titleLoader.Parent = mainFrame
	titleLoader.Text = "Vicat Hub"
	titleLoader.Font = Enum.Font.FredokaOne
	titleLoader.TextSize = 50
	titleLoader.TextColor3 = Color3.fromRGB(255, 255, 255)
	titleLoader.BackgroundTransparency = 1
	titleLoader.AnchorPoint = Vector2.new(0.5, 0.5)
	titleLoader.Position = UDim2.new(0.5, 0, 0.3, 0)
	titleLoader.Size = UDim2.new(0.8, 0, 0.2, 0)
	
	local descLoader = Instance.new("TextLabel")
	descLoader.Parent = mainFrame
	descLoader.Text = "Loading.."
	descLoader.Font = Enum.Font.Gotham
	descLoader.TextSize = 15
	descLoader.TextColor3 = Color3.fromRGB(255, 255, 255)
	descLoader.BackgroundTransparency = 1
	descLoader.AnchorPoint = Vector2.new(0.5, 0.5)
	descLoader.Position = UDim2.new(0.5, 0, 0.6, 0)
	descLoader.Size = UDim2.new(0.8, 0, 0.2, 0)
	
	local loadingBarBg = Instance.new("Frame")
	loadingBarBg.Parent = mainFrame
	loadingBarBg.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	loadingBarBg.AnchorPoint = Vector2.new(0.5, 0.5)
	loadingBarBg.Position = UDim2.new(0.5, 0, 0.7, 0)
	loadingBarBg.Size = UDim2.new(0.7, 0, 0.05, 0)
	loadingBarBg.ClipsDescendants = true
	loadingBarBg.BorderSizePixel = 0
	CreateRounded(loadingBarBg, 20)
	
	local loadingBar = Instance.new("Frame")
	loadingBar.Parent = loadingBarBg
	loadingBar.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
	loadingBar.Size = UDim2.new(0, 0, 1, 0)
	loadingBar.BorderSizePixel = 0
	CreateRounded(loadingBar, 20)
	
	local running = true
	local dotCount = 0
	
	local tween1 = TweenService:Create(loadingBar, TweenInfo.new(0.5, Enum.EasingStyle.Linear), {
		Size = UDim2.new(0.25, 0, 1, 0)
	})
	
	local tween2 = TweenService:Create(loadingBar, TweenInfo.new(1, Enum.EasingStyle.Linear), {
		Size = UDim2.new(1, 0, 1, 0)
	})
	
	tween1:Play()
	
	function Update:Loaded()
		tween2:Play()
	end
	
	tween1.Completed:Connect(function()
		tween2:Play()
		tween2.Completed:Connect(function()
			task.wait(1)
			running = false
			descLoader.Text = "Loaded!"
			task.wait(0.5)
			loader:Destroy()
		end)
	end)
	
	task.spawn(function()
		while running do
			dotCount = (dotCount + 1) % 4
			descLoader.Text = "Please wait" .. string.rep(".", dotCount)
			task.wait(0.5)
		end
	end)
end

-- Hệ thống lưu cấu hình
local SettingsLib = {
	SaveSettings = true,
	LoadAnimation = true,
	PageAnimation = true
}

getgenv().LoadConfig = function()
	if readfile and writefile and isfile and isfolder then
		if not isfolder("Vicat Hub") then makefolder("Vicat Hub") end
		if not isfolder("Vicat Hub/Library/") then makefolder("Vicat Hub/Library/") end
		
		local configPath = "Vicat Hub/Library/" .. Players.LocalPlayer.Name .. ".json"
		if not isfile(configPath) then
			writefile(configPath, HttpService:JSONEncode(SettingsLib))
		else
			local decode = HttpService:JSONDecode(readfile(configPath))
			for i, v in pairs(decode) do
				SettingsLib[i] = v
			end
		end
		print("Vicat Hub Config Loaded!")
	else
		warn("Executor không hỗ trợ file system")
	end
end

getgenv().SaveConfig = function()
	if writefile and isfile and isfolder then
		local configPath = "Vicat Hub/Library/" .. Players.LocalPlayer.Name .. ".json"
		writefile(configPath, HttpService:JSONEncode(SettingsLib))
	end
end

getgenv().LoadConfig()

function Update:SaveSettings()
	return SettingsLib.SaveSettings
end

function Update:LoadAnimation()
	return SettingsLib.LoadAnimation
end

function Update:PageAnimation()
	return SettingsLib.PageAnimation
end

-- Hàm tạo Window
function Update:Window(config)
	assert(config.SubTitle, "SubTitle is required")
	
	local windowConfig = {
		Size = config.Size,
		TabWidth = config.TabWidth
	}
	
	local vicatHub = Instance.new("ScreenGui")
	vicatHub.Name = "VicatHub"
	vicatHub.Parent = coreGui
	vicatHub.DisplayOrder = 999
	
	local outlineMain = Instance.new("Frame")
	outlineMain.Name = "OutlineMain"
	outlineMain.Parent = vicatHub
	outlineMain.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	outlineMain.BackgroundTransparency = 0.4
	outlineMain.AnchorPoint = Vector2.new(0.5, 0.5)
	outlineMain.Position = UDim2.new(0.5, 0, 0.45, 0)
	outlineMain.Size = UDim2.new(0, 0, 0, 0)
	CreateRounded(outlineMain, 15)
	
	local main = Instance.new("Frame")
	main.Name = "Main"
	main.Parent = outlineMain
	main.BackgroundColor3 = Color3.fromRGB(24, 24, 26)
	main.AnchorPoint = Vector2.new(0.5, 0.5)
	main.Position = UDim2.new(0.5, 0, 0.5, 0)
	main.Size = windowConfig.Size
	CreateRounded(main, 12)
	
	outlineMain:TweenSize(
		UDim2.new(0, windowConfig.Size.X.Offset + 15, 0, windowConfig.Size.Y.Offset + 15),
		"Out", "Quad", 0.4, true
	)
	
	-- Top Bar
	local top = Instance.new("Frame")
	top.Name = "Top"
	top.Parent = main
	top.BackgroundTransparency = 1
	top.Size = UDim2.new(1, 0, 0, 40)
	CreateRounded(top, 5)
	
	local nameHub = Instance.new("TextLabel")
	nameHub.Parent = top
	nameHub.BackgroundTransparency = 1
	nameHub.Position = UDim2.new(0, 15, 0.5, 0)
	nameHub.AnchorPoint = Vector2.new(0, 0.5)
	nameHub.Font = Enum.Font.GothamBold
	nameHub.Text = "Vicat Hub"
	nameHub.TextSize = 20
	nameHub.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameHub.TextXAlignment = Enum.TextXAlignment.Left
	nameHub.ZIndex = 5
	nameHub.Size = UDim2.new(0, 0, 0, 25)
	
	local nameSize = game:GetService("TextService"):GetTextSize(
		nameHub.Text, nameHub.TextSize, nameHub.Font, 
		Vector2.new(math.huge, math.huge)
	)
	nameHub.Size = UDim2.new(0, nameSize.X, 0, 25)
	
	local subTitle = Instance.new("TextLabel")
	subTitle.Parent = top
	subTitle.BackgroundTransparency = 1
	subTitle.Position = UDim2.new(0, 15 + nameSize.X + 8, 0.5, 0)
	subTitle.AnchorPoint = Vector2.new(0, 0.5)
	subTitle.Font = Enum.Font.Cartoon
	subTitle.Text = config.SubTitle
	subTitle.TextSize = 15
	subTitle.TextColor3 = Color3.fromRGB(150, 150, 150)
	subTitle.ZIndex = 5
	subTitle.Size = UDim2.new(0, 0, 0, 25)
	
	local subTitleSize = game:GetService("TextService"):GetTextSize(
		subTitle.Text, subTitle.TextSize, subTitle.Font, 
		Vector2.new(math.huge, math.huge)
	)
	subTitle.Size = UDim2.new(0, subTitleSize.X, 0, 25)
	
	-- Background Settings Frame (tạo trước để có thể reference)
	local backgroundSettings = Instance.new("Frame")
	backgroundSettings.Name = "BackgroundSettings"
	backgroundSettings.Parent = outlineMain
	backgroundSettings.Active = true
	backgroundSettings.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
	backgroundSettings.BackgroundTransparency = 0.3
	backgroundSettings.Size = UDim2.new(1, 0, 1, 0)
	backgroundSettings.Visible = false
	backgroundSettings.ZIndex = 10
	CreateRounded(backgroundSettings, 15)
	
	local settingsFrame = Instance.new("Frame")
	settingsFrame.Name = "SettingsFrame"
	settingsFrame.Parent = backgroundSettings
	settingsFrame.BackgroundColor3 = Color3.fromRGB(24, 24, 26)
	settingsFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	settingsFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	settingsFrame.Size = UDim2.new(0.7, 0, 0.7, 0)
	settingsFrame.ZIndex = 11
	CreateRounded(settingsFrame, 15)
	
	local closeSettings = Instance.new("ImageButton")
	closeSettings.Name = "CloseSettings"
	closeSettings.Parent = settingsFrame
	closeSettings.BackgroundTransparency = 1
	closeSettings.AnchorPoint = Vector2.new(1, 0)
	closeSettings.Position = UDim2.new(1, -20, 0, 15)
	closeSettings.Size = UDim2.new(0, 20, 0, 20)
	closeSettings.Image = "rbxassetid://10747384394"
	closeSettings.ImageColor3 = Color3.fromRGB(245, 245, 245)
	closeSettings.ZIndex = 12
	CreateRounded(closeSettings, 3)
	
	closeSettings.MouseButton1Click:Connect(function()
		backgroundSettings.Visible = false
	end)
	
	local titleSettings = Instance.new("TextLabel")
	titleSettings.Name = "TitleSettings"
	titleSettings.Parent = settingsFrame
	titleSettings.BackgroundTransparency = 1
	titleSettings.Position = UDim2.new(0, 20, 0, 15)
	titleSettings.Size = UDim2.new(1, 0, 0, 20)
	titleSettings.Font = Enum.Font.GothamBold
	titleSettings.Text = "Library Settings"
	titleSettings.TextSize = 20
	titleSettings.TextColor3 = Color3.fromRGB(245, 245, 245)
	titleSettings.TextXAlignment = Enum.TextXAlignment.Left
	titleSettings.ZIndex = 12
	
	local settingsMenuList = Instance.new("Frame")
	settingsMenuList.Name = "SettingsMenuList"
	settingsMenuList.Parent = settingsFrame
	settingsMenuList.BackgroundTransparency = 1
	settingsMenuList.Position = UDim2.new(0, 0, 0, 50)
	settingsMenuList.Size = UDim2.new(1, 0, 1, -70)
	settingsMenuList.ZIndex = 11
	CreateRounded(settingsMenuList, 15)
	
	local scrollSettings = Instance.new("ScrollingFrame")
	scrollSettings.Name = "ScrollSettings"
	scrollSettings.Parent = settingsMenuList
	scrollSettings.BackgroundTransparency = 1
	scrollSettings.Size = UDim2.new(1, 0, 1, 0)
	scrollSettings.ScrollBarThickness = 3
	scrollSettings.ZIndex = 11
	
	local settingsListLayout = Instance.new("UIListLayout")
	settingsListLayout.Parent = scrollSettings
	settingsListLayout.Padding = UDim.new(0, 8)
	
	local paddingScroll = Instance.new("UIPadding")
	paddingScroll.Parent = scrollSettings
	paddingScroll.PaddingLeft = UDim.new(0, 20)
	paddingScroll.PaddingRight = UDim.new(0, 20)
	
	-- Settings Functions
	local function CreateCheckbox(title, state, callback)
		local checked = state or false
		
		local background = Instance.new("Frame")
		background.Name = "Background"
		background.Parent = scrollSettings
		background.BackgroundTransparency = 1
		background.Size = UDim2.new(1, 0, 0, 20)
		background.ZIndex = 11
		
		local titleLabel = Instance.new("TextLabel")
		titleLabel.Parent = background
		titleLabel.BackgroundTransparency = 1
		titleLabel.Position = UDim2.new(0, 60, 0.5, 0)
		titleLabel.AnchorPoint = Vector2.new(0, 0.5)
		titleLabel.Size = UDim2.new(1, -60, 0, 20)
		titleLabel.Font = Enum.Font.Code
		titleLabel.Text = title or ""
		titleLabel.TextSize = 15
		titleLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
		titleLabel.TextXAlignment = Enum.TextXAlignment.Left
		titleLabel.ZIndex = 12
		
		local checkbox = Instance.new("ImageButton")
		checkbox.Parent = background
		checkbox.BackgroundColor3 = checked and _G.Third or Color3.fromRGB(100, 100, 100)
		checkbox.AnchorPoint = Vector2.new(0, 0.5)
		checkbox.Position = UDim2.new(0, 30, 0.5, 0)
		checkbox.Size = UDim2.new(0, 20, 0, 20)
		checkbox.Image = "rbxassetid://10709790644"
		checkbox.ImageTransparency = checked and 0 or 1
		checkbox.ImageColor3 = Color3.fromRGB(245, 245, 245)
		checkbox.ZIndex = 12
		CreateRounded(checkbox, 5)
		
		checkbox.MouseButton1Click:Connect(function()
			checked = not checked
			checkbox.BackgroundColor3 = checked and _G.Third or Color3.fromRGB(100, 100, 100)
			checkbox.ImageTransparency = checked and 0 or 1
			pcall(callback, checked)
		end)
		
		pcall(callback, checked)
	end
	
	local function CreateButton(title, callback)
		local background = Instance.new("Frame")
		background.Name = "Background"
		background.Parent = scrollSettings
		background.BackgroundTransparency = 1
		background.Size = UDim2.new(1, 0, 0, 30)
		background.ZIndex = 11
		
		local button = Instance.new("TextButton")
		button.Parent = background
		button.BackgroundColor3 = _G.Third
		button.Size = UDim2.new(0.8, 0, 0, 30)
		button.Font = Enum.Font.Code
		button.Text = title or "Button"
		button.AnchorPoint = Vector2.new(0.5, 0)
		button.Position = UDim2.new(0.5, 0, 0, 0)
		button.TextColor3 = Color3.fromRGB(255, 255, 255)
		button.TextSize = 15
		button.AutoButtonColor = false
		button.ZIndex = 12
		CreateRounded(button, 5)
		
		button.MouseButton1Click:Connect(function()
			callback()
		end)
	end
	
	-- Add settings options
	CreateCheckbox("Save Settings", SettingsLib.SaveSettings, function(state)
		SettingsLib.SaveSettings = state
		getgenv().SaveConfig()
	end)
	
	CreateCheckbox("Loading Animation", SettingsLib.LoadAnimation, function(state)
		SettingsLib.LoadAnimation = state
		getgenv().SaveConfig()
	end)
	
	CreateCheckbox("Page Animation", SettingsLib.PageAnimation, function(state)
		SettingsLib.PageAnimation = state
		getgenv().SaveConfig()
	end)
	
	CreateButton("Reset Config", function()
		if isfolder("Vicat Hub") then
			delfolder("Vicat Hub")
		end
		Update:Notify("Config has been reset!")
	end)
	
	-- Auto-resize settings canvas
	RunService.Stepped:Connect(function()
		pcall(function()
			scrollSettings.CanvasSize = UDim2.new(0, 0, 0, settingsListLayout.AbsoluteContentSize.Y)
		end)
	end)
	
	-- Close Button
	local closeButton = Instance.new("ImageButton")
	closeButton.Parent = top
	closeButton.BackgroundTransparency = 1
	closeButton.AnchorPoint = Vector2.new(1, 0.5)
	closeButton.Position = UDim2.new(1, -15, 0.5, 0)
	closeButton.Size = UDim2.new(0, 20, 0, 20)
	closeButton.Image = "rbxassetid://7743878857"
	closeButton.ImageColor3 = Color3.fromRGB(245, 245, 245)
	closeButton.ZIndex = 5
	CreateRounded(closeButton, 3)
	
	closeButton.MouseButton1Click:Connect(function()
		vicatHub.Enabled = not vicatHub.Enabled
	end)
	
	-- Resize Button
	local resizeButton = Instance.new("ImageButton")
	resizeButton.Name = "ResizeButton"
	resizeButton.Parent = top
	resizeButton.BackgroundTransparency = 1
	resizeButton.AnchorPoint = Vector2.new(1, 0.5)
	resizeButton.Position = UDim2.new(1, -50, 0.5, 0)
	resizeButton.Size = UDim2.new(0, 20, 0, 20)
	resizeButton.Image = "rbxassetid://10734886735"
	resizeButton.ImageColor3 = Color3.fromRGB(245, 245, 245)
	resizeButton.ZIndex = 5
	CreateRounded(resizeButton, 3)
	
	-- Settings Button
	local settingsButton = Instance.new("ImageButton")
	settingsButton.Name = "SettingsButton"
	settingsButton.Parent = top
	settingsButton.BackgroundTransparency = 1
	settingsButton.AnchorPoint = Vector2.new(1, 0.5)
	settingsButton.Position = UDim2.new(1, -85, 0.5, 0)
	settingsButton.Size = UDim2.new(0, 20, 0, 20)
	settingsButton.Image = "rbxassetid://10734950020"
	settingsButton.ImageColor3 = Color3.fromRGB(245, 245, 245)
	settingsButton.ZIndex = 5
	CreateRounded(settingsButton, 3)
	
	-- Settings button click handler
	settingsButton.MouseButton1Click:Connect(function()
		backgroundSettings.Visible = true
	end)
	
	-- Resize functionality
	local defaultSize = true
	resizeButton.MouseButton1Click:Connect(function()
		if defaultSize then
			defaultSize = false
			
			-- Tween to fullscreen
			local tweenInfo = TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
			
			outlineMain:TweenPosition(UDim2.new(0.5, 0, 0.5, 0), "Out", "Quad", 0.2, true)
			outlineMain:TweenSize(UDim2.new(1, -10, 1, -10), "Out", "Quad", 0.4, true)
			
			TweenService:Create(main, tweenInfo, {
				Size = UDim2.new(1, -20, 1, -20)
			}):Play()
			
			-- Wait a bit then update children
			task.wait(0.1)
			
			TweenService:Create(page, tweenInfo, {
				Size = UDim2.new(0, main.AbsoluteSize.X - tab.AbsoluteSize.X - 25, 0, main.AbsoluteSize.Y - top.AbsoluteSize.Y - 10)
			}):Play()
			
			TweenService:Create(tab, tweenInfo, {
				Size = UDim2.new(0, windowConfig.TabWidth, 0, main.AbsoluteSize.Y - top.AbsoluteSize.Y - 10)
			}):Play()
			
			resizeButton.Image = "rbxassetid://10734895698"
			
		else
			defaultSize = true
			
			-- Tween back to normal
			local tweenInfo = TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
			
			outlineMain:TweenSize(UDim2.new(0, windowConfig.Size.X.Offset + 15, 0, windowConfig.Size.Y.Offset + 15), "Out", "Quad", 0.4, true)
			outlineMain:TweenPosition(UDim2.new(0.5, 0, 0.45, 0), "Out", "Quad", 0.2, true)
			
			TweenService:Create(main, tweenInfo, {
				Size = windowConfig.Size
			}):Play()
			
			-- Wait a bit then update children
			task.wait(0.1)
			
			TweenService:Create(page, tweenInfo, {
				Size = UDim2.new(0, windowConfig.Size.X.Offset - tab.Size.X.Offset - 25, 0, windowConfig.Size.Y.Offset - top.Size.Y.Offset - 10)
			}):Play()
			
			TweenService:Create(tab, tweenInfo, {
				Size = UDim2.new(0, windowConfig.TabWidth, 0, windowConfig.Size.Y.Offset - top.Size.Y.Offset - 10)
			}):Play()
			
			resizeButton.Image = "rbxassetid://10734886735"
		end
	end)
	
	-- Background Settings Frame
	local backgroundSettings = Instance.new("Frame")
	backgroundSettings.Name = "BackgroundSettings"
	backgroundSettings.Parent = outlineMain
	backgroundSettings.Active = true
	backgroundSettings.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
	backgroundSettings.BackgroundTransparency = 0.3
	backgroundSettings.Size = UDim2.new(1, 0, 1, 0)
	backgroundSettings.Visible = false
	backgroundSettings.ZIndex = 10
	CreateRounded(backgroundSettings, 15)
	
	local settingsFrame = Instance.new("Frame")
	settingsFrame.Name = "SettingsFrame"
	settingsFrame.Parent = backgroundSettings
	settingsFrame.BackgroundColor3 = Color3.fromRGB(24, 24, 26)
	settingsFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	settingsFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	settingsFrame.Size = UDim2.new(0.7, 0, 0.7, 0)
	settingsFrame.ZIndex = 11
	CreateRounded(settingsFrame, 15)
	
	local closeSettings = Instance.new("ImageButton")
	closeSettings.Name = "CloseSettings"
	closeSettings.Parent = settingsFrame
	closeSettings.BackgroundTransparency = 1
	closeSettings.AnchorPoint = Vector2.new(1, 0)
	closeSettings.Position = UDim2.new(1, -20, 0, 15)
	closeSettings.Size = UDim2.new(0, 20, 0, 20)
	closeSettings.Image = "rbxassetid://10747384394"
	closeSettings.ImageColor3 = Color3.fromRGB(245, 245, 245)
	closeSettings.ZIndex = 12
	CreateRounded(closeSettings, 3)
	
	closeSettings.MouseButton1Click:Connect(function()
		backgroundSettings.Visible = false
	end)
	
	local titleSettings = Instance.new("TextLabel")
	titleSettings.Name = "TitleSettings"
	titleSettings.Parent = settingsFrame
	titleSettings.BackgroundTransparency = 1
	titleSettings.Position = UDim2.new(0, 20, 0, 15)
	titleSettings.Size = UDim2.new(1, 0, 0, 20)
	titleSettings.Font = Enum.Font.GothamBold
	titleSettings.Text = "Library Settings"
	titleSettings.TextSize = 20
	titleSettings.TextColor3 = Color3.fromRGB(245, 245, 245)
	titleSettings.TextXAlignment = Enum.TextXAlignment.Left
	titleSettings.ZIndex = 12
	
	local settingsMenuList = Instance.new("Frame")
	settingsMenuList.Name = "SettingsMenuList"
	settingsMenuList.Parent = settingsFrame
	settingsMenuList.BackgroundTransparency = 1
	settingsMenuList.Position = UDim2.new(0, 0, 0, 50)
	settingsMenuList.Size = UDim2.new(1, 0, 1, -70)
	settingsMenuList.ZIndex = 11
	CreateRounded(settingsMenuList, 15)
	
	local scrollSettings = Instance.new("ScrollingFrame")
	scrollSettings.Name = "ScrollSettings"
	scrollSettings.Parent = settingsMenuList
	scrollSettings.BackgroundTransparency = 1
	scrollSettings.Size = UDim2.new(1, 0, 1, 0)
	scrollSettings.ScrollBarThickness = 3
	scrollSettings.ZIndex = 11
	
	local settingsListLayout = Instance.new("UIListLayout")
	settingsListLayout.Parent = scrollSettings
	settingsListLayout.Padding = UDim.new(0, 8)
	
	local paddingScroll = Instance.new("UIPadding")
	paddingScroll.Parent = scrollSettings
	paddingScroll.PaddingLeft = UDim.new(0, 20)
	paddingScroll.PaddingRight = UDim.new(0, 20)
	
	-- Settings Functions
	local function CreateCheckbox(title, state, callback)
		local checked = state or false
		
		local background = Instance.new("Frame")
		background.Name = "Background"
		background.Parent = scrollSettings
		background.BackgroundTransparency = 1
		background.Size = UDim2.new(1, 0, 0, 20)
		background.ZIndex = 11
		
		local titleLabel = Instance.new("TextLabel")
		titleLabel.Parent = background
		titleLabel.BackgroundTransparency = 1
		titleLabel.Position = UDim2.new(0, 60, 0.5, 0)
		titleLabel.AnchorPoint = Vector2.new(0, 0.5)
		titleLabel.Size = UDim2.new(1, -60, 0, 20)
		titleLabel.Font = Enum.Font.Code
		titleLabel.Text = title or ""
		titleLabel.TextSize = 15
		titleLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
		titleLabel.TextXAlignment = Enum.TextXAlignment.Left
		titleLabel.ZIndex = 12
		
		local checkbox = Instance.new("ImageButton")
		checkbox.Parent = background
		checkbox.BackgroundColor3 = checked and _G.Third or Color3.fromRGB(100, 100, 100)
		checkbox.AnchorPoint = Vector2.new(0, 0.5)
		checkbox.Position = UDim2.new(0, 30, 0.5, 0)
		checkbox.Size = UDim2.new(0, 20, 0, 20)
		checkbox.Image = "rbxassetid://10709790644"
		checkbox.ImageTransparency = checked and 0 or 1
		checkbox.ImageColor3 = Color3.fromRGB(245, 245, 245)
		checkbox.ZIndex = 12
		CreateRounded(checkbox, 5)
		
		checkbox.MouseButton1Click:Connect(function()
			checked = not checked
			checkbox.BackgroundColor3 = checked and _G.Third or Color3.fromRGB(100, 100, 100)
			checkbox.ImageTransparency = checked and 0 or 1
			pcall(callback, checked)
		end)
		
		pcall(callback, checked)
	end
	
	local function CreateButton(title, callback)
		local background = Instance.new("Frame")
		background.Name = "Background"
		background.Parent = scrollSettings
		background.BackgroundTransparency = 1
		background.Size = UDim2.new(1, 0, 0, 30)
		background.ZIndex = 11
		
		local button = Instance.new("TextButton")
		button.Parent = background
		button.BackgroundColor3 = _G.Third
		button.Size = UDim2.new(0.8, 0, 0, 30)
		button.Font = Enum.Font.Code
		button.Text = title or "Button"
		button.AnchorPoint = Vector2.new(0.5, 0)
		button.Position = UDim2.new(0.5, 0, 0, 0)
		button.TextColor3 = Color3.fromRGB(255, 255, 255)
		button.TextSize = 15
		button.AutoButtonColor = false
		button.ZIndex = 12
		CreateRounded(button, 5)
		
		button.MouseButton1Click:Connect(function()
			callback()
		end)
	end
	
	-- Add settings options
	CreateCheckbox("Save Settings", SettingsLib.SaveSettings, function(state)
		SettingsLib.SaveSettings = state
		getgenv().SaveConfig()
	end)
	
	CreateCheckbox("Loading Animation", SettingsLib.LoadAnimation, function(state)
		SettingsLib.LoadAnimation = state
		getgenv().SaveConfig()
	end)
	
	CreateButton("Reset Config", function()
		if isfolder("VicatHub") then
			delfolder("VicatHub")
		end
		Update:Notify("Config has been reset!")
	end)
	
	-- Auto-resize settings canvas
	RunService.Stepped:Connect(function()
		pcall(function()
			scrollSettings.CanvasSize = UDim2.new(0, 0, 0, settingsListLayout.AbsoluteContentSize.Y)
		end)
	end)
	
	MakeDraggable(top, outlineMain)
	
	-- Toggle UI với phím Insert
	UserInputService.InputBegan:Connect(function(input)
		if input.KeyCode == Enum.KeyCode.Insert then
			vicatHub.Enabled = not vicatHub.Enabled
		end
	end)
	
	-- Tab Container
	local tab = Instance.new("Frame")
	tab.Name = "Tab"
	tab.Parent = main
	tab.BackgroundTransparency = 1
	tab.Position = UDim2.new(0, 8, 0, top.Size.Y.Offset)
	tab.Size = UDim2.new(0, windowConfig.TabWidth, 0, windowConfig.Size.Y.Offset - top.Size.Y.Offset - 8)
	CreateRounded(tab, 5)
	
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
	page.Size = UDim2.new(0, windowConfig.Size.X.Offset - tab.Size.X.Offset - 25, 0, windowConfig.Size.Y.Offset - top.Size.Y.Offset - 8)
	page.ClipsDescendants = true
	CreateRounded(page, 3)
	
	local mainPage = Instance.new("Frame")
	mainPage.Parent = page
	mainPage.BackgroundTransparency = 1
	mainPage.Size = UDim2.new(1, 0, 1, 0)
	mainPage.ClipsDescendants = true
	
	local pageList = Instance.new("Folder")
	pageList.Name = "PageList"
	pageList.Parent = mainPage
	
	-- Auto-resize canvas
	RunService.Stepped:Connect(function()
		pcall(function()
			scrollTab.CanvasSize = UDim2.new(0, 0, 0, tabListLayout.AbsoluteContentSize.Y)
		end)
	end)
	
	local uitab = {}
	local abc = false
	
	function uitab:Tab(text, img)
		local tabButton = Instance.new("TextButton")
		tabButton.Name = text .. "Unique"
		tabButton.Parent = scrollTab
		tabButton.Text = ""
		tabButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
		tabButton.BackgroundTransparency = 1
		tabButton.Size = UDim2.new(1, 0, 0, 35)
		CreateRounded(tabButton, 6)
		
		local selectedTab = Instance.new("Frame")
		selectedTab.Name = "SelectedTab"
		selectedTab.Parent = tabButton
		selectedTab.BackgroundColor3 = _G.Third
		selectedTab.Size = UDim2.new(0, 3, 0, 0)
		selectedTab.Position = UDim2.new(0, 0, 0.5, 0)
		selectedTab.AnchorPoint = Vector2.new(0, 0.5)
		CreateRounded(selectedTab, 100)
		
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
		uiListLayout.Padding = UDim.new(0, 3)
		uiListLayout.SortOrder = Enum.SortOrder.LayoutOrder
		
		local uiPadding = Instance.new("UIPadding")
		uiPadding.Parent = mainFramePage
		
		-- Tab Click Handler với animation mới
		local tabIndex = 0
		
		-- Set index cho tab button
		tabButton.LayoutOrder = tabIndex
		local currentTabIndex = tabIndex
		tabIndex = tabIndex + 1
		
		tabButton.MouseButton1Click:Connect(function()
			local clickedIndex = tabButton.LayoutOrder
			
			-- Nếu click vào tab hiện tại, không làm gì cả
			if clickedIndex == currentTabIndex then
				return
			end
			
			for _, v in pairs(scrollTab:GetChildren()) do
				if v:IsA("TextButton") then
					TweenService:Create(v, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
					TweenService:Create(v.SelectedTab, TweenInfo.new(0.3), {Size = UDim2.new(0, 3, 0, 0)}):Play()
					TweenService:Create(v.IDK, TweenInfo.new(0.3), {ImageTransparency = 0.4}):Play()
					TweenService:Create(v.Title, TweenInfo.new(0.3), {TextTransparency = 0.4}):Play()
				end
			end
			
			-- Ẩn tất cả các page
			for _, v in pairs(pageList:GetChildren()) do
				if v:IsA("ScrollingFrame") then
					v.Visible = false
				end
			end
			
			-- Hiển thị page được chọn
			mainFramePage.Visible = true
			
			TweenService:Create(tabButton, TweenInfo.new(0.3), {BackgroundTransparency = 0.8}):Play()
			TweenService:Create(selectedTab, TweenInfo.new(0.3), {Size = UDim2.new(0, 3, 0, 15)}):Play()
			TweenService:Create(icon, TweenInfo.new(0.3), {ImageTransparency = 0}):Play()
			TweenService:Create(title, TweenInfo.new(0.3), {TextTransparency = 0}):Play()
			
			-- Animation logic
			if SettingsLib.PageAnimation then
				-- Xác định hướng animation
				if clickedIndex > currentTabIndex then
					-- Đi xuống (tab 1 -> 3)
					mainFramePage.Position = UDim2.new(0, 0, 1, 0) -- Start below
					mainFramePage:TweenPosition(UDim2.new(0, 0, 0, 0), "Out", "Quad", 0.3, true)
				else
					-- Đi lên (tab 3 -> 1)
					mainFramePage.Position = UDim2.new(0, 0, -1, 0) -- Start above
					mainFramePage:TweenPosition(UDim2.new(0, 0, 0, 0), "Out", "Quad", 0.3, true)
				end
			else
				-- Không có animation, hiện ngay
				mainFramePage.Position = UDim2.new(0, 0, 0, 0)
			end
			
			currentTabIndex = clickedIndex
		end)
		
		-- Select first tab by default
		if not abc then
			-- Hiển thị tab đầu tiên
			mainFramePage.Visible = true
			mainFramePage.Position = UDim2.new(0, 0, 0, 0)
			
			TweenService:Create(tabButton, TweenInfo.new(0.3), {BackgroundTransparency = 0.8}):Play()
			TweenService:Create(selectedTab, TweenInfo.new(0.3), {Size = UDim2.new(0, 3, 0, 15)}):Play()
			TweenService:Create(icon, TweenInfo.new(0.3), {ImageTransparency = 0}):Play()
			TweenService:Create(title, TweenInfo.new(0.3), {TextTransparency = 0}):Play()
			abc = true
		end
		
		-- Auto-resize canvas
		RunService.Stepped:Connect(function()
			pcall(function()
				mainFramePage.CanvasSize = UDim2.new(0, 0, 0, uiListLayout.AbsoluteContentSize.Y)
			end)
		end)
		
		local main = {}
		
		-- Button Component
		function main:Button(text, callback)
			local button = Instance.new("Frame")
			button.Name = "Button"
			button.Parent = mainFramePage
			button.BackgroundTransparency = 1
			button.Size = UDim2.new(1, 0, 0, 36)
			CreateRounded(button, 5)
			
			local textLabel = Instance.new("TextLabel")
			textLabel.Parent = button
			textLabel.BackgroundTransparency = 1
			textLabel.Position = UDim2.new(0, 20, 0.5, 0)
			textLabel.AnchorPoint = Vector2.new(0, 0.5)
			textLabel.Size = UDim2.new(1, -50, 1, 0)
			textLabel.Font = Enum.Font.Cartoon
			textLabel.Text = text
			textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
			textLabel.TextSize = 15
			textLabel.TextXAlignment = Enum.TextXAlignment.Left
			
			local textButton = Instance.new("TextButton")
			textButton.Parent = button
			textButton.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
			textButton.BackgroundTransparency = 0.8
			textButton.AnchorPoint = Vector2.new(1, 0.5)
			textButton.Position = UDim2.new(1, -1, 0.5, 0)
			textButton.Size = UDim2.new(0, 25, 0, 25)
			textButton.Text = ""
			CreateRounded(textButton, 4)
			
			local imageLabel = Instance.new("ImageLabel")
			imageLabel.Parent = textButton
			imageLabel.BackgroundTransparency = 1
			imageLabel.AnchorPoint = Vector2.new(0.5, 0.5)
			imageLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
			imageLabel.Size = UDim2.new(0, 15, 0, 15)
			imageLabel.Image = "rbxassetid://10734898355"
			imageLabel.ImageColor3 = Color3.fromRGB(255, 255, 255)
			
			textButton.MouseButton1Click:Connect(function()
				callback()
			end)
		end
		
		-- Toggle Component (đã tối ưu hơn)
		function main:Toggle(text, config, desc, callback)
			config = config or false
			local toggled = config
			
			local button = Instance.new("TextButton")
			button.Name = "Button"
			button.Parent = mainFramePage
			button.BackgroundColor3 = _G.Primary
			button.BackgroundTransparency = 0.8
			button.AutoButtonColor = false
			button.Text = ""
			button.Size = UDim2.new(1, 0, 0, desc and 46 or 36)
			CreateRounded(button, 5)
			
			local title2 = Instance.new("TextLabel")
			title2.Parent = button
			title2.BackgroundTransparency = 1
			title2.Size = UDim2.new(1, 0, 0, 35)
			title2.Font = Enum.Font.Cartoon
			title2.Text = text
			title2.TextColor3 = Color3.fromRGB(255, 255, 255)
			title2.TextSize = 15
			title2.TextXAlignment = Enum.TextXAlignment.Left
			title2.AnchorPoint = Vector2.new(0, 0.5)
			title2.Position = UDim2.new(0, 15, 0.5, desc and -5 or 0)
			
			if desc then
				local descLabel = Instance.new("TextLabel")
				descLabel.Parent = title2
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
			toggleFrame.Name = "ToggleFrame"
			toggleFrame.Parent = button
			toggleFrame.BackgroundTransparency = 1
			toggleFrame.Position = UDim2.new(1, -10, 0.5, 0)
			toggleFrame.Size = UDim2.new(0, 35, 0, 20)
			toggleFrame.AnchorPoint = Vector2.new(1, 0.5)
			CreateRounded(toggleFrame, 10)
			
			local toggleImage = Instance.new("TextButton")
			toggleImage.Parent = toggleFrame
			toggleImage.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
			toggleImage.BackgroundTransparency = 0.8
			toggleImage.Size = UDim2.new(1, 0, 1, 0)
			toggleImage.Text = ""
			toggleImage.AutoButtonColor = false
			CreateRounded(toggleImage, 10)
			
			local circle = Instance.new("Frame")
			circle.Parent = toggleImage
			circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			circle.Position = UDim2.new(0, 3, 0.5, 0)
			circle.Size = UDim2.new(0, 14, 0, 14)
			circle.AnchorPoint = Vector2.new(0, 0.5)
			CreateRounded(circle, 10)
			
			toggleImage.MouseButton1Click:Connect(function()
				toggled = not toggled
				
				if toggled then
					circle:TweenPosition(UDim2.new(0, 17, 0.5, 0), "Out", "Sine", 0.2, true)
					TweenService:Create(toggleImage, TweenInfo.new(0.4, Enum.EasingStyle.Quad), {
						BackgroundColor3 = _G.Third,
						BackgroundTransparency = 0
					}):Play()
				else
					circle:TweenPosition(UDim2.new(0, 4, 0.5, 0), "Out", "Sine", 0.2, true)
					TweenService:Create(toggleImage, TweenInfo.new(0.4, Enum.EasingStyle.Quad), {
						BackgroundColor3 = Color3.fromRGB(200, 200, 200),
						BackgroundTransparency = 0.8
					}):Play()
				end
				
				pcall(callback, toggled)
			end)
			
			if config then
				circle.Position = UDim2.new(0, 17, 0.5, 0)
				toggleImage.BackgroundColor3 = _G.Third
				toggleImage.BackgroundTransparency = 0
				pcall(callback, toggled)
			end
		end
		
		-- Dropdown Component
		function main:Dropdown(text, option, var, callback)
			local isdropping = false
			local activeItem = var
			
			local dropdown = Instance.new("Frame")
			dropdown.Name = "Dropdown"
			dropdown.Parent = mainFramePage
			dropdown.BackgroundColor3 = _G.Primary
			dropdown.BackgroundTransparency = 0.8
			dropdown.Size = UDim2.new(1, 0, 0, 40)
			CreateRounded(dropdown, 5)
			
			local dropTitle = Instance.new("TextLabel")
			dropTitle.Parent = dropdown
			dropTitle.BackgroundTransparency = 1
			dropTitle.Position = UDim2.new(0, 15, 0, 5)
			dropTitle.Size = UDim2.new(1, 0, 0, 30)
			dropTitle.Font = Enum.Font.Cartoon
			dropTitle.Text = text
			dropTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
			dropTitle.TextSize = 15
			dropTitle.TextXAlignment = Enum.TextXAlignment.Left
			
			local selectItems = Instance.new("TextButton")
			selectItems.Parent = dropdown
			selectItems.BackgroundColor3 = Color3.fromRGB(24, 24, 26)
			selectItems.Position = UDim2.new(1, -5, 0, 5)
			selectItems.AnchorPoint = Vector2.new(1, 0)
			selectItems.Size = UDim2.new(0, 100, 0, 30)
			selectItems.Font = Enum.Font.GothamMedium
			selectItems.Text = "   " .. (var or "Select Items")
			selectItems.TextColor3 = Color3.fromRGB(255, 255, 255)
			selectItems.TextSize = 9
			selectItems.TextXAlignment = Enum.TextXAlignment.Left
			CreateRounded(selectItems, 5)
			
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
			dropdownFrameScroll.BackgroundColor3 = Color3.fromRGB(24, 24, 26)
			dropdownFrameScroll.Position = UDim2.new(0, 5, 0, 40)
			dropdownFrameScroll.Size = UDim2.new(1, -10, 0, 0)
			dropdownFrameScroll.Visible = false
			dropdownFrameScroll.ClipsDescendants = true
			CreateRounded(dropdownFrameScroll, 5)
			
			local dropScroll = Instance.new("ScrollingFrame")
			dropScroll.Parent = dropdownFrameScroll
			dropScroll.BackgroundTransparency = 1
			dropScroll.Position = UDim2.new(0, 0, 0, 10)
			dropScroll.Size = UDim2.new(1, 0, 0, 80)
			dropScroll.ScrollBarThickness = 3
			
			local uiListLayout = Instance.new("UIListLayout")
			uiListLayout.Parent = dropScroll
			uiListLayout.Padding = UDim.new(0, 1)
			
			local padding = Instance.new("UIPadding")
			padding.Parent = dropScroll
			padding.PaddingLeft = UDim.new(0, 10)
			padding.PaddingRight = UDim.new(0, 10)
			
			for _, v in pairs(option) do
				local item = Instance.new("TextButton")
				item.Parent = dropScroll
				item.BackgroundColor3 = _G.Primary
				item.BackgroundTransparency = 1
				item.Size = UDim2.new(1, 0, 0, 30)
				item.Font = Enum.Font.Nunito
				item.Text = tostring(v)
				item.TextColor3 = Color3.fromRGB(255, 255, 255)
				item.TextSize = 13
				item.TextTransparency = 0.5
				item.TextXAlignment = Enum.TextXAlignment.Left
				CreateRounded(item, 5)
				
				local itemPadding = Instance.new("UIPadding")
				itemPadding.Parent = item
				itemPadding.PaddingLeft = UDim.new(0, 8)
				
				local selectedItems = Instance.new("Frame")
				selectedItems.Name = "SelectedItems"
				selectedItems.Parent = item
				selectedItems.BackgroundColor3 = _G.Third
				selectedItems.BackgroundTransparency = 1
				selectedItems.Size = UDim2.new(0, 3, 0.4, 0)
				selectedItems.Position = UDim2.new(0, -8, 0.5, 0)
				selectedItems.AnchorPoint = Vector2.new(0, 0.5)
				CreateRounded(selectedItems, 999)
				
				if var and tostring(v) == var then
					item.BackgroundTransparency = 0.8
					item.TextTransparency = 0
					selectedItems.BackgroundTransparency = 0
				end
				
				item.MouseButton1Click:Connect(function()
					callback(item.Text)
					activeItem = item.Text
					selectItems.Text = "   " .. item.Text
					
					for _, child in pairs(dropScroll:GetChildren()) do
						if child:IsA("TextButton") then
							local sel = child:FindFirstChild("SelectedItems")
							if child.Text == activeItem then
								child.BackgroundTransparency = 0.8
								child.TextTransparency = 0
								if sel then sel.BackgroundTransparency = 0 end
							else
								child.BackgroundTransparency = 1
								child.TextTransparency = 0.5
								if sel then sel.BackgroundTransparency = 1 end
							end
						end
					end
				end)
			end
			
			dropScroll.CanvasSize = UDim2.new(0, 0, 0, uiListLayout.AbsoluteContentSize.Y)
			
			selectItems.MouseButton1Click:Connect(function()
				isdropping = not isdropping
				
				if isdropping then
					TweenService:Create(dropdownFrameScroll, TweenInfo.new(0.3), {
						Size = UDim2.new(1, -10, 0, 100),
						Visible = true
					}):Play()
					TweenService:Create(dropdown, TweenInfo.new(0.3), {
						Size = UDim2.new(1, 0, 0, 145)
					}):Play()
					TweenService:Create(arrowDown, TweenInfo.new(0.3), {Rotation = 180}):Play()
				else
					TweenService:Create(dropdownFrameScroll, TweenInfo.new(0.3), {
						Size = UDim2.new(1, -10, 0, 0),
						Visible = false
					}):Play()
					TweenService:Create(dropdown, TweenInfo.new(0.3), {
						Size = UDim2.new(1, 0, 0, 40)
					}):Play()
					TweenService:Create(arrowDown, TweenInfo.new(0.3), {Rotation = 0}):Play()
				end
			end)
			
			local dropfunc = {}
			
			function dropfunc:Add(t)
				local item = Instance.new("TextButton")
				item.Parent = dropScroll
				item.BackgroundColor3 = _G.Primary
				item.BackgroundTransparency = 1
				item.Size = UDim2.new(1, 0, 0, 30)
				item.Font = Enum.Font.Nunito
				item.Text = tostring(t)
				item.TextColor3 = Color3.fromRGB(255, 255, 255)
				item.TextSize = 13
				item.TextTransparency = 0.5
				item.TextXAlignment = Enum.TextXAlignment.Left
				CreateRounded(item, 5)
				
				local itemPadding = Instance.new("UIPadding")
				itemPadding.Parent = item
				itemPadding.PaddingLeft = UDim.new(0, 8)
				
				local selectedItems = Instance.new("Frame")
				selectedItems.Name = "SelectedItems"
				selectedItems.Parent = item
				selectedItems.BackgroundColor3 = _G.Third
				selectedItems.BackgroundTransparency = 1
				selectedItems.Size = UDim2.new(0, 3, 0.4, 0)
				selectedItems.Position = UDim2.new(0, -8, 0.5, 0)
				selectedItems.AnchorPoint = Vector2.new(0, 0.5)
				CreateRounded(selectedItems, 999)
				
				item.MouseButton1Click:Connect(function()
					callback(item.Text)
					activeItem = item.Text
					selectItems.Text = "   " .. item.Text
					
					for _, child in pairs(dropScroll:GetChildren()) do
						if child:IsA("TextButton") then
							local sel = child:FindFirstChild("SelectedItems")
							if child.Text == activeItem then
								child.BackgroundTransparency = 0.8
								child.TextTransparency = 0
								if sel then sel.BackgroundTransparency = 0 end
							else
								child.BackgroundTransparency = 1
								child.TextTransparency = 0.5
								if sel then sel.BackgroundTransparency = 1 end
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
		
		-- Slider Component
		function main:Slider(text, min, max, set, callback)
			local value = set or min
			
			local slider = Instance.new("Frame")
			slider.Name = "Slider"
			slider.Parent = mainFramePage
			slider.BackgroundTransparency = 1
			slider.Size = UDim2.new(1, 0, 0, 50)
			
			local sliderr = Instance.new("Frame")
			sliderr.Parent = slider
			sliderr.BackgroundColor3 = _G.Primary
			sliderr.BackgroundTransparency = 0.8
			sliderr.Size = UDim2.new(1, 0, 1, 0)
			CreateRounded(sliderr, 5)
			
			local title = Instance.new("TextLabel")
			title.Parent = sliderr
			title.BackgroundTransparency = 1
			title.Position = UDim2.new(0, 15, 0, 8)
			title.Size = UDim2.new(1, -100, 0, 20)
			title.Font = Enum.Font.Cartoon
			title.Text = text
			title.TextColor3 = Color3.fromRGB(255, 255, 255)
			title.TextSize = 15
			title.TextXAlignment = Enum.TextXAlignment.Left
			
			-- TextBox để nhập số (màu đen hơn)
			local valueBox = Instance.new("TextBox")
			valueBox.Parent = sliderr
			valueBox.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
			valueBox.BackgroundTransparency = 0
			valueBox.BorderSizePixel = 0
			valueBox.Position = UDim2.new(1, -65, 0, 5)
			valueBox.AnchorPoint = Vector2.new(0, 0)
			valueBox.Size = UDim2.new(0, 55, 0, 22)
			valueBox.Font = Enum.Font.GothamBold
			valueBox.Text = tostring(set)
			valueBox.TextColor3 = Color3.fromRGB(255, 255, 255)
			valueBox.TextSize = 13
			valueBox.ClearTextOnFocus = false
			CreateRounded(valueBox, 4)
			
			local barContainer = Instance.new("Frame")
			barContainer.Parent = sliderr
			barContainer.BackgroundTransparency = 1
			barContainer.Position = UDim2.new(0, 15, 1, -20)
			barContainer.Size = UDim2.new(1, -30, 0, 15)
			
			local bar = Instance.new("Frame")
			bar.Parent = barContainer
			bar.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
			bar.BackgroundTransparency = 0.8
			bar.Position = UDim2.new(0, 0, 0.5, 0)
			bar.AnchorPoint = Vector2.new(0, 0.5)
			bar.Size = UDim2.new(1, 0, 0, 4)
			CreateRounded(bar, 5)
			
			local bar1 = Instance.new("Frame")
			bar1.Parent = bar
			bar1.BackgroundColor3 = _G.Third
			bar1.Size = UDim2.new((set - min) / (max - min), 0, 1, 0)
			CreateRounded(bar1, 5)
			
			local circlebar = Instance.new("Frame")
			circlebar.Parent = bar1
			circlebar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			circlebar.Position = UDim2.new(1, 0, 0.5, 0)
			circlebar.AnchorPoint = Vector2.new(0.5, 0.5)
			circlebar.Size = UDim2.new(0, 15, 0, 15)
			CreateRounded(circlebar, 100)
			
			local function updateValue(newValue)
				newValue = math.clamp(tonumber(newValue) or min, min, max)
				value = newValue
				valueBox.Text = tostring(value)
				local percentage = (value - min) / (max - min)
				bar1.Size = UDim2.new(percentage, 0, 1, 0)
				pcall(callback, value)
			end
			
			-- TextBox input
			valueBox.FocusLost:Connect(function(enterPressed)
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
			
			UserInputService.InputEnded:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or 
				   input.UserInputType == Enum.UserInputType.Touch then
					dragging = false
				end
			end)
			
			UserInputService.InputChanged:Connect(function(input)
				if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or 
				   input.UserInputType == Enum.UserInputType.Touch) then
					local percentage = math.clamp((input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
					local newValue = math.floor(min + (max - min) * percentage)
					updateValue(newValue)
				end
			end)
		end
		
		-- Textbox Component
		function main:Textbox(text, disappear, callback)
			local textbox = Instance.new("Frame")
			textbox.Name = "Textbox"
			textbox.Parent = mainFramePage
			textbox.BackgroundColor3 = _G.Primary
			textbox.BackgroundTransparency = 0.8
			textbox.Size = UDim2.new(1, 0, 0, 35)
			CreateRounded(textbox, 5)
			
			local textboxLabel = Instance.new("TextLabel")
			textboxLabel.Parent = textbox
			textboxLabel.BackgroundTransparency = 1
			textboxLabel.Position = UDim2.new(0, 15, 0.5, 0)
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
			CreateRounded(realTextbox, 5)
			
			realTextbox.FocusLost:Connect(function()
				callback(realTextbox.Text)
			end)
		end
		
		-- Label Component
		function main:Label(text)
			local frame = Instance.new("Frame")
			frame.Name = "Frame"
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
			label.TextColor3 = Color3.fromRGB(225, 225, 225)
			label.TextSize = 15
			label.TextXAlignment = Enum.TextXAlignment.Left
			
			local imageLabel = Instance.new("ImageLabel")
			imageLabel.Parent = frame
			imageLabel.BackgroundTransparency = 1
			imageLabel.Position = UDim2.new(0, 10, 0.5, 0)
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
		function main:Seperator(text)
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
		function main:Line()
			local linee = Instance.new("Frame")
			linee.Name = "Linee"
			linee.Parent = mainFramePage
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
				ColorSequenceKeypoint.new(0, _G.Dark),
				ColorSequenceKeypoint.new(0.4, _G.Primary),
				ColorSequenceKeypoint.new(0.5, _G.Primary),
				ColorSequenceKeypoint.new(0.6, _G.Primary),
				ColorSequenceKeypoint.new(1, _G.Dark)
			})
			gradient.Parent = line
		end
		
		return main
	end
	
	return uitab
end

return Update
