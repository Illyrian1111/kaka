-- Jailbreak-kompatible Silent Aim Version (Lernzwecke)

if not game:IsLoaded() then game.Loaded:Wait() end

getgenv().protectgui = getgenv().protectgui or function() end

local SilentAimSettings = {
    Enabled = true,
    ToggleKey = "RightAlt",
    TeamCheck = false,
    VisibleCheck = false,
    TargetPart = "HumanoidRootPart",
    SilentAimMethod = "Mouse.Hit/Target",
    FOVRadius = 160,
    FOVVisible = true,
    ShowSilentAimTarget = true,
    MouseHitPrediction = true,
    MouseHitPredictionAmount = 0.2,
    HitChance = 100
}

getgenv().SilentAimSettings = SilentAimSettings

-- Services
local Camera = workspace.CurrentCamera
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- Drawing
local mouse_box = Drawing.new("Square")
mouse_box.Visible = true
mouse_box.ZIndex = 999
mouse_box.Color = Color3.fromRGB(54, 57, 241)
mouse_box.Thickness = 20
mouse_box.Size = Vector2.new(20, 20)
mouse_box.Filled = true

local fov_circle = Drawing.new("Circle")
fov_circle.Thickness = 1
fov_circle.NumSides = 100
fov_circle.Radius = SilentAimSettings.FOVRadius
fov_circle.Filled = false
fov_circle.Visible = SilentAimSettings.FOVVisible
fov_circle.ZIndex = 999
fov_circle.Transparency = 1
fov_circle.Color = Color3.fromRGB(54, 57, 241)

-- Helpers
local function getMousePosition()
    return UserInputService:GetMouseLocation()
end

local function getPositionOnScreen(Vector)
    local screenPos, onScreen = Camera:WorldToScreenPoint(Vector)
    return Vector2.new(screenPos.X, screenPos.Y), onScreen
end

local function getClosestPlayer()
    local closest = nil
    local shortestDistance = math.huge

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        if SilentAimSettings.TeamCheck and player.Team == LocalPlayer.Team then continue end

        local character = player.Character
        local targetPart = character and character:FindFirstChild(SilentAimSettings.TargetPart)
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if not (targetPart and humanoid and humanoid.Health > 0) then continue end

        local screenPos, onScreen = getPositionOnScreen(targetPart.Position)
        if not onScreen then continue end

        local distance = (getMousePosition() - screenPos).Magnitude
        if distance < shortestDistance and distance <= SilentAimSettings.FOVRadius then
            closest = targetPart
            shortestDistance = distance
        end
    end

    return closest
end

-- Drawing updater
RunService.RenderStepped:Connect(function()
    local mousePos = getMousePosition()
    fov_circle.Position = mousePos

    if SilentAimSettings.FOVVisible then
        fov_circle.Radius = SilentAimSettings.FOVRadius
        fov_circle.Visible = true
    else
        fov_circle.Visible = false
    end

    local target = getClosestPlayer()
    if target and SilentAimSettings.ShowSilentAimTarget and SilentAimSettings.Enabled then
        local screenPos, onScreen = getPositionOnScreen(target.Position)
        if onScreen then
            mouse_box.Visible = true
            mouse_box.Position = screenPos
        else
            mouse_box.Visible = false
        end
    else
        mouse_box.Visible = false
    end
end)

-- __index hook (Mouse.Hit/Target support)
local oldIndex
oldIndex = hookmetamethod(game, "__index", newcclosure(function(self, index)
    if self == Mouse and not checkcaller() and SilentAimSettings.Enabled and SilentAimSettings.SilentAimMethod == "Mouse.Hit/Target" then
        local target = getClosestPlayer()
        if target then
            if index == "Target" or index == "target" then
                return target
            elseif index == "Hit" or index == "hit" then
                if SilentAimSettings.MouseHitPrediction then
                    return (target.CFrame + target.Velocity * SilentAimSettings.MouseHitPredictionAmount).Position
                else
                    return target.Position
                end
            end
        end
    end
    return oldIndex(self, index)
end))
