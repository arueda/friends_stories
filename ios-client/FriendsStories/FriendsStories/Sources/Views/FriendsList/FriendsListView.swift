//
//  FriendsStories
//

import SwiftUI
import SwiftData
import UserNotifications

enum FeedTab: String, CaseIterable, Identifiable {
    case friends, newest, favorites
    var id: String { rawValue }
}

struct FriendsListView: View {
    @AppStorage("storySpeed") var storySpeed: String = StorySpeed.normal.rawValue

    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) var scenePhase
    @Environment(\.storiesRepository) private var storiesRepository
    @Environment(NotificationHandler.self) private var notificationHandler

    @State var selection: StorySelection?
    @State var showingSettings = false
    @State var isGenerating = false
    @State var notificationStatus: UNAuthorizationStatus = .notDetermined
    
    @State private var isLoading = true
    @State private var loadError = false
    @State private var selectedTab: FeedTab = .friends

    @Query(sort: \User.username) var users: [User]
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
        VStack(spacing: 0) {
            Picker("Tab", selection: $selectedTab) {
                Text("Friends").tag(FeedTab.friends)
                Text("Newest").tag(FeedTab.newest)
                Text("Favorites").tag(FeedTab.favorites)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.vertical, 8)

            switch selectedTab {
            case .friends:
                friendsTab(sorted: sorted)
            case .newest:
                newestTab(sorted: sorted)
            case .favorites:
                favoritesTab(sorted: sorted)
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
                startingStoryIndex: selection.startingStoryIndex,
                storyFilter: selection.storyFilter,
                orderedStories: selection.orderedStories
            )
        }
        .navigationTitle(String(localized: "friends.title"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button { showingSettings = true } label: {
                    Image(systemName: "gear").resizable()
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

    func refresh() async {
        isLoading = true
        loadError = false
        do {
            try await storiesRepository?.refreshStories()
        } catch {
            loadError = true
        }
        isLoading = false
    }
}

struct StorySelection: Identifiable {
    let id = UUID()
    let users: [User]
    let startingUserIndex: Int
    let startingStoryIndex: Int
    let storyFilter: ((Story) -> Bool)?
    let orderedStories: [(user: User, story: Story)]?

    init(users: [User], startingUserIndex: Int, startingStoryIndex: Int, storyFilter: ((Story) -> Bool)? = nil, orderedStories: [(user: User, story: Story)]? = nil) {
        self.users = users
        self.startingUserIndex = startingUserIndex
        self.startingStoryIndex = startingStoryIndex
        self.storyFilter = storyFilter
        self.orderedStories = orderedStories
    }
}
