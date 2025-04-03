-- Загружаем MacLib
local MacLib = loadstring(game:HttpGet("https://github.com/biggaboy212/Maclib/releases/latest/download/maclib.txt"))()

-- Создаём окно
local Window = MacLib:Window({
    Title = "Zombie ESP",
    Subtitle = "by Grok",
    Size = UDim2.fromOffset(868, 650),
    DragStyle = 1,
    DisabledWindowControls = {},
    ShowUserInfo = true,
    Keybind = Enum.KeyCode.RightControl,
    AcrylicBlur = true,
})

-- Создаём группу вкладок
local tabGroups = {
    TabGroup1 = Window:TabGroup()
}

-- Создаём вкладки
local tabs = {
    Visual = tabGroups.TabGroup1:Tab({ Name = "Visual", Image = "rbxassetid://6034281935" }),
    Combat = tabGroups.TabGroup1:Tab({ Name = "Combat", Image = "rbxassetid://6034509993" }),
    GameSettings = tabGroups.TabGroup1:Tab({ Name = "Game Settings", Image = "rbxassetid://6034509993" })
}

-- Создаём секции
local sections = {
    -- Visual
    ESPSettings = tabs.Visual:Section({ Side = "Left" }),
    -- Combat
    AimAssist = tabs.Combat:Section({ Side = "Left" }),
    SilentAim = tabs.Combat:Section({ Side = "Right" }),
    WeaponMods = tabs.Combat:Section({ Side = "Left" }),
    -- Game Settings
    GameMods = tabs.GameSettings:Section({ Side = "Left" })
}

-- Логирование всех RemoteEvent в ReplicatedStorage.Remotes (без хука)
local RemoteEvent = game:GetService("ReplicatedStorage"):FindFirstChild("RemoteEvent")
if RemoteEvent then
    RemoteEvent.OnClientEvent:Connect(function(...)
        print("RemoteEvent вызван (OnClientEvent): " .. RemoteEvent:GetFullName(), "Аргументы:", ...)
    end)
end

-- Временное отключение хука FireServer
-- Мы заменим его на прямое логирование через подключение к RemoteEvent, если это возможно
-- Для этого нам нужно найти, где игра вызывает FireServer, но пока просто убираем хук

-- Логирование содержимого Tool и WeaponStats
local Player = game.Players.LocalPlayer
local Character = Player.Character
if Character then
    local Tool = Character:FindFirstChildOfClass("Tool")
    if Tool then
        print("Содержимое Tool:")
        for _, child in pairs(Tool:GetChildren()) do
            print(child.Name, child.ClassName)
            if child:IsA("RemoteEvent") then
                print("Найден RemoteEvent в Tool:", child.Name)
            end
        end
        local SPH_Weapon = Tool:FindFirstChild("SPH_Weapon")
        if SPH_Weapon then
            print("Содержимое SPH_Weapon:")
            for _, child in pairs(SPH_Weapon:GetChildren()) do
                print(child.Name, child.ClassName)
                if child:IsA("RemoteEvent") then
                    print("Найден RemoteEvent в SPH_Weapon:", child.Name)
                end
            end
            local WeaponStats = SPH_Weapon:FindFirstChild("WeaponStats")
            if WeaponStats then
                local success, weaponStatsTable = pcall(function()
                    return require(WeaponStats)
                end)
                if success then
                    print("Содержимое WeaponStats:")
                    for key, value in pairs(weaponStatsTable) do
                        print(key, value)
                    end
                else
                    warn("Не удалось загрузить WeaponStats: " .. tostring(weaponStatsTable))
                end
            end
        end
    end
end

-- Вкладка Visual
sections.ESPSettings:Header({ Name = "ESP Settings" })

local ESPEnabled = false
local BoxEnabled = false
local NameEnabled = false
local DistanceEnabled = false
local HealthEnabled = false
local ESPObjects = {}
local ESPConnection

local function AddESP(Zombie)
    if ESPObjects[Zombie] then return end
    if not Zombie.Parent == workspace.Zombies then
        print("Зомби " .. Zombie.Name .. " не находится в Workspace.Zombies, пропущен")
        return
    end

    if not Zombie:FindFirstChild("HumanoidRootPart") then
        warn("Зомби " .. Zombie.Name .. " в Workspace.Zombies не имеет HumanoidRootPart!")
        return
    end

    local Box = Drawing.new("Square")
    Box.Visible = false
    Box.Color = Color3.fromRGB(255, 0, 0)
    Box.Thickness = 2
    Box.Filled = false

    local NameText = Drawing.new("Text")
    NameText.Visible = false
    NameText.Size = 16
    NameText.Color = Color3.fromRGB(255, 255, 255)
    NameText.Text = Zombie.Name
    NameText.Center = true

    local DistanceText = Drawing.new("Text")
    DistanceText.Visible = false
    DistanceText.Size = 16
    DistanceText.Color = Color3.fromRGB(255, 255, 255)
    DistanceText.Center = true

    local HPText = Drawing.new("Text")
    HPText.Visible = false
    HPText.Size = 16
    HPText.Color = Color3.fromRGB(255, 255, 255)
    HPText.Center = true

    ESPObjects[Zombie] = {Box = Box, NameText = NameText, DistanceText = DistanceText, HPText = HPText}
    print("Добавлен ESP для зомби: " .. Zombie.Name)
end

local function UpdateESP()
    for Zombie, Data in pairs(ESPObjects) do
        if ESPEnabled and Zombie and Zombie.Parent == workspace.Zombies and Zombie:FindFirstChild("HumanoidRootPart") then
            local HRP = Zombie.HumanoidRootPart
            local Vector, OnScreen = workspace.CurrentCamera:WorldToViewportPoint(HRP.Position)
            local Player = game.Players.LocalPlayer
            local Character = Player.Character
            local Humanoid = Zombie:FindFirstChild("Humanoid")

            if Character and Character:FindFirstChild("HumanoidRootPart") then
                local Distance = (Character.HumanoidRootPart.Position - HRP.Position).Magnitude

                if BoxEnabled then
                    Data.Box.Size = Vector2.new(2000 / Vector.Z, 3000 / Vector.Z)
                    Data.Box.Position = Vector2.new(Vector.X - Data.Box.Size.X / 2, Vector.Y - Data.Box.Size.Y / 2)
                    Data.Box.Visible = OnScreen
                    Data.Box.Color = Color3.fromRGB(255, 0, 0)
                else
                    Data.Box.Visible = false
                end

                if NameEnabled then
                    Data.NameText.Position = Vector2.new(Vector.X, Vector.Y - Data.Box.Size.Y / 2 - 30)
                    Data.NameText.Text = Zombie.Name
                    Data.NameText.Visible = OnScreen
                    Data.NameText.Color = Color3.fromRGB(255, 255, 255)
                else
                    Data.NameText.Visible = false
                end

                if DistanceEnabled then
                    Data.DistanceText.Position = Vector2.new(Vector.X, Vector.Y + Data.Box.Size.Y / 2 + 15)
                    Data.DistanceText.Text = "Dist: " .. math.floor(Distance) .. " studs"
                    Data.DistanceText.Visible = OnScreen
                    Data.DistanceText.Color = Color3.fromRGB(255, 255, 255)
                else
                    Data.DistanceText.Visible = false
                end

                if HealthEnabled and Humanoid then
                    Data.HPText.Position = Vector2.new(Vector.X, Vector.Y + Data.Box.Size.Y / 2 + 30)
                    Data.HPText.Text = "HP: " .. math.floor(Humanoid.Health) .. "/" .. Humanoid.MaxHealth
                    Data.HPText.Visible = OnScreen
                    Data.HPText.Color = Color3.fromRGB(255, 255, 255)
                else
                    Data.HPText.Visible = false
                    if not Humanoid then
                        print("Зомби " .. Zombie.Name .. " не имеет Humanoid, HP не отображается")
                    end
                end
            else
                Data.Box.Visible = false
                Data.NameText.Visible = false
                Data.DistanceText.Visible = false
                Data.HPText.Visible = false
            end
        else
            Data.Box.Visible = false
            Data.NameText.Visible = false
            Data.DistanceText.Visible = false
            Data.HPText.Visible = false
            if Zombie and Zombie.Parent then
                print("ESP не отображается для зомби " .. Zombie.Name .. ": не в Workspace.Zombies или нет HumanoidRootPart")
            end
        end
    end
end

local function CheckZombies()
    if not workspace:FindFirstChild("Zombies") then
        warn("Папка Workspace.Zombies не найдена!")
        return
    end
    for _, Zombie in pairs(workspace.Zombies:GetChildren()) do
        if not ESPObjects[Zombie] then
            AddESP(Zombie)
        end
    end
end

sections.ESPSettings:Toggle({
    Name = "Enable ESP",
    Default = false,
    Callback = function(Value)
        ESPEnabled = Value
        if ESPEnabled then
            CheckZombies()
            if not ESPConnection then
                ESPConnection = game:GetService("RunService").RenderStepped:Connect(function()
                    CheckZombies()
                    UpdateESP()
                end)
            end
            Window:Notify({
                Title = "Zombie ESP",
                Description = "ESP включён",
                Lifetime = 5
            })
        else
            if ESPConnection then
                ESPConnection:Disconnect()
                ESPConnection = nil
            end
            for _, Data in pairs(ESPObjects) do
                Data.Box.Visible = false
                Data.NameText.Visible = false
                Data.DistanceText.Visible = false
                Data.HPText.Visible = false
                Data.Box:Remove()
                Data.NameText:Remove()
                Data.DistanceText:Remove()
                Data.HPText:Remove()
            end
            ESPObjects = {}
            Window:Notify({
                Title = "Zombie ESP",
                Description = "ESP выключён",
                Lifetime = 5
            })
        end
    end
}, "ZombieESP")

sections.ESPSettings:Toggle({
    Name = "Box ESP",
    Default = false,
    Callback = function(Value)
        BoxEnabled = Value
        Window:Notify({
            Title = "Zombie ESP",
            Description = "Box ESP " .. (Value and "включён" or "выключён"),
            Lifetime = 5
        })
    end
}, "BoxESP")

sections.ESPSettings:Toggle({
    Name = "Name ESP",
    Default = false,
    Callback = function(Value)
        NameEnabled = Value
        Window:Notify({
            Title = "Zombie ESP",
            Description = "Name ESP " .. (Value and "включён" or "выключён"),
            Lifetime = 5
        })
    end
}, "NameESP")

sections.ESPSettings:Toggle({
    Name = "Distance ESP",
    Default = false,
    Callback = function(Value)
        DistanceEnabled = Value
        Window:Notify({
            Title = "Zombie ESP",
            Description = "Distance ESP " .. (Value and "включён" or "выключён"),
            Lifetime = 5
        })
    end
}, "DistanceESP")

sections.ESPSettings:Toggle({
    Name = "Health ESP",
    Default = false,
    Callback = function(Value)
        HealthEnabled = Value
        Window:Notify({
            Title = "Zombie ESP",
            Description = "Health ESP " .. (Value and "включён" or "выключён"),
            Lifetime = 5
        })
    end
}, "HealthESP")

workspace.Zombies.ChildRemoved:Connect(function(Zombie)
    if ESPObjects[Zombie] then
        ESPObjects[Zombie].Box:Remove()
        ESPObjects[Zombie].NameText:Remove()
        ESPObjects[Zombie].DistanceText:Remove()
        ESPObjects[Zombie].HPText:Remove()
        ESPObjects[Zombie] = nil
        print("Удалён ESP для зомби: " .. Zombie.Name)
    end
end)

-- Вкладка Combat
sections.AimAssist:Header({ Name = "Aim Assist" })
sections.SilentAim:Header({ Name = "Silent Aim" })
sections.WeaponMods:Header({ Name = "Weapon Mods" })

-- Общие функции для Combat
local AimRadius = 100
local SilentAimRadius = 100
local AimSmoothness = 10

local function IsVisible(PlayerPos, TargetPos, IgnoreList)
    local RaycastParams = RaycastParams.new()
    RaycastParams.FilterDescendantsInstances = IgnoreList
    RaycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    RaycastParams.IgnoreWater = true
    local RaycastResult = workspace:Raycast(PlayerPos, (TargetPos - PlayerPos), RaycastParams)
    if RaycastResult then
        local HitPart = RaycastResult.Instance
        if HitPart and HitPart.CanCollide then
            print("Wall Check: Препятствие обнаружено - " .. tostring(HitPart) .. " на расстоянии " .. math.floor((PlayerPos - RaycastResult.Position).Magnitude) .. " studs")
            return false
        end
    end
    print("Wall Check: Зомби виден на расстоянии " .. math.floor((PlayerPos - TargetPos).Magnitude) .. " studs")
    return true
end

local function GetZombieHeadUnderCursor()
    local Player = game.Players.LocalPlayer
    local Mouse = Player:GetMouse()
    local Camera = workspace.CurrentCamera
    local UnitRay = Camera:ScreenPointToRay(Mouse.X, Mouse.Y)
    local RaycastParams = RaycastParams.new()
    RaycastParams.FilterDescendantsInstances = {Player.Character}
    RaycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    local RaycastResult = workspace:Raycast(UnitRay.Origin, UnitRay.Direction * 1000, RaycastParams)
    
    if RaycastResult and RaycastResult.Instance then
        local HitPart = RaycastResult.Instance
        if HitPart.Name == "Head" then
            local Zombie = HitPart.Parent
            if Zombie and Zombie.Parent == workspace.Zombies then
                print("Trigger Bot (Aim): Обнаружен зомби под курсором: " .. Zombie.Name)
                return Zombie
            end
        end
    end
    return nil
end

local function GetClosestZombieForTriggerBot()
    local Player = game.Players.LocalPlayer
    local Character = Player.Character
    if not Character or not Character:FindFirstChild("HumanoidRootPart") then return nil end
    
    local ClosestZombie = nil
    local MinDistance = math.huge

    for _, Zombie in pairs(workspace.Zombies:GetChildren()) do
        local Head = Zombie:FindFirstChild("Head")
        local HRP = Zombie:FindFirstChild("HumanoidRootPart")
        if Head and HRP then
            local Distance = (Character.HumanoidRootPart.Position - HRP.Position).Magnitude
            if Distance <= SilentAimRadius and Distance < MinDistance then
                local IsZombieVisible = true
                if SilentAimWallCheckEnabled then
                    IsZombieVisible = IsVisible(Character.HumanoidRootPart.Position, Head.Position, {Character, Zombie})
                    if not IsZombieVisible then
                        print("Silent Aim TriggerBot: Зомби " .. Zombie.Name .. " за стеной, выстрел отменён")
                        continue
                    end
                end
                MinDistance = Distance
                ClosestZombie = Zombie
                print("Silent Aim TriggerBot: Выбран зомби: " .. Zombie.Name .. " (Distance: " .. math.floor(Distance) .. ")")
            end
        end
    end
    return ClosestZombie
end

local function FindFireRemote()
    local FireRemote = game:GetService("ReplicatedStorage"):FindFirstChild("RemoteEvent")
    if FireRemote then
        print("Найден RemoteEvent: ReplicatedStorage.RemoteEvent")
        return FireRemote
    end
    warn("Не удалось найти ReplicatedStorage.RemoteEvent!")
    return nil
end

-- Aim Assist
local AimEnabled = false
local AimWallCheckEnabled = false
local AimTriggerBotEnabled = false
local AimConnection
local AimTriggerBotConnection

local function GetClosestZombie()
    local Player = game.Players.LocalPlayer
    local Character = Player.Character
    if not Character or not Character:FindFirstChild("HumanoidRootPart") then return nil end
    
    local ClosestZombie = nil
    local MinValue = math.huge
    local Method = "Distance"

    for _, Zombie in pairs(workspace.Zombies:GetChildren()) do
        local Head = Zombie:FindFirstChild("Head")
        local HRP = Zombie:FindFirstChild("HumanoidRootPart")
        if Head and HRP then
            local Distance = (Character.HumanoidRootPart.Position - HRP.Position).Magnitude
            if Distance <= AimRadius then
                local IsZombieVisible = true
                if AimWallCheckEnabled then
                    IsZombieVisible = IsVisible(Character.HumanoidRootPart.Position, Head.Position, {Character, Zombie})
                    if not IsZombieVisible then
                        print("Aim: Зомби " .. Zombie.Name .. " за стеной, пропущен (Wall Check включён)")
                        continue
                    end
                end

                local Value
                if Method == "Distance" then
                    Value = Distance
                elseif Method == "HP" then
                    local Humanoid = Zombie:FindFirstChild("Humanoid")
                    Value = Humanoid and Humanoid.Health or math.huge
                elseif Method == "Random" then
                    Value = math.random()
                end
                if Value and Value < MinValue then
                    MinValue = Value
                    ClosestZombie = Zombie
                    print("Aim: Выбран зомби: " .. Zombie.Name .. " (Distance: " .. math.floor(Distance) .. ")")
                end
            end
        end
    end
    return ClosestZombie
end

local function AimAtTarget()
    if not AimEnabled then return end
    local Zombie = GetClosestZombie()
    if Zombie and Zombie:FindFirstChild("Head") then
        local Camera = workspace.CurrentCamera
        local HeadPos = Zombie.Head.Position
        local CurrentCFrame = Camera.CFrame
        local TargetCFrame = CFrame.new(CurrentCFrame.Position, HeadPos)
        Camera.CFrame = CurrentCFrame:Lerp(TargetCFrame, 1 / AimSmoothness)
        print("Aim: Наводится на голову зомби: " .. Zombie.Name)
    else
        print("Aim: Не найден подходящий зомби для наведения")
    end
end

local function SetupAimTriggerBot()
    if not AimTriggerBotEnabled then return end
    local Player = game.Players.LocalPlayer
    local Character = Player.Character
    if not Character then return end

    local FireRemote = FindFireRemote()
    if not FireRemote then
        warn("Aim TriggerBot: Не найден RemoteEvent для стрельбы")
        return
    end

    if not AimTriggerBotConnection then
        AimTriggerBotConnection = game:GetService("RunService").RenderStepped:Connect(function()
            local Zombie = GetZombieHeadUnderCursor()
            if Zombie then
                local Head = Zombie:FindFirstChild("Head")
                if Head then
                    local IsZombieVisible = true
                    if AimWallCheckEnabled then
                        IsZombieVisible = IsVisible(Character.HumanoidRootPart.Position, Head.Position, {Character, Zombie})
                        if not IsZombieVisible then
                            print("Aim TriggerBot: Зомби " .. Zombie.Name .. " за стеной, выстрел отменён")
                            return
                        end
                    end
                    print("Aim TriggerBot: Попытка выстрела по зомби " .. Zombie.Name)
                    local success, err = pcall(function()
                        -- Временная заглушка: отправляем таблицу с минимальными данными
                        FireRemote:FireServer({
                            Action = "Fire",
                            Target = Head,
                            Position = Head.Position,
                            Damage = 100
                        })
                    end)
                    print("Aim TriggerBot: Результат: " .. (success and "Успех" or "Ошибка: " .. tostring(err)))
                end
            end
        end)
    end
end

sections.AimAssist:Toggle({
    Name = "Enable Aim",
    Default = false,
    Callback = function(Value)
        AimEnabled = Value
        if AimEnabled then
            if not AimConnection then
                AimConnection = game:GetService("RunService").RenderStepped:Connect(AimAtTarget)
            end
            Window:Notify({
                Title = "Zombie ESP",
                Description = "Aim включён",
                Lifetime = 5
            })
        else
            if AimConnection then
                AimConnection:Disconnect()
                AimConnection = nil
            end
            Window:Notify({
                Title = "Zombie ESP",
                Description = "Aim выключён",
                Lifetime = 5
            })
        end
    end
}, "AimEnabled")

sections.AimAssist:Keybind({
    Name = "Aim Key",
    Blacklist = false,
    Callback = function(binded)
        AimEnabled = not AimEnabled
        if AimEnabled then
            if not AimConnection then
                AimConnection = game:GetService("RunService").RenderStepped:Connect(AimAtTarget)
            end
            Window:Notify({
                Title = "Zombie ESP",
                Description = "Aim включён",
                Lifetime = 3
            })
        else
            if AimConnection then
                AimConnection:Disconnect()
                AimConnection = nil
            end
            Window:Notify({
                Title = "Zombie ESP",
                Description = "Aim выключён",
                Lifetime = 3
            })
        end
    end,
    onBinded = function(bind)
        Window:Notify({
            Title = "Zombie ESP",
            Description = "Aim Keybind установлен на " .. tostring(bind.Name),
            Lifetime = 3
        })
    end
}, "AimKey")

sections.AimAssist:Toggle({
    Name = "Wall Check",
    Default = false,
    Callback = function(Value)
        AimWallCheckEnabled = Value
        Window:Notify({
            Title = "Zombie ESP",
            Description = "Aim Wall Check " .. (Value and "включён" or "выключён"),
            Lifetime = 5
        })
    end
}, "AimWallCheckEnabled")

sections.AimAssist:Toggle({
    Name = "Trigger Bot",
    Default = false,
    Callback = function(Value)
        AimTriggerBotEnabled = Value
        if AimTriggerBotEnabled then
            SetupAimTriggerBot()
            Window:Notify({
                Title = "Zombie ESP",
                Description = "Aim TriggerBot включён",
                Lifetime = 5
            })
        else
            if AimTriggerBotConnection then
                AimTriggerBotConnection:Disconnect()
                AimTriggerBotConnection = nil
                Window:Notify({
                    Title = "Zombie ESP",
                    Description = "Aim TriggerBot выключён",
                    Lifetime = 5
                })
            end
        end
    end
}, "AimTriggerBotEnabled")

sections.AimAssist:Slider({
    Name = "Aim Radius",
    Default = 100,
    Minimum = 10,
    Maximum = 500,
    DisplayMethod = "Number",
    Precision = 1,
    Callback = function(Value)
        AimRadius = Value
        Window:Notify({
            Title = "Zombie ESP",
            Description = "Aim Radius установлен на " .. Value .. " studs",
            Lifetime = 5
        })
    end
}, "AimRadius")

sections.AimAssist:Slider({
    Name = "Smoothness",
    Default = 10,
    Minimum = 1,
    Maximum = 20,
    DisplayMethod = "Number",
    Precision = 1,
    Callback = function(Value)
        AimSmoothness = Value
        Window:Notify({
            Title = "Zombie ESP",
            Description = "Smoothness установлен на " .. Value,
            Lifetime = 5
        })
    end
}, "AimSmoothness")

-- Silent Aim
local SilentAimEnabled = false
local SilentAimWallCheckEnabled = false
local SilentAimTriggerBotEnabled = false
local SilentAimConnection
local SilentAimTriggerBotConnection

local function GetClosestZombieForSilentAim()
    local Player = game.Players.LocalPlayer
    local Character = Player.Character
    if not Character or not Character:FindFirstChild("HumanoidRootPart") then return nil end
    
    local ClosestZombie = nil
    local MinValue = math.huge
    local Method = "Distance"

    for _, Zombie in pairs(workspace.Zombies:GetChildren()) do
        local Head = Zombie:FindFirstChild("Head")
        local HRP = Zombie:FindFirstChild("HumanoidRootPart")
        if Head and HRP then
            local Distance = (Character.HumanoidRootPart.Position - HRP.Position).Magnitude
            if Distance <= SilentAimRadius then
                local IsZombieVisible = true
                if SilentAimWallCheckEnabled then
                    IsZombieVisible = IsVisible(Character.HumanoidRootPart.Position, Head.Position, {Character, Zombie})
                    if not IsZombieVisible then
                        print("Silent Aim: Зомби " .. Zombie.Name .. " за стеной, пропущен (Wall Check включён)")
                        continue
                    end
                end

                local Value
                if Method == "Distance" then
                    Value = Distance
                elseif Method == "HP" then
                    local Humanoid = Zombie:FindFirstChild("Humanoid")
                    Value = Humanoid and Humanoid.Health or math.huge
                elseif Method == "Random" then
                    Value = math.random()
                end
                if Value and Value < MinValue then
                    MinValue = Value
                    ClosestZombie = Zombie
                    print("Silent Aim: Выбран зомби: " .. Zombie.Name .. " (Distance: " .. math.floor(Distance) .. ")")
                end
            end
        end
    end
    return ClosestZombie
end

local function SetupSilentAim()
    if not SilentAimEnabled then return end
    local Player = game.Players.LocalPlayer
    local Character = Player.Character
    if not Character then return end

    local FireRemote = FindFireRemote()
    if not FireRemote then
        warn("Silent Aim: Не найден RemoteEvent для стрельбы")
        return
    end

    if not SilentAimConnection then
        SilentAimConnection = game:GetService("UserInputService").InputBegan:Connect(function(input, gameProcessed)
            if input.UserInputType == Enum.UserInputType.MouseButton1 and not gameProcessed then
                local Zombie = GetClosestZombieForSilentAim()
                if Zombie and Zombie:FindFirstChild("Head") then
                    local Head = Zombie:FindFirstChild("Head")
                    print("Silent Aim: Попытка перенаправления пули на голову зомби: " .. Zombie.Name)
                    local success, err = pcall(function()
                        FireRemote:FireServer({
                            Action = "Fire",
                            Target = Head,
                            Position = Head.Position,
                            Damage = 100
                        })
                    end)
                    print("Silent Aim: Результат: " .. (success and "Успех" or "Ошибка: " .. tostring(err)))
                end
            end
        end)
    end
end

local function SetupSilentAimTriggerBot()
    if not SilentAimTriggerBotEnabled then return end
    local Player = game.Players.LocalPlayer
    local Character = Player.Character
    if not Character then return end

    local FireRemote = FindFireRemote()
    if not FireRemote then
        warn("Silent Aim TriggerBot: Не найден RemoteEvent для стрельбы")
        return
    end

    if not SilentAimTriggerBotConnection then
        SilentAimTriggerBotConnection = game:GetService("RunService").RenderStepped:Connect(function()
            local Zombie = GetClosestZombieForTriggerBot()
            if Zombie and Zombie:FindFirstChild("Head") then
                local Head = Zombie:FindFirstChild("Head")
                print("Silent Aim TriggerBot: Попытка выстрела по зомби " .. Zombie.Name)
                local success, err = pcall(function()
                    FireRemote:FireServer({
                        Action = "Fire",
                        Target = Head,
                        Position = Head.Position,
                        Damage = 100
                    })
                end)
                print("Silent Aim TriggerBot: Результат: " .. (success and "Успех" or "Ошибка: " .. tostring(err)))
            end
        end)
    end
end

sections.SilentAim:Toggle({
    Name = "Enable Silent Aim",
    Default = false,
    Callback = function(Value)
        SilentAimEnabled = Value
        if SilentAimEnabled then
            SetupSilentAim()
            Window:Notify({
                Title = "Zombie ESP",
                Description = "Silent Aim включён",
                Lifetime = 5
            })
        else
            if SilentAimConnection then
                SilentAimConnection:Disconnect()
                SilentAimConnection = nil
                Window:Notify({
                    Title = "Zombie ESP",
                    Description = "Silent Aim выключён",
                    Lifetime = 5
                })
            end
        end
    end
}, "SilentAimEnabled")

sections.SilentAim:Toggle({
    Name = "Wall Check",
    Default = false,
    Callback = function(Value)
        SilentAimWallCheckEnabled = Value
        Window:Notify({
            Title = "Zombie ESP",
            Description = "Silent Aim Wall Check " .. (Value and "включён" or "выключён"),
            Lifetime = 5
        })
    end
}, "SilentAimWallCheckEnabled")

sections.SilentAim:Toggle({
    Name = "Trigger Bot",
    Default = false,
    Callback = function(Value)
        SilentAimTriggerBotEnabled = Value
        if SilentAimTriggerBotEnabled then
            SetupSilentAimTriggerBot()
            Window:Notify({
                Title = "Zombie ESP",
                Description = "Silent Aim TriggerBot включён",
                Lifetime = 5
            })
        else
            if SilentAimTriggerBotConnection then
                SilentAimTriggerBotConnection:Disconnect()
                SilentAimTriggerBotConnection = nil
                Window:Notify({
                    Title = "Zombie ESP",
                    Description = "Silent Aim TriggerBot выключён",
                    Lifetime = 5
                })
            end
        end
    end
}, "SilentAimTriggerBotEnabled")

sections.SilentAim:Slider({
    Name = "Silent Aim Radius",
    Default = 100,
    Minimum = 10,
    Maximum = 500,
    DisplayMethod = "Number",
    Precision = 1,
    Callback = function(Value)
        SilentAimRadius = Value
        Window:Notify({
            Title = "Zombie ESP",
            Description = "Silent Aim Radius установлен на " .. Value .. " studs",
            Lifetime = 5
        })
    end
}, "SilentAimRadius")

-- Weapon Mods
local NoRecoilEnabled = false
local NoSpreadEnabled = false
local InfiniteAmmoEnabled = false
local NoReloadEnabled = false
local OneHitKillEnabled = false
local OneHitKillConnection
local InfiniteAmmoConnection
local NoReloadConnection

local function DisableRecoilAndSpread()
    if not (NoRecoilEnabled or NoSpreadEnabled) then return end
    local Player = game.Players.LocalPlayer
    local Character = Player.Character
    if not Character then return end

    local WeaponRig = Character:FindFirstChild("WeaponRig")
    local Tool = Character:FindFirstChildOfClass("Tool")
    local AnimationController = WeaponRig and WeaponRig:FindFirstChild("AnimationController")

    if NoRecoilEnabled and AnimationController then
        for _, anim in pairs(AnimationController:GetPlayingAnimationTracks()) do
            if anim.Name:lower():find("recoil") or anim.Name:lower():find("fire") or anim.Name:lower():find("shoot") then
                anim:Stop()
                print("Остановлена анимация: " .. anim.Name)
            end
        end
    end

    if Tool then
        local SPH_Weapon = Tool:FindFirstChild("SPH_Weapon")
        if SPH_Weapon then
            local WeaponStats = SPH_Weapon:FindFirstChild("WeaponStats")
            if WeaponStats then
                local success, weaponStatsTable = pcall(function()
                    return require(WeaponStats)
                end)
                if success and weaponStatsTable then
                    if NoRecoilEnabled then
                        if weaponStatsTable.recoil then
                            weaponStatsTable.recoil.vertical = 0
                            weaponStatsTable.recoil.horizontal = 0
                            weaponStatsTable.recoil.camShake = 0
                            weaponStatsTable.recoil.damping = 0
                            weaponStatsTable.recoil.speed = 0
                            weaponStatsTable.recoil.aimReduction = 0
                            print("Recoil параметры обнулены")
                        end

                        if weaponStatsTable.gunRecoil then
                            weaponStatsTable.gunRecoil.vertical = 0
                            weaponStatsTable.gunRecoil.horizontal = 0
                            weaponStatsTable.gunRecoil.damping = 0
                            weaponStatsTable.gunRecoil.speed = 0
                            weaponStatsTable.gunRecoil.punchMultiplier = 0
                            print("GunRecoil параметры обнулены")
                        end
                    end

                    if NoSpreadEnabled then
                        if weaponStatsTable.spread then
                            weaponStatsTable.spread = 0
                            print("Spread обнулён")
                        end
                        if weaponStatsTable.aimSpread then
                            weaponStatsTable.aimSpread = 0
                            print("AimSpread обнулён")
                        end
                    end
                else
                    warn("Не удалось загрузить WeaponStats: " .. tostring(weaponStatsTable))
                end
            end
        end
    end
end

local function SetupInfiniteAmmo()
    if not InfiniteAmmoEnabled then return end
    local Player = game.Players.LocalPlayer
    local Character = Player.Character
    if not Character then return end

    local Tool = Character:FindFirstChildOfClass("Tool")
    if not Tool then return end

    local Ammo = Tool:FindFirstChild("Ammo")
    if Ammo then
        local MagAmmo = Ammo:FindFirstChild("MagAmmo")
        if MagAmmo then
            MagAmmo.Value = 9999
            print("Infinite Ammo: Установлено 9999 патронов (MagAmmo)")
        else
            warn("Infinite Ammo: MagAmmo не найден в Ammo")
        end

        local ArcadeAmmoPool = Ammo:FindFirstChild("ArcadeAmmoPool")
        if ArcadeAmmoPool then
            ArcadeAmmoPool.Value = 9999
            print("Infinite Ammo: Установлено 9999 патронов (ArcadeAmmoPool)")
        end
    else
        warn("Infinite Ammo: Папка Ammo не найдена в " .. Tool.Name)
    end
end

local function SetupNoReload()
    if not NoReloadEnabled then return end
    local Player = game.Players.LocalPlayer
    local Character = Player.Character
    if not Character then return end

    local Tool = Character:FindFirstChildOfClass("Tool")
    if not Tool then return end

    local Ammo = Tool:FindFirstChild("Ammo")
    if Ammo then
        local MagAmmo = Ammo:FindFirstChild("MagAmmo")
        if MagAmmo then
            MagAmmo.Value = 9999
            print("No Reload: Установлено 9999 патронов (MagAmmo) для предотвращения перезарядки")
        else
            warn("No Reload: MagAmmo не найден в Ammo")
        end

        if Ammo:FindFirstChild("BoltReady") then
            Ammo.BoltReady.Value = true
            print("No Reload: BoltReady установлен в true")
        end
        if Ammo:FindFirstChild("Chambered") then
            Ammo.Chambered.Value = true
            print("No Reload: Chambered установлен в true")
        end
    else
        warn("No Reload: Папка Ammo не найдена в " .. Tool.Name)
    end
end

local function SetupOneHitKill()
    if not OneHitKillEnabled then return end

    if not OneHitKillConnection then
        OneHitKillConnection = game:GetService("RunService").RenderStepped:Connect(function()
            for _, Zombie in pairs(workspace.Zombies:GetChildren()) do
                local Humanoid = Zombie:FindFirstChild("Humanoid")
                if Humanoid and Humanoid.Health > 0 then
                    -- Альтернативный способ: используем Humanoid:TakeDamage
                    local success, err = pcall(function()
                        Humanoid:TakeDamage(Humanoid.MaxHealth)
                    end)
                    if success then
                        print("One Hit Kill: Зомби " .. Zombie.Name .. " убит через Humanoid:TakeDamage")
                    else
                        print("One Hit Kill: Ошибка при использовании Humanoid:TakeDamage: " .. tostring(err))
                    end
                end
            end
        end)
    end
end

sections.WeaponMods:Toggle({
    Name = "No Recoil",
    Default = false,
    Callback = function(Value)
        NoRecoilEnabled = Value
        if NoRecoilEnabled then
            DisableRecoilAndSpread()
            Window:Notify({
                Title = "Zombie ESP",
                Description = "No Recoil включён",
                Lifetime = 5
            })
        else
            Window:Notify({
                Title = "Zombie ESP",
                Description = "No Recoil выключён",
                Lifetime = 5
            })
        end
    end
}, "NoRecoilEnabled")

sections.WeaponMods:Toggle({
    Name = "No Spread",
    Default = false,
    Callback = function(Value)
        NoSpreadEnabled = Value
        if NoSpreadEnabled then
            DisableRecoilAndSpread()
            Window:Notify({
                Title = "Zombie ESP",
                Description = "No Spread включён",
                Lifetime = 5
            })
        else
            Window:Notify({
                Title = "Zombie ESP",
                Description = "No Spread выключён",
                Lifetime = 5
            })
        end
    end
}, "NoSpreadEnabled")

sections.WeaponMods:Toggle({
    Name = "Infinite Ammo",
    Default = false,
    Callback = function(Value)
        InfiniteAmmoEnabled = Value
        if InfiniteAmmoEnabled then
            if not InfiniteAmmoConnection then
                InfiniteAmmoConnection = game:GetService("RunService").RenderStepped:Connect(SetupInfiniteAmmo)
            end
            Window:Notify({
                Title = "Zombie ESP",
                Description = "Infinite Ammo включён",
                Lifetime = 5
            })
        else
            if InfiniteAmmoConnection then
                InfiniteAmmoConnection:Disconnect()
                InfiniteAmmoConnection = nil
            end
            Window:Notify({
                Title = "Zombie ESP",
                Description = "Infinite Ammo выключён",
                Lifetime = 5
            })
        end
    end
}, "InfiniteAmmoEnabled")

sections.WeaponMods:Toggle({
    Name = "No Reload",
    Default = false,
    Callback = function(Value)
        NoReloadEnabled = Value
        if NoReloadEnabled then
            if not NoReloadConnection then
                NoReloadConnection = game:GetService("RunService").RenderStepped:Connect(SetupNoReload)
            end
            Window:Notify({
                Title = "Zombie ESP",
                Description = "No Reload включён",
                Lifetime = 5
            })
        else
            if NoReloadConnection then
                NoReloadConnection:Disconnect()
                NoReloadConnection = nil
            end
            Window:Notify({
                Title = "Zombie ESP",
                Description = "No Reload выключён",
                Lifetime = 5
            })
        end
    end
}, "NoReloadEnabled")

sections.WeaponMods:Toggle({
    Name = "One Hit Kill",
    Default = false,
    Callback = function(Value)
        OneHitKillEnabled = Value
        if OneHitKillEnabled then
            SetupOneHitKill()
            Window:Notify({
                Title = "Zombie ESP",
                Description = "One Hit Kill включён",
                Lifetime = 5
            })
        else
            if OneHitKillConnection then
                OneHitKillConnection:Disconnect()
                OneHitKillConnection = nil
                Window:Notify({
                    Title = "Zombie ESP",
                    Description = "One Hit Kill выключён",
                    Lifetime = 5
                })
            end
        end
    end
}, "OneHitKillEnabled")

-- Вкладка Game Settings
sections.GameMods:Header({ Name = "Game Mods" })

local CashConnection
local BaseHealthConnection
local PlayerHealthConnection
local DesiredCash = 0
local DesiredBaseHealth = 1000
local DesiredPlayerHealth = 100

local function UpdateCash()
    local Cash = game:GetService("ReplicatedStorage"):FindFirstChild("Cash")
    if Cash and (Cash:IsA("IntValue") or Cash:IsA("NumberValue")) then
        if Cash.Value ~= DesiredCash then
            Cash.Value = DesiredCash
            print("Установлено " .. DesiredCash .. " денег")
        end
    else
        warn("ReplicatedStorage.Cash не найден или не является IntValue/NumberValue")
    end
end

local function UpdateBaseHealth()
    local BaseHealth = game:GetService("ReplicatedStorage"):FindFirstChild("BaseHealth")
    if BaseHealth and (BaseHealth:IsA("IntValue") or BaseHealth:IsA("NumberValue")) then
        if BaseHealth.Value ~= DesiredBaseHealth then
            BaseHealth.Value = DesiredBaseHealth
            print("Установлено " .. DesiredBaseHealth .. " здоровья базы")
        end
    else
        warn("ReplicatedStorage.BaseHealth не найден или не является IntValue/NumberValue")
    end
end

local function UpdatePlayerHealth()
    local Player = game.Players.LocalPlayer
    local Character = Player.Character
    if Character then
        local Humanoid = Character:FindFirstChild("Humanoid")
        if Humanoid then
            if Humanoid.MaxHealth ~= DesiredPlayerHealth or Humanoid.Health ~= DesiredPlayerHealth then
                Humanoid.MaxHealth = DesiredPlayerHealth
                Humanoid.Health = DesiredPlayerHealth
                print("Установлено " .. DesiredPlayerHealth .. " здоровья игрока")
            end
        else
            warn("Humanoid не найден в персонаже игрока")
        end
    else
        warn("Персонаж игрока не найден")
    end
end

sections.GameMods:Slider({
    Name = "Set Money",
    Default = 0,
    Minimum = 0,
    Maximum = 100000,
    DisplayMethod = "Number",
    Precision = 0,
    Callback = function(Value)
        DesiredCash = Value
        UpdateCash()
        if not CashConnection then
            CashConnection = game:GetService("RunService").RenderStepped:Connect(UpdateCash)
        end
        Window:Notify({
            Title = "Zombie ESP",
            Description = "Set Money: " .. Value,
            Lifetime = 5
        })
    end
}, "SetMoney")

sections.GameMods:Slider({
    Name = "Set Base Health",
    Default = 1000,
    Minimum = 0,
    Maximum = 10000,
    DisplayMethod = "Number",
    Precision = 0,
    Callback = function(Value)
        DesiredBaseHealth = Value
        UpdateBaseHealth()
        if not BaseHealthConnection then
            BaseHealthConnection = game:GetService("RunService").RenderStepped:Connect(UpdateBaseHealth)
        end
        Window:Notify({
            Title = "Zombie ESP",
            Description = "Set Base Health: " .. Value,
            Lifetime = 5
        })
    end
}, "SetBaseHealth")

sections.GameMods:Slider({
    Name = "Set Player Health",
    Default = 100,
    Minimum = 100,
    Maximum = 10000,
    DisplayMethod = "Number",
    Precision = 0,
    Callback = function(Value)
        DesiredPlayerHealth = Value
        UpdatePlayerHealth()
        if not PlayerHealthConnection then
            PlayerHealthConnection = game:GetService("RunService").RenderStepped:Connect(UpdatePlayerHealth)
        end
        Window:Notify({
            Title = "Zombie ESP",
            Description = "Set Player Health: " .. Value,
            Lifetime = 5
        })
    end
}, "SetPlayerHealth")

-- Инициализация
MacLib:SetFolder("ZombieESPConfig")
tabs.Visual:Select()
MacLib:LoadAutoLoadConfig()