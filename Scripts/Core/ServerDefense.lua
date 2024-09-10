-------------------

PUNISH_BAN  = 0
PUNISH_KICK = 1
PUNISH_WARN = 2

eCheat_WeaponRate   = "FireRate"
eCheat_NoRecoil     = "NoRecoil"
eCheat_NoSpread     = "NoSpread"
eCheat_ClientSpeed  = "ClSpeed"
eCheat_ServerSpeed  = "SvSpeed"
eCheat_ClientPhys   = "Collider"
eCheat_ClientFly    = "Flying"

eCheat_DropItem = "SvRequestDropItem" -- should align with RMI name
eCheat_UseItem  = "SvRequestUseItem" -- should align with RMI name
eCheat_PickItem = "SvRequestPickupItem" -- should align with RMI name

-------------------
ServerDefense = {

    LogTimers = {},

    Detects = {},
    Config  = {

        -- Interval between logging cheats to console
        CheatLogInterval = 0.75,

        -- Testing mode, no punishments will be given!
        TestMode = true,

        -- Timeout for detected cheats
        ActionTimeout = 120,

        -- Required detects to take action against a cheater
        ActionThreshold = {

            ["Default"]             = 3,
            [eCheat_DropItem]       = 3,
            [eCheat_WeaponRate]     = 3,
            [eCheat_NoRecoil]       = 2,
            [eCheat_NoSpread]       = 2,
            [eCheat_ClientPhys]     = 3,
            [eCheat_ClientFly]      = 3,
            [eCheat_ClientSpeed]    = 3,
            [eCheat_ServerSpeed]    = 3,
        },

        -- Actions to be performed once a cheater is being dealt with
        ActionPunishments = {

            [eCheat_DropItem]   = { Action = PUNISH_KICK },
            [eCheat_UseItem]    = { Action = PUNISH_KICK },
            [eCheat_PickItem]   = { Action = PUNISH_KICK },

            [eCheat_NoRecoil]   = { Action = PUNISH_BAN, Count = "1d" },
            [eCheat_NoSpread]   = { Action = PUNISH_BAN, Count = "1d" },
        }

    },

    -------------------
    Init = function(self)

        self.Config = ConfigGet("General.AntiCheat", self.Config, eConfigGet_Array)
        table.checkM(self.Config, "ActionTimeout", 120)
        table.checkM(self.Config, "ActionPunishments", {})
        table.checkM(self.Config, "ActionThreshold", {})
        table.checkM(self.Config, "ClientCVars", {})
    end,

    -------------------
    GetDetects = function(self, iNetChannel, iTimeout, bWantNumber, bNoLag)

        local aDetects = {}
        for _, aInfo in pairs(self.Detects[iNetChannel] or {}) do
            if (iTimeout == nil or not aInfo.Time.expired(iTimeout)) then
                if (bNoLag == nil or aInfo.Lag ~= true) then
                    table.insert(aDetects, table.copy(aInfo))
                end
            end
        end

        if (bWantNumber) then
            return table.size(aDetects)
        end
        return aDetects
    end,

    -------------------
    InitChannel = function(self, iNetChannel)
        table.checkM(self.LogTimers, iNetChannel, {  })
        table.checkM(self.Detects, iNetChannel, {})
    end,

    -------------------
    GetActor = function(self, iNetChannel)
        return g_pGame:GetPlayerByChannelId(iNetChannel)
    end,

    -------------------
    CheckCVar = function(self, hPlayer, xHash, sVar, sVal)

        if (xHash ~= self.PlayerSyncHash) then
            return
        end
    end,

    -------------------
    CheckDistance = function(self, hPlayer, vFrom, vTo)

        local iDistance = vector.distance(vFrom, vTo)
        if (iDistance < 120) then
            return true
        end

        self:HandleCheater(hPlayer:GetChannel(), "Distance", string.format("%0.2f > %0.2f", iDistance, 120.0), nil, false)
        return false
    end,

    -------------------
    PunishCheater = function(self, iNetChannel, sCheat)

        local aConfig = self.Config
        local aPunishments = (aConfig.ActionPunishments or {})

        local sMessage = string.format("Detected Cheat: %s", g_ts(sCheat))
        local hPlayer  = self:GetActor(iNetChannel)
        local hAction  = PUNISH_KICK
        local hActionC = 0

        local aInfo = aPunishments[sCheat]
        if (aInfo) then
            hAction = (aInfo.Action or aInfo[1])
            hActionC = (aInfo.Count or aInfo[2]) -- warn count, ban time..
        end

        hActionC = ParseTime(hActionC)--checkNumber(hActionC, 0)

        if (hAction == PUNISH_WARN) then
            -- TODO!
            if (hPlayer) then
                -- Warn()
            else
                -- WriteWarn()
            end

        elseif (hAction == PUNISH_KICK) then
            if (hPlayer) then
                KickPlayer(hPlayer, sMessage, nil, "Server")
            else
                ServerPunish:DisconnectChannel(iNetChannel, eKickType_Kicked, sMessage, nil, "Server")
            end

        elseif (hAction == PUNISH_BAN) then
            if (hPlayer) then
                ServerPunish:BanPlayer(Server.ServerEntity, hPlayer, hActionC, sMessage)
            else
                ServerPunish:DisconnectChannel(iNetChannel, eKickType_Kicked, sMessage, nil, "Server")
            end

        else

            if (hPlayer) then
                KickPlayer(hPlayer, sMessage, nil, "Server")
            else
                ServerPunish:DisconnectChannel(iNetChannel, eKickType_Kicked, sMessage, nil, "Server")
            end
            HandleError("no action to deal with the cheater was found!")
        end
    end,

    -------------------
    HandleCheater = function(self, iNetChannel, sName, sDetect, hVictimID, bSure, hP1, hP2)

        local aConfig = self.Config
        local sInfo   = string.match(sDetect, "^%w-:?:?Handle_(.*)") or sDetect

        local iThreshold = (aConfig.ActionThreshold[sInfo] or aConfig.ActionThreshold["Default"] or 3)
        local iTimeout   = aConfig.ActionTimeout
        local bLagging   = false

        local hPlayer = self:GetActor(iNetChannel)
        if (hPlayer and hPlayer:IsLagging()) then
            bLagging = true
            bSure = false
        end

        self:InitChannel(iNetChannel) -- FIXME
        table.insert(self.Detects[iNetChannel], {
            Time = timernew(iTimeout),
            Info = sDetect,
            Name = sInfo,
            Lag  = bLagging
        })

        self:LogCheat(iNetChannel, sName, sInfo, bSure, bLagging, hVictimID)
        if (bSure and self:GetDetects(iNetChannel, iTimeout, true, true) >= iThreshold) then
            self:PunishCheater(iNetChannel, sName)
        end
    end,

    -------------------
    LogCheat = function(self, iNetChannel, sDetect, sInfo, bSure, bLag, hVictimID)

        local iLogClass = RANK_PLAYER
        local sName     = "Channel " .. iNetChannel
        local hPlayer   = self:GetActor(iNetChannel)
        if (hPlayer) then
            sName = hPlayer:GetName()
            iLogClass = math.max(iLogClass, hPlayer:GetAccess())
        end

        ServerLog("[%s] Detected Cheat %s(%s) on [%s](%d)%s (Victim: %s, %s)",
                (bSure and "POSITIVE" or "UNCERTAIN"),
                (sDetect), (sInfo or sDetect),
                (bLag and "LAGGING" or "NORMAL"),
                iNetChannel, (hPlayer and hPlayer:GetName() or "<null>"),
                g_ts(hVictimID), ServerUtils.EntityName(hVictimID, "<null>")
        )

        if (not self:CanLog(iNetChannel, sDetect)) then
            return
        end

        SendMsg(CHAT_DEFENSE_LOCALE, GetPlayers({ Access = iLogClass }), "@l_ui_chat_cheatDetected", sName, sDetect, sInfo)
        Logger:LogEventTo(GetPlayers({ Access = iLogClass }), eLogEvent_Cheat, "@l_ui_cheat_Detected", sName, sInfo, sDetect, (bSure and "Positive " or ""), (bLag and "${orange}Lagger ${red}" or ""))
        self.LogTimers[iNetChannel][sDetect].refresh()
    end,

    -------------------
    CanLog = function(self, iNetChannel, sDetect)

        table.checkM(self.LogTimers[iNetChannel], sDetect, timernew(self.CheatLogInterval))
        return self.LogTimers[iNetChannel][sDetect].expired()
    end,

    -------------------
}
