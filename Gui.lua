local CG = game:GetService("CoreGui")
local UIS = game:GetService("UserInputService")
local TS = game:GetService("TweenService")

if CG:FindFirstChild("TCHub") then CG.TCHub:Destroy() end

local TCH = {}

-- Hàm tạo Object ngắn gọn
local function C(cls, props)
	local i = Instance.new(cls)
	for k, v in pairs(props or {}) do
		if type(k) == "number" then v.Parent = i else i[k] = v end
	end
	return i
end

-- Kéo thả mượt cho Mobile & PC
local function MakeDrag(dragObj, moveObj)
	local dragging, dragInput, startPos, startGuiPos
	dragObj.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			startPos = input.Position
			startGuiPos = moveObj.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then dragging = false end
			end)
		end
	end)
	dragObj.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)
	UIS.InputChanged:Connect(function(input)
		if input == dragInput and dragging then
			local delta = input.Position - startPos
			moveObj.Position = UDim2.new(startGuiPos.X.Scale, startGuiPos.X.Offset + delta.X, startGuiPos.Y.Scale, startGuiPos.Y.Offset + delta.Y)
		end
	end)
end

-- Khởi tạo UI Thông báo
local NotiUI = C("ScreenGui", {Name = "TCHub_Noti", Parent = CG})
local NotiCont = C("Frame", {BackgroundTransparency = 1, Size = UDim2.new(0, 300, 1, -40), Position = UDim2.new(1, -15, 0, 20), AnchorPoint = Vector2.new(1, 0), Parent = NotiUI,
	C("UIListLayout", {Padding = UDim.new(0, 10), VerticalAlignment = Enum.VerticalAlignment.Bottom, HorizontalAlignment = Enum.HorizontalAlignment.Right})
})

function TCH:Notify(title, desc, duration)
	local f = C("Frame", {BackgroundColor3 = Color3.fromRGB(20, 20, 20), Size = UDim2.new(1, 0, 0, 60), Parent = NotiCont,
		C("UICorner", {CornerRadius = UDim.new(0, 4)}),
		C("UIStroke", {Color = self.ThemeCol, Thickness = 1}),
		C("TextLabel", {BackgroundTransparency = 1, Position = UDim2.new(0, 10, 0, 5), Size = UDim2.new(1, -20, 0, 20), Text = title, TextColor3 = self.ThemeCol, Font = Enum.Font.GothamBold, TextSize = 16, TextXAlignment = Enum.TextXAlignment.Left}),
		C("TextLabel", {BackgroundTransparency = 1, Position = UDim2.new(0, 10, 0, 25), Size = UDim2.new(1, -20, 0, 30), Text = desc, TextColor3 = Color3.fromRGB(200, 200, 200), Font = Enum.Font.Gotham, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true})
	})
	task.delay(duration or 3, function() f:Destroy() end)
end

function TCH:Window(cfg)
	local wnd = {
		Title = cfg.Title or "Tea Cat Hub",
		ThemeCol = cfg.Color or Color3.fromRGB(0, 255, 128),
		Tabs = {},
		CurrentTab = nil
	}
	self.ThemeCol = wnd.ThemeCol

	local gui = C("ScreenGui", {Name = "TCHub", Parent = CG, ResetOnSpawn = false})
	
	local floatBtn = C("ImageButton", {BackgroundColor3 = Color3.fromRGB(15, 15, 15), Size = UDim2.new(0, 45, 0, 45), Position = UDim2.new(0, 10, 0, 10), Parent = gui, AutoButtonColor = false,
		C("UICorner", {CornerRadius = UDim.new(1, 0)}),
		C("UIStroke", {Color = wnd.ThemeCol, Thickness = 2}),
		C("ImageLabel", {BackgroundTransparency = 1, Size = UDim2.new(0, 25, 0, 25), Position = UDim2.new(0.5, 0, 0.5, 0), AnchorPoint = Vector2.new(0.5, 0.5), Image = "rbxassetid://13940080072"})
	})
	
	local main = C("Frame", {BackgroundColor3 = Color3.fromRGB(18, 18, 18), Size = UDim2.new(0, 500, 0, 350), Position = UDim2.new(0.5, 0, 0.5, 0), AnchorPoint = Vector2.new(0.5, 0.5), Parent = gui, ClipsDescendants = true,
		C("UICorner", {CornerRadius = UDim.new(0, 4)}),
		C("UIStroke", {Color = wnd.ThemeCol, Thickness = 1})
	})

	MakeDrag(floatBtn, floatBtn)
	floatBtn.MouseButton1Click:Connect(function() main.Visible = not main.Visible end)

	local top = C("Frame", {BackgroundColor3 = Color3.fromRGB(12, 12, 12), Size = UDim2.new(1, 0, 0, 35), Parent = main,
		C("TextLabel", {BackgroundTransparency = 1, Size = UDim2.new(1, -10, 1, 0), Position = UDim2.new(0, 10, 0, 0), Text = wnd.Title, TextColor3 = wnd.ThemeCol, Font = Enum.Font.GothamBold, TextSize = 16, TextXAlignment = Enum.TextXAlignment.Left}),
		C("Frame", {BackgroundColor3 = wnd.ThemeCol, Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 1, 0), BorderSizePixel = 0})
	})
	MakeDrag(top, main)

	local tabCont = C("ScrollingFrame", {BackgroundTransparency = 1, Size = UDim2.new(0, 120, 1, -36), Position = UDim2.new(0, 0, 0, 36), CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 0, Parent = main,
		C("UIListLayout", {Padding = UDim.new(0, 2)}),
		C("UIPadding", {PaddingTop = UDim.new(0, 5), PaddingLeft = UDim.new(0, 5), PaddingRight = UDim.new(0, 5)})
	})

	local pageCont = C("Frame", {BackgroundColor3 = Color3.fromRGB(22, 22, 22), Size = UDim2.new(1, -120, 1, -36), Position = UDim2.new(0, 120, 0, 36), Parent = main})

	function wnd:Tab(name)
		local tab = {Elements = {}}
		
		local tBtn = C("TextButton", {BackgroundColor3 = Color3.fromRGB(25, 25, 25), Size = UDim2.new(1, 0, 0, 30), Text = name, TextColor3 = Color3.fromRGB(200, 200, 200), Font = Enum.Font.Gotham, TextSize = 14, AutoButtonColor = false, Parent = tabCont,
			C("UICorner", {CornerRadius = UDim.new(0, 4)})
		})
		
		local page = C("ScrollingFrame", {BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 2, ScrollBarImageColor3 = wnd.ThemeCol, Visible = false, Parent = pageCont,
			C("UIListLayout", {Padding = UDim.new(0, 6), HorizontalAlignment = Enum.HorizontalAlignment.Center}),
			C("UIPadding", {PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8)})
		})

		-- Định nghĩa hàm chuyển tab
		local function selectTab()
			if wnd.CurrentTab then
				wnd.CurrentTab.Btn.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
				wnd.CurrentTab.Btn.TextColor3 = Color3.fromRGB(200, 200, 200)
				wnd.CurrentTab.Page.Visible = false
			end
			wnd.CurrentTab = {Btn = tBtn, Page = page}
			tBtn.BackgroundColor3 = wnd.ThemeCol
			tBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
			page.Visible = true
		end

		tBtn.MouseButton1Click:Connect(selectTab)
		
		-- Gọi hàm trực tiếp thay vì .Fire()
		if not wnd.CurrentTab then selectTab() end

		-- ... (Rest of the tab elements remain the same)
function tab:Label(txt)
    local sec = C("Frame", {
        BackgroundTransparency = 1, 
        Size = UDim2.new(1, -16, 0, 30), 
        Parent = page
    })

    C("TextLabel", {
        BackgroundTransparency = 1, 
        Size = UDim2.new(1, 0, 1, -5),
        Text = string.upper(txt), 
        TextColor3 = wnd.ThemeCol, 
        Font = Enum.Font.GothamBold, 
        TextSize = 12, 
        TextXAlignment = Enum.TextXAlignment.Left, 
        Parent = sec
    })

    C("Frame", {
        BackgroundColor3 = wnd.ThemeCol, 
        Size = UDim2.new(1, 0, 0, 1), 
        Position = UDim2.new(0, 0, 1, -5), 
        BorderSizePixel = 0, 
        Parent = sec
    })
		end
		function tab:Button(txt, cb)
			local btn = C("TextButton", {BackgroundColor3 = Color3.fromRGB(30, 30, 30), Size = UDim2.new(1, -16, 0, 35), Text = txt, TextColor3 = Color3.fromRGB(220, 220, 220), Font = Enum.Font.Gotham, TextSize = 14, AutoButtonColor = false, Parent = page,
				C("UICorner", {CornerRadius = UDim.new(0, 4)}),
				C("UIStroke", {Color = Color3.fromRGB(50, 50, 50), Thickness = 1})
			})
			btn.MouseButton1Click:Connect(function() pcall(cb) end)
		end

		function tab:Toggle(txt, default, cb)
			local state = default or false
			local tgl = C("TextButton", {BackgroundColor3 = Color3.fromRGB(30, 30, 30), Size = UDim2.new(1, -16, 0, 35), Text = "", AutoButtonColor = false, Parent = page,
				C("UICorner", {CornerRadius = UDim.new(0, 4)}),
				C("UIStroke", {Color = Color3.fromRGB(50, 50, 50), Thickness = 1}),
				C("TextLabel", {BackgroundTransparency = 1, Size = UDim2.new(1, -50, 1, 0), Position = UDim2.new(0, 10, 0, 0), Text = txt, TextColor3 = Color3.fromRGB(220, 220, 220), Font = Enum.Font.Gotham, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left}),
			})
			local check = C("Frame", {BackgroundColor3 = state and wnd.ThemeCol or Color3.fromRGB(50, 50, 50), Size = UDim2.new(0, 20, 0, 20), Position = UDim2.new(1, -30, 0.5, -10), Parent = tgl,
				C("UICorner", {CornerRadius = UDim.new(0, 4)})
			})

			local function trigger()
				state = not state
				check.BackgroundColor3 = state and wnd.ThemeCol or Color3.fromRGB(50, 50, 50)
				pcall(cb, state)
			end
			tgl.MouseButton1Click:Connect(trigger)
			if default then pcall(cb, state) end
		end

		return tab
	end
	return wnd
end

return TCH
