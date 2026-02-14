import Testing
import Foundation
@testable import FriendsStories

struct FriendsStoriesTests {

    // I want to test decoding of data.
    @Test func testDecoding() async throws {
        // GIVEN
        let mockClient = NetworkClientMock()
        mockClient.onFetch = { endpoint in
            let responseString = """
            {"data":[{"user":{"id":4,"username":"dave","avatar_url":"https://i.pravatar.cc/150?u=dave"},"stories":[{"id":8,"image_url":"https://picsum.photos/seed/d1/400/700","caption":"Road trip!","created_at":"2026-02-14T17:18:23.483Z"}]},{"user":{"id":3,"username":"carol","avatar_url":"https://i.pravatar.cc/150?u=carol"},"stories":[{"id":5,"image_url":"https://picsum.photos/seed/c1/400/700","caption":"New recipe","created_at":"2026-02-14T17:18:23.483Z"},{"id":6,"image_url":"https://picsum.photos/seed/c2/400/700","caption":"Book club","created_at":"2026-02-14T17:18:23.483Z"},{"id":7,"image_url":"https://picsum.photos/seed/c3/400/700","caption":null,"created_at":"2026-02-14T17:18:23.483Z"}]},{"user":{"id":2,"username":"bob","avatar_url":"https://i.pravatar.cc/150?u=bob"},"stories":[{"id":3,"image_url":"https://picsum.photos/seed/b1/400/700","caption":"At the gym","created_at":"2026-02-14T17:18:23.483Z"},{"id":4,"image_url":"https://picsum.photos/seed/b2/400/700","caption":null,"created_at":"2026-02-14T17:18:23.483Z"}]},{"user":{"id":1,"username":"alice","avatar_url":"https://i.pravatar.cc/150?u=alice"},"stories":[{"id":1,"image_url":"https://picsum.photos/seed/a1/400/700","caption":"Morning coffee","created_at":"2026-02-14T17:18:23.483Z"},{"id":2,"image_url":"https://picsum.photos/seed/a2/400/700","caption":"Sunset walk","created_at":"2026-02-14T17:18:23.483Z"}]}],"page":1,"limit":10,"hasMore":false}
            """
            let responseData = try #require(responseString.data(using: .utf8))
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            let storyResponse = try decoder.decode(StoryResponse.self,
                                                   from: responseData)
            return storyResponse
        }
        
        // WHEN
        let endpoint = Request<StoryResponse>(path: "/api/stories", method: "GET")
        let result = try await mockClient.fetch(endpoint)
        
        // THEN
        #expect(result.data.count == 4)
        let user = try #require(result.data.first?.user)
        #expect(user.username == "dave")
        let userStories = try #require(result.data.first?.stories)
        #expect(userStories.count == 1)
        #expect(userStories.first?.caption == "Road trip!")
        // Check date logic if needed
    }

}
