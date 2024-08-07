-------------------
ServerPlugins = {

    PluginDir = (SERVER_DIR_PLUGINS),
    Plugins = {},
    PluginEvents = {},
}

-------------------
ServerPlugins.Init = function(self)

    CreatePlugin = function(...)
        return ServerPlugins:CreatePlugin(...)
    end

    self:LoadPlugins()
    Logger:LogEvent(eLogEvent_Plugins, "Loaded ${red}%d${gray} Plugins", table.count(self.Plugins))
end

-------------------
ServerPlugins.LoadPlugins = function(self, sPath)

    local sDir = (sPath or self.PluginDir)
    if (not ServerLFS.DirExists(sDir)) then
        return
    end

    local aFiles = ServerLFS.DirGetFiles(sDir, GETFILES_ALL)
    if (table.count(aFiles) == 0) then
        return
    end

    for _, sFile in pairs(aFiles) do

        if (ServerLFS.DirIsDir(sFile)) then
            self:LoadPlugins(sFile)
        else
            FileLoader:ExecuteFile(sFile, eFileType_Plugin)
        end
    end
end

-------------------
ServerPlugins.OnEvent = function(self, ...)
    local aParams   = { ... }
    local iEvent    = table.popLast(aParams)

    local aLinks = self.PluginEvents[iEvent]
    if (table.count(aLinks) > 0) then

        local bOk, sError
        for _, aLink in pairs(aLinks) do
            bOk, sError = pcall(aLink[2], self.Plugins[aLink[1]], unpack(aParams))
            if (not bOk) then
                HandleError("Failed to Execute Event %s for Plugin %s (%s)", g_ts(_), g_ts(aLink[1]), g_ts(sError))
            end
        end
    end
end

-------------------
ServerPlugins.GetPlugin = function(self, sID)
    return self.Plugins[sID]
end

-------------------
ServerPlugins.CreatePlugin = function(self, aPlugin)

    local aLinks = aPlugin.Links
    local sID    = aPlugin.ID
    if (not sID) then
        return HandleError("No ID Specified in CreateEvent()")
    elseif (self:GetPlugin(sID)) then
        return HandleError("Event with ID %s Already Exists", sID)
    end

    if (aPlugin.Init) then
        if (SERVER_DEBUG_MODE) then
            aPlugin:Init()
        else
            local bOk, sError = pcall(aPlugin.Init, aPlugin)
            if (not bOk) then

                HandleError("Failed to Initialize Plugin %s (%s)", sID, (sError or "NA/"))
                ServerLogError("Failed to Initialize Plugin (%s)", (sError or "N/A"))
                return
            end
        end
    end

    if (table.count(aLinks) > 0) then
        for iEventID, sFunc in pairs(aLinks) do
            if (not self.PluginEvents[iEventID]) then
                LinkEvent(iEventID, "ServerPlugins", self.OnEvent)
                self.PluginEvents[iEventID] = {}
            end
            table.insert(self.PluginEvents[iEventID], { sID, aPlugin[sFunc] })
        end
    end

    self.Plugins[sID] = aPlugin
end