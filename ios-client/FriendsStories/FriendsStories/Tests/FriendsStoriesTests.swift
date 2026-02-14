//
//  FriendsStories
//

import Testing
import Foundation
@testable import FriendsStories

struct FriendsStoriesTests {

    // I want to test decoding of data.
    @Test func testDecoding() async throws {
        // GIVEN
        let mockClient = NetworkClientMock()
        mockClient.onFetch = { endpoint in
            let fixtureURL = try #require(
                Bundle(for: BundleToken.self).url(forResource: "stories_response", withExtension: "json")
            )
            let responseData = try Data(contentsOf: fixtureURL)

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
    }
    
    // Use the FriendsStoriesAPIImpl with a mock network client
    @Test func testGetStories() async throws {
        let mockClient = NetworkClientMock()
        mockClient.onFetch = { endpoint in
            let fixtureURL = try #require(
                Bundle(for: BundleToken.self).url(forResource: "stories_response", withExtension: "json")
            )
            let responseData = try Data(contentsOf: fixtureURL)

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601

            let storyResponse = try decoder.decode(StoryResponse.self,
                                                   from: responseData)
            return storyResponse
        }
        
        let apiClient = FriendsStoriesAPIImpl(networkClient: mockClient)
        let response = try await apiClient.getStories()
        
        // The mock data has 4 users
        #expect(response.data.count > 0)
        let userResponse = try #require(response.data.first)
        #expect(userResponse.stories.count != 0)
    }

    @Test func testServerError() async throws {
        // GIVEN
        let session = URLSessionMock()
        session.mockResponse = HTTPURLResponse(
            url: URL(string: "https://example.com")!,
            statusCode: 500,
            httpVersion: nil,
            headerFields: nil
        )
        session.mockData = Data()

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let client = NetworkClientImpl(
            baseURL: URL(string: "https://example.com")!,
            decoder: decoder,
            session: session
        )

        // WHEN / THEN
        let endpoint = Request<StoryResponse>(path: "/api/stories")
        await #expect(throws: URLError.self) {
            try await client.fetch(endpoint)
        }
    }

    @Test func testNetworkError() async throws {
        // GIVEN
        let session = URLSessionMock()
        session.mockError = URLError(.notConnectedToInternet)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let client = NetworkClientImpl(
            baseURL: URL(string: "https://example.com")!,
            decoder: decoder,
            session: session
        )

        // WHEN / THEN
        let endpoint = Request<StoryResponse>(path: "/api/stories")
        await #expect(throws: URLError.self) {
            try await client.fetch(endpoint)
        }
    }

}

private class BundleToken {}
