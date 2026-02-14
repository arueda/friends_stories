//
//  FriendsStories
//

import Foundation

struct Request<Response: Decodable>: Endpoint {
    let path: String
    let queryItems: [URLQueryItem]
    let method: String

    init(path: String, method: String = "GET", queryItems: [URLQueryItem] = []) {
        self.path = path
        self.method = method
        self.queryItems = queryItems
    }
}
