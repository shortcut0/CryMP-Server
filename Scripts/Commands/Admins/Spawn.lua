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
    Name = "delclass",
    Access = RANK_ADMIN, -- Must be accessible to all!

    ----------------------------------------
    Arguments = {
        {
            Name = "@l_ui_entityClass",
            Desc = "@l_ui_entityClass_d",
            Optional = true
        },
    },

    ----------------------------------------
    Properties = {
    },

    ----------------------------------------
    Function = function(self, sClass)

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

        local iDeleted = 0
        local bAllowAll = self:IsTesting()
        for _, hEntity in pairs(System.GetEntities()) do
            if (hEntity.class == aFound[1] and (
                    hEntity.id ~= Server.ServerEntity.id
                    and not hEntity.IsChatEntity
                    and not hEntity.IsPlayer
                    and not hEntity.IsServer
                    and hEntity.class ~= "Factory"
                    and (bAllowAll or (
                            not hEntity.IsImportant
                    ))
            )) then
                System.RemoveEntity(hEntity.id)
                iDeleted = iDeleted + 1
            end
        end

        SendMsg(CHAT_SERVER, self, self:Localize("@l_ui_entitiesDeleted", { aFound[1], iDeleted }))
        Logger:LogEventTo(self:GetAccess(), eLogEvent_Game, self:Localize("@l_ui_entitiesDeleted_console", { self:GetName(), aFound[1], iDeleted }))
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
        Cooldown = 15,
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
                Usable = false,

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

------------
AddCommand({
    Name = "st",
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
        Cooldown = 15,
    },

    ----------------------------------------
    Function = function(self, iCount)

        local vPos = self:GetFacingPos(eFacing_Front, 8, eFollow_Auto, 1)
        for i = 1, iCount do

            local aParams = {
                Physics = true,
                Mass = 10,
                Rigid = true,
                Resting = false,
                Pickable = true,
                Usable = false,

                Model = getrandom({
                    "objects/library/storage/barrels/barrel_red.cgf";
                    "objects/library/storage/barrels/barrel_black.cgf";
                    "objects/library/storage/barrels/barrel_blue.cgf";
                    "objects/library/storage/barrels/barrel_green.cgf";
                    "objects/library/storage/barrels/barrel_explosiv_black.cgf";
                    "Objects/Library/storage/trashcontainers/trashbag.cgf";
                    "objects/library/storage/trashcontainers/trashcon_med_a.cgf";
                    "Objects/Library/storage/trashcontainers/trashcon_orange_a.cgf";
                    "Objects/Library/storage/trashcontainers/trashcon_orange_b.cgf";
                    "Objects/Library/storage/trashcontainers/trashcon_orange_c.cgf";
                    "Objects/Library/Props/trashbins/trash_container_small.cgf";
                    "Objects/Library/Props/trashbins/trash_wooden_a.cgf";
                    "Objects/Library/Props/trashbins/trash_wooden_b.cgf";
                    "Objects/Library/Props/trashbins/trash_wooden_c.cgf";
                    "Objects/Library/Props/trashbins/trash_wooden_d.cgf";
                    "objects/library/props/trashbins/trashbin.cgf";
                    "objects/library/props/trashbins/trash_container_big.cgf";
                    "Objects/Library/Props/misc/trashbin_small/trashbin_small.cgf";
                    "Objects/Library/Props/misc/trashbin_small/trashbin_small_base.cgf";
                    "Objects/Library/Props/bananafarm_tank/bananafarm_tank.cgf";
                    "objects/library/props/building material/steel_beam_pack.cgf";
                    "objects/library/props/building material/reinforced_pipe_servicehatch_grate.cgf";
                    "objects/library/props/building material/tube_stack.cgf";
                    "objects/library/props/building material/steel_support_beam_vertical.cgf";
                    "objects/library/props/building material/steel_support_beam_vertical_a.cgf";
                    "objects/library/props/building material/steel_support_beam_vertical_b.cgf";
                    "objects/library/props/building material/steel_support_beam_vertical_c.cgf";
                    "objects/library/props/building material/wooden_shelves.cgf";
                    "objects/library/props/building material/wooden_stack.cgf";
                    "objects/library/props/building material/wooden_support_beam_b_closed.cgf";
                    "objects/library/props/electronic_devices/coffeemaker/coffeemaker.cgf";
                    "objects/library/props/electronic_devices/computer_racks/flightcase_small_computer.cgf";
                    "objects/library/props/electronic_devices/computer_racks/flightcase_small_closed.cgf";
                    "objects/library/props/electronic_devices/computer_racks/flightcase_small_open.cgf";
                    "objects/library/props/electronic_devices/computer_racks/server/server_03.cgf";
                    "objects/library/props/electronic_devices/misc/asian_artifact_scanner/asian_artifact_scanner_bottom.cgf";
                    "objects/library/props/electronic_devices/screens/television_old.cgf";
                    "objects/library/props/fish/fish2_double.cgf";
                    "objects/library/props/fishing_nets/cage_a.cgf";
                    "objects/library/props/flowers/flowerpot_harbour_a.cgf";
                    "objects/library/props/flowers/flowerpot_harbour_l_a_pink.cgf";
                    "objects/library/props/flowers/flowerpot_harbour_s_a_white.cgf";
                    "objects/library/props/kable_drum_wooden/kable_drum_wooden_b.cgf";
                    "objects/library/props/misc/cooker/cooker.cgf";
                    "objects/library/props/misc/pushcart/pushcart.cgf";
                    "objects/library/props/misc/shopping_cart/shopping_cart.cgf";
                    "objects/library/props/misc/washing_machine/washing_machine.cgf";
                    "objects/library/props/oiltanks/oiltank2_destroyed.cgf";
                    "objects/library/props/school/table_a.cgf";
                    "objects/library/props/school/table_b.cgf";
                    "objects/library/props/school/table_c.cgf";
                    "objects/library/props/stacks/harbor_stack_small.cgf";
                    "objects/library/props/stonelantern/stonelantern.cgf";
                    "objects/library/props/watermine/watermine.cgf";
                    "objects/library/storage/palettes/palettes_pack_small.cgf";
                    "objects/library/storage/palettes/palettes_pack_big.cgf";
                    "objects/library/storage/palettes/palettes_pack_big_mp.cgf";
                    "objects/library/storage/palettes/palettes_pack_med.cgf";
                }),
                Pos = vector.randomize(vPos, math.min(20, math.max(5, iCount)), true, true),
                Dir = self:SmartGetDir(1),
                Pickable = true,
                Network = true
            }
            g_pGame:ScheduleEntityRemoval(SpawnGUI(aParams).id, 120, false)
        end

        SpawnEffect(ePE_Light, vPos)
        SendMsg(CHAT_SERVER, self, self:Localize("@l_ui_entitiesSpawned", { "GUI", iCount }))
        Logger:LogEventTo(self:GetAccess(), eLogEvent_Game, self:Localize("@l_ui_entitiesSpawned_console", { self:GetName(), "GUI", iCount }))
    end
})

------------
AddCommand({
    Name = "testeffect",
    Access = RANK_ADMIN, -- Must be accessible to all!

    ----------------------------------------
    Arguments = {
        {
            Name = "@l_ui_argument",
            Desc = "@l_ui_argument_d",
            Required = true,
        }, { Name = "@l_ui_distance", Desc = "@l_ui_distance_d", Optional = true, IsNumber = true, Min = 1, Max = 10000, Auto = true }
    },

    ----------------------------------------
    Properties = {
    },

    ----------------------------------------
    Function = function(self, sEffect, iDistance)

        local vPos = self:GetFacingPos(eFacing_Front, iDistance, eFollow_Auto, 5)
        SpawnEffect(sEffect, vPos)
        SendMsg(CHAT_SERVER, self, self:Localize("@l_ui_hereIsYour", { sEffect }))
    end
})