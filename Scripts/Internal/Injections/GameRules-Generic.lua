------------
local ServerGameRules = {

    -----------------
    This = "g_gameRules",

    -----------------
    PostInit = function(self)

        MAXIMUM_PRESTIGE = (10000000 - 1)

        self.ServerData = (self.ServerData or {})

        self.IS_PS = (g_sGameRules == "PowerStruggle")
        self.IS_IA = (g_sGameRules == "InstantAction")

        self.KillAssistTimeout = ConfigGet("General.GameRules.HitConfig.KillAssistanceTimeout", 12.5, eConfigGet_Number)
        self.TeamKills = {}

        Logger.CreateAbstract(self, { LogClass = "GameRules" })

        if (ConfigGet("General.GameRules.SkipPreGame", false)) then
            if (self:GetState() ~= "InGame") then
                self:Log("Skipping PreGame.. ")
                self:GotoState("InGame")
            end
        end

        local iTeamKillDamage = ConfigGet("General.GameRules.HitConfig.TeamKill.DamageMultiplier", 0, eConfigGet_Number)
        SetCVar("g_friendlyFireRatio", g_ts(iTeamKillDamage))

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

            -- Handled inside player tick func to allow client to validate herself first
            --if (not ServerPCH:OnClientConnect(hClient, sName)) then
            --    return false
            --end

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


            ---------------------------------
            -- FIXME: Factory.lua (Injection)
            local hFactory, aZoneSynch
            for i, hEntity in pairs(System.GetEntities()) do
                hFactory = hEntity.BuyZoneSynch
                if (hFactory) then
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

    ---------------------------------------------
    --- UpdatePings
    ---------------------------------------------
    {

        Class = "g_gameRules",
        Target = { "UpdatePings" },
        Type = eInjection_Replace,

        ------------------------
        Function = function(self)
            -- Moved to HandlePings() which is only called ever second instead of every frame.
        end
    },

    ---------------------------------------------
    --- OnUpdate
    ---------------------------------------------
    {

        Class = "g_gameRules",
        Target = { "Server.OnUpdate" },
        Type = eInjection_Replace,

        ------------------------
        Function = function(self, iFrameTime)
            if (self.IS_PS) then
                self:UpdateUnclaimedVehicles(iFrameTime)
                if (TeamInstantAction) then
                    TeamInstantAction.Server.OnUpdate(self, iFrameTime)
                end
            end
        end
    },

    ---------------------------------------------
    --- OnTickTimer
    ---------------------------------------------
    {

        Class = "g_gameRules",
        Target = { "OnTickTimer" },
        Type = eInjection_Replace,

        ------------------------
        Function = function(self, iFrameTime)
            self:HandlePings()
        end
    },

    ---------------------------------------------
    --- HandlePings
    ---------------------------------------------
    {

        Class = "g_gameRules",
        Target = { "HandlePings" },
        Type = eInjection_Replace,

        ------------------------
        Function = function(self)

            local iPing           = 0
            local iPingTotal      = 0
            local iPingAverage    = 0
            local iPingFixed      = ConfigGet("General.PingControl.FixedPing",     -1, eConfigGet_Number)
            local iPingMultiplier = ConfigGet("General.PingControl.PingMultiplier", 1, eConfigGet_Number)

            local aClients = g_pGame:GetPlayers()
            if (table.count(aClients) > 0) then

                local iChannel
                for _, hClient in pairs(aClients) do

                    iChannel = hClient:GetChannel()
                    iPing    = math.floor((g_pGame:GetPing(iChannel) or 0) * 1000 + 0.5)

                    if (iPingFixed ~= -1) then
                        iPing = iPingFixed
                    end

                    iPing = (iPing * iPingMultiplier)
                    iPingTotal = (iPingTotal + iPing)

                    if (hClient:GetPing(iPing, true)) then
                        hClient:SetRealPing(iPing)
                    end

                    hClient:SetPing(iPing)
                end

                iPingAverage = (iPingTotal / table.count(aClients))
            end

            self.ServerData.AveragePing = iPingAverage
            self.ServerData.TotalPing   = iPingTotal
        end
    },

    ---------------------------------------------
    --- HandlePings
    ---------------------------------------------
    {

        Class = "g_gameRules",
        Target = { "Server.OnChangeTeam" },
        Type = eInjection_Replace,

        ------------------------
        Function = function(self, hPlayerID, iTeam)

            local oldTeamId = self.game:GetTeam(hPlayerID)
            if (iTeam ~= oldTeamId) then

                local hPlayer = GetEntity(hPlayerID)
                if (hPlayer) then

                    if (hPlayer.last_team_change and (oldTeamId == 0 or iTeam ~= 0)) then
                        if (self:GetState() == "InGame") then

                            if (_time - hPlayer.last_team_change < self.TEAM_CHANGE_MIN_TIME) then
                                if ((not hPlayer.last_team_change_warning) or (_time - hPlayer.last_team_change_warning >= 4)) then
                                    hPlayer.last_team_change_warning = _time
                                    self.game:SendTextMessage(TextMessageError, "@mp_TeamChangeLimit", TextMessageToClient, hPlayerID, self.TEAM_CHANGE_MIN_TIME - math.floor(_time - hPlayer.last_team_change + 0.5))
                                end
                                return
                            end
                        end
                    end

                    if (self:IsTeamLocked(iTeam, hPlayerID)) then
                        if ((not hPlayer.last_team_locked_warning) or (iTeam - hPlayer.last_team_locked_warning >= 4)) then
                            hPlayer.last_team_locked_warning = _time

                            Log("team change request by %s denied: team %d has too many players", EntityName(hPlayerID), iTeam)
                            self.game:SendTextMessage(TextMessageError, "@mp_TeamLockedTooMany", TextMessageToClient, hPlayerID)
                        end
                        return
                    end

                    if (hPlayer.actor:GetHealth() > 0 and hPlayer.actor:GetSpectatorMode()==0) then
                        self:KillPlayer(hPlayer)
                    end

                    if (iTeam ~= 0) then
                        self:QueueRevive(hPlayerID);
                        self.game:SetTeam(iTeam, hPlayerID);
                        self.Server.RequestSpawnGroup(self, hPlayer.id, self.game:GetTeamDefaultSpawnGroup(iTeam) or NULL_ENTITY, true)

                        hPlayer.TeamChangeTimer = timernew()
                        hPlayer.last_team_change = _time
                    end
                end

                for _, hFactory in pairs(self.factories) do
                    hFactory:CancelJobForPlayer(hPlayerID)
                end
            end
        end
    },

    ---------------------------------------------
    --- HandlePings
    ---------------------------------------------
    {

        Class = "g_gameRules",
        Target = { "RevivePlayer" },
        Type = eInjection_Replace,

        ------------------------
        Function = function(self, iChannel, hPlayer, bForce, bKeepEquip)

            local iTeamForce
            if (self.IS_PS) then
                if (hPlayer:IsSpectating()) then
                    g_pGame:ChangeSpectatorMode(hPlayer.id, 0, NULL_ENTITY)
                end
                if (not bForce) then
                end
            end

            if (bForce or (hPlayer:GetTeam() == 0 and self.IS_PS)) then
                g_pGame:RevivePlayer(hPlayer.id, hPlayer.RevivePosition, (hPlayer.ReviveAngles or hPlayer:GetAngles()), hPlayer:GetTeam(), not bKeepEquip)
                if (hPlayer:IsSpectating()) then
                    hPlayer.actor:SetSpectatorMode(0, NULL_ENTITY)
                end
                if (not bKeepEquip or (hPlayer:IsInventoryEmpty())) then
                    self:EquipPlayer(hPlayer)
                end

                if (self.IS_PS) then
                    self:ResetRevive(hPlayer.id, true)
                end
                return true
            end

            local bResult 	 = false
            local iGroup 	= (hPlayer.ForcedSpawnID or hPlayer.spawnGroupId)
            local iTeam 	= hPlayer:GetTeam()

            if (hPlayer:IsDead()) then
                bKeepEquip 	= false
            end

            -- Forced Spawn Point
            hPlayer.ForcedSpawnID = nil

            ----
            local hSpawn
            if (self.USE_SPAWN_GROUPS and iGroup and iGroup ~= NULL_ENTITY) then

                hSpawn = System.GetEntity(iGroup)

                -- spawn group is a vehicle, and the vehicle has some free seats then
                if (hSpawn and hSpawn.vehicle) then
                    bResult = false

                    for i, aSeat in pairs(hSpawn.Seats) do
                        if ((not aSeat.seat:IsDriver()) and (not aSeat.seat:IsGunner()) and (not aSeat.seat:IsLocked()) and (aSeat.seat:IsFree()))  then
                            self.game:RevivePlayerInVehicle(hPlayer.id, hSpawn.id, i, iTeam, (not bKeepEquip))
                            bResult = true
                            break
                        end
                    end

                    if (not bResult) then
                        self.game:RevivePlayerInVehicle(hPlayer.id, hSpawn.id, -1, iTeam, (not bKeepEquip))
                        bResult = true
                    end
                end

            elseif (self.USE_SPAWN_GROUPS) then

                ServerLogError("Failed to spawn %s! teamId: %d  groupId: %s  groupTeamId: %d", hPlayer:GetName(), self.game:GetTeam(hPlayer.id), tostring(iGroup), self.game:GetTeam(iGroup or NULL_ENTITY))
                return false
            end


            local hSpawnId, iZOffset
            local hGroup

            if (not bResult) then

                local bIgnoreTeam = ((iGroup ~= nil) or (not self.TEAM_SPAWN_LOCATIONS))

                local bIncludeNeutral = true
                if (self.TEAM_SPAWN_LOCATIONS) then
                    bIncludeNeutral = self.NEUTRAL_SPAWN_LOCATIONS or false;
                end

                if (self.USE_SPAWN_GROUPS or (not hPlayer.death_time) or (not hPlayer.death_pos)) then
                    hSpawnId, iZOffset = self.game:GetSpawnLocation(hPlayer.id, bIgnoreTeam, bIncludeNeutral, iGroup or NULL_ENTITY)

                else
                    hSpawnId, iZOffset = self.game:GetSpawnLocation(hPlayer.id, bIgnoreTeam, bIncludeNeutral, iGroup or NULL_ENTITY, 50, hPlayer.death_pos)
                end


                -- TODO: Spawn Handler ( Plugin? :3 )
                local hNewSpawn = EventCall(eServerEvent_ResolveSpawnLocation, hPlayer)
                if (hNewSpawn ~= nil) then
                    hSpawnId = hNewSpawn.id
                end

                local vPlayerSpawn, vPlayerAng = hPlayer:GetSpawnLocation()


                local vPos, vAng
                if (vPlayerSpawn) then

                    self.game:RevivePlayer(hPlayer.id, vPlayerSpawn, (vPlayerAng or hPlayer:GetAngles()), iTeam, not bKeepEquip)
                    bResult = true

                elseif (hSpawnId) then
                    hSpawn	= System.GetEntity(hSpawnId)
                    if (hSpawn) then

                        hSpawn:Spawned(hPlayer)

                        vPos    = hSpawn:GetWorldPos(g_Vectors.temp_v1)
                        vAng	= hSpawn:GetWorldAngles(g_Vectors.temp_v2)
                        vPos.z	= vPos.z + iZOffset


                        if (hPlayer.RespawnAtDeathPosition) then
                            vPos = hPlayer.death_pos
                        end

                        g_pGame:RevivePlayer(hPlayer.id, vPos, vAng, iTeam, not bKeepEquip);
                        bResult = true
                    end
                end
            end

            -- make the game realise the areas we're in right now...
            -- otherwise we'd have to wait for an entity system update, next frame
            hPlayer:UpdateAreas()

            if (bResult) then
                if (hPlayer:IsSpectating()) then
                    hPlayer.actor:SetSpectatorMode(0, NULL_ENTITY)
                end

                if (not bKeepEquip) then
                    local additionalEquip
                    if (iGroup) then
                        hGroup = System.GetEntity(iGroup)
                        if (hGroup and hGroup.GetAdditionalEquipmentPack) then
                            additionalEquip = hGroup:GetAdditionalEquipmentPack()
                        end
                    end

                    self:EquipPlayer(hPlayer, additionalEquip)
                end
                hPlayer.death_time		= nil
                hPlayer.frostShooterId	= nil

                if (self.INVULNERABILITY_TIME and self.INVULNERABILITY_TIME > 0) then
                    self.game:SetInvulnerability(hPlayer.id, true, self.INVULNERABILITY_TIME)
                end
            end

            if (not bResult) then
                ServerLogError("Failed to spawn %s! teamId: %d  groupId: %s  groupTeamId: %d", hPlayer:GetName(), hPlayer:GetTeam(), tostring(iGroup), self.game:GetTeam(iGroup or NULL_ENTITY))
            end
            -- IA part end

            if (self.IS_PS) then
                self:ResetUnclaimedVehicle(hPlayer.id, false)
                self:ResetServerItems(hPlayer)
                hPlayer.lastVehicleId = nil
            end

            ------------
            -- Event
            EventCall(eServerEvent_OnClientRevived, hPlayer, hGroup, (hGroup and hGroup.vehicle ~= nil))

            if (hGroup) then
                self:CheckSpawnPP(hPlayer, hGroup.vehicle ~=nil, hGroup)
            end

            return bResult
        end
    },

    ---------------------------------------------
    --- OnPlayerKilled
    ---------------------------------------------
    {

        Class = "g_gameRules",
        Target = { "EquipPlayer" },
        Type = eInjection_Replace,

        ------------------------
        Function = function(self, hPlayer, aAdditionalEquip)

            hPlayer.inventory:Destroy()
            if (hPlayer:IsPunished(ePlayerPunish_NoEquipment)) then
                return
            end

            hPlayer:GiveItem("AlienCloak")
            hPlayer:GiveItem("OffHand")
            hPlayer:GiveItem("Fists")

            local bEquipped = ServerItemHandler:EquipPlayer(hPlayer)
            if (not bEquipped) then
                if (aAdditionalEquip and aAdditionalEquip ~= "") then
                    hPlayer:GiveItemPack(aAdditionalEquip)
                end
                hPlayer:GiveItem("SOCOM")
            end
        end

    },

    ---------------------------------------------
    --- OnPlayerKilled
    ---------------------------------------------
    {

        Class = "g_gameRules",
        Target = { "Server.OnPlayerKilled" },
        Type = eInjection_Replace,

        ------------------------
        Function = function(self, aHitInfo)

            local bTeamKill = false
            local hTarget   = aHitInfo.target
            local hShooter  = aHitInfo.shooter

            hTarget.death_time = _time
            hTarget.death_pos  = hTarget:GetWorldPos(hTarget.death_pos)

            if (self.IS_IA) then
                self.game:KillPlayer(hit.targetId, true, true, hit.shooterId, hit.weaponId, hit.damage, hit.materialId, hit.typeId, hit.dir or vector.make(0,0,1));
            else
                if (hShooter and hShooter.actor and hShooter.actor:IsPlayer()) then
                    if (hTarget ~= hShooter) then
                        local iTeam1 = self.game:GetTeam(hShooter.id)
                        local iTeam2 = self.game:GetTeam(hTarget.id)

                        if ((iTeam1 ~= 0) and (iTeam1 == iTeam2)) then
                            bTeamKill = true
                            if (self.OnTeamKill) then
                                self:OnTeamKill(hTarget.id, hShooter.id)
                            end
                        end
                    end
                end

                self.game:KillPlayer(aHitInfo.targetId, (not bTeamKill), true, aHitInfo.shooterId, aHitInfo.weaponId, aHitInfo.damage or 0, aHitInfo.materialId or "mat_default", aHitInfo.typeId or -1, aHitInfo.dir or vector.make(0,0,0));
            end

            self:ProcessScores(aHitInfo, bTeamKill)
            self:AwardAssistPPAndCP(aHitInfo)
            self:OnKilled(aHitInfo)
        end
    },


    ---------------------------------------------
    --- OnPlayerKilled
    ---------------------------------------------
    {

        Class = "g_gameRules",
        Target = { "OnKilled" },
        Type = eInjection_Replace,

        ------------------------
        Function = function(self, aHitInfo)

            local hWeapon    = aHitInfo.weapon
            local hTarget    = aHitInfo.target
            local hShooter   = aHitInfo.shooter

            local iKillType = eKillType_Unknown
            local bHeadshot = false

            local bSuicide = (not hShooter or hShooter == hTarget)
            local iSuicideKills   = ConfigGet("General.GameRules.HitConfig.DeductSuicideKills", 0, eConfigGet_Number)
            local iSuicideDeaths  = ConfigGet("General.GameRules.HitConfig.SuicideAddDeaths", 1, eConfigGet_Number)
            local iTeamKillReward = ConfigGet("General.GameRules.HitConfig.DeductTeamKill", 1, eConfigGet_Number)
            local bRemoveBotScore = ConfigGet("General.GameRules.HitConfig.DeductBotKills", false, eConfigGet_Boolean)

            if (hTarget.IsPlayer) then

                if (bSuicide) then
                    iKillType = eKillType_Suicide
                    hTarget:SetKills(hTarget:GetKills() + (iSuicideKills + 1))
                    hTarget:SetDeaths(hTarget:GetDeaths() + (iSuicideDeaths))

                elseif (hShooter.isPlayer) then

                    -- detect teamkill
                    if (not self.IS_IA and g_pGame:GetTeam(hShooter.id) == g_pGame:GetTeam(hTarget.id)) then
                        iKillType = eKillType_Team
                        hShooter:SetKills(hShooter:GetKills() - (1 - iTeamKillReward))

                    else
                        iKillType = eKillType_Enemy
                        if (aHitInfo.material_type and string.find(aHitInfo.material_type, "head", nil, true)) then
                            bHeadshot = true
                        end
                    end
                else
                    iKillType = eKillType_Bot
                end

            elseif (hShooter) then
                if (hShooter.isPlayer) then

                    -- target is not player -> remove points
                    iKillType = eKillType_Bot

                    if (bRemoveBotScore) then

                        hShooter:SetKills(hShooter:GetKills() - 1)
                        self:AwardPPCount(aHitInfo.shooterId, -self.ppList.KILL)
                        self:AwardCPCount(aHitInfo.shooterId, -self.cpList.KILL)
                    end
                else
                    iKillType = eKillType_Bot
                end
            else
                iKillType = eKillType_BotDeath
            end
        end
    },

    ---------------------------------------------
    --- OnShoot
    ---------------------------------------------
    {

        Class = "g_gameRules",
        Target = { "OnTeamKill" },
        Type = eInjection_Replace,

        ------------------------
        Function = function(self, hPlayerID)

            local bOk = ConfigGet("General.GameRules.HitConfig.TeamKill.Allowed", false, eConfigGet_Boolean)
            if (bOk) then
                return
            end

            local iThreshold = ConfigGet("General.GameRules.HitConfig.TeamKill.PunishThreshold", 5, eConfigGet_Number)
            local iBanTime = ConfigGet("General.GameRules.HitConfig.TeamKill.BanTime", 0, eConfigGet_Number)

            self.TeamKills[hPlayerID] = ((self.TeamKills[hPlayerID] or 0) + 1)
            if (self.TeamKills[hPlayerID] > iThreshold) then
                if (iBanTime > 0) then

                    -- FIXME: Ban
                    -- Ban()

                    -- FIXME: Kick
                    -- Kick()
                end
            end
        end

    },

    ---------------------------------------------
    --- OnShoot
    ---------------------------------------------
    {

        Class = "g_gameRules",
        Target = { "AwardAssistPPAndCP" },
        Type = eInjection_Replace,

        ------------------------
        Function = function(self, aHitInfo)


            if (not self.IS_PS) then
                return
            end

            local hTarget    = aHitInfo.target
            local hShooter   = aHitInfo.shooter

            if (not hShooter or not hTarget) then
                return
            end

            if (not ConfigGet("General.GameRules.HitConfig.KillAssistanceRewards", true, eConfigGet_Boolean)) then
                return throw_error("config bad")
            end

            local hMethod = ConfigGet("General.GameRules.HitConfig.KillAssistanceType", 1, eConfigGet_Number)
            local iThreshold = ConfigGet("General.GameRules.HitConfig.KillAssistanceThreshold", 15, eConfigGet_Number)

            local iPP = self:CalcKillPP(aHitInfo)
            local iCP = self:CalcKillCP(aHitInfo)

            if (hTarget.id ~= hShooter.id) then
                local aCollectedHits = hTarget.CollectedHits
                if (table.empty(aCollectedHits)) then
                    return throw_error("no hits")
                end

                local iTotalHits   = 0
                local iTotalDamage = 0

                for hPlayerID, aInfo in pairs(aCollectedHits) do
                    if (hPlayerID ~= hTarget.id and GetEntity(hPlayerID)) then

                        -- only add hits from players who actually assisted in the kill
                        if (not aInfo.Timer.expired()) then
                            iTotalHits   = iTotalHits   + aInfo.HitCount
                            iTotalDamage = iTotalDamage + aInfo.DamageCount
                        end
                    end
                end

                local iAssistance = 0
                for hPlayerID, aInfo in pairs(aCollectedHits) do
                    if (hPlayerID ~= hShooter.id and hPlayerID ~= hTarget.id and GetEntity(hPlayerID)) then

                        -- only add hits from players who actually assisted in the kill
                        if (not aInfo.Timer.expired()) then

                            -- Divide the rewards by the percentage of hits
                            iAssistance = (aInfo.HitCount / iTotalHits)
                            if (hMethod == 1) then

                                -- Divide the rewards by the percentage of damage dealt
                                iAssistance = (aInfo.DamageCount / iTotalDamage)
                            end

                            Debug(hPlayerID,"assistance:",iAssistance,">",(iThreshold or 0))
                            if ((iAssistance * 100) > (iThreshold or 0)) then

                                -- TODO: ClientMod()
                                -- ClientMod()

                                self:AwardPPCount(hPlayerID, math.floor(math.max(0, iPP * iAssistance)), nil, GetEntity(hPlayerID):HasClientMod())
                                self:AwardCPCount(hPlayerID, math.floor(math.max(0, iCP * iAssistance)))

                            end
                        else
                            throw_error("timer expired")
                        end
                    end
                end
            end
        end

    },

    ---------------------------------------------
    --- OnShoot
    ---------------------------------------------
    {

        Class = "g_gameRules",
        Target = { "OnShoot" },
        Type = eInjection_Replace,

        ------------------------
        Function = function(self, aShotInfo)

            local hShooter 	= aShotInfo.shooter
            local hWeapon 	= aShotInfo.weapon

            if (hShooter.IsPlayer) then
                if (hShooter:HitAccuracyExpired()) then
                    hShooter:RefreshHitAccuracy()
                end
                hShooter:UpdateHitAccuracy(eHitAccuracy_OnShot)
            end

            SendMsg(MSG_CENTER, hShooter, "Accuracy: " .. hShooter:GetHitAccuracy())
        end

    },

    ---------------------------------------------
    --- OnHit
    ---------------------------------------------
    {

        Class = "g_gameRules",
        Target = { "OnHit" },
        Type = eInjection_Replace,

        ------------------------
        Function = function(self, aHitInfo)

            local hShooter 	= aHitInfo.shooter
            local hTarget 	= aHitInfo.target
            local hWeapon 	= aHitInfo.weapon

            if (hShooter and hTarget and hShooter ~= hTarget) then
                if (self.IS_PS and hShooter.IsPlayer and hTarget.class == "Player" and hShooter:GetTeam() ~= g_pGame:GetTeam(hTarget.id)) then

                    hTarget.CollectedHits = (hTarget.CollectedHits or {})
                    hTarget.CollectedHits[hShooter.id] = (hTarget.CollectedHits[hShooter.id] or {
                        Timer       = timernew(self.KillAssistTimeout),
                        HitCount    = 0,
                        DamageCount = 0
                    })

                    if (hTarget.CollectedHits[hShooter.id].Timer.expired()) then
                        hTarget.CollectedHits[hShooter.id].HitCount     = 0
                        hTarget.CollectedHits[hShooter.id].DamageCount  = 0
                        Debug("reset all")
                    end

                    hTarget.CollectedHits[hShooter.id].Timer.refresh()
                    hTarget.CollectedHits[hShooter.id].HitCount     = (hTarget.CollectedHits[hShooter.id].DamageCount + 1)
                    hTarget.CollectedHits[hShooter.id].DamageCount  = (hTarget.CollectedHits[hShooter.id].DamageCount + aHitInfo.damage)

                end

                if (hTarget.IsPlayer) then
                    if (not aHitInfo.explosion and not aHitInfo.melee) then
                        if (not hShooter:HitAccuracyExpired()) then
                            hShooter:UpdateHitAccuracy(eHitAccuracy_OnHit)
                        end
                    end
                end
            end
        end
    },

    ---------------------------------------------
    --- OnHit
    ---------------------------------------------
    {

        Class = "g_gameRules",
        Target = { "ProcessActorDamage" },
        Type = eInjection_Replace,

        ------------------------
        Function = function(self, aHitInfo)

            ---------
            if (not ServerItemHandler:CheckHit(aHitInfo)) then
                return false
            end
            self:OnHit(aHitInfo)

            ---------
            local hTarget = aHitInfo.target
            local iHealth = hTarget.actor:GetHealth()

            ---------
            iHealth = math.floor(iHealth - aHitInfo.damage * (1 - self:GetDamageAbsorption(hTarget, aHitInfo)))
            hTarget.actor:SetHealth(iHealth)

            ---------
            local bDead = (iHealth <= 0)
            return bDead
        end
    },
}

------------
ServerInjector.InjectAll(ServerGameRules)