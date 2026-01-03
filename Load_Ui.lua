-- Vicat Hub - Optimized Remastered Version
-- Cải thiện bởi Gemini AI

local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")

-- [Cleanup] Xóa UI cũ tránh chồng chéo
if CoreGui:FindFirstChild("VicatHub") then CoreGui.VicatHub:Destroy() end
if CoreGui:FindFirstChild("VicatHub_Notify") then CoreGui.VicatHub_Notify:Destroy() end
if CoreGui:FindFirstChild("VicatHub_Button") then CoreGui.VicatHub_Button:Destroy() end

--------------------------------------------------------------------------------
-- CONFIG & THEMES
--------------------------------------------------------------------------------
local Config = {
	Colors = {
		Primary = Color3.fromRGB(100, 100, 100), -- Màu nền item
		Dark    = Color3.fromRGB(22, 22, 26),    -- Màu nền chính
		Accent  = Color3.fromRGB(255, 0, 0),     -- Màu nhấn (Đỏ)
		Text    = Color3.fromRGB(255, 255, 255),
		TextDim = Color3.fromRGB(150, 150, 150)
	},
	Sizes = {
		TopBarHeight = 40,
		TabWidth = 140, -- Chiều rộng Tab list
		CornerRadius = 6
	}
}

local Library = {
	Connections = {}, -- Lưu các connection để disconnect khi cần
	Settings = {
		SaveSettings = true,
		PageAnimation = true
	}
}

--------------------------------------------------------------------------------
-- UTILITY FUNCTIONS
--------------------------------------------------------------------------------
local function CreateCorner(parent, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius or Config.Sizes.CornerRadius)
	corner.Parent = parent
	return corner
end

local function MakeDraggable(dragObject, mainObject)
	local dragging, dragInput, dragStart, startPos
	
	local function update(input)
		local delta = input.Position - dragStart
		local pos = UDim2.new(
			startPos.X.Scale, startPos.X.Offset + delta.X,
			startPos.Y.Scale, startPos.Y.Offset + delta.Y
		)
		TweenService:Create(mainObject, TweenInfo.new(0.15), {Position = pos}):Play()
	end
	
	dragObject.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = mainObject.Position
			
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)
	
	dragObject.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)
	
	UserInputService.InputChanged:Connect(function(input)
		if input == dragInput and dragging then
			update(input)
		end
	end)
end

-- Hàm cập nhật CanvasSize tự động (Tối ưu thay cho RunService)
local function AutoCanvasSize(scrollingFrame, listLayout)
	listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 20)
	end)
end

--------------------------------------------------------------------------------
-- NOTIFICATION SYSTEM (Fixed Animation & Stacking)
--------------------------------------------------------------------------------
local NotifyGui = Instance.new("ScreenGui")
NotifyGui.Name = "VicatHub_Notify"
NotifyGui.Parent = CoreGui
NotifyGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local NotifyContainer = Instance.new("Frame")
NotifyContainer.Name = "Container"
NotifyContainer.Parent = NotifyGui
NotifyContainer.AnchorPoint = Vector2.new(1, 1)
NotifyContainer.Position = UDim2.new(1, -20, 1, -20)
NotifyContainer.Size = UDim2.new(0, 300, 1, 0)
NotifyContainer.BackgroundTransparency = 1

local NotifyListLayout = Instance.new("UIListLayout")
NotifyListLayout.Parent = NotifyContainer
NotifyListLayout.SortOrder = Enum.SortOrder.LayoutOrder
NotifyListLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
NotifyListLayout.Padding = UDim.new(0, 5)

function Library:Notify(title, desc, duration)
	duration = duration or 3
	
	local Frame = Instance.new("Frame")
	Frame.Name = "NotifyFrame"
	Frame.Parent = NotifyContainer
	Frame.BackgroundColor3 = Config.Colors.Dark
	Frame.Size = UDim2.new(1, 0, 0, 0) -- Bắt đầu với height 0 để animation mượt
	Frame.ClipsDescendants = true
	Frame.BackgroundTransparency = 0.1
	Frame.BorderSizePixel = 0
	CreateCorner(Frame, 8)
	
	local Stroke = Instance.new("UIStroke")
	Stroke.Parent = Frame
	Stroke.Color = Config.Colors.Accent
	Stroke.Thickness = 1
	Stroke.Transparency = 1 -- Fade in border sau
	
	local Icon = Instance.new("ImageLabel")
	Icon.Parent = Frame
	Icon.BackgroundTransparency = 1
	Icon.Position = UDim2.new(0, 10, 0.5, -15)
	Icon.Size = UDim2.new(0, 30, 0, 30)
	Icon.Image = "rbxassetid://13940080072"
	Icon.ImageTransparency = 1
	
	local TitleLabel = Instance.new("TextLabel")
	TitleLabel.Parent = Frame
	TitleLabel.BackgroundTransparency = 1
	TitleLabel.Position = UDim2.new(0, 50, 0, 10)
	TitleLabel.Size = UDim2.new(1, -60, 0, 20)
	TitleLabel.Font = Enum.Font.GothamBold
	TitleLabel.Text = title or "Notification"
	TitleLabel.TextColor3 = Config.Colors.Text
	TitleLabel.TextSize = 14
	TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
	TitleLabel.TextTransparency = 1
	
	local DescLabel = Instance.new("TextLabel")
	DescLabel.Parent = Frame
	DescLabel.BackgroundTransparency = 1
	DescLabel.Position = UDim2.new(0, 50, 0, 30)
	DescLabel.Size = UDim2.new(1, -60, 0, 25)
	DescLabel.Font = Enum.Font.Gotham
	DescLabel.Text = desc or ""
	DescLabel.TextColor3 = Config.Colors.TextDim
	DescLabel.TextSize = 12
	DescLabel.TextXAlignment = Enum.TextXAlignment.Left
	DescLabel.TextTransparency = 1
	DescLabel.TextWrapped = true
	
	-- Animation In
	TweenService:Create(Frame, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {Size = UDim2.new(1, 0, 0, 65)}):Play()
	task.wait(0.1)
	TweenService:Create(Stroke, TweenInfo.new(0.3), {Transparency = 0}):Play()
	TweenService:Create(Icon, TweenInfo.new(0.3), {ImageTransparency = 0}):Play()
	TweenService:Create(TitleLabel, TweenInfo.new(0.3), {TextTransparency = 0}):Play()
	TweenService:Create(DescLabel, TweenInfo.new(0.3), {TextTransparency = 0}):Play()
	
	-- Auto Close Logic using LayoutOrder to keep stack clean
	task.delay(duration, function()
		if not Frame then return end
		TweenService:Create(Frame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Size = UDim2.new(1, 0, 0, 0)}):Play()
		TweenService:Create(Stroke, TweenInfo.new(0.2), {Transparency = 1}):Play()
		TweenService:Create(TitleLabel, TweenInfo.new(0.2), {TextTransparency = 1}):Play()
		
		task.wait(0.3)
		Frame:Destroy()
		-- UIListLayout tự động đẩy các item khác xuống/lên, không cần code loop phức tạp
	end)
end

--------------------------------------------------------------------------------
-- MAIN WINDOW
--------------------------------------------------------------------------------
-- Thay thế từ dòng function Library:Window(config) trở xuống

function Library:Window(config)
	local WindowConfig = config or {}
	WindowConfig.Title = WindowConfig.Title or "Vicat Hub"
	WindowConfig.SubTitle = WindowConfig.SubTitle or "Remastered"
	WindowConfig.Size = WindowConfig.Size or UDim2.new(0, 550, 0, 350)
	
	local ScreenGui = Instance.new("ScreenGui")
	ScreenGui.Name = "VicatHub"
	ScreenGui.Parent = CoreGui
	ScreenGui.DisplayOrder = 100
	
	-- Toggle Button (Nút mở menu nhỏ)
	local ToggleBtnFrame = Instance.new("Frame")
	ToggleBtnFrame.Name = "ToggleBtnFrame"
	ToggleBtnFrame.Parent = ScreenGui
	ToggleBtnFrame.BackgroundColor3 = Config.Colors.Dark
	ToggleBtnFrame.Position = UDim2.new(0, 10, 0, 10)
	ToggleBtnFrame.Size = UDim2.new(0, 50, 0, 50)
	CreateCorner(ToggleBtnFrame, 12)
	
	local ToggleBtn = Instance.new("ImageButton")
	ToggleBtn.Parent = ToggleBtnFrame
	ToggleBtn.AnchorPoint = Vector2.new(0.5, 0.5)
	ToggleBtn.Position = UDim2.new(0.5, 0, 0.5, 0)
	ToggleBtn.Size = UDim2.new(0, 40, 0, 40)
	ToggleBtn.BackgroundColor3 = Config.Colors.Dark
	ToggleBtn.Image = "rbxassetid://13940080072"
	CreateCorner(ToggleBtn, 10)
	MakeDraggable(ToggleBtn, ToggleBtnFrame)
	
	-- Main Outline
	local MainOutline = Instance.new("Frame")
	MainOutline.Name = "MainOutline"
	MainOutline.Parent = ScreenGui
	MainOutline.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	MainOutline.AnchorPoint = Vector2.new(0.5, 0.5)
	MainOutline.Position = UDim2.new(0.5, 0, 0.5, 0)
	MainOutline.Size = WindowConfig.Size + UDim2.new(0, 4, 0, 4)
	CreateCorner(MainOutline, 8)
	
	local MainFrame = Instance.new("Frame")
	MainFrame.Name = "MainFrame"
	MainFrame.Parent = MainOutline
	MainFrame.BackgroundColor3 = Config.Colors.Dark
	MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	MainFrame.Size = UDim2.new(1, -4, 1, -4)
	MainFrame.ClipsDescendants = true
	CreateCorner(MainFrame, 8)
	
	MakeDraggable(MainFrame, MainOutline)
	
	-- Toggle Logic
	local isVisible = true
	ToggleBtn.MouseButton1Click:Connect(function()
		isVisible = not isVisible
		MainOutline.Visible = isVisible
	end)
	
	-- TOP BAR
	local TopBar = Instance.new("Frame")
	TopBar.Name = "TopBar"
	TopBar.Parent = MainFrame
	TopBar.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
	TopBar.Size = UDim2.new(1, 0, 0, Config.Sizes.TopBarHeight)
	TopBar.BorderSizePixel = 0
	CreateCorner(TopBar, 8)
	
	-- Che góc bo dưới
	local TopBarFix = Instance.new("Frame")
	TopBarFix.Parent = TopBar
	TopBarFix.BackgroundColor3 = TopBar.BackgroundColor3
	TopBarFix.BorderSizePixel = 0
	TopBarFix.Position = UDim2.new(0, 0, 1, -5)
	TopBarFix.Size = UDim2.new(1, 0, 0, 5)
	
	local Title = Instance.new("TextLabel")
	Title.Parent = TopBar
	Title.BackgroundTransparency = 1
	Title.Position = UDim2.new(0, 15, 0, 0)
	Title.Size = UDim2.new(0, 200, 1, 0)
	Title.Font = Enum.Font.GothamBold
	Title.Text = WindowConfig.Title .. " <font color=\"rgb(150,150,150)\">" .. WindowConfig.SubTitle .. "</font>"
	Title.RichText = true
	Title.TextColor3 = Config.Colors.Text
	Title.TextSize = 16
	Title.TextXAlignment = Enum.TextXAlignment.Left
	
	local CloseBtn = Instance.new("ImageButton")
	CloseBtn.Parent = TopBar
	CloseBtn.AnchorPoint = Vector2.new(1, 0.5)
	CloseBtn.Position = UDim2.new(1, -10, 0.5, 0)
	CloseBtn.Size = UDim2.new(0, 20, 0, 20)
	CloseBtn.Image = "rbxassetid://7743878857"
	CloseBtn.BackgroundTransparency = 1
	CloseBtn.MouseButton1Click:Connect(function()
		isVisible = false
		MainOutline.Visible = false
	end)
	
	local isFullscreen = false
	local ResizeBtn = Instance.new("ImageButton")
	ResizeBtn.Parent = TopBar
	ResizeBtn.AnchorPoint = Vector2.new(1, 0.5)
	ResizeBtn.Position = UDim2.new(1, -40, 0.5, 0)
	ResizeBtn.Size = UDim2.new(0, 20, 0, 20)
	ResizeBtn.Image = "rbxassetid://10734886735"
	ResizeBtn.BackgroundTransparency = 1
	
	ResizeBtn.MouseButton1Click:Connect(function()
		isFullscreen = not isFullscreen
		if isFullscreen then
			TweenService:Create(MainOutline, TweenInfo.new(0.5, Enum.EasingStyle.Quart), {
				Size = UDim2.new(1, -60, 1, -60),
				Position = UDim2.new(0.5, 0, 0.5, 0)
			}):Play()
		else
			TweenService:Create(MainOutline, TweenInfo.new(0.5, Enum.EasingStyle.Quart), {
				Size = WindowConfig.Size + UDim2.new(0, 4, 0, 4),
				Position = UDim2.new(0.5, 0, 0.5, 0)
			}):Play()
		end
	end)
	
	-- BODY
	local Body = Instance.new("Frame")
	Body.Name = "Body"
	Body.Parent = MainFrame
	Body.BackgroundTransparency = 1
	Body.Position = UDim2.new(0, 0, 0, Config.Sizes.TopBarHeight)
	Body.Size = UDim2.new(1, 0, 1, -Config.Sizes.TopBarHeight) 
	
	local TabContainer = Instance.new("Frame")
	TabContainer.Name = "TabContainer"
	TabContainer.Parent = Body
	TabContainer.BackgroundColor3 = Color3.fromRGB(25, 25, 28)
	TabContainer.Size = UDim2.new(0, Config.Sizes.TabWidth, 1, 0)
	TabContainer.BorderSizePixel = 0
	
	local TabScroll = Instance.new("ScrollingFrame")
	TabScroll.Parent = TabContainer
	TabScroll.BackgroundTransparency = 1
	TabScroll.Size = UDim2.new(1, 0, 1, -10)
	TabScroll.Position = UDim2.new(0, 0, 0, 10)
	TabScroll.ScrollBarThickness = 2
	TabScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y -- FIX: Auto resize
	TabScroll.CanvasSize = UDim2.new(0,0,0,0)
	
	local TabListLayout = Instance.new("UIListLayout")
	TabListLayout.Parent = TabScroll
	TabListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	TabListLayout.Padding = UDim.new(0, 5)
	
	-- PAGE CONTAINER (Đã bỏ Folder đi để tránh lỗi)
	local PageContainer = Instance.new("Frame")
	PageContainer.Name = "PageContainer"
	PageContainer.Parent = Body
	PageContainer.BackgroundTransparency = 1
	PageContainer.ClipsDescendants = true
	PageContainer.Position = UDim2.new(0, Config.Sizes.TabWidth, 0, 0)
	PageContainer.Size = UDim2.new(1, -Config.Sizes.TabWidth, 1, 0)
	
	-- TAB SYSTEM
	local Tabs = {}
	local FirstTab = true
	local CurrentPage = nil
	
	function Tabs:Tab(name, iconId)
		local TabBtn = Instance.new("TextButton")
		TabBtn.Name = name
		TabBtn.Parent = TabScroll
		TabBtn.BackgroundColor3 = Config.Colors.Dark
		TabBtn.BackgroundTransparency = 1
		TabBtn.Size = UDim2.new(1, -10, 0, 32)
		TabBtn.Position = UDim2.new(0, 5, 0, 0)
		TabBtn.Text = ""
		TabBtn.AutoButtonColor = false
		CreateCorner(TabBtn, 6)
		
		local TabTitle = Instance.new("TextLabel")
		TabTitle.Parent = TabBtn
		TabTitle.BackgroundTransparency = 1
		TabTitle.Position = UDim2.new(0, 35, 0, 0)
		TabTitle.Size = UDim2.new(1, -35, 1, 0)
		TabTitle.Font = Enum.Font.GothamMedium
		TabTitle.Text = name
		TabTitle.TextColor3 = Config.Colors.TextDim
		TabTitle.TextSize = 13
		TabTitle.TextXAlignment = Enum.TextXAlignment.Left
		
		local TabIcon = Instance.new("ImageLabel")
		TabIcon.Parent = TabBtn
		TabIcon.BackgroundTransparency = 1
		TabIcon.Position = UDim2.new(0, 8, 0.5, -9)
		TabIcon.Size = UDim2.new(0, 18, 0, 18)
		TabIcon.Image = iconId or "rbxassetid://7733960981"
		TabIcon.ImageColor3 = Config.Colors.TextDim
		
		local TabIndicator = Instance.new("Frame")
		TabIndicator.Parent = TabBtn
		TabIndicator.BackgroundColor3 = Config.Colors.Accent
		TabIndicator.Position = UDim2.new(0, 0, 0.5, -8)
		TabIndicator.Size = UDim2.new(0, 3, 0, 16)
		TabIndicator.BackgroundTransparency = 1
		CreateCorner(TabIndicator, 4)
		
		-- Create Page
		local Page = Instance.new("ScrollingFrame")
		Page.Name = name .. "_Page"
		Page.Parent = PageContainer -- FIX: Parent trực tiếp vào Frame, không qua Folder
		Page.BackgroundTransparency = 1
		Page.Size = UDim2.new(1, 0, 1, 0)
		Page.Visible = false
		Page.ScrollBarThickness = 3
		Page.ScrollBarImageColor3 = Config.Colors.Accent
		-- FIX QUAN TRỌNG: Tự động tính toán chiều cao nội dung
		Page.AutomaticCanvasSize = Enum.AutomaticSize.Y 
		Page.CanvasSize = UDim2.new(0,0,0,0) 
		
		local PageLayout = Instance.new("UIListLayout")
		PageLayout.Parent = Page
		PageLayout.SortOrder = Enum.SortOrder.LayoutOrder
		PageLayout.Padding = UDim.new(0, 6)
		
		local PagePadding = Instance.new("UIPadding")
		PagePadding.Parent = Page
		PagePadding.PaddingTop = UDim.new(0, 10)
		PagePadding.PaddingLeft = UDim.new(0, 10)
		PagePadding.PaddingRight = UDim.new(0, 10)
		PagePadding.PaddingBottom = UDim.new(0, 10)
		
		local function Activate()
			if CurrentPage == Page then return end
			
			for _, btn in pairs(TabScroll:GetChildren()) do
				if btn:IsA("TextButton") then
					TweenService:Create(btn.TextLabel, TweenInfo.new(0.2), {TextColor3 = Config.Colors.TextDim}):Play()
					TweenService:Create(btn.ImageLabel, TweenInfo.new(0.2), {ImageColor3 = Config.Colors.TextDim}):Play()
					TweenService:Create(btn.Frame, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
				end
			end
			
			for _, p in pairs(PageContainer:GetChildren()) do
				if p:IsA("ScrollingFrame") then p.Visible = false end
			end
			
			TweenService:Create(TabTitle, TweenInfo.new(0.2), {TextColor3 = Config.Colors.Text}):Play()
			TweenService:Create(TabIcon, TweenInfo.new(0.2), {ImageColor3 = Config.Colors.Text}):Play()
			TweenService:Create(TabIndicator, TweenInfo.new(0.2), {BackgroundTransparency = 0}):Play()
			
			Page.Visible = true
			
			if Library.Settings.PageAnimation then
				Page.CanvasPosition = Vector2.new(0, 0) -- Reset scroll khi qua tab mới
				Page.BackgroundTransparency = 1
				local fadeInfo = TweenInfo.new(0.3)
				for _, element in pairs(Page:GetChildren()) do
					if element:IsA("Frame") or element:IsA("TextButton") then
						element.BackgroundTransparency = 1
						local targetAlpha = element:GetAttribute("TargetAlpha") or 0
						TweenService:Create(element, fadeInfo, {BackgroundTransparency = targetAlpha}):Play()
					end
				end
			end
			
			CurrentPage = Page
		end
		
		TabBtn.MouseButton1Click:Connect(Activate)
		
		if FirstTab then
			FirstTab = false
			Activate()
		end
		
		-- ELEMENTS
		local Elements = {}
		
		function Elements:Button(text, callback)
			local Button = Instance.new("TextButton")
			Button.Name = "Button"
			Button.Parent = Page
			Button.BackgroundColor3 = Config.Colors.Primary
			Button.Size = UDim2.new(1, 0, 0, 38)
			Button.AutoButtonColor = false
			Button.Text = ""
			Button:SetAttribute("TargetAlpha", 0)
			CreateCorner(Button, 6)
			
			local BtnTitle = Instance.new("TextLabel")
			BtnTitle.Parent = Button
			BtnTitle.BackgroundTransparency = 1
			BtnTitle.Position = UDim2.new(0, 15, 0, 0)
			BtnTitle.Size = UDim2.new(1, -15, 1, 0)
			BtnTitle.Font = Enum.Font.GothamMedium
			BtnTitle.Text = text
			BtnTitle.TextColor3 = Config.Colors.Text
			BtnTitle.TextSize = 14
			BtnTitle.TextXAlignment = Enum.TextXAlignment.Left
			
			local BtnIcon = Instance.new("ImageLabel")
			BtnIcon.Parent = Button
			BtnIcon.BackgroundTransparency = 1
			BtnIcon.AnchorPoint = Vector2.new(1, 0.5)
			BtnIcon.Position = UDim2.new(1, -10, 0.5, 0)
			BtnIcon.Size = UDim2.new(0, 20, 0, 20)
			BtnIcon.Image = "rbxassetid://10734898355"
			
			Button.MouseButton1Click:Connect(function()
				TweenService:Create(Button, TweenInfo.new(0.1), {BackgroundColor3 = Config.Colors.Accent}):Play()
				task.wait(0.1)
				TweenService:Create(Button, TweenInfo.new(0.2), {BackgroundColor3 = Config.Colors.Primary}):Play()
				pcall(callback)
			end)
		end
		
		function Elements:Toggle(text, default, callback)
			local toggled = default or false
			
			local ToggleFrame = Instance.new("TextButton")
			ToggleFrame.Name = "Toggle"
			ToggleFrame.Parent = Page
			ToggleFrame.BackgroundColor3 = Config.Colors.Primary
			ToggleFrame.Size = UDim2.new(1, 0, 0, 38)
			ToggleFrame.AutoButtonColor = false
			ToggleFrame.Text = ""
			ToggleFrame:SetAttribute("TargetAlpha", 0)
			CreateCorner(ToggleFrame, 6)
			
			local ToggleTitle = Instance.new("TextLabel")
			ToggleTitle.Parent = ToggleFrame
			ToggleTitle.BackgroundTransparency = 1
			ToggleTitle.Position = UDim2.new(0, 15, 0, 0)
			ToggleTitle.Size = UDim2.new(1, -60, 1, 0)
			ToggleTitle.Font = Enum.Font.GothamMedium
			ToggleTitle.Text = text
			ToggleTitle.TextColor3 = Config.Colors.Text
			ToggleTitle.TextSize = 14
			ToggleTitle.TextXAlignment = Enum.TextXAlignment.Left
			
			local SwitchBg = Instance.new("Frame")
			SwitchBg.Parent = ToggleFrame
			SwitchBg.AnchorPoint = Vector2.new(1, 0.5)
			SwitchBg.Position = UDim2.new(1, -10, 0.5, 0)
			SwitchBg.Size = UDim2.new(0, 40, 0, 22)
			SwitchBg.BackgroundColor3 = toggled and Config.Colors.Accent or Color3.fromRGB(60, 60, 60)
			CreateCorner(SwitchBg, 12)
			
			local SwitchCircle = Instance.new("Frame")
			SwitchCircle.Parent = SwitchBg
			SwitchCircle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			SwitchCircle.Size = UDim2.new(0, 18, 0, 18)
			SwitchCircle.Position = toggled and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)
			CreateCorner(SwitchCircle, 100)
			
			ToggleFrame.MouseButton1Click:Connect(function()
				toggled = not toggled
				
				TweenService:Create(SwitchBg, TweenInfo.new(0.2), {BackgroundColor3 = toggled and Config.Colors.Accent or Color3.fromRGB(60, 60, 60)}):Play()
				
				if toggled then
					TweenService:Create(SwitchCircle, TweenInfo.new(0.2), {Position = UDim2.new(1, -20, 0.5, -9)}):Play()
				else
					TweenService:Create(SwitchCircle, TweenInfo.new(0.2), {Position = UDim2.new(0, 2, 0.5, -9)}):Play()
				end
				
				pcall(callback, toggled)
			end)
		end
		
		function Elements:Slider(text, min, max, default, callback)
			local value = default or min
			local dragging = false
			
			local SliderFrame = Instance.new("Frame")
			SliderFrame.Name = "Slider"
			SliderFrame.Parent = Page
			SliderFrame.BackgroundColor3 = Config.Colors.Primary
			SliderFrame.Size = UDim2.new(1, 0, 0, 50)
			SliderFrame:SetAttribute("TargetAlpha", 0)
			CreateCorner(SliderFrame, 6)
			
			local SliderTitle = Instance.new("TextLabel")
			SliderTitle.Parent = SliderFrame
			SliderTitle.BackgroundTransparency = 1
			SliderTitle.Position = UDim2.new(0, 15, 0, 5)
			SliderTitle.Size = UDim2.new(1, -30, 0, 20)
			SliderTitle.Font = Enum.Font.GothamMedium
			SliderTitle.Text = text
			SliderTitle.TextColor3 = Config.Colors.Text
			SliderTitle.TextSize = 14
			SliderTitle.TextXAlignment = Enum.TextXAlignment.Left
			
			local ValueLabel = Instance.new("TextLabel")
			ValueLabel.Parent = SliderFrame
			ValueLabel.BackgroundTransparency = 1
			ValueLabel.Position = UDim2.new(1, -15, 0, 5)
			ValueLabel.AnchorPoint = Vector2.new(1, 0)
			ValueLabel.Size = UDim2.new(0, 50, 0, 20)
			ValueLabel.Font = Enum.Font.GothamBold
			ValueLabel.Text = tostring(value)
			ValueLabel.TextColor3 = Config.Colors.Text
			ValueLabel.TextSize = 14
			ValueLabel.TextXAlignment = Enum.TextXAlignment.Right
			
			local SlideBg = Instance.new("TextButton")
			SlideBg.Parent = SliderFrame
			SlideBg.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
			SlideBg.Position = UDim2.new(0, 15, 0, 32)
			SlideBg.Size = UDim2.new(1, -30, 0, 6)
			SlideBg.AutoButtonColor = false
			SlideBg.Text = ""
			CreateCorner(SlideBg, 3)
			
			local SlideFill = Instance.new("Frame")
			SlideFill.Parent = SlideBg
			SlideFill.BackgroundColor3 = Config.Colors.Accent
			SlideFill.Size = UDim2.new((value - min) / (max - min), 0, 1, 0)
			CreateCorner(SlideFill, 3)
			
			local function Update(input)
				local pos = UDim2.new(math.clamp((input.Position.X - SlideBg.AbsolutePosition.X) / SlideBg.AbsoluteSize.X, 0, 1), 0, 1, 0)
				local newVal = math.floor(min + ((max - min) * pos.X.Scale))
				
				TweenService:Create(SlideFill, TweenInfo.new(0.05), {Size = pos}):Play()
				ValueLabel.Text = tostring(newVal)
				pcall(callback, newVal)
			end
			
			SlideBg.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					dragging = true
					Update(input)
				end
			end)
			
			UserInputService.InputEnded:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					dragging = false
				end
			end)
			
			UserInputService.InputChanged:Connect(function(input)
				if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
					Update(input)
				end
			end)
		end
		
		return Elements
	end
	
	return Tabs
end

return Library
