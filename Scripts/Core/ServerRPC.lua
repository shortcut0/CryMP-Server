----------------
ServerRPC = {
    Callbacks = {
        -- OnUpdate
        -- OnTimer (s, m, h)

        -- OnConnection
        -- OnConnect
    },
}

----------------
ServerRPC.Init = function(self)

    eUpdateTimer_Tick   = 1
    eUpdateTimer_Minute = 2
    eUpdateTimer_Hour   = 3

    ServerLog("ServerRPC.Init()")
end

------------------------------------------------
--- CALLBACKS
ServerRPC.Callbacks.OnUpdate = function()
    Server:OnUpdate()
end

----------------
ServerRPC.Callbacks.OnTimer = function(self, iTimer)

    if (iTimer == eUpdateTimer_Tick) then
        Server:OnTick()

    elseif (iTimer == eUpdateTimer_Minute) then
        Server:OnMinuteTick()

    elseif (iTimer == eUpdateTimer_Hour) then
        Server:OnHourTick()

    end
end

----------------
ServerRPC.Callbacks.OnConnection = function(self, iChannel, sIP)

    if (ServerConnections) then
        ServerConnections:OnConnection(iChannel, sIP)
    end

end

----------------
ServerRPC.Callbacks.OnChannelDisconnect = function(self, iChannel, sIP)

    if (ServerConnections) then
        ServerConnections:OnConnectionClosed(iChannel, sIP)
    end

end

----------------
ServerRPC.Callbacks.OnChatMessage = function(self, iType, iSenderID, iTargetID, sMessage)

    -- FIXME: Check mutes here!
    -- CheckMutes() - ServerPunish ??
    -- if (not_muted) then
    return ServerChat:OnChatMessage(iType, iSenderID, iTargetID, sMessage)
    -- end
end
