----------------
Logger = {
    ConsoleMessageCenterPos = 60,
    LogTag                  = "System ",
    DefaultColor            = CRY_COLOR_RED,
}

----------------

LOG_STARS           = string.rep("*", 40)
CLIENT_CONSOLE_LEN  = 113 -- Length of the client console

----------------

LOG_NORMAL  = 0
LOG_ERROR   = 1
LOG_WARNING = 2

----------------

eLogEvent_Server            = 0
eLogEvent_Connection        = 1
eLogEvent_ScriptError       = 2
eLogEvent_ChatMessageAll    = 3
eLogEvent_ChatMessageTeam   = 4
eLogEvent_ChatMessageTarget = 5
eLogEvent_Command           = 6
eLogEvent_Commands          = 7
eLogEvent_Config            = 8
eLogEvent_DataLog           = 9
eLogEvent_ServerScripts     = 10
eLogEvent_ServerLocale      = 11
eLogEvent_Plugins           = 12
eLogEvent_Debug             = 13
eLogEvent_BuyMessage        = 14
eLogEvent_Rename            = 15
eLogEvent_Punish            = 16
eLogEvent_Maps              = 17
eLogEvent_HQ              = 18
eLogEvent_Game              = 19
eLogEvent_ClientMod              = 20
eLogEvent_Cheat              = 21
eLogEvent_Voting              = 22

--------------------------------
--- Init
Logger.Init = function(self)

    -------------
    ServerLog("Logger.Init()")

    -------------

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

    Debug = function(...)
        local s = ""
        for _, v in pairs({...}) do
            if (isArray(v)) then
                LogEvent(eLogEvent_Debug, table.tostring(v))
            end
            s = s .. g_ts(v) .. ", "
        end
        if (s ~= "") then
            Logger:LogEvent(eLogEvent_Debug, s)
        end
    end

    -------------
    g_Logger = self
end

--------------------------------
--- Init
Logger.InitLogEvents = function(self, iEvent, sMessage, ...)


    self.ConsoleMessageCenterPos = 60
    self.LogTag                  = "System "
    self.DefaultColor            = CRY_COLOR_RED

    self.LOG_EVENTS = {
        [eLogEvent_Server] = {
            NoLocale        = false,
            PlayerMessages  = true,
            Tag             = "Server",
            Color           = self.DefaultColor,
            Access          = { Regular = RANK_DEVELOPER }
        },

        [eLogEvent_Connection] = {
            NoLocale        = false,
            PlayerMessages  = true,
            Tag             = "Connect",
            Color           = self.DefaultColor,
            Access          = {
                Regular   = RANK_GUEST,
                Extended  = RANK_MODERATOR
            }
        },

        [eLogEvent_ScriptError] = {
            NoServerLog     = true,
            NoLocale        = false,
            PlayerMessages  = true,
            Tag             = "Script-Error",
            Color           = self.DefaultColor,
            MsgColor        = CRY_COLOR_RED,
            Access          = { Regular = RANK_DEVELOPER }
        },

        [eLogEvent_Maps] = {
            PlayerMessages  = true,
            Tag             = "Levels",
            Color           = self.DefaultColor,
            Access          = { Regular = RANK_GUEST }
        },

        [eLogEvent_ClientMod] = {
            PlayerMessages  = true,
            Tag             = "ClientMod",
            Color           = self.DefaultColor,
            Access          = { Regular = RANK_GUEST }
        },

        [eLogEvent_Voting] = {
            PlayerMessages  = true,
            Tag             = "Voting",
            Color           = self.DefaultColor,
            Access          = { Regular = RANK_GUEST }
        },

        [eLogEvent_Cheat] = {
            PlayerMessages  = true,
            Tag             = "Defense",
            Color           = self.DefaultColor,
            Access          = { Regular = RANK_GUEST, Extended = RANK_ADMIN }
        },

        [eLogEvent_HQ] = {
            PlayerMessages  = true,
            Tag             = "HQ-Mods",
            Color           = self.DefaultColor,
            Access          = { Regular = RANK_GUEST }
        },

        [eLogEvent_Game] = {
            PlayerMessages  = true,
            Tag             = "Game",
            Color           = self.DefaultColor,
            Access          = { Regular = RANK_GUEST }
        },

        -- Chat
        [eLogEvent_ChatMessageAll] = {
            NoLocale        = false,
            PlayerMessages  = true,
            Tag             = "Chat",
            Color           = self.DefaultColor,
            Access          = { Regular = RANK_GUEST }
        },

        [eLogEvent_ChatMessageTeam] = {
            NoLocale        = false,
            PlayerMessages  = true,
            Tag             = "Chat",
            Color           = self.DefaultColor,
            Access          = { Regular = RANK_GUEST }
        },

        [eLogEvent_ChatMessageTarget] = {
            NoLocale        = false,
            PlayerMessages  = true,
            Tag             = "Chat",
            Color           = self.DefaultColor,
            Access          = { Regular = RANK_GUEST }
        },

        -- Debug
        [eLogEvent_Punish] = {
            ConsoleType     = MSG_DEBUG,
            Locale          = false,
            NoLocale        = false,
            PlayerMessages  = true,
            Tag             = "Punish",
            Color           = self.DefaultColor,
            Access          = { Regular = RANK_GUEST }
        },

        -- Debug
        [eLogEvent_Debug] = {
            ConsoleType     = MSG_DEBUG,
            ChatTypes       = { CHAT_DEBUG },
            Locale          = false,
            NoLocale        = false,
            PlayerMessages  = true,
            Tag             = "Debug",
            Color           = self.DefaultColor,
            Access          = { Regular = GetDevRanks(1) }
        },

        -- Debug
        [eLogEvent_Rename] = {
            ConsoleType     = nil,
            Locale          = false,
            NoLocale        = false,
            PlayerMessages  = true,
            Tag             = "Rename",
            Color           = self.DefaultColor,
            Access          = { Regular = RANK_GUEST }
        },

        -- Debug
        [eLogEvent_BuyMessage] = {
            ConsoleType     = nil,
            Locale          = false,
            NoLocale        = false,
            PlayerMessages  = true,
            Tag             = "Buying",
            Color           = self.DefaultColor,
            Access          = { Regular = GetLowestRank() }
        },

        -- Commands
        [eLogEvent_Command] = {
            ConsoleType     = MSG_CONSOLE_FIXED,
            Locale          = true,
            NoLocale        = false,
            PlayerMessages  = true,
            Tag             = "Chat",
            Color           = self.DefaultColor,
            Access          = { Regular = RANK_GUEST }
        },

        [eLogEvent_Commands] = {
            NoLocale        = false,
            PlayerMessages  = true,
            Tag             = "Commands",
            Color           = self.DefaultColor,
            Access          = { Regular = RANK_MODERATOR }
        },

        [eLogEvent_Plugins] = {
            NoLocale        = false,
            PlayerMessages  = true,
            Tag             = "Plugins",
            Color           = self.DefaultColor,
            Access          = { Regular = RANK_MODERATOR }
        },

        -- Misc
        [eLogEvent_Config] = {
            ConsoleType     = nil, -- Normal Centered
            PlayerMessages  = true,
            Tag             = "Config",
            Color           = self.DefaultColor,
            Access          = { Regular = RANK_MODERATOR }
        },

        [eLogEvent_ServerScripts] = {
            ConsoleType     = nil, -- Normal Centered
            PlayerMessages  = true,
            Tag             = "Scripts",
            Color           = self.DefaultColor,
            Access          = { Regular = RANK_MODERATOR }
        },

        [eLogEvent_DataLog] = {
            ConsoleType     = nil, -- Normal Centered
            PlayerMessages  = true,
            Tag             = "Data",
            Color           = self.DefaultColor,
            Access          = { Regular = RANK_MODERATOR }
        },

        [eLogEvent_ServerLocale] = {
            ConsoleType     = nil, -- Normal Centered
            PlayerMessages  = true,
            Tag             = "Locale",
            Color           = self.DefaultColor,
            Access          = { Regular = RANK_MODERATOR }
        },
    }

end

--------------------------------
--- Init
Logger.LogToServer = function(self, aInfo, sMessage, ...)

    local sLocalized = sMessage
    if (sMessage and not aInfo.NoLocale) then
        sLocalized = Localize(sMessage, SERVER_LANGUAGE, true)
        if (sLocalized == nil or aInfo.NoLocale) then
            sLocalized = string.formatex(sMessage, ...)
        else
            sLocalized = self:FormatLocalized(sLocalized, { ... })
        end
    end

    local sFinalMsg = self.Format(string.format("(%s) %s", (aInfo.Tag or "Server"), (sLocalized or "No Message")))
    ServerLog(sFinalMsg)
end

--------------------------------
--- Init
Logger.LogEvent = function(self, iEvent, sMessage, ...)

    local aInfo = self.LOG_EVENTS[iEvent]
    if (not isArray(aInfo)) then
        return error("info not found "..g_ts(iEvent))
    end

    if (not sMessage) then
        throw_error("no message")
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

--------------------------------
--- Init
Logger.LogEventTo = function(self, aClients, iEvent, sMessage, ...)

    local aInfo = self.LOG_EVENTS[iEvent]
    if (not isArray(aInfo)) then
        return throw_error("info not found?")
    end

    if (not sMessage) then
        throw_error("no message")
    end

    -----------
    -- Log to Players
    if (aInfo.PlayerMessages) then
        if (isNumber(aClients) and GetRankInfo(aClients)) then
            aClients = GetPlayers({ Access = aClients })
        end
        self:LogToPlayers(aInfo, sMessage, { ... }, aClients)
    end

    -----------
    -- Always log to console
    self:LogToServer(aInfo, sMessage, ...)
end

--------------------------------
--- Init
Logger.LogChatEvent = function(self, iLogType, iChatType, sMessage, hSender, aClients, sChatMsg)

    local aInfo = self.LOG_EVENTS[iLogType]
    if (not isArray(aInfo)) then
        return throw_error("info not found?")
    end

    if (not sMessage) then
        throw_error("no message")
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
    ServerLog("%s To %s (%s)", sSenderName, g_ts(iChatType), sChatMsg)
    --self:LogToServer(aInfo, sMessage, sSenderName, sChatMsg)
end

--------------------------------
--- Init
Logger.LogCommandEvent = function(self, aClients, sLocale, ...)

    local aInfo = self.LOG_EVENTS[eLogEvent_Command]
    if (not sLocale) then
        throw_error("no sLocale")
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

--------------------------------
--- Init
Logger.LogToPlayers = function(self, aInfo, sMessage, aFormat, aClients, sLogTag)

    local bClientList = (aClients ~= nil)

    sMessage = self:ReplaceColors(sMessage)
    aClients = (aClients or GetPlayers())
    if (table.empty(aClients)) then
        return
    end

    local sEntity = string.format((aInfo.TagClass or "$9" .. (self.LogTag) .. "(%s%s$9)"), aInfo.Color, aInfo.Tag)
    local sAppendTag = aInfo.AppendTag

    local iRankExtended = (aInfo.Access.Extended) -- Rank required to view a the extended message
    local iRankNormal   = (aInfo.Access.Regular)-- or GetLowestRank())    -- Rank required to view a the regular message
    if (not iRankNormal) then
        throw_error("no rank ?")
    end
    local bExtended = (iRankExtended == nil)      -- Can a user see the extended message?)

    local sLocalized
    local sExtended
    local iRank
    local sLang

    local bShowMessage

    for _, hClient in pairs(aClients) do

        if (hClient.IsPlayer) then
            -- the clients rank (access)
            iRank = (hClient:GetAccess() or 0)
            if (not iRank) then
                throw_error("no rank??? name="..hClient:GetName())
            end

            -- the language of the client
            sLang = (hClient:GetPreferredLanguage() or SERVER_LANGUAGE)

            -- Can a user see the extended message?)
            bExtended = (iRankExtended == nil or (iRank >= iRankExtended))

            -- can the user view the message?
            if (iRank >= iRankNormal or bClientList) then
                sLocalized = sMessage
                sExtended = sMessage
                if (not aInfo.NoLocale) then
                    sLocalized, sExtended = Localize(sMessage, sLang)
                    if (sLocalized == nil) then
                        --ServerLog("assuming non-locale for message %s", sMessage)
                        sLocalized = self:FormatMessage(sMessage, aFormat)
                    else
                        sLocalized = self:FormatLocalized(sLocalized, aFormat)
                    end

                    if (sExtended and bExtended) then
                        sLocalized = self:FormatLocalized(sExtended, aFormat)
                    end
                end

                --ServerLog("ENTITY:::: %s",g_ts(sEntity))

                if (sAppendTag) then
                    sEntity = sEntity .. ("(" .. LocalizeForClient(hClient, sAppendTag, {}) .. ")")
                end

                SendMsg((aInfo.ConsoleType or MSG_CONSOLE), hClient, ((aInfo.MsgColor or "") .. sLocalized), sEntity, unpack(aFormat))
                if (aInfo.ChatTypes) then
                    SendMsg(aInfo.ChatTypes, hClient, string.gsub(sLocalized, string.COLOR_CODE, ""), unpack(aFormat))
                end
                --ServerLog("Final message for client %s: %s", hClient:GetName(), sLocalized)
            else
                -- ServerLog("no access %d<%d<%d",iRank,iRankNormal,iRankExtended or-1)
            end
        end
    end
end

--------------------------------
--- Init
Logger.FormatTime = function(iTime, iStyle)
    return (string.formatex(sMessage, unpack(aFormat)))
end

--------------------------------
--- Init
Logger.FormatMessage = function(self, sMessage, aFormat)
    return (string.formatex(sMessage, unpack(aFormat)))
end

--------------------------------
--- Init
Logger.FormatLocalized = function(self, sMessage, aFormat)

    if (not isArray(aFormat)) then
        throw_error("format: aFormat is not an array")
    end

    local sFormatted = sMessage
    for _, sFmt in pairs((aFormat or {})) do
        if (sFmt == nil) then
            throw_error("format not found " .. g_ts(_))
        end
        sFormatted = string.gsub(sFormatted, "${" .. _ .. "}", sFmt)
    end

    return self:ReplaceColors(sFormatted)
end

--------------------------------
--- Init
Logger.RemoveColors = function(self, sMessage)
    return string.gsub(self:ReplaceColors(sMessage), string.COLOR_CODE, "")
end

--------------------------------
--- Init
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

--------------------------------
--- Init
Logger.Format = function(sMessage, aFormatAppend)

    ---------------
    local aFormat = table.merge({
        ["mod_rawname"]    = MOD_RAW_NAME, -- CryMP-Server
        ["mod_exe"]        = MOD_EXE_NAME, -- CryMP-Server.exe
        ["mod_name"]       = MOD_NAME,     -- CryMP-Server x64 bit
        ["mod_bits"]       = MOD_BITS,     -- 64 bit
        ["mod_version"]    = MOD_VERSION,  -- v21
        ["mod_compiler"]   = MOD_COMPILER, -- MSVC 2019

        -- Stats
        ["server_uptime"]  = math.calctime(_time),
        ["server_highestchannel"]  = LAST_CHANNEL,

        -- debug
        ["dbg_scripterr"] = table.count(ErrorHandler:GetErrorList(1)),

    }, (aFormatAppend or {}))

    ---------------
    -- Server stats
    if (ServerStats) then
        table.merge(aFormat, {
            ["server_alltime"]  = math.calctime(ServerStats:Get(eServerStat_ServerTime)),
            ["server_maxplayer"]  = (ServerStats:Get(eServerStat_PlayerRecord)),
            ["server_totalchannel"]  = (ServerStats:Get(eServerStat_TotalChannels)),
        })
    end

    ---------------
    local sFormatted = (sMessage or "")
    for sTag, sColor in pairs(aFormat) do
        sFormatted = (string.gsub(sFormatted, string.format("${%s}", sTag), sColor))
    end

    return Logger:ReplaceColors(sFormatted)
end

--------------------------------
--- Init
Logger.FormatError = function(sMessage)
    local sFormatted
    return (sFormatted or sMessage)
end

--------------------------------
--- Init
Logger.CreateLogFunction = function(self, iType, fBase, sPrefix)

    local f = function(this, s, ...)
        local n = ((sPrefix or "")) .. g_ts(s)
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

--------------------------------
--- Init
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

    local fBase    = (aParams.Base or SystemLog)
    local fErrBase = (aParams.ErrorBase or fBase)

    self.Log        = hLogger:CreateLogFunction(LOG_NORMAL,  fBase, (sLog))
    self.LogError   = hLogger:CreateLogFunction(LOG_ERROR,   fErrBase, (sLog ..  "Error: "))
    self.LogWarning = hLogger:CreateLogFunction(LOG_WARNING, fErrBase, (sLog ..  "Warning: "))
end