------------------------------------------------
--- Initializer for the Server
---
--- File Loading Structure:
---  > Libraries
---  > Logger
---  > Server
---    > Config
---      > Config Files
---    > FileLoader
---    > ServerPublisher
---    > ServerRPC
---    > Internals
---
----------------
ServerInit = {}

----------------

SERVER_DEBUG_MODE = false
DebugMode = function() return SERVER_DEBUG_MODE   -- <== This is so we can easily modify what defines the debug mode
end

----------------
ServerInit.Init = function(self)

    if (EarlyInit) then EarlyInit.Init() end

    SCRIPT_ERROR = true
    LOG_STARS    = (string.rep("*", 40))

    -----
    MOD_RAW_NAME = ("CryMP-Server")
    MOD_EXE_NAME = (MOD_RAW_NAME .. ".exe")
    MOD_NAME     = (MOD_RAW_NAME .. " x" .. CRYMP_SERVER_BITS)
    MOD_VERSION  = ("v" .. CRYMP_SERVER_VERSION)
    MOD_BITS     = CRYMP_SERVER_BITS
    MOD_COMPILER = CRYMP_SERVER_COMPILER

    -----
    SystemLog        = System.LogAlways
    ServerLog        = self:CreateLogAbstract(SystemLog, "$9[$4Server$9] ")
    ServerLogError   = self:CreateLogAbstract(SystemLog, "$9[$4Server$9] Error: ")
    ServerLogWarning = self:CreateLogAbstract(SystemLog, "$9[$4Server$9] Warning: ")

    -----
    -- CreateLogFunction = self.CreateLogFunction

    -----
    ServerLog(LOG_STARS .. LOG_STARS)
    ServerLog("Initializing Globals..")

    SERVER_ROOT       = ServerDLL.GetRoot()
    SERVER_DIR        = ServerDLL.GetRoot()
    SERVER_WORKINGDIR = ServerDLL.GetWorkingDir()

    SERVER_DIR_DATA     = (SERVER_ROOT .. "\\Data\\")            -- Server Data (Bans, Mutes, Warns, etc)
    SERVER_DIR_CONFIG   = (SERVER_ROOT .. "\\Config\\")          -- Server Configuration
    SERVER_DIR_SCRIPTS  = (SERVER_ROOT .. "\\Scripts\\")         -- Scripts (Commands, Plugins, etc)
    SERVER_DIR_LIBS     = (SERVER_DIR_SCRIPTS .. "Libs\\")       -- Library (3rd party scripts)
    SERVER_DIR_CORE     = (SERVER_DIR_SCRIPTS .. "Core\\")       -- Core Scripts (Scripts the server depends on)
    SERVER_DIR_INTERNAL = (SERVER_DIR_SCRIPTS .. "Internal\\")   -- Internal Scripts (Scripts the server relies on)
    SERVER_DIR_COMMANDS = (SERVER_DIR_SCRIPTS .. "Commands\\")   -- Commands
    SERVER_DIR_PLUGINS  = (SERVER_DIR_SCRIPTS .. "Plugins\\")    -- Plugins

    SERVER_FILE_MAIN    = "Server.lua"
    SERVER_FILE_LOGGER  = "Logger.lua"
    SERVER_FILE_GLOBALS = "Globals.lua"

    -----
    eFileType_Server    = "Server"
    eFileType_Library   = "Library"
    eFileType_Core      = "Core"
    eFileType_Internal  = "Internal"
    eFileType_Plugin    = "Plugin"
    eFileType_Command   = "Command"
    eFileType_Config    = "Config"
    eFileType_Data      = "Data"
    eFileType_Other     = "Other"

    -----
    self.LOADED_FILES = {
        [eFileType_Server]   = {},
        [eFileType_Library]  = {},
        [eFileType_Core]     = {},
        [eFileType_Internal] = {},
        [eFileType_Plugin]   = {},
        [eFileType_Command]  = {},
        [eFileType_Config]   = {},
        [eFileType_Data]     = {},
        [eFileType_Other]    = {}
    }

    -----
    if (not g_gameRules) then
        --error("game rules does not exist")
    end

    if (g_gameRules) then
        g_sGameRules = g_gameRules.class
        g_pGame = g_gameRules.game
    end

    -----
    GetCVar  = System.GetCVar
    SetCVar  = System.SetCVar
    FSetCVar = ServerDLL.FSetCVar -- FIXME: Add this

    -----
    --- Not optimal, need to reload scripts twice for these functions to recognize changes.. move to Server.Init?
    if (FIRST_RELOAD_FINISHED) then
        if (Server ~= nil) then
            local bOk, sErr = pcall(Server.OnReload, Server)
            if (not bOk) then
                ServerLogError("OnReload Call failed (%s)", (sErr or "N/A"))
            end
        end
    end

    -----
    ServerLog("Initializing Scripts..")
    for _, fFunc in pairs({
        -- More ?
        self.LoadLibraries,
        self.LoadGlobals,
        self.InitLogger,
    }) do
        if (not fFunc(self)) then
            return false
        end
    end

    -- Allow server to load before gamerules exist, this is important for patching entities
    if (g_gameRules ~= nil) then
        self:InitServer()
    end

    -- Link Some Stuff
    -- ServerDLL.SetCallback(SV_EVENT_ON_GAME_RULES_CREATED, function() ServerInit:Init()  end)

    ServerLog(LOG_STARS .. LOG_STARS)
    SCRIPT_ERROR = false
    FIRST_RELOAD_FINISHED = (g_gameRules ~= nil)

    return true
end

----------------
--- It's Recursive
ServerInit.LoadLibraries = function(self, sPath)

    -----
    local sDir = (sPath or SERVER_DIR_LIBS)
    if (not ServerLFS.DirExists(sDir)) then
        return true, self:LogError("Libraries directory does not exist")
    end

    local aFolders = ServerLFS.DirGetFiles(sDir, GETFILES_DIR)
    if (#(aFolders or {}) > 0) then
        for _, sFolder in pairs(aFolders) do
            self:LoadLibraries(sFolder)
        end
    end

    local aFiles = ServerLFS.DirGetFiles(sDir, GETFILES_FILES, ".*")
    if (#aFiles == 0) then
        return true
    end

    for _, sFile in pairs(aFiles) do

        -- We don't load Library files where the name starts with '!'
        if (ServerLFS.FileExists(sFile) and (string.sub(ServerLFS.FileGetName(sFile), 1, 1) ~= "!")) then
            if (not self:LoadFile(sFile, "Library")) then
                -- Nothing, it's just a library, which are mostly optional!
            else
                -- EDIT: Comment later
            end
        end
    end

    -- Overwrite FileSystem Handle with our own File System
    if (fileutils) then
        fileutils.LFS = ServerLFS
    end

    -- Overwrite Error Handler Handle with our our handler
    if (luautils) then
        luautils.ERROR_HANDLER = HandleError
    end

    return true
end

----------------
ServerInit.LoadGlobals = function(self)

    -----
    local sFile = (SERVER_DIR_CORE .. SERVER_FILE_GLOBALS)
    if (not ServerLFS.FileExists(sFile)) then
        return false, self:OnError("Logger Script %s not found", sFile)
    end

    if (not self:LoadFile(sFile, eFileType_Core)) then
        return false
    end

    ------
    return true
end

----------------
ServerInit.InitLogger = function(self)

    -----
    local sFile = (SERVER_DIR_CORE .. SERVER_FILE_LOGGER)
    if (not ServerLFS.FileExists(sFile)) then
        return false, self:OnError("Logger Script %s not found", sFile)
    end

    if (not self:LoadFile(sFile, eFileType_Core)) then
        return false
    end

    if (not Logger) then
        return false, self:OnError("Logger is null")
    end

    ------
    Logger:Init()

    ------
    return true
end

----------------
ServerInit.InitServer = function(self)

    -----
    local sFile = (SERVER_DIR_CORE .. SERVER_FILE_MAIN)
    if (not ServerLFS.FileExists(sFile)) then
        return false, self:OnError("Server Script %s not found", sFile)
    end

    if (not self:LoadFile(sFile, eFileType_Server)) then
        return false
    end

    if (not Server) then
        return false, self:OnError("Server is null")
    end

    ------
    Server:Init()

    ------
    return true
end

----------------
ServerInit.LoadFile = function(self, sFile, sType)

    if (not sFile) then
        return false, self:OnError("No File Specified to LoadFile()")
    end
    sType = (sType or "Unspecified")

    -----
    local hLib, bOk, sErr, sErr2
    hLib, sErr = loadfile(sFile)
    if (not hLib or sErr) then
        return false, self:OnError("%s while trying to load file %s", (sErr or "N/A"), sFile)
    end

    bOk, sErr2 = pcall(hLib)
    if (not bOk) then
        return false, self:OnError("%s while trying to execute file %s", (sErr2 or sErr or "N/A"), sFile)
    end

    -- Statistical reasons
    self:OnFileLoaded(sFile, sType)

    return true
end

----------------
ServerInit.OnFileLoaded = function(self, sFile, sType)
    table.insert(self.LOADED_FILES[(sType or eFileType_Other)], sFile)
end

----------------
ServerInit.CreateLogAbstract = function(self, fBase, sPrefix)
    local function fLog(s, ...)
        local n = ((sPrefix or "")) .. s
        if (#{...} > 0) then
            n = string.format(n, ...)
        end
        for line in string.gmatch(n, "[^\n]+") do
            fBase(line)
        end
    end
    return fLog
end

----------------
ServerInit.OnError = function(self, sError, ...)
    ServerLogError(sError, ...)
end

----------------
ServerInit.OnWaring = function(self, sWarning, ...)
    ServerLogWarning(sWarning, ...)
end

----------------
ServerDLL.SetScriptErrorLog(true)
ServerInit:Init()