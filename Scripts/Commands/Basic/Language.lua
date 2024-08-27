------------
AddCommand({
    Name = "language",
    Access = GetLowestRank(), -- Must be accessible to all!
    Description = "@l_ui_command_Language_Description",

    Arguments = {
        { "@l_ui_language", "@l_ui_language_d", Optional = true }
    },

    Properties = {
        NoConsoleResponse = true
    },

    -- self is the user unless specified otherwise
    Function = function(self, sNewLang)

        if (not sNewLang) then
            return true, self:Localize("@l_ui_availableLanguages", { table.concat(AVAILABLE_LANGUAGES, ", ") })
        end

        if (string.lower(sNewLang) == NO_LANGUAGE) then
            self:SetPreferredLanguage(NO_LANGUAGE)
            self.WantNoLanguage = true
            return true, self:Localize("@l_ui_languageUpdatedTo", {"@l_ui_default"})
        end
        if (not table.findv(AVAILABLE_LANGUAGES, string.lower(sNewLang))) then
            return false, self:Localize("@l_ui_languageNotFound", { sNewLang })
        end

        self:SetPreferredLanguage(sNewLang)
        return true, self:Localize("@l_ui_languageUpdatedTo", {sNewLang})
    end
})