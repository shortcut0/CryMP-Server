------------------
PlayerHandler = (PlayerHandler or {

    CachedInfo = {},
    PlayerData = {},

    DataDir  = (SERVER_DIR_DATA .. "PlayerData\\"),
    DataFile = "PlayerData.lua"

})

------------------
PlayerHandler.Init = function(self)

    self:LoadFile()
    EventLink(eServerEvent_OnScriptReload, "PlayerHandler", "SaveFile")
end

------------------
PlayerHandler.LoadFile = function(self)

    local sFile = (self.DataDir .. self.DataFile)
    local aData = FileLoader:ExecuteFile(sFile, eFileType_Data)
    if (not aData) then
        return
    end

    self.PlayerData = aData
end

-------------------
PlayerHandler.SaveFile = function(self)

    local sData = string.format("return %s", (table.tostring((self.PlayerData or {}), "", "") or "{}"))
    local sFile = (self.DataDir .. self.DataFile)

    local bOk, sErr = FileOverwrite(sFile, sData)
    if (not bOk) then

        -- FIXME: Error Handler
        -- ErrorHandler()

        ServerLogError("Failed to open file %s for writing", sFile)
    end
end

------------------
PlayerHandler.InitClient = function(self, hClient, iChannel)

    self.RegisterFunctions(hClient, iChannel)

    EventCall(eServerEvent_OnClientInit, hClient, iChannel)
end

------------------
PlayerHandler.GetClientInfo = function(self, iChannel)

    self:CreateClientInfo(iChannel)
    return (self.CachedInfo[iChannel])
end

------------------
PlayerHandler.SetClientInfo = function(self, iChannel, aInfo)

    self:CreateClientInfo(iChannel)
    if (not aInfo) then
        error("no info")
    end

    self.CachedInfo[iChannel].IPData.Data = aInfo
end

------------------
PlayerHandler.CreateClientInfo = function(self, iChannel)

    if (self.CachedInfo[iChannel]) then
        return
    end

    local sChannelName = ServerDLL.GetChannelName(iChannel)
    local sHostName, sPort = string.match(sChannelName, "(.-):(%d+)")

    self.CachedInfo[iChannel] = {

        -- Client Profile Validated?
        Validated   = false,
        Validating  = false,

        ChannelNick = ServerDLL.GetChannelNick(iChannel),
        ChannelID   = iChannel,
        ProfileID   = nil,
        HostName    = sHostName,
        Port        = sPort,
        IP          = ServerDLL.GetChannelIP(iChannel),

        ----------
        IPData = {

            Data = {},

            Set             = function(x, y) x.Info.Data = y end,
            GetCountry      = function(x) local f = x.Info.Data return (f["Country"] or f["country"]) end,
            GetCountryCode  = function(x) local f = x.Info.Data return (f["CountryCode"] or f["countryCode"]) end
        },

        ----------
        Rank = {
            ID        = GetDefaultRank(),
            PendingID = nil,
            Dev       = false,

            Is    = function(x, y) return (x.Info.Rank.ID == y) end,
            Has   = function(x, y) return (x.Info.Rank.ID >= y) end,
            IsNot = function(x, y) return (x.Info.Rank.ID ~= y)  end,
            Set   = function(x, y) x.Info.Rank.ID = y  end,
            IsDev = function(x) return x.Info.Rank.Dev == true  end,
        },

        ----------
        Language = {
            Language  = SERVER_LANGUAGE,
            Preferred = SERVER_LANGUAGE
        }
    }
end

------------------
PlayerHandler.RegisterFunctions = function(hClient, iChannel)

    hClient.IsPlayer  = true
    hClient.Info      = PlayerHandler:GetClientInfo(iChannel)

    hClient.IsValidated     = function(self) return (self.Info.Validated == true) end
    hClient.GetProfileID    = function(self) return self.Info.ProfileID end
    hClient.GetProfile      = function(self) return self.Info.ProfileID end
    hClient.SetProfile      = function(self, hProfile) self.Info.ProfileID = hProfile end
    hClient.SetProfileID    = function(self, hProfile) self.Info.ProfileID = hProfile end
    hClient.GetInfo         = function(self) return self.Info end
    hClient.GetChannel      = function(self) return self.Info.ChannelID end
    hClient.GetIP           = function(self) return self.Info.IP end
    hClient.GetHostName     = function(self) return self.Info.HostName end
    hClient.GetPort         = function(self) return self.Info.Port end
    hClient.GetIPData       = function(self) return self.Info.IPData end
    hClient.GetCountryCode  = function(self) return self.Info.IPData:GetCountryCode() end
    hClient.GetCountry      = function(self) return self.Info.IPData:GetCountry() end
    hClient.GetServerRank   = function(self) return self.Info.Rank end
    hClient.GetAccess       = function(self) return self.Info.Rank.ID end
    hClient.SetAccess       = function(self, iRank) self.Info.Rank.ID = iRank self.Info.Rank.PendingID = nil self.Info.Rank.Dev = IsDevRank(iRank) end
    hClient.SetPendingAccess= function(self, iRank) self.Info.Rank.PendingID = iRank end
    hClient.GetPendingAccess= function(self) return self.Info.Rank.PendingID end
    hClient.HasAccess       = function(self, iRank) return self.Info.Rank.Has(self, iRank) end
    hClient.IsDevRank       = function(self, iRank) return self.Info.Rank.IsDev(self, iRank) end
    hClient.IsAccess        = function(self, iRank) return self.Info.Rank.Is(self, iRank) end
    hClient.GetLanguage     = function(self) return self.Info.Language.Language end
    hClient.SetLanguage     = function(self, sLang) self.Info.Language.Language = sLang end
    hClient.GetTeam         = function(self) return (g_pGame:GetTeam(self.id)) end
    hClient.SetTeam         = function(self, iTeam) g_pGame:SetTeam(iTeam, self.id) end
    hClient.GetKills        = function(self) return (g_gameRules:GetKills(self.id) or 0) end
    hClient.GetDeaths       = function(self) return (g_gameRules:GetDeaths(self.id) or 0) end
    hClient.GetRank         = function(self) return (g_gameRules:GetPlayerRank(self.id) or 0) end

    hClient.SetPreferredLanguage = function(self, sLang) self.Info.Language.Preferred = sLang end
    hClient.GetPreferredLanguage = function(self) return self.Info.Language.Preferred end

    hClient.Tick = function(self)

        -- It's delayed to allow the client to send !validate first!
        if (self.InitTimer.expired()) then
            if (not self.Connected) then
                ServerPCH:OnConnected(hClient, iChannel)
            end

            if (self:IsValidated()) then
                local iPending = self:GetPendingAccess()
                local aInfo = ServerAccess:GetRegisteredUser(self:GetProfile())
                local bIsPeasant = (self:GetAccess() == GetDefaultRank())
                if (bIsPeasant) then
                    if (iPending) then
                        self:SetAccess(iPending)
                        self.PendingAccess = nil

                    elseif (aInfo and bIsPeasant) then
                        ServerAccess:AssignAccess(self, aInfo.Rank)
                    end
                end
                --[[ -- This is the same as above!
                local aInfo = ServerAccess:GetRegisteredUser(self:GetProfileID())
                if (aInfo) then
                    if (aInfo and (aInfo.Rank > self:GetRank())) then
                        ServerAccess:AssignAccess(self, aInfo.Rank)
                        error("now giving rank")
                    end
                end
                ]]
            end
        end
    end
    hClient.Update = function(self)  end

    hClient.Info.Initialized = true
    hClient.InfoInitialized  = true
    hClient.InitTimer        = timernew(1.25)

    ServerLog("Client Initialized!")
end