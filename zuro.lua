do
    pcall(function()
        local old_dinfo
        old_dinfo = hookfunction(getrenv().debug.info, function(f, t)
            if type(f) == "function" then
                return "[C]"
            elseif f == 4 and t == "s" then
                return "ReplicatedStorage.Controllers.SwordsController "
            end
            return old_dinfo(f, t)
        end)

        local old_gfenv
        old_gfenv = hookfunction(getrenv().getfenv, function(l)
            if l ~= nil and type(l) == "number" then
                if l >= 1 and l <= 10 then return old_gfenv(10) end
            end
            return old_gfenv(l)
        end)
    end)
end

function convertStringToTable(inputString)
    local result = {}
    for value in string.gmatch(inputString, "([^,]+)") do
        local trimmedValue = value:match("^%s*(.-)%s*$")
        table.insert(result, trimmedValue)
    end

    return result
end

function convertTableToString(inputTable)
    return table.concat(inputTable, ", ")
end

local UserInputService = cloneref(game:GetService('UserInputService'))
local TweenService = cloneref(game:GetService('TweenService'))
local HttpService = cloneref(game:GetService('HttpService'))
local TextService = cloneref(game:GetService('TextService'))
local RunService = cloneref(game:GetService('RunService'))
local Players = cloneref(game:GetService('Players'))
local CoreGui = cloneref(game:GetService('CoreGui'))
local Debris = cloneref(game:GetService('Debris'))

local mouse = Players.LocalPlayer:GetMouse()
local old_Zuro = CoreGui:FindFirstChild('Zuro✿')

if old_Zuro then
    Debris:AddItem(old_Zuro, 0)
end

pcall(function()
    if getgenv()._Zuro_Cleanup then
        getgenv()._Zuro_Cleanup()
        getgenv()._Zuro_Cleanup = nil
    end
end)

if not isfolder("Zuro") then
    makefolder("Zuro")
end

local Connections = setmetatable({
    disconnect = function(self, connection)
        if not self[connection] then
            return
        end

        self[connection]:Disconnect()
        self[connection] = nil
    end,
    disconnect_all = function(self)
        for _, value in self do
            if typeof(value) == 'function' then
                continue
            end

            value:Disconnect()
        end
    end
}, Connections)

local Config = setmetatable({
    save = function(self: any, file_name: any, config: any)
        local success_save, result = pcall(function()
            local flags = HttpService:JSONEncode(config)
            writefile('Zuro/'..file_name..'.json', flags)
        end)

        if not success_save then
            warn('failed to save config', result)
        end
    end,
    load = function(self: any, file_name: any, config: any)
        local success_load, result = pcall(function()
            if not isfile('Zuro/'..file_name..'.json') then
                self:save(file_name, config)

                return
            end

            local flags = readfile('Zuro/'..file_name..'.json')

            if not flags then
                self:save(file_name, config)

                return
            end

            return HttpService:JSONDecode(flags)
        end)

        if not success_load then
            warn('failed to load config', result)
        end

        if not result then
            result = {
                _flags = {},
                _keybinds = {}
            }
        end

        return result
    end
}, Config)

local Library = {
    _config = Config:load(game.GameId, { _flags = {}, _keybinds = {} }),

    _choosing_keybind = false,
    _device = nil,

    _ui_open = true,
    _ui_scale = 1,
    _ui = nil,

    _dragging = false,
    _drag_start = nil,
    _container_position = nil,

    _flag_registry = {}
}
Library.__index = Library

function Library.new()
    local self = setmetatable({
        _tab = 0,
    }, Library)

    self:create_ui()

    return self
end

local NotificationContainer = Instance.new("Frame")
NotificationContainer.Name = "RobloxCoreGuis"
NotificationContainer.Size = UDim2.new(0, 300, 0, 0)
NotificationContainer.AnchorPoint = Vector2.new(0, 1)
NotificationContainer.Position = UDim2.new(0, 22, 1, -22)
NotificationContainer.BackgroundTransparency = 1
NotificationContainer.ClipsDescendants = false
local NotificationRoot = CoreGui:FindFirstChild("RobloxGui")
local NotificationHost = NotificationRoot and NotificationRoot:FindFirstChild("RobloxCoreGuis")

if not NotificationHost then
    NotificationHost = Instance.new("ScreenGui")
    NotificationHost.Name = "ZuroNotifications"
    NotificationHost.ResetOnSpawn = false
    NotificationHost.IgnoreGuiInset = true
    NotificationHost.DisplayOrder = 101
    NotificationHost.Parent = NotificationRoot or CoreGui
end

NotificationContainer.Parent = NotificationHost
NotificationContainer.AutomaticSize = Enum.AutomaticSize.Y

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.FillDirection = Enum.FillDirection.Vertical
UIListLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 8)
UIListLayout.Parent = NotificationContainer

function Library.SendNotification(settings)
    local Notification = Instance.new("Frame")
    Notification.Size = UDim2.new(1, 0, 0, 62)
    Notification.BackgroundTransparency = 1
    Notification.BorderSizePixel = 0
    Notification.Name = "Notification"
    Notification.Parent = NotificationContainer

    local InnerFrame = Instance.new("Frame")
    InnerFrame.Size = UDim2.new(1, 0, 1, 0)
    InnerFrame.Position = UDim2.new(-1, -320, 0, 0)
    InnerFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    InnerFrame.BackgroundTransparency = 0
    InnerFrame.BorderSizePixel = 0
    InnerFrame.Name = "InnerFrame"
    InnerFrame.ZIndex = 1
    InnerFrame.Parent = Notification

    local InnerGradient = Instance.new("UIGradient")
    InnerGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0.00, Color3.fromRGB(92, 92, 92)),
        ColorSequenceKeypoint.new(0.34, Color3.fromRGB(18, 18, 18)),
        ColorSequenceKeypoint.new(1.00, Color3.fromRGB(0, 0, 0))
    }
    InnerGradient.Rotation = 90
    InnerGradient.Parent = InnerFrame

    local InnerUICorner = Instance.new("UICorner")
    InnerUICorner.CornerRadius = UDim.new(0, 8)
    InnerUICorner.Parent = InnerFrame

    local InnerStroke = Instance.new("UIStroke")
    InnerStroke.Color = Color3.fromRGB(255, 255, 255)
    InnerStroke.Transparency = 0.72
    InnerStroke.Thickness = 1
    InnerStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    InnerStroke.Parent = InnerFrame

    local Title = Instance.new("TextLabel")
    Title.Text = settings.title or "Notification"
    Title.TextColor3 = Color3.fromRGB(238, 238, 242)
    Title.FontFace = Font.new('rbxasset://fonts/families/SFPro.json', Enum.FontWeight.Bold, Enum.FontStyle.Normal)
    Title.TextSize = 16
    Title.Size = UDim2.new(1, -28, 0, 15)
    Title.Position = UDim2.new(0, 14, 0, 12)
    Title.BackgroundTransparency = 1
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.TextYAlignment = Enum.TextYAlignment.Center
    Title.TextTruncate = Enum.TextTruncate.AtEnd
    Title.ZIndex = 2
    Title.Parent = InnerFrame

    local Body = Instance.new("TextLabel")
    Body.Text = settings.text or "Notification message"
    Body.TextColor3 = Color3.fromRGB(142, 142, 151)
    Body.FontFace = Font.new('rbxasset://fonts/families/SFPro.json', Enum.FontWeight.Bold, Enum.FontStyle.Normal)
    Body.TextSize = 14
    Body.Size = UDim2.new(1, -28, 0, 14)
    Body.Position = UDim2.new(0, 14, 0, 33)
    Body.BackgroundTransparency = 1
    Body.TextXAlignment = Enum.TextXAlignment.Left
    Body.TextYAlignment = Enum.TextYAlignment.Center
    Body.TextTruncate = Enum.TextTruncate.AtEnd
    Body.ZIndex = 2
    Body.Parent = InnerFrame

    task.spawn(function()
        local tweenIn = TweenService:Create(InnerFrame, TweenInfo.new(0.32, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            Position = UDim2.new(0, 0, 0, 0)
        })
        tweenIn:Play()

        task.wait(settings.duration or 5)

        local tweenOut = TweenService:Create(InnerFrame, TweenInfo.new(0.32, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
            Position = UDim2.new(-1, -320, 0, 0)
        })
        tweenOut:Play()
        tweenOut.Completed:Wait()
        Notification:Destroy()
    end)
end

function Library:get_screen_scale()
    local viewport_size_x = workspace.CurrentCamera.ViewportSize.X

    self._ui_scale = viewport_size_x / 1400
end

function Library:get_device()
    local device = 'Unknown'

    if not UserInputService.TouchEnabled and UserInputService.KeyboardEnabled and UserInputService.MouseEnabled then
        device = 'PC'
    elseif UserInputService.TouchEnabled then
        device = 'Mobile'
    elseif UserInputService.GamepadEnabled then
        device = 'Console'
    end

    self._device = device
end

function Library:removed(action: any)
    self._ui.AncestryChanged:Once(action)
end

function Library:flag_type(flag: any, flag_type: any)
    if Library._config._flags[flag] == nil then
        return
    end

    return typeof(Library._config._flags[flag]) == flag_type
end

function Library:remove_table_value(__table: any, table_value: string)
    for index, value in __table do
        if value ~= table_value then
            continue
        end

        table.remove(__table, index)
    end
end

function Library:create_ui()
    local old_Zuro = CoreGui:FindFirstChild('Zuro✿')

    if old_Zuro then
        Debris:AddItem(old_Zuro, 0)
    end

    local Zuro = Instance.new('ScreenGui')
    Zuro.ResetOnSpawn = false
    Zuro.Name = 'Zuro✿'
    Zuro.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    Zuro.Parent = CoreGui

    local Container = Instance.new('Frame')
    Container.ClipsDescendants = true
    Container.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Container.AnchorPoint = Vector2.new(0.5, 0.5)
    Container.Name = 'Container'
    Container.BackgroundTransparency = 0
    Container.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Container.Position = UDim2.new(0.5, 0, 0.5, 0)
    Container.Size = UDim2.new(0, 0, 0, 0)
    Container.Active = true
    Container.BorderSizePixel = 0
    Container.Parent = Zuro

    local ShadowHolder = Instance.new('Frame')
    ShadowHolder.Name = 'ShadowHolder'
    ShadowHolder.AnchorPoint = Container.AnchorPoint
    ShadowHolder.Position = Container.Position
    ShadowHolder.Size = Container.Size
    ShadowHolder.BackgroundTransparency = 1
    ShadowHolder.BorderSizePixel = 0
    ShadowHolder.ZIndex = 0
    ShadowHolder.Parent = Zuro
    ShadowHolder.Visible = false

    local ShadowOuter = Instance.new('ImageLabel')
    ShadowOuter.Name = 'SoftShadowOuter'
    ShadowOuter.AnchorPoint = Vector2.new(0.5, 0.5)
    ShadowOuter.Position = UDim2.new(0.5, 0, 0.5, 2)
    ShadowOuter.Size = UDim2.new(1, 58, 1, 58)
    ShadowOuter.BackgroundTransparency = 1
    ShadowOuter.BorderSizePixel = 0
    ShadowOuter.Image = 'rbxassetid://6014261993'
    ShadowOuter.ImageColor3 = Color3.fromRGB(0, 0, 0)
    ShadowOuter.ImageTransparency = 0.43
    ShadowOuter.ScaleType = Enum.ScaleType.Slice
    ShadowOuter.SliceCenter = Rect.new(49, 49, 450, 450)
    ShadowOuter.ZIndex = 0
    ShadowOuter.Parent = ShadowHolder

    local ShadowInner = Instance.new('ImageLabel')
    ShadowInner.Name = 'SoftShadowInner'
    ShadowInner.AnchorPoint = Vector2.new(0.5, 0.5)
    ShadowInner.Position = UDim2.new(0.5, 0, 0.5, 1)
    ShadowInner.Size = UDim2.new(1, 32, 1, 32)
    ShadowInner.BackgroundTransparency = 1
    ShadowInner.BorderSizePixel = 0
    ShadowInner.Image = 'rbxassetid://6014261993'
    ShadowInner.ImageColor3 = Color3.fromRGB(0, 0, 0)
    ShadowInner.ImageTransparency = 0.30
    ShadowInner.ScaleType = Enum.ScaleType.Slice
    ShadowInner.SliceCenter = Rect.new(49, 49, 450, 450)
    ShadowInner.ZIndex = 0
    ShadowInner.Parent = ShadowHolder

    Container:GetPropertyChangedSignal('Position'):Connect(function()
        ShadowHolder.Position = Container.Position
    end)

    Container:GetPropertyChangedSignal('Size'):Connect(function()
        ShadowHolder.Size = Container.Size
    end)

    local ContainerGradient = Instance.new("UIGradient")
    ContainerGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0.00, Color3.fromRGB(145, 145, 145)),
        ColorSequenceKeypoint.new(0.11, Color3.fromRGB(0, 0, 0)),
        ColorSequenceKeypoint.new(1.00, Color3.fromRGB(0, 0, 0))
    }
    ContainerGradient.Rotation = 90
    ContainerGradient.Parent = Container

    local Background = Instance.new('ImageLabel')
    Background.Name = 'Background'
    Background.Size = UDim2.new(1, 0, 1, 0)
    Background.Position = UDim2.new(0, 0, 0, 0)
    Background.BackgroundTransparency = 1
    Background.BorderSizePixel = 0
    Background.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Background.Image = ''
    Background.ImageTransparency = 0.5
    Background.ScaleType = Enum.ScaleType.Crop
    Background.Visible = false
    Background.ZIndex = 0
    Background.Parent = Container

    local UICorner = Instance.new('UICorner')
    UICorner.CornerRadius = UDim.new(0, 10)
    UICorner.Parent = Background

    local Texture = Instance.new('ImageLabel')
    Texture.Name = 'Texture'
    Texture.Size = UDim2.new(1, 0, 1, 0)
    Texture.Position = UDim2.new(0, 0, 0, 0)
    Texture.BackgroundTransparency = 1
    Texture.BorderSizePixel = 0
    Texture.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Texture.Image = 'rbxassetid://9968344227'
    Texture.ImageColor3 = Color3.fromRGB(0, 0, 0)
    Texture.ImageTransparency = 0.88
    Texture.ScaleType = Enum.ScaleType.Tile
    Texture.TileSize = UDim2.new(0, 128, 0, 128)
    Texture.ZIndex = 0
    Texture.Parent = Container

    local SideBar = Instance.new("Frame")
    SideBar.Name = "GradientSide"
    SideBar.Parent = Container
    SideBar.Size = UDim2.new(0, 10, 1, 0)
    SideBar.Position = UDim2.new(0, 0, 0, 0)
    SideBar.BackgroundTransparency = 1

    local SideGradient = Instance.new("UIGradient")
    SideGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0.00, Color3.fromRGB(92, 92, 92)),
        ColorSequenceKeypoint.new(0.11, Color3.fromRGB(0, 0, 0)),
        ColorSequenceKeypoint.new(1.00, Color3.fromRGB(0, 0, 0))
    }
    SideGradient.Rotation = 90
    SideGradient.Parent = SideBar

    local UICorner = Instance.new('UICorner')
    UICorner.CornerRadius = UDim.new(0, 10)
    UICorner.Parent = Container

    local UIStroke = Instance.new('UIStroke')
    UIStroke.Color = Color3.fromRGB(68, 68, 68)
    UIStroke.Transparency = 0.58
    UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    UIStroke.Parent = Container

    local Handler = Instance.new('Frame')
    Handler.BackgroundTransparency = 1
    Handler.Name = 'Handler'
    Handler.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Handler.Size = UDim2.new(0, 752, 0, 479)
    Handler.BorderSizePixel = 0
    Handler.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Handler.Parent = Container

    local Tabs = Instance.new('ScrollingFrame')
    Tabs.ScrollBarImageTransparency = 1
    Tabs.ScrollBarThickness = 0
    Tabs.Name = 'Tabs'
    Tabs.Size = UDim2.new(0, 129, 0, 401)
    Tabs.Selectable = false
    Tabs.AutomaticCanvasSize = Enum.AutomaticSize.XY
    Tabs.BackgroundTransparency = 1
    Tabs.Position = UDim2.new(0, 18, 0, 67)
    Tabs.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Tabs.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Tabs.BorderSizePixel = 0
    Tabs.CanvasSize = UDim2.new(0, 0, 0.5, 0)
    Tabs.Parent = Handler

    local UIListLayout = Instance.new('UIListLayout')
    UIListLayout.Padding = UDim.new(0, 4)
    UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    UIListLayout.Parent = Tabs

    local ClientName = Instance.new('TextLabel')
    ClientName.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.Heavy, Enum.FontStyle.Normal)
    ClientName.TextStrokeColor3 = Color3.fromRGB(255, 255, 255)
    ClientName.TextStrokeTransparency = 1
    ClientName.TextColor3 = Color3.fromRGB(255, 255, 255)
    ClientName.TextTransparency = 0
    ClientName.Text = 'Zuro✿'
    ClientName.Name = 'ClientName'
    ClientName.Size = UDim2.new(0, 110, 0, 19)
    ClientName.AnchorPoint = Vector2.new(0, 0.5)
    ClientName.Position = UDim2.new(0, 43, 0, 26)
    ClientName.BackgroundTransparency = 1
    ClientName.TextXAlignment = Enum.TextXAlignment.Left
    ClientName.BorderSizePixel = 0
    ClientName.BorderColor3 = Color3.fromRGB(0, 0, 0)
    ClientName.TextSize = 16
    ClientName.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    ClientName.Parent = Handler

    local Logo = Instance.new('ImageLabel')
    Logo.Name = 'Logo'
    Logo.Size = UDim2.new(0, 26, 0, 26)
    Logo.AnchorPoint = Vector2.new(0, 0.5)
    Logo.Position = UDim2.new(0, 14, 0, 26)
    Logo.BackgroundTransparency = 1
    Logo.BorderSizePixel = 0
    Logo.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Logo.Image = 'rbxassetid://86155014390461'
    Logo.ImageColor3 = Color3.fromRGB(255, 255, 255)
    Logo.ImageTransparency = 0
    Logo.ScaleType = Enum.ScaleType.Fit
    Logo.Parent = Handler
    local Pin = Instance.new('Frame')
    Pin.Name = 'Pin'
    Pin.Position = UDim2.new(0, 18, 0, 79)
    Pin.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Pin.Size = UDim2.new(0, 2, 0, 16)
    Pin.BorderSizePixel = 0
    Pin.BackgroundColor3 = Color3.fromRGB(224, 224, 224)
    Pin.Parent = Handler

    local UICorner2 = Instance.new('UICorner')
    UICorner2.CornerRadius = UDim.new(1, 0)
    UICorner2.Parent = Pin

    local Divider = Instance.new('Frame')
    Divider.Name = 'Divider'
    Divider.BackgroundTransparency = 0.65
    Divider.Position = UDim2.new(0, 164, 0, 75)
    Divider.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Divider.Size = UDim2.new(0, 1, 0, 330)
    Divider.BorderSizePixel = 0
    Divider.BackgroundColor3 = Color3.fromRGB(68, 68, 68)
    Divider.Parent = Handler

    local Sections = Instance.new('Folder')
    Sections.Name = 'Sections'
    Sections.Parent = Handler

    local Minimize = Instance.new('TextButton')
    Minimize.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
    Minimize.TextColor3 = Color3.fromRGB(0, 0, 0)
    Minimize.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Minimize.Text = ''
    Minimize.AutoButtonColor = false
    Minimize.Name = 'Minimize'
    Minimize.BackgroundTransparency = 1
    Minimize.Position = UDim2.new(0.020057305693626404, 0, 0.02922755666077137, 0)
    Minimize.Size = UDim2.new(0, 24, 0, 24)
    Minimize.BorderSizePixel = 0
    Minimize.TextSize = 14
    Minimize.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Minimize.Parent = Handler

    local Search = Instance.new('ImageButton')
    Search.Name = 'Search'
    Search.AutoButtonColor = false
    Search.BackgroundTransparency = 1
    Search.BorderSizePixel = 0
    Search.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Search.Image = 'rbxassetid://102373102520464'
    Search.ImageColor3 = Color3.fromRGB(188, 188, 188)
    Search.ImageTransparency = 0
    Search.ScaleType = Enum.ScaleType.Fit
    Search.AnchorPoint = Vector2.new(1, 0.5)
    Search.Position = UDim2.new(0, 734, 0, 26)
    Search.Size = UDim2.new(0, 22, 0, 22)
    Search.Parent = Handler

    local UIScale = Instance.new('UIScale')
    UIScale.Parent = Container

    local ShadowScale
    if UserInputService.TouchEnabled then
        ShadowScale = Instance.new('UIScale')
        ShadowScale.Scale = UIScale.Scale
        ShadowScale.Parent = ShadowHolder
    end

    self._ui = Zuro

    local function on_drag(input: InputObject, process: boolean)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            self._dragging = true
            self._drag_start = input.Position
            self._container_position = Container.Position

            Connections['container_input_ended'] = input.Changed:Connect(function()
                if input.UserInputState ~= Enum.UserInputState.End then
                    return
                end

                Connections:disconnect('container_input_ended')
                self._dragging = false
            end)
        end
    end

    local function update_drag(input: any)
        local delta = input.Position - self._drag_start
        local position = UDim2.new(self._container_position.X.Scale, self._container_position.X.Offset + delta.X, self._container_position.Y.Scale, self._container_position.Y.Offset + delta.Y)

        TweenService:Create(Container, TweenInfo.new(0.2), {
            Position = position
        }):Play()
    end

    local function drag(input: InputObject, process: boolean)
        if not self._dragging then
            return
        end

        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            update_drag(input)
        end
    end

    Connections['container_input_began'] = Container.InputBegan:Connect(on_drag)
    Connections['input_changed'] = UserInputService.InputChanged:Connect(drag)

    self:removed(function()
        self._ui = nil
        Connections:disconnect_all()
    end)

    function self:change_visiblity(state: boolean)
        Library._ui_open = state
        ShadowHolder.Visible = state
        if state then
            ContainerGradient.Enabled = true
            ContainerGradient.Color = ColorSequence.new{
                ColorSequenceKeypoint.new(0.00, Color3.fromRGB(145, 145, 145)),
                ColorSequenceKeypoint.new(0.11, Color3.fromRGB(0, 0, 0)),
                ColorSequenceKeypoint.new(1.00, Color3.fromRGB(0, 0, 0))
            }
            ContainerGradient.Rotation = 90
            Container.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Logo.Position = UDim2.new(0, 14, 0, 26)
            ClientName.Position = UDim2.new(0, 43, 0, 26)

            TweenService:Create(Container, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                Size = UDim2.fromOffset(752, 479)
            }):Play()
        else
            ContainerGradient.Enabled = true
            ContainerGradient.Color = ColorSequence.new{
                ColorSequenceKeypoint.new(0.00, Color3.fromRGB(72, 72, 72)),
                ColorSequenceKeypoint.new(1.00, Color3.fromRGB(0, 0, 0))
            }
            ContainerGradient.Rotation = 90
            Container.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Logo.Position = UDim2.new(0, 10, 0, 26)
            ClientName.Position = UDim2.new(0, 39, 0, 26)

            TweenService:Create(Container, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                Size = UDim2.fromOffset(104.5, 52)
            }):Play()
        end
    end

    function self:set_gui_visibility(state: boolean)
        if not self._ui then return end
        if state then
            self._ui.Enabled = true
            Container.Size = UDim2.fromOffset(0, 0)
            TweenService:Create(Container, TweenInfo.new(0.35, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {
                Size = UDim2.fromOffset(752, 479)
            }):Play()
        else
            local t = TweenService:Create(Container, TweenInfo.new(0.25, Enum.EasingStyle.Exponential, Enum.EasingDirection.In), {
                Size = UDim2.fromOffset(0, 0)
            })
            t:Play()
            t.Completed:Once(function()
                self._ui.Enabled = false
            end)
        end
    end

    function self:load()
        self:get_device()

        if self._device == 'Mobile' or self._device == 'Unknown' then
            self:get_screen_scale()
            UIScale.Scale = self._ui_scale
            if ShadowScale then
                ShadowScale.Scale = self._ui_scale
            end

            Connections['ui_scale'] = workspace.CurrentCamera:GetPropertyChangedSignal('ViewportSize'):Connect(function()
                self:get_screen_scale()
                UIScale.Scale = self._ui_scale
                if ShadowScale then
                    ShadowScale.Scale = self._ui_scale
                end
            end)
        end

        ShadowHolder.Visible = true

        TweenService:Create(Container, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            Size = UDim2.fromOffset(752, 479)
        }):Play()
    end

    function self:update_tabs(tab: TextButton)
        for index, object in Tabs:GetChildren() do
            if object.Name ~= 'Tab' then
                continue
            end

            if object == tab then
                if object.BackgroundTransparency ~= 0.5 then
                    local offset = object.LayoutOrder * 42

                    TweenService:Create(Pin, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Position = UDim2.new(0, 18, 0, 79 + offset)
                    }):Play()

                    TweenService:Create(object, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        BackgroundTransparency = 0.5
                    }):Play()

                    TweenService:Create(object.TextLabel, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        TextTransparency = 0,
                        TextColor3 = Color3.fromRGB(255, 255, 255)
                    }):Play()

                    TweenService:Create(object.TextLabel.UIGradient, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Offset = Vector2.new(1, 0)
                    }):Play()

                    TweenService:Create(object.Icon, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        ImageColor3 = object.Icon:GetAttribute('ActiveColor') or Color3.fromRGB(255, 255, 255)
                    }):Play()
                end

                continue
            end

            if object.BackgroundTransparency ~= 1 then
                TweenService:Create(object, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    BackgroundTransparency = 1
                }):Play()

                TweenService:Create(object.TextLabel, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    TextTransparency = 0,
                    TextColor3 = Color3.fromRGB(138, 138, 138)
                }):Play()

                TweenService:Create(object.TextLabel.UIGradient, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    Offset = Vector2.new(0, 0)
                }):Play()

                TweenService:Create(object.Icon, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    ImageColor3 = object.Icon:GetAttribute('IdleColor') or Color3.fromRGB(138, 138, 138)
                }):Play()
            end
        end
    end

    function self:update_sections(left_section: ScrollingFrame, right_section: ScrollingFrame)
        for _, object in Sections:GetChildren() do
            if object == left_section or object == right_section then
                object.Visible = true

                continue
            end

            object.Visible = false
        end
    end

    function self:create_tab(title: string, icon: string, icon_size: number, idle_color: Color3?, active_color: Color3?)
        local TabManager = {}

        local font_params = Instance.new('GetTextBoundsParams')
        font_params.Text = title
        font_params.Font = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
        font_params.Size = 13
        font_params.Width = 10000

        local font_size = TextService:GetTextBoundsAsync(font_params)
        local first_tab = not Tabs:FindFirstChild('Tab')

        local Tab = Instance.new('TextButton')
        Tab.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
        Tab.TextColor3 = Color3.fromRGB(0, 0, 0)
        Tab.BorderColor3 = Color3.fromRGB(0, 0, 0)
        Tab.Text = ''
        Tab.AutoButtonColor = false
        Tab.BackgroundTransparency = 1
        Tab.Name = 'Tab'
        Tab.Size = UDim2.new(0, 129, 0, 38)
        Tab.BorderSizePixel = 0
        Tab.TextSize = 14
        Tab.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
        Tab.Parent = Tabs
        Tab.LayoutOrder = self._tab

        local UICorner = Instance.new('UICorner')
        UICorner.CornerRadius = UDim.new(0, 5)
        UICorner.Parent = Tab

        local TextLabel = Instance.new('TextLabel')
        TextLabel.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
        TextLabel.TextColor3 = Color3.fromRGB(138, 138, 138)
        TextLabel.TextTransparency = 0
        TextLabel.Text = title
        TextLabel.Size = UDim2.new(0, font_size.X, 0, 16)
        TextLabel.AnchorPoint = Vector2.new(0, 0.5)
        TextLabel.Position = UDim2.new(0, 37, 0.5, 0)
        TextLabel.BackgroundTransparency = 1
        TextLabel.TextXAlignment = Enum.TextXAlignment.Left
        TextLabel.BorderSizePixel = 0
        TextLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
        TextLabel.TextSize = 13
        TextLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        TextLabel.Parent = Tab

        local UIGradient = Instance.new('UIGradient')
        UIGradient.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
            ColorSequenceKeypoint.new(0.7, Color3.fromRGB(155, 155, 155)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(58, 58, 58))
        }
        UIGradient.Parent = TextLabel

        local Icon = Instance.new('ImageLabel')
        Icon.Name = 'Icon'
        Icon.Size = UDim2.new(0, icon_size or 16, 0, icon_size or 16)
        Icon.AnchorPoint = Vector2.new(0.5, 0.5)
        Icon.Position = UDim2.new(0, 19, 0.5, 0)
        Icon.BackgroundTransparency = 1
        Icon.BorderSizePixel = 0
        Icon.BorderColor3 = Color3.fromRGB(0, 0, 0)
        Icon.Image = icon or ''
        Icon.ImageColor3 = idle_color or Color3.fromRGB(138, 138, 138)
        Icon:SetAttribute('IdleColor', idle_color or Color3.fromRGB(138, 138, 138))
        Icon:SetAttribute('ActiveColor', active_color or Color3.fromRGB(255, 255, 255))
        Icon.ImageTransparency = 0
        Icon.ScaleType = Enum.ScaleType.Fit
        Icon.Parent = Tab

        local LeftSection = Instance.new('ScrollingFrame')
        LeftSection.Name = 'LeftSection'
        LeftSection.AutomaticCanvasSize = Enum.AutomaticSize.XY
        LeftSection.ScrollBarThickness = 0
        LeftSection.ScrollBarImageTransparency = 1
        LeftSection.Size = UDim2.new(0, 243, 0, 395)
        LeftSection.Selectable = false
        LeftSection.AnchorPoint = Vector2.new(0, 0)
        LeftSection.BackgroundTransparency = 1
        LeftSection.Position = UDim2.new(0, 203, 0, 67)
        LeftSection.BorderColor3 = Color3.fromRGB(0, 0, 0)
        LeftSection.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        LeftSection.BorderSizePixel = 0
        LeftSection.CanvasSize = UDim2.new(0, 0, 0.5, 0)
        LeftSection.Visible = false
        LeftSection.Parent = Sections

        local UIListLayout = Instance.new('UIListLayout')
        UIListLayout.Padding = UDim.new(0, 11)
        UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
        UIListLayout.Parent = LeftSection
        local UIPadding = Instance.new('UIPadding')
        UIPadding.PaddingTop = UDim.new(0, 1)
        UIPadding.Parent = LeftSection

        local RightSection = Instance.new('ScrollingFrame')
        RightSection.Name = 'RightSection'
        RightSection.AutomaticCanvasSize = Enum.AutomaticSize.XY
        RightSection.ScrollBarThickness = 0
        RightSection.Size = UDim2.new(0, 243, 0, 395)
        RightSection.Selectable = false
        RightSection.AnchorPoint = Vector2.new(0, 0)
        RightSection.ScrollBarImageTransparency = 1
        RightSection.BackgroundTransparency = 1
        RightSection.Position = UDim2.new(0, 474, 0, 67)
        RightSection.BorderColor3 = Color3.fromRGB(0, 0, 0)
        RightSection.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        RightSection.BorderSizePixel = 0
        RightSection.CanvasSize = UDim2.new(0, 0, 0.5, 0)
        RightSection.Visible = false
        RightSection.Parent = Sections

        local UIListLayout = Instance.new('UIListLayout')
        UIListLayout.Padding = UDim.new(0, 11)
        UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
        UIListLayout.Parent = RightSection

        local UIPadding = Instance.new('UIPadding')
        UIPadding.PaddingTop = UDim.new(0, 1)
        UIPadding.Parent = RightSection

        self._tab += 1

        if first_tab then
            self:update_tabs(Tab, LeftSection, RightSection)
            self:update_sections(LeftSection, RightSection)
        end

        Tab.MouseButton1Click:Connect(function()
            self:update_tabs(Tab, LeftSection, RightSection)
            self:update_sections(LeftSection, RightSection)
        end)

        function TabManager:create_module(settings: any)

            local LayoutOrderModule = 0;

            local ModuleManager = {
                _state = false,
                _size = 0,
                _multiplier = 0
            }

            if settings.section == 'right' then
                settings.section = RightSection
            else
                settings.section = LeftSection
            end

            local Module = Instance.new('Frame')
            Module.ClipsDescendants = true
            Module.BorderColor3 = Color3.fromRGB(0, 0, 0)
            Module.BackgroundTransparency = 0
            Module.Position = UDim2.new(0.004115226212888956, 0, 0, 0)
            Module.Name = 'Module'
            Module.Size = UDim2.new(0, 241, 0, 93)
            Module.BorderSizePixel = 0
            Module.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
            Module.Parent = settings.section

            local UIListLayout = Instance.new('UIListLayout')
            UIListLayout.Padding = UDim.new(0, 2)
            UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
            UIListLayout.Parent = Module

            local UICorner = Instance.new('UICorner')
            UICorner.CornerRadius = UDim.new(0, 9)
            UICorner.Parent = Module

            local UIStroke = Instance.new('UIStroke')
            UIStroke.Color = Color3.fromRGB(255, 255, 255)
            UIStroke.Transparency = 0.72
            UIStroke.Thickness = 1
            UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            UIStroke.Parent = Module

            local ModuleScrollTrack = Instance.new('Frame')
            ModuleScrollTrack.Name = 'ModuleScrollTrack'
            ModuleScrollTrack.AnchorPoint = Vector2.new(1, 0)
            ModuleScrollTrack.Position = UDim2.new(1, 9, 0, 4)
            ModuleScrollTrack.Size = UDim2.new(0, 4, 0, 140)
            ModuleScrollTrack.BackgroundColor3 = Color3.fromRGB(72, 72, 78)
            ModuleScrollTrack.BackgroundTransparency = 0.55
            ModuleScrollTrack.BorderSizePixel = 0
            ModuleScrollTrack.ZIndex = 20
            ModuleScrollTrack.Visible = false
            ModuleScrollTrack.Parent = Handler

            local ModuleScrollTrackCorner = Instance.new('UICorner')
            ModuleScrollTrackCorner.CornerRadius = UDim.new(1, 0)
            ModuleScrollTrackCorner.Parent = ModuleScrollTrack

            local ModuleScrollThumb = Instance.new('Frame')
            ModuleScrollThumb.Name = 'Thumb'
            ModuleScrollThumb.AnchorPoint = Vector2.new(0.5, 0)
            ModuleScrollThumb.Position = UDim2.new(0.5, 0, 0, 0)
            ModuleScrollThumb.Size = UDim2.new(1, 0, 0, 88)
            ModuleScrollThumb.BackgroundColor3 = Color3.fromRGB(232, 232, 236)
            ModuleScrollThumb.BackgroundTransparency = 0.08
            ModuleScrollThumb.BorderSizePixel = 0
            ModuleScrollThumb.ZIndex = 21
            ModuleScrollThumb.Parent = ModuleScrollTrack

            local ModuleScrollThumbCorner = Instance.new('UICorner')
            ModuleScrollThumbCorner.CornerRadius = UDim.new(1, 0)
            ModuleScrollThumbCorner.Parent = ModuleScrollThumb

            local function UpdateModuleScrollIndicator()
                local moduleX
                local moduleY
                local sectionTop
                local viewportHeight
                local moduleWidth
                local moduleHeight
                local scale = UIScale.Scale

                if UserInputService.TouchEnabled then
                    moduleX = (Module.AbsolutePosition.X - Handler.AbsolutePosition.X) / scale
                    moduleY = (Module.AbsolutePosition.Y - Handler.AbsolutePosition.Y) / scale
                    sectionTop = (settings.section.AbsolutePosition.Y - Handler.AbsolutePosition.Y) / scale
                    viewportHeight = settings.section.AbsoluteWindowSize.Y / scale
                    moduleWidth = Module.AbsoluteSize.X / scale
                    moduleHeight = Module.AbsoluteSize.Y / scale
                else
                    moduleX = Module.AbsolutePosition.X - Handler.AbsolutePosition.X
                    moduleY = Module.AbsolutePosition.Y - Handler.AbsolutePosition.Y
                    sectionTop = settings.section.AbsolutePosition.Y - Handler.AbsolutePosition.Y
                    viewportHeight = settings.section.AbsoluteWindowSize.Y
                    moduleWidth = Module.AbsoluteSize.X
                    moduleHeight = Module.AbsoluteSize.Y
                end

                local moduleTop = math.max(moduleY + 4, sectionTop + 4)
                local moduleBottom = math.min(moduleY + moduleHeight - 4, sectionTop + viewportHeight - 4)
                local trackHeight = math.max(moduleBottom - moduleTop, 1)
                ModuleScrollTrack.Position = UDim2.fromOffset(moduleX + moduleWidth + 10, moduleTop)
                ModuleScrollTrack.Size = UDim2.new(0, 4, 0, trackHeight)

                local section = settings.section
                local viewportHeight = UserInputService.TouchEnabled and section.AbsoluteWindowSize.Y / scale or section.AbsoluteWindowSize.Y
                local canvasHeight = UserInputService.TouchEnabled and section.AbsoluteCanvasSize.Y / scale or section.AbsoluteCanvasSize.Y
                local scrollable = canvasHeight > viewportHeight + 1
                ModuleScrollTrack.Visible = ModuleManager._state and section.Visible and Library._ui_open

                if not scrollable then
                    ModuleScrollThumb.Size = UDim2.new(1, 0, 0, math.clamp(ModuleScrollTrack.AbsoluteSize.Y * 0.52, 80, 112))
                    ModuleScrollThumb.Position = UDim2.new(0.5, 0, 0, 0)
                    return
                end

                local trackHeight = math.max(ModuleScrollTrack.AbsoluteSize.Y, 1)
                local thumbMin = math.min(80, trackHeight)
                local thumbMax = math.min(math.max(thumbMin, 112), trackHeight)
                local thumbHeight = math.clamp(trackHeight * (viewportHeight / canvasHeight), thumbMin, thumbMax)
                local maxCanvasPosition = math.max(canvasHeight - viewportHeight, 1)
                local maxThumbPosition = math.max(trackHeight - thumbHeight, 0)
                local thumbPosition = maxThumbPosition * math.clamp(section.CanvasPosition.Y / maxCanvasPosition, 0, 1)

                ModuleScrollThumb.Size = UDim2.new(1, 0, 0, thumbHeight)
                ModuleScrollThumb.Position = UDim2.new(0.5, 0, 0, thumbPosition)
            end

            settings.section:GetPropertyChangedSignal('CanvasPosition'):Connect(UpdateModuleScrollIndicator)
            settings.section:GetPropertyChangedSignal('AbsoluteCanvasSize'):Connect(UpdateModuleScrollIndicator)
            settings.section:GetPropertyChangedSignal('AbsoluteWindowSize'):Connect(UpdateModuleScrollIndicator)
            settings.section:GetPropertyChangedSignal('Visible'):Connect(UpdateModuleScrollIndicator)
            Module:GetPropertyChangedSignal('AbsoluteSize'):Connect(UpdateModuleScrollIndicator)
            Module:GetPropertyChangedSignal('AbsolutePosition'):Connect(UpdateModuleScrollIndicator)

            local Header = Instance.new('TextButton')
            Header.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
            Header.TextColor3 = Color3.fromRGB(0, 0, 0)
            Header.BorderColor3 = Color3.fromRGB(0, 0, 0)
            Header.Text = ''
            Header.AutoButtonColor = false
            Header.BackgroundTransparency = 1
            Header.Name = 'Header'
            Header.Size = UDim2.new(0, 241, 0, 93)
            Header.BorderSizePixel = 0
            Header.TextSize = 14
            Header.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Header.Parent = Module

            local ModuleName = Instance.new('TextLabel')
            ModuleName.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
            ModuleName.TextColor3 = Color3.fromRGB(238, 238, 242)
            ModuleName.TextTransparency = 0
            if not settings.rich then
                ModuleName.Text = settings.title or "Module"
            else
                ModuleName.RichText = true
                ModuleName.Text = settings.richtext or "<font color='rgb(255,255,255)'>Zuro✿</font> user"
            end
            ModuleName.Name = 'ModuleName'
            ModuleName.Size = UDim2.new(0, 205, 0, 13)
            ModuleName.AnchorPoint = Vector2.new(0, 0.5)
            ModuleName.Position = UDim2.new(0, 14, 0, 22)
            ModuleName.BackgroundTransparency = 1
            ModuleName.TextXAlignment = Enum.TextXAlignment.Left
            ModuleName.BorderSizePixel = 0
            ModuleName.TextSize = 13
            ModuleName.Parent = Header

            local LockIcon = Instance.new('ImageLabel')
            LockIcon.Name = 'LockIcon'
            LockIcon.Image = 'rbxassetid://132906779122559'
            LockIcon.ImageColor3 = Color3.fromRGB(178, 178, 185)
            LockIcon.ImageTransparency = 0.14
            LockIcon.ScaleType = Enum.ScaleType.Fit
            LockIcon.AnchorPoint = Vector2.new(1, 0)
            LockIcon.Position = UDim2.new(1, -12, 0, 8.5)
            LockIcon.Size = UDim2.fromOffset(23, 23)
            LockIcon.BackgroundTransparency = 1
            LockIcon.BorderSizePixel = 0
            LockIcon.Parent = Header

            local Description = Instance.new('TextLabel')
            Description.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
            Description.TextColor3 = Color3.fromRGB(142, 142, 151)
            Description.TextTransparency = 0
            Description.Text = settings.description or ''
            Description.Name = 'Description'
            Description.Size = UDim2.new(0, 205, 0, 13)
            Description.AnchorPoint = Vector2.new(0, 0.5)
            Description.Position = UDim2.new(0, 14, 0, 40)
            Description.BackgroundTransparency = 1
            Description.TextXAlignment = Enum.TextXAlignment.Left
            Description.BorderSizePixel = 0
            Description.TextSize = 10
            Description.Parent = Header

            local Toggle = Instance.new('Frame')
            Toggle.Name = 'Toggle'
            Toggle.BackgroundTransparency = 0
            Toggle.Position = UDim2.new(0, 229, 0, 76)
            Toggle.AnchorPoint = Vector2.new(1, 0.5)
            Toggle.Size = UDim2.new(0, 30, 0, 16)
            Toggle.BorderSizePixel = 0
            Toggle.BackgroundColor3 = Color3.fromRGB(36, 36, 42)
            Toggle.Parent = Header

            local ToggleCorner = Instance.new('UICorner')
            ToggleCorner.CornerRadius = UDim.new(1, 0)
            ToggleCorner.Parent = Toggle

            local Circle = Instance.new('Frame')
            Circle.AnchorPoint = Vector2.new(0, 0.5)
            Circle.BackgroundTransparency = 0
            Circle.Position = UDim2.new(0, 2, 0.5, 0)
            Circle.Name = 'Circle'
            Circle.Size = UDim2.new(0, 12, 0, 12)
            Circle.BorderSizePixel = 0
            Circle.BackgroundColor3 = Color3.fromRGB(126, 126, 136)
            Circle.Parent = Toggle

            local CircleCorner = Instance.new('UICorner')
            CircleCorner.CornerRadius = UDim.new(1, 0)
            CircleCorner.Parent = Circle

            local Keybind = Instance.new('TextButton')
            Keybind.Name = 'Keybind'
            Keybind.AutoButtonColor = false
            Keybind.Text = ''
            Keybind.BackgroundTransparency = 0
            Keybind.Position = UDim2.new(0, 14, 0, 67)
            Keybind.Size = UDim2.new(0, 38, 0, 16)
            Keybind.BorderSizePixel = 0
            Keybind.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
            Keybind.Parent = Header

            local Icon = Instance.new('ImageLabel')
            Icon.Name = 'Icon'
            Icon.Image = settings.icon or 'rbxassetid://79095934438045'
            Icon.ImageColor3 = Color3.fromRGB(195, 195, 202)
            Icon.ImageTransparency = 0
            Icon.ScaleType = Enum.ScaleType.Fit
            Icon.AnchorPoint = Vector2.new(0, 0.5)
            Icon.Position = UDim2.new(0, 13, 0, 75)
            Icon.Size = UDim2.fromOffset(17, 17)
            Icon.BackgroundTransparency = 1
            Icon.BorderSizePixel = 0
            Icon.Parent = Header

            Keybind.Position = UDim2.new(0, 34, 0, 67)

            local KeybindCorner = Instance.new('UICorner')
            KeybindCorner.CornerRadius = UDim.new(0, 2)
            KeybindCorner.Parent = Keybind

            local KeybindStroke = Instance.new('UIStroke')
            KeybindStroke.Color = Color3.fromRGB(255, 255, 255)
            KeybindStroke.Transparency = 0.68
            KeybindStroke.Thickness = 1
            KeybindStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            KeybindStroke.Parent = Keybind

            local TextLabel = Instance.new('TextLabel')
            TextLabel.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
            TextLabel.TextColor3 = Color3.fromRGB(195, 195, 202)
            TextLabel.Text = 'None'
            TextLabel.Size = UDim2.new(1, -10, 1, 0)
            TextLabel.Position = UDim2.new(0, 5, 0, 0)
            TextLabel.BackgroundTransparency = 1
            TextLabel.TextXAlignment = Enum.TextXAlignment.Center
            TextLabel.TextYAlignment = Enum.TextYAlignment.Center
            TextLabel.BorderSizePixel = 0
            TextLabel.TextSize = 10
            TextLabel.Parent = Keybind

            local Divider = Instance.new('Frame')
            Divider.BorderColor3 = Color3.fromRGB(0, 0, 0)
            Divider.AnchorPoint = Vector2.new(0.5, 0)
            Divider.BackgroundTransparency = 0.72
            Divider.Position = UDim2.new(0.5, 0, 0.6200000047683716, 0)
            Divider.Name = 'Divider'
            Divider.Size = UDim2.new(0, 241, 0, 1)
            Divider.BorderSizePixel = 0
            Divider.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Divider.Parent = Header

            local Divider = Instance.new('Frame')
            Divider.BorderColor3 = Color3.fromRGB(0, 0, 0)
            Divider.AnchorPoint = Vector2.new(0.5, 0)
            Divider.BackgroundTransparency = 0.72
            Divider.Position = UDim2.new(0.5, 0, 1, 0)
            Divider.Name = 'Divider'
            Divider.Size = UDim2.new(0, 241, 0, 1)
            Divider.BorderSizePixel = 0
            Divider.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Divider.Parent = Header

            local Options = Instance.new('Frame')
            Options.Name = 'Options'
            Options.BackgroundTransparency = 1
            Options.Position = UDim2.new(0, 0, 1, 2)
            Options.BorderColor3 = Color3.fromRGB(0, 0, 0)
            Options.Size = UDim2.new(0, 241, 0, 8)
            Options.BorderSizePixel = 0
            Options.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Options.Parent = Module

            local UIPadding = Instance.new('UIPadding')
            UIPadding.PaddingTop = UDim.new(0, 8)
            UIPadding.Parent = Options

            local UIListLayout = Instance.new('UIListLayout')
            UIListLayout.Padding = UDim.new(0, 7)
            UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
            UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
            UIListLayout.Parent = Options

            function ModuleManager:change_state(state: boolean)
                self._state = state
                ModuleScrollTrack.Visible = self._state and settings.section.Visible
                task.defer(UpdateModuleScrollIndicator)
                task.delay(0.3, UpdateModuleScrollIndicator)

                if self._state then
                    TweenService:Create(Module, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Size = UDim2.fromOffset(241, 93 + self._size + self._multiplier)
                    }):Play()

                    TweenService:Create(Toggle, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        BackgroundColor3 = Color3.fromRGB(202, 202, 208)
                    }):Play()

                    TweenService:Create(Circle, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        BackgroundColor3 = Color3.fromRGB(24, 24, 27),
                        Position = UDim2.new(1, -14, 0.5, 0)
                    }):Play()
                else
                    TweenService:Create(Module, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Size = UDim2.fromOffset(241, 93)
                    }):Play()

                    TweenService:Create(Toggle, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        BackgroundColor3 = Color3.fromRGB(27, 27, 31)
                    }):Play()

                    TweenService:Create(Circle, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        BackgroundColor3 = Color3.fromRGB(132, 132, 132),
                        Position = UDim2.new(0, 2, 0.5, 0)
                    }):Play()
                end

                Library._config._flags[settings.flag] = self._state

                settings.callback(self._state)
                Config:save(game.GameId, Library._config)
            end

            function ModuleManager:connect_keybind()
                if not Library._config._keybinds[settings.flag] then
                    return
                end

                Connections[settings.flag..'_keybind'] = UserInputService.InputBegan:Connect(function(input: InputObject, process: boolean)
                    if process then
                        return
                    end

                    if tostring(input.KeyCode) ~= Library._config._keybinds[settings.flag] then
                        return
                    end

                    self:change_state(not self._state)
                end)
            end

            function ModuleManager:scale_keybind(empty: boolean)
                if Library._config._keybinds[settings.flag] and not empty then
                    local keybind_string = string.gsub(tostring(Library._config._keybinds[settings.flag]), 'Enum.KeyCode.', '')

                    local font_params = Instance.new('GetTextBoundsParams')
                    font_params.Text = keybind_string
                    font_params.Font = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold)
                    font_params.Size = 10
                    font_params.Width = 10000

                    local font_size = TextService:GetTextBoundsAsync(font_params)

                    Keybind.Size = UDim2.fromOffset(math.max(38, font_size.X + 12), 16)
                    TextLabel.Size = UDim2.new(1, -10, 1, 0)
                else
                    Keybind.Size = UDim2.fromOffset(38, 16)
                    TextLabel.Size = UDim2.new(1, -10, 1, 0)
                end
            end

            if Library._config._flags[settings.flag] == nil then
                Library._config._flags[settings.flag] = false
            end

            if Library:flag_type(settings.flag, 'boolean') then
                ModuleManager._state = Library._config._flags[settings.flag]
                settings.callback(ModuleManager._state)

                if ModuleManager._state then
                    Toggle.BackgroundColor3 = Color3.fromRGB(202, 202, 208)
                    Circle.BackgroundColor3 = Color3.fromRGB(24, 24, 27)
                    Circle.Position = UDim2.new(1, -14, 0.5, 0)
                else
                    Toggle.BackgroundColor3 = Color3.fromRGB(36, 36, 42)
                    Circle.BackgroundColor3 = Color3.fromRGB(126, 126, 136)
                    Circle.Position = UDim2.new(0, 2, 0.5, 0)
                end
            end

            task.defer(UpdateModuleScrollIndicator)

            if Library._config._keybinds[settings.flag] then
                local keybind_string = string.gsub(tostring(Library._config._keybinds[settings.flag]), 'Enum.KeyCode.', '')
                TextLabel.Text = keybind_string

                ModuleManager:connect_keybind()
                ModuleManager:scale_keybind()
            end

            Connections[settings.flag..'_input_began'] = Keybind.MouseButton1Click:Connect(function()
                if Library._choosing_keybind then
                    return
                end

                Library._choosing_keybind = true
                TextLabel.Text = '...'
                Keybind.BackgroundColor3 = Color3.fromRGB(45, 45, 51)

                Connections['keybind_choose_start'] = UserInputService.InputBegan:Connect(function(input: InputObject, process: boolean)
                    if process then
                        return
                    end

                    if input == Enum.UserInputState or input == Enum.UserInputType then
                        return
                    end

                    if input.KeyCode == Enum.KeyCode.Unknown then
                        return
                    end

                    if input.KeyCode == Enum.KeyCode.Backspace then
                        ModuleManager:scale_keybind(true)

                        Library._config._keybinds[settings.flag] = nil

                        TextLabel.Text = 'None'

                        if Connections[settings.flag..'_keybind'] then
                            Connections[settings.flag..'_keybind']:Disconnect()
                            Connections[settings.flag..'_keybind'] = nil
                        end

                        Connections['keybind_choose_start']:Disconnect()
                        Connections['keybind_choose_start'] = nil

                        Library._choosing_keybind = false
                        Keybind.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
                        Config:save(game.GameId, Library._config)
                        return
                    end

                    Connections['keybind_choose_start']:Disconnect()
                    Connections['keybind_choose_start'] = nil

                    Library._config._keybinds[settings.flag] = tostring(input.KeyCode)

                    if Connections[settings.flag..'_keybind'] then
                        Connections[settings.flag..'_keybind']:Disconnect()
                        Connections[settings.flag..'_keybind'] = nil
                    end

                    ModuleManager:connect_keybind()
                    ModuleManager:scale_keybind()

                    Library._choosing_keybind = false

                    local keybind_string = string.gsub(tostring(Library._config._keybinds[settings.flag]), 'Enum.KeyCode.', '')
                    TextLabel.Text = keybind_string
                    Config:save(game.GameId, Library._config)
                end)
            end)

            Header.MouseButton1Click:Connect(function()
                ModuleManager:change_state(not ModuleManager._state)
            end)

            function ModuleManager:create_checkbox(settings: any)
                LayoutOrderModule = LayoutOrderModule + 1
                local CheckboxManager = { _state = false }

                if self._size == 0 then
                    self._size = 11
                end
                self._size += 28

                if ModuleManager._state then
                    Module.Size = UDim2.fromOffset(241, 93 + self._size)
                end
                Options.Size = UDim2.fromOffset(241, self._size)

                local Row = Instance.new("TextButton")
                Row.Name = "ToggleRow"
                Row.Size = UDim2.new(0, 207, 0, 22)
                Row.BackgroundTransparency = 1
                Row.BorderSizePixel = 0
                Row.Text = ""
                Row.AutoButtonColor = false
                Row.Parent = Options
                Row.LayoutOrder = LayoutOrderModule

                local TitleLabel = Instance.new("TextLabel")
                TitleLabel.Name = "TitleLabel"
                TitleLabel.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                TitleLabel.TextSize = 12
                TitleLabel.TextColor3 = Color3.fromRGB(202, 202, 209)
                TitleLabel.Text = settings.title or "Toggle"
                TitleLabel.Size = UDim2.new(1, -64, 1, 0)
                TitleLabel.Position = UDim2.new(0, 0, 0, 0)
                TitleLabel.BackgroundTransparency = 1
                TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
                TitleLabel.TextYAlignment = Enum.TextYAlignment.Center
                TitleLabel.Parent = Row

                local KeybindBox = Instance.new("TextButton")
                KeybindBox.Name = "KeybindBox"
                KeybindBox.Size = UDim2.fromOffset(16, 16)
                KeybindBox.Position = UDim2.new(1, -38, 0.5, 0)
                KeybindBox.AnchorPoint = Vector2.new(1, 0.5)
                KeybindBox.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
                KeybindBox.BorderSizePixel = 0
                KeybindBox.AutoButtonColor = false
                KeybindBox.Text = ""
                KeybindBox.Parent = Row

                local KeybindCorner = Instance.new("UICorner")
                KeybindCorner.CornerRadius = UDim.new(0, 2)
                KeybindCorner.Parent = KeybindBox

                local KeybindStroke = Instance.new("UIStroke")
                KeybindStroke.Color = Color3.fromRGB(255, 255, 255)
                KeybindStroke.Transparency = 0.72
                KeybindStroke.Thickness = 1
                KeybindStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                KeybindStroke.Parent = KeybindBox

                local KeybindLabel = Instance.new("TextLabel")
                KeybindLabel.Name = "KeybindLabel"
                KeybindLabel.Size = UDim2.new(1, -4, 1, 0)
                KeybindLabel.Position = UDim2.new(0, 2, 0, 0)
                KeybindLabel.BackgroundTransparency = 1
                KeybindLabel.TextColor3 = Color3.fromRGB(178, 178, 185)
                KeybindLabel.TextSize = 9
                KeybindLabel.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                KeybindLabel.Text = Library._config._keybinds[settings.flag]
                    and string.gsub(tostring(Library._config._keybinds[settings.flag]), "Enum.KeyCode.", "")
                    or "..."
                KeybindLabel.Parent = KeybindBox

                local Toggle = Instance.new("Frame")
                Toggle.Name = "Toggle"
                Toggle.Size = UDim2.fromOffset(31, 17)
                Toggle.Position = UDim2.new(1, 0, 0.5, 0)
                Toggle.AnchorPoint = Vector2.new(1, 0.5)
                Toggle.BackgroundColor3 = Color3.fromRGB(27, 27, 31)
                Toggle.BorderSizePixel = 0
                Toggle.Parent = Row

                local ToggleStroke = Instance.new("UIStroke")
                ToggleStroke.Color = Color3.fromRGB(65, 65, 73)
                ToggleStroke.Transparency = 0.62
                ToggleStroke.Thickness = 1
                ToggleStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                ToggleStroke.Parent = Toggle

                local ToggleCorner = Instance.new("UICorner")
                ToggleCorner.CornerRadius = UDim.new(1, 0)
                ToggleCorner.Parent = Toggle

                local Knob = Instance.new("Frame")
                Knob.Name = "Knob"
                Knob.Size = UDim2.fromOffset(13, 13)
                Knob.Position = UDim2.new(0, 2, 0.5, 0)
                Knob.AnchorPoint = Vector2.new(0, 0.5)
                Knob.BackgroundColor3 = Color3.fromRGB(126, 126, 136)
                Knob.BorderSizePixel = 0
                Knob.Parent = Toggle

                local KnobCorner = Instance.new("UICorner")
                KnobCorner.CornerRadius = UDim.new(1, 0)
                KnobCorner.Parent = Knob

                function CheckboxManager:change_state(state: boolean)
                    self._state = state
                    TweenService:Create(Toggle, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        BackgroundColor3 = state and Color3.fromRGB(225, 225, 230) or Color3.fromRGB(36, 36, 42)
                    }):Play()
                    TweenService:Create(Knob, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        BackgroundColor3 = state and Color3.fromRGB(35, 35, 40) or Color3.fromRGB(126, 126, 136),
                        Position = state and UDim2.new(1, -15, 0.5, 0) or UDim2.new(0, 2, 0.5, 0)
                    }):Play()
                    Library._config._flags[settings.flag] = self._state
                    settings.callback(self._state)
                    Config:save(game.GameId, Library._config)
                end

                if Library._config._flags[settings.flag] == nil then
                    Library._config._flags[settings.flag] = false
                end

                if Library:flag_type(settings.flag, "boolean") then
                    CheckboxManager._state = Library._config._flags[settings.flag]
                    if CheckboxManager._state then
                        Toggle.BackgroundColor3 = Color3.fromRGB(225, 225, 230)
                        Knob.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
                        Knob.Position = UDim2.new(1, -15, 0.5, 0)
                    else
                        Toggle.BackgroundColor3 = Color3.fromRGB(36, 36, 42)
                        Knob.BackgroundColor3 = Color3.fromRGB(126, 126, 136)
                        Knob.Position = UDim2.new(0, 2, 0.5, 0)
                    end
                    settings.callback(CheckboxManager._state)
                end

                KeybindBox.MouseButton1Click:Connect(function()
                    if Library._choosing_keybind then return end
                    Library._choosing_keybind = true
                    KeybindLabel.Text = "..."
                    local chooseConnection
                    chooseConnection = UserInputService.InputBegan:Connect(function(input, processed)
                        if processed then return end
                        if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
                        if input.KeyCode == Enum.KeyCode.Unknown then return end
                        chooseConnection:Disconnect()
                        if input.KeyCode == Enum.KeyCode.Backspace then
                            Library._config._keybinds[settings.flag] = nil
                            KeybindLabel.Text = "..."
                        else
                            Library._config._keybinds[settings.flag] = tostring(input.KeyCode)
                            KeybindLabel.Text = string.gsub(tostring(input.KeyCode), "Enum.KeyCode.", "")
                        end
                        Library._choosing_keybind = false
                    end)
                end)

                KeybindBox.MouseButton1Click:Connect(function()
                    task.defer(function()
                        Row.Active = false
                        task.wait()
                        Row.Active = true
                    end)
                end)

                Row.MouseButton1Click:Connect(function()
                    CheckboxManager:change_state(not CheckboxManager._state)
                end)

                Connections[settings.flag .. "_row_keybind"] = UserInputService.InputBegan:Connect(function(input, processed)
                    if processed or Library._choosing_keybind then return end
                    local stored = Library._config._keybinds[settings.flag]
                    if stored and tostring(input.KeyCode) == stored then
                        CheckboxManager:change_state(not CheckboxManager._state)
                    end
                end)

                Library._flag_registry[settings.flag] = function(state)
                    CheckboxManager:change_state(state)
                end

                return CheckboxManager
            end

            function ModuleManager:create_keybind_row(settings: any)
                LayoutOrderModule = LayoutOrderModule + 1

                if self._size == 0 then
                    self._size = 11
                end
                self._size += 28

                if ModuleManager._state then
                    Module.Size = UDim2.fromOffset(241, 93 + self._size)
                end
                Options.Size = UDim2.fromOffset(241, self._size)

                local Row = Instance.new('Frame')
                Row.Name = 'KeybindRow'
                Row.Size = UDim2.new(0, 207, 0, 22)
                Row.BackgroundTransparency = 1
                Row.BorderSizePixel = 0
                Row.LayoutOrder = LayoutOrderModule
                Row.Parent = Options

                local TitleLabel = Instance.new('TextLabel')
                TitleLabel.Name = 'TitleLabel'
                TitleLabel.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                TitleLabel.TextSize = 12
                TitleLabel.TextColor3 = Color3.fromRGB(202, 202, 209)
                TitleLabel.Text = settings.title or 'Keybind'
                TitleLabel.Size = UDim2.new(1, -46, 1, 0)
                TitleLabel.Position = UDim2.new(0, 0, 0, 0)
                TitleLabel.BackgroundTransparency = 1
                TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
                TitleLabel.TextYAlignment = Enum.TextYAlignment.Center
                TitleLabel.Parent = Row

                local KeybindBox = Instance.new('TextButton')
                KeybindBox.Name = 'KeybindBox'
                KeybindBox.Size = UDim2.fromOffset(38, 16)
                KeybindBox.AnchorPoint = Vector2.new(1, 0.5)
                KeybindBox.Position = UDim2.new(1, 0, 0.5, 0)
                KeybindBox.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
                KeybindBox.BorderSizePixel = 0
                KeybindBox.AutoButtonColor = false
                KeybindBox.Text = ''
                KeybindBox.Parent = Row

                local KeybindCorner = Instance.new('UICorner')
                KeybindCorner.CornerRadius = UDim.new(0, 2)
                KeybindCorner.Parent = KeybindBox

                local KeybindStroke = Instance.new('UIStroke')
                KeybindStroke.Color = Color3.fromRGB(255, 255, 255)
                KeybindStroke.Transparency = 0.72
                KeybindStroke.Thickness = 1
                KeybindStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                KeybindStroke.Parent = KeybindBox

                local KeybindLabel = Instance.new('TextLabel')
                KeybindLabel.Name = 'KeybindLabel'
                KeybindLabel.Size = UDim2.new(1, -4, 1, 0)
                KeybindLabel.Position = UDim2.new(0, 2, 0, 0)
                KeybindLabel.BackgroundTransparency = 1
                KeybindLabel.TextColor3 = Color3.fromRGB(178, 178, 185)
                KeybindLabel.TextSize = 9
                KeybindLabel.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                KeybindLabel.Text = Library._config._keybinds[settings.flag]
                    and string.gsub(tostring(Library._config._keybinds[settings.flag]), 'Enum.KeyCode.', '')
                    or '...'
                KeybindLabel.Parent = KeybindBox

                local function resize_keybind_row()
                    local txt = KeybindLabel.Text
                    if txt == '...' then
                        KeybindBox.Size = UDim2.fromOffset(38, 16)
                        return
                    end
                    local fp = Instance.new('GetTextBoundsParams')
                    fp.Text = txt
                    fp.Font = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold)
                    fp.Size = 9
                    fp.Width = 10000
                    local fs = TextService:GetTextBoundsAsync(fp)
                    KeybindBox.Size = UDim2.fromOffset(math.max(38, fs.X + 12), 16)
                end

                resize_keybind_row()

                KeybindBox.MouseButton1Click:Connect(function()
                    if Library._choosing_keybind then return end
                    Library._choosing_keybind = true
                    KeybindLabel.Text = '...'
                    KeybindBox.Size = UDim2.fromOffset(38, 16)
                    KeybindBox.BackgroundColor3 = Color3.fromRGB(45, 45, 51)

                    local conn
                    conn = UserInputService.InputBegan:Connect(function(input, process)
                        if process then return end
                        if input.KeyCode == Enum.KeyCode.Unknown then return end
                        conn:Disconnect()
                        conn = nil

                        if input.KeyCode == Enum.KeyCode.Backspace then
                            Library._config._keybinds[settings.flag] = nil
                            KeybindLabel.Text = '...'
                        else
                            Library._config._keybinds[settings.flag] = tostring(input.KeyCode)
                            KeybindLabel.Text = string.gsub(tostring(input.KeyCode), 'Enum.KeyCode.', '')
                        end

                        resize_keybind_row()
                        Library._choosing_keybind = false
                        KeybindBox.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
                    end)
                end)
            end

            function ModuleManager:create_slider(settings: any)

                LayoutOrderModule = LayoutOrderModule + 1

                local SliderManager = {}

                if self._size == 0 then
                    self._size = 11
                end

                self._size += 40

                if ModuleManager._state then
                    Module.Size = UDim2.fromOffset(241, 93 + self._size)
                end

                Options.Size = UDim2.fromOffset(241, self._size)

                local Slider = Instance.new('TextButton')
                Slider.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal);
                Slider.TextSize = 14;
                Slider.TextColor3 = Color3.fromRGB(0, 0, 0)
                Slider.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Slider.Text = ''
                Slider.AutoButtonColor = false
                Slider.BackgroundTransparency = 1
                Slider.Name = 'Slider'
                Slider.Size = UDim2.new(0, 207, 0, 33)
                Slider.BorderSizePixel = 0
                Slider.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                Slider.Parent = Options
                Slider.LayoutOrder = LayoutOrderModule

                local TextLabel = Instance.new('TextLabel')
                TextLabel.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                TextLabel.TextSize = 12;
                TextLabel.TextColor3 = Color3.fromRGB(206, 206, 212)
                TextLabel.TextTransparency = 0
                TextLabel.Text = settings.title
                TextLabel.Size = UDim2.new(0, 160, 0, 14)
                TextLabel.Position = UDim2.new(0, 0, 0, 0)
                TextLabel.BackgroundTransparency = 1
                TextLabel.TextXAlignment = Enum.TextXAlignment.Left
                TextLabel.BorderSizePixel = 0
                TextLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
                TextLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                TextLabel.Parent = Slider

                local Drag = Instance.new('Frame')
                Drag.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Drag.AnchorPoint = Vector2.new(0.5, 1)
                Drag.BackgroundTransparency = 0
                Drag.Position = UDim2.new(0.5, 0, 0.94, 0)
                Drag.Name = 'Drag'
                Drag.Size = UDim2.new(0, 207, 0, 6)
                Drag.BorderSizePixel = 0
                Drag.BackgroundColor3 = Color3.fromRGB(42, 42, 48)
                Drag.Parent = Slider

                local UICorner = Instance.new('UICorner')
                UICorner.CornerRadius = UDim.new(1, 0)
                UICorner.Parent = Drag

                local Fill = Instance.new('Frame')
                Fill.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Fill.AnchorPoint = Vector2.new(0, 0.5)
                Fill.BackgroundTransparency = 0
                Fill.Position = UDim2.new(0, 0, 0.5, 0)
                Fill.Name = 'Fill'
                Fill.Size = UDim2.new(0, 103, 0, 6)
                Fill.BorderSizePixel = 0
                Fill.BackgroundColor3 = Color3.fromRGB(220, 220, 225)
                Fill.Parent = Drag

                local UICorner = Instance.new('UICorner')
                UICorner.CornerRadius = UDim.new(0, 3)
                UICorner.Parent = Fill

                local UIGradient = Instance.new('UIGradient')
                UIGradient.Color = ColorSequence.new{
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(238, 238, 242)),
                    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(224, 224, 230)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(202, 202, 210))
                }
                UIGradient.Rotation = 0
                UIGradient.Parent = Fill

                local Circle = Instance.new('Frame')
                Circle.AnchorPoint = Vector2.new(1, 0.5)
                Circle.Name = 'Circle'
                Circle.Position = UDim2.new(1, 0, 0.5, 0)
                Circle.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Circle.Size = UDim2.new(0, 10, 0, 10)
                Circle.BorderSizePixel = 0
                Circle.BackgroundColor3 = Color3.fromRGB(232, 232, 236)
                Circle.Parent = Fill

                local UICorner = Instance.new('UICorner')
                UICorner.CornerRadius = UDim.new(1, 0)
                UICorner.Parent = Circle

                local CircleStroke = Instance.new('UIStroke')
                CircleStroke.Color = Color3.fromRGB(20, 20, 24)
                CircleStroke.Transparency = 0.58
                CircleStroke.Thickness = 1
                CircleStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                CircleStroke.Parent = Circle

                local Value = Instance.new('TextLabel')
                Value.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                Value.TextColor3 = Color3.fromRGB(188, 188, 198)
                Value.TextTransparency = 0.20000000298023224
                Value.Text = '50'
                Value.Name = 'Value'
                Value.Size = UDim2.new(0, 42, 0, 13)
                Value.AnchorPoint = Vector2.new(1, 0)
                Value.Position = UDim2.new(1, 0, 0, 0)
                Value.BackgroundTransparency = 1
                Value.TextXAlignment = Enum.TextXAlignment.Right
                Value.BorderSizePixel = 0
                Value.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Value.TextSize = 10
                Value.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                Value.Parent = Slider

                function SliderManager:set_percentage(percentage: number)
                    local rounded_number = 0

                    if settings.round_number then
                        rounded_number = math.floor(percentage)
                    else
                        rounded_number = math.floor(percentage * 10) / 10
                    end

                    percentage = (percentage - settings.minimum_value) / (settings.maximum_value - settings.minimum_value)

                    local slider_size = math.clamp(percentage, 0.02, 1) * Drag.Size.X.Offset
                    local number_threshold = math.clamp(rounded_number, settings.minimum_value, settings.maximum_value)

                    Library._config._flags[settings.flag] = number_threshold
                    Value.Text = number_threshold

                    TweenService:Create(Fill, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Size = UDim2.fromOffset(slider_size, Drag.Size.Y.Offset)
                    }):Play()

                    settings.callback(number_threshold)
                    Config:save(game.GameId, Library._config)
                end

                function SliderManager:update()
                    local mouse_position = (mouse.X - Drag.AbsolutePosition.X) / Drag.Size.X.Offset
                    local percentage = settings.minimum_value + (settings.maximum_value - settings.minimum_value) * mouse_position

                    self:set_percentage(percentage)
                end

                function SliderManager:input()
                    SliderManager:update()

                    Connections['slider_drag_'..settings.flag] = mouse.Move:Connect(function()
                        SliderManager:update()
                    end)

                    Connections['slider_input_'..settings.flag] = UserInputService.InputEnded:Connect(function(input: InputObject, process: boolean)
                        if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
                            return
                        end

                        Connections:disconnect('slider_drag_'..settings.flag)
                        Connections:disconnect('slider_input_'..settings.flag)

                        if not settings.ignoresaved then
                        end;
                    end)
                end

                if Library:flag_type(settings.flag, 'number') then
                    if not settings.ignoresaved then
                        SliderManager:set_percentage(Library._config._flags[settings.flag]);
                    else
                        SliderManager:set_percentage(settings.value);
                    end;
                else
                    SliderManager:set_percentage(settings.value);
                end;

                Slider.MouseButton1Down:Connect(function()
                    SliderManager:input()
                end)

                Library._flag_registry[settings.flag] = function(value)
                    SliderManager:set_percentage(value)
                end

                return SliderManager
            end

            function ModuleManager:create_button(settings: any)
                LayoutOrderModule = LayoutOrderModule + 1

                if self._size == 0 then self._size = 11 end
                self._size += 29

                if ModuleManager._state then
                    Module.Size = UDim2.fromOffset(241, 93 + self._size + self._multiplier)
                end
                Options.Size = UDim2.fromOffset(241, self._size + self._multiplier)

                local Holder = Instance.new('Frame')
                Holder.Name = 'ButtonHolder'
                Holder.Size = UDim2.fromOffset(207, 23)
                Holder.BackgroundTransparency = 1
                Holder.BorderSizePixel = 0
                Holder.LayoutOrder = LayoutOrderModule
                Holder.Parent = Options

                local Btn = Instance.new('TextButton')
                Btn.Name = 'Button'
                Btn.AnchorPoint = Vector2.new(0, 1)
                Btn.Position = UDim2.new(0, 0, 1, 0)
                Btn.Size = UDim2.fromOffset(207, 22)
                Btn.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
                Btn.BorderSizePixel = 0
                Btn.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                Btn.TextColor3 = Color3.fromRGB(202, 202, 209)
                Btn.TextSize = 12
                Btn.AutoButtonColor = false
                Btn.Text = settings.title
                Btn.Parent = Holder

                local BtnCorner = Instance.new('UICorner')
                BtnCorner.CornerRadius = UDim.new(0, 4)
                BtnCorner.Parent = Btn

                local BtnStroke = Instance.new('UIStroke')
                BtnStroke.Color = Color3.fromRGB(255, 255, 255)
                BtnStroke.Transparency = 0.72
                BtnStroke.Thickness = 1
                BtnStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                BtnStroke.Parent = Btn

                Btn.MouseButton1Click:Connect(settings.callback)
            end

            function ModuleManager:create_textbox(settings: any)
                LayoutOrderModule = LayoutOrderModule + 1

                if self._size == 0 then self._size = 11 end
                self._size += 29

                if ModuleManager._state then
                    Module.Size = UDim2.fromOffset(241, 93 + self._size + self._multiplier)
                end
                Options.Size = UDim2.fromOffset(241, self._size + self._multiplier)

                local Holder = Instance.new('Frame')
                Holder.Name = 'TextboxHolder'
                Holder.Size = UDim2.fromOffset(207, 23)
                Holder.BackgroundTransparency = 1
                Holder.BorderSizePixel = 0
                Holder.LayoutOrder = LayoutOrderModule
                Holder.Parent = Options

                local Box = Instance.new('TextBox')
                Box.Name = 'TextBox'
                Box.AnchorPoint = Vector2.new(0, 1)
                Box.Position = UDim2.new(0, 0, 1, 0)
                Box.Size = UDim2.fromOffset(207, 22)
                Box.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
                Box.BorderSizePixel = 0
                Box.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                Box.TextColor3 = Color3.fromRGB(202, 202, 209)
                Box.TextSize = 12
                Box.PlaceholderText = settings.placeholder or ''
                Box.PlaceholderColor3 = Color3.fromRGB(100, 100, 107)
                Box.Text = settings.value or ''
                Box.ClearTextOnFocus = false
                Box.Parent = Holder

                local BoxCorner = Instance.new('UICorner')
                BoxCorner.CornerRadius = UDim.new(0, 4)
                BoxCorner.Parent = Box

                local BoxStroke = Instance.new('UIStroke')
                BoxStroke.Color = Color3.fromRGB(255, 255, 255)
                BoxStroke.Transparency = 0.72
                BoxStroke.Thickness = 1
                BoxStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                BoxStroke.Parent = Box

                Box.FocusLost:Connect(function()
                    settings.callback(Box.Text)
                end)

                return Box
            end

            function ModuleManager:create_dropdown(settings: any)

                if not settings.Order then
                    LayoutOrderModule = LayoutOrderModule + 1;
                end;

                local DropdownManager = {
                    _state = false,
                    _size = 0
                }

                if not settings.Order then
                    if self._size == 0 then
                        self._size = 11
                    end

                    self._size += 53
                end;

                if not settings.Order then
                    if ModuleManager._state then
                        Module.Size = UDim2.fromOffset(241, 93 + self._size)
                    end
                    Options.Size = UDim2.fromOffset(241, self._size)
                end

                local Dropdown = Instance.new('TextButton')
                Dropdown.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                Dropdown.TextColor3 = Color3.fromRGB(0, 0, 0)
                Dropdown.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Dropdown.Text = ''
                Dropdown.AutoButtonColor = false
                Dropdown.BackgroundTransparency = 1
                Dropdown.Name = 'Dropdown'
                Dropdown.Size = UDim2.new(0, 210, 0, 45)
                Dropdown.BorderSizePixel = 0
                Dropdown.TextSize = 14
                Dropdown.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                Dropdown.Parent = Options

                if not settings.Order then
                    Dropdown.LayoutOrder = LayoutOrderModule;
                else
                    Dropdown.LayoutOrder = settings.OrderValue;
                end;

                if not Library._config._flags[settings.flag] then
                    Library._config._flags[settings.flag] = {};
                end;

                local TextLabel = Instance.new('TextLabel')
                TextLabel.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal);
                TextLabel.TextSize = 11;
                TextLabel.TextColor3 = Color3.fromRGB(206, 206, 212)
                TextLabel.TextTransparency = 0.20000000298023224
                TextLabel.Text = settings.title
                TextLabel.Size = UDim2.new(0, 207, 0, 13)
                TextLabel.BackgroundTransparency = 1
                TextLabel.TextXAlignment = Enum.TextXAlignment.Left
                TextLabel.BorderSizePixel = 0
                TextLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
                TextLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                TextLabel.Parent = Dropdown

                local Box = Instance.new('Frame')
                Box.ClipsDescendants = true
                Box.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Box.AnchorPoint = Vector2.new(0.5, 0)
                Box.BackgroundTransparency = 0
                Box.Position = UDim2.new(0.5, 0, 1.3, 0)
                Box.Name = 'Box'
                Box.Size = UDim2.new(0, 210, 0, 28)
                Box.BorderSizePixel = 0
                Box.BackgroundColor3 = Color3.fromRGB(24, 24, 28)
                Box.Parent = TextLabel

                local UICorner = Instance.new('UICorner')
                UICorner.CornerRadius = UDim.new(0, 5)
                UICorner.Parent = Box

                local BoxStroke = Instance.new('UIStroke')
                BoxStroke.Color = Color3.fromRGB(70, 70, 78)
                BoxStroke.Transparency = 0.48
                BoxStroke.Thickness = 1
                BoxStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                BoxStroke.Parent = Box

                local Header = Instance.new('Frame')
                Header.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Header.AnchorPoint = Vector2.new(0.5, 0)
                Header.BackgroundTransparency = 1
                Header.Position = UDim2.new(0.5, 0, 0, 0)
                Header.Name = 'Header'
                Header.Size = UDim2.new(0, 210, 0, 28)
                Header.BorderSizePixel = 0
                Header.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                Header.Parent = Box

                local CurrentOption = Instance.new('TextLabel')
                CurrentOption.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                CurrentOption.TextColor3 = Color3.fromRGB(226, 226, 232)
                CurrentOption.TextTransparency = 0
                CurrentOption.Name = 'CurrentOption'
                CurrentOption.Size = UDim2.new(0, 164, 0, 16)
                CurrentOption.AnchorPoint = Vector2.new(0, 0.5)
                CurrentOption.Position = UDim2.new(0, 10, 0.5, 0)
                CurrentOption.BackgroundTransparency = 1
                CurrentOption.TextXAlignment = Enum.TextXAlignment.Left
                CurrentOption.BorderSizePixel = 0
                CurrentOption.BorderColor3 = Color3.fromRGB(0, 0, 0)
                CurrentOption.TextSize = 11
                CurrentOption.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                CurrentOption.Parent = Header
                local UIGradient = Instance.new('UIGradient')
                UIGradient.Transparency = NumberSequence.new{
                    NumberSequenceKeypoint.new(0, 0),
                    NumberSequenceKeypoint.new(0.704, 0),
                    NumberSequenceKeypoint.new(0.872, 0.36250001192092896),
                    NumberSequenceKeypoint.new(1, 1)
                }
                UIGradient.Parent = CurrentOption

                local Arrow = Instance.new('ImageLabel')
                Arrow.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Arrow.AnchorPoint = Vector2.new(0, 0.5)
                Arrow.Image = 'rbxassetid://84232453189324'
                Arrow.ImageColor3 = Color3.fromRGB(184, 184, 194)
                Arrow.BackgroundTransparency = 1
                Arrow.Position = UDim2.new(1, -16, 0.5, 0)
                Arrow.Name = 'Arrow'
                Arrow.Size = UDim2.new(0, 9, 0, 9)
                Arrow.BorderSizePixel = 0
                Arrow.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                Arrow.Parent = Header

                local Options = Instance.new('ScrollingFrame')
                Options.ScrollBarImageColor3 = Color3.fromRGB(0, 0, 0)
                Options.Active = true
                Options.ScrollBarImageTransparency = 1
                Options.AutomaticCanvasSize = Enum.AutomaticSize.XY
                Options.ScrollBarThickness = 0
                Options.Name = 'Options'
                Options.Size = UDim2.new(0, 207, 0, 0)
                Options.BackgroundTransparency = 1
                Options.Position = UDim2.new(0, 0, 1, 0)
                Options.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                Options.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Options.BorderSizePixel = 0
                Options.CanvasSize = UDim2.new(0, 0, 0.5, 0)
                Options.Parent = Box

                local UIListLayout = Instance.new('UIListLayout')
                UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
                UIListLayout.Parent = Options

                local UIPadding = Instance.new('UIPadding')
                UIPadding.PaddingTop = UDim.new(0, 4)
                UIPadding.PaddingLeft = UDim.new(0, 11)
                UIPadding.Parent = Options

                local UIListLayout = Instance.new('UIListLayout')
                UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
                UIListLayout.Parent = Box

                function DropdownManager:update(option: string)

                    if settings.multi_dropdown then

                        if not Library._config._flags[settings.flag] then
                            Library._config._flags[settings.flag] = {};
                        end;

                        local CurrentTargetValue = nil;

                        if #Library._config._flags[settings.flag] > 0 then

                            CurrentTargetValue = convertTableToString(Library._config._flags[settings.flag]);

                        end;

                        local selected = {}

                        if CurrentTargetValue then
                            for value in string.gmatch(CurrentTargetValue, "([^,]+)") do

                                local trimmedValue = value:match("^%s*(.-)%s*$")

                                if trimmedValue ~= "Label" then
                                    table.insert(selected, trimmedValue)
                                end
                            end
                        else
                            for value in string.gmatch(CurrentOption.Text, "([^,]+)") do

                                local trimmedValue = value:match("^%s*(.-)%s*$")

                                if trimmedValue ~= "Label" then
                                    table.insert(selected, trimmedValue)
                                end
                            end
                        end;

                        local CurrentTextGet = convertStringToTable(CurrentOption.Text);

                        local optionSkibidi = "nil";
                        if typeof(option) ~= 'string' then
                            optionSkibidi = option.Name;
                        else
                            optionSkibidi = option;
                        end;

                        for i, v in pairs(CurrentTextGet) do
                            if v == optionSkibidi then
                                table.remove(CurrentTextGet, i);
                                break;
                            end
                        end

                        CurrentOption.Text = table.concat(selected, ", ")
                        local OptionsChild = {}

                        for _, object in Options:GetChildren() do
                            if object.Name == "Option" then
                                table.insert(OptionsChild, object.Text)
                                if table.find(selected, object.Text) then
                                    object.TextTransparency = 0.2
                                else
                                    object.TextTransparency = 0.6
                                end
                            end
                        end

                        CurrentTargetValue = convertStringToTable(CurrentOption.Text);

                        for _, v in CurrentTargetValue do
                            if not table.find(OptionsChild, v) and table.find(selected, v) then
                                table.remove(selected, _)
                            end;
                        end;

                        CurrentOption.Text = table.concat(selected, ", ");

                        Library._config._flags[settings.flag] = convertStringToTable(CurrentOption.Text);
                    else

                        CurrentOption.Text = (typeof(option) == "string" and option) or (option and option.Name) or ''
                        for _, object in Options:GetChildren() do
                            if object.Name == "Option" then

                                if object.Text == CurrentOption.Text then
                                    object.TextTransparency = 0.2
                                else
                                    object.TextTransparency = 0.6
                                end
                            end
                        end
                        Library._config._flags[settings.flag] = option
                    end


                    settings.callback(option)
                    Config:save(game.GameId, Library._config)
                end

                function DropdownManager:unfold_settings()
                    self._state = not self._state

                    local extra = self._state and self._size or 0

                    if self._state then
                        ModuleManager._multiplier += self._size
                    else
                        ModuleManager._multiplier -= self._size
                    end

                    TweenService:Create(Module, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Size = UDim2.fromOffset(241, 93 + ModuleManager._size + ModuleManager._multiplier)
                    }):Play()

                    TweenService:Create(Module.Options, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Size = UDim2.fromOffset(241, ModuleManager._size + ModuleManager._multiplier)
                    }):Play()

                    TweenService:Create(Dropdown, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Size = UDim2.fromOffset(210, 45 + extra)
                    }):Play()

                    TweenService:Create(Box, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Size = UDim2.fromOffset(210, 28 + extra)
                    }):Play()

                    TweenService:Create(Arrow, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Rotation = self._state and 180 or 0
                    }):Play()
                end

                function DropdownManager:refresh(new_options)
                    local old_size = self._size
                    for _, child in ipairs(Options:GetChildren()) do
                        if child.Name == 'Option' then child:Destroy() end
                    end
                    self._size = 8
                    for index, value in new_options do
                        local Option = Instance.new('TextButton')
                        Option.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                        Option.Active = false
                        Option.TextTransparency = 0.32
                        Option.AnchorPoint = Vector2.new(0, 0.5)
                        Option.TextSize = 11
                        Option.Size = UDim2.new(0, 184, 0, 19)
                        Option.TextColor3 = Color3.fromRGB(211, 211, 218)
                        Option.BorderColor3 = Color3.fromRGB(0, 0, 0)
                        Option.Text = (typeof(value) == 'string' and value) or value.Name
                        Option.AutoButtonColor = false
                        Option.Name = 'Option'
                        Option.BackgroundTransparency = 1
                        Option.TextXAlignment = Enum.TextXAlignment.Left
                        Option.Selectable = false
                        Option.Position = UDim2.new(0.04999988153576851, 0, 0.34210526943206787, 0)
                        Option.BorderSizePixel = 0
                        Option.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                        Option.Parent = Options
                        local UIGradient = Instance.new('UIGradient')
                        UIGradient.Transparency = NumberSequence.new{
                            NumberSequenceKeypoint.new(0, 0),
                            NumberSequenceKeypoint.new(0.704, 0),
                            NumberSequenceKeypoint.new(0.872, 0.36250001192092896),
                            NumberSequenceKeypoint.new(1, 1)
                        }
                        UIGradient.Parent = Option
                        Option.MouseButton1Click:Connect(function()
                            DropdownManager:update(value)
                        end)
                        if settings.maximum_options and index > settings.maximum_options then continue end
                        self._size += 19
                        Options.Size = UDim2.fromOffset(210, self._size)
                    end
                    if self._state then
                        local diff = self._size - old_size
                        ModuleManager._multiplier += diff
                        Module.Size = UDim2.fromOffset(241, 93 + ModuleManager._size + ModuleManager._multiplier)
                        Module.Options.Size = UDim2.fromOffset(241, ModuleManager._size + ModuleManager._multiplier)
                        Dropdown.Size = UDim2.fromOffset(210, 45 + self._size)
                        Box.Size = UDim2.fromOffset(210, 28 + self._size)
                    end
                end

                if #settings.options > 0 then
                    DropdownManager._size = 8

                    for index, value in settings.options do
                        local Option = Instance.new('TextButton')
                        Option.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                        Option.Active = false
                        Option.TextTransparency = 0.32
                        Option.AnchorPoint = Vector2.new(0, 0.5)
                        Option.TextSize = 11
                        Option.Size = UDim2.new(0, 184, 0, 19)
                        Option.TextColor3 = Color3.fromRGB(211, 211, 218)
                        Option.BorderColor3 = Color3.fromRGB(0, 0, 0)
                        Option.Text = (typeof(value) == "string" and value) or value.Name;
                        Option.AutoButtonColor = false
                        Option.Name = 'Option'
                        Option.BackgroundTransparency = 1
                        Option.TextXAlignment = Enum.TextXAlignment.Left
                        Option.Selectable = false
                        Option.Position = UDim2.new(0.04999988153576851, 0, 0.34210526943206787, 0)
                        Option.BorderSizePixel = 0
                        Option.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                        Option.Parent = Options

                        local UIGradient = Instance.new('UIGradient')
                        UIGradient.Transparency = NumberSequence.new{
                            NumberSequenceKeypoint.new(0, 0),
                            NumberSequenceKeypoint.new(0.704, 0),
                            NumberSequenceKeypoint.new(0.872, 0.36250001192092896),
                            NumberSequenceKeypoint.new(1, 1)
                        }
                        UIGradient.Parent = Option

                        Option.MouseButton1Click:Connect(function()
                            if not Library._config._flags[settings.flag] then
                                Library._config._flags[settings.flag] = {};
                            end;

                            if settings.multi_dropdown then
                                if table.find(Library._config._flags[settings.flag], value) then
                                    Library:remove_table_value(Library._config._flags[settings.flag], value)
                                else
                                    table.insert(Library._config._flags[settings.flag], value)
                                end
                            end

                            DropdownManager:update(value)
                        end)

                        if settings.maximum_options and index > settings.maximum_options then
                            continue
                        end

                        DropdownManager._size += 19
                        Options.Size = UDim2.fromOffset(210, DropdownManager._size)
                    end
                end

                if Library:flag_type(settings.flag, 'string') then
                    DropdownManager:update(Library._config._flags[settings.flag])
                elseif settings.options[1] then
                    DropdownManager:update(settings.options[1])
                end

                Dropdown.MouseButton1Click:Connect(function()
                    DropdownManager:unfold_settings()
                end)

                return DropdownManager
            end

            Library._flag_registry[settings.flag] = function(state)
                ModuleManager:change_state(state)
            end

            return ModuleManager
        end

        return TabManager
    end

    Connections['library_visiblity'] = UserInputService.InputBegan:Connect(function(input: InputObject, process: boolean)
        local custom = Library._config._keybinds['Minimize_Keybind']
        if custom then
            if tostring(input.KeyCode) ~= custom then return end
        else
            if input.KeyCode ~= Enum.KeyCode.RightControl then return end
        end

        self._ui_open = not self._ui_open
        if Library._config._flags['UI_Gui_Visible'] then
            self:set_gui_visibility(self._ui_open)
            return
        end
        self:change_visiblity(self._ui_open)
    end)

    self._ui.Container.Handler.Minimize.MouseButton1Click:Connect(function()
        self._ui_open = not self._ui_open
        if Library._config._flags['UI_Gui_Visible'] then
            self:set_gui_visibility(self._ui_open)
            return
        end
        self:change_visiblity(self._ui_open)
    end)

    return self
end

local ReplicatedStorage = cloneref(game:GetService("ReplicatedStorage"))
local Runtime = workspace:FindFirstChild("Runtime") or workspace:WaitForChild("Runtime")

local Player = Players.LocalPlayer

local Tornado_Time = tick();
local Grab_Parry = nil;
local Speed_Divisor_Multiplier = 1.1;
local PingHistory = {};
local MaxPingHistory = 5;
local PingAvg = 0;
do
	local StatsService = game:GetService("Stats");
	local function GetRawPing()
		local ok, val = pcall(function()
				return StatsService.Network.ServerStatsItem["Data Ping"]:GetValue();
			end);
		if ok and type(val) == "number" then
			return val;
		end;
		return 0;
	end;
	local function UpdatePingHistory()
		local raw = GetRawPing();
		table.insert(PingHistory, raw);
		if #PingHistory > MaxPingHistory then
			table.remove(PingHistory, 1);
		end;
		local sum = 0;
		for _, p in ipairs(PingHistory) do
			sum = sum + p;
		end;
		PingAvg = #PingHistory > 0 and sum / #PingHistory or raw;
		return PingAvg;
	end;
	local function GetAveragePing()
		if #PingHistory == 0 then
			return GetRawPing();
		end;
		return PingAvg;
	end;
	(getgenv())._ZX_Tune = { GetAveragePing = GetAveragePing };
	task.spawn(function()
		while true do
			UpdatePingHistory();
			task.wait(1);
		end;
	end);
end;
ZX_Parry = {
		Remote = nil,
		Function = nil,
		KeyTable = nil,
		TransformFn = nil,
		NetModule = nil,
		RemoteId = nil,
		ParryHash = nil,
		Hooked = false
	};
local lastParryTime = 0;
local parryCooldown = .05;
task.spawn(function()
	pcall(function()
			local RS = game:GetService("ReplicatedStorage");
			local getupvals = debug.getupvalues or getupvalues;
			local SC = RS:WaitForChild("Controllers", 10) and RS.Controllers:FindFirstChild("SwordsController \012");
			local PRY = SC and SC:WaitForChild("PRY", 10);
			if not PRY then
				return;
			end;
			ZX_Parry.Function = require(PRY);
			local ups = getupvals(ZX_Parry.Function);
			ZX_Parry.KeyTable = ups[3];
			ZX_Parry.TransformFn = ups[4];
			ZX_Parry.NetModule = ups[6];
			ZX_Parry.RemoteId = ups[7];
			ZX_Parry.ParryHash = ups[8];
			if not ZX_Parry.KeyTable or not ZX_Parry.TransformFn or not ZX_Parry.NetModule or not ZX_Parry.RemoteId or not ZX_Parry.ParryHash then
				return;
			end;
			local keyIndex = ZX_Parry.KeyTable[3];
			local currentKey = ZX_Parry.KeyTable[1][keyIndex];
			if not currentKey then
				return;
			end;
			local tok, transformed = pcall(ZX_Parry.TransformFn, currentKey, "TIME");
			if not tok or not transformed then
				return;
			end;
			local rok = pcall(function()
					ZX_Parry.Remote = ZX_Parry.NetModule:RemoteEvent(ZX_Parry.RemoteId);
				end);
			if not rok or not ZX_Parry.Remote then
				return;
			end;
			ZX_Parry.Hooked = true;
		end);
end);
local function generateToken(currentKey)
	if not currentKey or not ZX_Parry.TransformFn then
		return nil;
	end;
	local tok, transformed = pcall(ZX_Parry.TransformFn, currentKey, "TIME");
	if not tok or not transformed then
		return nil;
	end;
	local serverTime = workspace:GetServerTimeNow() * 100;
	local timeStr = tostring(math.floor(serverTime));
	local tokenChars = {};
	for i = 1, #timeStr, 1 do
		local ki = (i - 1) % #transformed + 1;
		local kb = string.byte(transformed, ki);
		local tb = (string.byte(timeStr, i) + i) % 256;
		local xb = bit32.bxor(tb, kb);
		tokenChars[i] = string.char(xb);
	end;
	return table.concat(tokenChars);
end;
local rs = game:GetService("ReplicatedStorage");
local playParryFunc;
local parrySuccessAllConnection;
local _parryAllTimeout = 0;
while not parrySuccessAllConnection and _parryAllTimeout < 200 do
	for i, v in getconnections(rs.Remotes.ParrySuccessAll.OnClientEvent) do
		if v.Function and (getinfo(v.Function)).name == "parrySuccessAll" then
			parrySuccessAllConnection = v;
			playParryFunc = v.Function;
			v:Disable();
		end;
	end;
	task.wait(.2);
	_parryAllTimeout = _parryAllTimeout + 1;
end;
local parrySuccessClientConnection;
local _parryClientTimeout = 0;
while not parrySuccessClientConnection and _parryClientTimeout < 200 do
	for i, v in getconnections(rs.Remotes.ParrySuccessClient.Event) do
		if v.Function and (getinfo(v.Function)).name == "parrySuccessAll" then
			parrySuccessClientConnection = v;
			v:Disable();
		end;
	end;
	task.wait(.2);
	_parryClientTimeout = _parryClientTimeout + 1;
end;
rs.Remotes.ParrySuccessAll.OnClientEvent:Connect(function(...)
	setthreadidentity(2);
	local args = { ... };
	if not playParryFunc then
		return;
	end;
	return playParryFunc(unpack(args));
end);
local Parries = 0;
local _Cache_Life = .01;
local _Cache_Ball = { value = nil, time = 0 };
local _Cache_Balls = { value = nil, time = 0 };
local _Cache_Entity = { value = nil, time = 0 };
local _Cache_Ping = { value = 0, time = 0 };
local _Cache_Animation = {};
local Auto_Parry = {};
function Auto_Parry.Parry_Animation()
	local Current_Sword = Player.Character:GetAttribute("CurrentlyEquippedSword");
	if not Current_Sword then
		return;
	end;
	local Parry_Animation = _Cache_Animation[Current_Sword];
	if not Parry_Animation then
		Parry_Animation = (game:GetService("ReplicatedStorage")).Shared.SwordAPI.Collection.Default:FindFirstChild("GrabParry");
		if not Parry_Animation then
			return;
		end;
		local Sword_Data = (game:GetService("ReplicatedStorage")).Shared.ReplicatedInstances.Swords.GetSword:Invoke(Current_Sword);
		if not Sword_Data or not Sword_Data.AnimationType then
			return;
		end;
		for _, object in pairs((game:GetService("ReplicatedStorage")).Shared.SwordAPI.Collection:GetChildren()) do
			if object.Name == Sword_Data.AnimationType then
				if object:FindFirstChild("GrabParry") or object:FindFirstChild("Grab") then
					local sword_animation_type = "GrabParry";
					if object:FindFirstChild("Grab") then
						sword_animation_type = "Grab";
					end;
					Parry_Animation = object[sword_animation_type];
				end;
			end;
		end;
		_Cache_Animation[Current_Sword] = Parry_Animation;
	end;
	Grab_Parry = Player.Character.Humanoid.Animator:LoadAnimation(Parry_Animation);
	Grab_Parry:Play();
end;
function Auto_Parry.Get_Balls()
	local Now = tick();
	if _Cache_Balls.value and Now - _Cache_Balls.time < _Cache_Life then
		return _Cache_Balls.value;
	end;
	local Balls = {};
	for _, Instance in pairs(workspace.Balls:GetChildren()) do
		if Instance:GetAttribute("realBall") then
			if Instance.CanCollide then
				Instance.CanCollide = false;
			end;
			table.insert(Balls, Instance);
		end;
	end;
	_Cache_Balls.value = Balls;
	_Cache_Balls.time = Now;
	return Balls;
end;
function Auto_Parry.Get_Ball()
	local Now = tick();
	if Now - _Cache_Ball.time < _Cache_Life then
		return _Cache_Ball.value;
	end;
	local Found = nil;
	for _, Instance in pairs(workspace.Balls:GetChildren()) do
		if Instance:GetAttribute("realBall") then
			if Instance.CanCollide then
				Instance.CanCollide = false;
			end;
			Found = Instance;
			break;
		end;
	end;
	_Cache_Ball.value = Found;
	_Cache_Ball.time = Now;
	return Found;
end;
function Auto_Parry.Get_Ping()
	local Now = tick();
	if Now - _Cache_Ping.time < .05 then
		return _Cache_Ping.value;
	end;
	local ok, value = pcall(function()
		return (game:GetService("Stats")).Network.ServerStatsItem["Data Ping"]:GetValue();
	end);
	if ok and type(value) == "number" then
		_Cache_Ping.value = value;
	end;
	_Cache_Ping.time = Now;
	return _Cache_Ping.value;
end;
local Closest_Entity = nil;
function Auto_Parry.Closest_Player()
	local Now = tick();
	if Now - _Cache_Entity.time < _Cache_Life then
		Closest_Entity = _Cache_Entity.value;
		return Closest_Entity;
	end;
	local Max_Distance = math.huge;
	local Found_Entity = nil;
	for _, Entity in pairs(workspace.Alive:GetChildren()) do
		if tostring(Entity) ~= tostring(Player) then
			if Entity.PrimaryPart then
				local Distance = Player:DistanceFromCharacter(Entity.PrimaryPart.Position);
				if Distance < Max_Distance then
					Max_Distance = Distance;
					Found_Entity = Entity;
				end;
			end;
		end;
	end;
	_Cache_Entity.value = Found_Entity;
	_Cache_Entity.time = Now;
	Closest_Entity = Found_Entity;
	return Found_Entity;
end;
local isMobile = UserInputService.TouchEnabled and not UserInputService.MouseEnabled;
local Selected_Target = nil
local Target_Lock_Enabled = false
function Auto_Parry.Parry_Data(Parry_Type)
	Auto_Parry.Closest_Player();
	local Events = {};
	if Target_Lock_Enabled and Selected_Target and Selected_Target.PrimaryPart then
		local cam = workspace.CurrentCamera;
		local target_pos = Selected_Target.PrimaryPart.Position;
		local target_cf = CFrame.new(cam.CFrame.Position, target_pos);
		local screen_pos = cam:WorldToViewportPoint(target_pos);
		local vec2_mouse = { screen_pos.X, screen_pos.Y };
		return { 0, target_cf, Events, vec2_mouse };
	end;
	local Camera = workspace.CurrentCamera;
	local Vector2_Mouse_Location;
	if isMobile then
		Vector2_Mouse_Location = { Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2 };
	else
		local ok, Mouse_Location = pcall(function()
			return UserInputService:GetMouseLocation();
		end);
		if ok and Mouse_Location then
			Vector2_Mouse_Location = { Mouse_Location.X, Mouse_Location.Y };
		else
			Vector2_Mouse_Location = { Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2 };
		end;
	end;
	if Parry_Type == "Camera" then
		return {
			0,
			Camera.CFrame,
			Events,
			Vector2_Mouse_Location,
		};
	end;
	if Parry_Type == "Backwards" then
		local Backwards_Direction = Camera.CFrame.LookVector * -10000;
		Backwards_Direction = Vector3.new(Backwards_Direction.X, 0, Backwards_Direction.Z);
		return {
			0,
			CFrame.new(Camera.CFrame.Position, Camera.CFrame.Position + Backwards_Direction),
			Events,
			Vector2_Mouse_Location,
		};
	end;
	if Parry_Type == "High" then
		local High_Direction = Camera.CFrame.UpVector * 10000;
		return {
			0,
			CFrame.new(Camera.CFrame.Position, Camera.CFrame.Position + High_Direction),
			Events,
			Vector2_Mouse_Location,
		};
	end;
	if Parry_Type == "Slowball" then
		local Slowball_Direction = Vector3.new(0, -1, 0) * 99999;
		return {
			0,
			CFrame.new(Camera.CFrame.Position, Camera.CFrame.Position + Slowball_Direction),
			Events,
			Vector2_Mouse_Location,
		};
	end;
	if Parry_Type == "Fastball" then
		local Fastball_Direction = Camera.CFrame.LookVector * 10 + Vector3.new(0, 7, 0);
		return {
			0,
			CFrame.new(Camera.CFrame.Position, Camera.CFrame.Position + Fastball_Direction),
			Events,
			Vector2_Mouse_Location,
		};
	end;
	if Parry_Type == "Left" then
		local Left_Direction = Camera.CFrame.RightVector * 10000;
		return {
			0,
			CFrame.new(Camera.CFrame.Position, Camera.CFrame.Position - Left_Direction),
			Events,
			Vector2_Mouse_Location,
		};
	end;
	if Parry_Type == "Right" then
		local Right_Direction = Camera.CFrame.RightVector * 10000;
		return {
			0,
			CFrame.new(Camera.CFrame.Position, Camera.CFrame.Position + Right_Direction),
			Events,
			Vector2_Mouse_Location,
		};
	end;
	return Parry_Type;
end;
local function _parry_hooked()
	if not ZX_Parry.Hooked or not ZX_Parry.Remote then
		return false;
	end;
	if not ZX_Parry.KeyTable or not ZX_Parry.TransformFn or not ZX_Parry.ParryHash then
		return false;
	end;
	return true;
end;
local function _send_parry(Parry_Type)
	local parryData = Auto_Parry.Parry_Data(Parry_Type);
	if not parryData then
		return false;
	end;
	local keyIndex = ZX_Parry.KeyTable[3];
	local currentKey = ZX_Parry.KeyTable[1][keyIndex];
	if not currentKey then
		return false;
	end;
	local token = generateToken(currentKey);
	if not token then
		return false;
	end;
	local cam = workspace.CurrentCamera;
	local alive = workspace:FindFirstChild("Alive");
	local playerScreenPositions = {};
	if alive then
		for _, character in ipairs(alive:GetChildren()) do
			local primary = character.PrimaryPart;
			if primary then
				playerScreenPositions[character.Name] = cam:WorldToScreenPoint(primary.Position);
			end;
		end;
	end;
	pcall(function()
		ZX_Parry.Remote:FireServer(ZX_Parry.ParryHash, currentKey, token, .5, parryData[2], playerScreenPositions, parryData[4], false);
	end);
	Parries += 1;
	task.delay(.5, function()
		if Parries > 0 then
			Parries -= 1;
		end;
	end);
	return true;
end;
function Auto_Parry.Parry(Parry_Type)
	if tick() - lastParryTime < parryCooldown then
		return false;
	end;
	if not _parry_hooked() then
		return false;
	end;
	lastParryTime = tick();
	_send_parry(Parry_Type);
end;
local Lerp_Radians = 0;
local Last_Warping = tick();
function Auto_Parry.Linear_Interpolation(a, b, time_volume)
	time_volume = math.clamp(time_volume, 0, 1);
	return a + (b - a) * time_volume;
end;
local Previous_Velocity = {};
local Curving = tick();
(getgenv())._ZX_VelHistory = (getgenv())._ZX_VelHistory or { ball = {}, player = {}, MAX_SAMPLES = 5 };
local _ZX_VelHistory = (getgenv())._ZX_VelHistory;
function _ZX_pushVelSample(target, pos, vel)
	local history = target == "ball" and _ZX_VelHistory.ball or _ZX_VelHistory.player;
	table.insert(history, 1, { pos = pos, vel = vel, t = tick() });
	while #history > _ZX_VelHistory.MAX_SAMPLES do
		table.remove(history, #history);
	end;
end;
function _ZX_calcAcceleration(target)
	local history = target == "ball" and _ZX_VelHistory.ball or _ZX_VelHistory.player;
	if #history < 2 then
		return Vector3.zero;
	end;
	local newest = history[1];
	local oldest = history[#history];
	local dt = newest.t - oldest.t;
	if dt <= 0 then
		return Vector3.zero;
	end;
	return (newest.vel - oldest.vel) / dt;
end;
function _ZX_predictFuturePosition(target, t_future)
	local history = target == "ball" and _ZX_VelHistory.ball or _ZX_VelHistory.player;
	if #history == 0 then
		return nil;
	end;
	local newest = history[1];
	local accel = _ZX_calcAcceleration(target);
	local predicted = (newest.pos + newest.vel * t_future) + ((.5 * accel) * t_future) * t_future;
	if #history >= 3 then
		local P0 = history[3].pos;
		local P1 = history[2].pos;
		local P2 = history[1].pos;
		local t_bezier = 1 + t_future;
		local omt = 1 - t_bezier;
		local bezierPoint = ((omt * omt) * P0 + ((2 * omt) * t_bezier) * P1) + (t_bezier * t_bezier) * P2;
		predicted = predicted:Lerp(bezierPoint, .5);
	end;
	return predicted;
end;
function _ZX_calcSpeedDivisorBase(speed)
	return 2.2 + .9 * math.log(1 + speed / 80);
end;
function Auto_Parry.Is_Curved()
	local Ball = Auto_Parry.Get_Ball();
	if not Ball then
		return false;
	end;
	local Zoomies = Ball:FindFirstChild("zoomies");
	if not Zoomies then
		return false;
	end;
	local Ping = Auto_Parry.Get_Ping();
	local Velocity = Zoomies.VectorVelocity;
	local Ball_Direction = Velocity.Unit;
	local playerPos = Player.Character.PrimaryPart.Position;
	local ballPos = Ball.Position;
	local Direction = (playerPos - ballPos).Unit;
	local Dot = Direction:Dot(Ball_Direction);
	local Speed = Velocity.Magnitude;
	local Speed_Threshold = math.min(Speed / 100, 40);
	local Distance = (playerPos - ballPos).Magnitude;
	local Reach_Time = Distance / Speed - Ping / 1000;
	local Ball_Distance_Threshold = (15 - math.min(Distance / 1000, 15)) + Speed_Threshold;
	table.insert(Previous_Velocity, Velocity);
	if #Previous_Velocity > 4 then
		table.remove(Previous_Velocity, 1);
	end;
	if Ball:FindFirstChild("AeroDynamicSlashVFX") then
		Debris:AddItem(Ball.AeroDynamicSlashVFX, 0);
		Tornado_Time = tick();
	end;
	if Runtime:FindFirstChild("Tornado") then
		if tick() - Tornado_Time < (Runtime.Tornado:GetAttribute("TornadoTime") or 1) + .314159 then
			return true;
		end;
	end;
	local Enough_Speed = Speed > 160;
	if Enough_Speed and Reach_Time > Ping / 10 + .03 then
		if Speed < 300 then
			Ball_Distance_Threshold = math.max(Ball_Distance_Threshold - 13, 13);
		elseif Speed <= 600 then
			Ball_Distance_Threshold = math.max(Ball_Distance_Threshold - 15, 15);
		elseif Speed <= 1000 then
			Ball_Distance_Threshold = math.max(Ball_Distance_Threshold - 17, 17);
		else
			Ball_Distance_Threshold = math.max(Ball_Distance_Threshold - 19, 19);
		end;
	end;
	if Distance < Ball_Distance_Threshold then
		return false;
	end;
	local adjustedReachTime = Reach_Time + .03;
	if Speed < 300 then
		if tick() - Curving < adjustedReachTime / 1.15 then
			return true;
		end;
	elseif Speed < 450 then
		if tick() - Curving < adjustedReachTime / 1.18 then
			return true;
		end;
	elseif Speed < 600 then
		if tick() - Curving < adjustedReachTime / 1.3 then
			return true;
		end;
	else
		if tick() - Curving < adjustedReachTime / 1.45 then
			return true;
		end;
	end;
	local Dot_Threshold = 0 - Ping / 1000;
	local Direction_Difference = Ball_Direction - Velocity.Unit;
	local Direction_Similarity = Direction:Dot(Direction_Difference.Unit);
	local Dot_Difference = Dot - Direction_Similarity;
	if Dot_Difference < Dot_Threshold then
		return true;
	end;
	local Clamped_Dot = math.clamp(Dot, -1, 1);
	local Radians = math.deg(math.asin(Clamped_Dot));
	Lerp_Radians = Auto_Parry.Linear_Interpolation(Lerp_Radians, Radians, .8);
	if Speed < 300 then
		if Lerp_Radians < .015 then
			Last_Warping = tick();
		end;
		if tick() - Last_Warping < adjustedReachTime / 1.15 then
			return true;
		end;
	else
		if Lerp_Radians < .012 then
			Last_Warping = tick();
		end;
		if tick() - Last_Warping < adjustedReachTime / 1.45 then
			return true;
		end;
	end;
	if #Previous_Velocity == 4 then
		for i = 1, 2, 1 do
			local prevDir = (Ball_Direction - Previous_Velocity[i].Unit).Unit;
			local prevDot = Direction:Dot(prevDir);
			if Dot - prevDot < Dot_Threshold then
				return true;
			end;
		end;
	end;
	local backwardsCurveDetected = false;
	local BACK_RANGE = 200;
	local targeted = Ball:GetAttribute("target") == tostring(Player);
	if targeted and Distance < BACK_RANGE then
		if Dot < 0.05 and Lerp_Radians < 0.15 then
			backwardsCurveDetected = true;
		end;
		if not backwardsCurveDetected then
			local bcDotThreshold = math.clamp(0.55 - (Distance / BACK_RANGE) * 0.25, 0.30, 0.55);
			local willMiss = Dot < Dot_Threshold;
			if willMiss and Dot < bcDotThreshold and Speed > 15 then
				backwardsCurveDetected = true;
			end;
		end;
	end;
	if not backwardsCurveDetected then
		local horizDirection = Vector3.new(playerPos.X - ballPos.X, 0, playerPos.Z - ballPos.Z);
		if horizDirection.Magnitude > 0 then
			horizDirection = horizDirection.Unit;
		end;
		local awayFromPlayer = -horizDirection;
		local horizBallDir = Vector3.new(Ball_Direction.X, 0, Ball_Direction.Z);
		if horizBallDir.Magnitude > 0 then
			horizBallDir = horizBallDir.Unit;
			local backwardsAngle = math.deg(math.acos(math.clamp(awayFromPlayer:Dot(horizBallDir), -1, 1)));
			if backwardsAngle < 60 then
				backwardsCurveDetected = true;
			end;
		end;
	end;
	return Dot < Dot_Threshold or backwardsCurveDetected;
end;
local Target_Lock_Highlight = nil
local Target_Lock_Label = nil
local Target_Label_Enabled = false
local Connections_Manager = {};
local AutoParryEnabled = false;
local Selected_Parry_Type = nil;
local Parried = false;
local Last_Parry = 0;
local Randomize_Curve = false;
local Curve_Pool = { "Backwards", "High", "Slowball", "Fastball", "Left", "Right" };
local function Resolve_Parry_Type()
	if not Randomize_Curve then
		return Selected_Parry_Type;
	end;
	return Curve_Pool[math.random(#Curve_Pool)];
end;
local playerGui = game.Players.LocalPlayer:WaitForChild("PlayerGui");
local Hotbar = playerGui:WaitForChild("Hotbar", 10);
local ParryBlock = Hotbar and Hotbar:WaitForChild("Block", 10);
local ParryCD = ParryBlock and ParryBlock:FindFirstChildOfClass("UIGradient");
local AbilityButton = Hotbar and Hotbar:WaitForChild("Ability", 10);
local AbilityCD = AbilityButton and AbilityButton:FindFirstChildOfClass("UIGradient");
local function isCooldownInEffect1(uigradient)
	return uigradient.Offset.Y < .4;
end;
local function cooldownProtection()
	if ParryCD and isCooldownInEffect1(ParryCD) then
		pcall(function()
			(game:GetService("ReplicatedStorage")).Remotes.AbilityButtonPress:Fire();
		end);
		return true;
	end;
	return false;
end;

local LocalPlayer = Players.LocalPlayer

do
    local animFix = false
    local Grab_Parry = nil
    local SwordAPI, AnimationCache = nil, {}
    local lastplayedd = 0
    local bypasscd = false
    local AnimationDelay = 1

    pcall(function()
        SwordAPI = ReplicatedStorage:WaitForChild("Shared", 5) and ReplicatedStorage.Shared:WaitForChild("SwordAPI", 5)
    end)

    local function GetCharacter() return LocalPlayer.Character end
    local function GetHumanoid()
        local char = GetCharacter()
        return char and char:FindFirstChildOfClass("Humanoid")
    end
    local function StopAnimation(track)
        track:Stop(track:GetAttribute("StopFadeTime") or 0.1)
    end
    local function PlayGrabAnimation(track)
        track:Play(track:GetAttribute("PlayFadeTime") or 0, track:GetAttribute("PlayWeight") or 1, track:GetAttribute("PlaySpeed") or 1)
    end
    local function GetParryAnimation()
        if not SwordAPI then return nil end
        local char = GetCharacter()
        if not char then return nil end
        local currentSword = char:GetAttribute("CurrentlyEquippedSword")
        if not currentSword then return SwordAPI.Collection.Default:FindFirstChild("GrabParry") end
        if AnimationCache[currentSword] then return AnimationCache[currentSword] end
        local ok, swordData = pcall(function()
            return ReplicatedStorage.Shared.ReplicatedInstances.Swords.GetSword:Invoke(currentSword)
        end)
        if not ok or type(swordData) ~= "table" then
            AnimationCache[currentSword] = SwordAPI.Collection.Default:FindFirstChild("GrabParry")
            return AnimationCache[currentSword]
        end
        for _, obj in pairs(SwordAPI.Collection:GetChildren()) do
            if obj.Name == swordData.AnimationType then
                local anim = obj:FindFirstChild("GrabParry") or obj:FindFirstChild("Grab")
                if anim then AnimationCache[currentSword] = anim; return anim end
            end
        end
        AnimationCache[currentSword] = SwordAPI.Collection.Default:FindFirstChild("GrabParry")
        return AnimationCache[currentSword]
    end
    local function PlayParry_Animation()
        local humanoid = GetHumanoid()
        if not humanoid then return end
        local animation = GetParryAnimation()
        if not animation then return end
        for _, track in pairs(humanoid.Animator:GetPlayingAnimationTracks()) do
            if track.Name == "GrabParry" or track.Name == "Grab" then
                track.TimePosition = 0; StopAnimation(track)
            elseif track.Name == "SuccessParry" or track.Name == "Success" then
                StopAnimation(track)
            end
        end
        Grab_Parry = humanoid.Animator:LoadAnimation(animation)
        PlayGrabAnimation(Grab_Parry)
    end
    local function SpamParry_Animation()
        if not animFix then return end
        if (os.clock() - lastplayedd) >= (AnimationDelay - 0.9) or bypasscd then
            lastplayedd = os.clock()
            bypasscd = false
            pcall(PlayParry_Animation)
        end
    end

    pcall(function()
        ReplicatedStorage.Remotes.ParrySuccess.OnClientEvent:Connect(function()
            bypasscd = true
            local humanoid = GetHumanoid()
            if humanoid then
                for _, track in pairs(humanoid.Animator:GetPlayingAnimationTracks()) do
                    if track.Name == "GrabParry" or track.Name == "Grab" then StopAnimation(track) end
                end
            end
        end)
    end)

    local originalParryAnimation = Auto_Parry.Parry_Animation

    Auto_Parry.Parry_Animation = function()
        if animFix then
            return SpamParry_Animation()
        end

        if originalParryAnimation then
            return originalParryAnimation()
        end
    end

    ZX_SetAnimationFix = function(value)
        animFix = value and true or false
    end
end

task.spawn(function()
    pcall(function()
        local RS = game:GetService("ReplicatedStorage")
        local getupvals = debug.getupvalues or getupvalues
        if not getupvals then return end

        local SC = RS:WaitForChild("Controllers", 10)
        SC = SC and SC:FindFirstChild("SwordsController \12")
        local PRY = SC and SC:WaitForChild("PRY", 10)
        if not PRY then return end

        local Parry_Function = require(PRY)
        local ups = getupvals(Parry_Function)

        local keyTable = ups[3]
        local transformFn = ups[4]
        local netModule = ups[6]
        local remoteId = ups[7]
        local parryHash = ups[8]
        if not (keyTable and transformFn and netModule and remoteId and parryHash) then return end

        local parryRemote
        pcall(function()
            parryRemote = netModule:RemoteEvent(remoteId)
        end)
        if not parryRemote then return end

        if ZX_Parry and not ZX_Parry.Remote then
            ZX_Parry.KeyTable = keyTable
            ZX_Parry.TransformFn = transformFn
            ZX_Parry.NetModule = netModule
            ZX_Parry.RemoteId = remoteId
            ZX_Parry.ParryHash = parryHash
            ZX_Parry.Remote = parryRemote
            ZX_Parry.Hooked = true
        end
    end)
end)

local library = Library.new()
local Blatant = library:create_tab('Blatant', 'rbxassetid://137110061186987')
local Detection = library:create_tab('Detection', 'rbxassetid://117564972951337', 20)
local Visual = library:create_tab('Visual', 'rbxassetid://101377186242044')
local Misc = library:create_tab('Misc', 'rbxassetid://92887699286229')
local Interface = library:create_tab('Interface', 'rbxassetid://94381583400007', 16, Color3.fromRGB(100, 100, 100), Color3.fromRGB(190, 190, 190))

library:load()

local TeleportService = cloneref(game:GetService('TeleportService'))

local server_tools_module = Misc:create_module({
	title = 'Server Tools',
	flag = 'Server_Tools',
	description = 'Rejoin or hop to another server',
	section = 'left',
	callback = function() end,
})

local server_tools_frame = (function()
	for _, obj in library._ui:GetDescendants() do
		if obj.Name == 'Module' then
			local h = obj:FindFirstChild('Header')
			local mn = h and h:FindFirstChild('ModuleName')
			if mn and mn.Text == 'Server Tools' then
				return obj
			end
		end
	end
end)()

if server_tools_frame then
	local Options = server_tools_frame:FindFirstChild('Options')

	if Options then
		local function make_button(label, layout_order, on_click)
			local Holder = Instance.new('Frame')
			Holder.Name = 'ButtonHolder'
			Holder.Size = UDim2.fromOffset(207, 23)
			Holder.BackgroundTransparency = 1
			Holder.BorderSizePixel = 0
			Holder.LayoutOrder = layout_order
			Holder.Parent = Options

			local Btn = Instance.new('TextButton')
			Btn.Name = 'Button'
			Btn.AnchorPoint = Vector2.new(0, 1)
			Btn.Position = UDim2.new(0, 0, 1, 0)
			Btn.Size = UDim2.fromOffset(207, 22)
			Btn.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
			Btn.BorderSizePixel = 0
			Btn.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
			Btn.TextColor3 = Color3.fromRGB(202, 202, 209)
			Btn.TextSize = 12
			Btn.AutoButtonColor = false
			Btn.Text = label
			Btn.Parent = Holder

			local BtnCorner = Instance.new('UICorner')
			BtnCorner.CornerRadius = UDim.new(0, 4)
			BtnCorner.Parent = Btn

			local BtnStroke = Instance.new('UIStroke')
			BtnStroke.Color = Color3.fromRGB(255, 255, 255)
			BtnStroke.Transparency = 0.72
			BtnStroke.Thickness = 1
			BtnStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			BtnStroke.Parent = Btn

			Btn.MouseButton1Click:Connect(on_click)
		end

		make_button('Rejoin', 1, function()
			local lp = Players.LocalPlayer
			TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, lp)
		end)

		make_button('Server Hop', 2, function()
			local lp = Players.LocalPlayer
			local PlaceId = game.PlaceId
			local CurrentJobId = game.JobId
			
			local success, result = pcall(function()
				return HttpService:JSONDecode(HttpService:GetAsync('https://games.roblox.com/v1/games/'..PlaceId..'/servers/0?sortOrder=Asc&limit=100', true))
			end)
			
			if success and result and result.data then
				local servers = result.data
				local availableServers = {}
				
				for _, server in ipairs(servers) do
					if server.id ~= CurrentJobId and server.maxPlayers > server.players then
						table.insert(availableServers, server)
					end
				end
				
				if #availableServers > 0 then
					local randomServer = availableServers[math.random(1, #availableServers)]
					TeleportService:TeleportToPlaceInstance(PlaceId, randomServer.id, lp)
					return
				end
			end
			TeleportService:Teleport(PlaceId, lp)
		end)

		server_tools_module._size = (server_tools_module._size == 0 and 11 or server_tools_module._size) + 62
		if server_tools_module._state then
			server_tools_frame.Size = UDim2.fromOffset(241, 93 + server_tools_module._size)
		end
		Options.Size = UDim2.fromOffset(241, server_tools_module._size)
	end
end

do
	local Anti_Lag_Conn = nil
	local Anti_Lag_Desc_Conn = nil
	local Anti_Lag_Char_Conn = nil

	local Lighting = cloneref(game:GetService('Lighting'))
	local SoundService = cloneref(game:GetService('SoundService'))

	local Anti_Lag_Types = {
		ParticleEmitter = true,
		Trail = true,
		Smoke = true,
		Fire = true,
		Sparkles = true,
		Sound = true,
	}

	local orig_shadow = Lighting.GlobalShadows
	local orig_ambient = SoundService.AmbientReverb

	local function disable_effect(v)
		if Anti_Lag_Types[v.ClassName] then
			pcall(function()
				if v:IsA('Sound') then
					v.Volume = 0
				else
					v.Enabled = false
				end
			end)
		end
	end

	local function disable_all_effects()
		for _, v in pairs(workspace:GetDescendants()) do
			disable_effect(v)
		end
	end

	local function enable_anti_lag()
		pcall(function()
			local clientFX = Players.LocalPlayer.PlayerScripts:FindFirstChild('EffectScripts')
			clientFX = clientFX and clientFX:FindFirstChild('ClientFX')
			if clientFX then clientFX.Disabled = true end
		end)

		if Anti_Lag_Conn then Anti_Lag_Conn:Disconnect() end
		Anti_Lag_Conn = Runtime.ChildAdded:Connect(function(v)
			Debris:AddItem(v, 0)
		end)

		if Anti_Lag_Desc_Conn then Anti_Lag_Desc_Conn:Disconnect() end
		Anti_Lag_Desc_Conn = workspace.DescendantAdded:Connect(function(v)
			disable_effect(v)
		end)

		if Anti_Lag_Char_Conn then Anti_Lag_Char_Conn:Disconnect() end
		Anti_Lag_Char_Conn = Players.LocalPlayer.CharacterAdded:Connect(function()
			task.defer(disable_all_effects)
		end)

		disable_all_effects()

		pcall(function()
			for _, v in pairs(Lighting:GetChildren()) do
				if v:IsA('BloomEffect') or v:IsA('SunRaysEffect') or v:IsA('DepthOfFieldEffect') or v:IsA('BlurEffect') then
					v.Enabled = false
				end
			end
			orig_shadow = Lighting.GlobalShadows
			Lighting.GlobalShadows = false
		end)

		pcall(function()
			orig_ambient = SoundService.AmbientReverb
			SoundService.AmbientReverb = Enum.ReverbType.NoReverb
		end)
	end

	local function disable_anti_lag()
		pcall(function()
			local clientFX = Players.LocalPlayer.PlayerScripts:FindFirstChild('EffectScripts')
			clientFX = clientFX and clientFX:FindFirstChild('ClientFX')
			if clientFX then clientFX.Disabled = false end
		end)

		if Anti_Lag_Conn then Anti_Lag_Conn:Disconnect(); Anti_Lag_Conn = nil end
		if Anti_Lag_Desc_Conn then Anti_Lag_Desc_Conn:Disconnect(); Anti_Lag_Desc_Conn = nil end
		if Anti_Lag_Char_Conn then Anti_Lag_Char_Conn:Disconnect(); Anti_Lag_Char_Conn = nil end

		pcall(function()
			for _, v in pairs(Lighting:GetChildren()) do
				if v:IsA('BloomEffect') or v:IsA('SunRaysEffect') or v:IsA('DepthOfFieldEffect') or v:IsA('BlurEffect') then
					v.Enabled = true
				end
			end
			Lighting.GlobalShadows = orig_shadow
		end)

		pcall(function()
			SoundService.AmbientReverb = orig_ambient
			for _, v in pairs(workspace:GetDescendants()) do
				if v:IsA('Sound') then
					pcall(function() v.Volume = v:GetAttribute('_orig_vol') or 0.5 end)
				end
			end
		end)
	end

	Misc:create_module({
		title = 'Anti Lag',
		flag = 'Anti_Lag',
		description = 'Disables Effects to Reduce Lag',
		section = 'right',
		callback = function(state)
			if state then
				enable_anti_lag()
			else
				disable_anti_lag()
			end
		end,
	})

	getgenv()._Zuro_AntiLag_Cleanup = disable_anti_lag
end

do
	local _td_conn = nil
	local _td_mod = nil
	local _td_orig_cd = nil
	local _td_orig_cdr = nil

	local _sj_conn = nil
	local _sj_mod = nil
	local _sj_orig_cd = nil
	local _sj_orig_cdr = nil

	local function _ensure_td()
		if _td_mod then return true end
		local shared = ReplicatedStorage:FindFirstChild('Shared')
		local abilities = shared and shared:FindFirstChild('Abilities')
		local m = abilities and abilities:FindFirstChild('Thunder Dash')
		if not m then return false end
		local ok, result = pcall(require, m)
		if ok and result then
			_td_mod = result
			_td_orig_cd = result.cooldown
			_td_orig_cdr = result.cooldownReductionPerUpgrade
			return true
		end
		return false
	end

	local function _apply_td()
		if not _ensure_td() then return end
		pcall(function()
			_td_mod.cooldown = 0
			_td_mod.cooldownReductionPerUpgrade = 0
		end)
	end

	local function _restore_td()
		if not _td_mod then return end
		pcall(function()
			_td_mod.cooldown = _td_orig_cd
			_td_mod.cooldownReductionPerUpgrade = _td_orig_cdr
		end)
	end

	local function start_thunder_dash_exploit()
		if _td_conn then return end
		_apply_td()
		_td_conn = task.spawn(function()
			while _td_conn do
				_apply_td()
				task.wait(0.5)
			end
		end)
	end

	local function stop_thunder_dash_exploit()
		_td_conn = nil
		_restore_td()
	end

	local function _ensure_sj()
		if _sj_mod then return true end
		local shared = ReplicatedStorage:FindFirstChild('Shared')
		local abilities = shared and shared:FindFirstChild('Abilities')
		local m = abilities and abilities:FindFirstChild('Super Jump')
		if not m then return false end
		local ok, result = pcall(require, m)
		if ok and result then
			_sj_mod = result
			_sj_orig_cd = result.cooldown
			_sj_orig_cdr = result.cooldownReductionPerUpgrade
			return true
		end
		return false
	end

	local function _apply_sj()
		if not _ensure_sj() then return end
		pcall(function()
			_sj_mod.cooldown = 0
			_sj_mod.cooldownReductionPerUpgrade = 0
		end)
	end

	local function _restore_sj()
		if not _sj_mod then return end
		pcall(function()
			_sj_mod.cooldown = _sj_orig_cd
			_sj_mod.cooldownReductionPerUpgrade = _sj_orig_cdr
		end)
	end

	local function start_super_jump_exploit()
		if _sj_conn then return end
		_apply_sj()
		_sj_conn = task.spawn(function()
			while _sj_conn do
				_apply_sj()
				task.wait(0.5)
			end
		end)
	end

	local function stop_super_jump_exploit()
		_sj_conn = nil
		_restore_sj()
	end

	local _da_conn = nil
	local _da_mod = nil
	local _da_orig_cd = nil
	local _da_orig_cdr = nil

	local function _ensure_da()
		if _da_mod then return true end
		local shared = ReplicatedStorage:FindFirstChild('Shared')
		local abilities = shared and shared:FindFirstChild('Abilities')
		local m = abilities and abilities:FindFirstChild('Dash')
		if not m then return false end
		local ok, result = pcall(require, m)
		if ok and result then
			_da_mod = result
			_da_orig_cd = result.cooldown
			_da_orig_cdr = result.cooldownReductionPerUpgrade
			return true
		end
		return false
	end

	local function _apply_da()
		if not _ensure_da() then return end
		pcall(function()
			_da_mod.cooldown = 0
			_da_mod.cooldownReductionPerUpgrade = 0
		end)
	end

	local function _restore_da()
		if not _da_mod then return end
		pcall(function()
			_da_mod.cooldown = _da_orig_cd
			_da_mod.cooldownReductionPerUpgrade = _da_orig_cdr
		end)
	end

	local function start_dash_exploit()
		if _da_conn then return end
		_apply_da()
		_da_conn = task.spawn(function()
			while _da_conn do
				_apply_da()
				task.wait(0.5)
			end
		end)
	end

	local function stop_dash_exploit()
		_da_conn = nil
		_restore_da()
	end

	getgenv()._Zuro_TD_Stop = function()
		stop_thunder_dash_exploit()
		stop_super_jump_exploit()
		stop_dash_exploit()
	end

	local ability_exploit_module = Misc:create_module({
		title = 'Ability Exploit',
		flag = 'AbilityExploit',
		description = 'Ability no cooldowns',
		section = 'left',
		callback = function(value)
			getgenv().AbilityExploit = value
			if not value then
				stop_thunder_dash_exploit()
				stop_super_jump_exploit()
				stop_dash_exploit()
			end
		end,
	})

	ability_exploit_module:create_checkbox({
		title = 'Thunder Dash',
		flag = 'ThunderDashNoCooldown',
		callback = function(value)
			getgenv().ThunderDashNoCooldown = value
			if value and getgenv().AbilityExploit then
				start_thunder_dash_exploit()
			else
				stop_thunder_dash_exploit()
			end
		end,
	})

	ability_exploit_module:create_checkbox({
		title = 'Super Jump',
		flag = 'SuperJumpNoCooldown',
		callback = function(value)
			getgenv().SuperJumpNoCooldown = value
			if value and getgenv().AbilityExploit then
				start_super_jump_exploit()
			else
				stop_super_jump_exploit()
			end
		end,
	})

	ability_exploit_module:create_checkbox({
		title = 'Dash',
		flag = 'DashNoCooldown',
		callback = function(value)
			getgenv().DashNoCooldown = value
			if value and getgenv().AbilityExploit then
				start_dash_exploit()
			else
				stop_dash_exploit()
			end
		end,
	})

	ability_exploit_module._size += 6
	if ability_exploit_module._state then
		ability_exploit_module:change_state(true)
	end
end

local Det = {
	Infinity_Active = false,
	DeathSlash_Active = false,
	TimeHole_Active = false,
	Pull_Active = false,
	Slashes_Active = false,
	Slashes_Count = 0,
	Infinity_Enabled = false,
	DeathSlash_Enabled = false,
	TimeHole_Enabled = false,
	Pull_Enabled = false,
	Singularity_Enabled = false,
	Forcefield_Active = false,
	Slashes_Enabled = false,
	Forcefield_Enabled = false,
	Slashes_ParryDelay = 0.05,
	Slashes_MaxCount = 36,
}

local Net = ReplicatedStorage:FindFirstChild('Packages')
Net = Net and Net:FindFirstChild('_Index')
Net = Net and Net:FindFirstChild('sleitnick_net@0.1.0')
Net = Net and Net:FindFirstChild('net')

ReplicatedStorage.Remotes.InfinityBall.OnClientEvent:Connect(function(_, state)
	Det.Infinity_Active = state or false
end)

ReplicatedStorage.Remotes.DeathBall.OnClientEvent:Connect(function(_, state)
	Det.DeathSlash_Active = state or false
end)

pcall(function()
	ReplicatedStorage.Remotes.PlrPulled.OnClientEvent:Connect(function(a, b)
		if type(a) == 'boolean' then
			Det.Pull_Active = a
		elseif type(b) == 'boolean' then
			Det.Pull_Active = b
		else
			Det.Pull_Active = true
			task.delay(1.5, function() Det.Pull_Active = false end)
		end
	end)
end)

pcall(function()
	ReplicatedStorage.Remotes.PlrPulsed.OnClientEvent:Connect(function(a, b)
		if type(a) == 'boolean' then
			Det.Pull_Active = a
		elseif type(b) == 'boolean' then
			Det.Pull_Active = b
		else
			Det.Pull_Active = true
			task.delay(1.5, function() Det.Pull_Active = false end)
		end
	end)
end)

pcall(function()
	local char = Players.LocalPlayer.Character or Players.LocalPlayer.CharacterAdded:Wait()
	local function watch_forcefield(c)
		c.AttributeChanged:Connect(function(attr)
			if attr == 'PassiveLock_ForceField' then
				Det.Forcefield_Active = c:GetAttribute('PassiveLock_ForceField') == true
			end
		end)
	end
	watch_forcefield(char)
	Players.LocalPlayer.CharacterAdded:Connect(function(c)
		Det.Forcefield_Active = false
		watch_forcefield(c)
	end)
end)

if Net then
	local TimeHoleActivate = Net:FindFirstChild('RE/TimeHoleActivate')
	local TimeHoleDeactivate = Net:FindFirstChild('RE/TimeHoleDeactivate')

	if TimeHoleActivate then
		TimeHoleActivate.OnClientEvent:Connect(function()
			Det.TimeHole_Active = true
		end)
	end

	if TimeHoleDeactivate then
		TimeHoleDeactivate.OnClientEvent:Connect(function()
			Det.TimeHole_Active = false
		end)
	end
end

if Net then
	local SlashesActivate = Net:FindFirstChild('RE/SlashesOfFuryActivate')
	local SlashesEnd = Net:FindFirstChild('RE/SlashesOfFuryEnd')
	local SlashesCatch = Net:FindFirstChild('RE/SlashesOfFuryCatch')
	local SlashesParry = Net:FindFirstChild('RE/SlashesOfFuryParry')

	if SlashesActivate then
		SlashesActivate.OnClientEvent:Connect(function()
			Det.Slashes_Active = true
			Det.Slashes_Count = 0
		end)
	end

	if SlashesEnd then
		SlashesEnd.OnClientEvent:Connect(function()
			Det.Slashes_Active = false
			Det.Slashes_Count = 0
		end)
	end

	if SlashesParry then
		SlashesParry.OnClientEvent:Connect(function()
			Det.Slashes_Count += 1
		end)
	end

	if SlashesCatch then
		SlashesCatch.OnClientEvent:Connect(function()
			if not Det.Slashes_Enabled then return end
			task.spawn(function()
				while Det.Slashes_Active and Det.Slashes_Count < Det.Slashes_MaxCount do
					Auto_Parry.Parry(Resolve_Parry_Type())
					task.wait(Det.Slashes_ParryDelay)
				end
			end)
		end)
	end
end

do
	local _GROUP_ID = 12836673
	local _MIN_RANK = 10
	local _detected = {}
	local _action = 'Notification'
	local _playerAddedConn = nil

	local function _check_player(plr)
		if plr == Player or _detected[plr.UserId] then return end
		local ok, rank = pcall(function() return plr:GetRankInGroup(_GROUP_ID) end)
		if not ok or rank < _MIN_RANK then return end
		_detected[plr.UserId] = true
		if _action == 'Notification' then
			Library.SendNotification({ title = 'Staff Detected', text = plr.Name .. ' joined the server', duration = 6 })
		elseif _action == 'Kick' then
			Player:Kick('Staff joined the server.')
		end
	end

	local function _start_staff_detection()
		table.clear(_detected)
		for _, plr in pairs(Players:GetPlayers()) do
			task.spawn(_check_player, plr)
		end
		if not _playerAddedConn then
			_playerAddedConn = Players.PlayerAdded:Connect(function(plr)
				if not getgenv().StaffDetection then return end
				task.spawn(_check_player, plr)
			end)
		end
	end

	local function _stop_staff_detection()
		if _playerAddedConn then
			_playerAddedConn:Disconnect()
			_playerAddedConn = nil
		end
		table.clear(_detected)
	end

	getgenv()._Zuro_StaffDet_Stop = _stop_staff_detection

	local staff_detection_module = Detection:create_module({
		title = 'Staff Detection',
		flag = 'StaffDetection',
		description = 'Detect Bladeball moderator to server',
		section = 'left',
		callback = function(state)
			getgenv().StaffDetection = state
			if state then
				_start_staff_detection()
			else
				_stop_staff_detection()
			end
		end,
	})

	staff_detection_module:create_dropdown({
		title = 'Action Mode',
		flag = 'StaffDetection_Action',
		options = { 'Notification', 'Kick' },
		multi_dropdown = false,
		maximum_options = 2,
		callback = function(value)
			_action = (typeof(value) == 'string' and value) or value.Name
		end,
	})

	if staff_detection_module._state then
		staff_detection_module:change_state(true)
	end
end

local infinity_detection_module = Detection:create_module({
	title = 'Infinity Detection',
	flag = 'Detection_Infinity',
	description = 'Infinity Detection',
	section = 'left',
	callback = function(state)
		Det.Infinity_Enabled = state
	end,
})

local deathslash_detection_module = Detection:create_module({
	title = 'Death Slash Detection',
	flag = 'Detection_DeathSlash',
	description = 'Death Slash Detection',
	section = 'left',
	callback = function(state)
		Det.DeathSlash_Enabled = state
	end,
})

local timehole_detection_module = Detection:create_module({
	title = 'Time Hole Detection',
	flag = 'Detection_TimeHole',
	description = 'Time Hole Detection',
	section = 'right',
	callback = function(state)
		Det.TimeHole_Enabled = state
	end,
})

local pull_detection_module = Detection:create_module({
	title = 'Pull Detection',
	flag = 'Detection_Pull',
	description = 'Pull Detection',
	section = 'right',
	callback = function(state)
		Det.Pull_Enabled = state
	end,
})

Detection:create_module({
	title = 'Singularity Detection',
	flag = 'Detection_Singularity',
	description = 'Singularity Detection',
	section = 'left',
	callback = function(state)
		Det.Singularity_Enabled = state
	end,
})

local slashes_detection_module = Detection:create_module({
	title = 'Slashes of Fury',
	flag = 'Detection_SlashesOfFury',
	description = 'Slashes of Fury Detection',
	section = 'right',
	callback = function(state)
		Det.Slashes_Enabled = state
	end,
})

slashes_detection_module:create_slider({
	title = 'Parry Delay',
	flag = 'Detection_SlashesOfFury_Delay',
	minimum_value = 0.05,
	maximum_value = 0.25,
	value = 0.05,
	round_number = false,
	callback = function(value)
		Det.Slashes_ParryDelay = value
	end,
})

slashes_detection_module:create_slider({
	title = 'Max Parry Count',
	flag = 'Detection_SlashesOfFury_MaxCount',
	minimum_value = 1,
	maximum_value = 36,
	value = 36,
	round_number = true,
	callback = function(value)
		Det.Slashes_MaxCount = value
	end,
})

slashes_detection_module._size += 6
if slashes_detection_module._state then
	slashes_detection_module:change_state(true)
end

Detection:create_module({
	title = 'Forcefield Detection',
	flag = 'Detection_Forcefield',
	description = 'Forcefield Detection',
	section = 'right',
	callback = function(state)
		Det.Forcefield_Enabled = state
	end,
})

local Target_Highlight_Enabled = false

local function apply_highlight(character)
    if Target_Lock_Highlight then
        Target_Lock_Highlight:Destroy()
        Target_Lock_Highlight = nil
    end
    if not character or not Target_Highlight_Enabled then
        return
    end
    local hl = Instance.new('Highlight')
    hl.FillColor = Color3.fromRGB(255, 255, 255)
    hl.OutlineColor = Color3.fromRGB(255, 255, 255)
    hl.FillTransparency = 0.6
    hl.OutlineTransparency = 0
    hl.Adornee = character
    hl.Parent = CoreGui
    Target_Lock_Highlight = hl
end

local function apply_label(character)
    if Target_Lock_Label then
        Target_Lock_Label:Destroy()
        Target_Lock_Label = nil
    end
    if not character or not Target_Label_Enabled then
        return
    end
    local head = character:FindFirstChild('Head')
    if not head then
        return
    end
    local player = Players:GetPlayerFromCharacter(character)
    local bill = Instance.new('BillboardGui')
    bill.Name = 'ZuroTargetLabel'
    bill.Size = UDim2.fromOffset(80, 90)
    bill.StudsOffset = Vector3.new(0, 2.5, 0)
    bill.AlwaysOnTop = true
    bill.ResetOnSpawn = false
    bill.Adornee = head
    bill.Parent = CoreGui
    local thumb = Instance.new('ImageLabel')
    thumb.Size = UDim2.fromOffset(40, 40)
    thumb.AnchorPoint = Vector2.new(0.5, 0)
    thumb.Position = UDim2.new(0.5, 0, 0, 0)
    thumb.BackgroundTransparency = 1
    thumb.BorderSizePixel = 0
    thumb.Image = player and ('rbxthumb://type=AvatarHeadShot&id='..player.UserId..'&w=48&h=48') or ''
    thumb.ScaleType = Enum.ScaleType.Fit
    thumb.Parent = bill
    local ThumbCorner = Instance.new('UICorner')
    ThumbCorner.CornerRadius = UDim.new(1, 0)
    ThumbCorner.Parent = thumb
    local name_label = Instance.new('TextLabel')
    name_label.Size = UDim2.new(1, 0, 0, 18)
    name_label.AnchorPoint = Vector2.new(0.5, 0)
    name_label.Position = UDim2.new(0.5, 0, 0, 44)
    name_label.BackgroundTransparency = 1
    name_label.FontFace = Font.new('rbxasset://fonts/families/SFPro.json', Enum.FontWeight.Bold, Enum.FontStyle.Normal)
    name_label.Text = tostring(character)
    name_label.TextColor3 = Color3.fromRGB(255, 255, 255)
    name_label.TextSize = 12
    name_label.TextStrokeTransparency = 0.5
    name_label.TextXAlignment = Enum.TextXAlignment.Center
    name_label.Parent = bill
    Target_Lock_Label = bill
end

local function set_target(character)
    Selected_Target = character
    if Target_Highlight_Enabled then
        apply_highlight(character)
    end
    if Target_Label_Enabled then
        apply_label(character)
    end
end

local StatsOverlayState = {
    overlay = nil,
    fpsConnection = nil,
    fps = 0,
    ping = 0,
    samples = {},
    maxSamples = 24
}

local function destroy_performance_overlay()
    if StatsOverlayState.fpsConnection then
        StatsOverlayState.fpsConnection:Disconnect()
        StatsOverlayState.fpsConnection = nil
    end
    if StatsOverlayState.overlay and StatsOverlayState.overlay.dragConnection then
        StatsOverlayState.overlay.dragConnection:Disconnect()
    end
    if StatsOverlayState.overlay and StatsOverlayState.overlay.gui then
        StatsOverlayState.overlay.gui:Destroy()
    end
    StatsOverlayState.overlay = nil
    table.clear(StatsOverlayState.samples)
end

local function create_performance_overlay()
    if StatsOverlayState.overlay then
        return
    end

    local OverlayGui = Instance.new('ScreenGui')
    OverlayGui.Name = 'ZuroPerformanceMetrics'
    OverlayGui.ResetOnSpawn = false
    OverlayGui.IgnoreGuiInset = true
    OverlayGui.DisplayOrder = 99
    OverlayGui.Parent = CoreGui

    local GraphShadow = Instance.new('ImageLabel')
    GraphShadow.Name = 'GraphShadow'
    GraphShadow.Size = UDim2.new(0, 212, 0, 104)
    GraphShadow.Position = UDim2.new(0, 232, 0.5, -86)
    GraphShadow.BackgroundTransparency = 1
    GraphShadow.BorderSizePixel = 0
    GraphShadow.Image = 'rbxassetid://6014261993'
    GraphShadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
    GraphShadow.ImageTransparency = 0.38
    GraphShadow.ScaleType = Enum.ScaleType.Slice
    GraphShadow.SliceCenter = Rect.new(49, 49, 450, 450)
    GraphShadow.ZIndex = 0
    GraphShadow.Parent = OverlayGui

    local GraphPanel = Instance.new('Frame')
    GraphPanel.Name = 'GraphPanel'
    GraphPanel.Size = UDim2.new(0, 184, 0, 76)
    GraphPanel.Position = UDim2.new(0, 246, 0.5, -72)
    GraphPanel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    GraphPanel.BorderSizePixel = 0
    GraphPanel.Active = true
    GraphPanel.Parent = OverlayGui

    local GraphCorner = Instance.new('UICorner')
    GraphCorner.CornerRadius = UDim.new(0, 7)
    GraphCorner.Parent = GraphPanel

    local GraphStroke = Instance.new('UIStroke')
    GraphStroke.Color = Color3.fromRGB(255, 255, 255)
    GraphStroke.Transparency = 0.88
    GraphStroke.Thickness = 1
    GraphStroke.Parent = GraphPanel

    local GraphPanelGradient = Instance.new('UIGradient')
    GraphPanelGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0.00, Color3.fromRGB(145, 145, 145)),
        ColorSequenceKeypoint.new(0.30, Color3.fromRGB(14, 14, 16)),
        ColorSequenceKeypoint.new(1.00, Color3.fromRGB(0, 0, 0))
    }
    GraphPanelGradient.Rotation = 90
    GraphPanelGradient.Parent = GraphPanel

    local PingValue = Instance.new('TextLabel')
    PingValue.Name = 'PingValue'
    PingValue.Size = UDim2.new(0, 82, 0, 21)
    PingValue.Position = UDim2.new(1, -91, 0, 4)
    PingValue.BackgroundTransparency = 1
    PingValue.FontFace = Font.new('rbxasset://fonts/families/SFPro.json', Enum.FontWeight.Bold, Enum.FontStyle.Normal)
    PingValue.Text = '0 ms'
    PingValue.TextColor3 = Color3.fromRGB(238, 238, 242)
    PingValue.TextSize = 15
    PingValue.TextXAlignment = Enum.TextXAlignment.Right
    PingValue.Parent = GraphPanel

    local Divider = Instance.new('Frame')
    Divider.Size = UDim2.new(1, -20, 0, 1)
    Divider.Position = UDim2.new(0, 9, 0, 27)
    Divider.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Divider.BackgroundTransparency = 0.92
    Divider.BorderSizePixel = 0
    Divider.Parent = GraphPanel

    local GraphArea = Instance.new('Frame')
    GraphArea.Name = 'GraphArea'
    GraphArea.Size = UDim2.new(1, -18, 0, 38)
    GraphArea.Position = UDim2.new(0, 9, 0, 32)
    GraphArea.BackgroundTransparency = 1
    GraphArea.BorderSizePixel = 0
    GraphArea.ClipsDescendants = true
    GraphArea.Parent = GraphPanel

    for index = 1, 4 do
        local GridLine = Instance.new('Frame')
        GridLine.Name = 'VerticalGridLine'
        GridLine.Size = UDim2.new(0, 1, 1, 0)
        GridLine.Position = UDim2.new(index / 5, 0, 0, 0)
        GridLine.BackgroundColor3 = Color3.fromRGB(58, 58, 62)
        GridLine.BackgroundTransparency = 0.55
        GridLine.BorderSizePixel = 0
        GridLine.ZIndex = 1
        GridLine.Parent = GraphArea
    end

    local Bars = {}
    for index = 1, StatsOverlayState.maxSamples do
        local Bar = Instance.new('Frame')
        Bar.Name = 'Bar'
        Bar.AnchorPoint = Vector2.new(0, 1)
        Bar.Size = UDim2.new(0, 7, 0, 5)
        Bar.Position = UDim2.new(0, (index - 1) * 7, 1, -4)
        Bar.BackgroundColor3 = Color3.fromRGB(126, 203, 255)
        Bar.BackgroundTransparency = 0
        Bar.BorderSizePixel = 0
        Bar.ZIndex = 2
        Bar.Parent = GraphArea

        local BarGradient = Instance.new('UIGradient')
        BarGradient.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0.00, Color3.fromRGB(205, 237, 255)),
            ColorSequenceKeypoint.new(0.30, Color3.fromRGB(151, 216, 255)),
            ColorSequenceKeypoint.new(0.72, Color3.fromRGB(92, 181, 242)),
            ColorSequenceKeypoint.new(1.00, Color3.fromRGB(48, 122, 190))
        }
        BarGradient.Rotation = 90
        BarGradient.Parent = Bar

        local Highlight = Instance.new('Frame')
        Highlight.Name = 'Highlight'
        Highlight.Size = UDim2.new(1, 0, 0, 1)
        Highlight.Position = UDim2.new(0, 0, 0, 0)
        Highlight.BackgroundColor3 = Color3.fromRGB(235, 248, 255)
        Highlight.BackgroundTransparency = 0.34
        Highlight.BorderSizePixel = 0
        Highlight.ZIndex = 3
        Highlight.Parent = Bar

        local SegmentLine = Instance.new('Frame')
        SegmentLine.Name = 'SegmentLine'
        SegmentLine.Size = UDim2.new(0, 1, 1, 0)
        SegmentLine.Position = UDim2.new(1, -1, 0, 0)
        SegmentLine.BackgroundColor3 = Color3.fromRGB(38, 105, 168)
        SegmentLine.BackgroundTransparency = 0.18
        SegmentLine.BorderSizePixel = 0
        SegmentLine.ZIndex = 3
        SegmentLine.Parent = Bar

        Bars[index] = Bar
    end

    local FpsPanel = Instance.new('Frame')
    FpsPanel.Name = 'FpsPanel'
    FpsPanel.Size = UDim2.new(0, 140, 0, 34)
    FpsPanel.Position = UDim2.new(0, 290, 0.5, 12)
    FpsPanel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    FpsPanel.BorderSizePixel = 0
    FpsPanel.Active = true
    FpsPanel.Parent = OverlayGui

    local FpsCorner = Instance.new('UICorner')
    FpsCorner.CornerRadius = UDim.new(0, 12)
    FpsCorner.Parent = FpsPanel

    local FpsStroke = Instance.new('UIStroke')
    FpsStroke.Color = Color3.fromRGB(255, 255, 255)
    FpsStroke.Transparency = 0.86
    FpsStroke.Thickness = 1
    FpsStroke.Parent = FpsPanel

    local FpsPanelGradient = Instance.new('UIGradient')
    FpsPanelGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0.00, Color3.fromRGB(145, 145, 145)),
        ColorSequenceKeypoint.new(0.30, Color3.fromRGB(14, 14, 16)),
        ColorSequenceKeypoint.new(1.00, Color3.fromRGB(0, 0, 0))
    }
    FpsPanelGradient.Rotation = 90
    FpsPanelGradient.Parent = FpsPanel

    local FpsValue = Instance.new('TextLabel')
    FpsValue.Name = 'FpsValue'
    FpsValue.Size = UDim2.new(0, 68, 1, 0)
    FpsValue.Position = UDim2.new(0, 14, 0, 0)
    FpsValue.BackgroundTransparency = 1
    FpsValue.FontFace = Font.new('rbxasset://fonts/families/SFPro.json', Enum.FontWeight.Bold, Enum.FontStyle.Normal)
    FpsValue.Text = '0'
    FpsValue.TextColor3 = Color3.fromRGB(255, 255, 255)
    FpsValue.TextSize = 24
    FpsValue.TextXAlignment = Enum.TextXAlignment.Left
    FpsValue.Parent = FpsPanel

    local FpsLabel = Instance.new('TextLabel')
    FpsLabel.Size = UDim2.new(0, 48, 1, 0)
    FpsLabel.Position = UDim2.new(1, -58, 0, 0)
    FpsLabel.BackgroundTransparency = 1
    FpsLabel.FontFace = Font.new('rbxasset://fonts/families/SFPro.json', Enum.FontWeight.Bold, Enum.FontStyle.Normal)
    FpsLabel.Text = 'FPS'
    FpsLabel.TextColor3 = Color3.fromRGB(178, 178, 185)
    FpsLabel.TextSize = 12
    FpsLabel.Parent = FpsPanel

    local dragging = false
    local dragStart = nil
    local graphStart = nil
    local fpsStart = nil
    local shadowStart = nil

    local function beginDrag(input)
        dragging = true
        dragStart = input.Position
        graphStart = GraphPanel.Position
        fpsStart = FpsPanel.Position
        shadowStart = GraphShadow.Position
    end

    GraphPanel.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            beginDrag(input)
        end
    end)

    FpsPanel.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            beginDrag(input)
        end
    end)

    local dragConnection = UserInputService.InputChanged:Connect(function(input)
        if not dragging then
            return
        end
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            local delta = input.Position - dragStart
            GraphPanel.Position = UDim2.new(graphStart.X.Scale, graphStart.X.Offset + delta.X, graphStart.Y.Scale, graphStart.Y.Offset + delta.Y)
            FpsPanel.Position = UDim2.new(fpsStart.X.Scale, fpsStart.X.Offset + delta.X, fpsStart.Y.Scale, fpsStart.Y.Offset + delta.Y)
            GraphShadow.Position = UDim2.new(shadowStart.X.Scale, shadowStart.X.Offset + delta.X, shadowStart.Y.Scale, shadowStart.Y.Offset + delta.Y)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputState == Enum.UserInputState.End then
            dragging = false
        end
    end)

    StatsOverlayState.overlay = {
        gui = OverlayGui,
        pingValue = PingValue,
        fpsValue = FpsValue,
        bars = Bars,
        dragConnection = dragConnection
    }
end

local function update_performance_overlay()
    local overlay = StatsOverlayState.overlay
    if not overlay then
        return
    end

    overlay.pingValue.Text = tostring(StatsOverlayState.ping) .. ' ms'
    overlay.fpsValue.Text = tostring(StatsOverlayState.fps)

    table.insert(StatsOverlayState.samples, StatsOverlayState.ping)
    if #StatsOverlayState.samples > StatsOverlayState.maxSamples then
        table.remove(StatsOverlayState.samples, 1)
    end

    for index, bar in ipairs(overlay.bars) do
        local sample = StatsOverlayState.samples[index] or 0
        local height = math.clamp(5 + sample / 38, 5, 10)
        bar.Size = UDim2.new(0, 7, 0, height)
    end
end

Visual:create_module({
    title = "Performance",
    description = "Show your FPS and Ping",
    flag = "StatsOverlayModule",
    section = "left",
    callback = function(state)
        if state then
            create_performance_overlay()

            local frameCount = 0
            local elapsed = 0
            local updateElapsed = 0

            StatsOverlayState.fpsConnection = RunService.RenderStepped:Connect(function(deltaTime)
                frameCount += 1
                elapsed += deltaTime
                updateElapsed += deltaTime

                if elapsed >= 0.5 then
                    StatsOverlayState.fps = math.round(frameCount / elapsed)
                    frameCount = 0
                    elapsed = 0
                end

                if updateElapsed >= 0.5 then
                    StatsOverlayState.ping = math.round(Players.LocalPlayer:GetNetworkPing() * 1000)
                    update_performance_overlay()
                    updateElapsed = 0
                end
            end)
        else
            destroy_performance_overlay()
        end
    end
})

local BallStatsState = {
    gui = nil,
    frame = nil,
    vlog = nil,
    plog = nil,
    connection = nil,
    peak_velocity = 0
}

local function get_real_ball()
    local balls = workspace:FindFirstChild('Balls')
    if not balls then
        return nil
    end

    for _, ball in pairs(balls:GetChildren()) do
        if ball:GetAttribute('realBall') then
            ball.CanCollide = false
            return ball
        end
    end

    return nil
end

local function destroy_ball_stats()
    if BallStatsState.connection then
        BallStatsState.connection:Disconnect()
        BallStatsState.connection = nil
    end

    if BallStatsState.gui then
        pcall(function()
            BallStatsState.gui:Destroy()
        end)
    end

    BallStatsState.gui = nil
    BallStatsState.frame = nil
    BallStatsState.vlog = nil
    BallStatsState.plog = nil
    BallStatsState.peak_velocity = 0
end

local function create_ball_stats_gui()
    if BallStatsState.gui then
        return
    end

    local OverlayGui = Instance.new('ScreenGui')
    OverlayGui.Name = 'ZuroBallMetrics'
    OverlayGui.ResetOnSpawn = false
    OverlayGui.IgnoreGuiInset = true
    OverlayGui.DisplayOrder = 99
    OverlayGui.Parent = CoreGui

    local Panel = Instance.new('Frame')
    Panel.Name = 'Panel'
    Panel.Size = UDim2.new(0, 184, 0, 96)
    Panel.Position = UDim2.new(0, 20, 0.5, -48)
    Panel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Panel.BorderSizePixel = 0
    Panel.Active = true
    Panel.Parent = OverlayGui

    local PanelCorner = Instance.new('UICorner')
    PanelCorner.CornerRadius = UDim.new(0, 13)
    PanelCorner.Parent = Panel

    local PanelStroke = Instance.new('UIStroke')
    PanelStroke.Color = Color3.fromRGB(255, 255, 255)
    PanelStroke.Transparency = 0.78
    PanelStroke.Thickness = 1
    PanelStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    PanelStroke.Parent = Panel

    local PanelGradient = Instance.new('UIGradient')
    PanelGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0.00, Color3.fromRGB(145, 145, 145)),
        ColorSequenceKeypoint.new(0.30, Color3.fromRGB(12, 12, 12)),
        ColorSequenceKeypoint.new(1.00, Color3.fromRGB(0, 0, 0))
    }
    PanelGradient.Rotation = 90
    PanelGradient.Parent = Panel

    local BoltIcon = Instance.new('ImageLabel')
    BoltIcon.Name = 'BoltIcon'
    BoltIcon.Size = UDim2.fromOffset(18, 18)
    BoltIcon.Position = UDim2.new(0, 12, 0, 9)
    BoltIcon.BackgroundTransparency = 1
    BoltIcon.BorderSizePixel = 0
    BoltIcon.Image = 'rbxassetid://100394875638012'
    BoltIcon.ImageColor3 = Color3.fromRGB(255, 255, 255)
    BoltIcon.ScaleType = Enum.ScaleType.Fit
    BoltIcon.Parent = Panel

    local TitleLabel = Instance.new('TextLabel')
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Size = UDim2.new(1, -46, 0, 22)
    TitleLabel.Position = UDim2.new(0, 33, 0, 7)
    TitleLabel.FontFace = Font.new('rbxasset://fonts/families/SFPro.json', Enum.FontWeight.Bold, Enum.FontStyle.Normal)
    TitleLabel.Text = 'Ball Stats'
    TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    TitleLabel.TextSize = 16
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.TextYAlignment = Enum.TextYAlignment.Center
    TitleLabel.Parent = Panel

    local Divider = Instance.new('Frame')
    Divider.Name = 'Divider'
    Divider.Size = UDim2.new(1, -20, 0, 1)
    Divider.Position = UDim2.new(0, 10, 0, 34)
    Divider.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Divider.BackgroundTransparency = 0.93
    Divider.BorderSizePixel = 0
    Divider.Parent = Panel

    local VelocityLabel = Instance.new('TextLabel')
    VelocityLabel.BackgroundTransparency = 1
    VelocityLabel.Size = UDim2.new(0, 88, 0, 24)
    VelocityLabel.Position = UDim2.new(0, 14, 0, 42)
    VelocityLabel.FontFace = Font.new('rbxasset://fonts/families/SFPro.json', Enum.FontWeight.Medium, Enum.FontStyle.Normal)
    VelocityLabel.Text = 'Speed'
    VelocityLabel.TextColor3 = Color3.fromRGB(178, 178, 185)
    VelocityLabel.TextSize = 14
    VelocityLabel.TextXAlignment = Enum.TextXAlignment.Left
    VelocityLabel.TextYAlignment = Enum.TextYAlignment.Center
    VelocityLabel.Parent = Panel

    local SpeedVal = Instance.new('TextLabel')
    SpeedVal.Name = 'SpeedValue'
    SpeedVal.BackgroundTransparency = 1
    SpeedVal.Size = UDim2.new(0, 64, 0, 24)
    SpeedVal.Position = UDim2.new(1, -78, 0, 42)
    SpeedVal.FontFace = Font.new('rbxasset://fonts/families/SFPro.json', Enum.FontWeight.Bold, Enum.FontStyle.Normal)
    SpeedVal.Text = '0.0'
    SpeedVal.TextColor3 = Color3.fromRGB(255, 255, 255)
    SpeedVal.TextSize = 16
    SpeedVal.TextXAlignment = Enum.TextXAlignment.Right
    SpeedVal.TextYAlignment = Enum.TextYAlignment.Center
    SpeedVal.Parent = Panel

    local PeakLabel = Instance.new('TextLabel')
    PeakLabel.BackgroundTransparency = 1
    PeakLabel.Size = UDim2.new(0, 88, 0, 24)
    PeakLabel.Position = UDim2.new(0, 14, 0, 67)
    PeakLabel.FontFace = Font.new('rbxasset://fonts/families/SFPro.json', Enum.FontWeight.Medium, Enum.FontStyle.Normal)
    PeakLabel.Text = 'Peak'
    PeakLabel.TextColor3 = Color3.fromRGB(178, 178, 185)
    PeakLabel.TextSize = 14
    PeakLabel.TextXAlignment = Enum.TextXAlignment.Left
    PeakLabel.TextYAlignment = Enum.TextYAlignment.Center
    PeakLabel.Parent = Panel

    local PeakVal = Instance.new('TextLabel')
    PeakVal.Name = 'PeakValue'
    PeakVal.BackgroundTransparency = 1
    PeakVal.Size = UDim2.new(0, 64, 0, 24)
    PeakVal.Position = UDim2.new(1, -78, 0, 67)
    PeakVal.FontFace = Font.new('rbxasset://fonts/families/SFPro.json', Enum.FontWeight.Bold, Enum.FontStyle.Normal)
    PeakVal.Text = '0.0'
    PeakVal.TextColor3 = Color3.fromRGB(255, 255, 255)
    PeakVal.TextSize = 16
    PeakVal.TextXAlignment = Enum.TextXAlignment.Right
    PeakVal.TextYAlignment = Enum.TextYAlignment.Center
    PeakVal.Parent = Panel

    Panel.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            local dragStart = input.Position
            local startPos = Panel.Position
            local moving = true
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    moving = false
                end
            end)
            local dragConnection
            dragConnection = UserInputService.InputChanged:Connect(function(changedInput)
                if not moving then
                    dragConnection:Disconnect()
                    return
                end
                if changedInput.UserInputType == Enum.UserInputType.MouseMovement or changedInput.UserInputType == Enum.UserInputType.Touch then
                    local delta = changedInput.Position - dragStart
                    Panel.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
                end
            end)
        end
    end)

    BallStatsState.gui = OverlayGui
    BallStatsState.frame = Panel
    BallStatsState.vlog = SpeedVal
    BallStatsState.plog = PeakVal
end

local function enable_ball_stats()
    create_ball_stats_gui()

    if BallStatsState.connection then
        BallStatsState.connection:Disconnect()
        BallStatsState.connection = nil
    end

    local _ball_elapsed = 0
    BallStatsState.connection = RunService.RenderStepped:Connect(function(dt)
        _ball_elapsed += dt
        if _ball_elapsed < 0.05 then return end
        _ball_elapsed = 0
        if not BallStatsState.frame or not BallStatsState.vlog or not BallStatsState.plog then
            return
        end

        local ball = get_real_ball()
        local speed = 0

        if ball then
            local velocity = ball.AssemblyLinearVelocity or Vector3.new()
            if typeof(velocity) == 'Vector3' then
                speed = velocity.Magnitude
            end
        end

        BallStatsState.vlog.Text = string.format('%.1f', speed)

        if speed > BallStatsState.peak_velocity then
            BallStatsState.peak_velocity = speed
            BallStatsState.plog.Text = string.format('%.1f', BallStatsState.peak_velocity)
        end
    end)
end

Visual:create_module({
    title = 'Ball Statistic',
    flag = 'Ball_Stats',
    description = 'Show the Ball Velocity',
    section = 'left',
    callback = function(state)
        if state then
            enable_ball_stats()
        else
            destroy_ball_stats()
        end
    end
})

local Cosmetics_Cleanup = {}
local Cosmetics_CharConn = nil

local function applyKorblox(character)
    local leg = character:FindFirstChild('Right Leg') or character:FindFirstChild('RightLeg')
    if not leg then return end
    if leg:FindFirstChild('KorbloxMesh') then return end
    for _, child in ipairs(leg:GetChildren()) do
        if child:IsA('SpecialMesh') then child:Destroy() end
    end
    local mesh = Instance.new('SpecialMesh')
    mesh.Name = 'KorbloxMesh'
    mesh.MeshId = 'rbxassetid://902942096'
    mesh.TextureId = 'rbxassetid://902843398'
    mesh.Offset = Vector3.new(0, 0.7, 0)
    mesh.Parent = leg
end

local function restoreKorblox(character)
    local leg = character:FindFirstChild('Right Leg') or character:FindFirstChild('RightLeg')
    if not leg then return end
    for _, child in ipairs(leg:GetChildren()) do
        if child:IsA('SpecialMesh') then child:Destroy() end
    end
end

local function applyHeadless(character)
    local head = character:FindFirstChild('Head')
    if not head then return end
    if Cosmetics_Cleanup.headTransparency == nil then
        Cosmetics_Cleanup.headTransparency = head.Transparency
    end
    local face = head:FindFirstChildOfClass('Decal')
    if face then
        Cosmetics_Cleanup.faceDecalId = face.Texture
        Cosmetics_Cleanup.faceDecalName = face.Name
    end
    head.Transparency = 1
    for _, child in ipairs(head:GetChildren()) do
        if child:IsA('Decal') or child.Name == 'face' then
            child.Transparency = 1
        elseif child:IsA('SpecialMesh') or child:IsA('DataModelMesh') then
            if not child:GetAttribute('OriginalScale') then
                child:SetAttribute('OriginalScale', child.Scale)
                child.Scale = Vector3.new(0, 0, 0)
            end
        end
    end
end

local function restoreHeadless(character)
    local head = character:FindFirstChild('Head')
    if not head then return end
    if Cosmetics_Cleanup.headTransparency ~= nil then
        head.Transparency = Cosmetics_Cleanup.headTransparency
    end
    if Cosmetics_Cleanup.faceDecalId then
        local decal = head:FindFirstChildOfClass('Decal') or Instance.new('Decal', head)
        decal.Name = Cosmetics_Cleanup.faceDecalName or 'face'
        decal.Texture = Cosmetics_Cleanup.faceDecalId
        decal.Face = Enum.NormalId.Front
    end
    for _, child in ipairs(head:GetChildren()) do
        if child:IsA('Decal') or child.Name == 'face' then
            child.Transparency = 0
        elseif child:IsA('SpecialMesh') or child:IsA('DataModelMesh') then
            local orig = child:GetAttribute('OriginalScale')
            if orig then
                child.Scale = orig
                child:SetAttribute('OriginalScale', nil)
            end
        end
    end
end

local function applyCosmetics(character)
    if not character then return end
    applyKorblox(character)
    applyHeadless(character)
end

Visual:create_module({
    title = 'Player Cosmetics',
    flag = 'Player_Cosmetics',
    description = 'Apply Headless and Korblox',
    section = 'right',
    callback = function(state)
        local lp = Players.LocalPlayer
        if state then
            Cosmetics_Cleanup = {}
            if lp.Character then applyCosmetics(lp.Character) end
            if Cosmetics_CharConn then Cosmetics_CharConn:Disconnect() end
            Cosmetics_CharConn = lp.CharacterAdded:Connect(function(char)
                task.wait(0.5)
                applyCosmetics(char)
            end)
        else
            if Cosmetics_CharConn then
                Cosmetics_CharConn:Disconnect()
                Cosmetics_CharConn = nil
            end
            if lp.Character then
                restoreHeadless(lp.Character)
                restoreKorblox(lp.Character)
            end
            Cosmetics_Cleanup = {}
        end
    end,
})

do
local ESP_Data = {}
local ESP_HeartbeatConn = nil
local ESP_PlayerAddedConn = nil
local ESP_Cooldowns = {}
local ESP_IconCache = {}
local ESP_CharConns = {}
local ESP_AliveAddedConn = nil
local ESP_AliveRemovedConn = nil
local _esp_last_update = 0

local _Abilities = require(game.ReplicatedStorage.Shared.Abilities)

local function esp_get_cd(player)
    local ability = player:GetAttribute('CurrentlyEquippedAbility') or player:GetAttribute('EquippedAbility')
    if not ability then return nil end
    local ok, cd = pcall(_Abilities.getAbilityCooldown, player, ability)
    if ok and type(cd) == 'number' and cd > 0 then return cd end
    return nil
end

local function esp_get_icon(abilityName)
    if not abilityName or abilityName == '' then return '' end
    if ESP_IconCache[abilityName] ~= nil then return ESP_IconCache[abilityName] end
    local shared = game.ReplicatedStorage:FindFirstChild('Shared')
    local abilities = shared and shared:FindFirstChild('Abilities')
    local m = abilities and abilities:FindFirstChild(abilityName)
    if not m then ESP_IconCache[abilityName] = ''; return '' end
    local ok, mod = pcall(require, m)
    local icon = (ok and mod and type(mod.iconId) == 'string') and mod.iconId or ''
    ESP_IconCache[abilityName] = icon
    return icon
end

local function create_esp_for_player(player)
    task.spawn(function()
        local char = player.Character
        while not char or not char.Parent do
            task.wait()
            char = player.Character
        end
        local head = char:WaitForChild('Head', 10)
        if not head or not getgenv().AbilityESP then return end

        if ESP_Data[player] then
            pcall(function() ESP_Data[player].bill:Destroy() end)
            if ESP_Data[player].cdConn then
                pcall(function() ESP_Data[player].cdConn:Disconnect() end)
            end
            ESP_Data[player] = nil
        end

        local bill = Instance.new('BillboardGui')
        bill.Name = 'AbilityESPGui'
        bill.Adornee = head
        bill.Size = UDim2.fromOffset(100, 62)
        bill.StudsOffset = Vector3.new(0, 3.2, 0)
        bill.AlwaysOnTop = true
        bill.ResetOnSpawn = false
        bill.Parent = CoreGui

        local icon = Instance.new('ImageLabel')
        icon.Name = 'AbilityIcon'
        icon.Size = UDim2.fromOffset(32, 32)
        icon.AnchorPoint = Vector2.new(0.5, 0)
        icon.Position = UDim2.new(0.5, 0, 0, 0)
        icon.BackgroundTransparency = 1
        icon.BorderSizePixel = 0
        icon.ScaleType = Enum.ScaleType.Fit
        icon.Image = esp_get_icon(player:GetAttribute('CurrentlyEquippedAbility') or player:GetAttribute('EquippedAbility') or '')
        icon.Parent = bill

        local label = Instance.new('TextLabel')
        label.Size = UDim2.new(1, 0, 0, 14)
        label.Position = UDim2.new(0, 0, 0, 34)
        label.BackgroundTransparency = 1
        label.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.Bold, Enum.FontStyle.Normal)
        label.TextColor3 = Color3.fromRGB(255, 255, 255)
        label.TextSize = 11
        label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        label.TextStrokeTransparency = 0.2
        label.TextXAlignment = Enum.TextXAlignment.Center
        label.TextTruncate = Enum.TextTruncate.AtEnd
        label.Text = player:GetAttribute('CurrentlyEquippedAbility') or player:GetAttribute('EquippedAbility') or player.DisplayName
        label.Parent = bill

        local timerLabel = Instance.new('TextLabel')
        timerLabel.Size = UDim2.new(1, 0, 0, 13)
        timerLabel.Position = UDim2.new(0, 0, 0, 49)
        timerLabel.BackgroundTransparency = 1
        timerLabel.FontFace = Font.new('rbxasset://fonts/families/SFPro.json', Enum.FontWeight.Bold, Enum.FontStyle.Normal)
        timerLabel.TextColor3 = Color3.fromRGB(100, 220, 100)
        timerLabel.TextSize = 12
        timerLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        timerLabel.TextStrokeTransparency = 0.2
        timerLabel.TextXAlignment = Enum.TextXAlignment.Center
        timerLabel.Text = 'Ready'
        timerLabel.Parent = bill

        local _last_cd_trigger = 0
        local cdConn = char.AttributeChanged:Connect(function(attr)
            if attr == 'CooldownExpiration' then
                local val = char:GetAttribute('CooldownExpiration')
                if (val == 0 or val == nil) and tick() - _last_cd_trigger > 0.5 then
                    local dur = esp_get_cd(player)
                    if dur then
                        _last_cd_trigger = tick()
                        ESP_Cooldowns[player] = { expiry = tick() + dur, duration = dur }
                    end
                end
            elseif attr == 'AbilityActive' then
                local active = char:GetAttribute('AbilityActive')
                if active == true and tick() - _last_cd_trigger > 0.5 then
                    local dur = esp_get_cd(player)
                    if dur then
                        _last_cd_trigger = tick()
                        ESP_Cooldowns[player] = { expiry = tick() + dur, duration = dur }
                    end
                end
            end
        end)

        local _ability = player:GetAttribute('CurrentlyEquippedAbility') or player:GetAttribute('EquippedAbility')
        local _ok, _dur = pcall(_Abilities.getAbilityCooldown, player, _ability or '')
        local _isPassive = _ok and type(_dur) == 'number' and _dur <= 0

        ESP_Data[player] = {
            bill = bill,
            label = label,
            icon = icon,
            timerLabel = timerLabel,
            cdConn = cdConn,
            isPassive = _isPassive,
        }
    end)
end

local function add_esp_player(player)
    if player == Players.LocalPlayer then return end
    if ESP_CharConns[player] then return end

    local charAddedConn = player.CharacterAdded:Connect(function()
        ESP_Cooldowns[player] = nil
        create_esp_for_player(player)
    end)

    local charRemovingConn = player.CharacterRemoving:Connect(function()
        ESP_Cooldowns[player] = nil
        if ESP_Data[player] then
            if ESP_Data[player].isPassive then
                ESP_Data[player].timerLabel.Text = 'Passive'
                ESP_Data[player].timerLabel.TextColor3 = Color3.fromRGB(160, 160, 180)
            else
                ESP_Data[player].timerLabel.Text = 'Ready'
                ESP_Data[player].timerLabel.TextColor3 = Color3.fromRGB(100, 220, 100)
            end
        end
    end)

    ESP_CharConns[player] = { charAddedConn, charRemovingConn }

    if player.Character then
        create_esp_for_player(player)
    end
end

local function esp_reset_all_cooldowns()
    table.clear(ESP_Cooldowns)
    for _, data in pairs(ESP_Data) do
        pcall(function()
            if data.isPassive then
                data.timerLabel.Text = 'Passive'
                data.timerLabel.TextColor3 = Color3.fromRGB(160, 160, 180)
            else
                data.timerLabel.Text = 'Ready'
                data.timerLabel.TextColor3 = Color3.fromRGB(100, 220, 100)
            end
        end)
    end
end

local function start_ability_esp()
    getgenv().AbilityESP = true

    local _lastAliveCount = #workspace.Alive:GetChildren()
    if not ESP_AliveAddedConn then
        ESP_AliveAddedConn = workspace.Alive.ChildAdded:Connect(function()
            if not getgenv().AbilityESP then return end
            local count = #workspace.Alive:GetChildren()
            if _lastAliveCount == 0 and count > 0 then
                task.defer(esp_reset_all_cooldowns)
            end
            _lastAliveCount = count
        end)
    end
    if not ESP_AliveRemovedConn then
        ESP_AliveRemovedConn = workspace.Alive.ChildRemoved:Connect(function()
            if not getgenv().AbilityESP then return end
            local count = #workspace.Alive:GetChildren()
            if count == 0 then
                task.defer(esp_reset_all_cooldowns)
            end
            _lastAliveCount = count
        end)
    end

    if not ESP_HeartbeatConn then
        ESP_HeartbeatConn = RunService.Heartbeat:Connect(function()
            if not getgenv().AbilityESP then return end
            local now = tick()
            if now - _esp_last_update < 0.1 then return end
            _esp_last_update = now
            for player, data in pairs(ESP_Data) do
                if not (player and player.Parent) then
                    pcall(function() data.bill:Destroy() end)
                    if data.cdConn then pcall(function() data.cdConn:Disconnect() end) end
                    ESP_Data[player] = nil
                    ESP_Cooldowns[player] = nil
                    continue
                end

                local ab = player:GetAttribute('CurrentlyEquippedAbility') or player:GetAttribute('EquippedAbility') or ''
                local displayText = ab ~= '' and ab or player.DisplayName
                if data.label.Text ~= displayText then
                    data.label.Text = displayText
                    data.icon.Image = esp_get_icon(ab)
                    local ok2, dur2 = pcall(_Abilities.getAbilityCooldown, player, ab)
                    data.isPassive = ok2 and type(dur2) == 'number' and dur2 <= 0
                    ESP_Cooldowns[player] = nil
                end

                local cd = ESP_Cooldowns[player]
                if cd and now < cd.expiry then
                    local remaining = cd.expiry - now
                    data.timerLabel.Text = string.format('%.1fs', remaining)
                    data.timerLabel.TextColor3 = Color3.fromRGB(255, 120, 50)
                else
                    if cd then ESP_Cooldowns[player] = nil end
                    if data.isPassive then
                        data.timerLabel.Text = 'Passive'
                        data.timerLabel.TextColor3 = Color3.fromRGB(160, 160, 180)
                    else
                        data.timerLabel.Text = 'Ready'
                        data.timerLabel.TextColor3 = Color3.fromRGB(100, 220, 100)
                    end
                end
            end
        end)
    end

    for _, player in pairs(Players:GetPlayers()) do
        add_esp_player(player)
    end
    if not ESP_PlayerAddedConn then
        ESP_PlayerAddedConn = Players.PlayerAdded:Connect(function(player)
            if getgenv().AbilityESP then add_esp_player(player) end
        end)
    end

end

local function stop_ability_esp()
    getgenv().AbilityESP = false
    if ESP_HeartbeatConn then
        ESP_HeartbeatConn:Disconnect()
        ESP_HeartbeatConn = nil
    end
    if ESP_PlayerAddedConn then
        pcall(function() ESP_PlayerAddedConn:Disconnect() end)
        ESP_PlayerAddedConn = nil
    end
    if ESP_AliveAddedConn then
        pcall(function() ESP_AliveAddedConn:Disconnect() end)
        ESP_AliveAddedConn = nil
    end
    if ESP_AliveRemovedConn then
        pcall(function() ESP_AliveRemovedConn:Disconnect() end)
        ESP_AliveRemovedConn = nil
    end
    for _, conns in pairs(ESP_CharConns) do
        for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
    end
    table.clear(ESP_CharConns)
    for _, data in pairs(ESP_Data) do
        pcall(function() data.bill:Destroy() end)
        if data.cdConn then pcall(function() data.cdConn:Disconnect() end) end
    end
    ESP_Data = {}
    ESP_Cooldowns = {}
    table.clear(ESP_IconCache)
end

getgenv()._Zuro_ESP_Stop = stop_ability_esp

Visual:create_module({
    title = 'Ability ESP',
    flag = 'Ability_ESP',
    description = 'Show player abilities and cooldown',
    section = 'right',
    callback = function(state)
        if state then
            start_ability_esp()
        else
            stop_ability_esp()
        end
    end,
})
end

local start_force_stats
local stop_force_stats

do
	local Force_Stats_Conn2 = nil
	local Force_Stats_LbConns = {}
	local Force_Stats_Cache = {}

	local function _find_player_by_userid(userid)
		for _, player in ipairs(Players:GetPlayers()) do
			if player.UserId == userid then return player end
		end
	end

	local function _fmt(n)
		if type(n) ~= 'number' then return tostring(n) end
		local s = tostring(math.floor(n))
		return s:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
	end

	local Force_Stats_WatchConns = {}

	local function _apply_patch(entry, wins_lbl, elims_lbl, player)
		local wins = player:GetAttribute("PlayerWins")
		local elims = player:GetAttribute("PlayerElims")
		if wins_lbl and wins then wins_lbl.Text = _fmt(wins) end
		if elims_lbl and elims then elims_lbl.Text = _fmt(elims) end
	end

	local function _patch_playerlist_entry(entry)
		local userid = tonumber(entry.Name:match("PlayerEntry_(%d+)"))
		if not userid then return end
		local player = _find_player_by_userid(userid)
		if not player then return end
		local overlay = entry:FindFirstChild("PlayerEntryContentFrame")
		overlay = overlay and overlay:FindFirstChild("OverlayFrame")
		if not overlay then return end
		local wins_lbl = overlay:FindFirstChild("GameStat_Wins") and overlay.GameStat_Wins:FindFirstChild("PlayerStatDisplay")
		local elims_lbl = overlay:FindFirstChild("GameStat_Elims") and overlay.GameStat_Elims:FindFirstChild("PlayerStatDisplay")

		if not Force_Stats_Cache[entry] then Force_Stats_Cache[entry] = {} end
		if wins_lbl and not Force_Stats_Cache[entry].wins then
			Force_Stats_Cache[entry].wins = wins_lbl.Text
		end
		if elims_lbl and not Force_Stats_Cache[entry].elims then
			Force_Stats_Cache[entry].elims = elims_lbl.Text
		end

		_apply_patch(entry, wins_lbl, elims_lbl, player)

		if Force_Stats_WatchConns[entry] then return end
		local conns = {}
		Force_Stats_WatchConns[entry] = conns
		local guarding = false
		local function reapply()
			if guarding then return end
			guarding = true
			task.defer(function()
				guarding = false
				if not Force_Stats_WatchConns[entry] then return end
				local ov2 = entry:FindFirstChild("PlayerEntryContentFrame")
				ov2 = ov2 and ov2:FindFirstChild("OverlayFrame")
				if not ov2 then return end
				local w2 = ov2:FindFirstChild("GameStat_Wins") and ov2.GameStat_Wins:FindFirstChild("PlayerStatDisplay")
				local e2 = ov2:FindFirstChild("GameStat_Elims") and ov2.GameStat_Elims:FindFirstChild("PlayerStatDisplay")
				_apply_patch(entry, w2, e2, player)
			end)
		end
		if wins_lbl then
			table.insert(conns, wins_lbl:GetPropertyChangedSignal("Text"):Connect(reapply))
		end
		if elims_lbl then
			table.insert(conns, elims_lbl:GetPropertyChangedSignal("Text"):Connect(reapply))
		end
		table.insert(conns, player:GetAttributeChangedSignal("PlayerWins"):Connect(reapply))
		table.insert(conns, player:GetAttributeChangedSignal("PlayerElims"):Connect(reapply))
	end

	local function _restore_playerlist_entry(entry)
		if Force_Stats_WatchConns[entry] then
			for _, c in ipairs(Force_Stats_WatchConns[entry]) do pcall(function() c:Disconnect() end) end
			Force_Stats_WatchConns[entry] = nil
		end
		local cache = Force_Stats_Cache[entry]
		if not cache then return end
		local overlay = entry:FindFirstChild("PlayerEntryContentFrame")
		overlay = overlay and overlay:FindFirstChild("OverlayFrame")
		if not overlay then return end
		local wins_lbl = overlay:FindFirstChild("GameStat_Wins") and overlay.GameStat_Wins:FindFirstChild("PlayerStatDisplay")
		local elims_lbl = overlay:FindFirstChild("GameStat_Elims") and overlay.GameStat_Elims:FindFirstChild("PlayerStatDisplay")
		if wins_lbl and cache.wins then wins_lbl.Text = cache.wins end
		if elims_lbl and cache.elims then elims_lbl.Text = cache.elims end
		Force_Stats_Cache[entry] = nil
	end

	local function _patch_all_playerlist_entries(teamlist)
		for _, entry in ipairs(teamlist:GetChildren()) do
			if entry.Name:find("PlayerEntry_") then
				_patch_playerlist_entry(entry)
			end
		end
	end

	local function _restore_all_playerlist_entries(teamlist)
		for _, entry in ipairs(teamlist:GetChildren()) do
			if entry.Name:find("PlayerEntry_") then
				_restore_playerlist_entry(entry)
			end
		end
	end

	local Force_Stats_TeamLists = {}

	local function _patch_entry_when_ready(entry)
		task.spawn(function()
			local deadline = tick() + 5
			while tick() < deadline do
				local overlay = entry:FindFirstChild("PlayerEntryContentFrame")
				overlay = overlay and overlay:FindFirstChild("OverlayFrame")
				if overlay then
					_patch_playerlist_entry(entry)
					return
				end
				task.wait(0.1)
			end
		end)
	end

	local function _hook_teamlist(teamlist)
		table.insert(Force_Stats_TeamLists, teamlist)
		_patch_all_playerlist_entries(teamlist)
		local conn = teamlist.ChildAdded:Connect(function(entry)
			if entry.Name:find("PlayerEntry_") then
				_patch_entry_when_ready(entry)
			end
		end)
		table.insert(Force_Stats_LbConns, conn)
	end

	local function _patch_duelframes_row(row)
		local userid = tonumber(row.Name)
		if not userid then return end
		local player = _find_player_by_userid(userid)
		if not player then return end
		local stats = row:FindFirstChild("Stats")
		if not stats then return end
		if not Force_Stats_Cache[row] then Force_Stats_Cache[row] = {} end
		for _, data in ipairs({ {"Wins", "PlayerWins", "wins"}, {"Kills", "PlayerElims", "elims"} }) do
			local s = stats:FindFirstChild(data[1])
			local lbl = s and s:FindFirstChild("Frame") and s.Frame:FindFirstChild("TextLabel")
			if lbl then
				Force_Stats_Cache[row][data[3]] = Force_Stats_Cache[row][data[3]] or lbl.Text
				local val = player:GetAttribute(data[2])
				if val then lbl.Text = _fmt(val) end
			end
		end
	end

	local function _restore_duelframes_row(row)
		local cache = Force_Stats_Cache[row]
		if not cache then return end
		local stats = row:FindFirstChild("Stats")
		if not stats then return end
		for _, data in ipairs({ {"Wins", "wins"}, {"Kills", "elims"} }) do
			local s = stats:FindFirstChild(data[1])
			local lbl = s and s:FindFirstChild("Frame") and s.Frame:FindFirstChild("TextLabel")
			if lbl and cache[data[2]] then lbl.Text = cache[data[2]] end
		end
		Force_Stats_Cache[row] = nil
	end

	local Force_Stats_DuelSF = nil

	local function _patch_all_duelframes_rows(sf)
		Force_Stats_DuelSF = sf
		for _, row in ipairs(sf:GetChildren()) do
			_patch_duelframes_row(row)
		end
	end

	start_force_stats = function()
		local pg = Players.LocalPlayer:WaitForChild("PlayerGui")

		local df = pg:WaitForChild("DuelFrames", 10)
		if df then
			local sf = df:FindFirstChild("Playerlist") and df.Playerlist:FindFirstChild("ScrollingFrame")
			if sf then
				if Force_Stats_Conn2 then Force_Stats_Conn2:Disconnect() end
				_patch_all_duelframes_rows(sf)
				Force_Stats_Conn2 = sf.ChildAdded:Connect(function(row)
					task.defer(_patch_duelframes_row, row)
				end)
			end
		end

		local conn_join = Players.PlayerAdded:Connect(function(player)
			task.spawn(function()
				local entryName = "PlayerEntry_" .. player.UserId
				local deadline = tick() + 8
				while tick() < deadline do
					for _, teamlist in ipairs(Force_Stats_TeamLists) do
						local entry = teamlist:FindFirstChild(entryName)
						if entry then
							_patch_entry_when_ready(entry)
							return
						end
					end
					task.wait(0.2)
				end
			end)
		end)
		table.insert(Force_Stats_LbConns, conn_join)

		task.spawn(function()
			local cg = game:GetService("CoreGui")
			local pl = cg:WaitForChild("PlayerList", 10)
			if not pl then return end
			local ok, scroll = pcall(function()
				return pl.Children.OffsetFrame.PlayerScrollList.SizeOffsetFrame.ScrollingFrameContainer.ScrollingFrameClippingFrame.ScrollingFrame
			end)
			if not ok or not scroll then return end
			local function hook_offsetframe(offsetframe)
				for _, teamlist in ipairs(offsetframe:GetChildren()) do
					if teamlist.Name:find("TeamList_") then
						_hook_teamlist(teamlist)
					end
				end
				local conn = offsetframe.ChildAdded:Connect(function(teamlist)
					if teamlist.Name:find("TeamList_") then
						_hook_teamlist(teamlist)
					end
				end)
				table.insert(Force_Stats_LbConns, conn)
			end
			scroll.ChildAdded:Connect(function(child)
				if child.Name == "OffsetUndoFrame" then
					task.defer(hook_offsetframe, child)
				end
			end)
			local existing = scroll:FindFirstChild("OffsetUndoFrame")
			if existing then hook_offsetframe(existing) end
		end)
	end

	stop_force_stats = function()
		if Force_Stats_Conn2 then Force_Stats_Conn2:Disconnect(); Force_Stats_Conn2 = nil end
		for _, conn in ipairs(Force_Stats_LbConns) do pcall(function() conn:Disconnect() end) end
		table.clear(Force_Stats_LbConns)
		for _, teamlist in ipairs(Force_Stats_TeamLists) do
			pcall(function() _restore_all_playerlist_entries(teamlist) end)
		end
		table.clear(Force_Stats_TeamLists)
		if Force_Stats_DuelSF then
			for _, row in ipairs(Force_Stats_DuelSF:GetChildren()) do
				pcall(function() _restore_duelframes_row(row) end)
			end
			Force_Stats_DuelSF = nil
		end
		for _, conns in pairs(Force_Stats_WatchConns) do
			for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
		end
		table.clear(Force_Stats_WatchConns)
		table.clear(Force_Stats_Cache)
	end

	Visual:create_module({
		title = 'Force Show Stats',
		flag = 'Force_Show_Stats',
		description = 'Force show players statistic',
		section = 'right',
		callback = function(state)
			if state then
				start_force_stats()
			else
				stop_force_stats()
			end
		end,
	})
end

local function cleanup_visual_stats()
    destroy_performance_overlay()
    destroy_ball_stats()
    pcall(function()
        if getgenv()._Zuro_PlayerPanel_Stop then getgenv()._Zuro_PlayerPanel_Stop() end
    end)
end

do
    local PlayerPanelState = {
        gui = nil,
        conn = nil,
        drag = nil,
        release = nil,
    }

    local function destroy_player_panel()
        if PlayerPanelState.conn then
            PlayerPanelState.conn:Disconnect()
            PlayerPanelState.conn = nil
        end
        if PlayerPanelState.drag then
            PlayerPanelState.drag:Disconnect()
            PlayerPanelState.drag = nil
        end
        if PlayerPanelState.release then
            PlayerPanelState.release:Disconnect()
            PlayerPanelState.release = nil
        end
        if PlayerPanelState.gui then
            pcall(function() PlayerPanelState.gui:Destroy() end)
            PlayerPanelState.gui = nil
        end
    end

    local function create_player_panel()
        if PlayerPanelState.gui then return end

        local Gui = Instance.new('ScreenGui')
        Gui.Name = 'ZuroPlayerPanel'
        Gui.ResetOnSpawn = false
        Gui.IgnoreGuiInset = true
        Gui.DisplayOrder = 99
        Gui.Parent = CoreGui

        local Shadow = Instance.new('ImageLabel')
        Shadow.Size = UDim2.fromOffset(178, 122)
        Shadow.Position = UDim2.new(1, -216, 0, 38)
        Shadow.BackgroundTransparency = 1
        Shadow.BorderSizePixel = 0
        Shadow.Image = 'rbxassetid://6014261993'
        Shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
        Shadow.ImageTransparency = 0.38
        Shadow.ScaleType = Enum.ScaleType.Slice
        Shadow.SliceCenter = Rect.new(49, 49, 450, 450)
        Shadow.ZIndex = 0
        Shadow.Parent = Gui

        local Panel = Instance.new('Frame')
        Panel.Name = 'PlayerPanel'
        Panel.Size = UDim2.fromOffset(150, 0)
        Panel.AutomaticSize = Enum.AutomaticSize.Y
        Panel.Position = UDim2.new(1, -202, 0, 52)
        Panel.BackgroundColor3 = Color3.fromRGB(10, 10, 12)
        Panel.BorderSizePixel = 0
        Panel.Active = true
        Panel.ZIndex = 40
        Panel.Parent = Gui

        local PanelCorner = Instance.new('UICorner')
        PanelCorner.CornerRadius = UDim.new(0, 7)
        PanelCorner.Parent = Panel

        local PanelStroke = Instance.new('UIStroke')
        PanelStroke.Color = Color3.fromRGB(255, 255, 255)
        PanelStroke.Transparency = 0.88
        PanelStroke.Thickness = 1
        PanelStroke.Parent = Panel

        local PanelGradient = Instance.new('UIGradient')
        PanelGradient.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.fromRGB(145, 145, 145)),
            ColorSequenceKeypoint.new(0.3, Color3.fromRGB(14, 14, 16)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0))
        }
        PanelGradient.Rotation = 90
        PanelGradient.Parent = Panel

        local Layout = Instance.new('UIListLayout')
        Layout.SortOrder = Enum.SortOrder.LayoutOrder
        Layout.Padding = UDim.new(0, 0)
        Layout.Parent = Panel

        local Pad = Instance.new('UIPadding')
        Pad.PaddingTop = UDim.new(0, 6)
        Pad.PaddingBottom = UDim.new(0, 6)
        Pad.PaddingLeft = UDim.new(0, 10)
        Pad.PaddingRight = UDim.new(0, 10)
        Pad.Parent = Panel

        local function make_row(title, value, order, color)
            local Row = Instance.new('Frame')
            Row.Name = title
            Row.Size = UDim2.new(1, 0, 0, 16)
            Row.AutomaticSize = Enum.AutomaticSize.Y
            Row.BackgroundTransparency = 1
            Row.BorderSizePixel = 0
            Row.LayoutOrder = order
            Row.Parent = Panel

            local TitleLabel = Instance.new('TextLabel')
            TitleLabel.Size = UDim2.new(0.5, 0, 1, 0)
            TitleLabel.BackgroundTransparency = 1
            TitleLabel.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
            TitleLabel.TextColor3 = Color3.fromRGB(160, 160, 168)
            TitleLabel.TextSize = 10
            TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
            TitleLabel.Text = title
            TitleLabel.ZIndex = 41
            TitleLabel.Parent = Row

            local ValueLabel = Instance.new('TextLabel')
            ValueLabel.Name = 'Value'
            ValueLabel.Size = UDim2.new(0.5, 0, 1, 0)
            ValueLabel.Position = UDim2.new(0.5, 0, 0, 0)
            ValueLabel.BackgroundTransparency = 1
            ValueLabel.FontFace = Font.new('rbxasset://fonts/families/SFPro.json', Enum.FontWeight.Bold, Enum.FontStyle.Normal)
            ValueLabel.TextColor3 = color or Color3.fromRGB(238, 238, 242)
            ValueLabel.TextSize = 10
            ValueLabel.TextXAlignment = Enum.TextXAlignment.Right
            ValueLabel.Text = value
            ValueLabel.ZIndex = 41
            ValueLabel.Parent = Row

            return ValueLabel
        end

        local vWins    = make_row('Wins',     '0',   1)
        local vKills   = make_row('Kills',    '0',   2)
        local vParries = make_row('Parries',  '0',   3)
        local vAlive   = make_row('Alive',    '0',   4)
        local vStatus  = make_row('Status',   '--',   5, Color3.fromRGB(100, 220, 100))
        local vTarget  = make_row('Target',   '--',   6)
        local vDist    = make_row('Distance', '--',   7, Color3.fromRGB(180, 180, 255))

        local dragging = false
        local dragStart = nil
        local startPos = nil

        Panel.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                dragStart = input.Position
                startPos = Panel.Position
            end
        end)

        Panel:GetPropertyChangedSignal('AbsoluteSize'):Connect(function()
            Shadow.Size = UDim2.fromOffset(Panel.AbsoluteSize.X + 28, Panel.AbsoluteSize.Y + 28)
        end)

        PlayerPanelState.drag = UserInputService.InputChanged:Connect(function(input)
            if not dragging then return end
            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                local delta = input.Position - dragStart
                Panel.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
                Shadow.Position = UDim2.new(Panel.Position.X.Scale, Panel.Position.X.Offset - 14, Panel.Position.Y.Scale, Panel.Position.Y.Offset - 14)
            end
        end)

        PlayerPanelState.release = UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end)

        local _last_update = 0
        PlayerPanelState.conn = RunService.Heartbeat:Connect(function()
            local now = tick()
            if now - _last_update < 0.2 then return end
            _last_update = now

            vWins.Text    = tostring(Player:GetAttribute('PlayerWins') or 0)
            vKills.Text   = tostring(Player:GetAttribute('PlayerElims') or 0)
            vParries.Text = tostring(Parries)
            vAlive.Text   = tostring(#workspace.Alive:GetChildren())

            local char = Player.Character
            local hum = char and char:FindFirstChildOfClass('Humanoid')
            local alive = hum and hum.Health > 0
            if alive then
                vStatus.Text = 'Alive'
                vStatus.TextColor3 = Color3.fromRGB(100, 220, 100)
            else
                vStatus.Text = 'Dead'
                vStatus.TextColor3 = Color3.fromRGB(220, 80, 80)
            end

            if Selected_Target and Selected_Target.PrimaryPart then
                vTarget.Text = Selected_Target.Name
                local dist = math.floor(Player:DistanceFromCharacter(Selected_Target.PrimaryPart.Position))
                vDist.Text = dist .. ' st'
            else
                vTarget.Text = '--'
                vDist.Text = '--'
            end
        end)

        PlayerPanelState.gui = Gui
    end

    Visual:create_module({
        title = 'Player Panel',
        flag = 'Player_Panel',
        description = 'Stats, status and target distance',
        section = 'left',
        callback = function(state)
            if state then
                create_player_panel()
            else
                destroy_player_panel()
            end
        end,
    })

    getgenv()._Zuro_PlayerPanel_Stop = destroy_player_panel
end

local Auto_Spam = {
	Enabled = false,
	Threshold = 1,
	Distance_Multiplier = .3,
	Interval = 0.01,
	Last_Fire = 0,
	In_Close_Contact = false,
	Last_Close_Contact = 0,
};
function Auto_Spam.Get_Entity_Properties()
	Auto_Parry.Closest_Player();
	if not Closest_Entity or not Closest_Entity.PrimaryPart then
		return false;
	end;
	if not Player.Character or not Player.Character.PrimaryPart then
		return false;
	end;
	local Entity_Offset = Player.Character.PrimaryPart.Position - Closest_Entity.PrimaryPart.Position;
	return {
		Velocity = Closest_Entity.PrimaryPart.Velocity,
		Direction = Entity_Offset.Magnitude > 0 and Entity_Offset.Unit or Vector3.zero,
		Distance = Entity_Offset.Magnitude,
	};
end;
function Auto_Spam.Get_Ball_Properties()
	local Ball = Auto_Parry.Get_Ball();
	if not Ball then
		return false;
	end;
	if not Player.Character or not Player.Character.PrimaryPart then
		return false;
	end;
	local Ball_Velocity = Ball.AssemblyLinearVelocity or Vector3.zero;
	local Ball_Offset = Player.Character.PrimaryPart.Position - Ball.Position;
	local Ball_Distance = Ball_Offset.Magnitude;
	local Ball_Direction = Vector3.zero;
	local Ball_Dot = 0;
	if Ball_Distance > 0 then
		Ball_Direction = Ball_Offset.Unit;
		if Ball_Velocity.Magnitude > 0 then
			Ball_Dot = Ball_Direction:Dot(Ball_Velocity.Unit);
		end;
	end;
	return {
		Velocity = Ball_Velocity,
		Direction = Ball_Direction,
		Distance = Ball_Distance,
		Dot = Ball_Dot,
	};
end;
function Auto_Spam.Spam_Service(self)
	local Ball = Auto_Parry.Get_Ball();
	local Entity = Auto_Parry.Closest_Player();
	if not Ball or not Entity or not Entity.PrimaryPart then
		return false;
	end;
	if not Player.Character or not Player.Character.PrimaryPart then
		return false;
	end;

	local D = 5;
	local Velocity = Ball.AssemblyLinearVelocity or Vector3.zero;
	local Speed = Velocity.Magnitude;
	if Speed == 0 then
		return D;
	end;

	local To_Ball = Player.Character.PrimaryPart.Position - Ball.Position;
	if To_Ball.Magnitude == 0 then
		return D;
	end;

	local Ball_Dot = To_Ball.Unit:Dot(Velocity.Unit);
	local Target_Position = Entity.PrimaryPart.Position;
	local Target_Distance = Player:DistanceFromCharacter(Target_Position);
	local Retreat_Factor = 1;
	local Move_Direction = Vector3.zero;
	local Humanoid = Player.Character:FindFirstChildOfClass("Humanoid");
	if Humanoid then
		Move_Direction = Humanoid.MoveDirection;
	end;

	local Target_Offset = Target_Position - Player.Character.PrimaryPart.Position;
	local Target_Direction = Target_Offset.Magnitude > 0 and Target_Offset.Unit or Vector3.zero;
	local Entity_Move_Direction = Vector3.zero;
	local Entity_Humanoid = Entity:FindFirstChildOfClass("Humanoid");
	if Entity_Humanoid then
		Entity_Move_Direction = Entity_Humanoid.MoveDirection;
	end;

	local Now = tick();
	if Target_Distance <= 3 then
		Auto_Spam.In_Close_Contact = true;
	end;
	if Auto_Spam.In_Close_Contact and Target_Distance > 3.3 then
		Auto_Spam.In_Close_Contact = false;
		Auto_Spam.Last_Close_Contact = Now;
	end;
	local Separated = not Auto_Spam.In_Close_Contact and Now - Auto_Spam.Last_Close_Contact >= 1.5;
	if Separated and Move_Direction.Magnitude > .2 and Move_Direction:Dot(Target_Direction) < -.4 then
		Retreat_Factor = 10;
	end;
	if Separated and Entity_Move_Direction.Magnitude > .2 and Entity_Move_Direction:Dot(-Target_Direction) < -.4 then
		Retreat_Factor = 10;
	end;

	local Maximum_Spam_Distance = ((self.Ping or 50) * .7 + math.min(Speed / (Retreat_Factor * 1.2), 80)) * Auto_Spam.Distance_Multiplier;
	if (self.Entity_Properties and self.Entity_Properties.Distance or math.huge) > Maximum_Spam_Distance then
		return D;
	end;
	if (self.Ball_Properties and self.Ball_Properties.Distance or math.huge) > Maximum_Spam_Distance then
		return D;
	end;
	if Target_Distance > Maximum_Spam_Distance then
		return D;
	end;

	local Approach = math.clamp(-Ball_Dot, 0, 1);
	local Dot_Penalty = math.clamp(Approach * (Speed / 40), 0, 4);
	return Maximum_Spam_Distance - Dot_Penalty;
end;
function Auto_Spam.Fire()
	if not _parry_hooked() then
		return false;
	end;
	return _send_parry(Resolve_Parry_Type());
end;
function Auto_Spam.Start()
	if Connections_Manager["Auto Spam"] then
		Connections_Manager["Auto Spam"]:Disconnect();
		Connections_Manager["Auto Spam"] = nil;
	end;
	Connections_Manager["Auto Spam"] = RunService.PreSimulation:Connect(function()
		if not Auto_Spam.Enabled then
			return;
		end;
		if not Player.Character or not Player.Character.PrimaryPart then
			return;
		end;
		local Ball = Auto_Parry.Get_Ball();
		if not Ball then
			return;
		end;
		if Ball:FindFirstChild("ComboCounter") then
			return;
		end;
		local Zoomies = Ball:FindFirstChild("zoomies");
		if not Zoomies then
			return;
		end;
		if Zoomies.VectorVelocity.Magnitude == 0 then
			return;
		end;
		local Ball_Target = Ball:GetAttribute("target");
		if not Ball_Target then
			return;
		end;
		Auto_Parry.Closest_Player();
		if not Closest_Entity or not Closest_Entity.PrimaryPart then
			return;
		end;
		local Ball_Properties = Auto_Spam.Get_Ball_Properties();
		local Entity_Properties = Auto_Spam.Get_Entity_Properties();
		if not Ball_Properties or not Entity_Properties then
			return;
		end;
		local Ping_Threshold = math.clamp(Auto_Parry.Get_Ping() / 10, 1, 16);
		local Spam_Accuracy = Auto_Spam.Spam_Service({
			Ball_Properties = Ball_Properties,
			Entity_Properties = Entity_Properties,
			Ping = Ping_Threshold,
		});
		if not Spam_Accuracy then
			return;
		end;
		local Target_Distance = Player:DistanceFromCharacter(Closest_Entity.PrimaryPart.Position);
		local Distance = Player:DistanceFromCharacter(Ball.Position);
		if Target_Distance > Spam_Accuracy or Distance > Spam_Accuracy then
			return;
		end;
		if Player.Character:GetAttribute("Pulsed") then
			return;
		end;
		if Ball_Target == tostring(Player) and Target_Distance > 30 and Distance > 30 then
			return;
		end;
		if Det.Infinity_Enabled and Det.Infinity_Active then
			return;
		end;
		if Det.DeathSlash_Enabled and Det.DeathSlash_Active then
			return;
		end;
		if Det.TimeHole_Enabled and Det.TimeHole_Active then
			return;
		end;
		if Det.Pull_Enabled and Det.Pull_Active then
			return;
		end;
		if Det.Singularity_Enabled and Player.Character and Player.Character.PrimaryPart and Player.Character.PrimaryPart:FindFirstChild('SingularityCape') then
			return;
		end;
		if Det.Slashes_Enabled and Det.Slashes_Active then
			return;
		end;
		if Det.Forcefield_Enabled and Det.Forcefield_Active then
			return;
		end;
		if Parries > Auto_Spam.Threshold then
			local now = os.clock();
			if (now - Auto_Spam.Last_Fire) < Auto_Spam.Interval then
				return;
			end;
			Auto_Spam.Last_Fire = now;
			if (getgenv()).AutoSpamAnimationFix then
				Auto_Parry.Parry_Animation();
			end;
			Auto_Spam.Fire();
		end;
	end);
end;
function Auto_Spam.Stop()
	if Connections_Manager["Auto Spam"] then
		Connections_Manager["Auto Spam"]:Disconnect();
		Connections_Manager["Auto Spam"] = nil;
	end;
end;

local Manual_Spam = {
	Enabled = false,
	Active = false,
	Mobile_Gate = false,
	Target_CPS = 100,
	Fired = 0,
	Live_CPS = 0,
	Token = 0,
	Mobile_Overlay_On = false,
	Cps_Counter_On = false,
};
function Manual_Spam.Start()
	Manual_Spam.Token += 1;
	local Current_Token = Manual_Spam.Token;
	task.spawn(function()
		local Accumulator = 0;
		local conn;
		conn = RunService.Heartbeat:Connect(function(dt)
			if Manual_Spam.Token ~= Current_Token then
				conn:Disconnect();
				return;
			end;
			local Running = (Manual_Spam.Mobile_Gate and Manual_Spam.Active) or (not Manual_Spam.Mobile_Gate and Manual_Spam.Enabled);
			if not Running then
				conn:Disconnect();
				return;
			end;
			Accumulator = Accumulator + Manual_Spam.Target_CPS * dt;
			local Fires = math.floor(Accumulator);
			if Fires > 0 then
				Accumulator = Accumulator - Fires;
				for _ = 1, Fires do
					Auto_Spam.Fire();
					Manual_Spam.Fired += 1;
				end;
				if (getgenv()).ManualSpamAnimationFix then
					Auto_Parry.Parry_Animation();
				end;
			end;
		end);
	end);
end;
function Manual_Spam.Stop()
	Manual_Spam.Token += 1;
end;

local module = Blatant:create_module({
		title = "Auto Parry",
		flag = "Auto_Parry",
		description = "Automatically Parry the Ball",
		section = "left",
		callback = function(value)
			local previousAutoParryState = AutoParryEnabled
			AutoParryEnabled = value
			if previousAutoParryState ~= nil and previousAutoParryState ~= value and (getgenv()).AutoParryNotify then
				if value then
					Library.SendNotification({ title = "Auto Parry Enabled", text = "Enabled", duration = 3 });
				else
					Library.SendNotification({ title = "Auto Parry Disabled", text = "Disabled", duration = 3 });
				end;
			end;
			if value then
				if Connections_Manager["Auto Parry"] then
					Connections_Manager["Auto Parry"]:Disconnect();
					Connections_Manager["Auto Parry"] = nil;
				end;
				Connections_Manager["Auto Parry"] = RunService.PreSimulation:Connect(function()
					if not AutoParryEnabled then
						return;
					end;
						local One_Ball = Auto_Parry.Get_Ball();
						local Balls = Auto_Parry.Get_Balls();
						for _, Ball in pairs(Balls) do
							if not Ball then
								return;
							end;
							local Zoomies = Ball:FindFirstChild("zoomies");
							if not Zoomies then
								return;
							end;
							(Ball:GetAttributeChangedSignal("target")):Once(function()
								Parried = false;
							end);
							if Parried then
								return;
							end;
							local Ball_Target = Ball:GetAttribute("target");
							local One_Target = One_Ball:GetAttribute("target");
							local Velocity = Zoomies.VectorVelocity;
							local Speed = Velocity.Magnitude;
							local avgPing = (getgenv())._ZX_Tune and (getgenv())._ZX_Tune.GetAveragePing() or 0;
							local pingSec = avgPing / 2000;
							local pingStuds = avgPing / 10;
							local playerPos = Player.Character.PrimaryPart.Position;
							local ballPos = Ball.Position;
							local playerVel = Player.Character.PrimaryPart.AssemblyLinearVelocity;
							_ZX_pushVelSample("ball", ballPos, Velocity);
							_ZX_pushVelSample("player", playerPos, playerVel);
							local Ball_Future_Position = _ZX_predictFuturePosition("ball", pingSec);
							local Player_Future_Position = _ZX_predictFuturePosition("player", pingSec);
							if not Ball_Future_Position then
								Ball_Future_Position = ballPos + Velocity * pingSec;
							end;
							if not Player_Future_Position then
								Player_Future_Position = playerPos + playerVel * pingSec;
							end;
							local Distance = (Player_Future_Position - Ball_Future_Position).Magnitude;
							local Ping_Threshold = math.clamp(pingStuds / 8, 4, 25);
							local speed_divisor_base = _ZX_calcSpeedDivisorBase(Speed);
							local effectiveMultiplier = Speed_Divisor_Multiplier;
							if (getgenv()).RandomParryAccuracyEnabled then
								local hMin = (getgenv()).HumanizerMin or 1;
								local hMax = (getgenv()).HumanizerMax or 100;
								local lo = math.min(hMin, hMax);
								local hi = math.max(hMin, hMax);
								if Speed < 200 then lo = math.max(lo, 40) end;
								if lo > hi then lo = hi end;
								effectiveMultiplier = .7 + (math.random(lo, hi) - 1) * .0035353535353535;
							end;
							local speed_divisor = speed_divisor_base * effectiveMultiplier;
							local speedFactor = 1;
							if Speed > 200 then
								speedFactor = 1 + math.min((Speed - 200) / 1000, .3);
							end;
							local Parry_Accuracy = Ping_Threshold + math.max(Speed / speed_divisor, 9.5) * speedFactor;
							local Curved = Auto_Parry.Is_Curved();
							if Ball:FindFirstChild("AeroDynamicSlashVFX") then
								Debris:AddItem(Ball.AeroDynamicSlashVFX, 0);
								Tornado_Time = tick();
							end;
							if Runtime:FindFirstChild("Tornado") then
								if tick() - Tornado_Time < (Runtime.Tornado:GetAttribute("TornadoTime") or 1) + .314159 then
									return;
								end;
							end;
							if One_Target == tostring(Player) and Curved then
								return;
							end;
							if Ball:FindFirstChild("ComboCounter") then
								return;
							end;
							if Det.Infinity_Enabled and Det.Infinity_Active then
								return;
							end;
							if Det.DeathSlash_Enabled and Det.DeathSlash_Active then
								return;
							end;
							if Det.TimeHole_Enabled and Det.TimeHole_Active then
								return;
							end;
							if Det.Pull_Enabled and Det.Pull_Active then
								return;
							end;
							if Det.Singularity_Enabled and Player.Character and Player.Character.PrimaryPart and Player.Character.PrimaryPart:FindFirstChild('SingularityCape') then
								return;
							end;
							if Det.Slashes_Enabled and Det.Slashes_Active then
								return;
							end;
							if Det.Forcefield_Enabled and Det.Forcefield_Active then
								return;
							end;
							if Ball_Target == tostring(Player) and Distance <= Parry_Accuracy then
								if (getgenv()).CooldownProtection and cooldownProtection() then
									return;
								end;
								if getgenv().AutoAbility then
									local AbilityCD = Player.PlayerGui.Hotbar.Ability.UIGradient
									if AbilityCD and AbilityCD.Offset.Y == 0.5 then
										if Player.Character and Player.Character:FindFirstChild('Abilities') and (
											(Player.Character.Abilities:FindFirstChild('Raging Deflection') and Player.Character.Abilities['Raging Deflection'].Enabled) or
											(Player.Character.Abilities:FindFirstChild('Rapture') and Player.Character.Abilities['Rapture'].Enabled) or
											(Player.Character.Abilities:FindFirstChild('Calming Deflection') and Player.Character.Abilities['Calming Deflection'].Enabled) or
											(Player.Character.Abilities:FindFirstChild('Aerodynamic Slash') and Player.Character.Abilities['Aerodynamic Slash'].Enabled) or
											(Player.Character.Abilities:FindFirstChild('Fracture') and Player.Character.Abilities['Fracture'].Enabled) or
											(Player.Character.Abilities:FindFirstChild('Death Slash') and Player.Character.Abilities['Death Slash'].Enabled)
										) then
											Parried = true;
											ReplicatedStorage.Remotes.AbilityButtonPress:Fire();
											task.wait(2.432);
											pcall(function()
												ReplicatedStorage:WaitForChild('Remotes'):WaitForChild('DeathSlashShootActivation'):FireServer(true);
											end);
											return;
										end;
									end;
								end;
								local Parry_Time = os.clock();
								local Time_View = Parry_Time - Last_Parry;
								if Time_View > .5 then
									Auto_Parry.Parry_Animation();
								end;
								if AutoParryEnabled then
									Auto_Parry.Parry(Resolve_Parry_Type());
								end;
								Last_Parry = Parry_Time;
								Parried = true;
							end;
							local Last_Parrys = tick();
							repeat
								RunService.PreSimulation:Wait();
							until tick() - Last_Parrys >= 1 or not Parried;
							Parried = false;
						end;
					end);
			else
				if Connections_Manager["Auto Parry"] then
					Connections_Manager["Auto Parry"]:Disconnect();
					Connections_Manager["Auto Parry"] = nil;
				end;
			end;
		end,
	});
local CurveOverlayState = {
	gui = nil,
	frame = nil,
	buttons = {},
	drag = nil,
	release = nil,
}
local update_curve_buttons
local parryTypeMap = {
		Camera = "Camera",
		Slow = "Slowball",
		Dot = "Fastball",
		Backwards = "Backwards",
		High = "High",
		Left = "Left",
		Right = "Right",
	};
local Curve_Mode_Dropdown = module:create_dropdown({
		title = "Curve Mode",
		flag = "Parry_Type",
		options = {
			"Camera",
			"Backwards",
			"Dot",
			"Slow",
			"High",
			"Left",
			"Right",
		},
		multi_dropdown = false,
		maximum_options = 7,
		callback = function(value)
			Selected_Parry_Type = parryTypeMap[value] or value;
			if CurveOverlayState.frame then
				local pill = CurveOverlayState.frame:FindFirstChild("PillLabel")
				if pill then pill.Text = value end
			end
			if #CurveOverlayState.buttons > 0 then
				update_curve_buttons()
			end
		end,
	});
module:create_slider({
	title = "Parry Accuracy",
	flag = "Parry_Accuracy",
	maximum_value = 100,
	minimum_value = 1,
	value = 100,
	round_number = true,
	callback = function(value)
		Speed_Divisor_Multiplier = .7 + (value - 1) * .0035353535353535;
	end,
});
module:create_checkbox({ title = "Randomize Curve", flag = "Randomize_Curve", callback = function(value)
		Randomize_Curve = value;
	end });

module:create_checkbox({ title = "Cooldown Protection", flag = "CooldownProtection", callback = function(value)
		(getgenv()).CooldownProtection = value;
	end });

module:create_checkbox({ title = "Animation Fix", flag = "Animation_Fix", callback = function(value)
		if ZX_SetAnimationFix then
			ZX_SetAnimationFix(value);
		end;
	end });
module:create_checkbox({ title = "Auto Ability", flag = "AutoAbility", callback = function(value)
		(getgenv()).AutoAbility = value;
	end });
module:create_checkbox({ title = "Notify", flag = "Auto_Parry_Notify", callback = function(value)
		(getgenv()).AutoParryNotify = value;
	end });
module._size += 6
if module._state then
    module:change_state(true)
end

local humanizer_module = Blatant:create_module({
	title = 'Humanizer',
	flag = 'Humanizer',
	description = 'Randomize parry accuracy range',
	section = 'right',
	callback = function(value)
		(getgenv()).RandomParryAccuracyEnabled = value;
	end,
})
do
	local saved_min = Library._config._flags['Humanizer_Min']
	local saved_max = Library._config._flags['Humanizer_Max']
	local hMin = (type(saved_min) == 'number' and math.clamp(saved_min, 1, 100)) or 1
	local hMax = (type(saved_max) == 'number' and math.clamp(saved_max, 1, 100)) or 100

	;(getgenv()).HumanizerMin = hMin
	;(getgenv()).HumanizerMax = hMax

	local humanizer_module_frame = (function()
		for _, obj in library._ui:GetDescendants() do
			if obj.Name == 'Module' then
				local h = obj:FindFirstChild('Header')
				local mn = h and h:FindFirstChild('ModuleName')
				if mn and mn.Text == 'Humanizer' then
					return obj
				end
			end
		end
	end)()

	if humanizer_module_frame then
		local Options = humanizer_module_frame:FindFirstChild('Options')

		if Options then
			humanizer_module._size = (humanizer_module._size == 0 and 11 or humanizer_module._size) + 50

			if humanizer_module._state then
				humanizer_module_frame.Size = UDim2.fromOffset(241, 93 + humanizer_module._size)
			end
			Options.Size = UDim2.fromOffset(241, humanizer_module._size)

			local RangeRow = Instance.new('Frame')
			RangeRow.Name = 'RangeSliderRow'
			RangeRow.Size = UDim2.new(0, 207, 0, 44)
			RangeRow.BackgroundTransparency = 1
			RangeRow.BorderSizePixel = 0
			RangeRow.LayoutOrder = 1
			RangeRow.Parent = Options

			local TitleLabel = Instance.new('TextLabel')
			TitleLabel.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
			TitleLabel.TextSize = 12
			TitleLabel.TextColor3 = Color3.fromRGB(206, 206, 212)
			TitleLabel.Text = 'Humanizer Range'
			TitleLabel.Size = UDim2.new(0, 120, 0, 14)
			TitleLabel.Position = UDim2.new(0, 0, 0, 0)
			TitleLabel.BackgroundTransparency = 1
			TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
			TitleLabel.BorderSizePixel = 0
			TitleLabel.Parent = RangeRow

			local ValueLabel = Instance.new('TextLabel')
			ValueLabel.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
			ValueLabel.TextColor3 = Color3.fromRGB(188, 188, 198)
			ValueLabel.TextTransparency = 0.2
			ValueLabel.Text = hMin .. ' - ' .. hMax
			ValueLabel.Size = UDim2.new(0, 80, 0, 14)
			ValueLabel.AnchorPoint = Vector2.new(1, 0)
			ValueLabel.Position = UDim2.new(1, 0, 0, 0)
			ValueLabel.BackgroundTransparency = 1
			ValueLabel.TextXAlignment = Enum.TextXAlignment.Right
			ValueLabel.BorderSizePixel = 0
			ValueLabel.TextSize = 10
			ValueLabel.Parent = RangeRow

			local Track = Instance.new('Frame')
			Track.Name = 'Drag'
			Track.AnchorPoint = Vector2.new(0.5, 1)
			Track.Position = UDim2.new(0.5, 0, 1, 0)
			Track.Size = UDim2.new(0, 207, 0, 6)
			Track.BorderSizePixel = 0
			Track.BackgroundColor3 = Color3.fromRGB(42, 42, 48)
			Track.Parent = RangeRow

			local TrackCorner = Instance.new('UICorner')
			TrackCorner.CornerRadius = UDim.new(1, 0)
			TrackCorner.Parent = Track

			local HitArea = Instance.new('TextButton')
			HitArea.Name = 'HitArea'
			HitArea.Size = UDim2.new(1, 0, 1, 0)
			HitArea.Position = UDim2.new(0, 0, 0, 0)
			HitArea.BackgroundTransparency = 1
			HitArea.BorderSizePixel = 0
			HitArea.Text = ''
			HitArea.AutoButtonColor = false
			HitArea.ZIndex = 10
			HitArea.Parent = RangeRow

			local Fill = Instance.new('Frame')
			Fill.Name = 'Fill'
			Fill.AnchorPoint = Vector2.new(0, 0.5)
			Fill.Position = UDim2.new(0, 0, 0.5, 0)
			Fill.Size = UDim2.fromOffset(207, 6)
			Fill.BorderSizePixel = 0
			Fill.BackgroundColor3 = Color3.fromRGB(220, 220, 225)
			Fill.Parent = Track

			local FillCorner = Instance.new('UICorner')
			FillCorner.CornerRadius = UDim.new(0, 3)
			FillCorner.Parent = Fill

			local FillGradient = Instance.new('UIGradient')
			FillGradient.Color = ColorSequence.new{
				ColorSequenceKeypoint.new(0, Color3.fromRGB(238, 238, 242)),
				ColorSequenceKeypoint.new(0.5, Color3.fromRGB(224, 224, 230)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(202, 202, 210))
			}
			FillGradient.Parent = Fill

			local function make_handle()
				local Circle = Instance.new('Frame')
				Circle.AnchorPoint = Vector2.new(0.5, 0.5)
				Circle.Position = UDim2.new(0, 0, 0.5, 0)
				Circle.Size = UDim2.fromOffset(10, 10)
				Circle.BorderSizePixel = 0
				Circle.BackgroundColor3 = Color3.fromRGB(232, 232, 236)
				Circle.Parent = Track

				local cc = Instance.new('UICorner')
				cc.CornerRadius = UDim.new(1, 0)
				cc.Parent = Circle

				local cs = Instance.new('UIStroke')
				cs.Color = Color3.fromRGB(20, 20, 24)
				cs.Transparency = 0.58
				cs.Thickness = 1
				cs.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
				cs.Parent = Circle

				return Circle
			end

			local MinHandle = make_handle()
			local MaxHandle = make_handle()

			local function val_to_scale(v)
				return (math.clamp(v, 1, 100) - 1) / 99
			end

			local function scale_to_val(s)
				return math.clamp(math.round(1 + s * 99), 1, 100)
			end

			local function refresh()
				local sMin = val_to_scale(hMin)
				local sMax = val_to_scale(hMax)
				local w = Track.Size.X.Offset
				MinHandle.Position = UDim2.new(sMin, 0, 0.5, 0)
				MaxHandle.Position = UDim2.new(sMax, 0, 0.5, 0)
				Fill.Position = UDim2.new(sMin, 0, 0.5, 0)
				Fill.Size = UDim2.fromOffset(math.max((sMax - sMin) * w, 0), 6)
				ValueLabel.Text = hMin .. ' - ' .. hMax
				Library._config._flags['Humanizer_Min'] = hMin
				Library._config._flags['Humanizer_Max'] = hMax
				;(getgenv()).HumanizerMin = hMin
				;(getgenv()).HumanizerMax = hMax
			end

			refresh()

			local function begin_drag(is_min)
				Connections['humanizer_drag'] = mouse.Move:Connect(function()
					local s = math.clamp((mouse.X - Track.AbsolutePosition.X) / Track.AbsoluteSize.X, 0, 1)
					local v = scale_to_val(s)
					if is_min then
						hMin = math.min(v, hMax)
					else
						hMax = math.max(v, hMin)
					end
					refresh()
				end)

				Connections['humanizer_end'] = UserInputService.InputEnded:Connect(function(input)
					if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
						return
					end
					Connections:disconnect('humanizer_drag')
					Connections:disconnect('humanizer_end')
				end)
			end

			HitArea.MouseButton1Down:Connect(function()
				local s = math.clamp((mouse.X - Track.AbsolutePosition.X) / Track.AbsoluteSize.X, 0, 1)
				local v = scale_to_val(s)
				local dMin = math.abs(v - hMin)
				local dMax = math.abs(v - hMax)
				local is_min = dMin <= dMax
				if is_min then
					hMin = math.min(v, hMax)
				else
					hMax = math.max(v, hMin)
				end
				refresh()
				begin_drag(is_min)
			end)
		end
	end
end

humanizer_module._size += 6
if humanizer_module._state then
	humanizer_module:change_state(true)
end

local spam_module = Blatant:create_module({
	title = "Auto Spam",
	flag = "Auto_Spam",
	description = "Automatically Spam the Ball",
	section = "right",
	callback = function(value)
		local previousAutoSpamState = Auto_Spam.Enabled;
		Auto_Spam.Enabled = value;
		if value then
			Auto_Spam.Start();
		else
			Auto_Spam.Stop();
		end;
		if previousAutoSpamState ~= value and (getgenv()).AutoSpamNotify then
			if value then
				Library.SendNotification({ title = "Auto Spam Enabled", text = "Enabled", duration = 3 });
			else
				Library.SendNotification({ title = "Auto Spam Disabled", text = "Disabled", duration = 3 });
			end;
		end;
	end,
});
spam_module:create_slider({
	title = "Parry Threshold",
	flag = "Auto_Spam_Threshold",
	maximum_value = 3,
	minimum_value = 1,
	value = Auto_Spam.Threshold,
	round_number = true,
	callback = function(value)
		Auto_Spam.Threshold = value;
	end
});
spam_module:create_slider({
	title = "Distance Multiplier",
	flag = "Auto_Spam_Distance_Multiplier",
	maximum_value = 3.0,
	minimum_value = 0.3,
	value = Auto_Spam.Distance_Multiplier,
	round_number = true,
	callback = function(value)
		Auto_Spam.Distance_Multiplier = value;
	end
});
spam_module:create_checkbox({ title = "Animation Fix", flag = "Auto_Spam_Animation_Fix", callback = function(value)
	(getgenv()).AutoSpamAnimationFix = value;
end });
spam_module:create_checkbox({ title = "Notify", flag = "Auto_Spam_Notify", callback = function(value)
	(getgenv()).AutoSpamNotify = value;
end });
spam_module._size += 6
if spam_module._state then
	spam_module:change_state(true)
end

local Kill_PreClick = {
    Enabled = false,
    Delay = 0.08,
    KillConn = nil,
}

local function kill_preclick_fire()
    if not _parry_hooked() then return end
    Auto_Parry.Parry_Animation()
    Auto_Parry.Parry(Resolve_Parry_Type())
end

local function kill_preclick_start()
    if Kill_PreClick.KillConn then return end
    Kill_PreClick.KillConn = game.ReplicatedStorage.Remotes.Killed.OnClientEvent:Connect(function()
        if not Kill_PreClick.Enabled then return end
        task.delay(Kill_PreClick.Delay, kill_preclick_fire)
    end)
end

local function kill_preclick_stop()
    if Kill_PreClick.KillConn then
        Kill_PreClick.KillConn:Disconnect()
        Kill_PreClick.KillConn = nil
    end
end

local kill_pc_module = Blatant:create_module({
    title = 'Pre Click on Kill',
    flag = 'Kill_PreClick',
    description = 'Auto pre click if you kill someone',
    section = 'right',
    callback = function(state)
        Kill_PreClick.Enabled = state
        if state then
            kill_preclick_start()
        else
            kill_preclick_stop()
        end
    end,
})

kill_pc_module:create_slider({
    title = 'Click Delay',
    flag = 'Kill_PreClick_Delay',
    minimum_value = 0,
    maximum_value = 0.5,
    value = 0.08,
    round_number = false,
    callback = function(value)
        Kill_PreClick.Delay = value
    end,
})

kill_pc_module._size += 6
if kill_pc_module._state then
    kill_pc_module:change_state(true)
end

do
	local _tb_ball_conns = {}
	local _tb_alive_conn = nil
	local _tb_spam_threads = {}

	local playerStr = tostring(Player)

	local function _start_spam(ball)
		if _tb_spam_threads[ball] then return end
		local conn
		conn = RunService.PreSimulation:Connect(function()
			if not _tb_spam_threads[ball] or not getgenv().Triggerbot or not ball.Parent or ball:GetAttribute("target") ~= playerStr then
				conn:Disconnect()
				_tb_spam_threads[ball] = nil
				return
			end
			_send_parry(Resolve_Parry_Type())
		end)
		_tb_spam_threads[ball] = conn
	end

	local function _stop_spam(ball)
		local t = _tb_spam_threads[ball]
		if t and type(t) ~= 'boolean' then
			pcall(function() t:Disconnect() end)
		end
		_tb_spam_threads[ball] = nil
	end

	local function _hook_ball(ball)
		if _tb_ball_conns[ball] then return end
		local conns = {}
		_tb_ball_conns[ball] = conns

		table.insert(conns, ball:GetAttributeChangedSignal("target"):Connect(function()
			if not getgenv().Triggerbot then return end
			if ball:GetAttribute("target") == playerStr then
				_start_spam(ball)
			else
				_stop_spam(ball)
			end
		end))

		table.insert(conns, ball.AncestryChanged:Connect(function()
			if not ball.Parent then
				_stop_spam(ball)
				for _, c in ipairs(_tb_ball_conns[ball] or {}) do pcall(function() c:Disconnect() end) end
				_tb_ball_conns[ball] = nil
			end
		end))
	end

	local function start_triggerbot()
		if _tb_alive_conn then return end
		for _, ball in pairs(workspace.Balls:GetChildren()) do
			if ball:GetAttribute("realBall") then
				_hook_ball(ball)
			end
		end
		_tb_alive_conn = workspace.Balls.ChildAdded:Connect(function(ball)
			if not getgenv().Triggerbot then return end
			task.defer(function()
				if ball:GetAttribute("realBall") then
					_hook_ball(ball)
				end
			end)
		end)
	end

	local function stop_triggerbot()
		if _tb_alive_conn then
			_tb_alive_conn:Disconnect()
			_tb_alive_conn = nil
		end
		for _, conns in pairs(_tb_ball_conns) do
			for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
		end
		table.clear(_tb_ball_conns)
		for _, t in pairs(_tb_spam_threads) do
			if t and type(t) ~= 'boolean' then
				pcall(function() t:Disconnect() end)
			end
		end
		table.clear(_tb_spam_threads)
		getgenv().Triggerbot = false
	end

	getgenv()._Zuro_TB_Stop = stop_triggerbot
	getgenv()._Zuro_TB_Set = function(state)
		getgenv().Triggerbot = state
		if state then
			start_triggerbot()
		else
			stop_triggerbot()
		end
		if getgenv()._Zuro_Triggerbot_UI_Update then
			getgenv()._Zuro_Triggerbot_UI_Update()
		end
	end

	local triggerbot_module = Blatant:create_module({
		title = 'Triggerbot',
		flag = 'Triggerbot',
		description = 'Instantly parry when ball targets you',
		section = 'right',
		callback = function(state)
			getgenv()._Zuro_TB_Set(state)
		end,
	})
	triggerbot_module:create_checkbox({
		title = 'Mobile UI',
		flag = 'Triggerbot_Mobile_UI',
		callback = function(value)
			if value then
				if getgenv()._Zuro_Triggerbot_UI_Create then
					getgenv()._Zuro_Triggerbot_UI_Create()
				end
			else
				if getgenv()._Zuro_Triggerbot_UI_Destroy then
					getgenv()._Zuro_Triggerbot_UI_Destroy()
				end
			end
		end,
	})
	triggerbot_module._size += 6
	if triggerbot_module._state then
		triggerbot_module:change_state(true)
	end
end



local ManualSpamOverlayState = {
	gui = nil,
	frame = nil,
	label = nil,
	drag = nil,
	release = nil
};
local CpsCounterState = {
	gui = nil,
	frame = nil,
	value = nil,
	drag = nil,
	release = nil,
	sample = nil
};
local function attach_overlay_shadow(target, pad)
	local Shadow = Instance.new('ImageLabel');
	Shadow.Name = 'SoftShadow';
	Shadow.BackgroundTransparency = 1;
	Shadow.BorderSizePixel = 0;
	Shadow.Image = 'rbxassetid://6014261993';
	Shadow.ImageColor3 = Color3.fromRGB(0, 0, 0);
	Shadow.ImageTransparency = 0.42;
	Shadow.ScaleType = Enum.ScaleType.Slice;
	Shadow.SliceCenter = Rect.new(49, 49, 450, 450);
	Shadow.Visible = target.Visible;
	Shadow.ZIndex = 39;
	Shadow.Parent = target.Parent;
	local function sync()
		Shadow.Position = UDim2.new(target.Position.X.Scale, target.Position.X.Offset - pad, target.Position.Y.Scale, target.Position.Y.Offset - pad);
		Shadow.Size = UDim2.new(target.Size.X.Scale, target.Size.X.Offset + pad * 2, target.Size.Y.Scale, target.Size.Y.Offset + pad * 2);
	end;
	sync();
	target:GetPropertyChangedSignal('Position'):Connect(sync);
	target:GetPropertyChangedSignal('Size'):Connect(sync);
	target:GetPropertyChangedSignal('Visible'):Connect(function()
		Shadow.Visible = target.Visible;
	end);
end;
local function update_manual_spam_overlay()
	local Running = (Manual_Spam.Mobile_Gate and Manual_Spam.Active) or (not Manual_Spam.Mobile_Gate and Manual_Spam.Enabled);
	if not Running then
		Manual_Spam.Fired = 0;
		Manual_Spam.Live_CPS = 0;
		if CpsCounterState.value then
			CpsCounterState.value.Text = '0';
		end;
	end;
	if not ManualSpamOverlayState.frame then
		return;
	end;
	if Running then
		ManualSpamOverlayState.label.Text = 'ON';
		ManualSpamOverlayState.label.TextColor3 = Color3.fromRGB(255, 255, 255);
	else
		ManualSpamOverlayState.label.Text = 'OFF';
		ManualSpamOverlayState.label.TextColor3 = Color3.fromRGB(138, 138, 138);
	end;
end;
local function sync_manual_spam_overlays()
	if ManualSpamOverlayState.frame then
		ManualSpamOverlayState.frame.Visible = Manual_Spam.Mobile_Overlay_On;
	end;
	if CpsCounterState.frame then
		CpsCounterState.frame.Visible = Manual_Spam.Cps_Counter_On;
	end;
end;
local function destroy_manual_spam_overlay()
	if ManualSpamOverlayState.drag then
		ManualSpamOverlayState.drag:Disconnect();
		ManualSpamOverlayState.drag = nil;
	end;
	if ManualSpamOverlayState.release then
		ManualSpamOverlayState.release:Disconnect();
		ManualSpamOverlayState.release = nil;
	end;
	if ManualSpamOverlayState.gui then
		pcall(function()
			ManualSpamOverlayState.gui:Destroy();
		end);
	end;
	ManualSpamOverlayState.gui = nil;
	ManualSpamOverlayState.frame = nil;
	ManualSpamOverlayState.label = nil;
end;
local function create_manual_spam_overlay()
	if ManualSpamOverlayState.gui then
		return;
	end;
	local OverlayGui = Instance.new('ScreenGui');
	OverlayGui.Name = 'ZuroManualSpamOverlay';
	OverlayGui.ResetOnSpawn = false;
	OverlayGui.IgnoreGuiInset = true;
	OverlayGui.DisplayOrder = 100;
	OverlayGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling;
	OverlayGui.Parent = CoreGui;
	local Pill = Instance.new('Frame');
	Pill.Name = 'TogglePill';
	Pill.Size = UDim2.new(0, 132, 0, 51);
	Pill.Position = UDim2.new(0, 30, 0.5, -26);
	Pill.BackgroundColor3 = Color3.fromRGB(255, 255, 255);
	Pill.BorderSizePixel = 0;
	Pill.ClipsDescendants = true;
	Pill.Visible = false;
	Pill.Active = true;
	Pill.ZIndex = 40;
	Pill.Parent = OverlayGui;
	attach_overlay_shadow(Pill, 14);
	local PillCorner = Instance.new('UICorner');
	PillCorner.CornerRadius = UDim.new(0, 14);
	PillCorner.Parent = Pill;
	local PillGradient = Instance.new('UIGradient');
	PillGradient.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0.00, Color3.fromRGB(145, 145, 145)),
		ColorSequenceKeypoint.new(0.30, Color3.fromRGB(12, 12, 12)),
		ColorSequenceKeypoint.new(1.00, Color3.fromRGB(0, 0, 0))
	};
	PillGradient.Rotation = 90;
	PillGradient.Parent = Pill;
	local PillTexture = Instance.new('ImageLabel');
	PillTexture.Name = 'Texture';
	PillTexture.Size = UDim2.new(1, 0, 1, 0);
	PillTexture.BackgroundTransparency = 1;
	PillTexture.BorderSizePixel = 0;
	PillTexture.Image = 'rbxassetid://9968344227';
	PillTexture.ImageColor3 = Color3.fromRGB(0, 0, 0);
	PillTexture.ImageTransparency = 0.92;
	PillTexture.ScaleType = Enum.ScaleType.Tile;
	PillTexture.TileSize = UDim2.new(0, 128, 0, 128);
	PillTexture.ZIndex = 40;
	PillTexture.Parent = Pill;
	local PillHighlight = Instance.new('Frame');
	PillHighlight.Name = 'TopHighlight';
	PillHighlight.Size = UDim2.new(1, -28, 0, 1);
	PillHighlight.Position = UDim2.new(0, 14, 0, 0);
	PillHighlight.BackgroundColor3 = Color3.fromRGB(255, 255, 255);
	PillHighlight.BackgroundTransparency = 0.86;
	PillHighlight.BorderSizePixel = 0;
	PillHighlight.ZIndex = 41;
	PillHighlight.Parent = Pill;
	local BaseStroke = Instance.new('UIStroke');
	BaseStroke.Color = Color3.fromRGB(255, 255, 255);
	BaseStroke.Transparency = 0.85;
	BaseStroke.Thickness = 1;
	BaseStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border;
	BaseStroke.Parent = Pill;
	local NameLabel = Instance.new('TextLabel');
	NameLabel.Name = 'NameLabel';
	NameLabel.Size = UDim2.new(0, 52, 0, 12);
	NameLabel.Position = UDim2.new(0, 4, 0, 4);
	NameLabel.BackgroundTransparency = 1;
	NameLabel.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal);
	NameLabel.Text = 'Spam';
	NameLabel.TextColor3 = Color3.fromRGB(175, 175, 182);
	NameLabel.TextSize = 8;
	NameLabel.TextXAlignment = Enum.TextXAlignment.Center;
	NameLabel.ZIndex = 42;
	NameLabel.Parent = Pill;

	local Label = Instance.new('TextLabel');
	Label.Name = 'Label';
	Label.Size = UDim2.new(1, -55, 1, 0);
	Label.Position = UDim2.new(0, 55, 0, 0);
	Label.BackgroundTransparency = 1;
	Label.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.Heavy, Enum.FontStyle.Normal);
	Label.Text = 'OFF';
	Label.TextColor3 = Color3.fromRGB(138, 138, 138);
	Label.TextSize = 16;
	Label.TextXAlignment = Enum.TextXAlignment.Center;
	Label.ZIndex = 42;
	Label.Parent = Pill;
	local DragHit = Instance.new('TextButton');
	DragHit.Name = 'DragHit';
	DragHit.Size = UDim2.new(0, 55, 1, 0);
	DragHit.Position = UDim2.new(0, 0, 0, 0);
	DragHit.BackgroundTransparency = 1;
	DragHit.Text = '';
	DragHit.AutoButtonColor = false;
	DragHit.ZIndex = 43;
	DragHit.Parent = Pill;
	local ToggleHit = Instance.new('TextButton');
	ToggleHit.Name = 'ToggleHit';
	ToggleHit.Size = UDim2.new(1, -55, 1, 0);
	ToggleHit.Position = UDim2.new(0, 55, 0, 0);
	ToggleHit.BackgroundTransparency = 1;
	ToggleHit.Text = '';
	ToggleHit.AutoButtonColor = false;
	ToggleHit.ZIndex = 43;
	ToggleHit.Parent = Pill;
	local dragging = false;
	local dragStart = nil;
	local startPos = nil;
	DragHit.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true;
			dragStart = input.Position;
			startPos = Pill.Position;
			TweenService:Create(Pill, TweenInfo.new(0.06, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
				Size = UDim2.new(0, 126, 0, 46)
			}):Play();
		end;
	end);
	ManualSpamOverlayState.drag = UserInputService.InputChanged:Connect(function(input)
		if not dragging then
			return;
		end;
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			local delta = input.Position - dragStart;
			Pill.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y);
		end;
	end);
	ManualSpamOverlayState.release = UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			if dragging then
				dragging = false;
				TweenService:Create(Pill, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
					Size = UDim2.new(0, 132, 0, 51)
				}):Play();
			end;
		end;
	end);
	ToggleHit.Activated:Connect(function()
		Manual_Spam.Active = not Manual_Spam.Active;
		Manual_Spam.Start();
		update_manual_spam_overlay();
	end);
	ManualSpamOverlayState.gui = OverlayGui;
	ManualSpamOverlayState.frame = Pill;
	ManualSpamOverlayState.label = Label;
	update_manual_spam_overlay();
end;

-- Triggerbot floating toggle UI: same style/behavior as Manual Spam's Mobile UI.
do
	local TriggerbotUI = {
		gui = nil,
		frame = nil,
		label = nil,
		drag = nil,
		release = nil,
	}

	local function update_triggerbot_ui()
		if not TriggerbotUI.frame or not TriggerbotUI.label then
			return
		end
		if getgenv().Triggerbot then
			TriggerbotUI.label.Text = 'ON'
			TriggerbotUI.label.TextColor3 = Color3.fromRGB(255, 255, 255)
		else
			TriggerbotUI.label.Text = 'OFF'
			TriggerbotUI.label.TextColor3 = Color3.fromRGB(138, 138, 138)
		end
	end

	local function destroy_triggerbot_ui()
		if TriggerbotUI.drag then
			TriggerbotUI.drag:Disconnect()
			TriggerbotUI.drag = nil
		end
		if TriggerbotUI.release then
			TriggerbotUI.release:Disconnect()
			TriggerbotUI.release = nil
		end
		if TriggerbotUI.gui then
			pcall(function()
				TriggerbotUI.gui:Destroy()
			end)
		end
		TriggerbotUI.gui = nil
		TriggerbotUI.frame = nil
		TriggerbotUI.label = nil
	end

	local function create_triggerbot_ui()
		if TriggerbotUI.gui then
			update_triggerbot_ui()
			return
		end

		local OverlayGui = Instance.new('ScreenGui')
		OverlayGui.Name = 'ZuroTriggerbotOverlay'
		OverlayGui.ResetOnSpawn = false
		OverlayGui.IgnoreGuiInset = true
		OverlayGui.DisplayOrder = 101
		OverlayGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		OverlayGui.Parent = CoreGui

		local Pill = Instance.new('Frame')
		Pill.Name = 'TogglePill'
		Pill.Size = UDim2.new(0, 132, 0, 51)
		Pill.Position = UDim2.new(0, 30, 0.5, 34)
		Pill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		Pill.BorderSizePixel = 0
		Pill.ClipsDescendants = true
		Pill.Visible = true
		Pill.Active = true
		Pill.ZIndex = 40
		Pill.Parent = OverlayGui
		attach_overlay_shadow(Pill, 14)

		local Corner = Instance.new('UICorner')
		Corner.CornerRadius = UDim.new(0, 14)
		Corner.Parent = Pill

		local Gradient = Instance.new('UIGradient')
		Gradient.Color = ColorSequence.new{
			ColorSequenceKeypoint.new(0.00, Color3.fromRGB(145, 145, 145)),
			ColorSequenceKeypoint.new(0.30, Color3.fromRGB(12, 12, 12)),
			ColorSequenceKeypoint.new(1.00, Color3.fromRGB(0, 0, 0))
		}
		Gradient.Rotation = 90
		Gradient.Parent = Pill

		local Texture = Instance.new('ImageLabel')
		Texture.Name = 'Texture'
		Texture.Size = UDim2.new(1, 0, 1, 0)
		Texture.BackgroundTransparency = 1
		Texture.BorderSizePixel = 0
		Texture.Image = 'rbxassetid://9968344227'
		Texture.ImageColor3 = Color3.fromRGB(0, 0, 0)
		Texture.ImageTransparency = 0.92
		Texture.ScaleType = Enum.ScaleType.Tile
		Texture.TileSize = UDim2.new(0, 128, 0, 128)
		Texture.ZIndex = 40
		Texture.Parent = Pill

		local Highlight = Instance.new('Frame')
		Highlight.Name = 'TopHighlight'
		Highlight.Size = UDim2.new(1, -28, 0, 1)
		Highlight.Position = UDim2.new(0, 14, 0, 0)
		Highlight.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		Highlight.BackgroundTransparency = 0.86
		Highlight.BorderSizePixel = 0
		Highlight.ZIndex = 41
		Highlight.Parent = Pill

		local Stroke = Instance.new('UIStroke')
		Stroke.Color = Color3.fromRGB(255, 255, 255)
		Stroke.Transparency = 0.85
		Stroke.Thickness = 1
		Stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		Stroke.Parent = Pill

		local NameLabel = Instance.new('TextLabel')
		NameLabel.Name = 'NameLabel'
		NameLabel.Size = UDim2.new(0, 52, 0, 12)
		NameLabel.Position = UDim2.new(0, 4, 0, 4)
		NameLabel.BackgroundTransparency = 1
		NameLabel.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
		NameLabel.Text = 'Trigger'
		NameLabel.TextColor3 = Color3.fromRGB(175, 175, 182)
		NameLabel.TextSize = 8
		NameLabel.TextXAlignment = Enum.TextXAlignment.Center
		NameLabel.ZIndex = 42
		NameLabel.Parent = Pill

		local Label = Instance.new('TextLabel')
		Label.Name = 'Label'
		Label.Size = UDim2.new(1, -55, 1, 0)
		Label.Position = UDim2.new(0, 55, 0, 0)
		Label.BackgroundTransparency = 1
		Label.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.Heavy, Enum.FontStyle.Normal)
		Label.Text = 'OFF'
		Label.TextColor3 = Color3.fromRGB(138, 138, 138)
		Label.TextSize = 16
		Label.TextXAlignment = Enum.TextXAlignment.Center
		Label.ZIndex = 42
		Label.Parent = Pill

		local DragHit = Instance.new('TextButton')
		DragHit.Name = 'DragHit'
		DragHit.Size = UDim2.new(0, 55, 1, 0)
		DragHit.BackgroundTransparency = 1
		DragHit.Text = ''
		DragHit.AutoButtonColor = false
		DragHit.ZIndex = 43
		DragHit.Parent = Pill

		local ToggleHit = Instance.new('TextButton')
		ToggleHit.Name = 'ToggleHit'
		ToggleHit.Size = UDim2.new(1, -55, 1, 0)
		ToggleHit.Position = UDim2.new(0, 55, 0, 0)
		ToggleHit.BackgroundTransparency = 1
		ToggleHit.Text = ''
		ToggleHit.AutoButtonColor = false
		ToggleHit.ZIndex = 43
		ToggleHit.Parent = Pill

		local dragging = false
		local dragStart
		local startPos

		DragHit.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch then
				dragging = true
				dragStart = input.Position
				startPos = Pill.Position
				TweenService:Create(Pill, TweenInfo.new(0.06, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
					Size = UDim2.new(0, 126, 0, 46)
				}):Play()
			end
		end)

		TriggerbotUI.drag = UserInputService.InputChanged:Connect(function(input)
			if not dragging then
				return
			end
			if input.UserInputType == Enum.UserInputType.MouseMovement
				or input.UserInputType == Enum.UserInputType.Touch then
				local delta = input.Position - dragStart
				Pill.Position = UDim2.new(
					startPos.X.Scale, startPos.X.Offset + delta.X,
					startPos.Y.Scale, startPos.Y.Offset + delta.Y
				)
			end
		end)

		TriggerbotUI.release = UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch then
				if dragging then
					dragging = false
					TweenService:Create(Pill, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
						Size = UDim2.new(0, 132, 0, 51)
					}):Play()
				end
			end
		end)

		ToggleHit.Activated:Connect(function()
			if getgenv()._Zuro_TB_Set then
				getgenv()._Zuro_TB_Set(not getgenv().Triggerbot)
			end
		end)

		TriggerbotUI.gui = OverlayGui
		TriggerbotUI.frame = Pill
		TriggerbotUI.label = Label
		update_triggerbot_ui()
	end

	getgenv()._Zuro_Triggerbot_UI_Create = create_triggerbot_ui
	getgenv()._Zuro_Triggerbot_UI_Destroy = destroy_triggerbot_ui
	getgenv()._Zuro_Triggerbot_UI_Update = update_triggerbot_ui
end

local function destroy_cps_counter()
	if CpsCounterState.sample then
		CpsCounterState.sample:Disconnect();
		CpsCounterState.sample = nil;
	end;
	if CpsCounterState.drag then
		CpsCounterState.drag:Disconnect();
		CpsCounterState.drag = nil;
	end;
	if CpsCounterState.release then
		CpsCounterState.release:Disconnect();
		CpsCounterState.release = nil;
	end;
	if CpsCounterState.gui then
		pcall(function()
			CpsCounterState.gui:Destroy();
		end);
	end;
	CpsCounterState.gui = nil;
	CpsCounterState.frame = nil;
	CpsCounterState.value = nil;
end;
local function create_cps_counter()
	if CpsCounterState.gui then
		return;
	end;
	local CounterGui = Instance.new('ScreenGui');
	CounterGui.Name = 'ZuroCpsCounter';
	CounterGui.ResetOnSpawn = false;
	CounterGui.IgnoreGuiInset = true;
	CounterGui.DisplayOrder = 100;
	CounterGui.Parent = CoreGui;
	local Panel = Instance.new('Frame');
	Panel.Name = 'CpsPanel';
	Panel.Size = UDim2.new(0, 132, 0, 46);
	Panel.Position = UDim2.new(0, 30, 0.5, 34);
	Panel.BackgroundColor3 = Color3.fromRGB(255, 255, 255);
	Panel.BorderSizePixel = 0;
	Panel.ClipsDescendants = true;
	Panel.Visible = false;
	Panel.Active = true;
	Panel.ZIndex = 40;
	Panel.Parent = CounterGui;
	attach_overlay_shadow(Panel, 14);
	local PanelCorner = Instance.new('UICorner');
	PanelCorner.CornerRadius = UDim.new(0, 14);
	PanelCorner.Parent = Panel;
	local PanelGradient = Instance.new('UIGradient');
	PanelGradient.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0.00, Color3.fromRGB(145, 145, 145)),
		ColorSequenceKeypoint.new(0.30, Color3.fromRGB(12, 12, 12)),
		ColorSequenceKeypoint.new(1.00, Color3.fromRGB(0, 0, 0))
	};
	PanelGradient.Rotation = 90;
	PanelGradient.Parent = Panel;
	local PanelTexture = Instance.new('ImageLabel');
	PanelTexture.Name = 'Texture';
	PanelTexture.Size = UDim2.new(1, 0, 1, 0);
	PanelTexture.BackgroundTransparency = 1;
	PanelTexture.BorderSizePixel = 0;
	PanelTexture.Image = 'rbxassetid://9968344227';
	PanelTexture.ImageColor3 = Color3.fromRGB(0, 0, 0);
	PanelTexture.ImageTransparency = 0.92;
	PanelTexture.ScaleType = Enum.ScaleType.Tile;
	PanelTexture.TileSize = UDim2.new(0, 128, 0, 128);
	PanelTexture.ZIndex = 40;
	PanelTexture.Parent = Panel;
	local PanelHighlight = Instance.new('Frame');
	PanelHighlight.Name = 'TopHighlight';
	PanelHighlight.Size = UDim2.new(1, -24, 0, 1);
	PanelHighlight.Position = UDim2.new(0, 12, 0, 0);
	PanelHighlight.BackgroundColor3 = Color3.fromRGB(255, 255, 255);
	PanelHighlight.BackgroundTransparency = 0.86;
	PanelHighlight.BorderSizePixel = 0;
	PanelHighlight.ZIndex = 41;
	PanelHighlight.Parent = Panel;
	local PanelStroke = Instance.new('UIStroke');
	PanelStroke.Color = Color3.fromRGB(255, 255, 255);
	PanelStroke.Transparency = 0.85;
	PanelStroke.Thickness = 1;
	PanelStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border;
	PanelStroke.Parent = Panel;
	local CpsValue = Instance.new('TextLabel');
	CpsValue.Name = 'CpsValue';
	CpsValue.Size = UDim2.new(1, 0, 1, 0);
	CpsValue.Position = UDim2.new(0, 0, 0, 0);
	CpsValue.BackgroundTransparency = 1;
	CpsValue.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.Heavy, Enum.FontStyle.Normal);
	CpsValue.Text = '0';
	CpsValue.TextColor3 = Color3.fromRGB(255, 255, 255);
	CpsValue.TextSize = 22;
	CpsValue.TextXAlignment = Enum.TextXAlignment.Center;
	CpsValue.TextYAlignment = Enum.TextYAlignment.Center;
	CpsValue.ZIndex = 42;
	CpsValue.Parent = Panel;
	local PanelDrag = Instance.new('TextButton');
	PanelDrag.Name = 'DragHit';
	PanelDrag.Size = UDim2.new(1, 0, 1, 0);
	PanelDrag.BackgroundTransparency = 1;
	PanelDrag.Text = '';
	PanelDrag.AutoButtonColor = false;
	PanelDrag.ZIndex = 43;
	PanelDrag.Parent = Panel;
	local dragging = false;
	local dragStart = nil;
	local startPos = nil;
	PanelDrag.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true;
			dragStart = input.Position;
			startPos = Panel.Position;
			TweenService:Create(Panel, TweenInfo.new(0.06, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
				Size = UDim2.new(0, 126, 0, 41)
			}):Play();
		end;
	end);
	CpsCounterState.drag = UserInputService.InputChanged:Connect(function(input)
		if not dragging then
			return;
		end;
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			local delta = input.Position - dragStart;
			Panel.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y);
		end;
	end);
	CpsCounterState.release = UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			if dragging then
				dragging = false;
				TweenService:Create(Panel, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
					Size = UDim2.new(0, 132, 0, 46)
				}):Play();
			end;
		end;
	end);
	local Sample_Elapsed = 0;
	CpsCounterState.sample = RunService.Heartbeat:Connect(function(delta)
		if delta <= 0 then
			return;
		end;
		local Instant = Manual_Spam.Fired / delta;
		Manual_Spam.Fired = 0;
		Manual_Spam.Live_CPS = Manual_Spam.Live_CPS + (Instant - Manual_Spam.Live_CPS) * 0.04;
		Sample_Elapsed = Sample_Elapsed + delta;
		if Sample_Elapsed < 0.4 then
			return;
		end;
		Sample_Elapsed = 0;
		CpsValue.Text = tostring(math.floor(Manual_Spam.Live_CPS + 0.5));
	end);
	CpsCounterState.gui = CounterGui;
	CpsCounterState.frame = Panel;
	CpsCounterState.value = CpsValue;
end;
local manual_spam_module = Blatant:create_module({
	title = "Manual Spam",
	flag = "Manual_Spam",
	description = "High Intensity Spam",
	section = "right",
	callback = function(value)
		local previousManualSpamState = Manual_Spam.Enabled;
		Manual_Spam.Enabled = value;
		Manual_Spam.Start();
		update_manual_spam_overlay();
		sync_manual_spam_overlays();
		if previousManualSpamState ~= value and (getgenv()).ManualSpamNotify then
			if value then
				Library.SendNotification({ title = "Manual Spam Enabled", text = "Enabled", duration = 3 });
			else
				Library.SendNotification({ title = "Manual Spam Disabled", text = "Disabled", duration = 3 });
			end;
		end;
	end,
});
manual_spam_module:create_slider({
	title = "CPS Speed",
	flag = "Manual_Spam_CPS",
	minimum_value = 100,
	maximum_value = 100,
	value = 100,
	round_number = true,
	callback = function(value)
		Manual_Spam.Target_CPS = value;
	end,
});
manual_spam_module:create_checkbox({ title = "Mobile UI", flag = "Manual_Spam_Mobile_Overlay", callback = function(value)
		Manual_Spam.Mobile_Gate = value;
		Manual_Spam.Mobile_Overlay_On = value;
		if value then
			Manual_Spam.Active = false;
			create_manual_spam_overlay();
		end;
		sync_manual_spam_overlays();
		Manual_Spam.Start();
		update_manual_spam_overlay();
	end });
manual_spam_module:create_checkbox({ title = "CPS Counter", flag = "Manual_Spam_Cps_Counter", callback = function(value)
		Manual_Spam.Cps_Counter_On = value;
		if value then
			create_cps_counter();
		end;
		sync_manual_spam_overlays();
	end });
manual_spam_module:create_checkbox({ title = "Animation Fix", flag = "Manual_Spam_Animation_Fix", callback = function(value)
		(getgenv()).ManualSpamAnimationFix = value;
	end });
manual_spam_module:create_checkbox({ title = "Notify", flag = "Manual_Spam_Notify", callback = function(value)
		(getgenv()).ManualSpamNotify = value;
	end });
manual_spam_module._size += 6
if manual_spam_module._state then
	manual_spam_module:change_state(true)
end

local target_lock_module = Blatant:create_module({
	title = "Target Player",
	flag = "Target_Lock",
	description = "Point mouse and click key to Target",
	section = "left",
	callback = function(value)
		Target_Lock_Enabled = value
		if not value then
			set_target(nil)
		end
	end,
})

target_lock_module:create_keybind_row({
	title = "Keybind Target",
	flag = "Target_Lock_Player",
})

target_lock_module:create_checkbox({
	title = "Highlight Target",
	flag = "Target_Lock_Highlight",
	callback = function(value)
		Target_Highlight_Enabled = value
		if not value then
			if Target_Lock_Highlight then
				Target_Lock_Highlight:Destroy()
				Target_Lock_Highlight = nil
			end
			return
		end
		if Selected_Target then
			apply_highlight(Selected_Target)
		end
	end,
})

target_lock_module:create_checkbox({
	title = "Player Info",
	flag = "Target_Lock_Label",
	callback = function(value)
		Target_Label_Enabled = value
		if not value then
			if Target_Lock_Label then
				Target_Lock_Label:Destroy()
				Target_Lock_Label = nil
			end
			return
		end
		if Selected_Target then
			apply_label(Selected_Target)
		end
	end,
})

local function find_target_at_ray(unit_ray)
	local best, best_dot = nil, 0.92
	for _, character in ipairs(workspace.Alive:GetChildren()) do
		if tostring(character) ~= tostring(Player) and character.PrimaryPart then
			local to_char = (character.PrimaryPart.Position - unit_ray.Origin).Unit
			local dot = to_char:Dot(unit_ray.Direction)
			if dot > best_dot then
				best_dot = dot
				best = character
			end
		end
	end
	return best
end

local function toggle_target(best)
	if best and Selected_Target and tostring(best) == tostring(Selected_Target) then
		set_target(nil)
	else
		set_target(best)
	end
end

if not isMobile then
	Connections_Manager['target_lock_key'] = UserInputService.InputBegan:Connect(function(input, process)
		if process or not Target_Lock_Enabled then return end
		local bound = Library._config._keybinds['Target_Lock_Player']
		if not bound or tostring(input.KeyCode) ~= bound then return end
		local camera = workspace.CurrentCamera
		local ok, mouse_loc = pcall(function() return UserInputService:GetMouseLocation() end)
		if not ok or not mouse_loc then return end
		local unit_ray = camera:ViewportPointToRay(mouse_loc.X, mouse_loc.Y)
		local best = find_target_at_ray(unit_ray)
		toggle_target(best)
	end)
else
	local last_tap_time = 0
	local last_tap_target = nil
	Connections_Manager['target_lock_touch'] = UserInputService.InputBegan:Connect(function(input, process)
		if process or not Target_Lock_Enabled then return end
		if input.UserInputType ~= Enum.UserInputType.Touch then return end
		local camera = workspace.CurrentCamera
		local touch_pos = input.Position
		local unit_ray = camera:ViewportPointToRay(touch_pos.X, touch_pos.Y)
		local best = find_target_at_ray(unit_ray)
		local current_time = tick()
		if current_time - last_tap_time < 0.3 and best and last_tap_target and tostring(best) == tostring(last_tap_target) then
			toggle_target(best)
			last_tap_time = 0
			last_tap_target = nil
		else
			last_tap_time = current_time
			last_tap_target = best
		end
	end)
end

Players.PlayerRemoving:Connect(function(leavingPlayer)
	if Selected_Target and tostring(Selected_Target) == tostring(leavingPlayer) then
		set_target(nil)
	end
end)

target_lock_module._size += 6
if target_lock_module._state then
	target_lock_module:change_state(true)
end

local function destroy_curve_overlay()
	if CurveOverlayState.drag then
		CurveOverlayState.drag:Disconnect()
		CurveOverlayState.drag = nil
	end
	if CurveOverlayState.release then
		CurveOverlayState.release:Disconnect()
		CurveOverlayState.release = nil
	end
	if CurveOverlayState.gui then
		pcall(function() CurveOverlayState.gui:Destroy() end)
	end
	CurveOverlayState.gui = nil
	CurveOverlayState.frame = nil
	CurveOverlayState.buttons = {}
end

do
	local Curve_Hotkey_Order = { "Camera", "Backwards", "Dot", "Slow", "High", "Left", "Right" }
	local Curve_Hotkey_Keys = {
		[Enum.KeyCode.One]   = 1,
		[Enum.KeyCode.Two]   = 2,
		[Enum.KeyCode.Three] = 3,
		[Enum.KeyCode.Four]  = 4,
		[Enum.KeyCode.Five]  = 5,
		[Enum.KeyCode.Six]   = 6,
		[Enum.KeyCode.Seven] = 7,
	}
	local Curve_Hotkey_Enabled = false
	local Curve_Hotkey_Notify = false
	local Curve_Hotkey_Conn = nil
	local Curve_Mobile_On = false

	update_curve_buttons = function()
		for _, lbl in ipairs(CurveOverlayState.buttons) do
			lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
		end
	end

	local function create_curve_overlay()
		if CurveOverlayState.gui then return end

		local OverlayGui = Instance.new('ScreenGui')
		OverlayGui.Name = 'ZuroCurveOverlay'
		OverlayGui.ResetOnSpawn = false
		OverlayGui.IgnoreGuiInset = true
		OverlayGui.DisplayOrder = 100
		OverlayGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		OverlayGui.Parent = CoreGui

		local Pill = Instance.new('Frame')
		Pill.Name = 'CurvePill'
		Pill.Size = UDim2.new(0, 120, 0, 36)
		Pill.AnchorPoint = Vector2.new(0.5, 1)
		Pill.Position = UDim2.new(0.5, 0, 1, -28)
		Pill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		Pill.BorderSizePixel = 0
		Pill.ClipsDescendants = false
		Pill.Active = true
		Pill.ZIndex = 40
		Pill.Parent = OverlayGui

		local PillCorner = Instance.new('UICorner')
		PillCorner.CornerRadius = UDim.new(0, 8)
		PillCorner.Parent = Pill

		local PillGradient = Instance.new('UIGradient')
		PillGradient.Color = ColorSequence.new{
			ColorSequenceKeypoint.new(0.00, Color3.fromRGB(145, 145, 145)),
			ColorSequenceKeypoint.new(0.30, Color3.fromRGB(12, 12, 12)),
			ColorSequenceKeypoint.new(1.00, Color3.fromRGB(0, 0, 0))
		}
		PillGradient.Rotation = 90
		PillGradient.Parent = Pill

		local PillStroke = Instance.new('UIStroke')
		PillStroke.Color = Color3.fromRGB(255, 255, 255)
		PillStroke.Transparency = 0.88
		PillStroke.Thickness = 1
		PillStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		PillStroke.Parent = Pill

		local PillLabel = Instance.new('TextLabel')
		PillLabel.Name = 'PillLabel'
		PillLabel.Size = UDim2.new(1, -10, 1, 0)
		PillLabel.Position = UDim2.new(0, 5, 0, 0)
		PillLabel.BackgroundTransparency = 1
		PillLabel.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
		PillLabel.Text = 'Curve'
		PillLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
		PillLabel.TextSize = 12
		PillLabel.TextXAlignment = Enum.TextXAlignment.Center
		PillLabel.ZIndex = 42
		PillLabel.Parent = Pill

		local OPTION_H = 36
		local POPUP_FULL_H = #Curve_Hotkey_Order * OPTION_H + 8

		local Popup = Instance.new('Frame')
		Popup.Name = 'CurvePopup'
		Popup.Size = UDim2.new(0, 120, 0, POPUP_FULL_H)
		Popup.AnchorPoint = Vector2.new(0.5, 1)
		Popup.Position = UDim2.new(0.5, 0, 0, -6)
		Popup.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		Popup.BackgroundTransparency = 1
		Popup.BorderSizePixel = 0
		Popup.ZIndex = 50
		Popup.Visible = false
		Popup.Parent = Pill

		local PopupCorner = Instance.new('UICorner')
		PopupCorner.CornerRadius = UDim.new(0, 8)
		PopupCorner.Parent = Popup

		local PopupGradient = Instance.new('UIGradient')
		PopupGradient.Color = ColorSequence.new{
			ColorSequenceKeypoint.new(0.00, Color3.fromRGB(145, 145, 145)),
			ColorSequenceKeypoint.new(0.30, Color3.fromRGB(12, 12, 12)),
			ColorSequenceKeypoint.new(1.00, Color3.fromRGB(0, 0, 0))
		}
		PopupGradient.Rotation = 90
		PopupGradient.Parent = Popup

		local PopupStroke = Instance.new('UIStroke')
		PopupStroke.Color = Color3.fromRGB(255, 255, 255)
		PopupStroke.Transparency = 1
		PopupStroke.Thickness = 1
		PopupStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		PopupStroke.Parent = Popup

		local PopupPad = Instance.new('UIPadding')
		PopupPad.PaddingTop = UDim.new(0, 4)
		PopupPad.PaddingBottom = UDim.new(0, 4)
		PopupPad.Parent = Popup

		local PopupList = Instance.new('UIListLayout')
		PopupList.SortOrder = Enum.SortOrder.LayoutOrder
		PopupList.HorizontalAlignment = Enum.HorizontalAlignment.Center
		PopupList.Padding = UDim.new(0, 0)
		PopupList.Parent = Popup

		local popupOpen = false
		local tweening = false

		local function setPopupAlpha(a)
			Popup.BackgroundTransparency = a
			PopupStroke.Transparency = 0.88 + (1 - 0.88) * a
			for _, d in ipairs(Popup:GetDescendants()) do
				if d:IsA('TextLabel') or d:IsA('TextButton') then
					d.TextTransparency = a
				elseif d:IsA('Frame') then
					d.BackgroundTransparency = math.min(1, (d.BackgroundTransparency == 1 and 1) or 0.92 + (1 - 0.92) * a)
				end
			end
		end

		local function openPopup()
			if tweening then return end
			popupOpen = true
			tweening = true
			setPopupAlpha(1)
			Popup.Position = UDim2.new(0.5, 0, 0, 6)
			Popup.Visible = true
			local t = TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
			TweenService:Create(Popup, t, { BackgroundTransparency = 0, Position = UDim2.new(0.5, 0, 0, -6) }):Play()
			TweenService:Create(PopupStroke, t, { Transparency = 0.88 }):Play()
			for _, d in ipairs(Popup:GetDescendants()) do
				if d:IsA('TextLabel') or d:IsA('TextButton') then
					TweenService:Create(d, t, { TextTransparency = 0 }):Play()
				elseif d:IsA('Frame') and d.BackgroundTransparency < 1 then
					TweenService:Create(d, t, { BackgroundTransparency = 0.92 }):Play()
				end
			end
			task.delay(0.22, function() tweening = false end)
		end

		local function closePopup()
			if tweening then return end
			popupOpen = false
			tweening = true
			local t = TweenInfo.new(0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
			TweenService:Create(Popup, t, { BackgroundTransparency = 1, Position = UDim2.new(0.5, 0, 0, 6) }):Play()
			TweenService:Create(PopupStroke, t, { Transparency = 1 }):Play()
			for _, d in ipairs(Popup:GetDescendants()) do
				if d:IsA('TextLabel') or d:IsA('TextButton') then
					TweenService:Create(d, t, { TextTransparency = 1 }):Play()
				elseif d:IsA('Frame') and d.BackgroundTransparency < 1 then
					TweenService:Create(d, t, { BackgroundTransparency = 1 }):Play()
				end
			end
			task.delay(0.18, function()
				Popup.Visible = false
				Popup.Position = UDim2.new(0.5, 0, 0, -6)
				tweening = false
			end)
		end

		for i, label in ipairs(Curve_Hotkey_Order) do
			local Opt = Instance.new('TextButton')
			Opt.Name = 'CurveOpt'
			Opt.Size = UDim2.new(1, 0, 0, OPTION_H)
			Opt.BackgroundTransparency = 1
			Opt.BorderSizePixel = 0
			Opt.AutoButtonColor = false
			Opt.Text = ''
			Opt.LayoutOrder = i
			Opt.ZIndex = 46
			Opt.Parent = Popup

			local OptLabel = Instance.new('TextLabel')
			OptLabel.Name = 'TextLabel'
			OptLabel.Size = UDim2.new(1, 0, 1, 0)
			OptLabel.BackgroundTransparency = 1
			OptLabel.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.Regular, Enum.FontStyle.Normal)
			OptLabel.Text = label
			OptLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
			OptLabel.TextSize = 12
			OptLabel.TextXAlignment = Enum.TextXAlignment.Center
			OptLabel.ZIndex = 47
			OptLabel.Parent = Opt

			if i < #Curve_Hotkey_Order then
				local Sep = Instance.new('Frame')
				Sep.Size = UDim2.new(1, -24, 0, 1)
				Sep.Position = UDim2.new(0, 12, 1, -1)
				Sep.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				Sep.BackgroundTransparency = 0.92
				Sep.BorderSizePixel = 0
				Sep.ZIndex = 46
				Sep.Parent = Opt
			end

			CurveOverlayState.buttons[i] = OptLabel

			Opt.Activated:Connect(function()
				if not Curve_Hotkey_Enabled then return end
				local name = Curve_Hotkey_Order[i]
				Selected_Parry_Type = parryTypeMap[name] or name
				PillLabel.Text = label
				Curve_Mode_Dropdown:update(name)
				update_curve_buttons()
				closePopup()
				if Curve_Hotkey_Notify then
					Library.SendNotification({ title = "Curve Mode", text = name, duration = 2 })
				end
			end)
		end

		local dragMoved = false
		local dragStart = nil
		local pillStartPos = nil

		local PillHit = Instance.new('TextButton')
		PillHit.Name = 'PillHit'
		PillHit.Size = UDim2.new(1, 0, 1, 0)
		PillHit.BackgroundTransparency = 1
		PillHit.Text = ''
		PillHit.AutoButtonColor = false
		PillHit.ZIndex = 43
		PillHit.Parent = Pill

		local holdThread = nil
		local holdReady = false

		PillHit.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = false
				dragMoved = false
				holdReady = false
				dragStart = input.Position
				pillStartPos = Pill.Position
				holdThread = task.delay(1, function()
					holdReady = true
				end)
			end
		end)

		CurveOverlayState.drag = UserInputService.InputChanged:Connect(function(input)
			if not holdReady then return end
			if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
				local delta = input.Position - dragStart
				if not dragMoved and (math.abs(delta.X) > 4 or math.abs(delta.Y) > 4) then
					dragMoved = true
					if popupOpen then closePopup() end
				end
				if dragMoved then
					Pill.Position = UDim2.new(pillStartPos.X.Scale, pillStartPos.X.Offset + delta.X, pillStartPos.Y.Scale, pillStartPos.Y.Offset + delta.Y)
				end
			end
		end)

		CurveOverlayState.release = UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				if holdThread then
					task.cancel(holdThread)
					holdThread = nil
				end
				if not dragMoved then
					local pos = input.Position
					local abs = Pill.AbsolutePosition
					local sz = Pill.AbsoluteSize
					local onPill = pos.X >= abs.X and pos.X <= abs.X + sz.X and pos.Y >= abs.Y and pos.Y <= abs.Y + sz.Y
					if onPill then
						if popupOpen then
							closePopup()
						else
							openPopup()
						end
					end
				end
				holdReady = false
				dragMoved = false
			end
		end)

		CurveOverlayState.gui = OverlayGui
		CurveOverlayState.frame = Pill
		update_curve_buttons()
	end

	local curve_hotkey_module = Blatant:create_module({
		title = "Curve Shortcut",
		flag = "Curve_Hotkey",
		description = "Keyboard and Mobile Curve Switcher",
		section = "left",
		callback = function(state)
			Curve_Hotkey_Enabled = state
			if state then
				if Curve_Hotkey_Conn then
					Curve_Hotkey_Conn:Disconnect()
					Curve_Hotkey_Conn = nil
				end
				Curve_Hotkey_Conn = UserInputService.InputBegan:Connect(function(input, process)
					if process or not Curve_Hotkey_Enabled then return end
					local index = Curve_Hotkey_Keys[input.KeyCode]
					if not index then return end
					local name = Curve_Hotkey_Order[index]
					if not name then return end
					Selected_Parry_Type = parryTypeMap[name] or name
					Curve_Mode_Dropdown:update(name)
					if CurveOverlayState.frame then
						local pill = CurveOverlayState.frame:FindFirstChild("PillLabel")
						if pill then pill.Text = name end
					end
					update_curve_buttons()
					if Curve_Hotkey_Notify then
						Library.SendNotification({ title = "Curve Mode", text = name, duration = 2 })
					end
				end)
			else
				if Curve_Hotkey_Conn then
					Curve_Hotkey_Conn:Disconnect()
					Curve_Hotkey_Conn = nil
				end
			end
			if CurveOverlayState.frame then
				CurveOverlayState.frame.Visible = state and Curve_Mobile_On
			end
		end,
	})

	curve_hotkey_module:create_checkbox({ title = "Mobile UI", flag = "Curve_Hotkey_Mobile", callback = function(value)
		Curve_Mobile_On = value
		if value then
			create_curve_overlay()
		end
		if CurveOverlayState.frame then
			CurveOverlayState.frame.Visible = value and Curve_Hotkey_Enabled
		end
	end })

	curve_hotkey_module:create_checkbox({ title = "Notify", flag = "Curve_Hotkey_Notify", callback = function(value)
		Curve_Hotkey_Notify = value
	end })

	curve_hotkey_module._size += 6
	if curve_hotkey_module._state then
		curve_hotkey_module:change_state(true)
	end
end

local GuiService = cloneref(game:GetService('GuiService'))

local Default_Gui_Colors = {
    Header = { 145, 145, 145 },
    Body = { 0, 0, 0 },
    Modules = { 0, 0, 0 },
    Tabs = { 255, 255, 255 },
    Sliders = { 220, 220, 225 }
}

local Pill_Presets = {
    ['White and Black'] = { top = { 214, 214, 219 }, bottom = { 0, 0, 0 } },
    ['Black and White'] = { top = { 0, 0, 0 }, bottom = { 214, 214, 219 }, pivot = 0.68 },
    ['Gray and White'] = { top = { 120, 120, 120 }, bottom = { 214, 214, 219 } },
    ['Gray and Black'] = { top = { 72, 72, 72 }, bottom = { 0, 0, 0 } },
    ['Full Black'] = { top = { 24, 24, 27 }, bottom = { 0, 0, 0 } },
    ['Blue and Black'] = { top = { 48, 122, 190 }, bottom = { 0, 0, 0 } },
    ['Purple and Black'] = { top = { 118, 72, 190 }, bottom = { 0, 0, 0 } }
}

local Pill_Preset_Options = { 'White and Black', 'Black and White', 'Gray and White', 'Gray and Black', 'Full Black', 'Blue and Black', 'Purple and Black' }
local Selected_Pill_Preset = 'Gray and Black'

local Color_Targets = { 'Header', 'Body', 'Modules', 'Tabs', 'Sliders' }
local Color_Swatches = {}
local Gui_Colors = {}
local Gui_Colors_Enabled = false
local Selected_Color_Target = 'Header'
local Pointer_Offset = Vector2.zero
local Refresh_Elapsed = 0
local Current_Hue = 0
local Current_Saturation = 0
local Current_Value = 1

for target, channels in Default_Gui_Colors do
    Gui_Colors[target] = { channels[1], channels[2], channels[3] }
end

local Saved_Gui_Colors = Library._config._flags['Gui_Color_Values']

if typeof(Saved_Gui_Colors) == 'table' then
    for target, channels in Saved_Gui_Colors do
        if Gui_Colors[target] and typeof(channels) == 'table' then
            Gui_Colors[target] = { channels[1] or 0, channels[2] or 0, channels[3] or 0 }
        end
    end
end

local function apply_gui_color(target, source)
    local root = library._ui

    if not root then
        return
    end

    local Container = root.Container

    if target == 'Header' or target == 'Body' then
        local gradient = Container:FindFirstChildOfClass('UIGradient')

        if not gradient then
            return
        end

        local header = source.Header
        local body = source.Body
        local body_color = Color3.fromRGB(body[1], body[2], body[3])

        Container.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        gradient.Rotation = 90
        gradient.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0.00, Color3.fromRGB(header[1], header[2], header[3])),
            ColorSequenceKeypoint.new(0.11, body_color),
            ColorSequenceKeypoint.new(1.00, body_color)
        }

        return
    end

    local channels = source[target]
    local color = Color3.fromRGB(channels[1], channels[2], channels[3])

    for _, object in root:GetDescendants() do
        if target == 'Modules' and object.Name == 'Module' then
            object.BackgroundColor3 = color
        elseif target == 'Sliders' and object.Name == 'Fill' then
            object.BackgroundColor3 = color
        elseif target == 'Tabs' and object.Name == 'Tab' and object.BackgroundTransparency < 0.9 then
            object.TextLabel.TextColor3 = color
            object.Icon.ImageColor3 = color
        end
    end
end

local function apply_all_gui_colors(source)
    for _, target in Color_Targets do
        apply_gui_color(target, source)
    end
end

local function save_gui_colors()
    Library._config._flags['Gui_Color_Values'] = Gui_Colors
end

local function find_module_frame(title: string)
    for _, object in library._ui:GetDescendants() do
        if object.Name == 'Module' then
            local header = object:FindFirstChild('Header')
            local module_name = header and header:FindFirstChild('ModuleName')

            if module_name and module_name.Text == title then
                return object
            end
        end
    end
end

local function build_reset_button(parent, layout_order, on_click)
    local Reset_Holder = Instance.new('Frame')
    Reset_Holder.Name = 'ResetHolder'
    Reset_Holder.Size = UDim2.fromOffset(207, 23)
    Reset_Holder.BackgroundTransparency = 1
    Reset_Holder.BorderSizePixel = 0
    Reset_Holder.LayoutOrder = layout_order
    Reset_Holder.Parent = parent

    local Reset = Instance.new('TextButton')
    Reset.Name = 'Reset'
    Reset.AnchorPoint = Vector2.new(0, 1)
    Reset.Position = UDim2.new(0, 0, 1, 0)
    Reset.Size = UDim2.fromOffset(207, 22)
    Reset.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
    Reset.BorderSizePixel = 0
    Reset.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
    Reset.TextColor3 = Color3.fromRGB(202, 202, 209)
    Reset.TextSize = 12
    Reset.AutoButtonColor = false
    Reset.Text = 'Reset'
    Reset.Parent = Reset_Holder

    local ResetCorner = Instance.new('UICorner')
    ResetCorner.CornerRadius = UDim.new(0, 4)
    ResetCorner.Parent = Reset

    local ResetStroke = Instance.new('UIStroke')
    ResetStroke.Color = Color3.fromRGB(255, 255, 255)
    ResetStroke.Transparency = 0.72
    ResetStroke.Thickness = 1
    ResetStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    ResetStroke.Parent = Reset

    Reset.MouseButton1Click:Connect(on_click)
end

local color_module = Interface:create_module({
    title = 'Appearance',
    flag = 'Gui_Colors',
    description = 'Customize UI Colors',
    section = 'left',
    callback = function(state)
        Gui_Colors_Enabled = state

        if state then
            apply_all_gui_colors(Gui_Colors)
            return
        end

        apply_all_gui_colors(Default_Gui_Colors)
    end
})

local Color_Module_Frame = find_module_frame('Appearance')

if Color_Module_Frame then
    local Container = library._ui.Container
    local Handler = Container.Handler
    local Options = Color_Module_Frame.Options

    local function apply_pill_preset()
        local gradient = Container:FindFirstChildOfClass('UIGradient')
        local preset = Pill_Presets[Selected_Pill_Preset]
        if not gradient or not preset then return end
        if not Gui_Colors_Enabled then return end
        local top_color = Color3.fromRGB(preset.top[1], preset.top[2], preset.top[3])
        local keypoints = { ColorSequenceKeypoint.new(0.00, top_color) }
        if preset.pivot then
            table.insert(keypoints, ColorSequenceKeypoint.new(preset.pivot, top_color))
        end
        table.insert(keypoints, ColorSequenceKeypoint.new(1.00, Color3.fromRGB(preset.bottom[1], preset.bottom[2], preset.bottom[3])))
        Container.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        gradient.Rotation = 90
        gradient.Color = ColorSequence.new(keypoints)
        Handler.ClientName.TextColor3 = Color3.fromRGB(255, 255, 255)
        Handler.Logo.ImageColor3 = Color3.fromRGB(255, 255, 255)
    end

    local Popup = Instance.new('Frame')
    Popup.Name = 'ColorPopup'
    Popup.Position = UDim2.fromOffset(8, 8)
    Popup.Size = UDim2.fromOffset(214, 144)
    Popup.BackgroundColor3 = Color3.fromRGB(14, 14, 16)
    Popup.BorderSizePixel = 0
    Popup.Visible = false
    Popup.ZIndex = 30
    Popup.Parent = Handler

    do
        local PopupCorner = Instance.new('UICorner')
        PopupCorner.CornerRadius = UDim.new(0, 9)
        PopupCorner.Parent = Popup
    end

    do
        local PopupStroke = Instance.new('UIStroke')
        PopupStroke.Color = Color3.fromRGB(255, 255, 255)
        PopupStroke.Transparency = 0.72
        PopupStroke.Thickness = 1
        PopupStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        PopupStroke.Parent = Popup
    end

    local Field = Instance.new('TextButton')
    Field.Name = 'Field'
    Field.Position = UDim2.fromOffset(10, 10)
    Field.Size = UDim2.fromOffset(194, 100)
    Field.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    Field.BorderSizePixel = 0
    Field.ClipsDescendants = true
    Field.AutoButtonColor = false
    Field.Text = ''
    Field.ZIndex = 31
    Field.Parent = Popup

    do
        local FieldCorner = Instance.new('UICorner')
        FieldCorner.CornerRadius = UDim.new(0, 5)
        FieldCorner.Parent = Field
    end

    local Saturation = Instance.new('Frame')
    Saturation.Name = 'Saturation'
    Saturation.Size = UDim2.new(1, 0, 1, 0)
    Saturation.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Saturation.BorderSizePixel = 0
    Saturation.ZIndex = 32
    Saturation.Parent = Field

    do
        local SaturationGradient = Instance.new('UIGradient')
        SaturationGradient.Transparency = NumberSequence.new{
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(1, 1)
        }
        SaturationGradient.Parent = Saturation
    end

    local Brightness = Instance.new('Frame')
    Brightness.Name = 'Brightness'
    Brightness.Size = UDim2.new(1, 0, 1, 0)
    Brightness.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    Brightness.BorderSizePixel = 0
    Brightness.ZIndex = 33
    Brightness.Parent = Field

    do
        local BrightnessGradient = Instance.new('UIGradient')
        BrightnessGradient.Rotation = 90
        BrightnessGradient.Transparency = NumberSequence.new{
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(1, 0)
        }
        BrightnessGradient.Parent = Brightness
    end

    local Cursor = Instance.new('Frame')
    Cursor.Name = 'Cursor'
    Cursor.AnchorPoint = Vector2.new(0.5, 0.5)
    Cursor.Position = UDim2.new(0, 0, 0, 0)
    Cursor.Size = UDim2.fromOffset(11, 11)
    Cursor.BackgroundTransparency = 1
    Cursor.BorderSizePixel = 0
    Cursor.ZIndex = 34
    Cursor.Parent = Field

    do
        local CursorCorner = Instance.new('UICorner')
        CursorCorner.CornerRadius = UDim.new(1, 0)
        CursorCorner.Parent = Cursor

        local CursorStroke = Instance.new('UIStroke')
        CursorStroke.Color = Color3.fromRGB(255, 255, 255)
        CursorStroke.Transparency = 0
        CursorStroke.Thickness = 2
        CursorStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        CursorStroke.Parent = Cursor
    end

    local Hue = Instance.new('TextButton')
    Hue.Name = 'Hue'
    Hue.Position = UDim2.fromOffset(10, 120)
    Hue.Size = UDim2.fromOffset(194, 12)
    Hue.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Hue.BorderSizePixel = 0
    Hue.AutoButtonColor = false
    Hue.Text = ''
    Hue.ZIndex = 31
    Hue.Parent = Popup

    do
        local HueCorner = Instance.new('UICorner')
        HueCorner.CornerRadius = UDim.new(1, 0)
        HueCorner.Parent = Hue

        local HueGradient = Instance.new('UIGradient')
        HueGradient.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 0, 0)),
            ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
            ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
            ColorSequenceKeypoint.new(0.50, Color3.fromRGB(0, 255, 255)),
            ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
            ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
            ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 0, 0))
        }
        HueGradient.Parent = Hue
    end

    local Hue_Knob = Instance.new('Frame')
    Hue_Knob.Name = 'Knob'
    Hue_Knob.AnchorPoint = Vector2.new(0.5, 0.5)
    Hue_Knob.Position = UDim2.new(0, 0, 0.5, 0)
    Hue_Knob.Size = UDim2.fromOffset(5, 16)
    Hue_Knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Hue_Knob.BorderSizePixel = 0
    Hue_Knob.ZIndex = 32
    Hue_Knob.Parent = Hue

    do
        local Hue_Knob_Corner = Instance.new('UICorner')
        Hue_Knob_Corner.CornerRadius = UDim.new(1, 0)
        Hue_Knob_Corner.Parent = Hue_Knob

        local Hue_Knob_Stroke = Instance.new('UIStroke')
        Hue_Knob_Stroke.Color = Color3.fromRGB(20, 20, 24)
        Hue_Knob_Stroke.Transparency = 0.42
        Hue_Knob_Stroke.Thickness = 1
        Hue_Knob_Stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        Hue_Knob_Stroke.Parent = Hue_Knob
    end

    local function set_color(hue: number, saturation: number, brightness: number)
        Current_Hue = hue
        Current_Saturation = saturation
        Current_Value = brightness

        local color = Color3.fromHSV(hue, saturation, brightness)
        local channels = Gui_Colors[Selected_Color_Target]

        Field.BackgroundColor3 = Color3.fromHSV(hue, 1, 1)
        Cursor.Position = UDim2.new(saturation, 0, 1 - brightness, 0)
        Hue_Knob.Position = UDim2.new(hue, 0, 0.5, 0)
        Color_Swatches[Selected_Color_Target].BackgroundColor3 = color

        channels[1] = math.round(color.R * 255)
        channels[2] = math.round(color.G * 255)
        channels[3] = math.round(color.B * 255)

        if not Gui_Colors_Enabled then
            return
        end

        apply_gui_color(Selected_Color_Target, Gui_Colors)
    end

    local function calibrate_pointer(frame: GuiObject)
        local inset = GuiService:GetGuiInset()
        local location = UserInputService:GetMouseLocation()
        local top_left = frame.AbsolutePosition
        local bottom_right = top_left + frame.AbsoluteSize

        for _, offset in { Vector2.zero, inset, -inset } do
            local point = location + offset

            if point.X >= top_left.X and point.X <= bottom_right.X and point.Y >= top_left.Y and point.Y <= bottom_right.Y then
                Pointer_Offset = offset
                return
            end
        end
    end

    local function update_field()
        local location = UserInputService:GetMouseLocation() + Pointer_Offset
        local saturation = math.clamp((location.X - Field.AbsolutePosition.X) / Field.AbsoluteSize.X, 0, 1)
        local brightness = math.clamp((location.Y - Field.AbsolutePosition.Y) / Field.AbsoluteSize.Y, 0, 1)

        set_color(Current_Hue, saturation, 1 - brightness)
    end

    local function update_hue()
        local location = UserInputService:GetMouseLocation() + Pointer_Offset
        local hue = math.clamp((location.X - Hue.AbsolutePosition.X) / Hue.AbsoluteSize.X, 0, 1)

        set_color(hue, Current_Saturation, Current_Value)
    end

    local function begin_drag(key: string, frame: GuiObject, update: any)
        calibrate_pointer(frame)
        update()

        Connections[key..'_move'] = UserInputService.InputChanged:Connect(function(input: InputObject)
            if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then
                return
            end

            update()
        end)

        Connections[key..'_ended'] = UserInputService.InputEnded:Connect(function(input: InputObject)
            if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
                return
            end

            Connections:disconnect(key..'_move')
            Connections:disconnect(key..'_ended')
            save_gui_colors()
        end)
    end

    local function close_popup()
        Popup.Visible = false

        for _, swatch in Color_Swatches do
            swatch.UIStroke.Transparency = 0.72
        end
    end

    local function open_popup(target: string, swatch: GuiObject)
        if Popup.Visible and Selected_Color_Target == target then
            close_popup()
            return
        end

        Selected_Color_Target = target

        for name, object in Color_Swatches do
            object.UIStroke.Transparency = name == target and 0 or 0.72
        end

        local scale = Handler.AbsoluteSize.X / 752
        local relative_x = (swatch.AbsolutePosition.X - Handler.AbsolutePosition.X) / scale
        local relative_y = (swatch.AbsolutePosition.Y - Handler.AbsolutePosition.Y) / scale

        Popup.Position = UDim2.fromOffset(math.clamp(relative_x - 224, 8, 530), math.clamp(relative_y - 62, 8, 327))
        Popup.Visible = true

        local channels = Gui_Colors[target]
        local hue, saturation, brightness = Color3.toHSV(Color3.fromRGB(channels[1], channels[2], channels[3]))

        set_color(hue, saturation, brightness)
    end

    local function build_color_row(index, target)
        local Row = Instance.new('TextButton')
        Row.Name = 'ColorRow'
        Row.Size = UDim2.fromOffset(207, 22)
        Row.BackgroundTransparency = 1
        Row.BorderSizePixel = 0
        Row.AutoButtonColor = false
        Row.Text = ''
        Row.LayoutOrder = index
        Row.Parent = Options

        local TitleLabel = Instance.new('TextLabel')
        TitleLabel.Name = 'TitleLabel'
        TitleLabel.Size = UDim2.new(1, -50, 1, 0)
        TitleLabel.Position = UDim2.new(0, 0, 0, 0)
        TitleLabel.BackgroundTransparency = 1
        TitleLabel.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
        TitleLabel.TextColor3 = Color3.fromRGB(202, 202, 209)
        TitleLabel.TextSize = 12
        TitleLabel.Text = target
        TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
        TitleLabel.TextYAlignment = Enum.TextYAlignment.Center
        TitleLabel.Parent = Row

        local channels = Gui_Colors[target]

        local Swatch = Instance.new('TextButton')
        Swatch.Name = 'Swatch'
        Swatch.AnchorPoint = Vector2.new(1, 0.5)
        Swatch.Position = UDim2.new(1, 0, 0.5, 0)
        Swatch.Size = UDim2.fromOffset(34, 16)
        Swatch.BackgroundColor3 = Color3.fromRGB(channels[1], channels[2], channels[3])
        Swatch.BorderSizePixel = 0
        Swatch.AutoButtonColor = false
        Swatch.Text = ''
        Swatch.Parent = Row

        local SwatchCorner = Instance.new('UICorner')
        SwatchCorner.CornerRadius = UDim.new(0, 4)
        SwatchCorner.Parent = Swatch

        local SwatchStroke = Instance.new('UIStroke')
        SwatchStroke.Color = Color3.fromRGB(255, 255, 255)
        SwatchStroke.Transparency = 0.72
        SwatchStroke.Thickness = 1
        SwatchStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        SwatchStroke.Parent = Swatch

        Swatch.MouseButton1Click:Connect(function()
            open_popup(target, Swatch)
        end)

        Row.MouseButton1Click:Connect(function()
            open_popup(target, Swatch)
        end)

        Color_Swatches[target] = Swatch
    end

    for index, target in Color_Targets do
        build_color_row(index, target)
    end

    build_reset_button(Options, #Color_Targets + 2, function()
        close_popup()

        for target, channels in Default_Gui_Colors do
            Gui_Colors[target] = { channels[1], channels[2], channels[3] }
            Color_Swatches[target].BackgroundColor3 = Color3.fromRGB(channels[1], channels[2], channels[3])
        end

        if Gui_Colors_Enabled then
            apply_all_gui_colors(Gui_Colors)
        end

        save_gui_colors()
    end)

    Field.MouseButton1Down:Connect(function()
        begin_drag('gui_color_field', Field, update_field)
    end)

    Hue.MouseButton1Down:Connect(function()
        begin_drag('gui_color_hue', Hue, update_hue)
    end)

    Connections['gui_color_restore'] = Container:GetPropertyChangedSignal('Size'):Connect(function()
        if not library._ui_open then
            apply_pill_preset()

            return
        end

        Handler.ClientName.TextColor3 = Color3.fromRGB(255, 255, 255)
        Handler.Logo.ImageColor3 = Color3.fromRGB(255, 255, 255)

        if not Gui_Colors_Enabled then
            return
        end

        apply_gui_color('Header', Gui_Colors)
    end)

    Connections['gui_color_refresh'] = RunService.Heartbeat:Connect(function(delta)
        Refresh_Elapsed += delta

        if Refresh_Elapsed < 0.25 then
            return
        end

        Refresh_Elapsed = 0

        if not Gui_Colors_Enabled then
            return
        end

        apply_gui_color('Tabs', Gui_Colors)
    end)

    Connections['gui_color_section'] = Color_Module_Frame.Parent:GetPropertyChangedSignal('Visible'):Connect(function()
        if Color_Module_Frame.Parent.Visible then
            return
        end

        close_popup()
    end)

    Connections['gui_color_visiblity'] = Color_Module_Frame:GetPropertyChangedSignal('Size'):Connect(function()
        if Color_Module_Frame.AbsoluteSize.Y > 100 then
            return
        end

        close_popup()
    end)

    color_module:create_dropdown({
        title = 'Minimized',
        flag = 'Gui_Pill_Preset',
        options = Pill_Preset_Options,
        multi_dropdown = false,
        maximum_options = 7,
        Order = true,
        OrderValue = #Color_Targets + 1,
        callback = function(value)
            Selected_Pill_Preset = (typeof(value) == 'string' and value) or value.Name

            if library._ui_open then
                return
            end

            apply_pill_preset()
        end
    })

    color_module._size = 240
    Options.Size = UDim2.fromOffset(241, color_module._size)

    if color_module._state then
        color_module:change_state(true)
    end
end

local Background_Image = library._ui.Container:FindFirstChild('Background')
local Saved_Background_Id = Library._config._flags['Background_Image_Id']
local Background_Image_Id = (typeof(Saved_Background_Id) == 'string' and Saved_Background_Id) or ''
local Custom_Asset = getcustomasset or getsynasset
local Background_Folder = 'Zuro/Backgrounds'

if Custom_Asset and not isfolder(Background_Folder) then
    makefolder(Background_Folder)
end

local function resolve_background(source: string)
    if source == '' then
        return ''
    end

    if source:match('^%d+$') then
        return 'rbxassetid://'..source
    end

    if source:match('^rbx%a+://') then
        return source
    end

    if not Custom_Asset then
        return ''
    end

    if not source:match('^https?://') then
        return (isfile(source) and Custom_Asset(source)) or ''
    end

    local extension = source:match('%.(%a%a%a%a?)[%?#]') or source:match('%.(%a%a%a%a?)$') or 'png'
    local path = Background_Folder..'/'..source:gsub('%W', ''):sub(-48)..'.'..extension

    if not isfile(path) then
        local success, body = pcall(game.HttpGet, game, source, true)

        if not success then
            return ''
        end

        writefile(path, body)
    end

    return Custom_Asset(path)
end

local function set_background_image(source: string)
    if not Background_Image then
        return
    end

    Background_Image.Image = resolve_background(source)
end

local Transparent_Targets = { Module = true, Box = true, Keybind = true, Reset = true, AssetId = true }

local function set_module_transparency(value: number)
    for _, object in library._ui:GetDescendants() do
        if Transparent_Targets[object.Name] then
            object.BackgroundTransparency = value
        end
    end
end

local Background_Presets = {
    ['Preset 1'] = 'https://i.pinimg.com/736x/74/1e/ad/741ead9813c27462a14c4d134114435b.jpg',
    ['Preset 2'] = 'https://i.pinimg.com/736x/c3/df/ab/c3dfab11deba78345b4330b2f9d147b0.jpg',
    ['Preset 3'] = 'https://i.pinimg.com/736x/53/7c/f6/537cf6b7b7b545c5e9c618450f5bb1fe.jpg',
    ['Preset 4'] = 'https://i.pinimg.com/736x/55/9f/cb/559fcb79fa2f5b0cba7a6a9d85fdd112.jpg',
    ['Preset 5'] = 'https://i.pinimg.com/1200x/08/84/74/088474af27fa27d94372360fe0df0f6e.jpg',
    ['Preset 6'] = 'https://i.pinimg.com/736x/84/8a/2f/848a2fb0ff4ad249b2db6c490a270fec.jpg',
    ['Preset 7'] = 'https://i.pinimg.com/736x/2a/83/9d/2a839d184d7e2676dd1232dfa7bd98c9.jpg',
    ['Preset 8'] = 'https://i.pinimg.com/736x/0b/a9/38/0ba938f76c91d60e705cfdd11b798c31.jpg',
    ['Preset 9'] = 'https://i.pinimg.com/736x/d7/82/26/d7822671566a7cbf79cd1389c1119d93.jpg',
    ['Preset 10'] = 'https://i.pinimg.com/736x/d8/17/70/d817701d42948a2ae9692cb0290e240b.jpg'
}

local Preset_Options = { 'None', 'Preset 1', 'Preset 2', 'Preset 3', 'Preset 4', 'Preset 5', 'Preset 6', 'Preset 7', 'Preset 8', 'Preset 9', 'Preset 10' }
local Asset_Input

local image_module = Interface:create_module({
    title = 'Background',
    flag = 'Background_Image',
    description = 'Pick the Image Background',
    section = 'right',
    callback = function(state)
        if not Background_Image then
            return
        end

        Background_Image.Visible = state

        if state then
            set_module_transparency((Library._config._flags['Background_Module_Transparency'] or 0) / 100)
            return
        end

        set_module_transparency(0)
    end
})

local preset_dropdown = image_module:create_dropdown({
    title = 'Preset',
    flag = 'Background_Preset',
    options = Preset_Options,
    multi_dropdown = false,
    maximum_options = 4,
    callback = function(value)
        local name = (typeof(value) == 'string' and value) or (typeof(value) == 'table' and value.Name)
        local source = (name and Background_Presets[name]) or ''

        Background_Image_Id = source
        set_background_image(source)

        if Asset_Input then
            Asset_Input.Text = source
        end

        Library._config._flags['Background_Image_Id'] = source
    end
})

local transparency_slider = image_module:create_slider({
    title = 'Transparency',
    flag = 'Background_Image_Transparency',
    minimum_value = 0,
    maximum_value = 100,
    value = 50,
    round_number = true,
    callback = function(value)
        if not Background_Image then
            return
        end

        Background_Image.ImageTransparency = value / 100
    end
})

local module_transparency_slider = image_module:create_slider({
    title = 'Module Transparency',
    flag = 'Background_Module_Transparency',
    minimum_value = 0,
    maximum_value = 100,
    value = 0,
    round_number = true,
    callback = function(value)
        set_module_transparency(value / 100)
    end
})

local Image_Module_Frame = find_module_frame('Background')

if Image_Module_Frame then
    local Options = Image_Module_Frame.Options

    local Row = Instance.new('Frame')
    Row.Name = 'AssetRow'
    Row.Size = UDim2.fromOffset(207, 24)
    Row.BackgroundTransparency = 1
    Row.BorderSizePixel = 0
    Row.LayoutOrder = 0
    Row.Parent = Options

    local Input = Instance.new('TextBox')
    Input.Name = 'AssetId'
    Input.AnchorPoint = Vector2.new(0, 0.5)
    Input.Position = UDim2.new(0, 0, 0.5, 0)
    Input.Size = UDim2.fromOffset(207, 22)
    Input.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
    Input.BorderSizePixel = 0
    Input.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
    Input.TextColor3 = Color3.fromRGB(202, 202, 209)
    Input.PlaceholderColor3 = Color3.fromRGB(138, 138, 138)
    Input.PlaceholderText = 'Asset ID or Image Link'
    Input.TextSize = 12
    Input.ClearTextOnFocus = false
    Input.ClipsDescendants = true
    Input.Text = Background_Image_Id
    Input.Parent = Row

    Asset_Input = Input

    local InputCorner = Instance.new('UICorner')
    InputCorner.CornerRadius = UDim.new(0, 4)
    InputCorner.Parent = Input

    local InputStroke = Instance.new('UIStroke')
    InputStroke.Color = Color3.fromRGB(255, 255, 255)
    InputStroke.Transparency = 0.72
    InputStroke.Thickness = 1
    InputStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    InputStroke.Parent = Input

    Input.FocusLost:Connect(function()
        local source = Input.Text:match('^%s*(.-)%s*$')

        Input.Text = source
        Background_Image_Id = source
        set_background_image(source)

        Library._config._flags['Background_Image_Id'] = source
    end)

    build_reset_button(Options, 4, function()
        Input.Text = ''
        Background_Image_Id = ''
        set_background_image('')

        preset_dropdown:update('None')
        transparency_slider:set_percentage(50)
        module_transparency_slider:set_percentage(0)

        Library._config._flags['Background_Image_Id'] = ''
    end)

    image_module._size += 62
    Options.Size = UDim2.fromOffset(241, image_module._size)

    if image_module._state then
        image_module:change_state(true)
    end
end

set_background_image(Background_Image_Id)
set_module_transparency((Library._config._flags['Background_Module_Transparency'] or 0) / 100)

local hide_ui_module = Interface:create_module({
    title = 'Hide Interface',
    flag = 'UI_Gui_Visible',
    description = 'Hide the entire interface',
    section = 'right',
    callback = function(state)
        getgenv().UI_Gui_Visible = state
    end,
})

if hide_ui_module._state then
    hide_ui_module:change_state(true)
end

local minimize_keybind_module = Interface:create_module({
    title = 'Minimize Keybind',
    flag = 'Minimize_Keybind_Module',
    description = 'Set a custom key to minimize the UI',
    section = 'left',
    callback = function() end,
})

minimize_keybind_module:create_keybind_row({
    title = 'Minimize Key',
    flag = 'Minimize_Keybind',
    callback = function() end,
})

minimize_keybind_module._size += 6
if minimize_keybind_module._state then
    minimize_keybind_module:change_state(true)
end

do
local config_module = Interface:create_module({
    title = 'Configuration',
    flag = 'Config_Module',
    description = 'Set your configuration to your settings',
    section = 'right',
    callback = function() end,
})

local _last_profile_path = 'Zuro/last_profile.txt'
local _cfg_name = 'default'

    local function _get_profiles()
        local files = {}
        local ok, result = pcall(listfiles, 'Zuro/profiles')
        if ok and result then
            for _, path in ipairs(result) do
                local name = path:match('([^/\\]+)%.json$')
                if name then table.insert(files, name) end
            end
        end
        return files
    end

    local function _apply_config(cfg, reset_all)
        if reset_all then
            for flag, fn in pairs(Library._flag_registry) do
                local current = Library._config._flags[flag]
                if typeof(current) == 'boolean' and current ~= false then
                    pcall(fn, false)
                end
            end
            Library._config = cfg
        end
        for flag, value in pairs(cfg._flags or {}) do
            local fn = Library._flag_registry[flag]
            if fn then pcall(fn, value) end
        end
    end

    pcall(function() makefolder('Zuro/profiles') end)

    if isfile(_last_profile_path) then
        local last_name = readfile(_last_profile_path):gsub('%s+', '')
        if last_name ~= '' then
            local path = 'Zuro/profiles/' .. last_name .. '.json'
            if isfile(path) then
                local ok, result = pcall(function()
                    return HttpService:JSONDecode(readfile(path))
                end)
                if ok and result then
                    task.defer(function() _apply_config(result) end)
                end
            end
        end
    end

    local _profiles_dd = config_module:create_dropdown({
        title = 'Profiles',
        flag = 'Config_Profile_Select',
        options = (function()
            local p = _get_profiles()
            table.insert(p, 1, 'Default')
            return p
        end)(),
        multi_dropdown = false,
        maximum_options = 10,
        callback = function(value)
            local name = typeof(value) == 'string' and value or (value and value.Name)
            if name then _cfg_name = name end
        end,
    })

    local _name_box = config_module:create_textbox({
        placeholder = 'name...',
        value = '',
        callback = function(text)
            local clean = text:gsub('[^%w_%-]', ''):lower()
            if clean == '' then clean = 'default' end
            _cfg_name = clean
            _name_box.Text = clean
        end,
    })

    config_module:create_button({
        title = 'Save Config',
        callback = function()
            pcall(function() makefolder('Zuro/profiles') end)
            local ok = pcall(function()
                writefile('Zuro/profiles/' .. _cfg_name .. '.json', HttpService:JSONEncode(Library._config))
            end)
            if ok then
                local p = _get_profiles()
                table.insert(p, 1, 'Default')
                _profiles_dd:refresh(p)
                Library.SendNotification({ title = 'Configuration', text = 'Saved: ' .. _cfg_name, duration = 3 })
            else
                Library.SendNotification({ title = 'Configuration', text = 'Save failed', duration = 3 })
            end
        end,
    })

    config_module:create_button({
        title = 'Load Config',
        callback = function()
            if _cfg_name == 'Default' then
                _apply_config({ _flags = {}, _keybinds = {} }, true)
                Library.SendNotification({ title = 'Configuration', text = 'Config reset', duration = 3 })
                return
            end
            local path = 'Zuro/profiles/' .. _cfg_name .. '.json'
            if not isfile(path) then
                Library.SendNotification({ title = 'Configuration', text = 'Not found: ' .. _cfg_name, duration = 3 })
                return
            end
            local ok, result = pcall(function() return HttpService:JSONDecode(readfile(path)) end)
            if ok and result then
                _apply_config(result, true)
                pcall(function() writefile(_last_profile_path, _cfg_name) end)
                Library.SendNotification({ title = 'Configuration', text = 'Loaded: ' .. _cfg_name, duration = 3 })
            else
                Library.SendNotification({ title = 'Configuration', text = 'Load failed', duration = 3 })
            end
        end,
    })

    config_module:create_button({
        title = 'Delete Config',
        callback = function()
            local path = 'Zuro/profiles/' .. _cfg_name .. '.json'
            if not isfile(path) then
                Library.SendNotification({ title = 'Configuration', text = 'Not found: ' .. _cfg_name, duration = 3 })
                return
            end
            pcall(function() delfile(path) end)
            local p = _get_profiles()
            table.insert(p, 1, 'Default')
            _profiles_dd:refresh(p)
            Library.SendNotification({ title = 'Configuration', text = 'Deleted: ' .. _cfg_name, duration = 3 })
        end,
    })

    config_module._size += 6

if config_module._state then
    config_module:change_state(true)
end
end

library:removed(function()
    cleanup_visual_stats()
    pcall(function() if getgenv()._Zuro_TB_Stop then getgenv()._Zuro_TB_Stop() end end)
    pcall(function() if getgenv()._Zuro_ESP_Stop then getgenv()._Zuro_ESP_Stop() end end)
    pcall(function() if getgenv()._Zuro_StaffDet_Stop then getgenv()._Zuro_StaffDet_Stop() end end)
    stop_force_stats()
    if Target_Lock_Highlight then
        Target_Lock_Highlight:Destroy()
        Target_Lock_Highlight = nil
    end
    if Target_Lock_Label then
        Target_Lock_Label:Destroy()
        Target_Lock_Label = nil
    end
    Selected_Target = nil
    Manual_Spam.Enabled = false
    Manual_Spam.Active = false
    Manual_Spam.Stop()
    destroy_manual_spam_overlay()
    destroy_cps_counter()
    destroy_curve_overlay()
    if Cosmetics_CharConn then
        Cosmetics_CharConn:Disconnect()
        Cosmetics_CharConn = nil
    end
    pcall(function()
        if getgenv()._Zuro_AntiLag_Cleanup then
            getgenv()._Zuro_AntiLag_Cleanup()
        end
    end)
    if Connections_Manager["Auto Parry"] then
        Connections_Manager["Auto Parry"]:Disconnect()
        Connections_Manager["Auto Parry"] = nil
    end
    if Connections_Manager["Auto Spam"] then
        Connections_Manager["Auto Spam"]:Disconnect()
        Connections_Manager["Auto Spam"] = nil
    end
    kill_preclick_stop()
    pcall(function()
        if getgenv()._Zuro_TD_Stop then getgenv()._Zuro_TD_Stop() end
    end)
end)

getgenv()._Zuro_Cleanup = function()
    pcall(function() Connections:disconnect_all() end)
    for key in Connections_Manager do
        if typeof(Connections_Manager[key]) == 'RBXScriptConnection' then
            pcall(function() Connections_Manager[key]:Disconnect() end)
        end
    end
end

return Library