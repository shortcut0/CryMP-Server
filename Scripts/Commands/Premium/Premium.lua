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

------------
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