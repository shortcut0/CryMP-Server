------------
ServerGameRules = {

    -----------------
    This = g_gameRules,

    -----------------
    Init = function(self)

        self.IS_PS = (g_sGameRules == "PowerStruggle")
        self.IS_IA = (g_sGameRules == "InstantAction")

        Logger.CreateAbstract(self, { LogClass = "GameRules" })

        if (ConfigGet("General.GameRules.bSkipPreGame", false)) then

            self:Log("Skipping PreGame.. ")
            if (self:GetState() ~= "InGame") then
                self:GotoState("InGame")
            end
        end
    end,

    -----------------
    {
        Class = "g_gameRules",
        Target = { "Server.OnClientConnect", "PreGame.Server.OnClientConnect", "InGame.Server.OnClientConnect" },
        Type = eInjection_Replace,

        ------------------------
        Function = function(self, iChannel, bReset, sName)

            local hClient = self:SpawnPlayer(iChannel, sName)
            if (not hClient) then
                ServerLogError("Failed to Spawn Client %s", checkString(sName))
                return false
            end

            local bOnHold = CryAction.IsChannelOnHold(iChannel)

            if (not bReset) then
                g_pGame:ChangeSpectatorMode(hClient.id, 2, NULL_ENTITY)
            else

                if (not bOnHold) then
                    self:ResetScore(hClient.id)
                end

                local iSpecMode = self.channelSpectatorMode[iChannel] or 0
                local iTeam = self.game:GetChannelTeam(iChannel) or 0

                if (iSpecMode == 0 or iTeam ~= 0) then

                    self.game:SetTeam(iTeam, hClient.id)
                    self.Server.RequestSpawnGroup(self, hClient.id, self.game:GetTeamDefaultSpawnGroup(iTeam) or NULL_ENTITY, true)
                    self:RevivePlayer(hClient.actor:GetChannel(), hClient)
                else
                    self.Server.OnChangeSpectatorMode(self, hClient.id, iSpecMode, nil, true)
                end
            end

            if (self.IS_PS) then
                if (not bOnHold) then
                    self:ResetScore(hClient.id)
                    self:ResetPP(hClient.id)
                    self:ResetCP(hClient.id)
                end
                self:ResetRevive(hClient.id)
            end


            -- FIXME: Factory.lua (Injection)
            local hFactory, aZoneSynch
            for i, v in pairs(System.GetEntities()) do
                aZoneSynch = hEntity.BuyZoneSynch
                if (aZoneSynch) then
                    hFactory = GetEntity(aZoneSynch.ID)
                    if (hFactory) then
                        hFactory.allClients:ClSetBuyFlags(aZoneSynch.ID, aZoneSynch.Flags)
                    end
                end
            end
        end
    }
}

------------
ServerInjector.InjectAll(ServerGameRules)