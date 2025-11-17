import Foundation
import FoundationModels

struct Property {
    let name: String
    let description: String
    var minLength: Int? = nil
    var maxLength: Int? = nil
    var disallowQuestion: Bool = false
    var examples: [String] = []
    
    func dynamicGenerationSchemaProperty() -> DynamicGenerationSchema.Property {
        DynamicGenerationSchema.Property(
            name: self.name,
            description: self.description,
            schema: DynamicGenerationSchema(type: String.self),
            isOptional: false
        )
    }
}
