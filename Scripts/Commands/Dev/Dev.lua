------------
AddCommand({
    Name = "reload",
    Access = GetDevRanks(1), -- Must be accessible to all!

    Arguments = {
    },

    Properties = {
        NoLogging = true
    },

    Function = function(self)

        Logger:LogEventTo(GetDevs(), eLogEvent_Server,"Server Reloading ...")
        SendMsg(CHAT_SERVER, GetDevs(), "Server is Reloading ...")
        Script.SetTimer(250, function()
            System.ExecuteCommand("server_reloadScript")
            SendMsg(CHAT_SERVER, GetDevs(), "Sever Reloaded!")
        end)
        return true
    end
})