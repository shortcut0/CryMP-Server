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
ServerRPC.Callbacks.OnCheat = function(self, iNetChannel, sName, sInfo, hVictimID, ...)

    if (ServerDefense) then
        ServerDefense:HandleCheater(iNetChannel, sName, sInfo, hVictimID, ...)
    else
        ServerLog("Cheater detected! channel %d, info %s (victim: %s)", iNetChannel, sInfo, g_ts(hVictimID))
    end
end

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

--------------------------------
--- Init
ServerRPC.Callbacks.CanPickupWeapon = function(self, ...)

    -- FIXME: AntiCheat
    if (ServerItemHandler:CanPickupWeapon(...) == true) then
        --ServerItemHandler:OnPickedUp(...)-- !!! BAD !!! CRASHES SERVER!!!!
        return true
    end
    return false
end

--------------------------------
--- Init
ServerRPC.Callbacks.CanDropWeapon = function(self, ...)

    -- FIXME: AntiCheat
    if (ServerItemHandler:CanDropWeapon(...) == true) then
        return true
    end

    return false
end

--------------------------------
--- Init
ServerRPC.Callbacks.CanUseWeapon = function(self, ...)

    -- FIXME: AntiCheat
    return (ServerItemHandler:CanUseWeapon(...) == true)
end

--------------------------------
--- Init
ServerRPC.Callbacks.OnWeaponPickedUp = function(self, hPlayerID, hItemID)
    ServerItemHandler:OnPickedUp(hPlayerID, hItemID)
end

--------------------------------
--- Init
ServerRPC.Callbacks.OnMapCommand = function(self, sMap)

    -- not called? REMOVE?
    throw_error("MAP CHANGED oMG oMG oMG")
end

--------------------------------
--- Init
ServerRPC.Callbacks.OnGameQuit = function()
    Server:Quit()
end

--------------------------------
--- Init
ServerRPC.Callbacks.OnMapStarted = function()
    Server:OnMapReset()
end

--------------------------------
--- Init
ServerRPC.Callbacks.OnBeforeSpawn = function(self, hParams)
    return (Server:OnBeforeSpawn(hParams) or hParams)
end

--------------------------------
--- Init
ServerRPC.Callbacks.OnProjectileExplosion = function(self, ...)
    return (ServerItemHandler:OnProjectileExplosion(...))
end

--------------------------------
--- Init
ServerRPC.Callbacks.OnExplosivePlaced = function(self, nPlayer, nExplosive, iType, iCount, iLimit)
    return (ServerItemHandler:OnExplosivePlaced(nPlayer, nExplosive, iType, iCount, iLimit))
end

--------------------------------
--- Init
ServerRPC.Callbacks.OnExplosiveRemoved = function(self, nPlayer, nExplosive, iType, iCount)
    return (ServerItemHandler:OnExplosiveRemoved(nPlayer, nExplosive, iType, iCount))
end

--------------------------------
--- Init
ServerRPC.Callbacks.OnProjectileHit = function(self, nShooter, nProjectile, iDamage, nWeapon, vPos, vNormal)
    return (ServerItemHandler:OnProjectileHit(nShooter, nProjectile, iDamage, nWeapon, vPos, vNormal))
end

--------------------------------
--- Init
ServerRPC.Callbacks.OnMelee = function(self, nPlayer, ...)

    if (ClientMod) then
        ClientMod:OnMelee(GetEntity(nPlayer), ...)
    end
end


--------------------------------
--- Init
ServerRPC.Callbacks.OnWalljump = function(self, hPlayerID, hItemID)

   --FIXME!!
end
