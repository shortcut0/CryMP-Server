----------------
ServerChat = (ServerChat or {
    ConsoleMessageCenterPos = 38,
    ConsoleTotalLength = CLIENT_CONSOLE_LEN,

    RegisteredEntities = {},
    ChatEntities = {},

    TM_START = 0,
    TM_END   = 0,

    ConsoleQueue = {

        -- Configurable
        Enabled  = true,
        PopCount = 1,
        PopDelay = 100, -- In Milliseconds

        -- Static
        LastPop  = timernew(0),
        Queue    = {},
    }
})

----------------
ServerChat.Init = function(self)

    ----------
    self.ChatEntities = {
        { ID = "SERVER",    Name = "CryMP-Server" },
        { ID = "TEST",      Name = "Test" },
        { ID = "DEBUG",     Name = "Server-Debug" },
        { ID = "EQUIP",     Name = "Server-Equip" },
        { ID = "VOTING",    Name = "Voting" },
    }

    ----------
    ALL = 0

    ----------
    MSG_CONSOLE          = 0
    CONSOLE              = 0
    MSG_CONSOLE_FIXED    = 1 -- Ignoring ConsoleMessageCenterPos (is this the wrong name?)
    MSG_CONSOLE_CENTERED = 7 -- Ignoring ConsoleMessageCenterPos (is this the wrong name?)
    MSG_CENTER           = 3 -- Center
    MSG_SERVER           = 4
    MSG_INFO             = 5
    MSG_ERROR            = 6

    MSG_CONSOLE_FIXED_NOLOCALE    = 1 -- Ignoring ConsoleMessageCenterPos (is this the wrong name?)

    ----------
    self.TM_START = 0
    self.TM_END   = 7

    ----------
    inc(self.TM_END, 1)
    local nID1, nID2, nID3, nID4, hEntity
    for _, aInfo in pairs(self.ChatEntities) do

        nID1 = inc()
        nID2 = inc()
        nID3 = inc()
        nID4 = inc()

        hEntity = self:CreateChatEntity(aInfo)

        self.RegisteredEntities[nID1] = table.merge(aInfo, { Entity = hEntity })
        self.RegisteredEntities[nID2] = table.merge(aInfo, { Entity = hEntity, Team = true })
        self.RegisteredEntities[nID3] = table.merge(aInfo, { Entity = hEntity, Locale = true })
        self.RegisteredEntities[nID4] = table.merge(aInfo, { Entity = hEntity, Team = true, Locale = true })

        _G[("CHAT_" .. aInfo.ID)] = nID1
        _G[("CHAT_" .. aInfo.ID .. "_TEAM")] = nID2
        _G[("CHAT_" .. aInfo.ID .. "_LOCALE")] = nID3
        _G[("CHAT_" .. aInfo.ID .. "_TEAMLOCALE")] = nID4

        ServerLog("New Chat Entity %s (ID: %s, %s)", aInfo.Name, aInfo.ID, ("CHAT_" .. aInfo.ID))
    end
    incEnd()

    ----------
    ServerLog("Registered %d Chat Entities", table.count(self.ChatEntities))
    SendMsg = function(...)
        ServerChat:Send(...)
    end

    ----------
    for _, sCfg in pairs({
        "Enabled", "PopCount", "PopDelay"
    }) do
        self.ConsoleQueue[sCfg] = ConfigGet(("Messages.Console.Queue." .. sCfg), self.ConsoleQueue[sCfg], eConfigGet_Any)
    end

    self.ForbiddenWords = ConfigGet("Messages.Chat.ForbiddenWords", {
        "gay", "shit", "fuck", "bitch"
    }, eConfigGet_Array)

    --------------
    LinkEvent(eServerEvent_ScriptUpdate, "ServerChat", "OnUpdate")
end

----------------
ServerChat.QueuePush = function(self, sMessage, aFmt, aClients)
    table.insertFirst(self.ConsoleQueue.Queue, {
        Message = sMessage,
        Format  = aFmt,
        SendTo  = aClients
    })
end

----------------
ServerChat.UpdateQueue = function(self)
    local iPopCount = (self.ConsoleQueue.PopCount or 1)
    local iPopDelay = (self.ConsoleQueue.PopDelay / 1000)
    local hPopTimer = self.ConsoleQueue.LastPop

    if (not hPopTimer.expired(iPopDelay)) then
        return
    end

    local aQueue = self.ConsoleQueue.Queue
    local iQueue = table.count(aQueue)
    if (iQueue == 0) then
        return
    end

    local aPopList = {}
    local iPopMax  = math.limit(iPopCount, 1, iQueue)
    local aPopNext
    for i = 1, iPopMax do
        aPopNext = aQueue[(iQueue - i + 1)]
        aPopNext.QueueID = (iQueue - i + 1)
        table.insert(aPopList, aPopNext)
    end

    for _, aPop in pairs(aPopList) do
        if (aPop.SendTo == ALL) then
            for _, hClient in pairs(GetPlayers()) do
                g_pGame:SendTextMessage(TextMessageConsole, hClient:LocalizeNest(aPop.Message, aPop.Format), TextMessageToAll)
            end
        else
            for _, hClient in pairs(aPop.SendTo) do
                if (hClient.IsServer) then
                    ServerLog(aPop.Message)
                else
                    g_pGame:SendTextMessage(TextMessageConsole, hClient:LocalizeNest(aPop.Message, aPop.Format), TextMessageToClient, hClient.id)
                end
            end
        end
        table.remove(aQueue, aPop.QueueID)
    end

    hPopTimer.refresh()
end

----------------
ServerChat.OnUpdate = function(self)

    self:UpdateQueue()
end

----------------
ServerChat.DeleteChatEntities = function(self)

    ServerLog("Deleting Chat Entities")

    local hEntity, sEntityID
    for sID, aInfo in pairs(self.RegisteredEntities) do

        hEntity     = GetEntity(aInfo.Entity)
        sEntityID   = string.format("SV_CHAT_ENTITY_%s", aInfo.ID)
        if (hEntity and hEntity.IsChatEntity and hEntity.ChatName) then
            RemoveEntity(hEntity.id)
        end

        _G[sEntityID] = nil
        self.RegisteredEntities[sID].Entity = self:CreateChatEntity(aInfo)
    end
end

----------------
ServerChat.CreateChatEntity = function(self, aInfo)

    local sName = aInfo.Name
    local sID = string.format("SV_CHAT_ENTITY_%s", aInfo.ID)

    local hEntity = _G[sID]
    if (hEntity ~= nil) then
        hEntity = GetEntity(hEntity.id)
        if (hEntity and hEntity.IsChatEntity and hEntity.ChatName == sName) then
            return hEntity
        end
    end

    local hNew = SpawnEntity({
        class       = "Fists",
        name        = sName,
        position    = { x = 0, y = 0, z = 0 },
        orientation = { x = 0, y = 0, z = 1 },
    })

    if (not hNew) then
        throw_error("failed to spawn chat entity %s", sName)
    end

    hNew.IsChatEntity = true
    hNew.ChatName = sName

    _G[sID] = hNew
    return hNew
end

----------------
ServerChat.ShouldHideMessage = function(self)
    return false -- TODO
end

----------------
ServerChat.FilterMessage = function(self, sMessage)

    local aForbidden = self.ForbiddenWords

    local function getVariations(char)
        local map = ({
            ["e"] = { 3 },
            ["s"] = { 5 },
            ["a"] = { 4 },
            ["o"] = { 0 },
        })[char]
        if (map) then
            return table.concat(map,"")
        end
        return ""
    end

    local function createPattern(word)
        local pattern = ""
        local sVars = ""
        for i = 1, #word do
            local c = word:sub(i, i)
            sVars = getVariations(c)
            pattern = pattern .. string.format("[%s%s%s]+", c:lower(), c:upper(), sVars)
        end
        return pattern
    end

    local function maskBadWord(word)
        return string.rep("*", #word)
    end

    for _, badWord in ipairs(aForbidden) do
        local pattern = createPattern(badWord)
        sMessage = sMessage:gsub(pattern, maskBadWord)
    end

    return sMessage
end



----------------
ServerChat.OnChatMessage = function(self, iType, iSenderID, iTargetID, sMessage, iForcedteam, bServerMessage)

    -- bServerMessage, Was this message sent by the server itself?
    -- iForcedteam,    Was this message forcefully sent to a team?

    local aReturn = {
        ShowMessage = true,
        NewMessage  = sMessage
    }

    local hSender = GetEntity(iSenderID)
    local hTarget = GetEntity(iTargetID)

    local iLogType
    local aClients
    local sMsg
    local bLog = true
    local bShow = true

    if (hSender.IsPlayer) then

        if (ClientMod) then
            ClientMod:ChatEffect(hSender,false)
        end

    end

    if (ServerCommands:OnChatMessage(iType, hSender, hTarget, sMessage)) then
        return { ShowMessage = false }
    end

    if (hSender.IsPlayer) then

        local aMuteInfo = hSender:GetMute()
        if (aMuteInfo) then
            SendMsg(CHAT_SERVER_LOCALE, hSender, "@l_ui_youAreMuted", aMuteInfo:GetReason(), math.calctime(aMuteInfo:GetRemaining(), nil, 3))
            Logger:LogEventTo(GetPlayers({ Access = hSender:GetAuthority(RANK_MODERATOR) }), eLogEvent_Punish, "@l_ui_logMutedMessage", hSender:GetName(), sMessage)

            return { ShowMessage = false }
        end

        if (self:ShouldHideMessage(hSender, sMessage)) then
            return { ShowMessage = false }
        end
    end

    if (iType == ChatToAll) then

        iLogType = eLogEvent_ChatMessageAll
        aClients = GetPlayers()
        sMsg     = "l_console_chatmessage_all"

    elseif (iType == ChatToTeam) then

        iLogType = eLogEvent_ChatMessageTeam
        aClients = GetPlayers({ Team = (iForcedteam or g_pGame:GetTeam(iSenderID)) })
        sMsg     = "l_console_chatmessage_team"

    elseif (iType == ChatToTarget) then

        iLogType = eLogEvent_ChatMessageTarget
        aClients = { hTarget }
        if (iSenderID ~= iTargetID) then
            aClients[2] = hSender
        end
        sMsg     = "l_console_chatmessage_target"

        if (hSender and hSender.PMMessage) then

            iLogType = eLogEvent_ChatMessagePM
            sMsg     = "l_console_chatmessage_pm"
            error("pm not supported yet")
        end

        if (not hSender.IsPlayer) then
            bLog = false
        end

        --ServerLog("to target")
    end

    if (iLogType and bLog) then
        --iLogType, sMessage, hSender, aClients, sChatMsg)
        Logger:LogChatEvent(iLogType, iType,"@" .. sMsg, hSender, aClients, sMessage)
        aReturn.ShowMessage = true
    end

    if (hSender.IsPlayer and iType == ChatToTeam) then
        aReturn.NewMessage = string.format("(Coords, %s): %s", hSender:GetMapCoords(), (sMessage or ""))
    end

    if (hSender.IsPlayer) then
        aReturn.NewMessage = self:FilterMessage(aReturn.NewMessage)
    end
    return aReturn
end

----------------
ServerChat.SendPM = function(self, hFrom, hTo, sMessage)

    if (hFrom == hTo and not hFrom:IsTesting()) then return end

    -- Chat Msg
    SendMsg(CHAT_SERVER, hTo, hTo:LocalizeNest("@l_ui_pmReceived", {hFrom:GetName()}))

    -- Console Msgs
    local iBoxWidth = (CLIENT_CONSOLE_LEN - 24) -- fany fancy~
    local sBanner = string.rspace(string.format("$9== ~ $4%s$9 ~ ", hTo:LocalizeNest("@l_ui_pm")), iBoxWidth, string.COLOR_CODE, "=")
    local sPMLine = string.format("<%s> : %s", string.rspace(hFrom:GetName(), 30, string.COLOR_CODE), sMessage)

    SendMsg(CONSOLE_CENTERED, hTo, sBanner)
    SendMsg(CONSOLE_CENTERED, hTo, string.format("$9[ %s $9]", string.rspace(sPMLine, (iBoxWidth - 4), string.COLOR_CODE)))
    SendMsg(CONSOLE_CENTERED, hTo, string.format("$9%s", string.rep("=", iBoxWidth)))
    --[[
    == [ ~ PM ~ ] ==================================================================================
    [ <Marisa            > : Hello uwu listen to when the world ends
    ================================================================================================

    ]]
end

----------------
ServerChat.Send = function(self, iType, aTargetList, sMessage, sMessage2, ...)

    if (not iType) then
        error("no message type")
    end

    if (isNumber(aTargetList) and aTargetList ~= ALL_PLAYERS  and GetRankInfo(aTargetList)) then
        return self:Send(iType, GetPlayers({ Access = aTargetList }), sMessage, sMessage2, ...)
    end

    if (isArray(iType)) then
        for _, __ in pairs(iType) do
            self:Send(__, aTargetList, sMessage, sMessage2)
        end
        return
    end

    if (iType >= self.TM_START and iType <= self.TM_END) then
        return self:SendTextMessage(iType, aTargetList, sMessage, sMessage2, ...)
    end

    return self:SendChatMessage(iType, aTargetList, sMessage, sMessage2, ...)
end

----------------
ServerChat.SendTextMessage = function(self, iType, aTargetList, sMessage, sMessage2, ...)
    --ServerLog(table.tostring({...}))

    if (not iType) then
        error("no message type")
    end

    if (not isArray(aTargetList) and not isNumber(aTargetList)) then
        HandleError("bad target")
    end

    local sFinalMsg = sMessage
    local bUseQueue = self.ConsoleQueue.Enabled
    local bConsole  = false

    local iRealType
    if (IsAny(iType, MSG_CONSOLE, MSG_CONSOLE_FIXED, MSG_CONSOLE_CENTERED)) then

        bConsole = true
        if (iType == MSG_CONSOLE) then
            if (sMessage2) then
                sFinalMsg = string.format("%" .. (self.ConsoleMessageCenterPos + (string.count(sMessage2, "%$%d") * 2)) .. "s$9: %s", sMessage2, sMessage)
            else
                sFinalMsg = string.format("%-" .. (self.ConsoleMessageCenterPos) .. "s", sMessage)
                -- FIXME
            end
        elseif (iType == MSG_CONSOLE_CENTERED) then
            sFinalMsg = string.mspace(sMessage, (self.ConsoleTotalLength / 1), nil, string.COLOR_CODE)
        end

        sFinalMsg = Logger.Format(sFinalMsg, {})
        iRealType = TextMessageConsole

    elseif (iType == MSG_CENTER) then
        iRealType = TextMessageCenter

    elseif (iType == MSG_INFO) then
        iRealType = TextMessageInfo

    elseif (iType == MSG_ERROR) then
        iRealType = TextMessageError

    elseif (iType == MSG_SERVER) then
        iRealType = TextMessageServer
    end

    if (iRealType == nil) then
        error("bad type!")
    end

    if (aTargetList == ALL) then

        if (iRealType == TextMessageConsole) then
            if (bUseQueue) then
                self:QueuePush(sFinalMsg, { ... }, TextMessageToAll)
            else
                for _, hClient in pairs(GetPlayers()) do
                    local sFormatted = hClient:LocalizeNest(sFinalMsg, { ... })
                    if (not bConsole) then sFormatted = Logger:RemoveColors(sFormatted) end
                    g_pGame:SendTextMessage(iRealType, sFormatted, TextMessageToClient, hClient.id)
                end
            end
        else
            for _, hClient in pairs(GetPlayers()) do
                --g_pGame:SendTextMessage(iRealType, sFinalMsg, TextMessageToAll)
                local sFormatted = hClient:LocalizeNest(sFinalMsg, { sMessage2, ... })
                if (not bConsole) then sFormatted = Logger:RemoveColors(sFormatted) end
                g_pGame:SendTextMessage(iRealType, sFormatted, TextMessageToClient, hClient.id)
            end
        end

        -- FIXME: Proper logging!
        --ServerLog("To All: %s", sFinalMsg)
    elseif (aTargetList == nil) then
        throw_error("no receipients")
    else
        if (not aTargetList.id) then
            for _, hClient in pairs(aTargetList) do

                if (not isArray(hClient) or not hClient.IsPlayer) then
                    throw_error("bad client list")
                end
                if (iRealType == TextMessageConsole) then
                    if (bUseQueue) then
                        self:QueuePush(sFinalMsg, { ... }, aTargetList)
                        break
                    else
                        local sFormatted = hClient:LocalizeNest(sFinalMsg, { ... })
                        if (not bConsole) then sFormatted = Logger:RemoveColors(sFormatted) end
                        g_pGame:SendTextMessage(iRealType, sFormatted, TextMessageToClient, hClient.id)
                    end
                else
                    local sFormatted = hClient:LocalizeNest(sFinalMsg, { sMessage2, ... })
                    if (not bConsole) then sFormatted = Logger:RemoveColors(sFormatted) end
                    g_pGame:SendTextMessage(iRealType, sFormatted, TextMessageToClient, hClient.id)
                end

            end
        else
            if (iRealType == TextMessageConsole) then
                if (bUseQueue) then
                    self:QueuePush(sFinalMsg, { ... }, { aTargetList })
                    --ServerLog("ppuuuu")
                else
                    local sFormatted = aTargetList:LocalizeNest(sFinalMsg, { ... })
                    if (not bConsole) then sFormatted = Logger:RemoveColors(sFormatted) end
                    g_pGame:SendTextMessage(iRealType, sFormatted, TextMessageToClient, aTargetList.id)
                    --ServerLog("ssss")
                end
            else
                local sFormatted = aTargetList:LocalizeNest(sFinalMsg, { ... })
                if (not bConsole) then sFormatted = Logger:RemoveColors(sFormatted) end
                g_pGame:SendTextMessage(iRealType, sFormatted, TextMessageToClient, aTargetList.id)
            end
        end
    end
end

----------------
ServerChat.GetEntityFromParam = function(self, hInput)

    if (isArray(hInput)) then
        return { Entity = hInput, Name = hInput:GetName(), Team = false, ID = 0, IgnoreID = hInput.id }
    end

    return
end

----------------
ServerChat.SendChatMessage = function(self, iType, aTargetList, sMessage, ...)

    local aInfo = (self.RegisteredEntities[iType] or self:GetEntityFromParam(iType))
    if (not aInfo) then
        return error("no message info")
    end

    local hSender = aInfo.Entity
    --local hSenderID = hSender.id --unused

    -- g_pGame:SetTeam(TEAM_NEUTRAL, hSenderID)

    local iForcedTeam = -1
    local iRealType = ChatToTarget
    local bTeam = (aInfo.Team)
    if (bTeam) then
        iRealType = ChatToTeam
    end

    local sLocalized, sExtended
    local sFinalMsg

    if (iRealType == nil) then
        error("bad type!")
    end

    local aFormat = { ... }
    local function fSendTo(hClient)

        -- FIXME: use localize nest??
        -- tried.. its hard..
        sFinalMsg = nil
        if (aInfo.Locale) then
            sLocalized, sExtended = Localize(sMessage, hClient:GetPreferredLanguage())
            if (sLocalized) then
                if (sExtended and hClient:IsDevRank()) then
                    sLocalized = sExtended
                end
                sFinalMsg = Logger:FormatLocalized(sLocalized, aFormat)
            elseif (sExtended and hClient:IsAdmin()) then
                sFinalMsg = Logger:FormatLocalized(sExtended, aFormat)
            end
        end

        --workaround..doesnt support >1 format tho!
        --if (sFinalMsg) then
        --ServerLog("%s,%s",g_ts(sFinalMsg),g_ts(sMessage))
        sFinalMsg = hClient:LocalizeNest(sFinalMsg or sMessage)--, unpack(aFormat))
        --end

        if (bTeam) then iForcedTeam = hClient:GetTeam() end
        if (not aInfo.IgnoreID or (aInfo.IgnoreID ~= hClient.id)) then

            -- FIXME: Some client could be used as the chat entity, in case of loggin, add something to prevent recursion!!
            g_pGame:SendChatMessage(iRealType, aInfo.Entity.id, hClient.id, (sFinalMsg or sMessage), iForcedTeam)

            -- FIXME: Proper logging
            ServerLog("Chat (%s) To %s: %s", aInfo.Name, hClient:GetName(), sMessage)
        end
    end

    if (aTargetList == ALL) then
        for _, hClient in pairs(GetPlayers()) do
            fSendTo(hClient)
        end
    else
        if (not aTargetList.id) then
            for _, hClient in pairs(aTargetList) do
                fSendTo(hClient)
            end
        elseif (not aInfo.IgnoreID or (aInfo.IgnoreID ~= aTargetList.id)) then
            fSendTo(aTargetList)
        end
    end
end