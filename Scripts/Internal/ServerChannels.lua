-------------------
ServerChannels = (ServerChannels or {

    MasterServerAPI  = "https://proxycheck.io/v2/{ip}?vpn=1&asn=1",
    MasterServerBody = {
    },

    MasterServerHeaders = {
        ["Content-Type"] = "application/json",
    },

    IPData   = {},
    DataDir  = (SERVER_DIR_DATA .. "IP-Data\\"),
    DataFile = "IP-Database.lua",

    ChannelData = {},
    Default = {
        Default = true,
        Country = "Crysis",
        CountryCode = "CV",
        Continent = "Lingshan Islands",
        ContinentCode = "LI",
    },

    ActiveConnections = {}
})

-------------------

LAST_CHANNEL = 0

-------------------
ServerChannels.Init = function(self)

    -- Config
    self.DataDir  = (SERVER_DIR_DATA .. "IP-Data\\")
    self.DataFile = "IP-Database.lua"

    -- Functions
    ChannelExists    = self.ChannelExists
    WasChannelBanned = self.WasChannelBanned

    -- Events
    ServerEvents:LinkEvent(eServerEvent_OnScriptReload, "ServerChannels", "SaveFile")

    -- Load File & Log
    self:LoadFile()
    Logger:LogEventTo(GetDevs(), eLogEvent_DataLog, "Loaded ${red}%d${gray} IP Database entries..", table.size(self.IPData))
end

-------------------
ServerChannels.ChannelExists = function(iChannel)
    return (g_pGame:GetPlayerByChannelId(iChannel) ~= nil)
end

-------------------
ServerChannels.WasChannelBanned = function(iChannel)
    return ((ServerChannels.ChannelData[iChannel] or {}).Banned == true)
end

-------------------
ServerChannels.OnChannelBanned = function(self, iChannel)
    if (self.ChannelData[iChannel]) then
        self.ChannelData[iChannel].Banned = true
    end
end

-------------------
ServerChannels.IsChannelConnecting = function(self, iChannel)
    return table.findv(self.ActiveConnections, iChannel)
end

-------------------
ServerChannels.OnChannelDisconnect = function(self, iChannel)
    table.popV(self.ActiveConnections, iChannel)
end

-------------------
ServerChannels.GetConnecting = function(self)
    local aConns = {}
    for _, iChannel in pairs(self.ActiveConnections or {}) do
        table.insert(aConns, {
            Nick = ServerDLL.GetChannelNick(iChannel) or "Nomad",
            IP   = ServerDLL.GetChannelIP(iChannel) or "127.0.0.1",
        })
    end

    if (DebugMode()) then
        for i = 1, 3 do
            table.insert(aConns, {
                Nick = "Nomad-" .. i,
                IP   = "127.0.0.1",
            })
        end
    end

    return aConns
end

-------------------
ServerChannels.InitChannel = function(self, iChannel, sIP)

    LAST_CHANNEL = math.max(LAST_CHANNEL, iChannel)

    -- Stats Update
    ServerLog("Player Record %d", LAST_CHANNEL)
    IncreaseServerStat(eServerStat_PlayerRecord, iChannel)

    if (self.ChannelData[iChannel]) then
        return
    end

    table.insert(self.ActiveConnections, iChannel)

    self.ChannelData[iChannel] = {
        Name    = ServerDLL.GetChannelNick(iChannel),
        IP      = sIP,
        ID      = iChannel,
        Banned  = false
    }

    self:ResolveIPData(self.ChannelData[iChannel], sIP)
end

-------------------
ServerChannels.ResolveIPData = function(self, aChannel, sIP)

    local aData = self.IPData[sIP]
    if (aData and aData.Default == nil) then
        aChannel.IPData = table.copy(aData)
        PlayerHandler:SetClientInfo(aChannel.ID, aData)
        self:PostResolve(aChannel.ID)

        ServerLog("Data already resolved!")
        ServerLog(table.tostring(self.IPData[sIP]))
        return
    end

    ServerLog("Resolving Data for IP %s", sIP)

    ServerDLL.Request({
        url = string.gsub(self.MasterServerAPI, "{ip}", sIP),
        header = self.MasterServerHeaders,
        body = json.encode(self.MasterServerBody),
        method = "GET",
        timeout = 30
    }, function(sError, sResponse, iCode)
        self.IPData[sIP] = self:GetDefaultData()
        ServerChannels:OnResolve(aChannel.ID, aChannel.IP, sError, sResponse, iCode)
        ServerChannels:PostResolve(aChannel.ID)
        -- Connect Log
    end)
end

-------------------
ServerChannels.PostResolve = function(self, iChannel)

    local aChannel = self.ChannelData[iChannel]

    ServerNames:HandleChannelNick(aChannel.ID, { Country = self:GetCountryCode(iChannel), Channel = aChannel.ID, Profile = aChannel.ID })
    ServerPCH:LogOnConnection(aChannel.ID, aChannel.IP)
end

-------------------
ServerChannels.OnResolve = function(self, iChannel, sIP, sError, sResponse, iCode)

    local aDefault = self:GetDefaultData()
    local aChannel = self.ChannelData[iChannel]
    aChannel.IPData = aDefault
    PlayerHandler:SetClientInfo(iChannel, self:GetDefaultData())

    if (iCode ~= 200) then
        return false, ServerLogError("HTTP Error (%d) %s", iCode, g_ts(sError))
    end

    local aResponse = json.decode(sResponse)
    if (not isArray(aResponse)) then
        return false, ServerLogError("Failed to decode Reponse %s", sResponse)
    end

    if (aResponse.status ~= "ok") then
        return false, ServerLogError("Request failed, Response %s", sResponse)
    end

    ServerLog("Resolved IP Data for Channel %d", aChannel.ID)

    aResponse = aResponse[sIP]
    aChannel.IPData = aResponse
    self.IPData[sIP] = aResponse
    self:SaveFile()

    PlayerHandler:SetClientInfo(iChannel, aResponse)
    return true
end

-------------------
ServerChannels.LoadFile = function(self)

    local sFile = (self.DataDir .. self.DataFile)
    local aData = FileLoader:ExecuteFile(sFile, eFileType_Data)

    self.IPData = checkArray(aData, {})
end

-------------------
ServerChannels.SaveFile = function(self)

    local sData = string.format("return %s", (table.tostring((self.IPData or {}), "", "") or "{}"))
    local sFile = (self.DataDir .. self.DataFile)

    local bOk, sErr = FileOverwrite(sFile, sData)
    if (not bOk) then

        -- FIXME: Error Handler
        -- ErrorHandler()

        ServerLogError("Failed to open file %s for writing", sFile)
    end
end

-------------------
ServerChannels.GetDefaultData = function(self)
    return table.copy(self.Default)
end

-------------------
ServerChannels.GetCountryCode = function(self, iChannel)
    local aInfo = self.IPData[iChannel]
    if (not aInfo) then
        return
    end

    ServerLog(table.tostring(aInfo))
    return (aInfo.countryCode or aInfo.countrycode or aInfo.CountryCode or aInfo.country_code)
end

-------------------
ServerChannels.GetHost = function(self, iChannel)
    local sHost, iPort = string.match((ServerDLL.GetChannelName(iChannel) or ""), "(.-):(%d+)")
    return sHost
end

-------------------
ServerChannels.CountryToLanguage = function(self, sCountry, hDef)

    -- this is to automatically assign a language to a player
    -- edit: invalids commented so avoid false "auto detected language"
    return ({
        germany = "german",
        chile = "spanish",
        spain = "spanish",
        mexico = "spanish",
        russia = "russian",
        belarus = "russian",
        turkey = "turkish",
        czechia = "czech",
        austria = "german",
        switzerland = "german",
        argentina = "spanish",
        colombia = "spanish",
        ukraine = "russian",
        kazakhstan = "russian",
        usa = "english",
        canada = "english",
        --france = NO_LANGUAGE,
        --italy = NO_LANGUAGE,
        --japan = NO_LANGUAGE,
        --china = NO_LANGUAGE,
        --india = NO_LANGUAGE
    })[string.lower(sCountry)] or hDef
end

