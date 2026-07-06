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

-- 1. Nút Bật/Tắt Menu (Toggle Button) phù hợp cho điện thoại
local ToggleBtn = create("TextButton", ScreenGui, {
    Size = UDim2.new(0, 50, 0, 50),
    Position = UDim2.new(0.05, 0, 0.1, 0),
    BackgroundColor3 = Color3.fromRGB(22, 38, 64),
    Text = "Vanut",
    TextColor3 = Color3.new(1, 1, 1),
    TextSize = 14,
    Font = Enum.Font.SourceSansBold,
    Active = true,
    Draggable = true -- Tự động cho phép di chuyển nút bật/tắt
})
create("UICorner", ToggleBtn, {CornerRadius = UDim.new(0, 25)})

-- 2. Tùy chỉnh Menu (Không quá màn hình, không lớn quá nửa màn hình điện thoại)
local MainMenu = create("Frame", ScreenGui, {
    Size = UDim2.new(0, 240, 0, 320), 
    Position = UDim2.new(0.5, -120, 0.5, -160), 
    BackgroundColor3 = Color3.fromRGB(10, 16, 28), 
    Visible = false -- Mặc định ẩn, bấm nút để bật
})
create("UICorner", MainMenu, {CornerRadius = UDim.new(0, 8)})

-- Tính năng Bật/Tắt khi nhấn nút
ToggleBtn.MouseButton1Click:Connect(function()
    MainMenu.Visible = not MainMenu.Visible
end)

-- Tính năng Di chuyển (Drag) cho MainMenu trên Điện thoại và Máy tính
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

-- Điều chỉnh kích thước nút bên trong Menu cho vừa vặn size mới
for i, data in ipairs(shaderFuncs) do
    local btn = create("TextButton", MainMenu, {Size = UDim2.new(0.9, 0, 0, 35), Position = UDim2.new(0.05, 0, 0, 10 + (i-1)*40), BackgroundColor3 = Color3.fromRGB(22, 38, 64), Text = data[1], TextColor3 = Color3.new(1,1,1), TextSize = 14})
    create("UICorner", btn, {CornerRadius = UDim.new(0, 6)})
    btn.MouseButton1Click:Connect(function() resetLightingComplete() data[2]() end)
end

local ResetBtn = create("TextButton", MainMenu, {Size = UDim2.new(0.9, 0, 0, 35), Position = UDim2.new(0.05, 0, 0, 270), BackgroundColor3 = Color3.fromRGB(110, 35, 40), Text = "XÓA SHADER", TextColor3 = Color3.new(1,1,1), TextSize = 14})
create("UICorner", ResetBtn, {CornerRadius = UDim.new(0, 6)})
ResetBtn.MouseButton1Click:Connect(resetLightingComplete)
