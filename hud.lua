local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
 
local LocalPlayer = Players.LocalPlayer
local MAX_PLAYERS = 12
 
-- Cấu hình check trăng
local FULL_MOON_IDS = {
    ["9709149431"] = true, -- ID texture mặt trăng tròn (thêm ID khác vào đây nếu game đổi)
}
local DEBUG_MOON = false   -- true: in ID mặt trăng + giờ trong game ra console (F9) để căn chỉnh
 
-- Cấu hình đếm ngược (tính theo giờ trong game: Lighting.ClockTime, 0-24)
local NIGHT_START = 18     -- đêm bắt đầu lúc mấy giờ game
local NIGHT_END   = 5.5    -- đêm kết thúc (trăng hết) lúc mấy giờ game
 
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
local function makeLabel(y, size)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.Position = UDim2.new(0, 16, 0, y)
    l.Size = UDim2.new(0, 480, 0, size + 6)
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
local moonLabel = makeLabel(108, 30)
 
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
 
-- Check trăng tròn + đếm ngược
local isFullMoon = false
 
local function getMoonId()
    local sky = Lighting:FindFirstChildOfClass("Sky")
    if not sky then return nil end
    return string.match(tostring(sky.MoonTextureId), "%d+")
end
 
-- Đo tốc độ trôi giờ game: cộng dồn từ đầu nên rất ổn định (không dao động theo từng giây)
local prevClock
local accHours, startReal = 0, nil
local rate -- giờ game mỗi giây thực
 
local function sampleRate()
    local clock = Lighting.ClockTime
    local real = os.clock()
 
    if prevClock then
        local dh = (clock - prevClock) % 24
        if dh < 12 then
            accHours += dh
        else
            -- giờ game nhảy bất thường -> đo lại từ đầu
            accHours, startReal, rate = 0, real, nil
        end
    end
    prevClock = clock
    startReal = startReal or real
 
    local secs = real - startReal
    if secs >= 5 and accHours > 0 then
        local r = accHours / secs
        if r > 1e-4 and r < 0.5 then rate = r end
    end
end
 
local function isNight(clock)
    return clock >= NIGHT_START or clock < NIGHT_END
end
 
local function formatTime(sec)
    sec = math.max(0, math.floor(sec + 0.5))
    return string.format("%02d:%02d", sec // 60, sec % 60)
end
 
-- Mốc thời gian thực mà trăng hết, được làm mượt để số chỉ giảm đều
local endReal
local lastShown
 
local function updateMoon()
    local id = getMoonId()
    local clock = Lighting.ClockTime
    local now = os.clock()
    sampleRate()
 
    if DEBUG_MOON then
        print(string.format("Moon ID: %s | ClockTime: %.2f | rate: %s",
            tostring(id), clock, rate and string.format("%.5f", rate) or "?"))
    end
 
    isFullMoon = id ~= nil and FULL_MOON_IDS[id] == true
 
    if not isFullMoon then
        endReal, lastShown = nil, nil
        moonLabel.Text = "Trăng: thường"
        moonLabel.TextColor3 = Color3.fromRGB(190, 190, 205)
        return
    end
 
    if not isNight(clock) then
        endReal, lastShown = nil, nil
        moonLabel.Text = "Trăng tròn: đã hết đêm"
        return
    end
 
    if not rate then
        moonLabel.Text = "Trăng tròn! Còn: đang đo..."
        return
    end
 
    -- Ước lượng mới từ giờ game, rồi trộn nhẹ vào mốc cũ thay vì thay hẳn
    local est = now + ((NIGHT_END - clock) % 24) / rate
    if not endReal or math.abs(est - endReal) > 8 then
        endReal, lastShown = est, nil          -- lệch lớn (đổi đêm, lag...) -> đặt lại
    else
        endReal = endReal + (est - endReal) * 0.1
    end
 
    local remain = endReal - now
    if lastShown and remain > lastShown then
        remain = lastShown                      -- không cho số nhảy ngược lên
    end
    lastShown = remain
 
    moonLabel.Text = "Trăng tròn! Còn ~" .. formatTime(remain)
end
 
updateMoon()
task.spawn(function()
    while gui.Parent do
        pcall(updateMoon)
        task.wait(0.5)
    end
end)
 
-- FPS + màu cầu vồng
local frames = 0
local last = os.clock()
 
RunService.RenderStepped:Connect(function()
    frames += 1
 
    local t = os.clock()
    fpsLabel.TextColor3 = Color3.fromHSV((t % 4) / 4, 1, 1)
 
    -- Trăng tròn thì chữ nhấp nháy vàng cho nổi bật
    if isFullMoon then
        local pulse = (math.sin(t * 6) + 1) / 2
        moonLabel.TextColor3 = Color3.fromRGB(255, 255, 140):Lerp(Color3.fromRGB(255, 190, 40), pulse)
    end
 
    if t - last >= 1 then
        fpsLabel.Text = "FPS: " .. math.floor(frames / (t - last))
        frames = 0
        last = t
    end
end)
