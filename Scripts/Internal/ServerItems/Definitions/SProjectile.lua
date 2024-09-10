ServerItemSystem:CreateClassType({

    ID = "SProjectile",

    m_info = {

    },

    Init        = function(this, hEntity, aInfo, aSpawnParams)

        --Debug("at init====",aInfo.Entity.DeathEffect)

        local aEntityProps    = aInfo.Entity
        local aParticleProps  = aEntityProps.Particle
        local aHealthProps    = aEntityProps.Health
        local aDeathProps     = aEntityProps.Health.DeathEffect
        local aCollisionProps = aInfo.Behavior
        local aMovementProps  = aInfo.Movement

        local vPos = aSpawnParams.Pos
        local vDir = aSpawnParams.Dir

        local m_info = {

            --- changed later ---
            m_ownerId = hEntity and hEntity.id or NULL_ENTITY,
            m_owner = hEntity,

            m_ownerWeapon = hEntity,
            m_ownerWeaponId = hEntity or NULL_ENTITY,
            m_lastWeaponId = hEntity and hEntity.id or NULL_ENTITY,

            m_pEntityId = hEntity and hEntity.id or NULL_ENTITY,
            m_pEntity = hEntity,

            --- timers ---
            m_spawnTimer = timernew(),
            m_updateTimer = timernew(),
            m_movementTimer = timernew(),

            --- members ---
            m_hp = aHealthProps.MaxHitPoints or 0,
            m_speed = aMovementProps.Speed,
            m_spawnDir = vDir,
            m_spawnPos = vPos,
            m_isImmortal = aCollisionProps.Immortal,
            m_immortalTime = aCollisionProps.ImmortalTime or -1,
            m_lifeTime = aEntityProps.Health.Lifetime,
            m_properties = aInfo,
            m_entityProperties = aEntityProps,
            m_collisionProperties = aCollisionProps,
            m_movementProps = aMovementProps,
            m_deathProps = aDeathProps,
            m_healthProps = aHealthProps,
        }

        this.m_info = m_info
    end,

    SetEntityID = function(this, id) this.m_info.m_pEntityId = id end,
    SetEntity   = function(this, ent) this.m_info.m_pEntity = ent end,
    GetOwnerID  = function(this) return this.m_info.m_ownerId end,
    SetOwnerID  = function(this, id) this.m_info.m_ownerId = id end,
    SetOwner    = function(this, ent) this.m_info.m_owner = ent end,
    SetWeaponID = function(this, id) this.m_info.m_ownerWeaponId = id end,
    SetWeapon   = function(this, ent) this.m_info.m_ownerWeapon = ent end,

    GetEntityID = function(this) return this.m_info.m_pEntityId end,
    GetEntity   = function(this) return this.m_info.m_pEntity end,
    GetPos      = function(this) return this:GetEntity():GetWorldPos() end,
    GetDir      = function(this) return this:GetEntity():GetDirectionVector() end,
    GetVel      = function(this) return this:GetEntity():GetVelocity() end,

    SetSpeed   = function(this) end,

    Delete = function(this, bForce)

        if (bForce or not this.m_info.m_keepProjectile) then
            System.RemoveEntity(this:GetEntityID())
        end
    end,

    OnHit = function(this, aHitInfo)

        local aInfo = this.m_info.m_healthProps
        if (not aInfo.Immortal and not this.m_info.m_isImmortal) then
            local iMax = aInfo.MaxHitPoints
            if (iMax > 0) then
                this.m_info.m_hp = this.m_info.m_hp - aHitInfo.damage
                if (this.m_info.m_hp <= 0) then
                    this:Destroy("Death", {
                        Pos = aHitInfo.pos,
                        Dir = aHitInfo.dir,
                        Normal = aHitInfo.normal
                    })
                end
            end

        end

    end,

    Explode = function(this, iReason, aInfo)

        local vPos = aInfo.Pos
        local vDir = aInfo.Dir
        local vNormal = aInfo.Normal

        local hOwner = this.m_info.m_owner
        local hOwnerID = this.m_info.m_ownerId

        local hWeapon = this.m_info.m_ownerWeapon
        local hWeaponID = this.m_info.m_ownerWeaponId

        local aDeathProps = this.m_info.m_deathProps
        local aExplosionInfo = aDeathProps.Explosion

        local aEffects = aDeathProps.Effects[iReason] or aDeathProps.Effects.Default
        local sEffect = (isArray(aEffects) and table.random(aEffects) or aEffects)

        local iScale = aDeathProps.Scale
        local bNormal = aDeathProps.UseNormal

        local aSounds = aDeathProps.Sounds
        local sSound = aSounds[iReason] or aSounds.Default
        if (isArray(sSound)) then
            sSound = table.random(sSound)
        end

        --Debug("sound=",aDeathProps)

        if (sSound and sSound ~= "") then
            PlaySound({
                Pos = vPos,
                File = sSound,
                Vol = 1
            })
        end

        if (aExplosionInfo.Radius > 0) then

            --(sEffect, vPos, iRadius, iDamage, vDir, hShooter, hWeapon, iScale)
            SpawnExplosion(sEffect, vPos, aExplosionInfo.Radius, aExplosionInfo.Damage, (bNormal and vNormal or vDir), hOwnerID, hWeaponID, iScale)
        else
            SpawnEffect(sEffect, vPos, (bNormal and vNormal or vDir), iScale)
        end

    end,

    Destroy = function(this, iReason, aInfo, aCollisionInfo)

        if (this.m_info.m_destroying) then
            return true
        end

        local aBehavior = this.m_info.m_collisionProperties
        local aCollisionProps = aBehavior.Collisions
        local aProps = (aCollisionProps[iReason or "Default"] or aCollisionProps["Default"])
        if (aProps) then
            if (aProps.IgnoreCollision) then
                return false
            end

            if (this.m_info.m_isImmortal) then
                if (not aProps.IgnoreImmortality) then
                    return false
                end
            end

            if (aCollisionInfo) then
                local fImpact = aCollisionInfo.impulse
                local fMinImpact = aProps.MinimumImpact
                if (fMinImpact == nil) then
                    fMinImpact = aBehavior.MinimumImpact
                end
                --Debug("too small!",fMinImpact)
                --Debug(aCollisionProps)
                if (fMinImpact and fMinImpact > fImpact) then
                    return false
                end
            end

            if (not aProps.NoExplosion) then
                this:Explode(iReason, aInfo)
            end
        else
            if (this.m_info.m_isImmortal) then
                return false
            end
        end

        this.m_info.m_destroying = true
        ServerItemSystem:Unregister(this:GetEntityID())
        this:Delete()

        return true
    end,

    Update = function(this)
        local vPos = this:GetPos()
        local vDir = this:GetVel()

        local iImmortalityTime = this.m_info.m_immortalTime
        if (this.m_info.m_isImmortal and iImmortalityTime > 0) then
            if (this.m_info.m_spawnTimer.expired(iImmortalityTime)) then
                this.m_info.m_isImmortal = false
            end
        end

        if (this:Expired()) then
            if (this:Destroy("Timeout", {
                Pos = vPos,
                Dir = vDir,
                Normal = vector.neg(vDir),
            })) then
                return
            end
        end

        local bUnderwater = IsPointUnderwater(vPos, 1)
        if (bUnderwater) then
            if (this:Destroy("Water", {
                Pos = vPos,
                Dir = vDir,
                Normal = vector.neg(vDir),
            })) then
                return
            end
        end


        if (not this.m_info.m_destroying) then
            this:UpdateMovement()
        end
    end,

    Expired = function(this)
        local iLifeTime = this.m_info.m_lifeTime
        --Debug("expires in",(iLifeTime/1000)-this.m_info.m_spawnTimer.diff())
        return ((iLifeTime == nil or iLifeTime < 0) or this.m_info.m_spawnTimer.expired(iLifeTime/1000))
    end,

    UpdateMovement = function(this)

        local hEntity = this:GetEntity()

        local aProps = this.m_info.m_movementProps
        local hTimer = this.m_info.m_movementTimer

        local iTime  = aProps.UpdateInfo.Delay
        local iTimeInitial = aProps.UpdateInfo.InitialDelay
        if (iTimeInitial and iTimeInitial > 0) then
            if (not hTimer.expired(iTimeInitial / 1000)) then
                return
            end
        end


        local iSpeed = hEntity:GetSpeed()--hEntity.scp:GetSpeed()
        local vVel = hEntity:GetVelocity()
        local fMass = hEntity:GetMass()
        local fSpeed = aProps.Speed
        local vDir = this:GetHeading()

        if (iSpeed > aProps.MaxSpeed) then
            this:Push(vector.neg(vVel), fMass)
            Debug("too fast")
            return
            --elseif (iSpeed < aProps.MinSpeed) then
            -- this:Push(vVel, fMass)
            --  Debug("too slow")
            --  return
        end

        if (iTime > 0) then
            if (not hTimer.expired(iTime / 1000)) then
                return
            end
        end

        if (this.m_info.m_speed > 0) then
            this:Push(vDir,fMass * fSpeed)
           -- this:UpdateDirection(vDir)
            this.m_info.m_lastDir = vDir
        else--if (this:GetEntity():GetSpeed()>10) then
            this:UpdateDirection(this:GetVel(),99)
        end

        hTimer.refresh()
    end,
    UpdateDirection = function(this, vDir, ss)

        local hEntity = this:GetEntity()
        --vDir = this:GetVel()

        local vPos = hEntity:GetPos()
        local iSpeed = ss or this.m_info.m_speed
       -- vector.fastsum(vPos, vPos, vector.scale(vDir, 10000))
        --hEntity.scp:MoveTo(vPos, 10 * iSpeed, 10 * iSpeed, 99, 0)
        --hEntity.scp:RotateToAngles(vector.toang(vDir), 10 * iSpeed, 10 * iSpeed, 99, 0)
       -- this:GetEntity():SetAngles(vector.toang(vDir))
        --this:GetEntity():SetDirectionVector(vDir)
    end,
    Push = function(this, vDir, iStrength)
        --Debug(vDir)
        -- SpawnEffect(ePE_Flare,this:GetPos(),vDir,0.1)
        --this:GetEntity():SetDirectionVector(vDir)
        --this:GetEntity():AddImpulse(-1, this:GetEntity():GetCenterOfMassPos(), vDir, iStrength, -1)

        --vDir = this:GetVel()

        local hEntity = this:GetEntity()

        local vPos = hEntity:GetPos()
        local iSpeed = this.m_info.m_speed
        --if (iSpeed <= 0) then iSpeed = 10 end
        vector.fastsum(vPos, vPos, vector.scale(vDir, 10000))
        hEntity.scp:MoveTo(vPos, 10 * iSpeed, 10 * iSpeed, 99, 0)
        hEntity.scp:RotateToAngles(vector.toang(vDir), 10 * iSpeed, 10 * iSpeed, 99, 0)
        --self.goalAngle, self.scp:GetAngularSpeed(), self.Properties.Rotation.fSpeed, self.Properties.Rotation.fAcceleration, self.Properties.Rotation.fStopTime);
        --(self.goalPos, self:GetSpeed(), self.Properties.Slide.fSpeed, self.Properties.Slide.fAcceleration, self.Properties.Slide.fStopTime);
    end,
    GetHeading = function(this)

        local vDir = this.m_info.m_lastDir or this.m_info.m_spawnDir
        local aProps = this.m_info.m_movementProps.Following

        local hOwner = GetEntity(this.m_info.m_ownerId)
        if (not hOwner) then
            return vDir
        end

        local hWeapon = hOwner.actor and hOwner.inventory:GetCurrentItem()
        if (hWeapon and hWeapon.id ~= this.m_info.m_lastWeaponId) then
            --Debug("suing last dir")
            return vDir
        end

        -- m_lastWeaponId = hWeapon and hWeapon.id

        if (aProps.OwnerDir) then
            vDir = hOwner:GetDirectionVector()
            if (hOwner.IsPlayer) then
                vDir = hOwner:SmartGetDir()
            end
        end

        if (aProps.OwnerLookAt) then
            vDir = hOwner:GetDirectionVector() -- npcs?
            if (hOwner.IsPlayer) then
                local vPoint = hOwner:GetViewPoint() or hOwner:GetFacingPos(eFacing_Front, 9999)
                vDir = vector.getdir(vPoint, this:GetPos(), 1)
            end
        end

        return vDir

    end,
    Template = function(this) end,
    Template = function(this) end,
    Template = function(this) end,
    Template = function(this) end,
    Template = function(this) end,
    Template = function(this) end,
    Template = function(this) end,
    Template = function(this) end,


})