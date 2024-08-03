------------
AddCommand({
    Name = "validate",
    Access = GetLowestRank(), -- Must be accessible to all!

    Arguments = {
        {
            Name = "@l_command_validate_arg1_name",
            Desc = "@l_command_validate_arg1_desc",
            Required = true,

            Optional = false,
            IsPlayer = false,
            IsNumber = false,
            Max      = 0,
            Min      = 0,
            Concat   = false,
        },
        {
            Name = "@l_command_validate_arg2_name",
            Desc = "@l_command_validate_arg2_desc",
            Required = true
        }
    },

    Properties = {
        NoChatResponse = true,
        Quiet = true, -- Silence feedback from this command
        Host = nil,
        HostCondition = {

            IgnoreSilence = true,
            ErrorMessage = "You're already Validated",
            Key = "Info.Validated", -- A member key
            Value = { false, nil }, -- Required value(s)
        }
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