---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by Ekhion.
--- DateTime: 2023. 04. 16. 12:58
---

local hf = hf

function sharedGlobalFunctions()

    local self = {}

    ---Determines the weight of items in the inventory
    ---@param playerData table
    ---@return number total weight
    function self.getInventoryWeight(playerData)

        if OX_INVENTORY and type(playerData.weight) == 'number' then

            return playerData.weight
        end

        local weight, count = 0
        local multiply = not OX_INVENTORY
        local inventory = eCore.getInventory(playerData)
        local countIdx = Config.inventoryIdx.count

        if not hf.isPopulatedTable(inventory) then
            return 0
        end

        for _, item in pairs(inventory) do

            count = multiply and item[countIdx] or 1
            weight = weight + item.weight * count
        end

        return weight
    end

    ---Returns true or false (and reason) depending if the inventory can swapping the specified item
    ---@param swappingItems table { elements: {name: string, amount: number, metadata: table} } e.g: recipe ingredients
    ---@param item table {name: string, amount: number, metadata: table}
    ---@return boolean, string
    function self.canSwapItems(swappingItems, itemData, playerData)

        local inventory = eCore.getInventory(playerData)
        local freeSlots = self.countFreeSlots(inventory)
        local requiredSlot = 0
        local capacity = INVENTORY_CONFIG.MAX_WEIGHT - self.getInventoryWeight(playerData)
        local itemWeight = self.getItemWeight(itemData.name, itemData.metadata) * itemData.amount

        if REGISTERED_ITEMS[itemData.name:lower()].isUnique then

            requiredSlot = itemData.amount
        else

            requiredSlot = self.getFirstSlotByItem(inventory, itemData.name) and 0 or 1
        end

        -- check
        if itemWeight <= capacity and requiredSlot <= freeSlots then

            return true
        end

        -- swapping items calculate
        local amountToRemove, weight = 0, 0
        local nameIdx, countIdx = Config.inventoryIdx.name, Config.inventoryIdx.count

        for _, swapItem in pairs(swappingItems) do

            amountToRemove = swapItem.amount
            weight = self.getItemWeight(swapItem.name, swapItem.metadata)

            if REGISTERED_ITEMS[swapItem.name:lower()].isUnique then

                freeSlots = freeSlots + swapItem.amount
                capacity = capacity + (weight * swapItem.amount)
            else

                for _, item in pairs(inventory) do

                    if item[nameIdx]:lower() == swapItem.name:lower() and item[countIdx] > 0 then

                        if item[countIdx] >= amountToRemove then

                            item[countIdx] = item[countIdx] - amountToRemove
                            capacity = capacity + (weight * amountToRemove)
                            amountToRemove = 0

                        elseif item[countIdx] < amountToRemove then

                            amountToRemove = amountToRemove - item[countIdx]
                            capacity = capacity + (weight * item[countIdx])
                            item[countIdx] = 0
                        end

                        if item[countIdx] < 1 then

                            freeSlots = freeSlots + 1
                        end

                        if amountToRemove == 0 then

                            break
                        end
                    end
                end
            end
        end

        -- check
        if itemWeight > capacity then

            return false, 'too_heavy'
        end

        if requiredSlot > freeSlots then

            return false, 'not_enough_space'
        end

        return true
    end

    ---Returns true or false (and reason) depending if the inventory can carry the specified item
    ---@param itemData table {name: string, amount: number, metadata: table}
    ---@return boolean, string
    function self.canCarryItem(itemData, playerData)

        local inventory = eCore.getInventory(playerData)
        local requiredSlot = 0

        local capacity = INVENTORY_CONFIG.MAX_WEIGHT - self.getInventoryWeight(playerData)
        local itemWeight = self.getItemWeight(itemData.name, itemData.metadata) * itemData.amount

        if itemWeight > capacity then

            return false, 'too_heavy'
        end

        if REGISTERED_ITEMS[itemData.name:lower()].isUnique then

            requiredSlot = itemData.amount
        else

            requiredSlot = self.getFirstSlotByItem(inventory, itemData.name) and 0 or 1
        end

        if requiredSlot == 0 then

            return true
        end

        if requiredSlot > self.countFreeSlots(inventory) then

            return false, 'not_enough_space'
        end

        return true
    end

    ---Determines the number of free slots
    ---@param inventory table
    ---@return number number of free slots
    function self.countFreeSlots(inventory)

        local free = INVENTORY_CONFIG.SLOTS
        local countIdx = Config.inventoryIdx.count

        for _, item in pairs(inventory) do

            if item[countIdx] > 0 then

                free = free - 1
            end
        end

        return free < 0 and 0 or free
    end

    function self.getItemWeight(itemName, metadata)

        local item = REGISTERED_ITEMS[itemName:lower()]

        if not item then

            return 0
        end

        local weight = item.weight

        if hf.isPopulatedTable(metadata) then

            -- AMMO
            if item.ammoname and metadata.ammo then

                local ammoWeight = 0

                if REGISTERED_ITEMS[item.ammoname] then

                    ammoWeight = REGISTERED_ITEMS[item.ammoname].weight
                end

                if ammoWeight and ammoWeight > 0 then

                    weight = weight + ammoWeight * metadata.ammo
                end
            end

            -- COMPONENTS
            if hf.isPopulatedTable(metadata.components) then

                for i = 1, #metadata.components do

                    local component = REGISTERED_ITEMS[metadata.components[i]]

                    if component and component.weight then

                        weight = weight + component.weight
                    end
                end
            end

            -- CUSTOM WEIGHT
            if metadata.weight then

                weight = weight + metadata.weight
            end
        end

        return weight
    end

    ---Finds the first occurrence of an object
    ---@param inventory table
    ---@param itemName string
    ---@return nil, number slot index
    function self.getFirstSlotByItem(inventory, itemName)

        if not hf.isPopulatedTable(inventory) then

            return nil
        end

        local slotIdx = Config.inventoryIdx.slot

        for slot, item in pairs(inventory) do

            if item.name:lower() == itemName:lower() then

                return tonumber(item[slotIdx] or slot)
            end
        end

        return nil
    end

    ---Sums up and returns all items in inventory and their quantities
    ---@param inventory table
    ---@return table
    function self.getAmountOfItems(inventory)

        local playerItems = {}
        local nameIdx, countIdx = Config.inventoryIdx.name, Config.inventoryIdx.count
        local name, amount

        if not hf.isPopulatedTable(inventory) then

            return playerItems
        end

        for _, item in pairs(inventory) do

            name, amount = item[nameIdx], item[countIdx]

            if not playerItems[name] then

                playerItems[name] = 0
            end

            playerItems[name] = playerItems[name] + amount
        end

        return playerItems
    end

    return self
end