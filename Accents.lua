local _, A = ...

-- Phrase-level styles are deliberately curated. We never apply global chat
-- hooks or rewrite arbitrary text, names, hyperlinks, colours or variables.
-- The variants are creative RP flavour, not phonetic claims about real people.
A.accents = {}
local function register(id, label, lang, login, join, level, help, flair)
    A.accents[id] = {
        id=id, label=label, language=lang,
        text={login=login, join=join, level=level, help=help},
        flair=flair,
    }
end
-- Human / English-speaking regional flavours
register("australian", "Australian", "en", "Good to see you back, {name}!", "Welcome aboard, {name}!", "Nice work hitting level {level}, {name}!", "[LFG] {type}: {activity}. I can cover {myroles}; need {needed}. Give me a shout!", "G'day! ")
register("british", "British", "en", "Lovely to have you back, {name}!", "Welcome to the guild, {name}!", "Splendid work reaching level {level}, {name}!", "[LFG] {type}: {activity}. I can play {myroles}; looking for {needed}. Do whisper me!", "Cheers! ")
register("american", "American", "en", "Hey, welcome back, {name}!", "Hey {name}, welcome to the guild!", "Awesome job reaching level {level}, {name}!", "[LFG] {type}: {activity}. I can do {myroles}; need {needed}. Hit me up!", "Hey there! ")
register("scottish", "Scottish-inspired", "en", "Guid to see ye back, {name}!", "Welcome tae the guild, {name}!", "Well done reachin' level {level}, {name}!", "[LFG] {type}: {activity}. I can play {myroles}; need {needed}. Send a wee whisper!", "Och! ")
register("irish", "Irish-inspired", "en", "Grand to see you again, {name}!", "You're very welcome here, {name}!", "Fair play reaching level {level}, {name}!", "[LFG] {type}: {activity}. I can play {myroles}; looking for {needed}. Drop me a whisper!", "Ah, grand! ")
register("canadian", "Canadian", "en", "Good to have you back, {name}!", "Glad to have you with us, {name}!", "Great job hitting level {level}, {name}!", "[LFG] {type}: {activity}. I can fill {myroles}; need {needed}. Feel free to whisper!", "Hey, welcome! ")
register("newzealand", "New Zealand", "en", "Kia ora, welcome back, {name}!", "Kia ora {name}, welcome to the guild!", "Choice work reaching level {level}, {name}!", "[LFG] {type}: {activity}. I can do {myroles}; need {needed}. Flick me a whisper!", "Kia ora! ")
register("southafrican", "South African", "en", "Howzit, good to see you back, {name}!", "Welcome to the guild, {name}!", "Lekker work getting to level {level}, {name}!", "[LFG] {type}: {activity}. I can fill {myroles}; looking for {needed}. Send a whisper!", "Howzit! ")
-- WoW-inspired RP voices: no pretending to speak Blizzard's invented languages.
register("dwarf", "Khaz Modan Dwarf", "en", "Back again, {name}? Good on ye!", "Welcome to the clan, {name}!", "By the forge, level {level}! Well done, {name}!", "[LFG] {type}: {activity}. I can handle {myroles}; need {needed}. Give us a shout!", "By the forge! ")
register("wildhammer", "Wildhammer Dwarf", "en", "The winds bring ye back, {name}!", "Welcome among friends, {name}!", "Storm and thunder! Level {level}, {name}!", "[LFG] {type}: {activity}. I can fly in as {myroles}; need {needed}. Whisper me!", "By the winds! ")
register("darkiron", "Dark Iron Dwarf", "en", "The forge burns brighter with ye back, {name}!", "Welcome to our ranks, {name}!", "Level {level}! Forged stronger, {name}!", "[LFG] {type}: {activity}. I can fill {myroles}; require {needed}. Whisper me!", "By the anvil! ")
register("gnome", "Gnomeregan Tinker", "en", "Excellent, {name}! You're online again!", "Fantastic! New guild member detected: {name}!", "Level {level} achieved, {name}! Brilliant data!", "[LFG] {type}: {activity}. Available modules: {myroles}. Required modules: {needed}. Whisper me!", "Eureka! ")
register("nightelf", "Kaldorei", "en", "The stars welcome your return, {name}.", "May the stars guide you, {name}. Welcome.", "Elune watch over your path to level {level}, {name}.", "[LFG] {type}: {activity}. I offer {myroles}; seeking {needed}. Whisper me.", "By the stars, ")
register("orc", "Orcish Warrior", "en", "You return, {name}. Strength and honour!", "Join our ranks, {name}. For the guild!", "Level {level}, {name}! Your strength grows!", "[LFG] {type}: {activity}. I fight as {myroles}. Need {needed}. Whisper me!", "Lok'tar! ")
register("troll", "Darkspear Troll", "en", "Good to see ya back, {name}, mon!", "Welcome to da guild, {name}, mon!", "Ya made level {level}, {name}! Nice one, mon!", "[LFG] {type}: {activity}. I can bring {myroles}; need {needed}. Whisper me, mon!", "Hey, mon! ")
register("tauren", "Mulgore Tauren", "en", "The winds welcome you back, {name}.", "Walk with us, {name}. Welcome.", "May the Earth Mother bless your level {level}, {name}.", "[LFG] {type}: {activity}. I can serve as {myroles}; seek {needed}. Whisper me.", "Walk in peace. ")
register("forsaken", "Forsaken", "en", "Back among us, {name}. How reassuring.", "Welcome to our little gathering, {name}.", "Level {level}, {name}. How delightfully persistent.", "[LFG] {type}: {activity}. I can offer {myroles}; require {needed}. Whisper me.", "How curious. ")
register("skyborne", "Skyborne", "en", "The winds welcome your return, {name}!", "Rise with us, {name}. Welcome!", "You've risen to level {level}, {name}!", "[LFG] {type}: {activity}. I can bring {myroles}; seek {needed}. Whisper me!", "On the winds! ")
register("goblin", "Goblin Dealer", "en", "You're back, {name}! Let's make a deal!", "Welcome aboard, {name}! No refunds!", "Level {level}, {name}! Now that's an upgrade!", "[LFG] {type}: {activity}. Selling services as {myroles}; buying {needed}. Whisper me!", "Great deal! ")
register("bloodelf", "Sin'dorei", "en", "Your return is most welcome, {name}.", "Welcome to our distinguished guild, {name}.", "An elegant ascent to level {level}, {name}.", "[LFG] {type}: {activity}. I offer {myroles}; seeking {needed}. Whisper me.", "Anar'alah! ")
register("draenei", "Draenei", "en", "The Light welcomes you back, {name}.", "May the Light guide you, {name}. Welcome.", "May the Light guide your path at level {level}, {name}.", "[LFG] {type}: {activity}. I can provide {myroles}; seeking {needed}. Whisper me.", "In the Light, ")
-- Real-world variants of translated languages
register("mexican", "Mexican Spanish", "es", "¡Qué gusto verte otra vez, {name}!", "¡Bienvenido a la hermandad, {name}!", "¡Qué bien, ya eres nivel {level}, {name}!", "[LFG] {type}: {activity}. Puedo ir de {myroles}; nos falta {needed}. ¡Mándame un susurro!", "¡Órale! ")
register("cuban", "Cuban Spanish", "es", "¡Qué bueno verte de nuevo, {name}!", "¡Bienvenido al grupo, {name}!", "¡Asere, felicidades por el nivel {level}, {name}!", "[LFG] {type}: {activity}. Puedo ir de {myroles}; hace falta {needed}. ¡Mándame un susurro!", "¡Asere! ")
register("spanish", "Spain Spanish", "es", "¡Qué alegría verte otra vez, {name}!", "¡Bienvenido a la hermandad, {name}!", "¡Enhorabuena por el nivel {level}, {name}!", "[LFG] {type}: {activity}. Puedo ir de {myroles}; buscamos {needed}. ¡Mándame un susurro!", "¡Venga! ")
register("quebec", "Québécois French", "fr", "Content de te revoir, {name} !", "Bienvenue dans la guilde, {name} !", "Bravo pour ton niveau {level}, {name} !", "[LFG] {type} : {activity}. Je peux jouer {myroles}. On cherche {needed}. Écris-moi !", "Salut ! ")
register("bavarian", "Bavarian-inspired German", "de", "Servus, schön dass du wieder da bist, {name}!", "Servus {name}, willkommen in der Gilde!", "Sauber, Stufe {level}, {name}!", "[LFG] {type}: {activity}. Ich kann {myroles} spielen; suche {needed}. Schreib mir!", "Servus! ")
register("brazilian", "Brazilian Portuguese", "pt", "Que bom te ver de volta, {name}!", "Bem-vindo à guilda, {name}!", "Boa! Nível {level}, {name}!", "[LFG] {type}: {activity}. Posso ir de {myroles}; falta {needed}. Me chama no sussurro!", "E aí! ")
register("portuguese", "Portugal Portuguese", "pt", "Bem-vindo de volta, {name}!", "Bem-vindo à guilda, {name}!", "Parabéns pelo nível {level}, {name}!", "[LFG] {type}: {activity}. Posso jogar como {myroles}; falta {needed}. Envia-me um sussurro!", "Ora viva! ")
register("southernitalian", "Southern Italian-inspired", "it", "Che bello rivederti, {name}!", "Benvenuto tra noi, {name}!", "Bravo, livello {level}, {name}!", "[LFG] {type}: {activity}. Posso giocare come {myroles}; cerchiamo {needed}. Scrivimi!", "Ciao! ")

A.accentOrder = {
    "australian", "british", "american", "scottish", "irish", "canadian", "newzealand", "southafrican",
    "dwarf", "wildhammer", "darkiron", "gnome", "nightelf", "orc", "troll", "tauren", "forsaken", "skyborne", "goblin", "bloodelf", "draenei",
    "mexican", "cuban", "spanish", "quebec", "bavarian", "brazilian", "portuguese", "southernitalian",
}
