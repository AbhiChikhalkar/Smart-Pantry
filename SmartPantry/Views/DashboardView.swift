import SwiftUI
import SwiftData
import VisionKit

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Item]
    @Binding var selectedTab: Int
    
    // Add Item Sheets State
    @State private var showingAddOptions = false
    @State private var showingScanner = false
    @State private var showingManualEntry = false
    @State private var showingScannerError = false
    @State private var scannedCode: String?
    
    // Greeting based on time of day
    var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "Good Morning"
        case 12..<17: return "Good Afternoon"
        default: return "Good Evening"
    }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Hero Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text(greeting)
                            .font(.largeTitle)
                            .bold()
                            .foregroundStyle(.primary)
                        
                        Text("You have \(expiringSoonCount) items expiring soon.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.top)
                    
                    // Horizontal Scroll Cards
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            // 1. Due Today Card
                            DashboardCard(
                                title: "Due Today",
                                count: dueTodayCount,
                                icon: "calendar.badge.exclamationmark",
                                color: .red
                            ) {
                                // Filter action
                            }
                            
                            // 2. Upcoming Card
                            DashboardCard(
                                title: "Upcoming",
                                count: upcomingCount,
                                icon: "clock.fill",
                                color: .orange
                            ) {
                                // Filter action
                            }
                            
                            // 3. Smart Recipes Card
                            Button(action: {
                                selectedTab = 2 // Recipes Tab
                            }) {
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                        Image(systemName: "sparkles")
                                            .font(.title2)
                                            .foregroundStyle(.yellow)
                                            .padding(8)
                                            .background(Color.yellow.opacity(0.1))
                                            .clipShape(Circle())
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Text("Find Recipes")
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                    Text("Based on what you have")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .padding()
                                .frame(width: 160, height: 140)
                                .background(Color(UIColor.secondarySystemGroupedBackground))
                                .cornerRadius(20)
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Insights Link Banner
                    NavigationLink(destination: InsightsView()) {
                        HStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Pantry Insights")
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                Text("Check your waste & consumption stats")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chart.pie.fill")
                                .font(.title)
                                .foregroundStyle(.blue)
                        }
                        .padding()
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .cornerRadius(16)
                        .padding(.horizontal)
                    }
                    
                    // Quick Shortcuts (Replacing Storage)
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Quick Access")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                            QuickAccessButton(title: "Fridge", icon: "refrigerator", color: .blue) {
                                selectedTab = 1
                            }
                            
                            QuickAccessButton(title: "Pantry", icon: "cabinet", color: .brown) {
                                selectedTab = 1
                            }
                            
                            QuickAccessButton(title: "Shopping List", icon: "cart", color: .green) {
                                selectedTab = 3
                            }
                            
                            QuickAccessButton(title: "Add Item", icon: "plus", color: .purple) {
                                showingAddOptions = true
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.bottom, 20)
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("StockUpPantry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Toolbar items can be added here if needed in the future
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
            .onChange(of: scannedCode) { _, newValue in
                if newValue != nil {
                    showingManualEntry = true
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    var availableItems: [Item] { items.filter { $0.status == .available } }
    
    var dueTodayCount: Int {
        availableItems.filter { Calendar.current.isDateInToday($0.expiryDate) }.count
    }
    
    var upcomingCount: Int {
        let today = Date()
        let nextWeek = Calendar.current.date(byAdding: .day, value: 7, to: today)!
        return availableItems.filter {
            !Calendar.current.isDateInToday($0.expiryDate) &&
            $0.expiryDate > today &&
            $0.expiryDate <= nextWeek
        }.count
    }
    
    var expiringSoonCount: Int {
        dueTodayCount + upcomingCount
    }
}

struct DashboardCard: View {
    let title: String
    let count: Int
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundStyle(color)
                        .padding(8)
                        .background(color.opacity(0.1))
                        .clipShape(Circle())
                    Spacer()
                    Text("\(count)")
                        .font(.title)
                        .bold()
                        .foregroundStyle(Color(UIColor.label))
                }
                
                Spacer()
                
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)
            }
            .padding()
            .frame(width: 160, height: 140)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(20)
        }
    }
}

struct QuickAccessButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                Spacer()
            }
            .padding()
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(12)
        }
    }
}
