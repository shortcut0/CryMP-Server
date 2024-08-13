----------------
ServerPublisher = (ServerPublisher or {

    MasterAPI = ServerDLL.GetMasterServerAPI(),
    RegisterEP = "/reg.php", -- Register Endpoint
    UpdateEP = "/up.php", -- Update Endpoint

    Timeout = 30,

    DefaultHeaders = {
        ["Content-Type"] = "application/x-www-form-urlencoded; charset=utf-8"
    },
    JSONHeaders = {
        ["Content-Type"] = "applicaton/json"
    },

    GameVersion = "6156",

    -----
    UseJSONReport = true, -- Send Report as JSON Instead of literal url parameter

    -----
    LastUpdate = timernew(0),
    UpdateFail = timernew(0),
    ExposedFail = timernew(0),
    UpdateRate = 30.0,
    ErrorRecovery = 30.0,
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

eServerReport_Expose = 0
eServerReport_Status = 1

--------------------------------
--- Init
ServerPublisher.Init = function(self)

    -----
    Logger.CreateAbstract(self, { Base = ServerLog, LogClass = "ServerPublisher", LogTemplate = "{class} " })
    self:Log("ServerPublisher.Init()")

    -----
    self.MapLinks = table.merge(ConfigGet("Server.MapLinks", {}, eConfigGet_Array), self:LoadMapLinks())

    -----
    self.ErrorRecovery = ConfigGet("Server.Report.ErrorRecovery", 10, eConfigGet_Number)
    self.UpdateRate = ConfigGet("Server.Report.UpdateRate", 30, eConfigGet_Number)
    self.Description = ConfigGet("Server.Report.Description", "No Description Available.", eConfigGet_String)
    self.Initialized = true

    local sName = ConfigGet("Server.Report.Name", GetCVar("sv_servername)"), eConfigGet_String)
    System.SetCVar("sv_servername", Logger.Format(sName))
end

--------------------------------
--- Init
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

                    HandleError("Failed to read Map Link file %s (%s)", ServerLFS.FileGetName(sFile), g_ts(sErr))
                    ServerLogError("Failed to read Map Link file %s (%s)", ServerLFS.FileGetName(sFile), g_ts(sErr))
                end

            elseif (sType == "txt") then
                for _, sLine in pairs(string.split(sData, "\n")) do
                    hTemp = { string.match(sLine, "(.-/../[^/]*) = (.*)") }
                    if (table.size(hTemp) == 2) then
                        aLinks[string.lower(hTemp[1])] = hTemp[2]
                    else

                        HandleError("Bad Line (%d) in Map Links file %s (%s)", _, ServerLFS.FileGetName(sFile), g_ts(sErr))
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

                    HandleError("Failed to read Map Link file %s (%s)", ServerLFS.FileGetName(sFile), g_ts("Json Error"))
                    ServerLogError("Failed to read Map Link file %s (%s)", ServerLFS.FileGetName(sFile), g_ts("Json Error"))
                end

            else
                ServerLog("Unknown file type!! help!!")
            end
        end
    end

    return aLinks
end

--------------------------------
--- Init
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
        if (self.LastUpdate.expired() or (self.UpdateFail and self.UpdateFail.expired())) then
            self.LastUpdate.refresh(self.UpdateRate)
            self:UpdateServer()
        end
    end
end

--------------------------------
--- Init
ServerPublisher.UpdateServer = function(self)

    self.UpdateFail = nil

    local sBody = self:GetServerReport(eServerReport_Report)
    local aHeaders = self.DefaultHeaders
    if (self.UseJSONReport) then
        aHeaders = self.JSONHeaders
    end

    ServerDLL.Request({
        url = (self.MasterAPI .. self.UpdateEP),
        method = "POST",
        body = sBody,
        headers = aHeaders,
        timeout = self.Timeout,
    }, function(a,b,c)
        ServerPublisher:OnUpdated(a, b, c)
    end)

    self:Log("Updating Server")
end

--------------------------------
--- Init
ServerPublisher.OnUpdated = function(self, sError, sResponse, iCode)

    self.UpdateFail = timernew(self.ErrorRecovery)
    if (iCode ~= 200) then
        return self:LogError("Status Update failed with code %d (%s)", checkNumber(iCode), g_ts(sError))
    end

    if (sResponse ~= "OK") then
        return self:LogError("Server Status Update failed")
    end

    self.UpdateFail = nil
    self:Log("Server Status Updated")
end

--------------------------------
--- Init
ServerPublisher.OnExposed = function(self, sError, sResponse, iCode)

    self.Exposed = false
    self.ExposedFail = timernew(self.ErrorRecovery)

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

--------------------------------
--- Init
ServerPublisher.ExtractCookie = function(self, sInput)
    return (string.match(sInput, "^<<Cookie>>(.*)<<$"))
end

--------------------------------
--- Init
ServerPublisher.BodyToString = function(self, aBody)
    local aTemp = {}
    for i, v in pairs(aBody) do
        table.insert(aTemp, g_ts(i) .. "=" .. ServerDLL.URLEncode(g_ts(v)))
    end
    return (table.concat(aTemp, "&"))
end

--------------------------------
--- Init
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
    if (self.UseJSONReport) then
        aHeaders = self.JSONHeaders
    end

    ServerDLL.Request({
        url = (self.MasterAPI .. self.RegisterEP),
        method = "POST",
        body = sBody,
        headers = aHeaders,
        timeout = self.Timeout,
    }, function(...)
        ServerPublisher:OnExposed(...)
    end)

    self.Exposed = true
    self.ExposedSuccess = false

    self:Log("Exposing Server at %s...", (self.MasterAPI .. self.RegisterEP))
end

--------------------------------
--- Init
ServerPublisher.GetServerReport = function(self, iType)


    -- Server Config
    local sName         = GetCVar("sv_servername")
    local sPakLink      = self:GetServerPakLink()
    local sDesc         = Logger.Format(self:GetServerDescription())
    local sLocal        = "localhost"
    local sVersion      = self.GameVersion
    local sPass         = (self:GetServerPassword() == "0" and "0" or "1")

    -- Map Config
    local iDirectX10    = 1
    local sMapName      = ServerDLL.GetMapName()
    local sMapTitle     = self:GetMapTitle(sMapName)
    local sMapDownload  = self:GetMapDownloadLink()
    local iTimeLeft     = (g_pGame:GetRemainingGameTime())

    -- Player Config
    local iMaxPlayers   = GetCVar("sv_maxPlayers")
    local hPlayerList   = self:GetPlayers()
    local iPlayerCount  = table.count(hPlayerList)
    if (isString(hPlayerList)) then
        iPlayerCount    = string.count(hPlayerList, "@")
    end

    -- Net Config
    local iPort         = GetCVar("sv_port")
    local iPublicPort   = GetCVar("sv_port")
    local bGameSpy      = "0"

    -- General Config
    local iVoiceChat    = GetCVar("net_enable_voice_chat") >= 1
    local iIsDedicated  = (ServerDLL.IsDedicated() and 1 or 0)
    local iAntiCheat    = g_ts(GetCVar("sv_cheatprotection"))
    local iGPOnly       = "0" -- FIXME
    local iFriendlyFire = g_ts(GetCVar("g_friendlyFireRatio"))
    local iRanked       = "1"

    ------
    if (SERVER_DEBUG_MODE) then
        iPlayerCount = (iPlayerCount + getrandom(50, 120))
        hPlayerList     = self:GetPlayers(iPlayerCount)
    end

    local aBody = {
        cookie       = nil,
        players      = nil,
        port         = iPort,
        gamespy      = bGameSpy,
        desc         = sDesc,
        timel        = iTimeLeft,
        name         = sName,
        numPlayers   = iPlayerCount,
        maxpl        = iMaxPlayers,
        pak          = sPakLink,
        map          = sMapName,
        mapnm        = sMapTitle,
        mapdl        = sMapDownload,
        pass         = sPass,
        ranked       = iRanked,
        gameVersion  = sVersion,
        ["local"]    = sLocal,
        public_port  = iPublicPort,
        dx10         = iDirectX10,
        voicechat    = iVoiceChat,
        dedicated    = g_ts(iIsDedicated),
        anticheat    = iAntiCheat,
        gamepadsonly = iGPOnly,
        friendlyfire = iFriendlyFire
    }

    if (iType == eServerReport_Status) then
        aBody.cookie  = self.Cookie
        aBody.players = hPlayerList
    end

    if (self.UseJSONReport) then
        return json.encode(aBody)
    end

    return self:BodyToString(aBody)
end

--------------------------------
--- Init
ServerPublisher.GetPlayers = function(self, iPopulate)

    local sName, sRank, sKills, sDeaths, sProfile, sTeam

    local aPlayers = {}
    local aPopulation = {}

    local sPlayers = ""
    local sPopulation = ""

    if (iPopulate) then
        for i = 1, iPopulate do

            sName    = ("Entity" .. i)
            sRank    = 1
            sKills   = getrandom(1, 100)
            sDeaths  = getrandom(1, 100)
            sProfile = "1008858"
            sTeam    = getrandom(0, 2)

            sPopulation = string.format("%s@%s%%%s%%%s%%%s%%%s", sPopulation, sName, sRank, sKills, sDeaths, sProfile)
            table.insert(aPopulation, {
                name       = sName,
                rank       = sRank,
                kills      = sKills,
                deaths     = sDeaths,
                profile_id = sProfile,
                team       = sTeam
            })
        end
    end

    -- FIXME:
    -- Implementation missing!
    for _, hClient in pairs(GetPlayers()) do

        sName    = hClient:GetName()
        sRank    = hClient:GetRank()
        sKills   = hClient:GetKills()
        sDeaths  = hClient:GetDeaths()
        sProfile = hClient:GetProfileID()
        sTeam    = hClient:GetTeam()

        sPlayers = string.format("%s@%s%%%s%%%s%%%s%%%s", g_ts(sPlayers), g_ts(sName), g_ts(sRank), g_ts(sKills), g_ts(sDeaths), g_ts(sProfile))
        table.insert(aPlayers, {
            name       = sName,
            rank       = sRank,
            kills      = sKills,
            deaths     = sDeaths,
            profile_id = sProfile,
            team       = sTeam
        })
    end

    if (self.UseJSONReport) then
        return table.append(aPlayers, aPopulation)
    end
    return (sPlayers .. sPopulation)
end

--------------------------------
--- Init
ServerPublisher.GetMapTitle = function(self, sMap)

    local sForced = GetCVar("server_maptitle")
    if (string.len(sForced) < 1 or sForced == "0") then
        local sTitle = (string.match(string.lower(sMap), ".-/.-/(.*)") or sMap)
        return string.capitalN(sTitle)
    end
    return sForced
end

--------------------------------
--- Init
ServerPublisher.GetMapDownloadLink = function(self, sLevel)
    return (self.MapLinks[string.lower((sLevel or ServerDLL.GetMapName()))] or "")
end

--------------------------------
--- Init
ServerPublisher.GetServerPakLink = function(self)
    return ConfigGet("Server.PAKUrl", "", eConfigGet_String)
end

--------------------------------
--- Init
ServerPublisher.GetServerPassword = function(self)
    return GetCVar("sv_password")
end

--------------------------------
--- Init
ServerPublisher.GetServerDescription = function(self)
    return (self.Description or "No Description Available!")
end