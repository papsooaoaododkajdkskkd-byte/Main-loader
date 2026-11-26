--[[
    ════════════════════════════════════════════
      insight UI — Faithful Recreation
      LocalScript → StarterPlayerScripts
      Audio player excluded per user request
    ════════════════════════════════════════════
--]]

local Players      = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UIS          = game:GetService("UserInputService")
local RunService   = game:GetService("RunService")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

---------------------------------------------------------------
-- 🎨  THEME
---------------------------------------------------------------
local T = {
	Bg           = Color3.fromRGB(35, 26, 23),
	BgDeep       = Color3.fromRGB(28, 20, 17),
	BgSidebar    = Color3.fromRGB(30, 22, 19),
	BgTopBar     = Color3.fromRGB(26, 18, 15),
	BgInput      = Color3.fromRGB(44, 33, 29),
	BgHover      = Color3.fromRGB(52, 40, 35),

	Accent       = Color3.fromRGB(228, 78, 38),
	AccentDim    = Color3.fromRGB(175, 58, 28),

	Text         = Color3.fromRGB(238, 230, 226),
	TextSec      = Color3.fromRGB(145, 132, 126),
	TextDim      = Color3.fromRGB(95, 84, 78),

	CheckOn      = Color3.fromRGB(222, 72, 34),
	CheckOff     = Color3.fromRGB(58, 44, 40),

	SliderTrack  = Color3.fromRGB(52, 40, 36),
	SliderThumb  = Color3.fromRGB(228, 78, 38),

	Border       = Color3.fromRGB(60, 46, 40),
	BorderDim    = Color3.fromRGB(48, 36, 32),

	FovPink      = Color3.fromRGB(232, 52, 78),
	White        = Color3.fromRGB(255, 255, 255),
}

---------------------------------------------------------------
-- ⏱  TWEEN PRESETS
---------------------------------------------------------------
local tfFast   = TweenInfo.new(0.12, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local tfMed    = TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local tfSlow   = TweenInfo.new(0.32, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local tfBounce = TweenInfo.new(0.28, Enum.EasingStyle.Back,  Enum.EasingDirection.Out)

local function tw(obj, info, props)
	local t = TweenService:Create(obj, info, props)
	t:Play()
	return t
end

---------------------------------------------------------------
-- 🛠  TINY BUILDERS
---------------------------------------------------------------
local function mkCorner(p, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = r or UDim.new(0, 6)
	c.Parent = p
	return c
end

local function mkStroke(p, col, thick, trans)
	local s = Instance.new("UIStroke")
	s.Color = col or T.Border
	s.Thickness = thick or 1
	s.Transparency = trans or 0.5
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = p
	return s
end

local function mkPad(p, top, right, bot, left)
	local d = Instance.new("UIPadding")
	d.PaddingTop    = UDim.new(0, top or 0)
	d.PaddingRight  = UDim.new(0, right or top or 0)
	d.PaddingBottom = UDim.new(0, bot or top or 0)
	d.PaddingLeft   = UDim.new(0, left or right or top or 0)
	d.Parent = p
	return d
end

local function mkList(p, dir, pad, hAlign, vAlign, sortOrder)
	local l = Instance.new("UIListLayout")
	l.FillDirection = dir or Enum.FillDirection.Vertical
	l.Padding = UDim.new(0, pad or 4)
	l.HorizontalAlignment = hAlign or Enum.HorizontalAlignment.Left
	l.VerticalAlignment = vAlign or Enum.VerticalAlignment.Top
	l.SortOrder = sortOrder or Enum.SortOrder.LayoutOrder
	l.Parent = p
	return l
end

---------------------------------------------------------------
-- 📐  DIMENSIONS
---------------------------------------------------------------
local PANEL_W, PANEL_H = 460, 370
local SIDEBAR_W        = 50
local CONTENT_W        = PANEL_W - SIDEBAR_W
local TOPBAR_H         = 34
local HEADER_H         = 44
local TABBAR_H         = 32
local COL_W            = math.floor((CONTENT_W - 48) / 2)

---------------------------------------------------------------
-- 🏗  SCREEN GUI
---------------------------------------------------------------
local sg = Instance.new("ScreenGui")
sg.Name = "InsightUI"
sg.ResetOnSpawn = false
sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
sg.Parent = playerGui

-- Root container (holds topbar + panel, used for dragging & entrance anim)
local root = Instance.new("Frame")
root.Name = "Root"
root.AnchorPoint = Vector2.new(0.5, 0.5)
root.Position = UDim2.new(0.5, 0, 0.5, 0)
root.Size = UDim2.fromOffset(PANEL_W, TOPBAR_H + 4 + PANEL_H)
root.BackgroundTransparency = 1
root.Parent = sg

---------------------------------------------------------------
-- ▬  TOP BAR
---------------------------------------------------------------
local topBar = Instance.new("TextButton")
topBar.Name = "TopBar"
topBar.Size = UDim2.new(1, 0, 0, TOPBAR_H)
topBar.Position = UDim2.new(0, 0, 0, 0)
topBar.BackgroundColor3 = T.BgTopBar
topBar.AutoButtonColor = false
topBar.Text = ""
topBar.Parent = root
mkCorner(topBar, UDim.new(0, 8))

-- Accent line at top
local accentLine = Instance.new("Frame")
accentLine.Size = UDim2.new(1, 0, 0, 2)
accentLine.Position = UDim2.new(0, 0, 0, 0)
accentLine.BackgroundColor3 = T.Accent
accentLine.BorderSizePixel = 0
accentLine.ZIndex = 3
accentLine.Parent = topBar
mkCorner(accentLine, UDim.new(0, 8))

-- Top bar text with live clock
local topBarLabel = Instance.new("TextLabel")
topBarLabel.Size = UDim2.new(1, -20, 1, 0)
topBarLabel.Position = UDim2.new(0, 14, 0, 0)
topBarLabel.BackgroundTransparency = 1
topBarLabel.Font = Enum.Font.GothamBold
topBarLabel.TextSize = 13
topBarLabel.TextColor3 = T.Text
topBarLabel.TextXAlignment = Enum.TextXAlignment.Left
topBarLabel.RichText = true
topBarLabel.Parent = topBar

local function updateClock()
	local t = os.date("*t")
	local clock = string.format("%02d:%02d:%02d", t.hour, t.min, t.sec)
	topBarLabel.Text = string.format(
		'insight [beta]  <font color="#%s">|</font>  <font color="#E44E26">dev</font>  <font color="#%s">|</font>  %s',
		"5F544E", "5F544E", clock
	)
end
updateClock()
local clockConn = RunService.Heartbeat:Connect(function()
	updateClock()
end)

---------------------------------------------------------------
-- ◼  MAIN PANEL
---------------------------------------------------------------
local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.Size = UDim2.new(1, 0, 0, PANEL_H)
panel.Position = UDim2.new(0, 0, 0, TOPBAR_H + 4)
panel.BackgroundColor3 = T.Bg
panel.ClipsDescendants = true
panel.Parent = root
mkCorner(panel, UDim.new(0, 10))

---------------------------------------------------------------
-- ◀  SIDEBAR
---------------------------------------------------------------
local sidebar = Instance.new("Frame")
sidebar.Name = "Sidebar"
sidebar.Size = UDim2.new(0, SIDEBAR_W, 1, 0)
sidebar.Position = UDim2.new(0, 0, 0, 0)
sidebar.BackgroundColor3 = T.BgSidebar
sidebar.BorderSizePixel = 0
sidebar.ZIndex = 2
sidebar.Parent = panel
mkCorner(sidebar, UDim.new(0, 10))

-- Cover the right-side rounded corners of sidebar
local sidebarCover = Instance.new("Frame")
sidebarCover.Size = UDim2.new(0, 12, 1, 0)
sidebarCover.Position = UDim2.new(1, -12, 0, 0)
sidebarCover.BackgroundColor3 = T.BgSidebar
sidebarCover.BorderSizePixel = 0
sidebarCover.ZIndex = 2
sidebarCover.Parent = sidebar

-- Separator line
local sepLine = Instance.new("Frame")
sepLine.Size = UDim2.new(0, 1, 1, -16)
sepLine.Position = UDim2.new(0, SIDEBAR_W, 0, 8)
sepLine.BackgroundColor3 = T.Border
sepLine.BackgroundTransparency = 0.6
sepLine.BorderSizePixel = 0
sepLine.ZIndex = 3
sepLine.Parent = panel

-- Sidebar icons
local iconDefs = {
	{ sym = "⊹",  name = "aimbot"   },
	{ sym = "◉",  name = "visuals"  },
	{ sym = "✦",  name = "world"    },
	{ sym = "⚇",  name = "players"  },
	{ sym = "☰",  name = "settings" },
}

local iconContainer = Instance.new("Frame")
iconContainer.Size = UDim2.new(1, 0, 0, #iconDefs * 44)
iconContainer.Position = UDim2.new(0, 0, 0, 12)
iconContainer.BackgroundTransparency = 1
iconContainer.ZIndex = 4
iconContainer.Parent = sidebar
mkList(iconContainer, Enum.FillDirection.Vertical, 2, Enum.HorizontalAlignment.Center)

local activeSidebarIdx = 1
local sidebarButtons = {}

for i, def in ipairs(iconDefs) do
	local btn = Instance.new("TextButton")
	btn.Name = def.name
	btn.Size = UDim2.new(0, 40, 0, 40)
	btn.BackgroundColor3 = T.BgHover
	btn.BackgroundTransparency = i == 1 and 0.5 or 1
	btn.Text = def.sym
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 18
	btn.TextColor3 = i == 1 and T.Accent or T.TextSec
	btn.AutoButtonColor = false
	btn.LayoutOrder = i
	btn.ZIndex = 5
	btn.Parent = iconContainer
	mkCorner(btn, UDim.new(0, 8))

	-- Active indicator bar (left edge)
	local indicator = Instance.new("Frame")
	indicator.Name = "Indicator"
	indicator.Size = UDim2.new(0, 3, 0, i == 1 and 20 or 0)
	indicator.Position = UDim2.new(0, -2, 0.5, 0)
	indicator.AnchorPoint = Vector2.new(0, 0.5)
	indicator.BackgroundColor3 = T.Accent
	indicator.BorderSizePixel = 0
	indicator.ZIndex = 6
	indicator.Parent = btn
	mkCorner(indicator, UDim.new(0, 2))

	sidebarButtons[i] = { btn = btn, indicator = indicator }

	-- Hover
	btn.MouseEnter:Connect(function()
		if activeSidebarIdx ~= i then
			tw(btn, tfFast, { BackgroundTransparency = 0.6 })
			tw(btn, tfFast, { TextColor3 = T.Text })
		end
	end)
	btn.MouseLeave:Connect(function()
		if activeSidebarIdx ~= i then
			tw(btn, tfFast, { BackgroundTransparency = 1 })
			tw(btn, tfFast, { TextColor3 = T.TextSec })
		end
	end)

	-- Click
	btn.MouseButton1Click:Connect(function()
		if activeSidebarIdx == i then return end
		-- Deactivate old
		local old = sidebarButtons[activeSidebarIdx]
		tw(old.btn, tfMed, { BackgroundTransparency = 1, TextColor3 = T.TextSec })
		tw(old.indicator, tfMed, { Size = UDim2.new(0, 3, 0, 0) })
		-- Activate new
		activeSidebarIdx = i
		tw(btn, tfMed, { BackgroundTransparency = 0.5, TextColor3 = T.Accent })
		tw(indicator, tfBounce, { Size = UDim2.new(0, 3, 0, 20) })
	end)
end

-- Avatar circle at sidebar bottom
local avatar = Instance.new("Frame")
avatar.Size = UDim2.fromOffset(32, 32)
avatar.AnchorPoint = Vector2.new(0.5, 1)
avatar.Position = UDim2.new(0.5, 0, 1, -14)
avatar.BackgroundColor3 = Color3.fromRGB(165, 140, 125)
avatar.ZIndex = 4
avatar.Parent = sidebar
mkCorner(avatar, UDim.new(1, 0))
mkStroke(avatar, T.Border, 2, 0.4)

---------------------------------------------------------------
-- 📄  CONTENT AREA
---------------------------------------------------------------
local content = Instance.new("Frame")
content.Name = "Content"
content.Size = UDim2.new(1, -SIDEBAR_W, 1, 0)
content.Position = UDim2.new(0, SIDEBAR_W, 0, 0)
content.BackgroundTransparency = 1
content.ZIndex = 2
content.Parent = panel

-- ── HEADER ───────────────────────────────────────
local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, HEADER_H)
header.BackgroundTransparency = 1
header.ZIndex = 3
header.Parent = content

local logo = Instance.new("TextLabel")
logo.Size = UDim2.new(0, 120, 1, 0)
logo.Position = UDim2.new(0, 18, 0, 0)
logo.BackgroundTransparency = 1
logo.Font = Enum.Font.Merriweather
logo.TextSize = 24
logo.TextColor3 = T.Accent
logo.Text = "insight"
logo.TextXAlignment = Enum.TextXAlignment.Left
logo.RichText = true
logo.ZIndex = 3
logo.Parent = header

-- Close button
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.fromOffset(28, 28)
closeBtn.AnchorPoint = Vector2.new(1, 0.5)
closeBtn.Position = UDim2.new(1, -14, 0.5, 0)
closeBtn.BackgroundTransparency = 1
closeBtn.Text = "✕"
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 16
closeBtn.TextColor3 = T.TextSec
closeBtn.AutoButtonColor = false
closeBtn.ZIndex = 3
closeBtn.Parent = header

closeBtn.MouseEnter:Connect(function() tw(closeBtn, tfFast, { TextColor3 = T.Accent }) end)
closeBtn.MouseLeave:Connect(function() tw(closeBtn, tfFast, { TextColor3 = T.TextSec }) end)
closeBtn.MouseButton1Click:Connect(function()
	tw(root, tfSlow, { Size = UDim2.fromOffset(PANEL_W * 0.96, (TOPBAR_H + 4 + PANEL_H) * 0.96) })
	local fade = tw(sg, tfSlow, {})  -- dummy; we'll handle via group transparency
	for _, desc in ipairs(root:GetDescendants()) do
		if desc:IsA("GuiObject") and desc.BackgroundTransparency < 1 then
			tw(desc, tfSlow, { BackgroundTransparency = 1 })
		end
		if desc:IsA("TextLabel") or desc:IsA("TextButton") then
			tw(desc, tfSlow, { TextTransparency = 1 })
		end
	end
	task.delay(0.35, function() sg.Enabled = false end)
end)

-- Search button
local searchBtn = Instance.new("TextButton")
searchBtn.Size = UDim2.fromOffset(28, 28)
searchBtn.AnchorPoint = Vector2.new(1, 0.5)
searchBtn.Position = UDim2.new(1, -44, 0.5, 0)
searchBtn.BackgroundTransparency = 1
searchBtn.Text = "🔍"
searchBtn.Font = Enum.Font.Gotham
searchBtn.TextSize = 15
searchBtn.TextColor3 = T.TextSec
searchBtn.AutoButtonColor = false
searchBtn.ZIndex = 3
searchBtn.Parent = header

searchBtn.MouseEnter:Connect(function() tw(searchBtn, tfFast, { TextColor3 = T.Text }) end)
searchBtn.MouseLeave:Connect(function() tw(searchBtn, tfFast, { TextColor3 = T.TextSec }) end)

-- ── TAB BAR ──────────────────────────────────────
local tabBar = Instance.new("Frame")
tabBar.Size = UDim2.new(1, 0, 0, TABBAR_H)
tabBar.Position = UDim2.new(0, 0, 0, HEADER_H)
tabBar.BackgroundTransparency = 1
tabBar.ZIndex = 3
tabBar.Parent = content

local tabInner = Instance.new("Frame")
tabInner.Size = UDim2.new(1, -36, 1, 0)
tabInner.Position = UDim2.new(0, 18, 0, 0)
tabInner.BackgroundTransparency = 1
tabInner.ZIndex = 3
tabInner.Parent = tabBar
mkList(tabInner, Enum.FillDirection.Horizontal, 8, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Center)

-- "aimbot >"
local aimTabPrefix = Instance.new("TextLabel")
aimTabPrefix.Size = UDim2.fromOffset(72, TABBAR_H)
aimTabPrefix.BackgroundTransparency = 1
aimTabPrefix.Text = "aimbot  >"
aimTabPrefix.Font = Enum.Font.GothamMedium
aimTabPrefix.TextSize = 12
aimTabPrefix.TextColor3 = T.TextSec
aimTabPrefix.LayoutOrder = 0
aimTabPrefix.ZIndex = 3
aimTabPrefix.Parent = tabInner

local tabNames   = { "general", "triggerbot", "hitboxes" }
local activeTab   = 1
local tabButtons  = {}

for i, name in ipairs(tabNames) do
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.fromOffset(#name * 7.5 + 12, TABBAR_H)
	btn.BackgroundTransparency = 1
	btn.Text = name
	btn.Font = Enum.Font.GothamMedium
	btn.TextSize = 12
	btn.TextColor3 = i == 1 and T.Accent or T.TextDim
	btn.AutoButtonColor = false
	btn.LayoutOrder = i
	btn.ZIndex = 3
	btn.Parent = tabInner

	tabButtons[i] = btn

	btn.MouseEnter:Connect(function()
		if activeTab ~= i then tw(btn, tfFast, { TextColor3 = T.TextSec }) end
	end)
	btn.MouseLeave:Connect(function()
		if activeTab ~= i then tw(btn, tfFast, { TextColor3 = T.TextDim }) end
	end)
	btn.MouseButton1Click:Connect(function()
		if activeTab == i then return end
		tw(tabButtons[activeTab], tfMed, { TextColor3 = T.TextDim })
		activeTab = i
		tw(btn, tfMed, { TextColor3 = T.Accent })
	end)
end

-- Tab separator line
local tabSep = Instance.new("Frame")
tabSep.Size = UDim2.new(1, -36, 0, 1)
tabSep.Position = UDim2.new(0, 18, 0, HEADER_H + TABBAR_H)
tabSep.BackgroundColor3 = T.Border
tabSep.BackgroundTransparency = 0.6
tabSep.BorderSizePixel = 0
tabSep.ZIndex = 3
tabSep.Parent = content

---------------------------------------------------------------
-- 🔧  COMPONENT FACTORIES
---------------------------------------------------------------

-- Section header label
local function mkSection(parent, text, order)
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, 0, 0, 22)
	lbl.BackgroundTransparency = 1
	lbl.Text = text
	lbl.Font = Enum.Font.GothamMedium
	lbl.TextSize = 12
	lbl.TextColor3 = T.TextSec
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.LayoutOrder = order or 0
	lbl.ZIndex = 4
	lbl.Parent = parent
	return lbl
end

-- Keybind / badge pill
local function mkBadge(parent, text)
	local badge = Instance.new("TextLabel")
	badge.Size = UDim2.fromOffset(text == "NONE" and 44 or 30, 20)
	badge.BackgroundColor3 = T.BgInput
	badge.TextColor3 = T.TextSec
	badge.Text = text
	badge.Font = Enum.Font.GothamMedium
	badge.TextSize = 10
	badge.ZIndex = 5
	badge.Parent = parent
	mkCorner(badge, UDim.new(0, 4))
	mkStroke(badge, T.BorderDim, 1, 0.55)
	return badge
end

-- Checkbox row  ------------------------------------------------
local function mkCheckbox(parent, text, default, order, extras)
	-- extras = { keybind = "M2", lock = true }
	extras = extras or {}
	local row = Instance.new("TextButton")
	row.Name = "Check_" .. text
	row.Size = UDim2.new(1, 0, 0, 24)
	row.BackgroundColor3 = T.BgHover
	row.BackgroundTransparency = 1
	row.Text = ""
	row.AutoButtonColor = false
	row.LayoutOrder = order or 0
	row.ZIndex = 4
	row.Parent = parent
	mkCorner(row, UDim.new(0, 4))

	-- Checkbox square
	local box = Instance.new("Frame")
	box.Size = UDim2.fromOffset(18, 18)
	box.AnchorPoint = Vector2.new(0, 0.5)
	box.Position = UDim2.new(0, 0, 0.5, 0)
	box.BackgroundColor3 = default and T.CheckOn or T.CheckOff
	box.ZIndex = 5
	box.Parent = row
	mkCorner(box, UDim.new(0, 4))
	if not default then mkStroke(box, T.Border, 1, 0.5) end

	local check = Instance.new("TextLabel")
	check.Size = UDim2.new(1, 0, 1, 0)
	check.BackgroundTransparency = 1
	check.Text = "✓"
	check.Font = Enum.Font.GothamBold
	check.TextSize = 13
	check.TextColor3 = T.White
	check.TextTransparency = default and 0 or 1
	check.ZIndex = 6
	check.Parent = box

	-- Label
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, -26, 1, 0)
	lbl.Position = UDim2.new(0, 26, 0, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text = text
	lbl.Font = Enum.Font.GothamMedium
	lbl.TextSize = 12
	lbl.TextColor3 = T.Text
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.ZIndex = 5
	lbl.Parent = row

	-- Optional lock icon
	if extras.lock then
		local lock = Instance.new("TextLabel")
		lock.Size = UDim2.fromOffset(16, 20)
		lock.AnchorPoint = Vector2.new(1, 0.5)
		lock.Position = UDim2.new(1, extras.keybind and -52 or -4, 0.5, 0)
		lock.BackgroundTransparency = 1
		lock.Text = "🔒"
		lock.TextSize = 11
		lock.ZIndex = 5
		lock.Parent = row
	end

	-- Optional keybind badge
	if extras.keybind then
		local badge = mkBadge(row, extras.keybind)
		badge.AnchorPoint = Vector2.new(1, 0.5)
		badge.Position = UDim2.new(1, -2, 0.5, 0)
	end

	local state = { on = default and true or false }

	-- Hover
	row.MouseEnter:Connect(function() tw(row, tfFast, { BackgroundTransparency = 0.7 }) end)
	row.MouseLeave:Connect(function() tw(row, tfFast, { BackgroundTransparency = 1 }) end)

	-- Toggle
	row.MouseButton1Click:Connect(function()
		state.on = not state.on
		tw(box, tfMed, { BackgroundColor3 = state.on and T.CheckOn or T.CheckOff })
		tw(check, tfMed, { TextTransparency = state.on and 0 or 1 })
		-- Scale bounce
		tw(box, tfFast, { Size = UDim2.fromOffset(20, 20) })
		task.delay(0.1, function()
			tw(box, tfBounce, { Size = UDim2.fromOffset(18, 18) })
		end)

		-- Manage stroke visibility
		local existingStroke = box:FindFirstChildOfClass("UIStroke")
		if state.on and existingStroke then
			tw(existingStroke, tfMed, { Transparency = 1 })
		elseif not state.on then
			if not existingStroke then
				mkStroke(box, T.Border, 1, 0.5)
			else
				tw(existingStroke, tfMed, { Transparency = 0.5 })
			end
		end
	end)

	return row, state
end

-- Slider  -------------------------------------------------------
local function mkSlider(parent, labelText, min, max, step, default, suffix, order)
	local container = Instance.new("Frame")
	container.Name = "Slider_" .. labelText
	container.Size = UDim2.new(1, 0, 0, 36)
	container.BackgroundTransparency = 1
	container.LayoutOrder = order or 0
	container.ZIndex = 4
	container.Parent = parent

	-- Label + value row
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(0.6, 0, 0, 16)
	lbl.BackgroundTransparency = 1
	lbl.Text = labelText
	lbl.Font = Enum.Font.GothamMedium
	lbl.TextSize = 12
	lbl.TextColor3 = T.TextSec
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.ZIndex = 5
	lbl.Parent = container

	local valLabel = Instance.new("TextLabel")
	valLabel.Size = UDim2.new(0.4, 0, 0, 16)
	valLabel.AnchorPoint = Vector2.new(1, 0)
	valLabel.Position = UDim2.new(1, 0, 0, 0)
	valLabel.BackgroundTransparency = 1
	valLabel.Font = Enum.Font.GothamMedium
	valLabel.TextSize = 12
	valLabel.TextColor3 = T.TextSec
	valLabel.TextXAlignment = Enum.TextXAlignment.Right
	valLabel.ZIndex = 5
	valLabel.Parent = container

	-- Track
	local track = Instance.new("TextButton")
	track.Size = UDim2.new(1, 0, 0, 4)
	track.Position = UDim2.new(0, 0, 0, 24)
	track.BackgroundColor3 = T.SliderTrack
	track.AutoButtonColor = false
	track.Text = ""
	track.ZIndex = 5
	track.Parent = container
	mkCorner(track, UDim.new(1, 0))

	-- Fill
	local pct = math.clamp((default - min) / (max - min), 0, 1)
	local fill = Instance.new("Frame")
	fill.Size = UDim2.new(pct, 0, 1, 0)
	fill.BackgroundColor3 = T.SliderThumb
	fill.BorderSizePixel = 0
	fill.ZIndex = 6
	fill.Parent = track
	mkCorner(fill, UDim.new(1, 0))

	-- Thumb
	local thumb = Instance.new("Frame")
	thumb.Size = UDim2.fromOffset(12, 12)
	thumb.AnchorPoint = Vector2.new(0.5, 0.5)
	thumb.Position = UDim2.new(pct, 0, 0.5, 0)
	thumb.BackgroundColor3 = T.SliderThumb
	thumb.ZIndex = 7
	thumb.Parent = track
	mkCorner(thumb, UDim.new(1, 0))

	-- Thumb glow (shadow)
	local thumbGlow = Instance.new("Frame")
	thumbGlow.Size = UDim2.fromOffset(20, 20)
	thumbGlow.AnchorPoint = Vector2.new(0.5, 0.5)
	thumbGlow.Position = UDim2.new(0.5, 0, 0.5, 0)
	thumbGlow.BackgroundColor3 = T.SliderThumb
	thumbGlow.BackgroundTransparency = 1
	thumbGlow.ZIndex = 6
	thumbGlow.Parent = thumb
	mkCorner(thumbGlow, UDim.new(1, 0))

	local value = default
	local dragging = false

	local function formatVal(v)
		if step >= 1 then
			return tostring(math.floor(v + 0.5))
		else
			return string.format("%.1f", v)
		end
	end

	local function updateVisual(v, animate)
		local p = math.clamp((v - min) / (max - min), 0, 1)
		valLabel.Text = formatVal(v) .. (suffix or "")
		if animate then
			tw(fill, tfFast, { Size = UDim2.new(p, 0, 1, 0) })
			tw(thumb, tfFast, { Position = UDim2.new(p, 0, 0.5, 0) })
		else
			fill.Size = UDim2.new(p, 0, 1, 0)
			thumb.Position = UDim2.new(p, 0, 0.5, 0)
		end
	end

	local function setFromInput(inputX)
		local absX = track.AbsolutePosition.X
		local absW = track.AbsoluteSize.X
		local p = math.clamp((inputX - absX) / absW, 0, 1)
		local raw = min + p * (max - min)
		value = math.clamp(math.floor(raw / step + 0.5) * step, min, max)
		updateVisual(value, false)
	end

	updateVisual(default, false)

	track.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			setFromInput(input.Position.X)
			tw(thumbGlow, tfFast, { BackgroundTransparency = 0.7 })
			tw(thumb, tfFast, { Size = UDim2.fromOffset(14, 14) })
		end
	end)

	UIS.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch) then
			setFromInput(input.Position.X)
		end
	end)

	UIS.InputEnded:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch) then
			dragging = false
			tw(thumbGlow, tfMed, { BackgroundTransparency = 1 })
			tw(thumb, tfMed, { Size = UDim2.fromOffset(12, 12) })
		end
	end)

	return container, { getValue = function() return value end }
end

-- Dropdown  ------------------------------------------------------
local function mkDropdown(parent, options, default, order)
	local container = Instance.new("Frame")
	container.Name = "Dropdown"
	container.Size = UDim2.new(1, 0, 0, 30)
	container.BackgroundTransparency = 1
	container.LayoutOrder = order or 0
	container.ZIndex = 10
	container.ClipsDescendants = false
	container.Parent = parent

	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, 0, 0, 30)
	btn.BackgroundColor3 = T.BgInput
	btn.AutoButtonColor = false
	btn.Text = ""
	btn.ZIndex = 11
	btn.Parent = container
	mkCorner(btn, UDim.new(0, 6))
	mkStroke(btn, T.BorderDim, 1, 0.45)

	local selLabel = Instance.new("TextLabel")
	selLabel.Size = UDim2.new(1, -28, 1, 0)
	selLabel.Position = UDim2.new(0, 10, 0, 0)
	selLabel.BackgroundTransparency = 1
	selLabel.Text = default or options[1]
	selLabel.Font = Enum.Font.GothamMedium
	selLabel.TextSize = 12
	selLabel.TextColor3 = T.Text
	selLabel.TextXAlignment = Enum.TextXAlignment.Left
	selLabel.ZIndex = 12
	selLabel.Parent = btn

	local arrow = Instance.new("TextLabel")
	arrow.Size = UDim2.fromOffset(20, 30)
	arrow.AnchorPoint = Vector2.new(1, 0)
	arrow.Position = UDim2.new(1, -4, 0, 0)
	arrow.BackgroundTransparency = 1
	arrow.Text = "▾"
	arrow.Font = Enum.Font.GothamBold
	arrow.TextSize = 14
	arrow.TextColor3 = T.TextSec
	arrow.ZIndex = 12
	arrow.Parent = btn

	-- Options list
	local optionListH = #options * 28 + 6
	local optionFrame = Instance.new("Frame")
	optionFrame.Size = UDim2.new(1, 0, 0, 0)
	optionFrame.Position = UDim2.new(0, 0, 0, 32)
	optionFrame.BackgroundColor3 = T.BgInput
	optionFrame.ClipsDescendants = true
	optionFrame.ZIndex = 20
	optionFrame.Parent = container
	mkCorner(optionFrame, UDim.new(0, 6))
	mkStroke(optionFrame, T.BorderDim, 1, 0.45)

	local optList = Instance.new("Frame")
	optList.Size = UDim2.new(1, 0, 0, optionListH)
	optList.BackgroundTransparency = 1
	optList.ZIndex = 21
	optList.Parent = optionFrame
	mkList(optList, Enum.FillDirection.Vertical, 2)
	mkPad(optList, 3, 3, 3, 3)

	local isOpen = false

	for _, opt in ipairs(options) do
		local optBtn = Instance.new("TextButton")
		optBtn.Size = UDim2.new(1, 0, 0, 26)
		optBtn.BackgroundColor3 = T.BgHover
		optBtn.BackgroundTransparency = 1
		optBtn.Text = opt
		optBtn.Font = Enum.Font.GothamMedium
		optBtn.TextSize = 12
		optBtn.TextColor3 = T.Text
		optBtn.TextXAlignment = Enum.TextXAlignment.Left
		optBtn.AutoButtonColor = false
		optBtn.ZIndex = 22
		optBtn.Parent = optList
		mkCorner(optBtn, UDim.new(0, 4))
		mkPad(optBtn, 0, 8, 0, 8)

		optBtn.MouseEnter:Connect(function() tw(optBtn, tfFast, { BackgroundTransparency = 0.5 }) end)
		optBtn.MouseLeave:Connect(function() tw(optBtn, tfFast, { BackgroundTransparency = 1 }) end)

		optBtn.MouseButton1Click:Connect(function()
			selLabel.Text = opt
			isOpen = false
			tw(optionFrame, tfMed, { Size = UDim2.new(1, 0, 0, 0) })
			tw(arrow, tfMed, { Rotation = 0 })
		end)
	end

	-- Toggle
	btn.MouseButton1Click:Connect(function()
		isOpen = not isOpen
		if isOpen then
			tw(optionFrame, tfMed, { Size = UDim2.new(1, 0, 0, optionListH) })
			tw(arrow, tfMed, { Rotation = 180 })
		else
			tw(optionFrame, tfMed, { Size = UDim2.new(1, 0, 0, 0) })
			tw(arrow, tfMed, { Rotation = 0 })
		end
	end)

	-- Hover on main button
	btn.MouseEnter:Connect(function() tw(btn, tfFast, { BackgroundColor3 = T.BgHover }) end)
	btn.MouseLeave:Connect(function() tw(btn, tfFast, { BackgroundColor3 = T.BgInput }) end)

	return container
end

-- Color swatch  ---------------------------------------------------
local function mkColorSwatch(parent, labelText, default, order)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 24)
	row.BackgroundTransparency = 1
	row.LayoutOrder = order or 0
	row.ZIndex = 4
	row.Parent = parent

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(0.6, 0, 1, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text = labelText
	lbl.Font = Enum.Font.GothamMedium
	lbl.TextSize = 12
	lbl.TextColor3 = T.TextSec
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.ZIndex = 5
	lbl.Parent = row

	local swatch = Instance.new("TextButton")
	swatch.Size = UDim2.fromOffset(36, 18)
	swatch.AnchorPoint = Vector2.new(1, 0.5)
	swatch.Position = UDim2.new(1, 0, 0.5, 0)
	swatch.BackgroundColor3 = default or T.FovPink
	swatch.AutoButtonColor = false
	swatch.Text = ""
	swatch.ZIndex = 5
	swatch.Parent = row
	mkCorner(swatch, UDim.new(0, 4))
	mkStroke(swatch, T.BorderDim, 1, 0.5)

	local presets = {
		Color3.fromRGB(232, 52, 78),
		Color3.fromRGB(52, 199, 89),
		Color3.fromRGB(52, 120, 246),
		Color3.fromRGB(255, 204, 0),
		Color3.fromRGB(255, 255, 255),
		Color3.fromRGB(0, 230, 230),
	}
	local idx = 1

	swatch.MouseButton1Click:Connect(function()
		idx = idx % #presets + 1
		tw(swatch, tfMed, { BackgroundColor3 = presets[idx] })
	end)

	swatch.MouseEnter:Connect(function()
		tw(swatch, tfFast, { Size = UDim2.fromOffset(38, 20) })
	end)
	swatch.MouseLeave:Connect(function()
		tw(swatch, tfFast, { Size = UDim2.fromOffset(36, 18) })
	end)

	return row
end

---------------------------------------------------------------
-- ⚙  SETTINGS AREA
---------------------------------------------------------------
local settingsY = HEADER_H + TABBAR_H + 6
local settings = Instance.new("Frame")
settings.Name = "Settings"
settings.Size = UDim2.new(1, 0, 1, -settingsY)
settings.Position = UDim2.new(0, 0, 0, settingsY)
settings.BackgroundTransparency = 1
settings.ZIndex = 3
settings.Parent = content

-- ── LEFT COLUMN ──────────────────────────────────
local leftCol = Instance.new("Frame")
leftCol.Name = "LeftCol"
leftCol.Size = UDim2.new(0, COL_W, 1, -10)
leftCol.Position = UDim2.new(0, 18, 0, 6)
leftCol.BackgroundTransparency = 1
leftCol.ZIndex = 4
leftCol.Parent = settings
mkList(leftCol, Enum.FillDirection.Vertical, 4)

mkSection(leftCol, "aimbot", 1)
mkCheckbox(leftCol, "aimbot", true, 2, { lock = true, keybind = "M2" })
mkCheckbox(leftCol, "silent aim", false, 3, { keybind = "NONE" })

-- Spacer
local spacer1 = Instance.new("Frame")
spacer1.Size = UDim2.new(1, 0, 0, 4)
spacer1.BackgroundTransparency = 1
spacer1.LayoutOrder = 4
spacer1.Parent = leftCol

mkSection(leftCol, "target", 5)
mkDropdown(leftCol, { "Head", "Torso", "Closest", "Random" }, "Head", 6)

-- Spacer
local spacer2 = Instance.new("Frame")
spacer2.Size = UDim2.new(1, 0, 0, 4)
spacer2.BackgroundTransparency = 1
spacer2.LayoutOrder = 7
spacer2.Parent = leftCol

mkSection(leftCol, "aim lock & smoothing", 8)
mkCheckbox(leftCol, "smoothing", true, 9, { keybind = "NONE" })
mkSlider(leftCol, "smoothness", 0, 10, 0.1, 5.0, nil, 10)

-- ── RIGHT COLUMN ─────────────────────────────────
local rightCol = Instance.new("Frame")
rightCol.Name = "RightCol"
rightCol.Size = UDim2.new(0, COL_W, 1, -10)
rightCol.Position = UDim2.new(0, 18 + COL_W + 16, 0, 6)
rightCol.BackgroundTransparency = 1
rightCol.ZIndex = 4
rightCol.Parent = settings
mkList(rightCol, Enum.FillDirection.Vertical, 4)

mkSection(rightCol, "fov settings", 1)
mkCheckbox(rightCol, "draw fov", true, 2)
mkSlider(rightCol, "fov radius", 0, 500, 1, 120, " px", 3)
mkColorSwatch(rightCol, "fov color", T.FovPink, 4)

-- Spacer
local spacer3 = Instance.new("Frame")
spacer3.Size = UDim2.new(1, 0, 0, 4)
spacer3.BackgroundTransparency = 1
spacer3.LayoutOrder = 5
spacer3.Parent = rightCol

mkSection(rightCol, "target checks", 6)
mkCheckbox(rightCol, "visible check", true, 7)
mkCheckbox(rightCol, "team check", false, 8)
mkCheckbox(rightCol, "alive check", true, 9)

---------------------------------------------------------------
-- 🖱  DRAGGING
---------------------------------------------------------------
do
	local dragging  = false
	local dragStart = Vector2.zero
	local startPos  = UDim2.new()

	topBar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = root.Position
		end
	end)

	topBar.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)

	UIS.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - dragStart
			root.Position = UDim2.new(
				startPos.X.Scale, startPos.X.Offset + delta.X,
				startPos.Y.Scale, startPos.Y.Offset + delta.Y
			)
		end
	end)
end

---------------------------------------------------------------
-- ✨  ENTRANCE ANIMATION
---------------------------------------------------------------
do
	local totalH = TOPBAR_H + 4 + PANEL_H
	root.Size = UDim2.fromOffset(PANEL_W * 0.94, totalH * 0.94)
	-- Set initial transparency
	for _, desc in ipairs(root:GetDescendants()) do
		if desc:IsA("GuiObject") and desc.BackgroundTransparency < 1 then
			desc.BackgroundTransparency = math.min(desc.BackgroundTransparency + 0.6, 1)
		end
		if desc:IsA("TextLabel") or desc:IsA("TextButton") then
			desc.TextTransparency = 0.6
		end
	end

	task.defer(function()
		tw(root, tfSlow, { Size = UDim2.fromOffset(PANEL_W, totalH) })
		for _, desc in ipairs(root:GetDescendants()) do
			if desc:IsA("Frame") or desc:IsA("TextButton") or desc:IsA("TextLabel") then
				-- Restore to designed transparency
				if desc.Name == "Root" then continue end
				local targetBgTrans = 0
				-- Identify transparent-by-design elements
				if desc.BackgroundTransparency >= 0.9 then
					targetBgTrans = 1
				elseif desc.Name == "ShadowSoft" or desc.Name == "ShadowHard" then
					-- skip
				elseif desc:IsA("Frame") and desc.BackgroundTransparency > 0.5 then
					targetBgTrans = desc.BackgroundTransparency
				end

				if desc:IsA("GuiObject") then
					tw(desc, tfSlow, { BackgroundTransparency = targetBgTrans })
				end
				if desc:IsA("TextLabel") or desc:IsA("TextButton") then
					tw(desc, tfSlow, { TextTransparency = 0 })
				end
			end
		end
	end)
end

---------------------------------------------------------------
-- ⌨  TOGGLE KEY (RightShift to show/hide)
---------------------------------------------------------------
local uiVisible = true
UIS.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == Enum.KeyCode.RightShift then
		uiVisible = not uiVisible
		if uiVisible then
			sg.Enabled = true
			local totalH = TOPBAR_H + 4 + PANEL_H
			tw(root, tfSlow, { Size = UDim2.fromOffset(PANEL_W, totalH) })
			for _, desc in ipairs(root:GetDescendants()) do
				if desc:IsA("GuiObject") and desc.BackgroundTransparency > 0 then
					-- Only restore non-transparent-by-design
				end
				if desc:IsA("TextLabel") or desc:IsA("TextButton") then
					tw(desc, tfSlow, { TextTransparency = 0 })
				end
			end
		else
			for _, desc in ipairs(root:GetDescendants()) do
				if desc:IsA("TextLabel") or desc:IsA("TextButton") then
					tw(desc, tfSlow, { TextTransparency = 1 })
				end
			end
			task.delay(0.35, function() sg.Enabled = false end)
		end
	end
end)
