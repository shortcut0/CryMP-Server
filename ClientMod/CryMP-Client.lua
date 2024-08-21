---------------------------------------------------------
-- CLIENT UNDER CONSTRUCTION.
--
-- COPYRIGHT (D) MARISAAAAAAUH 2006-2069
--
---------------------------------------------------------

--=========================================================
-- Hallo
--=========================================================

RELOAD = (ClientMod ~= nil)

local ClientModX = ClientMod or {}
ClientMod = {
    version = "0",
    id      = g_localActorId,
    ent     = g_localActor,
    channel = g_localActor.actor:GetChannel(),

    -- ======================

    -- ======================
    _G              = {},
    CHAT_EFFECTS    = {},
    MATERIAL_CACHE  = {},
    DEBUG           = ClientModX.DEBUG,
    COUNTER         = ClientModX.COUNTER or 0,
    DRAW_TOOLS      = ClientModX.DRAW_TOOLS or {},
    FORCED_CVARS    = {
        R_ATOC = 0
    },

    UpdateRate      = ClientModX.UpdateRate or 1 / 60,
}

if (ClientMod.DEBUG) then
    ClientMod.DRAW_TOOLS={}
    CPPAPI.RemoveTextOrImageAll()
end

-- ==================
CPPAPI = CPPAPI or {}
CALLBACK_OK = false

-- ==================

-- ==================

DEVELOPER_MODE = DEVELOPER_MODE or (g_localActor ~= nil and g_localActor:GetName() == "test_player")


--=========================================================
-- Some Globals
--=========================================================

if (not g_gameRules) then return end
g_pGame = g_gameRules.game
GetEntity = function(hId)
    if (hId == nil) then return end
    if (isUserdata(hId)) then return System.GetEntity(hId) end
    if (isArray(hId)) then if (hId.id) then return System.GetEntity(hId.id) end return end
    if (isString(hId)) then return System.GetEntityByName(hId) end return
end
GP = function(c) return g_pGame:GetPlayerByChannelId(c) end
g_ts = tostring
g_tn = tonumber

IS_PS = (g_gameRules.class == "PowerStruggle")
IA_IA = (g_gameRules.class == "InstantAction")

-- pak
MODEL_NOMAD_HEADLESS = "CryMP-Objects/characters/nomad/headless.cdf"

--=========================================================
-- START UP
--=========================================================

SystemLog = System.LogAlways
ClientLog = function(sMsg, ...)
    local p = {...}
    local s = "$9[$4CryMP-Server$9] " .. tostring(sMsg)
    if (#p>0) then
        s = string.format(s,unpack(p))
    end
    local p=0
    for line in string.gmatch(s,"[^\n]+") do
        SystemLog(line)p=p+1
    end
    if (p==0)then SystemLog(s)end
end
DebugLog = function(...)
    if (not ClientMod.DEBUG) then
        return
    end
    ClientLog(...)
end

--=========================================================
-- Functions

--=========================================================
-- Init
ClientMod.Init = function(self)

    -- es muy importante
    self:InitLibs()
    Script.ReloadScript("CryMP-Client.lua",1,1)
    if (not PAK_LOADED) then

        -- !!!
        MODEL_NOMAD_HEADLESS = "objects/characters/human/us/nanosuit/nanosuit_us_multiplayer.cdf"
        ClientLog("Pak not loaded!")

    else
        -- removed in new client!
        --for _, sFile in pairs(System.ScanDirectory("Scripts/CryMP/Libs/", SCANDIR_FILES) or {}) do Script.ReloadScript(sFile, 1, 1) end
        for i, v in pairs({
            "string.utils.lua",
            "math.utils.lua",
            "lua.utils.lua"
        }) do
            local bOk, sErr = pcall(loadfile, "Scripts/CryMP/Libs/" .. v)
            if (not bOk) then
                ClientLog("Failed loading Include: %s (%s)", v, g_ts(sErr))
            end
        end
    end

    -- ====================
    local fCKB = CPPAPI.CreateKeyBind
    if (fCKB) then
        for _,s in pairs({
            "f3","f4","f5",
            "enter","escape"
        }) do
            fCKB(s,"cmp_p g_localActor:OnAction('"..s.."','',0)")
        end
    end

    -- ====================
    g_pCVars = {}
    self:InitCVars()
    self:AddCVars()

    -- ====================
    self:InitCallbacks()

    -- ====================
    eTS_Spectator, eTS_Message
    = 0, 1

    -- ====================
    eInjection_Replace, eInjection_Post, eInjection_Pre
    = 0, 1, 2

    -- ====================
    eCR_Installed, eCR_NotInstalled, eCR_PakOk, eCR_NoPak
    = 10, 11, 12, 13

    -- ====================
    eCR_OpenChat, eCR_CloseChat
    = 20, 21

    -- ====================
    eCR_ELV
    = 30

    -- ====================
    -- 40 - 50 (or more?)
    eCR_ModifiedCVar
    = 40

    -------
    self:FixClWork()
    self:PatchGameRules()
    self:PatchLocalActor()

    -------
    self.AASearchLasers:Init()
    self.AnimationHandler:Init()

    -------
    self:ToServer(eTS_Spectator, (PAK_LOADED and eCR_PakOk or eCR_NoPak))

    -- =====================
    ClientEvent = self.Event

    -- =====================
    eEvent_BLE = 0

    g_Client = self
    return true
end

--=========================================================
-- Events
ClientMod.Delete = function(self)

    ClientLog("Client Deleted..")
    g_aHooks = nil
end

--=========================================================
-- Events
ClientMod.InitCallbacks = function(self)

    -- for update draw()
    local bHooked = true

    --funcs
    local uF = function(...) _G["ClientMod"]:Update(...) end
    local sF = function(...) _G["ClientMod"]:OnEntitySpawn(...) end
    local dF = function(...) _G["ClientMod"]:Delete(...) end

    if (Updater) then
        if (not g_ClientUpdater or not GetEntity(g_ClientUpdater.id)) then
            g_ClientUpdater = System.SpawnEntity({
                class = "Updater"
            })
            g_ClientUpdater:SetCallback(uF)
        end
        ClientLog("Init Updater")

    elseif (AddHook ~= nil) then
        self:AddHook("OnUpdate", uF)

    else
        bHooked = false
    end

    if (AddHook) then
        self:AddHook("OnSpawn", sF)
        self:AddHook("OnDisconnect", dF)
    end

    CALLBACK_OK = bHooked
end

--=========================================================
-- Events
ClientMod.AddHook = function(self, sID, hFunc)
    ClientLog("Hook->%s",g_ts(AddHook(sID, sID, hFunc)))
end

--=========================================================
-- Events
ClientMod.AddCVars = function(self)

    for var, val in pairs({
        --sys_physics_cpu = 1,
        e_particles_quality = 4,
        r_UseSoftParticles = 1,
        e_water_ocean_soft_particles = 1,
        e_particles_object_collisions = 1,
        e_particles_max_emitter_draw_screen = 500000,
        r_glow = 1,
        --e_particles_thread = 1
    }) do
        System.SetCVar(var, tostring(val))
    end

    -- Tests ?
    AddCVar("crymp_test69", "a pointer to 6t9", 69)
    AddCVar("crymp_test69Pointer", "a pointer to 6t9", ClientMod.UpdateRate, "ClientMod.UpdateRate")

    -- Stuff
    AddCVar("crymp_chatdots", "CryMP-Client Mod Update Rate", 3, nil)
    AddCVar("crymp_chatlabel", "CryMP-Client Mod Update Rate", 0, nil)
    AddCVar("crymp_updateRate", "CryMP-Client Mod Update Rate", ClientMod.UpdateRate, "ClientMod.UpdateRate")
    AddCVar("crymp_debug", "CryMP-Client Mod Update Rate", (ClientMod.DEBUG==true), "ClientMod.DEBUG")

    -- Anims
    AddCVar("crymp_animation_handler", "CryMP-Client Mod Animation handler", 1)
    AddCVar("crymp_animation_rate", "CryMP-Client Mod Animation handler", ClientMod.AnimationHandler.UpdateRate, "ClientMod.AnimationHandler.UpdateRate")

    -- Commands
    AddCommand("crymp_loadlocal", "Load local client sources.", [[loadfile("crymp-server\\clientmod\\crymp-client.lua")()]])
    AddCommand("crymp_loadlocalPAK", "Load local client sources.", [[loadfile("crymp-server\\clientmod\\crymp-client\\crymp-client.lua")()]])

    AddCommand("cmp_t_th","","g_Client:AddHelmet(g_Client.channel, true, 'objects/characters/human/us/officer/captains_hat.chr',{-1.58,0.13,0,})")
    AddCommand("cmp_p","","loadstring(%%)()")
    AddCommand("cmp_ssi","","g_Client:ShowServerInfo(false)")
    AddCommand("cmp_hsi","","g_Client:ShowServerInfo(true)")
end

--=========================================================
-- Events
ClientMod.InitCVars = function(self)

    AddCommand = function(a, b, c)
        if (false and CPPAPI.AddCommand) then
            CPPAPI.AddCCommand(a, c)
        else
            System.AddCCommand(a, c, b)
        end
    end

    SetCVar = function(sName, pValue)

        local aVar = g_pCVars[sName]
        if (aVar == nil) then
            System.LogAlways(string.format("$6[Warning] Unknown command: %s", tostring(sCVar)))
            return
        end

        local sID   = aVar._N -- nest
        local hType = (aVar._T or "string")

        if (pValue ~= nil) then
            if (hType == "number") then
                pValue = (g_tn(pValue) or 0)
            elseif (hType == "boolean") then
                pValue = (pValue == "true" or (g_tn(pValue) or 0) > 0)
            end
            if (pValue ~= nil) then
                aVar._C = pValue
                if (sID) then
                    if (hType == "string") then
                        loadstring(sID .. " = \"" .. pValue .. "\"")()
                    else
                        loadstring(sID .. " = " .. g_ts(pValue))()
                    end
                end
            end
        end

        local sInfo = string.format("%s%s", (sID and ("G:"..sID..",") or ""), aVar._T:upper())
        System.LogAlways(string.format("   $3%s = $6%s $5[%s]", sName, g_ts(aVar._C), sInfo))
    end

    function GetCVar(sName, bPtr)
        local aVar = g_pCVars[sName]
        if (bPtr) then
            return aVar
        end
        if (not aVar) then
            return
        end
        return aVar._C
    end

    function AddCVar(sName, sDesc, pValue, hNest)
        if (GetCVar(sName)) then
            ClientLog("Overwriting CVar %s...",sName)
        end

        g_pCVars[sName] = {
            _T = type(pValue),
            _C = pValue,
            _N = hNest --TODO (x.y.z=123, Add("xyz","x.y.z")->Set("xyz",321)->x.y.z=321)
        }
        AddCommand(sName, sDesc, [[local p = {%%} SetCVar("]].. sName ..[[", unpack(p))]])
    end

end

--=========================================================
-- Events
ClientMod.OnAction = function(self, hPlayer, sKey, sMode, iValue)

    if (self.DEBUG) then
        ClientLog("-> %s (%s) %d",sKey,sMode,iValue)
    end

    local send


    -- ============
    -- Chat
    if (sKey == "hud_openchat" or sKey == "hud_openteamchat") then
        self:ChatEffect(self.channel,1)
        send = eCR_OpenChat

    elseif (sKey == "enter" or sKey == "escape")  then
        self:ChatEffect(self.channel,0)
        send = eCR_CloseChat

    end


    -- ============
    -- etc etc etc

    -- ============
    if (send) then self:ToServer(0,send) end
end

--=========================================================
-- Events
ClientMod.ChatEffect = function(self, channel, mode)

    local hPlayer = GP(channel)
    if (not hPlayer or (self.CHAT_EFFECTS[channel] == nil and mode == 0)) then
        return ClientLog("no channel..")
    end

    if (self.CHAT_EFFECTS[channel] == nil) then
        self.CHAT_EFFECTS[channel] = { m = mode, s = _time, t = "", tl = GetCVar("crymp_chatdots") }
    end

    if (mode == 0) then
        self.CHAT_EFFECTS[channel] = nil
    end
end

--=========================================================
-- Events
ClientMod.UpdateChatEffects = function(self)

    if (GetCVar("crymp_chatlabel") < 1) then return end

    local p, ppos, ok, g, r, d, s, alpha
    for _, a in pairs(self.CHAT_EFFECTS) do
        p = GP(_)
        if (p) then
            ppos = p:GetBonePos("Bip01 head")
            ppos.z=ppos.z+0.3
            if (a.m > 0) then
                if (a.m == 1) then

                    ok = (CryAction.IsGameObjectProbablyVisible(p.id)==1) and p:IsAlive() and not p:GetSuitMode(NANOMODE_CLOAK)
ClientLog(g_ts(CryAction.IsGameObjectProbablyVisible(p.id)))
                    if (ok) then
                        if (_time - a.s > 0.25) then
                            if (string.len(a.t) >= GetCVar("crymp_chatdots")) then
                                a.t = ""
                            else
                                a.t = (a.t .. ".")
                            end
                            a.s = _time
                        end
                       -- if () then
                        r = g_pGame:GetTeam(p.id)==g_pGame:GetTeam(self.id) and 1 or 0
                        g = r == 1 and 0 or 1
                        d = vector.distance(ppos, self.ent:GetPos())
                        alpha = 1 - d / 60 if (alpha < 0.1) then alpha = 0.1 end
                        s = 100 / d / 5
                        if (s > 1.5) then s = 1.25 end
                        if (s < 0.1) then s = 0.15 end
                            System.DrawLabel( ppos, s, "Typing " .. a.t, r, g, 0, alpha )
                       -- end
                    end
                end
            end
        end
    end
end

--=========================================================
-- Events
ClientMod.OnHit = function(self, hPlayer, aHitInfo)

    local hShooter = aHitInfo.shooter
    local hTarget  = aHitInfo.target
    if (not hShooter or not hTarget) then
        return
    end

    local ht = aHitInfo.type
    if (ht == "lockpick" or ht == "repair") then
        return
    end

    local bShooterLA = aHitInfo.shooterId == self.id
    local bTargetLA  = aHitInfo.targetId  == self.id
    local bHitSelf	 = bShooterLA and bTargetLA

    local bBullet       = string.find(tostring(ht), "bullet")
    local bMelee        = ht == "melee"
    local bExplosion    = aHitInfo.explosion
    local bHeadshot     = g_gameRules:IsHeadShot(aHitInfo)
    local sWeapon       = aHitInfo.weapon and aHitInfo.weapon.class

    --if (hit.target and hit.shooter and hit.targetId ~= hit.shooterId) then
    --    ATOMClient.AnimationHandler:OnAnimationEvent(hit.target, eCE_AnimHit, hit, (bBullet or bMelee))
    --end

    -------------------------------------------------------------------------------------
    if (GetCVar("crymp_animation_handler") > 0) then
        self.AnimationHandler:OnAnimationEvent(hPlayer, eCE_AnimHit, aHitInfo, (bBullet or bMelee))
    end

    if (hPlayer.hit) then
        hPlayer.hit_dir = aHitInfo.dir
    else
        hPlayer.hit = true
        hPlayer.hit_dir = aHitInfo.dir
    end


    -- store some information for musiclogic
    if (not hPlayer.MusicInfo) then hPlayer.MusicInfo={}; end
    hPlayer.MusicInfo.headshot  = bHeadshot
    hPlayer:LastHitInfo(hPlayer.lastHit, aHitInfo)

    local armor = hPlayer.actor:GetArmor();
    if (aHitInfo.radius==0) then
        if (not hPlayer:IsBleeding()) then
            hPlayer:SetTimer(BLEED_TIMER, 0);
        end

        local sound;
        local iDist = vector.distance(aHitInfo.pos,hTarget:GetPos())
        if(aHitInfo.damage > 10) then

            if (hTarget.id==self.id) then
                if (bHeadshot) then
                    sound="sounds/physics:bullet_impact:helmet_feedback"
                elseif (armor > 10) then
                    sound="sounds/physics:bullet_impact:mat_armor_fp";
                else
                    sound="sounds/physics:bullet_impact:mat_flesh_fp";
                end
            elseif(aHitInfo.shooter and aHitInfo.shooter.id == self.id) then
                if (bHeadshot) then
                    sound="sounds/physics:bullet_impact:headshot_feedback_mp";
                else
                    sound="sounds/physics:bullet_impact:helmet_feedback"
                    if(armor>10) then
                        sound="sounds/physics:bullet_impact:generic_feedback";
                    else
                        if(aHitInfo.material_type == "kevlar") then
                            sound="sounds/physics:bullet_impact:kevlar_feedback";
                        else
                            sound="sounds/physics:bullet_impact:flesh_feedback";
                        end
                    end
                end
                self:AddHitMarker(aHitInfo.pos, iDist)
            end
            if (sound) then
                hTarget:PlaySoundEvent(sound, g_Vectors.v000, g_Vectors.v010, SOUND_2D, SOUND_SEMANTIC_PLAYER_FOLEY);
            end





            if(armor > -1 and iDist<60) then
                local direction = aHitInfo.dir;
                direction.x = direction.x * -1.0;
                direction.y = direction.y * -1.0;
                direction.z = direction.z * -1.0;
                local scale = 0.25
                if (sWeapon == "GaussRifle"or sWeapon=="DSG1") then bHeadshot=1 scale = 1 end
                Particle.SpawnEffect((bHeadshot and"bullet.hit_flesh.c"or"bullet.hit_flesh.armor"), aHitInfo.pos, direction, scale);
            end
        end
        hPlayer:WallBloodSplat(aHitInfo);
    end

    local camShakeAmt = tonumber(System.GetCVar("cl_hitShake"))
    local camShakeDuration = 0.35
    local camShakeFreq = 0.15

    -- need to save some strength indicator for melees, so we can apply impulse
    -- when we ragdoll them
    if (bMelee) then
        self.lastMelee = 1
        self.lastMeleeImpulse = aHitInfo.damage * 2
        camShakeAmt = 33
        camShakeFreq = 0.2
    else
        self.lastMelee = nil
    end

    --hPlayer:StartBleeding()
    if (hPlayer.actor:GetHealth() <= 0) then
        if (timerexpired(hPlayer.BloodPoolTimer, 1)) then
            hPlayer.BloodPoolTimer = timerinit()
            hPlayer:BloodPool()
        end
        return
    end

    if (aHitInfo.damage > 5 and armor <= 0) then
        if (not hPlayer.painSoundTriggered) then
            hPlayer:SetTimer(PAIN_TIMER,0.15 * 1000)
            hPlayer.painSoundTriggered = true
        end
    end

    --
    if (hPlayer.id==self.id) then
        hPlayer.actor:CameraShake(camShakeAmt, camShakeDuration, camShakeFreq, g_Vectors.v000);
        hPlayer.viewBlur = 0.5;
        hPlayer.viewBlurAmt = tonumber(System.GetCVar("cl_hitBlur"));
    end

    ----------------------------------------------------------------------------------------



end

--=========================================================
-- Events
ClientMod.Update = function(self)

    -- check the peasants (maybe hook cppapi spawn)
    local aPlayers = System.GetEntitiesByClass("Player")
    for _, hPlayer in pairs(aPlayers) do
        if (not hPlayer.Initialized or RELOAD) then
            hPlayer:ClInit()
        end
    end

    RELOAD = false

    --------------------------------
    --- Needs to be called on frame
    self:UpdateHitMarkers()
    self:UpdateChatEffects()

    -- NOTE: we dont need to do this, setting it once overwrites it completely.
    --[[
    if (self.FORCED_MATERIAL) then
        if (not self.ent:IsHidden() and not self.ent:IsSpectating()) then
           -- self.ent:SetMaterial(self.FORCED_MATERIAL)
            self.ent:SetMaterial(self.FORCED_MATERIAL)
            self.CHANGED_MATERIAL = true
            DebugLog("forcing material.... %s!",self.FORCED_MATERIAL)
        end
    else]]--if (self.CHANGED_MATERIAL) then
      --  self.CHANGED_MATERIAL = nil
      --  if (self.ORIGINAL_MATERIAL) then self.ent:SetMaterial(self.ORIGINAL_MATERIAL) end
      --  self.ent:ResetMaterial(0)
      --  self.ent:ResetMaterial(1)
      --  self.ent:ResetMaterial(2)
     --   self.ent:ResetMaterial(3)
   -- end

    --------------------------------
    --- Limit Update Rate
    if (not timerexpired(self.UpdateTick, self.UpdateRate)) then
        return --ClientLog("%fms next:%f",self.UpdateRate,self.UpdateRate-timerdiff(self.UpdateTick))
    else
        self.UpdateTick = timerinit()
    end

    --------------------------------
    --- Limit Update Rate
    if (timerexpired(self.SecondTick, 1)) then
        self:TIMER_SECOND()
        self.SecondTick = timerinit()
    end

    --------------------------------
    --- UPDATE !!
    self.AASearchLasers:PreUpdateAASearchLaser()
    self.AnimationHandler:Update()

end

--=========================================================
-- Events
ClientMod.TIMER_SECOND = function(self)

    self:UpdateVoteMenu()

    local G = System.GetCVar
    local _ = 0
    for sVar, sForced in pairs(self.FORCED_CVARS) do
        _ = _ + 1
        if (g_ts(G(sVar)) ~= g_ts(sForced)) then
            System.SetCVar(sVar, g_ts(sForced))
            self:ToServer(0,eCR_ModifiedCVar+_)
        end
    end

end

--=========================================================
-- Events
ClientMod.AddHitMarker = function(self, v, d)
    if (d < 80) then
        local lifetime = 1
        local n = table.count(self.HIT_MARKERS)
        table.insert(self.HIT_MARKERS, { n = n, pos = v, spawn = _time, lt = lifetime, exp = _time + lifetime })
    end
end

--=========================================================
-- Events
ClientMod.UpdateHitMarkers = function(self)
    local pos = self.ent:GetPos()
    local n = {}
    for i = 1, table.count(self.HIT_MARKERS) do
        local m = self.HIT_MARKERS[i]
        if (m and _time < m.exp) then
            local d = vector.distance(m.pos, pos)
            if (d <= 80) then
                local alpha = ((m.exp - _time) / m.lt) * 1
                if (alpha > 0) then
                    System.DrawLabel( m.pos, 1.5, "$4(X)", 1, 0, 0, alpha ) -- only one label can be drawn at a time :c
                end
            end
            table.insert(n, m)
        else
            self.HIT_MARKERS[i] = nil
        end
    end
    self.HIT_MARKERS = n
end
--=========================================================
-- Events
ClientMod.PassengerCount = function(self, hEntity)
    local i = 0
    for _,seat in pairs(hEntity.Seats) do
        if (seat:GetPassengerId()) then
            i=i+1
        end
    end
    return i
end

--=========================================================
-- Events
--[[

(0, "usCarrier_watchTowerLookOut_binoculars_01", 1, 1, 1, true);
if (not boneName:lower():find("arm") and not boneName:lower():find("twist") and not boneName:lower():find("hand")) then
player:EnableBoneAnimation(0, 1, boneName, false);
--System.LogAlways(i.." | "..boneName);
else
--System.LogAlways(i.." $3| "..boneName);
end]]


--=========================================================
-- Events
ClientMod.SetModel = function(self, m, fp3p)
    if (m) then
        if (fp3p) then self.Properties.clientFileModel = fp3p end
        self.Properties.fileModel = m
    end
end

--=========================================================
-- Events
ClientMod.ReEnterVehicle = function(self, chan, seat, cm)
    local p = GP(chan)
    if (not p) then return DebugLog("no P :(")end
    local v = (cm and GetEntity(p.CM.Vehicle) or p:GetVehicle())
    if (not v) then return DebugLog("no V") end
    v.vehicle:ExitVehicle(p.id,true)
    Script.SetTimer(1,function()
        v.vehicle:EnterVehicle(p.id,seat,true)end)
end

--=========================================================
-- Events
ClientMod.GetObjMaterial = function(self, char)

    --todo:make c++ func
    if (self.MATERIAL_CACHE[char]) then
        return self.MATERIAL_CACHE[char]
    end

    local hTest = System.SpawnEntity({
        name = "gm",
        class = "BasicEntity",
        properties={object_Model=char}
    })
    local sMat=""
    if (hTest) then
        sMat = hTest:GetMaterial(0)
        System.RemoveEntity(hTest.id)
    end
    self.MATERIAL_CACHE[char] = sMat
    return sMat
end

--=========================================================
-- Events
ClientMod.DebugArrow = function(self, pos,dir,scale,color,name,timeout)
if (not self.DEBUG)then return end--only for the DEVS!!
    -- helper says its POS, RADIUS, COLOR, DIR, but in reality, DIR and COLOR are swapped!
    CryAction.PersistantArrow(pos,scale or 1,dir,color or {1,0,0},name or "a",timeout or 10)
end

--=========================================================
-- Events
ClientMod.RequestHead = function(self, iChannel, iHeadId)

    local hPlayer = GP(iChannel)
    if (not hPlayer) then
        return
    end

    local CA_SKIN = 1
    local CA_BONE = 2

    --must sync with server
    local HEAD_HELENA = 1
    local HEAD_CHICKEN = 2

    local aWardrobe = {
        [HEAD_HELENA] = {
            { AttachName = "head", Type = CA_SKIN, Bone = "", Model = "objects/characters/heads/story/helena_rosenthal/helena_rosenthal_head.chr", Rot = { 1, 0, 0, 0 }, Pos = { x = -1.45, y = 0.15, z = 0 } },
            { Type = CA_SKIN, Bone = "", Model = "objects/characters/heads/story/helena_rosenthal/helena_rosenthal_hair.chr", Rot = { 1, 0, 0, 0 }, Pos = { x = -1.45, y = 0.15, z = 0 } }
        },
        [HEAD_CHICKEN] = {
            { AttachName = "head", Type = CA_BONE, Bone = "Bip01 Head", Model = "objects/characters/animals/birds/chicken/chicken.chr", Rot = { 1, 0, 0, 0 }, Pos = { x = -0.3, y = -0.1, z = 0 } },
        },
    }

    if (not hPlayer.HEAD_ATTACHMENTS) then
        hPlayer.HEAD_ATTACHMENTS = {}
    else
        for _, aInfo in pairs(hPlayer.HEAD_ATTACHMENTS) do
            hPlayer:DestroyAttachment(0, aInfo.AttachID)
            --System.RemoveEntity(aInfo.EntityID) -- old head stuff
            DebugLog("destroy %s",aInfo.AttachID)
        end
        hPlayer.HEAD_ATTACHMENTS = {}
    end

    local aHeadData = aWardrobe[iHeadId]
    if (not aHeadData) then
        DebugLog("no head found!")
        return false
    end

    if (iHeadId == 0) then
        return -- head already destroyed by default, so just exit scope!
    end

 --   Script.SetTimer(1, function()

        for i, aInfo in pairs(aHeadData) do

            local sAttachName   = (aInfo.AttachName or "head_part_" .. i)
            local iAttachType   = aInfo.Type
            local sBoneName     = aInfo.Bone
            local sPartName     = aInfo.Model

            if (iAttachType == CA_SKIN) then
                sBoneName = "Bip01 Head"
            end

         --   table.insert(hPlayer.HEAD_ATTACHMENTS, { -- not real id.. UUUGh
           --     AttachID = sAttachName
           -- })

            local vPos = (aInfo.Pos or{ x = 0, y = 0, z = 0 })
            local vRot = aInfo.Rot

            vRot = hPlayer:GetDirectionVector(1)

            self:DebugArrow(hPlayer.actor:GetHeadPos(),vRot)

            local hNewID = self:AttachObject({
                Overwrite = 1,
                Parent = hPlayer,
                Name = "crymp_head_" .. i,
                Bone =  sBoneName,
                Model = sPartName,
                Object = nil,--object
                Pos = vPos,
                Dir = (vRot), --direction vector and model direction sometimes desynced
            }, true)

            table.insert(hPlayer.HEAD_ATTACHMENTS, { --fixed id (its dynamic to allow user to attach MUCHO STUFF!
                 AttachID = hNewID
             })

           -- hPlayer:DestroyAttachment(0, sAttachName)
        --    hPlayer:CreateBoneAttachment(0, sBoneName, sAttachName)
           ---- hPlayer:SetAttachmentCGF(0, sAttachName, sHeadName)

            --vPos.x = vPos.x - 1.45 -- Helena Special Test
            --vPos.y = vPos.y + 0.1 -- Helena Special Test
        --    local vPlayer = vPos
        --    hPlayer:SetAttachmentPos(0, sAttachName, vPlayer, true)

         --   local vDir = hPlayer.actor:GetHeadDir()
         --   local vHead = { x = 0, y = 0, z = 0 }
         --   vHead.x = vDir.x
        --    vHead.y = vDir.y
        --    hPlayer:SetAttachmentDir(0, sAttachName, vHead, true)
        end
   -- end)
end

--=========================================================
-- Events
ClientMod.ShowCCM = function(self, show)
    --fixme: character creation menu :3
end

--=========================================================
-- Events
ClientMod.ShowServerInfo___ = function(self, show)
    if (not show) then
        self:HideMenu("serverinfo")
        return
    end

    self:CreateMenu("serverinfo",{
        Banner = "Hellowo:3",
        X = 100, Y = 100,
        Width = 600,
        Height = 400
    },nil)
    self:DrawMenu("serverinfo")
end

--=========================================================
-- Events
ClientMod.GetMenu = function(self, id)
    self.DRAW_TOOLS[id]=self.DRAW_TOOLS[id]or{IDS={},Visible=false}
    return self.DRAW_TOOLS[id]
end

--=========================================================
-- Events
ClientMod.FadeMenu = function(self, id)

    local m=self:GetMenu(id)
    local o=m.Alpha

    for _,d in pairs(m.IDS) do

    end
end

--=========================================================
-- Events
ClientMod.UpdateVoteMenu = function(self)

    local ended=g_pGame:GetSynchedGlobalValue(801)==1
    local show = g_pGame:GetSynchedGlobalValue(800)==1-- or ended
    local menu = self:GetMenu("voting").IDS
    if (ended) then
        menu[-4] = menu[-4] or  _time
        DebugLog(_time- menu[-4])
        if (_time- menu[-4] > 5) then
            show=false
        end
    else
       -- menu[-4]=nil
    end

    if (not show) then
      --  menu[-1]=nil menu[-2]=nil
       -- self:FadeMenu("vote",1)
        DebugLog("hide?")
        self:HideMenu("voting")
        return
    end

    if (not ended) then
     --   menu[-4]=nil
    end

--    self:ResetFade("vote",1)
    local function ms(x,y)
        local s=string.rep(" ",(y-string.len(x))/2)
        return s..x..s
    end
    local function ls(x,y)
        local s=string.rep(" ",(y-string.len(x))/1)
        return s..x
    end
    local function rs(x,y)
        local s=string.rep(" ",(y-string.len(x))/1)
        return x..s
    end


    if (not menu[-1]) then
        menu[-1]=_time
        menu[-2]=0
    end


    local iX = 590
    local iY = 10

    local iH = 300
    local iW = 200
    local c1, c2 = 0.0, 1.0; --0.576471, 0.858824;
    local c3 = 0.498039; --0.439216;

    if (not menu[1]) then
        menu[1] = CPPAPI.DrawColorBox(iX, iY, iW, iH, 0, 0, 0,0.5)
    end
    if (not menu[2]) then
        menu[2] = CPPAPI.DrawText(iX, iY+10, 1.2, 1.2, 0.8, 0.8, 0.8, 1, ms("VOTE INFO",iW/6.5))
        menu[3] = CPPAPI.DrawColorBox(iX+20, iY+30, iW-35, 2, 0, 0, 0,0.5)
    end

    local iLabel_X = iX + 5
    local iLabel_Y = iY + 40

    local L = {
        "Type",
        "Status",
        "Voted YES",
        "Voted NO",
        "Initiator",
        "Remaining"
    }
    for i = 10, 16 do
        if (not L[i-9]) then break end
        if(menu[i]) then CPPAPI.RemoveTextOrImageById(menu[i]) end
         menu[i]=CPPAPI.DrawText(iLabel_X, iLabel_Y, 1.2, 1.2, c1, c2, c3, 1, ls(L[i-9],13).. " :")
        iLabel_Y = iLabel_Y+20
    end

    DebugLog(g_pGame:GetSynchedGlobalValue(800))
    iLabel_X = iX + 120
    iLabel_Y = iY + 40
    L = {
        g_pGame:GetSynchedGlobalValue(802):upper(),
        g_pGame:GetSynchedGlobalValue(810),
        g_pGame:GetSynchedGlobalValue(805),
        g_pGame:GetSynchedGlobalValue(806),
        GP(g_pGame:GetSynchedGlobalValue(807)):GetName(),
        g_pGame:GetSynchedGlobalValue(809) .. "s",
    }
    for i = 20, 36 do
        if (not L[i-19]) then break end
        if(menu[i]) then CPPAPI.RemoveTextOrImageById(menu[i]) end
         menu[i]=CPPAPI.DrawText(iLabel_X, iLabel_Y, 1.2, 1.2, c1, c2, c3, 1, rs(L[i-19],13))
        iLabel_Y = iLabel_Y+20
    end

    --[[

    g_pGame:SetSynchedGlobalValue(800, 1) -- vote status
    g_pGame:SetSynchedGlobalValue(801, 0) -- vote ENDED
    g_pGame:SetSynchedGlobalValue(802, aVote.Name) -- vote name  "MAP"
    g_pGame:SetSynchedGlobalValue(803, aVote.Title) -- vote title "CHANGE MAP"
    g_pGame:SetSynchedGlobalValue(804, aVote.Desc) -- vote desc "CHANGE MAP"
    g_pGame:SetSynchedGlobalValue(805, 0) -- vote yes "0"
    g_pGame:SetSynchedGlobalValue(806, 0) -- vote no "0"
    g_pGame:SetSynchedGlobalValue(807, hUser:GetChannel()) -- "INITIATOR"
    ]]

end

--=========================================================
-- Events
ClientMod.CreateMenu = function(self, id, info, tabs)

   --[[
    self.DRAW_TOOLS[id] = not self.DEBUG and self.DRAW_TOOLS[id] or {
        Type = 1,
        Pos = { X = info.X or 100, Y = info.Y or 100, Width = info.Width or 250, Height = info.Height or 250},
        Tabs = {
            C = tabs and tabs.Current or 1,
            T = tabs and table.count(tabs) or 1,
            Next = function(this) this.C=this.C+1 if (this.C>this.T)then this.C=1 end end,
            Data = tabs or {
                { "Tab One", { "Line1","sssLine1","Lin dfge1","Lifdg sdfg sne1","Li sdfgsd fgne1","Lins  sdfgs dfg e1","Linesdf gsdfgsdf g1","Lisfgs  sdfgs dfg sfgsd fne1","Linesdfgsdfgsdfg1","Line dfg d1","Lin dfgs dfe1" } },
                { "Tab 3", { "Line1","sssLine1","Lin dfge1","Lifdg sdfg sne1","Li sdfgsd fgne1","Lins  sdfgs dfg e1","Linesdf gsdfgsdf g1","Lisfgs  sdfgs dfg sfgsd fne1","Linesdfgsdfgsdfg1","Line dfg d1","Lin dfgs dfe1" } },
                { "Tab 5", { "Line1","sssLine1","Lin dfge1","Lifdg sdfg sne1","Li sdfgsd fgne1","Lins  sdfgs dfg e1","Linesdf gsdfgsdf g1","Lisfgs  sdfgs dfg sfgsd fne1","Linesdfgsdfgsdfg1","Line dfg d1","Lin dfgs dfe1" } },
                { "Tab 11", { "Line1","sssLine1","Lin dfge1","Lifdg sdfg sne1","Li sdfgsd fgne1","Lins  sdfgs dfg e1","Linesdf gsdfgsdf g1","Lisfgs  sdfgs dfg sfgsd fne1","Linesdfgsdfgsdfg1","Line dfg d1","Lin dfgs dfe1" } },
            },
            Banner = info.Banner or "nun"
        },
        IDS = {}
    }]]
    return self.DRAW_TOOLS[id]
end

--=========================================================
-- Events
ClientMod.DrawMenu = function(self, id)

    --[[
    --test code, thats why it looks uuugly

    local DT = self.DRAW_TOOLS[id]
    if (not DT) then
        DebugLog("not found, DUHHHH")
        return
    end

    local IDS = DT.IDS

    table.insert(IDS,
            CPPAPI.DrawColorBox(DT.Pos.X, DT.Pos.Y, DT.Pos.Width, DT.Pos.Height, 0, 0, 0,0.5)
    )

    local n = DT.Tabs.C
    local a = DT.Tabs.Data
    local h=0


    local centertabstart = 10


    centertabstart=((DT.Pos.Height-20-50)/2)-DT.Tabs.T
DebugLog("%f-20/ %d*10 / 2",DT.Pos.Height,DT.Tabs.T)

    local h_pos_y = DT.Pos.Y+centertabstart
    local h_pos_x = DT.Pos.Y+10

    local ltab=50
    for _,aa in pairs(a) do
        if (string.len(aa[1])>ltab)then ltab=string.len(aa[1])end
    end ltab=ltab+20
    local l_pos_y = DT.Pos.Y+15--ltab
    local l_pos_x = h_pos_x+ltab+5

    local c1, c2 = 0.0, 1.0; --0.576471, 0.858824;
    local c3 = 0.498039; --0.439216;

    table.insert(IDS,
            CPPAPI.DrawColorBox(DT.Pos.X+ltab+30, DT.Pos.Y+10, DT.Pos.Width-ltab-40, DT.Pos.Height-50, 0, 0, 0,0.5)
    )

    local function ms(x,y)
        local s=string.rep(" ",(y-string.len(x))/2)
        return s..x..s
    end

    local linelen=DT.Pos.Width-ltab-40-5-5

    for _, info in pairs(a) do
        h=0
        if (_ == n) then
            h=1
        end

        local brightness = h==1 and 1 or 0.5
        table.insert(IDS,
                CPPAPI.DrawText(h_pos_x, h_pos_y, 1.2, 1.2, c1, c2, c3, brightness, (h==1 and "-> " or"   " )..info[1])
        )

        if (h==1) then
            for _,smsg in pairs(info[2]) do

                DebugLog("%s>%s<",linelen,ms(smsg,linelen))
                local nid=CPPAPI.DrawText(l_pos_x, l_pos_y, 1.2, 1.2, 0.4, 1, 0.6, brightness, ms(smsg,linelen/6.56))

                l_pos_y=l_pos_y+20
               -- DT.Tabs[_][3] = {
--
              --  }

                table.insert(IDS,
                    nid
                )
            end
        end

        h_pos_x = h_pos_x + 20
    end]]
end

--=========================================================
-- Events
ClientMod.HideMenu = function(self, id)

    if (not self:GetMenu(id)) then
        return
    end
    local ids = self:GetMenu(id).IDS
    for _ in pairs(ids) do
        CPPAPI.RemoveTextOrImageById(_)
    end

    self.DRAW_TOOLS[id].IDS = {}
    self.DRAW_TOOLS[id].Visible = false
end

--=========================================================
-- Events
ClientMod.RequestModel = function(self, channelId, modelId, modelPath, soundPath, seatFixId)
    local hPlayer = GP(channelId)
    if (not hPlayer) then
        return ClientLog("no chan..again")
    end

    if (hPlayer.CM.ID == modelId) then return DebugLog("we ARE already that model!!") end

    local v = hPlayer:GetVehicle()
    local sMat = modelPath and self:GetObjMaterial(modelPath) or ""
    if (modelId == 0) then
        local sDef1, sDef2 =
        "objects/characters/human/us/nanosuit/nanosuit_us_multiplayer.cdf",
        "objects/characters/human/us/nanosuit/nanosuit_us_fp3p.cdf"
        if (g_gameRules and g_gameRules.game:GetTeam(hPlayer.id) == 1) then
            sDef1, sDef2 =
            "objects/characters/human/asian/nanosuit/nanosuit_asian_multiplayer.cdf",
            "objects/characters/human/asian/nanosuit/nanosuit_asian_fp3p.cdf"
        end
        self.SetModel(hPlayer, sDef1, sDef2)
        hPlayer.CM = { File = nil, ID = 0, Vehicle = nil }
        if (hPlayer.id ~= self.id) then
            hPlayer.actor:ActivateNanoSuit(1)
        else
            sMat = self:GetObjMaterial(sDef1)
            if (sMat and sMat ~="") then -- material MUST EXIST, else CRASH!
                hPlayer:SetMaterial(sMat) -- breaks nano suit materials . . .... ... . .
            end
        end
    else

        if (hPlayer.id == self.id) then
            DebugLog("reset mat.. ->%s",g_ts(hPlayer:ResetMaterial(0)or-1))
            for i=1,100 do
            hPlayer:ResetMaterial(i)end
        end
        self.SetModel(hPlayer, modelPath)
        hPlayer.CM = { File = modelPath, ID = modelId, Vehicle = v, Material = sMat }
    end

    DebugLog("nanosuit = %s %s",g_ts(string.find(sMat or "", "nanosuit")),sMat)

    local bDead = hPlayer:IsDead()
    hPlayer.currModel = ""
    if (self.id ~= hPlayer.id) then
        if (bDead) then
            hPlayer.currModel = ""
        else
            hPlayer:Physicalize(0, 4, hPlayer.physicsParams)
            hPlayer.actor:Revive()
        end
        hPlayer.actor:ActivateNanoSuit(not string.find(sMat, "nanosuit")and 1 or 0) -- so material stays normal :3
        hPlayer:SetMaterial(sMat) -- breaks nano suit materials . . .... ... . .
    else
        if (not bDead) then
            hPlayer.actor:Revive()
        end

        self.FORCED_MATERIAL = nil
        if (sMat ~= "" and not string.find(sMat, "nanosuit")) then --for 3p, for local only
            --  self.ORIGINAL_MATERIAL = self.ORIGINAL_MATERIAL or hPlayer:GetMaterial(0)
            self.FORCED_MATERIAL = sMat
        else
            hPlayer:SetMaterial(sMat) -- breaks nano suit materials . . .... ... . .
        end
        --hPlayer:SetActorModel()
    end


    if (soundPath and soundPath ~= "") then self:PSE(soundPath,hPlayer,"modelchange") end
    local hItem = hPlayer.inventory:GetCurrentItem()
    if (hItem and not bDead) then hItem.item:Select(true) end
    if (v and seatFixId and seatFixId~=-1) then-- and self:SeatFree(v,seatFixId)) then
       -- v.vehicle:ExitVehicle(self.id,true)
      --  self:ToServer(0,eCR_ELV)
       -- local iSeat = self:GetSeat(v,self.id) -- brrrrooOOOOKEN
       -- DebugLog("iSeat = %d:%s",g_tn(iSeat or -69) or -70,g_ts(iSeat))
       -- v.vehicle:ExitVehicle(self.id,true)
       -- v.vehicle:EnterVehicle(self.id,(iSeat or 1),true)
       --DebugLog("enter back into %d",seatFixId)
        --v.vehicle:EnterVehicle(self.id,seatFixId,true)--bad because can desync for new players.. but can try
    end

    --hPlayer.CMResetMat = (bLocalActor or (bResetMat))
    --hPlayer.CMMaterial = nil
    --hPlayer.CMMaterial = GetObjectMaterial(sModelPath)
    --hPlayer:ReattachItems()
    --hPlayer:SetMaterial(hPlayer.CMMaterial)
    --hPlayer:UpdateAttachedItems()
    --hPlayer:ResetMaterial(0)
end

--=========================================================
-- GetSeat
ClientMod.GetSeat = function(self, p, c)
    -- this is BROKEN! all seats have localactor inside them!!!!
    local v = p.vehicle and p or p:GetVehicle()
    if (not v) then return DebugLog("no V for da P")end
    for _, s in pairs(v.Seats) do
        DebugLog(g_ts(s:GetPassengerId()))
        DebugLog(g_ts(g_localActorId))
        DebugLog(g_ts(self.id))
        if (s:GetPassengerId()==(c or p.id)) then return s.seatId or _ end
    end
end

--=========================================================
-- GetSeat
ClientMod.SeatFree = function(self, v, i)
    for _, s in pairs(v.Seats) do
        if (s.seatId==i and s.seat:IsFree()) then
            return true
        end
    end
end

--=========================================================
-- Events
ClientMod.AddHelmet = function(self, channel, enable, model, offset, rot)

    local hPlayer = GP(channel)
    if (not hPlayer) then return ClientLog("no player..")end

    self:AttachObject({
        Overwrite=1,
        Parent = hPlayer,
        Name = "crymp_helmet",
        Bone = "Bip01 Head",
        Model = model or "objects/default.cgf",
        Object = nil,--object
        Pos = offset,
        Dir = rot or hPlayer:GetDirectionVector(1),
    }, enable)

    if (channel == self.channel) then
    end
end

--=========================================================
-- Events
ClientMod.GetMSlot = function(self,ent, id)
    ent.Slots=ent.Slots or{}
    local c=ent.Slots[id]
    if (c) then return c end
    c=10+#ent.Slots
    ent.Slots[id]=c
    ClientLog("new slot for id %s %d",id,c)
    return c
end

--=========================================================
-- Events
ClientMod.AttachObject = function(self,props, enable)

    local hEntity = GetEntity(props.Parent)
    if (not hEntity) then
        return ClientLog("no entity..")
    end
    local sName = props.Name
    local sID = (sName .. (props.ID or "0"))
    local iSlot = (props.Slot or self:GetMSlot(hEntity,sID))
    local sBone = props.Bone
    local sModel = props.ModelName or props.Model
    local hObj = props.Object

    local vPos = props.Pos
    local vDir = props.Dir

    local function n(e,s,i)
        return e:GetAttachmentBone(0,s)
    end

    if (enable) then

        if (n(hEntity, sID, iSlot)) then
            if (props.Overwrite) then
                hEntity:DestroyAttachment(0, sID)
                if (hObj) then hObj:EnablePhysics(true) end
            else return
            end
        end

        hEntity:CreateBoneAttachment(0, sBone, sID)

        -- attach a MODEL
        if (not string.empty(sBone)) then
            local ext = string.lower(string.sub(sModel, -4))
            if ((ext == ".chr") or (ext == ".cdf") or (ext == ".cga")) then
                iSlot = hEntity:LoadCharacter(iSlot, sModel)
            else
                iSlot = hEntity:LoadObject(iSlot, sModel)
            end
            hEntity:DrawSlot(iSlot, 0)
            hEntity:SetAttachmentObject(0, sID, hEntity.id, iSlot, 0)

        -- attach an OBJECT
        else
            hObj:EnablePhysics(false)
            hEntity:SetAttachmentObject(0, sID, hObj.id, -1, 0)
        end
        if (vPos) then hEntity:SetAttachmentPos(0, sID, vPos, false) end
        if (vDir) then hEntity:SetAttachmentDir(0, sID, vDir, true) end

        return sID
    elseif (n(hEntity,sID)) then
        hEntity:DestroyAttachment(0, sID)
        return
    end
end

--=========================================================
-- Events
ClientMod.DissolveVehicle = function(self, id, enable)

    local hEntity = GetEntity(id)
    if (not hEntity) then
       return ClientLog("<entity not found >%s",g_ts(id))
    end

    if (self:PassengerCount(hEntity) > 0) then
        return
    end

    hEntity.Dissolving = self:LoadEffectOnEntity(hEntity, "dissolve", {
        Effect = "misc.electric_man.disolve",
        Type   = "Render",
        Form   = "Surface",
        Speed  = 0.5,
        UnitScale = 5
    }, enable)
end

--=========================================================
-- PLAY SOUND EVENT
ClientMod.PSE = function(self, sound, entity, id, slot, loop, force_restart, overwrite)

    -- Sowwy chris
    local TD = SOUND_DEFAULT_3D
    local vc, vc2 = g_Vectors.v000, g_Vectors.v010
    local fol = SOUND_SEMANTIC_PLAYER_FOLEY

    id = id or "generic"

    entity = (entity or self.ent)
    entity.SoundSlots = entity.SoundSlots or {}
    entity.SoundSlots[id] = entity.SoundSlots[id] or {}

    slot = slot or -1

    local hSound = entity.SoundSlots[id][slot]
    if (hSound and Sound.IsPlaying(hSound)) then
        if (force_restart) then
            if (not overwrite) then
                entity:StopSound(hSound)
            end
        else
            return
        end
    end

    ClientLog("->play%s",sound)
    entity.SoundSlots[id][slot] = entity:PlaySoundEvent(sound, vc, vc2, TD, fol)
    if (loop) then
        Sound.SetSoundLoop(entity.SoundSlots[id][slot], 1)
    end
end

--=========================================================
-- Events
ClientMod.LoadEffectOnEntity = function(self, entity, id, params, enable)

    local hEntity = GetEntity(entity)
    if (not hEntity) then
        ClientLog("<entity not found>")
       return false -- none?
    end

    local iSlot   = (params.Slot or -1)
    local sEffect = params.Effect
    local aParams = {
        bActive			= params.Active,
        bPrime			= params.Prime,
        Scale		    = params.Scale,			-- Scale entire effect size.
        SpeedScale		= params.Speed,			-- Scale particle emission speed
        CountScale		= params.Count,			-- Scale particle counts.
        bCountPerUnit 	= params.UnitScale,  -- Multiply count by attachment extent
        AttachType		= params.Type,		    -- BoundingBox, Physics, Render
        AttachForm		= params.Form,	        -- Vertices, Edges, Surface, Volume - cool stuff :D
        PulsePeriod		= params.Pulse,			-- Restart continually at this period.
    }

    hEntity.EffectSlots = hEntity.EffectSlots or {}
    hEntity.EffectSlots[id] = hEntity.EffectSlots[id] or {}

    local hSlot = hEntity.EffectSlots[id][iSlot]
    if (hSlot) then
        if (enable) then return true, ClientLog("already") end -- on?
        hEntity:FreeSlot(hSlot)
        hEntity.EffectSlots[id][iSlot] = nil
        ClientLog("Disable")
        return false -- off

    elseif (enable) then
        hEntity.EffectSlots[id][iSlot] = hEntity:LoadParticleEffect(iSlot, sEffect, aParams)
        ClientLog("Enable")
        return true -- on
    end

    ClientLog("F > %s", g_ts(enable))
    return false -- off?
end

--=========================================================
-- Events
ClientMod.OnEntitySpawn = function(self, hEntity)

    ClientLog("it WORKED! %s",hEntity.class)

end

--=========================================================
-- Events
ClientMod.Event = function(iEvent,...)

    local p = {...}
    if (iEvent == eEvent_BLE) then
        HUD.BattleLogEvent(p[1],p[2],p[3])

    else
        ClientLog("Invalid Event To Event(%s)", g_ts(iEvent))
    end

end

--=========================================================
-- LoadCode
ClientMod.LoadCode = function(self, sCode)

    local bOk, sErr = pcall(loadstring(sCode))
    if (not bOk) then
        self:ToServer(eTS_Message, "!clerr EXECUTE {" .. sCode .. "}={" .. tostring(sErr) .. "}")
        ClientLog("Error: %s", g_ts(sErr))
    end
end

--=========================================================
-- ToServer
ClientMod.ToServer = function(self, hType, hMessage)

    if (hType == eTS_Spectator) then
        g_gameRules.server:RequestSpectatorTarget(self.id, hMessage)

    elseif (hType == eTS_Message) then
        g_pGame:SendChatMessage(ChatToTarget, self.id, self.id, hMessage)

    else
        ClientLog("Bad Message Type!")
    end

end

--=========================================================
-- Inject
ClientMod.Inject = function(self, aParams)
    local sEntity   = aParams.Class
    local hEntity   = aParams.Entity
    local sTarget   = aParams.Target
    local fFunction = aParams.Function
    local iType     = (aParams.Type or eInjection_Replace)
    local bPatchEntities = aParams.PatchEntities

    if (hEntity) then
        ServerInjector.InjectEntity(aParams)
    end

    local hClass = _G[sEntity]
    if (not hClass) then
        ClientLog("Class %s to Inject not found", sEntity)
        return
    end

    local function Replace(sT, c, f)
        local aNest = string.split(sT, ".")
        local iNest = table.size(aNest)
        if (iNest == 1) then
            if (iType == eInjection_Replace) then c[sT] = f end
        else
            local h = table.remove(aNest, 1)
            if (not c[h]) then
                return ClientLog("index " .. g_ts(h) .. " not found to inject on %s!",sT)
            end
            return Replace(table.concat(aNest, "."), c[h], f)
        end
    end

    if (isArray(sTarget)) then
        for _, s in pairs(sTarget) do Replace(s, hClass, fFunction) end
    else
        Replace(sTarget, hClass, fFunction)
    end

    if (bPatchEntities) then
        for _, hEnt in pairs(System.GetEntitiesByClass(sEntity) or {}) do
            if (isArray(sTarget)) then
                for _, s in pairs(sTarget) do Replace(s, hEnt, fFunction) end
            else
                Replace(sTarget, hEnt, fFunction)
            end
        end
    end
end

--=========================================================
-- fix cl work
ClientMod.FixClWork = function(self)
    self.ClWorkComplete = (self.ClWorkComplete or function(gameRules, entityId, workName)
        if (workName:sub(1,2)=="L:") then return ClientMod:LoadCode(workName:sub(3)) end
        local s if (workName == "repair") then s = "sounds/weapons:repairkit:repairkit_successful" elseif (workName == "lockpick") then s = "sounds/weapons:lockpick:lockpick_successful" end
        if (s) then local entity = System.GetEntity(entityId) if (entity) then local sndFlags = SOUND_DEFAULT_3D; sndFlags = band(sndFlags, bnot(SOUND_OBSTRUCTION)) sndFlags = bor(sndFlags, SOUND_LOAD_SYNCHRONOUSLY) local pos=entity:GetWorldPos(g_Vectors.temp_v1) pos.z=pos.z+1 return Sound.Play(sound, pos, sndFlags, SOUND_SEMANTIC_MP_CHAT) end end
    end)
    g_gameRules.Client.ClWorkComplete = self.ClWorkComplete
end

--=========================================================
-- Patch player
ClientMod.PatchLocalActor = function(client)
    client:Inject({
        Class    = "g_localActor",
        Target   = "UpdateDraw",
        PatchEntities = true,
        Function = function(self, ft)
            local stats = self.actorStats;
            if (self.actor:GetSpectatorMode()~=0 or stats.isHidden) then
                self:DrawSlot(0,0);
            else
                local hide=(stats.firstPersonBody or 0)>0;
                if (stats.thirdPerson or stats.isOnLadder) then
                    hide=false;
                end

                -- uhm, what
                local customModel=(self.CM and self.CM > 0) and hide;
                self:DrawSlot(0,customModel and 0 or 1);
                self:HideAllAttachments(0, hide, false);
            end

            if (g_Client) then
                if (not self.Initialized) then
                    self:ClInit()
                end
                if (not CALLBACK_OK) then
                    g_Client:Update()
                end
            end
        end
    })
    client:Inject({
        Class    = "Player",
        Target   = "Client.OnHit",
        PatchEntities = true,
        Function = function(self, aHit)
            g_Client:OnHit(self, aHit)
        end
    })

    client:Inject({
        Class    = "Player",
        Target   = "SetActorModel",
        PatchEntities = true,
        Function = function(self, isClient)
            self:KillTimer(UNRAGDOLL_TIMER);

            local PropInstance = self.PropertiesInstance;
            local model = self.Properties.fileModel;

            -- take care of fp3p
            if (self.Properties.clientFileModel and isClient) then
                model = self.Properties.clientFileModel;
            end

            local nModelVariations = self.Properties.nModelVariations;
            if (nModelVariations and nModelVariations > 0 and PropInstance and PropInstance.nVariation) then
                local nModelIndex = PropInstance.nVariation;
                if (nModelIndex < 1) then
                    nModelIndex = 1;
                end
                if (nModelIndex > nModelVariations) then
                    nModelIndex = nModelVariations;
                end
                local sVariation = string.format('%.2d',nModelIndex);
                model = string.gsub(model, "_%d%d", "_"..sVariation);
                --System.Log( "ActorModel = "..model );
            end

            if (self.CM and self.CM.ID and self.CM.ID > 0 and self.CM.File ~= model) then
                model = self.CM.File
                ClientLog("swap.. %s",model)
            end

            if (self.currModel ~= model) then

                DebugLog("setmodel: %s->%s == %s",self:GetName()or"",model or"",self.currModel or"")

                self.currModel = model;
                self:LoadCharacter(0, model);

                --set all animation events
                self:InitAnimationEvents();

                --set IK limbs
                self:InitIKLimbs();

                self:ForceCharacterUpdate(0, false);
                if (self.Properties.objFrozenModel and self.Properties.objFrozenModel~="") then
                    self:LoadObject(1, self.Properties.objFrozenModel);
                    self:DrawSlot(1, 0);
                end

                self:CreateBoneAttachment(0, "weapon_bone", "right_item_attachment");
                self:CreateBoneAttachment(0, "alt_weapon_bone01", "left_item_attachment");

                --laser bone (need it for updating character correctly when out of camera view)
                self:CreateBoneAttachment(0, "weapon_bone", "laser_attachment");

                if(self.CreateAttachments) then
                    self:CreateAttachments();
                end
            end

            if (self.currItemModel ~= self.Properties.fpItemHandsModel) then
                self:LoadCharacter(3, self.Properties.fpItemHandsModel);
                self:DrawSlot(3, 0);
                self:LoadCharacter(4, self.Properties.fpItemHandsModel); -- second instance for dual wielding
                self:DrawSlot(4, 0);

                self.currItemModel = self.Properties.fpItemHandsModel;
            end
        end
    })
    client:Inject({
        Class    = "g_localActor",
        Target   = "OnAction",
        PatchEntities = true,
        Function = function(self, action, ac, value)
            if (action == "use" or action == "xi_use") then
                self:UseEntity( self.OnUseEntityId, self.OnUseSlot, ac=="press") end
            g_Client:OnAction(self,action,ac,value)
            if(g_gameRules.Client.OnActorAction)then g_gameRules.Client.OnActorAction(g_gameRules,self,action,ac,value)end
            if(g_gameRules.OnAction)then g_gameRules:OnAction(self,action,ac,value)end -- hola! que es eso?
        end
    })
    client:Inject({
        Class    = "Player",
        Target   = "DoPainSounds",
        PatchEntities = true,
        Function = function(self, dead)
            if (not dead) then
                if (self.lastPainSound and ((_time-self.lastPainTime<5.0) or Sound.IsPlaying(self.lastPainSound))) then
                    return;
                end
            end

            local sound;
            if (dead) then
                if(not self.actor:IsLocalClient()) then
                    sound = GetRandomSound(self.voiceTable.death_mp);
                else
                  --  sound = GetRandomSound(self.voiceTable.death);
                end
            else
                if(not self.actor:IsLocalClient()) then
                    sound = GetRandomSound(self.voiceTable.pain_mp);
                else
                    sound = GetRandomSound(self.voiceTable.pain);
                end
            end

            if (sound) then
                local sndFlags = bor(bor(SOUND_EVENT, SOUND_VOICE), SOUND_DEFAULT_3D);
                self.lastPainSound = self:PlaySoundEvent(sound[1], g_Vectors.v000, g_Vectors.v010, sndFlags, SOUND_SEMANTIC_PLAYER_FOLEY);
                self.lastPainTime = _time;
            end
        end
    })
    client:Inject({
        Class    = "Player",
        Target   = "WallBloodSplat",
        PatchEntities = true,
        Function = function(self, aHit)
            if (aHit.material) then
                local dist = 2.5;
                local dir = vecScale(aHit.dir, dist);
                local	hits = Physics.RayWorldIntersection(aHit.pos,dir,1,ent_all,aHit.targetId,nil,g_HitTable);

                local splat = g_HitTable[1];
                if (hits > 0 and splat and ((splat.dist or 0)>0.25)) then
                    local n = table.getn(self.bloodSplatWall);
                    local i = math.random(1,n);
                    local s = 0.25+(splat.dist/dist)*0.35;

                    Particle.CreateMatDecal(splat.pos, splat.normal, s, 300, self.bloodSplatWall[i], math.random()*360, vecNormalize(aHit.dir), splat.entity and splat.entity.id, splat.renderNode);
                end
            end
        end
    })
    client:Inject({
        Class    = "Player",
        Target   = "BloodPool",
        PatchEntities = true,
        Function = function(self, hit)
            local iHP = self.actor:GetHealth()
            if (not iHP or iHP >= 1) then
                if (self.BLOODPOOL_TIMER) then Script.KillTimer(self.BLOODPOOL_TIMER) end
                return
            end

            self:GetVelocity(g_Vectors.temp_v1)
            if (LengthSqVector(g_Vectors.temp_v1) > 0.2) then
                if (self.BLOODPOOL_TIMER) then Script.KillTimer(self.BLOODPOOL_TIMER) end
                self.BLOODPOOL_TIMER = Script.SetTimer(100, function() if (self and System.GetEntity(self.id)) then self.BloodPool(self, hit) end end)
                return
            end

            if (self.BLOODPOOL_TIMER) then
                Script.KillTimer(self.BLOODPOOL_TIMER)
            end

            local pos = self:GetBonePos("Bip01 Pelvis", g_Vectors.temp_v1)
            if (pos == nil) then
                return
            end
            pos.z = pos.z + 1;

            local dir = { x = 0, y = 0, z = -3 }
            local hits = Physics.RayWorldIntersection(pos, dir, 3, ent_terrain + ent_static, self.id or NULL_ENTITY, nil, g_HitTable)
            local splat = g_HitTable[1];
            if (hits > 0 and splat) then

                local n = table.getn(self.bloodSplatGround)
                local i = math.random(1, n)
                local s = 0.8 * splat.dist --calcDist(pos, splat.pos)
                Particle.CreateMatDecal(splat.pos, splat.normal, s, 300, self.bloodSplatGround[i], math.random() * 360, vecNormalize(dir), splat.entity and splat.entity.id, splat.renderNode, 6, true)
            end
        end
    })
    client:Inject({
        Class    = "Player",
        Target   = "BloodSplat",
        PatchEntities = true,
        Function = function(self, hit)
            if (hit.material) then
                local dist = 2.5;
                local dir = vecScale(hit.dir, dist)
                local hits = Physics.RayWorldIntersection(hit.pos, dir, 1, ent_all, hit.targetId, nil, g_HitTable)

                local splat = g_HitTable[1];
                if (hits > 0 and splat and ((splat.dist or 0) > 0.25)) then
                    local n = table.getn(self.bloodSplatWall)
                    local i = math.random(1, n)
                    local s = 0.25 + (splat.dist / dist) * 0.35;
                    Particle.CreateMatDecal(splat.pos, splat.normal, s, 300, self.bloodSplatWall[i], math.random()*360, vecNormalize(hit.dir), splat.entity and splat.entity.id, splat.renderNode)
                end
            end
        end
    })
    client:Inject({
        Class    = "Player",
        Target   = "ClInit",
        PatchEntities = true,
        Function = function(self)

            self.CM = self.CM or { ID = 0, File = "" }

            -- Shorts
            self.IsDead       = function(this) return (this.actor:GetHealth() <= 0) end
            self.IsAlive      = function(this) return (this.actor:GetHealth() >  0) end
            self.IsSpectating = function(this) return (this.actor:GetSpectatorMode() > 0) end
            self.IsFlying     = function(this) return (this.actor:IsFlying() and (this.actorStats.inAir or 0) > 0.05) end
            self.GetChannel   = function(this) return (this.actor:GetChannel()) end
            self.GetPelvisPos = function(this) return (this:GetBonePos("Bip01 Pelvis")) end
            self.GetHeadPos   = function(this) return (this.actor:GetHeadPos()) end
            self.GetHeadDir   = function(this) return (this.actor:GetHeadDir()) end
            self.GetLoopAt    = function(this) return (this.actor:GetLookatPoint()) end
            self.GetSuitMode  = function(this,c) local m = this.actor:GetNanoSuitMode() if (c) then return m==c end return m end
            self.GetVehicle   = function(this,c) return GetEntity(self.actor:GetLinkedVehicleId()) end

            -- Longs, like on the server!
            self.RegisterAnimationLoop  = function(this, ...) return (g_Client.AnimationHandler:StartAnimation(this, ...)) end
            self.ClAnimationEvent       = function(this, ...) return (g_Client.AnimationHandler:OnAnimationEvent(this, ...)) end

            self.Initialized = true
            self.InitTimer = timerinit()

            if (GetCVar("crymp_animation_handler") > 0) then
                g_Client.AnimationHandler:ResetPlayer(self)
                g_Client.AnimationHandler:InitPlayer(self)
            end

            ClientLog("%s.ClInit()", self:GetName())
        end
    })
end

--=========================================================
-- Patch Game rules (and flags..)
ClientMod.PatchGameRules = function(self)


    -- =========================================================================================================
    self:Inject({
        Class    = "g_gameRules",
        Target   = "CanWork",
        Function = function(this, building, vehicleName)
            return true
        end
    })

    -- =========================================================================================================
    self:Inject({
        Class    = "g_gameRules",
        Target   = "Client.OnHit",
        Function = function(self, aHitInfo)

            if ((not aHitInfo.target) or (not self.game:IsFrozen(aHitInfo.target.id))) then
                local target = aHitInfo.target;
                if (target and (not aHitInfo.backface) and target.Client and target.Client.OnHit) then
                    target.Client.OnHit(target, aHitInfo)
                end
            end
        end
    })

    -- =========================================================================================================
    -- Power Struggle Shit
    -- =========================================================================================================

    if (IS_PS) then

        self:Inject({
            Class    = "g_gameRules",
            Target   = "Client.OnVehicleCancel",
            Function = function(this, building, vehicleName)
                if (timerexpired(this.BLETimers, 1)) then
                    HUD.BattleLogEvent(eBLE_Information, "@mp_BLVehicleConstructionCancel", this:GetItemName(vehicleName))
                    HUD.ShowConstructionProgress(false, false, 0)
                    this:PlaySoundAlert("constructcancel")

                    this.BLETimers = timerinit()
                end
            end
        })
        self:Inject({
            Class    = "g_gameRules",
            Target   = "Client.OnVehicleQueued",
            Function = function(this, building, vehicleName)
                if (timerexpired(this.BLETimers, 1)) then
                    HUD.BattleLogEvent(eBLE_Information, "@mp_BLVehicleConstructionQueued", this:GetItemName(vehicleName))
                    HUD.ShowConstructionProgress(true, true, 0)

                    this.BLETimers = timerinit()
                end
            end
        })
    end

    self:Inject({
        Class    = "g_gameRules",
        Target   = { "Client.InGame.OnDisconnect", "Client.PreGame.OnDisconnect", "Client.PostGame.OnDisconnect", "Client.OnDisconnect" },
        Function = function(this, cause, desc) -- doesnt get called anymore for whatever unknown reason
            System.LogAlways("$4Disconnecting")
            if (g_Client) then
                g_Client:Delete(cause, desc)
            end
        end
    })

    -- =========================================================================================================
    -- Flag bug!
    -- =========================================================================================================

    self:Inject({
        Class    = "Flag",
        Target   = "SetTeam",
        Function = function(self, teamName)
            if (self.teamName~=teamName) then
                local action= "";
                local team	= "";
                local speed = 1;

                if (self.teamName and self.teamName~="") then
                    if (teamName~="") then
                        action="up";
                        team=teamName;
                        speed=500;
                    else
                        action="down";
                        team=self.teamName;
                    end
                else
                    if (teamName~="") then
                        action="up";
                        team=teamName;
                    end
                end

                if (action~="") then
                    ClientLog("whats the error? its %s OR %s (maybe its %s)!!", g_ts(team), g_ts(action), g_ts(self.Properties.animationTemplate))
                    local animation=string.format(self.Properties.animationTemplate, g_ts(team), action);
                    self:StartAnimation(0, animation, 0, 0.250, speed, false, false, true);
                    self:ForceCharacterUpdate(0, true);
                    local time=self:GetAnimationLength(0, animation)*1000/speed;
                    time=math.max(0, time-125);
                    self:SetTimer(0, time);
                end
                self.teamName=teamName;
            end
        end
    })

end

--=========================================================
-- InitLibs
ClientMod.InitLibs = function()

    --- TIMER ---
    timerinit=function()return os.clock()  end
    timerdiff=function(t)return os.clock()-t  end
    timerexpired=function(t,e) return t==nil or timerdiff(t)>=e  end

    --- LUA ---
    isArray=function(h)return type(h)=="table" end
    isNumber=function(h)return type(h)=="number" end
    isString=function(h)return type(h)=="string" end
    isFunction=function(h)return type(h)=="function" end
    isUserdata=function(h)return type(h)=="userdata" or string.match(g_ts(h),"^userdata:.*$") end
    isNull=function(h)return h==nil end
    checkNumber=function(h,d)if (not isNumber(h)) then return (d or 0) end return h end
    checkString=function(h,d)if (not isString(h)) then return (d or "") end return h end
    checkArray=function(h,d)if (not isArray(h)) then return (d or {}) end return h end
    checkVar=function(h,d)if (isNull(h)) then return (d) end return h end
    getrandom = function(x,y) if (isArray(x)) then return x[math.random(#x)] end return math.random(x,y) end

    --- ARRAY ---
    table.count=function(t)local x=0 if(not isArray(t))then return x end for i,v in pairs(t) do x=x+1 end return x end
    table.size=table.count
    table.empty=function(t)return table.size(t)==0  end

    --- STRING ---
    string.empty=function(s)return(s==nil or string.len(s)==0)end
    string.split = function(sString, sDelims, level)
        if (string.empty(sString)) then return {} end
        local iString = string.len(sString)
        if (not sDelims) then sDelims = "" end
        local iDelimsLen = string.len(sDelims) if (iDelimsLen <= 1) then iDelimsLen = 0 else iDelimsLen = iDelimsLen - 1 end
        local aRes = {}
        local sCollect = ""
        local nSkip
        for i = 1, iString do if (not nSkip or i >= nSkip) then local sChar = string.sub(sString, i, i + iDelimsLen)
            if (sDelims == "") then table.insert(aRes, sChar)
            elseif (sChar == sDelims) then
                if (sCollect ~= "" or (i > 1 and i < iString)) then table.insert(aRes, sCollect) end
                nSkip = (i + iDelimsLen + 1)
                sCollect = ""
            else sCollect = sCollect .. string.sub(sString, i, i) end
            if (sCollect ~= "" and i == iString) then table.insert(aRes, sCollect) end end
        end
        for i = 1, (level or 0) do table.popFirst(aRes, i) end return aRes
    end

    --- VECTOR ---
    vector=(vector or {})
    vector.distance=function(a,b)local dx=b.x-a.x local dy=b.y-a.y local dz=b.z-a.z return math.sqrt(dx * dx + dy * dy + dz * dz)end
    vector.scale=function(a,b)return{x=a.x*b,y=a.y*b,z=a.z*b}end
end

--=========================================================
-- Animation Handler

-- !!! !!! !!!  !!!  !!!  !!!  !!!  !!!  !!!  !!!  !!!  !!!  !!!  !!!  !!!  !!!  !!!  !!!  !!!  !!!
-- !!! !!! !!!  !!!  !!!  !!!  !!!  !!!  !!!  !!!  !!!  !!!  !!!  !!!  !!!  !!!  !!!  !!!  !!!  !!!
-- !!!                R    E    W    R    I    T    E         T    H    I    S                   !!!
-- !!! !!! !!!  !!!  !!!  !!!  !!!  !!!  !!!  !!!  !!!  !!!  !!!  !!!  !!!  !!!  !!!  !!!  !!!  !!!
-- !!! !!! !!!  !!!  !!!  !!!  !!!  !!!  !!!  !!!  !!!  !!!  !!!  !!!  !!!  !!!  !!!  !!!  !!!  !!!

ClientMod.AnimationHandler = {

    UpdateRate = 0.15,

    cfg = {
        bStatus = true,
        aDefaultProps = {
            AnimName = nil, -- The Name of the Animation
            MinSpeed = nil, -- If > 0, Only play when player is moving faster than this speed
            MaxSpeed = nil, -- If > 0, Only play when player is moving slower than this speed
            OnGround = nil, -- If 1 or true, Only play when player is standing
            InAir = nil, -- If 1 or true, Only play when player is flying
            InWater = nil, -- If 1 or true, Only play when player is in/under water
            OnlyAlive = nil, -- If 1 or true, Only play when player is alive (default: true)
            NoSwimming = nil, -- If 1 or true, Only play when player is NOT swimming
            NoSpectator = nil, -- If 1 or true, Only play when player is not spectating (default: true)
            RequiredStance = nil, -- The Required Stance(s) for the Animation to play
            Condition = nil, -- The Condition for the Animation to be able to play (must return true (can be followed by a new animation name that will be used instead of the AnimName one))
            Events = nil, --[[ { -- Event callbacks what happen during the animation
						OnHit = function(hClient, aHit, bBulletOrMelee) end, -- Called when the client gets hit
						OnKilled = function(hClient) end, -- Called when the client dies (not called when entering spectator mode, which also counts and dying)
						OnRevived = function(hClient) end, -- Called when the client gets revived
					} ]]
        },
    },
    ---------------------------------------------------------
    -- Data
    ANIMATION_DATA      = {},
    ANIM_COUNTERS       = {},
    CACHED_ANIM_TIMES   = {},
    ANIMATION_COUNTER   = 0,
    ---------------------------------------------------------
    -- Constructor
    Init = function(self)

        -- synced with server
        -- Client Model IDs
        CM_NONE, CM_DEFAULT, CM_KYONG, CM_KOREANAI,
        CM_AZTEC, CM_JESTER, CM_SYKES, CM_PROPHET,
        CM_PSYCHO, CM_BADOWSKY, CM_SCIENTIST, CM_KEEGAN,
        CM_EGIRL1, CM_EGIRL2, CM_BRADLEY, CM_RICHARD,
        CM_NKPILOT, CM_GONGPITTER, CM_EGIRL3, CM_JUMPSAILOR,
        CM_USPILOT, CM_MARINE, CM_CORONA, CM_OFFICER,
        CM_TECHNICIAN, CM_EGIRL4, CM_ARCHAEOLOGIST, CM_FIREFIGHTER,
        CM_WORKER, CM_ALIEN, CM_HUNTER, CM_SCOUT,
        CM_SHARK, CM_DOG, CM_TROOPER, CM_CHICKEN,
        CM_TURTLE, CM_CRAB, CM_FINCH, CM_TERN,
        CM_FROG, CM_ALIENWORK, CM_HEADLESS =
        0, 1, 2, 3, 4, 5, 6, 7,
        8, 9, 10, 11, 12, 13, 14, 15,
        16, 17, 18, 19, 20, 21, 22, 23,
        24, 25, 26, 27, 28, 29, 30, 31,
        32, 33, 34, 35, 36, 37, 38, 39,
        40, 41, 1000


        -- Client Event Cases
        eCE_AnimMelee, eCE_AnimHit, eCE_AnimTick
        = 1, 2, 3

        -- Client Event Cases
        eSE_Melee, eSE_StartMoving, eSE_Moving, eSE_Flying, eSE_Jump, eSE_Dead, eSE_Idle
        = 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11

    end,
    ---------------------------------------------------------
    -- Constructor
    ResetPlayer = function(self, hPlayer)

        hPlayer.bPlayingAnim = false
        hPlayer.idPlayingAnim = nil
        hPlayer.idPlayingAnimIndex = nil
        hPlayer.sLastAnimPlayed = nil
        hPlayer.iLastAnimSpeed = nil
        hPlayer.ModifiedCharacterOffset = nil
        hPlayer.hTimerLastAnimEffect = nil
        hPlayer.hTimerLastHit = nil

        local hChar = hPlayer.hAnimatedCharacter
        if (hChar) then
            hChar:DetachThis()
            System.RemoveEntity(hChar.id)
        end
        hPlayer.hAnimatedCharacter = nil

        if (hPlayer.bHiddenByAC) then
            hPlayer:DrawSlot(0, 1)
        end
        hPlayer.bHiddenByAC = nil

    end,
    ---------------------------------------------------------
    -- Constructor
    InitPlayer = function(self, hPlayer)
        self:RegisterAnimations(hPlayer)
    end,
    ---------------------------------------------------------
    -- Destructor
    Shutdown = function(self)
    end,
    ---------------------------------------------------------
    -- ResetAnimData
    ResetAnimData = function(self, hPlayer)
        hPlayer.sLastMeeleAnim = nil
        hPlayer.sLastIdleAnim = nil
        hPlayer.sLastStaggerAnim = nil
    end,
    ---------------------------------------------------------
    -- SoundEvent
    SoundEvent = function(self, hPlayer, iEvent, aAnimation)

        if (not hPlayer or not iEvent or not aAnimation or not self.cfg.bStatus) then
            return
        end

        local aEvents = aAnimation.SoundEvents
        local iVolume = checkNumber(aAnimation.SoundVolume, 1)
        if (not aEvents) then
            return
        end

        if (not hPlayer.aSoundEventSlots) then
            hPlayer.aSoundEventSlots = {}
        end

        local hTimer
        local iTime = 6
        local sSound

        if (iEvent == eSE_Melee and aEvents.Melee) then
            hTimer = "hTimerMeleeSound"
            iTime = 1
            if (isArray(aEvents.Melee)) then
                iTime = checkNumber(aEvents.Melee.Time, iTime)
                sSound = aEvents.Melee.Sound
            else
                sSound = aEvents.Melee
            end
        elseif (iEvent == eSE_Jump and aEvents.Jump) then

            hTimer = "hTimerJumpSound"
            iTime = 1
            if (isArray(aEvents.Jump)) then
                iTime = checkNumber(aEvents.Jump.Time, iTime)
                sSound = aEvents.Jump.Sound
            else
                sSound = aEvents.Jump
            end
        elseif (iEvent == eSE_Idle and aEvents.Idle) then

            hTimer = "hTimerIdleSound"
            iTime = 8
            if (isArray(aEvents.Idle)) then
                iTime = checkNumber(aEvents.Idle.Time, iTime)
                sSound = aEvents.Idle.Sound
            else
                sSound = aEvents.Idle
            end
        elseif (iEvent == eSE_StartMoving and aEvents.StartMoving) then

            hTimer = "hTimerStartMoveSound"
            iTime = 1
            if (isArray(aEvents.StartMoving)) then
                iTime = checkNumber(aEvents.StartMoving.Time, iTime)
                sSound = aEvents.StartMoving.Sound
            else
                sSound = aEvents.StartMoving
            end
        elseif (iEvent == eSE_Moving and aEvents.Moving) then

            hTimer = "hTimerMoveSound"
            iTime = 10
            if (isArray(aEvents.Moving)) then
                iTime = checkNumber(aEvents.Moving.Time, iTime)
                sSound = aEvents.Moving.Sound
            else
                sSound = aEvents.Moving
            end
        elseif (iEvent == eSE_Dead) then

            self:StopAllSounds(hPlayer, { [eSE_Dead] = true })
            if (aEvents.Death) then
                hTimer = "hTimerDeathSound"
                if (isArray(aEvents.Death)) then
                    iTime = checkNumber(aEvents.Death.Time, iTime)
                    sSound = aEvents.Death.Sound
                else
                    sSound = aEvents.Death
                end
            end
        else
            ClientLog( "Invalid sound event to SoundEvent(%s)", tostring(iEvent))
            return
        end

        if (not sSound) then
            return
        end

        if (Sound.IsPlaying(hPlayer.aSoundEventSlots[iEvent])) then
            hPlayer[hTimer] = timerinit()
            return
        end

        if (not timerexpired(hPlayer[hTimer], iTime)) then
        --    ClientLog("too early for this sound event")
            return
        end

        Sound.StopSound(hPlayer.aSoundEventSlots[iEvent])
        hPlayer.aSoundEventSlots[iEvent] = hPlayer:PlaySoundEvent(sSound, g_Vectors.v000, g_Vectors.v010, SOUND_EVENT, SOUND_SEMANTIC_SOUNDSPOT)
        Sound.SetSoundVolume(hPlayer.aSoundEventSlots[iEvent], iVolume)
        hPlayer[hTimer] = timerinit()

       -- ClientLog( "Playing sound %s", sSound)

    end,
    ---------------------------------------------------------
    -- StopAllSounds
    StopAllSounds = function(self, hEntity, aIngore)

        if (not hEntity or not hEntity.aSoundEventSlots) then
            return
        end

        for i, hSoundEvent in pairs(hEntity.aSoundEventSlots) do
            if (aIngore == nil or not aIngore[i]) then
                Sound.StopSound(hSoundEvent)
                hEntity.aSoundEventSlots[i] = nil
            end
        end
    end,
    ---------------------------------------------------------
    -- OnAnimationEvent
    OnAnimationEvent = function(self, hPlayer, iEvent, xParam1, xParam2, ...)

        if (not hPlayer or not iEvent or not self.cfg.bStatus) then
            return
        end

        local aAnims = self.ANIMATION_DATA[hPlayer.id]
        local idAnim = hPlayer.idPlayingAnimIndex
        local aAnim, aEvents
        if (aAnims and idAnim) then
            aAnim = aAnims[idAnim]
            if (aAnim) then
                aEvents = aAnim.Events
            end
        end

     --   ClientLog( "aAnims = %s, idAnim = %s, aAnim = %s, aEvents = %s", tostring(aAnims), tostring(idAnim), tostring(aAnim), tostring(aEvents))

        if (iEvent == eCE_AnimMelee) then
            self:ResetAnimData(hPlayer)
            self:SoundEvent(hPlayer, eSE_Melee, aAnim)
            hPlayer.MeleeAnimTimer = timerinit()
        elseif (iEvent == eCE_AnimHit) then

            hPlayer.aLastRegisteredHit = xParam1
            hPlayer.hTimerLastHit = timerinit()
            hPlayer.bWasHit = true

            if (aEvents and aEvents.OnHit) then
                aEvents.OnHit(hPlayer, xParam1, xParam2)
            end
        elseif (iEvent == eCE_AnimTick) then
            if (aEvents and aEvents.OnTick) then
                aEvents.OnTick(hPlayer)
            end
        else
            ClientLog( "Invalid Animation Event to OnAnimationEvent()")
        end

    end,
    ---------------------------------------------------------
    -- GetAnimationLength
    GetAnimationLength = function(self, hPlayer, sAnim)

        if (not hPlayer or not sAnim) then
            return
        end

        if (self.CACHED_ANIM_TIMES[sAnim]) then
            return self.CACHED_ANIM_TIMES[sAnim]
        end

        local iLen = hPlayer:GetAnimationLength(0, sAnim)
        if (iLen == -1) then
            return
        end

        self.CACHED_ANIM_TIMES[sAnim] = iLen
        return iLen

    end,
    ---------------------------------------------------------
    -- RegisterAnimations
    RegisterAnimations = function(self, hPlayer, bForce)
        if (not hPlayer) then
            return
        end

        ClientLog( "Registering Animation Events for %s", hPlayer:GetName())

        self:StartAnimation(hPlayer, {
            Condition = function(hClient, aAnimation)
                if (not hClient or hClient.CM.ID == 0) then
                    --ClientLog("no cm")
                    return false
                end

               -- ClientLog("hClient.CM=%d",checkNumber(hClient.CM.ID,-1))
                local sMelee, sAnim, sStagger, iSpeed, iTime, iStart
                local iClientSpeed = hClient:GetSpeed()

                aAnimation.AnimatedCharacter = nil
                aAnimation.CharacterOffset = nil
                aAnimation.Events = nil
                aAnimation.SoundEvents = nil
                aAnimation.SoundVolume = nil

                if (hClient.CM.ID == CM_FROG) then
                    sAnim = "frog_idle_01"
                    if (iClientSpeed > 0.5) then
                        sAnim = "frog_walk_01"
                        iSpeed = self:CalculateAnimationSpeedFromVelocity(iClientSpeed, nil, 1, 5)
                    end

                    aAnimation.SoundVolume = 5
                    aAnimation.SoundEvents = {
                        Idle = "sounds/environment:random_oneshots_natural:frog_idle",
                        Melee = "sounds/environment:random_oneshots_natural:frog_scared",
                        Jump = "sounds/environment:random_oneshots_natural:frog_idle",
                        Flying = nil,
                        Moving = nil,
                        StartMoving = "sounds/environment:random_oneshots_natural:frog_scared",
                        Death = "sounds/environment:random_oneshots_natural:frog_scared"
                    }

                    return true, sAnim, iSpeed, iTime

                -- =================================================================================
                elseif (hClient.CM.ID == CM_TERN) then
                    sAnim = "fly_loop"
                    if (iClientSpeed < 1) then
                        iSpeed = GetCVar("a_testmodel_tern_idleAnimSpeed")
                        iTime = GetCVar("a_testmodel_tern_idleAnimTime")
                        iStart = GetCVar("a_testmodel_tern_idleAnimStart")
                    else
                        iSpeed = self:CalculateAnimationSpeedFromVelocity(iClientSpeed, nil, 1, 1.25)
                        --	sAnim = "fly_fly" -- BROKEN !!! UGLY !!!
                    end

                    aAnimation.Events = { OnTick = function(hClient)

                        local iMaxVelocity = 16
                        local iVelocity = hClient:GetSpeed()
                        if (iVelocity > iMaxVelocity) then
                            iVelocity = iMaxVelocity
                        end

                        local iBaseMass = 80
                        local iNewMass = ((1 - (iVelocity / iMaxVelocity)) * iBaseMass)

                        local iBaseGravity = -9.8
                        local iNewGravity = ((1 - (iVelocity / iMaxVelocity)) * iBaseGravity)
                        local sNewGravity = tostring(string.format("%0.4f", iNewGravity))
                        local sCurrGravity = string.format("%0.4f", System.GetCVar("p_gravity_z"))

                        PREVIOUS_GRAVITY = checkVar(PREVIOUS_GRAVITY, System.GetCVar("p_gravity_z"))
                        if (sCurrGravity ~= sNewGravity and hClient.id == g_localActorId) then
                            Msg(1, "New gravity: %s",sNewGravity)
                            CPPAPI.FSetCVar("p_gravity_z", sNewGravity)
                        end
                        GRAVITY_MODIFIED = true

                        if (W_KEY_PRESSED and hClient.id == g_localActorId and iVelocity > 1.5) then
                            hClient:AddImpulse(-1, hClient:GetCenterOfMassPos(), System.GetViewCameraDir(), GetCVar("a_flying_bird_speed") * (2 + (iVelocity / iMaxVelocity)), 1)
                            hClient:AddImpulse(-1, hClient:GetCenterOfMassPos(), g_Vectors.up, 1, 1)
                        end

                    end }
                    return true, sAnim, iSpeed, iTime, iStart

                    -- =================================================================================
                elseif (hClient.CM.ID == CM_EGIRL2) then
                    sAnim = "cineFleet_ab1_FlightDeckHelenaIdle_01"
                    return true, sAnim

                    -- =================================================================================
                elseif (hClient.CM.ID == CM_SHARK) then
                    sAnim = "shark_swim_01"
                    iSpeed = 0.25
                    if (not timerexpired(hClient.MeleeAnimTimer, self:GetAnimationLength(hPlayer, "shark_swim_bite_01"))) then
                        Msg(1, "Shark melee")
                        sAnim = "shark_swim_bite_01"
                        iSpeed = 1
                    elseif (iClientSpeed > 1) then
                        sAnim = "shark_swim_01"
                        iSpeed = 1
                    end
                    return true, sAnim, iSpeed, iTime

                    -- =================================================================================
                elseif ((hClient.CM.ID == CM_TROOPER or hClient.CM.ID == CM_DOG)) then
                    sMelee = hClient.sLastMeeleAnim or getrandom({ "trooper_meleeattack_01", "trooper_meleeattack_02", "trooper_meleeattack_03" })
                    hClient.sLastMeeleAnim = sMelee

                    sAnim = hClient.sLastIdleAnim or getrandom({ "trooper_idleVert_01" })--, "trooper_idleVert_indoor_01", "trooper_idleVert_02" })
                    hClient.sLastIdleAnim = sAnim

                    --sStagger = hClient.sLastStaggerAnim or getrandom({ "trooper_heavyHitFly_01" })
                    --hClient.sLastStaggerAnim = sAnim

                    iSpeed = 1
                    if (not timerexpired(hClient.MeleeAnimTimer, self:GetAnimationLength(hClient, sMelee))) then
                        sAnim = sMelee
                        iSpeed = 1
                    elseif (hClient:IsFlying()) then
                        sAnim = "trooper_jump1m_forward_01"
                        if (not timerexpired(hClient.hTimerLastHit, self:GetAnimationLength(hClient, "trooper_heavyHitFly_01"))) then
                            sAnim = "trooper_heavyHitFly_01"
                        end
                        iSpeed = 1
                    elseif (iClientSpeed <= 4 and not timerexpired(hClient.hTimerLastHit, self:GetAnimationLength(hClient, "trooper_heavyHit_01"))) then
                        sAnim = "trooper_heavyHit_01"
                        iSpeed = 1
                    elseif (iClientSpeed > 0.5) then
                        sAnim = "trooper_flyVert_forward_fast_01"
                        iSpeed = 1
                    end

                    --if (sAnim ~= hClient.sLastIdleAnim) then
                    --	hClient.sLastIdleAnim = nil
                    --end

                    aAnimation.Events = {
                        OnRevived = function(hPlayer)
                            self:SetActorModel()
                        end,
                        OnHit = function(hPlayer, aHit, bBulletOrMelee)
                            if (bBulletOrMelee and timerexpired(hPlayer.hTimerLastAnimEffect, 1)) then
                                hPlayer.hTimerLastAnimEffect = timerinit()
                                Particle.SpawnEffect("melee.hit_alien.hit", aHit.pos, (aHit.normal or aHit.dir), 1.5)
                            end
                        end,
                        OnKilled = function(hPlayer)
                            Particle.SpawnEffect("alien_special.Trooper.death_explosion", hPlayer:GetPos(), g_Vectors.up, 0.3)
                        end,
                    }

                    return true, sAnim, iSpeed, iTime

                    -- =================================================================================
                elseif (hClient.CM.ID == CM_CHICKEN) then
                    sAnim = "idle01"
                    iSpeed = 1
                    if (hClient:IsFlying()) then
                        sAnim = "pickup"
                        iSpeed = 2
                        iTime = 0.4
                    elseif (not timerexpired(hClient.MeleeAnimTimer, 1.5 or self:GetAnimationLength(hClient, "pickup"))) then
                        sAnim = "pickup"
                        iSpeed = 1.25
                        iTime = 1.5
                    elseif (iClientSpeed > 0.5) then
                        sAnim = "walk_loop"
                        iSpeed = self:CalculateAnimationSpeedFromVelocity(iClientSpeed, nil, 1, 5)
                    end

                    aAnimation.SoundEvents = {
                        Idle = "sounds/environment:random_oneshots_natural:chicken_cluck",
                        Melee = "sounds/environment:random_oneshots_natural:chicken_dies",
                        Jump = "sounds/environment:random_oneshots_natural:chicken_throw",
                        Flying = nil,
                        Moving = nil,
                        StartMoving = "sounds/environment:random_oneshots_natural:chicken_run",
                        Death = "sounds/environment:random_oneshots_natural:chicken_dies"
                    }
                    aAnimation.Events = {
                        OnRevive = nil,
                        OnHit = function(hPlayer, aHit, bBulletOrMelee)
                            if (bBulletOrMelee and timerexpired(hPlayer.hTimerLastAnimEffect, 1)) then
                                hPlayer.hTimerLastAnimEffect = timerinit()
                                Particle.SpawnEffect("bullet.hit_feathers.a", aHit.pos, (aHit.normal or aHit.dir), 0.8)
                            end
                        end,
                        OnKilled = function(hPlayer)
                            Particle.SpawnEffect("bullet.hit_feathers.a", hPlayer:GetPos(), g_Vectors.up, 1)
                        end,
                    }

                    return true, sAnim, iSpeed, iTime

                    -- =================================================================================
                elseif (hClient.CM == CM_FINCH or hClient.CM == CM_TURTLE or hClient.CM == CM_CRAB) then
                    sAnim = "idle01"
                    iSpeed = 1
                    if (iClientSpeed > 1) then
                        sAnim = "walk_loop"
                        iSpeed = (hClient.CM == CM_FINCH and 1.25 or 4)
                    end
                    return true, sAnim, iSpeed, iTime

                    -- =================================================================================
                elseif (hClient.CM.ID == CM_ALIENWORK or hClient.CM.ID == CM_ALIEN) then

                    aAnimation.AnimatedCharacter = {
                        Model = hClient.CMPath,
                        HidePlayer = true,
                        LocalPosition = { x = 0, y = 0, z = 1.5 }
                    }
                    aAnimation.CharacterOffset = { x = 2, y = 2, z = 2 }


                    sAnim = hClient.sLastIdleAnim or getrandom({ "alien_flyProneIdle_slow_01", "alien_flyProneIdle_fast_01", "alien_idleAim_01" })--, "trooper_idleVert_02" })
                    hClient.sLastIdleAnim = sAnim

                    iSpeed = 1
                    if (hClient:IsFlying()) then
                        sAnim = "alien_flyProne_forward_fast_02"
                        iSpeed = 1
                    elseif (not timerexpired(hClient.MeleeAnimTimer, self:GetAnimationLength(hClient, "alien_flyProneAttack_forward_fast_01"))) then
                        sAnim = "alien_flyProneAttack_forward_fast_01"
                        iSpeed = 1.0
                    elseif (iClientSpeed > 6) then
                        sAnim = "alien_flyProneAim_forward_fast_01"
                        iSpeed = 1
                    elseif (iClientSpeed > 1) then
                        sAnim = "alien_flyProneAim_forward_slow_01"
                        iSpeed = 1.5
                    end
                    return true, sAnim, iSpeed, iTime

                    -- =================================================================================
                end

                return false
            end
        }, "IDANIM_SHARK_ANIMS")
    end,
    ---------------------------------------------------------
    -- Destructor
    CalculateAnimationSpeedFromVelocity = function(self, iVelocity, iMultiplier, iMinSpeed, iMaxSpeed)

        iMaxSpeed = checkNumber(iMaxSpeed, 4)
        iMinSpeed = checkNumber(iMinSpeed, 0.75)

        local iSpeed = (iMaxSpeed * (iVelocity / 12))
        if (iSpeed > iMaxSpeed) then
            iSpeed = iMaxSpeed
        elseif (iSpeed < iMinSpeed) then
            iSpeed = iMinSpeed
        end

        return iSpeed * checkNumber(iMultiplier, 1)
    end,
    ---------------------------------------------------------
    -- Destructor
    GetInsertName = function(self, hPlayer)
        return ("ANIM_EVENT_" .. (hPlayer and hPlayer:GetChannel() or "NULL_CHAN") .. "_" .. self.ANIMATION_COUNTER)
    end,
    ---------------------------------------------------------
    -- StartAnimation
    StartAnimation = function(self, hPlayer, aProperties, idInsert)

        if (not self.ANIMATION_DATA[hPlayer.id]) then
            self.ANIMATION_DATA[hPlayer.id] = {}
        end

        self.ANIMATION_COUNTER = self.ANIMATION_COUNTER + 1

        idInsert = idInsert or self:GetInsertName()
        if (self.ANIMATION_DATA[hPlayer.id][idInsert]) then
            ClientLog( "WARNING: OVERWRITING EXISTING ANIMATION EVENT NOW")
        end

        aProperties.ID = self:MakeAnimationID(hPlayer, aProperties.AnimName)
        aProperties.IDIndex = idInsert
        self.ANIMATION_DATA[hPlayer.id][idInsert] = aProperties
    end,
    ---------------------------------------------------------
    -- StopAnimation
    StopAnimationEvent = function(self, hPlayer, idInsert)

        if (not self.ANIMATION_DATA[hPlayer.id]) then
            return
        end

        if (not idInsert) then
            return
        end

        self.ANIMATION_DATA[hPlayer.id][idInsert] = nil

    end,
    ---------------------------------------------------------
    -- Updater
    Update = function(self)

        if (not self.cfg.bStatus) then
            return
        end

        if (not timerexpired(self.UpdateTick, self.UpdateRate)) then
            return
        end self.UpdateTick = timerinit()

        local hPlayer
        for idPlayer, aEvents in pairs(self.ANIMATION_DATA) do

            hPlayer = System.GetEntity(idPlayer)
            if (not hPlayer) then
                for iEvent, aEvent in pairs(aEvents) do
                    self:DeleteCharacterAttachment(nil, aEvent)
                end
                self.ANIMATION_DATA[idPlayer] = nil
            else
                for iEvent, aEvent in pairs(aEvents) do
                    self:UpdateLoopedAnim(hPlayer, self.ANIMATION_DATA[idPlayer][iEvent])
                end
            end
        end

    end,
    ---------------------------------------------------------
    -- Destructor
    UpdateLoopedAnim = function(self, hPlayer, aAnimation)

        --if (not aAnimation.ID) then
        --	aAnimation.ID = self:MakeAnimationID(hPlayer, aAnimation.AnimName)
        --end

        --FIXME ASAP
        LOOPED_ANIMS=LOOPED_ANIMS or{}
        if (not LOOPED_ANIMS[hPlayer.id]) then

            --ClientLog( "Process Anim Slot " .. aAnimation.ID)
            if (not hPlayer.bPlayingAnim or aAnimation.ID == hPlayer.idPlayingAnim) then

                if (timerexpired(aAnimation.hTickTimer, 0.15) and hPlayer.bPlayingAnim) then
                    aAnimation.hTickTimer = timerinit()
                    self:OnAnimationEvent(hPlayer, eCE_AnimTick)
                end

                local sAnimName = aAnimation.AnimName
                local iAnimSpeed = checkNumber(aAnimation.AnimSpeed, 1)
                local iAnimTime = nil
                local iAnimStart = nil
                local bAnimOk, sError, iSpeed, iTime, iStartTime = self:CanPlayLoopedAnim(hPlayer, aAnimation)
                if (bAnimOk) then

                    if (sError) then
                        sAnimName = sError
                    end
                    if (iSpeed) then
                        iAnimSpeed = iSpeed
                    end
                    if (iTime) then
                        iAnimTime = iTime
                    end
                    if (iStartTime) then
                        iAnimStart = iStartTime
                    end

                    if (Remote and Remote.FORCED_CLIENT_ANIMATION) then
                        sAnimName = Remote.FORCED_CLIENT_ANIMATION
                    end

                    local vCharOffset = aAnimation.CharacterOffset
                    --[[
                            if (vCharOffset) then
                                if (not hPlayer.ModifiedCharacterOffset) then
                                    hPlayer.ModifiedCharacterOffset = true
                                    hPlayer.actor:SetParams({
                                        modelOffset = vCharOffset
                                    })
                                    local vOffset = hPlayer:GetWorldPos()
                                    vOffset.x = vOffset.x + checkNumber(vCharOffset.x, 0)
                                    vOffset.y = vOffset.y + checkNumber(vCharOffset.y, 0)
                                    vOffset.z = vOffset.z + checkNumber(vCharOffset.z, 0)

                                    hPlayer:SetSlotWorldTM(0, vOffset, hPlayer:GetDirectionVector())

                                    Msg(0, "OFFSET CHANGED ?")
                                end
                            elseif (hPlayer.ModifiedCharacterOffset) then

                                hPlayer.ModifiedCharacterOffset = nil
                                hPlayer.actor:SetParams({
                                    modelOffset = { x = 0, y = 0, z = 0 }
                                })
                                local vOffset = hPlayer:GetWorldPos()
                                hPlayer:SetSlotWorldTM(0, vOffset, hPlayer:GetDirectionVector())
                            end
                            --]]

                    self:ProcessAnimationEvents(hPlayer, aAnimation)
                    if (aAnimation.CharacterAttachment) then
                        self:SpawnCharacterAttachment(hPlayer, aAnimation.CharacterAttachment)
                    end

                    --[[
                            local aProps = aAnimation.AnimatedCharacter
                            local hChar = hPlayer.hAnimatedCharacter
                            if (aProps) then
                                if (not hPlayer.hAnimatedCharacter) then

                                    local hCharacter = System.SpawnEntity({
                                        class = checkVar(aProps.Class, "BasicEntity"),
                                        name = checkVar(aProps.Name, "Animated_Character_" .. hPlayer:GetName()),
                                        --properties = {
                                        --	object_Model =
                                        --}
                                    })

                                    local sModel = checkVar(aProps.Model, "")
                                    if (string.sub(sModel, -4) == ".chr") then
                                        hCharacter:LoadCharacter(0, sModel)
                                    else
                                        hCharacter:LoadObject(0, sModel)
                                    end

                                    hPlayer:AttachChild(hCharacter.id, 1)
                                    hCharacter:SetLocalPos(checkVar(aProps.LocalPosition, { x = 0, y = 0, z = 0 }))
                                    hCharacter:SetLocalAngles({ x = 0, y = 0, z = 0 })

                                    hPlayer.hAnimatedCharacter = hCharacter
                                    Msg(0, "Spawn")
                                end

                                if (aProps.HidePlayer) then
                                    Msg(0, "Hide")
                                    hPlayer.bHiddenByAC = true
                                    hPlayer:DrawSlot(0, 0)
                                end

                                if (hChar and hPlayer.id == g_localActorId) then
                                    hChar:EnablePhysics(false)
                                end
                            else
                                if (hPlayer.bHiddenByAC) then
                                    hPlayer.bHiddenByAC = nil
                                    hPlayer:DrawSlot(0, 1)
                                end
                                if (hChar) then
                                    hChar:DetachThis()
                                    System.RemoveEntity(hChar.id)
                                    hPlayer.hAnimatedCharacter = nil
                                end
                            end
                            ]]

                    if (iAnimTime) then
                        --Msg(0, "CUSTOM ANIM TIME: %f",iAnimTime)
                        --Msg(0, "%s",tostring((iAnimTime ~= nil and timerexpired(aAnimation.PlayTimer, iAnimTime))))
                    end
                    if (sAnimName and sAnimName ~= "" and ((iAnimTime ~= nil and timerexpired(aAnimation.PlayTimer, iAnimTime)) or (sAnimName ~= hPlayer.sLastAnimPlayed or iAnimSpeed ~= hPlayer.iLastAnimSpeed) or (hPlayer.bWasHit or timerexpired(aAnimation.PlayTimer, checkNumber(aAnimation.AnimTime, 0)) or (aAnimation.ForcedRestart and timerexpired(aAnimation.PlayTimer, aAnimation.ForcedRestart))))) then

                        --if (hPlayer.bWasHit and iAnimTime == nil and hPlayer.PlayTimer ~= nil) then
                        --	iAnimTime = timerdiff(hPlayer.PlayTimer)
                        --	Msg(0,"d=%f",iAnimTime)
                        --end
                        hPlayer.bWasHit = false

                        aAnimation.PlayTimer = timerinit()

                        hPlayer.sLastAnimPlayed = sAnimName
                        hPlayer.idPlayingAnim = aAnimation.ID
                        hPlayer.idPlayingAnimIndex = aAnimation.IDIndex
                        hPlayer.bPlayingAnim = true
                        hPlayer.bPlayingAnim = true

                        local hAnimTarget = hPlayer.hAnimatedCharacter
                        if (hAnimTarget == nil) then
                            hAnimTarget = hPlayer
                        end

                        hAnimTarget:StopAnimation(0, 8)
                        if (iAnimTime) then
                            hAnimTarget:StopAnimation(0, -1)
                        end
                        hAnimTarget:StartAnimation(0, sAnimName, 8, 0, iAnimSpeed, true)
                        if (iAnimStart) then
                            hAnimTarget:SetAnimationTime(0, 8, iAnimStart)
                        end

                        if (aAnimation.AnimTime == nil or iAnimSpeed ~= hPlayer.iLastAnimSpeed) then
                            aAnimation.AnimTime = ((hAnimTarget:GetAnimationLength(0, sAnimName) - checkNumber(iAnimStart, 0)) * (1 / iAnimSpeed))
                        end

                        hPlayer.iLastAnimSpeed = iAnimSpeed
                        if (sAnimName ~= hPlayer.sLastIdleAnim) then
                            hPlayer.sLastIdleAnim = nil
                        end
                        if (sAnimName ~= hPlayer.sLastStaggerAnim) then
                            hPlayer.sLastStaggerAnim = nil
                        end
                        if (sAnimName ~= hPlayer.sLastMeeleAnim) then
                            hPlayer.sLastMeeleAnim = nil
                        end

                    --    ClientLog( "Anim Speed: %f", aAnimation.AnimTime)
                    --    ClientLog( "STarted now %s (next in %fs)", sAnimName, timerdiff(timerinit()+aAnimation.AnimTime)*-1)

                    end
                else

                    self:ProcessAnimationEvents(hPlayer, aAnimation)

                    if (hPlayer.bPlayingAnim) then
                        hPlayer:StopAnimation(0, 8)
                        self:StopAnimation(hPlayer, aAnimation)
                    end
                   -- ClientLog( "-> error: %s", sError)
                end
            else
             --  ClientLog( "No updating slot " .. aAnimation.ID)
            end
        elseif (hPlayer.bPlayingAnim) then
            self:StopAnimation(hPlayer, aAnimation)
        end
    end,
    ---------------------------------------------------------
    -- ProcessAnimationEvents
    ProcessAnimationEvents = function(self, hPlayer, aAnimation)

        local iSpeed = hPlayer:GetSpeed()
        local bMoving = (iSpeed > 0.25)
        local bIsDead = hPlayer:IsDead()
        local bIsFlying = hPlayer:IsFlying()
        local bSpectating = hPlayer:IsSpectating()
        local bKilled = (not bSpectating and (bIsDead and not hPlayer.bOnKillCalled))
        local bRevived = ((not bIsDead and not hPlayer.bOnReviveCalled))
        local bJumped = (bIsFlying and not hPlayer.bOnJumpCalled)
        local bStartedMoving = (bMoving and not hPlayer.bOnStartMoveCalled)

        if (bKilled) then
            hPlayer.bOnKillCalled = true elseif (not bIsDead) then
            hPlayer.bOnKillCalled = false
        end
        if (bRevived) then
            hPlayer.bOnReviveCalled = true elseif (bIsDead) then
            hPlayer.bOnReviveCalled = false
        end
        if (bJumped) then
            hPlayer.bOnJumpCalled = true elseif (not bIsFlying) then
            hPlayer.bOnJumpCalled = false
        end
        if (bStartedMoving) then
            hPlayer.bOnStartMoveCalled = true elseif (not bMoving) then
            hPlayer.bOnStartMoveCalled = false
        end

        local aEvents = aAnimation.Events
        if (bKilled) then
            if (aEvents and aEvents.OnKilled) then
                aEvents.OnKilled(hPlayer, hPlayer.aLastRegisteredHit)
            end
            self:SoundEvent(hPlayer, eSE_Melee, aAnimation)
        end
        if (bRevived) then
            if (aEvents and aEvents.OnRevive) then
                aEvents.OnRevive(hPlayer)
            end
            self:SoundEvent(hPlayer, eSE_Revived, aAnimation)
        end
        if (bJumped) then
            if (aEvents and aEvents.OnStartFly) then
                aEvents.OnStartFly(hPlayer)
            end
            self:SoundEvent(hPlayer, eSE_Jump, aAnimation)
        end
        if (bIsFlying) then
            if (aEvents and aEvents.OnFlying) then
                aEvents.OnFlying(hPlayer)
            end
            self:SoundEvent(hPlayer, eSE_Flying, aAnimation)
        end
        if (bStartedMoving) then
            if (aEvents and aEvents.OnStartMoving) then
                aEvents.OnStartMoving(hPlayer)
            end
            self:SoundEvent(hPlayer, eSE_StartMoving, aAnimation)
        end
        if (bMoving) then
            if (aEvents and aEvents.OnMoving) then
                aEvents.OnMoving(hPlayer)
            end
            self:SoundEvent(hPlayer, eSE_Moving, aAnimation)
        else
            if (aEvents and aEvents.OnIdle) then
                aEvents.OnIdle(hPlayer)
            end
            self:SoundEvent(hPlayer, eSE_Idle, aAnimation)
        end
    end,
    ---------------------------------------------------------
    -- StopAnimation
    StopAnimation = function(self, hPlayer, aAnimation)

        self:DeleteCharacterAttachment(hPlayer, aAnimation)
        if (hPlayer.ModifiedCharacterOffset) then

            hPlayer.ModifiedCharacterOffset = nil
            hPlayer.actor:SetParams({
                modelOffset = { x = 0, y = 0, z = 0 }
            })
            local vOffset = hPlayer:GetWorldPos()
            hPlayer:SetSlotWorldTM(0, vOffset, hPlayer:GetDirectionVector())
        end

        if (PREVIOUS_GRAVITY ~= nil and GRAVITY_MODIFIED) then
            --if (CPPAPI) then
            --	CPPAPI.FSetCVar("p_gravity_z", tostring(PREVIOUS_GRAVITY))
            --end
            GRAVITY_MODIFIED = false
            PREVIOUS_GRAVITY = nil
        end

        aAnimation.AnimTime = nil
        self:ResetPlayer(hPlayer)

        ClientLog( "Stopped!!")
    end,
    ---------------------------------------------------------
    -- SpawnCharacterAttachment
    SpawnCharacterAttachment = function(self, hPlayer, aAnimation)

        local aProperties = aAnimation.CharacterAttachment
        if (aAnimation.hCharacterAttachment and System.GetEntity(aAnimation.hCharacterAttachment.id)) then
            return
        end

        local hAttachment = System.SpawnEntity({
            class = "BasicEntity",
            name = "CharacterAnimAttachment_" .. hPlayer:GetName(),
            properties = {
                object_Model = aProperties.Model,
                Physics = {
                    bPhysicalize = 1,
                    bPushableByPlayers = 0,
                    bRigidBody = 1,
                    Density = -1,
                    Mass = -1
                }
            }
        })

        if (not hAttachment) then
            return ClientLog( "Failed to spawn attachment")
        end

        if (aProperties.Bone) then
            --	objects/library/equipment/binoculars/binoculars.cgf
            --	hPlayer:CreateBoneAttachment
        end
        aAnimation.hCharacterAttachment = hAttachment
    end,
    ---------------------------------------------------------
    -- DeleteCharacterAttachment
    DeleteCharacterAttachment = function(self, hPlayer, aAnimation)

        if (aAnimation.hCharacterAttachment) then
            System.RemoveEntity(aAnimation.hCharacterAttachment.id)
            aAnimation.hCharacterAttachment = nil
        end

    end,
    ---------------------------------------------------------
    -- MakeAnimationID
    MakeAnimationID = function(self, hPlayer, sAnimation)
        if (not self.ANIM_COUNTERS[hPlayer.id]) then
            self.ANIM_COUNTERS[hPlayer.id] = 0
        end
        self.ANIM_COUNTERS[hPlayer.id] = self.ANIM_COUNTERS[hPlayer.id] + 1

        return ("ANIM_" .. hPlayer:GetChannel() .. "_" .. (sAnimation or "NULLANIM") .. "_" .. self.ANIM_COUNTERS[hPlayer.id])
    end,
    ---------------------------------------------------------
    -- CanPlayLoopedAnim
    CanPlayLoopedAnim = function(self, hPlayer, aAnimation)
        -------------
        local iStance = hPlayer.actorStats.stance
        local bAnimOk = true

        -------------
        local iAnimStance = aAnimation.RequiredStance or aAnimation.Stance
        if (iAnimStance) then
            if (isArray(iAnimStance)) then
                bAnimOk = (bAnimOk and (iAnimStance[iStance] == true))
            else
                bAnimOk = (bAnimOk and (iStance == -1 or iStance == iAnimStance))
            end
        end

        if (not bAnimOk) then return false, "stance" end

        -------------
        local iAnimSpeed = nil
        local sAnimName = nil
        local iAnimTime = nil
        local iAnimStart = nil
        local fPred = checkVar(aAnimation.Condition, nil)
        if (fPred and isFunction(fPred)) then
            local bOk, sReturn, iSpeed, iTime, iStart = aAnimation.Condition(hPlayer, aAnimation)
            bAnimOk = (bAnimOk and (bOk == true))
            if (sReturn) then
                sAnimName = sReturn
            --    ClientLog( "Condition return animation name %s", sReturn)
            end
            if (iSpeed) then
                iAnimSpeed = iSpeed
             --   ClientLog( "Condition return animation speed %f", iSpeed)
            end
            if (iTime) then
                iAnimTime = iTime
            --    ClientLog( "Condition return animation time %f", iTime)
            end
            if (iStart) then
                iAnimStart = iStart
            --    ClientLog( "Condition return animation length %f", iStart)
            end
        end

        if (not bAnimOk) then return false, "condition" end

        -------------
        local bAlive = checkVar(aAnimation.OnlyAlive, true)
        if (bAlive) then
            bAnimOk = (bAnimOk and ((bAlive == true and hPlayer.actor:GetHealth() > 0 )))
        end

        if (not bAnimOk) then return false, "not alive" end

        -------------
        local bNoSpec = checkVar(aAnimation.NoSpectator, true)
        if (bNoSpec) then
            bAnimOk = (bAnimOk and (hPlayer.actor:GetSpectatorMode() == 0))
        end

        -------------
        if (not bAnimOk) then return false, "is spectating" end

        local bOnGround = checkVar(aAnimation.OnGround, nil)
        if (bOnGround == true or bOnGround == 1) then
            bAnimOk = (bAnimOk and (not hPlayer.actor:IsFlying()))
        end

        if (not bAnimOk) then return false, "not on ground" end

        -------------
        local bInAir = checkVar(aAnimation.InAir, nil)
        if (bInAir == true or bInAir == 1) then
            bAnimOk = (bAnimOk and (hPlayer.actor:IsFlying()))
        end

        if (not bAnimOk) then return false, "not flying" end

        -------------
        local bNoSwimming = checkVar(aAnimation.NoSwimming, nil)
        if (bNoSwimming == true or bNoSwimming == 1) then
            bAnimOk = (bAnimOk and (iStance ~= STANCE_SWIM))
        end

        if (not bAnimOk) then return false, "is swimming" end

        -------------
        local bInWater = checkVar(aAnimation.InWater, nil)
        local vPlayer = hPlayer:GetPos()
        local vWater = CryAction.GetWaterInfo(vPlayer)
        if (bInWater == true or bInWater == 1) then
            bAnimOk = (bAnimOk and (vWater > vPlayer.z))
        elseif (bInWater == false or bInWater == 0) then
            bAnimOk = (bAnimOk and (vWater < vPlayer.z))
        end
        if (not bAnimOk) then return false, "over or under water" end

        -------------
        local iMaxSpeed = checkVar(aAnimation.MaxSpeed, -1)
        if (iMaxSpeed and iMaxSpeed ~= -1) then
            bAnimOk = (bAnimOk and (hPlayer:GetSpeed() <= iMaxSpeed))
        end

        if (not bAnimOk) then return false, "too fast" end

        -------------
        local iMinSpeed = checkVar(aAnimation.MinSpeed, -1)
        if (iMinSpeed and iMinSpeed ~= -1) then
            bAnimOk = (bAnimOk and (hPlayer:GetSpeed() >= iMinSpeed))
        end

        if (not bAnimOk) then return false, "too slow" end

        -------------
        return bAnimOk, sAnimName, iAnimSpeed, iAnimTime, iAnimStart
    end,

}


--=========================================================
-- Search Lasers
ClientMod.AASearchLasers = {

    LaserScale = 15,

    ---------------------------------------------------------
    -- Constructor
    Init = function(self)

        self.RESET = true
        self:EnableAASearchLaser("AutoTurret",   true)
        self:EnableAASearchLaser("AutoTurretAA", true)

    end,
    ---------------------------------------------------------
    -- Enabler
    EnableAASearchLaser = function(self, class, enable)
        for i, v in pairs(System.GetEntitiesByClass(class) or {}) do
            self:SpawnSearchLaser(v, enable)
        end
    end,
    ---------------------------------------------------------
    -- PreUpdater
    PreUpdateAASearchLaser = function(self, class)
        self:PostUpdateAASearchLaser("AutoTurret")
        self:PostUpdateAASearchLaser("AutoTurretAA")
    end,
    ---------------------------------------------------------
    -- PostUpdater
    PostUpdateAASearchLaser = function(self, class)
        -- update
        for i, v in pairs(System.GetEntitiesByClass(class) or {}) do

            if (System.IsPointVisible(v:GetPos())) then
                if (v.item:IsDestroyed()) then
                    if (v.SearchLaser and not v.HadSearchLaser) then
                        self:SpawnSearchLaser(v, false) -- remove from destroyed turrets!
                        v.HadSearchLaser = true
                    end
                else
                    if (v.HadSearchLaser) then
                        self:SpawnSearchLaser(v, true) -- add (!!!)LASER(!!!) back if it already had one!!
                        v.HadSearchLaser = false
                    end
                    if (v.SearchLaser) then
                        if (v.SearchLaser:GetScale() ~= self.LaserScale) then
                            v.SearchLaser:SetScale(self.LaserScale) -- real time updating scale! how cool is that!
                        end
                        v.SearchLaser:SetAngles(v:GetSlotAngles(1)) -- slot angles 1 = gun turret direction
                    end
                end
            end
        end
    end,
    ---------------------------------------------------------
    -- Spawner
    SpawnSearchLaser = function(self, entity, enable)
        if (enable) then
            self:LoadAALaser(entity)
        else
            self:UnloadLaser(entity, entity.SearchLaser)
        end
    end,
    ---------------------------------------------------------
    -- Unloader
    UnloadLaser = function(self, entity, laser)
        if (laser) then
            --Msg(0, "del %s", laser:GetName())
            System.RemoveEntity(laser.id)
            entity.SearchLaser = nil
        end
    end,
    ---------------------------------------------------------
    -- Loader
    LoadAALaser = function(self, entity)

        -- no double spawning (!)LASERS(!)
        if (entity.SearchLaser and System.GetEntity(entity.SearchLaser.id)) then
            if (self.RESET) then
                System.RemoveEntity(entity.SearchLaser.id)
            else
                return
            end
        end

        -- note: this spawns a (!)LASER(!)
        local laser = System.SpawnEntity({
            class = "BasicEntity", -- maybe not the best entity for this?
            name = entity:GetName() .. "_searchlaser", -- prolly not unique, but who cares
            properties = {
                object_Model = "objects/effects/beam_laser_02.cgf", -- better than the other one
            },
            fMass = -1, -- no mass
        })
        laser:SetScale(self.LaserScale) -- scale (!)LASER(!) before attaching!
        entity.SearchLaser = laser
        entity:AttachChild(laser.id, 8)
        laser:SetLocalPos({ x = 0, y = 0, z = 1.8 }) -- set (!)LASER(!) position after attaching!
    end
};


--=========================================================
-- wa wa wa wa
ClientMod.Counter = function(self)
    return self.COUNTER + 1
end









-- from CHRIS
function GetVersion()
    local version = CRYMP_CLIENT or 0
    if (CRYMP_CLIENT_STRING and #CRYMP_CLIENT_STRING > 3) then
        version = version + 1
        local custom = "dirty"
        if (string.sub(CRYMP_CLIENT_STRING, #CRYMP_CLIENT_STRING-#custom + 1, #CRYMP_CLIENT_STRING) == custom) then
            version = version + 1
        end
    end
    return version
end


--=========================================================
-- Init
local bOk, sError = pcall(ClientMod.Init, ClientMod)
if (not bOk) then

    ClientLog("Client Failed to Install\n%s", tostring(sError))

    ClientMod:ToServer(0, 10)
    ClientMod:ToServer(1, "!clerr INSTALL {" .. tostring(sError) .. "}")
else
    ClientMod:ToServer(0, 11)
end