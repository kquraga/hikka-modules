--[[
    Auto-Buy для Grow a Garden
    Поддержка: Seed Shop, Gear Shop, Event Shop
]]

--// Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

--// Создаём GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AutoBuyGarden"
ScreenGui.Parent = PlayerGui

--// Главное окно
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 400, 0, 500)
MainFrame.Position = UDim2.new(0.5, -200, 0.5, -250)
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 10)
MainCorner.Parent = MainFrame

--// Заголовок
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 40)
TitleBar.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
TitleBar.Parent = MainFrame

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 10)
TitleCorner.Parent = TitleBar

local TitleText = Instance.new("TextLabel")
TitleText.Size = UDim2.new(1, -50, 1, 0)
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
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -40, 0, 5)
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.TextSize = 18
CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
CloseBtn.BorderSizePixel = 0
CloseBtn.Parent = TitleBar

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 6)
CloseCorner.Parent = CloseBtn

CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

--// Скролл-контейнер
local ScrollFrame = Instance.new("ScrollingFrame")
ScrollFrame.Size = UDim2.new(1, 0, 1, -40)
ScrollFrame.Position = UDim2.new(0, 0, 0, 40)
ScrollFrame.BackgroundTransparency = 1
ScrollFrame.ScrollBarThickness = 6
ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
ScrollFrame.Parent = MainFrame

local UIPadding = Instance.new("UIPadding")
UIPadding.PaddingLeft = UDim.new(0, 10)
UIPadding.PaddingRight = UDim.new(0, 10)
UIPadding.PaddingTop = UDim.new(0, 10)
UIPadding.PaddingBottom = UDim.new(0, 10)
UIPadding.Parent = ScrollFrame

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Padding = UDim.new(0, 15)
UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
UIListLayout.Parent = ScrollFrame

--// === Функции создания элементов ===

-- Секция
local function CreateSection(title)
    local Section = Instance.new("Frame")
    Section.Size = UDim2.new(0.95, 0, 0, 60)
    Section.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    Section.BorderSizePixel = 0
    Section.Parent = ScrollFrame
    
    local SectionCorner = Instance.new("UICorner")
    SectionCorner.CornerRadius = UDim.new(0, 8)
    SectionCorner.Parent = Section
    
    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Size = UDim2.new(1, 0, 0, 30)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Text = title
    TitleLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
    TitleLabel.TextSize = 16
    TitleLabel.Font = Enum.Font.GothamBold
    TitleLabel.Parent = Section
    
    return Section
end

-- Чекбокс
local function CreateCheckbox(parent, text, default, yOffset)
    local CheckboxFrame = Instance.new("Frame")
    CheckboxFrame.Size = UDim2.new(1, -20, 0, 30)
    CheckboxFrame.Position = UDim2.new(0, 10, 0, yOffset or 35)
    CheckboxFrame.BackgroundTransparency = 1
    CheckboxFrame.Parent = parent
    
    local CheckBtn = Instance.new("ImageButton")
    CheckBtn.Size = UDim2.new(0, 22, 0, 22)
    CheckBtn.Position = UDim2.new(0, 0, 0, 4)
    CheckBtn.Image = "rbxassetid://3926305904"
    CheckBtn.BackgroundTransparency = 1
    CheckBtn.Parent = CheckboxFrame
    
    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -35, 1, 0)
    Label.Position = UDim2.new(0, 30, 0, 0)
    Label.Text = text
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.TextColor3 = Color3.fromRGB(220, 220, 220)
    Label.BackgroundTransparency = 1
    Label.TextSize = 14
    Label.Parent = CheckboxFrame
    
    local checked = default
    CheckBtn.MouseButton1Click:Connect(function()
        checked = not checked
        CheckBtn.Image = checked and "rbxassetid://3926309021" or "rbxassetid://3926305904"
        if parent.Callback then parent.Callback(checked) end
    end)
    
    if default then
        checked = true
        CheckBtn.Image = "rbxassetid://3926309021"
    end
    
    return {Get = function() return checked end}
end

-- Выпадающий список (ComboBox)
local function CreateCombo(parent, label, items, default, yOffset)
    local ComboFrame = Instance.new("Frame")
    ComboFrame.Size = UDim2.new(1, -20, 0, 50)
    ComboFrame.Position = UDim2.new(0, 10, 0, yOffset or 35)
    ComboFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
    ComboFrame.BorderSizePixel = 0
    ComboFrame.Parent = parent
    
    local ComboCorner = Instance.new("UICorner")
    ComboCorner.CornerRadius = UDim.new(0, 6)
    ComboCorner.Parent = ComboFrame
    
    local LabelText = Instance.new("TextLabel")
    LabelText.Size = UDim2.new(1, -10, 0, 20)
    LabelText.Position = UDim2.new(0, 5, 0, 2)
    LabelText.Text = label
    LabelText.TextColor3 = Color3.fromRGB(180, 180, 180)
    LabelText.TextSize = 12
    LabelText.TextXAlignment = Enum.TextXAlignment.Left
    LabelText.BackgroundTransparency = 1
    LabelText.Parent = ComboFrame
    
    local Dropdown = Instance.new("TextButton")
    Dropdown.Size = UDim2.new(1, -10, 0, 25)
    Dropdown.Position = UDim2.new(0, 5, 0, 22)
    Dropdown.Text = default or items[1] or "Выбрать"
    Dropdown.TextColor3 = Color3.fromRGB(255, 255, 255)
    Dropdown.BackgroundColor3 = Color3.fromRGB(70, 70, 80)
    Dropdown.BorderSizePixel = 0
    Dropdown.Parent = ComboFrame
    
    local DropdownCorner = Instance.new("UICorner")
    DropdownCorner.CornerRadius = UDim.new(0, 4)
    DropdownCorner.Parent = Dropdown
    
    local selected = default or items[1]
    
    Dropdown.MouseButton1Click:Connect(function()
        -- Простой выбор (можно расширить до настоящего дропдауна)
        local newValue = items[(table.find(items, selected) or 0) % #items + 1]
        selected = newValue
        Dropdown.Text = selected
        if parent.OnChange then parent.OnChange(selected) end
    end)
    
    return {Get = function() return selected end}
end

-- Кнопка
local function CreateButton(parent, text, color, callback, yOffset)
    local Button = Instance.new("TextButton")
    Button.Size = UDim2.new(0.9, 0, 0, 40)
    Button.Position = UDim2.new(0.05, 0, 0, yOffset or 35)
    Button.Text = text
    Button.TextColor3 = Color3.fromRGB(255, 255, 255)
    Button.TextSize = 16
    Button.BackgroundColor3 = color or Color3.fromRGB(70, 130, 70)
    Button.BorderSizePixel = 0
    Button.Parent = parent
    
    local ButtonCorner = Instance.new("UICorner")
    ButtonCorner.CornerRadius = UDim.new(0, 8)
    ButtonCorner.Parent = Button
    
    Button.MouseButton1Click:Connect(callback)
    
    return Button
end

-- Тоггл (вкл/выкл)
local function CreateToggle(parent, text, default, yOffset)
    local ToggleFrame = Instance.new("Frame")
    ToggleFrame.Size = UDim2.new(1, -20, 0, 35)
    ToggleFrame.Position = UDim2.new(0, 10, 0, yOffset or 35)
    ToggleFrame.BackgroundColor3 = Color3.fromRGB(60, 60, 65)
    ToggleFrame.BorderSizePixel = 0
    ToggleFrame.Parent = parent
    
    local ToggleCorner = Instance.new("UICorner")
    ToggleCorner.CornerRadius = UDim.new(0, 6)
    ToggleCorner.Parent = ToggleFrame
    
    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -60, 1, 0)
    Label.Position = UDim2.new(0, 10, 0, 0)
    Label.Text = text
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.TextColor3 = Color3.fromRGB(220, 220, 220)
    Label.BackgroundTransparency = 1
    Label.TextSize = 14
    Label.Parent = ToggleFrame
    
    local ToggleBtn = Instance.new("TextButton")
    ToggleBtn.Size = UDim2.new(0, 50, 0, 25)
    ToggleBtn.Position = UDim2.new(1, -60, 0, 5)
    ToggleBtn.Text = default and "ON" or "OFF"
    ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    ToggleBtn.TextSize = 12
    ToggleBtn.BackgroundColor3 = default and Color3.fromRGB(70, 130, 70) or Color3.fromRGB(130, 70, 70)
    ToggleBtn.BorderSizePixel = 0
    ToggleBtn.Parent = ToggleFrame
    
    local ToggleCorner2 = Instance.new("UICorner")
    ToggleCorner2.CornerRadius = UDim.new(0, 4)
    ToggleCorner2.Parent = ToggleBtn
    
    local state = default or false
    
    ToggleBtn.MouseButton1Click:Connect(function()
        state = not state
        ToggleBtn.Text = state and "ON" or "OFF"
        ToggleBtn.BackgroundColor3 = state and Color3.fromRGB(70, 130, 70) or Color3.fromRGB(130, 70, 70)
        if callback then callback(state) end
    end)
    
    return {Get = function() return state end, Set = function(v) state = v end}
end

--// === РАЗДЕЛЫ МАГАЗИНОВ ===

-- 1. Обычный Seed Shop
local SeedShopSection = CreateSection("🌱 Seed Shop (Обычный)")

local AutoBuySeeds = CreateToggle(SeedShopSection, "Автопокупка семян", false)
local SeedCombo = CreateCombo(SeedShopSection, "Выберите семя", {"Blueberry", "Raspberry", "Blackberry", "Strawberry", "Cocoa", "Grape", "Pepper", "Cacao"}, "Blueberry", 80)
local BuyLimitSeed = CreateCombo(SeedShopSection, "Лимит покупки", {"1", "5", "10", "25", "50", "100", "∞"}, "∞", 135)

-- 2. Gear Shop
local GearShopSection = CreateSection("🎒 Gear Shop (Снаряжение)")

local AutoBuyGear = CreateToggle(GearShopSection, "Автопокупка снаряжения", false)
local GearCombo = CreateCombo(GearShopSection, "Выберите предмет", {"Watering Can", "Hoe", "Scythe", "Fertilizer", "Scarecrow"}, "Watering Can", 80)
local BuyLimitGear = CreateCombo(GearShopSection, "Лимит покупки", {"1", "5", "10"}, "1", 135)

-- 3. Event Shop
local EventShopSection = CreateSection("🎪 Event Shop (Ивенты)")

local AutoBuyEvent = CreateToggle(EventShopSection, "Автопокупка ивент-вещей", false)
local EventCombo = CreateCombo(EventShopSection, "Выберите предмет", {"Event Seed", "Event Tool", "Event Pet", "Cosmetic"}, "Event Seed", 80)
local BuyLimitEvent = CreateCombo(EventShopSection, "Лимит покупки", {"1", "5", "10", "25"}, "1", 135)

-- 4. Настройки автопокупки
local SettingsSection = CreateSection("⚙️ Настройки")

local BuyInterval = CreateCombo(SettingsSection, "Интервал проверки (сек)", {"0.5", "1", "2", "5", "10"}, "2", 35)
local NotifyBuy = CreateToggle(SettingsSection, "Уведомлять о покупке", true, 85)

-- Кнопка принудительной покупки
CreateButton(SettingsSection, "💸 Купить сейчас (выбранное)", Color3.fromRGB(100, 100, 200), function()
    print("Принудительная покупка...")
    -- Здесь логика покупки
end, 130)

-- Статус
local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(0.95, 0, 0, 40)
StatusLabel.Position = UDim2.new(0.025, 0, 0, 10)
StatusLabel.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
StatusLabel.Text = "Статус: Ожидание"
StatusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
StatusLabel.TextSize = 12
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.Parent = SettingsSection

local StatusCorner = Instance.new("UICorner")
StatusCorner.CornerRadius = UDim.new(0, 6)
StatusCorner.Parent = StatusLabel

--// === ЛОГИКА АВТОПОКУПКИ ===

local function UpdateStatus(text)
    StatusLabel.Text = "Статус: " .. text
    print("[AutoBuy] " .. text)
end

-- Функция покупки в обычном магазине
local function BuyFromSeedShop(seedName)
    local args = {
        [1] = seedName
    }
    -- Отправляем событие на сервер
    local success, err = pcall(function()
        game:GetService("ReplicatedStorage").GameEvents.BuySeedStock:FireServer(unpack(args))
    end)
    
    if success then
        UpdateStatus("Куплено: " .. seedName)
    else
        UpdateStatus("Ошибка покупки " .. seedName)
    end
end

-- Функция покупки в Gear Shop
local function BuyFromGearShop(gearName)
    -- Нужно узнать точное событие для Gear Shop
    -- Временная заглушка
    UpdateStatus("Попытка купить " .. gearName .. " (Gear Shop)")
    warn("Gear Shop покупка требует уточнения события")
end

-- Функция покупки в Event Shop
local function BuyFromEventShop(itemName)
    -- Нужно узнать точное событие для Event Shop
    UpdateStatus("Попытка купить " .. itemName .. " (Event Shop)")
    warn("Event Shop покупка требует уточнения события")
end

-- Основной цикл автопокупки
local function StartAutoBuy()
    local interval = tonumber(BuyInterval.Get()) or 2
    
    while true do
        wait(interval)
        
        -- Seed Shop
        if AutoBuySeeds.Get() then
            local seed = SeedCombo.Get()
            local limit = BuyLimitSeed.Get()
            
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
        if AutoBuyGear.Get() then
            local gear = GearCombo.Get()
            local limit = tonumber(BuyLimitGear.Get()) or 1
            
            for i = 1, limit do
                BuyFromGearShop(gear)
                wait(0.3)
            end
        end
        
        -- Event Shop
        if AutoBuyEvent.Get() then
            local item = EventCombo.Get()
            local limit = tonumber(BuyLimitEvent.Get()) or 1
            
            for i = 1, limit do
                BuyFromEventShop(item)
                wait(0.3)
            end
        end
    end
end

--// Запуск
coroutine.wrap(StartAutoBuy)()

UpdateStatus("Готово! Включите нужные тогглы")

-- Обновление CanvasSize
UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, UIListLayout.AbsoluteContentSize.Y + 20)
end)

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

print("Auto-Buy GUI загружен!")
