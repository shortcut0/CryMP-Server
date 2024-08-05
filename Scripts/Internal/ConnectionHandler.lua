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

----------------
ServerPCH.Init = function(self)
    ServerConnections = self
    self.WelcomeChatMessage = ConfigGet("Server.Welcome.ChatMessage", "@l_ui_welcomechat", eConfigGet_String)
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
ServerPCH.OnEnteredGame = function(self, hClient)

    ServerLog("!!!!!!!!!!!!! ENTERED GAME !!!!!!!!!!!!!!!!!!")
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

    -- FIXME: Good place?
    ServerAccess:InitClient(hClient)

    hClient.Connected = true
    self:SendBanner(hClient)

    -- Just log
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

    -- FIXME: Good Place?
    PlayerHandler:OnClientDisconnect(hClient)
    CallEvent(eServerEvent_OnClientDisconnect, hClient, sReason, sReasonShort)

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

----------------
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
        ["cl_playtime"]  = math.calctime(hClient:GetPlayTime(), 1),
        ["cl_country"]  = hClient:GetCountry(),
        ["cl_lang"]     = string.capitalN(sLang),
        ["cl_access"]   = sAccess,
        ["cl_visit"]    = TryLocalize("@l_ui_last_visit", sLang, { sLastSeen }) .. ": ${red}" .. sLastSeen,
        ["cl_welcome"]  = TryLocalize("@l_ui_welcomebanner", sLang, { sAccess, sName })
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
    CreateLine(aBoxes,{ ID = "ID",       Data = "${red}${cl_id}${gray}"      },{ ID = "@l_ui_uptime", Data = "${red}" .. math.calctime(timerinit(), 1), }, { Data = "" })
    CreateLine(aBoxes,{ ID = "IP",       Data = "${white}${cl_ip}${gray}"      },{ ID = "-", Data = "-", Width = 1000}, { Data = "${white}${cl_welcome}${gray}" })
    CreateLine(aBoxes,{ ID = "@l_ui_playtime",   Data = "${cl_playtime}"  },{ ID = "-", Data = "-", }, { Data = "${cl_visit}" })
    CreateLine(aBoxes,{ ID = "@l_ui_country",  Data = "${cl_country}" },{ ID = "-", Data = "-", }, { Data = "" })
    CreateLine(aBoxes,{ ID = "@l_ui_language", Data = "${cl_lang}"    },{ ID = "-", Data = "-", }, { Data = "" })


    -- !!FIXME
    local sCPU = "AMD Ryzen 5 4600H - 12 Cores"
    local sModInfo = Logger.Format("${red}${mod_version}${gray}, ${red}x${mod_bits}", {})

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

    do return end
    local sID_01 = "ID" -- 1 L
    local sID_02 = "Restored"
    local sID_03 = "IP"
    local sID_05 = "Country"
    local sID_04 = "ID"
    local sID_06 = "ID"
    local sID_07 = "Language"
    local sID_08 = "ID"

    -- fixme: add: restored, system up time etc

    local sData_01 = hClient:GetProfile()
    local sData_02 = "Yes" -- FIXME
    local sData_03 = hClient:GetIP()
    local sData_04 = "1008858"
    local sData_05 = hClient:GetCountry()
    local sData_06 = "1008858"
    local sData_07 = hClient:GetPreferredLanguage()
    local sData_08 = "1008858"

    local sCenter_01 = string.mspace("Welcome, " .. hClient:GetRankName() .. " " .. hClient:GetName() .. "!", 45, nil, string.COLOR_CODE)
    local sCenter_02 = string.mspace("Your Last Visit: " .. CRY_COLOR_RED .. "Never" .. CRY_COLOR_GRAY, 45, nil, string.COLOR_CODE)
    local sCenter_03 = string.mspace(" ", 45, nil, string.COLOR_CODE)
    local sCenter_04 = string.mspace(" ", 45, nil, string.COLOR_CODE)
    local sCenter_05 = string.mspace("System Runtime " .. math.calctime(timerinit(), 1), 45, nil, string.COLOR_CODE)

    SendMsg(MSG_CONSOLE_FIXED, hClient, ("${grey}" .. sMidSpace .. "**********************************************************************"))
    SendMsg(MSG_CONSOLE_FIXED, hClient, ("${grey}" .. sMidSpace .. "**********************************************************************"))
    SendMsg(MSG_CONSOLE_FIXED, hClient, ("${grey}" .. sMidSpace .. "   ______           __  _______       _____                           "))
    SendMsg(MSG_CONSOLE_FIXED, hClient, ("${grey}" .. sMidSpace .. "  / ____/______  __/  |/  / __ \\     / ___/___  ______   _____  _____ "))
    SendMsg(MSG_CONSOLE_FIXED, hClient, ("${grey}" .. sMidSpace .. " / /   / ___/ / / / /|_/ / /_/ /_____\\__ \\/ _ \\/ ___/ | / / _ \\/ ___/ "))
    SendMsg(MSG_CONSOLE_FIXED, hClient, ("${grey}" .. sMidSpace .. "/ /___/ /  / /_/ / /  / / ____/_____/__/ /  __/ /   | |/ /  __/ /     "))
    SendMsg(MSG_CONSOLE_FIXED, hClient, ("${grey}" .. sMidSpace .. "\\____/_/   \\__, /_/  /_/_/         /____/\\___/_/    |___/\\___/_/      "))
    SendMsg(MSG_CONSOLE_FIXED, hClient, ("${gray}" .. sMidSpace .. string.format("${grey}          /____/ %s %s                           ", string.rspace(sModInfo, 17, string.COLOR_CODE, "."), sCPU)))
    SendMsg(MSG_CONSOLE_FIXED, hClient, ("${grey}" .. "  -------------------------------------------------------------------------------------------------------------"))
    SendMsg(MSG_CONSOLE_FIXED, hClient, ("${grey} "))
    SendMsg(MSG_CONSOLE_FIXED, hClient, ("${grey}" .. string.format("   [ %-8s : $4%-15s$9 ] %s [ %-8s : $3%-15s$9 ]", sID_01, sData_01, sCenter_01, sID_02, sData_02)))
    SendMsg(MSG_CONSOLE_FIXED, hClient, ("${grey}" .. string.format("   [ %-8s : $8%-15s$9 ] %s [ %-8s : %-15s ]", sID_03, sData_03, sCenter_02, sID_04, sData_04)))
    SendMsg(MSG_CONSOLE_FIXED, hClient, ("${grey}" .. string.format("   [ %-8s : $1%-15s$9 ] %s [ %-8s : %-15s ]", sID_05, sData_05, sCenter_03, sID_06, sData_06)))
    SendMsg(MSG_CONSOLE_FIXED, hClient, ("${grey}" .. string.format("   [ %-8s : $1%-15s$9 ] %s [ %-8s : %-15s ]", sID_07, sData_07, sCenter_04, sID_08, sData_08)))
    SendMsg(MSG_CONSOLE_FIXED, hClient, ("${grey}" .. string.format("                                 %s ", sCenter_05)))
    SendMsg(MSG_CONSOLE_FIXED, hClient, ("${grey}" .. "  -------------------------------------------------------------------------------------------------------------"))
end