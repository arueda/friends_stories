//
//  FriendsStories
//

struct FriendsStoriesAPIImpl: FriendsStoriesAPI {
    // GET /api/users — list all users
    func getUsers() async throws -> [User] {
        return []
    }
    // GET /api/stories — paginated stories grouped by user
    func getStories() async throws -> [Story] {
        return []
    }
}
