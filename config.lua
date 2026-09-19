--[[
    ██╗     ██╗  ██╗██████╗       ███████╗██╗  ██╗ ██████╗ ██████╗ ███████╗
    ██║     ╚██╗██╔╝██╔══██╗      ██╔════╝██║  ██║██╔═══██╗██╔══██╗██╔════╝
    ██║      ╚███╔╝ ██████╔╝█████╗███████╗███████║██║   ██║██████╔╝███████╗
    ██║      ██╔██╗ ██╔══██╗╚════╝╚════██║██╔══██║██║   ██║██╔═══╝ ╚════██║
    ███████╗██╔╝ ██╗██║  ██║      ███████║██║  ██║╚██████╔╝██║     ███████║
    ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝      ╚══════╝╚═╝  ╚═╝ ╚═════╝ ╚═╝     ╚══════╝

    LXR Core - Shops

    Counters across the map. Every price is the core ledger's 1899 value
    times the store's mark-up; every shelf is a filter over the catalog
    (categories, tags, names, legality) so a new catalog item lands on the
    right shelf without touching this file. Stock can be infinite or limited
    with restocking; selling pays a share of the ledger value by quality.

    Brand:       LXRCore — Lux Empire eXperience RedM Core
    Product:     wolves.land / The Land of Wolves
    Developer:   iBoss21 / LXRCore
    Website:     https://www.lxrcore.com
    Discord:     https://discord.gg/GAhk8cgXe9
    GitHub:      https://github.com/LXRCore

    Version: 3.0.0
    Performance Target: 0.00 ms idle (clerks are lxr-interact targets; nothing runs until a counter opens)

    © 2026 iBoss21 / LXRCore | lxrcore.com | All Rights Reserved
]]

Config = Config or {}

-- ████████████████████████████████████████████████████████████████████████████████
-- ████████████████████████ LANGUAGE ██████████████████████████████████████████████
-- ████████████████████████████████████████████████████████████████████████████████
Config.Lang = 'en'

-- ████████████████████████████████████████████████████████████████████████████████
-- ████████████████████████ TRADE ═════════════════════════════════════════════════
-- ████████████████████████████████████████████████████████████████████████████████
Config.Trade = {
    account = 'cash',            -- what the counter takes by default
    accounts = { 'cash', 'bank' }, -- purses the counter accepts; the player picks one at the till
    images = 'nui://lxr-inventory/html/images/', -- item pictures (the inventory's icon set)
    sellPct = 0.45,              -- a store pays this share of the ledger value (by quality) when buying from players
    maxPerPurchase = 50,
    openHours = nil,             -- { from = 6, to = 22 } closes counters at night (nil = always open)
    closedMult = 1.25,           -- when open outside hours is allowed, the night mark-up
    nightOpen = true,
    receipts = true,             -- lxr:shops:bought / sold carry the receipt for ledgers and logs
}

-- prices that move: every unit bought lifts that store's price for the item, every unit sold to the store lowers it,
-- and the drift eases back toward the ledger price by the hour (persisted in lxr_shops_drift)
Config.Pricing = {
    dynamic = false,
    upPerUnit = 0.02,            -- +2 % of the ledger price per unit bought
    downPerUnit = 0.02,          -- −2 % per unit sold to the store
    min = 0.5, max = 3.0,        -- the multiplier never leaves this range
    easePerHour = 0.05,          -- the multiplier moves this much back toward 1.0 every hour
}

-- limited stock: quantities live per shop item and restock on a timer (persisted)
Config.Stock = {
    limited = false,             -- false: every shelf is bottomless
    defaultQty = 25,
    restockEveryMs = 3600000,    -- one hour
    restockTo = 25,
    persist = true,              -- lxr_shops_stock
}

-- ████████████████████████████████████████████████████████████████████████████████
-- ████████████████████████ SHELVES ═══════════════════════════════════════════════
-- ████████████████████████████████████████████████████████████████████████████████
-- A shelf is a filter over the core catalog. Fields (all optional, all combine with AND):
--   categories = { 'food', 'drink' }     tags = { 'weapon_care' }     names = { 'bread' }
--   exclude = { 'ammo_arrow_dynamite' }  legal = true|false|nil       rarityMax = 'uncommon'
-- `buys` uses the same shape and lists what the store purchases from players.
Config.Shelves = {
    general = {
        { label = 'Provisions', categories = { 'food', 'drink', 'alcohol', 'tobacco' }, legal = true },
        { label = 'Medicine',   categories = { 'medical', 'herb' }, legal = true, rarityMax = 'uncommon' },
        { label = 'Tools',      categories = { 'tool', 'kit', 'camp', 'fishing', 'wagon' }, legal = true, rarityMax = 'uncommon' },
        { label = 'Materials',  categories = { 'material', 'component' }, legal = true, rarityMax = 'uncommon' },
        { label = 'Horse',      categories = { 'horse', 'tack' }, legal = true, rarityMax = 'uncommon' },
        { label = 'Sundries',   categories = { 'personal', 'document', 'misc' }, legal = true, rarityMax = 'uncommon' },
    },
    gunsmith = {
        { label = 'Sidearms',   categories = { 'weapon' }, weaponCategories = { 'revolver', 'pistol' }, legal = true, rarityMax = 'uncommon' },
        { label = 'Long arms',  categories = { 'weapon' }, weaponCategories = { 'repeater', 'rifle', 'sniper', 'shotgun', 'bow' }, legal = true, rarityMax = 'uncommon' },
        { label = 'Blades',     categories = { 'weapon' }, weaponCategories = { 'melee', 'thrown' }, legal = true, rarityMax = 'uncommon' },
        { label = 'Cartridges', categories = { 'ammo' }, legal = true },
        { label = 'Gun care',   tags = { 'weapon_care' } },
    },
    saloon = {
        { label = 'Drinks',     categories = { 'drink', 'alcohol' }, legal = true },
        { label = 'Food',       categories = { 'food' }, legal = true },
        { label = 'Tobacco',    categories = { 'tobacco' }, legal = true },
    },
    doctor = {
        { label = 'Medicine',   categories = { 'medical' }, legal = true },
        { label = 'Herbs',      categories = { 'herb' }, legal = true },
    },
    butcher = {
        { label = 'Meat',       categories = { 'meat' }, legal = true },
    },
    fence = {
        { label = 'Under the counter', legal = false, exclude = { 'bank_bag', 'strongbox' } },
    },
}

-- what each kind of store buys from players
Config.Buys = {
    general  = { { categories = { 'material', 'component', 'herb', 'collectible', 'fishing' }, legal = true }, { tags = { 'vegetable', 'fruit' }, legal = true } },   -- produce from lxr-farming
    gunsmith = { { categories = { 'weapon', 'ammo' }, legal = true } },
    saloon   = {},
    doctor   = { { categories = { 'herb' } } },
    butcher  = { { categories = { 'meat', 'hunting' } } },
    fence    = { { legal = false }, { categories = { 'valuable', 'contraband' } } },
    trapper  = { { categories = { 'hunting' } } },
}

-- ████████████████████████████████████████████████████████████████████████████████
-- ████████████████████████ THE STORES ════════════════════════════════════════════
-- ████████████████████████████████████████████████████████████████████████████████
-- kind → shelves + buys; priceMult on the ledger value; clerk = ped model at the counter;
-- jobs = { bank = 0 } locks the counter to a job (staff stores); sells = false for buy-only counters.
Config.Stores = {
    -- general stores
    { id = 'gen_valentine',  kind = 'general', label = 'Valentine General Store',   coords = vector3(-322.43, 803.80, 117.90), heading = 96.0,  clerk = 'u_m_m_valgenstoreowner_01', blip = true },
    { id = 'gen_rhodes',     kind = 'general', label = 'Rhodes General Store',      coords = vector3(1328.99, -1293.28, 77.02), heading = 132.0, clerk = 'u_m_m_rhdgenstoreowner_01', blip = true },
    { id = 'gen_strawberry', kind = 'general', label = 'Strawberry General Store',  coords = vector3(-1791.49, -386.87, 160.30), heading = 130.0, clerk = 'u_m_m_strgenstoreowner_01', blip = true, priceMult = 1.05 },
    { id = 'gen_annesburg',  kind = 'general', label = 'Annesburg General Store',   coords = vector3(2931.35, 1365.94, 45.19), heading = 20.0,  clerk = 'u_m_m_bwmstablehand_01', blip = true, priceMult = 1.10 },
    { id = 'gen_saintdenis', kind = 'general', label = 'Saint Denis General Store', coords = vector3(2859.81, -1200.37, 49.59), heading = 275.0, clerk = 'u_m_m_sdgenstoreowner_01', blip = true, priceMult = 1.15 },
    { id = 'gen_tumbleweed', kind = 'general', label = 'Tumbleweed General Store',  coords = vector3(-5487.60, -2938.54, -0.38), heading = 350.0, clerk = 'u_m_m_tumgenstoreowner_01', blip = true, priceMult = 1.10 },
    { id = 'gen_armadillo',  kind = 'general', label = 'Armadillo General Store',   coords = vector3(-3685.60, -2622.60, -13.43), heading = 190.0, clerk = 'u_m_m_armgenstoreowner_01', blip = true, priceMult = 1.10 },
    { id = 'gen_blackwater', kind = 'general', label = 'Blackwater General Store',  coords = vector3(-785.18, -1323.83, 43.88), heading = 275.0, clerk = 'u_m_m_bwmgenstoreowner_01', blip = true, priceMult = 1.10 },
    { id = 'gen_vanhorn',    kind = 'general', label = 'Van Horn General Store',    coords = vector3(3027.03, 561.00, 44.72), heading = 100.0, clerk = 'u_m_m_vhtgenstoreowner_01', blip = true, priceMult = 1.05 },
    -- gunsmiths (repairs and parts are lxr-weapons; these sell)
    { id = 'gun_valentine',  kind = 'gunsmith', label = 'Valentine Gunsmith',   coords = vector3(-281.97, 781.09, 119.52), heading = 270.0, clerk = 'u_m_m_valgunsmith_01', blip = true },
    { id = 'gun_rhodes',     kind = 'gunsmith', label = 'Rhodes Gunsmith',      coords = vector3(1322.67, -1323.16, 77.88), heading = 90.0,  clerk = 'u_m_m_rhdgunsmith_01', blip = true },
    { id = 'gun_saintdenis', kind = 'gunsmith', label = 'Saint Denis Gunsmith', coords = vector3(2716.42, -1285.42, 49.63), heading = 180.0, clerk = 'u_m_m_sdgunsmith_01', blip = true, priceMult = 1.15 },
    { id = 'gun_tumbleweed', kind = 'gunsmith', label = 'Tumbleweed Gunsmith',  coords = vector3(-5508.14, -2964.33, -0.62), heading = 90.0, clerk = 'u_m_m_tumgunsmith_01', blip = true, priceMult = 1.10 },
    { id = 'gun_annesburg',  kind = 'gunsmith', label = 'Annesburg Gunsmith',   coords = vector3(2946.50, 1319.53, 44.82), heading = 260.0, clerk = 'u_m_m_anngunsmith_01', blip = true, priceMult = 1.10 },
    -- saloons
    { id = 'sal_valentine',  kind = 'saloon', label = 'Smithfield\'s Saloon',    coords = vector3(-313.26, 805.22, 118.98), heading = 190.0, clerk = 'u_m_m_valbartender_01', blip = true },
    { id = 'sal_rhodes',     kind = 'saloon', label = 'Rhodes Parlour House',    coords = vector3(1340.14, -1374.99, 80.48), heading = 80.0,  clerk = 'u_m_m_rhdbartender_01', blip = true },
    { id = 'sal_saintdenis', kind = 'saloon', label = 'Doyle\'s Tavern',         coords = vector3(2792.55, -1168.14, 47.93), heading = 20.0,  clerk = 'u_m_m_sdbartender_01', blip = true, priceMult = 1.20 },
    { id = 'sal_blackwater', kind = 'saloon', label = 'Blackwater Saloon',       coords = vector3(-817.66, -1319.43, 43.67), heading = 275.0, clerk = 'u_m_m_bwmbartender_01', blip = true, priceMult = 1.10 },
    { id = 'sal_tumbleweed', kind = 'saloon', label = 'Tumbleweed Saloon',       coords = vector3(-5518.35, -2906.40, -1.75), heading = 350.0, clerk = 'u_m_m_tumbartender_01', blip = true },
    { id = 'sal_armadillo',  kind = 'saloon', label = 'Armadillo Saloon',        coords = vector3(-3699.70, -2594.50, -13.31), heading = 190.0, clerk = 'u_m_m_armbartender_01', blip = true },
    { id = 'sal_vanhorn',    kind = 'saloon', label = 'Van Horn Saloon',         coords = vector3(2947.58, 528.07, 45.33), heading = 100.0, clerk = 'u_m_m_vhtbartender_01', blip = true },
    -- doctors' counters (treatment is lxr-doctor; these sell)
    { id = 'doc_valentine',  kind = 'doctor', label = 'Valentine Doctor',        coords = vector3(-288.62, 807.47, 119.38), heading = 275.0, clerk = 'u_m_m_valdoctor_01', blip = true },
    { id = 'doc_saintdenis', kind = 'doctor', label = 'Saint Denis Doctor',      coords = vector3(2724.25, -1234.54, 50.37), heading = 90.0,  clerk = 'u_m_m_sddoctor_01', blip = true, priceMult = 1.15 },
    -- butchers buy meat and pelts
    { id = 'but_valentine',  kind = 'butcher', label = 'Valentine Butcher',      coords = vector3(-355.75, 789.03, 116.18), heading = 100.0, clerk = 'u_m_m_valbutcher_01', blip = true, sells = false },
    { id = 'but_saintdenis', kind = 'butcher', label = 'Saint Denis Butcher',    coords = vector3(2750.11, -1291.68, 49.59), heading = 60.0,  clerk = 'u_m_m_sdbutcher_01', blip = true, sells = false },
    -- the fence: under the counter, buys what nobody else will
    { id = 'fence_emerald',  kind = 'fence', label = 'Emerald Station Fence',    coords = vector3(1522.66, 439.72, 90.68), heading = 40.0, clerk = 'u_m_m_emrfarmhand_01', blip = false, priceMult = 1.5 },
}

-- blip sprites per kind
Config.Blips = {
    general = 'blip_shop_store', gunsmith = 'blip_shop_gunsmith', saloon = 'blip_shop_saloon', doctor = 'blip_shop_doctor', butcher = 'blip_shop_butcher', fence = nil, trapper = 'blip_shop_trapper',
}

-- ████████████████████████████████████████████████████████████████████████████████
-- ████████████████████████ SECURITY ══════════════════════════════════════════════
-- ████████████████████████████████████████████████████████████████████████████████
Config.Security = {
    rateLimit = { windowMs = 2000, burst = 10 },
    maxDistance = 4.0,
    promptDistance = 2.5,
}

-- ████████████████████████████████████████████████████████████████████████████████
-- ████████████████████████ DEBUG ═════════════════════════════════════════════════
-- ████████████████████████████████████████████████████████████████████████████████
Config.Debug = { printBanner = true, log = false }
