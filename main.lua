if not game:IsLoaded() then game.Loaded:Wait() end

-- SETTINGS
getgenv().SilentAimTarget = nil
getgenv().SilentAimPart = "HumanoidRootPart"

-- SERVICES
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- GUI SETUP
local gui = Instance.new("ScreenGui", game.CoreGui)
gui.Name = "SilentAim_UI"

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 250, 0, 100)
frame.Position = UDim2.new(0, 10, 0, 10)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.BackgroundTransparency = 0.2
frame.BorderSizePixel = 0

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundTransparency = 1
title.Text = "🎯 Silent Aim Menü"
title.TextColor3 = Color3.new(1, 1, 1)
title.Font = Enum.Font.SourceSansBold
title.TextSize = 18

local targetLabel = Instance.new("TextLabel", frame)
targetLabel.Position = UDim2.new(0, 0, 0, 35)
targetLabel.Size = UDim2.new(1, 0, 0, 25)
targetLabel.BackgroundTransparency = 1
targetLabel.Text = "Ziel: [Kein Spieler]"
targetLabel.TextColor3 = Color3.new(1, 1, 1)
targetLabel.Font = Enum.Font.SourceSans
targetLabel.TextSize = 16

local hintLabel = Instance.new("TextLabel", frame)
hintLabel.Position = UDim2.new(0, 0, 0, 65)
hintLabel.Size = UDim2.new(1, 0, 0, 30)
hintLabel.BackgroundTransparency = 1
hintLabel.Text = "Drücke [E] um Ziel zu setzen"
hintLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
hintLabel.Font = Enum.Font.SourceSans
hintLabel.TextSize = 14

-- TASTE: Ziel auswählen mit E (kein Reset mehr)
UIS.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.E then
        local target = Mouse.Target
        if target then
            local model = target:FindFirstAncestorOfClass("Model")
            if model and model:FindFirstChild("Humanoid") and model ~= LocalPlayer.Character then
                getgenv().SilentAimTarget = model
                targetLabel.Text = "Ziel: " .. model.Name
            end
        end
    end
end)

-- Silent Aim Hook
local oldIndex = hookmetamethod(game, "__index", newcclosure(function(self, index)
    if self == Mouse and not checkcaller() and getgenv().SilentAimTarget then
        local char = getgenv().SilentAimTarget
        local part = char:FindFirstChild(getgenv().SilentAimPart)
        if part then
            if index:lower() == "target" then
                return part
            elseif index:lower() == "hit" then
                return part.Position
            end
        end
    end
    return oldIndex(self, index)
end))
