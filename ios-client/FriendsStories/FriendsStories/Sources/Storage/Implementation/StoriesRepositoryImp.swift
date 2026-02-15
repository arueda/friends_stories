//
//  FriendsStories
//

import Foundation
import SwiftData

class StoriesRepositoryImpl: StoriesRepository {
    private var api: FriendsStoriesAPI
    private var modelContainer: ModelContainer
    // NOTE: This is a very basic pagination.
    // The backend returns stories sorted by date.
    // if new stories get inserted into the database, we might skip them if we are already in page N
    private var lastPage: Int = 0 // first time we get the first page
    
    init(api: FriendsStoriesAPI, modelContainer: ModelContainer) {
        self.api = api
        self.modelContainer = modelContainer
    }
    
    @MainActor
    func refreshStories() async throws {
        let context = modelContainer.mainContext
        let limit = 10
        let response = try await api.getStories(page: lastPage, limit: limit)
        if response.hasMore {
            lastPage = response.page + 1
        }
        try upsert(response.data, in: context)
        try context.save()
    }

    @MainActor
    private func upsert(_ groups: [UserResponse], in context: ModelContext) throws {
        for group in groups {
            let userDTO = group.user
            let userId = userDTO.id

            // Upsert user
            let userDescriptor = FetchDescriptor<User>(
                predicate: #Predicate { $0.id == userId }
            )
            let user: User
            if let existing = try context.fetch(userDescriptor).first {
                existing.username = userDTO.username
                existing.avatarURL = userDTO.avatarURL
                user = existing
            } else {
                user = User(id: userDTO.id, username: userDTO.username, avatarURL: userDTO.avatarURL)
                context.insert(user)
            }

            // Upsert stories
            for storyDTO in group.stories {
                let storyId = storyDTO.id
                let storyDescriptor = FetchDescriptor<Story>(
                    predicate: #Predicate { $0.id == storyId }
                )
                if let existing = try context.fetch(storyDescriptor).first {
                    existing.imageUrl = storyDTO.imageUrl
                    existing.caption = storyDTO.caption
                    existing.createdAt = storyDTO.createdAt
                    existing.user = user
                } else {
                    let story = Story(
                        id: storyDTO.id,
                        imageUrl: storyDTO.imageUrl,
                        caption: storyDTO.caption,
                        createdAt: storyDTO.createdAt
                    )
                    story.user = user
                    context.insert(story)
                }
            }
        }

        try context.save()
    }
}
