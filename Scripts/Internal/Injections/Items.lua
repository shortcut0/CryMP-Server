------------
local ServerItems = {

    -----------------
    This = nil,
    PatchEntities = true,

    -----------------
    PostInit = function(self)
    end,

    ---------------------------------------------
    --- PatchShiTen
    ---------------------------------------------
    {

        Class = "ShiTen",
        Type  = eInjection_Replace,
        Target  = { "PatchShiTen" },
        Execute = true,

        ------------------------
        Function = function(self)
        end
    },

    ---------------------------------------------
    --- Server.OnHit
    ---------------------------------------------
    {

        Class = { "Item", "Item", "AutoTurret", "AutoTurretAA" },
        Type  = eInjection_Replace,
        Target  = { "Server.OnHit",  },

        ------------------------
        Function = function(self, aHitInfo)

            local explosionOnly=tonumber(self.Properties.bExplosionOnly or 0)~=0;
            local hitpoints = self.Properties.HitPoints;

            if (hitpoints and (hitpoints > 0)) then
                local destroyed=self.item:IsDestroyed()
                if (aHitInfo.type=="repair") then
                    self.item:OnHit(aHitInfo);
                elseif ((not explosionOnly) or (aHitInfo.explosion)) then
                    if ((not g_gameRules:IsMultiplayer()) or g_gameRules.game:GetTeam(aHitInfo.shooterId)~=g_gameRules.game:GetTeam(self.id)) then
                        self.item:OnHit(aHitInfo);
                        if (not destroyed) then
                            if (aHitInfo.damage>0) then
                                if (g_gameRules.Server.OnTurretHit) then
                                    g_gameRules.Server.OnTurretHit(g_gameRules, self, aHitInfo);
                                end
                            end

                            if (self.item:IsDestroyed()) then
                                if(self.FlowEvents and self.FlowEvents.Outputs.Destroyed)then
                                    self:ActivateOutput("Destroyed",1);
                                end
                            end
                        end
                    end
                end
            end

            --Debug("hiiiiit")

            if (self.item:GetHealth() <= 0) then
                g_pGame:SetSynchedEntityValue(self.id, 101, true)
                --Debug("bDestroyed")
            else--if (g_pGame:GetSynchedEntityValue(self.id, 100) == true) then
                g_pGame:SetSynchedEntityValue(self.id, 101, false)
               Debug("fixed")
            end
        end
    },
}

------------
ServerInjector.InjectAll(ServerItems)