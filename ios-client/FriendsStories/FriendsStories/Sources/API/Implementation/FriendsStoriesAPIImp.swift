//
//  FriendsStories
//

import Foundation

struct FriendsStoriesAPIImpl: FriendsStoriesAPI {
    private let networkClient: NetworkClient

    init(networkClient: NetworkClient = NetworkClientImp()) {
        self.networkClient = networkClient
    }
    
    // GET /api/users — list all users
    func getUsers() async throws -> [UserDTO] {
        let endpoint = Request<[UserDTO]>(path: "/api/users", method: "GET")
        return try await networkClient.fetch(endpoint)
    }
    
    // GET /api/stories — paginated stories grouped by user
    func getStories() async throws -> [StoryDTO] {
        let endpoint = Request<[StoryDTO]>(path: "/api/stories", method: "GET")
        return try await networkClient.fetch(endpoint)
    }
}

