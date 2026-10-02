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

-- Khung chính
local frame = Instance.new("Frame")
frame.Position = UDim2.new(0, 12, 0, 12)
frame.Size = UDim2.new(0, 200, 0, 118)
frame.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
frame.BackgroundTransparency = 0.2
frame.Parent = gui

Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 12)

local stroke = Instance.new("UIStroke")
stroke.Thickness = 2
stroke.Parent = frame

-- Hàm tạo TextLabel cho gọn
local function makeLabel(props)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Position = props.Position
    l.Size = props.Size
    l.Font = props.Font
    l.TextSize = props.TextSize
    l.TextColor3 = props.Color or Color3.new(1, 1, 1)
    l.Text = props.Text or ""
    l.Parent = frame
    return l
end

-- Hàng FPS
makeLabel({
    Position = UDim2.new(0, 12, 0, 6), Size = UDim2.new(1, -24, 0, 14),
    Font = Enum.Font.GothamMedium, TextSize = 12,
    Color = Color3.fromRGB(170, 170, 180), Text = "FPS",
})
local fpsValue = makeLabel({
    Position = UDim2.new(0, 12, 0, 18), Size = UDim2.new(1, -24, 0, 32),
    Font = Enum.Font.FredokaOne, TextSize = 28, Text = "0",
})
fpsValue.TextStrokeTransparency = 0.5

-- Đường kẻ ngăn cách
local divider = Instance.new("Frame")
divider.Position = UDim2.new(0, 12, 0, 56)
divider.Size = UDim2.new(1, -24, 0, 1)
divider.BackgroundColor3 = Color3.fromRGB(120, 120, 130)
divider.BackgroundTransparency = 0.6
divider.BorderSizePixel = 0
divider.Parent = frame

-- Hàng số người
makeLabel({
    Position = UDim2.new(0, 12, 0, 62), Size = UDim2.new(1, -24, 0, 14),
    Font = Enum.Font.GothamMedium, TextSize = 12,
    Color = Color3.fromRGB(170, 170, 180), Text = "NGƯỜI TRONG SERVER",
})
local playersValue = makeLabel({
    Position = UDim2.new(0, 12, 0, 76), Size = UDim2.new(1, -24, 0, 26),
    Font = Enum.Font.FredokaOne, TextSize = 22,
})

-- Thanh tiến trình
local barBg = Instance.new("Frame")
barBg.Position = UDim2.new(0, 12, 0, 104)
barBg.Size = UDim2.new(1, -24, 0, 6)
barBg.BackgroundColor3 = Color3.fromRGB(50, 50, 58)
barBg.BorderSizePixel = 0
barBg.Parent = frame
Instance.new("UICorner", barBg).CornerRadius = UDim.new(1, 0)

local barFill = Instance.new("Frame")
barFill.Size = UDim2.new(0, 0, 1, 0)
barFill.BorderSizePixel = 0
barFill.Parent = barBg
Instance.new("UICorner", barFill).CornerRadius = UDim.new(1, 0)

-- Màu theo độ đông
local function getColor(count)
    if count >= MAX_PLAYERS then
        return Color3.fromRGB(235, 80, 80)   -- đầy
    elseif count >= 9 then
        return Color3.fromRGB(240, 190, 60)  -- khá đông
    end
    return Color3.fromRGB(80, 200, 120)      -- còn nhiều chỗ
end

local function updatePlayers()
    local count = #Players:GetPlayers()
    local color = getColor(count)

    playersValue.Text = string.format("%d / %d", count, MAX_PLAYERS)
    playersValue.TextColor3 = color

    local info = TweenInfo.new(0.3, Enum.EasingStyle.Quad)
    TweenService:Create(barFill, info, {
        Size = UDim2.new(math.clamp(count / MAX_PLAYERS, 0, 1), 0, 1, 0),
        BackgroundColor3 = color,
    }):Play()
end

updatePlayers()
Players.PlayerAdded:Connect(function() task.wait(0.1) updatePlayers() end)
Players.PlayerRemoving:Connect(function() task.wait(0.1) updatePlayers() end)

-- FPS + hiệu ứng cầu vồng (gộp chung 1 vòng lặp)
local frames = 0
local last = os.clock()

RunService.RenderStepped:Connect(function()
    frames += 1

    local rainbow = Color3.fromHSV((os.clock() % 4) / 4, 1, 1)
    fpsValue.TextColor3 = rainbow
    stroke.Color = rainbow

    local now = os.clock()
    if now - last >= 1 then
        fpsValue.Text = tostring(math.floor(frames / (now - last)))
        frames = 0
        last = now
    end
end)
