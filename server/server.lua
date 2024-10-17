RegisterNetEvent('lxr-shops:server:UpdateShopItems', function(shopType, slot, amount)
    Config.Products[shopType][slot].amount -= amount
    if Config.Products[shopType][slot].amount <= 0 then
        Config.Products[shopType][slot].amount = 0
    end
    TriggerClientEvent('lxr-shops:client:SetShopItems', -1, shopType, Config.Products[shopType])
end)

RegisterNetEvent('lxr-shops:server:RestockShopItems', function(shopType)
    if Config.Products[shopType] ~= nil then
        local randAmount = math.random(10, 50)
        for k, v in pairs(Config.Products[shopType]) do
            Config.Products[shopType][k].amount += randAmount
        end
        TriggerClientEvent('lxr-shops:client:RestockShopItems', -1, shopType, randAmount)
    end
end)

exports['lxr-core']:CreateCallback('lxr-shops:server:getLicenseStatus', function(source, cb)
    local src = source
    local Player = exports['lxr-core']:GetPlayer(src)
    local licenseTable = Player.PlayerData.metadata["licences"]

    if licenseTable.weapon then
        cb(true)
    else
        cb(false)
    end
end)
