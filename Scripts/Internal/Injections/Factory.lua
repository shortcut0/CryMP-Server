------------
local ServerFactory = {

    -----------------
    This = "Factory",
    PatchEntities = true,

    -----------------
    PostInit = function(self)
    end,

    ---------------------------------------------
    --- KillPlayers
    ---------------------------------------------
    {

        Class = "Factory",
        Target = { "KillPlayers" },
        Type = eInjection_Replace,

        ------------------------
        Function = function(self, hSlot)

            Debug("kill hit!!")

            if (not ConfigGet("General.GameRules.HitConfig.FactoryKills", true, eConfigGet_Boolean)) then
                return
            end

            local aEntities = self:GetNearbyEntities(true, false)
            if (aEntities) then
                local iAreaID = hSlot.areaId
                for _, hEntity in pairs(aEntities) do
                    if (self:IsPointInsideArea(iAreaID, hEntity:GetWorldPos(g_Vectors.temp_v1))) then
                        if (hEntity.actor and (not hEntity:IsDead())) then
                            g_gameRules:CreateHit(hEntity.id, hEntity.id, NULL_ENTITY, 1000)
                        end
                    end
                end
            end

        end

    },

    ---------------------------------------------
    --- UpdateSlot
    ---------------------------------------------
    {

        Class = "Factory",
        Target = { "UpdateSlot" },
        Type = eInjection_Replace,

        ------------------------
        Function = function(self, hSlot, iFrameTime)

            if (not hSlot.enabled) then
                return
            end

            if (hSlot.building) then
                hSlot.buildTimer = (hSlot.buildTimer - iFrameTime)

                if (hSlot.buildTimer <= 0) then
                    local hVehicle = self:BuildVehicle(hSlot)
                    self:StopBuilding(hSlot, true)

                    if (g_gameRules.Server.OnVehicleBuilt) then
                        g_gameRules.Server.OnVehicleBuilt(g_gameRules, self, hSlot.buildVehicle, hVehicle.id, hSlot.buildOwnerId, hSlot.buildTeamId, hSlot.id)
                    end

                    self.allClients:ClVehicleBuilt(hSlot.buildVehicle, hVehicle.id, hSlot.buildOwnerId, hSlot.buildTeamId, hSlot.id)
                    hSlot.builtVehicleId = hVehicle.id
                end
            end

            if (hSlot.opening) then
                hSlot.openTimer = (hSlot.openTimer - iFrameTime)
                if (hSlot.openTimer <= 0) then

                    if (not self.isClient) then
                        self:OpenSlot(hSlot, true, false)
                    end

                    -- need to tell the clients that this is a buy zone
                    if (hSlot.builtVehicleId) then
                        local aDef = g_gameRules:GetItemDef(hSlot.buildVehicle);
                        if (aDef.buyzoneradius and aDef.buyzoneflags) then
                            self.allClients:ClSetBuyFlags(hSlot.builtVehicleId, aDef.buyzoneflags)
                            local hVehicle = GetEntity(hSlot.buildVehicle)
                            if (hVehicle) then

                                -- Save it for sync for clients that connect after the fact
                                hVehicle.BuyZoneSynch = {
                                    FactoryID = self.id,
                                    Flags     = aDef.buyzoneflags
                                }
                            end
                        end
                    end

                    self.allClients:ClOpenSlot(hSlot.id, true, false)
                    hSlot.opening = false
                    hSlot.builtVehicleId = nil
                end

            elseif(hSlot.closing) then
                self:KillPlayers(hSlot)
                hSlot.closeTimer = (hSlot.closeTimer - iFrameTime)

                if (hSlot.closeTimer <= 0) then
                    if (not self.isClient) then
                        self:OpenSlot(hSlot, false, false)
                    end

                    self.allClients:ClOpenSlot(hSlot.id, false, false)
                    hSlot.closing = false
                end
            end
        end
    },

}

------------
ServerInjector.InjectAll(ServerFactory)