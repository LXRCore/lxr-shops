--[[
    ██╗     ██╗  ██╗██████╗        ███████╗██╗  ██╗ ██████╗ ██████╗ ███████╗
    ██║     ╚██╗██╔╝██╔══██╗       ██╔════╝██║  ██║██╔═══██╗██╔══██╗██╔════╝
    ██║      ╚███╔╝ ██████╔╝█████╗ ███████╗███████║██║   ██║██████╔╝███████╗
    ██║      ██╔██╗ ██╔══██╗╚════╝ ╚════██║██╔══██║██║   ██║██╔═══╝ ╚════██║
    ███████╗██╔╝ ██╗██║  ██║       ███████║██║  ██║╚██████╔╝██║     ███████║
    ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝       ╚══════╝╚═╝  ╚═╝ ╚═════╝ ╚═╝     ╚══════╝

    🐺 LXR Shops — Dynamic Multi-Framework Shop System

    This configuration file controls store locations, product catalogues, and
    framework settings for the lxr-shops resource. General-store, saloon,
    gunsmith and farming-supply shops are all managed here.

    ═══════════════════════════════════════════════════════════════════════════════
    SERVER INFORMATION
    ═══════════════════════════════════════════════════════════════════════════════

    Server:      The Land of Wolves 🐺
    Tagline:     Georgian RP 🇬🇪 | მგლების მიწა - რჩეულთა ადგილი!
    Description: ისტორია ცოცხლდება აქ! (History Lives Here!)
    Type:        Serious Hardcore Roleplay
    Access:      Discord & Whitelisted

    Developer:   iBoss21 / The Lux Empire
    Website:     https://www.wolves.land
    Discord:     https://discord.gg/CrKcWdfd3A
    GitHub:      https://github.com/iBoss21
    Store:       https://theluxempire.tebex.io
    Server:      https://servers.redm.net/servers/detail/8gj7eb

    ═══════════════════════════════════════════════════════════════════════════════

    Version: 1.0.2

    Framework Support:
    - LXR Core  (Primary)
    - RSG Core  (Primary)
    - VORP Core (Supported / Legacy)
    - RedEM:RP  (Optional)
    - QBR Core  (Optional)
    - QR Core   (Optional)
    - Standalone (Fallback)

    ═══════════════════════════════════════════════════════════════════════════════
    CREDITS
    ═══════════════════════════════════════════════════════════════════════════════

    Script Author: iBoss21 / The Lux Empire for The Land of Wolves

    © 2026 iBoss21 / The Lux Empire | wolves.land | All Rights Reserved
]]

-- ═══════════════════════════════════════════════════════════════════════════════
-- 🐺 RESOURCE NAME PROTECTION - RUNTIME CHECK
-- ═══════════════════════════════════════════════════════════════════════════════

local REQUIRED_RESOURCE_NAME = "lxr-shops"
local currentResourceName = GetCurrentResourceName()

if currentResourceName ~= REQUIRED_RESOURCE_NAME then
    error(string.format([[

        ═══════════════════════════════════════════════════════════════════════════════
        ❌ CRITICAL ERROR: RESOURCE NAME MISMATCH ❌
        ═══════════════════════════════════════════════════════════════════════════════

        Expected: %s
        Got: %s

        This resource is branded and must maintain the correct name.
        Rename the folder to "%s" to continue.

        🐺 wolves.land - The Land of Wolves

        ═══════════════════════════════════════════════════════════════════════════════

    ]], REQUIRED_RESOURCE_NAME, currentResourceName, REQUIRED_RESOURCE_NAME))
end

Config = {}

-- ████████████████████████████████████████████████████████████████████████████████
-- ████████████████████████ SERVER BRANDING & INFO ████████████████████████████████
-- ████████████████████████████████████████████████████████████████████████████████

Config.ServerInfo = {
    name        = 'The Land of Wolves 🐺',
    tagline     = 'Georgian RP 🇬🇪 | მგლების მიწა - რჩეულთა ადგილი!',
    description = 'ისტორია ცოცხლდება აქ!', -- History Lives Here!
    type        = 'Serious Hardcore Roleplay',
    access      = 'Discord & Whitelisted',

    -- Contact & Links
    website       = 'https://www.wolves.land',
    discord       = 'https://discord.gg/CrKcWdfd3A',
    github        = 'https://github.com/iBoss21',
    store         = 'https://theluxempire.tebex.io',
    serverListing = 'https://servers.redm.net/servers/detail/8gj7eb',

    -- Developer Info
    developer = 'iBoss21 / The Lux Empire',

    -- Tags
    tags = { 'RedM', 'Georgian', 'SeriousRP', 'Whitelist', 'Shops', 'Economy', 'Survival' }
}

-- ████████████████████████████████████████████████████████████████████████████████
-- ████████████████████████ FRAMEWORK CONFIGURATION ███████████████████████████████
-- ████████████████████████████████████████████████████████████████████████████████

--[[
    Framework Priority (in order):
    1. LXR-Core  (Primary)
    2. RSG-Core  (Primary)
    3. VORP Core (Supported)
    4. RedEM:RP  (Optional - if detected)
    5. QBR-Core  (Optional - if detected)
    6. QR-Core   (Optional - if detected)
    7. Standalone (Fallback)
]]

Config.Framework = 'auto' -- 'auto' or manual: 'lxr-core', 'rsg-core', 'vorp_core', 'redem_roleplay', 'qbr-core', 'qr-core', 'standalone'

-- Framework-specific settings
Config.FrameworkSettings = {
    ['lxr-core'] = {
        resource  = 'lxr-core',
        inventory = 'lxr-inventory',
        -- Inventory open event
        inventoryEvent = 'inventory:server:OpenInventory',
        -- Event naming convention
        events = {
            server   = 'lxr-shops:server:%s',
            client   = 'lxr-shops:client:%s',
            callback = 'lxr-shops:server:%s'
        }
    },
    ['rsg-core'] = {
        resource  = 'rsg-core',
        inventory = 'rsg-inventory',
        inventoryEvent = 'inventory:server:OpenInventory',
        events = {
            server   = 'lxr-shops:server:%s',
            client   = 'lxr-shops:client:%s',
            callback = 'lxr-shops:server:%s'
        }
    },
    ['vorp_core'] = {
        resource  = 'vorp_core',
        inventory = 'vorp_inventory-lua',
        inventoryEvent = 'vorpinventory:openShop',
        events = {
            server = 'lxr-shops:server:%s',
            client = 'lxr-shops:client:%s'
        }
    },
    ['redem_roleplay'] = {
        resource  = 'redem_roleplay',
        inventory = 'redem_inventory',
        inventoryEvent = 'inventory:server:OpenInventory',
        events = {
            server = 'lxr-shops:server:%s',
            client = 'lxr-shops:client:%s'
        }
    },
    ['qbr-core'] = {
        resource  = 'qbr-core',
        inventory = 'qbr-inventory',
        inventoryEvent = 'inventory:server:OpenInventory',
        events = {
            server = 'lxr-shops:server:%s',
            client = 'lxr-shops:client:%s'
        }
    },
    ['qr-core'] = {
        resource  = 'qr-core',
        inventory = 'qr-inventory',
        inventoryEvent = 'inventory:server:OpenInventory',
        events = {
            server = 'lxr-shops:server:%s',
            client = 'lxr-shops:client:%s'
        }
    },
    ['standalone'] = {
        resource       = 'standalone',
        inventory      = 'none',
        inventoryEvent = 'none',
        events         = {}
    }
}

-- ████████████████████████████████████████████████████████████████████████████████
-- ████████████████████████ SHOP PRODUCTS █████████████████████████████████████████
-- ████████████████████████████████████████████████████████████████████████████████

-- Products available in different stores
Config.Products = {
    ["normal"] = {
        [1] = { name = "water",        price = 2,   amount = 50, info = {}, type = "item" },
        [2] = { name = "bread",        price = 2,   amount = 50, info = {}, type = "item" },
        [3] = { name = "apple",        price = 1,   amount = 50, info = {}, type = "item" },
        [4] = { name = "chocolate",    price = 2,   amount = 50, info = {}, type = "item" }
    },
    ["saloon"] = {
        [1] = { name = "beer",         price = 7,   amount = 50,  info = {}, type = "item" },
        [2] = { name = "whiskey",      price = 10,  amount = 50,  info = {}, type = "item" },
        [3] = { name = "vodka",        price = 12,  amount = 50,  info = {}, type = "item" },
        [4] = { name = "coffee",       price = 5,   amount = 500, info = {}, type = "item" }
    },
    ["weapons"] = {
        [1] = { name = "weapon_revolver_cattleman", price = 250, amount = 250, info = {}, type = "item", requiresLicense = true },
        [2] = { name = "ammo_revolver",            price = 15,  amount = 250, info = {}, type = "item" }
    },
    ["farming"] = {
        [1]  = { name = 'seed_corn',             price = 0.10, amount = 10, info = {}, type = "item" },
        [2]  = { name = 'seed_coffee',           price = 0.20, amount = 10, info = {}, type = "item" },
        [3]  = { name = 'seed_tobacco',          price = 0.30, amount = 10, info = {}, type = "item" },
        [4]  = { name = 'seed_american_ginseng', price = 0.40, amount = 50, info = {}, type = "item" },
        [5]  = { name = 'seed_alaskan_ginseng',  price = 0.45, amount = 50, info = {}, type = "item" },
        [6]  = { name = 'seed_black_berry',      price = 0.50, amount = 50, info = {}, type = "item" },
        [7]  = { name = 'seed_bay_bolete',       price = 0.55, amount = 50, info = {}, type = "item" },
        [8]  = { name = 'seed_black_currant',    price = 0.60, amount = 50, info = {}, type = "item" },
        [9]  = { name = 'seed_huckle_berry',     price = 0.65, amount = 50, info = {}, type = "item" },
        [10] = { name = 'seed_mint',             price = 0.70, amount = 50, info = {}, type = "item" }
    }
}

-- ████████████████████████████████████████████████████████████████████████████████
-- ████████████████████████ SHOP LOCATIONS ████████████████████████████████████████
-- ████████████████████████████████████████████████████████████████████████████████

-- Store locations and their product mixes
-- Format: { name = 'Store Name', products = 'Product Mix', coords = vector3(x, y, z), blip = Blip ID }
Config.Locations = {
    -- ── General Stores ──────────────────────────────────────────────────────────
    { name = 'Rhodes General Store',      products = "normal",  coords = vector3(1328.99,  -1293.28, 77.02),  blip = 1475879922 },
    { name = 'Valentine General Store',   products = "normal",  coords = vector3(-322.433,  803.797, 117.9),  blip = 1475879922 },
    { name = 'Strawberry General Store',  products = "normal",  coords = vector3(-1791.49,  -386.87, 160.3),  blip = 1475879922 },
    { name = 'Annesburg General Store',   products = "normal",  coords = vector3(2931.350,  1365.94,  45.19), blip = 1475879922 },
    { name = 'Saint Denis General Store', products = "normal",  coords = vector3(2859.81,  -1200.37,  49.59), blip = 1475879922 },
    { name = 'Tumbleweed General Store',  products = "normal",  coords = vector3(-5487.6,  -2938.54,  -0.38), blip = 1475879922 },
    { name = 'Armadillo General Store',   products = "normal",  coords = vector3(-3685.6,   -2622.6, -13.43), blip = 1475879922 },
    { name = 'Blackwater General Store',  products = "normal",  coords = vector3(-785.18,  -1323.83,  43.88), blip = 1475879922 },
    { name = 'Van Horn General Store',    products = "normal",  coords = vector3(3027.030,   561.00,  44.720), blip = 1475879922 },

    -- ── Gunsmiths ────────────────────────────────────────────────────────────────
    { name = 'Valentine Gunsmith',        products = "weapons", coords = vector3(-281.970,   781.09, 119.52), blip = -145868367 },
    { name = 'Tumbleweed Gunsmith',       products = "weapons", coords = vector3(-5508.14, -2964.33,  -0.62), blip = -145868367 },
    { name = 'Saint Denis Gunsmith',      products = "weapons", coords = vector3(2716.42,  -1285.42,  49.63), blip = -145868367 },
    { name = 'Rhodes Gunsmith',           products = "weapons", coords = vector3(1322.67,  -1323.16,  77.88), blip = -145868367 },
    { name = 'Annesburg Gunsmith',        products = "weapons", coords = vector3(2946.50,   1319.530, 44.82), blip = -145868367 },

    -- ── Saloons ──────────────────────────────────────────────────────────────────
    { name = 'Valentine Saloon',          products = "saloon",  coords = vector3(-313.26,   805.220, 118.98), blip = 1879260108 },
    { name = 'Tumbleweed Saloon',         products = "saloon",  coords = vector3(-5518.35,  -2906.4,  -1.75), blip = 1879260108 },
    { name = 'Armadillo Saloon',          products = "saloon",  coords = vector3(-3699.7,   -2594.5, -13.31), blip = 1879260108 },
    { name = 'Blackwater Saloon',         products = "saloon",  coords = vector3(-817.66,  -1319.43,  43.67), blip = 1879260108 },
    { name = 'Rhodes Saloon',             products = "saloon",  coords = vector3(1340.14,  -1374.99,  80.48), blip = 1879260108 },
    { name = 'Saint Denis Saloon',        products = "saloon",  coords = vector3(2792.55,  -1168.14,  47.93), blip = 1879260108 },
    { name = 'Van Horn Saloon',           products = "saloon",  coords = vector3(2947.580,   528.070, 45.33),  blip = 1879260108 },

    -- ── Farming Supplies ─────────────────────────────────────────────────────────
    { name = 'Farming Supplies',          products = "farming", coords = vector3(2825.64,  -1318.15,  46.76), blip = 819673798 }
}

-- ████████████████████████████████████████████████████████████████████████████████
-- ████████████████████████ DEBUG SETTINGS ████████████████████████████████████████
-- ████████████████████████████████████████████████████████████████████████████████

Config.Debug = false -- Enable debug prints and extra logging

