//
//  FriendsStories
//

import SwiftUI
import SwiftData

struct FriendsListView: View {
    @Query(sort: \User.username) private var users: [User]
    private var sortedUsers: [User] {
        users.sorted { lhs, rhs in
            let lhsUnseen = lhs.stories.contains { !$0.isSeen }
            let rhsUnseen = rhs.stories.contains { !$0.isSeen }
            if lhsUnseen != rhsUnseen { return lhsUnseen }
            return lhs.username < rhs.username
        }
    }
    @State private var selection: StorySelection?
    @State private var isLoading = true
    @State private var loadError = false
    @State private var showingSettings = false
    @AppStorage("storySpeed") private var storySpeed: String = StorySpeed.normal.rawValue
    @Environment(\.modelContext) private var modelContext
    @Environment(\.storiesRepository) private var storiesRepository

    var body: some View {
        List(sortedUsers) { user in
            userRow(user)
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
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
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
                }
                #endif
            }
            .navigationTitle(String(localized: "settings.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(String(localized: "settings.done")) { showingSettings = false }
                }
            }
        }
        .presentationDetents([.medium])
    }

    #if DEBUG
    private func resetSeenState() {
        for user in users {
            for story in user.stories {
                story.seenAt = nil
            }
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
        let sortedStories = user.stories.sorted { $0.createdAt < $1.createdAt }
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
        .frame(width: 56, height: 80)
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
