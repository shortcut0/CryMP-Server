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
        self.TaggedExplosives = {}

        eGRMessage_AutoVoteStart = 0
        eGRMessage_MapEndsIn     = 1
        eGRMessage_GameEndRadio  = 1

        ---------
        self.TEAM_CHANGE_MIN_TIME = 0

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
        self.RougeJets = {}

        ---------
        local iTeamKillDamage = ConfigGet("General.GameRules.HitConfig.TeamKill.DamageMultiplier", 0, eConfigGet_Number)
        SetCVar("g_friendlyFireRatio", g_ts(iTeamKillDamage))
        if (g_pGame.InitScriptTables) then
            g_pGame:InitScriptTables()
        end

        self.FirstBlood = {
            Reward  = ConfigGet("General.GameRules.HitConfig.FirstBlood.Reward", 500, eConfigGet_Number),
            Enabled = ConfigGet("General.GameRules.HitConfig.FirstBlood.Enabled", true, eConfigGet_Boolean),
            Shooters = {
                [TEAM_NK] = nil,
                [TEAM_US] = nil,
                [TEAM_NEUTRAL] = nil,
            }
        }

        ---------

        self.StreakMessages = {
            Deaths  = ConfigGet("General.GameRules.HitConfig.KillStreaks.DeathMessages", {}, eConfigGet_Array),
            Kills   = ConfigGet("General.GameRules.HitConfig.KillStreaks.KillMessages", {}, eConfigGet_Array),
            Repeats = ConfigGet("General.GameRules.HitConfig.KillStreaks.RepeatMessages", {}, eConfigGet_Array)
        }

        ---------

        self.KillConfig = {
            SuicideKills    = ConfigGet("General.GameRules.HitConfig.DeductSuicideKills", 0,  eConfigGet_Number),
            SuicideDeaths   = ConfigGet("General.GameRules.HitConfig.SuicideAddDeaths", 1,    eConfigGet_Number),
            TeamKill        = ConfigGet("General.GameRules.HitConfig.DeductTeamKill", 1,      eConfigGet_Number),
            BotScore        = ConfigGet("General.GameRules.HitConfig.DeductBotKills", false,  eConfigGet_Boolean),
            NewMessages     = ConfigGet("General.GameRules.EnableNewKillMessages", true, eConfigGet_Boolean)
        }

        FSetCVar("mp_killMessages", g_ts(self.KillConfig.NewMessages and 0 or 1))

        self.PingControl = {
            Limit   = ConfigGet("General.PingControl.PingLimit.Limit", 300, eConfigGet_Number),
            Delay   = ConfigGet("General.PingControl.PingLimit.InfractionDelay", 10, eConfigGet_Number),
            Type    = ConfigGet("General.PingControl.PingLimit.CheckType", "Real", eConfigGet_String),
            Warns   = ConfigGet("General.PingControl.PingLimit.InfractionLimit", 5, eConfigGet_Number),
            BanTime = ConfigGet("General.PingControl.PingLimit.BanTime", 0, eConfigGet_Number),
            Text    = ConfigGet("General.PingControl.PingLimit.WarningMessage", "@l_ui_pingwarning", eConfigGet_String),
        }
        Debug("shoul dbe 10, its:",ConfigGet("General.PingControl.InfractionLimit", -6969696, eConfigGet_Number))

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
            hClient.TagAward = { PP = 0, CP = 0, Timer = nil, Num = 0, Hostiles = 0 }
            hClient.PingControl = { Timer = timernew(), WarnCount = 0 }

            self:SvInitClientStreaks(hClient)
            ServerLog("GameRules.InitClient")
        end

    },

    ---------------------------------------------
    --- RequestSpawnGroup
    ---------------------------------------------
    {
        Class = "g_gameRules",
        Target = { "Server.RequestSpawnGroup" },
        Type = eInjection_Replace,

        ------------------------
        Function = function(self, playerId, groupId, force)
            local player = System.GetEntity(playerId);
            if (not player or not player.actor) then
                return
            end

            local teamId=self.game:GetTeam(playerId);

            if ((not force) and (teamId ~= self.game:GetTeam(groupId))) then
                return;
            end

            if (groupId==player.spawnGroupId) then
                return;
            end

            local group=System.GetEntity(groupId);
            if (group and group.vehicle and (group.vehicle:IsDestroyed() or group.vehicle:IsSubmerged())) then
                return;
            end

            if (group and group.vehicle) then
                local vehicle=group.vehicle;
                local seats=group.Seats;
                local seatCount = 0;

                for i,v in pairs(seats) do
                    if ((not v.seat:IsGunner()) and (not v.seat:IsDriver()) and (not v.seat:IsLocked())) then
                        seatCount=seatCount+1;
                    end
                end

                local occupied=0;
                local players=self.game:GetPlayers(true);
                local mateGroupId;

                if (players) then
                    for i,player in pairs(players) do
                        if (teamId==self.game:GetTeam(player.id)) then
                            mateGroupId=self:GetPlayerSpawnGroup(System.GetEntity(player.id)) or NULL_ENTITY;
                            if (mateGroupId==groupId) then
                                occupied=occupied+1;
                            end
                        end
                    end
                end

                if (occupied>=seatCount) then
                    return;
                end
            end

            self:SetPlayerSpawnGroup(playerId, groupId);

            if ((not g_localActorId) or (g_localActorId~=playerId)) then
                local channelId=player.actor:GetChannel();

                if (channelId and channelId>0) then
                    self.onClient:ClSetSpawnGroup(channelId, groupId);
                end
            end

            self:UpdateSpawnGroupSelection(player.id);
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
            if (not hPlayer or not hPlayer.actor) then
                return
            end

            --- 111 Is from Bots
            if (iMode == 111) then
                ServerPCH:OnBotConnection(hPlayer)
                return
            end

            if ((iMode < -3 or iMode > 3)) then
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

                            hPlayer:Execute([[ClientEvent(eEvent_BLE,eBLE_Currency,"]]..hPlayer:LocalizeNest((hBuilding.LocaleType or "Unknown") .. " @l_ui_captured ( +" .. iValue .. " PP )")..[[")]])
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
        Target = { "OnRadarScanComplete" },
        Type = eInjection_Replace,

        ------------------------
        Function = function(self, hShooterID, hWeaponID, iScanDistance)

            local hShooter = System.GetEntity(hShooterID)
            local hWeapon = System.GetEntity(hWeaponID)

            local iTeam = hShooter:GetTeam()

            if (GetCVar("server_allow_scan_explosives") > 0) then
                local aNearby = System.GetEntitiesInSphere(hShooter:GetPos(), iScanDistance / 3)
                for _, hNearby in pairs(aNearby) do
                    if (IsAny(hNearby.class, "claymoreexplosive", "avexplosive", "c4explosive"
                    )) then
                        self.TaggedExplosives[hNearby.id] = {
                            Timer       = timernew(),
                            EffectTimer = timernew(),
                            MsgTimer    = timernew(),
                            TeamID      = hShooter:GetTeam()
                        }
                        hShooter.TagAward.Num = hShooter.TagAward.Num + 1
                        hShooter.TagAward.PP  = hShooter.TagAward.PP + 5
                        hShooter.TagAward.CP  = hShooter.TagAward.CP + 1

                        local vPos = hNearby:GetPos()
                        if (iTeam ~= TEAM_NEUTRAL) then
                            Debug("hello! not neutral!!! on team",iTeam)
                            Debug(hNearby:GetName(), iTeam, #GetPlayers({ TeamID = iTeam }))
                            --ClientMod.ExecuteOn(GetPlayers({ TeamID = iTeam }), 'g_Client:SLH("' .. hNearby:GetName() .. '","red",15)ClientLog("slh")')
                            ClientMod.ExecuteOn(GetPlayers({ TeamID = iTeam }), string.format([[g_Client:ESLH("%s","%s",{x=%f,y=%f,z=%f},%d,0.15)]],
                                    hNearby:GetName(), hNearby.class, vPos.x, vPos.y, vPos.z, g_pGame:GetTeam(hNearby.id)
                            ))
                        else
                            --ClientMod.ExecuteOn(GetPlayers({ NotID = hShooter.id }), 'g_Client:SLH("' .. hNearby:GetName() .. '","red",15)')
                            --ClientMod.ExecuteOn({ hShooter }, 'g_Client:SLH("' .. hNearby:GetName() .. '","green",15)')
                            ClientMod.ExecuteOn(GetPlayers({ NotID = hShooter.id }), string.format([[g_Client:ESLH("%s","%s",{x=%f,y=%f,z=%f},%d,0.15,"red")]],
                                    hNearby:GetName(), hNearby.class, vPos.x, vPos.y, vPos.z, g_pGame:GetTeam(hNearby.id)
                            ))
                            ClientMod.ExecuteOn({ hShooter }, string.format([[g_Client:ESLH("%s","%s",{x=%f,y=%f,z=%f},%d,0.15,"green")]],
                                    hNearby:GetName(), hNearby.class, vPos.x, vPos.y, vPos.z, g_pGame:GetTeam(hNearby.id)
                            ))
                        end
                        --ClientMod.ExecuteOn(GetPlayers({ TeamID = GetOtherTeam(hShooter:GetTeam()) }), 'g_Client:SLH("' .. hNearby:GetName() .. '","red",15)')
                    end
                end
            end

            if (self.IS_PS) then

                local iScanned = hShooter.TagAward.Num
                if (iScanned > 0) then

                    local iHostile = hShooter.TagAward.Hostiles
                    Debug(iHostile)
                    if (iHostile > 0) then
                        local aNearby = GetPlayers({ NotID = hShooter.id, Range = iScanDistance, Pos = hShooter:GetPos(), Team = hShooter:GetTeam() })
                        for _, hNearby in pairs(aNearby) do

                            hNearby:Execute(string.format([[g_Client:PSE("sounds/interface:multiplayer_interface:mp_tac_alarm_suit",nil,"hostiles")ClientEvent(eEvent_BLE,eBLE_Warning,"%s")]],
                                    hNearby:Localize("@l_ui_hostilesOnRadar", {iHostile}))
                            )
                        end
                    end

                    hShooter:Execute(string.format(
                            [[ClientEvent(eEvent_BLE,eBLE_Currency,"%s ( +%d PP, +%d CP )")]],
                            hShooter:Localize("@l_ui_entitiesTagged",{hShooter.TagAward.Num.." "}),
                            hShooter.TagAward.PP,
                            hShooter.TagAward.CP
                    ))
                    self:AwardPPCount(hShooterID, self.ppList.TAG_ENEMY, nil, hShooter:HasClientMod())
                    self:AwardCPCount(hShooterID, self.cpList.TAG_ENEMY, nil, hShooter:HasClientMod())
                else
                    hShooter:Execute(string.format(
                            [[ClientEvent(eEvent_BLE,eBLE_Warning,"%s")]],
                            hShooter:Localize("@l_ui_noEntitiesTagged",{}),
                            hShooter.TagAward.PP,
                            hShooter.TagAward.CP
                    ))
                end
            end

            hShooter.TagAward = {
                CP  = 0,
                PP  = 0,
                Num = 0,
                Hostiles = 0
            }
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
        Function = function(self, hShooterID, hTargetID, sClass)

           -- Debug("C")

            -- give players PP and CP for tagging enemies
            local iTeam_S = self.game:GetTeam(hShooterID)
            local iTeam_T = self.game:GetTeam(hTargetID)

            local hTarget = System.GetEntity(hTargetID)
            local hShooter = System.GetEntity(hShooterID)

            local bTesting = hShooter.IsPlayer and hShooter:IsTesting()

            if ((iTeam_S ~= iTeam_T) or bTesting) then

                -- Always increase counter!
                hShooter.TagAward.Num = (hShooter.TagAward.Num) + 1

                if (hTarget) then
                    if ((hShooter:IsTesting() or not hTarget.last_scanned) or (_time - hTarget.last_scanned > 16)) then

                        if ((hTarget and hTarget.class == "Player") or bTesting) then
                            hShooter.TagAward.Hostiles = hShooter.TagAward.Hostiles + 1
                        end

                        hShooter.TagAward.PP  = (hShooter.TagAward.PP) + self.ppList.TAG_ENEMY
                        hShooter.TagAward.CP  = (hShooter.TagAward.CP) + self.cpList.TAG_ENEMY

                        hTarget.last_scanned = _time
                    end
                end
                --[[
                                if (IsAny(sClass, "c4explosive", "avexplosive", "claymoreexplosive")) then
                                    hShooter.TagAward.PP  = (hShooter.TagAward.PP) + 15
                                    hShooter.TagAward.CP  = (hShooter.TagAward.CP) + self.cpList.TAG_ENEMY
                                    self.TaggedExplosives[hTargetID] = { Timer = timernew() }


                                    Debug("expl")
                                end]]
            end
--[[
            if (hShooter) then
                if (hShooter.TagAward.Timer) then
                    Script.KillTimer(hShooter.TagAward.Timer)
                end
                hShooter.TagAward.Timer = Script.SetTimer(125, function()


                end)
            end]]
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
        Target = { "Server.OnClientConnect", "Server.InGame.OnClientConnect", "Server.PreGame.OnClientConnect", "Server.PostGame.OnClientConnect" },
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
    --- SetPlayerRank
    ---------------------------------------------
    {

        Class = "g_gameRules",
        Target = { "SetPlayerRank" },
        Type = eInjection_Replace,

        ------------------------
        Function = function(self, iClientID, iRank)
            if (self.IS_IA) then
                return
            end
            return (g_pGame:SetSynchedEntityValue(iClientID, self.RANK_KEY, iRank))
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
            Server:OnMapReset()
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

            for hID, hVehicle in pairs(self.RougeJets) do
                if (not GetEntity(hID) or hVehicle:GetDriver() or hVehicle.vehicle:IsDestroyed()) then
                    self.RougeJets[hID] = nil
                    --Debug("nun")
                end

                if (self.RougeJets[hID] and hVehicle.CLIENT_THRUSTERS) then

                    local fImpulse = hVehicle:GetMass() * 10 * 1--(hVehicle.CLIENT_THRUSTERPOWER / 100)
                    hVehicle:AddImpulse(-1, hVehicle:GetCenterOfMassPos(), hVehicle:GetDirectionVector(), fImpulse, 1)
                    --Debug(hVehicle.CLIENT_THRUSTERPOWER)
                end
            end

            --[[
            for _, aInfo in pairs(self.TaggedExplosives) do
                if (not GetEntity(_)) then
                    self.TaggedExplosives[_] = nil
                else
                    if (aInfo.Timer.expired(15)) then
                        self.TaggedExplosives[_] = nil
                    elseif (aInfo.EffectTimer.expired(3)) then
                        --SpawnEffect("misc.runway_light.flash_red", ServerDLL.GetProjectilePos(_), g_Vectors.up, 0.1)
                        aInfo.EffectTimer.refresh()
                    end
                end
            end]]
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
            for _, aInfo in pairs(self.TaggedExplosives) do
                local hExplosive = GetEntity(_)
                if (not hExplosive) then
                    self.TaggedExplosives[_] = nil
                else
                    if (aInfo.Timer.expired(15)) then
                        self.TaggedExplosives[_] = nil
                    elseif (aInfo.MsgTimer.expired_refresh(1)) then
                        --SendMsg(MSG_CENTER, GetPlayers({ TeamID = aInfo.TeamID, Pos = hExplosive:GetPos(), Range = 8 }), "@l_ui_explosiveNearby")
                        for __, hNearby in pairs(GetPlayers({ TeamID = aInfo.TeamID, Pos = hExplosive:GetPos(), Range = 8 })) do
                            SendMsg(MSG_CENTER, hNearby, hNearby:LocalizeNest("@l_ui_explosiveNearby", { string.format("%0.2f", hNearby:Distance(hExplosive)) }))
                        end
                    end
                end
            end

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

            local aControlInfo = self.PingControl
            local iBanTime     = aControlInfo.BanTime

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

                    local iCheck = (string.lower(aControlInfo.Type) == "real" and hClient:GetRealPing() or iPing)
                    local iLimit = aControlInfo.Limit
                    if (hClient:IsTesting()) then
                        iLimit = 10
                    end
                    if (iCheck >= iLimit) then
                        if (hClient.PingControl.Timer.expired_refresh(aControlInfo.Delay)) then

                            local iWarns = (hClient.PingControl.WarnCount + 1)
                            if (iWarns > aControlInfo.Warns) then

                                if (iBanTime > 0) then
                                    ServerPunish:BanPlayer(Server.ServerEntity, hClient, iBanTime, ("High Latency (Limit " .. iLimit .. ")"))
                                else
                                    KickPlayer(hClient, ("High Latency (Limit " .. iLimit .. ")"), nil, "Server")
                                end
                            else

                                hClient.PingControl.WarnCount = (hClient.PingControl.WarnCount + 1)
                                SendMsg(CHAT_SERVER, hClient, hClient:LocalizeNest(aControlInfo.Text, { iLimit, hClient.PingControl.WarnCount, aControlInfo.Warns, iCheck }))
                            end
                        end
                    end
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

                    if (hPlayer.last_team_change and (oldTeamId ~= 0 and iTeam ~= 0)) then
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
        Target = { "UpdateReviveQueue" },
        Type = eInjection_Replace,

        ------------------------
        Function = function(self)

            if (not self.IS_PS) then
                return
            end

            -- todo: someone with free time rewrite this
            local iAutoSpecTime   = ConfigGet("General.GameRules.AutoSpectateTimer", 30, eConfigGet_Number)
            local iPremiumSpawnPP = ConfigGet("General.GameRules.PremiumSpawnPP", 1.25, eConfigGet_Number)

           -- Debug("UPDATED!!")
            local reviveTimer = self.game:GetRemainingReviveCycleTime()
            if (reviveTimer>0) then
                for playerId,revive in pairs(self.reviveQueue) do
                    if (revive.active) then
                        local player=System.GetEntity(playerId);
                        if (player and player.spawnGroupId and player.spawnGroupId~=NULL_ENTITY) then

                            if (not revive.announced) then
                                self.onClient:ClReviveCycle(player.actor:GetChannel(), true);
                                revive.announced=true;
                                --Debug("show cycle!")
                            end
                        elseif (revive.announced) then -- spawngroup got invalidated while spawn cycle was up,
                            -- so need to make sure it gets sent again after the situation is cleared
                            revive.announced=nil;
                        end
                    end
                end

                -- if player has been dead more than 5s and isn't spectating, auto-switch to spectator mode 3
                local players=self.game:GetPlayers();
                if (players) then
                    for i,player in pairs(players) do
                        if(player and player:IsDead() and player.death_time and _time-player.death_time>iAutoSpecTime and player.actor:GetSpectatorMode() == 0) then
                            self.Server.RequestSpectatorTarget(self, player.id, 1);
                        end
                    end
                end
            end

            if (reviveTimer<=0) then
                self.game:ResetReviveCycleTime();

                for i,teamId in ipairs(self.teamId) do
                    self:UpdateTeamRanks(teamId);
                end

                for playerId,revive in pairs(self.reviveQueue) do
                    if (revive.active and self:CanRevive(playerId)) then
                        revive.active=false;

                        local player=System.GetEntity(playerId);
                        if (player) then
                            self:RevivePlayer(player.actor:GetChannel(), player)

                            if (not revive.tk) then
                                local rank=self.rankList[self:GetPlayerRank(player.id)]
                                if (rank and rank.min_pp and rank.min_pp>0) then

                                    local currentpp=self:GetPlayerPP(player.id)
                                    local iMinPP = rank.min_pp * (player:IsPremium() and iPremiumSpawnPP or 1)
                                    if (currentpp < iMinPP) then

                                        local iAward = iMinPP - currentpp

                                        if (iAward > 0) then
                                            self:AwardPPCount(player.id, iAward, nil, player:HasClientMod())

                                            Script.SetTimer(100, function()
                                                player:Execute(string.format([[g_Client.Event(eEvent_BLE, eBLE_Currency,"%%1 %s ( +%d PP )","%s")]],
                                                        player:Localize("@l_ui_spawnPP"),
                                                        iMinPP,
                                                        rank.name
                                                ))
                                            end)
                                        end
                                    end
                                end
                            end

                            self:CommitRevivePurchases(playerId)
                            revive.tk = nil
                            revive.announced = nil
                        end
                    end
                end
            end
        end

    },

    ---------------------------------------------
    --- CanRevive
    ---------------------------------------------
    {

        Class = "g_gameRules",
        Target = { "CanRevive" },
        Type = eInjection_Replace,

        ------------------------
        Function = function(self, playerId)
            local player=System.GetEntity(playerId);
            if (not player) then
                return false;
            end

            local groupId=player.spawnGroupId;
            if ((not self.USE_SPAWN_GROUPS) or (groupId and groupId~=NULL_ENTITY)) then
                Debug("can revive!")
                return true;
            end
            return false;
        end

    },

    ---------------------------------------------
    --- QueueRevive
    ---------------------------------------------
    {

        Class = "g_gameRules",
        Target = { "QueueRevive" },
        Type = eInjection_Replace,

        ------------------------
        Function = function(self, playerId)
            local revive=self.reviveQueue[playerId]

            if (not revive) then
                self:ResetRevive(playerId)
                revive=self.reviveQueue[playerId]
            end

            revive.active=true;
            --Debug("revive active?")

            local player=System.GetEntity(playerId);
            if (player) then
                self.channelSpectatorMode[player.actor:GetChannel()]=nil;
            end
        end

    },

    ---------------------------------------------
    --- HandlePings
    ---------------------------------------------
    {

        Class = "g_gameRules",
        Target = { "Server.RequestRevive" },
        Type = eInjection_Replace,

        ------------------------
        Function = function(self, hPlayerID)

            local hPlayer = GetEntity(hPlayerID)
            local iQueueTimer = (g_pGame:GetRemainingReviveCycleTime() or 0)

            --Debug("reques?")
            --Debug("spawngrou=",g_ts(hPlayer.spawnGroupId),"team=",g_pGame:GetTeam(hPlayer.spawnGroupId),"(null=",NULL_ENTITY)
            if (hPlayer and hPlayer.actor) then

                if (hPlayer:HasInstantRevive()) then
                    --Debug("instant=")
                    return self:RevivePlayer(hPlayer.actor:GetChannel(), hPlayer)
                end

                if (self.IS_PS) then
                    if (hPlayer.spawnGroupId and hPlayer.spawnGroupId ~= NULL_ENTITY) then
                        if (((hPlayer.actor:GetSpectatorMode() == 3 and self.game:GetTeam(hPlayerID) ~= 0) or (hPlayer:IsDead() and hPlayer.death_time and _time - hPlayer.death_time > 2.5)) and (not self:IsInReviveQueue(hPlayerID))) then
                            self:QueueRevive(hPlayerID)
                            --Debug("SHOUL DBE IN QUEU !!")
                        elseif (iQueueTimer >= 2 and self:IsInReviveQueue(hPlayerID)) then
                            self:ResetRevive(hPlayerID)
                            SendMsg(MSG_CENTER, hPlayer, "@l_ui_reviveQueuePaused")
                        end
                    else
                        SendMsg(MSG_ERROR, hPlayer, "@l_ui_noSpawnGroupSelected")
                    end
                else
                    if (hPlayer.death_time and _time - hPlayer.death_time > 2.5 and hPlayer:IsDead()) then
                        self:RevivePlayer(hPlayer.actor:GetChannel(), hPlayer)
                    end
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

            if (hPlayer.IsPlayer) then
                hPlayer.SpawnTimer.refresh()
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

                ServerLogError("[group] Failed to spawn %s! teamId: %d  groupId: %s  groupTeamId: %d", hPlayer:GetName(), self.game:GetTeam(hPlayer.id), tostring(iGroup), self.game:GetTeam(iGroup or NULL_ENTITY))
                if (hPlayer:GetTeam() == TEAM_NEUTRAL and self.IS_PS) then
                    return self.Server.RequestSpectatorTarget(self, hPlayer.id, 0)
                else
                    return false
                end
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
                ServerLogError("[result] Failed to spawn %s! teamId: %d  groupId: %s  groupTeamId: %d", hPlayer:GetName(), hPlayer:GetTeam(), tostring(iGroup), self.game:GetTeam(iGroup or NULL_ENTITY))
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
    --- EquipPlayer
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

            Script.SetTimer(25, function()
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
            end)
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

            ServerItemHandler:OnBeforeKilled(hShooter, hTarget, aHitInfo)

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

            ServerItemHandler:OnPlayerKilled(hShooter, hTarget, aHitInfo)
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

            local bSuicide    = (not hShooter or hShooter == hTarget)
            local aKillConfig = self.KillConfig

            local iSuicideKills   = aKillConfig.SuicideKills --ConfigGet("General.GameRules.HitConfig.DeductSuicideKills", 0,  eConfigGet_Number)
            local iSuicideDeaths  = aKillConfig.SuicideDeaths --ConfigGet("General.GameRules.HitConfig.SuicideAddDeaths", 1,    eConfigGet_Number)
            local iTeamKillReward = aKillConfig.TeamKill --ConfigGet("General.GameRules.HitConfig.DeductTeamKill", 1,      eConfigGet_Number)
            local bRemoveBotScore = aKillConfig.BotScore --ConfigGet("General.GameRules.HitConfig.DeductBotKills", false,  eConfigGet_Boolean)


            if (hTarget.IsPlayer) then

                if (bSuicide) then
                    iKillType = eKillType_Suicide
                    hTarget:SetKills(hTarget:GetKills() + (iSuicideKills + 1))
                    hTarget:SetDeaths(hTarget:GetDeaths() + (iSuicideDeaths))

                elseif (hShooter.IsPlayer) then

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
                if (hShooter.IsPlayer) then

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

            if (hShooter and hShooter.IsPlayer and (iKillType ~= eKillType_Suicide) and not aHitInfo.explosion) then

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

            aHitInfo.kill_type = iKillType

            Debug("iKillType=",iKillType)
            if (iKillType == eKillType_Enemy) then-- or (hShooter.IsPlayer and hShooter:IsTesting())) then
               -- Debug("fb?")
                local aFPConfig = self.FirstBlood
                local iTeam = g_pGame:GetTeam(hShooter.id)

               -- Debug("a1=",aFPConfig.Shooters[iTeam],"a2=",aFPConfig.Enabled)
                if (aFPConfig.Shooters[iTeam] == nil and aFPConfig.Enabled) then
                    aFPConfig.Shooters[iTeam] = timernew()

                    local iRewardPP = aFPConfig.Reward
                    local iRewardCP = aFPConfig.RewardCP or 10
                    SendMsg(CHAT_SERVER_LOCALE, ALL, "@l_ui_firstBlood", hShooter:GetName(), GetTeamName(iTeam), iRewardPP, iRewardCP)
                   -- Debug("first blood for team ", GetTeamName(iTeam))
                end
            end

            if (aKillConfig.NewMessages) then
                self:SvSendKillMessage(aHitInfo)
            end


            if (hShooter ~= hTarget and hShooter.IsPlayer and hTarget and hWeapon and hWeapon.class == "DSG1" and self.class == "PowerStruggle") then
                local iDist = vector.distance(hTarget:GetPos(), hShooter:GetPos())
                if (iDist > 100) then
                    local iReward = math.floor((iDist / 100) + 0.5) * 100 * (bHeadshot and 2.5 or 1)
                    self:AwardPPCount(hShooter.id, iReward, nil, hShooter:HasClientMod())

                    local sMsg = string.format("SNIPER-KILL :: %0.2fm, ( + %d PP )", iDist, iReward)
                    SendMsg(MSG_CENTER, hShooter, sMsg)
                    hShooter:SendBLE(eBLE_Information, sMsg)
                end

            end
        end
    },

    ---------------------------------------------
    --- CheckDefenseKill
    ---------------------------------------------
    {

        Class = "g_gameRules",
        Target = { "CheckDefenseKill" },
        Type = eInjection_Replace,

        ------------------------
        Function = function(self, aHitInfo)

            -- check if inside a factory
            local hTarget   = aHitInfo.target
            local hShooter  = aHitInfo.shooter

            local bDefense = false
            local sType    = nil

            if (hTarget ~= hShooter) then
                local iTeam1 = self.game:GetTeam(hShooter.id)
                local iTeam2 = self.game:GetTeam(hTarget.id)
                for _, hFactory in pairs(self.factories) do
                    local iFactoryTeam = self.game:GetTeam(hFactory.id)
                    if (hFactory:IsPlayerInside(aHitInfo.targetId) and (iFactoryTeam ~= iTeam2) and (iFactoryTeam == iTeam1)) then
                        bDefense = true
                        sType    = hFactory.LocaleType
                    end
                end
            end

            return bDefense, sType
        end

    },

    ---------------------------------------------
    --- CalcKillPP
    ---------------------------------------------
    {

        Class = "g_gameRules",
        Target = { "CalcKillPP" },
        Type = eInjection_Replace,

        ------------------------
        Function = function(self, aHitInfo)
            local target = aHitInfo.target
            local shooter = aHitInfo.shooter
            local headshot = self:IsHeadShot(aHitInfo)
            local melee = aHitInfo.type=="melee"

            if (target ~= shooter) then
                local team1 = self.game:GetTeam(shooter.id)
                local team2 = self.game:GetTeam(target.id)
                if (team1 == 0 or team1 ~= team2) then
                    local ownRank = self:GetPlayerRank(shooter.id)
                    local enemyRank = self:GetPlayerRank(target.id)
                    local bonus = 0

                    if (headshot) then
                        bonus = bonus + self.ppList.HEADSHOT
                    end

                    if (melee) then
                        bonus = bonus + self.ppList.MELEE
                    end

                    local rankDiff = enemyRank-ownRank
                    if (rankDiff ~= 0) then
                        bonus = bonus + rankDiff * self.ppList.KILL_RANKDIFF_MULT
                    end

                    -- check if inside a factory
                    local bFactoryDefended = false
                    for _, hFactory in pairs(self.factories) do
                        local factoryTeamId = self.game:GetTeam(hFactory.id);
                        if (hFactory:IsPlayerInside(aHitInfo.targetId) and (factoryTeamId ~= team2) and (factoryTeamId == team1)) then
                            bonus = (bonus + self.defenseValue[hFactory:GetCaptureIndex() or 0] or 0)
                            bFactoryDefended = true
                        end
                    end

                    local iPremiumBonus = ConfigGet("General.GameRules.PremiumKillPP", 1.25, eConfigGet_Number)
                    return math.max(0, (self.ppList.KILL + bonus) * iPremiumBonus)
                else
                    return self.ppList.TEAMKILL
                end
            else
                return self.ppList.SUICIDE
            end
        end

    },

    ---------------------------------------------
    --- ProcessScores
    ---------------------------------------------
    {

        Class = "g_gameRules",
        Target = { "ProcessScores" },
        Type = eInjection_Replace,

        ------------------------
        Function = function(self, aHitInfo)
            local target = aHitInfo.target
            local shooter = aHitInfo.shooter
            local headshot = self:IsHeadShot(aHitInfo)

            local h=0;
            if (headshot) then
                h=1;
            end

            if (target.actor and target.actor:IsPlayer()) then
                self:Award(target, 1, 0, 0)
            end

            if (shooter and shooter.actor and shooter.actor:IsPlayer()) then
                if (target ~= shooter) then

                    if (self.IS_IA) then
                        self:Award(shooter, 0, 1, h)
                    else
                        local team1=self.game:GetTeam(shooter.id);
                        local team2=self.game:GetTeam(target.id);

                        if (team1 == 0 or team1~=team2) then
                            self:Award(shooter, 0, 1, h);

                            -- update team score
                            self:SetTeamScore(team1, self:GetTeamScore(team1)+1);
                        else
                            self:Award(shooter, 0, -1, 0);--teamkill
                            self:OnTeamKill(shooter.id);
                        end
                    end
                else
                    self:Award(shooter, 0, -1, 0)
                end
            end



            if (self.IS_PS) then
                if (shooter and shooter.actor and shooter.actor:IsPlayer()) then
                    self:AwardKillPP(aHitInfo)
                    self:AwardKillCP(aHitInfo)

                    local bDefense, sType = self:CheckDefenseKill(aHitInfo)
                    if (bDefense) then
                        for _, hPlayer in pairs(GetPlayers({ TeamID = shooter:GetTeam() })) do
                            if (hPlayer.id ~= shooter.id) then
                                hPlayer:Execute(string.format("g_Client.Event(eEvent_BLE, eBLE_Information,\"%s\")", hPlayer:LocalizeNest("@l_ui_factoryDefended", { shooter:GetName(), sType })))
                            end
                        end
                        Debug("mdfkn Defense")
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
        Target = { "AwardKillPP" },
        Type = eInjection_Replace,

        ------------------------
        Function = function(self, aHitInfo)

            local hPlayer = aHitInfo.shooter
            if (not hPlayer or not hPlayer.IsPlayer) then
                return
            end

            local iPP = self:CalcKillPP(aHitInfo)
            local hPlayerID = hPlayer.id

            local sType = "@l_ui_enemy @l_ui_eliminated"
            if (aHitInfo.shooterId == aHitInfo.targetId) then
                sType = "@l_ui_suicide"
            elseif (self:CheckDefenseKill(aHitInfo)) then
                sType = "@l_ui_factoryDefense"
            end

            if (iPP > 0) then
                self:AwardPPCount(hPlayerID, iPP, nil, hPlayer:HasClientMod())
                hPlayer:Execute(string.format([[ClientEvent(eEvent_BLE,eBLE_Currency,"%s ( +%d PP )")]],
                        hPlayer:LocalizeNest(sType .. " "),
                        iPP
                ))
            end

            if (iPP < 0) then -- negative points are assumed to be a teamkill here
                local revive = self.reviveQueue[hPlayerID]
                if (revive) then
                    revive.tk = true
                end
            end
        end

    },

    ---------------------------------------------
    --- OnShoot
    ---------------------------------------------
    {

        Class = "g_gameRules",
        Target = { "ProcessVehicleScores" },
        Type = eInjection_Replace,

        ------------------------
        Function = function(self, aHitInfo)
            local target = aHitInfo.target
            local shooter = aHitInfo.shooter

            if (shooter and shooter.actor) then
                local vTeam = self.game:GetTeam(target.id)
                local sTeam = self.game:GetTeam(aHitInfo.shooterId)

                if ((vTeam~=0) and (vTeam~=sTeam)) then
                    local pp = self.ppList.VEHICLE_KILL_MIN
                    local cp = self.cpList.VEHICLE_KILL_MIN

                    if (target.builtas) then
                        local def = self:GetItemDef(target.builtas)
                        if (def) then
                            pp = math.max(pp, math.floor(def.price*self.ppList.VEHICLE_KILL_MULT))
                            cp = math.max(cp, math.floor(def.price*self.cpList.VEHICLE_KILL_MULT))
                        end
                    end

                    shooter:Execute(string.format([[ClientEvent(eEvent_BLE,eBLE_Currency,"%s ( +%d PP )")]],
                            shooter:LocalizeNest("@l_ui_vehicle @l_ui_eliminated"),
                            pp
                    ))
                    self:AwardPPCount(aHitInfo.shooterId, pp, nil, shooter:HasClientMod())
                    self:AwardCPCount(aHitInfo.shooterId, cp)
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

    ---------------------------------------------
    --- OnTurretHit
    ---------------------------------------------
    {
        Class = "g_gameRules",
        Target = { "Server.OnTurretHit" },
        Type = eInjection_Replace,
        ------------------------
        Function = function(self, hTurret, aHitInfo)

            local hShooter = aHitInfo.shooter
            if (hShooter and hShooter.IsPlayer and hShooter:IsTesting()) then
                aHitInfo.damage = 99999
                hTurret.item:OnHit(aHitInfo)
                Debug("ded")
            end

            if (hTurret and self:GetState() == "InGame") then
                local teamId = (self.game:GetTeam(hTurret.id) or 0)
                hTurret.LastHitTimer = timernew()

                if (teamId ~= 0) then
                    if (_time - self.lastTurretHit[teamId] >= 5) then
                        self.lastTurretHit[teamId] = _time
                        local players = self.game:GetTeamPlayers(teamId, true)
                        if (players) then
                            for i, p in pairs(players) do
                                local channel = p.actor:GetChannel()
                                if (channel > 0) then
                                    self.onClient:ClTurretHit(channel, hTurret.id)
                                    if (hTurret.item:IsDestroyed()) then
                                        self.onClient:ClTurretDestroyed(channel, hTurret.id)
                                    end
                                end
                            end
                        end
                    end

                    if (hShooter and hShooter.IsPlayer and (teamId == 0 or (teamId ~= self.game:GetTeam(aHitInfo.shooterId))) and hTurret.item:IsDestroyed()) then

                        local iPP = self.ppList.TURRETKILL
                        hShooter:Execute(string.format([[ClientEvent(eEvent_BLE,eBLE_Currency,"%s ( +%d PP )")]],
                            hShooter:LocalizeNest("@l_ui_turret @l_ui_eliminated"),
                            iPP
                        ))
                        self:AwardPPCount(aHitInfo.shooterId, iPP, nil, hShooter:HasClientMod())
                        self:AwardCPCount(aHitInfo.shooterId, self.cpList.TURRETKILL)
                        hTurret.DestroyedTimer = timernew()

                    end
                end
            end
        end
    },

    ---------------------------------------------
    --- CanHackTurret
    ---------------------------------------------
    {
        Class = "g_gameRules",
        Target = { "CanHackTurret" },
        Type = eInjection_Replace,
        ------------------------
        Function = function(self, hEntity, hPlayerID)

            if (((hEntity.class == "AutoTurret") or (hEntity.class == "AutoTurretAA"))) then
                local turretTeam = g_pGame:GetTeam(hEntity.id)
                local playerTeam = g_pGame:GetTeam(hPlayerID)
                return turretTeam ~= 0 and turretTeam ~= playerTeam
            end
        end
    },

    ---------------------------------------------
    --- CanRepairTurret
    ---------------------------------------------
    {
        Class = "g_gameRules",
        Target = { "CanRepairTurret" },
        Type = eInjection_Replace,
        ------------------------
        Function = function(self, hEntity, hPlayerID)
            if (((hEntity.class == "AutoTurret") or (hEntity.class == "AutoTurretAA"))) then
                local health = hEntity.item:GetHealth()
                local maxhealth = hEntity.item:GetMaxHealth()
                if ((health < maxhealth)) then
                    return true
                end
            end
        end
    },

    ---------------------------------------------
    --- CanRepairHQ
    ---------------------------------------------
    {
        Class = "g_gameRules",
        Target = { "CanRepairHQ" },
        Type = eInjection_Replace,
        ------------------------
        Function = function(self, hEntity, hPlayerID)
            local iRepairable = hEntity.Properties.nHitPoints - hEntity:GetHealth()
            if (self.game:IsSameTeam(hEntity.id, hPlayerID)) then
                if ((iRepairable > 0) and (not hEntity.HQDestroyed)) then
                    return true
                end
            end
        end
    },

    ---------------------------------------------
    --- CanRepairTurret
    ---------------------------------------------
    {
        Class = "g_gameRules",
        Target = { "CanLockpickVehicle" },
        Type = eInjection_Replace,
        ------------------------
        Function = function(self, hEntity, hPlayerID)
            if ((not self.game:IsSameTeam(hEntity.id, hPlayerID)) and (not self.game:IsNeutral(hEntity.id))) then
                local v = hEntity.vehicle

                -- FIXME: COnfig
                if ((v:IsEmpty() or true) and (not v:IsDestroyed())) then
                    return true
                end
            end
        end
    },

    ---------------------------------------------
    --- CanRepairTurret
    ---------------------------------------------
    {
        Class = "g_gameRules",
        Target = { "CanRepairVehicle" },
        Type = eInjection_Replace,
        ------------------------
        Function = function(self, hEntity, hEntityID, hPlayerID)
            local dmgratio = hEntity.vehicle:GetRepairableDamage()
            if (self.game:IsSameTeam(hEntityID, hPlayerID) or self.game:IsNeutral(hEntityID)) then
                if ((dmgratio>0) and (not hEntity.vehicle:IsSubmerged())) then
                    return true
                end
            end
        end
    },

    ---------------------------------------------
    --- IsTurret
    ---------------------------------------------
    {
        Class = "g_gameRules",
        Target = { "IsTurret" },
        Type = eInjection_Replace,
        ------------------------
        Function = function(self, hID)
            local hEntity = GetEntity(hID) or {class = hID}

            local sClass = hEntity.class
            Debug("sClass",sClass)
            return (sClass == "AutoTurret" or sClass == "AutoTurretAA")
        end
    },

    ---------------------------------------------
    --- OnTurretRepaired
    ---------------------------------------------
    {
        Class = "g_gameRules",
        Target = { "OnTurretRepaired" },
        Type = eInjection_Replace,
        ------------------------
        Function = function(self, player, turret)

            local iReward = ConfigGet("General.GameRules.TurretConfig.RepairReward", 100, eConfigGet_Number)
            if (ConfigGet("General.GameRules.TurretConfig.HitPointBasedReward", false, eConfigGet_Boolean)) then
                iReward = player.LastWorkCount or 10
            end

            Debug("iReward",iReward)
            if (iReward > 0) then
                self:AwardPPCount(player.id, iReward, nil, player:HasClientMod())
                player:Execute(string.format(
                        [[ClientEvent(eEvent_BLE,eBLE_Currency,"%s ( +%d PP )")]],
                        player:LocalizeNest("@l_ui_turret @l_ui_repaired"),
                        iReward
                ))
            end
        end
    },

    ---------------------------------------------
    --- CanRepairTurret
    ---------------------------------------------
    {
        Class = "g_gameRules",
        Target = { "CanRepairTurret" },
        Type = eInjection_Replace,
        ------------------------
        Function = function(self, hEntity, hPlayerID, sType)

            if (((hEntity.class == "AutoTurret") or (hEntity.class == "AutoTurretAA"))) then
                local iHP = hEntity.item:GetHealth()
                local iMaxHP = hEntity.item:GetMaxHealth()
                if ((iHP < iMaxHP)) then
                    return true
                end
            end
        end
    },

    ---------------------------------------------
    --- HackTurret
    ---------------------------------------------
    {
        Class = "g_gameRules",
        Target = { "HackTurret" },
        Type = eInjection_Replace,
        ------------------------
        Function = function(self, player, turret, work, workamount)

            --todo
        end
    },

    ---------------------------------------------
    --- Work
    ---------------------------------------------
    {

        Class = "g_gameRules",
        Target = { "Work" },
        Type = eInjection_Replace,

        ------------------------
        Function = function(self, playerId, amount, frameTime)

            local work = self.works[playerId]
            if (work and work.active) then
                --Log("%s doing '%s' work on %s for %.3fs...", EntityName(playerId), work.type, EntityName(work.entityId), frameTime);

                local entity = System.GetEntity(work.entityId)
                local player = System.GetEntity(playerId)
                if (entity) then
                    local workamount = amount * frameTime
                    if (player:IsTesting()) then
                        workamount = workamount * 100
                    end

                    local iMult = entity.RepairSpeedMult
                    if (iMult) then
                        workamount = (workamount * iMult)
                    end

                    player.LastWorkCount = (player.LastWorkCount + workamount)

                    if (work.type == "repair") then
                        if (entity.actor) then
                            return self:RebootSuit(GetEnt(playerId), entity, work, workamount)
                        end

                        if (not self.repairHit) then
                            self.repairHit = {
                                typeId	    = self.game:GetHitTypeId("repair"),
                                type		= "repair",
                                material    = 0,
                                materialId  = 0,
                                dir			= g_Vectors.up,
                                radius	    = 0,
                                partId	    = -1,
                            }
                        end

                        local hit = self.repairHit
                        hit.shooter     = System.GetEntity(playerId)
                        hit.shooterId   = playerId
                        hit.target      = entity
                        hit.targetId    = work.entityId
                        hit.pos         = entity:GetWorldPos(hit.pos)
                        hit.damage      = workamount
                        work.amount     = work.amount+workamount

                        if (entity.vehicle) then
                            entity.Server.OnHit(entity, hit)
                            work.complete = entity.vehicle:GetRepairableDamage() <= 0 -- keep working?

                            local progress = math.floor(0.5+(1.0-entity.vehicle:GetRepairableDamage())*100)
                            self.onClient:ClStepWorking(self.game:GetChannelId(playerId), progress)
                            return (not work.complete)

                        elseif (entity.item and (entity.class == "AutoTurret" or entity.class == "AutoTurretAA") ) then
                            entity.Server.OnHit(entity, hit);
                            work.complete=entity.item:GetHealth()>=entity.item:GetMaxHealth();

                            local progress=math.floor(0.5+(100*entity.item:GetHealth()/entity.item:GetMaxHealth()));
                            self.onClient:ClStepWorking(self.game:GetChannelId(playerId), progress);
                            return (not work.complete)

                        elseif (entity.class == "HQ") then

                            workamount = 0.5
                            if (player and player.megaGod) then
                                workamount = workamount * 100
                            end
                            hit.damage = workamount
                            work.amount = work.amount+workamount

                            player.HQRepairAmount = (player.HQRepairAmount or 0) + (hit.damage * 0.1)
                            entity:SetHealth(entity:GetHealth() + hit.damage)
                            work.complete = entity:GetHealth() >= entity.Properties.nHitPoints

                            local progress = math.floor(0.5+(100*entity:GetHealth()/entity.Properties.nHitPoints))
                            self.onClient:ClStepWorking(self.game:GetChannelId(playerId), progress)

                            return (not work.complete)
                        end
                    elseif (work.type=="lockpick") then
                        if (entity.actor) then
                            return self:RebootSuit(GetEntity(playerId), entity, work, workamount)
                        end

                        if (entity.item and self:IsTurret(entity)) then
                            return self:HackTurret(GetEntity(playerId), entity, work, workamount)
                        end

                        if (true) then
                            work.amount = work.amount + workamount
                            if (work.amount > 100) then
                                self.game:SetTeam(self.game:GetTeam(playerId), entity.id)
                                entity.vehicle:SetOwnerId(NULL_ENTITY)
                                work.complete = true
                            end
                        end
                        self.onClient:ClStepWorking(self.game:GetChannelId(playerId), math.floor(work.amount+0.5));
                        return (not work.complete)

                    elseif (work.type == "disarm") then
                        if ((entity.CanDisarm and entity:CanDisarm(playerId)) or (entity.class == "Claymore" or entity.class == "AVMine" or entity.class == "c4explosive")) then
                            work.amount = work.amount+(100/4)*frameTime

                            if (work.amount>100) then
                                work.complete = true
                                if (self.OnExplosiveDisarmed) then
                                    self:OnExplosiveDisarmed(work.entityId, playerId)
                                end
                            end

                            self.onClient:ClStepWorking(self.game:GetChannelId(playerId), math.floor(work.amount+0.5));

                            return (not work.complete);
                        end
                    end
                end
            end

            return false;
        end

    },

    ---------------------------------------------
    --- StopWork
    ---------------------------------------------
    {

        Class = "g_gameRules",
        Target = { "StopWork" },
        Type = eInjection_Replace,

        ------------------------
        Function = function(self, playerId)

            local work = self.works[playerId]
            if (work and work.active) then
                work.active = false

                self.onClient:ClStopWorking(self.game:GetChannelId(playerId), work.entityId, work.complete or false)
                local entity = System.GetEntity(work.entityId)
                local player = System.GetEntity(playerId)


                if (work.complete) then
                    self.allClients:ClWorkComplete(work.entityId, work.type)
                    if (entity and self:IsTurret(entity)) then
                        if (work.type == "repair") then
                            self:OnTurretRepaired(player, entity)
                        else
                            self:OnTurretHacked(player, entity)
                        end
                    end

                    if (work.type == "lockpick") then
                        if (entity.vehicle) then
                            self:AwardVehicleTheftPP(player)
                        end
                    elseif (work.type == "repair") then
                        if (entity.vehicle) then
                            self:AwardVehicleRepairPP(player)
                        end

                        if (entity.class == "HQ") then
                            self:AwardHQRepairPP(player)
                        end
                    end
               end


                if (player) then
                    player.LastWorkCount = nil
                    if (player.LastWorkID and player.LastWorkID ~= work.entityId) then
                        player.HQRepairAmount = 0
                    end

                    player.LastWorkID = work.entityId
                end
            end
        end

    },

    ---------------------------------------------
    --- AwardHQRepairPP
    ---------------------------------------------
    {

        Class = "g_gameRules",
        Target = { "AwardHQRepairPP" },
        Type = eInjection_Replace,

        ------------------------
        Function = function(self, hPlayer)

            --local iReward = ConfigGet("General.GameRules.WorkingConfig.VehicleTheftReward", 50, eConfigGet_Number)
            local iReward = hPlayer.HQRepairAmount
            self:AwardPPCount(hPlayer.id, iReward, nil, hPlayer:HasClientMod())
            hPlayer:Execute(string.format(
                    [[ClientEvent(eEvent_BLE,eBLE_Currency,"%s ( +%d PP )")]],
                    hPlayer:LocalizeNest("@l_ui_hq @l_ui_repaired"),
                    iReward
            ))
        end
    },

    ---------------------------------------------
    --- OnExplosiveDisarmed
    ---------------------------------------------
    {

        Class = "g_gameRules",
        Target = { "OnExplosiveDisarmed" },
        Type = eInjection_Replace,

        ------------------------
        Function = function(self, hEntityID, hPlayerID)

            local hEntity = System.GetEntity(hEntityID)
            local hPlayer = System.GetEntity(hPlayerID)

            -- WHAT IS THIS OMG
            local sClass = hEntity and hEntity.class
            sClass = sClass == "claymoreexplosive" and "Claymore" or
                    sClass == "c4explosive" and "C4" or
                    sClass == "avexplosive" and "AVMine"

            if (hEntity and hPlayer and sClass) then
                hPlayer:GiveItem(sClass)
                hPlayer:SelectItem(sClass)
            end

            hEntity.DISARMED = true
            hEntity.WAS_DISARMED = true

            local iPP = 0
            if (hPlayer:IsTesting() or self.game:GetTeam(hEntityID) ~= self.game:GetTeam(hPlayerID)) then

                -- give the player some PP
                iPP = self.ppList.DISARM
                self:AwardPPCount(hPlayerID, iPP, nil, hPlayer:HasClientMod())
                hPlayer:Execute(string.format(
                        [[ClientEvent(eEvent_BLE,eBLE_Currency,"%s ( +%d PP )")]],
                        hPlayer:LocalizeNest((sClass or "@l_ui_explosive") .. " @l_ui_disarmed"),
                        iPP
                ))
            end

            if (not hPlayer:IsTesting()) then
                Script.SetTimer(1, function()
                    System.RemoveEntity(hEntityID)
                end)
            end
        end
    },

    ---------------------------------------------
    --- StartWork
    ---------------------------------------------
    {

        Class = "g_gameRules",
        Target = { "AwardVehicleTheftPP" },
        Type = eInjection_Replace,

        ------------------------
        Function = function(self, hPlayer)

            local iReward = ConfigGet("General.GameRules.WorkingConfig.VehicleTheftReward", 50, eConfigGet_Number)
            self:AwardPPCount(hPlayer.id, iReward, nil, hPlayer:HasClientMod())
            hPlayer:Execute(string.format(
                    [[ClientEvent(eEvent_BLE,eBLE_Currency,"%s ( +%d PP )")]],
                    hPlayer:LocalizeNest("@l_ui_vehicle @l_ui_stolen"),
                    iReward
            ))
        end
    },

    ---------------------------------------------
    --- StartWork
    ---------------------------------------------
    {

        Class = "g_gameRules",
        Target = { "AwardVehicleRepairPP" },
        Type = eInjection_Replace,

        ------------------------
        Function = function(self, hPlayer)

            local iReward = ConfigGet("General.GameRules.WorkingConfig.VehicleRepairReward", 50, eConfigGet_Number)
            self:AwardPPCount(hPlayer.id, iReward, nil, hPlayer:HasClientMod())
            hPlayer:Execute(string.format(
                    [[ClientEvent(eEvent_BLE,eBLE_Currency,"%s ( +%d PP )")]],
                    hPlayer:LocalizeNest("@l_ui_vehicle @l_ui_repaired"),
                    iReward
            ))
        end

    },

    ---------------------------------------------
    --- StartWork
    ---------------------------------------------
    {

        Class = "g_gameRules",
        Target = { "StartWork" },
        Type = eInjection_Replace,

        ------------------------
        Function = function(self, entityId, playerId, sType)

            local work = self.works[playerId]
            if (not work) then
                work = {}
                self.works[playerId] = work
            end

            work.active     = true
            work.entityId   = entityId
            work.playerId   = playerId
            work.type       = sType
            work.amount     = 0
            work.complete   = nil

            --Log("%s starting '%s' work on %s...", EntityName(playerId), work_type, EntityName(entityId));

            -- HAX
            local entity = System.GetEntity(entityId)
            if (entity) then
                if (entity.CanDisarm and entity:CanDisarm(playerId)) then
                    sType = "disarm"
                    work.type = sType
                end
            end
            local player = System.GetEntity(playerId)
            player.LastWorkCount = 0

            if (entity.actor) then
                self:OnSuitReboot(player, entity)
                if (self.class == "PowerStruggle" and self:IsInReviveQueue(entity.id)) then
                    self:ResetRevive(entity.id)
                    Debug("start reboot, STOP revive")
                end
            else
                self.onClient:ClStartWorking(self.game:GetChannelId(playerId), entityId, sType)
                if (self:IsTurret(entity) and sType == "lockpick") then
                    -- FIXME
                end
            end
        end

    },

    ---------------------------------------------
    --- CanWork
    ---------------------------------------------
    {

        Class = "g_gameRules",
        Target = { "CanWork" },
        Type = eInjection_Replace,

        ------------------------
        Function = function(self, hEntityID, hPlayerID, sType)

            ---------
            local hEntity = GetEntity(hEntityID)
            local hPlayer = GetEntity(hPlayerID)

            if (self.isServer) then
                local work = self.works[hPlayerID]
                if (work) then
                    if (work.active and (work.entityId ~= hEntityID)) then -- disarming explosives will change work.type, but the weapon will keep reporting a different work_type
                        return false
                    end
                end
            end

            if (sType == "repair") then
                if (hEntity.actor) then
                    return self:CanRebootNanosuit(hPlayerID, hEntityID)

                elseif (hEntity.vehicle) then
                    return self:CanRepairVehicle(hEntity, hEntityID, hPlayerID) -- DONE !!

                elseif (hEntity.item) then
                    return self:CanRepairTurret(hEntity, hPlayerID)  -- DONE !!

                elseif (hEntity.CanDisarm and hEntity:CanDisarm(hPlayerID)) then
                    return true

                elseif (hEntity.class == "HQ") then
                    return self:CanRepairHQ(hEntity, hPlayerID)

                end

            elseif (sType == "lockpick") then
                if (hEntity.vehicle) then
                    return self:CanLockpickVehicle(hEntity, hPlayerID)

                elseif (hEntity.item and false) then
                    return self:CanHackTurret(hEntity, hPlayerID)

                end
            end
        end
    },

    ---------------------------------------------
    --- CanEnterVehicle
    ---------------------------------------------
    {

        Class = "g_gameRules",
        Target = { "CanEnterVehicle" },
        Type = eInjection_Replace,

        ------------------------
        Function = function(self, hVehicle, hUserID)

            local hPlayer = GetEntity(hUserID)
            if (not hPlayer) then
                return false
            end

            if (hPlayer:Distance(hVehicle) > 25) then
                return false
            end

            if (hVehicle.vehicle:GetMovementType() == "sea" and not hVehicle.vehicle:IsSubmerged()) then
                local aHitDown = hPlayer:GetHitPos(2, nil, g_Vectors.down, hPlayer:GetPos())
                if (not aHitDown or aHitDown.entity ~= hVehicle) then
                    ServerUtils.AddImpulse(hVehicle, hPlayer:GetDirectionVector(), hVehicle:GetMass() * (hPlayer:GetSuitMode(NANOMODE_STRENGTH) and 5 or 2.5))
                    return false
                end
            end

            if (hVehicle.vehicle:GetOwnerId() == hUserID) then
                return true
            end

            -- Gods can do ANYTHING!
            if (hPlayer:HasGodMode()) then
                return true
            end

            local bCheck       = (hVehicle.SvCanEnter == nil or (hVehicle:SvCanEnter(hPlayer) == true))
            local iVehicleTeam = self.game:GetTeam(hVehicle.id)
            local iPlayerTeam  = self.game:GetTeam(hUserID)

            if (iPlayerTeam == iVehicleTeam or iVehicleTeam == 0) then
                local bOk = (hVehicle.vehicle:GetOwnerId() == nil)
                return (bOk and bCheck)

            elseif (iPlayerTeam ~= iVehicleTeam) then
                return false
            end

            return bCheck
        end

    },

    ---------------------------------------------
    --- OnLeaveVehicleSeat
    ---------------------------------------------
    {

        Class = "g_gameRules",
        Target = { "OnLeaveVehicleSeat" },
        Type = eInjection_Replace,

        ------------------------
        Function = function(self, hVehicle, aSeat, hPlayerID, bExiting)

            ---------
            local hPlayer = System.GetEntity(hPlayerID)
            if (hPlayer) then
                if (bExiting) then
                    hPlayer.ExitVehicleID = hVehicle.id
                    hPlayer.ExitVehicleTimer.refresh()
                    hPlayer:ResetServerFiring()
                    if (aSeat.seat:IsDriver()) then
                        if (hVehicle.HeliMGs) then
                            for _, hMG in pairs(hVehicle.HeliMGs) do
                                hMG.weapon:Sv_ResetFiringInfo()
                            end
                        end
                    end
                end


               -- Debug(">",hVehicle.IsJetVM)
                if (hVehicle.IsJetVM and not hVehicle:GetDriver()) then
                    self.RougeJets[hVehicle.id] = hVehicle
                   -- Debug("lefty")
                end

                if (not hVehicle:GetDriver()) then
                    hVehicle:SetHeliMGOwner(NULL_ENTITY)
                end
            end

            if (self.isServer) then
                if (bExiting) then
                    local empty=true
                    for i,seat in pairs(hVehicle.Seats) do
                        local passengerId = seat:GetPassengerId()
                        if (passengerId and passengerId~=NULL_ENTITY and passengerId~=hPlayerID) then
                            empty=false
                            break
                        end
                    end

                    if (empty) then
                        --self.game:SetTeam(0, vehicle.id);
                        hVehicle.lastOwnerId=hPlayerID
                        if (hPlayer) then
                            hPlayer.lastVehicleId = hVehicle.id
                        end
                    end

                    if(hPlayerID==hVehicle.vehicle:GetOwnerId()) then
                        hVehicle.vehicle:SetOwnerId(NULL_ENTITY)
                    end
                end
            end
        end
    },

    ---------------------------------------------
    --- OnExplosion
    ---------------------------------------------
    {

        Class = "g_gameRules",
        Target = { "OnExplosion" },
        Type = eInjection_Replace,

        ------------------------
        Function = function(self, explosion)
            local entities = explosion.AffectedEntities;
            local entitiesObstruction = explosion.AffectedEntitiesObstruction;

            if (entities) then
                -- calculate damage for each entity
                for i,entity in ipairs(entities) do

                    local incone=true;
                    if (explosion.angle>0 and explosion.angle<2*math.pi) then
                        self.explosion_entity_pos = entity:GetWorldPos(self.explosion_entity_pos);
                        local entitypos = self.explosion_entity_pos;
                        local ha = explosion.angle*0.5;
                        local edir = vecNormalize(vecSub(entitypos, explosion.pos));
                        local dot = 1;

                        if (edir) then
                            dot = vecDot(edir, explosion.dir);
                        end

                        local angle = math.abs(math.acos(dot));
                        if (angle>ha) then
                            incone=false;
                        end
                    end

                    local frozen = self.game:IsFrozen(entity.id);
                    if (incone and (frozen or (entity.Server and entity.Server.OnHit))) then
                        local obstruction=entitiesObstruction[i];
                        local damage=explosion.damage;

                        damage = math.floor(0.5+self:CalcExplosionDamage(entity, explosion, obstruction));

                        local dead = (entity.IsDead and entity:IsDead());

                        local explHit=self.explosionHit;
                        explHit.pos = explosion.pos;
                        explHit.dir = vecNormalize(vecSub(entity:GetWorldPos(), explosion.pos));
                        explHit.radius = explosion.radius;
                        explHit.partId = -1;
                        explHit.target = entity;
                        explHit.targetId = entity.id;
                        explHit.weapon = explosion.weapon;
                        explHit.weaponId = explosion.weaponId;
                        explHit.shooter = explosion.shooter;
                        explHit.shooterId = explosion.shooterId;
                        explHit.materialId = 0;
                        explHit.damage = damage;
                        explHit.typeId = explosion.typeId or 0;
                        explHit.type = explosion.type or "";
                        explHit.explosion = true;
                        explHit.impact = explosion.impact;
                        explHit.impact_targetId = explosion.impact_targetId;

                        local deadly=false;
                        local canShatter = ((not entity.CanShatter) or (tonumber(entity:CanShatter())~=0));

                        if (self.game:IsFrozen(entity.id) and canShatter) then
                            if (damage>15) then
                                local hitpos = entity:GetWorldPos();
                                local hitdir = vecNormalize(vecSub(hitpos, explosion.pos));

                                self:ShatterEntity(entity.id, explHit);
                            end
                        else
                            if (entity.actor and entity.actor:IsPlayer()) then
                                if (self.game:IsInvulnerable(entity.id)) then
                                    explHit.damage=0;
                                end
                            end

                            if ((not dead) and entity.Server and entity.Server.OnHit and entity.Server.OnHit(entity, explHit)) then
                                -- special case for actors
                                -- if more special cases come up, lets move this into the entity
                                if (entity.actor and self.ProcessDeath) then
                                    self:ProcessDeath(explHit);
                                elseif (entity.vehicle and self.ProcessVehicleDeath) then
                                    self:ProcessVehicleDeath(explHit);
                                end

                                deadly=true;
                            end
                        end

                        local debugHits = self.game:DebugHits();

                        if (debugHits>0) then
                            self:LogHit(explHit, debugHits>1, deadly);
                        end
                    end
                end
            end
        end
    },

    ---------------------------------------------
    --- OnCollision
    ---------------------------------------------
    {

        Class = "g_gameRules",
        Target = { "OnCollision" },
        Type = eInjection_Replace,

        ------------------------
        Function = function(self, entity, hit)

            local collider = hit.target;
            local colliderMass = hit.target_mass; -- beware, collider can be null (e.g. entity-less rigid entities)
            local contactVelocitySq;
            local contactMass;

            ServerItemHandler:OnCollision(entity, hit)

            -- check if frozen
            if (self.game:IsFrozen(entity.id)) then
                if ((not entity.CanShatter) or (tonumber(entity:CanShatter())~=0)) then
                    local energy = self:GetCollisionEnergy(entity, hit);

                    local minEnergy = 1000;

                    if (energy >= minEnergy) then
                        if (not collider) then
                            collider=entity;
                        end

                        local colHit = self.collisionHit;
                        colHit.pos = hit.pos;
                        colHit.dir = hit.dir or hit.normal;
                        colHit.radius = 0;
                        colHit.partId = -1;
                        colHit.target = entity;
                        colHit.targetId = entity.id;
                        colHit.weapon = collider;
                        colHit.weaponId = collider.id
                        colHit.shooter = collider;
                        colHit.shooterId = collider.id
                        colHit.materialId = 0;
                        colHit.damage = 0;
                        colHit.typeId = g_collisionHitTypeId;
                        colHit.type = "collision";

                        if (collider.vehicle and collider.GetDriverId) then
                            local driverId = collider:GetDriverId();
                            if (driverId) then
                                colHit.shooterId = driverId;
                                colHit.shooter=System.GetEntity(colHit.shooterId);
                            end
                        end

                        self:ShatterEntity(entity.id, colHit);
                    end

                    return;
                end
            end

            if (not (entity.Server and entity.Server.OnHit)) then
                return;
            end

            if (entity.IsDead and entity:IsDead()) then
                return;
            end

            local minVelocity;

            -- collision with another entity
            if (collider or colliderMass>0) then
                FastDifferenceVectors(self.tempVec, hit.velocity, hit.target_velocity);
                contactVelocitySq = vecLenSq(self.tempVec);
                contactMass = colliderMass;
                minVelocity = self:GetCollisionMinVelocity(entity, collider, hit);
            else	-- collision with world
                contactVelocitySq = vecLenSq(hit.velocity);
                contactMass = entity:GetMass();
                minVelocity = 7.5;
            end

            -- marcok: avoid fp exceptions, not nice but I don't want to mess up any damage calculations below at this stage
            if (contactVelocitySq < 0.01) then
                contactVelocitySq = 0.01;
            end

            local damage = 0;

            -- make sure we're colliding with something worthy
            if (contactMass > 0.01) then
                local minVelocitySq = minVelocity*minVelocity;
                local bigObject = false;
                --this should handle falling trees/rocks (vehicles are more heavy usually)
                if(contactMass > 200.0 and contactMass < 10000 and contactVelocitySq > 2.25) then
                    if(hit.target_velocity and vecLenSq(hit.target_velocity) > (contactVelocitySq * 0.3)) then
                        bigObject = true;
                        --vehicles and doors shouldn't be 'bigObject'-ified
                        if(collider and (collider.vehicle or collider.advancedDoor)) then
                            bigObject = false;
                        end
                    end
                end

                local collideBarbWire = false;
                if(hit.materialId == g_barbWireMaterial and entity and entity.actor) then
                    collideBarbWire = true;
                end

                --Log("velo : %f, mass : %f", contactVelocitySq, contactMass);
                if (contactVelocitySq >= minVelocitySq or bigObject or collideBarbWire) then
                    -- tell AIs about collision
                    if(AI and entity and entity.AI and not entity.AI.Colliding) then
                        g_SignalData.id = hit.target_id;
                        g_SignalData.fValue = contactVelocitySq;
                        AI.Signal(SIGNALFILTER_SENDER,1,"OnCollision",entity.id,g_SignalData);
                        entity.AI.Colliding = true;
                        entity:SetTimer(COLLISION_TIMER,4000);
                    end
                    --

                    -- marcok: Uncomment this stuff when you need it
                    --local debugColl = self.game:DebugCollisionDamage();

                    --if (debugColl>0) then
                    -- Log("------------------------- collision -------------------------");
                    --end

                    local contactVelocity = math.sqrt(contactVelocitySq)-minVelocity;
                    if (contactVelocity < 0.0) then
                        contactVelocitySq = minVelocitySq;
                        contactVelocity = 0.0;
                    end

                    -- damage
                    if(entity.vehicle) then
                        if(not self:IsMultiplayer()) then
                            damage = 0.0005*self:GetCollisionEnergy(entity, hit); -- vehicles get less damage SINGLEPLAYER ONLY.
                        else
                            damage = 0.0002*self:GetCollisionEnergy(entity, hit);	-- keeping the original values for MP.
                        end
                    else
                        damage = 0.0025*self:GetCollisionEnergy(entity, hit);
                    end

                    -- apply damage multipliers
                    damage = damage * self:GetCollisionDamageMult(entity, collider, hit);

                    if(collideBarbWire and entity.id == g_localActorId) then
                        damage = damage * (contactMass * 0.15) * (30.0 / contactVelocitySq);
                    end

                    if(bigObject) then
                        if (damage > 0.5) then
                            damage = damage * (contactMass / 10.0) * (10.0 / contactVelocitySq);
                            if(entity.id ~= g_localActorId) then
                                damage = damage * 3;
                            end
                        else
                            return;
                        end
                    end

                    -- subtract collision damage threshold, if available
                    if (entity.GetCollisionDamageThreshold) then
                        local old = damage;
                        damage = __max(0, damage - entity:GetCollisionDamageThreshold());
                    end

                    if (entity.actor) then
                        if(entity.actor:IsPlayer()) then
                            if(hit.target_velocity and vecLen(hit.target_velocity) == 0) then --limit damage from running agains static objects
                                damage = damage * 0.2;
                            end
                        end

                        if(collider and collider.class=="AdvancedDoor")then
                            if(collider:GetState()=="Opened")then
                                entity:KnockedOutByDoor(hit,contactMass,contactVelocity);
                            end
                        end;

                        if (collider and not collider.actor) then
                            local contactVelocityCollider = __max(0, vecLen(hit.target_velocity)-minVelocity);
                            local killVelocity = (entity.collisionKillVelocity or 20.0);

                            if(contactVelocity > killVelocity and contactVelocityCollider > killVelocity and colliderMass > 50 and not entity.actor:IsPlayer()) then
                                local bNoDeath = entity.Properties.Damage.bNoDeath;
                                local bFall = bNoDeath and bNoDeath~=0;

                                -- don't allow killing friendly AIs by collisions
                                if(not AI.Hostile(entity.id, g_localActorId, false)) then
                                    return;
                                end


                                --if (debugColl~=0) then
                                --  Log("%s for <%s>, collider <%s>, contactVel %.1f, contactVelCollider %.1f, colliderMass %.1f", bFall and "FALL" or "KILL", entity:GetName(), collider:GetName(), contactVelocity, contactVelocityCollider, colliderMass);
                                --end

                                if(bFall) then
                                    entity.actor:Fall(hit.pos);
                                else
                                    entity:Kill(true, NULL_ENTITY, NULL_ENTITY);
                                end
                            else
                                if(g_localActorId and AI.Hostile(entity.id, g_localActorId, false)) then
                                    if(not entity.isAlien and contactVelocity > 5.0 and contactMass > 10.0 and not entity.actor:IsPlayer()) then
                                        if(damage < 50) then
                                            damage = 50;
                                            entity.actor:Fall(hit.pos);
                                        end
                                    else
                                        if(not entity.isAlien and contactMass > 2.0 and contactVelocity > 15.0 and not entity.actor:IsPlayer()) then
                                            if(damage < 50) then
                                                damage = 50;
                                                entity.actor:Fall(hit.pos);
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end


                    if (damage >= 0.5) then
                        if (not collider) then collider = entity; end;

                        --prevent deadly collision damage (old system somehow failed)
                        if(entity.actor and not self:IsMultiplayer() and not AI.Hostile(entity.id, g_localActorId, false)) then
                            if(entity.id ~= g_localActorId) then
                                if(entity.actor:GetHealth() <= damage) then
                                    entity.actor:Fall(hit.pos);
                                    return;
                                end
                            end
                        end

                        local curtime = System.GetCurrTime();
                        if (entity.lastCollDamagerId and entity.lastCollDamagerId==collider.id and
                                entity.lastCollDamageTime+0.3>curtime and damage<entity.lastCollDamage*2) then
                            return
                        end
                        entity.lastCollDamagerId = collider.id;
                        entity.lastCollDamageTime = curtime;
                        entity.lastCollDamage = damage;

                        --if (debugColl>0) then
                        --  Log("[SinglePlayer] <%s>: sending coll damage %.1f", entity:GetName(), damage);
                        --end

                        local colHit = self.collisionHit;
                        colHit.pos = hit.pos;
                        colHit.dir = hit.dir or hit.normal;
                        colHit.radius = 0;
                        colHit.partId = -1;
                        colHit.target = entity;
                        colHit.targetId = entity.id;
                        colHit.weapon = collider;
                        colHit.weaponId = collider.id
                        colHit.shooter = collider;
                        colHit.shooterId = collider.id
                        colHit.materialId = 0;
                        colHit.damage = damage;
                        colHit.typeId = g_collisionHitTypeId;
                        colHit.type = "collision";
                        colHit.impulse=hit.impulse;

                        if (collider.vehicle and collider.GetDriverId) then
                            local driverId = collider:GetDriverId();
                            if (driverId) then
                                colHit.shooterId = driverId;
                                colHit.shooter=System.GetEntity(colHit.shooterId);
                            end
                        end

                        local deadly=false;

                        if (entity.Server.OnHit(entity, colHit)) then
                            -- special case for actors
                            -- if more special cases come up, lets move this into the entity
                            if (entity.actor and self.ProcessDeath) then
                                self:ProcessDeath(colHit);
                            elseif (entity.vehicle and self.ProcessVehicleDeath) then
                                self:ProcessVehicleDeath(colHit);
                            end

                            deadly=true;
                        end

                        local debugHits = self.game:DebugHits();

                        if (debugHits>0) then
                            self:LogHit(colHit, debugHits>1, deadly);
                        end
                    end
                end
            end
        end
    },
}

------------
ServerInjector.InjectAll(ServerGameRules)