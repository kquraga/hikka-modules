--[[
    Grow a Garden - Auto-Buy Menu (Улучшенная версия)
    - Только покупки (никакой продажи/посадки)
    - С сохранением выбора
    - С отображением баланса
    - С кнопками "Выбрать всё"
]]

--// Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

--// Настройки
local TOGGLE_KEY = Enum.KeyCode.RightShift
local HOLD_KEY = Enum.KeyCode.LeftControl
local SAVE_FILE = "AutoBuy_Garden.txt"

--// Состояния
local isVisible = true
local isExpanded = true
local isDragging = false
local dragStart, startPos
local minimizedSize = UDim2.new(0, 220, 0, 50)
local expandedSize = UDim2.new(0, 580, 0, 620)

--// Загрузка сохранений
local savedSelections = {}
local function LoadSavedSelections()
    local success, data = pcall(function() return readfile(SAVE_FILE) end)
    if success and data then
        savedSelections = game:GetService("HttpService"):JSONDecode(data)
    else
        savedSelections = {}
    end
end

local function SaveSelections()
    local success, encoded = pcall(function() return game:GetService("HttpService"):JSONEncode(savedSelections) end)
    if success then
        pcall(function() writefile(SAVE_FILE, encoded) end)
    end
end

LoadSavedSelections()

-- Удаляем старый GUI
local oldGui = PlayerGui:FindFirstChild("AutoBuyGarden")
if oldGui then oldGui:Destroy() end

--// Создаём GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AutoBuyGarden"
ScreenGui.Parent = PlayerGui

--// Главное окно
local MainFrame = Instance.new("Frame")
MainFrame.Size = expandedSize
MainFrame.Position = UDim2.new(0.5, -290, 0.5, -310)
MainFrame.BackgroundColor3 = Color3.fromRGB(28, 28, 34)
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 12)
MainCorner.Parent = MainFrame

--// Заголовок
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 50)
TitleBar.BackgroundColor3 = Color3.fromRGB(38, 38, 46)
TitleBar.Parent = MainFrame

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 12)
TitleCorner.Parent = TitleBar

-- Баланс в заголовке
local BalanceText = Instance.new("TextLabel")
BalanceText.Size = UDim2.new(0, 200, 1, 0)
BalanceText.Position = UDim2.new(0, 15, 0, 0)
BalanceText.BackgroundTransparency = 1
BalanceText.Text = "💰 Загрузка..."
BalanceText.TextColor3 = Color3.fromRGB(255, 215, 0)
BalanceText.TextSize = 14
BalanceText.TextXAlignment = Enum.TextXAlignment.Left
BalanceText.Font = Enum.Font.GothamBold
BalanceText.Parent = TitleBar

local TitleText = Instance.new("TextLabel")
TitleText.Size = UDim2.new(1, -180, 1, 0)
TitleText.Position = UDim2.new(0, 220, 0, 0)
TitleText.BackgroundTransparency = 1
TitleText.Text = "🌱 Auto-Buy | Grow a Garden"
TitleText.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleText.TextSize = 18
TitleText.TextXAlignment = Enum.TextXAlignment.Center
TitleText.Font = Enum.Font.GothamBold
TitleText.Parent = TitleBar

-- Кнопки в заголовке
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 35, 0, 35)
CloseBtn.Position = UDim2.new(1, -90, 0, 7)
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.TextSize = 20
CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
CloseBtn.BorderSizePixel = 0
CloseBtn.Parent = TitleBar

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 8)
CloseCorner.Parent = CloseBtn

CloseBtn.MouseButton1Click:Connect(function()
    SaveSelections()
    ScreenGui:Destroy()
end)

local ExpandBtn = Instance.new("TextButton")
ExpandBtn.Size = UDim2.new(0, 35, 0, 35)
ExpandBtn.Position = UDim2.new(1, -45, 0, 7)
ExpandBtn.Text = "▼"
ExpandBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ExpandBtn.TextSize = 20
ExpandBtn.BackgroundColor3 = Color3.fromRGB(70, 130, 70)
ExpandBtn.BorderSizePixel = 0
ExpandBtn.Parent = TitleBar

local ExpandCorner = Instance.new("UICorner")
ExpandCorner.CornerRadius = UDim.new(0, 8)
ExpandCorner.Parent = ExpandBtn

--// Контейнер содержимого
local ContentContainer = Instance.new("Frame")
ContentContainer.Size = UDim2.new(1, 0, 1, -50)
ContentContainer.Position = UDim2.new(0, 0, 0, 50)
ContentContainer.BackgroundTransparency = 1
ContentContainer.Parent = MainFrame

--// ЛЕВАЯ ПАНЕЛЬ
local LeftPanel = Instance.new("Frame")
LeftPanel.Size = UDim2.new(0, 180, 1, 0)
LeftPanel.BackgroundColor3 = Color3.fromRGB(33, 33, 40)
LeftPanel.BorderSizePixel = 0
LeftPanel.Parent = ContentContainer

local ButtonsContainer = Instance.new("ScrollingFrame")
ButtonsContainer.Size = UDim2.new(1, 0, 1, 0)
ButtonsContainer.BackgroundTransparency = 1
ButtonsContainer.ScrollBarThickness = 4
ButtonsContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
ButtonsContainer.Parent = LeftPanel

local ButtonsLayout = Instance.new("UIListLayout")
ButtonsLayout.Padding = UDim.new(0, 8)
ButtonsLayout.Parent = ButtonsContainer

local ButtonsPadding = Instance.new("UIPadding")
ButtonsPadding.PaddingLeft = UDim.new(0, 10)
ButtonsPadding.PaddingRight = UDim.new(0, 10)
ButtonsPadding.PaddingTop = UDim.new(0, 15)
ButtonsPadding.PaddingBottom = UDim.new(0, 15)
ButtonsPadding.Parent = ButtonsContainer

--// ПРАВАЯ ПАНЕЛЬ
local RightPanel = Instance.new("Frame")
RightPanel.Size = UDim2.new(1, -190, 1, 0)
RightPanel.Position = UDim2.new(0, 190, 0, 0)
RightPanel.BackgroundColor3 = Color3.fromRGB(38, 38, 46)
RightPanel.BorderSizePixel = 0
RightPanel.Parent = ContentContainer

local RightCorner = Instance.new("UICorner")
RightCorner.CornerRadius = UDim.new(0, 10)
RightCorner.Parent = RightPanel

local RightScroll = Instance.new("ScrollingFrame")
RightScroll.Size = UDim2.new(1, 0, 1, 0)
RightScroll.BackgroundTransparency = 1
RightScroll.ScrollBarThickness = 6
RightScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
RightScroll.Parent = RightPanel

local RightLayout = Instance.new("UIListLayout")
RightLayout.Padding = UDim.new(0, 12)
RightLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
RightLayout.Parent = RightScroll

local RightPadding = Instance.new("UIPadding")
RightPadding.PaddingLeft = UDim.new(0, 15)
RightPadding.PaddingRight = UDim.new(0, 15)
RightPadding.PaddingTop = UDim.new(0, 15)
RightPadding.PaddingBottom = UDim.new(0, 15)
RightPadding.Parent = RightScroll

--// === ФУНКЦИИ СОЗДАНИЯ ЭЛЕМЕНТОВ ===

local function CreateItemCheckbox(parent, itemName, default, onChange)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 38)
    frame.BackgroundColor3 = Color3.fromRGB(48, 48, 56)
    frame.BorderSizePixel = 0
    frame.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = frame
    
    local checkBtn = Instance.new("ImageButton")
    checkBtn.Size = UDim2.new(0, 24, 0, 24)
    checkBtn.Position = UDim2.new(0, 12, 0, 7)
    checkBtn.Image = default and "rbxassetid://3926309021" or "rbxassetid://3926305904"
    checkBtn.BackgroundTransparency = 1
    checkBtn.Parent = frame
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -55, 1, 0)
    label.Position = UDim2.new(0, 48, 0, 0)
    label.Text = itemName
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextColor3 = Color3.fromRGB(230, 230, 230)
    label.BackgroundTransparency = 1
    label.TextSize = 14
    label.Font = Enum.Font.Gotham
    label.Parent = frame
    
    local selected = default
    
    checkBtn.MouseButton1Click:Connect(function()
        selected = not selected
        checkBtn.Image = selected and "rbxassetid://3926309021" or "rbxassetid://3926305904"
        if onChange then onChange(itemName, selected) end
    end)
    
    return {Get = function() return selected end, Set = function(v) selected = v; checkBtn.Image = selected and "rbxassetid://3926309021" or "rbxassetid://3926305904" end}
end

local function CreateSection(parent, title)
    local section = Instance.new("Frame")
    section.Size = UDim2.new(1, 0, 0, 0)
    section.BackgroundTransparency = 1
    section.AutomaticSize = Enum.AutomaticSize.Y
    section.Parent = parent
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, 0, 0, 35)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = title
    titleLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
    titleLabel.TextSize = 16
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.Parent = section
    
    local line = Instance.new("Frame")
    line.Size = UDim2.new(1, 0, 0, 2)
    line.Position = UDim2.new(0, 0, 0, 33)
    line.BackgroundColor3 = Color3.fromRGB(70, 130, 70)
    line.BorderSizePixel = 0
    line.Parent = section
    
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 0, 0)
    container.Position = UDim2.new(0, 0, 0, 40)
    container.BackgroundTransparency = 1
    container.AutomaticSize = Enum.AutomaticSize.Y
    container.Parent = section
    
    return container
end

local function CreateButton(parent, text, color, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -20, 0, 42)
    btn.Position = UDim2.new(0, 10, 0, 5)
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 15
    btn.BackgroundColor3 = color or Color3.fromRGB(70, 130, 70)
    btn.BorderSizePixel = 0
    btn.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = btn
    
    btn.MouseButton1Click:Connect(callback)
    return btn
end

local function CreateAutoToggle(parent, default)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 48)
    frame.BackgroundColor3 = Color3.fromRGB(55, 55, 65)
    frame.BorderSizePixel = 0
    frame.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -100, 1, 0)
    label.Position = UDim2.new(0, 15, 0, 0)
    label.Text = "🤖 Автопокупка"
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextColor3 = Color3.fromRGB(255, 200, 100)
    label.BackgroundTransparency = 1
    label.TextSize = 15
    label.Font = Enum.Font.GothamBold
    label.Parent = frame
    
    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(0, 70, 0, 34)
    toggleBtn.Position = UDim2.new(1, -85, 0, 7)
    toggleBtn.Text = default and "ON" or "OFF"
    toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggleBtn.TextSize = 14
    toggleBtn.BackgroundColor3 = default and Color3.fromRGB(70, 130, 70) or Color3.fromRGB(160, 70, 70)
    toggleBtn.BorderSizePixel = 0
    toggleBtn.Parent = frame
    
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 6)
    btnCorner.Parent = toggleBtn
    
    local state = default or false
    
    toggleBtn.MouseButton1Click:Connect(function()
        state = not state
        toggleBtn.Text = state and "ON" or "OFF"
        toggleBtn.BackgroundColor3 = state and Color3.fromRGB(70, 130, 70) or Color3.fromRGB(160, 70, 70)
    end)
    
    return {Get = function() return state end}
end

local function CreateLimitSelect(parent, default)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 48)
    frame.BackgroundColor3 = Color3.fromRGB(48, 48, 56)
    frame.BorderSizePixel = 0
    frame.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = frame
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0, 80, 1, 0)
    label.Position = UDim2.new(0, 12, 0, 0)
    label.Text = "Лимит:"
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextColor3 = Color3.fromRGB(180, 180, 200)
    label.BackgroundTransparency = 1
    label.TextSize = 14
    label.Parent = frame
    
    local limits = {"1", "5", "10", "25", "50", "100", "∞"}
    local currentIndex = 7
    local selected = default or "∞"
    
    for i, limit in ipairs(limits) do
        if limit == default then currentIndex = i end
    end
    
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 80, 0, 34)
    btn.Position = UDim2.new(1, -95, 0, 7)
    btn.Text = selected
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 14
    btn.BackgroundColor3 = Color3.fromRGB(70, 70, 80)
    btn.BorderSizePixel = 0
    btn.Parent = frame
    
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 6)
    btnCorner.Parent = btn
    
    btn.MouseButton1Click:Connect(function()
        currentIndex = currentIndex % #limits + 1
        selected = limits[currentIndex]
        btn.Text = selected
    end)
    
    return {Get = function() return selected end}
end

local function CreateCounter(parent)
    local counter = Instance.new("TextLabel")
    counter.Size = UDim2.new(1, 0, 0, 30)
    counter.BackgroundTransparency = 1
    counter.Text = "📦 Выбрано: 0 из 0"
    counter.TextColor3 = Color3.fromRGB(150, 150, 170)
    counter.TextSize = 12
    counter.Font = Enum.Font.Gotham
    counter.Parent = parent
    return counter
end

local function CreateSelectAllButtons(parent, onSelectAll, onDeselectAll)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 35)
    frame.BackgroundTransparency = 1
    frame.Parent = parent
    
    local selectAll = Instance.new("TextButton")
    selectAll.Size = UDim2.new(0.48, 0, 0, 30)
    selectAll.Position = UDim2.new(0, 0, 0, 2)
    selectAll.Text = "✅ Выбрать всё"
    selectAll.TextColor3 = Color3.fromRGB(255, 255, 255)
    selectAll.TextSize = 12
    selectAll.BackgroundColor3 = Color3.fromRGB(60, 100, 60)
    selectAll.BorderSizePixel = 0
    selectAll.Parent = frame
    
    local selectCorner = Instance.new("UICorner")
    selectCorner.CornerRadius = UDim.new(0, 6)
    selectCorner.Parent = selectAll
    
    local deselectAll = Instance.new("TextButton")
    deselectAll.Size = UDim2.new(0.48, 0, 0, 30)
    deselectAll.Position = UDim2.new(0.52, 0, 0, 2)
    deselectAll.Text = "❌ Снять всё"
    deselectAll.TextColor3 = Color3.fromRGB(255, 255, 255)
    deselectAll.TextSize = 12
    deselectAll.BackgroundColor3 = Color3.fromRGB(100, 60, 60)
    deselectAll.BorderSizePixel = 0
    deselectAll.Parent = frame
    
    local deselectCorner = Instance.new("UICorner")
    deselectCorner.CornerRadius = UDim.new(0, 6)
    deselectCorner.Parent = deselectAll
    
    selectAll.MouseButton1Click:Connect(onSelectAll)
    deselectAll.MouseButton1Click:Connect(onDeselectAll)
    
    return frame
end

local function CreateStatus(parent)
    local status = Instance.new("TextLabel")
    status.Size = UDim2.new(1, 0, 0, 38)
    status.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
    status.Text = "📢 Готов"
    status.TextColor3 = Color3.fromRGB(150, 150, 170)
    status.TextSize = 12
    status.Font = Enum.Font.Gotham
    status.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = status
    
    return status
end

--// === ДАННЫЕ МАГАЗИНОВ ===

local shopData = {
    Seed = {
        name = "🌱 Seed Shop",
        items = {"Blueberry", "Raspberry", "Blackberry", "Strawberry", "Cocoa", "Grape", "Pepper", "Cacao"},
        defaults = {true, false, false, false, false, false, false, false}
    },
    Gear = {
        name = "🎒 Gear Shop", 
        items = {"Watering Can", "Hoe", "Scythe", "Fertilizer", "Scarecrow", "Sprinkler"},
        defaults = {true, false, false, false, false, false}
    },
    Event = {
        name = "🎪 Event Shop",
        items = {"Event Seed", "Event Tool", "Event Pet", "Cosmetic", "Limited"},
        defaults = {true, false, false, false, false}
    }
}

-- Загружаем сохранённые выборы
for shopKey, data in pairs(shopData) do
    if not savedSelections[shopKey] then
        savedSelections[shopKey] = {}
        for i, item in ipairs(data.items) do
            savedSelections[shopKey][item] = data.defaults[i] or false
        end
    end
end

local checkboxes = {}
local autoToggles = {}
local limitSelects = {}
local statusLabels = {}
local counters = {}

--// === СОЗДАНИЕ ПРАВЫХ ПАНЕЛЕЙ ===

for shopKey, data in pairs(shopData) do
    local container = Instance.new("ScrollingFrame")
    container.Size = UDim2.new(1, 0, 1, 0)
    container.BackgroundTransparency = 1
    container.ScrollBarThickness = 0
    container.CanvasSize = UDim2.new(0, 0, 0, 0)
    container.Visible = false
    container.Parent = RightScroll
    
    local containerLayout = Instance.new("UIListLayout")
    containerLayout.Padding = UDim.new(0, 12)
    containerLayout.Parent = container
    
    -- Заголовок
    local titleFrame = Instance.new("Frame")
    titleFrame.Size = UDim2.new(1, 0, 0, 45)
    titleFrame.BackgroundTransparency = 1
    titleFrame.Parent = container
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 1, 0)
    title.Text = data.name
    title.TextColor3 = Color3.fromRGB(255, 200, 100)
    title.TextSize = 22
    title.Font = Enum.Font.GothamBold
    title.BackgroundTransparency = 1
    title.Parent = titleFrame
    
    autoToggles[shopKey] = CreateAutoToggle(container, false)
    
    -- Счетчик выбранных
    counters[shopKey] = CreateCounter(container)
    
    -- Кнопки "Выбрать всё / Снять всё"
    CreateSelectAllButtons(container, 
        function()  -- Выбрать всё
            for item, cb in pairs(checkboxes[shopKey]) do
                cb.Set(true)
                savedSelections[shopKey][item] = true
            end
            local count = 0
            for _, cb in pairs(checkboxes[shopKey]) do if cb.Get() then count = count + 1 end end
            counters[shopKey].Text = "📦 Выбрано: " .. count .. " из " .. #data.items
        end,
        function()  -- Снять всё
            for item, cb in pairs(checkboxes[shopKey]) do
                cb.Set(false)
                savedSelections[shopKey][item] = false
            end
            counters[shopKey].Text = "📦 Выбрано: 0 из " .. #data.items
        end
    )
    
    -- Секция предметов
    local itemsSection = CreateSection(container, "📦 Предметы для покупки:")
    
    checkboxes[shopKey] = {}
    local function updateCounter()
        local count = 0
        for _, cb in pairs(checkboxes[shopKey]) do if cb.Get() then count = count + 1 end end
        counters[shopKey].Text = "📦 Выбрано: " .. count .. " из " .. #data.items
        SaveSelections()
    end
    
    for i, itemName in ipairs(data.items) do
        local default = savedSelections[shopKey][itemName] or false
        checkboxes[shopKey][itemName] = CreateItemCheckbox(itemsSection, itemName, default, function(name, val)
            savedSelections[shopKey][name] = val
            updateCounter()
        end)
    end
    updateCounter()
    
    limitSelects[shopKey] = CreateLimitSelect(container, "∞")
    
    CreateButton(container, "💸 Купить выбранное", Color3.fromRGB(70, 130, 70), function()
        local itemsToBuy = {}
        for item, cb in pairs(checkboxes[shopKey]) do
            if cb.Get() then
                table.insert(itemsToBuy, item)
            end
        end
        BuySelectedItems(shopKey, itemsToBuy)
    end)
    
    statusLabels[shopKey] = CreateStatus(container)
    
    local function updateContainerCanvas()
        container.CanvasSize = UDim2.new(0, 0, 0, containerLayout.AbsoluteContentSize.Y + 20)
    end
    containerLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateContainerCanvas)
    task.defer(updateContainerCanvas)
    
    shopData[shopKey].container = container
end

--// === ЛЕВЫЕ КНОПКИ ===

local currentShop = nil
local tabButtons = {}

local function SwitchToShop(shopKey)
    if currentShop then
        shopData[currentShop].container.Visible = false
    end
    currentShop = shopKey
    shopData[shopKey].container.Visible = true
    
    for key, btn in pairs(tabButtons) do
        btn.BackgroundColor3 = (key == shopKey) and Color3.fromRGB(70, 130, 70) or Color3.fromRGB(48, 48, 56)
    end
    
    UpdateStatus("Выбран: " .. shopData[shopKey].name)
end

for key, data in pairs(shopData) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 50)
    btn.Text = data.name
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 15
    btn.Font = Enum.Font.Gotham
    btn.BackgroundColor3 = Color3.fromRGB(48, 48, 56)
    btn.BorderSizePixel = 0
    btn.Parent = ButtonsContainer
    
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 8)
    btnCorner.Parent = btn
    
    btn.MouseButton1Click:Connect(function()
        SwitchToShop(key)
    end)
    
    tabButtons[key] = btn
end

ButtonsLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    ButtonsContainer.CanvasSize = UDim2.new(0, 0, 0, ButtonsLayout.AbsoluteContentSize.Y + 30)
end)

SwitchToShop("Seed")

local function updateRightCanvas()
    RightScroll.CanvasSize = UDim2.new(0, 0, 0, RightLayout.AbsoluteContentSize.Y + 30)
end
RightLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateRightCanvas)
task.defer(updateRightCanvas)

--// === ЛОГИКА ПОКУПОК ===

-- Обновление баланса
local Leaderstats = LocalPlayer:FindFirstChild("leaderstats")
local Sheckles = Leaderstats and Leaderstats:FindFirstChild("Sheckles")

local function UpdateBalance()
    if Sheckles then
        local bal = Sheckles.Value
        local formatted = tostring(bal):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
        BalanceText.Text = "💰 " .. formatted .. " Sheckles"
    end
end
UpdateBalance()
if Sheckles then Sheckles.Changed:Connect(UpdateBalance) end

local function UpdateStatus(text)
    if currentShop and statusLabels[currentShop] then
        statusLabels[currentShop].Text = "📢 " .. text
    end
    print("[AutoBuy] " .. text)
end

local function BuyFromSeedShop(seedName)
    local GameEvents = ReplicatedStorage:FindFirstChild("GameEvents")
    if not GameEvents then 
        UpdateStatus("❌ GameEvents не найдены")
        return false
    end
    
    local success = pcall(function()
        GameEvents.BuySeedStock:FireServer(seedName)
    end)
    
    if success then
        UpdateStatus("✅ Куплено: " .. seedName)
        task.wait(0.5)
        UpdateBalance()
    else
        UpdateStatus("❌ Ошибка: " .. seedName)
    end
    return success
end

local function BuyFromGearShop(gearName)
    UpdateStatus("⚠️ Gear Shop: событие не найдено (нужно найти BuyGear)")
    return false
end

local function BuyFromEventShop(itemName)
    UpdateStatus("⚠️ Event Shop: событие не найдено (нужно найти BuyEventItem)")
    return false
end

local function BuySelectedItems(shopKey, items)
    if #items == 0 then
        UpdateStatus("⚠️ Ничего не выбрано")
        return
    end
    
    local buyFunction = (shopKey == "Seed" and BuyFromSeedShop) or 
                        (shopKey == "Gear" and BuyFromGearShop) or 
                        BuyFromEventShop
    
    for _, item in ipairs(items) do
        buyFunction(item)
        task.wait(0.3)
    end
    
    UpdateStatus("✅ Готово! Куплено: " .. #items .. " предметов")
end

-- Автопокупка
local function StartAutoBuy()
    while true do
        task.wait(2)
        
        for shopKey, data in pairs(shopData) do
            if autoToggles[shopKey] and autoToggles[shopKey].Get() then
                local itemsToBuy = {}
                for item, cb in pairs(checkboxes[shopKey]) do
                    if cb.Get() then
                        table.insert(itemsToBuy, item)
                    end
                end
                
                if #itemsToBuy > 0 then
                    local limit = limitSelects[shopKey].Get()
                    local buyFunction = (shopKey == "Seed" and BuyFromSeedShop) or 
                                        (shopKey == "Gear" and BuyFromGearShop) or 
                                        BuyFromEventShop
                    
                    for _, item in ipairs(itemsToBuy) do
                        if limit == "∞" then
                            buyFunction(item)
                        else
                            for i = 1, tonumber(limit) or 1 do
                                buyFunction(item)
                                task.wait(0.2)
                            end
                        end
                        task.wait(0.5)
                    end
                    UpdateBalance()
                end
            end
        end
        task.wait(3)
    end
end

--// === АНИМАЦИИ ===

local function AnimateSize(targetSize)
    TweenService:Create(MainFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = targetSize}):Play()
end

local function ToggleExpand()
    isExpanded = not isExpanded
    if isExpanded then
        ExpandBtn.Text = "▼"
        ContentContainer.Visible = true
        AnimateSize(expandedSize)
    else
        ExpandBtn.Text = "▲"
        ContentContainer.Visible = false
        AnimateSize(minimizedSize)
    end
end

local function ToggleVisibility()
    isVisible = not isVisible
    MainFrame.Visible = isVisible
end

ExpandBtn.MouseButton1Click:Connect(ToggleExpand)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == TOGGLE_KEY then ToggleVisibility() end
    if input.KeyCode == HOLD_KEY and isExpanded then ToggleExpand() end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == HOLD_KEY and not isExpanded then ToggleExpand() end
end)

-- Перетаскивание
TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        isDragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then isDragging = false end
        end)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if isDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

--// ЗАПУСК
coroutine.wrap(StartAutoBuy)()
UpdateStatus("✅ Готов! Выберите предметы и включите автопокупку")
print("========== Auto-Buy Menu ==========")
print("Seed Shop: РАБОТАЕТ (BuySeedStock)")
print("Gear Shop: нужен поиск события")
print("Event
