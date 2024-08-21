AddCommand({
    Name 	= "vote",
    Access	= RANK_GUEST,

    Arguments = {
        { "@l_ui_voteType", "@l_ui_voteType_d", Required = true },
        { "@l_ui_argument", "@l_ui_argument_d", Optional = true }
    },

    Properties = {
        Host = 'ServerVoting',
    },

    Function = function(self, hPlayer, sType, ...)
        return self:StartVote(hPlayer, sType, ...)
    end
})

AddCommand({
    Name 	= "yes",
    Access	= RANK_GUEST,

    Arguments = {
    },

    Properties = {
        Host = 'ServerVoting',
    },

    Function = function(self, hPlayer)
        return self:VoteYes(hPlayer)
    end
})

AddCommand({
    Name 	= "no",
    Access	= RANK_GUEST,

    Arguments = {
    },

    Properties = {
        Host = 'ServerVoting',
    },

    Function = function(self, hPlayer)
        return self:VoteNo(hPlayer)
    end
})