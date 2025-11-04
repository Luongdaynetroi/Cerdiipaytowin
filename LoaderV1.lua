-- LVM ViolenceDistrict ESP v1.1(BETA)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local CoreGui = game:GetService("CoreGui")

-- ====== Config ======
local UI_SIZE = UDim2.new(0, 260, 0.45, 0) -- to fit selector
local DEFAULT_MAX_DIST = 120
local TELEPORT_OFFSET = Vector3.new(0, 0, 3) -- offset from target to avoid overlap

-- ====== Helpers ======
local function safeParent(inst, parent)
    pcall(function() inst.Parent = parent end)
end

local function make(class, props)
    local obj = Instance.new(class)
    if props then
        for k, v in pairs(props) do
            if k ~= "Parent" then
                pcall(function() obj[k] = v end)
            end
        end
    end
    if props and props.Parent then safeParent(obj, props.Parent) end
    return obj
end

-- ====== GUI ======
local screenGui = make("ScreenGui", { Name = "LVM_ESP_UI_v3_4" })
safeParent(screenGui, CoreGui)

local frame = make("Frame", {
    Parent = screenGui,
    Size = UI_SIZE,
    Position = UDim2.new(1, -300, 0.18, 0),
    BackgroundColor3 = Color3.fromRGB(30, 30, 30),
    BackgroundTransparency = 0.35,
    BorderSizePixel = 0,
    Active = true,
})
make("UICorner", { Parent = frame, CornerRadius = UDim.new(0, 8) })

-- draggable
do
    local dragging, dragStart, startPos
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    frame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement and dragging then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

-- title
make("TextLabel", {
    Parent = frame,
    Size = UDim2.new(1, 0, 0, 26),
    Text = "🧠 LVM ESP + Teleport",
    TextColor3 = Color3.fromRGB(240, 240, 240),
    BackgroundTransparency = 1,
    Font = Enum.Font.GothamBold,
    TextSize = 16,
})

-- list container (players list in UI)
local listFrame = make("ScrollingFrame", {
    Parent = frame,
    Size = UDim2.new(1, -8, 0.56, -36),
    Position = UDim2.new(0, 4, 0, 32),
    BackgroundTransparency = 1,
    CanvasSize = UDim2.new(0, 0, 0, 0),
})
local listLayout = make("UIListLayout", { Parent = listFrame, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 2) })

-- controls row (toggle + dist input)
local controls = make("Frame", { Parent = frame, Size = UDim2.new(1, 0, 0, 28), Position = UDim2.new(0, 0, 0.56, -4), BackgroundTransparency = 1 })
local espToggle = make("TextButton", { Parent = controls, Size = UDim2.new(0.28, -6, 1, 0), Position = UDim2.new(0, 6, 0, 0), Text = "ESP: ON", BackgroundColor3 = Color3.fromRGB(45, 45, 48), BorderSizePixel = 0, Font = Enum.Font.Gotham, TextSize = 13 })
local distInput = make("TextBox", { Parent = controls, Size = UDim2.new(0.28, -6, 1, 0), Position = UDim2.new(0.36, 2, 0, 0), Text = tostring(DEFAULT_MAX_DIST), ClearTextOnFocus = false, BackgroundColor3 = Color3.fromRGB(40, 40, 44), BorderSizePixel = 0, Font = Enum.Font.Gotham, TextSize = 13, TextColor3 = Color3.fromRGB(230, 230, 230), TextXAlignment = Enum.TextXAlignment.Center })

-- selector container (near dist input)
local selector = make("Frame", { Parent = controls, Size = UDim2.new(0.36, -8, 1, 0), Position = UDim2.new(0.66, 4, 0, 0), BackgroundTransparency = 1 })
local leftBtn = make("TextButton", { Parent = selector, Size = UDim2.new(0, 28, 1, 0), Position = UDim2.new(0, 0, 0, 0), Text = "<", Font = Enum.Font.GothamBold, TextSize = 16, BorderSizePixel = 0 })
local nameLabel = make("TextLabel", { Parent = selector, Size = UDim2.new(0.6, -4, 1, 0), Position = UDim2.new(0.12, 0, 0, 0), Text = "Nobody", BackgroundTransparency = 1, TextScaled = true, Font = Enum.Font.Gotham, TextSize = 14, TextColor3 = Color3.fromRGB(240,240,240), TextXAlignment = Enum.TextXAlignment.Center })
local rightBtn = make("TextButton", { Parent = selector, Size = UDim2.new(0, 28, 1, 0), Position = UDim2.new(0.74, 0, 0, 0), Text = ">", Font = Enum.Font.GothamBold, TextSize = 16, BorderSizePixel = 0 })

-- teleport button under selector (full width of selector)
local teleportBtn = make("TextButton", { Parent = frame, Size = UDim2.new(0.36, -8, 0, 28), Position = UDim2.new(0.66, 4, 0.56, 30), Text = "Teleport", BackgroundColor3 = Color3.fromRGB(70, 120, 240), BorderSizePixel = 0, Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = Color3.fromRGB(255,255,255) })

-- clear button (small) at bottom
local clearBtn = make("TextButton", { Parent = frame, Size = UDim2.new(0.32, -8, 0, 26), Position = UDim2.new(0.02, 4, 1, -32), Text = "Clear All ESP", BackgroundColor3 = Color3.fromRGB(200, 50, 50), BorderSizePixel = 0, Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = Color3.fromRGB(255,255,255) })

-- ====== State ======
local ESP_ENABLED = true
local MAX_DIST = DEFAULT_MAX_DIST

local espData = {}   -- player => { label, highlight, dot, charConn }
local genData = {}   -- genModel => { highlight, childAddedConn, childRemovedConn }

-- selector state
local playerList = {}     -- array of player objects (excluding local)
local currentIndex = 1

-- ====== Helpers for selector ======
local function rebuildPlayerList()
    playerList = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            table.insert(playerList, p)
        end
    end
    if #playerList == 0 then currentIndex = 0 else
        if currentIndex < 1 then currentIndex = 1 end
        if currentIndex > #playerList then currentIndex = #playerList end
    end
end

local function updateSelectorLabel()
    if #playerList == 0 then
        nameLabel.Text = "No players"
    else
        local p = playerList[currentIndex]
        if p then
            local distText = ""
            if LocalPlayer.Character and LocalPlayer.Character.PrimaryPart and p.Character and p.Character.PrimaryPart then
                local d = math.floor((p.Character.PrimaryPart.Position - LocalPlayer.Character.PrimaryPart.Position).Magnitude)
                distText = " ("..tostring(d).."m)"
            end
            nameLabel.Text = p.Name .. distText
        else
            nameLabel.Text = "Unknown"
        end
    end
end

leftBtn.MouseButton1Click:Connect(function()
    if #playerList == 0 then return end
    currentIndex = currentIndex - 1
    if currentIndex < 1 then currentIndex = #playerList end
    updateSelectorLabel()
end)
rightBtn.MouseButton1Click:Connect(function()
    if #playerList == 0 then return end
    currentIndex = currentIndex + 1
    if currentIndex > #playerList then currentIndex = 1 end
    updateSelectorLabel()
end)

-- Teleport action (client-side)
teleportBtn.MouseButton1Click:Connect(function()
    if not LocalPlayer.Character or not LocalPlayer.Character.PrimaryPart then return end
    if #playerList == 0 or currentIndex == 0 then return end
    local target = playerList[currentIndex]
    if not target or not target.Character or not target.Character.PrimaryPart then return end
    if target == LocalPlayer then return end

    local ok, err = pcall(function()
        -- teleport client character's PrimaryPart to near target's PrimaryPart
        local targetCFrame = target.Character.PrimaryPart.CFrame
        LocalPlayer.Character:SetPrimaryPartCFrame(targetCFrame * CFrame.new(TELEPORT_OFFSET))
    end)
    if not ok then
        warn("Teleport failed:", err)
    end
end)

-- toggle & dist input
espToggle.MouseButton1Click:Connect(function()
    ESP_ENABLED = not ESP_ENABLED
    espToggle.Text = "ESP: " .. (ESP_ENABLED and "ON" or "OFF")
end)
distInput.FocusLost:Connect(function()
    local n = tonumber(distInput.Text)
    if n and n > 10 then MAX_DIST = n else distInput.Text = tostring(MAX_DIST) end
end)

clearBtn.MouseButton1Click:Connect(function()
    -- Cleanup all (defined below)
    if _G and type(_G.LVM_CleanupAll) == "function" then
        pcall(_G.LVM_CleanupAll)
    end
end)

-- ====== Player ESP functions ======
local function createOrUpdateUIListCanvas()
    listFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 8)
end

local function clearESPForPlayer(player)
    if not player then return end
    local d = espData[player]
    if not d then return end
    pcall(function() if d.label then d.label:Destroy() end end)
    pcall(function() if d.dot and d.dot.Parent then d.dot.Parent:Destroy() end end)
    pcall(function() if d.highlight and d.highlight.Parent then d.highlight:Destroy() end end)
    if d.charConn and type(d.charConn) == "RBXScriptConnection" then
        pcall(function() d.charConn:Disconnect() end)
    end
    espData[player] = nil
    createOrUpdateUIListCanvas()
end

local function setupCharForPlayer(player, character)
    if not player or not character then return end
    local d = espData[player]
    if not d then return end

    if d.highlight and d.highlight.Parent then
        d.highlight:Destroy()
    end

    local hl = Instance.new("Highlight")
    hl.Name = "LVM_Player_HL"
    hl.Adornee = character
    hl.FillTransparency = 0.5
    hl.OutlineTransparency = 1
    hl.Parent = character
    d.highlight = hl

    if d.dot and d.dot.Parent then
        d.dot.Parent:Destroy()
        d.dot = nil
    end
    local head = character:FindFirstChild("Head")
    if head then
        local bg = Instance.new("BillboardGui")
        bg.Name = "LVM_Player_Dot"
        bg.Adornee = head
        bg.Size = UDim2.new(0, 100, 0, 40)
        bg.AlwaysOnTop = true
        bg.Parent = head

        local dot = Instance.new("Frame", bg)
        dot.Size = UDim2.new(0, 12, 0, 12)
        dot.Position = UDim2.new(0.5, -6, 0, -14)
        dot.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
        dot.BorderSizePixel = 0
        Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
        d.dot = dot
    end
end

local function applyPlayerESP(player)
    if not player or player == LocalPlayer or espData[player] then return end
    local data = {}
    espData[player] = data

    local label = make("TextLabel", { Parent = listFrame, Size = UDim2.new(1, -10, 0, 18), BackgroundTransparency = 1, Text = player.Name, TextXAlignment = Enum.TextXAlignment.Left, Font = Enum.Font.Gotham, TextSize = 13 })
    data.label = label
    createOrUpdateUIListCanvas()

    if player.Character then
        setupCharForPlayer(player, player.Character)
    end
    data.charConn = player.CharacterAdded:Connect(function(c)
        task.wait(0.45)
        setupCharForPlayer(player, c)
    end)
end

Players.PlayerRemoving:Connect(function(player)
    clearESPForPlayer(player)
    rebuildPlayerList()
    updateSelectorLabel()
end)

-- ====== Generator ESP (highlight only) ======
local function clearESPForGen(gen)
    if not gen then return end
    local d = genData[gen]
    if not d then return end
    pcall(function() if d.highlight and d.highlight.Parent then d.highlight:Destroy() end end)
    pcall(function()
        if d.childAddedConn and type(d.childAddedConn) == "RBXScriptConnection" then d.childAddedConn:Disconnect() end
        if d.childRemovedConn and type(d.childRemovedConn) == "RBXScriptConnection" then d.childRemovedConn:Disconnect() end
    end)
    genData[gen] = nil
end

local function applyGenESP(gen)
    if not gen or genData[gen] then return end
    local hl = Instance.new("Highlight")
    hl.Name = "LVM_Gen_HL"
    hl.Adornee = gen
    hl.FillColor = Color3.fromRGB(255, 215, 0)
    hl.FillTransparency = 0.5
    hl.OutlineTransparency = 0
    hl.Parent = gen

    genData[gen] = { highlight = hl }

    -- small handlers just to trigger update; actual check in Heartbeat
    genData[gen].childAddedConn = gen.ChildAdded:Connect(function() end)
    genData[gen].childRemovedConn = gen.ChildRemoved:Connect(function() end)
end

-- remove when model removed from workspace
workspace.DescendantRemoving:Connect(function(o)
    if genData[o] then clearESPForGen(o) end
end)

-- ====== Init ======
for _, p in ipairs(Players:GetPlayers()) do
    applyPlayerESP(p)
end
Players.PlayerAdded:Connect(function(p)
    applyPlayerESP(p)
    rebuildPlayerList()
    updateSelectorLabel()
end)

for _, obj in ipairs(workspace:GetDescendants()) do
    if obj:IsA("Model") and obj.Name:lower():find("gen") then
        applyGenESP(obj)
    end
end
workspace.DescendantAdded:Connect(function(o)
    if o:IsA("Model") and o.Name:lower():find("gen") then
        applyGenESP(o)
    end
end)

-- build initial selector
rebuildPlayerList()
updateSelectorLabel()

-- ====== Single Heartbeat loop ======
RunService.Heartbeat:Connect(function()
    -- update player labels and visuals
    for player, data in pairs(espData) do
        if not data or not player then espData[player] = nil else
            if not ESP_ENABLED then
                if data.label then data.label.TextColor3 = Color3.fromRGB(140,140,140) end
            else
                if player.Character and player.Character.PrimaryPart and LocalPlayer and LocalPlayer.Character and LocalPlayer.Character.PrimaryPart then
                    local isKiller = player.Team and tostring(player.Team):lower():find("kill")
                    local color = isKiller and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(0, 255, 0)
                    local dist = math.floor((player.Character.PrimaryPart.Position - LocalPlayer.Character.PrimaryPart.Position).Magnitude)
                    if data.label then
                        data.label.TextColor3 = color
                        data.label.Text = player.Name .. " (" .. tostring(dist) .. "m)"
                    end
                    if data.dot then data.dot.BackgroundColor3 = color end
                    if data.highlight then data.highlight.FillColor = color end
                    local visible = dist <= MAX_DIST
                    if data.highlight then pcall(function() data.highlight.Enabled = visible end) end
                    if data.dot and data.dot.Parent then pcall(function() data.dot.Parent.Enabled = visible end) end
                else
                    if data.label then data.label.TextColor3 = Color3.fromRGB(200,200,200); data.label.Text = player.Name end
                end
            end
        end
    end

    -- update generators: remove if no GeneratorPoint
    for gen, d in pairs(genData) do
        if not gen or not gen.Parent then
            clearESPForGen(gen)
        else
            local points = 0
            for _, child in ipairs(gen:GetChildren()) do
                if child.Name:match("^GeneratorPoint") then points = points + 1 end
            end
            if points == 0 then
                clearESPForGen(gen)
            else
                if d.highlight then pcall(function() d.highlight.Enabled = true end) end
            end
        end
    end

    -- update selector label distance live
    updateSelectorLabel()
end)

-- ====== Cleanup ======
local function cleanupAll()
    for p, _ in pairs(espData) do
        pcall(function() clearESPForPlayer(p) end)
    end
    for g, _ in pairs(genData) do
        pcall(function() clearESPForGen(g) end)
    end
    pcall(function() if screenGui and screenGui.Parent then screenGui:Destroy() end end)
end
_G.LVM_CleanupAll = cleanupAll

UserInputService.InputBegan:Connect(function(inp, processed)
    if processed then return end
    if inp.KeyCode == Enum.KeyCode.Delete then cleanupAll() end
end)

game:BindToClose(function() cleanupAll() end)

listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(createOrUpdateUIListCanvas)

print("LVM ESP v3.4 loaded — Player ESP + Generator highlight + Teleport selector.")

