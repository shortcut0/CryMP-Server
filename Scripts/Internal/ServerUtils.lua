----------------
ServerUtils = (ServerUtils or {
    ActiveCounters = {}
})

----------------

ePE_Light		= "explosions.light.portable_light"
ePE_Flare		= "explosions.flare.a"
ePE_FlareNight	= "explosions.flare.night_time"
ePE_Firework	= "misc.extremly_important_fx.celebrate"
ePE_C4Explosive = "explosions.C4_explosion.ship_door"
ePE_Claymore	= "explosions.mine.claymore"
ePE_AlienBeam	= "alien_weapons.singularity.Tank_Singularity_Spinup"
ePE_BarrelExplo	= "explosions.barrel.explode"

----------------

ALL_ENTITIES = {}
ALL_ITEMS    = {}

----------------

ENTITY_CLASS_ALL     = 0
ENTITY_CLASS_PLAYER  = "Player"
ENTITY_CLASS_ALIEN   = "Alien"

----------------

eFollow_Terrain = 0
eFollow_Water   = 1
eFollow_Auto    = 2

eFacing_Front = 0
eFacing_Left  = 1
eFacing_Right = 2
eFacing_Back  = 3

----------------

TEAM_NEUTRAL = 0
TEAM_US      = 2
TEAM_NK      = 1
TEAM_END     = 3

----------------

eCounter_Generic        = 0
eCounter_Spawned        = 1
eCounter_RPC            = 2
eCounter_ClientMod      = 3
eCounter_ClientModSync  = 4

----------------

SPAWN_COUNTER = (SPAWN_COUNTER or 0)

----------------
ServerUtils.Init = function(self)


    ------------
    self:InitEntityClasses()

    FormatTOD   = self.FormatTOD

    --for i = 0, 24 do
    --    ServerLog(FormatTOD(i + (math.random(0, 60)/100)))
    --end

    ListToConsole = self.ListToConsole
    UpdateCounter = self.Counter

    IsPointIndoors = System.IsPointIndoors
    IsPointUnderwater = self.IsPointUnderwater
    IsPointUnderground = self.IsPointUnderground

    --- Players
    GetPlayers   = self.GetPlayers
    GetPlayer    = self.GetPlayer

    --- Sounds
    PlaySound    = self.PlaySound

    --- Effects
    SpawnEffect    = self.SpawnEffect
    SpawnEffectT   = self.SpawnEffectT
    SpawnExplosion = self.SpawnExplosion

    --- Entities
    SpawnGUI          = self.SpawnGUI

    GetVehicleClasses = self.GetVehicleClasses
    GetEntityClasses  = self.GetEntityClasses
    GetItemClasses    = self.GetItemClasses
    IsEntityClass     = function(s, l) return table.it(l or GetEntityClasses(), function(x, i, v) return (x or string.lower(v) == string.lower(s))  end)  end
    IsItemClass       = function(s, l) return table.it(l or GetItemClasses(),   function(x, i, v) return (x or v == s)  end)  end

    AwakeEntity     = self.AwakeEntity

    GetEntities     = self.GetEntities
    GetEntity       = self.GetEntity
    GetEntityN      = self.GetEntityName
    DeleteEntity    = System.RemoveEntity
    RemoveEntity    = System.RemoveEntity
    SpawnEntity     = function(...) UpdateCounter(eCounter_Spawned) return System.SpawnEntity(...) end
    SvSpawnEntity   = self.SvSpawnEntity
    IsEntity        = self.IsEntity

    --- Game
    GetTeamName     = self.GetTeamName
    GetOtherTeam    = self.GetOtherTeam
    FindTeam        = self.FindTeam

    --- Utils
    ByteSuffix   = self.ByteSuffix

    --- Stuff.. :3

    AutoFollow    = self.AutoFollow
    FollowWater   = self.FollowWater
    FollowTerrain = self.FollowTerrain
    GetFacingPos  = self.GetFacingPos

    local iMaxInt = 1
    while (not string.find(g_ts(iMaxInt),"e")) do
        --ServerLog(g_ts(iMaxInt))
        iMaxInt = (iMaxInt * 10)
    end
    LUA_MAX_INTEGER = (iMaxInt / 10)
    ServerLog("LUA_MAX_INTEGER = %s", g_ts(LUA_MAX_INTEGER))
end

----------------

ServerUtils.IsEntityUnderwater = function(hEntity, iThreshold)
    return IsPointUnderwater(hEntity:GetPos(), iThreshold)
end

----------------

ServerUtils.IsEntityUnderground = function(hEntity, iThreshold)
    return IsPointUnderground(hEntity:GetPos(), iThreshold)
end

----------------

ServerUtils.EntityName = function(hID, hDefault)
    local hEntity = GetEntity(hID)
    if (hEntity) then
        return (hEntity:GetName() or hDefault)
    end
    return (hDefault or "")
end

----------------

ServerUtils.AddImpulse = function(hEntity, vDir, iStrength, iPlayerStrength)

    if (not hEntity) then
        return
    end

    local bClient = false
    local hClient = hEntity
    if (hEntity.vehicle) then
        hClient = hEntity:GetDriver()
    end

    if (hClient and hClient.IsPlayer) then
        hClient:Execute(string.format([[local g=g_localActor;g:AddImpulse(-1,g:GetCenterOfMassPos(),{x=%f,y=%f,z=%f},%f,1)]],
            vDir.x, vDir.y, vDir.z,
            math.min(99999, iPlayerStrength or iStrength) -- low mass objects (like players) cannot take such huge impulses
        )) bClient = true
    end

    if (not bClient) then
        hEntity:AddImpulse(-1, hEntity:GetCenterOfMassPos(), vDir, iStrength, 1)
        Debug("impulse")
    end

end

----------------

ServerUtils.PlaySound = function(aParams)

    --Debug(aParams.File)
    local hFile = SpawnGUI({
        Model = "",
        Mass = -1,
        Physics = 0,
        Rigid = 0,
        Sound = aParams.File,
        Pos = aParams.Pos,
        Dir = aParams.Dir,
        Network = true
    })

    g_pGame:ScheduleEntityRemoval(hFile.id, 30, true)
    return hFile

end

----------------

ServerUtils.SpawnGUI = function(aParams)

    local sName = "gui_" .. UpdateCounter(eCounter_Spawned)

    sName = string.format("%s,Model={%s}",   sName, aParams.Model or "")--, aParams.ModelSlot2 or "")
    sName = string.format("%s,Resting={%d}", sName, (aParams.Resting == true and 1 or 0))
    sName = string.format("%s,Physics={%d}", sName, (aParams.Physics == true and 1 or 0))
    sName = string.format("%s,Rigid={%d}",   sName, ((aParams.Rigid == false or aParams.Static == true) and 0 or 1))
    sName = string.format("%s,Mass={%d}",    sName, (aParams.Mass or 0))
    sName = string.format("%s,Pick={%d}",    sName, (aParams.Pickable and 1 or 0))
    sName = string.format("%s,Use={%d}",     sName, (aParams.Usable and 1 or 0))
    sName = string.format("%s,Scale={%f}",   sName, (aParams.Scale or 1))
    sName = string.format("%s,Sound={%s}",   sName, (aParams.Sound or ""))
    sName = string.format("%s,PProps={%s}",  sName, (aParams.Effect or ""))
    sName = string.format("%s,UseM={%s}",     sName, (aParams.Usability or ""))

   -- ServerLog(sName)
    -- name = "xyz,Model={file.cfg}Physics={1},Mass={69},Rigid={1},Resting={0}"
    local hGUI = System.SpawnEntity({
        class = "GUI",
        name = sName,
        properties = {
            ServerModel = aParams.ServerModel
        },
        position = aParams.Pos,
        orientation = aParams.Dir,
        fMass = (aParams.Mass or 0)
    })


    if (aParams.Dir) then
        hGUI:SetAngles(vector.toang(aParams.Dir))
    end
    hGUI:SetPhysicParams(PHYSICPARAM_SIMULATION, { mass = (aParams.Mass or 0), density = nil })
    --SpawnEffect(ePE_Light,aParams.Pos)

    hGUI.HitConfig = aParams.HitCfg

    if (aParams.Network) then
        CryAction.CreateGameObjectForEntity(hGUI.id)
        CryAction.BindGameObjectToNetwork(hGUI.id)
        if (CryAction.IsServer()) then
            CryAction.ForceGameObjectUpdate(hGUI.id, true)
        end
    end

    return hGUI
end

----------------

ServerUtils.FormatTOD = function(iTime, sAM, sPM)

    local iHours = math.floor(iTime)
    local iMinutes = math.max(0, math.min(1, g_tn("0." ..
            (string.match(iTime, "%.(%d+)$") or 0)
    ))) * 60

    local suffix = (sAM or "AM")
    if (iHours == 12) then
        suffix = (sPM or "PM")
    elseif (iHours > 12) then
        iHours = iHours - 12
        suffix = (sPM or "PM")
    end

    return string.format("%02d:%02d %s", iHours, iMinutes, suffix)
end

----------------

ServerUtils.AwakeEntity = function(hEntityID)

    local hEntity = GetEntity(hEntityID)
    if (hEntity) then
        hEntity:AwakePhysics(1)
        hEntity:AddImpulse(-1, hEntity:GetPos(), vectors.up, 1, 1)
    end
end

----------------

ServerUtils.GetItemClasses = function(bSpawnable)
    local aClasses = ServerDLL.GetItemClasses()
    if (not bSpawnable) then
        return aClasses
    end

    local aSpawn = {
        "AACannon",
        "AARocketLauncher",
        "AIFlashbangs",
        "AIGrenades",
        "AISmokeGrenades",
        "APCCannon",
        "APCCannon_AscMod",
        "APCRocketLauncher",
        "AVMine",
        "AlienCloak",
        "AlienCore",
        "AlienMount",
        "AlienPowerCore",
        "AlienTurret",
        "Asian50Cal",
        "AsianCoaxialGun",
        "AssaultScope",
        "AutoAA",
        "AutoTurret",
        "AutoTurretAA",
        "AvengerCannon",
        "Binoculars",
        "BunkerBuster",
        "C4",
        "Claymore",
        --"CustomAmmoPickup",
        --"CustomAmmoPickupLarge",
        --"CustomAmmoPickupMedium",
        --"CustomAmmoPickupSmall",
        "DSG1",
        "DebugGun",
        "Detonator",
        "DualSOCOM",
        "EMPGrenade",
        "Exocet",
        "FY71",
        "FY71IncendiaryAmmo",
        "FY71NormalAmmo",
        "FastLightMOAC",
        "FastLightMOAR",
        "Fists",
        "FlashbangGrenade",
        "FragGrenade",
        "GaussAAA",
        "GaussCannon",
        "GaussRifle",
        "Golfclub",
        "GrenadeLauncher",
        "GrenadeShell",
        "HeavyMOAC",
        "Hellfire",
        "HovercraftGun",
        "HunterSweepMOAR",
        "Hurricane",
        "LAM",
        "LAMFlashLight",
        "LAMRifle",
        "LAMRifleFlashLight",
        "LAW",
        "LAWScope",
        "LightMOAC",
        "LockpickKit",
        "MOAC",
        "MOACAttach",
        "MOAR",
        "MOARAttach",
        "MissilePlatform",
        "NanoSuit",
        "NightVision",
        "OffHand",
        "OffhandFlashbang",
        "OffhandGrenade",
        "OffhandNanoDisruptor",
        "OffhandSmoke",
        "Parachute",
        "RadarKit",
        "RefWeapon",
        "Reflex",
        "RepairKit",
        "SCAR",
        "SCARIncendiaryAmmo",
        "SCARNormalAmmo",
        "SCARTagAmmo",
        "SCARTutorial",
        "SMG",
        "SOCOM",
        "SOCOMSilencer",
        "ScoutMOAC",
        "ScoutSearchBeam",
        "ScoutSingularity",
        "Scout_MOAR",
        "ShiTen",
        "Shotgun",
        "SideWinder",
        "SideWinder_AscMod",
        "Silencer",
        "SingularityCannon",
        "SingularityCannonWarrior",
        "SmokeGrenade",
        "SniperScope",
        "TACCannon",
        "TACGun",
        "TACGun_Fleet",
        "TacticalAttachment",
        "TankCannon",
        "USCoaxialGun",
        "USCoaxialGun_VTOL",
        "USTankCannon",
        "VehicleGaussMounted",
        "VehicleMOAC",
        "VehicleMOACAttach",
        "VehicleMOACMounted",
        "VehicleMOAR",
        "VehicleMOARAttach",
        "VehicleMOARMounted",
        "VehicleRocketLauncher",
        "VehicleShiTenV2",
        "VehicleSingularity",
        "VehicleUSMachinegun",
        "WarriorMOARTurret"
    }


    return aSpawn
end

----------------

ServerUtils.GetVehiclePaints = function(sClass)
    local aPaintJobs = {
        ["Civ_car1"] = { "black", "blue", "green", "police", "red", "silver", "utility" }
    }
    return aPaintJobs[sClass]
end

----------------

ServerUtils.GetVehicleClasses = function()
    return ServerDLL.GetVehicleClasses()
end

----------------

ServerUtils.GetEntityClasses = function(bSpawnable)
    local aClasses = ServerDLL.GetEntityClasses()
    if (not bSpawnable) then
        return aClasses
    end

    local aSpawn = {
        "APCCannon",
        "APCRocketLauncher", "AVMine", "AdvancedDoor",
        "Alien", "AlienCloak", "AlienCore", "AlienEnergyPoint",
        "AlienMount", "AlienPlayer", "AlienPowerCore", "AlienTurret",
        "Alien_warrior", "AmbientVolume", "AnimDoor", "AnimObject",
        "AreaBox", "AreaRiver", "AreaRoad",
        "AreaShape", "AreaSphere", "AreaTrigger", "Asian50Cal",
        "AsianCoaxialGun", "Asian_aaa", "Asian_apc", "Asian_helicopter",
        "Asian_ltv", "Asian_patrolboat", "Asian_tank", "Asian_truck",
        "AssaultScope", "AutoAA", "AutoTurret", "AutoTurretAA",
        "AvengerCannon", "BasicEntity", "BattleEvent", "Binoculars",
        "Birds", "Boid", "BreakableObject", "Bugs",
        "BunkerBuster", "BuyZone", "C4", "CameraShake",
        "CameraSource", "CameraTarget",  "Chickens",
        "CinematicTrigger", "Civ_car1", "Civ_speedboat", "Civilian",
        "Claymore", "CloneFactory", "Cloth", "Cloud",
        "Comment", "Constraint", "Crabs", "CustomAmmoPickup",
        "DSG1",
        "DeadBody", "DebugGun",
        "DefaultVehicle", "DelayTrigger", "DestroyableObject", "Detonator",
        "Dialog", "Door", "DualSOCOM", "EMPGrenade",
        "Elevator", "ElevatorSwitch", "Exocet", "Explosion",
        "ExplosiveObject", "FY71", "Factory", "Fan",
        "FastLightMOAC", "FastLightMOAR",
        "Fish", "Fists", "Flag", "Flash",
        "FlashbangAI", "FlashbangGrenade", "Fog", "FogVolume",
        "ForbiddenArea", "FragGrenade", "Frogs", "GUI",
        "GaussAAA", "GaussCannon", "GaussRifle", "GeomEntity",
        "Golfclub", "GravityBox", "GravitySphere", "GravityStream",
        "GrenadeLauncher", "GrenadeShell",
        "Grunt", "HQ", "Hazard", "HeavyMOAC",
        "Hellfire", "HovercraftGun", "Hunter", "Hurricane",
        "IndirectLight", "InteractiveEntity",
        "LAM", "LAMFlashLight", "LAMRifle", "LAMRifleFlashLight",
        "LAW", "LAWScope", "Ladder", "Light",
        "LightMOAC", "Lightning", "LockpickKit", "MGbullet",
        "MOAC", "MOACAttach", "MOAR", "MOARAttach",
        "Mine", "MissilePlatform",
        "NightVision", "Objective",
        "Parachute",
        "ParticleEffect", "Player",
        "Plover",
        "PressurizedObject", "ProximityTrigger", "RadarKit", "RaisingWater",
        "RandomSoundVolume", "RefWeapon", "Reflex", "RepairKit",
        "ReverbVolume", "RigidBody", "RigidBodyEx", "Rope",
        "RopeEntity", "SCAR", "SCARTagAmmo", "SCARTutorial", "SMG", "SOCOM",
        "SOCOMSilencer", "Scout", "Shake", "Shark",
        "ShiTen", "ShootingTarget", "Shotgun", "SideWinder",
        "SideWinder_AscMod", "Silencer", "SimpleIndirectLight", "SimpleLight",
        "SinglePlayer", "SingularityCannon", "SmartObject",
        "SmokeGrenade", "SniperScope", "SoundEventSpot",
        "SoundMoodVolume", "SoundSpot", "SoundSupressor", "SpawnAlien",
        "SpawnCivilian", "SpawnCoordinator", "SpawnGroup", "SpawnGrunt",
        "SpawnHunter", "SpawnObserver", "SpawnPoint", "SpawnScout",
        "SpawnTrooper", "SpectatorPoint", "Switch", "TACCannon",
        "TACGun", "TACGun_Fleet", "TacticalAttachment", "TagPoint",
        "TankCannon", "TeamSoundSpot", "Tornado", "Trooper", "Turtles",
        "USCoaxialGun", "USCoaxialGun_VTOL", "USTankCannon", "US_apc",
        "US_hovercraft", "US_ltv", "US_smallboat", "US_tank",
        "US_transportVTOL", "US_trolley", "US_vtol", "VehicleGaussMounted",
        "VehicleMOAC", "VehicleMOACAttach", "VehicleMOACMounted", "VehicleMOAR",
        "VehicleMOARAttach", "VehicleMOARMounted", "VehiclePartDetached",
        "VehicleShiTenV2", "VehicleSingularity", "VehicleUSMachinegun",
        "VolumeObject", "Warrior", "WarriorMOARTurret",
        "WaterKillEvent", "Wind", "WindArea",
        "a2ahomingmissile", "a2ghomingmissile", "acmo",
        "alienmount_acmo", "avexplosive", "bullet", "bunkerbuster",
        "c4explosive", "claymoreexplosive", "dumbaamissile", "empgrenade",
        "exocetmissile", "explosivegrenade", "explosivegrenadeAI", "flashbang",
        "fybullet", "gaussbullet", "gausstankbullet", "heavyacmo",
        "helicoptermissile", "homingmissile", "homingmoac",
        "incendiarybullet", "lightacmo", "lightbullet", "rock",
        "rocket", "rubberbullet", "scargrenade", "smgbullet",
        "sniperbullet", "tacbullet", "tank125", "tank30",
        "tankaa", "towmissile", "turret_rocket", "turretacmo",
        "vtol20", "vtolbullet"
    }


    -- FIXME: automate
    for i, sClass in pairs(aClasses) do

    end

    return aSpawn
end

----------------

ServerUtils.ListToConsole = function(aParams)


    local sLine     = ""
    local iCurrent  = 0
    local iBoxWidth = (aParams.BoxWidth or CLIENT_CONSOLE_LEN )

    local hPlayer = aParams.Client
    local aList   = aParams.List
    local sTitle  = aParams.Title
    local iItems  = (aParams.PerLine or 5)
    local sIndex  = aParams.Index
    local iWidth  = (aParams.ItemWidth or (iBoxWidth / iItems))
    local bValue  = (aParams.Value or false)
    local bPIndex = aParams.PrintIndex

    SendMsg(MSG_CONSOLE, hPlayer, string.format("$9%s", string.rep("=", iBoxWidth)))
    SendMsg(MSG_CONSOLE, hPlayer, string.format("$9[ %s ]", string.mspace(("$4" .. sTitle .. "$9"), (iBoxWidth - 4), nil, string.COLOR_CODE)))

    local iTotal    = table.count(aList)

    local sItem
    for i, v in pairs(aList) do
        iCurrent = (iCurrent + 1)

        sItem = i
        if (sIndex) then
            sItem = v[sIndex]
        elseif (bValue) then
            sItem = v
        end

        sLine = sLine .. "$1(" .. string.lspace((bPIndex and g_ts(i) or iCurrent), string.len(iTotal)) .. ". $9" .. string.rspace(sItem, iWidth) .. "$1)" .. (iCurrent == iTotal and "" or " ")
        if (iCurrent % iItems == 0 or iCurrent == iTotal) then
            SendMsg(MSG_CONSOLE, hPlayer, "$9[ " .. string.mspace(string.rspace(string.ridtrail(sLine, "%s", 1), (iBoxWidth - 4), string.COLOR_CODE), iBoxWidth - 4, nil, string.COLOR_CODE)  .. " $9]")
            sLine = ""
        else

        end
    end
    SendMsg(MSG_CONSOLE, hPlayer, string.format("$9%s", string.rep("=", iBoxWidth)))
end

----------------

ServerUtils.GetFacingPos = function(hEntityID, iFace, iDistance, iFollowType, iFollowMax, iFollowMin)

    iDistance = (iDistance or 1.5)

    local hEntity = GetEntity(hEntityID)
    local vPos    = hEntity:GetPos()
    -- fixme
    --[[
    if (vPos.z < 0) then vPos.z = 0 end
    if (vPos.y < 0) then vPos.y = 0 end
    if (vPos.x < 0) then vPos.x = 0 end
    if (vPos.z > 10000) then vPos.z = 10000 end
    if (vPos.y > 10000) then vPos.y = 10000 end
    if (vPos.x > 10000) then vPos.x = 10000 end

    if (iDistance == 0) then iDistance = 1 end
]]
    local vDir    = hEntity:GetDirectionVector(1)
    if (hEntity.IsPlayer) then
        vDir = hEntity:SmartGetDir(1)
        Debug(Vec2Str(vDir))
    end

    if (iFace == eFacing_Front) then
        vDir = vector.scaleInPlace(vDir, iDistance)

    elseif (iFace == eFacing_Left) then
        vDir = vector.left(vDir)
        vDir = vector.scaleInPlace(vDir, iDistance)

    elseif (iFace == eFacing_Right) then
        vDir = vector.right(vDir)
        vDir = vector.scaleInPlace(vDir, iDistance)

    elseif (iFace == eFacing_Back) then
        vDir = vector.scaleInPlace(vDir, -iDistance)

    elseif (vector.isvector(iFace)) then

        vDir = vector.scaleInPlace(iFace, iDistance)

    end


    ServerLog("pos before%s",Vec2Str(vPos))
    vector.fastsum(vPos, vPos, vDir)
    ServerLog("%s",Vec2Str(vPos))

    local iFollowed
    local iGround = System.GetTerrainElevation(vPos)
    local iWater  = CryAction.GetWaterInfo(vPos)
    local iDiff
    if (iFollowType == eFollow_Terrain) then
        if (iGround) then
            iDiff = (iGround - vPos.z)
           -- Debug("tdiff",iDiff,iFollowMax,iFollowMin)
            if ((iFollowMax == nil or iDiff < iFollowMax) and (iFollowMin == nil or iDiff > iFollowMin)) then
                vPos.z = iGround
               -- Debug(">>now",Vec2Str(vPos))
                iFollowed = eFollow_Terrain
            end
        end

    elseif (iFollowType == eFollow_Water) then
        if (iWater) then
            iDiff = (iWater - vPos.z)
            if (iFollowMax == nil or iDiff < iFollowMax and (iFollowMin == nil or iDiff > iFollowMin)) then
                vPos.z = iWater
                iFollowed = eFollow_Water
            end
        end

    elseif (iFollowType == eFollow_Auto) then
        local iFollow = math.max(iGround or 0, iWater or 0)
        if (iFollow) then
            iDiff = iFollow - vPos.z--math.abs()
           -- Debug("auto",iDiff,"w",iWater,"g",iGround)
            if (iFollowMax == nil or iDiff < iFollowMax and (iFollowMin == nil or iDiff > iFollowMin)) then
                vPos.z = iFollow
                iFollowed = (((iGround or 0) > (iWater or 0)) and eFollow_Terrain or eFollow_Water)
            end
        end

    end
    return vector.modifyz(vPos, 0.15), iFollowed
end

----------------
ServerUtils.GetTeamName = function(iTeam, sNeutral)
    if (iTeam == TEAM_NK) then
        return ("NK")

    elseif (iTeam == TEAM_US) then
        return ("US")

    elseif (iTeam == TEAM_NEUTRAL) then
        return (sNeutral or "Neutral")
    end

    throw_error("INVALID team. learn to code.")
end

----------------
ServerUtils.GetOtherTeam = function(iTeam)
    if (iTeam == TEAM_NK) then
        return TEAM_US

    elseif (iTeam == TEAM_US) then
        return TEAM_NK

    elseif (iTeam == TEAM_NEUTRAL) then
        return TEAM_NEUTRAL -- ???
    end

    throw_error("INVALID team. learn to code.")
end

----------------
ServerUtils.FindItemByClass = function(hClient, sClass)

    local aItems = GetItemClasses(1)
    local iItems = table.size(aItems)
    if (iItems == 0) then
        return nil, hClient:Localize("@l_ui_noItemsFound")
    end

    local aFound
    if (sClass) then
        aFound = table.it(aItems, function(x, i, v)
            local t = x
            local a = string.lower(v)
            local b = string.lower(sClass)
            if (a == b) then
                return { v }, 1
            elseif (string.len(b) > 1 and string.match(a, "^" .. b)) then
                if (t) then
                    table.insert(t, v)
                    return t
                end
                return { v }
            end
            return t
        end)

        if (table.count(aFound) == 0) then aFound = nil end
    end

    if (sClass == nil or (not aFound or table.count(aFound) > 1)) then
        ListToConsole({
            Client      = hClient,
            List        = (aFound or aItems),
            Title       = hClient:Localize("@l_ui_itemList"),
            ItemWidth   = 20,
            PerLine     = 4,
            Value       = 1
        })
        return nil, hClient:Localize("@l_ui_entitiesListedInConsole", { table.count((aFound or aItems)) })
    end

    return aFound[1]
end

----------------
ServerUtils.FindTeam = function(iTeam)

    if (not iTeam) then
        return
    end

    local sTeam = string.lower(iTeam)
    if (iTeam == TEAM_NK or sTeam == "nk") then
        return TEAM_NK

    elseif (iTeam == TEAM_US or sTeam == "us") then
        return TEAM_US

    elseif (iTeam == TEAM_NEUTRAL or sTeam == "none" or sTeam == "neutral") then
        return TEAM_NEUTRAL -- ???
    end

    return
end

----------------
ServerUtils.InitEntityClasses = function(self)

    ALL_ENTITIES = ServerDLL.GetEntityClasses()
    ALL_ITEMS    = ServerDLL.GetItemClasses()

end

----------------
ServerUtils.ByteSuffix = function(iBytes, iZeroCount)

    local aSuffixes = {"B", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"}
    local iSuffixes = table.count(aSuffixes)
    local iCurr = 1

    while (iBytes >= 1024 and iCurr < iSuffixes) do
        iBytes = (iBytes / 1024)
        iCurr = (iCurr + 1)
    end

    return string.format("%." .. (iZeroCount or 2) .. "f%s", iBytes, aSuffixes[iCurr])
end

----------------
ServerUtils.SpawnExplosion = function(sEffect, vPos, iRadius, iDamage, vDir, hShooter, hWeapon, iScale)

    if (not sEffect) then
        return false
    end

    vPos = vPos or vector.make()
    vDir = vDir or vector.make(0, 0, 1)
    iScale  = iScale or 1
    iDamage = iDamage or 0
    iRadius = iRadius or 1
    hShooter = hShooter or NULL_ENTITY
    hWeapon  = hWeapon or hShooter or NULL_ENTITY

    g_gameRules:CreateExplosion(hShooter, hShooter, iDamage, vPos, vDir, iRadius, 45, iRadius, iRadius, sEffect, iScale, iRadius, iRadius/2, iRadius/2)
end

----------------
ServerUtils.SpawnEffect = function(sEffect, vPos, vDir, iScale)
    g_pGame:ServerExplosion(NULL_ENTITY, NULL_ENTITY, 0, (vPos), (vDir or vectors.up), 0, 0, 0, 0, sEffect, (iScale or 1), nil, 0, 0, 0)
end

----------------
ServerUtils.SpawnEffectT = function(sHandle, sEffect, ...)

    if (not sEffect) then
        return
    end

    table.checkM(ServerUtils, "ExplosionCache", {})
    table.checkM(ServerUtils.ExplosionCache, sHandle, {})
    local hLast = ServerUtils.ExplosionCache[sHandle][sEffect]
    if (hLast) then
        if (not hLast.expired()) then
            return
        end
        hLast.refresh()
    else
        ServerUtils.ExplosionCache[sHandle][sEffect] = timernew(0.15)
    end

    SpawnEffect(sEffect, ...)
end

----------------
ServerUtils.GetPlayerByName = function(sName)
    local hPlayer
    for _, hTarget in pairs(GetPlayers()) do
        if (string.lower(hTarget:GetName()) == string.lower(sName)) then
            hPlayer = hTarget
        end
    end
    return hPlayer
end

----------------
ServerUtils.GetPlayer = function(hId, bGreedy, bNoChannel)

    if (isString(hId)) then

        hId = string.escape(hId)

        local aFound = {}
        local aChanFound = {}
        local sId = string.lower(hId)
        local bChan, iChan

        for _, hClient in pairs(GetPlayers()) do
            if (bGreedy) then
                if (string.match(string.lower(hClient:GetName()), sId)) then
                    table.insert(aFound, hClient)
                end
            elseif (string.match(hClient:GetName(), sId)) then
                table.insert(aFound, hClient)
            end

            if (not bNoChannel) then
                iChan = string.match(sId, "^chan(%d+)$")
                if (iChan) then
                    if (hClient:GetChannel() == g_tn(iChan)) then
                        table.insert(aChanFound, hClient)
                    end
                end
            end
        end
        local iResults = table.size(aFound)
        if (table.count(aChanFound) == 1 and (iResults > 1 or iResults == 0)) then
            return aChanFound[1]
        end
        if (iResults > 1) then
            return
        elseif (iResults == 0 and not bGreedy) then
            return GetPlayer(sId, true)
        end
        return aFound[1]
    end

    local hPlayer = GetEntity(hId)
    if (hPlayer) then
        if (not hPlayer.IsPlayer) then
            return
        end
    end

    return
end

----------------
ServerUtils.GetPlayers = function(aParams)

    local aPlayers = g_pGame:GetPlayers()
    if (aParams == 1) then
        return table.count(aPlayers)
    end

    local iParams = table.count(aParams)
    if (iParams > 0 and (aParams.Bots or aParams.NPCs)) then
        aPlayers = table.append(aPlayers, GetEntities("Player", function(a) return (not a.actor:IsPlayer())  end))
    end

    local aResult = {}
    if (table.empty(aPlayers)) then
        return aResult
    end

    local bInsert = true
    for i, hPlayer in pairs(aPlayers) do

        bInsert = true
        if (hPlayer.actor:IsPlayer() and not hPlayer.InfoInitialized) then
            bInsert = false
        end

        if (bInsert and table.size(aParams) > 0) then
            if (aParams.Access) then
                if (not hPlayer:HasAccess(aParams.Access)) then
                    bInsert = false
                end
            end

            if (aParams.Alive) then
                if (not hPlayer:IsAlive()) then
                    bInsert = false
                end
            end

            if (aParams.Dead) then
                if (not hPlayer:IsDead()) then
                    bInsert = false
                end
            end

            if (aParams.Spectators) then
                if (not hPlayer:IsSpectating()) then
                    bInsert = false
                end
            end

            if (aParams.TeamID) then
                if (hPlayer:GetTeam() ~= aParams.TeamID) then
                    bInsert = false
                end
            end

            if (aParams.NotTeamID) then
                if (hPlayer:GetTeam() == aParams.NotTeamID) then
                    bInsert = false
                end
            end

            if (aParams.NotID) then
                if (hPlayer.id == aParams.NotID) then
                    bInsert = false
                end
            end

            if (aParams.ThisID) then
                if (hPlayer.id ~= aParams.ThisID) then
                    bInsert = false
                end
            end

            if (aParams.Force and hPlayer.id == aParams.Force) then
                bInsert = true
            end
        end

        if (bInsert) then
            table.insert(aResult, hPlayer)
        end
    end

    return aResult
end

----------------
ServerUtils.IsEntity = function(hId)

    -- It's null!
    if (hId == nil) then
        return false
    end

    -- It's a userdata, easy!
    if (isUserdata(hId)) then
        return true
    end

    -- It's an array, check .id
    if (isArray(hId)) then
        return (hId.id ~= nil and GetEntity(hId.id))
    end

    -- Not an entity
    return false
end

----------------
ServerUtils.GetEntities = function(sClass, fPred)

    local aColl = {}
    if (isArray(sClass)) then
        for _, s in pairs(sClass) do
            table.append(aColl, System.GetEntitiesByClass(s))
        end
    else
        if (aColl == ENTITY_CLASS_ALL) then
            aColl = System.GetEntities()
        else
            aColl = System.GetEntitiesByClass(sClass)
        end
    end

    if (fPred ~= nil) then
        return table.iselect(aColl, fPred)
    end

    return aColl
end

----------------
ServerUtils.GetEntity = function(hId)

    -- It's null!
    if (hId == nil) then
        return
    end

    -- It's a userdata, simple!
    if (isUserdata(hId)) then
        return System.GetEntity(hId)
    end

    -- It's already an entity?
    if (isArray(hId)) then
        if (hId.id) then
            return System.GetEntity(hId.id)
        end
        return
    end

    -- Try by name
    if (isString(hId)) then
        return System.GetEntityByName(hId)
    end

    -- Exhaused
    return
end

----------------
ServerUtils.GetEntityName = function(hId)
    local hEntity = GetEntity(hId)
    if (not hEntity) then
        return
    end
    return hEntity:GetName()
end

----------------
ServerUtils.SpawnEntity = function(aParams)
    if (aParams.class == "Civ_car1") then
        aParams.properties = aParams.properties or {}
        if (aParams.properties.Paint == nil) then
            local aPaints = {
                "brown","green","blue","black","silver"
            }
            aParams.properties.Paint = sPaint
        end
    end
end

----------------
ServerUtils.SvSpawnEntity = function(aParams)

    local sClass = aParams.Class
    local iCount = (aParams.Count or 1)

    local aTagList  = aParams.Tags
    local fMass     = aParams.Mass
    local hFlags    = aParams.Flags
    local sName     = (aParams.Name or "entity-")

    local bPermanent    = aParams.IsPermanent
    local iRemovalTimer = (aParams.RemovalTimer or 120)

    local vSpawn = aParams.Pos
    local vDir   = aParams.Dir
    local aProperties = {
        name        = sName,
        class       = sClass,
        position    = vSpawn,
        orientation = vDir,
        fMass       = (fMass),
        flags       = hFlags,
        properties  = table.merge(aParams.Properties or {}, {})
    }

    if (IsItemClass(sClass)) then
        aProperties.properties.fMass    = 10
        aProperties.properties.bPhysics = 1
    end

    -- Vehicles ?
    aProperties.properties.Respawn  = (aProperties.properties.Respawn or {
        nTimer = g_gameRules.WEAPON_ABANDONED_TIME,
        bUnique = 0,
        bRespawn = (aParams.Respawn and 1 or 0),
    })

    local hLastSpawned
    local aEquip = aParams.Equipment
    local hItem

    -- FIXME:
    -- TEMPORARY
    local iZAdd = 0
    if (aProperties.class == "US_vtol") then
        iZAdd = iZAdd + 5.5
    end

    -- Apply timer by default because of Vehicles
    --Script.SetTimer(1, function()
        for i = 1, iCount do

            if (not aParams.FixedName) then
                aProperties.name = (sName .. UpdateCounter(eCounter_Spawned, 1))
            end

            vSpawn = vector.modifyz(vSpawn, iZAdd)
            aProperties.position = vSpawn

            local hEntity = SpawnEntity(aProperties)

            if (hEntity) then

                hEntity.ServerSpawned = true

                iZAdd = math.positive(vector.length(hEntity:GetLocalBBox()))
                if (aTagList) then
                    table.it(aTagList, function(x, i, v) hEntity[i] = v  end)
                end

                if (hEntity.actor) then
                    for _, sItem in pairs(aEquip or{}) do
                        hItem = ItemSystem.GiveItem(hEntity, sItem, true)
                        if (hItem) then
                            hItem.weapon:AttachAccessory("LAMRifle", true, true)
                        end
                    end
                end

                if (not bPermanent) then
                    if (hEntity.vehicle) then
                        hEntity.vehicle:StartAbandonTimer(true, iRemovalTimer) -- we dont want bad admins trashing the map with useless vehicles..
                    else
                        if (hEntity.weapon) then
                            g_pGame:ScheduleEntityRemoval(hEntity.id, hEntity.Properties.Respawn.nTimer, false) -- or weapons..
                        else
                            g_pGame:ScheduleEntityRemoval(hEntity.id, iRemovalTimer, false) -- or random entities..
                        end
                    end

                    hEntity.REMOVAL_TIMER = timernew(iRemovalTimer)
                end

                AwakeEntity(hEntity)
                hLastSpawned = hEntity
            else
                HandleError("Failed to Spawn Entity of Class " .. sClass)
            end
        end
  --  end)

    return hLastSpawned
end

----------------
ServerUtils.IsPointUnderwater = function(vPoint, iThreshold)

    local iWaterInfo = CryAction.GetWaterInfo(vPoint)
    if (iWaterInfo) then
        local iDiff = iWaterInfo - vPoint.z
        return (iDiff > (iThreshold or 0))
    end

    return false
end

----------------
ServerUtils.IsPointUnderground = function(vPoint, iThreshold)

    local iTerrain = System.GetTerrainElevation(vPoint)
    if (iTerrain) then
        local iDiff = iTerrain - vPoint.z
        --Debug(iDiff, iThreshold)
        return (iDiff > (iThreshold or 0))
    end

    return false
end

----------------
ServerUtils.FollowTerrain = function(vPoint)

    local iTerrain = System.GetTerrainElevation(vPoint)
    if (iTerrain) then
        vPoint.z = iTerrain
    end

    return vPoint
end

----------------
ServerUtils.FollowWater = function(vPoint)

    local iTerrain = CryAction.GetWaterInfo(vPoint)
    if (iTerrain) then
        vPoint.z = iTerrain
    end

    return vPoint
end

----------------
ServerUtils.AutoFollow = function(vPoint, iThreshold, hElse)

    local iWater = CryAction.GetWaterInfo(vPoint)
    local iTerrain = System.GetTerrainElevation(vPoint)

    local z = math.max(iWater, iTerrain)
    if (math.positive(vPoint.z - z) < (iThreshold or 2)) then
        vPoint.z = z
    end

    return hElse or vPoint
end

----------------
ServerUtils.GetEntitiesInFront = function(hEntityID, iType, iDistance, iRadius)

    local hEntity = GetEntity(hEntityID)
    if (not hEntity) then
        Debug("no input entity.")
        return
    end

    iDistance     = iDistance or 5
    iRadius       = iRadius or 3

    local vDir   = hEntity:GetDirectionVector()
    local vStart = hEntity:GetPos()

    vector.add(vStart, vector.scaleInPlace(vDir, iDistance))

    local aCollected = {}
    if (iType == eGet_Physicalized) then
        aCollected = table.it(System.GetPhysicalEntitiesInBox(vStart, iRadius) or {}, function(x, i, v)
            x = x or {}
            if (v.GetMass and v:GetMass() >= 80) then
                table.insert(x, v)
            end
            return x
        end)
    else
        aCollected = System.GetEntitiesInSphere(vStart, iRadius)
    end

    table.removeValue((aCollected or {}), function(k,v) Debug(v.id,hEntity.id)return (v.id == hEntity.id)  end)

    local sFirstClass
    local iCount = table.count(aCollected)
    if (iCount >= 1) then
        sFirstClass = aCollected[1].class
    end

    local aInfo = {
        Indoors     = (not IsPointUnderground(vStart, 1) and System.IsPointIndoors(vStart)),
        Underwater  = IsPointUnderwater(vStart),
        Underground = IsPointUnderground(vStart),

        Count       = iCount,
        Entities    = aCollected,
        First       = sFirstClass,

        None        = function() return (iCount == 0)  end,
        Any         = function() return (iCount >= 1)  end,
    }

    return aInfo
end


----------------
ServerUtils.Counter = function(hID, bRead)
    hID = (hID or eCounter_Generic)

    ServerUtils.ActiveCounters[hID] = (ServerUtils.ActiveCounters[hID] or 0) + (bRead and 0 or 1)
    return ServerUtils.ActiveCounters[hID]
end
