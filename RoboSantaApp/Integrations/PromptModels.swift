import Foundation

let helloPhrase = "Ett ord eller två för att snabbt få personens uppmärksamhet. Får inte vara långt, annars har de redan gått!"
let goodbyePhrase = "En sista hejdå-fras för att avsluta samtalet eller när personen går (igen, inte mycket tid – håll det kort)."

let peppTalkSchema = Model(
    name: "PeppTalk",
    description: "Din scen: Tomten lyfter humöret hemma. Allt ska vara positivt, lekfullt och lite fräckt men rumsrent, utan mörker eller oro.",
    properties: [
        Property(
            name: "happyPhrase",
            description: "En kort, glad peppfras som får personen att le. Mycket värme, hopp och omtanke men med mer humor. Knyt gärna an till ämnet på ett lekfullt sätt."
        ),
    ]
)

var passByAndGreetSchema = Model(
    name: "PassbyAndGreet",
    description: "Snabb hälsning hemma i en privat miljö.",
    properties: [
        Property(
            name: "helloPhrase",
            description: "Direkt, personlig öppning.",
            minLength: 3, maxLength: 50, disallowQuestion: true
        ),
        Property(
            name: "conversationPhrase",
            description: "En enda mening; smyg in temat subtilt och gärna med humor.",
            minLength: 5, maxLength: 70
        ),
        Property(
            name: "goodbyePhrase",
            description: "Rappt avslut utan artighetsutfyllnad.",
            minLength: 3, maxLength: 55, disallowQuestion: true
        ),
    ]
)

struct QuizOut: Decodable { let helloPhrase, question, answer1, answer2, answer3, correct_answer, goodbyePhrase: String }
let quizSchema = Model(
    name: "Quiz",
    description: "Din scen: Tomten ger en mycket kort, rolig och lite busig quiz med tre val. Lägg varje svar i sitt eget fält. Lägg inte till A/B/C på svaren.",
    properties: [
        Property(
            name: "helloPhrase",
            description: helloPhrase
        ),
        Property(
            name: "question",
            description: "En kort enradig fråga om ett ämne, om situationen, julen eller något slumpmässigt."
        ),
        Property(
            name: "answer1",
            description: "Ett kort första svar på frågan."
        ),
        Property(
            name: "answer2",
            description: "Ett kort andra svar på frågan."
        ),
        Property(
            name: "answer3",
            description: "Ett kort tredje svar på frågan."
        ),
        Property(
            name: "correct_answer",
            description: "Det svar du tycker att det ska vara. Helst inte ett av ovan, hellre något oväntat men relaterat."
        ),
        Property(
            name: "goodbyePhrase",
            description: goodbyePhrase
        ),
    ]
)

let jokeSchema = Model(
    name: "Joke",
    description: "Din scen: Tomten känner till en busig hemlighet om personen han möter. Håll det kort, fräckt men rumsrent!",
    properties: [
        Property(
            name: "helloPhrase",
            description: helloPhrase
        ),
        Property(
            name: "secret",
            description: "En kort enradig hemlighet om en person. Tomten känner allas hemligheter!"
        ),
        Property(
            name: "compliment",
            description: "En mycket kort enradig komplimang om den hemligheten."
        ),
        Property(
            name: "goodbyePhrase",
            description: goodbyePhrase
        ),
    ]
)

let pointingSchema = Model(
    name: "Pointing",
    description: "Din scen: Tomten pekar åt personen hemma för att dela ett kort råd eller en humoristisk varning. Håll det lekfullt, busigt och rumsrent!",
    properties: [
        Property(
            name: "attentionPhrase",
            description: "Ett GENERISKT utrop (1-3 ord) för att fånga uppmärksamhet. MÅSTE vara oberoende av ämnet. Välj SLUMPMÄSSIGT ett av: 'Hallå du!', 'Psst!', 'Lyssna!', 'Du där!', 'Hallå!', 'Hörru!', 'Titta här!', 'Stopp!', 'Vänta!', 'Akta dig!', 'Kolla!', 'Hej du!'. VARIERA valet varje gång!",
            minLength: 2, maxLength: 15, disallowQuestion: true
        ),
        Property(
            name: "lecturePhrase",
            description: "En kort rekommendation, humoristisk varning eller visdomsord. Något man säger medan man pekar med fingret uppåt. Knyt an till ämnet.",
            minLength: 15, maxLength: 120
        ),
    ]
)

//

let randomTopicActions = [
    "investering i",
    "idéer om",
    "färgen på",
    "motsatsen till",
    "framtiden för",
    "historien om",
    "kritik av",
    "försvar av",
    "fördelar med",
    "nackdelar med",
    "risker med",
    "möjligheter i",
    "konsekvenser av",
    "effekter av",
    "strategier för",
    "visionen för",
    "drömmar om",
    "mardrömmar om",
    "fantasier om",
    "metafor för",
    "symboliken i",
    "humorn i",
    "ironin i",
    "paradoxen i",
    "mysteriet med",
    "skandalen kring",
    "hemligheten bakom",
    "ursprunget till",
    "framtidsscenarier för",
    "sagor om",
    "haiku om",
    "standup-rutin om",
    "memer om",
    "tweetstorm om",
    "dagboksanteckningar om",
    "nyhetsartikel om",
    "polisanmälan om",
    "buggrapport om",
    "manual för",
    "användarguide till",
    "färdplan för",
    "retrospektiv om",
    "postmortem om",
    "affärsplan för",
    "budget för",
    "workshop om",
    "rollspel kring",
    "debatt om",
    "föreläsning om",
    "TED-talk om",
    "konstinstallation om",
    "fotoutställning om",
    "brädspel om",
    "podcast-avsnitt om",
    "radioteater om",
    "sångtitel om",
    "soundtrack för",
    "filmmanus om",
    "TV-serie om",
    "dystopi om",
    "utopi om",
    "manualen för att överleva",
    "livscoachning kring",
    "terapisession om",
    "barndomsminnen av",
    "nostalgi kring",
    "framtidsångest om",
    "kärleken till",
    "besattheten av",
    "beroendet av",
    "konflikten kring",
    "balansen i",
    "kompromissen kring",
    "förhandlingen om",
    "lagstiftning om",
    "paragrafdjungeln kring",
    "policy för",
    "etiken kring",
    "moralen i",
    "säkerhetsbrister i",
    "teststrategi för",
    "proof-of-concept för",
    "hackathon-idéer om",
    "prototyp av",
    "wireframes för",
    "UX-katastrof kring",
    "dark-pattern-version av",
    "värsta möjliga tolkning av",
    "bästa möjliga tolkning av",
    "slumputredd teori om",
    "konspirationsteori om",
    "soffskvaller om",
    "köksbänksnack om",
    "småprat om",
    "kompischatt om",
    "dagboksrad om",
    "pressmeddelande om",
    "affischkampanj för",
    "tatuering med"
]


let randomTopics = [
    "kaffe",
    "fika",
    "frukost",
    "brunch",
    "matlåda",
    "promenad",
    "cykel",
    "pendling",
    "t-bana",
    "buss",
    "väder",
    "regnjacka",
    "lunch",
    "middag",
    "disk",
    "tvätt",
    "sopsortering",
    "matbutik",
    "lögner",
    "hyra",
    "grannar",
    "bajs",
    "hundpromenad",
    "tjuvfis",
    "Söder",
    "Götgatan",
    "Hornstull",
    "Mariatorget",
    "Skinnarviksberget",
    "smygätande",
    "julgran",
    "julpynt",
    "julbelysning",
    "adventsljusstake",
    "pepparkakor",
    "glögg",
    "lussekatter",
    "julklappar",
    "julklappsjakt",
    "julklappspapper",
    "julstress",
    "julstämning",
    "julmusik",
    "julsång",
    "snarkning",
    "tomten",
    "nisse",
    "snö",
    "isiga trottoarer",
    "julfirande",
    "julmat",
    "julskinka",
    "sill",
    "knäck",
    "pinsamheter",
    "julledighet",
    "advent",
    "lucia",
    "julkalender",
    "nyårslöfte",
]
