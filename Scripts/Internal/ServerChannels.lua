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
        Country = "Crysis",
        CountryCode = "CV",
        Continent = "Lingshan Islands",
        ContinentCode = "LI",
    }
})

-------------------
ServerChannels.Init = function(self)

    -- Config
    self.DataDir  = (SERVER_DIR_DATA .. "IP-Data\\")
    self.DataFile = "IP-Database.lua"

    -- Functions
    ChannelExists = self.ChannelExists

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
ServerChannels.InitChannel = function(self, iChannel, sIP)

    if (self.ChannelData[iChannel]) then
        return
    end

    self.ChannelData[iChannel] = {
        Name = ServerDLL.GetChannelNick(iChannel),
        IP = sIP,
        ID = iChannel,
    }

    self:ResolveIPData(self.ChannelData[iChannel], sIP)
end

-------------------
ServerChannels.ResolveIPData = function(self, aChannel, sIP)

    if (self.IPData[sIP]) then
        aChannel.IPData = table.copy(self.IPData[sIP])
        return
    end

    ServerDLL.Request({
        url = string.gsub(self.MasterServerAPI, "{ip}", sIP),
        header = self.MasterServerHeaders,
        body = json.encode(self.MasterServerBody),
        method = "GET",
        timeout = 30
    }, function(sError, sResponse, iCode)
        ServerChannels:OnResolve(aChannel.ID, aChannel.IP, sError, sResponse, iCode)
    end)
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

    aChannel.IPData = aResponse
    self.IPData[sIP] = aResponse
    self:SaveFile()

    PlayerHandler:SetClientInfo(iChannel, aResponse)
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
