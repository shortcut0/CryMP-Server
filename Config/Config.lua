-----------------------
--- Create a new Config
---
--- Data entries in this file start with their respective variable type (in lower-case only)
--- This however is only optional and it's only purpose is to prevent Script Errors with invalid data types!
---
--- Types:
---  > f, n i = number
---  >      s = string
---  >      b = boolean
---

---------------
ConfigCreate({

    --------------
    Active = true,  -- Active status
    ID = "Main",    -- ID Of the configuration (must be unique)

    FixInvalid = true, -- Automatic Data validation for this Configuration

    ----------------
    --- Server CVars
    CVars = {

        MP_CRYMP          = 0,
        MP_CIRCLEJUMP     = 0.45,
        MP_WALLJUMP       = 1,
        MP_FLYMODE        = 0,
        MP_PICKUPOBJECTS  = 1,
        MP_PICKUPVEHICLES = 1,
        MP_WEAPONSONBACK  = 1,
        MP_THRIDPERSON    = 1,

        MP_UNRESTRICTEDRAGDOOLS   = 1,
        MP_ANIMATIONGRENADESWITCH = 1,

        --
        G_REVIVETIME   = 6,

        G_SUITSPEEDMULTMULTIPLAYER = 1.0,
        G_SUITSPEEDENERGYCONSUMPTIONMULTIPLAYER = 35,

        --
        SERVER_USE_HIT_QUEUE = 0.0,         -- Server Hit Queue (Slow)
        SERVER_USE_EXPLOSION_QUEUE = 1.0,   -- Server Explosion Queue
    },

    -------------------------
    ---> Server Configuration
    Config = {

        --------------------------
        ---> Command Configuration
        Commands = {

            --- Send a Sound feedback to the clients
            SoundFeedback = true,

            --- Create Server Console Command Representation of each Command (server_cmd_*)
            CreateCCommand = true,

            --- Available Prefixes to trigger commands
            CommandPrefixes = {
                "!",
                "\\",
                "/"
            }

        }, ---< Commands

        ------------------
        ---> Server Ranks
        Ranks = {

            --- A list of hard-coded registered users
            UserList = {

                ["1011669"] = {
                    Name          = "Marisa",
                    ProfileID     = "1011669",
                    Rank          = 9,
                    ProtectedName = true,
                    Login         = "1234"
                },

                ["1005711"] = {
                    Name          = "Andrey",
                    ProfileID     = "1005711",
                    Rank          = 6,
                    ProtectedName = true,
                    Login         = "1234"
                }

            }, ---< UserList

            --------------------------
            --- List of Existing Ranks
            --- Cosmetics:
            ---  > Name,     The Short Name of the Rank
            ---  > LongName, The Long Name of the Rank (If null, uses Short Name)
            ---  > Color,    The Color used when displaying this Rank
            RankList = {
            ---   Authority        Global Identifier  Name                  Color                Will be assigned to new players
                { Authority   = 1, ID = "GUEST",      Name = "Guest",       Color = CRY_COLOR_GREEN,    Default = true },
                { Authority   = 2, ID = "PLAYER",     Name = "Player",      Color = CRY_COLOR_WHITE                    },
                { Authority   = 3, ID = "PREMIUM",    Name = "Premium",     Color = CRY_COLOR_BLUE,     Premium = true },
                { Authority   = 4, ID = "MODERATOR",  Name = "Moderator",   Color = CRY_COLOR_ORANGE                   },
                { Authority   = 5, ID = "ADMIN",      Name = "Admin",       Color = CRY_COLOR_RED,      Admin = true   },
                { Authority   = 6, ID = "HEADADMIN",  Name = "HeadAdmin",   Color = CRY_COLOR_RED                      },
                { Authority   = 7, ID = "SUPERADMIN", Name = "SuperAdmin",  Color = CRY_COLOR_WHITE }, -- indicating that this class is a developer class
                { Authority   = 8, ID = "DEVELOPER",  Name = "Developer",   Color = CRY_COLOR_MAGENTA,  Developer = true },
                { Authority   = 9, ID = "OWNER",      Name = "Owner",       Color = CRY_COLOR_MAGENTA,  Developer = true }
            }

        }, ---< Ranks

        --------------------------
        ---> Server Configuration
        Server = {

            --------------------
            -- Punishment Config
            Punishment = {

                -- Ban profile spoofers
                BanInvalidProfile = false, -- sometimes there are false positives or timeouts!

                -- Kick profile spoofers
                KickInvalidProfile = true,

                -- Bind bans to hardware ids of clients
                UseHardwareBans = true,

                -- The maximum amount of time anyone can be banned (in seconds)
                MaximumBanTime = 31536000,

                -- The default ban time if none was specified
                DefaultBanTime = 86400,

                -- The maximum amount of time anyone can be banned (in seconds)
                MaximumMuteTime = 86400,

                -- The default ban time if none was specified
                DefaultMuteTime = 300,

            }, ---< Punishment

            ------------------
            --- Welcome Config
            Welcome = {

                --- The Chat message appearing when a user entered the server
                ChatMessage = "@l_ui_welcomechat",

            }, ---< Welcome

            -- The available languages on this server
            AvailableLanguages = {
                "english",
                "german",
                "spanish",
                "russian",
                "turkish",
                "czech",
            },

            --- The Default Server Language
            Language = "english",

            ----------------------------------
            --- Info sent to the Master Server
            Report = {

                -- Name of the Server Displayed
                Name = "CryMP-Server ${mod_version}",

                -- Time between each Status Report, in Seconds
                UpdateRate = 60.0,

                -- Time after which to send a new report if previous request failed
                ErrorRecovery = 10.0,

                -- The Server Description
                -- Format Variables are
                --  <bold>...</bold>
                --- > {mod_name}        > Server Mod Name
                --- > {mod_version}     > Server Mod Version
                Description = "\tServer Running on {mod_exe} ${mod_version} (x${mod_bits})\nCompiled Using ${mod_compiler}\n\nUp-Time: ${server_uptime}\n\n[debug]: se(${dbg_scripterr})",

            }, ---< Report

            --- Server PAK Url
            PAKUrl = "http://nomad.nullptr.one/~finch/CryMP-Client-v0.pak",

            ----------------------
            --- Map Download Links
            MapLinks = {

                ["Multiplayer/PS/Mesa"] = "http://download.host.net/ps/mesa", -- FIXME

            } ---< MapLinks

        }, ---< Server

        --------------------------
        ---> General Game Settings
        General = {

            ----------------
            --- Item Config
            Weapons = {

                -- Use client side enhanced explosion effects
                CreateExplosionEffects = true,

                -- Use improved weapon effects
                UseWeaponEffects = true,

                -- Use special RPG ground effects
                RPGGroundEffects = true,

                -- Enhance underwater explosions
                EnhanceUWExplosions = true

            }, ---< Weapons

            ----------------
            --- Cheat Config
            AntiCheat = {

                -- TODO -->
                -- Checks client CVars and reports it to server if they are not the appropriate value
                ClientCVars = {

                    R_ATOC  = 0, -- crysis' broken alpha-to-coverage
                },

                -- Testing mode, no punishments will be given!
                TestMode = true,

                -- Timeout for detected cheats
                ActionTimeout = 120,

                -- Required detects to take action against a cheater
                ActionThreshold = {

                    ["Default"]           = 3,
                    ["SvRequestDropItem"] = 3,
                }, ---< ActionThreshold

                -- Actions to be performed once a cheater is being dealt with
                ActionPunishments = {

                    ["SvRequestDropItem"]   = { 0, "21d" },
                    ["SvRequestUseItem"]    = { 1 },
                    ["SvRequestPickupItem"] = { 2 },
                } ---< ActionPunishments

            }, ---< AntiCheat

            -- Disables forbidden areas
            DisableForbiddenAreas = true,

            ------------------------
            ---> Player Data Config
            PlayerData = {

                -- Period after which a players data will be removed if they haven't connected for this long
                DeleteAfter = (ONE_MONTH * 3),

                -- If the server should save/restore player data
                SaveData = true,

            }, ---< PlayerData


            ----------------------
            --- Map Configuration
            MapConfig = {

                -- the default fallback value for time limits
                DefaultTimeLimit = ONE_HOUR, -- One Hour

                -- default limit for PS Games
                DefaultTimeLimit_PS = THREE_HOURS, -- One Hour

                -- default limit for IA Games
                DefaultTimeLimit_IA = ONE_HOUR, -- One Hour

                -- A list of forbidden maps
                ForbiddenMaps = {
                    -- "multiplayer/ps/mesa"
                },

                -- Loop through ALL available Maps (Ignores custom rotation)
                UseAllMaps = false,

                -- Ignore maps that don't have a download link
                IgnoreNonDownloadable = true,

                -- Custom Map Rotation
                Rotation = {

                    -- If Server should shuffle the map rotation
                    ShuffleRotation = true,

                    -- The map rotation
                    Rotation = {
                        { Map = "Multiplayer/IA/Outpost", TimeLimit = "1h" },
                        { Map = "Multiplayer/IA/SteelMill", TimeLimit = "1h" },
                        { Map = "Multiplayer/IA/Quarry", TimeLimit = "1h" },
                        { Map = "Multiplayer/IA/Poolday_v2", TimeLimit = "2h" },
                        { Map = "Multiplayer/PS/Mesa", TimeLimit = "6h" },
                    } ---< Rotation

                } ---< Rotation

            }, ---< MapConfig

            -----------------------
            --- Ping Control Config
            PingControl = {

                -- Fixed Ping for all Players
                FixedPing = -1,

                -- Ping Multiplier for all Players
                PingMultiplier = 1.0,

                ---------------
                --- Ping Limits
                PingLimit = {

                    -- Which type of ping to check
                    -- Real = Real Ping
                    -- Fake = Fake Ping (Server Influenced, by the variables above)
                    CheckType = "Real",

                    -- Maximum ping after which the player will receive a warning
                    Limit = 300,

                    -- Infraction Delay (in seconds)
                    InfractionDelay = 3,

                    -- Maximum infractions after which the Player will be kicked
                    MaxInfractions = 3,

                    -- Warning Message
                    WarningMessage = "@l_ui_pingwarning",

                    -- Amount of time to ban after exceeding infeaction limit
                    -- If it's 0, the player will only be kicked
                    BanTime = 0,



                } ---< PingLimit

            }, ---< PingControl

            -----------------------
            ---> Game Rule Specific
            GameRules = {

                ----------------------
                --- Work Configuration
                WorkingConfig = {

                    -- Reward upon stealing a vehicle
                    VehicleTheftReward = 25,

                    -- Reward upon reparing a vehicle
                    VehicleRepairReward = 25,

                }, ---< WorkingConfig

                ------------------------
                --- Turret Configuration
                TurretConfig = {

                    -- Calculate rewards based of points repaired
                    HitPointBasedReward = false,

                    -- Repair upon repairing a turret
                    RepairReward = 100,

                }, ---< TurretConfig

                ----------------------
                --- Hit Configuration
                HitConfig = {

                    -----------------
                    --- HQ Hit Config
                    HQHits = {

                        -- If true, will enable new HQ settings
                        CustomHQSettings = true,

                        -- TODO: FINISH this.
                        -- Localized damage (overwrites TacHits config)
                        LocalizedDamage = false,

                        -- How many TAC Hits it requires to destroy a HQ
                        TacHits = 5,

                        -- If true, HQs will be undestroyable
                        HQUndestroyable = false,

                        -- HQ cannot be destroyed before this amount of time
                        AttackDelay = FIFTEEN_MINUTES, -- 30 Minutes

                        -- If true, will send info message if HQ was hit
                        InfoMessage = true,

                        -- Reward for hitting HQs
                        RewardOnHit = {
                            PP = 500,
                            CP = 100,
                        }, ---< RewardOnHit

                    }, ---< HQHits

                    -- If players get killed when standing inside a garage in PS games
                    FactoryKills = false,

                    --------------
                    --- Team Kills
                    TeamKills = {

                        -- Damage Multiplier for hitting teammates
                        DamageMultiplier = 0.0, -- disabled

                        -- Threshold after which the player gets punished
                        PunishThreshold = 5,

                        -- Ban time (0 for kick)
                        BanTime = 0,

                    }, ---< TeamKills

                    -- Deduct rewards for killing bots
                    DeductBotKills = false,

                    -- Deduct Kills for killing teammates
                    DeductTeamKills = 1,

                    -- Deduct kills for suiciding
                    DeductSuicideKills = 0,

                    -- Add Deaths for suiciding (1 + this)
                    SuicideAddDeaths = 0,

                    -- If Server give out assistance based rewards for kills
                    KillAssistanceRewards = true,

                    -- timeout for assisting in kills
                    KillAssistanceTimeout = 12.5,

                    -- The assistance calulation type
                    -- 1 = Divide rewards by amount of damage dealt
                    -- 2 = Divide by the amount of hits landed
                    KillAssistanceType = 1,

                    -- The Minimum threshold to receive a share of the rewards (in percentage)
                    KillAssistanceThreshold = 5,

                    -- Fll dmage multiplier
                    FallMultiplier = 0.35,

                }, ---< HitConfig

                -----------------------
                -- Voting Configuration
                Voting = {

                    -- Allow users to utilize the kick vote
                    AllowKickVote = true,

                    -- Threshold after which a player will be banned
                    VoteKickBanThreshold = 3,

                    -- TIme after which kick vote counter will reset
                    VoteKickReset = THREE_HOURS

                }, ---< Voting

                -------------------------
                -- Prestige Configuration
                Prestige = {

                    -- Awards Players who captured a bunker prestige when someone spawns there
                    -- Or when a Player spawns in someones vehicle
                    AwardSpawnPrestige = true,

                    -- For Bunkers
                    BunkerSpawnAward = 100,

                    -- For Vehicles
                    VehicleSpawnAward = 100,

                    -- if a player should receive a share when another player buys an item
                    -- in a building that they have captured
                    AwardInvestPrestige = true,

                    -- The amount of prestige of the share the player gets (in percentage)
                    ItemInvestAward = 25,

                    -- The amount of prestige of the share the player gets (in percentage)
                    VehicleInvestAward = 15,

                }, ---< Prestige


                -----------------------
                -- Buying Configuration
                Buying = {

                    -- If players are allowed to sell their items
                    AllowSellItems = true,

                    -- the amount of prestige you get when selling an item (in percentage)
                    SellItemReward = 75,

                    -- A list of items the player cannot buy
                    -- check ItemList.txt for the correct names
                    ForbiddenItems = {
                        --"pistol"
                    },

                    -- A list of items the player cannot buy
                    -- check ItemList.txt for the correct names
                    ForbiddenVehicles = {
                    },

                    -- The maximum amount of kits a player can buy
                    KitLimit = 2,

                }, ---< Buying

                -- Skip Pre Game?
                SkipPreGame = true,

            }, ---< GameRules

            ---------------------------
            --- Equipment Configuration
            Equipment = {

                -- Physicalize plantables such as claymores and avmines
                PhysicalizePlantables = true,

                -- Load saved accessories and attach them when picking up an item
                RestoreOnPickUp = true,

                -- Save Players Accessory configuration
                SavePlayerAccessories = true,

                -------------------
                --- Spawn Equipment
                SpawnEquipment = {

                    -- Use saved accessory configuration
                    LoadPlayerAccessories = true,

                    -- PowerStruggle Config
                    ["PowerStruggle"] = {
                        Active  = true,
                        Regular = { { "SMG",  {} } },
                        Premium = { { "FY71", {} } },
                        Admin = {
                            { "FY71", { "LAMRifle" }},
                            --{ "RadarKit" } -- unfair, unbalanced..
                        },
                        AdditionalEquip = { 'Binoculars', 'Parachute' },
                        MustHave        = {},
                    }, ---< PowerStruggle

                    -- InstantAction Config
                    ["InstantAction"] = {
                        Active  = true,
                        Regular = { { "FY71",  { "LAMRifle" } } },
                        Premium = { { "FY71", { "Silencer", "LAMRifle"} } },
                        Admin = {
                            { "FY71", { "LAMRifle", "Reflex", "Silencer" }},
                        },
                        AdditionalEquip = { 'Binoculars' },
                        MustHave        = {},
                    } ---< InstantAction

                } ---< SpawnEquip

            } ---< Equipment

        }, ---< General

        -------------------------
        ---> Server Name Settings
        Names = {

            -- Name Template
            -- Format Variables are
            --- > {a_country}   > Country Code
            --- > {a_profile}   > Profile ID
            NameTemplate = "Nomad:{a_country} (#{a_profile})",

            -- Allow Spaces in Names
            AllowSpaces = true,

            -- Forbidden Names
            ForbiddenNames = {
                "Nomad",
            },

            -- Forbidden Symbols
            ForbiddenSymbols = {
                "@",
                "%%",
            },

            -- Replacement Character used in sanitization
            ReplacementCharacter = "_",

        }, ---< Names

        ----------------------------
        ---> Server Message Settings
        Messages = {

            Console = {

                Queue = {

                    -- Queue is not needed with changed RMI reliability flags
                    Enabled = false, -- Status of the Console Queue

                    -- Pop count per cycle
                    PopCount = 2,

                    -- delay between cycles, in ms
                    PopDelay = 1,

                } ---< Queue

            } ---< Console

        } ---< Names

    } ---< Config
})