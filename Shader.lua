local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera
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
    Active = true
})
create("UICorner", ToggleBtn, {CornerRadius = UDim.new(0, 30)})
create("UIStroke", ToggleBtn, {Color = Color3.fromRGB(56, 189, 248), Thickness = 2})

local MainMenu = create("Frame", ScreenGui, {
    Size = UDim2.new(0, 260, 0, 550), 
    Position = UDim2.new(0.5, -130, 0.5, -275), 
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
    Size = UDim2.new(1, -20, 1, -210),
    Position = UDim2.new(0, 10, 0, 45),
    BackgroundTransparency = 1,
    CanvasSize = UDim2.new(0, 0, 0, 300),
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
            
            local connection
            connection = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    connection:Disconnect()
                end
            end)
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            guiObject.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end
makeDraggable(MainMenu)
makeDraggable(ToggleBtn)

local FpsFrame = create("Frame", ScreenGui, {Size = UDim2.new(0, 120, 0, 40), Position = UDim2.new(0.85, 0, 0.05, 0), BackgroundTransparency = 1, Active = true})
local FpsLabel = create("TextLabel", FpsFrame, {Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "FPS: ...", TextSize = 18, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Center, TextYAlignment = Enum.TextYAlignment.Center})
makeDraggable(FpsFrame)

-- Hệ thống Tối ưu hóa Chuyển động Quay Camera (Smooth Mouse Camera)
local SMOOTHNESS = 0.15 
local targetCFrame = camera.CFrame

RunService:BindToRenderStep("VanutSmoothCamera", Enum.RenderPriority.Camera.Value + 1, function(dt)
    if camera.CameraType == Enum.CameraType.Custom then
        targetCFrame = targetCFrame:Lerp(camera.CFrame, math.clamp(dt * (1 / SMOOTHNESS), 0, 1))
        camera.CFrame = targetCFrame
    else
        targetCFrame = camera.CFrame
    end
end)

task.spawn(function()
    local frameCount, hue = 0, 0
    RunService.RenderStepped:Connect(function(dt)
        frameCount = frameCount + 1
        hue = (hue + dt * 0.1) % 1 
        FpsLabel.TextColor3 = Color3.fromHSV(hue, 1, 1)
    end)
    while true do
        task.wait(0.5)
        FpsLabel.Text = "FPS: " .. (frameCount * 2)
        frameCount = 0
    end
end)

local cachedParts = {}
local cachedLights = {}
local cachedVisuals = {}
local isWorldCached = false

local function cacheWorkspace()
    if isWorldCached then return end
    table.clear(cachedParts)
    table.clear(cachedLights)
    table.clear(cachedVisuals)
    
    for i, object in ipairs(Workspace:GetDescendants()) do
        if object:IsA("BasePart") then
            table.insert(cachedParts, object)
        elseif object:IsA("Light") then
            table.insert(cachedLights, object)
        elseif object:IsA("Decal") or object:IsA("Texture") or object:IsA("SurfaceAppearance") then
            table.insert(cachedVisuals, object)
        end
        if i % 1000 == 0 then task.wait() end
    end
    isWorldCached = true
end
task.defer(cacheWorkspace)

local ReflectSliderFrame = create("Frame", MainMenu, {Size = UDim2.new(0.9, 0, 0, 45), Position = UDim2.new(0.05, 0, 1, -110), BackgroundColor3 = Color3.fromRGB(30, 41, 59)})
create("UICorner", ReflectSliderFrame, {CornerRadius = UDim.new(0, 6)})
local ReflectSliderLabel = create("TextLabel", ReflectSliderFrame, {Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1, Text = "Độ Bóng Đồ Họa Cao: 0%", TextColor3 = Color3.fromRGB(148, 163, 184), TextSize = 11, Font = Enum.Font.GothamSemibold})
local ReflectSliderBar = create("Frame", ReflectSliderFrame, {Size = UDim2.new(0.8, 0, 0, 6), Position = UDim2.new(0.1, 0, 0.65, 0), BackgroundColor3 = Color3.fromRGB(51, 65, 85)})
create("UICorner", ReflectSliderBar, {CornerRadius = UDim.new(0, 3)})
local ReflectSliderBtn = create("TextButton", ReflectSliderBar, {Size = UDim2.new(0, 14, 0, 14), Position = UDim2.new(0, -7, 0.5, -7), BackgroundColor3 = Color3.fromRGB(56, 189, 248), Text = ""})
create("UICorner", ReflectSliderBtn, {CornerRadius = UDim.new(0, 7)})

local ReflectActive, currentGlossValue = false, 0
local lastReflectionUpdate = 0

local function updateWorldReflection(glossPercentage)
    ReflectSliderLabel.Text = "Độ Bóng Đồ Họa Cao: " .. math.floor(glossPercentage * 100) .. "%"
    task.spawn(function()
        for i, object in ipairs(cachedParts) do
            if object.Parent and (object.Size.X > 1.5 or object.Size.Z > 1.5) then
                object.Material = Enum.Material.SmoothPlastic 
                object.Reflectance = glossPercentage * 0.35
            end
            if i % 1000 == 0 then task.wait() end
        end
    end)
end

ReflectSliderBtn.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then ReflectActive = true end end)
UserInputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then ReflectActive = false end end)
UserInputService.InputChanged:Connect(function(input)
    if ReflectActive and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local percentage = math.clamp((input.Position.X - ReflectSliderBar.AbsolutePosition.X) / ReflectSliderBar.AbsoluteSize.X, 0, 1)
        ReflectSliderBtn.Position = UDim2.new(percentage, -7, 0.5, -7) 
        currentGlossValue = percentage 
        
        local now = os.clock()
        if now - lastReflectionUpdate >= 0.1 then
            lastReflectionUpdate = now
            updateWorldReflection(percentage)
        end
    end
end)

local timeLockConn, nightActive, isVisualsEnhanced = nil, false, false

local function resetLightingComplete()
    if timeLockConn then timeLockConn:Disconnect() timeLockConn = nil end
    nightActive = false
    
    task.spawn(function()
        for i, part in ipairs(cachedParts) do
            if part.Parent then part.Reflectance = 0 end
            if i % 1000 == 0 then task.wait() end
        end
    end)
    
    for _, v in pairs(Workspace:GetChildren()) do if v.Name == "VanutMeteor" then v:Destroy() end end
    for _, n in pairs({"VanutBloom", "VanutCC", "VanutAtmosphere", "VanutSunRays"}) do local found = Lighting:FindFirstChild(n) if found then found:Destroy() end end
    Lighting.ClockTime = 14 Lighting.Brightness = 2 Lighting.Ambient = Color3.fromRGB(128, 128, 128) Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
end

local function lockTime(targetTime) if timeLockConn then timeLockConn:Disconnect() end timeLockConn = RunService.Heartbeat:Connect(function() Lighting.ClockTime = targetTime end) end

local function spawnAdvancedNight()
    nightActive = true
    task.spawn(function()
        while nightActive do
            task.wait(0.5)
            if math.random(1, 5) == 1 then
                local startPos = Vector3.new(math.random(-200, 200), math.random(120, 180), math.random(-200, 200))
                local meteor = create("Part", Workspace, {Name = "VanutMeteor", Size = Vector3.new(1, 1, 5), Material = Enum.Material.Neon, Color = Color3.fromRGB(200, 240, 255), Anchored = true, CanCollide = false, Position = startPos})
                task.spawn(function()
                    task.wait(0.2)
                    if meteor then meteor:Destroy() end
                end)
            end
        end
    end)
end

-- Hệ thống tăng cường đèn đường/đèn nhà sang trọng kiểu Evade
local function enhanceLightsAndVisuals()
    if isVisualsEnhanced then return end
    isVisualsEnhanced = true
    
    task.spawn(function()
        for i, obj in ipairs(cachedLights) do
            if obj.Parent then
                -- Làm đèn sáng rực rỡ và tỏa rộng ra xung quanh giống Evade
                obj.Brightness = obj.Brightness * 3.5 
                obj.Range = obj.Range * 2.0
                obj.Shadows = true
                
                -- Tạo tông màu ấm áp sang trọng cho ánh đèn nhà/đèn đường
                if obj.Color == Color3.fromRGB(255, 255, 255) then
                    obj.Color = Color3.fromRGB(255, 238, 204)
                end
            end
            if i % 1000 == 0 then task.wait() end
        end
    end)

    task.spawn(function()
        Lighting.GlobalShadows = true 
        Lighting.ShadowSoftness = 0 
        for i, obj in ipairs(cachedParts) do
            if obj.Parent then
                obj.CastShadow = true
                if obj:IsA("MeshPart") or obj:FindFirstChildOfClass("SpecialMesh") then
                    obj.RenderFidelity = Enum.RenderFidelity.Precise
                end
                -- Làm nổi bật các thanh Neon của đèn đường
                if obj.Material == Enum.Material.Neon then
                    obj.LocalTransparencyModifier = 0
                end
            end
            if i % 1000 == 0 then task.wait() end
        end
    end)

    task.spawn(function()
        for i, obj in ipairs(cachedVisuals) do
            if obj.Parent then obj.LocalTransparencyModifier = 0 end
            if i % 1000 == 0 then task.wait() end
        end
    end)
end

local shaderFuncs = {
    {"Bình minh vàng", function() lockTime(6.2) Lighting.Brightness = 2.6 Lighting.OutdoorAmbient = Color3.fromRGB(255, 225, 160) create("SunRaysEffect", Lighting, {Name = "VanutSunRays", Intensity = 0.35, Spread = 0.7}) enhanceLightsAndVisuals() end},
    {"Trưa nắng rực rỡ", function() lockTime(12) Lighting.Brightness = 3.4 Lighting.OutdoorAmbient = Color3.fromRGB(150, 150, 150) create("SunRaysEffect", Lighting, {Name = "VanutSunRays", Intensity = 0.4, Spread = 0.6}) create("BloomEffect", Lighting, {Name = "VanutBloom", Intensity = 0.3, Size = 15, Threshold = 0.85}) enhanceLightsAndVisuals() end},
    {"Hoàng hôn hồng", function() lockTime(17.8) Lighting.Brightness = 2.5 Lighting.OutdoorAmbient = Color3.fromRGB(255, 170, 120) create("SunRaysEffect", Lighting, {Name = "VanutSunRays", Intensity = 0.4, Spread = 0.75}) enhanceLightsAndVisuals() end},
    {"Đêm nhiều sao", function() lockTime(0) Lighting.Brightness = 1.6 Lighting.Ambient = Color3.fromRGB(65, 70, 95) Lighting.OutdoorAmbient = Color3.fromRGB(45, 50, 70) spawnAdvancedNight() enhanceLightsAndVisuals() end},
    {"Cinematic Lofi", function() lockTime(16.5) Lighting.Brightness = 2.2 create("ColorCorrectionEffect", Lighting, {Name = "VanutCC", Saturation = -0.1, Contrast = 0.15, TintColor = Color3.fromRGB(255, 240, 220)}) create("BloomEffect", Lighting, {Name = "VanutBloom", Intensity = 0.2, Size = 10, Threshold = 0.9}) enhanceLightsAndVisuals() end},
    {"Cyberpunk Neon", function() lockTime(19) Lighting.Brightness = 2.8 create("ColorCorrectionEffect", Lighting, {Name = "VanutCC", Saturation = 0.3, Contrast = 0.2, TintColor = Color3.fromRGB(230, 220, 255)}) create("BloomEffect", Lighting, {Name = "VanutBloom", Intensity = 0.6, Size = 24, Threshold = 0.5}) enhanceLightsAndVisuals() end}
}

for i, data in ipairs(shaderFuncs) do
    local btn = create("TextButton", ScrollFrame, {Size = UDim2.new(0.96, 0, 0, 38), Position = UDim2.new(0.02, 0, 0, 5 + (i-1)*44), BackgroundColor3 = Color3.fromRGB(30, 41, 59), Text = data[1], TextColor3 = Color3.fromRGB(241, 245, 249), TextSize = 13, Font = Enum.Font.GothamSemibold})
    create("UICorner", btn, {CornerRadius = UDim.new(0, 6)}) create("UIStroke", btn, {Color = Color3.fromRGB(51, 65, 85), Thickness = 1})
    btn.MouseButton1Click:Connect(function() resetLightingComplete() data[2]() end)
end

local ResetBtn = create("TextButton", MainMenu, {Size = UDim2.new(0.9, 0, 0, 38), Position = UDim2.new(0.05, 0, 1, -48), BackgroundColor3 = Color3.fromRGB(239, 68, 68), Text = "XÓA SHADER ALL", TextColor3 = Color3.fromRGB(255, 255, 255), TextSize = 13, Font = Enum.Font.GothamBold})
create("UICorner", ResetBtn, {CornerRadius = UDim.new(0, 6)})
ResetBtn.MouseButton1Click:Connect(resetLightingComplete)
