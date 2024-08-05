------------------
PlayerHandler = (PlayerHandler or {

    CachedInfo = {},
    PlayerData = {},

    DataDir  = (SERVER_DIR_DATA .. "PlayerData\\"),
    DataFile = "PlayerData.lua"

})

------------------
PlayerHandler.Init = function(self)

    --- Cases
    ePlayerData_All = 0
    ePlayerData_LastVisit = "last_visit"
    ePlayerData_GameTime  = "play_time"
    ePlayerData_PlayTime  = "game_time"
    ePlayerData_LastName  = "last_name"

    ALL_PLAYERS = 0

    --- Link Event
    EventLink(eServerEvent_OnScriptReload, "PlayerHandler", "SaveFile")
    self:LoadFile()

    --- Log
    Logger:LogEventTo(GetDevs(), eLogEvent_DataLog, "Loaded Player Data from ${red}%d${gray} Users", table.count(self.PlayerData))
end

------------------
PlayerHandler.LoadFile = function(self)

    local sFile = (self.DataDir .. self.DataFile)
    local aData = FileLoader:ExecuteFile(sFile, eFileType_Data)
    if (not aData) then
        return
    end

    self.PlayerData = aData
end

-------------------
PlayerHandler.SaveFile = function(self)

    local sData = string.format("return %s", (table.tostring((self.PlayerData or {}), "", "") or "{}"))
    local sFile = (self.DataDir .. self.DataFile)

    local bOk, sErr = FileOverwrite(sFile, sData)
    if (not bOk) then

        HandleError("Error saving File %s (%s)", self.DataFile, sErr)
        ServerLogError("Failed to open file %s for writing", sFile)
    end
end

------------------
PlayerHandler.OnClientDisconnect = function(self, hClient, bNoSave)

    hClient:SetData(ePlayerData_LastName, hClient:GetName())
    hClient:SetData(ePlayerData_LastVisit, GetTimestamp())

    local sID = hClient:GetProfileID()
    local aData = hClient:GetStoredData()

    self.PlayerData[sID] = aData
    if (not bNoSave) then
        self:SaveFile()
    end

    CallEvent(eServerEvent_SavePlayerData, hClient)

end

------------------
PlayerHandler.SavePlayerData = function(self)

    for _, hClient in pairs(GetPlayers()) do
        ServerLog("FOR CLIENT %s",hClient:GetName())
        self:OnClientDisconnect(hClient, true)
    end
    self:SaveFile()
end

------------------
PlayerHandler.GetPlayerData = function(self, sID)
    return self.PlayerData[sID]
end

------------------
PlayerHandler.InitClient = function(self, hClient, iChannel)

    self.RegisterFunctions(hClient, iChannel)
    EventCall(eServerEvent_OnClientInit, hClient, iChannel)
end

------------------
PlayerHandler.GetClientInfo = function(self, iChannel)

    self:CreateClientInfo(iChannel)
    return (self.CachedInfo[iChannel])
end

------------------
PlayerHandler.SetClientInfo = function(self, iChannel, aInfo)

    self:CreateClientInfo(iChannel)
    if (not aInfo) then
        error("no info")
    end

    self.CachedInfo[iChannel].IPData.Data = aInfo
    ServerLog("%s",table.tostring(aInfo))
end

------------------
PlayerHandler.CreateClientInfo = function(self, iChannel)

    if (self.CachedInfo[iChannel]) then
        return
    end

    local sChannelName = ServerDLL.GetChannelName(iChannel)
    local sHostName, sPort = string.match(sChannelName, "(.-):(%d+)")

    self.CachedInfo[iChannel] = {

        -- Client Profile Validated?
        Validated   = false,
        Validating  = false,

        ChannelNick = ServerDLL.GetChannelNick(iChannel),
        ChannelID   = iChannel,
        ProfileID   = GetInvalidID(),
        HostName    = sHostName,
        Port        = sPort,
        IP          = ServerDLL.GetChannelIP(iChannel),

        ----------
        IPData = {

            Data = {},
            Default = ServerChannels:GetDefaultData(),

            Set             = function(x, y) x.Info.Data = y end,
            GetCountry      = function(x) ServerLog(table.tostring(x.Info.Data)) local f = (x.Info.Data or {}) return (f["Country"] or f["country"] or x.Info.IPData.Default.Country) end,
            GetCountryCode  = function(x) local f = (x.Info.IPData.Data or {}) return (f["CountryCode"] or f["countryCode"] or x.Info.IPData.Default.CountryCode) end
        },

        ----------
        Rank = {
            ID        = GetDefaultRank(),
            PendingID = nil,
            Dev       = false,

            Is    = function(x, y) return (x.Info.Rank.ID == y) end,
            Has   = function(x, y) return (x.Info.Rank.ID >= y) end,
            IsNot = function(x, y) return (x.Info.Rank.ID ~= y)  end,
            Set   = function(x, y) x.Info.Rank.ID = y  end,
            IsDev = function(x) return x.Info.Rank.Dev == true  end,
        },

        ----------
        Language = {
            Language  = SERVER_LANGUAGE,
            Preferred = SERVER_LANGUAGE
        },

        ----------
        StoredData = {
            Loaded = false,
            Data   = {}
        }
    }
end

------------------
PlayerHandler.RegisterFunctions = function(hClient, iChannel)

    hClient.IsPlayer  = true
    hClient.Info      = PlayerHandler:GetClientInfo(iChannel)

    hClient.IsValidated     = function(self) return (self.Info.Validated == true) end
    hClient.GetProfileID    = function(self) return self.Info.ProfileID end
    hClient.GetProfile      = function(self) return self.Info.ProfileID end
    hClient.SetProfile      = function(self, hProfile) self.Info.ProfileID = hProfile end
    hClient.SetProfileID    = function(self, hProfile) self.Info.ProfileID = hProfile end
    hClient.GetInfo         = function(self) return self.Info end
    hClient.GetChannel      = function(self) return self.Info.ChannelID end
    hClient.GetIP           = function(self) return self.Info.IP end
    hClient.GetHostName     = function(self) return self.Info.HostName end
    hClient.GetPort         = function(self) return self.Info.Port end
    hClient.GetIPData       = function(self) return self.Info.IPData end
    hClient.GetCountryCode  = function(self) return self.Info.IPData.GetCountryCode(self) end
    hClient.GetCountry      = function(self) return self.Info.IPData.GetCountry(self) end
    hClient.GetServerRank   = function(self) return self.Info.Rank end
    hClient.GetRankName     = function(self) return GetRankName(self.Info.Rank.ID) end
    hClient.GetAccess       = function(self) return self.Info.Rank.ID end
    hClient.SetAccess       = function(self, iRank) self.Info.Rank.ID = iRank self.Info.Rank.PendingID = nil self.Info.Rank.Dev = IsDevRank(iRank) end
    hClient.SetPendingAccess= function(self, iRank) self.Info.Rank.PendingID = iRank end
    hClient.GetPendingAccess= function(self) return self.Info.Rank.PendingID end
    hClient.HasAccess       = function(self, iRank) return self.Info.Rank.Has(self, iRank) end
    hClient.IsDevRank       = function(self, iRank) return self.Info.Rank.IsDev(self, iRank) end
    hClient.IsAccess        = function(self, iRank) return self.Info.Rank.Is(self, iRank) end
    hClient.GetLanguage     = function(self) return self.Info.Language.Language end
    hClient.SetLanguage     = function(self, sLang) self.Info.Language.Language = sLang end

    hClient.GetTeam         = function(self) return (g_pGame:GetTeam(self.id)) end
    hClient.SetTeam         = function(self, iTeam) g_pGame:SetTeam(iTeam, self.id) end
    hClient.GetKills        = function(self) return (g_gameRules:GetKills(self.id) or 0) end
    hClient.SetKills        = function(self, kills) g_gameRules:SetKills(self.id, kills) end
    hClient.GetDeaths       = function(self) return (g_gameRules:GetDeaths(self.id) or 0) end
    hClient.SetDeaths       = function(self, deaths) g_gameRules:SetDeaths(self.id, deaths) end
    hClient.GetRank         = function(self) return (g_gameRules:GetPlayerRank(self.id) or 0) end
    hClient.SetRank         = function(self, rank) g_gameRules:SetPlayerRank(self.id, rank) end
    hClient.GetCP           = function(self) g_gameRules:GetPlayerCP(self.id) end
    hClient.SetCP           = function(self, cp) g_gameRules:SetPlayerCP(self.id, cp) end
    hClient.GetPrestige     = function(self) return (g_gameRules:GetPlayerPrestige(self.id) or 0) end
    hClient.SetPrestige     = function(self, pp) g_gameRules:SetPlayerPrestige(self.id, pp) end

    hClient.GetStoredData   = function(self) return self.Info.StoredData.Data end
    hClient.SetStoredData   = function(self, data) self.Info.StoredData.Data = data end

    hClient.GetData         = function(self, id, default) return checkVar(self.Info.StoredData.Data[id], default) end
    hClient.SetData         = function(self, id, data) self.Info.StoredData.Data[id] = data end
    hClient.AddData         = function(self, id, data) self.Info.StoredData.Data[id] = ((self.Info.StoredData.Data[id] or 0) + data) end

    --> Data
    hClient.GetGameTime     = function(self) return self:GetData(ePlayerData_GameTime, 0)  end
    hClient.GetPlayTime     = function(self) return self:GetData(ePlayerData_PlayTime, 0) + self:GetGameTime()  end

    hClient.DataLoaded      = function(self) return self.Info.StoredData.Loaded end
    hClient.SetDataLoaded   = function(self, mode) self.Info.StoredData.Loaded = mode end
    hClient.GetLastVisit    = function(self, style, never, today) local d = (never or "Never") local s = self:GetData(ePlayerData_LastVisit, d) if (s == d) then return d end local n = GetTimestamp() local pt = s - n if (pt < ONE_DAY) then return (today or "Today") end return math.calctime(pt, (style or 1))  end

    hClient.SetPreferredLanguage = function(self, sLang) self.Info.Language.Preferred = sLang end
    hClient.GetPreferredLanguage = function(self) return self.Info.Language.Preferred end

    hClient.Tick = function(self)

        if (self:IsValidated()) then

            local sID        = self:GetProfileID()
            local iPending   = self:GetPendingAccess()
            local aInfo      = ServerAccess:GetRegisteredUser(self:GetProfile())
            local bIsPeasant = (self:GetAccess() == GetDefaultRank())

            if (bIsPeasant) then
                if (iPending) then
                    self:SetAccess(iPending)
                    self.PendingAccess = nil

                elseif (aInfo and bIsPeasant) then
                    ServerAccess:AssignAccess(self, aInfo.Rank)
                end
            end

            if (sID) then
                local aData = PlayerHandler:GetPlayerData(sID)
                if (aData) then
                    if (not self:DataLoaded()) then
                        self:SetStoredData(table.merge(self:GetStoredData(), aData))
                        self:SetDataLoaded(true)
                    end
                end

                -- Call Event
                if (not self.ValidateLinked) then
                    CallEvent(eServerEvent_OnClientValidated, self, sID)
                    self.ValidateLinked = true
                end
            end

            -- Update Data Values
            self:AddData(ePlayerData_GameTime, self.LastTick.diff())

            -- If not connected already, do so now
            if (not self.Connected) then
                ServerPCH:OnConnected(self, self:GetChannel())
            end

        -- It's delayed to allow the client to send !validate first!
        elseif (self.InitTimer.expired()) then

            if (not self.Connected) then
                ServerPCH:OnConnected(self, self:GetChannel())
            end
        end

        self.LastTick.refresh()
    end

    hClient.Update = function(self)
    end

    hClient.Info.Initialized = true
    hClient.InfoInitialized  = true
    hClient.InitTimer        = (hClient.InitTimer or timernew(5))
    hClient.LastTick         = timernew()

    SendMsg(MSG_CENTER, hClient, "Successfully Initialized")
    ServerLog("Client Initialized!")
end