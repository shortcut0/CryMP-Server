CreateVoteType("kick", {
    Name = "kick",
    Title = "@l_ui_voteMapTitle",--UNUSED
    Description = "@l_ui_voteTime_d",--UNUSED
    VoteMessage = "@l_ui_voteToAddTime",--UNUSED

    RequiredPercent = 75,

    Functions = {


        Condition   = function(self, hUser, hTargetID)

            -- HELLO! move to STartVote() and make it an "option" or "parameter" property??!??!? yuss???!?!? jksdjkf
            if (not ConfigGet("General.Voting.AllowKickVote", true, eConfigGet_Boolean)) then
                return false, hUser:Localize("@l_ui_voteTypeDisabled")
            end

            local hLastKick = hUser:GetData(ePlayerData_LastKickVote)
            if (hLastKick and (hLastKick > 0 and GetTimestamp() - hLastKick < THREE_HOURS)) then
                return false, hUser:Localize("@l_commandresp_cooldown", math.calctime(THREE_HOURS - (GetTimestamp() - hLastKick)))
            end

            local hTarget = GetPlayer(hTargetID)
            if (not hTarget) then
                return false, hUser:Localize("@l_ui_playerNotFound")
            end

            if (hTarget:GetAccess() > hUser:GetAccess()) then
                return false, hUser:Localize("@l_ui_insufficientAccess")
            end

            return VOTE_OK, string.format("$4@l_ui_kick %s$9, ", hTarget:GetName()), hTarget
        end,

        OnFail      = function(self, hUser, aParams)
        end,

        OnSuccess   = function(self, hUser)

            local iExpiry = ConfigGet("General.Voting.VoteKickReset", THREE_HOURS, eConfigGet_Number)
            local iBanThreshold = ConfigGet("General.Voting.VoteKickBanThreshold", 3, eConfigGet_Number)

            local hVictim = GetEntity(self.VoteReturn)
            if (hVictim) then
                hVictim.VoteKicked = true
                hVictim:AddData(ePlayerData_ConsecutiveVoteKicks, 1)

                local hLastVoteKicked = hVictim:GetData(ePlayerData_LastVoteKicked) --GetTimestamp()-THREE_HOURS-1--
                if (hLastVoteKicked and GetTimestamp() - hLastVoteKicked >= iExpiry) then
                    hVictim:SetData(ePlayerData_ConsecutiveVoteKicks, 1) -- reset
                end
                if (hVictim:GetData(ePlayerData_ConsecutiveVoteKicks) > iBanThreshold) then

                    -- If players get kicked more than 3 times by votes, within 3 hours, ban them for 3 hours!
                    -- Reset the counter if the last kick vote was more than 3 hours ago!
                    ServerPunish:BanPlayer(Server.ServerEntity, hVictim, "3h", "Too many Vote Kicks")
                    return
                end
                KickPlayer(self.VoteReturn, "Unanimous Vote", nil, Server.ServerEntity)
            end
        end,

        OnStart     = function(self, hUser, aParams)
        end,
    }
})