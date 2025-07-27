--===[ Einstellungen ]===--
local config = {
    -- Silent Aim
    SilentAimEnabled     = true,
    SilentAimDistance    = 1000,    -- maximale Reichweite in Studs

    -- Aimbot
    AimBotEnabled        = true,
    AimBotKey            = Enum.KeyCode.F,
    AimBotSmoothing      = 0.25,    -- 0 == instant, 1 == sehr langsam

    -- ESP
    ESPEnabled           = true,
    ESPBoxes             = true,
    ESPNames             = true,
    ESPBoxSize           = Vector2.new(50, 50),
}

--===[ Services & Locals ]===--
local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS         = game:GetService("UserInputService")
local Camera     = workspace.CurrentCamera
local LocalPlayer= Players.LocalPlayer

-- Notification beim Laden
game:GetService("StarterGui"):SetCore("SendNotification", {
    Title    = "Jailbreak‑Hub",
    Text     = "SilentAim, AimBot & ESP aktiviert",
    Duration = 5,
})

--===[ Silent Aim & Wallbang ]===--
do
    local RSModule = game:GetService("ReplicatedStorage")
        :WaitForChild("Module")
        :WaitForChild("RayCast")
    -- alte Funktion sichern
    getgenv()._oldRay = getgenv()._oldRay or RSModule.RayIgnoreNonCollideWithIgnoreList

    if config.SilentAimEnabled then
        RSModule.RayIgnoreNonCollideWithIgnoreList = function(...)
            -- nächster Gegner suchen
            local nearestDist, nearestPlr = config.SilentAimDistance, nil
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= LocalPlayer
                and plr.Team ~= LocalPlayer.Team
                and plr.Character
                and plr.Character:FindFirstChild("HumanoidRootPart")
                then
                    local mag = (plr.Character.HumanoidRootPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
                    if mag < nearestDist then
                        nearestDist, nearestPlr = mag, plr
                    end
                end
            end

            -- originale Argumente holen
            local args = { getgenv()._oldRay(...) }

            -- ersetzen, wenn der BulletEmitter läuft
            local envScript = tostring(getfenv(2).script)
            if nearestPlr
            and (envScript == "BulletEmitter" or envScript == "Taser")
            then
                args[1] = nearestPlr.Character.HumanoidRootPart
                args[2] = nearestPlr.Character.HumanoidRootPart.Position
            end

            return unpack(args)
        end
    else
        RSModule.RayIgnoreNonCollideWithIgnoreList = getgenv()._oldRay
    end
end

--===[ Aimbot ]===--
do
    local aiming = false

    -- Toggle per KeyDown/Up
    UIS.InputBegan:Connect(function(input, gp)
        if not gp and input.KeyCode == config.AimBotKey then
            aiming = true
        end
    end)
    UIS.InputEnded:Connect(function(input)
        if input.KeyCode == config.AimBotKey then
            aiming = false
        end
    end)

    -- Hilfsfunktion: nächsten Gegner zurückgeben
    local function getNearestTarget()
        local nearest, bestDist = nil, math.huge
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer
            and plr.Team ~= LocalPlayer.Team
            and plr.Character
            and plr.Character:FindFirstChild("HumanoidRootPart")
            and plr.Character.Humanoid.Health > 0
            then
                local headPos = plr.Character.HumanoidRootPart.Position
                -- Distanz aus Kamerasicht
                local screenPos, onScreen = Camera:WorldToViewportPoint(headPos)
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

    -- Beim RenderStepped: Kamera anpassen
    RunService.RenderStepped:Connect(function(dt)
        if config.AimBotEnabled and aiming then
            local target = getNearestTarget()
            if target and target.Character then
                local headPos = target.Character.HumanoidRootPart.Position
                local newCFrame = CFrame.new(Camera.CFrame.Position, headPos)
                Camera.CFrame = Camera.CFrame:Lerp(newCFrame, config.AimBotSmoothing)
            end
        end
    end)
end

--===[ ESP ]===--
if config.ESPEnabled then
    local drawings = {}

    local function clearESP()
        for _, obj in ipairs(drawings) do
            pcall(function() obj:Remove() end)
        end
        drawings = {}
    end

    RunService.RenderStepped:Connect(function()
        clearESP()
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer
            and plr.Character
            and plr.Character:FindFirstChild("HumanoidRootPart")
            and plr.Character.Humanoid.Health > 0
            then
                local rootPos = plr.Character.HumanoidRootPart.Position
                local screenPos, onScreen = Camera:WorldToViewportPoint(rootPos)
                if onScreen then
                    -- Box
                    if config.ESPBoxes then
                        local box = Drawing.new("Square")
                        box.Size         = config.ESPBoxSize
                        box.Position     = Vector2.new(screenPos.X - config.ESPBoxSize.X/2, screenPos.Y - config.ESPBoxSize.Y/2)
                        box.Thickness    = 2
                        box.Transparency = 1
                        box.Color        = Color3.new(1, 0, 0)
                        box.Filled       = false
                        table.insert(drawings, box)
                    end
                    -- Name
                    if config.ESPNames then
                        local txt = Drawing.new("Text")
                        txt.Text       = plr.Name
                        txt.Position   = Vector2.new(screenPos.X, screenPos.Y - config.ESPBoxSize.Y/2 - 15)
                        txt.Center     = true
                        txt.Outline    = true
                        txt.Size       = 16
                        table.insert(drawings, txt)
                    end
                end
            end
        end
    end)
end
