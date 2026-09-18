--[[ ═══════════════════════════════════════════════════════════════════════════
     LXR-SHOPS — Client: clerks, blips, the counter page
     ═══════════════════════════════════════════════════════════════════════════
     A clerk stands at every counter (a local, frozen ped that exists only
     while a player is near). Talking to the clerk — through lxr-interact —
     opens the counter; the page shows the shelves and what the store buys.
     ═══════════════════════════════════════════════════════════════════════════
     © 2026 iBoss21 / LXRCore — All Rights Reserved
     ═══════════════════════════════════════════════════════════════════════════ ]]

local LXRCore = exports['lxr-core']:GetCoreObject()
local LXR = exports['lxr-core']:GetLXR()
local S = LXRShops
local N = Citizen.InvokeNative
local clerks = {}     -- storeId → ped
local blips = {}
local session = nil

local function toast(key, kind, vars) LXRCore.Notify(Lang:t(key, vars), kind or 'info') end

-- ═══════════════════════════════════════════════════════════════════════════════
-- 🧾 THE COUNTER
-- ═══════════════════════════════════════════════════════════════════════════════
local function close()
    if not session then return end
    session = nil
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end

local function open(store)
    if session then return end
    local ok, data, bundle, brand = LXR.RPC.Server('lxr-shops:open', store.id)
    if not ok then return toast('error.' .. tostring(data), 'error') end
    session = { store = store }
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'open', data = data, locale = bundle, brand = brand or LXRCore.Brand, lang = Config.Lang, images = Config.Trade.images })
end

RegisterNUICallback('close', function(_, cb) close() cb({ ok = true }) end)
RegisterNUICallback('buy', function(d, cb)
    if not session then return cb({ ok = false }) end
    local ok, res, extra = LXR.RPC.Server('lxr-shops:buy', session.store.id, d.cart, d.account)
    if not ok then toast('error.' .. tostring(res), 'error', { amount = extra, label = extra }) return cb({ ok = false, why = res }) end
    toast('info.paid', 'success', { amount = ('%.2f'):format(extra or 0) })
    cb({ ok = true, data = res })
end)
RegisterNUICallback('sell', function(d, cb)
    if not session then return cb({ ok = false }) end
    local ok, res, extra = LXR.RPC.Server('lxr-shops:sell', session.store.id, d.slot, d.amount)
    if not ok then toast('error.' .. tostring(res), 'error') return cb({ ok = false, why = res }) end
    toast('info.sold', 'success', { amount = ('%.2f'):format(extra or 0) })
    cb({ ok = true, data = res })
end)
RegisterNUICallback('sound', function(d, cb) PlaySoundFrontend(d.name or 'NAV_UP', d.set or 'HUD_SHOP_SOUNDSET', true, 0) cb({}) end)

-- ═══════════════════════════════════════════════════════════════════════════════
-- 🧍 CLERKS & BLIPS
-- ═══════════════════════════════════════════════════════════════════════════════
local function spawnClerk(store)
    local model = joaat(store.clerk)
    if not IsModelValid(model) then return end
    RequestModel(model)
    local t = GetGameTimer() + 5000
    while not HasModelLoaded(model) and GetGameTimer() < t do Wait(10) end
    if not HasModelLoaded(model) then return end
    local ped = CreatePed(model, store.coords.x, store.coords.y, store.coords.z - 1.0, store.heading or 0.0, false, false, false, false)
    N(0x283978A15512B2FE, ped, true) -- SET_RANDOM_OUTFIT_VARIATION
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    FreezeEntityPosition(ped, true)
    SetEntityCanBeDamaged(ped, false)
    SetModelAsNoLongerNeeded(model)
    clerks[store.id] = ped
    exports['lxr-interact']:AddEntity('lxr-shops:' .. store.id, ped, { label = store.label, distance = Config.Security.promptDistance, options = {
        { label = Lang:t('ui.browse'), key = 'J', onSelect = function() open(store) end },
    }})
end

local function removeClerk(store)
    local ped = clerks[store.id]
    if not ped then return end
    exports['lxr-interact']:Remove('lxr-shops:' .. store.id)
    if DoesEntityExist(ped) then DeleteEntity(ped) end
    clerks[store.id] = nil
end

CreateThread(function()
    for _, store in ipairs(Config.Stores) do
        local sprite = Config.Blips[store.kind]
        if store.blip and sprite then
            local blip = N(0x554D9D53F696D002, 1664425300, store.coords.x, store.coords.y, store.coords.z)
            if blip and blip ~= 0 then
                N(0x74F74D3207ED525C, blip, joaat(sprite), true)
                N(0x9CB1A1623062F402, blip, store.label)
                if GetResourceState('lxr-mapcolor') == 'started' then pcall(function() N(0x662D364ABF16DE2F, blip, exports['lxr-mapcolor']:modifier()) end) end
                blips[#blips + 1] = blip
            end
        end
    end
    while true do
        if LocalPlayer.state.isLoggedIn then
            local pos = GetEntityCoords(PlayerPedId())
            for _, store in ipairs(Config.Stores) do
                local d = #(pos - store.coords)
                if d < 60.0 and not clerks[store.id] then spawnClerk(store)
                elseif d > 80.0 and clerks[store.id] then removeClerk(store) end
            end
        end
        Wait(2000)
    end
end)

RegisterNetEvent('lxr:client:unloaded', function() close() for _, store in ipairs(Config.Stores) do removeClerk(store) end end)
AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    close()
    for _, b in ipairs(blips) do RemoveBlip(b) end
    for _, store in ipairs(Config.Stores) do removeClerk(store) end
end)

exports('Open', function(id) local st = S.Store(id) if st then open(st) end end)
exports('IsOpen', function() return session ~= nil end)
