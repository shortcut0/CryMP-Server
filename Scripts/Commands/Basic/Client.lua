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