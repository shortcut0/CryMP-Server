---------------------------------------------------------
-- CLIENT UNDER CONSTRUCTION.
--
-- COPYRIGHT (D) MARISAAAAAAUH 2006-2069
--
---------------------------------------------------------

--=========================================================
-- Hallo
--=========================================================

ClientMod = {
    version = "0",
    id = g_localActorId,
    ent = g_localActor
}

-- ==================
CPPAPI = CPPAPI or {}
CALLBACK_OK = false

-- ==================
ClientMod.UpdateRate = 1 / 60

-- ==================
ClientMod._G = {}
ClientMod._DEBUG = true

--=========================================================
-- Some Globals
--=========================================================

DEVELOPER_MODE = (g_localActor ~= nil and g_localActor:GetName() == "test_player")

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

--=========================================================
-- Functions

--=========================================================
-- Init
ClientMod.Init = function(self)

    -- es muy importante
    self:InitLibs()
    if (not PAK_LOADED) then

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

    -------
    self:FixClWork()
    self:PatchGameRules()
    self:PatchLocalActor()

    -------
    self.AASearchLasers:Init()

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

    if (CPPAPI.SetCallback) then

        -- cannt overwrite these .. !!
        --CPPAPI.SetCallback(SCRIPT_CALLBACK_ON_UPDATE, function() ClientLog("ticktick") self:Update() end)
        --CPPAPI.SetCallback(SCRIPT_CALLBACK_ON_SPAWN, function(...) self:OnEntitySpawn(...) end)


        if (Updater) then
            Updater:SetCallback(uF)

        elseif (AddHook ~= nil) then
            self:AddHook("OnUpdate", uF)

        else
            bHooked = false
        end
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

    g_aHooks = g_aHooks or {}
--[[
    for _, aInfo in pairs(g_aHooks) do

        -- only 1 per type needed..
        if (aInfo.ID == sID) then
            return
        end
    end]]

    table.insert(g_aHooks, { ID = sID, Function = hFunc, hPtr = AddHook(sID, sID, hFunc) })
end

--=========================================================
-- Events
ClientMod.AddCVars = function(self)

    -- Tests ?
    AddCVar("crymp_test69", "a pointer to 6t9", 69)
    AddCVar("crymp_test69Pointer", "a pointer to 6t9", ClientMod.UpdateRate, "ClientMod.UpdateRate")

    -- Stuff
    AddCVar("crymp_updateRate", "CryMP-Client Mod Update Rate", ClientMod.UpdateRate, "ClientMod.UpdateRate")

    -- Anims
    AddCVar("crymp_animation_handler", "CryMP-Client Mod Animation handler", 1)

    -- Commands
    AddCommand("crymp_loadlocal", "Load local client sources.", [[loadfile("crymp-server\\clientmod\\crymp-client.lua")()]])
    AddCommand("crymp_loadlocalPAK", "Load local client sources.", [[loadfile("crymp-server\\clientmod\\crymp-client\\crymp-client.lua")()]])

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
                        loadstring(sID .. " = " .. pValue)()
                    end
                end
            end
        end

        local sInfo = string.format("%s%s", (sID and ("G:"..sID..",") or ""), aVar._T:upper())
        System.LogAlways(string.format("   $3%s = $6%s $5[%s]", sName, aVar._C, sInfo))
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
ClientMod.Update = function(self)

    -- check the peasants (maybe hook cppapi spawn)
    local aPlayers = System.GetEntitiesByClass("Player")
    for _, hPlayer in pairs(aPlayers) do
        if (not hPlayer.Initialized) then
            hPlayer:ClInit()
        end
    end

    --------------------------------
    --- Limit Update Rate
    if (not timerexpired(self.UpdateTick, self.UpdateRate)) then
        return --ClientLog("%fms next:%f",self.UpdateRate,self.UpdateRate-timerdiff(self.UpdateTick))
    else
        self.UpdateTick = timerinit()
    end

    --------------------------------
    --- UPDATE !!
    self.AASearchLasers:PreUpdateAASearchLaser()
    self.AnimationHandler:Update()

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
ClientMod.PSE = function(self, sound, entity, id, slot, loop, force_restart)

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
            entity:StopSound(hSound)
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
        Target   = "ClInit",
        PatchEntities = true,
        Function = function(self)

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
                    local animation=string.format(self.Properties.animationTemplate, team, action);
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
end

--=========================================================
-- Animation Handler

ClientMod.AnimationHandler = {
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

        -- Client Model IDs
        CLIENT_MODEL_SHARK, CLIENT_MODEL_ALIEN,
        CLIENT_MODEL_ALIENTROOPER, CLIENT_MODEL_ALIENSCOUT,
        CLIENT_MODEL_ALIENWORKER,
        CLIENT_MODEL_CHICKEN, CLIENT_MODEL_TURTLE, CLIENT_MODEL_CRAB, CLIENT_MODEL_FINCH,
        CLIENT_MODEL_HELENA,
        CLIENT_MODEL_TERN, CLIENT_MODEL_FROG,
        CLIENT_MODEL_HEADLESS
        = 31, 28, 33, 30, 35, 34, 36, 37, 38, 17, 39, 40, 999

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
            ClientLog("too early for this sound event")
            return
        end

        Sound.StopSound(hPlayer.aSoundEventSlots[iEvent])
        hPlayer.aSoundEventSlots[iEvent] = hPlayer:PlaySoundEvent(sSound, g_Vectors.v000, g_Vectors.v010, SOUND_EVENT, SOUND_SEMANTIC_SOUNDSPOT)
        Sound.SetSoundVolume(hPlayer.aSoundEventSlots[iEvent], iVolume)
        hPlayer[hTimer] = timerinit()

        ClientLog( "Playing sound %s", sSound)

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

        ClientLog( "aAnims = %s, idAnim = %s, aAnim = %s, aEvents = %s", tostring(aAnims), tostring(idAnim), tostring(aAnim), tostring(aEvents))

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
                if (not hClient or not hClient.CM) then
                    return false
                end

                Msg(3, "hClient.CM=%d",checkNumber(hClient.CM,-1))
                local sMelee, sAnim, sStagger, iSpeed, iTime, iStart
                local iClientSpeed = hClient:GetSpeed()

                aAnimation.AnimatedCharacter = nil
                aAnimation.CharacterOffset = nil
                aAnimation.Events = nil
                aAnimation.SoundEvents = nil
                aAnimation.SoundVolume = nil

                if (hClient.CM == CLIENT_MODEL_FROG) then
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
                elseif (hClient.CM == CLIENT_MODEL_TERN) then
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
                elseif (hClient.CM == CLIENT_MODEL_HELENA and not CLIENT_MOD_ENABLED) then
                    sAnim = "cineFleet_ab1_FlightDeckHelenaIdle_01"
                    return true, sAnim
                elseif (hClient.CM == CLIENT_MODEL_SHARK) then
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
                elseif ((hClient.CM == CLIENT_MODEL_ALIEN or hClient.CM == CLIENT_MODEL_ALIENTROOPER)) then
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
                elseif (hClient.CM == CLIENT_MODEL_CHICKEN) then
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
                elseif (hClient.CM == CLIENT_MODEL_FINCH or hClient.CM == CLIENT_MODEL_TURTLE or hClient.CM == CLIENT_MODEL_CRAB) then
                    sAnim = "idle01"
                    iSpeed = 1
                    if (iClientSpeed > 1) then
                        sAnim = "walk_loop"
                        iSpeed = (hClient.CM == CLIENT_MODEL_FINCH and 1.25 or 4)
                    end
                    return true, sAnim, iSpeed, iTime
                elseif (hClient.CM == CLIENT_MODEL_ALIENWORKER) then

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
                end

                return false
            end
        }, "IDANIM_SHARK_ANIMS")
    end,
    ---------------------------------------------------------
    -- Destructor
    CalculateAnimationSpeedFromVelocity = function(self, iVelocity, iMultiplier, iMinSpeed, iMaxSpeed)

        local iMaxSpeed = checkNumber(iMaxSpeed, 4)
        local iMinSpeed = checkNumber(iMinSpeed, 0.75)

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

                        ClientLog( "Anim Speed: %f", aAnimation.AnimTime)
                        ClientLog( "STarted now %s (next in %fs)", sAnimName, timerdiff(timerinit()+aAnimation.AnimTime)*-1)

                    end
                else

                    self:ProcessAnimationEvents(hPlayer, aAnimation)

                    if (hPlayer.bPlayingAnim) then
                        hPlayer:StopAnimation(0, 8)
                        self:StopAnimation(hPlayer, aAnimation)
                    end
                    --ClientLog( "-> error: %s", sError)
                end
            else
               -- ClientLog( "No updating slot " .. aAnimation.ID)
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
                ClientLog( "Condition return animation name %s", sReturn)
            end
            if (iSpeed) then
                iAnimSpeed = iSpeed
                ClientLog( "Condition return animation speed %f", iSpeed)
            end
            if (iTime) then
                iAnimTime = iTime
                ClientLog( "Condition return animation time %f", iTime)
            end
            if (iStart) then
                iAnimStart = iStart
                ClientLog( "Condition return animation length %f", iStart)
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