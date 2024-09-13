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
    TryGetRankInfo   = self.TryGetRankInfo
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

    local aConfigUsers = ConfigGet("Ranks.UserList", {}, eConfigGet_Array)
    self.HardCodedUsers = aConfigUsers
    self.RegisteredUsers = table.merge(self.RegisteredUsers, aConfigUsers)

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
        self:AssignAccess(hClient, GetHighestRank(), nil, nil, true)
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
ServerAccess.ChangeAccess = function(self, hAdmin, hClient, iAccess)

    local bTesting = (hAdmin:GetAccess(GetHighestRank()) and hAdmin:IsTesting())

    local iClientAccess = hClient:GetAccess()
    local iAdminAccess  = hAdmin:GetAccess()

    local sColor  = GetRankColor(iAccess)
    local sAccess = GetRankName(iAccess)

    if (not bTesting and (iAccess > iAdminAccess or hClient:GetAccess() >= iAdminAccess)) then
        return false, hAdmin:Localize("@l_ui_insufficientAccess")
    elseif (iAccess == iClientAccess) then
        return false, hAdmin:Localize("@l_ui_accessEqual", { sAccess })
    end

    if (not hClient:IsValidated()) then
        return false, hAdmin:Localize("@l_ui_clientNotValidated", { hClient:GetName() })
    end

    local sID = hClient:GetProfileID()
    local bIsDelete = iAccess == GetLowestRank()
    if (self:IsHardCodedUser(sID)) then
        if (bIsDelete) then
            return false, hAdmin:Localize("@l_ui_cannotRemoveHCUsers")
        end
    end

    local bDemoted = (iClientAccess > iAccess)
    Logger:LogEventTo(GetPlayers({ Force = hClient.id, Access = RANK_ADMIN }), eLogEvent_Users, "@l_ui_changedAccess", hClient:GetName(), (bDemoted and "@l_ui_demoted" or "@l_ui_promoted"), sAccess, sColor)

    if (bIsDelete) then
        self:DeleteUsers(sID, true)
    else
        local aUserInfo = (self:GetRegisteredUser(sID) or self:InsertUser(sID))
        aUserInfo.Rank          = iAccess
    end

    self:AssignAccess(hClient, iAccess, false, true) -- not pending + quiet
    self:SaveFile()
end

----------------
ServerAccess.AddUserByID = function(self, hAdmin, sID, sName, iAccess)

    local bTesting      = (hAdmin:GetAccess(GetHighestRank()) and hAdmin:IsTesting())
    local iAdminAccess  = hAdmin:GetAccess()

    local sColor  = GetRankColor(iAccess)
    local sAccess = GetRankName(iAccess)

    if (not bTesting and (iAccess > iAdminAccess)) then
        return false, hAdmin:Localize("@l_ui_insufficientAccess")
    end

    local aUserInfo = self:GetRegisteredUser(sID)
    local bIsDelete = iAccess == GetLowestRank()
    if (aUserInfo) then

        local iClientAccess = aUserInfo.Rank

        if (self:IsHardCodedUser(sID)) then
            if (bIsDelete) then
                return false, hAdmin:Localize("@l_ui_cannotRemoveHCUsers")
            end
        end
        if (bIsDelete) then
            self:DeleteUsers(sID)
            return true
        end

        if (not bTesting and (iClientAccess > iAdminAccess)) then
            return false, hAdmin:Localize("@l_ui_insufficientAccess")
        elseif (iAccess == iClientAccess) then
            return false, hAdmin:Localize("@l_ui_accessEqual", { sAccess })
        end

        aUserInfo.Rank = iAccess

        local bDemoted = (iClientAccess > iAccess)
        Logger:LogEventTo(GetPlayers({ Access = RANK_ADMIN }), eLogEvent_Users, "@l_ui_assignedAccessTo", ("@l_ui_registeredUser " .. aUserInfo.Name), sColor, sAccess, (""))
    elseif (bIsDelete) then
        return false, hAdmin:Localize("@l_ui_chooseHigherValue")
    else
        Logger:LogEventTo(GetPlayers({ Access = RANK_ADMIN }), eLogEvent_Users, "@l_ui_addedRegisteredUser", sName, sID, sColor, sAccess)
        self:InsertUser(sID, iAccess, sName)
    end

    self:SaveFile()
end

----------------
ServerAccess.InsertUser = function(self, sID, iRank, sName)

    local aUserInfo = self.RegisteredUsers[sID]
    if (aUserInfo) then
        return aUserInfo
    end

    self.RegisteredUsers[sID] = {
        Name          = sName,
        Rank          = iRank,
        Login         = "1234", -- TODO
        ProfileID     = sID,
        ProtectedName = (not ServerNames:IsNomad(sName))
    }

    return self.RegisteredUsers[sID]
end

----------------
ServerAccess.DeleteUsers = function(self, sID, bQuiet)

    local aUserInfo = self.RegisteredUsers[sID]
    if (aUserInfo) then
        local sColor, sName = GetRankColor(aUserInfo.Rank), GetRankName(aUserInfo.Rank)
        if (not bQuiet) then
            Logger:LogEventTo(GetPlayers({ Access = RANK_ADMIN }), eLogEvent_Users, "@l_ui_userDeleted", aUserInfo.Name, aUserInfo.ProfileID, sName, sColor)
        end
        self.RegisteredUsers[sID] = nil
        return true
    end

    return false
end

----------------
ServerAccess.IsHardCodedUser = function(self, sID)
    return self.HardCodedUsers[sID] ~= nil
end

----------------
ServerAccess.AssignAccess = function(self, hClient, iRank, bPending, bQuiet, bForceValidation)

    if (hClient:IsAccess(iRank)) then
        return ServerLog("Client %s Already Rank %d", hClient:GetName(), iRank)
    end

    if (bPending) then
        hClient:SetPendingAccess(iRank)
    else
        hClient:SetAccess(iRank)
        if (bForceValidation) then
            hClient.Info.Validated  = true
            hClient.Info.Validating = false
            hClient.InitTimer.setexpiry(0)
            hClient:Tick() -- Update!
        end
    end

    if (not bQuiet) then
        Logger:LogEventTo(GetPlayers({ Force = hClient.id, Access = RANK_ADMIN }), eLogEvent_Users, "@l_ui_assignedAccessTo", hClient:GetName(), GetRankColor(iRank), GetRankName(iRank), (bPending and "@l_ui_pending-" or ""))
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
        aUser.Name = aUser.Name or "Nomad"
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
ServerAccess.TryGetRankInfo = function(hID)

    local hFound
    local sID       = (g_ts(hID) or "none") -- FIXME: what if a rank name starts with "none" ???
    local sID_Lower = (g_ts(hID) or "none") -- FIXME: what if a rank name starts with "none" ???
    local iID       = (g_tn(hID) or -1)

    for _, aInfo in pairs(ServerAccess.RegisteredRanks) do
        local sLowerID = string.lower(aInfo.ID)
        local sLowerName = string.lower(aInfo.Name)
        if (sLowerID == sID_Lower or sLowerName == sID_Lower or aInfo.Authority == iID) then
            hFound = aInfo
            break -- stop on complete matches
        elseif (string.match(sLowerID, "^" .. string.escape(sID_Lower)) or string.match(sLowerName, "^" .. string.escape(sID_Lower))) then
            if (hFound) then
                hFound = nil
                break
            end
            hFound = aInfo
        end
    end

    ServerLog(table.tostring(hFound))
    return hFound
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
ServerAccess.IsPremiumRank = function(iRank, bLiteral)
    local bPremium = (GetRankInfo(iRank, "Premium") == true)
    if (not bPremium and not bLiteral) then
        local iLowestPremium = -1
        for _, aInfo in pairs(ServerAccess.RegisteredRanks) do
            if (aInfo.Premium) then
                if (iLowestPremium == -1 or aInfo.Authority <= iLowestPremium) then
                    iLowestPremium = aInfo.Authority
                end
            end
            if (iLowestPremium ~= -1 and aInfo.Authority > iLowestPremium) then
                return true
            end
        end
        bPremium = false
    end
    return bPremium
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