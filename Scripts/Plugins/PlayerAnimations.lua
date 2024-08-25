CreatePlugin("PlayerAnimations", {

    Animations = {
            KickDeadBody = {
                Use = true,
                {
                    Rifle = { "combat_deadBodyKick_rifle_01", "combat_deadBodyKick_rifle_02", "combat_deadBodyKick_rifle_03" },
                },
            },
            Prone = {
                Use = true,
                {
                    --Sniper = { "" },
                    Pistol = { "prone_idle_pistol_01", "prone_idle_pistol_02", "prone_idle_pistol_03", "prone_idle_pistol_04" }, -- SOCOM
                    Rifle = { "prone_idle_rifle_01", "prone_idle_rifle_02", "prone_idle_rifle_03" }, -- Rifle
                    Fist = { "prone_idle_nw_01", "prone_idle_nw_02", "prone_idle_nw_03", "prone_idle_nw_04" } -- Fists
                }, -- = [1]
            },
            Stand = {
                Use = true,
                {
                    Minigun = { "combat_idle_mg_01", "combat_idle_mg_02", "combat_idle_mg_03", "combat_idle_mg_04" }, -- Minigun
                    Sniper = { "combat_sniperIdle_rifle_01", "combat_guard_rifle_01" }, -- Sniper
                    Pistol = {"combat_idle_nw_02","combat_idle_nw_01", "combat_idle_pistol_01", --[["combat_idle_pistol_02",]] "combat_idle_pistol_03", "combat_idle_pistol_04" }, -- SOCOM
                    Rifle = {"combat_idle_nw_02","combat_idle_nw_01", "combat_idle_rifle_01", "combat_idle_rifle_02", "combat_idle_rifle_03", "combat_idle_rifle_04", "combat_guard_rifle_01" }, -- Rifle
                    Rocket = { "combat_idleAimBlockPoses_rocket_01" },

                    Leaning = {
                        Fist = {
                            Left = { "combat_peekIdle_nw_left_01" },
                            Right = { "combat_peekIdle_nw_right_01" },
                        };
                        Rifle = {
                            Left = { "combat_peekIdle_rifle_left_01" },
                            Right = { "combat_peekIdle_rifle_right_01" },
                        };
                        Pistol = {
                            Left = { "combat_peekIdle_pistol_left_01" },
                            Right = { "combat_peekIdle_pistol_right_01" },
                        };

                    };
                    --Fist = { "" } -- Fists -- Now 'Idle' category
                }, -- = [1]
            },
            Crouch = {
                Use = true,
                {

                    Cloaked = {
                        Minigun = { "stealth_idle_mg_01", "stealth_idle_mg_02", "stealth_idle_mg_03", "stealth_idle_mg_04" },
                        Fist = { "stealth_idle_nw_01", "stealth_idle_nw_02", "stealth_idle_nw_03", "stealth_idle_nw_04" },
                        Pistol = { "stealth_idle_pistol_01", "stealth_idle_pistol_02", "stealth_idle_pistol_03", "stealth_idle_pistol_04" },
                        Rifle = { "stealth_idle_rifle_01", "stealth_idle_rifle_02", "stealth_idle_rifle_03", "stealth_idle_rifle_04" },
                    },
                    Minigun = { "stealth_idle_mg_01", "stealth_idle_mg_02", "stealth_idle_mg_03", "stealth_idle_mg_04", --[[!!!!]] "crouch_idle_mg_01", "crouch_idle_mg_02", "crouch_idle_mg_03", "crouch_idle_mg_04" }, -- Minigun
                    --Sniper = { "combat_sniperIdle_rifle_01" }, -- Sniper
                    Pistol = {"crouch_idleKnee_nw_03", "crouch_idleKnee_nw_04", "stealth_idle_pistol_01", "stealth_idle_pistol_02", "stealth_idle_pistol_03", "stealth_idle_pistol_04", --[[!!!!]] "crouch_idle_pistol_01", "crouch_idle_pistol_02", "crouch_idle_pistol_03", "crouch_idleKnee_pistol_01", "crouch_idleKnee_pistol_02", "crouch_idleKnee_pistol_03" }, -- SOCOM
                    Rifle = { "stealth_idle_rifle_01", "stealth_idle_rifle_02", "stealth_idle_rifle_03", "stealth_idle_rifle_04", --[[!!!!]]"crouch_listening_rifle_01", "crouch_talk_rifle_01", "crouch_idle_rifle_01", "crouch_idle_rifle_02", "crouch_idle_rifle_03", "crouch_idle_rifle_04", "crouch_idleKnee_rifle_01", "crouch_idleKnee_rifle_02", "crouch_idleKnee_rifle_03", "crouch_idleKnee_rifle_04" }, -- Rifle
                    Fist = { "stealth_idle_nw_01", "stealth_idle_nw_02", "stealth_idle_nw_03", "stealth_idle_nw_04", --[[!!!!]] "crouch_idle_nw_01", "crouch_idle_nw_02", "crouch_idle_nw_03", "crouch_idle_nw_04", "crouch_idleKnee_nw_02", "crouch_idleKnee_nw_03", "crouch_idleKnee_nw_04" } ,-- Fists

                    Rocket = { "crouch_idleKnee_rocket_01" },

                    -- "crouch_idleKnee_nw_01", "crouch_idleKnee_nw_03", "crouch_idleKnee_nw_04",

                    Leaning = {
                        Fist = {
                            Left = { "crouch_peekIdle_nw_left_01" },
                            Right = { "crouch_peekIdle_nw_right_01" },
                        };
                        Rifle = {
                            Left = { "crouch_peekIdle_rifle_left_01" },
                            Right = { "crouch_peekIdle_rifle_right_01" },
                        };
                        Pistol = {
                            Left = { "crouch_peekIdle_pistol_left_01" },
                            Right = { "crouch_peekIdle_pistol_right_01" },
                        };

                    };
                }, -- = [1]
            },
            Air = { -- !!WIP
                Use = true,
                {
                    Fly = { "" },
                    Fall = {
                        Ground = { "parachute_diveHeadUp_nw_01" }, -- over ground
                        Water = { "parachute_fallWater_nw_01" }, -- over water
                    },
                    FreeFall = {
                        Close = { "parachute_signalBackOff_nw_01" }, -- if close to ground
                        Far = {
                            Ground = { "parachute_diveHeadUp_nw_01" }, -- over ground
                            Water = { "parachute_fallWater_nw_01" }, -- over water
                        }, -- if far away from ground
                    },
                    Parachute = { "" },
                }, -- = [1]
            },
            Stagger = { -- !!WIP
                Use = true,
                {
                    Stand = {
                        Fist = { "combat_fearFront_nw_01", "combat_fearFront_nw_02" },
                        Rifle = { "combat_fearFront_rifle_01", "combat_fearFront_rifle_02", "combat_flinch_rifle_01" },
                        Pistol = { "combat_fearFront_pistol_01", "combat_fearFront_pistol_02" },
                    },
                    Crouch = {
                        Cloaked = {
                            Rifle = { "stealth_flinch_rifle_01" },
                        },
                        --Fist = { "combat_fearFront_nw_01", "combat_fearFront_nw_02" },
                        Rifle = { "stealth_flinch_rifle_01", "crouch_flinch_rifle_01", "crouch_flinch_rifle_02", "combat_flinch_rifle_01" },
                        --Pistol = { "combat_fearFront_pistol_01", "combat_fearFront_pistol_02" },
                    },
                    --Prone = {
                    --	Fist = { "combat_fearFront_nw_01", "combat_fearFront_nw_02" },
                    --	Rifle = { "combat_fearFront_rifle_01", "combat_fearFront_rifle_02", "combat_flinch_rifle_01" },
                    --	Pistol = { "combat_fearFront_pistol_01", "combat_fearFront_pistol_02" },
                    --},
                }, -- = [1]
            },
            Vehicle = {
                Use = true,
                {
                    Repair = { -- if player is facing a damaged vehicle
                        Stand = { "relaxed_cleaningBoatArgument_01", "relaxed_cleaningBoatLoop_01", "relaxed_repairGeneric_hammer_01", "relaxed_repairGeneric_hammer_02", "relaxed_repairGeneric_screwdriver_01", },
                        Crouch = { "relaxed_repairGenericCrouch_hammer_01", "relaxed_repairGenericCrouch_screwdriver_01", "relaxed_repairGenericCrouch_screwdriver_02", "relaxed_repairGenericCrouch_screwdriver_03", },
                    },
                    Inside = {

                    },
                },
            },
            Idle = {
                Use = true,
                {
                    --Sniper = { "" }, -- Sniper
                    --Pistol = { "" }, -- SOCOM
                    --Rifle = { "" }, -- Rifle
                    --Fist = { "" } -- Fists
                    Leaning = {
                        "relaxed_idleFootOnWallLoop_nw_01",
                        --	"relaxed_idleFootOnWallLoop_nw_02" -- too short
                    },
                    Standing = {

                        "combat_idle_nw_02","combat_idle_nw_01",
                        "relaxed_idleCheckingWatch_01",
                        "relaxed_idleChinrub_01", "relaxed_idleChinrub_02", "relaxed_idleChinrub_03",
                        "relaxed_idleClaphands_01",
                        "relaxed_idleDawdling_nw_01",
                        "relaxed_idleDrummingOnLegs_nw_01",
                        "relaxed_idleHeadScratch_01","relaxed_idleHeadScratch_02","relaxed_idleHeadScratch_03","relaxed_idleHeadScratch_04","relaxed_idleHeadScratch_05",
                        "relaxed_idleInsectSwat_leftHand_01","relaxed_idleInsectSwat_leftHand_02",
                        "relaxed_idleKickDust_01","relaxed_idleKickStone_01",
                        "relaxed_idleListening_01","relaxed_idleListening_02","relaxed_idleListening_03",
                        "relaxed_idlePickNose_nw_01",
                        "relaxed_idleRubKnee_01", "relaxed_idleRubNeck_01",
                        "relaxed_idleScratchbutt_01","relaxed_idleScratchNose_nw_01",
                        "relaxed_idleShift_01","relaxed_idleShift_01",
                        "relaxed_idleShoulderShrug_01","relaxed_idleShoulderShrug_02","relaxed_idleShoulderShrug_03",
                        "relaxed_idleSmokeDrag_cigarette_01","relaxed_idleSmokeDrag_cigarette_02",
                        "relaxed_idleTappingFoot_01",
                        "relaxed_idleTeetering_nw_01",
                        "relaxed_idleTieLaces_01",
                        "relaxed_idleYawn_nw_01",
                        "relaxed_readIdle_book_01",
                        --"relaxed_salute_nw_01","relaxed_saluteLazyCO_nw_01",
                        "relaxed_standIdleHandsBehindCOLoop_01",
                        "relaxed_standIdleHandsBehindCOLoop_01", "relaxed_standIdleHandsBehindCOLoop_02",
                        --
                        "usCarrier_lsoWatchingPlanes_nw_01",
                        "usCarrier_flightSignal_nw_13",
                    },
                }, -- = [1]
            },
            HelloAdmin = { -- Used when a player with higher access approches a player with lesser access
                Use = true,
                Anims = {
                    "relaxed_salute_nw_01", "relaxed_saluteLazyCO_nw_01",
                },
            },
            Radio = {
                Use = true,
                {
                    Help = { "combat_callReinforcements_nw_01", "combat_callReinforcements_nw_02" },
                    Other = { "combat_idleFranticRadio_rifle_01", "combat_idleFranticRadio_rifle_02", "cineFleet_manTalkingOnCBFranticLoop_radioHandset_01"},
                    Follow = {
                        Rifle = { "stealth_signalFollowUB_rifle_01", "cineSphere_ab3_MarineWavesIntoVTOLLoop_01", },
                        Pistol = { "stealth_signalFollowUB_pistol_01", "cineSphere_ab3_MarineWavesIntoVTOLLoop_01" },
                    };
                },
            },
            Weapons = {
                Use = true,
                {
                    DSG1 = { "combat_sniperFire_rifle_01" },
                },
            },
        },

    Links = {
        [eServerEvent_ScriptTick]   = "UpdateAll",
        [eServerEvent_OnClientInit] = "InitClient"
    },

    ---------------------
    Init = function(self)
    end,

    ---------------------
    InitClient = function(self, hClient)

        hClient.IdleInfo = {

            SaluteInfo = {},

            CanStartNewAnim = function(this) return (this.AnimationTime == nil or this.AnimationTimer.expired(this.AnimationTime)) end,
            SetPackID       = function(this, pack) this.AnimationPack = pack end,
            SetAnimID       = function(this, anim) this.AnimationName = anim end,
            SetStance       = function(this, mode) this.AnimationStance = mode end,
            SetLean         = function(this, lean) this.AnimationLean = lean end,
            Refresh         = function(this, time) this.AnimationTimer.refresh(time) this.AnimationTime = time  end,

            LastAnim        = "",

            AnimationTimer  = timernew(),
            AnimationTime   = nil,
        }
    end,

    ---------------------
    UpdateAll = function(self)

        local aPlayers = GetPlayers()
        if (table.empty(aPlayers)) then
            return
        end

        local sPush = ""
        for _, hPlayer in pairs(aPlayers) do
            sPush = sPush .. (self:UpdatePlayer(hPlayer) or "")
        end

        if (string.emptyN(sPush)) then
            self:Push(sPush)
        end
    end,

    ---------------------
    Push = function(self, sPush)

        ClientMod:OnAll(sPush)
    end,

    ---------------------
    UpdatePlayer = function(self, hPlayer)

        if (hPlayer:IsDead() or hPlayer:IsSpectating() or hPlayer:IsFrozen()) then
            return
        end

        if (not hPlayer.Info.FiringTimer.expired(5)) then
            return
        end

        local hVehicle   = hPlayer:GetVehicle()
        local iSpeed     = hPlayer:GetSpeed()
        if (iSpeed > 0 or hVehicle) then
            return
        end

        local bAlive     = (not (hPlayer:IsDead() and hPlayer:IsSpectating()))
        local iStance    = hPlayer.actorStats.stance
        local bFreeFall  = hPlayer.actorStats.inFreeFall == 1
        local bFlying    = hPlayer.actor:IsFlying()
        local hItem      = hPlayer:GetCurrentItem()
        if (not hItem) then
            hItem = { class = "Fists" } -- fallback
        end

        local iLean = hPlayer:GetLean()

        local bLean_L = iLean == LEAN_LEFT
        local bLean_R = iLean == LEAN_RIGHT

        local bFists         = not hItem or (hItem.class == "Fists" or hItem.class == "Binoculars")
        local bPistol        = hItem.class == "SOCOM"
        local bRocket        = hItem.class == "LAW"
        local bSniper        = (hItem.class == "DSG1" or hItem.class == "GaussRifle")
        local bKit           = (hItem.class == "RadarKit" or hItem.class == "RepairKit" or hItem.class == "LockpickKit")
        local bMini          = (hItem.class == "Hurricane" or hItem.class == "AlienMount" or hItem.class == "ShiTen")
        local bRifle         = not bMini and not bSniper and not bFists and not bRocket and not bPistol and not bKit

        local bLeaningBack  = (hPlayer:GetHitPos(-0.85)) ~= nil
        local aRHFront      = hPlayer:GetHitPos(1.5, nil, nil, hPlayer:GetBonePos("Bip01 Pelvis"))
        local bRepairAnim   = (aRHFront and aRHFront.entity and aRHFront.entity.vehicle)
        if (bRepairAnim) then
            local hEntity = aRHFront.entity
            if (hEntity.vehicle:GetRepairableDamage() <= 0) then
            end
        end

        local bNewAdminNear = false
        local sAppend = ""
        local bSalute = table.it(GetPlayers(), function(x, i, v)
            local d = vector.distance(v:GetPos(), hPlayer:GetPos())
            if (d > 0) then
                if (d > 20) then -- left
                    v.IdleInfo.SaluteInfo[hPlayer.id] = nil
                elseif (d < 7 and not v.IdleInfo.SaluteInfo[hPlayer.id]) then -- came to us, lets salute!
                    v.IdleInfo.SaluteInfo[hPlayer.id] = true
                    sAppend = sAppend .. "g_Client:IDLEFP(" .. v:GetChannel() .. ',"salute_right_01")' -- they salute
                    x = x or true
                end
            end
            return x -- we salute
        end)

        local bResetAnim =(iStance ~= hPlayer.IdleInfo.AnimationStance)
        local bLeanChange = (iLean ~= hPlayer.IdleInfo.AnimationLean)
        local bKeepAnim = false -- keep current selected?
        local bLoopAnim = false--false -- loop current selcjslf
        local hAnimationList = self.Animations
        local hAnimationPack

        -- PRONE
        if (not bFlying) then


            if (bSalute and (iStance == STANCE_STAND)) then
                bResetAnim = true
                hAnimationPack = hAnimationList.HelloAdmin.Anims

            elseif (bLeaningBack and (iStance == STANCE_STAND)) then
                hAnimationPack = hAnimationList.Idle[1].Leaning

            elseif (bMini) then
                hAnimationPack = (iStance == STANCE_STAND and hAnimationList.Stand[1].Minigun or iStance == STANCE_CROUCH and hAnimationList.Crouch[1].Minigun)

            elseif (bRifle) then
                hAnimationPack = (iStance == STANCE_PRONE and hAnimationList.Prone[1].Rifle or iStance == STANCE_STAND and hAnimationList.Stand[1].Rifle or iStance == STANCE_CROUCH and hAnimationList.Crouch[1].Rifle)
                -- can add custom here

            elseif (bSniper) then
                hAnimationPack = (iStance == STANCE_PRONE and hAnimationList.Prone[1].Rifle or iStance == STANCE_STAND and hAnimationList.Stand[1].Sniper or iStance == STANCE_CROUCH and hAnimationList.Crouch[1].Rifle)

            elseif (bPistol) then
                --[[if ((bLean_R or bLean_L) and (iStance == STANCE_STAND or iStance == STANCE_CROUCH)) then
                    hAnimationPack = (iStance == STANCE_STAND and hAnimationList.Stand[1].Leaning.Pistol[(bLean_R and "Right" or "Left")] or hAnimationList.Crouch[1].Leaning.Pistol[(bLean_R and "Right" or "Left")])
                    bResetAnim = bLeanChange
                    bLoopAnim = true
                    if (bLeanChange) then
                        Debug("lean changed, reset anim!")
                    else
                        bKeepAnim = true
                        Debug("REUSINGF ANIM!!")
                    end
                else--]]
                    hAnimationPack = (iStance == STANCE_PRONE and hAnimationList.Prone[1].Pistol or iStance == STANCE_STAND and hAnimationList.Stand[1].Pistol or iStance == STANCE_CROUCH and hAnimationList.Crouch[1].Pistol)
               -- end

            elseif (bRocket) then
                hAnimationPack = (iStance == STANCE_PRONE and hAnimationList.Prone[1].Rifle or iStance == STANCE_STAND and hAnimationList.Stand[1].Rifle or iStance == STANCE_CROUCH and hAnimationList.Crouch[1].Rocket)
                --hAnimationPack = (iStance == STANCE_STAND and hAnimationList.Stand[1].Minigun or iStance == STANCE_CROUCH and hAnimationList.Crouch[1].Minigun)

            else
                if (bRepairAnim and (iStance == STANCE_STAND or iStance == STANCE_CROUCH)) then
                    hAnimationPack = iStance == STANCE_STAND and hAnimationList.Vehicle[1].Repair.Stand or hAnimationList.Vehicle[1].Repair.Crouch

                else
                    hAnimationPack = (iStance == STANCE_PRONE and hAnimationList.Prone[1].Fist or iStance == STANCE_STAND and hAnimationList.Idle[1].Standing or iStance == STANCE_CROUCH and hAnimationList.Crouch[1].Fist)
                end

            end
        end

        if (hAnimationPack) then

            if (hAnimationPack ~= hPlayer.IdleInfo.AnimationPack) then
                bResetAnim = true
            end

            if (hPlayer.IdleInfo:CanStartNewAnim() or bResetAnim) then
                local sRandom = table.random(hAnimationPack)
                if (hPlayer.IdleInfo.AnimationName and bKeepAnim and not bResetAnim) then
                    sRandom = hPlayer.IdleInfo.LastAnim
                end

                local iAnimationLength = self:GetAnimationLength(sRandom) or 12
                if (iAnimationLength < 3) then
                    iAnimationLength = 3
                end

                local sFPRandom = "nil"
                if (hPlayer:IsIdle(15)) then
                    sFPRandom = table.random({ "cineFleet_nomadShieldsEysRightHand_01", "cineRescue_ExitHandsDawdle_01","cineRescue_nomadHandsExit_01","idle_01" })
                end

                hPlayer.IdleInfo.LastAnim = sRandom
                hPlayer.IdleInfo:Refresh(iAnimationLength)
                hPlayer.IdleInfo:SetPackID(hAnimationPack)
                hPlayer.IdleInfo:SetAnimID(sRandom)
                hPlayer.IdleInfo:SetStance(iStance)
                hPlayer.IdleInfo:SetLean(iLean)

                return string.format([[g_Client:IDLE(%d,"%s","%s",%s,%s)%s]],
                    hPlayer:GetChannel(),
                        sRandom,
                        sFPRandom,
                        g_ts(bLoopAnim),
                        g_ts(bResetAnim),
                        sAppend
                )
            end
        else
        end

      --  return sAppend

        do return sAppend end

        local vPlayer = hPlayer:GetPos()
        local aNearby = GetPlayers({ Pos = vPlayer, Range = 100 })


        local iSpeed     = hPlayer:GetSpeed()
        local hVehicle   = hPlayer:GetVehicle()
        local bAlive     = (not (hPlayer:IsDead() and hPlayer:IsSpectating()))
        local iStance    = hPlayer.actorStats.stance
        local bFreeFall  = hPlayer.actorStats.inFreeFall == 1
        local bFlying    = hPlayer.actor:IsFlying()
        local hItem      = hPlayer:GetCurrentItem()
        if (not hItem) then
            hItem = { class = "Fists" } -- fallback
        end

        local iTerrain      = System.GetTerrainElevation(vPlayer)
        local iTerrainDist  = vPlayer.z - System.GetTerrainElevation(vPlayer)
        local iWater        = CryAction.GetWaterInfo(vPlayer)
        local iWaterDist    = vPlayer.z - iWater
        local bHitWater     = iWaterDist > iTerrainDist
        local iGroundTime    = iTerrainDist / iSpeed

        local bFists         = not hItem or (hItem.class == "Fists" or hItem.class == "Binoculars")
        local bPistol        = hItem.class == "SOCOM"
        local bRocket        = hItem.class == "LAW"
        local bKit           = (hItem.class == "RadarKit" or hItem.class == "RepairKit" or hItem.class == "LockpickKit")
        local bRifle         = not bFists and not bRocket and not bPistol and not bKit
        local bMini          = (hItem.class == "Hurricane" or hItem.class == "AlienMount" or hItem.class == "ShiTen")
        local bSniper        = (hItem.class == "DSG1" or hItem.class == "GaussRifle")
        local bIsIdleAnim    = iStance == STANCE_STAND and bFists
        local bLoopAnim      = false
        local bOnGround      = not bFlying
        local bIsIdle        = hPlayer.Info.IdleTimer.expired(5)

        local hAtVehicle
        local bAtWall    = false
        local bAtVehicle = false

        local bFrozen = g_pGame:IsFrozen(hPlayer.id)
        local bLean_R = hPlayer:IsLeaning(LEAN_RIGHT)
        local bLean_L = hPlayer:IsLeaning(LEAN_LEFT)

        local bDeadBody = false
        local vDeadBody = hPlayer:CalcSpawnPos(1, -1.6)
        if (table.count(DoGetPlayers({ AllActors = true, except = player.id, pos = vDeadBody, range = 1.8, OnlyDead = true })) > 0) then
            bDeadBody = true
        end

        local sWeaponClass = (item and item.class or nil)
        if (sWeaponClass and not player.sLastWeaponClass) then
            player.sLastWeaponClass = sWeaponClass
        end


        if (fists and speed == 0 and player.IdleTime and player.IdleTime > 3) then
            atWall = player:GetHitPos(1, ent_static, player:GetBonePos("Bip01 Pelvis"), vecScale(player:GetBoneDir("Bip01 Pelvis"), -1));
            atWall = atWall and atWall.dist < 0.8;
            if (not atWall) then
                atVehicle = player:GetHitPos(1, ent_rigid+ent_living, nil,nil);
                vehicleEnt = atVehicle and atVehicle.entity;
                atVehicle = atVehicle and atVehicle.entity and atVehicle.entity.vehicle and atVehicle.entity.vehicle:GetRepairableDamage()<100 and atVehicle.dist < 1;
            end;
        end;
        local anims = cfg.Animations;
        local instant=false
        local reset_loop=false

        if (isIdle ) then
            local animPack;

            player.IdleTime = (player.IdleTime or 0) + 1;
            player.inlean = false;
            if ((not player.LastRadioAnim or _time>player.LastRadioAnim) and (not player.StaggerAnimtime or _time>player.StaggerAnimtime) and (not player.LastFireAnim or _time>player.LastFireAnim)) then

                if (onGround) then
                    if (fists or kit) then
                        if ((lean_r or lean_l) and (stance == STANCE_STAND or stance==STANCE_CROUCH)) then
                            animPack = stance == STANCE_STAND and  anims.Stand[1].Leaning.Fist[(lean_r and "Right" or "Left")] or anims.Crouch[1].Leaning.Fist[(lean_r and "Right" or "Left")];
                            NoExtraTime = true;
                            IsLoop=true
                            isIdleAnim = false;
                            reset_loop = stance~=player.lastPeekStance or lean_r~=player.LastRightLean
                            --Debug(reset_loop)
                            --Loop = true;
                            player.lastPeekStance=stance;
                            player.LastRightLean=lean_r;
                            player.inlean = true;
                            --	Debug("leaning " .. (lean_r and "R" or "L"))
                        elseif (atVehicle and (stance == STANCE_STAND or stance == STANCE_CROUCH)) then
                            animPack = stance == STANCE_STAND and anims.Vehicle[1].Repair.Stand or anims.Vehicle[1].Repair.Crouch;
                            NoExtraTime = true;
                            isIdleAnim = false;
                            if (vehicleEnt) then
                                --	Debug("Repair ...")
                                local hit = {
                                    shooter = player;
                                    shooterId = player.id;
                                    target = vehicleEnt;
                                    targetId = vehicleEnt.id;
                                    type = "repair";
                                    typeId = g_gameRules.game:GetHitTypeId("repair");
                                    weapon = nil;
                                    damage = 1;
                                    radius = 0;
                                    materialId = 0;
                                    partId = -1;
                                    pos = vehicleEnt:GetWorldPos();
                                    dir = { x=0.0, y=0.0, z=1.0 };
                                };
                                vehicleEnt.Server.OnHit(vehicleEnt, hit);
                            end;
                            --	Debug("Repair Vehicle OK")
                        elseif (atWall and stance == STANCE_STAND) then
                            animPack = anims.Idle[1].Leaning;
                            NoExtraTime = true;
                        else
                            animPack = (stance == STANCE_PRONE and anims.Prone[1].Fist or stance == STANCE_STAND and anims.Idle[1].Standing or stance == STANCE_CROUCH and anims.Crouch[1].Fist);
                        end;
                        if (player.GuardAnim and stance == STANCE_STAND) then
                            animPack = {
                                "relaxed_officerHandsBehindListening_01", --player.GuardAnimS or "relaxed_idle_rifle_01", --
                            };
                            reset_loop = player.sLastWeaponClass ~= sWeaponClass
                            IsLoop = true;
                        end;
                        if (stance == STANCE_STAND) then
                            local sayHello = false;
                            for i, v in pairs(GetPlayersInRange(playerPos, 7, player.id)or{}) do
                                if (v:HasAccess(ADMINISTRATOR)) then
                                    sayHello = true;
                                    break;
                                end;
                            end;
                            if (sayHello and player.IdleTime>2) then
                                if (not player.SaidHello) then
                                    player.SaidHello = true;
                                    isIdleAnim = false;
                                    player.AnimationTime = nil;
                                    animPack = anims.HelloAdmin.Anims;
                                    --Debug("PACK",animPack,"!",anims.HelloAdmin.Anims)
                                    --Debug(player:GetName()," says Salute!!!!");
                                end;
                            elseif (not sayHello and player.SaidHello) then
                                --	Debug(player:GetName()," says bye fucker")
                                player.SaidHello = false;
                            end;
                        end;
                    elseif (rifle and (lean_r or lean_l) and (stance == STANCE_STAND or stance==STANCE_CROUCH)) then
                        animPack = stance == STANCE_STAND and  anims.Stand[1].Leaning.Rifle[(lean_r and "Right" or "Left")] or anims.Crouch[1].Leaning.Rifle[(lean_r and "Right" or "Left")];
                        NoExtraTime = true;
                        IsLoop=true
                        isIdleAnim = false;
                        reset_loop = stance~=player.lastPeekStance or lean_r~=player.LastRightLean
                        --Debug(reset_loop)
                        --Loop = true;
                        player.lastPeekStance=stance;
                        player.LastRightLean=lean_r;
                        --Debug("RIFLE !!! leaning " .. (lean_r and "R" or "L"))
                    elseif (bDeadBody and anims.KickDeadBody.Use and (rifle or sniper) and stance == STANCE_STAND) then

                        animPack = anims.KickDeadBody[1].Rifle
                    elseif (sniper) then
                        --Debug("S")
                        animPack = (stance == STANCE_PRONE and anims.Prone[1].Rifle or stance == STANCE_STAND and anims.Stand[1].Sniper or stance == STANCE_CROUCH and anims.Crouch[1].Rifle);
                        if (player.GuardAnim and stance == STANCE_STAND) then
                            animPack = {
                                player.GuardAnimS or "relaxed_idle_rifle_01", --relaxed_officerHandsBehindListening_01
                            };
                            reset_loop = player.sLastWeaponClass ~= sWeaponClass
                            IsLoop = true;
                        end;
                    elseif (mini) then
                        --Debug("M")
                        animPack = (stance == STANCE_STAND and anims.Stand[1].Minigun or stance == STANCE_CROUCH and anims.Crouch[1].Minigun);

                    elseif (rifle) then
                        -- Debug("R1")
                        animPack = (stance == STANCE_PRONE and anims.Prone[1].Rifle or stance == STANCE_STAND and anims.Stand[1].Rifle or stance == STANCE_CROUCH and anims.Crouch[1].Rifle);
                        if (player.GuardAnim and stance == STANCE_STAND) then
                            animPack = {
                                player.GuardAnimS or "relaxed_idle_rifle_01", --relaxed_officerHandsBehindListening_01
                            };
                            reset_loop = player.sLastWeaponClass ~= sWeaponClass
                            IsLoop = true;
                        end;
                    elseif (pistol) then
                        --Debug("P")
                        if ((lean_r or lean_l) and (stance == STANCE_STAND or stance==STANCE_CROUCH)) then
                            animPack = stance == STANCE_STAND and  anims.Stand[1].Leaning.Pistol[(lean_r and "Right" or "Left")] or anims.Crouch[1].Leaning.Pistol[(lean_r and "Right" or "Left")];
                            NoExtraTime = true;
                            IsLoop=true
                            isIdleAnim = false;
                            reset_loop = stance~=player.lastPeekStance or lean_r~=player.LastRightLean
                            --	Debug(reset_loop)
                            --Loop = true;
                            player.lastPeekStance=stance;
                            player.LastRightLean=lean_r;
                            --Debug("PISTOL!!!! !!! leaning " .. (lean_r and "R" or "L"))
                        else
                            animPack = (stance == STANCE_PRONE and anims.Prone[1].Pistol or stance == STANCE_STAND and anims.Stand[1].Pistol or stance == STANCE_CROUCH and anims.Crouch[1].Pistol);
                        end;
                    elseif (rocket) then
                        -- Debug("R2")
                        animPack = (stance == STANCE_PRONE and anims.Prone[1].Rifle or stance == STANCE_STAND and anims.Stand[1].Rifle or stance == STANCE_CROUCH and anims.Crouch[1].Rifle);
                        -- if (stance == STANCE_STAND) then
                        -- IsLoop = true
                        -- IsIdleAnim = false
                        -- end

                    end;

                    player.sLastWeaponClass = sWeaponClass
                    if ((not isIdleAnim and player.IdleTime > 2 or instant) or (player.IdleTime > 15)) then
                        --	Debug("Is Idle!",player:GetName())
                        if (animPack) then
                            local animation = self:GetRandomAnim(animPack, player.LastAnimation);
                            local animationLength = self:GetAnimLength(animation);
                            local ExtraCode;
                            -- Debug(animPack,animation)
                            if (IsLoop) then
                                --	Debug("Is LOOP!!!!",player:GetName())
                                if (reset_loop) then
                                    player.LoopAnim=false;
                                    Debug("loop reset! :D")
                                end;
                                if (player.LoopAnim) then
                                    Debug("Already looping.");
                                    return true;
                                else
                                    local code = [[
										ATOMClient:HandleEvent(eCE_IdleAnim, "]] .. player:GetName() .. [[", "]] .. animation .. [[", true);
									]];
                                    ExecuteOnAll(code);
                                    if (player.GuardSyncId) then
                                        RCA:StopSync(player.id, player.GuardSyncId)
                                    end;
                                    player.GuardSyncId = RCA:SetSync(player, { linked = player.id, client = code });
                                    player.LoopAnim = true;
                                    return true;
                                end;
                            elseif (player.LoopAnim or player.GuardSyncId) then
                                Debug("unregiserting looped anim..",player:GetName())
                                RCA:Unsync(player.id, player.GuardSyncId);
                                player.GuardSyncId = nil;
                                ExtraCode = "LOOPED_ANIMS[p.id]=nil";
                                player.LoopAnim = false;
                                player.AnimationTime = nil;
                            end;

                            if (not player.AnimationTime) then
                                --	Debug("PLAY NEW ANIMATIN::",player:GetName(),animationLength* (NoExtraTime and 1 or (isIdleAnim and 4 or 3)))
                                player.LastAnimation = animation;
                                player.AnimationTime = _time + animationLength * (NoExtraTime and 1 or (isIdleAnim and 4 or 3));
                                self:StartAnim(player, animation, ExtraCode);
                            elseif (_time > player.AnimationTime) then
                                --	Debug("ANBIMATION DONHEE::",player:GetName())
                                player.AnimationTime = nil;
                                self:UpdatePlayer(player); -- !!Check this
                            elseif (_time - player.AnimationTime < -100 ) then
                                ATOMLog:LogError("Animation (%s) created infinite delay %s (%s)", (player.LastAnimation or "<error>"), cutNum(player.AnimationTime-_time,2),(self:GetAnimLength((player.LastAnimation or "<error>")) or "<error>"));
                                player.AnimationTime = nil;
                            end;

                        else
                            -- do something ..
                        end;
                    end;
                else
                    player.AirTime = (player.AirTime or 0) + 1;

                    if (player.AirTime > 6) then
                        if (isFlying) then
                            animPack = anims.Air[1].Fly;
                            --Debug("Fly")
                        else
                            if (freeFall) then
                                if (hitgroundTime < 2) then
                                    --	Debug("Free fall CLOSE");
                                    animPack = anims.Air[1].FreeFall.Close;
                                else
                                    --	Debug("Free fall FAR",willHitWater);
                                    animPack = anims.Air[1].FreeFall.Far[((willHitWater and waterDistance < 30) and "Water" or "Ground")];
                                end;
                            else
                                if (willHitWater and waterDistance < 30) then
                                    animPack = anims.Air[1].Fall.Water;
                                else
                                    animPack = anims.Air[1].Fall.Ground;
                                end;
                                --Debug("Fall")
                            end;
                        end;




                    end
                end
            end
        end

        if (animPack) then
            local sAnimation = table.random(animPack)
            local iLength = self:GetAnimLength(sAnimation)

            if (player.AnimTimer.expired()) then
                player.AnimTimer.refresh(iLength)
                return string.format([[g_Client:IDLE(%d,"%s",%s)]], player:GetChannel(), sAnimation, g_ts(IsLoop))

            end
        end
    end,

    ---------------------
    GetAnimationLength = function(self, sID)
        local aAnimTimes = { -- Auto-Generated
            ["prone_idle_pistol_01"] = 1.93333,
            ["prone_idle_pistol_02"] = 3.66667,
            ["prone_idle_pistol_03"] = 4.96667,
            ["prone_idle_pistol_04"] = 4.23333,
            ["prone_idle_rifle_01"] = 2.06667,
            ["prone_idle_rifle_02"] = 11.1,
            ["prone_idle_rifle_03"] = 8.96667,
            ["prone_idle_nw_01"] = 2,
            ["prone_idle_nw_02"] = 3.66667,
            ["prone_idle_nw_03"] = 2,
            ["prone_idle_nw_04"] = 4.53333,
            ["combat_idle_mg_01"] = 2.23333,
            ["combat_idle_mg_02"] = 4.33333,
            ["combat_idle_mg_03"] = 3.76667,
            ["combat_idle_mg_04"] = 4.9,
            ["combat_sniperIdle_rifle_01"] = 10.4333,
            ["combat_idle_pistol_01"] = 2.1,
            ["combat_idle_pistol_02"] = 3.6,
            ["combat_idle_pistol_03"] = 3.6,
            ["combat_idle_pistol_04"] = 4.1,
            ["combat_idle_rifle_01"] = 1.4,
            ["combat_idle_rifle_02"] = 7.7,
            ["combat_idle_rifle_03"] = 8.36667,
            ["combat_idle_rifle_04"] = 3.66667,
            ["combat_guard_rifle_01"] = 0.33333,
            ["crouch_idle_mg_01"] = 3.06667,
            ["crouch_idle_mg_02"] = 4.93333,
            ["crouch_idle_mg_03"] = 3.63333,
            ["crouch_idle_mg_04"] = 4,
            ["crouch_idle_pistol_01"] = 1.96667,
            ["crouch_idle_pistol_02"] = 3,
            ["crouch_idle_pistol_03"] = 1.66667,
            ["crouch_idleKnee_pistol_01"] = 1.96667,
            ["crouch_idleKnee_pistol_02"] = 3,
            ["crouch_idleKnee_pistol_03"] = 1.66667,
            ["crouch_idle_rifle_01"] = 1.46667,
            ["crouch_idle_rifle_02"] = 8.33333,
            ["crouch_idle_rifle_03"] = 9.33333,
            ["crouch_idle_rifle_04"] = 2.93333,
            ["crouch_idleKnee_rifle_01"] = 1.46667,
            ["crouch_idleKnee_rifle_02"] = 8.33333,
            ["crouch_idleKnee_rifle_03"] = 9.33333,
            ["crouch_idleKnee_rifle_04"] = 2.93333,
            ["crouch_idle_nw_01"] = 1.46667,
            ["crouch_idle_nw_02"] = 12.2667,
            ["crouch_idle_nw_03"] = 5.83333,
            ["crouch_idle_nw_04"] = 5,
            ["crouch_idleKnee_nw_02"] = 12.2667,
            ["crouch_idleKnee_nw_03"] = 5.83333,
            ["crouch_idleKnee_nw_04"] = 5,
            ["relaxed_idleCheckingWatch_01"] = 6,
            ["relaxed_idleChinrub_01"] = 4.33333,
            ["relaxed_idleChinrub_02"] = 6.33333,
            ["relaxed_idleChinrub_03"] = 7,
            ["relaxed_idleClaphands_01"] = 9.66667,
            ["relaxed_idleDawdling_nw_01"] = 7,
            ["relaxed_idleDrummingOnLegs_nw_01"] = 7,
            ["relaxed_idleHeadScratch_01"] = 6.33333,
            ["relaxed_idleHeadScratch_02"] = 4.16667,
            ["relaxed_idleHeadScratch_03"] = 4.9,
            ["relaxed_idleHeadScratch_04"] = 6.7,
            ["relaxed_idleHeadScratch_05"] = 4.9,
            ["relaxed_idleInsectSwat_leftHand_01"] = 4.16667,
            ["relaxed_idleInsectSwat_leftHand_02"] = 7.16667,
            ["relaxed_idleKickDust_01"] = 5.33333,
            ["relaxed_idleKickStone_01"] = 6.33333,
            ["relaxed_idleListening_01"] = 4.46667,
            ["relaxed_idleListening_02"] = 4.53333,
            ["relaxed_idleListening_03"] = 10.6667,
            ["relaxed_idlePickNose_nw_01"] = 6.66667,
            ["relaxed_idleRubKnee_01"] = 4.9,
            ["relaxed_idleRubNeck_01"] = 4.33333,
            ["relaxed_idle_rifle_01"] = 2.25,
            ["relaxed_idleScratchbutt_01"] = 4,
            ["relaxed_idleScratchNose_nw_01"] = 5.86667,
            ["relaxed_idleShift_01"] = 7.33333,
            ["relaxed_idleShift_01"] = 7.33333,
            ["relaxed_idleShoulderShrug_01"] = 5.33333,
            ["relaxed_idleShoulderShrug_02"] = 5.76667,
            ["relaxed_idleShoulderShrug_03"] = 7.5,
            ["relaxed_idleSmokeDrag_cigarette_01"] = 10,
            ["relaxed_idleSmokeDrag_cigarette_02"] = 8.33333,
            ["relaxed_idleTappingFoot_01"] = 6.5,
            ["relaxed_idleTeetering_nw_01"] = 6.36667,
            ["relaxed_idleTieLaces_01"] = 10,
            ["relaxed_idleYawn_nw_01"] = 5.66667,
            ["relaxed_readIdle_book_01"] = 4.43333,
            ["relaxed_salute_nw_01"] = 3,
            ["relaxed_saluteLazyCO_nw_01"] = 3.6,
            ["relaxed_standIdleHandsBehindCOLoop_01"] = 5.33333,
            ["relaxed_idleFootOnWallLoop_nw_01"] = 15.3333,
            ["relaxed_idleFootOnWallLoop_nw_02"] = 2.23333,
            ["relaxed_standIdleHandsBehindCOLoop_01"] = 5.33333,
            ["relaxed_standIdleHandsBehindCOLoop_01"] = 5.33333,
            ["relaxed_standIdleHandsBehindCOLoop_02"] = 10,
            ["relaxed_repairGeneric_hammer_01"] = 5.2,
            ["relaxed_repairGeneric_hammer_02"] = 5.2,
            ["relaxed_repairGeneric_screwdriver_01"] = 1.8,
            ["relaxed_repairGenericCrouch_hammer_01"] = 1.26667,
            ["relaxed_repairGenericCrouch_screwdriver_01"] = 9.26667,
            ["relaxed_repairGenericCrouch_screwdriver_02"] = 9.26667,
            ["relaxed_repairGenericCrouch_screwdriver_03"] = 17.2,
            ["relaxed_salute_nw_01"] = 3,
            ["relaxed_saluteLazyCO_nw_01"] = 3.6,
            ["stealth_idle_mg_01"] = 2.2,
            ["stealth_idle_mg_02"] = 3.8,
            ["stealth_idle_mg_03"] = 4.3,
            ["stealth_idle_mg_04"] = 3.66667,
            ["stealth_idle_mg_01"] = 2.2,
            ["stealth_idle_nw_01"] = 1.66667,
            ["stealth_idle_mg_02"] = 3.8,
            ["stealth_idle_nw_02"] = 3.66667,
            ["stealth_idle_mg_03"] = 4.3,
            ["stealth_idle_nw_03"] = 4.93333,
            ["stealth_idle_mg_04"] = 3.66667,
            ["stealth_idle_nw_04"] = 2.93333,
            ["stealth_idle_nw_01"] = 1.66667,
            ["stealth_idle_pistol_01"] = 1.3,
            ["stealth_idle_nw_02"] = 3.66667,
            ["stealth_idle_pistol_02"] = 2.8,
            ["stealth_idle_nw_03"] = 4.93333,
            ["stealth_idle_pistol_03"] = 3.5,
            ["stealth_idle_nw_04"] = 2.93333,
            ["stealth_idle_pistol_04"] = 3.53333,
            ["stealth_idle_pistol_01"] = 1.3,
            ["stealth_idle_rifle_01"] = 1.86667,
            ["stealth_idle_pistol_02"] = 2.8,
            ["stealth_idle_rifle_02"] = 3.76667,
            ["stealth_idle_pistol_03"] = 3.5,
            ["stealth_idle_rifle_03"] = 2.9,
            ["stealth_idle_pistol_04"] = 3.53333,
            ["stealth_idle_rifle_04"] = 3.66667,
            ["stealth_idle_rifle_01"] = 1.86667,
            ["stealth_flinch_rifle_01"] = 1.63333,
            ["stealth_idle_rifle_02"] = 3.76667,
            ["stealth_idle_rifle_03"] = 2.9,
            ["stealth_idle_rifle_04"] = 3.66667,
            ["stealth_flinch_rifle_01"] = 1.63333,
            ["combat_callReinforcements_nw_01"] = 2.6,
            ["combat_callReinforcements_nw_02"] = 3.56667,
            ["combat_fearFront_nw_01"] = 1.5,
            ["combat_fearFront_nw_02"] = 1.76667,
            ["combat_fearFront_rifle_01"] = 1.5,
            ["combat_fearFront_rifle_02"] = 1.76667,
            ["combat_flinch_rifle_01"] = 1.63333,
            ["combat_fearFront_pistol_01"] = 1.5,
            ["combat_fearFront_pistol_02"] = 1.76667,
            ["stealth_flinch_rifle_01"] = 1.63333,
            ["stealth_flinch_rifle_01"] = 1.63333,
            ["crouch_flinch_rifle_01"] = 1.26667,
            ["crouch_flinch_rifle_02"] = 1.43333,
            ["combat_flinch_rifle_01"] = 1.63333,
        };
        return aAnimTimes[sID]
    end,

})