----------------
Server = {

    -- FIXME: Add Identifiers!
    IS_PUBLIC = nil,
    IS_PRIVATE = (GetCVar("sv_lanOnly") >= 1 or nil)

}

----------------
Server.Init = function(self)

    -----
    Logger.CreateAbstract(self, { LogClass = "Server", Color = "$4" })
    self:Log("Init()")

    --------
    self.INIT_TIMER = timernew()
    self.Initializer = ServerInit

    --------
    self.CONFIG_FILES = {
        "ErrorHandler",
        "FileLoader",
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

    if (SERVER_DEBUG_MODE) then
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
end

----------------
Server.UpdateCore = function(self)
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

    -- Priority
    ServerUtils:Init() -- Exposes functions!

    ServerAccess:Init()
    ServerChat:Init()
    PlayerHandler:Init()

    ServerLocale:Init()
    ServerCommands:Init()
    ServerPunish:Init()

    ServerPlugins:Init()

    ServerPCH:Init()
    ErrorHandler:Init()
    ServerInjector:Init()
    ServerNames:Init()
    ServerChannels:Init()
    ServerItemHandler:Init()
end

----------------
Server.UpdateInternals = function(self)
    --ServerPHC:OnUpdate()
    --ErrorHandler:OnUpdate()
end

----------------
Server.OnUpdate = function(self)
    self:UpdateCore()
    self:UpdateInternals()

    for _, hClient in pairs(GetPlayers()) do
        if (hClient.InfoInitialized) then
            hClient:Update()
        end
    end

    EventCall(eServerEvent_ScriptUpdate)
end

----------------
Server.OnTick = function(self)

    -- New Timer
    g_gameRules:OnTickTimer()

    self:CoreTick()
    for _, hClient in pairs(GetPlayers()) do
        if (hClient.InfoInitialized) then
            hClient:Tick()
            EventCall(eServerEvent_OnClientTick, hClient)
        end
    end
    EventCall(eServerEvent_ScriptTick)
end

----------------
Server.OnMinuteTick = function(self)
    EventCall(eServerEvent_ScriptMinuteTick)
end

----------------
Server.OnHourTick = function(self)
    EventCall(eServerEvent_ScriptHourTick)
end