------------
AddCommand({
    Name = "reload",
    Access = RANK_DEVELOPER, -- Must be accessible to all!

    Arguments = {
    },

    Properties = {
        NoLogging = true
    },

    Function = function(self)

        Logger:LogEventTo(GetDevs(), eLogEvent_Server,"************ Server Reloading")
        SendMsg(CHAT_SERVER, GetDevs(), "Server is Reloading ...")
        Script.SetTimer(250, function()
            System.ExecuteCommand("server_reloadScript")
            SendMsg(CHAT_SERVER, GetDevs(), string.format("Sever Reloaded (Took %0.2fs)!", Server.INIT_TIME))
            Logger:LogEventTo(GetDevs(), eLogEvent_Server,"Reloaded in ($4%0.2fs$9)", Server.INIT_TIME)
        end)
        return true
    end
})

------------
AddCommand({
    Name = "install",
    Access = RANK_DEVELOPER, -- Must be accessible to all!

    Arguments = {
    },

    Properties = {
        NoLogging = true
    },

    Function = function(self,a)

        ClientMod:Install(self,a)
        return true
    end
})

------------
AddCommand({
    Name = "mypos",
    Access = RANK_DEVELOPER, -- Must be accessible to all!

    Arguments = {
    },

    Properties = {
        NoLogging = true
    },

    Function = function(self)

        local vPos = self:GetPos()
        local vDir = self:GetDirectionVector()

        local sPos = string.format("Pos = { x = %f, y = %f, z = %f }", vPos.x, vPos.y, vPos.z)
        local sDir = string.format("Dir = { x = %f, y = %f, z = %f }", vDir.x, vDir.y, vDir.z)

        Logger:LogEventTo({ self }, eLogEvent_Debug, sPos)
        Logger:LogEventTo({ self }, eLogEvent_Debug, sDir)

        SendMsg(CHAT_SERVER, self, sPos)
        SendMsg(CHAT_SERVER, self, sDir)
        return true
    end
})

------------
AddCommand({
    Name = "debugmode",
    Access = RANK_DEVELOPER, -- Must be accessible to all!

    Arguments = {
    },

    Properties = {
    },

    Function = function(self)

        if (SERVER_DEBUG_MODE) then
            SERVER_DEBUG_MODE = false
        else
            SERVER_DEBUG_MODE = true
        end

        return true, self:LocalizeNest("@l_ui_" .. (SERVER_DEBUG_MODE and "enabled" or "disabled"))
    end
})

------------
AddCommand({
    Name = "errorlog",
    Access = RANK_DEVELOPER, -- Must be accessible to all!

    Arguments = {
        { IsNumber = true, Min = 1, Name = "@l_ui_argument", Desc = "@l_ui_argument_d", Optional = true }
    },

    Properties = {
        NoLogging = true
    },

    Function = function(self, hIndex)

        local aList = table.copy(ErrorHandler:GetErrorList())
        if (table.empty(aList)) then
            return false, self:Localize("@l_ui_ErrorLogEmpty")
        end


        local iBoxWidth = CLIENT_CONSOLE_LEN
        local iDateLength = 21
        local sBanner = string.rspace(string.format("$9== ~ $4%s$9 ~ ", self:Localize("@l_ui_errorLog")), iBoxWidth, string.COLOR_CODE, "=")

        SendMsg(MSG_CONSOLE_FIXED, self, string.format("%s", sBanner))
        SendMsg(MSG_CONSOLE_FIXED, self, string.format("$9[ %s $9]", string.rep(" ", iBoxWidth - 4)))

        local iTimestamp = GetTimestamp()
        local iTotal = table.count(aList)
        hIndex = math.min((hIndex or -1), iTotal)

        local sLine = ""
        for _, aInfo in pairs(aList) do

            if (_ > 99 and hIndex ~= -1) then
                break
            end

            if (hIndex == -1 or (_ == hIndex or (_ == (hIndex - 1) or _ == (hIndex + 1)))) then
                sLine = string.format("$1%s$9) %s : ",
                        string.lspace(_, string.len(iTotal)) ,
                        string.rspace(string.format("<$4%s %s$9>",math.calctime(aInfo.Timer.diff_t()), self:Localize("@l_ui_ago")), iDateLength, string.COLOR_CODE)
                )
                sLine = string.rspace(sLine .. "$1" .. aInfo.Error.Desc, iBoxWidth - 4, string.COLOR_CODE)
                SendMsg(MSG_CONSOLE_FIXED, self, string.format("$9[ %s $9]", sLine))
                if (hIndex == _) then
                    local sError
                    for __, sErrorLine in pairs(aInfo.Error.Location) do

                        sError = string.rep(" ", string.len(iTotal) + 1) .. "-> " .. sErrorLine
                        sError = string.rspace(sError, iBoxWidth - 4, string.COLOR_CODE)
                        SendMsg(MSG_CONSOLE_FIXED, self, string.format("$9[ %s $9]", sError))
                    end
                end
            end

        end
        SendMsg(MSG_CONSOLE_FIXED, self, string.format("$9%s", string.rep("=", iBoxWidth)))

        --[[
        table.insert(self.CollectedErrors, {
            GetTimestamp = GetTimestamp(),
            Timer        = timernew(),
            Error        = {
                Desc     = sErrorDesc,
                Location = aLocation
            }
        })

        == [ ~ Error Log ~ ] =============================================================================
        [
        [   1) <1d: 30m: 1s Ago>  : Attempt to Call a Nil Value
        [     -> C:\Users\WTF\WTF.lua (Error?) Line 69!
        [
        ==================================================================================================
        ]]
        return true
    end
})