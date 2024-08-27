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