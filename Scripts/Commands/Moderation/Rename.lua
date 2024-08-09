------------
AddCommand({
    Name = "rename",
    Access = RANK_ADMIN, -- Must be accessible to all!

    Arguments = {
        {
            Name = "@l_ui_player",
            Desc = "@l_ui_player_d",
            Required = true,
            IsPlayer = true,
            EqualAccess = true,
        },
        {   Name = "@l_ui_name",
            Desc = "@l_ui_newname_d",
            Required = true,
        },
        {
            Name = "@l_ui_reason",
            Desc = "@l_ui_reason_d",
            Default = "Admin Decision",
            Concat  = true
        }
    },

    Properties = {
    },

    Function = function(self, hTarget, sNewName, sReason)
        return ServerNames:RequestRename(hTarget, sNewName, self, sReason)
    end
})