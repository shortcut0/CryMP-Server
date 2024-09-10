------------
local ServerItems = {

    -----------------
    This = nil,
    PatchEntities = true,

    -----------------
    PostInit = function(self)
    end,

    ---------------------------------------------
    --- PatchShiTen
    ---------------------------------------------
    {

        Class = "ShiTen",
        Type  = eInjection_Replace,
        Target  = { "PatchShiTen" },
        Execute = true,

        ------------------------
        Function = function(self)
        end
    },
}

------------
ServerInjector.InjectAll(ServerItems)