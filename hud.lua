-- ============================================================
--  InfoHUD + Fix Lag  |  Blox Fruits
--  GitHub: ezhub/hud.lua
-- ============================================================
 
-- ╔══════════════════════════════════════════════════════════╗
--  Đọc _G.CONFIG nếu người dùng truyền vào trước loadstring
--  Nếu không có thì dùng giá trị mặc định bên dưới
-- ╚══════════════════════════════════════════════════════════╝
local function cfg(key, default)
    if _G.CONFIG and _G.CONFIG[key] ~= nil then
        return _G.CONFIG[key]
    end
    return default
end
 
local SHOW_FPS     = cfg("SHOW_FPS",     true)
local SHOW_PLAYERS = cfg("SHOW_PLAYERS", true)
local SHOW_PING    = cfg("SHOW_PING",    true)
local FIX_LAG      = cfg("FIX_LAG",      true)
 
-- ── Cài đặt nâng cao ────────────────────────────────────────
local MAX_PLAYERS   = 12
local MAX_SANE_PING = 3000
local PING_SAMPLES  = 5
local DEBUG_PING    = false
-- ────────────────────────────────────────────────────────────
 
local RunService  = game:GetService("RunService")
local Players     = game:GetService("Players")
local Stats       = game:GetService("Stats")
local Lighting    = game:GetService("Lighting")
local Workspace   = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
 
print(string.format(
    "[ezhub] FPS=%s | Players=%s | Ping=%s | FixLag=%s",
    tostring(SHOW_FPS), tostring(SHOW_PLAYERS),
    tostring(SHOW_PING), tostring(FIX_LAG)
))
 
-- ══════════════════════════════════════════════════════════
--  FIX LAG
-- ══════════════════════════════════════════════════════════
if FIX_LAG then
    Lighting.GlobalShadows            = false
    Lighting.EnvironmentDiffuseScale  = 0
    Lighting.EnvironmentSpecularScale = 0
 
    local gray = Lighting:FindFirstChild("FullMapGrayscale")
    if not gray then
        gray        = Instance.new("ColorCorrectionEffect")
        gray.Name   = "FullMapGrayscale"
        gray.Parent = Lighting
    end
    gray.Saturation = -1
    gray.Contrast   = 0
    gray.Brightness = 0
 
    local function optimizeObject(obj)
        if obj:IsA("BasePart") then
            obj.Color       = Color3.fromRGB(128, 128, 128)
            obj.Material    = Enum.Material.Plastic
            obj.Reflectance = 0
            obj.CastShadow  = false
        end
        if obj:IsA("ParticleEmitter") or obj:IsA("Trail")
        or obj:IsA("Beam")           or obj:IsA("Smoke")
        or obj:IsA("Fire")           or obj:IsA("Sparkles") then
            obj.Enabled = false
        end
        if obj:IsA("PointLight") or obj:IsA("SpotLight")
        or obj:IsA("SurfaceLight") then
            obj.Enabled = false
        end
    end
 
    for _, obj in ipairs(Workspace:GetDescendants()) do
        optimizeObject(obj)
    end
    Workspace.DescendantAdded:Connect(function(obj)
        task.wait(); optimizeObject(obj)
    end)
 
    print("[ezhub] FIX LAG: ON")
end
 
-- ══════════════════════════════════════════════════════════
--  INFO HUD
-- ══════════════════════════════════════════════════════════
if not (SHOW_FPS or SHOW_PING or SHOW_PLAYERS) then return end
 
local function getParent()
    local ok, ui = pcall(function()
        return (gethui and gethui()) or game:GetService("CoreGui")
    end)
    if ok and ui then return ui end
    return LocalPlayer:WaitForChild("PlayerGui")
end
 
local parent = getParent()
local old    = parent:FindFirstChild("InfoHUD")
if old then old:Destroy() end
 
local gui = Instance.new("ScreenGui")
gui.Name              = "InfoHUD"
gui.ResetOnSpawn      = false
gui.IgnoreGuiInset    = true
gui.DisplayOrder      = 2147483647
gui.ZIndexBehavior    = Enum.ZIndexBehavior.Sibling
pcall(function() gui.OnTopOfCoreBlur = true end)
gui.Parent = parent
 
local function makeLabel(y, size, x)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.Position               = UDim2.new(0, x or 16, 0, y)
    l.Size                   = UDim2.new(0, 320, 0, size + 6)
    l.Font                   = Enum.Font.FredokaOne
    l.TextSize               = size
    l.TextXAlignment         = Enum.TextXAlignment.Left
    l.TextStrokeColor3       = Color3.new(0, 0, 0)
    l.TextStrokeTransparency = 0.2
    l.ZIndex                 = 1000
    l.Text                   = ""
    l.Parent                 = gui
    return l
end
 
local PING_GAP     = 18
local fpsLabel     = SHOW_FPS     and makeLabel(14, 44) or nil
local pingLabel    = SHOW_PING    and makeLabel(24, 34) or nil
local playersLabel = SHOW_PLAYERS and makeLabel(66, 34) or nil
 
local function repositionPing()
    if not (pingLabel and fpsLabel) then return end
    pingLabel.Position = UDim2.new(0, 16 + fpsLabel.TextBounds.X + PING_GAP, 0, 24)
end
 
-- ── Số người chơi ──────────────────────────────────────────
if SHOW_PLAYERS then
    local function playerColor(n)
        if n >= MAX_PLAYERS then return Color3.fromRGB(255, 85,  85) end
        if n >= 9           then return Color3.fromRGB(255, 200, 60) end
        return Color3.fromRGB(85, 230, 130)
    end
    local function updatePlayers()
        local n = #Players:GetPlayers()
        playersLabel.Text       = string.format("Người: %d/%d", n, MAX_PLAYERS)
        playersLabel.TextColor3 = playerColor(n)
    end
    updatePlayers()
    Players.PlayerAdded:Connect(function()    task.wait(0.1); updatePlayers() end)
    Players.PlayerRemoving:Connect(function() task.wait(0.1); updatePlayers() end)
end
 
-- ── Ping ───────────────────────────────────────────────────
if SHOW_PING then
    local function isSane(v)
        return type(v) == "number" and v >= 0 and v <= MAX_SANE_PING
    end
    local function getPing()
        local dataPing, netPing
        local ok,  v = pcall(function() return Stats.Network.ServerStatsItem["Data Ping"]:GetValue() end)
        local ok2, p = pcall(function() return LocalPlayer:GetNetworkPing() * 2000 end)
        if ok  then dataPing = v end
        if ok2 then netPing  = p end
        if DEBUG_PING then print("Data Ping:", dataPing, "| NetPing x2000:", netPing) end
        if isSane(dataPing) then return dataPing end
        if isSane(netPing)  then return netPing  end
        return nil
    end
    local function pingColor(ms)
        if ms < 80  then return Color3.fromRGB(85, 230, 130) end
        if ms < 150 then return Color3.fromRGB(255, 200, 60) end
        return Color3.fromRGB(255, 85, 85)
    end
    local samples = {}
    local function median(t)
        local c = table.clone(t); table.sort(c)
        local n = #c
        if n % 2 == 1 then return c[(n+1)//2] end
        return (c[n//2] + c[n//2+1]) / 2
    end
    task.spawn(function()
        while gui.Parent do
            local ms = getPing()
            if ms then
                table.insert(samples, ms)
                if #samples > PING_SAMPLES then table.remove(samples, 1) end
                local val = median(samples)
                pingLabel.Text       = string.format("Ping: %dms", math.floor(val + 0.5))
                pingLabel.TextColor3 = pingColor(val)
            else
                pingLabel.Text = "Ping: --"
            end
            repositionPing()
            task.wait(0.5)
        end
    end)
end
 
-- ── FPS + màu cầu vồng ─────────────────────────────────────
if SHOW_FPS then
    local frames, last = 0, os.clock()
    RunService.RenderStepped:Connect(function()
        frames += 1
        local t = os.clock()
        fpsLabel.TextColor3 = Color3.fromHSV((t % 4) / 4, 1, 1)
        if t - last >= 1 then
            fpsLabel.Text = "FPS: " .. math.floor(frames / (t - last))
            repositionPing()
            frames = 0
            last   = t
        end
    end)
end
