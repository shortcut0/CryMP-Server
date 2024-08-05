------------
ServerGameRules = {

    -----------------
    This = "g_gameRules",

    -----------------
    Init = function(self)

        self.IS_PS = (g_sGameRules == "PowerStruggle")
        self.IS_IA = (g_sGameRules == "InstantAction")

        Logger.CreateAbstract(self, { LogClass = "GameRules" })

        if (ConfigGet("General.GameRules.SkipPreGame", false)) then
            if (self:GetState() ~= "InGame") then
                self:Log("Skipping PreGame.. ")
                self:GotoState("InGame")
            end
        end

        g_pGame:InitScriptTables()
    end,

    ---------------------------------------------
    --- .Server.OnClientConnect
    ---------------------------------------------
    {
        Class = "g_gameRules",
        Target = { "Server.OnClientConnect" },
        Type = eInjection_Replace,

        ------------------------
        Function = function(self, iChannel, bReset, sName)

            local hClient = self:SpawnPlayer(iChannel, sName)
            if (not hClient) then
                ServerLogError("Failed to Spawn Client %s", checkString(sName))
                return false
            end

            if (not ServerPCH:OnClientConnect(hClient, sName)) then
                return false
            end

            local bOnHold = CryAction.IsChannelOnHold(iChannel)
            if (not bReset) then
                g_pGame:ChangeSpectatorMode(hClient.id, 2, NULL_ENTITY)
            else

                if (not bOnHold) then
                    self:ResetScore(hClient.id)
                end

                local iSpecMode = self.channelSpectatorMode[iChannel] or 0
                local iTeam = self.game:GetChannelTeam(iChannel) or 0

                if (iSpecMode == 0 or iTeam ~= 0) then

                    self.game:SetTeam(iTeam, hClient.id)
                    self.Server.RequestSpawnGroup(self, hClient.id, self.game:GetTeamDefaultSpawnGroup(iTeam) or NULL_ENTITY, true)
                    self:RevivePlayer(hClient.actor:GetChannel(), hClient)
                else
                    self.Server.OnChangeSpectatorMode(self, hClient.id, iSpecMode, nil, true)
                end
            end

            if (self.IS_PS) then
                if (not bOnHold) then
                    self:ResetScore(hClient.id)
                    self:ResetPP(hClient.id)
                    self:ResetCP(hClient.id)
                end
                self:ResetRevive(hClient.id)
            end


            -- FIXME: Factory.lua (Injection)
            local hFactory, aZoneSynch
            for i, v in pairs(System.GetEntities()) do
                aZoneSynch = hEntity.BuyZoneSynch
                if (aZoneSynch) then
                    hFactory = GetEntity(aZoneSynch.ID)
                    if (hFactory) then
                        hFactory.allClients:ClSetBuyFlags(aZoneSynch.ID, aZoneSynch.Flags)
                    end
                end
            end
        end
    },

    ---------------------------------------------
    --- .Server.OnClientConnect
    ---------------------------------------------
    {
        Class = "g_gameRules",
        Target = { "Server.OnClientDisconnect" },
        Type = eInjection_Replace,

        ------------------------
        Function = function(self, iChannel, sReason)

            local hClient = g_pGame:GetPlayerByChannelId(iChannel)
            if (not hClient) then
                return
            end

            self.channelSpectatorMode[iChannel] = nil
            self.works[hClient.id] = nil

            for _, hPlayer in pairs(GetPlayers()) do
                self.onClient:ClClientDisconnect(hPlayer:GetChannel(), hClient:GetName())
            end

            if (self.IS_PS) then
                if (not CryAction.IsChannelOnHold(iChannel)) then
                    self:ResetScore(hClient.id)
                    self:ResetPP(hClient.id)
                    self:ResetCP(hClient.id)
                end

                self:ResetRevive(hClient.id)
                self:ResetRevive(hClient.id, true)

                self:VehicleOwnerDeath(hClient)
                self:ResetUnclaimedVehicle(hClient.id, true)

                self.inBuyZone[hClient.id] = nil
                self.inServiceZone[hClient.id] = nil
            end
        end
    },

    ---------------------------------------------
    --- .Server.OnClientEnteredGame
    ---------------------------------------------
    {
        Class = "g_gameRules",
        Target = { "Server.OnClientEnteredGame" },
        Type = eInjection_Replace,

        ------------------------
        Function = function(self, iChannel, hClient, bReset)

            error("bad bad bad")

            local bOnHold = CryAction.IsChannelOnHold(iChannel)
            if ((not bOnHold) and (not bReset)) then
                g_pGame:ChangeSpectatorMode(hClient.id, 2, NULL_ENTITY)

            elseif (not bReset) then
                if (hClient.actor:GetHealth()>0) then
                    hClient.actor:SetPhysicalizationProfile("alive")
                else
                    hClient.actor:SetPhysicalizationProfile("ragdoll")
                end
            end

            if (not bReset) then
                self.otherClients:ClClientEnteredGame(iChannel, hClient:GetName());
            end

            self:SetupPlayer(hClient)
            if ((not g_localActorId) or (hClient.id ~= g_localActorId)) then
                self.onClient:ClSetupPlayer(hClient.actor:GetChannel(), hClient.id)
            end

            if (self.IS_PS) then
                if (hClient) then
                    if (bReset) then
                        self:SetPlayerPP(hClient.id, self.ppList.START)
                    end

                    self.inBuyZone = self.inBuyZone or {}
                    if (self.inBuyZone[hClient.id]) then
                        for zoneId, yes in pairs(self.inBuyZone[hClient.id]) do
                            if (yes) then
                                self.onClient:ClEnterBuyZone(hClient.actor:GetChannel(), zoneId, true)
                            end
                        end
                    end
                end
            end

            ServerPCH:OnEnteredGame(hClient)
        end
    },

    ---------------------------------------------
    --- SpawnPlayer
    ---------------------------------------------
    {

        Class = "g_gameRules",
        Target = { "SpawnPlayer" },
        Type = eInjection_Replace,

        ------------------------
        Function = function(self, iChannel, sName)

            -- What is this?
            self.dudeCount = self.dudeCount or 0

            local vPos, vAng
            local hInterestingSpot = GetEntity(self.game:GetInterestingSpectatorLocation())
            if (hInterestingSpot) then
                vPos = hInterestingSpot:GetWorldPos()
                vAng = hInterestingSpot:GetWorldAngles()
            end

            local sSpawnClass = ConfigGet("General.PlayerSpawnClass", ENTITY_CLASS_PLAYER, eConfigGet_String)
            sName = ServerNames:ValidateName(sName, { Country = ServerChannels:GetCountryCode(iChannel), Profile = iChannel })

            ServerLog("Spawning new Client with Name %s", sName)

            local hClient = g_pGame:SpawnPlayer(iChannel, (sName or "Nomad"), sSpawnClass, vPos, vAng)
            if (hClient) then
                PlayerHandler:InitClient(hClient, iChannel)
            end

            return hClient
        end
    },

    ---------------------------------------------
    --- GetKills
    ---------------------------------------------
    {

        Class = "g_gameRules",
        Target = { "GetKills" },
        Type = eInjection_Replace,

        ------------------------
        Function = function(self, iClientID)
            return (g_pGame:GetSynchedEntityValue(iClientID, self.SCORE_KILLS_KEY) or 1)
        end
    },

    ---------------------------------------------
    --- GetDeaths
    ---------------------------------------------
    {

        Class = "g_gameRules",
        Target = { "GetDeaths" },
        Type = eInjection_Replace,

        ------------------------
        Function = function(self, iClientID)
            return (g_pGame:GetSynchedEntityValue(iClientID, self.SCORE_DEATHS_KEY) or 1)
        end
    },

    ---------------------------------------------
    --- SetDeaths
    ---------------------------------------------
    {

        Class = "g_gameRules",
        Target = { "SetDeaths" },
        Type = eInjection_Replace,

        ------------------------
        Function = function(self, iClientID, iDeaths)
            return (g_pGame:SetSynchedEntityValue(iClientID, self.SCORE_DEATHS_KEY, iDeaths))
        end
    },

    ---------------------------------------------
    --- SetDeaths
    ---------------------------------------------
    {

        Class = "g_gameRules",
        Target = { "SetKills" },
        Type = eInjection_Replace,

        ------------------------
        Function = function(self, iClientID, iKills)
            return (g_pGame:SetSynchedEntityValue(iClientID, self.SCORE_KILLS_KEY, iKills))
        end
    },

    ---------------------------------------------
    --- GetDeaths
    ---------------------------------------------
    {

        Class = "g_gameRules",
        Target = { "GetPlayerRank" },
        Type = eInjection_Replace,

        ------------------------
        Function = function(self, iClientID)
            if (self.IS_IA) then
                return 1
            end
            return (g_pGame:GetSynchedEntityValue(iClientID, self.RANK_KEY) or 1)
        end
    },

    ---------------------------------------------
    --- GetPlayerPrestige
    ---------------------------------------------
    {

        Class = "g_gameRules",
        Target = { "GetPlayerPrestige" },
        Type = eInjection_Replace,

        ------------------------
        Function = function(self, iClientID)
            if (self.IS_IA) then
                return 0
            end
            return (g_pGame:GetSynchedEntityValue(iClientID, self.PP_AMOUNT_KEY) or 1)
        end
    },

    ---------------------------------------------
    --- SetPlayerPrestige
    ---------------------------------------------
    {

        Class = "g_gameRules",
        Target = { "SetPlayerPrestige" },
        Type = eInjection_Replace,

        ------------------------
        Function = function(self, iClientID, iPP)
            if (self.IS_IA) then
                return 0
            end
            return (g_pGame:SetSynchedEntityValue(iClientID, self.PP_AMOUNT_KEY, iPP))
        end
    },

    ---------------------------------------------
    --- RestartGame
    ---------------------------------------------
    {

        Class = "g_gameRules",
        Target = { "RestartGame" },
        Type = eInjection_Replace,

        ------------------------
        Function = function(self, bForceInGame)

            --Server:OnReload()
            PlayerHandler:SavePlayerData()
            ServerLog("Restarting Game ..")

            self:GotoState("Reset")
            self.game:ResetEntities()
            self.forceInGame = true

            ServerLog("Game Restarted")
        end
    },

    ---------------------------------------------
    --- Reset
    ---------------------------------------------
    {

        Class = "g_gameRules",
        Target = { "Reset" },
        Type = eInjection_Replace,

        ------------------------
        Function = function(self, forcePregame)

            --Server:OnReload()

            self:ResetTime()
            self:GotoState("InGame")
            self.forceInGame = nil
            self.works = {}

            -- Refresh
            ServerChat:DeleteChatEntities()
            ServerLog("Game Reset")
        end
    },
}

------------
ServerInjector.InjectAll(ServerGameRules)