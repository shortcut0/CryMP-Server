------------
AddCommand({
    Name = "initclient",
    Access = RANK_ADMIN, -- Must be accessible to all!

    Arguments = {
        { "@l_ui_player", "@l_ui_player_d", Optional = true, Default = "self", AllOk = true, SelfOk = true, IsPlayer = true }
    },

    Properties = {
    },

    Function = function(self, hClient)
        if (hClient == ALL_PLAYERS) then
            for _, hTarget in pairs(GetPlayers()) do
                PlayerHandler.RegisterFunctions(hTarget, hTarget:GetChannel())
            end
            SendMsg(CHAT_SERVER, self, "(Initializing all Players)")
            return true
        end

        PlayerHandler.RegisterFunctions(hClient, hClient:GetChannel())
        SendMsg(CHAT_SERVER, self, string.format("(%s: Initializing)", hClient:GetName()))
        return true
    end
})

------------
AddCommand({
    Name = "revive",
    Access = RANK_ADMIN, -- Must be accessible to all!

    Arguments = {
        { "@l_ui_player", "@l_ui_player_d", Optional = true, Default = "self", AllOk = true, SelfOk = true, IsPlayer = true },
        { "@l_ui_spawnpoint", "@l_ui_spawnpoint_revive_d", Optional = true }
    },

    Properties = {
    },

    Function = function(self, hClient, bSpawn)

        if (hClient == ALL_PLAYERS) then
            for _, hTarget in pairs(GetPlayers()) do
                hTarget:Revive(1, 1, (bSpawn ~= nil))
                SpawnEffect(ePE_Light, hTarget:GetPos())
            end

            -- TODO: Locale
            SendMsg(CHAT_SERVER, self, string.format("(%s)", self:Localize("@l_ui_revived_all")))
            return true
        end

        -- TODO: Locale
        hClient:Revive(1, 1, (bSpawn ~= nil))
        SpawnEffect(ePE_Light, hClient:GetPos())
        SendMsg(CHAT_SERVER, self, string.format("(%s: %s)", hClient:GetName(), self:Localize("@l_ui_revived")))
        return true
    end
})