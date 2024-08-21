------------
local ServerActor = {

    -----------------
    This = "BasicActor",
    PatchEntities = true,

    -----------------
    PostInit = function(self)
    end,

    ---------------------------------------------
    --- DoPainSounds
    ---------------------------------------------
    {

        Class = "BasicActor",
        Target = { "DoPainSounds" },
        Type = eInjection_Replace,

        ------------------------
        Function = function()
        end
    },
}

------------
ServerInjector.InjectAll(ServerActor)