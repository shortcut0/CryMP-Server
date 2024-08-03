-----------------------------
--- Player Connection Handler
ServerPCH = {

    ValidationAPI = (ServerDLL.GetMasterServerAPI() .. "/validate.php"),
    ValidationBody = {
        prof = nil,
        uid  = nil
    },
    ValidationHeaders = {
        ["Content-Type"] = "application/json; charset=utf-8",
    },
}

----------------
ServerPCH.Init = function(self)
    ServerConnections = self
end

----------------
ServerPCH.ValidateClient = function(self, hClient, sProfile, sHash)

    ServerLog("Validating Client %s At %s", hClient:GetName(), self.ValidationAPI)
    ServerLog("Claimed ID: %s, Hash: %s", sProfile, sHash)

    self.ValidationBody.prof = sProfile
    self.ValidationBody.uid  = sHash

    ServerDLL.Request({
        url     = (self.ValidationAPI .. "?prof=" .. sProfile .. "&uid=" .. sHash),
        headers = self.ValidationHeaders,
        method  = "GET"
    }, function(...)
        self:OnValidation(hClient, ...)
    end)

end

----------------
ServerPCH.OnValidation = function(self, hClient, sError, sResponse, iCode)

    if (not ChannelExists(hClient:GetChannel())) then
        return ServerLogError("Client left before validation finished!")
    end

    local bOk = true
    if (iCode ~= 200) then
        bOk = false
    end

    if (sResponse ~= "%Validation:Successful%") then
        bOk = false
    end

    if (bOk) then

        ServerLog("Client Validted Successfully!")

        hClient.Info.Validated  = true
        hClient.Info.Validating = false
        hClient.InitTimer.setexpiry(0)
        hClient:Tick() -- Update!
    else

        ServerLog("Client Validation Failed!")
        ServerLog("(%d) %s", iCode, g_ts(sResponse))

        -- FIXME: Ban!
        -- Ban()

        hClient.Info.Validated  = false
        hClient.Info.Validating = false
    end

end

----------------
ServerPCH.OnConnection = function(self, iChannel, sIP)

    local sNick = (ServerDLL.GetChannelNick(iChannel) or "Nomad")

    -- FIXME: Check Bans Here!
    -- CheckBansHere(sIP)

    -- FIXME: Check VPNs Here!
    -- CheckVPN(sIP)

    -- FIXME: Check Country Here!
    -- CheckCountry(sIP)

    ServerChannels:InitChannel(iChannel, sIP)
    PlayerHandler:CreateClientInfo(iChannel, sIP)

    -- Just log
    Logger:LogEvent(eLogEvent_Connection, "@l_console_on_connection", sNick, iChannel, sIP)
end

----------------
ServerPCH.OnConnectionClosed = function(self, iChannel, sReason)

    local sReasonShort = (self:GetShortReason(sReason))
    local sNick = (ServerDLL.GetChannelNick(iChannel) or "Nomad")

    -- Just log
    Logger:LogEvent(eLogEvent_Connection, "@l_console_on_chandisconnect", (sNick or "Nomad"), iChannel, sReasonShort)
end

----------------
ServerPCH.OnConnected = function(self, hClient)

    local iChannel = (hClient.actor:GetChannel())
    local sName = (hClient:GetName())

    -- FIXME: Check Bans Here!
    -- CheckBansHere(hClient)

    -- FIXME: Check VPNs Here!
    -- CheckVPN(hClient)

    -- FIXME: Check Country Here!
    -- CheckCountry(hClient)

    -- FIXME: GOod place?
    ServerAccess:InitClient(hClient)

    -- Just log
    hClient.Connected = true
    Logger:LogEvent(eLogEvent_Connection, "@l_console_on_connected", sName, iChannel, hClient:GetProfileID())
end

----------------
ServerPCH.OnDisconnected = function(self, hClient, sReason)

    local sReasonShort = (self:GetShortReason(sReason))
    local iChannel = (hClient.actor:GetChannel())
    local sName = (hClient:GetName())

    -- FIXME: Check Bans Here!
    -- CheckBansHere(hClient)

    -- FIXME: Check VPNs Here!
    -- CheckVPN(hClient)

    -- FIXME: Check Country Here!
    -- CheckCountry(hClient)

    -- Just log
    Logger:LogEvent(eLogEvent_Connection, "@l_console_on_disconnected", sName, iChannel, sReasonShort)
end

----------------
ServerPCH.GetShortReason = function(self, sMessage)

    local iTimeout = string.match(sMessage, "no packet for (%d+) seconds")
    if (iTimeout) then
        return string.format("Timed out After %s", Logger.FormatTime(iTimeout))
    end

    local aShorts = {
        { "user left the game", "User Decision" },
    }

    local sShort = sMessage
    for _, aShort in pairs(aShorts) do
        if (string.find(string.lower(sMessage), string.lower(aShort[1]))) then
            sShort = aShort[2]
        end
    end

    -- FIXME: Shorten the message!
    return string.gsuba(sShort, {
        { f = "^Remote disconnected:", r = "" }
    })
end