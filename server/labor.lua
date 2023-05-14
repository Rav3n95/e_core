--- @param playerId number (source)
--- @return number, nil |boolean, string success and, in case of an error, the reason as well
function getLabor(playerId)

    if not Config.systemMode.labor then

        return false, 'the_system_is_turned_off'
    end

    if not tonumber(playerId) or not ECO.meta[playerId] then

        return false, 'not_found_metadata'
    end

    return ECO.meta[playerId].labor.val
end

--- @param playerId number (source)
--- @param amount number of labor points
--- @return boolean success and, in case of an error, the reason as well
function setLabor(playerId, amount)

    if not Config.systemMode.labor then

        return false, 'the_system_is_turned_off'
    end

    if not tonumber(playerId) or not ECO.meta[playerId] then

        return false, 'not_found_metadata'
    end

    if not tonumber(amount) then

        return false, 'not_valid_amount'
    end

    ECO.meta[playerId].labor.val = settingLimits(amount, Config.laborLimit)
    ECO.meta[playerId].labor.time = os.time()

    syncRequest(playerId)

    return true
end

--- @param playerId number (source)
--- @param amount number of labor points to be removed
--- @return boolean success and, in case of an error, the reason as well
function removeLabor(playerId, amount)

    if not Config.systemMode.labor then

        return false, 'the_system_is_turned_off'
    end

    if not tonumber(playerId) or not ECO.meta[playerId] then

        return false, 'not_found_metadata'
    end

    if not tonumber(amount) then

        return false, 'not_valid_amount'
    end

    if ECO.meta[playerId].labor.val < 1 then

        return false, 'has_already_reached_the_limit'
    end

    ECO.meta[playerId].labor.val = settingLimits(ECO.meta[playerId].labor.val - amount, Config.laborLimit)
    ECO.meta[playerId].labor.time = os.time()

    syncRequest(playerId)

    return true
end

--- @param playerId number (source)
--- @param amount number of labor points to be added
--- @return boolean success and, in case of an error, the reason as well
function addLabor(playerId, amount)

    if not Config.systemMode.labor then

        return false, 'the_system_is_turned_off'
    end

    if not tonumber(playerId) or not ECO.meta[playerId] then

        return false, 'not_found_metadata'
    end

    if not tonumber(amount) then

        return false, 'not_valid_amount'
    end

    if ECO.meta[playerId].labor.val >= Config.laborLimit then

        return false, 'has_already_reached_the_limit'
    end

    ECO.meta[playerId].labor.val = settingLimits(ECO.meta[playerId].labor.val + amount, Config.laborLimit)
    ECO.meta[playerId].labor.time = os.time()

    syncRequest(playerId)

    return true
end

-----------------------
--- AUTO LABOR INCREASE
-----------------------

function laborIncrease()

    SetTimeout(Config.laborIncreaseTime * 60000, function()

        local timeStamp = os.time()

        for playerId, meta in pairs(ECO.meta) do

            meta.labor.time = timeStamp

            if (meta.labor and meta.labor.val < Config.laborLimit) then

                meta.labor.val = settingLimits(
                    meta.labor.val + Config.laborIncrease,
                    Config.laborLimit
                )

                TriggerClientEvent('e_core:sync', playerId, meta)
            end
        end

        laborIncrease()
    end)
end

if Config.systemMode.labor and

    tonumber(Config.laborIncreaseTime) and
    Config.laborIncreaseTime > 0 and

    tonumber(Config.laborIncrease) and
    Config.laborIncrease > 0 then

    laborIncrease()
end

-----------------
--- OFFLINE LABOR
-----------------
function addOfflineLabor(playerId)

    if not Config.systemMode.labor then

        return false
    end

    if type(Config.laborIncreaseOffline) ~= 'number' or Config.laborIncreaseOffline < 1 then

        return false
    end

    local increaseTime = Config.laborIncreaseTime * 60
    local elapsedTime = os.time() - ECO.meta[playerId].labor.time

    if elapsedTime < increaseTime then
        return 0
    end

    local multiplier = math.floor(elapsedTime / increaseTime)
    local offlineLabor = Config.laborIncreaseOffline * multiplier

    ECO.meta[playerId].labor.val = settingLimits(ECO.meta[playerId].labor.val + offlineLabor, Config.laborLimit)
end
