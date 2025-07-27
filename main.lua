--===[ Einstellungen ]===--
local config = {
    SilentAimEnabled   = true,     -- Silent Aim AN/AUS
    SilentAimFOV       = 120,      -- Maximales FOV in Pixeln
    SilentAimTeamCheck = false,    -- Nur Gegner anvisieren?

    ESPEnabled         = true,     -- ESP AN/AUS
    ESPBoxes           = true,     -- Umrandungen zeichnen?
    ESPNames           = true,     -- Spielernamen anzeigen?
}

--===[ Services & Locals ]===--
local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera     = workspace.CurrentCamera
local LocalPlayer= Players.LocalPlayer
local Mouse      = LocalPlayer:GetMouse()

-- Notification beim Laden
game:GetService("StarterGui"):SetCore("SendNotification", {
    Title    = "Jailbreak‑Hub",
    Text     = "Silent Aim & ESP geladen",
    Duration = 5,
})

--===[ Hilfsfunktion: Nächsten Gegner finden ]===--
local function getNearestTarget()
    local nearest, bestDist = nil, math.huge
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer
        and plr.Character
        and plr.Character:FindFirstChild("Humanoid")
        and plr.Character.Humanoid.Health > 0
        and plr.Character:FindFirstChild("Head") then

            if not config.SilentAimTeamCheck or plr.Team ~= LocalPlayer.Team then
                local headPos = plr.Character.Head.Position
                local screenPos, onScreen = Camera:WorldToViewportPoint(headPos)
                if onScreen then
                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - Vector2.new(Mouse.X, Mouse.Y)).magnitude
                    if dist < bestDist and dist <= config.SilentAimFOV then
                        nearest, bestDist = plr, dist
                    end
                end
            end
        end
    end
    return nearest
end

--===[ Silent‑Aim Hook ]===--
-- Fängt alle :FireServer‑Aufrufe ab und ersetzt das erste Vector3‑Argument
do
    local mt            = getrawmetatable(game)
    local oldNamecall   = mt.__namecall
    local newNamecall   = newcclosure or function(f) return f end

    setreadonly(mt, false)
    mt.__namecall = newNamecall(function(self, ...)
        local method = getnamecallmethod()
        local args   = {...}

        -- Nur FireServer mit Vector3‑Erstparameter anpassen
        if config.SilentAimEnabled
        and method == "FireServer"
        and typeof(args[1]) == "Vector3" then
            local target = getNearestTarget()
            if target and target.Character and target.Character:FindFirstChild("Head") then
                args[1] = target.Character.Head.Position
            end
        end

        return oldNamecall(self, unpack(args))
    end)
    setreadonly(mt, true)
end

--===[ ESP ]===--
if config.ESPEnabled then
    -- Container für alle Drawings
    local espFolder = {}
    local function clearESP()
        for _, obj in pairs(espFolder) do
            obj:Remove()
        end
        espFolder = {}
    end

    RunService.RenderStepped:Connect(function()
        clearESP()
        for _, plr in pairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer
            and plr.Character
            and plr.Character:FindFirstChild("HumanoidRootPart")
            and plr.Character.Humanoid.Health > 0 then

                local rootPos = plr.Character.HumanoidRootPart.Position
                local screenPos, onScreen = Camera:WorldToViewportPoint(rootPos)
                if onScreen then
                    -- Box
                    if config.ESPBoxes then
                        local box = Drawing.new("Square")
                        box.Size       = Vector2.new(50, 50)  -- ca. 50×50px; Anpassen nach Geschmack
                        box.Position   = Vector2.new(screenPos.X - 25, screenPos.Y - 25)
                        box.Thickness  = 2
                        box.Transparency = 1
                        box.Color      = Color3.new(1, 0, 0)
                        box.Filled     = false
                        table.insert(espFolder, box)
                    end

                    -- Name
                    if config.ESPNames then
                        local txt = Drawing.new("Text")
                        txt.Text       = plr.Name
                        txt.Position   = Vector2.new(screenPos.X, screenPos.Y - 40)
                        txt.Center     = true
                        txt.Outline    = true
                        txt.Size       = 16
                        table.insert(espFolder, txt)
                    end
                end
            end
        end
    end)
end
