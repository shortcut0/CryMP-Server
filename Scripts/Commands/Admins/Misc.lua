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