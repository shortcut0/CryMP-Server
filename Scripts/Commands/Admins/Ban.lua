------------
AddCommand({
    Name = "ban",
    Access = RANK_ADMIN,

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
            Name = "@l_ui_time",
            Desc = "@l_ui_time_d",
            Default = "30m",
            Optional = true,
            IsTime = true,
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

        if (isNumber(hTarget)) then
            return ServerPunish:BanChannel(hPlayer, hTarget, sTime, sReason)
        end

        return ServerPunish:BanPlayer(hPlayer, hTarget, sTime, sReason)
    end
})

------------
AddCommand({
    Name = "unban",
    Access = RANK_ADMIN,

    Arguments = {
        {
            Name = "@l_ui_player",
            Desc = "@l_ui_player_d",
            Required = true,
            Predicate = function(arg)
                return (g_tn(arg) and ServerChannels:IsChannelConnecting(g_tn(arg))), g_tn(arg)
            end
        },
    },

    Properties = {
        Self = "ServerPunish"
    },

    -- self is the user unless specified otherwise
    Function = function(self, hPlayer, sID)
        return self:TryRemoveBan(hPlayer, sID)
    end
})

------------
AddCommand({
    Name = "banlist",
    Access = RANK_ADMIN,

    Arguments = {
        {
            Name = "@l_ui_index",
            Desc = "@l_ui_index_d",
            Optional = true,
            Default = "l"
        },
        {
            Name = "@l_ui_option",
            Desc = "@l_ui_option_d",
            Optional = true,
        },
    },

    Properties = {
        Self = "ServerPunish"
    },

    -- self is the user unless specified otherwise
    Function = function(self, hPlayer, sID, sOption)
        return self:ListBans(hPlayer, sID, sOption)
    end
})