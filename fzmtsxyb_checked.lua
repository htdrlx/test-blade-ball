local ZPlayers = game:GetService("Players")
local ZTweenService = game:GetService("TweenService")
local ZUserInputService = game:GetService("UserInputService")
local ZRunService = game:GetService("RunService")
local ZLighting = game:GetService("Lighting")
local player = ZPlayers.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
if playerGui:FindFirstChild("ZuroUI") then playerGui.ZuroUI:Destroy() end
if ZLighting:FindFirstChild("ZuroUIBlur") then ZLighting.ZuroUIBlur:Destroy() end
local COLORS = {
    black = Color3.fromRGB(7, 12, 19),
    card = Color3.fromRGB(10, 18, 28),
    selected = Color3.fromRGB(20, 48, 72),
    control = Color3.fromRGB(15, 30, 45),
    controlHover = Color3.fromRGB(22, 48, 70),
    border = Color3.fromRGB(67, 132, 174),
    divider = Color3.fromRGB(34, 69, 94),
    white = Color3.fromRGB(225, 244, 255),
    text = Color3.fromRGB(194, 224, 242),
    dim = Color3.fromRGB(132, 174, 199),
    muted = Color3.fromRGB(78, 119, 146),
    switchOff = Color3.fromRGB(31, 50, 65),
    switchKnob = Color3.fromRGB(111, 151, 177),
    track = Color3.fromRGB(34, 66, 87),
}
local EASE = TweenInfo.new(0.24, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local FAST = TweenInfo.new(0.16, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local DROP = TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local PAGE = TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local MINIMIZE = TweenInfo.new(0.38, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut)
local function create(className, properties, parent)
    local object = Instance.new(className)
    for key, value in pairs(properties or {}) do object[key] = value end
    object.Parent = parent
    return object
end
local function round(object, pixels)
    return create("UICorner", {CornerRadius = UDim.new(0, pixels)}, object)
end
local function outline(object, color, thickness, transparency)
    return create("UIStroke", {
        Color = color or COLORS.border,
        Thickness = thickness or 1,
        Transparency = transparency or 0,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, object)
end
local function padding(object, left, right, top, bottom)
    return create("UIPadding", {
        PaddingLeft = UDim.new(0, left or 0), PaddingRight = UDim.new(0, right or 0),
        PaddingTop = UDim.new(0, top or 0), PaddingBottom = UDim.new(0, bottom or 0),
    }, object)
end
local function text(parent, value, size, color, bold)
    return create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        Font = bold and Enum.Font.GothamBold or Enum.Font.GothamMedium,
        Text = value or "", TextSize = size or 15,
        TextColor3 = color or COLORS.text,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        TextTruncate = Enum.TextTruncate.AtEnd,
    }, parent)
end
local function tween(object, info, properties)
    local animation = ZTweenService:Create(object, info or EASE, properties)
    animation:Play()
    return animation
end
local function addHover(button, normal, hover)
    button.MouseEnter:Connect(function() tween(button, FAST, {BackgroundColor3 = hover}) end)
    button.MouseLeave:Connect(function() tween(button, FAST, {BackgroundColor3 = normal}) end)
end
local function makeLogo(parent, position)
    local logo = create("TextButton", {
        Position = position, Size = UDim2.fromOffset(34, 34),
        BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 8,
    }, parent)
    local function line(x, y, w, h)
        create("Frame", {Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, h), BackgroundColor3 = COLORS.white, BorderSizePixel = 0}, logo)
    end
    line(0,0,10,2); line(0,0,2,10); line(24,0,10,2); line(32,0,2,10)
    line(0,32,10,2); line(0,24,2,10); line(24,32,10,2); line(32,24,2,10)
    return logo
end
local function makeSearch(parent, position)
    local holder = create("Frame", {Position = position, Size = UDim2.fromOffset(34,34), BackgroundTransparency = 1}, parent)
    local ring = create("Frame", {Position = UDim2.fromOffset(3,2), Size = UDim2.fromOffset(18,18), BackgroundTransparency = 1}, holder)
    round(ring, 20); outline(ring, Color3.fromRGB(168,220,247), 3, 0)
    local handle = create("Frame", {Position = UDim2.fromOffset(19,19), Size = UDim2.fromOffset(12,3), Rotation = 45, BackgroundColor3 = Color3.fromRGB(168,220,247), BorderSizePixel = 0}, holder)
    round(handle, 2)
    return holder
end
local function makeLock(parent)
    local lock = create("Frame", {AnchorPoint = Vector2.new(1,0), Position = UDim2.new(1,-22,0,20), Size = UDim2.fromOffset(27,29), BackgroundTransparency = 1}, parent)
    local shackle = create("Frame", {Position = UDim2.fromOffset(7,1), Size = UDim2.fromOffset(14,15), BackgroundTransparency = 1}, lock)
    round(shackle, 8); outline(shackle, Color3.fromRGB(145,144,154), 2.5, 0)
    local body = create("Frame", {Position = UDim2.fromOffset(4,11), Size = UDim2.fromOffset(20,15), BackgroundColor3 = COLORS.card, BorderSizePixel = 0}, lock)
    round(body,4); outline(body, Color3.fromRGB(145,144,154), 2, 0)
    round(create("Frame", {Position = UDim2.fromOffset(12,16), Size = UDim2.fromOffset(4,7), BackgroundColor3 = Color3.fromRGB(145,144,154), BorderSizePixel = 0}, lock), 2)
    return lock
end
local function makeSlidersIcon(parent)
    local icon = create("Frame", {Size = UDim2.fromOffset(24,28), BackgroundTransparency = 1}, parent)
    for index, x in ipairs({3,11,19}) do
        create("Frame", {Position = UDim2.fromOffset(x,3), Size = UDim2.fromOffset(2,21), BackgroundColor3 = Color3.fromRGB(128,126,137), BorderSizePixel = 0}, icon)
        local y = ({7,15,10})[index]
        round(create("Frame", {Position = UDim2.fromOffset(x-2,y), Size = UDim2.fromOffset(6,5), BackgroundColor3 = Color3.fromRGB(128,126,137), BorderSizePixel = 0}, icon), 2)
    end
    return icon
end
local function makeSwitch(parent, initial, callback)
    local button = create("TextButton", {
        Size = UDim2.fromOffset(51,28), BackgroundColor3 = initial and Color3.fromRGB(178,225,250) or COLORS.switchOff,
        BorderSizePixel = 0, Text = "", AutoButtonColor = false,
    }, parent)
    round(button, 20)
    local knob = create("Frame", {
        Position = initial and UDim2.fromOffset(27,3) or UDim2.fromOffset(4,3),
        Size = UDim2.fromOffset(22,22), BorderSizePixel = 0,
        BackgroundColor3 = initial and Color3.fromRGB(35,34,40) or COLORS.switchKnob,
    }, button)
    round(knob, 20)
    local value = initial == true
    local busy = false
    local function set(nextValue, silent)
        value = nextValue == true
        tween(button, EASE, {BackgroundColor3 = value and Color3.fromRGB(178,225,250) or COLORS.switchOff})
        tween(knob, TweenInfo.new(.26, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            Position = value and UDim2.fromOffset(27,3) or UDim2.fromOffset(4,3),
            BackgroundColor3 = value and Color3.fromRGB(35,34,40) or COLORS.switchKnob,
        })
        if not silent and callback then task.spawn(callback, value) end
    end
    button.MouseButton1Click:Connect(function()
        if busy then return end
        busy = true; set(not value); task.delay(.1, function() busy = false end)
    end)
    local switchObject = {Instance = button, Set = set, Get = function() return value end}
    switchObject.change_state = function(_, state) return set(state) end
    return switchObject
end
local Zuro = {}
Zuro.__index = Zuro
function Zuro:CreateWindow(options)
    options = options or {}
    local screen = create("ScreenGui", {
        Name = "ZuroUI", IgnoreGuiInset = true, ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 100,
    }, playerGui)
    local blur = create("BlurEffect", {Name = "ZuroUIBlur", Size = options.Blur or 0}, ZLighting)
    local scaleRoot = create("Frame", {
        AnchorPoint = Vector2.new(.5,.5), Position = UDim2.fromScale(.5,.5),
        Size = UDim2.fromOffset(1080,680), BackgroundTransparency = 1,
    }, screen)
    local scaler = create("UIScale", {Scale = 1}, scaleRoot)
    local scaleRefreshers = {}
    local function rescale()
        local camera = workspace.CurrentCamera
        if camera then
            local viewport = camera.ViewportSize
            scaler.Scale = math.clamp(math.min(viewport.X/1080, viewport.Y/680) * .70, .30, .90)
            task.defer(function()
                for _, refresh in ipairs(scaleRefreshers) do refresh() end
            end)
        end
    end
    rescale()
    if workspace.CurrentCamera then workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(rescale) end
    local shadow = create("Frame", {
        AnchorPoint = Vector2.new(.5,.5), Position = UDim2.fromScale(.5,.5),
        Size = UDim2.fromOffset(1100,700), BackgroundColor3 = Color3.new(0,0,0),
        BackgroundTransparency = .48, BorderSizePixel = 0, ZIndex = 0,
    }, scaleRoot)
    round(shadow, 25)
    local shell = create("Frame", {
        AnchorPoint = Vector2.new(.5,.5), Position = UDim2.fromScale(.5,.5), Size = UDim2.fromOffset(1080,680),
        BackgroundColor3 = COLORS.black, BorderSizePixel = 0, ClipsDescendants = false, ZIndex = 1,
    }, scaleRoot)
    round(shell, 18)
    local outerBorder = create("Frame", {
        AnchorPoint = Vector2.new(.5,.5), Position = shell.Position,
        Size = shell.Size, BackgroundTransparency = 1, BorderSizePixel = 0,
        Active = false, ZIndex = 100,
    }, scaleRoot)
    round(outerBorder, 18)
    local outerStroke = outline(outerBorder, Color3.fromRGB(158,158,164), 2.5, 0)
    create("UIGradient", {
        Rotation = 90,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(205,205,209)),
            ColorSequenceKeypoint.new(.18, Color3.fromRGB(125,125,130)),
            ColorSequenceKeypoint.new(.62, Color3.fromRGB(72,72,76)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(118,118,122)),
        }),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(.22, .20),
            NumberSequenceKeypoint.new(.72, .42),
            NumberSequenceKeypoint.new(1, .14),
        }),
    }, outerStroke)
    local header = create("TextButton", {
        Size = UDim2.new(1,0,0,94), BackgroundColor3 = Color3.fromRGB(74,74,76), BorderSizePixel = 0,
        Text = "", AutoButtonColor = false, ZIndex = 5,
    }, shell)
    round(header, 18)
    create("UIGradient", {Rotation = 90, Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(111,111,113)),
        ColorSequenceKeypoint.new(.28, Color3.fromRGB(65,65,67)),
        ColorSequenceKeypoint.new(.72, Color3.fromRGB(25,25,27)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(4,4,5)),
    })}, header)
    local sheen = create("Frame", {
        Size = UDim2.new(1,0,0,52), BackgroundColor3 = Color3.fromRGB(255,255,255),
        BackgroundTransparency = 0, BorderSizePixel = 0, Active = false,
    }, header)
    round(sheen, 18)
    create("UIGradient", {
        Rotation = 90,
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, .78),
            NumberSequenceKeypoint.new(.34, .91),
            NumberSequenceKeypoint.new(1, 1),
        }),
    }, sheen)
    local logo = makeLogo(header, UDim2.fromOffset(25,22))
    local title = text(header, options.Title or "Zuro UI", 21, Color3.fromRGB(248,248,248), true)
    title.Position = UDim2.fromOffset(70,9); title.Size = UDim2.fromOffset(210,54)
    local search = makeSearch(header, UDim2.new(1,-55,0,22))
    local body = create("CanvasGroup", {
        Position = UDim2.fromOffset(0,76), Size = UDim2.new(1,0,1,-76),
        BackgroundTransparency = 1, BorderSizePixel = 0, GroupTransparency = 0, ZIndex = 6,
    }, shell)
    local sidebar = create("Frame", {Size = UDim2.fromOffset(270,604), BackgroundTransparency = 1}, body)
    create("Frame", {Position = UDim2.new(1,-1,0,36), Size = UDim2.new(0,1,1,-72), BackgroundColor3 = Color3.fromRGB(46,46,49), BorderSizePixel = 0}, sidebar)
    local tabHolder = create("Frame", {Position = UDim2.fromOffset(28,25), Size = UDim2.fromOffset(212,420), BackgroundTransparency = 1}, sidebar)
    create("UIListLayout", {Padding = UDim.new(0,7), SortOrder = Enum.SortOrder.LayoutOrder}, tabHolder)
    local pageArea = create("Frame", {Position = UDim2.fromOffset(270,0), Size = UDim2.new(1,-270,1,0), BackgroundTransparency = 1, ClipsDescendants = true}, body)
    
local window = Zuro:CreateWindow({
    Title = "Zuro",
    Blur = 0,
    ToggleKey = Enum.KeyCode.RightShift,
})

-- =========================================================
-- ZURO / BLADE BALL
-- One tab only: Main
-- =========================================================

local Main = window:AddTab("Main", "grid")

local AutoParryEnabled = false
local UIS = ZUserInputService
local RunService = ZRunService
local AutoSpamEnabled = false
local ParryRange = 100
local LastParry = 0
local SpamDelay = 0.045

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BallsFolder = workspace:FindFirstChild("Balls")
local remote_eh, get_hash_net, get_hash_parry, get_num_net, get_remote_not, get_key_net_time
local remoteReady = false

-- Kitty-style remote discovery, guarded so the UI still loads if
-- the current executor/game version does not expose these APIs.
task.spawn(function()
    pcall(function()
        if type(getgc) ~= "function" or type(debug) ~= "table" then return end

        local index = ReplicatedStorage:FindFirstChild("Packages")
        local netPackage = index and index:FindFirstChild("_Index")
        local netVersion = netPackage and netPackage:FindFirstChild("sleitnick_net@0.1.0")
        local netFolder = netVersion and netVersion:FindFirstChild("net")
        if not netFolder then return end

        local known = {}

        for _, item in ipairs(getgc(true)) do
            if type(item) == "table" then
                for _, value in pairs(item) do
                    if typeof(value) == "Instance"
                        and value:IsA("RemoteEvent")
                        and value:IsDescendantOf(netFolder) then
                        known[value] = true
                    end
                end
            elseif type(item) == "function" then
                local source = debug.info(item, "s")
                if source and source:find("SwordsController") and source:find("PRY") then
                    local ups = debug.getupvalues(item)
                    local keyTable = ups[3]

                    for _, remote in ipairs(netFolder:GetDescendants()) do
                        if remote:IsA("RemoteEvent")
                            and not known[remote]
                            and remote.Name:sub(1,3) == "RE/"
                            and #remote.Name >= 32
                            and type(ups[8]) == "string"
                            and get_remote_not == nil
                            and type(keyTable) == "table"
                            and type(keyTable[1]) == "table" then

                            get_key_net_time = ups[4]
                            get_num_net = keyTable[1][keyTable[3]]
                            get_remote_not = remote
                            get_hash_net = ups[8]
                            if type(ups[3]) == "table" then
                                get_hash_parry = ups[3][2]
                            end
                            remote_eh = remote
                            remoteReady = remote_eh ~= nil
                            return
                        end
                    end
                end
            end
        end
    end)
end)

local function fireParry()
    if not (remote_eh and get_hash_net and get_hash_parry and get_key_net_time and get_num_net and get_remote_not) then
        return false
    end

    local cam = workspace.CurrentCamera
    local char = player.Character
    if not cam or not char then return false end

    local ok, result = pcall(function()
        local eventData = {}
        local alive = workspace:FindFirstChild("Alive")

        if alive then
            for _, entity in ipairs(alive:GetChildren()) do
                if entity.PrimaryPart then
                    local sp = cam:WorldToScreenPoint(entity.PrimaryPart.Position)
                    eventData[entity.Name] = sp
                end
            end
        end

        local aimTarget
        if UIS.TouchEnabled and not UIS.MouseEnabled then
            local vp = cam.ViewportSize
            aimTarget = {vp.X / 2, vp.Y / 2}
        else
            local mouse = UIS:GetMouseLocation()
            aimTarget = {mouse.X, mouse.Y}
        end

        local timeStr = tostring(math.floor(workspace:GetServerTimeNow() * 100))
        local key = get_key_net_time(get_num_net, "TIME")
        if type(key) ~= "string" or #key == 0 then return false end

        local token = ""
        for i = 1, #timeStr do
            token = token .. string.char(bit32.bxor(
                (timeStr:byte(i) + i) % 256,
                key:byte((i - 1) % #key + 1)
            ))
        end

        remote_eh:FireServer(
            get_hash_net, get_hash_parry, token, get_num_not,
            cam.CFrame, eventData, aimTarget, false
        )
        return true
    end)

    return ok and result == true
end

local function ping()
    local ok, value = pcall(function()
        return game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue()
    end)
    return ok and value or 80
end

local function autoParryStep()
    if not AutoParryEnabled or not BallsFolder then return end

    local char = player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    for _, ball in ipairs(BallsFolder:GetChildren()) do
        if ball:GetAttribute("realBall") then
            local distance = (hrp.Position - ball.Position).Magnitude
            local zoomies = ball:FindFirstChild("zoomies")
            local shouldParry = false

            if zoomies then
                local velocity = zoomies.VectorVelocity
                if velocity.Magnitude > 1 then
                    local direction = (hrp.Position - ball.Position).Unit
                    local dot = direction:Dot(velocity.Unit)
                    local p = ping() / 1000

                    if dot >= (0.3 - p * 0.5) then
                        local threshold = velocity.Magnitude * (p + 0.016) * 8 * 0.43
                        threshold *= (ParryRange / 100)
                        shouldParry = distance <= math.max(9 * (ParryRange / 100), threshold)
                    end
                end
            else
                shouldParry =
                    distance <= math.max(1, 12 * (ParryRange / 100))
                    and ball.AssemblyLinearVelocity.Magnitude > 1
            end

            if shouldParry and os.clock() - LastParry >= 0.04 then
                if fireParry() then
                    LastParry = os.clock()
                end
            end
        end
    end
end

RunService.Stepped:Connect(autoParryStep)

-- Controlled spam loop: no unbounded tight loop.
task.spawn(function()
    while task.wait(SpamDelay) do
        if AutoSpamEnabled and os.clock() - LastParry >= SpamDelay then
            if fireParry() then LastParry = os.clock() end
        end
    end
end)

-- ==================== MAIN / COMBAT ====================

local Combat = Main:AddSection({
    Column = "Left",
    Title = "Combat",
    Description = "Auto parry and timing controls",
    Enabled = true,
})

Combat:AddToggle({
    Name = "Auto Parry",
    Default = false,
    Callback = function(state)
        AutoParryEnabled = state
    end,
})

Combat:AddSlider({
    Name = "Parry Range",
    Min = 1,
    Max = 100,
    Default = 100,
    Callback = function(value)
        ParryRange = math.clamp(value, 1, 100)
    end,
})

Combat:AddButton({
    Name = "Parry Now",
    Callback = function()
        if fireParry() then
            LastParry = os.clock()
            window:Notify({Title="Zuro", Content="Parry sent", Duration=1.5})
        else
            window:Notify({Title="Zuro", Content="Parry remote not ready", Duration=2})
        end
    end,
})

local Spam = Main:AddSection({
    Column = "Right",
    Title = "Spam",
    Description = "Fast parry controls",
    Enabled = true,
})

Spam:AddToggle({
    Name = "Auto Spam",
    Default = false,
    Callback = function(state)
        AutoSpamEnabled = state
    end,
})

Spam:AddButton({
    Name = "Spam Parry",
    Callback = function()
        task.spawn(function()
            for _ = 1, 12 do
                if fireParry() then LastParry = os.clock() end
                task.wait(0.04)
            end
        end)
    end,
})

-- ==================== VISUALS ====================

local Visuals = Main:AddSection({
    Column = "Left",
    Title = "Visuals",
    Description = "Match information and appearance",
    Enabled = true,
})

local trailEnabled = false

local function updateTrail(ball)
    if not ball or not ball:IsA("BasePart") then return end

    local a0 = ball:FindFirstChild("ZuroTrailA0")
    local a1 = ball:FindFirstChild("ZuroTrailA1")
    local trail = ball:FindFirstChild("ZuroTrail")

    if trailEnabled then
        if not a0 then
            a0 = Instance.new("Attachment")
            a0.Name = "ZuroTrailA0"
            a0.Position = Vector3.new(0, 1, 0)
            a0.Parent = ball
        end
        if not a1 then
            a1 = Instance.new("Attachment")
            a1.Name = "ZuroTrailA1"
            a1.Position = Vector3.new(0, -1, 0)
            a1.Parent = ball
        end
        if not trail then
            trail = Instance.new("Trail")
            trail.Name = "ZuroTrail"
            trail.Attachment0 = a0
            trail.Attachment1 = a1
            trail.Lifetime = 0.45
            trail.Transparency = NumberSequence.new(0, 1)
            trail.LightEmission = 0.7
            trail.Parent = ball
        end
        trail.Color = ColorSequence.new(Color3.fromRGB(150, 220, 255))
    else
        if trail then trail:Destroy() end
        if a0 then a0:Destroy() end
        if a1 then a1:Destroy() end
    end
end

Visuals:AddToggle({
    Name = "Ball Trail",
    Default = false,
    Callback = function(state)
        trailEnabled = state
        if BallsFolder then
            for _, ball in ipairs(BallsFolder:GetChildren()) do
                updateTrail(ball)
            end
        end
    end,
})

Visuals:AddSlider({
    Name = "FOV",
    Min = 70,
    Max = 120,
    Default = 70,
    Callback = function(value)
        local cam = workspace.CurrentCamera
        if cam then cam.FieldOfView = value end
    end,
})

-- ==================== PERFORMANCE ====================

local Performance = Main:AddSection({
    Column = "Right",
    Title = "Performance",
    Description = "Optional FPS-friendly settings",
    Enabled = true,
})

Performance:AddToggle({
    Name = "Low Graphics",
    Default = false,
    Callback = function(state)
        pcall(function()
            settings().Rendering.QualityLevel =
                state and Enum.QualityLevel.Level01 or Enum.QualityLevel.Automatic
            ZLighting.GlobalShadows = not state
            ZLighting.FogEnd = state and math.huge or 100000
        end)
    end,
})

Performance:AddButton({
    Name = "Check Parry Status",
    Callback = function()
        window:Notify({
            Title = "Zuro",
            Content = remoteReady and "Parry remote ready" or "Waiting for parry remote...",
            Duration = 2.5,
        })
    end,
})

window:SelectTab(Main)
window:Notify({
    Title = "Zuro",
    Content = "Main loaded • Combat / Spam / Visuals",
    Duration = 3,
})
