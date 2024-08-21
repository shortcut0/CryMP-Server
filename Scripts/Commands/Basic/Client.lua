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
        NoConsoleResponse = true
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
        NoConsoleResponse = true
    },

    Function = function(self, x, sCVar, sValue)
        ServerDefense:CheckCVar(self, x, sCVar, sValue)
        return true
    end
})