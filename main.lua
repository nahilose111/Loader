local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local Stats = game:GetService("Stats")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Drawing = Drawing

if not Drawing then warn("[RSilent] Missing Drawing API"); return end
if not LocalPlayer then warn("[RSilent] Not in-game"); return end

local CONFIG_FOLDER = "RSilent_Configs"
pcall(function() if makefolder then makefolder(CONFIG_FOLDER) end end)
_G.RSilentSavedConfigs = _G.RSilentSavedConfigs or {}

local function gui_parent()
    local ok, cg = pcall(function() return game:GetService("CoreGui") end)
    if ok and cg then return cg end
    return LocalPlayer:WaitForChild("PlayerGui")
end

local old = gui_parent():FindFirstChild("RSilent_UI")
if old then old:Destroy() end
if _G.RSilentCleanup then pcall(_G.RSilentCleanup) end
if _G.RSilentDrawings then
    for _, d in pairs(_G.RSilentDrawings) do pcall(function() d:Remove() end) end
end
_G.RSilentDrawings = {}

local ScriptConnections = {}
local function trackConn(conn)
    table.insert(ScriptConnections, conn)
    return conn
end

local function unloadScript()
    if _G.RSilentCleanup then
        local fn = _G.RSilentCleanup
        _G.RSilentCleanup = nil
        pcall(fn)
    end
end

local function makeDrawing(kind)
    local d = Drawing.new(kind)
    table.insert(_G.RSilentDrawings, d)
    return d
end

local U = {
    BG        = Color3.fromRGB(9, 12, 19),
    BG_GLASS  = Color3.fromRGB(13, 17, 27),
    SIDEBAR   = Color3.fromRGB(12, 16, 25),
    CARD      = Color3.fromRGB(17, 23, 35),
    CARD2     = Color3.fromRGB(22, 29, 44),
    CARD_HOV  = Color3.fromRGB(28, 38, 58),
    BORDER    = Color3.fromRGB(30, 42, 64),
    BORDER_HI = Color3.fromRGB(60, 90, 138),
    ACCENT    = Color3.fromRGB(56, 130, 255),
    ACCENT_H  = Color3.fromRGB(85, 155, 255),
    TEXT      = Color3.fromRGB(230, 238, 248),
    TEXT_DIM  = Color3.fromRGB(140, 152, 172),
    TEXT_MUTE = Color3.fromRGB(85, 96, 116),
    GOOD      = Color3.fromRGB(50, 225, 120),
    BAD       = Color3.fromRGB(235, 65, 65),
    AMBER     = Color3.fromRGB(245, 175, 45),
    RISKY     = Color3.fromRGB(255, 190, 45),
    SHEEN     = Color3.fromRGB(255, 255, 255),
}

local Config = {
    Combat = {
        AimLine = true,
    },
    UI = {
        ToggleKey = Enum.KeyCode.RightControl,
        AccentColor = Color3.fromRGB(56, 130, 255),
        WindowTransparency = 0.12,
        ShowMetrics = true,
    },
    SilentAim = {
        Enabled = false, TargetPart = "Head",
        HitChance = 100, FOV = 150, ShowFOV = true,
        FOVColor = Color3.fromRGB(56, 130, 255),
        WallCheck = true, TeamCheck = false,
    },
    Aimbot = {
        Enabled = false, TargetPart = "Head",
        FOV = 130, ShowFOV = true,
        FOVColor = Color3.fromRGB(255, 190, 45),
        Smoothness = 5, Prediction = 12,
        WallCheck = true, TeamCheck = true,
    },
    AimMagnet = {
        Enabled = false,
        Distance = 6, TriggerFOV = 320, MaxRange = 500,
        TeamCheck = true, NoWallCheck = true,
        ShowBox = true, BoxColor = Color3.fromRGB(255, 60, 60),
        ShowLabel = true, LabelColor = Color3.fromRGB(255, 200, 200),
        ShowHighlight = true, HighlightColor = Color3.fromRGB(56, 130, 255),
        Anchor = false, HoldLMB = true,
    },
    ESP = {
        Enabled = false,
        Style = "Style 1", -- "Style 1" (Classic) or "Style 2" (Banner Card)
        ShowWatermark = true,
        ShowEspCount = true,
        ShowAimWarning = true,
        Boxes = false, BoxType = "Full Box", BoxThickness = 1.4,
        BoxFill = false, BoxFillColor = Color3.fromRGB(56, 130, 255), BoxFillTransparency = 0.75,
        Names = false, NameColor = Color3.fromRGB(225, 232, 242), NameSize = 11,
        Distance = false, DistanceColor = Color3.fromRGB(180, 190, 205), DistanceSize = 10,
        HealthBar = false, HealthText = false,
        Skeleton = false, SkeletonColor = Color3.fromRGB(200, 210, 225),
        Tracers = false, TracerOrigin = "Bottom",
        OffscreenArrows = false, ArrowSize = 18,
        WeaponInfo = false,
        Range = 2000, TeamCheck = false, TeamColors = false,
        WallCheck = false,
        EspPosX = 0, EspPosY = 0, DrawPosX = 0, DrawPosY = 0,
    },
    Chams = {
        Enabled = false,
        VisibleFill = Color3.fromRGB(50, 225, 120),
        InvisibleFill = Color3.fromRGB(235, 65, 65),
        FillTransparency = 0.5,
        WallCheck = true,
        TeamCheck = true,
    },
    Radar = {
        Enabled = false, Shape = "Square",
        Size = 200, Range = 250, PosX = 20, PosY = 60,
        BgColor = Color3.fromRGB(10, 13, 20), BgAlpha = 0.75,
        BorderColor = Color3.fromRGB(56, 130, 255),
        BlipColor = Color3.fromRGB(255, 60, 60), BlipSize = 4,
        SelfColor = Color3.fromRGB(50, 225, 120),
        ShowSelf = true, ShowBlips = true, ShowCone = true,
        ShowRings = true, ShowCompass = true, ShowRangeText = true,
        ShowDistanceText = true, FadeEdge = true, TeamColors = true,
        Rotate = true,
    },
}

-- ═══════════════════════════════════════════════════════════
-- CONFIG SERIALIZATION
-- ═══════════════════════════════════════════════════════════
local function isColor(v)
    local ok, t = pcall(function() return typeof(v) end)
    return ok and t == "Color3"
end

local function serializeConfig(cfg)
    local out = {}
    for section, values in pairs(cfg) do
        out[section] = {}
        for k, v in pairs(values) do
            if isColor(v) then
                out[section][k] = {_c = true, r = v.R, g = v.G, b = v.B}
            else
                out[section][k] = v
            end
        end
    end
    return out
end

local function applySerialized(data)
    if type(data) ~= "table" then return false end
    for section, values in pairs(data) do
        if Config[section] and type(values) == "table" then
            for k, v in pairs(values) do
                if type(v) == "table" and v._c then
                    Config[section][k] = Color3.new(v.r, v.g, v.b)
                else
                    Config[section][k] = v
                end
            end
        end
    end
    return true
end

local function listConfigs()
    local out = {}
    if listfiles then
        local ok, files = pcall(listfiles, CONFIG_FOLDER)
        if ok and files then
            for _, f in ipairs(files) do
                local name = tostring(f):match("([^/\\]+)%.json$")
                if name then table.insert(out, name) end
            end
        end
    end
    for k in pairs(_G.RSilentSavedConfigs) do
        local found = false
        for _, n in ipairs(out) do if n == k then found = true; break end end
        if not found then table.insert(out, k) end
    end
    table.sort(out)
    return out
end

local function saveConfigToDisk(name)
    if not name or name == "" then return false end
    local data = serializeConfig(Config)
    local encoded
    local ok = pcall(function() encoded = HttpService:JSONEncode(data) end)
    if not ok then return false end
    _G.RSilentSavedConfigs[name] = encoded
    if writefile then
        pcall(writefile, CONFIG_FOLDER .. "/" .. name .. ".json", encoded)
    end
    return true
end

local function loadConfigFromDisk(name)
    if not name or name == "" then return false end
    local content
    if isfile then
        local ok = pcall(function()
            if isfile(CONFIG_FOLDER .. "/" .. name .. ".json") then
                content = readfile(CONFIG_FOLDER .. "/" .. name .. ".json")
            end
        end)
    end
    if not content and _G.RSilentSavedConfigs[name] then
        content = _G.RSilentSavedConfigs[name]
    end
    if not content then return false end
    local ok, data = pcall(function() return HttpService:JSONDecode(content) end)
    if not ok or type(data) ~= "table" then return false end
    return applySerialized(data)
end

local function deleteConfigFromDisk(name)
    if not name or name == "" then return false end
    if delfile then
        pcall(delfile, CONFIG_FOLDER .. "/" .. name .. ".json")
    end
    _G.RSilentSavedConfigs[name] = nil
    return true
end

-- ═══════════════════════════════════════════════════════════
-- SILENT AIM CORE
-- ═══════════════════════════════════════════════════════════
local isInternalRaycast = false
local CurrentSilentTarget = nil
local lastSilentCheck = 0
local lastSilentRoll = 0
local silentRollOk = true

local function isEnemyForSilent(p)
    if Config.SilentAim.TeamCheck and LocalPlayer.Team and p.Team then
        return p.Team ~= LocalPlayer.Team
    end
    return true
end

local function isPositionVisible(origin, targetPos, targetChar)
    local dir = targetPos - origin
    if dir.Magnitude < 0.1 then return true end
    local filterList = { Camera }
    if LocalPlayer.Character then table.insert(filterList, LocalPlayer.Character) end
    if targetChar then table.insert(filterList, targetChar) end
    local params = RaycastParams.new()
    params.FilterDescendantsInstances = filterList
    pcall(function() params.FilterType = Enum.RaycastFilterType.Exclude end)
    params.IgnoreWater = true
    local curOrigin, curDir = origin, dir
    isInternalRaycast = true
    local isVis = false
    for _ = 1, 4 do
        if curDir.Magnitude <= 0.1 then isVis = true; break end
        local res = workspace:Raycast(curOrigin, curDir, params)
        if not res then isVis = true; break end
        local hit = res.Instance
        if not hit then isVis = true; break end
        if targetChar and (hit:IsDescendantOf(targetChar) or hit == targetChar) then isVis = true; break end
        if (not hit.CanCollide) or hit.Transparency >= 0.7 or hit:IsA("Accessory") or hit:IsA("Tool") then
            table.insert(filterList, hit)
            params.FilterDescendantsInstances = filterList
            curOrigin = res.Position + dir.Unit * 0.15
            curDir = targetPos - curOrigin
        else isVis = false; break end
    end
    isInternalRaycast = false
    return isVis
end

local function updateSilentAimTarget()
    if not Config.SilentAim.Enabled then
        CurrentSilentTarget = nil
        return nil
    end
    local now = os.clock()
    if now - lastSilentCheck < 0.033 then return CurrentSilentTarget end
    lastSilentCheck = now
    if now - lastSilentRoll > 1.0 then
        lastSilentRoll = now
        silentRollOk = (math.random(1, 100) <= Config.SilentAim.HitChance)
    end
    if not silentRollOk then CurrentSilentTarget = nil; return nil end

    local mousePos = UserInputService:GetMouseLocation()
    local bestPart, bestDist, bestChar = nil, Config.SilentAim.FOV, nil
    local camPos = Camera.CFrame.Position

    for _, p in ipairs(Players:GetPlayers()) do
        if p == LocalPlayer then continue end
        local char = p.Character
        if not char then continue end
        if not isEnemyForSilent(p) then continue end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then continue end
        local chosenPart
        if Config.SilentAim.TargetPart == "Random" then
            local cands = {"Head","UpperTorso","HumanoidRootPart","Torso"}
            for _, b in ipairs(cands) do local pt = char:FindFirstChild(b); if pt then chosenPart = pt; break end end
        else
            chosenPart = char:FindFirstChild(Config.SilentAim.TargetPart)
        end
        if not chosenPart then chosenPart = char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart") end
        if not chosenPart then continue end
        local sp, onScreen = Camera:WorldToViewportPoint(chosenPart.Position)
        if not onScreen then continue end
        local dist = (Vector2.new(sp.X, sp.Y) - mousePos).Magnitude
        if dist <= bestDist then
            local canHit = true
            if Config.SilentAim.WallCheck then
                canHit = isPositionVisible(camPos, chosenPart.Position, char)
            end
            if canHit then bestDist = dist; bestPart = chosenPart; bestChar = char end
        end
    end
    CurrentSilentTarget = bestPart
    return bestPart
end

pcall(function()
    local hook_fn = hookmetamethod or hookfunction
    local check_caller = checkcaller or function() return false end
    local get_namecall = getnamecallmethod or get_namecall_method
    if not hook_fn then return end
    local oldNamecall
    oldNamecall = hook_fn(game, "__namecall", newcclosure(function(self, ...)
        if isInternalRaycast then return oldNamecall(self, ...) end
        local method = get_namecall()
        if (method == "Raycast" or method == "raycast") and (self == workspace or self == game:GetService("Workspace")) then
            if check_caller() then return oldNamecall(self, ...) end
            local args = {...}
            local origin, origDir = args[1], args[2]
            if typeof(origin) ~= "Vector3" or typeof(origDir) ~= "Vector3" then
                return oldNamecall(self, ...)
            end
            if not Config.SilentAim.Enabled or not CurrentSilentTarget or not CurrentSilentTarget.Parent then
                return oldNamecall(self, ...)
            end
            args[2] = (CurrentSilentTarget.Position - origin).Unit * origDir.Magnitude
            return oldNamecall(self, unpack(args))
        end
        return oldNamecall(self, ...)
    end))
end)

-- ═══════════════════════════════════════════════════════════
-- HARDWARE / MOUSEMOVEMENT AIMBOT
-- ═══════════════════════════════════════════════════════════
local HoldingAimbotKey = false
local CurrentAimbotTarget = nil

local function moveMouseRel(dx, dy)
    pcall(function()
        if mousemoverel then
            mousemoverel(dx, dy)
        elseif mouse_moverel then
            mouse_moverel(dx, dy)
        elseif Input and Input.MouseMove then
            Input.MouseMove(dx, dy)
        end
    end)
end

trackConn(UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        HoldingAimbotKey = true
    end
end))

trackConn(UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        HoldingAimbotKey = false
        CurrentAimbotTarget = nil
    end
end))

local function isEnemyForAimbot(p)
    if Config.Aimbot.TeamCheck and LocalPlayer.Team and p.Team then
        return p.Team ~= LocalPlayer.Team
    end
    return true
end

local function updateAimbot(dt)
    if not Config.Aimbot.Enabled or not HoldingAimbotKey then
        CurrentAimbotTarget = nil
        return
    end

    local mousePos = UserInputService:GetMouseLocation()
    local bestPart = nil
    local bestDist = Config.Aimbot.FOV
    local camPos = Camera.CFrame.Position

    for _, p in ipairs(Players:GetPlayers()) do
        if p == LocalPlayer then continue end
        local char = p.Character
        if not char then continue end
        if not isEnemyForAimbot(p) then continue end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then continue end
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then continue end

        local chosenPart = nil
        if Config.Aimbot.TargetPart == "Random" then
            chosenPart = char:FindFirstChild("Head") or root
        else
            chosenPart = char:FindFirstChild(Config.Aimbot.TargetPart) or char:FindFirstChild("Head") or root
        end
        if not chosenPart then continue end

        local targetPos = chosenPart.Position
        if Config.Aimbot.Prediction and Config.Aimbot.Prediction > 0 then
            local vel = root.AssemblyLinearVelocity or root.Velocity or Vector3.zero
            targetPos = targetPos + vel * (Config.Aimbot.Prediction / 100)
        end

        local sp, onScreen = Camera:WorldToViewportPoint(targetPos)
        if not onScreen then continue end

        local dist = (Vector2.new(sp.X, sp.Y) - mousePos).Magnitude
        if dist <= bestDist then
            local canHit = true
            if Config.Aimbot.WallCheck then
                canHit = isPositionVisible(camPos, chosenPart.Position, char)
            end
            if canHit then
                bestDist = dist
                bestPart = chosenPart
            end
        end
    end

    CurrentAimbotTarget = bestPart
    if bestPart then
        local root = bestPart.Parent and bestPart.Parent:FindFirstChild("HumanoidRootPart")
        local targetPos = bestPart.Position
        if Config.Aimbot.Prediction and Config.Aimbot.Prediction > 0 and root then
            local vel = root.AssemblyLinearVelocity or root.Velocity or Vector3.zero
            targetPos = targetPos + vel * (Config.Aimbot.Prediction / 100)
        end
        local sp, onScreen = Camera:WorldToViewportPoint(targetPos)
        if onScreen then
            local deltaX = sp.X - mousePos.X
            local deltaY = sp.Y - mousePos.Y
            local smooth = math.max(1, Config.Aimbot.Smoothness or 5)
            moveMouseRel(deltaX / smooth, deltaY / smooth)
        end
    end
end

-- ═══════════════════════════════════════════════════════════
-- AIM MAGNET
-- ═══════════════════════════════════════════════════════════
local HoldingLMB = false
local PullTarget = nil
local PullState = nil

trackConn(UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 then HoldingLMB = true end
end))
trackConn(UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then HoldingLMB = false end
end))

local function cleanupPullState()
    if not PullState then return end
    if PullState.hrp and PullState.hrp.Parent then
        pcall(function()
            PullState.hrp.Anchored = PullState.originalAnchored or false
            PullState.hrp.AssemblyLinearVelocity = Vector3.zero
            PullState.hrp.AssemblyAngularVelocity = Vector3.zero
        end)
    end
    if PullState.highlight then pcall(function() PullState.highlight:Destroy() end) end
    if PullState.box then pcall(function() PullState.box.Visible = false end) end
    if PullState.label then pcall(function() PullState.label.Visible = false end) end
    PullState = nil; PullTarget = nil
end

local function findPullTarget()
    local camPos = Camera.CFrame.Position
    local vp = Camera.ViewportSize
    local center = Vector2.new(vp.X/2, vp.Y/2)
    local best, bestScore = nil, math.huge
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr == LocalPlayer then continue end
        local char = plr.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not (char and hum and root and hum.Health > 0) then continue end
        if Config.AimMagnet.TeamCheck and plr.Team and LocalPlayer.Team and plr.Team == LocalPlayer.Team then continue end
        local dist = (root.Position - camPos).Magnitude
        if dist > Config.AimMagnet.MaxRange then continue end
        local sp, onScreen = Camera:WorldToViewportPoint(root.Position)
        if not onScreen then continue end
        local dCenter = (Vector2.new(sp.X, sp.Y) - center).Magnitude
        if dCenter > Config.AimMagnet.TriggerFOV then continue end
        if not Config.AimMagnet.NoWallCheck then
            if not isPositionVisible(camPos, root.Position, char) then continue end
        end
        if dCenter < bestScore then
            bestScore = dCenter
            best = {plr = plr, char = char, hum = hum, root = root, dist = dist}
        end
    end
    return best
end

local function initPull(target)
    local root = target.root
    local st = {
        hrp = root, char = target.char, originalAnchored = root.Anchored,
        box = makeDrawing("Square"), label = makeDrawing("Text"), highlight = nil,
    }
    st.box.Thickness = 1.4; st.box.Filled = false
    st.box.Color = Config.AimMagnet.BoxColor; st.box.Visible = false
    st.label.Size = 12; st.label.Center = true; st.label.Outline = true
    st.label.Color = Config.AimMagnet.LabelColor; st.label.Visible = false
    if Config.AimMagnet.ShowHighlight then
        local h = Instance.new("Highlight")
        h.Parent = target.char
        h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        h.FillColor = Config.AimMagnet.HighlightColor
        h.OutlineColor = Config.AimMagnet.HighlightColor
        h.FillTransparency = 0.7; h.OutlineTransparency = 0
        st.highlight = h
    end
    PullTarget = target.plr; PullState = st
end

local function updateAimPull()
    if not Config.AimMagnet.Enabled then
        if PullState then cleanupPullState() end
        return
    end
    local wantPull = (not Config.AimMagnet.HoldLMB) or HoldingLMB
    if not wantPull then
        if PullState then cleanupPullState() end
        return
    end
    if PullTarget then
        local char = PullTarget.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local camPos = Camera.CFrame.Position
        local invalid = false
        if not (char and hum and hum.Health > 0 and root and root.Parent) then invalid = true
        elseif Config.AimMagnet.TeamCheck and PullTarget.Team and LocalPlayer.Team and PullTarget.Team == LocalPlayer.Team then invalid = true
        elseif (root.Position - camPos).Magnitude > Config.AimMagnet.MaxRange * 1.5 then invalid = true end
        if invalid then cleanupPullState() end
    end
    if not PullTarget then
        local t = findPullTarget()
        if t then initPull(t) end
    end
    if not PullTarget or not PullState then return end
    local camPos = Camera.CFrame.Position
    local targetPos = camPos + Camera.CFrame.LookVector * Config.AimMagnet.Distance
    local targetCF = CFrame.new(targetPos, camPos)
    local root = PullState.hrp
    if not (root and root.Parent) then cleanupPullState(); return end
    pcall(function()
        if Config.AimMagnet.Anchor and not root.Anchored then root.Anchored = true end
        root.CFrame = targetCF
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
        local vel = root:FindFirstChild("Velocity")
        if vel then vel.Velocity = Vector3.zero end
    end)
    local char = PullState.char
    local head = char and char:FindFirstChild("Head")
    if head and root then
        local top0, ok1 = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.4, 0))
        local bot0, ok2 = Camera:WorldToViewportPoint(root.Position - Vector3.new(0, 1.5, 0))
        if ok1 and ok2 then
            local bh = math.abs(bot0.Y - top0.Y); local bw = bh * 0.55
            PullState.box.Position = Vector2.new(top0.X - bw/2, top0.Y)
            PullState.box.Size = Vector2.new(bw, bh)
            PullState.box.Color = Config.AimMagnet.BoxColor
            PullState.box.Visible = Config.AimMagnet.ShowBox
            PullState.label.Text = PullTarget.Name
            PullState.label.Position = Vector2.new(top0.X, top0.Y - 16)
            PullState.label.Color = Config.AimMagnet.LabelColor
            PullState.label.Visible = Config.AimMagnet.ShowLabel
        else
            PullState.box.Visible = false; PullState.label.Visible = false
        end
    end
    if PullState.highlight then
        PullState.highlight.FillColor = Config.AimMagnet.HighlightColor
        PullState.highlight.OutlineColor = Config.AimMagnet.HighlightColor
        PullState.highlight.FillTransparency = Config.AimMagnet.Anchor and 0.3 or 0.7
    end
end

-- ═══════════════════════════════════════════════════════════
-- DRAWINGS & WATERMARK
-- ═══════════════════════════════════════════════════════════
local SilentFOVCircle = makeDrawing("Circle")
SilentFOVCircle.NumSides = 64; SilentFOVCircle.Filled = false
SilentFOVCircle.Thickness = 1.2; SilentFOVCircle.Transparency = 0.85
SilentFOVCircle.Visible = false

local AimbotFOVCircle = makeDrawing("Circle")
AimbotFOVCircle.NumSides = 64; AimbotFOVCircle.Filled = false
AimbotFOVCircle.Thickness = 1.2; AimbotFOVCircle.Transparency = 0.85
AimbotFOVCircle.Visible = false

local function renderAimbotFOV()
    if not Config.Aimbot.Enabled or not Config.Aimbot.ShowFOV then
        AimbotFOVCircle.Visible = false
        return
    end
    local mousePos = UserInputService:GetMouseLocation()
    AimbotFOVCircle.Position = mousePos
    AimbotFOVCircle.Radius = Config.Aimbot.FOV
    AimbotFOVCircle.Color = Config.Aimbot.FOVColor
    AimbotFOVCircle.Visible = true
end

-- Snapline / Aim Line from FOV center to target
local AimSnapLine = makeDrawing("Line")
AimSnapLine.Thickness = 1.5
AimSnapLine.Transparency = 0.85
AimSnapLine.Visible = false

local function updateAimSnapLine()
    if not (Config.Combat and Config.Combat.AimLine) then
        AimSnapLine.Visible = false
        return
    end

    local targetPart = CurrentSilentTarget or CurrentAimbotTarget
    if not targetPart and PullState and PullState.hrp then
        targetPart = PullState.hrp
    end

    if not targetPart or not targetPart.Parent then
        AimSnapLine.Visible = false
        return
    end

    local sp, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
    if not onScreen then
        AimSnapLine.Visible = false
        return
    end

    local fovCenter = UserInputService:GetMouseLocation()
    local wallCheckEnabled = Config.SilentAim.WallCheck or Config.Aimbot.WallCheck or (Config.AimMagnet.Enabled and not Config.AimMagnet.NoWallCheck)
    
    local lineColor = Color3.fromRGB(255, 255, 255) -- Mặc định màu trắng khi không bật wall check
    if wallCheckEnabled then
        local isVis = isPositionVisible(Camera.CFrame.Position, targetPart.Position, targetPart.Parent)
        if isVis then
            lineColor = Color3.fromRGB(50, 225, 120) -- Màu xanh khi lộ
        else
            lineColor = Color3.fromRGB(235, 65, 65)  -- Màu đỏ khi khuất
        end
    end

    AimSnapLine.From = fovCenter
    AimSnapLine.To = Vector2.new(sp.X, sp.Y)
    AimSnapLine.Color = lineColor
    AimSnapLine.Visible = true
end

local ESPCache = {}
local ChamsCache = {}
local RadarBlips = {}

-- On-screen Watermark drawings
local WatermarkBg = makeDrawing("Square")
WatermarkBg.Filled = true; WatermarkBg.Transparency = 0.82; WatermarkBg.Color = Color3.fromRGB(10, 13, 20)
WatermarkBg.Visible = false

local WatermarkBorder = makeDrawing("Square")
WatermarkBorder.Filled = false; WatermarkBorder.Thickness = 1; WatermarkBorder.Transparency = 0.6; WatermarkBorder.Color = U.ACCENT
WatermarkBorder.Visible = false

local WatermarkBar = makeDrawing("Line")
WatermarkBar.Thickness = 2; WatermarkBar.Color = U.ACCENT; WatermarkBar.Visible = false

local WatermarkText = makeDrawing("Text")
WatermarkText.Size = 11; WatermarkText.Outline = true; WatermarkText.Color = U.TEXT; WatermarkText.Visible = false

-- Aim warning drawings
local AimWarningText = makeDrawing("Text")
AimWarningText.Size = 16
AimWarningText.Center = true
AimWarningText.Outline = true
AimWarningText.Color = Color3.fromRGB(255, 50, 50)
AimWarningText.Text = "▲# Enemy aiming at you!"
AimWarningText.Visible = false

local AimWarningHeadCircles = {}
local function getAimCircle(plr)
    local c = AimWarningHeadCircles[plr]
    if not c then
        c = makeDrawing("Circle")
        c.Radius = 18
        c.Thickness = 2
        c.Filled = false
        c.Color = Color3.fromRGB(255, 45, 45)
        c.Visible = false
        AimWarningHeadCircles[plr] = c
    end
    return c
end

-- (EspCount is now rendered with rounded corners and translucency in EspCountGui)

local bones = {
    {"Head","UpperTorso"},{"UpperTorso","LowerTorso"},
    {"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},{"LeftLowerArm","LeftHand"},
    {"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},{"RightLowerArm","RightHand"},
    {"LowerTorso","LeftUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},{"LeftLowerLeg","LeftFoot"},
    {"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"},{"RightLowerLeg","RightFoot"}
}

local CHAM_BONES = {
    "Head", "HumanoidRootPart",
    "UpperTorso", "LowerTorso", "Torso",
    "LeftUpperArm", "LeftLowerArm", "LeftHand", "Left Arm",
    "RightUpperArm", "RightLowerArm", "RightHand", "Right Arm",
    "LeftUpperLeg", "LeftLowerLeg", "LeftFoot", "Left Leg",
    "RightUpperLeg", "RightLowerLeg", "RightFoot", "Right Leg"
}

function worldToScreen(v3)
    local p, on = Camera:WorldToViewportPoint(v3)
    if not on or p.Z <= 0 then return Vector2.new(), false end
    return Vector2.new(p.X, p.Y), true
end

local function healthColor(ratio)
    local r, g
    if ratio < 0.5 then r = 1.0; g = ratio * 2.0
    else r = (1.0 - ratio) * 2.0; g = 1.0 end
    return Color3.fromRGB(math.floor(r * 255), math.floor(g * 255), 40)
end

local function makeESP(plr)
    if ESPCache[plr] then return ESPCache[plr] end
    local d = {}
    d.Box = makeDrawing("Square"); d.Box.Filled = false
    d.BoxFill = makeDrawing("Square"); d.BoxFill.Thickness = 0; d.BoxFill.Filled = true
    d.Corner = {}
    for i = 1, 8 do local l = makeDrawing("Line"); l.Thickness = 1.5; table.insert(d.Corner, l) end
    d.Tracer = makeDrawing("Line"); d.Tracer.Thickness = 1.3
    d.Name = makeDrawing("Text"); d.Name.Center = true; d.Name.Outline = true
    d.Distance = makeDrawing("Text"); d.Distance.Center = true; d.Distance.Outline = true
    d.HealthText = makeDrawing("Text"); d.HealthText.Center = true; d.HealthText.Outline = true
    d.HealthBack = makeDrawing("Line"); d.HealthBack.Thickness = 3; d.HealthBack.Color = Color3.fromRGB(30,35,45)
    d.HealthFront = makeDrawing("Line"); d.HealthFront.Thickness = 3
    d.Head = makeDrawing("Circle"); d.Head.Filled = true
    d.Weapon = makeDrawing("Text"); d.Weapon.Center = true; d.Weapon.Outline = true
    d.Weapon.Size = 10; d.Weapon.Color = Color3.fromRGB(180, 200, 240)
    d.Skeleton = {}
    for i = 1, #bones do local l = makeDrawing("Line"); l.Thickness = 1.3; table.insert(d.Skeleton, l) end
    d.Arrow = makeDrawing("Triangle"); d.Arrow.Filled = true; d.Arrow.Visible = false

    -- Style 2 Banner elements
    d.BannerBg = makeDrawing("Square"); d.BannerBg.Filled = true; d.BannerBg.Thickness = 0
    d.BannerBorder = makeDrawing("Square"); d.BannerBorder.Filled = false; d.BannerBorder.Thickness = 1
    d.BannerHealthBack = makeDrawing("Square"); d.BannerHealthBack.Filled = true; d.BannerHealthBack.Thickness = 0
    d.BannerHealthFill = makeDrawing("Square"); d.BannerHealthFill.Filled = true; d.BannerHealthFill.Thickness = 0

    ESPCache[plr] = d
    return d
end

local function clearESP(plr)
    local d = ESPCache[plr]
    if not d then return end
    for _, obj in pairs(d) do
        if type(obj) == "table" then
            for _, x in pairs(obj) do
                if x and x.Visible ~= nil then x.Visible = false end
            end
        elseif obj and obj.Visible ~= nil then obj.Visible = false end
    end
end

local function drawCornerBox(lines, TL, TR, BL, BR, size, color, thickness)
    local p = {
        {TL, TL + Vector2.new(size, 0)}, {TL, TL + Vector2.new(0, size)},
        {TR, TR + Vector2.new(-size, 0)}, {TR, TR + Vector2.new(0, size)},
        {BL, BL + Vector2.new(size, 0)}, {BL, BL + Vector2.new(0, -size)},
        {BR, BR + Vector2.new(-size, 0)}, {BR, BR + Vector2.new(0, -size)},
    }
    for i, v in ipairs(p) do
        lines[i].From = v[1]; lines[i].To = v[2]
        lines[i].Color = color; lines[i].Thickness = thickness; lines[i].Visible = true
    end
end

local function computeBox(top, bottom)
    local h = math.abs(bottom.Y - top.Y)
    if h < 4 then h = 4 end
    if h > 4000 then h = 4000 end
    return h * 0.5, h
end

-- ═══════════════════════════════════════════════════════════
-- UI FRAMEWORK
-- ═══════════════════════════════════════════════════════════
local ParentGui = Instance.new("ScreenGui")
ParentGui.Name = "RSilent_UI"; ParentGui.ResetOnSpawn = false
ParentGui.IgnoreGuiInset = true; ParentGui.DisplayOrder = 9999
ParentGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ParentGui.Parent = gui_parent()

local function corner(parent, r)
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r or 6); c.Parent = parent
    return c
end
local function stroke(parent, col, th)
    local s = Instance.new("UIStroke"); s.Color = col or U.BORDER; s.Thickness = th or 1; s.Parent = parent
    return s
end

-- Frosted Glass Rounded ESP Count Widget
local EspCountGui = Instance.new("Frame")
EspCountGui.Name = "RSilent_EspCount"
EspCountGui.BackgroundColor3 = Color3.fromRGB(12, 16, 26)
EspCountGui.BackgroundTransparency = 0.25
EspCountGui.BorderSizePixel = 0
EspCountGui.Size = UDim2.new(0, 115, 0, 26)
EspCountGui.Position = UDim2.new(0.5, -57, 0, 20)
EspCountGui.ZIndex = 8000
EspCountGui.Visible = false
EspCountGui.Parent = ParentGui
corner(EspCountGui, 8)
local countStroke = stroke(EspCountGui, U.BORDER_HI, 1)

local countSheen = Instance.new("Frame", EspCountGui)
countSheen.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
countSheen.BackgroundTransparency = 0.92
countSheen.BorderSizePixel = 0
countSheen.Size = UDim2.new(1, 0, 0, 1.5)
countSheen.Position = UDim2.new(0, 0, 0, 0)
corner(countSheen, 1)

local countLabel = Instance.new("TextLabel")
countLabel.BackgroundTransparency = 1
countLabel.Size = UDim2.new(1, 0, 1, 0)
countLabel.Font = Enum.Font.GothamBold
countLabel.TextSize = 11
countLabel.TextColor3 = U.GOOD
countLabel.Text = "ENEMIES: 0"
countLabel.ZIndex = 8001
countLabel.Parent = EspCountGui

-- ═══════════════════════════════════════════════════════════
-- NOTIFICATION SYSTEM (LIQUID GLASS & GLITCH-FREE)
-- ═══════════════════════════════════════════════════════════
local NotifContainer = Instance.new("Frame")
NotifContainer.Name = "Notifications"
NotifContainer.BackgroundTransparency = 1
NotifContainer.BorderSizePixel = 0
NotifContainer.Size = UDim2.new(0, 310, 1, -40)
NotifContainer.Position = UDim2.new(1, -20, 1, -20)
NotifContainer.AnchorPoint = Vector2.new(1, 1)
NotifContainer.ZIndex = 9999
NotifContainer.Parent = ParentGui

local notifLayout = Instance.new("UIListLayout")
notifLayout.SortOrder = Enum.SortOrder.LayoutOrder
notifLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
notifLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
notifLayout.Padding = UDim.new(0, 8)
notifLayout.Parent = NotifContainer

local function Notify(title, message, notifType, duration)
    duration = duration or 3.5
    notifType = notifType or "info"

    local accentCol = U.ACCENT
    local iconSym = "ℹ"
    if notifType == "success" then
        accentCol = U.GOOD
        iconSym = "✓"
    elseif notifType == "warning" then
        accentCol = U.AMBER
        iconSym = "⚠"
    elseif notifType == "error" then
        accentCol = U.BAD
        iconSym = "✕"
    end

    local wrapper = Instance.new("Frame")
    wrapper.BackgroundTransparency = 1
    wrapper.BorderSizePixel = 0
    wrapper.Size = UDim2.new(1, 0, 0, 0)
    wrapper.AutomaticSize = Enum.AutomaticSize.Y
    wrapper.ClipsDescendants = false
    wrapper.ZIndex = 10000
    wrapper.Parent = NotifContainer

    local card = Instance.new("Frame")
    card.BackgroundColor3 = U.BG_GLASS
    card.BackgroundTransparency = 0.15
    card.BorderSizePixel = 0
    card.Size = UDim2.new(1, 0, 0, 0)
    card.AutomaticSize = Enum.AutomaticSize.Y
    card.Position = UDim2.new(1, 330, 0, 0)
    card.ZIndex = 10001
    card.ClipsDescendants = true
    card.Parent = wrapper
    corner(card, 8)
    local cardStroke = stroke(card, accentCol, 1)

    local pad = Instance.new("UIPadding", card)
    pad.PaddingLeft = UDim.new(0, 12); pad.PaddingRight = UDim.new(0, 12)
    pad.PaddingTop = UDim.new(0, 10); pad.PaddingBottom = UDim.new(0, 12)

    local topSheen = Instance.new("Frame", card)
    topSheen.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    topSheen.BackgroundTransparency = 0.92
    topSheen.BorderSizePixel = 0
    topSheen.Size = UDim2.new(1, 24, 0, 1.5)
    topSheen.Position = UDim2.new(0, -12, 0, -10)
    topSheen.ZIndex = 10002

    local sidePill = Instance.new("Frame")
    sidePill.BackgroundColor3 = accentCol
    sidePill.BorderSizePixel = 0
    sidePill.Size = UDim2.new(0, 3, 1, -12)
    sidePill.Position = UDim2.new(0, -8, 0, 6)
    sidePill.ZIndex = 10002
    sidePill.Parent = card
    corner(sidePill, 1.5)

    local iconBg = Instance.new("Frame")
    iconBg.BackgroundColor3 = accentCol
    iconBg.BackgroundTransparency = 0.82
    iconBg.BorderSizePixel = 0
    iconBg.Size = UDim2.new(0, 24, 0, 24)
    iconBg.Position = UDim2.new(0, 0, 0, 2)
    iconBg.ZIndex = 10002
    iconBg.Parent = card
    corner(iconBg, 12); stroke(iconBg, accentCol, 1)

    local iconLbl = Instance.new("TextLabel")
    iconLbl.BackgroundTransparency = 1
    iconLbl.Size = UDim2.new(1, 0, 1, 0)
    iconLbl.Font = Enum.Font.GothamBold
    iconLbl.TextSize = 12
    iconLbl.TextColor3 = accentCol
    iconLbl.Text = iconSym
    iconLbl.ZIndex = 10003
    iconLbl.Parent = iconBg

    local titleLbl = Instance.new("TextLabel")
    titleLbl.BackgroundTransparency = 1
    titleLbl.Size = UDim2.new(1, -34, 0, 14)
    titleLbl.Position = UDim2.new(0, 32, 0, 0)
    titleLbl.Font = Enum.Font.GothamBold
    titleLbl.TextSize = 12
    titleLbl.TextColor3 = U.TEXT
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.Text = string.upper(title)
    titleLbl.ZIndex = 10002
    titleLbl.Parent = card

    local msgLbl = Instance.new("TextLabel")
    msgLbl.BackgroundTransparency = 1
    msgLbl.Size = UDim2.new(1, -34, 0, 0)
    msgLbl.AutomaticSize = Enum.AutomaticSize.Y
    msgLbl.Position = UDim2.new(0, 32, 0, 16)
    msgLbl.Font = Enum.Font.Gotham
    msgLbl.TextSize = 11
    msgLbl.TextColor3 = U.TEXT_DIM
    msgLbl.TextWrapped = true
    msgLbl.TextXAlignment = Enum.TextXAlignment.Left
    msgLbl.Text = message
    msgLbl.ZIndex = 10002
    msgLbl.Parent = card

    local progTrack = Instance.new("Frame")
    progTrack.BackgroundColor3 = U.BORDER
    progTrack.BorderSizePixel = 0
    progTrack.Size = UDim2.new(1, 24, 0, 2)
    progTrack.Position = UDim2.new(0, -12, 1, 10)
    progTrack.ZIndex = 10002
    progTrack.Parent = card

    local progFill = Instance.new("Frame")
    progFill.BackgroundColor3 = accentCol
    progFill.BorderSizePixel = 0
    progFill.Size = UDim2.new(1, 0, 1, 0)
    progFill.ZIndex = 10003
    progFill.Parent = progTrack

    TweenService:Create(card, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Position = UDim2.new(0, 0, 0, 0)
    }):Play()

    local progTween = TweenService:Create(progFill, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
        Size = UDim2.new(0, 0, 1, 0)
    })
    progTween:Play()

    local dismissed = false
    local function dismiss()
        if dismissed then return end
        dismissed = true
        progTween:Cancel()
        local outTween = TweenService:Create(card, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Position = UDim2.new(1, 330, 0, 0),
            BackgroundTransparency = 1,
        })
        outTween:Play()
        task.delay(0.23, function()
            pcall(function() wrapper:Destroy() end)
        end)
    end

    local clickBtn = Instance.new("TextButton")
    clickBtn.BackgroundTransparency = 1
    clickBtn.Size = UDim2.new(1, 0, 1, 0)
    clickBtn.Text = ""
    clickBtn.ZIndex = 10005
    clickBtn.Parent = card
    clickBtn.MouseButton1Click:Connect(dismiss)

    clickBtn.MouseEnter:Connect(function()
        TweenService:Create(cardStroke, TweenInfo.new(0.15), {Color = U.ACCENT_H}):Play()
        TweenService:Create(card, TweenInfo.new(0.15), {BackgroundColor3 = U.CARD_HOV, BackgroundTransparency = 0.05}):Play()
    end)
    clickBtn.MouseLeave:Connect(function()
        TweenService:Create(cardStroke, TweenInfo.new(0.15), {Color = accentCol}):Play()
        TweenService:Create(card, TweenInfo.new(0.15), {BackgroundColor3 = U.BG_GLASS, BackgroundTransparency = 0.15}):Play()
    end)

    task.delay(duration, function()
        if not dismissed then dismiss() end
    end)
end

-- ═══════════════════════════════════════════════════════════
-- TOOLTIP SYSTEM (FLOATING HOVER UI)
-- ═══════════════════════════════════════════════════════════
local TooltipFrame = Instance.new("Frame")
TooltipFrame.Name = "RSilent_Tooltip"
TooltipFrame.BackgroundColor3 = Color3.fromRGB(12, 16, 26)
TooltipFrame.BackgroundTransparency = 1
TooltipFrame.BorderSizePixel = 0
TooltipFrame.Size = UDim2.new(0, 220, 0, 0)
TooltipFrame.AutomaticSize = Enum.AutomaticSize.Y
TooltipFrame.ZIndex = 50000
TooltipFrame.ClipsDescendants = true
TooltipFrame.Visible = false
TooltipFrame.Parent = ParentGui
corner(TooltipFrame, 7)
local tooltipStroke = stroke(TooltipFrame, U.BORDER_HI, 1)

local ttPad = Instance.new("UIPadding", TooltipFrame)
ttPad.PaddingLeft = UDim.new(0, 10); ttPad.PaddingRight = UDim.new(0, 10)
ttPad.PaddingTop = UDim.new(0, 8); ttPad.PaddingBottom = UDim.new(0, 8)

local ttSheen = Instance.new("Frame", TooltipFrame)
ttSheen.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
ttSheen.BackgroundTransparency = 0.9
ttSheen.BorderSizePixel = 0
ttSheen.Size = UDim2.new(1, 20, 0, 1.5)
ttSheen.Position = UDim2.new(0, -10, 0, -8)
ttSheen.ZIndex = 50001

local ttTitle = Instance.new("TextLabel")
ttTitle.BackgroundTransparency = 1
ttTitle.Size = UDim2.new(1, 0, 0, 14)
ttTitle.Font = Enum.Font.GothamBold
ttTitle.TextSize = 11
ttTitle.TextColor3 = U.ACCENT_H
ttTitle.TextXAlignment = Enum.TextXAlignment.Left
ttTitle.Text = ""
ttTitle.ZIndex = 50002
ttTitle.Parent = TooltipFrame

local ttDesc = Instance.new("TextLabel")
ttDesc.BackgroundTransparency = 1
ttDesc.Size = UDim2.new(1, 0, 0, 0)
ttDesc.AutomaticSize = Enum.AutomaticSize.Y
ttDesc.Position = UDim2.new(0, 0, 0, 16)
ttDesc.Font = Enum.Font.Gotham
ttDesc.TextSize = 10
ttDesc.TextColor3 = U.TEXT_DIM
ttDesc.TextXAlignment = Enum.TextXAlignment.Left
ttDesc.TextWrapped = true
ttDesc.Text = ""
ttDesc.ZIndex = 50002
ttDesc.Parent = TooltipFrame

local currentTooltipOwner = nil
local function showTooltip(title, desc, rowFrame)
    if not desc or desc == "" then return end
    currentTooltipOwner = rowFrame
    ttTitle.Text = title
    ttDesc.Text = desc
    TooltipFrame.Visible = true

    local mouse = UserInputService:GetMouseLocation()
    local vp = Camera.ViewportSize
    local posX = math.clamp(mouse.X + 16, 10, vp.X - 235)
    local posY = math.clamp(mouse.Y + 12, 10, vp.Y - 110)
    TooltipFrame.Position = UDim2.new(0, posX, 0, posY)
    TweenService:Create(TooltipFrame, TweenInfo.new(0.12), {BackgroundTransparency = 0.1}):Play()
    TweenService:Create(tooltipStroke, TweenInfo.new(0.12), {Color = U.ACCENT}):Play()
end

local function hideTooltip(rowFrame)
    if currentTooltipOwner == rowFrame then
        currentTooltipOwner = nil
        local t = TweenService:Create(TooltipFrame, TweenInfo.new(0.1), {BackgroundTransparency = 1})
        t:Play()
        task.delay(0.1, function()
            if not currentTooltipOwner then
                TooltipFrame.Visible = false
            end
        end)
    end
end

-- ═══════════════════════════════════════════════════════════
-- RISKY FEATURE CONFIRMATION MODAL
-- ═══════════════════════════════════════════════════════════
local function showRiskyConfirmModal(featureName, desc, onConfirm, onCancel)
    local modalOverlay = Instance.new("TextButton")
    modalOverlay.Name = "RiskyConfirmOverlay"
    modalOverlay.BackgroundColor3 = Color3.fromRGB(5, 7, 12)
    modalOverlay.BackgroundTransparency = 0.4
    modalOverlay.BorderSizePixel = 0
    modalOverlay.Size = UDim2.new(1, 0, 1, 0)
    modalOverlay.Position = UDim2.new(0, 0, 0, 0)
    modalOverlay.ZIndex = 40000
    modalOverlay.Text = ""
    modalOverlay.AutoButtonColor = false
    modalOverlay.Parent = ParentGui

    local dialog = Instance.new("Frame")
    dialog.BackgroundColor3 = U.BG_GLASS
    dialog.BackgroundTransparency = 0.08
    dialog.BorderSizePixel = 0
    dialog.Size = UDim2.new(0, 390, 0, 230)
    dialog.Position = UDim2.new(0.5, -195, 0.5, -115)
    dialog.ZIndex = 40001
    dialog.ClipsDescendants = true
    dialog.Parent = modalOverlay
    corner(dialog, 10)
    stroke(dialog, U.RISKY, 1.5)

    local topSheen = Instance.new("Frame", dialog)
    topSheen.BackgroundColor3 = U.RISKY
    topSheen.BorderSizePixel = 0
    topSheen.Size = UDim2.new(1, 0, 0, 2.5)
    topSheen.Position = UDim2.new(0, 0, 0, 0)
    topSheen.ZIndex = 40002

    local dPad = Instance.new("UIPadding", dialog)
    dPad.PaddingLeft = UDim.new(0, 18); dPad.PaddingRight = UDim.new(0, 18)
    dPad.PaddingTop = UDim.new(0, 16); dPad.PaddingBottom = UDim.new(0, 16)

    local hRow = Instance.new("Frame")
    hRow.BackgroundTransparency = 1
    hRow.Size = UDim2.new(1, 0, 0, 24)
    hRow.Parent = dialog

    local warnIcon = Instance.new("TextLabel")
    warnIcon.BackgroundTransparency = 1
    warnIcon.Size = UDim2.new(0, 22, 1, 0)
    warnIcon.Font = Enum.Font.GothamBold
    warnIcon.TextSize = 16
    warnIcon.TextColor3 = U.RISKY
    warnIcon.Text = "⚠"
    warnIcon.Parent = hRow

    local titleLbl = Instance.new("TextLabel")
    titleLbl.BackgroundTransparency = 1
    titleLbl.Size = UDim2.new(1, -26, 1, 0)
    titleLbl.Position = UDim2.new(0, 26, 0, 0)
    titleLbl.Font = Enum.Font.GothamBold
    titleLbl.TextSize = 13
    titleLbl.TextColor3 = U.RISKY
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.Text = "WARNING: HIGH DETECTION RISK"
    titleLbl.Parent = hRow

    local qLbl = Instance.new("TextLabel")
    qLbl.BackgroundTransparency = 1
    qLbl.Size = UDim2.new(1, 0, 0, 20)
    qLbl.Position = UDim2.new(0, 0, 0, 36)
    qLbl.Font = Enum.Font.GothamBold
    qLbl.TextSize = 13
    qLbl.TextColor3 = U.TEXT
    qLbl.TextXAlignment = Enum.TextXAlignment.Left
    qLbl.Text = "Are you sure you want to enable " .. featureName .. "?"
    qLbl.Parent = dialog

    local descBox = Instance.new("Frame")
    descBox.BackgroundColor3 = U.CARD2
    descBox.BackgroundTransparency = 0.3
    descBox.BorderSizePixel = 0
    descBox.Size = UDim2.new(1, 0, 0, 68)
    descBox.Position = UDim2.new(0, 0, 0, 64)
    descBox.Parent = dialog
    corner(descBox, 6); stroke(descBox, U.BORDER, 1)

    local descPad = Instance.new("UIPadding", descBox)
    descPad.PaddingLeft = UDim.new(0, 10); descPad.PaddingRight = UDim.new(0, 10)
    descPad.PaddingTop = UDim.new(0, 8); descPad.PaddingBottom = UDim.new(0, 8)

    local descText = Instance.new("TextLabel")
    descText.BackgroundTransparency = 1
    descText.Size = UDim2.new(1, 0, 1, 0)
    descText.Font = Enum.Font.Gotham
    descText.TextSize = 11
    descText.TextColor3 = U.TEXT_DIM
    descText.TextWrapped = true
    descText.TextXAlignment = Enum.TextXAlignment.Left
    descText.TextYAlignment = Enum.TextYAlignment.Top
    descText.Text = desc
    descText.Parent = descBox

    local btnRow = Instance.new("Frame")
    btnRow.BackgroundTransparency = 1
    btnRow.Size = UDim2.new(1, 0, 0, 30)
    btnRow.Position = UDim2.new(0, 0, 1, -30)
    btnRow.Parent = dialog

    local cancelBtn = Instance.new("TextButton")
    cancelBtn.BackgroundColor3 = U.CARD2
    cancelBtn.BorderSizePixel = 0
    cancelBtn.Size = UDim2.new(0, 140, 1, 0)
    cancelBtn.Position = UDim2.new(0, 0, 0, 0)
    cancelBtn.Font = Enum.Font.GothamMedium
    cancelBtn.TextSize = 11
    cancelBtn.TextColor3 = U.TEXT_DIM
    cancelBtn.Text = "Cancel"
    cancelBtn.AutoButtonColor = false
    cancelBtn.Parent = btnRow
    corner(cancelBtn, 5); stroke(cancelBtn, U.BORDER, 1)

    local confirmBtn = Instance.new("TextButton")
    confirmBtn.BackgroundColor3 = U.RISKY
    confirmBtn.BorderSizePixel = 0
    confirmBtn.Size = UDim2.new(1, -150, 1, 0)
    confirmBtn.Position = UDim2.new(0, 150, 0, 0)
    confirmBtn.Font = Enum.Font.GothamBold
    confirmBtn.TextSize = 11
    confirmBtn.TextColor3 = Color3.fromRGB(15, 18, 25)
    confirmBtn.Text = "Confirm & Enable"
    confirmBtn.AutoButtonColor = false
    confirmBtn.Parent = btnRow
    corner(confirmBtn, 5)

    cancelBtn.MouseEnter:Connect(function()
        TweenService:Create(cancelBtn, TweenInfo.new(0.15), {BackgroundColor3 = U.CARD_HOV, TextColor3 = U.TEXT}):Play()
    end)
    cancelBtn.MouseLeave:Connect(function()
        TweenService:Create(cancelBtn, TweenInfo.new(0.15), {BackgroundColor3 = U.CARD2, TextColor3 = U.TEXT_DIM}):Play()
    end)
    confirmBtn.MouseEnter:Connect(function()
        TweenService:Create(confirmBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(255, 205, 80)}):Play()
    end)
    confirmBtn.MouseLeave:Connect(function()
        TweenService:Create(confirmBtn, TweenInfo.new(0.15), {BackgroundColor3 = U.RISKY}):Play()
    end)

    dialog.Position = UDim2.new(0.5, -195, 0.5, -95)
    dialog.BackgroundTransparency = 1
    TweenService:Create(dialog, TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Position = UDim2.new(0.5, -195, 0.5, -115),
        BackgroundTransparency = 0.08,
    }):Play()

    local function closeDialog(confirmed)
        TweenService:Create(dialog, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Position = UDim2.new(0.5, -195, 0.5, -95),
            BackgroundTransparency = 1,
        }):Play()
        TweenService:Create(modalOverlay, TweenInfo.new(0.18), {BackgroundTransparency = 1}):Play()
        task.delay(0.2, function()
            pcall(function() modalOverlay:Destroy() end)
            if confirmed then
                if onConfirm then onConfirm() end
            else
                if onCancel then onCancel() end
            end
        end)
    end

    cancelBtn.MouseButton1Click:Connect(function() closeDialog(false) end)
    confirmBtn.MouseButton1Click:Connect(function() closeDialog(true) end)
end

-- ═══════════════════════════════════════════════════════════
-- MAIN WINDOW (LIQUID GLASS STYLING)
-- ═══════════════════════════════════════════════════════════
local Window = Instance.new("Frame")
Window.BackgroundColor3 = U.BG_GLASS
Window.BackgroundTransparency = 0.12
Window.BorderSizePixel = 0
Window.Size = UDim2.new(0, 750, 0, 490)
Window.Position = UDim2.new(0.5, -375, 0.5, -245)
Window.Active = true
Window.Visible = false
Window.Parent = ParentGui
corner(Window, 10)
local windowStroke = stroke(Window, U.BORDER, 1)

local winSheen = Instance.new("Frame", Window)
winSheen.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
winSheen.BackgroundTransparency = 0.94
winSheen.BorderSizePixel = 0
winSheen.Size = UDim2.new(1, 0, 0, 1.5)
winSheen.Position = UDim2.new(0, 0, 0, 0)
winSheen.ZIndex = 5

local windowOpen = false
local function toggleWindow(force)
    if force ~= nil then
        windowOpen = force
    else
        windowOpen = not windowOpen
    end

    if windowOpen then
        Window.Visible = true
        Window.BackgroundTransparency = 1
        Window.Size = UDim2.new(0, 700, 0, 440)
        Window.Position = UDim2.new(0.5, -350, 0.5, -220)
        local targetTransp = (Config.UI and Config.UI.WindowTransparency) or 0.12
        TweenService:Create(Window, TweenInfo.new(0.32, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            BackgroundTransparency = targetTransp,
            Size = UDim2.new(0, 750, 0, 490),
            Position = UDim2.new(0.5, -375, 0.5, -245),
        }):Play()
    else
        local closeTween = TweenService:Create(Window, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            BackgroundTransparency = 1,
            Size = UDim2.new(0, 700, 0, 440),
            Position = UDim2.new(0.5, -350, 0.5, -220),
        })
        closeTween:Play()
        task.delay(0.21, function()
            if not windowOpen then
                Window.Visible = false
            end
        end)
    end
end

-- ═══════ TOPBAR DRAG ZONE WITH LIVE METRICS ═══════
local Topbar = Instance.new("Frame")
Topbar.BackgroundColor3 = U.SIDEBAR; Topbar.BorderSizePixel = 0
Topbar.Size = UDim2.new(1, -165, 0, 40); Topbar.Position = UDim2.new(0, 165, 0, 0)
Topbar.Parent = Window
Topbar.Active = true

local dragging, dragStart, startPos = false, nil, nil
Topbar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true; dragStart = input.Position; startPos = Window.Position
        TweenService:Create(windowStroke, TweenInfo.new(0.15), {Color = U.ACCENT}):Play()
    end
end)
Topbar.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
        TweenService:Create(windowStroke, TweenInfo.new(0.2), {Color = U.BORDER}):Play()
    end
end)
trackConn(UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 and dragging then
        dragging = false
        TweenService:Create(windowStroke, TweenInfo.new(0.2), {Color = U.BORDER}):Play()
    end
end))
trackConn(UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local d = input.Position - dragStart
        Window.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
    end
end))

-- Topbar bottom animated shimmer line
local TopDiv = Instance.new("Frame", Topbar)
TopDiv.BackgroundColor3 = U.ACCENT; TopDiv.BorderSizePixel = 0
TopDiv.Size = UDim2.new(1, 0, 0, 1.5); TopDiv.Position = UDim2.new(0, 0, 1, -1.5)
local topGrad = Instance.new("UIGradient", TopDiv)
topGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, U.BORDER),
    ColorSequenceKeypoint.new(0.5, U.ACCENT_H),
    ColorSequenceKeypoint.new(1, U.BORDER),
})

local TitleLbl = Instance.new("TextLabel")
TitleLbl.BackgroundTransparency = 1
TitleLbl.Size = UDim2.new(0, 140, 1, 0); TitleLbl.Position = UDim2.new(0, 14, 0, 0)
TitleLbl.Font = Enum.Font.GothamBlack; TitleLbl.TextSize = 12
TitleLbl.TextColor3 = U.TEXT; TitleLbl.TextXAlignment = Enum.TextXAlignment.Left
TitleLbl.Text = ""; TitleLbl.Parent = Topbar

local MetricsLbl = Instance.new("TextLabel")
MetricsLbl.BackgroundTransparency = 1
MetricsLbl.Size = UDim2.new(0, 140, 1, 0); MetricsLbl.Position = UDim2.new(1, -220, 0, 0)
MetricsLbl.Font = Enum.Font.Code; MetricsLbl.TextSize = 10
MetricsLbl.TextColor3 = U.TEXT_MUTE; MetricsLbl.TextXAlignment = Enum.TextXAlignment.Right
MetricsLbl.Text = "60 FPS · 30ms"; MetricsLbl.Parent = Topbar

-- Minimize button
local MinBtn = Instance.new("TextButton")
MinBtn.BackgroundColor3 = U.CARD; MinBtn.BorderSizePixel = 0
MinBtn.Size = UDim2.new(0, 24, 0, 24); MinBtn.Position = UDim2.new(1, -62, 0.5, -12)
MinBtn.Font = Enum.Font.GothamBold; MinBtn.TextSize = 12
MinBtn.TextColor3 = U.TEXT_DIM; MinBtn.Text = "─"
MinBtn.AutoButtonColor = false; MinBtn.Parent = Topbar
corner(MinBtn, 5); stroke(MinBtn, U.BORDER, 1)

MinBtn.MouseEnter:Connect(function()
    TweenService:Create(MinBtn, TweenInfo.new(0.12), {BackgroundColor3 = U.CARD_HOV, TextColor3 = U.TEXT}):Play()
end)
MinBtn.MouseLeave:Connect(function()
    TweenService:Create(MinBtn, TweenInfo.new(0.12), {BackgroundColor3 = U.CARD, TextColor3 = U.TEXT_DIM}):Play()
end)
MinBtn.MouseButton1Click:Connect(function()
    toggleWindow(false)
    Notify("Amethyst", "UI Minimized, Press RightCtrl To Open", "info", 2.5)
end)

-- Close button
local CloseBtn = Instance.new("TextButton")
CloseBtn.BackgroundColor3 = U.CARD; CloseBtn.BorderSizePixel = 0
CloseBtn.Size = UDim2.new(0, 24, 0, 24); CloseBtn.Position = UDim2.new(1, -32, 0.5, -12)
CloseBtn.Font = Enum.Font.GothamBold; CloseBtn.TextSize = 14
CloseBtn.TextColor3 = U.TEXT_DIM; CloseBtn.Text = "×"
CloseBtn.AutoButtonColor = false; CloseBtn.Parent = Topbar
corner(CloseBtn, 5)
local closeStroke = stroke(CloseBtn, U.BORDER, 1)

CloseBtn.MouseEnter:Connect(function()
    TweenService:Create(CloseBtn, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        BackgroundColor3 = U.BAD,
        TextColor3 = U.TEXT,
        Rotation = 90,
    }):Play()
    TweenService:Create(closeStroke, TweenInfo.new(0.15), {Color = U.BAD}):Play()
end)
CloseBtn.MouseLeave:Connect(function()
    TweenService:Create(CloseBtn, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        BackgroundColor3 = U.CARD,
        TextColor3 = U.TEXT_DIM,
        Rotation = 0,
    }):Play()
    TweenService:Create(closeStroke, TweenInfo.new(0.15), {Color = U.BORDER}):Play()
end)
CloseBtn.MouseButton1Click:Connect(function()
    Notify("Amethyst", "Unloading script completely...", "warning", 1.5)
    task.delay(0.25, function()
        unloadScript()
    end)
end)

-- ═══════ SIDEBAR REDESIGN WITH PROFILE BADGE ═══════
local Sidebar = Instance.new("Frame")
Sidebar.BackgroundColor3 = U.SIDEBAR; Sidebar.BorderSizePixel = 0
Sidebar.Size = UDim2.new(0, 165, 1, 0); Sidebar.Parent = Window
corner(Sidebar, 10)
local sidebarRight = Instance.new("Frame", Sidebar)
sidebarRight.BackgroundColor3 = U.SIDEBAR; sidebarRight.BorderSizePixel = 0
sidebarRight.Size = UDim2.new(0, 16, 1, 0); sidebarRight.Position = UDim2.new(1, -16, 0, 0); sidebarRight.ZIndex = 1

local Brand = Instance.new("TextLabel")
Brand.BackgroundTransparency = 1; Brand.Size = UDim2.new(1, -20, 0, 26)
Brand.Position = UDim2.new(0, 16, 0, 12)
Brand.Font = Enum.Font.GothamBlack; Brand.TextSize = 15
Brand.TextColor3 = U.TEXT; Brand.TextXAlignment = Enum.TextXAlignment.Left
Brand.Text = "Amethyst | Rivals"; Brand.ZIndex = 2; Brand.Parent = Sidebar

local brandDiv = Instance.new("Frame", Sidebar)
brandDiv.BackgroundColor3 = U.BORDER; brandDiv.BorderSizePixel = 0
brandDiv.Size = UDim2.new(1, -26, 0, 1); brandDiv.Position = UDim2.new(0, 13, 0, 44); brandDiv.ZIndex = 2

local navButtons = {}
local function makeNavBtn(name, icon, yoffset)
    local btn = Instance.new("TextButton")
    btn.BackgroundColor3 = U.CARD; btn.BackgroundTransparency = 1
    btn.BorderSizePixel = 0; btn.Size = UDim2.new(1, -20, 0, 32)
    btn.Position = UDim2.new(0, 10, 0, yoffset); btn.Text = ""
    btn.AutoButtonColor = false; btn.ZIndex = 3; btn.Parent = Sidebar
    corner(btn, 6)

    local dot = Instance.new("Frame")
    dot.BackgroundColor3 = U.TEXT_MUTE; dot.BorderSizePixel = 0
    dot.Size = UDim2.new(0, 4, 0, 4); dot.Position = UDim2.new(0, 10, 0.5, -2)
    dot.ZIndex = 4; dot.Parent = btn
    corner(dot, 2)

    local iconLbl = Instance.new("TextLabel")
    iconLbl.BackgroundTransparency = 1
    iconLbl.Size = UDim2.new(0, 18, 1, 0); iconLbl.Position = UDim2.new(0, 20, 0, 0)
    iconLbl.Font = Enum.Font.GothamBold; iconLbl.TextSize = 12
    iconLbl.TextColor3 = U.TEXT_DIM; iconLbl.Text = icon; iconLbl.ZIndex = 4; iconLbl.Parent = btn

    local lbl = Instance.new("TextLabel")
    lbl.BackgroundTransparency = 1
    lbl.Size = UDim2.new(1, -44, 1, 0); lbl.Position = UDim2.new(0, 40, 0, 0)
    lbl.Font = Enum.Font.GothamMedium; lbl.TextSize = 11
    lbl.TextColor3 = U.TEXT_DIM; lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Text = name; lbl.ZIndex = 4; lbl.Parent = btn

    btn.MouseEnter:Connect(function()
        if btn:GetAttribute("active") then return end
        TweenService:Create(btn, TweenInfo.new(0.18, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            BackgroundTransparency = 0.5,
            Position = UDim2.new(0, 13, 0, yoffset),
        }):Play()
        TweenService:Create(lbl, TweenInfo.new(0.15), {TextColor3 = U.TEXT}):Play()
        TweenService:Create(iconLbl, TweenInfo.new(0.15), {TextColor3 = U.ACCENT}):Play()
    end)
    btn.MouseLeave:Connect(function()
        if btn:GetAttribute("active") then return end
        TweenService:Create(btn, TweenInfo.new(0.18, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 10, 0, yoffset),
        }):Play()
        TweenService:Create(lbl, TweenInfo.new(0.15), {TextColor3 = U.TEXT_DIM}):Play()
        TweenService:Create(iconLbl, TweenInfo.new(0.15), {TextColor3 = U.TEXT_DIM}):Play()
    end)
    navButtons[name] = {btn = btn, dot = dot, label = lbl, icon = iconLbl, yoffset = yoffset}
end

makeNavBtn("Combat", "", 58)
makeNavBtn("Visual", "", 96)
makeNavBtn("Config", "", 134)
makeNavBtn("Interface", "", 172)

-- User Profile Card at bottom of sidebar
local UserCard = Instance.new("Frame")
UserCard.BackgroundColor3 = U.CARD; UserCard.BorderSizePixel = 0
UserCard.Size = UDim2.new(1, -22, 0, 44); UserCard.Position = UDim2.new(0, 11, 1, -54)
UserCard.ZIndex = 2; UserCard.Parent = Sidebar
corner(UserCard, 6); stroke(UserCard, U.BORDER, 1)

local userDot = Instance.new("Frame")
userDot.BackgroundColor3 = U.GOOD; userDot.BorderSizePixel = 0
userDot.Size = UDim2.new(0, 6, 0, 6); userDot.Position = UDim2.new(0, 10, 0.5, -3)
userDot.ZIndex = 3; userDot.Parent = UserCard
corner(userDot, 3)

local userNameLbl = Instance.new("TextLabel")
userNameLbl.BackgroundTransparency = 1
userNameLbl.Size = UDim2.new(1, -26, 0, 14); userNameLbl.Position = UDim2.new(0, 22, 0, 7)
userNameLbl.Font = Enum.Font.GothamBold; userNameLbl.TextSize = 10
userNameLbl.TextColor3 = U.TEXT; userNameLbl.TextXAlignment = Enum.TextXAlignment.Left
userNameLbl.Text = LocalPlayer.DisplayName; userNameLbl.ZIndex = 3; userNameLbl.Parent = UserCard

local userRoleLbl = Instance.new("TextLabel")
userRoleLbl.BackgroundTransparency = 1
userRoleLbl.Size = UDim2.new(1, -26, 0, 12); userRoleLbl.Position = UDim2.new(0, 22, 0, 22)
userRoleLbl.Font = Enum.Font.Code; userRoleLbl.TextSize = 9
userRoleLbl.TextColor3 = U.ACCENT; userRoleLbl.TextXAlignment = Enum.TextXAlignment.Left
userRoleLbl.Text = "● Stable"; userRoleLbl.ZIndex = 3; userRoleLbl.Parent = UserCard

-- ═══════ CONTENT ═══════
local Content = Instance.new("Frame")
Content.BackgroundTransparency = 1
Content.Size = UDim2.new(1, -165, 1, -40); Content.Position = UDim2.new(0, 165, 0, 40)
Content.Parent = Window

local Pages = {}
local function makePage(name)
    local sf = Instance.new("ScrollingFrame")
    sf.BackgroundTransparency = 1; sf.BorderSizePixel = 0
    sf.Size = UDim2.new(1, 0, 1, 0)
    sf.CanvasSize = UDim2.new(0, 0, 0, 0)
    sf.AutomaticCanvasSize = Enum.AutomaticSize.Y
    sf.ScrollBarThickness = 3; sf.ScrollBarImageColor3 = U.BORDER
    sf.Visible = false; sf.Parent = Content
    local pad = Instance.new("UIPadding", sf)
    pad.PaddingLeft = UDim.new(0, 10); pad.PaddingRight = UDim.new(0, 10)
    pad.PaddingTop = UDim.new(0, 10); pad.PaddingBottom = UDim.new(0, 10)
    local layout = Instance.new("UIListLayout", sf)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 8)
    Pages[name] = sf
end

-- ═══════ WIDGETS WITH LIQUID GLASS & HOVER EFFECTS ═══════
local function makeSection(parent, title)
    local card = Instance.new("Frame")
    card.BackgroundColor3 = U.CARD
    card.BackgroundTransparency = 0.2
    card.BorderSizePixel = 0
    card.Size = UDim2.new(1, 0, 0, 0); card.AutomaticSize = Enum.AutomaticSize.Y
    card.Parent = parent
    corner(card, 6)
    local cardStk = stroke(card, U.BORDER, 1)

    local cSheen = Instance.new("Frame", card)
    cSheen.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    cSheen.BackgroundTransparency = 0.94
    cSheen.BorderSizePixel = 0
    cSheen.Size = UDim2.new(1, 0, 0, 1)
    cSheen.Position = UDim2.new(0, 0, 0, 0)

    local header = Instance.new("Frame")
    header.BackgroundTransparency = 1
    header.Size = UDim2.new(1, 0, 0, 26)
    header.Parent = card

    local accentDot = Instance.new("Frame")
    accentDot.BackgroundColor3 = U.ACCENT; accentDot.BorderSizePixel = 0
    accentDot.Size = UDim2.new(0, 3, 0, 12); accentDot.Position = UDim2.new(0, 10, 0.5, -6)
    accentDot.Parent = header
    corner(accentDot, 1.5)

    local titleLbl = Instance.new("TextLabel")
    titleLbl.BackgroundTransparency = 1
    titleLbl.Size = UDim2.new(1, -26, 1, 0); titleLbl.Position = UDim2.new(0, 20, 0, 0)
    titleLbl.Font = Enum.Font.GothamBold; titleLbl.TextSize = 11
    titleLbl.TextColor3 = U.TEXT; titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.Text = title; titleLbl.Parent = header

    local hDiv = Instance.new("Frame", card)
    hDiv.BackgroundColor3 = U.BORDER; hDiv.BorderSizePixel = 0
    hDiv.Size = UDim2.new(1, 0, 0, 1); hDiv.Position = UDim2.new(0, 0, 0, 26)

    local body = Instance.new("Frame")
    body.BackgroundTransparency = 1
    body.Size = UDim2.new(1, 0, 0, 0); body.AutomaticSize = Enum.AutomaticSize.Y
    body.Position = UDim2.new(0, 0, 0, 28)
    body.Parent = card
    local pad = Instance.new("UIPadding", body)
    pad.PaddingLeft = UDim.new(0, 12); pad.PaddingRight = UDim.new(0, 12)
    pad.PaddingTop = UDim.new(0, 8); pad.PaddingBottom = UDim.new(0, 8)
    local layout = Instance.new("UIListLayout", body)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 6)

    card.MouseEnter:Connect(function()
        TweenService:Create(cardStk, TweenInfo.new(0.2), {Color = U.BORDER_HI}):Play()
        TweenService:Create(card, TweenInfo.new(0.2), {BackgroundColor3 = U.CARD_HOV, BackgroundTransparency = 0.1}):Play()
        TweenService:Create(accentDot, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 3, 0, 16),
            Position = UDim2.new(0, 10, 0.5, -8),
            BackgroundColor3 = U.ACCENT_H,
        }):Play()
    end)
    card.MouseLeave:Connect(function()
        TweenService:Create(cardStk, TweenInfo.new(0.2), {Color = U.BORDER}):Play()
        TweenService:Create(card, TweenInfo.new(0.2), {BackgroundColor3 = U.CARD, BackgroundTransparency = 0.2}):Play()
        TweenService:Create(accentDot, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 3, 0, 12),
            Position = UDim2.new(0, 10, 0.5, -6),
            BackgroundColor3 = U.ACCENT,
        }):Play()
    end)

    return body
end

local function makeToggleRow(parent, label, initial, tooltipDesc, callback)
    if typeof(tooltipDesc) == "function" then
        callback = tooltipDesc
        tooltipDesc = nil
    end
    tooltipDesc = tooltipDesc or ("Toggle " .. label)

    local row = Instance.new("Frame")
    row.BackgroundTransparency = 1
    row.Size = UDim2.new(1, 0, 0, 22); row.Parent = parent

    local lbl = Instance.new("TextLabel"); lbl.BackgroundTransparency = 1
    lbl.Size = UDim2.new(1, -44, 1, 0); lbl.Position = UDim2.new(0, 0, 0, 0)
    lbl.Font = Enum.Font.Gotham; lbl.TextSize = 11
    lbl.TextColor3 = U.TEXT_DIM; lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Text = label; lbl.Parent = row

    local track = Instance.new("Frame")
    track.BackgroundColor3 = initial and U.ACCENT or U.CARD2
    track.BorderSizePixel = 0
    track.Size = UDim2.new(0, 28, 0, 13)
    track.Position = UDim2.new(1, -28, 0.5, -6.5)
    track.Parent = row
    corner(track, 6.5)
    local trackStroke = stroke(track, initial and U.ACCENT or U.BORDER, 1)

    local knob = Instance.new("Frame")
    knob.BackgroundColor3 = Color3.new(1, 1, 1)
    knob.BorderSizePixel = 0
    knob.Size = UDim2.new(0, 9, 0, 9)
    knob.Position = initial and UDim2.new(1, -11, 0.5, -4.5) or UDim2.new(0, 2, 0.5, -4.5)
    knob.Parent = track
    corner(knob, 4.5)

    local checked = initial
    local btn = Instance.new("TextButton")
    btn.BackgroundTransparency = 1
    btn.Size = UDim2.new(1, 0, 1, 0); btn.Text = ""
    btn.AutoButtonColor = false; btn.Parent = row
    btn.MouseButton1Click:Connect(function()
        checked = not checked
        local targetPos = checked and UDim2.new(1, -11, 0.5, -4.5) or UDim2.new(0, 2, 0.5, -4.5)
        
        TweenService:Create(knob, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 12, 0, 7),
        }):Play()
        task.delay(0.08, function()
            TweenService:Create(knob, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                Position = targetPos,
                Size = UDim2.new(0, 9, 0, 9),
            }):Play()
        end)
        
        TweenService:Create(track, TweenInfo.new(0.18), {BackgroundColor3 = checked and U.ACCENT or U.CARD2}):Play()
        TweenService:Create(trackStroke, TweenInfo.new(0.18), {Color = checked and U.ACCENT or U.BORDER}):Play()
        if callback then callback(checked) end
    end)

    row.MouseEnter:Connect(function()
        showTooltip(label, tooltipDesc, row)
        TweenService:Create(lbl, TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            TextColor3 = U.TEXT,
            Position = UDim2.new(0, 3, 0, 0),
        }):Play()
        TweenService:Create(trackStroke, TweenInfo.new(0.15), {Color = checked and U.ACCENT_H or U.BORDER_HI}):Play()
    end)
    row.MouseLeave:Connect(function()
        hideTooltip(row)
        TweenService:Create(lbl, TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            TextColor3 = U.TEXT_DIM,
            Position = UDim2.new(0, 0, 0, 0),
        }):Play()
        TweenService:Create(trackStroke, TweenInfo.new(0.15), {Color = checked and U.ACCENT or U.BORDER}):Play()
    end)
    return row
end

local function makeRiskyToggleRow(parent, label, initial, tooltipDesc, riskExplanation, callback)
    if typeof(tooltipDesc) == "function" then
        callback = tooltipDesc
        tooltipDesc = nil
        riskExplanation = nil
    elseif typeof(riskExplanation) == "function" then
        callback = riskExplanation
        riskExplanation = tooltipDesc
    end
    tooltipDesc = tooltipDesc or ("High-risk combat feature: " .. label)
    riskExplanation = riskExplanation or ("Enabling " .. label .. " significantly increases detection risk.")

    local row = Instance.new("Frame")
    row.BackgroundTransparency = 1
    row.Size = UDim2.new(1, 0, 0, 24); row.Parent = parent

    local lbl = Instance.new("TextLabel"); lbl.BackgroundTransparency = 1
    lbl.Size = UDim2.new(1, -95, 1, 0); lbl.Position = UDim2.new(0, 0, 0, 0)
    lbl.Font = Enum.Font.GothamMedium; lbl.TextSize = 11
    lbl.TextColor3 = U.RISKY; lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Text = label; lbl.Parent = row

    local riskBadge = Instance.new("Frame")
    riskBadge.BackgroundColor3 = U.RISKY
    riskBadge.BackgroundTransparency = 0.82
    riskBadge.BorderSizePixel = 0
    riskBadge.Size = UDim2.new(0, 52, 0, 14)
    riskBadge.Position = UDim2.new(1, -86, 0.5, -7)
    riskBadge.Parent = row
    corner(riskBadge, 3); stroke(riskBadge, U.RISKY, 1)

    local badgeLbl = Instance.new("TextLabel")
    badgeLbl.BackgroundTransparency = 1
    badgeLbl.Size = UDim2.new(1, 0, 1, 0)
    badgeLbl.Font = Enum.Font.GothamBold
    badgeLbl.TextSize = 8
    badgeLbl.TextColor3 = U.RISKY
    badgeLbl.Text = "⚠ RISKY"
    badgeLbl.Parent = riskBadge

    local track = Instance.new("Frame")
    track.BackgroundColor3 = initial and U.RISKY or U.CARD2
    track.BorderSizePixel = 0
    track.Size = UDim2.new(0, 28, 0, 13)
    track.Position = UDim2.new(1, -28, 0.5, -6.5)
    track.Parent = row
    corner(track, 6.5)
    local trackStroke = stroke(track, initial and U.RISKY or U.BORDER, 1)

    local knob = Instance.new("Frame")
    knob.BackgroundColor3 = Color3.new(1, 1, 1)
    knob.BorderSizePixel = 0
    knob.Size = UDim2.new(0, 9, 0, 9)
    knob.Position = initial and UDim2.new(1, -11, 0.5, -4.5) or UDim2.new(0, 2, 0.5, -4.5)
    knob.Parent = track
    corner(knob, 4.5)

    local checked = initial

    local function applyState(val)
        checked = val
        local targetPos = checked and UDim2.new(1, -11, 0.5, -4.5) or UDim2.new(0, 2, 0.5, -4.5)
        TweenService:Create(knob, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 12, 0, 7),
        }):Play()
        task.delay(0.08, function()
            TweenService:Create(knob, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                Position = targetPos,
                Size = UDim2.new(0, 9, 0, 9),
            }):Play()
        end)
        TweenService:Create(track, TweenInfo.new(0.18), {BackgroundColor3 = checked and U.RISKY or U.CARD2}):Play()
        TweenService:Create(trackStroke, TweenInfo.new(0.18), {Color = checked and U.RISKY or U.BORDER}):Play()
        if callback then callback(checked) end
    end

    local btn = Instance.new("TextButton")
    btn.BackgroundTransparency = 1
    btn.Size = UDim2.new(1, 0, 1, 0); btn.Text = ""
    btn.AutoButtonColor = false; btn.Parent = row
    btn.MouseButton1Click:Connect(function()
        if not checked then
            showRiskyConfirmModal(label, riskExplanation, function()
                applyState(true)
                Notify("Risky Feature", label .. " enabled. Anticheat risk increased.", "warning", 3)
            end, function()
                -- cancelled
            end)
        else
            applyState(false)
        end
    end)

    row.MouseEnter:Connect(function()
        showTooltip(label, tooltipDesc, row)
        TweenService:Create(lbl, TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            TextColor3 = Color3.fromRGB(255, 215, 90),
            Position = UDim2.new(0, 3, 0, 0),
        }):Play()
        TweenService:Create(riskBadge, TweenInfo.new(0.15), {BackgroundTransparency = 0.65}):Play()
    end)
    row.MouseLeave:Connect(function()
        hideTooltip(row)
        TweenService:Create(lbl, TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            TextColor3 = U.RISKY,
            Position = UDim2.new(0, 0, 0, 0),
        }):Play()
        TweenService:Create(riskBadge, TweenInfo.new(0.15), {BackgroundTransparency = 0.82}):Play()
    end)
    return row
end

local function makeSliderRow(parent, label, minv, maxv, initial, tooltipDesc, callback, fmt)
    if typeof(tooltipDesc) == "function" then
        fmt = callback
        callback = tooltipDesc
        tooltipDesc = nil
    end
    tooltipDesc = tooltipDesc or ("Adjust " .. label .. " value (Range: " .. minv .. " - " .. maxv .. ")")

    local row = Instance.new("Frame")
    row.BackgroundTransparency = 1
    row.Size = UDim2.new(1, 0, 0, 30); row.Parent = parent

    local lbl = Instance.new("TextLabel"); lbl.BackgroundTransparency = 1
    lbl.Size = UDim2.new(0.6, 0, 0, 13); lbl.Position = UDim2.new(0, 0, 0, 0)
    lbl.Font = Enum.Font.Gotham; lbl.TextSize = 11
    lbl.TextColor3 = U.TEXT_DIM; lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Text = label; lbl.Parent = row

    local valLbl = Instance.new("TextLabel"); valLbl.BackgroundTransparency = 1
    valLbl.Size = UDim2.new(0.4, 0, 0, 13); valLbl.Position = UDim2.new(0.6, 0, 0, 0)
    valLbl.Font = Enum.Font.Code; valLbl.TextSize = 11
    valLbl.TextColor3 = U.TEXT; valLbl.TextXAlignment = Enum.TextXAlignment.Right
    valLbl.Text = fmt and fmt(initial) or tostring(initial); valLbl.Parent = row

    local track = Instance.new("Frame")
    track.BackgroundColor3 = U.CARD2; track.BorderSizePixel = 0
    track.Size = UDim2.new(1, 0, 0, 3); track.Position = UDim2.new(0, 0, 0, 20)
    track.Parent = row
    corner(track, 1.5)

    local fill = Instance.new("Frame")
    fill.BackgroundColor3 = U.ACCENT; fill.BorderSizePixel = 0
    fill.Size = UDim2.new((initial - minv) / math.max(1, maxv - minv), 0, 1, 0)
    fill.Parent = track
    corner(fill, 1.5)

    local thumb = Instance.new("Frame")
    thumb.BackgroundColor3 = Color3.new(1,1,1); thumb.BorderSizePixel = 0
    thumb.Size = UDim2.new(0, 9, 0, 9)
    thumb.Position = UDim2.new((initial - minv) / math.max(1, maxv - minv), -4.5, 0.5, -4.5)
    thumb.Parent = track
    corner(thumb, 4.5)

    local drag = false
    local function upd(posX)
        local rel = math.clamp((posX - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        local val = math.floor(minv + rel * (maxv - minv) + 0.5)
        fill.Size = UDim2.new(rel, 0, 1, 0)
        thumb.Position = UDim2.new(rel, -4.5, 0.5, -4.5)
        valLbl.Text = fmt and fmt(val) or tostring(val)
        
        TweenService:Create(valLbl, TweenInfo.new(0.1), {TextColor3 = U.ACCENT_H}):Play()
        task.delay(0.12, function()
            TweenService:Create(valLbl, TweenInfo.new(0.2), {TextColor3 = U.TEXT}):Play()
        end)
        if callback then callback(val) end
    end

    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            drag = true
            upd(input.Position.X)
            TweenService:Create(thumb, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                Size = UDim2.new(0, 14, 0, 14),
                Position = UDim2.new(thumb.Position.X.Scale, -7, 0.5, -7),
            }):Play()
            TweenService:Create(track, TweenInfo.new(0.15), {Size = UDim2.new(1, 0, 0, 5)}):Play()
            TweenService:Create(fill, TweenInfo.new(0.15), {BackgroundColor3 = U.ACCENT_H}):Play()
        end
    end)
    trackConn(UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 and drag then
            drag = false
            TweenService:Create(thumb, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                Size = UDim2.new(0, 9, 0, 9),
                Position = UDim2.new(thumb.Position.X.Scale, -4.5, 0.5, -4.5),
            }):Play()
            TweenService:Create(track, TweenInfo.new(0.2), {Size = UDim2.new(1, 0, 0, 3)}):Play()
            TweenService:Create(fill, TweenInfo.new(0.2), {BackgroundColor3 = U.ACCENT}):Play()
        end
    end))
    trackConn(UserInputService.InputChanged:Connect(function(input)
        if drag and input.UserInputType == Enum.UserInputType.MouseMovement then upd(input.Position.X) end
    end))

    row.MouseEnter:Connect(function()
        showTooltip(label, tooltipDesc, row)
        TweenService:Create(lbl, TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            TextColor3 = U.TEXT,
            Position = UDim2.new(0, 3, 0, 0),
        }):Play()
        TweenService:Create(track, TweenInfo.new(0.15), {Size = UDim2.new(1, 0, 0, 4)}):Play()
    end)
    row.MouseLeave:Connect(function()
        hideTooltip(row)
        TweenService:Create(lbl, TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            TextColor3 = U.TEXT_DIM,
            Position = UDim2.new(0, 0, 0, 0),
        }):Play()
        if not drag then
            TweenService:Create(track, TweenInfo.new(0.15), {Size = UDim2.new(1, 0, 0, 3)}):Play()
        end
    end)
    return row
end

-- ═══════ DROPDOWN WITH ANIMATIONS ═══════
local OpenDropdown = nil
local OpenDropdownArrow = nil

local function closeDropdown()
    if OpenDropdown then
        local dd = OpenDropdown; OpenDropdown = nil
        if OpenDropdownArrow then
            TweenService:Create(OpenDropdownArrow, TweenInfo.new(0.2, Enum.EasingStyle.Quart), {Rotation = 0}):Play()
            OpenDropdownArrow = nil
        end
        TweenService:Create(dd, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Size = UDim2.new(dd.Size.X.Scale, dd.Size.X.Offset, 0, 0)
        }):Play()
        task.delay(0.16, function() if dd then dd:Destroy() end end)
    end
end

local function makeDropdownRow(parent, label, options, initial, tooltipDesc, callback)
    if typeof(tooltipDesc) == "function" then
        callback = tooltipDesc
        tooltipDesc = nil
    end
    tooltipDesc = tooltipDesc or ("Select " .. label .. " configuration option")

    local row = Instance.new("Frame")
    row.BackgroundTransparency = 1
    row.Size = UDim2.new(1, 0, 0, 24); row.Parent = parent

    local lbl = Instance.new("TextLabel"); lbl.BackgroundTransparency = 1
    lbl.Size = UDim2.new(0.5, 0, 1, 0); lbl.Position = UDim2.new(0, 0, 0, 0)
    lbl.Font = Enum.Font.Gotham; lbl.TextSize = 11
    lbl.TextColor3 = U.TEXT_DIM; lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Text = label; lbl.Parent = row

    local btn = Instance.new("TextButton")
    btn.BackgroundColor3 = U.CARD2; btn.BorderSizePixel = 0
    btn.Size = UDim2.new(0, 160, 0, 20); btn.Position = UDim2.new(1, -160, 0.5, -10)
    btn.Font = Enum.Font.Gotham; btn.TextSize = 11
    btn.TextColor3 = U.TEXT; btn.Text = initial
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.AutoButtonColor = false; btn.Parent = row
    corner(btn, 4)
    local btnStroke = stroke(btn, U.BORDER, 1)
    local pad = Instance.new("UIPadding", btn); pad.PaddingLeft = UDim.new(0, 8)

    local arrow = Instance.new("TextLabel")
    arrow.BackgroundTransparency = 1
    arrow.Size = UDim2.new(0, 14, 1, 0); arrow.Position = UDim2.new(1, -16, 0, 0)
    arrow.Font = Enum.Font.GothamBold; arrow.TextSize = 10
    arrow.TextColor3 = U.TEXT_DIM; arrow.Text = "v"
    arrow.Parent = btn

    local function buildPopup()
        if OpenDropdown then closeDropdown() end
        local popup = Instance.new("Frame")
        popup.BackgroundColor3 = U.CARD
        popup.BackgroundTransparency = 0.05
        popup.BorderSizePixel = 0
        popup.Size = UDim2.new(0, 160, 0, 0)
        popup.Position = UDim2.new(0, btn.AbsolutePosition.X - Window.AbsolutePosition.X, 0, btn.AbsolutePosition.Y - Window.AbsolutePosition.Y + 22)
        popup.ZIndex = 100; popup.ClipsDescendants = true
        popup.Parent = Window
        corner(popup, 5); stroke(popup, U.BORDER_HI, 1)

        TweenService:Create(arrow, TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Rotation = 180}):Play()
        OpenDropdownArrow = arrow

        local total = 0
        for i, opt in ipairs(options) do
            local optBtn = Instance.new("TextButton")
            optBtn.BackgroundColor3 = U.CARD; optBtn.BackgroundTransparency = 1
            optBtn.BorderSizePixel = 0
            optBtn.Size = UDim2.new(1, -4, 0, 22); optBtn.Position = UDim2.new(0, 2, 0, 2 + (i - 1) * 22)
            optBtn.Font = Enum.Font.Gotham; optBtn.TextSize = 11
            optBtn.TextColor3 = (opt == btn.Text) and U.ACCENT or U.TEXT
            optBtn.Text = tostring(opt)
            optBtn.TextXAlignment = Enum.TextXAlignment.Left
            optBtn.AutoButtonColor = false; optBtn.ZIndex = 101; optBtn.Parent = popup
            corner(optBtn, 3)
            local opad = Instance.new("UIPadding", optBtn); opad.PaddingLeft = UDim.new(0, 8)

            optBtn.MouseEnter:Connect(function()
                TweenService:Create(optBtn, TweenInfo.new(0.12), {BackgroundTransparency = 0, BackgroundColor3 = U.CARD_HOV}):Play()
                TweenService:Create(opad, TweenInfo.new(0.12), {PaddingLeft = UDim.new(0, 12)}):Play()
            end)
            optBtn.MouseLeave:Connect(function()
                TweenService:Create(optBtn, TweenInfo.new(0.12), {BackgroundTransparency = 1}):Play()
                TweenService:Create(opad, TweenInfo.new(0.12), {PaddingLeft = UDim.new(0, 8)}):Play()
            end)
            optBtn.MouseButton1Click:Connect(function()
                btn.Text = tostring(opt)
                if callback then callback(opt) end
                closeDropdown()
            end)
            total = total + 22
        end
        local targetSize = total + 4
        OpenDropdown = popup
        TweenService:Create(popup, TweenInfo.new(0.24, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 160, 0, targetSize)
        }):Play()
    end

    btn.MouseButton1Click:Connect(function()
        if OpenDropdown then closeDropdown() else buildPopup() end
    end)
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = U.CARD_HOV}):Play()
        TweenService:Create(btnStroke, TweenInfo.new(0.15), {Color = U.ACCENT}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = U.CARD2}):Play()
        TweenService:Create(btnStroke, TweenInfo.new(0.15), {Color = U.BORDER}):Play()
    end)
    row.MouseEnter:Connect(function()
        showTooltip(label, tooltipDesc, row)
        TweenService:Create(lbl, TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            TextColor3 = U.TEXT,
            Position = UDim2.new(0, 3, 0, 0),
        }):Play()
    end)
    row.MouseLeave:Connect(function()
        hideTooltip(row)
        TweenService:Create(lbl, TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            TextColor3 = U.TEXT_DIM,
            Position = UDim2.new(0, 0, 0, 0),
        }):Play()
    end)
    return row
end

-- ═══════ UPGRADED HSV COLOR PICKER WITH RGB & HEX COPY ═══════
local OpenColorPicker = nil

local function closeColorPicker()
    if OpenColorPicker then
        local cp = OpenColorPicker; OpenColorPicker = nil
        TweenService:Create(cp, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Size = UDim2.new(0, 0, 0, 0)
        }):Play()
        task.delay(0.16, function() if cp then cp:Destroy() end end)
    end
end

local function openColorPicker(anchorX, anchorY, initial, callback)
    if OpenColorPicker then closeColorPicker() end
    local h0, s0, v0 = initial:ToHSV()

    local picker = Instance.new("Frame")
    picker.BackgroundColor3 = U.BG_GLASS
    picker.BackgroundTransparency = 0.08
    picker.BorderSizePixel = 0
    picker.Size = UDim2.new(0, 0, 0, 0)
    picker.Position = UDim2.new(0, anchorX, 0, anchorY)
    picker.ZIndex = 200; picker.ClipsDescendants = true
    picker.Parent = Window
    corner(picker, 8); stroke(picker, U.BORDER_HI, 1.5)
    OpenColorPicker = picker

    local topSheen = Instance.new("Frame", picker)
    topSheen.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    topSheen.BackgroundTransparency = 0.92
    topSheen.BorderSizePixel = 0
    topSheen.Size = UDim2.new(1, 0, 0, 1.5)
    topSheen.Position = UDim2.new(0, 0, 0, 0)
    topSheen.ZIndex = 201

    TweenService:Create(picker, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 240, 0, 250)
    }):Play()

    -- SV Saturation-Value box
    local sv = Instance.new("Frame")
    sv.BackgroundColor3 = Color3.fromHSV(h0, 1, 1); sv.BorderSizePixel = 0
    sv.Size = UDim2.new(1, -16, 0, 105); sv.Position = UDim2.new(0, 8, 0, 8)
    sv.ClipsDescendants = true; sv.ZIndex = 202; sv.Parent = picker
    corner(sv, 5)

    local whiteOv = Instance.new("Frame")
    whiteOv.BackgroundColor3 = Color3.new(1,1,1); whiteOv.BorderSizePixel = 0
    whiteOv.Size = UDim2.new(1,0,1,0); whiteOv.ZIndex = 203; whiteOv.Parent = sv
    local wg = Instance.new("UIGradient")
    wg.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1)})
    wg.Parent = whiteOv

    local blackOv = Instance.new("Frame")
    blackOv.BackgroundColor3 = Color3.new(0,0,0); blackOv.BorderSizePixel = 0
    blackOv.Size = UDim2.new(1,0,1,0); blackOv.ZIndex = 204; blackOv.Parent = sv
    local bg = Instance.new("UIGradient")
    bg.Rotation = 90
    bg.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0)})
    bg.Parent = blackOv

    local svCursor = Instance.new("Frame")
    svCursor.BackgroundTransparency = 1; svCursor.BorderSizePixel = 0
    svCursor.Size = UDim2.new(0, 10, 0, 10)
    svCursor.Position = UDim2.new(s0, -5, 1 - v0, -5)
    svCursor.ZIndex = 205; svCursor.Parent = sv
    corner(svCursor, 5); stroke(svCursor, Color3.new(1,1,1), 1.5)

    -- Hue Bar
    local hueBar = Instance.new("Frame")
    hueBar.BackgroundColor3 = Color3.new(1,1,1); hueBar.BorderSizePixel = 0
    hueBar.Size = UDim2.new(1, -16, 0, 13); hueBar.Position = UDim2.new(0, 8, 0, 119)
    hueBar.ZIndex = 202; hueBar.Parent = picker
    corner(hueBar, 4)

    local hg = Instance.new("UIGradient")
    hg.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
        ColorSequenceKeypoint.new(1/6, Color3.fromRGB(255, 255, 0)),
        ColorSequenceKeypoint.new(2/6, Color3.fromRGB(0, 255, 0)),
        ColorSequenceKeypoint.new(3/6, Color3.fromRGB(0, 255, 255)),
        ColorSequenceKeypoint.new(4/6, Color3.fromRGB(0, 0, 255)),
        ColorSequenceKeypoint.new(5/6, Color3.fromRGB(255, 0, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)),
    })
    hg.Parent = hueBar

    local hueCursor = Instance.new("Frame")
    hueCursor.BackgroundTransparency = 1; hueCursor.BorderSizePixel = 0
    hueCursor.Size = UDim2.new(0, 4, 1, 0)
    hueCursor.Position = UDim2.new(h0, -2, 0, 0)
    hueCursor.ZIndex = 203; hueCursor.Parent = hueBar
    corner(hueCursor, 1); stroke(hueCursor, Color3.new(1,1,1), 1.5)

    -- 10 Neon Tactical Presets
    local presetRow = Instance.new("Frame")
    presetRow.BackgroundTransparency = 1; presetRow.BorderSizePixel = 0
    presetRow.Size = UDim2.new(1, -16, 0, 15); presetRow.Position = UDim2.new(0, 8, 0, 138)
    presetRow.ZIndex = 202; presetRow.Parent = picker

    local presets = {
        Color3.fromRGB(56, 130, 255),  -- Electric Blue
        Color3.fromRGB(0, 230, 255),   -- Cyan
        Color3.fromRGB(60, 245, 170),  -- Mint Green
        Color3.fromRGB(50, 225, 120),  -- Lime
        Color3.fromRGB(255, 190, 45),  -- Amber
        Color3.fromRGB(255, 120, 40),  -- Orange
        Color3.fromRGB(235, 60, 60),   -- Red
        Color3.fromRGB(255, 80, 160),  -- Pink
        Color3.fromRGB(180, 85, 255),  -- Purple
        Color3.fromRGB(245, 248, 255), -- White
    }

    -- Split Preview (Old vs New)
    local previewBox = Instance.new("Frame")
    previewBox.BackgroundColor3 = U.CARD2; previewBox.BorderSizePixel = 0
    previewBox.Size = UDim2.new(0, 34, 0, 22); previewBox.Position = UDim2.new(0, 8, 0, 160)
    previewBox.ZIndex = 202; previewBox.ClipsDescendants = true; previewBox.Parent = picker
    corner(previewBox, 4); stroke(previewBox, U.BORDER_HI, 1)

    local oldHalf = Instance.new("Frame")
    oldHalf.BackgroundColor3 = initial; oldHalf.BorderSizePixel = 0
    oldHalf.Size = UDim2.new(0.5, 0, 1, 0); oldHalf.Position = UDim2.new(0, 0, 0, 0)
    oldHalf.ZIndex = 203; oldHalf.Parent = previewBox

    local newHalf = Instance.new("Frame")
    newHalf.BackgroundColor3 = initial; newHalf.BorderSizePixel = 0
    newHalf.Size = UDim2.new(0.5, 0, 1, 0); newHalf.Position = UDim2.new(0.5, 0, 0, 0)
    newHalf.ZIndex = 203; newHalf.Parent = previewBox

    -- HEX & RGB displays
    local hexLbl = Instance.new("TextLabel")
    hexLbl.BackgroundColor3 = U.CARD2; hexLbl.BorderSizePixel = 0
    hexLbl.Size = UDim2.new(0, 75, 0, 22); hexLbl.Position = UDim2.new(0, 48, 0, 160)
    hexLbl.Font = Enum.Font.Code; hexLbl.TextSize = 10
    hexLbl.TextColor3 = U.TEXT; hexLbl.Text = "#" .. string.upper(initial:ToHex())
    hexLbl.ZIndex = 202; hexLbl.Parent = picker
    corner(hexLbl, 4); stroke(hexLbl, U.BORDER, 1)

    local copyBtn = Instance.new("TextButton")
    copyBtn.BackgroundColor3 = U.CARD2; copyBtn.BorderSizePixel = 0
    copyBtn.Size = UDim2.new(0, 44, 0, 22); copyBtn.Position = UDim2.new(0, 128, 0, 160)
    copyBtn.Font = Enum.Font.GothamBold; copyBtn.TextSize = 9
    copyBtn.TextColor3 = U.TEXT_DIM; copyBtn.Text = "COPY"
    copyBtn.AutoButtonColor = false; copyBtn.ZIndex = 202; copyBtn.Parent = picker
    corner(copyBtn, 4); stroke(copyBtn, U.BORDER, 1)

    copyBtn.MouseEnter:Connect(function()
        TweenService:Create(copyBtn, TweenInfo.new(0.12), {BackgroundColor3 = U.CARD_HOV, TextColor3 = U.TEXT}):Play()
    end)
    copyBtn.MouseLeave:Connect(function()
        TweenService:Create(copyBtn, TweenInfo.new(0.12), {BackgroundColor3 = U.CARD2, TextColor3 = U.TEXT_DIM}):Play()
    end)

    local doneBtn = Instance.new("TextButton")
    doneBtn.BackgroundColor3 = U.ACCENT; doneBtn.BorderSizePixel = 0
    doneBtn.Size = UDim2.new(0, 52, 0, 22); doneBtn.Position = UDim2.new(1, -60, 0, 160)
    doneBtn.Font = Enum.Font.GothamBold; doneBtn.TextSize = 10
    doneBtn.TextColor3 = Color3.new(1,1,1); doneBtn.Text = "DONE"
    doneBtn.AutoButtonColor = false; doneBtn.ZIndex = 202; doneBtn.Parent = picker
    corner(doneBtn, 4)
    doneBtn.MouseButton1Click:Connect(closeColorPicker)

    doneBtn.MouseEnter:Connect(function()
        TweenService:Create(doneBtn, TweenInfo.new(0.12), {BackgroundColor3 = U.ACCENT_H}):Play()
    end)
    doneBtn.MouseLeave:Connect(function()
        TweenService:Create(doneBtn, TweenInfo.new(0.12), {BackgroundColor3 = U.ACCENT}):Play()
    end)

    local rgbLbl = Instance.new("TextLabel")
    rgbLbl.BackgroundTransparency = 1
    rgbLbl.Size = UDim2.new(1, -16, 0, 16); rgbLbl.Position = UDim2.new(0, 8, 0, 190)
    rgbLbl.Font = Enum.Font.Code; rgbLbl.TextSize = 9
    rgbLbl.TextColor3 = U.TEXT_MUTE; rgbLbl.TextXAlignment = Enum.TextXAlignment.Left
    rgbLbl.Text = string.format("R: %d  G: %d  B: %d", math.floor(initial.R * 255), math.floor(initial.G * 255), math.floor(initial.B * 255))
    rgbLbl.ZIndex = 202; rgbLbl.Parent = picker

    local curH, curS, curV = h0, s0, v0
    local function updateColor()
        local c = Color3.fromHSV(curH, curS, curV)
        sv.BackgroundColor3 = Color3.fromHSV(curH, 1, 1)
        newHalf.BackgroundColor3 = c
        hexLbl.Text = "#" .. string.upper(c:ToHex())
        rgbLbl.Text = string.format("R: %d  G: %d  B: %d", math.floor(c.R * 255), math.floor(c.G * 255), math.floor(c.B * 255))
        if callback then callback(c) end
    end

    copyBtn.MouseButton1Click:Connect(function()
        local hexStr = "#" .. string.upper(Color3.fromHSV(curH, curS, curV):ToHex())
        pcall(function()
            if setclipboard then setclipboard(hexStr) end
        end)
        Notify("Color Picker", "Copied " .. hexStr .. " to clipboard!", "info", 2)
    end)

    for i, col in ipairs(presets) do
        local pbtn = Instance.new("TextButton")
        pbtn.BackgroundColor3 = col; pbtn.BorderSizePixel = 0
        pbtn.Size = UDim2.new(0, 19, 0, 14); pbtn.Position = UDim2.new(0, (i - 1) * 22.5, 0, 0)
        pbtn.Text = ""; pbtn.AutoButtonColor = false; pbtn.ZIndex = 203; pbtn.Parent = presetRow
        corner(pbtn, 3); stroke(pbtn, U.BORDER_HI, 1)
        pbtn.MouseButton1Click:Connect(function()
            local ph, ps, pv = col:ToHSV()
            curH, curS, curV = ph, ps, pv
            svCursor.Position = UDim2.new(ps, -5, 1 - pv, -5)
            hueCursor.Position = UDim2.new(ph, -2, 0, 0)
            updateColor()
        end)
    end

    local svDrag = false
    local function updSV(x, y)
        local relX = math.clamp((x - sv.AbsolutePosition.X) / sv.AbsoluteSize.X, 0, 1)
        local relY = math.clamp((y - sv.AbsolutePosition.Y) / sv.AbsoluteSize.Y, 0, 1)
        curS = relX; curV = 1 - relY
        svCursor.Position = UDim2.new(relX, -5, relY, -5)
        updateColor()
    end
    sv.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then svDrag = true; updSV(input.Position.X, input.Position.Y) end
    end)
    trackConn(UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then svDrag = false end
    end))
    trackConn(UserInputService.InputChanged:Connect(function(input)
        if svDrag and input.UserInputType == Enum.UserInputType.MouseMovement then updSV(input.Position.X, input.Position.Y) end
    end))

    local hDrag = false
    local function updH(x)
        local relX = math.clamp((x - hueBar.AbsolutePosition.X) / hueBar.AbsoluteSize.X, 0, 1)
        curH = relX
        hueCursor.Position = UDim2.new(relX, -2, 0, 0)
        updateColor()
    end
    hueBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then hDrag = true; updH(input.Position.X) end
    end)
    trackConn(UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then hDrag = false end
    end))
    trackConn(UserInputService.InputChanged:Connect(function(input)
        if hDrag and input.UserInputType == Enum.UserInputType.MouseMovement then updH(input.Position.X) end
    end))
end

local function makeColorRow(parent, label, initial, tooltipDesc, callback)
    if typeof(tooltipDesc) == "function" then
        callback = tooltipDesc
        tooltipDesc = nil
    end
    tooltipDesc = tooltipDesc or ("Customize color for " .. label)

    local row = Instance.new("Frame")
    row.BackgroundTransparency = 1
    row.Size = UDim2.new(1, 0, 0, 22); row.Parent = parent

    local lbl = Instance.new("TextLabel"); lbl.BackgroundTransparency = 1
    lbl.Size = UDim2.new(0.6, 0, 1, 0); lbl.Position = UDim2.new(0, 0, 0, 0)
    lbl.Font = Enum.Font.Gotham; lbl.TextSize = 11
    lbl.TextColor3 = U.TEXT_DIM; lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Text = label; lbl.Parent = row

    local swatch = Instance.new("TextButton")
    swatch.BackgroundColor3 = initial; swatch.BorderSizePixel = 0
    swatch.Size = UDim2.new(0, 30, 0, 15); swatch.Position = UDim2.new(1, -30, 0.5, -7.5)
    swatch.Text = ""; swatch.AutoButtonColor = false; swatch.Parent = row
    corner(swatch, 3)
    local swatchStroke = stroke(swatch, U.BORDER_HI, 1)

    swatch.MouseEnter:Connect(function()
        TweenService:Create(swatch, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 34, 0, 17),
            Position = UDim2.new(1, -32, 0.5, -8.5),
        }):Play()
        TweenService:Create(swatchStroke, TweenInfo.new(0.15), {Color = U.ACCENT}):Play()
    end)
    swatch.MouseLeave:Connect(function()
        TweenService:Create(swatch, TweenInfo.new(0.15), {
            Size = UDim2.new(0, 30, 0, 15),
            Position = UDim2.new(1, -30, 0.5, -7.5),
        }):Play()
        TweenService:Create(swatchStroke, TweenInfo.new(0.15), {Color = U.BORDER_HI}):Play()
    end)

    swatch.MouseButton1Click:Connect(function()
        local ax = swatch.AbsolutePosition.X - Window.AbsolutePosition.X - 110
        local ay = swatch.AbsolutePosition.Y - Window.AbsolutePosition.Y + 20
        ax = math.clamp(ax, 6, Window.AbsoluteSize.X - 250)
        ay = math.clamp(ay, 6, Window.AbsoluteSize.Y - 260)
        openColorPicker(ax, ay, swatch.BackgroundColor3, function(c)
            swatch.BackgroundColor3 = c
            if callback then callback(c) end
        end)
    end)

    row.MouseEnter:Connect(function()
        showTooltip(label, tooltipDesc, row)
        TweenService:Create(lbl, TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            TextColor3 = U.TEXT,
            Position = UDim2.new(0, 3, 0, 0),
        }):Play()
    end)
    row.MouseLeave:Connect(function()
        hideTooltip(row)
        TweenService:Create(lbl, TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            TextColor3 = U.TEXT_DIM,
            Position = UDim2.new(0, 0, 0, 0),
        }):Play()
    end)
    return row
end
-- ═══════════════════════════════════════════════════════════
-- PAGE BUILDERS
-- ═══════════════════════════════════════════════════════════
local function buildCombatPage(sf)
    local b_general = makeSection(sf, "Combat Visuals")
    makeToggleRow(b_general, "Aim Line (Snapline)", Config.Combat.AimLine,
        "Draws a snapline from center of FOV directly to the locked target. Wall check active: Green = visible, Red = behind wall; otherwise White.",
        function(v)
            Config.Combat.AimLine = v
            Notify("Combat Visuals", v and "Aim Line Enabled" or "Aim Line Disabled", "info", 2)
        end)

    local b = makeSection(sf, "Silent Aim")
    makeRiskyToggleRow(b, "Enable Silent Aim", Config.SilentAim.Enabled,
        "Intercepts bullet rays in memory to hit targets without camera movement.",
        "Silent Aim redirects bullet vectors directly at targets. Highly detectable on games with server-side trajectory validation or bullet simulation checks.",
        function(v)
            Config.SilentAim.Enabled = v
            Notify("Silent Aim", v and "Silent Aim Enabled" or "Silent Aim Disabled", v and "success" or "warning", 2)
        end)
    makeDropdownRow(b, "Target Part", {"Head","UpperTorso","HumanoidRootPart","Torso","Random"}, Config.SilentAim.TargetPart,
        "Selects which enemy bone to lock onto.", function(v)
        Config.SilentAim.TargetPart = v
    end)
    makeSliderRow(b, "FOV", 10, 600, Config.SilentAim.FOV, "Maximum screen radius to acquire silent aim targets.", function(v) Config.SilentAim.FOV = v end)
    makeSliderRow(b, "Hit Chance", 1, 100, Config.SilentAim.HitChance, "Percentage chance for bullet redirection to hit.", function(v) Config.SilentAim.HitChance = v end, function(v) return v .. "%" end)
    makeToggleRow(b, "Wall Check", Config.SilentAim.WallCheck, "Validates line of sight before redirecting bullets.", function(v) Config.SilentAim.WallCheck = v end)
    makeToggleRow(b, "Team Check", Config.SilentAim.TeamCheck, "Prevents targeting teammates or friendly units.", function(v) Config.SilentAim.TeamCheck = v end)
    makeToggleRow(b, "Show FOV", Config.SilentAim.ShowFOV, "Renders visual FOV circle on screen.", function(v) Config.SilentAim.ShowFOV = v end)
    makeColorRow(b, "FOV Color", Config.SilentAim.FOVColor, "Color of the silent aim FOV circle.", function(v) Config.SilentAim.FOVColor = v end)

    local b_aim = makeSection(sf, "Aimbot")
    makeRiskyToggleRow(b_aim, "Enable Aimbot", Config.Aimbot.Enabled,
        "Smoothly snaps camera crosshair to enemy using hardware mouse movement",
        "Hardware Mouse Aimbot simulates raw mouse movements to track targets. Low smoothness values can trigger anticheat angle/acceleration heuristics and spectator reports.",
        function(v)
            Config.Aimbot.Enabled = v
            Notify("Aimbot", v and "Mouse Aimbot Enabled (Hold Right Click)" or "Aimbot Disabled", v and "success" or "warning", 2.5)
        end)
    makeDropdownRow(b_aim, "Target Part", {"Head","UpperTorso","HumanoidRootPart","Torso","Random"}, Config.Aimbot.TargetPart,
        "Body part to aim towards when holding Right Mouse Button.", function(v)
        Config.Aimbot.TargetPart = v
    end)
    makeSliderRow(b_aim, "FOV", 10, 500, Config.Aimbot.FOV, "Maximum screen distance from mouse to target.", function(v) Config.Aimbot.FOV = v end)
    makeSliderRow(b_aim, "Smoothness", 1, 20, Config.Aimbot.Smoothness, "Movement interpolation divisor. Higher is smoother and looks more legit.", function(v) Config.Aimbot.Smoothness = v end)
    makeSliderRow(b_aim, "Prediction", 0, 30, Config.Aimbot.Prediction, "Velocity compensation for moving targets.", function(v) Config.Aimbot.Prediction = v end, function(v) return string.format("%.2fs", v / 100) end)
    makeToggleRow(b_aim, "Wall Check", Config.Aimbot.WallCheck, "Only locks on targets visible through obstacles.", function(v) Config.Aimbot.WallCheck = v end)
    makeToggleRow(b_aim, "Team Check", Config.Aimbot.TeamCheck, "Ignores players on your team.", function(v) Config.Aimbot.TeamCheck = v end)
    makeToggleRow(b_aim, "Show FOV", Config.Aimbot.ShowFOV, "Draws amber FOV circle centered at your mouse cursor.", function(v) Config.Aimbot.ShowFOV = v end)
    makeColorRow(b_aim, "FOV Color", Config.Aimbot.FOVColor, "Color for the aimbot mouse FOV circle.", function(v) Config.Aimbot.FOVColor = v end)

    local b2 = makeSection(sf, "Aim Magnet")
    makeRiskyToggleRow(b2, "Enable Magnet", Config.AimMagnet.Enabled,
        "Warp and magnetize target CFrame directly in front of crosshair.",
        "Aim Magnet directly teleports enemy character CFrames in front of your camera. Easily detected by server anticheat velocity & position validation. High risk of immediate kicks.",
        function(v)
            Config.AimMagnet.Enabled = v
            if not v then cleanupPullState() end
            Notify("Aim Magnet", v and "Aim Magnet Enabled" or "Aim Magnet Disabled", v and "success" or "warning", 2)
        end)
    makeToggleRow(b2, "Hold LMB", Config.AimMagnet.HoldLMB, "Magnet only pulls when holding Left Mouse Button.", function(v) Config.AimMagnet.HoldLMB = v end)
    makeSliderRow(b2, "Distance", 2, 20, Config.AimMagnet.Distance, "Distance in studs in front of camera to hold the enemy.", function(v) Config.AimMagnet.Distance = v end)
    makeSliderRow(b2, "Trigger FOV", 50, 800, Config.AimMagnet.TriggerFOV, "Screen radius to lock pull target.", function(v) Config.AimMagnet.TriggerFOV = v end)
    makeSliderRow(b2, "Max Range", 50, 2000, Config.AimMagnet.MaxRange, "Maximum 3D distance to target.", function(v) Config.AimMagnet.MaxRange = v end)
    makeToggleRow(b2, "Team Check", Config.AimMagnet.TeamCheck, "Avoids pulling teammates.", function(v) Config.AimMagnet.TeamCheck = v end)
    makeToggleRow(b2, "Ignore Walls", Config.AimMagnet.NoWallCheck, "Allows pulling targets through walls and objects.", function(v) Config.AimMagnet.NoWallCheck = v end)
    makeToggleRow(b2, "Show Box", Config.AimMagnet.ShowBox, "Draws bounding box on currently magnetized target.", function(v) Config.AimMagnet.ShowBox = v end)
    makeColorRow(b2, "Box Color", Config.AimMagnet.BoxColor, "Color of magnetized bounding box.", function(v) Config.AimMagnet.BoxColor = v end)
    makeToggleRow(b2, "Show Label", Config.AimMagnet.ShowLabel, "Displays target name above head.", function(v) Config.AimMagnet.ShowLabel = v end)
    makeColorRow(b2, "Label Color", Config.AimMagnet.LabelColor, "Color of magnetized target name label.", function(v) Config.AimMagnet.LabelColor = v end)
    makeToggleRow(b2, "Show Highlight", Config.AimMagnet.ShowHighlight, "Renders glowing character highlight on pulled player.", function(v) Config.AimMagnet.ShowHighlight = v end)
    makeColorRow(b2, "Highlight Color", Config.AimMagnet.HighlightColor, "Color of magnetized highlight effect.", function(v) Config.AimMagnet.HighlightColor = v end)
end

local function buildVisualPage(sf)
    local b = makeSection(sf, "ESP Settings")
    makeToggleRow(b, "Enable ESP", Config.ESP.Enabled, function(v)
        Config.ESP.Enabled = v
        Notify("ESP", v and "ESP Enabled" or "ESP Disabled", v and "success" or "warning", 2)
    end)
    makeDropdownRow(b, "ESP Style", {"Style 1", "Style 2"}, Config.ESP.Style, function(v)
        Config.ESP.Style = v
        Notify("ESP Style", "Switched to " .. v .. (v == "Style 2" and " (Banner Header)" or " (Classic)"), "info", 2.5)
    end)
    makeToggleRow(b, "Enemy Count Box", Config.ESP.ShowEspCount, "Shows rounded frosted glass enemy counter widget at top center of screen.", function(v)
        Config.ESP.ShowEspCount = v
        if EspCountGui then EspCountGui.Visible = v end
    end)
    makeToggleRow(b, "Aim Warning", Config.ESP.ShowAimWarning, "Shows warning icon & text when an enemy is aiming directly at you.", function(v)
        Config.ESP.ShowAimWarning = v
    end)
    makeSliderRow(b, "Range", 100, 5000, Config.ESP.Range, "Maximum distance to render player visual boxes and info.", function(v) Config.ESP.Range = v end, function(v) return v .. "m" end)
    makeToggleRow(b, "Boxes", Config.ESP.Boxes, "Draw bounding boxes around targets.", function(v) Config.ESP.Boxes = v end)
    makeDropdownRow(b, "Box Style", {"Full Box","Corner Box"}, Config.ESP.BoxType, "2D full outline or tactical corner brackets.", function(v) Config.ESP.BoxType = v end)
    makeToggleRow(b, "Box Fill", Config.ESP.BoxFill, "Fill bounding box interior with translucent color.", function(v) Config.ESP.BoxFill = v end)
    makeColorRow(b, "Fill Color", Config.ESP.BoxFillColor, "Color for bounding box fill.", function(v) Config.ESP.BoxFillColor = v end)
    makeToggleRow(b, "Names", Config.ESP.Names, "Displays player username & display name.", function(v) Config.ESP.Names = v end)
    makeColorRow(b, "Name Color", Config.ESP.NameColor, "Color of player name tags.", function(v) Config.ESP.NameColor = v end)
    makeToggleRow(b, "Distance", Config.ESP.Distance, "Shows distance in meters/studs to target.", function(v) Config.ESP.Distance = v end)
    makeColorRow(b, "Distance Color", Config.ESP.DistanceColor, "Color of distance tags.", function(v) Config.ESP.DistanceColor = v end)
    makeToggleRow(b, "Health Bar", Config.ESP.HealthBar, "Vertical dynamic health bar indicator.", function(v) Config.ESP.HealthBar = v end)
    makeToggleRow(b, "Health Text", Config.ESP.HealthText, "Displays exact HP number.", function(v) Config.ESP.HealthText = v end)
    makeToggleRow(b, "Weapon Info", Config.ESP.WeaponInfo, "Displays equipped tool/weapon name.", function(v) Config.ESP.WeaponInfo = v end)
    makeToggleRow(b, "Skeleton", Config.ESP.Skeleton, "Draws player skeleton rig bones.", function(v) Config.ESP.Skeleton = v end)
    makeColorRow(b, "Skeleton Color", Config.ESP.SkeletonColor, "Color of skeleton bones.", function(v) Config.ESP.SkeletonColor = v end)
    makeToggleRow(b, "Tracers", Config.ESP.Tracers, "Draws snapline from screen to player.", function(v) Config.ESP.Tracers = v end)
    makeDropdownRow(b, "Tracer Origin", {"Bottom","Middle","Top"}, Config.ESP.TracerOrigin, "Screen origin point for tracers.", function(v) Config.ESP.TracerOrigin = v end)
    makeToggleRow(b, "Offscreen Arrows", Config.ESP.OffscreenArrows, "360-degree tactical directional arrows pointing toward off-screen enemies.", function(v) Config.ESP.OffscreenArrows = v end)
    makeSliderRow(b, "Arrow Size", 10, 32, Config.ESP.ArrowSize, "Size of the off-screen directional arrows.", function(v) Config.ESP.ArrowSize = v end)

    local b2 = makeSection(sf, "Filters")
    makeToggleRow(b2, "Team Check", Config.ESP.TeamCheck, function(v) Config.ESP.TeamCheck = v end)
    makeToggleRow(b2, "Team Colors", Config.ESP.TeamColors, function(v) Config.ESP.TeamColors = v end)
    makeToggleRow(b2, "Wall Check", Config.ESP.WallCheck, function(v) Config.ESP.WallCheck = v end)

    local b3 = makeSection(sf, "Position Offset")
    makeSliderRow(b3, "ESP Pos X", -500, 500, Config.ESP.EspPosX, function(v) Config.ESP.EspPosX = v end)
    makeSliderRow(b3, "ESP Pos Y", -500, 500, Config.ESP.EspPosY, function(v) Config.ESP.EspPosY = v end)
    makeSliderRow(b3, "Draw Pos X", -500, 500, Config.ESP.DrawPosX, function(v) Config.ESP.DrawPosX = v end)
    makeSliderRow(b3, "Draw Pos Y", -500, 500, Config.ESP.DrawPosY, function(v) Config.ESP.DrawPosY = v end)

    local b4 = makeSection(sf, "Chams (Per-Bone)")
    makeToggleRow(b4, "Enable Chams", Config.Chams.Enabled, function(v)
        Config.Chams.Enabled = v
        Notify("Chams", v and "Chams Enabled" or "Chams Disabled", v and "success" or "warning", 2)
    end)
    makeToggleRow(b4, "Team Check", Config.Chams.TeamCheck, function(v) Config.Chams.TeamCheck = v end)
    makeToggleRow(b4, "Wall Check", Config.Chams.WallCheck, function(v) Config.Chams.WallCheck = v end)
    makeColorRow(b4, "Visible Fill", Config.Chams.VisibleFill, function(v) Config.Chams.VisibleFill = v end)
    makeColorRow(b4, "Invisible Fill", Config.Chams.InvisibleFill, function(v) Config.Chams.InvisibleFill = v end)
    makeSliderRow(b4, "Fill Transp", 0, 100, math.floor(Config.Chams.FillTransparency * 100), function(v) Config.Chams.FillTransparency = v / 100 end, function(v) return v .. "%" end)

    local b5 = makeSection(sf, "Radar")
    makeToggleRow(b5, "Enable Radar", Config.Radar.Enabled, function(v)
        Config.Radar.Enabled = v
        Notify("Radar", v and "Radar Enabled" or "Radar Disabled", v and "success" or "warning", 2)
    end)
    makeDropdownRow(b5, "Shape", {"Square","Circle"}, Config.Radar.Shape, function(v) Config.Radar.Shape = v end)
    makeSliderRow(b5, "Size", 100, 400, Config.Radar.Size, function(v) Config.Radar.Size = v end)
    makeSliderRow(b5, "Range", 50, 1000, Config.Radar.Range, function(v) Config.Radar.Range = v end)
    makeSliderRow(b5, "Pos X", 0, 1500, Config.Radar.PosX, function(v) Config.Radar.PosX = v end)
    makeSliderRow(b5, "Pos Y", 0, 900, Config.Radar.PosY, function(v) Config.Radar.PosY = v end)
    makeToggleRow(b5, "Show Self", Config.Radar.ShowSelf, function(v) Config.Radar.ShowSelf = v end)
    makeToggleRow(b5, "Show Blips", Config.Radar.ShowBlips, function(v) Config.Radar.ShowBlips = v end)
    makeToggleRow(b5, "Show Cone", Config.Radar.ShowCone, function(v) Config.Radar.ShowCone = v end)
    makeToggleRow(b5, "Show Rings", Config.Radar.ShowRings, function(v) Config.Radar.ShowRings = v end)
    makeToggleRow(b5, "Show Compass", Config.Radar.ShowCompass, function(v) Config.Radar.ShowCompass = v end)
    makeToggleRow(b5, "Fade Edge", Config.Radar.FadeEdge, function(v) Config.Radar.FadeEdge = v end)
    makeToggleRow(b5, "Rotate with View", Config.Radar.Rotate, function(v) Config.Radar.Rotate = v end)
    makeToggleRow(b5, "Team Colors", Config.Radar.TeamColors, function(v) Config.Radar.TeamColors = v end)
    makeColorRow(b5, "Background", Config.Radar.BgColor, function(v) Config.Radar.BgColor = v end)
    makeSliderRow(b5, "Bg Alpha", 0, 100, math.floor(Config.Radar.BgAlpha * 100), function(v) Config.Radar.BgAlpha = v / 100 end, function(v) return v .. "%" end)
    makeColorRow(b5, "Border", Config.Radar.BorderColor, function(v) Config.Radar.BorderColor = v end)
    makeColorRow(b5, "Blip", Config.Radar.BlipColor, function(v) Config.Radar.BlipColor = v end)
    makeColorRow(b5, "Self", Config.Radar.SelfColor, function(v) Config.Radar.SelfColor = v end)
    makeSliderRow(b5, "Blip Size", 1, 10, Config.Radar.BlipSize, function(v) Config.Radar.BlipSize = v end)
end

-- ═══════ CONFIG PAGE ═══════
local ConfigUI = {}
local function buildConfigPage(sf)
    local b = makeSection(sf, "Config Manager")

    local nameRow = Instance.new("Frame")
    nameRow.BackgroundTransparency = 1
    nameRow.Size = UDim2.new(1, 0, 0, 26); nameRow.Parent = b

    local nameBox = Instance.new("TextBox")
    nameBox.BackgroundColor3 = U.CARD2; nameBox.BorderSizePixel = 0
    nameBox.Size = UDim2.new(1, -100, 1, 0)
    nameBox.Font = Enum.Font.Gotham; nameBox.TextSize = 11
    nameBox.TextColor3 = U.TEXT; nameBox.Text = ""
    nameBox.PlaceholderText = "Config name..."
    nameBox.PlaceholderColor3 = U.TEXT_MUTE
    nameBox.TextXAlignment = Enum.TextXAlignment.Left
    nameBox.ClearTextOnFocus = false
    nameBox.Parent = nameRow
    corner(nameBox, 4)
    local nameBoxStroke = stroke(nameBox, U.BORDER, 1)
    local npad = Instance.new("UIPadding", nameBox); npad.PaddingLeft = UDim.new(0, 8)
    ConfigUI.nameBox = nameBox

    nameBox.Focused:Connect(function()
        TweenService:Create(nameBoxStroke, TweenInfo.new(0.2), {Color = U.ACCENT}):Play()
    end)
    nameBox.FocusLost:Connect(function()
        TweenService:Create(nameBoxStroke, TweenInfo.new(0.2), {Color = U.BORDER}):Play()
    end)

    local newBtn = Instance.new("TextButton")
    newBtn.BackgroundColor3 = U.ACCENT; newBtn.BorderSizePixel = 0
    newBtn.Size = UDim2.new(0, 90, 1, 0); newBtn.Position = UDim2.new(1, -90, 0, 0)
    newBtn.Font = Enum.Font.GothamBold; newBtn.TextSize = 11
    newBtn.TextColor3 = Color3.new(1,1,1); newBtn.Text = "New"
    newBtn.AutoButtonColor = false; newBtn.Parent = nameRow
    corner(newBtn, 4)
    newBtn.MouseEnter:Connect(function()
        TweenService:Create(newBtn, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            BackgroundColor3 = U.ACCENT_H,
            Size = UDim2.new(0, 92, 1, 2),
            Position = UDim2.new(1, -91, 0, -1),
        }):Play()
    end)
    newBtn.MouseLeave:Connect(function()
        TweenService:Create(newBtn, TweenInfo.new(0.15), {
            BackgroundColor3 = U.ACCENT,
            Size = UDim2.new(0, 90, 1, 0),
            Position = UDim2.new(1, -90, 0, 0),
        }):Play()
    end)
    ConfigUI.newBtn = newBtn
    b.Parent.Parent.Name = "configSection"

    local ddContainer = Instance.new("Frame")
    ddContainer.BackgroundTransparency = 1
    ddContainer.BorderSizePixel = 0
    ddContainer.Size = UDim2.new(1, 0, 0, 24)
    ddContainer.Parent = b

    local function refreshConfigUI()
        ddContainer:ClearAllChildren()
        local names = listConfigs()
        if #names == 0 then names = {"(no configs)"} end
        local current = ConfigUI.selectedName
        if not current or not table.find(names, current) then
            current = names[1]
        end
        ConfigUI.selectedName = current
        makeDropdownRow(ddContainer, "Select Config", names, current, function(v)
            ConfigUI.selectedName = v
            if nameBox then nameBox.Text = (v ~= "(no configs)") and v or "" end
        end)
        if nameBox and (nameBox.Text == "" or not table.find(names, nameBox.Text)) then
            nameBox.Text = (current ~= "(no configs)") and current or ""
        end
    end
    ConfigUI.refreshConfigUI = refreshConfigUI
    refreshConfigUI()

    local actionsRow = Instance.new("Frame")
    actionsRow.BackgroundTransparency = 1
    actionsRow.Size = UDim2.new(1, 0, 0, 24); actionsRow.Parent = b

    local function mkBtn(txt, col, pos, w)
        local btn = Instance.new("TextButton")
        btn.BackgroundColor3 = col; btn.BorderSizePixel = 0
        btn.Size = UDim2.new(w, 0, 1, 0); btn.Position = UDim2.new(pos, 0, 0, 0)
        btn.Font = Enum.Font.GothamBold; btn.TextSize = 10
        btn.TextColor3 = Color3.new(1,1,1); btn.Text = txt
        btn.AutoButtonColor = false; btn.Parent = actionsRow
        corner(btn, 4)
        btn.MouseEnter:Connect(function()
            local c = Color3.new(
                math.min(1, col.R + 0.12), math.min(1, col.G + 0.12), math.min(1, col.B + 0.12))
            TweenService:Create(btn, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                BackgroundColor3 = c,
                Size = UDim2.new(w, 0, 1, 2),
                Position = UDim2.new(pos, 0, 0, -1),
            }):Play()
        end)
        btn.MouseLeave:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.15), {
                BackgroundColor3 = col,
                Size = UDim2.new(w, 0, 1, 0),
                Position = UDim2.new(pos, 0, 0, 0),
            }):Play()
        end)
        return btn
    end

    local applyBtn = mkBtn("Apply Config", U.GOOD, 0, 0.32)
    local saveBtn = mkBtn("Save Config", U.ACCENT, 0.34, 0.32)
    local delBtn = mkBtn("Delete Config", U.BAD, 0.68, 0.32)

    newBtn.MouseButton1Click:Connect(function()
        local name = nameBox.Text:gsub("^%s+", ""):gsub("%s+$", "")
        if name == "" then
            Notify("Config Error", "Please enter a valid config name.", "error", 2.5)
            return
        end
        if saveConfigToDisk(name) then
            ConfigUI.selectedName = name
            refreshConfigUI()
            nameBox.Text = name
            Notify("Config Saved", "Created and saved '" .. name .. "'", "success", 3)
        end
    end)

    applyBtn.MouseButton1Click:Connect(function()
        local name = ConfigUI.selectedName or nameBox.Text
        if not name or name == "" or name == "(no configs)" then
            Notify("Config Error", "No config selected.", "error", 2.5)
            return
        end
        if loadConfigFromDisk(name) then
            rebuildAllPages()
            Notify("Config Loaded", "Applied config '" .. name .. "'", "success", 3)
        end
    end)

    saveBtn.MouseButton1Click:Connect(function()
        local name = nameBox.Text:gsub("^%s+", ""):gsub("%s+$", "")
        if name == "" then name = ConfigUI.selectedName end
        if not name or name == "(no configs)" then
            Notify("Config Error", "No config selected to overwrite.", "error", 2.5)
            return
        end
        saveConfigToDisk(name)
        ConfigUI.selectedName = name
        refreshConfigUI()
        Notify("Config Saved", "Overwrote config '" .. name .. "'", "success", 3)
    end)

    delBtn.MouseButton1Click:Connect(function()
        local name = ConfigUI.selectedName or nameBox.Text
        if not name or name == "" or name == "(no configs)" then
            Notify("Config Error", "No config selected to delete.", "error", 2.5)
            return
        end
        deleteConfigFromDisk(name)
        ConfigUI.selectedName = nil
        refreshConfigUI()
        Notify("Config Deleted", "Removed config '" .. name .. "'", "warning", 3)
    end)

    local refreshBtn = Instance.new("TextButton")
    refreshBtn.BackgroundColor3 = U.CARD2; refreshBtn.BorderSizePixel = 0
    refreshBtn.Size = UDim2.new(1, 0, 0, 22)
    refreshBtn.Font = Enum.Font.Gotham; refreshBtn.TextSize = 11
    refreshBtn.TextColor3 = U.TEXT_DIM; refreshBtn.Text = "Refresh"
    refreshBtn.AutoButtonColor = false; refreshBtn.Parent = b
    corner(refreshBtn, 4); stroke(refreshBtn, U.BORDER, 1)
    refreshBtn.MouseEnter:Connect(function()
        TweenService:Create(refreshBtn, TweenInfo.new(0.15), {BackgroundColor3 = U.CARD_HOV, TextColor3 = U.TEXT}):Play()
    end)
    refreshBtn.MouseLeave:Connect(function()
        TweenService:Create(refreshBtn, TweenInfo.new(0.15), {BackgroundColor3 = U.CARD2, TextColor3 = U.TEXT_DIM}):Play()
    end)
    refreshBtn.MouseButton1Click:Connect(function()
        refreshConfigUI()
        Notify("Config Manager", "Configuration list refreshed.", "info", 2)
    end)

    local info = makeSection(sf, "Info")
    local infoLbl = Instance.new("TextLabel")
    infoLbl.BackgroundTransparency = 1
    infoLbl.Size = UDim2.new(1, 0, 0, 0); infoLbl.AutomaticSize = Enum.AutomaticSize.Y
    infoLbl.Font = Enum.Font.Gotham; infoLbl.TextSize = 10
    infoLbl.TextColor3 = U.TEXT_DIM; infoLbl.TextWrapped = true
    infoLbl.TextXAlignment = Enum.TextXAlignment.Left
    infoLbl.Text = "Configs saved to: " .. CONFIG_FOLDER .. "/<name>.json\nExecutor needs writefile/readfile/isfile/listfiles to persist between sessions.\nOtherwise configs are saved in-memory only."
    infoLbl.Parent = info
end

-- ═══════════════════════════════════════════════════════════
-- PAGE MANAGEMENT WITH STAGGERED ANIMATIONS
-- ═══════════════════════════════════════════════════════════
local function buildInterfacePage(sf)
    local b1 = makeSection(sf, "Theme & Personalization")
    makeColorRow(b1, "Accent Theme Color", Config.UI.AccentColor or U.ACCENT, "Customize the primary accent color across all UI panels, buttons and highlights.", function(c)
        Config.UI.AccentColor = c
        U.ACCENT = c
        U.ACCENT_H = Color3.new(math.min(1, c.R + 0.15), math.min(1, c.G + 0.15), math.min(1, c.B + 0.15))
        if windowStroke then windowStroke.Color = U.BORDER_HI end
        Notify("Theme", "Updated primary accent color.", "success", 2)
    end)
    makeSliderRow(b1, "Glass Translucency", 0, 50, math.floor((Config.UI.WindowTransparency or 0.12) * 100), "Adjust frosted glass background transparency for the window.", function(v)
        Config.UI.WindowTransparency = v / 100
        if Window and Window.Visible then
            Window.BackgroundTransparency = Config.UI.WindowTransparency
        end
    end, function(v) return v .. "%" end)
    makeDropdownRow(b1, "Preset Themes", {"Electric Blue", "Purple", "Emerald Neon", "Sunset Amber", "Crimson Red"}, "Electric Blue", "Quickly apply predefined luxury color themes.", function(v)
        local map = {
            ["Electric Blue"] = Color3.fromRGB(56, 130, 255),
            ["Purple"] = Color3.fromRGB(180, 85, 255),
            ["Emerald Neon"] = Color3.fromRGB(50, 225, 120),
            ["Sunset Amber"] = Color3.fromRGB(255, 185, 45),
            ["Crimson Red"] = Color3.fromRGB(235, 60, 60),
        }
        local c = map[v] or Color3.fromRGB(56, 130, 255)
        Config.UI.AccentColor = c
        U.ACCENT = c
        U.ACCENT_H = Color3.new(math.min(1, c.R + 0.15), math.min(1, c.G + 0.15), math.min(1, c.B + 0.15))
        Notify("Theme Preset", "Applied " .. v .. " theme preset.", "success", 2)
    end)

    local b2 = makeSection(sf, "HUD & Overlays")
    makeToggleRow(b2, "Show Watermark", Config.ESP.ShowWatermark, "Display sleek status watermark HUD at top left.", function(v)
        Config.ESP.ShowWatermark = v
    end)
    makeToggleRow(b2, "Show FPS/Ping", Config.UI.ShowMetrics, "Toggle live FPS and latency telemetry in the header.", function(v)
        Config.UI.ShowMetrics = v
        if MetricsLbl then MetricsLbl.Visible = v end
    end)
    makeDropdownRow(b2, "Toggle Keybind", {"RightControl", "RightShift", "Insert"}, "RightControl", "Physical keyboard key used to hide or reveal the menu.", function(v)
        if v == "RightControl" then
            Config.UI.ToggleKey = Enum.KeyCode.RightControl
        elseif v == "RightShift" then
            Config.UI.ToggleKey = Enum.KeyCode.RightShift
        elseif v == "Insert" then
            Config.UI.ToggleKey = Enum.KeyCode.Insert
        end
        Notify("Keybind", "Menu toggle key set to " .. v, "info", 2)
    end)
end

local function buildAllPages()
    for name, page in pairs(Pages) do
        page:Destroy()
    end
    Pages = {}
    makePage("Combat")
    makePage("Visual")
    makePage("Config")
    makePage("Interface")
    buildCombatPage(Pages["Combat"])
    buildVisualPage(Pages["Visual"])
    buildConfigPage(Pages["Config"])
    buildInterfacePage(Pages["Interface"])
end

function rebuildAllPages()
    local currentPage = nil
    for name, page in pairs(Pages) do
        if page.Visible then currentPage = name; break end
    end
    buildAllPages()
    showPage(currentPage or "Combat")
end

local function showPage(name)
    for pname, page in pairs(Pages) do
        if pname == name then
            page.Visible = true
            page.Position = UDim2.new(0, 20, 0, 0)
            TweenService:Create(page, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                Position = UDim2.new(0, 0, 0, 0)
            }):Play()
        else
            page.Visible = false
        end
    end
    for bname, btn in pairs(navButtons) do
        local isActive = (bname == name)
        btn.btn:SetAttribute("active", isActive)
        if isActive then
            TweenService:Create(btn.btn, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                BackgroundTransparency = 0.35,
                BackgroundColor3 = U.CARD,
                Position = UDim2.new(0, 14, 0, btn.yoffset),
            }):Play()
            TweenService:Create(btn.dot, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                BackgroundColor3 = U.ACCENT,
                Size = UDim2.new(0, 4, 0, 14),
                Position = UDim2.new(0, 10, 0.5, -7),
            }):Play()
            TweenService:Create(btn.label, TweenInfo.new(0.2), {TextColor3 = U.TEXT}):Play()
            TweenService:Create(btn.icon, TweenInfo.new(0.2), {TextColor3 = U.ACCENT_H}):Play()
        else
            TweenService:Create(btn.btn, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 10, 0, btn.yoffset),
            }):Play()
            TweenService:Create(btn.dot, TweenInfo.new(0.2), {
                BackgroundColor3 = U.TEXT_MUTE,
                Size = UDim2.new(0, 4, 0, 4),
                Position = UDim2.new(0, 10, 0.5, -2),
            }):Play()
            TweenService:Create(btn.label, TweenInfo.new(0.2), {TextColor3 = U.TEXT_DIM}):Play()
            TweenService:Create(btn.icon, TweenInfo.new(0.2), {TextColor3 = U.TEXT_DIM}):Play()
        end
    end
end

buildAllPages()

for name, btn in pairs(navButtons) do
    btn.btn.MouseButton1Click:Connect(function()
        if OpenDropdown then closeDropdown() end
        if OpenColorPicker then closeColorPicker() end
        showPage(name)
    end)
end
showPage("Combat")

-- Close popups on outside click
Window.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        local mx = input.Position.X - Window.AbsolutePosition.X
        local my = input.Position.Y - Window.AbsolutePosition.Y
        if OpenDropdown then
            local dd = OpenDropdown
            local dpx = dd.AbsolutePosition.X - Window.AbsolutePosition.X
            local dpy = dd.AbsolutePosition.Y - Window.AbsolutePosition.Y
            if not (mx >= dpx and mx <= dpx + dd.AbsoluteSize.X and my >= dpy and my <= dpy + dd.AbsoluteSize.Y) then
                closeDropdown()
            end
        end
        if OpenColorPicker then
            local cp = OpenColorPicker
            local cpx = cp.AbsolutePosition.X - Window.AbsolutePosition.X
            local cpy = cp.AbsolutePosition.Y - Window.AbsolutePosition.Y
            if not (mx >= cpx and mx <= cpx + cp.AbsoluteSize.X and my >= cpy and my <= cpy + cp.AbsoluteSize.Y) then
                closeColorPicker()
            end
        end
    end
end)

-- ═══════════════════════════════════════════════════════════
-- RENDER
-- ═══════════════════════════════════════════════════════════
local function renderSilentFOV()
    if Config.SilentAim.Enabled and Config.SilentAim.ShowFOV then
        local mousePos = UserInputService:GetMouseLocation()
        SilentFOVCircle.Position = mousePos
        SilentFOVCircle.Radius = Config.SilentAim.FOV
        SilentFOVCircle.Color = Config.SilentAim.FOVColor
        SilentFOVCircle.Visible = true
    else
        SilentFOVCircle.Visible = false
    end
end

local function isBoneVisible(camPos, part, targetChar)
    if not part or not part.Parent then return false end
    if isPositionVisible(camPos, part.Position, targetChar) then return true end
    local sz = part.Size * 0.45
    local cf = part.CFrame
    local testPoints = {
        cf.Position + cf.RightVector * sz.X,
        cf.Position - cf.RightVector * sz.X,
        cf.Position + cf.UpVector * sz.Y,
        cf.Position - cf.UpVector * sz.Y,
        cf.Position + cf.LookVector * sz.Z,
        cf.Position - cf.LookVector * sz.Z,
    }
    for _, pt in ipairs(testPoints) do
        if isPositionVisible(camPos, pt, targetChar) then
            return true
        end
    end
    return false
end

local function clearChams(plr)
    local existing = ChamsCache[plr]
    if not existing then return end
    if type(existing) == "table" then
        for _, h in pairs(existing) do
            pcall(function() h:Destroy() end)
        end
    else
        pcall(function() existing:Destroy() end)
    end
    ChamsCache[plr] = nil
end

local function applyChams(plr, char)
    local c = Config.Chams
    if not c.Enabled or not char or not char.Parent then
        clearChams(plr)
        return
    end

    if c.TeamCheck and LocalPlayer.Team and plr.Team and plr.Team == LocalPlayer.Team then
        clearChams(plr)
        return
    end

    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then
        clearChams(plr)
        return
    end

    local camPos = Camera.CFrame.Position
    local parts = ChamsCache[plr]
    if type(parts) ~= "table" then
        if parts and parts.Destroy then pcall(function() parts:Destroy() end) end
        parts = {}
        ChamsCache[plr] = parts
    end

    for _, boneName in ipairs(CHAM_BONES) do
        local part = char:FindFirstChild(boneName)
        if part and part:IsA("BasePart") and boneName ~= "HumanoidRootPart" then
            local isVis = true
            if c.WallCheck then
                isVis = isBoneVisible(camPos, part, char)
            end

            local h = parts[part]
            if not h or not h.Parent then
                if h and h.Destroy then pcall(function() h:Destroy() end) end
                h = Instance.new("Highlight")
                h.Adornee = part
                h.Parent = char
                h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                parts[part] = h
            end

            local col = isVis and c.VisibleFill or c.InvisibleFill
            h.FillColor = col
            h.OutlineColor = col
            h.FillTransparency = c.FillTransparency
            h.OutlineTransparency = 1
        end
    end
end

local function renderESP()
    local vp = Camera.ViewportSize
    local center = Vector2.new(vp.X/2, vp.Y/2)

    local countW, countH = 76, 24
    local countX = math.floor(vp.X / 2 - countW / 2)
    local countY = 16
    local countBottomCenter = Vector2.new(vp.X / 2, countY + countH)

    if not Config.ESP.Enabled then
        for plr in pairs(ESPCache) do clearESP(plr) end
        for plr in pairs(ChamsCache) do clearChams(plr) end
        EspCountBox.Visible = false
        EspCountBorder.Visible = false
        EspCountText.Visible = false
        return
    end

    local myChar = LocalPlayer.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then
        EspCountBox.Visible = false
        EspCountBorder.Visible = false
        EspCountText.Visible = false
        return
    end

    local myPos = myRoot.Position
    local espOff = Vector2.new(Config.ESP.EspPosX, Config.ESP.EspPosY) + Vector2.new(Config.ESP.DrawPosX, Config.ESP.DrawPosY)

    local tracerFrom = Vector2.new(vp.X/2, vp.Y)
    if Config.ESP.TracerOrigin == "Middle" then
        tracerFrom = center
    elseif Config.ESP.TracerOrigin == "Top" then
        tracerFrom = countBottomCenter
    end

    local espEnemyCount = 0

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr == LocalPlayer then continue end
        local char = plr.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local head = char and char:FindFirstChild("Head")

        if not (char and hum and root and hum.Health > 0) then
            clearESP(plr)
            clearChams(plr)
            continue
        end

        if Config.ESP.TeamCheck and plr.Team and LocalPlayer.Team and plr.Team == LocalPlayer.Team then
            clearESP(plr)
            clearChams(plr)
            continue
        end

        local dist = (root.Position - myPos).Magnitude
        if dist > Config.ESP.Range then
            clearESP(plr)
            clearChams(plr)
            continue
        end

        espEnemyCount = espEnemyCount + 1

        local blocked = false
        if Config.ESP.WallCheck then
            blocked = not isPositionVisible(Camera.CFrame.Position, root.Position, char)
        end

        applyChams(plr, char)

        local d = makeESP(plr)
        local top0, ok1 = worldToScreen(head and (head.Position + Vector3.new(0, 0.2, 0)) or (root.Position + Vector3.new(0, 1.5, 0)))
        local bottom0, ok2 = worldToScreen(root.Position - Vector3.new(0, 1.5, 0))
        local onScreen = ok1 and ok2

        if not onScreen and Config.ESP.OffscreenArrows then
            local camCF = Camera.CFrame
            local toTarget = root.Position - camCF.Position
            local fDot = toTarget:Dot(camCF.LookVector)
            local rDot = toTarget:Dot(camCF.RightVector)
            local uDot = toTarget:Dot(camCF.UpVector)

            local dir2D
            if fDot < 0 then
                dir2D = Vector2.new(-rDot, -uDot)
            else
                dir2D = Vector2.new(rDot, uDot)
            end

            if dir2D.Magnitude > 0.001 then
                local normDir = Vector2.new(dir2D.X, -dir2D.Y).Unit
                local arrowRadius = math.min(center.X, center.Y) - 55
                local arrowPos = center + normDir * arrowRadius

                local sz = Config.ESP.ArrowSize or 18
                local perp = Vector2.new(-normDir.Y, normDir.X)
                local tip = arrowPos + normDir * (sz * 0.7)
                local base = arrowPos - normDir * (sz * 0.5)
                local left = base + perp * (sz * 0.55)
                local right = base - perp * (sz * 0.55)

                d.Arrow.PointA = tip
                d.Arrow.PointB = left
                d.Arrow.PointC = right
                local col = (Config.ESP.TeamColors and plr.TeamColor) and plr.TeamColor.Color or (blocked and Color3.fromRGB(235, 65, 65) or Color3.fromRGB(50, 225, 120))
                d.Arrow.Color = col
                d.Arrow.Filled = true
                d.Arrow.Transparency = 0.88
                d.Arrow.Visible = true
            else
                d.Arrow.Visible = false
            end
        else
            d.Arrow.Visible = false
        end

        local top = onScreen and (top0 + espOff) or top0
        local bottom = onScreen and (bottom0 + espOff) or bottom0

        if onScreen then
            local bw, bh = computeBox(top, bottom)
            local x = top.X - bw/2
            local y = top.Y
            local TL = Vector2.new(x, y); local TR = Vector2.new(x+bw, y)
            local BL = Vector2.new(x, y+bh); local BR = Vector2.new(x+bw, y+bh)

            local primary = Color3.fromRGB(50, 225, 120)
            if Config.ESP.WallCheck then
                primary = blocked and Color3.fromRGB(235, 65, 65) or Color3.fromRGB(50, 225, 120)
            elseif Config.ESP.TeamColors and plr.TeamColor then
                primary = plr.TeamColor.Color
            end

            local tracerCol = Color3.fromRGB(56, 130, 255)
            if Config.ESP.WallCheck then
                tracerCol = blocked and Color3.fromRGB(235, 65, 65) or Color3.fromRGB(50, 225, 120)
            end

            -- Main Player Bounding Box
            if Config.ESP.Boxes then
                if Config.ESP.BoxType == "Full Box" then
                    d.Box.Position = Vector2.new(x, y); d.Box.Size = Vector2.new(bw, bh)
                    d.Box.Color = primary; d.Box.Thickness = Config.ESP.BoxThickness; d.Box.Visible = true
                    for _, l in pairs(d.Corner) do l.Visible = false end
                else
                    d.Box.Visible = false
                    drawCornerBox(d.Corner, TL, TR, BL, BR, math.clamp(bw/4, 3, 14), primary, Config.ESP.BoxThickness)
                end
                if Config.ESP.BoxFill then
                    d.BoxFill.Position = Vector2.new(x, y); d.BoxFill.Size = Vector2.new(bw, bh)
                    d.BoxFill.Color = Config.ESP.BoxFillColor
                    d.BoxFill.Transparency = Config.ESP.BoxFillTransparency
                    d.BoxFill.Visible = true
                else d.BoxFill.Visible = false end
            else
                d.Box.Visible = false; d.BoxFill.Visible = false
                for _, l in pairs(d.Corner) do l.Visible = false end
            end

            local r = math.clamp(hum.Health / math.max(1, hum.MaxHealth), 0, 1)
            local isStyle2 = (Config.ESP.Style == "Style 2")

            if isStyle2 then

                d.HealthBack.Visible = false; d.HealthFront.Visible = false; d.HealthText.Visible = false

                local bannerW = math.max(bw, 78)
                local bannerH = 22
                local bannerX = math.floor(top.X - bannerW / 2)
                local bannerY = math.floor(y - bannerH - 5)

                -- Banner dark background
                d.BannerBg.Position = Vector2.new(bannerX, bannerY)
                d.BannerBg.Size = Vector2.new(bannerW, bannerH)
                d.BannerBg.Color = Color3.fromRGB(10, 13, 20)
                d.BannerBg.Transparency = 0.85
                d.BannerBg.Visible = true

                -- Banner solid outline border
                d.BannerBorder.Position = Vector2.new(bannerX, bannerY)
                d.BannerBorder.Size = Vector2.new(bannerW, bannerH)
                d.BannerBorder.Color = primary
                d.BannerBorder.Thickness = 1
                d.BannerBorder.Visible = true

                -- Horizontal health bar at top of banner (green bar)
                d.BannerHealthBack.Position = Vector2.new(bannerX, bannerY)
                d.BannerHealthBack.Size = Vector2.new(bannerW, 4)
                d.BannerHealthBack.Color = Color3.fromRGB(25, 32, 45)
                d.BannerHealthBack.Visible = true

                local hFillW = math.floor(bannerW * r)
                d.BannerHealthFill.Position = Vector2.new(bannerX, bannerY)
                d.BannerHealthFill.Size = Vector2.new(hFillW, 4)
                d.BannerHealthFill.Color = Color3.fromRGB(0, 230, 80) -- bright green as shown in sketch
                d.BannerHealthFill.Visible = true

                -- Name on left of banner
                if Config.ESP.Names then
                    d.Name.Center = false
                    d.Name.Position = Vector2.new(bannerX + 4, bannerY + 6)
                    d.Name.Size = 10
                    d.Name.Color = Config.ESP.NameColor
                    d.Name.Text = plr.Name
                    d.Name.Visible = true
                else d.Name.Visible = false end

                -- Distance on right of banner
                if Config.ESP.Distance then
                    local distStr = string.format("%dm", math.floor(dist))
                    local distTextW = #distStr * 6
                    d.Distance.Center = false
                    d.Distance.Position = Vector2.new(bannerX + bannerW - distTextW - 4, bannerY + 6)
                    d.Distance.Size = 10
                    d.Distance.Color = Config.ESP.DistanceColor
                    d.Distance.Text = distStr
                    d.Distance.Visible = true
                else d.Distance.Visible = false end

                -- Weapon centered under the main player box
                if Config.ESP.WeaponInfo then
                    local tool = char:FindFirstChildOfClass("Tool")
                    if tool then
                        d.Weapon.Text = tool.Name
                        d.Weapon.Position = Vector2.new(top.X, y + bh + 4)
                        d.Weapon.Visible = true
                    else d.Weapon.Visible = false end
                else d.Weapon.Visible = false end

                -- Tracer connects to middle-top of the banner
                if Config.ESP.Tracers then
                    d.Tracer.From = tracerFrom
                    d.Tracer.To = Vector2.new(math.floor(bannerX + bannerW / 2), bannerY)
                    d.Tracer.Color = tracerCol
                    d.Tracer.Visible = true
                else d.Tracer.Visible = false end
            else
                -- ═══════ STYLE 1 (CLASSIC ESP) ═══════
                d.BannerBg.Visible = false; d.BannerBorder.Visible = false
                d.BannerHealthBack.Visible = false; d.BannerHealthFill.Visible = false

                if Config.ESP.Tracers then
                    d.Tracer.From = tracerFrom; d.Tracer.To = Vector2.new(top.X, top.Y + bh/2)
                    d.Tracer.Color = tracerCol
                    d.Tracer.Visible = true
                else d.Tracer.Visible = false end

                if Config.ESP.Names then
                    d.Name.Center = true
                    d.Name.Text = plr.Name; d.Name.Size = Config.ESP.NameSize
                    d.Name.Position = Vector2.new(top.X, y - Config.ESP.NameSize - 2)
                    d.Name.Color = Config.ESP.NameColor; d.Name.Visible = true
                else d.Name.Visible = false end

                if Config.ESP.Distance then
                    d.Distance.Center = true
                    d.Distance.Text = string.format("[%dm]", math.floor(dist))
                    d.Distance.Size = Config.ESP.DistanceSize
                    d.Distance.Position = Vector2.new(top.X, y + bh + 4)
                    d.Distance.Color = Config.ESP.DistanceColor; d.Distance.Visible = true
                else d.Distance.Visible = false end

                local infoY = y + bh + 4
                if Config.ESP.Distance then infoY = infoY + 14 end

                if Config.ESP.HealthBar then
                    local lx = x - 5
                    d.HealthBack.From = Vector2.new(lx, y); d.HealthBack.To = Vector2.new(lx, y + bh); d.HealthBack.Visible = true
                    d.HealthFront.From = Vector2.new(lx, y + bh * (1 - r)); d.HealthFront.To = Vector2.new(lx, y + bh)
                    d.HealthFront.Color = healthColor(r); d.HealthFront.Visible = true
                else d.HealthBack.Visible = false; d.HealthFront.Visible = false end

                if Config.ESP.HealthText then
                    d.HealthText.Text = string.format("%d", math.floor(hum.Health))
                    d.HealthText.Position = Vector2.new(top.X, infoY)
                    d.HealthText.Color = healthColor(r)
                    d.HealthText.Size = 10; d.HealthText.Visible = true
                    infoY = infoY + 13
                else d.HealthText.Visible = false end

                if Config.ESP.WeaponInfo then
                    local tool = char:FindFirstChildOfClass("Tool")
                    if tool then
                        d.Weapon.Text = tool.Name
                        d.Weapon.Position = Vector2.new(top.X, infoY)
                        d.Weapon.Visible = true
                    else d.Weapon.Visible = false end
                else d.Weapon.Visible = false end
            end

            if d.Head then d.Head.Visible = false end

            if Config.ESP.Skeleton then
                for i, pair in ipairs(bones) do
                    local p1 = char:FindFirstChild(pair[1]); local p2 = char:FindFirstChild(pair[2])
                    if p1 and p2 then
                        local v1, o1 = worldToScreen(p1.Position); local v2, o2 = worldToScreen(p2.Position)
                        if o1 and o2 then
                            d.Skeleton[i].From = v1 + espOff; d.Skeleton[i].To = v2 + espOff
                            d.Skeleton[i].Color = Config.ESP.SkeletonColor; d.Skeleton[i].Visible = true
                        else d.Skeleton[i].Visible = false end
                    else d.Skeleton[i].Visible = false end
                end
            else for _, l in ipairs(d.Skeleton) do l.Visible = false end end
        else
            d.Box.Visible = false; d.BoxFill.Visible = false
            for _, l in pairs(d.Corner) do l.Visible = false end
            d.Tracer.Visible = false
            d.Name.Visible = false; d.Distance.Visible = false
            d.HealthBack.Visible = false; d.HealthFront.Visible = false; d.HealthText.Visible = false
            d.Head.Visible = false; d.Weapon.Visible = false
            for _, l in ipairs(d.Skeleton) do l.Visible = false end
            d.BannerBg.Visible = false; d.BannerBorder.Visible = false
            d.BannerHealthBack.Visible = false; d.BannerHealthFill.Visible = false
        end
    end

    -- Update Frosted Glass Rounded ESP Count Widget
    if Config.ESP.Enabled and Config.ESP.ShowEspCount then
        EspCountGui.Visible = true
        if espEnemyCount == 0 then
            countLabel.Text = "CLEAR"
            countLabel.TextColor3 = U.GOOD
            countStroke.Color = U.GOOD
        else
            countLabel.Text = "ENEMIES: " .. espEnemyCount
            countLabel.TextColor3 = Color3.fromRGB(255, 75, 75)
            countStroke.Color = Color3.fromRGB(255, 75, 75)
        end
    else
        EspCountGui.Visible = false
    end
end

local function updateAimWarning()
    if not (Config.ESP.Enabled and Config.ESP.ShowAimWarning) then
        AimWarningText.Visible = false
        for _, c in pairs(AimWarningHeadCircles) do c.Visible = false end
        return
    end

    local myChar = LocalPlayer.Character
    local myHead = myChar and myChar:FindFirstChild("Head")
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not (myChar and (myHead or myRoot)) then
        AimWarningText.Visible = false
        for _, c in pairs(AimWarningHeadCircles) do c.Visible = false end
        return
    end

    local myTargetPos = myHead and myHead.Position or myRoot.Position
    local vp = Camera.ViewportSize
    AimWarningText.Position = Vector2.new(math.floor(vp.X / 2), math.floor(vp.Y * 0.32))

    local someoneAiming = false

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr == LocalPlayer then continue end
        local char = plr.Character
        local head = char and char:FindFirstChild("Head")
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local isAiming = false

        if char and head and hum and hum.Health > 0 then
            local isTeam = (Config.ESP.TeamCheck and plr.Team and LocalPlayer.Team and plr.Team == LocalPlayer.Team)
            if not isTeam then
                local toMe = myTargetPos - head.Position
                local dist = toMe.Magnitude
                if dist > 1 and dist < 2000 then
                    local dir = toMe.Unit
                    local enemyLook = head.CFrame.LookVector
                    local dot = enemyLook:Dot(dir)
                    if dot > 0.965 then
                        if isPositionVisible(head.Position, myTargetPos, myChar) then
                            isAiming = true
                            someoneAiming = true
                        end
                    end
                end
            end
        end

        local circle = getAimCircle(plr)
        if isAiming and head then
            local headScrn, onScrn = worldToScreen(head.Position)
            if onScrn then
                circle.Position = headScrn
                circle.Radius = 18
                circle.Visible = true
            else
                circle.Visible = false
            end
        else
            circle.Visible = false
        end
    end

    AimWarningText.Visible = someoneAiming
end

-- ═══════ ON-SCREEN WATERMARK & METRICS UPDATE ═══════
local lastFpsUpdate = 0
local frameCount = 0
local currentFps = 60
local currentPing = 30

local function updateWatermarkAndMetrics(dt)
    frameCount = frameCount + 1
    local now = os.clock()
    if now - lastFpsUpdate >= 0.5 then
        currentFps = math.floor(frameCount / (now - lastFpsUpdate))
        frameCount = 0
        lastFpsUpdate = now
        pcall(function()
            local pingItem = Stats.Network.ServerStatsItem["Data Ping"]
            if pingItem then
                currentPing = math.floor(tonumber(pingItem:GetValueString():match("%d+")) or 30)
            end
        end)
        MetricsLbl.Text = string.format("%d FPS · %dms", currentFps, currentPing)
    end

    if Config.ESP.Enabled and Config.ESP.ShowWatermark then
        local userStr = (LocalPlayer and LocalPlayer.DisplayName) or "User"
        local wmStr = string.format("AMETHYST · V1 | %d FPS | %dms", currentFps, currentPing, userStr)
        local wmW = #wmStr * 6.5 + 24
        local wmH = 22
        local wmX = 20
        local wmY = 20

        WatermarkBg.Position = Vector2.new(wmX, wmY)
        WatermarkBg.Size = Vector2.new(wmW, wmH)
        WatermarkBg.Color = Color3.fromRGB(11, 15, 23)
        WatermarkBg.Transparency = 0.88
        WatermarkBg.Visible = true

        WatermarkBorder.Position = Vector2.new(wmX, wmY)
        WatermarkBorder.Size = Vector2.new(wmW, wmH)
        WatermarkBorder.Color = U.ACCENT
        WatermarkBorder.Transparency = 0.75
        WatermarkBorder.Visible = true

        WatermarkBar.From = Vector2.new(wmX, wmY)
        WatermarkBar.To = Vector2.new(wmX + wmW, wmY)
        WatermarkBar.Color = (currentPing < 60 and U.GOOD) or (currentPing < 110 and U.AMBER) or U.BAD
        WatermarkBar.Thickness = 2
        WatermarkBar.Visible = true

        WatermarkText.Position = Vector2.new(wmX + 12, wmY + 4)
        WatermarkText.Text = wmStr
        WatermarkText.Color = U.TEXT
        WatermarkText.Visible = true
    else
        WatermarkBg.Visible = false
        WatermarkBorder.Visible = false
        WatermarkBar.Visible = false
        WatermarkText.Visible = false
    end
end

-- Tactical Radar Drawings (Complete Remake)
local RadarDraw = {
    Bg = makeDrawing("Square"), BgC = makeDrawing("Circle"),
    Border = makeDrawing("Square"), BorderC = makeDrawing("Circle"),
    Rings = {}, Cardinals = {}, RangeText = makeDrawing("Text"),
    Self = makeDrawing("Circle"), SelfHeading = makeDrawing("Line"),
    AxisH = makeDrawing("Line"), AxisV = makeDrawing("Line"),
    SweepLine = makeDrawing("Line"), OuterGlow = makeDrawing("Circle"),
}
for i = 1, 3 do RadarDraw.Rings[i] = makeDrawing("Circle") end
for i = 1, 4 do
    local t = makeDrawing("Text"); t.Size = 10; t.Center = true; t.Outline = true
    RadarDraw.Cardinals[i] = t
end

RadarDraw.AxisH.Thickness = 1; RadarDraw.AxisH.Transparency = 0.7; RadarDraw.AxisH.Visible = false
RadarDraw.AxisV.Thickness = 1; RadarDraw.AxisV.Transparency = 0.7; RadarDraw.AxisV.Visible = false
RadarDraw.SweepLine.Thickness = 1.5; RadarDraw.SweepLine.Transparency = 0.6; RadarDraw.SweepLine.Visible = false
RadarDraw.OuterGlow.Filled = false; RadarDraw.OuterGlow.Thickness = 2.5; RadarDraw.OuterGlow.Transparency = 0.75; RadarDraw.OuterGlow.Visible = false

local function makeRadarBlip(plr)
    if RadarBlips[plr] then return RadarBlips[plr] end
    local b = {
        Dot = makeDrawing("Circle"),
        Label = makeDrawing("Text"),
        Cone = makeDrawing("Line"),
        Elevation = makeDrawing("Text"),
    }
    b.Dot.Filled = true; b.Dot.Thickness = 0
    b.Label.Size = 9; b.Label.Center = true; b.Label.Outline = true
    b.Cone.Thickness = 1
    b.Elevation.Size = 10; b.Elevation.Center = true; b.Elevation.Outline = true
    RadarBlips[plr] = b
    return b
end

local function clearRadarBlip(plr)
    local b = RadarBlips[plr]
    if not b then return end
    b.Dot.Visible = false
    b.Label.Visible = false
    b.Cone.Visible = false
    if b.Elevation then b.Elevation.Visible = false end
end

local function renderRadar()
    local r = Config.Radar
    RadarDraw.Bg.Visible = false; RadarDraw.BgC.Visible = false
    RadarDraw.Border.Visible = false; RadarDraw.BorderC.Visible = false
    RadarDraw.RangeText.Visible = false; RadarDraw.Self.Visible = false
    RadarDraw.SelfHeading.Visible = false
    RadarDraw.AxisH.Visible = false; RadarDraw.AxisV.Visible = false
    RadarDraw.SweepLine.Visible = false; RadarDraw.OuterGlow.Visible = false
    for _, rr in ipairs(RadarDraw.Rings) do rr.Visible = false end
    for _, c in ipairs(RadarDraw.Cardinals) do c.Visible = false end

    if not r.Enabled then
        for plr in pairs(RadarBlips) do clearRadarBlip(plr) end
        return
    end

    local size = r.Size
    local radius = size / 2 - 4
    local cx = r.PosX + radius + 4
    local cy = r.PosY + radius + 4
    local center = Vector2.new(cx, cy)

    if r.Shape == "Square" then
        RadarDraw.Bg.Position = Vector2.new(cx - radius, cy - radius)
        RadarDraw.Bg.Size = Vector2.new(radius * 2, radius * 2)
        RadarDraw.Bg.Color = r.BgColor; RadarDraw.Bg.Filled = true
        RadarDraw.Bg.Thickness = 0; RadarDraw.Bg.Transparency = r.BgAlpha; RadarDraw.Bg.Visible = true
        RadarDraw.Border.Position = Vector2.new(cx - radius, cy - radius)
        RadarDraw.Border.Size = Vector2.new(radius * 2, radius * 2)
        RadarDraw.Border.Color = r.BorderColor; RadarDraw.Border.Filled = false
        RadarDraw.Border.Thickness = 1.5; RadarDraw.Border.Transparency = 0.5; RadarDraw.Border.Visible = true
    else
        RadarDraw.BgC.Position = center; RadarDraw.BgC.Radius = radius
        RadarDraw.BgC.Color = r.BgColor; RadarDraw.BgC.Filled = true
        RadarDraw.BgC.Thickness = 0; RadarDraw.BgC.Transparency = r.BgAlpha; RadarDraw.BgC.Visible = true
        RadarDraw.BorderC.Position = center; RadarDraw.BorderC.Radius = radius
        RadarDraw.BorderC.Color = r.BorderColor; RadarDraw.BorderC.Filled = false
        RadarDraw.BorderC.Thickness = 1.5; RadarDraw.BorderC.Transparency = 0.5; RadarDraw.BorderC.Visible = true
    end

    -- Tactical Crosshair Axes & Sweep Beam
    RadarDraw.AxisH.From = Vector2.new(cx - radius, cy)
    RadarDraw.AxisH.To = Vector2.new(cx + radius, cy)
    RadarDraw.AxisH.Color = r.BorderColor
    RadarDraw.AxisH.Visible = true

    RadarDraw.AxisV.From = Vector2.new(cx, cy - radius)
    RadarDraw.AxisV.To = Vector2.new(cx, cy + radius)
    RadarDraw.AxisV.Color = r.BorderColor
    RadarDraw.AxisV.Visible = true

    -- Animated Tactical Radar Sweep Line
    local sweepAngle = (os.clock() * 2.2) % (math.pi * 2)
    RadarDraw.SweepLine.From = center
    RadarDraw.SweepLine.To = Vector2.new(cx + math.cos(sweepAngle) * radius, cy + math.sin(sweepAngle) * radius)
    RadarDraw.SweepLine.Color = U.ACCENT_H
    RadarDraw.SweepLine.Visible = true

    if r.ShowRings then
        for i, rr in ipairs(RadarDraw.Rings) do
            rr.Position = center; rr.Radius = radius * (i / 3)
            rr.Color = r.BorderColor; rr.Filled = false
            rr.Thickness = 0.8; rr.Transparency = 0.75; rr.Visible = true
        end
    end

    if r.ShowRangeText then
        RadarDraw.RangeText.Text = string.format("%dm", r.Range)
        RadarDraw.RangeText.Position = Vector2.new(cx, cy + radius + 6)
        RadarDraw.RangeText.Color = r.BorderColor; RadarDraw.RangeText.Visible = true
    end

    if r.ShowCompass then
        local labels = r.Rotate and {"F","B","L","R"} or {"N","S","W","E"}
        local positions = {{cx, cy-radius-8},{cx, cy+radius+12},{cx-radius-10, cy},{cx+radius+10, cy}}
        for i, t in ipairs(RadarDraw.Cardinals) do
            t.Text = labels[i]
            t.Position = Vector2.new(positions[i][1], positions[i][2])
            t.Color = r.BorderColor; t.Visible = true
        end
    end

    local myChar = LocalPlayer.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end
    local myPos = myRoot.Position
    local lookDir, rightDir
    if r.Rotate then
        local look = Vector3.new(Camera.CFrame.LookVector.X, 0, Camera.CFrame.LookVector.Z)
        if look.Magnitude > 0.01 then lookDir = look.Unit end
        local right = Vector3.new(Camera.CFrame.RightVector.X, 0, Camera.CFrame.RightVector.Z)
        if right.Magnitude > 0.01 then rightDir = right.Unit end
    else
        lookDir = Vector3.new(0,0,-1); rightDir = Vector3.new(1,0,0)
    end

    if r.ShowSelf then
        RadarDraw.Self.Position = center; RadarDraw.Self.Radius = 3
        RadarDraw.Self.Color = r.SelfColor; RadarDraw.Self.Filled = true
        RadarDraw.Self.Thickness = 0; RadarDraw.Self.Transparency = 0; RadarDraw.Self.Visible = true
        if lookDir then
            RadarDraw.SelfHeading.From = center
            RadarDraw.SelfHeading.To = Vector2.new(cx + lookDir.X * 12, cy - lookDir.Z * 12)
            RadarDraw.SelfHeading.Color = r.SelfColor
            RadarDraw.SelfHeading.Thickness = 1.5
            RadarDraw.SelfHeading.Visible = true
        end
    end

    if r.ShowBlips then
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr == LocalPlayer then continue end
            local char = plr.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if not (char and root and hum and hum.Health > 0) then clearRadarBlip(plr); continue end
            if Config.ESP.TeamCheck and plr.Team and LocalPlayer.Team and plr.Team == LocalPlayer.Team then
                clearRadarBlip(plr); continue
            end
            local rel = root.Position - myPos
            local relXZ = Vector3.new(rel.X, 0, rel.Z)
            local dist = relXZ.Magnitude

            -- Practical Edge Clamping: If slightly outside range, clamp to rim for tactical awareness
            local isClamped = false
            if dist > r.Range then
                if dist <= r.Range * 1.35 then
                    isClamped = true
                else
                    clearRadarBlip(plr); continue
                end
            end

            local bx, by
            local effectiveDist = isClamped and r.Range or dist
            local scaleFrac = effectiveDist / r.Range

            if lookDir and rightDir then
                local normDir = relXZ.Unit
                bx = cx + (normDir:Dot(rightDir) * scaleFrac) * radius
                by = cy - (normDir:Dot(lookDir) * scaleFrac) * radius
            else
                bx = cx + (rel.X / r.Range) * radius
                by = cy - (-rel.Z / r.Range) * radius
            end

            local edgeAlpha = isClamped and 0.45 or 1
            if r.FadeEdge and not isClamped then
                local frac = dist / r.Range
                edgeAlpha = math.clamp(1 - math.max(0, (frac - 0.7) / 0.3), 0, 1)
                if edgeAlpha < 0.05 then clearRadarBlip(plr); continue end
            end

            local blip = makeRadarBlip(plr)
            local blipCol = (r.TeamColors and plr.TeamColor) and plr.TeamColor.Color or r.BlipColor

            -- Tactical Elevation Indicators
            if rel.Y > 6 then
                -- Enemy is above (e.g. roof/hill)
                blip.Elevation.Text = "▲"
                blip.Elevation.Position = Vector2.new(bx, by - 6)
                blip.Elevation.Color = blipCol
                blip.Elevation.Transparency = 1 - edgeAlpha
                blip.Elevation.Visible = true
                blip.Dot.Visible = false
            elseif rel.Y < -6 then
                -- Enemy is below (e.g. basement/ground)
                blip.Elevation.Text = "▼"
                blip.Elevation.Position = Vector2.new(bx, by - 6)
                blip.Elevation.Color = blipCol
                blip.Elevation.Transparency = 1 - edgeAlpha
                blip.Elevation.Visible = true
                blip.Dot.Visible = false
            else
                -- Level plane
                blip.Elevation.Visible = false
                blip.Dot.Position = Vector2.new(bx, by)
                blip.Dot.Radius = r.BlipSize
                blip.Dot.Color = blipCol
                blip.Dot.Filled = true
                blip.Dot.Thickness = 0
                blip.Dot.Transparency = 1 - edgeAlpha
                blip.Dot.Visible = true
            end

            if r.ShowCone and not isClamped then
                local el = char:FindFirstChild("Head") and char.Head.CFrame.LookVector or root.CFrame.LookVector
                local fl = Vector3.new(el.X, 0, el.Z)
                if fl.Magnitude > 0.01 then
                    fl = fl.Unit
                    local fx, fy
                    if lookDir and rightDir then fx = fl:Dot(rightDir); fy = fl:Dot(lookDir)
                    else fx = fl.X; fy = -fl.Z end
                    blip.Cone.From = Vector2.new(bx, by)
                    blip.Cone.To = Vector2.new(bx + fx * 8, by - fy * 8)
                    blip.Cone.Color = blipCol
                    blip.Cone.Thickness = 1.2
                    blip.Cone.Transparency = 1 - edgeAlpha * 0.7
                    blip.Cone.Visible = true
                else blip.Cone.Visible = false end
            else blip.Cone.Visible = false end

            if r.ShowDistanceText then
                blip.Label.Text = string.format("%.0f", dist)
                blip.Label.Position = Vector2.new(bx, by + 6)
                blip.Label.Color = blipCol
                blip.Label.Transparency = 1 - edgeAlpha * 0.9
                blip.Label.Visible = true
            else blip.Label.Visible = false end
        end
    else
        for plr in pairs(RadarBlips) do clearRadarBlip(plr) end
    end
end

trackConn(RunService.RenderStepped:Connect(function(dt)
    if not LocalPlayer.Character then return end
    if not Camera or Camera ~= workspace.CurrentCamera then Camera = workspace.CurrentCamera end
    pcall(updateSilentAimTarget)
    pcall(renderSilentFOV)
    pcall(updateAimbot, dt)
    pcall(renderAimbotFOV)
    pcall(updateAimSnapLine)
    pcall(updateAimPull)
    pcall(renderESP)
    pcall(updateAimWarning)
    pcall(updateWatermarkAndMetrics, dt)
    pcall(renderRadar)
end))

trackConn(UserInputService.InputBegan:Connect(function(input, gp)
    local targetKey = (Config.UI and Config.UI.ToggleKey) or Enum.KeyCode.RightControl
    if input.KeyCode == targetKey or input.KeyCode == Enum.KeyCode.RightControl or input.KeyCode == Enum.KeyCode.RightShift then
        if UserInputService:GetFocusedTextBox() then return end
        toggleWindow()
    end
end))

trackConn(Players.PlayerRemoving:Connect(function(pl)
    clearESP(pl); ESPCache[pl] = nil
    if PullTarget == pl then cleanupPullState() end
    clearChams(pl)
    clearRadarBlip(pl); RadarBlips[pl] = nil
    if AimWarningHeadCircles[pl] then
        pcall(function() AimWarningHeadCircles[pl]:Remove() end)
        AimWarningHeadCircles[pl] = nil
    end
end))

_G.RSilentCleanup = function()
    for _, conn in ipairs(ScriptConnections) do
        pcall(function() conn:Disconnect() end)
    end
    ScriptConnections = {}
    cleanupPullState()
    for _, d in pairs(_G.RSilentDrawings) do pcall(function() d:Remove() end) end
    _G.RSilentDrawings = {}
    if ParentGui and ParentGui.Parent then ParentGui:Destroy() end
    for plr in pairs(ChamsCache) do
        clearChams(plr)
    end
    ChamsCache = {}
    for plr, c in pairs(AimWarningHeadCircles) do
        pcall(function() c:Remove() end)
    end
    AimWarningHeadCircles = {}
    Config.SilentAim.Enabled = false
    Config.AimMagnet.Enabled = false
    Config.ESP.Enabled = false
    Config.Chams.Enabled = false
    Config.Radar.Enabled = false
    _G.RSilentCleanup = nil
    print("[Amethyst] Unload succesfully")
end

-- Initial build and launch
buildAllPages()
showPage("Visual")
toggleWindow(true)
Notify("Amethyst", "By, " .. LocalPlayer.DisplayName .. "!", "success", 3.5)
