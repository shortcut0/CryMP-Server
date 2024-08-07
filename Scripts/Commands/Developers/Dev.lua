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