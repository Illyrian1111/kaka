--===[ Konfiguration & State ]===--
local config = {
    SilentAimEnabled  = false,
    AimBotEnabled     = false,
    ESPEnabled        = false,
}
local AimBotKey        = Enum.KeyCode.F
local AimBotSmoothing  = 0.25
local SilentAimRange   = 1000
local ESPBoxSize       = Vector2.new(50,50)

--===[ Services & Locals ]===--
local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS         = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local Camera     = workspace.CurrentCamera
local LocalPlayer= Players.LocalPlayer
local Mouse      = LocalPlayer:GetMouse()

-- Notification beim Start
StarterGui:SetCore("SendNotification", {
    Title = "Jailbreak‑Hub",
    Text  = "Menu lädt…",
    Duration = 5,
})

--===[ GUI erzeugen ]===--
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "JailbreakHub"
screenGui.IgnoreGuiInset = true
screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0,200,0,140)
frame.Position = UDim2.new(0,20,0,100)
frame.BackgroundTransparency = 0.3
frame.BackgroundColor3 = Color3.new(0,0,0)
frame.BorderSizePixel = 0
frame.Parent = screenGui

local function makeToggle(name, text, posY, callback)
    local btn = Instance.new("TextButton")
    btn.Name = name
    btn.Size = UDim2.new(1,-10,0,30)
    btn.Position = UDim2.new(0,5,0,posY)
    btn.BackgroundTransparency = 0.4
    btn.BackgroundColor3 = Color3.new(0.1,0.1,0.1)
    btn.BorderSizePixel = 0
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Font = Enum.Font.SourceSans
    btn.TextSize = 18
    btn.Text = text .. ": OFF"
    btn.Parent = frame

    btn.MouseButton1Click:Connect(function()
        local newState = callback()
        btn.Text = text .. ": " .. (newState and "ON" or "OFF")
    end)
end

makeToggle("ToggleSilentAim", "SilentAim", 10, function()
    config.SilentAimEnabled = not config.SilentAimEnabled
    return config.SilentAimEnabled
end)

makeToggle("ToggleAimBot", "AimBot (F)", 50, function()
    config.AimBotEnabled = not config.AimBotEnabled
    return config.AimBotEnabled
end)

makeToggle("ToggleESP", "ESP", 90, function()
    config.ESPEnabled = not config.ESPEnabled
    return config.ESPEnabled
end)

--===[ Silent Aim Hook ]===--
do
    local mt          = getrawmetatable(game)
    local oldNamecall = mt.__namecall
    local newNamecall = newcclosure or function(f) return f end

    setreadonly(mt, false)
    mt.__namecall = newNamecall(function(self, ...)
        local method = getnamecallmethod()
        local args   = {...}

        if config.SilentAimEnabled
        and method == "FireServer"
        and typeof(args[1]) == "Vector3"
        then
            -- nächster Gegner
            local nearest, bestDist = nil, SilentAimRange
            for _, plr in pairs(Players:GetPlayers()) do
                if plr ~= LocalPlayer
                and plr.Team ~= LocalPlayer.Team
                and plr.Character
                and plr.Character:FindFirstChild("HumanoidRootPart")
                and plr.Character.Humanoid.Health > 0
                then
                    local mag = (plr.Character.HumanoidRootPart.Position - Camera.CFrame.Position).Magnitude
                    if mag < bestDist then
                        nearest, bestDist = plr, mag
                    end
                end
            end
            if nearest then
                args[1] = nearest.Character.HumanoidRootPart.Position
            end
        end

        return oldNamecall(self, unpack(args))
    end)
    setreadonly(mt, true)
end

--===[ Aimbot ]===--
do
    local aiming = false

    UIS.InputBegan:Connect(function(input, gp)
        if not gp and input.KeyCode == AimBotKey then
            aiming = true
        end
    end)
    UIS.InputEnded:Connect(function(input)
        if input.KeyCode == AimBotKey then
            aiming = false
        end
    end)

    local function getNearest()
        local nearest, bestDist = nil, math.huge
        for _, plr in pairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer
            and plr.Team ~= LocalPlayer.Team
            and plr.Character
            and plr.Character:FindFirstChild("HumanoidRootPart")
            and plr.Character.Humanoid.Health > 0
            then
                local screenPos, onScreen = Camera:WorldToViewportPoint(plr.Character.HumanoidRootPart.Position)
                if onScreen then
                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - Vector2.new(Mouse.X, Mouse.Y)).Magnitude
                    if dist < bestDist then
                        nearest, bestDist = plr, dist
                    end
                end
            end
        end
        return nearest
    end

    RunService.RenderStepped:Connect(function(dt)
        if config.AimBotEnabled and aiming then
            local target = getNearest()
            if target then
                local head = target.Character.HumanoidRootPart.Position
                local newCF = CFrame.new(Camera.CFrame.Position, head)
                Camera.CFrame = Camera.CFrame:Lerp(newCF, AimBotSmoothing)
            end
        end
    end)
end

--===[ ESP ]===--
do
    local draws = {}

    local function clear()
        for _, d in ipairs(draws) do
            pcall(function() d:Remove() end)
        end
        draws = {}
    end

    RunService.RenderStepped:Connect(function()
        if not config.ESPEnabled then
            clear()
            return
        end

        clear()
        for _, plr in pairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer
            and plr.Character
            and plr.Character:FindFirstChild("HumanoidRootPart")
            and plr.Character.Humanoid.Health > 0
            then
                local pos3 = plr.Character.HumanoidRootPart.Position
                local pos2, onScreen = Camera:WorldToViewportPoint(pos3)
                if onScreen then
                    -- Box
                    local box = Drawing.new("Square")
                    box.Size       = ESPBoxSize
                    box.Position   = Vector2.new(pos2.X-ESPBoxSize.X/2, pos2.Y-ESPBoxSize.Y/2)
                    box.Thickness  = 2
                    box.Transparency= 1
                    box.Color      = Color3.new(1,0,0)
                    box.Filled     = false
                    table.insert(draws, box)
                    -- Name
                    local txt = Drawing.new("Text")
                    txt.Text       = plr.Name
                    txt.Position   = Vector2.new(pos2.X, pos2.Y - ESPBoxSize.Y/2 - 5)
                    txt.Center     = true
                    txt.Outline    = true
                    txt.Size       = 14
                    table.insert(draws, txt)
                end
            end
        end
    end)
end

-- abschließende Notification
StarterGui:SetCore("SendNotification", {
    Title = "Jailbreak‑Hub",
    Text  = "Menü bereit! Klicke auf die Buttons oben.",
    Duration = 5,
})
