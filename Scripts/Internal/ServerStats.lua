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

eServerStat_ServerTime          = "server_total_time"
eServerStat_PlayerRecord        = "server_player_record"
eServerStat_TotalChannels       = "server_total_channels"
eServerStat_ConnectedCount      = "server_total_channels" -- these are the same! --"server_total_connects"
eServerStat_ConnectionCount     = "server_total_connections"
eServerStat_WallJumps           = "wall_jump_count"
eServerStat_TransferredRPCData  = "rpc_transferred_total"

PROFILER_DAILY  = 0 -- daily usage
PROFILER_HOUR   = 1 -- hourly usage
PROFILER_MINUTE = 2 -- usage this minute
PROFILER_TOTAL  = 3 -- normal usage

-----------------
ServerStats.Init = function(self)

    local iServerFPS = GetCVar("sv_dedicatedMaxRate")

    self.SERVER_RATE  = (1 / iServerFPS)

    -- Make Global?
    local RATE_FASTEST = (self.SERVER_RATE * 1)
    local RATE_FASTER  = (self.SERVER_RATE * 2)
    local RATE_FAST    = (self.SERVER_RATE * 4)
    local RATE_SLOW    = (self.SERVER_RATE * 6)
    local RATE_SLOWER  = (self.SERVER_RATE * 10)
    local RATE_SLOWEST = (self.SERVER_RATE * 20) -- Basically no updating at all

    self.UPDATE_RATES = {
        ["Default"]     = RATE_FASTEST,
        ["Player"]      = RATE_FASTEST, -- kkeep default for humans..
        ["NonPlayer"]   = RATE_SLOW, -- (1 / (iServerFPS * 0.85))
        ["GUI"]         = RATE_SLOWER,
        ["BasicEntity"] = RATE_SLOW,
    }

    self:LoadFile()
    LinkEvent(eServerEvent_OnScriptReload, "ServerStats", self.SaveFile)

    GetServerStat       = function(...) return ServerStats:Get(...)  end
    SetServerStat       = function(...) ServerStats:Set(...)  end
    AddServerStat       = function(a, b) SetServerStat(a, b, true)  end
    IncreaseServerStat  = function(a, b, c) SetServerStat(a, b, c, true)  end


    -- Defaults
    AddServerStat(eServerStat_TransferredRPCData, 0)
end

-----------------
ServerStats.SetEntityUpdateRate = function(self, hEntity)

    local sClass = hEntity.class
    if (hEntity.actor and not hEntity.IsPlayer) then
        sClass = "NonPlayer"
    end
    local iRate = self:GetEntityUpdateRate(sClass)
    if (iRate) then
        --hEntity:SetScriptUpdateRate(iRate)
        ServerDLL.SetEntityScriptUpdateRate(hEntity.id, iRate)
        --ServerLog("[%s.%s] Update Rate: %0.2f (Server: %0.2f)", hEntity.class, hEntity:GetName(), iRate, self.SERVER_RATE)
    end

    --for i,vv in pairs(System.GetEntities()) do
    --   vv:SetScriptUpdateRate(10)
    --   ServerLog("[%s.%s] Update Rate: %0.2f (Server: %0.2f)", vv.class, vv:GetName(), iRate, 1 / self.SERVER_RATE)
    --end
end

-----------------
ServerStats.GetEntityUpdateRate = function(self, sClass)

    return (self.UPDATE_RATES[sClass] or self.UPDATE_RATES["Default"])
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