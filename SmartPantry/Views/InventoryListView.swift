import SwiftUI
import SwiftData
import VisionKit

struct InventoryListView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var authManager: AuthManager
    @State private var searchText = ""
    @State private var showingAddOptions = false
    @State private var showingScanner = false
    @State private var showingManualEntry = false
    @State private var showingScannerError = false
    @State private var scannedCode: String?
    @State private var itemToEdit: Item?
    
    // Wrapper view to handle search filtering and combined list
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // Fridge Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Fridge")
                        .font(.title2)
                        .bold()
                        .padding(.horizontal)
                    
                    InventorySection(category: .fridge, searchText: searchText, itemToEdit: $itemToEdit)
                }
                
                Divider()
                    .padding(.horizontal)
                
                // Pantry Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Pantry")
                        .font(.title2)
                        .bold()
                        .padding(.horizontal)
                    
                    InventorySection(category: .pantry, searchText: searchText, itemToEdit: $itemToEdit)
                }
            }
            .padding(.top)
            .padding(.bottom, 80) // Space for content
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle("Inventory")
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: { showingAddOptions = true }) {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 32, height: 32)
                        .background(Color.blue)
                        .clipShape(Circle())
                }
            }
        }
        .alert("Add Item", isPresented: $showingAddOptions) {
            Button("Scan / Camera") {
                if DataScannerViewController.isSupported && DataScannerViewController.isAvailable {
                    scannedCode = nil // Reset previous scan
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
                scannedCode = nil // Ensure fresh form
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
            AddItemView(barcode: scannedCode)
        }
        .sheet(item: $itemToEdit) { item in
            EditItemView(item: item)
        }
        .onChange(of: scannedCode) { _, newValue in
            if newValue != nil {
                showingManualEntry = true
            }
        }
    }
}

struct InventorySection: View {
    @Query private var items: [Item]
    @Binding var itemToEdit: Item?
    let category: Category
    
    init(category: Category, searchText: String, itemToEdit: Binding<Item?>) {
        self.category = category
        self._itemToEdit = itemToEdit
        
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
        LazyVStack(spacing: 12) {
            if items.isEmpty {
                ContentUnavailableView(
                    "No Items",
                    systemImage: category == .fridge ? "refrigerator" : "cabinet",
                    description: Text("Tap + to add.")
                )
                .frame(height: 150)
                .padding(.top, 40)
            } else {
                ForEach(items) { item in
                    ItemCard(item: item) {
                        itemToEdit = item
                    }
                    .padding(.horizontal)
                    .swipeActions(edge: .leading, allowsFullSwipe: true) {
                        Button {
                            withAnimation {
                                item.status = .consumed
                            }
                        } label: {
                            Label("Consumed", systemImage: "fork.knife")
                        }
                        .tint(.green)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            withAnimation {
                                item.status = .discarded
                            }
                        } label: {
                            Label("Discard", systemImage: "trash")
                        }
                    }
                    .contextMenu {
                        Button(role: .destructive) {
                            withAnimation {
                                item.status = .discarded
                            }
                        } label: {
                            Label("Discard", systemImage: "trash")
                        }
                        
                        Button {
                            withAnimation {
                                item.status = .consumed
                            }
                        } label: {
                            Label("Consumed", systemImage: "fork.knife")
                        }
                    }
                }
            }
        }
        .padding(.top)
    }
}

struct ItemCard: View {
    let item: Item
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Image or Icon
                if let imageURL = item.imageURL {
                    AsyncImage(url: imageURL) { image in
                        image.resizable().scaledToFit()
                    } placeholder: {
                        Image(systemName: "photo")
                            .foregroundStyle(.gray)
                    }
                    .frame(width: 50, height: 50)
                    .background(Color.gray.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    Image(systemName: "cube.box.fill")
                        .font(.title)
                        .foregroundStyle(.blue)
                        .frame(width: 50, height: 50)
                        .background(Color.blue.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    if let brand = item.brand {
                        Text(brand)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Text(item.quantity)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                // Expiry Badge
                VStack(alignment: .trailing) {
                    let days = Calendar.current.dateComponents([.day], from: Date(), to: item.expiryDate).day ?? 0
                    
                    Text(days < 0 ? "Expired" : (days == 0 ? "Today" : "\(days)d left"))
                        .font(.caption)
                        .bold()
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(days < 3 ? Color.red.opacity(0.1) : Color.green.opacity(0.1))
                        .foregroundStyle(days < 3 ? .red : .green)
                        .clipShape(Capsule())
                }
            }
            .padding()
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(16)
        }
    }
}
