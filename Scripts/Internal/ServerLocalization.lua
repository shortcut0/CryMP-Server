NO_LANGUAGE = "none"

-----------------
ServerLocale = {

    LocaleDir = (SERVER_DIR_DATA .. "Locale\\"),
    LocaleFiles = "\.(txt|json|lua)$",

    Localization = {},
    DefaultLanguage = "english",
    AvailableLanguages = { "english", "german", "spanish", "russian", "turkish", "czech", "russian_andrey" }
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

    --self:TranslateText()
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
    if (sLang == NO_LANGUAGE) then
        sLang = sDefault
    end
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
ServerLocale.TranslateText = function(self, sId)
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

    local sRussian = self.Localization[sId]["russian"]
    if (sRussian) then
        if (self.Localization[sId]["russian_andrey"] == nil) then

            if (isArray(sRussian)) then
                self.Localization[sId]["russian_andrey"] = {
                    regular = sRussian.regular and self:TranslateRussianToAndrey(sRussian.regular),
                    extended = sRussian.extended and self:TranslateRussianToAndrey(sRussian.extended)
                }
            else
                self.Localization[sId]["russian_andrey"] = { regular = self:TranslateRussianToAndrey(sRussian)
                }
            end
        end
    end
end

----------------
ServerLocale.TranslateRussianToAndrey = function(self, sMsg) -- TODO: Rename this

    local aMap = {
        { "А", "A", "A" }, { "Б", "B", "B" }, { "В", "V", "B" }, { "Г", "G", "r" }, { "Д", "D", "D" }, { "Е", "E", "E" },
        { "Ё", "Yo", "E" }, { "Ж", "Zh", ")|(" }, { "З", "Z", "3" }, { "И", "I", "N" }, { "Й", "Y", "N" }, { "К", "K", "K" },
        { "Л", "L", "L" }, { "М", "M", "M" }, { "Н", "N", "H" }, { "О", "O", "O" }, { "П", "P", "P" }, { "Р", "R", "P" },
        { "С", "S", "C" }, { "Т", "T", "T" }, { "У", "U", "Y" }, { "Ф", "F", "O" }, { "Х", "Kh", "X" }, { "Ц", "Ts", "U" },
        { "Ч", "Ch", "y" }, { "W", "Sh", "w" }, { "Щ", "Sch", "W" }, { "Ъ", "''", "b" }, { "Ы", "Y", "bl" }, { "Ь", "'", "b" },
        { "Э", "E", "3" }, { "Ю", "Yu", "IO" }, { "Я", "Ya", "R" },
        { "а", "a", "a" }, { "б", "b", "b" }, { "в", "v", "B" }, { "г", "g", "r" }, { "д", "d", "D" }, { "е", "e", "e" },
        { "ё", "yo", "e" }, { "ж", "zh", ")|(" }, { "з", "z", "3" }, { "и", "i", "N" }, { "й", "y", "N" }, { "к", "k", "k" },
        { "л", "l", "n" }, { "м", "m", "m" }, { "н", "n", "H" }, { "о", "o", "o" }, { "п", "p", "n" }, { "р", "r", "p" },
        { "с", "s", "c" }, { "т", "t", "T" }, { "у", "u", "y" }, { "ф", "f", "O" }, { "х", "kh", "x" }, { "ц", "ts", "u" },
        { "ч", "ch", "y" }, { "ш", "sh", "w" }, { "щ", "sch", "w" }, { "ъ", "''", "b" }, { "ы", "y", "bl" }, { "ь", "'", "b" },
        { "э", "e", "3" }, { "ю", "yu", "lO" }, { "я", "ya", "R" }
    }

    local sChar_Previous = ""
    local sTrans    = ""
    local bFound    = false
    local bFmtOpen  = false
    local nSkip     = 0

    for i, sChar in pairs(string.split(sMsg, "")) do
        bFound   = false
        bFmtOpen = bFmtOpen or (sChar == "{" and sChar_Previous == "$")

        if (sChar == "}") then
            bFmtOpen = false
        end

        if (nSkip == 0 or i >= nSkip) then
            nSkip = 0
            if (not bFmtOpen) then
                if (not string.matchex(sChar, ",", "%s", "%d", "%$", "{", "}", "%(", "%)", ":")) then
                    for __, aInfo in pairs(aMap) do

                        --if (aInfo[2] == "ch") then
                        --    ServerLog(string.sub(sMsg, i, i+string.len(aInfo[2])-1))
                        --end
                        --
                        if (aInfo[2] == sChar or aInfo[2] == string.sub(sMsg, i, i + string.len(aInfo[2]) - 1)) then
                            sTrans = sTrans .. aInfo[3]
                            bFound = true
                            nSkip  = i + string.len(aInfo[2])
                            --ServerLog("%s==%s",aInfo[2],string.sub(sMsg, i, i+string.len(aInfo[2])))
                            --ServerLog("skipping to %d (%d)",nSkip,i)
                            break
                        end
                    end
                    if (not bFound) then
                        if (DebugMode()) then
                            ServerLog("unknown character: %s for msg %s", sChar, sMsg)
                        end
                    end
                end
            else
                --    ServerLog("format open.. ignoring sequence %s",sChar)
            end
            if (not bFound) then
                sTrans = sTrans .. sChar
            end
            sChar_Previous = sChar
        else
            --ServerLog("skipping %d",i)
        end
    end

    if (DebugMode()) then
        ServerLog("Translated %-60s <===> %s", sMsg, sTrans)
    end

    --if (sMsg == "Igroka") then
    --    ServerLog("translation for Igroka is %s",sTrans)
    --end
    return sTrans

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
                    throw_error("unsupported type")

                elseif (sType == "json") then

                    -- FIXME
                    throw_error("unsupported type")

                else
                    ServerLog("Unknown file type!! help!!")
                end
            end
        end
    end
end