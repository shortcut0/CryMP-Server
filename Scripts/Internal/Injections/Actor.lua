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

    ---------------------------------------------
    --- Server.OnUpdate
    ---------------------------------------------
    {

        Class = "BasicActor",
        Target = { "Server.OnUpdate" },
        Type = eInjection_Replace,

        ------------------------
        Function = function(self, iFrameTime)

            -- PlayerHandler
            if (self.IsPlayer) then
                self:Update()
            end

            if (not self:IsDead()) then
                self:UpdateEvents(iFrameTime)
            end

            --ServerLog("hi")
        end
    },
}

------------
ServerInjector.InjectAll(ServerActor)