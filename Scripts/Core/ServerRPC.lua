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

eUpdateTimer_Tick   = 1
eUpdateTimer_Minute = 2
eUpdateTimer_Hour   = 3

--------------------------------
--- Init
ServerRPC.Init = function(self)

    ServerLog("ServerRPC.Init()")
end

--------------------------------
--------------------------------
--- Init
ServerRPC.Callbacks.OnUpdate = function()
    Server:OnUpdate()
end

--------------------------------
--- Init
ServerRPC.Callbacks.OnTimer = function(self, iTimer)

    if (iTimer == eUpdateTimer_Tick) then
        Server:OnTick()

    elseif (iTimer == eUpdateTimer_Minute) then
        Server:OnMinuteTick()

    elseif (iTimer == eUpdateTimer_Hour) then
        Server:OnHourTick()

    end
end

--------------------------------
--- Init
ServerRPC.Callbacks.OnConnection = function(self, iChannel, sIP)

    if (ServerConnections) then
        ServerConnections:OnConnection(iChannel, sIP)
    end

end

--------------------------------
--- Init
ServerRPC.Callbacks.OnChannelDisconnect = function(self, iChannel, sIP)
    if (ServerConnections) then
        ServerConnections:OnConnectionClosed(iChannel, sIP)
    end
end

--------------------------------
--- Init
ServerRPC.Callbacks.OnClientDisconnect = function(self, iChannel, hClient, sReason)
    if (ServerConnections) then
        ServerConnections:OnDisconnected(hClient, sReason)
    end
end

--------------------------------
--- Init
ServerRPC.Callbacks.OnChatMessage = function(self, iType, iSenderID, iTargetID, sMessage)

    -- FIXME: Check mutes here!
    -- CheckMutes() - ServerPunish ??
    -- if (not_muted) then
    return ServerChat:OnChatMessage(iType, iSenderID, iTargetID, sMessage)
    -- end
end

--------------------------------
--- Init
ServerRPC.Callbacks.OnShoot = function(self, ...)
    return (ServerItemHandler:OnShoot(...) == true)
end

--------------------------------
--- Init
ServerRPC.Callbacks.OnLeaveWeaponModify = function(self, ...)
    return (ServerItemHandler:OnLeaveWeaponModify(...) == true)
end

--------------------------------
--- Init
ServerRPC.Callbacks.OnSwitchAccessory = function(self, ...)
    return (ServerItemHandler:OnSwitchAccessory(...) == true)
end
