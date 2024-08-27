-- ==================================
eVE_ThrowFrag           = 0
eVE_IncomingExplosive   = 1
eVE_PlaceExplosive      = 2
eVE_UseMG               = 3
eVE_FriendlyFire        = 4
eVE_MeleeDeath          = 5 -- NOW on CLIENT!
eVE_ReloadWeapon        = 6
eVE_AllEliminated       = 7
eVE_OneEliminated       = 8
eVE_OneEliminatedReply  = 9
eVE_AllyEliminated      = 10

-- ==================================
CreatePlugin("PlayerVoices", {

    Voices = {

        [eVE_AllyEliminated] = {
            SoundName = "aidowngroup_",
            SoundRange = { "00", "01", "02", "03", "04", "05" },
            FolderName = "ai_marine",
            FolderRange = { "", "_1", "_2", "_3" },
            ModelSpecific = {
                [CM_KYONG] 		= { FolderName = "ai_kyong", 			FolderRange = { "" } },
                [CM_KOREANAI] 	= { FolderName = "ai_korean_soldier", 	FolderRange = { "_1", "_2", "_3" } },
                [CM_AZTEC] 			= { FolderName = "ai_marine", 			FolderRange = { "_2" } },
                [CM_JESTER] 		= { FolderName = "ai_marine", 			FolderRange = { "" } },
                [CM_SYKES] 			= { FolderName = "ai_marine", 			FolderRange = { "_1" } },
                [CM_PROPHET] 		= { FolderName = "ai_marine", 	FolderRange = { "_3" } },
                [CM_PSYCHO] 		= { FolderName = "ai_marine", 	FolderRange = { "" } },
                [CM_KEEGAN] 		= { FolderName = "ai_marine", 	FolderRange = { "" } },
                [CM_BRADLEY] 		= { FolderName = "ai_marine", 	FolderRange = { "_2" } },
                ["TeamNK"] 		= { FolderName = "ai_korean_soldier", FolderRange = { "_1_suit", "_02_suit", "_3_suit" } },
                ["Females"] 			= { SoundName = "helena_mine_ab4", SoundRange = { "_pu0009", "_pu00010","_pu00011","_pu00012" }, FolderName = "mine", 	FolderRange = { "" } },
            }
        },

        [eVE_OneEliminatedReply] = {
            SoundName = "targetdownreply_",
            SoundRange = { "00", "01", "02", "03", "04", "05", "06", "07", "08", "09", "10" , "11" , "12" , "13" , "14" },
            FolderName = "ai_marine",
            FolderRange = { "", "_1", "_2", "_3" },
            ModelSpecific = {
                [CM_KYONG] 		= { SoundRange = {"00", "01", "02", "03", "04", "05", "06", "07", "08"},SoundName="targetdown_",FolderName = "ai_kyong", 			FolderRange = { "" } },
                [CM_KOREANAI] 	= { SoundRange = {"00", "01", "02", "03", "04", "05", "06", "07", "08"},FolderName = "ai_korean_soldier", 	FolderRange = { "_1", "_2", "_3" } },
                [CM_AZTEC] 			= { FolderName = "ai_marine", 			FolderRange = { "_2" } },
                [CM_JESTER] 		= { FolderName = "ai_jester", 			FolderRange = { "" } },
                [CM_SYKES] 			= { FolderName = "ai_marine", 			FolderRange = { "_1" } },
                [CM_PROPHET] 		= { FolderName = "ai_prophet", 	FolderRange = { "" } },
                [CM_PSYCHO] 		= { FolderName = "ai_psycho", 	FolderRange = { "" } },
                [CM_KEEGAN] 		= { FolderName = "ai_marine", 	FolderRange = { "" } },
                [CM_BRADLEY] 		= { FolderName = "ai_marine", 	FolderRange = { "_2" } },
                ["TeamN"] 		= { SoundRange = {"00", "01", "02", "03", "04", "05", "06", "07", "08"}, FolderName = "ai_korean_soldier", FolderRange = { "_1_suit", "_02_suit", "_3_suit" } },
                ["Females"] 			= { SoundName = "helena_mine_ab4", SoundRange = {"_pu0009", "_pu00010","_pu00011","_pu00012",  "_pu0004" }, FolderName = "mine", 	FolderRange = { "" } },
            }
        },

        [eVE_OneEliminated] = {
            SoundName = "targetdown_",
            SoundRange = { "00", "01", "02", "03", "04", "05", "06", "07", "08", "09", "10" , "11" , "12" , "13" , "14" },
            FolderName = "ai_marine",
            FolderRange = { "", "_1", "_2", "_3" },
            ModelSpecific = {
                [CM_KYONG] 		= { SoundRange = {"00", "01", "02", "03", "04", "05", "06", "07", "08"}, FolderName = "ai_kyong", 			FolderRange = { "" } },
                [CM_KOREANAI] 	= { FolderName = "ai_korean_soldier", 	FolderRange = { "_1", "_2", "_3" } },
                [CM_AZTEC] 			= { FolderName = "ai_marine", 			FolderRange = { "_2" } },
                [CM_JESTER] 		= { SoundName = "targetdownreply_", FolderName = "ai_jester", 			FolderRange = { "" } },
                [CM_SYKES] 			= { FolderName = "ai_marine", 			FolderRange = { "_1" } },
                [CM_PROPHET] 		= { SoundName = "targetdownreply_", FolderName = "ai_prophet", 	FolderRange = { "" } },
                [CM_PSYCHO] 		= { SoundName = "targetdownreply_", FolderName = "ai_psycho", 	FolderRange = { "" } },
                [CM_KEEGAN] 		= { FolderName = "ai_marine", 	FolderRange = { "" } },
                [CM_BRADLEY] 		= { FolderName = "ai_marine", 	FolderRange = { "_2" } },
                ["TeamNK"] 		= { SoundRange = {"00", "01", "02", "03", "04", "05", "06", "07", "08"}, FolderName = "ai_korean_soldier", FolderRange = { "_1_suit", "_02_suit", "_3_suit" } },
                ["Females"] 			= { SoundName = "helena_mine_ab4", SoundRange = {"_pu0009", "_pu00010","_pu00011","_pu00012",  "_pu0004" }, FolderName = "mine", 	FolderRange = { "" } },
            }
        },

        [eVE_AllEliminated] = {
            SoundName = "alldead_",
            SoundRange = { "00", "01", "02", "03", "04", "05" },
            FolderName = "ai_marine",
            FolderRange = { "", "_1", "_2", "_3" },
            ModelSpecific = {
                [CM_KYONG] 		= { SoundName = "contactgroup_", SoundRange = {"00", "01", "02", "03", "04", "05", "06", "07", "08","09"}, FolderName = "ai_kyong", 			FolderRange = { "" } },
                [CM_KOREANAI] 	= { SoundName = "combatgroup_", SoundRange = {"00", "01", "02", "03", "04", "05", "06", "07", "08","09"}, FolderName = "ai_korean_soldier", 	FolderRange = { "_1", "_2", "_3" } },
                [CM_AZTEC] 			= { FolderName = "ai_marine", 			FolderRange = { "_2" } },
                [CM_JESTER] 		= { FolderName = "ai_jester", 			FolderRange = { "" } },
                [CM_SYKES] 			= { FolderName = "ai_marine", 			FolderRange = { "_1" } },
                [CM_PROPHET] 		= { FolderName = "ai_prophet", 	FolderRange = { "" } },
                [CM_PSYCHO] 		= { FolderName = "ai_psycho", 	FolderRange = { "" } },
                [CM_KEEGAN] 		= { FolderName = "ai_marine", 	FolderRange = { "" } },
                [CM_BRADLEY] 		= { FolderName = "ai_marine", 	FolderRange = { "_2" } },
                ["TeamNK"] 		= { SoundName = "combatgroup_", SoundRange = {"00", "01", "02", "03", "04", "05", "06", "07", "08"}, FolderName = "ai_korean_soldier", FolderRange = { "_1_suit", "_02_suit", "_3_suit" } },
                ["Females"] 			= { SoundName = "helena_mine_ab4", SoundRange = { "_pu0009", "_pu00010","_pu00011","_pu00012", "_pu0004" }, FolderName = "mine", 	FolderRange = { "" } },
            }
        },

        [eVE_ReloadWeapon] = {
            SoundName = "reloading_",
            SoundRange = { "00", "01", "02", "03", "04", "05" },
            FolderName = "ai_marine",
            FolderRange = { "", "_1", "_2", "_3" },
            ModelSpecific = {
                [CM_KYONG] 		= { SoundName = "contactreply_", SoundRange = { "02", "04", "05" }, FolderName = "ai_kyong", 			FolderRange = { "" } },
                [CM_KOREANAI] 	= { FolderName = "ai_korean_soldier", 	FolderRange = { "_1", "_2", "_3" } },
                [CM_AZTEC] 			= { FolderName = "ai_marine", 			FolderRange = { "_2" } },
                [CM_JESTER] 		= { FolderName = "ai_marine", 			FolderRange = { "" } },
                [CM_SYKES] 			= { FolderName = "ai_marine", 			FolderRange = { "_1" } },
                [CM_PROPHET] 		= { FolderName = "ai_marine", 	FolderRange = { "_3" } },
                [CM_PSYCHO] 		= { FolderName = "ai_marine", 	FolderRange = { "" } },
                [CM_KEEGAN] 		= { FolderName = "ai_marine", 	FolderRange = { "" } },
                [CM_BRADLEY] 		= { FolderName = "ai_marine", 	FolderRange = { "_2" } },
                ["TeamNK"] 		= { FolderName = "ai_korean_soldier", FolderRange = { "_1", "_2", "_3" } },
                ["Females"] 			= { SoundName = "helena_mine_ab4", SoundRange = {"_pu0009", "_pu00010","_pu00011","_pu00012",  "_pu0004" }, FolderName = "mine", 	FolderRange = { "" } },
            }
        },

        [eVE_FriendlyFire] = {
            SoundName = "friendlyfire_",
            SoundRange = { "00", "01", "02", "03", "04", "05" },
            FolderName = "ai_marine",
            FolderRange = { "", "_1", "_2", "_3" },
            ModelSpecific = {
                [CM_KYONG] 		= { SoundName = "bulletrain_", FolderName = "ai_kyong", 			FolderRange = { "" } },
                [CM_KOREANAI] 	= { SoundName = "bulletrain_", FolderName = "ai_korean_soldier", 	FolderRange = { "_1", "_2", "_3" } },
                [CM_AZTEC] 			= { FolderName = "ai_marine", 			FolderRange = { "_2" } },
                [CM_JESTER] 		= { FolderName = "ai_marine_3", 			FolderRange = { "" } },
                [CM_SYKES] 			= { FolderName = "ai_marine", 			FolderRange = { "_1" } },
                [CM_PROPHET] 		= { FolderName = "ai_prophet", 	FolderRange = { "" } },
                [CM_PSYCHO] 		= { FolderName = "ai_psycho", 	FolderRange = { "" } },
                [CM_KEEGAN] 		= { FolderName = "ai_marine", 	FolderRange = { "" } },
                [CM_BRADLEY] 		= { FolderName = "ai_major_bradley", 	FolderRange = { "" } },
                ["TeamNK"] 		= { SoundName = "alertthreatreply_", FolderName = "ai_korean_soldier", FolderRange = { "_1_suit", "_02_suit", "_3_suit" } },
                ["Females"] 			= { SoundName = "helena_mine_ab4", SoundRange = { "_pu0009", "_pu00010","_pu00011","_pu00012" }, FolderName = "mine", 	FolderRange = { "" } },
            }
        },

        [eVE_UseMG] = {
            SoundName = "mountedweapon_",
            SoundRange = { "00", "01", "02", "03" },
            FolderName = "ai_marine",
            FolderRange = { "", "_1", "_2", "_3" },
            ModelSpecific = {
                [CM_KYONG] 		= { SoundRange = { "00", "01", "02", "03", "04", "05", "06", "07", "08", "09" },SoundName = "contactgroup_", FolderName = "ai_kyong", 			FolderRange = { "" } },
                [CM_KOREANAI] 	= { SoundName = "mountedweapon_", FolderName = "ai_korean_soldier", 	FolderRange = { "_1", "_2", "_3" } },
                [CM_AZTEC] 			= { FolderName = "ai_marine", 			FolderRange = { "_2" } },
                [CM_JESTER] 		= { FolderName = "ai_marine_3", FolderRange = { "" } },
                [CM_SYKES] 			= { FolderName = "ai_marine", 			FolderRange = { "_1" } },
                [CM_PROPHET] 		= { FolderName = "ai_prophet", 	FolderRange = { "" } },
                [CM_PSYCHO] 		= { FolderName = "ai_psycho", 	FolderRange = { "" } },
                [CM_KEEGAN] 		= { FolderName = "ai_marine", 	FolderRange = { "" } },
                [CM_BRADLEY] 		= { FolderName = "ai_marine", 	FolderRange = { "_2" } },
                ["TeamNK"] 		= { SoundName = "contactsoloclose_", FolderName = "ai_korean_soldier", FolderRange = { "_1_suit", "_02_suit", "_3_suit" } },
                ["Females"] 			= { SoundName = "helena_mine_ab4", SoundRange = {"_pu0009", "_pu00010","_pu00011","_pu00012",  "_pu0004" }, FolderName = "mine", 	FolderRange = { "" } },
            }
        },

        [eVE_PlaceExplosive] = {
            SoundName   = "explosionimminent_",
            SoundRange  = { "00", "01", "02", "03" },
            FolderName  = "ai_marine",
            FolderRange = { "", "_1", "_2", "_3" },
            ModelSpecific = {
                [CM_KYONG] 		= { SoundName = "incominggrenade_", SoundRange = { "00", "01", "02", "03", "04", "05" }, FolderName = "ai_kyong", 			FolderRange = { "" } },
                [CM_KOREANAI] 	= { FolderName = "ai_korean_soldier", 	FolderRange = { "_1", "_2", "_3" } },
                [CM_AZTEC] 			= { FolderName = "ai_marine", 			FolderRange = { "_2" } },
                [CM_JESTER] 		= { FolderName = "ai_marine_3", FolderRange = { "" } },
                [CM_SYKES] 			= { FolderName = "ai_marine", 			FolderRange = { "_1" } },
                [CM_PROPHET] 		= { FolderName = "ai_prophet", 	FolderRange = { "" } },
                [CM_PSYCHO] 		= { FolderName = "ai_psycho", 	FolderRange = { "" } },
                [CM_KEEGAN] 		= { FolderName = "ai_marine", 	FolderRange = { "" } },
                [CM_BRADLEY] 		= { FolderName = "ai_marine", 	FolderRange = { "_2" } },
                ["TeamNK"] 		= { FolderName = "ai_korean_soldier", FolderRange = { "_1_suit", "_02_suit", "_3_suit" } },
                ["Females"] 			= { SoundName = "helena_mine_ab4", SoundRange = {"_pu0009", "_pu00010","_pu00011","_pu00012",  "_pu0004" }, FolderName = "mine", 	FolderRange = { "" } },
            }
        },


        [eVE_IncomingExplosive] = {
            SoundName   = "incominggrenade_",
            SoundRange  = { "00", "01", "02", "03", "04", "05" },
            FolderName  = "ai_marine",
            FolderRange = { "", "_1", "_2", "_3" },

            ModelSpecific = {
                [CM_KYONG] 		= { SoundRange = nil, FolderName = "ai_kyong", 			FolderRange = { "" } },
                [CM_KOREANAI] 	= { FolderName = "ai_korean_soldier", 	FolderRange = { "_1", "_2", "_3" } },
                [CM_AZTEC] 		= { FolderName = "ai_marine", 			FolderRange = { "_2" } },
                [CM_JESTER] 	= { FolderName = "ai_marine_3", FolderRange = { "" } },
                [CM_SYKES] 		= { FolderName = "ai_marine", 			FolderRange = { "_1" } },
                [CM_PROPHET] 	= { FolderName = "ai_prophet", 	FolderRange = { "" } },
                [CM_PSYCHO] 	= { FolderName = "ai_psycho", 	FolderRange = { "" } },
                [CM_KEEGAN] 	= { FolderName = "ai_marine", 	FolderRange = { "" } },
                [CM_BRADLEY] 	= { FolderName = "ai_marine", 	FolderRange = { "_2" } },
                ["TeamNK"] 		= { FolderName = "ai_korean_soldier", FolderRange = { "_1_suit", "_02_suit", "_3_suit" } },
                ["Females"] 	= { SoundName = "helena_mine_ab4", SoundRange = {"_pu0009", "_pu00010","_pu00011","_pu00012",  "_pu0004" }, FolderName = "mine", 	FolderRange = { "" } },
            }
        },

        [eVE_ThrowFrag] = {

            SoundName = "grenade_",
            SoundRange = { "00", "01", "02", "03", "04" },

            FolderName = "ai_marine",
            FolderRange = { "", "_1", "_2", "_3" },

            ModelSpecific = {
                [CM_KYONG]      = { SoundName = "grenade_", FolderName = "ai_kyong", 			FolderRange = { "" } },
                [CM_KOREANAI] 	= { SoundName = "grenade_", FolderName = "ai_korean_soldier", 	FolderRange = { "_1", "_2", "_3" } },
                [CM_AZTEC]      = { SoundName = "grenade_", FolderName = "ai_marine", 			FolderRange = { "_2" } },
                [CM_JESTER]     = { SoundName = "grenade_", SoundRange = { "00", "01", "03", "04" }, FolderName = "ai_marine_3", FolderRange = { "" } },
                [CM_SYKES]      = { SoundName = "grenade_", FolderName = "ai_marine", 			FolderRange = { "_1" } },
                [CM_PROPHET]    = { SoundName = "incominggrenade_", SoundRange = { "00", "01", "02", "03", "04", "05" }, FolderName = "ai_prophet", 	FolderRange = { "" } },
                [CM_PSYCHO]     = { SoundName = "incominggrenade_", SoundRange = { "00", "01", "02", "03", "04", "05" }, FolderName = "ai_psycho", 	FolderRange = { "" } },
                [CM_KEEGAN]     = { SoundName = "grenade_", FolderName = "ai_marine", 	FolderRange = { "" } },
                [CM_BRADLEY] 	= { SoundName = "grenade_", FolderName = "ai_marine", 	FolderRange = { "_2" } },
                ["TeamNK"] 		= { SoundName = "incominggrenade_", FolderName = "ai_korean_soldier", 	FolderRange = { "_1_suit", "_02_suit", "_3_suit" } },
                ["Females"] 	= { SoundName = "helena_mine_ab4", SoundRange = { "_pu0001", "_pu0002", "_pu0003" }, FolderName = "mine", 	FolderRange = { "" } },
            }

        }

    },

    ---------------------
    Links = {
        [eServerEvent_OnClientInit] = "InitClient",
        [eServerEvent_ScriptTick]   = "OnTick",
    },

    ---------------------
    Init = function(self)

    end,

    ---------------------
    InitClient = function(self, hClient)

        hClient.VoiceData = {

            -- so we dont say the same thing twice
            Sounds = {},

            -- so we dont use random voices for the same model every time
            Voices = {},

            PlayTimer = timernew(),
            FallTimer = timernew()
        }
    end,

    ---------------------
    OnTick = function(self)

        for hID, aInfo in pairs(ServerItemHandler.ProjectileMap or {}) do
            local vExplosive = ServerDLL.GetProjectilePos(hID)
            if (vExplosive and aInfo.Timer.expired(0.3)) then
                for _, hPlayer in pairs(GetPlayers()) do
                    if (aInfo.OwnerID ~= hPlayer.id and (aInfo.Team == 0 or hPlayer:GetTeam() ~= aInfo.Team)) then

                        --- INCOMING EVENT !! im dumb and cant rmember shit hjfksl fdkslö
                        --Debug("Not same team !! !!")

                        if (vector.distance(vExplosive, hPlayer:GetPos()) < 15) then
                            aInfo.SoundTemp = aInfo.SoundTemp or {}
                            if (not table.findv(aInfo.SoundTemp, hPlayer.id)) then
                                table.insert(aInfo.SoundTemp, hPlayer.id)
                                self:ProcessEvent(hPlayer, eVE_IncomingExplosive)
                            end
                            break
                        end
                    end
                end
            end
        end
        for _, hPlayer in pairs(GetPlayers()) do
            local vPlayer = hPlayer:GetPos()
            if (hPlayer.actor:IsFlying() and not IsPointUnderwater(vPlayer) and not hPlayer:IsDead() and not hPlayer:IsSpectating() and hPlayer:GetVehicle()) then

            else
                hPlayer.VoiceData.FallTimer.refresh()
            end

            if (hPlayer.VoiceData.FallTimer.expired(2)) then
                self:ProcessEvent(hPlayer, eEV_EventFalling)
                hPlayer.VoiceData.FallTimer.refresh()
            end
        end

    end,

    ---------------------
    ProcessEvent = function(self, hClient, iEvent)
        if (not hClient.IsPlayer) then
            return
        end

        local aVoiceList = self.Voices[iEvent]

        if (not aVoiceList) then
            return HandleError("Bad sound event " .. g_ts(iEvent) .. "!")
        end

        if (isArray(aVoiceList)) then
            self:PlaySound(hClient, aVoiceList)
        end
    end,

    ---------------------
    GetUniqueRandom = function(self, hClient, iCM, aMap)

        local iRemaining = table.count(hClient.VoiceData.Sounds[iCM])
        if (iRemaining == 0 or not hClient.VoiceData.Sounds[iCM]) then
            hClient.VoiceData.Sounds[iCM] = table.shuffle(table.copy(aMap))
        end

        local hRandom = table.pop(hClient.VoiceData.Sounds[iCM], getrandom(1, table.count(hClient.VoiceData.Sounds[iCM])))
        return hRandom
    end,

    ---------------------
    PlaySound = function(self, hClient, aVoiceMap)

        if (not hClient.VoiceData.PlayTimer.expired(4)) then
            return
        end

        local aVoiceInfo = aVoiceMap

        local iCM = hClient.CM.ID
        if (iCM ~= CM_NONE) then

            if (IsAny(iCM, CM_EGIRL1, CM_EGIRL2, CM_EGIRL3, CM_EGIRL4)) then
                Debug(CM_EGIRL1,CM_EGIRL2,CM_EGIRL3,CM_EGIRL4)
                iCM = "Females"
            end
        elseif (g_gameRules.IS_PS and hClient:GetTeam() == TEAM_NK) then
            iCM = "TeamNK"
        end

        if (iCM ~= CM_NONE) then
            aVoiceInfo = (aVoiceMap.ModelSpecific[iCM] or aVoiceInfo)
        end



        local sSoundName  = aVoiceInfo.SoundName  or aVoiceMap.SoundName  or ""
        local aSoundRange = aVoiceInfo.SoundRange or aVoiceMap.SoundRange or { "" }

        local sFolderName  = aVoiceInfo.FolderName  or aVoiceMap.FolderName  or ""
        local aFolderRange = aVoiceInfo.FolderRange or aVoiceMap.FolderRange or { "" }

        local aPrevious = hClient.VoiceData.Voices[iCM]
        if (not aPrevious) then
            hClient.VoiceData.Voices[iCM] = {
                Folder = getrandom(aFolderRange)
            }
            aPrevious = hClient.VoiceData.Voices[iCM]
        end

        local sRandomFolder = getrandom(aFolderRange)
        local sRandomSound = self:GetUniqueRandom(hClient, iCM, aSoundRange)
        if (aPrevious) then
            sRandomFolder = aPrevious.Folder
        else
            aPrevious.Folder = sRandomFolder
        end

        local sSoundPath = string.format("%s%s/%s%s",
            sFolderName, sRandomFolder,
            sSoundName, sRandomSound
        )

        hClient.VoiceData.PlayTimer.refresh()
        ClientMod:OnAll(string.format([[g_Client:PSE("%s",GP(%d),"taunt",nil,nil,1)]],
                sSoundPath,
                hClient:GetChannel()
        ))

    end,
})