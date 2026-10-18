local _, A = ...

-- Offline, curated translations of the four BUILT-IN templates. These are not
-- a machine-translation service and never rewrite a custom message or guild chat.
A.languages = {
    {id="en", label="English"},
    {id="es", label="Spanish (Español)"},
    {id="fr", label="French (Français)"},
    {id="de", label="German (Deutsch)"},
    {id="it", label="Italian (Italiano)"},
    {id="pt", label="Portuguese (Português)"},
    {id="pl", label="Polish (Polski)"},
    {id="nl", label="Dutch (Nederlands)"},
}
A.languageByID = {}
for _, lang in ipairs(A.languages) do A.languageByID[lang.id] = lang.label end
A.localeTemplates = {
    en = A.defaults.templates,
    es = {
        login = "¡Bienvenido de nuevo, {name}!",
        join = "¡Bienvenido al gremio, {name}!",
        level = "¡Felicidades por alcanzar el nivel {level}, {name}!",
        help = "[LFG] {type}: {activity}. Puedo ir como: {myroles}. Busco: {needed}. ¡Susúrrame!",
    },
    fr = {
        login = "Bon retour, {name} !",
        join = "Bienvenue dans la guilde, {name} !",
        level = "Bravo pour le niveau {level}, {name} !",
        help = "[LFG] {type} : {activity}. Je peux jouer : {myroles}. Recherche : {needed}. Chuchote-moi !",
    },
    de = {
        login = "Willkommen zurück, {name}!",
        join = "Willkommen in der Gilde, {name}!",
        level = "Glückwunsch zu Stufe {level}, {name}!",
        help = "[LFG] {type}: {activity}. Ich kann spielen als: {myroles}. Gesucht: {needed}. Flüstere mir!",
    },
    it = {
        login = "Bentornato, {name}!",
        join = "Benvenuto nella gilda, {name}!",
        level = "Complimenti per il livello {level}, {name}!",
        help = "[LFG] {type}: {activity}. Posso giocare come: {myroles}. Cerco: {needed}. Scrivimi in privato!",
    },
    pt = {
        login = "Bem-vindo de volta, {name}!",
        join = "Bem-vindo à guilda, {name}!",
        level = "Parabéns pelo nível {level}, {name}!",
        help = "[LFG] {type}: {activity}. Posso jogar como: {myroles}. Procuro: {needed}. Manda sussurro!",
    },
    pl = {
        login = "Witaj ponownie, {name}!",
        join = "Witaj w gildii, {name}!",
        level = "Gratulacje z okazji poziomu {level}, {name}!",
        help = "[LFG] {type}: {activity}. Mogę grać jako: {myroles}. Szukam: {needed}. Napisz do mnie!",
    },
    nl = {
        login = "Welkom terug, {name}!",
        join = "Welkom bij het gilde, {name}!",
        level = "Gefeliciteerd met level {level}, {name}!",
        help = "[LFG] {type}: {activity}. Ik kan spelen als: {myroles}. Gezocht: {needed}. Fluister me!",
    },
}
A.localeRoleNames = {
    en={tank="Tank", healer="Healer", damage="DPS", flexible="Flexible", any="Any role"},
    es={tank="Tanque", healer="Sanador", damage="DPS", flexible="Flexible", any="Cualquier rol"},
    fr={tank="Tank", healer="Soigneur", damage="DPS", flexible="Flexible", any="Tout rôle"},
    de={tank="Tank", healer="Heiler", damage="DPS", flexible="Flexibel", any="Jede Rolle"},
    it={tank="Tank", healer="Guaritore", damage="DPS", flexible="Flessibile", any="Qualsiasi ruolo"},
    pt={tank="Tanque", healer="Curador", damage="DPS", flexible="Flexível", any="Qualquer função"},
    pl={tank="Tank", healer="Uzdrowiciel", damage="DPS", flexible="Elastycznie", any="Dowolna rola"},
    nl={tank="Tank", healer="Genezer", damage="DPS", flexible="Flexibel", any="Elke rol"},
}
A.localeActivityTypes = {
    en={Dungeon="Dungeon",Raid="Raid",Quest="Quest"},
    es={Dungeon="Mazmorra",Raid="Banda",Quest="Misión"},
    fr={Dungeon="Donjon",Raid="Raid",Quest="Quête"},
    de={Dungeon="Dungeon",Raid="Schlachtzug",Quest="Quest"},
    it={Dungeon="Spedizione",Raid="Incursione",Quest="Missione"},
    pt={Dungeon="Masmorra",Raid="Raide",Quest="Missão"},
    pl={Dungeon="Loch",Raid="Rajd",Quest="Zadanie"},
    nl={Dungeon="Kerker",Raid="Raid",Quest="Missie"},
}
