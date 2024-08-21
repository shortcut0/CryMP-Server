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
    },


    WeaponsEffects = {
        { Class = "AlienMount", Projectile = false, Requires = nil, Name = nil, SoundVol = 0.3, Sound = { "sounds/environment:harbor:cruiser_mg_impacts_1", "sounds/environment:harbor:cruiser_mg_impacts_2" }, Delay = 1, },
        { Class = "AlienMount", Projectile = false, Requires = "MegaAlienGun", Scale = 0.4, Name = "alien_weapons.Moac.Warrior_Turret_Impact", Damage = 15, Radius = 1.5 },

        -- Alien gun
        { Class = "SMG", Projectile = false, Requires = "AlienGun", Name = "alien_weapons.Freeze_Beam.hit", Damage = 10, Radius = 1 },

        -- Frags
        { Class = "scargrenade", OnlyOnGround = true, RemoveProjectile = true, Projectile = true, Requires = nil, Name = "ATOM_Effects.Explosions.CarpetBomb_Explosion", WaterEffect = "explosions.rocket.water", Scale = 1 },
        { Class = "explosivegrenade", OnlyOnGround = true, RemoveProjectile = true, Projectile = true, Requires = nil, Name = "ATOM_Effects.Explosions.CarpetBomb_Explosion", WaterEffect = "explosions.rocket.water", Scale = 1 },

        -- RPG
        { Class = "LAW", Projectile = true, Requires = nil, Replace = false, Name = "explosions.rocket_terrain.exocet", WaterEffect = "explosions.rocket.water", Scale = 1 },

        -- DSG, Hurricane and Gauss
        { Class = "DSG1", Projectile = false, Requires = nil, Name = "bullet.hit_rock.b_dusty", Scale = 0.8, Sound = "sounds/physics:bullet_impact:mat_concrete_50cal" },
        { Class = "Hurricane", Projectile = false, Requires = nil, Name = "bullet.hit_rock.b_dusty", Scale = 0.3, Sound = "sounds/physics:bullet_impact:mat_concrete_50cal" },
        { Class = "GaussRifle", Projectile = false, Requires = nil, Name = "alien_special.Trooper.death_explosion", Scale = 0.4 },

        -- TAC Gun
        { Class = "TACGun", Projectile = true, Requires = nil, RemoveProjectile = true, Name = "ATOM_Effects.Explosions.Medium_Explosion", Scale = 0.45, WaterEffect = {
            { "explosions.warrior.water_wake_sphere", 0.10 },
            { "explosions.mine.seamine", 5.0 },
            { "explosions.Grenade_SCAR.water", 5.0 },
            { "explosions.jet_water_impact.hit", 3.00 }
        }, WaterSound = "sounds/physics:explosions:sphere_cafe_explo_3", SoundVol = 0.90, NoWaterExplosion = true, WaterRemoveProjectile = true },

        -- TAC Tank
        { Class = "TACCannon", Projectile = true, Requires = nil, Name = "ATOM_Effects.Explosions.Nuke", Scale = 0.25, WaterEffect = {
            { "explosions.warrior.water_wake_sphere", 0.10 },
            { "explosions.mine.seamine", 5.0 },
            { "explosions.Grenade_SCAR.water", 5.0 },
            { "explosions.jet_water_impact.hit", 3.00 }
        }, WaterSound = "sounds/physics:explosions:sphere_cafe_explo_3", SoundVol = 0.90, RemoveProjectile = true },

        -- Singularity Tank
        { Class = "VehicleSingularity", Projectile = true, Requires = nil, Name = "ATOM_Effects.Explosions.Singularity_Nuke_PinkCB", Scale = 0.85, WaterEffect = {
            { "explosions.warrior.water_wake_sphere", 0.10 },
            { "explosions.mine.seamine", 5.0 },
            { "explosions.Grenade_SCAR.water", 5.0 },
            { "explosions.jet_water_impact.hit", 3.00 }
        }, WaterSound = "sounds/physics:explosions:sphere_cafe_explo_3", SoundVol = 0.90, RemoveProjectile = true },

        -- AV Mine
        { Class = "AVMine", Projectile = true, Requires = nil, Name = "ATOM_Effects.Explosions.Medium_Explosion_No_Dust", Scale = 0.2 },
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

    self.UseWeaponEffects    = ConfigGet("General.Weapons.UseWeaponEffects", true, eConfigGet_Boolean)
    self.RPGGroundEffects    = ConfigGet("General.Weapons.RPGGroundEffects", true, eConfigGet_Boolean)
    self.EnhanceUWExplosions = ConfigGet("General.Weapons.EnhanceUWExplosions", true, eConfigGet_Boolean)

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
ServerItemHandler.CanBuyVehicle = function(self, hPlayer, sVehicle, aDef)

    ServerLog("Can buy %s", sItem)

    local aForbidden = ConfigGet("General.GameRules.Buying.ForbiddenVehicles", {}, eConfigGet_Array)
    if (table.empty(aForbidden)) then
        return true
    end

    if (string.matchex(sItem, unpack(aForbidden))) then
        self:HandleMessage(hPlayer, "@l_ui_buyVehicleForbidden", { aDef.class }, MSG_ERROR)
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

                    hPlayer:Execute([[ClientEvent(eEvent_BLE,eBLE_Currency,"]]..hPlayer:LocalizeNest("@l_ui_item " .. hCurrent.class .. " @l_ui_sold ( +" .. iSellPrice .. " PP )")..[[")]])
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

                    if (hUser ~= hPlayer) then
                        hUser:Execute([[ClientEvent(eEvent_BLE,eBLE_Currency,"]]..hUser:LocalizeNest("@l_ui_investmentShare ( +" .. iShare .. " PP )")..[[")]])
                        g_gameRules:AwardPPCount(hUser.id, iShare, nil, hUser:HasClientMod())
                    end
                end
            end
        end
    end

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
    elseif (aRegular) then
        self:Equip(hPlayer, aRegular)
    end

    return true
end

----------------------
ServerItemHandler.Equip = function(self, hPlayer, aEquipment)

    Debug(aEquipment)
    local hWeapon, aStored
    for _, aInfo in pairs(aEquipment) do
        Debug(aInfo[1])
        hWeapon = GetEntity(hPlayer:GiveItem(aInfo[1]))
        if (hWeapon) then
            for __, sAttach in pairs(aInfo[2]) do
                hPlayer:GiveItem(sAttach) -- give the player the spawn attachment regardless of stored data...
            end

            aStored = (checkArray(hPlayer:GetData(ePlayerData_Equipment))[hWeapon.class])
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
                if ((bNeedsItem or bPickup)) then
                    bOk = false
                else
                    hPlayer:GiveItem(sClass, true)
                end
            end

            if (bOk) then
                if (bPickup) then
                    hWeapon.weapon:SvChangeAccessory(sClass)
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
    local aList = hWeapon.weapon:GetAttachedAccessories(1)
    return aList
end

----------------------
ServerItemHandler.OnLeaveWeaponModify = function(self, hWeapon, hOwner)

    if (not hOwner or not hOwner.IsPlayer) then
        return true
    end

    -- TODO: Save Modifications !!!!
    local aEquipmentConfig = table.checkM(hOwner:GetData(ePlayerData_Equipment, {}), hWeapon.class, {})
    aEquipmentConfig[hWeapon.class] = table.append({
        "FY71NormalAmmo",
        "SCARNormalAmmo"
    }, self:GetAttachedAccessories(hWeapon))

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

    -- Press drop twice within 2s to drop RPGs
    if (hItem.class == "LAW") then

        if (hItem.LAWDropTimer) then
            if (hItem.LAWDropTimer.expired()) then
                hItem.LAWDropTimer = nil
                return false
            end
        else
            hItem.LAWDropTimer = timernew(2)
            return false
        end
        if (not hItem.LAWDropTimer or hItem.LAWDropTimer.expired()) then
            hItem.LAWDropTimer = (hItem.LAWDropTimer or timernew(2))
            return
        end
    end

    hItem.LAWDropTimer = nil
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
    if (not hWeapon or hPlayer.inventory:GetItemByClass(hWeapon.class) ~= hItemID) then
        return
    end

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

    -----------
    local hShooter = GetEntity(aHitInfo.shooterId)
    if (hShooter and hShooter.id ~= aHitInfo.targetId and aHitInfo.target and not aHitInfo.explosion and not ServerDefense:CheckDistance(hShooter, aHitInfo.target:GetPos(), aHitInfo.pos)) then
        return false
    end

    local hObject = GetEntity(aHitInfo.shooterId)
    if (hObject and hObject.OwnerID) then

        --overwrite test
        if (hObject.OwnerID ~= aHitInfo.targetId) then
            aHitInfo.shooterId = hObject.OwnerID
            aHitInfo.damage = aHitInfo.damage * 10
        else
            aHitInfo.damage = 0
        end
    end

    return true
end

----------------------
ServerItemHandler.GetRPGEffect = function(self, hPlayer, hWeapon, vPos)
    Debug("aHit")

    local sEffectName
    local aHit = hPlayer:GetHitPos(3, nil, hPlayer:GetPos(), g_Vectors.down)
    local vNew = vPos


    if (IsPointUnderwater(vNew)) then
        sEffectName = "weapon_fx.LAW.water"
        FollowWater(vNew)

    elseif (aHit) then

        sEffectName = "weapon_fx.LAW.default"
        local idSurface = System.GetSurfaceTypeNameById(aHit.surface)
        if (idSurface == "mat_sand") then
            sEffectName = "weapon_fx.LAW.sand"

        elseif (idSurface == "mat_leaves") then
            sEffectName = "weapon_fx.LAW.leaves"

        elseif (idSurface == "mat_mud") then
            sEffectName = "weapon_fx.LAW.mud"

        elseif (idSurface == "mat_soil") then
            sEffectName = "weapon_fx.LAW.spil"

        elseif (idSurface == "mat_snow") then
            sEffectName = "weapon_fx.LAW.snow"
        end
        --FollowTerrain(vNew)
    end

    return sEffectName, vNew
end


----------------------
ServerItemHandler.OnProjectileExplosion = function(self, pWeapon, sWeapon, nProjectile, sEffect, vPos, vDir, vNormal)

    local sEffect_New  = sEffect
    local bDelete      = false
    local bNoExplosion = false

    if (self.EnhanceUWExplosions and (string.matchex(sWeapon, "C4", "explosivegrenade")) and IsPointUnderwater(vPos)) then
        SpawnEffect("explosions.Grenade_SCAR.water", FollowWater(vPos), g_Vectors.up)
    end

    local aEffects = self.WeaponsEffects
    if (aEffects) then
        for i, aEffect in pairs(aEffects) do
            if (aEffect.Class == sWeapon and (not aEffect.Requires or pWeapon[aEffect.Requires] ~= nil) and aEffect.Projectile) then

                ---------
                if (aEffect.NoExplosion) then
                    bNoExplosion = true
                end

                ---------
                local vFixedPos
                local sEffectName = aEffect.Name
                local iEffectScale = checkNumber(aEffect.Scale, 1)
                if (type(sEffectName) == "function") then
                    sEffectName, vFixedPos = sEffectName(pWeapon, vPos) end

                ---------
                if (vFixedPos) then
                    vPos = vFixedPos end

                ---------
                local bUnderWater = IsPointUnderwater(vector.modifyz(vPos, -0.85))
                if (bUnderWater) then
                    sEffectName = aEffect.WaterEffect
                    iEffectScale = checkNumber(aEffect.WaterScale, iEffectScale)
                end
                ---------
                if (aEffect.RemoveProjectile and (not aEffect.OnlyOnGround or not bUnderWater)) then
                    bDelete = true
                end

                ---------
                if (bUnderWater) then
                    if (aEffect.WaterRemoveProjectile) then
                        bDelete = true
                    end
                    if (aEffect.NoWaterExplosion) then
                        bNoExplosion = true
                    end
                end

                ---------
                if (sEffectName) then
                    if (type(sEffectName) == "table") then
                        local sNEffect, iScale
                        for ii, aTEffect in pairs(sEffectName) do
                            if (type(aTEffect) == "table") then
                                sNEffect = aTEffect[1]
                                iScale = aTEffect[2]
                            else
                                sNEffect = aTEffect
                                iScale = (aEffect.Scale or 1)
                            end

                            SpawnEffect(sNEffect, vPos, g_Vectors.up, iScale)
                        end
                    else
                        if (aEffect.Damage) then
                            SpawnExplosion(sEffectName, vPos, aEffect.Radius or 1, aEffect.Damage, g_Vectors.up, (pWeapon.weapon:GetOwner() or pWeapon), pWeapon, 1) else
                            SpawnEffect(sEffectName, vPos, g_Vectors.up, iEffectScale)
                        end
                    end
                end

                ---------
                local bWaterSoundPlayed = false
                if (bUnderWater and (aEffect.WaterSound or aEffect.WaterSound)) then
                    if (not aEffect.WaterDelay or timerexpired(aEffect.LastWater, aEffect.WaterDelay)) then
                        aEffect.LastWater = timerinit()

                        local sWaterSound = aEffect.WaterSound
                        if (isArray(sWaterSound)) then
                            sWaterSound = getrandom(sWaterSound)
                        end
                        PlaySound((sWaterSound or aEffect.Sound), vPos, aEffect.SoundVol)
                        bWaterSoundPlayed = true
                    end
                end

                ---------
                if (aEffect.Sound and not bWaterSoundPlayed) then
                    if (not aEffect.Delay or timerexpired(aEffect.Last, aEffect.Delay)) then
                        aEffect.Last = timerinit()
                        PlaySound((type(aEffect.Sound) == "table" and getrandom(aEffect.Sound) or aEffect.Sound), vPos, aEffect.SoundVol)
                    end
                end
            end
        end
    end

    local aReturn = {
        RemoveProjectile = bDelete,
        SkipExplosion    = bNoExplosion,
        Effect           = sEffect_New
    }
    return aReturn
end


----------------------
ServerItemHandler.OnProjectileHit = function(self, nShooter, nProjectile, bDead, iDamage, nWeapon, vPos, vNormal)

    local hShooter = GetEntity(nShooter)
    local hProjectile = GetEntity(nProjectile)
    if (not hShooter) then return end

    local iBonus = ConfigGet("General.GameRules.Prestige.ProjectileEliminationAward", 50, eConfigGet_Number)
    if (g_gameRules.IS_PS) then
        if (hShooter.IsPlayer) then

            Debug(hProjectile)
            if (ServerDLL.GetProjectileOwnerId(nProjectile) ~= nShooter) then
                if (hShooter:GetTeam() == g_pGame:GetTeam(nProjectile)) then
                    if (not bDead) then
                        SendMsg(MSG_CENTER, hShooter, "@l_ui_thisIsAFriendyExplosive")
                    else
                        hShooter:Execute(string.format(
                                [[ClientEvent(eEvent_BLE,eBLE_Currency,"%s ( -%d PP )")]],
                                hShooter:LocalizeNest("@l_ui_projectileEleminated",{"@l_ui_friendly "}),
                                iBonus
                        ))
                        g_gameRules:AwardPPCount(nShooter, -iBonus, nil, hShooter:HasClientMod())
                    end
                elseif (bDead) then

                    hShooter:Execute(string.format(
                            [[ClientEvent(eEvent_BLE,eBLE_Currency,"%s ( +%d PP )")]],
                            hShooter:Localize("@l_ui_projectileEleminated",{""}),
                            iBonus
                    ))
                    g_gameRules:AwardPPCount(nShooter, iBonus, nil, hShooter:HasClientMod())
                end
            else
                SendMsg(MSG_CENTER, hShooter, "@l_ui_thisIsYourExplosive")
            end
        end
    end
end


----------------------
ServerItemHandler.OnExplosiveRemoved = function(self, nPlayer, nExplosive, iType, iCount)

    local hExplosive = GetEntity(nExplosive)
    local hPlayer    = GetEntity(nPlayer)
    local sType      = ({ [2] = "C4", [0] = "Claymore", [1] = "AVMine" })[iType]

    if (hExplosive and not hExplosive.WAS_DISARMED) then

        local sMode = (iType == 2 and "@l_ui_detonated_u" or "@l_ui_exploded_u")
        SendMsg(MSG_CENTER, hPlayer, "(" .. sType:upper() .. ": " .. sMode .. " - (" .. iCount .. " @l_ui_remaining))")

        if (iType == 2) then
            if (hPlayer:HasGodMode(2)) then
                SpawnEffect("explosions.C4_explosion.fleet_reactor_wall", hExplosive:GetWorldPos())
            else
                SpawnEffect(getrandom({ "ATOM_Effects.Explosions.C4_Explosion", "ATOM_Effects.Explosions.C4_Explosion", "ATOM_Effects.Explosions.C4_Explosion", "ATOM_Effects.Explosions.C4_Explosion", ePE_C4Explosive}), hExplosive:GetWorldPos(), g_Vectors.up, getrandom(60, 80) / 100)
            end
        end
    end

end

----------------------
ServerItemHandler.OnExplosivePlaced = function(self, nPlayer, nExplosive, iType, iCount, iLimit)

    local hExplosive = GetEntity(nExplosive)
    local hPlayer    = GetEntity(nPlayer)
    local sType      = ({ [2] = "C4", [0] = "Claymore", [1] = "AVMine" })[iType]

    -- FIXME: AntiCheat()
    -- Check distance!!!

    if (iType == 2) then
        if (hPlayer.actor:GetNanoSuitMode() == NANOMODE_STRENGTH) then
            local iImpulse = 500 * (hPlayer:HasGodMode() and 1 or (hPlayer.actor:GetNanoSuitEnergy() / 200)) * (hPlayer:HasGodMode(2) and 10 or 1)
            hExplosive:AddImpulse(-1, hExplosive:GetCenterOfMassPos(),hPlayer:GetHeadDir(), iImpulse, 1)
        end
    else
        if (ConfigGet("General.Equipment.PhysicalizePlantables", false, eConfigGet_Boolean)) then
            hExplosive:SetPos(vector.modifyz(hExplosive:GetPos(), 0.15)) -- adjust position so claymores wont fall over!!
            hExplosive:Physicalize(0, PE_RIGID, {mass = 50})
        end
    end

    local bCloak = (hPlayer:GetSuitMode() == NANOMODE_CLOAK) and iType ~= 2
    if (hExplosive) then
        SendMsg(MSG_CENTER, hPlayer, "(" .. (bCloak and "@l_ui_cloaked_u-"or"") .. sType:upper() .. ": @l_ui_placed_u - (" .. iCount .. " / " .. (iLimit or -1) .. "))")
        if (bCloak) then
            local vPos = hExplosive:GetPos()
            local sCode = [[
				local vp1 = {x=]]..vPos.x..[[,y=]]..vPos.y..[[,z=]]..vPos.z..[[};local vc = ']]..hExplosive.class ..[[';local m = string.match;local e;for i, v in pairs(System.GetEntities()) do if (v.class == vc) then local vp2 = v:GetPos()  if (m(vp1.x, vp2.x) and m(vp1.y, vp2.y) and m(vp1.z, vp2.z)) then e=v break end end end if (e) then e:EnableMaterialLayer(true, 4) end
			]]
            ClientMod:OnAll(sCode, {
                BindID = hExplosive.id,
                SyncID = "EnableCloak",
                Sync = true
            })
        end
    end
end


----------------------
ServerItemHandler.OnShoot = function(self, hShooter, hWeapon, vPos, vHit, vDir)

    -----------
    --- check only weapons
    local aIgnore = {
        ["RadarKit"] = true,
        ["RepairKit"] = true,
        ["Lockpick"] = true,
    }
    if (not aIgnore[hWeapon.class] and not ServerDefense:CheckDistance(hShooter, hShooter:GetPos(), vPos)) then
        return false
    end

    local vFollowed = AutoFollow(vPos, 5, vPos)
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

    --------------------------------
    if (hShooter and hShooter.IsPlayer) then
        hShooter:OnShoot(aShotInfo)
    end

    --------------------------------
    if (not g_gameRules:OnShoot(aShotInfo)) then
        return false
    end

    --------------------------------
    if (CallEvent(eServerEvent_OnShoot, aShotInfo) == false) then
        return false
    end


    --------------------------------
    -- RPG
    if (hWeapon.class == "LAW" and self.RPGGroundEffects) then
        local sEffect, vSpawn = self:GetRPGEffect(hShooter, hWeapon, vFollowed)
        if (sEffect) then
            SpawnEffect(sEffect, vFollowed)
            SpawnEffect(ePE_Flare, vFollowed)
        end
    end


    --------------------------------
    -- Cfg
    local aEffects = self.WeaponsEffects
    if (aEffects) then
        for i, aEffect in pairs(aEffects) do
            if (aEffect.Class == hWeapon.class and (not aEffect.Requires or hWeapon[aEffect.Requires] ~= nil) and not aEffect.Projectile) then

                if (aEffect.FirePos) then
                    vHit = hShooter:GetPos()

                else
                    vDir = g_Vectors.up
                end

                ---------
                local vFixedPos
                local sEffectName = aEffect.Name
                if (type(sEffectName) == "function") then
                    sEffectName, vFixedPos = sEffectName(hShooter, hWeapon, vHit) end

                ---------
                if (vFixedPos) then
                    vHit = vFixedPos end

                ---------
                if (sEffectName) then
                    if (aEffect.Damage) then
                        SpawnExplosion(sEffectName, vHit, aEffect.Radius or 1, aEffect.Damage, vDir, hShooter, hWeapon, 1) else
                        SpawnEffectT(tostring(hWeapon.id), sEffectName, vHit, vDir, aEffect.Scale) end
                end

                ---------
                if (aEffect.Sound) then
                    if (not aEffect.Delay or timerexpired(aEffect.Last, aEffect.Delay)) then
                        aEffect.Last = timerinit()
                        PlaySound((type(aEffect.Sound) == "table" and getrandom(aEffect.Sound) or aEffect.Sound), vHit, aEffect.SoundVol)
                    end
                end
            end
        end
    end

    return true
end