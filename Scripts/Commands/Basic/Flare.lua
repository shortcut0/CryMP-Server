------------
AddCommand({
    Name = "flare",
    Access = RANK_GUEST,
    Properties = {
        Cooldown = 120,
    },
    Function = function(self)
        SpawnEffect((GetCVar("e_time_of_day") <= 12 and ePE_FlareNight or ePE_Flare), self:GetPos())
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