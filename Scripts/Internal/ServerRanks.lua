----------------
ServerAccess = {

    RankList = {
        { Authority   = 0, ID = "GUEST",      Name = "Guest",       Color = CRY_COLOR_GREEN },
        { Authority   = 1, ID = "PLAYER",     Name = "Player",      Color = CRY_COLOR_WHITE },
        { Authority   = 2, ID = "PREMIUM",    Name = "Premium",     Color = CRY_COLOR_WHITE },
        { Authority   = 3, ID = "MODERATOR",  Name = "Moderator",   Color = CRY_COLOR_WHITE },
        { Authority   = 4, ID = "ADMIN",      Name = "Admin",       Color = CRY_COLOR_WHITE },
        { Authority   = 5, ID = "HEADADMIN",  Name = "HeadAdmin",   Color = CRY_COLOR_WHITE },
        { Authority   = 6, ID = "SUPERADMIN", Name = "SuperAdmin",  Color = CRY_COLOR_WHITE },
        { Authority   = 7, ID = "DEVELOPER",  Name = "Developer",   Color = CRY_COLOR_WHITE },
        { Authority   = 8, ID = "OWNER",      Name = "Owner",       Color = CRY_COLOR_WHITE }
    },

    RegisteredRanks = {},
    RegisteredDevs = {},
    RegisteredUsers = {
        ["1063698"] = {
            Name          = "Marisa",
            ProfileID     = "1063698",
            Rank          = 8,
            ProtectedName = true,
            Login         = "password"
        }
    },

    DataDir  = (SERVER_DIR_DATA .. "Users\\"),
    DataFile = "Users.lua",

    LowestRank = 999,
    HighestRank = -1,
    DefaultRank = 0

}

----------------
ServerAccess.Init = function(self)

    GetInvalidID     = self.GetInvalidID

    GetDefaultRank   = self.GetDefaultRank
    GetLowestRank    = self.GetLowestRank
    GetHighestRank   = self.GetHighestRank
    GetRankInfo      = self.GetRankInfo
    GetRankName      = self.GetRankName
    GetRankColor     = self.GetRankColor
    GetRankAuthority = self.GetRankAuthority
    IsDevRank        = self.IsDevRank
    IsPremiumRank    = self.IsPremiumRank
    IsAdminRank      = self.IsAdminRank
    GetDevRanks      = self.GetDevRanks
    GetDevs          = function() return GetPlayers({ Access = GetDevRanks(1) }) end

    -- Reset this in case of changes
    RANK_DEFAULT = nil

    self.RegisteredUsers = table.merge(self.RegisteredUsers, ConfigGet("Ranks.UserList", {}, eConfigGet_Array))

    self:LoadFile()
    self:RegisterRanks()
    Logger:InitLogEvents()

    ServerLog("Registered %d Server Ranks", table.count(self.RegisteredRanks))

    local sUserLog = string.format("Loaded ${red}%d${gray} Registered Users", table.count(self.RegisteredUsers))
    Logger:LogEventTo(GetDevs(), eLogEvent_DataLog, sUserLog)

    LinkEvent(eServerEvent_OnScriptReload, "ServerAccess", "SaveFile")


    -------------
    GetAdmins          = function() return GetPlayers({ Access = RANK_ADMIN }) end
end

----------------
ServerAccess.InitClient = function(self, hClient)

    local sName = hClient:GetName()
    local sProfileID = hClient:GetProfileID()
    local sIP = hClient:GetIP()

    --ServerLog(table.tostring(self.RegisteredUsers))
    --ServerLog("PROF= %s", hClient:GetProfileID())

    local aRegInfo = self:GetRegisteredUser(sProfileID)
    if (aRegInfo) then
        ServerLog("Client %s is a Registered User", sName)
        self:AssignAccess(hClient, aRegInfo.Rank, (not hClient:IsValidated()))
        return
    end

    if (self:IsIPLocalHost(sIP)) then
        ServerLog("Client %s Connecting on localhost, Assigning Highest Access %s", sName, GetRankName(GetHighestRank()))
        self:AssignAccess(hClient, GetHighestRank())
        return
    end

    if (not self:IsProfileValid(sProfileID)) then
        ServerLog("Client %s has an invalid Profile.. Assigning Default Rank %s", sName, GetRankName(RANK_DEFAULT))
        self:AssignAccess(hClient, RANK_DEFAULT)
        return
    end

    ServerLog("Assigning Default Rank %s to Client %s", GetRankName(RANK_DEFAULT), sName)
    self:AssignAccess(hClient, RANK_DEFAULT)
end

----------------
ServerAccess.IsIPLocalHost = function(self, sIP)

    local bIsLocal = string.matchex(sIP,
        "127%.0%.0%.1",
        "192%.168%.0%.1"
    )
    if (bIsLocal and Server.IS_PUBLIC) then
        return false
    end

    return bIsLocal
end

----------------
ServerAccess.IsProfileValid = function(self, sID)
    return (sID ~= "0" or sID ~= "-1")
end

----------------
ServerAccess.GetInvalidID = function(self)
    return "0"
end

----------------
ServerAccess.GetRegisteredUser = function(self, sID)
    return self.RegisteredUsers[g_ts(sID)]
end

----------------
ServerAccess.IsProtectedName = function(self, sName, sExceptionID)

    local bIsProtected = false
    local sLowerName   = string.lower(sName)

    for sID, aInfo in pairs(self.RegisteredUsers) do
        if (sID ~= sExceptionID) then
            if (aInfo.ProtectedName) then

                if (sLowerName == string.lower(aInfo.Name) or string.match(sLowerName, "^" .. string.lower(aInfo.Name))) then
                    bIsProtected = true
                end
            end
        end
    end

    return bIsProtected
end

----------------
ServerAccess.AssignAccess = function(self, hClient, iRank, bPending)

    if (hClient:HasAccess(iRank)) then
        return ServerLog("Client %s Already Rank %d", hClient:GetName(), iRank)
    end

    if (bPending) then
        hClient:SetPendingAccess(iRank)
    else
        hClient:SetAccess(iRank)
    end
    ServerLog("Assigned %sRank %d to %s", (bPending and "Pending " or ""), iRank, hClient:GetName())
end

-------------------
ServerAccess.RegisterRanks = function(self)

    local aList = ConfigGet("Ranks.RankList", self.RankList, eConfigGet_Array)

    local iAuthority
    local iFirstAdminRank = -1
    for _, aRank in pairs(aList) do

        iAuthority = aRank.Authority
        if (iAuthority > self.HighestRank) then
            self.HighestRank = iAuthority
        end
        if (iAuthority < self.LowestRank) then
            self.LowestRank = iAuthority
        end

        if (aRank.Default) then
            _G["RANK_DEFAULT"] = iAuthority
            self.DefaultRank   = iAuthority
        end

        if (aRank.Developer) then
            self.RegisteredDevs[iAuthority] = true
        end

        if (aRank.Admin or (iFirstAdminRank ~= -1 and aRank.Authority >= iFirstAdminRank)) then
            if (iFirstAdminRank == -1) then
                iFirstAdminRank = aRank.Authority
            end
            aRank.Admin = true
        end

        _G[("RANK_" .. aRank.ID)] = iAuthority
        self.RegisteredRanks[iAuthority] = table.copy(aRank)
    end

    if (RANK_DEFAULT == nil) then
        _G["RANK_DEFAULT"] = GetLowestRank()
    end
end

-------------------
ServerAccess.LoadFile = function(self)

    local sFile = (self.DataDir .. self.DataFile)
    local aData = FileLoader:ExecuteFile(sFile, eFileType_Data)
    if (not aData) then
        return {}
    end

    local aParsed = self.RegisteredUsers
    for sProfileId, aUser in pairs(aData) do
        aParsed[g_ts(aUser.ProfileID)] = aUser
    end

    self.RegisteredUsers = aParsed
end

-------------------
ServerAccess.SaveFile = function(self)

    local sData = string.format("return %s", (table.tostring((self.RegisteredUsers or {}), "", "") or "{}"))
    local sFile = (self.DataDir .. self.DataFile)

    local bOk, sErr = FileOverwrite(sFile, sData)
    if (not bOk) then

        -- FIXME: Error Handler
        -- ErrorHandler()

        ServerLogError("Failed to open file %s for writing", sFile)
    end
end

-------------------
ServerAccess.GetDefaultRank = function(iRank)
    return (ServerAccess.DefaultRank)
end

-------------------
ServerAccess.GetLowestRank = function(iRank)
    return (ServerAccess.LowestRank)
end

-------------------
ServerAccess.GetHighestRank = function(iRank)
    return (ServerAccess.HighestRank)
end

-------------------
ServerAccess.GetRankAuthority = function(iRank)
    return ServerAccess.GetRankInfo(iRank, "Authority")
end

-------------------
ServerAccess.GetRankName = function(iRank)
    return ServerAccess.GetRankInfo(iRank, "Name")
end

-------------------
ServerAccess.GetRankColor = function(iRank)
    return ServerAccess.GetRankInfo(iRank, "Color")
end

-------------------
ServerAccess.GetRankInfo = function(iRank, sMember)
    if (not iRank) then
        return ServerLogWarning("Rank %s does not exist", g_ts(iRank))
    end

    local aInfo = ServerAccess.RegisteredRanks[iRank]
    if (aInfo == nil) then
        return ServerLogWarning("Rank %s does not exist", g_ts(iRank))
    end

    if (sMember ~= nil) then
        return aInfo[sMember]
    end

    return aInfo
end

-------------------
ServerAccess.IsDevRank = function(iRank)

    --local iLowestDev
    --for _ in pairs(self.RegisteredDevs) do
    --    if (iRank >= _) then
    --        return true
    --    end
    --end
    return (ServerAccess.RegisteredDevs[iRank] == true)
end

-------------------
ServerAccess.IsPremiumRank = function(iRank)
    return (GetRankInfo(iRank, "Premium") == true)
end

-------------------
ServerAccess.IsAdminRank = function(iRank)
    return (GetRankInfo(iRank, "Admin") == true)
end

-------------------
ServerAccess.GetDevRanks = function(iId)
    local aRanks = {}
    for _ in pairs(ServerAccess.RegisteredDevs) do
        table.insert(aRanks, _)
    end

    if (iId) then
        local aOne = aRanks[iId]
        if (aOne == nil) then
            return GetHighestRank()
        end

        return aOne
    end
    return (aRanks)
end