-------------------
ServerPlugins = (ServerPlugins or {

    PluginDir = (SERVER_DIR_PLUGINS),
    Plugins = {},
    PluginData = {},
    PluginEvents = {},
})

-------------------
ServerPlugins.Init = function(self)

    self.Plugins = {}
    self.PluginEvents = {}

    CreatePlugin = function(...)
        return ServerPlugins:CreatePlugin(...)
    end
    PluginGetData = function(...)
        return ServerPlugins:GetPluginData(...)
    end
    SetPluginData = function(...)
        return ServerPlugins:SetPluginData(...)
    end
    PluginSaveCall = function(...)
        return ServerPlugins:PluginSaveCall(...)
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

    if (iEvent == eServerEvent_OnScriptReload) then
        for _, aPlugin in pairs(self.Plugins) do
            --self.PluginData[_] = table.getM(aPlugin, )
        end
    end

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
ServerPlugins.PluginSaveCall = function(self, sID, sCall, ...)

    local hPlugin = self:GetPlugin(sID)
    if (not hPlugin) then
        HandleError("Attempt to call function from invalid plugin %s",g_ts(sID))
        return
    end

    local hFunc = table.getnested(hPlugin, sCall)
    if (not isFunc(hFunc)) then
        HandleError("Attempt to call %s, a non-function (%s) for event %s", g_ts(sCall),g_ts(hFunc),g_ts(sID))
        return
    end

    if (DebugMode()) then
        return hFunc(hPlugin, ...)
    else
        local bOk, sError = pcall(hFunc, hPlugin, ...)
        if (not bOk) then
            HandleError("encountered error %s while trying to safely execute %s for event %s", g_ts(sError), g_ts(sCall), g_ts(sID))
        end

        return sError
    end
end

-------------------
ServerPlugins.SetPluginData = function(self, sID, sNest, hData)
    table.checkM(self.PluginData, sID, {})
    table.setM(self.PluginData[sID], sNest, hData)
end

-------------------
ServerPlugins.GetPluginData = function(self, sID, sNested, hDefault)

    --Debug(sNested)
    --Debug("stored:",self.PluginData[sID])

    --table.checkM(self.PluginData, sID, {})
    --table.checkNestedM(self.PluginData[sID], sNested, hDefault)
    --local hData = table.getnested(self.PluginData[sID], sNested)

    table.checkM(self.PluginData, sID, {})
    local hData = table.getM(self.PluginData[sID], sNested, hDefault)

    --ServerLog("PluginData = %s",table.tostring(self.PluginData))
    --ServerLog("Data = %s",table.tostring(hData))
    --ServerLog("hDefault = %s",table.tostring(hDefault))

    --if (hData == nil) then
    --    self.PluginData[sID] = { }
    --    hData = self.PluginData[sID]
    --end
    --Debug("DATA FOUND::",hData)

    -- hData or hDefault -- not working, what if hData it "false"!!
    if (hData == nil )then
        return hDefault
    end
    return hData
end

-------------------
ServerPlugins.CreatePlugin = function(self, sID, aPlugin)

    local aLinks = aPlugin.Links
    --local sID    = aPlugin.ID
    if (not sID) then
        return HandleError("No ID Specified in CreateEvent()")
    elseif (self:GetPlugin(sID)) then
        return HandleError("Event with ID %s Already Exists", sID)
    end

    if (aPlugin.Init) then
        if (DebugMode()) then
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

                ServerLog("Registered new event %d", iEventID)
            end
            table.insert(self.PluginEvents[iEventID], { sID, aPlugin[sFunc] })
        end
    end

    self.Plugins[sID] = aPlugin
end