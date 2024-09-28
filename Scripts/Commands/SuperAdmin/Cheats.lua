------------
AddCommand({
    Name = "noclip",
    Access = RANK_ADMIN,

    Arguments = {
        { "@l_ui_mode", "@l_ui_mode_d", IsNumber = true, Min = 0, Max = 3, Required = true, Default = 2 },
        { "@l_ui_player", "@l_ui_player_d", IsPlayer = true, Required = true, Default = "self", SelfOk = true }
    },

    Properties = {
    },

    -- self is the user unless specified otherwise
    Function = function(self, iMode, hPlayer)

        local bOn = iMode
        if (iMode == 0 or (iMode == hPlayer.ClientTemp.NoClip)) then
            bOn = false
        end

        hPlayer.ClientTemp.NoClip = bOn
        hPlayer:Execute("g_Client.NO_CLIP = " .. g_ts(bOn))

        if (self == hPlayer) then
            SendMsg(CHAT_SERVER, self, self:Localize("@l_ui_noClipEnabled", { bOn and "@l_ui_enabled" or "@l_ui_disabled" }))
        else
            SendMsg(CHAT_SERVER, hPlayer, hPlayer:Localize("@l_ui_noClipEnabled", { bOn and "@l_ui_enabled" or "@l_ui_disabled" }))
            SendMsg(CHAT_SERVER, self, self:Localize("@l_ui_noClipEnabledOn", { hPlayer:GetName(), bOn and "@l_ui_enabled" or "@l_ui_disabled" }))
        end
    end
})

------------
AddCommand({
    Name = "crazygun",
    Access = RANK_ADMIN,

    Arguments = {
        { "@l_ui_ItemClass", "@l_ui_ItemClass_d", Optional = true },
    },

    Properties = {
    },

    -- self is the user unless specified otherwise
    Function = function(self, sAmmo)

        local hCrazyGun = GetEntity(self.CrazyGunId)
        if (hCrazyGun) then
            System.RemoveEntity(hCrazyGun.id)
        end

        if (IsAny(sAmmo, nil, self.CrazyAmmo, "reset", "remove", "0")) then
            self.CrazyAmmo = nil
            -- FIXME: Locale
            return true, self:Localize("(AMMO: @l_ui_removed")
        end

        local sClass, sError = ServerUtils.FindItemByClass(self, sAmmo)
        if (not sClass) then
            return false, sError
        end

        self.CrazyAmmo = sClass
        return true, self:Localize("(AMMO: " .. string.upper(sClass) .. " @l_ui_enabled")
    end
})

------------
AddCommand({
    Name = "crazyammo",
    Access = RANK_ADMIN,

    Arguments = {
        { "@l_ui_ItemClass", "@l_ui_ItemClass_d", Optional = true },
    },

    Properties = {
        Spectating = false
    },

    -- self is the user unless specified otherwise
    Function = function(self, sClass)

        local hItem = GetEntity(self:GetCurrentItem() or self:GiveItem("SCAR"))
        if (not hItem) then
            return false, self:Localize("@l_ui_noItemsFound")
        end

        if (IsAny(sClass, hItem.CrazyProjectile, "reset", "remove", "0")) then
            hItem.CrazyProjectile = nil
            -- FIXME: Locale
            return true, self:Localize("(AMMO: @l_ui_removed")
        end

        local aItems = table.merge(
                new(ServerItemSystem:GetRegisteredAmmoClasses()),
                new(ServerItemSystem:GetRegisteredItemClasses())
        )
        local iItems = table.size(aItems)
        if (iItems == 0) then
            return nil, self:Localize("@l_ui_noListFound")
        end

        local aFound
        if (sClass) then
            aFound = table.it(aItems, function(x, i, v)
                local t = x
                local n = { Name = v.Name, ID = v.ID, Type = v.Type }
                local a = string.lower(v.Name)
                local b = string.lower(sClass)
                if (a == b) then
                    return { n }
                elseif (string.len(b) > 1 and string.match(a, "^" .. b)) then
                    if (t) then
                        table.insert(t, n)
                        return t
                    end
                    return { n }
                end
                return t
            end)

            if (table.count(aFound) == 0) then aFound = nil end
        end

        if (sClass == nil or (not aFound or table.count(aFound) > 1)) then
            ListToConsole({
                Client      = self,
                List        = (aFound or aItems),
                Title       = self:Localize("@l_ui_itemList"),
                ItemWidth   = 20,
                PerLine     = 4,
                Index       = "Name"
            })
            return nil, self:Localize("@l_ui_entitiesListedInConsole", { table.count((aFound or aItems)) })
        end

        Debug(aFound)

        aFound = aFound[1]
        local hType = aFound.Type
        if (hType == eItemType_Ammo) then
            hItem.CrazyProjectile = aFound.ID
        else

            hItem.CrazyItem = aFound.ID
        end
        return true, self:Localize("(AMMO: " .. aFound.Name .. " @l_ui_enabled")
    end
})