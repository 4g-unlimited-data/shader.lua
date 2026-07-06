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

-- 1. BẢNG HIỂN THỊ FPS RIÊNG BIỆT Ở GÓC TRÊN BÊN TRÁI MÀN HÌNH (Cập nhật siêu mượt)
local CornerFpsContainer = create("Frame", ScreenGui, {
    Size = UDim2.new(0, 110, 0, 35),
    Position = UDim2.new(0, 15, 0, 15),
    BackgroundColor3 = Color3.fromRGB(10, 16, 28),
    BorderSizePixel = 0,
    Visible = true
})
create("UICorner", CornerFpsContainer, {CornerRadius = UDim.new(0, 6)})
create("UIStroke", CornerFpsContainer, {Color = Color3.fromRGB(0, 255, 150), Thickness = 1.5})

local CornerFpsLabel = create("TextLabel", CornerFpsContainer, {
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundTransparency = 1,
    Text = "FPS: ...",
    TextColor3 = Color3.fromRGB(0, 255, 150),
    TextSize = 14,
    Font = Enum.Font.FredokaOne
})

-- Đo FPS thực tế độc lập siêu mượt
local fpsCount = 0
local lastUpdate = os.clock()
RunService.RenderStepped:Connect(function()
    fpsCount = fpsCount + 1
    local now = os.clock()
    if now - lastUpdate >= 1 then
        CornerFpsLabel.Text = "⚡ FPS: " .. fpsCount
        fpsCount = 0
        lastUpdate = now
    end
end)

-- 2. Nút Bật/Tắt Menu (Dịch xuống dưới bảng FPS góc trái)
local ToggleBtn = create("TextButton", ScreenGui, {
    Size = UDim2.new(0, 50, 0, 30),
    Position = UDim2.new(0, 15, 0, 55),
    BackgroundColor3 = Color3.fromRGB(22, 38, 64),
    Text = "Menu",
    TextColor3 = Color3.new(1, 1, 1),
    TextSize = 12,
    Font = Enum.Font.SourceSansBold,
    Active = true
})
create("UICorner", ToggleBtn, {CornerRadius = UDim.new(0, 6)})

-- Tách biệt cơ chế di chuyển nút Menu độc lập
local btnDragging, btnStart, btnStartPos
ToggleBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        btnDragging = true
        btnStart = input.Position
        btnStartPos = ToggleBtn.Position
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if btnDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - btnStart
        ToggleBtn.Position = UDim2.new(btnStartPos.X.Scale, btnStartPos.X.Offset + delta.X, btnStartPos.Y.Scale, btnStartPos.Y.Offset + delta.Y)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        btnDragging = false
    end
end)

-- 3. Tùy chỉnh Giao diện Menu chính
local MainMenu = create("Frame", ScreenGui, {
    Size = UDim2.new(0, 260, 0, 420), 
    Position = UDim2.new(0.5, -130, 0.5, -210), 
    BackgroundColor3 = Color3.fromRGB(10, 16, 28), 
    Visible = false
})
create("UICorner", MainMenu, {CornerRadius = UDim.new(0, 8)})

-- Tiêu đề Menu
local MenuTitle = create("TextLabel", MainMenu, {
    Size = UDim2.new(0.9, 0, 0, 30),
    Position = UDim2.new(0.05, 0, 0, 10),
    BackgroundTransparency = 1,
    Text = "VANUT SHADER V4",
    TextColor3 = Color3.fromRGB(255, 255, 255),
    TextSize = 16,
    Font = Enum.Font.SourceSansBold
})

-- Vùng cuộn chứa các nút tính năng Shader
local ScrollFrame = create("ScrollingFrame", MainMenu, {
    Size = UDim2.new(0.92, 0, 0, 210),
    Position = UDim2.new(0.04, 0, 0, 45),
    BackgroundTransparency = 1,
    CanvasSize = UDim2.new(0, 0, 0, 580),
    ScrollBarThickness = 4,
    ScrollBarImageColor3 = Color3.fromRGB(0, 255, 150)
})

ToggleBtn.MouseButton1Click:Connect(function()
    MainMenu.Visible = not MainMenu.Visible
end)

-- Tính năng Di chuyển (Drag) Menu chính
local dragging, dragStart, startPos
MainMenu.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = MainMenu.Position
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        MainMenu.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

local timeLockConn, starConn

local function resetLightingComplete()
    if timeLockConn then timeLockConn:Disconnect() timeLockConn = nil end
    if starConn then starConn:Disconnect() starConn = nil end
    for _, v in pairs(Workspace:GetChildren()) do if v.Name == "VanutMeteor" then v:Destroy() end end
    
    for _, obj in pairs(Lighting:GetChildren()) do
        if obj:IsA("Sky") or obj:IsA("PostEffect") or obj:IsA("Atmosphere") then
            obj:Destroy()
        end
    end
    
    Lighting.ClockTime = 14
    Lighting.Brightness = 2
    Lighting.Ambient = Color3.fromRGB(128, 128, 128)
end

local function lockTime(targetTime)
    if timeLockConn then timeLockConn:Disconnect() end
    timeLockConn = RunService.Heartbeat:Connect(function() Lighting.ClockTime = targetTime end)
end

-- TÍNH NĂNG MỚI: LÀM NÉT CHI TIẾT & ÉP CHẾ ĐỘ ĐỔ BÓNG TRỰC TIẾP TRÊN MỨC ĐỒ HỌA 2
local function forceHighVisualAndSharpness()
    pcall(function()
        Lighting.GlobalShadows = true
        Lighting.ShadowSoftness = 0.05 -- Làm nét viền bóng cứng cáp, rõ ràng
        
        -- Ép cấu trúc chi tiết Mesh vật thể sắc nét nhất
        for _, obj in pairs(game:GetDescendants()) do
            if obj:IsA("MeshPart") then
                obj.RenderFidelity = Enum.RenderFidelity.Precise
            elseif obj:IsA("BasePart") then
                obj.CastShadow = true
            end
        end
        
        -- Làm trong suốt và nét bề mặt nước phẳng lặng
        if Workspace:FindFirstChildOfClass("Terrain") then
            local terrain = Workspace:FindFirstChildOfClass("Terrain")
            terrain.WaterWaveSize = 0.1
            terrain.WaterWaveSpeed = 8
            terrain.WaterReflectance = 0.6
            terrain.WaterTransparency = 0.5
        end
    end)
end

-- Cập nhật hệ thống quét và thay thế Skybox 2026 siêu đẹp chống đè map
local function applyCustomSky(skyId)
    for _, obj in pairs(Lighting:GetChildren()) do
        if obj:IsA("Sky") then obj:Destroy() end
    end
    create("Sky", Lighting, {
        Name = "VanutSky",
        SkyboxBk = "rbxassetid://"..skyId,
        SkyboxDn = "rbxassetid://"..skyId,
        SkyboxFt = "rbxassetid://"..skyId,
        SkyboxLf = "rbxassetid://"..skyId,
        SkyboxRt = "rbxassetid://"..skyId,
        SkyboxUp = "rbxassetid://"..skyId,
        CelestialBodiesShown = true
    })
end

local function spawnAdvancedNight()
    if starConn then starConn:Disconnect() end
    applyCustomSky("12143133917") -- Tải Bầu trời đêm tinh vân vũ trụ siêu thực
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
    {"Bình minh vàng", function() forceHighVisualAndSharpness() applyCustomSky("6008860012") lockTime(6.2) Lighting.Brightness = 2.6 create("SunRaysEffect", Lighting, {Name = "VanutSunRays", Intensity = 0.35}) end},
    {"Trưa nắng rực rỡ", function() forceHighVisualAndSharpness() applyCustomSky("10811054235") lockTime(12) Lighting.Brightness = 3.4 create("BloomEffect", Lighting, {Name = "VanutBloom", Intensity = 0.3}) end},
    {"Hoàng hôn hồng", function() forceHighVisualAndSharpness() applyCustomSky("6008860012") lockTime(17.8) Lighting.Brightness = 2.5 create("SunRaysEffect", Lighting, {Name = "VanutSunRays", Intensity = 0.4}) end},
    {"Đêm nhiều sao", function() forceHighVisualAndSharpness() lockTime(0) Lighting.Brightness = 1.6 spawnAdvancedNight() end},
    {"Cinematic Lofi", function() forceHighVisualAndSharpness() applyCustomSky("10811054235") lockTime(16.5) Lighting.Brightness = 2.2 create("ColorCorrectionEffect", Lighting, {Name = "VanutCC", Saturation = -0.1, Contrast = 0.15}) end},
    {"Cyberpunk Neon", function() forceHighVisualAndSharpness() applyCustomSky("12143133917") lockTime(19) Lighting.Brightness = 2.8 create("BloomEffect", Lighting, {Name = "VanutBloom", Intensity = 0.6, Size = 24}) end},
    {"Giấc Mơ Anime (Soft)", function() forceHighVisualAndSharpness() applyCustomSky("10811054235") lockTime(15.5) Lighting.Brightness = 2.7 create("ColorCorrectionEffect", Lighting, {Name = "VanutCC", TintColor = Color3.fromRGB(255, 225, 225), Saturation = 0.25}) create("BloomEffect", Lighting, {Name = "VanutBloom", Intensity = 0.45, Size = 16}) end},
    {"Nắng Mùa Hè Cực Hạn", function() forceHighVisualAndSharpness() applyCustomSky("10811054235") lockTime(12.5) Lighting.Brightness = 3.8 create("ColorCorrectionEffect", Lighting, {Name = "VanutCC", Saturation = 0.2, Contrast = 0.12}) create("SunRaysEffect", Lighting, {Name = "VanutSunRays", Intensity = 0.45}) end},
    {"Đồ Họa HDR Siêu Thực", function() forceHighVisualAndSharpness() applyCustomSky("10811054235") lockTime(14) Lighting.Brightness = 3.0 create("ColorCorrectionEffect", Lighting, {Name = "VanutCC", Contrast = 0.3, Saturation = 0.15}) create("BloomEffect", Lighting, {Name = "VanutBloom", Intensity = 0.2, Size = 10}) end},
    {"Sương Mù Huyền Ảo", function() forceHighVisualAndSharpness() lockTime(5.8) Lighting.Brightness = 1.4 create("Atmosphere", Lighting, {Name = "VanutAtmosphere", Density = 0.7, Color = Color3.fromRGB(190, 200, 210)}) end},
    {"Tone Lạnh Bắc Cực", function() forceHighVisualAndSharpness() applyCustomSky("12143133917") lockTime(10) Lighting.Brightness = 2.3 create("ColorCorrectionEffect", Lighting, {Name = "VanutCC", TintColor = Color3.fromRGB(205, 235, 255), Saturation = -0.15}) end},
    {"U Ám Kinh Dị (Horror)", function() forceHighVisualAndSharpness() applyCustomSky("12143133917") lockTime(19.5) Lighting.Brightness = 0.4 Lighting.Ambient = Color3.fromRGB(15,15,15) create("ColorCorrectionEffect", Lighting, {Name = "VanutCC", Saturation = -0.5, Contrast = 0.3}) end},
    {"Màu Film Hoài Cổ (Vibe)", function() forceHighVisualAndSharpness() applyCustomSky("6008860012") lockTime(17) Lighting.Brightness = 2.4 create("ColorCorrectionEffect", Lighting, {Name = "VanutCC", TintColor = Color3.fromRGB(255, 240, 200), Saturation = -0.05, Contrast = 0.08}) end}
}

local function boostFPS()
    settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
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
end

local function playClickAnimation(button)
    local originalSize = button.Size
    local originalColor = button.BackgroundColor3
    local shrinkTween = TweenService:Create(button, TweenInfo.new(0.06, Enum.EasingStyle.QuadOut), {
        Size = UDim2.new(originalSize.X.Scale, originalSize.X.Offset - 6, originalSize.Y.Scale, originalSize.Y.Offset - 2),
        BackgroundColor3 = Color3.fromRGB(35, 70, 120)
    })
    local returnTween = TweenService:Create(button, TweenInfo.new(0.1, Enum.EasingStyle.QuadIn), {
        Size = originalSize,
        BackgroundColor3 = originalColor
    })
    shrinkTween:Play()
    shrinkTween.Completed:Connect(function() returnTween:Play() end)
end

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
    
    btn.MouseButton1Down:Connect(function() 
        playClickAnimation(btn)
        resetLightingComplete() 
        data[2]() 
    end)
end

-- NÚT ẨN/HIỆN KHUNG FPS GÓC TRÁI MÀN HÌNH MỚI THÊM VÀO
local ToggleFpsUiBtn = create("TextButton", MainMenu, {Size = UDim2.new(0.9, 0, 0, 30), Position = UDim2.new(0.05, 0, 0, 270), BackgroundColor3 = Color3.fromRGB(16, 26, 46), Text = "👁️ Ẩn/Hiện Khung FPS Góc Trái", TextColor3 = Color3.fromRGB(0, 255, 150), TextSize = 13, Font = Enum.Font.SourceSansBold})
create("UICorner", ToggleFpsUiBtn, {CornerRadius = UDim.new(0, 6)})
create("UIStroke", ToggleFpsUiBtn, {Color = Color3.fromRGB(0, 255, 150), Thickness = 1})
ToggleFpsUiBtn.MouseButton1Down:Connect(function()
    playClickAnimation(ToggleFpsUiBtn)
    CornerFpsContainer.Visible = not CornerFpsContainer.Visible
end)

-- NÚT LÀM NÉT & ĐỔ BÓNG TRỰC TIẾP (ÉP CHO MỨC ĐỒ HỌA 2)
local UltraGraphicsBtn = create("TextButton", MainMenu, {Size = UDim2.new(0.9, 0, 0, 30), Position = UDim2.new(0.05, 0, 0, 305), BackgroundColor3 = Color3.fromRGB(150, 80, 20), Text = "✨ LÀM NÉT & ĐỔ BÓNG MỨC 2", TextColor3 = Color3.new(1,1,1), TextSize = 13, Font = Enum.Font.SourceSansBold})
create("UICorner", UltraGraphicsBtn, {CornerRadius = UDim.new(0, 6)})
UltraGraphicsBtn.MouseButton1Down:Connect(function()
    playClickAnimation(UltraGraphicsBtn)
    forceHighVisualAndSharpness()
end)

-- Nút BOOST FPS TOÁN DIỆN
local BoostBtn = create("TextButton", MainMenu, {Size = UDim2.new(0.43, 0, 0, 30), Position = UDim2.new(0.05, 0, 0, 340), BackgroundColor3 = Color3.fromRGB(30, 110, 40), Text = "SIÊU BOOST FPS", TextColor3 = Color3.new(1,1,1), TextSize = 12, Font = Enum.Font.SourceSansBold})
create("UICorner", BoostBtn, {CornerRadius = UDim.new(0, 6)})
BoostBtn.MouseButton1Down:Connect(function()
    playClickAnimation(BoostBtn)
    boostFPS()
end)

-- Nút BOOST 100 - 200 FPS
local UltraBoostBtn = create("TextButton", MainMenu, {Size = UDim2.new(0.43, 0, 0, 30), Position = UDim2.new(0.52, 0, 0, 340), BackgroundColor3 = Color3.fromRGB(24, 84, 137), Text = "BOOST 100-200 FPS", TextColor3 = Color3.new(1,1,1), TextSize = 12, Font = Enum.Font.SourceSansBold})
create("UICorner", UltraBoostBtn, {CornerRadius = UDim.new(0, 6)})
UltraBoostBtn.MouseButton1Down:Connect(function()
    playClickAnimation(UltraBoostBtn)
    ultraBoostFPS()
end)

-- Nút XÓA SHADER / RESET LIGHTING
local ResetBtn = create("TextButton", MainMenu, {Size = UDim2.new(0.9, 0, 0, 32), Position = UDim2.new(0.05, 0, 0, 375), BackgroundColor3 = Color3.fromRGB(110, 35, 40), Text = "❌ XÓA SHADER / RESET ĐỒ HỌA", TextColor3 = Color3.new(1,1,1), TextSize = 13, Font = Enum.Font.SourceSansBold})
create("UICorner", ResetBtn, {CornerRadius = UDim.new(0, 6)})
ResetBtn.MouseButton1Down:Connect(function()
    playClickAnimation(ResetBtn)
    resetLightingComplete()
end)
