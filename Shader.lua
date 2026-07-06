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

local ToggleBtn = create("TextButton", ScreenGui, {
    Size = UDim2.new(0, 60, 0, 60), Position = UDim2.new(0.05, 0, 0.1, 0),
    BackgroundColor3 = Color3.fromRGB(30, 41, 59), Text = "Vanut",
    TextColor3 = Color3.fromRGB(255, 255, 255), TextSize = 15, Font = Enum.Font.GothamBold,
    Active = true, Draggable = true
})
create("UICorner", ToggleBtn, {CornerRadius = UDim.new(0, 30)})

local MainMenu = create("Frame", ScreenGui, {
    Size = UDim2.new(0, 260, 0, 500), Position = UDim2.new(0.5, -130, 0.5, -250),
    BackgroundColor3 = Color3.fromRGB(15, 23, 42), Visible = false
})
create("UICorner", MainMenu, {CornerRadius = UDim.new(0, 12)})

local ScrollFrame = create("ScrollingFrame", MainMenu, {
    Size = UDim2.new(1, -20, 1, -100), Position = UDim2.new(0, 10, 0, 45),
    BackgroundTransparency = 1, CanvasSize = UDim2.new(0, 0, 0, 500)
})

ToggleBtn.MouseButton1Click:Connect(function() MainMenu.Visible = not MainMenu.Visible end)

local originalMaterials = {}
local function resetEverything()
    for part, mat in pairs(originalMaterials) do if part and part:IsA("BasePart") then part.Material = mat part.Reflectance = 0 end end
    table.clear(originalMaterials)
    for _, n in pairs({"VanutBloom", "VanutCC", "VanutSunRays", "VanutSky"}) do local f = Lighting:FindFirstChild(n) if f then f:Destroy() end end
    Lighting.Brightness = 2
end

local shaderFuncs = {
    {"Đồ Họa Cinematic Nét", function()
        create("ColorCorrectionEffect", Lighting, {Name = "VanutCC", Contrast = 0.2, Saturation = 0.1})
        create("BloomEffect", Lighting, {Name = "VanutBloom", Intensity = 0.1, Size = 10, Threshold = 0.8})
    end},
    {"Làm nét Texture (Tối ưu)", function()
        for _, obj in pairs(Workspace:GetDescendants()) do
            if obj:IsA("BasePart") then
                if not originalMaterials[obj] then originalMaterials[obj] = obj.Material end
                if obj.Material == Enum.Material.Plastic then obj.Material = Enum.Material.Concrete end
            end
        end
    end},
    {"XÓA SHADER ALL", resetEverything}
}

for i, data in ipairs(shaderFuncs) do
    local btn = create("TextButton", ScrollFrame, {
        Size = UDim2.new(0.9, 0, 0, 40), Position = UDim2.new(0.05, 0, 0, (i-1)*50),
        BackgroundColor3 = Color3.fromRGB(30, 41, 59), Text = data[1], TextColor3 = Color3.fromRGB(255, 255, 255)
    })
    create("UICorner", btn, {CornerRadius = UDim.new(0, 6)})
    btn.MouseButton1Click:Connect(data[2])
end
