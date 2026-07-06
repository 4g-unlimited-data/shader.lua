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

local MenuTitle = create("TextLabel", MainMenu, {
    Size = UDim2.new(1, 0, 0, 40),
    BackgroundTransparency = 1,
    Text = "VANUT SHADER HUB",
    TextColor3 = Color3.fromRGB(255, 255, 255),
    TextSize = 14,
    Font = Enum.Font.GothamBold
})

local ScrollFrame = create("ScrollingFrame", MainMenu, {
    Size = UDim2.new(1, -20, 1, -265),
    Position = UDim2.new(0, 10, 0, 45),
    BackgroundTransparency = 1,
    CanvasSize = UDim2.new(0, 0, 0, 500),
    ScrollBarThickness = 2,
    ScrollBarImageColor3 = Color3.fromRGB(56, 189, 248)
})

ToggleBtn.MouseButton1Click:Connect(function()
    MainMenu.Visible = not MainMenu.Visible
end)

local function makeDraggable(guiObject)
    local dragging, dragInput, dragStart, startPos
    guiObject.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = guiObject.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    guiObject.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            guiObject.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

makeDraggable(MainMenu)

local FpsFrame = create("Frame", ScreenGui, {
    Size = UDim2.new(0, 120, 0, 40),
    Position = UDim2.new(0.85, 0, 0.05, 0),
    BackgroundTransparency = 1,
    Active = true
})
local FpsLabel = create("TextLabel", FpsFrame, {
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundTransparency = 1,
    Text = "FPS: ...",
    TextSize = 18,
    Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Center,
    TextYAlignment = Enum.TextYAlignment.Center
})
makeDraggable(FpsFrame)

local frameCount = 0
local lastUpdate = os.clock()
local hue = 0
RunService.RenderStepped:Connect(function(dt)
    frameCount = frameCount + 1
    local now = os.clock()
    if now - lastUpdate >= 0.5 then
        local fps = math.floor(frameCount / (now - lastUpdate))
        FpsLabel.Text = "FPS: " .. fps
        frameCount = 0
        lastUpdate = now
    end
    hue = (hue + dt * 0.1) % 1
    FpsLabel.TextColor3 = Color3.fromHSV(hue, 1, 1)
end)

local SliderFrame = create("Frame", MainMenu, {
    Size = UDim2.new(0.9, 0, 0, 45),
    Position = UDim2.new(0.05, 0, 1, -255),
    BackgroundColor3 = Color3.fromRGB(30, 41, 59)
})
create("UICorner", SliderFrame, {CornerRadius = UDim.new(0, 6)})
local SliderBar = create("Frame", SliderFrame, {
    Size = UDim2.new(0.8, 0, 0, 6),
    Position = UDim2.new(0.1, 0, 0.65, 0),
    BackgroundColor3 = Color3.fromRGB(51, 65, 85)
})
create("UICorner", SliderBar, {CornerRadius = UDim.new(0, 3)})
local SliderBtn = create("TextButton", SliderBar, {
    Size = UDim2.new(0, 14, 0, 14),
    Position = UDim2.new(0.4, -7, 0.5, -7),
    BackgroundColor3 = Color3.fromRGB(56, 189, 248),
    Text = ""
})
create("UICorner", SliderBtn, {CornerRadius = UDim.new(0, 7)})

local SliderActive = false
SliderBtn.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then SliderActive = true end end)
UserInputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then SliderActive = false end end)
UserInputService.InputChanged:Connect(function(input)
    if SliderActive and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local percentage = math.clamp((input.Position.X - SliderBar.AbsolutePosition.X) / SliderBar.AbsoluteSize.X, 0, 1)
        SliderBtn.Position = UDim2.new(percentage, -7, 0.5, -7)
        local targetSize = 12 + (percentage * 20)
        FpsLabel.TextSize = targetSize
        FpsFrame.Size = UDim2.new(0, targetSize * 6, 0, targetSize * 2)
    end
end)

local ReflectSliderFrame = create("Frame", MainMenu, {
    Size = UDim2.new(0.9, 0, 0, 45),
    Position = UDim2.new(0.05, 0, 1, -200),
    BackgroundColor3 = Color3.fromRGB(30, 41, 59)
})
create("UICorner", ReflectSliderFrame, {CornerRadius = UDim.new(0, 6)})
local ReflectSliderLabel = create("TextLabel", ReflectSliderFrame, {
    Size = UDim2.new(1, 0, 0, 20),
    BackgroundTransparency = 1,
    Text = "Độ Bóng Đồ Họa Cao: 0%",
    TextColor3 = Color3.fromRGB(148, 163, 184),
    TextSize = 11,
    Font = Enum.Font.GothamSemibold
})
local ReflectSliderBar = create("Frame", ReflectSliderFrame, {
    Size = UDim2.new(0.8, 0, 0, 6),
    Position = UDim2.new(0.1, 0, 0.65, 0),
    BackgroundColor3 = Color3.fromRGB(51, 65, 85)
})
create("UICorner", ReflectSliderBar, {CornerRadius = UDim.new(0, 3)})
local ReflectSliderBtn = create("TextButton", ReflectSliderBar, {
    Size = UDim2.new(0, 14, 0, 14),
    Position = UDim2.new(0, -7, 0.5, -7),
    BackgroundColor3 = Color3.fromRGB(56, 189, 248),
    Text = ""
})
create("UICorner", ReflectSliderBtn, {CornerRadius = UDim.new(0, 7)})

local ReflectActive = false
local originalMaterials = {}
local timeLockConn, starConn, brightConn

local function disableMotionBlurOnly()
    RunService:UnbindFromRenderStep("VanutMotionBlurUpdate")
    local blur = Lighting:FindFirstChild("VanutMotionBlur")
    if blur then blur:Destroy() end
end

local function resetLightingComplete()
    if timeLockConn then timeLockConn:Disconnect() timeLockConn = nil end
    if starConn then starConn:Disconnect() starConn = nil end
    if brightConn then brightConn:Disconnect() brightConn = nil end
    disableMotionBlurOnly()
    for part, mat in pairs(originalMaterials) do if part and part:IsA("BasePart") then part.Material = mat part.Reflectance = 0 end end
    table.clear(originalMaterials)
    for _, v in pairs(Workspace:GetChildren()) do if v.Name == "VanutMeteor" then v:Destroy() end end
    for _, n in pairs({"VanutBloom", "VanutCC", "VanutAtmosphere", "VanutSunRays", "VanutSky"}) do local found = Lighting:FindFirstChild(n) if found then found:Destroy() end end
    Lighting.ClockTime = 14
    Lighting.Brightness = 2
    Lighting.Ambient = Color3.fromRGB(128, 128, 128)
end

local function updateWorldReflection(glossPercentage)
    ReflectSliderLabel.Text = "Độ Bóng Đồ Họa Cao: " .. math.floor(glossPercentage * 100) .. "%"
    for _, object in pairs(Workspace:GetDescendants()) do
        if object:IsA("BasePart") and (object.Size.X > 1.5 or object.Size.Z > 1.5) then
            object.Material = Enum.Material.SmoothPlastic
            object.Reflectance = glossPercentage * 0.65
        end
    end
end

ReflectSliderBtn.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then ReflectActive = true end end)
UserInputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then ReflectActive = false end end)
UserInputService.InputChanged:Connect(function(input)
    if ReflectActive and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local percentage = math.clamp((input.Position.X - ReflectSliderBar.AbsolutePosition.X) / ReflectSliderBar.AbsoluteSize.X, 0, 1)
        ReflectSliderBtn.Position = UDim2.new(percentage, -7, 0.5, -7)
        updateWorldReflection(percentage)
    end
end)

local shaderFuncs = {
    {"Bình minh vàng", function() Lighting.ClockTime = 6.2 Lighting.Brightness = 2.6 create("SunRaysEffect", Lighting, {Name = "VanutSunRays", Intensity = 0.35}) end},
    {"Trưa nắng rực rỡ", function() Lighting.ClockTime = 12 Lighting.Brightness = 3.4 create("BloomEffect", Lighting, {Name = "VanutBloom", Intensity = 0.3}) end},
    {"Chỉ Nét Texture & Mượt", function()
        for _, object in pairs(Workspace:GetDescendants()) do
            if object:IsA("Decal") or object:IsA("Texture") then object.LocalTransparencyModifier = object.LocalTransparencyModifier end
        end
        disableMotionBlurOnly()
        local blur = create("BlurEffect", Lighting, {Name = "VanutMotionBlur", Size = 0})
        local camera = Workspace.CurrentCamera
        local lastRotation = camera.CFrame.Rotation
        RunService:BindToRenderStep("VanutMotionBlurUpdate", Enum.RenderPriority.Camera.Value + 1, function()
            local currentRotation = camera.CFrame.Rotation
            local deltaAngle = math.acos(math.clamp(currentRotation.LookVector:Dot(lastRotation.LookVector), -1, 1))
            blur.Size = math.clamp(deltaAngle * 12, 0, 3.5)
            lastRotation = currentRotation
        end)
    end}
}

for i, data in ipairs(shaderFuncs) do
    local btn = create("TextButton", ScrollFrame, {
        Size = UDim2.new(0.96, 0, 0, 38), 
        Position = UDim2.new(0.02, 0, 0, 5 + (i-1)*44), 
        BackgroundColor3 = Color3.fromRGB(30, 41, 59), 
        Text = data[1], 
        TextColor3 = Color3.fromRGB(241, 245, 249), 
        TextSize = 13,
        Font = Enum.Font.GothamSemibold
    })
    create("UICorner", btn, {CornerRadius = UDim.new(0, 6)})
    btn.MouseButton1Click:Connect(function() resetLightingComplete() data[2]() end)
end
