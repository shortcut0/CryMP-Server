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
        ["Content-Type"] = "application/json"
    },

    GameVersion = "6156",

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

ServerPublisher.UseJSONReport = false -- Send Report as JSON Instead of literal url parameter
ServerPublisher.DefaultHeaders = {
    ["Content-Type"] = "application/x-www-form-urlencoded; charset=utf-8"
}
ServerPublisher.JSONHeaders = {
    ["Content-Type"] = "application/json"
}

----------------

eServerReport_Expose = 0
eServerReport_Status = 1

--------------------------------
--- Init
ServerPublisher.Init = function(self)

    -----
    Logger.CreateAbstract(self, { Base = ServerLog, ErrorBase = replace_pre(ServerLog, HandleError), LogClass = "ServerPublisher", LogTemplate = "{class} " })
    self:Log("ServerPublisher.Init()")

    -----
    self.MapLinks = table.merge(ConfigGet("Server.MapLinks", {}, eConfigGet_Array), self:LoadMapLinks())

    -----
    self.ErrorRecovery = ConfigGet("Server.Report.ErrorRecovery", 10, eConfigGet_Number)
    self.UpdateRate = ConfigGet("Server.Report.UpdateRate", 30, eConfigGet_Number)
    self.Description = ConfigGet("Server.Report.Description", "No Description Available.", eConfigGet_String)
    self.Initialized = true

    local sName = ConfigGet("Server.Report.Name", GetCVar("sv_servername"), eConfigGet_String)
    SetCVar("sv_servername", Logger.Format(sName))
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

    if (GetCVar("sv_lanOnly") > 0) then
        self.Exposed = false
        self.ExposedSuccess = false
        self.LanEnabled = true
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

    local sBody = self:GetServerReport(eServerReport_Status)
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
        return self:LogError("Status Update failed with code %d (%s)", checkNumber(iCode), string.gsub(g_ts(sError),"\n",""))
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
    local sDesc         = self:ConvertFormatTags(Logger.Format(self:GetServerDescription()))
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
    if (DebugMode()) then
        iPlayerCount = (iPlayerCount + getrandom(1, 2))
        hPlayerList     = self:GetPlayers(iPlayerCount)

        -- TEST TEST
        -- Debug("sPass:",sPass)
        Debug("count:",table.count(hPlayerList))
        Debug("iPlayerCount:",iPlayerCount)
        Debug(hPlayerList)
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
        numpl        = iPlayerCount,
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
            sTeam    = getrandom(0, 2) if (g_gameRules.IS_IA) then sTeam = "1" end

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

        sName    = ServerNames:RemoveCrypt(hClient:GetName())
        sRank    = hClient:GetRank()
        sKills   = hClient:GetKills() if (sKills < 0) then sKills = 0 end
        sDeaths  = hClient:GetDeaths()  if (sDeaths < 0) then sDeaths = 0 end
        sProfile = hClient:GetProfileID()

        -- FIXME: In IA games, Make it team 0 if spectator?
        sTeam    = hClient:GetTeam() if (g_gameRules.IS_IA) then sTeam = "1" end

        sPlayers = string.format("%s@%s%%%s%%%s%%%s%%%s%%%s", g_ts(sPlayers), (g_ts(sName)), g_ts(sRank), g_ts(sKills), g_ts(sDeaths), g_ts(sProfile), g_ts(sTeam))
        table.insert(aPlayers, {
            name       = sName,
            rank       = sRank,
            kills      = sKills,
            deaths     = sDeaths,
            profile_id = sProfile,
            team       = sTeam
        })
    end

    -- INCOMING CONNECTIONS !!
    for _, aInfo in pairs(ServerChannels:GetConnecting()) do

        sName    = string.format("(Connecting) %s", aInfo.Nick)
        sRank    = "0"
        sKills   = "0"
        sDeaths  = "0"
        sProfile = "0"
        sTeam    = "0" if (g_gameRules.IS_IA) then sTeam = "1" end

        sPlayers = string.format("%s@%s%%%s%%%s%%%s%%%s%%%s", g_ts(sPlayers), (g_ts(sName)), g_ts(sRank), g_ts(sKills), g_ts(sDeaths), g_ts(sProfile), g_ts(sTeam))
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
    local sPass = GetCVar("sv_password")
    if (string.empty(sPass)) then
        sPass = "0"
    end
    return sPass
end

--------------------------------
--- Init
ServerPublisher.GetServerDescription = function(self)
    return (self.Description or "No Description Available!")
end

--------------------------------
--- Init

ServerPublisher.BoldCharMap = {
    ['A'] = '𝗔', ['B'] = '𝗕', ['C'] = '𝗖', ['D'] = '𝗗', ['E'] = '𝗘',
    ['F'] = '𝗙', ['G'] = '𝗚', ['H'] = '𝗛', ['I'] = '𝗜', ['J'] = '𝗝',
    ['K'] = '𝗞', ['L'] = '𝗟', ['M'] = '𝗠', ['N'] = '𝗡', ['O'] = '𝗢',
    ['P'] = '𝗣', ['Q'] = '𝗤', ['R'] = '𝗥', ['S'] = '𝗦', ['T'] = '𝗧',
    ['U'] = '𝗨', ['V'] = '𝗩', ['W'] = '𝗪', ['X'] = '𝗫', ['Y'] = '𝗬',
    ['Z'] = '𝗭', ['a'] = '𝗮', ['b'] = '𝗯', ['c'] = '𝗰', ['d'] = '𝗱',
    ['e'] = '𝗲', ['f'] = '𝗳', ['g'] = '𝗴', ['h'] = '𝗵', ['i'] = '𝗶',
    ['j'] = '𝗷', ['k'] = '𝗸', ['l'] = '𝗹', ['m'] = '𝗺', ['n'] = '𝗻',
    ['o'] = '𝗼', ['p'] = '𝗽', ['q'] = '𝗾', ['r'] = '𝗿', ['s'] = '𝘀',
    ['t'] = '𝘁', ['u'] = '𝘂', ['v'] = '𝘃', ['w'] = '𝘄', ['x'] = '𝘅',
    ['y'] = '𝘆', ['z'] = '𝘇', ['0'] = '𝟬', ['1'] = '𝟭', ['2'] = '𝟮',
    ['3'] = '𝟯', ['4'] = '𝟰', ['5'] = '𝟱', ['6'] = '𝟲', ['7'] = '𝟳',
    ['8'] = '𝟴', ['9'] = '𝟵'
}

ServerPublisher.ConvertFormatTags = function(self, sInput)

    -- Unicode offsets
    local aMap = self.BoldCharMap
    local sResult = string.gsub(sInput, "<bold>(.-)</bold>", function(content)
        return content:gsub(".", function(c)
            return (aMap[c] or c)  -- Use the mapped character or keep the original if not found
        end)
    end)

   -- Debug("in->",sInput)
   --s Debug("->",sResult)
    return sResult
end