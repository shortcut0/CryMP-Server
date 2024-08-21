----------------
ServerNames = {

    ForbiddenNames = {},
    ForbiddenSymbols = {},
    ReplacementCharacter = "_",

    AllowSpaces = true,

    NomadTemplate = "^Nomad$",
    NameTemplate = "[Nomad.${a_country}] ::  (${a_channel})",
}

----------------
ServerNames.Init = function(self)

    Logger.CreateAbstract(self, { LogClass = "Names", Color = "$4" })

    self.AllowSpaces    = ConfigGet("General.Names.AllowSpaces", self.AllowSpaces, eConfigGet_Boolean)
    self.NameTemplate   = ConfigGet("General.Names.Template", self.NameTemplate, eConfigGet_String)
    self.NomadTemplate   = ConfigGet("General.Names.Template", self.NameTemplate, eConfigGet_String)
    self.ForbiddenNames = ConfigGet("General.Names.ForbiddenNames", {}, eConfigGet_Array)
    self.ForbiddenSymbols = ConfigGet("General.Names.ForbiddenSymbols", {}, eConfigGet_Array)
    self.ReplacementCharacter = ConfigGet("General.Names.Replacement", "_", eConfigGet_String)

end

----------------
ServerNames.RequestRename = function(self, hPlayer, sName, hAdmin, sReason)

    local sCurrentName = hPlayer:GetName()
    if (sCurrentName == sName) then
        return false, "@l_ui_chooseDifferentName"
    end

    local iMin = ConfigGet("General.Names.MinimumLength", 3, eConfigGet_Number)
    local iMax = ConfigGet("General.Names.MaximumLength", 18, eConfigGet_Number)

    if (hPlayer:IsDeveloper()) then
        iMin = 1
        iMax = 256
    end

    sName = self:Sanitize(sName)
    Debug("string.lower(sName)>","-"..string.lower(sName).."-","<")
    if (string.lower(sName) == "nomad") then
        sName = self:GetDefaultName(hPlayer)
        Debug("sName",sName)
    end

    if (string.len(sName) < iMin) then
        return false, "@l_ui_nameTooShort"
    end

    if (string.len(sName) > iMax) then
        return false, "@l_ui_nameTooLong"
    end

    if (ServerAccess:IsProtectedName(sName, hPlayer:GetProfile())) then
        return false, "@l_ui_nameIsProtected"
    end

    if (self:IsForbiddenName(sName) and not hPlayer:IsDeveloper()) then
        return false, "@l_ui_nameIsForbidden"
    end

    if (GetPlayer(sName)) then
        return false, "@l_ui_nameIsInUse"
    end

    local sOldName = hPlayer:GetName()
    g_pGame:RenamePlayer(hPlayer.id, sName)
    if (hPlayer:GetName() ~= sOldName) then
        local sMsgCon = "@l_console_clientrenamed"
        local sMsgChat = "@l_chat_clientrenamed"
        if (hAdmin) then
            sMsgCon = "@l_console_clientrenamedByAdmin"
            sMsgChat = "@l_chat_clientrenamedByAdmin"
        end
        Logger:LogEvent(eLogEvent_Rename, sMsgCon, sOldName, sName, hAdmin and hAdmin:GetName() or "", checkVar(sReason, "Admin Decision"))
        SendMsg(CHAT_SERVER_LOCALE, ALL_PLAYERS, sMsgChat, sOldName, sName, hAdmin and hAdmin:GetName() or "", checkVar(sReason, "Admin Decision"))
    else
        return false, "@l_ui_chooseDifferentName"
    end

    return true
end

----------------
ServerNames.IsForbiddenName = function(self, sName)

    local aForbidden = self.ForbiddenNames
    for _, sForbidden in pairs(aForbidden or {}) do
        if (string.lower(sName) == string.lower(sForbidden)) then
            return true
        end
    end

    return (string.match(sName, "Nomad"))
end

----------------
ServerNames.IsNomad = function(self, sName)
    if (string.match(string.lower(sName), string.lower(self.NomadTemplate))) then
        return true
    end

    local sNameTemplate = string.gsuba(string.escape(string.lower(self.NameTemplate)), {
        { "{a_country}", ".." },
        { "{a_profile}", "%%d+" }
    })

    return (string.match(("(" .. string.lower(sName) .. ")"), sNameTemplate))
end

----------------
ServerNames.GetDefaultName = function(self, hClient)

    local sCountry = (hClient.Country or "CV")
    local sProfile = (hClient.Profile or "0")
    local iChannel = (hClient.Channel or "0")
    if (IsEntity(hClient)) then
        sCountry = (hClient:GetCountryCode() or "CV")
        sProfile = (hClient:GetProfile() or "0000000")
        iChannel = (hClient:GetChannel() or "0000000")
    end

    return Logger.Format(self.NameTemplate, { ["a_channel"] = string.format("%04d", iChannel), ["a_country"] = sCountry, ["a_profile"] = sProfile })
end

----------------
ServerNames.HandleChannelNick = function(self, iChannel, aFmt)
    local sNick = ServerDLL.GetChannelNick(iChannel)
    Debug("nick:",sNick)
    if (sNick == nil or self:IsNomad(sNick)) then
        ServerDLL.SetChannelNick(iChannel, self:GetDefaultName(aFmt))
        Debug("changed name fucking name")
    end
end

----------------
ServerNames.Format = function(self, hClient)


end

----------------
ServerNames.ValidateName = function(self, sName, hClient)

    if (self:IsNomad(sName) and hClient) then
        return self:GetDefaultName(hClient)
    end

    return self:Sanitize(sName)
end

----------------
ServerNames.RemoveCrypt = function(self, sName)
    local sNewName = ""
    local iRemoved = 0
    local sAllowed = "[a-zA-Z0-9_'{}\"%(%) %*&%%%$#@!%?/\\;:,%.<>%-%[%]%+]"
    for i = 1, string.len(sName) do
        local s = string.sub(sName, i, i)
        if (s and s:match(sAllowed)) then
            sNewName = sNewName .. s
        else
            iRemoved = iRemoved + 1
        end
    end
    return sNewName, iRemoved
end

----------------
ServerNames.Sanitize = function(self, sName)

    local sSanitized = sName
    sSanitized = string.ridlead(sSanitized, "%s*", 1)
    sSanitized = string.ridtrail(sSanitized, "%s*", 1)

    local aForbidden = self.ForbiddenSymbols
    local sReplace = self.ReplacementCharacter
    if (string.empty(sReplace)) then
        sReplace = "_"
    end

    if (table.empty(aForbidden)) then
        return sSanitized
    end

    if (table.findv(aForbidden, sReplace)) then
        self:LogError("Replacement Character '%s' is a forbidden character!!")
        return sName
    end

    for _, sBad in pairs(aForbidden) do
        sSanitized = string.gsub(sSanitized, sBad, sReplace)
    end

    return sSanitized
end