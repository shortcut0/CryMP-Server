local LocaleList = {
    ["l_console_on_connection"] = {
        -- 1 = Name, 2 = Channel, 3 = IP
        english  = { regular = "${gray}${1}${gray} Connecting on Channel ${2}", extended = "${gray}${1}${gray} Connecting on Channel ${2} (${3})" },
        spanish  = { regular = "${gray}${1}${gray} Conectando en Canal ${2}", extended = "${gray}${1}${gray} Conectando en Canal ${2} (${3})" },
        german   = { regular = "${gray}${1}${gray} Verbindung auf Kanal ${2}", extended = "${gray}${1}${gray} Verbindung auf Kanal ${2} (${3})" },
        turkish  = { regular = "${gray}${1}${gray} Kanal ${2}'ye Baglaniyor", extended = "${gray}${1}${gray} Kanal ${2}'ye Baglaniyor (${3})" },
        russian  = { regular = "${gray}${1}${gray} Podklyucheniye k Kanalu ${2}", extended = "${gray}${1}${gray} Podklyucheniye k Kanalu ${2} (${3})" },
        czech    = { regular = "${gray}${1}${gray} Pripojeni na Kanalu ${2}", extended = "${gray}${1}${gray} Pripojeni na Kanalu ${2} (${3})" }
    },

    ["l_chat_on_Connection"] = {
        -- 1 = Name, 2 = Channel, 3 = IP
        english  = { regular = "(${1}: Connecting on Channel ${2})", extended = "(${1}: Connecting on Channel ${2} (${3}))" },
        spanish  = { regular = "(${1}: Conectando en Canal ${2})", extended = "(${1}: Conectando en Canal ${2} (${3}))" },
        german   = { regular = "(${1}: Verbindung auf Kanal ${2})", extended = "(${1}: Verbindung auf Kanal ${2} (${3}))" },
        turkish  = { regular = "(${1}: Kanal ${2}'ye Baglaniyor)", extended = "(${1}: Kanal ${2}'ye Baglaniyor (${3}))" },
        russian  = { regular = "(${1}: Podklyucheniye k Kanalu ${2})", extended = "(${1}: Podklyucheniye k Kanalu ${2} (${3}))" },
        czech    = { regular = "(${1}: Pripojeni na Kanalu ${2})", extended = "(${1}: Pripojeni na Kanalu ${2} (${3}))" }
    },

    ["l_console_on_connected"] = {
        -- 1 = Name, 2 = Channel, 3 = Profile
        english  = { regular = "${gray}${1}${gray} Connected on Channel ${2}", extended = "${gray}${1}${gray} Connected on Channel ${2} (${3})" },
        spanish  = { regular = "${gray}${1}${gray} Conectado en Canal ${2}", extended = "${gray}${1}${gray} Conectado en Canal ${2} (${3})" },
        german   = { regular = "${gray}${1}${gray} Verbunden auf Kanal ${2}", extended = "${gray}${1}${gray} Verbunden auf Kanal ${2} (${3})" },
        turkish  = { regular = "${gray}${1}${gray} Kanal ${2}'ye Baglandi", extended = "${gray}${1}${gray} Kanal ${2}'ye Baglandi (${3})" },
        russian  = { regular = "${gray}${1}${gray} Podklyucheno k Kanalu ${2}", extended = "${gray}${1}${gray} Podklyucheno k Kanalu ${2} (${3})" },
        czech    = { regular = "${gray}${1}${gray} Pripojeno na Kanalu ${2}", extended = "${gray}${1}${gray} Pripojeno na Kanalu ${2} (${3})" }
    },

    ["l_chat_on_Connected"] = {
        -- 1 = Name, 2 = Channel, 3 = Profile
        english  = { regular = "(${1}: Connected on Channel ${2})", extended = "(${1}: Connected on Channel ${2} (${3}))" },
        spanish  = { regular = "(${1}: Conectado en Canal ${2})", extended = "(${1}: Conectado en Canal ${2} (${3}))" },
        german   = { regular = "(${1}: Verbunden auf Kanal ${2})", extended = "(${1}: Verbunden auf Kanal ${2} (${3}))" },
        turkish  = { regular = "(${1}: Kanal ${2}'ye Baglandi)", extended = "(${1}: Kanal ${2}'ye Baglandi (${3}))" },
        russian  = { regular = "(${1}: Podklyucheno k Kanalu ${2})", extended = "(${1}: Podklyucheno k Kanalu ${2} (${3}))" },
        czech    = { regular = "(${1}: Pripojeno na Kanalu ${2})", extended = "(${1}: Pripojeno na Kanalu ${2} (${3}))" }
    },

    ["l_console_on_disconnected"] = {
        -- 1 = Name, 2 = Channel, 3 = IP
        english  = { regular = "${gray}${1}${gray} Disconnected from Channel ${2}", extended = "${gray}${1}${gray} Disconnected from Channel ${2} (${3})" },
        spanish  = { regular = "${gray}${1}${gray} Desconectado de Canal ${2}", extended = "${gray}${1}${gray} Desconectado de Canal ${2} (${3})" },
        german   = { regular = "${gray}${1}${gray} Getrennt von Kanal ${2}", extended = "${gray}${1}${gray} Getrennt von Kanal ${2} (${3})" },
        turkish  = { regular = "${gray}${1}${gray} Kanal ${2}'den Baglantisi Kesildi", extended = "${gray}${1}${gray} Kanal ${2}'den Baglantisi Kesildi (${3})" },
        russian  = { regular = "${gray}${1}${gray} Otklyuchen ot Kanala ${2}", extended = "${gray}${1}${gray} Otklyuchen ot Kanala ${2} (${3})" },
        czech    = { regular = "${gray}${1}${gray} Odpojeno z Kanalu ${2}", extended = "${gray}${1}${gray} Odpojeno z Kanalu ${2} (${3})" }
    },

    ["l_chat_on_Disconnected"] = {
        -- 1 = Name, 2 = Channel, 3 = IP
        english  = { regular = "(${1}: Disconnected (${3}))" },
        spanish  = { regular = "(${1}: Desconectado (${3}))" },
        german   = { regular = "(${1}: Getrennt (${3}))" },
        turkish  = { regular = "(${1}: Baglantisi Kesildi (${3}))" },
        russian  = { regular = "(${1}: Otklyuchen (${3}))" },
        czech    = { regular = "(${1}: Odpojeno (${3}))" }
    },

    ["l_console_on_chandisconnect"] = {
        -- 1 = Name, 2 = Channel, 3 = IP
        english  = { regular = "${gray}${1}${gray} Disconnected from Channel ${2}", extended = "${gray}${1}${gray} Disconnected from Channel ${2} (${3})" },
        spanish  = { regular = "${gray}${1}${gray} Desconectado de Canal ${2}", extended = "${gray}${1}${gray} Desconectado de Canal ${2} (${3})" },
        german   = { regular = "${gray}${1}${gray} Getrennt von Kanal ${2}", extended = "${gray}${1}${gray} Getrennt von Kanal ${2} (${3})" },
        turkish  = { regular = "${gray}${1}${gray} Kanal ${2}'den Baglantisi Kesildi", extended = "${gray}${1}${gray} Kanal ${2}'den Baglantisi Kesildi (${3})" },
        russian  = { regular = "${gray}${1}${gray} Otklyuchen ot Kanala ${2}", extended = "${gray}${1}${gray} Otklyuchen ot Kanala ${2} (${3})" },
        czech    = { regular = "${gray}${1}${gray} Odpojeno z Kanalu ${2}", extended = "${gray}${1}${gray} Odpojeno z Kanalu ${2} (${3})" }
    },

    ["l_chat_on_chanDisconnect"] = {
        -- 1 = Name, 2 = Channel, 3 = IP
        english  = { extended = "(${1}: Connection on Channel ${2} Closed (${3}))" },
        spanish  = { extended = "(${1}: Conexion en Canal ${2} Cerrada (${3}))" },
        german   = { extended = "(${1}: Verbindung auf Kanal ${2} Geschlossen (${3}))" },
        turkish  = { extended = "(${1}: Kanal ${2}'deki Baglanti Kapatildi (${3}))" },
        russian  = { extended = "(${1}: Soedinenie na Kanale ${2} Zakryto (${3}))" },
        czech    = { extended = "(${1}: Pripojeni na Kanalu ${2} Uzavreno (${3}))" }
    }

}

for s, a in pairs(LocaleList) do
    CreateLocalization(s, a)
end