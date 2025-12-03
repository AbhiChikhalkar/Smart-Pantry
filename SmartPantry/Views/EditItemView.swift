import SwiftUI
import SwiftData

struct EditItemView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var item: Item
    
    @State private var quantityValue: String = ""
    @State private var quantityUnit: String = "pcs"
    
    let units = ["pcs", "g", "kg", "ml", "l"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Item Details")) {
                    if let imageURL = item.imageURL {
                        HStack {
                            Spacer()
                            AsyncImage(url: imageURL) { image in
                                image.resizable().scaledToFit()
                            } placeholder: {
                                ProgressView()
                            }
                            .frame(height: 150)
                            Spacer()
                        }
                    }
                    
                    TextField("Name", text: $item.name)
                    
                    if let brand = item.brand {
                        Text("Brand: \(brand)").font(.caption).foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        TextField("Amount", text: $quantityValue)
                            .keyboardType(.decimalPad)
                        Picker("Unit", selection: $quantityUnit) {
                            ForEach(units, id: \.self) { unit in
                                Text(unit).tag(unit)
                            }
                        }
                        .labelsHidden()
                    }
                    
                    Picker("Category", selection: $item.category) {
                        ForEach(Category.allCases, id: \.self) { category in
                            Text(category.rawValue).tag(category)
                        }
                    }
                }
                
                Section(header: Text("Expiry")) {
                    DatePicker("Expires On", selection: $item.expiryDate, displayedComponents: .date)
                }
            }
            .navigationTitle("Edit Item")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        saveChanges()
                    }
                }
            }
            .onAppear {
                parseQuantity()
            }
        }
    }
    
    private func parseQuantity() {
        // Use QuantityHelper to parse robustly
        if let quantity = QuantityHelper.shared.parse(item.quantity) {
            // Remove trailing .0
            let value = quantity.value
            let formattedValue = value.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", value) : String(format: "%.1f", value)
            
            quantityValue = formattedValue
            quantityUnit = quantity.unit
        } else {
            // Fallback: try to extract just the number
            let components = item.quantity.components(separatedBy: CharacterSet.decimalDigits.inverted).filter { !$0.isEmpty }
            if let first = components.first {
                quantityValue = first
            } else {
                quantityValue = item.quantity
            }
        }
    }
    
    private func saveChanges() {
        item.quantity = "\(quantityValue) \(quantityUnit)"
        dismiss()
    }
}
