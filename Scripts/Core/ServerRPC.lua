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

----------------
ServerRPC.OnUpdate = function(self)
end

----------------
ServerRPC.OnTimer = function(self, iTimer)
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

    if (ServerPCH) then
        ServerPCH:OnConnection(iChannel, sIP)
    end

end
