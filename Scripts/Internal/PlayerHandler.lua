------------------
PlayerHandler = (PlayerHandler or {

    CachedInfo = {},
    PlayerData = {},

    DataDir  = (SERVER_DIR_DATA .. "PlayerData\\"),
    DataFile = "PlayerData.lua"

})

------------------

ePlayerData_All             = 0
ePlayerData_LastVisit       = "last_visit"
ePlayerData_GameTime        = "play_time"
ePlayerData_PlayTime        = "game_time"
ePlayerData_LastName        = "last_name"
ePlayerData_Equipment       = "equipment"
ePlayerData_PreferredLang   = "language"

ALL_PLAYERS = 0

------------------

eHitAccuracy_OnShot = 0
eHitAccuracy_OnHit  = 1

------------------

ePlayerPunish_None          = 0
ePlayerPunish_NoEquipment   = 1

------------------

ePlayerTemp_SpectatorEquip  = 0

------------------

ePlayerTimer_EquipmentMsg       = 0
ePlayerTimer_EquipmentLoadedMsg = 1

------------------
PlayerHandler.Init = function(self)

    --- Link Event
    EventLink(eServerEvent_OnScriptReload, "PlayerHandler", "SavePlayerData")
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

    ServerLog("File Saved.")
end

------------------
PlayerHandler.OnClientDisconnect = function(self, hClient, bNoSave, bQuiet)

    local sName = hClient:GetName()
    if (not ServerNames:IsNomad(sName)) then
        hClient:SetData(ePlayerData_LastName, sName)
    end
    hClient:SetData(ePlayerData_LastVisit, GetTimestamp())

    local sID = hClient:GetProfileID()
    local aData = hClient:GetStoredData()

    self.PlayerData[sID] = aData
    if (not bNoSave) then
        self:SaveFile()
    end

    CallEvent(eServerEvent_SavePlayerData, hClient, bQuiet)

end

------------------
PlayerHandler.SavePlayerData = function(self)

    for _, hClient in pairs(GetPlayers()) do
        ServerLog("FOR CLIENT %s",hClient:GetName())
        self:OnClientDisconnect(hClient, true, true)
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
PlayerHandler.InitServer = function(self, hServer)

    self.RegisterFunctions(hServer, SERVERENT_CHANNEL, true)
    EventCall(eServerEvent_OnServerInit, hServer)
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

    local sChannelName      = (ServerDLL.GetChannelName(iChannel) or "")
    local sIP               = (ServerDLL.GetChannelIP(iChannel) or "")
    local sHostName, sPort  = string.match(sChannelName, "(.-):(%d+)")
    local iDefRank          = GetDefaultRank()

    if (iChannel == SERVERENT_CHANNEL) then
        sChannelName = MOD_NAME
        sHostName    = MOD_NAME
        sPort        = 6969
        sIP          = "127.0.0.1"
        iDefRank     = GetHighestRank()
    end

    self.CachedInfo[iChannel] = {

        -- Client Profile Validated?
        Validated   = false,
        Validating  = false,

        StaticID    = nil,
        HWID        = nil,
        ChannelNick = sChannelName,
        ChannelID   = iChannel,
        ProfileID   = GetInvalidID(),
        AccountName = "Nomad",
        HostName    = sHostName,
        Port        = sPort,
        IP          = sIP,

        ----------
        LastPing    = 0,
        RealPing    = 0,

        ----------
        Buying = {
            Cooldowns = {},
            Set       = function(this, id) this.Cooldowns[id] = timerinit() end,
            Get       = function(this, id) return timerdiff(this.Cooldowns[id]) end,
            IsOn      = function(this, id, time) if (not this.Cooldowns[id]) then return false end return (timerexpired(this.Cooldowns[id], time)) end
        },

        ----------
        Timers = {
            Timers  = {},
            Expired = function(this, id, seconds, refresh) if (this.Timers[id] == nil) then this.Timers[id] = timernew(id) return true end if (this.Timers[id].expired(seconds)) then if (refresh) then this.Timers[id].refresh() end return true end return false end,
            Refresh = function(this, id, newseconds) if (not id) then return throw_error("No timer ID specified!") end if (not this.Timers[id]) then return end this.Timers[id].refresh(newseconds) end,
            Diff    = function(this, id) if (not id) then return throw_error("No timer ID specified!") end if (not this.Timers[id]) then return 0 end this.Timers[id].diff() end
        },

        ----------
        -- FIXME: ClientMod
        ClientMod = {
            InstallTimer    = nil,
            IsInstalled     = false, -- Did she install the client mod?
            ModVersion      = "0.0", -- The client mod version
            ClientVersion   = "0.0", -- The client's client version
        },

        ----------
        MPClientMod = { -- MULTIPLAYER
        },

        ----------
        IPData = {

            Data = {},
            Default = ServerChannels:GetDefaultData(),

            Set             = function(x, y) x.Info.Data = y end,
            GetCountry      = function(x) local f = (x.Info.Data or {}) return (f["Country"] or f["country"] or x.Info.IPData.Default.Country) end,
            GetCountryCode  = function(x) local f = (x.Info.IPData.Data or {}) return (f["CountryCode"] or f["countryCode"] or x.Info.IPData.Default.CountryCode) end
        },

        ----------
        Rank = {
            ID        = iDefRank,
            PendingID = nil,
            Dev       = false,
            Admin     = false,
            Premium   = false,

            Is        = function(x, y) return (x.Info.Rank.ID == y) end,
            Has       = function(x, y) return (x.Info.Rank.ID >= y) end,
            IsNot     = function(x, y) return (x.Info.Rank.ID ~= y)  end,
            Set       = function(x, y) x.Info.Rank.ID = y  end,
            IsDev     = function(x) return x.Info.Rank.Dev == true  end,
            IsAdmin   = function(x) return x.Info.Rank.Admin == true  end,
            IsPremium = function(x) return x.Info.Rank.Premium == true  end,
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
        },

        ----------
        SpawnLocations = {
            default = nil
        },

        ----------
        Punishment = {

            WasBanned   = false,

            -- FIXME
            Punished    = false,
            Types       = {
                [ePlayerPunish_None]        = false, -- None
                [ePlayerPunish_NoEquipment] = false, -- No Equipment
            },

            Is = function(this, f) return (this.Punished == true and this.Types[f] == true)  end
        },

        ----------
        MuteInfo = nil,

        ----------
        Temporary = {  },

        ----------
        HitAccuracy = {
            Timer   = timernew(10), -- Expires after 10s..

            Hits    = 0,
            Shots   = 0,

            OnHit   = function(this) this:Refresh(1) this.Hits = ((this.Hits or 0) + 1)  end,
            OnShot  = function(this) this:Refresh(1) this.Shots = ((this.Shots or 0) + 1)  end,
            Expired = function(this) return (this.Timer.expired())  end,
            Refresh = function(this, keep) this.Timer.refresh() if (not keep) then this.Shots = 0 this.Hits = 0 end  end,
            Get     = function(this) if (this.Shots == 0) then return 0 elseif (this.Hits == 0) then return 0 end return math.min(100, math.max(0, (this.Hits / this.Shots) * 100))  end,
        }
    }
end

------------------
PlayerHandler.RegisterFunctions = function(hClient, iChannel, bServer)

    hClient.CommandTimers = {}

    hClient.IsPlayer  = (not bServer)
    hClient.IsServer  = (bServer)
    hClient.Info      = PlayerHandler:GetClientInfo(iChannel)

    hClient.IsFrozen        = function(self) return g_pGame:IsFrozen(self.id)  end
    hClient.IsAlive         = function(self, ignorespec) return (self:GetHealth() > 0 and (ignorespec or not self:IsSpectating()))  end
    hClient.IsDead          = function(self) return (self:GetHealth() <= 0) end
    hClient.IsSpectating    = function(self) return (self.actor:GetSpectatorMode() ~= 0) end
    hClient.Spectate        = function(self, mode, target) self.inventory:Destroy() self.actor:SetSpectatorMode(mode, (target and target.id or NULL_ENTITY)) end
    hClient.GetHealth       = function(self) return (self.actor:GetHealth() or 0)  end
    hClient.SetHealth       = function(self, health) self.actor:SetHealth(health)  end
    hClient.GetEnergy       = function(self) return (self.actor:GetNanoSuitEnergy())  end
    hClient.SetEnergy       = function(self, energy) self.actor:SetNanoSuitEnergy(energy)  end
    hClient.GetSuitMode     = function(self, mode) local m = self.actor:GetNanoSuitMode() if (mode) then return (m == mode) end return m  end
    hClient.SetSuitMode     = function(self, mode) self.actor:SetNanoSuitMode(mode) end -- NOT synched
    hClient.GetVehicle      = function(self) return GetEntity(self:GetVehicleId()) end -- NOT synched
    hClient.GetVehicleId    = function(self) return self.actor:GetLinkedVehicleId() end -- NOT synched

    hClient.GetFacingPos        = function(self, iFace, iDistance, iFollowType, t) return GetFacingPos(self, iFace, iDistance, iFollowType, t)  end
    hClient.GetHeadPos          = function(self) return self.actor:GetHeadPos() end
    hClient.GetHeadDir          = function(self) return self.actor:GetHeadDir()  end
    hClient.GetViewPoint        = function(self, dist) return (self.actor:GetLookAtPoint(dist or 9999))  end
    hClient.SvMoveTo            = function(self, pos, ang) self:SetInvulnerability(5) g_pGame:MovePlayer(self.id, vector.modifyz(pos, 0.25), (ang or self:GetWorldAngles()))  end
    hClient.SetInvulnerability  = function(self, time) g_pGame:SetInvulnerability(self.id, true, (time or 2.5)) end

    hClient.IsValidated     = function(self) return (self.Info.Validated == true) end
    hClient.GetProfileID    = function(self) return self.Info.ProfileID end
    hClient.GetProfile      = function(self) return self.Info.ProfileID end
    hClient.GetAccountName  = function(self) return self.Info.AccountName end
    hClient.SetProfile      = function(self, hProfile) self.Info.ProfileID = hProfile end
    hClient.SetProfileID    = function(self, hProfile) self.Info.ProfileID = hProfile end
    hClient.GetInfo         = function(self) return self.Info end
    hClient.GetChannel      = function(self) return self.Info.ChannelID end
    hClient.GetIP           = function(self) return self.Info.IP end
    hClient.GetStaicID      = function(self) return self.Info.StaticID end
    hClient.GetHWID         = function(self) return self.Info.HWID end
    hClient.GetHostName     = function(self) return self.Info.HostName end
    hClient.GetHost         = function(self) return self.Info.HostName end
    hClient.GetPort         = function(self) return self.Info.Port end
    hClient.GetIPData       = function(self) return self.Info.IPData end
    hClient.GetCountryCode  = function(self) return self.Info.IPData.GetCountryCode(self) end
    hClient.GetCountry      = function(self) return self.Info.IPData.GetCountry(self) end
    hClient.GetServerRank   = function(self) return self.Info.Rank end
    hClient.GetRankName     = function(self) return GetRankName(self.Info.Rank.ID) end
    hClient.GetAuthority    = function(self, minimum) local i = self.Info.Rank.ID if (i == GetHighestRank()) then return i end i = i + 1 if (i < minimum) then i = minimum end return i end
    hClient.GetAccess       = function(self) return self.Info.Rank.ID end
    hClient.SetAccess       = function(self, iRank) self.Info.Rank.ID = iRank self.Info.Rank.PendingID = nil self.Info.Rank.Dev = IsDevRank(iRank) self.Info.Rank.Admin = IsAdminRank(iRank) self.Info.Rank.Premium = IsPremiumRank(iRank) end
    hClient.SetPendingAccess= function(self, iRank) self.Info.Rank.PendingID = iRank end
    hClient.GetPendingAccess= function(self) return self.Info.Rank.PendingID end
    hClient.HasAccess       = function(self, iRank) return self.Info.Rank.Has(self, iRank) end
    hClient.IsDevRank       = function(self, iRank) return self.Info.Rank.IsDev(self, iRank) end
    hClient.IsDeveloper     = function(self, iRank) return self.Info.Rank.IsDev(self, iRank) end
    hClient.IsAdmin         = function(self, iRank) return IsAdminRank((iRank or self:GetAccess())) end
    hClient.IsPremium       = function(self, iRank) return IsPremiumRank((iRank or self:GetAccess())) end
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
    hClient.AddPrestige     = function(self, pp, reason) self:SetPrestige(self:GetPrestige() + pp) if (reason) then end end -- TODO: ClientMod()
    hClient.AwardPrestige   = function(self, pp, reason) g_gameRules:AwardPPCount(self.id, pp, nil, self:HasClientMod()) if (reason) then end end -- TODO: ClientMod()
    hClient.AwardCP         = function(self, pp, reason) g_gameRules:AwardCPCount(self.id, pp) if (reason) then end end -- TODO: ClientMod()
    hClient.GetStoredData   = function(self) return self.Info.StoredData.Data end
    hClient.SetStoredData   = function(self, data) self.Info.StoredData.Data = data end
    hClient.GetData         = function(self, id, default) return checkVar(self.Info.StoredData.Data[id], default) end
    hClient.SetData         = function(self, id, data) self.Info.StoredData.Data[id] = data end
    hClient.AddData         = function(self, id, data) self.Info.StoredData.Data[id] = ((self.Info.StoredData.Data[id] or 0) + data) end

    hClient.SetTemp = function(self, id, data, no_overwrite)
        if (self.Info.Temporary[id] ~= nil and no_overwrite) then
            return
        end
        self.Info.Temporary[id] = data
    end
    hClient.GetTemp = function(self, id, default, destroy)
        local c = self.Info.Temporary[id]
        if (c == nil) then
            return
        end
        if (destroy) then
            self.Info.Temporary[id] = nil
        end
        return c
    end

    -- TODO ClientMod :o
    hClient.HasClientMod    = function(self) return self.Info.ClientMod.IsInstalled  end
    hClient.GetClientMod    = function(self, data) if (data) then return self.Info.ClientMod[data] end return self.Info.ClientMod end

    -- mp
    hClient.GetMPClient     = function(self, data) if (data) then return self.Info.MPClientMod[data] end return self.Info.MPClientMod end

    --> Timers
    hClient.GetBuyCooldown  = function(self, id) return self.Info.Buying:Get(id) end
    hClient.OnBuyCooldown   = function(self, id, seconds) return self.Info.Buying:IsOn(id, seconds) end
    hClient.SetBuyCooldown  = function(self, id) return self.Info.Buying:Set(id) end
    hClient.TimerExpired    = function(self, id, seconds, refresh) return self.Info.Timers:Expired(id, seconds, refresh) end
    hClient.TimerRefresh    = function(self, id, newseconds) return self.Info.Timers:Refresh(id, newseconds) end
    hClient.TimerDiff       = function(self, id) return self.Info.Timers:Diff(id) end

    --> Data
    hClient.GetGameTime     = function(self) return self:GetData(ePlayerData_GameTime, 0)  end
    hClient.GetPlayTime     = function(self) return self:GetData(ePlayerData_PlayTime, 0) + self:GetGameTime()  end
    hClient.DataLoaded      = function(self) return self.Info.StoredData.Loaded end
    hClient.SetDataLoaded   = function(self, mode) self.Info.StoredData.Loaded = mode end
    hClient.GetLastVisit    = function(self, style, never, today) local d = (never or "Never") local s = self:GetData(ePlayerData_LastVisit, d) if (s == d) then return d end local n = GetTimestamp() local pt = s - n if (pt < ONE_DAY) then return (today or "Today") end return math.calctime(pt, (style or 1))  end
    hClient.GetPing         = function(self, check, n) local p = self.Info.LastPing if (check) then if (n) then return p ~= check end return p == check end return p end
    hClient.SetPing         = function(self, ping) self.Info.LastPing = ping end
    hClient.GetRealPing     = function(self) return (g_pGame:GetPing(self:GetChannel() or 0) * 1000)  end
    hClient.SetRealPing     = function(self, real) g_pGame:SetSynchedEntityValue(self.id, g_gameRules.SCORE_PING_KEY, math.floor(real))  end
    hClient.GetCurrentItem  = function(self) return self.inventory:GetCurrentItem() end
    hClient.HasItem         = function(self, class) return self.inventory:GetItemByClass(class) end
    hClient.GetItem         = function(self, class) return self.inventory:GetItemByClass(class) end
    hClient.GiveItem        = function(self, class, noforce) return ItemSystem.GiveItem(class, self.id, (not noforce)) end
    hClient.GiveItemPack    = function(self, pack, noforce) return ItemSystem.GiveItemPack(self.id, pack, (not noforce)) end
    hClient.SelectItem      = function(self, class) return self.actor:SelectItemByNameRemote(class) end
    hClient.GetEquipment    = function(self) local a = self.inventory:GetInventoryTable() local e for i, v in pairs(a) do local x = GetEntity(v) if (x and x.weapon) then if (e == nil) then e = {} end table.insert(e, { x.class, table.it(x.weapon:GetAttachedAccessories(), function(ret, index, val) local class = GetEntity(val) if (ret == nil) then return { class }  end table.insert(ret, class) end) }) end end return e end

    hClient.IsPunished      = function(self, f) return (self.Info.Punishment:Is(f))  end
    hClient.SetBanned       = function(self, mode) self.Info.Punishment.WasBanned = mode  end
    hClient.WasBanned       = function(self) return (self.Info.Punishment.WasBanned)  end

    hClient.Revive          = function(self, pos, ang, noforce, equiplist) if (pos) then self.RevivePosition = checkVec(pos, vector.modifyz(self:GetPos(), 0.25)) self.ReviveAngles = checkVec(ang, self:GetAngles()) end g_gameRules:RevivePlayer(self:GetChannel(), self, (not noforce), (not noforce), equiplist) self.RevivePosition = nil self.ReviveAngles = nil  end
    hClient.Localize        = function(self, locale, format) return TryLocalize(locale, self:GetPreferredLanguage(), format) end
    hClient.LocalizeEx      = function(self, locale, format) return LocalizeForClient(self, locale, format) end
    hClient.LocalizeNest    = function(self, locale, ...) return LocalizeNestForClient(self, locale, ...) end

    hClient.SetMute         = function(self, info) self.Info.MuteInfo = info end
    hClient.RemoveMute      = function(self) self.Info.MuteInfo = nil end
    hClient.IsMuted         = function(self) return self.Info.MuteInfo ~= nil end
    hClient.GetMuteReason   = function(self) if (not self:IsMuted()) then return end return self.Info.MuteInfo:GetReason() end
    hClient.GetMuteExpiry   = function(self) if (not self:IsMuted()) then return end return self.Info.MuteInfo:GetRemainingTime() end
    hClient.GetMuteAdmin    = function(self) if (not self:IsMuted()) then return end return self.Info.MuteInfo:GetAdmin() end
    hClient.GetMute         = function(self) if (not self:IsMuted()) then return end return self.Info.MuteInfo end

    -- LOOOONGS
    hClient.IsInventoryEmpty     = function(self, count) return (table.count(self.inventory:GetInventoryTable()) <= (count or 0)) end
    hClient.SetPreferredLanguage = function(self, sLang) self.Info.Language.Preferred = sLang self:SetData(ePlayerData_PreferredLang, sLang) end
    hClient.GetPreferredLanguage = function(self) return self.Info.Language.Preferred end
    hClient.GetHitAccuracy       = function(self) return self.Info.HitAccuracy:Get() end
    hClient.RefreshHitAccuracy   = function(self) return self.Info.HitAccuracy:Refresh() end
    hClient.UpdateHitAccuracy    = function(self, t) if (t == eHitAccuracy_OnShot) then self.Info.HitAccuracy:OnShot() elseif (t == eHitAccuracy_OnHit) then self.Info.HitAccuracy:OnHit() end end
    hClient.HitAccuracyExpired   = function(self) return self.Info.HitAccuracy:Expired() end

    -- TODO
    hClient.GetSpawnLocation     = function(self, id) return self.Info.SpawnLocations[(id or "default")]  end
    ----------------------------------------------------------
    -- Server does not need the functions and statements below
    if (bServer) then
        return ServerLog("Server Initialized")
    end

    ------------

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

                        -- Language Perferrence!
                        local sPreferred = self:GetData(ePlayerData_PreferredLang)
                        if (sPreferred) then
                            self:SetPreferredLanguage(sPreferred)
                        end
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


---------------------------
PlayerHandler.ListPlayers = function(self, hUser, hIndex)

    local aPlayers = GetPlayers()
    local hInfoTarget = aPlayers[hIndex or -1]
    if (hInfoTarget) then
        return self:PlayerInfo(hUser, hInfoTarget)
    end


    local iBoxWidth = CLIENT_CONSOLE_LEN
    local sAccess, sIP, sProfile, iChannel, sPort, sHost, sCountry, sAccount, sTeam, sName

    SendMsg(MSG_CONSOLE_FIXED, hUser, string.format("$9%s", string.rep("=", iBoxWidth)))
    SendMsg(MSG_CONSOLE_FIXED, hUser, string.format("$9%s", "$9 #     Slot  Name                  Team  Access       ID        CC IP               Port    Host    "));

    local iCounter = 0
    for _, hTarget in ipairs(aPlayers) do
        iCounter = iCounter + 1

        sTeam = GetTeamName(hTarget:GetTeam(), "None")
        if (g_gameRules.IS_IA) then if (hTarget:IsSpectating()) then sTeam = "$9SPEC" else sTeam = "$5INGM" end
        end

        local iRank = hTarget:GetAccess()

        sAccess 	= string.format("%s%s", GetRankColor(iRank), GetRankName(iRank))
        sIP 		= checkVar(hTarget:GetIP(), 		string.UNKNOWN)
        sProfile 	= checkVar(hTarget:GetProfile(), 	string.UNKNOWN)
        iChannel 	= checkVar(hTarget:GetChannel(),	string.UNKNOWN)
        sPort 		= checkVar(hTarget:GetPort(), 		string.UNKNOWN)
        sHost 		= checkVar(hTarget:GetHostName(),	string.UNKNOWN)
        sCountry 	= checkVar(hTarget:GetCountryCode(),string.UNKNOWN)
        sName 		= string.sub(hTarget:GetName(), 0, 21)

        SendMsg(MSG_CONSOLE_FIXED, hUser, string.format("$9 $1%s$9  ($1%s$9) $1%s $9%s $9(%s $9: $4%s$9) <$8%s$9>$8%s $9($4%s $9: $1%s$9)]",
                string.rspace(iCounter, 3, string.COLOR_CODE),
                string.rspace(iChannel, 4, string.COLOR_CODE),
                string.rspace(sName, 21, string.COLOR_CODE),
                string.rspace(sTeam, 4, string.COLOR_CODE),
                string.rspace(sAccess, 10, string.COLOR_CODE),
                string.rspace(sProfile, 7, string.COLOR_CODE),
                string.rspace(sCountry, 2, string.COLOR_CODE),
                string.rspace(sIP, 15, string.COLOR_CODE),
                string.rspace(sPort, 5, string.COLOR_CODE),
                string.rspace(sHost, 19, string.COLOR_CODE)
        ))
    end
    SendMsg(MSG_CONSOLE_FIXED, hUser, string.format("$9%s", string.rep("=", iBoxWidth)))

end

---------------------------
PlayerHandler.PlayerInfo = function(self, hUser, hTarget)

    local iTimestamp    = GetTimestamp()

    local sName         = hTarget:GetName()
    local iAccess       = hTarget:GetAccess()
    local sAccess 		= string.format("%s%s (%d)", GetRankColor(iAccess), GetRankName(iAccess), iAccess)
    local sIP 			= checkVar(hTarget:GetIP(), 		    string.UNKNOWN)
    local sProfile 		= string.format("%d (%s)", hTarget:GetProfile(), hTarget:GetAccountName())
    local iChannel 		= hTarget:GetChannel()
    local sHost 		= hTarget:GetHostName()
    local sPort 		= hTarget:GetPort()
    local sCountry 		= hTarget:GetCountry()
    local sLang 		= string.format("%s (%s)", hTarget:GetLanguage(), hTarget:GetPreferredLanguage())
    local sTSession     = math.calctime(hTarget.InitTimer.diff())
    local sTServer      = math.calctime(hTarget:GetData(ePlayerData_GameTime) or 0)
    local sLastSeen     = math.calctime(iTimestamp - (hTarget:GetData(ePlayerData_LastVisit) or 0))
    local sClient       = hTarget:GetMPClient(eMPClient_Version) or "N/A"
    local sSvClient     = hTarget:GetClientMod(eSvClient_Version) or "N/A"


    local iSpace = 84

    ------------------
    SendMsg(CONSOLE, hUser, " ")
    SendMsg(CONSOLE, hUser, "$9===== [ $5LOOKUP$9 ] ===============================================================================================")
    SendMsg(CONSOLE, hUser, "$9[                  Name : $5" .. string.rspace(sName,		 iSpace, string.COLOR_CODE)		.. " $9]")
    SendMsg(CONSOLE, hUser, "$9[                  Rank : $5" .. string.rspace(sAccess,		 iSpace, string.COLOR_CODE)		.. " $9]")
    SendMsg(CONSOLE, hUser, "$9[               Profile : $4" .. string.rspace(sProfile,		 iSpace, string.COLOR_CODE)		.. " $9]")
    SendMsg(CONSOLE, hUser, "$9[                    IP : $1" .. string.rspace(sIP,	    	 iSpace, string.COLOR_CODE)		.. " $9]")
    SendMsg(CONSOLE, hUser, "$9[               Country : $1" .. string.rspace(sCountry,		 iSpace, string.COLOR_CODE)		.. " $9]")
    SendMsg(CONSOLE, hUser, "$9[              Language : $1" .. string.rspace(sLang,		 iSpace, string.COLOR_CODE)		.. " $9]")
    SendMsg(CONSOLE, hUser, "$9[                  Host : $1" .. string.rspace(sHost,		 iSpace, string.COLOR_CODE)		.. " $9]")
    SendMsg(CONSOLE, hUser, "$9[                  Port : $1" .. string.rspace(sPort,		 iSpace, string.COLOR_CODE)		.. " $9]")
    SendMsg(CONSOLE, hUser, "$9[               Channel : $4" .. string.rspace(iChannel,		 iSpace, string.COLOR_CODE)		.. " $9]")
    SendMsg(CONSOLE, hUser, "$9[          Session Time : $4" .. string.rspace(sTSession,	 iSpace, string.COLOR_CODE)		.. " $9]")
    SendMsg(CONSOLE, hUser, "$9[           Server Time : $4" .. string.rspace(sTServer,		 iSpace, string.COLOR_CODE)		.. " $9]")
    SendMsg(CONSOLE, hUser, "$9[          Last Connect : $4" .. string.rspace(sLastSeen,     iSpace, string.COLOR_CODE)		.. " $9]")
    SendMsg(CONSOLE, hUser, "$9[                Client : $1" .. string.rspace(sClient,		 iSpace, string.COLOR_CODE)		.. " $9]")
    SendMsg(CONSOLE, hUser, "$9[         Server Client : $1" .. string.rspace(sSvClient,	 iSpace, string.COLOR_CODE)		.. " $9]")
    SendMsg(CONSOLE, hUser, "$9================================================================================================ [ $5LOOKUP$9 ] ====")
end