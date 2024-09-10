------------
AddCommand({
    Name = "premium",
    Access = RANK_PREMIUM, -- Must be accessible to all!

    Arguments = {
    },

    Properties = {
    },

    -- self is the user unless specified otherwise
    Function = function(self, hPlayer, sRank)
    end
})

-- =====================================================================================
AddCommand({
    Name = "bigfirework",
    Access = RANK_PREMIUM,
    Properties = {
        Cooldown = 120,
        Cost = 25,
    },
    Function = function(self)
        SpawnEffect(ePE_Firework, self:GetPos(), g_Vectors.up, 2)
    end
})

-- =====================================================================================
AddCommand({
    Name = "modelid",
    Access = RANK_PREMIUM,

    Arguments = {
        { Name = "@l_ui_index", Desc = "@l_ui_index_d", Optional = true, IsNumber = true }
    },

    Properties = {
        Cooldown = 10,
    },

    -- self is the user unless specified otherwise
    Function = function(self, hID)
        return ClientMod:RequestModel(self, hID)
    end
})

-- =====================================================================================
AddCommand({
    Name = "vehiclemodel",
    Access = RANK_PREMIUM,

    Arguments = {
        { Name = "@l_ui_index", Desc = "@l_ui_index_d", Optional = true, IsNumber = true }
    },

    Properties = {
        Cooldown = 10,
    },

    -- self is the user unless specified otherwise
    Function = function(self, hID)
        return ClientMod:ChangeVehicleModel(self, nil, hID)
    end
})

-- =====================================================================================
AddCommand({
    Name = "headid",
    Access = RANK_PREMIUM,

    Arguments = {
        { Name = "@l_ui_index", Desc = "@l_ui_index_d", Optional = true, IsNumber = true }
    },

    Properties = {
        Cooldown = 10,
    },

    -- self is the user unless specified otherwise
    Function = function(self, hID)
        return ClientMod:RequestHead(self, hID)
    end
})

-- =====================================================================================
AddCommand({
    Name = "playas",
    Access = RANK_PREMIUM,

    Arguments = {
        { Name = "@l_ui_index", Desc = "@l_ui_index_d", Optional = true, IsNumber = true }
    },

    Properties = {
        Cooldown = 10,
    },

    -- self is the user unless specified otherwise
    Function = function(self, hID)
        return ClientMod:RequestCharacter(self, hID)
    end
})

------------
AddCommand({
    Name = "turtle",
    Access = RANK_PREMIUM,
    Arguments = {},
    Properties = {
        Cooldown = 10,
    },
    Function = function(self) return ClientMod:RequestCharacter(self, CHAR_TURTLE) end
})

------------
AddCommand({
    Name = "shark",
    Access = RANK_PREMIUM,
    Arguments = {},
    Properties = {
        Cooldown = 10,
    },
    Function = function(self) return ClientMod:RequestCharacter(self, CHAR_SHARK) end
})

------------
AddCommand({
    Name = "trooper",
    Access = RANK_PREMIUM,
    Arguments = {},
    Properties = {
        Cooldown = 10,
    },
    Function = function(self) return ClientMod:RequestCharacter(self, CHAR_TROOPER) end
})

------------
AddCommand({
    Name = "crab",
    Access = RANK_PREMIUM,
    Arguments = {},
    Properties = {
        Cooldown = 10,
    },
    Function = function(self) return ClientMod:RequestCharacter(self, CHAR_CRAB) end
})

------------
AddCommand({
    Name = "finch",
    Access = RANK_PREMIUM,
    Arguments = {},
    Properties = {
        Cooldown = 10,
    },
    Function = function(self) return ClientMod:RequestCharacter(self, CM_FINCH) end
})

------------
AddCommand({
    Name = "monkeywalk",
    Access = RANK_PREMIUM,
    Arguments = {},
    Properties = {
        Cooldown = 10,
    },
    Function = function(self)
        self.ClientTemp.HasMonkeyWalk = (not self.ClientTemp.HasMonkeyWalk)
        ClientMod:OnAll(string.format("g_Client:AddLA(GP(%d),'%s',%s)",
                self:GetChannel(),
                "misc_replaceMe_01",
                g_ts(self.ClientTemp.HasMonkeyWalk)
        ), {
            Sync = true,
            SyncID = "monkeywalk",
            BindID = self.id,
            Check = function() return self and self.ClientTemp.HasMonkeyWalk ~= false end
        })
    end
})

-- =====================================================================================
AddCommand({
    Name 	= "jump",
    Access	= RANK_PREMIUM,
    Args = {},

    Properties = {
        Indoors  = false,
        Flying   = false,
        Cooldown = 320,
        Price    = 50,
        Alive    = true,
        Vehicle  = false
    },

    Function = function(self)

        local vPos = self:GetPos()
        local vUp  = vector.modifyz(vPos, 150)

        SpawnEffect(ePE_AlienBeam, vPos)
        SpawnEffect(ePE_Light, vPos)
        SpawnEffect(ePE_Light, vUp)

        self:GiveItem("Parachute")
        g_pGame:MovePlayer(self.id, vUp, self:GetAngles())
        SendMsg(CHAT_SERVER_LOCALE, ALL_PLAYERS, "@l_ui_superJumped", self:GetName())
        return true
    end
})