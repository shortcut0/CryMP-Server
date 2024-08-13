------------
AddCommand({
    Name = "players",
    Access = RANK_MODERATOR, -- Must be accessible to all!

    Arguments = {
        {
            Name = "@l_ui_index",
            Desc = "@l_ui_index_d",
            Optional = true,
            IsNumber = true
        },
    },

    Properties = {
        Self = "PlayerHandler"
    },

    Function = function(self, hPlayer, hIndex)
        return self:ListPlayers(hPlayer, hIndex)
    end
})

------------
AddCommand({
    Name = "lookup",
    Access = RANK_MODERATOR, -- Must be accessible to all!

    Arguments = {
        {
            Name = "@l_ui_player",
            Desc = "@l_ui_player_d",
            Required = true,
            IsPlayer = true
        },
    },

    Properties = {
        Self = "PlayerHandler"
    },

    Function = function(self, hPlayer, hTarget)
        return self:PlayerInfo(hPlayer, hTarget)
    end
})