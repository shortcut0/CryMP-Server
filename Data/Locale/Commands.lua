------------------------------------------------------
------------------------------------------------------
--- RETURN TYPES

local sCmdPreSpace = "    "

CreateLocalization("l_commandresp_con_failed", {
    english = { regular  = sCmdPreSpace .. "${gray}(${white}${1}: ${red}Failed${2}${grey})", }
})

CreateLocalization("l_commandresp_con_scripterror", {
    english = {
        regular  = sCmdPreSpace .. "${gray}(${white}${1}: ${red}Failed: Script Error${grey})",
        extended  = sCmdPreSpace .. "${gray}(${white}${1}: ${red}Failed: Script Error (${2})${grey})",
    }
})

CreateLocalization("l_commandresp_con_condition", {
    english = { regular = sCmdPreSpace .. "(${1}: ${red}Failed: Unfulfilled Conditions${gray})" }
})


CreateLocalization("l_commandresp_con_success", {
    english = { regular = sCmdPreSpace .. "(${1}: ${green}Success${gray}${2})" }
})

CreateLocalization("l_commandresp_con_nofeedback", {
    english = { regular = sCmdPreSpace .. "(${1}: ${orange}No Feedback${gray}${2})" }
})

CreateLocalization("l_commandresp_con_notfound", {
    english = { regular  = sCmdPreSpace .. "${gray}(${white}${1}: ${red}Command Not Found${grey})", }
})

CreateLocalization("l_commandresp_con_noaccess", {
    english = { regular  = sCmdPreSpace .. "${gray}(${white}${1}: ${red}Command Not Found${grey})", }
})

CreateLocalization("l_commandresp_con_reserved", {
    english = { regular  = sCmdPreSpace .. "${gray}(${white}${1}: ${red}Reserved for {2}${grey})", }
})

------------------------------------------------------
------------------------------------------------------
--- CHAT MESSAGES

CreateLocalization("l_commandresp_chat_failed", {
    english = { regular = "(${1}: Failed${2})" }
})

CreateLocalization("l_commandresp_chat_scripterror", {
    english = {
        regular = "(${1}: Failed: Script Error)",
        extended  = "(${1}: Failed: Script Error, Check your Console!)",
    }
})

CreateLocalization("l_commandresp_chat_condition", {
    english = { regular = "(${1}: Failed: Unfulfilled Conditions)" }
})

CreateLocalization("l_commandresp_chat_success", {
    english = { regular = "(${1}: Success${2})" }
})

CreateLocalization("l_commandresp_chat_nofeedback", {
    english = { regular = "(${1}: No Feedback${2})" }
})

CreateLocalization("l_commandresp_chat_notfound", {
    english = { regular  = "(${1}: Unknown Command)", }
})

CreateLocalization("l_commandresp_chat_noaccess", {
    english = { regular = "(${1}: Unknown Command)" }
})

CreateLocalization("l_commandresp_chat_reserved", {
    english = { regular = "(${1}: Reserved for {2})" }
})

CreateLocalization("l_commandresp_chat_manyfound", {
    english = { regular = "(${1}: Open your Console to view the ${2} Results)" }
})



------------------------------------------------------
------------------------------------------------------
--- ERROR TYPES

CreateLocalization("l_commanderr_test", {

    -- CONSOLE:
    -- 1 = Command name (capitalized), 2 = Description of the fail

    english = {
        regular = "TEST Failed :ooooo"
    }
})

------------------------------------------------------
------------------------------------------------------
--- !Validate

CreateLocalization("l_command_validate_arg1_desc", {
    english = { regular = "The Profile ID" },
    spanish = { regular = "El ID de Perfil" },
    german = { regular = "Die Profil-ID" },
    russian = { regular = "ID profilya" }
})

CreateLocalization("l_command_validate_arg1_name", {
    english = { regular = "Profile" },
    spanish = { regular = "Perfil" },
    german = { regular = "Profil" },
    russian = { regular = "Profil" }
})

CreateLocalization("l_command_validate_arg2_desc", {
    english = { regular = "The Profile Hash" },
    spanish = { regular = "El Hash del Perfil" },
    german = { regular = "Der Profil-Hash" },
    russian = { regular = "Hash profilya" }
})

CreateLocalization("l_command_validate_arg2_name", {
    english = { regular = "Hash" },
    spanish = { regular = "Hash" },
    german = { regular = "Hash" },
    russian = { regular = "Hash" }
})

------------------------------------------------------
------------------------------------------------------