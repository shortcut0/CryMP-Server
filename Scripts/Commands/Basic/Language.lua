------------
AddCommand({
    Name = "language",
    Access = GetLowestRank(), -- Must be accessible to all!
    Description = "@l_ui_command_Language_Description",

    Arguments = {
        { "@l_ui_language", "@l_ui_language_d", Optional = true }
    },

    Properties = {
        Host = "ServerPCH",
        NoConsoleResponse = true
    },

    -- self is the user unless specified otherwise
    Function = function(self, sNewLang)

        if (not sNewLang) then
            return true, self:Localize("@l_ui_availableLanguages", self:GetPreferredLanguage(), table.concat(AVAILABLE_LANGUAGES, ", "))
        end

        if (not table.findv(AVAILABLE_LANGUAGES, string.lower(sNewLang))) then
            return false, "@l_ui_languageNotFound", sNewLang
        end
        return true, "@l_ui_languageUpdatedTo", sNewLang
    end
})