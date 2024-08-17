-----------------
ServerStats = (ServerStats or {

    DataDir  = (SERVER_DIR_DATA .. "ServerData\\"),
    DataFile = "ServerStats.lua",

    Stats = {}
})

-----------------

eServerStat_ServerTime      = "server_total_time"
eServerStat_PlayerRecord    = "server_player_record"
eServerStat_TotalChannels   = "server_total_channels"
eServerStat_ConnectedCount  = "server_total_connects"
eServerStat_ConnectionCount = "server_total_connections"

-----------------
ServerStats.Init = function(self)

    self:LoadFile()
    LinkEvent(eServerEvent_OnScriptReload, "ServerStats", self.SaveFile)

    GetServerStat       = function(...) ServerStats:Get(...)  end
    SetServerStat       = function(...) ServerStats:Set(...)  end
    AddServerStat       = function(a, b) SetServerStat(a, b, true)  end
    IncreaseServerStat  = function(a, b, c) SetServerStat(a, b, c, true)  end

end

-----------------
ServerStats.Get = function(self, hID, hDefault)

    if (not hID) then
        throw_error("no id specified to GET()")
    end

    local hStat = self.Stats[hID]
    if (isNull(hStat)) then
        return hDefault
    end

    return hStat
end

-----------------
ServerStats.Set = function(self, hID, hValue, bAdd, bIncreaseOnly)

    if (not hID) then
        throw_error("no id specified to SET()")
    end

    if (bAdd) then
        hValue = (hValue + (self.Stats[hID] or 0))
    end

    local hCurrent = self.Stats[hID]
    if (bIncreaseOnly) then
        if (hCurrent and hCurrent >= hValue) then
            ServerLog("too small!")
            return
        end
    end

    --ServerLog("%s=%s",g_ts(hID),g_ts(hValue))
    self.Stats[hID] = hValue
end

-----------------
ServerStats.LoadFile = function(self)

    local sFile = (self.DataDir .. self.DataFile)
    local aData = FileLoader:ExecuteFile(sFile, eFileType_Data)
    if (not aData) then
        return
    end

    self.Stats = aData
end

-----------------
ServerStats.SaveFile = function(self)

    local sData = string.format("return %s", (table.tostring((self.Stats or {}), "", "") or "{}"))
    local sFile = (self.DataDir .. self.DataFile)

    local bOk, sErr = FileOverwrite(sFile, sData)
    if (not bOk) then

        -- FIXME: Error Handler
        -- ErrorHandler()

        ServerLogError("Failed to open file %s for writing", sFile)
    end
end