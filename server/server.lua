--[[
    ██╗     ██╗  ██╗██████╗        ███████╗██╗  ██╗ ██████╗ ██████╗ ███████╗
    ██║     ╚██╗██╔╝██╔══██╗       ██╔════╝██║  ██║██╔═══██╗██╔══██╗██╔════╝
    ██║      ╚███╔╝ ██████╔╝█████╗ ███████╗███████║██║   ██║██████╔╝███████╗
    ██║      ██╔██╗ ██╔══██╗╚════╝ ╚════██║██╔══██║██║   ██║██╔═══╝ ╚════██║
    ███████╗██╔╝ ██╗██║  ██║       ███████║██║  ██║╚██████╔╝██║     ███████║
    ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝       ╚══════╝╚═╝  ╚═╝ ╚═════╝ ╚═╝     ╚══════╝

    🐺 LXR Shops — Server Script

    ═══════════════════════════════════════════════════════════════════════════════
    SERVER INFORMATION
    ═══════════════════════════════════════════════════════════════════════════════

    Server:    The Land of Wolves 🐺
    Developer: iBoss21 / The Lux Empire
    Website:   https://www.wolves.land
    Discord:   https://discord.gg/CrKcWdfd3A
    Store:     https://theluxempire.tebex.io

    ═══════════════════════════════════════════════════════════════════════════════

    © 2026 iBoss21 / The Lux Empire | wolves.land | All Rights Reserved
]]

-- ═══════════════════════════════════════════════════════════════════════════════
-- 🐺 FRAMEWORK BRIDGE — AUTO-DETECTION
-- ═══════════════════════════════════════════════════════════════════════════════

local FrameworkName = Config.Framework

local function InitFramework()
    if FrameworkName ~= 'auto' then return end

    if GetResourceState('lxr-core') == 'started' then
        FrameworkName = 'lxr-core'
    elseif GetResourceState('rsg-core') == 'started' then
        FrameworkName = 'rsg-core'
    elseif GetResourceState('vorp_core') == 'started' then
        FrameworkName = 'vorp_core'
    elseif GetResourceState('redem_roleplay') == 'started' then
        FrameworkName = 'redem_roleplay'
    elseif GetResourceState('qbr-core') == 'started' then
        FrameworkName = 'qbr-core'
    elseif GetResourceState('qr-core') == 'started' then
        FrameworkName = 'qr-core'
    else
        FrameworkName = 'standalone'
    end

    if Config.Debug then
        print(('[lxr-shops] 🐺 Framework detected: %s'):format(FrameworkName))
    end
end

-- Register a server-side callback using the active framework
local function CreateFrameworkCallback(name, cb)
    if FrameworkName == 'lxr-core' then
        exports['lxr-core']:CreateCallback(name, cb)
    elseif FrameworkName == 'rsg-core' then
        exports['rsg-core']:CreateCallback(name, cb)
    elseif FrameworkName == 'vorp_core' then
        -- VORP uses event-based RPC; register via net event as a compatibility shim
        RegisterNetEvent(name)
        AddEventHandler(name, function(requestId, ...)
            local src = source
            cb(src, function(result)
                TriggerClientEvent(name .. ':response', src, requestId, result)
            end, ...)
        end)
    elseif FrameworkName == 'redem_roleplay' or FrameworkName == 'qbr-core' or FrameworkName == 'qr-core' then
        local ok, err = pcall(function()
            exports[FrameworkName]:CreateCallback(name, cb)
        end)
        if not ok and Config.Debug then
            print(('[lxr-shops] ⚠ CreateCallback unavailable for %s: %s'):format(FrameworkName, err))
        end
    end
    -- Standalone: callbacks are not needed (client-side fallback grants access)
end

-- Retrieve a player object using the active framework
local function GetFrameworkPlayer(src)
    if FrameworkName == 'lxr-core' then
        return exports['lxr-core']:GetPlayer(src)
    elseif FrameworkName == 'rsg-core' then
        return exports['rsg-core']:GetPlayer(src)
    elseif FrameworkName == 'vorp_core' then
        return exports['vorp_core']:GetUser(src)
    elseif FrameworkName == 'redem_roleplay' or FrameworkName == 'qbr-core' or FrameworkName == 'qr-core' then
        local ok, player = pcall(function()
            return exports[FrameworkName]:GetPlayer(src)
        end)
        return ok and player or nil
    end
    return nil
end

-- Check whether a player holds a weapon licence
local function HasWeaponLicense(player)
    if not player then return false end

    if FrameworkName == 'lxr-core' or FrameworkName == 'rsg-core'
        or FrameworkName == 'redem_roleplay' or FrameworkName == 'qbr-core' or FrameworkName == 'qr-core' then
        local licenseTable = player.PlayerData and player.PlayerData.metadata
            and player.PlayerData.metadata["licences"]
        return (licenseTable and licenseTable.weapon) == true
    elseif FrameworkName == 'vorp_core' then
        -- VORP stores character data differently; grant access as a safe fallback
        return true
    end
    return false
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- 🐺 BOOT
-- ═══════════════════════════════════════════════════════════════════════════════

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    InitFramework()
    RegisterShopCallbacks()
    print(('[lxr-shops] 🐺 Started successfully | Framework: %s | wolves.land'):format(FrameworkName))
end)

-- ═══════════════════════════════════════════════════════════════════════════════
-- 🐺 EVENTS & HANDLERS
-- ═══════════════════════════════════════════════════════════════════════════════

RegisterNetEvent('lxr-shops:server:UpdateShopItems', function(shopType, slot, amount)
    Config.Products[shopType][slot].amount = Config.Products[shopType][slot].amount - amount
    if Config.Products[shopType][slot].amount <= 0 then
        Config.Products[shopType][slot].amount = 0
    end
    TriggerClientEvent('lxr-shops:client:SetShopItems', -1, shopType, Config.Products[shopType])
end)

RegisterNetEvent('lxr-shops:server:RestockShopItems', function(shopType)
    if Config.Products[shopType] ~= nil then
        local randAmount = math.random(10, 50)
        for k, v in pairs(Config.Products[shopType]) do
            Config.Products[shopType][k].amount = Config.Products[shopType][k].amount + randAmount
        end
        TriggerClientEvent('lxr-shops:client:RestockShopItems', -1, shopType, randAmount)
    end
end)

-- ═══════════════════════════════════════════════════════════════════════════════
-- 🐺 CALLBACKS
-- ═══════════════════════════════════════════════════════════════════════════════

function RegisterShopCallbacks()
    CreateFrameworkCallback('lxr-shops:server:getLicenseStatus', function(source, cb)
        local Player = GetFrameworkPlayer(source)
        cb(HasWeaponLicense(Player))
    end)
end
