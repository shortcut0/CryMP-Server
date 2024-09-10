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

        local aInfo = self:GetEntitiesInFront(eGet_Physicalized, 5, 2)
        if (not aInfo:None()) then
            if (aInfo.Indoors) then
                return false, self:Localize("@l_commandresp_notIndoors")
            end
            return false, self:Localize("@l_ui_EntitiesInFront", {aInfo.First or "Object"})
        end

        local vDir = self:SmartGetDir(1)
        local vPos, iFollowed = self:GetFacingPos(vDir, 8.5, eFollow_Auto, 1.5)

        --SpawnEffect(ePE_Flare,vPos)
        --SpawnEffect(ePE_Flare,self:GetPos())

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

        local hLast = self.LastTaxi
        if (hLast and GetEntity(hLast)) then
            if (hLast:GetPassengerCount() == 0) then
                ClientMod:OnAll(string.format([[
                ClientLog(GetEntity("%s"):GetName())
                    g_Client:DissolveVehicle(GetEntity("%s"),true)
                ]], hLast:GetName(), hLast:GetName()))
                Script.SetTimer(6000, function()
                    if (hLast and hLast:GetPassengerCount() == 0) then
                        RemoveEntity(hLast.id)
                    end
                end)
            end
        end
        Script.SetTimer(1, function()
            self.LastTaxi = SvSpawnEntity({

                Pos = vPos,
                Dir = vDir,

                Command = true,
                Class   = aClass[1],
                Count   = 1,

                RemovalTimer = 30,
            })
        end)
        SpawnEffect(ePE_Light, vPos)
        SendMsg(CHAT_SERVER, self, self:LocalizeNest("@l_ui_hereIsYour", {aClass[2]}))
    end
})

------------
AddCommand({
    Name = "supercab",
    Access = RANK_GUEST,

    Properties = {
        Prestige = 50,
        Cooldown = 60,
        Indoors = false,
    },

    Function = function(self)

        local aInfo = self:GetEntitiesInFront(eGet_Physicalized, 5, 2)
        if (not aInfo:None()) then
            if (aInfo.Indoors) then
                return false, self:Localize("@l_commandresp_notIndoors")
            end
            return false, self:Localize("@l_ui_EntitiesInFront", { aInfo.First or "Object" })
        end

        ClientMod:ChangeVehicleModel(self, nil, table.random({VM_TESLA}), true)
        SendMsg(CHAT_SERVER, self, self:LocalizeNest("@l_ui_hereIsYour", {"SuperCab"}))
    end
})

------------
AddCommand({
    Name = "audir8",
    Access = RANK_GUEST,

    Properties = {
        Prestige = 50,
        Cooldown = 60,
        Indoors = false,
    },

    Function = function(self)

        local aInfo = self:GetEntitiesInFront(eGet_Physicalized, 5, 2)
        if (not aInfo:None()) then
            if (aInfo.Indoors) then
                return false, self:Localize("@l_commandresp_notIndoors")
            end
            return false, self:Localize("@l_ui_EntitiesInFront", { aInfo.First or "Object" })
        end

        ClientMod:ChangeVehicleModel(self, nil, table.random({VM_AUDI}), true)
        SendMsg(CHAT_SERVER, self, self:LocalizeNest("@l_ui_hereIsYour", {"Audi R8"}))
    end
})