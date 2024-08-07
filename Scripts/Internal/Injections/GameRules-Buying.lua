------------
local ServerGameRulesBuying = {

    -----------------
    This = "g_gameRules",

    ---------------------------------------------
    --- OnPurchaseCancelled
    ---------------------------------------------
    {

        Class = "g_gameRules",
        Target = { "OnPurchaseCancelled" },
        Type = eInjection_Replace,

        ------------------------
        Function = function(self, idPlayer, iTeam, sItem)

            local hPlayer = GetEntity(idPlayer)
            if (not hPlayer) then
                return
            end

            local iPrice, iEnergy = self:GetPrice(sItem)
            if (iPrice > 0) then

                -- FIXME: ClientMod!
                -- hPlayer:ClientEvent(eCallClMod_BattleLog, string.format("%s (+%d)", LocalizeForClient(hPlayer, "@l_ui_vehiclerefund")))
                self:AwardPPCount(idPlayer, iPrice, nil, hPlayer:HasClientMod())
            end

            if (iEnergy and iEnergy > 0) then
                self:SetTeamPower(iTeam, self:GetTeamPower(iTeam) + iEnergy)
            end
        end
    },

    ---------------------------------------------
    --- CheckSpawnPP
    ---------------------------------------------
    {

        Class = "g_gameRules",
        Target = { "CheckSpawnPP" },
        Type = eInjection_Replace,

        ------------------------
        Function = function(self, hPlayer, bIsVehicle, hSpawn)

            local bSpawnAward = ConfigGet("General.GameRules.Prestige.AwardSpawnPrestige", true, eConfigGet_Boolean)
            if (not bSpawnAward) then
                return
            end

            local iBunkerAward  = ConfigGet("General.GameRules.Prestige.BunkerSpawnAward", 100, eConfigGet_Number)
            local iVehicleAward = ConfigGet("General.GameRules.Prestige.VehicleSpawnAward", 100, eConfigGet_Number)

            if (not bIsVehicle) then
                for _, hUser in pairs(hSpawn.CapturedBy or {}) do
                    if (_ ~= hPlayer.id and hPlayer:GetTeam() == hUser:GetTeam()) then

                        -- FIXME: ClientMod
                        self:AwardPPCount(_, iBunkerAward, nil, hUser:HasClientMod())
                        Debug("Awarding for spawning in bunker")
                    end
                end
            else
                local hOwner = GetEntity(hSpawn.vehicle:GetOwnerId()) or GetEntity(hSpawn.OwnerID)
                if (hOwner and hOwner.IsPlayer and hOwner.id ~= hPlayer.id) then

                    -- FIXME: ClientMod
                    self:AwardPPCount(hOwner.id, iBunkerAward, nil, hUser:HasClientMod())
                    Debug("Awarding for spawning in vehicle")
                end
            end
        end
    },

    ---------------------------------------------
    --- Reset
    ---------------------------------------------
    {

        Class = "g_gameRules",
        Target = { "AwardPPCount" },
        Type = eInjection_Replace,

        ------------------------
        Function = function(self, idPlayer, iCount, sWhy, bSilent)

            local hPlayer = System.GetEntity(idPlayer)
            if (not hPlayer) then
                return
            end

            if (iCount > 0) then
                local iIncomeScale = System.GetCVar("g_pp_scale_income")
                if (iIncomeScale) then
                    iCount = math.floor(iCount * math.max(0, iIncomeScale))
                end
            end

            local iTotal = (self:GetPlayerPP(idPlayer) + iCount)
            self:SetPlayerPP(idPlayer, math.max(0, iTotal))

            if (not bSilent) then
                self.onClient:ClPP(hPlayer.actor:GetChannel(), iCount)
            end

            CryAction.SendGameplayEvent(idPlayer, eGE_Currency, nil, iTotal)
            CryAction.SendGameplayEvent(idPlayer, eGE_Currency, sWhy, iCount)
        end
    },

    ---------------------------------------------
    --- Reset
    ---------------------------------------------
    {

        Class = "g_gameRules",
        Target = { "Server.OnCapture" },
        Type = eInjection_Replace,

        ------------------------
        Function = function(self, hSpawn, iTeam)

            hSpawn.CapturedBy = {}

            local aInside = hSpawn.inside
            if (aInside) then

                local hPlayer
                for _, idPlayer in ipairs(aInside) do
                    if (g_gameRules.game:GetTeam(idPlayer) == iTeam) then

                        hPlayer = System.GetEntity(idPlayer)
                        if (hPlayer and hPlayer:IsAlive()) then
                            hSpawn.CapturedBy[idPlayer] = hPlayer
                            Debug("Captured by ",hPlayer:GetName())
                        end
                    end
                end
            end
        end
    },

    ---------------------------------------------
    --- OnUncapture
    ---------------------------------------------
    {

        Class = "g_gameRules",
        Target = { "Server.OnUncapture" },
        Type = eInjection_Replace,

        ------------------------
        Function = function(self, hSpawn)
            hSpawn.CapturedBy = {}
        end
    },

    ---------------------------------------------
    --- ResetServerItems
    ---------------------------------------------
    {

        Class = "g_gameRules",
        Target = { "ResetServerItems" },
        Type = eInjection_Replace,

        ------------------------
        Function = function(self, hPlayer)

        end,
    },
}

------------
ServerInjector.InjectAll(ServerGameRulesBuying)