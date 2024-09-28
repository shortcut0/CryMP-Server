-- ========================================
ServerItemSystem:CreateItemClass({
    Name  = "Teleport",
    ID    = "teleport",

    Listeners = {
        OnShoot = function(self, hShooter, vPos, vDir, vHit, hAmmoID, hAmmoClass)
            if (hShooter.IsPlayer) then
                hShooter:SvMoveTo(vHit, vector.toang(vDir))
                SpawnEffect(ePE_AlienBeam, vPos, vDir)
                SpawnEffect(ePE_Light, vHit)
            end
        end
    }
})

-- ========================================
ServerItemSystem:CreateItemClass({
    Name  = "Flare",
    ID    = "flare",

    Listeners = {
        OnShoot = function(self, hShooter, vPos, vDir, vHit, hAmmoID, hAmmoClass)
            SpawnEffect(ePE_Flare, vPos, vDir)
        end
    }
})

-- ========================================
ServerItemSystem:CreateItemClass({
    Name  = "Light_Explosion",
    ID    = "explosion0",

    Listeners = {
        OnShoot = function(self, hShooter, vPos, vDir, vHit, vNormal, hAmmoID, hAmmoClass)
            SpawnExplosion(ePE_Light, vHit, 1, 50, vNormal, (hShooter and hShooter.id), (self and self.id), 1)
        end
    }
})

-- ========================================
ServerItemSystem:CreateItemClass({
    Name  = "Explosion",
    ID    = "explosion1",

    Listeners = {
        OnShoot = function(self, hShooter, vPos, vDir, vHit, vNormal, hAmmoID, hAmmoClass)
            SpawnExplosion(ePE_C4Explosive, vHit, 1, 50, vNormal, (hShooter and hShooter.id), (self and self.id), 1)
            PlaySound({
                Pos = vHit,
                File = eSE_ExplosionMissileLAW2
            })
        end
    }
})