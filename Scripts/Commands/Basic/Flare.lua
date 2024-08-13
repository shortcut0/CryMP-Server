------------
AddCommand({
    Name = "flare",
    Access = RANK_GUEST,
    Properties = {
        Cooldown = 120,
    },
    Function = function(self)
        SpawnEffect(ePE_Flare, self:GetPos())
    end
})

------------
AddCommand({
    Name = "firework",
    Access = RANK_GUEST,
    Properties = {
        Cooldown = 120,
    },
    Function = function(self)
        SpawnEffect(ePE_Firework, self:GetPos())
    end
})