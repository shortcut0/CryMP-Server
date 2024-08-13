------------
AddCommand({
    Name = "set",
    Access = RANK_ADMIN,

    Arguments = {
        {
            Name = "@l_ui_cvar",
            Desc = "@l_ui_cvar_d",
            Required = true,
            IsCVar = true,
        },
        {
            Name = "@l_ui_value",
            Desc = "@l_ui_value_d",
            Optional = true,
            Concat = true
        },
    },

    Properties = {
    },

    Function = function(self, sCVar, hValue)
        local hCurr = GetCVar(sCVar)
        if (not hValue) then
            SendMsg(CHAT_SERVER, self, string.format("(%s: %s)", string.upper(sCVar), hCurr))
            return true
        end

        Debug(">>hValue",hValue)
        if (string.matchex(hValue, "default", "reset")) then
            Debug("WTF")
            if (Server:IsCVarChanged(sCVar)) then
                Server:RestoreCVar(sCVar, self)
            else
                return false, self:Localize("@l_ui_cvarAlreadyDefault", { sCVar })
            end
            return true
        end
        Server:ChangeCVar(sCVar, hValue, self)
    end
})