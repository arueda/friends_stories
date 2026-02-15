//
//  FriendsStories
//

import SwiftUI

extension FriendsListView {
    func friendsTab(sorted: [User]) -> some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(Array(sorted.enumerated()), id: \.element.id) {
                    userIndex,
                    user in
                    let sortedStories = user.stories.sorted {
                        $0.createdAt < $1.createdAt
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
                        selectStory(nil, ofUser: user, in: sorted)
                    }

                    // Story thumbnails grid
                    LazyVGrid(columns: columns, spacing: 4) {
                        ForEach(Array(sortedStories.enumerated()), id: \.element.id) { index, story in
                            storyThumbnail(story: story)
                                .onTapGesture {
                                    selectStory(story, ofUser: user, in: sorted)
                                }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 12)
                }
            }
        }
    }

    func newestTab(sorted: [User]) -> some View {
        let allStories = sorted.flatMap { user in
            user.stories.map { (user: user, story: $0) }
        }.sorted { $0.story.createdAt > $1.story.createdAt }

        return ScrollView {
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(allStories, id: \.story.id) { pair in
                    storyThumbnail(story: pair.story)
                        .onTapGesture {
                            selectStoryInOrder(pair.story, from: allStories)
                        }
                }
            }
            .padding(.horizontal)
        }
    }

    func favoritesTab(sorted: [User]) -> some View {
        let likedStories = sorted.flatMap { user in
            user.stories.filter { $0.isLiked ?? false }.map { (user: user, story: $0) }
        }.sorted { $0.story.createdAt > $1.story.createdAt }

        return ScrollView {
            if likedStories.isEmpty {
                ContentUnavailableView(
                    String(localized: "friends.title"),
                    systemImage: "heart"
                )
                    .padding(.top, 60)
            } else {
                LazyVGrid(columns: columns, spacing: 4) {
                    ForEach(likedStories, id: \.story.id) { pair in
                        storyThumbnail(story: pair.story)
                            .onTapGesture {
                                selectStory(pair.story, ofUser: pair.user, in: sorted, storyFilter: { $0.isLiked == true })
                            }
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    func selectStoryInOrder(_ story: Story, from orderedStories: [(user: User, story: Story)]) {
        guard let index = orderedStories.firstIndex(where: { $0.story.id == story.id }) else { return }
        selection = StorySelection(
            users: [],
            startingUserIndex: index,
            startingStoryIndex: 0,
            orderedStories: orderedStories
        )
    }

    func selectStory(_ story: Story?, ofUser user: User, in sorted: [User], storyFilter: ((Story) -> Bool)? = nil) {
        guard let userIndex = sorted.firstIndex(where: { $0.id == user.id }) else { return }
        var sortedStories = user.stories.sorted { $0.createdAt < $1.createdAt }
        if let storyFilter {
            sortedStories = sortedStories.filter(storyFilter)
        }
        let storyIndex: Int
        if let story {
            storyIndex = sortedStories.firstIndex(where: { $0.id == story.id }) ?? 0
        } else {
            storyIndex = 0
        }
        selection = StorySelection(
            users: sorted,
            startingUserIndex: userIndex,
            startingStoryIndex: storyIndex,
            storyFilter: storyFilter
        )
    }
}
