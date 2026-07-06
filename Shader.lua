-- [[ vanut v6.4 / rimuru tempest - Ultimate Minimalist Mobile Edition ]] --
print("GUI script running")

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer

local currentGloss = 20
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

local targetGui = player:WaitForChild("PlayerGui")

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

-- Fix 4 & 2: Đẩy DisplayOrder lên 1,000,000 và trả về ZIndexBehavior.Global chống đè hiển thị hoàn toàn
local ScreenGui = create("ScreenGui", targetGui, {
    Name = "Vanut_Rimuru_v64", 
    ResetOnSpawn = false, 
    ZIndexBehavior = Enum.ZIndexBehavior.Global,
    DisplayOrder = 1000000, 
    IgnoreGuiInset = true,
    Enabled = true
})

-- Fix 5: Thêm nhãn MENU TEST cưỡng bức sau 1 giây kiểm tra lớp render layer
task.delay(1, function()
    pcall(function()
        local t = Instance.new("TextLabel")
        t.Size = UDim2.new(0, 300, 0, 60)
        t.Position = UDim2.new(0, 50, 0, 200)
        t.Text = "MENU TEST"
        t.TextScaled = true
        t.TextColor3 = Color3.fromRGB(255, 255, 0)
        t.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        t.ZIndex = 1000000
        t.Parent = ScreenGui
        task.delay(5, function() pcall(function() t:Destroy() end) end)
    end)
end)

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
    Active = true,
    ZIndex = 999999
}) addCorner(ToggleMenuBtn, 18) addStroke(ToggleMenuBtn)

-- Fix 3: Ép bung toàn màn hình chống lỗi clip sai tỉ lệ / lệch góc trên mobile executor công phá layer
local MainMenu = create("Frame", ScreenGui, {
    Size = UDim2.new(1, 0, 1, 0),
    Position = UDim2.new(0, 0, 0, 0),
    BackgroundColor3 = Color3.fromRGB(10, 16, 28),
    Visible = true,
    Active = true,
    ZIndex = 999999
}) addCorner(MainMenu, 0)

local MainMenuContainer = create("Frame", MainMenu, {
    Size = UDim2.new(0, 340, 0, 260),
    Position = UDim2.new(0.5, -170, 0.5, -130),
    BackgroundColor3 = Color3.fromRGB(10, 16, 28),
    ZIndex = 100000
}) addCorner(MainMenuContainer, 8) addStroke(MainMenuContainer)

create("TextLabel", MainMenuContainer, {
    Size = UDim2.new(1, 0, 0, 30),
    BackgroundColor3 = Color3.fromRGB(16, 26, 44),
    Text = "BẢNG ĐIỀU KHIỂN - RIMURU ENGINE V6.4 SHADER",
    TextColor3 = Color3.fromRGB(255, 255, 255),
    Font = Enum.Font.GothamBold,
    TextSize = 11,
    ZIndex = 100001
}) addCorner(MainMenuContainer:FindFirstChildOfClass("TextLabel"), 8)

table.insert(connections, ToggleMenuBtn.MouseButton1Click:Connect(function()
    if isGuiDestroyed then return end
    MainMenu.Visible = not MainMenu.Visible
end))

local TabContainer = create("Frame", MainMenuContainer, {Size = UDim2.new(1, 0, 0, 28), Position = UDim2.new(0, 0, 0, 30), BackgroundColor3 = Color3.fromRGB(14, 22, 38), ZIndex = 100001})
local ContentContainer = create("Frame", MainMenuContainer, {Size = UDim2.new(1, -12, 1, -68), Position = UDim2.new(0, 6, 0, 62), BackgroundTransparency = 1, ZIndex = 100001})
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
        ZIndex = 100002
    })
    
    table.insert(connections, tBtn.MouseButton1Click:Connect(function()
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
makeDraggable(MainMenuContainer, MainMenuContainer:FindFirstChildOfClass("TextLabel"))

-- =======================================================================
-- TAB 1: SHADER ENGINE
-- =======================================================================
local PageShader = create("ScrollingFrame", nil, {CanvasSize = UDim2.new(0, 0, 0, 310), ScrollBarThickness = 2, BackgroundTransparency = 1, BorderSizePixel = 0, Active = false, ScrollingEnabled = true, ZIndex = 100002}) create("UIListLayout", PageShader, {Padding = UDim.new(0, 4)})

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
    local sb = create("TextButton", PageShader, {Size = UDim2.new(1, -4, 0, 32), BackgroundColor3 = Color3.fromRGB(22, 38, 64), Text = "   " .. data[1], TextColor3 = Color3.fromRGB(200, 230, 255), Font = Enum.Font.Gotham, TextSize = 10, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 100003}) addCorner(sb, 4) addStroke(sb)
    table.insert(connections, sb.MouseButton1Click:Connect(buildProtectedCallback(data[2])))
end

local ClearShaderBtn = create("TextButton", PageShader, {Size = UDim2.new(1, -4, 0, 32), BackgroundColor3 = Color3.fromRGB(110, 35, 40), Text = "❌ XÓA TOÀN BỘ CẤU HÌNH SHADER", TextColor3 = Color3.fromRGB(255, 255, 255), Font = Enum.Font.GothamBold, TextSize = 10, ZIndex = 100003}) addCorner(ClearShaderBtn, 4) addStroke(ClearShaderBtn)
table.insert(connections, ClearShaderBtn.MouseButton1Click:Connect(buildProtectedCallback(function() resetLightingComplete() end)))

createTab("Shader", 1, PageShader)

-- =======================================================================
-- TAB 2: ĐỘ BÓNG NÂNG CAO
-- =======================================================================
local PageGloss = create("Frame", nil, {ZIndex = 100002})
local SliderTitle = create("TextLabel", PageGloss, {Size = UDim2.new(1, 0, 0, 20), Position = UDim2.new(0, 0, 0, 15), BackgroundTransparency = 1, Text = "ĐỘ BÓNG BỀ MẶT PHẢN CHIẾU: 20 %", TextColor3 = Color3.fromRGB(0, 255, 180), Font = Enum.Font.GothamBold, TextSize = 10, ZIndex = 100003})
local SliderTrack = create("Frame", PageGloss, {Size = UDim2.new(1, -40, 0, 6), Position = UDim2.new(0, 20, 0, 45), BackgroundColor3 = Color3.fromRGB(25, 38, 60), ZIndex = 100003}) addCorner(SliderTrack, 3)
local SliderFill = create("Frame", SliderTrack, {Size = UDim2.new(0.2, 0, 1, 0), BackgroundColor3 = Color3.fromRGB(0, 215, 255), ZIndex = 100003}) addCorner(SliderFill, 3)
local SliderBtn = create("TextButton", SliderTrack, {Size = UDim2.new(0, 14, 0, 14), Position = UDim2.new(0.2, -7, 0.5, -7), BackgroundColor3 = Color3.fromRGB(255, 255, 255), Text = "", ZIndex = 100004}) addCorner(SliderBtn, 7) addStroke(SliderBtn)

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
    ZIndex = 100003
})

createTab("Độ Bóng", 2, PageGloss)

print("GUI script executed successfully to the end")
