------------
AddCommand({
    Name = "map",
    Access = GetLowestRank(), -- Must be accessible to all!

    Arguments = {
        {   Name = "@l_ui_map",
            Desc = "@l_ui_changeMap_d",
        },
        {
            Name = "@l_ui_countdown",
            Desc = "@l_ui_countdown_d",
            IsNumber = true,
            Optional = true,
            Min = 0,
            Max = FIVE_MINUTES,
            Auto = true
        }
    },

    Properties = {
    },

    Function = function(self, sMap, iCountdown)
        if (sMap == nil or not self:HasAccess(RANK_MODERATOR)) then
            return true, self:Localize("@l_ui_currentMap", { ServerMaps:GetLevel() })
        end

        return ServerMaps:StartMap(self, sMap, iCountdown)
    end
})

------------
AddCommand({
    Name = "maplist",
    Access = GetLowestRank(), -- Must be accessible to all!

    Arguments = {
        {   Name = "@l_ui_filter",
            Desc = "@l_ui_filter_d",
        },
    },

    Properties = {
    },

    Function = function(self, sFilter)
        return ServerMaps:ListMaps(self, sFilter)
    end
})

------------
AddCommand({
    Name = "nextmap",
    Access = GetLowestRank(), -- Must be accessible to all!

    Arguments = {
        {
            Name = "@l_ui_countdown",
            Desc = "@l_ui_countdown_d",
            IsNumber = true,
            Optional = true,
            Min = 0,
            Max = FIVE_MINUTES,
            Auto = true
        }
    },

    Properties = {
    },

    Function = function(self, iCountdown)
        if (not self:HasAccess(RANK_MODERATOR)) then
            return self:Localize("@l_ui_nextMap", { ServerMaps:GetNextLevel() })
        end

        return ServerMaps:StartNextMap(self, iCountdown)
    end
})

------------
AddCommand({
    Name = "endgame",
    Access = RANK_MODERATOR, -- Must be accessible to all!

    Arguments = {
    },

    Properties = {
        This = "g_gameRules"
    },

    Function = function(self)

        if (self.IS_PS) then
            self:EndGameWithWinner_PS()
        else
            self:EndGameWithWinner_IA()
        end
    end
})

------------
AddCommand({
    Name = "timelimit",
    Access = RANK_MODERATOR,

    Arguments = {
        {
            Name = "@l_ui_time",
            Desc = "@l_ui_time_d",
            IsNumber = true,
            IsTime = true,
            Required = true,
            Min = 1,
            Max = MAXIMUM_TIMELIMIT * 60,
            Auto = true
        }
    },

    Properties = {
    },

    Function = function(self, iNewLimit)
        return ServerMaps:SetTimeLimit(self, iNewLimit/60)
    end
})

------------
AddCommand({
    Name = "restart",
    Access = RANK_MODERATOR,

    Arguments = {
        {
            Name = "@l_ui_time",
            Desc = "@l_ui_time_d",
            IsNumber = true,
            IsTime = true,
            Default = 5,
            Required = true,
            Min = 1,
            Max = 60,
            Auto = true
        }
    },

    Properties = {
    },

    Function = function(self, iCountdown)
        return ServerMaps:RestartMap(self, iCountdown)
    end
})