----------
RPC = {}

----------
RPC.Await = function(self, aParams, fCallback, iTimeout)
    -- TODO
end

----------
RPC.OnAll = function(self, a, b, c)


    local aRequest = {
        ID = UpdateCounter(eCounter_RPC),
    }
    if (type(b) == "string") then
        aRequest.class  = a
        aRequest.method = b
        aRequest.params = c or {}
    else
        aRequest.method = a
        aRequest.params = b or {}
    end

    local sRequest = json.encode(aRequest)
    g_gameRules.allClients:ClStartWorking(Server.ServerEntity.id, "@" .. sRequest)

    return aRequest
end

----------
RPC.OnPlayer = function(self, hClient, a, b, c)

    local aRequest = {
        ID = UpdateCounter(eCounter_RPC),
    }
    if (type(b) == "string") then
        aRequest.class  = a
        aRequest.method = b
        aRequest.params = c or {}
    else
        aRequest.method = a
        aRequest.params = b or {}
    end

    local sRequest = json.encode(aRequest)
    local iChannel = hClient:GetChannel()

    g_gameRules.onClient:ClStartWorking(iChannel, Server.ServerEntity.id, "@" .. sRequest)

    return aRequest
end

----------
RPC.OnOthers = function(self, player, a, b, c)

    local aRequest = {
        ID = UpdateCounter(eCounter_RPC),
    }
    if (type(b) == "string") then
        aRequest.class  = a
        aRequest.method = b
        aRequest.params = c or {}
    else
        aRequest.method = a
        aRequest.params = b or {}
    end

    local sRequest = json.encode(aRequest)
    local iChannel = hClient:GetChannel()

    g_gameRules.otherClients:ClStartWorking(iChannel, Server.ServerEntity.id, "@" .. sRequest)

    return aRequest
end

