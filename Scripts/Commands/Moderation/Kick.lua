------------
AddCommand({
    Name = "kick",
    Access = RANK_MODERATOR,

    Arguments = {
        {
            Name = "@l_ui_player",
            Desc = "@l_ui_player_d",
            Required = true,
            IsPlayer = true,
            EqualAccess = true,
            Predicate = function(arg)
                return (g_tn(arg) and ServerChannels:IsChannelConnecting(g_tn(arg))), g_tn(arg)
            end
        },
        {
            Name = "@l_ui_reason",
            Desc = "@l_ui_reason_d",
            Default = "Admin Decision",
            Concat  = true
        }
    },

    Properties = {
        Self = "ServerPunish"
    },

    -- self is the user unless specified otherwise
    Function = function(self, hPlayer, hTarget, sReason)

        if (isNumber(hTarget)) then
            ServerPunish:DisconnectChannel(eKickType_Kicked, hTarget, sReason, nil, hAdmin:GetName())
            return true
        end

        ServerPunish:DisconnectPlayer(eKickType_Kicked, hTarget, sReason, nil, hAdmin:GetName())
        return true
    end
})