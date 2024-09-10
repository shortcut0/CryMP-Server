------------
AddCommand({
    Name = "god",
    Access = RANK_ADMIN, -- Must be accessible to all!

    Arguments = {
        {
            Name = "@l_ui_player",
            Desc = "@l_ui_player_d",
            Optional = true,
            SelfOk = true,
            IsPlayer = true,
            Default = "self",
        },
        {
            Name = "@l_ui_mode",
            Desc = "@l_ui_mode_d",
            IsNumber = true,
            Min = 0,
            Max = 3,
        }
    },

    Properties = {
    },

    -- self is the user unless specified otherwise
    Function = function(self, hTarget, iMode)

        local sMode = "@l_ui_enabled"
        if (hTarget and hTarget ~= self) then
            if (hTarget:HasGodMode()) then

                if (iMode == nil or iMode == 0) then
                    sMode = "@l_ui_disabled"
                    hTarget:SetGodMode(0)
                else
                    hTarget:SetGodMode(iMode)
                end
            else
                iMode = (iMode or 1)
                hTarget:SetGodMode(iMode)
            end

            local sExtra = table.find({
                [1] = "@l_ui_normal-",
                [2] = "@l_ui_extended-",
                [3] = "@l_ui_mega-"
            }, (iMode or -1)) or ""

            SendMsg(CHAT_SERVER, self, self:LocalizeNest(string.format(
                    "(%s: %s@l_ui_godMode: %s)", hTarget:GetName(),
                    sExtra, sMode
            )))
            SendMsg(CHAT_SERVER, hTarget, hTarget:LocalizeNest(string.format(
                    "(%s@l_ui_godMode: %s)",
                    sExtra, sMode
            )))
            return true
        end

        if (self:HasGodMode()) then

            if (iMode == nil or iMode == 0) then
                sMode = "@l_ui_disabled"
                self:SetGodMode(0)
            else
                self:SetGodMode(iMode)
            end
        else
            iMode = (iMode or 1)
            self:SetGodMode(iMode)
        end

        local sExtra = table.find({
            [1] = "@l_ui_normal-",
            [2] = "@l_ui_extended-",
            [3] = "@l_ui_mega-"
        }, (iMode or -1)) or ""

        SendMsg(CHAT_SERVER, self, self:LocalizeNest(string.format(
                "(%s@l_ui_godMode: %s)",
                sExtra, sMode
        )))
        return true
    end
})

------------
AddCommand({
    Name = "superman",
    Access = RANK_ADMIN, -- Must be accessible to all!

    Arguments = {
        {
            Name = "@l_ui_player",
            Desc = "@l_ui_player_d",
            Optional = true,
            SelfOk = true,
            IsPlayer = true,
            Default = "self",
        },
    },

    Properties = {
    },

    -- self is the user unless specified otherwise
    Function = function(self, hTarget)

        local sMode = "@l_ui_enabled"
        if (hTarget and hTarget ~= self) then
            if (hTarget:IsSuperman()) then
                sMode = "@l_ui_disabled"
                hTarget:SetSuperman(0)
            else
                hTarget:SetSuperman(1)
            end

            SendMsg(CHAT_SERVER, self, self:LocalizeNest(string.format(
                    "(%s: @l_ui_superMode: %s)", hTarget:GetName(),
                    sMode
            )))
            SendMsg(CHAT_SERVER, hTarget, hTarget:LocalizeNest(string.format(
                    "(@l_ui_superMode: %s)",
                    sMode
            )))
            return true
        end

        if (self:IsSuperman()) then
            sMode = "@l_ui_disabled"
            self:SetSuperman(0)
        else
            self:SetSuperman(1)
        end

        SendMsg(CHAT_SERVER, self, self:LocalizeNest(string.format(
                "(@l_ui_superMode: %s)",
                sMode
        )))
        return true
    end
})