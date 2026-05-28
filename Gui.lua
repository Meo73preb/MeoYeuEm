local CG = (game:GetService("CoreGui") or game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui"))
local UIS = game:GetService("UserInputService")
local TS = game:GetService("TweenService")
if CG:FindFirstChild("TeaCatHub") then
	CG.TeaCatHub:Destroy()
end
local TCH = {ThemeCol = Color3.fromRGB(0, 255, 128)}
local function C(cls, props)
	local i = Instance.new(cls)
	for k, v in pairs(props or {}) do
		if type(k) == "number" then
			v.Parent = i
		else
			i[k] = v
		end
	end
	return i
end
local function MakeDrag(dragObj, moveObj)
	local dragging, dragInput, startPos, startGuiPos
	dragObj.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			startPos = input.Position
			startGuiPos = moveObj.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
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
			TS:Create(moveObj, TweenInfo.new(0.08, Enum.EasingStyle.Out, Enum.EasingDirection.Quad), {
				Position = UDim2.new(startGuiPos.X.Scale, startGuiPos.X.Offset + delta.X, startGuiPos.Y.Scale, startGuiPos.Y.Offset + delta.Y)
			}):Play()
		end
	end)
end
local NotiUI = C("ScreenGui", {Name = "TCHub_Noti", Parent = CG})
local NotiCont = C("Frame", {BackgroundTransparency = 1, Size = UDim2.new(0, 300, 1, -40), Position = UDim2.new(1, -15, 0, 20), AnchorPoint = Vector2.new(1, 0), Parent = NotiUI,
	C("UIListLayout", {Padding = UDim.new(0, 10), VerticalAlignment = Enum.VerticalAlignment.Bottom, HorizontalAlignment = Enum.HorizontalAlignment.Right})
})
function TCH:StartLoad() end
function TCH:Loaded() end
function TCH:SaveSettings() return false end
function TCH:LoadAnimation() return false end
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
	local gui = C("ScreenGui", {Name = "TeaCatHub", Parent = CG, ResetOnSpawn = false})
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
		if not wnd.CurrentTab then
			selectTab()
		end
		function tab:Label(txt)
			local l = C("TextLabel", {BackgroundTransparency = 1, Size = UDim2.new(1, -16, 0, 20), Text = txt, TextColor3 = wnd.ThemeCol, Font = Enum.Font.GothamBold, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, Parent = page})
			return {
				Set = function(_, newTxt) l.Text = newTxt end,
				Update = function(_, newTxt) l.Text = newTxt end,
				Refresh = function(_, newTxt) l.Text = newTxt end
			}
		end
		function tab:Label1(txt)
			return self:Label(txt)
		end
		function tab:Dis(txt1, txt2)
			return self:Label(tostring(txt1) .. " " .. tostring(txt2 or ""))
		end
		function tab:Button(txt, cb)
			local btn = C("TextButton", {BackgroundColor3 = Color3.fromRGB(30, 30, 30), Size = UDim2.new(1, -16, 0, 35), Text = txt, TextColor3 = Color3.fromRGB(220, 220, 220), Font = Enum.Font.Gotham, TextSize = 14, AutoButtonColor = false, Parent = page,
				C("UICorner", {CornerRadius = UDim.new(0, 4)}),
				C("UIStroke", {Color = Color3.fromRGB(50, 50, 50), Thickness = 1})
			})
			btn.MouseButton1Click:Connect(function() pcall(cb) end)
			return btn
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
			local function set(v)
				state = v
				check.BackgroundColor3 = state and wnd.ThemeCol or Color3.fromRGB(50, 50, 50)
				pcall(cb, state)
			end
			tgl.MouseButton1Click:Connect(function()
				set(not state)
			end)
			if default then
				pcall(cb, state)
			end
			return {
				Set = function(_, v) set(v) end,
				SetState = function(_, v) set(v) end
			}
		end
		function tab:Slider(txt, min, max, default, cb)
			local val = default or min
			local sld = C("Frame", {BackgroundColor3 = Color3.fromRGB(30, 30, 30), Size = UDim2.new(1, -16, 0, 50), Parent = page,
				C("UICorner", {CornerRadius = UDim.new(0, 4)}),
				C("UIStroke", {Color = Color3.fromRGB(50, 50, 50), Thickness = 1}),
				C("TextLabel", {BackgroundTransparency = 1, Size = UDim2.new(1, -60, 0, 25), Position = UDim2.new(0, 10, 0, 0), Text = txt, TextColor3 = Color3.fromRGB(220, 220, 220), Font = Enum.Font.Gotham, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left})
			})
			local box = C("TextBox", {BackgroundColor3 = Color3.fromRGB(15, 15, 15), Size = UDim2.new(0, 40, 0, 20), Position = UDim2.new(1, -50, 0, 2), Text = tostring(val), TextColor3 = wnd.ThemeCol, Font = Enum.Font.GothamBold, TextSize = 13, Parent = sld,
				C("UICorner", {CornerRadius = UDim.new(0, 4)})
			})
			local track = C("Frame", {BackgroundColor3 = Color3.fromRGB(15, 15, 15), Size = UDim2.new(1, -20, 0, 8), Position = UDim2.new(0, 10, 0, 32), Parent = sld,
				C("UICorner", {CornerRadius = UDim.new(1, 0)})
			})
			local fill = C("Frame", {BackgroundColor3 = wnd.ThemeCol, Size = UDim2.new((val - min) / (max - min), 0, 1, 0), Parent = track,
				C("UICorner", {CornerRadius = UDim.new(1, 0)})
			})
			local function set(v)
				val = math.clamp(v, min, max)
				fill.Size = UDim2.new((val - min) / (max - min), 0, 1, 0)
				box.Text = tostring(val)
				pcall(cb, val)
			end
			local function update(input)
				local pct = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
				set(math.floor(min + (max - min) * pct))
			end
			local sliding = false
			track.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					sliding = true; update(input)
				end
			end)
			UIS.InputEnded:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					sliding = false
				end
			end)
			UIS.InputChanged:Connect(function(input)
				if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
					update(input)
				end
			end)
			box.FocusLost:Connect(function()
				local n = tonumber(box.Text)
				if n then
					set(n)
				else
					box.Text = tostring(val)
				end
			end)
			return {
				Set = function(_, v) set(v) end,
				SetValue = function(_, v) set(v) end
			}
		end
		function tab:Dropdown(txt, options, multi, cb)
			local selected = multi and {} or nil
			local open = false
			local getTxt = function()
				if not multi then
					return selected or "Chọn.."
				end
				local s = ""
				for k, _ in pairs(selected) do
					s = s .. k .. ", "
				end
				return s == "" and "Chọn.." or s:sub(1, -3)
			end
			local drp = C("Frame", {BackgroundColor3 = Color3.fromRGB(30, 30, 30), Size = UDim2.new(1, -16, 0, 35), Parent = page, ClipsDescendants = true,
				C("UICorner", {CornerRadius = UDim.new(0, 4)}),
				C("UIStroke", {Color = Color3.fromRGB(50, 50, 50), Thickness = 1})
			})
			local dBtn = C("TextButton", {BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 35), Text = "", Parent = drp,
				C("TextLabel", {BackgroundTransparency = 1, Size = UDim2.new(0.5, 0, 1, 0), Position = UDim2.new(0, 10, 0, 0), Text = txt, TextColor3 = Color3.fromRGB(220, 220, 220), Font = Enum.Font.Gotham, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left}),
				C("TextLabel", {Name = "Val", BackgroundTransparency = 1, Size = UDim2.new(0.5, -30, 1, 0), Position = UDim2.new(0.5, 0, 0, 0), Text = getTxt(), TextColor3 = wnd.ThemeCol, Font = Enum.Font.GothamBold, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Right, TextTruncate = Enum.TextTruncate.AtEnd})
			})
			local list = C("ScrollingFrame", {BackgroundColor3 = Color3.fromRGB(20, 20, 20), Size = UDim2.new(1, -10, 0, 100), Position = UDim2.new(0, 5, 0, 40), CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 2, Parent = drp,
				C("UIListLayout", {Padding = UDim.new(0, 2)}),
				C("UICorner", {CornerRadius = UDim.new(0, 4)})
			})
			local function render()
				for _, v in pairs(list:GetChildren()) do
					if v:IsA("TextButton") then
						v:Destroy()
					end
				end
				for _, opt in ipairs(options) do
					local isSel = multi and selected[opt] or selected == opt
					local iBtn = C("TextButton", {BackgroundColor3 = isSel and wnd.ThemeCol or Color3.fromRGB(25, 25, 25), Size = UDim2.new(1, 0, 0, 25), Text = opt, TextColor3 = isSel and Color3.fromRGB(0, 0, 0) or Color3.fromRGB(200, 200, 200), Font = Enum.Font.Gotham, TextSize = 13, AutoButtonColor = false, Parent = list,
						C("UICorner", {CornerRadius = UDim.new(0, 2)})
					})
					iBtn.MouseButton1Click:Connect(function()
						if multi then
							if selected[opt] then
								selected[opt] = nil
							else
								selected[opt] = true
							end
							render()
						else
							selected = opt
							open = false
							drp.Size = UDim2.new(1, -16, 0, 35)
							render()
						end
						dBtn.Val.Text = getTxt()
						pcall(cb, selected)
					end)
				end
			end
			local function selectOpt(opt)
				if multi then
					selected[opt] = true
				else
					selected = opt
				end
				dBtn.Val.Text = getTxt()
				render()
				pcall(cb, selected)
			end
			dBtn.MouseButton1Click:Connect(function()
				open = not open
				drp.Size = UDim2.new(1, -16, 0, open and 145 or 35)
			end)
			render()
			return {
				Refresh = function(_, newOpts) options = newOpts; selected = multi and {} or nil; dBtn.Val.Text = getTxt(); render() end,
				Select = function(_, opt) selectOpt(opt) end,
				Set = function(_, opt) selectOpt(opt) end
			}
		end
		function tab:Textbox(txt, disappear, cb)
			local box = C("Frame", {BackgroundColor3 = Color3.fromRGB(30, 30, 30), Size = UDim2.new(1, -16, 0, 35), Parent = page,
				C("UICorner", {CornerRadius = UDim.new(0, 4)}),
				C("UIStroke", {Color = Color3.fromRGB(50, 50, 50), Thickness = 1}),
				C("TextLabel", {BackgroundTransparency = 1, Size = UDim2.new(1, -100, 1, 0), Position = UDim2.new(0, 10, 0, 0), Text = txt, TextColor3 = Color3.fromRGB(220, 220, 220), Font = Enum.Font.Gotham, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left}),
			})
			local rBox = C("TextBox", {BackgroundColor3 = Color3.fromRGB(15, 15, 15), Size = UDim2.new(0, 80, 0, 24), Position = UDim2.new(1, -90, 0.5, -12), Text = "", TextColor3 = wnd.ThemeCol, Font = Enum.Font.Gotham, TextSize = 12, Parent = box,
				C("UICorner", {CornerRadius = UDim.new(0, 4)})
			})
			rBox.FocusLost:Connect(function()
				pcall(cb, rBox.Text)
				if disappear then
					rBox.Text = ""
				end
			end)
			return {
				Set = function(_, v) rBox.Text = tostring(v) end,
				SetText = function(_, v) rBox.Text = tostring(v) end
			}
		end
		function tab:Bind(txt, defaultKey, cb)
			local key = defaultKey or Enum.KeyCode.F
			local binding = false
			local btn = C("TextButton", {BackgroundColor3 = Color3.fromRGB(30, 30, 30), Size = UDim2.new(1, -16, 0, 35), Text = "", AutoButtonColor = false, Parent = page,
				C("UICorner", {CornerRadius = UDim.new(0, 4)}),
				C("UIStroke", {Color = Color3.fromRGB(50, 50, 50), Thickness = 1}),
				C("TextLabel", {BackgroundTransparency = 1, Size = UDim2.new(1, -100, 1, 0), Position = UDim2.new(0, 10, 0, 0), Text = txt, TextColor3 = Color3.fromRGB(220, 220, 220), Font = Enum.Font.Gotham, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left}),
			})
			local lbl = C("TextLabel", {BackgroundColor3 = Color3.fromRGB(15, 15, 15), Size = UDim2.new(0, 80, 0, 24), Position = UDim2.new(1, -90, 0.5, -12), Text = tostring(key):gsub("Enum.KeyCode.", ""), TextColor3 = wnd.ThemeCol, Font = Enum.Font.GothamBold, TextSize = 12, Parent = btn,
				C("UICorner", {CornerRadius = UDim.new(0, 4)})
			})
			btn.MouseButton1Click:Connect(function()
				binding = true
				lbl.Text = "..."
				local conn
				conn = UIS.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.Keyboard then
						key = input.KeyCode
						lbl.Text = tostring(key):gsub("Enum.KeyCode.", "")
						binding = false
						conn:Disconnect()
					end
				end)
			end)
			UIS.InputBegan:Connect(function(input, gpe)
				if not gpe and not binding and input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == key then
					pcall(cb)
				end
			end)
			return {
				Set = function(_, newKey) key = newKey; lbl.Text = tostring(newKey):gsub("Enum.KeyCode.", "") end
			}
		end
		function tab:Seperator(txt)
			C("Frame", {BackgroundTransparency = 1, Size = UDim2.new(1, -16, 0, 30), Parent = page,
				C("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center, HorizontalAlignment = Enum.HorizontalAlignment.Center}),
				C("Frame", {BackgroundColor3 = Color3.fromRGB(50, 50, 50), Size = UDim2.new(0.5, -40, 0, 1), BorderSizePixel = 0}),
				C("TextLabel", {BackgroundTransparency = 1, Size = UDim2.new(0, 80, 1, 0), Text = txt, TextColor3 = Color3.fromRGB(150, 150, 150), Font = Enum.Font.GothamBold, TextSize = 12}),
				C("Frame", {BackgroundColor3 = Color3.fromRGB(50, 50, 50), Size = UDim2.new(0.5, -40, 0, 1), BorderSizePixel = 0})
			})
		end
		function tab:Line()
			C("Frame", {BackgroundColor3 = Color3.fromRGB(50, 50, 50), Size = UDim2.new(1, -16, 0, 1), BorderSizePixel = 0, Parent = page})
		end
		return tab
	end
	return wnd
end
return TCH
