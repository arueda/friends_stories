//
//  FriendsStories
//

import SwiftUI
import SwiftData

struct FriendsListView: View {
    private enum ViewState {
        case loading
        case loaded
        case error
    }

    @Query(sort: \User.username) private var users: [User]
    @State private var viewState: ViewState = .loading
    @State private var selectedUser: User?
    @Environment(\.storiesRepository) private var storiesRepository

    var body: some View {
        switch viewState {
            case .loading:
            VStack {
                ProgressView()
                Text("Loading Friend's Stories...")
            }
            .task {
                do {
                    try await storiesRepository?.refreshStories()
                    viewState = .loaded
                } catch {
                    viewState = .error
                }
            }
        case .loaded:
            List(users) { user in
                Button {
                    selectedUser = user
                } label: {
                    userRow(user)
                }
            }
            .fullScreenCover(item: $selectedUser) { user in
                StoryViewerView(user: user)
            }
            .refreshable {
                viewState = .loading
            }
        case .error:
            Text("Error loading users. Pull to refresh!")
                .refreshable {
                    viewState = .loading
                }
        }
    }

    private func userRow(_ user: User) -> some View {
        HStack {
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

            VStack(alignment: .leading) {
                Text(user.username)
                    .font(.headline)
                subtitleView(for: user)
            }
        }
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
