--[[
    ██╗     ██╗  ██╗██████╗        ███████╗██╗  ██╗ ██████╗ ██████╗ ███████╗
    ██║     ╚██╗██╔╝██╔══██╗       ██╔════╝██║  ██║██╔═══██╗██╔══██╗██╔════╝
    ██║      ╚███╔╝ ██████╔╝█████╗ ███████╗███████║██║   ██║██████╔╝███████╗
    ██║      ██╔██╗ ██╔══██╗╚════╝ ╚════██║██╔══██║██║   ██║██╔═══╝ ╚════██║
    ███████╗██╔╝ ██╗██║  ██║       ███████║██║  ██║╚██████╔╝██║     ███████║
    ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝       ╚══════╝╚═╝  ╚═╝ ╚═════╝ ╚═╝     ╚══════╝

    🐺 LXR Shops — Client Script

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

-- Trigger a framework callback with the provided name, callback, and args
local function TriggerFrameworkCallback(name, cb, ...)
    if FrameworkName == 'lxr-core' then
        exports['lxr-core']:TriggerCallback(name, cb, ...)
    elseif FrameworkName == 'rsg-core' then
        exports['rsg-core']:TriggerCallback(name, cb, ...)
    elseif FrameworkName == 'vorp_core' then
        -- VORP does not use the same callback bridge; assume license granted as fallback
        cb(true)
    elseif FrameworkName == 'redem_roleplay' or FrameworkName == 'qbr-core' or FrameworkName == 'qr-core' then
        exports[FrameworkName]:TriggerCallback(name, cb, ...)
    else
        -- Standalone fallback — grant access
        cb(true)
    end
end

-- Register a map prompt using the active framework
local function CreateFrameworkPrompt(name, coords, hash, label, options)
    if FrameworkName == 'lxr-core' then
        exports['lxr-core']:createPrompt(name, coords, hash, label, options)
    elseif FrameworkName == 'rsg-core' then
        exports['rsg-core']:createPrompt(name, coords, hash, label, options)
    elseif FrameworkName == 'vorp_core' or FrameworkName == 'redem_roleplay'
        or FrameworkName == 'qbr-core' or FrameworkName == 'qr-core' then
        -- Attempt shared createPrompt export; fall back silently if unavailable
        local ok, err = pcall(function()
            exports[FrameworkName]:createPrompt(name, coords, hash, label, options)
        end)
        if not ok and Config.Debug then
            print(('[lxr-shops] ⚠ createPrompt unavailable for %s: %s'):format(FrameworkName, err))
        end
    end
end

-- Open the shop inventory via the correct framework inventory event
local function OpenShopInventory(shopType, shopItems)
    local fw = Config.FrameworkSettings[FrameworkName]
    local event = fw and fw.inventoryEvent or 'inventory:server:OpenInventory'

    if event == 'none' then
        if Config.Debug then
            print('[lxr-shops] ⚠ No inventory event configured for framework: ' .. FrameworkName)
        end
        return
    end

    if FrameworkName == 'vorp_core' then
        TriggerEvent(event, shopItems)
    else
        TriggerServerEvent(event, "shop", "Itemshop_" .. shopType, shopItems)
    end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- 🐺 FUNCTIONS
-- ═══════════════════════════════════════════════════════════════════════════════

local function OpenShop(shopType, shopName)
    TriggerFrameworkCallback('lxr-shops:server:getLicenseStatus', function(result)
        local ShopItems = {}
        ShopItems.items = {}
        ShopItems.label = shopName
        if shopType == "weapon" then
            if result then
                ShopItems.items = Config.Products[shopType]
            else
                for i = 1, #Config.Products[shopType] do
                    if not Config.Products[shopType][i].requiresLicense then
                        table.insert(ShopItems.items, Config.Products[shopType][i])
                    end
                end
            end
        else
            ShopItems.items = Config.Products[shopType]
        end
        ShopItems.slots = 30
        OpenShopInventory(shopType, ShopItems)
    end)
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- 🐺 EVENTS & HANDLERS
-- ═══════════════════════════════════════════════════════════════════════════════

RegisterNetEvent('lxr-shops:client:SetShopItems', function(shopType, shopProducts)
    Config.Products[shopType] = shopProducts
end)

RegisterNetEvent('lxr-shops:client:RestockShopItems', function(shopType, amount)
    if not Config.Products[shopType] then return end
    for k, v in pairs(Config.Products[shopType]) do
        Config.Products[shopType][k].amount = Config.Products[shopType][k].amount + amount
    end
end)

-- ═══════════════════════════════════════════════════════════════════════════════
-- 🐺 THREADS
-- ═══════════════════════════════════════════════════════════════════════════════

CreateThread(function()
    InitFramework()

    for store, v in pairs(Config.Locations) do
        CreateFrameworkPrompt(v.name, v.coords, 0xF3830D8E, 'Open ' .. v.name, {
            type  = 'callback',
            event = OpenShop,
            args  = { v.products, v.name },
        })
        if v.blip then
            local StoreBlip = N_0x554d9d53f696d002(1664425300, v.coords)
            SetBlipSprite(StoreBlip, v.blip, 1)
            SetBlipScale(StoreBlip, 0.2)
        end
    end
end)
