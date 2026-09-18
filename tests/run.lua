--[[ ═══════════════════════════════════════════════════════════════════════════
     LXR-SHOPS — Offline tests: shelves over the catalog, prices, stores, locale parity
     Requires a sibling checkout of lxr-core (../lxr-core).
     Usage (from the lxr-shops folder):  lua tests/run.lua [--mock out.js en|ka]
     © 2026 iBoss21 / LXRCore — All Rights Reserved
     ═══════════════════════════════════════════════════════════════════════════ ]]

local CORE = os.getenv('LXR_CORE_PATH') or '../lxr-core'
package.path = CORE .. '/?.lua;' .. package.path
local ok = pcall(function() require('tests.lib.fxshim') end)
if not ok then print('lxr-core shim not found at ' .. CORE .. ' (set LXR_CORE_PATH)') os.exit(2) end
local Shim = require('tests.lib.fxshim')

for _, f in ipairs({ 'shared/main.lua', 'shared/locale.lua', 'locales/en.lua', 'config.lua', 'shared/catalog.lua', 'shared/items.lua', 'shared/prices.lua', 'shared/weapons.lua', 'shared/jobs.lua' }) do Shim.load(CORE .. '/' .. f) end
Config = nil
Locale = nil
Shim.load('shared/locale.lua')
Shim.load('locales/en.lua')
Shim.load('locales/ka.lua')
Shim.load('config.lua')
Shim.load('shared/rules.lua')
local S = LXRShops

local passed, failed = 0, 0
local function test(name, fn)
    local okT, err = xpcall(fn, debug.traceback)
    if okT then passed = passed + 1 print('  ^ ok   ' .. name) else failed = failed + 1 print('  x FAIL ' .. name .. '\n' .. err) end
end
local function eq(a, b, msg) if a ~= b then error((msg or 'eq') .. ': expected ' .. tostring(b) .. ' got ' .. tostring(a), 2) end end

print('lxr-shops offline tests')

test('every store kind has shelves or buys; every store has a clerk, coords and a known job', function()
    for _, st in ipairs(Config.Stores) do
        assert(Config.Shelves[st.kind] or Config.Buys[st.kind], st.id .. ' kind ' .. st.kind .. ' has no shelves')
        assert(st.clerk and st.coords and st.label, st.id .. ' incomplete')
        for job in pairs(st.jobs or {}) do assert(LXRShared.Jobs[job], st.id .. ' unknown job ' .. job) end
        assert(Config.Blips[st.kind] ~= nil or st.blip == false or st.kind == 'fence', st.id .. ' kind has no blip sprite')
    end
    local ids = {}
    for _, st in ipairs(Config.Stores) do assert(not ids[st.id], 'duplicate ' .. st.id) ids[st.id] = true end
end)

test('shelves are non-empty and legal where they say so', function()
    for kind, shelves in pairs(Config.Shelves) do
        local total = 0
        for _, sh in ipairs(S.Shelves(kind)) do
            total = total + #sh.items
            for _, def in ipairs(sh.items) do
                if kind ~= 'fence' then assert(def.legal ~= false, kind .. ' sells illegal ' .. def.name) end
                assert(def.category ~= 'currency')
            end
        end
        assert(total > 0, kind .. ' shelves are empty')
    end
    local gs = S.Shelves('gunsmith')
    local sidearms = gs[1].items
    for _, d in ipairs(sidearms) do local rec = LXRShared.WeaponsByName[d.name] assert(rec and (rec.category == 'revolver' or rec.category == 'pistol'), d.name) end
    local fence = S.Shelves('fence')[1].items
    for _, d in ipairs(fence) do assert(d.legal == false and d.name ~= 'bank_bag', d.name) end
end)

test('prices come from the ledger with the store mark-up; offers pay a share by quality', function()
    local val = S.Store('gen_valentine')
    local sd = S.Store('gen_saintdenis')
    eq(S.Price('bread', val), LXRShared.ItemValue('bread'))
    assert(S.Price('bread', sd) > S.Price('bread', val), 'Saint Denis is dearer')
    assert(S.Price('bread', val, true) > S.Price('bread', val), 'night mark-up')
    local full = S.Offer('weapon_revolver_cattleman', { quality = 100 }, val)
    local worn = S.Offer('weapon_revolver_cattleman', { quality = 20 }, val)
    assert(full > worn and worn > 0, 'quality matters: ' .. full .. ' / ' .. worn)
    assert(math.abs(full - LXRShared.ItemValue('weapon_revolver_cattleman') * Config.Trade.sellPct) < 0.01)
    assert(S.Buys('gunsmith', LXRShared.Items['weapon_revolver_cattleman']))
    assert(not S.Buys('saloon', LXRShared.Items['bread']))
    assert(S.Buys('butcher', LXRShared.Items[next(LXRShared.ItemsByCategory('meat'))] or { category = 'meat' }))
end)

test('hours', function()
    Config.Trade.openHours = nil
    assert(S.Open(3))
    Config.Trade.openHours = { from = 6, to = 22 }
    assert(S.Open(12) and not S.Open(23) and not S.Open(3))
    Config.Trade.openHours = { from = 20, to = 4 }
    assert(S.Open(23) and S.Open(2) and not S.Open(12))
    Config.Trade.openHours = nil
end)

test('locale parity + every kind labelled', function()
    local en, ka = Locale.Bundles.en, Locale.Bundles.ka
    local missing = {}
    for k in pairs(en) do if ka[k] == nil then missing[#missing + 1] = k end end
    eq(#missing, 0, 'ka missing: ' .. table.concat(missing, ', '))
    for kind in pairs(Config.Shelves) do assert(en['kind.' .. kind], 'kind label ' .. kind) end
end)

print(('%d passed, %d failed'):format(passed, failed))

if arg and arg[1] == '--mock' and arg[2] then
    Config.Lang = arg[3] or 'en'
    local st = S.Store('gen_valentine')
    local shelves = {}
    for _, sh in ipairs(S.Shelves('general')) do
        local items = {}
        for i, def in ipairs(sh.items) do items[#items + 1] = { name = def.name, label = def.label, description = def.description, category = def.category, price = S.Price(def.name, st), weight = def.weight, rarity = def.rarity, stock = (i % 7 == 0) and 0 or (12 + (i * 5) % 40) } end
        shelves[#shelves + 1] = { label = sh.label, items = items }
    end
    local sells = { { slot = 3, name = 'iron_ore', label = 'Iron Ore', amount = 12, offer = S.Offer('iron_ore', nil, st) }, { slot = 7, name = 'bream', label = 'Bream', amount = 2, offer = S.Offer('bream', { quality = 2 }, st), quality = 2 } }
    local data = { store = { id = st.id, label = st.label, kind = st.kind, priceMult = 1 }, shelves = shelves, sells = sells, cash = 23.40, purses = { cash = 23.40, bank = 140.00 }, accounts = { 'cash', 'bank' }, closed = false, maxPerPurchase = Config.Trade.maxPerPurchase }
    local f = assert(io.open(arg[2], 'w'))
    f:write('window.__LXR_MOCK__ = ' .. json.encode({ action = 'open', data = data, locale = Lang.bundle(), lang = Config.Lang, images = '/lxr-inventory/html/images/', brand = { name = 'The Land of Wolves', theme = 'night' } }) .. ';\n')
    f:close()
    print('mock written to ' .. arg[2])
end
os.exit(failed == 0 and 0 or 1)
