-----------------------------
--- Player Connection Handler
ServerPCH = {
}

----------------
ServerPCH.Init = function(self)

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

    -- Just log
    Logger:LogEvent(eLogEvent_Connection, "${red}%s${grey} Connecting on Channel ${red}%d${gray} (${red}%s${gray})", sNick, iChannel, sIP)
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

    -- Just log
    Logger:LogEvent(eLogEvent_Connection, "{red}%s{gray} Connected on Channel %d", sName, iChannel)
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
    Logger:LogEvent(eLogEvent_Connection, "{red}%s{gray} Disconnecting from Channel %d (%s)", sName, iChannel, sReasonShort)
end

----------------
ServerPCH.GetShortReason = function(self, sMessage)

   local aShorts = {
       { "user left the game", "User left the Game" },
   }

    -- FIXME: Shorten the message!
    return (sMessage)
end