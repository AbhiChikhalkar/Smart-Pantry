import Foundation

struct Quantity {
    var value: Double
    var unit: String
}

class QuantityHelper {
    static let shared = QuantityHelper()
    
    private init() {}
    
    // Parse "500 g" or "1.5 kg" into Quantity struct
    func parse(_ string: String) -> Quantity? {
        let parts = string.lowercased().split(separator: " ")
        guard parts.count >= 2, let value = Double(parts[0]) else { return nil }
        
        let unit = String(parts[1])
        return Quantity(value: value, unit: unit)
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
