----------------
ServerChat = {
    ConsoleMessageCenterPos = 38,

    RegisteredEntities = {},

    ChatEntities = {
        { ID = "SERVER",    Name = "CryMP-Server" },
        { ID = "TEST",      Name = "Test" }
    },

    TM_START = 0,
    TM_END   = 0
}

----------------
ServerChat.Init = function(self)

    ALL = 0

    MSG_CONSOLE       = 0
    MSG_CONSOLE_FIXED = 1 -- Ignoring ConsoleMessageCenterPos (is this the wrong name?)
    MSG_CENTER        = 3 -- Center
    MSG_SERVER        = 4
    MSG_INFO          = 5
    MSG_ERROR         = 6

    self.TM_START = 0
    self.TM_END   = 6

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

    ServerLog("test: %s", CHAT_TEST)
    ServerLog("Registered %d Chat Entities", table.count(self.ChatEntities))

    SendMsg = function(...)
        ServerChat:Send(...)
    end

    incEnd()

    --LinkEvent(eServerEvent_ScriptTick, "ServerChat", "Test")

    -- FIXME:
    TEAM_NEUTRAL = 0
    TEAM_US = 1
    TEAM_NK = 2
end

----------------
ServerChat.Test = function(self)

    local aClients = GetPlayers()
    if (table.count(aClients) > 0 and not self.d) then
       -- SendMsg(CHAT_SERVER, aClients, "CHAT_SERVER Test fixed console to all clients")
       -- SendMsg(CHAT_SERVER, aClients[1], "CHAT_SERVER Test fixed console to 1 client")

      --  SendMsg(CHAT_TEST, aClients, "CHAT_TEST Test fixed console to all clients")
     --   SendMsg(CHAT_TEST, aClients[1], "CHAT_TEST Test fixed console to 1 client")

        SendMsg(CHAT_TEST_TEAM, aClients, "CHAT_TEST_TEAM Test fixed console to all clients")
        SendMsg(CHAT_TEST_TEAM, aClients[1], "CHAT_TEST_TEAM Test fixed console to 1 client")

        self.d = 1
    end
end

----------------
ServerChat.CreateChatEntity = function(self, aInfo)

    local sName = aInfo.Name
    local sID = string.format("SV_CHAT_ENTITY_%s", aInfo.ID)

    local hEntity = _G[sID]
    if (hEntity ~= nil) then
        if (hEntity.IsChatEntity and hEntity.ChatName == sName) then
            return hEntity
        end
    end

    local hNew = SpawnEntity({
        class = "Fists",
        name = sName,
        position = { x = 0, y = 0, z = 0 },
        orientation = { x = 0, y = 0, z = 1 }
    })

    if (not hNew) then
        error("failed to spawn chat entity %s", sName)
    end

    hNew.IsChatEntity = true
    hNew.ChatName = sName

    _G[sID] = hNew
    return hNew
end

----------------
ServerChat.OnChatMessage = function(self, iType, iSenderID, iTargetID, sMessage, iForcedteam, bServerMessage)

    -- bServerMessage, Was this message sent by the server itself?
    -- iForcedteam,    Was this message forcefully sent to a team?

    local hSender = GetEntity(iSenderID)
    local hTarget = GetEntity(iTargetID)

    local iLogType
    local aClients
    local sMsg
    local bLog = true
    local bShow = true

    if (ServerCommands:OnChatMessage(iType, hSender, hTarget, sMessage)) then
        return false
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

        if (hSender.PMMessage) then

            iLogType = eLogEvent_ChatMessagePM
            sMsg     = "l_console_chatmessage_pm"
            error("pm not supported yet")
        end

        if (not hSender.IsPlayer) then
            bLog = false
        end

        ServerLog("to target")
    end

    if (iLogType and bLog) then
        --iLogType, sMessage, hSender, aClients, sChatMsg)
        Logger:LogChatEvent(iLogType, iType,"@" .. sMsg, hSender, aClients, sMessage)
        return true
    end

    --error("not showing")
    return (bShow)
end

----------------
ServerChat.Send = function(self, iType, aTargetList, sMessage, sMessage2, ...)

    if (not iType) then
        error("no message type")
    end

    if (isNumber(aTargetList) and GetRankInfo(aTargetList)) then
        return self:Send(iType, GetPlayers({ Access = aTargetList }), sMessage, sMessage2, ...)
    end

    if (isArray(iType)) then
        for _, __ in pairs(iType) do
            self:Send(__, aTargetList, sMessage, sMessage2)
        end
        return
    end

    if (iType >= self.TM_START and iType <= self.TM_END) then
        return self:SendTextMessage(iType, aTargetList, sMessage, sMessage2)
    end

    return self:SendChatMessage(iType, aTargetList, sMessage, sMessage2, ...)
end

----------------
ServerChat.SendTextMessage = function(self, iType, aTargetList, sMessage, sMessage2)

    if (not iType) then
        error("no message type")
    end

    local sFinalMsg = sMessage

    local iRealType
    if (iType == MSG_CONSOLE or iType == MSG_CONSOLE_FIXED) then
        if (iType ~= MSG_CONSOLE_FIXED) then
            if (sMessage2) then

                sFinalMsg = string.format("%" .. (self.ConsoleMessageCenterPos + (string.count(sMessage2, "%$%d") * 2)) .. "s$9: %s", sMessage2, sMessage)
            else
                sFinalMsg = string.format("%-" .. (self.ConsoleMessageCenterPos) .. "s", sMessage)
                -- FIXME
            end
        end
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
        g_pGame:SendTextMessage(iRealType, sFinalMsg, TextMessageToAll)

        -- FIXME: Proper logging!
        ServerLog("To All: %s", sFinalMsg)
    else
        if (not aTargetList.id) then
            for _, hClient in pairs(aTargetList) do
                g_pGame:SendTextMessage(iRealType, sFinalMsg, TextMessageToClient, hClient.id)
            end
        else
            g_pGame:SendTextMessage(iRealType, sFinalMsg, TextMessageToClient, aTargetList.id)
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
    local hSenderID = hSender.id

    -- g_pGame:SetTeam(TEAM_NEUTRAL, hSenderID)

    local iForcedteam = -1
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

        sFinalMsg = nil
        if (aInfo.Locale) then
            sLocalized, sExtended = Localize(sMessage, hClient:GetPreferredLanguage())
            if (sLocalized) then
                if (sExtended and hClient:IsDevRank()) then
                    sLocalized = sExtended
                end
                sFinalMsg = Logger:FormatLocalized(sLocalized, aFormat)
            end
        end

        if (bTeam) then iForcedteam = hClient:GetTeam() end
        if (not aInfo.IgnoreID or (aInfo.IgnoreID ~= hClient.id)) then

            -- FIXME: Some client could be used as the chat entity, in case of loggin, add something to prevent recursion!!
            g_pGame:SendChatMessage(iRealType, aInfo.Entity.id, hClient.id, (sFinalMsg or sMessage), iForcedteam)

            -- FIXME: Proper logging
            ServerLog("Chat (%s) To %s: %s", aInfo.Name, hClient:GetName(), sMessage)
        end
    end

    ServerLog("entityid: %s", g_ts(hSenderID))

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