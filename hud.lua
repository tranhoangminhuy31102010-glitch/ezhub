local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
 
local LocalPlayer = Players.LocalPlayer
local MAX_PLAYERS = 12
 
-- ScreenGui
local gui = Instance.new("ScreenGui")
gui.Name = "InfoHUD"
gui.ResetOnSpawn = false
gui.DisplayOrder = 100
gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
 
-- Khung chính (to hơn)
local frame = Instance.new("Frame")
frame.Position = UDim2.new(0, 14, 0, 14)
frame.Size = UDim2.new(0, 300, 0, 196)
frame.BackgroundColor3 = Color3.fromRGB(16, 16, 22)
frame.BackgroundTransparency = 0.1
frame.Parent = gui
 
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 16)
 
local bgGradient = Instance.new("UIGradient")
bgGradient.Color = ColorSequence.new(Color3.fromRGB(34, 34, 48), Color3.fromRGB(12, 12, 18))
bgGradient.Rotation = 90
bgGradient.Parent = frame
 
local stroke = Instance.new("UIStroke")
stroke.Thickness = 3
stroke.Parent = frame
 
-- Hàm tạo TextLabel
local function makeLabel(props)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.TextXAlignment = props.Align or Enum.TextXAlignment.Left
    l.Position = props.Position
    l.Size = props.Size
    l.Font = props.Font
    l.TextSize = props.TextSize
    l.TextColor3 = props.Color or Color3.new(1, 1, 1)
    l.Text = props.Text or ""
    l.Parent = frame
    return l
end
 
local function makeDivider(y)
    local d = Instance.new("Frame")
    d.Position = UDim2.new(0, 16, 0, y)
    d.Size = UDim2.new(1, -32, 0, 2)
    d.BackgroundColor3 = Color3.fromRGB(120, 120, 140)
    d.BackgroundTransparency = 0.65
    d.BorderSizePixel = 0
    d.Parent = frame
end
 
-- Tiêu đề
local title = makeLabel({
    Position = UDim2.new(0, 16, 0, 8), Size = UDim2.new(1, -32, 0, 24),
    Font = Enum.Font.GothamBlack, TextSize = 20, Text = "EZ HUB",
})
title.TextStrokeTransparency = 0.6
makeDivider(38)
 
-- FPS
makeLabel({
    Position = UDim2.new(0, 16, 0, 44), Size = UDim2.new(1, -32, 0, 16),
    Font = Enum.Font.GothamBold, TextSize = 14,
    Color = Color3.fromRGB(190, 190, 205), Text = "FPS",
})
local fpsValue = makeLabel({
    Position = UDim2.new(0, 16, 0, 58), Size = UDim2.new(1, -32, 0, 48),
    Font = Enum.Font.FredokaOne, TextSize = 46, Text = "0",
})
fpsValue.TextStrokeTransparency = 0.3
makeDivider(112)
 
-- Số người
makeLabel({
    Position = UDim2.new(0, 16, 0, 118), Size = UDim2.new(1, -32, 0, 16),
    Font = Enum.Font.GothamBold, TextSize = 14,
    Color = Color3.fromRGB(190, 190, 205), Text = "NGƯỜI TRONG SERVER",
})
local playersValue = makeLabel({
    Position = UDim2.new(0, 16, 0, 134), Size = UDim2.new(0.5, 0, 0, 36),
    Font = Enum.Font.FredokaOne, TextSize = 34,
})
playersValue.TextStrokeTransparency = 0.4
 
local statusLabel = makeLabel({
    Position = UDim2.new(0.5, 0, 0, 142), Size = UDim2.new(0.5, -16, 0, 24),
    Font = Enum.Font.GothamBlack, TextSize = 18,
    Align = Enum.TextXAlignment.Right,
})
 
-- Thanh tiến trình
local barBg = Instance.new("Frame")
barBg.Position = UDim2.new(0, 16, 0, 175)
barBg.Size = UDim2.new(1, -32, 0, 12)
barBg.BackgroundColor3 = Color3.fromRGB(50, 50, 62)
barBg.BorderSizePixel = 0
barBg.Parent = frame
Instance.new("UICorner", barBg).CornerRadius = UDim.new(1, 0)
 
local barFill = Instance.new("Frame")
barFill.Size = UDim2.new(0, 0, 1, 0)
barFill.BorderSizePixel = 0
barFill.Parent = barBg
Instance.new("UICorner", barFill).CornerRadius = UDim.new(1, 0)
 
-- Màu và trạng thái theo độ đông
local function getState(count)
    if count >= MAX_PLAYERS then
        return Color3.fromRGB(255, 85, 85), "ĐẦY"
    elseif count >= 9 then
        return Color3.fromRGB(255, 200, 60), "ĐÔNG"
    end
    return Color3.fromRGB(85, 230, 130), "CÒN CHỖ"
end
 
local function updatePlayers()
    local count = #Players:GetPlayers()
    local color, status = getState(count)
 
    playersValue.Text = string.format("%d / %d", count, MAX_PLAYERS)
    playersValue.TextColor3 = color
    statusLabel.Text = status
    statusLabel.TextColor3 = color
 
    TweenService:Create(barFill, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
        Size = UDim2.new(math.clamp(count / MAX_PLAYERS, 0, 1), 0, 1, 0),
        BackgroundColor3 = color,
    }):Play()
end
 
updatePlayers()
Players.PlayerAdded:Connect(function() task.wait(0.1) updatePlayers() end)
Players.PlayerRemoving:Connect(function() task.wait(0.1) updatePlayers() end)
 
-- FPS + hiệu ứng cầu vồng
local frames = 0
local last = os.clock()
 
RunService.RenderStepped:Connect(function()
    frames += 1
 
    local rainbow = Color3.fromHSV((os.clock() % 4) / 4, 1, 1)
    fpsValue.TextColor3 = rainbow
    title.TextColor3 = rainbow
    stroke.Color = rainbow
 
    local now = os.clock()
    if now - last >= 1 then
        fpsValue.Text = tostring(math.floor(frames / (now - last)))
        frames = 0
        last = now
    end
end)
