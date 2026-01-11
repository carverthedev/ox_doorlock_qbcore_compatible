local QBCore = exports['qb-core']:GetCoreObject()
local oxInventory = GetResourceState('ox_inventory'):find('start') and exports.ox_inventory

local function isAdmin(src)
    if Config.PlayerAceAuthorised and IsPlayerAceAllowed(src, 'command.doorlock') then
        return true
    end

    return QBCore.Functions.HasPermission(src, 'admin')
end

local function getGroupGrades(player)
    local groups = {}
    local playerData = player.PlayerData

    if not playerData then return groups end

    local job = playerData.job

    if job and job.name then
        groups[job.name] = job.grade and job.grade.level or 0
    end

    local gang = playerData.gang

    if gang and gang.name then
        groups[gang.name] = gang.grade and gang.grade.level or 0
    end

    return groups
end

function GetPlayer(src)
    return QBCore.Functions.GetPlayer(src)
end

function GetCharacterId(player)
    if not player then return end

    local playerData = player.PlayerData
    return playerData and playerData.citizenid
end

function IsPlayerInGroup(player, filter)
    if not player then return end

    local playerData = player.PlayerData
    local src = playerData and playerData.source or player.source
    local groups = getGroupGrades(player)
    local filterType = type(filter)

    local function checkGroup(name, requiredGrade)
        if name == 'admin' and src and isAdmin(src) then
            return name, 0
        end

        local grade = groups[name]

        if grade == nil then return end

        if requiredGrade and requiredGrade > grade then return end

        return name, grade
    end

    if filterType == 'string' then
        return checkGroup(filter)
    end

    local tableType = table.type(filter)

    if tableType == 'array' then
        for i = 1, #filter do
            local result = checkGroup(filter[i])

            if result then
                return result
            end
        end

        return
    end

    if tableType == 'hash' then
        for name, requiredGrade in pairs(filter) do
            local result = checkGroup(name, requiredGrade)

            if result then
                return result
            end
        end
    end
end

function RemoveItem(playerId, item, slot)
    local player = GetPlayer(playerId)

    if not player then return end

    if oxInventory then
        oxInventory:RemoveItem(playerId, item, 1, nil, slot)
        return
    end

    player.Functions.RemoveItem(item, 1, slot)
end

---@param player table
---@param items string[] | { name: string, remove?: boolean, metadata?: string }[]
---@param removeItem? boolean
---@return string?
function DoesPlayerHaveItem(player, items, removeItem)
    if not player then return end

    local playerId = player.PlayerData and player.PlayerData.source or player.source

    for i = 1, #items do
        local item = items[i]
        local itemName = item.name or item
        local metadataType = item.metadata or item.type

        if oxInventory then
            local results = oxInventory:Search(playerId, 'slots', itemName)

            if results then
                for j = 1, #results do
                    local slot = results[j]

                    if slot.count and slot.count > 0 and (not metadataType or slot.metadata and slot.metadata.type == metadataType) then
                        if removeItem or item.remove then
                            oxInventory:RemoveItem(playerId, itemName, 1, nil, slot.slot)
                        end

                        return itemName
                    end
                end
            end
        else
            local data = player.Functions.GetItemByName(itemName)

            if data and data.amount and data.amount > 0 then
                local itemType = (data.info and data.info.type) or (data.metadata and data.metadata.type)

                if not metadataType or itemType == metadataType then
                    if removeItem or item.remove then
                        player.Functions.RemoveItem(itemName, 1, data.slot)
                    end

                    return itemName
                end
            end
        end
    end
end