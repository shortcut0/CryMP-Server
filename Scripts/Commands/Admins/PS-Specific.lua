
------------
AddCommand({
    Name = "award",
    Access = RANK_ADMIN, -- Must be accessible to all!

    Arguments = {
        { "@l_ui_player", "@l_ui_player_d", Optional = true, Default = "self", AllOk = true, SelfOk = true, IsPlayer = true },
        { "@l_ui_amount", "@l_ui_amount_d", Required = true, IsNumber = true, Min = 1, Max = MAXIMUM_PRESTIGE, Auto = true }
    },

    Properties = {
        PowerStruggle = true,
        Host = "g_gameRules",
    },

    Function = function(self, hClient, hTarget, iAmount)

        if (hClient == ALL_PLAYERS) then
            for _, hUser in pairs(GetPlayers()) do
                hUser:AwardPrestige(iAmount, hUser:Localize("@l_ui_admindecision"))
            end

            SendMsg(CHAT_SERVER, self, string.format("(%s)", self:Localize("@l_ui_prestigeAwardedAll")))
            return true
        end

        hTarget:AwardPrestige(iAmount, hTarget:Localize("@l_ui_admindecision"))
        SendMsg(CHAT_SERVER, hClient, string.format("(%s)", hClient:Localize("@l_ui_prestigeAwarded", { hTarget:GetName(), iAmount })))
        return true
    end
})

------------
AddCommand({
    Name = "team",
    Access = RANK_ADMIN, -- Must be accessible to all!

    Arguments = {
        { "@l_ui_player", "@l_ui_player_d", Optional = true, Default = "self", AllOk = true, SelfOk = true, IsPlayer = true },
        { "@l_ui_amount", "@l_ui_amount_d", Required = true, IsNumber = true, Min = 0, Max = TEAM_END, Auto = true, Transform = { ["nk"] = TEAM_NK, ["us"] = TEAM_US, ["neutral"] = TEAM_NEUTRAL } }
    },

    Properties = {
        PowerStruggle = true,
        Host = "g_gameRules",
    },

    Function = function(self, hClient, hTarget, iTeam)

        local sTeamName = GetTeamName(iTeam)

        if (hClient == ALL_PLAYERS) then
            for _, hUser in pairs(GetPlayers()) do
                hUser:SetTeam(iTeam)
            end

            SendMsg(CHAT_SERVER, self, string.format("(%s)", self:Localize("@l_ui_movedToTeamAll", { sTeamName })))
            return true
        end

        if (hTarget:GetTeam() == iTeam) then
            return false, hClient:Localize("@l_ui_targetAlreadyInTeam", { hTarget:GetName(), sTeamName })
        end
        hTarget:SetTeam(iTeam)
        SendMsg(CHAT_SERVER, hClient, string.format("(%s)", hClient:Localize("@l_ui_movedToTeam", { hTarget:GetName(), sTeamName })))
        return true
    end
})