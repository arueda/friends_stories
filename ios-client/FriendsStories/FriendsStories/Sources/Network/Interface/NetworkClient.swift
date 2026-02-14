//
//  FriendsStories
//

import Foundation

protocol NetworkClient {
    func fetch<E: Endpoint>(_ endpoint: E) async throws -> E.Response
}




