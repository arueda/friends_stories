//
//  FriendsStories
//

import SwiftUI
import SwiftData
import UserNotifications

struct FriendsListView: View {
    @AppStorage("storySpeed") private var storySpeed: String = StorySpeed.normal.rawValue
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.storiesRepository) private var storiesRepository
    @Environment(NotificationHandler.self) private var notificationHandler
    
    @State private var selection: StorySelection?
    @State private var isLoading = true
    @State private var loadError = false
    @State private var showingSettings = false
    @State private var notificationStatus: UNAuthorizationStatus = .notDetermined
    @State private var isGenerating = false
    
    @Query(sort: \User.username) private var users: [User]
    private var sortedUsers: [User] {
        users.sorted { lhs, rhs in
            let lhsUnseen = lhs.stories.contains { !$0.isSeen }
            let rhsUnseen = rhs.stories.contains { !$0.isSeen }
            if lhsUnseen != rhsUnseen { return lhsUnseen }
            return lhs.username < rhs.username
        }
    }
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
    ]

    var body: some View {
        let sorted = sortedUsers
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(Array(sorted.enumerated()), id: \.element.id) {
                    userIndex,
                    user in
                    let sortedStories = user.stories.sorted {
                        if $0.isSeen != $1.isSeen { return !$0.isSeen }
                        return $0.createdAt < $1.createdAt
                    }
                    
                    // Avatar + username header
                    HStack(spacing: 8) {
                        CachedAsyncImage(url: URL(string: user.avatarURL ?? "")) { phase in
                            switch phase {
                            case .success(let image):
                                image.resizable().scaledToFill()
                            default:
                                Circle().fill(.gray.opacity(0.3))
                            }
                        }
                        .frame(width: 44, height: 44)
                        .clipShape(Circle())
                        .overlay {
                            if user.stories.contains(where: { !$0.isSeen }) {
                                Circle()
                                    .strokeBorder(Color.accentColor, lineWidth: 2)
                                    .frame(width: 50, height: 50)
                            }
                        }
                        
                        Text(user.username)
                            .font(.headline)
                        Spacer()
                        subtitleView(for: user)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selection = StorySelection(
                            users: sorted,
                            startingUserIndex: userIndex,
                            startingStoryIndex: 0
                        )
                    }

                    // Story thumbnails grid
                    LazyVGrid(columns: columns, spacing: 4) {
                        ForEach(Array(sortedStories.enumerated()), id: \.element.id) { index, story in
                            storyThumbnail(story: story)
                                .onTapGesture {
                                    selection = StorySelection(
                                        users: sorted,
                                        startingUserIndex: userIndex,
                                        startingStoryIndex: index
                                    )
                                }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 12)
                }
            }
        }
        .task {
            await refresh()
        }
        .refreshable {
            await refresh()
        }
        .fullScreenCover(item: $selection) { selection in
            StoryViewerView(
                users: selection.users,
                startingUserIndex: selection.startingUserIndex,
                startingStoryIndex: selection.startingStoryIndex
            )
        }
        .navigationTitle(String(localized: "friends.title"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button { showingSettings = true } label: {
                    Image(systemName: "gearshape")
                }
            }
        }
        .sheet(isPresented: $showingSettings) {
            storySpeedSettings
        }
        .onChange(of: notificationHandler.pendingUserId) { _, userId in
            guard let userId else { return }
            let sorted = sortedUsers
            guard let userIndex = sorted.firstIndex(where: { $0.id == userId }) else { return }
            selection = StorySelection(users: sorted, startingUserIndex: userIndex, startingStoryIndex: 0)
            notificationHandler.clearPending()
        }
        .overlay {
            if isLoading && users.isEmpty {
                VStack {
                    ProgressView()
                    Text("friends.loading")
                }
            } else if loadError && users.isEmpty {
                Text("friends.error")
            }
        }
    }

    private var storySpeedSettings: some View {
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

    private var notificationStatusLabel: LocalizedStringResource {
        switch notificationStatus {
        case .authorized, .provisional, .ephemeral: "settings.notifications_on"
        case .denied: "settings.notifications_off"
        default: "settings.notifications_off"
        }
    }

    private func checkNotificationStatus() {
        Task {
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            notificationStatus = settings.authorizationStatus
        }
    }

    private func handleNotificationAction() {
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
    private func resetSeenState() {
        for user in users {
            for story in user.stories {
                story.seenAt = nil
            }
        }
    }

    private func generateTestStories() {
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

    private func refresh() async {
        isLoading = true
        loadError = false
        do {
            try await storiesRepository?.refreshStories()
        } catch {
            loadError = true
        }
        isLoading = false
    }

    private func userRow(_ user: User) -> some View {
        let sorted = sortedUsers
        let userIndex = sorted.firstIndex(where: { $0.id == user.id }) ?? 0
        let sortedStories = user.stories.sorted {
            if $0.isSeen != $1.isSeen { return !$0.isSeen }
            return $0.createdAt < $1.createdAt
        }
        return HStack(alignment: .top) {
            CachedAsyncImage(url: URL(string: user.avatarURL ?? "")) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFill()
                default:
                    Circle().fill(.gray.opacity(0.3))
                }
            }
            .frame(width: 44, height: 44)
            .clipShape(Circle())
            .overlay {
                if user.stories.contains(where: { !$0.isSeen }) {
                    Circle()
                        .strokeBorder(Color.accentColor, lineWidth: 2)
                        .frame(width: 50, height: 50)
                }
            }
            .onTapGesture {
                selection = StorySelection(users: sorted, startingUserIndex: userIndex, startingStoryIndex: 0)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(user.username)
                    .font(.headline)
                subtitleView(for: user)

                if !sortedStories.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(Array(sortedStories.enumerated()), id: \.element.id) { index, story in
                                storyThumbnail(story: story)
                                    .onTapGesture {
                                        selection = StorySelection(users: sorted, startingUserIndex: userIndex, startingStoryIndex: index)
                                    }
                            }
                        }
                    }
                }
            }
        }
    }

    private func storyThumbnail(story: Story) -> some View {
        CachedAsyncImage(url: URL(string: story.imageUrl)) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .scaledToFill()
            case .failure:
                Image(systemName: "photo")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            default:
                ProgressView()
                    .controlSize(.mini)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .aspectRatio(4/7, contentMode: .fill)
        .clipped()
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .opacity(story.isSeen ? 0.5 : 1.0)
    }

    @ViewBuilder
    private func subtitleView(for user: User) -> some View {
        let unseenCount = user.stories.filter { !$0.isSeen }.count
        if unseenCount > 0 {
            Text("friends.new_count \(unseenCount)")
                .font(.caption)
                .foregroundStyle(Color.accentColor)
        } else {
            Text("friends.story_count \(user.stories.count)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

private struct StorySelection: Identifiable {
    let id = UUID()
    let users: [User]
    let startingUserIndex: Int
    let startingStoryIndex: Int
}
