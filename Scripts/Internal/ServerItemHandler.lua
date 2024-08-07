----------------------
ServerItemHandler = {}

----------------------

eKillType_Unknown   = 0
eKillType_Suicide   = 1
eKillType_Team      = 2
eKillType_Enemy     = 3
eKillType_Bot       = 4
eKillType_BotDeath  = 5

----------------------
ServerItemHandler.Init = function(self)

end

----------------------
ServerItemHandler.CheckHit = function(self, aHitInfo)
    return true
end

----------------------
ServerItemHandler.OnShoot = function(self, hShooter, hWeapon, vHit, vPos, vDir)

    -- TODO: Anticheat
    -- Check()

    local aShotInfo = {

        -- New Style
        Shooter = hShooter,
        Weapon  = hWeapon,
        Hit     = vHit,
        Pos     = vPos,
        Dir     = vDir,

        -- Old Style (get rid of this)
        shooter = hShooter,
        weapon  = hWeapon,
        hit     = vHit,
        pos     = vPos,
        dir     = vDir
    }

    if (not g_gameRules:OnShoot(aShotInfo)) then
        return false
    end

    if (CallEvent(eServerEvent_OnShoot, aShotInfo) == false) then
        return false
    end

    return true
end