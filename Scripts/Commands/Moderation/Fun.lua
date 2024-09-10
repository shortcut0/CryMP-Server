------------
AddCommand({
    Name = "jetpack",
    Access = RANK_MODERATOR,

    Arguments = {
        {
            Name = "@l_ui_player",
            Desc = "@l_ui_player_d",
            Required = true,
            IsPlayer = true,
            AllOk = true,
            SelfOk = true,
        },
    },

    Properties = {
    },

    -- self is the user unless specified otherwise
    Function = function(self, hPlayer)

        if (hPlayer == ALL_PLAYERS) then
            if (not ClientMod.JETPACKS_ENABLED) then
                ClientMod.JETPACKS_ENABLED = true
            else
                ClientMod.JETPACKS_ENABLED = false
            end

            --return true, self:Localize("@l_ui_jetPackParty", { ClientMod.JETPACKS_ENABLED and "@l_ui_enabled" or "@l_ui_disabled" })
            return true, self:LocalizeNest("@l_ui_jetPackPlayer", { "@l_ui_allPlayers", ClientMod.JETPACKS_ENABLED and "@l_ui_enabled" or "@l_ui_disabled" })
        end

        local sPlayer = (hPlayer == self and "@l_ui_you" or hPlayer:GetName())
        if (hPlayer.HasJetPack) then
            ClientMod:RemoveJetpack(hPlayer)
        else
            if (hPlayer:IsDead() or hPlayer:IsSpectating()) then
                return false, self:Localize("@l_ui_targetNotAlive", { sPlayer })
            end
            ClientMod:EquipJetpack(hPlayer)
        end

        if (hPlayer ~= self) then
            SendMsg(CHAT_SERVER, hPlayer, hPlayer:Localize("@l_ui_jetPackEquipped", { hPlayer.HasJetPack and "@l_ui_enabled" or "@l_ui_disabled" }))
        end
        return true, self:Localize("@l_ui_jetPackPlayer", { sPlayer, hPlayer.HasJetPack and "@l_ui_enabled" or "@l_ui_disabled" })
    end
})

------------
AddCommand({
    Name = "chair",
    Access = RANK_MODERATOR,

    Arguments = {
        {
            Name = "@l_ui_index",
            Desc = "@l_ui_index_d",
            IsNumber = true,
            Optional = true
        },
    },

    Properties = {
    },

    -- self is the user unless specified otherwise
    Function = function(self, hID)

        local aList = {
            { Name = "Chair",            Model = "Objects/library/architecture/aircraftcarrier/props/furniture/chairs/console_chair.cgf" },
            { Name = "Chair 2",          Model = "Objects/library/furniture/chairs/cafe_chair_frozen.cgf" },
            { Name = "Wooden Bank",      Model = "objects/library/furniture/chairs/bank_wooden_01.cgf" },
            { Name = "Wooden Chair",     Model = "objects/library/furniture/chairs/chair_wooden_01.cgf" },
            { Name = "Office Chair",     Model = "objects/library/furniture/chairs/office_chair.cgf" },
            { Name = "Cafe Chair",       Model = "objects/library/furniture/chairs/hillside_cafe_chair_bar.cgf" },
            { Name = "Couch",            Model = "objects/library/furniture/chairs/hillside_cafe_couch.cgf" },
            { Name = "Captains Chair",   Model = "Objects/library/architecture/aircraftcarrier/props/furniture/chairs/captains_chair.cgf" },
            { Name = "Captains Chair 2", Model = "objects/library/architecture/aircraftcarrier/props/furniture/chairs/captains_loungechair.cgf" },
            { Name = "Chair 3",          Model = "objects/library/architecture/aircraftcarrier/props/furniture/chairs/console_chair_bag.cgf" },
            { Name = "Toilet",           Model = "Objects/library/installations/sanitary/toilet.cgf" },
            { Name = "FranceToilet",     Model = "objects/library/installations/sanitary/france_toilet.cgf" }
        }

        local aInfo = (aList)[hID or -1]
        if (not aInfo) then
            ListToConsole({
                Client      = self,
                List        = aList,
                Title       = self:Localize("@l_ui_entityList"),
                ItemWidth   = 15,
                PerLine     = 6,
                Index       = "Name"
            })
            return true, self:Localize("@l_ui_entitiesListedInConsole", { table.count(aList) })
        end

        local hChair = SpawnGUI({
            Pos = self:GetFacingPos(eFacing_Front, 1.25, eFollow_Auto, 0.2),
            Dir = self:SmartGetDir(1),
            Model = aInfo.Model,
            Physics = true,
            Mass = 300,
            Rigid = true,
            Resting = false,
            Network = true
        })

        hChair.SvPickup = function(this, hUser, bForceOff)

            if (this.Rider == nil and not bForceOff) then

                if (hUser.Chair) then
                    hUser.Chair:SvPickup(hUser, true)
                end

                ClientMod:OnAll(string.format([[g_Client:CHAIR(%d,"%s",true)]], hUser:GetChannel(),this:GetName()), {
                    Sync = true,
                    SyncID = "mountchair",
                    BindID = hUser.id,
                    Dependencies = { hUser.id, this.id }
                })

                Debug("MOUNT")
                this.Rider = hUser
                this:EnablePhysics(false)
                this:DestroyPhysics()
                hUser.Chair = this

            elseif (bForceOff or this.Rider == hUser) then

                Debug("DISMOUNT!")
                ClientMod:OnAll(string.format([[g_Client:CHAIR(%d,"%s",false)]], hUser:GetChannel(),this:GetName()))
                ClientMod:StopSync(hUser, "mountchair")
                this.Rider = nil
                this:Physicalize(0, PE_RIGID, { mass = 300 })
                this:EnablePhysics(true)
                this:SetWorldPos(hUser:GetPos())
                hUser.Chair = nil
            end
        end

        return true, self:Localize("@l_ui_hereIsYour", { "@l_ui_flying " .. aInfo.Name })
    end
})

------------
AddCommand({
    Name = "spawnjet",
    Access = RANK_MODERATOR,

    Arguments = {
        {
            Name = "@l_ui_index",
            Desc = "@l_ui_index_d",
            IsNumber = true,
            Optional = true
        },
    },

    Properties = {
    },

    -- self is the user unless specified otherwise
    Function = function(self, hID)

        local aList = {
            { Name = "US Fighter", ID = VM_USPLANE },
            { Name = "NK Fighter", ID = VM_NKPLANE },
            { Name = "Epic 1000", ID = VM_AIRCRAFT },
            { Name = "Cargo Plane", ID = VM_CARGOPLANE },
        }
        local aInfo = (aList)[hID or -1]
        if (not aInfo) then
            ListToConsole({
                Client      = self,
                List        = aList,
                Title       = self:Localize("@l_ui_entityList"),
                ItemWidth   = 15,
                PerLine     = 6,
                Index       = "Name"
            })
            return true, self:Localize("@l_ui_entitiesListedInConsole", { table.count(aList) })
        end
        return ClientMod:ChangeVehicleModel(self, "US_vtol", aInfo.ID)
    end
})

------------
AddCommand({
    Name = "spawnhouse",
    Access = RANK_MODERATOR,

    Arguments = {
        {
            Name = "@l_ui_index",
            Desc = "@l_ui_index_d",
            IsNumber = true,
            Optional = true
        },
    },

    Properties = {
    },

    -- self is the user unless specified otherwise
    Function = function(self, hID)

        local aList = {
            {
                Name = "Terminal Building",
                Parts = {
                    "objects/library/architecture/airfield/terminal_building_b/exterior.cgf",
                    "objects/library/architecture/airfield/terminal_building_b/interior.cgf",
                    "objects/library/architecture/airfield/terminal_building_b/roof.cgf",
                    "objects/library/architecture/airfield/terminal_building_b/walls_first_floor.cgf",
                    "objects/library/architecture/airfield/terminal_building_b/walls_ground_floor.cgf"
                }
            },
            {
                Name = "Terminal Building 2",
                Parts = {
                    "objects/library/architecture/airfield/terminal/ext_departure_canopy.cgf";
                    "objects/library/architecture/airfield/terminal/ext_entrance_roof.cgf";
                    "objects/library/architecture/airfield/terminal/ext_entrance_supports.cgf";
                    "objects/library/architecture/airfield/terminal/ext_floor.cgf";
                    "objects/library/architecture/airfield/terminal/ext_mainwall.cgf";
                    "objects/library/architecture/airfield/terminal/ext_pillars1.cgf";
                    "objects/library/architecture/airfield/terminal/ext_pillars2.cgf";
                    "objects/library/architecture/airfield/terminal/ext_pillars3.cgf";
                    "objects/library/architecture/airfield/terminal/ext_pillars4.cgf";
                    "objects/library/architecture/airfield/terminal/ext_roof.cgf";
                    "objects/library/architecture/airfield/terminal/ext_simplepillars.cgf";
                    "objects/library/architecture/airfield/terminal/ext_stairs_departure.cgf";
                    "objects/library/architecture/airfield/terminal/ext_topwindowframe.cgf";
                    "objects/library/architecture/airfield/terminal/ext_walkway1.cgf";
                    "objects/library/architecture/airfield/terminal/ext_walkway1_pillars.cgf";
                    "objects/library/architecture/airfield/terminal/ext_walkway1_railing.cgf";
                    "objects/library/architecture/airfield/terminal/ext_walkway2.cgf";
                    "objects/library/architecture/airfield/terminal/ext_walkway2_pillars.cgf";
                    "objects/library/architecture/airfield/terminal/ext_walkway2_railing.cgf";
                    "objects/library/architecture/airfield/terminal/ext_windowframes_cafe.cgf";
                    "objects/library/architecture/airfield/terminal/ext_windowframes_departure.cgf";
                    "objects/library/architecture/airfield/terminal/ext_windowframes_depstairs.cgf";
                    "objects/library/architecture/airfield/terminal/ext_windowframes_entrance.cgf";
                    "objects/library/architecture/airfield/terminal/ext_windowframes_helpdesk.cgf";
                    "objects/library/architecture/airfield/terminal/ext_windowframes_walkway2.cgf";
                    "objects/library/architecture/airfield/terminal/int_2ndfloor.cgf";
                    "objects/library/architecture/airfield/terminal/int_2ndfloor_corner1.cgf";
                    "objects/library/architecture/airfield/terminal/int_2ndfloor_corner2.cgf";
                    "objects/library/architecture/airfield/terminal/int_2ndfloor_railing.cgf";
                    "objects/library/architecture/airfield/terminal/int_doorframe.cgf";
                    "objects/library/architecture/airfield/terminal/int_doorframe01.cgf";
                    "objects/library/architecture/airfield/terminal/int_doorframe02.cgf";
                    "objects/library/architecture/airfield/terminal/int_doorframe03.cgf";
                    "objects/library/architecture/airfield/terminal/int_doorframe04.cgf";
                    "objects/library/architecture/airfield/terminal/int_doorframe05.cgf";
                    "objects/library/architecture/airfield/terminal/int_doorframe06.cgf";
                    "objects/library/architecture/airfield/terminal/int_entrance_roof.cgf";
                    --"objects/library/architecture/airfield/terminal/int_floor.cgf";
                    "objects/library/architecture/airfield/terminal/int_floor1.cgf";
                    "objects/library/architecture/airfield/terminal/int_floor2.cgf";
                    "objects/library/architecture/airfield/terminal/int_floor3.cgf";
                    "objects/library/architecture/airfield/terminal/int_floor4.cgf";
                    "objects/library/architecture/airfield/terminal/int_floor5.cgf";
                    "objects/library/architecture/airfield/terminal/int_floor6.cgf";
                    "objects/library/architecture/airfield/terminal/int_floor7.cgf";
                    "objects/library/architecture/airfield/terminal/int_floor8.cgf";
                    "objects/library/architecture/airfield/terminal/int_floor9.cgf";
                    "objects/library/architecture/airfield/terminal/int_floor10.cgf";
                    "objects/library/architecture/airfield/terminal/int_floor11.cgf";
                    "objects/library/architecture/airfield/terminal/int_floor12.cgf";
                    "objects/library/architecture/airfield/terminal/int_floor13.cgf";
                    "objects/library/architecture/airfield/terminal/int_floor14.cgf";
                    "objects/library/architecture/airfield/terminal/int_floor15.cgf";
                    "objects/library/architecture/airfield/terminal/int_floor16.cgf";
                    "objects/library/architecture/airfield/terminal/int_floor17.cgf";
                    "objects/library/architecture/airfield/terminal/int_floor18.cgf";
                    "objects/library/architecture/airfield/terminal/int_floor19.cgf";
                    "objects/library/architecture/airfield/terminal/int_floor20.cgf";
                    "objects/library/architecture/airfield/terminal/int_floor21.cgf";
                    "objects/library/architecture/airfield/terminal/int_floor22.cgf";
                    "objects/library/architecture/airfield/terminal/int_floor23.cgf";
                    "objects/library/architecture/airfield/terminal/int_floor24.cgf";
                    "objects/library/architecture/airfield/terminal/int_floor25.cgf";
                    "objects/library/architecture/airfield/terminal/int_floor26.cgf";
                    "objects/library/architecture/airfield/terminal/int_floor27.cgf";
                    "objects/library/architecture/airfield/terminal/int_floor28.cgf";
                    "objects/library/architecture/airfield/terminal/int_floor29.cgf";
                    "objects/library/architecture/airfield/terminal/int_floor30.cgf";
                    "objects/library/architecture/airfield/terminal/int_floor31.cgf";
                    "objects/library/architecture/airfield/terminal/int_floor32.cgf";
                    "objects/library/architecture/airfield/terminal/int_floor33.cgf";
                    "objects/library/architecture/airfield/terminal/int_floor34.cgf";
                    "objects/library/architecture/airfield/terminal/int_floor35.cgf";
                    "objects/library/architecture/airfield/terminal/int_floor36.cgf";
                    "objects/library/architecture/airfield/terminal/int_floor37.cgf";
                    "objects/library/architecture/airfield/terminal/int_floor38.cgf";
                    "objects/library/architecture/airfield/terminal/int_floor39.cgf";
                    "objects/library/architecture/airfield/terminal/int_floor40.cgf";
                    "objects/library/architecture/airfield/terminal/int_floor41.cgf";
                    "objects/library/architecture/airfield/terminal/int_floor42.cgf";
                    "objects/library/architecture/airfield/terminal/int_floor43.cgf";
                    "objects/library/architecture/airfield/terminal/int_floor44.cgf";
                    "objects/library/architecture/airfield/terminal/int_floor45.cgf";
                    "objects/library/architecture/airfield/terminal/int_floor46.cgf";
                    "objects/library/architecture/airfield/terminal/int_floor47.cgf";
                    "objects/library/architecture/airfield/terminal/int_gardenframe.cgf";
                    "objects/library/architecture/airfield/terminal/int_giftshop_shelf1.cgf";
                    "objects/library/architecture/airfield/terminal/int_giftshop_shelf2.cgf";
                    "objects/library/architecture/airfield/terminal/int_giftshop_shelf3.cgf";
                    "objects/library/architecture/airfield/terminal/int_giftshop_shelf4.cgf";
                    "objects/library/architecture/airfield/terminal/int_luggagerack.cgf";
                    "objects/library/architecture/airfield/terminal/int_mainwall.cgf";
                    "objects/library/architecture/airfield/terminal/int_pillars1.cgf";
                    "objects/library/architecture/airfield/terminal/int_pillars4.cgf";
                    "objects/library/architecture/airfield/terminal/int_roof.cgf";
                    "objects/library/architecture/airfield/terminal/int_shop1_shelf1.cgf";
                    "objects/library/architecture/airfield/terminal/int_shop1_shelf2.cgf";
                    "objects/library/architecture/airfield/terminal/int_shop1_shelf3.cgf";
                    "objects/library/architecture/airfield/terminal/int_shop2_freezer.cgf";
                    "objects/library/architecture/airfield/terminal/int_shop2_shelf1.cgf";
                    "objects/library/architecture/airfield/terminal/int_shop2_shelf2.cgf";
                    "objects/library/architecture/airfield/terminal/int_shop2_shelf3.cgf";
                    "objects/library/architecture/airfield/terminal/int_sign_toilets.cgf";
                    "objects/library/architecture/airfield/terminal/int_simplepillars.cgf";
                    "objects/library/architecture/airfield/terminal/int_stairs.cgf";
                    --"objects/library/architecture/airfield/terminal/int_stairs_railing.cgf";
                    "objects/library/architecture/airfield/terminal/int_supports1.cgf";
                    "objects/library/architecture/airfield/terminal/int_toiletmen_stalls.cgf";
                    "objects/library/architecture/airfield/terminal/int_toiletwomen_stalls.cgf";
                    "objects/library/architecture/airfield/terminal/int_walls1.cgf";
                    "objects/library/architecture/airfield/terminal/int_walls2.cgf";
                    "objects/library/architecture/airfield/terminal/int_walls3.cgf";
                    "objects/library/architecture/airfield/terminal/int_walls4.cgf";
                    "objects/library/architecture/airfield/terminal/int_walls5.cgf";
                    "objects/library/architecture/airfield/terminal/int_walls6.cgf";
                    "objects/library/architecture/airfield/terminal/int_walls7.cgf";
                    "objects/library/architecture/airfield/terminal/int_windowframes_cafe.cgf";
                    "objects/library/architecture/airfield/terminal/int_windowframes_depstairs.cgf";
                    "objects/library/architecture/airfield/terminal/int_windowframes_entrance.cgf";
                    "objects/library/architecture/airfield/terminal/int_windowframes_helpdesk.cgf";
                    "objects/library/architecture/airfield/terminal/int_windowframes_walkway2.cgf"
                }
            },
            {
                Name = "Power Building",
                Parts = {
                    "objects/library/architecture/airfield/powerbuilding/powerbuilding.cgf";
                    "objects/library/architecture/airfield/powerbuilding/powerbuilding_interior.cgf"
                }
            },
            {
                Name = "Control Tower",
                Parts = {
                    "objects/library/architecture/airfield/air_control_tower/air_control_tower_mp.cgf"
                }
            },
            {
                Name = "Control Tower 2",
                Parts = {
                    "objects/library/architecture/airfield/air_control_tower/control_tower_b.cgf"
                }
            },
            {
                Name = "Control Tower 3",
                Parts = {
                    "objects/library/architecture/airfield/air_control_tower/air_control_tower_mockup.cgf"
                }
            },
            {
                Name = "Contol Tower 4",
                Parts = {
                    "objects/library/architecture/airfield/air_control_tower_b/air_control_tower_b.cgf"
                }
            },
            {
                Name = "Control Center",
                Parts = {
                    "objects/library/architecture/harbour/control_center/harbor_control_center.cgf";
                    "objects/library/architecture/harbour/control_center/harbor_control_center_arch.cgf";
                    "objects/library/architecture/harbour/control_center/harbor_control_center_arch01.cgf";
                    "objects/library/architecture/harbour/control_center/harbor_control_center_arch02.cgf";
                    "objects/library/architecture/harbour/control_center/harbor_control_center_big_room.cgf";
                    "objects/library/architecture/harbour/control_center/harbor_control_center_big_room_detail.cgf";
                    "objects/library/architecture/harbour/control_center/harbor_control_center_big_room_lamp.cgf";
                    "objects/library/architecture/harbour/control_center/harbor_control_center_decals.cgf";
                    "objects/library/architecture/harbour/control_center/harbor_control_center_detail.cgf";
                    "objects/library/architecture/harbour/control_center/harbor_control_center_drawing.cgf";
                    "objects/library/architecture/harbour/control_center/harbor_control_center_frame01.cgf";
                    "objects/library/architecture/harbour/control_center/harbor_control_center_frame02.cgf";
                    "objects/library/architecture/harbour/control_center/harbor_control_center_frame03.cgf";
                    "objects/library/architecture/harbour/control_center/harbor_control_center_fun.cgf";
                    "objects/library/architecture/harbour/control_center/harbor_control_center_garret.cgf";
                    "objects/library/architecture/harbour/control_center/harbor_control_center_garret_detail.cgf";
                    "objects/library/architecture/harbour/control_center/harbor_control_center_garret_lamp.cgf";
                    "objects/library/architecture/harbour/control_center/harbor_control_center_glass.cgf";
                    "objects/library/architecture/harbour/control_center/harbor_control_center_glass_roof_long_a.cgf";
                    "objects/library/architecture/harbour/control_center/harbor_control_center_glass_roof_long_b.cgf";
                    "objects/library/architecture/harbour/control_center/harbor_control_center_glass_roof_long_c.cgf";
                    "objects/library/architecture/harbour/control_center/harbor_control_center_glass_roof_long_d.cgf";
                    "objects/library/architecture/harbour/control_center/harbor_control_center_glass_roof_long_e.cgf";
                    "objects/library/architecture/harbour/control_center/harbor_control_center_hall.cgf";
                    "objects/library/architecture/harbour/control_center/harbor_control_center_hall01.cgf";
                    "objects/library/architecture/harbour/control_center/harbor_control_center_hall01_detail.cgf";
                    "objects/library/architecture/harbour/control_center/harbor_control_center_hall01_lamp.cgf";
                    "objects/library/architecture/harbour/control_center/harbor_control_center_hall02.cgf";
                    "objects/library/architecture/harbour/control_center/harbor_control_center_hall02_detail.cgf";
                    "objects/library/architecture/harbour/control_center/harbor_control_center_hall_detail.cgf";
                    "objects/library/architecture/harbour/control_center/harbor_control_center_hall_lamp.cgf";
                    "objects/library/architecture/harbour/control_center/harbor_control_center_interior.cgf";
                    "objects/library/architecture/harbour/control_center/harbor_control_center_interior_detail.cgf";
                    "objects/library/architecture/harbour/control_center/harbor_control_center_interior_lamp.cgf";
                    "objects/library/architecture/harbour/control_center/harbor_control_center_kitchen01.cgf";
                    "objects/library/architecture/harbour/control_center/harbor_control_center_kitchen01_detail.cgf";
                    "objects/library/architecture/harbour/control_center/harbor_control_center_kitchen01_lamp.cgf";
                    "objects/library/architecture/harbour/control_center/harbor_control_center_room01.cgf";
                    "objects/library/architecture/harbour/control_center/harbor_control_center_room01_detail.cgf";
                    "objects/library/architecture/harbour/control_center/harbor_control_center_room01_lamp.cgf";
                    "objects/library/architecture/harbour/control_center/harbor_control_center_room02.cgf";
                    "objects/library/architecture/harbour/control_center/harbor_control_center_room02_detail.cgf";
                    "objects/library/architecture/harbour/control_center/harbor_control_center_room02_lamp.cgf";
                    "objects/library/architecture/harbour/control_center/harbor_control_center_seats.cgf";
                    "objects/library/architecture/harbour/control_center/harbor_control_center_stairs.cgf";
                    "objects/library/architecture/harbour/control_center/harbor_control_center_storage01.cgf";
                    "objects/library/architecture/harbour/control_center/harbor_control_center_toilet01.cgf";
                    "objects/library/architecture/harbour/control_center/harbor_control_center_toilet01_detail.cgf";
                    "objects/library/architecture/harbour/control_center/harbor_control_center_toilet01_detail_lamp.cgf";
                    "objects/library/architecture/harbour/control_center/harbor_control_center_toilet02.cgf";
                    "objects/library/architecture/harbour/control_center/harbor_control_center_toilet02_detail.cgf";
                    "objects/library/architecture/harbour/control_center/harbor_control_center_toilet02_detail_lamp.cgf";
                    "objects/library/architecture/harbour/control_center/harbor_control_center_toilet03.cgf";
                    "objects/library/architecture/harbour/control_center/harbor_control_center_toilet03_detail.cgf";
                    "objects/library/architecture/harbour/control_center/harbor_control_center_toilet04.cgf";
                    "objects/library/architecture/harbour/control_center/harbor_control_center_toilet04_detail.cgf";
                    "objects/library/architecture/harbour/control_center/harbor_control_center_toilet05.cgf";
                    "objects/library/architecture/harbour/control_center/harbor_control_center_toilet05_detail.cgf";
                    "objects/library/architecture/harbour/control_center/harbor_control_center_toilet06.cgf";
                    "objects/library/architecture/harbour/control_center/harbor_control_center_toilet06_detail.cgf"
                }
            },
            {
                Name = "Workshop",
                Parts = {
                    "objects/library/architecture/harbour/workshop/workshop.cgf";
                    "objects/library/architecture/harbour/workshop/workshop_2.cgf";
                    "objects/library/architecture/harbour/workshop/workshop_2_detail_breakable.cgf";
                    "objects/library/architecture/harbour/workshop/workshop_decal_door.cgf";
                    "objects/library/architecture/harbour/workshop/workshop_glass.cgf";
                    "objects/library/architecture/harbour/workshop/workshop_in.cgf";
                    "objects/library/architecture/harbour/workshop/workshop_in_crane.cgf"
                }
            },
            {
                Name = "Warehouse",
                Parts = {
                    "objects/library/architecture/harbour/warehouse/warehouse.cgf";
                    "objects/library/architecture/harbour/warehouse/warehouse_2.cgf";
                    "objects/library/architecture/harbour/warehouse/warehouse_base_rampa.cgf";
                    "objects/library/architecture/harbour/warehouse/warehouse_decal.cgf";
                    "objects/library/architecture/harbour/warehouse/warehouse_glass_big.cgf";
                    "objects/library/architecture/harbour/warehouse/warehouse_in.cgf";
                    "objects/library/architecture/harbour/warehouse/warehouse_kitchen.cgf";
                    "objects/library/architecture/harbour/warehouse/warehouse_kitchen_wall.cgf";
                    "objects/library/architecture/harbour/warehouse/warehouse_metal_shelter_cable.cgf";
                    "objects/library/architecture/harbour/warehouse/warehouse_metal_shelter.cgf";
                    "objects/library/architecture/harbour/warehouse/warehouse_room_01.cgf";
                    "objects/library/architecture/harbour/warehouse/warehouse_room_02.cgf";
                    "objects/library/architecture/harbour/warehouse/warehouse_room_03.cgf";
                    "objects/library/architecture/harbour/warehouse/warehouse_room_04_01.cgf";
                    "objects/library/architecture/harbour/warehouse/warehouse_room_5.cgf";
                    "objects/library/architecture/harbour/warehouse/warehouse_signs.cgf";
                    "objects/library/architecture/harbour/warehouse/warehouse_stairs.cgf";
                    "objects/library/architecture/harbour/warehouse/warehouse_stairs_02.cgf"
                }
            },
            {
                Name = "Motel",
                Parts = {
                    "objects/library/architecture/hillside_cafe/sleep_house_5_rooms.cgf"
                }
            },
            {
                Name = "Cafe",
                Parts = {
                    "objects/library/architecture/hillside_cafe/cafe_house.cgf",
                    "objects/library/architecture/hillside_cafe/terrace.cgf",
                    "objects/library/architecture/hillside_cafe/glass_01.cgf",
                    "objects/library/architecture/hillside_cafe/glass_02.cgf",
                    "objects/library/architecture/hillside_cafe/glass_03.cgf",
                    "objects/library/architecture/hillside_cafe/glass_04.cgf",
                    "objects/library/architecture/hillside_cafe/glass_05.cgf",
                    "objects/library/architecture/hillside_cafe/glass_06.cgf",
                    "objects/library/architecture/hillside_cafe/glass_07.cgf",
                    "objects/library/architecture/hillside_cafe/glass_08.cgf",
                    "objects/library/architecture/hillside_cafe/glass_09.cgf",
                    "objects/library/architecture/hillside_cafe/glass_10.cgf",
                    "objects/library/architecture/hillside_cafe/glass_11.cgf",
                    "objects/library/architecture/hillside_cafe/glass_12.cgf",
                    "objects/library/architecture/hillside_cafe/glass_13.cgf",
                    "objects/library/architecture/hillside_cafe/glass_14.cgf",
                    "objects/library/architecture/hillside_cafe/glass_15.cgf",
                }
            },
            {
                Name = "House 1",
                Parts = {
                    "objects/library/architecture/village/village_house1.cgf"
                }
            },
            {
                Name = "House 2",
                Parts = {
                    "objects/library/architecture/village/village_house2.cgf"
                }
            },
            {
                Name = "House 3",
                Parts = {
                    "objects/library/architecture/village/village_house3.cgf"
                }
            },
            {
                Name = "House 4",
                Parts = {
                    "objects/library/architecture/village/village_house4.cgf"
                }
            },
            {
                Name = "House 5",
                Parts = {
                    "objects/library/architecture/village/village_house5.cgf"
                }
            },
            {
                Name = "House 6",
                Parts = {
                    "objects/library/architecture/village/village_house6.cgf"
                }
            },
            {
                Name = "House 7",
                Parts = {
                    "objects/library/architecture/village/village_house7.cgf"
                }
            },
            {
                Name = "House 8",
                Parts = {
                    "objects/library/architecture/village/village_house8.cgf"
                }
            },
            {
                Name = "House 9",
                Parts = {
                    "objects/library/architecture/village/village_house9.cgf"
                }
            },
        }
        local aInfo = (aList)[hID or -1]
        if (not aInfo) then
            ListToConsole({
                Client      = self,
                List        = aList,
                Title       = self:Localize("@l_ui_entityList"),
                ItemWidth   = 20,
                PerLine     = 4,
                Index       = "Name"
            })
            return true, self:Localize("@l_ui_entitiesListedInConsole", { table.count(aList) })
        end

        local hPart
        local vPos = self:GetPos()
        local vDir = self:SmartGetDir(1)
        for _, sModel in pairs(aInfo.Parts) do
            hPart = SpawnGUI({
                Model = sModel,
                Pos = vPos,
                Dir = vDir,
                Physics = true,
                Rigid = false,
                Mass = 0,
                Resting = 1,
                Network = true
            })

            g_pGame:ScheduleEntityRemoval(hPart.id, 600, false)
        end
        return true, self:Localize("@l_ui_hereIsYour", {aInfo.Name})
    end
})

------------
AddCommand({
    Name = "vehiclemg",
    Access = RANK_MODERATOR,

    Arguments = {
        { "@l_ui_ItemClass", "@l_ui_ItemClass_d", Optional = true, Default = "Hurricane" }
    },

    Properties = {
    },

    -- self is the user unless specified otherwise
    Function = function(self, sItem)

        -- Cool classes to choose
        -- Asian_coaxialgun

        local sClass, sError = ServerUtils.FindItemByClass(self, sItem)
        if (not sClass) then
            return false, sError
        end

        Script.SetTimer(1, function()
            local hVehicle = self:GetVehicle() or SvSpawnEntity({
                Class = "Civ_car1",
                Pos = self:GetFacingPos(eFacing_Front, 8),
                Dir = self:SmartGetDir(1)
            })

            if (hVehicle.HeliMGs) then
                SendMsg(CHAT_SERVER, self, self:Localize("@l_ui_xRemoved", {"Mounted Miniguns"}))
                hVehicle:DeleteHeliMGs()
                if (sClass == hVehicle.HeliMGClass) then
                    return
                end
            end

            Script.SetTimer(1, function()
                SendMsg(CHAT_SERVER, self, self:Localize("@l_ui_hereIsYour", {"Mounted Miniguns"}))
                hVehicle:AttachHeliMGs(sClass)
            end)
        end)

    end
})