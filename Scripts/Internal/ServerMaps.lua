---------------
ServerMaps = (ServerMaps or {

    MapPatterns = {
        "^([^/]+)/([^/]+)/([^/]+)$",
        "^([^\\]+)\\([^\\]+)\\([^\\]+)$",
    },

    -- Data
    MapList          = {
        IA = {},
        PS = {}
    },
    ForbiddenMaps    = nil,
    MapRotation      = nil,
    DefaultTimeLimit = ONE_HOUR,
    DefaultTimeLimit_IA = ONE_HOUR,
    DefaultTimeLimit_PS = ONE_HOUR * 3,

    -- FIXME: Move to Config !!!! :d
    Default = {
        Rotation = {
            Rotation = {
                { Map = "multiplayer/ps/mesa", TimeLimit = (ONE_HOUR * 3) }
            }
        }
    },

    FirstInit = true,
})

---------------
ServerMaps.Init = function(self)

    self.DefaultTimeLimit    = ConfigGet("General.MapConfig.DefaultTimeLimit", ONE_HOUR, eConfigGet_Number)
    self.DefaultTimeLimit_IA = ConfigGet("General.MapConfig.DefaultTimeLimit_IA", self.DefaultTimeLimit, eConfigGet_Number)
    self.DefaultTimeLimit_PS = ConfigGet("General.MapConfig.DefaultTimeLimit_PS", 60 or self.DefaultTimeLimit, eConfigGet_Number)

    self:CollectForbiddenMaps()
    self:CollectMaps()
    self:InitRotation()

    self.FirstInit = false
end

---------------
ServerMaps.CollectForbiddenMaps = function(self)

    self.ForbiddenMaps = {}
    local aForbidden = ConfigGet("General.MapConfig.ForbiddenMaps", {}, eConfigGet_Array)
    for _, sMap in pairs(aForbidden) do
        table.insert(self.ForbiddenMaps, string.lower(sMap))
    end
end

---------------
ServerMaps.IsMapForbidden = function(self, sMap)

    return table.findv(self.ForbiddenMaps, sMap)
end

---------------
ServerMaps.CollectMaps = function(self)
    self.MapList = {}

    local aLevels = ServerDLL.GetLevels()

    local sType, sRules, sMap
    for _, sLevel in pairs(aLevels) do
        sType, sRules, sMap = string.matchex(sLevel[1], unpack(self.MapPatterns))
        if (sType and sRules and sMap) then

            table.checkM(self.MapList, string.upper(sRules), {})
            table.insert(self.MapList[string.upper(sRules)], sLevel[1])
        end
    end

    Logger:LogEventTo(RANK_ADMIN, eLogEvent_Maps, "@l_ui_loadedMaps", table.count(self.MapList["IA"]), table.count(self.MapList["PS"]))

end

---------------
ServerMaps.InitRotation = function(self)

    local aConfig = ConfigGet("General.MapConfig", self.Default, eConfigGet_Array)
    local aRotation = table.getnested(aConfig, "Rotation", {})

    local aRotationList = table.copy(aRotation.Rotation or {})

    local bIgnoreLinkless = aConfig.IgnoreNonDownloadable
    if (aConfig.UseAllMaps) then
        aRotationList = {}
        for sRules, aMaps in pairs(self.MapList) do
            for _, sMap in pairs(aMaps) do
                if (not bIgnoreLinkless or not string.empty(ServerPublisher:GetMapDownloadLink(sMap))) then
                    table.insert(aRotationList, { Map = sMap, TimeLimit = self:GetDefaultTimeLimit(sMap) })
                end
            end
        end
    end

    if (aRotation.ShuffleRotation) then
        aRotationList = table.shuffle(aRotationList)
    end

    if (true or self.MapRotation == nil or not table.compS(self.MapRotation, aRotationList)) then
        self.MapRotation = self:CreateRotation(aRotationList)
    end

    if (self.FirstInit) then
        local sMap = string.lower(ServerDLL.GetMapName())
        for _, aInfo in pairs(self.MapRotation.L) do
            if (string.lower(aInfo.MapPath) == sMap) then
                local iLimit = ParseTime(aInfo.TimeLimit or 0)
                if (iLimit > 1) then
                    self:SetTimeLimit(nil, iLimit)
                end
                ServerLog("Found Initial Map %s in Rotation, Overwriting TimeLimit to %s", aInfo.MapName or "<Undefined>", math.calctime(iLimit or 0, 6))
            end
        end
    end

    Logger:LogEventTo(RANK_ADMIN, eLogEvent_Maps, "@l_ui_initMapRotation", table.count(self.MapRotation.L))
    if (table.empty(self.MapRotation)) then
        ServerLogWarning("Map Rotation is Empty")
    end
end

---------------
ServerMaps.ResetRotation = function(self)

    ServerLog("Map Rotation Ended, Resetting..")

    self.MapRotation = nil
    self:InitRotation()
end

---------------
ServerMaps.CreateRotation = function(self, aRotation)

    local aList = {
        L = {}
    }

    aList.Empty         = function(this) return this.L[2] == nil end
    aList.GetPrevious   = function(this) if (this.Current == 1) then return this.L[1] end return this.L[(this.Current - 1)] end
    aList.GetNext       = function(this) if (this.Current >= this.Last) then return this.L[this.Last] end return this.L[(this.Current + 1)] end
    aList.GetNextID     = function(this) if (this.Current >= this.Last) then return this.Last end return (this.Current + 1) end
    aList.GetCurrent    = function(this) return this.L[this.Current] end
    aList.GetCurrentID  = function(this) return this.Current end
    aList.Next          = function(this) this.Current = this.Current + 1 if (this.Current > this.Last) then this.Current = 1 end end
    aList.Previous      = function(this) this.Current = math.max(0, this.Current - 1) end
    aList.LoadCurrent   = function(this) ServerMaps:StartLevel(this.L[this.Current]) end
    aList.StartNext     = function(this) this:Next() this:LoadCurrent() end

    local sType, sRules, sMap, iLimit
    local iCurr = 1
    for _, aInfo in pairs(aRotation) do

        if (isArray(aInfo)) then

            aList.L[iCurr] = {}

            iLimit = (aInfo.TimeLimit or self:GetDefaultTimeLimit(aInfo.Map))
            if (isString(iLimit)) then
                iLimit = ParseTime(iLimit)
            end

            sType, sRules, sMap = string.matchex(aInfo.Map, "^(.-)\\(..)\\(.*)$", "^(.-)/(..)/(.*)$")
            aList.L[_].MapPath   = aInfo.Map
            aList.L[_].MapType   = sType
            aList.L[_].MapRules  = self:LongRules(sRules)
            aList.L[_].MapName   = sMap
            aList.L[_].TimeLimit = iLimit

            iCurr = (iCurr + 1)
        end
    end

    aList.Current   = 1
    aList.Last      = table.count(aList.L)

    Debug("last:",aList.Last)

    return aList
end

---------------
ServerMaps.ListRotation = function(self, hPlayer)

    local iCurrent      = self.MapRotation:GetCurrentID()
    local aRotation     = self.MapRotation.L
    local iMapCount     = table.count(aRotation)
    local iLongestName  = table.it(aRotation, function(x, i, v) local l = string.len(v.MapName) if (x == nil or l > x) then return l end return x end)
    local iBoxWidth     = 69
    local sBanner = string.format("$9== [ ~ $4%s$9 ~ ] ==", hPlayer:Localize("@l_ui_mapRotation"))
    SendMsg(MSG_CONSOLE_FIXED, hPlayer, string.rspace(sBanner, iBoxWidth , string.COLOR_CODE, "="))
    SendMsg(MSG_CONSOLE_FIXED, hPlayer, (string.format("$9[ %s ]", string.rspace("", iBoxWidth - 4))))

    local sLine, sNext
    for _, aInfo in ipairs(aRotation) do
        sNext = ""
        if (_ == iCurrent + 1) then
            sNext = "$9< " .. hPlayer:Localize("@l_ui_upNext")
        elseif (_ == iCurrent) then
            sNext = "$9< " .. hPlayer:Localize("@l_ui_current")
        end
        sLine = string.rspace(string.format("$9[  $1%0" .. string.len(iMapCount) .. "d$9) %s $1%s$9 %s- $4%s %s$9", _, aInfo.MapRules, aInfo.MapName, string.rep(" ", iLongestName - string.len(aInfo.MapName)), math.calctime(aInfo.TimeLimit, 0, 4), sNext), (iBoxWidth - 1), string.COLOR_CODE) .. "]"
        SendMsg(MSG_CONSOLE_FIXED, hPlayer, sLine)
    end
    SendMsg(MSG_CONSOLE_FIXED, hPlayer, string.rep("=", iBoxWidth))

    return true, hPlayer:Localize("@l_ui_rotationOpenConsole", { iMapCount })
end

---------------
ServerMaps.ListMaps = function(self, hPlayer, sFilter, aMaps)

    ----------
    local aList = aMaps
    if (not aList) then

        aList = self.MapList
        if (table.countRec(aList) == 0) then
            return false, hPlayer:Localize("@l_ui_noMapsFound")
        end

        sFilter = string.lower(checkVar(sFilter, ""))
        if (string.findex(sFilter, "po", "pow", "power", "power+struggle")) then
            aList = aList["PS"]

        elseif (string.findex(sFilter, "ins", "inst", "instant", "instant+action", "action", "iaction")) then
            aList = aList["IA"]

        else
           local aNewList = {
               IA = {},
               PS = {}
           }
            for _, sMap in pairs(aList["PS"]) do
                if (string.match(string.lower(sMap), string.lower(sFilter))) then
                    table.insert(aNewList["PS"], sMap)
                end
            end
            for _, sMap in pairs(aList["IA"]) do
                if (string.match(string.lower(sMap), string.lower(sFilter))) then
                    table.insert(aNewList["IA"], sMap)
                end
            end

            aList = aNewList
        end

        if (table.countRec(aList) == 0) then
            return false, hPlayer:Localize("@l_ui_noMapsOfTypeFound", { self:LongRules(sFilter) })
        end
    end

    ----------
    local iMaps = table.countRec(aList)
    --SendMsg(MSG_CONSOLE_FIXED, hPlayer, "$9================================================================================================================")

    local bLink = false
    local sLink = ""
    local sMapPath = ""
    local sMapName = ""
    local sMapColor = ""
    local sLine = ""
    local sRulesFixed = ""
    local iIndex = 0
    local iCounter = 0
    local iMapCount = 0

    local iLineWidth = CLIENT_CONSOLE_LEN - 1

    for sRules, aAllMaps in pairs(aList) do
        sRulesFixed = self:LongRules(string.lower(sRules))

        SendMsg(MSG_CONSOLE_FIXED, hPlayer, "$9" .. string.mspace(" [ ~ $4" .. sRulesFixed .. "$9 ~ ] ", iLineWidth, nil, string.COLOR_CODE, "="))

        sLink = ""
        sLine = "     "
        iIndex = 0
        iCounter = 0
        iMapCount = table.count(aAllMaps)

        for _, sMap in pairs(aAllMaps) do
            iIndex = iIndex + 1
            iCounter = iCounter + 1

            sMapName = string.match(sMap, ".*/.*/(.*)$")
            sMapColor = "$9"
            bLink, sLink = ServerPublisher:GetMapDownloadLink(sMapPath)
            if (self:IsMapForbidden(sMapPath)) then
                sMapColor = "$4"
            elseif (not bLink) then
                sMapColor = "$6"
            end

            sLine = sLine .. "$1" .. string.lspace(iCounter, 2, nil, " ") .. ") " .. sMapColor .. sMapName .. string.rep(" ", 25 -
                    string.len(sMapName))

            if (iIndex >= 4 or iIndex == iMapCount) then
                SendMsg(MSG_CONSOLE, hPlayer, sLine)
                sLine = "     "
                iIndex = 0
            end
        end

        SendMsg(MSG_CONSOLE_FIXED, hPlayer, "")
    end

    SendMsg(MSG_CONSOLE_FIXED, hPlayer, "     $9=======================================")
    SendMsg(MSG_CONSOLE_FIXED, hPlayer, "     $9" .. hPlayer:Localize("@l_ui_note_maplist_1"))
    SendMsg(MSG_CONSOLE_FIXED, hPlayer, "     $9" .. hPlayer:Localize("@l_ui_note_maplist_2"))
    SendMsg(MSG_CONSOLE_FIXED, hPlayer, "$9================================================================================================================")
end

---------------
ServerMaps.StartNextMap = function(self, hAdmin, iTimer)

    self.MapChangeTimer = iTimer
    self.EndGame = true

    if (self.MapRotation:Empty()) then
        return false, hAdmin:Localize("@l_ui_levelRotationEmpty")
    end

    local bOk, sMsg = self:OnNextLevel(true)
    if (not bOk) then
        return false, hAdmin:Localize(sMsg)
    end
    return true
end

---------------
ServerMaps.StartMap = function(self, hAdmin, sMap, iTimer)

    local aInfo, sMsg = self:GetMap(sMap, hAdmin)
    if (not isArray(aInfo)) then
        return aInfo, sMsg
    end

    self:StartLevel(table.merge(aInfo[1], { ChangeTimer = iTimer }))
    Debug("change..")
end

---------------
ServerMaps.GetMap = function(self, sMap, hAdmin)

    local aInfo = self:FindLevel(sMap)
    if (table.empty(aInfo)) then
        return false, hAdmin and hAdmin:Localize("@l_ui_levelNotFound", { sMap })
    elseif (table.size(aInfo) > 1) then
        if (hAdmin) then
            self:ListMaps(hAdmin, nil, self:SortResults(aInfo))
            SendMsg(CHAT_SERVER, hAdmin, hAdmin:Localize("@l_ui_levelsListedInConsole", { table.count(aInfo) }))
        end
        return true
    end

    return aInfo
end

---------------
ServerMaps.SortResults = function(self, aList, sFilter)

    --Debug(aList)
    local aSorted = {}
    local sType, sRules, sMap
    for _, aInfo in pairs(aList) do
        sType, sRules, sMap = string.matchex(aInfo.MapPath, unpack(self.MapPatterns))
        if (sFilter == nil or (sMap and string.match(sMap, sFilter))) then
            table.checkM(aSorted, string.upper(sRules), {})
            table.insert(aSorted[string.upper(sRules)], aInfo.MapPath)
        end
    end
    return aSorted
end


---------------
ServerMaps.FindLevel = function(self, sMap)

    local aResults = { }
    local sMapName
    for sRules, aLevels in pairs(self.MapList) do
        for _, sLevel in pairs(aLevels) do
            sMapName = string.match(sLevel, "^.*/.*/(.*)")
            if (IsAny(sMap:lower(), sLevel:lower(), sMapName:lower())) then
                return {{ MapName = sMapName, MapRules = sRules, MapPath = sLevel }}
            end

            if (string.lower(sMap) == string.lower(sLevel) or string.match(sLevel:lower(), (sMap:lower() .. "$")) or string.match(sMapName:lower(), (sMap:lower()))) then
                table.insert(aResults, { MapName = sMapName, MapRules = sRules, MapPath = sLevel })
            end
        end
    end

    return aResults
end

---------------
ServerMaps.OnReset = function(self, aInfo)
    self.MapChanged = true
    self.EndGame = nil

    g_gameRules.QuietGameEnd = false
    g_gameRules.NoMapChange = false
    g_gameRules.GameEnded = nil

    if (self.RestartTimer) then
        Script.KillTimer(self.RestartTimer)
    end
    self.RestartCD = nil
    self.RestartTimer = nil
end

---------------
ServerMaps.StartLevel = function(self, aInfo)

    local sMap       = aInfo.MapPath
    local sRules     = self:LongRules(aInfo.MapRules)
    local iTimeLimit = (aInfo.TimeLimit or self.DefaultTimeLimit)
    local iTimer     = math.max(5, self.MapChangeTimer or aInfo.ChangeTimer or 0)
    local bEndGame   = aInfo.EndGame

    if (self.LevelChangeTimer) then
        if (aInfo.KeepTimer) then
            return false
        end
        Script.KillTimer(self.LevelChangeTimer)
    end

    if (aInfo.Quiet) then
        g_gameRules.QuietGameEnd = true
    else
        g_gameRules.QuietGameEnd = false
    end

    -- risa risa, dont silence these.. for now!
    if (not g_gameRules.GameEnded) then
        Logger:LogEvent(eLogEvent_Maps, "@l_ui_startingLevel", aInfo.MapName, sRules, (iTimer .. "s"))
        SendMsg(CHAT_SERVER_LOCALE, ALL_PLAYERS, "@l_ui_startingLevel_Chat", aInfo.MapName, sRules, math.calctime(iTimer, nil, 3))
    else
        iTimer = 0
    end

    if (bEndGame) then
        if (g_gameRules.IS_PS) then
            g_gameRules:EndGameWithWinner_PS()
        else
            g_gameRules:EndGameWithWinner_IA()
        end
        g_gameRules.NoMapChange = true
    end

    self.LevelChangeTimer = Script.SetTimer((iTimer * 1000), function()

        -- FIXME: EndGame()!

        if (self.RestartTimer) then
            Script.KillTimer(self.RestartTimer)
        end
        self.MapChanged = true
        self.EndGame = nil

        g_gameRules.NoMapChange = false
        g_gameRules.GameEnded = nil

        System.SetCVar("g_timeLimit", g_ts(iTimeLimit / 60))
        System.SetCVar("sv_gameRules", sRules)
        System.ExecuteCommand("map " .. sMap)
    end)

    self.MapChangeTimer = nil
    return true
end


---------------
ServerMaps.OnNextLevel = function(self, bCommand)

    if (not ConfigGet("General.MapConfig.Enabled", true, eConfigGet_Boolean)) then
        return false
    end

    if (bCommand and g_gameRules.GameEnded) then
        return false, "@l_ui_gameAlreadyEnding"
    end
    self.EndGame = bCommand

    if (self.MapRotation:Empty()) then
        self:RestartLevel()
        if (self.LevelRestartTimer) then
            Script.KillTimer(self.LevelRestartTimer)
        end
        self.LevelRestartTimer = Script.SetTimer(5000, function()
        end)

        return true
    else
        self.MapRotation:StartNext()
    end
    return true
end

---------------
ServerMaps.RestartLevel = function()
    System.ExecuteCommand("sv_restart")
end

---------------
ServerMaps.GetLevel = function()
    local sLevel = ServerDLL.GetMapName()
    local sType, sRules, sMap = string.matchex(sLevel, unpack(ServerMaps.MapPatterns))
    return sMap, sRules, sType
end

---------------
ServerMaps.GetNextLevel = function(self)

    local aRotation = self.MapRotation
    if (table.empty(aRotation)) then
        return self:GetLevel()
    end

    local aNext = aRotation:GetNext()
    return aNext.MapName, aNext.MapRules, aNext.MapType
end

---------------
ServerMaps.LongRules = function(self, sRules)

    if (not sRules) then
        return
    end

    sRules = string.lower(sRules)
    if (sRules == "ia" or sRules == "instantaction") then
        return "InstantAction"

    elseif (sRules == "ps" or sRules == "powerstruggle") then
        return "PowerStruggle"

    end

    return sRules
end

---------------
ServerMaps.ShortRules = function(self, sRules)

    if (not sRules) then
        return
    end

    sRules = string.lower(sRules)
    if (sRules == "instantaction" or sRules == "ia") then
        return "IA"

    elseif (sRules == "powerstruggle" or sRules == "ps") then
        return "PS"

    end

    return sRules
end

---------------
ServerMaps.CreateLevelInfo = function(self, sPath, iTimer)

    --Debug(">",sPath)
    -- wtf is this.. who made this?
    return isArray(sPath) and sPath or {

        MapPath = sPath,
        MapName = string.match(sPath, ".-/../(.*)") or sPath,
        ChangeTimer = (iTimer or 10)

    }

end

---------------
ServerMaps.GetDefaultTimeLimit = function(self, sMap)

    local sName, sRules, sType = string.matchex(sMap, unpack(self.MapPatterns))
    if (sRules) then
        return (self["DefaultTimeLimit_" .. string.upper(sRules)] or self.DefaultTimeLimit)
    end
    return self.DefaultTimeLimit
end

---------------
ServerMaps.GetTimeLimit = function(self, hDefault)

    if (g_pGame:IsTimeLimited()) then
        return g_pGame:GetRemainingGameTime()
    end
    return hDefault
end

---------------
ServerMaps.RestartMap = function(self, hAdmin, iCountdown)

    if (self.RestartCD) then
        return false, hAdmin:Localize("@l_ui_mapAlreadyRestarting")
    end
    local iTime = math.min(iCountdown, self:GetTimeLimit(70) - 10)
    if (iTime > 0) then
        self.RestartCD = true
        Debug(iTime,iTime*1000)
        ServerMaps.RestartTimer = Script.SetTimer(iTime * 1000, function()

            self.RestartCD = false
            self.RestartTimer = nil
            --if (self.MapChanged) then
            --    self.MapChanged = false
            --    return
            --end
            System.ExecuteCommand("sv_restart")
        end)
        Logger:LogEvent(eLogEvent_Maps, "@l_ui_mapRestartingIn",math.calctime(iTime))
        return true, Logger:RemoveColors(hAdmin:Localize("@l_ui_mapRestartingIn", {math.calctime(iTime)}))
    else
        System.ExecuteCommand("sv_restart")
    end
end

---------------
ServerMaps.SetTimeLimit = function(self, hAdmin, iTime)

    local iMinutes = math.max(0, iTime)
    Debug(">",iTime)

    System.SetCVar("g_timelimit", iMinutes)
    g_pGame:ResetGameTime()
end

---------------
ServerMaps.AddTimeLimit = function(self, iTime)

    if (not g_pGame:IsTimeLimited()) then
        return
    end

    local iRemaining = g_pGame:GetRemainingGameTime()
    self:SetTimeLimit(nil, (iTime + iRemaining) / 60)
end