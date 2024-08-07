------------
AddCommand({
    Name = "validate",
    Access = GetLowestRank(), -- Must be accessible to all!

    Arguments = {
        {
            Name = "@l_command_arg_PROFILE_N",
            Desc = "@l_command_arg_PROFILE_D",
            Required = true,

            Optional = false,
            IsPlayer = false,
            IsNumber = false,
            Max      = 0,
            Min      = 0,
            Concat   = false,
        },
        {
            Name = "@l_command_arg_HASH_N",
            Desc = "@l_command_arg_HASH_D",
            Required = true
        }
    },

    Properties = {
        Hidden = true,
        NoChatResponse = true,
        NoConsoleResponse = true
    },

    -- self is the user unless specified otherwise
    Function = function(self, sProfile, sHash)
        if (self.Info.Validating or self.Info.Validated) then
            return
        end

        -- FIXME Validate!
        -- Validate()
        self.Info.Validating = true
        self:SetProfileID(sProfile)
        ServerPCH:ValidateClient(self, sProfile, sHash)

        return true
    end
})