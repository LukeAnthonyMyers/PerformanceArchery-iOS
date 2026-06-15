//
//  NotificationService.swift
//  Performance Archery
//
//  Created by Luke Myers on 14/02/2026.
//

import Foundation
import UserNotifications

class NotificationService {
    static let shared = NotificationService()
    
    static func scheduleReminder(for date: Date, competition: Competition) {
        let content = UNMutableNotificationContent()
        content.title = "Entries Now Open!"
        content.body = "Entries for \(competition.name) are now open."
        content.sound = .default

        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let request = UNNotificationRequest(
            identifier: "entry_reminder_\(competition.id)",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }
    
    static func cancelReminder(for competition: Competition) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["entry_reminder_\(competition.id)"])
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: ["entry_reminder_\(competition.id)"])
    }
    
    static func requestPermission(completion: @escaping (Bool) -> Void = { _ in }) {
        let center = UNUserNotificationCenter.current()
        
        center.getNotificationSettings { settings in
            guard settings.authorizationStatus == .notDetermined else {
                completion(settings.authorizationStatus == .authorized)
                return
            }
            
            center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                if let error = error {
                    print("Error requesting notification permission: \(error.localizedDescription)")
                }
                DispatchQueue.main.async {
                    completion(granted)
                }
            }
        }
    }
}
