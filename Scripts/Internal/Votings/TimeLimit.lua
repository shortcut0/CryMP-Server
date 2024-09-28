CreateVoteType("time", {
    Name = "time",
    Title = "@l_ui_voteMapTitle",
    Description = "@l_ui_voteTime_d",
    VoteMessage = "@l_ui_voteToAddTime",

    Functions = {

        Condition   = function(self, hUser)

            if (not g_pGame:IsTimeLimited()) then
                return false, hUser:Localize("@l_ui_noTimeLimit")
            end

            local iTime = ParseTime("45m")

            return VOTE_OK, string.format("$4@l_ui_add %s$9, ", math.calctime(iTime)), iTime
        end,

        OnFail      = function(self, hUser, aParams)
        end,

        OnSuccess   = function(self, hUser)

            SendMsg(CHAT_VOTING_LOCALE, ALL_PLAYERS, "@l_ui_addedTimeLimit", math.calctime(self.VoteReturn))
            ServerMaps:AddTimeLimit(self.VoteReturn)
        end,

        OnStart     = function(self, hUser, aParams)
        end,
    }
})