------------------
ServerMapSetup = {

    Entities = {},
    Setups   = {},
    DataDir  = (SERVER_DIR_INTERNAL .. "MapSetups\\")

}

------------------
ServerMapSetup.Init = function(self)

    CreateMapSetup = function(...)
        return self:CreateMapSetup(...)
    end

    self:LoadSetups()
    LinkEvent(eServerEvent_MapReset, "ServerMapSetup", self.OnMapStart)

    Logger:LogEventTo(GetDevs(), eLogEvent_DataLog, "Loaded %d Map Setups", table.count(self.Setups))
end

------------------
ServerMapSetup.CreateMapSetup = function(self, sMap, sRules, aSetup)

    sRules = string.lower(sRules)
    sMap   = string.lower(sMap)

    table.checkM(self.Setups, sRules, {})

    aSetup.Spawn = function(this, aProperties)

        aProperties.Properties.IsServerSpawn = true

        local hSpawned = SvSpawnEntity(aProperties)
        if (hSpawned) then
            hSpawned.MapSetup = true
        end


        -- This isn't optional, maybe it's better to modify SvSpawnEntity
        if (hSpawned.vehicle) then
            hSpawned.vehicle:KillAbandonTimer()
        else
            g_pGame:AbortEntityRemoval(hSpawned.id)
        end

        table.insert(ServerMapSetup.Entities, {
            EntityID = hSpawned.id,
            Vehicle  = (hSpawned.vehicle or hSpawned.weapon)
        })
        return hSpawned
    end

    aSetup.SpawnGUI = function(this, aProperties)
        local hSpawned = SpawnGUI(aProperties)
        if (hSpawned) then
            hSpawned.MapSetup = true
        end

        table.insert(ServerMapSetup.Entities, {
            EntityID = hSpawned.id,
            Vehicle  = false
        })
        return hSpawned
    end
    self.Setups[sRules][sMap] = aSetup
end

------------------
ServerMapSetup.LoadSetups = function(self, sPath)

    local sDir = (sPath or self.DataDir)
    if (not ServerLFS.DirExists(sDir)) then
        return
    end

    local aFolders = ServerLFS.DirGetFiles(sDir, GETFILES_DIR)
    if (table.count(aFolders) > 0) then
        table.it(aFolders, function(x, i, v) self:LoadSetups(v)  end)
    end

    local aFiles = ServerLFS.DirGetFiles(sDir, GETFILES_FILES)
    if (table.count(aFiles) == 0) then
        return
    end

    for _, sFile in pairs(aFiles) do
        if (not FileLoader:LoadFile(sFile)) then
            HandleError(string.format("Failed to load file %s (%s)", ServerLFS.FileGetName(sFile), FileLoader.LAST_ERROR))
        end
    end
end

------------------
ServerMapSetup.GetSetup = function(self, sMap, sRules)

    sRules = string.lower(sRules)
    sMap   = string.lower(sMap)

    local aRules = self.Setups[sRules]
    if (table.empty(aRules)) then
        return
    end

    return aRules[sMap]
end

------------------
ServerMapSetup.CheckEntityNames = function(self)

    local aEntities = table.it(System.GetEntities(), function(x, i, v) x = x or {} x[v.id] = v return x end)
    for _, hEntity in pairs(aEntities) do
        if (hEntity.vehicle) then
            for __, hOtherEntity in pairs(aEntities) do
                if (hEntity.id ~= hOtherEntity.id and hEntity:GetName() == hOtherEntity:GetName()) then

                    -- Respawn this entity!
                    Script.SetTimer(1, function()

                        local aProperties = hEntity.Properties or {}
                        local aPaints = ServerUtils.GetVehiclePaints("Civ_car1")
                        if (aProperties.Paint == nil and table.emptyN(aPaints)) then
                            aProperties.Paint = table.random(aPaints)
                        end
                        System.SpawnEntity({
                            name = (hEntity.class .. "_" .. UpdateCounter(eCounter_Spawned)),
                            class = hEntity.class,
                            position = hEntity:GetWorldPos(),
                            orientation = hEntity:GetDirectionVector(),
                            properties = aProperties,
                        })
                        ServerLog("Respawned non-unique entity %s", hEntity:GetName())
                        System.RemoveEntity(_)
                    end)
                    aEntities[_] = nil
                    break
                end
            end
        end
    end

end

------------------
ServerMapSetup.OnMapStart = function(self)

    for _, hEntity in pairs(System.GetEntities()) do
        if (hEntity.MapSetup or (hEntity.Properties and hEntity.Properties.IsServerSpawn)) then
            --ServerLog("Deleted Old Entity %s", hEntity:GetName())
            System.RemoveEntity(hEntity.id)
        end
    end

    self:CheckEntityNames()

    for _, aInfo in pairs(self.Entities) do
        if (aInfo.Vehicle) then
            g_pGame:AbortEntityRemoval(aInfo.EntityID)
            g_pGame:AbortEntityRespawn(aInfo.EntityID, true)
        end
        System.RemoveEntity(aInfo.EntityID)
    end

    self.Entities = {}

    local sMap, sRules, sType = ServerMaps:GetLevel()
    local aSetup = self:GetSetup(sMap, sRules)
    if (aSetup) then

        if (not aSetup.Active) then
            ServerLog("Map Setup for %s (%s) is disabled", sMap, sRules)
            Logger:LogEventTo(GetDevs(), eLogEvent_Maps, "@l_ui_mapSetupIsDisabled", sMap, sRules)
            return
        end

        ServerLog("Loading MapSetup for Map %s (%s)", sMap, sRules)
        Logger:LogEventTo(GetDevs(), eLogEvent_Maps, "@l_ui_mapSetupLoaded", sMap, sRules)

        if (DebugMode()) then
            aSetup:Init()
        else
            local bOk, sError = pcall(aSetup.Init, aSetup, sMap, sRules)
            if (not bOk) then
                HandleError("Failed to execute map setup (%s)", g_ts(sError))
            end
        end
    else
        Logger:LogEventTo(GetDevs(), eLogEvent_Maps, "@l_ui_noMapSetupFound", sMap, sRules)
    end
end
