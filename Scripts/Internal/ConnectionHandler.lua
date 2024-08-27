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

    -- Welcome Message in Chat
    WelcomeChatMessage = nil
}

--------------------------------
--- Init
ServerPCH.Init = function(self)
    ServerConnections = self
    self.WelcomeChatMessage = ConfigGet("Server.Welcome.ChatMessage", "@l_ui_welcomechat", eConfigGet_String)
end

--------------------------------
--- Init
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

--------------------------------
--- Init
ServerPCH.OnBotConnection = function(self, hBot)

    ServerLog("Detected BOT Connection on Channel %d", hBot:GetChannel())
    if (ConfigGet("Server.AllowBots", true, eConfigGet_Boolean) == false) then
        hBot:Kick("Server", "Bots not Allowed.")
    end

end

--------------------------------
--- Init
ServerPCH.OnValidation = function(self, hClient, sError, sResponse, iCode)

    if (not ChannelExists(hClient:GetChannel())) then
        return ServerLogError("Client left before validation finished!")
    end

    local bPunish = false
    local bOk = true
    if (iCode ~= 200) then
        bOk = false
    end

    if (sResponse ~= "%Validation:Successful%") then
        bOk = false
        bPunish = true
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


        if (bPunish and ConfigGet("Server.Punishment.BanInvalidProfile", true, eConfigGet_Boolean)) then
            ServerPunish:BanPlayer(Server.ServerEntity, hClient, "1h", "Validate at CryMP.org Failed - Please Try again")

        elseif (ConfigGet("Server.Punishment.KickInvalidProfile", true, eConfigGet_Boolean)) then
            ServerPunish:DisconnectPlayer(eKickType_Kicked, hClient, "Validate at CryMP.org Failed - Please Try again", nil, "Server")
        end

        hClient.Info.Validated  = false
        hClient.Info.Validating = false
    end

    -- Check Mute
    local aMuteInfo = ServerPunish:Mute_CheckPlayer(hClient)
    if (aMuteInfo) then
        hClient:SetMute(aMuteInfo)
    else
        hClient:RemoveMute()
    end

end

--------------------------------
--- Init
ServerPCH.OnConnection = function(self, iChannel, sIP)

    -- Stats
    AddServerStat(eServerStat_ConnectionCount, 1)

    ServerDefense:InitChannel(iChannel)
    ServerChannels:InitChannel(iChannel, sIP)
    PlayerHandler:CreateClientInfo(iChannel, sIP)

    local sHost = ServerChannels:GetHost(iChannel)
    local sNick = (ServerDLL.GetChannelNick(iChannel) or "Nomad")

    -- Check Bans
    if (ServerPunish:Ban_CheckChannel(iChannel, sIP, sHost)) then
        return false
    end

    -- FIXME: Check VPNs Here!
    -- CheckVPN(sIP)

    -- FIXME: Check Country Here!
    -- CheckCountry(sIP)
end

--------------------------------
--- Init
ServerPCH.LogOnConnection = function(self, iChannel, sIP)

    local sHost = ServerChannels:GetHost(iChannel)
    local sNick = (ServerDLL.GetChannelNick(iChannel) or "Nomad")

    -- Just log
    SendMsg(CHAT_SERVER_LOCALE, GetPlayers(), "@l_chat_on_connection", sNick, iChannel, sIP)
    Logger:LogEvent(eLogEvent_Connection, "@l_console_on_connection", sNick, iChannel, sIP)
end

--------------------------------
--- Init
ServerPCH.OnConnectionClosed = function(self, iChannel, sReason)

    local sReasonShort = (self:GetShortReason(sReason))
    local sNick = (ServerDLL.GetChannelNick(iChannel) or "Nomad")

    -- Just log
    if (not WasChannelBanned(iChannel)) then
        SendMsg(CHAT_SERVER_LOCALE, GetPlayers(), "@l_chat_on_chanDisconnect", (sNick or "Nomad"), iChannel, sReasonShort)
        Logger:LogEvent(eLogEvent_Connection, "@l_console_on_chandisconnect", (sNick or "Nomad"), iChannel, sReasonShort)
    end

    ServerChannels:OnChannelDisconnect(iChannel)
end

--------------------------------
--- Init
ServerPCH.OnEnteredGame = function(self, hClient)

    ServerLog("!!!!!!!!!!!!! ENTERED GAME !!!!!!!!!!!!!!!!!!")
end

--------------------------------
--- Init
ServerPCH.OnConnected = function(self, hClient)

    -- Stats
    AddServerStat(eServerStat_TotalChannels, 1)

    local iChannel = (hClient.actor:GetChannel())
    local sName = (hClient:GetName())

    ServerChannels:OnChannelDisconnect(iChannel)

    -- Check Bans
    if (ServerPunish:Ban_CheckPlayer(hClient)) then
        return false
    end

    -- Check Mute
    local aMuteInfo = ServerPunish:Mute_CheckPlayer(hClient)
    if (aMuteInfo) then
        hClient:SetMute(aMuteInfo)
    else
        hClient:RemoveMute()
    end

    -- FIXME: Check VPNs Here!
    -- CheckVPN(hClient)

    -- FIXME: Check Country Here!
    -- CheckCountry(hClient)

    -- FIXME: Good place?
    ServerAccess:InitClient(hClient)

    hClient.Connected = true
    self:SendBanner(hClient)

    -- Just log
    SendMsg(CHAT_SERVER_LOCALE, GetPlayers(), "@l_chat_on_Connected", sName, iChannel, hClient:GetProfileID())
    Logger:LogEvent(eLogEvent_Connection, "@l_console_on_connected", sName, iChannel, hClient:GetProfileID())
end

--------------------------------
--- Init
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

    -- FIXME: Good Place?
    PlayerHandler:OnClientDisconnect(hClient)
    CallEvent(eServerEvent_OnClientDisconnect, hClient, sReason, sReasonShort)

    -- Just log
    if (not hClient:WasBanned()) then
        SendMsg(CHAT_SERVER_LOCALE, GetPlayers(), "@l_chat_on_disconnected", sName, iChannel, sReasonShort)
        Logger:LogEvent(eLogEvent_Connection, "@l_console_on_disconnected", sName, iChannel, sReasonShort)
    end
end

--------------------------------
--- Init
ServerPCH.GetShortReason = function(self, sMessage)

    local iTimeout = string.match(sMessage, "no packet for (%d+) seconds")
    if (iTimeout) then
        return string.format("Timed out After %s", Logger.FormatTime(iTimeout))
    end

    local aShorts = {
        { "user left the game", "User Disconnected" },
        { "Unreachable address .*", "User Quit"}
    }

    local sShort = sMessage
    for _, aShort in pairs(aShorts) do
        if (string.match(string.lower(sMessage), string.lower(aShort[1]))) then
            sShort = aShort[2]
        end
    end

    -- FIXME: Shorten the message!
    return string.gsuba(sShort, {
        { f = "^Remote disconnected:", r = "" }
    })
end

--------------------------------
--- Init
ServerPCH.SendBanner = function(self, hClient, sForcedLang)

    local sMidSpace = "                "
    local iBoxIDLen = 10
    local iBoxDataLen = 15
    local iCenterLineWidth = 44
    local AlignCenter = 0
    local AlignLeft = 1
    local AlignRight = 2

    local sLang     = (sForcedLang or hClient:GetPreferredLanguage())
    local sAccess   = hClient:GetRankName()
    local sName     = hClient:GetName()
    local sLastSeen = hClient:GetLastVisit()

    local sUsageInfo = string.format("CPU: %d%%, %s", ServerDLL.GetCPUUsage(), ServerUtils.ByteSuffix(ServerDLL.GetMemUsage(), 0))

    if (sLastSeen == "Never") then
        sLastSeen = TryLocalize("@l_ui_never", sLang)
    elseif (sLastSeen == "Today") then
        sLastSeen = TryLocalize("@l_ui_today", sLang)
    else
        local sFmt = "@l_ui_days"
        if (sLastSeen > ONE_WEEK) then
            sFmt = "@l_ui_weeks"
            sLastSeen = math.floor(sLastSeen / ONE_WEEK)
        end
        sLastSeen = TryLocalize("@l_ui_timeago", sLang, { sLastSeen, TryLocalize(sFmt, sLang) })
    end

    local aFormat = {
        ["cl_ip"]       = hClient:GetIP(),
        ["cl_id"]       = hClient:GetProfileID(),
        ["cl_playtime"] = math.calctime(hClient:GetPlayTime()),
        ["cl_country"]  = hClient:GetCountry(),
        ["cl_lang"]     = string.capitalN(sLang),
        ["cl_access"]   = sAccess,
        ["cl_visit"]    = TryLocalize("@l_ui_last_visit", sLang, { sLastSeen }) .. ": ${red}" .. sLastSeen,
        ["cl_welcome"]  = string.format("-- %s -- ", TryLocalize("@l_ui_welcomebanner_np", sLang, {  })),
        ["cl_name"]     = "${white}"..sName
    }

    local function CreateLine(aHost, aInfoLeft, aInfoRight, aCenterInfo)
        table.insert(aHost, {
            Left = {
                Field = { Name = aInfoLeft.ID,   Width = (aInfoLeft.IDWidth or iBoxIDLen) },
                Value = { Name = aInfoLeft.Data, Width = (aInfoLeft.DataWidth or iBoxDataLen) }
            },
            Right = {
                Field = { Name = aInfoRight.ID,   Width = (aInfoRight.IDWidth or iBoxIDLen) },
                Value = { Name = aInfoRight.Data, Width = (aInfoRight.DataWidth or iBoxDataLen) }
            },
            Center = {
                Value = (aCenterInfo.Data or ""),
                Width = (aCenterInfo.Width or iCenterLineWidth),
                Align = AlignCenter
            }
        })
    end

    local function PadString(s, width, align)

        s = Logger.Format(TryLocalize(s, sLang), aFormat)
        local iLen = string.len(s) - (string.count(s, string.COLOR_CODE) * 2)
        if (align == AlignLeft) then
            return (s .. string.rep(" ", width - iLen))

        elseif (align == AlignRight) then
            return (string.rep(" ", width - iLen) .. s)

        elseif (align == AlignCenter) then
            local iPad = (width - iLen)
            local iLeftPad = math.floor(iPad / 2)
            local iRightPad = (iPad - iLeftPad)
            return (string.rep(" ", iLeftPad) .. s .. string.rep(" ", iRightPad))
        end
    end

    local function PrintLines(sPrefix, aBoxes)
        for _, aBox in ipairs(aBoxes) do
            local sLeftField  = PadString(aBox.Left.Field.Name,  aBox.Left.Field.Width, AlignLeft)
            local sLeftValue  = PadString(aBox.Left.Value.Name,  aBox.Left.Value.Width, AlignLeft)
            local sRightField = PadString(aBox.Right.Field.Name, aBox.Right.Field.Width, AlignLeft)
            local sRightValue = PadString(aBox.Right.Value.Name, aBox.Right.Value.Width, AlignLeft)
            local sCenterLine = PadString(aBox.Center.Value,    (aBox.Center.Width or iCenterLineWidth), aBox.Center.Align)

            SendMsg(MSG_CONSOLE_FIXED, hClient, (string.format("%s[ %s$9 : %s$9 ] %s${gray} [ %s$9 : %s$9 ]", sPrefix, sLeftField, sLeftValue, sCenterLine, sRightField, sRightValue)))
        end
    end

    local aBoxes = {}
    CreateLine(aBoxes,{ ID = "ID",       Data = "${red}${cl_id}${gray}"      },{ ID = "@l_ui_uptime", Data = "${red}" .. math.calctime(timerinit()+1, 5), }, { Data = "" })
    CreateLine(aBoxes,{ ID = "IP",       Data = "${white}${cl_ip}${gray}"      },{ ID = "@l_ui_rssusage", Data = "${red}" .. sUsageInfo }, { Data = "${white}${cl_welcome}${gray}" })
    CreateLine(aBoxes,{ ID = "@l_ui_playtime",   Data = "${cl_playtime}"  },{ ID = "-", Data = "-", }, { Data = "${cl_name}" })
    CreateLine(aBoxes,{ ID = "@l_ui_country",  Data = "${cl_country}" },{ ID = "-", Data = "-", }, { Data = "" })
    CreateLine(aBoxes,{ ID = "@l_ui_language", Data = "${cl_lang}"    },{ ID = "-", Data = "-", }, { Data = "${cl_visit}" })


    -- !!FIXME
    local sCPU = checkString(ServerDLL.GetCPUName(), "Unknown")
    local sModInfo = Logger.Format("${red}${mod_version}${gray}, ${red}x${mod_bits}", {})

    SendMsg(MSG_CONSOLE_FIXED, hClient, ("${grey}" .. " "))
    SendMsg(MSG_CONSOLE_FIXED, hClient, ("${grey}" .. " "))
    SendMsg(MSG_CONSOLE_FIXED, hClient, ("${grey}" .. " "))
    SendMsg(MSG_CONSOLE_FIXED, hClient, ("${grey}" .. " "))
    SendMsg(MSG_CONSOLE_FIXED, hClient, ("${grey}" .. " "))
    SendMsg(MSG_CONSOLE_FIXED, hClient, ("${grey}" .. " "))
    SendMsg(MSG_CONSOLE_FIXED, hClient, ("${grey}" .. sMidSpace .. "**********************************************************************"))
    SendMsg(MSG_CONSOLE_FIXED, hClient, ("${grey}" .. sMidSpace .. "   ______           __  _______       _____                           "))
    SendMsg(MSG_CONSOLE_FIXED, hClient, ("${grey}" .. sMidSpace .. "  / ____/______  __/  |/  / __ \\     / ___/___  ______   _____  _____ "))
    SendMsg(MSG_CONSOLE_FIXED, hClient, ("${grey}" .. sMidSpace .. " / /   / ___/ / / / /|_/ / /_/ /_____\\__ \\/ _ \\/ ___/ | / / _ \\/ ___/ "))
    SendMsg(MSG_CONSOLE_FIXED, hClient, ("${grey}" .. sMidSpace .. "/ /___/ /  / /_/ / /  / / ____/_____/__/ /  __/ /   | |/ /  __/ /     "))
    SendMsg(MSG_CONSOLE_FIXED, hClient, ("${grey}" .. sMidSpace .. "\\____/_/   \\__, /_/  /_/_/         /____/\\___/_/    |___/\\___/_/      "))
    SendMsg(MSG_CONSOLE_FIXED, hClient, ("${gray}" .. sMidSpace .. string.format("${grey}          /____/ %s %s                           ", string.rspace(sModInfo, 17, string.COLOR_CODE, " "), sCPU)))
    SendMsg(MSG_CONSOLE_FIXED, hClient, ("${grey}" .. "  --------------------------------------------------------------------------------------------------------------"))
    PrintLines("${gray}  ", aBoxes)
    SendMsg(MSG_CONSOLE_FIXED, hClient, ("${grey}" .. "  --------------------------------------------------------------------------------------------------------------"))
    SendMsg(MSG_CONSOLE_FIXED, hClient, ("${grey}" .. " "))
    SendMsg(MSG_CONSOLE_FIXED, hClient, ("${grey}" .. "  CPU: " .. sCPU))
    SendMsg(MSG_CONSOLE_FIXED, hClient, ("${grey}" .. " "))

    -- Chat
    SendMsg(CHAT_SERVER, hClient, string.gsub(Logger.Format(TryLocalize(self.WelcomeChatMessage, sLang, { sAccess, sName }), aFormat), string.COLOR_CODE, ""))
end