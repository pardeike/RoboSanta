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
            description: "A final phrase to end the conversation or when they leave."
        ),
    ]
)
