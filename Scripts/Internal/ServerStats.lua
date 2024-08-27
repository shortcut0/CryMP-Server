-----------------
ServerStats = (ServerStats or {

    DataDir  = (SERVER_DIR_DATA .. "ServerData\\"),
    DataFile = "ServerStats.lua",

    Stats = {},

    Performance = {
        Mem = {
        },
        CPU = {
        }
    }
})

-----------------

eServerStat_ServerTime      = "server_total_time"
eServerStat_PlayerRecord    = "server_player_record"
eServerStat_TotalChannels   = "server_total_channels"
eServerStat_ConnectedCount  = "server_total_connects"
eServerStat_ConnectionCount = "server_total_connections"

PROFILER_DAILY  = 0 -- daily usage
PROFILER_HOUR   = 1 -- hourly usage
PROFILER_MINUTE = 2 -- usage this minute
PROFILER_TOTAL  = 3 -- normal usage

-----------------
ServerStats.Init = function(self)

    self:LoadFile()
    LinkEvent(eServerEvent_OnScriptReload, "ServerStats", self.SaveFile)

    GetServerStat       = function(...) return ServerStats:Get(...)  end
    SetServerStat       = function(...) ServerStats:Set(...)  end
    AddServerStat       = function(a, b) SetServerStat(a, b, true)  end
    IncreaseServerStat  = function(a, b, c) SetServerStat(a, b, c, true)  end

end

-----------------
ServerStats.GetMemUsage = function(self, iProfiler)

    iProfiler = iProfiler or PROFILER_TOTAL
    --self:UpdatePerformance() -- so values update!

    local aComp = self.Performance.Mem[iProfiler]
    return (aComp and aComp.V or 0)
end

-----------------
ServerStats.UpdatePerformance = function(self)

    table.checkM(self.Performance.Mem, PROFILER_MINUTE, { N = "Minute", L = timernew(), V = 0, LV = 0 })
    table.checkM(self.Performance.Mem, PROFILER_HOUR,   { N = "Hour",   L = timernew(), V = 0, LV = 0 })
    table.checkM(self.Performance.Mem, PROFILER_DAILY,  { N = "Day",    L = timernew(), V = 0, LV = 0 })
    table.checkM(self.Performance.Mem, PROFILER_TOTAL,  { N = "Total",  L = timernew(), V = 0, LV = 0 })

    local iMemUsage = ServerDLL.GetMemUsage()
    self:UpdateComponent(self.Performance.Mem[PROFILER_DAILY],  iMemUsage, ONE_DAY, true)
    self:UpdateComponent(self.Performance.Mem[PROFILER_HOUR],   iMemUsage, ONE_HOUR, true)
    self:UpdateComponent(self.Performance.Mem[PROFILER_MINUTE], iMemUsage, ONE_MINUTE, false)
    self.Performance.Mem[PROFILER_TOTAL] = { V = iMemUsage }

    --[[("Mem Current: %s, This Minute: %s, This Hour: %s, This Day: %s",
        string.bytesuffix(self:GetMemUsage()),
        string.bytesuffix(self:GetMemUsage(PROFILER_MINUTE)),
        string.bytesuffix(self:GetMemUsage(PROFILER_HOUR)),
        string.bytesuffix(self:GetMemUsage(PROFILER_DAILY))
    )]]
    --self:UpdateComponent(self.Performance.Mem, PROFILER_TOTAL,  iMemUsage)
end

-----------------
ServerStats.UpdateComponent = function(self, aComp, iNow, iExpiry, bAutoLog)

    local hTimer = aComp.L
    if (iExpiry == nil or hTimer.expired(iExpiry)) then
        if (bAutoLog) then
            ServerLog("Memory Usage this %s: %s (Current: %s)",
               aComp.N or "<N/A>",
                string.bytesuffix((aComp.V)),
                string.bytesuffix((iNow))
            )
        end
        hTimer.refresh()
        aComp.V = 0
    elseif (aComp.LV ~= nil) then
        aComp.V = (aComp.V or 0) + (iNow - (aComp.LV or 0))
    end

    aComp.LV = iNow

end

-----------------
ServerStats.Get = function(self, hID, hDefault)

    if (not hID) then
        throw_error("no id specified to GET()")
    end

    local hStat = self.Stats[hID]
    if (hStat == nil) then
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

   -- ServerLog("%s=%s",g_ts(hID),g_ts(hValue))
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