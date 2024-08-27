------------
AddCommand({
    Name = "testcommand",
    Access = RANK_DEVELOPER, -- Must be accessible to all!

    Arguments = {
        {},
     --[[   { "1", nil, Required = true },
        { "2", "-", Required = true, Default = "null" },
        { "3", "-", IsNumber = true },
        { "4", "-", IsNumber = true, Min = 1 },
        { "5", "-", IsNumber = true, Max = 10 },
        { "6", "-", IsNumber = true, Max = 11, Min = 3, Auto = false },
        { "7", "-", IsNumber = true, Max = 15, Min = 3, Auto = true },
        { "8", "-", IsPlayer = true, Required = true,AcceptAll = true },
        { "9", "-", IsPlayer = true, Required = true, AcceptAll = true },
        { "10", "-", Concat = true },]]
    },

    Properties = {
    },

    Function = function(self, s,...)


        do return self:IsPremium() end


        ClientMod:OnAll([[g_Client.FA[g_localActorId]={ENTITY=g_localActor,ANIM="]]..s..[["}g_localActor:StartAnimation(0,"]]..s..[[",8)]]or[[


local XY = g_localActor.inventory:GetCurrentItem()

if false then XY:LoadCharacter(0,'objects/weapons/us/at_mine/at_mine_fp.chr') end

        g_localActor.inventory:GetCurrentItem():StartAnimation(0,"]]..s..[[",8)
        g_localActor.inventory:GetCurrentItem().item:PlayAction("pickup_weapon_left",1,1)
        ]])


        do return end
        PlaySound({
            File = "sounds/physics:bullet_impact:mat_concrete_50cal",
            Pos = self:GetPos(),
            Vol = 69
        })
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
    Name = "aaaaaaaa",
    Access = RANK_DEVELOPER, -- Must be accessible to all!

    Arguments = {
    },

    Properties = {
    },

    Function = function(self)

        Debug(ParseTime("10m"))
        self.CollectedHits={}
    end
})
------------
AddCommand({
    Name = "testlocale",
    Access = RANK_DEVELOPER, -- Must be accessible to all!

    Arguments = {
    },

    Properties = {
    },

    Function = function(self)

        Debug(self:LocalizeNest("@l_ui_testNestedLocale_STACKOVERFLOW", {"1"},{"2"}))
    end
})
------------
AddCommand({
    Name = "spamrmi",
    Access = RANK_DEVELOPER, -- Must be accessible to all!

    Arguments = {
    },

    Properties = {
    },

    Function = function(self)

        for i = 1, 1000 do
            g_gameRules.onClient:ClStartWorking(self:GetChannel(), self.id,[[hello=]]..UpdateCounter())
        end
    end
})
------------
AddCommand({
    Name = "pushstatus",
    Access = RANK_DEVELOPER, -- Must be accessible to all!

    Arguments = {
    },

    Properties = {
    },

    Function = function(self)

        ServerPublisher:UpdateServer()
    end
})
------------
AddCommand({
    Name = "testsyncedS",
    Access = RANK_DEVELOPER, -- Must be accessible to all!

    Arguments = {
    },

    Properties = {
    },

    Function = function(self)

        ClientMod:OnAll([[ClientLog("executed ONCE. readyfor sync!")]], {
            Sync = true,
            SyncID = "testSync",
            BindID = self.id,
            Server = function(_client_, _info_)
                Debug("heelo madafaka ", _client_:GetName())
            end
        })
        ClientMod:OnAll([[ClientLog("executed ONCE. readyfor sync!")]], {
            Sync = true,
            SyncID = "testSync",
            Server = function(_client_, _info_)
                Debug("heelo madafaka!!!! ", _client_:GetName())
            end
        })
    end
})