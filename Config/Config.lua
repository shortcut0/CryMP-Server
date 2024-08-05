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
                { Authority   = 0, ID = "GUEST",      Name = "Guest",       Color = CRY_COLOR_GREEN, Default = true },
                { Authority   = 1, ID = "PLAYER",     Name = "Player",      Color = CRY_COLOR_WHITE },
                { Authority   = 2, ID = "PREMIUM",    Name = "Premium",     Color = CRY_COLOR_WHITE },
                { Authority   = 3, ID = "MODERATOR",  Name = "Moderator",   Color = CRY_COLOR_WHITE },
                { Authority   = 4, ID = "ADMIN",      Name = "Admin",       Color = CRY_COLOR_WHITE },
                { Authority   = 5, ID = "HEADADMIN",  Name = "HeadAdmin",   Color = CRY_COLOR_WHITE },
                { Authority   = 6, ID = "SUPERADMIN", Name = "SuperAdmin",  Color = CRY_COLOR_WHITE }, -- indicating that this class is a developer class
                { Authority   = 7, ID = "DEVELOPER",  Name = "Developer",   Color = CRY_COLOR_WHITE, Developer = true },
                { Authority   = 8, ID = "OWNER",      Name = "Owner",       Color = CRY_COLOR_WHITE, Developer = true }
            }

        }, ---< Ranks

        --------------------------
        ---> Server Configuration
        Server = {

            ------------------
            --- Welcome Config
            Welcome = {

                --- The Chat message appearing when a user entered the server
                ChatMessage = "@l_ui_welcomechat",

            }, ---< Welcome

            --- The Default Server Language
            --- Available:
            ---  > english
            ---  > spanish
            ---  > german
            ---  > russian
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
            ---> Game Rule Specific
            GameRules = {

                -- Skip Pre Game?
                SkipPreGame = true,

            } ---< GameRules

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