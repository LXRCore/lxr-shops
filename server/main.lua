--[[ ═══════════════════════════════════════════════════════════════════════════
     LXR-SHOPS — Server: counters, stock, buying and selling
     ═══════════════════════════════════════════════════════════════════════════
     Every counter is built from the core catalog through Config.Shelves;
     every price from the ledger through the store's mark-up. The server
     checks distance, hours, stock, money and carry weight, moves money and
     items through the core, and emits receipts.
     ═══════════════════════════════════════════════════════════════════════════
     © 2026 iBoss21 / LXRCore — All Rights Reserved
     ═══════════════════════════════════════════════════════════════════════════ ]]

local LXRCore = exports['lxr-core']:GetCoreObject()
local LXR = exports['lxr-core']:GetLXR()
local S = LXRShops
local Inventory = LXRCore.Inventory
local RES = GetCurrentResourceName()
local stock = {}      -- storeId → { [item] = qty }  (only when limited)
local buckets = {}

local function limited(src)
    local b = buckets[src]
    local now = GetGameTimer()
    if not b or now - b.at > Config.Security.rateLimit.windowMs then b = { at = now, n = 0 } buckets[src] = b end
    b.n = b.n + 1
    return b.n > Config.Security.rateLimit.burst
end
local function player(src) return LXRCore.Functions.GetPlayer(src) end
local function near(src, store)
    local ped = GetPlayerPed(src)
    if ped == 0 then return false end
    return #(GetEntityCoords(ped) - store.coords) <= Config.Security.maxDistance
end
local function hour() return tonumber(GlobalState.hour) or 12 end
local function closed() return not S.Open(hour()) end
local function jobOk(P, store)
    if not store.jobs then return true end
    local job = P.PlayerData.job or {}
    local need = store.jobs[job.name]
    if need == nil then return false end
    local grade = type(job.grade) == 'table' and job.grade.level or job.grade
    return (tonumber(grade) or 0) >= (tonumber(need) or 0)
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- 📦 STOCK
-- ═══════════════════════════════════════════════════════════════════════════════
if Config.Stock.limited and Config.Stock.persist then
    LXRCore.DB.RegisterMigration(RES, '0001_shop_stock', [[
CREATE TABLE IF NOT EXISTS `lxr_shops_stock` (
  `store` VARCHAR(64) NOT NULL,
  `item` VARCHAR(64) NOT NULL,
  `qty` INT NOT NULL DEFAULT 0,
  PRIMARY KEY (`store`, `item`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
]])
end

local function qty(store, item)
    if not Config.Stock.limited then return math.huge end
    local s = stock[store.id]
    if not s then return 0 end
    return tonumber(s[item]) or 0
end
local function take(store, item, n)
    if not Config.Stock.limited then return end
    stock[store.id][item] = math.max(0, qty(store, item) - n)
    if Config.Stock.persist then LXRCore.DB.UpdateAsync('INSERT INTO lxr_shops_stock (store, item, qty) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE qty = VALUES(qty)', { store.id, item, stock[store.id][item] }) end
end

local function seed()
    if not Config.Stock.limited then return end
    local saved = {}
    if Config.Stock.persist then
        for _, r in ipairs(LXRCore.DB.Query('SELECT store, item, qty FROM lxr_shops_stock') or {}) do saved[r.store .. '|' .. r.item] = r.qty end
    end
    for _, store in ipairs(Config.Stores) do
        stock[store.id] = {}
        for _, shelf in ipairs(S.Shelves(store.kind)) do
            for _, def in ipairs(shelf.items) do
                stock[store.id][def.name] = saved[store.id .. '|' .. def.name] or Config.Stock.defaultQty
            end
        end
    end
    CreateThread(function()
        while true do
            Wait(Config.Stock.restockEveryMs)
            for _, store in ipairs(Config.Stores) do
                for item, n in pairs(stock[store.id]) do if n < Config.Stock.restockTo then stock[store.id][item] = Config.Stock.restockTo take(store, item, 0) end end
            end
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- 🧾 THE COUNTER
-- ═══════════════════════════════════════════════════════════════════════════════
local function counter(src, store)
    local P = player(src)
    local isClosed = closed()
    local shelves = {}
    if store.sells ~= false then
        for _, shelf in ipairs(S.Shelves(store.kind)) do
            local items = {}
            for _, def in ipairs(shelf.items) do
                items[#items + 1] = { name = def.name, label = def.label, description = def.description, category = def.category, price = S.Price(def.name, store, isClosed), stock = Config.Stock.limited and qty(store, def.name) or nil, weight = def.weight, rarity = def.rarity }
            end
            shelves[#shelves + 1] = { label = shelf.label, items = items }
        end
    end
    local sells = {}
    for slot, it in pairs(P.PlayerData.items or {}) do
        local def = it and LXRShared.Items[it.name]
        if def and S.Buys(store.kind, def) then
            sells[#sells + 1] = { slot = tonumber(slot), name = it.name, label = def.label, amount = it.amount, offer = S.Offer(it.name, it.info, store), quality = it.info and it.info.quality }
        end
    end
    table.sort(sells, function(a, b) return a.slot < b.slot end)
    local purses = {}
    for _, a in ipairs(Config.Trade.accounts or { Config.Trade.account }) do purses[a] = P.PlayerData.money[a] or 0 end
    return { store = { id = store.id, label = store.label, kind = store.kind, priceMult = store.priceMult or 1 }, shelves = shelves, sells = sells, cash = P.PlayerData.money[Config.Trade.account] or 0, purses = purses, accounts = Config.Trade.accounts or { Config.Trade.account }, closed = isClosed, maxPerPurchase = Config.Trade.maxPerPurchase }
end

LXR.RPC.Register('lxr-shops:open', function(src, id)
    if limited(src) then return false, 'rate' end
    local P, store = player(src), S.Store(id)
    if not P or not store then return false, 'invalid' end
    if not near(src, store) then return false, 'too_far' end
    if not jobOk(P, store) then return false, 'staff_only' end
    if closed() and not Config.Trade.nightOpen then return false, 'closed' end
    return true, counter(src, store), Lang.bundle(), LXRCore.Brand
end)

LXR.RPC.Register('lxr-shops:buy', function(src, id, cart, account)
    if limited(src) then return false, 'rate' end
    local P, store = player(src), S.Store(id)
    if not P or not store or type(cart) ~= 'table' then return false, 'invalid' end
    if not near(src, store) then return false, 'too_far' end
    if not jobOk(P, store) or store.sells == false then return false, 'staff_only' end
    local isClosed = closed()
    if isClosed and not Config.Trade.nightOpen then return false, 'closed' end
    -- validate every line against the shelves, then charge once
    local allowed = {}
    for _, shelf in ipairs(S.Shelves(store.kind)) do for _, def in ipairs(shelf.items) do allowed[def.name] = def end end
    local total, lines = 0, {}
    for _, line in ipairs(cart) do
        local name, n = tostring(line.name or ''):lower(), math.floor(tonumber(line.amount) or 0)
        local def = allowed[name]
        if not def or n <= 0 or n > Config.Trade.maxPerPurchase then return false, 'invalid' end
        if qty(store, name) < n then return false, 'out_of_stock', def.label end
        if def.unique and n > 1 then n = 1 end
        local price = S.Price(name, store, isClosed)
        total = total + price * n
        lines[#lines + 1] = { name = name, amount = n, price = price, def = def }
    end
    if #lines == 0 then return false, 'invalid' end
    total = LXRShared.Round(total, 2)
    local purse = Config.Trade.account
    for _, a in ipairs(Config.Trade.accounts or { purse }) do if a == account then purse = a end end
    if (P.PlayerData.money[purse] or 0) < total then return false, 'no_money', total end
    for _, l in ipairs(lines) do if not Inventory.CanCarry(src, l.name, l.amount) then return false, 'too_heavy', l.def.label end end
    if not P.Functions.RemoveMoney(purse, total, 'shop:' .. store.id) then return false, 'no_money', total end
    local receipt = {}
    for _, l in ipairs(lines) do
        local ok = false
        if l.def.unique then
            for _ = 1, l.amount do ok = P.Functions.AddItem(l.name, 1, nil, nil, 'shop:' .. store.id) end
        else ok = P.Functions.AddItem(l.name, l.amount, nil, nil, 'shop:' .. store.id) end
        if ok then take(store, l.name, l.amount) receipt[#receipt + 1] = { name = l.name, amount = l.amount, price = l.price } end
    end
    LXRCore.Emit('lxr:shops:bought', nil, src, store.id, receipt, total)
    if Config.Debug.log then LXRCore.Log.info('shops', ('bought $%.2f at %s'):format(total, store.id), { source = src, lines = #receipt }) end
    return true, counter(src, store), total
end)

LXR.RPC.Register('lxr-shops:sell', function(src, id, slot, amount)
    if limited(src) then return false, 'rate' end
    local P, store = player(src), S.Store(id)
    if not P or not store then return false, 'invalid' end
    if not near(src, store) then return false, 'too_far' end
    local it = P.PlayerData.items[tonumber(slot) or -1]
    local def = it and LXRShared.Items[it.name]
    if not def or not S.Buys(store.kind, def) then return false, 'not_wanted' end
    local n = math.max(1, math.min(math.floor(tonumber(amount) or 1), it.amount))
    local offer = S.Offer(it.name, it.info, store)
    local total = LXRShared.Round(offer * n, 2)
    if not P.Functions.RemoveItem(it.name, n, it.slot, 'sold:' .. store.id) then return false, 'invalid' end
    P.Functions.AddMoney(Config.Trade.account, total, 'sold:' .. store.id)
    LXRCore.Emit('lxr:shops:sold', nil, src, store.id, { name = it.name, amount = n, price = offer }, total)
    return true, counter(src, store), total
end)

CreateThread(function()
    seed()
    if Config.Debug.printBanner then
        local n = 0
        for _, st in ipairs(Config.Stores) do for _, sh in ipairs(S.Shelves(st.kind)) do n = n + #sh.items end end
        print(('^1[lxr-shops]^7 v%s — %d counters, %d shelf lines, stock %s'):format(GetResourceMetadata(RES, 'version', 0), #Config.Stores, n, Config.Stock.limited and 'limited' or 'open'))
    end
end)

AddEventHandler('playerDropped', function() buckets[source] = nil end)

exports('GetStore', S.Store)
exports('Price', function(name, storeId) return S.Price(name, S.Store(storeId), closed()) end)
exports('Offer', function(name, info, storeId) return S.Offer(name, info, S.Store(storeId)) end)
exports('GetStock', function(storeId, item) local st = S.Store(storeId) return st and qty(st, item) or 0 end)
exports('SetStock', function(storeId, item, n) local st = S.Store(storeId) if not st or not Config.Stock.limited then return false end stock[st.id][item] = math.max(0, math.floor(tonumber(n) or 0)) take(st, item, 0) return true end)
