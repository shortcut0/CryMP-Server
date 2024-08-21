------------
local ServerPlayer = {

    -----------------
    This = "Player",
    PatchEntities = true,

    -----------------
    PostInit = function(self)
    end,

    ---------------------------------------------
    --- DoPainSounds
    ---------------------------------------------
    {

        Class = "Player",
        Target = { "DoPainSounds" },
        Type = eInjection_Replace,

        ------------------------
        Function = function()
        end
    },

    ---------------------------------------------
    --- OnHit
    ---------------------------------------------
    {

        Class = "Player",
        Target = { "Server.OnHit" },
        Type = eInjection_Replace,

        ------------------------
        Function = function(self, aHitInfo)
            if (self.actor:GetSpectatorMode()~=0) then
                return;
            end

            if (aHitInfo.damage >= 1) then
                if (g_gameRules and aHitInfo.target and aHitInfo.target.actor and aHitInfo.target.actor:IsPlayer()) then
                    if(not aHitInfo.shooterId == nil or (aHitInfo.damage > 3.0)) then
                        g_gameRules.game:SendDamageIndicator(aHitInfo.targetId, aHitInfo.shooterId or NULL_ENTITY, aHitInfo.weaponId or NULL_ENTITY);
                    end
                end
                if (aHitInfo.shooter and aHitInfo.shooter.actor and aHitInfo.shooterId~=aHitInfo.targetId and aHitInfo.shooter.actor:IsPlayer()) then
                    if (g_gameRules) then
                        g_gameRules.game:SendHitIndicator(aHitInfo.shooterId,aHitInfo.explosion~=nil)
                    end
                end
            end


            if (self:IsOnVehicle() and aHitInfo.type~="heal") then
                local vehicle = System.GetEntity(self.actor:GetLinkedVehicleId());
                local newDamage = vehicle.vehicle:ProcessPassengerDamage(self.id, self.actor:GetHealth(), aHitInfo.damage, aHitInfo.type or "", aHitInfo.explosion or false);
                if (newDamage <= 0.0) then
                    return;
                end
            end

            local isPlayer = self.actor:IsPlayer()
            if (aHitInfo.damage > 0) then
                self.actor:NanoSuitHit(aHitInfo.damage)
            end

            --	if (self.actor:GetPhysicalizationProfile() == "sleep") then
            --		self.actor:StandUp();
            --	end

            if (aHitInfo.frost and aHitInfo.frost>0) then
                self.actor:AddFrost(aHitInfo.frost);
            end

            --	Log("OnHit >>>>>>>>> "..self:GetName().."   damage: "..hit.damage);

            local died = g_gameRules:ProcessActorDamage(aHitInfo);

            if (died and not isPlayer and (aHitInfo.type == "collision" or aHitInfo.explosion == true)) then
                self:LastHitInfo(self.lastHit, aHitInfo);
            end

            if (aHitInfo.damage == 0 or aHitInfo.type == "heal") then return end

            --[[
        --some AI related
        if (not isPlayer) then
                local theShooter=hit.shooter;
                -- upade hide-in-vehicle
                if (theShooter and theShooter.IsOnVehicle) then
                    local shootersVehicleId = theShooter:IsOnVehicle();
                    if (shootersVehicleId) then
                        local shootersVehicle = System.GetEntity(shootersVehicleId);
                        if(shootersVehicle and shootersVehicle.ChangeSpecies and (shootersVehicle.AI==nil or shootersVehicle.AI.hostileSet~=1)) then
                            shootersVehicle:ChangeSpecies(theShooter, 2);
                        end
                    end
                end

            if (hit.type and hit.type ~= "collision" and hit.type ~= "fall" and hit.type ~= "event") then


                if (theShooter) then
                    CopyVector(g_SignalData.point, theShooter:GetWorldPos());
                    g_SignalData.id = hit.shooterId;
                else
                    g_SignalData.id = NULL_ENTITY;
                    CopyVector(g_SignalData.point, g_Vectors.v000);
                end

                g_SignalData.fValue = hit.damage;

                if (theShooter and AI.Hostile(self.id,hit.shooterId)) then
                    AI.Signal(SIGNALFILTER_SENDER,0,"OnEnemyDamage",self.id,g_SignalData);
                    AI.UpTargetPriority(self.id, hit.shooterId, 0.2);	-- make the target more important
                    -- check for greeting player in case of "nice shot"
                    if(died and theShooter == g_localActor) then
                        local ratio = self.lastHealth / self.Properties.Damage.health;
                        if( ratio> 0.9 and hit.material_type and hit.material_type=="head" and hit.type and hit.type=="bullet") then
                            AI.Signal(SIGNALFILTER_GROUPONLY,0,"OnPlayerNiceShot",g_localActor.id);
                        end
                    end
                    --			elseif(hit.shooter and hit.shooter==g_localActor and self.Properties.species==hit.shooter.Properties.species) then
                    --				AI.Signal(SIGNALFILTER_SENDER,0,"OnFriendlyDamageByPlayer",self.id,g_SignalData);
                elseif (theShooter ~= nil and theShooter~=self) then
                    if(hit.weapon and hit.weapon.vehicle) then
                        AI.Signal(SIGNALFILTER_SENDER,0,"OnDamage",self.id,g_SignalData);
                    else
                        AI.Signal(SIGNALFILTER_SENDER,0,"OnFriendlyDamage",self.id,g_SignalData);
                    end
                else
                    AI.Signal(SIGNALFILTER_SENDER,0,"OnDamage",self.id,g_SignalData);
                end
            end

            if (self.RushTactic) then
                self:RushTactic(5)
            end
        end
                ]]

            self:HealthChanged()
            return died
        end
    },

    ---------------------------------------------
    --- DoPainSounds
    ---------------------------------------------
    {

        Class = "Player",
        Target = { "CurrentItemChanged" },
        Type = eInjection_Replace,

        ------------------------
        Function = function(self, hNewID, hOldID)

            local hNewItem = GetEntity(hNewID)
            local hOldItem = GetEntity(hOldID)

            local sNewClass = (hNewItem and hNewItem.class or "")
            local sOldClass = (hOldItem and hOldItem.class or "Fists")

            if (not self:IsAllowedEquip(sNewClass)) then
                self:SelectItem(sOldClass)
                local sMsg = self:GetEquipReason()
                if (sMsg) then
                    SendMsg(MSG_CENTER, self, Logger:Format(sMsg, { ["weapon"] = sOldClass }))
                end
            end

            ------------------------------------
            -- Hello! is this needed? remove pls
            --[[
            local item = System.GetEntity(hNewID);
            if(item) then
                -- notify squadmates about the attachments on new weapon
                local weapon = item.weapon;
                local entityAccessoryTable = SafeTableGet(self.AI, "WeaponAccessoryTable");
                if(weapon and entityAccessoryTable) then
                    if(weapon:GetAccessory("Silencer") or item.class == "Fists") then
                        entityAccessoryTable["Silencer"] = 1;
                        self.AI.Silencer = true;
                    else
                        entityAccessoryTable["Silencer"] = 0;
                        self.AI.Silencer = false;
                    end

                    if(weapon:GetAccessory("SCARIncendiaryAmmo")) then
                        entityAccessoryTable["SCARIncendiaryAmmo"] = 2;
                        entityAccessoryTable["SCARNormalAmmo"] = 0;
                    elseif(weapon:GetAccessory("SCARNormalAmmo")) then
                        entityAccessoryTable["SCARIncendiaryAmmo"] = 0;
                        entityAccessoryTable["SCARNormalAmmo"] = 2;
                    end
                    -- use a timer to avoid repeated spamming notifications
                    self:SetTimer(SWITCH_WEAPON_TIMER,2000);
                end
            end]]
        end
    },

}

------------
ServerInjector.InjectAll(ServerPlayer)