------------------
PlayerHandler = (PlayerHandler or {

    CachedInfo = {},
    PlayerData = {},

    DataDir  = (SERVER_DIR_DATA .. "PlayerData\\"),
    DataFile = "PlayerData.lua"

})

------------------

TIMER_CREATE = false
NO_REFRESH = false
CHECK_ONLY = true

------------------

ePlayerData_All             = 0
ePlayerData_LastVisit       = "last_visit"
ePlayerData_GameTime        = "play_time"
ePlayerData_PlayTime        = "game_time"
ePlayerData_LastName        = "last_name"
ePlayerData_Equipment       = "equipment"
ePlayerData_PreferredLang   = "language"
ePlayerData_CM              = "last_cm"
ePlayerData_CMHead          = "last_cm_head"

ePlayerData_ConsecutiveVoteKicks = "vote_kicked_count"
ePlayerData_LastKickVote         = "last_kick_vote"
ePlayerData_LastVoteKicked       = "last_kicked_by_vote"

ALL_PLAYERS = 0

------------------

eAllowedEquip_Default   = -1 -- allow all?
eAllowedEquip_None      = 0 -- NONE allowed
eAllowedEquip_All       = 1 -- all allowed
eAllowedEquip_List      = 2 -- checks list

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
ePlayerTimer_ClientInstall      = 2
ePlayerTimer_Firing             = 3

------------------

eGodMode_None       = 0
eGodMode_Normal     = 1
eGodMode_Extended   = 2 -- + testing mode
eGodMode_Ultra      = 3 -- + special stuff

------------------
-- Synced Client Keys

PLAYERKEY_GODSTATUS = 500

------------------

g_PlayerRayTable = {}

------------------
PlayerHandler.Init = function(self)

    --- Link Event (because they are out of order, we need to call this one manually.)
    --EventLink(eServerEvent_OnScriptReload, "PlayerHandler", "SavePlayerData")
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

    local iTimestamp      = GetTimestamp()
    local iDeletionPeriod = ConfigGet("General.PlayerData.DeleteAfter", -1, eConfigGet_Number)
    if (iDeletionPeriod > 0) then
        for _, aInfo in pairs(aData) do
            if ((iTimestamp - (aInfo[ePlayerData_LastVisit] or iTimestamp)) >= iDeletionPeriod) then
                ServerLog("Deleting Data from %s (Not connected for %s)", _, math.calctime(iDeletionPeriod))
                aData[_] = nil
            end
        end
    end

    self.PlayerData = aData
end

-------------------
PlayerHandler.SaveFile = function(self)

    -- moved to load file..
    local aCleaned = (self.PlayerData or {})
    if (not ConfigGet("General.PlayerData.SaveData", true, eConfigGet_Boolean)) then
        return ServerLog("Not saving data..")
    end

    local sData = string.format("return %s", (table.tostring(aCleaned, "", "") or "{}"))
    local sFile = (self.DataDir .. self.DataFile)

    local bOk, sErr = FileOverwrite(sFile, sData)
    if (not bOk) then

        HandleError("Error saving File %s (%s)", self.DataFile, sErr)
        ServerLogError("Failed to open file %s for writing", sFile)
    end

    ServerLog("File Saved.")
end

------------------
PlayerHandler.OnClientDisconnect = function(self, hClient, bNoSave, bQuiet, bReload)

    hClient:SetData(ePlayerData_LastName, nil)
    hClient:SetData(ePlayerData_LastVoteKicked, nil)
    hClient:SetData(ePlayerData_LastVisit, GetTimestamp())

    local sName = hClient:GetName()

    if (not ServerNames:IsNomad(sName)) then hClient:SetData(ePlayerData_LastName, sName) end
    if (hClient.VoteKicked) then hClient:SetData(ePlayerData_LastVoteKicked, GetTimestamp()) end

    local sID   = hClient:GetProfileID()
    if (not hClient:IsValidated()) then
        ServerLog("Client didnt validate, discarding data...")
        return
    end
    local aData = hClient:GetStoredData()

    ServerLog("============================================= [ OLD ] ====================================")
    ServerLog(table.tostring(self.PlayerData[sID]))
    ServerLog("============================================= [ NEW ] ====================================")
    ServerLog(table.tostring(aData))
    self.PlayerData[sID] = aData--table.merge({}, aData)
    if (not bNoSave) then
        self:SaveFile()
    end

    --Debug(">>>>>>>>>>>> CALL EVENT. NOW!")
    CallEvent(eServerEvent_SavePlayerData, hClient, bQuiet, bReload)

end

------------------
PlayerHandler.SavePlayerData = function(self)

    for _, hClient in pairs(GetPlayers() or {}) do
        ServerLog("FOR CLIENT %s",hClient:GetName())
        self:OnClientDisconnect(hClient, true, true, true)
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
    ServerLog("Cached Info: %s",table.tostring(aInfo))
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

    local bServer = false

    if (iChannel == SERVERENT_CHANNEL) then
        sChannelName = MOD_NAME
        sHostName    = MOD_NAME
        sPort        = 6969
        sIP          = "127.0.0.1"
        iDefRank     = GetHighestRank()
        bServer      = true
    end

    self.CachedInfo[iChannel] = {

        -- Client Profile Validated?
        Validated   = false,
        Validating  = false,

        StaticID    = nil, -- sent by client
        HWID        = nil, -- sent by client
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
        Commands = {
            Timers       = {},
            TimerExpired = function(this, id) local t = this.Timers[id] if (not t) then return true end return t.expired() end,
            TimerRefresh = function(this, id, expiry) local t = this.Timers[id] if (not t) then self.Timers[id] = timernew(expiry) end return t.refresh(expiry) end
        },

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
            Expired = function(this, id, seconds, refresh, check_only) if (this.Timers[id] == nil) then if (not check_only) then this.Timers[id] = timernew(seconds) end return true end if (this.Timers[id].expired(seconds)) then if (refresh) then this.Timers[id].refresh() end return true end return false end,
            Refresh = function(this, id, newseconds, f) if (not id) then return throw_error("No timer ID specified!") end if (not this.Timers[id]) then if (not f) then return end this.Timers[id] = timernew(newseconds) end this.Timers[id].refresh(newseconds) end,
            Diff    = function(this, id) if (not id) then return throw_error("No timer ID specified!") end if (not this.Timers[id]) then return 0 end return this.Timers[id].diff() end,
            Expiry  = function(this, id) if (not id) then return throw_error("No timer ID specified!") end if (not this.Timers[id]) then return 0 end return this.Timers[id].getexpiry() end
        },

        ----------
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
        -- bad indexing here.. someone rewrite!
        IPData = {

            Data = {},
            Default = ServerChannels:GetDefaultData(),

            Set             = function(x, y) x.Info.Data = y end,
            GetCountry      = function(x) local f = (x.Info.IPData.Data or {}) return (f["Country"] or f["country"] or x.Info.IPData.Default.Country) end,
            GetCountryCode  = function(x) local f = (x.Info.IPData.Data or {}) return (f["isocode"] or f["CountryCode"] or f["countryCode"] or x.Info.IPData.Default.CountryCode) end
        },

        ----------
        -- bad indexing here.. someone rewrite!
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
        GodMode = {

            Superman   = 0,
            GodStatus  = (bServer and 3 or 0),
            TestStatus = (bServer and 3 or 0),

            SetGod     = function(this, level) this:SetTesting(0) this.GodStatus = level if (level > 1) then this:SetTesting(1) end end,
            IsGod      = function(this, level) local g = this.GodStatus if (level) then return g >= level end return (g or 0) > 0 end,
            IsTesting  = function(this, level) local t = this.TestStatus if (level) then return t >= level end return (t or 0) > 0 end,
            SetTesting = function(this, level) this.TestStatus = level end,
            IsSuperman = function(this, level) level = (level or 1) return (this:IsTesting() or this:IsGod(level + 2) or this.Superman >= level) end,
            SetSuperman= function(this, level) this.Superman = level or 0 end,

        },

        ----------
        Language = {
            Language  = "default",
            Preferred = "default"
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
        ReviveRules = {
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
        AllowedEquip = {

            List    = {},
            Status  = eAllowedEquip_All,
            Reason  = "You're not Allowed to use ${weapon}",
            Default = "You're not Allowed to use ${weapon}",

            Allowed     = function(this, class) if (this.Status == eAllowedEquip_All or this.Status == eAllowedEquip_Default) then return true end if (this.Status == eAllowedEquip_None) then return false end return table.findv(this.List, class) end,
            Set         = function(this, list, msg) if (isNumber(list)) then this.Status = list else this.Status = eAllowedEquip_List this.List = list end this.Reason = this.Default or msg end,
            Get         = function(this) return this.List end,
            GetReason   = function(this) return this.Reason end,
            SetReason   = function(this, msg) this.Reason = msg end
        },

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

    local aKeys = {
        [PLAYERKEY_GODSTATUS] = 0,
    }

    for iKey, hDef in pairs(aKeys) do
        if (g_pGame:GetSynchedEntityValue(hClient.id, iKey) == nil) then
            g_pGame:SetSynchedEntityValue(hClient.id, iKey, hDef)
        end
    end

    hClient.CommandTimers = {}

    hClient.IsPlayer  = (not bServer)
    hClient.IsServer  = (bServer)
    hClient.Info      = PlayerHandler:GetClientInfo(iChannel)
    hClient.Info.ChannelID = hClient.actor and hClient.actor:GetChannel() or 0

    -- FIXME
    hClient.IsLagging       = function(self) return false end --self.actor:IsFlying()  end
    hClient.IsFlying        = function(self) return self.actor:IsFlying()  end
    hClient.IsIndoors       = function(self) return IsPointIndoors(self:GetPos())  end
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
    hClient.GetVehicleSeat  = function(self) local c = self:GetVehicle() if (not c) then return end return c:GetSeat(self.id) end -- NOT synched
    hClient.GetVehicleSeatId= function(self) local c = self:GetVehicleSeat()if (not c) then return end return c.seatId end -- NOT synched

    hClient.SetAllowedEquip = function(self, list, msg) return self.Info.AllowedEquip:Set(list,msg) end -- NOT synched
    hClient.GetAllowedEquip = function(self) return self.Info.AllowedEquip:Get() end -- NOT synched
    hClient.IsAllowedEquip  = function(self, class) return self.Info.AllowedEquip:Allowed(class) end -- NOT synched
    hClient.GetEquipReason  = function(self) return self.Info.AllowedEquip:GetReason() end -- NOT synched

    hClient.CreateHit = function(self, aInfo)

        local hCurrent = self:GetCurrentItem()
        local hTarget = aInfo.Target or self
        local hShooter = aInfo.Shooter or self
        local hWeapon = aInfo.Weapon or self

        local hTargetId = hTarget and hTarget.id
        local hShooterId = hShooter and hShooter.id
        local hWeaponId = hWeapon and hWeapon.id

        local iDamage = aInfo.Damage or 100
        local iRadius = aInfo.Radius or 0

        local iMaterialID = 0
        if (aInfo.Material) then
            iMaterialID = g_pGame:GetHitMaterialId(aInfo.Material)
        end

        local iPart = aInfo.Part or -1
        local iTypeID = 0
        if (aInfo.Type) then
            iTypeID = g_pGame:GetHitTypeId(aInfo.Type)
        else
            iTypeID = g_pGame:GetHitTypeId("normal")
        end

        local vPos = aInfo.Pos or hTarget:GetPos()
        local vDir = aInfo.Dir or self:SmartGetDir()
        local vNormal = aInfo.Normal or vDir

        g_pGame:ServerHit(hTargetId, hShooterId, hWeaponId, iDamage, iRadius, iMaterialID, iPart, iTypeID, vPos, vDir, vNormal)
    end

    hClient.Distance = function(self, hTargetID)

        local vPos = self:GetPos()
        local hTarget = GetEntity(hTargetID)
        if (not hTarget) then
            return 0
        end

        return vector.distance(hTarget:GetPos(), vPos)
    end
    hClient.GetHitPos = function(self, iDist, iTypes, vDir, vPos)
        iTypes = iTypes or ent_all
        iDist = iDist or 5

        local iPosP = 0
        if (iDist < 0) then
            iDist = iDist * -1
            if (iDist < 1) then iPosP = (1 - iDist) iDist = 1 end
            vDir = vector.scale(vector.neg(vDir or self:SmartGetDir(1)), iDist)
        else
            if (iDist < 1) then iPosP = (1 - iDist) iDist = 1 end
            vDir = vector.scale(vDir or self:SmartGetDir(1), iDist)
        end

        vPos = (vPos or self:GetHeadPos())
        if (iPosP > 0) then
            vPos = vector.add(vPos, vector.scale(vector.neg(vDir), iPosP))
            --SpawnEffect(ePE_Flare,vPos,g_Vectors.up,0.1)
        end

        --Debug("req1=",iDist)
        --Debug("req2=",vDir)
        --Debug("req3=",iPosP)

        --SpawnEffect(ePE_Flare,vPos,vDir,0.1)

        local nIgnore = (self:GetVehicleId() or self.id)
        local iHits = (ServerDLL.RayWorldIntersection or Physics.RayWorldIntersection)(vPos, vDir, 1, iTypes, self.id, self:GetVehicleId(), g_PlayerRayTable)
        local aHit = g_PlayerRayTable[1]
        if (iHits and iHits > 0) then
            aHit.surfaceName = System.GetSurfaceTypeNameById( aHit.surface )
            return aHit
        end
        return
    end
    hClient.IsSwimming          = function(self) return self:IsUnderwater(1) or self:GetStance(STANCE_SWIM)  end
    hClient.IsUnderground       = function(self, iThreshold) return ServerUtils.IsEntityUnderground(self, iThreshold)  end
    hClient.IsUnderwater        = function(self, iThreshold) return ServerUtils.IsEntityUnderwater(self, iThreshold)  end
    hClient.GetFacingPos        = function(self, iFace, iDistance, iFollowType, t, t2) return GetFacingPos(self, iFace, iDistance, iFollowType, t, t2)  end
    hClient.GetHeadPos          = function(self) return self.actor:GetHeadPos() end
    --hClient.GetBonePos          = function(self, bone) return self:GetBonePos(bone) end
    hClient.GetHeadDir          = function(self) return self.actor:GetHeadDir()  end
    hClient.GetViewPoint        = function(self, dist) return (self.actor:GetLookAtPoint(dist or 9999))  end
    hClient.SvMoveTo            = function(self, pos, ang) self:SetInvulnerability(5) local v = self:GetVehicle() if (v) then v:SetWorldPos(pos) return end g_pGame:MovePlayer(self.id, vector.modifyz(pos, 0.25), (ang or self:GetWorldAngles()))  end
    hClient.SetInvulnerability  = function(self, time) g_pGame:SetInvulnerability(self.id, true, (time or 2.5)) end
    hClient.GetSpectatorDir     = function(self) return (self.actor:GetLookDirection() or self.PseudoDirection or vector.make()) end
    hClient.GetVehicleDir       = function(self) return (self.actor:GetVehicleViewDir()) end
    hClient.SmartGetDir         = function(self, dv) if (self:IsSpectating()) then return self:GetSpectatorDir() elseif (self:GetVehicleId()) then return self:GetVehicleDir()end return (dv and self:GetDirectionVector() or self.actor:GetLookDirection() or self:GetHeadDir()) end
    hClient.GetLean             = function(self, dir) local d = self.actor:GetLean() if (dir) then return d == dir end return d end
    hClient.IsIdle              = function(self, time) return self.Info.IdleTimer.expired(time or 5) end
    hClient.GetStance           = function(self, check) local s = self.actorStats.stance if (check) then return s==check end return s end

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
    hClient.SetHWID         = function(self, id) self.Info.HWID = id end
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
    hClient.GetElevatedAccess = function(self, min, max) local r = self.Info.Rank.ID min = min or RANK_MODERATOR max = max or RANK_OWNER r = r + 1 if (r > max) then r = max end if (r < min) then r = min end return r end
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

    hClient.SetSuperman     = function(self, level) return self.Info.GodMode:SetSuperman(level) end
    hClient.IsSuperman      = function(self, level) return self.Info.GodMode:IsSuperman(level) end
    hClient.HasGodMode      = function(self, level) return self.Info.GodMode:IsGod(level) end
    hClient.SetGodMode      = function(self, level) self.Info.GodMode:SetGod(level) self.actor:SetGodMode(level) self:Tick() g_pGame:SetSynchedEntityValue(self.id, PLAYERKEY_GODSTATUS, (level or 0))  end
    hClient.IsTesting       = function(self, level) return self.Info.GodMode:IsTesting(level) end
    hClient.SetTesting      = function(self, level) self.Info.GodMode:SetTesting(level) end

    hClient.GetTeam         = function(self) return (g_pGame:GetTeam(self.id)) end
    hClient.GetTeamName     = function(self, neutral) return GetTeamName(g_pGame:GetTeam(self.id), neutral) end
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
    hClient.PayPrestige     = function(self, pp, msg) local have = self:GetPrestige() if (have < pp) then return false, (pp - have) end self:AwardPrestige(-pp, msg) return true, 0 end
    hClient.AddPrestige     = function(self, pp, reason) self:SetPrestige(self:GetPrestige() + pp)
        if (reason) then
            self:SendPPMsg((pp > 0 and "+" or "") .. pp .. " PP", reason)
        end end -- TODO: ClientMod()
    hClient.AwardPrestige   = function(self, pp, reason) g_gameRules:AwardPPCount(self.id, pp, nil, self:HasClientMod())
        if (reason) then
            self:SendPPMsg((pp > 0 and "+" or "") .. pp .. " PP", reason)
        end end -- TODO: ClientMod()
    hClient.SendPPMsg         = function(self, pp, msg) if (self:HasClientMod()) then self:Execute(string.format("g_Client.Event(eEvent_BLE, eBLE_Currency,\"%s ( %s )\")", self:LocalizeNest(msg), pp))end end -- TODO: ClientMod()
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
    hClient.SetClientMod    = function(self, data, value) self.Info.ClientMod[data] = value end

    -- mp
    hClient.GetMPClient     = function(self, data) if (data) then return self.Info.MPClientMod[data] end return self.Info.MPClientMod end

    --> Timers
    hClient.GetBuyCooldown  = function(self, id) return self.Info.Buying:Get(id) end
    hClient.OnBuyCooldown   = function(self, id, seconds) return self.Info.Buying:IsOn(id, seconds) end
    hClient.SetBuyCooldown  = function(self, id) return self.Info.Buying:Set(id) end
    hClient.TimerExpired    = function(self, id, seconds, refresh, check_only) return self.Info.Timers:Expired(id, seconds, refresh, check_only) end
    hClient.TimerRefresh    = function(self, id, newseconds) return self.Info.Timers:Refresh(id, newseconds) end
    hClient.TimerDiff       = function(self, id) return self.Info.Timers:Diff(id) end
    hClient.TimerExpiry     = function(self, id) return self.Info.Timers:Expiry(id) end

    hClient.VoteKicked      = function(self, admin, msg) ServerPunish:DisconnectPlayer(eKickType_Kicked, self, (msg or "No Reason Specified"), nil, admin or "Server") end

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
    hClient.GetCurrentItemClass = function(self) local c =  self.inventory:GetCurrentItem() return c and c.class end
    hClient.GetItemByClass  = function(self, class) local h = self.inventory:GetItemByClass(class) return GetEntity(h) end
    hClient.HasItem         = function(self, class) return self.inventory:GetItemByClass(class) end
    hClient.GetItem         = function(self, class) return self.inventory:GetItemByClass(class) end
    hClient.RemoveItem      = function(self, class) local id = self.inventory:GetItemByClass(class) if (id) then self.inventory:RemoveItem(id) end end
    hClient.GiveItem        = function(self, class, noforce) self.actor:SetActorMode(ACTORMODE_UNLIMITEDITEMS, 1) if (class == "Parachute") then self:RemoveItem("Parachute") end local i = ItemSystem.GiveItem(class, self.id, (not noforce))self.actor:SetActorMode(ACTORMODE_UNLIMITEDITEMS, 0) return i end
    hClient.GiveItemPack    = function(self, pack, noforce) return ItemSystem.GiveItemPack(self.id, pack, (not noforce)) end
    hClient.SelectItem      = function(self, class) return self.actor:SelectItemByNameRemote(class) end
    hClient.GetEquipment    = function(self) local a = self.inventory:GetInventoryTable() local e for i, v in pairs(a) do local x = GetEntity(v) if (x and x.weapon) then if (e == nil) then e = {} end table.insert(e, { x.class, table.it(x.weapon:GetAttachedAccessories(), function(ret, index, val) local class = GetEntity(val) if (ret == nil) then return { class }  end table.insert(ret, class) end) }) end end return e end
    hClient.GetInventory    = function(self) local a = self.inventory:GetInventoryTable() local n = {} for _,id in pairs(a or {}) do table.insert(n,GetEntity(id)) end return n end
    hClient.SetActorMode    = function(self, m, v) self.actor:SetActorMode(m,v) end
    hClient.GetActorMode    = function(self, m) return self.actor:GetActorMode(m) end

    hClient.IsPunished      = function(self, f) return (self.Info.Punishment:Is(f))  end
    hClient.SetBanned       = function(self, mode) self.Info.Punishment.WasBanned = mode  end
    hClient.WasBanned       = function(self) return (self.Info.Punishment.WasBanned)  end

    hClient.Revive          = function(self, pos, ang, noforce, equiplist) if (pos) then self.RevivePosition = checkVec(pos, vector.modifyz(self:GetPos(), 0.25)) self.ReviveAngles = checkVec(ang, vector.toang(self:SmartGetDir())) end g_gameRules:RevivePlayer(self:GetChannel(), self, (not noforce), (not noforce), equiplist) self.RevivePosition = nil self.ReviveAngles = nil  end
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
    hClient.HasUnlimitedAmmo     = function(self) return self:HasGodMode(eGodMode_Extended) end
    hClient.IsInventoryEmpty     = function(self, count) return (table.count(self.inventory:GetInventoryTable()) <= (count or 0)) end
    hClient.SetPreferredLanguage = function(self, sLang) self.Info.Language.Preferred = sLang self:SetData(ePlayerData_PreferredLang, sLang)
        Logger:LogEventTo(RANK_MODERATOR, eLogEvent_Game, "@l_ui_changedLang", self:GetName(), sLang)
    end
    hClient.GetPreferredLanguage = function(self) return self.Info.Language.Preferred end
    hClient.GetHitAccuracy       = function(self) return self.Info.HitAccuracy:Get() end
    hClient.RefreshHitAccuracy   = function(self) return self.Info.HitAccuracy:Refresh() end
    hClient.UpdateHitAccuracy    = function(self, t) if (t == eHitAccuracy_OnShot) then self.Info.HitAccuracy:OnShot() elseif (t == eHitAccuracy_OnHit) then self.Info.HitAccuracy:OnHit() end end
    hClient.HitAccuracyExpired   = function(self) return self.Info.HitAccuracy:Expired() end

    -- TODO
    hClient.AddInstantRevive     = function(self, id, p) self.Info.ReviveRules[id] = p  end
    hClient.HasInstantRevive     = function(self, id)
        local bOk
        for _, f in pairs(self.Info.ReviveRules) do
            if ((isFunc(f) and f(self)) or false) then
                bOk = true
            end
        end
        return bOk
    end
    hClient.AddSpawnLocation     = function(self, id, info) self.Info.SpawnLocations[id] = info  end
    hClient.GetSpawnLocation     = function(self, id)
        local vPos, vAng
        local fCb
        local iMax = 0
        for i, aLocation in pairs(self.Info.SpawnLocations) do
            if ((id ~= nil and i == id) or ((aLocation.Check == nil or (aLocation.Check(aLocation, self)) == true) and (aLocation.Priority or 0) >= iMax)) then

                vPos, vAng=
                aLocation.Pos,
                aLocation.Ang or aLocation.Dir

                iMax = (aLocation.Priority or 0)
                fCb = aLocation.OnUsed
            end
        end

        if (fCb) then
            fCb(self)
        end
        return vPos, vAng
    end
    hClient.GetEntitiesInFront   = function(self, ...) return ServerUtils.GetEntitiesInFront(self, ...)  end
    hClient.IsObjectInFront      = function(self, dist) local aHit = self:RayHit(dist) if (not aHit) then return false end return true end
    hClient.RayHit      = function(self, dist, ents, flags)

        local iHits = Physics.RayWorldIntersection(self:GetHeadPos(), vector.scale(self:GetHeadDir(), (dist or 5)), 1, ents, self.id, nil,g_PlayerRayTable)
        if (iHits > 0) then
            return g_PlayerRayTable[1]
        end
        return
    end
    ----------------------------------------------------------
    -- Server does not need the functions and statements below
    if (bServer) then
        return ServerLog("Server Initialized")
    end

    ------------

    hClient.OnShoot = function(self, aShotInfo)

        local hWeapon = aShotInfo.Weapon
        if (self:HasUnlimitedAmmo()) then
            Script.SetTimer(1, function()
                ServerItemHandler:RefillAmmo(self, hWeapon)
            end)
        end
    end

    ------------

    hClient.Tick = function(self)

        local hVehicle   = self:GetVehicle()
        local bHasClient = self:HasClientMod()
        local sGodColor  = "orange"
        if (self:HasGodMode()) then

            self:SetEnergy(199)
            self:SetEnergy(200)
            self:SetInvulnerability()
            if (self:IsDead() and not self:IsSpectating()) then
                self:Revive(1, 1)
            end
            if (bHasClient and self.ClientTemp.SLHColor == nil) then

                --self.ClientTemp.SLHColor = sGodColor
                --ClientMod:OnAll(string.format([[g_Client:AddSLH(%d,"%s",true)]], self:GetChannel(), sGodColor), {
                --    Sync = true,
                --    SyncID = "GodModeSLH",
                --    BindID = self.id
                --})
                --Debug("add slh")
            end
        elseif (false) then --(bHasClient and g_pGame:GetSynchedEntityValue(self.id, PLAYERKEY_GODSTATUS) > 0) then
            --ClientMod:OnAll(string.format([[g_Client:AddSLH(%d,nil,false)]], self:GetChannel()))
            --ClientMod:StopSync(self, "GodModeSLH")
            --self.ClientTemp.SLHColor = nil
            Debug("remove slh")
        end

        --Debug(self.ClientTemp.SLHColor , sGodColor)

        local sCountry = self:GetCountry()
        local sAutoLang = ServerChannels:CountryToLanguage(sCountry)
        --Debug(sCountry,"===",sAutoLang)
        if (not self.WantNoLanguage and self:GetPreferredLanguage() == NO_LANGUAGE and table.findv(AVAILABLE_LANGUAGES, sAutoLang) and sAutoLang ~= NO_LANGUAGE) then

            self:SetPreferredLanguage(sAutoLang)
            Script.SetTimer(5000, function()
                --(${2}: Language Auto-Set to ${1} (Use !Language to Change))
                SendMsg(CHAT_SERVER, self, self:Localize("@l_ui_languageAutoSet", { string.capitalN(sAutoLang), sCountry }))
            end)
        end

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
                        ServerLog("Assigned data %s",table.tostring(table.merge(aData, self:GetStoredData(), true)))
                        self:SetStoredData(table.merge(aData, self:GetStoredData(), true))
                        self:SetDataLoaded(true)

                        -- Language Perferrence!
                        local sPreferred = self:GetData(ePlayerData_PreferredLang)
                        if (sPreferred) then
                            self:SetPreferredLanguage(sPreferred)
                        end
                    end
                end

                --self.CM.Restored = false--test!
                local iCM = self:GetData(ePlayerData_CM)
                if (self:HasClientMod() and not self.CM.Restored and iCM ~= nil and iCM ~= CM_NONE) then

                    -- dont restore if dead, causes strange bug. although its only temporary, still annoying ;)
                    if (self:IsAlive() or self:IsSpectating()) then
                        ClientMod:RequestModel(self, iCM, true)
                        self.CM.Restored = true
                        -- Debug("restore CM!")
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

        -- =================================================

        if (hVehicle) then
           -- local bCargo
           -- if (hVehicle.CMID == VM_TRANSPLANER) then

           -- end
           -- if (not bCargo) then
           --     hVehicle.TransCargoID = nil
           -- end

        elseif (not self:IsSpectating()) then
            if (not self:IsSwimming() and self:IsFlying() and not self:IsIndoors() and self:IsUnderground(20)) then
                self:SvMoveTo(self:GetFacingPos(eFacing_Front, 0, eFollow_Auto), self:GetAngles())
                Debug("fixed pos??")
            end
        end

        -- =================================================
        if (ClientMod) then ClientMod:ClientTick(self) end

        self.LastTick.refresh()
    end

    hClient.Update = function(self)

        if (DebugMode()) then
            ServerLog("%f (%f)", ServerStats.SERVER_RATE-self.FrameTick.diff(), ServerStats.SERVER_RATE)
        end

        ---------------------------
        -- Update World Dir (kinda)
        local vPos      = self:GetWorldPos()
        local vLast      = self.LastPosition
        local vPseudoDir = self.LastDirection

        if (vLast and vector.distance(vPos, vLast) > 0) then
            vPseudoDir = vector.getdir(vPos, vLast, 1)
        end

        self.PseudoDirection = vPseudoDir
        self.LastPosition    = vPos

        self.Info.IdleTime = (self.Info.IdleTime or 0) + System.GetFrameTime()
        if (vector.length(self:GetVelocity()) > 0) then
            self.Info.IdleTimer.refresh()
            self.Info.IdleTime = 0
        end

        if (self:HasClientMod()) then
            ClientMod:UpdateClient(self)
        end

        local hVehicle = self:GetVehicle()
        local hItem = self:GetCurrentItem()

        if (hItem) then
            self:UpdateFiringInfo(hItem)
            if (hItem.class == "C4" and self:GetActorMode(ACTORMODE_RAPIDFIRE) > 0) then
                hItem.weapon:Sv_Update()
            end
        elseif (hVehicle and hVehicle:GetDriverId() == self.id) then
            local hMGs = hVehicle.HeliMGs
            if (hMGs) then
                for _, hMG in pairs(hMGs) do
                    local vDir = hVehicle:GetDirectionVector()
                    if (self:HasGodMode(2) or hVehicle.UsePlayerMGDir) then
                        vDir = self:SmartGetDir()
                    end
                    --self:UpdateFiringInfo(hMG, vDir, (hMG.SvFireRate or -1))
                    hMG.weapon:Sv_SetFiringInfo(vDir, hMG:GetWorldPos(), vector.sum(hMG:GetWorldPos(), vDir, 2024), (hMG.SvFireRate or -1))--vDir, vHand, vHit)
                    hMG.weapon:Sv_Update()
                    hMG.weapon:SetAmmoCount(nil, 10)
                    --ServerLog("Lua updated..")
                    --hMG:SetAngles(vector.toang(vDir))
                    --Debug("uwupdate")
                end
            end
        end

        local bFlying = self:IsFlying()
        if (self.Info.IsFlying ~= bFlying) then
            if (not bFlying) then -- Landed
                self:ResetServerFiring()
            end
        end
        self.Info.IsFlying = bFlying

        -- Tick
        self.FrameTick.refresh()
    end

    hClient.UpdateFiringInfo = function(self, hItem, vDir, iRate)

        if (not hItem.weapon:Sv_IsFiring()) then
            return
        end

        vDir = vDir or self:SmartGetDir()
        local vHand = self:GetBonePos("Bip01 R Hand") or self:GetPos()
        hItem.weapon:Sv_SetFiringInfo(vDir, vHand, vector.sum(vHand, vDir, 2024), (iRate or -1))--vDir, vHand, vHit)
    end

    hClient.ResetServerFiring = function(self)
        for _, hItem in pairs(self:GetInventory() or {}) do
            if (hItem.SvFiring) then
                hItem.weapon:Sv_RequestStopFire()
                hItem.SvFiring = false
            end
        end
    end

    -- EXPERIMENTAL
    ServerStats:SetEntityUpdateRate(hClient)

    hClient.Info.FiringTimer = timernew()
    hClient.Info.IdleTimer   = timernew()
    hClient.Info.IdleTime    = 0

    hClient.Info.Initialized = true
    hClient.InfoInitialized  = true
    hClient.InitTimer        = (hClient.InitTimer or timernew(12))
    hClient.LastTick         = timernew()
    hClient.FrameTick        = timernew()

    ClientMod:InitClient(hClient)
    g_gameRules:SvInitClient(hClient)
    if (hClient.IsPlayer) then
        EventCall(eServerEvent_OnClientInit, hClient, iChannel)
    end

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

---------------
Server.Register(PlayerHandler, "PlayerHandler")