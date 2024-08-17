local ServerVehicleBase = {

    -----------------
    This = "VehicleBase",
    PatchEntities = true,

    -----------------
    PostInit = function(self)
    end,

    ---------------------------------------------
    --- KillPlayers
    ---------------------------------------------
    {

        Class = table.append({ "VehicleBase" }, GetVehicleClasses() ),
        Target = { "GetPassengerCount" },
        Type = eInjection_Replace,

        ------------------------
        Function = function(self, player, time)
            local iCount = 0
            for _, aSeat in pairs(self.Seats) do
                if (aSeat:GetPassengerId()) then
                     iCount = iCount + 1
                end
            end
            return iCount
        end
    }

}

---------------------
ServerInjector.InjectAll(ServerVehicleBase)