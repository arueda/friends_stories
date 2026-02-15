//
//  FriendsStories
//

import SwiftUI

extension FriendsListView {
    func storyThumbnail(story: Story) -> some View {
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
    func subtitleView(for user: User) -> some View {
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
