import FoundationModels

struct Property {
    let name: String
    let description: String
    
    func dynamicGenerationSchemaProperty() -> DynamicGenerationSchema.Property {
        DynamicGenerationSchema.Property(
            name: self.name,
            description: self.description,
            schema: DynamicGenerationSchema(type: String.self),
            isOptional: false
        )
    }
}
