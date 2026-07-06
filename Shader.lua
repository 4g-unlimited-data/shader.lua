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

-- UI chính
local ToggleBtn = create("TextButton", ScreenGui, {
    Size = UDim2.new(0, 60, 0, 60), Position = UDim2.new(0.05, 0, 0.1, 0),
    BackgroundColor3 = Color3.fromRGB(30, 41, 59), Text = "Vanut",
    TextColor3 = Color3.fromRGB(255, 255, 255), TextSize = 15, Font = Enum.Font.GothamBold,
    Active = true, Draggable = true
})
create("UICorner", ToggleBtn, {CornerRadius = UDim.new(0, 30)})

local MainMenu = create("Frame", ScreenGui, {
    Size = UDim2.new(0, 260, 0, 400), Position = UDim2.new(0.5, -130, 0.5, -200),
    BackgroundColor3 = Color3.fromRGB(15, 23, 42), Visible = false
})
create("UICorner", MainMenu, {CornerRadius = UDim.new(0, 12)})

ToggleBtn.MouseButton1Click:Connect(function() MainMenu.Visible = not MainMenu.Visible end)

-- Hệ thống Shader Bóng Đổ Nét & Đồ Họa Mượt
local function applySharpGraphics()
    Lighting.Technology = Enum.Technology.Future
    Lighting.ShadowMapDisplayDistance = 1000
    
    local cc = Lighting:FindFirstChild("VanutCC") or create("ColorCorrectionEffect", Lighting, {Name = "VanutCC"})
    cc.Contrast = 0.2
    cc.Brightness = 0.05
    cc.Saturation = 0.1
    
    local bloom = Lighting:FindFirstChild("VanutBloom") or create("BloomEffect", Lighting, {Name = "VanutBloom"})
    bloom.Intensity = 0.15
    bloom.Threshold = 0.8
    
    -- Làm mượt vật liệu toàn map
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            if obj.Material == Enum.Material.Plastic then obj.Material = Enum.Material.SmoothPlastic end
        end
    end
end

-- Nút kích hoạt
local Btn = create("TextButton", MainMenu, {
    Size = UDim2.new(0.9, 0, 0, 50), Position = UDim2.new(0.05, 0, 0.2, 0),
    BackgroundColor3 = Color3.fromRGB(56, 189, 248), Text = "KÍCH HOẠT ĐỒ HỌA MƯỢT",
    Font = Enum.Font.GothamBold, TextSize = 14
})
create("UICorner", Btn, {CornerRadius = UDim.new(0, 8)})

Btn.MouseButton1Click:Connect(function()
    applySharpGraphics()
    Btn.Text = "ĐÃ ÁP DỤNG"
    task.wait(1)
    Btn.Text = "KÍCH HOẠT ĐỒ HỌA MƯỢT"
end)
