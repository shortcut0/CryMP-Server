-----------------
ServerVoting = {

    DataPath = (SERVER_DIR_INTERNAL .. "Votings\\"),
    VoteTypes = {},
    ActiveVote = {}
}

-----------------

VOTE_OK = 1

-----------------
ServerVoting.Init = function(self)

    LinkEvent(eServerEvent_ScriptTick, "ServerVoting", self.Tick)
    CreateVoteType = function(...) return self:CreateVoteType(...)  end

    self:LoadFiles()
end

-----------------
ServerVoting.LoadFiles = function(self)

    -- TODO: Make it recursive
    local aFiles = ServerLFS.DirGetFiles(self.DataPath, GETFILES_FILES, ".*\.lua$")
    if (table.empty(aFiles)) then
        return
    end

    for _, sFile in pairs(aFiles) do
        if (not FileLoader:LoadFile(sFile)) then

            -- TODO: Error Handler
            -- ErrorHandler()

            HandleError("Failed to load file %s (%s)", ServerLFS.FileGetName(sFile), FileLoader.LAST_ERROR)
        end

    end
end

-----------------
ServerVoting.VoteYes = function(self, hUser)

    if (not self.ActiveVote.Active) then
        return false, hUser:Localize("@l_ui_noVoteActive")
    end

    self.ActiveVote.Yes = self.ActiveVote.Yes + 1
    if (hUser.VotedNo) then
        self.ActiveVote.No = self.ActiveVote.No + 1
    end

    hUser.VotedNo = false
    hUser.VotedYes = true

    SendMsg(CHAT_VOTING_LOCALE, hUser, hUser:Localize("@l_ui_youVotedYES"))
end

-----------------
ServerVoting.VoteNo = function(self, hUser)

    if (not self.ActiveVote.Active) then
        return false, hUser:Localize("@l_ui_noVoteActive")
    end

    self.ActiveVote.No = self.ActiveVote.No + 1
    if (hUser.VotedYes) then
        self.ActiveVote.Yes = self.ActiveVote.Yes + 1
    end

    hUser.VotedNo = true
    hUser.VotedYes = false

    SendMsg(CHAT_VOTING_LOCALE, hUser, hUser:Localize("@l_ui_youVotedNO"))
end

-----------------
ServerVoting.StartVote = function(self, hUser, sName, sArg, ...)

    sName = string.lower(sName)
    if (sName == "stop" or sName == "end") then
        if (hUser:HasAccess(RANK_MODERATOR)) then
            self:StopVote(hUser, sName == "stop") -- "end" ends it, stop cancels it without executing whatever action
            return
        end
    end

    local aVote = self:FindVote(sName)
    if (not aVote) then
        return false, hUser:Localize("@l_ui_voteNotFound", {sName})
    end

    if (self.ActiveVote.Active) then
        return false, hUser:Localize("@l_ui_voteInProgress", {self.ActiveVote.Name})
    end

    local iMinPlayers = aVote.MinimumPlayers
    if (iMinPlayers and iMinPlayers < GetPlayers(1)) then
        return false, hUser:Localize("@l_ui_insufficientPlayersOnline")
    end

    local bOk, sVoteMsg, hVoteRet = aVote.Functions.Condition(self, hUser, sArg, ...)
    if (bOk ~= VOTE_OK) then
        return bOk, sVoteMsg
    end

    self.ActiveVote = {
        Active  = true,
        Name    = aVote.Name,
        Desc    = aVote.Desc,
        Title   = aVote.Title,

        VoteReturn = hVoteRet,
        Funcs = aVote.Functions,

        Args = { sArg, ... },
        User = hUser,

        Yes = 0,
        No = 0,

        RequiredPercent = aVote.RequiredPercent or 51,
        RequiredYes = aVote.RequiredYes or 1,

        EndTime = 60,

        Timer = timernew(),
        MessageTimer = timernew(9.9)
    }

    Logger:LogEvent(eLogEvent_Voting, "@l_ui_votingStarted_c",
            aVote.Name:upper(),
            sVoteMsg or "",
            math.calctime(self.ActiveVote.EndTime)
    )
    SendMsg(CHAT_VOTING_LOCALE, ALL_PLAYERS, "@l_ui_votingStarted",
        aVote.Name:upper(),
            string.gsub(sVoteMsg or "", string.COLOR_CODE,""),
            math.calctime(self.ActiveVote.EndTime)
    )

    g_pGame:SetSynchedGlobalValue(800, 0) -- vote status
    g_pGame:SetSynchedGlobalValue(801, 0) -- vote ENDED
    g_pGame:SetSynchedGlobalValue(802, aVote.Name or "<Unknown>") -- vote title
    g_pGame:SetSynchedGlobalValue(803, aVote.Title) -- vote title
    g_pGame:SetSynchedGlobalValue(804, aVote.Desc) -- vote title
    g_pGame:SetSynchedGlobalValue(805, 0) -- vote title
    g_pGame:SetSynchedGlobalValue(806, 0) -- vote title
    g_pGame:SetSynchedGlobalValue(807, hUser:GetChannel()) -- vote title
    g_pGame:SetSynchedGlobalValue(808, hUser:GetChannel()) -- vote title
    g_pGame:SetSynchedGlobalValue(809, self.ActiveVote.EndTime) -- REMAINING TIME
    g_pGame:SetSynchedGlobalValue(810, "ACTIVE") -- REMAINING TIME

end

-----------------
ServerVoting.VoteMessage = function(self)

    local aCurrent = self.ActiveVote
    local iYes = aCurrent.Yes
    local iNo  = aCurrent.No

    --SendMsg(MSG_ERROR, ALL_PLAYERS, ("@l_ui_playermutedby"), 1, 33333, "0fsdjh lsdfjk ")

    Logger:LogEvent(eLogEvent_Voting, "@l_ui_voteMessageConsole",
            aCurrent.Name:upper(),
            math.calctime(aCurrent.EndTime - aCurrent.Timer.diff_t()),
            iYes, iNo
    )
    SendMsg(CHAT_VOTING_LOCALE, ALL_PLAYERS, "@l_ui_voteMessage",
            aCurrent.Name:upper(),
            iYes, iNo,
            math.calctime(aCurrent.EndTime - aCurrent.Timer.diff_t())
    )
end

-----------------
ServerVoting.Tick = function(self, bForceMessage)

    local aCurrent = self.ActiveVote
    if (aCurrent.Active) then

        g_pGame:SetSynchedGlobalValue(809, math.floor(self.ActiveVote.EndTime - aCurrent.Timer.diff())) -- REMAINING TIME

        if (aCurrent.Timer.expired(aCurrent.EndTime)) then
            --Debug("vote time bad")
            Debug("stop now!")
            self:StopVote()
        elseif (aCurrent.MessageTimer.expired()) then
            self:VoteMessage()
            aCurrent.MessageTimer.refresh()
        end
    elseif (not aCurrent.Reset) then
        self:ResetVote()
    end
end

-----------------
ServerVoting.ResetVote = function(self)

    g_pGame:SetSynchedGlobalValue(800, 0) -- vote status
    g_pGame:SetSynchedGlobalValue(801, 1) -- vote ENDED
    g_pGame:SetSynchedGlobalValue(810, "ENDED") -- REMAINING TIME

    ServerLog("end!")

    Script.SetTimer(2500, function()
        g_pGame:SetSynchedGlobalValue(801, 0) -- vote ENDED
    end)

    self.ActiveVote = {
        Active = false,
        Reset  = true
    }

    for _, hPlayer in pairs(GetPlayers()) do
        hPlayer.VotedNo = nil
        hPlayer.VotedYes = nil
    end
end

-----------------
ServerVoting.StopVote = function(self, hAdmin, bCancel)

    local aCurrent = self.ActiveVote
    if (not aCurrent.Active) then
        return false, hAdmin and hAdmin:Localize("@l_ui_noVoteActive")
    end

    local sReason = "@l_ui_voteEnded"
    local sMsg = ""

    local iYes = aCurrent.Yes
    local iNo  = aCurrent.No

    local iYesPercent = (iYes / iNo)
    if (iNo == 0) then iYesPercent = 100 end -- nan fix
    if (iYes == 0) then iYesPercent = 0 end -- nan fix

    local bFailed = false
    if (iYesPercent < aCurrent.RequiredPercent) then
        sMsg = "@l_ui_voteInsufficientVotes"
        bFailed = true
    end

    if (not bFailed and iYes < aCurrent.RequiredYes) then
        bFailed = true
        sMsg = "@l_ui_voteInsufficientYes"
    end

    if (bCancel) then
        if (hAdmin) then
            sMsg = "$4@l_ui_cancelledBy " .. hAdmin:GetName()
        else
            sMsg = "@l_ui_cancelled"
        end
        bFailed = true
    elseif (hAdmin) then
        sMsg = " ($4@l_ui_stoppedBy " .. hAdmin:GetName() .. "$9)"
    end

    if (bFailed) then

        Logger:LogEvent(eLogEvent_Voting, "$4%s$9 @l_ui_votingFailed ($4%s$9)",
                aCurrent.Name:upper(),
                sMsg
        )
        SendMsg(CHAT_VOTING_LOCALE, ALL_PLAYERS, string.format("(%s: @l_ui_votingFailed_c (%s)",
                aCurrent.Name:upper(),
                string.gsub(sMsg, string.COLOR_CODE, "")
        ), iYesPercent, iYes, iNo)

        aCurrent.Funcs.OnFail(aCurrent, aCurrent.User, aCurrent.Args)

    else

        Logger:LogEvent(eLogEvent_Voting, "$4%s$9 @l_ui_votingSucceeded %s",
                aCurrent.Name:upper(),
                sMsg
        )
        SendMsg(CHAT_VOTING_LOCALE, ALL_PLAYERS, string.format("(%s: @l_ui_votingSucceeded_c%s)",
                aCurrent.Name:upper(),
                string.gsub(sMsg, string.COLOR_CODE, "")
        ), iYesPercent, iYes, iNo)

        aCurrent.Funcs.OnSuccess(aCurrent, aCurrent.User, aCurrent.Args)
    end

    self:ResetVote()
end

-----------------
ServerVoting.FindVote = function(self, sID)
    return self.VoteTypes[string.lower(sID)]
end

-----------------
ServerVoting.CreateVoteType = function(self, sID, aParams)

    if (self:FindVote(sID)) then
        HandleError("Overwritig vote type " .. g_ts(sID))
    end

    self.VoteTypes[sID] = {

        Title = aParams.Title,
        Name = aParams.Name,
        Desc = aParams.Description,

        MinimumVoters = 1,
        MinimumPercent = 51,
        MinimumPlayers = 1,

        VoteArgs = {},

        Functions = {

            Condition   = aParams.Functions.Condition,
            OnFail      = aParams.Functions.OnFail,
            OnSuccess   = aParams.Functions.OnSuccess,
            OnStart     = aParams.Functions.OnStart,
            GetMessage  = aParams.VoteMessage

        }
    }
end

-----------------
ServerVoting.GetVoteType = function(self, sID)
    return self.VoteTypes[sID]
end