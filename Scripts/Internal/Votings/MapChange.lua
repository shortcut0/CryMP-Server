CreateVoteType("map", {
    Name = "map",
    Title = "@l_ui_voteMapTitle",
    Description = "@l_ui_voteMap_d",
    VoteMessage = "@l_ui_voteToChangeMap",

    Functions = {

        Condition   = function(self, hUser, sMap)

            if (not sMap) then
                return false, hUser:Localize("@l_ui_insufficientParams")
            end

            local aInfo = ServerMaps:FindLevel(sMap)
            if (table.empty(aInfo)) then
                return false, hUser:Localize("@l_ui_levelNotFound", { sMap })
            elseif (table.size(aInfo) > 1) then
                ServerMaps:ListMaps(hUser, nil, ServerMaps:SortResults(aInfo))
                return true, hUser:Localize("@l_ui_levelsListedInConsole", { table.count(aInfo) })
            end


            if (string.lower(ServerDLL.GetMapName()) == string.lower(aInfo[1].MapPath)) then
                return false, hUser:Localize("@l_ui_chooseDifferentLevel")
            end

            return VOTE_OK, string.format("$4%s %s$9, ", aInfo[1].MapRules, string.capitalN(sMap)), aInfo[1]
        end,

        OnFail      = function(self, hUser, aParams)
        end,

        OnSuccess   = function(self, hUser)

            self.VoteReturn.EndGame     = true
            self.VoteReturn.Quiet       = true
            self.VoteReturn.ChangeTimer = 12

            ServerMaps:StartLevel(self.VoteReturn)
        end,

        OnStart     = function(self, hUser, aParams)
        end,
    }
})

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