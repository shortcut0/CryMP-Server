------------
AddCommand({
    Name = "clerr",
    Access = GetLowestRank(), -- Must be accessible to all!

    Arguments = {
        {"",""},
        {"","",Concat=true}
    },

    Properties = {
        Hidden = true,
        NoChatResponse = true,
        NoConsoleResponse = true,
        Quiet = true
    },

    -- self is the user unless specified otherwise
    Function = function(self, sType, sMessage)
        ClientMod:OnClientError(self, sType, sMessage)
        return true
    end
})

------------
AddCommand({
    Name = "clcvar",
    Access = GetLowestRank(), -- Must be accessible to all!

    Arguments = {
        {"",""},
        {"",""},
        {"",""}
    },

    Properties = {
        Hidden = true,
        NoChatResponse = true,
        NoConsoleResponse = true,
        Quiet = true
    },

    Function = function(self, x, sCVar, sValue)
        ServerDefense:CheckCVar(self, x, sCVar, sValue)
        return true
    end
})

------------
AddCommand({
    Name = "kyong",
    Access = GetLowestRank(), -- Must be accessible to all!
    Arguments = {},
    Properties = {
        Cooldown = 10,
    },
    Function = function(self) return ClientMod:RequestModel(self, CM_KYONG) end
})

------------
AddCommand({
    Name = "prophet",
    Access = GetLowestRank(),
    Arguments = {},
    Properties = {
        Cooldown = 10,
    },
    Function = function(self) return ClientMod:RequestModel(self, CM_PROPHET) end
})

------------
AddCommand({
    Name = "aztec",
    Access = GetLowestRank(),
    Arguments = {},
    Properties = {
        Cooldown = 10,
    },
    Function = function(self) return ClientMod:RequestModel(self, CM_AZTEC) end
})

------------
AddCommand({
    Name = "psycho",
    Access = GetLowestRank(),
    Arguments = {},
    Properties = {
        Cooldown = 10,
    },
    Function = function(self) return ClientMod:RequestModel(self, CM_PSYCHO) end
})

------------
AddCommand({
    Name = "sykes",
    Access = GetLowestRank(),
    Arguments = {},
    Properties = {
        Cooldown = 10,
    },
    Function = function(self) return ClientMod:RequestModel(self, CM_PSYCHO) end
})

------------
AddCommand({
    Name = "jester",
    Access = GetLowestRank(),
    Arguments = {},
    Properties = {
        Cooldown = 10,
    },
    Function = function(self) return ClientMod:RequestModel(self, CM_JESTER) end
})

------------
AddCommand({
    Name = "korean",
    Access = GetLowestRank(),
    Arguments = {},
    Properties = {
        Cooldown = 10,
    },
    Function = function(self) return ClientMod:RequestModel(self, CM_KOREANAI) end
})

------------
AddCommand({
    Name = "chicken",
    Access = GetLowestRank(),
    Arguments = {},
    Properties = {
        Cooldown = 10,
    },
    Function = function(self) return ClientMod:RequestCharacter(self, CM_CHICKEN) end
})