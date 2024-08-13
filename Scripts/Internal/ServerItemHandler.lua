----------------------
ServerItemHandler = {
    Equipment = {
        ["PowerStruggle"] = {
            Active = true,
            Regular = {
                { "FY71", { "LAMRifle", "Silencer" }}
            },
            Premium = {
                { "FY71", { "LAMRifle", "Silencer" }},
                { "SCAR", { "LAMRifle", "Silencer", "Reflex" }}
            },
            Admin = {
                { "FY71", { "LAMRifle", "Silencer", "SniperScope" }},
                { "SCAR", { "LAMRifle", "Silencer", "Reflex" }},
                { "RadarKit" }
            },
            AdditionalEquip = {
                'Binoculars'
            },
            MustHave = {
                "LAMRifle",
                "Silencer"
            }
        },
        ["InstantAction"] = {

            Active = true,
            Regular = {
                { "FY71", { "LAMRifle", "Silencer" }}
            },
            Premium = {
                { "SMG",  { "LAMRifle", "Silencer", "Reflex" }},
                { "FY71", { "LAMRifle", "Silencer", "Reflex" }}
            },
            AdditionalEquip = {
                'Binoculars'
            },
            MustHave = {
                "LAMRifle",
                "Silencer"
            }
        },
    }
}

----------------------

eKillType_Unknown   = 0
eKillType_Suicide   = 1
eKillType_Team      = 2
eKillType_Enemy     = 3
eKillType_Bot       = 4
eKillType_BotDeath  = 5

----------------------
ServerItemHandler.Init = function(self)

    self.Equipment.PowerStruggle = ConfigGet("General.Equipment.SpawnEquipment.PowerStruggle", self.Equipment.PowerStruggle, eConfigGet_Array)
    self.Equipment.InstantAction = ConfigGet("General.Equipment.SpawnEquipment.InstantAction", self.Equipment.InstantAction, eConfigGet_Array)

end

----------------------
ServerItemHandler.CanBuyItem = function(self, hPlayer, sItem, aDef)

    ServerLog("Can buy %s", sItem)

    local aForbidden = ConfigGet("General.GameRules.Buying.ForbiddenItems", {}, eConfigGet_Array)
    if (table.empty(aForbidden)) then
        return true
    end

    if (string.matchex(sItem, unpack(aForbidden))) then
        self:HandleMessage(hPlayer, "@l_ui_buyItemForbidden", { aDef.class }, MSG_ERROR)
        return false
    end
    return true
end

----------------------
ServerItemHandler.SellItem = function(self, hPlayerID, sItem)

    local hPlayer = System.GetEntity(hPlayerID)
    if (not hPlayer) then
        return false
    end

    local hCurrent = hPlayer:GetCurrentItem()
    local bSold    = false
    local iPrice
    local aDef

    local iSellMultiplier = ConfigGet("General.GameRules.Buying.SellItemReward", 75, eConfigGet_Number)
    if (g_gameRules:IsInBuyZone(hPlayerID)) then
        if (hCurrent) then
            for _, aInfo in pairs(g_gameRules.buyList) do
                if (aInfo.class == hCurrent.class) then
                    aDef = aInfo
                    break
                end
            end

            if (aDef) then
                iPrice = aDef.price
                if (iPrice) then

                    local iSellPrice = math.floor(math.max(0, iPrice * (iSellMultiplier / 100)) + 0.5)
                    self:HandleMessage(hPlayer, "@l_ui_itemSold", { hCurrent.class, iSellPrice })

                    -- FIXME: ClientMod
                    -- ClientMod()

                    g_gameRules:AwardPPCount(hPlayerID, iSellPrice, nil, hPlayer:HasClientMod())
                    hPlayer.actor:SelectItemByNameRemote("Fists")
                    System.RemoveEntity(hCurrent.id)

                    bSold = true
                else
                    self:HandleMessage(hPlayer, "@l_ui_cannotSellItem", { hCurrent.class }, MSG_ERROR)
                end
            else
                self:HandleMessage(hPlayer, "@l_ui_cannotSellItem", { hCurrent.class }, MSG_ERROR)
            end
        else
            self:HandleMessage(hPlayer, "@l_ui_cannotSellItem", {})
        end
    end

    return bSold
end

----------------------
ServerItemHandler.HandleMessage = function(self, hPlayer, sMsg, aFormat, iExType)

    local sLocale = hPlayer:Localize(sMsg, aFormat)
    Logger:LogEventTo({ hPlayer }, eLogEvent_BuyMessage, sLocale)
    if (iExType) then
        SendMsg(iExType, hPlayer, string.gsub(Logger:ReplaceColors(sLocale), string.COLOR_CODE, ""))
    end
end

----------------------
ServerItemHandler.OnItemBought = function(self, hPlayer, hItem, aDef, iPrice, aFactory)

    if (not hItem) then
        return
    end

    local aEquipConfig = hPlayer:GetData(ePlayerData_Equipment, {})[hItem.class]
    if (aEquipConfig) then
        if (self:AttachOnWeapon(hPlayer, hItem, aEquipConfig, nil, true)) then
            if (hPlayer:TimerExpired(ePlayerTimer_EquipmentLoadedMsg, 120, true)) then
                SendMsg(CHAT_EQUIP, hPlayer, hPlayer:Localize("@l_ui_accessoryloaded", { string.upper(hItem.class) }))
            end
        end
    end

    local hWeapon = hPlayer:GetCurrentItem()
    if (not hItem.weapon and (hWeapon and hWeapon.weapon)) then
        self:AttachOnWeapon(hPlayer, hWeapon, { hItem.class }, true, false)
    end

    if (ConfigGet("General.GameRules.Prestige.AwardInvestPrestige", false, eConfigGet_Boolean)) then
        local iInvestmentShare = ConfigGet("General.GameRules.Prestige.ItemInvestAward")
        if (iInvestmentShare > 0) then
            local iShare = math.floor((iPrice * (iInvestmentShare / 100)) + 0.5)
            if (iShare > 0) then
                for _, hUser in pairs(aFactory.CapturedBy or {}) do

                    -- FIXME: ClientMod
                    -- ClientMod()

                    g_gameRules:AwardPPCount(hUser.id, iShare, nil, hUser:HasClientMod())
                end
            end
        end
    end

    -- FIXME: ClientMod()
    -- ClientMod()
end

----------------------
ServerItemHandler.EquipPlayer = function(self, hPlayer, aList)

    local aEquipment = self.Equipment[g_sGameRules]
    if (table.empty(aEquipment) or aEquipment.Active ~= true) then
        return false
    end

    --Debug(">",g_sGameRules)

    local aRegular = aEquipment.Regular
    local aPremium = aEquipment.Premium
    local aAdmin   = aEquipment.Admin

    -- Additionals
    local aRequired   = aEquipment.MustHave
    local aAdditional = aEquipment.AdditionalEquip
    for _, sClass in pairs(table.append(
            checkArray(aRequired),
            checkArray(aAdditional)
    )) do
        hPlayer:GiveItem(sClass)
    end

    -- Mains
    local iAccess  = hPlayer:GetAccess()

    if (aList) then
        self:Equip(hPlayer, aList)
    elseif (hPlayer:IsAdmin() and aAdmin ~= nil) then
        self:Equip(hPlayer, aAdmin)
    elseif (hPlayer:IsPremium() and aPremium ~= nil) then
        self:Equip(hPlayer, aPremium)
    else
        self:Equip(hPlayer, aRegular)
    end

    return true
end

----------------------
ServerItemHandler.Equip = function(self, hPlayer, aEquipment)

    local hWeapon, aStored
    for _, aInfo in pairs(aEquipment) do
        hWeapon = GetEntity(hPlayer:GiveItem(aInfo[1]))
        if (hWeapon) then
            aStored = (checkArray(hPlayer:GetData(ePlayerData_Equipment))[hWeapon.class])
            if (aStored) then
            end
            self:AttachOnWeapon(hPlayer, hWeapon, (aStored or aInfo[2] or {}), false, (aStored ~= nil))
        end
    end

    return true
end

----------------------
ServerItemHandler.AttachOnWeapon = function(self, hPlayer, hWeapon, aList, bPickup, bNeedsItem)

    local bOk = true
    local bAny = (table.count(aList) == 0)
    if (bPickup) then
        --hWeapon.weapon:SvRemoveAccessory("all")
        --Debug("off")
    end

    for _, sClass in pairs(aList) do
        if (hWeapon.weapon:SupportsAccessory(sClass)) then

            bOk = true
            if (not hPlayer:HasItem(sClass)) then
                if (bNeedsItem) then
                    bOk = false
                else
                    hPlayer:GiveItem(sClass, true)
                end
            end

            if (bOk) then
                if (bPickup) then
                    if (not hWeapon.weapon:GetAccessory(sClass)) then
                        hWeapon.weapon:SvChangeAccessory(sClass)
                        --Debug("swap",sClass)
                    else
                        --Debug("Not ",sClass)
                    end
                else
                    hWeapon.weapon:AttachAccessory(sClass, true, true)
                end
                bAny = true
            end
        end
    end

    return bAny
end

----------------------
ServerItemHandler.RefillAmmo = function(self, hPlayer, hWeaponID)

    local hWeapon = (GetEntity(hWeaponID) or hPlayer.inventory:GetCurrentItem())
    if (hWeapon and hWeapon.weapon) then

        local ammoType = hWeapon.weapon:GetAmmoType()
        if (ammoType) then

            local iCapacity = hPlayer.inventory:GetAmmoCapacity(ammoType)
            if (iCapacity) then

                local iRefilled 		= (iCapacity - hPlayer.inventory:GetAmmoCount(ammoType))
                local iItemRefilled 	= (hWeapon.weapon:GetClipSize()+1 - hWeapon.weapon:GetAmmoCount())

                hWeapon.weapon:SetAmmoCount(nil, hWeapon.weapon:GetClipSize()+1)
                hPlayer.actor:SetInventoryAmmo(ammoType, iCapacity)
                hPlayer.inventory:SetAmmoCount(ammoType, iCapacity)

                return iRefilled, iItemRefilled
            end
        end
    end

    return
end

----------------------
ServerItemHandler.OnSwitchAccessory = function(self, hWeapon, hOwner, sClass)

    if (not hOwner or (not hOwner.IsPlayer)) then-- or hOwner:IsDev())) then
        return true
    end

    if (not ConfigGet("General.Equipment.ForbiddenAttachments.Active", false, eConfigGet_Boolean)) then
        return true
    end

    local aForbidden = ConfigGet("General.Equipment.ForbiddenAttachments.List", {}, eConfigGet_Array)
    if (table.empty(aForbidden)) then
        return true
    end

    local bOk = (not IsAny(sClass, unpack(aForbidden)))
    if (not bOk) then
        SendMsg({ MSG_ERROR, CHAT_EQUIP }, hOwner, string.format("%s", hOwner:Localize("@l_ui_accessoryforbidden", { sClass })))
        return false
    end

    return true
end

----------------------
ServerItemHandler.GetAttachedAccessories = function(self, hWeapon)
    local aList = {}
    for _, hID in pairs(hWeapon.weapon:GetAttachedAccessories() or {}) do
        table.insert(aList, GetEntity(hID).class)
    end

    return aList
end

----------------------
ServerItemHandler.OnLeaveWeaponModify = function(self, hWeapon, hOwner)

    if (not hOwner or not hOwner.IsPlayer) then
        return true
    end

    -- TODO: Save Modifications !!!!
    local aEquipmentConfig = table.checkM(hOwner:GetData(ePlayerData_Equipment, {}), hWeapon.class, {})
    aEquipmentConfig[hWeapon.class] = self:GetAttachedAccessories(hWeapon)

    hOwner:SetData(ePlayerData_Equipment, aEquipmentConfig)
    if (hOwner:TimerExpired(ePlayerTimer_EquipmentMsg, 120, true)) then
        SendMsg(CHAT_EQUIP, hOwner, string.format("%s", hOwner:Localize("@l_ui_accessorysaved", { string.upper(hWeapon.class) })))
    end

    return true
end

----------------------
ServerItemHandler.CanPickupWeapon = function(self, hPlayerID, hItemID)

    local hPlayer = GetEntity(hPlayerID)
    if (not hPlayer or not hPlayer.IsPlayer) then
        return true
    end

    local hItem = GetEntity(hItemID)

    return true
end

----------------------
ServerItemHandler.CanDropWeapon = function(self, hPlayerID, hItemID)

    local hPlayer = GetEntity(hPlayerID)
    if (not hPlayer or not hPlayer.IsPlayer) then
        return true
    end

    local hItem = GetEntity(hItemID)

    return true
end

----------------------
ServerItemHandler.CanUseWeapon = function(self, hPlayerID, hItemID)

    local hPlayer = GetEntity(hPlayerID)
    if (not hPlayer or not hPlayer.IsPlayer) then
        return true
    end

    local hItem = GetEntity(hItemID)

    return true
end

----------------------
ServerItemHandler.OnPickedUp = function(self, hPlayerID, hItemID)

    local hPlayer = GetEntity(hPlayerID)
    if (not hPlayer or not hPlayer.IsPlayer) then
        return true
    end

    local hWeapon = GetEntity(hItemID)

    local aStored = (checkArray(hPlayer:GetData(ePlayerData_Equipment))[hWeapon.class])
    if (ConfigGet("General.Equipment.RestoreOnPickUp", true, eConfigGet_Boolean) and aStored) then
        hWeapon.weapon:SvRemoveAccessory("all")
        self:AttachOnWeapon(hPlayer, hWeapon, aStored, true)
        if (hPlayer:TimerExpired(ePlayerTimer_EquipmentMsg, 320, true)) then
            SendMsg(CHAT_EQUIP, hPlayer, string.format("%s", hPlayer:Localize("@l_ui_accessoryLoaded", { string.upper(hWeapon.class) })))
        end
    end
    return true
end

----------------------
ServerItemHandler.CheckHit = function(self, aHitInfo)
    return true
end

----------------------
ServerItemHandler.OnShoot = function(self, hShooter, hWeapon, vHit, vPos, vDir)

    -- TODO: Anticheat
    -- Check()

    local aShotInfo = {

        -- New Style
        Shooter = hShooter,
        Weapon  = hWeapon,
        Hit     = vHit,
        Pos     = vPos,
        Dir     = vDir,

        -- Old Style (get rid of this)
        shooter = hShooter,
        weapon  = hWeapon,
        hit     = vHit,
        pos     = vPos,
        dir     = vDir
    }

    if (not g_gameRules:OnShoot(aShotInfo)) then
        return false
    end

    if (CallEvent(eServerEvent_OnShoot, aShotInfo) == false) then
        return false
    end

    return true
end