CreateMapSetup("Mesa", "PS", {

    -- ==================
    Active = true,

    -- ==================
    -- AddEntity

    -- ==================
    Init = function(self)

        -- FIXME
        -- self:Spawn({})

        for _, aInfo in pairs({

            -- ============================================================
            -- Neutrals

            {
                Pos = { x = 2086.822998, y = 1984.178711, z = 48.188164 },
                Dir = { x = -0.999328, y = -0.036646, z = 0.000000 }
            },
            {
                Pos = { x = 2085.105225, y = 2008.642578, z = 48.188164 },
                Dir = { x = -0.994867, y = 0.101189, z = 0.000000 }
            },
            {
                Pos = { x = 2086.841064, y = 2015.880737, z = 48.188164 },
                Dir = { x = 0.063053, y = 0.998010, z = 0.000000 }
            },
            {
                SvCanEnter = function(this, hUser)

                    local hProto = g_gameRules.SortedBuildings["proto"][1]
                    local iDistance = vector.distance(this:GetPos(), hProto:GetPos())

                    local iThisTeam = g_pGame:GetTeam(this.id)
                    local iUserTeam = g_pGame:GetTeam(hUser.id)
                    local iProtoTeam = g_pGame:GetTeam(hProto.id)

                    --[[
                    if (iThisTeam == iUserTeam and not this:IsEmpty()) then
                        return true
                    elseif (this:IsEmpty() and iDistance < 115) then
                        Debug(iDistance,"set to team",iProtoTeam)
                        g_pGame:SetTeam(iProtoTeam, this.id)
                    end
                    if (iUserTeam == 0 or (iUserTeam ~= iProtoTeam and iDistance < 115)) then
                        SendMsg(MSG_ERROR, hUser, hUser:Localize("@l_ui_captureTheBuildingToEnter", {"@l_ui_bName_Prototype"}))
                        return false
                    end]]

                    -- New System: If vehicle was ever used, allow team to enter..
                    --Debug(this:GetInfo("WasUsed"))
                    if (not this:GetInfo("WasUsed") and (iProtoTeam ~= iUserTeam)) then
                        SendMsg(MSG_ERROR, hUser, hUser:Localize("@l_ui_captureTheBuildingToEnter", {"@l_ui_bName_Prototype"}))
                        return false
                    end

                    return true
                end,
                RespawnTimer = 300,
                Class = "Asian_helicopter",
                Pos = { x = 2069.031494, y = 2038.287354, z = 49.203819 },
                Dir = { x = -0.999592, y = -0.028560, z = 0.000000 }
            },

            -- =======================================================
            -- US Base
            {
                RespawnTimer = 600,
                Class = "US_vtol",
                Paint = "us",
                Team = TEAM_US,
                Pos = { x = 1605.632324, y = 1737.053833, z = 81.129539 },
                Dir = { x = -0.670866, y = 0.741578, z = 0.000000 }
            },
            {
                RespawnTimer = 120,
                Class = "Asian_aaa",
                Paint = "us",
                Team = TEAM_US,
                Pos = { x = 1597.633179, y = 1719.617554, z = 82.649391 },
                Dir = { x = -0.702171, y = 0.712009, z = 0.000000 }
            },
            {
                RespawnTimer = 60,
                Class = "Asian_truck",
                Paint = "us",
                Modification = "MP",
                Team = TEAM_US,
                Pos = { x = 1564.423340, y = 1755.995483, z = 79.203484 },
                Dir = { x = -0.711041, y = -0.703151, z = 0.000000 }
            },
            {
                RespawnTimer = 60,
                Class = "Asian_truck",
                Paint = "us",
                Modification = "MP",
                Team = TEAM_US,
                Pos = { x = 1512.126465, y = 1758.871826, z = 79.203644 },
                Dir = { x = 0.740691, y = 0.671846, z = 0.000000 }
            },
            {
                RespawnTimer = 60,
                Class = "US_ltv",
                Modification = "MP",
                Team = TEAM_US,
                Pos = { x = 1544.699707, y = 1775.969727, z = 79.203484 },
                Dir = { x = -0.661099, y = 0.750298, z = 0.000000 }
            },
            {
                RespawnTimer = 60,
                Class = "US_ltv",
                Modification = "MP",
                Team = TEAM_US,
                Pos = { x = 1565.663574, y = 1823.363281, z = 79.204033 },
                Dir = { x = 0.977120, y = -0.212690, z = 0.000000 }
            },
            {
                RespawnTimer = 60,
                VehicleID = VM_TESLA,
                Class = "Civ_car1",
                Team = TEAM_US,
                Pos = { x = 1533.146118, y = 1793.517944, z = 79.203812 },
                Dir = { x = 1.000000, y = 0.001011, z = 0.000000 }
            },

            -- ===========================================================
            -- NK Base
            {
                RespawnTimer = 60,
                Class = "Asian_ltv",
                Team = TEAM_NK,
                Paint = "nk",
                Modification = "MP",
                Pos = { x = 2587.073730, y = 2490.656982, z = 58.125286 },
                Dir = { x = -0.999942, y = -0.010752, z = 0.000000 }
            },
            {
                RespawnTimer = 60,
                Class = "Asian_ltv",
                Team = TEAM_NK,
                Paint = "nk",
                Modification = "MP",
                Pos = { x = 2544.868652, y = 2514.559082, z = 58.124428 },
                Dir = { x = -0.999742, y = -0.022726, z = 0.000000 }
            },
            {
                RespawnTimer = 80,
                Class = "Asian_aaa",
                Team = TEAM_NK,
                Paint = "nk",
                Pos = { x = 2607.632812, y = 2447.523438, z = 61.507874 },
                Dir = { x = -0.998535, y = 0.054108, z = 0.000000 }
            },
            {
                RespawnTimer = 80,
                Class = "Asian_aaa",
                Team = TEAM_NK,
                Paint = "nk",
                Pos = { x = 2482.905762, y = 2525.101318, z = 58.076012 },
                Dir = { x = 0.998274, y = -0.058723, z = 0.000000 }
            },
            {
                RespawnTimer = 600,
                Class = "US_vtol",
                Paint = "nk",
                Team = TEAM_NK,
                Pos = { x = 2615.970947, y = 2429.035645, z = 59.988258 },
                Dir = { x = -0.998644, y = 0.052058, z = 0.000000 }
            },
            {
                RespawnTimer = 60,
                Class = "Asian_truck",
                Modification = "MP",
                Paint = "nk",
                Team = TEAM_NK,
                Pos = { x = 2553.745850, y = 2450.035645, z = 58.125168 },
                Dir = { x = 0.028437, y = 0.999596, z = 0.000000 }
            },
            {
                RespawnTimer = 60,
                VehicleID = VM_TESLA,
                Class = "Civ_car1",
                Team = TEAM_NK,
                Pos = { x = 2552.274170, y = 2506.794922, z = 58.124428 },
                Dir = { x = -0.042831, y = -0.999082, z = 0.000000 }
            },
            {
                RespawnTimer = 60,
                VehicleID = VM_TESLA,
                Class = "Civ_car1",
                Team = TEAM_NK,
                Pos = { x = 2563.850342, y = 2468.661865, z = 59.192135 },
                Dir = { x = 0.996786, y = -0.079864, z = 0.006267 }
            },


        }) do
            Script.SetTimer(1, function()
                local hSpawned = self:Spawn({
                    Class = (aInfo.Class or "Civ_car1"),
                    Pos   = aInfo.Pos,
                    Dir   = aInfo.Dir,
                    Properties = {
                        Paint = (aInfo.Paint or getrandom({ "red", "silver", "brown", "green", "blue" })),
                        Modification = (aInfo.Modification),
                    },
                    Respawn = true,
                    RespawnTimer = (aInfo.RespawnTimer or 120)
                })

                hSpawned.SvCanEnter = aInfo.SvCanEnter

                g_pGame:SetTeam((aInfo.Team or TEAM_NEUTRAL), hSpawned.id)
                if (aInfo.VehicleID) then
                    ClientMod:ChangeVehicleModel(nil, hSpawned, aInfo.VehicleID)
                end
            end)
        end

        for _, hBunker in pairs(g_gameRules.SortedBuildings["bunker"]) do
            self:SpawnBunkerDoors(hBunker, hBunker:GetDirectionVector())
        end
    end,

    -- ==================
    SpawnBunkerDoors = function(self, hBunker, vRot)

        -- the model
        local sModel = "Objects/library/barriers/concrete_wall/gate_6m.cgf";

        -- directions
        local vLeft = vector.left(vRot)
        local directions = {
            vLeft, -- bunker direction
            vRot, -- bunker direction
            vLeft, -- bunker direction
        }

        -- local positions
        local aPositions = {
            vector.make( -1.1492, -4.2734, -1.8255 ), -- wall 1 pt 1
            vector.make( -4.2681, 0.113,   -1.8255 ), -- wall 1 pt 2
            vector.make( -1.1492, 4.3940,  -1.8255 ), -- wall 2 pt 1
        }

        for i = 1, 3 do
            self:SpawnGUI({
                Model   = sModel,
                Pos     = hBunker:ToGlobal(-1, aPositions[i]),
                Dir     = directions[i],
                Physics = true,
                Rigid   = false,
                Mass    = -1,
                Resting = true,
                Network = true
            })
        end


    end

})