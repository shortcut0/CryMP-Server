------------
AddCommand({
    Name = "testcommand",
    Access = RANK_DEVELOPER, -- Must be accessible to all!

    Arguments = {
        { "1", "-", Required = true },
        { "2", "-", Required = true, Default = "null" },
        { "3", "-", IsNumber = true },
        { "4", "-", IsNumber = true, Min = 1 },
        { "5", "-", IsNumber = true, Max = 10 },
        { "6", "-", IsNumber = true, Max = 11, Min = 3, Auto = false },
        { "7", "-", IsNumber = true, Max = 15, Min = 3, Auto = true },
        { "8", "-", IsPlayer = true, Required = true,AcceptAll = true },
        { "9", "-", IsPlayer = true, Required = true, AcceptAll = true },
        { "10", "-", Concat = true },
    },

    Properties = {
    },

    Function = function(self, ...)

        --ServerLog(table.tostring({...}))
        return true
    end
})