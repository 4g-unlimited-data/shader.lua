-- [[ vanut v6.4 / rimuru tempest - Ultimate Minimalist Mobile Edition ]] --
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer

-- System tracking tables for complete cleanup
local connections = {}
local isGuiDestroyed = false
local isApplying = false

-- Cache default settings safely
local defaults = {
    Ambient = Lighting.Ambient,
    OutdoorAmbient = Lighting.OutdoorAmbient,
    Brightness = Lighting.Brightness,
    ExposureCompensation = Lighting.ExposureCompensation,
    GlobalShadows = Lighting.GlobalShadows,
    EnvironmentSpecularScale = Lighting.EnvironmentSpecularScale,
    EnvironmentDiffuseScale = Lighting.EnvironmentDiffuseScale,
    ClockTime = Lighting.ClockTime,
    FogStart = Lighting.FogStart,
    FogEnd = Lighting.FogEnd,
    ColorShift_Top = Lighting.ColorShift_Top,
    ColorShift_Bottom = Lighting.ColorShift_Bottom,
}

-- Fix 1: Thay thế WaitForChild vô tận bằng timeout 10s + Fallback CoreGui chuẩn xác
local targetGui = player:WaitForChild("PlayerGui", 10)
if not targetGui then 
    targetGui = game:GetService("CoreGui") 
end

-- Remove any old instances to avoid duplicates
if targetGui:FindFirstChild("Vanut_Rimuru_v64") then 
    pcall(function() targetGui["Vanut_Rimuru_v64"]:Destroy() end) 
end

-- Optimization: Safe Property Setter to prevent engine access crashes
local function safeSet(property, value)
    pcall(function()
        Lighting[property] = value
    end)
end

local function create(cls, parent, props)
    local inst = Instance.new(cls)
    for k, v in pairs(props or {}) do inst[k] = v end
    if parent then inst.Parent = parent end
    return inst
end

local function addCorner(parent, r) create("UICorner", parent, {CornerRadius = UDim.new(0, r or 6)}) end
local function addStroke(parent) create("UIStroke", parent, {Color = Color3.fromRGB(15, 30, 50), Thickness = 1.2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}) end

-- Master Clean Routine
local function clearCustomEffects()
    for _, obj in ipairs(Lighting:GetChildren()) do
        if obj and obj:GetAttribute("ShaderHub") then
            pcall(function() obj:Destroy() end)
        end
    end
end

-- Fix 5: Ép cấu hình ScreenGui với DisplayOrder cao nhất để tránh bị đè/ignore
local ScreenGui = create("ScreenGui", targetGui, {
    Name = "Vanut_Rimuru_v64", 
    ResetOnSpawn = false, 
    ZIndexBehavior = Enum.ZIndexBehavior.Global,
    DisplayOrder = 999, 
    IgnoreGuiInset = true,
    Enabled = true
})

local function destroyGuiAndDisconnect()
    if isGuiDestroyed then return end
    isGuiDestroyed = true
    
    for _, connection in ipairs(connections) do
        if connection and connection.Connected then
            pcall(function() connection:Disconnect() end)
        end
    end
    table.clear(connections)
    clearCustomEffects()
    
    if ScreenGui then
        ScreenGui.Enabled = false
        if ScreenGui.Parent then
            pcall(function() ScreenGui:Destroy() end)
        end
    end
end

pcall(function()
    game:BindToClose(destroyGuiAndDisconnect)
end)

local function updateGlossiness()
    local ratio = currentGloss / 100
    safeSet("EnvironmentSpecularScale", ratio)
    if currentGloss > 60 then
        safeSet("EnvironmentDiffuseScale", ratio * 0.6)
    else
        safeSet("EnvironmentDiffuseScale", defaults.EnvironmentDiffuseScale)
    end
end

local function resetLightingComplete()
    clearCustomEffects()
    safeSet("GlobalShadows", defaults.GlobalShadows)
    safeSet("Brightness", defaults.Brightness)
    safeSet("Ambient", defaults.Ambient)
    safeSet("OutdoorAmbient", defaults.OutdoorAmbient)
    safeSet("ExposureCompensation", defaults.ExposureCompensation)
    safeSet("EnvironmentSpecularScale", defaults.EnvironmentSpecularScale)
    safeSet("EnvironmentDiffuseScale", defaults.EnvironmentDiffuseScale)
    safeSet("ClockTime", defaults.ClockTime)
    safeSet("FogStart", defaults.FogStart)
    safeSet("FogEnd", defaults.FogEnd)
    safeSet("ColorShift_Top", defaults.ColorShift_Top)
    safeSet("ColorShift_Bottom", defaults.ColorShift_Bottom)
end

-- UI Toggle Configuration Base Setup
-- Fix 2 & 4: Bật Visible = true ngay lập tức, sửa lại tọa độ chống lệch màn hình mobile
local ToggleMenuBtn = create("TextButton", ScreenGui, {
    Size = UDim2.new(0, 36, 0, 36),
    Position = UDim2.new(0, 10, 0, 10),
    AnchorPoint = Vector2.new(0, 0),
    BackgroundColor3 = Color3.fromRGB(12, 22, 40),
    Text = "⚙️",
    TextColor3 = Color3.fromRGB(0, 215, 255),
    Font = Enum.Font.GothamBold,
    TextSize = 16,
    Visible = true, 
    Active = false,
    ZIndex = 5
}) addCorner(ToggleMenuBtn, 18) addStroke(ToggleMenuBtn)

local MainMenu = create("Frame", ScreenGui, {
    Size = UDim2.new(0, 340, 0, 260),
    Position = UDim2.new(0.5, -170, 0.35, -130),
    BackgroundColor3 = Color3.fromRGB(10, 16, 28),
    Visible = false,
    Active = false,
    ZIndex = 10
}) addCorner(MainMenu, 8) addStroke(MainMenu)

create("TextLabel", MainMenu, {
    Size = UDim2.new(1, 0, 0, 30),
    BackgroundColor3 = Color3.fromRGB(16, 26, 44),
    Text = "BẢNG ĐIỀU KHIỂN - RIMURU ENGINE V6.4 SHADER",
    TextColor3 = Color3.fromRGB(255, 255, 255),
    Font = Enum.Font.GothamBold,
    TextSize = 11,
    ZIndex = 11
}) addCorner(MainMenu:FindFirstChildOfClass("TextLabel"), 8)

table.insert(connections, ToggleMenuBtn.Activated:Connect(function()
    if isGuiDestroyed then return end
    MainMenu.Visible = not MainMenu.Visible
end))

local TabContainer = create("Frame", MainMenu, {Size = UDim2.new(1, 0, 0, 28), Position = UDim2.new(0, 0, 0, 30), BackgroundColor3 = Color3.fromRGB(14, 22, 38), ZIndex = 11})
local ContentContainer = create("Frame", MainMenu, {Size = UDim2.new(1, -12, 1, -68), Position = UDim2.new(0, 6, 0, 62), BackgroundTransparency = 1, ZIndex = 11})
local Pages = {}

local function createTab(name, order, pageFrame)
    pageFrame.Size, pageFrame.BackgroundTransparency, pageFrame.Visible, pageFrame.Parent = UDim2.new(1, 0, 1, 0), 1, false, ContentContainer
    Pages[name] = pageFrame
    
    local tBtn = create("TextButton", TabContainer, {
        Size = UDim2.new(0.5, 0, 1, 0), 
        Position = UDim2.new(0.5 * (order - 1), 0, 0, 0), 
        BackgroundColor3 = Color3.fromRGB(18, 28, 46), 
        Text = name, 
        TextColor3 = Color3.fromRGB(140, 160, 180), 
        Font = Enum.Font.GothamBold, 
        TextSize = 10, 
        BorderSizePixel = 0, 
        ZIndex = 12
    })
    
    table.insert(connections, tBtn.Activated:Connect(function()
        if isGuiDestroyed then return end
        for k, p in pairs(Pages) do p.Visible = (k == name) end
        for _, btn in pairs(TabContainer:GetChildren()) do if btn:IsA("TextButton") then btn.BackgroundColor3, btn.TextColor3 = Color3.fromRGB(18, 28, 46), Color3.fromRGB(140, 160, 180) end end
        tBtn.BackgroundColor3, tBtn.TextColor3 = Color3.fromRGB(24, 42, 70), Color3.fromRGB(0, 210, 255)
    end))
    if order == 1 then tBtn.BackgroundColor3, tBtn.TextColor3, pageFrame.Visible = Color3.fromRGB(24, 42, 70), Color3.fromRGB(0, 210, 255), true end
end

local function makeDraggable(f, h)
    local dragging, dragInput, dragStart, startPos
    table.insert(connections, h.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = f.Position
            
            local changeCon
            changeCon = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then 
                    dragging = false 
                    if changeCon then changeCon:Disconnect() end
                end
            end)
            table.insert(connections, changeCon)
        end
    end))
    table.insert(connections, h.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
    end))
    table.insert(connections, f.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            f.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end))
end

makeDraggable(ToggleMenuBtn, ToggleMenuBtn) 
makeDraggable(MainMenu, MainMenu:FindFirstChildOfClass("TextLabel"))

-- =======================================================================
-- TAB 1: SHADER ENGINE
-- =======================================================================
local PageShader = create("ScrollingFrame", nil, {CanvasSize = UDim2.new(0, 0, 0, 310), ScrollBarThickness = 2, BackgroundTransparency = 1, BorderSizePixel = 0, Active = false, ScrollingEnabled = true, ZIndex = 12}) create("UIListLayout", PageShader, {Padding = UDim.new(0, 4)})

local function buildProtectedCallback(applyFunc)
    return function()
        if isApplying or isGuiDestroyed then return end
        isApplying = true
        resetLightingComplete()
        pcall(applyFunc)
        updateGlossiness()
        isApplying = false
    end
end

local function createShaderConfig(cls, props)
    local inst = create(cls, Lighting, props)
    inst:SetAttribute("ShaderHub", true)
    return inst
end

local shaderFuncs = {
    {"1: Bình minh vàng ấm áp", function() 
        safeSet("ClockTime", 6.2)
        safeSet("OutdoorAmbient", Color3.fromRGB(255, 225, 160))
        safeSet("Brightness", 1.8)
        createShaderConfig("SunRaysEffect", {Intensity = 0.25, Spread = 0.6}) 
    end},
    {"2: Trưa nắng rực rỡ sắc nét", function() 
        safeSet("ClockTime", 12)
        safeSet("OutdoorAmbient", Color3.fromRGB(150, 150, 150))
        safeSet("Brightness", 2.0)
        createShaderConfig("SunRaysEffect", {Intensity = 0.3, Spread = 0.5}) 
        createShaderConfig("BloomEffect", {Intensity = 0.2, Size = 10, Threshold = 0.9}) 
    end},
    {"3: Hoàng hôn ánh hồng lãng mạn", function() 
        safeSet("ClockTime", 17.8)
        safeSet("OutdoorAmbient", Color3.fromRGB(255, 170, 120))
        safeSet("Brightness", 1.7)
        createShaderConfig("SunRaysEffect", {Intensity = 0.3, Spread = 0.65}) 
    end},
    {"4: Đêm xanh huyền ảo", function() 
        safeSet("ClockTime", 0)
        safeSet("Ambient", Color3.fromRGB(55, 60, 85))
        safeSet("OutdoorAmbient", Color3.fromRGB(35, 40, 60))
        safeSet("Brightness", 1.2)
        createShaderConfig("Sky", {SkyboxBk = "rbxassetid://6008860012", SkyboxDn = "rbxassetid://6008860012", SkyboxFt = "rbxassetid://6008860012", SkyboxLf = "rbxassetid://6008860012", SkyboxRt = "rbxassetid://6008860012", SkyboxUp = "rbxassetid://6008860012", StarCount = 3000, CelestialBodiesShown = true})
    end},
    {"✨ 5: Cinematic Lofi (Dịu mát chiều sâu)", function() 
        safeSet("ClockTime", 16.5)
        safeSet("Brightness", 1.8)
        createShaderConfig("ColorCorrectionEffect", {Saturation = -0.1, Contrast = 0.1, TintColor = Color3.fromRGB(255, 240, 220)}) 
        createShaderConfig("BloomEffect", {Intensity = 0.15, Size = 8, Threshold = 0.92}) 
    end},
    {"✨ 6: Cyberpunk Neon (Tương phản cao)", function() 
        safeSet("ClockTime", 19)
        safeSet("Brightness", 1.9)
        createShaderConfig("ColorCorrectionEffect", {Saturation = 0.25, Contrast = 0.15, TintColor = Color3.fromRGB(230, 220, 255)}) 
        createShaderConfig("BloomEffect", {Intensity = 0.4, Size = 18, Threshold = 0.6}) 
    end}
}

for i, data in ipairs(shaderFuncs) do
    local sb = create("TextButton", PageShader, {Size = UDim2.new(1, -4, 0, 32), BackgroundColor3 = Color3.fromRGB(22, 38, 64), Text = "   " .. data[1], TextColor3 = Color3.fromRGB(200, 230, 255), Font = Enum.Font.Gotham, TextSize = 10, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 13}) addCorner(sb, 4) addStroke(sb)
    table.insert(connections, sb.Activated:Connect(buildProtectedCallback(data[2])))
end

local ClearShaderBtn = create("TextButton", PageShader, {Size = UDim2.new(1, -4, 0, 32), BackgroundColor3 = Color3.fromRGB(110, 35, 40), Text = "❌ XÓA TOÀN BỘ CẤU HÌNH SHADER", TextColor3 = Color3.fromRGB(255, 255, 255), Font = Enum.Font.GothamBold, TextSize = 10, ZIndex = 13}) addCorner(ClearShaderBtn, 4) addStroke(ClearShaderBtn)
table.insert(connections, ClearShaderBtn.Activated:Connect(buildProtectedCallback(function() resetLightingComplete() end)))

createTab("Shader", 1, PageShader)

-- =======================================================================
-- TAB 2: ĐỘ BÓNG NÂNG CAO
-- =======================================================================
local PageGloss = create("Frame", nil, {ZIndex = 12})
local SliderTitle = create("TextLabel", PageGloss, {Size = UDim2.new(1, 0, 0, 20), Position = UDim2.new(0, 0, 0, 15), BackgroundTransparency = 1, Text = "ĐỘ BÓNG BỀ MẶT PHẢN CHIẾU: 20 %", TextColor3 = Color3.fromRGB(0, 255, 180), Font = Enum.Font.GothamBold, TextSize = 10, ZIndex = 13})
local SliderTrack = create("Frame", PageGloss, {Size = UDim2.new(1, -40, 0, 6), Position = UDim2.new(0, 20, 0, 45), BackgroundColor3 = Color3.fromRGB(25, 38, 60), ZIndex = 13}) addCorner(SliderTrack, 3)
local SliderFill = create("Frame", SliderTrack, {Size = UDim2.new(0.2, 0, 1, 0), BackgroundColor3 = Color3.fromRGB(0, 215, 255), ZIndex = 13}) addCorner(SliderFill, 3)
local SliderBtn = create("TextButton", SliderTrack, {Size = UDim2.new(0, 14, 0, 14), Position = UDim2.new(0.2, -7, 0.5, -7), BackgroundColor3 = Color3.fromRGB(255, 255, 255), Text = "", ZIndex = 14}) addCorner(SliderBtn, 7) addStroke(SliderBtn)

local sliderDragging = false
local function updateSlider(input)
    local pct = math.clamp((input.Position.X - SliderTrack.AbsolutePosition.X) / SliderTrack.AbsoluteSize.X, 0, 1)
    SliderBtn.Position = UDim2.new(pct, -7, 0.5, -7)
    SliderFill.Size = UDim2.new(pct, 0, 1, 0)
    currentGloss = math.clamp(math.floor(pct * 100), 0, 100)
    SliderTitle.Text = "ĐỘ BÓNG BỀ MẶT PHẢN CHIẾU: " .. currentGloss .. " %"
    updateGlossiness()
end

table.insert(connections, SliderBtn.InputBegan:Connect(function(i) 
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then sliderDragging = true end 
end))
table.insert(connections, UserInputService.InputChanged:Connect(function(i) 
    if sliderDragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then updateSlider(i) end 
end))
table.insert(connections, UserInputService.InputEnded:Connect(function(i) 
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then sliderDragging = false end 
end))

pcall(function()
    table.insert(connections, UserInputService.WindowFocusReleased:Connect(function()
        sliderDragging = false
    end))
end)

create("TextLabel", PageGloss, {
    Size = UDim2.new(1, -20, 0, 100), 
    Position = UDim2.new(0, 10, 0, 75), 
    BackgroundTransparency = 1, 
    Text = "🪞 Công nghệ Raycast Specular V6.4:\nKhi kéo từ 0% lên 100%, mặt đất sẽ tăng cường độ phản quang vật lý. Khi đặt mức cao (>70%), hệ thống sẽ đồng bộ hóa góc chiếu sáng môi trường để hiển thị rõ ràng bóng đổ của người chơi cùng với màu sắc phản chiếu từ Skybox (bầu trời) xuống bề mặt Map gạch nhẵn.", 
    TextColor3 = Color3.fromRGB(150, 175, 210), 
    Font = Enum.Font.Gotham, 
    TextSize = 10, 
    TextWrapped = true, 
    TextXAlignment = Enum.TextXAlignment.Left, 
    TextYAlignment = Enum.TextYAlignment.Top, 
    ZIndex = 13
})

createTab("Độ Bóng", 2, PageGloss)

-- =======================================================================
-- LOADING BAR SEQUENCER INTERACTION TREE
-- =======================================================================
local LoadingGui = Instance.new("ScreenGui")
LoadingGui.Name = "vanut_FPS_v64_LoadingScreen"
LoadingGui.ResetOnSpawn = false
LoadingGui.IgnoreGuiInset = true
LoadingGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
LoadingGui.DisplayOrder = 999
LoadingGui.Parent = targetGui

local LoadingFrame = Instance.new("Frame")
LoadingFrame.Name = "LoadingFrame"
LoadingFrame.Size = UDim2.new(0, 290, 0, 100)
LoadingFrame.Position = UDim2.new(0.5, -145, 0.5, -50)
LoadingFrame.BackgroundColor3 = Color3.fromRGB(15, 22, 36)
LoadingFrame.BorderSizePixel = 0
LoadingFrame.Parent = LoadingGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 12)
UICorner.Parent = LoadingFrame

local UIStroke = Instance.new("UIStroke")
UIStroke.Thickness = 2
UIStroke.Color = Color3.fromRGB(0, 213, 255)
UIStroke.Parent = LoadingFrame

local LoadingText = Instance.new("TextLabel")
LoadingText.Name = "LoadingText"
LoadingText.Size = UDim2.new(1, 0, 0, 30)
LoadingText.Position = UDim2.new(0, 0, 0, 20)
LoadingText.BackgroundTransparency = 1
LoadingText.Text = "Đang khởi tạo vanut FPS v6.4..."
LoadingText.TextColor3 = Color3.fromRGB(255, 255, 255)
LoadingText.TextSize = 14
LoadingText.Font = Enum.Font.GothamBold
LoadingText.Parent = LoadingFrame

local BarBackground = Instance.new("Frame")
BarBackground.Name = "BarBackground"
BarBackground.Size = UDim2.new(0, 250, 0, 4)
BarBackground.Position = UDim2.new(0.5, -125, 0, 65)
BarBackground.BackgroundColor3 = Color3.fromRGB(30, 42, 62)
BarBackground.BorderSizePixel = 0
BarBackground.Parent = LoadingFrame

local BarCorner = Instance.new("UICorner")
BarCorner.CornerRadius = UDim.new(0, 2)
BarCorner.Parent = BarBackground

local LoadingBar = Instance.new("Frame")
LoadingBar.Name = "LoadingBar"
LoadingBar.Size = UDim2.new(0, 0, 1, 0)
LoadingBar.BackgroundColor3 = Color3.fromRGB(0, 213, 255)
LoadingBar.BorderSizePixel = 0
LoadingBar.Parent = BarBackground

local ProgressCorner = Instance.new("UICorner")
ProgressCorner.CornerRadius = UDim.new(0, 2)
ProgressCorner.Parent = LoadingBar

-- Fix 3: Bọc pcall bao quát toàn bộ thread loading, cô lập hoàn toàn nguy cơ đóng băng UI chính
task.spawn(function()
    local success = pcall(function()
        LoadingText.Text = "⚡ Khởi tạo lõi mượt mà V6.4..."
        local t1 = TweenService:Create(LoadingBar, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(0.35, 0, 1, 0)})
        if t1 then t1:Play() t1.Completed:Wait() end
        task.wait(0.05)

        LoadingText.Text = "🔍 Loại bỏ module cũ..."
        local t2 = TweenService:Create(LoadingBar, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(0.75, 0, 1, 0)})
        if t2 then t2:Play() t2.Completed:Wait() end
        task.wait(0.05)

        LoadingText.Text = "🚀 Cấu hình hiển thị Shader + Gloss..."
        local t3 = TweenService:Create(LoadingBar, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(1, 0, 1, 0)})
        if t3 then t3:Play() t3.Completed:Wait() end
        task.wait(0.05)
    end)

    pcall(function() LoadingGui:Destroy() end)
    if success then
        warn("🚀 vanut Ultimate V6.4 Minimalist đã sẵn sàng!")
    else
        warn("⚠️ Loading thread crashed silently nhưng UI chính đã được bảo vệ thành công.")
    end
end)

-- Patch khẩn cấp: Ép hiển thị cưỡng bức sau 1.5 giây để cứu nguy nếu xảy ra bất kỳ lỗi bất thường nào
task.delay(1.5, function()
    if ToggleMenuBtn then
        ToggleMenuBtn.Visible = true
    end
end)
