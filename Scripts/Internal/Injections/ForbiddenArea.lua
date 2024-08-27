local ServerForbiddenArea = {

    -----------------
    This = "ForbiddenArea",
    PatchEntities = true,

    -----------------
    PostInit = function(self)
    end,

    ---------------------------------------------
    --- Server.OnLeaveArea
    ---------------------------------------------
    {

        Class = "ForbiddenArea",
        Target = { "SvOnLeaveArea" },
        Type = eInjection_Replace,

        ------------------------
        Function = function(self, entity, areaId)

            local bShow = true
            if (ConfigGet("General.DisableForbiddenAreas", eConfigGet_Boolean, true)) then
                bShow = false
            end

            if (entity.IsPlayer and entity:HasGodMode()) then
                bShow = false
            end

            if (entity.actor) then
                local inside=false;
                for i,v in ipairs(self.inside) do
                    if (v==entity.id) then
                        inside=true;
                        table.remove(self.inside, i);
                        break;
                    end
                end

                if (bShow) then
                    if ((not self.teamId) or (self.teamId~=g_gameRules.game:GetTeam(entity.id))) then
                        if (self.reverse) then
                            if (inside) then
                                self.warning[entity.id]=self.delay;

                                if (self.showWarning) then
                                    if ((entity.actor:GetSpectatorMode()==0) and (not entity:IsDead())) then
                                        g_gameRules.game:ForbiddenAreaWarning(true, self.delay, entity.id);
                                    end
                                end
                            end
                        else
                            self.warning[entity.id]=nil;

                            if (self.showWarning) then
                                g_gameRules.game:ForbiddenAreaWarning(false, 0, entity.id);
                            end
                        end
                    end
                end
            end
        end

    },

    ---------------------------------------------
    --- Server.OnEnterArea
    ---------------------------------------------
    {

        Class = "ForbiddenArea",
        Target = { "SvOnEnterArea" },
        Type = eInjection_Replace,

        ------------------------
        Function = function(self, entity, areaId)

            local bShow = true
            if (ConfigGet("General.DisableForbiddenAreas", eConfigGet_Boolean, true)) then
                bShow = false
            end

            if (entity.IsPlayer and entity:HasGodMode()) then
                bShow = false
            end

            if (entity.actor) then
                local inside=false;
                for i,v in ipairs(self.inside) do
                    if (v==entity.id) then
                        inside=true;
                        break;
                    end
                end

                if (inside) then
                    return;
                end

                table.insert(self.inside, entity.id);

                if (bShow) then
                    if ((not self.teamId) or (self.teamId~=g_gameRules.game:GetTeam(entity.id))) then
                        if (not self.reverse) then
                            self.warning[entity.id]=self.delay;

                            if (self.showWarning) then
                                if ((entity.actor:GetSpectatorMode()==0) and (not entity:IsDead())) then
                                    g_gameRules.game:ForbiddenAreaWarning(true, self.delay, entity.id);
                                end
                            end
                        else
                            self.warning[entity.id]=nil;

                            if (self.showWarning) then
                                g_gameRules.game:ForbiddenAreaWarning(false, 0, entity.id);
                            end
                        end
                    end
                end
            end
        end
    },

    ---------------------------------------------
    --- KillPlayers
    ---------------------------------------------
    {

        Class = "ForbiddenArea",
        Target = { "PunishPlayer" },
        Type = eInjection_Replace,

        ------------------------
        Function = function(self, player, time)

            --Debug("pun..")

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