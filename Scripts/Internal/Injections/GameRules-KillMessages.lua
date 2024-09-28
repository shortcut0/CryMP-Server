ServerInjector.InjectAll({

    -----------------
    This = "g_gameRules",

    ---------------------------------------------
    --- SvInitClientStreaks
    ---------------------------------------------
    {
        Class = "g_gameRules",
        Target = { "SvInitClientStreaks" },
        Type = eInjection_Replace,

        ---------------------
        Function = function(self, hClient)

            hClient.Streaks = {
                Kills   = 0,
                Deaths  = 0,
                Repeats = {},

                -- Kill streak
                SetKills = function(this, kills) this.Kills = kills return kills end,
                AddKill  = function(this, kills) kills = (kills or 1) return this:SetKills(this.Kills + kills) end,

                -- Death streak
                SetDeaths = function(this, deaths) this.Deaths = deaths return deaths end,
                AddDeath  = function(this, deaths) deaths = (deaths or 1) return this:SetDeaths(this.Deaths + deaths) end,

                -- Repeated streaks
                SetRS   = function(this, id, rs) table.checkM(this.Repeats, id, 0) rs = (rs or 1) this.Repeats[id] = rs return rs  end,
                AddRS   = function(this, id, rs) table.checkM(this.Repeats, id, 0) rs = (rs or 1) return this:SetRS(id, this.Repeats[id] + rs)  end,
                GetRS   = function(this, id) table.checkM(this.Repeats, id, 0) return this.Repeats[id] end,
                ResetRS = function(this, id, def) def = (def or 0) if (id) then this.Repeats[id] = 0 else for i, v in pairs(this.Repeats) do this.Repeats[i] = def end end end,
            }

            hClient.SpawnTimer = timernew()
        end
    },

    ---------------------------------------------
    --- SvSendStreakMessages
    ---------------------------------------------
    {
        Class = "g_gameRules",
        Target = { "SvSendStreakMessages" },
        Type = eInjection_Replace,

        ---------------------
        Function = function(self, hTarget, hShooter, aKillInfo)

            local bMsg = false

            --Debug(self.StreakMessages)
            local aDeathMessages = self.StreakMessages.Deaths
            local aKillMessages  = self.StreakMessages.Kills
            local aRSMessages    = self.StreakMessages.Repeats

            local iKills = (hShooter and self:GetKills(hShooter.id) or 0)
            local aFormat = {
                ["shooter"] = GetEntityName(hShooter),
                ["target"]  = GetEntityName(hTarget),
                ["kills"]   = iKills,
            }

            if (hTarget and hTarget.    IsPlayer) then

                local iDeathStreak  = hTarget.Streaks:AddDeath()
                local sDeathMessage = aDeathMessages[iDeathStreak]

                if (sDeathMessage) then
                    aFormat["kills"] = iDeathStreak
                    bMsg = true
                    ClientMod:SendBLE(ALL_PLAYERS, Logger.Format(sDeathMessage, aFormat))
                end

                hTarget.Streaks:SetKills(0)
                hTarget.Streaks:ResetRS()
            end


            if (hShooter and hShooter.IsPlayer and hTarget ~= hShooter) then
                hShooter.Streaks:SetDeaths(0)

                local iKillStreak  = hShooter.Streaks:AddKill()
                local sKillMessage = aKillMessages[iKillStreak]
                local iRSStreak    = hShooter.Streaks:AddRS(hTarget.id)
                local sRSMessage   = aRSMessages[iRSStreak]

                if (sRSMessage) then
                    aFormat["kills"] = iRSStreak
                    bMsg = true
                    ClientMod:SendBLE(ALL_PLAYERS, Logger.Format(sRSMessage, aFormat))

                elseif (sKillMessage) then
                    aFormat["kills"] = iKillStreak
                    bMsg = true
                    ClientMod:SendBLE(ALL_PLAYERS, Logger.Format(sKillMessage, aFormat))
                end
            end

            return bMsg -- no message was sent
        end
    },

    ---------------------------------------------
    --- SvSendKillMessage
    ---------------------------------------------
    {
        Class = "g_gameRules",
        Target = { "SvSendKillMessage" },
        Type = eInjection_Replace,

        ---------------------
        Function = function(self, aKillInfo)

            local hTarget  = aKillInfo.target
            local hShooter = aKillInfo.shooter
            local hWeapon  = aKillInfo.weapon
            local sWeapon  = (hWeapon or { class = "" }).class
            local sType    = (aKillInfo.type or "")
            local iType    = (aKillInfo.kill_type or -1)
            local iDamage  = aKillInfo.damage

            if (self:SvSendStreakMessages(hTarget, hShooter, aKillInfo)) then
                return Debug("msg")
            end

            if (hTarget and hShooter) then
                local bFists 	    = (sWeapon == "Fists")
                local bFrag 	    = (sType == "frag")
                local bSuicide 		= (iType == eKillType_Suicide)
                local bFell 	    = (hTarget == hShooter and iDamage <= 1000 and hShooter.IsPlayer and not aKillInfo.material_type and not hWeapon and sType == "")
                local bExploded     = (aKillInfo.explosion == true)
                local bC4           = (bExploded and sWeapon == "c4explosive")
                local bClaymore     = (bExploded and sWeapon == "claymoreexplosive")
                local bPistol 		= (sWeapon == "SOCOM")
                local bSniped 		= (sWeapon == "DSG1")
                local bGauss 		= (sWeapon == "GaussRifle")
                local bHurricane 	= (sWeapon == "Hurricane")
                local bShotgunned   = (sWeapon == "Shotgun")
                local bDrivenOver   = (hWeapon and (hWeapon.VehicleCMParent or hWeapon.vehicle))
                local bKilledSelf   = (bSuicide and iDamage == 8190)
                local bSpawnKill    = (not bSuicide and hTarget.IsPlayer and not hTarget.SpawnTimer.expired(10))

                --Debug(hit.damage)
                Debug(sWeapon)
                local aMessages = { "%s Killed %s", }
                if (bFell) then
                    aMessages = { "%s Thought they can Fly", "%s Believed they had wings", "%s Fell to Death", "%s Slipped Off a Cliff", "%s Took the Jump" }

                elseif (bKilledSelf) then
                    aMessages = { "%s Took the Easy way Out" }

                elseif (bSuicide) then
                    if (bExploded) then
                        aMessages = { "%s Blew Themselves Up", "%s Took the Bomb", "%s Ate a Frag" }

                    elseif (bDrivenOver) then
                        aMessages = { "%s Drove Over Themselves", "%s rammed themself" }

                    else
                        aMessages = { "%s Commited Suicide" }
                    end

                elseif (bDrivenOver) then
                    aMessages = { "%s Drove Over %s", "%s Flattened %s", "%s Ran Over %s", "%s Ran %s Down" }

                elseif (bFists) then
                    aMessages = { "%s Fisted %s", "%s knocked %s Out", "%s Knocked %s tf out", "%s Slapped %s" }

                elseif (bSpawnKill) then
                    aMessages = {
                        "${target} was born and immediately regretted it",
                        "${target} barely had time to breathe",
                        "${shooter} made sure ${target}'s return was short lived"
                    }

                elseif (bPistol) then
                    aMessages = { "%s Pistoled %s" }

                elseif (bSniped) then
                    aMessages = { "%s Sniped %s", "%s Picked Off %s", "%s Scoped %s" }

                elseif (bGauss) then
                    aMessages = { "%s GAUSSED %s", "%s NOOB GUNNED %s", "%s Killed %s WITH A GAUSS" }

                elseif (bFrag) then
                    aMessages = { "%s Fragged %s", "%s Fed %s the Frag", "%s Gave %s the Frag" }

                elseif (bC4) then
                        aMessages = { "%s Fed %s Chocolate", "%s Handed %s An Explosive Cake", "%s Got Fed C4" }

                elseif (bClaymore) then
                        aMessages = { "${target} Didnt watch their Step", "${target} found a surprise underfoot", "${target} Squashed a Claymore" }

                elseif (bExploded) then
                    aMessages = { "%s Blew Up %s", "%s Bombed %s", "%s Detonated %s", "%s Erased %s", "%s Destroyed %s", "%s Obliterated %s", "%s Nuked %s" }

                elseif (bHurricane) then
                    aMessages = { "%s Ripped %s Apart", "%s Torn %s Apart", "%s Wiped %s Out" }

                elseif (bShotgunned) then
                    aMessages = { "%s Pulverised %s", "%s Shotgunned %s" }

                else
                    aMessages = { "%s Eliminated %s" }
                end

                local sMessage = Logger.Format(string.format(table.random(aMessages), hShooter:GetName(), hTarget:GetName()), {
                    ["target"]  = hTarget:GetName(),
                    ["shooter"] = hShooter:GetName(),
                })
                ClientMod:OnAll(string.format("HUD.BattleLogEvent(eBLE_Information,\"%s\")", sMessage))
                --Debug("km",sMessage,"all",aMessages)
            end
        end
    }

})