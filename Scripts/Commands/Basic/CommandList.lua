------------
AddCommand({
    Name = "commands",
    Access = GetLowestRank(), -- Must be accessible to all!
    Description = "@l_ui_command_desc_commands",

    Arguments = {
        { "@l_ui_access", "@l_ui_access_d", Optional = true }
    },

    Properties = {
        Host = "ServerCommands",
        NoConsoleResponse = true
    },

    -- self is the user unless specified otherwise
    Function = function(self, hPlayer, sRank)
        self:ListCommands(hPlayer, nil, sRank)
        return true, hPlayer:Localize("@l_ui_commands_openconsole")
    end
})