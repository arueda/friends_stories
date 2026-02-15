//
//  FriendsStories
//

protocol FriendsStoriesAPI {
    // GET /api/stories — paginated stories grouped by user
    func getStories(page: Int, limit: Int) async throws -> StoryResponse
}

