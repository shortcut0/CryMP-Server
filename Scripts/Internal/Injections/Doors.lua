local ServerDoor = {

    -----------------
    This = "Door",
    PatchEntities = true,

    -----------------
    PostInit = function(self)
    end,

    ---------------------------------------------
    --- Door.Open
    ---------------------------------------------
    {

        Class = "Door",
        Target = { "Open" },
        Type = eInjection_Replace,

        ------------------------
        Function = function(self, user, mode, bForceRelative)

            -- =================
            -- CryMP
            bForceRelative = (bForceRelative or ConfigGet("General.Immersion.Doors.AlwaysOpenRelativeToUsers", true, eConfigGet_Boolean))
            if (bForceRelative) then
            end

            local lastAction = self.action
            if (mode == DOOR_TOGGLE) then
                if (self.action == DOOR_OPEN) then
                    self.action = DOOR_CLOSE
                else
                    self.action = DOOR_OPEN
                end
            else
                self.action = mode
            end

            if (lastAction == self.action) then
                return 0
            end

            if (self.AutoClose) then
                if (self.AutoCloseTimer) then
                    Script.KillTimer(self.AutoCloseTimer)
                end
                self.AutoCloseTimer = Script.SetTimer(self.AutoClose.Time * 1000, function()
                    if (self and self:IsOpen()) then
                        self:Open(Server.ServerEntity, DOOR_CLOSE)
                    end
                end)
            end

            if (self.Properties.Rotation.fRange ~= 0) then
                local open = false
                local fwd  = true

                if (self.action == DOOR_OPEN) then
                    if (user and (bForceRelative or tonumber(self.Properties.Rotation.bRelativeToUser) ~=0)) then
                        local userForward=g_Vectors.temp_v2
                        local myPos=self:GetWorldPos(g_Vectors.temp_v3)
                        local userPos=user:GetWorldPos(g_Vectors.temp_v4)
                        SubVectors(userForward,myPos,userPos)
                        NormalizeVector(userForward)

                        local dot = dotproduct3d(self.frontAxis, userForward)

                        if (dot < 0) then
                            fwd = false
                        end
                    end

                    open = true
                end

                self.fwd = fwd
                self:Rotate(open, fwd)
                self.allClients:ClRotate(open, fwd)
            end

            if (self.Properties.Slide.fRange ~= 0) then
                local open = (self.action == DOOR_OPEN)

                self:Slide(open)
                self.allClients:ClSlide(open)
            end

            -- Hello! Is This Needed?
            if (AI) then
                if (self.action == DOOR_OPEN) then
                    AI.ModifySmartObjectStates( self.id, "Open-Closed" )
                    BroadcastEvent(self, "Open")
                elseif (self.action == DOOR_CLOSE) then
                    AI.ModifySmartObjectStates( self.id, "Closed-Open" )
                    BroadcastEvent(self, "Close")
                end
            end

            return 1
        end
    },

}

------------
ServerInjector.InjectAll(ServerDoor)