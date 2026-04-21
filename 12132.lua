--[[
    Grow a Garden - Auto-Buy Menu
    С возможностью расширения и скрытия по кнопке
]]

--// Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

--// Настройки горячих клавиш
local TOGGLE_KEY = Enum.KeyCode.RightShift  -- Кнопка для показа/скрытия (можно изменить)
local EXPAND_KEY = Enum.KeyCode.LeftControl -- Кнопка для расширения/сжатия (зажатая)

--// Переменные состояния
local isVisible = true
local isExpanded = true
local minimizedSize = UDim2.new(0, 220, 0, 50)  -- Размер свёрнутого меню
local expandedSize = UDim2.new(0, 500, 0, 600) -- Размер развёрнутого меню

-- Удаляем старый GUI если есть
local oldGui = PlayerGui:FindFirstChild("AutoBuyGarden")
if oldGui then oldGui:Destroy() end

--// Создаём GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AutoBuyGarden"
ScreenGui.Parent = PlayerGui

--// Главное окно
local MainFrame = Instance.new("Frame")
MainFrame.Size = expandedSize
MainFrame.Position = UDim2.new(0.5, -250, 0.5, -300)
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 12)
MainCorner.Parent = MainFrame

--// Заголовок (всегда видимый)
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 45)
TitleBar.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
TitleBar.Parent = MainFrame

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 12)
TitleCorner.Parent = TitleBar

local TitleText = Instance.new("TextLabel")
TitleText.Size = UDim2.new(1, -100, 1, 0)
TitleText.Position = UDim2.new(0, 15, 0, 0)
TitleText.BackgroundTransparency = 1
TitleText.Text = "🌱 Auto-Buy | Grow a Garden"
TitleText.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleText.TextSize = 18
TitleText.TextXAlignment = Enum.TextXAlignment.Left
TitleText.Font = Enum.Font.GothamBold
TitleText.Parent = TitleBar

--// Кнопка закрытия
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 35, 0, 35)
CloseBtn.Position = UDim2.new(1, -90, 0, 5)
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
    ScreenGui:Destroy()
end)

--// Кнопка сворачивания/разворачивания
local ExpandBtn = Instance.new("TextButton")
ExpandBtn.Size = UDim2.new(0, 35, 0, 35)
ExpandBtn.Position = UDim2.new(1, -45, 0, 5)
ExpandBtn.Text = "▼"
ExpandBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ExpandBtn.TextSize = 20
ExpandBtn.BackgroundColor3 = Color3.fromRGB(70, 130, 70)
ExpandBtn.BorderSizePixel = 0
ExpandBtn.Parent = TitleBar

local ExpandCorner = Instance.new("UICorner")
ExpandCorner.CornerRadius = UDim.new(0, 8)
ExpandCorner.Parent = ExpandBtn

--// Контейнер для всего содержимого (будет скрываться при сворачивании)
local ContentContainer = Instance.new("Frame")
ContentContainer.Size = UDim2.new(1, 0, 1, -45)
ContentContainer.Position = UDim2.new(0, 0, 0, 45)
ContentContainer.BackgroundTransparency = 1
ContentContainer.Parent = MainFrame

--// ЛЕВАЯ ПАНЕЛЬ С КНОПКАМИ
local LeftPanel = Instance.new("Frame")
LeftPanel.Size = UDim2.new(0, 180, 1, 0)
LeftPanel.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
LeftPanel.BorderSizePixel = 0
LeftPanel.Parent = ContentContainer

local LeftPanelCorner = Instance.new("UICorner")
LeftPanelCorner.CornerRadius = UDim.new(0, 0)
LeftPanelCorner.Parent = LeftPanel

-- Контейнер для кнопок
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
RightPanel.BackgroundColor3 = Color3.fromRGB(40, 40, 48)
RightPanel.BorderSizePixel = 0
RightPanel.Parent = ContentContainer

local RightCorner = Instance.new("UICorner")
RightCorner.CornerRadius = UDim.new(0, 10)
RightCorner.Parent = RightPanel

-- Скролл для правой панели
local RightScroll = Instance.new("ScrollingFrame")
RightScroll.Size = UDim2.new(1, 0, 1, 0)
RightScroll.BackgroundTransparency = 1
RightScroll.ScrollBarThickness = 6
RightScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
RightScroll.Parent = RightPanel

local RightLayout = Instance.new("UIListLayout")
RightLayout.Padding = UDim.new(0, 15)
RightLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
RightLayout.Parent = RightScroll

local RightPadding = Instance.new("UIPadding")
RightPadding.PaddingLeft = UDim.new(0, 15)
RightPadding.PaddingRight = UDim.new(0, 15)
RightPadding.PaddingTop = UDim.new(0, 15)
RightPadding.PaddingBottom = UDim.new(0, 15)
RightPadding.Parent = RightScroll

--// === ФУНКЦИИ СОЗДАНИЯ ЭЛЕМЕНТОВ ===

local function CreateSection(parent, title)
    local Section = Instance.new("Frame")
    Section.Size = UDim2.new(1, 0, 0, 0)
    Section.BackgroundColor3 = Color3.fromRGB(50, 50, 58)
    Section.BorderSizePixel = 0
    Section.AutomaticSize = Enum.AutomaticSize.Y
    Section.Parent = parent
    
    local SectionCorner = Instance.new("UICorner")
    SectionCorner.CornerRadius = UDim.new(0, 8)
    SectionCorner.Parent = Section
    
    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Size = UDim2.new(1, 0, 0, 35)
    TitleLabel.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
    TitleLabel.Text = title
    TitleLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
    TitleLabel.TextSize = 16
    TitleLabel.Font = Enum.Font.GothamBold
    TitleLabel.Parent = Section
    
    local TitleCorner = Instance.new("UICorner")
    TitleCorner.CornerRadius = UDim.new(0, 8)
    TitleCorner.Parent = TitleLabel
    
    local ContentFrame = Instance.new("Frame")
    ContentFrame.Size = UDim2.new(1, 0, 0, 0)
    ContentFrame.Position = UDim2.new(0, 0, 0, 35)
    ContentFrame.BackgroundTransparency = 1
    ContentFrame.AutomaticSize = Enum.AutomaticSize.Y
    ContentFrame.Parent = Section
    
    return ContentFrame
end

local function CreateToggle(parent, text, default, callback)
    local ToggleFrame = Instance.new("Frame")
    ToggleFrame.Size = UDim2.new(1, 0, 0, 40)
    ToggleFrame.BackgroundColor3 = Color3.fromRGB(55, 55, 63)
    ToggleFrame.BorderSizePixel = 0
    ToggleFrame.Parent = parent
    
    local ToggleCorner = Instance.new("UICorner")
    ToggleCorner.CornerRadius = UDim.new(0, 6)
    ToggleCorner.Parent = ToggleFrame
    
    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -80, 1, 0)
    Label.Position = UDim2.new(0, 15, 0, 0)
    Label.Text = text
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.TextColor3 = Color3.fromRGB(220, 220, 220)
    Label.BackgroundTransparency = 1
    Label.TextSize = 14
    Label.Font = Enum.Font.Gotham
    Label.Parent = ToggleFrame
    
    local ToggleBtn = Instance.new("TextButton")
    ToggleBtn.Size = UDim2.new(0, 60, 0, 30)
    ToggleBtn.Position = UDim2.new(1, -75, 0, 5)
    ToggleBtn.Text = default and "ON" or "OFF"
    ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    ToggleBtn.TextSize = 13
    ToggleBtn.BackgroundColor3 = default and Color3.fromRGB(70, 130, 70) or Color3.fromRGB(160, 70, 70)
    ToggleBtn.BorderSizePixel = 0
    ToggleBtn.Parent = ToggleFrame
    
    local ToggleCorner2 = Instance.new("UICorner")
    ToggleCorner2.CornerRadius = UDim.new(0, 6)
    ToggleCorner2.Parent = ToggleBtn
    
    local state = default or false
    
    ToggleBtn.MouseButton1Click:Connect(function()
        state = not state
        ToggleBtn.Text = state and "ON" or "OFF"
        ToggleBtn.BackgroundColor3 = state and Color3.fromRGB(70, 130, 70) or Color3.fromRGB(160, 70, 70)
        if callback then callback(state) end
    end)
    
    return {Get = function() return state end}
end

local function CreateOptionButtons(parent, label, items, default, onSelect)
    local Container = Instance.new("Frame")
    Container.Size = UDim2.new(1, 0, 0, 0)
    Container.BackgroundTransparency = 1
    Container.AutomaticSize = Enum.AutomaticSize.Y
    Container.Parent = parent
    
    local LabelText = Instance.new("TextLabel")
    LabelText.Size = UDim2.new(1, 0, 0, 25)
    LabelText.BackgroundTransparency = 1
    LabelText.Text = label
    LabelText.TextColor3 = Color3.fromRGB(180, 180, 200)
    LabelText.TextSize = 13
    LabelText.TextXAlignment = Enum.TextXAlignment.Left
    LabelText.Font = Enum.Font.Gotham
    LabelText.Parent = Container
    
    local ButtonsFrame = Instance.new("Frame")
    ButtonsFrame.Size = UDim2.new(1, 0, 0, 0)
    ButtonsFrame.BackgroundTransparency = 1
    ButtonsFrame.AutomaticSize = Enum.AutomaticSize.Y
    ButtonsFrame.Parent = Container
    
    local FlowLayout = Instance.new("UIListLayout")
    FlowLayout.FillDirection = Enum.FillDirection.Horizontal
    FlowLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    FlowLayout.Padding = UDim.new(0, 8)
    FlowLayout.Parent = ButtonsFrame
    
    local selected = default or items[1]
    local buttons = {}
    
    for _, item in ipairs(items) do
        local Btn = Instance.new("TextButton")
        Btn.Size = UDim2.new(0, 90, 0, 32)
        Btn.Text = item
        Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        Btn.TextSize = 13
        Btn.BackgroundColor3 = (item == selected) and Color3.fromRGB(70, 130, 70) or Color3.fromRGB(60, 60, 70)
        Btn.BorderSizePixel = 0
        Btn.Parent = ButtonsFrame
        
        local BtnCorner = Instance.new("UICorner")
        BtnCorner.CornerRadius = UDim.new(0, 6)
        BtnCorner.Parent = Btn
        
        Btn.MouseButton1Click:Connect(function()
            selected = item
            for _, btn in pairs(buttons) do
                btn.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
            end
            Btn.BackgroundColor3 = Color3.fromRGB(70, 130, 70)
            if onSelect then onSelect(item) end
        end)
        
        table.insert(buttons, Btn)
    end
    
    return {Get = function() return selected end}
end

local function CreateButton(parent, text, color, callback)
    local Button = Instance.new("TextButton")
    Button.Size = UDim2.new(1, -20, 0, 42)
    Button.Position = UDim2.new(0, 10, 0, 5)
    Button.Text = text
    Button.TextColor3 = Color3.fromRGB(255, 255, 255)
    Button.TextSize = 15
    Button.BackgroundColor3 = color or Color3.fromRGB(70, 130, 70)
    Button.BorderSizePixel = 0
    Button.Parent = parent
    
    local ButtonCorner = Instance.new("UICorner")
    ButtonCorner.CornerRadius = UDim.new(0, 8)
    ButtonCorner.Parent = Button
    
    Button.MouseButton1Click:Connect(callback)
    
    return Button
end

local function CreateStatus(parent)
    local Status = Instance.new("TextLabel")
    Status.Size = UDim2.new(1, -20, 0, 38)
    Status.Position = UDim2.new(0, 10, 0, 5)
    Status.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
    Status.Text = "Статус: Готов"
    Status.TextColor3 = Color3.fromRGB(200, 200, 200)
    Status.TextSize = 12
    Status.Font = Enum.Font.Gotham
    Status.Parent = parent
    
    local StatusCorner = Instance.new("UICorner")
    StatusCorner.CornerRadius = UDim.new(0, 6)
    StatusCorner.Parent = Status
    
    return Status
end

--// === СОЗДАНИЕ РАЗДЕЛОВ ===

-- Данные для разделов
local sections = {}
local currentSection = nil
local tabButtons = {}

-- 1. Seed Shop
sections.Seed = {name = "🌱 Seed Shop", content = CreateSection(RightScroll, "🌱 Магазин семян")}
sections.Seed.toggles = {auto = CreateToggle(sections.Seed.content, "Автопокупка семян", false)}
sections.Seed.selects = {
    seed = CreateOptionButtons(sections.Seed.content, "Выберите семя", {"Blueberry", "Raspberry", "Blackberry", "Strawberry", "Cocoa", "Grape", "Pepper", "Cacao"}, "Blueberry"),
    limit = CreateOptionButtons(sections.Seed.content, "Лимит покупки", {"1", "5", "10", "25", "50", "100", "∞"}, "∞")
}
CreateButton(sections.Seed.content, "🌱 Купить сейчас", Color3.fromRGB(70, 130, 70), function()
    UpdateStatus("Покупка: " .. sections.Seed.selects.seed.Get())
    BuyFromSeedShop(sections.Seed.selects.seed.Get())
end)

-- 2. Gear Shop
sections.Gear = {name = "🎒 Gear Shop", content = CreateSection(RightScroll, "🎒 Магазин снаряжения")}
sections.Gear.toggles = {auto = CreateToggle(sections.Gear.content, "Автопокупка снаряжения", false)}
sections.Gear.selects = {
    item = CreateOptionButtons(sections.Gear.content, "Выберите предмет", {"Watering Can", "Hoe", "Scythe", "Fertilizer", "Scarecrow", "Sprinkler"}, "Watering Can"),
    limit = CreateOptionButtons(sections.Gear.content, "Лимит покупки", {"1", "5", "10"}, "1")
}
CreateButton(sections.Gear.content, "🎒 Купить сейчас", Color3.fromRGB(100, 100, 200), function()
    UpdateStatus("Покупка: " .. sections.Gear.selects.item.Get())
    BuyFromGearShop(sections.Gear.selects.item.Get())
end)

-- 3. Event Shop
sections.Event = {name = "🎪 Event Shop", content = CreateSection(RightScroll, "🎪 Ивент-магазин")}
sections.Event.toggles = {auto = CreateToggle(sections.Event.content, "Автопокупка ивент-вещей", false)}
sections.Event.selects = {
    item = CreateOptionButtons(sections.Event.content, "Выберите предмет", {"Event Seed", "Event Tool", "Event Pet", "Cosmetic"}, "Event Seed"),
    limit = CreateOptionButtons(sections.Event.content, "Лимит покупки", {"1", "5", "10", "25"}, "1")
}
CreateButton(sections.Event.content, "🎪 Купить сейчас", Color3.fromRGB(200, 130, 70), function()
    UpdateStatus("Покупка: " .. sections.Event.selects.item.Get())
    BuyFromEventShop(sections.Event.selects.item.Get())
end)

-- 4. Настройки
sections.Settings = {name = "⚙️ Настройки", content = CreateSection(RightScroll, "⚙️ Настройки")}
sections.Settings.selects = {
    interval = CreateOptionButtons(sections.Settings.content, "Интервал проверки (сек)", {"0.5", "1", "2", "3", "5", "10"}, "2")
}
sections.Settings.toggles = {notify = CreateToggle(sections.Settings.content, "Уведомлять о покупке", true)}
sections.Settings.status = CreateStatus(sections.Settings.content)

-- Обновление CanvasSize
local function updateCanvas()
    RightScroll.CanvasSize = UDim2.new(0, 0, 0, RightLayout.AbsoluteContentSize.Y + 30)
end
RightLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateCanvas)
task.defer(updateCanvas)

--// === ФУНКЦИИ ДЛЯ РАСШИРЕНИЯ/СВОРАЧИВАНИЯ ===

local function AnimateSize(targetSize)
    local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local tween = TweenService:Create(MainFrame, tweenInfo, {Size = targetSize})
    tween:Play()
    return tween
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

-- Кнопка сворачивания
ExpandBtn.MouseButton1Click:Connect(ToggleExpand)

--// === СОЗДАНИЕ ЛЕВЫХ КНОПОК (ТАБОВ) ===

local function SwitchToSection(sectionKey)
    if currentSection then
        currentSection.Visible = false
    end
    currentSection = sections[sectionKey].content
    currentSection.Visible = true
    
    for key, btn in pairs(tabButtons) do
        btn.BackgroundColor3 = (key == sectionKey) and Color3.fromRGB(70, 130, 70) or Color3.fromRGB(50, 50, 60)
    end
    
    UpdateStatus("Раздел: " .. sections[sectionKey].name)
    updateCanvas()
end

-- Создание кнопок-табов
local tabOrder = {"Seed", "Gear", "Event", "Settings"}
for _, key in ipairs(tabOrder) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 48)
    btn.Text = sections[key].name
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 14
    btn.Font = Enum.Font.Gotham
    btn.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    btn.BorderSizePixel = 0
    btn.Parent = ButtonsContainer
    
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 8)
    btnCorner.Parent = btn
    
    btn.MouseButton1Click:Connect(function()
        SwitchToSection(key)
    end)
    
    tabButtons[key] = btn
    
    -- Скрыть контент сначала
    sections[key].content.Visible = false
end

-- Обновление высоты контейнера кнопок
ButtonsLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    ButtonsContainer.CanvasSize = UDim2.new(0, 0, 0, ButtonsLayout.AbsoluteContentSize.Y + 30)
end)

-- Активация первого раздела
SwitchToSection("Seed")

--// === ЛОГИКА АВТОПОКУПКИ ===

local function UpdateStatus(text)
    if sections.Settings and sections.Settings.status then
        sections.Settings.status.Text = "Статус: " .. text
    end
    print("[AutoBuy] " .. text)
end

local function BuyFromSeedShop(seedName)
    local success = pcall(function()
        game:GetService("ReplicatedStorage").GameEvents.BuySeedStock:FireServer(seedName)
    end)
    if success then
        UpdateStatus("Куплено: " .. seedName)
        if sections.Settings.toggles.notify.Get() then
            game:GetService("StarterGui"):SetCore("SendNotification", {
                Title = "Auto-Buy",
                Text = "Куплено: " .. seedName,
                Duration = 2
            })
        end
    else
        UpdateStatus("Ошибка: " .. seedName)
    end
end

local function BuyFromGearShop(gearName)
    UpdateStatus("Покупка " .. gearName .. " (Gear Shop)")
    -- Замените на реальное событие
end

local function BuyFromEventShop(itemName)
    UpdateStatus("Покупка " .. itemName .. " (Event Shop)")
    -- Замените на реальное событие
end

-- Основной цикл
local function StartAutoBuy()
    while true do
        local interval = tonumber(sections.Settings.selects.interval.Get()) or 2
        wait(interval)
        
        if not isExpanded then wait(1) end
        
        -- Seed Shop
        if sections.Seed.toggles.auto.Get() then
            local seed = sections.Seed.selects.seed.Get()
            local limit = sections.Seed.selects.limit.Get()
            if limit == "∞" then
                BuyFromSeedShop(seed)
            else
                for i = 1, tonumber(limit) or 1 do
                    BuyFromSeedShop(seed)
                    wait(0.3)
                end
            end
        end
        
        -- Gear Shop
        if sections.Gear.toggles.auto.Get() then
            local item = sections.Gear.selects.item.Get()
            local limit = tonumber(sections.Gear.selects.limit.Get()) or 1
            for i = 1, limit do
                BuyFromGearShop(item)
                wait(0.3)
            end
        end
        
        -- Event Shop
        if sections.Event.toggles.auto.Get() then
            local item = sections.Event.selects.item.Get()
            local limit = tonumber(sections.Event.selects.limit.Get()) or 1
            for i = 1, limit do
                BuyFromEventShop(item)
                wait(0.3)
            end
        end
    end
end

--// === ГОРЯЧИЕ КЛАВИШИ ===

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    -- Скрытие/показ по нажатию (например, RightShift)
    if input.KeyCode == TOGGLE_KEY then
        ToggleVisibility()
    end
    
    -- Расширение/сжатие при зажатии (например, Ctrl)
    if input.KeyCode == EXPAND_KEY then
        if not isExpanded then
            ToggleExpand()
        end
    end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == EXPAND_KEY then
        if isExpanded then
            ToggleExpand()
        end
    end
end)

--// Запуск
coroutine.wrap(StartAutoBuy)()

-- Перетаскивание окна
local dragging = false
local dragStart, startPos

TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

TitleBar.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

UpdateStatus("Готово! RightShift - скрыть, Ctrl (зажать) - свернуть")
print("Auto-Buy GUI с управлением загружен!")
