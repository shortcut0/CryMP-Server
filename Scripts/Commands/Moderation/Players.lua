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