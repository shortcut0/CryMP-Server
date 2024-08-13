------------
AddCommand({
    Name = "rotation",
    Access = RANK_GUEST,
    Description = "@l_ui_commandDesc_Rotation",

    Arguments = {
    },

    Properties = {
    },

    Function = function(self)
        return ServerMaps:ListRotation(self)
    end
})
