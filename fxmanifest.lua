--[[
    ██╗     ██╗  ██╗██████╗        ███████╗██╗  ██╗ ██████╗ ██████╗ ███████╗
    ██║     ╚██╗██╔╝██╔══██╗       ██╔════╝██║  ██║██╔═══██╗██╔══██╗██╔════╝
    ██║      ╚███╔╝ ██████╔╝█████╗ ███████╗███████║██║   ██║██████╔╝███████╗
    ██║      ██╔██╗ ██╔══██╗╚════╝ ╚════██║██╔══██║██║   ██║██╔═══╝ ╚════██║
    ███████╗██╔╝ ██╗██║  ██║       ███████║██║  ██║╚██████╔╝██║     ███████║
    ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝       ╚══════╝╚═╝  ╚═╝ ╚═════╝ ╚═╝     ╚══════╝

    🐺 LXR Shops — Dynamic Multi-Framework Shop System

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

fx_version 'cerulean'
game       'rdr3'

rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'

name        'lxr-shops'
author      'iBoss21 / The Lux Empire'
description '🐺 LXR Shops - Dynamic Multi-Framework Shop System | wolves.land'
version     '1.0.2'

shared_script 'config.lua'
server_script 'server/*.lua'
client_script 'client/*.lua'

dependencies {
    'lxr-inventory'
}

lua54 'yes'
