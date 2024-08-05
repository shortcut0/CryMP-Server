-----------------
ServerLocale = {

    LocaleDir = (SERVER_DIR_DATA .. "Locale\\"),
    LocaleFiles = "\.(txt|json|lua)$",

    Localization = {},
    DefaultLanguage = "english"
}

----------------
ServerLocale.Init = function(self)

    LocalizeForClient  = function(...) return self:LocalizeForClient(...) end
    Localize           = function(...) return self:LocalizeText(...) end
    TryLocalize        = function(...) return self:TryLocalize(...) end
    CreateLocalization = function(...) return self:CreateLocalization(...) end

    SERVER_LANGUAGE = string.lower(ConfigGet("Server.Language", self.DefaultLanguage, eConfigGet_String))

    self:LoadLanguages()

    local aLocalizationData = self.Localization
    local sLog = string.format("Loaded ${red}%d${gray} Localizations", table.count(aLocalizationData))

    ServerLog(sLog)
    Logger:LogEventTo(GetDevs(), eLogEvent_ServerLocale, sLog)

    for sLocale, aInfo in pairs(aLocalizationData) do
    --    ServerLog(" [%-30s] Languages: %d", sLocale, table.count(aInfo))
    end


end

----------------
ServerLocale.LocalizeForClient = function(self, hClient, sMsg, aFormat)
    local sLang = hClient:GetPreferredLanguage()
    local iClientRank = hClient:GetAccess()

    local sLocalized, sExtended = Localize(sMsg, sLang, (hClient:IsDevRank()))
    if (sLocalized) then
        return Logger:FormatLocalized(sLocalized, aFormat)
    end

    return sMsg
end
----------------
ServerLocale.TryLocalize = function(self, sMsg, sLang, aFormat, bForceExt)

    local sLocalized = Localize(sMsg, sLang, bForceExt)
    if (sLocalized) then
        return Logger:FormatLocalized(sLocalized, (aFormat or {}))
    end

    return sMsg
end

----------------
ServerLocale.LocalizeText = function(self, sId, sLang, bForceExt)

    local sDefault = self.DefaultLanguage
    local aLocale = self.Localization[sId]

    if (not sId) then
        error("no id")
    end

    if (string.find(sId, " ") or not string.fc(sId, "@")) then
        --ServerLog("No localizing %s", sId)
        return
    end

    if (not aLocale) then
        ServerLogError("No Locale found for string %s", sId)
        return ("@{error:missing_" .. sId .. "}")
    end

    sLang = (sLang or sDefault)
    local aContent = (aLocale[sLang] or aLocale[sDefault])

    --ServerLog(sLang)
   -- ServerLog(table.tostring(aLocale["english"]))
    if (not aContent) then
        ServerLogError("Localization for string %s for Language %s not found.. Trying '%s'", sId, sLang, sDefault)
        return ("@{error:missing_" .. sId .. "_" .. sLang .. "}")
    end

    local sLocalized = aContent.regular
    local sExtra = aContent.extended

    if (bForceExt and sExtra) then
        return sExtra
    end

    return sLocalized, sExtra
end

----------------
ServerLocale.CreateLocalization = function(self, sId, aLanguages)

    if (not string.fc(sId, "@")) then
        sId = ("@" .. sId)
    end

    self.Localization[sId] = (self.Localization[sId] or {})
    for sLang, aLang in pairs(aLanguages) do
        self.Localization[sId][sLang] = aLang
        if (isString(aLang)) then
            self.Localization[sId][sLang] = { regular = aLang }
        end
    end
end

----------------
ServerLocale.LoadLanguages = function(self, sDir)

    local sPath = (sDir or self.LocaleDir)
    if (not ServerLFS.DirExists(sPath)) then
        return ServerLFS.DirCreate(sPath)
    end

    local aFiles = ServerLFS.DirGetFiles(sPath, GETFILES_FILES)
    if (table.empty(aFiles)) then
        error("empty")
        return
    end

    local sType, sData
    local bOk, sErr

    for _, sFile in pairs(aFiles) do

        if (ServerLFS.DirIsDir(sFile)) then
            self:LoadLanguages(sFile)
        else

            sType = FileGetExtension(sFile)
            sData = FileRead(sFile)
            if (string.len(sData) > 0) then
                if (sType == "lua") then

                    bOk, sErr = pcall(loadstring(sData))
                    if (not bOk) then

                        HandleError("Failed to read Locale file %s (%s)", ServerLFS.FileGetName(sFile), g_ts(sErr))
                    end

                elseif (sType == "txt") then

                    -- FIXME
                    error("unsupported type")

                elseif (sType == "json") then

                    -- FIXME
                    error("unsupported type")

                else
                    ServerLog("Unknown file type!! help!!")
                end
            end
        end
    end
end