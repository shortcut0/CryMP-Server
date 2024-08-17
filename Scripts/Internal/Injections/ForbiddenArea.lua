local ServerForbiddenArea = {

    -----------------
    This = "ForbiddenArea",
    PatchEntities = true,

    -----------------
    PostInit = function(self)
    end,

    ---------------------------------------------
    --- KillPlayers
    ---------------------------------------------
    {

        Class = "ForbiddenArea",
        Target = { "PunishPlayer" },
        Type = eInjection_Replace,

        ------------------------
        Function = function(self, player, time)

            if (ConfigGet("General.DisableForbiddenAreas", eConfigGet_Boolean, true)) then
                return g_gameRules.game:ForbiddenAreaWarning(false, 0, player.id)
            end

            if (player:HasGodMode()) then
                return g_gameRules.game:ForbiddenAreaWarning(false, 0, player.id)
            end

            if ((player.actor:GetSpectatorMode()~=0) or player:IsDead()) then
                return;
            end

            local warning=self.warning[player.id];
            if (warning and warning>0) then
                warning=warning-(time/1000);
                self.warning[player.id]=warning;
            elseif (not warning) then
                warning=self.delay;
                self.warning[player.id]=warning;
            end

            if (self.showWarning) then
                g_gameRules.game:ForbiddenAreaWarning(true, warning, player.id);
            end

            if (warning<=0) then
                g_gameRules:CreateHit(player.id,player.id,player.id,self.dps*(time/1000),nil,nil,nil,"punish");
            end
        end
    }

}

---------------------
ServerInjector.InjectAll(ServerForbiddenArea)