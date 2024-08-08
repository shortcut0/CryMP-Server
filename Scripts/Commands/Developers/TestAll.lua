------------
AddCommand({
    Name = "testcommand",
    Access = RANK_DEVELOPER, -- Must be accessible to all!

    Arguments = {
        { "1", nil, Required = true },
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

------------
AddCommand({
    Name = "testspeed",
    Access = RANK_DEVELOPER, -- Must be accessible to all!

    Arguments = {
    },

    Properties = {
    },

    Function = function(self)

        local x = timernew()
        for i = 1, 1000000 do
            GetTimestamp()
        end
        SendMsg(CHAT_DEBUG, "Test1 Took %fs", x.diff_refresh())

        for i = 1, 1000000 do

        end
        SendMsg(CHAT_DEBUG, "Test2 Took %fs", x.diff_refresh())

        return true
    end
})

------------
AddCommand({
    Name = "aaaaaaaaahhhhh:3",
    Access = RANK_DEVELOPER, -- Must be accessible to all!

    Arguments = {
    },

    Properties = {
    },

    Function = function(self)

        self.CollectedHits={}
    end
})
------------
AddCommand({
    Name = "testaccsoorssdfjlsdkf:3",
    Access = RANK_DEVELOPER, -- Must be accessible to all!

    Arguments = {
    },

    Properties = {
    },

    Function = function(self)

        ServerItemHandler:AttachOnWeapon(self,self:GetCurrentItem(),{"LAMRifle"})
    end
})