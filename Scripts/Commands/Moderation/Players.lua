------------
AddCommand({
    Name = "players",
    Access = RANK_MODERATOR, -- Must be accessible to all!

    Arguments = {
        {
            Name = "@l_ui_index",
            Desc = "@l_ui_index_d",
            Optional = true,
            IsNumber = true
        },
    },

    Properties = {
        Self = "PlayerHandler"
    },

    Function = function(self, hPlayer, hIndex)
        return self:ListPlayers(hPlayer, hIndex)
    end
})

------------
AddCommand({
    Name = "lookup",
    Access = RANK_MODERATOR, -- Must be accessible to all!

    Arguments = {
        {
            Name = "@l_ui_player",
            Desc = "@l_ui_player_d",
            Required = true,
            IsPlayer = true
        },
    },

    Properties = {
        Self = "PlayerHandler"
    },

    Function = function(self, hPlayer, hTarget)
        return self:PlayerInfo(hPlayer, hTarget)
    end
})

------------
AddCommand({
    Name = "sendhelp",
    Access = RANK_MODERATOR, -- Must be accessible to all!

    Arguments = {
        {
            Name = "@l_ui_player",
            Desc = "@l_ui_player_d",
            IsPlayer = true,
            Required = true,
            AllOk = true,
            SelfOk = true,
        },
        {
            Name = "@l_ui_command",
            Desc = "@l_ui_command_d",
            Required = true,
        },
    },

    Properties = {
    },

    Function = function(self, hTarget, sCommand)
        local aCommand = ServerCommands:FindCommandByName(self, sCommand)
        if (aCommand == nil) then
            return false, self:Localize("@l_commandresp_chat_notfound", {sCommand})
        end

        if (hTarget == ALL_PLAYERS) then
            for _, hPlayer in pairs(GetPlayers()) do
                ServerCommands:SendHelp(hPlayer, aCommand)
            end
        else
            ServerCommands:SendHelp(hTarget, aCommand)
            if (hTarget ~= self or self:IsTesting()) then
                SendMsg(CHAT_SERVER, self, self:Localize("@l_ui_helpSendToXConsole", { hTarget:GetName(), sCommand:upper()}))
            end
        end
    end
})

------------
AddCommand({
    Name = "kill",
    Access = RANK_MODERATOR, -- Must be accessible to all!

    Arguments = {
        {
            Name = "@l_ui_player",
            Desc = "@l_ui_player_d",
            IsPlayer = true,
            Required = true,
            AllOk = true,
            SelfOk = true,
        },
        {
            Name = "@l_ui_count",
            Desc = "@l_ui_count_d",
            IsNumber = true,
            Min = 1, Max = 100,
            Default = 1,
            Required = true,
        },
    },

    Properties = {
    },

    Function = function(self, hTarget, iCount)

        if (hTarget ~= ALL_PLAYERS and hTarget:HasGodMode()) then
            return false, self:Localize("@l_ui_playerInvulnerable")
        end

        for i = 1, iCount do
            Script.SetTimer(i * 10, function()
                if (hTarget == ALL_PLAYERS) then
                    for _, hPlayer in pairs(GetPlayers()) do
                        g_pGame:SetInvulnerability(hPlayer.id, false, 0)
                        hPlayer:Revive(1, 1)
                        g_gameRules:CreateHit(hPlayer.id, hPlayer.id, NULL_ENTITY, 10000)
                    end
                else
                    g_pGame:SetInvulnerability(hTarget.id, false, 0)
                    hTarget:Revive(1, 1)
                    g_gameRules:CreateHit(hTarget.id, hTarget.id, NULL_ENTITY, 10000)
                end
            end)
        end
        return true, self:Localize("@l_ui_targetKilled", { (hTarget == ALL_PLAYERS and "All Players" or hTarget:GetName()), iCount })
    end
})

------------
AddCommand({
    Name = "repair",
    Access = RANK_MODERATOR, -- Must be accessible to all!

    Arguments = {
        {
            Name = "@l_ui_player",
            Desc = "@l_ui_player_d",
            Default = "self",
            IsPlayer = true,
            Required = true,
            AllOk = true,
            SelfOk = true,
        },
    },

    Properties = {
    },

    Function = function(self, hTarget, iCount)

        local function fHeal(hEntity)

            local hVehicle = hEntity:GetVehicle()
            local hVehicleId = (hVehicle and hVehicle.id or hEntity.id)
            local aRepairHit = {
                typeId	    = g_pGame:GetHitTypeId("repair"),
                type		= "repair",
                material    = 0,
                materialId  = 0,
                dir			= g_Vectors.up,
                radius	    = 0,
                partId	    = -1,
                damage      = 9999,
                target      = (hVehicle or hEntity),
                targetId    = hVehicleId,
                shooterId   = hVehicleId,
                shooter     = (hVehicle or hEntity),
            }

            if (hVehicle) then
                hVehicle.Server.OnHit(hVehicle, aRepairHit)
            else
                hEntity.actor:SetHealth(100)
                hEntity.actor:SetNanoSuitEnergy(200)
            end
        end

        if (hTarget == ALL_PLAYERS) then
            for _, hPlayer in pairs(GetPlayers()) do
                fHeal(hPlayer)
            end
        else
            fHeal(hTarget)
        end
        return true, self:Localize("@l_ui_targetRepaired", { (hTarget == ALL_PLAYERS and "All Players" or hTarget:GetName()), iCount })
    end
})