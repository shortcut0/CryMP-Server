-----------------
--- Server locale

CreateLocalization("l_console_on_connection", {

    -- 1 = Name, 2 = Channel, 3 = IP

    english = {
        regular = "${gray}${1}${gray} Connecting on Channel ${2}",
        extended = "${gray}${1}${gray} Connecting on Channel ${2} (${3})",
    },

    spanish = {
        regular = "${1} Nueva conecion en el Canal ${2}",
        extended = "${1} Nueva conecion en el Canal ${2} (${3})",
    },

    german = {
        regular = "${1} Neue Verbindung auf Kanal ${2}",
        extended = "${1} Neue Verbindung auf Kanal ${2} (${3})",
    },

    russian = {
        regular = "${1} Podklyuchaetsya na kanale ${2}",
        extended = "${1} Podklyuchaetsya na kanale ${2} (${3})",
    },
})

CreateLocalization("l_console_on_connected", {

    -- 1 = Name, 2 = Channel, 3 = Profile

    english = {
        regular = "${gray}${1}${gray} Connected on Channel ${2}",
        extended = "${gray}${1}${gray} Connected on Channel ${2} (${3})",
    },

    spanish = {
        regular = "${1} Conectar en el Canal ${2}",
        extended = "${1} Conectar en el Canal ${2} (${3})",
    },

    german = {
        regular = "${1} Verbunden auf Kanal ${2}",
        extended = "${1} Verbunden auf Kanal ${2} (${3})",
    },

    russian = {
        regular = "${1} Podklyuchen k kanalu ${2}",
        extended = "${1} Podklyuchen k kanalu ${2} (${3})",
    }
})

CreateLocalization("l_console_on_disconnected", {

    -- 1 = Name, 2 = Channel, 3 = IP

    english = {
        regular = "${gray}${1}${gray} Disconnected from Channel ${2}",
        extended = "${gray}${1}${gray} Disconnected from Channel ${2} (${3})",
    },

    spanish = {
        regular = "${gray}${1}${gray} Desconectado del Canal ${2}",
        extended = "${gray}${1}${gray} Desconectado del Canal ${2} (${3})",
    },

    german = {
        regular = "${gray}${1}${gray} Verbindung Getrennt vom Kanal ${2}",
        extended = "${gray}${1}${gray} Verbindung Getrennt vom Kanal ${2} (${3})",
    },

    russian = {
        regular = "${gray}${1}${gray} Otklyuchen ot kanala ${2}",
        extended = "${gray}${1}${gray} Otklyuchen ot kanala ${2} (${3})",
    }
})

CreateLocalization("l_console_on_chandisconnect", {

    -- 1 = Name, 2 = Channel, 3 = IP

    english = {
        regular = "${gray}${1}${gray} Disconnected from Channel ${2}",
        extended = "${gray}${1}${gray} Disconnected from Channel ${2} (${3})",
    },

    spanish = {
        regular = "${gray}${1}${gray} Desconectado del Canal ${2}",
        extended = "${gray}${1}${gray} Desconectado del Canal ${2} (${3})",
    },

    german = {
        regular = "${gray}${1}${gray} Verbindung Getrennt vom Kanal ${2}",
        extended = "${gray}${1}${gray} Verbindung Getrennt vom Kanal ${2} (${3})",
    },

    russian = {
        regular = "${gray}${1}${gray} Otklyuchen ot kanala ${2}",
        extended = "${gray}${1}${gray} Otklyuchen ot kanala ${2} (${3})",
    }
})