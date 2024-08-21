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
    },

    -- self is the user unless specified otherwise
    Function = function(self, hID)
        return ClientMod:RequestModel(self, hID)
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
    },

    -- self is the user unless specified otherwise
    Function = function(self, hID)
        return ClientMod:RequestCharacter(self, hID)
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