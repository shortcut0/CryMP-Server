-- ===========================================================
-- Ammo Definitions !

-- =============================
ServerItemSystem:CreateAmmoClass({
    Class = "SProjectile",
    Name  = "Hellfire_Missile",
    ID    = "hellfire",
})

-- =============================
ServerItemSystem:CreateAmmoClass({
    Class = "SProjectile",
    Name  = "Exocet",
    ID    = "exocet",

    Entity = {
        Health = {
            DeathEffect = {
                Effects = {
                    Default = { "explosions.rocket_terrain.exocet" },
                    Water   = { "explosions.rocket.water" }
                },
                Sounds = {
                    Default = {},
                    Water   = { "sounds/physics:explosions:water_explosion_medium" }
                }
            }
        }
    },
    Movement = {
        Speed = 25
    }
})

-- =============================
ServerItemSystem:CreateAmmoClass({
    Class = "SProjectile",
    Name  = "Missile_Platform",
    ID    = "missileplatform",

    Entity = {
        Health = {
            DeathEffect = {
                Effects = {
                    Default = { "explosions.rocket_terrain.explosion" },
                    Water   = { "explosions.rocket.water" }
                },
                Sounds = {
                    Default = {},
                    Water   = { "sounds/physics:explosions:water_explosion_large" }
                }
            }
        }
    },
    Movement = {
        Speed = 25
    }
})

-- =============================
ServerItemSystem:CreateAmmoClass({
    Class = "SProjectile",
    Name  = "Sidewinder",
    ID    = "sidewinder",

    Entity = {
        Health = {
            DeathEffect = {
                Effects = {
                    Default = {"explosions.rocket.concrete", "explosions.rocket.generic"},
                    Water   = { "explosions.rocket.water" }
                },
                Sounds = {
                    Default = { "sounds/physics:explosions:missile_vtol_explosion" },
                    Water   = { "sounds/physics:explosions:water_explosion_large" }
                }
            }
        }
    },
    Movement = {
        Speed = 25
    }
})

-- =============================
ServerItemSystem:CreateAmmoClass({
    Class = "SProjectile",
    Name  = "Singularity",
    ID    = "singularity0",

    Entity = {

        Particle = AmmoParticleParams("alien_weapons.singularity.Hunter_Singularity_Projectile", 1, 1),
        Sound  = AmmoSoundParams("Sounds/weapons:singularity_cannon:sing_cannon_flying_loop", 1),
        Health = {
            DeathEffect = {
                Effects = {
                    Default = { "Alien_Weapons.singularity.Scout_Singularity_Impact" },
                    Water   = { "explosions.rocket.water" }
                },
                Sounds = {
                    Default = { "" },
                    Water   = { "sounds/physics:explosions:water_explosion_large" }
                }
            }
        }
    },
    Movement = {
        Speed = 25
    }
})

-- =============================
ServerItemSystem:CreateAmmoClass({
    Class = "SProjectile",
    Name  = "Tank_Singularity",
    ID    = "singularity1",

    Entity = {

        Particle = AmmoParticleParams("alien_weapons.singularity.Hunter_Singularity_Projectile", 1, 1),
        Sound  = AmmoSoundParams("Sounds/weapons:singularity_cannon:sing_cannon_flying_loop", 1),
        Health = {
            DeathEffect = {
                Effects = {
                    Default = { "Alien_Weapons.singularity.Tank_Singularity_Impact" },
                    Water   = { "explosions.rocket.water" }
                },
                Sounds = {
                    Default = { "" },
                    Water   = { "sounds/physics:explosions:water_explosion_large" }
                }
            }
        }
    },
    Movement = {
        Speed = 25
    }
})

-- =============================
ServerItemSystem:CreateAmmoClass({
    Class = "SProjectile",
    Name  = "Smart_Singularity",
    ID    = "singularity2",

    Entity = {

        Particle = AmmoParticleParams("alien_weapons.singularity.Hunter_Singularity_Projectile", 1, 1),
        Sound  = AmmoSoundParams("Sounds/weapons:singularity_cannon:sing_cannon_flying_loop", 1),
        Health = {
            DeathEffect = {
                Effects = {
                    Default = { "Alien_Weapons.singularity.Tank_Singularity_Impact" },
                    Water   = { "explosions.rocket.water" }
                },
                Sounds = {
                    Default = { "" },
                    Water   = { "sounds/physics:explosions:water_explosion_large" }
                }
            }
        }
    },
    Movement = {
        Speed = 25,
        Following = {
            OwnerLookAt = true
        }
    }
})

-- =============================
ServerItemSystem:CreateAmmoClass({
    Class = "SProjectile",
    Name  = "RPG",
    ID    = "rpg0",

    Entity = {
        Health = {
            DeathEffect = {
                Effects = {
                    Default = { "explosions.rocket.generic", "explosions.rocket.concrete" },
                    Water   = { "explosions.rocket.water" }
                },
                Sounds = {
                    Default = { "sounds/physics:explosions:law_explosion" },
                    Water   = { "sounds/physics:explosions:water_explosion_medium" }
                }
            }
        }
    },
    Movement = {
        Speed = 25,
        Following = {
            OwnerLookAt = true
        }
    }
})

-- =============================
ServerItemSystem:CreateAmmoClass({
    Class = "SProjectile",
    Name  = "APC_Round",
    ID    = "tank30",

    Entity = {
        Sound = AmmoSoundParams(),
        Particle = {
            Name = "smoke_and_fire.Tank_round.apc30",
        },
        Health = {
            DeathEffect = {
                Effects = {
                    Default = { "explosions.tank30.default" },
                    Water   = { "explosions.rocket.water" }
                },
                Sounds = {
                    Default = { "sounds/physics:explosions:large_explosion" },
                    Water   = { "sounds/physics:explosions:water_explosion_medium" }
                },
                Explosion = {
                    Radius = 1,    -- 0 Radius means no explosion!
                    Damage = 50,   -- damage
                }
            },
        }
    },
    Movement = {
        Speed = 150,
    }
})

-- =============================
ServerItemSystem:CreateAmmoClass({
    Class = "SProjectile",
    Name  = "Grenade_Launcher",
    ID    = "gl0",

    Entity = {
        Sound = AmmoSoundParams(),
        Particle = {
            Name = "muzzleflash.LAM.grenade_white",
            Scale = 3
        },
        Health = {
            Lifetime = 5000,
            DeathEffect = {
                Effects = {
                    Default = { "explosions.Grenade_SCAR.backup" },
                    Water   = { "explosions.rocket.water" }
                },
                Sounds = {
                    Default = { "sounds/physics:explosions:grenade_launcher_explosion" },
                    Water   = { "sounds/physics:explosions:water_explosion_medium" }
                },
                Explosion = {
                    Radius = 1.5,    -- 0 Radius means no explosion!
                    Damage = 50,   -- damage
                }
            },
        }
    },
    Movement = {
        InitialImpulse = 200,
        Speed = 0,
    }
})

-- =============================
ServerItemSystem:CreateAmmoClass({
    Class = "SProjectile",
    Name  = "FGL_40",
    ID    = "gl1",

    Entity = {
        Sound = AmmoSoundParams(),
        Particle = {
            Name = "muzzleflash.LAM.grenade_white",
            Scale = 3
        },
        Health = {
            Lifetime = 5000,
            DeathEffect = {
                Effects = {
                    Default = { "explosions.mine.frog_mine" },
                    Water   = { "explosions.rocket.water" }
                },
                Sounds = {
                    Default = { "sounds/physics:explosions:grenade_explosion" },
                    Water   = { "sounds/physics:explosions:water_explosion_small" }
                },
                Explosion = {
                    Radius = 1.5,    -- 0 Radius means no explosion!
                    Damage = 50,   -- damage
                },
                Scale = 0.5
            },
        }
    },
    Movement = {
        InitialImpulse = 200,
        Speed = 0,
    }
})

-- =============================
ServerItemSystem:CreateAmmoClass({
    Class = "SProjectile",
    Name  = "Frag",
    ID    = "grenade",

    Entity = {
        Sound = AmmoSoundParams(),
        Particle = {
            Name = "muzzleflash.LAM.grenade_white",
            Scale = 3
        },
        Health = {
            Lifetime = 5000,
            DeathEffect = {
                Effects = {
                    Default = { "explosions.Grenade_SCAR.concrete" },
                    Water   = { "explosions.Grenade_SCAR.water" }
                },
                Sounds = {
                    Default = { "sounds/physics:explosions:grenade_explosion" },
                    Water   = { "sounds/physics:explosions:water_explosion_small" }
                },
                Explosion = {
                    Radius = 1.5,    -- 0 Radius means no explosion!
                    Damage = 50,   -- damage
                },
                Scale = 0.5
            },
        }
    },
    Movement = {
        InitialImpulse = 200,
        Speed = 0,
    },
    Behavior = {
        Collisions = {
            Water   = CollisionParams(true, nil, nil),
            Default = CollisionParams(true, nil, nil),
            Timeout = CollisionParams(false, false, nil),
        }
    }
})

-- =============================
ServerItemSystem:CreateAmmoClass({
    Class = "SProjectile",
    Name  = "FGL_40b",
    ID    = "gl2",

    Pellets = {
        Count  = 3,
        Delay  = 0,
        RandomDir = {
            x = 0.1,
            y = 0.1,
            z = 0.0
        }
    },

    Entity = {
        Sound = AmmoSoundParams(),
        Particle = {
            Name = "muzzleflash.LAM.grenade_white",
            Scale = 3
        },
        Health = {
            Lifetime = 5000,
            DeathEffect = {
                Effects = {
                    Default = { "explosions.mine.frog_mine" },
                    Water   = { "explosions.rocket.water" }
                },
                Sounds = {
                    Default = { "sounds/physics:explosions:grenade_explosion" },
                    Water   = { "sounds/physics:explosions:water_explosion_small" }
                },
                Explosion = {
                    Radius = 1.5,    -- 0 Radius means no explosion!
                    Damage = 50,   -- damage
                },
                Scale = 0.5
            },
        }
    },
    Movement = {
        InitialImpulse = 500,
        Speed = 0,
    }
})

-- =============================
ServerItemSystem:CreateAmmoClass({
    Class = "SProjectile",
    Name  = "Tank_Round",
    ID    = "tank31",

    Entity = {
        Sound = AmmoSoundParams(),
        Particle = {
            Name = "smoke_and_fire.Tank_round.Trail",
            Scale = 0.5
        },
        Health = {
            DeathEffect = {
                Effects = {
                    Default = { "explosions.rocket.metal" },
                    Water   = { "explosions.rocket.water" }
                },
                Sounds = {
                    Default = { "sounds/physics:explosions:cannon_explosion_big" },
                    Water   = { "sounds/physics:explosions:water_explosion_medium" }
                },
                Explosion = {
                    Radius = 12,    -- 0 Radius means no explosion!
                    Damage = 350,   -- damage
                }
            },
        }
    },
    Movement = {
        Speed = 150,
    }
})

-- =============================
ServerItemSystem:CreateAmmoClass({
    Class = "SProjectile",
    Name  = "Comet",
    ID    = "comet0",

    Entity = {
        Sound = {
            Name = "Sounds/vehicles:trackview_vehicles:jet_constant_run_01_mp_with_fade",
        },
        Model = "Objects/natural/rocks/cliff_rocks/cliff_rock_a_small.cgf",
        Particle = {
            Name = "explosions.jet_explosion.burning",
            Scale = 0.5,
            Pulse = 8,
        },
        Health = {
            DeathEffect = {
                Effects = {
                    Default = { "explosions.jet_explosion.on_fleet_deck", "explosions.mine_explosion.hunter_reveal", "explosions.mine_explosion.door_explosion", "explosions.harbor_airstirke.airstrike_large", "explosions.harbor_airstirke.airstrike_medium"  },
                    Water   = { "explosions.rocket.water" }
                },
                Sounds = {
                    Default = {"Sounds/physics:explosions:sphere_cafe_explo_1", "Sounds/physics:explosions:sphere_cafe_explo_2", "Sounds/physics:explosions:sphere_cafe_explo_3"},
                    Water   = { "sounds/physics:explosions:sphere_cafe_explo_3" }
                },
                Explosion = {
                    Radius = 25,    -- 0 Radius means no explosion!
                    Damage = 1000,   -- damage
                }
            },
        }
    },
    Movement = {
        Speed = 150,
    }
})

-- =============================
ServerItemSystem:CreateAmmoClass({
    Class = "SProjectile",
    Name  = "Smart_Comet",
    ID    = "comet0",

    Entity = {
        Sound = {
            Name = "Sounds/vehicles:trackview_vehicles:jet_constant_run_01_mp_with_fade",
        },
        Model = "Objects/natural/rocks/cliff_rocks/cliff_rock_a_small.cgf",
        ClientOnlyModel = true,
        Particle = {
            Name = "explosions.jet_explosion.burning",
            Scale = 0.5,
            Pulse = 8,
        },
        Health = {
            DeathEffect = {
                Effects = {
                    Default = { "explosions.jet_explosion.on_fleet_deck", "explosions.mine_explosion.hunter_reveal", "explosions.mine_explosion.door_explosion", "explosions.harbor_airstirke.airstrike_large", "explosions.harbor_airstirke.airstrike_medium"  },
                    Water   = { "explosions.rocket.water" }
                },
                Sounds = {
                    Default = {"Sounds/physics:explosions:sphere_cafe_explo_1", "Sounds/physics:explosions:sphere_cafe_explo_2", "Sounds/physics:explosions:sphere_cafe_explo_3"},
                    Water   = { "sounds/physics:explosions:sphere_cafe_explo_3" }
                },
                Explosion = {
                    Radius = 25,    -- 0 Radius means no explosion!
                    Damage = 1000,   -- damage
                }
            },
        }
    },
    Movement = {
        Speed = 150,
        Following = {
            OwnerLookAt = true
        }
    }
})

-- =============================
ServerItemSystem:CreateAmmoClass({
    Class = "SProjectile",
    Name  = "Seamine",
    ID    = "seamine",

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
    Name  = "SeaMine_Missile",
    ID    = "seamine",

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
        Speed = 5
    },
    Behavior = {
        MinimumImpact = 20,
    }
})

-- =============================
ServerItemSystem:CreateAmmoClass({
    Class = "SProjectile",
    Name  = "JetBomb",
    ID    = "bomb",

    Entity = {

        Offset   = { x = 1, y = 0, z = 0 },
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

-- =============================
ServerItemSystem:CreateAmmoClass({
    Class = "SProjectile",
    Name  = "JetBomb_Missile",
    ID    = "bombmissile",

    Entity = {

        Offset   = { x = -1.5675, y = 1, z = 0 },
        Model    = "objects/library/architecture/aircraftcarrier/props/weapons/bomb_big.cgf",
        Particle = {
            Scale = 5
        },
        --Particle = AmmoParticleParams(),
        --Sound    = AmmoSoundParams(),

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
        Speed = 10
    },
    Behavior = {
        MinimumImpact = 20,
    }
})