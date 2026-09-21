local UI = {}
function UI:Init(Manager)
    if not Manager.Cache.NormalUILoaded then return end
    if Manager.Cache.RayfieldModified then return end
    Manager.Cache.RayfieldModified = true

    local Window = Manager.Window

    --## HEADER ##--
    if type(Window.settings) == "table" then
        Window.settings.toggleKeybind = Enum.KeyCode.LeftControl
    end
    local TitleRow = Window:Create("Frame", {
        Name = "TitleRow",
        Size = UDim2.fromOffset(0, 22),
        AutomaticSize = Enum.AutomaticSize.X,
        BackgroundTransparency = 1,
        LayoutOrder = 1,
        Parent = Window.titleContainer,
    })
    Window:Create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 8),
        Parent = TitleRow,
    })
    Window.title.Parent = TitleRow
    Window:_bindLocale(Window.title, "Text", "Angel Hub")
    Window.title.TextWrapped = false
    Window.title.LayoutOrder = 1
    Window.title.TextSize = 21
    Window.title.Size = UDim2.fromOffset(50, 22)
    Window.subtitle.LayoutOrder = 2
    Window.subtitle.TextSize = 13
    Window.subtitle.Size = UDim2.fromOffset(50, 15)
    Window.tagContainer.Parent = TitleRow
    Window.tagContainer.LayoutOrder = 2
    local VersionTag = Window:CreateTag({ text = "v1.2.0", color = Window.theme.AccentColor })
    
    --## WINDOW SIZE ##--
    local InputService = game:GetService("UserInputService")
    local TweenService = game:GetService("TweenService")
    local DesiredSize = Vector2.new(850, 610)
    local Resizing = nil
    local function FittedSize(Requested, Viewport)
        local MaxX = math.max(1, Viewport.X - 24)
        local MaxY = math.max(1, Viewport.Y - 40)
        return Vector2.new(
            math.clamp(Requested.X, math.min(480, MaxX), MaxX),
            math.clamp(Requested.Y, math.min(340, MaxY), MaxY)
        )
    end
    local function ApplySize()
        if Window.unloaded then return end
        local Size = FittedSize(DesiredSize, Window.screenGui.AbsoluteSize)
        local Target = UDim2.fromOffset(Size.X, Size.Y)
        local Changed = Window.size ~= Target
        Window.size = Target
        if Window.hidden or Window.minimised or Window.animating or Window._revealing then
            Window._pendingResize = Window._pendingResize or Changed
            return
        end
        if Changed or Window._pendingResize or Window.main.Size ~= Target then
            Window._pendingResize = false
            Window.main.Size = Target
            Window:_applyRailWidth()
            Window:_clampToScreen()
            Window:_syncDragBar()
        end
    end
    Window._applyWindowSize = ApplySize
    local ResizeGrip = Window:Create("Frame", {
        Name = "ResizeGrip",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(1, 1),
        Size = UDim2.fromOffset(40, 40),
        BackgroundTransparency = 1,
        ZIndex = 1100,
        Parent = Window.main,
    })
    local ResizeGlyph = Window:Create("ImageLabel", {
        Name = "Glyph",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, -8, 0.5, -8),
        Size = UDim2.fromOffset(80, 80),
        BackgroundTransparency = 1,
        Image = "rbxassetid://120997033468887",
        ImageTransparency = 0.8,
        ZIndex = 1101,
        Parent = ResizeGrip,
    }, { ImageColor3 = "ContentColor" })
    local ResizeTween
    local function SetGripTransparency(Value)
        if ResizeTween then ResizeTween:Cancel() end
        ResizeTween = TweenService:Create(
            ResizeGlyph,
            TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
            { ImageTransparency = Value }
        )
        ResizeTween:Play()
    end
    local ResizeHandle = Window:Create("TextButton", {
        Name = "ResizeHandle",
        Text = "",
        AutoButtonColor = false,
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Active = true,
        ZIndex = 1102,
        Parent = ResizeGrip,
    })
    local function StopResize()
        Resizing = nil
        SetGripTransparency(0.8)
    end
    Window:Connect(ResizeHandle.MouseEnter, function()
        if not Resizing then SetGripTransparency(0.35) end
    end)
    Window:Connect(ResizeHandle.MouseLeave, function()
        if not Resizing then SetGripTransparency(0.8) end
    end)
    Window:Connect(ResizeHandle.InputBegan, function(Input)
        if Input.UserInputType ~= Enum.UserInputType.MouseButton1
            and Input.UserInputType ~= Enum.UserInputType.Touch then return end
        if Window.hidden or Window.minimised or Window.animating or Window._revealing then return end
        Resizing = {
            Input = Input,
            Pointer = Vector2.new(Input.Position.X, Input.Position.Y),
            Size = Window.main.AbsoluteSize,
            Origin = Vector2.new(
                Window.main.Position.X.Scale * Window.screenGui.AbsoluteSize.X + Window.main.Position.X.Offset,
                Window.main.Position.Y.Scale * Window.screenGui.AbsoluteSize.Y + Window.main.Position.Y.Offset
            ) - Window.main.AbsoluteSize * Window.main.AnchorPoint,
        }
        SetGripTransparency(0)
    end)
    Window:Connect(InputService.InputChanged, function(Input)
        if not Resizing then return end
        if Window.hidden or Window.minimised or Window.animating or Window._revealing then
            StopResize()
            return
        end
        local Touch = Resizing.Input.UserInputType == Enum.UserInputType.Touch
        if Touch and Input ~= Resizing.Input then return end
        if not Touch and Input.UserInputType ~= Enum.UserInputType.MouseMovement then return end
        local Delta = Vector2.new(Input.Position.X, Input.Position.Y) - Resizing.Pointer
        local Viewport = Window.screenGui.AbsoluteSize
        local Size = FittedSize(Resizing.Size + Delta, Viewport)
        local Origin = Resizing.Origin
        DesiredSize = Vector2.new(
            math.round(math.min(Size.X, math.max(1, Viewport.X - Origin.X - 8))),
            math.round(math.min(Size.Y, math.max(1, Viewport.Y - Origin.Y - 8)))
        )
        local Anchor = Window.main.AnchorPoint
        Window.main.Position = UDim2.fromOffset(
            Origin.X + DesiredSize.X * Anchor.X,
            Origin.Y + DesiredSize.Y * Anchor.Y
        )
        ApplySize()
    end)
    Window:Connect(InputService.InputEnded, function(Input)
        if Resizing and (Input == Resizing.Input
            or Input.UserInputType == Enum.UserInputType.MouseButton1) then
            StopResize()
        end
    end)
    Window:Connect(InputService.WindowFocusReleased, StopResize)
    Window:Connect(Window.main:GetPropertyChangedSignal("Size"), function()
        ResizeGrip.Visible = not Window.hidden and not Window.minimised
            and Window.main.Size.Y.Offset > Window.layout.topbarHeight + 30
    end)
    ApplySize()
    end

return UI
