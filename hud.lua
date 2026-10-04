local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Stats = game:GetService("Stats")
 
local LocalPlayer = Players.LocalPlayer
local MAX_PLAYERS = 12
 
-- Xóa HUD cũ nếu chạy script nhiều lần
local function getParent()
    -- Ưu tiên gethui / CoreGui để nằm trên các UI khác, rồi mới tới PlayerGui
    local ok, ui = pcall(function()
        return (gethui and gethui()) or game:GetService("CoreGui")
    end)
    if ok and ui then
        return ui
    end
    return LocalPlayer:WaitForChild("PlayerGui")
end
 
local parent = getParent()
local old = parent:FindFirstChild("InfoHUD")
if old then old:Destroy() end
 
-- ScreenGui (hiển thị đè lên mọi thứ)
local gui = Instance.new("ScreenGui")
gui.Name = "InfoHUD"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 2147483647
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
pcall(function() gui.OnTopOfCoreBlur = true end)
gui.Parent = parent
 
-- Hàm tạo chữ (không nền, không viền khung)
local function makeLabel(y, size, x)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.Position = UDim2.new(0, x or 16, 0, y)
    l.Size = UDim2.new(0, 320, 0, size + 6)
    l.Font = Enum.Font.FredokaOne
    l.TextSize = size
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.TextStrokeColor3 = Color3.new(0, 0, 0)
    l.TextStrokeTransparency = 0.2
    l.ZIndex = 1000
    l.Text = ""
    l.Parent = gui
    return l
end
 
local fpsLabel = makeLabel(14, 44)
local playersLabel = makeLabel(66, 34)
local pingLabel = makeLabel(24, 34, 250) -- nằm bên phải FPS (đổi số 250 để dời ngang)
 
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
 
-- Ping (độ trễ mạng, đơn vị ms)
local function getPing()
    local ok, v = pcall(function()
        return Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
    end)
    if ok and v then return v end
 
    local ok2, p = pcall(function()
        return LocalPlayer:GetNetworkPing() * 2000
    end)
    if ok2 then return p end
    return nil
end
 
local function getPingColor(ms)
    if ms < 80 then
        return Color3.fromRGB(85, 230, 130)   -- mạng tốt
    elseif ms < 150 then
        return Color3.fromRGB(255, 200, 60)   -- tạm được
    end
    return Color3.fromRGB(255, 85, 85)        -- lag
end
 
task.spawn(function()
    while gui.Parent do
        local ms = getPing()
        if ms then
            pingLabel.Text = string.format("Ping: %dms", math.floor(ms + 0.5))
            pingLabel.TextColor3 = getPingColor(ms)
        else
            pingLabel.Text = "Ping: --"
        end
        task.wait(1)
    end
end)
 
-- FPS + màu cầu vồng
local frames = 0
local last = os.clock()
 
RunService.RenderStepped:Connect(function()
    frames += 1
 
    local t = os.clock()
    fpsLabel.TextColor3 = Color3.fromHSV((t % 4) / 4, 1, 1)
 
    if t - last >= 1 then
        fpsLabel.Text = "FPS: " .. math.floor(frames / (t - last))
        frames = 0
        last = t
    end
end)
 
