-- Script taken from https://xenoscripts.com website --

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
    LocalPlayer = Players:WaitForChild("LocalPlayer", 10)
end

local waitFn = (typeof ~= nil and task ~= nil and task.wait) or wait
local function clamp(v, a, b)
    if v < a then return a end
    if v > b then return b end
    return v
end

local function showError(msg)
    pcall(function()
        local sg = Instance.new("ScreenGui")
        sg.ResetOnSpawn = false
        sg.Parent = game:GetService("CoreGui")
        local f = Instance.new("Frame")
        f.Size = UDim2.new(0, 460, 0, 240)
        f.Position = UDim2.new(0.5, -230, 0.5, -120)
        f.BackgroundColor3 = Color3.fromRGB(45, 0, 0)
        f.BorderSizePixel = 0
        f.Parent = sg
        local t = Instance.new("TextLabel")
        t.Size = UDim2.new(1, -16, 1, -16)
        t.Position = UDim2.new(0, 8, 0, 8)
        t.BackgroundTransparency = 1
        t.TextColor3 = Color3.fromRGB(255, 255, 255)
        t.TextSize = 14
        t.TextWrapped = true
        t.Font = Enum.Font.Code
        t.Text = "SCRIPT ERROR:\n" .. tostring(msg)
        t.Parent = f
    end)
end

-- ============================================================
-- HITBOXES MODULE (inline, self-contained for easy sharing)
-- ============================================================
local Hitboxes = (function()
            local H = {}
            local P = game:GetService("Players")
            local LP = P.LocalPlayer
            H.Config = { Enabled = true, TeamCheck = false, Size = 1.6,
                Color = Color3.fromRGB(170, 0, 255), Transparency = 0.4 }
            local visual, connections = {}, {}
            local BASE = Vector3.new(4, 6, 2)
            local function gc(p) return p and p.Character end
            local function isEnemy(p)
                if p == LP then return false end
                if H.Config.TeamCheck and p.Team and LP.Team and p.Team == LP.Team then return false end
                local c = gc(p); return c and c:FindFirstChild("Humanoid") ~= nil
            end
            local function create(p)
                local c = gc(p); if not c then return end
                local root = c:FindFirstChild("HumanoidRootPart"); if not root then return end
                local sz = BASE * H.Config.Size
                local vis = Instance.new("Part")
                vis.Name = "HitboxESP"; vis.CanCollide = false; vis.Anchored = false; vis.Massless = true
                vis.Transparency = H.Config.Transparency; vis.Color = H.Config.Color
                vis.Material = Enum.Material.ForceField; vis.Size = sz; vis.Parent = c
                local w1 = Instance.new("WeldConstraint"); w1.Part0 = root; w1.Part1 = vis; w1.Parent = vis
                visual[p] = vis
            end
            local function remove(p)
                if visual[p] then visual[p]:Destroy(); visual[p] = nil end
            end
            function H:Refresh()
                for _, p in ipairs(P:GetPlayers()) do
                    if self.Config.Enabled and isEnemy(p) then
                        local c = gc(p)
                        local root = c and c:FindFirstChild("HumanoidRootPart")
                        if root then
                            local sz = BASE * self.Config.Size
                            if not visual[p] then
                                create(p)
                            else
                                if visual[p] then visual[p].Size = sz end
                            end
                        end
                    else remove(p) end
                end
            end
            function H:SetEnabled(s) self.Config.Enabled = s; self:Refresh() end
            local function onChar(p, c)
                c:WaitForChild("HumanoidRootPart", 5)
                if H.Config.Enabled and isEnemy(p) then waitFn(0.3); create(p) end
            end
            local function bind(p)
                if connections[p] then return end
                connections[p] = p.CharacterAdded:Connect(function(c) onChar(p, c) end)
                if p.Character then onChar(p, p.Character) end
            end
            for _, p in ipairs(P:GetPlayers()) do bind(p) end
            P.PlayerAdded:Connect(bind)
            P.PlayerRemoving:Connect(function(p)
                if connections[p] then connections[p]:Disconnect(); connections[p] = nil end
                remove(p)
            end)
            return H
        end)()

local function RUN()
    if not Hitboxes then
        error("Hitboxes module failed to initialize.")
    end

    -- ============================================================
    -- AIMBOT (mouse mode, smoothed)
    -- ============================================================
    local Aimbot = {
        Enabled   = false,
        HoldToAim = true,
        FOV       = 250,
        Speed     = 0.35,
        AimHead   = true,
        TeamCheck = false,
    }
    local aiming = false
    local canMouse = (typeof(mousemoverel) == "function")

    local function sameTeam(pl)
        return Aimbot.TeamCheck
            and pl.Team and LocalPlayer.Team
            and pl.Team == LocalPlayer.Team
    end

    local function getTarget()
        local cam = workspace.CurrentCamera
        if not cam then return nil end
        local center = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2)
        local best, bestDist = nil, Aimbot.FOV
        for _, pl in ipairs(Players:GetPlayers()) do
            if pl ~= LocalPlayer and not sameTeam(pl) then
                local char = pl.Character
                if char and char:FindFirstChild("Humanoid") then
                    local part = (Aimbot.AimHead and char:FindFirstChild("Head"))
                        or char:FindFirstChild("HumanoidRootPart")
                    if part and part.Parent then
                        local sp, vis = cam:WorldToViewportPoint(part.Position)
                        if vis then
                            local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                            if d < bestDist then bestDist = d; best = part end
                        end
                    end
                end
            end
        end
        return best
    end

    RunService.RenderStepped:Connect(function()
        pcall(function()
            if not Aimbot.Enabled then return end
            if Aimbot.HoldToAim and not aiming then return end
            if not canMouse then return end
            local cam = workspace.CurrentCamera
            if not cam then return end
            local target = getTarget()
            if not target then return end
            local sp, vis = cam:WorldToViewportPoint(target.Position)
            local vs = cam.ViewportSize
            if not vis or sp.X < 0 or sp.X > vs.X or sp.Y < 0 or sp.Y > vs.Y then return end
            local mp = UserInputService:GetMouseLocation()
            local dx = sp.X - mp.X
            local dy = sp.Y - mp.Y
            local f = clamp(Aimbot.Speed, 0.05, 1)
            mousemoverel(math.round(dx * f), math.round(dy * f))
        end)
    end)

    -- ============================================================
    -- MOVEMENT: FLY + SPEED  (rebindable via settings)
    -- ============================================================
    local Binds = { Menu = "P", Aimbot = "MouseButton2", Fly = "N", Speed = "N" }
    local Fly   = { Enabled = false, Speed = 50 }
    local Speed = { Enabled = false, Value = 32 }
    local speedHum
    local flyBV, flyConn

    local function setFly(on)
        Fly.Enabled = on
        local char = LocalPlayer.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart") or char:WaitForChild("HumanoidRootPart", 5)
        if not hrp then return end
        if on then
            if flyBV then pcall(function() flyBV:Destroy() end) end
            flyBV = Instance.new("BodyVelocity")
            flyBV.MaxForce = Vector3.new(1e5, 1e5, 1e5)
            flyBV.Velocity = Vector3.new()
            flyBV.Parent = hrp
            if flyConn then flyConn:Disconnect() end
            flyConn = RunService.RenderStepped:Connect(function()
                if not flyBV or not flyBV.Parent then return end
                local cam = workspace.CurrentCamera
                if not cam then return end
                local dir = Vector3.new()
                local U = UserInputService
                if U:IsKeyDown(Enum.KeyCode.W) then dir = dir + cam.CFrame.LookVector end
                if U:IsKeyDown(Enum.KeyCode.S) then dir = dir - cam.CFrame.LookVector end
                if U:IsKeyDown(Enum.KeyCode.A) then dir = dir - cam.CFrame.RightVector end
                if U:IsKeyDown(Enum.KeyCode.D) then dir = dir + cam.CFrame.RightVector end
                if U:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0, 1, 0) end
                if U:IsKeyDown(Enum.KeyCode.LeftControl) or U:IsKeyDown(Enum.KeyCode.LeftShift) then dir = dir - Vector3.new(0, 1, 0) end
                if dir.Magnitude > 0 then dir = dir.Unit end
                flyBV.Velocity = dir * Fly.Speed
            end)
        else
            if flyBV then pcall(function() flyBV:Destroy() end); flyBV = nil end
            if flyConn then flyConn:Disconnect(); flyConn = nil end
        end
    end

    local function applySpeed()
        if Speed.Enabled and speedHum then
            speedHum.WalkSpeed = Speed.Value
        end
    end
    local function bindSpeedHum(hum)
        speedHum = hum
        applySpeed()
        hum:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
            if Speed.Enabled and hum.WalkSpeed ~= Speed.Value then
                hum.WalkSpeed = Speed.Value
            end
        end)
    end
    local function setSpeed(on)
        Speed.Enabled = on
        applySpeed()
    end
    do
        local c = LocalPlayer.Character
        local h = c and c:FindFirstChild("Humanoid")
        if h then bindSpeedHum(h) end
    end
    RunService.Stepped:Connect(function()
        if Speed.Enabled and speedHum and speedHum.WalkSpeed ~= Speed.Value then
            speedHum.WalkSpeed = Speed.Value
        end
    end)

    LocalPlayer.CharacterAdded:Connect(function(c)
        waitFn(0.2)
        local hum = c:FindFirstChild("Humanoid") or c:WaitForChild("Humanoid", 5)
        if hum then bindSpeedHum(hum) end
        if Fly.Enabled then
            local hrp = c:WaitForChild("HumanoidRootPart", 5)
            if hrp then setFly(true) end
        end
    end)

    -- ============================================================
    -- TRIGGERBOT (auto-fires when crosshair lands on an enemy)
    -- ============================================================
    local Triggerbot = { Enabled = false }
    local canClick = (typeof(mouse1press) == "function")
    local triggerDown = false

    local function triggerTarget()
        local cam = workspace.CurrentCamera
        if not cam then return false end
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Blacklist
        params.FilterDescendantsInstances = { LocalPlayer.Character or workspace }
        local res = workspace:Raycast(cam.CFrame.Position, cam.CFrame.LookVector * 1000, params)
        if res and res.Instance then
            local m = res.Instance:FindFirstAncestorOfClass("Model")
            if m then
                local pl = Players:GetPlayerFromCharacter(m)
                if pl and pl ~= LocalPlayer and not sameTeam(pl) then
                    return true
                end
            end
        end
        return false
    end

    RunService.RenderStepped:Connect(function()
        if not Triggerbot.Enabled or not canClick then
            if triggerDown then pcall(function() mouse1release() end); triggerDown = false end
            return
        end
        local hit = triggerTarget()
        if hit and not triggerDown then
            pcall(function() mouse1press() end); triggerDown = true
        elseif not hit and triggerDown then
            pcall(function() mouse1release() end); triggerDown = false
        end
    end)

    -- ============================================================
    -- ARRAYLIST (live player list panel, top-right)
    -- ============================================================
    local ArrayList = { Enabled = true, MaxRows = 30 }

    -- ============================================================
    -- TRACERS (2D lines from screen bottom to each enemy)
    -- ============================================================
    local Tracers = { Enabled = true }

    -- ============================================================
    -- CLEAN PURPLE INTERFACE
    -- ============================================================
    local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

    local PURPLE   = Color3.fromRGB(176, 38, 255)
    local PURPLE_D = Color3.fromRGB(138, 43, 226)
    local BG_A     = Color3.fromRGB(28, 14, 48)
    local BG_B     = Color3.fromRGB(18, 9, 33)
    local CARD     = Color3.fromRGB(38, 20, 60)
    local TXT      = Color3.fromRGB(232, 222, 248)
    local SUB      = Color3.fromRGB(150, 130, 175)
    local IDLE     = Color3.fromRGB(58, 42, 79)

    local gui = Instance.new("ScreenGui")
    gui.Name = "RivalsUI"
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.DisplayOrder = 2147483647
    gui.IgnoreGuiInset = true
    pcall(function() gui.Parent = PlayerGui end)

    local main = Instance.new("Frame")
    main.Size = UDim2.new(0, 300, 0, 860)
    main.Position = UDim2.new(0.5, -150, 0.5, -430)
    main.BackgroundColor3 = BG_B
    main.BorderSizePixel = 0
    main.Active = true
    main.ClipsDescendants = true
    main.Parent = gui
    local mc = Instance.new("UICorner"); mc.CornerRadius = UDim.new(0, 14); mc.Parent = main
    local mg = Instance.new("UIGradient")
    mg.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, BG_A),
        ColorSequenceKeypoint.new(1, BG_B),
    })
    mg.Parent = main

    -- Title bar
    local title = Instance.new("TextButton")
    title.Size = UDim2.new(1, 0, 0, 50)
    title.BackgroundColor3 = PURPLE_D
    title.BorderSizePixel = 0
    title.Text = "Penith Hub"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 15
    title.AutoButtonColor = false
    title.Parent = main
    local tcor = Instance.new("UICorner"); tcor.CornerRadius = UDim.new(0, 14); tcor.Parent = title
    local tfix = Instance.new("Frame")
    tfix.Size = UDim2.new(1, 0, 0, 14)
    tfix.Position = UDim2.new(0, 0, 1, -14)
    tfix.BackgroundColor3 = PURPLE_D
    tfix.BorderSizePixel = 0
    tfix.Parent = title

    local minBtn = Instance.new("TextButton")
    minBtn.Size = UDim2.new(0, 32, 0, 32)
    minBtn.Position = UDim2.new(1, -38, 0, 9)
    minBtn.BackgroundColor3 = Color3.fromRGB(255, 80, 160)
    minBtn.Text = "-"
    minBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    minBtn.Font = Enum.Font.GothamBold
    minBtn.TextSize = 20
    minBtn.AutoButtonColor = false
    minBtn.Parent = title
    local mcor = Instance.new("UICorner"); mcor.CornerRadius = UDim.new(0, 8); mcor.Parent = minBtn

    local setBtn = Instance.new("TextButton")
    setBtn.Size = UDim2.new(0, 32, 0, 32)
    setBtn.Position = UDim2.new(1, -72, 0, 9)
    setBtn.BackgroundColor3 = Color3.fromRGB(90, 70, 140)
    setBtn.Text = "SET"
    setBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    setBtn.Font = Enum.Font.GothamBold
    setBtn.TextSize = 13
    setBtn.AutoButtonColor = false
    setBtn.Parent = title
    local sc2 = Instance.new("UICorner"); sc2.CornerRadius = UDim.new(0, 8); sc2.Parent = setBtn

    local body = Instance.new("Frame")
    body.Size = UDim2.new(1, 0, 1, -50)
    body.Position = UDim2.new(0, 0, 0, 50)
    body.BackgroundTransparency = 1
    body.Parent = main

    -- Draggable
    local dragging, dragStart, startPos
    title.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = i.Position
            startPos = main.Position
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
            local d = i.Position - dragStart
            main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X,
                startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)

    -- Card helper
    local function makeCard(parent, yPos, height, titleText)
        local card = Instance.new("Frame")
        card.Size = UDim2.new(0, 276, 0, height)
        card.Position = UDim2.new(0, 12, 0, yPos)
        card.BackgroundColor3 = CARD
        card.BorderSizePixel = 0
        card.Parent = parent
        local cc = Instance.new("UICorner"); cc.CornerRadius = UDim.new(0, 10); cc.Parent = card
        local hdr = Instance.new("TextLabel")
        hdr.Size = UDim2.new(1, -24, 0, 22)
        hdr.Position = UDim2.new(0, 12, 0, 8)
        hdr.BackgroundTransparency = 1
        hdr.Text = titleText
        hdr.TextColor3 = PURPLE
        hdr.Font = Enum.Font.GothamBold
        hdr.TextSize = 13
        hdr.TextXAlignment = Enum.TextXAlignment.Left
        hdr.Parent = card
        local line = Instance.new("Frame")
        line.Size = UDim2.new(1, -24, 0, 2)
        line.Position = UDim2.new(0, 12, 0, 32)
        line.BackgroundColor3 = PURPLE
        line.BorderSizePixel = 0
        line.Parent = card
        return card
    end

    local function makeToggle(parent, y, text, default, cb)
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, -24, 0, 36)
        row.Position = UDim2.new(0, 12, 0, y)
        row.BackgroundTransparency = 1
        row.Parent = parent

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -64, 1, 0)
        label.BackgroundTransparency = 1
        label.Text = text
        label.TextColor3 = TXT
        label.Font = Enum.Font.Gotham
        label.TextSize = 13
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = row

        local sw = Instance.new("TextButton")
        sw.Size = UDim2.new(0, 46, 0, 24)
        sw.Position = UDim2.new(1, -46, 0.5, -12)
        sw.BackgroundColor3 = IDLE
        sw.AutoButtonColor = false
        sw.Text = ""
        sw.Parent = row
        local sc = Instance.new("UICorner"); sc.CornerRadius = UDim.new(1, 0); sc.Parent = sw

        local knob = Instance.new("Frame")
        knob.Size = UDim2.new(0, 20, 0, 20)
        knob.Position = UDim2.new(0, 2, 0.5, -10)
        knob.BackgroundColor3 = Color3.fromRGB(235, 225, 250)
        knob.Parent = sw
        local kc = Instance.new("UICorner"); kc.CornerRadius = UDim.new(1, 0); kc.Parent = knob

        local state = default
        local function set(v)
            state = v
            sw.BackgroundColor3 = v and PURPLE or IDLE
            TweenService:Create(knob, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {
                Position = v and UDim2.new(0, 24, 0.5, -10) or UDim2.new(0, 2, 0.5, -10)
            }):Play()
            cb(v)
        end
        sw.MouseButton1Click:Connect(function() set(not state) end)
        set(state)
    end

    local function makeSlider(parent, y, text, min, max, default, cb)
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, -24, 0, 44)
        row.Position = UDim2.new(0, 12, 0, y)
        row.BackgroundTransparency = 1
        row.Parent = parent

        local top = Instance.new("Frame")
        top.Size = UDim2.new(1, 0, 0, 18)
        top.BackgroundTransparency = 1
        top.Parent = row

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -50, 1, 0)
        label.BackgroundTransparency = 1
        label.Text = text
        label.TextColor3 = TXT
        label.Font = Enum.Font.Gotham
        label.TextSize = 13
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = top

        local val = Instance.new("TextLabel")
        val.Size = UDim2.new(0, 50, 1, 0)
        val.Position = UDim2.new(1, -50, 0, 0)
        val.BackgroundTransparency = 1
        val.Text = tostring(default)
        val.TextColor3 = PURPLE
        val.Font = Enum.Font.GothamBold
        val.TextSize = 13
        val.TextXAlignment = Enum.TextXAlignment.Right
        val.Parent = top

        local bar = Instance.new("Frame")
        bar.Size = UDim2.new(1, 0, 0, 6)
        bar.Position = UDim2.new(0, 0, 1, -10)
        bar.BackgroundColor3 = IDLE
        bar.Parent = row
        local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(1, 0); bc.Parent = bar

        local fill = Instance.new("Frame")
        fill.Size = UDim2.new(0, 0, 1, 0)
        fill.BackgroundColor3 = PURPLE
        fill.Parent = bar
        local fc = Instance.new("UICorner"); fc.CornerRadius = UDim.new(1, 0); fc.Parent = fill

        local knob = Instance.new("Frame")
        knob.Size = UDim2.new(0, 14, 0, 14)
        knob.BackgroundColor3 = Color3.fromRGB(240, 230, 255)
        knob.Parent = bar
        local kc = Instance.new("UICorner"); kc.CornerRadius = UDim.new(1, 0); kc.Parent = knob

        local value = default
        local function setValue(v)
            value = clamp(v, min, max)
            local t = (value - min) / (max - min)
            fill.Size = UDim2.new(t, 0, 1, 0)
            knob.Position = UDim2.new(t, -7, 0.5, -7)
            val.Text = string.format("%.1f", value)
            cb(value)
        end

        local sliding
        bar.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 then
                sliding = true
                local rel = (i.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X
                setValue(min + rel * (max - min))
            end
        end)
        UserInputService.InputEnded:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 then sliding = false end
        end)
        UserInputService.InputChanged:Connect(function(i)
            if sliding and i.UserInputType == Enum.UserInputType.MouseMovement then
                local rel = (i.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X
                setValue(min + rel * (max - min))
            end
        end)
        setValue(default)
    end

    -- Two views: MAIN and SETTINGS
    local viewMain = Instance.new("Frame")
    viewMain.Size = UDim2.new(1, 0, 1, 0)
    viewMain.BackgroundTransparency = 1
    viewMain.Parent = body
    local viewSettings = Instance.new("Frame")
    viewSettings.Size = UDim2.new(1, 0, 1, 0)
    viewSettings.BackgroundTransparency = 1
    viewSettings.Visible = false
    viewSettings.Parent = body

    local listening, bindButtons = nil, {}

    -- MAIN view
    local esp = makeCard(viewMain, 10, 268, "VISUAL  -  HITBOX ESP")
    makeToggle(esp, 44, "Show Boxes", true, function(v) Hitboxes:SetEnabled(v) end)
    makeToggle(esp, 86, "Team Check", false, function(v)
        Hitboxes.Config.TeamCheck = v; Hitboxes:Refresh(); Aimbot.TeamCheck = v
    end)
    makeToggle(esp, 128, "Tracers", true, function(v) Tracers.Enabled = v end)
    makeSlider(esp, 170, "Box Size", 1, 5, 1.6, function(v) Hitboxes.Config.Size = v; Hitboxes:Refresh() end)
    makeToggle(esp, 218, "ArrayList", true, function(v) ArrayList.Enabled = v end)

    local mv = makeCard(viewMain, 246, 130, "MOVEMENT  -  FLY / SPEED")
    makeToggle(mv, 44, "Fly", false, function(v) setFly(v) end)
    makeToggle(mv, 86, "Speed", false, function(v) setSpeed(v) end)

    local aim = makeCard(viewMain, 386, 276, "COMBAT  -  AIMBOT")
    makeToggle(aim, 44, "Enabled", false, function(v) Aimbot.Enabled = v end)
    makeToggle(aim, 86, "Hold RMB", true, function(v) Aimbot.HoldToAim = v end)
    makeToggle(aim, 128, "Aim Head", true, function(v) Aimbot.AimHead = v end)
    makeSlider(aim, 172, "FOV", 30, 400, 250, function(v) Aimbot.FOV = v end)
    makeSlider(aim, 222, "Smoothness", 0.05, 1, 0.35, function(v) Aimbot.Speed = v end)

    local trig = makeCard(viewMain, 672, 130, "COMBAT  -  TRIGGERBOT")
    makeToggle(trig, 44, "Enabled", false, function(v) Triggerbot.Enabled = v end)

    -- SETTINGS view
    local function makeBind(parent, y, text, key)
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, -24, 0, 36)
        row.Position = UDim2.new(0, 12, 0, y)
        row.BackgroundTransparency = 1
        row.Parent = parent
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -80, 1, 0)
        label.BackgroundTransparency = 1
        label.Text = text
        label.TextColor3 = TXT
        label.Font = Enum.Font.Gotham
        label.TextSize = 13
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = row
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 76, 0, 28)
        btn.Position = UDim2.new(1, -76, 0.5, -14)
        btn.BackgroundColor3 = IDLE
        btn.AutoButtonColor = false
        btn.Text = Binds[key]
        btn.TextColor3 = Color3.fromRGB(240, 230, 255)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 12
        btn.Parent = row
        local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0, 8); bc.Parent = btn
        btn.MouseButton1Click:Connect(function()
            listening = key
            btn.Text = "..."
        end)
        bindButtons[key] = btn
    end

    local kb = makeCard(viewSettings, 10, 212, "SETTINGS  -  KEYBINDS")
    makeBind(kb, 44, "Menu (show/hide)", "Menu")
    makeBind(kb, 84, "Aimbot", "Aimbot")
    makeBind(kb, 124, "Fly", "Fly")
    makeBind(kb, 164, "Speed", "Speed")

    local mvset = makeCard(viewSettings, 234, 150, "SETTINGS  -  MOVEMENT")
    makeSlider(mvset, 44, "Fly Speed", 10, 150, 50, function(v) Fly.Speed = v end)
    makeSlider(mvset, 96, "Walk Speed", 16, 100, 32, function(v) Speed.Value = v end)

    local hint = Instance.new("TextLabel")
    hint.Size = UDim2.new(1, -24, 0, 22)
    hint.Position = UDim2.new(0, 12, 1, -30)
    hint.BackgroundTransparency = 1
    hint.Text = "click a key, then press a new one"
    hint.TextColor3 = SUB
    hint.Font = Enum.Font.Gotham
    hint.TextSize = 11
    hint.Parent = viewSettings

    -- Settings toggle
    local inSettings = false
    setBtn.MouseButton1Click:Connect(function()
        inSettings = not inSettings
        viewSettings.Visible = inSettings
        viewMain.Visible = not inSettings
        setBtn.Text = inSettings and "BACK" or "SET"
    end)

    local foot = Instance.new("TextLabel")
    foot.Size = UDim2.new(1, 0, 0, 22)
    foot.Position = UDim2.new(0, 0, 1, -22)
    foot.BackgroundTransparency = 1
    foot.Text = "press  P  to hide / show"
    foot.TextColor3 = SUB
    foot.Font = Enum.Font.Gotham
    foot.TextSize = 11
    foot.Parent = main

    -- ============================================================
    -- ARRAYLIST PANEL
    -- ============================================================
    local arrayGui = Instance.new("ScreenGui")
    arrayGui.Name = "RivalsArrayList"
    arrayGui.ResetOnSpawn = false
    arrayGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    arrayGui.DisplayOrder = 2147483646
    arrayGui.IgnoreGuiInset = true
    pcall(function() arrayGui.Parent = PlayerGui end)

    local arrayFrame = Instance.new("Frame")
    arrayFrame.Size = UDim2.new(0, 210, 0, 40)
    arrayFrame.Position = UDim2.new(1, -220, 0, 10)
    arrayFrame.BackgroundColor3 = CARD
    arrayFrame.BorderSizePixel = 0
    arrayFrame.ClipsDescendants = true
    arrayFrame.Parent = arrayGui
    local ac = Instance.new("UICorner"); ac.CornerRadius = UDim.new(0, 10); ac.Parent = arrayFrame

    local aHdr = Instance.new("TextLabel")
    aHdr.Size = UDim2.new(1, -16, 0, 26)
    aHdr.Position = UDim2.new(0, 8, 0, 6)
    aHdr.BackgroundTransparency = 1
    aHdr.Text = "PLAYERS"
    aHdr.TextColor3 = PURPLE
    aHdr.Font = Enum.Font.GothamBold
    aHdr.TextSize = 13
    aHdr.TextXAlignment = Enum.TextXAlignment.Left
    aHdr.Parent = arrayFrame

    local arrayRows = {}
    local function ensureRows(n)
        while #arrayRows < n do
            local i = #arrayRows + 1
            local row = Instance.new("Frame")
            row.Size = UDim2.new(1, -16, 0, 22)
            row.Position = UDim2.new(0, 8, 0, 38 + (i - 1) * 24)
            row.BackgroundTransparency = 1
            row.Parent = arrayFrame
            local dot = Instance.new("Frame")
            dot.Size = UDim2.new(0, 10, 0, 10)
            dot.Position = UDim2.new(0, 0, 0.5, -5)
            dot.BackgroundColor3 = PURPLE
            dot.BorderSizePixel = 0
            dot.Parent = row
            local dc = Instance.new("UICorner"); dc.CornerRadius = UDim.new(1, 0); dc.Parent = dot
            local nm = Instance.new("TextLabel")
            nm.Size = UDim2.new(1, -18, 1, 0)
            nm.Position = UDim2.new(0, 16, 0, 0)
            nm.BackgroundTransparency = 1
            nm.Text = ""
            nm.TextColor3 = TXT
            nm.Font = Enum.Font.Gotham
            nm.TextSize = 12
            nm.TextXAlignment = Enum.TextXAlignment.Left
            nm.Parent = row
            arrayRows[i] = { row = row, dot = dot, nm = nm }
        end
    end

    local ArrayListModules = {
        { "Hitbox ESP", function() return Hitboxes.Config.Enabled end },
        { "Team Check", function() return Hitboxes.Config.TeamCheck end },
        { "Tracers",    function() return Tracers.Enabled end },
        { "Fly",        function() return Fly.Enabled end },
        { "Speed",      function() return Speed.Enabled end },
        { "Aimbot",     function() return Aimbot.Enabled end },
        { "Triggerbot", function() return Triggerbot.Enabled end },
    }
    local modHdr = Instance.new("TextLabel")
    modHdr.Size = UDim2.new(1, -16, 0, 22)
    modHdr.Position = UDim2.new(0, 8, 0, 40)
    modHdr.BackgroundTransparency = 1
    modHdr.Text = "MODULES"
    modHdr.TextColor3 = PURPLE
    modHdr.Font = Enum.Font.GothamBold
    modHdr.TextSize = 13
    modHdr.TextXAlignment = Enum.TextXAlignment.Left
    modHdr.Parent = arrayFrame
    local modRows = {}
    for i, m in ipairs(ArrayListModules) do
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, -16, 0, 22)
        row.BackgroundTransparency = 1
        row.Parent = arrayFrame
        local dot = Instance.new("Frame")
        dot.Size = UDim2.new(0, 10, 0, 10)
        dot.Position = UDim2.new(0, 0, 0.5, -5)
        dot.BackgroundColor3 = IDLE
        dot.BorderSizePixel = 0
        dot.Parent = row
        local dc = Instance.new("UICorner"); dc.CornerRadius = UDim.new(1, 0); dc.Parent = dot
        local nm = Instance.new("TextLabel")
        nm.Size = UDim2.new(1, -18, 1, 0)
        nm.Position = UDim2.new(0, 16, 0, 0)
        nm.BackgroundTransparency = 1
        nm.Text = m[1]
        nm.TextColor3 = SUB
        nm.Font = Enum.Font.Gotham
        nm.TextSize = 12
        nm.TextXAlignment = Enum.TextXAlignment.Left
        nm.Parent = row
        modRows[i] = { row = row, dot = dot, nm = nm, get = m[2] }
    end

    local arrayT = 0
    RunService.RenderStepped:Connect(function(dt)
        if not ArrayList.Enabled then arrayGui.Enabled = false; return end
        arrayGui.Enabled = true
        arrayT = arrayT + dt
        if arrayT < 0.25 then return end
        arrayT = 0
        local lp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        local list = {}
        for _, pl in ipairs(Players:GetPlayers()) do
            if pl ~= LocalPlayer and pl.Character and pl.Character:FindFirstChild("HumanoidRootPart") then
                local root = pl.Character.HumanoidRootPart
                local dist = lp and (root.Position - lp.Position).Magnitude or 0
                local enemy = not (Aimbot.TeamCheck and pl.Team and LocalPlayer.Team and pl.Team == LocalPlayer.Team)
                table.insert(list, { pl = pl, dist = dist, enemy = enemy })
            end
        end
        table.sort(list, function(a, b) return a.dist < b.dist end)
        local shown = math.min(#list, ArrayList.MaxRows)
        ensureRows(shown)
        for i = 1, #arrayRows do
            local r = arrayRows[i]
            if i <= shown then
                local e = list[i]
                r.row.Visible = true
                r.nm.Text = e.pl.Name .. "  [" .. math.floor(e.dist) .. "m]"
                if e.enemy then
                    r.nm.TextColor3 = PURPLE
                    r.dot.BackgroundColor3 = PURPLE
                else
                    r.nm.TextColor3 = Color3.fromRGB(120, 200, 120)
                    r.dot.BackgroundColor3 = Color3.fromRGB(120, 200, 120)
                end
            else
                r.row.Visible = false
            end
        end
        local y = 38 + shown * 24 + 6
        modHdr.Position = UDim2.new(0, 8, 0, y)
        y = y + 24
        for _, mr in ipairs(modRows) do
            mr.row.Position = UDim2.new(0, 8, 0, y)
            y = y + 22
            local on = mr.get()
            if on then
                mr.nm.TextColor3 = PURPLE
                mr.dot.BackgroundColor3 = PURPLE
            else
                mr.nm.TextColor3 = SUB
                mr.dot.BackgroundColor3 = IDLE
            end
        end
        arrayFrame.Size = UDim2.new(0, 210, 0, y + 6)
    end)

    -- ============================================================
    -- TRACERS (2D lines from bottom-center to each on-screen enemy)
    -- ============================================================
    local tracerLines = {}
    local DrawingLib
    pcall(function()
        if (typeof(Drawing) == "table" or typeof(Drawing) == "userdata") and typeof(Drawing.new) == "function" then
            DrawingLib = Drawing
        end
    end)
    local function removeTracer(p)
        local l = tracerLines[p]
        if l then
            pcall(function() if l.Remove then l:Remove() else if DrawingLib and DrawingLib.clear then DrawingLib:clear() end end end)
            tracerLines[p] = nil
        end
    end
    Players.PlayerRemoving:Connect(removeTracer)
    RunService.RenderStepped:Connect(function()
        if not Tracers.Enabled or not DrawingLib then
            for _, l in pairs(tracerLines) do pcall(function() l.Visible = false end) end
            return
        end
        pcall(function()
            local cam = workspace.CurrentCamera
            if not cam then return end
            local vs = cam.ViewportSize
            local from = Vector2.new(vs.X / 2, vs.Y)
            for _, pl in ipairs(Players:GetPlayers()) do
                if pl ~= LocalPlayer then
                    local enemy = not (Aimbot.TeamCheck and pl.Team and LocalPlayer.Team and pl.Team == LocalPlayer.Team)
                    local char = pl.Character
                    local part = char and (char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart"))
                    local l = tracerLines[pl]
                    if part then
                        local sp, vis = cam:WorldToViewportPoint(part.Position)
                        if vis and sp.X >= 0 and sp.X <= vs.X and sp.Y >= 0 and sp.Y <= vs.Y then
                            if not l then
                                l = DrawingLib.new("Line")
                                l.Thickness = 1.5
                                l.Transparency = 1
                                tracerLines[pl] = l
                            end
                            l.Visible = true
                            l.Color = enemy and Color3.fromRGB(170, 0, 255) or Color3.fromRGB(120, 200, 120)
                            l.From = from
                            l.To = Vector2.new(sp.X, sp.Y)
                        elseif l then
                            l.Visible = false
                        end
                    elseif l then
                        l.Visible = false
                    end
                end
            end
        end)
    end)

    local minimized = false
    minBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        TweenService:Create(main, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
            Size = minimized and UDim2.new(0, 300, 0, 50) or UDim2.new(0, 300, 0, 860)
        }):Play()
        minBtn.Text = minimized and "+" or "-"
    end)

    local function matchBind(bindName, i)
        if bindName == "MouseButton1" or bindName == "MouseButton2" or bindName == "MouseButton3" then
            local map = { MouseButton1 = Enum.UserInputType.MouseButton1,
                MouseButton2 = Enum.UserInputType.MouseButton2,
                MouseButton3 = Enum.UserInputType.MouseButton3 }
            return i.UserInputType == map[bindName]
        end
        return i.KeyCode.Name == bindName
    end

    UserInputService.InputBegan:Connect(function(i, gp)
        if listening then
            if i.KeyCode == Enum.KeyCode.Escape then
                if bindButtons[listening] then bindButtons[listening].Text = Binds[listening] end
                listening = nil
                return
            end
            local nm
            if i.UserInputType == Enum.UserInputType.MouseButton2 then nm = "MouseButton2"
            elseif i.UserInputType == Enum.UserInputType.MouseButton3 then nm = "MouseButton3"
            elseif i.KeyCode and i.KeyCode ~= Enum.KeyCode.Unknown then nm = i.KeyCode.Name
            else nm = nil end
            if nm and nm ~= "MouseButton1" then
                Binds[listening] = nm
                if bindButtons[listening] then bindButtons[listening].Text = nm end
                listening = nil
            end
            return
        end
        if matchBind(Binds.Aimbot, i) then aiming = true; return end
        if gp and (i.UserInputType == Enum.UserInputType.MouseButton1
                or i.UserInputType == Enum.UserInputType.MouseButton2
                or i.UserInputType == Enum.UserInputType.MouseButton3) then
            return
        end
        if matchBind(Binds.Menu, i) then gui.Enabled = not gui.Enabled; return end
        if matchBind(Binds.Fly, i) then setFly(not Fly.Enabled); return end
        if matchBind(Binds.Speed, i) then setSpeed(not Speed.Enabled); return end
    end)
    UserInputService.InputEnded:Connect(function(i, gp)
        if matchBind(Binds.Aimbot, i) then aiming = false end
    end)
end

xpcall(RUN, showError)
