------------
local ServerFactory = {

    -----------------
    This = "Factory",
    PatchEntities = true,

    -----------------
    PostInit = function(self)
    end,

    ---------------------------------------------
    --- Queue
    ---------------------------------------------
    {

        Class = "Factory",
        Target = { "Queue" },
        Type = eInjection_Replace,

        ------------------------
        Function = function(self, class, ownerId)

            local hPlayer = GetEntity(ownerId)
            if (hPlayer and hPlayer.IsPlayer) then
                table.checkM(self, "JobFloods", {})
                table.checkM(self.JobFloods, ownerId, { Timer = timernew(0.5), Flood = 0 })

                local aJob = self.JobFloods[ownerId]
                local bExpired = aJob.Timer.expired()

                aJob.Timer.refresh()

                if (not bExpired) then
                    aJob.Flood = (aJob.Flood + 1)
                    if (aJob.Flood > 2) then
                        -- No more than 2 vehicles within 0.5s, otherwise it's considered spam!
                        --SendMsg(MSG_ERROR, hPlayer, hPlayer:Localize("@l_ui_floodBlocked"))
                        return
                    end
                else
                    aJob.Flood = 0
                end
            end

            local slot=self:GetFreeSlot();
            if (slot) then
                local time=self:GetBuildTime(class);
                if (not time) then
                    Log("Vehicle Factory %s - Can't build that!", self:GetName());

                    return false;
                end
                self:StartBuilding(slot, time, class, ownerId, g_gameRules.game:GetTeam(ownerId));

                return true;
            end

            if (self:AddToQueue(class, ownerId)) then
                return true;
            else
                Log("Vehicle Factory %s - No free factory slots available and queue is full!", self:GetName());

                return false;
            end
        end
    },

    ---------------------------------------------
    --- KillPlayers
    ---------------------------------------------
    {

        Class = "Factory",
        Target = { "BuildVehicle" },
        Type = eInjection_Replace,

        ------------------------
        Function = function(self, hSlot)

            local def=g_gameRules:GetItemDef(hSlot.buildVehicle);
            if ((not def) or (not def.vehicle)) then
                return
            end

            local pos, dir = self:GetParkingLocation(hSlot)
            if (def.modification) then
                self.spawnparams.properties.Modification=def.modification
            else
                self.spawnparams.properties.Modification=nil
            end

            if (def.abandon) then
                if (def.abandon>0) then
                    self.spawnparams.properties.Respawn.bAbandon=1;
                    self.spawnparams.properties.Respawn.nAbandonTimer=def.abandon;
                else
                    self.spawnparams.properties.Respawn.bAbandon=0;
                end
            else
                self.spawnparams.properties.Respawn.bAbandon=1;
                self.spawnparams.properties.Respawn.nAbandonTimer=300;
            end

            self.spawnparams.position=pos;
            self.spawnparams.orientation=dir;

            -- make names unique!
            self.spawnparams.name=hSlot.buildVehicle.."_built_" .. UpdateCounter(eCounter_Generic);
            self.spawnparams.class=def.class;
            self.spawnparams.position.z=pos.z;

            if (self:GetTeamId()~=0 and g_gameRules.VehiclePaint) then
                self.spawnparams.properties.Paint = g_gameRules.VehiclePaint[g_gameRules.game:GetTeamName(self:GetTeamId())] or "";
            end

            local vehicle=System.SpawnEntity(self.spawnparams);

            if (vehicle) then
                Log("Vehicle Factory %s - Built %s at door %s...", self:GetName(), hSlot.buildVehicle, hSlot.id);

                vehicle.builtas=hSlot.buildVehicle;
                vehicle.vehicle:SetOwnerId(hSlot.buildOwnerId);
                g_gameRules.game:SetTeam(hSlot.buildTeamId, vehicle.id);
                self:AdjustVehicleLocation(vehicle); -- adjust the position of the vehicle so that the vehicle is centered in the spawn helper,
                -- using the center of the bounding box
                vehicle:AwakePhysics(1);
            end

            if (def.buyzoneradius) then
                self:MakeBuyZone(vehicle, def.buyzoneradius*1.15, def.buyzoneflags);

                if (not def.spawngroup) then
                    g_gameRules.game:AddMinimapEntity(vehicle.id, 1, 0);
                end
            end

            if (def.servicezoneradius) then
                self:MakeServiceZone(vehicle, def.servicezoneradius*1.15);
            end

            if (def.spawngroup) then
                g_gameRules.game:AddSpawnGroup(vehicle.id);
            end

            return vehicle;
        end

    },

    ---------------------------------------------
    --- KillPlayers
    ---------------------------------------------
    {

        Class = "Factory",
        Target = { "KillPlayers" },
        Type = eInjection_Replace,

        ------------------------
        Function = function(self, hSlot)

            --Debug("kill hit!!")

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