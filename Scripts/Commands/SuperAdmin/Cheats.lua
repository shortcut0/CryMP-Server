------------
AddCommand({
    Name = "noclip",
    Access = GetLowestRank(),

    Arguments = {
        {  "@l_ui_player", "@l_ui_player_d", IsPlayer = true, Required = true, Default = "self", SelfOk = true },
        { "@l_ui_mode", "@l_ui_mode_d", IsNumber = true, Min = 0, Max = 3, Required = true, Default = 2 }
    },

    Properties = {
    },

    -- self is the user unless specified otherwise
    Function = function(self, hPlayer, iMode)

        local bOn = iMode
        if (iMode == 0) then
            bOn = false
        end

        hPlayer.ClientTemp.NoClip = bOn
        hPlayer:Execute("g_Client.NO_CLIP = " .. g_ts(iMode))

        if (self == hPlayer) then
            SendMsg(CHAT_SERVER, self, self:Localize("@l_ui_noClipEnabled", { bOn and "@l_ui_enabled" or "@l_ui_disabled" }))
        else
            SendMsg(CHAT_SERVER, hPlayer, hPlayer:Localize("@l_ui_noClipEnabled", { bOn and "@l_ui_enabled" or "@l_ui_disabled" }))
            SendMsg(CHAT_SERVER, self, self:Localize("@l_ui_noClipEnabledOn", { hPlayer:GetName(), bOn and "@l_ui_enabled" or "@l_ui_disabled" }))
        end
    end
})