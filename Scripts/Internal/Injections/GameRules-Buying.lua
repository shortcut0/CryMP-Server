------------
local ServerGameRulesBuying = {

    -----------------
    This = "g_gameRules",

    ---------------------------------------------
    --- OnPurchaseCancelled
    ---------------------------------------------
    {

        Class = "g_gameRules",
        Target = { "PurchaseAmmo" },
        Type = eInjection_Replace,

        ------------------------
        Function = function(self, player)

            local buyMessage;
            local pp = player:GetPrestige()
            local start_pp = pp;
            local vehicle = player:GetVehicle()
            local p_v = vehicle and vehicle or player;
            local tmp = {};
            if (vehicle) then
                for i = 1, 2 do
                    local seat = vehicle.Seats[i];
                    if (seat) then
                        local weaponCount = seat.seat:GetWeaponCount();
                        for j = 1, weaponCount do
                            tmp[#tmp + 1] = seat.seat:GetWeaponId(j);
                        end
                    end
                end
            else
                tmp = p_v.inventory:GetInventoryTable();
            end
            --local pos = player:GetWorldPos();
            --pos = CryMP.Library:CalcSpawnPos(player, 1.5);
            --pos.z = pos.z - 0.5;
            for i, itemId in pairs(tmp or {}) do
                local item = System.GetEntity(itemId);
                if (item and item.weapon) then
                    local type = item.weapon:GetAmmoType();
                    if (type) then
                        local capacity = p_v.inventory:GetAmmoCapacity(type);
                        if (capacity > 0) then
                            local clipSize = item.weapon:GetClipSize();
                            local clipCount = item.weapon:GetAmmoCount();
                            --if (item.weapon:GetClipSize() ~= -1) then
                            --	item.weapon:Reload();
                            --	System.LogAlways("Reloading $4"..item.class);
                            --else
                            --	System.LogAlways("won't reload "..item.class);
                            --end
                            local count = p_v.inventory:GetAmmoCount(type) or 0;
                            local need = {clipSize - clipCount, capacity - count};
                            if (need[1] + need[2] > 0) then
                                local def = g_gameRules:GetItemDef(type);
                                if (def) then
                                    local costPerAmmo = def.price * 2;
                                    if (def.amount > 1) then
                                        costPerAmmo = costPerAmmo / def.amount;
                                    end
                                    local needTotal = need[1] + need[2];
                                    local canBuy = needTotal;
                                    local fullCost = (needTotal * costPerAmmo);
                                    local cancel = fullCost > pp;
                                    --System.LogAlways("CANCEL: fullCost "..fullCost.." - pp "..pp.." : needTotal "..needTotal.." * costPerAmmo "..costPerAmmo.." "..type);
                                    if (cancel) then
                                        canBuy = math.floor(pp / fullCost) * canBuy;
                                    end
                                    if (canBuy > 0) then
                                        local increaseClip = 0;
                                        if (clipSize > 0 and need[1] > 0) then
                                            increaseClip = math.min(canBuy, need[1]);
                                            item.weapon:SetAmmoCount(type, clipCount + increaseClip)
                                            --System.LogAlways("ammo: increasing clip for "..item.class.." : clipcount "..clipCount.." + "..increaseClip.." (size "..clipSize..")");
                                        end
                                        local remaining = canBuy - increaseClip;
                                        if (p_v.vehicle) then
                                            p_v.vehicle:SetAmmoCount(type, count + remaining);
                                        else
                                            p_v.actor:SetInventoryAmmo(type, count + remaining, 3);
                                        end
                                        local str = "(" .. item.class.." - "..canBuy..")";
                                        if (not buyMessage) then
                                            buyMessage = str;
                                        else
                                            buyMessage = buyMessage..", "..str;
                                        end
                                    end
                                    local cost = canBuy * costPerAmmo;
                                    pp = pp - cost;
                                    if (cancel) then
                                        --CryMP.Msg.Flash:ToPlayer(channelId, {50, "#d77676", "#ec2020",}, "INSUFFICIENT PRESTIGE", "<font size=\"32\"><b><font color=\"#b9b9b9\">*** </font> <font color=\"#843b3b\">UPGRADE [<font color=\"#d77676\">  %s  </font><font color=\"#843b3b\">] CANCELED</font> <font color=\"#b9b9b9\"> ***</font></b></font>");
                                        local totalPrice = start_pp - pp;
                                        if (buyMessage) then
                                          --  SendMsg(CHAT_EQUIP, player, "(AMMO REFILL: -[ "..buyMessage.." | " .. totalPrice .. " PP ])");
                                            SendMsg(CHAT_EQUIP, player, player:Localize("@l_ui_ammoRefilledCMD", { buyMessage, totalPrice }));
                                        end
                                        --Debug(">>",totalPrice)

                                        self:AwardPPCount(player.id, -totalPrice, nil, player:HasClientMod())
                                        --player:GivePrestige(-totalPrice);
                                        return false, "no more prestige left";
                                    end
                                end
                            end
                        end
                    end
                end
            end
            if (buyMessage) then
                local totalPrice = math.floor(start_pp - pp);
                --CryMP.Msg.Animated:ToPlayer(channelId, 1, "<b><font color=\"#b9b9b9\">*** </font> <font color=\"#843b3b\">SCAN [<font color=\"#d77676\"> COST : "..totalPrice.." PP </font><font color=\"#843b3b\">] FINISHED</font> <font color=\"#b9b9b9\"> ***</font></b>");
                --	nCX.ParticleManager("explosions.light.mine_light", 2, pos, g_Vectors.up, 0);
               -- SendMsg(CHAT_EQUIP, player, "(AMMO REFILL: -[ "..buyMessage.." | " .. totalPrice .. " PP ])");
                SendMsg(CHAT_EQUIP, player, player:Localize("@l_ui_ammoRefilledCMD", { buyMessage, totalPrice }));
                self:AwardPPCount(player.id, -totalPrice, nil, player:HasClientMod())
            else
                return false, "ammo already full"
            end
            return true;
        end;
    },

    ---------------------------------------------
    --- OnPurchaseCancelled
    ---------------------------------------------
    {

        Class = "g_gameRules",
        Target = { "OnPurchaseCancelled" },
        Type = eInjection_Replace,

        ------------------------
        Function = function(self, idPlayer, iTeam, sItem)

            local hPlayer = GetEntity(idPlayer)
            if (not hPlayer) then
                return
            end

            local iPrice, iEnergy = self:GetPrice(sItem)
            if (iPrice > 0) then

                -- FIXME: ClientMod!
                -- hPlayer:ClientEvent(eCallClMod_BattleLog, string.format("%s (+%d)", LocalizeForClient(hPlayer, "@l_ui_vehiclerefund")))
                self:AwardPPCount(idPlayer, iPrice, nil, hPlayer:HasClientMod())
            end

            if (iEnergy and iEnergy > 0) then
                self:SetTeamPower(iTeam, self:GetTeamPower(iTeam) + iEnergy)
            end
        end
    },

    ---------------------------------------------
    --- SvBuyAmmo
    ---------------------------------------------
    {

        Class = "g_gameRules",
        Target = { "Server.SvBuyAmmo" },
        Type = eInjection_Replace,

        ------------------------
        Function = function(self, hPlayerID, sItem)

            local hPlayer = System.GetEntity(hPlayerID)
            if (not hPlayer) then
                return
            end

            -- FIXME: AntiCheat()
            -- CheckFlood()

            local iChannel = hPlayer:GetChannel()
            local bFrozen  = hPlayer:IsFrozen()
            local bAlive   = hPlayer:IsAlive(true)
            local bOk      = false

            if (not bFrozen) then
                bOk = self:DoBuyAmmo(hPlayerID, sItem)
            end

            if (bOk) then
                self.onClient:ClBuyOk(iChannel, sItem)
            else
                self.onClient:ClBuyError(iChannel, sItem)
            end
        end

    },

    ---------------------------------------------
    --- SvBuy
    ---------------------------------------------
    {

        Class = "g_gameRules",
        Target = { "Server.BuyVehicle" },
        Type = eInjection_Replace,

        ------------------------
        Function = function(self, hPlayerID, sItem)

            local hPlayer = System.GetEntity(hPlayerID)
            if (not hPlayer) then
                return false
            end

            if (ServerItemHandler:CanBuyVehicle(hPlayer, sItem) ~= true) then
                return false
            end

            local hFactory = self:GetProductionFactory(hPlayerID, sItem, true)
            if (hFactory) then

                local bLimitOk, bTeamCheck = self:CheckBuyLimit(sItem, hPlayer:GetTeam())
                if (not bLimitOk) then
                    if (bTeamCheck) then
                        self.game:SendTextMessage(TextMessageError, "@mp_TeamItemLimit", TextMessageToClient, hPlayerID, self:GetItemName(sItem))
                    else
                        self.game:SendTextMessage(TextMessageError, "@mp_GlobalItemLimit", TextMessageToClient, hPlayerID, self:GetItemName(sItem))
                    end

                    return false
                end

                for _, pFactory in pairs(self.factories) do
                    pFactory:CancelJobForPlayer(hPlayerID)
                end

                local aDef              = self.buyList[sItem]
                local aServerProperties = (aDef.ServerProperties or {})

                local iPrice, iEnergy = self:GetPrice(sItem)
                if (hFactory:Buy(hPlayerID, sItem, aServerProperties)) then

                    -- FIXME: ClientMod()
                    -- ClientMod()

                    self:AwardPPCount(hPlayerID, -iPrice, nil, hPlayer:HasClientMod())
                    self:AwardCPCount(hPlayerID, self.cpList.BUYVEHICLE)

                    if (iEnergy and iEnergy > 0) then
                        local iTeam = self.game:GetTeam(hPlayerID)
                        if (iTeam and iTeam ~= 0) then
                            self:SetTeamPower(iTeam, self:GetTeamPower(iTeam) - iEnergy)
                        end
                    end

                    self:AbandonPlayerVehicle(hPlayerID)
                    return true
                end
            end

            return false
        end

    },

    ---------------------------------------------
    --- SvBuy
    ---------------------------------------------
    {

        Class = "g_gameRules",
        Target = { "Server.SvBuy" },
        Type = eInjection_Replace,

        ------------------------
        Function = function(self, hPlayerID, sItem)

            local hPlayer = System.GetEntity(hPlayerID)
            if (not hPlayer) then
                return
            end

            -- FIXME: AntiCheat()
            -- CheckFlood()

            local bOk = false
            local iChannel = hPlayer:GetChannel()

            if (hPlayer:GetTeam() ~= 0) then
                local bFrozen = hPlayer:IsFrozen()
                local bAlive  = hPlayer:IsAlive(true)

                if ((not bFrozen)) then
                    if (self:ItemExists(hPlayerID, sItem)) then
                        local aDef     = self.buyList[sItem]
                        local iPrice   = aDef.price
                        local iMissing = (iPrice - hPlayer:GetPrestige())

                        if (self:IsVehicle(sItem) and bAlive) then
                            if (self:EnoughPP(hPlayerID, sItem)) then
                                bOk = self:BuyVehicle(hPlayerID, sItem)
                            else
                                ServerItemHandler:HandleMessage(hPlayer, "@l_ui_buyVehicleMissingPrestige", { aDef.class, iMissing }, MSG_ERROR)
                            end
                        elseif (((not bFrozen) and self:IsInBuyZone(hPlayerID)) or (not bAlive)) then
                            if (self:EnoughPP(hPlayerID, sItem)) then
                                bOk = self:BuyItem(hPlayerID, sItem)
                            else
                                ServerItemHandler:HandleMessage(hPlayer, "@l_ui_buyItemMissingPrestige", { aDef.class, iMissing }, MSG_ERROR)
                            end
                        end
                    else
                        ServerItemHandler:HandleMessage(hPlayer, "@l_ui_itemNotFound", { sItem }, MSG_ERROR)
                    end
                end
            end

            if (bOk) then
                self.onClient:ClBuyOk(iChannel, sItem)
            else
                self.onClient:ClBuyError(iChannel, sItem)
            end
        end

    },

    ---------------------------------------------
    --- OnPurchaseCancelled
    ---------------------------------------------
    {

        Class = "g_gameRules",
        Target = { "DoBuyAmmo" },
        Type = eInjection_Replace,

        ------------------------
        Function = function(self, hPlayerID, sItem)

            local hPlayer = System.GetEntity(hPlayerID)
            if (not hPlayer) then
                return
            end


            local hCurrent = hPlayer:GetCurrentItem()
            local iPrice
            local aDef

            if (sItem == "sell") then
                return ServerItemHandler:SellItem(hPlayerID, sItem)
            end

            aDef = self:GetItemDef(sItem)
            if (not aDef) then
                ServerItemHandler:HandleMessage(hPlayer, "@l_ui_ammoNotFound", { sItem }, MSG_ERROR)
                return false
            end

            local aReviveQueue
            local bAlive = hPlayer:IsAlive()
            if (not bAlive) then
                aReviveQueue = self.reviveQueue[hPlayerID]
            end

            -- Server
            local aServerProperties = (aDef.ServerProperties or {})

            local iLevel    = 0
            local aZones    = self.inBuyZone[hPlayerID]
            local teamId    = self.game:GetTeam(hPlayerID)

            local hVehicle = GetEntity(hPlayer:GetVehicleId())
            if (hVehicle and (not hVehicle.buyFlags or hVehicle.buyFlags == 0)) then
                aZones = self.inServiceZone[hPlayerID]
            end

            local aZone, iZoneLevel
            for zoneId in pairs(aZones or {}) do
                if (teamId == self.game:GetTeam(zoneId)) then
                    aZone = System.GetEntity(zoneId)
                    if (aZone and aZone.GetPowerLevel) then
                        iZoneLevel = aZone:GetPowerLevel()
                        if (iZoneLevel > iLevel) then
                            iLevel = iZoneLevel
                        end
                    end
                end
            end

            if (aDef.level and aDef.level > 0 and aDef.level > iLevel) then

                ServerItemHandler:HandleMessage(hPlayer, "@l_ui_alienEnergyRequired")
                self.game:SendTextMessage(TextMessageError, "@mp_AlienEnergyRequired", TextMessageToClient, hPlayerID, aDef.name)
                return false
            end
            ---------------------------------------

            local aAmmo = self.buyList[sItem]
            local iAmmoCurr, iAmmoMax, iNeed

            if (aAmmo and aAmmo.ammo) then

                iPrice = self:GetPrice(sItem)

                -- ignore vehicles with buyzones here (we want to buy ammo for the player not the vehicle in this case)
                if (hVehicle and not hVehicle.buyFlags and not hVehicle.NoBuyAmmo) then
                    if (bAlive) then

                        --is in vehiclebuyzone
                        if (self:IsInServiceZone(hPlayerID) and (iPrice == 0 or self:EnoughPP(hPlayerID, nil, iPrice)) and self:VehicleCanUseAmmo(hVehicle, sItem)) then
                            iAmmoCurr = (hVehicle.inventory:GetAmmoCount(sItem) or 0)
                            iAmmoMax  = (hVehicle.inventory:GetAmmoCapacity(sItem) or 0)

                            if (iAmmoCurr < iAmmoMax or iAmmoMax == 0) then
                                iNeed = aAmmo.amount
                                if (iAmmoMax>0) then
                                    iNeed = math.min(iAmmoMax - iAmmoCurr, aAmmo.amount)
                                end

                                -- this function takes care of synchronizing it to clients
                                hVehicle.vehicle:SetAmmoCount(sItem, iAmmoCurr + iNeed)

                                if (iPrice > 0) then
                                    if (iNeed < aAmmo.amount) then
                                        iPrice = math.ceil((iNeed * iPrice) / aAmmo.amount)
                                    end

                                    -- TODO: ClientMod()
                                    -- ClientMod()
                                    self:AwardPPCount(hPlayerID, -iPrice, nil, hPlayer:HasClientMod())
                                end

                                return true
                            end
                        end
                    end
                elseif ((self:IsInBuyZone(hPlayerID) or (not bAlive)) and (iPrice == 0 or self:EnoughPP(hPlayerID, nil, iPrice))) then
                    iAmmoCurr = (hPlayer.inventory:GetAmmoCount(sItem) or 0)
                    iAmmoMax  = (hPlayer.inventory:GetAmmoCapacity(sItem) or 0)

                    if (not bAlive) then
                        iAmmoCurr = (aReviveQueue.ammo[sItem] or 0)
                    end

                    if (iAmmoCurr < iAmmoMax or iAmmoMax == 0) then
                        iNeed = aAmmo.amount;
                        if (iAmmoMax > 0) then
                            iNeed = math.min(iAmmoMax - iAmmoCurr, aAmmo.amount)
                        end

                        if (bAlive) then
                            -- this function takes care of synchronizing it to clients
                            hPlayer.actor:SetInventoryAmmo(sItem, iAmmoCurr + iNeed)
                        else
                            aReviveQueue.ammo[sItem] = (iAmmoCurr + iNeed)
                        end

                        if (iPrice > 0) then
                            if (iNeed < aAmmo.amount) then
                                iPrice = math.ceil((iNeed * iPrice) / aAmmo.amount)
                            end

                            if (bAlive) then

                                -- FIXME: ClientMod()
                                -- ClientMod()
                                self:AwardPPCount(hPlayerID, -iPrice, nil, hPlayer:HasClientMod())
                            else
                                aReviveQueue.ammo_price = (aReviveQueue.ammo_price + iPrice)
                            end
                        end

                        return true
                    end
                end
            end
            return false
        end
    },

    ---------------------------------------------
    --- OnPurchaseCancelled
    ---------------------------------------------
    {

        Class = "g_gameRules",
        Target = { "BuyItem" },
        Type = eInjection_Replace,

        ------------------------
        Function = function(self, hPlayerID, sItem)

            -- !!hook
            local hPlayer = GetEntity(hPlayerID)
            if (not hPlayer) then
                return false
            end

            local iEnergy
            local iPrice = self:GetPrice(sItem)
            local aDef   = self:GetItemDef(sItem)

            if (not aDef) then
                ServerItemHandler:HandleMessage(hPlayer, "@l_ui_itemNotFound", { sItem }, MSG_ERROR)
                return false
            end

            if (not ServerItemHandler:CanBuyItem(hPlayer, sItem, aDef)) then
                return false
            end

            if (aDef.buy) then
                local aBuyDef = self:GetItemDef(aDef.buy)
                if (aBuyDef and (not self:HasItem(hPlayerID, aBuyDef.class))) then
                    local result = self:BuyItem(hPlayerID, aBuyDef.id)
                    if (not result) then
                        return false
                    end
                end

            end

            if (aDef.buyammo and self:HasItem(hPlayerID, aDef.class)) then
                local ret = self:DoBuyAmmo(hPlayerID, aDef.buyammo)
                if (aDef.selectOnBuyAmmo and ret and hPlayer) then
                    hPlayer.actor:SelectItemByNameRemote(aDef.class)
                end
                return ret
            end

            local aReviveQueue
            local bAlive = hPlayer:IsAlive()
            if (not bAlive) then
                aReviveQueue = self.reviveQueue[hPlayerID]
            end

            -- Server
            local aServerProperties = (aDef.ServerProperties or {})

            local iKitLimit = ConfigGet("General.GameRules.Buying.KitLimit", 1, eConfigGet_Number)
            local iKitCount = table.count({
                hPlayer:GetItem("RadarKit"),
                hPlayer:GetItem("RepairKit"),
                hPlayer:GetItem("LockpickKit")
            })

            local uniqueOld
            if (aDef.uniqueId) then
                local hasUnique, currentUnique = self:HasUniqueItem(hPlayerID, aDef.uniqueId)
                if (hasUnique) then
                    if (bAlive and aServerProperties.NoItemLimit ~= true) then
                        if (aDef.category == "@mp_catEquipment") then
                            if (iKitCount > iKitLimit) then
                                ServerItemHandler:HandleMessage(hPlayer, "@l_ui_cannotCarryMoreKits", iKitLimit)
                                g_pGame:SendTextMessage(TextMessageError, "@mp_CannotCarryMoreKit", TextMessageToClient, hPlayerID)
                            end
                        else
                            if (aDef.class) then
                                if (aDef.category == "@mp_catWeapons") then
                                    hPlayer:SelectItem(aDef.class)
                                end
                                ServerItemHandler:HandleMessage(hPlayer, "@l_ui_cannotCarryMore")
                            end
                            self.game:SendTextMessage(TextMessageError, "@mp_CannotCarryMore", TextMessageToClient, hPlayerID)
                        end
                        Debug("no!")
                        return false
                    end
                    uniqueOld = currentUnique
                end
            end

            local flags     = 0
            local level     = 0
            local aZones    = self.inBuyZone[hPlayerID]
            local iTeam     = g_pGame:GetTeam(hPlayerID)
            local aFactory

            for zoneId in pairs(aZones) do
                if (iTeam == self.game:GetTeam(zoneId)) then
                    local zone = System.GetEntity(zoneId)
                    if (zone and zone.GetPowerLevel) then
                        local zonelevel = zone:GetPowerLevel()
                        if (zonelevel > level) then
                            level = zonelevel
                        end
                    end
                    if (zone and zone.GetBuyFlags) then
                        flags = bor(flags, zone:GetBuyFlags())
                    end
                    aFactory = zone
                end
            end

            -- dead players can't buy anything else
            if (not bAlive) then
                flags = bor(bor(self.BUY_WEAPON, self.BUY_AMMO), self.BUY_EQUIPMENT)
            end

            -- FIXME: Bypass xyz mode
            if (aDef.level and aDef.level > 0 and aDef.level > level) then
                self.game:SendTextMessage(TextMessageError, "@mp_AlienEnergyRequired", TextMessageToClient, hPlayerID, aDef.name)
                ServerItemHandler:HandleMessage(hPlayer, "@l_ui_alienEnergyRequired", (aDef.level - level))
                return false
            end

            local itemflags = self:GetItemFlag(sItem)
            if (band(itemflags, flags) == 0) then
                return false
            end

            -- FIXME: Bypass xyz mode
            local limitOk, teamCheck, iLimit = self:CheckBuyLimit(sItem, self.game:GetTeam(hPlayerID))
            if (not limitOk) then
                if (teamCheck) then
                    ServerItemHandler:HandleMessage(hPlayer, "@l_ui_itemteamLimit", { iLimit, aDef.class })
                    self.game:SendTextMessage(TextMessageError, "@mp_TeamItemLimit", TextMessageToClient, hPlayerID, aDef.name)
                else

                    ServerItemHandler:HandleMessage(hPlayer, "@l_ui_itemglobalLimit", { iLimit, aDef.class })
                    self.game:SendTextMessage(TextMessageError, "@mp_GlobalItemLimit", TextMessageToClient, hPlayerID, aDef.name)
                end

                return false;
            end

            -- check inventory
            local hItemID
            local bOk

            if (bAlive) then
                if (aServerProperties.NoItemLimit ~= true) then
                    bOk = hPlayer.actor:CheckInventoryRestrictions(aDef.class)
                else
                    bOk = true
                end
            else

                if (aReviveQueue.items and table.count(aReviveQueue.items) > 0) then
                    local aInventory = {}
                    for _, v in ipairs(aReviveQueue.items) do
                        local aItem = self:GetItemDef(v)
                        if (aItem) then
                            table.insert(aInventory, aItem.class)
                        end
                    end
                    bOk = hPlayer.actor:CheckVirtualInventoryRestrictions(aInventory, aDef.class)
                else
                    bOk = true
                end
            end

            -- FIXME: Bypass for xy mode
            if (bOk) then
                if ((not bAlive) and (uniqueOld)) then
                    for i, old in pairs(aReviveQueue.items) do
                        if (old == uniqueOld) then
                            aReviveQueue.items_price = aReviveQueue.items_price - self:GetPrice(old)
                            table.remove(aReviveQueue.items, i)
                            break
                        end
                    end
                end

                iPrice, iEnergy = self:GetPrice(aDef.id);
                if (bAlive) then

                    local iCooldown = aServerProperties.BuyCooldown
                    if (iCooldown) then
                        if (hPlayer:OnBuyCooldown(aDef.class, iCooldown)) then
                            ServerItemHandler:HandleMessage(hPlayer, "@l_ui_itemBuyCooldown", { math.calctime(hPlayer:GetBuyCooldown(aDef.class)), aDef.class})
                            return false
                        end
                    end

                    hPlayer:SetBuyCooldown(aDef.id)

                    local hItem
                    if (not aServerProperties.DontGiveItem) then
                        hItemID = hPlayer:GiveItem(aDef.class, true)
                        hItem   = GetEntity(hItemID)
                    end

                    ServerItemHandler:OnItemBought(hPlayer, hItem, aDef, iPrice, aFactory)

                    self:AwardPPCount(hPlayerID, -iPrice, nil, hPlayer:HasClientMod())
                    if (iEnergy and iEnergy > 0) then
                        self:SetTeamPower(iTeam, self:GetTeamPower(iTeam) - iEnergy)
                    end
                    if (hItem) then
                        hItem.builtas = aDef.id
                    end

                elseif ((not iEnergy) or (iEnergy == 0)) then
                    table.insert(aReviveQueue.items, aDef.id)
                    aReviveQueue.items_price = aReviveQueue.items_price + iPrice
                else
                    return false
                end
            else
                if (aDef.class) then
                    ServerItemHandler:HandleMessage(hPlayer, "@l_ui_cannotCarryMoreType", { string.capitalN(ServerDLL.GetItemCategory(aDef.class)) })
                else
                    ServerItemHandler:HandleMessage(hPlayer, "@l_ui_cannotCarryMore")
                end

                self.game:SendTextMessage(TextMessageError, "@mp_CannotCarryMore", TextMessageToClient, hPlayerID)
                return false
            end

            if (hItemID) then
                self.Server.OnItemBought(self, hItemID, sItem, hPlayerID)
            end

            return true

        end
    },

    ---------------------------------------------
    --- CheckSpawnPP
    ---------------------------------------------
    {

        Class = "g_gameRules",
        Target = { "CheckSpawnPP" },
        Type = eInjection_Replace,

        ------------------------
        Function = function(self, hPlayer, bIsVehicle, hSpawn)

            local bSpawnAward = ConfigGet("General.GameRules.Prestige.AwardSpawnPrestige", true, eConfigGet_Boolean)
            if (not bSpawnAward) then
                return
            end

            local iBunkerAward  = ConfigGet("General.GameRules.Prestige.BunkerSpawnAward", 100, eConfigGet_Number)
            local iVehicleAward = ConfigGet("General.GameRules.Prestige.VehicleSpawnAward", 100, eConfigGet_Number)

            if (not bIsVehicle) then
                for _, hUser in pairs(hSpawn.CapturedBy or {}) do
                    if (_ ~= hPlayer.id and hPlayer:GetTeam() == hUser:GetTeam()) then

                        -- FIXME: ClientMod
                        self:AwardPPCount(_, iBunkerAward, nil, hUser:HasClientMod())
                        Debug("Awarding for spawning in bunker")
                    end
                end
            else
                local hOwner = GetEntity(hSpawn.vehicle:GetOwnerId()) or GetEntity(hSpawn.OwnerID)
                if (hOwner and hOwner.IsPlayer and hOwner.id ~= hPlayer.id) then

                    -- FIXME: ClientMod
                    self:AwardPPCount(hOwner.id, iBunkerAward, nil, hUser:HasClientMod())
                    Debug("Awarding for spawning in vehicle")
                end
            end
        end
    },

    ---------------------------------------------
    --- Reset
    ---------------------------------------------
    {

        Class = "g_gameRules",
        Target = { "SetPlayerPP" },
        Type = eInjection_Replace,

        ------------------------
        Function = function(self, hPlayerID, iPP)
            g_pGame:SetSynchedEntityValue(hPlayerID, self.PP_AMOUNT_KEY, math.min(MAXIMUM_PRESTIGE, math.max(-MAXIMUM_PRESTIGE, iPP)))
        end

    },

    ---------------------------------------------
    --- Reset
    ---------------------------------------------
    {

        Class = "g_gameRules",
        Target = { "AwardPPCount" },
        Type = eInjection_Replace,

        ------------------------
        Function = function(self, idPlayer, iCount, sWhy, bSilent)

            local hPlayer = System.GetEntity(idPlayer)
            if (not hPlayer) then
                return
            end

            if (iCount > 0) then
                local iIncomeScale = System.GetCVar("g_pp_scale_income")
                if (iIncomeScale) then
                    iCount = math.floor(iCount * math.max(0, iIncomeScale))
                end
            end

            local iTotal = (self:GetPlayerPP(idPlayer) + iCount)
            self:SetPlayerPP(idPlayer, math.max(0, iTotal))

            if (not bSilent) then
                self.onClient:ClPP(hPlayer.actor:GetChannel(), iCount)
            end

            CryAction.SendGameplayEvent(idPlayer, eGE_Currency, nil, iTotal)
            CryAction.SendGameplayEvent(idPlayer, eGE_Currency, sWhy, iCount)
        end
    },

    ---------------------------------------------
    --- Reset
    ---------------------------------------------
    {

        Class = "g_gameRules",
        Target = { "Server.OnCapture" },
        Type = eInjection_Replace,

        ------------------------
        Function = function(self, hSpawn, iTeam)

            hSpawn.CapturedBy = {}

            local aInside = hSpawn.inside
            if (aInside) then

                local hPlayer
                for _, idPlayer in ipairs(aInside) do
                    if (g_gameRules.game:GetTeam(idPlayer) == iTeam) then

                        hPlayer = System.GetEntity(idPlayer)
                        if (hPlayer and hPlayer:IsAlive()) then
                            hSpawn.CapturedBy[idPlayer] = hPlayer
                            Debug("Captured by ",hPlayer:GetName())
                        end
                    end
                end
            end
        end
    },

    ---------------------------------------------
    --- OnUncapture
    ---------------------------------------------
    {

        Class = "g_gameRules",
        Target = { "Server.OnUncapture" },
        Type = eInjection_Replace,

        ------------------------
        Function = function(self, hSpawn)
            hSpawn.CapturedBy = {}
        end
    },

    ---------------------------------------------
    --- ResetServerItems
    ---------------------------------------------
    {

        Class = "g_gameRules",
        Target = { "CheckBuyLimit" },
        Type = eInjection_Replace,

        ------------------------
        Function = function(self, sItem, iTeam, bTeamOnly)
            local aDef = self:GetItemDef(sItem)
            if (not aDef) then
                return false, nil, -1
            end

            local iCurrent
            if (aDef.limit and (not bTeamOnly)) then
                iCurrent = self:GetActiveItemCount(sItem)
                if (iCurrent >= aDef.limit) then
                    -- send limit warning here
                    return false, nil, aDef.limit
                end
            end

            if (iTeam and aDef.teamlimit) then
                iCurrent = self:GetActiveItemCount(sItem, iTeam)
                if (iCurrent >= aDef.teamlimit) then
                    -- send team limit warning here
                    return false, true, aDef.limit
                end
            end

            return true
        end,
    },

    ---------------------------------------------
    --- ResetServerItems
    ---------------------------------------------
    {

        Class = "g_gameRules",
        Target = { "ResetServerItems" },
        Type = eInjection_Replace,

        ------------------------
        Function = function(self, hPlayer)

        end,
    },
}

------------
ServerInjector.InjectAll(ServerGameRulesBuying)