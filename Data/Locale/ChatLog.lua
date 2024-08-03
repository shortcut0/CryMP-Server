-----------------
--- Server locale

CreateLocalization("l_console_chatmessage_teamtag", {
    english = { regular = "TEAM" },
    spanish = { regular = "EQUIPO" },
    german = { regular = "TEAM" },
    russian = { regular = "KOMANDA" }
})

CreateLocalization("l_console_chatmessage_pmtag", {
    english = { regular = "PM" }
})

CreateLocalization("l_console_chatmessage_all", {

    -- 1 = Sender Name, 2 = Message
    english = { regular = "${color_white}${2}", },
})

CreateLocalization("l_console_chatmessage_team", {

    -- 1 = Sender Name, 2 = Message
    english = { regular = "${color_white}${blue}${2}", },
})

CreateLocalization("l_console_chatmessage_target", {

    -- 1 = Sender Name, 2 = Message
    english = { regular = "${color_white}${2}", },
})

CreateLocalization("l_console_chatmessage_pm", {

    -- 1 = Sender Name, 2 = Message
    english = { regular = "${color_white}${green}${2}", },

})