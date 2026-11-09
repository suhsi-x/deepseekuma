-- UMACring 原生极简UI版 (修复技能卡顿 + 拦截发包)
if not game:IsLoaded() then game.Loaded:Wait() end
task.wait(0.5)

local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- 状态变量
local isInfiniteStamina = false
local isEasyControl = false
local speedMultiplier = 1
local FVelocity = Vector3.new(0, 0, 0)

-- ==========================================
-- 1. 原生极简 UI (固定位置，轻量流畅)
-- ==========================================
local gui = Instance.new("ScreenGui")
gui.Name = "UMAC_Native_UI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 9999
gui.Parent = player:WaitForChild("PlayerGui")

local mainFrame = Instance.new("Frame", gui)
mainFrame.Size = UDim2.fromOffset(180, 130)
mainFrame.Position = UDim2.new(0.5, -90, 0, 10) -- 顶部居中固定
mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
mainFrame.BackgroundTransparency = 0.1
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 8)

-- 标题栏
local titleBar = Instance.new("Frame", mainFrame)
titleBar.Size = UDim2.new(1, 0, 0, 24)
titleBar.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
titleBar.BorderSizePixel = 0
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 8)

local title = Instance.new("TextLabel", titleBar)
title.Size = UDim2.new(1, -30, 1, 0)
title.Position = UDim2.fromOffset(10, 0)
title.BackgroundTransparency = 1
title.Text = "UMACring · 优化版"
title.TextColor3 = Color3.fromRGB(200, 200, 210)
title.Font = Enum.Font.GothamMedium
title.TextSize = 12
title.TextXAlignment = Enum.TextXAlignment.Left

-- 关闭按钮
local closeBtn = Instance.new("TextButton", titleBar)
closeBtn.Size = UDim2.fromOffset(20, 20)
closeBtn.Position = UDim2.new(1, -24, 0, 2)
closeBtn.BackgroundTransparency = 1
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 12
closeBtn.MouseButton1Click:Connect(function() gui:Destroy() end)

-- 勾选框生成函数
local function createToggle(textStr, yPos, callback)
    local btn = Instance.new("TextButton", mainFrame)
    btn.Size = UDim2.fromOffset(20, 20)
    btn.Position = UDim2.fromOffset(10, yPos)
    btn.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
    btn.Text = ""
    btn.AutoButtonColor = false
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
    
    local check = Instance.new("TextLabel", btn)
    check.Size = UDim2.fromScale(1, 1)
    check.BackgroundTransparency = 1
    check.Text = "✓"
    check.TextColor3 = Color3.fromRGB(120, 255, 150)
    check.TextSize = 16
    check.Font = Enum.Font.GothamBold
    check.TextTransparency = 1

    local label = Instance.new("TextLabel", mainFrame)
    label.Size = UDim2.new(1, -40, 0, 20)
    label.Position = UDim2.fromOffset(38, yPos)
    label.BackgroundTransparency = 1
    label.Text = textStr
    label.TextColor3 = Color3.fromRGB(230, 230, 240)
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left

    local state = false
    btn.Activated:Connect(function()
        state = not state
        check.TextTransparency = state and 0 or 1
        btn.BackgroundColor3 = state and Color3.fromRGB(40, 90, 55) or Color3.fromRGB(60, 60, 70)
        callback(state)
    end)
end

-- 滑动条生成函数
local function createSlider(textStr, yPos, callback)
    local label = Instance.new("TextLabel", mainFrame)
    label.Size = UDim2.new(1, -20, 0, 20)
    label.Position = UDim2.fromOffset(10, yPos)
    label.BackgroundTransparency = 1
    label.Text = textStr .. " : 1.00"
    label.TextColor3 = Color3.fromRGB(230, 230, 240)
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left

    local sliderBtn = Instance.new("TextButton", mainFrame)
    sliderBtn.Size = UDim2.new(1, -20, 0, 16)
    sliderBtn.Position = UDim2.fromOffset(10, yPos + 20)
    sliderBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
    sliderBtn.Text = ""
    Instance.new("UICorner", sliderBtn).CornerRadius = UDim.new(0, 4)

    local fill = Instance.new("Frame", sliderBtn)
    fill.Size = UDim2.new(0, 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(90, 150, 220)
    Instance.new("UICorner", fill).CornerRadius = UDim.new(0, 4)

    local function updateSlider(input)
        local percent = math.clamp((input.Position.X - sliderBtn.AbsolutePosition.X) / sliderBtn.AbsoluteSize.X, 0, 1)
        fill.Size = UDim2.fromScale(percent, 1)
        local val = 1 + (percent * 2)
        label.Text = textStr .. " : " .. string.format("%.2f", val)
        callback(val)
    end

    sliderBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            updateSlider(input)
            local moveConn
            moveConn = game:GetService("UserInputService").InputChanged:Connect(function(moveInput)
                if moveInput.UserInputType == Enum.UserInputType.MouseMovement or moveInput.UserInputType == Enum.UserInputType.Touch then
                    updateSlider(moveInput)
                end
            end)
            game:GetService("UserInputService").InputEnded:Connect(function(endInput)
                if endInput.UserInputType == Enum.UserInputType.MouseButton1 or endInput.UserInputType == Enum.UserInputType.Touch then
                    if moveConn then moveConn:Disconnect() end
                end
            end)
        end
    end)
end

-- 渲染 UI
createToggle("无限体力 (4109)", 32, function(s) isInfiniteStamina = s end)
createToggle("简易控制 (4256)", 60, function(s) isEasyControl = s end)
createSlider("移动速度倍率", 90, function(v) speedMultiplier = v end)

-- ==========================================
-- 2. 核心 Hook 逻辑 (修复技能卡死)
-- ==========================================

-- 拦截 __index
local oldindex
oldindex = hookmetamethod(game, "__index", function(v1, v2)
    if v2 == "Velocity" or v2 == "ToOrientation" then
        if isEasyControl and v2 == "Velocity" then
            if getnamecallmethod() == "ToOrientation" then
                return FVelocity
            end
        end
    end
    return oldindex(v1, v2)
end)

-- 拦截 __newindex (处理物理速度)
local oldnewindex
oldnewindex = hookmetamethod(game, "__newindex", function(v1, v2, v3)
    if v2 == "AssemblyLinearVelocity" and typeof(v3) == "Vector3" then
        if isEasyControl then
            local mag = v3.Magnitude
            -- 技能高速 (>50) 或 几乎静止 (<0.1) 时，直接放行，不干涉，防止卡在原地或卡空中
            if mag > 50 or mag < 0.1 then
                return oldnewindex(v1, v2, v3)
            end
            
            -- 正常跑动时：仅修改 X 和 Z，保留 Y 轴（重力/跳跃），并按倍率放大水平速度
            local newVel = Vector3.new(
                v3.X * speedMultiplier, 
                v3.Y, 
                v3.Z * speedMultiplier
            )
            return oldnewindex(v1, v2, newVel)
        end
    end
    return oldnewindex(v1, v2, v3)
end)

-- 拦截 __namecall (核心：解决掉体力)
local oldnamecall
oldnamecall = hookmetamethod(game, "__namecall", function(v1, ...)
    local method = getnamecallmethod()
    if isInfiniteStamina and method == "FireServer" then
        local args = {...}
        -- 拦截发向服务器的 SpeedTarget 请求，改为 0
        if args[1] == "SpeedTarget" then
            return oldnamecall(v1, 0, select(2, ...))
        end
    end
    return oldnamecall(v1, ...)
end)

print("[UMACring] 极简 UI 加载完成，技能防卡顿逻辑已就绪。")