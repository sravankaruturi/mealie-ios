import Foundation

struct IngredientParser {
    
    static func parse(_ text: String) -> (quantity: Double, unit: String, name: String)? {
        
        // Very basic parser for demo purposes
        let pattern = "([0-9.]+)\\s*([a-zA-Z]+)?\\s*(.*)"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return nil }
        let nsrange = NSRange(text.startIndex..<text.endIndex, in: text)
        guard let match = regex.firstMatch(in: text, options: [], range: nsrange) else { return nil }
        let quantity = Double((text as NSString).substring(with: match.range(at: 1))) ?? 1.0
        let unit = match.range(at: 2).location != NSNotFound ? (text as NSString).substring(with: match.range(at: 2)) : ""
        let name = match.range(at: 3).location != NSNotFound ? (text as NSString).substring(with: match.range(at: 3)) : text
        
        if unit.isEmpty || !name.trimmingCharacters(in: .whitespaces).isEmpty {
            return (quantity, unit, name)
        } else {
            // When there is no item name left, treat the captured unit as the ingredient name.
            return (quantity, "", unit)
        }
        
    }
    
}
