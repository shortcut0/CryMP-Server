----------------
ServerPublisher = (ServerPublisher or {

    MasterAPI = ServerDLL.GetMasterServerAPI(),
    RegisterEP = "/reg.php", -- Register Endpoint
    UpdateEP = "/up.php", -- Update Endpoint

    DefaultHeaders = {
        ["Content-Type"] = "application/x-www-form-urlencoded; charset=utf-8"
    },

    GameVersion = "6156",

    -----
    LastUpdate = timernew(0),
    UpdateRate = 30.0,
    Description = "No Description Available.",

    MapLinkDir = (SERVER_DIR_DATA .. "\\"),
    MapLinkFiles = "MapLinks\.(txt|json|lua)",
    MapLinks = {},

    -----
    Cookie = nil, -- Session Cookie
    Exposed = false,
    ExposedSuccess = false,
    Initialized = false,
})

----------------
ServerPublisher.Init = function(self)

    -----
    eServerReport_Expose = 0
    eServerReport_Status = 1

    -----
    Logger.CreateAbstract(self, { Base = ServerLog, LogClass = "ServerPublisher", LogTemplate = "{class} " })

    -----
    ServerLog("ServerPublisher.Init()")

    -----
    self.MapLinks = table.merge(ConfigGet("Server.MapLinks", {}, eConfigGet_Array), self:LoadMapLinks())

    -----
    self.UpdateRate = ConfigGet("Server.Report.UpdateRate", 30, eConfigGet_Number)
    self.ServerDescription = ConfigGet("Server.Report.Description", "No Description Available.", eConfigGet_String)
    self.Initialized = true
end

----------------
ServerPublisher.LoadMapLinks = function(self)

    local aLinks = {}
    local sFilter = self.MapLinkFiles
    local sDir = self.MapLinkDir

    local aMapLinkFiles = ServerLFS.DirGetFiles(sDir, GETFILES_FILES, sFilter)
    if (table.empty(aMapLinkFiles)) then
        return aLinks
    end

    local sType, sData
    local hTemp
    local bOk, sErr
    for _, sFile in pairs(aMapLinkFiles) do

        sType = FileGetExtension(sFile)
        sData = FileRead(sFile)
        if (string.len(sData) > 0) then
            if (sType == "lua") then

                bOk, sErr = pcall(loadstring(sData))
                if (isArray(sErr)) then
                    for sMap, sLink in pairs(sErr) do
                        aLinks[string.lower(sMap)] = sLink
                    end
                else
                    -- FIXME: Error Handler
                    -- HandleError()

                    ServerLogError("Failed to read Map Link file %s (%s)", ServerLFS.FileGetName(sFile), g_ts(sErr))
                end

            elseif (sType == "txt") then
                for _, sLine in pairs(string.split(sData, "\n")) do
                    hTemp = { string.match(sLine, "(.-/../[^/]*) = (.*)") }
                    if (table.size(hTemp) == 2) then
                        aLinks[string.lower(hTemp[1])] = hTemp[2]
                    else
                        -- FIXME: Error Handler
                        -- HandleError()

                        ServerLogError("[%d] Bad Line in Map Links file %s (%s)", _, ServerLFS.FileGetName(sFile), g_ts(sErr))
                    end
                end

            elseif (sType == "json") then
                hTemp = json.decode(sData)
                if (isArray(hTemp)) then
                    for _, aLink in pairs(hTemp) do
                        aLinks[string.lower(aLink.map)] = aLink.link
                    end
                else
                    -- FIXME: Error Handler
                    -- HandleError()

                    ServerLogError("Failed to read Map Link file %s (%s)", ServerLFS.FileGetName(sFile), g_ts("Json Error"))
                end

            else
                ServerLog("Unknown file type!! help!!")
            end
        end
    end

    return aLinks
end

----------------
ServerPublisher.OnTick = function(self)

    if (not self.Initialized) then
        return
    end

    -- Expose
    if (not self.Exposed) then
        self:ExposeServer()
    end

    -- Update
    if (self.Exposed and self.ExposedSuccess) then
        if (self.LastUpdate.expired()) then
            self.LastUpdate.refresh(self.UpdateRate)
            self:UpdateServer()
        end
    end
end

----------------
ServerPublisher.UpdateServer = function(self)

    local hFail = self.ExposedFail
    if (hFail and not hFail.expired()) then
        return -- Prevent DDosing
    end

    local sBody = self:GetServerReport(eServerReport_Status)
    local aHeaders = self.DefaultHeaders

    ServerDLL.Request({
        url = (self.MasterAPI .. self.UpdateEP),
        method = "POST",
        body = self:BodyToString(sBody),
        headers = aHeaders,
        timeout = 10,
    }, function(...)
        self:OnUpdated(...)
    end)

    self:Log("Updating Server")
end

----------------
ServerPublisher.OnUpdated = function(self, sError, sResponse, iCode)

    if (iCode ~= 200) then
        return self:LogError("Status Update failed with code %d (%s)", checkNumber(iCode), g_ts(sError))
    end

    if (sResponse ~= "OK") then
        return self:LogError("Server Status Update failed")
    end

    self:Log("Server Status Updated")
end

----------------
ServerPublisher.OnExposed = function(self, sError, sResponse, iCode)

    self.Exposed = false
    self.ExposedFail = timernew(10)

    if (iCode ~= 200) then
        return self:LogError("Expose failed with code %d (%s)", checkNumber(iCode), g_ts(sResponse))
    end

    if (sResponse == "FAIL") then
        return self:LogError("Server Exposing failed")
    end

    self.Cookie = self:ExtractCookie(sResponse)
    if (not self.Cookie) then
        return self:LogError("Failed to extract Cookie from response (%s)", g_ts(sResponse))
    end

    self:Log("Server Exposed. Cookie for this Session is %s", g_ts(self.Cookie))

    self.ExposedFail = nil
    self.ExposedSuccess = true
    self.Exposed = true
end

----------------
ServerPublisher.ExtractCookie = function(self, sInput)
    return (string.match(sInput, "^<<Cookie>>(.*)<<$"))
end

----------------
ServerPublisher.BodyToString = function(self, aBody)
    local aTemp = {}
    for i, v in pairs(aBody) do
        table.insert(aTemp, g_ts(i) .. "=" .. ServerDLL.URLEncode(g_ts(v)))
    end
    return (table.concat(aTemp, "&"))
end

----------------
ServerPublisher.ExposeServer = function(self)

    if (self.Exposed == true and self.ExposedSuccess == false) then
        return -- Already trying!
    end

    local hFail = self.ExposedFail
    if (hFail and not hFail.expired()) then
        return -- Prevent DDosing
    end

    local sBody = self:GetServerReport(eServerReport_Expose)
    local aHeaders = self.DefaultHeaders

    ServerDLL.Request({
        url = (self.MasterAPI .. self.RegisterEP) .. "?" .. self:BodyToString(sBody),
        method = "POST",
        body = "",
        headers = aHeaders,
        timeout = 16,
    }, function(...)
        self:OnExposed(...)
    end)

    self.Exposed = true
    self.ExposedSuccess = false

    self:Log("Exposing Server...")
end

----------------
ServerPublisher.GetServerReport = function(self, iType)

    local iPort         = GetCVar("sv_port")
    local sName         = GetCVar("sv_servername")
    local iPlayerCount  = (g_pGame:GetPlayerCount())
    local iMaxPlayers   = GetCVar("sv_maxPlayers")
    local sMapName      = ServerDLL.GetMapName()
    local iTimeLeft     = (g_pGame:GetRemainingGameTime())
    local sMapDownload  = self:GetMapDownloadLink()
    local sDesc         = Logger.Format(self:GetServerDescription())
    local sLocal        = "127.0.0.1"
    local sVersion      = self.GameVersion
    local iRanked       = 1
    local sPlayers      = self:GetPlayers()

    ------
    if (SERVER_DEBUG_MODE) then
        iPlayerCount = (iPlayerCount + getrandom(50, 120))
        sPlayers     = self:GetPlayers(iPlayerCount)
    end

    local aBody = {
        port      = iPort,
        maxpl     = iMaxPlayers,
        numpl     = iPlayerCount,
        name      = sName,
        map       = sMapName,
        timel     = iTimeLeft,
        mapdl     = sMapDownload,
        ver       = sVersion,
        ranked    = iRanked,
        desc      = sDesc,
        ["local"] = sLocal -- Ughhh
    }

    if (iType == eServerReport_Status) then
        aBody.cookie  = self.Cookie
        aBody.players = sPlayers
    end

    return aBody
end

----------------
ServerPublisher.GetPlayers = function(self, iPopulate)

    local sName, sRank, sKills, sDeaths, sProfile
    local sPlayers = ""
    local sPopulation = ""

    if (iPopulate) then
        for i = 1, iPopulate do

            sName    = ("Entity" .. i)
            sRank    = 1
            sKills   = getrandom(1, 100)
            sDeaths  = getrandom(1, 100)
            sProfile = "1008858"

            sPopulation = string.format("%s@%s%%%s%%%s%%%s%%%s", sPopulation, sName, sRank, sKills, sDeaths, sProfile)
        end
    end

    -- FIXME:
    -- Implementation missing!
    for _, hClient in pairs(GetPlayers()) do

        sName    = ServerDLL.URLEncode(hClient:GetName())
        sRank    = hClient:GetRank()
        sKills   = hClient:GetKills()
        sDeaths  = hClient:GetDeaths()
        sProfile = hClient:GetProfileID()

        sPlayers = string.format("%s@%s%%%s%%%s%%%s%%%s", g_ts(sPlayers), g_ts(sName), g_ts(sRank), g_ts(sKills), g_ts(sDeaths), g_ts(sProfile))
    end
    return (sPlayers .. sPopulation)
end

----------------
ServerPublisher.GetMapDownloadLink = function(self)
    return (self.MapLinks[string.lower(ServerDLL.GetMapName())] or "")
end

----------------
ServerPublisher.GetServerDescription = function(self)
    return (self.Description or "No Description Available!")
end