---------------------------------------------------------
-- CLIENT UNDER CONSTRUCTION.
--
-- COPYRIGHT (D) MARISAAAAAAUH 2006-2069
--
-- todo:
-- add back pushing boats from atomcl!
---------------------------------------------------------

if (not g_localActor) then return end

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
    chan    = g_localActor.actor:GetChannel(),

    -- ======================
    COLORS = {
        red     = {0.91, 0.1, 0.1},
        green   = {0, 1, 0},
        blue    = {0.041, 0.6, 0.9},
        grey    = {0.4, 0.4, 0.4},
        orange  = {1, 0.647, 0},
        yellow  = {0.587, 0.79, 0.21},
        pink    = {1, 0.75, 0.8},
        purple  = {0.5, 0, 0.5},
        cyan    = {0, 1, 1},
        magenta = {1, 0, 1},
        brown   = {0.6, 0.3, 0.1},
        teal    = {0, 0.5, 0.5},
        maroon  = {0.5, 0, 0},
        olive   = {0.5, 0.5, 0},
        lavender= {0.8, 0.6, 0.8},
    },

    -- ======================
    _G                  = {},
    VM                  = {},
    WANT_VM             = {},
    LS                  = {},
    LA                  = {},
    FA                  = {},
    NSS                 = {},
    PREVIOUS_INV        = {},
    CHAT_EFFECTS        = {},
    MATERIAL_CACHE      = {},
    DEBUG               = ClientModX.DEBUG,
    COUNTER             = ClientModX.COUNTER or 0,
    NO_CLIP             = ClientModX.NO_CLIP or 0,
    DRAW_TOOLS          = ClientModX.DRAW_TOOLS or {},
    EXPLOSION_EFFECTS   = {},
    FORCED_CVARS        = {
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
    if (isNumber(hId)) then return GP(hId) end
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
MODEL_NOMAD_BOOBS = "CryMP-Objects/characters/woman/nanosuit_female/Nanosuit_Female.cdf"
if (not PAK_LOADED) then
    -- :(
    MODEL_NOMAD_BOOBS = "objects/characters/human/story/Dr_Rosenthal/Dr_Rosenthal.cdf"
end

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
    VM_TESLA,    VM_AUDI,     VM_DUELER,  VM_FERRARI,  VM_TRAIN,
    VM_AIRCRAFT, VM_NKPLANE,  VM_USPLANE, VM_CARGOPLANE, VM_TRANSPLANE,
    VM_PLANE1,   VM_VTOLTRANS, VM_EXCAVATOR, VM_FORKLIFT, VM_MINETRUCK,
    VM_CRANE,    VM_WAGON,    VM_BAGGAGECART, VM_SHOPPINGCART, VM_AAA,
    VM_APC,      VM_HELI,     VM_TANK,    VM_TANKHEADLESS, VM_TANKTURRET,
    VM_TRUCK,    VM_CAR,      VM_LTV,     VM_DAUNTLESS, VM_KUANTI,
    VM_SPEEDBOAT, VM_DESTROYER, VM_HOVER, VM_SCIENCESHIP, VM_CARGOSHIP,
    VM_SKYFORGE, VM_NAVYSHIP, VM_TANKER,  VM_SHARK,    VM_PALM,
    VM_ROCK =
    1, 2, 3, 4, 5,
    6, 7, 8, 9, 10,
    11, 12, 13, 14, 15,
    16, 17, 18, 19, 20,
    21, 22, 23, 24, 25,
    26, 27, 28, 29, 30,
    31, 32, 33, 34, 35,
    36, 37, 38, 39, 40,
    41

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

    eCR_MeleeRelease, eCR_Melee = 60, 61

    eCR_JetpackOn = 66
    eCR_JetpackOff = 67

    eCR_ChairEffectsOn = 68
    eCR_ChairEffectsOff = 69
    eCR_ChairRemove = 70

    -------
    self:FixClWork()
    self:PatchGameRules() if (IS_PS) then self.PatchBL(g_gameRules) end
    self:PatchLocalActor()
    self:PatchGUI()
    self:PatchDoor()
    self:PatchVB()

    -------
    self.AASearchLasers:Init()
    self.AnimationHandler:Init()

    -------
    self:ToServer(eTS_Spectator, (PAK_LOADED and eCR_PakOk or eCR_NoPak))

    -- =====================
    ClientEvent = self.Event

    -- =====================
    eEvent_BLE = 0


    LAYER_CLOAK = GetCVar("crymp_cloaklayer")



    g_Client = self
    return true
end

--=========================================================
-- Events
ClientMod.Delete = function(self)

    ClientLog("Client Deleted..")
    g_aHooks = nil

    self._G                  = nil
    self.VM                  = nil
    self.WANT_VM             = nil
    self.LS                  = nil
    self.LA                  = nil
    self.FA                  = nil
    self.NSS                 = nil
    self.PREVIOUS_INV        = nil
    self.CHAT_EFFECTS        = nil
    self.MATERIAL_CACHE      = nil
    self.DEBUG               = nil
    self.COUNTER             = nil
    self.NO_CLIP             = nil
    self.DRAW_TOOLS          = nil
    self.EXPLOSION_EFFECTS   = nil
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

    AddCVar("crymp_explosionWeedLifetime", "lalala", 120)
    AddCVar("crymp_idleanimslot", "lalala", 0)
    AddCVar("crymp_weapon_cockingalways", "lalala", 0)
    AddCVar("crymp_cloaklayer", "lalala", 4)
    AddCVar("crymp_fp_anim_allowall", "lalala", 0)

    -- Commands
    AddCommand("crymp_loadlocal", "Load local client sources.", [[loadfile("crymp-server\\clientmod\\crymp-client.lua")()]])
    AddCommand("crymp_loadlocalPAK", "Load local client sources.", [[loadfile("crymp-server\\clientmod\\crymp-client\\crymp-client.lua")()]])

    AddCommand("cmp_t_th","","g_Client:AddHelmet(g_Client.channel, true, 'objects/characters/human/us/officer/captains_hat.chr',{-1.58,0.13,0,})")
    AddCommand("cmp_p","","loadstring(%%)()")
    AddCommand("cmp_ssi","","g_Client:ShowServerInfo(false)")
    AddCommand("cmp_hsi","","g_Client:ShowServerInfo(true)")
    AddCommand("cmp_jp","","g_Client:Jetpack(g_Client.chan,not g_Client.ent.JETPACK.HAS)")
    AddCommand("cmp_slh","","g_Client:SLH(g_localActor,'green',5)")
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
ClientMod.ExplosionEffect = function(self, pos, norm,count, radius, time_left)

    -- ??
    -- objects/natural/rocks/explosion_crater/explosion_crater_a.cgf

    count = count or 6
    radius = radius or 4

    for _,info in pairs(self.EXPLOSION_EFFECTS) do
        if (vector.distance(info.Pos,pos)<10)then
            return DebugLog("not spawning gawkers at %s",Vec2Str(pos))
        end
    end
    
    local n = table.insert(self.EXPLOSION_EFFECTS, { Ents = {}, Pos = pos, Timer = timerinit() - (time_left or 0) })
    n=self.EXPLOSION_EFFECTS[table.count(self.EXPLOSION_EFFECTS)]
    n.Main = System.SpawnEntity({class="BasicEntity",position=pos})

    local s = "smoke_and_fire.black_smoke.harbor_smokestack1"
    local pos_2 = new(pos) pos_2.y = pos_2.y - 2 pos_2.z = pos_2.z + 2.5
    local pos_3 = new(pos) pos_3.y = pos_2.y - 4 pos_3.z = pos_3.z + 5
    self:LoadEffectOnEntity(n.Main, "smoke0", {Effect = s,CountScale=1,Scale=1}, true)
    self:LoadEffectOnEntity(n.Main, "smoke1", {Effect = s,CountScale=1,Scale=1,Pos=pos_2}, true)
    self:LoadEffectOnEntity(n.Main, "smoke2", {Effect = s,CountScale=1,Scale=1,Pos=pos_3}, true)

    Particle.CreateMatDecal(pos, g_Vectors.up, 3, 30, "Materials/decals/dirty_rust/decal_explo_bright", math.random()*360)
    Particle.CreateMatDecal(pos, g_Vectors.up, math.frandom(2.5, 3.5), 30, "Materials/Decals/Dirty_rust/decal_explo_2", math.random()*360)
    Particle.CreateMatDecal(pos, g_Vectors.up, math.frandom(2.5, 3.5), 30, "Materials/Decals/Dirty_rust/decal_explo_3", math.random()*360)
    Particle.CreateMatDecal(pos, g_Vectors.up, math.frandom(2.5, 3.5), 30, "Materials/Decals/burnt/decal_burned_22", math.random()*360)

    local m = {
        "Objects/Natural/Rocks/Precipice/street_broken_harbour_big_a.cgf",
        "objects/natural/rocks/precipice/street_broken_harbour_big_b.cgf"
    }

    pos.z = pos.z - 0.15
    for _,info in pairs(vector.gawker(pos,count,radius)) do
        VecRotate90_Z(info.dir)
        local crack = System.SpawnEntity({
            name = "crack-" .. self:Counter(),
            class = "BasicEntity",
            position = info.pos,
            orientation = info.dir,
            properties = {
                object_Model = getrandom(m),
                Physics = { bPhysicalize = 1, bPushableByPlayers = 0, bRigidBody = 1, Density = -1, Mass = -1 }
            },
        })
        crack:SetScale(math.frandom(0.8,1))
        table.insert(n.Ents, crack)
    end

    if (self.DEBUG) then
        System.DeformTerrain(pos, radius,"") -- !!! IRREVERSIBLE !!!
    end
end

--=========================================================
-- Events
ClientMod.OnAction = function(self, hPlayer, sKey, sMode, iValue)

    if (self.DEBUG) then
        ClientLog("-> %s (%s) %d",sKey,sMode,iValue)
    end

    local send

    local c = hPlayer.inventory:GetCurrentItem()
    local f = hPlayer.inventory:GetItemByClass("Fists") f = f and GetEntity(f)

    -- ============
    -- Chat
    if (sKey == "hud_openchat" or sKey == "hud_openteamchat") then
        self:ChatEffect(self.channel,1)
        send = eCR_OpenChat

    elseif (sKey == "enter" or sKey == "escape")  then
        self:ChatEffect(self.channel,0)
        send = eCR_CloseChat

    elseif (sKey == "special") then

        local aInfo = c and ({
            ["AVMine"] = { "melee_01" },
            ["RepairKit"] = { "melee_01" },
            ["Claymore"] = { "melee_01", 1 },
        })[c.class]
        if (aInfo) then
            if (aInfo[2]) then
                if (f) then
                    f.item:PlayAction(aInfo[1],1,1)
                end
            else
                c:StartAnimation(0, aInfo[1], 8)
            end
        end
        send = iValue == 0 and eCR_MeleeRelease or eCR_Melee

    elseif (sKey == "use") then
        if (self.ent.JETPACK.HAS) then
            send = self:JetPack_Toggle(sMode=="press")
        end
        if (self.ent.FLYING_CHAIR.HAS) then
            self:FlyingChair_Toggle(sMode=="press", sMode)
        end

    end



    -- ============
    -- etc etc etc

    -- ============
    if (send) then
        if (timerexpired(self.NSS[send],0.4)) then
            self:ToServer(0,send)self.NSS[send]=timerinit()
        end
    end
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
ClientMod.OnKill = function(self, hPlayer, hShooterID, bMelee, headshot, tpe)

    local shooter = System.GetEntity(hShooterID)


    local falling = hPlayer.actor:IsFlying()
    local fm = falling and 4 or 9
    local iCM = (hPlayer.CM and hPlayer.CM.ID or CM_NONE)
    local sDeathSound = "ai_marine_"..math.random(1,3).."/"..(bMelee and ("meleedeath_0" ) or falling and ("fallingdeath_0") or ("death_0")) ..math.random(0,fm)
    if (iCM == CM_KYONG) then sDeathSound = "ai_kyong/" .. (bMelee and ("meleedeath_0" ) or falling and ("fallingdeath_0") or ("death_0")) .. math.random(0,fm) end
    if (iCM == CM_KOREANAI) then sDeathSound = "ai_korean_ai_" .. math.random(1,3) .. "/" .. (bMelee and ("meleedeath_0" ) or falling and ("fallingdeath_0") or ("death_0")) .. math.random(0,fm) end

    DebugLog("snd=",sDeathSound)
    if (sDeathSound) then
        self:PSE(sDeathSound, hPlayer, "death")
    end
end

--=========================================================
-- Events
ClientMod.VehicleHit = function(self, v, hit)

    local id = v.CMID
    local dmg = v.vehicle:GetRepairableDamage()
    DebugLog(dmg)
    if (id) then
        if (id == VM_USPLANE or id == VM_NKPLANE or id == VM_CARGOPLANE or id == VM_AIRCRAFT) then
            DebugLog("jet hit")
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

    hTarget.LAST_HIT = aHitInfo

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
        if(aHitInfo.damage > 10 and not bMelee) then

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
ClientMod.AddLA = function(self, ent, anim, enable)

    local e = GetEntity(ent)
    if (not e) then
        return DebugLog("bad id %s",g_ts(ent))
    end

    if (enable) then
        self.FA[e.id] = {
            ANIM = anim,
            ENTITY = e
        }
        DebugLog("new loopy poopy anim %s", anim)
    else
        self.FA[e.id] = nil
        e:StopAnimation(0,10)
    end
end

--=========================================================
-- Events
ClientMod.UpdateJets = function(self)

    --local v = self.ent:GetVehicle()
    --if (v and v:GetDriverId() == self.id) then
    --    self:Update_Jet()
    --elseif (self.JET.PGB) then
    --    HUD.SetProgressBar("",false)
   --     self.JET_PGB = nil
    --end
end

--=========================================================
-- Events
ClientMod.Update = function(self,ft)

    ft = ft or System.GetFrameTime()

    -- check the peasants (maybe hook cppapi spawn)
    local aPlayers = System.GetEntitiesByClass("Player")
    for _, hPlayer in pairs(aPlayers) do

      --  hPlayer.LAST_SPEED = hPlayer:GetSpeed()
        hPlayer.LAST_VELOCITY = hPlayer:GetVelocity()
       -- hPlayer.SPEED = (hPlayer.LAST_POS and vector.distance(hPlayer:GetPos(), hPlayer.LAST_POS) or 0)

        if (not hPlayer.Initialized or RELOAD) then
            hPlayer:ClInit()
        end

        --hPlayer.LAST_POS = hPlayer:GetPos()

        --hmm, sometimes animation FREEZES. fis it PLEASE!
        if (hPlayer.IDLE.PLAYING) then
            if (hPlayer.actorStats.stance ~= hPlayer.IDLE.STANCE or DistanceVectors(hPlayer.IDLE.POS,hPlayer:GetPos()) > 0) then
                self:IDLE(hPlayer.actor:GetChannel(), "stop")
            elseif (timerexpired(hPlayer.IDLE.TIMER, hPlayer.IDLE.TIME-System.GetFrameTime())) then
                if (hPlayer.IDLE.QUEUED) then
                    self:IDLE(hPlayer:GetChannel(), hPlayer.IDLE.QUEUED)
                    hPlayer.IDLE.QUEUED = nil
                    DebugLog("playing queued item %s.......","d")
                elseif (hPlayer.IDLE.LOOP) then

                    hPlayer.IDLE.TIME = 0
                    hPlayer.IDLE.TIMER = nil
                    self:IDLE(hPlayer:GetChannel(), hPlayer.IDLE.ANIM, nil, true)
                    DebugLog("loopy poopy")
                end
            end
        end

        if (hPlayer.JETPACK.HAS) then
            if (hPlayer:GetSuitMode(NANOMODE_CLOAK)) then
                if (not hPlayer.JETPACK.CLOAKED) then
                    for _,id in pairs(hPlayer.JETPACK.PTRS) do
                        local p = GetEntity(id)
                        if (p) then p:EnableMaterialLayer(true,LAYER_CLOAK) end
                    end
                end
                hPlayer.JETPACK.CLOAKED = true
            elseif (hPlayer.JETPACK.CLOAKED) then
                for _,id in pairs(hPlayer.JETPACK.PTRS) do
                    local p = GetEntity(id)
                    if (p) then p:EnableMaterialLayer(false,LAYER_CLOAK) end
                end
                hPlayer.JETPACK.CLOAKED = false
            end
        end

        local chair = GetEntity(hPlayer.FLYING_CHAIR.ENTITYID)
        if (chair) then
            if (not hPlayer:GetVehicle() and hPlayer:IsAlive() and not hPlayer:IsSpectating()) then
                local p = hPlayer:GetBonePos("Bip01 Pelvis") p.z = p.z - 0.5
                chair:SetWorldPos(p)
                local d = hPlayer:GetBoneDir("Bip01 Pelvis")
                d.z = 0
                NormalizeVector(d)
                DebugLog(Vec2Str(d))
                chair:SetDirectionVector(d,g_Vectors.up)--hPlayer:GetDirectionVector())
                if (hPlayer.id == self.id) then
                    self:Update_Chair(ft)
                end
                hPlayer:StartAnimation(0,"relaxed_sit_nw_01",9)
            else
                if (hPlayer.id == self.id) then self:TS(0,eCR_ChairRemove) end
                hPlayer:StopAnimation(0,9)
                self:FlyingChar_Effects(hPlayer:GetChannel(),false)
                hPlayer.FLYING_CHAIR = {}
            end
        end
     --   DebugLog(hPlayer:GetAnimationLength(0,"relaxed_sit_nw_01"))
    end

    RELOAD = false

    --------------------------------
    --- Needs to be called on frame
    self:UpdateHitMarkers()
    self:UpdateChatEffects()
    self:UpdateJets()

    self:UpdateFlying(ft)

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
    -- test!
    --[[
    self.sprintfps=self.sprintfps or 0
    local f=self.ent:GetItemByClass("Fists")
    if (false and timerexpired(self.sprintfp,self.sprintfpt) and self.ent:GetSpeed()>3) then
        if (self.sprintfps>=2) then
            self.sprintfps=0
        end
        self.sprintfps = self.sprintfps+1
        local a
        if (self.sprintfps==1) then
            DebugLog("a1")
            a="run_forward_nw_01"
        elseif (self.sprintfps==2) then
            DebugLog("a2")
            a="run_forward_nw_01"
        else
            -- more STEPS!
        end

        if (a) then
            self.sprintfp=timerinit()
            local speed = self.ent:GetSuitMode(NANOMODE_SPEED) and 1.2 or 1
            f:StartAnimation(0,a,9,0.15,speed,1)
            self.sprintfpt=((f:GetAnimationLength(0,a) or 0)-System.GetFrameTime()*2)*speed

        end
    end
]]
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
    --- Limit Update Rate
    if (timerexpired(self.QuarterTick, 0.25)) then
        self:TIMER_QUARTER()
        self.QuarterTick = timerinit()
    end

    for x, y in pairs(self.LS) do
        if (not Sound.IsPlaying(y.ID)) then
            -- todo...
        end
    end

    for x, y in pairs(self.FA) do
        if (not GetEntity(x)) then
            self.FA[x] = nil
        else
            if (timerexpired(y.START,y.TIME)) then

                y.ENTITY:StartAnimation(0,y.ANIM or"misc_replaceMe_01",10,1,1,1,1) -- 6th is loop BTW
                y.START = timerinit()
                y.TIME = y.ENTITY:GetAnimationLength(0,y.ANIM or "misc_replaceMe_01")
            end
        end
    end

    --------------------------------
    --- UPDATE !!
    self.AASearchLasers:PreUpdateAASearchLaser(ft)
    self.AnimationHandler:Update(ft)

end

--=========================================================
-- Events
ClientMod.UpdateFlying = function(self,ft)
    if (self.ent.JETPACK.HAS) then
        self:Update_JETPACK(ft)
    elseif (self.ent.FLYING_CHAIR) then

    end
end

--=========================================================
-- Events
ClientMod.CHAIR = function(self, chan, chair, enable)

    local p = GP(chan)
    if (not p) then return end
    local c = GetEntity(chair) if (not c) then
        if (enable) then self.WANT_CHAIR[chan] = { chan,chair,enable } end
        return
    end

    local cc = GetEntity(p.FLYING_CHAIR.ENTITYID)
    if (cc and cc.id ~= c.id) then

        -- this is bad!
        DebugLog("something BAD happened!!")

        c:Physicalize(0, PE_RIGID, { mass = 300 })
        c:EnablePhysics(true)
    end

    p.FLYING_CHAIR.THRUSTERS = nil
    p.FLYING_CHAIR.HAS = nil
    p.FLYING_CHAIR.ENTITYID = nil

    if (enable) then

        if (p.id == self.id) then
        end

        p.FLYING_CHAIR.THRUSTERS = nil
        p.FLYING_CHAIR.HAS = true
        p.FLYING_CHAIR.ENTITYID = c.id

        c:EnablePhysics(false)
        c:DestroyPhysics()
        c.Properties.bUsable = (p.id == self.id)

        DebugLog("now has chair!!")
    else

        c:Physicalize(0, PE_RIGID, { mass = 300 })
        c:EnablePhysics(true)

        MakeUsable(c)
        c.Properties.UseText = "Sit"
        c.Properties.bUsable = 1
    end
end

--=========================================================
-- Events
ClientMod.Update_Chair = function(self, ft)
    local c = self.ent.FLYING_CHAIR
    local gl = self.ent

    if (not c.THRUSTERS) then
        return
    elseif (gl:IsDead() or gl:IsSpectating() or gl:GetVehicle() or not gl.actor:IsFlying()) then
        c.THRUSTERS = false
        self:TS(0, eCR_ChairEffectsOff)
        return
    end

    c.THROTTLE = (c.THROTTLE or 1) + 1

    local i1 = math.min(30, c.THROTTLE)
    local i2 = math.min(20, c.THROTTLE)

    local la = g_localActor
    la:AddImpulse( -1, la:GetCenterOfMassPos(), g_Vectors.up, ft * i1 * 40, 1)
    la:AddImpulse( -1, la:GetCenterOfMassPos(), System.GetViewCameraDir(), ft * i2 * 40 * 1, 1)
end

--=========================================================
-- Events
ClientMod.Update_JETPACK = function(self, ft)

    local jp = self.ent.JETPACK
    local gl = self.ent

    if (not jp.THRUSTERS) then
        return
    elseif (gl:IsDead() or gl:IsSpectating() or gl:GetVehicle() or not gl.actor:IsFlying()) then
        jp.THRUSTERS = false
        self:TS(0, eCR_JetpackOff)
        return
    end

    jp.THROTTLE = (jp.THROTTLE or 1) + 1

    local i1 = math.min(30, jp.THROTTLE)
    local i2 = math.min(20, jp.THROTTLE)

    local la = g_localActor

    local ff = (la.actorStats.inFreeFall == 1)
    local p = (la.actorStats.stance == STANCE_PRONE)

    if (not ff and not p) then

        -- normal air control
        la:AddImpulse( -1, la:GetCenterOfMassPos(), g_Vectors.up, ft * i1 * 40, 1)
        if (jp.SUPER_SPEED) then
            jp.SUPER_SPEED = false -- to server? more e-e-ffects?
        --    DebugLog("ss off")
        end
    else
        if (not jp.SUPER_SPEED) then
            jp.SUPER_SPEED = true
        --    DebugLog("ss on")
        end

    end

    la:AddImpulse( -1, la:GetCenterOfMassPos(), System.GetViewCameraDir(), ft * i2 * 40 * ((ff or p) and 3 or 1), 1)
end

--=========================================================
-- Events
ClientMod.JetPack_Toggle = function(self, enable)
    local send
    if (enable and g_localActor.actor:IsFlying()) then
        send = eCR_JetpackOn
        self.ent.JETPACK.THRUSTERS = true
        self:Jetpack_Effects(self.chan,true) -- effects should be instant on client

        DebugLog("now ON!")

    elseif (self.ent.JETPACK.THRUSTERS) then
        self.ent.JETPACK.THRUSTERS = false
        send = eCR_JetpackOff
        self:Jetpack_Effects(self.chan,false) -- effects should be instant on client

        DebugLog("Now OFF!")
    end
    return send
end

--=========================================================
-- Events
ClientMod.FlyingChair_Toggle = function(self, enable, sMode)
    local send
    if (enable and g_localActor.actor:IsFlying()) then
        send = eCR_ChairEffectsOn
        self.ent.FLYING_CHAIR.THRUSTERS = true
        self:FlyingChar_Effects(self.chan,true) -- effects should be instant on client

        DebugLog("now ON!")

    elseif (self.ent.FLYING_CHAIR.THRUSTERS) then
        self.ent.FLYING_CHAIR.THRUSTERS = false
        send = eCR_ChairEffectsOff
        self:FlyingChar_Effects(self.chan,false) -- effects should be instant on client

        DebugLog("Now OFF!")
    elseif (not g_localActor.actor:IsFlying() and sMode ~= "release") then
        send = eCR_ChairRemove
    end

    DebugLog("el modo es %s",sMode)
    if (send) then self:TS(0,send) end
end

--=========================================================
-- Events
ClientMod.FlyingChar_Effects = function(self, chan, enable)

    local p = GP(chan) if (not p) then return end
    local c = GetEntity(p.FLYING_CHAIR.ENTITYID) if (not c) then return end

    self:LoadEffectOnEntity(c, "f0", { Effect = "misc.signal_flare.on_ground_purple", Dir = g_Vectors.down, Pos = c:GetPos(), Scale = 1 }, enable)
    self:LoadEffectOnEntity(c, "f1", { Effect = "misc.signal_flare.on_ground_green",  Dir = g_Vectors.down, Pos = c:GetPos(), Scale = 2 }, enable)
    self:LoadEffectOnEntity(c, "f2", { Effect = "misc.signal_flare.on_ground",        Dir = g_Vectors.down, Pos = c:GetPos(), Scale = 2 }, enable)
end

--=========================================================
-- Events
ClientMod.Jetpack_Effects = function(self, chan, enable)

    local p = GP(chan)
    if (not p) then
        return
    end
    local jp = p.JETPACK
    if (not jp.HAS) then
        return DebugLog("dont have!")
    end

    local e0 = jp.EXHAUST0
    local e1 = jp.EXHAUST1

    local rnd = {
        [1] = "misc.signal_flare.on_ground_green",
        [2] = "misc.signal_flare.on_ground",
        [3] = "misc.signal_flare.on_ground_purple"
    }

   -- self:LoadEffectOnEntity() --"smoke_and_fire.pipe_steam_a.steam"
   -- self:LoadEffectOnEntity() --"smoke_and_fire.pipe_steam_a.steam"

    self:LoadEffectOnEntity(e0, "jpt0", { Effect = "smoke_and_fire.pipe_steam_a.steam" }, enable)
    self:LoadEffectOnEntity(e1, "jpt0", { Effect = "smoke_and_fire.pipe_steam_a.steam" }, enable)

    self:LoadEffectOnEntity(e0, "jpt1", { Effect = getrandom(rnd) }, enable)
    self:LoadEffectOnEntity(e1, "jpt1", { Effect = getrandom(rnd) }, enable)

    -- Sowwy chris
    if (enable) then
        if (p.id == self.id) then
            self:PSE("sounds/interface:suit:thrusters_use",nil,"thrusters_use")
        end
        self:PSE("sounds/interface:suit:thrusters_use",jp.MAIN,"thrusters", nil, true)
    else
        self:StopSound(jp.MAIN,"thrusters")
    end

    jp.EFFECTS = true
end

--=========================================================
-- Events
ClientMod.Jetpack = function(self, chan, enable)

    local p = GP(chan)
    if (not p) then
        -- self:SCHEDULE()--todo fixme
        return
    end

    if (p.JETPACK.HAS and enable) then
        DebugLog("has.. one..")
        return
    end

    if (not p.JETPACK.HAS and not enable) then
        DebugLog("has nOT!")
        return
    end

    if (not enable) then
        p.JETPACK.HAS = false
        p.JETPACK.VISIBLE = false
        for _,e in pairs(
                p.JETPACK.PTRS) do
            System.RemoveEntity(e)
        end
        p.JETPACK.PARTS = {}
        p.JETPACK.PTRS = {}
        return
    end

    p.JETPACK.VISIBLE = true
    p.JETPACK.HAS = true
    p.JETPACK.PARTS = {}
    p.JETPACK.PTRS = {}

    local v0 = p:GetPos() v0.z=v0.z+0.5                  -- dp1
    local v1 = p:GetPos() v1.x=v1.x+0.1 v1.z=v1.z+0.2    -- dp

    local s = System.SpawnEntity
    local spawn_class = "BasicEntity"

    local main = s({ class = spawn_class, position = v0, orientation = { x = 0.5, y = 0, z = -1}, name = "JetPackPart_" .. chan .. "_0"})
    local exhaust0 = s({ class = spawn_class, position = { x = v1.x - 0.15, y = v1.y, z = v1.z - 0.2 }, orientation = g_Vectors.down, name = "JetPackExhause_"..chan.."_0" })
    local exhaust1 = s({ class = spawn_class, position = { x = v1.x + 0.15, y = v1.y, z = v1.z - 0.2 }, orientation = g_Vectors.down, name = "JetPackExhause_"..chan.."_1"  })
    local info = {
        { Scale = 0.2, Pos = { x = v1.x, y = v1.y, z = v1.z + 0.01 }, Dir = { x = 0, y = 1, z = 0 }, File = "objects/library/installations/electric/electrical_cabinets/electrical_cabinet1.cgf" },
        { Pos = { x = v1.x - 0.15, y = v1.y, z = v1.z }, Dir = { x = 0, y = 0, z = -1 }, File = "objects/library/props/gasstation/funnel.cgf" },
        { Pos = { x = v1.x + 0.15, y = v1.y, z = v1.z }, Dir = { x = 0, y = 0, z = -1 }, File = "objects/library/props/gasstation/funnel.cgf" },
        { Pos = { x = v1.x - 0.15, y = v1.y, z = v1.z }, Dir = { x = 1, y = 0, z = 0 }, File = "objects/library/props/gasstation/can_a.cgf", Scale = 3 },
        { Pos = { x = v1.x + 0.15, y = v1.y, z = v1.z }, Dir = { x = 1, y = 0, z = 0 }, File = "objects/library/props/gasstation/can_a.cgf", Scale = 3 },
        { Pos = { x = v1.x - 0.15, y = v1.y, z = v1.z - 0.03 }, Dir = { x = 1, y = 0, z = 0 }, File = "objects/library/props/gasstation/tire_rim.cgf", Scale = 0.25 },
        { Pos = { x = v1.x + 0.15, y = v1.y, z = v1.z - 0.03 }, Dir = { x = 1, y = 0, z = 0 }, File = "objects/library/props/gasstation/tire_rim.cgf", Scale = 0.25 },
        { Pos = { x = v1.x - 0.15, y = v1.y, z = v1.z + 0.1 }, Dir = { x = 0, y = 0, z = 0 }, File = "objects/library/props/household/windchimes/windchime1/tube06.cgf" },
        { Pos = { x = v1.x + 0.15, y = v1.y, z = v1.z + 0.1 }, Dir = { x = 0, y = 0, z = 0 }, File = "objects/library/props/household/windchimes/windchime1/tube06.cgf" },
        { Pos = { x = v1.x - 0.15, y = v1.y, z = v1.z }, Dir = { x = 0, y = 1, z = 1 }, File = "objects/library/props/household/windchimes/windchime1/tube06.cgf" },
        { Pos = { x = v1.x + 0.15, y = v1.y, z = v1.z }, Dir = { x = 0, y = 1, z = 1 }, File = "objects/library/props/household/windchimes/windchime1/tube06.cgf" },
        { Pos = { x = v1.x, y = v1.y, z = v1.z + 0.2 }, Dir = { x = 0.001, y = 0, z = 1 }, File = "objects/library/props/building material/wodden_support_beam_plank_2_b.cgf", Scale = 0.2 },
        { Pos = { x = v1.x, y = v1.y, z = v1.z + 0.1 }, Dir = { x = 0.001, y = 0, z = 1 }, File = "objects/library/props/building material/wodden_support_beam_plank_2_b.cgf", Scale = 0.2 },
        { Pos = { x = v1.x - 0.075, y = v1.y, z = v1.z }, Dir = { x = 0, y = 0, z = 0 }, File = "objects/library/installations/electric/power_pole/power_pole_wood_700_b.cgf", Scale = 0.3 },
        { Pos = { x = v1.x + 0.15, y = v1.y, z = v1.z }, Dir = { x = 0, y = 0, z = 0 }, File = "objects/library/props/flags/northkorean_flagpole_b.cgf", Scale = 0.1 }
    }

    local n
    for _, a in pairs(info) do
        n = s({
            class = spawn_class,
            properties = { object_Model = a.File },
            position = a.Pos,
            orientation = a.Dir,
            name = string.format("JetPackPart_%d_%d", chan, _)
        })
        n:SetScale(a.Scale or 1)
        n:EnablePhysics(false)
        n:DestroyPhysics()
        main:AttachChild(n.id,-1)
        table.insert(p.JETPACK.PTRS, n.id)
    end

    p.JETPACK.MAIN = main

    p.JETPACK.EXHAUST0 = exhaust0
    p.JETPACK.EXHAUST1 = exhaust1

    main:AttachChild(exhaust0.id,-1)
    main:AttachChild(exhaust1.id,-1)

    table.insert(p.JETPACK.PTRS, main.id)
    table.insert(p.JETPACK.PTRS, exhaust0.id)
    table.insert(p.JETPACK.PTRS, exhaust0.id)
    p:CreateBoneAttachment(0, "weaponPos_rifle01","JetPack")
    p:SetAttachmentObject(0, "JetPack", main.id, -1, 0)


end

--=========================================================
-- Events
ClientMod.GetVehicles = function(self)
    local v={}
    for i,h in pairs(System.GetEntities()) do
        if (h.vehicle) then table.insert(v,h) end
    end
    return v
end

--=========================================================
-- Events
ClientMod.TIMER_QUARTER = function(self)

    --[[
    local aVehicles = CPPAPI.GetVehicles and CPPAPI.GetVehicles() or self:GetVehicles()
    local vVehicle, iWaterInfo
    for _, hVehicle in pairs(aVehicles) do
        vVehicle = hVehicle:GetPos()
        iWaterInfo = CryAction.GetWaterInfo(vVehicle)
        if (iWaterInfo and vVehicle.z < iWaterInfo) then
            if (not hVehicle.WaterSplash) then
                vVehicle.z = iWaterInfo
                --Particle.SpawnEffect( "vehicle_fx.tanks_surface_fx.water_splashes",vVehicle,g_Vectors.up )
                DebugLog("immersion!!!")
            end
        elseif (hVehicle.WaterSplash) then
            hVehicle.WaterSplash = nil
        end
    end]]

end

--=========================================================
-- Events
ClientMod.TIMER_SECOND = function(self)

    local vPos = self.ent:GetPos()
    local mcX, mcY = HUD.GetMapGridCoord(vPos.x, vPos.y)
    if ((mcX..mcY) ~= self.LAST_MC) then
        self:TS(0,100+mcX)
        self:TS(0,110+mcY)
        DebugLog("%d=%d, %d=%d", mcX,100+mcX,mcY,110+mcY)
        self.LAST_MC = mcX..mcY
    end

    if (self.REMOTE_SECOND) then self:REMOTE_SECOND() end
    self:UpdateVoteMenu()

    local iClipping = self.NO_CLIP
    if (iClipping and iClipping > 0) then
        if (self.ent:IsAlive()) then
            self.ent:SetColliderMode(iClipping)
        end
    elseif (iClipping == 0) then
        self.ent:SetColliderMode(0)
        self.NO_CLIP = nil
    end

    local G = System.GetCVar
    local _ = 0
    for sVar, sForced in pairs(self.FORCED_CVARS) do
        _ = _ + 1
        if (g_ts(G(sVar)) ~= g_ts(sForced)) then
            System.SetCVar(sVar, g_ts(sForced))
            self:ToServer(0,eCR_ModifiedCVar+_)
        end
    end

    for x, y in pairs(self.VM) do
        local ent = System.GetEntity(x)
        if (ent == nil) then
            self.VM[x] = nil
        elseif (System.GetEntity(y.EntityID) == nil) then
            System.RemoveEntity(x)
            self.VM[x] = nil
        else

          --  DebugLog(y.ID)
            if (y.ID == VM_CRANE) then
                self:Update_V_ANIM(ent.CM,{FWD= { "crane_wheelforward" },BACK= { "crane_wheelbackward" }})
            end

            ent.LAST_POS = ent:GetPos()
        end
    end

    for x, y in pairs(self.WANT_VM) do
        if (System.GetEntityByName(x)) then
            self:V_MODEL(unpack(y))
            self.WANT_VM[x] = nil
        end
    end

    self:UpdateExplosionEffects()
end

--=========================================================
-- Events
ClientMod.Update_V_ANIM = function(self, id, info)

    local v = GetEntity(id)
    if (not v) then
        return
    end

    local anim
    local bFwd = true
    local dirLp={x=0,y=0,z=0}
    local dirNow=v:GetDirectionVector()
    if (v.LAST_POS and DistanceVectors(v:GetPos(),v.LAST_POS)>0.1) then
        SubVectors(dirLp,v:GetPos(),v.LAST_POS)
        NormalizeVector(dirLp)
        if (dirLp.x * dirNow.x + dirLp.y * dirNow.y + dirLp.z * dirNow.z) > 0 then
            DebugLog("The vehiclePosLast is in front of the vehicle.")
            anim=getrandom(info.FWD)
        else
            DebugLog("The vehiclePosLast is behind the vehicle.")
            anim=getrandom(info.BACK)
        end
    end

    if (anim) then

        self:AddLA(v.CM,anim,true)
       -- if (timerexpired(v.ANIM_TIMER,v.ANIM_TIME) or anim~= v.ANIM) then

         --   v:StartAnimation(0,anim)
       --     v.ANIM_TIME=v:GetAnimationLength(0,anim)
       --     v.ANIM_TIMER=timerinit()
       --     v.ANIM=anim
       -- end
     else
        self:AddLA(v.id,"anim",false)
    end
end

--=========================================================
-- Events
ClientMod.UpdateExplosionEffects = function(self)
    for _, aInfo in pairs(self.EXPLOSION_EFFECTS) do
        if (timerexpired(aInfo.Timer, GetCVar("crymp_explosionWeedLifetime"))) then
            self:UnloadEffectAll(aInfo.Main)
            System.RemoveEntity(aInfo.Main.id)
            for __, hWeed in pairs(aInfo.Ents) do
                System.RemoveEntity(hWeed.id)
            end
            table.remove(self.EXPLOSION_EFFECTS, _)
            return self:UpdateExplosionEffects()
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
    Script.SetTimer(2,function()
        DebugLog("nter %d",seat)
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
      --  DebugLog(_time- menu[-4])
        if (_time- menu[-4] > 5) then
            show=false
        end
    else
       -- menu[-4]=nil
    end

    if (not show) then
      --  menu[-1]=nil menu[-2]=nil
       -- self:FadeMenu("vote",1)
      --  DebugLog("hide?")
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

--[[

['objects/vehicles/us_vtol_transport/us_vtol_transport.cga'] = {
        [0] = 'vtol_transport_engfront_to_flying',
        [1] = 'vtol_transport_engfront_to_hovering',
        [2] = 'vtol_transport_lg_close',
        [3] = 'vtol_transport_lg_open',
    };


           [0] = 'Default',
        [1] = 'tank_cannon_recoil',
        [2] = 'tank_cineharboropenhatch_01',
        [3] = 'tank_cineharboropenhatchidle_01',


            ['objects/vehicles/us_cargoplane/us_cargoplane.cga'] = {
        [0] = 'cargoplane_backdoor_close',
        [1] = 'cargoplane_backdoor_open',
        [2] = 'cargoplane_land',
        [3] = 'cargoplane_rotor',
        [4] = 'cargoplane_takeoff',
    };
    ['objects/vehicles/us_destroyer/us_destroyer_mp.cga'] = {
        [0] = 'Default',
    };
    ['objects/vehicles/us_fighter_b/us_fighter.cga'] = {
        [0] = 'Default',
        [1] = 'fighter_canopy_open',
        [2] = 'fighter_landing',
        [3] = 'fighter_landing_gear_close',
        [4] = 'fighter_landing_idle',
        [5] = 'fighter_wing_close',
        [6] = 'fighter_wing_open',


    ['objects/vehicles/asian_tank/asian_tank.cga'] = {
        [0] = 'tank_cannon_recoil',
        [1] = 'tank_closehatch',
        [2] = 'tank_enterclosedhatch',
        [3] = 'tank_toopenhatch',
    };
    ['objects/vehicles/asian_tank/asian_tank_low.cga'] = {
        [0] = 'tank_cannon_recoil',
        [1] = 'tank_closehatch',
        [2] = 'tank_enterclosedhatch',
        [3] = 'tank_toopenhatch',
    };
    ['objects/vehicles/asian_tank/tread_left.chr'] = {
        [0] = 'null',
    };
    ['objects/vehicles/asian_tank/tread_right.chr'] = {
        [0] = 'null',
    };
    ['objects/vehicles/asian_truck_b/asian_truck_b.cga'] = {
        [0] = 'truck_b_door1_enter',
        [1] = 'truck_b_door1_exit',
        [2] = 'truck_b_door2_enter',
        [3] = 'truck_b_door2_exit',
        [4] = 'truck_b_gunner_pitch',
        [5] = 'truck_b_gunner_yaw',
        [6] = 'truck_b_steeringwheel',
    };
    ['objects/vehicles/civ_car1/civ_car.cga'] = {
        [0] = 'car_door1_exit',
        [1] = 'car_door1_open',
        [2] = 'car_door2_exit',
        [3] = 'car_door2_open',
        [4] = 'car_steeringwheel',
    };
    ['objects/vehicles/kuanti/kuanti_radarjammer.cga'] = {
        [0] = 'Default',
    };
    ['objects/vehicles/ltv/ltv.cga'] = {
        [0] = 'door_left_front_enter',
        [1] = 'door_left_front_exit',
        [2] = 'door_left_rear_enter',
        [3] = 'door_left_rear_exit',
        [4] = 'door_right_front_enter',
        [5] = 'door_right_front_exit',
        [6] = 'door_right_rear_enter',
        [7] = 'door_right_rear_exit',

           };
    ['objects/library/vehicles/mobile_crane/mobile_crane.cga'] = {
        [0] = 'Default',
        [1] = 'crane_cinematic',
        [2] = 'crane_cinematic_freakout',
        [3] = 'crane_cinematic_wheelbackward',
        [4] = 'crane_turnleft',
        [5] = 'crane_turnright',
        [6] = 'crane_wheelbackward',
        [7] = 'crane_wheelforward',
    };


            [1] = 'crane_cinematic',
        [2] = 'crane_cinematic_freakout',
        [3] = 'crane_cinematic_wheelbackward',
        [4] = 'crane_turnleft',
        [5] = 'crane_turnright',
        [6] = 'crane_wheelbackward',
        [7] = 'crane_wheelforward',
]]
--=========================================================
-- Events
ClientMod.V_MODEL = function(self, name, model, id, p, d, s, ht)

    local vehicle = GetEntity(name)
    if (not vehicle) then
        self.WANT_VM[name] = { name, model, id, p, d, s, ht } -- lag can cause RPC code to be recieved before entity gets initialized! WHAAAT
        return
    end

    if (not vehicle.vehicle) then return end

    if (vehicle and model) then


        --[[
        if (false and self.DEBUG) then

            vehicle:LoadObject(0, model)
            vehicle:DrawSlot(0,1)


          --  vehicle:SetSlotWorldTM(10,p,d)
            local rp=vehicle:GetPos()
            p = {
                x = (p and p.x or 0) + 0 or rp.x,
                y = (p and p.y or 0) + 0 or rp.y,
                z= (p and p.z or 0) + 0 or rp.z,
            }
            DebugLog(Vec2Str(p))
            vehicle:SetSlotPos(0,p)

            local rd=vehicle:GetAngles()
            d = {
                x = (d and d.x or 0) +0 or rd.x,
                y = (d and d.y or 0) +0 or rd.y,
                z= (d and d.z or 0) +0 or rd.z,
            }
            vehicle:SetSlotAngles(0,d)

            DebugLog(self:GetObjMaterial(model))
            vehicle:SetMaterial(self:GetObjMaterial(model))
        else]]
            if (vehicle.CM) then System.RemoveEntity(vehicle.CM) end
            local CM = System.SpawnEntity({ class = "BasicEntity", position = vehicle:GetPos(), orientation = vehicle:GetDirectionVector(), name = vehicle:GetName() .. "_cm", properties = { object_Model = model }})

            local e=model:sub(-3)
            --crysis geometry animated
            if (e=="cga"or e=="chr")then
                CM:LoadCharacter(0, model)
            else -- crysis geometry file
                CM:LoadObject(0, model)
            end
            --[[if (id == VM_USPLANE) then -- for collision
                model = string.sub(model, 1, string.len(model) - 4) .. ".cga"
                DebugLog("load clollision fix %s",model)
                CM:LoadObject(1, model)
                CM:DrawSlot(1, 1)
                CM:DrawSlot(0, 0)
            end]]

            CM:PhysicalizeSlot(0, { flags = 1.8537e+008 }) -- special flags for correct collision.
            CM.Parent = vehicle.id

            self.VM[CM.id] = { EntityID = vehicle.id, ID = id }

            vehicle:DrawSlot(0, 0)
            vehicle:AttachChild(CM.id, PHYSICPARAM_SIMULATION)


            vehicle.CM = CM.id
            vehicle.CMID = id

            if (p) then CM:SetLocalPos(p) end
            if (d) then CM:SetLocalAngles(d) end
            if (s) then CM:SetScale(s) end
            if (ht) then for i = 1, 4 do vehicle:DrawSlot(i, 0) end end

            local anim=({
                [VM_HELI]="helicopter_rotate_mainrotor",
                [VM_AAA]="aaa_radar_rotate",
            })[id]
            self:AddLA(CM.id,anim,anim~=nil)
            DebugLog("anim=%s",anim or "null")
        --end
    end

end

--=========================================================
-- Events
ClientMod.RequestModel = function(self, channelId, modelId, modelPath, soundPath, seatFixId)
    local hPlayer = GP(channelId)
    if (not hPlayer) then
        return ClientLog("no chan..again")
    end

    local sG = string.match(modelPath, "^G:(.*)")
    if (sG) then
        DebugLog("using global for MODEL %s",sG)
        modelPath = _G[sG] or modelPath -- fallback in case its an error!
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
    if (hPlayer.JETPACK.HAS) then
        -- need to re-attach!
        self:Jetpack(hPlayer:GetChannel(),false)
        self:Jetpack(hPlayer:GetChannel(),true)
    end
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
ClientMod.StartBurn = function(self, ent,effect,enable)

    local hEntity = GetEntity(ent)
    if (not hEntity) then
        return ClientLog("<entity not found >%s",g_ts(ent))
    end

    hEntity.Burning = self:LoadEffectOnEntity(hEntity, "burn", {
        Effect = effect or "explosions.barrel.burning",
        Speed  = 1,
        Pulse = 5,
    }, true)
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
        UnitScale = 3.881
    }, enable)
end

-- PICKUP:
-- clay pick_up_claymore_left_01

-- PLACE
-- av

--=========================================================
ClientMod.GetWeaponOwner = function(self,i)

    for _, v in pairs(g_pGame:GetPlayers() or System.GetEntitiesByClass("Player")) do
        if (v.actor:IsPlayer()) then
            for __, _v in pairs(v.inventory:GetInventoryTable() or {}) do
                if (_v == i.id) then
                    return true
                end
            end
        end
    end
    return false
end

--=========================================================
ClientMod.GetItemDefByClass = function(self, c)
    local def
    for i, v in pairs(g_gameRules.buyList) do
        if (v.class and v.class == c) then
            def = v
        end
    end
    return def
end

--=========================================================
ClientMod.GetItemDefBy = function(self, c)
    return g_gameRules.buyList and g_gameRules.buyList[c]
end

--=========================================================
ClientMod.ItemChanged = function(self, p, n, o)

    if (IS_PS) then
        self:UpdateBLSell()
    end

    -- slh?
    local hOld = GetEntity(o)
    local iTeam = g_pGame:GetTeam(p.id)
    local cg,cr=self.COLORS.green,self.COLORS.red
    if (hOld) then
        local bDropped = false

        if (GetVersion() > 16) then
            bDropped = not hOld.weapon:GetShooter()
        elseif (false and hOld.GetParent) then
            bDropped = hOld:GetParent()==nil
        else
            bDropped = not self:GetWeaponOwner(hOld)
        end

        if (bDropped) then
            if (self.id==p.id or (IS_PS and iTeam == g_pGame:GetTeam(self.id))) then
                --DebugLog("GREEN!")
                self:SLH(hOld,cg,10) -- highlight GREEN
            else
                --DebugLog("RED")
                self:SLH(hOld,cr,10) -- highlight RED
            end
        end
    end

    local pick
    if (n) then

        --if still in highlight, stop it, for ourselfs, timer is 2.5s, for othrs its
        if (true or not timerexpired(n.SLH_TIMER, n.SLH_TIME)) then
            self:SLH(n,((p.id~=self.id and (not IS_PS or iTeam~=g_pGame:GetTeam(self.id)))) and cr or cg,(n.id==self.id and 2.5 or 1))
        else
        end

    local a={["AVMine"]="arm_01",}
     pick = (p.PREVIOUS_INV[n.id] == nil or (n.class~="GaussRifle" and timerexpired(p.PREVIOUS_INV[n.id],math.random(45,72))))
    if (GetCVar("crymp_weapon_cockingalways") >0 or pick)then
        a["DSG1"]="cock_right_01"
        a["GaussRifle"]=getrandom({"cock_right_akimbo_01","cock_right_01"})
        a["SMG"]="select_cock_01"
        a["Shotgun"]=getrandom({"post_reload_01","post_reload_02"})
       -- a["SCAR"]="fire_tactical_right_akimbo_01"
       --a["LAW"]="idle_01"
    end
    if (p.id==self.id)then
        if (n) then
            local an=a[n.class]
            if (an) then n:StartAnimation(0,an,8)end
        end
        if (o) then
            o.FPARM = nil
        end
    end
    end

    local new={}
    for _,y in pairs(self.ent.inventory:GetInventoryTable()or{}) do
        new[y]=not pick and p.PREVIOUS_INV[y] or timerinit()
    end


    p.PREVIOUS_INV = new
end

--=========================================================
ClientMod.IDLEFP = function(self, chan, anim, speed, all)

    -- !! melee_01 >

    local p = GP(chan)
    if (not p) then
        return
    end
    if (p.id == self.id) then
        local hFists = g_localActor.inventory:GetCurrentItem()
        if (not hFists or (not all and hFists.class ~= "Fists")) then
            if (GetCVar("crymp_fp_anim_allowall")<=0) then
                return DebugLog("not playing fp. bad item")
            else
                hFists = p:GetItemByClass("Fists")if(not hFists) then return DebugLog("f not found")end
            end
        end
        hFists:Hide(0)
        hFists:DrawSlot(0,1)
        hFists:StartAnimation(0, anim, 8)

        hFists.animtimer = timerinit()
        hFists.animtime  = hFists:GetAnimationLength(0, anim, 8, 0, speed or 1)

        DebugLog("len=%f",hFists.animtime or -6969)
        DebugLog("fp=%s",hFists.fpanim or -6969)
        --end
    end
end

--=========================================================
ClientMod.ANIM = function(self, chan, anim, freeze)

    local p = GP(chan)
    if (not p) then
        return
    end

    p:StartAnimation(0, anim, 8) -- server SCHLOTT
    local iAnimTime = p:GetAnimationLength(0, anim)

    p.ANIM_TIME = iAnimTime
    p.ANIM_TIMER = timerinit()

    if (freeze and p.id==self.id) then
        g_pGame:FreezeInput(true)
        Script.SetTimer(iAnimTime * 1000, function() g_pGame:FreezeInput(false)  end)
    end

end

--=========================================================
ClientMod.IDLE = function(self, chan, anim, fpanim, loop, reset)


    local speed = 1
    local slot = GetCVar("crymp_idleanimslot")

    local p = GP(chan)
    if (not p or p:GetVehicle() or p:IsDead() or p:IsSpectating() or p.actorStats.stance == STANCE_SWIM) then
        return
    end

    if (p.ANIM_TIMER ~= nil and not timerexpired(p.ANIM_TIMER, p.ANIM_TIME)) then
        p.IDLE.QUEUED = anim
        return
    end

    p.ANIM_TIME = nil
    p.ANIM_TIMER = nil

    p.IDLE.STANCE = p.actorStats.stance
    p.IDLE.POS = p:GetPos()

    if (anim == "stop" or (p.LAST_VELOCITY and LengthVector(p.LAST_VELOCITY) > 0)) then
        if (p.IDLE.PLAYING and not timerexpired(p.IDLE.TIMER, p.IDLE.TIME - 0.1)) then -- try to not call this if IDLE is no longer playing.. else FREEZING MODEL
            p:StopAnimation(0,slot)
            p:StartAnimation(0, "Default" ,slot)
            p:ForceCharacterUpdate(0, true) -- what this
            DebugLog("mierda")
        end

        p.IDLE.QUEUED = nil
        p.IDLE.PLAYING = false
        return
    end


    DebugLog("ULTRA IMMERSIVE IDLE RECEIVED %s",anim)

    --7 slot 7 slot 7 77
    if (anim ~= "none") then -- for fp only (salute etc)

        p.IDLE.PLAYING = true
        p.IDLE.LOOP = loop
        p.IDLE.ANIM = anim

        if (not reset and p.IDLE.TIME and not timerexpired(p.IDLE.TIMER, p.IDLE.TIME)) then
            p.IDLE.QUEUED = anim
            DebugLog("added to QUEUE!")
            return
        end

        p:StopAnimation(0,slot)
        p:StartAnimation(0, anim, slot, 0, speed)
        p:ForceCharacterUpdate(0, true) -- what this

        --self:StartAnimation( 0,self.Properties.Animation.Animation,0,0,1,self.Properties.Animation.bLoop,1 );

        p.IDLE.TIMER = timerinit()
        p.IDLE.TIME = p:GetAnimationLength(0, anim)
    end
    if (fpanim and p.id == self.id) then
        local hFists = g_localActor.inventory:GetCurrentItem()

            if (not hFists or hFists.class ~= "Fists") then

                if (GetCVar("crymp_fp_anim_allowall") <= 0) then
                    return
                else
                    hFists = (p:GetItemByClass("Fists"))
                    if (not hFists) then
                        return
                    end
                end
            end

        if (timerexpired(hFists.animtimer, hFists.animtime)) then
            hFists:StartAnimation(0, fpanim, 8)

            hFists.animtimer = timerinit()
            hFists.animtime = hFists:GetAnimationLength(0,fpanim)+7

            DebugLog("len=%f",hFists.animtime or -6969)
            DebugLog("fp=%s",hFists.fpanim or -6969)
        end
    end
end

--=========================================================
-- PLAY SOUND EVENT
ClientMod.StopSound = function(self, entity, id, slot)

    id = id or "generic"

    entity = (entity or self.ent)
    entity.SoundSlots = entity.SoundSlots or {}
    entity.SoundSlots[id] = entity.SoundSlots[id] or {}

    slot = slot or -1

    local sslot = entity.SoundSlots[id][slot]
    if (sslot and Sound.IsPlaying(sslot)) then
        entity:StopSound(sslot)
    end

    entity.SoundSlots[id][slot] = nil
end

--=========================================================
ClientMod.IMP = function(self, ent, dir, str, pos)

    ent = GetEntity(ent)
    if (not ent) then
        return
    end

    ent:AddImpulse(-1, pos or ent:GetCenterOfMassPos(), dir, str, 1)
end

--=========================================================
ClientMod.ESLH = function(self, n,c,p,t,rad)

    local a=System.GetEntities()
    local e = GetEntity(n)
    if (not e) then

        -->>>> this is god AWFUL!!
        for _,h in pairs(a) do
            if (h.class==c) then
                local hp=h:GetPos()
                if (hp.x==p.x and hp.y==p.y and hp.z==p.z)then
                    e=h
                    break
                end
                if (DistanceVectors(hp,h:GetPos())<(rad or 1)) then
                    if (g_pGame:GetTeam(h.id)==t) then
                        if (e) then
                            DebugLog("uncertain...."..h:GetName()..","..e:GetName())
                            e=nil
                          --  break
                        end
                        e = h
                    end
                end
            end
        end
    end
    if e then
        self:SLH(e.id,g_pGame:GetTeam(e.id)==g_pGame:GetTeam(self.id) and "green" or "red",15)
    else
        DebugLog("not found..")
    end
end

--=========================================================
ClientMod.SLH = function(self, name, c, t)
    if (not HUD.SetSilhouette) then
        return
    end

    for _,__ in pairs(System.GetEntities()) do
        if (__.class=="claymoreexplosive") then
            DebugLog(__:GetName())
        end
    end
    local iAlpha = 1
    local hEntity = GetEntity(name)
    if (not hEntity) then
        return DebugLog("Entity %s not found for slh", g_ts(name))
    end

    c = (c and (self.COLORS[c] or c))
    HUD.SetSilhouette(hEntity.id, c[1], c[2], c[3], iAlpha, t or -1)
    hEntity.SLH_TIMER = timerinit()
    hEntity.SLH_TIME = t or 0
end

--=========================================================
-- PLAY SOUND EVENT

ClientMod.INCREASE_VOICE_VOLUMES = true
ClientMod.PATCHED_VOICES = {}

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

    ----------------------
    -- FROM FAPP!!

    --if (p.lastPainSound and Sound.IsPlaying(p.lastPainSound)) then
    --    return;
    --end

    --[[if (p ~= g_localActor) then
        if (p:GetDistance(g_localActorId) > 100) then --skip sounds too far away
            return;
        end
    end]]
    if (self.INCREASE_VOICE_VOLUMES and not self.PATCHED_VOICES[sound] and CPPAPI.GetLanguage and CPPAPI.AddLocalizedLabel and sound:sub(1, 3) ~= "mp_") then
        local language = CPPAPI.GetLanguage()
        local tbl = {
            languages = {},
            english_text = sound,
            sound_volume = 0.8,
            sound_event = "",
            sound_radio_ratio = 0,
            sound_radio_background = 0,
            sound_radio_squelch = 0,
            sound_ducking = 0,
            --keep_existing = true,
            use_subtitle = false,
        }

        tbl.languages[language:lower()] = {
            sound_volume = 0.8,
            sound_radio_ratio = 0.0,
            sound_radio_background = 0,
            sound_radio_squelch = 0,
            sound_event = "",
            --localized_text = "30 seconds until mission termination.",
        }

        local ok = CPPAPI.AddLocalizedLabel(sound, tbl)

        if (ok) then
            DebugLog("Modified label "..sound.." for language: "..language:lower());

            self.PATCHED_VOICES[sound] = true
        else
            DebugLog("Failed Modified label "..sound.." for language: "..language:lower());

        end
    end

    if (loop) then
        TD = bor(TD,SOUND_LOOP)
    end


    DebugLog("[%s] %s->play%s",string.sub(sound, 2),entity:GetName(),sound)
    if (entity.actor and (string.sub(sound, 0,2) == "ai" or string.find(sound,"dialog"))) then

        TD = bor(TD, SOUND_EVENT)
        TD = bor(TD, SOUND_VOICE)
      --  TD = bor(TD, SOUND_RADIUS)

      --  TD = bor(bor(bor(SOUND_EVENT, SOUND_VOICE), SOUND_DEFAULT_3D), SOUND_RADIUS)
      --  entity.SoundSlots[id][slot] = entity:PlaySoundEventEx(sound, TD, 3, vc, 15, 35, fol)
   --     Sound.SetSoundVolume(entity.SoundSlots[id][slot], 10)
   -- else
       -- entity.SoundSlots[id][slot] = entity:PlaySoundEvent(sound, g_Vectors.v000, g_Vectors.v010, SOUND_VOICE,SOUND_SEMANTIC_PLAYER_FOLEY)
        --entity.SoundSlots[id][slot] = entity:PlaySoundEventEx(sound, TD, 1, g_Vectors.v000, 1, 5, fol );
    --else
    end
    entity.SoundSlots[id][slot] = entity:PlaySoundEvent(sound, vc, vc2, TD, fol)

    --p.lastPainSound = p:PlaySoundEvent(se,g_Vectors.v000,g_Vectors.v010, bor(SOUND_LOAD_SYNCHRONOUSLY, SOUND_VOICE), v);


    --entity.SoundSlots[id][slot] = entity:PlaySoundEvent(sound, vc, vc2, TD, fol)
    if (loop) then
        Sound.SetSoundLoop(entity.SoundSlots[id][slot], 1)
    end
end

--=========================================================
-- Events
ClientMod.UnloadEffectAll = function(self, hEntity)
    if (not hEntity.EffectSlots) then return end
    for _, aIDs in pairs(hEntity.EffectSlots) do
        for __, hSlot in pairs(aIDs) do
            DebugLog("brutally unloaded %s",g_ts(hSlot))
            hEntity:FreeSlot(hSlot)
        end
    end
    hEntity.EffectSlots = nil
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
        if (enable) then return true, DebugLog("already") end -- on?
        hEntity:FreeSlot(hSlot)
        hEntity.EffectSlots[id][iSlot] = nil
        DebugLog("Disable eff")
        return false -- off

    elseif (enable) then
        hEntity.EffectSlots[id][iSlot] = hEntity:LoadParticleEffect(iSlot, sEffect, aParams)
        if (params.Pos) then
            hEntity:SetSlotWorldTM(hEntity.EffectSlots[id][iSlot], params.Pos, params.Dir or g_Vectors.up)
        end
        DebugLog("Enable eff")
        return true -- on
    end

    DebugLog("F > %s", g_ts(enable))
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

ClientMod.TS=ClientMod.ToServer

--=========================================================
-- Inject
ClientMod.Inject = function(self, aParams)
    local sEntity   = aParams.Class
    local hEntity   = aParams.Entity
    local sTarget   = aParams.Target
    local fFunction = aParams.Function
    local iType     = (aParams.Type or eInjection_Replace)
    local bPatchEntities = aParams.PatchEntities or aParams.Patch

    if (hEntity) then
        ServerInjector.InjectEntity(aParams)
    end

    local hClass = _G[sEntity]
    local sScriptPath
    if (CPPAPI.GetEntityScriptPath) then
        sScriptPath = CPPAPI.GetEntityScriptPath(sEntity)
    else
        sScriptPath = ({
            ["GUI"] = "Scripts/Entities/Others/GUI.lua",
            ["Door"] = "Scripts/Entities/Doors/Door.lua",
        })[sEntity]
    end

    if (isString(sEntity) and not hClass) then
        DebugLog("Class %s to Inject not found", g_ts(sEntity))
        if (not sScriptPath) then
            return
        end
        DebugLog("Loding %s",sScriptPath)
        Script.ReloadScript(sScriptPath)
    else
        DebugLog("%s OK",g_ts(sEntity))
    end

    local function Replace(sT, c, f)
        if (not c) then
            ClientLog("%s not found",g_ts(sT))
            return
        end
        local aNest = string.split(sT, ".")
        local iNest = table.size(aNest)
        if (iNest == 1) then
            if (iType == eInjection_Replace) then c[sT] = f end
            DebugLog("REPLACED OK %s!",sT)
        else
            local h = table.remove(aNest, 1)
            if (not c[h]) then
                return ClientLog("index " .. g_ts(h) .. " not found to inject on %s!",sT)
            end
            return Replace(table.concat(aNest, "."), c[h], f)
        end
    end

    sEntity = not isArray(sEntity) and { sEntity } or sEntity
    for i, v in pairs(sEntity) do

        if (isArray(sTarget)) then
            for _, s in pairs(sTarget) do Replace(s, _G[v], fFunction) end
        else
            Replace(sTarget, _G[v], fFunction)
        end

        if (bPatchEntities) then
            for _, hEnt in pairs(System.GetEntitiesByClass(v) or {}) do
                if (isArray(sTarget)) then
                    for _, s in pairs(sTarget) do Replace(s, hEnt, fFunction) end
                else
                    Replace(sTarget, hEnt, fFunction)
                end

                if (aParams.Call) then
                    fFunction(hEnt)
                end
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
        Class    = "Player",
        Target   = "CurrentItemChanged",
        PatchEntities = true,
        Function = function(self, newItemId, lastItemId)

            --
            g_Client:ItemChanged(self,GetEntity(newItemId),GetEntity(lastItemId))

            local item = System.GetEntity(newItemId);
            if(item) then
                -- notify squadmates about the attachments on new weapon
                local weapon = item.weapon;
                local entityAccessoryTable = SafeTableGet(self.AI, "WeaponAccessoryTable");
                if(weapon and entityAccessoryTable) then
                    if(weapon:GetAccessory("Silencer") or item.class == "Fists") then
                        entityAccessoryTable["Silencer"] = 1;
                        self.AI.Silencer = true;
                    else
                        entityAccessoryTable["Silencer"] = 0;
                        self.AI.Silencer = false;
                    end

                    if(weapon:GetAccessory("SCARIncendiaryAmmo")) then
                        entityAccessoryTable["SCARIncendiaryAmmo"] = 2;
                        entityAccessoryTable["SCARNormalAmmo"] = 0;
                    elseif(weapon:GetAccessory("SCARNormalAmmo")) then
                        entityAccessoryTable["SCARIncendiaryAmmo"] = 0;
                        entityAccessoryTable["SCARNormalAmmo"] = 2;
                    end
                    -- use a timer to avoid repeated spamming notifications
                    self:SetTimer(SWITCH_WEAPON_TIMER,2000);
                end
            end
        end
    })

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

            self.PREVIOUS_INV = self.PREVIOUS_INV or { }
            self.FLYING_CHAIR = self.FLYING_CHAIR or { ENTITYID = nil }
            self.JETPACK = self.JETPACK or { HAS = false, VISIBLE = false, PARTS = {}, MAIN = nil, EXHAUST0 = nil, EXHAUST1 = nil }
            self.CM = self.CM or { ID = 0, File = "" }
            self.IDLE = self.IDLE or {
                PLAYING  = false,
                POS      = self:GetPos(),
                TIMER    = timerinit() - 9999,
                QUEUED   = nil,
            }

            self.actor:GetCurrentAnimationState()
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
            self.GetVehicle   = function(this,c) return GetEntity(this.actor:GetLinkedVehicleId()) end


            self.GetItemByClass   = function(this,c) return GetEntity(this.inventory:GetItemByClass(c)) end
            self.GetCurrentItem   = function(this) return GetEntity(this.inventory:GetCurrentItem()) end

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
-- guiguiguiguig
ClientMod.PatchGUI = function(client)


    -- =========================================================================================================
    client:Inject({
        Class    = "GUI",
        Target   = "OnSpawn",
        PatchEntities = true,
        Function = function(self)
            self:OnReset()
        end

    })

    -- =========================================================================================================
    client:Inject({
        Class    = "GUI",
        Target   = "OnReset",
        PatchEntities = true,
        Call          = true,
        Function = function(self)

            local sName = self:GetName()
            local function g(s,m,n)
                local x = string.match(sName, s .. "={(" .. (m or ".-") .. ")}")
                --ClientLog("%s=%s",s,g_ts(x))
                if (n) then
                    return tonumber(x)
                end
                return x
            end

            local sObj 		= (g("Model") or self.Properties.objModel)
            local iPhysics 	= (g("Physics", "%d+", 1) or self.Properties.bPhysicalized)
            local fMass 	= (g("Mass", "%d*", 1) or self.Properties.fMass)
            local fRigid 	= (g("Rigid", "%d", 1) or self.Properties.bRigidBody)
            local fResting 	= (g("Resting", "%d", 1) or self.Properties.bResting)
            local fUsable 	= (g("Use", "%d", 1) or 0)
            local fPickable	= (g("Pick", "%d", 1) or 0)
            local fScale	= (g("Scale", ".-", 1) or 0)
            local sEffect   = g("PProps" or "") -- client only
            local sSound	= g("Sound" or "") -- client only

            DebugLog("s=%s",sSound)
            if (CryAction.IsClient()) then
                if (sSound and sSound ~="") then
                    local sndFlags = SOUND_DEFAULT_3D
                    if (string.match(sSound, "&loop$")) then
                        sndFlags = bor(sndFlags, SOUND_LOOP)
                    end
                    DebugLog("s=%s",string.gsub(sSound, "&loop$", ""))
                    self.SndSlot = self:PlaySoundEvent(string.gsub(sSound, "&loop$", ""), g_Vectors.v000, g_Vectors.v010, sndFlags, SOUND_SEMANTIC_PLAYER_FOLEY)
                end

                if (sEffect and sEffect~="") then
                    if (g_Client) then
                        g_Client:LoadEffectOnEntity(self, "generic0", {Effect = sEffect,CountScale=1,Scale=1}, true)
                    end
                end
            end

            if (fUsable ~= 0) then MakeUsable(self) end
            if (fPickable ~= 0) then MakePickable(self) end
            if (fScale > 0) then self:SetScale(fScale) end

            self:Activate(1)
            self:SetUpdatePolicy(ENTITY_UPDATE_VISIBLE)
            self:SetViewDistRatio(450)

            if (sObj ~= "") then
                self:LoadObject(0, sObj)
                DebugLog("load %s",sObj)
            end

            --ClientLog(sObj)
            --(fMass)
            ----ClientLog(type(fMass))
            --ClientLog("%s",Vec2Str(self:GetPos()))

            self:DrawSlot(0, 1)

            if (iPhysics ~= 0) then

                local iPhysType   = PE_STATIC
                local aPhysParams = { mass = fMass, }
                if (fRigid ~= 0) then iPhysType = PE_RIGID end

                self:Physicalize(0, iPhysType, aPhysParams)
                if (fResting ~= 0) then
                    self:AwakePhysics(0)
                else
                    self:AwakePhysics(1)
                end
            end

            DebugLog("GUI Spawned. Name is %s", sName)
        end
    })


end

--=========================================================
-- Patch Game rules (and flags..)
ClientMod.PatchVB = function(client)

    local aClasses = table.append({"VehicleBase"}, (System.GetVehicleClasses and System.GetVehicleClasses() or { "Alien_warrior",
        "Asian_aaa", "Asian_apc", "Asian_helicopter", "Asian_ltv", "Asian_patrolboat", "Asian_tank", "Asian_truck",
        "Civ_car1", "Civ_speedboat",
        "DefaultVehicle",
        "US_apc", "US_hovercraft", "US_ltv", "US_smallboat", "US_tank", "US_transportVTOL", "US_trolley", "US_vtol"
    }))
    client:Inject({
        Class    = aClasses,
        Patch    = true,
        Target   = {"Client.OnHit"},
        Function = function(self, aHit)
            g_Client:VehicleHit(self,aHit)
        end

    })

end

--=========================================================
-- Patch Game rules (and flags..)
ClientMod.PatchDoor = function(client)

    client:Inject({
        Class    = "Door",
        Target   = {"OnUsed"},
        Function = function(self, hUser)

            if (not hUser or hUser.id ~= g_localActor.id) then -- Possible manipulation
                g_Client:TS(0,eAC_Door)
                return
            end

            if (hUser.id == g_Client.id and self.action ~= DOOR_OPEN) then
                local iSpeed = 1
                if (hUser:GetSuitMode(NANOMODE_SPEED)) then
                    iSpeed = 2.5
                end
                g_Client:IDLEFP(hUser:GetChannel(), "melee_01", iSpeed, 1)
            end

            DebugLog("%s is using door %s", hUser:GetName(), self:GetName())
            self.server:SvRequestOpen(hUser.id, self.action ~= DOOR_OPEN)
        end
    })

end

--=========================================================
-- Patch Game rules (and flags..)
ClientMod.UpdateBLSell = function(self)

    g_gameRules.buyList["sell_1"].price = 0
    g_gameRules.buyList["sell_1"].available = false
    g_gameRules.buyList["sell_2"].price = 0
    g_gameRules.buyList["sell_2"].available = false

    local hCurrent = self.ent:GetCurrentItem()
    if (hCurrent) then
        local def = self:GetItemDefByClass(hCurrent.class)
        if (def) then
            g_gameRules.buyList["sell_1"].price = def.price * 0.75 -- FIXME, sync with server ! gobalsynchedvalue?? maybe??
            g_gameRules.buyList["sell_2"].price = def.price * 0.75 -- FIXME, sync with server ! gobalsynchedvalue?? maybe??
        end
    end

    HUD.UpdateBuyList()
end

--=========================================================
-- Patch Game rules (and flags..)
ClientMod.PatchBL = function(self)

    -- TODO: top tech price reducing! (also on server!)
    DebugLog("patching bl")


    -- Vehicles!
    self.buyList["usvtol"].price = 800
    self.buyList["nkhelicopter"].price = 600
    self.buyList["nkapc"].price = 600
    self.buyList["ustank"].price = 700
    self.buyList["nktank"].price = 700

    -- Weapons!
    self.weaponList["shiten"] = { id = "shiten", name = "ShiTen", category = "@mp_catWeapons", price = 400, loadout = 1, weapon = true, class = "ShiTen", uniqueId = 620, uniqueloadoutgroup = 1, uniqueloadoutcount =2};
    self.buyList["rpg"].price = 200
    self.buyList["dsg1"].price = 350
    self.buyList["gauss"].price = 650

    -- Ammo!
    self.weaponList["sell_1"]  = { id = "sell",   name = "Sell Current Item", 		category = "@mp_catExplosives", 	price = 0, 		loadout = 1};
    self.ammoList["sell_2"]  = { id = "sell",   name = "Sell Current Item", 		ammo = true, category = "@mp_catAmmo", 	price = 0, 		loadout = 1};
    self.buyList["rocket"]   = { id = "rocket", name = "@mp_eRocket",       invisible = true, ammo = true, price = 25, amount = 1, category="@mp_catAmmo", loadout = 1 }

    -- Update!
    self.buyList["sell_1"]  = self.weaponList["sell_1"]
    self.buyList["sell_2"]  = self.ammoList["sell_2"]
    self.buyList["shiten"]  = self.weaponList["shiten"]

    for _, aDef in pairs(self.buyList) do
       --[[ if (aDef.category == "@mp_catWeaponsEx") then
            aDef.category = "mp_catWeapons"
        end
        if (aDef.category == "@mp_catExplosivesEx") then
            aDef.category = "mp_catExplosives"
        end]]
    end

    HUD.UpdateBuyList()
    HUD.UpdateBuyList("")
    -- ====================================================
--[[
    local aWeaponList = table.append(g_gameRules.weaponList, {
        --{ id = "flashbang", 		name = "@mp_eFlashbang", 	category = "@mp_catExplosives", price = 10, 	loadout = 1, class = "FlashbangGrenade", 	amount = 1, weapon = false, ammo = true},
    })

    local aAmmoList = table.append(g_gameRules.ammoList, {
        { id = "sell",          name = "Sell Current Item",     category = "@mp_catAmmo", 	price = 0, 		loadout = 1},
        { id = "rocket",        name = "@mp_eRocket",            price = 25, amount = 1, category="@mp_catAmmo", loadout = 1 },
    })
    local aEquipList = table.append(g_gameRules.equipList, {
        --{ id = "binocs", 	name = "@mp_eBinoculars", 	category = "@mp_catEquipment", price = 50, loadout = 1, class = "Binoculars", 	uniqueId = 101},
    })
    local aVehicleList = table.append(g_gameRules.vehicleList, {
       -- { id = "speedboat", 		name = "Speed Boat", 			category = "@mp_catVehicles", price = 0, 	loadout = 0, class = "Civ_speedboat", 		modification = "MP", 			buildtime = 10},
    })
   local aProtoList = table.append(g_gameRules.protoList, {
        --{ id = "moac", name = "@mp_eAlienWeapon", category = "@mp_catWeapons", price = 300, loadout = 1, class = "AlienMount", uniqueId = 11, uniqueloadoutgroup = 1, uniqueloadoutcount =2,level = 50, weapon = true},
   })


    -- ====================================================
    g_gameRules.buyList={}
    for _,def in pairs(g_gameRules.weaponList) do
        g_gameRules.buyList[def.id]=def;
        if def.weapon==nil then
            def.weapon=true;
        end
    end
    for _,def in pairs(aAmmoList) do
        def.price=0
        DebugLog(def.id)
        g_gameRules.buyList[def.id]=def;
        if def.ammo==nil then
            def.ammo=true;
        end
    end
    for _,def in pairs(g_gameRules.equipList) do
        g_gameRules.buyList[def.id]=def;
        if def.equip==nil then
            def.equip=true;
        end
    end
    for _,def in pairs(g_gameRules.vehicleList) do
        g_gameRules.buyList[def.id]=def;
        if def.vehicle==nil then
            def.vehicle=true;
        end
    end
    for _,def in pairs(g_gameRules.protoList) do
        g_gameRules.buyList[def.id]=def;
        if def.proto==nil then
            def.proto=true;
        end
    end
    g_gameRules.buyList={}--]]

end
--=========================================================
-- Patch Game rules (and flags..)
ClientMod.PatchGameRules = function(self)


    -- =========================================================================================================
    if (IS_PS) then
        g_gameRules.teamRadio=
        {
            black =
            {
                [1]=
                {
                    {"mp_american/us_F5_1_10-4","@mp_radio_Yes",3},
                    {"mp_american/us_F5_2_negative","@mp_radio_No",3},
                    {"mp_american/us_F5_3_wait","@mp_radio_Wait",3},
                    {"mp_american/us_F5_4_follow_me","@mp_radio_FollowMe",3},
                    {"mp_american/us_F5_6_thank_you","@mp_radio_Thanks",3},
                    {"mp_american/us_F5_5_sorry","@mp_radio_Sorry", 3},
                    {"mp_american/us_F5_7_watch_out","@mp_radio_WatchOut", 3},
                    {"mp_american/us_F5_8_well_done","@mp_radio_WellDone", 3},
                    {"mp_american/us_F5_9_hurry_up","@mp_radio_HurryUp", 3},
                },
                [2]=
                {
                    {"mp_american/us_F6_1_attack_enemy_base","@mp_radio_TakeBase"},
                    {"mp_american/us_F6_2_gather_power_cores","@mp_radio_GatherPower"},
                    {"mp_american/us_F6_3_take_prototype_factory","@mp_radio_TakePT"},
                    {"mp_american/us_F6_4_take_war_factory","@mp_radio_TakeWar"},
                    {"mp_american/us_F6_5_take_airfield","@mp_radio_TakeAir"},
                    {"mp_american/us_F6_6_take_bunker","@mp_radio_TakeBunker"},
                    {"mp_american/us_F6_7_take_naval","@mp_radio_TakeNaval"},
                },
                [3]=
                {
                    {"mp_american/us_F7_1_armor_spotted","@mp_radio_ArmorSpotted"},
                    {"mp_american/us_F7_2_aircraft_spotted","@mp_radio_AircraftSpotted"},
                    {"mp_american/us_F7_3_boat_spotted","@mp_radio_BoatSpotted"},
                    {"mp_american/us_F7_4_vehicle_spotted","@mp_radio_LTVSpotted"},
                    {"mp_american/us_F7_5_infantry_spotted","@mp_radio_InfantrySpotted"},
                    {"mp_american/us_F7_6_sniper","@mp_radio_SniperSpotted"},
                },
                [4]=
                {
                    {"mp_american/us_F8_1_request_assistance","@mp_radio_Assistance"},
                    {"mp_american/us_F8_2_get_into_vehicle","@mp_radio_GetIn"},
                    {"mp_american/us_F8_3_get_out_vehicle","@mp_radio_GetOut"},
                    {"mp_american/us_F8_4_mechanical_assistance_needed","@mp_radio_MechAssistance"},
                    {"mp_american/us_F8_5_radar_scan","@mp_radio_Radar"},
                    {"mp_american/us_F5_10_request_pickup","@mp_radio_Pickup", 3},
                },
            },
            tan =
            {
                [1]=
                {
                    {"mp_korean/nk_F5_1_10-4","@mp_radio_Yes",3},
                    {"mp_korean/nk_F5_2_negative","@mp_radio_No",3},
                    {"mp_korean/nk_F5_3_wait","@mp_radio_Wait",3},
                    {"mp_korean/nk_F5_4_follow_me","@mp_radio_FollowMe",3},
                    {"mp_korean/nk_F5_6_thank_you","@mp_radio_Thanks",3},
                    {"mp_korean/nk_F5_5_sorry","@mp_radio_Sorry", 3},
                    {"mp_korean/nk_F5_7_watch_out","@mp_radio_WatchOut", 3},
                    {"mp_korean/nk_F5_8_well_done","@mp_radio_WellDone", 3},
                    {"mp_korean/nk_F5_9_hurry_up","mp_radio_HurryUp", 3},
                },
                [2]=
                {
                    {"mp_korean/nk_F6_1_attack_enemy_base","@mp_radio_TakeBase"},
                    {"mp_korean/nk_F6_2_gather_power_cores","@mp_radio_GatherPower"},
                    {"mp_korean/nk_F6_3_take_prototype_factory","@mp_radio_TakePT"},
                    {"mp_korean/nk_F6_4_take_war_factory","@mp_radio_TakeWar"},
                    {"mp_korean/nk_F6_5_take_airfield","@mp_radio_TakeAir"},
                    {"mp_korean/nk_F6_6_take_bunker","@mp_radio_TakeBunker"},
                    {"mp_korean/nk_F6_7_take_naval","@mp_radio_TakeNaval"},
                },
                [3]=
                {
                    {"mp_korean/nk_F7_1_armor_spotted","@mp_radio_ArmorSpotted"},
                    {"mp_korean/nk_F7_2_aircraft_spotted","@mp_radio_AircraftSpotted"},
                    {"mp_korean/nk_F7_3_boat_spotted","@mp_radio_BoatSpotted"},
                    {"mp_korean/nk_F7_4_vehicle_spotted","@mp_radio_LTVSpotted"},
                    {"mp_korean/nk_F7_5_infantry_spotted","@mp_radio_InfantrySpotted"},
                    {"mp_korean/nk_F7_6_sniper","@mp_radio_SniperSpotted"},
                },
                [4]=
                {
                    {"mp_korean/nk_F8_1_request_assistance","@mp_radio_Assistance"},
                    {"mp_korean/nk_F8_2_get_into_vehicle","@mp_radio_GetIn"},
                    {"mp_korean/nk_F8_3_get_out_vehicle","@mp_radio_GetOut"},
                    {"mp_korean/nk_F8_4_mechanical_assistance_needed","@mp_radio_MechAssistance"},
                    {"mp_korean/nk_F8_5_radar_scan","@mp_radio_Radar"},
                    {"mp_korean/nk_F5_10_request_pickup","@mp_radio_Pickup", 3},
                },
            }
        };
    end

    -- =========================================================================================================
    self:Inject({
        Class    = "g_gameRules",
        Target   = {"Client.InGame.OnKill"},
        Function = function(this, playerId, shooterId, weapon, dmg, material, tpe)
            tpe = this.game:GetHitType(tpe) or ""

            local mat = this.game:GetHitMaterialName(material) or ""
            local headshot = mat:find("head")
            local melee = tpe:find("melee")
            local player = playerId and System.GetEntity(playerId)

            if(playerId == self.id) then
                HUD.ShowDeathFX(headshot and 2 or melee and 3 or 5)
            end
            g_Client:OnKill(player,shooterId,melee,headshot,tpe)
        end
    })


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

    --- MATH ---
    math.frandom=function(x,y)return x+math.random()*((y or 1)-x)end

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
    table.append=function(t,a)local n={} for _,v in pairs(t) do table.insert(n,v) end for _,v in pairs(a) do table.insert(n,v) end return n  end

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
    vector.gawker=function(center,num,rad)local p={}for i=0,360,360/(num or 10)do local x,y,z=center.x+math.sin(math.rad(i))*rad,center.y+math.cos(math.rad(i))*rad,center.z local d={x=center.x-x,y=center.y-y,z=center.z-z}p[#p+1]={pos={x=x,y=y,z=z},dir=d}end return p end
    vector.distance=function(a,b)local dx=b.x-a.x local dy=b.y-a.y local dz=b.z-a.z return math.sqrt(dx * dx + dy * dy + dz * dz)end
    vector.scale=function(a,b)return{x=a.x*b,y=a.y*b,z=a.z*b}end
    vector.getang = function(v1, v2) local iX, iY, iZ = v1.x - v2.x, v1.y - v2.y, v1.z - v2.z local iDist = math.sqrt(iX * iX + iY * iY + iZ * iZ) return {x = math.atan2(iZ, iDist), y = 0, z = math.atan2(-iX, iY)} end
    vector.toang=function(v) return{
        x = math.deg(math.atan2(v.z, math.sqrt(v.x * v.x + v.y * v.y))),
        y = 0,
        z = math.deg(math.atan2(-v.x, v.y))
    }  end

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
        CM_FROG, CM_ALIENWORK, CM_BUTTERFLY, CM_BOOBS, CM_HEADLESS =
        0, 1, 2, 3, 4, 5, 6, 7,
        8, 9, 10, 11, 12, 13, 14, 15,
        16, 17, 18, 19, 20, 21, 22, 23,
        24, 25, 26, 27, 28, 29, 30, 31,
        32, 33, 34, 35, 36, 37, 38, 39,
        40, 41, 42, 43, 1000


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

                if (hClient.CM.ID == CM_BUTTERFLY) then
                    sAnim = "fly_loop"
                    if (iClientSpeed < 0.1) then
                        sAnim = "landing"
                    end
                    return true, sAnim, iSpeed, iTime

                elseif (hClient.CM.ID == CM_FROG) then
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