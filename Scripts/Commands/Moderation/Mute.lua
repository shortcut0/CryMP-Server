------------
AddCommand({
    Name = "mute",
    Access = RANK_MODERATOR,

    Arguments = {
        {
            Name = "@l_ui_player",
            Desc = "@l_ui_player_d",
            Required = true,
            IsPlayer = true,
            EqualAccess = true,
        },
        {
            Name = "@l_ui_time",
            Desc = "@l_ui_time_d",
            Default = "30m",
            Optional = true
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
    Function = function(self, hPlayer, hTarget, sTime, sReason)
        return ServerPunish:MutePlayer(hPlayer, hTarget, sTime, sReason)
    end
})

------------
AddCommand({
    Name = "unmute",
    Access = RANK_ADMIN,

    Arguments = {
        {
            Name = "@l_ui_player",
            Desc = "@l_ui_player_d",
            Required = true,
        },
    },

    Properties = {
        Self = "ServerPunish"
    },

    -- self is the user unless specified otherwise
    Function = function(self, hPlayer, sID)
        return self:TryRemoveMute(hPlayer, sID)
    end
})