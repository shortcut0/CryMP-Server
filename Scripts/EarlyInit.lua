------------
EarlyInit = {

    ------------------
    ---    Init    ---
    ------------------
    Init = function()

        System.LogAlways("EarlyInit.Init()")

        -- fix non-unique entity name

        --fixme mapsetup
        System.OldSpawnEntity = (System.OldSpawnEntity or System.SpawnEntity)
        System.SpawnEntity = function(aParams, ...)
            if (aParams.class == "Civ_car1") then
                aParams.properties = aParams.properties or {}
                if (aParams.properties.Paint == nil) then
                    local aPaints = {
                        "red","green","blue","black","silver"
                    }
                    aParams.properties.Paint = aPaints[math.random(#aPaints)]
                end
            end
            return System.OldSpawnEntity(aParams, ...)
        end
    end,

}


EarlyInit.Init()