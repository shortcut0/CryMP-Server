----------------
Logger = {
    ConsoleMessageCenterPos = 60
}

----------------
Logger.Init = function(self)

    -------------
    ServerLog("Logger.Init()")

    -------------
    LOG_STARS = string.rep("*", 40)

    CLIENT_CONSOLE_LEN = 116 -- Length of the client console

    LOG_NORMAL = 0
    LOG_ERROR = 1
    LOG_WARNING = 2

    -------------
    -- Log Events
    eLogEvent_Server        = 0
    eLogEvent_Connection    = 1
    eLogEvent_ScriptError   = 2

    eLogEvent_ChatMessageAll    = 3
    eLogEvent_ChatMessageTeam   = 4
    eLogEvent_ChatMessageTarget = 5

    eLogEvent_Command           = 6
    eLogEvent_Commands          = 7

    -- Must be done twice, now? and after ranks are initialized .. oof!
    self:InitLogEvents()

    -------------
    ServerLog        = self.CreateLogFunction(nil, LOG_NORMAL,  SystemLog, "$9[$4Server$9] ")
    ServerLogError   = self.CreateLogFunction(nil, LOG_ERROR,   SystemLog, "$9[$4Server$9] Error: ")
    ServerLogWarning = self.CreateLogFunction(nil, LOG_WARNING, SystemLog, "$9[$4Server$9] Warning: ")

    -------------
    LogEvent = function(...)
        Logger:LogEvent(...)
    end

    -------------
    g_Logger = self
end

----------------
Logger.InitLogEvents = function(self, iEvent, sMessage, ...)

    self.LOG_EVENTS = {
        [eLogEvent_Server]      = { NoLocale = false, PlayerMessages = true, Tag = "Server",  Color = CRY_COLOR_RED,   Access = { Regular = RANK_DEVELOPER } },
        [eLogEvent_Connection]  = { NoLocale = false, PlayerMessages = true, Tag = "Connect", Color = CRY_COLOR_RED,   Access = { Regular = RANK_GUEST,    Extended = RANK_MODERATOR } },
        [eLogEvent_ScriptError] = { NoLocale = false, PlayerMessages = true, Tag = "Error",   Color = CRY_COLOR_RED,   Access = { Regular = RANK_DEVELOPER} },

        -- Chat
        [eLogEvent_ChatMessageAll]    = { NoLocale = false,  PlayerMessages = true, Tag = "Chat",    Color = CRY_COLOR_WHITE, Access = { Regular = RANK_GUEST} },
        [eLogEvent_ChatMessageTeam]   = { NoLocale = false,  PlayerMessages = true, Tag = "Chat",    Color = CRY_COLOR_WHITE, Access = { Regular = RANK_GUEST} },
        [eLogEvent_ChatMessageTarget] = { NoLocale = false,  PlayerMessages = true, Tag = "Chat",    Color = CRY_COLOR_WHITE, Access = { Regular = RANK_GUEST} },

        -- Commands
        [eLogEvent_Command]  = { ConsoleType = MSG_CONSOLE_FIXED, Locale = true, NoLocale = false,  PlayerMessages = true, Tag = "Chat",    Color = CRY_COLOR_WHITE, Access = { Regular = RANK_GUEST} },
        [eLogEvent_Commands] = { NoLocale = false,  PlayerMessages = true, Tag = "Commands",    Color = CRY_COLOR_WHITE, Access = { Regular = RANK_MODERATOR } },

    }

end

----------------
Logger.LogToServer = function(self, aInfo, sMessage, ...)

    local sLocalized = sMessage
    if (sMessage and not aInfo.NoLocale) then
        sLocalized = Localize(sMessage, SERVER_LANGUAGE, true)
        if (sLocalized == nil or aInfo.NoLocale) then
            sLocalized = sMessage
            ServerLog(":3")
            ServerLog("Not localized (%s)",sMessage)
        else
            sLocalized = self:FormatLocalized(sLocalized, { ... })
        end
    end

    ServerLog("(%s) %s", (aInfo.Tag or "Server"), (sLocalized or "No Message"))
end


----------------
Logger.LogEvent = function(self, iEvent, sMessage, ...)

    local aInfo = self.LOG_EVENTS[iEvent]
    if (not isArray(aInfo)) then
        return error("info not found?")
    end

    if (not sMessage) then
        error("no message")
    end

    -----------
    -- Log to Players
    if (aInfo.PlayerMessages) then
        self:LogToPlayers(aInfo, sMessage, { ... })
    end

    -----------
    -- Always log to console
    self:LogToServer(aInfo, sMessage, ...)
end

----------------
Logger.LogEventTo = function(self, aClients, iEvent, sMessage, ...)

    local aInfo = self.LOG_EVENTS[iEvent]
    if (not isArray(aInfo)) then
        return error("info not found?")
    end

    if (not sMessage) then
        error("no message")
    end

    -----------
    -- Log to Players
    if (aInfo.PlayerMessages) then
        self:LogToPlayers(aInfo, sMessage, { ... }, aClients)
    end

    -----------
    -- Always log to console
    self:LogToServer(aInfo, sMessage, ...)
end

----------------
Logger.LogChatEvent = function(self, iLogType, iChatType, sMessage, hSender, aClients, sChatMsg)

    local aInfo = self.LOG_EVENTS[iLogType]
    if (not isArray(aInfo)) then
        return error("info not found?")
    end

    if (not sMessage) then
        error("no message")
    end

    -----------
    -- Log to Players

    local sSenderName = hSender:GetName()

    local sTagClass = (sSenderName)
    local sColor = CRY_COLOR_WHITE

    local sTag


    if (iChatType == ChatToTeam) then
        sTag = "@l_console_chatmessage_teamtag"
        sTagClass = (sSenderName .. " ")
    elseif (iChatType == ChatToTarget) then
        if (iLogType == eLogEvent_ChatMessagePM) then
            sTag = "@l_console_chatmessage_pmtag"
            sTagClass = (sSenderName .. " ")
        end
    end

    if (aInfo.PlayerMessages) then
        self:LogToPlayers({
            AppendTag = sTag,
            TagClass = sTagClass,
            Color = sColor,
            Access = {
                Regular = RANK_GUEST
            }
        }, sMessage, { sSenderName, sChatMsg }, aClients)
    end

    -----------
    -- Always log to console
    self:LogToServer(aInfo, sMessage, sSenderName, sChatMsg)
end

----------------
Logger.LogCommandEvent = function(self, aClients, sLocale, ...)

    local aInfo = self.LOG_EVENTS[eLogEvent_Command]
    if (not sLocale) then
        error("no sLocale")
    end

    -----------
    -- Log to Players
    if (aInfo.PlayerMessages) then
        self:LogToPlayers(aInfo, sLocale, { ... }, aClients)
    end

    -----------
    -- Always log to console
    self:LogToServer(aInfo, sMessage, ...)
end

----------------
Logger.LogToPlayers = function(self, aInfo, sMessage, aFormat, aClients, sLogTag)

    aClients = (aClients or GetPlayers())
    if (table.empty(aClients)) then
        return ServerLog("No Clients")
    end

    local sEntity = string.format((aInfo.TagClass or "$9Server(%s%s$9)"), aInfo.Color, aInfo.Tag)
    local sAppendTag = aInfo.AppendTag

    local iRankExtended = (aInfo.Access.Extended) -- Rank required to view a the extended message
    local iRankNormal = (aInfo.Access.Regular)    -- Rank required to view a the regular message
    local bExtended = (iRankExtended == nil)      -- Can a user see the extended message?)

    local sLocalized
    local sExtended
    local iRank
    local sLang

    local bShowMessage

    for _, hClient in pairs(aClients) do

        if (hClient.IsPlayer) then
            -- the clients rank (access)
            iRank = hClient:GetAccess()

            -- the language of the client
            sLang = (hClient:GetPreferredLanguage() or SERVER_LANGUAGE)

            -- Can a user see the extended message?)
            bExtended = (iRankExtended == nil or (iRank >= iRankExtended))

            -- can the user view the message?
            if (iRank >= iRankNormal) then
                sLocalized = sMessage
                sLocalizedExtended = sMessage
                if (not aInfo.NoLocale) then
                    sLocalized, sExtended = Localize(sMessage, sLang)
                    if (sLocalized == nil) then
                        ServerLog("assuming non-locale for message %s", sMessage)
                        sLocalized = self:FormatMessage(sMessage, aFormat)
                    else
                        sLocalized = self:FormatLocalized(sLocalized, aFormat)
                    end

                    if (sExtended and bExtended) then
                        sLocalized = self:FormatLocalized(sExtended, aFormat)
                    end
                end

                if (sAppendTag) then
                    sEntity = sEntity .. ("(" .. LocalizeForClient(hClient, sAppendTag, {}) .. ")")
                end

                ServerChat:Send((aInfo.ConsoleType or MSG_CONSOLE), hClient, sLocalized, sEntity)
                ServerLog("Final message for client %s: %s", hClient:GetName(), sLocalized)
            else
                ServerLog("no access %d<%d<%d",iRank,iRankNormal,iRankExtended or-1)
            end
        end
    end
end

----------------
Logger.FormatTime = function(iTime, iStyle)
    return (string.formatex(sMessage, unpack(aFormat)))
end

----------------
Logger.FormatMessage = function(self, sMessage, aFormat)
    return (string.formatex(sMessage, unpack(aFormat)))
end

----------------
Logger.FormatLocalized = function(self, sMessage, aFormat)

    local sFormatted = sMessage
    for _, sFmt in pairs(aFormat) do
        sFormatted = string.gsub(sFormatted, "${" .. _ .. "}", sFmt)
    end

    return self:ReplaceColors(sFormatted)
end

----------------
Logger.ReplaceColors = function(self, sMessage)

    local aColors = {
        ["white"]   = CRY_COLOR_WHITE,      -- $1
        ["dblue"]   = CRY_COLOR_DARK_BLUE,  -- $2
        ["green"]   = CRY_COLOR_GREEN,      -- $3
        ["red"]     = CRY_COLOR_RED,        -- $4
        ["blue"]    = CRY_COLOR_BLUE,       -- $5
        ["yellow"]  = CRY_COLOR_YELLOW,     -- $6
        ["pink"]    = CRY_COLOR_MAGENTA,    -- $7
        ["magenta"] = CRY_COLOR_MAGENTA,    -- $7
        ["orange"]  = CRY_COLOR_ORANGE,     -- $8
        ["gray"]    = CRY_COLOR_GRAY,       -- $9
        ["grey"]    = CRY_COLOR_GRAY,       -- $9
        ["black"]   = CRY_COLOR_BLACK,      -- $0, $O
    }

    local sFixed = sMessage
    for sTag, sColor in pairs(aColors) do
        sFixed = (string.gsub(sFixed, string.format("${%s}", sTag), sColor))
        sFixed = (string.gsub(sFixed, string.format("${color_%s}", sTag), sColor))
    end

    return sFixed
end

----------------
Logger.Format = function(sMessage, aFormatAppend)

    local aFormat = table.merge({
        ["mod_name"]       = MOD_NAME,
        ["mod_bits"]       = MOD_BITS,
        ["mod_version"]    = MOD_VERSION,
    }, (aFormatAppend or {}))

    local sFormatted = sMessage
    for sTag, sColor in pairs(aFormat) do
        sFormatted = (string.gsub(sFormatted, string.format("${%s}", sTag), sColor))
    end

    return Logger:ReplaceColors(sFormatted)
end

----------------
Logger.FormatError = function(sMessage)
    local sFormatted
    return (sFormatted or sMessage)
end

----------------
Logger.CreateLogFunction = function(self, iType, fBase, sPrefix)

    local f = function(this, s, ...)
        local n = ((sPrefix or "")) .. s
        if (#{...} > 0) then
            n = string.format(n, ...)
        end
        if (iType == LOG_ERROR) then
            n = Logger.FormatError(n)
        end
        for line in string.gmatch(n, "[^\n]+") do
            fBase(line)
        end
    end

    local fLog
    if (self ~= nil) then
        fLog = function(this, s, ...)
            f(0, s, ...)
        end
    else
        fLog = function(s, ...)
            f(0, s, ...)
        end
    end
    return fLog
end

----------------
Logger.CreateAbstract = function(self, aParams)

    local hLogger = Logger
    if (not hLogger) then
        return
    end

    local sColor    = (aParams.Color or "$4")
    local sTemplate = (aParams.LogTemplate or ("$9[{color}{class}$9] "))
    local sLogClass = (aParams.LogClass or "Server")

    local sLog = sTemplate
    sLog = string.gsub(sLog, "{color}", sColor)
    sLog = string.gsub(sLog, "{class}", sLogClass)

    local fBase = (aParams.Base or SystemLog)

    self.Log        = hLogger:CreateLogFunction(LOG_NORMAL,  fBase, (sLog))
    self.LogError   = hLogger:CreateLogFunction(LOG_ERROR,   fBase, (sLog ..  "Error: "))
    self.LogWarning = hLogger:CreateLogFunction(LOG_WARNING, fBase, (sLog ..  "Warning: "))
end