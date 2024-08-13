------------
local ServerPlayer = {

    -----------------
    This = "Player",
    PatchEntities = true,

    -----------------
    PostInit = function(self)
    end,

}

------------
ServerInjector.InjectAll(ServerPlayer)