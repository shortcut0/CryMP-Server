------------
AddCommand({
    Name = "spawn",
    Access = RANK_ADMIN, -- Must be accessible to all!

    ----------------------------------------
    Arguments = {
        {
            Name = "@l_ui_entityClass",
            Desc = "@l_ui_entityClass_d",
            Optional = true
        },
        {
            Name = "@l_ui_count",
            Desc = "@l_ui_count_d",
            Required = true,
            Default = 1,
            IsNumber = true,
            Max = 100,
            Min = 1,
            Auto = true
        }
    },

    ----------------------------------------
    Properties = {
    },

    ----------------------------------------
    Function = function(self, sClass, iCount)

        local aEntities = GetEntityClasses(1)
        local iEntities = table.size(aEntities)
        if (iEntities == 0) then
            return false, self:Localize("@l_ui_noEntitiesFound")
        end

        local aFound
        if (sClass) then
            aFound = table.it(aEntities, function(x, i, v)
                local t = x
                local a = string.lower(v)
                local b = string.lower(sClass)
                if (a == b) then
                    return { v }, 1
                elseif (string.len(b) > 1 and string.match(a, "^" .. b)) then
                    if (t) then
                        table.insert(t, v)
                        return t
                    end
                    return { v }
                end
                return t
            end)

            if (table.count(aFound) == 0) then aFound = nil end
        end

        if (sClass == nil or (not aFound or table.count(aFound) > 1)) then
            ListToConsole({
                Client      = self,
                List        = (aFound or aEntities),
                Title       = self:Localize("@l_ui_entityList"),
                ItemWidth   = 20,
                PerLine     = 4,
                Value       = 1
            })
            return true, self:Localize("@l_ui_entitiesListedInConsole", { table.count((aFound or aEntities)) })
        end

        local vPos = self:GetFacingPos(eFacing_Front, 5, eFollow_Auto, 1)
        Script.SetTimer(1, function()
            SvSpawnEntity({

                Pos = vPos,
                Dir = self:SmartGetDir(1),

                Command = true,
                Admin   = self,
                Class   = aFound[1],
                Count   = iCount,

            })
        end)
        SpawnEffect(ePE_Light, vPos)

        SendMsg(CHAT_SERVER, self, self:Localize("@l_ui_entitiesSpawned", { aFound[1], iCount }))
        Logger:LogEventTo(self:GetAccess(), eLogEvent_Game, self:Localize("@l_ui_entitiesSpawned_console", { self:GetName(), aFound[1], iCount }))
    end
})

------------
AddCommand({
    Name = "equip",
    Access = RANK_ADMIN,

    ----------------------------------------
    Arguments = {
        {
            Name = "@l_ui_player",
            Desc = "@l_ui_player_d",
            Optional = true,
            IsPlayer = true,
            SelfOk = true,
            AllOk = true,
            Default = "self"
        },
        {
            Name = "@l_ui_ItemClass",
            Desc = "@l_ui_ItemClass_d",
            Optional = true,
            Required = true,
        },
        {
            Name = "@l_ui_count",
            Desc = "@l_ui_count_d",
            Optional = true,
            IsNumber = true,
            Default = 1,
            Min = 0,
            Max = 100,
            Auto = true
        },
        {
            Name = "@l_ui_attachments",
            Desc = "@l_ui_attachments_d",
        },
    },

    ----------------------------------------
    Properties = {
    },

    ----------------------------------------
    Function = function(self, hTarget, sClass, iCount, ...)

        local aItems = GetItemClasses(1)
        local iItems = table.size(aItems)
        if (iItems == 0) then
            return false, self:Localize("@l_ui_noItemsFound")
        end

        local aFound
        if (sClass) then
            aFound = table.it(aItems, function(x, i, v)
                local t = x
                local a = string.lower(v)
                local b = string.lower(sClass)
                if (a == b) then
                    return { v }, 1
                elseif (string.len(b) > 1 and string.match(a, "^" .. b)) then
                    if (t) then
                        table.insert(t, v)
                        return t
                    end
                    return { v }
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
                Value       = 1
            })
            return true, self:Localize("@l_ui_entitiesListedInConsole", { table.count((aFound or aItems)) })
        end

        local sItem = aFound[1]
        local hReceived
        local aAttachments = { ... }

        if (hTarget == ALL_PLAYERS) then

            for _, hPlayer in pairs(GetPlayer()) do
                if (hPlayer:IsAlive()) then
                    if (hPlayer ~= self) then
                        for _ = 1, iCount do
                            hReceived = hPlayer:GiveItem(sItem)
                        end
                        if (hReceived) then
                            ServerItemHandler:AttachOnWeapon(hPlayer, GetEntity(hReceived), aAttachments)
                            --hPlayer.actor:SelectItemByNameRemote(sItem)
                        end
                    end
                end
            end
            SendMsg(CHAT_SERVER, self, self:LocalizeNest("@l_ui_itemGiven", { "@l_ui_allPlayers", sItem, iCount }))
            return true
        else
            for _ = 1, iCount do
                hReceived = hTarget:GiveItem(sItem)
            end
            if (hReceived) then
                ServerItemHandler:AttachOnWeapon(hTarget, GetEntity(hReceived), aAttachments)
                --hTarget.actor:SelectItemByNameRemote(sItem)
            end
            if (hTarget ~= self) then
                SendMsg(CHAT_SERVER, self, self:Localize("@l_ui_itemGiven", { hTarget:GetName(), sItem, iCount }))
                SendMsg(CHAT_SERVER, hTarget, hTarget:Localize("@l_ui_itemReceived", { sItem, iCount }))
            else
                SendMsg(CHAT_SERVER, self, self:Localize("@l_ui_itemReceived", { sItem, iCount }))
            end
        end
        return true
    end
})

------------
AddCommand({
    Name = "sb",
    Access = RANK_ADMIN, -- Must be accessible to all!

    ----------------------------------------
    Arguments = {
        {
            Name = "@l_ui_count",
            Desc = "@l_ui_count_d",
            Required = true,
            Default = 1,
            IsNumber = true,
            Max = 100,
            Min = 1,
            Auto = true
        }, { Name = "@l_ui_argument", Desc = "@l_ui_argument_d", Optional = true}
    },

    ----------------------------------------
    Properties = {
    },

    ----------------------------------------
    Function = function(self, iCount, bExplosive)

        local vPos = self:GetFacingPos(eFacing_Front, 5, eFollow_Auto, 1)
        for i = 1, iCount do

            local aParams = {
                Physics = true,
                Mass = 10,
                Rigid = true,
                Resting = false,
                Pickable = true,
                Usable = true,

                Model = getrandom({ "objects/library/storage/barrels/barrel_blue.cgf", "objects/library/storage/barrels/barrel_green.cgf", "objects/library/storage/barrels/barrel_black.cgf", "objects/library/storage/barrels/barrel_red.cgf" }),
                Pos = vPos,
                Dir = self:SmartGetDir(1),
                Network = true
            }
            if (bExplosive) then
                aParams.Model = getrandom({ "Objects/library/storage/barrels/barrel_explosiv_black.cgf", "Objects/library/storage/barrels/barrel_explosive_red.cgf"})
                aParams.HitCfg = {
                    HP = 100,
                    Explosion = {
                        Effect = ePE_BarrelExplo,
                        Scale = 1,
                        Damage = 300,
                        Radius = 6,
                    },
                    Burning = {
                        BurnTime = 10,
                        Effect = "explosions.barrel.burn"
                    }
                }
            end
            g_pGame:ScheduleEntityRemoval(SpawnGUI(aParams).id, 120, false)
        end

        SpawnEffect(ePE_Light, vPos)
        SendMsg(CHAT_SERVER, self, self:Localize("@l_ui_entitiesSpawned", { "GUI", iCount }))
        Logger:LogEventTo(self:GetAccess(), eLogEvent_Game, self:Localize("@l_ui_entitiesSpawned_console", { self:GetName(), "GUI", iCount }))
    end
})