-----------------
--- Server locale

-- (TEAM)
CreateLocalization("l_console_chatmessage_teamtag", {
    english = { regular = "TEAM" },
    spanish = { regular = "EQUIPO" },
    german  = { regular = "TEAM" },
    russian = { regular = "KOMANDA" }
})

-- (PM)
CreateLocalization("l_console_chatmessage_pmtag", { english = { regular = "PM" } })

-------
CreateLocalization("l_console_chatmessage_all",     { english = { regular = "${color_white}${2}", }, })
CreateLocalization("l_console_chatmessage_team",    { english = { regular = "${color_white}${blue}${2}", }, })
CreateLocalization("l_console_chatmessage_target",  { english = { regular = "${color_white}${2}", }, })
CreateLocalization("l_console_chatmessage_pm",      { english = { regular = "${color_white}${green}${2}", }, })