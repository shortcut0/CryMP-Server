----------------
ServerNames = {

    ForbiddenNames = {},
    ForbiddenSymbols = {},
    ReplacementCharacter = "_",

    AllowSpaces = true,

    NomadTemplate = "^Nomad$",
    NameTemplate = "Nomad:{a_country} (#{a_profile})",
}

----------------
ServerNames.Init = function(self)

    Logger.CreateAbstract(self, { LogClass = "Names", Color = "$4" })

    self.AllowSpaces    = ConfigGet("General.Names.AllowSpaces", self.AllowSpaces, eConfigGet_Boolean)
    self.NameTemplate   = ConfigGet("General.Names.Template", self.NameTemplate, eConfigGet_String)
    self.ForbiddenNames = ConfigGet("General.Names.ForbiddenNames", {}, eConfigGet_Array)
    self.ForbiddenSymbols = ConfigGet("General.Names.ForbiddenSymbols", {}, eConfigGet_Array)
    self.ReplacementCharacter = ConfigGet("General.Names.Replacement", "_", eConfigGet_String)

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
    local sProfile = (hClient.Profile or "CV")
    if (IsEntity(hClient)) then
        sCountry = (hClient:GetCountryCode() or "CV")
        sProfile = (hClient:GetProfile() or "0000000")
    end

    return self:Format(self.NameTemplate, { ["a_country"] = sCountry, ["a_profile"] = sProfile })
end

----------------
ServerNames.ValidateName = function(self, sName, hClient)

    if (self:IsNomad(sName) and hClient) then
        return self:GetDefaultName(hClient)
    end

    return self:Sanitize(sName)
end

----------------
ServerNames.Sanitize = function(self, sName)

    local aForbidden = self.ForbiddenSymbols
    local sReplace = self.ReplacementCharacter
    if (string.empty(sReplace)) then
        sReplace = "_"
    end

    if (table.empty(aForbidden)) then
        return sName
    end

    if (table.findv(aForbidden, sReplace)) then
        self:LogError("Replacement Character '%s' is a forbidden character!!")
        return sName
    end

    local sSanitized = sName
    for _, sBad in pairs(aForbidden) do
        sSanitized = string.gsub(sSanitized, sBad, sReplace)
    end

    return sSanitized
end