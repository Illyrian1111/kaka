--===[ Konfiguration & State ]===--
local config = {
    SilentAimEnabled  = false,
    SilentAimFOV      = 80,      -- Fester FOV-Radius in Pixeln
    AimBotEnabled     = false,
    ESPEnabled        = false,
}
local AimKey = Enum.KeyCode.F
local AimBotSmoothing = 0.25
local ESPBoxSize = Vector2.new(50,50)

--===[ Services & Locals ]===--
local Players     = game:GetService("Players")
local RunService  = game:GetService("RunService")
local UIS         = game:GetService("UserInputService")
local StarterGui  = game:GetService("StarterGui")
local Camera      = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local Mouse       = LocalPlayer:GetMouse()

-- kurze Lade‑Notification
StarterGui:SetCore("SendNotification", {
    Title = "Jailbreak‑Hub",
    Text  = "Menü wird erstellt…",
    Duration = 3,
})

--===[ GUI: kleines Toggle‑Menu ]===--
local screenGui = Instance.new("ScreenGui", LocalPlayer:WaitForChild("PlayerGui"))
screenGui.IgnoreGuiInset = true

local frame = Instance.new("Frame", screenGui)
frame.Size              = UDim2.new(0,200,0,140)
frame.Position          = UDim2.new(0,20,0,20)
frame.BackgroundColor3  = Color3.new(0,0,0)
frame.BackgroundTransparency = 0.4
frame.BorderSizePixel   = 0

local function makeToggle(name, label, offsetY, key)
    local btn = Instance.new("TextButton", frame)
    btn.Name               = name
    btn.Size               = UDim2.new(1,-10,0,30)
    btn.Position           = UDim2.new(0,5,0,offsetY)
    btn.BackgroundColor3   = Color3.new(0.1,0.1,0.1)
    btn.BackgroundTransparency = 0.2
    btn.BorderSizePixel    = 0
    btn.TextColor3         = Color3.new(1,1,1)
    btn.Font               = Enum.Font.SourceSansSemibold
    btn.TextSize           = 18
    btn.Text               = label .. ": OFF"
    btn.MouseButton1Click:Connect(function()
        config[key] = not config[key]
        btn.Text = label .. ": " .. (config[key] and "ON" or "OFF")
    end)
end

makeToggle("ToggleSilentAim", "SilentAim", 10,  "SilentAimEnabled")
makeToggle("ToggleAimBot",    "AimBot (F)", 50,  "AimBotEnabled")
makeToggle("ToggleESP",       "ESP",         90,  "ESPEnabled")

StarterGui:SetCore("SendNotification", {
    Title = "Jailbreak‑Hub",
    Text  = "Menü bereit! (SilentAim FOV = "..config.SilentAimFOV.."px)",
    Duration = 4,
})

--===[ SilentAim Hook ]===--
do
    local mt    = getrawmetatable(game)
    local old   = mt.__namecall
    local wrap  = newcclosure or function(f) return f end
    setreadonly(mt, false)

    mt.__namecall = wrap(function(self, ...)
        local method = getnamecallmethod()
        local args   = {...}

        if config.SilentAimEnabled
        and method == "FireServer"
        and typeof(args[1]) == "Vector3"
        then
            local best, bestDist = nil, config.SilentAimFOV
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= LocalPlayer
                and plr.Character
                and plr.Character:FindFirstChild("HumanoidRootPart")
                and plr.Character.Humanoid.Health > 0
                then
                    local worldPos = plr.Character.HumanoidRootPart.Position
                    local screenPos, onScreen = Camera:WorldToViewportPoint(worldPos)
                    if onScreen then
                        local dist = (Vector2.new(screenPos.X,screenPos.Y) - Vector2.new(Mouse.X,Mouse.Y)).Magnitude
                        if dist < bestDist then
                            bestDist, best = dist, plr
                        end
                    end
                end
            end
            if best then
                args[1] = best.Character.HumanoidRootPart.Position
            end
        end

        return old(self, unpack(args))
    end)

    setreadonly(mt, true)
end

--===[ AimBot (F) ]===--
do
    local aiming = false
    UIS.InputBegan:Connect(function(inp, gameProcessed)
        if not gameProcessed and inp.KeyCode == AimKey then
            aiming = true
        end
    end)
    UIS.InputEnded:Connect(function(inp)
        if inp.KeyCode == AimKey then
            aiming = false
        end
    end)

    RunService.RenderStepped:Connect(function(delta)
        if config.AimBotEnabled and aiming then
            local best, bestDist = nil, math.huge
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= LocalPlayer
                and plr.Character
                and plr.Character:FindFirstChild("HumanoidRootPart")
                and plr.Character.Humanoid.Health > 0
                then
                    local screenPos, onScreen = Camera:WorldToViewportPoint(plr.Character.HumanoidRootPart.Position)
                    if onScreen then
                        local dist = (Vector2.new(screenPos.X,screenPos.Y) - Vector2.new(Mouse.X,Mouse.Y)).Magnitude
                        if dist < bestDist then
                            bestDist, best = dist, plr
                        end
                    end
                end
            end
            if best then
                local targetPos = best.Character.HumanoidRootPart.Position
                local newCF = CFrame.new(Camera.CFrame.Position, targetPos)
                Camera.CFrame = Camera.CFrame:Lerp(newCF, AimBotSmoothing)
            end
        end
    end)
end

--===[ ESP ]===--
do
    local drawings = {}
    local function clearAll()
        for _, d in ipairs(drawings) do
            pcall(function() d:Remove() end)
        end
        drawings = {}
    end

    RunService.RenderStepped:Connect(function()
        clearAll()
        if not config.ESPEnabled then return end

        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer
            and plr.Character
            and plr.Character:FindFirstChild("HumanoidRootPart")
            and plr.Character.Humanoid.Health > 0
            then
                local worldPos = plr.Character.HumanoidRootPart.Position
                local screenPos, onScreen = Camera:WorldToViewportPoint(worldPos)
                if onScreen then
                    local box = Drawing.new("Square")
                    box.Position    = Vector2.new(screenPos.X - ESPBoxSize.X/2, screenPos.Y - ESPBoxSize.Y/2)
                    box.Size        = ESPBoxSize
                    box.Thickness   = 2
                    box.Transparency= 1
                    box.Color       = Color3.new(1,0,0)
                    box.Filled      = false
                    table.insert(drawings, box)

                    local txt = Drawing.new("Text")
                    txt.Text        = plr.Name
                    txt.Position    = Vector2.new(screenPos.X, screenPos.Y - ESPBoxSize.Y/2 - 5)
                    txt.Center      = true
                    txt.Outline     = true
                    txt.Size        = 14
                    table.insert(drawings, txt)
                end
            end
        end
    end)
end
