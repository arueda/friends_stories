//
//  FriendsStories
//

import Foundation
import SwiftData

class StoriesRepositoryImpl: StoriesRepository {
    private var api: FriendsStoriesAPI
    private var modelContainer: ModelContainer
    
    init(api: FriendsStoriesAPI, modelContainer: ModelContainer) {
        self.api = api
        self.modelContainer = modelContainer
    }
    
    @MainActor
    func refreshStories() async throws {
        let response = try await api.getStories()
        let context = modelContainer.mainContext

        for group in response.data {
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
