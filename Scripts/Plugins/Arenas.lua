eARENA_MINI0   = 0

eARENA_BOXING  = 10
eARENA_PVP     = 11
eARENA_STADIUM = 12

eServerStat_Arena0 = "mini0"

eServerStat_Arena10 = "arena0"
eServerStat_Arena11 = "arena1"
eServerStat_Arena12 = "arena2"

ServerArena = {

    Temp    = (ServerArena and ServerArena.Temp or {}),
    Data    = {
        [eARENA_BOXING] = {

            Name = "@l_ui_boxing @l_ui_arena",

            Equipment = {
                "Fists"
            },
            BBox = {
                min = { x = 5 ,  y = 8,  z = -1 },
                max = { x = 45,  y = 50, z = 60 }
            },
            Parts = {
                { Pos = vector.make(0, 38, 7),  Dir = vector.make(0.70710671, 0, 0), Model = "Objects/library/barriers/concrete_wall/concrete_wall_16m_b.cgf" },
                { Pos = vector.make(48, 6, 7),  Dir = vector.make(-0.70710689, 0, 0), Model = "Objects/library/barriers/concrete_wall/concrete_wall_16m_b.cgf" },
                { Pos = vector.make(0, 54, 7),  Dir = vector.make(0.70710671, 0, 0), Model = "Objects/library/barriers/concrete_wall/concrete_wall_16m_b.cgf" },
                { Pos = vector.make(0, 22, 7),  Dir = vector.make(0, 0, 0), Model = "Objects/library/barriers/concrete_wall/concrete_wall_16m_b.cgf" },
                { Pos = vector.make(0, 6, 7),   Dir = vector.make(0, 1, 0), Model = "Objects/library/barriers/concrete_wall/concrete_wall_16m_b.cgf" },
                { Pos = vector.make(16, 6, 7),  Dir = vector.make(0, 1, 0), Model = "Objects/library/barriers/concrete_wall/concrete_wall_16m_b.cgf" },
                { Pos = vector.make(32, 6, 7),  Dir = vector.make(0, 1, 0), Model = "Objects/library/barriers/concrete_wall/concrete_wall_16m_b.cgf" },
                { Pos = vector.make(16, 54, 7), Dir = vector.make(0, -1, 0), Model = "Objects/library/barriers/concrete_wall/concrete_wall_16m_b.cgf" },
                { Pos = vector.make(32, 54, 7), Dir = vector.make(0, -1, 0), Model = "Objects/library/barriers/concrete_wall/concrete_wall_16m_b.cgf" },
                { Pos = vector.make(48, 22, 7), Dir = vector.make(-0.70710689, 0, 0), Model = "Objects/library/barriers/concrete_wall/concrete_wall_16m_b.cgf" },
                { Pos = vector.make(48, 54, 7), Dir = vector.make(0, -1, 0), Model = "Objects/library/barriers/concrete_wall/concrete_wall_16m_b.cgf" },
                { Pos = vector.make(48, 38, 7), Dir = vector.make(-1, 0, 0), Model = "Objects/library/barriers/concrete_wall/concrete_wall_16m_b.cgf" },
                { Pos = vector.make(16.075005, 50.975006, 0.075001),    Dir = vector.make(0, 1, 0), Model = "Objects/library/architecture/aircraftcarrier/hangar_a_floor3.cgf" },
                { Pos = vector.make(32.450012, 26.475002, 0.075001),    Dir = vector.make(0, 1, 0), Model = "Objects/library/architecture/aircraftcarrier/hangar_a_floor3.cgf" },
                { Pos = vector.make(16.075005, 26.475006, 0.075001),    Dir = vector.make(0, 1, 0), Model = "Objects/library/architecture/aircraftcarrier/hangar_a_floor3.cgf" },
                { Pos = vector.make(32.450012, 50.975006, 0.075001),    Dir = vector.make(0, 1, 0), Model = "Objects/library/architecture/aircraftcarrier/hangar_a_floor3.cgf" },
                { Pos = vector.make(-0.299995, 26.47501, 0.075001),     Dir = vector.make(0, 1, 0), Model = "Objects/library/architecture/aircraftcarrier/hangar_a_floor3.cgf" },
                { Pos = vector.make(-0.299995, 50.975006, 0.075001),    Dir = vector.make(0, 1, 0), Model = "Objects/library/architecture/aircraftcarrier/hangar_a_floor3.cgf" },
            }
        },

        [eARENA_MINI0] = {

            Name = "@l_ui_arena #%d",

            BBox = {
                min = { x = -14 ,  y = -36,  z = -5 },
                max = { x = -12 + 80,  y = 14, z = 60 }
            },
            Parts = {
                { Pos = vector.make(8.5, -9.25, 0),     Dir = vector.make(0, 1.57272, 0), 	Model = "Objects/library/architecture/harbour/warehouse/warehouse_helipad.cgf", Scale = 2 },
                { Pos = vector.make(43.40, -9.25, 0), 	Dir = vector.make(0, -1.57272, 0),	Model = "Objects/library/architecture/harbour/warehouse/warehouse_helipad.cgf", Scale = 2 },

                { Pos = vector.make(9.725, -19, 1.375), Dir = vector.make(0, 0, 0), 		Model = "Objects/library/architecture/concrete structure/terrain_level_ramp_20x.cgf" },
                { Pos = vector.make(43.40, 1, 1.375), 	Dir = vector.make(-1, 0, 0), 		Model = "Objects/library/architecture/concrete structure/terrain_level_ramp_20x.cgf" },

                { Pos = vector.make(32.0, -9, 2.375), 	Dir = vector.make(0, 0, 0), 		Model = "objects/library/architecture/concrete structure/terrain_level_ramp_corner_out.cgf" },
                { Pos = vector.make(26.0, -15, 2.375), 	Dir = vector.make(0, -1, 0), 		Model = "objects/library/architecture/concrete structure/terrain_level_ramp_corner_out.cgf" },
                { Pos = vector.make(20.0, -9, 2.375), 	Dir = vector.make(-1, 0, 0), 		Model = "objects/library/architecture/concrete structure/terrain_level_ramp_corner_out.cgf" },
                { Pos = vector.make(26.0, -3, 2.375), 	Dir = vector.make(0, 1, 0), 		Model = "objects/library/architecture/concrete structure/terrain_level_ramp_corner_out.cgf" },

            }

        },

        [eARENA_PVP] = {

            Name = "@l_ui_boxing @l_ui_arena",

            BBox = {
                min = { x = 5 ,  y = 8,  z = -1 },
                max = { x = 45,  y = 50, z = 60 }
            },
            Parts = {
                { Pos = vector.new(0, 38, 7), Dir = vector.new(0.70710671, 0, 0), Model = "Objects/library/barriers/concrete_wall/concrete_wall_16m_b.cgf" },
                { Pos = vector.new(48, 6, 7), Dir = vector.new(-0.70710689, 0, 0), Model = "Objects/library/barriers/concrete_wall/concrete_wall_16m_b.cgf" },
                { Pos = vector.new(0, 54, 7), Dir = vector.new(0.70710671, 0, 0), Model = "Objects/library/barriers/concrete_wall/concrete_wall_16m_b.cgf" },
                { Pos = vector.new(0, 22, 7), Dir = vector.new(0, 0, 0), Model = "Objects/library/barriers/concrete_wall/concrete_wall_16m_b.cgf" },
                { Pos = vector.new(0, 6, 7), Dir = vector.new(0, 1, 0), Model = "Objects/library/barriers/concrete_wall/concrete_wall_16m_b.cgf" },
                { Pos = vector.new(16, 6, 7), Dir = vector.new(0, 1, 0), Model = "Objects/library/barriers/concrete_wall/concrete_wall_16m_b.cgf" },
                { Pos = vector.new(32, 6, 7), Dir = vector.new(0, 1, 0), Model = "Objects/library/barriers/concrete_wall/concrete_wall_16m_b.cgf" },
                { Pos = vector.new(16, 54, 7), Dir = vector.new(0, -1, 0), Model = "Objects/library/barriers/concrete_wall/concrete_wall_16m_b.cgf" },
                { Pos = vector.new(32, 54, 7), Dir = vector.new(0, -1, 0), Model = "Objects/library/barriers/concrete_wall/concrete_wall_16m_b.cgf" },
                { Pos = vector.new(48, 22, 7), Dir = vector.new(-0.70710689, 0, 0), Model = "Objects/library/barriers/concrete_wall/concrete_wall_16m_b.cgf" },
                { Pos = vector.new(48, 54, 7), Dir = vector.new(0, -1, 0), Model = "Objects/library/barriers/concrete_wall/concrete_wall_16m_b.cgf" },
                { Pos = vector.new(48, 38, 7), Dir = vector.new(-1, 0, 0), Model = "Objects/library/barriers/concrete_wall/concrete_wall_16m_b.cgf" },
                { Pos = vector.new(16.075005, 50.975006, 0.075001), Dir = vector.new(0, 1, 0), Model = "Objects/library/architecture/aircraftcarrier/hangar_a_floor3.cgf" },
                { Pos = vector.new(32.450012, 26.475002, 0.075001), Dir = vector.new(0, 1, 0), Model = "Objects/library/architecture/aircraftcarrier/hangar_a_floor3.cgf" },
                { Pos = vector.new(16.075005, 26.475006, 0.075001), Dir = vector.new(0, 1, 0), Model = "Objects/library/architecture/aircraftcarrier/hangar_a_floor3.cgf" },
                { Pos = vector.new(32.450012, 50.975006, 0.075001), Dir = vector.new(0, 1, 0), Model = "Objects/library/architecture/aircraftcarrier/hangar_a_floor3.cgf" },
                { Pos = vector.new(-0.299995, 26.47501, 0.075001), Dir = vector.new(0, 1, 0), Model = "Objects/library/architecture/aircraftcarrier/hangar_a_floor3.cgf" },
                { Pos = vector.new(-0.299995, 50.975006, 0.075001), Dir = vector.new(0, 1, 0), Model = "Objects/library/architecture/aircraftcarrier/hangar_a_floor3.cgf" },

                { Pos = vector.new(66.575, 37.900002, 1.9999999985032e-06), Dir = vector.new(0, 1, 0), Model = "Objects/library/machines/cranes/container_crane/container_crane.cgf" },
                { Pos = vector.new(23.625, 7.875, 0), Dir = vector.new(0, 1, 0), Model = "Objects/library/barriers/concrete_wall/support_building_fit_concrete_wall.cgf" },
                { Pos = vector.new(22.547081, 10.747971, 0.375), Dir = vector.new(0.70710677, 0, 0), Model = "Objects/library/barriers/concrete_wall/door.cgf" },
                { Pos = vector.new(35.724983, 29.125, 2.474998), Dir = vector.new(0, 1, 0), Model = "Objects/library/architecture/concrete structure/concrete_structure_curb_6mb.cgf" },
                { Pos = vector.new(41.724976, 29.125008, 2.474998), Dir = vector.new(0, -1, 0), Model = "Objects/library/architecture/concrete structure/concrete_structure_curb_6mb.cgf" },
                { Pos = vector.new(26.72501, 19.749992, 2.475002), Dir = vector.new(0, 1, 0), Model = "Objects/library/architecture/concrete structure/concrete_structure_curb_b.cgf" },
                { Pos = vector.new(6.050011, 38.524994, 2.475002), Dir = vector.new(0, 1, 0), Model = "Objects/library/architecture/concrete structure/concrete_structure_curb_b.cgf" },
                { Pos = vector.new(26.72501, 38.524994, 2.475002), Dir = vector.new(0, 1, 0), Model = "Objects/library/architecture/concrete structure/concrete_structure_curb_b.cgf" },
                { Pos = vector.new(6.075008, 29.124992, 2.475002), Dir = vector.new(0, 1, 0), Model = "Objects/library/architecture/concrete structure/concrete_structure_curb_b.cgf" },
                { Pos = vector.new(6.075008, 19.749992, 2.475002), Dir = vector.new(0, 1, 0), Model = "Objects/library/architecture/concrete structure/concrete_structure_curb_b.cgf" },
                { Pos = vector.new(41.725014, 38.524994, 2.475002), Dir = vector.new(0, -1, 0), Model = "Objects/library/architecture/concrete structure/concrete_structure_curb_b.cgf" },
                { Pos = vector.new(21.075012, 29.124992, 2.475002), Dir = vector.new(0, -1, 0), Model = "Objects/library/architecture/concrete structure/concrete_structure_curb_b.cgf" },
                { Pos = vector.new(21.050014, 38.524994, 2.475002), Dir = vector.new(0, -1, 0), Model = "Objects/library/architecture/concrete structure/concrete_structure_curb_b.cgf" },
                { Pos = vector.new(21.075012, 19.749996, 2.475002), Dir = vector.new(0, -1, 0), Model = "Objects/library/architecture/concrete structure/concrete_structure_curb_b.cgf" },
                { Pos = vector.new(41.725014, 19.749996, 2.475002), Dir = vector.new(0, -1, 0), Model = "Objects/library/architecture/concrete structure/concrete_structure_curb_b.cgf" },
                { Pos = vector.new(35.725006, 29.125, 2.475), Dir = vector.new(0, -1, 0), Model = "Objects/library/architecture/concrete structure/concrete_structure_curb_9mb.cgf" },
                { Pos = vector.new(26.725006, 29.125008, 2.475), Dir = vector.new(0, 1, 0), Model = "Objects/library/architecture/concrete structure/concrete_structure_curb_9mb.cgf" },
                { Pos = vector.new(16.074997, 30.300003, 0.025002000000001), Dir = vector.new(-0.70710671, 0, 0), Model = "Objects/library/architecture/village/wall/concrete_wall_simple_4m.cgf" },
                { Pos = vector.new(28.712502, 37.674995, 0.025002000000001), Dir = vector.new(-0.70710671, 0, 0), Model = "Objects/library/architecture/village/wall/concrete_wall_simple_4m.cgf" },
                { Pos = vector.new(12.099991, 18.887501, 0.025002000000001), Dir = vector.new(-0.70710671, 0, 0), Model = "Objects/library/architecture/village/wall/concrete_wall_simple_4m.cgf" },
                { Pos = vector.new(12.099991, 37.662498, 0.025002000000001), Dir = vector.new(-0.70710671, 0, 0), Model = "Objects/library/architecture/village/wall/concrete_wall_simple_4m.cgf" },
                { Pos = vector.new(16.074997, 20.925003, 0.025002000000001), Dir = vector.new(-0.70710671, 0, 0), Model = "Objects/library/architecture/village/wall/concrete_wall_simple_4m.cgf" },
                { Pos = vector.new(31.724998, 30.300003, 0.025002000000001), Dir = vector.new(-0.70710671, 0, 0), Model = "Objects/library/architecture/village/wall/concrete_wall_simple_4m.cgf" },
                { Pos = vector.new(19.062489, 37.662498, 0.025002000000001), Dir = vector.new(-0.70710671, 0, 0), Model = "Objects/library/architecture/village/wall/concrete_wall_simple_4m.cgf" },
                { Pos = vector.new(19.062489, 18.887501, 0.025002000000001), Dir = vector.new(-0.70710671, 0, 0), Model = "Objects/library/architecture/village/wall/concrete_wall_simple_4m.cgf" },
                { Pos = vector.new(12.099991, 28.262505, 0.025002000000001), Dir = vector.new(-0.70710671, 0, 0), Model = "Objects/library/architecture/village/wall/concrete_wall_simple_4m.cgf" },
                { Pos = vector.new(31.724998, 20.925003, 0.025002000000001), Dir = vector.new(-0.70710671, 0, 0), Model = "Objects/library/architecture/village/wall/concrete_wall_simple_4m.cgf" },
                { Pos = vector.new(28.712502, 18.887501, 0.025002000000001), Dir = vector.new(-0.70710671, 0, 0), Model = "Objects/library/architecture/village/wall/concrete_wall_simple_4m.cgf" },
                { Pos = vector.new(16.074997, 39.700005, 0.025002000000001), Dir = vector.new(-0.70710671, 0, 0), Model = "Objects/library/architecture/village/wall/concrete_wall_simple_4m.cgf" },
                { Pos = vector.new(31.724998, 39.712509, 0.025002000000001), Dir = vector.new(-0.70710671, 0, 0), Model = "Objects/library/architecture/village/wall/concrete_wall_simple_4m.cgf" },
                { Pos = vector.new(8.099998, 30.300003, 0.025002000000001), Dir = vector.new(-0.70710671, 0, 0), Model = "Objects/library/architecture/village/wall/concrete_wall_simple_4m.cgf" },
                { Pos = vector.new(8.099998, 39.699997, 0.025002000000001), Dir = vector.new(-0.70710671, 0, 0), Model = "Objects/library/architecture/village/wall/concrete_wall_simple_4m.cgf" },
                { Pos = vector.new(8.099998, 20.925003, 0.025002000000001), Dir = vector.new(-0.70710671, 0, 0), Model = "Objects/library/architecture/village/wall/concrete_wall_simple_4m.cgf" },
                { Pos = vector.new(35.699997, 37.662498, 0.025002000000001), Dir = vector.new(-0.70710671, 0, 0), Model = "Objects/library/architecture/village/wall/concrete_wall_simple_4m.cgf" },
                { Pos = vector.new(35.699997, 18.887501, 0.025002000000001), Dir = vector.new(-0.70710671, 0, 0), Model = "Objects/library/architecture/village/wall/concrete_wall_simple_4m.cgf" },
                { Pos = vector.new(35.699997, 28.262505, 0.025002000000001), Dir = vector.new(-0.70710671, 0, 0), Model = "Objects/library/architecture/village/wall/concrete_wall_simple_4m.cgf" },
                { Pos = vector.new(8.099987, 28.262512, -0.475), Dir = vector.new(-0.70710671, 0, 0), Model = "Objects/library/architecture/village/wall/concrete_wall_simple_gate_4m.cgf" },
                { Pos = vector.new(8.099987, 18.88752, -0.475), Dir = vector.new(-0.70710671, 0, 0), Model = "Objects/library/architecture/village/wall/concrete_wall_simple_gate_4m.cgf" },
                { Pos = vector.new(8.099987, 37.662514, -0.475), Dir = vector.new(-0.70710671, 0, 0), Model = "Objects/library/architecture/village/wall/concrete_wall_simple_gate_4m.cgf" },
                { Pos = vector.new(39.700005, 20.925003, 0.025002000000001), Dir = vector.new(-0.70710671, 0, 0), Model = "Objects/library/architecture/village/wall/concrete_wall_simple_4m.cgf" },
                { Pos = vector.new(39.699989, 18.887512, -0.475), Dir = vector.new(-0.70710671, 0, 0), Model = "Objects/library/architecture/village/wall/concrete_wall_simple_gate_4m.cgf" },
                { Pos = vector.new(39.699989, 28.26252, -0.475), Dir = vector.new(-0.70710671, 0, 0), Model = "Objects/library/architecture/village/wall/concrete_wall_simple_gate_4m.cgf" },
                { Pos = vector.new(39.700005, 30.300003, 0.025002000000001), Dir = vector.new(-0.70710671, 0, 0), Model = "Objects/library/architecture/village/wall/concrete_wall_simple_4m.cgf" },
                { Pos = vector.new(39.699989, 37.662514, -0.475), Dir = vector.new(-0.70710671, 0, 0), Model = "Objects/library/architecture/village/wall/concrete_wall_simple_gate_4m.cgf" },
                { Pos = vector.new(39.700005, 39.712502, 0.025002000000001), Dir = vector.new(-0.70710671, 0, 0), Model = "Objects/library/architecture/village/wall/concrete_wall_simple_4m.cgf" },
                { Pos = vector.new(29.124992, 28.299995, -0.65), Dir = vector.new(-1, 0, 0), Model = "Objects/library/architecture/village/wall/concrete_wall_simple_end_destroyed_high.cgf" },
                { Pos = vector.new(29.124985, 27.974991, -0.65), Dir = vector.new(1, 0, 0), Model = "Objects/library/architecture/village/wall/concrete_wall_simple_end_destroyed_high.cgf" },
                { Pos = vector.new(18.649986, 27.974991, -0.65), Dir = vector.new(1, 0, 0), Model = "Objects/library/architecture/village/wall/concrete_wall_simple_end_destroyed_high.cgf" },
                { Pos = vector.new(18.649994, 28.299995, -0.65), Dir = vector.new(-1, 0, 0), Model = "Objects/library/architecture/village/wall/concrete_wall_simple_end_destroyed_high.cgf" },
                { Pos = vector.new(21.375004, 17.712505, 2.699999), Dir = vector.new(0, 1, 0), Model = "Objects/library/architecture/village/wall/concrete_wall_simple_4m_destroyed_high.cgf" },
                { Pos = vector.new(21.375004, 27.075001, 2.699999), Dir = vector.new(0, 1, 0), Model = "Objects/library/architecture/village/wall/concrete_wall_simple_4m_destroyed_high.cgf" },
                { Pos = vector.new(21.375004, 36.537506, 2.699999), Dir = vector.new(0, 1, 0), Model = "Objects/library/architecture/village/wall/concrete_wall_simple_4m_destroyed_high.cgf" },
                { Pos = vector.new(26.725006, 17.6875, 2.699999), Dir = vector.new(0, 1, 0), Model = "Objects/library/architecture/village/wall/concrete_wall_simple_4m_destroyed_high.cgf" },
                { Pos = vector.new(26.725006, 27.075001, 2.699999), Dir = vector.new(0, 1, 0), Model = "Objects/library/architecture/village/wall/concrete_wall_simple_4m_destroyed_high.cgf" },
                { Pos = vector.new(26.725006, 36.5625, 2.699999), Dir = vector.new(0, 1, 0), Model = "Objects/library/architecture/village/wall/concrete_wall_simple_4m_destroyed_high.cgf" },
                { Pos = vector.new(26.725002, 38.562492, 0.075001), Dir = vector.new(0, 1, 0), Model = "Objects/library/architecture/village/wall/concrete_wall_simple_4m.cgf" },
                { Pos = vector.new(26.725002, 19.687489, 0.075001), Dir = vector.new(0, 1, 0), Model = "Objects/library/architecture/village/wall/concrete_wall_simple_4m.cgf" },
                { Pos = vector.new(26.725002, 29.074997, 0.075001), Dir = vector.new(0, 1, 0), Model = "Objects/library/architecture/village/wall/concrete_wall_simple_4m.cgf" },
                { Pos = vector.new(21.374996, 38.537491, 0.075001), Dir = vector.new(0, 1, 0), Model = "Objects/library/architecture/village/wall/concrete_wall_simple_4m.cgf" },
                { Pos = vector.new(21.374996, 29.074997, 0.075001), Dir = vector.new(0, 1, 0), Model = "Objects/library/architecture/village/wall/concrete_wall_simple_4m.cgf" },
                { Pos = vector.new(21.374996, 19.712494, 0.075001), Dir = vector.new(0, 1, 0), Model = "Objects/library/architecture/village/wall/concrete_wall_simple_4m.cgf" },

            }
        },
    },

    --------------------
    Init = function(self)

        LinkEvent(eServerEvent_OnClientInit, "ServerArena", self.InitClient)
        LinkEvent(eServerEvent_OnClientTick, "ServerArena", self.CheckPlayer)
    end,

    --------------------
    InitClient = function(self, hClient)

        table.checkM(hClient, "ArenaInfo", {
            ID = nil,
            LastInside = nil
        })

        hClient:AddInstantRevive("Arena", function(this)
            return (this.ArenaInfo.ID ~= nil)
        end)
        hClient:AddSpawnLocation("Arena", {

            OnUsed = function(hPlayer)
                ServerArena:OnEntered(hPlayer, hPlayer.ArenaInfo.ID)
            end,

            Check = function(this, hPlayer)
                local hID = hPlayer.ArenaInfo.ID
                if (hID) then
                    local vPos, vDir = ServerArena:GetSpawnLocation(hPlayer, hID)
                    this.Pos = vPos
                    this.Dir = vDir
                end
                return hID ~= nil
            end,

            Priority = 1,
            Pos      = nil,
            Dir      = nil,
        })
    end,

    --------------------
    Init = function(self)

        LinkEvent(eServerEvent_OnClientInit, "ServerArena", self.InitClient)
        LinkEvent(eServerEvent_OnClientTick, "ServerArena", self.CheckPlayer)
    end,

    --------------------
    InitClient = function(self, hClient)

        table.checkM(hClient, "ArenaInfo", {
            ID = nil,
            LastInside = nil
        })

        hClient:AddInstantRevive("Arena", function(this)
            return (this.ArenaInfo.ID ~= nil)
        end)
        hClient:AddSpawnLocation("Arena", {

            OnUsed = function(hPlayer)
                ServerArena:OnEntered(hPlayer, hPlayer.ArenaInfo.ID)
            end,

            Check = function(this, hPlayer)
                local hID = hPlayer.ArenaInfo.ID
                if (hID) then
                    local vPos, vDir = ServerArena:GetSpawnLocation(hPlayer, hID)
                    this.Pos = vPos
                    this.Dir = vDir
                end
                return hID ~= nil
            end,

            Priority = 1,
            Pos      = nil,
            Dir      = nil,
        })
    end,

    --------------------
    CheckArena = function(self, hID)

        local bExists = self:ArenaExists(hID)
        if (not bExists) then
            self:SpawnArena(hID)
        end

    end,

    --------------------
    SpawnArena = function(self, hID)

        local bExists = self:ArenaExists(hID)
        if (bExists) then
            self:DeleteParts(hID)
        end

        local sClass = "GUI"
        local iScale = 1.25


        local aInfo = self.Data[hID]
        local vPos = {
            x = 100,
            y = 100,
            z = 1000 + (hID * 250)
        }

        local aBBox = {
            min = vector.scaleInPlace(aInfo.BBox.min, iScale),
            max = vector.scaleInPlace(aInfo.BBox.max, iScale)
        }

        aBBox.min = vector.addInPlace(aBBox.min, vPos)
        aBBox.max = vector.addInPlace(aBBox.max, vPos)


        self.Temp[hID] = {
            BBox    = aBBox,
            Pos     = vPos,
            Parts   = {},
            EmptyTimer = timernew(60)
        }
        local aParts = aInfo.Parts
        for _, aPart in pairs(table.copy(aParts)) do

            self.Temp[hID].Parts[_] = SpawnGUI({

                Model = aPart.Model,
                Pos = vector.addInPlace(vPos, vector.scaleInPlace(aPart.Pos, iScale)),
                Dir = aPart.Dir,
                Physics = true,
                Rigid = false,
                Mass = -1,
                Resting = true,
                Scale = iScale + (aPart.Scale or 0),
                Network = true
            })

            self.Temp[hID].Parts[_].IsArenaPart = true
            self.Temp[hID].Parts[_].IsImportant = true
        end

    end,

    --------------------
    ArenaExists = function(self, hID)

        local aParts = self.Temp[hID]
        if (not aParts or table.empty(aParts.Parts)) then
            return false
        end

        for _, aID in pairs(aParts.Parts) do
            if (not GetEntity(aID)) then
                self:DeleteParts(hID)
                return false
            end
        end

        return true
    end,

    --------------------
    DeleteParts = function(self, hID)

        local aParts = self.Temp[hID]
        if (not aParts or table.empty(aParts.Parts)) then
            return false
        end

        for _, aID in pairs(aParts.Parts) do
            if (aID and GetEntity(aID.id) and GetEntity(aID.id).IsArenaPart) then
                System.RemoveEntity(aID.id)
            end
        end

        self.Temp[hID] = nil
        return true
    end,

    --------------------
    EnterArena = function(self, hUser, hID)

        local hCurrent = hUser.ArenaInfo.ID
        if (hCurrent ~= nil) then
            self:Leave(hUser, hCurrent)
        end

        if (hID == eARENA_BOXING) then
            return self:Enter(hUser, eARENA_BOXING)
        end
    end,

    --------------------
    OnEntered = function(self, hUser, hID)

        if (not hID) then
            return --Debug("NOPE! no ID!")
        end

        local aInfo = self.Data[hID]
        local sName = string.format(aInfo.Name, hID)


        AddServerStat(_G["eServerStat_Arena" .. hID], 1)
        SendMsg(CHAT_SERVER_LOCALE, ALL_PLAYERS, "@l_ui_userEnteredArena", hUser:GetName(), sName, GetServerStat(_G["eServerStat_Arena" .. hID]))
    end,

    --------------------
    Enter = function(self, hUser, hID)

        local hCurrent = hUser.ArenaInfo.ID
        if (hCurrent) then
            self:Leave(hUser, hID)
            if (hCurrent == hID) then
                return
            end
        end

        if (not self.Data[hID]) then
            return false, hUser:Localize("@l_ui_invalidArena")
        end

        hUser.ArenaInfo.BeforePosition = nil
        if (hUser:IsAlive() and not hUser:IsSpectating()) then
            hUser.ArenaInfo.BeforePosition = {
                hUser:GetWorldPos(),
                hUser:GetAngles()
            }
        end
        hUser.ArenaInfo.ID = hID
        hUser.ArenaInfo.LastInside = nil
        self:CheckArena(hID)
        self:CheckPlayer(hUser) -- equipment tick
        self:OnEntered(hUser, hID)

        if (not hUser:IsSpectating()) then
            self:TeleportPlayer(hUser, hID)
        end
    end,

    --------------------
    Leave = function(self, hUser, hID)

        hUser.ArenaInfo.ID = nil

        local aPos = hUser.ArenaInfo.BeforePosition
        if (hUser:IsDead() or not aPos) then
            g_gameRules:RevivePlayer(hUser:GetChannel(), hUser, true)
        else
            hUser:SvMoveTo(unpack(hUser.ArenaInfo.BeforePosition))
        end

        local aInfo = self.Data[hID]
        local sName = string.format(aInfo.Name, hID)

        SendMsg(CHAT_SERVER_LOCALE, ALL_PLAYERS, "@l_ui_userLeftArena", hUser:GetName(), (sName or "@l_ui_arena"))
    end,

    --------------------
    CheckArenas = function(self, hUser)

        for hID, aTemp in pairs(self.Temp) do
            if (self:GetArenaPlayers(hID) == 0) then
                if (aTemp.EmptyTimer.expired(30)) then
                    self:DeleteParts(hID)
                end
            else
                aTemp.EmptyTimer.refresh()
            end
        end

    end,

    --------------------
    GetArenaPlayers = function(self, hID)
        local iPlayers = 0
        for _, hPlayer in pairs(GetPlayers()) do
            if (hPlayer.ArenaInfo.ID == hID) then
                iPlayers = iPlayers + 1
            end
        end
        return iPlayers
    end,

    --------------------
    CheckPlayer = function(self, hUser)

        local hID = hUser.ArenaInfo.ID
        if (not hID) then
            return
        end

        self:CheckArena(hID)

        local vPos = hUser:GetPos()
        local BBox = self.Temp[hID].BBox
        local vArena = self.Temp[hID].Pos

        --Debug(BBox)
        --Debug(vPos)

        if (not vector.bbox_inside(BBox, vPos)) then
            local vInside = vector.bbox_closestpoint(BBox, vPos, 10)
            vInside.z = vArena.z + 1
            self:TeleportPlayer(hUser, hID, vInside)
        else
            hUser.ArenaInfo.LastInside = vPos
        end

        local aInfo = self.Data[hID]
        if (aInfo.Equipment) then
            for _, hItem in pairs(hUser:GetInventory()) do
                if (not table.findv(aInfo.Equipment, hItem.class)) then
                    System.RemoveEntity(hItem.id)
                    hUser:SelectItem("Fists")
                end
            end
        end
    end,

    --------------------
    TeleportPlayer = function(self, hUser, hID, vPos)

        local vLocation, vDir = self:GetSpawnLocation(hUser, hID)
        if (vPos) then vLocation = vPos end

        hUser:SvMoveTo(vLocation, vDir)
        SpawnEffect(ePE_Light, vLocation)
    end,

    --------------------
    GetSpawnLocation = function(self, hUser, hID)

        local aBBox   = self.Temp[hID].BBox
        local vArena  = self.Temp[hID].Pos
        local vRandom = vector.bbox_randomedge(aBBox, 3) vRandom.z = vArena.z + 1
        local vFacing = vector.getdir(vector.bbox_center(aBBox, vArena.z + 1), vRandom, 1)

        local hPlayer = self:GetFirstPlayer(hID, hUser)
        if (hPlayer) then
            vFacing = vector.getdir(hPlayer:GetPos(), vRandom, 1)
        end

        return vRandom, vector.toang(vFacing)
    end,

    --------------------
    GetFirstPlayer = function(self, hID, hUser)

        local vUser = hUser:GetPos()

        local aNearest = { -1 }
        for _, hPlayer in pairs(GetPlayers()) do
            if (hPlayer.id ~= hUser.id and not hPlayer:IsSpectating() and hPlayer.ArenaInfo.ID == hID) then
                local iDistance = vector.distance(vUser, hPlayer:GetPos())
                if (aNearest[1] == -1 or aNearest[1] > iDistance) then
                    aNearest[2] = hPlayer
                end
            end
        end
        return aNearest[2]
    end,
}

ServerArena:Init()