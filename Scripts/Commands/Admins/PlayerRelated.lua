------------
AddCommand({
    Name = "bring",
    Access = RANK_ADMIN, -- Must be accessible to all!

    Arguments = {
        { "@l_ui_player", "@l_ui_player_d", Required = true, AllOk = true, IsPlayer = true, NotSelf = true },
        { "@l_ui_target", "@l_ui_target_d", Optional = true, Default = "self", AllOk = false, SelfOk = true, IsPlayer = true },
        { "@l_ui_argument", "@l_ui_argument_d", Optional = true},
    },

    Properties = {
    },

    Function = function(self, hBring, hTo, bIntoVehicle)

        local vPos = self:GetFacingPos(eFacing_Front, 3)
        if (hTo) then
            vPos = hTo:GetFacingPos(eFacing_Front, 3)
        end

        local hToPlayer = (hTo or self)
        local sTo = hToPlayer:GetName()

        local aBring = { hBring }
        if (hBring == ALL_PLAYERS) then
            aBring = GetPlayers({})
            if (table.count(aBring) == 0) then
                return false, self:Localize("@l_ui_noOtherPlayersOnline")
            end
            SendMsg(CHAT_SERVER, hToPlayer, hToPlayer:Localize("@l_ui_allPlayersBroughtToYou", { sTo }))
        else
            SendMsg(CHAT_SERVER, hToPlayer, hToPlayer:Localize("@l_ui_playerBroughtToYou", { hBring:GetName(), sTo }))
        end

        local bOk
        local hVehicle = hToPlayer:GetVehicle()
        for _, hTarget in pairs(aBring) do


            if (hTo) then
                bOk = (hTarget.id ~= hTo.id)
            else
                bOk = (hTarget.id ~= self.id)
            end

            if (bOk) then
                local vNPos = vector.randomize(vPos, (_ * 0.5), true)
                SpawnEffect(ePE_Light, vNPos)

                if (hTarget:IsDead()) then
                    hTarget:Revive(vNPos, true)
                else
                    hTarget:SvMoveTo(vNPos)
                end

                if (bIntoVehicle and hVehicle) then
                    local iSeat = nil
                    for i, aSeat in pairs(hVehicle.Seats) do if (aSeat:IsFree()) then iSeat = i break end end
                    if (iSeat) then
                        hVehicle.vehicle:EnterVehicle(hTarget.id, iSeat, true)
                    end
                end

                SendMsg(CHAT_SERVER, hTarget, hTarget:Localize("@l_ui_youWereTeleportedTo", { (hTo or self):GetName() }))
            end
        end

        return true
    end
})

------------
AddCommand({
    Name = "goto",
    Access = RANK_ADMIN, -- Must be accessible to all!

    Arguments = {
        { "@l_ui_player", "@l_ui_player_d", Required = true, AllOk = true, IsPlayer = true, NotSelf = true },
        { "@l_ui_argument", "@l_ui_argument_d", Optional = true},
    },

    Properties = {
    },

    Function = function(self, hGoto, bIntoVehicle)

        local vPos = hGoto:GetFacingPos(eFacing_Front, 1)

        SendMsg(CHAT_SERVER, hGoto, hGoto:Localize("@l_ui_playerTeleportedToYou", { self:GetName() }))
        SendMsg(CHAT_SERVER, self, self:Localize("@l_ui_youTeleportedTo", { hGoto:GetName() }))

        if (self:IsDead()) then
            self:Revive(vPos, true)
        else
            self:SvMoveTo(vPos)
        end

        local hVehicle = hGoto:GetVehicle()
        if (hVehicle and bIntoVehicle) then
            local iSeat = nil
            for i, aSeat in pairs(hVehicle.Seats) do if (aSeat:IsFree()) then iSeat = i break end end
            if (iSeat) then
                hVehicle.vehicle:EnterVehicle(self.id, iSeat, true)
            end
        end

        return true
    end
})

------------
AddCommand({
    Name = "initclient",
    Access = RANK_ADMIN, -- Must be accessible to all!

    Arguments = {
        { "@l_ui_player", "@l_ui_player_d", Optional = true, Default = "self", AllOk = true, SelfOk = true, IsPlayer = true }
    },

    Properties = {
    },

    Function = function(self, hClient)
        if (hClient == ALL_PLAYERS) then
            for _, hTarget in pairs(GetPlayers()) do
                PlayerHandler.RegisterFunctions(hTarget, hTarget:GetChannel())
            end
            SendMsg(CHAT_SERVER, self, "(Initializing all Players)")
            return true
        end

        PlayerHandler.RegisterFunctions(hClient, hClient:GetChannel())
        SendMsg(CHAT_SERVER, self, string.format("(%s: Initializing)", hClient:GetName()))
        return true
    end
})

------------
AddCommand({
    Name = "revive",
    Access = RANK_ADMIN, -- Must be accessible to all!

    Arguments = {
        { "@l_ui_player", "@l_ui_player_d", Optional = true, Default = "self", AllOk = true, SelfOk = true, IsPlayer = true },
        { "@l_ui_spawnpoint", "@l_ui_spawnpoint_revive_d", Optional = true }
    },

    Properties = {
    },

    Function = function(self, hClient, bSpawn)

        if (hClient == ALL_PLAYERS) then
            for _, hTarget in pairs(GetPlayers()) do
                hTarget:Revive(1, 1, (bSpawn ~= nil))
                SpawnEffect(ePE_Light, hTarget:GetPos())
            end

            -- TODO: Locale
            SendMsg(CHAT_SERVER, self, string.format("(%s)", self:Localize("@l_ui_revived_all")))
            return true
        end

        -- TODO: Locale
        hClient:Revive(1, 1, (bSpawn ~= nil))
        SpawnEffect(ePE_Light, hClient:GetPos())
        SendMsg(CHAT_SERVER, self, string.format("(%s: %s)", hClient:GetName(), self:Localize("@l_ui_revived")))
        return true
    end
})

------------
AddCommand({
    Name = "spec",
    Access = RANK_ADMIN, -- Must be accessible to all!

    Arguments = {
        { "@l_ui_player", "@l_ui_player_d", Optional = true, NotSelf = true, IsPlayer = true },
    },

    Properties = {
    },

    Function = function(self, hTarget)

        -- Stop
        if (self:IsSpectating()) then
            self:Revive(1, 1, nil, self:GetTemp(ePlayerTemp_SpectatorEquip, nil, true))
            return true
        end

        -- Start
        self:SetTemp(ePlayerTemp_SpectatorEquip, self:GetEquipment())
        self:Spectate(1, hTarget)
        return true
    end
})