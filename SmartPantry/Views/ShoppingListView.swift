import SwiftUI
import SwiftData

struct ShoppingListView: View {
    @Environment(\.modelContext) private var modelContext
    
    // Items to buy (status == .shoppingList)
    @Query(filter: #Predicate<Item> { item in
        item.statusRawValue == "shoppingList"
    }, sort: \Item.name) private var shoppingListItems: [Item]
    
    // Suggested items (status == .consumed or .discarded)
    // We limit to recent ones or just show all for now
    @Query(filter: #Predicate<Item> { item in
        item.statusRawValue == "consumed" || item.statusRawValue == "discarded"
    }, sort: \Item.expiryDate, order: .reverse) private var suggestedItems: [Item]
    
    @State private var showingAddSheet = false
    @State private var newItemName = ""
    
    var body: some View {
        NavigationStack {
            List {
                Section("To Buy") {
                    if shoppingListItems.isEmpty {
                        ContentUnavailableView("List is Empty", systemImage: "cart", description: Text("Add items or check suggestions below."))
                    } else {
                        ForEach(shoppingListItems) { item in
                            HStack {
                                Button(action: { markAsBought(item) }) {
                                    Image(systemName: "circle")
                                        .foregroundStyle(.secondary)
                                }
                                Text(item.name)
                                Spacer()
                                Text(item.quantity)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .onDelete(perform: deleteShoppingItems)
                    }
                }
                
                Section("Suggested (Based on History)") {
                    if suggestedItems.isEmpty {
                        Text("No history yet. Consume items to see suggestions.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(suggestedItems) { item in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(item.name)
                                    Text(item.status == .consumed ? "Consumed" : "Discarded")
                                        .font(.caption)
                                        .foregroundStyle(item.status == .consumed ? .green : .red)
                                }
                                Spacer()
                                Button(action: { addToShoppingList(item) }) {
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                        .onDelete(perform: deleteSuggestedItems)
                    }
                }
            }
            .navigationTitle("Shopping List")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingAddSheet = true }) {
                        Image(systemName: "plus")
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
        }
    }
    
    private func markAsBought(_ item: Item) {
        withAnimation {
            item.status = .available
            item.addedDate = Date()
            // Reset expiry to default 1 week from now as a guess, user should edit
            item.expiryDate = Date().addingTimeInterval(86400 * 7)
        }
    }
    
    private func addToShoppingList(_ item: Item) {
        withAnimation {
            item.status = .shoppingList
        }
    }
    
    private func addNewItem() {
        guard !newItemName.isEmpty else { return }
        let newItem = Item(name: newItemName, quantity: "1 pcs", category: .fridge, expiryDate: Date(), status: .shoppingList)
        modelContext.insert(newItem)
        newItemName = ""
    }
    
    private func deleteShoppingItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(shoppingListItems[index])
            }
        }
    }
    
    private func deleteSuggestedItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(suggestedItems[index])
            }
        }
    }
}
