------------
AddCommand({
    Name = "banner",
    Access = GetLowestRank(), -- Must be accessible to all!
    Description = "Shows the Server Welcome Banner",

    Arguments = {
        { "@l_ui_language", "@l_ui_language_d", Optional = true }
    },

    Properties = {
        Host = "ServerPCH",
        NoConsoleResponse = true
    },

    -- self is the user unless specified otherwise
    Function = function(self, hPlayer, sLang)

        self:SendBanner(hPlayer, sLang)
        return true, "Open your Console to view the Banner!"
    end
})