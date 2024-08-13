------------
AddCommand({
    Name = "ammo",
    Access = GetLowestRank(), -- Must be accessible to all!

    Arguments = {
    },

    Properties = {
        Timer = FIVE_MINUTES,
        PowerStruggle = true
    },

    -- self is the user unless specified otherwise
    Function = function(self)
        return g_gameRules:PurchaseAmmo(self)
    end
})