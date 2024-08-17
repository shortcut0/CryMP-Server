------------
local ServerHQ = {

    -----------------
    This = "HQ",
    PatchEntities = true,

    -----------------
    PostInit = function(self)

        for _, hEntity in pairs(GetEntities("HQ")) do
            hEntity:ServerInit()
        end
    end,

    ---------------------------------------------
    --- ServerInit
    ---------------------------------------------
    {

        Class = "HQ",
        Target = { "ServerInit" },
        Type = eInjection_Replace,

        ------------------------
        Function = function(self)
            self.RemainingHits = 0
        end

    },

    ---------------------------------------------
    --- Server.OnHit
    ---------------------------------------------
    {

        Class = "HQ",
        Target = { "Server.OnHit" },
        Type = eInjection_Replace,

        ------------------------
        Function = function(self, aHitInfo)

            if (self.destroyed) then
                return
            end

            if (not aHitInfo.shooter) then
                return
            end

            SystemLog("HQ[%s] Was hit by [%s] (damage = %f, weapon = %s)", self:GetName(), aHitInfo.shooter:GetName(), aHitInfo.damage or 0.0, (aHitInfo.weapon and aHitInfo.weapon.class or "No WEAPON"));

            -- !hook
            self:ServerHit(aHitInfo)

            local bDestroyed = false
            local teamId = g_pGame:GetTeam(aHitInfo.shooterId)
            if (teamId == 0 or teamId ~= self:GetTeamId()) then
                if (aHitInfo.explosion and aHitInfo.type == "tac") then
                    self:SetHealth(self:GetHealth() - aHitInfo.damage)
                    if (self:GetHealth() <= 0) then
                        bDestroyed = true
                    end

                    if (aHitInfo.damage > 0 and aHitInfo.type ~= "repair") then
                        if (g_gameRules.Server.OnHQHit) then
                            g_gameRules.Server.OnHQHit(g_gameRules, self, aHitInfo)
                        end
                    end
                end
            end

            if (bDestroyed) then
                self.HQDestroyed = true
                if (not self.isClient) then
                    self:Destroy()
                end

                self.allClients:ClDestroy()
                if (g_gameRules and g_gameRules.OnHQDestroyed) then
                    g_gameRules:OnHQDestroyed(self, aHitInfo.shooterId, teamId)
                end

                SpawnEffect("atom_effects.explosions.nuke", self:GetPos(), g_Vectors.up, 0.3)
            end

            return bDestroyed
        end
    },

    ---------------------------------------------
    --- ServerHit
    ---------------------------------------------
    {

        Class = "HQ",
        Target = { "ServerHit" },
        Type = eInjection_Replace,

        ------------------------
        Function = function(self, aHitInfo)

            local hShooter = aHitInfo.shooter
            local hShooterID = aHitInfo.shooterId
            local bTesting = (hShooter and hShooter.IsPlayer and hShooter:IsTesting())
            Debug(bTesting)

            local aCfg = ConfigGet("General.GameRules.HitConfig.HQHits", {}, eConfigGet_Array)

            if (aCfg.CustomHQSettings) then
                local teamId = g_gameRules.game:GetTeam(hShooterID)
                if (teamId and (teamId == 0 or teamId ~= self:GetTeamId()) and (aHitInfo.explosion or bTesting) and aHitInfo.type and (aHitInfo.type == "tac" or bTesting)) then --if tac hit

                    local iHQTeam = ((self:GetTeamId() == 2) and "US" or "NK")

                    if (aCfg.HQUndestroyable) then
                        SendMsg(MSG_ERROR, ALL, "@l_ui_hqsNotDestroyable")
                        SendMsg(CHAT_SERVER, hShooter, "@l_ui_hqsNotDestroyable_chat")
                        aHitInfo.damage = 0
                        return
                    end

                    local iRemaining = (MAP_START_TIME + aCfg.AttackDelay) - _time
                    if (aCfg.AttackDelay > 0 and iRemaining > _time) then
                        local sRemaining = math.calctime(iRemaining, nil, 3)

                        SendMsg(MSG_ERROR, ALL, "@l_ui_hqsCurrentlyNotDestroyable")
                        SendMsg(CHAT_SERVER, hShooter, hShooter:Localize("@l_ui_hqsCurrentlyNotDestroyable_chat", {sRemaining}))
                        aHitInfo.damage = 0
                        return
                    end


                    local iNewHP, iNeededHits
                    local sShooter = (hShooter:GetName() or "N/A")
                    local sHitMsg
                    local aRewards = aCfg.RewardOnHit
                    local iRewardMult = 1.0
                    local iPP = 500
                    local iCP = 100

                    if (aCfg.LocalizedDamage) then

                        Debug(checkFunc(self.GetRadius,-696969,self))

                        local iRadius = 65
                        local AABB = { self:GetLocalBBox() }
                        if (table.count(AABB) >= 1) then
                            iRadius = vector.length(vector.bbox_size(AABB))
                        end

                        local vHQPos = vector.modifyz(self:GetPos(), 5.3) -- centerofmasspos() there is none since its a static object
                        local iDamage = aHitInfo.damage
                        local iHitDistance = vector.distance(aHitInfo.pos, vHQPos) - 0.25
                        local iHitAccuracy = math.max(0, math.min(100, (1 - (iHitDistance / (iRadius))) * 100))
                        iRewardMult = (iHitAccuracy / 100)

                        sHitMsg = table.it({
                            [0] = "@l_ui_horrible",
                            [50] = "@l_ui_bad",
                            [60] = "@l_ui_decent",
                            [70] = "@l_ui_good",
                            [80] = "@l_ui_verygood",
                            [90] = "@l_ui_perfect",
                            [999] = "@l_ui_godlike",
                        }, function(x, i, v) if (iHitAccuracy >= i and (x == nil or x[1] < i)) then return { i, v } end return x end)[2]

                        iNewHP = (iDamage * (iHitAccuracy / 100))
                    else
                        aHitInfo.damage = math.ceil(self.Properties.nHitPoints / aCfg.TacHits)
                        iNewHP = (self:GetHealth() - aHitInfo.damage)
                        iNeededHits = (iNewHP / aHitInfo.damage)

                        self.RemainingHits = iNeededHits
                    end


                    local sShooterName = hShooter:GetName()
                    local sRewardString = ""

                    if (aRewards) then
                        iPP = aCfg.RewardOnHit[1] or aCfg.RewardOnHit.PP or 0
                        iCP = aCfg.RewardOnHit[2] or aCfg.RewardOnHit.CP or 0

                        iPP = (iPP or 0) * (hShooter:IsPremium() and 2 or 1) * iRewardMult
                        iCP = (iCP or 0) * (hShooter:IsPremium() and 2 or 1) * iRewardMult

                        if ((iPP > 0 or iCP > 0)) then
                            hShooter:AwardPrestige(iPP)
                            hShooter:AwardCP(iCP)
                        end

                        sRewardString = string.format(" (+%d PP, +%d CP)", iPP, iCP)
                    end

                    local sTeamPlayers = GetPlayers({ TeamID = g_pGame:GetTeam(aHitInfo.shooter.id) })
                    local oTeamPlayers = GetPlayers({ NotTeamID = g_pGame:GetTeam(aHitInfo.shooter.id) })

                    if (aCfg.InfoMessage) then
                        if (iNewHP > 0) then

                            SendMsg(MSG_ERROR, sTeamPlayers, "@l_ui_enemyHQHIt", sShooterName, sRewardString)--"** ENEMY HQ HIT BY :: %s %s**", shooterName, (reward and "- GOT " .. pp .. " PRESTIGE "or""));
                            SendMsg(MSG_ERROR, oTeamPlayers, "@l_ui_ourHQHIt", sShooterName, iRemaining)--"** ENEMY HQ HIT BY :: %s %s**", shooterName, (reward and "- GOT " .. pp .. " PRESTIGE "or""));

                            -- TODO: CLientMod()
                            --SendMsg(BLE_INFO,  sTeamPlayers, "%s: Hit the Enemy HQ - %d Hits Remaining", shooterName, neededhits);
                            --SendMsg(BLE_ERROR, oTeamPlayers, "%s: Hit our HQ - %d Hits Remaining", shooterName, neededhits);

                            --
                            SendMsg(CHAT_SERVER_LOCALE, sTeamPlayers, "@l_ui_enemyHQHit_chat", sShooterName, iNeededHits, sRewardString)
                            SendMsg(CHAT_SERVER_LOCALE, oTeamPlayers, "@l_ui_ourHQHit_chat", sShooterName, iNeededHits)

                            Logger:LogEventTo(sTeamPlayers, eLogEvent_HQ, "@l_ui_enemyHQHit_console", sShooterName, iNeededHits, sRewardString)
                            Logger:LogEventTo(oTeamPlayers, eLogEvent_HQ, "@l_ui_ourHQHit_console", sShooterName, iNeededHits)

                        else--if (iNeededHits <= 0 and iNewHP <= 0) then

                            SendMsg(MSG_ERROR, sTeamPlayers, "@l_ui_enemyHQDestroyed", sShooterName)
                            SendMsg(MSG_ERROR, oTeamPlayers, "@l_ui_ourHQDestroyed", sShooterName)

                            SendMsg(CHAT_SERVER_LOCALE, sTeamPlayers, "@l_ui_enemyHQDestroyed_chat", sShooterName)
                            SendMsg(CHAT_SERVER_LOCALE, oTeamPlayers, "@l_ui_ourHQDestroyed_chat", sShooterName)

                            Logger:LogEventTo(sTeamPlayers, eLogEvent_HQ, "@l_ui_enemyHQDestroyed_console", sShooterName)
                            Logger:LogEventTo(oTeamPlayers, eLogEvent_HQ, "@l_ui_ourHQDestroyed_console", sShooterName)
                        end
                    end
                end
            end

        end
    },

}

------------
ServerInjector.InjectAll(ServerHQ)