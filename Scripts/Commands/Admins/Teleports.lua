------------
AddCommand({
    Name = "tpto",
    Access = RANK_ADMIN, -- Must be accessible to all!

    Arguments = {
        { "@l_ui_x", "@l_ui_xcoord_d", Required = true, Default = 0, IsNumber = true, Min = 0, Max = 9999999 },
        { "@l_ui_y", "@l_ui_ycoord_d", Required = true, Default = 0, IsNumber = true, Min = 0, Max = 9999999 },
        { "@l_ui_z", "@l_ui_zcoord_d", Required = true, Default = 0, IsNumber = true, Min = 0, Max = 9999999 },
    },

    Properties = {
    },

    Function = function(self, iX, iY, iZ)

        local vPos = self:GetPos()
        vPos.x = iX == 0 and vPos.x or iX
        vPos.y = iY == 0 and vPos.y or iY
        vPos.z = iZ == 0 and vPos.z or iZ

        self:SvMoveTo(vPos, self:GetAngles())

        SendMsg(CHAT_SERVER, self, self:Localize("@l_ui_teleportedTo", { string.format("x = %0.2f, y = %0.2f, z = %0.2f", vPos.x, vPos.y, vPos.z) }))
    end
})

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

        local vPos = self:GetFacingPos(eFacing_Front, iDistance, (bFollow and eFollow_Auto or nil), 10000)
        self:SvMoveTo(vPos, self:GetAngles())

        SendMsg(CHAT_SERVER, self, self:Localize("@l_ui_teleportedFWD", { string.format("%0.2f", iDistance) }))
    end
})

------------
AddCommand({
    Name = "tpup",
    Access = RANK_ADMIN, -- Must be accessible to all!

    Arguments = {
        { "@l_ui_distance", "@l_ui_distance_d", Optional = true, Default = 10, IsNumber = true },
    },

    Properties = {
    },

    Function = function(self, iDistance)

        local vPos = vector.modifyz(self:GetPos(), iDistance)
        self:SvMoveTo(vPos, self:GetAngles())

        SendMsg(CHAT_SERVER, self, self:Localize("@l_ui_teleportedUP", { string.format("%0.2f", iDistance) }))
    end
})