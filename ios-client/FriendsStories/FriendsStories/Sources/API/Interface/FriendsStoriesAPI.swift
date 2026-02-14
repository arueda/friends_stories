//
//  FriendsStories
//

protocol FriendsStoriesAPI {
    // GET /api/stories — paginated stories grouped by user
    func getStories() async throws -> StoryResponse
}

