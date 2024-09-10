local ServerVehicleBase = {

    -----------------
    This = "VehicleBase",
    PatchEntities = true,

    -----------------
    PostInit = function(self)
    end,

    ---------------------------------------------
    --- SvInit
    ---------------------------------------------
    {

        Class = table.append({ "VehicleBase" }, GetVehicleClasses() ),
        Target = { "SvInit" },
        Type = eInjection_Replace,

        ------------------------
        Function = function(self)

            if (self.Initialized) then
                return
            end

            self.Initialized = true
            self.FiringTimer = timernew()
            self.BombTimer   = timernew()

            self.Properties.VehicleInfo = {}
            self.VehicleInfo = self.Properties.VehicleInfo -- Points to the Property table

            -- Properties table is passed down to new vehicles upon respawn, so we can store data like CM here!
            local iCM = self.Properties.CM
            if (iCM) then
                ClientMod:ChangeVehicleModel(nil, self, iCM)
            end

            -- Vehicle Miniguns
            --self.HeliMGs = self.HeliMGs or {}
            if (self.class == "Asian_helicopter" and ConfigGet("General.Vehicles.AttachHeliMGs", false, eConfigGet_Boolean)) then
                local sMGClass = ConfigGet("General.Vehicles.HeliMGClass", "Hurricane", eConfigGet_String)
                self:AttachHeliMGs(sMGClass)
            end
        end
    },

    ---------------------------------------------
    --- IsOnDriverSeat
    ---------------------------------------------
    {

        Class = table.append({ "VehicleBase" }, GetVehicleClasses() ),
        Target = { "IsOnDriverSeat" },
        Type = eInjection_Replace,

        ------------------------
        Function = function(self, hPlayer)

            for _, aSeat in pairs(self.Seats) do
                if (aSeat:GetPassengerId() == hPlayer.id and aSeat.seat:IsDriver()) then
                    return true
                end
            end
            return false
        end

    },

    ---------------------------------------------
    --- DeleteHeliMGs
    ---------------------------------------------
    {

        Class = table.append({ "VehicleBase" }, GetVehicleClasses() ),
        Target = { "DeleteHeliMGs" },
        Type = eInjection_Replace,

        ------------------------
        Function = function(self, hID, hDef)

            if (self.HeliMGs) then
                for _, hMG in pairs(self.HeliMGs) do
                    System.RemoveEntity(_)
                end
            end
            self.HeliMGs = nil
        end

    },

    ---------------------------------------------
    --- FireHeliMGs
    ---------------------------------------------
    {

        Class = table.append({ "VehicleBase" }, GetVehicleClasses() ),
        Target = { "FireHeliMGs" },
        Type = eInjection_Replace,

        ------------------------
        Function = function(self, hShooter, bFire, bEndless)

            if (not self.HeliMGs) then
                return
            end

            if (hShooter) then
                if (hShooter:GetVehicle() ~= self) then
                    return
                end

                if (not self:IsOnDriverSeat(hShooter)) then
                    return
                end
            end

            for _, hMG in pairs(self.HeliMGs) do

                hMG.weapon:Sv_SetOwnerID(hShooter.id)
                --hMG.OwnerID = hShooter.id

                hMG.weapon:SetAmmoCount(nil, 250)
                hMG.weapon:SetAmmoCount(hMG.weapon:GetAmmoType(), 250)

                if (bFire and not hMG.Firing) then
                    hMG.Firing = true
                    hMG.weapon:Sv_RequestStartFire()
                    Debug("fire!")

                elseif (not bFire and hMG.Firing) then
                    hMG.Firing = false
                    hMG.weapon:Sv_RequestStopFire()
                end
            end

            if (bFire and not bEndless) then
                if (self.HeliMGStopFire) then
                    Script.KillTimer(self.HeliMGStopFire)
                end

                self.HeliMGStopFire = Script.SetTimer(250, function()
                    if (self.FiringTimer.expired()) then
                        self:FireHeliMGs(hShooter, false)
                    end
                end)
            end
        end
    },

    ---------------------------------------------
    --- SetHeliMGOwner
    ---------------------------------------------
    {

        Class = table.append({ "VehicleBase" }, GetVehicleClasses() ),
        Target = { "SetHeliMGOwner" },
        Type = eInjection_Replace,

        ------------------------
        Function = function(self, hID)

            if (not self.HeliMGs) then
                return
            end

            for _, hMG in pairs(self.HeliMGs) do
                hMG.weapon:Sv_SetOwnerID(hID)
            end

        end

    },

    ---------------------------------------------
    --- AttachHeliMGs
    ---------------------------------------------
    {

        Class = table.append({ "VehicleBase" }, GetVehicleClasses() ),
        Target = { "AttachHeliMGs" },
        Type = eInjection_Replace,

        ------------------------
        Function = function(self, sClass)

            sClass = (sClass or "Hurricane")

            if (self.HeliMGs) then
                self:DeleteHeliMGs()
            end

            self.HeliMGs = {}

            local hMG1 = System.SpawnEntity({
                class    = sClass,
                position = self:GetPos(),
                name     = self:GetName() .. "_mg_left"
            })
            local hMG2 = System.SpawnEntity({
                class    = sClass,
                position = self:GetPos(),
                name     = self:GetName() .. "_mg_right"
            })

            hMG1.SvCannotGrab = true
            hMG2.SvCannotGrab = true

            self.HeliMGClass = sClass
            self.HeliMGs[hMG1.id] = hMG1
            self.HeliMGs[hMG2.id] = hMG2

            self:AttachChild(hMG1.id, 1)
            self:AttachChild(hMG2.id, 1)

            local vDir = self:GetDirectionVector()
            hMG1:SetDirectionVector(vDir)
            hMG2:SetDirectionVector(vDir)

            local aBBox = self:GetLocalBBox(1)
            local iX = 3.05
            local iY = -0.65
            local iZ = 0.25
            if (self.class ~= "Asian_helicopter") then

                iX = 1.8
                iY = 1.2
                iZ = 1.2
                if (self.class:find("tank") or self.class:find("apc") or self.class:find("Asian_aaa")) then
                    iX = 2.2
                    iY = -0.5
                    iZ = 1.2
                elseif (self.class:find("vtol")) then
                    iZ = -2
                    iY = -1.5
                    iX = 1.8
                end

                iX = 1.2
                iY = (aBBox.y / 2)
                iZ = 1

                local vHood = self:ToLocal(0, self:GetHelperPos("Engine"))
                if (vHood) then
                    vHood = {
                        x = vHood.x + 1.2,
                        y = vHood.y + 2,
                        z = vHood.z + 1.3,
                    }
                    iX = vHood.x
                    iY = vHood.y
                    iZ = vHood.z
                    Debug("hood",vHood)
                end
            end

            hMG1:SetLocalPos({ x = iX,  y = iY, z = iZ })
            hMG2:SetLocalPos({ x = -iX, y = iY, z = iZ })

            ClientMod:OnAll(string.format("g_Client:HELIMG(\"%s\",%f,%f,%f)",
                    self:GetName(),
                    iX, iY, iZ
            ), {
                Sync = true,
                SyncID = "HeliMG",
                BindID = self.id,
            })
        end
    },

    ---------------------------------------------
    --- GetInfo
    ---------------------------------------------
    {

        Class = table.append({ "VehicleBase" }, GetVehicleClasses() ),
        Target = { "GetInfo" },
        Type = eInjection_Replace,

        ------------------------
        Function = function(self, hID, hDef)

            if (not self.Initialized) then
                self:SvInit()
            end

            local hVal = self.VehicleInfo[hID]
            if (hVal == nil) then
                return hDef
            end
            return hVal
        end
    },

    ---------------------------------------------
    --- SetInfo
    ---------------------------------------------
    {

        Class = table.append({ "VehicleBase" }, GetVehicleClasses() ),
        Target = { "SetInfo" },
        Type = eInjection_Replace,

        ------------------------
        Function = function(self, hID, hVal)

            if (not self.Initialized) then
                self:SvInit()
            end

            local hOld = self:GetInfo(hID)
            self.VehicleInfo[hID] = hVal
            return hOld
        end
    },

    ---------------------------------------------
    --- GetDriver
    ---------------------------------------------
    {

        Class = table.append({ "VehicleBase" }, GetVehicleClasses() ),
        Target = { "GetDriver" },
        Type = eInjection_Replace,

        ------------------------
        Function = function(self)
            return GetEntity(self:GetDriverId())
        end
    },

    ---------------------------------------------
    --- GetDriver
    ---------------------------------------------
    {

        Class = table.append({ "VehicleBase" }, GetVehicleClasses() ),
        Target = { "CanEnter" },
        Type = eInjection_Replace,

        ------------------------
        Function = function(self, hUserID)
            local bOk = true
            if (g_gameRules and g_gameRules.CanEnterVehicle) then
                bOk = g_gameRules:CanEnterVehicle(self, hUserID)
            end

            if (bOk) then
                self:SetInfo("WasUsed", true)
                return true
            end
            return false
        end
    },

    ---------------------------------------------
    --- GetNearestFreeSeat
    ---------------------------------------------
    {

        Class = table.append({ "VehicleBase" }, GetVehicleClasses() ),
        Target = { "GetNearestFreeSeat" },
        Type = eInjection_Replace,

        ------------------------
        Function = function(self, vPos)
            local aNearest = { nil, -1 }
            for _, aSeat in pairs(self.Seats) do
                if (aSeat.seat:IsFree()) then
                    local iDistance = vector.distance(self:GetSeatEnterPosition(aSeat.seatId), vPos)
                    if (aNearest[2] == -1 or iDistance < aNearest[2]) then
                        aNearest = {
                            aSeat.seatId,
                            iDistance
                        }
                    end
                end
            end
            return aNearest[1], aNearest[2]
        end
    },

    ---------------------------------------------
    --- GetSeatEnterPosition
    ---------------------------------------------
    {

        Class = table.append({ "VehicleBase" }, GetVehicleClasses() ),
        Target = { "GetSeatEnterPosition" },
        Type = eInjection_Replace,

        ------------------------
        Function = function(self, iSeat)

            local vEnterPos = self:GetPos()
            local aSeat = self.Seats[iSeat]
            if (not aSeat) then
                return vEnterPos
            end

            if (aSeat.exitHelper) then
                vEnterPos = self.vehicle:MultiplyWithWorldTM(self:GetVehicleHelperPos(aSeat.exitHelper))
            elseif (aSeat.enterHelper) then
                vEnterPos = self.vehicle:MultiplyWithWorldTM(self:GetVehicleHelperPos(aSeat.enterHelper))
            end

            return vEnterPos
        end
    },

    ---------------------------------------------
    --- IsEmpty
    ---------------------------------------------
    {

        Class = table.append({ "VehicleBase" }, GetVehicleClasses() ),
        Target = { "IsEmpty" },
        Type = eInjection_Replace,

        ------------------------
        Function = function(self, iSeat)
            return (self:GetPassengerCount() == 0)
        end
    },

    ---------------------------------------------
    --- Server.OnHit
    ---------------------------------------------
    {

        Class = table.append({ "VehicleBase" }, GetVehicleClasses() ),
        Target = { "Server.OnHit" },
        Type = eInjection_Replace,

        ------------------------
        Function = function(self, aHitInfo)

            local explosion = aHitInfo.explosion or false
            local targetId = (explosion and aHitInfo.impact) and aHitInfo.impact_targetId or aHitInfo.targetId;
            local hitType = (explosion and aHitInfo.type == "") and "explosion" or aHitInfo.type;
            local direction = aHitInfo.dir;
            local hDriver = self:GetDriver()
            if (hDriver and hDriver.IsPlayer and hDriver:HasGodMode()) then
                aHitInfo.damage = 0
            end

            for _, aSeat in pairs(self.Seats) do
                local hPassenger = GetEntity(aSeat:GetPassengerId())
                if (hPassenger) then
                    if (hPassenger.IsPlayer and hPassenger:HasGodMode()) then
                        aHitInfo.damage = 0 break
                    end
                end
            end

            -- prevents infinite chain explosions from respawning vehicles damaging each other
            local hWeapon = aHitInfo.weapon
            if (not self:GetInfo("WasUsed") and (aHitInfo.explosion or hitType == "fire") and hWeapon and hWeapon.vehicle and hWeapon ~= self) then
                aHitInfo.damage = 0
            end

            if(aHitInfo.type ~= "fire" and aHitInfo.damage > 0) then
                g_gameRules.game:SendHitIndicator(aHitInfo.shooterId, aHitInfo.explosion~=nil)
            end

            if(aHitInfo.type == "collision") then
                direction.x = -direction.x
                direction.y = -direction.y
                direction.z = -direction.z

                if (self.IsJetVM) then
                   -- Debug(self:GetSpeed())
                    aHitInfo.damage = aHitInfo.damage * 5 * math.max(1, math.min(10, self:GetSpeed()/10))
                end
            end

            ServerItemHandler:CheckVehicleHit(self, aHitInfo)

            self.vehicle:OnHit(targetId, aHitInfo.shooterId, aHitInfo.damage, aHitInfo.pos, aHitInfo.radius, hitType, explosion)

            --[[
            if (AI and hit.type ~= "collision") then
                if (hit.shooter) then
                    g_SignalData.id = hit.shooterId;
                else
                    g_SignalData.id = NULL_ENTITY;
                end
                g_SignalData.fValue = hit.damage;
                if (hit.shooter and self.Properties.species ~= hit.shooter.Properties.species) then
                    CopyVector(g_SignalData.point, hit.shooter:GetWorldPos());
                    AI.Signal(SIGNALFILTER_SENDER,0,"OnEnemyDamage",self.id,g_SignalData);
                elseif (self.Behaviour and self.Behaviour.OnFriendlyDamage ~= nil) then
                    AI.Signal(SIGNALFILTER_SENDER,0,"OnFriendlyDamage",self.id,g_SignalData);
                else
                    AI.Signal(SIGNALFILTER_SENDER,0,"OnDamage",self.id,g_SignalData);
                end
            end]]

            local bDestroyed = self.vehicle:IsDestroyed()
            if (bDestroyed) then

                if (self.HeliMGs) then
                    self:DeleteHeliMGs()
                end

                if (self.CM) then
                    System.RemoveEntity(self.CM)
                end
            end
            return bDestroyed
        end,

    },

    ---------------------------------------------
    --- KillPlayers
    ---------------------------------------------
    {

        Class = table.append({ "VehicleBase" }, GetVehicleClasses() ),
        Target = { "GetPassengerCount" },
        Type = eInjection_Replace,

        ------------------------
        Function = function(self, player, time)
            local iCount = 0
            for _, aSeat in pairs(self.Seats) do
                if (aSeat:GetPassengerId()) then
                     iCount = iCount + 1
                end
            end
            return iCount
        end
    }

}

---------------------
ServerInjector.InjectAll(ServerVehicleBase)