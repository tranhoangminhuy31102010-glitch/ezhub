local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
 
local LocalPlayer = Players.LocalPlayer
local MAX_PLAYERS = 12
 
-- ScreenGui
local gui = Instance.new("ScreenGui")
gui.Name = "InfoHUD"
gui.ResetOnSpawn = false
gui.DisplayOrder = 100
gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
 
-- Hàm tạo chữ (không nền, không viền khung)
local function makeLabel(y, size)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.Position = UDim2.new(0, 16, 0, y)
    l.Size = UDim2.new(0, 320, 0, size + 6)
    l.Font = Enum.Font.FredokaOne
    l.TextSize = size
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.TextStrokeColor3 = Color3.new(0, 0, 0)
    l.TextStrokeTransparency = 0.2
    l.Text = ""
    l.Parent = gui
    return l
end
 
local fpsLabel = makeLabel(14, 44)
local playersLabel = makeLabel(66, 34)
 
-- Màu số người theo độ đông
local function getColor(count)
    if count >= MAX_PLAYERS then
        return Color3.fromRGB(255, 85, 85)   -- đầy
    elseif count >= 9 then
        return Color3.fromRGB(255, 200, 60)  -- khá đông
    end
    return Color3.fromRGB(85, 230, 130)      -- còn chỗ
end
 
local function updatePlayers()
    local count = #Players:GetPlayers()
    playersLabel.Text = string.format("Người: %d/%d", count, MAX_PLAYERS)
    playersLabel.TextColor3 = getColor(count)
end
 
updatePlayers()
Players.PlayerAdded:Connect(function() task.wait(0.1) updatePlayers() end)
Players.PlayerRemoving:Connect(function() task.wait(0.1) updatePlayers() end)
 
-- FPS + màu cầu vồng
local frames = 0
local last = os.clock()
local fps = 0
 
RunService.RenderStepped:Connect(function()
    frames += 1
 
    fpsLabel.TextColor3 = Color3.fromHSV((os.clock() % 4) / 4, 1, 1)
 
    local now = os.clock()
    if now - last >= 1 then
        fps = math.floor(frames / (now - last))
        fpsLabel.Text = "FPS: " .. fps
        frames = 0
        last = now
    end
end)
 
