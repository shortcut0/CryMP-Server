ServerItemSystem = {

    DataDirAmmo = (SERVER_DIR_INTERNAL .. "ServerItems\\Ammo"),
    DataDirType = (SERVER_DIR_INTERNAL .. "ServerItems\\Definitions"),
    UpdateTimer = timernew(0),

    RegisteredProjectiles = {},
    RegisteredClassTypes  = {},
    RegisteredAmmoClasses = {},
    RegisteredItemClasses = {},
    SpawnedProjectiles    = {}
}

--------------------
eProjectileEvent_OnTimeout = 0

eItemEvent_OnShoot = 0

eItemType_Ammo = 0
eItemType_Item = 1

--------------------
ServerItemSystem.Init = function(self)

    -- =========================================

    CollisionParams = function(a, b, c, d)
        return {
            IgnoreCollision   = a or false,  -- Will ignore collisions of this type
            IgnoreImmortality = b or false,  -- Will overwrite immortality setting
            MinimumImpact     = c or nil,    -- an impact with less than this amount of force is ignored
            NoExplosion       = d or false,  -- no effect/explosion will be spawned upton triggering this event
        }
    end

    AmmoParticleParams = function(a, b, c)
        return {
            Name  = a or "",  -- Name of the effect to attach
            Scale = b or 1.0, -- Scale of the effect
            Pulse = c or 0,   -- Pulse period of the effect
        }
    end

    AmmoSoundParams = function(a, b)
        return {
            Name   = a or "",  -- Name of the sound to attach
            Volume = b or 1.0, -- Volume
        }
    end

    -- =========================================


    --LinkEvent(eServerEvent_ScriptUpdate, "ServerItemSystem.OnUpdate")
    self:LoadDirectory(self.DataDirType) -- before ammo classes!
    self:LoadDirectory(self.DataDirAmmo)
end

--------------------
ServerItemSystem.CheckHit = function(self, hItem, aHitInfo)


    local aProjectile = self.SpawnedProjectiles[hItem.id]
    if (aProjectile) then
        aProjectile:OnHit(aHitInfo)
    end
end

--------------------
ServerItemSystem.CheckCollision = function(self, hEntity, hTarget, aInfo)

    local aProjectile = self.SpawnedProjectiles[hEntity.id]
    if (aProjectile and hEntity ~= hTarget) then

        if (hTarget) then

            local iDistance = vector.distance(aInfo.pos, hTarget:GetPos())
            if (hTarget.id == aProjectile:GetOwnerID() and iDistance > 1) then
                return-- Debug("too far? ",vector.distance(aInfo.pos, hTarget:GetPos()),hTarget:GetName(),aInfo.radius)
            end
        end

        local iType = "Default"
        if (aInfo.target_type == 0) then
            iType = "Ground"
        elseif (hTarget) then
            iType = hTarget.class
        end

        --if (aProjectile:GetCollisionTolerance()) then
        --end
        --Debug(aInfo)

        aProjectile:Destroy(iType, {
            Pos = aInfo.pos or aProjectile:GetPos(),
            Dir = aInfo.dir or aInfo.normal or aProjectile:GetDir(),
            Normal = aInfo.normal,
        }, aInfo)
        -- Debug("collison with",g_ts(hTarget:GetName()))
    end
    --  aInfo.target=nil
    --ServerLog(table.tostring(aInfo))
end

--------------------
ServerItemSystem.OnShoot = function(self, hShooter, hWeapon, vPos, vDir, vHit)

    if (hWeapon) then
    end
end

--------------------
ServerItemSystem.SpawnProjectile = function(self, aParams, iSeq)

    local sID   = (aParams.Name or aParams.ID)
    local aInfo = self:GetAmmoInfo(sID)
    if (aInfo == nil) then
        return
    end

    local aPelletInfo = aInfo.Pellets
    if (aPelletInfo.Count > 1) then
        if ((iSeq or 1) < aPelletInfo.Count) then
            local aNewParams = new(aParams)

            local iRandomness = aPelletInfo.RandomDir
            aNewParams.Dir.x = aNewParams.Dir.x + (math.frandom(-iRandomness.x, iRandomness.x))
            aNewParams.Dir.y = aNewParams.Dir.y + (math.frandom(-iRandomness.y, iRandomness.y))
            aNewParams.Dir.z = aNewParams.Dir.z + (math.frandom(-iRandomness.z, iRandomness.z))
            Script.SetTimer(0 + (aPelletInfo.Delay or 0), function()
                self:SpawnProjectile(aNewParams, (iSeq or 1) + 1)
            end)
            Debug("new pellet..",(iSeq or 1)+1)
        end
    end

    local vPos = aParams.Pos
    local vDir = aParams.Dir

    --Debug(vPos, vDir)
    --SpawnEffect(ePE_Flare,vPos)

    local aEntityProps    = aInfo.Entity
    local aParticleProps  = aEntityProps.Particle

    local sModel    = aEntityProps.Model
    local sSvModel  = aEntityProps.Model
    if (aEntityProps.ClientOnlyModel) then
        sSvModel    = "objects/weapons/us/frag_grenade/frag_grenade_tp.cgf"
    end

    local fMass     = aEntityProps.Mass
    local fScale    = aEntityProps.Scale
    local sSound    = aEntityProps.Sound.Name
    local fSoundVol = aEntityProps.Sound.Volume
    local bIsStatic = (fMass == -1 or (aEntityProps.Static or aEntityProps.Physics == false))

    local bUsable   = aEntityProps.IsUsable
    local bPickable = aEntityProps.Pickable

    local sEffect = aParticleProps.Name
    local sEffectProps = string.format("%s,%d,%d", sEffect, (aParticleProps.Scale or 1), (aParticleProps.Pulse or 0))
    if (string.empty(sEffect)) then
        sEffectProps = ""
    end

    local vSpawnDir = vector.copy(vDir)
    local vSpawnAng = vector.toang(vDir)
    local vOffset = aEntityProps.Offset
    if (vOffset) then
        vSpawnAng.x=vSpawnAng.x+vOffset.x---1.5675
        vSpawnAng.y=vSpawnAng.y+vOffset.y
        vSpawnAng.z=vSpawnAng.z+vOffset.z
    end


    local hProjectile = SpawnGUI({

        Model       = sModel,
        ServerModel = sSvModel,

        Physics = true,
        Static  = bIsStatic,

        Mass  = fMass,
        Scale = fScale,

        Pos = vPos,
        Dir = nil, --vSpawnDir,
        Ang = vSpawnAng,

        Sound   = sSound,
        Effect  = sEffectProps,

        Usable   = bUsable,
        Pickable = bPickable,

        Network = true,
    })

    hProjectile.SvIgnoreRWI = true
    hProjectile.SvReportCollisions = true
    hProjectile.SvOnCollision = function(this, hTarget, aCollisionInfo)
        ServerItemSystem:CheckCollision(this, hTarget, aCollisionInfo)
    end

    local hOwner   = aParams.Owner
    local hOwnerID = hOwner and hOwner.id
    local hWeapon  = (aParams.Weapon or hOwner)
    local hWeaponID = hWeapon and hWeapon.id

    -- not needed atm, not very useful RIGHT NOW! <== Now used again!
    CryAction.ActivateExtensionForGameObject(hProjectile.id, "ScriptControlledPhysics", true)

    --Debug(aInfo.Class)
    local aProjectile = self:GetClassTypeInfo(aInfo.Class)

    aProjectile:Init(hProjectile, new(aInfo), aParams)
    aProjectile:SetOwner(hOwner)
    aProjectile:SetOwnerID(hOwnerID)
    aProjectile:SetWeapon(hWeapon)
    aProjectile:SetWeaponID(hWeaponID)

   -- Debug(aInfo.Entity.DeathEffect)
    --[[
    local vOffset = aEntityProps.Offset or vector.make()
    vSpawnDir.x = ((vDir.x < 0 and -1 or 1) * vOffset.x)
    vSpawnDir.y = ((vDir.y < 0 and -1 or 1) * vOffset.y)
    vSpawnDir.z = ((vDir.z < 0 and -1 or 1) * vOffset.z)
    hProjectile:SetAngles(vector.toang(vSpawnDir))]]

   -- local ang=vector.toang({x=vDir.x,y=vDir.y+0,z=vDir.z+0})
   -- ang.x=ang.x+-1.5675
   -- hProjectile.scp:RotateToAngles(ang, 0, 99, 99, 1);
  --  hProjectile.scp:MoveTo(vPos, 99, 99, 99, 1);

    --Debug(":§")
    self.SpawnedProjectiles[hProjectile.id] = aProjectile
    return aProjectile
end

--------------------
ServerItemSystem.Unregister = function(self, sID)
    self.SpawnedProjectiles[sID] = nil
end

--------------------
ServerItemSystem.GetAmmoInfo = function(self, sID)
    return self.RegisteredAmmoClasses[sID]
end

--------------------
ServerItemSystem.GetClassTypeInfo = function(self, sID)

    local hProjectile = self.RegisteredClassTypes[sID]
    return new(hProjectile)
end

--------------------
ServerItemSystem.OnUpdate = function(self)

    if (not self.UpdateTimer.expired()) then
        return
    end

    for _, hProjectile in pairs(self.SpawnedProjectiles) do
        if (GetEntity(_)) then
            hProjectile:Update()
        else
            self:Unregister(_)
        end
    end

    self.UpdateTimer.refresh()
end

--------------------
ServerItemSystem.CreateClassType = function(self, aParams)
    local sID = aParams.ID
    self.RegisteredClassTypes[sID] = aParams
end

--------------------
ServerItemSystem.GetRegisteredAmmoClasses = function(self)
    return self.RegisteredAmmoClasses
end

--------------------
ServerItemSystem.GetRegisteredItemClasses = function(self)
    return self.RegisteredItemClasses
end

--------------------
ServerItemSystem.OnEvent = function(self, iEvent, hItem, hPlayer, hArgs)

    local sID = (hItem.CrazyItem)
    if (not sID) then
        return
    end

    local aInfo = (self.RegisteredItemClasses[sID] or self.RegisteredAmmoClasses[sID])
    if (not aInfo) then
        return
    end

    local hFunc
    if (iEvent == eItemEvent_OnShoot) then
        hFunc = aInfo.Listeners.OnShoot

    else
        HandleError("implementation missing for event")
    end

    if (hFunc) then
        hFunc(hItem, hPlayer, unpack(hArgs))
    end
end

--------------------
ServerItemSystem.CreateItemClass = function(self, aParams)

    local aProperties = table.deepMerge(aParams.Empty and {} or {

        Name = "Default",
        ID   = "Default",

        Listeners = {
            OnShoot     = nil, -- todo
            OnSelect    = nil, -- todo
            OnDrop      = nil, -- todo
            OnReload    = nil, -- todo
        }
    }, aParams, true)

    aProperties.Type = eItemType_Item
    self.RegisteredItemClasses[aProperties.ID] = aProperties
end

--------------------
ServerItemSystem.CreateAmmoClass = function(self, aParams)

    local aProperties = table.deepMerge(aParams.Empty and {} or {

        Class = "SProjectile",
        ID = "Default",

        Pellets = {
            Count  = 1,
            Delay  = 0,
            RandomDir = {
                x = 0.1,
                y = 0.1,
                z = 0.1
            }
        },

        Entity = {

            Model = "Objects/weapons/us/frag_grenade/frag_grenade_tp.cgf",
            Mass  = 10,
            Scale = 1.0,

            Physics = true,
            Static  = false,

            IsUsable = false,
            Pickable = false,

            Sound = {
                Name = "sounds/physics:bullet_whiz:missile_whiz_loop",
                Volume = nil, -- Unused
            },

            Particle = {

                Name    = "smoke_and_fire.weapon_stinger.FFAR",
                Scale   = 1.0,
                Pulse   = 0,
            },

            Health = {

                Immortal     = false,
                MaxHitPoints = 100,

                Lifetime     = 25000,

                DeathEffect  = {

                    UseNormal = true, -- Uses collision-normal direction

                    Effects     = {
                        Default = { "explosions.rocket.generic", },
                        Water   = { "explosions.rocket.water" },
                        Ground  = nil,
                        Grunt   = nil, -- can set properties for specific entities!
                    },

                    Sounds = {
                        Default = { "Sounds/physics:explosions:missile_helicopter_explosion" },
                        Water   = { "sounds/physics:explosions:water_explosion_medium", }
                    },

                    Scale = 1,

                    Explosion = {

                        Radius = 12,    -- 0 Radius means no explosion!
                        Damage = 250,   -- damage
                    }
                }
            }
        },

        Movement = {

            InitialImpulse = 0,

            Following = {

                OwnerDir    = false, -- Follows owner direction
                OwnerLookAt = false, -- Follows lookat position

                Locking     = false, -- Locks to entities

            },

            MaxSpeed = 100,  -- Maximum allowed speed
            MinSpeed = 0,    -- Minimum allowed speed

            Speed    = 5,    -- Speed Multiplier (what is 1?)

            UpdateInfo = {

                MaxUpdates = -1,     -- Maximum updates

                InitialDelay = 0, -- Delay after triggering first update
                Delay = 100,        -- Delay between updates
            }
        },

        Behavior = {

            Immortal     = true, -- If this projectile is immortal to collisions
            ImmortalTime = 0.2,     -- Time after which immortality will be disabled

            MinimumImpact = 0, -- Minimum impact required to trigger events

            Collisions = {

                Water   = CollisionParams(false, false, nil),
                Default = CollisionParams(false, false, nil),
                Timeout = CollisionParams(false, false, nil),
            },
        },

        Callbacks = {
            OnHit           = function(this, hShooter, aHitInfo) end,
            OnDeath         = function(this, aLastHit) end,                     -- Timeout, Destroyed by hits, etc
            OnCollision     = function(this, hContact, vPos, vDir, vNormal) end,
            OnSpawn         = function(this, aSpawnParams) end,
            OnBeforeSpawn   = function(this, aSpawnParams) end,
        }

    }, aParams, true)


    --Debug(aProperties)
    aProperties.Type = eItemType_Ammo
    self.RegisteredAmmoClasses[aProperties.ID] = aProperties
end

--------------------
ServerItemSystem.LoadDirectory = function(self, sDir)

    --sDir = (sDir or self.DataDirAmmo)
    if (not sDir) then
        return
    end

    local aFiles = ServerLFS.DirGetFiles(sDir, GETFILES_ALL, ".*\.lua$")
    if (table.empty(aFiles)) then
        return
    end

    for _, sFile in pairs(aFiles) do

        if (ServerLFS.DirIsDir(sFile)) then
            self:LoadItems(sFile)

        else
            local bOk, sError = FileLoader:LoadFile(sFile, eFileType_Other)
            if (not bOk) then
                HandleError("Failed to load item definition %s (%s)", FileGetNameEx(sFile), (sError or "<null>"))
            end
        end
    end
end




-- ================================================ OLD SYSTEM =====================================================
-- ================================================ OLD SYSTEM =====================================================
-- ================================================ OLD SYSTEM =====================================================
-- ================================================ OLD SYSTEM =====================================================
-- ================================================ OLD SYSTEM =====================================================
-- ================================================ OLD SYSTEM =====================================================
-- ================================================ OLD SYSTEM =====================================================
-- ================================================ OLD SYSTEM =====================================================
-- ================================================ OLD SYSTEM =====================================================
-- ================================================ OLD SYSTEM =====================================================
-- ================================================ OLD SYSTEM =====================================================
-- ================================================ OLD SYSTEM =====================================================
-- ================================================ OLD SYSTEM =====================================================
-- ================================================ OLD SYSTEM =====================================================
-- ================================================ OLD SYSTEM =====================================================
-- ================================================ OLD SYSTEM =====================================================
-- ================================================ OLD SYSTEM =====================================================
-- ================================================ OLD SYSTEM =====================================================
-- ================================================ OLD SYSTEM =====================================================
-- ================================================ OLD SYSTEM =====================================================
-- ================================================ OLD SYSTEM =====================================================
-- ================================================ OLD SYSTEM =====================================================
-- ================================================ OLD SYSTEM =====================================================
-- ================================================ OLD SYSTEM =====================================================
-- ================================================ OLD SYSTEM =====================================================
-- ================================================ OLD SYSTEM =====================================================
do return end