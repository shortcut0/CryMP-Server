------------
AddCommand({
    Name = "taxi",
    Access = RANK_GUEST,

    Properties = {
        Prestige = 50,
        Cooldown = 60,
        Indoors = false,
    },

    Function = function(self)

        local aInfo = self:GetEntitiesInFront(eGet_Physicalized, 3, 2)
        if (not aInfo:None()) then
            if (aInfo.Indoors) then
                return false, self:Localize("@l_commandresp_notIndoors")
            end
            return false, self:Localize("@l_ui_EntitiesInFront", {aInfo.First or "Object"})
        end

        local vPos, iFollowed = self:GetFacingPos(eFacing_Front, 8.5, eFollow_Auto, 1.5)

        local aClass = {
            "Civ_car1",
            "@l_ui_taxi",
        }

        if (iFollowed == eFollow_Water) then
            aClass = {
                "US_smallboat",
                "@l_ui_boat"
            }
        end

        SvSpawnEntity({

            Pos = vPos,
            Dir = self.actor:GetRotation(),

            Command = true,
            Class   = aClass[1],
            Count   = 1
        })
        SpawnEffect(ePE_Light, vPos)
        SendMsg(CHAT_SERVER, self, self:LocalizeNest("@l_ui_hereIsYour", {aClass[2]}))
    end
})