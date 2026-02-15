//
//  FriendsStories
//

import Foundation
import UserNotifications

@MainActor
@Observable
final class NotificationHandler: NSObject, UNUserNotificationCenterDelegate {
    var pendingUserId: Int64?

    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }

    // Called when the user taps a notification
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        let userId = userInfo["userId"] as? Int64
            ?? (userInfo["userId"] as? NSNumber)?.int64Value

        DispatchQueue.main.async {
            self.pendingUserId = userId
            completionHandler()
        }
    }

    // Called when a notification arrives while the app is in foreground
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }

    func clearPending() {
        pendingUserId = nil
    }
}
