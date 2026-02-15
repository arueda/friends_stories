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
    func getStories(page: Int, limit: Int) async throws -> StoryResponse {
        let endpoint = Request<StoryResponse>(
            path: "/api/stories",
            method: "GET",
            queryItems: [
                URLQueryItem(name: "page", value: String(page)),
                URLQueryItem(name: "limit", value: String(limit)),
            ]
        )
        return try await networkClient.fetch(endpoint)
    }
}
