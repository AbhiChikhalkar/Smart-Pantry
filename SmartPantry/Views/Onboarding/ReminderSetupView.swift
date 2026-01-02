import SwiftUI

struct ReminderSetupView: View {
    @Binding var isCompleted: Bool
    @State private var reminderTime = Date()
    @State private var animateIn = false
    
    // Set default time to 8:00 PM if needed, or use current
    init(isCompleted: Binding<Bool>) {
        self._isCompleted = isCompleted
        // Set default to 8:00 PM
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.hour = 20
        components.minute = 0
        self._reminderTime = State(initialValue: Calendar.current.date(from: components) ?? Date())
    }
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            VStack(spacing: 16) {
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.blue)
                    .background(
                        Circle()
                            .fill(Color.blue.opacity(0.1))
                            .frame(width: 120, height: 120)
                    )
                    .padding(.bottom, 20)
                    .scaleEffect(animateIn ? 1.0 : 0.8)
                    .animation(.spring(bounce: 0.5), value: animateIn)
                
                Text("Make it a Habit")
                    .font(.largeTitle)
                    .bold()
                
                Text("When do you usually finish cooking?")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
                
                Text("We'll remind you to update your pantry so you never forget what you've used.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            DatePicker("Reminder Time", selection: $reminderTime, displayedComponents: .hourAndMinute)
                .datePickerStyle(.wheel)
                .labelsHidden()
                .padding()
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .cornerRadius(16)
                .padding(.horizontal)
            
            Spacer()
            
            VStack(spacing: 16) {
                Button(action: saveReminder) {
                    Text("Set Reminder")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                
                Button(action: skipReminder) {
                    Text("Maybe Later")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .onAppear {
            animateIn = true
            // Pre-request permissions if not already done
            NotificationManager.shared.requestAuthorization()
        }
    }
    
    private func saveReminder() {
        NotificationManager.shared.scheduleDailyCheckIn(at: reminderTime)
        completeOnboarding()
    }
    
    private func skipReminder() {
        completeOnboarding()
    }
    
    private func completeOnboarding() {
        withAnimation {
            isCompleted = true
        }
    }
}
