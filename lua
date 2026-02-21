local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local running = false
local starting = false
local farmDelayActive = false
local initialWhaleCount = 0
local processedWhales = {}
local minimized = false

local HP_THRESHOLD = 35
local OXYGEN_THRESHOLD = 25
local SELL_POS = Vector3.new(-1933.84, 2531.77, -1421.55)
local ATLANTIS_POS = Vector3.new(-1900.36, 67.52, -1410.65)

local Midnight = {
    Main = Color3.fromRGB(12, 12, 15),
    Header = Color3.fromRGB(18, 18, 22),
    Accent = Color3.fromRGB(0, 170, 255),
    Success = Color3.fromRGB(0, 220, 100),
    Danger = Color3.fromRGB(255, 60, 60),
    Text = Color3.fromRGB(255, 255, 255),
    GhostText = Color3.fromRGB(150, 150, 150),
    Stroke = Color3.fromRGB(40, 40, 45)
}

-- GUI Setup
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AutoCollectBryntt_V3_FULL"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = localPlayer:WaitForChild("PlayerGui")

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 320, 0, 370)
MainFrame.Position = UDim2.new(0.1, 0, 0.35, 0)
MainFrame.BackgroundColor3 = Midnight.Main
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.ClipsDescendants = true
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)
local MainStroke = Instance.new("UIStroke", MainFrame)
MainStroke.Color = Midnight.Stroke
MainStroke.Thickness = 1.5

-- CUSTOM DRAG LOGIC (MOVABLE GUI)
local dragging, dragInput, dragStart, startPos
local function update(input)
    local delta = input.Position - dragStart
    MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end
MainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)
MainFrame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
end)
UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then update(input) end
end)

local Header = Instance.new("Frame", MainFrame)
Header.Size = UDim2.new(1, 0, 0, 45)
Header.BackgroundColor3 = Midnight.Header
Header.BorderSizePixel = 0
Instance.new("UICorner", Header).CornerRadius = UDim.new(0, 8)

local Title = Instance.new("TextLabel", Header)
Title.Size = UDim2.new(1, -90, 0, 25)
Title.Position = UDim2.new(0, 15, 0, 5)
Title.Text = "FISH AUTOFARM"
Title.TextColor3 = Midnight.Text
Title.Font = Enum.Font.GothamBold
Title.BackgroundTransparency = 1
Title.TextSize = 14
Title.TextXAlignment = Enum.TextXAlignment.Left

local SubTitle = Instance.new("TextLabel", Header)
SubTitle.Size = UDim2.new(1, -90, 0, 15)
SubTitle.Position = UDim2.new(0, 15, 0, 24)
SubTitle.Text = "Developed by Bryntt"
SubTitle.TextColor3 = Midnight.GhostText
SubTitle.Font = Enum.Font.Gotham
SubTitle.BackgroundTransparency = 1
SubTitle.TextSize = 10
SubTitle.TextXAlignment = Enum.TextXAlignment.Left

local CloseBtn = Instance.new("TextButton", Header)
CloseBtn.Size = UDim2.new(0, 28, 0, 28)
CloseBtn.Position = UDim2.new(1, -35, 0, 8)
CloseBtn.BackgroundColor3 = Midnight.Danger
CloseBtn.Text = "×"
CloseBtn.TextSize = 20
CloseBtn.TextColor3 = Midnight.Text
CloseBtn.Font = Enum.Font.GothamBold
Instance.new("UICorner", CloseBtn)
CloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

-- Minimize Button Logic
local MinBtn = Instance.new("TextButton", Header)
MinBtn.Size = UDim2.new(0, 28, 0, 28)
MinBtn.Position = UDim2.new(1, -70, 0, 8)
MinBtn.BackgroundColor3 = Midnight.GhostText
MinBtn.Text = "-"
MinBtn.TextSize = 20
MinBtn.TextColor3 = Midnight.Text
MinBtn.Font = Enum.Font.GothamBold
Instance.new("UICorner", MinBtn)

local ContentFrame = Instance.new("ScrollingFrame", MainFrame)
ContentFrame.Size = UDim2.new(1, 0, 1, -50)
ContentFrame.Position = UDim2.new(0, 0, 0, 50)
ContentFrame.BackgroundTransparency = 1
ContentFrame.BorderSizePixel = 0
ContentFrame.ScrollBarThickness = 2
ContentFrame.ScrollBarImageColor3 = Midnight.Accent
ContentFrame.CanvasSize = UDim2.new(0, 0, 0, 480)

MinBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    if minimized then
        MainFrame.Size = UDim2.new(0, 320, 0, 45)
        ContentFrame.Visible = false
        MinBtn.Text = "+"
    else
        MainFrame.Size = UDim2.new(0, 320, 0, 370)
        ContentFrame.Visible = true
        MinBtn.Text = "-"
    end
end)

local UIList = Instance.new("UIListLayout", ContentFrame)
UIList.Padding = UDim.new(0, 8)
UIList.HorizontalAlignment = Enum.HorizontalAlignment.Center
UIList.SortOrder = Enum.SortOrder.LayoutOrder

local StatusLabel = Instance.new("TextLabel", ContentFrame)
StatusLabel.Size = UDim2.new(0.9, 0, 0, 25)
StatusLabel.Text = "SYSTEM IDLE"
StatusLabel.TextColor3 = Midnight.GhostText
StatusLabel.BackgroundTransparency = 1
StatusLabel.Font = Enum.Font.GothamBold
StatusLabel.TextSize = 12
StatusLabel.LayoutOrder = 0

local ToggleBtn = Instance.new("TextButton", ContentFrame)
ToggleBtn.Size = UDim2.new(0.9, 0, 0, 40)
ToggleBtn.BackgroundColor3 = Midnight.Header
ToggleBtn.Text = "ENABLE SCRIPT"
ToggleBtn.TextColor3 = Midnight.Text
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.LayoutOrder = 1
Instance.new("UICorner", ToggleBtn)
Instance.new("UIStroke", ToggleBtn).Color = Midnight.Stroke

local function CreateStyledBtn(text, order, callback)
    local btn = Instance.new("TextButton", ContentFrame)
    btn.Size = UDim2.new(0.9, 0, 0, 40)
    btn.BackgroundColor3 = Midnight.Header
    btn.Text = text
    btn.TextColor3 = Midnight.Text
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 12
    btn.LayoutOrder = order
    Instance.new("UICorner", btn)
    local s = Instance.new("UIStroke", btn)
    s.Color = Midnight.Stroke
    btn.MouseButton1Click:Connect(callback)
    return btn
end

CreateStyledBtn("TELEPORT TO ATLANTIS", 2, function()
    local hrp = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
    if hrp then pcall(function() hrp.CFrame = CFrame.new(ATLANTIS_POS) end) end
end)

CreateStyledBtn("TELEPORT TO SELL AREA", 3, function()
    local hrp = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
    if hrp then pcall(function() hrp.CFrame = CFrame.new(SELL_POS) end) end
end)

CreateStyledBtn("SELL ALL FISH", 4, function()
    local args = { buffer.fromstring("\003\000") }
    game:GetService("ReplicatedStorage"):WaitForChild("Packets"):WaitForChild("Packet"):WaitForChild("RemoteEvent"):FireServer(unpack(args))
end)

local ESPEnabled = false
local ESPBtn = CreateStyledBtn("TOGGLE FISH ESP", 5, function()
    ESPEnabled = not ESPEnabled
    StatusLabel.Text = ESPEnabled and "STATUS: ESP ENABLED" or "STATUS: ESP DISABLED"
    StatusLabel.TextColor3 = ESPEnabled and Midnight.Accent or Midnight.GhostText
end)

---------------------------------------------------------
-- INTERNAL GAME LOGIC
---------------------------------------------------------

local function interact(prompt)
    if not prompt or not prompt.Parent then return end
    if typeof(fireproximityprompt) == "function" then
        pcall(function() fireproximityprompt(prompt) end)
        return
    end
    pcall(function() prompt:InputHoldBegin() end)
    task.wait((prompt.HoldDuration or 0) + 0.12)
    pcall(function() prompt:InputHoldEnd() end)
end

local fishNames = {"Pebblefish", "Peeber", "Rubyfish", "Mermaid"}

local function isFishModelName(name)
    if not name then return false end
    for _, v in ipairs(fishNames) do if string.find(string.lower(name), string.lower(v)) then return true end end
    return false
end

local function getPartPositionFromInstance(inst)
    if not inst then return nil end
    if inst:IsA("BasePart") then return inst.Position end
    if inst:IsA("Model") then
        if inst.PrimaryPart then return inst.PrimaryPart.Position end
        local bp = inst:FindFirstChildWhichIsA("BasePart", true)
        if bp then return bp.Position end
    end
    return nil
end

local function findPriorityFishPrompt(hrp)
    local nearestPrompt = nil
    local shortestDistance = math.huge
    for _, prompt in ipairs(workspace:GetDescendants()) do
        if prompt:IsA("ProximityPrompt") and prompt.Enabled then
            local model = prompt:FindFirstAncestorOfClass("Model")
            if model and isFishModelName(model.Name) and string.find(string.lower(prompt.Name or ""), "catch") then
                local pos = getPartPositionFromInstance(model)
                if pos and hrp then
                    local dist = (hrp.Position - pos).Magnitude
                    if dist < shortestDistance then shortestDistance = dist nearestPrompt = prompt end
                end
            end
        end
    end
    return nearestPrompt
end

local function findNearestGeneralPrompt(hrp)
    local nearestPrompt = nil
    local shortestDistance = math.huge
    local excludedKeywords = {"buy", "purchase", "restock", "shop", "treat"}
    
    for _, prompt in ipairs(workspace:GetDescendants()) do
        if prompt:IsA("ProximityPrompt") and prompt.Enabled then
            local name = string.lower(prompt.Name or "")
            local action = string.lower(prompt.ActionText or "")
            local object = string.lower(prompt.ObjectText or "")
            
            local isExcluded = false
            for _, word in ipairs(excludedKeywords) do
                if string.find(name, word) or string.find(action, word) or string.find(object, word) then
                    isExcluded = true
                    break
                end
            end
            
            if not isExcluded then
                local pos = getPartPositionFromInstance(prompt.Parent)
                if pos and hrp then
                    local dist = (hrp.Position - pos).Magnitude
                    if dist < shortestDistance then
                        shortestDistance = dist
                        nearestPrompt = prompt
                    end
                end
            end
        end
    end
    return nearestPrompt
end

-- IMPROVED ESP LOGIC (Seen through walls + Name tags)
local ESPObjects = {}
task.spawn(function()
    while task.wait(0.5) do
        -- CLEANUP
        for p, components in pairs(ESPObjects) do 
            if not p or not p.Parent then 
                if typeof(components) == "table" then
                    for _, v in pairs(components) do if v then v:Destroy() end end
                end
                ESPObjects[p] = nil 
            end 
        end
        
        -- SCANNING
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("Model") and isFishModelName(obj.Name) then
                local p = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
                if p and not ESPObjects[p] then
                    -- 1. BOX OVERLAY (Seen through walls)
                    local box = Instance.new("BoxHandleAdornment", p)
                    box.Name = "FishHighlight"
                    box.Adornee = p
                    box.AlwaysOnTop = true
                    box.ZIndex = 11
                    box.Transparency = 0.4
                    box.Color3 = Midnight.Danger 
                    box.Size = p.Size + Vector3.new(0.2, 0.2, 0.2)
                    
                    -- 2. NAME TAG (Seen through walls)
                    local billboard = Instance.new("BillboardGui", p)
                    billboard.Name = "FishNameTag"
                    billboard.Adornee = p
                    billboard.Size = UDim2.new(0, 150, 0, 40)
                    billboard.StudsOffset = Vector3.new(0, 2, 0)
                    billboard.AlwaysOnTop = true
                    
                    local label = Instance.new("TextLabel", billboard)
                    label.BackgroundTransparency = 1
                    label.Size = UDim2.new(1, 0, 1, 0)
                    label.Text = obj.Name
                    label.TextColor3 = Color3.fromRGB(255, 255, 255)
                    label.TextStrokeTransparency = 0
                    label.Font = Enum.Font.GothamBold
                    label.TextSize = 14
                    
                    ESPObjects[p] = {box, billboard}
                end
            end
        end
        
        -- TOGGLE VISIBILITY
        if not ESPEnabled then
             for p, components in pairs(ESPObjects) do
                 if typeof(components) == "table" then
                    for _, v in pairs(components) do if v then v:Destroy() end end
                 end
                 ESPObjects[p] = nil
             end
        end
    end
end)

task.spawn(function()
    while task.wait(0.3) do
        if not running then continue end
        local hrp = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then continue end
        
        -- ACTIVATE ONLY IF AT ATLANTIS COORDS
        if (hrp.Position - ATLANTIS_POS).Magnitude > 300 then continue end

        for _, obj in ipairs(workspace:GetDescendants()) do
            if string.find(string.lower(obj.Name or ""), "whale") and not processedWhales[obj] then
                local prompt = obj:FindFirstChildWhichIsA("ProximityPrompt", true)
                if prompt then
                    processedWhales[obj] = true
                    task.spawn(function()
                        while obj:IsDescendantOf(workspace) and prompt.Enabled and running do
                            local hrpInside = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
                            if hrpInside then
                                local targetPos = getPartPositionFromInstance(obj)
                                if targetPos then pcall(function() hrpInside.CFrame = CFrame.new(targetPos + Vector3.new(0, 6, 0)) end) end
                                interact(prompt)
                            end
                            task.wait(0.3)
                        end
                    end)
                end
            end
        end
    end
end)

task.spawn(function()
    while task.wait(0.1) do 
        if not running then continue end
        local char = localPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then continue end
        
        -- ACTIVATE ONLY IF AT ATLANTIS COORDS
        if (hrp.Position - ATLANTIS_POS).Magnitude > 300 then continue end
        
        local targetPrompt = findPriorityFishPrompt(hrp)
        
        if not targetPrompt then
            targetPrompt = findNearestGeneralPrompt(hrp)
        end
        
        if targetPrompt then
            local pos = getPartPositionFromInstance(targetPrompt.Parent)
            if pos then
                pcall(function() hrp.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0)) end)
                task.wait(0.05)
                interact(targetPrompt)
            end
        end
    end
end)

local inEmergency = false
local function attachHealthMonitor(character)
    local humanoid = character:WaitForChild("Humanoid")
    humanoid.HealthChanged:Connect(function(hp)
        if running and hp <= HP_THRESHOLD and not inEmergency then
            inEmergency = true
            local oldRunning = running
            running = false
            StatusLabel.Text = "EMERGENCY - SELLING"
            StatusLabel.TextColor3 = Midnight.Danger
            local hrp = character:FindFirstChild("HumanoidRootPart")
            if hrp then hrp.CFrame = CFrame.new(SELL_POS) end
            task.wait(15)
            if hrp then hrp.CFrame = CFrame.new(ATLANTIS_POS) end
            task.wait(1)
            inEmergency = false
            running = oldRunning
            StatusLabel.Text = running and "STATUS: ACTIVE" or "SYSTEM IDLE"
            StatusLabel.TextColor3 = running and Midnight.Success or Midnight.GhostText
        end
    end)
end

localPlayer.CharacterAdded:Connect(attachHealthMonitor)
if localPlayer.Character then attachHealthMonitor(localPlayer.Character) end

ToggleBtn.MouseButton1Click:Connect(function()
    if running or starting then
        running = false
        starting = false
        ToggleBtn.Text = "ENABLE SCRIPT"
        ToggleBtn.BackgroundColor3 = Midnight.Header
        StatusLabel.Text = "SYSTEM IDLE"
        StatusLabel.TextColor3 = Midnight.GhostText
    else
        starting = true
        task.spawn(function()
            for i = 4, 1, -1 do
                if not starting then return end
                ToggleBtn.Text = "CANCEL START (" .. i .. ")"
                StatusLabel.Text = "STARTING IN " .. i .. "s"
                StatusLabel.TextColor3 = Midnight.Accent
                task.wait(1)
            end
            if not starting then return end
            
            -- TELEPORT TO ATLANTIS UPON ENABLING
            local hrp = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
            if hrp then 
                pcall(function() hrp.CFrame = CFrame.new(ATLANTIS_POS) end)
            end
            
            task.wait(0.5) -- Small delay for character arrival
            
            starting = false
            running = true
            ToggleBtn.Text = "DISABLE SCRIPT"
            ToggleBtn.BackgroundColor3 = Midnight.Success
            StatusLabel.Text = "STATUS: ACTIVE"
            StatusLabel.TextColor3 = Midnight.Success
        end)
    end
end)
