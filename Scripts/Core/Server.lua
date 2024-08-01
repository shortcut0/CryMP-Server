----------------
Server = {
}

----------------
Server.Init = function(self)

    -----
    Logger.CreateAbstract(self, { LogClass = "Server", Color = "$4" })
    self:Log("Init()")

    SCRIPT_ERROR = true

    --------
    self.INIT_TIMER = timernew()
    self.Initializer = ServerInit

    --------
    self.CONFIG_FILES = {
        "FileLoader",
        "ServerConfig"
    }

    --------
    self.CORE_FILES = {
        "ServerPublisher",
        "ServerRPC",
    }

    self.INTERNAL_FILES = {
        "ConnectionHandler",
        "ErrorHandler",
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

    self:InitCore()
    self:InitInternals()

    local aLoaded = self.Initializer.LOADED_FILES
    self:Log(LOG_STARS)
    self:Log("[%02d] Files Loaded:", table.countRec(aLoaded))
    for sType, aFiles in pairs(aLoaded) do
        for _, sFile in pairs(aFiles) do
            self:Log(" > [%-8s] %s", sType, sFile)
        end
    end

    --------
    self:Log("Server Initialized in %fs", self.INIT_TIMER.diff())

    SCRIPT_ERROR = false
end

----------------
Server.InitConfigs = function(self)

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

    ServerPCH:Init()
    ErrorHandler:Init()
    ServerInjector:Init()
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
end

----------------
Server.OnTick = function(self)
    self:CoreTick()
end

----------------
Server.OnMinuteTick = function(self)
end

----------------
Server.OnHourTick = function(self)
end