-----------------
ServerLocale = {

    LocaleDir = (SERVER_DIR_DATA .. "Locale\\"),
    LocaleFiles = "\.(txt|json|lua)$",

    Localization = {},
    DefaultLanguage = "english",
    AvailableLanguages = { "english", "german", "spanish", "russian", "turkish", "czech" }
}

----------------
ServerLocale.Init = function(self)


    LocalizeForClient       = function(...) return self:LocalizeForClient(...) end
    LocalizeNestForClient   = function(...) return self:LocalizeNestForClient(...) end
    Localize                = function(...) return self:LocalizeText(...) end
    TryLocalize             = function(...) return self:TryLocalize(...) end
    CreateLocalization      = function(...) return self:CreateLocalization(...) end

    AVAILABLE_LANGUAGES = ConfigGet("Server.AvailableLanguages", self.AvailableLanguages, eConfigGet_Array)
    SERVER_LANGUAGE = string.lower(ConfigGet("Server.Language", self.DefaultLanguage, eConfigGet_String))

    self:LoadLanguages()

    local aLocalizationData = self.Localization
    local sLog = string.format("Loaded ${red}%d${gray} Localizations", table.count(aLocalizationData))

    Logger:LogEventTo(GetDevs(), eLogEvent_ServerLocale, sLog)
end

----------------
ServerLocale.LocalizeForClient = function(self, hClient, sMsg, aFormat, ...)
    local sLang = hClient:GetPreferredLanguage()
    local iClientRank = hClient:GetAccess()

    local sLocalized, sExtended = Localize(sMsg, sLang, (hClient:IsDevRank()))
    if (sLocalized) then
        return Logger:FormatLocalized(sLocalized, aFormat)
    end

    return sMsg
end

----------------
ServerLocale.LocalizeNestForClient = function(self, hClient, sMsg, ...)

    local sLang = hClient:GetPreferredLanguage()
    local iClientRank = hClient:GetAccess()
    local bExtended = hClient:IsDevRank()

    local aFmt = { ... }
    local iNextFmt = 1

    local sNextLocalized
    local sNextLocale = sMsg
    local sFinalMsg = sMsg
    local aIgnore = {}

    local iMaxSteps = 10
    while (true) do

        --ServerLog("next stepp..%d",iNextFmt)
        --ServerLog(debug.traceback())

        if (iNextFmt >= iMaxSteps) then
            ServerLogWarning("localization recursion too deep (%d). Input: %s, Result: %s!", iNextFmt, sMsg, sFinalMsg)
            break
        end

        sNextLocale = string.match(sFinalMsg, "(@[%w_]+)")

        if (not sNextLocale) then
            --ServerLog("%s, no next locale found..!",sMsg)
            break
        end

        sNextLocalized = Localize(sNextLocale, sLang, bExtended ,true)
        if (not sNextLocalized or sNextLocalized == sNextLocale) then
            --ServerLog("failed for %s",sMsg)
            --break
            -- dont break, just destroy the current result, so we can try to localize the next one :3
            sNextLocalized = "{missing_" .. string.gsub(sNextLocale, "@", "") .. "}"
        end

        --ServerLog("next: %s === %s",sNextLocale,sNextLocalized)
        -- format next string
        sFinalMsg = sFinalMsg:gsub(sNextLocale, Logger:FormatLocalized(sNextLocalized, (aFmt[iNextFmt] or {})))
        iNextFmt = (iNextFmt + 1)
    end

    -- Return the fully localized message
    return sFinalMsg
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
ServerLocale.LocalizeText = function(self, sId, sLang, bForceExt, noReturn)

    local sDefault = self.DefaultLanguage
    local aLocale = self.Localization[string.lower(sId)]

    if (not sId) then
        throw_error("no id")
    end

    if (string.find(sId, " ") or not string.fc(sId, "@")) then
        --ServerLog("No localizing %s", sId)
        return
    end

    if (not aLocale) then
        HandleError("Missing Locale: " .. g_ts(sId))
        if (noReturn) then
            return sId--("!{error:missing_" .. string.gsub(sId, "@", "AT") .. "}")
        end
        return ("{error:missing_" .. sId .. "}")
    end

    sLang = (sLang or sDefault)
    local aContent = (aLocale[sLang] or aLocale[sDefault])

    --ServerLog(sLang)
   -- ServerLog(table.tostring(aLocale["english"]))
    if (not aContent) then

        HandleError("Missing Language: " .. g_ts(sLang) .. " for Locale " .. g_ts(sId))
        return ("{error:missing_" .. sId .. "_" .. sLang .. "}")
    end

    local sLocalized = aContent.regular
    local sExtra = aContent.extended

    if (bForceExt and sExtra) then
        return sExtra
    end

    return sLocalized, sExtra
end

----------------
ServerLocale.GetLocalization = function(self, sId, sLang, sExtended)

    if (not sId) then
        return false
    end

    local aLocale = self.Localization[string.lower(sId)]

    if (string.find(sId, " ") or not string.fc(sId, "@")) then
        return false
    end

    if (not aLocale) then
        return false
    end

    return true
end

----------------
ServerLocale.CreateLocalization = function(self, sId, aLanguages)

    sId = string.lower(sId)

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