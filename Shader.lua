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
    Size = UDim2.new(0, 60, 0, 60),
    Position = UDim2.new(0.05, 0, 0.1, 0),
    BackgroundColor3 = Color3.fromRGB(30, 41, 59),
    Text = "Vanut",
    TextColor3 = Color3.fromRGB(255, 255, 255),
    TextSize = 15,
    Font = Enum.Font.GothamBold,
    Active = true,
    Draggable = true
})
create("UICorner", ToggleBtn, {CornerRadius = UDim.new(0, 30)})
create("UIStroke", ToggleBtn, {Color = Color3.fromRGB(56, 189, 248), Thickness = 2})

local MainMenu = create("Frame", ScreenGui, {
    Size = UDim2.new(0, 260, 0, 605), 
    Position = UDim2.new(0.5, -130, 0.5, -302), 
    BackgroundColor3 = Color3.fromRGB(15, 23, 42), 
    Visible = false
})
create("UICorner", MainMenu, {CornerRadius = UDim.new(0, 12)})
create("UIStroke", MainMenu, {Color = Color3.fromRGB(51, 65, 85), Thickness = 1.5})

local ScrollFrame = create("ScrollingFrame", MainMenu, {
    Size = UDim2.new(1, -20, 1, -265),
    Position = UDim2.new(0, 10, 0, 45),
    BackgroundTransparency = 1,
    CanvasSize = UDim2.new(0, 0, 0, 500),
    ScrollBarThickness = 2,
    ScrollBarImageColor3 = Color3.fromRGB(56, 189, 248)
})

ToggleBtn.MouseButton1Click:Connect(function() MainMenu.Visible = not MainMenu.Visible end)

local function makeDraggable(guiObject)
    local dragging, dragStart, startPos
    guiObject.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = guiObject.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            guiObject.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end end)
end
makeDraggable(MainMenu)

local FpsLabel = create("TextLabel", create("Frame", ScreenGui, {Size = UDim2.new(0, 120, 0, 40), Position = UDim2.new(0.85, 0, 0.05, 0), BackgroundTransparency = 1}), {Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "FPS: ...", TextSize = 18, Font = Enum.Font.GothamBold})
local frameCount, lastUpdate = 0, os.clock()
RunService.RenderStepped:Connect(function()
    frameCount += 1
    local now = os.clock()
    if now - lastUpdate >= 0.5 then FpsLabel.Text = "FPS: " .. math.floor(frameCount / (now - lastUpdate)) frameCount = 0 lastUpdate = now end
end)

local originalMaterials = {}
local timeLockConn, starConn, brightConn

local function resetLightingComplete()
    if timeLockConn then timeLockConn:Disconnect() timeLockConn = nil end
    if starConn then starConn:Disconnect() starConn = nil end
    if brightConn then brightConn:Disconnect() brightConn = nil end
    for part, mat in pairs(originalMaterials) do if part and part:IsA("BasePart") then part.Material = mat part.Reflectance = 0 end end
    table.clear(originalMaterials)
    for _, n in pairs({"VanutBloom", "VanutCC", "VanutAtmosphere", "VanutSunRays", "VanutSky", "VanutMotionBlur"}) do local f = Lighting:FindFirstChild(n) if f then f:Destroy() end end
    RunService:UnbindFromRenderStep("VanutMotionBlurUpdate")
    Lighting.ClockTime = 14 Lighting.Brightness = 2
end

local shaderFuncs = {
    {"Bình minh", function() Lighting.ClockTime = 6.2 create("SunRaysEffect", Lighting, {Name = "VanutSunRays", Intensity = 0.35}) end},
    {"Trưa", function() Lighting.ClockTime = 12 create("BloomEffect", Lighting, {Name = "VanutBloom", Intensity = 0.3}) end},
    {"Hoàng hôn", function() Lighting.ClockTime = 17.8 create("SunRaysEffect", Lighting, {Name = "VanutSunRays", Intensity = 0.4}) end},
    {"Đêm", function() Lighting.ClockTime = 0 create("Sky", Lighting, {Name = "VanutSky", SkyboxBk = "rbxassetid://6008860012", StarCount = 5000}) end},
    {"Làm nét Texture", function()
        for _, obj in pairs(Workspace:GetDescendants()) do
            if obj:IsA("BasePart") then
                if not originalMaterials[obj] then originalMaterials[obj] = obj.Material end
                obj.Reflectance = 0.05
            end
        end
    end},
    {"Bật Motion Blur (Mượt)", function()
        local blur = create("BlurEffect", Lighting, {Name = "VanutMotionBlur", Size = 0})
        local camera = Workspace.CurrentCamera
        local lastRot = camera.CFrame.Rotation
        RunService:BindToRenderStep("VanutMotionBlurUpdate", Enum.RenderPriority.Camera.Value + 1, function()
            local currRot = camera.CFrame.Rotation
            local delta = math.acos(math.clamp(currRot.LookVector:Dot(lastRot.LookVector), -1, 1))
            blur.Size = blur.Size + (math.clamp(delta * 12, 0, 3.5) - blur.Size) * 0.4
            lastRot = currRot
        end)
    end}
}

for i, data in ipairs(shaderFuncs) do
    local btn = create("TextButton", ScrollFrame, {Size = UDim2.new(0.96, 0, 0, 38), Position = UDim2.new(0.02, 0, 0, 5 + (i-1)*44), BackgroundColor3 = Color3.fromRGB(30, 41, 59), Text = data[1], TextColor3 = Color3.fromRGB(241, 245, 249), TextSize = 13, Font = Enum.Font.GothamSemibold})
    create("UICorner", btn, {CornerRadius = UDim.new(0, 6)})
    btn.MouseButton1Click:Connect(function() resetLightingComplete() data[2]() end)
end

local ResetBtn = create("TextButton", MainMenu, {Size = UDim2.new(0.9, 0, 0, 38), Position = UDim2.new(0.05, 0, 1, -48), BackgroundColor3 = Color3.fromRGB(239, 68, 68), Text = "XÓA SHADER", TextColor3 = Color3.fromRGB(255, 255, 255), TextSize = 13, Font = Enum.Font.GothamBold})
create("UICorner", ResetBtn, {CornerRadius = UDim.new(0, 6)})
ResetBtn.MouseButton1Click:Connect(resetLightingComplete)
