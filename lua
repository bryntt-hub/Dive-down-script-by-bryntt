local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")


local running = false
local farmDelayActive = false
local whalesCaught = 0
local initialWhaleCount = 0
local processedWhales = {}
local minimized = false

local HP_THRESHOLD = 35
local OXYGEN_THRESHOLD = 25
local SELL_POS = Vector3.new(-1933.84, 2531.77, -1421.55)
local DEEP_DARK_POS = Vector3.new(-1922.33, 573.04, -1421.30)

local Midnight = {
    Main = Color3.fromRGB(15, 15, 18),
    Header = Color3.fromRGB(20, 20, 25),
    Accent = Color3.fromRGB(0, 170, 255),
    Success = Color3.fromRGB(0, 255, 120),
    Danger = Color3.fromRGB(255, 60, 60),
    Text = Color3.fromRGB(240, 240, 240),
    Stroke = Color3.fromRGB(45, 45, 50)
}

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AutoCollectBryntt_V25"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = localPlayer:WaitForChild("PlayerGui")

local CounterFrame = Instance.new("Frame")
CounterFrame.Size = UDim2.new(0, 220, 0, 42)
CounterFrame.Position = UDim2.new(0.5, -110, 0, 10)
CounterFrame.BackgroundColor3 = Midnight.Main
CounterFrame.Parent = ScreenGui
Instance.new("UICorner", CounterFrame)
local CounterStroke = Instance.new("UIStroke", CounterFrame)
CounterStroke.Color = Midnight.Stroke
CounterStroke.Thickness = 1.5

local WhaleLabel = Instance.new("TextLabel")
WhaleLabel.Size = UDim2.new(1, 0, 1, 0)
WhaleLabel.BackgroundTransparency = 1
WhaleLabel.Text = "Whales Caught: 0"
WhaleLabel.TextColor3 = Midnight.Success
WhaleLabel.Font = Enum.Font.GothamBold
WhaleLabel.TextSize = 14
WhaleLabel.Parent = CounterFrame

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 240, 0, 260)
MainFrame.Position = UDim2.new(0.1, 0, 0.35, 0)
MainFrame.BackgroundColor3 = Midnight.Main
MainFrame.Draggable = true
MainFrame.Active = true
Instance.new("UICorner", MainFrame)
Instance.new("UIStroke", MainFrame).Color = Midnight.Stroke

local Header = Instance.new("Frame", MainFrame)
Header.Size = UDim2.new(1, 0, 0, 40)
Header.BackgroundColor3 = Midnight.Header
Instance.new("UICorner", Header)

local Title = Instance.new("TextLabel", Header)
Title.Size = UDim2.new(1, -70, 1, 0)
Title.Position = UDim2.new(0, 12, 0, 0)
Title.Text = "Auto Collect Fish By Bryntt"
Title.TextColor3 = Midnight.Text
Title.Font = Enum.Font.GothamBold
Title.BackgroundTransparency = 1
Title.TextSize = 11
Title.TextXAlignment = Enum.TextXAlignment.Left

local CloseBtn = Instance.new("TextButton", Header)
CloseBtn.Size = UDim2.new(0, 25, 0, 25)
CloseBtn.Position = UDim2.new(1, -30, 0, 7)
CloseBtn.BackgroundColor3 = Midnight.Danger
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Midnight.Text
CloseBtn.Font = Enum.Font.GothamBold
Instance.new("UICorner", CloseBtn)
CloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

local MinBtn = Instance.new("TextButton", Header)
MinBtn.Size = UDim2.new(0, 25, 0, 25)
MinBtn.Position = UDim2.new(1, -60, 0, 7)
MinBtn.BackgroundColor3 = Midnight.Accent
MinBtn.Text = "-"
MinBtn.TextColor3 = Midnight.Text
MinBtn.Font = Enum.Font.GothamBold
Instance.new("UICorner", MinBtn)

local ContentFrame = Instance.new("Frame", MainFrame)
ContentFrame.Size = UDim2.new(1, 0, 1, -40)
ContentFrame.Position = UDim2.new(0, 0, 0, 40)
ContentFrame.BackgroundTransparency = 1

local StatusLabel = Instance.new("TextLabel", ContentFrame)
StatusLabel.Size = UDim2.new(1, 0, 0, 20)
StatusLabel.Position = UDim2.new(0,0,0,5)
StatusLabel.Text = "STATUS: IDLE"
StatusLabel.TextColor3 = Midnight.Accent
StatusLabel.BackgroundTransparency = 1
StatusLabel.Font = Enum.Font.GothamMedium

local ToggleBtn = Instance.new("TextButton", ContentFrame)
ToggleBtn.Size = UDim2.new(1, -30, 0, 45)
ToggleBtn.Position = UDim2.new(0, 15, 0, 30)
ToggleBtn.BackgroundColor3 = Midnight.Header
ToggleBtn.Text = "ENABLE SCRIPT"
ToggleBtn.TextColor3 = Midnight.Text
ToggleBtn.Font = Enum.Font.GothamBold
Instance.new("UICorner", ToggleBtn)

MinBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    local targetSize = minimized and UDim2.new(0, 240, 0, 40) or UDim2.new(0, 240, 0, 260)
    TweenService:Create(MainFrame, TweenInfo.new(0.4, Enum.EasingStyle.Quart), {Size = targetSize}):Play()
    ContentFrame.Visible = not minimized
    MinBtn.Text = minimized and "+" or "-"
end)

local function getWhaleCountInInventory()
    local count = 0
    local locations = {localPlayer.Backpack, localPlayer.Character}
    for _, loc in pairs(locations) do
        for _, item in ipairs(loc:GetChildren()) do
            if item:IsA("Tool") and item.Name:lower():find("whale") then
                count = count + 1
            end
        end
    end
    return count
end

task.spawn(function()
    while true do
        task.wait(0.5)
        if running then
            local currentTotal = getWhaleCountInInventory()
            whalesCaught = math.max(0, currentTotal - initialWhaleCount)
            WhaleLabel.Text = "Whales Caught: " .. whalesCaught
        end
    end
end)

local function processTarget(obj)
    if obj.Name:lower():find("whale") and not processedWhales[obj] then
        local prompt = obj:FindFirstChildOfClass("ProximityPrompt", true)
        if prompt then
            processedWhales[obj] = true
            farmDelayActive = false
            task.spawn(function()
                while obj:IsDescendantOf(workspace) and prompt.Enabled and running do
                    local hrp = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        local targetPos
                        if obj:IsA("Model") then
                            local ok, pivot = pcall(function() return obj.PrimaryPart and obj.PrimaryPart.Position or obj:GetModelCFrame().Position end)
                            targetPos = (ok and pivot) or (obj:GetModelCFrame().Position)
                        else
                            targetPos = obj.Position
                        end
                        pcall(function()
                            if hrp and hrp.Parent then
                                hrp.CFrame = CFrame.new(targetPos + Vector3.new(0, 6, 0))
                            end
                        end)
                        if typeof(fireproximityprompt) == "function" then
                            pcall(function() fireproximityprompt(prompt) end)
                        end
                    end
                    task.wait(0.3)
                end
            end)
        end
    end
end

workspace.DescendantAdded:Connect(function(d) if running then processTarget(d) end end)

local inEmergency = false
local lastHp = 100
local healthConnection = nil
local charConnection = nil

local function safeTeleportTo(pos)
    task.spawn(function()
        for _ = 1, 30 do
            local hrp = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                pcall(function() hrp.CFrame = CFrame.new(pos) end)
                break
            end
            task.wait(0.2)
        end
    end)
end

local function triggerEmergency()
    if inEmergency then return end
    inEmergency = true
    farmDelayActive = true
    StatusLabel.Text = "STATUS: EMERGENCY - TELEPORTING TO SELL"
    safeTeleportTo(SELL_POS)
    task.spawn(function()
        local waited = 0
        while waited < 15 do
            task.wait(0.5)
            waited = waited + 0.5
        end
        safeTeleportTo(DEEP_DARK_POS)
        task.delay(0.5, function()
            farmDelayActive = false
            StatusLabel.Text = running and "STATUS: ACTIVE" or "STATUS: IDLE"
            local hum = localPlayer.Character and localPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum then
                lastHp = hum.Health
            end
            inEmergency = false
        end)
    end)
end

local function attachHealthMonitor(character)
    if healthConnection then
        healthConnection:Disconnect()
        healthConnection = nil
    end
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    lastHp = humanoid.Health or 100
    healthConnection = humanoid.HealthChanged:Connect(function(newHealth)
        if not running then
            lastHp = newHealth
            return
        end
        if (newHealth < lastHp) or (newHealth <= HP_THRESHOLD) then
            triggerEmergency()
        end
        lastHp = newHealth
    end)
    humanoid.Died:Connect(function()
        if inEmergency then return end
        triggerEmergency()
    end)
end

local function onCharacterAdded(char)
    attachHealthMonitor(char)
end

if localPlayer.Character then
    onCharacterAdded(localPlayer.Character)
end
if charConnection then charConnection:Disconnect() end
charConnection = localPlayer.CharacterAdded:Connect(onCharacterAdded)

ToggleBtn.MouseButton1Click:Connect(function()
    running = not running
    ToggleBtn.Text = running and "DISABLE SCRIPT" or "ENABLE SCRIPT"
    ToggleBtn.BackgroundColor3 = running and Midnight.Success or Midnight.Header
    if running then
        initialWhaleCount = getWhaleCountInInventory()
        whalesCaught = 0
        processedWhales = {}
        WhaleLabel.Text = "Whales Caught: 0"
        local hrp = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            pcall(function() hrp.CFrame = CFrame.new(DEEP_DARK_POS) end)
            farmDelayActive = true
            StatusLabel.Text = "STATUS: INITIALIZING (4S)"
            task.delay(4, function() if running then farmDelayActive = false; StatusLabel.Text = "STATUS: ACTIVE" end end)
        end
        if localPlayer.Character then attachHealthMonitor(localPlayer.Character) end
    else
        StatusLabel.Text = "STATUS: SYSTEM IDLE"
        whalesCaught = 0
        initialWhaleCount = 0
        processedWhales = {}
        WhaleLabel.Text = "Whales Caught: 0"
    end
end)

local function CreateNavBtn(text, pos, callback)
    local btn = Instance.new("TextButton", ContentFrame)
    btn.Size = UDim2.new(1, -30, 0, 35)
    btn.Position = pos
    btn.BackgroundColor3 = Midnight.Header
    btn.Text = text
    btn.TextColor3 = Midnight.Text
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 11
    Instance.new("UICorner", btn)
    Instance.new("UIStroke", btn).Color = Midnight.Stroke
    btn.MouseButton1Click:Connect(callback)
end

CreateNavBtn("TP TO DEEP DARK", UDim2.new(0, 15, 0, 85), function()
    local hrp = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
    if hrp then pcall(function() hrp.CFrame = CFrame.new(DEEP_DARK_POS) end) end
end)

CreateNavBtn("TP TO SELL AREA", UDim2.new(0, 15, 0, 130), function()
    local hrp = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
    if hrp then pcall(function() hrp.CFrame = CFrame.new(SELL_POS) end) end
end)

CreateNavBtn("Sell All Fish", UDim2.new(0, 15, 0, 175), function()
    local args = {
        buffer.fromstring("\003\000")
    }
    game:GetService("ReplicatedStorage"):WaitForChild("Packets"):WaitForChild("Packet"):WaitForChild("RemoteEvent"):FireServer(unpack(args))
end)

-- Whale detection and immediate teleport + collect with pause on fish auto-collect
local whaleCollectCooldown = false

local function teleportToPosition(pos)
    local hrp = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
    if hrp then
        pcall(function() hrp.CFrame = CFrame.new(pos) end)
    end
end

local function collectWhale(whaleModel)
    if not whaleModel or not whaleModel:IsDescendantOf(workspace) then return end
    local prompt = whaleModel:FindFirstChildOfClass("ProximityPrompt", true)
    if prompt and prompt.Enabled then
        whaleCollectCooldown = true
        farmDelayActive = true
        teleportToPosition(whaleModel.PrimaryPart.Position + Vector3.new(0, 5, 0))
        task.wait(0.5)
        if typeof(fireproximityprompt) == "function" then
            pcall(function() fireproximityprompt(prompt) end)
        end
        task.delay(10, function()
            whaleCollectCooldown = false
            farmDelayActive = false
        end)
    end
end

workspace.DescendantAdded:Connect(function(descendant)
    if not running then return end
    if whaleCollectCooldown then return end
    if descendant:IsA("Model") and descendant.Name:lower():find("whale") then
        collectWhale(descendant)
    elseif descendant:IsA("BasePart") and descendant.Parent and descendant.Parent:IsA("Model") and descendant.Parent.Name:lower():find("whale") then
        collectWhale(descendant.Parent)
    end
end)

task.spawn(function()
    while task.wait(0.12) do
        if not running or farmDelayActive or whaleCollectCooldown then continue end

        local hrp = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then continue end

        local targetPrompt, shortest = nil, math.huge

        for _, v in ipairs(workspace:GetDescendants()) do
            if v:IsA("ProximityPrompt") and v.Enabled and not v.Parent.Name:lower():find("whale") then
                local actionText = v.ActionText and tostring(v.ActionText):lower() or ""
                local objectText = v.ObjectText and tostring(v.ObjectText):lower() or ""
                if not (actionText:find("catch") or objectText:find("catch")) then
                    continue
                end

                local pos = v.Parent:IsA("BasePart") and v.Parent.Position or (v.Parent:IsA("Model") and v.Parent.PrimaryPart and v.Parent.PrimaryPart.Position)
                if pos then
                    local dist = (hrp.Position - pos).Magnitude
                    if dist < shortest then shortest = dist; targetPrompt = v end
                end
            end
        end

        if targetPrompt then
            local success, pivot = pcall(function() return targetPrompt.Parent:GetPivot() end)
            if success and pivot then
                pcall(function() hrp.CFrame = CFrame.new(pivot.Position + Vector3.new(0, 2, 0)) end)
            else
                pcall(function() hrp.CFrame = CFrame.new(targetPrompt.Parent:GetPivot().Position + Vector3.new(0, 2, 0)) end)
            end
            task.wait(0.12)
            if typeof(fireproximityprompt) == "function" then
                pcall(function() fireproximityprompt(targetPrompt) end)
            end
        end
    end
end)

local notifiedWhales = {}
local activeNotifications = {}

local function layoutNotifications()
    for i, frame in ipairs(activeNotifications) do
        local targetY = 60 + (i - 1) * 56
        pcall(function()
            TweenService:Create(frame, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = UDim2.new(0.5, -150, 0, targetY)}):Play()
        end)
    end
end

local function showNotification(text, duration)
    duration = duration or 4
    local notif = Instance.new("Frame")
    notif.Size = UDim2.new(0, 300, 0, 50)
    notif.Position = UDim2.new(0.5, -150, 0, -70)
    notif.AnchorPoint = Vector2.new(0, 0)
    notif.BackgroundColor3 = Midnight.Header
    notif.BorderSizePixel = 0
    notif.Parent = ScreenGui
    local corner = Instance.new("UICorner", notif)
    corner.CornerRadius = UDim.new(0, 8)
    local stroke = Instance.new("UIStroke", notif)
    stroke.Color = Midnight.Stroke
    stroke.Thickness = 1
    local title = Instance.new("TextLabel", notif)
    title.Size = UDim2.new(1, -20, 1, 0)
    title.Position = UDim2.new(0, 10, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = text
    title.TextColor3 = Midnight.Text
    title.Font = Enum.Font.GothamBold
    title.TextSize = 14
    title.TextXAlignment = Enum.TextXAlignment.Left
    table.insert(activeNotifications, notif)
    layoutNotifications()
    task.delay(duration, function()
        for i, f in ipairs(activeNotifications) do
            if f == notif then
                table.remove(activeNotifications, i)
                break
            end
        end
        pcall(function()
            TweenService:Create(notif, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Position = UDim2.new(0.5, -150, 0, -70)}):Play()
        end)
        task.wait(0.3)
        pcall(function() notif:Destroy() end)
        layoutNotifications()
    end)
end

workspace.DescendantAdded:Connect(function(d)
    local ok, name = pcall(function() return d.Name end)
    if not ok then return end
    local lname = tostring(name):lower()
    if d:IsA("Model") and lname:find("whale") then
        if not notifiedWhales[d] then
            notifiedWhales[d] = true
            showNotification("Whale Spawned", 4)
            d.AncestryChanged:Connect(function(_, parent)
                if not parent then
                    notifiedWhales[d] = nil
                end
            end)
        end
        return
    end
    if d:IsA("BasePart") and d.Parent and d.Parent.Name and tostring(d.Parent.Name):lower():find("whale") then
        local parent = d.Parent
        if not notifiedWhales[parent] then
            notifiedWhales[parent] = true
            showNotification("Whale Spawned", 4)
            parent.AncestryChanged:Connect(function(_, par)
                if not par then
                    notifiedWhales[parent] = nil
                end
            end)
        end
    end
end)
