local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local Library = {}
Library.Version = "Library-1.0"

local activeWindow
local GUI_NAMES = { "MateCatLibraryGui", "MateCatLibraryNotifications" }

local function clamp(value, minimum, maximum)
	value = tonumber(value) or minimum
	return math.max(minimum, math.min(maximum, value))
end

local function safeCallback(callback, ...)
	if type(callback) ~= "function" then
		return
	end
	local ok, err = pcall(callback, ...)
	if not ok then
		warn("[Mate Cat Library] callback error: " .. tostring(err))
		pcall(function() 
			window:Notify("[Mate Cat Library] callback error", tostring(err), 3.69) 
		end)
	end
end

local function newMaid()
	local maid = { tasks = {}, destroyed = false }

	function maid:Add(resource)
		if resource == nil then
			return resource
		end
		if self.destroyed then
			self:_cleanupOne(resource)
		else
			table.insert(self.tasks, resource)
		end
		return resource
	end

	function maid:Remove(resource)
		for i = #self.tasks, 1, -1 do
			if self.tasks[i] == resource then
				table.remove(self.tasks, i)
				return true
			end
		end
		return false
	end

	function maid:_cleanupOne(resource)
		if type(resource) == "function" then
			pcall(resource)
		elseif type(resource) == "thread" then
			pcall(task.cancel, resource)
		elseif typeof(resource) == "RBXScriptConnection" then
			pcall(function() resource:Disconnect() end)
		elseif typeof(resource) == "Instance" then
			pcall(function() resource:Destroy() end)
		elseif type(resource) == "table" then
			if type(resource.Cleanup) == "function" then
				pcall(function() resource:Cleanup() end)
			elseif type(resource.Disconnect) == "function" then
				pcall(function() resource:Disconnect() end)
			elseif type(resource.Destroy) == "function" then
				pcall(function() resource:Destroy() end)
			end
		end
	end

	function maid:Cleanup()
		if self.destroyed then
			return
		end
		self.destroyed = true
		for i = #self.tasks, 1, -1 do
			self:_cleanupOne(self.tasks[i])
			self.tasks[i] = nil
		end
	end

	return maid
end

local function create(className, properties, children)
	local instance = Instance.new(className)
	for property, value in pairs(properties or {}) do
		instance[property] = value
	end
	for _, child in ipairs(children or {}) do
		child.Parent = instance
	end
	return instance
end

local function makeDraggable(maid, dragObject, moveObject)
	local dragging = false
	local dragInput
	local startInputPosition
	local startGuiPosition

	maid:Add(dragObject.InputBegan:Connect(function(input)
		local kind = input.UserInputType
		if kind ~= Enum.UserInputType.MouseButton1 and kind ~= Enum.UserInputType.Touch then
			return
		end
		dragging = true
		dragInput = input
		startInputPosition = input.Position
		startGuiPosition = moveObject.Position
	end))

	maid:Add(dragObject.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end))

	maid:Add(UserInputService.InputChanged:Connect(function(input)
		if not dragging then
			return
		end
		local isMouseMove = input.UserInputType == Enum.UserInputType.MouseMovement
		local isMatchingTouch = input.UserInputType == Enum.UserInputType.Touch and input == dragInput
		if not isMouseMove and not isMatchingTouch then
			return
		end
		local delta = input.Position - startInputPosition
		moveObject.Position = UDim2.new(
			startGuiPosition.X.Scale,
			startGuiPosition.X.Offset + delta.X,
			startGuiPosition.Y.Scale,
			startGuiPosition.Y.Offset + delta.Y
		)
	end))

	maid:Add(UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or (input.UserInputType == Enum.UserInputType.Touch and input == dragInput) then
			dragging = false
			dragInput = nil
		end
	end))
end

local function bindCanvasSize(maid, frame, layout, padding)
	local function update()
		if frame.Parent then
			local size = layout.AbsoluteContentSize
			frame.CanvasSize = UDim2.new(0, size.X, 0, size.Y + (padding or 0))
		end
	end
	maid:Add(layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(update))
	update()
	return update
end

local function makeCorner(radius)
	return create("UICorner", { CornerRadius = UDim.new(0, radius or 5) })
end

local function makeStroke(color, thickness)
	return create("UIStroke", { Color = color, Thickness = thickness or 1 })
end

local function getGuiContainer()
	-- Thử lấy CoreGui; nếu không có quyền ghi thì fallback PlayerGui.
	local ok, coreGui = pcall(function()
		return game:GetService("CoreGui")
	end)
	if ok and coreGui then
		local test = Instance.new("Folder")
		local parentOk = pcall(function()
			test.Parent = coreGui
		end)
		test:Destroy()
		if parentOk then
			return coreGui
		end
	end

	local player = Players.LocalPlayer
	if not player then
		error("Mate Cat Library must be required from a client (no LocalPlayer available)")
	end
	return player:WaitForChild("PlayerGui")
end

local function cleanupOldGuisIn(container)
	for _, name in ipairs(GUI_NAMES) do
		local old = container:FindFirstChild(name)
		if old then
			old:Destroy()
		end
	end
end

local function cleanupOldGuis()
	local coreOk, coreGui = pcall(function()
		return game:GetService("CoreGui")
	end)
	if coreOk and coreGui then
		pcall(cleanupOldGuisIn, coreGui)
	end

	local player = Players.LocalPlayer
	if player then
		local playerGui = player:FindFirstChild("PlayerGui")
		if playerGui then
			pcall(cleanupOldGuisIn, playerGui)
		end
	end
end

local function createWindow(config)
	config = type(config) == "table" and config or {}
	local container = getGuiContainer()
	cleanupOldGuis()

	local theme = typeof(config.Color) == "Color3" and config.Color or Color3.fromRGB(0, 220, 130)
	local maid = newMaid()

	local window = {
		Title = tostring(config.Title or "Mate Cat Library"),
		ThemeCol = theme,
		CurrentTab = nil,
		maid = maid,
		destroyed = false,
	}

	-- ---------- Main ScreenGui ----------
	local screen = create("ScreenGui", {
		Name = "MateCatLibraryGui",
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = 20,
	})
	screen.Parent = container
	window.gui = screen
	maid:Add(screen)

	local main = create("Frame", {
		Name = "Main",
		BackgroundColor3 = Color3.fromRGB(18, 18, 18),
		Size = UDim2.fromOffset(500, 350),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		ClipsDescendants = true,
	}, { makeCorner(6), makeStroke(theme, 1) })
	main.Parent = screen

	local top = create("Frame", {
		Name = "TopBar",
		BackgroundColor3 = Color3.fromRGB(12, 12, 12),
		Size = UDim2.new(1, 0, 0, 36),
	}, {
		create("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(12, 0),
			Size = UDim2.new(1, -24, 1, 0),
			Text = window.Title,
			TextColor3 = theme,
			Font = Enum.Font.GothamBold,
			TextSize = 16,
			TextXAlignment = Enum.TextXAlignment.Left,
		}),
		create("Frame", {
			BackgroundColor3 = theme,
			BorderSizePixel = 0,
			Position = UDim2.new(0, 0, 1, -1),
			Size = UDim2.new(1, 0, 0, 1),
		}),
	})
	top.Parent = main
	makeDraggable(maid, top, main)

	local floatButton = create("TextButton", {
		Name = "OpenButton",
		BackgroundColor3 = Color3.fromRGB(15, 15, 15),
		Position = UDim2.fromOffset(12, 12),
		Size = UDim2.fromOffset(46, 46),
		Text = "M",
		TextColor3 = theme,
		Font = Enum.Font.GothamBold,
		TextSize = 20,
		AutoButtonColor = false,
	}, { create("UICorner", { CornerRadius = UDim.new(1, 0) }), makeStroke(theme, 2) })
	floatButton.Parent = screen
	maid:Add(floatButton)
	makeDraggable(maid, floatButton, floatButton)
	maid:Add(floatButton.Activated:Connect(function()
		if not window.destroyed then
			main.Visible = not main.Visible
		end
	end))

	-- ---------- Tabs ----------
	local tabLayout = create("UIListLayout", {
		Padding = UDim.new(0, 3),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})
	local tabContainer = create("ScrollingFrame", {
		Name = "Tabs",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(0, 37),
		Size = UDim2.new(0, 125, 1, -37),
		CanvasSize = UDim2.new(),
		ScrollBarThickness = 2,
		ScrollBarImageColor3 = theme,
		BorderSizePixel = 0,
	}, { tabLayout, create("UIPadding", {
		PaddingTop = UDim.new(0, 7),
		PaddingLeft = UDim.new(0, 6),
		PaddingRight = UDim.new(0, 6),
	}) })
	tabContainer.Parent = main
	bindCanvasSize(maid, tabContainer, tabLayout, 8)

	local pageContainer = create("Frame", {
		Name = "Pages",
		BackgroundColor3 = Color3.fromRGB(22, 22, 22),
		Position = UDim2.new(0, 125, 0, 37),
		Size = UDim2.new(1, -125, 1, -37),
		BorderSizePixel = 0,
	})
	pageContainer.Parent = main

	-- ---------- Notification GUI ----------
	local notificationGui = create("ScreenGui", {
		Name = "MateCatLibraryNotifications",
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = 21,
	})
	notificationGui.Parent = container
	maid:Add(notificationGui)

	local notificationContainer = create("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.new(1, -16, 0, 18),
		AnchorPoint = Vector2.new(1, 0),
		Size = UDim2.new(0, 300, 1, -36),
	}, { create("UIListLayout", {
		Padding = UDim.new(0, 8),
		VerticalAlignment = Enum.VerticalAlignment.Bottom,
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
	}) })
	notificationContainer.Parent = notificationGui

	function window:Notify(title, description, duration)
		if self.destroyed then
			return
		end
		local cards = {}
		for _, child in ipairs(notificationContainer:GetChildren()) do
			if child:IsA("Frame") then
				table.insert(cards, child)
			end
		end
		while #cards >= 8 do
			cards[1]:Destroy()
			table.remove(cards, 1)
		end

		local card = create("Frame", {
			BackgroundColor3 = Color3.fromRGB(20, 20, 20),
			Size = UDim2.new(1, 0, 0, 62),
		}, {
			makeCorner(5), makeStroke(theme, 1),
			create("TextLabel", {
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(10, 5),
				Size = UDim2.new(1, -20, 0, 22),
				Text = tostring(title or "Thông báo"),
				TextColor3 = theme,
				Font = Enum.Font.GothamBold,
				TextSize = 15,
				TextXAlignment = Enum.TextXAlignment.Left,
			}),
			create("TextLabel", {
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(10, 28),
				Size = UDim2.new(1, -20, 0, 28),
				Text = tostring(description or ""),
				TextColor3 = Color3.fromRGB(205, 205, 205),
				Font = Enum.Font.Gotham,
				TextSize = 12,
				TextWrapped = true,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Top,
			}),
		})
		card.Parent = notificationContainer
		maid:Add(card)

		local thread
		thread = task.delay(math.max(0, tonumber(duration) or 3), function()
			if card.Parent then
				card:Destroy()
			end
			maid:Remove(card)
			if thread then
				maid:Remove(thread)
			end
		end)
		maid:Add(thread)
	end

	-- ---------- Tab API ----------
	function window:Tab(name)
		if self.destroyed then
			return nil
		end

		local tabMaid = newMaid()
		maid:Add(tabMaid)
		local tab = {}

		local tabButton = create("TextButton", {
			BackgroundColor3 = Color3.fromRGB(27, 27, 27),
			Size = UDim2.new(1, 0, 0, 31),
			Text = tostring(name or "Tab"),
			TextColor3 = Color3.fromRGB(210, 210, 210),
			Font = Enum.Font.Gotham,
			TextSize = 13,
			AutoButtonColor = false,
		}, { makeCorner(5) })
		tabButton.Parent = tabContainer

		local pageLayout = create("UIListLayout", {
			Padding = UDim.new(0, 7),
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
		})
		local page = create("ScrollingFrame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 1, 0),
			CanvasSize = UDim2.new(),
			ScrollBarThickness = 3,
			ScrollBarImageColor3 = theme,
			BorderSizePixel = 0,
			Visible = false,
		}, { pageLayout, create("UIPadding", {
			PaddingTop = UDim.new(0, 8),
			PaddingBottom = UDim.new(0, 8),
		}) })
		page.Parent = pageContainer
		local refreshPage = bindCanvasSize(tabMaid, page, pageLayout, 16)
		tabMaid:Add(tabButton)
		tabMaid:Add(page)

		local function selectTab()
			if window.destroyed then
				return
			end
			if window.CurrentTab then
				window.CurrentTab.Button.BackgroundColor3 = Color3.fromRGB(27, 27, 27)
				window.CurrentTab.Button.TextColor3 = Color3.fromRGB(210, 210, 210)
				window.CurrentTab.Page.Visible = false
			end
			window.CurrentTab = { Button = tabButton, Page = page }
			tabButton.BackgroundColor3 = theme
			tabButton.TextColor3 = Color3.fromRGB(10, 10, 10)
			page.Visible = true
			refreshPage()
		end
		tabMaid:Add(tabButton.Activated:Connect(selectTab))
		if not self.CurrentTab then
			selectTab()
		end

		-- ---------- Label ----------
		function tab:Label(text)
			local section = create("Frame", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, -16, 0, 30),
			})
			local label = create("TextLabel", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 1, -5),
				Text = string.upper(tostring(text or "")),
				TextColor3 = theme,
				Font = Enum.Font.GothamBold,
				TextSize = 13,
				TextXAlignment = Enum.TextXAlignment.Left,
			})
			label.Parent = section
			local line = create("Frame", {
				BackgroundColor3 = theme,
				BorderSizePixel = 0,
				Position = UDim2.new(0, 0, 1, -2),
				Size = UDim2.new(1, 0, 0, 1),
			})
			line.Parent = section
			section.Parent = page
			tabMaid:Add(section)
			return { Set = function(_, value)
				if label.Parent then
					label.Text = string.upper(tostring(value or ""))
				end
			end }
		end

		-- ---------- Button ----------
		function tab:Button(text, callback)
			local button = create("TextButton", {
				BackgroundColor3 = Color3.fromRGB(30, 30, 30),
				Size = UDim2.new(1, -16, 0, 36),
				Text = tostring(text or "Button"),
				TextColor3 = Color3.fromRGB(225, 225, 225),
				Font = Enum.Font.Gotham,
				TextSize = 14,
				AutoButtonColor = false,
			}, { makeCorner(5), makeStroke(Color3.fromRGB(52, 52, 52), 1) })
			button.Parent = page
			tabMaid:Add(button)
			tabMaid:Add(button.Activated:Connect(function()
				if window.destroyed then
					return
				end
				button.BackgroundColor3 = theme
				TweenService:Create(button, TweenInfo.new(0.15), {
					BackgroundColor3 = Color3.fromRGB(30, 30, 30),
				}):Play()
				safeCallback(callback)
			end))
			return button
		end

		-- ---------- Toggle ----------
		function tab:Toggle(text, default, callback)
			local state = default == true
			local controlMaid = newMaid()
			tabMaid:Add(controlMaid)

			local button = create("TextButton", {
				BackgroundColor3 = Color3.fromRGB(30, 30, 30),
				Size = UDim2.new(1, -16, 0, 36),
				Text = "",
				AutoButtonColor = false,
			}, { makeCorner(5), makeStroke(Color3.fromRGB(52, 52, 52), 1) })
			button.Parent = page
			create("TextLabel", {
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(10, 0),
				Size = UDim2.new(1, -52, 1, 0),
				Text = tostring(text or "Toggle"),
				TextColor3 = Color3.fromRGB(225, 225, 225),
				Font = Enum.Font.Gotham,
				TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Left,
			}).Parent = button
			local indicator = create("Frame", {
				BackgroundColor3 = state and theme or Color3.fromRGB(50, 50, 50),
				Position = UDim2.new(1, -31, 0.5, -10),
				Size = UDim2.fromOffset(20, 20),
			}, { makeCorner(4) })
			indicator.Parent = button
			controlMaid:Add(button)

			local destroyed = false
			local function setState(value, emit)
				if destroyed then
					return
				end
				local nextState = value == true
				local changed = nextState ~= state
				state = nextState
				indicator.BackgroundColor3 = state and theme or Color3.fromRGB(50, 50, 50)
				if changed and emit then
					safeCallback(callback, state)
				end
			end
			controlMaid:Add(button.Activated:Connect(function()
				setState(not state, true)
			end))

			return {
				Set = function(_, value) setState(value, true) end,
				Get = function() if destroyed then return nil end return state end,
				Destroy = function()
					if destroyed then return end
					destroyed = true
					controlMaid:Cleanup()
				end,
			}
		end

		-- ---------- Dropdown ----------
		function tab:Dropdown(text, options, default, callback)
			options = type(options) == "table" and options or {}
			local selected = default
			local foundDefault = false
			for _, item in ipairs(options) do
				if item == selected then
					foundDefault = true
					break
				end
			end
			if not foundDefault then
				selected = options[1] or "Chưa chọn"
			end

			local expanded = false
			local destroyed = false
			local controlMaid = newMaid()
			tabMaid:Add(controlMaid)

			local root = create("Frame", {
				BackgroundColor3 = Color3.fromRGB(30, 30, 30),
				Size = UDim2.new(1, -16, 0, 36),
				ClipsDescendants = true,
			}, { makeCorner(5), makeStroke(Color3.fromRGB(52, 52, 52), 1) })
			root.Parent = page

			local header = create("TextButton", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 35),
				Text = "",
				AutoButtonColor = false,
			})
			header.Parent = root
			create("TextLabel", {
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(10, 0),
				Size = UDim2.new(0.5, -10, 1, 0),
				Text = tostring(text or "Dropdown"),
				TextColor3 = Color3.fromRGB(225, 225, 225),
				Font = Enum.Font.Gotham,
				TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Left,
			}).Parent = header
			local valueLabel = create("TextLabel", {
				BackgroundTransparency = 1,
				Position = UDim2.new(0.5, 0, 0, 0),
				Size = UDim2.new(0.5, -12, 1, 0),
				Text = tostring(selected),
				TextColor3 = theme,
				Font = Enum.Font.GothamBold,
				TextSize = 13,
				TextXAlignment = Enum.TextXAlignment.Right,
				TextTruncate = Enum.TextTruncate.AtEnd,
			})
			valueLabel.Parent = header

			local listLayout = create("UIListLayout", {
				Padding = UDim.new(0, 2),
				SortOrder = Enum.SortOrder.LayoutOrder,
			})
			local list = create("ScrollingFrame", {
				BackgroundColor3 = Color3.fromRGB(20, 20, 20),
				Position = UDim2.new(0, 5, 0, 40),
				Size = UDim2.new(1, -10, 0, 100),
				CanvasSize = UDim2.new(),
				ScrollBarThickness = 2,
				ScrollBarImageColor3 = theme,
				BorderSizePixel = 0,
			}, { listLayout, makeCorner(4) })
			list.Parent = root
			bindCanvasSize(controlMaid, list, listLayout, 2)

			local itemButtons = {}
			local function render()
				for item, button in pairs(itemButtons) do
					local isSelected = item == selected
					button.BackgroundColor3 = isSelected and theme or Color3.fromRGB(25, 25, 25)
					button.TextColor3 = isSelected and Color3.fromRGB(10, 10, 10) or Color3.fromRGB(210, 210, 210)
				end
			end

			local function choose(item)
				if destroyed then
					return
				end
				selected = item
				valueLabel.Text = tostring(item)
				expanded = false
				root.Size = UDim2.new(1, -16, 0, 36)
				render()
				safeCallback(callback, selected)
			end

			for index, option in ipairs(options) do
				local itemButton = create("TextButton", {
					BackgroundColor3 = Color3.fromRGB(25, 25, 25),
					Size = UDim2.new(1, 0, 0, 26),
					Text = tostring(option),
					TextColor3 = Color3.fromRGB(210, 210, 210),
					Font = Enum.Font.Gotham,
					TextSize = 13,
					AutoButtonColor = false,
					LayoutOrder = index,
				}, { makeCorner(3) })
				itemButton.Parent = list
				itemButtons[option] = itemButton
				controlMaid:Add(itemButton)
				controlMaid:Add(itemButton.Activated:Connect(function()
					choose(option)
				end))
			end

			controlMaid:Add(root)
			controlMaid:Add(header.Activated:Connect(function()
				if destroyed then
					return
				end
				expanded = not expanded
				root.Size = UDim2.new(1, -16, 0, expanded and 145 or 36)
			end))
			render()

			local function contains(value)
				for _, option in ipairs(options) do
					if option == value then
						return true
					end
				end
				return false
			end

			return {
				Set = function(_, value)
					if not destroyed and contains(value) then
						choose(value)
					end
				end,
				Get = function()
					if destroyed then return nil end
					return selected
				end,
				Destroy = function()
					if destroyed then return end
					destroyed = true
					controlMaid:Cleanup()
				end,
			}
		end

		-- ---------- Slider ----------
		function tab:Slider(text, minimum, maximum, default, callback)
			minimum = tonumber(minimum) or 0
			maximum = tonumber(maximum) or 100
			if maximum < minimum then
				minimum, maximum = maximum, minimum
			end
			if maximum == minimum then
				maximum = minimum + 1
			end

			local value = math.floor(clamp(default, minimum, maximum))
			local destroyed = false
			local sliding = false
			local lastCallback = 0
			local controlMaid = newMaid()
			tabMaid:Add(controlMaid)

			local root = create("Frame", {
				BackgroundColor3 = Color3.fromRGB(30, 30, 30),
				Size = UDim2.new(1, -16, 0, 52),
			}, { makeCorner(5), makeStroke(Color3.fromRGB(52, 52, 52), 1) })
			root.Parent = page
			create("TextLabel", {
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(10, 0),
				Size = UDim2.new(1, -60, 0, 26),
				Text = tostring(text or "Slider"),
				TextColor3 = Color3.fromRGB(225, 225, 225),
				Font = Enum.Font.Gotham,
				TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Left,
			}).Parent = root

			local valueBox = create("TextBox", {
				BackgroundColor3 = Color3.fromRGB(15, 15, 15),
				Position = UDim2.new(1, -50, 0, 3),
				Size = UDim2.fromOffset(40, 20),
				Text = tostring(value),
				TextColor3 = theme,
				Font = Enum.Font.GothamBold,
				TextSize = 13,
				ClearTextOnFocus = false,
			}, { makeCorner(4) })
			valueBox.Parent = root

			local track = create("TextButton", {
				BackgroundColor3 = Color3.fromRGB(15, 15, 15),
				Position = UDim2.new(0, 10, 0, 34),
				Size = UDim2.new(1, -20, 0, 8),
				Text = "",
				AutoButtonColor = false,
			}, { create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
			track.Parent = root
			local fill = create("Frame", {
				BackgroundColor3 = theme,
				Size = UDim2.new((value - minimum) / (maximum - minimum), 0, 1, 0),
			}, { create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
			fill.Parent = track
			controlMaid:Add(root)

			local function setValue(newValue, emit, force)
				if destroyed then
					return
				end
				local previous = value
				value = math.floor(clamp(newValue, minimum, maximum))
				fill.Size = UDim2.new((value - minimum) / (maximum - minimum), 0, 1, 0)
				valueBox.Text = tostring(value)
				local now = os.clock()
				if emit and value ~= previous and (force or now - lastCallback >= 0.1) then
					lastCallback = now
					safeCallback(callback, value)
				end
			end

			local function updateFromInput(input)
				if destroyed or track.AbsoluteSize.X <= 0 then
					return
				end
				local ratio = clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
				setValue(minimum + (maximum - minimum) * ratio, true, false)
			end

			controlMaid:Add(track.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1
					or input.UserInputType == Enum.UserInputType.Touch then
					sliding = true
					updateFromInput(input)
				end
			end))
			controlMaid:Add(UserInputService.InputChanged:Connect(function(input)
				if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement
					or input.UserInputType == Enum.UserInputType.Touch) then
					updateFromInput(input)
				end
			end))
			controlMaid:Add(UserInputService.InputEnded:Connect(function(input)
				if sliding and (input.UserInputType == Enum.UserInputType.MouseButton1
					or input.UserInputType == Enum.UserInputType.Touch) then
					sliding = false
					safeCallback(callback, value)
				end
			end))
			controlMaid:Add(valueBox.FocusLost:Connect(function()
				local number = tonumber(valueBox.Text)
				if number then
					setValue(number, true, true)
				else
					valueBox.Text = tostring(value)
				end
			end))

			return {
				Set = function(_, newValue) setValue(newValue, true, true) end,
				Get = function()
					if destroyed then return nil end
					return value
				end,
				Destroy = function()
					if destroyed then return end
					destroyed = true
					controlMaid:Cleanup()
				end,
			}
		end

		return tab
	end

	-- ---------- Window Destroy ----------
	function window:Destroy()
		if self.destroyed then
			return
		end
		self.destroyed = true
		self.maid:Cleanup()
		if activeWindow == self then
			activeWindow = nil
		end
	end

	activeWindow = window
	return window
end

function Library:Window(config)
	if activeWindow and not activeWindow.destroyed then
		activeWindow:Destroy()
	end
	return createWindow(config)
end

function Library:Notify(title, description, duration)
	if activeWindow and not activeWindow.destroyed then
		activeWindow:Notify(title, description, duration)
	end
end

return Library