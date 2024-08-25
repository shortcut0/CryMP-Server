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

            return true, self:Localize("@l_ui_jetPackParty", { ClientMod.JETPACKS_ENABLED and "@l_ui_enabled" or "@l_ui_disabled" })
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
            { Name = "Chair", Model = "Objects/library/architecture/aircraftcarrier/props/furniture/chairs/console_chair.cgf" }
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
                    Debug("fucking has")
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