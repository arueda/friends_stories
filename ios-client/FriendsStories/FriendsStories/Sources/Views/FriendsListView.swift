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
    @Environment(\.storiesRepository) private var storiesRepository

    var body: some View {
        List(sortedUsers) { user in
            userRow(user)
        }
        .overlay {
            if isLoading && users.isEmpty {
                VStack {
                    ProgressView()
                    Text("Loading Friend's Stories...")
                }
            } else if loadError && users.isEmpty {
                Text("Error loading users. Pull to refresh!")
            }
        }
        .task {
            await refresh()
        }
        .refreshable {
            await refresh()
        }
        .fullScreenCover(item: $selection) { selection in
            StoryViewerView(user: selection.user, startingIndex: selection.startingIndex)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .navigationTitle("My Friend's Stories")
        .navigationBarTitleDisplayMode(.inline)
    }

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
        let sortedStories = user.stories.sorted { $0.createdAt < $1.createdAt }
        return HStack(alignment: .top) {
            // There is no cache mechanism for AsyncImage.
            // Change for a custom implementation
            AsyncImage(url: URL(string: user.avatarURL ?? "")) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Circle().fill(.gray.opacity(0.3))
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
                selection = StorySelection(user: user, startingIndex: 0)
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
                                        selection = StorySelection(user: user, startingIndex: index)
                                    }
                            }
                        }
                    }
                }
            }
        }
    }

    private func storyThumbnail(story: Story) -> some View {
        AsyncImage(url: URL(string: story.imageUrl)) { phase in
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
            Text("\(unseenCount) new")
                .font(.caption)
                .foregroundStyle(Color.accentColor)
        } else {
            Text("\(user.stories.count) stories")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

private struct StorySelection: Identifiable {
    let id = UUID()
    let user: User
    let startingIndex: Int
}
