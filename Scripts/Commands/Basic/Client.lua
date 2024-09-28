------------
AddCommand({
    Name = "clerr",
    Access = GetLowestRank(), -- Must be accessible to all!

    Arguments = {
        {"",""},
        {"","",Concat=true}
    },

    Properties = {
        Hidden = true,
        NoChatResponse = true,
        NoConsoleResponse = true,
        Quiet = true
    },

    -- self is the user unless specified otherwise
    Function = function(self, sType, sMessage)
        ClientMod:OnClientError(self, sType, sMessage)
        return true
    end
})

------------
AddCommand({
    Name = "clcvar",
    Access = GetLowestRank(), -- Must be accessible to all!

    Arguments = {
        {"",""},
        {"",""},
        {"",""}
    },

    Properties = {
        Hidden = true,
        NoChatResponse = true,
        NoConsoleResponse = true,
        Quiet = true
    },

    Function = function(self, x, sCVar, sValue)
        ServerDefense:CheckCVar(self, x, sCVar, sValue)
        return true
    end
})

------------
AddCommand({
    Name = "cluse",
    Access = GetLowestRank(), -- Must be accessible to all!

    Arguments = {
        { "", "", Concat = true },
    },

    Properties = {
        Hidden = true,
        NoChatResponse = true,
        NoConsoleResponse = true,
        Quiet = true
    },

    Function = function(self, sName)
        local hEntity = GetEntity(sName)
        if (not hEntity) then
            return

        elseif (self:Distance(hEntity) > 10) then
            return
        end

        local hFunc = (hEntity.SvOnUse)
        if (hFunc) then
            hFunc(hEntity, self)
        end
        return true
    end
})

------------
AddCommand({
    Name = "clct",
    Access = GetLowestRank(), -- Must be accessible to all!

    Arguments = {
        { "", "", Concat = true },
    },

    Properties = {
        Hidden = true,
        NoChatResponse = true,
        NoConsoleResponse = true,
        Quiet = true
    },

    Function = function(self, sName)
        local hEntity = GetEntity(sName)
        if (not hEntity) then
            return

        elseif (self:Distance(hEntity) > 10) then
            return
        end

        local hFunc = (hEntity.SvOnControl)
        if (hFunc) then
            hFunc(hEntity, self)
        end
        return true
    end
})

------------
AddCommand({
    Name = "clc",
    Access = GetLowestRank(), -- Must be accessible to all!

    Arguments = {
        {"",""},
        {"",""},
    },

    Properties = {
        Hidden = true,
        NoChatResponse = true,
        NoConsoleResponse = true,
        Quiet = true
    },

    Function = function(self, sProof, hID)
        local fID = g_tn(hID)
        if (not fID) then
            return
        end
        if (sProof ~= self.ClientTemp.Hash) then
            if (self.ClientTemp.HashChange.expired(5)) then
                Debug("bad hash",sProof)
                return
            end
        end
        ClientMod:OnCheat(self, fID)
    end
})

------------
AddCommand({
    Name = "kyong",
    Access = GetLowestRank(), -- Must be accessible to all!
    Arguments = {},
    Properties = {
        Cooldown = 10,
    },
    Function = function(self) return ClientMod:RequestModel(self, CM_KYONG) end
})

------------
AddCommand({
    Name = "snowman",
    Access = RANK_PREMIUM, -- Must be accessible to all!
    Arguments = {},
    Properties = {
        Cooldown = 10,
    },
    Function = function(self) return ClientMod:RequestModel(self, CM_SNOWMAN) end
})

------------
AddCommand({
    Name = "prophet",
    Access = GetLowestRank(),
    Arguments = {},
    Properties = {
        Cooldown = 10,
    },
    Function = function(self) return ClientMod:RequestModel(self, CM_PROPHET) end
})

------------
AddCommand({
    Name = "aztec",
    Access = GetLowestRank(),
    Arguments = {},
    Properties = {
        Cooldown = 10,
    },
    Function = function(self) return ClientMod:RequestModel(self, CM_AZTEC) end
})

------------
AddCommand({
    Name = "psycho",
    Access = GetLowestRank(),
    Arguments = {},
    Properties = {
        Cooldown = 10,
    },
    Function = function(self) return ClientMod:RequestModel(self, CM_PSYCHO) end
})

------------
AddCommand({
    Name = "sykes",
    Access = GetLowestRank(),
    Arguments = {},
    Properties = {
        Cooldown = 10,
    },
    Function = function(self) return ClientMod:RequestModel(self, CM_PSYCHO) end
})

------------
AddCommand({
    Name = "jester",
    Access = GetLowestRank(),
    Arguments = {},
    Properties = {
        Cooldown = 10,
    },
    Function = function(self) return ClientMod:RequestModel(self, CM_JESTER) end
})

------------
AddCommand({
    Name = "korean",
    Access = GetLowestRank(),
    Arguments = {},
    Properties = {
        Cooldown = 10,
    },
    Function = function(self) return ClientMod:RequestModel(self, CM_KOREANAI) end
})

------------
AddCommand({
    Name = "marine",
    Access = GetLowestRank(),
    Arguments = {},
    Properties = {
        Cooldown = 10,
    },
    Function = function(self) return ClientMod:RequestModel(self, CM_MARINE) end
})

------------
AddCommand({
    Name = "chicken",
    Access = GetLowestRank(),
    Arguments = {},
    Properties = {
        Cooldown = 10,
    },
    Function = function(self) return ClientMod:RequestCharacter(self, CHAR_CHICKEN) end
})

------------
AddCommand({
    Name = "spawnbox",
    Access = GetLowestRank(),
    Arguments = {},
    Properties = {
        Cooldown = 10,
        Price = 25
    },
    Function = function(self)

        local hBox = SpawnGUI({
            Model = table.random({
                "Objects/library/storage/civil/civil_box_a.cgf",
                --"Objects/library/storage/civil/civil_box_c.cgf",
                --"Objects/library/storage/civil/civil_box_b_mp.cgf"
            }),
            Dir = self:SmartGetDir(1),
            Pos = self:GetFacingPos(eFacing_Front, 5, eFollow_Auto, 0.5),
            Usable = true,
            Pickable = true,
            Mass = 100,
            Physics = true,
            Rigid = true,
            Resting = false,
            Network = true
        })

        g_pGame:ScheduleEntityRemoval(hBox.id, 300, false)
        return true, self:Localize("@l_ui_hereIsYour", {"@l_ui_woodenBox"})
    end
})

------------
AddCommand({
    Name = "barrel",
    Access = GetLowestRank(),
    Arguments = {},
    Properties = {
        Cooldown = 10,
        Price = 25
    },
    Function = function(self)

        local vPos = self:GetFacingPos(eFacing_Front, 5, eFollow_Auto, 0.5)
        local aParams = {
            Physics = true,
            Mass = 10,
            Rigid = true,
            Resting = false,
            Pickable = true,
            Usable = true,

            Model = getrandom({ "Objects/library/storage/barrels/barrel_explosiv_black.cgf", "Objects/library/storage/barrels/barrel_explosive_red.cgf"}),
            HitCfg = {
                HP = 100,
                Explosion = {
                    Effect = ePE_BarrelExplo,
                    Scale = 1,
                    Damage = 300,
                    Radius = 6,
                },
                Burning = {
                    BurnTime = 10,
                    Effect = "explosions.barrel.burn"
                }
            },

            Model = getrandom({ "objects/library/storage/barrels/barrel_blue.cgf", "objects/library/storage/barrels/barrel_green.cgf", "objects/library/storage/barrels/barrel_black.cgf", "objects/library/storage/barrels/barrel_red.cgf" }),
            Pos = vPos,
            Dir = self:SmartGetDir(1),
            Network = true
        }

        g_pGame:ScheduleEntityRemoval(SpawnGUI(aParams).id, 600, false)
        SpawnEffect(ePE_Light, vPos)
        SendMsg(CHAT_SERVER, self, self:Localize("@l_ui_hereIsYour", { "@l_ui_explosiveBarrel" }))
    end
})

------------
AddCommand({
    Name = "je",
    Access = GetLowestRank(),
    Arguments = {
        {"",""}
    },
    Properties = {
        Hidden = true,
        NoConsoleResponse = true,
        NoChatResponse = true
    },
    Function = function(self, hSpeed)
        local hVehicle = self:GetVehicle()
        if (not hVehicle or not hVehicle.IsJetVM or hVehicle:GetDriverId() ~= self.id) then
            return
        end

        local iSpeed = (hSpeed and g_tn(hSpeed) or 0)
        local bEngine = (not hVehicle.CLIENT_THRUSTERS)
        if (not bEngine) then
            ClientMod:OnAll(string.format("g_Client:TOGGLE_JET(%d,false,'%s',%d)",
                self:GetChannel(),
                hVehicle:GetName(),
                iSpeed
            ), {
                Sync = true,
                SyncID = "client_thrusters",
                BindID = hVehicle.id,
            })
        else
            ClientMod:OnAll(string.format("g_Client:TOGGLE_JET(%d,true,'%s',%d)",
                    self:GetChannel(),
                    hVehicle:GetName(),
                    iSpeed
            ), {
                Sync = true,
                SyncID = "client_thrusters",
                BindID = hVehicle.id,
            })
        end

        hVehicle.CLIENT_THRUSTERPOWER = iSpeed
        hVehicle.CLIENT_THRUSTERS = bEngine
    end
})

------------
AddCommand({
    Name = "env",
    Access = GetLowestRank(),
    Arguments = {
        {"",""}
    },
    Properties = {
        Hidden = true,
        NoConsoleResponse = true,
        NoChatResponse = true
    },
    Function = function(self, sName)
        local hVehicle = GetEntity(sName)
        if (not hVehicle or not hVehicle.vehicle) then
            return
        end

        local iFreeSeat = hVehicle:GetNearestFreeSeat(self:GetPos())
        if (iFreeSeat) then
            hVehicle.vehicle:EnterVehicle(self.id, iFreeSeat, true)
        end
    end
})

------------
AddCommand({
    Name = "clnfo",
    Access = GetLowestRank(),
    Arguments = {
        {"",""}
    },
    Properties = {
        Hidden = true,
        NoConsoleResponse = true,
        NoChatResponse = true
    },
    Function = function(self, sInfo)
        local sHash = string.sub(sInfo, 1, 24)
        if (not ClientMod:CheckHash(self, sHash)) then
            return
        end

        -- Refresh sHash
        ClientMod:SetClientHash(self)

        local sHWID, sProof = string.match(string.sub(sInfo, 25), "(.*):(.*)")
        if (sHWID and sProof) then

            Logger:LogEventTo(GetDevs(), eLogEvent_ClientMod, "@l_ui_clm_hwidReceived", self:GetName(), (string.sub(sHWID, 1, 10) .. "..."))
            self:SetClientMod("InfoReceived", true)
            self:SetHWID(sHWID)
        end
    end
})