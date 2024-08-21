------------
AddCommand({
    Name = "pm",
    Access = GetLowestRank(),
    Arguments = {
        ARGUMENT_TARGET(),
        ARGUMENT_MESSAGE()
    },
    Properties = {
    },
    Function = function(self, hTarget, sMessage)
        ServerChat:SendPM(self, hTarget, sMessage)
        return true
    end
})