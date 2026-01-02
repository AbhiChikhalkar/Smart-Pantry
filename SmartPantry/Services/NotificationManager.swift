import Foundation
import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()
    
    private init() {}
    
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if let error = error {
                print("Error requesting notification authorization: \(error)")
            } else if granted {
                print("Notification permission granted")
            } else {
                print("Notification permission denied")
            }
        }
    }
    
    func scheduleNotification(for item: Item) {
        // Identifier based on item ID so we can cancel it later if needed
        let identifier = item.id.uuidString
        
        let content = UNMutableNotificationContent()
        content.title = "Item Expiring Soon"
        content.body = "Your \(item.name) expires tomorrow! Use it in a recipe."
        content.sound = .default
        
        // Schedule for 1 day before expiry
        // If expiry is today or passed, schedule for now (or don't schedule? Let's schedule for 1 min from now for testing if passed, or just ignore)
        // Real logic: 1 day before at 9:00 AM
        
        let calendar = Calendar.current
        guard let reminderDate = calendar.date(byAdding: .day, value: -1, to: item.expiryDate) else { return }
        
        // If reminder date is in the past, don't schedule (or schedule immediately if you want, but better to skip)
        if reminderDate < Date() {
            return
        }
        
        var dateComponents = calendar.dateComponents([.year, .month, .day], from: reminderDate)
        dateComponents.hour = 9 // 9 AM
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            } else {
                print("Scheduled notification for \(item.name) at \(dateComponents)")
            }
        }
    }
    
    func cancelNotification(for item: Item) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [item.id.uuidString])
    }
    
    func scheduleLowStockNotification(for item: Item) {
        let content = UNMutableNotificationContent()
        content.title = "Item Out of Stock"
        content.body = "You just ran out of \(item.name). It's been added to your Shopping List."
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    func scheduleDailyCheckIn(at date: Date) {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
        
        let content = UNMutableNotificationContent()
        content.title = "Did you cook today?"
        content.body = "Keep your inventory fresh! Tap to update what you used."
        content.sound = .default
        
        // Schedule daily at the user's preferred time
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "daily_checkin", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling daily check-in: \(error)")
            } else {
                print("Daily check-in scheduled for \(hour):\(minute)")
            }
        }
    }
}
