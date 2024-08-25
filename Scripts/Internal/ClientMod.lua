--------------
ClientMod = (ClientMod or {

    JETPACKS_ENABLED = false,

    ModURL = "http://nomad.nullptr.one/~finch/CryMP-Client.lua",
    DevURL = "http://nomad.nullptr.one/~finch/CryMP-Developer.lua",

    Server = {
    },

    Client = {
    },

    SynchedStorage = {
        [NULL_ENTITY] = {},
    },
})

--------------

eCM_Spectator = 0
eCM_Name = 1

--------------

eMPClient_Version = "mp_version"

----
eSvClient_Version       = "sv_version"
eSvClient_InitTimer     = "init_timer"
eSvClient_InstallTimer  = "install_timer"

---------------

eClientResp_OnNotInstalled  = 10
eClientResp_OnInstalled     = 11
eClientResp_OnPAKInstalled  = 12
eClientResp_NoPAKInstalled  = 13

eClientResp_OpenChat = 20
eClientResp_CloseChat = 21

eClientResp_WantEnterLastVehicle = 30

eClientResp_ModifiedCVars = { 40, 50 }

eClientResp_MeleeAttack = 60
eClientResp_StopMelee = 61


eClientResp_JetpackOn = 66
eClientResp_JetpackOff = 67

eClientResp_ChairEffectsOn = 68
eClientResp_ChairEffectsOff = 69
eClientResp_ChairRemove = 70

---------------

CM_NONE         = 0
CM_DEFAULT      = 1
CM_KYONG        = 2
CM_KOREANAI     = 3
CM_AZTEC        = 4
CM_JESTER       = 5
CM_SYKES        = 6
CM_PROPHET      = 7
CM_PSYCHO       = 8
CM_BADOWSKY     = 9
CM_SCIENTIST    = 10
CM_KEEGAN       = 11
CM_EGIRL1       = 12
CM_EGIRL2       = 13
CM_BRADLEY      = 14
CM_RICHARD      = 15
CM_NKPILOT      = 16
CM_GONGPITTER   = 17
CM_EGIRL3       = 18
CM_JUMPSAILOR   = 19
CM_USPILOT      = 20
CM_MARINE       = 21
CM_CORONA       = 22
CM_OFFICER      = 23
CM_TECHNICIAN   = 24
CM_EGIRL4       = 25
CM_ARCHAEOLOGIST = 26
CM_FIREFIGHTER  = 27
CM_WORKER       = 28
CM_ALIEN        = 29
CM_HUNTER       = 30
CM_SCOUT        = 31
CM_SHARK        = 32
CM_DOG          = 33
CM_TROOPER      = 34
CM_CHICKEN      = 35
CM_TURTLE       = 36
CM_CRAB         = 37
CM_FINCH        = 38
CM_TERN         = 39
CM_FROG         = 40
CM_ALIENWORK    = 41
CM_BUTTERFLY    = 42
CM_HEADLESS     = 1000

HEAD_NONE = 0
HEAD_HELENA = 1
HEAD_CHICKEN = 2


VM_TESLA      = 1
VM_AUDI       = 2
VM_DUELER     = 3
VM_FERRARI    = 4
VM_TRAIN      = 5
VM_AIRCRAFT   = 6
VM_NKPLANE    = 7
VM_USPLANE    = 8
VM_CARGOPLANE = 9
VM_TRANSPLANE = 10
VM_PLANE1     = 11
VM_VTOLTRANS  = 12
VM_EXCAVATOR  = 13
VM_FORKLIFT   = 14
VM_MINETRUCK  = 15
VM_CRANE      = 16
VM_WAGON      = 17
VM_BAGGAGECART = 18
VM_SHOPPINGCART = 19
VM_AAA        = 20
VM_APC        = 21
VM_HELI       = 22
VM_TANK       = 23
VM_TANKHEADLESS = 24
VM_TANKTURRET = 25
VM_TRUCK      = 26
VM_CAR        = 27
VM_LTV        = 28
VM_DAUNTLESS  = 29
VM_KUANTI     = 30
VM_SPEEDBOAT  = 31
VM_DESTROYER  = 32
VM_HOVER      = 33
VM_SCIENCESHIP = 34
VM_CARGOSHIP  = 35
VM_SKYFORGE   = 36
VM_NAVYSHIP   = 37
VM_TANKER     = 38
VM_SHARK      = 39
VM_PALM       = 40
VM_ROCK       = 41


---------------
ClientMod.Init = function(self)
    RegisterReset("ClientMod", function() ClientMod.SynchedStorage = {} end)
end

---------------
ClientMod.UpdateClient = function(self, hClient)

    local hVehicle = hClient:GetVehicle()
    local bDead = hClient:IsDead()
    local bSpec = hClient:IsSpectating()

    if (hVehicle or bDead or bSpec) then
        if (hClient.Chair) then
            hClient.Chair:SvPickup(hClient, true)
        end
        hClient.Chair = nil
    end
end

---------------
ClientMod.InitClient = function(self, hClient)

    -------
    hClient.ExecuteRPC = function(this, sMethod, aParams)
        RPC:OnPlayer(this, sMethod, aParams)
    end

    hClient.Execute = function(this, sCode, ...)
        sCode = string.formatex(sCode, ...)
        ClientMod.ExecuteOn({ this }, sCode)
    end
    hClient.ExecuteOthers = function(this, sCode, ...)
        sCode = string.formatex(sCode, ...)
        ClientMod.ExecuteOn(GetPlayers({ NotID = this.id }), sCode)
    end

    -------
    table.checkM(hClient, "CM", { Restored = false, ID = CM_NONE, File = "" })
    table.checkM(hClient, "ClientTemp", {  })

    -------
    ServerLog("ClientMod.InitClient")
    ClientMod:Install(hClient)
end

---------------
ClientMod.StopSync = function(self, hID, sID)

    local hEnt = GetEntity(hID) and GetEntity(hID).id or hID

    table.checkM(self.SynchedStorage, hEnt, {})
    self.SynchedStorage[hEnt][sID] = nil
end


---------------
ClientMod.SyncCode = function(self, hEntityID, sID, sCode_Client, aParams)

    local fCheck   = aParams.Check
    local fAppend  = aParams.Append
    local fServer  = aParams.Server
    local aDepends = aParams.Dependencies

    local aNew = {
        Code = {
            Check  = fCheck,
            Append = fAppend,
            Client = {
                _C = sCode_Client,
                _S = {}
            },
            Server = fServer
        },
        Dependencies = aDepends,
    }

    table.checkM(self.SynchedStorage, hEntityID, {})
    if (hEntityID == NULL_ENTITY) then
        sID = (sID .. UpdateCounter(eCounter_ClientModSync))
    end
    self.SynchedStorage[hEntityID][sID] = aNew
end

---------------
ClientMod.CheckSyncBind = function(self, hID)
    return (GetEntity(hID) ~= nil)
end

---------------
ClientMod.DependenciesOk = function(self, aLis)
    return table.it(aLis, function(x, i, v) return (x == true or x == nil) and (v == NULL_ENTITY or GetEntity(v) ~= nil) end)
end

---------------
ClientMod.SyncPart = function(self, hClient, sCode, bForce)


    local sPart = hClient.SyncStep
    if (string.emptyN(sPart) and (bForce or string.len(sPart) > 512)) then
        hClient.SyncStep = nil
        self.ExecuteOn({ hClient }, sPart)
    end
    hClient.SyncStep = ((hClient.SyncStep or "") .. " " .. sCode)
end

---------------
ClientMod.SyncAll = function(self, hClient)

    local aSS = self.SynchedStorage
    local iOk = 0
    local iDeleted = 0
    local sAppend

    for _, aInfo in pairs(aSS) do
        if (_ == NULL_ENTITY or self:CheckSyncBind(_)) then
            for __, aCode in pairs(aInfo) do
                if ((aCode.Code.Check == nil or aCode.Code.Check(hClient) == true) and (table.empty(aCode.Dependencies) or self:DependenciesOk(aCode.Dependencies))) then
                    if (not aCode.Code.Client._S[hClient.id]) then
                        iOk = iOk + 1
                        sAppend = ""
                        if (aCode.Code.Append) then
                            sAppend = aCode.Code.Append(hClient)
                        end
                        self:SyncPart(hClient, aCode.Code.Client._C .. sAppend)
                        local hServerPart = aCode.Code.Server
                        if (hServerPart) then
                            if (isFunc(hServerPart)) then
                                hServerPart(hClient, aCode)
                            else
                                HandleError("Bad server sync. its not a function!")
                            end
                        end
                    end
                else
                    iDeleted = (iDeleted + 1)
                end
            end
        else
            iDeleted = (iDeleted + 1)
        end
    end

    if (self.JETPACKS_ENABLED) then
        self:SyncPart(hClient, "g_Client:Jetpack("..hClient:GetChannel()..",true)")
    end
    self:SyncPart(hClient, "", true)
    Logger:LogEventTo(RANK_ADMIN, eLogEvent_ClientMod, "@l_ui_clm_syncFinished", hClient:GetName(), iDeleted, iOk)
end

---------------
ClientMod.OnAll = function(self, sCode, aParams, xCode)

    if (aParams) then
        if (aParams.Sync) then
            local sSyncID  = (aParams.SyncID or "sync_" .. UpdateCounter(eCounter_ClientModSync))
            local hLinkID  = (aParams.BindID or NULL_ENTITY)
            local aDepends = (aParams.Dependencies or {})
            local fCheck   = aParams.Check
            self:SyncCode(hLinkID, sSyncID, sCode, aParams)
        end

        -- Wat?
        if (aParams.StoreOnly) then
            return
        end
    end

    self.ExecuteOn(GetPlayers(), sCode .. (xCode or ""))
end

---------------
ClientMod.ExecuteOn = function(aClients, sCode)

    -------
    if (sCode == nil) then
        throw_error("no code")
    end
    if (not string.fc(sCode, "L:")) then
        sCode = "L:" .. sCode
    end

    for _, hPlayer in pairs(aClients) do

        UpdateCounter(eCounter_ClientMod)
        g_gameRules.onClient:ClWorkComplete(hPlayer:GetChannel(), hPlayer.id, sCode)
        ServerLog("Executing %s",sCode)
    end
end

---------------
ClientMod.Install = function(self, hClient, bDeveloper)

    hClient.ClientInstallTimer = timernew()

    hClient:ExecuteRPC("Execute", { url = self.ModURL })
    if (hClient:IsTesting() or bDeveloper) then
        hClient:ExecuteRPC("Execute", { url = self.DevURL })
    end

    hClient:SetClientMod("IsInstalled", false)
    Logger:LogEventTo(RANK_ADMIN, eLogEvent_ClientMod, "@l_ui_clm_InstallStart", hClient:GetName())
end

---------------
ClientMod.OnInstalled = function(self, hClient)

    local iTime = math.calctime(hClient.ClientInstallTimer.diff(), nil, 2)
    Logger:LogEventTo(RANK_ADMIN, eLogEvent_ClientMod, "@l_ui_clm_Installed", hClient:GetName(), iTime)
    hClient:SetClientMod("IsInstalled", true)

    --fixme: code queue
    self:SyncAll(hClient)
end

---------------
ClientMod.OnPakInstalled = function(self, hClient)

    Logger:LogEventTo(RANK_ADMIN, eLogEvent_ClientMod, "@l_ui_clm_InstalledPak", hClient:GetName())

    --fixme: code queue
end

---------------
ClientMod.OnPakFailed = function(self, hClient)

    Logger:LogEventTo(RANK_ADMIN, eLogEvent_ClientMod, "@l_ui_clm_NotInstalledPak", hClient:GetName())

    --fixme: code queue
end

---------------
ClientMod.OnInstallFailed = function(self, hClient)

    local iTime = math.calctime(hClient.ClientInstallTimer.diff(), nil, 2)
    Logger:LogEventTo(RANK_ADMIN, eLogEvent_ClientMod, "@l_ui_clm_InstalledFailed", hClient:GetName(), iTime)
end

---------------
ClientMod.OnClientError = function(self, hClient, sType, sError)

    local sCode, sErr
    if (sType == "EXECUTE") then

        sCode, sErr = string.match(sError,"^{(.*)}={(.*)}$")
        if (sErr) then
            sErr = string.gsub(sErr, "^%[%w+ \".*\"%]:", "")
        end

        Logger:LogEventTo(RANK_ADMIN, eLogEvent_ClientMod, "@l_ui_clm_ExecError", hClient:GetName())
        Logger:LogEventTo(RANK_ADMIN, eLogEvent_ScriptError, "Code: " .. (sCode or "N/A"))
        Logger:LogEventTo(RANK_ADMIN, eLogEvent_ScriptError, "Error: " .. (sErr or "N/A"))
    end
end

---------------
ClientMod.DecodeResponse = function(self, hClient, iType, ...)

    if (iType == eCM_Spectator) then
        return self:DecodeSpecRequest(hClient, ...)

    elseif (iType == eCM_Name) then
        return self:DecodeNameRequest(hClient, ...)

    else
        throw_error("bad type to decode()")
    end
end

---------------
ClientMod.DecodeSpecRequest = function(self, hClient, iMessage)
    local bResolved = true
    local hWeapon = hClient:GetCurrentItem()
    local hFists = hClient:GetItemByClass("Fists")
    local sWeapon = hWeapon and hWeapon.class or ""
    local hRHEntity, aRH
    local bMeleeFix = IsAny(sWeapon,
        "RadarKit", "RepairKit", "Lockpick",
            "AVMine", "Claymore", "C4"
    )

    if (iMessage == eClientResp_OnInstalled) then
        self:OnInstalled(hClient)

    elseif (iMessage == eClientResp_OnNotInstalled) then
        self:OnInstallFailed(hClient)

    elseif (iMessage == eClientResp_OnPAKInstalled) then
        self:OnPakInstalled(hClient)

    elseif (iMessage == eClientResp_NoPAKInstalled) then
        self:OnPakFailed(hClient)

    elseif (iMessage == eClientResp_OpenChat) then
        self:ChatEffect(hClient,true)

    elseif (iMessage == eClientResp_CloseChat) then
        self:ChatEffect(hClient,false)

    elseif (iMessage == eClientResp_WantEnterLastVehicle) then
        if (hClient:GetLastVehicle()) then
            hClient:EnterLastVehicle()
        end

    elseif (iMessage > eClientResp_ModifiedCVars[1] and iMessage < eClientResp_ModifiedCVars[2]) then
        self:OnModifiedCVar(hClient, iMessage)

    elseif (iMessage == eClientResp_MeleeAttack or iMessage == eClientResp_StopMelee) then
        if (iMessage == eClientResp_MeleeAttack) then
            if (bMeleeFix) then
                Debug("melee on otehrs")
                ClientMod:OnAll(string.format([[g_Client:ANIM(%d,"combat_weaponPunchUB_dualpistol_01")]], hClient:GetChannel()))
            end
            if (hFists) then
                aRH = hClient:GetHitPos(2)
                hRHEntity = aRH and aRH.entity
                if (hRHEntity) then
                    hClient:CreateHit({
                        Pos = aRH.pos,
                        Dir = aRH.dir,
                        Normal = aRH.normal,
                        Type = "melee",
                        Shooter = hClient,
                        Target = hRHEntity,
                        Material = "mat_torso",
                        Damage = 90,
                        Radius = 0,
                        Part = 23,
                    })
                end
                hFists.weapon:Sv_Melee()
            end
        end

    elseif (iMessage == eClientResp_JetpackOn or iMessage == eClientResp_JetpackOff) then
        self:JetPackEffects(hClient, (iMessage == eClientResp_JetpackOn))

    elseif (iMessage == eClientResp_ChairRemove) then
        if (hClient.Chair) then
            hClient.Chair:SvPickup(hClient, true)
        end

    elseif (iMessage == eClientResp_ChairEffectsOn or iMessage == eClientResp_ChairEffectsOff) then
        self:ChairEffects(hClient, iMessage == eClientResp_ChairEffectsOn)

    else
        Logger:LogEventTo(RANK_DEVELOPER, eLogEvent_ClientMod, "@l_ui_clm_invalidResponse", hClient:GetName(),g_tn(iMessage or 0))
        bResolved = false
    end

    return (bResolved == true)
end

---------------
ClientMod.JetPackEffects = function(self, hClient, enable)
    ClientMod:OnAll(string.format([[g_Client:Jetpack_Effects(%d,%s)]], hClient:GetChannel(),g_ts(enable)), {
        Sync = true,
        SyncID = "jetpack_effects",
        BindID = hClient.id,
        Check = function() return hClient.HasJetPack  end
    })
end


---------------
ClientMod.ChairEffects = function(self, hClient, enable)

    if (enable and not hClient.Chair) then
        return
    end

    ClientMod:OnAll(string.format([[g_Client:FlyingChar_Effects(%d,%s)]], hClient:GetChannel(),g_ts(enable)), {
        Sync = true,
        SyncID = "chair_effects",
        BindID = hClient.id,
        Check = function() return hClient.Chair ~= nil  end
    })
end

---------------
ClientMod.RemoveJetpack = function(self, hClient)
    if (not hClient.HasJetPack) then
        return
    end

    self:OnAll(string.format([[g_Client:Jetpack(%d,false)]], hClient:GetChannel()))
    self:StopSync(hClient, "jetpack")
    self:StopSync(hClient, "jetpack_effects")
    hClient.HasJetPack = false
end

---------------
ClientMod.EquipJetpack = function(self, hClient)
    if (hClient.HasJetPack) then
        return
    end

    self:OnAll(string.format([[g_Client:Jetpack(%d,true)]], hClient:GetChannel()), {
        Sync = true,
        SyncID = "jetpack",
        BindID = hClient.id,
        Check = function() return hClient.HasJetPack  end
    })
    hClient.HasJetPack = true
end

---------------
ClientMod.ChatEffect = function(self, hClient, enable)

    local iChannel = hClient:GetChannel()
    if (not enable) then
        if (hClient.ChatOpen) then
            self:OnAll(string.format([[g_Client:ChatEffect(%d,0)]], iChannel))
        end
    elseif (enable and not hClient.ChatOpen) then
        hClient.ChatEffectSync = self:OnAll(string.format([[g_Client:ChatEffect(%d,1)]], iChannel), {
            BindID = hClient.id,
            Sync = true,
            SyncID = "chateffect",
            Check = function(x)Debug("OPEN:",hClient.ChatOpen) return hClient.ChatOpen == true  end
        })
    end

   -- Debug("OPEN:",hClient.ChatOpen)
    hClient.ChatOpen = enable
end

---------------
ClientMod.GetModels = function()

    local aModels = {
        [CM_DEFAULT]    = { "Nomad", "objects/characters/human/us/nanosuit/nanosuit_us_multiplayer.cdf" , true},
        [CM_KYONG]      = {"General Kyong", "objects/characters/human/story/Kyong/Kyong.cdf", true},
        [CM_KOREANAI]   = {"Korean AI", { "objects/characters/human/asian/nk_soldier/nk_soldier_camp_cover_heavy_04.cdf", "objects/characters/human/asian/nk_soldier/nk_soldier_camp_cover_heavy_05.cdf", "objects/characters/human/asian/nk_soldier/nk_soldier_camp_cover_heavy_07.cdf", "objects/characters/human/asian/nk_soldier/nk_soldier_camp_cover_heavy_09.cdf", "objects/characters/human/asian/nk_soldier/nk_soldier_camp_cover_light_01.cdf", "objects/characters/human/asian/nk_soldier/nk_soldier_camp_cover_light_02.cdf", "objects/characters/human/asian/nk_soldier/nk_soldier_camp_light_leader_04.cdf", "objects/characters/human/asian/nk_soldier/nk_soldier_camp_light_leader_02.cdf", "objects/characters/human/asian/nk_soldier/nk_soldier_camp_light_leader_03.cdf", }},
        [CM_AZTEC]      = {"Aztec", "objects/characters/human/story/Harry_Cortez/harry_cortez_chute.cdf", 1},
        [CM_JESTER]     = {"Jester", "objects/characters/human/story/Martin_Hawker/Martin_Hawker.cdf", 1},
        [CM_SYKES]      = {"Sykes", "objects/characters/human/story/Michael_Sykes/Michael_Sykes.cdf", 1},
        [CM_PROPHET]    = {"Prophet", "objects/characters/human/story/Laurence_Barnes/Laurence_Barnes.cdf", 1},
        [CM_PSYCHO]     = {"Psycho", "objects/characters/human/story/michael_sykes/Michael_Sykes.cdf", 1},
        [CM_BADOWSKY]   = {"Badowsky", "objects/characters/human/story/badowsky/Badowsky.cdf"},
        [CM_SCIENTIST]  = {"Scientist", "objects/characters/human/story/female_scientist/female_scientist.cdf"},
        [CM_KEEGAN]     = {"Keegan", "Objects/characters/human/story/keegan/keegan.cdf"},
        [CM_EGIRL1]     = {"Journalist", "objects/characters/human/story/Journalist/journalist.cdf"},
        [CM_EGIRL2]     = {"Dr Rosenthal", "objects/characters/human/story/Dr_Rosenthal/Dr_Rosenthal.cdf"},
        [CM_BRADLEY]    = {"Lt Bradley", "objects/characters/human/story/Lt_Bradley/Lt_Bradley_radio.cdf"},
        [CM_RICHARD]    = {"Richard M", "objects/characters/human/story/Richard_Morrison/morrison_with_hat.cdf"},
        [CM_NKPILOT]    = {"NK Pilot", "objects/characters/human/asian/pilot/koreanpilot.cdf"},
        [CM_GONGPITTER] = {"Gong Pitter", "objects/characters/human/us/fire_fighter/green_cleaner.cdf"},
        [CM_EGIRL3]     = {"Shemad", "objects/characters/human/story/helena_rosenthal/helena_rosenthal.cdf"},
        [CM_JUMPSAILOR] = {"Jump Sailor", "objects/characters/human/us/jumpsuitsailor/jumpsuitsailor.cdf"},
        [CM_USPILOT]    = {"Navy Pilot", "objects/characters/human/us/navypilot/navypilot.cdf"},
        [CM_MARINE]     = {"Marine", { "objects/characters/human/us/marine/marine_01.cdf", "objects/characters/human/us/marine/marine_02.cdf", "objects/characters/human/us/marine/marine_03.cdf", "objects/characters/human/us/marine/marine_04.cdf", "objects/characters/human/us/marine/marine_05.cdf", "objects/characters/human/us/marine/marine_06.cdf", "objects/characters/human/us/marine/marine_07.cdf", "objects/characters/human/us/marine/marine_08.cdf", "objects/characters/human/us/marine/marine_09.cdf", "objects/characters/human/us/marine/marine_01_helmet_goggles_off.cdf", "objects/characters/human/us/marine/marine_02_helmet_goggles_off.cdf", "objects/characters/human/us/marine/marine_03_helmet_goggles_off.cdf", "objects/characters/human/us/marine/marine_04_helmet_goggles_off.cdf", "objects/characters/human/us/marine/marine_05_helmet_goggles_off.cdf", "objects/characters/human/us/marine/marine_01_helmet_goggles_on.cdf", "objects/characters/human/us/marine/marine_02_helmet_goggles_on.cdf", "objects/characters/human/us/marine/marine_03_helmet_goggles_on.cdf", "objects/characters/human/us/marine/marine_04_helmet_goggles_on.cdf", "objects/characters/human/us/marine/marine_05_helmet_goggles_on.cdf", }},
        [CM_CORONA]     = {"Corona Guy", { "objects/characters/human/asian/scientist/chinese_scientist_01.cdf", "objects/characters/human/asian/scientist/chinese_scientist_02.cdf", "objects/characters/human/asian/scientist/chinese_scientist_03.cdf", "objects/characters/human/asian/scientist/chinese_scientist_01_hazardmask.cdf", "objects/characters/human/asian/scientist/chinese_scientist_02_hazardmask.cdf", "objects/characters/human/asian/scientist/chinese_scientist_03_hazardmask.cdf", }},
        [CM_OFFICER]    = {"Officer", { "objects/characters/human/us/officer/officer_01.cdf", "objects/characters/human/us/officer/officer_02.cdf", "objects/characters/human/us/officer/officer_03.cdf", "objects/characters/human/us/officer/officer_04.cdf", "objects/characters/human/us/officer/officer_05.cdf", "objects/characters/human/us/officer/officer_afroamerican_01.cdf", "objects/characters/human/us/officer/officer_afroamerican_02.cdf", "objects/characters/human/us/officer/officer_afroamerican_03.cdf", "objects/characters/human/us/officer/officer_afroamerican_04.cdf", "objects/characters/human/us/officer/officer_afroamerican_05.cdf", "objects/characters/human/us/officer/officer_afroamerican_01.cdf", "objects/characters/human/us/officer/officer_afroamerican_02.cdf", "objects/characters/human/us/officer/officer_afroamerican_03.cdf", "objects/characters/human/us/officer/officer_afroamerican_04.cdf", }},
        [CM_TECHNICIAN] = {"Technician", { "objects/characters/human/asian/technician/technician_01.cdf", "objects/characters/human/asian/technician/technician_02.cdf" }},
        [CM_EGIRL4]     = {"Archaeologist", { "objects/characters/human/us/archaeologist/archaeologist_female_01.cdf", "objects/characters/human/us/archaeologist/archaeologist_female_02.cdf", }},
        [CM_ARCHAEOLOGIST] = {"Archaeologist", { "objects/characters/human/us/archaeologist/archaeologist_male_01.cdf", "objects/characters/human/us/archaeologist/archaeologist_male_02.cdf", }},
        [CM_FIREFIGHTER] = {"Firefighter", { "objects/characters/human/us/fire_fighter/firefighter.cdf", "objects/characters/human/us/fire_fighter/firefighter_helmet.cdf", "objects/characters/human/us/fire_fighter/firefighter_silver.cdf", "objects/characters/human/us/fire_fighter/firefighter_silver_mask.cdf", "objects/characters/human/us/fire_fighter/firefighter_silver_maskvs2.cdf", }},
        [CM_WORKER]     = {"Deckhander", { "objects/characters/human/us/deck_handler/deck_handler_grape_helmet.cdf", "objects/characters/human/us/deck_handler/deckhand_blue.cdf", "objects/characters/human/us/deck_handler/deckhand_brown.cdf", "objects/characters/human/us/deck_handler/deckhand_grape.cdf", "objects/characters/human/us/deck_handler/deckhand_green.cdf", "objects/characters/human/us/deck_handler/deckhand_red.cdf", "objects/characters/human/us/deck_handler/deckhand_white.cdf", "objects/characters/human/us/deck_handler/deckhand_blue2.cdf", "objects/characters/human/us/deck_handler/deckhand_yellow.cdf", "objects/characters/human/us/deck_handler/deckhand_brown2.cdf", "objects/characters/human/us/deck_handler/deckhand_grape2.cdf", "objects/characters/human/us/deck_handler/deckhand_green2.cdf", "objects/characters/human/us/deck_handler/deckhand_red2.cdf", "objects/characters/human/us/deck_handler/deckhand_white2.cdf", "objects/characters/human/us/deck_handler/deckhand_yellow2.cdf", }},
        [CM_ALIEN]      = {"Alien", "objects/characters/alien/alienbase/alienbase.cdf" },
        [CM_HUNTER]     = {"Hunter", "objects/characters/alien/hunter/hunter.cdf" },
        [CM_SCOUT]      = {"Scout", "objects/characters/alien/scout/scout_leader.cdf" },
        [CM_SHARK]      = {"Shark", "objects/characters/animals/Whiteshark/greatwhiteshark.cdf"},
        [CM_DOG]        = {"Dog or sum", "Objects/characters/alien/trooper/trooper_base.chr" },
        [CM_TROOPER]    = {"Alien Trooper", "objects/characters/alien/trooper/trooper_leader.chr" },
        [CM_CHICKEN]    = {"Chicken", "objects/characters/animals/birds/chicken/chicken.chr" },
        [CM_ALIENWORK]  = {"Alien", "objects/characters/alien/alienbase/alienbase.cdf" },
        [CM_TURTLE]     = {"Turtle", "objects/characters/animals/turtle/turtle.cdf" },
        [CM_CRAB]       = {"Crab", "objects/characters/animals/crab/crab.cdf" },
        [CM_FINCH]      = {"Finch", "objects/characters/animals/birds/plover/plover.cdf" },
        [CM_TERN]       = {"Tern", "Objects/characters/animals/birds/tern/tern.chr" },
        [CM_FROG]       = {"Frog", "objects/characters/animals/frog/frog.chr" },
        [CM_BUTTERFLY]  = {"Butterfly", "objects/characters/animals/insects/butterfly/butterfly_brown.chr" },
        [CM_HEADLESS]   = { "Headless", "MODEL_NOMAD_HEADLESS" }, --"CryMP-Objects/characters/nomad/headless.cdf" }
    }
    return aModels
end
----------
ClientMod.GetCharacters = function(self)
    local aCharacters = {
        { "Alien Trooper", 	CM_TROOPER, { "Fists", "FastLightMOAC" } },
        { "Alien Worker", 	CM_ALIEN,   { "Fists", "FastLightMOAC" } },
        { "Shark", 	        CM_SHARK,   { "Fists" } },
        { "Chicken",        CM_CHICKEN, { "Fists" } },
        { "Turtle",	        CM_TURTLE,  { "Fists" } },
        { "Crab", 	        CM_CRAB,    { "Fists" } },
        { "Finch", 	        CM_FINCH,   { "Fists" } },
        { "Tern", 	        CM_TERN,    { "Fists" } },
        { "Frog", 	        CM_FROG,    { "Fists" } },
        { "Butterfly", 	        CM_BUTTERFLY,    { "Fists" } },
    }
    return aCharacters
end
----------
ClientMod.GetHeads = function(self)
    local aHeads = {
        [HEAD_HELENA]   = { "Helena's Head" },
        [HEAD_CHICKEN]  = { "Chicken Head" },
    }
    return aHeads
end

---------------
ClientMod.RequestCharacter = function(self, hClient, iCharacter, bQuiet)

    local aChars = self:GetCharacters()
    if (iCharacter == 0) then
        if (hClient.CM.ID == CM_NONE) then
            return false, hClient:Localize("@l_ui_youHaveNoCM")
        end

        hClient:SetAllowedEquip(eAllowedEquip_All)
        self:RequestModel(hClient, 0)

        SendMsg(CHAT_SERVER_LOCALE, ALL_PLAYERS, "@l_ui_CMCharRemoved", hClient:GetName() )
        hClient:Revive(1, 1)
        return true
    end

    local aInfo = aChars[iCharacter]
    if (not aInfo) then

        ListToConsole({
            Client      = hClient,
            List        = table.sortI(aChars),
            Title       = hClient:Localize("@l_ui_CMList"),
            ItemWidth   = 15,
            PerLine     = 5,
            PrintIndex  = true,
            Index       = 1
        })
        return true, hClient:LocalizeNest("@l_ui_CMListedInConsole", { table.count(aChars) })
    end

    if (hClient.CM.ID == iCharacter) then
        return false, hClient:Localize("@l_ui_chooseDifferentCM", {aInfo[1]})
    end

    if (not bQuiet) then
        SendMsg(CHAT_SERVER_LOCALE, hClient, "@l_ui_CMHumanTip", aInfo[1])
        SendMsg(CHAT_SERVER_LOCALE, ALL_PLAYERS, "@l_ui_playerCM", hClient:GetName(), aInfo[1], "")
    end

    hClient.CM.IsCharacter = true
    self:RequestModel(hClient, aInfo[2], true, true)
    hClient:SetAllowedEquip(aInfo[3] or eAllowedEquip_All, hClient:LocalizeNest("@l_ui_CMEquipBlock", {aInfo[1]}))
    hClient.inventory:Destroy()
    for _, sClass in pairs(aInfo[3]) do hClient:GiveItem(sClass) end
end

---------------
ClientMod.RequestHead = function(self, hClient, iRequestedHead, bQuiet)

    local iHead = hClient.CM.HeadID
    local aList = self:GetHeads()
    local iChannel = hClient:GetChannel()
    local iCurrentSeat = hClient:GetVehicleSeatId() or -1

    if (hClient.CM.ID ~= CM_HEADLESS and hClient.CM.ID ~= CM_NONE) then
        return false, hClient:Localize("@l_ui_cannotUseCMHead", {hClient.CM.Name})
    end

    if (iRequestedHead and iRequestedHead == HEAD_NONE) then
        if (iHead == CM_NONE) then
            return false, "@l_ui_youHaveNoCM_Head"
        end

        hClient.CM.HeadID = CM_NONE
        self:OnAll("g_Client:RequestHead(" .. iChannel .. ",0)")

        --hack
        hClient.CM.ID = 6969
        self:RequestModel(hClient,0)

        --hClient:SetData(ePlayerData_CMHead, CM_NONE)
        return true, hClient:Localize("@l_ui_CMHeadRemoved")
    elseif (iRequestedHead == nil or iRequestedHead < 1 or iRequestedHead > table.count(aList) or aList[iRequestedHead] == nil) then

        ListToConsole({
            Client      = hClient,
            List        = table.sortI(aList),
            Title       = hClient:Localize("@l_ui_CMHeadList"),
            ItemWidth   = 15,
            PerLine     = 5,
            PrintIndex  = true,
            Index       = 1
        })
        return true, hClient:LocalizeNest("@l_ui_CMHeadsListedInConsole", { table.count(aList) })
    end

    local aInfo = aList[iRequestedHead]
    local sName = aInfo[1]

    if (iHead == iRequestedHead) then
        return false, hClient:Localize("@l_ui_chooseDifferentCM", {sName})
    end

    local sCode = string.format([[
    local chan = %d
    local id = %d
    local headless_id = %d
    g_Client:RequestModel(chan,headless_id,MODEL_NOMAD_HEADLESS)
    g_Client:RequestHead(chan,id)
    ]], iChannel, iRequestedHead, CM_HEADLESS)

    local function fSeatFix()
        local iSeat = hClient:GetVehicleSeatId()
        if (iSeat) then
            return "g_Client:ReEnterVehicle(" .. iChannel .. "," .. iSeat .. ",1)"
        end
        return ""
    end

    self:OnAll(sCode, {
        Sync = true,
        SyncID = "head", --"model" ??
        BindID = hClient.id,
        Check = function() return hClient.CM.ID == CM_NONE and hClient.CM.HeadID ~= CM_NONE end,
        Append = fSeatFix
    }, fSeatFix())

    hClient.CM.HeadID = iRequestedHead
    hClient:SetData(ePlayerData_CMHead, iRequestedHead)

    if (not bQuiet) then
        SendMsg(CHAT_SERVER_LOCALE, ALL_PLAYERS, "@l_ui_playerCMHead", hClient:GetName(), sName)
    end
end

---------------
ClientMod.RequestModel = function(self, hClient, iModel, bQuiet, bIsChar)

    local iCM = hClient.CM.ID
    local aList = self:GetModels()
    local iChannel = hClient:GetChannel()
    local iCurrentSeat = hClient:GetVehicleSeatId() or -1

    if (iModel and iModel == CM_NONE) then
        if (iCM == CM_NONE) then
            return false, "@l_ui_youHaveNoCM"
        end

        hClient.CM.ID = CM_NONE
        hClient.CM.IsCharacter = false
        hClient.CM.File = nil
        self:OnAll("g_Client:RequestModel(" .. iChannel .. ",0,nil,nil," .. (iCurrentSeat or -1) .. ")")
        hClient:SetData(ePlayerData_CM, CM_NONE)
        return true, hClient:Localize("@l_ui_CMRemoved")
    elseif (iModel == nil or iModel < 1 or iModel > table.count(aList) or aList[iModel] == nil) then

        ListToConsole({
            Client      = hClient,
            List        = table.sortI(aList),
            Title       = hClient:Localize("@l_ui_CMList"),
            ItemWidth   = 15,
            PerLine     = 5,
            PrintIndex  = true,
            Index       = 1
        })
        return true, hClient:LocalizeNest("@l_ui_CMListedInConsole", { table.count(aList) })
    end

    local aInfo = aList[iModel]
    local sName = aInfo[1]
    local sPath = aInfo[2]
    if (isArray(sPath)) then
        sPath = getrandom(sPath)
    end

    if (iCM == iModel) then
        return false, hClient:Localize("@l_ui_chooseDifferentCM", {sName})
    end

    local sPlay = (bQuiet and "" or self:GetCMGreet(iModel))
    local sCode = string.format([[
    local p,c,s,i="%s",%d,"%s",%d
    g_Client:RequestHead(c,0)
    g_Client:RequestModel(c,i,p,s,%d)
    ]], sPath, iChannel, g_ts(sPlay), iModel, iCurrentSeat)

    local function fSeatFix()
        local iSeat = hClient:GetVehicleSeatId()
        if (iSeat) then
            return "g_Client:ReEnterVehicle(" .. iChannel .. "," .. iSeat .. ",1)"
        end
        return ""
    end

    self:OnAll(sCode, {
        Sync = true,
        SyncID = "model",
        BindID = hClient.id,
        Check = function() return hClient.CM.ID ~= CM_NONE end,
        Append = fSeatFix
    }, fSeatFix())

    hClient.CM.HeadID = CM_NONE
    hClient.CM.ID = iModel
    hClient.CM.File = sPath
    hClient.CM.IsCharacter = bIsChar

    if (not bIsChar) then
        hClient:SetData(ePlayerData_CM, iModel)
    end

    if (not bQuiet) then
        SendMsg(CHAT_SERVER_LOCALE, ALL_PLAYERS, "@l_ui_playerCM", hClient:GetName(), sName, "")
    end
end

---------------
ClientMod.GetCMGreet = function(self, iModel)
    local aRng = {"01", "02", "03", "04", "05",}
    local sFile = "greets_"
    local sPath = "ai_marine_1/"

    if (iModel == CM_KYONG) then -- or c == 2
        sPath = "ai_kyong/"
        sFile = "aidowngroup_"
        aRng = {"04", "05",}

    elseif (iModel == CM_KOREANAI) then
        sPath = "ai_korean_soldier_3/"
        sFile = "contactsoloclose_"
        aRng = {"01", "02", "03", "04", "05",}

    elseif (iModel == CM_JESTER) then
        sPath = "ai_jester/"
        aRng = {"01", "02", "03", "04", "05",}

    elseif (iModel == CM_PSYCHO) then
        sPath = "ai_psycho/"
        sFile = "contactsoloclose_"
        aRng = {"01",}

    elseif (iModel == CM_PROPHET) then
        sPath = "ai_prophet/"
        aRng = {"00", "04",}

    elseif (iModel == CM_MARINE) then
        sPath = "ai_marine_1/"
        aRng = {"01", "02", "03", "04", "05",}

    else
    end

    local sFilePath = "languages/dialog/" .. sPath .. sFile .. getrandom(aRng) .. ".mp2"
    return sFilePath
end

---------------
ClientMod.OnModifiedCVar = function(self, hClient, iCVar)

    local iStart = eClientResp_ModifiedCVars[1]
    local aList = {
        [iStart + 1] = { "R_ATOC" }
    }

    --FIXME: Locale
    Logger:LogEventTo(GetPlayers({ Access = hClient:GetElevatedAccess(RANK_MODERATOR) }), eLogEvent_ClientMod, "Illegal CVar " .. (aList[g_tn(iCVar)] or {"Unknown"})[1])
end

---------------
ClientMod.OnMelee = function(self, hClient)
    if (hClient.CM.ID ~= CM_NONE) then
        if (not hClient.MeleeTimer or hClient.MeleeTimer.expired(2)) then
            self:OnAll("local p=GP("..hClient:GetChannel()..")if(not p)then return end g_Client.AnimationHandler:OnAnimationEvent(p,eCE_AnimMelee)")
            hClient.MeleeTimer = timernew()
        end
    end
end

---------------
ClientMod.GetVehicleModels = function(self)

    local makeVec = vector.make

    local aList = {
        [VM_TESLA]      = { "Tesla",            { "objects/library/vehicles/cars/car_b_chassi.cgf", 							{ x = 0, y = 0.350, z = 0.30 }, makeVec(0,0,0),			false,		 nil }},
        [VM_AUDI]       = { "Audi R8",			{ "objects/library/vehicles/cars/car_a.cgf", 									{ x = 0, y = 0.350, z = 0.50 }, makeVec(0,0,0),			false,		  }},
        [VM_DUELER]     = { "Düler",         { "objects/library/vehicles/mining_train/mining_locomotive.cgf",				{ x = 0, y = 0.0, z = 0.2 }, makeVec(0,0,-1.5727),			false,		  }},
        [VM_FERRARI]    = { "Ferrari",			{ "objects/library/vehicles/ship/roofed_rowing_boat/ship.cgf",				    { x = 0, y = 0.8, z = -0.1 }, makeVec(0,0,0),			false,		  }},
        [VM_TRAIN]      = { "Disel Train",		{ "objects/library/vehicles/diesel_train_engine/diesel_train_engine.cgf",		{ x = 0, y = 0.350, z = 0.10 }, makeVec(0,0,-1.5727),			false,		  }},
        [VM_AIRCRAFT]   = { "Aircraft",			{ "Objects/library/vehicles/aircraft/aircraft.cgf", 							{ x = 0, y = -0.00, z = -0.00 }, makeVec(0,0,0),			false, 		  }},
        [VM_NKPLANE]    = { "NK Fighter",       { "objects/vehicles/asian_fighter/asian_fighter.cgf",							{ x = 0, y = -1, z = 1 }, makeVec(0,0,0),			false, 		  }},
        [VM_USPLANE]    = { "US Fighter",       { "objects/vehicles/us_fighter_b/us_fighter.cgf",								{ x = 0, y = -1, z = -1.4 }, makeVec(0,0,3.14),			false, 		  }},
        [VM_CARGOPLANE] = { "Cargo Plane",		{ "objects/vehicles/us_cargoplane/us_cargoplane_open.cgf", 						{ x = 0, y = -21.0, z = -5.8 }, makeVec(0,0,-1.5727), 	false,		  }},
        [VM_TRANSPLANE] = { "Transport Plane",	{ "objects/library/vehicles/asian_transport_plane/asian_transport_plane.cgf",	{ x = 0, y = -10.40, z = -2.0 }, makeVec(0,0,-1.5727),			false,		  }},
        [VM_PLANE1]     = { "AWACS",            { "objects/library/vehicles/north_korean_awacs/nk_awacs.cgf",					{ x = 0, y = 00000, z = 5 }, makeVec(0,0,-1.5727),			false,		  }},
        [VM_VTOLTRANS]  = { "Transport VTOL",   { "objects/vehicles/us_vtol_transport/us_vtol_transport.cga",					{ x = 0, y = 0.0000, z = -4.10 }, makeVec(0,0,0),			false,		 nil }},


        [VM_EXCAVATOR]      = { "Excavator",		{ "objects/library/vehicles/excavator/excavator.cgf",							{ x = 0, y = 0.0, z = 0.0 }, makeVec(0,0,-1.5727),			false,		  }},
        [VM_FORKLIFT]       = { "Forklift",			{ "objects/library/vehicles/forklift/forklift.cgf",								{ x = 0, y = 1.2, z = 0.0 }, makeVec(0,0,-1.5727),			false,		  }},
        [VM_MINETRUCK]      = { "Mine Truck",	    { "objects/library/vehicles/mine_truck/mine_truck.cgf",							{ x = 0, y = 0.0, z = 0.0 }, makeVec(0,0,-1.5727),			false,		  }},
        [VM_CRANE]          = { "Crane",			{ "objects/library/vehicles/mobile_crane/mobile_crane.cga",						{ x = 0, y = 0.0, z = 0.0 }, makeVec(0,0,0),			false,		  }},
        [VM_WAGON]          = { "Wagon",			{ "objects/library/vehicles/rail_trailer/trans_wagon_4_wheel.cgf",		{ x = 0, y = 0.0, z = 0.0 }, makeVec(0,0,0),			false,		  }},
        [VM_BAGGAGECART]    = { "Cart",				{ "objects/library/vehicles/baggage_truck/baggage_cart.cgf",		{ x = 0, y = 0.0, z = 0.0 }, makeVec(0,0,0),			false,		  }},
        [VM_SHOPPINGCART]   = { "Shopping Cart",	{ "objects/library/props/misc/shopping_cart/shopping_cart.cgf",		{ x = 0, y = 0.0, z = 0.0 }, makeVec(0,0,0),			false,		  }},
        [VM_AAA]            = { "AAA",				{ "Objects/Vehicles/asian_aaa/asian_aaa.cga",		{ x = 0, y = 0.0, z = 0.0 }, makeVec(0,0,0),			false,		  }},
        [VM_APC]            = { "APC",				{ "objects/vehicles/asian_apc/asian_apc.cgf",		{ x = 0, y = 0.0, z = 0.0 }, makeVec(0,0,-1.574),			false,		  }},
        [VM_HELI]           = { "Heli",				{ "objects/vehicles/asian_helicopter/asian_helicopter.cgf",		{ x = 0, y = 0.0, z = 0.0 }, makeVec(0,0,0),			false,		  }},
        [VM_TANK]           = { "Tank",				{ "objects/vehicles/asian_tank/asian_tank.cga",		{ x = 0, y = 0.0, z = 0.0 }, makeVec(0,0,0),			false,		  }},
        [VM_TANKHEADLESS]   = { "Headless Tank ",	{ "objects/vehicles/asian_tank/frozen_asian_tank_chassis.cgf",		{ x = 0, y = 0.0, z = 0.0 }, makeVec(0,0,-1.5727),			false,		  }},
        [VM_TANKTURRET]     = { "Tank Turret ",		{ "objects/vehicles/asian_tank/frozen_asian_tank_turret.cgf",		{ x = 0, y = 1.0, z = 0.2 }, makeVec(0,0,-1.5727),			false,		  }},
        [VM_TRUCK]          = { "Truck",			{ "objects/vehicles/asian_truck_b/asian_truck_b.cga",		{ x = 0, y = 0.0, z = 0.0 }, makeVec(0,0,0),			false,		  }},
        [VM_CAR]            = { "Car",				{ "objects/vehicles/civ_car1/civ_car.cgf",		{ x = 0, y = 0.0, z = 0.0 }, makeVec(0,0,0),			false,		  }},
        [VM_LTV]            = { "LTV",				{ "objects/vehicles/ltv/asian_ltv.cgf",		{ x = 0, y = 0.0, z = 0.0 }, makeVec(0,0,0),			false,		  }},
        [VM_DAUNTLESS]      = { "Dauntless",        { "objects/vehicles/dauntless/dauntless.cga",		{ x = 0, y = 0.0, z = 0.0 }, makeVec(0,0,0),			false,		  }},
        [VM_KUANTI]         = { "Kuanti",			{ "objects/vehicles/kuanti/kuanti.cga",		{ x = 0, y = 0.0, z = 0.0 }, makeVec(0,0,0),			false,		  }},
        [VM_SPEEDBOAT]      = { "Speedboat",        { "objects/vehicles/speedboat/speedboat.cga",		{ x = 0, y = 0.0, z = 0.0 }, makeVec(0,0,0),			false,		  }},
        [VM_DESTROYER]      = { "Destroyer",        { "objects/vehicles/us_destroyer/us_destroyer_mp.cga",		{ x = 0, y = 0.0, z = 0.0 }, makeVec(0,0,0),			false,		  }},
        [VM_HOVER]          = { "Hovercraft",       { "objects/vehicles/us_hovercraft_b/us_hovercraft_b.cgf",		{ x = 0, y = 0.0, z = 0.0 }, makeVec(0,0,0),			false,		  }},
        [VM_SCIENCESHIP]    = { "Scientist Ship",   { "objects/library/vehicles/ship/cargo_ship/cargo_ship.cgf",		{ x = 0, y = 0.0, z = 0.0 }, makeVec(0,0,0),			false,		  }},
        [VM_CARGOSHIP]      = { "Cargo Ship",       { "objects/library/vehicles/diesel_train_engine/diesel_train_engine.cgf",		{ x = 0, y = 0.0, z = 0.0 }, makeVec(0,0,0),			false,		  }},
        [VM_SKYFORGE]       = { "Skyforge ",        { "objects/library/vehicles/ship/valley_forge_placeholder/valley_forge.cgf",		{ x = 0, y = 0.0, z = 0.0 }, makeVec(0,0,0),			false,		  }},
        [VM_NAVYSHIP]       = { "Navy Ship ",       { "objects/library/vehicles/ship/us_navy_ship_placeholder/us_navy_ship.cgf",		{ x = 0, y = 0.0, z = 0.0 }, makeVec(0,0,0),			false,		  }},
        [VM_TANKER]         = { "Tanker ",          { "objects/library/vehicles/tanker_truck/tanker_truck_trailer.cgf",		{ x = 0, y = 0.0, z = 0.0 }, makeVec(0,0,0),			false,		  }},
        [VM_SHARK]          = { "Shark ",		    { "objects/characters/animals/whiteshark/greatwhiteshark.chr",		{ x = 0, y = 0.0, z = 0.8 }, makeVec(0,0,3.1),			false,		  }},
        [VM_PALM]           = { "Palm ",			{ "Objects/natural/trees/palm_tree/palm_tree_large_b.cgf",		{ x = 0, y = 0.0, z = 0.0 }, makeVec(0,0,0),			false,		  }},
        [VM_ROCK]           = { "Rock ",			{ "objects/natural/rocks/suitjump_rocks/cliff_rock_cover_a.cgf",		{ x = 0, y = 0.0, z = 0.0 }, makeVec(0,0,0),			false,		  }},
    }

    return aList
end

---------------
ClientMod.ChangeVehicleModel = function(self, hClient, hVehicle, iModel, bQuiet)

    local aList = self:GetVehicleModels()
    local aInfo = iModel and aList[iModel]

    if (not aInfo) then
        ListToConsole({
            Client      = hClient,
            List        = table.sortI(aList),
            Title       = hClient:Localize("@l_ui_VMList"),
            ItemWidth   = 15,
            PerLine     = 5,
            PrintIndex  = true,
            Index       = 1
        })
        return true, hClient:LocalizeNest("@l_ui_CMListedInConsole", { table.count(aList) })
    end

    local function f()
        hVehicle = hVehicle or hClient:GetVehicle() or SvSpawnEntity({
            Class = "Civ_car1",
            Pos = hClient:GetFacingPos(eFacing_Front, 7.5, eFollow_Auto, 1),
            Dir = hClient:SmartGetDir(1),

            Instant = true,
        })


        local sModel = aInfo[2][1]
        local iScale = 1
        local bHideTires = false
        local vPos = aInfo[2][2]
        local vDir = aInfo[2][3]


        local vehicle = GetEntity(hVehicle:GetName())
        if (not vehicle or not vehicle.vehicle) then
            return
        end

        if (vehicle.CM) then
            System.RemoveEntity(vehicle.CM)
        end

        local CM = System.SpawnEntity({ class = "BasicEntity", position = vehicle:GetPos(), orientation = vehicle:GetDirectionVector(), name = vehicle:GetName() .. "_cm", properties = { object_Model = sModel }})
        CM:LoadObject(0, sModel)
        CM:PhysicalizeSlot(0, { flags = 1.8537e+008 }) -- special flags for correct collision.

        vehicle:DrawSlot(0, 0)
        --vehicle:EnablePhysics(0)
        vehicle:AttachChild(CM.id, PHYSICPARAM_SIMULATION)
        vehicle.CM = CM.id

        if (vPos) then CM:SetLocalPos(vPos) end
        if (vDir) then CM:SetLocalAngles(vDir) end
        if (iScale) then CM:SetScale(iScale) end
        if (bHideTires) then for i = 1, 4 do vehicle:DrawSlot(i, 0) end end

        self:OnAll(string.format([[g_Client:V_MODEL('%s','%s',%d,{x=%f,y=%f,z=%f},{x=%f,y=%f,z=%f},%f,%s)]],
                hVehicle:GetName(),
                sModel,
                iModel,
                vPos.x, vPos.y, vPos.z,
                vDir.x, vDir.y, vDir.z,
                iScale, g_ts(bHideTires)
        ), {
            Sync = true,
            SyncID = "model",
            BindID = hVehicle.id,
            Check  = function() return (hVehicle and hVehicle.CM ~= nil)  end
        })

        SpawnEffect(ePE_Light, hVehicle:GetPos())

        if (IsAny(iMode,
                VM_USPLANE, VM_NKPLANE,
                VM_CARGOPLANE, VM_AIRCRAFT, VM_PLANE1
        )) then
            self:CreatePlane(vehicle, IsAny(iMode, VM_USPLANE, VM_NKPLANE))
        end

        if (not bQuiet) then
            SendMsg(CHAT_SERVER, hClient, hClient:Localize("@l_ui_playerVM", { aInfo[1] }))
        end

    end

    Script.SetTimer(1, f)
end

---------------
ClientMod.CreatePlane = function(self, hVehicle, bWeapons)
    Debug("Hello, name request!!")
end

---------------
ClientMod.DecodeNameRequest = function(self, hClient, sMessage)
    Debug("Hello, name request!!")
end

---------------
ClientMod.DecodeNameRequest = function(self, hClient, sMessage)
    Debug("Hello, name request!!")
end