------------------------------------------------------
------------------------------------------------------
--- RETURN TYPES

local sCmdPreSpace = "    "

CreateLocalization("l_commandresp_con_failed", {
    english = { regular  = sCmdPreSpace .. "${gray}(${white}${1}: ${red}Failed${2}${grey})", },
    german = { regular  = sCmdPreSpace .. "${gray}(${white}${1}: ${red}Fehlgeschlagen${2}${grey})", },
    spanish = { regular  = sCmdPreSpace .. "${gray}(${white}${1}: ${red}Fallido${2}${grey})", },
    turkish = { regular  = sCmdPreSpace .. "${gray}(${white}${1}: ${red}Basarisiz${2}${grey})", },
    russian = { regular  = sCmdPreSpace .. "${gray}(${white}${1}: ${red}Neudacha${2}${grey})", },
    czech = { regular  = sCmdPreSpace .. "${gray}(${white}${1}: ${red}Selhalo${2}${grey})", }
})

CreateLocalization("l_commandresp_con_scripterror", {
    english = {
        regular  = sCmdPreSpace .. "${gray}(${white}${1}: ${red}Failed: Script Error${grey})",
        extended  = sCmdPreSpace .. "${gray}(${white}${1}: ${red}Failed: Script Error (${2})${grey})",
    },
    german = {
        regular  = sCmdPreSpace .. "${gray}(${white}${1}: ${red}Fehlgeschlagen: Skriptfehler${grey})",
        extended  = sCmdPreSpace .. "${gray}(${white}${1}: ${red}Fehlgeschlagen: Skriptfehler (${2})${grey})",
    },
    spanish = {
        regular  = sCmdPreSpace .. "${gray}(${white}${1}: ${red}Fallido: Error de Script${grey})",
        extended  = sCmdPreSpace .. "${gray}(${white}${1}: ${red}Fallido: Error de Script (${2})${grey})",
    },
    turkish = {
        regular  = sCmdPreSpace .. "${gray}(${white}${1}: ${red}Basarisiz: Script Hatasi${grey})",
        extended  = sCmdPreSpace .. "${gray}(${white}${1}: ${red}Basarisiz: Script Hatasi (${2})${grey})",
    },
    russian = {
        regular  = sCmdPreSpace .. "${gray}(${white}${1}: ${red}Neudacha: Oshibka Skripta${grey})",
        extended  = sCmdPreSpace .. "${gray}(${white}${1}: ${red}Neudacha: Oshibka Skripta (${2})${grey})",
    },
    czech = {
        regular  = sCmdPreSpace .. "${gray}(${white}${1}: ${red}Selhalo: Chyba Skriptu${grey})",
        extended  = sCmdPreSpace .. "${gray}(${white}${1}: ${red}Selhalo: Chyba Skriptu (${2})${grey})",
    }
})

CreateLocalization("l_commandresp_con_premium", {
    english = sCmdPreSpace .. "${gray}(${white}${1}: ${red}Failed: Reserved for Premium Members${grey})",
    german  = sCmdPreSpace .. "${gray}(${white}${1}: ${red}Fehlgeschlagen: Nur fur Premium-Mitglieder${grey})",
    spanish = sCmdPreSpace .. "${gray}(${white}${1}: ${red}Fallido: Reservado para Miembros Premium${grey})",
    turkish = sCmdPreSpace .. "${gray}(${white}${1}: ${red}Basarisiz: Sadece Premium Uyeler icin${grey})",
    russian = sCmdPreSpace .. "${gray}(${white}${1}: ${red}Neudacha: Tolko dlya Premium-Chlenov${grey})",
    czech   = sCmdPreSpace .. "${gray}(${white}${1}: ${red}Selhalo: Pouze pro Cleny Premium${grey})",
})

CreateLocalization("l_commandresp_con_noaccess", {
    english = sCmdPreSpace .. "${gray}(${white}${1}: ${red}Failed: Insufficient Access${grey})",
    german  = sCmdPreSpace .. "${gray}(${white}${1}: ${red}Fehlgeschlagen: Unzureichender Zugriff${grey})",
    spanish = sCmdPreSpace .. "${gray}(${white}${1}: ${red}Fallido: Acceso Insuficiente${grey})",
    turkish = sCmdPreSpace .. "${gray}(${white}${1}: ${red}Basarisiz: Yetersiz Erisim${grey})",
    russian = sCmdPreSpace .. "${gray}(${white}${1}: ${red}Neudacha: Nedostatochnyy Dostup${grey})",
    czech   = sCmdPreSpace .. "${gray}(${white}${1}: ${red}Selhalo: Nedostatecny Pristup${grey})",
})

CreateLocalization("l_commandresp_con_condition", {
    english = { regular = sCmdPreSpace .. "${gray}(${white}${1}: ${red}Failed: Unfulfilled Conditions${grey})" },
    german  = { regular = sCmdPreSpace .. "${gray}(${white}${1}: ${red}Fehlgeschlagen: Nicht Erfullte Bedingungen${grey})" },
    spanish = { regular = sCmdPreSpace .. "${gray}(${white}${1}: ${red}Fallido: Condiciones No Cumplidas${grey})" },
    turkish = { regular = sCmdPreSpace .. "${gray}(${white}${1}: ${red}Basarisiz: Karsilanmayan Sartlar${grey})" },
    russian = { regular = sCmdPreSpace .. "${gray}(${white}${1}: ${red}Neudacha: Neudovletvorennye Usloviya${grey})" },
    czech   = { regular = sCmdPreSpace .. "${gray}(${white}${1}: ${red}Selhalo: Nesplnene Podminky${grey})" },
})

CreateLocalization("l_commandresp_con_success", {
    english = { regular = sCmdPreSpace .. "${gray}(${white}${1}: ${green}Success${grey}${2})" },
    german  = { regular = sCmdPreSpace .. "${gray}(${white}${1}: ${green}Erfolg${grey}${2})" },
    spanish = { regular = sCmdPreSpace .. "${gray}(${white}${1}: ${green}Exito${grey}${2})" },
    turkish = { regular = sCmdPreSpace .. "${gray}(${white}${1}: ${green}Basari${grey}${2})" },
    russian = { regular = sCmdPreSpace .. "${gray}(${white}${1}: ${green}Uspeshno${grey}${2})" },
    czech   = { regular = sCmdPreSpace .. "${gray}(${white}${1}: ${green}Uspech${grey}${2})" },
})

CreateLocalization("l_commandresp_con_nofeedback", {
    english = { regular = sCmdPreSpace .. "${gray}(${white}${1}: ${orange}No Feedback${grey}${2})" },
    german  = { regular = sCmdPreSpace .. "${gray}(${white}${1}: ${orange}Kein Feedback${grey}${2})" },
    spanish = { regular = sCmdPreSpace .. "${gray}(${white}${1}: ${orange}Sin Respuesta${grey}${2})" },
    turkish = { regular = sCmdPreSpace .. "${gray}(${white}${1}: ${orange}Geri Bildirim Yok${grey}${2})" },
    russian = { regular = sCmdPreSpace .. "${gray}(${white}${1}: ${orange}Net Otklyka${grey}${2})" },
    czech   = { regular = sCmdPreSpace .. "${gray}(${white}${1}: ${orange}Zadna Odezva${grey}${2})" },
})

CreateLocalization("l_commandresp_con_notfound", {
    english = { regular  = sCmdPreSpace .. "${gray}(${white}${1}: ${red}Command Not Found${grey})", },
    german  = { regular  = sCmdPreSpace .. "${gray}(${white}${1}: ${red}Befehl Nicht Gefunden${grey})", },
    spanish = { regular  = sCmdPreSpace .. "${gray}(${white}${1}: ${red}Comando No Encontrado${grey})", },
    turkish = { regular  = sCmdPreSpace .. "${gray}(${white}${1}: ${red}Komut Bulunamadi${grey})", },
    russian = { regular  = sCmdPreSpace .. "${gray}(${white}${1}: ${red}Komanda Ne Naydena${grey})", },
    czech   = { regular  = sCmdPreSpace .. "${gray}(${white}${1}: ${red}Prikaz Nenalezen${grey})", },
})

CreateLocalization("l_commandresp_con_badgamerules", {
    english = { regular  = sCmdPreSpace .. "${gray}(${white}${1}: ${red}Failed: Not In ${2}${grey})", },
    german  = { regular  = sCmdPreSpace .. "${gray}(${white}${1}: ${red}Fehlgeschlagen: Nicht In ${2}${grey})", },
    spanish = { regular  = sCmdPreSpace .. "${gray}(${white}${1}: ${red}Fallido: No en ${2}${grey})", },
    turkish = { regular  = sCmdPreSpace .. "${gray}(${white}${1}: ${red}Basarisiz: ${2} Degil${grey})", },
    russian = { regular  = sCmdPreSpace .. "${gray}(${white}${1}: ${red}Neudacha: Ne V ${2}${grey})", },
    czech   = { regular  = sCmdPreSpace .. "${gray}(${white}${1}: ${red}Selhalo: Ne v ${2}${grey})", },
})

CreateLocalization("l_commandresp_con_reserved", {
    english = { regular  = sCmdPreSpace .. "${gray}(${white}${1}: ${red}Reserved for ${2}${grey})", },
    german  = { regular  = sCmdPreSpace .. "${gray}(${white}${1}: ${red}Reserviert fur ${2}${grey})", },
    spanish = { regular  = sCmdPreSpace .. "${gray}(${white}${1}: ${red}Reservado para ${2}${grey})", },
    turkish = { regular  = sCmdPreSpace .. "${gray}(${white}${1}: ${red}${2} icin Ayrildi${grey})", },
    russian = { regular  = sCmdPreSpace .. "${gray}(${white}${1}: ${red}Zarezervirovano dlya ${2}${grey})", },
    czech   = { regular  = sCmdPreSpace .. "${gray}(${white}${1}: ${red}Rezervovano pro ${2}${grey})", },
})



------------------------------------------------------
------------------------------------------------------
--- CHAT MESSAGES


CreateLocalization("l_commandresp_chat_failed", {
    english = { regular = "(${1}: Failed${2})" },
    spanish = { regular = "(${1}: Fallido${2})" },
    german  = { regular = "(${1}: Fehlgeschlagen${2})" },
    turkish = { regular = "(${1}: Basarisiz${2})" },
    russian = { regular = "(${1}: Neudacha${2})" },
    czech   = { regular = "(${1}: Selhalo${2})" }
})

CreateLocalization("l_commandresp_chat_scripterror", {
    english = {
        regular = "(${1}: Failed: Script Error)",
        extended = "(${1}: Failed: Script Error, Check your Console!)",
    },
    spanish = {
        regular = "(${1}: Fallido: Error de Script)",
        extended = "(${1}: Fallido: Error de Script, Revisa tu Consola!)",
    },
    german = {
        regular = "(${1}: Fehlgeschlagen: Skriptfehler)",
        extended = "(${1}: Fehlgeschlagen: Skriptfehler, Uberprufe deine Konsole!)",
    },
    turkish = {
        regular = "(${1}: Basarisiz: Betik Hatasi)",
        extended = "(${1}: Basarisiz: Betik Hatasi, Konsolu Kontrol Et!)",
    },
    russian = {
        regular = "(${1}: Neudacha: Skriptovaya Oshibka)",
        extended = "(${1}: Neudacha: Skriptovaya Oshibka, Proverte Konsol!)",
    },
    czech = {
        regular = "(${1}: Selhalo: Chyba Skriptu)",
        extended = "(${1}: Selhalo: Chyba Skriptu, Zkontrolujte Konzoli!)",
    }
})

CreateLocalization("l_commandresp_chat_condition", {
    english = { regular = "(${1}: Failed: Unfulfilled Conditions)" },
    spanish = { regular = "(${1}: Fallido: Condiciones No Cumplidas)" },
    german  = { regular = "(${1}: Fehlgeschlagen: Unerfullte Bedingungen)" },
    turkish = { regular = "(${1}: Basarisiz: Karsilanmamis Sartlar)" },
    russian = { regular = "(${1}: Neudacha: Ne Vypolneny Usloviya)" },
    czech   = { regular = "(${1}: Selhalo: Nesplnene Podminky)" }
})

CreateLocalization("l_commandresp_chat_success", {
    english = { regular = "(${1}: ${2})" },
    spanish = { regular = "(${1}: ${2})" },
    german  = { regular = "(${1}: ${2})" },
    turkish = { regular = "(${1}: ${2})" },
    russian = { regular = "(${1}: ${2})" },
    czech   = { regular = "(${1}: ${2})" }
})

CreateLocalization("l_commandresp_chat_nofeedback", {
    english = { regular = "(${1}: No Feedback${2})" },
    spanish = { regular = "(${1}: Sin Respuesta${2})" },
    german  = { regular = "(${1}: Kein Feedback${2})" },
    turkish = { regular = "(${1}: Geri Bildirim Yok${2})" },
    russian = { regular = "(${1}: Net Otklykov${2})" },
    czech   = { regular = "(${1}: Zadna Odezva${2})" }
})

CreateLocalization("l_commandresp_chat_notfound", {
    english = { regular = "(${1}: Unknown Command)" },
    spanish = { regular = "(${1}: Comando Desconocido)" },
    german  = { regular = "(${1}: Unbekannter Befehl)" },
    turkish = { regular = "(${1}: Bilinmeyen Komut)" },
    russian = { regular = "(${1}: Neizvestnaya Komanda)" },
    czech   = { regular = "(${1}: Nezname Prikaz)" }
})

CreateLocalization("l_commandresp_chat_noaccess", {
    english = { regular = "(${1}: Insufficient Access)" },
    spanish = { regular = "(${1}: Acceso Insuficiente)" },
    german  = { regular = "(${1}: Unzureichender Zugriff)" },
    turkish = { regular = "(${1}: Yetersiz Erişim)" },
    russian = { regular = "(${1}: Nedostatochnyy Dostup)" },
    czech   = { regular = "(${1}: Nedostatecny Pristup)" }
})

CreateLocalization("l_commandresp_chat_reserved", {
    english = { regular = "(${1}: Reserved for {2})" },
    spanish = { regular = "(${1}: Reservado para {2})" },
    german  = { regular = "(${1}: Reserviert fur {2})" },
    turkish = { regular = "(${1}: {2} Icin Rezerve Edildi)" },
    russian = { regular = "(${1}: Zarezervirovano dlya {2})" },
    czech   = { regular = "(${1}: Vyhrazeno pro {2})" }
})

CreateLocalization("l_commandresp_chat_manyfound", {
    english = { regular = "(${1}: Open your Console to view the ${2} Results)" },
    spanish = { regular = "(${1}: Abre tu Consola para ver los ${2} Resultados)" },
    german  = { regular = "(${1}: Offnen Sie Ihre Konsole, um die ${2} Ergebnisse zu sehen)" },
    turkish = { regular = "(${1}: ${2} Sonuclari Gormek Icin Konsolu Ac)" },
    russian = { regular = "(${1}: Otkroyte Konsol', chtoby uvidet' ${2} Rezultatov)" },
    czech   = { regular = "(${1}: Otevrete Konzoli a Zobrazte si ${2} Vysledky)" }
})

CreateLocalization("l_commandresp_chat_premium", {
    english = "(${1}: Reserved for Premium)",
    spanish = "(${1}: Reservado para Premium)",
    german  = "(${1}: Reserviert fur Premium)",
    turkish = "(${1}: Premium Icin Rezerve Edildi)",
    russian = "(${1}: Zarezervirovano dlya Premium)",
    czech   = "(${1}: Vyhrazeno pro Premium)"
})

CreateLocalization("l_commandresp_chat_badgamerules", {
    english = "(${1}: Not Available In ${2})",
    spanish = "(${1}: No Disponible En ${2})",
    german  = "(${1}: Nicht Verfugbar In ${2})",
    turkish = "(${1}: ${2} Icinde Kullanilamaz)",
    russian = "(${1}: Nedostupno v ${2})",
    czech   = "(${1}: Neni k Dispozici ve ${2})"
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


CreateLocalization("l_ui_command_Language_Description", {
    english = "hello, call 911, fixme please!",
})
