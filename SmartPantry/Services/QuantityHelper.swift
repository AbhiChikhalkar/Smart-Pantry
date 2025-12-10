import Foundation

struct Quantity {
    var value: Double
    var unit: String
}

class QuantityHelper {
    static let shared = QuantityHelper()
    
    private init() {}
    
    // Parse "500 g", "500g", "1.5kg" into Quantity struct
    func parse(_ string: String) -> Quantity? {
        let trimmed = string.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Regex to match number (integer or decimal) followed by optional space and unit
        // Groups: 1 = Value, 2 = Unit
        let pattern = "^([0-9]+(?:\\.[0-9]+)?)\\s*([a-z]+)$"
        
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(location: 0, length: trimmed.utf16.count)
        
        if let match = regex.firstMatch(in: trimmed, options: [], range: range) {
            if let valueRange = Range(match.range(at: 1), in: trimmed),
               let unitRange = Range(match.range(at: 2), in: trimmed) {
                
                let valueStr = String(trimmed[valueRange])
                let unitStr = String(trimmed[unitRange])
                
                if let value = Double(valueStr) {
                    return Quantity(value: value, unit: unitStr)
                }
            }
        }
        
        // Fallback for simple space split (legacy support)
        let parts = trimmed.split(separator: " ")
        if parts.count >= 2, let value = Double(parts[0]) {
            return Quantity(value: value, unit: String(parts[1]))
        }
        
        return nil
    }
    
    // Deduct recipe amount from inventory amount
    // Returns new Quantity string for inventory, or nil if calculation failed
    func deduct(recipeQtyStr: String, from inventoryQtyStr: String) -> String? {
        guard let recipeQty = parse(recipeQtyStr),
              let inventoryQty = parse(inventoryQtyStr) else { return nil }
        
        // Normalize to base units (g, ml, pcs)
        let (rVal, rUnit) = normalize(recipeQty)
        let (iVal, iUnit) = normalize(inventoryQty)
        
        guard rUnit == iUnit else { return nil } // Unit mismatch
        
        let newVal = iVal - rVal
        
        // If result is negative or zero, return "0 [unit]" (or handle as consumed)
        if newVal <= 0 {
            return "0 \(iUnit)" // Caller should probably delete the item or mark consumed
        }
        
        // Convert back to original unit if possible, or keep as base
        // For simplicity, we'll return in base units (g, ml) or smart convert if large
        return format(value: newVal, unit: iUnit)
    }
    
    private func normalize(_ qty: Quantity) -> (Double, String) {
        switch qty.unit {
        case "kg": return (qty.value * 1000, "g")
        case "g": return (qty.value, "g")
        case "l": return (qty.value * 1000, "ml")
        case "ml": return (qty.value, "ml")
        case "pcs", "pc": return (qty.value, "pcs")
        default: return (qty.value, qty.unit)
        }
    }
    
    private func format(value: Double, unit: String) -> String {
        if unit == "g" && value >= 1000 {
            return String(format: "%.1f kg", value / 1000)
        }
        if unit == "ml" && value >= 1000 {
            return String(format: "%.1f l", value / 1000)
        }
        // Remove trailing .0 for integers
        let formattedValue = value.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", value) : String(format: "%.1f", value)
        return "\(formattedValue) \(unit)"
    }
}
