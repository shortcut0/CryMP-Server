------------
AddCommand({
    Name = "tpf",
    Access = RANK_ADMIN, -- Must be accessible to all!

    Arguments = {
        { "@l_ui_distance", "@l_ui_distance_d", Optional = true, Default = 10, IsNumber = true },
        { "@l_ui_argument", "@l_ui_argument_d", Optional = true }
    },

    Properties = {
    },

    Function = function(self, iDistance, bFollow)

        local vPos = self:GetFacingPos(eFacing_Front, iDistance, (bFollow and eFollow_Auto or nil), 1)
        self:SvMoveTo(vPos, self:GetAngles())

        SendMsg(CHAT_SERVER, self, self:Localize("@l_ui_teleportedFWD", { string.format("%0.2f", iDistance) }))
    end
})