-------------------

PUNISH_BAN  = 0
PUNISH_KICK = 1
PUNISH_WARN = 2
PUNISH_MUTE = 3

eCheat_WeaponRate   = "FireRate"
eCheat_NoRecoil     = "NoRecoil"
eCheat_NoSpread     = "NoSpread"
eCheat_ClientSpeed  = "ClSpeed"
eCheat_ServerSpeed  = "SvSpeed"
eCheat_ClientPhys   = "Collider"
eCheat_ClientFly    = "Flying"
eCheat_ExpDistance  = "EDistance"
eCheat_BuySpoof     = "BuySpoof"

eCheat_ChatSpam     = "ChatSpam"
eCheat_ChatFlood    = "ChatFlood"

eCheat_DropItem  = "SvRequestDropItem" -- should align with RMI name
eCheat_UseItem   = "SvRequestUseItem" -- should align with RMI name
eCheat_PickItem  = "SvRequestPickupItem" -- should align with RMI name
eCheat_StopFire  = "SvRequestStopFire" -- should align with RMI name
eCheat_StartFire = "SvRequestStartFire" -- should align with RMI name

-------------------
ServerDefense = {

    LogTimers = {},
    ChatLogTimers = {},

    Detects = {},
    Config  = {

        -- Interval between logging cheats to console
        CheatLogInterval = 0.75,

        -- Interval between logging cheats to console
        ChatLogInterval = 5,

        -- Testing mode, no punishments will be given!
        TestMode = true,

        -- Timeout for detected cheats
        ActionTimeout = 120,

        -- a List of detected cheats that will be ignored (blocked, but ignored)
        Blacklist = {
            eCheat_StopFire,
            eCheat_StartFire,
            eCheat_DropItem,
        },

        ChatProtection = {

            FloodThreshold = 5, -- no more than this amount of any messages
            FloodTime      = 1, -- within this amount of time

            SpamThreshold  = 5, -- no more than this amount of the same message
            SpamTime       = 1, -- within this amount of time

        }, ---< ChatProtection

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
            [eCheat_ExpDistance]    = 3,

            [eCheat_ChatSpam]       = 1,
            [eCheat_ChatFlood]      = 1,
        },

        -- Actions to be performed once a cheater is being dealt with
        ActionPunishments = {

            [eCheat_DropItem]   = { Action = PUNISH_KICK },
            [eCheat_UseItem]    = { Action = PUNISH_KICK },
            [eCheat_PickItem]   = { Action = PUNISH_KICK },

            [eCheat_NoRecoil]   = { Action = PUNISH_BAN, Count = "1d" },
            [eCheat_NoSpread]   = { Action = PUNISH_BAN, Count = "1d" },

            [eCheat_ChatSpam]   = { Action = PUNISH_MUTE, Count = "30m" },
            [eCheat_ChatFlood]  = { Action = PUNISH_MUTE, Count = "30m" },
        }

    },

    -------------------
    Init = function(self)

        self.Config = ConfigGetMerge("General.AntiCheat", self.Config, self.Config, eConfigGet_Array)
        ServerLog(table.tostring(self.Config.Blacklist))
        table.checkM(self.Config, "ActionTimeout", 120)
        table.checkM(self.Config, "Blacklist", {})
        table.checkM(self.Config, "ActionPunishments", {})
        table.checkM(self.Config, "ActionThreshold", {})
        table.checkM(self.Config, "ClientCVars", {})
        table.checkM(self.Config, "ChatProtection", {})

        LinkEvent(eServerEvent_OnClientInit, "ServerDefense", self.InitClient)
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
        table.checkM(self.ChatLogTimers, iNetChannel, {  })
        table.checkM(self.LogTimers, iNetChannel, {  })
        table.checkM(self.Detects, iNetChannel, {})
    end,

    -------------------
    InitClient = function(self, hClient)
        hClient.SvChatTimer      = timernew(10) -- any number for initialisin..
        hClient.SvChatSpam       = 0  -- same message over and over
        hClient.SvChatFlood      = 0  -- flooding lots of messages

        hClient.SvBuyTimer       = timernew(0.5)
        hClient.BuyFlood         = 0
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
    CheckChatSpam = function(self, hPlayer, sMessage)

        local aConfig = self.Config.ChatProtection

        local iSpamThreshold  = aConfig.SpamThreshold   or 5
        local iSpamTime       = aConfig.SpamTime        or 1 -- no more than 5 messages with the same content within 1s
        local iFloodThreshold = aConfig.FloodThreshold  or 5
        local iFloodTime      = aConfig.FloodTime       or 1 -- no more than 5 messages within 1s

        local bExpiredSpam = (hPlayer.SvChatTimer.expired(iSpamTime))
        local bExpiredFlood = hPlayer.SvChatTimer.expired(iFloodTime)

        local bOk = true

        -- Check Spamming first
        if (not bExpiredSpam and sMessage == hPlayer.SvLastChatMessage) then
            hPlayer.SvChatSpam = (hPlayer.SvChatSpam + 1)
            if (hPlayer.SvChatSpam > iSpamThreshold) then
                bOk = false
                self:HandleCheater(hPlayer:GetChannel(), eCheat_ChatSpam, string.format("Spamming Chat (%d / %d)", hPlayer.SvChatSpam, iSpamThreshold), hPlayer.id, hPlayer.id, true)
                hPlayer.SvChatSpam = 0
            end
        else
            hPlayer.SvChatSpam = 0
        end

        -- If no spamming has been detected, check for flooding!
        if (bOk) then
            if (not bExpiredFlood) then
                hPlayer.SvChatFlood = (hPlayer.SvChatFlood + 1)
                if (hPlayer.SvChatFlood > iFloodThreshold) then
                    bOk = false
                    self:HandleCheater(hPlayer:GetChannel(), eCheat_ChatFlood, string.format("Flooding Chat (%d / %d)", hPlayer.SvChatFlood, iFloodThreshold), hPlayer.id, hPlayer.id, true)
                    hPlayer.SvChatFlood = 0
                end
            else
                hPlayer.SvChatFlood = 0
            end
        end

        hPlayer.SvLastChatMessage = sMessage
        hPlayer.SvChatTimer.refresh()

        return bOk
    end,

    -------------------
    CheckBuyFlood = function(self, hPlayer, sMessage)

        local bExpired = hPlayer.SvBuyTimer.expired()
        hPlayer.SvBuyTimer.refresh()

        if (not bExpired) then
            hPlayer.BuyFlood = (hPlayer.BuyFlood + 1)
            if (hPlayer.BuyFlood > 30) then
                return false
            end
        else
            hPlayer.BuyFlood = 0
        end

        return true
    end,

    -------------------
    CheckDistance = function(self, hPlayer, vFrom, vTo, sFunc)

        local iDistance = vector.distance(vFrom, vTo)
        if (iDistance < 120) then
            return true
        end

        self:HandleCheater(hPlayer:GetChannel(), ((sFunc or "") .. " Distance"), string.format("%0.2f > %0.2f", iDistance, 120.0), nil, nil, false)
        return false
    end,

    -------------------
    PunishCheater = function(self, iNetChannel, sCheat, sReason)

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

        elseif (hAction == PUNISH_MUTE) then
            if (hPlayer) then
                ServerPunish:MutePlayer(Server.ServerEntity, hPlayer, hActionC, sReason)
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
    HandleCheater = function(self, iNetChannel, sName, sDetect, hNetUserId, hVictimID, bSure, hP1, hP2)

        local aConfig = self.Config
        local sInfo   = string.match(sDetect, "^%w-:?:?Handle_(.*)") or sDetect
        if (table.findv(aConfig.Blacklist, sInfo)) then
            return ServerLog("Blocked Blacklisted Cheat %s from channel %d", sInfo, iNetChannel)
        end

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

        self:LogCheat(iNetChannel, sName, sInfo, bSure, bLagging, hVictimID, hNetUserId)
        if (bSure == true and self:GetDetects(iNetChannel, iTimeout, true, true) >= iThreshold) then
            self:PunishCheater(iNetChannel, sName, sDetect)
        end
    end,

    -------------------
    LogCheat = function(self, iNetChannel, sDetect, sInfo, bSure, bLag, hVictimID, hNetUserId)

        local iLogClass = RANK_PLAYER
        local sName     = "Channel " .. iNetChannel
        local hPlayer   = self:GetActor(iNetChannel)

        local hItem
        local sItems = "None"
        local sVictim = GetEntityName(hVictimID, "<Null>")
        local sNetUser = GetEntityName(hNetUserId, "<Null>")

        if (hPlayer) then
            sName = hPlayer:GetName()
            iLogClass = math.max(iLogClass, hPlayer:GetAccess())
            hItem = hPlayer:GetCurrentItem()
            sItems = hItem and hItem.class or "None"
        end

        ServerLog("[%s] Detected Cheat %s(%s) on [%s](%d)%s (Victim: %s, %s)",
                (bSure and "POSITIVE" or "UNCERTAIN"),
                (sDetect), (sInfo or sDetect),
                (bLag and "LAGGING" or "NORMAL"),
                iNetChannel, (hPlayer and hPlayer:GetName() or "<null>"),
                g_ts(hVictimID), ServerUtils.EntityName(hVictimID, "<null>")
        )


        if (self:CanLog(iNetChannel, sDetect)) then
            Logger:LogEventTo(GetPlayers({ Access = iLogClass }), eLogEvent_Cheat, "@l_ui_cheat_Detected", sName, sInfo, sDetect, (bSure and "Positive " or ""), (bLag and "${orange}Lagger ${red}" or ""))
            Logger:LogEventTo(GetPlayers({ Access = iLogClass }), eLogEvent_Cheat, string.format("${gray}NetUser ${orange}%s ${gray}Victim ${orange}%s", sNetUser, sVictim))
            Logger:LogEventTo(GetPlayers({ Access = iLogClass }), eLogEvent_Cheat, string.format("${gray}Equip ${orange}%s", sItems))
            self.LogTimers[iNetChannel][sDetect].refresh()
        end

        if (self:CanChatLog(iNetChannel, sDetect)) then
            SendMsg(CHAT_DEFENSE_LOCALE, GetPlayers({ Access = iLogClass }), "@l_ui_chat_cheatDetected", sName, sDetect, sInfo)
            self.ChatLogTimers[iNetChannel][sDetect].refresh()
        end


    end,

    -------------------
    CanChatLog = function(self, iNetChannel, sDetect)

        table.checkM(self.ChatLogTimers[iNetChannel], sDetect, timernew(self.Config.ChatLogInterval))
        return self.ChatLogTimers[iNetChannel][sDetect].expired()
    end,

    -------------------
    CanLog = function(self, iNetChannel, sDetect)

        table.checkM(self.LogTimers[iNetChannel], sDetect, timernew(self.Config.CheatLogInterval))
        return self.LogTimers[iNetChannel][sDetect].expired()
    end,

    -------------------
}
