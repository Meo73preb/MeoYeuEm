if (game:GetService("CoreGui")):FindFirstChild("TeaCatHub") then
	(game:GetService("CoreGui")).TeaCatHub:Destroy()
end
_G.Primary = Color3.fromRGB(100, 100, 100)
_G.Dark = Color3.fromRGB(22, 22, 26)
_G.Third = Color3.fromRGB(255, 0, 0)
function CreateRounded(Parent, Size)
	local Rounded = Instance.new("UICorner")
	Rounded.Name = "Rounded"
	Rounded.Parent = Parent
	Rounded.CornerRadius = UDim.new(0, Size)
end
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local function scaleText(label, max)
	label.TextScaled = true
	local constraint = Instance.new("UITextSizeConstraint")
	constraint.MaxTextSize = max or 15
	constraint.MinTextSize = 8
	constraint.Parent = label
end
function MakeDraggable(topbarobject, object)
	local Dragging = nil
	local DragInput = nil
	local DragStart = nil
	local StartPosition = nil
	local function Update(input)
		local Delta = input.Position - DragStart
		local pos = UDim2.new(StartPosition.X.Scale, StartPosition.X.Offset + Delta.X, StartPosition.Y.Scale, StartPosition.Y.Offset + Delta.Y)
		local Tween = TweenService:Create(object, TweenInfo.new(0.12, Enum.EasingStyle.Out, Enum.EasingDirection.Quad), {
			Position = pos
		})
		Tween:Play()
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
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Parent = game.CoreGui
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
local OutlineButton = Instance.new("Frame")
OutlineButton.Name = "OutlineButton"
OutlineButton.Parent = ScreenGui
OutlineButton.ClipsDescendants = true
OutlineButton.BackgroundColor3 = _G.Dark
OutlineButton.BackgroundTransparency = 0
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
ImageButton.ImageTransparency = 0
ImageButton.BackgroundTransparency = 0
ImageButton.Image = "rbxassetid://13940080072"
ImageButton.AutoButtonColor = false
MakeDraggable(ImageButton, OutlineButton)
CreateRounded(ImageButton, 10)
ImageButton.MouseButton1Click:Connect(function()
	local hub = game.CoreGui:FindFirstChild("TeaCatHub")
	if hub then
		hub.Enabled = not hub.Enabled
	end
end)
local NotificationGui = Instance.new("ScreenGui")
NotificationGui.Name = "NotificationGui"
NotificationGui.Parent = game.CoreGui
NotificationGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
local NotificationContainer = Instance.new("Frame")
NotificationContainer.Name = "NotificationContainer"
NotificationContainer.Parent = NotificationGui
NotificationContainer.Size = UDim2.new(0, 430, 0, 600)
NotificationContainer.Position = UDim2.new(1, -20, 0, 20)
NotificationContainer.AnchorPoint = Vector2.new(1, 0)
NotificationContainer.BackgroundTransparency = 1
local NotificationLayout = Instance.new("UIListLayout")
NotificationLayout.Parent = NotificationContainer
NotificationLayout.SortOrder = Enum.SortOrder.LayoutOrder
NotificationLayout.Padding = UDim.new(0, 10)
NotificationLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
local Update = {}
function Update:Notify(desc)
	local OutlineFrame = Instance.new("Frame")
	OutlineFrame.Name = "OutlineFrame"
	OutlineFrame.Parent = NotificationContainer
	OutlineFrame.ClipsDescendants = true
	OutlineFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	OutlineFrame.BackgroundTransparency = 0.4
	OutlineFrame.Size = UDim2.new(0, 412, 0, 72)
	OutlineFrame.Position = UDim2.new(1.5, 0, 0, 0)
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
	Image.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	Image.BackgroundTransparency = 1
	Image.Position = UDim2.new(0, 8, 0, 8)
	Image.Size = UDim2.new(0, 45, 0, 45)
	Image.Image = "rbxassetid://13940080072"
	local Title = Instance.new("TextLabel")
	Title.Parent = Frame
	Title.BackgroundColor3 = _G.Primary
	Title.BackgroundTransparency = 1
	Title.Position = UDim2.new(0, 55, 0, 12)
	Title.Size = UDim2.new(0, 300, 0, 20)
	Title.Font = Enum.Font.GothamBold
	Title.Text = "Tea Cat Hub"
	Title.TextColor3 = Color3.fromRGB(255, 255, 255)
	scaleText(Title, 16)
	Title.TextXAlignment = Enum.TextXAlignment.Left
	local Desc = Instance.new("TextLabel")
	Desc.Parent = Frame
	Desc.BackgroundColor3 = _G.Primary
	Desc.BackgroundTransparency = 1
	Desc.Position = UDim2.new(0, 55, 0, 31)
	Desc.Size = UDim2.new(0, 330, 0, 20)
	Desc.Font = Enum.Font.GothamSemibold
	Desc.TextTransparency = 0.3
	Desc.Text = desc or ""
	Desc.TextColor3 = Color3.fromRGB(200, 200, 200)
	scaleText(Desc, 12)
	Desc.TextXAlignment = Enum.TextXAlignment.Left
	TweenService:Create(OutlineFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(0, 0, 0, 0)
	}):Play()
	task.delay(4, function()
		local slideOut = TweenService:Create(OutlineFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Position = UDim2.new(1.5, 0, 0, 0),
			BackgroundTransparency = 1
		})
		slideOut:Play()
		slideOut.Completed:Connect(function()
			OutlineFrame:Destroy()
		end)
	end)
end
function Update:Window(Config)
	local WindowConfig = {
		Size = Config.Size,
		TabWidth = Config.TabWidth
	}
	local abc = false
	local currentpage = ""
	local keybind = Config.Keybind or Enum.KeyCode.RightControl
	local TeaCatHub = Instance.new("ScreenGui")
	TeaCatHub.Name = "TeaCatHub"
	TeaCatHub.Parent = game.CoreGui
	TeaCatHub.DisplayOrder = 999
	local OutlineMain = Instance.new("Frame")
	OutlineMain.Name = "OutlineMain"
	OutlineMain.Parent = TeaCatHub
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
	Main.BackgroundTransparency = 0
	Main.Position = UDim2.new(0.5, 0, 0.5, 0)
	Main.Size = WindowConfig.Size
	OutlineMain:TweenSize(UDim2.new(0, WindowConfig.Size.X.Offset + 15, 0, WindowConfig.Size.Y.Offset + 15), "Out", "Quad", 0.4, true)
	CreateRounded(Main, 12)
	local DragButton = Instance.new("Frame")
	DragButton.Name = "DragButton"
	DragButton.Parent = Main
	DragButton.Position = UDim2.new(1, 5, 1, 5)
	DragButton.AnchorPoint = Vector2.new(1, 1)
	DragButton.Size = UDim2.new(0, 15, 0, 15)
	DragButton.BackgroundColor3 = _G.Primary
	DragButton.BackgroundTransparency = 1
	DragButton.ZIndex = 10
	local CircleDragButton = Instance.new("UICorner")
	CircleDragButton.Name = "CircleDragButton"
	CircleDragButton.Parent = DragButton
	CircleDragButton.CornerRadius = UDim.new(0, 99)
	local Top = Instance.new("Frame")
	Top.Name = "Top"
	Top.Parent = Main
	Top.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
	Top.Size = UDim2.new(1, 0, 0, 40)
	Top.BackgroundTransparency = 1
	CreateRounded(Top, 5)
	local NameHub = Instance.new("TextLabel")
	NameHub.Name = "NameHub"
	NameHub.Parent = Top
	NameHub.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	NameHub.BackgroundTransparency = 1
	NameHub.RichText = true
	NameHub.Position = UDim2.new(0, 15, 0.5, 0)
	NameHub.AnchorPoint = Vector2.new(0, 0.5)
	NameHub.Size = UDim2.new(0, 1, 0, 25)
	NameHub.Font = Enum.Font.GothamBold
	NameHub.Text = "Tea Cat Hub"
	NameHub.TextColor3 = Color3.fromRGB(255, 255, 255)
	NameHub.TextXAlignment = Enum.TextXAlignment.Left
	scaleText(NameHub, 20)
	local nameHubSize = (game:GetService("TextService")):GetTextSize("Tea Cat Hub", 20, NameHub.Font, Vector2.new(math.huge, math.huge))
	NameHub.Size = UDim2.new(0, nameHubSize.X + 10, 0, 25)
	local SubTitle = Instance.new("TextLabel")
	SubTitle.Name = "SubTitle"
	SubTitle.Parent = NameHub
	SubTitle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	SubTitle.BackgroundTransparency = 1
	SubTitle.Position = UDim2.new(0, nameHubSize.X + 15, 0.5, 0)
	SubTitle.Size = UDim2.new(0, 1, 0, 20)
	SubTitle.Font = Enum.Font.Cartoon
	SubTitle.AnchorPoint = Vector2.new(0, 0.5)
	SubTitle.Text = Config.SubTitle or "v4"
	SubTitle.TextColor3 = Color3.fromRGB(150, 150, 150)
	scaleText(SubTitle, 15)
	local SubTitleSize = (game:GetService("TextService")):GetTextSize(SubTitle.Text, 15, SubTitle.Font, Vector2.new(math.huge, math.huge))
	SubTitle.Size = UDim2.new(0, SubTitleSize.X + 10, 0, 25)
	local CloseButton = Instance.new("ImageButton")
	CloseButton.Name = "CloseButton"
	CloseButton.Parent = Top
	CloseButton.BackgroundColor3 = _G.Primary
	CloseButton.BackgroundTransparency = 1
	CloseButton.AnchorPoint = Vector2.new(1, 0.5)
	CloseButton.Position = UDim2.new(1, -15, 0.5, 0)
	CloseButton.Size = UDim2.new(0, 20, 0, 20)
	CloseButton.Image = "rbxassetid://7743878857"
	CloseButton.ImageTransparency = 0
	CloseButton.ImageColor3 = Color3.fromRGB(245, 245, 245)
	CreateRounded(CloseButton, 3)
	CloseButton.MouseButton1Click:Connect(function()
		TeaCatHub.Enabled = not TeaCatHub.Enabled
	end)
	local Tab = Instance.new("Frame")
	Tab.Name = "Tab"
	Tab.Parent = Main
	Tab.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
	Tab.Position = UDim2.new(0, 8, 0, 40)
	Tab.BackgroundTransparency = 1
	Tab.Size = UDim2.new(0, WindowConfig.TabWidth, 1, -48)
	local ScrollTab = Instance.new("ScrollingFrame")
	ScrollTab.Name = "ScrollTab"
	ScrollTab.Parent = Tab
	ScrollTab.Active = true
	ScrollTab.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
	ScrollTab.Position = UDim2.new(0, 0, 0, 0)
	ScrollTab.BackgroundTransparency = 1
	ScrollTab.Size = UDim2.new(1, 0, 1, 0)
	ScrollTab.ScrollBarThickness = 0
	ScrollTab.ScrollingDirection = Enum.ScrollingDirection.Y
	CreateRounded(Tab, 5)
	local TabListLayout = Instance.new("UIListLayout")
	TabListLayout.Name = "TabListLayout"
	TabListLayout.Parent = ScrollTab
	TabListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	TabListLayout.Padding = UDim.new(0, 2)
	local PPD = Instance.new("UIPadding")
	PPD.Name = "PPD"
	PPD.Parent = ScrollTab
	local Page = Instance.new("Frame")
	Page.Name = "Page"
	Page.Parent = Main
	Page.BackgroundColor3 = _G.Dark
	Page.Position = UDim2.new(0, WindowConfig.TabWidth + 18, 0, 40)
	Page.Size = UDim2.new(1, -WindowConfig.TabWidth - 25, 1, -48)
	Page.BackgroundTransparency = 1
	CreateRounded(Page, 3)
	local MainPage = Instance.new("Frame")
	MainPage.Name = "MainPage"
	MainPage.Parent = Page
	MainPage.ClipsDescendants = true
	MainPage.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
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
	UIPageLayout.FillDirection = Enum.FillDirection.Vertical
	UIPageLayout.Padding = UDim.new(0, 10)
	UIPageLayout.TweenTime = 0
	UIPageLayout.GamepadInputEnabled = false
	UIPageLayout.ScrollWheelInputEnabled = false
	UIPageLayout.TouchInputEnabled = false
	MakeDraggable(Top, OutlineMain)
	UserInputService.InputBegan:Connect(function(input)
		if input.KeyCode == keybind or input.KeyCode == Enum.KeyCode.Insert then
			TeaCatHub.Enabled = not TeaCatHub.Enabled
		end
	end)
	local Resizing = false
	DragButton.InputBegan:Connect(function(Input)
		if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
			Resizing = true
		end
	end)
	UserInputService.InputEnded:Connect(function(Input)
		if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
			Resizing = false
		end
	end)
	UserInputService.InputChanged:Connect(function(Input)
		if Resizing and (Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch) then
			local deltaX = Input.Position.X - Main.AbsolutePosition.X
			local deltaY = Input.Position.Y - Main.AbsolutePosition.Y
			local newX = math.clamp(deltaX, WindowConfig.Size.X.Offset, 1200)
			local newY = math.clamp(deltaY, WindowConfig.Size.Y.Offset, 900)
			OutlineMain.Size = UDim2.new(0, newX + 15, 0, newY + 15)
			Main.Size = UDim2.new(0, newX, 0, newY)
		end
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
		local SelectedTab = Instance.new("Frame")
		SelectedTab.Name = "SelectedTab"
		SelectedTab.Parent = TabButton
		SelectedTab.BackgroundColor3 = _G.Third
		SelectedTab.BackgroundTransparency = 0
		SelectedTab.Size = UDim2.new(0, 3, 0, 0)
		SelectedTab.Position = UDim2.new(0, 0, 0.5, 0)
		SelectedTab.AnchorPoint = Vector2.new(0, 0.5)
		CreateRounded(SelectedTab, 100)
		local Title = Instance.new("TextLabel")
		Title.Parent = TabButton
		Title.Name = "Title"
		Title.BackgroundColor3 = Color3.fromRGB(150, 150, 150)
		Title.BackgroundTransparency = 1
		Title.Position = UDim2.new(0, 30, 0.5, 0)
		Title.Size = UDim2.new(1, -35, 0.8, 0)
		Title.Font = Enum.Font.Roboto
		Title.Text = text
		Title.AnchorPoint = Vector2.new(0, 0.5)
		Title.TextColor3 = Color3.fromRGB(255, 255, 255)
		Title.TextTransparency = 0.4
		Title.TextXAlignment = Enum.TextXAlignment.Left
		scaleText(Title, 14)
		local IDK = Instance.new("ImageLabel")
		IDK.Name = "IDK"
		IDK.Parent = TabButton
		IDK.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		IDK.BackgroundTransparency = 1
		IDK.ImageTransparency = 0.3
		IDK.Position = UDim2.new(0, 7, 0.5, 0)
		IDK.Size = UDim2.new(0, 15, 0, 15)
		IDK.AnchorPoint = Vector2.new(0, 0.5)
		IDK.Image = img
		CreateRounded(TabButton, 6)
		local MainFramePage = Instance.new("ScrollingFrame")
		MainFramePage.Name = text .. "_Page"
		MainFramePage.Parent = PageList
		MainFramePage.Active = true
		MainFramePage.BackgroundColor3 = _G.Dark
		MainFramePage.Position = UDim2.new(0, 0, 0, 0)
		MainFramePage.BackgroundTransparency = 1
		MainFramePage.Size = UDim2.new(1, 0, 1, 0)
		MainFramePage.ScrollBarThickness = 0
		MainFramePage.ScrollingDirection = Enum.ScrollingDirection.Y
		local zzzR = Instance.new("UICorner")
		zzzR.Parent = MainPage
		zzzR.CornerRadius = UDim.new(0, 5)
		local UIPadding = Instance.new("UIPadding")
		UIPadding.Parent = MainFramePage
		local UIListLayout = Instance.new("UIListLayout")
		UIListLayout.Padding = UDim.new(0, 3)
		UIListLayout.Parent = MainFramePage
		UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
		TabButton.MouseButton1Click:Connect(function()
			for _, v in next, ScrollTab:GetChildren() do
				if v:IsA("TextButton") then
					TweenService:Create(v, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
						BackgroundTransparency = 1
					}):Play()
					TweenService:Create(v.SelectedTab, TweenInfo.new(0, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
						Size = UDim2.new(0, 3, 0, 0)
					}):Play()
					TweenService:Create(v.IDK, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
						ImageTransparency = 0.4
					}):Play()
					TweenService:Create(v.Title, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
						TextTransparency = 0.4
					}):Play()
				end
			end
			TweenService:Create(TabButton, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				BackgroundTransparency = 0.8
			}):Play()
			TweenService:Create(SelectedTab, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Size = UDim2.new(0, 3, 0, 15)
			}):Play()
			TweenService:Create(IDK, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				ImageTransparency = 0
			}):Play()
			TweenService:Create(Title, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				TextTransparency = 0
			}):Play()
			currentpage = string.gsub(TabButton.Name, "Unique", "") .. "_Page"
			local targetPage = PageList:FindFirstChild(currentpage)
			if targetPage then
				UIPageLayout:JumpTo(targetPage)
			end
		end)
		if abc == false then
			TweenService:Create(TabButton, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				BackgroundTransparency = 0.8
			}):Play()
			TweenService:Create(SelectedTab, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Size = UDim2.new(0, 3, 0, 15)
			}):Play()
			TweenService:Create(IDK, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				ImageTransparency = 0
			}):Play()
			TweenService:Create(Title, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				TextTransparency = 0
			}):Play()
			UIPageLayout:JumpToIndex(1)
			abc = true
		end
		local function UpdateCanvasSizes()
			pcall(function()
				MainFramePage.CanvasSize = UDim2.new(0, 0, 0, UIListLayout.AbsoluteContentSize.Y)
				ScrollTab.CanvasSize = UDim2.new(0, 0, 0, TabListLayout.AbsoluteContentSize.Y)
			end)
		end
		UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(UpdateCanvasSizes)
		TabListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(UpdateCanvasSizes)
		local main = {}
		function main:Button(text, callback)
			local Button = Instance.new("Frame")
			Button.Name = "Button"
			Button.Parent = MainFramePage
			Button.BackgroundColor3 = _G.Primary
			Button.BackgroundTransparency = 1
			Button.Size = UDim2.new(1, 0, 0, 36)
			CreateRounded(Button, 5)
			local TextButton = Instance.new("TextButton")
			TextButton.Name = "TextButton"
			TextButton.Parent = Button
			TextButton.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
			TextButton.BackgroundTransparency = 0.8
			TextButton.AnchorPoint = Vector2.new(1, 0.5)
			TextButton.Position = UDim2.new(1, -1, 0.5, 0)
			TextButton.Size = UDim2.new(0, 25, 0, 25)
			TextButton.Font = Enum.Font.Nunito
			TextButton.Text = ""
			TextButton.TextColor3 = Color3.fromRGB(255, 255, 255)
			CreateRounded(TextButton, 4)
			local ImageLabel = Instance.new("ImageLabel")
			ImageLabel.Name = "ImageLabel"
			ImageLabel.Parent = TextButton
			ImageLabel.BackgroundColor3 = _G.Primary
			ImageLabel.BackgroundTransparency = 1
			ImageLabel.AnchorPoint = Vector2.new(0.5, 0.5)
			ImageLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
			ImageLabel.Size = UDim2.new(0, 15, 0, 15)
			ImageLabel.Image = "rbxassetid://10734898355"
			ImageLabel.ImageTransparency = 0
			ImageLabel.ImageColor3 = Color3.fromRGB(255, 255, 255)
			local TextLabel = Instance.new("TextLabel")
			TextLabel.Name = "TextLabel"
			TextLabel.Parent = Button
			TextLabel.BackgroundColor3 = _G.Primary
			TextLabel.BackgroundTransparency = 1
			TextLabel.AnchorPoint = Vector2.new(0, 0.5)
			TextLabel.Position = UDim2.new(0, 20, 0.5, 0)
			TextLabel.Size = UDim2.new(1, -50, 1, 0)
			TextLabel.Font = Enum.Font.Cartoon
			TextLabel.RichText = true
			TextLabel.Text = text
			TextLabel.TextXAlignment = Enum.TextXAlignment.Left
			TextLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
			scaleText(TextLabel, 15)
			TextLabel.ClipsDescendants = true
			local ArrowRight = Instance.new("ImageLabel")
			ArrowRight.Name = "ArrowRight"
			ArrowRight.Parent = Button
			ArrowRight.BackgroundColor3 = _G.Primary
			ArrowRight.BackgroundTransparency = 1
			ArrowRight.AnchorPoint = Vector2.new(0, 0.5)
			ArrowRight.Position = UDim2.new(0, 0, 0.5, 0)
			ArrowRight.Size = UDim2.new(0, 15, 0, 15)
			ArrowRight.Image = "rbxassetid://10709768347"
			ArrowRight.ImageTransparency = 0
			ArrowRight.ImageColor3 = Color3.fromRGB(255, 255, 255)
			local Black = Instance.new("Frame")
			Black.Name = "Black"
			Black.Parent = Button
			Black.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
			Black.BackgroundTransparency = 1
			Black.BorderSizePixel = 0
			Black.Position = UDim2.new(0, 0, 0, 0)
			Black.Size = UDim2.new(1, 0, 1, 0)
			CreateRounded(Black, 5)
			TextButton.MouseButton1Click:Connect(function()
				pcall(callback)
			end)
		end
		function main:Toggle(text, config, desc, callback)
			local toggled = config or false
			local Button = Instance.new("TextButton")
			Button.Name = "Button"
			Button.Parent = MainFramePage
			Button.BackgroundColor3 = _G.Primary
			Button.BackgroundTransparency = 0.8
			Button.AutoButtonColor = false
			Button.Font = Enum.Font.SourceSans
			Button.Text = ""
			Button.TextColor3 = Color3.fromRGB(0, 0, 0)
			CreateRounded(Button, 5)
			local Title2 = Instance.new("TextLabel")
			Title2.Parent = Button
			Title2.BackgroundColor3 = Color3.fromRGB(150, 150, 150)
			Title2.BackgroundTransparency = 1
			Title2.Size = UDim2.new(0.7, 0, 0.8, 0)
			Title2.Font = Enum.Font.Cartoon
			Title2.Text = text
			Title2.TextColor3 = Color3.fromRGB(255, 255, 255)
			Title2.TextXAlignment = Enum.TextXAlignment.Left
			Title2.AnchorPoint = Vector2.new(0, 0.5)
			scaleText(Title2, 15)
			local Desc = Instance.new("TextLabel")
			Desc.Parent = Title2
			Desc.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
			Desc.BackgroundTransparency = 1
			Desc.Size = UDim2.new(1, 0, 0.4, 0)
			Desc.Font = Enum.Font.Gotham
			Desc.TextColor3 = Color3.fromRGB(150, 150, 150)
			Desc.TextXAlignment = Enum.TextXAlignment.Left
			scaleText(Desc, 10)
			if desc then
				Desc.Text = desc
				Title2.Position = UDim2.new(0, 15, 0.4, 0)
				Desc.Position = UDim2.new(0, 0, 1, 0)
				Button.Size = UDim2.new(1, 0, 0, 46)
			else
				Title2.Position = UDim2.new(0, 15, 0.5, 0)
				Desc.Visible = false
				Button.Size = UDim2.new(1, 0, 0, 36)
			end
			local ToggleFrame = Instance.new("Frame")
			ToggleFrame.Name = "ToggleFrame"
			ToggleFrame.Parent = Button
			ToggleFrame.BackgroundColor3 = _G.Dark
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
			Circle.BackgroundTransparency = 0
			Circle.Position = UDim2.new(0, 3, 0.5, 0)
			Circle.Size = UDim2.new(0, 14, 0, 14)
			Circle.AnchorPoint = Vector2.new(0, 0.5)
			CreateRounded(Circle, 10)
			local function UpdateToggleVisual(animate)
				local targetX = toggled and 17 or 3
				local targetColor = toggled and _G.Third or Color3.fromRGB(200, 200, 200)
				local targetTrans = toggled and 0 or 0.8
				if animate then
					Circle:TweenPosition(UDim2.new(0, targetX, 0.5, 0), "Out", "Sine", 0.15, true)
					TweenService:Create(ToggleImage, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
						BackgroundColor3 = targetColor,
						BackgroundTransparency = targetTrans
					}):Play()
				else
					Circle.Position = UDim2.new(0, targetX, 0.5, 0)
					ToggleImage.BackgroundColor3 = targetColor
					ToggleImage.BackgroundTransparency = targetTrans
				end
			end
			local function Toggle()
				toggled = not toggled
				UpdateToggleVisual(true)
				pcall(callback, toggled)
			end
			ToggleImage.MouseButton1Click:Connect(Toggle)
			Button.MouseButton1Click:Connect(Toggle)
			UpdateToggleVisual(false)
			pcall(callback, toggled)
		end
		function main:Dropdown(text, option, var, callback)
			local isdropping = false
			local activeItem = tostring(var or "")
			local Dropdown = Instance.new("Frame")
			Dropdown.Name = "Dropdown"
			Dropdown.Parent = MainFramePage
			Dropdown.BackgroundColor3 = _G.Primary
			Dropdown.BackgroundTransparency = 0.8
			Dropdown.ClipsDescendants = false
			Dropdown.Size = UDim2.new(1, 0, 0, 40)
			CreateRounded(Dropdown, 5)
			local DropTitle = Instance.new("TextLabel")
			DropTitle.Name = "DropTitle"
			DropTitle.Parent = Dropdown
			DropTitle.BackgroundColor3 = _G.Primary
			DropTitle.BackgroundTransparency = 1
			DropTitle.Size = UDim2.new(0.6, 0, 0.7, 0)
			DropTitle.Font = Enum.Font.Cartoon
			DropTitle.Text = text
			DropTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
			DropTitle.TextXAlignment = Enum.TextXAlignment.Left
			DropTitle.Position = UDim2.new(0, 15, 0.5, 0)
			DropTitle.AnchorPoint = Vector2.new(0, 0.5)
			scaleText(DropTitle, 15)
			local SelectItems = Instance.new("TextButton")
			SelectItems.Name = "SelectItems"
			SelectItems.Parent = Dropdown
			SelectItems.BackgroundColor3 = Color3.fromRGB(24, 24, 26)
			SelectItems.TextColor3 = Color3.fromRGB(255, 255, 255)
			SelectItems.BackgroundTransparency = 0
			SelectItems.Position = UDim2.new(1, -5, 0, 5)
			SelectItems.Size = UDim2.new(0, 100, 0, 30)
			SelectItems.AnchorPoint = Vector2.new(1, 0)
			SelectItems.Font = Enum.Font.GothamMedium
			SelectItems.AutoButtonColor = false
			SelectItems.ClipsDescendants = true
			SelectItems.Text = "   Vui lòng chọn"
			SelectItems.TextXAlignment = Enum.TextXAlignment.Left
			scaleText(SelectItems, 11)
			CreateRounded(SelectItems, 5)
			local ArrowDown = Instance.new("ImageLabel")
			ArrowDown.Name = "ArrowDown"
			ArrowDown.Parent = Dropdown
			ArrowDown.BackgroundColor3 = _G.Primary
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
			DropdownFrameScroll.Size = UDim2.new(1, 0, 0, 0)
			DropdownFrameScroll.Position = UDim2.new(0, 5, 0, 40)
			DropdownFrameScroll.Visible = false
			CreateRounded(DropdownFrameScroll, 5)
			local DropScroll = Instance.new("ScrollingFrame")
			DropScroll.Name = "DropScroll"
			DropScroll.Parent = DropdownFrameScroll
			DropScroll.ScrollingDirection = Enum.ScrollingDirection.Y
			DropScroll.Active = true
			DropScroll.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			DropScroll.BackgroundTransparency = 1
			DropScroll.BorderSizePixel = 0
			DropScroll.Position = UDim2.new(0, 0, 0, 10)
			DropScroll.Size = UDim2.new(1, 0, 0, 80)
			DropScroll.ScrollBarThickness = 3
			DropScroll.ZIndex = 3
			local PaddingDrop = Instance.new("UIPadding")
			PaddingDrop.PaddingLeft = UDim.new(0, 10)
			PaddingDrop.PaddingRight = UDim.new(0, 10)
			PaddingDrop.Parent = DropScroll
			local DropListLayout = Instance.new("UIListLayout")
			DropListLayout.Parent = DropScroll
			DropListLayout.SortOrder = Enum.SortOrder.LayoutOrder
			DropListLayout.Padding = UDim.new(0, 1)
			local function UpdateDropVisuals()
				for _, v in next, DropScroll:GetChildren() do
					if v:IsA("TextButton") then
						local SelectedItemsMark = v:FindFirstChild("SelectedItems")
						if activeItem == v.Text then
							v.BackgroundTransparency = 0.8
							v.TextTransparency = 0
							if SelectedItemsMark then SelectedItemsMark.BackgroundTransparency = 0 end
						else
							v.BackgroundTransparency = 1
							v.TextTransparency = 0.5
							if SelectedItemsMark then SelectedItemsMark.BackgroundTransparency = 1 end
						end
					end
				end
			end
			local function AddItem(itemText)
				local Item = Instance.new("TextButton")
				Item.Name = "Item"
				Item.Parent = DropScroll
				Item.BackgroundColor3 = _G.Primary
				Item.BackgroundTransparency = 1
				Item.Size = UDim2.new(1, 0, 0, 30)
				Item.Font = Enum.Font.Nunito
				Item.Text = tostring(itemText)
				Item.TextColor3 = Color3.fromRGB(255, 255, 255)
				Item.TextSize = 13
				Item.TextTransparency = 0.5
				Item.TextXAlignment = Enum.TextXAlignment.Left
				Item.ZIndex = 4
				CreateRounded(Item, 5)
				local ItemPadding = Instance.new("UIPadding")
				ItemPadding.Parent = Item
				ItemPadding.PaddingLeft = UDim.new(0, 8)
				local SelectedItemsMark = Instance.new("Frame")
				SelectedItemsMark.Name = "SelectedItems"
				SelectedItemsMark.Parent = Item
				SelectedItemsMark.BackgroundColor3 = _G.Third
				SelectedItemsMark.BackgroundTransparency = 1
				SelectedItemsMark.Size = UDim2.new(0, 3, 0.4, 0)
				SelectedItemsMark.Position = UDim2.new(0, -8, 0.5, 0)
				SelectedItemsMark.AnchorPoint = Vector2.new(0, 0.5)
				SelectedItemsMark.ZIndex = 4
				CreateRounded(SelectedItemsMark, 999)
				Item.MouseButton1Click:Connect(function()
					activeItem = Item.Text
					SelectItems.Text = "   " .. Item.Text
					UpdateDropVisuals()
					pcall(callback, Item.Text)
				end)
				DropScroll.CanvasSize = UDim2.new(0, 0, 0, DropListLayout.AbsoluteContentSize.Y)
			end
			for _, v in next, option do
				AddItem(v)
			end
			if var then
				SelectItems.Text = "   " .. tostring(var)
				UpdateDropVisuals()
			end
			SelectItems.MouseButton1Click:Connect(function()
				isdropping = not isdropping
				if isdropping then
					DropdownFrameScroll.Visible = true
					TweenService:Create(DropdownFrameScroll, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
						Size = UDim2.new(1, -10, 0, 100)
					}):Play()
					TweenService:Create(Dropdown, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
						Size = UDim2.new(1, 0, 0, 145)
					}):Play()
					TweenService:Create(ArrowDown, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
						Rotation = 180
					}):Play()
				else
					local tween = TweenService:Create(DropdownFrameScroll, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
						Size = UDim2.new(1, -10, 0, 0)
					})
					tween:Play()
					tween.Completed:Connect(function()
						DropdownFrameScroll.Visible = false
					end)
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
				AddItem(t)
			end
			function dropfunc:Clear()
				SelectItems.Text = "   Vui lòng chọn"
				isdropping = false
				DropdownFrameScroll.Size = UDim2.new(1, -10, 0, 0)
				DropdownFrameScroll.Visible = false
				Dropdown.Size = UDim2.new(1, 0, 0, 40)
				ArrowDown.Rotation = 0
				for _, v in next, DropScroll:GetChildren() do
					if v:IsA("TextButton") then
						v:Destroy()
					end
				end
			end
			return dropfunc
		end
		function main:Slider(text, min, max, set, callback)
			local localValue = set or min
			local Slider = Instance.new("Frame")
			Slider.Name = "Slider"
			Slider.Parent = MainFramePage
			Slider.BackgroundColor3 = _G.Primary
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
			Title.BackgroundColor3 = Color3.fromRGB(150, 150, 150)
			Title.BackgroundTransparency = 1
			Title.Position = UDim2.new(0, 15, 0.5, 0)
			Title.Size = UDim2.new(0.5, 0, 0.8, 0)
			Title.Font = Enum.Font.Cartoon
			Title.Text = text
			Title.AnchorPoint = Vector2.new(0, 0.5)
			Title.TextColor3 = Color3.fromRGB(255, 255, 255)
			Title.TextXAlignment = Enum.TextXAlignment.Left
			scaleText(Title, 15)
			local bar = Instance.new("Frame")
			bar.Name = "bar"
			bar.Parent = sliderr
			bar.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
			bar.Size = UDim2.new(0, 100, 0, 4)
			bar.Position = UDim2.new(1, -10, 0.5, 0)
			bar.BackgroundTransparency = 0.8
			bar.AnchorPoint = Vector2.new(1, 0.5)
			CreateRounded(bar, 5)
			local bar1 = Instance.new("Frame")
			bar1.Name = "bar1"
			bar1.Parent = bar
			bar1.BackgroundColor3 = _G.Third
			bar1.Size = UDim2.new(math.clamp((localValue - min) / (max - min), 0, 1), 0, 1, 0)
			CreateRounded(bar1, 5)
			local ValueText = Instance.new("TextBox")
			ValueText.Parent = bar
			ValueText.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
			ValueText.BackgroundTransparency = 0.5
			ValueText.Position = UDim2.new(0, -45, 0.5, 0)
			ValueText.Size = UDim2.new(0, 35, 0, 20)
			ValueText.Font = Enum.Font.GothamMedium
			ValueText.Text = tostring(localValue)
			ValueText.AnchorPoint = Vector2.new(0, 0.5)
			ValueText.TextColor3 = Color3.fromRGB(255, 255, 255)
			ValueText.ClearTextOnFocus = false
			ValueText.TextXAlignment = Enum.TextXAlignment.Center
			scaleText(ValueText, 12)
			CreateRounded(ValueText, 3)
			local circlebar = Instance.new("Frame")
			circlebar.Name = "circlebar"
			circlebar.Parent = bar1
			circlebar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			circlebar.Position = UDim2.new(1, 0, 0.5, 0)
			circlebar.AnchorPoint = Vector2.new(0.5, 0.5)
			circlebar.Size = UDim2.new(0, 12, 0, 12)
			CreateRounded(circlebar, 100)
			pcall(callback, localValue)
			local function UpdateSlider(input)
				local percentage = math.clamp((input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
				local rawValue = min + percentage * (max - min)
				localValue = math.floor(rawValue + 0.5)
				bar1.Size = UDim2.new(percentage, 0, 1, 0)
				ValueText.Text = tostring(localValue)
				pcall(callback, localValue)
			end
			local function UpdateSliderFromInput()
				local num = tonumber(ValueText.Text)
				if num then
					localValue = math.clamp(math.floor(num + 0.5), min, max)
					local percentage = (localValue - min) / (max - min)
					bar1.Size = UDim2.new(percentage, 0, 1, 0)
					ValueText.Text = tostring(localValue)
					pcall(callback, localValue)
				else
					ValueText.Text = tostring(localValue)
				end
			end
			ValueText.FocusLost:Connect(UpdateSliderFromInput)
			local Sliding = false
			circlebar.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					Sliding = true
				end
			end)
			bar.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					Sliding = true
					UpdateSlider(input)
				end
			end)
			UserInputService.InputEnded:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					Sliding = false
				end
			end)
			UserInputService.InputChanged:Connect(function(input)
				if Sliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
					UpdateSlider(input)
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
			TextboxLabel.BackgroundColor3 = _G.Primary
			TextboxLabel.BackgroundTransparency = 1
			TextboxLabel.Position = UDim2.new(0, 15, 0.5, 0)
			TextboxLabel.Text = text
			TextboxLabel.Size = UDim2.new(0.6, 0, 0.8, 0)
			TextboxLabel.Font = Enum.Font.Nunito
			TextboxLabel.AnchorPoint = Vector2.new(0, 0.5)
			TextboxLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
			TextboxLabel.TextXAlignment = Enum.TextXAlignment.Left
			scaleText(TextboxLabel, 15)
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
			scaleText(RealTextbox, 11)
			RealTextbox.ClipsDescendants = true
			CreateRounded(RealTextbox, 5)
			RealTextbox.FocusLost:Connect(function(enterPressed)
				pcall(callback, RealTextbox.Text)
				if disappear then
					RealTextbox.Text = ""
				end
			end)
		end
		function main:Label(text)
			local Frame = Instance.new("Frame")
			Frame.Name = "Frame"
			Frame.Parent = MainFramePage
			Frame.BackgroundColor3 = _G.Primary
			Frame.BackgroundTransparency = 1
			Frame.Size = UDim2.new(1, 0, 0, 30)
			local Label = Instance.new("TextLabel")
			Label.Name = "Label"
			Label.Parent = Frame
			Label.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			Label.BackgroundTransparency = 1
			Label.Size = UDim2.new(1, -35, 0.8, 0)
			Label.Font = Enum.Font.Nunito
			Label.Position = UDim2.new(0, 30, 0.5, 0)
			Label.AnchorPoint = Vector2.new(0, 0.5)
			Label.TextColor3 = Color3.fromRGB(225, 225, 225)
			Label.Text = text
			Label.TextXAlignment = Enum.TextXAlignment.Left
			scaleText(Label, 15)
			local ImageLabel = Instance.new("ImageLabel")
			ImageLabel.Name = "ImageLabel"
			ImageLabel.Parent = Frame
			ImageLabel.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
			ImageLabel.BackgroundTransparency = 1
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
			Seperator.BackgroundColor3 = _G.Primary
			Seperator.BackgroundTransparency = 1
			Seperator.Size = UDim2.new(1, 0, 0, 36)
			local Sep1 = Instance.new("TextLabel")
			Sep1.Name = "Sep1"
			Sep1.Parent = Seperator
			Sep1.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			Sep1.BackgroundTransparency = 1
			Sep1.AnchorPoint = Vector2.new(0, 0.5)
			Sep1.Position = UDim2.new(0, 0, 0.5, 0)
			Sep1.Size = UDim2.new(0, 20, 0, 36)
			Sep1.Font = Enum.Font.GothamBold
			Sep1.RichText = true
			Sep1.Text = "«<font color=\"rgb(255, 0, 0)\">«</font>"
			Sep1.TextColor3 = Color3.fromRGB(255, 255, 255)
			Sep1.TextSize = 14
			local Sep2 = Instance.new("TextLabel")
			Sep2.Name = "Sep2"
			Sep2.Parent = Seperator
			Sep2.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
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
			Sep3.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			Sep3.BackgroundTransparency = 1
			Sep3.AnchorPoint = Vector2.new(1, 0.5)
			Sep3.Position = UDim2.new(1, 0, 0.5, 0)
			Sep3.Size = UDim2.new(0, 20, 0, 36)
			Sep3.Font = Enum.Font.GothamBold
			Sep3.RichText = true
			Sep3.Text = "<font color=\"rgb(255, 0, 0)\">»</font>»"
			Sep3.TextColor3 = Color3.fromRGB(255, 255, 255)
			Sep3.TextSize = 14
		end
		function main:Line()
			local Linee = Instance.new("Frame")
			Linee.Name = "Linee"
			Linee.Parent = MainFramePage
			Linee.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			Linee.BackgroundTransparency = 1
			Linee.Position = UDim2.new(0, 0, 0.12, 0)
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
