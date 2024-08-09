--------------------
CreatePlugin({

    DataDir = (SERVER_DIR_DATA .. "PlayerData\\"),
    DataFile = "PersistentScore.lua",
    Score = {
        PowerStruggle = {},
        InstantAction = {},
    },

    Config = {

        InstantAction = {
            RestoreKills  = true,
            RestoreDeaths = true
        },

        PowerStruggle = {
            RestoreKills  = false,
            RestoreDeaths = false,
            RestoreCP     = false,
            RestorePP     = false,
            RestoreRank   = false,
        }

    },

    ID = "PersistentScore",

    ---------------------
    Links = {
        [eServerEvent_OnScriptReload] = "SaveScore",
        [eServerEvent_OnClientValidated] = "OnProfileValidated",
        [eServerEvent_SavePlayerData] = "OnClientDisconnect",
    },

    ---------------------
    Init = function(self)
    end,

    ---------------------
    SaveScore = function(self)

        local sData = string.format("return %s", (table.tostring((self.Score or {}), "", "") or "{}"))
        local sFile = (self.DataDir .. self.DataFile)

        local bOk, sErr = FileOverwrite(sFile, sData)
        if (not bOk) then

            HandleError("Error saving File %s (%s)", self.DataFile, sErr)
            ServerLogError("Failed to open file %s for writing", sFile)
        end
    end,

    ---------------------
    LoadScore = function(self)

        local sFile = (self.DataDir .. self.DataFile)
        local aData = FileLoader:ExecuteFile(sFile, eFileType_Data)
        if (not aData) then
            return
        end

        self.Score = aData
    end,

    ---------------------
    OnProfileValidated = function(self, hClient, sID)

        local aScore = self.Score[g_sGameRules][sID]
        if (not aScore) then
            return-- HandleError("No Score found!")
        end

        local aConfig = self.Config[g_sGameRules]

        local iKills  = aScore.Kills
        local iDeaths = aScore.Deaths
        local iCP     = aScore.CP
        local iPP     = aScore.PP
        local iRank   = aScore.iRank

        local bAny    = false

        if (aConfig.RestoreKills)  then bAny = true hClient:SetKills(iKills) end
        if (aConfig.RestoreDeaths) then bAny = true hClient:SetDeaths(iDeaths) end

        if (g_gameRules.IS_PS) then
            if (aConfig.RestoreCP)   then bAny = true hClient:SetCP(iCP) end
            if (aConfig.RestorePP)   then bAny = true hClient:SetPrestige(iPP) end
            if (aConfig.RestoreRank) then bAny = true hClient:SetRank(iRank) end
        end

        if (bAny) then
            Logger:LogEventTo(GetPlayers(), eLogEvent_Plugins, "Score Restored for ${red}%s", hClient:GetName())
            SendMsg(CHAT_SERVER, hClient, "(SCORE: Restored!)")
        end
    end,

    ---------------------
    OnClientDisconnect = function(self, hClient, bQuiet)

        local sID     = hClient:GetProfileID()
        local iKills  = hClient:GetKills()
        local iDeaths = hClient:GetDeaths()

        local aInfo = {
            Kills  = iKills,
            Deaths = iDeaths
        }

        if (g_gameRules.IS_PS) then

            local iCP   = hClient:GetCP()
            local iPP   = hClient:GetPrestige()
            local iRank = hClient:GetRank()

            aInfo.CP    = iCP
            aInfo.PP    = iPP
            aInfo.Rank  = iRank
        end

        if (not bQuiet) then
            Logger:LogEvent(eLogEvent_Plugins, "Score Saved for ${red}%s", hClient:GetName())
        end

        self.Score[g_sGameRules][sID] = aInfo
        self:SaveScore()
    end,
})