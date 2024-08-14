-------------------
ServerCommands = {

    DataDir       = (SERVER_DIR_SCRIPTS .. "Commands\\"),
    Commands      = {},
    DeveloperRank = nil,

    -- Config
    CCommands       = 0,
    CreateCCommand  = true,
    CommandPrefixes = {
        "!", "\\", "/"
    }
}

-------------------

eCmdRet_NoFeedback = 0
eCmdRet_Failed     = 1
eCmdRet_Success    = 2
eCmdRet_Ok         = 2

-------------------------

eCommandEvent_Disabled = 0

-------------------------

eCommandResponse_NoFeedback         = 0 -- Command executed without returning feedback
eCommandResponse_Failed             = 1 -- Command failed to execute
eCommandResponse_Success            = 2 -- Command successfully executed
eCommandResponse_NotFound           = 3 -- No Results
eCommandResponse_ManyFound          = 4 -- More than one result
eCommandResponse_ScriptError        = 5 -- Script Error
eCommandResponse_ConditionNotMet    = 6 -- Unfulfilled conditions
eCommandResponse_Premium            = 7 -- It's for premium members
eCommandResponse_NoAccess           = 8 -- User doesn't have access (uses not found response!)
eCommandResponse_BadGameRules       = 9 -- User doesn't have access (uses not found response!)

-------------------------
--- Init
ServerCommands.Init = function(self)

    Logger.CreateAbstract(self, { LogClass = "Commands", Base = ServerLog })

    AddCommand = function(...)
        ServerCommands:CreateCommand(...)
    end

    self.DeveloperRank = GetDevRanks()[1]

    ------------------------


    self.CommandPrefixes = ConfigGet("Commands.Prefixes", self.CommandPrefixes, eConfigGet_Array)
    self.CreateCCommand  = ConfigGet("Commands.CreateServerCommand", self.CreateCCommand, eConfigGet_Boolean)

    self:LoadCommands()
end

-------------------
--- Init
ServerCommands.PostInit = function(self)

    ServerLog("Created (%d) Server-Console Commands", self.CCommands)
    Logger:LogEvent(eLogEvent_Commands, string.format("Loaded ${red}%d${gray} Commands", table.count(self.Commands)))
end

-------------------
--- Init
ServerCommands.OnChatMessage = function(self, iType, hSender, hTarget, sMessage)

    if (not (hSender.IsPlayer or hSender.IsServer)) then
        return
    end

    local sPrefix = self:HasCommandPrefix(sMessage)
    if (sPrefix) then
        self:OnCommand(hSender, self:RemovePrefix(sMessage, sPrefix))
        return true
    end

    return false
end

-------------------
--- Init
ServerCommands.OnCommand = function(self, hClient, sMessage)

    local aArgs = string.split(string.gsuba(sMessage, {
        { "%s+", " " },
    }), " ")

    if (table.empty(aArgs)) then
        return
    end

    local iUserRank = hClient:GetAccess()
    local sCommand = aArgs[1]
    if (sCommand == nil) then
        return true
    end

    local aCommands = self:FindCommand(99, string.lower(sCommand))
    local iCommands = table.count(aCommands)
    if (iCommands == 0) then

        return self:SendResponse(hClient, eCommandResponse_NotFound, sCommand)
    elseif (iCommands > 1) then

        local aShow = {}
        local iFound = 0
        for _, aFound in pairs(aCommands) do
            if (iUserRank >= aFound.Access) then
                iFound = (iFound + 1)
                table.insert(aShow, aFound)
            else
            end
        end

        if (iFound == 0) then
            return self:SendResponse(hClient, eCommandResponse_NotFound, sCommand)
        end

        self:ListCommands(hClient, aShow)
        return self:SendResponse(hClient, eCommandResponse_ManyFound, sCommand, iFound)
    end

    local aCommand = aCommands[1]
    local sArg2 = aArgs[2]
    if (sArg2 and (IsAny(sArg2, "-help", "help", "?", "-?", "-ayuda", "-hilfe"))) then
        return self:SendHelp(hClient, aCommand)
    end

    self:ProcessCommand(hClient, aCommand, { unpack(aArgs, 2) })
end

-------------------
--- Init
ServerCommands.SendHelp = function(self, hClient, aCommand)

    -- Misc
    local sAllPrefixes = CRY_COLOR_WHITE .. table.concat(self.CommandPrefixes, "$9, $1")
    local sSpace = "      "

    -- Cmd
    local aCopied   = table.copy(aCommand)
    local hArgs     = aCopied.Arguments
    local iAccess   = aCopied.Access
    local sDesc     = (aCopied.Description or "@l_ui_nodescription")
    local sName     = aCopied.Name

    -- Client
    local sLang = hClient:GetPreferredLanguage()

    -- Print
    local iBoxWidth = 100
    local iMaxArgLen = 0
    local sArgsLine = ""
    local sBracketColor = CRY_COLOR_GRAY
    local hArgsLocalized = table.it(hArgs, function(x, i, v)
        v.Name = TryLocalize(v.Name, sLang) -- Name
        v.Desc = TryLocalize((v.Desc or "@l_ui_nodescription"), sLang) -- Desc

        sBracketColor = CRY_COLOR_GRAY
        if (v.Required) then
            sBracketColor = CRY_COLOR_RED
        elseif (v.Optional) then
            sBracketColor = CRY_COLOR_BLUE
        end

        iMaxArgLen = math.max(iMaxArgLen, string.len(v.Name))
        if (sArgsLine == "") then
            sArgsLine = string.format("%s<%s%s%s>%s", sBracketColor, CRY_COLOR_YELLOW, v.Name, sBracketColor, CRY_COLOR_GRAY)
        else
            sArgsLine = string.format("%s, %s<%s%s%s>", sArgsLine, sBracketColor, CRY_COLOR_YELLOW, v.Name, sBracketColor, CRY_COLOR_GRAY)
        end
    end)
    local sCmdBanner    = string.format("== [ %s ] ", sName)
    local sDescBanner   = string.format("%s", TryLocalize(sDesc, sLang))

    local sLPrefix = TryLocalize("@l_ui_prefixes", sLang)
    local sLAccess = TryLocalize("@l_ui_access", sLang)
    local sLUsage  = TryLocalize("@l_ui_usage", sLang)

    local iMaxInfoLen   = math.max(string.len(sLPrefix), string.len(sLAccess), string.len(sLUsage))

    local sCommandLine  =  string.capitalN(sName)
    if (sArgsLine ~= "") then
        sCommandLine = sCommandLine .. ","
    end
    local iCommandLineLen = iMaxInfoLen + string.len(sCommandLine)

    local sPrefixLine   = string.format("%s: %s", string.rspace(sLPrefix, iMaxInfoLen, string.COLOR_CODE), sAllPrefixes)
    local sAccessLine   = string.format("%s: %s", string.rspace(sLAccess, iMaxInfoLen, string.COLOR_CODE), GetRankName(iAccess))
    local sUsageLine    = string.format("%s: %s %s", string.rspace((sLUsage), iMaxInfoLen, string.COLOR_CODE),  sCommandLine, sArgsLine)

    -- Send All
    SendMsg(MSG_CONSOLE_FIXED, hClient, sSpace .. CRY_COLOR_GRAY .. string.rspace(sCmdBanner, iBoxWidth, string.COLOR_CODE, "="))
    SendMsg(MSG_CONSOLE_FIXED, hClient, sSpace .. CRY_COLOR_GRAY .. string.format("[ %s ]", string.mspace((TryLocalize("@l_ui_description", sLang) .. ":"), iBoxWidth - 4, 1, string.COLOR_CODE)))
    SendMsg(MSG_CONSOLE_FIXED, hClient, sSpace .. CRY_COLOR_GRAY .. string.format("[ %s ]", string.mspace(sDescBanner, iBoxWidth - 4, 1, string.COLOR_CODE)))
    SendMsg(MSG_CONSOLE_FIXED, hClient, sSpace .. CRY_COLOR_GRAY .. string.format("[ %s ]", string.mspace("", iBoxWidth - 4)))
    SendMsg(MSG_CONSOLE_FIXED, hClient, sSpace .. CRY_COLOR_GRAY .. "[ " .. string.rspace(sPrefixLine, iBoxWidth - 4, string.COLOR_CODE) .. CRY_COLOR_GRAY .. " ]")
    SendMsg(MSG_CONSOLE_FIXED, hClient, sSpace .. CRY_COLOR_GRAY .. "[ " .. string.rspace(sAccessLine, iBoxWidth - 4, string.COLOR_CODE) .. CRY_COLOR_GRAY .. " ]")
    SendMsg(MSG_CONSOLE_FIXED, hClient, sSpace .. CRY_COLOR_GRAY .. "[ " .. string.rspace(sUsageLine,  iBoxWidth - 4, string.COLOR_CODE) .. CRY_COLOR_GRAY .. " ]")

    local iArgsStart = (iMaxArgLen + 3 + string.len(sCommandLine))
    local iArgMaxName = iMaxArgLen--table.it(hArgs, function(x, i, v) return math.max((x or 0), v.Name)  end)

    local sArgType = ""
    local sArgLine
    for _, aArg in pairs(hArgs) do

        sArgType = "@l_ui_string"
        if (aArg.IsPlayer) then
            sArgType = "@l_ui_player"
        elseif (aArg.IsNumber) then
            sArgType = "@l_ui_number"
        elseif (aArg.IsCVar) then
            sArgType = "@l_ui_cvar"
        elseif (aArg.IsTime) then
            sArgType = "@l_ui_time"
        end

        sBracketColor = CRY_COLOR_GRAY
        if (aArg.Required) then
            sBracketColor = CRY_COLOR_RED
        elseif (aArg.Optional) then
            sBracketColor = CRY_COLOR_BLUE
        end

        sArgType = string.format("%s(%s%s%s)", CRY_COLOR_GRAY, CRY_COLOR_WHITE, TryLocalize(sArgType, sLang), CRY_COLOR_GRAY)
        sArgLine = string.rep(" ", (iMaxInfoLen + 2 + string.len(sName) + 2)) .. string.rspace(string.format("%s<%s%s %s%s>%s", sBracketColor, CRY_COLOR_YELLOW, string.rspace(TryLocalize(aArg.Name, sLang), iArgMaxName, string.COLOR_CODE), sArgType, sBracketColor, CRY_COLOR_GRAY), 30, string.COLOR_CODE) .. " - " .. CRY_COLOR_WHITE .. TryLocalize((aArg.Desc or "@l_ui_nodescription"), sLang)


        SendMsg(MSG_CONSOLE_FIXED, hClient, sSpace .. CRY_COLOR_GRAY .. string.format("[ %s ]", string.rspace(sArgLine .. CRY_COLOR_GRAY, iBoxWidth - 4, string.COLOR_CODE)))

    end
    SendMsg(MSG_CONSOLE_FIXED, hClient, sSpace .. CRY_COLOR_GRAY .. "[ " .. string.rspace("",  iBoxWidth - 4, string.COLOR_CODE) .. CRY_COLOR_GRAY .. " ]")

    local sInfoHelp = TryLocalize("@l_ui_arg_color_info", sLang)
    sInfoHelp = string.format("%s", Logger.Format(sInfoHelp))

    SendMsg(MSG_CONSOLE_FIXED, hClient, sSpace .. CRY_COLOR_GRAY .. "[ " .. string.mspace(sInfoHelp .. CRY_COLOR_GRAY, iBoxWidth - 4, nil, string.COLOR_CODE) .. " ]")
    SendMsg(MSG_CONSOLE_FIXED, hClient, sSpace .. CRY_COLOR_GRAY .. string.rspace("", iBoxWidth, string.COLOR_CODE, "="))

    -- todo
    local x = {
        "== [ Commands ] ===================================================================================",
        "[                                         Description:                                            ]",
        "[                         Displays all available commands to your Console!                        ]",
        "[                                                                                                 ]",
        "[ Prefixes: !, /, \\                                                                               ]",
        "[ Access:   Developer                                                                             ]",
        "[ Usage :   !Commands, <Rank>, <Count>                                                            ]",
        "[                      <Rank  (String)>     - The Target Rank                                     ]",
        "[                      <Count (Number)>     - The Number                                          ]",
        "[                                                                                                 ]",
        "[                          RED Arguments are Required, Blue are Optional                          ]",
        "===================================================================================================",
    }

end

-------------------
--- Init
ServerCommands.SortCommands = function(self, aList)

    -- Fill in User Groups
    local aSorted = {}
    for i = GetLowestRank(), GetHighestRank() do
        aSorted[i] = {}
    end

    local iAccess
    for _, aCommand in pairs(aList) do

        iAccess = aCommand.Access
        table.insert(aSorted[iAccess], aCommand)
    end

    for _ in pairs(aSorted) do
        table.sort(aSorted[_], function(a, b) return (a.Name < b.Name)  end)
    end

    -- Remove Empty templates
    for i, v in pairs(aSorted) do
        if (table.empty(v)) then
            aSorted[i] = nil
        end
    end

    return aSorted

end

-------------------
--- Init
ServerCommands.ListCommands = function(self, hClient, aList, sWantList)

    local aCommandList   = self:SortCommands(table.copy(aList or self.Commands))
    local iItemsPerLine  = 5   -- Its per line
    local iCommandWidth  = 20     -- Fixed column width for command names
    local iCommandCount  = table.count(aCommandList)
    local iLineWidth     = CLIENT_CONSOLE_LEN - 2

    local iClientRank    = hClient:GetAccess()

    local sRank, sRankColor
    local sHeader, sAccessLine
    local sCmdColor

    local iCmdCount = 0
    local sCmdLine  = ""

    Debug(RANK_GUEST,RANK_ADMIN)

    for _, aCommands in pairs(aCommandList) do

        sRank      = GetRankName(_)
        sRankColor = GetRankColor(_)

        if (iClientRank >= _ and table.count(aCommands) > 0) then
            SendMsg(MSG_CONSOLE_FIXED, hClient, " ")
            SendMsg(MSG_CONSOLE_FIXED, hClient, "$9" .. string.mspace((" [ " .. sRankColor .. sRank .. " $9($4" .. table.count(aCommands) .. "$9)" .. " $9] "), iLineWidth, 1, string.COLOR_CODE, "="))
            SendMsg(MSG_CONSOLE_FIXED, hClient, " ")

            sCmdLine = "    "
            iCmdCount = 0
            for __, aCmd in pairs(aCommands) do

                if (not aCmd:IsHidden()) then
                    sCmdColor = CRY_COLOR_GRAY
                    if (aCmd:IsBroken() or aCmd:IsDisabled()) then
                        sCmdColor = CRY_COLOR_RED
                    end

                    sCmdLine = (sCmdLine .. string.rspace("($1!$9" .. sCmdColor .. aCmd.Name .. ")", iCommandWidth, string.COLOR_CODE))
                    iCmdCount = (iCmdCount + 1)
                    if (iCmdCount % iItemsPerLine == 0) then
                        SendMsg(MSG_CONSOLE_FIXED, hClient, CRY_COLOR_GRAY .. sCmdLine)--string.mspace(sCmdLine, iLineWidth, 1, string.COLOR_CODE))
                        sCmdLine = "    "
                    end
                end
            end

            if (not string.empty(sCmdLine)) then
                SendMsg(MSG_CONSOLE_FIXED, hClient, CRY_COLOR_GRAY .. sCmdLine)--string.mspace(sCmdLine, iLineWidth, 1, string.COLOR_CODE))
            end
        end
    end

    local sInfoHelp = TryLocalize("@l_ui_commands_help", hClient:GetPreferredLanguage())

    SendMsg(MSG_CONSOLE_FIXED, hClient, " ")
    SendMsg(MSG_CONSOLE_FIXED, hClient, CRY_COLOR_GRAY .. string.rep("-", iLineWidth))
    SendMsg(MSG_CONSOLE_FIXED, hClient, " " .. sInfoHelp)
end

-------------------
--- Init
ServerCommands.ProcessCommand = function(self, hClient, aCommand, aUserArgs)

    local sName     = aCommand.Name
    local sDesc     = aCommand.Description
    local fCmdFunc  = aCommand.Function
    local iAccess   = aCommand.Access
    local aCmdArgs  = (aCommand.Arguments or {})
    local aCmdProps = (aCommand.Properties or {})
    local sLang     = hClient:GetPreferredLanguage()

    if (not isFunc(fCmdFunc)) then
        throw_error(string.format("No function found for Command %s", sName))
    end

    local aHost
    local aHostCondition = (aCmdProps.HostCondition)
    local sHost = (aCmdProps.Host or aCmdProps.Self or aCmdProps.This)

    local iUserRank = hClient:GetAccess()
    if (iUserRank < iAccess) then
        if (IsPremiumRank(iAccess)) then
            return self:SendResponse(hClient, eCommandResponse_Premium, sName)
        end
        return self:SendResponse(hClient, eCommandResponse_NotFound, sName)
    end

    if ((aCmdProps.PowerStruggle and not g_gameRules.IS_PS) or (aCmdProps.InstantAction and g_gameRules.IS_PS)) then
        return self:SendResponse(hClient, eCommandResponse_BadGameRules, sName, g_sGameRules)
    end

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
        EqualAccess = true,
        Predicate = function(arg)  end,

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

    local bTestingMode = hClient:IsTesting()

    local iPrestige = (aCmdProps.Prestige or 0)
    local bPay = false
    if (g_gameRules.IS_PS and iPrestige > 0 and not bTestingMode) then
        local iBalance = hClient:GetPrestige()
        if (iBalance < iPrestige) then
            return self:SendResponse(hClient, eCommandResponse_Failed, sName, "@l_commandresp_insufficientPrestige", iPrestige - iBalance)
        end
        bPay = true
    end

    local bIndoors = aCmdProps.Indoors
    local bOutdoors = aCmdProps.Outdoors
    local bIsIndoors = System.IsPointIndoors(hClient:GetPos())

    if (bIndoors == false and bIsIndoors and not bTestingMode) then
        return self:SendResponse(hClient, eCommandResponse_Failed, sName, "@l_commandresp_notIndoors")
    end
    if (bOutdoors == false and not bIsIndoors and not bTestingMode) then
        return self:SendResponse(hClient, eCommandResponse_Failed, sName, "@l_commandresp_notOutdoors")
    end

    local iCooldown = (aCmdProps.Timer or aCmdProps.Cooldown or 0)
    local sTimerID  = string.format("cmd_%s_timer", string.lower(sName))
    if (iCooldown > 0 and not bTestingMode) then
        --local hLastUsed = hClient.CommandTimers[string.lower(sName)]

        --if (hLastUsed and not hLastUsed.expired()) then
        --    return self:SendResponse(hClient, eCommandResponse_Failed, sName, "@l_commandresp_cooldown", math.calctime(hLastUsed.getexpiry(), nil, 3))
        --end

        if (not hClient:TimerExpired(sTimerID, iCooldown)) then
            return self:SendResponse(hClient, eCommandResponse_Failed, sName, "@l_commandresp_cooldown", math.calctime(hClient:TimerExpiry(sTimerID), nil, 3))
        end
    end

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

    local bPred, hPred, fPred
    for _, aCmdArg in pairs(aCmdArgs) do

        sArg = aUserArgs[_]
        if (sArg == nil and aCmdArg.Default) then
            sArg = aCmdArg.Default
            aUserArgs[_] = sArg
        end

        sArgLower = string.lower(sArg or "")

        bOk = true
        if (sArg == nil) then
            if (aCmdArg.Required) then
                return self:SendResponse(hClient, eCommandResponse_Failed, sName, "@l_commandarg_required", hClient:Localize(aCmdArg.Name))
            end
            bOk = false
        end

        fPred = aCmdArg.Predicate
        hTemp = nil

        if (bOk) then

            if (false) then

            -- Argument expects a player
            elseif (aCmdArg.IsPlayer) then
                hTemp = GetPlayer(sArg)
                if (fPred) then
                    bPred, hPred = fPred(sArg)
                    if (bPred and hPred) then
                        hTemp = hPred
                    end
                end
                if (not hTemp) then

                    -- FIXME: what if a player with name "self" or "myself" exists? then self will never work!
                    if ((aCmdArg.SelfOk or aCmdArg.AcceptSelf) and IsAny(sArgLower, "myself", "self")) then
                        hTemp = hClient

                    -- FIXME: same problem as above!!
                    elseif ((aCmdArg.AllOk or aCmdArg.AcceptAll) and IsAny(sArgLower, "all", "everyone")) then
                        hTemp = ALL_PLAYERS
                    end

                    if (hTemp == nil) then
                        return self:SendResponse(hClient, eCommandResponse_Failed, sName, "@l_commandarg_player_notfounnd", sArg)
                    end
                elseif (isArray(hTemp)) then
                    if (aCmdArg.EqualAccess and hTemp:GetAccess() >= hClient:GetAccess() and hTemp.id ~= hClient.id) then
                        return self:SendResponse(hClient, eCommandResponse_NoAccess, sName)
                    end

                    if (aCmdArg.NotSelf and hTemp.id == hClient.id) then
                        return self:SendResponse(hClient, eCommandResponse_Failed, sName, "@l_commandarg_not_user", _)
                    end
                end
                aPushArgs[_] = hTemp

            -----------------------
            -- Argument expects a number
            elseif (aCmdArg.IsNumber) then
                if (aCmdArg.IsTime) then
                    sArg = ParseTime(sArg)
                end
                hTemp = g_tn(sArg)
                if (fPred) then
                    bPred, hPred = fPred(sArg)
                    if (bPred and hPred) then
                        hTemp = hPred
                    end
                end
                if (hTemp == nil) then
                    local aTransformers = aCmdArg.Transform
                    if (aTransformers and aTransformers[string.lower(sArg)]) then
                        hTemp = aTransformers[string.lower(sArg)]
                    end
                end

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

                -----------------------
                -- argument expects a time value
            elseif (aCmdArg.IsTime) then

                hTemp = ParseTime(sArg)
                if (hTemp == nil) then
                    return self:SendResponse(hClient, eCommandResponse_Failed, sName, "@l_commandarg_nottime", _)

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


                -----------------------
                --argument expects a cvar
            elseif (aCmdArg.IsCVar) then
                if (GetCVar(sArg) == nil) then
                    return self:SendResponse(hClient, eCommandResponse_Failed, sName, "@l_commandarg_notcvar", _)
                end

                aPushArgs[_] = aUserArgs[_]

            -- this breaks all other arguments!
            elseif (aCmdArg.Concat) then

                hTemp = ""
                for __ = _, iUserArgs do
                    hTemp = hTemp .. (hTemp ~= "" and " " or "") .. aUserArgs[__]
                end

                if (hTemp) then
                    aPushArgs[_] = g_ts(hTemp)
                end
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
        --ServerLog("pushing client")
    end

    if (SERVER_DEBUG_MODE) then
        hCmdResponse, sCmdError = fCmdFunc(aHost, unpack(aPushArgs))
    else
        bSuccess, hCmdResponse, sCmdError = pcall(fCmdFunc, aHost, unpack(aPushArgs))
        if (not bSuccess) then

            HandleError("Executing Command %s (%s)", sName, (hCmdResponse or "<Unknown>"))
            return self:SendResponse(hClient, eCommandResponse_ScriptError, sName, (TryLocalize("@l_ui_checkerrorlog", sLang) or hCmdResponse or "<Unknown>"))
        end

        sError = sCmdError
    end

    local bTimer = true
    if (hCmdResponse == nil or IsAny(hCmdResponse, eCmdRet_NoFeedback)) then
        self:SendResponse(hClient, eCommandResponse_NoFeedback, sName)

    elseif (IsAny(hCmdResponse, false, eCmdRet_Failed)) then
        bTimer = false
        self:SendResponse(hClient, eCommandResponse_Failed, sName, sError)

    elseif (IsAny(hCmdResponse, true, eCmdRet_Ok, eCmdRet_Success)) then
        self:SendResponse(hClient, eCommandResponse_Success, sName, sCmdError)

    else
        error("weird command response!")
    end

    if (bTimer) then
        --hClient.CommandTimers[string.lower(sName)] = timernew(iCooldown)
        hClient:TimerRefresh(sTimerID, iCooldown, true)
        if (bPay and not bTestingMode) then

            g_gameRules:AwardPPCount(hClient.id, -iPrestige, nil, hClient:HasClientMod())
            -- FIXME: clientmod()
        end
    end

    return true
end

-------------------
--- Init
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
--- Init
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

        if (table.getnested(aCommand, "Properties.NoLogging") == true and iResponse ~= eCommandResponse_NotFound) then
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
    if (sMsg and IsAny(iResponse, eCommandResponse_Failed, eCommandResponse_ScriptError)) then
        sLocalizedMsg = " (".. self:LocalizeMessage(hClient, sMsg, { ... }) .. ")"
    end


    local aMsg1, aMsg2
    if (iResponse == eCommandResponse_Failed) then
        aMsg1 = { "@l_commandresp_con_failed", string.upper(sCmd), (sLocalizedMsg or sMsg or "") }
        aMsg2 = { "@l_commandresp_chat_failed", string.upper(sCmd), (sLocalizedMsg or sMsg or "") }


    elseif (iResponse == eCommandResponse_Success) then
        if (sMsg) then
            aMsg2 = { "@l_commandresp_chat_success", string.upper(sCmd), (sLocalizedMsg or sMsg or "") }
        end
        if (sLocalizedMsg) then sLocalizedMsg = string.format(" (%s)", (sLocalizedMsg)) end
        if (sMsg) then sMsg = string.format(" (%s)", (sMsg)) end
        aMsg1 = { "@l_commandresp_con_success", string.upper(sCmd), (sLocalizedMsg or sMsg or "") }


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

    elseif (iResponse == eCommandResponse_Premium) then
        aMsg1 = { "@l_commandresp_con_premium", string.upper(sCmd), (sLocalizedMsg or sMsg or "") }
        aMsg2 = { "@l_commandresp_chat_premium", string.upper(sCmd), (sLocalizedMsg or sMsg or "") }

    elseif (iResponse == eCommandResponse_NoAccess) then
        aMsg1 = { "@l_commandresp_con_noaccess", string.upper(sCmd), (sLocalizedMsg or sMsg or "") }
        aMsg2 = { "@l_commandresp_chat_noaccess", string.upper(sCmd), (sLocalizedMsg or sMsg or "") }

    elseif (iResponse == eCommandResponse_BadGameRules) then
        aMsg1 = { "@l_commandresp_con_badgamerules", string.upper(sCmd), (sLocalizedMsg or sMsg or "") }
        aMsg2 = { "@l_commandresp_chat_badgamerules", string.upper(sCmd), (sLocalizedMsg or sMsg or "") }

    else
        throw_error("response not implemented " .. g_ts(iResponse))
    end

    if (aMsg1 and bConsoleMsg) then
        Logger:LogCommandEvent({ hClient }, aMsg1[1], unpack(aMsg1, 2))
    end

    if (aMsg2 and bChatMsg) then
        SendMsg(CHAT_SERVER_LOCALE, hClient, aMsg2[1], unpack(aMsg2, 2))
    end
end

-------------------
--- Init
ServerCommands.FindCommand = function(self, iUserRank, sMessage, bGreedy)

    local aFound = {}
    for sName, aCommand in pairs(table.copy(self.Commands)) do
        if (string.len(sMessage) >= 1) then

            --ServerLog("%s match %s", sName, sMessage)
            if (sName == sMessage) then
                return { aCommand }
                --table.insert(aFound, aCommand)
            elseif (string.match(sName, ("^" .. sMessage))) then
                table.insert(aFound, aCommand)
            elseif (bGreedy) then
                for i = string.len(sMessage), math.minex((string.len(sMessage) - 5), 3), -1 do

                    --ServerLog("%s match %s", sName, ("^" .. string.sub(sMessage, 1, i)))
                    if (string.match(sName, ("^" .. string.sub(sMessage, 1, i)))) then
                        table.insert(aFound, aCommand)
                        break
                    end
                end
            end
        elseif (sName == string.lower(sMessage)) then
            return { aCommand }
            --table.insert(aFound, aCommand)
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
--- Init
ServerCommands.HasCommandPrefix = function(self, sMessage)

    for _, sPrefix in pairs(self.CommandPrefixes) do

        -- Don't trigger if only a prefix has been sent!
        if (string.match(sMessage, ("^(" .. string.escape(sPrefix) .. "[^%s].-)%s?")) and string.len(sMessage) > string.len(sPrefix)) then
            return sPrefix
        end
    end
    return false

end

-------------------
--- Init
ServerCommands.RemovePrefix = function(self, sMessage, sPrefix)
    return string.sub(sMessage, (string.len(sPrefix) + 1))
end

-------------------
--- Init
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
--- Init
ServerCommands.GetCommand = function(self, sName)
    return (self.Commands[string.lower(sName)])
end

-------------------
--- Init
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
--- Init
ServerCommands.OnServerCommand = function(self, sName, ...)
    self:ProcessCommand(Server.ServerEntity, self.Commands[string.lower(sName)], { ... })
end

-------------------
--- Init
ServerCommands.CreateCommand = function(self, aInfo)

    local sName   = aInfo.Name
    local fFunc   = aInfo.Function
    local hArgs   = aInfo.Arguments or {}
    local iAccess = aInfo.Access
    local sDesc   = aInfo.Description
    if (not sDesc) then
        sDesc     = "@l_ui_no_description"
    end

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
    for _, hArg in pairs(aCommand.Arguments or {}) do
        table.checkM(hArg, "Name", hArg[1])
        table.checkM(hArg, "Desc", hArg[2])
    end

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

    if (self.CreateCCommand) then
        local sConsoleArgs = string.repeats("%%1{%a:,}", table.count(hArgs))
        local sConsoleFunc = string.format("ServerCommands:OnServerCommand(\"%s\"%s)", sName, (sConsoleArgs ~= "" and ("," .. sConsoleArgs) or sConsoleArgs))
        local sConsoleName = string.format("server_cmd_" .. sName)

        self.CCommands = (self.CCommands or 0) + 1
        System.AddCCommand(sConsoleName, sConsoleFunc, (sDesc))
    end
end