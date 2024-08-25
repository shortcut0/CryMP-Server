------------
AddCommand({
    Name = "reset",
    Access = GetLowestRank(), -- Must be accessible to all!

    Arguments = {
    },

    Properties = {
        Cooldown = 5,
    },

    Function = function(self)

        self:SetKills(0)
        self:SetDeaths(0)

        if (g_gameRules.IS_PS) then
            self:SetRank(0)
            self:SetCP(0)
        end

        SendMsg(CHAT_SERVER, self, self:Localize("@l_ui_scoreReset"))
        PluginSaveCall("PersistentScore", "TryDeleteScore", self)
        return true
    end
})