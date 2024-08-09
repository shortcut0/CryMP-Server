----------------
ServerUtils = {}

----------------

ePE_Light		= "explosions.light.portable_light"
ePE_Flare		= "explosions.flare.a"
ePE_FlareNight	= "explosions.flare.night_time"
ePE_Firework	= "misc.extremly_important_fx.celebrate"
ePE_C4Explosive = "explosions.C4_explosion.ship_door"
ePE_Claymore	= "explosions.mine.claymore"
ePE_AlienBeam	= "alien_weapons.singularity.Tank_Singularity_Spinup"

----------------

TEAM_NEUTRAL = 0
TEAM_US      = 2
TEAM_NK      = 1
TEAM_END     = 3

----------------
ServerUtils.Init = function(self)


    ------------
    self:InitEntityClasses()

    --- Players
    GetPlayers   = self.GetPlayers
    GetPlayer    = self.GetPlayer

    --- Effects
    SpawnEffect  = self.SpawnEffect

    --- Entities
    GetEntities  = self.GetEntities
    GetEntity    = self.GetEntity
    DeleteEntity = System.RemoveEntity
    RemoveEntity = System.RemoveEntity
    SpawnEntity  = System.SpawnEntity
    IsEntity     = self.IsEntity

    --- Game
    GetTeamName  = self.GetTeamName

    --- Utils
    ByteSuffix   = self.ByteSuffix

    --- Stuff.. :3
    local iMaxInt = 1
    while (not string.find(g_ts(iMaxInt),"e")) do
        ServerLog(g_ts(iMaxInt))
        iMaxInt = (iMaxInt * 10)
    end
    LUA_MAX_INTEGER = (iMaxInt / 10)

    ServerLog("LUA_MAX_INTEGER = %s", g_ts(LUA_MAX_INTEGER))
end

----------------
ServerUtils.GetTeamName = function(iTeam, bLocalize)
    if (iTeam == TEAM_NK) then
        return ("NK")

    elseif (iTeam == TEAM_US) then
        return ("US")

    elseif (iTeam == TEAM_NEUTRAL) then
        return ("Neutral")
    end

    throw_error("INVALID team. learn to code.")
end

----------------
ServerUtils.InitEntityClasses = function(self)

    ENTITY_CLASS_PLAYER = "Player"
    ENTITY_CLASS_ALIEN  = "Alien"
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
ServerUtils.SpawnEffect = function(sEffect, vPos, vDir, iScale)
    g_pGame:ServerExplosion(NULL_ENTITY, NULL_ENTITY, 0, (vPos), (vDir or vectors.up), 0, 0, 0, 0, sEffect, (iScale or 1), nil, 0, 0, 0)
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
    local iParams = table.count(aParams)

    if (iParams > 0 and (aParams.Bots or aParams.NPCs)) then
        aPlayers = table.append(aPlayers, GetEntities("Player", function(a) return (not a.actor:IsPlayer())  end))
    end

    if (table.empty(aPlayers)) then
        return {}
    end

    local aResult = {}
    local bInsert = true

    for i, hPlayer in pairs(aPlayers) do

        bInsert = true
        if (table.size(aParams) > 0) then
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
ServerUtils.SpawnEntity = function(...)
    return LocalSystem.SpawnEntity(...)
end

----------------
ServerUtils.DeleteEntity = function(...)
    return LocalSystem.DeleteEntity(...)
end
