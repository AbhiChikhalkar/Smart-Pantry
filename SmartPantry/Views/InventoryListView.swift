import SwiftUI
import SwiftData
import VisionKit

struct InventoryListView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var searchText = ""
    
    let category: Category
    
    // Wrapper view to handle search filtering
    var body: some View {
        InventoryList(category: category, searchText: searchText)
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
    }
}

struct InventoryList: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Item]
    
    @State private var showingAddOptions = false
    @State private var showingScanner = false
    @State private var showingManualEntry = false
    @State private var showingScannerError = false
    @State private var scannedCode: String?
    @State private var itemToEdit: Item?
    
    let category: Category
    
    init(category: Category, searchText: String) {
        self.category = category
        
        let categoryRawValue = category.rawValue
        let availableStatus = ItemStatus.available.rawValue
        
        if searchText.isEmpty {
            _items = Query(filter: #Predicate<Item> { item in
                item.categoryRawValue == categoryRawValue && item.statusRawValue == availableStatus
            }, sort: \Item.expiryDate)
        } else {
            _items = Query(filter: #Predicate<Item> { item in
                item.categoryRawValue == categoryRawValue && item.statusRawValue == availableStatus && item.name.localizedStandardContains(searchText)
            }, sort: \Item.expiryDate)
        }
    }
    
    var body: some View {
        List {
            if items.isEmpty {
                ContentUnavailableView(
                    "No Items",
                    systemImage: category == .fridge ? "refrigerator" : "cabinet",
                    description: Text("Tap + to add items to your \(category.rawValue).")
                )
            } else {
                ForEach(items) { item in
                    HStack {
                        if let imageURL = item.imageURL {
                            AsyncImage(url: imageURL) { image in
                                image.resizable().scaledToFit()
                            } placeholder: {
                                Image(systemName: "photo")
                            }
                            .frame(width: 40, height: 40)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        
                        VStack(alignment: .leading) {
                            Text(item.name)
                                .font(.headline)
                            if let brand = item.brand {
                                Text(brand)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing) {
                            Text(item.quantity)
                                .font(.subheadline)
                            
                            // Expiry Badge
                            let days = Calendar.current.dateComponents([.day], from: Date(), to: item.expiryDate).day ?? 0
                            Text(days < 0 ? "Expired" : (days == 0 ? "Today" : "\(days)d left"))
                                .font(.caption)
                                .padding(4)
                                .background(days < 3 ? Color.red.opacity(0.2) : Color.green.opacity(0.2))
                                .foregroundStyle(days < 3 ? .red : .green)
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        itemToEdit = item
                    }
                    .swipeActions(edge: .leading) {
                        Button {
                            withAnimation {
                                item.status = .consumed
                                try? modelContext.save()
                            }
                        } label: {
                            Label("Consumed", systemImage: "fork.knife")
                        }
                        .tint(.green)
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            withAnimation {
                                item.status = .discarded
                                try? modelContext.save()
                            }
                        } label: {
                            Label("Discard", systemImage: "trash")
                        }
                    }
                }
            }
        }
        .navigationTitle(category.rawValue)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: { showingAddOptions = true }) {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 32, height: 32)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                }
            }
        }
        .alert("Add Item", isPresented: $showingAddOptions) {
            Button("Scan / Camera") {
                if DataScannerViewController.isSupported && DataScannerViewController.isAvailable {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        showingScanner = true
                    }
                } else {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        showingScannerError = true
                    }
                }
            }
            Button("Manual Entry") {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showingManualEntry = true
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Choose how you want to add an item.")
        }
        .alert("Scanner Not Available", isPresented: $showingScannerError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("The camera is not available on this device. If you are on the Simulator, please use Manual Entry.")
        }
        .sheet(isPresented: $showingScanner) {
            ScannerView(scannedCode: $scannedCode)
        }
        .sheet(isPresented: $showingManualEntry) {
            AddItemView()
        }
        .sheet(item: $itemToEdit) { item in
            EditItemView(item: item)
        }
        .onChange(of: scannedCode) { oldValue, newValue in
            if let code = newValue {
                showingManualEntry = true
            }
        }
    }
}
    
    private func isExpiringSoon(_ date: Date) -> Bool {
        let days = Calendar.current.dateComponents([.day], from: Date(), to: date).day ?? 0
        return days <= 3
    }
