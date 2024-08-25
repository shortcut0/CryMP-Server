local ServerVehicleBase = {

    -----------------
    This = "VehicleBase",
    PatchEntities = true,

    -----------------
    PostInit = function(self)
    end,

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

            if(aHitInfo.type ~= "fire") then
                g_gameRules.game:SendHitIndicator(aHitInfo.shooterId, aHitInfo.explosion~=nil)
            end

            if(aHitInfo.type == "collision") then
                direction.x = -direction.x;
                direction.y = -direction.y;
                direction.z = -direction.z;
            end

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
            if (bDestroyed and self.CM) then
                System.RemoveEntity(self.CM)
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