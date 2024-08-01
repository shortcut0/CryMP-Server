----------------
Logger = {
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

    self.LOG_EVENTS = {
        [eLogEvent_Server]      = { Tag = "Server",  Color = COLOR_RED },
        [eLogEvent_Connection]  = { Tag = "Connect", Color = COLOR_RED }
    }

    -------------
    g_Logger = self
end

----------------
Logger.LogEvent = function(self, iEvent, sMessage, ...)

    local aInfo = self.LOG_EVENTS[iEvent]
    if (not isArray(aInfo)) then
        return
    end

    -----------
    -- Format
    local sFinalMsg = self:ReplaceColors(string.formatex(sMessage, ...))

    -----------
    -- Log to Players
    local sPlayerMsg = sFinalMsg
    ServerLog("To Players (FIXME) %s", sPlayerMsg)

    -----------
    -- Always log to console
    ServerLog("(%s) %s", aInfo.Tag, sFinalMsg)
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
    end

    return sFixed
end

----------------
Logger.Format = function(sMessage)

    local aFormat = {
        ["mod_name"]       = MOD_NAME,
        ["mod_bits"]       = MOD_BITS,
        ["mod_version"]    = MOD_VERSION,
    }

    local sFormatted = sMessage
    for sTag, sColor in pairs(aFormat) do
        sFormatted = (string.gsub(sFormatted, string.format("${%s}", sTag), sColor))
    end

    return Logger:ReplaceColors(sFormatted)
end

----------------
Logger.CreateLogFunction = function(self, iType, fBase, sPrefix)
    local function fLog(this, s, ...)
        local n = ((sPrefix or "")) .. s
        if (#{...} > 0) then
            n = string.format(n, ...)
        end
        fBase(n)
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