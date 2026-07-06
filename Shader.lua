-- [[ vanut v6.4 / rimuru tempest - Ultimate Minimalist Mobile Edition ]] --
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local CoreGui = game:GetService("CoreGui")

local player = Players.LocalPlayer
local function getChar() return player.Character or Workspace:FindFirstChild(player.Name) end

local targetGui = player:WaitForChild("PlayerGui", 10)
if not targetGui then return end
if targetGui:FindFirstChild("Vanut_Rimuru_v64") then targetGui["Vanut_Rimuru_v64"]:Destroy() end

local function create(cls, parent, props)
    local inst = Instance.new(cls)
    for k, v in pairs(props or {}) do inst[k] = v end
    if parent then inst.Parent = parent end
    return inst
end
local function addCorner(parent, r) create("UICorner", parent, {CornerRadius = UDim.new(0, r or 6)}) end
local function addStroke(parent) create("UIStroke", parent, {Color = Color3.fromRGB(15, 30, 50), Thickness = 1.2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}) end

local ScreenGui = create("ScreenGui", targetGui, {Name = "Vanut_Rimuru_v64", ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling})

-- --- CORE VARIABLE STORAGE ---
local originalData, currentMode, currentShader, currentGloss = {}, 0, 0, 20
local effectConn, autoResetConn, starConn, timeLockConn, skyLoopConn = nil, nil, nil, nil, nil
local NewHitboxEnabled = false
local HitboxColor = Color3.fromRGB(0, 255, 220)
local currentShadowPercent = 100

local function backupProps(obj)
    if obj:IsA("BasePart") and not originalData[obj] then
        originalData[obj] = {
            Material = obj.Material, 
            Color = obj.Color, 
            Reflectance = obj.Reflectance, 
            CastShadow = obj.CastShadow, 
            TextureID = obj:IsA("MeshPart") and obj.TextureID or nil,
            Transparency = obj.Transparency
        }
    end
end

task.spawn(function()
    local descendants = Workspace:GetDescendants()
    for i, obj in ipairs(descendants) do
        if obj:IsA("BasePart") and not obj:IsDescendantOf(getChar() or Workspace) then
            backupProps(obj)
        end
        if i % 300 == 0 then task.wait() end
    end
end)

local function isIgnored(obj)
    local char = getChar()
    if char and (obj:IsDescendantOf(char) or obj:FindFirstAncestorOfClass("Tool") or obj:FindFirstAncestorOfClass("Accessory")) then return true end
    local m = obj:FindFirstAncestorOfClass("Model") return m and m:FindFirstChildOfClass("Humanoid") and true or false
end

local function clearFog()
    Lighting.FogStart = 999999
    Lighting.FogEnd = 999999
    local atm = Lighting:FindFirstChildOfClass("Atmosphere")
    if atm then atm:Destroy() end
end

-- --- HỆ THỐNG HITBOX MỚI ĐỘC LẬP (MỤC 5) ---
local function applyModernHitbox(target)
    if not target or target == getChar() or not target:FindFirstChild("HumanoidRootPart") then return end
    local hrp = target.HumanoidRootPart
    local oldBox = hrp:FindFirstChild("VanutHitbox") if oldBox then oldBox:Destroy() end
    
    local box = hrp:FindFirstChild("VanutNewHitbox")
    if NewHitboxEnabled then
        if not box then
            create("SelectionBox", hrp, {
                Name = "VanutNewHitbox",
                Color3 = HitboxColor,
                LineThickness = 0.03,
                Adornee = target,
                Transparency = 0.3
            })
        end
    else
        if box then box:Destroy() end
    end
end

local function refreshAllHitboxes()
    for _, p in pairs(Players:GetPlayers()) do if p.Character then applyModernHitbox(p.Character) end end
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("Humanoid") and obj.Parent and obj.Parent ~= getChar() then
            applyModernHitbox(obj.Parent)
        end
    end
end

local function updateGlossiness()
    local ratio = currentGloss / 100
    Lighting.EnvironmentSpecularScale = ratio
    if currentGloss > 60 then
        Lighting.EnvironmentDiffuseScale = ratio * 0.6
    end
    for obj, props in pairs(originalData) do
        if obj and obj.Parent and obj:IsA("BasePart") and not isIgnored(obj) then
            pcall(function() obj.Reflectance = ratio end)
        end
    end
end

-- CƠ CHẾ KHÓA SKYBOX VÀ DIỆT CLOUDS (CHỐNG GAME ĐÈ)
local function applyCustomSky(skyId)
    if skyLoopConn then skyLoopConn:Disconnect() end
    
    local function forceSky()
        if Workspace:FindFirstChildOfClass("Terrain") then
            for _, c in pairs(Workspace:FindFirstChildOfClass("Terrain"):GetChildren()) do
                if c:IsA("Clouds") then c:Destroy() end
            end
        end
        for _, c in pairs(Lighting:GetChildren()) do
            if c:IsA("Clouds") then c:Destroy() end
        end

        local hasOurSky = false
        for _, obj in pairs(Lighting:GetChildren()) do
            if obj:IsA("Sky") then
                if obj.Name == "VanutSky" and obj.SkyboxBk == "rbxassetid://"..skyId then
                    hasOurSky = true
                else
                    obj:Destroy()
                end
            end
        end

        if not hasOurSky then
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
    end
    
    forceSky()
    skyLoopConn = RunService.Heartbeat:Connect(forceSky)
end

-- HÀM ÉP ĐỒ HỌA VÀ ĐỔ BÓNG GIẢ LẬP KỸ THUẬT SỐ CHO ĐỒ HỌA THẤP
local function forceHighVisualAndSharpness()
    pcall(function()
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level21
        Lighting.GlobalShadows = true
        Lighting.ShadowSoftness = (100 - currentShadowPercent) / 100
        
        for _, obj in pairs(game:GetDescendants()) do
            if obj:IsA("BasePart") then
                obj.CastShadow = true
                if obj.Material == Enum.Material.SmoothPlastic or obj.Material == Enum.Material.Plastic then
                    obj.Material = Enum.Material.Fabric
                end
            end
            if obj:IsA("MeshPart") then
                obj.RenderFidelity = Enum.RenderFidelity.Precise
            end
        end
    end)
end

local function resetLightingComplete()
    if timeLockConn then timeLockConn:Disconnect() timeLockConn = nil end
    if starConn then starConn:Disconnect() starConn = nil end
    if skyLoopConn then skyLoopConn:Disconnect() skyLoopConn = nil end
    for _, v in pairs(Workspace:GetChildren()) do if v.Name == "VanutMeteor" or v.Name == "VanutFirefly" then v:Destroy() end end
    for _, n in pairs({"VanutBloom", "VanutCC", "VanutAtmosphere", "VanutSunRays", "VanutSky"}) do 
        local found = Lighting:FindFirstChild(n) if found then found:Destroy() end 
    end
    Lighting.ClockTime = 14
    Lighting.GlobalShadows = true
    Lighting.Brightness = 2
    Lighting.Ambient = Color3.fromRGB(128, 128, 128)
    Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
    Lighting.EnvironmentSpecularScale = 0
    Lighting.EnvironmentDiffuseScale = 0
    Lighting.FogStart = 0
    Lighting.FogEnd = 100000
end

local function resetPartsComplete()
    currentMode = 0
    if effectConn then effectConn:Disconnect() effectConn = nil end
    for obj, props in pairs(originalData) do
        if obj and obj.Parent then
            pcall(function()
                obj.Material = props.Material
                obj.Color = props.Color
                obj.Reflectance = props.Reflectance
                obj.CastShadow = props.CastShadow
                obj.Transparency = props.Transparency
                if obj:IsA("MeshPart") and props.TextureID then obj.TextureID = props.TextureID end
            end)
        end
    end
end

local function applyRules(obj, mode)
    if not obj or not obj.Parent or mode == 0 then return end
    
    if mode == 6 then
        if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Fire") or obj:IsA("Smoke") or obj:IsA("Sparkles") or obj:IsA("Beam") then 
            obj:Destroy() return 
        end
        if obj:IsA("BasePart") and not isIgnored(obj) then
            obj.Material = Enum.Material.SmoothPlastic
            obj.Color = Color3.fromRGB(225, 225, 225)
            obj.CastShadow = true
            obj.Reflectance = currentGloss / 100
            if obj:IsA("MeshPart") then obj.TextureID = "" end
        elseif obj:IsA("Decal") or obj:IsA("Texture") or obj:IsA("Shirt") or obj:IsA("Pants") or obj:IsA("ShirtGraphic") then 
            obj:Destroy() 
        end
        return
    end

    if isIgnored(obj) then return end
    
    if obj:IsA("BasePart") then
        obj.Material = Enum.Material.SmoothPlastic
        if mode == 1 then
        elseif mode == 2 or mode == 3 then 
            obj.Reflectance = currentGloss / 100
        elseif mode == 4 then 
            obj.Color = Color3.fromRGB(255, 255, 255)
            obj.Reflectance = currentGloss / 100
        elseif mode == 5 then
            obj.Color = Color3.fromRGB(254, 254, 254)
            obj.Reflectance = currentGloss / 100
        end
    elseif (obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Fire") or obj:IsA("Smoke") or obj:IsA("Sparkles") or obj:IsA("Beam")) then
        if mode == 2 or mode == 3 or mode == 5 then 
            obj:Destroy() 
        end
    end
end

local function startChunkEngine(mode)
    currentMode = mode 
    resetPartsComplete()
    currentMode = mode
    clearFog()
    
    task.spawn(function()
        local descendants = Workspace:GetDescendants()
        for i, obj in ipairs(descendants) do
            applyRules(obj, mode)
            if i % 300 == 0 then task.wait() end
        end
    end)
    
    effectConn = Workspace.DescendantAdded:Connect(function(d)
        if currentMode > 0 then 
            task.defer(function() 
                if d and d.Parent then 
                    if d:IsA("BasePart") and not isIgnored(d) then backupProps(d) end 
                    applyRules(d, currentMode) 
                end 
            end) 
        end
    end)
end

-- --- THAY THẾ UI CŨ ---
local ToggleMenuBtn = create("TextButton", ScreenGui, {
    Size = UDim2.new(0, 36, 0, 36),
    Position = UDim2.new(0, 15, 0, 15),
    BackgroundColor3 = Color3.fromRGB(12, 22, 40),
    Text = "⚙️",
    TextColor3 = Color3.fromRGB(0, 215, 255),
    Font = Enum.Font.GothamBold,
    TextSize = 16,
    Visible = false,
    ZIndex = 5
}) addCorner(ToggleMenuBtn, 18) addStroke(ToggleMenuBtn)

local MainMenu = create("Frame", ScreenGui, {
    Size = UDim2.new(0, 420, 0, 320),
    Position = UDim2.new(0.5, -210, 0.35, -160),
    BackgroundColor3 = Color3.fromRGB(10, 16, 28),
    Visible = false,
    ZIndex = 10
}) addCorner(MainMenu, 8) addStroke(MainMenu)

create("TextLabel", MainMenu, {
    Size = UDim2.new(1, 0, 0, 30),
    BackgroundColor3 = Color3.fromRGB(16, 26, 44),
    Text = "BẢNG ĐIỀU KHIỂN - RIMURU ENGINE V6.4 ULTIMATE",
    TextColor3 = Color3.fromRGB(255, 255, 255),
    Font = Enum.Font.GothamBold,
    TextSize = 11,
    ZIndex = 11
}) addCorner(MainMenu:FindFirstChildOfClass("TextLabel"), 8)

ToggleMenuBtn.MouseButton1Click:Connect(function()
    MainMenu.Visible = not MainMenu.Visible
end)

local TabContainer = create("Frame", MainMenu, {Size = UDim2.new(1, 0, 0, 28), Position = UDim2.new(0, 0, 0, 30), BackgroundColor3 = Color3.fromRGB(14, 22, 38), ZIndex = 11})
local ContentContainer = create("Frame", MainMenu, {Size = UDim2.new(1, -12, 1, -68), Position = UDim2.new(0, 6, 0, 62), BackgroundTransparency = 1, ZIndex = 11})
local Pages = {}

local function createTab(name, order, pageFrame)
    pageFrame.Size, pageFrame.BackgroundTransparency, pageFrame.Visible, pageFrame.Parent = UDim2.new(1, 0, 1, 0), 1, false, ContentContainer
    Pages[name] = pageFrame
    
    local tBtn = create("TextButton", TabContainer, {
        Size = UDim2.new(0.2, 0, 1, 0), 
        Position = UDim2.new(0.2 * (order - 1), 0, 0, 0), 
        BackgroundColor3 = Color3.fromRGB(18, 28, 46), 
        Text = name, 
        TextColor3 = Color3.fromRGB(140, 160, 180), 
        Font = Enum.Font.GothamBold, 
        TextSize = 10, 
        BorderSizePixel = 0, 
        ZIndex = 12
    })
    
    tBtn.MouseButton1Click:Connect(function()
        for k, p in pairs(Pages) do p.Visible = (k == name) end
        for _, btn in pairs(TabContainer:GetChildren()) do if btn:IsA("TextButton") then btn.BackgroundColor3, btn.TextColor3 = Color3.fromRGB(18, 28, 46), Color3.fromRGB(140, 160, 180) end end
        tBtn.BackgroundColor3, tBtn.TextColor3 = Color3.fromRGB(24, 42, 70), Color3.fromRGB(0, 210, 255)
    end)
    if order == 1 then tBtn.BackgroundColor3, tBtn.TextColor3, pageFrame.Visible = Color3.fromRGB(24, 42, 70), Color3.fromRGB(0, 210, 255), true end
end

makeDraggable = function(f, h)
    local d, dStart, sPos
    h.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then d, dStart, sPos = true, i.Position, f.Position end end)
    UserInputService.InputChanged:Connect(function(i) if d and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then local delta = i.Position - dStart f.Position = UDim2.new(sPos.X.Scale, sPos.X.Offset + delta.X, sPos.Y.Scale, sPos.Y.Offset + delta.Y) end end)
    UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then d = false end end)
end
makeDraggable(ToggleMenuBtn, ToggleMenuBtn) makeDraggable(MainMenu, MainMenu:FindFirstChildOfClass("TextLabel"))

-- =======================================================================
-- MỤC 1: THÔNG TIN NGƯỜI DÙNG & CHỈ SỐ HỆ THỐNG
-- =======================================================================
local PageUser = create("Frame", nil, {ZIndex = 12})

local AvatarFrame = create("ImageLabel", PageUser, {
    Size = UDim2.new(0, 70, 0, 70),
    Position = UDim2.new(0, 15, 0, 25),
    BackgroundColor3 = Color3.fromRGB(16, 28, 48),
    Image = "rbxasset://textures/ui/Guideline.png",
    ZIndex = 13
}) addCorner(AvatarFrame, 35) addStroke(AvatarFrame)

task.spawn(function()
    pcall(function()
        local userId = player.UserId
        local thumbType = Enum.ThumbnailType.HeadShot
        local thumbSize = Enum.ThumbnailSize.Size100x100
        local content, isReady = Players:GetUserThumbnailAsync(userId, thumbType, thumbSize)
        if isReady then AvatarFrame.Image = content end
    end)
end)

local UserInfoText = create("TextLabel", PageUser, {
    Size = UDim2.new(1, -110, 0, 120),
    Position = UDim2.new(0, 100, 0, 15),
    BackgroundTransparency = 1,
    Text = "Đang tải dữ liệu...",
    TextColor3 = Color3.fromRGB(200, 235, 255),
    Font = Enum.Font.Code,
    TextSize = 11,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Top,
    ZIndex = 13
})

task.spawn(function()
    local fpsCount, lastTick = 0, tick()
    RunService.RenderStepped:Connect(function()
        fpsCount = fpsCount + 1
        if tick() - lastTick >= 1 then
            local sens = UserInputService.MouseDeltaSensitivity
            pcall(function()
                UserInfoText.Text = string.format(
                    "👤 Người chơi: %s\n🏷️ Tên ID: @%s\n🚀 Tốc độ: %d KH/S (FPS)\n🎯 Độ nhạy chuột/cảm ứng: %.2f\n📱 Hệ thống: Mobile Anti-Crash\n⚙️ Trạng thái Engine: Hoạt động mượt",
                    player.DisplayName, player.Name, fpsCount, sens
                )
            end)
            fpsCount, lastTick = 0, tick()
        end
    end)
end)
createTab("Người dùng", 1, PageUser)

-- =======================================================================
-- MỤC 2: PHẦN FIX LAG
-- =======================================================================
local PageFixLag = create("ScrollingFrame", nil, {CanvasSize = UDim2.new(0, 0, 0, 360), ScrollBarThickness = 2, BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 12}) create("UIListLayout", PageFixLag, {Padding = UDim.new(0, 4)})

local lagDescs = {
    "Chỉ nhẵn đất & Khử sương mù", 
    "Khử hiệu ứng tĩnh + Đất bóng loáng", 
    "XÓA SẠCH HIỆU ỨNG + Đất mượt siêu bóng", 
    "Mặt đất TRẮNG + Giữ bóng phản chiếu chiều sâu", 
    "Thế giới trắng mượt + Khử răng cưa giả lập", 
    "SIÊU CẤP v6.4: Đất xám chống sập + Giữ khối phản quang"
}
for num, desc in ipairs(lagDescs) do
    local b = create("TextButton", PageFixLag, {Size = UDim2.new(1, -4, 0, 32), BackgroundColor3 = Color3.fromRGB(20, 32, 52), Text = "Mục " .. num .. ": " .. desc, TextColor3 = Color3.fromRGB(215, 235, 255), Font = Enum.Font.Gotham, TextSize = 10, ZIndex = 13}) addCorner(b, 4) addStroke(b)
    b.MouseButton1Click:Connect(function()
        for _, child in pairs(PageFixLag:GetChildren()) do if child:IsA("TextButton") then child.BackgroundColor3 = Color3.fromRGB(20, 32, 52) end end
        b.BackgroundColor3 = (num == 6) and Color3.fromRGB(160, 25, 40) or Color3.fromRGB(22, 115, 80)
        startChunkEngine(num)
    end)
end

local ExtraFixBtn = create("TextButton", PageFixLag, {Size = UDim2.new(1, -4, 0, 32), BackgroundColor3 = Color3.fromRGB(35, 60, 90), Text = "⚙️ Ý TƯỞNG MỚI: KÍCH HOẠT TỐI ƯU HẠT & RÁC VẬT LÝ", TextColor3 = Color3.fromRGB(0, 255, 200), Font = Enum.Font.GothamBold, TextSize = 10, ZIndex = 13}) addCorner(ExtraFixBtn, 4) addStroke(ExtraFixBtn)
ExtraFixBtn.MouseButton1Click:Connect(function()
    ExtraFixBtn.Text = "✅ ĐÃ TỐI ƯU HÓA HẠT MÔI TRƯỜNG TỐI ĐA!"
    ExtraFixBtn.BackgroundColor3 = Color3.fromRGB(20, 80, 100)
    task.spawn(function()
        for _, v in pairs(Workspace:GetDescendants()) do
            if v:IsA("ParticleEmitter") and v.Parent and not isIgnored(v.Parent) then
                v.Rate = math.clamp(v.Rate, 0, 3)
            end
        end
    end)
end)

local CleanLagBtn = create("TextButton", PageFixLag, {Size = UDim2.new(1, -4, 0, 32), BackgroundColor3 = Color3.fromRGB(110, 35, 40), Text = "❌ KHÔI PHỤC HIỆU ỨNG ĐỊA HÌNH GỐC", TextColor3 = Color3.fromRGB(255, 255, 255), Font = Enum.Font.GothamBold, TextSize = 9, ZIndex = 13}) addCorner(CleanLagBtn, 4) addStroke(CleanLagBtn)
CleanLagBtn.MouseButton1Click:Connect(function()
    resetPartsComplete()
    for _, child in pairs(PageFixLag:GetChildren()) do if child:IsA("TextButton") and child ~= CleanLagBtn and child ~= ExtraFixBtn then child.BackgroundColor3 = Color3.fromRGB(20, 32, 52) end end
end)
createTab("Fix Lag", 2, PageFixLag)

-- =======================================================================
-- MỤC 3: SHADER CHUKỲ - PHIÊN BẢN KHÓA SKYBOX ULTRA V9
-- =======================================================================
local PageShader = create("ScrollingFrame", nil, {CanvasSize = UDim2.new(0, 0, 0, 310), ScrollBarThickness = 2, BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 12}) create("UIListLayout", PageShader, {Padding = UDim.new(0, 4)})

local function lockTime(targetTime)
    if timeLockConn then timeLockConn:Disconnect() end
    timeLockConn = RunService.Heartbeat:Connect(function() Lighting.ClockTime = targetTime end)
end

local function spawnAdvancedNight()
    if starConn then starConn:Disconnect() end
    applyCustomSky("6008860012")
    starConn = RunService.Heartbeat:Connect(function()
        if math.random(1, 120) == 1 then
            local startPos = Vector3.new(math.random(-200, 200), math.random(120, 180), math.random(-200, 200))
            local meteor = create("Part", Workspace, {Name = "VanutMeteor", Size = Vector3.new(1, 1, 5), Material = Enum.Material.Neon, Color = Color3.fromRGB(200, 240, 255), Anchored = true, CanCollide = false, Position = startPos})
            local trail = create("Trail", meteor, {Color = ColorSequence.new(Color3.fromRGB(0, 215, 255)), Lifetime = 0.5})
            local targetPos = startPos + Vector3.new(math.random(-60, 60), -100, math.random(-60, 60))
            local tween = TweenService:Create(meteor, TweenInfo.new(0.8, Enum.EasingStyle.QuadIn), {Position = targetPos, Transparency = 1})
            tween:Play() tween.Completed:Connect(function() meteor:Destroy() end)
        end
    end)
end

local shaderFuncs = {
    {"1: Bình minh vàng ấm áp (Khóa giờ)", function() forceHighVisualAndSharpness() applyCustomSky("6008860012") lockTime(6.2) Lighting.Brightness, Lighting.OutdoorAmbient = 2.6, Color3.fromRGB(255, 225, 160) create("SunRaysEffect", Lighting, {Name = "VanutSunRays", Intensity = 0.35, Spread = 0.7}) end},
    {"2: Trưa nắng rực rỡ sắc nét (Khóa giờ)", function() forceHighVisualAndSharpness() applyCustomSky("257173167") lockTime(12) Lighting.Brightness, Lighting.OutdoorAmbient = 3.4, Color3.fromRGB(150, 150, 150) create("SunRaysEffect", Lighting, {Name = "VanutSunRays", Intensity = 0.4, Spread = 0.6}) create("BloomEffect", Lighting, {Name = "VanutBloom", Intensity = 0.3, Size = 15, Threshold = 0.85}) end},
    {"3: Hoàng hôn ánh hồng lãng mạn", function() forceHighVisualAndSharpness() applyCustomSky("6008860012") lockTime(17.8) Lighting.Brightness, Lighting.OutdoorAmbient = 2.5, Color3.fromRGB(255, 170, 120) create("SunRaysEffect", Lighting, {Name = "VanutSunRays", Intensity = 0.4, Spread = 0.75}) end},
    {"4: Đêm nhiều sao + Sao băng lung linh", function() forceHighVisualAndSharpness() lockTime(0) Lighting.Brightness, Lighting.Ambient, Lighting.OutdoorAmbient = 1.6, Color3.fromRGB(65, 70, 95), Color3.fromRGB(45, 50, 70) spawnAdvancedNight() end},
    {"✨ Ý TƯỞNG 5: Cinematic Lofi (Dịu mát chiều sâu)", function() forceHighVisualAndSharpness() applyCustomSky("257173167") lockTime(16.5) Lighting.Brightness = 2.2 create("ColorCorrectionEffect", Lighting, {Name = "VanutCC", Saturation = -0.1, Contrast = 0.15, TintColor = Color3.fromRGB(255, 240, 220)}) create("BloomEffect", Lighting, {Name = "VanutBloom", Intensity = 0.2, Size = 10, Threshold = 0.9}) end},
    {"✨ Ý TƯỞNG 6: Cyberpunk Neon (Tương phản cao rực sắc)", function() forceHighVisualAndSharpness() applyCustomSky("6008860012") lockTime(19) Lighting.Brightness = 2.8 create("ColorCorrectionEffect", Lighting, {Name = "VanutCC", Saturation = 0.3, Contrast = 0.2, TintColor = Color3.fromRGB(230, 220, 255)}) create("BloomEffect", Lighting, {Name = "VanutBloom", Intensity = 0.6, Size = 24, Threshold = 0.5}) end}
}

for _, data in ipairs(shaderFuncs) do
    local sb = create("TextButton", PageShader, {Size = UDim2.new(1, -4, 0, 32), BackgroundColor3 = Color3.fromRGB(22, 38, 64), Text = "   " .. data[1], TextColor3 = Color3.fromRGB(200, 230, 255), Font = Enum.Font.Gotham, TextSize = 10, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 13}) addCorner(sb, 4) addStroke(sb)
    sb.MouseButton1Click:Connect(function() resetLightingComplete() data[2]() updateGlossiness() end)
end

local ClearShaderBtn = create("TextButton", PageShader, {Size = UDim2.new(1, -4, 0, 32), BackgroundColor3 = Color3.fromRGB(110, 35, 40), Text = "❌ XÓA TOÀN BỘ CẤU HÌNH SHADER", TextColor3 = Color3.fromRGB(255, 255, 255), Font = Enum.Font.GothamBold, TextSize = 10, ZIndex = 13}) addCorner(ClearShaderBtn, 4) addStroke(ClearShaderBtn)
ClearShaderBtn.MouseButton1Click:Connect(function() resetLightingComplete() end)
createTab("Shader", 3, PageShader)

-- =======================================================================
-- MỤC 4: THANH TRƯỢT ĐỔ BÓNG SHADOW KỸ THUẬT SỐ CHUYÊN SÂU (0% ĐẾN 100%)
-- =======================================================================
local PageGloss = create("Frame", nil, {ZIndex = 12})
local SliderTitle = create("TextLabel", PageGloss, {Size = UDim2.new(1, 0, 0, 20), Position = UDim2.new(0, 0, 0, 5), BackgroundTransparency = 1, Text = "ĐỘ NÉT ĐỔ BÓNG SHADOW GIẢ LẬP: 100 %", TextColor3 = Color3.fromRGB(0, 255, 180), Font = Enum.Font.GothamBold, TextSize = 10, ZIndex = 13})
local SliderTrack = create("Frame", PageGloss, {Size = UDim2.new(1, -40, 0, 6), Position = UDim2.new(0, 20, 0, 30), BackgroundColor3 = Color3.fromRGB(25, 38, 60), ZIndex = 13}) addCorner(SliderTrack, 3)
local SliderFill = create("Frame", SliderTrack, {Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Color3.fromRGB(0, 215, 255), ZIndex = 13}) addCorner(SliderFill, 3)
local SliderBtn = create("TextButton", SliderTrack, {Size = UDim2.new(0, 14, 0, 14), Position = UDim2.new(1, -7, 0.5, -7), BackgroundColor3 = Color3.fromRGB(255, 255, 255), Text = "", ZIndex = 14}) addCorner(SliderBtn, 7) addStroke(SliderBtn)

local sliderDragging = false
local function updateSlider(input)
    local pct = math.clamp((input.Position.X - SliderTrack.AbsolutePosition.X) / SliderTrack.AbsoluteSize.X, 0, 1)
    SliderBtn.Position = UDim2.new(pct, -7, 0.5, -7)
    SliderFill.Size = UDim2.new(pct, 0, 1, 0)
    currentShadowPercent = math.clamp(math.floor(pct * 100), 0, 100)
    SliderTitle.Text = "ĐỘ NÉT ĐỔ BÓNG SHADOW GIẢ LẬP: " .. currentShadowPercent .. " %"
    Lighting.ShadowSoftness = (100 - currentShadowPercent) / 100
end
SliderBtn.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then sliderDragging = true end end)
UserInputService.InputChanged:Connect(function(i) if sliderDragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then updateSlider(i) end end)
UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then sliderDragging = false end end)

local ForceGraphicBtn = create("TextButton", PageGloss, {
    Size = UDim2.new(1, -40, 0, 30),
    Position = UDim2.new(0, 20, 0, 48),
    BackgroundColor3 = Color3.fromRGB(150, 80, 20),
    Text = "✨ ÉP SHADOW ĐỒ HỌA THẤP -> CAO (BAKE SHADOW)",
    TextColor3 = Color3.new(1, 1, 1),
    Font = Enum.Font.GothamBold,
    TextSize = 9,
    ZIndex = 13
}) addCorner(ForceGraphicBtn, 4) addStroke(ForceGraphicBtn)
ForceGraphicBtn.MouseButton1Click:Connect(function() forceHighVisualAndSharpness() end)

create("TextLabel", PageGloss, {
    Size = UDim2.new(1, -20, 0, 80), 
    Position = UDim2.new(0, 10, 0, 85), 
    BackgroundTransparency = 1, 
    Text = "🪞 Công nghệ Bake Shadow V9:\nThanh trượt kiểm soát trực tiếp độ mịn mờ vùng rìa đổ bóng. Nút cam phía trên bẻ khóa luồng đồ họa ảo, tự động gán cấu trúc 'Fabric' lên vật thể và kích hoạt CastShadow liên tục, giúp giữ khối bóng sắc nét tại mọi mức đồ họa thấp nhất mà không lo sập engine.", 
    TextColor3 = Color3.fromRGB(150, 175, 210), 
    Font = Enum.Font.Gotham, 
    TextSize = 9, 
    TextWrapped = true, 
    TextXAlignment = Enum.TextXAlignment.Left, 
    TextYAlignment = Enum.TextYAlignment.Top, 
    ZIndex = 13
})
createTab("Độ Bóng", 4, PageGloss)

-- =======================================================================
-- MỤC 5: HỆ THỐNG BẬT TẮT HITBOX MỚI ĐỘC LẬP
-- =======================================================================
local PageHitbox = create("Frame", nil, {ZIndex = 12})

local ToggleHitboxBtn = create("TextButton", PageHitbox, {
    Size = UDim2.new(0, 180, 0, 40),
    Position = UDim2.new(0.5, -90, 0, 20),
    BackgroundColor3 = Color3.fromRGB(30, 20, 40),
    Text = "BẬT HITBOX NEON",
    TextColor3 = Color3.fromRGB(255, 50, 100),
    Font = Enum.Font.GothamBold,
    TextSize = 12,
    ZIndex = 13
}) addCorner(ToggleHitboxBtn, 6) addStroke(ToggleHitboxBtn)

local HitboxDesc = create("TextLabel", PageHitbox, {
    Size = UDim2.new(1, -20, 0, 80),
    Position = UDim2.new(0, 10, 0, 80),
    BackgroundTransparency = 1,
    Text = "🟢 Trạng thái hiện tại: ĐANG TẮT\n\nHitbox bản V6.4 sử dụng khung dây Neon với độ dày tối giản (0.03), tăng độ xuyên thấu và giúp bạn dễ dàng nhìn thấy kẻ địch qua tường hoặc góc tối mà không gây tụt khung hình khi chơi trên thiết bị di động.",
    TextColor3 = Color3.fromRGB(160, 170, 185),
    Font = Enum.Font.Gotham,
    TextSize = 10,
    TextWrapped = true,
    ZIndex = 13
})

ToggleHitboxBtn.MouseButton1Click:Connect(function()
    NewHitboxEnabled = not NewHitboxEnabled
    if NewHitboxEnabled then
        ToggleHitboxBtn.Text = "TẮT HITBOX NEON"
        ToggleHitboxBtn.BackgroundColor3 = Color3.fromRGB(15, 60, 55)
        ToggleHitboxBtn.TextColor3 = Color3.fromRGB(0, 255, 200)
        HitboxDesc.Text = "🟢 Trạng thái hiện tại: ĐANG HOẠT ĐỘNG\n\nHitbox bản V6.4 sử dụng khung dây Neon với độ dày tối giản (0.03), tăng độ xuyên thấu và giúp bạn dễ dàng nhìn thấy kẻ địch qua tường hoặc góc tối mà không gây tụt khung hình khi chơi trên thiết bị di động."
    else
        ToggleHitboxBtn.Text = "BẬT HITBOX NEON"
        ToggleHitboxBtn.BackgroundColor3 = Color3.fromRGB(30, 20, 40)
        ToggleHitboxBtn.TextColor3 = Color3.fromRGB(255, 50, 100)
        HitboxDesc.Text = "🟢 Trạng thái hiện tại: ĐANG TẮT\n\nHitbox bản V6.4 sử dụng khung dây Neon với độ dày tối giản (0.03), tăng độ xuyên thấu và giúp bạn dễ dàng nhìn thấy kẻ địch qua tường hoặc góc tối mà không gây tụt khung hình khi chơi trên thiết bị di động."
    end
    pcall(refreshAllHitboxes)
end)
createTab("Hitbox mới", 5, PageHitbox)

autoResetConn = task.spawn(function()
    while task.wait(3) do
        pcall(refreshAllHitboxes)
    end
end)

-- =======================================================================
-- HỆ THỐNG XỬ LÝ CHẠY TIẾN TRÌNH LOADING BAR 2.2 GIÂY HOÀN CHỈNH
-- =======================================================================
local LoadingGui = Instance.new("ScreenGui")
LoadingGui.Name = "vanut_FPS_v64_LoadingScreen"
LoadingGui.ResetOnSpawn = false

local success, err = pcall(function() LoadingGui.Parent = CoreGui end)
if not success then LoadingGui.Parent = player:WaitForChild("PlayerGui") end

local LoadingFrame = Instance.new("Frame")
LoadingFrame.Name = "LoadingFrame"
LoadingFrame.Size = UDim2.new(0, 290, 0, 100)
LoadingFrame.Position = UDim2.new(0.5, -145, 0.5, -50)
LoadingFrame.BackgroundColor3 = Color3.fromRGB(15, 22, 36)
LoadingFrame.BorderSizePixel = 0
LoadingFrame.Parent = LoadingGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 12)
UICorner.Parent = LoadingFrame

local UIStroke = Instance.new("UIStroke")
UIStroke.Thickness = 2
UIStroke.Color = Color3.fromRGB(0, 213, 255)
UIStroke.Parent = LoadingFrame

local LoadingText = Instance.new("TextLabel")
LoadingText.Name = "LoadingText"
LoadingText.Size = UDim2.new(1, 0, 0, 30)
LoadingText.Position = UDim2.new(0, 0, 0, 20)
LoadingText.BackgroundTransparency = 1
LoadingText.Text = "Đang khởi tạo vanut FPS v6.4..."
LoadingText.TextColor3 = Color3.fromRGB(255, 255, 255)
LoadingText.TextSize = 14
LoadingText.Font = Enum.Font.GothamBold
LoadingText.Parent = LoadingFrame

local BarBackground = Instance.new("Frame")
BarBackground.Name = "BarBackground"
BarBackground.Size = UDim2.new(0, 250, 0, 4)
BarBackground.Position = UDim2.new(0.5, -125, 0, 65)
BarBackground.BackgroundColor3 = Color3.fromRGB(30, 42, 62)
BarBackground.BorderSizePixel = 0
BarBackground.Parent = LoadingFrame

local BarCorner = Instance.new("UICorner")
BarCorner.CornerRadius = UDim.new(0, 2)
BarCorner.Parent = BarBackground

local LoadingBar = Instance.new("Frame")
LoadingBar.Name = "LoadingBar"
LoadingBar.Size = UDim2.new(0, 0, 1, 0)
LoadingBar.BackgroundColor3 = Color3.fromRGB(0, 213, 255)
LoadingBar.BorderSizePixel = 0
LoadingBar.Parent = BarBackground

local ProgressCorner = Instance.new("UICorner")
ProgressCorner.CornerRadius = UDim.new(0, 2)
ProgressCorner.Parent = LoadingBar

task.spawn(function()
    LoadingText.Text = "⚡ Khởi tạo lõi mượt mà V6.4..."
    local t1 = TweenService:Create(LoadingBar, TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(0.35, 0, 1, 0)})
    t1:Play() t1.Completed:Wait() task.wait(0.1)

    LoadingText.Text = "🔍 Loại bỏ UI cũ & Tải Avatar..."
    local t2 = TweenService:Create(LoadingBar, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(0.75, 0, 1, 0)})
    t2:Play() t2.Completed:Wait() task.wait(0.1)

    LoadingText.Text = "🚀 Đồng bộ hóa 5 mục cấu hình..."
    local t3 = TweenService:Create(LoadingBar, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(1, 0, 1, 0)})
    t3:Play() t3.Completed:Wait() task.wait(0.1)

    LoadingGui:Destroy()
    warn("🚀 vanut Ultimate V6.4 đã sẵn sàng tối ưu!")
    ToggleMenuBtn.Visible = true
end)
