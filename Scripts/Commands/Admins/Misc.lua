------------
AddCommand({
    Name = "getammo",
    Access = RANK_ADMIN, -- Must be accessible to all!

    Arguments = {
        {
            Name = "@l_ui_target",
            Desc = "@l_ui_target_d",
            AllOk = true,
            SelfOk = true,
            Default = "self",
            IsPlayer = true,
        }
    },

    Properties = {
       -- PowerStruggle = true
    },

    -- self is the user unless specified otherwise
    Function = function(self, hTarget)
        local aItems
        if (hTarget ~= ALL_PLAYERS) then

            local sYou = "@l_ui_yourself"
            if (hTarget ~= self) then
                sYou = hTarget:GetName()
            end

            aItems = self:GetEquipment()
            if (table.empty(aItems)) then
                return false, self:LocalizeNest("@l_ui_HaveNoEquipment", { sYou })
            end

            local hThis = (hTarget or self)
            local iRefilled = 0
            for _, aInfo in pairs(aItems) do
                local hItem = hThis.inventory:GetItemByClass(aInfo[1])
                if (hItem) then
                    if ((ServerItemHandler:RefillAmmo(hThis, hItem) or 0) > 0) then
                        iRefilled = iRefilled + 1
                    end
                end
            end

            if (iRefilled == 0) then
                return true, self:LocalizeNest("@l_ui_NoEquipmentRefilled", {sYou})
            end
            return true, self:LocalizeNest("@l_ui_EquipmentRefilled", { sYou, iRefilled })
        else
            for _, hPlayer in pairs(GetPlayers()) do
                aItems = hPlayer:GetEquipment()

                local iRefilled = 0
                if (table.count(aItems) > 0) then
                    for _, aInfo in pairs(aItems) do
                        local hItem = hPlayer.inventory:GetItemByClass(aInfo[1])
                        if (hItem) then
                            if ((ServerItemHandler:RefillAmmo(hPlayer, hItem) or 0) > 0) then
                                iRefilled = iRefilled + 1
                            end
                        end
                    end
                end
                if (hPlayer ~= self) then
                    SendMsg(CHAT_SERVER, hPlayer, hPlayer:Localize("@l_ui_EquipmentRefilled", {"@l_ui_yourself",iRefilled}))
                end
            end
            return true, self:LocalizeNest("@l_ui_AllEquipmentRefilled")
        end
        return true
    end
})

------------
AddCommand({
    Name = "tod",
    Access = RANK_ADMIN, -- Must be accessible to all!

    Arguments = {
        {
            Name = "@l_ui_time",
            Desc = "@l_ui_time_d",
            IsNumber = true,
            Optional = true
        }
    },

    Properties = {
    },

    -- self is the user unless specified otherwise
    Function = function(self, iTOD)

        local iCurrentTOD = GetCVar("e_time_of_day")
        if (iTOD == nil) then
            SendMsg(CHAT_SERVER, self, self:LocalizeNest("(@l_ui_timeofday: " .. FormatTOD(g_tn(iCurrentTOD), "@l_ui_am", "@l_ui_pm")) .. ")", {})
            return true
        end

        FSetCVar("e_time_of_day", g_ts(iTOD))
        SendMsg(CHAT_SERVER, self, self:LocalizeNest("(@l_ui_timeofday: @l_ui_SET_TO " .. FormatTOD(g_tn(iTOD), "@l_ui_am", "@l_ui_pm")) .. ")", {})
        SendMsg(MSG_ERROR, ALL_PLAYERS, "@l_ui_TODChanged", FormatTOD(iTOD, "@l_ui_am", "@l_ui_pm"), " (Admin Decision)")
        return true
    end
})