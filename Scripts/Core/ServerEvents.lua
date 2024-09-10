------------------
ServerEvents = {
    LinkedEvents = {},
    AvailableEvents = {
    },

    EventKillCount = 1,
}

------------------

eServerEvent_OnScriptReload     = 1  -- ()           When Server gets re-initialized
eServerEvent_OnScriptInit       = 2  -- (status)     When Server Initialized
eServerEvent_ScriptUpdate       = 3  -- ()           When Server Initialized
eServerEvent_ScriptTick         = 4  -- ()           When Server Initialized
eServerEvent_ScriptMinuteTick   = 5  -- ()           When Server Initialized
eServerEvent_ScriptHourTick     = 6  -- ()           When Server Initialized
eServerEvent_OnClientInit       = 7  -- ()           When Server Initialized
eServerEvent_OnClientTick       = 8  -- ()           When Server Initialized
eServerEvent_OnUpdate           = 3  -- ()           When Server Initialized
eServerEvent_OnClientValidated  = 10  -- ()           When Server Initialized
eServerEvent_OnClientDisconnect = 11  -- ()           When Server Initialized
eServerEvent_SavePlayerData     = 12  -- ()           When Server Initialized
eServerEvent_OnServerInit       = 13  -- ()           When Server Initialized
eServerEvent_OnPostInit         = 14  -- ()           When Server Initialized

eServerEvent_ResolveSpawnLocation   = 15  -- ()           When Server Initialized
eServerEvent_OnClientRevived        = 16  -- ()           When Server Initialized
eServerEvent_OnHardwareIDReceived   = 17  -- ()           When Server Initialized
eServerEvent_OnHardwareIDReceived   = 17  -- ()           When Server Initialized
eServerEvent_OnExit                 = 18  -- ()           When Server Initialized
eServerEvent_SpectorTarget          = 19  -- ()           When Server Initialized
eServerEvent_OnShoot                = 20  -- ()           When Server Initialized
eServerEvent_MapReset               = 21  -- ()           When Server Initialized

eServerEvent_Begin          = 0
eServerEvent_End            = 22

------------------------------------
--- Init
ServerEvents.Init = function(self)

    self:RegisterEvents()
    self:ResetEvents()

    EventCall = function(...)
        return ServerEvents:CallEvent(...)
    end

    EventLink = function(...)
        return ServerEvents:LinkEvent(...)
    end

    CallEvent = EventCall -- ?
    LinkEvent = EventLink -- ??
end

------------------------------------
--- Init
ServerEvents.PostInit = function(self)

    --------
    -- test

    --testFUNCTION = function()ServerLog("called!!")  end

    -- All these below are working and can be used!
    -- LinkEvent(eServerEvent_ScriptTick, "ServerEvents", "Error")
    -- LinkEvent(eServerEvent_ScriptTick, "ServerEvents", "this_function_does_not_exist")
    -- LinkEvent(eServerEvent_ScriptTick, "this_host_does_not_exist", "this_function_does_not_exist")
    --LinkEvent(eServerEvent_ScriptTick, "ServerEvents.TestTick")
    --LinkEvent(eServerEvent_ScriptTick, ServerEvents, "ServerEvents.TestTick2")
    --LinkEvent(eServerEvent_ScriptTick, self, self.TestTick3)
    --LinkEvent(eServerEvent_ScriptTick, self, testFUNCTION)
    --LinkEvent(eServerEvent_ScriptTick, self, "testFUNCTION")

    --------
    local iTotalLinks = table.it(self.LinkedEvents, function(x, i, v) return ((x or 0) + table.count(v)) end)
    if (DebugMode()) then
        ServerLog(LOG_STARS .. LOG_STARS)
        ServerLog("[%02d] Server Server Events:", iTotalLinks)
        for iEvent, aLinked in pairs(self.LinkedEvents) do
            ServerLog(" > [% 2d] Linked Callbacks: % 2d", iEvent, table.count(aLinked))
        end
    end

    Logger:LogEventTo(GetDevs(), eLogEvent_ServerScripts, "Linked ${red}%d${gray} Server Events..", iTotalLinks)
end

------------------------------------
--- Init
ServerEvents.TestTick = function(self)
  ServerLog("test tick.. self is %s",table.lookup(_G,self))
end

------------------------------------
--- Init
ServerEvents.TestTick2 = function(self)
  ServerLog("[2] test tick.. self is %s",table.lookup(_G,self))
end

------------------------------------
--- Init
ServerEvents.TestTick3 = function(self)
  ServerLog("[3] test tick.. self is %s",table.lookup(_G,self))
end

------------------------------------
--- Init
ServerEvents.Error = function(self)
    this_function_does_not_exist()
end

------------------------------------
--- Init
ServerEvents.RegisterEvents = function(self)

end

------------------------------------
--- Init
ServerEvents.ResetEvents = function(self)

    for i = eServerEvent_Begin, eServerEvent_End do
        self.LinkedEvents[i] = {}
    end
end

------------------------------------
--- Init
ServerEvents.CallEvent = function(self, iEvent, ...)


    -- =================================================================================
    -- > We want a rewrite of this whole entire system
    -- > There is nothing wrong with using global pointers
    -- > In fact, it might even be faster than looking up their _G values all the time!!
    -- ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^


    local sError
    if (not isNumber(iEvent)) then
        sError = throw_error("attempt to call invalid event (bad identifier (" .. g_ts(iEvent) .. ")")
    elseif (iEvent <= eServerEvent_Begin or iEvent >= eServerEvent_End) then
        sError = throw_error("attempt to call invalid event (out of range)")
    end

    if (sError) then
        if (DebugMode()) then
            throw_error(sError)
        else


            HandleError("Execute Event (%d) Failed (%s)", sError)
            return ServerLogError(sError)
        end
    end

    local aEvents = self.LinkedEvents[iEvent]
    if (table.empty(aEvents)) then
        return
    end

    local hReturn
    local bOk, sErr
    local sHost, sFunc, hHost
    local aArgs = { ... }
    table.insert(aArgs, iEvent)

    for _, aInfo in pairs(aEvents) do

        hHost = aInfo.Global
        sHost = aInfo.Host
        sFunc = aInfo.Func

        --ServerLog(sHost.."."..sFunc)

        if (aInfo.Active) then
            if (DebugMode()) then
                hReturn = aInfo.Function(hHost, unpack(aArgs))
            else
                bOk, sErr = pcall(aInfo.Function, hHost, unpack(aArgs))
                if (not bOk or sErr) then

                    HandleError("Execute Event (%d) Failed (%s)", sErr)

                    ServerLogError("Execute Event %d for Host \"%s\" for function \"%s\" failed", iEvent, g_ts(sHost), g_ts(sFunc))
                    ServerLogError("%s", (sErr or "N/A"))
                    ServerLogError("%s", (debug.traceback() or "N/A"))

                    aInfo.Errors.Count = (aInfo.Errors.Count + 1)
                    if (aInfo.Errors.Count >= aInfo.Errors.KillCount) then
                        aInfo.Active = false
                        ServerLogError("Event %d for Host \"%s\" for function \"%s\" disabled", iEvent, g_ts(sHost), g_ts(sFunc))
                    end
                    aInfo.Errors.Last  = timernew(1)
                else
                   -- ServerLog(sHost.."."..sFunc or "nul")
                end
            end
        end
    end

    -- FIXME
    -- This returns only the most recent called event.
    -- this is bad!
    return hReturn
end

------------------------------------
--- Init
ServerEvents.LinkEvent = function(self, iEvent, sThis, hFunc)

    local sError
    if (not isNumber(iEvent)) then
        sError = ("attempt to link invalid event (bad identifier (" .. g_ts(iEvent) .. "))  ")
    elseif (iEvent <= eServerEvent_Begin or iEvent >= eServerEvent_End) then
        sError = ("attempt to link invalid event (out of range)")
    elseif (not isString(sThis)) then
       -- sError = ("due to performance issues, host for events cannot be a table")
    end

    if (sError) then
        if (DebugMode()) then
            error(sError)
        else
            HandleError("Event Linking Error (%s)", sError)
            return -- already done in func above ==> ServerLogError(sError)
        end
    end

    local hThis = sThis
    local hFirst, hLast
    local sFirst, sLast
    local sFunc, sHost
    local fFunc

    if (hFunc) then
        fFunc = hFunc
        sFunc = g_ts(hFunc)
        if (isString(fFunc)) then
            if (isString(sThis)) then
                fFunc = table.getnested(_G, string.format("%s.%s", sThis, fFunc))
                --ServerLog("func is string.. try lookup")
                if (fFunc == nil) then -- try without host
                    --ServerLog("try without host.. ")
                    fFunc = table.getnested(_G,fFunc)
                end
            else
               -- ServerLog("not found.. trying host lookup")
                fFunc = table.getnested(sThis,hFunc)
                if (fFunc == nil) then -- try with host prefixed
                   -- ServerLog("func is string, host is global, try global lookup..")
                    fFunc = table.getnested(_G,hFunc)
                end
            end
        end
    end

    if (isString(hThis)) then
        hThis, hFirst, hLast, sFirst, sLast = table.getnested(_G, sThis)
        if (fFunc == nil) then
            hThis = hFirst
            fFunc = hLast
            sFunc = sLast
        end

        sHost = sFirst
    else
        sHost = g_ts(table.lookup(_G, hThis) or "<null>")
    end

    sFunc = g_ts(table.lookup(hThis,fFunc) or table.lookup(_G,fFunc) or "<null>")

    if ( DebugMode()) then
        ServerLog("[Event] %s", g_ts(iEvent))
        ServerLog(" ==> This  : %s",g_ts(sThis))
        ServerLog(" ==> Host  : %s",g_ts(hThis))
        ServerLog(" ==> Global: %s",sHost)
        ServerLog(" ==> Func  : %s",g_ts(fFunc))
        ServerLog(" ==> FuncID: %s",sFunc)
    end

    if (fFunc == nil) then
        if (DebugMode()) then
            throw_error("fFunc is nil")
        else
            HandleError("function %s to link to event %d for host %s not found", g_ts(sFunc), g_ts(iEvent), g_ts(sHost))
            return
        end
    end

    table.insert(self.LinkedEvents[iEvent], {

        Active   = true,

        Function = fFunc,
        Func     = sFunc,
        Host     = sHost,
        Global   = hThis,

        Errors = {
            Count = 0,
            Last  = timernew(0),
            KillCount = self.EventKillCount
        }
    })



    --[[

    local fFunc = hFunc
    if (isString(fFunc)) then
        fFunc = checkGlobal(string.format("%s.%s", hThis, fFunc))
    end

    if (not isFunc(fFunc)) then
        error("attempt to link event with an invalid function")
    end

    table.insert(self.LinkedEvents[iEvent], {

        Active   = true,

        Function = fFunc,
        Func     = hFunc,
        Host     = hThis,

        Errors = {
            Count = 0,
            Last  = timernew(0),
            KillCount = self.EventKillCount
        }
    })]]
end