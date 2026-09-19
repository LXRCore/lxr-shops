--[[ ═══════════════════════════════════════════════════════════════════════════
     LXR-SHOPS — Shared rules: shelves over the catalog, prices, what sells
     ═══════════════════════════════════════════════════════════════════════════
     Pure functions over the core catalog (LXRShared.Items, Rarities,
     WeaponsByName) and Config. The server builds counters with them, the
     client mirrors the price it shows, the tests exercise them.
     ═══════════════════════════════════════════════════════════════════════════
     © 2026 iBoss21 / LXRCore — All Rights Reserved
     ═══════════════════════════════════════════════════════════════════════════ ]]

LXRShops = LXRShops or {}
local S = LXRShops

local function has(list, v) for _, x in ipairs(list or {}) do if x == v then return true end end return false end
local function rarityRank(name) local r = LXRShared.Rarities and LXRShared.Rarities[name or 'common'] return r and r.tier or 1 end

---Does a catalog item pass a shelf / buys filter.
function S.Matches(def, f)
    if not def or type(f) ~= 'table' then return false end
    if f.names and not has(f.names, def.name) then return false end
    if f.exclude and has(f.exclude, def.name) then return false end
    if f.categories and not has(f.categories, def.category) then return false end
    if f.legal ~= nil and ((def.legal ~= false) ~= f.legal) then return false end
    if f.rarityMax and rarityRank(def.rarity) > rarityRank(f.rarityMax) then return false end
    if f.tags then
        local ok = false
        for _, t in ipairs(f.tags) do if has(def.tags, t) then ok = true end end
        if not ok then return false end
    end
    if f.weaponCategories then
        local rec = LXRShared.WeaponsByName and LXRShared.WeaponsByName[def.name]
        if not rec or not has(f.weaponCategories, rec.category) then return false end
    end
    if (def.category == 'currency') then return false end
    return true
end

---Every catalog item on a shelf, sorted by label.
function S.Shelf(filter)
    local out = {}
    for name, def in pairs(LXRShared.Items) do
        if S.Matches(def, filter) then out[#out + 1] = def end
    end
    table.sort(out, function(a, b) return (a.label or a.name) < (b.label or b.name) end)
    return out
end

---The shelves of a store kind: { { label, items = { def… } }… } (empty shelves dropped).
function S.Shelves(kind)
    local out = {}
    for _, shelf in ipairs(Config.Shelves[kind] or {}) do
        local items = S.Shelf(shelf)
        if #items > 0 then out[#out + 1] = { label = shelf.label, items = items } end
    end
    return out
end

---Does a store of this kind buy this item.
function S.Buys(kind, def)
    for _, f in ipairs(Config.Buys[kind] or {}) do if S.Matches(def, f) then return true end end
    return false
end

---Retail price at a store: ledger value × store mark-up (× night mark-up when closed).
function S.Price(name, store, closed, drift)
    local v = LXRShared.ItemValue(name)
    local mult = (store and store.priceMult or 1) * (closed and Config.Trade.closedMult or 1) * (tonumber(drift) or 1)
    return LXRShared.Round(v * mult, 2)
end

---What a store pays for one unit of an owned item (quality from info).
function S.Offer(name, info, store)
    local q = info and tonumber(info.quality)
    -- durability 0–100 maps onto the catalog's 1–3 grade
    if q and q > 3 then q = q >= 67 and 3 or (q >= 34 and 2 or 1) end
    local v = LXRShared.ItemValue(name, q)
    return LXRShared.Round(v * Config.Trade.sellPct * (store and store.sellMult or 1), 2)
end

---Is the counter open at this hour (nil hours = always).
function S.Open(hour)
    local h = Config.Trade.openHours
    if not h then return true end
    if h.from <= h.to then return hour >= h.from and hour < h.to end
    return hour >= h.from or hour < h.to
end

function S.Store(id) for _, s in ipairs(Config.Stores) do if s.id == id then return s end end end
