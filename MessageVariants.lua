local _, A = ...

-- Additional CURATED templates for addon-generated guild messages only.
-- No transformations of player names, hyperlinks, item IDs, activity names or
-- other placeholder values. All phrases are local/offline and safe to review.
-- The base text for each language/accent lives in Languages.lua/Accents.lua.
A.localeVariants = {
    en = {
        login = {"Look who's back! Welcome, {name}!", "Great to have you online again, {name}!", "Hey {name}, good to see you!"},
        join = {"Everyone, say hello to our newest member: {name}!", "A warm guild welcome to {name}!", "Glad to have you with us, {name}!"},
        level = {"Level {level} unlocked! Nicely done, {name}!", "Big cheers to {name} for reaching level {level}!", "Another milestone for {name}: level {level}!"},
        help = {"[LFG] Anyone up for {activity} ({type})? I can cover {myroles}; we need {needed}. Whisper me!", "[LFG] Putting together {activity} ({type}). My role: {myroles}. Still need: {needed}. PST!", "[LFG] Who's keen for {activity} ({type})? Offering {myroles}, looking for {needed}. Send a whisper!"},
    },
    es = {
        login = {"¡Qué alegría verte otra vez, {name}!", "¡{name} ha vuelto! ¡Bienvenido!"},
        join = {"¡Un aplauso para nuestro nuevo miembro, {name}!", "¡Qué gusto tenerte en la hermandad, {name}!"},
        level = {"¡Nivel {level} conseguido! ¡Bien hecho, {name}!", "¡Un aplauso para {name} por llegar al nivel {level}!"},
        help = {"[LFG] ¿Quién se apunta a {activity} ({type})? Puedo ir de {myroles}; buscamos {needed}. ¡Susúrrame!", "[LFG] Organizando {activity} ({type}). Mi rol: {myroles}. Nos falta: {needed}. ¡Manda un susurro!"},
    },
    fr = {
        login = {"Content de te retrouver, {name} !", "Revoilà {name} ! Bon retour parmi nous !"},
        join = {"Accueillons notre nouveau membre, {name} !", "Ravi de t'avoir dans la guilde, {name} !"},
        level = {"Niveau {level} atteint ! Bien joué, {name} !", "Bravo à {name} pour son niveau {level} !"},
        help = {"[LFG] Qui veut faire {activity} ({type}) ? Je joue {myroles}, il nous faut {needed}. Chuchote-moi !", "[LFG] Groupe pour {activity} ({type}). Mon rôle : {myroles}. On cherche : {needed}. MP bienvenu !"},
    },
    de = {
        login = {"Schön, dich wiederzusehen, {name}!", "{name} ist zurück! Willkommen!"},
        join = {"Begrüßt unser neues Gildenmitglied {name}!", "Schön, dass du bei uns bist, {name}!"},
        level = {"Stufe {level} geschafft! Gut gemacht, {name}!", "Applaus für {name}: Stufe {level} erreicht!"},
        help = {"[LFG] Wer hat Lust auf {activity} ({type})? Ich spiele {myroles}; wir brauchen {needed}. Flüstert mich an!", "[LFG] Gruppe für {activity} ({type}). Meine Rolle: {myroles}. Gesucht: {needed}. Bitte flüstern!"},
    },
    it = {
        login = {"Che bello rivederti, {name}!", "È tornato {name}! Bentornato!"},
        join = {"Diamo il benvenuto a {name}, il nostro nuovo membro!", "Felici di averti con noi, {name}!"},
        level = {"Livello {level} raggiunto! Grande, {name}!", "Un applauso a {name} per il livello {level}!"},
        help = {"[LFG] Chi viene a {activity} ({type})? Posso fare {myroles}; servono {needed}. Scrivimi!", "[LFG] Gruppo per {activity} ({type}). Il mio ruolo: {myroles}. Cerchiamo: {needed}. Mandami un messaggio!"},
    },
    pt = {
        login = {"Que bom ter você de volta, {name}!", "Olha quem voltou! Bem-vindo, {name}!"},
        join = {"Vamos dar as boas-vindas ao novo membro, {name}!", "É ótimo ter você na guilda, {name}!"},
        level = {"Nível {level} alcançado! Mandou bem, {name}!", "Parabéns a {name} por chegar ao nível {level}!"},
        help = {"[LFG] Alguém anima {activity} ({type})? Posso jogar de {myroles}; faltam {needed}. Me chama!", "[LFG] Montando grupo para {activity} ({type}). Meu papel: {myroles}. Precisamos de {needed}. Manda sussurro!"},
    },
    pl = {
        login = {"Miło cię znów widzieć, {name}!", "{name} wraca do gry! Witamy!"},
        join = {"Powitajmy nowego członka gildii, {name}!", "Cieszymy się, że jesteś z nami, {name}!"},
        level = {"Poziom {level} zdobyty! Brawo, {name}!", "Brawa dla {name} za osiągnięcie poziomu {level}!"},
        help = {"[LFG] Kto chętny na {activity} ({type})? Mogę grać jako {myroles}; potrzebujemy {needed}. Piszcie!", "[LFG] Składam grupę na {activity} ({type}). Moja rola: {myroles}. Szukamy: {needed}. Szepnij do mnie!"},
    },
    nl = {
        login = {"Leuk je weer te zien, {name}!", "Kijk wie er terug is! Welkom, {name}!"},
        join = {"Verwelkom ons nieuwste gildelid, {name}!", "Fijn dat je erbij bent, {name}!"},
        level = {"Level {level} behaald! Goed gedaan, {name}!", "Applaus voor {name}: level {level}!"},
        help = {"[LFG] Wie gaat mee naar {activity} ({type})? Ik kan {myroles} spelen; we zoeken {needed}. Fluister me!", "[LFG] Groep voor {activity} ({type}). Mijn rol: {myroles}. Nog nodig: {needed}. Stuur een whisper!"},
    },
}

-- Each accent retains its existing base template. These extra complete
-- templates vary sentence structure, rather than randomly replacing syllables.
A.accentVariants = {
    australian = {
        login = {"G'day {name}, good to have you back!", "Look who's back! How ya going, {name}?"},
        join = {"Give {name} a big welcome, everyone!", "G'day {name}! Glad to have you aboard."},
        level = {"You beauty, {name}! Level {level}!", "Cracker effort, {name}, hitting level {level}!"},
        help = {"[LFG] Keen for {activity} ({type})? Can do {myroles}, need {needed}. Give us a yell!", "[LFG] Getting {activity} going ({type}). I'm {myroles}; chasing {needed}. PST!"},
    },
    british = {
        login = {"Good to see you again, {name}!"}, join = {"Do welcome {name} to the guild!"},
        level = {"Brilliant! Level {level}, {name}!"}, help = {"[LFG] Fancy {activity} ({type})? I can do {myroles}; need {needed}. Do whisper!"},
    },
    american = {
        login = {"Hey {name}, you're back!"}, join = {"Everybody welcome {name} to the guild!"},
        level = {"Let's go, {name}! Level {level}!"}, help = {"[LFG] Anyone in for {activity} ({type})? I can play {myroles}; need {needed}. Hit me up!"},
    },
    scottish = {
        login = {"There ye are again, {name}! Welcome back!", "Guid tae have ye wi' us again, {name}!"},
        join = {"A warm welcome tae {name}, everyone!", "Come on in, {name}; there's room by the hearth!"},
        level = {"Och, level {level} already? Fine work, {name}!", "Well fought, {name}! Level {level} is yours!"},
        help = {"[LFG] Anyone fancy {activity} ({type})? I can bring {myroles}; need {needed}. Give a wee shout!"},
    },
    irish = {
        login = {"There you are, {name}! Good to see you!"}, join = {"A hearty welcome to {name}!"},
        level = {"Fair play, {name}! Level {level} already!"}, help = {"[LFG] Anyone up for {activity} ({type})? I can do {myroles}; need {needed}. Give us a shout!"},
    },
    canadian = {
        login = {"Hey {name}, glad you're back!"}, join = {"Everyone, let's welcome {name}!"},
        level = {"Nicely done, {name}! Level {level}!"}, help = {"[LFG] Anyone keen on {activity} ({type})? I'm {myroles}; could use {needed}. Whisper me!"},
    },
    newzealand = {
        login = {"Kia ora {name}! Good to see you again!"}, join = {"Big welcome to {name}, whānau!"},
        level = {"Sweet as, {name}! Level {level}!"}, help = {"[LFG] Who's keen for {activity} ({type})? I can do {myroles}; need {needed}. Flick a whisper!"},
    },
    southafrican = {
        login = {"Howzit {name}, welcome back!"}, join = {"Howzit {name}! Welcome aboard!"},
        level = {"Lekker, {name}! Level {level}!"}, help = {"[LFG] Keen for {activity} ({type})? I can fill {myroles}; looking for {needed}. Whisper!"},
    },
    dwarf = {
        login = {"There ye are, {name}! The hearth's still warm!", "Back frae adventure, {name}? Pull up a chair!"},
        join = {"Raise a mug for {name}, our new guildmate!", "Welcome to our halls, {name}! Mind the forge!"},
        level = {"That's level {level} in the bag, {name}! By me beard!", "Another rung up the mountain, {name}! Level {level}!"},
        help = {"[LFG] Gathering a crew fer {activity} ({type}). I can take {myroles}; need {needed}. Holler!", "[LFG] Into {activity} ({type}) we go! I'm {myroles}, seeking {needed}. Give a shout!"},
    },
    wildhammer = {
        login = {"The skies are livelier with ye back, {name}!"}, join = {"A thunderous welcome tae {name}!"},
        level = {"By the storm, {name}! Level {level}!"}, help = {"[LFG] Who'll soar into {activity} ({type})? I'm {myroles}; need {needed}. Whisper me!"},
    },
    darkiron = {
        login = {"Back to the forge, are ye, {name}?"}, join = {"A place at the anvil fer {name}! Welcome!"},
        level = {"Well tempered, {name}! Level {level}!"}, help = {"[LFG] Assemble fer {activity} ({type}). I offer {myroles}; require {needed}. Whisper!"},
    },
    gnome = {
        login = {"System online! Hello again, {name}!", "Welcome back, {name}! Diagnostics look excellent!"},
        join = {"Guild roster updated! Welcome, {name}!", "A new friendship module! Say hello to {name}!"},
        level = {"Level {level} confirmed for {name}! What a breakthrough!", "Achievement in progress: {name} reached level {level}!"},
        help = {"[LFG] Project {activity} ({type}) starting! Module {myroles} online; requesting {needed}. Whisper for details!"},
    },
    nightelf = {
        login = {"The moon shines upon your return, {name}."}, join = {"The grove welcomes you, {name}."},
        level = {"Your path grows brighter at level {level}, {name}."}, help = {"[LFG] The path leads to {activity} ({type}). I bring {myroles}, and seek {needed}. Whisper me."},
    },
    orc = {
        login = {"{name}! You have returned. Good!"}, join = {"Stand with us, {name}! Welcome to the guild!"},
        level = {"Strength earned! Level {level}, {name}!"}, help = {"[LFG] Warriors for {activity} ({type})! I bring {myroles}, require {needed}. Whisper!"},
    },
    troll = {
        login = {"Ey, {name}, ya back! Good to see ya, mon!", "Da guild be better with ya here, {name}!"},
        join = {"Make some room for {name}, mon!", "Da tribe grows! Welcome, {name}!"},
        level = {"Look at ya go, {name}! Level {level}, mon!", "Level {level}? Ya movin' up, {name}!"},
        help = {"[LFG] Who's comin' for {activity} ({type})? I bring {myroles}; need {needed}. Whisper me, mon!"},
    },
    tauren = {
        login = {"It is good to walk beside you again, {name}."}, join = {"The Earth Mother welcomes you, {name}."},
        level = {"Your journey reaches level {level}, {name}. Well done."}, help = {"[LFG] Our path leads to {activity} ({type}). I offer {myroles}; we seek {needed}. Whisper me."},
    },
    forsaken = {
        login = {"Still with us, {name}? How unexpectedly pleasant."}, join = {"Another soul joins us. Welcome, {name}."},
        level = {"Level {level}, {name}? Persistence pays, apparently."}, help = {"[LFG] An expedition to {activity} ({type}). I supply {myroles}; we require {needed}. Whisper me."},
    },
    skyborne = {
        login = {"The sky feels brighter with you here, {name}!"}, join = {"Spread your wings, {name}! Welcome!"},
        level = {"Higher still, {name}! Level {level}!"}, help = {"[LFG] Off to {activity} ({type})! I can fly as {myroles}; need {needed}. Whisper me!"},
    },
    goblin = {
        login = {"{name}! Back for another profitable day?"}, join = {"New recruit {name}! Signing bonus not included!"},
        level = {"Level {level}, {name}! That's value for money!"}, help = {"[LFG] Special deal: {activity} ({type})! Selling {myroles}, buying {needed}. Whisper me!"},
    },
    bloodelf = {
        login = {"Your presence graces us again, {name}."}, join = {"Do make yourself at home, {name}. Welcome."},
        level = {"Exquisite progress, {name}. Level {level}."}, help = {"[LFG] A party for {activity} ({type}). I offer {myroles} and seek {needed}. Whisper me."},
    },
    draenei = {
        login = {"It is a blessing to see you again, {name}."}, join = {"Welcome, {name}. May the Light guide your steps."},
        level = {"Level {level} achieved, {name}. Walk in the Light."}, help = {"[LFG] Companions for {activity} ({type})? I provide {myroles}, seeking {needed}. Whisper me."},
    },
    mexican = {
        login = {"¡Mira quién volvió, {name}! ¡Qué gusto!", "¡{name}, qué bueno tenerte de vuelta!"},
        join = {"¡Bienvenido, {name}! ¡Qué gusto que estés aquí!", "¡Un aplauso para {name}, que se une a la hermandad!"},
        level = {"¡Ándale, {name}! ¡Nivel {level}!", "¡Te luciste, {name}! ¡Ya llegaste al nivel {level}!"},
        help = {"[LFG] ¿Quién se anima a {activity} ({type})? Voy de {myroles}; nos falta {needed}. ¡Susúrrame!"},
    },
    cuban = {
        login = {"¡Asere, {name}, ya regresaste!"}, join = {"¡Un abrazo de bienvenida para {name}!"},
        level = {"¡Qué clase de subida, {name}! ¡Nivel {level}!"}, help = {"[LFG] ¿Quién viene a {activity} ({type})? Puedo ir de {myroles}; falta {needed}. ¡Escríbeme!"},
    },
    spanish = {
        login = {"¡Hombre, {name}! ¡Ya estás por aquí otra vez!"}, join = {"¡Recibamos a {name} en la hermandad!"},
        level = {"¡Muy bien, {name}! ¡Nivel {level}!"}, help = {"[LFG] ¿Alguien se apunta a {activity} ({type})? Voy de {myroles}; buscamos {needed}. ¡Susurradme!"},
    },
    quebec = {
        login = {"Te revoilà, {name} ! Ça fait plaisir !"}, join = {"Un gros bienvenue à {name} !"},
        level = {"Super, {name} ! Niveau {level} !"}, help = {"[LFG] Qui embarque pour {activity} ({type}) ? Je joue {myroles} ; il manque {needed}. Écris-moi !"},
    },
    bavarian = {
        login = {"Griaß di, {name}! Wieder da?"}, join = {"Ein herzliches Servus für {name}!"},
        level = {"Sauber gemacht, {name}! Stufe {level}!"}, help = {"[LFG] Wer ist bei {activity} ({type}) dabei? Ich spiele {myroles}; brauche {needed}. Schreib mir!"},
    },
    brazilian = {
        login = {"E aí, {name}! Bom te ver de volta!"}, join = {"Galera, deem as boas-vindas ao {name}!"},
        level = {"Mandou bem, {name}! Nível {level}!"}, help = {"[LFG] Bora fazer {activity} ({type})? Posso ir de {myroles}; precisamos de {needed}. Me chama!"},
    },
    portuguese = {
        login = {"Ora viva, {name}! Bom regresso!"}, join = {"Vamos dar as boas-vindas a {name}!"},
        level = {"Muito bem, {name}! Nível {level}!"}, help = {"[LFG] Quem quer fazer {activity} ({type})? Posso jogar como {myroles}; precisamos de {needed}. Sussurra-me!"},
    },
    southernitalian = {
        login = {"Ehi {name}, bentornato tra noi!"}, join = {"Che gioia, {name}! Benvenuto tra noi!"},
        level = {"Che bravo, {name}! Livello {level}!"}, help = {"[LFG] Chi viene a {activity} ({type})? Posso fare {myroles}; serve {needed}. Scrivimi!"},
    },
}

-- Shuffle bag: exhaust every wording before reshuffling, while avoiding an
-- immediate repeat across two consecutive bags. Session-local by design.
A.messageVariantBags = {}
function A:ChooseMessageTemplate(kind, language, accent, base)
    local choices = {base}
    local additions
    if accent then
        additions = self.accentVariants and self.accentVariants[accent.id]
    else
        additions = self.localeVariants and self.localeVariants[language]
    end
    for _, template in ipairs((additions and additions[kind]) or {}) do
        if type(template) == "string" and template ~= "" and template ~= base then
            choices[#choices + 1] = template
        end
    end
    if #choices < 2 then return base end

    local signature = table.concat({tostring(kind), tostring(language),
        accent and accent.id or "none"}, ":")
    local bag = self.messageVariantBags[signature]
    if not bag or bag.count ~= #choices or bag.position > #bag.order then
        local order = {}
        for i = 1, #choices do order[i] = i end
        for i = #order, 2, -1 do
            local j = math.random(i)
            order[i], order[j] = order[j], order[i]
        end
        if bag and bag.last and order[1] == bag.last then
            order[1], order[2] = order[2], order[1]
        end
        bag = {order=order, position=1, count=#choices, last=bag and bag.last}
        self.messageVariantBags[signature] = bag
    end
    local index = bag.order[bag.position]
    bag.last = index
    bag.position = bag.position + 1
    return choices[index]
end
