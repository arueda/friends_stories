import Foundation
@testable import FriendsStories

class NetworkClientMock: NetworkClient {
    var onFetch: ((Any) async throws -> Any)?

    func fetch<E: Endpoint>(_ endpoint: E) async throws -> E.Response {
        guard let onFetch = onFetch else {
            fatalError("NetworkClientMock: onFetch closure not set")
        }
        
        let result = try await onFetch(endpoint)
        
        guard let typedResult = result as? E.Response else {
             fatalError("NetworkClientMock: Expected result of type \(E.Response.self) but got \(type(of: result))")
        }
        
        return typedResult
    }
}
