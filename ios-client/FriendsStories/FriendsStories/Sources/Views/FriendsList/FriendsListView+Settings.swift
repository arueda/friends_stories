//
//  FriendsStories
//

import SwiftUI
import UserNotifications

extension FriendsListView {
    var storySpeedSettings: some View {
        NavigationStack {
            List {
                Section("settings.story_speed") {
                    ForEach(StorySpeed.allCases) { speed in
                        Button {
                            storySpeed = speed.rawValue
                        } label: {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(speed.label)
                                        .foregroundStyle(.primary)
                                    Text("settings.seconds_per_story \(Int(speed.duration))")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                if storySpeed == speed.rawValue {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Color.accentColor)
                                }
                            }
                        }
                    }
                }

                Section("settings.notifications") {
                    Button {
                        handleNotificationAction()
                    } label: {
                        HStack {
                            Text("settings.notifications_toggle")
                                .foregroundStyle(.primary)
                            Spacer()
                            Text(notificationStatusLabel)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Text("settings.notifications_description")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .onAppear { checkNotificationStatus() }

                #if DEBUG
                Section("settings.testing") {
                    Button(role: .destructive) {
                        resetSeenState()
                    } label: {
                        Text("settings.reset_seen")
                    }
                    Text("settings.reset_seen_description")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Button {
                        generateTestStories()
                    } label: {
                        HStack {
                            Text("settings.generate_stories")
                            if isGenerating {
                                Spacer()
                                ProgressView()
                                    .controlSize(.small)
                            }
                        }
                    }
                    .disabled(isGenerating)
                    Text("settings.generate_stories_description")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                #endif
            }
            .navigationTitle(String(localized: "settings.title"))
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: scenePhase) { _, phase in
                if phase == .active {
                    checkNotificationStatus()
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(String(localized: "settings.done")) { showingSettings = false }
                }
            }
        }
        .presentationDetents([.medium])
    }

    var notificationStatusLabel: LocalizedStringResource {
        switch notificationStatus {
        case .authorized, .provisional, .ephemeral: "settings.notifications_on"
        case .denied: "settings.notifications_off"
        default: "settings.notifications_off"
        }
    }

    func checkNotificationStatus() {
        Task {
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            notificationStatus = settings.authorizationStatus
        }
    }

    func handleNotificationAction() {
        Task {
            let center = UNUserNotificationCenter.current()
            let settings = await center.notificationSettings()

            if settings.authorizationStatus == .notDetermined {
                let granted = try? await center.requestAuthorization(options: [.alert, .badge, .sound])
                notificationStatus = granted == true ? .authorized : .denied
            } else {
                guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                await UIApplication.shared.open(url)
            }
        }
    }

    #if DEBUG
    func resetSeenState() {
        for user in users {
            for story in user.stories {
                story.seenAt = nil
            }
        }
    }

    func generateTestStories() {
        let storyCount = 25
        isGenerating = true
        Task {
            defer { isGenerating = false }
            let baseURL = URL(string: "http://localhost:3000/api/stories")!

            for i in 1...storyCount {
                let userId = Int.random(in: 1...4)
                let seed = "test\(Int.random(in: 1...9999))"
                let body: [String: Any] = [
                    "user_id": userId,
                    "image_url": "https://picsum.photos/seed/\(seed)/400/700",
                    "caption": "Test story \(i)"
                ]

                var request = URLRequest(url: baseURL)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.httpBody = try? JSONSerialization.data(withJSONObject: body)

                _ = try? await URLSession.shared.data(for: request)
            }

            await refresh()
        }
    }
    #endif
}
