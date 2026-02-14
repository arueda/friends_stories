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

                        VStack(alignment: .leading) {
                            Text(user.username)
                                .font(.headline)
                            Text("\(user.stories.count) stories")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
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
}
