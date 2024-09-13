------------
AddCommand({
    Name = "boxing",
    Access = GetLowestRank(),

    Arguments = {
        --  { "@l_ui_index", "@l_ui_index_d" }
    },

    Properties = {
        Alive = true
    },

    -- self is the user unless specified otherwise
    Function = function(self)
        return ServerArena:Enter(self, eARENA_BOXING)
    end
})

------------
AddCommand({
    Name = "pvp",
    Access = GetLowestRank(),

    Arguments = {
        --  { "@l_ui_index", "@l_ui_index_d" }
    },

    Properties = {
        Alive = true
    },

    -- self is the user unless specified otherwise
    Function = function(self)
        return ServerArena:Enter(self, eARENA_PVP)
    end
})

------------
AddCommand({
    Name = "arena",
    Access = GetLowestRank(),

    Arguments = {
          { "@l_ui_index", "@l_ui_index_d", IsNumber = true, Min = eARENA_MINI0, Max = aARENA_MINI0, Required = true }
    },

    Properties = {
        Alive = true
    },

    -- self is the user unless specified otherwise
    Function = function(self, iArena)
        return ServerArena:Enter(self, iArena)
    end
})

------------
AddCommand({
    Name = "joinstadium",
    Access = GetLowestRank(),

    Arguments = {
        { "@l_ui_team", "@l_ui_team_d", Optional = true, IsNumber = true, Min = 0, Max = TEAM_END, Auto = true, Transform = { ["nk"] = TEAM_NK, ["us"] = TEAM_US } }
    },

    Properties = {
        Alive = true
    },

    -- self is the user unless specified otherwise
    Function = function(self, iTeam)
        return ServerStadium:Enter(self, iTeam)
    end
})

------------
AddCommand({
    Name = "leavestadium",
    Access = GetLowestRank(),

    Arguments = {
    },

    Properties = {
        Alive = true
    },

    -- self is the user unless specified otherwise
    Function = function(self)
        return ServerStadium:Leave(self)
    end
})