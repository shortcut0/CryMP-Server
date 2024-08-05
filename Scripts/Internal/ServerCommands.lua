-------------------
ServerCommands = {

    DataDir = (SERVER_DIR_SCRIPTS .. "Commands\\"),
    Commands = {},

    DeveloperRank = nil,

    CommandPrefixes = {
        "!", "\\", "/"
    }
}

-------------------
ServerCommands.Init = function(self)

    Logger.CreateAbstract(self, { LogClass = "Commands", Base = ServerLog })

    AddCommand = function(...)
        ServerCommands:CreateCommand(...)
    end

    self.DeveloperRank = GetDevRanks()[1]

    ------------------------

    eCmdRet_NoFeedback = 0
    eCmdRet_Failed     = 1
    eCmdRet_Success    = 2
    eCmdRet_Ok         = 2

    -------------------------

    eCommandEvent_Disabled = 0

    -------------------------

    eCommandResponse_NoFeedback = 0 -- Command executed without returning feedback
    eCommandResponse_Failed     = 1 -- Command failed to execute
    eCommandResponse_Success    = 2 -- Command successfully executed

    eCommandResponse_NotFound   = 3 -- No Results
    eCommandResponse_ManyFound  = 4 -- More than one result

    eCommandResponse_ScriptError        = 5 -- Script Error
    eCommandResponse_ConditionNotMet    = 6 -- Script Error


    self.CommandPrefixes = ConfigGet("Commands.Prefixes", self.CommandPrefixes, eConfigGet_Array)

    self:LoadCommands()
    self:Log("Loaded %d Commands", table.count(self.Commands))
    Logger:LogEvent(eLogEvent_Commands, string.format("Loaded ${red}%d${gray} Commands", table.count(self.Commands)))


    -- FIXME (test)
    --self:SendResponse(GetPlayers()[1], eCommandResponse_Failed, "TESTCOMMAND:o", "@l_commanderr_test")
end

-------------------
ServerCommands.OnChatMessage = function(self, iType, hSender, hTarget, sMessage)

    local sPrefix = self:HasCommandPrefix(sMessage)
    if (sPrefix) then
        self:OnCommand(hSender, self:RemovePrefix(sMessage, sPrefix))
        return true
    end

    return false
end

-------------------
ServerCommands.OnCommand = function(self, hClient, sMessage)

    local aArgs = string.split(string.gsuba(sMessage, {
        { "%s+", " " },
        { "%s$", "" },
        { "^%s", "" }
    }), " ")

    if (table.empty(aArgs)) then
        return
    end

    local iUserRank = hClient:GetAccess()

    local sCommand = aArgs[1]
    local aCommands = self:FindCommand(99, string.lower(sCommand))
    local iCommands = table.count(aCommands)
    if (iCommands == 0) then

        return self:SendResponse(hClient, eCommandResponse_NotFound, sCommand)
    elseif (iCommands > 1) then

        local aShow
        local iFound = 0
        for _, aFound in pairs(aCommands) do
            if (iUserRank >= aFound.Access) then
                iFound = (iFound + 1)
                table.insert(aShow, aFound)
            else
            end
        end

        self:ListCommands(hClient, aShow)
        return self:SendResponse(hClient, eCommandResponse_ManyFound, sCommand, iFound)
    end

    local aCommand = aCommands[1]
    self:ProcessCommand(hClient, aCommand, { unpack(aArgs, 2) })
end

-------------------
ServerCommands.ListCommands = function(self, hClient, aList)

    aList = (aList or table.copy(self.Commands))
    ServerLog("listing............................")

end

-------------------
ServerCommands.ProcessCommand = function(self, hClient, aCommand, aUserArgs)

    local sName     = aCommand.Name
    local sDesc     = aCommand.Description
    local fCmdFunc  = aCommand.Function
    local aCmdArgs  = (aCommand.Arguments or {})
    local aCmdProps = (aCommand.Properties or {})

    local sLang     = hClient:GetPreferredLanguage()

    local aHost
    local aHostCondition = (aCmdProps.HostCondition)
    local sHost = (aCmdProps.Host or aCmdProps.Self or aCmdProps.This)


    local iUserRank = hClient:GetAccess()
    local iUserArgs = table.count(aUserArgs)
    local aPushArgs = {}
    local bOk
    local sArg, sArgLower
    local hTemp


    if (sHost) then
        aHost = checkGlobal(sHost)
        if (not aHost) then

            HandleError("Failed to add Command %s (%s)", sName, "Host not Found")
            return self:SendResponse(hClient, eCommandResponse_ScriptError, sName, "Error: Bad Host Provided")
        end
    else
        aHost = hClient
    end

    local aTestArgument = {
        Name     = "Hello :3",
        Desc     = "nothing here!!",
        Required = true,

        Optional = false,
        IsPlayer = false,
        SelfOk   = true, -- Accept "self" as the user
        AllOk    = true, -- Accept "all" for all users

        IsNumber = false,
        Max      = 0,
        Min      = 0,
        Concat   = false,

        Default  = "Default Value",
    }

    local aTestProperties = {

        NoChatResponse = false,     -- Never show chat response
        NoConsoleResponse = false,  -- Never show console response

        Quiet = true,       -- Command returns are surpressed and only returns no feedback
        Hidden = true,      -- Command is hidden
        Disabled = false,   -- Command is disabled

        Host = nil,       -- The host (self)
        HostCondition = { -- Conditions the host must have

            IgnoreSilence = true,
            ErrorMessage = "Bad",   -- Failed Message (TEST: Failed (Bad))
            Key = "Info.Validated", -- The Key that to check
            Value = { false, nil }, -- Required value(s) for the key
            Min = 0,                -- Min
            Max = 0,                -- & Max value for the key
        },

        ForcedReturn = {
            Not = eCommandResponse_Success,
            Then = eCommandResponse_NotFound
        }
    }

    local aValues, sKey, hVal, iMin, iMax, sMsg, iMsg
    if (aHost and aHostCondition) then
        sKey    = aHostCondition.Key
        aValues = aHostCondition.Value
        iMin    = aHostCondition.Min
        iMax    = aHostCondition.Max
        sMsg    = (aHostCondition.ErrorMessage or nil)

        if (sKey) then

            hVal = table.getnested(aHost, sKey)

            if (isNumber(hVal) and iMin and hVal < iMin) then
                iMsg = eCommandResponse_ConditionNotMet

            elseif (isNumber(hVal) and iMax and hVal > iMax) then
                iMsg = eCommandResponse_ConditionNotMet

            elseif (not IsAny(hVal, unpack(aValues))) then
                iMsg = eCommandResponse_ConditionNotMet

            end
            if (iMsg) then
                if (sMsg) then
                    iMsg = eCommandResponse_Failed
                end
                return self:SendResponse(hClient, iMsg, sName, sMsg)
            end
        end
    end

    for _, aCmdArg in pairs(aCmdArgs) do

        sArg = aUserArgs[_]
        if (sArg == nil and aCmdArg.Default) then
            sArg = aCmdArg.Default
        end

        sArgLower = string.lower(sArg or "")

        bOk = true
        if (sArg == nil) then
            if (aCmdArg.Required) then
                return self:SendResponse(hClient, eCommandResponse_Failed, sName, "@l_commandarg_required", _)
            end
            bOk = false
        end

        if (bOk) then

            if (ok) then

            -- Argument expects a player
            elseif (aCmdArg.IsPlayer) then
                hTemp = GetPlayer(sArg)
                if (not hTemp) then

                    if ((aCmdArg.SelfOk or aCmdArg.AcceptSelf) and IsAny(sArgLower, "myself", "self")) then
                        hTemp = hClient
                    elseif ((aCmdArg.AllOk or aCmdArg.AcceptAll) and IsAny(sArgLower, "all", "everyone")) then
                        hTemp = ALL_PLAYERS
                    end

                    if (hTemp == nil) then
                        return self:SendResponse(hClient, eCommandResponse_Failed, sName, "@l_commandarg_player_notfounnd", sArg)
                    end
                end
                aPushArgs[_] = hTemp

            -- Argument expects a number
            elseif (aCmdArg.IsNumber) then
                hTemp = g_tn(sArg)
                if (hTemp == nil) then
                    return self:SendResponse(hClient, eCommandResponse_Failed, sName, "@l_commandarg_notnumber", _)

                elseif (aCmdArg.Min and hTemp < aCmdArg.Min) then
                    if (aCmdArg.Auto) then
                        hTemp = aCmdArg.Min
                    else
                        return self:SendResponse(hClient, eCommandResponse_Failed, sName, "@l_commandarg_toolow", _, aCmdArg.Min)
                    end

                elseif (aCmdArg.Max and hTemp > aCmdArg.Max) then
                    if (aCmdArg.Auto) then
                        hTemp = aCmdArg.Max
                    else
                        return self:SendResponse(hClient, eCommandResponse_Failed, sName, "@l_commandarg_toohigh", _, aCmdArg.Max)
                    end
                end

                aPushArgs[_] = hTemp

            -- this breaks all other arguments!
            elseif (aCmdArg.Concat) then

                for __ = _, iUserArgs do
                    hTemp = hTemp .. aUserArgs[__]
                end

                aPushArgs[_] = hTemp
                break
            else
                aPushArgs[_] = aUserArgs[_]
            end
        end
    end

    local bSuccess, sError
    local hCmdResponse, sCmdError

    if (aHost ~= hClient) then
        aPushArgs = table.insertFirst(aPushArgs, hClient)
        ServerLog("pushing client")
    end

    if (SERVER_DEBUG_MODE) then
        hCmdResponse, sCmdError = fCmdFunc(aHost, unpack(aPushArgs))
    else
        bSuccess, hCmdResponse, sCmdError = pcall(fCmdFunc, aHost, unpack(aPushArgs))
        if (not bSuccess) then

            HandleError("Executing Command %s (%s)", sName, (hCmdResponse or "<Unknown>"))
            return self:SendResponse(hClient, eCommandResponse_ScriptError, sName, (hCmdResponse or "<Unknown>"))
        end

        ServerLog("1 = %s, 2 = %s, 3 = %s", g_ts(bSuccess), g_ts(hCmdResponse), g_ts(sCmdError))
    end

    if (hCmdResponse == nil or IsAny(hCmdResponse, eCmdRet_NoFeedback)) then
        self:SendResponse(hClient, eCommandResponse_NoFeedback, sName)

    elseif (IsAny(hCmdResponse, false, eCmdRet_Failed)) then
        self:SendResponse(hClient, eCommandResponse_Failed, sName, sError)

    elseif (IsAny(hCmdResponse, true, eCmdRet_Ok, eCmdRet_Success)) then
        self:SendResponse(hClient, eCommandResponse_Success, sName, sCmdError)

    else
        error("weird command response!")
    end

    return true
end

-------------------
ServerCommands.LocalizeMessage = function(self, hClient, sMsg, aFormat)

    local sLang = hClient:GetPreferredLanguage()
    local iClientRank = hClient:GetAccess()

    local sLocalized, sExtended = Localize(sMsg, sLang, (hClient:IsDevRank()))
    if (sLocalized) then
        return Logger:FormatLocalized(sLocalized, aFormat)
    end

    return sMsg
end

-------------------
ServerCommands.SendResponse = function(self, hClient, iResponse, sCmd, sMsg, ...)

    local aCommand = self.Commands[string.lower(sCmd)]
    local bChatMsg = true
    local bConsoleMsg = true

    if (aCommand) then

        if (aCommand.Properties.Quiet) then
            if (table.getnested(aCommand, "Properties.HostCondition.IgnoreSilence") ~= true) then
                iResponse = eCommandResponse_NoFeedback
                sMsg = nil
            end
        end

        local aForced = table.getnested(aCommand, "Properties.ForcedReturn")
        if (table.size(aForced) > 0 and aForced.Then ~= nil) then
            if (aForced.Not == nil or aForced.Not ~= iResponse) then
                iResponse = aForced.Then
            end
        end

        if (table.getnested(aCommand, "Properties.NoLogging") == true) then
            return
        end

        if (table.getnested(aCommand, "Properties.NoChatResponse")) then
            bChatMsg = false
        end

        if (table.getnested(aCommand, "Properties.NoConsoleResponse")) then
            bConsoleMsg = false
        end
    end

    local sLang = hClient:GetPreferredLanguage()
    local iClientRank = hClient:GetAccess()

    -- Localize the return message (if any)
    local sLocalizedMsg
    if (sMsg) then
        sLocalizedMsg = " (".. self:LocalizeMessage(hClient, sMsg, { ... }) .. ")"
    end


    local aMsg1, aMsg2
    if (iResponse == eCommandResponse_Failed) then
        aMsg1 = { "@l_commandresp_con_failed", string.upper(sCmd), (sLocalizedMsg or sMsg or "") }
        aMsg2 = { "@l_commandresp_chat_failed", string.upper(sCmd), (sLocalizedMsg or sMsg or "") }


    elseif (iResponse == eCommandResponse_Success) then
        aMsg1 = { "@l_commandresp_con_success", string.upper(sCmd), (sLocalizedMsg or sMsg or "") }
        if (sMsg) then
            aMsg2 = { "@l_commandresp_chat_success", string.upper(sCmd), (sLocalizedMsg or sMsg or "") }
        end


    elseif (iResponse == eCommandResponse_NoFeedback) then
        aMsg1 = { "@l_commandresp_con_nofeedback", string.upper(sCmd), (sLocalizedMsg or sMsg or "") }
        --aMsg2 = { "@l_commandresp_chat_nofeedback", string.upper(sCmd), (sLocalizedMsg or sMsg or "") }


    elseif (iResponse == eCommandResponse_NotFound) then
        aMsg1 = { "@l_commandresp_con_notfound", string.upper(sCmd), (sLocalizedMsg or sMsg or "") }
        aMsg2 = { "@l_commandresp_chat_notfound", string.upper(sCmd), (sLocalizedMsg or sMsg or "") }

    elseif (iResponse == eCommandResponse_ManyFound) then
        aMsg1 = nil
        aMsg2 = { "@l_commandresp_chat_manyfound", string.upper(sCmd), (sLocalizedMsg or sMsg or "") }

    elseif (iResponse == eCommandResponse_ScriptError) then


        -- always show to dev
        if (hClient:IsDevRank()) then
            bConsoleMsg = true
            bChatMsg = true
        end

        if (aCommand) then
            if (not aCommand:IsBroken()) then
                aCommand:Disable(true, "Server", "Script Error")
                aCommand:Break(true)
            end
        end

        aMsg1 = { "@l_commandresp_con_scripterror", string.upper(sCmd), (sLocalizedMsg or sMsg or "") }
        aMsg2 = { "@l_commandresp_chat_scripterror", string.upper(sCmd), (sLocalizedMsg or sMsg or "") }

    elseif (iResponse == eCommandResponse_ConditionNotMet) then
        aMsg1 = { "@l_commandresp_con_condition", string.upper(sCmd), (sLocalizedMsg or sMsg or "") }
        aMsg2 = { "@l_commandresp_chat_condition", string.upper(sCmd), (sLocalizedMsg or sMsg or "") }

    else
        error("response not implemented " .. g_ts(iResponse))
    end

    if (aMsg1 and bConsoleMsg) then
        Logger:LogCommandEvent({ hClient }, aMsg1[1], unpack(aMsg1, 2))
    end

    if (aMsg2 and bChatMsg) then
        SendMsg(CHAT_SERVER_LOCALE, hClient, aMsg2[1], unpack(aMsg2, 2))
    end
end

-------------------
ServerCommands.FindCommand = function(self, iUserRank, sMessage, bGreedy)

    local aFound = {}
    for sName, aCommand in pairs(table.copy(self.Commands)) do
        if (string.len(sMessage) >= 1) then

            ServerLog("%s match %s", sName, sMessage)
            if (sName == sMessage) then
                table.insert(aFound, aCommand)
            elseif (string.match(sName, ("^" .. sMessage))) then
                table.insert(aFound, aCommand)
            elseif (bGreedy) then
                for i = string.len(sMessage), math.minex((string.len(sMessage) - 5), 3), -1 do

                    ServerLog("%s match %s", sName, ("^" .. string.sub(sMessage, 1, i)))
                    if (string.match(sName, ("^" .. string.sub(sMessage, 1, i)))) then
                        table.insert(aFound, aCommand)
                        break
                    end
                end
            end
        elseif (sName == string.lower(sMessage)) then
            table.insert(aFound, aCommand)
        end
    end

    if (table.empty(aFound) and not bGreedy) then

        -- Try again but be a little greedy this time
        return self:FindCommand(iUserRank, sMessage, true)
    end

    for _, aCommand in pairs(aFound) do
        if (aCommand.Access > iUserRank) then
            table.remove(aFound, _)
        end
    end
    return aFound

end

-------------------
ServerCommands.HasCommandPrefix = function(self, sMessage)

    for _, sPrefix in pairs(self.CommandPrefixes) do

        -- Don't trigger if only a prefix has been sent!
        if (string.match(sMessage, ("^" .. string.escape(sPrefix))) and string.len(sMessage) > string.len(sPrefix)) then
            return sPrefix
        end
    end
    return false

end

-------------------
ServerCommands.RemovePrefix = function(self, sMessage, sPrefix)
    return string.sub(sMessage, (string.len(sPrefix) + 1))
end

-------------------
ServerCommands.LoadCommands = function(self, sPath)

    -- Files/Folders beginning with '!' are NOT loaded!

    local sDir = (sPath or self.DataDir)
    if (string.fc((ServerLFS.DirGetName(sDir .. "\\null")), "!")) then
        return ServerLog("Ignoring directory %s", sDir)
    end
    if (not ServerLFS.DirExists(sDir)) then
        return ServerLFS.DirCreate(sDir)
    end

    local aFiles = ServerLFS.DirGetFiles(sDir, GETFILES_ALL)
    if (table.count(aFiles) == 0) then
        return
    end

    for _, sFile in pairs(aFiles) do

        if (ServerLFS.DirIsDir(sFile)) then
            self:LoadCommands(sFile)
        elseif (not string.fc(FileGetName(sFile), "!")) then
            FileLoader:ExecuteFile(sFile)
        else
            ServerLog("Ignoring file %s", sFile)
        end
    end
end

-------------------
ServerCommands.GetCommand = function(self, sName)
    return (self.Commands[string.lower(sName)])
end

-------------------
ServerCommands.LogCommandEvent = function(self, aCommand, iEvent, P1, P2, P3)

    if (iEvent == eCommandEvent_Disabled) then
        if (aCommand.Properties.Disabled) then
            Logger:LogEventTo(GetDevs(), eLogEvent_Commands, "${red}%s${gray} Command Disabled by ${red}%s${gray} (${red}%s${gray})", aCommand.Name, (P1 or "Server"), (P2 or "No Reason Specific"))
        else
            Logger:LogEventTo(GetDevs(), eLogEvent_Commands, "${red}%s${gray} Command Enabled by ${red}%s${gray}", aCommand.Name, (P1 or "Server"))
        end
    end
end

-------------------
ServerCommands.CreateCommand = function(self, aInfo)

    local sName   = aInfo.Name
    local fFunc   = aInfo.Function
    local iAccess = aInfo.Access
    local sDesc   = aInfo.Description
    if (sDesc) then end

    if (not sName) then
        error("no name specified")
    end

    if (not fFunc) then
        error("no function specified")
    end

    if (not iAccess) then
        -- FIXME
        error("no access specified")
    end

    sName = string.lower(sName)
    if (self:GetCommand(sName)) then
        -- FIXME
        error("command already exists!")
    end

    local aCommand = table.copy(aInfo)
    aCommand.IsHidden       = function(this) return this.Properties.Hidden end
    aCommand.Hide           = function(this, mode) this.Properties.Hidden = mode end
    aCommand.IsQuiet        = function(this) return this.Properties.Quiet end
    aCommand.Silence        = function(this, mode) this.Properties.Quiet = mode end
    aCommand.IsBroken       = function(this) return this.Properties.Broken end
    aCommand.Break          = function(this, mode) this.Properties.Broken = mode end
    aCommand.IsDisabled     = function(this) return this.Properties.Disabled end
    aCommand.Disable        = function(this, mode, manager, reason) this.Properties.Disabled = mode ServerCommands:LogCommandEvent(this, eCommandEvent_Disabled, manager, reason) end
    aCommand.GetDescription = function(this) return (this.Description or "No Description") end
    aCommand.SetDescription = function(this, text) this.Description = text end

    self.Commands[sName] = aCommand
end