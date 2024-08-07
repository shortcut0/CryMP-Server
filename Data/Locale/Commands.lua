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

CreateLocalization("l_commandresp_con_premium", {
    english = sCmdPreSpace .. "${gray}(${white}${1}: ${red}Failed: Reserved for Premium Members${grey})",
})

CreateLocalization("l_commandresp_con_noaccess", {
    english = sCmdPreSpace .. "${gray}(${white}${1}: ${red}Failed: Insufficient Access${grey})",
})

CreateLocalization("l_commandresp_con_condition", {
    english = { regular = sCmdPreSpace .. "${gray}(${1}: ${red}Failed: Unfulfilled Conditions${gray})" }
})


CreateLocalization("l_commandresp_con_success", {
    english = { regular = sCmdPreSpace .. "${gray}(${1}: ${green}Success${gray}${2})" }
})

CreateLocalization("l_commandresp_con_nofeedback", {
    english = { regular = sCmdPreSpace .. "${gray}(${1}: ${orange}No Feedback${gray}${2})" }
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
    english = { regular = "(${1}: ${2})" }
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

CreateLocalization("l_commandresp_chat_premium", {
    english = "(${1}: Reserved for Premium)"
})

CreateLocalization("l_commandresp_chat_noaccess", {
    english = "(${1}: Insufficient Access)"
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
--- ARGUMENT MESSAGES

CreateLocalization("l_commandarg_player_notfounnd", {
    english = "Player ${1} not found",
    russian = "Player ${1} ne naiden",
    turkish = "Oyuncu ${1} bulunamadi",
    german = "Spieler ${1} nicht gefunden",
    spanish = "Jugador ${1} no encontrado"
})

CreateLocalization("l_commandarg_required", {
    english = "Argument <${1}> Expects a value",
    russian = "Argument <${1}> ozhidaet znachenie",
    turkish = "Arguman <${1}> bir deger bekliyor",
    german = "Argument <${1}> erwartet einen Wert",
    spanish = "Argumento <${1}> espera un valor"
})

CreateLocalization("l_commandarg_notnumber", {
    english = "Argument ${1} Expects a Number",
    russian = "Argument ${1} ozhidaet chislo",
    turkish = "Arguman ${1} bir sayi bekliyor",
    german = "Argument ${1} erwartet eine Zahl",
    spanish = "Argumento ${1} espera un numero"
})

CreateLocalization("l_commandarg_toolow", {
    english = "Argument ${1} Lower Limit ${2}",
    russian = "Argument ${1} nizhnij predel ${2}",
    turkish = "Arguman ${1} alt sinir ${2}",
    german = "Argument ${1} untere Grenze ${2}",
    spanish = "Argumento ${1} limite inferior ${2}"
})

CreateLocalization("l_commandarg_toohigh", {
    english = "Argument ${1} Upper Limit ${2}",
    russian = "Argument ${1} verkhniy predel ${2}",
    turkish = "Arguman ${1} üst sinir ${2}",
    german = "Argument ${1} obere Grenze ${2}",
    spanish = "Argumento ${1} limite superior ${2}"
})


------------------------------------------------------
------------------------------------------------------
CreateLocalization("l_ui_no_description", {
    english = "No Description Available",
    russian = "Net Opisaniya",
    turkish = "Aciklama Yok",
    german = "Keine Beschreibung",
    spanish = "Sin Descripcion"
})

CreateLocalization("l_ui_command_desc_commands", {
    english = "Lists all Available Commands to your Console",
    russian = "Spisok vsekh dostupnykh komand dlya vashey konsoli",
    turkish = "Konsolunuzdaki Tüm Kullanilabilir Komutlari Listeler",
    german = "Listet alle verfügbaren Befehle auf Ihrer Konsole auf",
    spanish = "Lista todos los comandos disponibles en tu consola"
})

CreateLocalization("l_ui_commands_openconsole", {
    english = "Open your Console to View the List of Available Commands!",
    russian = "Otkroyte konsol dlya prosmotra spiska dostupnykh komand!",
    turkish = "Mevcut Komutlarin Listesini Görmek Icin Konsolunuzu Acin!",
    german = "Öffnen Sie Ihre Konsole, um die Liste der verfügbaren Befehle anzuzeigen!",
    spanish = "¡Abre tu consola para ver la lista de comandos disponibles!"
})

CreateLocalization("l_ui_commands_help", {
    english = "${yellow}INFO: ${gray}Type ${white}!${gray}Command ${yellow}--help ${gray} To View Info about a Command",
    russian = "${yellow}INFO: ${gray}Vvedite ${white}!${gray}Komanda ${yellow}--help ${gray} dlya prosmotra informatsii o komande",
    turkish = "${yellow}BILGI: ${gray}${white}!${gray}Komut ${yellow}--yardim ${gray} yazarak bir komut hakkinda bilgi edinebilirsiniz",
    german = "${yellow}INFO: ${gray}Geben Sie ${white}!${gray}Befehl ${yellow}--hilfe ${gray} ein, um Informationen zu einem Befehl anzuzeigen",
    spanish = "${yellow}INFO: ${gray}Escribe ${white}!${gray}Comando ${yellow}--ayuda ${gray} para ver información sobre un comando"
})
