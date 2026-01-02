import SwiftUI
import SwiftData

struct ShoppingListView: View {
    @Environment(\.modelContext) private var modelContext
    
    // Items to buy (status == .shoppingList)
    @Query(filter: #Predicate<Item> { item in
        item.statusRawValue == "shoppingList"
    }, sort: \Item.name) private var shoppingListItems: [Item]
    
    // Suggested items (status == .consumed or .discarded)
    @Query(filter: #Predicate<Item> { item in
        item.statusRawValue == "consumed" || item.statusRawValue == "discarded"
    }, sort: \Item.expiryDate, order: .reverse) private var suggestedItems: [Item]
    
    @State private var showingAddSheet = false
    @State private var newItemName = ""
    @State private var itemToAdd: Item?
    @State private var showingQuantitySheet = false
    
    // Custom Sheet State
    @State private var quantityValue = "1"
    @State private var selectedUnit = "pcs"
    let units = ["pcs", "kg", "g", "L", "ml", "pack", "can"]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // To Buy Section
                    if shoppingListItems.isEmpty {
                        ContentUnavailableView("List is Empty", systemImage: "cart", description: Text("Add items to your shopping list."))
                            .padding(.vertical, 20)
                    } else {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("To Buy")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            ForEach(shoppingListItems) { item in
                                ShoppingItemCard(item: item, isSuggestion: false) {
                                    markAsBought(item)
                                }
                                .contextMenu {
                                    Button(role: .destructive) {
                                        modelContext.delete(item)
                                    } label: {
                                        Label("Remove", systemImage: "trash")
                                    }
                                }
                            }
                        }
                    }
                    
                    // Suggestions Section
                    if !suggestedItems.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Recently Used")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            ForEach(suggestedItems) { item in
                                ShoppingItemCard(item: item, isSuggestion: true) {
                                    promptForQuantity(item)
                                }
                            }
                        }
                    }
                }
                .padding(.vertical)
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Shopping List")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingAddSheet = true }) {
                        Image(systemName: "plus")
                            .font(.headline)
                            .bold()
                    }
                }
            }
            .alert("Add to Shopping List", isPresented: $showingAddSheet) {
                TextField("Item Name", text: $newItemName)
                Button("Add") {
                    addNewItem()
                }
                Button("Cancel", role: .cancel) { }
            }
            .sheet(isPresented: $showingQuantitySheet) {
                VStack(spacing: 24) {
                    Text("How much needed?")
                        .font(.headline)
                        .padding(.top)
                    
                    if let item = itemToAdd {
                        Text(item.name)
                            .font(.title2)
                            .bold()
                    }
                    
                    HStack(spacing: 16) {
                        // Numeric Input
                        TextField("Qty", text: $quantityValue)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.center)
                            .frame(width: 100, height: 50)
                            .background(Color(UIColor.secondarySystemGroupedBackground))
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.3)))
                        
                        // Unit Picker (Menu Style)
                        Menu {
                            ForEach(units, id: \.self) { unit in
                                Button(unit) {
                                    selectedUnit = unit
                                }
                            }
                        } label: {
                            HStack {
                                Text(selectedUnit)
                                    .foregroundStyle(.primary)
                                Image(systemName: "chevron.down")
                                    .foregroundStyle(.secondary)
                            }
                            .frame(width: 100, height: 50)
                            .background(Color(UIColor.secondarySystemGroupedBackground))
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.3)))
                        }
                    }
                    
                    Button(action: confirmAdd) {
                        Text("Add to List")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                }
                .padding()
                .presentationDetents([.fraction(0.35)]) // Helper sheet typically takes ~35%
                .presentationDragIndicator(.visible)
            }
        }
    }
    
    private func markAsBought(_ item: Item) {
        withAnimation {
            item.status = .available
            item.addedDate = Date()
            item.expiryDate = Date().addingTimeInterval(86400 * 7)
        }
    }
    
    private func promptForQuantity(_ item: Item) {
        itemToAdd = item
        quantityValue = "1"
        selectedUnit = "pcs"
        
        // Try to parse existing quantity to pre-fill
        let parts = item.quantity.split(separator: " ")
        if parts.count >= 2 {
             if Double(parts[0]) != nil {
                 quantityValue = parts[0].replacingOccurrences(of: ".0", with: "")
             } else {
                 quantityValue = String(parts[0])
             }
             selectedUnit = String(parts[1])
        }
        
        showingQuantitySheet = true
    }
    
    private func confirmAdd() {
        guard let item = itemToAdd else { return }
        
        withAnimation {
            item.quantity = "\(quantityValue) \(selectedUnit)"
            item.status = .shoppingList
        }
        
        showingQuantitySheet = false
        itemToAdd = nil
    }
    
    private func addNewItem() {
        guard !newItemName.isEmpty else { return }
        let newItem = Item(name: newItemName, quantity: "1 pcs", category: .fridge, expiryDate: Date(), status: .shoppingList)
        modelContext.insert(newItem)
        newItemName = ""
    }
}

struct ShoppingItemCard: View {
    let item: Item
    let isSuggestion: Bool
    let action: () -> Void
    
    var body: some View {
        HStack {
            Button(action: action) {
                Image(systemName: isSuggestion ? "plus.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(isSuggestion ? .green : .secondary)
            }
            
            VStack(alignment: .leading) {
                Text(item.name)
                    .font(.body)
                    .strikethrough(isSuggestion)
                    .foregroundStyle(isSuggestion ? .secondary : .primary)
                
                if !item.quantity.isEmpty && item.quantity != "1 pcs" {
                    Text(item.quantity)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            if isSuggestion {
                Text(item.status == .consumed ? "Consumed" : "Discarded")
                    .font(.caption2)
                    .foregroundStyle(item.status == .consumed ? .green : .red)
                    .padding(4)
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(4)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}
