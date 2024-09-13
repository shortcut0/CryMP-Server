----------------
Server = (Server or {

    ResetListeners = {},
    DefaultCVars = {},

    -- FIXME: Add Identifiers!
    IS_PUBLIC = nil,
    IS_PRIVATE = (GetCVar("sv_lanOnly") >= 1 or nil)

})

----------------
Server.Init = function(self)

    -----
    SERVER_INITIALIZED = false
    Logger.CreateAbstract(self, { LogClass = "Server", Color = "$4" })
    self:Log("Init()")

    --------
    self.INIT_TIMER = timernew()
    self.Initializer = ServerInit

    self.FastTickTimer = timernew(0.15)

    --------
    self.ResetListeners = {}
    RegisterReset = function(sID, hFunc)
        ServerLog("Added Reset Listener..")
        Server.ResetListeners[sID] = hFunc
    end

    --------
    self.CONFIG_FILES = {
        "ErrorHandler",
        "FileLoader",
        "ServerDefense",
        "ServerConfig"
    }

    --------
    self.CORE_FILES = {
        "ServerEvents",
        "ServerPublisher",
        "ServerRPC",
    }

    -- Unused
    self.INTERNAL_FILES = {
    --    "ConnectionHandler",
    --    "ErrorHandler",
    --    "ServerUtils",
    --    "ServerNames",
    --    "ServerChannels",
    }

    if (not self:LoadConfigFiles()) then
        return ServerLogError("Failed to load Config files")
    else
        self:InitConfigs()
    end

    --------
    --- Core
    if (not self:LoadCoreFiles()) then
        return ServerLogError("Failed to load Core files")
    end

    --------
    --- Internal
    if (not self:LoadInternalFiles()) then
        return ServerLogError("Failed to load Server Internal files")
    end


    ---

    ---
    self:InitCore()
    self:InitInternals()

    ---
    self:CreateServerEntity()
    self:InitServerEntity()

    if (DebugMode()) then
        local aLoaded = self.Initializer.LOADED_FILES
        self:Log(LOG_STARS)
        self:Log("[%02d] Files Loaded:", table.countRec(aLoaded))
        for sType, aFiles in pairs(aLoaded) do
            for _, sFile in pairs(aFiles) do
                self:Log(" > [%-8s] %s", sType, sFile)
            end
        end
    end

    --------
    self:PostInit()
    SCRIPT_ERROR = false
    SERVER_INITIALIZED = true

    --------
    self.INIT_TIME = self.INIT_TIMER.diff()
    self:Log("Server Initialized in %fs", self.INIT_TIME)
end

----------------
Server.SetServerEntity = function(self, hEnt)
    self.ServerEntity = hEnt
end

----------------
Server.InitServerEntity = function(self)
    PlayerHandler:InitServer(self.ServerEntity)
end

----------------
Server.CreateServerEntity = function(self)

    local hEnt = GetEntity(SERVERENT_ID)
    if (hEnt) then
        if (hEnt.IsServerEntity and hEnt.IsServer) then
            return self:SetServerEntity(hEnt)
        else
            SERVERENT_ID = nil
            SERVERENT    = nil
        end
    end

    hEnt = SpawnEntity({
        name        = MOD_RAW_NAME,
        class       = "OffHand",
        position    = vector.make(0, 0, 1000),
        orientation = vector.make(0, 0, 1)
    })

    if (not hEnt) then
        error("failed to spawn server entity")
    end

    SERVERENT_CHANNEL = -69
    SERVERENT_ID = hEnt.id
    SERVERENT = hEnt

    self.ServerEntity = hEnt
end

----------------
Server.PostInit = function(self)

    -- we must re-initialize these!!
    Logger:InitLogEvents()
    ServerEvents:PostInit()
    ServerCommands:PostInit()

    EventCall(eServerEvent_OnPostInit)
end

----------------
Server.OnReload = function(self)

    if (PlayerHandler) then
        PlayerHandler:SavePlayerData()
    end
    EventCall(eServerEvent_OnScriptReload)
end

----------------
Server.InitConfigs = function(self)

    ServerLog("Initializing Error Handler...")
    ErrorHandler:Init()

    ServerLog("Initializing Configurations...")
    ServerConfig:Init()
end

----------------
Server.LoadConfigFiles = function(self)

    local sDir = SERVER_DIR_CORE
    local aFiles = self.CONFIG_FILES

    for _, sFile in pairs(aFiles) do
        if (not self.Initializer:LoadFile((sDir .. sFile .. ".lua"), eFileType_Config)) then
            return false
        end
    end

    return true
end

----------------
Server.InitCore = function(self)

    ServerLog("Initializing Core...")

    ServerPublisher:Init()
    ServerRPC:Init()
    ServerEvents:Init()
    ServerDefense:Init()
end

----------------
Server.UpdateCore = function(self)

    --[[
    table.checkM(self,"L",timernew(1))
    Script.SetTimer(1,function()if (self.L.expired(0.1)) then

        local v=SvSpawnEntity({
            Respawn=true,
            FixedName=true,
            Pos = vector.make(math.random(0,1000),math.random(0,1000),math.random(0,1000)),
            Class = "Civ_car1",
            Name = "Bicth_Car1";
            Properties = {
                Respawn = {
                    bRespawn = 1,
                    bUnique = 0,
                    nTimer = 30,
                }
            }
        })


        self.repairHit={
            typeId	=g_gameRules.game:GetHitTypeId("repair"),
            type		="repair",
            material=0,
            materialId=0,
            dir			=g_Vectors.up,
            radius	=0,
            partId	=-1,
        };

    local hit=self.repairHit;
    hit.shooter=System.GetEntity(v.id);
    hit.shooterId=v.id;
    hit.target=v;
    hit.targetId=v.id;
    hit.pos=v:GetWorldPos(hit.pos);
    hit.damage=999999;

        for i=1,1000 do
            g_pGame:SetSynchedEntityValue(v.id,i,(
                    i>750 and NULL_ENTITY or
                    i>500 and math.random()*99 or
                    i>250 and "hello" or
                    0
            ))
        end

        v.Server.OnHit(v, hit);
        g_pGame:ScheduleEntityRemoval(v.id,300,false)
        ServerLog("Garbage:" .. string.bytesuffix(collectgarbage("count")*1024))
        self.L.refresh()
end  end)


    ]]
    --[[
    if (DebugMode()) then
        --collectgarbage("stop")
        --collectgarbage("collect")

        table.checkM(self,"LGX",1)
        for i = 1, 1000+math.random(5000,10000) do
            if (i> 3000) then
                _G[self.LGX+1 .."garbage"] = math.random(1,3)==2 and {
                    trasharay ={}
                } or function()return trash()  end
            end
            _G[self.LGX.."gbbb"] = _G[i-self.LGX*2-1 .."gbbb"]
            self.LGX=self.LGX+1
        end

        collectgarbage("stop")
    elseif (self.LGX) then

        collectgarbage("collect")
        self.LGX=nil
    end
    if (self.L.expired()) then
        collectgarbage()

        ServerLog("Garbage:" .. string.bytesuffix(collectgarbage("count")*1024))
        self.L.refresh()
    end]]

end

----------------
Server.CoreTick = function(self)
    ServerPublisher:OnTick()
end

----------------
Server.LoadCoreFiles = function(self)

    local sDir = SERVER_DIR_CORE
    local aFiles = self.CORE_FILES

    for _, sFile in pairs(aFiles) do
        if (not self.Initializer:LoadFile((sDir .. sFile .. ".lua"), eFileType_Core)) then
            return false
        end
    end

    return true
end

----------------
Server.LoadInternalFiles = function(self)

    local sDir = SERVER_DIR_INTERNAL
    local aFiles = ServerLFS.DirGetFiles(sDir, GETFILES_FILES)

    for _, sFile in pairs(aFiles) do
        if (not self.Initializer:LoadFile(sFile, eFileType_Internal)) then
            return false
        end
    end

    return true
end

----------------
Server.InitInternals = function(self)

    ServerLog("Initializing Internals...")

    -- These reply on no other internals, so they can be on top
    ServerStats:Init()  -- Requires: <Nothing>

    -- Priority
    ServerUtils:Init() -- Exposes functions!

    ServerAccess:Init()
    ServerChat:Init()
    PlayerHandler:Init()

    ServerLocale:Init()
    ServerCommands:Init()
    ServerPunish:Init()

    ServerPlugins:Init()
    ServerMaps:Init()

    ServerPCH:Init()
    ErrorHandler:Init()
    ServerInjector:Init()
    ServerNames:Init()
    ServerChannels:Init()
    ServerItemHandler:Init()

    ServerVoting:Init()
    ServerMapSetup:Init()
    ServerItemSystem:Init()

    if (ClientMod) then
        ClientMod:Init()
    end
end

----------------
Server.UpdateInternals = function(self)
    --ServerPHC:OnUpdate()
    --ErrorHandler:OnUpdate()
end

----------------
Server.OnUpdate = function(self)

    if (not SERVER_INITIALIZED) then
        return
    end

    self:UpdateCore()
    self:UpdateInternals()

    --for _, hClient in pairs(GetPlayers() or {}) do
        --if (hClient.InfoInitialized) then
            --hClient:Update()
        --end
    --end

    if (self.FastTickTimer.expired()) then
        EventCall(eServerEvent_ScriptTickFast)
        self.FastTickTimer.refresh()
    end

    g_gameRules:UpdateReviveQueue()

    EventCall(eServerEvent_ScriptUpdate)
end

----------------
Server.OnTick = function(self)

    if (not SERVER_INITIALIZED) then
        return
    end

    -- New Timer
    g_gameRules:OnTickTimer()

    self:CoreTick()
    for _, hClient in pairs(GetPlayers()) do
        if (hClient.InfoInitialized) then
            hClient:Tick()
            EventCall(eServerEvent_OnClientTick, hClient)
        else
            Debug("Not init!S")
        end
    end
    EventCall(eServerEvent_ScriptTick)

    -- Stats Update
    ServerStats:UpdatePerformance()
    AddServerStat(eServerStat_ServerTime, 1)

    self:SyncCVars()
end

----------------
Server.SyncCVars = function(self)

    local aCVars = {
        ["p_max_player_velocity"] = 0
    }

    for sName, iAdd in pairs(aCVars) do
        g_pGame:SetSynchedGlobalValue((900 + iAdd), GetCVar(sName))
    end
end

----------------
Server.OnMinuteTick = function(self)
    EventCall(eServerEvent_ScriptMinuteTick)
end

----------------
Server.OnHourTick = function(self)

    -- save data every now and then!
    if (table.count(GetPlayers()) == 0) then
        self:OnReload()
    end

    EventCall(eServerEvent_ScriptHourTick)
end

----------------
Server.IsCVarChanged = function(self, sCVar)

    return self.DefaultCVars[string.lower(sCVar)] ~= nil
end

----------------
Server.SaveCVar = function(self, sCVar)

    if (not self:IsCVarChanged(sCVar)) then
        self.DefaultCVars[string.lower(sCVar)] = GetCVar(sCVar)
    end
end

----------------
Server.RestoreCVar = function(self, sCVar, hUser)

    if (self:IsCVarChanged(sCVar)) then
        FSetCVar(sCVar, self.DefaultCVars[string.lower(sCVar)])
        self.DefaultCVars[string.lower(sCVar)] = nil

        if (hUser) then
            SendMsg(CHAT_SERVER, hUser, hUser:Localize("@l_ui_cvarRestored", { sCVar }))
            Logger:LogEventTo(GetAdmins(), eLogEvent_Game, "@l_ui_cvarRestored_console",  sCVar, GetCVar(sCVar), hUser:GetName() )
        end
    end
end

----------------
Server.ChangeCVar = function(self, sCVar, hValue, hUser)

    self:SaveCVar(sCVar)
    FSetCVar(sCVar, hValue)

    if (hUser) then
        SendMsg(CHAT_SERVER, hUser, hUser:Localize("@l_ui_cvarChanged", { sCVar, hValue }))
        Logger:LogEventTo(GetAdmins(), eLogEvent_Game, "@l_ui_cvarChanged_console",  sCVar, hValue, hUser:GetName() )
    end
end

----------------
Server.Reset = function(self)
    for _, h in pairs(self.ResetListeners) do
        if (isString(h)) then
            local bOk, sErr = pcall(loadstring, h)
            if (not bOk) then
                ErrorHandler("Failed to execute event listener %s (%s)", _, g_ts(sErr))
            end
        else
            ServerLog("Executing Reset Listener..")
            h()
        end
    end

    if (ConfigGet("General.MapConfig.DeleteClientEntities", false, eConfigGet_Boolean)) then
        self:CollectGarbageEntities()
    end
end

----------------
Server.OnMapReset = function(self)

    self:Reset()
    ServerMaps:OnReset()
    CallEvent(eServerEvent_MapReset, true)
end

----------------
Server.CollectGarbageEntities = function(self)

    ServerLog("Collecting Garbage Entities..")

    local aEntities = System.GetEntities()
    if (table.empty(aEntities)) then
        return
    end

    local iDeleted = 0
    for _, hEntity in pairs(aEntities) do
        if (hEntity:HasFlags(ENTITY_FLAG_CLIENT_ONLY)) then
            iDeleted = iDeleted + 1
            RemoveEntity(hEntity.id)
        end
    end

    ServerLog("Deleted %d Garbage Entities", iDeleted)
end

----------------
Server.OnBeforeSpawn = function(self, aParams)

    if (aParams.class == "GUI") then
    --    aParams.name = GUI.PrepareName(aParams)
    end
    return aParams
end

----------------
Server.Register = function(hModule, sName)

    hModule.MODULE_NAME = sName
    hModule.GetName = function(self)
        return self.MODULE_NAME
    end
end

----------------
Server.Quit = function(self)

    --self:OnReload()
   -- CallEvent(eServerEvent_OnExit)
end