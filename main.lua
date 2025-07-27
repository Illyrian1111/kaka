if not game:IsLoaded() then game.Loaded:Wait() end

-- Settings
getgenv().SilentAimTarget = nil
getgenv().SilentAimPart = "HumanoidRootPart"

-- Services
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- GUI
local ScreenGui = Instance.new("ScreenGui", game.CoreGui)
ScreenGui.Name = "SilentAimMenu"

local TargetBox = Instance.new("TextLabel", ScreenGui)
TargetBox.Position = UDim2.new(0.5, -100, 0, 20)
TargetBox.Size = UDim2.new(0, 200, 0, 30)
TargetBox.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
TargetBox.TextColor3 = Color3.fromRGB(255, 255, 255)
TargetBox.TextSize = 16
TargetBox.Text = "Kein Ziel ausgewählt"
TargetBox.BorderSizePixel = 0

-- Select Target with E
UIS.InputBegan:Connect(function(input, gameProcessed)
    if input.KeyCode == Enum.KeyCode.E and not gameProcessed then
        local target = Mouse.Target
        if target and target.Parent then
            local model = target:FindFirstAncestorWhichIsA("Model")
            if model and model:FindFirstChild("Humanoid") then
                getgenv().SilentAimTarget = model
                TargetBox.Text = "Ziel: " .. model.Name
            end
        end
    end
end)

-- Silent Aim Hook (__index)
local oldIndex = nil
oldIndex = hookmetamethod(game, "__index", newcclosure(function(self, index)
    if self == Mouse and not checkcaller() and getgenv().SilentAimTarget then
        local targetChar = getgenv().SilentAimTarget
        local targetPart = targetChar:FindFirstChild(getgenv().SilentAimPart)

        if targetPart then
            if index:lower() == "target" then
                return targetPart
            elseif index:lower() == "hit" then
                return targetPart.Position
            end
        end
    end
    return oldIndex(self, index)
end))
