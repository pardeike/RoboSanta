import FoundationModels

struct Answer {
    let fields: [String: String]
    
    init(model: Model, content: GeneratedContent) {
        var fields = [String: String]()
        for p in model.properties {
            fields[p.name] = (try? content.value(String.self, forProperty: p.name)) ?? ""
        }
        self.fields = fields
    }
    
    func value(_ name: String) -> String { fields[name] ?? "" }
}
