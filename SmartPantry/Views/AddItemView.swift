import SwiftUI
import SwiftData

struct AddItemView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String = ""
    @State private var quantityValue: String = ""
    @State private var quantityUnit: String = "pcs"
    @State private var category: Category = .fridge
    @State private var expiryDate: Date = Date().addingTimeInterval(86400 * 7) // Default 1 week
    @State private var barcode: String?
    @State private var imageURL: URL?
    @State private var brand: String?
    @State private var isLoading = false
    
    let units = ["pcs", "g", "kg", "ml", "l"]
    
    init(barcode: String? = nil) {
        _barcode = State(initialValue: barcode)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                if isLoading {
                    HStack {
                        Spacer()
                        ProgressView("Fetching product details...")
                        Spacer()
                    }
                }
                
                Section(header: Text("Item Details")) {
                    if let imageURL {
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
                    
                    TextField("Name (e.g., Milk)", text: $name)
                    if let brand {
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
                    
                    Picker("Category", selection: $category) {
                        ForEach(Category.allCases, id: \.self) { category in
                            Text(category.rawValue).tag(category)
                        }
                    }
                }
                
                Section(header: Text("Expiry"), footer: barcode != nil ? Text("Please verify the expiry date on the package.").foregroundStyle(.red) : nil) {
                    DatePicker("Expires On", selection: $expiryDate, displayedComponents: .date)
                }
            }
            .navigationTitle("Add Item")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        addItem()
                    }
                    .disabled(name.isEmpty || quantityValue.isEmpty || isLoading)
                }
            }
            .task {
                if let barcode, name.isEmpty {
                    await fetchProductDetails(barcode: barcode)
                }
            }
        }
    }
    
    private func fetchProductDetails(barcode: String) async {
        isLoading = true
        do {
            if let product = try await OpenFoodFactsService.shared.fetchProduct(barcode: barcode) {
                if let productName = product.productName {
                    self.name = productName
                }
                if let brand = product.brands {
                    self.brand = brand
                }
                if let urlString = product.imageFrontUrl, let url = URL(string: urlString) {
                    self.imageURL = url
                }
                
                if let quantityString = product.quantity {
                    // Use QuantityHelper to parse "500 g" -> value: 500, unit: g
                    if let qty = QuantityHelper.shared.parse(quantityString) {
                        // Remove trailing .0
                        let value = qty.value
                        let formattedValue = value.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", value) : String(format: "%.1f", value)
                        
                        self.quantityValue = formattedValue
                        self.quantityUnit = qty.unit
                    } else {
                        // Fallback if parsing fails, just put it all in value or try simple split
                        self.quantityValue = quantityString
                    }
                }
                
                // Auto-fill Category and Expiry
                self.category = product.predictedCategory
                self.expiryDate = product.estimatedExpiryDate
            }
        } catch {
            print("Error fetching product: \(error)")
        }
        isLoading = false
    }
    
    private func addItem() {
        let finalQuantity = "\(quantityValue) \(quantityUnit)"
        let newItem = Item(name: name, quantity: finalQuantity, category: category, expiryDate: expiryDate, barcode: barcode, imageURL: imageURL, brand: brand)
        modelContext.insert(newItem)
        try? modelContext.save()
        
        // Schedule notification
        NotificationManager.shared.scheduleNotification(for: newItem)
        
        dismiss()
    }
}
