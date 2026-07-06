local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local targetGui = player:WaitForChild("PlayerGui", 10)
if not targetGui then return end
if targetGui:FindFirstChild("Vanut_Shader_Only") then targetGui["Vanut_Shader_Only"]:Destroy() end

local function create(cls, parent, props)
    local inst = Instance.new(cls)
    for k, v in pairs(props or {}) do inst[k] = v end
    if parent then inst.Parent = parent end
    return inst
end

local ScreenGui = create("ScreenGui", targetGui, {Name = "Vanut_Shader_Only", ResetOnSpawn = false})

-- 1. NÚT BẬT/TẮT MENU (MODERN CHROME)
local ToggleBtn = create("TextButton", ScreenGui, {
    Size = UDim2.new(0, 55, 0, 55),
    Position = UDim2.new(0.05, 0, 0.1, 0),
    BackgroundColor3 = Color3.fromRGB(15, 23, 42),
    Text = "Vanut",
    TextColor3 = Color3.fromRGB(56, 189, 248),
    TextSize = 15,
    Font = Enum.Font.GothamBold,
    Active = true,
    Draggable = true
})
create("UICorner", ToggleBtn, {CornerRadius = UDim.new(0, 16)})
create("UIStroke", ToggleBtn, {Color = Color3.fromRGB(56, 189, 248), Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border})

-- 2. GIAO DIỆN CHÍNH (NEUMORPHISM DARK)
local MainMenu = create("Frame", ScreenGui, {
    Size = UDim2.new(0, 260, 0, 370), 
    Position = UDim2.new(0.5, -130, 0.5, -185), 
    BackgroundColor3 = Color3.fromRGB(15, 23, 42), 
    Visible = false,
    ClipsDescendants = true
})
create("UICorner", MainMenu, {CornerRadius = UDim.new(0, 16)})
create("UIStroke", MainMenu, {Color = Color3.fromRGB(30, 41, 59), Thickness = 1.5})

local Title = create("TextLabel", MainMenu, {
    Size = UDim2.new(1, 0, 0, 40),
    BackgroundTransparency = 1,
    Text = "VANUT SHADER",
    TextColor3 = Color3.fromRGB(255, 255, 255),
    TextSize = 14,
    Font = Enum.Font.GothamBold
})

-- TÍNH NĂNG KÉO THẢ (DRAG)
local function makeDraggable(gui)
    local dragging, dragInput, dragStart, startPos
    gui.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true; dragStart = input.Position; startPos = gui.Position
            input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
        end
    end)
    gui.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            gui.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end
makeDraggable(MainMenu)

-- TẬP HỢP HIỆU ỨNG LÀM MỚI UI KHI NHẤN NÚT MENU
ToggleBtn.MouseButton1Click:Connect(function()
    MainMenu.Visible = not MainMenu.Visible
    if MainMenu.Visible then
        MainMenu.Size = UDim2.new(0, 260, 0, 0)
        TweenService:Create(MainMenu, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0, 260, 0, 370)}):Play()
    end
end)

-- 3. UI FPS TRONG SUỐT 7 SẮC CẦU VỒNG (CÓ THỂ DI CHUYỂN)
local FpsGui = create("Frame", ScreenGui, {
    Size = UDim2.new(0, 90, 0, 35),
    Position = UDim2.new(0.85, 0, 0.02, 0),
    BackgroundTransparency = 1,
    Active = true
})
local FpsText = create("TextLabel", FpsGui, {
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundTransparency = 1,
    Text = "FPS: --",
    TextSize = 16,
    Font = Enum.Font.GothamBold
})
create("UIStroke", FpsText, {Color = Color3.fromRGB(0,0,0), Thickness = 1.5})
makeDraggable(FpsGui)

-- Xử lý FPS và màu 7 sắc cầu vồng
local fpsCount = 0
local lastUpdate = os.clock()
RunService.RenderStepped:Connect(function()
    fpsCount = fpsCount + 1
    local now = os.clock()
    if now - lastUpdate >= 0.5 then
        FpsText.Text = string.format("FPS: %d", math.floor(fpsCount / (now - lastUpdate)))
        fpsCount = 0
        lastUpdate = now
    end
    FpsText.TextColor3 = Color3.fromHSV(tick() % 5 / 5, 1, 1)
end)

-- 4. LOGIC XỬ LÝ SHADER & LIGHTING
local timeLockConn, starConn

local function resetLightingComplete()
    if timeLockConn then timeLockConn:Disconnect() timeLockConn = nil end
    if starConn then starConn:Disconnect() starConn = nil end
    for _, v in pairs(Workspace:GetChildren()) do if v.Name == "VanutMeteor" then v:Destroy() end end
    for _, n in pairs({"VanutBloom", "VanutCC", "VanutAtmosphere", "VanutSunRays", "VanutSky"}) do 
        local found = Lighting:FindFirstChild(n) if found then found:Destroy() end 
    end
    Lighting.ClockTime = 14
    Lighting.Brightness = 2
    Lighting.Ambient = Color3.fromRGB(128, 128, 128)
end

local function lockTime(targetTime)
    if timeLockConn then timeLockConn:Disconnect() end
    timeLockConn = RunService.Heartbeat:Connect(function() Lighting.ClockTime = targetTime end)
end

local function spawnAdvancedNight()
    if starConn then starConn:Disconnect() end
    create("Sky", Lighting, {Name = "VanutSky", SkyboxBk = "rbxassetid://6008860012", SkyboxDn = "rbxassetid://6008860012", SkyboxFt = "rbxassetid://6008860012", SkyboxLf = "rbxassetid://6008860012", SkyboxRt = "rbxassetid://6008860012", SkyboxUp = "rbxassetid://6008860012", StarCount = 5000})
    starConn = RunService.Heartbeat:Connect(function()
        if math.random(1, 120) == 1 then
            local startPos = Vector3.new(math.random(-200, 200), math.random(120, 180), math.random(-200, 200))
            local meteor = create("Part", Workspace, {Name = "VanutMeteor", Size = Vector3.new(1, 1, 5), Material = Enum.Material.Neon, Color = Color3.fromRGB(200, 240, 255), Anchored = true, CanCollide = false, Position = startPos})
            local tween = TweenService:Create(meteor, TweenInfo.new(0.8, Enum.EasingStyle.QuadIn), {Position = startPos + Vector3.new(0, -100, 0), Transparency = 1})
            tween:Play() tween.Completed:Connect(function() meteor:Destroy() end)
        end
    end)
end

local shaderFuncs = {
    {"Bình minh vàng", function() lockTime(6.2) Lighting.Brightness = 2.6 create("SunRaysEffect", Lighting, {Name = "VanutSunRays", Intensity = 0.35}) end},
    {"Trưa nắng rực rỡ", function() lockTime(12) Lighting.Brightness = 3.4 create("BloomEffect", Lighting, {Name = "VanutBloom", Intensity = 0.3}) end},
    {"Hoàng hôn hồng", function() lockTime(17.8) Lighting.Brightness = 2.5 create("SunRaysEffect", Lighting, {Name = "VanutSunRays", Intensity = 0.4}) end},
    {"Đêm nhiều sao", function() lockTime(0) Lighting.Brightness = 1.6 spawnAdvancedNight() end},
    {"Cinematic Lofi", function() lockTime(16.5) Lighting.Brightness = 2.2 create("ColorCorrectionEffect", Lighting, {Name = "VanutCC", Saturation = -0.1, Contrast = 0.15}) end},
    {"Cyberpunk Neon", function() lockTime(19) Lighting.Brightness = 2.8 create("BloomEffect", Lighting, {Name = "VanutBloom", Intensity = 0.6, Size = 24}) end}
}

-- KHỞI TẠO NÚT SHADER VỚI ANIMATION CLICK MỚI
for i, data in ipairs(shaderFuncs) do
    local btn = create("TextButton", MainMenu, {
        Size = UDim2.new(0.9, 0, 0, 38), 
        Position = UDim2.new(0.05, 0, 0, 45 + (i-1)*44), 
        BackgroundColor3 = Color3.fromRGB(30, 41, 59), 
        Text = data[1], 
        TextColor3 = Color3.fromRGB(226, 232, 240), 
        TextSize = 13,
        Font = Enum.Font.GothamMedium
    })
    create("UICorner", btn, {CornerRadius = UDim.new(0, 8)})
    create("UIStroke", btn, {Color = Color3.fromRGB(51, 65, 85), Thickness = 1})
    
    btn.MouseButton1Click:Connect(function()
        local origSize = UDim2.new(0.9, 0, 0, 38)
        local origPos = UDim2.new(0.05, 0, 0, 45 + (i-1)*44)
        
        TweenService:Create(btn, TweenInfo.new(0.1, Enum.EasingStyle.QuadOut), {Size = UDim2.new(0.85, 0, 0, 34), Position = origPos + UDim2.new(0.025, 0, 0, 2)}):Play()
        task.wait(0.1)
        TweenService:Create(btn, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = origSize, Position = origPos}):Play()
        
        resetLightingComplete() 
        data[2]() 
    end)
end

-- 5. NÚT XÓA SHADER
local ResetBtn = create("TextButton", MainMenu, {
    Size = UDim2.new(0.9, 0, 0, 40), 
    Position = UDim2.new(0.05, 0, 0, 315), 
    BackgroundColor3 = Color3.fromRGB(239, 68, 68), 
    Text = "XÓA SHADER", 
    TextColor3 = Color3.new(1,1,1), 
    TextSize = 13,
    Font = Enum.Font.GothamBold
})
create("UICorner", ResetBtn, {CornerRadius = UDim.new(0, 8)})

ResetBtn.MouseButton1Click:Connect(function()
    TweenService:Create(ResetBtn, TweenInfo.new(0.1, Enum.EasingStyle.QuadOut), {Size = UDim2.new(0.85, 0, 0, 36), Position = UDim2.new(0.075, 0, 0, 317)}):Play()
    task.wait(0.1)
    TweenService:Create(ResetBtn, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0.9, 0, 0, 40), Position = UDim2.new(0.05, 0, 0, 315)}):Play()
    resetLightingComplete()
end)
