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
        SERVER_USE_HIT_QUEUE = 0.0,         -- Server Hit Queue (Slow)
        SERVER_USE_EXPLOSION_QUEUE = 1.0,   -- Server Explosion Queue
    },

    -------------------------
    ---> Server Configuration
    Config = {

        --------------------------
        ---> Command Configuration
        Commands = {

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

            --------------------------
            --- List of Existing Ranks
            --- Cosmetics:
            ---  > Name,     The Short Name of the Rank
            ---  > LongName, The Long Name of the Rank (If null, uses Short Name)
            ---  > Color,    The Color used when displaying this Rank
            RankList = {
            ---   Authority        Global Identifier  Name                  Color                Will be assigned to new players
                { Authority   = 0, ID = "GUEST",      Name = "Guest",       Color = CRY_COLOR_GREEN,    Default = true },
                { Authority   = 1, ID = "PLAYER",     Name = "Player",      Color = CRY_COLOR_WHITE                    },
                { Authority   = 2, ID = "PREMIUM",    Name = "Premium",     Color = CRY_COLOR_BLUE,     Premium = true },
                { Authority   = 3, ID = "MODERATOR",  Name = "Moderator",   Color = CRY_COLOR_ORANGE                   },
                { Authority   = 4, ID = "ADMIN",      Name = "Admin",       Color = CRY_COLOR_RED,      Admin = true   },
                { Authority   = 5, ID = "HEADADMIN",  Name = "HeadAdmin",   Color = CRY_COLOR_RED                      },
                { Authority   = 6, ID = "SUPERADMIN", Name = "SuperAdmin",  Color = CRY_COLOR_WHITE }, -- indicating that this class is a developer class
                { Authority   = 7, ID = "DEVELOPER",  Name = "Developer",   Color = CRY_COLOR_MAGENTA,  Developer = true },
                { Authority   = 8, ID = "OWNER",      Name = "Owner",       Color = CRY_COLOR_MAGENTA,  Developer = true }
            }

        }, ---< Ranks

        --------------------------
        ---> Server Configuration
        Server = {

            --------------------
            -- Punishment Config
            Punishment = {

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
                --- > {mod_name}        > Server Mod Name
                --- > {mod_version}     > Server Mod Version
                Description = "\tServer Running on ${mod_exe} ${mod_version} (x${mod_bits})\nCompiled Using ${mod_compiler}",

            }, ---< Report

            ----------------------
            --- Map Download Links
            MapLinks = {

                ["Multiplayer/PS/Mesa"] = "http://download.host.net/ps/mesa", -- FIXME

            } ---< MapLinks

        }, ---< Server

        --------------------------
        ---> General Game Settings
        General = {

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

                    -- Infaction Delay (in seconds)
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
                --- Hit Configuration
                HitConfig = {

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

                }, ---< HitConfig

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

                -- Save Players Accessory configuration
                SavePlayerAccessories = true,

                -------------------
                --- Spawn Equipment
                SpawnEquip = {

                    -- Use saved accessory configuration
                    LoadPlayerAccessories = true,

                    -- PowerStruggle Config
                    ["PowerStruggle"] = {
                        Active  = true,
                        Regular = {
                            Regular = { { "FY71", { "LAMRifle", "Silencer" }} },
                            Premium = {
                                { "FY71", { "LAMRifle", "Silencer" }},
                                { "SCAR", { "LAMRifle", "Silencer", "Reflex" }}
                            },
                            Admin = {
                                { "FY71", { "LAMRifle", "Silencer", "SniperScope" }},
                                { "SCAR", { "LAMRifle", "Silencer", "Reflex" }},
                                { "RadarKit" }
                            },
                            AdditionalEquip = { 'Binoculars' },
                            MustHave        = { "LAMRifle", "Silencer" }
                        }
                    }, ---< PowerStruggle

                    -- InstantAction Config
                    ["InstantAction"] = {
                        Active  = true,
                        Regular = {
                            Regular = {
                                { "FY71", { "LAMRifle", "Silencer" }}
                            },
                            Premium = {
                                { "SMG",  { "LAMRifle", "Silencer", "Reflex" }},
                                { "FY71", { "LAMRifle", "Silencer", "Reflex" }}
                            },
                            AdditionalEquip = { 'Binoculars' },
                            MustHave        = { "LAMRifle", "Silencer" }
                        }
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

                    Enabled = true, -- Status of the Console Queue
                    PopCount = 2, -- Amount of messages to pep each cycle
                    PopDelay = 1, -- In Milliseconds

                } ---< Queue

            } ---< Console

        } ---< Names

    } ---< Config
})