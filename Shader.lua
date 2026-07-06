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

-- ScreenGui chính
local ScreenGui = create("ScreenGui", targetGui, {Name = "Vanut_Shader_Only", ResetOnSpawn = false})

-- 1. Nút Bật/Tắt Menu (Toggle Button) phù hợp cho cả PC và Điện thoại
local ToggleBtn = create("TextButton", ScreenGui, {
    Size = UDim2.new(0, 50, 0, 50),
    Position = UDim2.new(0.05, 0, 0.1, 0),
    BackgroundColor3 = Color3.fromRGB(22, 38, 64),
    Text = "Vanut",
    TextColor3 = Color3.new(1, 1, 1),
    TextSize = 14,
    Font = Enum.Font.SourceSansBold,
    Active = true,
    Draggable = true
})
create("UICorner", ToggleBtn, {CornerRadius = UDim.new(0, 25)})

-- 2. Tùy chỉnh Menu (Kích thước chuẩn, có ScrollingFrame chống tràn)
local MainMenu = create("Frame", ScreenGui, {
    Size = UDim2.new(0, 260, 0, 420), 
    Position = UDim2.new(0.5, -130, 0.5, -210), 
    BackgroundColor3 = Color3.fromRGB(10, 16, 28), 
    Visible = false
})
create("UICorner", MainMenu, {CornerRadius = UDim.new(0, 8)})

-- 3. BẢNG HIỂN THỊ FPS ĐỒ HỌA ĐẸP (UI hiện FPS đang có)
local FpsContainer = create("Frame", MainMenu, {
    Size = UDim2.new(0.9, 0, 0, 40),
    Position = UDim2.new(0.05, 0, 0, 10),
    BackgroundColor3 = Color3.fromRGB(16, 26, 46),
    BorderSizePixel = 0
})
create("UICorner", FpsContainer, {CornerRadius = UDim.new(0, 6)})
create("UIStroke", FpsContainer, {Color = Color3.fromRGB(0, 255, 150), Thickness = 1})

local FpsLabel = create("TextLabel", FpsContainer, {
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundTransparency = 1,
    Text = "FPS: ĐANG TÍNH...",
    TextColor3 = Color3.fromRGB(0, 255, 150),
    TextSize = 16,
    Font = Enum.Font.FredokaOne
})

-- Đo lượng FPS thực tế liên tục
local fpsCount = 0
local lastUpdate = os.clock()
RunService.RenderStepped:Connect(function()
    fpsCount = fpsCount + 1
    local now = os.clock()
    if now - lastUpdate >= 1 then
        FpsLabel.Text = "⚡ FPS: " .. fpsCount .. " ⚡"
        fpsCount = 0
        lastUpdate = now
    end
end)

-- Vùng cuộn chứa các nút tính năng
local ScrollFrame = create("ScrollingFrame", MainMenu, {
    Size = UDim2.new(0.92, 0, 0, 240),
    Position = UDim2.new(0.04, 0, 0, 60),
    BackgroundTransparency = 1,
    CanvasSize = UDim2.new(0, 0, 0, 720), -- Mở rộng vùng cuộn cho đống Shader mới
    ScrollBarThickness = 4,
    ScrollBarImageColor3 = Color3.fromRGB(0, 255, 150)
})

-- Tính năng Bật/Tắt khi nhấn nút Vanut
ToggleBtn.MouseButton1Click:Connect(function()
    MainMenu.Visible = not MainMenu.Visible
end)

-- Tính năng Di chuyển (Drag) Menu
local dragging, dragInput, dragStart, startPos
local function update(input)
    local delta = input.Position - dragStart
    MainMenu.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end

MainMenu.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = MainMenu.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)

MainMenu.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then update(input) end
end)

local timeLockConn, starConn

local function resetLightingComplete()
    if timeLockConn then timeLockConn:Disconnect() timeLockConn = nil end
    if starConn then starConn:Disconnect() starConn = nil end
    for _, v in pairs(Workspace:GetChildren()) do if v.Name == "VanutMeteor" then v:Destroy() end end
    for _, n in pairs({"VanutBloom", "VanutCC", "VanutAtmosphere", "VanutSunRays", "VanutSky", "VanutBlur", "VanutDepth"}) do 
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

-- MỤC LÀM BÓNG & HIỆU ỨNG ĐẸP LÊN (Mở khóa max đồ họa siêu đẹp)
local function maxGraphicsUltra()
    settings().Rendering.QualityLevel = Enum.QualityLevel.Level21
    Lighting.GlobalShadows = true
    Lighting.ShadowSoftness = 0.1
    sethiddenproperty(Lighting, "Technology", Enum.LightingTechnology.Future)
    if Workspace:FindFirstChildOfClass("Terrain") then
        local terrain = Workspace:FindFirstChildOfClass("Terrain")
        sethiddenproperty(terrain, "Decoration", true)
        terrain.WaterWaveSize = 0.2
        terrain.WaterWaveSpeed = 15
        terrain.WaterReflectance = 0.8
        terrain.WaterTransparency = 0.7
    end
    for _, obj in pairs(game:GetDescendants()) do
        if obj:IsA("MeshPart") then
            obj.RenderFidelity = Enum.RenderFidelity.Precise
            obj.CollisionFidelity = Enum.CollisionFidelity.Default
        elseif obj:IsA("BasePart") then
            obj.CastShadow = true
        end
    end
end

-- TỔNG HỢP DANH SÁCH NHIỀU SHADER ĐẸP MỚI VÀ CŨ
local shaderFuncs = {
    {"Bình minh vàng", function() lockTime(6.2) Lighting.Brightness = 2.6 create("SunRaysEffect", Lighting, {Name = "VanutSunRays", Intensity = 0.35}) end},
    {"Trưa nắng rực rỡ", function() lockTime(12) Lighting.Brightness = 3.4 create("BloomEffect", Lighting, {Name = "VanutBloom", Intensity = 0.3}) end},
    {"Hoàng hôn hồng", function() lockTime(17.8) Lighting.Brightness = 2.5 create("SunRaysEffect", Lighting, {Name = "VanutSunRays", Intensity = 0.4}) end},
    {"Đêm nhiều sao", function() lockTime(0) Lighting.Brightness = 1.6 spawnAdvancedNight() end},
    {"Cinematic Lofi", function() lockTime(16.5) Lighting.Brightness = 2.2 create("ColorCorrectionEffect", Lighting, {Name = "VanutCC", Saturation = -0.1, Contrast = 0.15}) end},
    {"Cyberpunk Neon", function() lockTime(19) Lighting.Brightness = 2.8 create("BloomEffect", Lighting, {Name = "VanutBloom", Intensity = 0.6, Size = 24}) end},
    -- Shader đẹp bổ sung thêm:
    {"Giấc Mơ Anime (Soft)", function() lockTime(15.5) Lighting.Brightness = 2.7 create("ColorCorrectionEffect", Lighting, {Name = "VanutCC", TintColor = Color3.fromRGB(255, 225, 225), Saturation = 0.25}) create("BloomEffect", Lighting, {Name = "VanutBloom", Intensity = 0.45, Size = 16}) end},
    {"Nắng Mùa Hè Cực Hạn", function() lockTime(12.5) Lighting.Brightness = 3.8 create("ColorCorrectionEffect", Lighting, {Name = "VanutCC", Saturation = 0.2, Contrast = 0.12}) create("SunRaysEffect", Lighting, {Name = "VanutSunRays", Intensity = 0.45}) end},
    {"Đồ Họa HDR Siêu Thực", function() lockTime(14) Lighting.Brightness = 3.0 create("ColorCorrectionEffect", Lighting, {Name = "VanutCC", Contrast = 0.3, Saturation = 0.15}) create("BloomEffect", Lighting, {Name = "VanutBloom", Intensity = 0.2, Size = 10}) end},
    {"Sương Mù Huyền Ảo", function() lockTime(5.8) Lighting.Brightness = 1.4 create("Atmosphere", Lighting, {Name = "VanutAtmosphere", Density = 0.7, Color = Color3.fromRGB(190, 200, 210)}) end},
    {"Tone Lạnh Bắc Cực", function() lockTime(10) Lighting.Brightness = 2.3 create("ColorCorrectionEffect", Lighting, {Name = "VanutCC", TintColor = Color3.fromRGB(205, 235, 255), Saturation = -0.15}) end},
    {"U Ám Kinh Dị (Horror)", function() lockTime(19.5) Lighting.Brightness = 0.4 Lighting.Ambient = Color3.fromRGB(15,15,15) create("ColorCorrectionEffect", Lighting, {Name = "VanutCC", Saturation = -0.5, Contrast = 0.3}) end},
    {"Màu Film Hoài Cổ (Vibe)", function() lockTime(17) Lighting.Brightness = 2.4 create("ColorCorrectionEffect", Lighting, {Name = "VanutCC", TintColor = Color3.fromRGB(255, 240, 200), Saturation = -0.05, Contrast = 0.08}) end}
}

-- Tính năng Tối ưu FPS
local function boostFPS()
    settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
    sethiddenproperty(Workspace.Terrain, "Decoration", false)
    Workspace.Terrain.WaterWaveSize = 0
    Workspace.Terrain.WaterWaveSpeed = 0
    Workspace.Terrain.WaterReflectance = 0
    Workspace.Terrain.WaterTransparency = 0
    Lighting.GlobalShadows = false
    Lighting.ShadowSoftness = 0
    for _, v in pairs(game:GetDescendants()) do
        if v:IsA("Part") or v:IsA("CornerWedgePart") or v:IsA("MeshPart") or v:IsA("SolitaryPart") or v:IsA("SpawnLocation") then
            v.Material = Enum.Material.SmoothPlastic
            v.Reflectance = 0
        elseif v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Smoke") or v:IsA("Sparkles") then
            v.Enabled = false
        end
    end
end

local function ultraBoostFPS()
    settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
    Lighting.GlobalShadows = false
    if Workspace:FindFirstChildOfClass("Terrain") then
        local terrain = Workspace:FindFirstChildOfClass("Terrain")
        sethiddenproperty(terrain, "Decoration", false)
        terrain.WaterWaveSize = 0
        terrain.WaterReflectance = 0
    end
    for _, obj in pairs(game:GetDescendants()) do
        if obj:IsA("MeshPart") then
            obj.RenderFidelity = Enum.RenderFidelity.Performance
        elseif obj:IsA("BasePart") then
            obj.CastShadow = false
        end
    end
    sethiddenproperty(Lighting, "Technology", Enum.LightingTechnology.Compatibility)
end

-- Hàm tạo Animation Click co giãn mượt mà khi chọn nút
local function playClickAnimation(button)
    local originalSize = button.Size
    local originalColor = button.BackgroundColor3
    
    local shrinkTween = TweenService:Create(button, TweenInfo.new(0.08, Enum.EasingStyle.QuadOut), {
        Size = UDim2.new(originalSize.X.Scale, originalSize.X.Offset - 8, originalSize.Y.Scale, originalSize.Y.Offset - 3),
        BackgroundColor3 = Color3.fromRGB(35, 70, 120)
    })
    
    local returnTween = TweenService:Create(button, TweenInfo.new(0.12, Enum.EasingStyle.QuadIn), {
        Size = originalSize,
        BackgroundColor3 = originalColor
    })
    
    shrinkTween:Play()
    shrinkTween.Completed:Connect(function() returnTween:Play() end)
end

-- Tạo danh sách Shader vào vùng cuộn
for i, data in ipairs(shaderFuncs) do
    local btn = create("TextButton", ScrollFrame, {
        Size = UDim2.new(0.95, 0, 0, 35), 
        Position = UDim2.new(0.02, 0, 0, 5 + (i-1)*40), 
        BackgroundColor3 = Color3.fromRGB(22, 38, 64), 
        Text = data[1], 
        TextColor3 = Color3.new(1,1,1), 
        TextSize = 13,
        Font = Enum.Font.SourceSansSemibold
    })
    create("UICorner", btn, {CornerRadius = UDim.new(0, 6)})
    
    btn.MouseButton1Click:Connect(function() 
        playClickAnimation(btn)
        resetLightingComplete() 
        data[2]() 
    end)
end

-- NÚT LÀM BÓNG & HIỆU ỨNG SIÊU ĐẸP (FUTURE)
local UltraGraphicsBtn = create("TextButton", MainMenu, {Size = UDim2.new(0.9, 0, 0, 30), Position = UDim2.new(0.05, 0, 0, 305), BackgroundColor3 = Color3.fromRGB(150, 80, 20), Text = "✨ BẬT BÓNG & ĐỒ HỌA ĐẸP lên", TextColor3 = Color3.new(1,1,1), TextSize = 13, Font = Enum.Font.SourceSansBold})
create("UICorner", UltraGraphicsBtn, {CornerRadius = UDim.new(0, 6)})
UltraGraphicsBtn.MouseButton1Click:Connect(function()
    playClickAnimation(UltraGraphicsBtn)
    maxGraphicsUltra()
end)

-- Nút BOOST FPS TOÁN DIỆN
local BoostBtn = create("TextButton", MainMenu, {Size = UDim2.new(0.43, 0, 0, 30), Position = UDim2.new(0.05, 0, 0, 340), BackgroundColor3 = Color3.fromRGB(30, 110, 40), Text = "SIÊU BOOST FPS", TextColor3 = Color3.new(1,1,1), TextSize = 12, Font = Enum.Font.SourceSansBold})
create("UICorner", BoostBtn, {CornerRadius = UDim.new(0, 6)})
BoostBtn.MouseButton1Click:Connect(function()
    playClickAnimation(BoostBtn)
    boostFPS()
end)

-- Nút BOOST 100 - 200 FPS
local UltraBoostBtn = create("TextButton", MainMenu, {Size = UDim2.new(0.43, 0, 0, 30), Position = UDim2.new(0.52, 0, 0, 340), BackgroundColor3 = Color3.fromRGB(24, 84, 137), Text = "BOOST 100-200 FPS", TextColor3 = Color3.new(1,1,1), TextSize = 12, Font = Enum.Font.SourceSansBold})
create("UICorner", UltraBoostBtn, {CornerRadius = UDim.new(0, 6)})
UltraBoostBtn.MouseButton1Click:Connect(function()
    playClickAnimation(UltraBoostBtn)
    ultraBoostFPS()
end)

-- Nút XÓA SHADER / RESET LIGHTING
local ResetBtn = create("TextButton", MainMenu, {Size = UDim2.new(0.9, 0, 0, 32), Position = UDim2.new(0.05, 0, 0, 375), BackgroundColor3 = Color3.fromRGB(110, 35, 40), Text = "❌ XÓA SHADER / RESET ĐỒ HỌA", TextColor3 = Color3.new(1,1,1), TextSize = 13, Font = Enum.Font.SourceSansBold})
create("UICorner", ResetBtn, {CornerRadius = UDim.new(0, 6)})
ResetBtn.MouseButton1Click:Connect(function()
    playClickAnimation(ResetBtn)
    resetLightingComplete()
end)
