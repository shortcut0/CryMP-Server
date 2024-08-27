------------
AddCommand({
    Name = "name",
    Access = RANK_GUEST, -- Must be accessible to all!

    Arguments = {
        { "@l_ui_name", "@l_ui_newname_d", Required = true, Concat = true },
    },

    Properties = {
    },

    Function = function(self, sNewName)

        if (string.lower(sNewName) == string.lower(self:GetName())) then
            return false, "@l_ui_chooseDifferentName"
        end

        return ServerNames:RequestRename(self, sNewName)
    end
})