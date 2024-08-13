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

        local vPos = self:GetFacingPos(eFacing_Front, 5, eFollow_Auto, 3)
        SvSpawnEntity({

            Pos = vPos,
            Dir = self.actor:GetRotation(),

            Command = true,
            Admin   = self,
            Class   = aFound[1],
            Count   = iCount
        })
        SpawnEffect(ePE_Light, vPos)

        SendMsg(CHAT_SERVER, self, self:Localize("@l_ui_entitiesSpawned", { aFound[1], iCount }))
        Logger:LogEventTo(self:GetAccess(), eLogEvent_Game, self:Localize("@l_ui_entitiesSpawned_console", { self:GetName(), aFound[1], iCount }))
    end
})