//
//  FriendsStories
//

import Foundation

struct FriendsStoriesAPIImpl: FriendsStoriesAPI {
    private let networkClient: NetworkClient

    init(networkClient: NetworkClient) {
        self.networkClient = networkClient
    }
    
    // GET /api/stories — paginated stories grouped by user
    func getStories() async throws -> StoryResponse {
        let endpoint = Request<StoryResponse>(path: "/api/stories", method: "GET")
        let response = try await networkClient.fetch(endpoint)
        return response
    }
}
