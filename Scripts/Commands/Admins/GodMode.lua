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

        if (hTarget and hTarget ~= self) then

            return true
        end

        local sMode = "@l_ui_enabled"
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

        Debug(iMode)

        SendMsg(CHAT_SERVER, self, self:LocalizeNest(string.format(
                "(%s@l_ui_godMode: %s)",
                sExtra, sMode
        )))
        return true
    end
})