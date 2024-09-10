-- ===========================================================
-- Ammo Definitions !

-- =============================
ServerItemSystem:CreateAmmoClass({
    Class = "SProjectile",
    ID = "hellfire",
})

-- =============================
ServerItemSystem:CreateAmmoClass({
    Class = "SProjectile",
    ID = "seamine",

    Entity = {

        Model    = "objects/library/props/watermine/watermine.cgf",
        Particle = AmmoParticleParams(),
        Sound    = AmmoSoundParams(),

        Health = {
            DeathEffect = {

                Effects = {
                    Default = { "explosions.jet_explosion.on_fleet_deck", "explosions.mine_explosion.hunter_reveal", "explosions.mine_explosion.door_explosion", "explosions.harbor_airstirke.airstrike_large", "explosions.harbor_airstirke.airstrike_medium" },
                    Water = { "explosions.mine.seamine" },
                },

                Sounds = {
                    Default = { "Sounds/physics:explosions:sphere_cafe_explo_1", "Sounds/physics:explosions:sphere_cafe_explo_2", "Sounds/physics:explosions:sphere_cafe_explo_3" },
                    Water = { "" }
                }
            }
        }
    },
    Movement = {
        Speed = 0
    },
    Behavior = {
        MinimumImpact = 20,
    }
})

-- =============================
ServerItemSystem:CreateAmmoClass({
    Class = "SProjectile",
    ID = "bomb",

    Entity = {

        Model    = "objects/library/architecture/aircraftcarrier/props/weapons/bomb_big.cgf",
        Particle = AmmoParticleParams(),
        Sound    = AmmoSoundParams(),

        Health = {
            DeathEffect = {

                Effects = {
                    Default = { "explosions.C4_explosion.ship_door", "explosions.C4_explosion.ship_door" },
                    Water = { "explosions.rocket.water" },
                },

                Sounds = {
                    Default = { "sounds/physics:explosions:explo_rocket" },
                    Water = { "sounds/physics:explosions:water_explosion_large" }
                }
            }
        }
    },
    Movement = {
        Speed = 0
    },
    Behavior = {
        MinimumImpact = 20,
    }
})