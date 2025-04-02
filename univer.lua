-- Загружаем LunarLib
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/nosexclub/morbidstuffdw/main/lunarlib_solarafix.lua"))()
local flags = Library.Flags
getgenv().ConfigFolder = "ZombieESPConfig"

-- Создаём окно
local Window = Library:Window({Size = UDim2.new(0, 580, 0, 600)})

-- Вкладка Visual
local Visual = Window:Page({Name = "Visual", Weapons = true}) do
    local ESPSection = Visual:Weapon({Icon = "rbxassetid://6034281935"})
    local VisualSettings = ESPSection:Section({Name = "ESP Settings", Size = 330}) do
        local ESPEnabled = false
        local ESPObjects = {}

        local function AddESP(Zombie)
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

            local function UpdateESP()
    if ESPEnabled and Zombie and Zombie.Parent == workspace.Zombies and Zombie:FindFirstChild("HumanoidRootPart") then
        local HRP = Zombie.HumanoidRootPart
        local Vector, OnScreen = workspace.CurrentCamera:WorldToViewportPoint(HRP.Position)
        local Player = game.Players.LocalPlayer
        local Character = Player.Character
        local Humanoid = Zombie:FindFirstChild("Humanoid")

        if Character and Character:FindFirstChild("HumanoidRootPart") then
            local Distance = (Character.HumanoidRootPart.Position - HRP.Position).Magnitude
            Box.Size = Vector2.new(2000 / Vector.Z, 3000 / Vector.Z)
            Box.Position = Vector2.new(Vector.X - Box.Size.X / 2, Vector.Y - Box.Size.Y / 2)
            Box.Visible = true

            NameText.Position = Vector2.new(Vector.X, Vector.Y - Box.Size.Y / 2 - 30)
            NameText.Text = Zombie.Name
            NameText.Visible = true

            DistanceText.Position = Vector2.new(Vector.X, Vector.Y - Box.Size.Y / 2 - 15)
            DistanceText.Text = "Dist: " .. math.floor(Distance) .. " studs"
            DistanceText.Visible = true

            if Humanoid then
                HPText.Position = Vector2.new(Vector.X, Vector.Y - Box.Size.Y / 2)
                HPText.Text = "HP: " .. math.floor(Humanoid.Health) .. "/" .. Humanoid.MaxHealth
                HPText.Visible = true
            else
                HPText.Visible = false
                print("Зомби " .. Zombie.Name .. " не имеет Humanoid, HP не отображается")
            end
        else
            Box.Visible = false
            NameText.Visible = false
            DistanceText.Visible = false
            HPText.Visible = false
        end
    else
        Box.Visible = false
        NameText.Visible = false
        DistanceText.Visible = false
        HPText.Visible = false
        if ESPEnabled and Zombie and Zombie.Parent then
            print("ESP не отображается для зомби " .. Zombie.Name .. ": не в Workspace.Zombies или нет HumanoidRootPart")
        end
    end
end

            ESPObjects[Zombie] = {Box = Box, NameText = NameText, DistanceText = DistanceText, HPText = HPText}
            game:GetService("RunService").RenderStepped:Connect(UpdateESP)
            print("Добавлен ESP для зомби: " .. Zombie.Name)
        end

        local function CheckZombies()
            for _, Zombie in pairs(workspace.Zombies:GetChildren()) do
                if not ESPObjects[Zombie] then
                    AddESP(Zombie)
                end
            end
        end

        VisualSettings:Toggle({
            Name = "Zombie ESP",
            Flag = "ZombieESP",
            Callback = function(Value)
                ESPEnabled = Value
                if ESPEnabled then
                    CheckZombies()
                    print("ESP включён, найдено зомби в Workspace.Zombies: " .. tostring(#workspace.Zombies:GetChildren()))
                else
                    for _, Data in pairs(ESPObjects) do
                        Data.Box.Visible = false
                        Data.NameText.Visible = false
                        Data.DistanceText.Visible = false
                        Data.HPText.Visible = false
                    end
                    ESPObjects = {}
                    print("ESP выключён")
                end
            end
        }):Colorpicker({
            Name = "ESP Color",
            Default = Color3.fromRGB(255, 0, 0),
            Flag = "ESPColor",
            Callback = function(Color)
                for _, Data in pairs(ESPObjects) do
                    Data.Box.Color = Color
                end
            end
        })

        workspace.Zombies.ChildAdded:Connect(function(Zombie)
            if ESPEnabled and not ESPObjects[Zombie] then
                AddESP(Zombie)
            end
        end)

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
    end
end

-- Вкладка Combat settings
local Combat = Window:Page({Name = "Combat settings", Weapons = true}) do
    local ToolsSection = Combat:Weapon({Icon = "rbxassetid://6034509993"})
    
    -- Секция для аимбота и Silent Aim
    local AimSection = ToolsSection:Section({Name = "Aim Assist", Size = 330}) do
        local AimEnabled = false
        local SilentAimEnabled = false
        local WallCheckEnabled = false
        local AimConnection
        local SilentAimConnection

        local function IsVisible(PlayerPos, TargetPos, IgnoreList)
            local RaycastParams = RaycastParams.new()
            RaycastParams.FilterDescendantsInstances = IgnoreList
            RaycastParams.FilterType = Enum.RaycastFilterType.Blacklist
            local Direction = (TargetPos - PlayerPos).Unit * (TargetPos - PlayerPos).Magnitude
            local RaycastResult = workspace:Raycast(PlayerPos, Direction, RaycastParams)
            return not RaycastResult
        end

        local function GetClosestZombie()
            local Player = game.Players.LocalPlayer
            local Character = Player.Character
            if not Character or not Character:FindFirstChild("HumanoidRootPart") then return nil end
            
            local ClosestZombie = nil
            local MinValue = math.huge
            local Method = flags.AimMethod or "Distance"

            for _, Zombie in pairs(workspace.Zombies:GetChildren()) do
                local Head = Zombie:FindFirstChild("Head")
                local HRP = Zombie:FindFirstChild("HumanoidRootPart")
                if Head and HRP then
                    local Distance = (Character.HumanoidRootPart.Position - HRP.Position).Magnitude
                    if Distance <= (flags.AimRadius or 500) then
                        local IsZombieVisible = true
                        if WallCheckEnabled then
                            IsZombieVisible = IsVisible(Character.HumanoidRootPart.Position, Head.Position, {Character, Zombie})
                            if not IsZombieVisible then
                                print("Зомби " .. Zombie.Name .. " за стеной, пропущен (Wall Check включён)")
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
                            print("Выбран зомби для аимбота/Silent Aim: " .. Zombie.Name .. " (Distance: " .. math.floor(Distance) .. ")")
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
                local Smoothness = flags.AimSmoothness or 10
                local CurrentCFrame = Camera.CFrame
                local TargetCFrame = CFrame.new(CurrentCFrame.Position, HeadPos)
                Camera.CFrame = CurrentCFrame:Lerp(TargetCFrame, 1 / Smoothness)
                print("Аимбот наводится на голову зомби: " .. Zombie.Name)
            end
        end

        local function SetupSilentAim()
            if not SilentAimEnabled then return end
            local Player = game.Players.LocalPlayer
            local Character = Player.Character
            if not Character then return end

            local Tool = Character:FindFirstChildOfClass("Tool")
            if not Tool then return end

            local SPH_Weapon = Tool:FindFirstChild("SPH_Weapon")
            if not SPH_Weapon then return end

            local function RedirectBullet()
                local Zombie = GetClosestZombie()
                if Zombie and Zombie:FindFirstChild("Head") then
                    local HeadPos = Zombie.Head.Position
                    local PlayerPos = Character.HumanoidRootPart.Position
                    local Direction = (HeadPos - PlayerPos).Unit
                    print("Silent Aim перенаправляет пулю на голову зомби: " .. Zombie.Name)
                    -- Игнорируем физику рикошета и пробивания из BulletPhysics, так как Silent Aim должен гарантированно попадать
                    local RaycastParams = RaycastParams.new()
                    RaycastParams.FilterDescendantsInstances = {Character}
                    RaycastParams.FilterType = Enum.RaycastFilterType.Blacklist
                    local RaycastResult = workspace:Raycast(PlayerPos, Direction * 1000, RaycastParams)
                    if RaycastResult and RaycastResult.Instance:IsDescendantOf(Zombie) then
                        print("Silent Aim: Попадание в зомби " .. Zombie.Name .. " подтверждено")
                    end
                end
            end

            if not SilentAimConnection then
                SilentAimConnection = game:GetService("UserInputService").InputBegan:Connect(function(input, gameProcessed)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 and not gameProcessed then
                        RedirectBullet()
                    end
                end)
            end
        end

        AimSection:Toggle({
            Name = "Enable Aim",
            Flag = "AimEnabled",
            Callback = function(Value)
                AimEnabled = Value
                if AimEnabled then
                    if not AimConnection then
                        AimConnection = game:GetService("RunService").RenderStepped:Connect(AimAtTarget)
                    end
                else
                    if AimConnection then
                        AimConnection:Disconnect()
                        AimConnection = nil
                    end
                end
            end
        }):Keybind({
            Name = "Aim Key",
            Flag = "AimKey",
            Mode = "Toggle",
            Default = Enum.KeyCode.E
        })

        AimSection:Toggle({
            Name = "Silent Aim",
            Flag = "SilentAimEnabled",
            Callback = function(Value)
                SilentAimEnabled = Value
                if SilentAimEnabled then
                    SetupSilentAim()
                    print("Silent Aim включён")
                else
                    if SilentAimConnection then
                        SilentAimConnection:Disconnect()
                        SilentAimConnection = nil
                        print("Silent Aim выключён")
                    end
                end
            end
        })

        AimSection:Toggle({
            Name = "Wall Check",
            Flag = "WallCheckEnabled",
            Callback = function(Value)
                WallCheckEnabled = Value
                print("Wall Check " .. (Value and "включён" or "выключён"))
            end
        })

        AimSection:Slider({
            Name = "Aim Radius",
            Flag = "AimRadius",
            Min = 10,
            Max = 500,
            Default = 100,
            Decimals = 1,
            Suffix = " studs"
        })

        AimSection:Slider({
            Name = "Smoothness",
            Flag = "AimSmoothness",
            Min = 1,
            Max = 20,
            Default = 10,
            Decimals = 1
        })

        AimSection:Dropdown({
            Name = "Target Method",
            Flag = "AimMethod",
            Options = {"Distance", "HP", "Random"},
            Default = "Distance",
            Callback = function() end
        })
    end

    -- Секция для No Recoil и No Spread
    local RecoilSection = ToolsSection:Section({Name = "Recoil Control", Size = 330}) do
        local NoRecoilEnabled = false
        local NoSpreadEnabled = false
        local RecoilConnection
        local OriginalRecoilValues = {}
        local OriginalGunRecoilValues = {}
        local OriginalSpreadValues = {}

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
                            -- Отключаем отдачу
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

                            -- Отключаем разброс
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

        RecoilSection:Toggle({
            Name = "No Recoil",
            Flag = "NoRecoil",
            Callback = function(Value)
                NoRecoilEnabled = Value
                if NoRecoilEnabled then
                    if not RecoilConnection then
                        local Player = game.Players.LocalPlayer
                        local Character = Player.Character
                        if Character then
                            local Tool = Character:FindFirstChildOfClass("Tool")
                            if Tool then
                                local SPH_Weapon = Tool:FindFirstChild("SPH_Weapon")
                                if SPH_Weapon then
                                    local WeaponStats = SPH_Weapon:FindFirstChild("WeaponStats")
                                    if WeaponStats then
                                        local success, weaponStatsTable = pcall(function()
                                            return require(WeaponStats)
                                        end)
                                        if success and weaponStatsTable then
                                            if weaponStatsTable.recoil then
                                                OriginalRecoilValues = {
                                                    vertical = weaponStatsTable.recoil.vertical,
                                                    horizontal = weaponStatsTable.recoil.horizontal,
                                                    camShake = weaponStatsTable.recoil.camShake,
                                                    damping = weaponStatsTable.recoil.damping,
                                                    speed = weaponStatsTable.recoil.speed,
                                                    aimReduction = weaponStatsTable.recoil.aimReduction
                                                }
                                            end
                                            if weaponStatsTable.gunRecoil then
                                                OriginalGunRecoilValues = {
                                                    vertical = weaponStatsTable.gunRecoil.vertical,
                                                    horizontal = weaponStatsTable.gunRecoil.horizontal,
                                                    damping = weaponStatsTable.gunRecoil.damping,
                                                    speed = weaponStatsTable.gunRecoil.speed,
                                                    punchMultiplier = weaponStatsTable.gunRecoil.punchMultiplier
                                                }
                                            end
                                        end
                                    end
                                end
                            end
                        end

                        RecoilConnection = game:GetService("RunService").RenderStepped:Connect(DisableRecoilAndSpread)
                        print("No Recoil включён")
                    end
                else
                    if RecoilConnection then
                        RecoilConnection:Disconnect()
                        RecoilConnection = nil

                        local Player = game.Players.LocalPlayer
                        local Character = Player.Character
                        if Character then
                            local Tool = Character:FindFirstChildOfClass("Tool")
                            if Tool then
                                local SPH_Weapon = Tool:FindFirstChild("SPH_Weapon")
                                if SPH_Weapon then
                                    local WeaponStats = SPH_Weapon:FindFirstChild("WeaponStats")
                                    if WeaponStats then
                                        local success, weaponStatsTable = pcall(function()
                                            return require(WeaponStats)
                                        end)
                                        if success and weaponStatsTable then
                                            if weaponStatsTable.recoil and next(OriginalRecoilValues) then
                                                weaponStatsTable.recoil.vertical = OriginalRecoilValues.vertical
                                                weaponStatsTable.recoil.horizontal = OriginalRecoilValues.horizontal
                                                weaponStatsTable.recoil.camShake = OriginalRecoilValues.camShake
                                                weaponStatsTable.recoil.damping = OriginalRecoilValues.damping
                                                weaponStatsTable.recoil.speed = OriginalRecoilValues.speed
                                                weaponStatsTable.recoil.aimReduction = OriginalRecoilValues.aimReduction
                                            end
                                            if weaponStatsTable.gunRecoil and next(OriginalGunRecoilValues) then
                                                weaponStatsTable.gunRecoil.vertical = OriginalGunRecoilValues.vertical
                                                weaponStatsTable.gunRecoil.horizontal = OriginalGunRecoilValues.horizontal
                                                weaponStatsTable.gunRecoil.damping = OriginalGunRecoilValues.damping
                                                weaponStatsTable.gunRecoil.speed = OriginalGunRecoilValues.speed
                                                weaponStatsTable.gunRecoil.punchMultiplier = OriginalGunRecoilValues.punchMultiplier
                                            end
                                        end
                                    end
                                end
                            end
                        end

                        OriginalRecoilValues = {}
                        OriginalGunRecoilValues = {}
                        print("No Recoil выключён")
                    end
                end
            end
        })

        RecoilSection:Toggle({
            Name = "No Spread",
            Flag = "NoSpread",
            Callback = function(Value)
                NoSpreadEnabled = Value
                if NoSpreadEnabled then
                    if not RecoilConnection then
                        local Player = game.Players.LocalPlayer
                        local Character = Player.Character
                        if Character then
                            local Tool = Character:FindFirstChildOfClass("Tool")
                            if Tool then
                                local SPH_Weapon = Tool:FindFirstChild("SPH_Weapon")
                                if SPH_Weapon then
                                    local WeaponStats = SPH_Weapon:FindFirstChild("WeaponStats")
                                    if WeaponStats then
                                        local success, weaponStatsTable = pcall(function()
                                            return require(WeaponStats)
                                        end)
                                        if success and weaponStatsTable then
                                            if weaponStatsTable.spread then
                                                OriginalSpreadValues.spread = weaponStatsTable.spread
                                            end
                                            if weaponStatsTable.aimSpread then
                                                OriginalSpreadValues.aimSpread = weaponStatsTable.aimSpread
                                            end
                                        end
                                    end
                                end
                            end
                        end

                        RecoilConnection = game:GetService("RunService").RenderStepped:Connect(DisableRecoilAndSpread)
                        print("No Spread включён")
                    end
                else
                    if RecoilConnection and not NoRecoilEnabled then
                        RecoilConnection:Disconnect()
                        RecoilConnection = nil
                    end

                    local Player = game.Players.LocalPlayer
                    local Character = Player.Character
                    if Character then
                        local Tool = Character:FindFirstChildOfClass("Tool")
                        if Tool then
                            local SPH_Weapon = Tool:FindFirstChild("SPH_Weapon")
                            if SPH_Weapon then
                                local WeaponStats = SPH_Weapon:FindFirstChild("WeaponStats")
                                if WeaponStats then
                                    local success, weaponStatsTable = pcall(function()
                                        return require(WeaponStats)
                                    end)
                                    if success and weaponStatsTable then
                                        if weaponStatsTable.spread and OriginalSpreadValues.spread then
                                            weaponStatsTable.spread = OriginalSpreadValues.spread
                                        end
                                        if weaponStatsTable.aimSpread and OriginalSpreadValues.aimSpread then
                                            weaponStatsTable.aimSpread = OriginalSpreadValues.aimSpread
                                        end
                                    end
                                end
                            end
                        end
                    end

                    OriginalSpreadValues = {}
                    print("No Spread выключён")
                end
            end
        })
    end

    -- Секция для выгрузки
    local UnloadSection = ToolsSection:Section({Name = "Script Tools", Size = 330}) do
        UnloadSection:Button({
            Name = "Unload",
            Callback = function()
                for _, Data in pairs(ESPObjects) do
                    Data.Box:Remove()
                    Data.NameText:Remove()
                    Data.DistanceText:Remove()
                    Data.HPText:Remove()
                end
                ESPObjects = {}
                Library:Unload()
            end
        })
    end
end

-- Настройки
local Settings = Window:Page({Name = "Settings"}) do
    local Menu = Settings:Section({Name = "Menu", Size = 120})
    local Cfgs = Settings:Section({Name = "Configs", Size = 200, Side = "Right"})

    local abc = false
    Menu:Keybind({
        Name = "Menu key",
        Flag = "MenuKey",
        Default = Enum.KeyCode.End,
        Mode = "Toggle",
        Callback = function()
            abc = not abc
            Library:SetOpen(abc)
        end
    })

    local CFGList = Cfgs:Dropdown({Name = "Cfg List", Flag = "SettingConfigurationList", Options = {}})
    Cfgs:Textbox({Flag = "SettingsConfigurationName", Placeholder = "Config name"})

    local CurrentList = {}
    if not isfolder(getgenv().ConfigFolder) then
        makefolder(getgenv().ConfigFolder)
    end
    if not isfolder(getgenv().ConfigFolder .. "/Configs") then
        makefolder(getgenv().ConfigFolder .. "/Configs")
    end

    local function UpdateConfigList()
        local List = {}
        for _, file in ipairs(listfiles(getgenv().ConfigFolder .. "/Configs")) do
            local FileName = file:gsub(getgenv().ConfigFolder .. "/Configs\\", ""):gsub(".cfg", "")
            List[#List + 1] = FileName
        end
        if #List ~= #CurrentList then
            CurrentList = List
            CFGList:Refresh(CurrentList)
        end
    end

    Cfgs:Button({Name = "Create", Callback = function()
        local ConfigName = flags.SettingsConfigurationName
        if ConfigName == "" or isfile(getgenv().ConfigFolder .. "/Configs/" .. ConfigName .. ".cfg") then
            return
        end
        writefile(getgenv().ConfigFolder .. "/Configs/" .. ConfigName .. ".cfg", Library:GetConfig())
        UpdateConfigList()
    end})
    Cfgs:Button({Name = "Save", Callback = function()
        local SelectedConfig = flags.SettingConfigurationList
        if SelectedConfig then
            writefile(getgenv().ConfigFolder .. "/Configs/" .. SelectedConfig .. ".cfg", Library:GetConfig())
        end
    end})
    Cfgs:Button({Name = "Load", Callback = function()
        local SelectedConfig = flags.SettingConfigurationList
        if SelectedConfig then
            Library:LoadConfig(readfile(getgenv().ConfigFolder .. "/Configs/" .. SelectedConfig .. ".cfg"))
        end
    end})
    Cfgs:Button({Name = "Delete", Callback = function()
        local SelectedConfig = flags.SettingConfigurationList
        if SelectedConfig then
            delfile(getgenv().ConfigFolder .. "/Configs/" .. SelectedConfig .. ".cfg")
        end
        UpdateConfigList()
    end})
    Cfgs:Button({Name = "Refresh", Callback = function()
        UpdateConfigList()
    end})

    UpdateConfigList()
end