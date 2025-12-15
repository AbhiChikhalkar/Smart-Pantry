import SwiftUI
import SwiftData
import Charts

struct InsightsView: View {
    @Query private var items: [Item]
    @State private var timeRange: TimeRange = .monthly
    @State private var currentDate = Date()
    
    enum TimeRange: String, CaseIterable {
        case daily = "Daily"
        case weekly = "Weekly"
        case monthly = "Monthly"
        case yearly = "Yearly"
        // case allTime = "All Time" // Simplifies logic to stick to date-based for now
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 1. Date Navigator (Top Center with Arrows)
                HStack {
                    Button(action: moveDateBackward) {
                        Image(systemName: "arrow.left.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Text(dateLabel)
                        .font(.headline)
                        .bold()
                    
                    Spacer()
                    
                    Button(action: moveDateForward) {
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    }
                    .disabled(isFutureDate)
                }
                .padding()
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .cornerRadius(16)
                .padding(.horizontal)
                
                // 2. Dynamic Insight Banner (Highlight)
                if topConsumedItem != nil {
                     VStack(alignment: .leading, spacing: 12) {
                        Text(insightHeadline)
                            .font(.headline)
                            .foregroundStyle(.white)
                        
                        Text(insightSubheadline)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.8))
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(LinearGradient(colors: [.black.opacity(0.8), .gray.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .cornerRadius(16)
                    .padding(.horizontal)
                }
                
                // 3. Summary Cards (Waste Rate & Consumed)
                HStack(spacing: 16) {
                    InsightSummaryCard(
                        title: "Waste Rate",
                        value: wasteRateString,
                        icon: "trash.fill",
                        color: .red
                    )
                    
                    InsightSummaryCard(
                        title: "Items Consumed", // Replaces "Total Saved"
                        value: "\(consumedCount)",
                        icon: "fork.knife.circle.fill", // Changed icon to represent eating
                        color: .green
                    )
                }
                .padding(.horizontal)
                
                // 4. Most Consumed List
                if !mostConsumedItems.isEmpty {
                    VStack(alignment: .leading) {
                        Text("Most Consumed Items")
                            .font(.headline)
                            .padding(.bottom, 8)
                        
                        ForEach(mostConsumedItems, id: \.name) { item in
                            HStack {
                                Image(systemName: "fork.knife.circle.fill")
                                    .foregroundStyle(.blue)
                                Text(item.name)
                                Spacer()
                                Text("\(item.count) times")
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 8)
                            Divider()
                        }
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .cornerRadius(16)
                    .padding(.horizontal)
                }
                
                // 5. Daily Trash (Most Wasted)
                if !mostWastedItems.isEmpty {
                    VStack(alignment: .leading) {
                        Text("Daily Trash (Most Wasted)")
                            .font(.headline)
                            .foregroundStyle(.red)
                            .padding(.bottom, 8)
                        
                        ForEach(mostWastedItems, id: \.name) { item in
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.orange)
                                Text(item.name)
                                Spacer()
                                Text("\(item.count) times")
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 8)
                            Divider()
                        }
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .cornerRadius(16)
                    .padding(.horizontal)
                } else if filteredItems.isEmpty {
                     Text("No activity for this period.")
                        .foregroundStyle(.secondary)
                        .padding(.top)
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Insights")
        .background(Color(UIColor.systemGroupedBackground))
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    ForEach(TimeRange.allCases, id: \.self) { range in
                        Button(action: { timeRange = range }) {
                            if timeRange == range {
                                Label(range.rawValue, systemImage: "checkmark")
                            } else {
                                Text(range.rawValue)
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(timeRange.rawValue)
                        Image(systemName: "chevron.down")
                    }
                    .font(.subheadline)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .clipShape(Capsule())
                }
            }
        }
    }
    
    // MARK: - Date Logic
    
    private func moveDateBackward() {
        withAnimation {
            currentDate = Calendar.current.date(byAdding: dateComponentForRange, value: -1, to: currentDate) ?? currentDate
        }
    }
    
    private func moveDateForward() {
        withAnimation {
            currentDate = Calendar.current.date(byAdding: dateComponentForRange, value: 1, to: currentDate) ?? currentDate
        }
    }
    
    private var dateComponentForRange: Calendar.Component {
        switch timeRange {
        case .daily: return .day
        case .weekly: return .weekOfYear
        case .monthly: return .month
        case .yearly: return .year
        }
    }
    
    private var isFutureDate: Bool {
        // Simple check if moving forward would exceed today (loosely)
        // For monthly, check if current month is >= current actual month
        return currentDate >= Date()
    }
    
    private var dateLabel: String {
        let formatter = DateFormatter()
        switch timeRange {
        case .daily:
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            if Calendar.current.isDateInToday(currentDate) { return "Today" }
        case .weekly:
            // Show "Dec 10 - Dec 17"
            let start = Calendar.current.dateInterval(of: .weekOfYear, for: currentDate)?.start ?? currentDate
            let end = Calendar.current.date(byAdding: .day, value: 6, to: start) ?? currentDate
            formatter.dateFormat = "MMM d"
            return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
        case .monthly:
            formatter.dateFormat = "MMMM yyyy"
        case .yearly:
            formatter.dateFormat = "yyyy"
        }
        return formatter.string(from: currentDate)
    }
    
    // MARK: - Computed Data
    
    // Filter items based on the selected date range.
    // Using `addedDate` as proxy for "activity happened" since we don't store `consumedDate`.
    var filteredItems: [Item] {
        items.filter { item in
            let itemDate = item.addedDate // Limitation: Uses addedDate. Ideally needs statusChangeDate.
            return Calendar.current.isDate(itemDate, equalTo: currentDate, toGranularity: dateComponentForRange)
        }
    }
    
    var consumedCount: Int { filteredItems.filter { $0.status == .consumed }.count }
    var discardedCount: Int { filteredItems.filter { $0.status == .discarded }.count }
    var totalProcessed: Int { consumedCount + discardedCount }
    
    var wasteRateString: String {
        guard totalProcessed > 0 else { return "0%" }
        let rate = (Double(discardedCount) / Double(totalProcessed)) * 100
        return String(format: "%.1f%%", rate)
    }
    
    var topConsumedItem: (name: String, count: Int)? {
        mostConsumedItems.first
    }
    
    var insightHeadline: String {
        if let top = topConsumedItem {
            return "You love \(top.name)!"
        }
        return "Start tracking to see insights."
    }
    
    var insightSubheadline: String {
        if let top = topConsumedItem {
            return "You've consumed it \(top.count) times this \(timeRange.rawValue.lowercased().dropLast(2)) period."
        }
        return "Mark items as consumed or wasted."
    }
    
    var mostConsumedItems: [(name: String, count: Int)] {
        getTopItems(status: .consumed)
    }
    
    var mostWastedItems: [(name: String, count: Int)] {
        getTopItems(status: .discarded)
    }
    
    func getTopItems(status: ItemStatus) -> [(name: String, count: Int)] {
        let filtered = filteredItems.filter { $0.status == status }
        let grouped = Dictionary(grouping: filtered, by: { $0.name })
        let sorted = grouped.map { (name: $0.key, count: $0.value.count) }
            .sorted { $0.count > $1.count }
        return Array(sorted.prefix(3))
    }
}

struct InsightSummaryCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .center, spacing: 12) { // Centered alignment
            Text(title)
                .font(.subheadline) // Smaller title at top
                .foregroundStyle(.secondary)
            
            Text(value)
                .font(.system(size: 24, weight: .bold)) // Large value
                .foregroundStyle(.primary)
            
            if !value.contains("da") { // Hacky check for 'No data'
                 Text("No data available")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .opacity(value == "0%" || value == "0" ? 1 : 0)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }
}
