
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

        if (hTarget == ALL_PLAYERS) then
            for _, hUser in pairs(GetPlayers()) do
                hUser:AwardPrestige(iAmount, hUser:Localize("@l_ui_admindecision"))
            end

            SendMsg(CHAT_SERVER, hClient, string.format("(%s)", hClient:Localize("@l_ui_prestigeAwardedAll")))
            return true
        end

        hTarget:AwardPrestige(iAmount, hTarget:Localize("@l_ui_admindecision"))
        SendMsg(CHAT_SERVER, hClient, string.format("(%s)", hClient:Localize("@l_ui_prestigeAwarded", { hTarget:GetName(), iAmount })))
        return true
    end
})

------------
AddCommand({
    Name = "energy",
    Access = RANK_ADMIN, -- Must be accessible to all!

    Arguments = {
        { "@l_ui_amount", "@l_ui_amount_d", Required = true, IsNumber = true, Min = 1, Max = 100, Auto = true },
        { "@l_ui_team", "@l_ui_team_d", Optional = true, IsNumber = true, Min = 0, Max = TEAM_END, Auto = true, Transform = { ["nk"] = TEAM_NK, ["us"] = TEAM_US, ["neutral"] = TEAM_NEUTRAL } }
    },

    Properties = {
        PowerStruggle = true,
        Host = "g_gameRules",
    },

    Function = function(self, hClient, iEnergy, iTeam)

        iTeam = iTeam or hClient:GetTeam()
        g_gameRules:SetTeamPower(iTeam, iEnergy)

        SendMsg(MSG_ERROR, ALL_PLAYERS, "@l_ui_teamEnergySet", GetTeamName(iTeam), iEnergy)
        return true, hClient:Localize("@l_ui_teamEnergySet", {GetTeamName(iTeam), iEnergy})
    end
})

------------
AddCommand({
    Name = "team",
    Access = RANK_ADMIN, -- Must be accessible to all!

    Arguments = {
        { "@l_ui_player", "@l_ui_player_d", Optional = true, Default = "self", AllOk = true, SelfOk = true, IsPlayer = true },
        { "@l_ui_team", "@l_ui_team_d", Required = true, IsNumber = true, Min = 0, Max = TEAM_END, Auto = true, Transform = { ["nk"] = TEAM_NK, ["us"] = TEAM_US, ["neutral"] = TEAM_NEUTRAL } }
    },

    Properties = {
        PowerStruggle = true,
        Host = "g_gameRules",
    },

    Function = function(self, hClient, hTarget, iTeam)

        local sTeamName = GetTeamName(iTeam)

        if (hTarget == ALL_PLAYERS) then
            for _, hUser in pairs(GetPlayers()) do
                hUser:SetTeam(iTeam)
            end

            SendMsg(CHAT_SERVER, hClient, string.format("(%s)", hClient:Localize("@l_ui_movedToTeamAll", { sTeamName })))
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

------------
AddCommand({
    Name = "capture",
    Access = RANK_ADMIN, -- Must be accessible to all!

    Arguments = {
        {
            Name = "@l_ui_building",
            Desc = "@l_ui_building_d",
            Optional = true
        },
        {
            Name = "@l_ui_argument",
            Desc = "@l_ui_argument_d",
            Optional = true
        },
        {
            Name = "@l_ui_argument",
            Desc = "@l_ui_argument_d",
            Optional = true
        },
        {
            Name = "@l_ui_argument",
            Desc = "@l_ui_argument_d",
            Optional = true
        },
    },

    Properties = {
        PowerStruggle = true,
        Host = "g_gameRules",
    },

    Function = function(self, hClient, hP1, hP2, hP3)
        return self:CaptureByCommand(hClient, hP1, hP2, hP3)
    end
})