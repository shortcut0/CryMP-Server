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

        sTestE = "Test ok!",

        --------------------------
        ---> Server Configuration
        Server = {

            ----------------------------------
            --- Info sent to the Master Server
            Report = {

                -- Time between each Status Report, in Seconds
                UpdateRate = 60.0,

                -- The Server Description
                -- Format Variables are
                --- > {mod_name}        > Server Mod Name
                --- > {mod_version}     > Server Mod Version
                Description = "Server Running on ${mod_name} - ${mod_version}",

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

        } ---< General

    } ---< Config
})