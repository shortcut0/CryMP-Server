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

-- =================================================================
AddCommand({
    Name 	= "transfer",
    Access	= RANK_GUEST,

    Arguments = {
        { "@l_ui_player", "@l_ui_player_d", IsPlayer = true, NotSelf = true, Required = true },
        { "@l_ui_amount", "@l_ui_amount_d", IsNumber = true, Min = 1, Max = 5000, Required = true }
    },

    Properties = {
        Cooldown = 60
    },

    Function = function(self, hPlayer, iAmount)

        local iPP = self:GetPrestige()
        if (iPP < iAmount) then
            return false, self:Localize("@l_ui_insufficientPrestige")
        end

        SendMsg({ MSG_CENTER }, hPlayer, hPlayer:Localize("@l_ui_prestigeReceivedC", {iAmount, self:GetName()}))
        SendMsg({ MSG_CENTER }, self, self:Localize("@l_ui_prestigeTransferredC", {iAmount, self:GetName()}))

        hPlayer:Execute(string.format([[ClientEvent(eEvent_BLE,eBLE_Currency,"%s ( +%d PP )")]],
                hPlayer:Localize("@l_ui_prestigeReceived"), iAmount
        ))
        self:Execute(string.format([[ClientEvent(eEvent_BLE,eBLE_Currency,"%s ( -%d PP )")]],
                self:Localize("@l_ui_prestigeTransferred"), iAmount
        ))

        g_gameRules:AwardPPCount(self.id, -iAmount, nil, self:HasClientMod())
        g_gameRules:AwardPPCount(hPlayer.id, iAmount, nil, hPlayer:HasClientMod())
    end
})