-----------------
ServerPunish = {

    DataDir  = (SERVER_DIR_DATA .. "Punish\\"),
    DataFile = "Punishments.lua",
    Data     = {},
    Default  = {
        Bans  = {
            --{
            --                Date   = GetTimestamp() - 1000,
            --                Expiry = GetTimestamp() + 60,
            --                Reason = "Test Ban",
            --                Admin  = { "0", "Server" },
            --                Player = { "0", "Player !!" },
            --                IPs    = { "!127.0.0.1" },
            --                Host   = { "!1234.net.com" },
            --                IDs    = { "!1007757" },
            --                HWIDs  = { }
            --            }
        },
        Mutes = {},
        Warns = {},
    },

}

-----------------

ePunishType_Ban  = "Bans"
ePunishType_Mute = "Mutes"
ePunishType_Warn = "Warns"

-----------------

BAN_EXPIRED      = "Ban Expired"
MUTE_EXPIRED     = "Mute Expired"
WARN_EXPIRED     = "Warn Expired"

-----------------

eKickType_Timeout                 = 0
eKickType_ProtocolError           = 1
eKickType_ResolveFailed           = 2
eKickType_VersionMismatch         = 3
eKickType_ServerFull              = 4
eKickType_Kicked                  = 5
eKickType_Banned                  = 6
eKickType_ContextCorruption       = 7
eKickType_AuthenticationFailed    = 8
eKickType_NotLoggedIn             = 9
eKickType_CDKeyCheckFailed        = 10
eKickType_GameError               = 11
eKickType_NotDX10Capable          = 12
eKickType_NubDestroyed            = 13
eKickType_ICMPError               = 14
eKickType_NatNegError             = 15
eKickType_PunkDetected            = 16
eKickType_DmoPlaybackFinished     = 17
eKickType_DmoPlaybackFileNotFound = 18
eKickType_UserRequested           = 19
eKickType_NoController            = 20
eKickType_CantConnect             = 21
eKickType_ModMismatch             = 22
eKickType_MapNotFound             = 23
eKickType_MapVersion              = 24
eKickType_Unknown                 = 25

-----------------
ServerPunish.Init = function(self)

    GetBan     = self.GetBan
    KickPlayer = function(...) return self:DisconnectPlayer(eKickType_Kicked, ...) end

    self:LoadData()

    Logger:LogEventTo(RANK_MODERATOR, eLogEvent_Punish, "@l_ui_loaded_mutes", table.count(self.Data.Mutes))
    Logger:LogEventTo(RANK_MODERATOR, eLogEvent_Punish, "@l_ui_loaded_bans",  table.count(self.Data.Bans))
    Logger:LogEventTo(RANK_MODERATOR, eLogEvent_Punish, "@l_ui_loaded_warns", table.count(self.Data.Warns))

    LinkEvent(eServerEvent_ScriptTick, "ServerPunish", self.OnTick)
    LinkEvent(eServerEvent_OnScriptReload, "ServerPunish", self.SaveData)
    LinkEvent(eServerEvent_OnClientValidated, "ServerPunish", self.Ban_CheckProfile)
    LinkEvent(eServerEvent_OnHardwareIDReceived, "ServerPunish", self.CheckHardwareID)

    self.MaxBanTime = ConfigGet("Server.Punishment.MaximumBanTime", ONE_YEAR, eConfigGet_Number)
    self.DefaultBanTime = ConfigGet("Server.Punishment.DefaultBanTime", ONE_DAY, eConfigGet_Number)
    self.MaxMuteTime = ConfigGet("Server.Punishment.MaximumMuteTime", ONE_YEAR, eConfigGet_Number)
    self.DefaultMuteTime = ConfigGet("Server.Punishment.DefaultMuteTime", ONE_DAY, eConfigGet_Number)
    self.UseHardwareBans = ConfigGet("Server.Punishment.UseHardwareBans", true, eConfigGet_Boolean)

    self.Mangers = {
        Bans = RANK_ADMIN,
        Mutes = RANK_MODERATOR,
        Warns = RANK_MODERATOR
    }
end

-----------------
ServerPunish.FormatBanReason = function(self, aBanInfo)
    return string.format("%s | Admin: %s | Time Remaining: %s", (aBanInfo.Reason or "No Reason."), aBanInfo:GetAdmin(), math.calctime(aBanInfo:GetRemaining(), nil, 3))
end

-----------------
ServerPunish.FormatMuteReason = function(self, aMuteInfo)
end

-----------------
ServerPunish.SendBanReason = function(self, iChannel, aBanInfo)

    local hClient = g_pGame:GetPlayerByChannelId(iChannel)
    local f = function(m, bNoSpace)
        g_pGame:SendTextMessage(TextMessageConsole, string.mspace(string.rspace(m, (bNoSpace and 0 or 50), string.COLOR_CODE), CLIENT_CONSOLE_LEN, nil, string.COLOR_CODE), TextMessageToClient, hClient and hClient.id or iChannel)
    end

    -- You can send messages to a channel but since game rules doesn't exist in the main menu, the client won't receive them unless they are fully connected to the server.
    f ("$9====================================================")
    f ("$9 Connection $4Denied.", 1)
    f ("$9     > Banned By: $5" .. (aBanInfo:GetAdmin()))
    f ("$9     > Reason:    $1" .. math.calctime(aBanInfo:GetReason()))
    f ("$9     > Remaining: $4" .. (aBanInfo:GetRemaining()))
    f ("$9     > Appeal:    $4" .. ("Discord.com @shortcut0"))
    f ("$9====================================================")
end

-----------------
ServerPunish.Ban_CheckProfile = function(self, hPlayer, sID)

    local aBanInfo = self:GetInfoForType(ePunishType_Ban, sID)
    if (aBanInfo) then
        self:SendBanReason(hPlayer:GetChannel(), aBanInfo)
        self:DisconnectPlayer(eKickType_Banned, hPlayer, self:FormatBanReason(aBanInfo), aBanInfo.Reason)
    end

    return (aBanInfo ~= nil)
end

-----------------
ServerPunish.Ban_CheckHardware = function(self, hPlayer, sID)

    local aBanInfo = self:GetInfoForType(ePunishType_Ban, sID)
    if (aBanInfo) then
        self:SendBanReason(hPlayer:GetChannel(), aBanInfo)
        self:DisconnectPlayer(eKickType_Banned, hPlayer, self:FormatBanReason(aBanInfo), aBanInfo.Reason)
    end

    return (aBanInfo ~= nil)
end

-----------------
ServerPunish.Ban_CheckPlayer = function(self, hPlayer)

    local sIP   = hPlayer:GetIP()
    local sHost = hPlayer:GetHostName()
    local sID   = hPlayer:IsValidated() and hPlayer:GetProfileID()
    local sHWID = hPlayer:GetHWID()

    local aBanInfo = self:GetInfoForType(ePunishType_Ban, { sIP, sHost, sID, sHWID })
    if (aBanInfo) then
        self:SendBanReason(hPlayer:GetChannel(), aBanInfo)
        self:DisconnectPlayer(eKickType_Banned, hPlayer, self:FormatBanReason(aBanInfo), aBanInfo.Reason)
    end

    return (aBanInfo ~= nil)
end

-----------------
ServerPunish.Ban_CheckChannel = function(self, iChannel, sIP, sHost)

    local aBanInfo = self:GetInfoForType(ePunishType_Ban, { sIP, sHost })
    if (aBanInfo) then
        self:SendBanReason(iChannel, aBanInfo)
        self:DisconnectChannel(eKickType_Banned, iChannel, self:FormatBanReason(aBanInfo), aBanInfo.Reason)
    end

    return (aBanInfo ~= nil)
end

-----------------
ServerPunish.Mute_CheckPlayer = function(self, hPlayer, sMessage)

    if (not hPlayer.IsPlayer) then
        return nil
    end

    local sIP       = hPlayer:GetIP()
    local sHost     = hPlayer:GetHost()
    local sID       = hPlayer:GetProfileID()
    local sStatic   = hPlayer:GetStaicID()
    local sHWID     = hPlayer:GetHWID()

    local aMuteInfo = self:GetInfoForType(ePunishType_Mute, { sIP, sHost, sID, sStatic, sHWID })
    if (aMuteInfo) then
        return aMuteInfo
    end

    return (nil)
end

-----------------
ServerPunish.MutePlayer = function(self, hAdmin, hPlayer, sTime, sReason)


    sReason         = (sReason or "Server Decision")

    local sIP       = hPlayer:GetIP()
    local sHost     = hPlayer:GetHost()
    local sID       = hPlayer:GetProfileID()

    -- mutes are more forgiving..
    local sStatic   = hPlayer:GetStaicID()
    local sHWID     = hPlayer:GetHWID()

    if (self:GetInfoForType(ePunishType_Mute, { sIP, sHost, sID })) then
        return false, hAdmin:Localize("@l_ui_playerAlreadyMuted", { hPlayer:GetName() })
    end

    local iMax = self.MaxMuteTime
    if (hAdmin:IsDeveloper()) then iMax = (LUA_MAX_INTEGER - GetTimestamp() - 1) end
    local iMuteTime = math.max(0, math.min(iMax, (ParseTime(sTime) or self.DefaultMuteTime)))
    if (not iMuteTime or iMuteTime == 0) then
        iMuteTime = ONE_HOUR
    end

    local iTimestamp = GetTimestamp()
    local aMuteInfo = {
        Date   = iTimestamp,
        Expiry = g_ts(iTimestamp + iMuteTime),
        Reason = sReason,
        Admin  = { hAdmin:GetProfileID(), hAdmin:GetName() },
        Player = { hPlayer:GetProfileID(), hPlayer:GetName() },
        IPs    = { sIP, sHost },
        IDs    = { sID },
    }
    self:SetupEntry(aMuteInfo, (self:GetTypeCount(ePunishType_Mute) + 1))

    -- X Has been Muted by Admin for 1d (Ruuuuuuleee Break)
    Logger:LogEvent(eLogEvent_Punish, "@l_ui_playerMutedByShort", hPlayer:GetName(), hAdmin:GetName(), math.calctime(iMuteTime, nil, 3), sReason)

    hPlayer:SetMute(aMuteInfo)

    table.insert(self.Data[ePunishType_Mute], aMuteInfo)
    self:SaveData()
    return true
end

-----------------
ServerPunish.TryRemoveMute = function(self, hAdmin, hPlayer)

    local aMuteInfo = self:GetInfoByName(ePunishType_Mute, hPlayer)
    if (not aMuteInfo) then
        aMuteInfo = self:GetInfoByIDs(ePunishType_Mute, hPlayer, { "IDs", "IPs" })
    end

    if (not aMuteInfo) then
        return false, hAdmin:Localize("@l_ui_muteNotFound", { hPlayer })
    end

    self:RemoveType(ePunishType_Mute, aMuteInfo, self.Data[ePunishType_Mute], aMuteInfo:GetIndex(), "Admin Decision")
    return true
end

-----------------
ServerPunish.CheckHardwareID = function(self, hPlayer, sID)
    throw_error("implementation missing")
end

-----------------
ServerPunish.OnTick = function(self)

    local iRemoved = 0
    for sType, aList in pairs(self.Data) do
        for iID, aInfo in pairs(aList) do

            aInfo.ID = iID
            if (aInfo:Expired()) then

                self:RemoveType(sType, aInfo, self.Data[sType], iID, BAN_EXPIRED)
                iRemoved = (iRemoved + 1)
            end
        end
    end

    if (iRemoved >= 1 or self.SaveQueued) then
        self:SaveData()
    end

end

-----------------
ServerPunish.TryRemoveBan = function(self, hAdmin, hPlayer)

    local aBanInfo = self:GetInfoByName(ePunishType_Ban, hPlayer)
    if (not aBanInfo) then
        aBanInfo = self:GetInfoByIDs(ePunishType_Ban, hPlayer, { "IDs", "IPs" })
    end

    if (not aBanInfo) then
        return false, hAdmin:Localize("@l_ui_banNotFound", { hPlayer })
    end

    self:RemoveBan(aBanInfo, self.Data[ePunishType_Ban], aBanInfo:GetIndex(), "Admin Decision")
    return true
end

-----------------
ServerPunish.GetInfoByIDs = function(self, iType, sCheck, aCheckList)

    local aList = self.Data[iType]
    if (table.empty(aList)) then
        return
    end

    local aResult
    local aScan
    for _, aInfo in pairs(aList) do
        aScan = {}
        for __, sMem in pairs(aCheckList) do
            table.appendA(aScan, aInfo[sMem])
        end

        for __, sID in pairs(aScan) do
            if (sCheck == sID) then
                aResult = aInfo
            end
        end
    end
    return aResult
end

-----------------
ServerPunish.GetInfoByName = function(self, iType, sName)

    local aList = self.Data[iType]
    if (table.empty(aList)) then
        return
    end

    local aResult
    local bExactMatch
    for _, aInfo in pairs(aList) do
        bExactMatch = string.lower(aInfo:GetName()) == string.lower(sName)
        if (bExactMatch or string.match(aInfo:GetName(), sName)) then
            if (aResult) then
                return
            end
            aResult = aInfo

            -- Avoid filter collisions
            if (bExactMatch) then
                break
            end
        end
    end
    return aResult
end

-----------------
ServerPunish.BanPlayer = function(self, hAdmin, hPlayer, sTime, sReason)

    local sIP       = hPlayer:GetIP()
    local sHost     = hPlayer:GetHost()
    local sID       = hPlayer:GetProfileID()
    local sStatic   = hPlayer:GetStaicID()
    local sHWID     = hPlayer:GetHWID()

    local aOldInfo = self:GetInfoForType(ePunishType_Ban, { sIP, sHost, sID, sStatic, sHWID })
    if (aOldInfo) then
        return false, hAdmin and hAdmin:Localize("@l_ui_playerAlreadyBanned", {hPlayer:GetName(), aOldInfo:GetIndex()})
    end

    local iMax = self.MaxBanTime
    if (hAdmin and hAdmin:IsDeveloper()) then iMax = (LUA_MAX_INTEGER - GetTimestamp() - 1) end
    local iBanTime = math.max(0, math.min(iMax, (ParseTime(sTime) or self.DefaultBanTime)))
    if (not iBanTime or iBanTime == 0) then
        iBanTime = ONE_HOUR
    end

    local iTimestamp = GetTimestamp()
    local aBanInfo = {
        Date   = iTimestamp,
        Expiry = g_ts(iTimestamp + iBanTime),
        Reason = (sReason or "Server Decision"),
        Admin  = { hAdmin and hAdmin:GetProfileID() or SERVERENT_ID, hAdmin and hAdmin:GetName() or "Server" },
        Player = { hPlayer:GetProfileID(), hPlayer:GetName() },
        Host   = { sHost },
        IPs    = { sIP },
        IDs    = { sID, sStatic },
        HWIDs  = { sHWID }
    }
    self:SetupEntry(aBanInfo, (self:GetTypeCount(ePunishType_Ban) + 1))

    table.insert(self.Data.Bans, aBanInfo)
    self:SaveData()

    self:SendBanReason(hPlayer:GetChannel(), aBanInfo)
    self:DisconnectPlayer(eKickType_Banned, hPlayer, self:FormatBanReason(aBanInfo), aBanInfo.Reason, hAdmin and hAdmin:GetName() or "Server")
    return true
end

-----------------
ServerPunish.IsManager = function(self, hAdmin, iType)
    local iAccess  = hAdmin:GetAccess()
    local iManager = self.Mangers[iType]
    return (iAccess >= iManager), iManager
end

-----------------
ServerPunish.ListBans = function(self, hAdmin, hIndex, hOption)

    local bManager, iManager = self:IsManager(hAdmin, ePunishType_Ban)
    local aBans = DebugMode() and {
        self:SetupEntry({
            Date   = GetTimestamp() - 1000,
            Expiry = GetTimestamp() + 60,
            Reason = "Test Ban",
            Admin  = { "0", "Server" },
            Player = { "0", "Player !!" },
            IPs    = { "!127.0.0.1" },
            Host   = { "!1234.net.com" },
            IDs    = { "!1007757" },
            HWIDs  = { }
        },1),
        self:SetupEntry({
            Date   = GetTimestamp() - 4000,
            Expiry = GetTimestamp() + 80,
            Reason = "Test Ban",
            Admin  = { "10", "Server666" },
            Player = { "10", "Player !!666" },
            IPs    = { "!127.0.5.1" },
            Host   = { "!123666.net.com" },
            IDs    = { "!88838" },
            HWIDs  = { }
        },2),
    } or self.Data.Bans
    local iBans = table.count(aBans)
    if (iBans == 0) then
        return false, hAdmin:Localize("@l_ui_noBansFound")
    end

    hIndex = string.lower(hIndex or "list")
    hOption = string.lower(hOption or "")

    if (bManager) then
        if (hIndex == "flush") then

            self.Data.Bans = {}
            self:QueueSaveFile()

            Logger:LogEventTo(GetPlayers({ iManager }), eLogEvent_Punish, "@l_ui_bansFlushed", iBans, ("$4" .. hAdmin:GetName() .. " $9"))
            return true, string.gsub(hAdmin:Localize("@l_ui_bansFlushed", { iBans, "" }), string.COLOR_CODE, "")--SendMsg(CHAT_SERVER, hAdmin, hAdmin:Localize("@l_ui_bansFlushed", { iBans, "" }))
        end

        if (hIndex == "refresh") then
            for _, hPlayer in pairs(GetPlayers()) do
                self:Ban_CheckPlayer(hPlayer)
            end
            return true, hAdmin:Localize("@l_ui_bansRefreshed", { iBans })
        end
    end

    local aBanInfo = aBans[hIndex]
    if (aBanInfo) then

        if (bManager and IsAny(hOption, "unban", "remove", "erase", "delete", "flush")) then
            self:RemoveType(ePunishType_Ban, aBanInfo, self.Data[ePunishType_Ban], aBanInfo:GetIndex(), "@l_ui_adminDecision")
            return true, hAdmin:Localize("@l_ui_banRemovedId", { aBanInfo:GetName(), hIndex })
        end

        local iLeftWidth = 24 + 8
        local iRightWidth = 45 - 8

        local sBanName  = string.rspace(aBanInfo:GetName(),     iLeftWidth, string.COLOR_CODE)
        local sBanAdmin = string.rspace(aBanInfo:GetAdmin(),    iRightWidth, string.COLOR_CODE)
        local sBanIndex = string.rspace(aBanInfo:GetIndex(),    iRightWidth - 1, string.COLOR_CODE)
        local sBanIP    = string.rspace(aBanInfo:GetIP(1),      iLeftWidth, string.COLOR_CODE)
        local sBanHost  = string.rspace(aBanInfo:GetHost(1),    iRightWidth, string.COLOR_CODE)
        local sBanID    = string.rspace(aBanInfo:GetProfile(1), iLeftWidth, string.COLOR_CODE)
        local sBanAgo   = string.rspace(aBanInfo:GetElapsed(1),  iRightWidth, string.COLOR_CODE)
        local sBanExpire= string.rspace(aBanInfo:GetExpiry(1),   iRightWidth, string.COLOR_CODE)
        local sBanReason= string.rspace(aBanInfo:GetReason(),   iLeftWidth, string.COLOR_CODE)
        local sBanDate  = string.rspace(aBanInfo:GetDate(1),     iLeftWidth, string.COLOR_CODE)

        SendMsg(MSG_CONSOLE, hAdmin, '$9================================================================================================================')
        SendMsg(MSG_CONSOLE, hAdmin, string.format('$9[           Name | $1%s $9]            Entry | #$8%s $9]', sBanName, sBanIndex))
        SendMsg(MSG_CONSOLE, hAdmin, string.format('$9[             IP | $9%s $9]           Domain | $9%s $9]',  sBanIP, sBanHost))
        SendMsg(MSG_CONSOLE, hAdmin, string.format('$9[        Profile | $9%s $9]          Elapsed | $4%s $9]',  sBanID, sBanAgo))
        SendMsg(MSG_CONSOLE, hAdmin, string.format('$9[         Reason | $4%s $9]           Expiry | $4%s $9]',  sBanReason, sBanExpire))
        SendMsg(MSG_CONSOLE, hAdmin, string.format('$9[      Timestamp | $9%s $9]        Banned by | $5%s $9]',  sBanDate, sBanAdmin))
        SendMsg(MSG_CONSOLE, hAdmin, '$9================================================================================================================')
        SendMsg(CHAT_SERVER, hAdmin, hAdmin:LocalizeNest("@l_ui_openYourConsoleToViewThe", {hIndex, "@l_ui_banEntry"}))
    else
        SendMsg(MSG_CONSOLE, hAdmin, '$9================================================================================================================')
        SendMsg(MSG_CONSOLE, hAdmin, '$9       Name                   Reason                Admin                 Date                    Expiry')
        --SendMsg(MSG_CONSOLE, hAdmin, '$9================================================================================================================')
        for i, aInfo in pairs(aBans) do
            local sLine = string.format('$9[ $1%02d $9] $9%s $9| $4%s $9| $5%s $9| $9%s $9| $4%s$9]',
                    i,
                    string.rspace(string.sub(aInfo:GetName(), 1, 20), 20, string.COLOR_CODE),
                    string.rspace(string.sub(aInfo:GetReason(), 1, 19), 19, string.COLOR_CODE),
                    string.rspace(string.sub(aInfo:GetAdmin(), 1, 19), 19, string.COLOR_CODE),
                    string.rspace(aInfo:GetDate(1), 21, string.COLOR_CODE),
                    string.rspace(aInfo:GetExpiry(1, 6), 21, string.COLOR_CODE)
            )
            SendMsg(MSG_CONSOLE, hAdmin, sLine)
        end
        SendMsg(MSG_CONSOLE, hAdmin, '$9================================================================================================================')
        SendMsg(CHAT_SERVER, hAdmin, hAdmin:LocalizeNest("@l_ui_openYourConsoleToViewThe", {iBans, "@l_ui_bans"}))
    end
end

-----------------
ServerPunish.BanChannel = function(self, hAdmin, iChannel, sTime, sReason)

    local sIP       = ServerDLL.GetChannelIP(iChannel)
    local sNick     = (ServerDLL.GetChannelNick(iChannel) or "Nomad")

    local aBanInfo = self:GetInfoForType(ePunishType_Ban, { sIP })
    if (aBanInfo) then
        return false, hAdmin:Localize("@l_ui_playerAlreadyBanned", {aBanInfo:GetName(), aBanInfo:GetIndex()})
    end

    local iMax = self.MaxBanTime
    if (hAdmin:IsDeveloper()) then iMax = (LUA_MAX_INTEGER - GetTimestamp() - 1) end
    local iBanTime = math.max(0, math.min(iMax, (ParseTime(sTime) or self.DefaultBanTime)))
    if (not iBanTime or iBanTime == 0) then
        iBanTime = ONE_HOUR
    end

    local iTimestamp = GetTimestamp()
    local aBanInfo = {
        Date   = iTimestamp,
        Expiry = g_ts(iTimestamp + iBanTime),
        Reason = (sReason or "Server Decision"),
        Admin  = { hAdmin:GetProfileID(), hAdmin:GetName() },
        Player = { "-1", sNick },
        IPs    = { sIP },
        IDs    = {  },
        HWIDs  = {  }
    }
    self:SetupEntry(aBanInfo, (self:GetTypeCount(ePunishType_Ban) + 1))

    table.insert(self.Data.Bans, aBanInfo)

    self:SendBanReason(iChannel, aBanInfo)
    self:DisconnectPlayer(eKickType_Banned, sNick, self:FormatBanReason(aBanInfo), aBanInfo.Reason, hAdmin:GetName())
    self:SaveData()
    return true
end

-----------------
ServerPunish.DisconnectPlayer = function(self, iType, hPlayer, sReason, sLogReason, sAdmin)

    sReason = (sReason or "Server Decision")

    local sLocale = "@l_ui_player_kicked"
    if (iType == eKickType_Banned) then
        sLocale = "@l_ui_player_banned"
    end

    SendMsg(MSG_ERROR, ALL_PLAYERS, (sLocale .. "_by"), hPlayer:GetName(), (sLogReason or sReason))
    Logger:LogEvent(eLogEvent_Punish, sLocale, hPlayer:GetName(), (sLogReason or sReason), sAdmin or "Server")
    hPlayer:SetBanned(true)

    --Script.SetTimer(1, function()
        ServerDLL.KickChannel(iType, hPlayer:GetChannel(), sReason)
    --end)
end

-----------------
ServerPunish.DisconnectChannel = function(self, iType, iChannel, sReason, sLogReason, sAdmin)

    sReason = (sReason or "Server Decision")

    local sLocale = "@l_ui_channel_kicked"
    if (iType == eKickType_Banned) then
        sLocale = "@l_ui_channel_banned"
    end

    SendMsg(MSG_ERROR, ALL_PLAYERS, (sLocale .. "_by"), iChannel, (sLogReason or sReason), sAdmin or "Server")
    Logger:LogEvent(eLogEvent_Punish, sLocale, iChannel, (sLogReason or sReason))
    ServerChannels:OnChannelBanned(iChannel)
    ServerDLL.KickChannel(iType, iChannel, sReason)
end

-----------------
ServerPunish.GetInfoForType = function(self, hType, hIdentifier)

    local aBanInfo
    local aInfoList = self.Data[hType]
    if (table.empty(aInfoList)) then
        return
    end

    for iBan, aInfo in pairs(aInfoList) do
        if (not aInfo:Expired()) then
            for _, sID in pairs({
                unpack(aInfo.Host),
                unpack(aInfo.IPs),
                unpack(aInfo.IDs),
                unpack(self:GetHardwareIDs(aInfo))
            }) do
                if (isArray(hIdentifier)) then
                    for _, sCheck in pairs(hIdentifier) do
                        if (sCheck == sID) then
                            aBanInfo = aInfo
                            break
                        end
                    end
                else
                    if (sID == hIdentifier) then
                        aBanInfo = aInfo
                    end
                end

                if (aBanInfo) then
                    break
                end
            end
        else

            -- FIXME
            self:RemoveType(hType, aInfo, self.Data[hType], iBan, "Expired")
        end
    end

    if (table.empty(aBanInfo)) then
        return
    end
    return aBanInfo
end

-----------------
ServerPunish.GetHardwareIDs = function(self, aInfo)
    if (not self.UseHardwareBans) then
        return {}
    end

    return (aInfo.HWIDs or {})
end

-----------------
ServerPunish.GetTypeCount = function(self, hType)

    if (IsAny(hType, ePunishType_Warn, ePunishType_Mute, ePunishType_Ban)) then
        return table.count(self.Data[hType])

    else
        throw_error("bad type for remove punishment")
    end
end

-----------------
ServerPunish.RemoveType = function(self, hType, ...)

    if (hType == ePunishType_Ban) then
        return self:RemoveBan(...)

    elseif (hType == ePunishType_Mute) then
        return self:RemoveMute(...)

    elseif (hType == ePunishType_Warn) then
        return self:RemoveWarn(...)

    else
        throw_error("bad type for remove punishment")
    end
end

-----------------
ServerPunish.RemoveBan = function(self, aBanInfo, aList, hID, sReason)

    -- FIXME: Log!
    Logger:LogEvent(eLogEvent_Punish, "@l_ui_ban_removed", aBanInfo:GetName(), sReason)

    -- Delete
    --if (not aList[hID]) then
    --    return false
    --end

    aList[hID] = nil
    self:QueueSaveFile()
end

-----------------
ServerPunish.RemoveMute = function(self, aBanInfo, aList, hID, sReason)

    -- FIXME: Log!
    Logger:LogEvent(eLogEvent_Punish, "@l_ui_mute_removed", aBanInfo:GetName(), sReason)

    local bOk
    local sIP, sHost, sProfile, sStatic, sHWID
    for _, hPlayer in pairs(GetPlayers()) do

        sIP       = hPlayer:GetIP()
        sHost     = hPlayer:GetHost()
        sProfile  = hPlayer:GetProfileID()
        sStatic   = hPlayer:GetStaicID()
        sHWID     = hPlayer:GetHWID()

        bOk = false

        for __, sID in pairs({
            unpack(aBanInfo.Host),
            unpack(aBanInfo.IPs),
            unpack(aBanInfo.IDs),
            unpack(self:GetHardwareIDs(aBanInfo))
        }) do
            for ___, sCheck in pairs({
                sIP, sHost, sID, sStatic, sHWID
            }) do
                if (sCheck == sID) then
                    SendMsg(CHAT_SERVER_LOCALE, hPlayer, "@l_ui_youHaveBeenUnMuted", sReason)
                    hPlayer:RemoveMute()
                    bOk = true
                    break
                end
            end
            if (bOk) then break end
        end
    end

    -- Delete
    aList[hID] = nil
    self:QueueSaveFile()
end

-----------------
ServerPunish.LoadData = function(self)

    local sFile = (self.DataDir .. self.DataFile)
    local aData = FileLoader:ExecuteFile(sFile, eFileType_Data)
    if (table.countRec(aData) <= 3) then
        aData = self.Default
    end

    for sType, aList in pairs(aData) do
        for _, aInfo in pairs(aList) do
            self:SetupEntry(aInfo, _)

            -- Crazy ban times like 12367891264824123489YEARS can cause bugs like negative invalid expiry, so we need to fix this
            -- Fixed by storing expiry as a string value ?
            --if (aInfo.Expiry < -1) then
            --    aInfo.Expiry = (aInfo.Expiry * -1)
            --end
        end
    end

    self.Data = aData
end

-----------------
ServerPunish.SaveData = function(self)

    local aData = table.deepCopy(self.Data)

    for sType, aList in pairs(aData) do
        for _, aInfo in pairs(aList) do
            aInfo.ID = nil -- we don't need this!
            for __, h in pairs(aInfo) do
                if (isFunc(h)) then
                    aInfo[__] = nil
                end
            end
        end
    end

    local sData = string.format("return %s", (table.tostring(aData, "", "", nil, nil, 3) or "{}"))
    local sFile = (self.DataDir .. self.DataFile)

    local bOk, sErr = FileOverwrite(sFile, sData)
    if (not bOk) then

        -- FIXME: Error Handler
        -- ErrorHandler()

        ServerLogError("Failed to open file %s for writing", sFile)
    end

    self.SaveQueued = nil
end

-----------------
ServerPunish.QueueSaveFile = function(self)
    self.SaveQueued = true
end

-----------------
ServerPunish.SetupEntry = function(self, aInfo, iID)

    -- Functions
    aInfo.Expired       = function(this) return (GetTimestamp() >= g_tn(this.Expiry))  end
    aInfo.GetExpiry     = function(this, fmt, x) local e = g_tn(this.Expiry) - GetTimestamp() return (fmt and math.calctime(e,x) or e)  end
    aInfo.GetRemaining  = function(this) return math.max(0, g_tn(this.Expiry) - GetTimestamp())  end
    aInfo.GetElapsed    = function(this, fmt, x) local e = math.max(0, GetTimestamp() - g_tn(this.Date)) return (fmt and math.calctime(e, x) or e)  end
    aInfo.GetDate       = function(this, fmt) return (fmt and os.date("%Y-%m-%d %H:%M:%S", this.Date) or this.Date)  end
    aInfo.GetName       = function(this) return (this.Player[2])  end
    aInfo.GetPlayerID   = function(this) return (this.Player[1])  end
    aInfo.GetAdmin      = function(this) return (this.Admin[2])  end
    aInfo.GetAdminID    = function(this) return (this.Admin[1])  end
    aInfo.GetReason     = function(this) return (this.Reason)  end
    aInfo.GetIndex      = function(this) return (this.ID or iID)  end
    aInfo.GetIP         = function(this, i) return (i and this.IPs[i] or this.IPs)  end--FIXME
    aInfo.GetHost       = function(this, i) return (i and this.Host[i] or this.Host)  end--FIXME
    aInfo.GetProfile    = function(this, i) return (i and this.IDs[i] or this.IDs)  end--FIXME

    return aInfo
end