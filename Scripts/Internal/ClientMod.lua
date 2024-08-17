--------------
ClientMod = (ClientMod or {

    ModURL = "http://nomad.nullptr.one/~finch/CryMP-Client.lua",
    DevURL = "http://nomad.nullptr.one/~finch/CryMP-Developer.lua",

    Server = {
    },

    Client = {
    },

    SynchedStorage = {
        [NULL_ENTITY] = {},
    },
})

--------------

eCM_Spectator = 0
eCM_Name = 1

--------------

eMPClient_Version = "mp_version"

----
eSvClient_Version       = "sv_version"
eSvClient_InitTimer     = "init_timer"
eSvClient_InstallTimer  = "install_timer"

---------------

eClientResp_OnNotInstalled  = 10
eClientResp_OnInstalled     = 11
eClientResp_OnPAKInstalled  = 12
eClientResp_NoPAKInstalled  = 13

---------------
ClientMod.Init = function(self)
    RegisterReset("ClientMod", function() ClientMod.SynchedStorage = {} end)
end

---------------
ClientMod.InitClient = function(self, hClient)

    -------
    hClient.ExecuteRPC = function(this, sMethod, aParams)
        RPC:OnPlayer(this, sMethod, aParams)
    end

    hClient.Execute = function(this, sCode, ...)
        sCode = string.formatex(sCode, ...)
        ClientMod.ExecuteOn({ this }, sCode)
    end
    hClient.ExecuteOthers = function(this, sCode, ...)
        sCode = string.formatex(sCode, ...)
        ClientMod.ExecuteOn(GetPlayers({ NotID = this.id }), sCode)
    end

    -------
    ServerLog("ClientMod.InitClient")
    ClientMod:Install(hClient)
end

---------------
ClientMod.StopSync = function(self, hEntityID, sID)

    table.checkM(self.SynchedStorage, hEntityID, {})
    self.SynchedStorage[hEntityID][sID] = nil
end


---------------
ClientMod.SyncCode = function(self, hEntityID, sID, sCode_Client, sCode_Server, aDependencies)

    local aNew = {
        Code = {
            Client = {
                _C = sCode_Client,
                _S = {}
            },
            Server = sCode_Server
        },
        Dependencies = aDependencies,
    }

    table.checkM(self.SynchedStorage, hEntityID, {})
    if (hEntityID == NULL_ENTITY) then
        sID = (sID .. UpdateCounter(eCounter_ClientModSync))
    end
    self.SynchedStorage[hEntityID][sID] = aNew
end

---------------
ClientMod.CheckSyncBind = function(self, hID)
    return (GetEntity(hID) ~= nil)
end

---------------
ClientMod.DependenciesOk = function(self, aLis)
    return table.it(aLis, function(x, i, v) return (x == true or x == nil) and (v == NULL_ENTITY or GetEntity(v) ~= nil) end)
end

---------------
ClientMod.SyncPart = function(self, hClient, sCode, bForce)

    local sPart = hClient.SyncStep
    if (sPart and (bForce or string.len(sPart) > 1024)) then
        hClient.SyncStep = nil
        self.ExecuteOn({ hClient }, sPart)
    end

    hClient.SyncStep = ((hClient.SyncStep or "") .. " " .. sCode)
end

---------------
ClientMod.SyncAll = function(self, hClient)

    local aSS = self.SynchedStorage
    local iOk = 0
    local iDeleted = 0

    for _, aInfo in pairs(aSS) do
        if (_ == NULL_ENTITY or self:CheckSyncBind(_)) then
            for __, aCode in pairs(aInfo) do
                Debug("sync id ",__)
                if (table.empty(aCode.Dependencies) or self:DependenciesOk(aCode.Dependencies)) then
                    if (not aCode.Code.Client._S[hClient.id]) then
                        iOk = iOk + 1
                        self:SyncPart(hClient, aCode.Code.Client._C)
                        local hServerPart = aCode.Code.Server
                        if (hServerPart) then
                            if (isFunc(hServerPart)) then
                                hServerPart(hClient, aCode)
                            else
                                HandleError("Bad server sync. its not a function!")
                            end
                        end
                    end
                else
                    iDeleted = (iDeleted + 1)
                    Debug("xyz Deleted Entity (dependencies not ok)",_)
                end
            end
        else
            iDeleted = (iDeleted + 1)
            Debug("Deleted Entity (bind not found) ",_)
        end
    end

    self:SyncPart(hClient, "", true)
    Logger:LogEventTo(RANK_ADMIN, eLogEvent_ClientMod, "@l_ui_clm_syncFinished", hClient:GetName(), iDeleted, iOk)
end

---------------
ClientMod.OnAll = function(self, sCode, aParams)

    if (aParams) then
        if (aParams.Sync) then
            local sSyncID  = (aParams.SyncID or "sync_" .. UpdateCounter(eCounter_ClientModSync))
            local hLinkID  = (aParams.BindID or NULL_ENTITY)
            local aDepends = (aParams.Dependencies or {})
            self:SyncCode(hLinkID, sSyncID, sCode, aParams.Server, aDepends)
        end

        -- Wat?
        if (aParams.StoreOnly) then
            return
        end
    end

    self.ExecuteOn(GetPlayers(), sCode)
end

---------------
ClientMod.ExecuteOn = function(aClients, sCode)

    -------
    if (sCode == nil) then
        throw_error("no code")
    end
    if (not string.fc(sCode, "L:")) then
        sCode = "L:" .. sCode
    end

    for _, hPlayer in pairs(aClients) do

        UpdateCounter(eCounter_ClientMod)
        g_gameRules.onClient:ClWorkComplete(hPlayer:GetChannel(), hPlayer.id, sCode)
        ServerLog("Executing %s",sCode)
    end
end

---------------
ClientMod.Install = function(self, hClient, bDeveloper)

    hClient.ClientInstallTimer = timernew()

    hClient:ExecuteRPC("Execute", { url = self.ModURL })
    if (hClient:IsTesting() or bDeveloper) then
        hClient:ExecuteRPC("Execute", { url = self.DevURL })
    end

    hClient:SetClientMod("IsInstalled", false)
    Logger:LogEventTo(RANK_ADMIN, eLogEvent_ClientMod, "@l_ui_clm_InstallStart", hClient:GetName())
end

---------------
ClientMod.OnInstalled = function(self, hClient)

    local iTime = math.calctime(hClient.ClientInstallTimer.diff(), nil, 2)
    Logger:LogEventTo(RANK_ADMIN, eLogEvent_ClientMod, "@l_ui_clm_Installed", hClient:GetName(), iTime)
    hClient:SetClientMod("IsInstalled", true)

    --fixme: code queue
    self:SyncAll(hClient)
end

---------------
ClientMod.OnPakInstalled = function(self, hClient)

    Logger:LogEventTo(RANK_ADMIN, eLogEvent_ClientMod, "@l_ui_clm_InstalledPak", hClient:GetName())

    --fixme: code queue
end

---------------
ClientMod.OnPakFailed = function(self, hClient)

    Logger:LogEventTo(RANK_ADMIN, eLogEvent_ClientMod, "@l_ui_clm_NotInstalledPak", hClient:GetName())

    --fixme: code queue
end

---------------
ClientMod.OnInstallFailed = function(self, hClient)

    local iTime = math.calctime(hClient.ClientInstallTimer.diff(), nil, 2)
    Logger:LogEventTo(RANK_ADMIN, eLogEvent_ClientMod, "@l_ui_clm_InstalledFailed", hClient:GetName(), iTime)
end

---------------
ClientMod.OnClientError = function(self, hClient, sType, sError)

    local sCode, sErr
    if (sType == "EXECUTE") then

        sCode, sErr = string.match(sError,"^{(.*)}={(.*)}$")
        if (sErr) then
            sErr = string.gsub(sErr, "^%[%w+ \".*\"%]:", "")
        end

        Logger:LogEventTo(RANK_ADMIN, eLogEvent_ClientMod, "@l_ui_clm_ExecError", hClient:GetName())
        Logger:LogEventTo(RANK_ADMIN, eLogEvent_ScriptError, "Code: " .. (sCode or "N/A"))
        Logger:LogEventTo(RANK_ADMIN, eLogEvent_ScriptError, "Error: " .. (sErr or "N/A"))
    end
end

---------------
ClientMod.DecodeResponse = function(self, hClient, iType, ...)

    if (iType == eCM_Spectator) then
        return self:DecodeSpecRequest(hClient, ...)

    elseif (iType == eCM_Name) then
        return self:DecodeNameRequest(hClient, ...)

    else
        throw_error("bad type to decode()")
    end
end

---------------
ClientMod.DecodeSpecRequest = function(self, hClient, iMessage)
    local bResolved = true

    if (iMessage == eClientResp_OnInstalled) then
        self:OnInstalled(hClient)

    elseif (iMessage == eClientResp_OnNotInstalled) then
        self:OnInstallFailed(hClient)

    elseif (iMessage == eClientResp_OnPAKInstalled) then
        self:OnPakInstalled(hClient)

    elseif (iMessage == eClientResp_NoPAKInstalled) then
        self:OnPakFailed(hClient)

    else
        Logger:LogEventTo(RANK_DEVELOPER, eLogEvent_ClientMod, "@l_ui_clm_invalidResponse", hClient:GetName(),g_tn(iMessage or 0))
        bResolved = false
    end

    return (bResolved == true)
end

---------------
ClientMod.DecodeNameRequest = function(self, hClient, sMessage)
    Debug("Hello, name request!!")
end