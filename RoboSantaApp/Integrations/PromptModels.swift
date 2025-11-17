let passByAndGreetSchema = Model(
    name: "PassbyAndGreet",
    description: "Things to say by a Swedish Santa Claus standing in an office corridor meeting a passerby. All three phrases must be coherent.",
    properties: [
        Property(
            name: "firstPhrase",
            description: "A short first phrase to say to catch their attention. Make it interesting!"
        ),
        Property(
            name: "secondPhrase",
            description: "A second phrase to say once that person got closer."
        ),
        Property(
            name: "thirdPhrase",
            description: "A final phrase to say goodbye and end the conversation."
        ),
    ]
)

let quizSchema = Model(
    name: "Quiz",
    description: "A funny quiz with three choices. Put each answer in its own field. Do not add A/B/C to the answers.",
    properties: [
        Property(
            name: "question",
            description: "A short single line question about a random topic. Make it interesting!"
        ),
        Property(
            name: "answer1",
            description: "A single line first answer to the question."
        ),
        Property(
            name: "answer2",
            description: "A single line second answer to the question."
        ),
        Property(
            name: "answer3",
            description: "A single line third answer to the question."
        ),
        Property(
            name: "ending",
            description: "The resolving answer to the quiz, followed by a short goodbye phrase."
        ),
    ]
)

let jokeSchema = Model(
    name: "Joke",
    description: "An office worker stands in front of Santa. Give them a compliment only Santa Claus would know, and a tasteful joke, divided in a buildup and a punchline.",
    properties: [
        Property(
            name: "compliment",
            description: "A short single line compliment."
        ),
        Property(
            name: "buildup",
            description: "A very short single line buildup for a joke about the person. Santa knows everyones secrets!"
        ),
        Property(
            name: "punchline",
            description: "A very short single line punchline that goes with the buildup."
        ),
    ]
)
