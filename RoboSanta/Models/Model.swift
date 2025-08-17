import FoundationModels

struct Model {
    let name: String
    let description: String
    let properties: [Property]
    
    func dynamicGenerationSchema() throws -> GenerationSchema {
        let schema = DynamicGenerationSchema(
            name: self.name,
            description: self.description,
            properties: self.properties.map { $0.dynamicGenerationSchemaProperty() }
        )
        return try GenerationSchema(root: schema, dependencies: [])
    }
}
