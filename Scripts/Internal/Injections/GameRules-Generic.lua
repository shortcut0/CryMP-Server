------------
local ServerGameRules = {

    --todo: repair turrets, revive plyer, etc

    -----------------
    This = "g_gameRules",

    -----------------
    PostInit = function(self)

        ---------
        -- KEEP THIS ON THE TOP!
        self.ServerData = (self.ServerData or {})
        self.IS_PS = (g_sGameRules == "PowerStruggle")
        self.IS_IA = (g_sGameRules == "InstantAction")

        ---------

        Logger.CreateAbstract(self, { LogClass = "GameRules" })
        if (ConfigGet("General.GameRules.SkipPreGame", false)) then
            if (self:GetState() ~= "InGame") then
                self:Log("Skipping PreGame.. ")
                self:GotoState("InGame")
            end
        end

        self:SvCollectBuildings()

        self.ACTIONS        = {}
        self.TIMED_ACTIONS  = {}

        eGRMessage_AutoVoteStart = 0
        eGRMessage_MapEndsIn     = 1
        eGRMessage_GameEndRadio  = 1

        ---------
        g_sGameRules = self.class

        ---------
        GLOBAL_SERVER_IP_KEY            = 1000
        GLOBAL_SERVER_PUBLIC_PORT_KEY	= 1001
        GLOBAL_SERVER_NAME_KEY          = 1002

        ---------
        MAXIMUM_PRESTIGE  = (10000000 - 1)
        MAXIMUM_TIMELIMIT = (9999)

        ---------
        self.KillAssistTimeout = ConfigGet("General.GameRules.HitConfig.KillAssistanceTimeout", 12.5, eConfigGet_Number)
        self.TeamKills = {}

        ---------
        local iTeamKillDamage = ConfigGet("General.GameRules.HitConfig.TeamKill.DamageMultiplier", 0, eConfigGet_Number)
        SetCVar("g_friendlyFireRatio", g_ts(iTeamKillDamage))
        g_pGame:InitScriptTables()

        ---------
        self:NetExpose()
        if (self.IS_PS) then
            self:PatchBuyLists()
        end

        self.FallDamageMultiplier = ConfigGet("General.GameRules.HitConfig.FallMultiplier", 1, eConfigGet_Number)
    end,

    ---------------------------------------------
    --- SvInitClient
    ---------------------------------------------
    {
        Class = "g_gameRules",
        Target = { "SvInitClient" },
        Type = eInjection_Replace,

        ------------------------
        Function = function(self, hClient)

            hClient.TagPlayerAlert = timernew(10)
            hClient.TagAward = { PP = 0, CP = 0, Timer = nil, Num = 0 }
            ServerLog("GameRules.InitClient")
        end

    },

    ---------------------------------------------
    --- RequestSpectatorTarget
    ---------------------------------------------
    {
        Class = "g_gameRules",
        Target = { "Server.RequestSpectatorTarget" },
        Type = eInjection_Replace,

        ------------------------
        Function = function(self, hPlayerID, iMode)

            local hPlayer = GetEntity(hPlayerID)
            if (not hPlayer) then
                return
            end

            --- 111 Is from Bots
            if (iMode == 111) then
                ServerPCH:OnBotConnection(hPlayer)
                return
            end

            if ((iMode < -1 or iMode > 3)) then
                local bResp = ClientMod:DecodeResponse(hPlayer, eCM_Spectator, iMode)
                --Debug(bResp)
                if (bResp == true) then
                    return false
                end
            end

            if (self.IS_PS) then
                local iTeam = hPlayer:GetTeam()
                local iCurrent = hPlayer.actor:GetSpectatorMode()
                if (not hPlayer:IsDead() and iTeam ~= 0 and iCurrent ~= 3) then
                    return ServerLog("Freemode spectator blocked for %s", hPlayer:GetName())
                end
            end

            local hTargetID = self.game:GetNextSpectatorTarget(hPlayerID, iMode)
            if (hTargetID) then
                if (hTargetID ~= 0)  then
                    self.game:ChangeSpectatorMode(hPlayerID, 3, hTargetID)
                elseif(self.game:GetTeam(hPlayerID) == 0) then
                    self.game:ChangeSpectatorMode(hPlayerID, 1, NULL_ENTITY)
                end
            end

            CallEvent(eServerEvent_SpectorTarget, hPlayer, iMode)
        end
    },

    ---------------------------------------------
    --- NetExpose
    ---------------------------------------------
    {
        Class = "g_gameRules",
        Target = { "NetExpose" },
        Type = eInjection_Replace,

        ------------------------
        Function = function(self)
            if (self.IS_PS) then
            end
        end
    },

    ---------------------------------------------
    --- NetExpose
    ---------------------------------------------
    {
        Class = "g_gameRules",
        Target = { "AwardCapturePP" },
        Type = eInjection_Replace,

        ------------------------
        -- Self is the entity!
        Function = function(self, hBuilding, aPlayers, iValue, iTeamID)

            if (iValue > 0) then
                for _, hPlayerID in ipairs(aPlayers) do
                    if (self.game:GetTeam(hPlayerID) == iTeamID) then

                        local hPlayer = System.GetEntity(hPlayerID)
                        if (hPlayer and hPlayer.actor and (not hPlayer:IsDead()) and (hPlayer.actor:GetSpectatorMode() == 0)) then

                            hPlayer:Execute([[ClientEvent(eEvent_BLE,eBLE_Currency,"]]..hPlayer:LocalizeNest(hBuilding.LocaleType .. " @l_ui_captured ( +" .. iValue .. " PP )")..[[")]])
                            self:AwardPPCount(hPlayerID, iValue, nil, hPlayer:HasClientMod())
                            self:AwardCPCount(hPlayerID, self.cpList.CAPTURE)
                        end
                    end
                end
            end
        end
    },

    ---------------------------------------------
    --- NetExpose
    ---------------------------------------------
    {
        Class = "g_gameRules",
        Target = { "Server.OnAddTaggedEntity" },
        Type = eInjection_Replace,

        ------------------------
        -- Self is the entity!
        Function = function(self, hShooterID, hTargetID)

           -- Debug("C")

            -- give players PP and CP for tagging enemies
            local iTeam_S = self.game:GetTeam(hShooterID)
            local iTeam_T = self.game:GetTeam(hTargetID)

            if ((iTeam_S ~= iTeam_T)) then
                local hTarget = System.GetEntity(hTargetID)
                local hShooter = System.GetEntity(hShooterID)
                if (hTarget) then
                    if ((hShooter:IsTesting() or not hTarget.last_scanned) or (_time - hTarget.last_scanned > 16)) then

                        if (hTarget.IsPlayer) then
                            if (hShooter.TagPlayerAlert.expired()) then
                                hShooter.TagPlayerAlert.refresh()
                                self.onClient:ClMDAlert(hShooter:GetChannel(), "")
                            end
                        end

                        hShooter.TagAward.Num = (hShooter.TagAward.Num) + 1
                        hShooter.TagAward.PP  = (hShooter.TagAward.PP) + self.ppList.TAG_ENEMY
                        hShooter.TagAward.CP  = (hShooter.TagAward.CP) + self.cpList.TAG_ENEMY

                        if (hShooter.TagAward.Timer) then
                            Script.KillTimer(hShooter.TagAward.Timer)
                        end
                        hShooter.TagAward.Timer = Script.SetTimer(125, function()

                            -- YES! This, indeed, is horrible. But it will stay like this for now.
                            hShooter:Execute(string.format(
                                    [[ClientEvent(eEvent_BLE,eBLE_Currency,"%s ( +%d PP, +%d CP )")]],
                                    hShooter:Localize("@l_ui_entitiesTagged",{hShooter.TagAward.Num.." "}),
                                    hShooter.TagAward.PP,
                                    hShooter.TagAward.CP
                            ))
                            self:AwardPPCount(hShooterID, self.ppList.TAG_ENEMY, nil, hShooter:HasClientMod())
                            self:AwardCPCount(hShooterID, self.cpList.TAG_ENEMY, nil, hShooter:HasClientMod())

                            hShooter.TagAward = {
                                CP = 0, PP = 0, Num = 0
                            }
                        end)

                        hTarget.last_scanned = _time
                    end
                end
            end
        end
    },

    ---------------------------------------------
    --- InitBuildings
    ---------------------------------------------
    {
        Class = "g_gameRules",
        Target = { "SvCollectBuildings" },
        Type = eInjection_Replace,

        ------------------------
        Function = function(self)
            if (self.IS_PS) then

                self.Buildings = {}
                self.SortedBuildings = {
                    ["bunker"] 	= {},
                    ["base"]	= {},
                    ["alien"]	= {},
                    ["hqs"]		= {},
                    ["air"]		= {},
                    ["small"]	= {},
                    ["war"]		= {},
                    ["boat"] 	= {},
                    ["proto"] 	= {}
                }

                local hBuildings = System.GetEntitiesByClass("Factory")
                local sType, sLocale
                if (hBuildings) then
                    for _, hFactory in pairs(hBuildings) do

                        table.insert(self.Buildings, hFactory)
                        if (hFactory.Properties.buyOptions.bPrototypes == 1) then
                            sType = "proto"
                            sLocale = "@l_ui_bName_Prototype"

                        elseif (hFactory:GetName():lower():find("air")) then
                            sType = "air"
                            sLocale = "@l_ui_bName_Air"

                        elseif (hFactory:GetName():lower():find("naval")) then
                            sType = "boat"
                            sLocale = "@l_ui_bName_Naval"

                        elseif (hFactory:GetName():lower():find("small")) then
                            sType = "small"
                            sLocale = "@l_ui_bName_Small"

                        else
                            sType = "war"
                            sLocale = "@l_ui_bName_War"
                        end

                        hFactory.LocaleType = sLocale
                        hFactory.BuildingType = sType
                        table.insert(self.SortedBuildings[sType], hFactory)
                        table.insert(self.Buildings, hFactory)
                    end
                end

                -- Spawn Groups
                hBuildings = System.GetEntitiesByClass("SpawnGroup")
                if (hBuildings) then

                    for _, hSpawn in pairs(hBuildings) do

                        table.insert(self.Buildings, hSpawn)
                        if ((hSpawn.Properties.teamName == "tan" or hSpawn.Properties.teamName == "black") and not hSpawn.Properties.bCaptureable) then
                            sType = "base"
                            sLocale = "@l_ui_bName_SpawnB"

                        else
                            sType = "bunker"
                            sLocale = "@l_ui_bName_Spawn"
                        end

                        hSpawn.BuildingType = sType
                        hSpawn.LocaleType = sLocale
                        table.insert(self.SortedBuildings[sType], hSpawn)
                        table.insert(self.Buildings, hSpawn)
                    end
                end

                -- Alien Energy Sites
                hBuildings = System.GetEntitiesByClass("AlienEnergyPoint")
                if (hBuildings) then
                    for _, hAlienSite in pairs(hBuildings) do

                        hAlienSite.BuildingType = "alien"
                        hAlienSite.LocaleType = "@l_ui_bName_Alien"
                        table.insert(self.Buildings, hAlienSite)
                        table.insert(self.SortedBuildings["alien"], hAlienSite)
                    end
                end

                -- HQs
                hBuildings = System.GetEntitiesByClass("HQ")
                if (hBuildings) then
                    for _, hHQ in pairs(hBuildings) do

                        hHQ.BuildingType = "hq"
                        hHQ.LocaleType = "@l_ui_bName_HQ"
                        table.insert(self.Buildings, hHQ)
                        table.insert(self.SortedBuildings["hqs"], hHQ)
                    end
                end

                -- Init Functions
                for _, hBuilding in pairs(self.Buildings) do

                    if (hBuilding.GetTeam == nil) then
                        hBuilding.GetTeam = function(this) return g_pGame:GetTeam(this.id)  end
                    end
                end
            end
        end
    },

    ---------------------------------------------
    --- CaptureByCommand
    ---------------------------------------------
    {
        Class = "g_gameRules",
        Target = { "CaptureByCommand" },
        Type = eInjection_Replace,

        ------------------------
        Function = function(self, hAdmin, sBuilding, iTeam, iTeam2)

            Debug("CaptureByCommand->",self:GetName())

            local hAdminTeam = hAdmin:GetTeam()
            local vAdminPos = hAdmin:GetPos()

            local sIndex = ""
            local hCaptureThis
            local iTargetTeam  = (FindTeam(iTeam) or hAdmin:GetTeam())

            local aBuildings = self.Buildings
            local iClosest

            -- None specified, capture closest for admins team
            if (not sBuilding) then
                for _, v in pairs(aBuildings) do
                    local iDistance = vector.distance(vAdminPos, v:GetPos())
                    if (not iClosest or iDistance < iClosest) then
                        iClosest = iDistance
                        hCaptureThis = v
                    end
                end
                if (not hCaptureThis) then

                    -- FIXME
                    return false, "@l_ui_noBuildingToCaptureFound"
                end
            end

            if (hCaptureThis) then

                if (hCaptureThis:GetTeam() == iTargetTeam and iTargetTeam ~= TEAM_NEUTRAL) then
                    iTargetTeam = TEAM_NEUTRAL --GetOtherTeam(iTargetTeam)
                end
                hCaptureThis:CancelCapture()
                hCaptureThis:Capture(iTargetTeam)
                SendMsg(MSG_INFO, ALL_PLAYERS, string.format("(%s: @l_ui_capturedForTeam %s (Admin Decision))", hCaptureThis.LocaleType, GetTeamName(iTargetTeam)))
                SendMsg(CHAT_SERVER, hAdmin, hAdmin:LocalizeNest(string.format("(%s: @l_ui_capturedForTeam %s)",  hCaptureThis.LocaleType, GetTeamName(iTargetTeam) )))
                return true

            elseif (string.lower(sBuilding) == "all") then

                for _, hBuilding in pairs(aBuildings) do
                    if (hBuilding.BuildingType ~= "base" and hBuilding.BuildingType ~= "hq") then
                        hBuilding:CancelCapture()
                        hBuilding:Capture(iTargetTeam)
                    end
                end
                SendMsg(MSG_INFO, ALL_PLAYERS, string.format("(%s: @l_ui_capturedForTeam %s (Admin Decision))", "@l_ui_allBuildings", GetTeamName(iTargetTeam)))
                SendMsg(CHAT_SERVER, hAdmin, hAdmin:LocalizeNest(string.format("(@l_ui_allBuildings: @l_ui_capturedForTeam %s)", GetTeamName(iTargetTeam) )))
                return true

            else
                local aCategory = self.SortedBuildings[string.lower(sBuilding)]
                if (aCategory) then
                    if (table.count(aCategory) == 1) then
                        hCaptureThis = aCategory[1]
                    else
                        iTargetTeam = (g_tn(iTeam2) or g_tn(iTeam) or hAdmin:GetTeam())
                        if (aCategory[tonumber(iTeam or iTeam2 or 0)]) then
                            hCaptureThis = aCategory[tonumber(iTeam or iTeam2 or 0)]
                            sIndex = (" #" .. (iTeam or iTeam2) .. "")
                        else
                            SendMsg(CHAT_SERVER, hAdmin, hAdmin:LocalizeNest("@l_ui_specifyBuildingIndex", { table.count(aCategory), string.capitalN(sBuilding) }))
                            return true
                        end
                    end
                else
                    return false, "@l_ui_unknownBuilding"
                end
            end

            if (hCaptureThis) then

                if (hCaptureThis:GetTeam() == iTargetTeam) then
                    hCaptureThis:CancelCapture()
                    hCaptureThis:Uncapture(iTargetTeam)
                    SendMsg(MSG_INFO, ALL, string.format("(%s: %s@l_ui_uncapturedFromTeam %s (Admin Decision))", hCaptureThis.LocaleType, sIndex, GetTeamName(iTargetTeam)))
                    SendMsg(CHAT_SERVER, hAdmin, hAdmin:LocalizeNest(string.format("(%s: %s@l_ui_uncapturedFromTeam %s)",  hCaptureThis.LocaleType, sIndex, GetTeamName(iTargetTeam)) ))
                else

                    hCaptureThis:CancelCapture()
                    hCaptureThis:Capture(iTargetTeam)
                    SendMsg(MSG_INFO, ALL, string.format("(%s: %s@l_ui_capturedForTeam %s (Admin Decision))", hCaptureThis.LocaleType, sIndex, GetTeamName(iTargetTeam)))
                    SendMsg(CHAT_SERVER, hAdmin, hAdmin:LocalizeNest(string.format("(%s: %s@l_ui_capturedForTeam %s)",  hCaptureThis.LocaleType, sIndex, GetTeamName(iTargetTeam) )))
                end
            end
        end
    },

    ---------------------------------------------
    --- CheckAction
    ---------------------------------------------
    {
        Class = "g_gameRules",
        Target = { "CheckAction" },
        Type = eInjection_Replace,

        ------------------------
        Function = function(self, iActionID, fTask)
            return self:CheckTimedAction(iActionID, -1, fTask)
        end

    },

    ---------------------------------------------
    --- CheckTimedAction
    ---------------------------------------------
    {
        Class = "g_gameRules",
        Target = { "CheckTimedAction" },
        Type = eInjection_Replace,

        ------------------------
        Function = function(self, iActionID, iExpiry, fTask)

            local bReset  = false
            local hAction = self.ACTIONS[iActionID]

            if (hAction == nil) then
                fTask(self)
                bReset = true

            elseif (hAction.TimerExpire ~= -1 and hAction.LastExecute.expired(iExpiry)) then
                fTask(self)
                bReset = true
            end

            if (bReset) then
                self.ACTIONS[iActionID] = {

                    -- Add Members here
                    LastExecute = timernew(),
                    TimerExpire = iExpiry
                }
            end
        end

    },

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
            local hFactory, aZoneSync
            for i, hEntity in pairs(System.GetEntities()) do
                aZoneSync = hEntity.BuyZoneSync
                if (aZoneSync) then
                    hFactory = GetEntity(aZoneSync.FactoryID)
                    if (hFactory) then

                        ServerLog("Syncing Zone Data..")
                        hFactory.allClients:ClSetBuyFlags(hEntity.id, aZoneSync.Flags)
                        throw_error()
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

            if (vPos == nil) then

                -- Dirty
                local hRandom = table.shuffle(GetEntities(GetEntityClasses()))[1]
                vPos = hRandom:GetPos()
                vAng = hRandom:GetAngles()
                ServerLogWarning("No point found to spawn player!")
            end

            if (not sName) then
                sName = ServerNames:GetDefaultName({ Country = ServerChannels:GetCountryCode(iChannel), Channel = iChannel, Profile = iChannel })
            end
            sName = ServerNames:ValidateName(sName, { Country = ServerChannels:GetCountryCode(iChannel), Channel = iChannel, Profile = iChannel })

            ServerLog("Spawning new Client with Name %s", sName)

            local sSpawnClass = ConfigGet("General.PlayerSpawnClass", ENTITY_CLASS_PLAYER, eConfigGet_String)
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
            Server:Reset()
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

            --ServerDLL.UpdateGameSpyReport(eGSUpdate_Server, "")

            local iCPU      = ServerDLL.GetCPUUsage()
            local iMem      = ServerDLL.GetMemUsage()
            local iMemPeak  = ServerDLL.GetMemPeak()
            g_pGame:SetSynchedGlobalValue(GLOBAL_SERVER_IP_KEY, string.format("CPU: %.2f%%, %s (%s)", iCPU, ByteSuffix(iMem), ByteSuffix(iMemPeak)))
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
        Function = function(self, iChannel, hPlayer, bKeepEquip, bForce, aEquip)

            local iTeamForce
            if (self.IS_PS) then
                if (hPlayer:IsSpectating()) then
                    g_pGame:ChangeSpectatorMode(hPlayer.id, 0, NULL_ENTITY)
                end
                if (not bForce) then
                end
            end

            if (bForce) then --or (hPlayer:GetTeam() == 0 and self.IS_PS)) then
                if (hPlayer:IsSpectating()) then
                    hPlayer.actor:SetSpectatorMode(0, NULL_ENTITY)
                end
                g_pGame:RevivePlayer(hPlayer.id, hPlayer.RevivePosition, (hPlayer.ReviveAngles or hPlayer:GetAngles()), hPlayer:GetTeam(), not bKeepEquip)
                if (not bKeepEquip or (hPlayer:IsInventoryEmpty())) then
                    self:EquipPlayer(hPlayer, nil, aEquip)
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

                    self:EquipPlayer(hPlayer, additionalEquip, aEquip)
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
                self:CheckSpawnPP(hPlayer, hGroup.vehicle ~= nil, hGroup)
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
        Function = function(self, hPlayer, aAdditionalEquip, aForced)

            hPlayer.inventory:Destroy()
            if (hPlayer:IsPunished(ePlayerPunish_NoEquipment)) then
                throw_error("wtf")
                return
            end

            hPlayer:GiveItem("AlienCloak")
            hPlayer:GiveItem("OffHand")
            hPlayer:GiveItem("Fists")

          --  Debug("give stuff")

            local bEquipped = ServerItemHandler:EquipPlayer(hPlayer, aForced)
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
                self.game:KillPlayer(aHitInfo.targetId, true, true, aHitInfo.shooterId, aHitInfo.weaponId, aHitInfo.damage, aHitInfo.materialId, aHitInfo.typeId, aHitInfo.dir or vector.make(0,0,1));
            else
                if (hShooter and hShooter.actor and hShooter.actor:IsPlayer() and hTarget and hTarget.IsPlayer) then
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
            local iSuicideKills   = ConfigGet("General.GameRules.HitConfig.DeductSuicideKills", 0,  eConfigGet_Number)
            local iSuicideDeaths  = ConfigGet("General.GameRules.HitConfig.SuicideAddDeaths", 1,    eConfigGet_Number)
            local iTeamKillReward = ConfigGet("General.GameRules.HitConfig.DeductTeamKill", 1,      eConfigGet_Number)
            local bRemoveBotScore = ConfigGet("General.GameRules.HitConfig.DeductBotKills", false,  eConfigGet_Boolean)

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

            if (hShooter and hShooter.IsPlayer and (iKillType ~= eKillType_Suicide)) then

                local iAccuracy = hShooter:GetHitAccuracy()
                local aMessageList = {
                    [ 0] = "@l_ui_accuracy_0",
                    [ 5] = "@l_ui_accuracy_5",
                    [10] = "@l_ui_accuracy_10",
                    [20] = "@l_ui_accuracy_20",
                    [35] = "@l_ui_accuracy_35",
                    [50] = "@l_ui_accuracy_50",
                    [60] = "@l_ui_accuracy_60",
                    [70] = "@l_ui_accuracy_70",
                    [80] = "@l_ui_accuracy_80",
                    [90] = "@l_ui_accuracy_90",
                    [99] = "@l_ui_accuracy_99",
                }
                local sAccuracy = table.it(aMessageList, function(x, i, v) if (iAccuracy >= i and (x == nil or x[1] < i)) then return { i, v } end return x end)[2]
                SendMsg(CHAT_SERVER, hShooter, hShooter:Localize("@l_ui_accuracy", { hShooter:Localize(sAccuracy), string.format("%.2f", iAccuracy) }))

                hShooter:RefreshHitAccuracy()
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

            local hPlayer = GetEntity(hPlayerID)
            if (not hPlayer) then
                return
            end

            local bOk = ConfigGet("General.GameRules.HitConfig.TeamKill.Allowed", false, eConfigGet_Boolean)
            if (bOk) then
                return
            end

            local iThreshold = ConfigGet("General.GameRules.HitConfig.TeamKill.PunishThreshold", 5, eConfigGet_Number)
            local iBanTime = ConfigGet("General.GameRules.HitConfig.TeamKill.BanTime", 0, eConfigGet_Number)

            self.TeamKills[hPlayerID] = ((self.TeamKills[hPlayerID] or 0) + 1)
            if (self.TeamKills[hPlayerID] > iThreshold) then
                if (iBanTime > 0) then
                    ServerPunish:BanPlayer(Server.ServerEntity, hPlayer, iBanTime, "Team Killing")

                else
                    KickPlayer(hPlayer, "Team Killing", nil, "Server")
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
                    return
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
                    local hPlayer = GetEntity(hPlayerID)
                    if (hPlayerID ~= hShooter.id and hPlayerID ~= hTarget.id and hPlayer and hPlayer.IsPlayer) then

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
                        --    throw_error("timer expired")
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

            if (hWeapon and hWeapon.weapon and hShooter.IsPlayer) then
                if (hShooter:HitAccuracyExpired()) then
                    hShooter:RefreshHitAccuracy()
                end
                hShooter:UpdateHitAccuracy(eHitAccuracy_OnShot)
            end

            return true
            --SendMsg(MSG_CENTER, hShooter, "Accuracy: " .. hShooter:GetHitAccuracy())
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
                    end

                    hTarget.CollectedHits[hShooter.id].Timer.refresh()
                    hTarget.CollectedHits[hShooter.id].HitCount     = (hTarget.CollectedHits[hShooter.id].DamageCount + 1)
                    hTarget.CollectedHits[hShooter.id].DamageCount  = (hTarget.CollectedHits[hShooter.id].DamageCount + aHitInfo.damage)

                end

                if (hShooter.IsPlayer) then
                    if (not aHitInfo.explosion and not aHitInfo.melee) then
                        if (not hShooter:HitAccuracyExpired()) then
                            hShooter:UpdateHitAccuracy(eHitAccuracy_OnHit)
                        end
                    end
                end
            end

            if (aHitInfo.type == "" and not aHitInfo.explosion and aHitInfo.targetId==aHitInfo.shooterId) then
                aHitInfo.damage = aHitInfo.damage * self.FallDamageMultiplier
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

    ---------------------------------------------
    --- CheckTimeLimit
    ---------------------------------------------
    {

        Class = "g_gameRules",
        Target = { "CheckTimeLimit" },
        Type = eInjection_Replace,

        ------------------------
        Function = function(self)
            local fCheck = self["CheckTimeLimit_" .. (self.class)]
            if (fCheck == nil) then
                throw_error("no timelimit check found")
            end

            fCheck(self)
        end

    },

    ---------------------------------------------
    --- CheckTimeLimit
    ---------------------------------------------
    {

        Class = "g_gameRules",
        Target = { "CheckTimeLimit_PowerStruggle" },
        Type = eInjection_Replace,

        ------------------------
        Function = function(self)

            ---------
            local sGameState = self:GetState()
            local iTimeLeft  = self.game:GetRemainingGameTime()
            local bIsLimited = self.game:IsTimeLimited()

            if (bIsLimited and iTimeLeft <= 0) then
                if (sGameState ~= "InGame") then
                    return
                end

                self.AddTimeHit = false
                self.MapVote = false
                self:EndGameWithWinner_PS()

            elseif (bIsLimited) then

                if (iTimeLeft <= FIVE_MINUTES) then
                    self:CheckAction(eGRMessage_AutoVoteStart, function()
                    --    SendMsg(CHAT_VOTING, ALL, "Map ends in 5 Minutes! Map Voting Started, cast your vote using !vote");
                    end)

                elseif (iTimeLeft <= FIFTEEN_MINUTES) then
                    self:CheckAction(eGRMessage_MapEndsIn, function()
                        SendMsg(CHAT_VOTING_LOCALE, ALL, "@l_ui_mapEndsSoon");
                    end)
                end
            end

        end
    },

    ---------------------------------------------
    --- EndGameWithWinner_IA
    ---------------------------------------------
    {

        Class = "g_gameRules",
        Target = { "EndGameWithWinner_PS" },
        Type = eInjection_Replace,

        ------------------------
        Function = function(self)

            ---------
            local bDraw      = true
            local iMaxHP     = nil
            local iMaxTeamID = nil

            for _, iTeamID in pairs(self.teamId) do
                local iHP = 0
                for __, iHQId in pairs(self.hqs) do
                    if (self.game:GetTeam(iHQId) == iTeamID) then
                        local hHQ = System.GetEntity(iHQId)
                        if (hHQ) then
                            iHP = (iHP + math.max(0, hHQ:GetHealth()))
                        end
                    end
                end

                if (not iMaxHP) then
                    iMaxHP = iHP
                    iMaxTeamID = iTeamID
                else
                    if (iHP > iMaxHP or iHP < iMaxHP) then
                        if (iHP > iMaxHP) then
                            iMaxHP = iHP
                            iMaxTeamID = iTeamID
                        end
                        bDraw = false
                    end
                end
            end

            if (not bDraw) then
                self:OnGameEnd(iMaxTeamID, 2)
            else
                self:OnGameEnd(nil, 2)
            end
        end
    },

    ---------------------------------------------
    --- CheckTimeLimit
    ---------------------------------------------
    {

        Class = "g_gameRules",
        Target = { "CheckTimeLimit_InstantAction" },
        Type = eInjection_Replace,

        ------------------------
        Function = function(self)

            ---------
            local sGameState = self:GetState()
            local iTimeLeft  = self.game:GetRemainingGameTime()
            local bIsLimited = self.game:IsTimeLimited()

            if (bIsLimited and (sGameState == "InGame")) then
                if (iTimeLeft <= 0) then
                    self:EndGameWithWinner_IA()

                elseif (ConfigGet("General.MapConfig.IAEndGameRadio", true, eConfigGet_Boolean)) then
                    local aRadioTimers = {
                        [120] = "mp_american/us_commander_2_minute_warming_01",
                        [60 ] = "mp_american/us_commander_1_minute_warming_01",
                        [30 ] = "mp_american/us_commander_30_second_warming_01",
                        [5  ] = "mp_american/us_commander_final_countdown_01",
                    }

                    self:CheckTimedAction(eGRMessage_GameEndRadio, 1, function(this)

                        local iLeft  = math.floor(iTimeLeft)
                        local sSound = aRadioTimers[iLeft]
                        if (sSound) then
                            SendMsg(MSG_INFO, ALL_PLAYERS, "@l_ui_gameEndCountdownInfo", iLeft)
                            ClientMod:OnAll([[g_Client:PSE("]]..sSound..[[",nil,"timeralert")]], {
                                Sync = false,
                                SyncID = "timermsg",
                                Server = function(_code_)
                                    Debug("heelo madafaka")
                                end
                            })
                        end

                        if (iTimeLeft <= 30) then
                            SendMsg(MSG_CENTER, ALL_PLAYERS, "@l_ui_gameEndCountdown", iLeft)
                        end
                    end)
                end
            end

        end
    },

    ---------------------------------------------
    --- EndGameWithWinner_IA
    ---------------------------------------------
    {

        Class = "g_gameRules",
        Target = { "EndGameWithWinner_IA" },
        Type = eInjection_Replace,

        ------------------------
        Function = function(self)

            ---------
            local iMaxScore = nil
            local iMinDeath = nil
            local iMaxID    = nil
            local iMinID    = nil
            local bDraw     = false

            local aPlayers = self.game:GetPlayers(true)

            if (aPlayers) then
                for _, hPlayer in pairs(aPlayers) do
                    local iScore = self:GetPlayerScore(hPlayer.id)
                    if (not iMaxScore) then
                        iMaxScore = iScore
                    end

                    if (iScore >= iMaxScore) then
                        if ((iMaxID ~= nil) and (iMaxScore == iScore)) then
                            bDraw = true
                        else
                            bDraw     = false
                            iMaxID    = hPlayer.id
                            iMaxScore = iScore
                        end
                    end
                end

                -- if there's a draw, check for lowest number of deaths
                if (bDraw) then

                    iMinID    = nil
                    iMinDeath = nil

                    for _, hPlayer in pairs(aPlayers) do

                        local iScore = self:GetPlayerScore(hPlayer.id)
                        if (iScore == iMaxScore) then
                            local iDeaths = self:GetPlayerDeaths(hPlayer.id)
                            if (not iMinDeath) then
                                iMinDeath = iDeaths
                            end

                            if (iDeaths <= iMinDeath) then
                                if ((iMinID ~= nil) and (iMinDeath == iDeaths)) then
                                    bDraw = true
                                else
                                    bDraw     = false
                                    iMinID    = hPlayer.id
                                    iMinDeath = iDeaths
                                end
                            end
                        end
                    end

                    if (not bDraw) then
                        iMaxID = iMinID
                    end
                end
            end

            if (not bDraw) then
                self:OnGameEnd(iMaxID, 2)
            else
                self:OnGameEnd(nil, 2)
            end
        end
    },

    ---------------------------------------------
    --- OnGameEnd
    ---------------------------------------------
    {

        Class = "g_gameRules",
        Target = { "OnGameEnd" },
        Type = eInjection_Replace,

        ------------------------
        Function = function(self, hWinnerID, iType, hShooterID)

            ---------
            local sWinner = GetEntityN(hWinnerID)
            local sNextMap, sRules = ServerMaps:GetNextLevel()
            if (self.IS_IA) then
                if (hWinnerID) then
                    self.game:SendTextMessage(TextMessageCenter, "@mp_GameOverWinner", TextMessageToAll, nil, sWinner)
                    self.allClients:ClVictory(hWinnerID)
                else
                    self.game:SendTextMessage(TextMessageCenter, "@mp_GameOverNoWinner", TextMessageToAll)
                    self.allClients:ClNoWinner()
                end

            elseif (self.IS_PS) then
                if (hWinnerID and hWinnerID ~= 0) then
                    local sTeam = self.game:GetTeamName(hWinnerID)
                    self.game:SendTextMessage(TextMessageCenter, "@mp_GameOverWinner", TextMessageToAll, nil, "@mp_team_" .. sTeam)
                else
                    self.game:SendTextMessage(TextMessageCenter, "@mp_GameOverNoWinner", TextMessageToAll)
                end
                self.allClients:ClVictory((hWinnerID or 0), iType, (hShooterID or NULL_ENTITY))
                self.nukePlayer = (hShooterID or NULL_ENTITY)
            end

            if (not self.QuietGameEnd) then
                SendMsg(CHAT_SERVER_LOCALE, ALL_PLAYERS, "@l_ui_nextMap", sNextMap, ServerMaps:LongRules(sRules))
            end

            self.game:EndGame()
            self:GotoState("PostGame")
            self.GameEnded = true
        end
    },
}

------------
ServerInjector.InjectAll(ServerGameRules)