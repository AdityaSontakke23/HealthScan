//
//  NotificationManager.swift
//  HealthScan
//
//  Schedules a daily heart rate measurement reminder notification.
//

import Foundation
import UserNotifications

@MainActor
final class NotificationManager: Sendable {
    static let shared = NotificationManager()
    private let center = UNUserNotificationCenter.current()
    static let reminderIdentifier = "com.healthscan.daily-reminder"
    
    func requestAuthorization() async -> Bool {
        do {
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }
    
    /// Schedule a daily reminder at the specified hour and minute (24h).
    func scheduleDailyReminder(hour: Int, minute: Int) async {
        center.removePendingNotificationRequests(withIdentifiers: [Self.reminderIdentifier])
        
        let content = UNMutableNotificationContent()
        content.title = "Time for your daily heart check"
        content.body = "Tap to measure your heart rate and HRV."
        content.sound = .default
        
        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(
            identifier: Self.reminderIdentifier,
            content: content,
            trigger: trigger
        )
        
        do {
            try await center.add(request)
        } catch {
            print("Failed to schedule notification: \(error)")
        }
    }
    
    func cancelReminder() {
        center.removePendingNotificationRequests(withIdentifiers: [Self.reminderIdentifier])
    }
}
