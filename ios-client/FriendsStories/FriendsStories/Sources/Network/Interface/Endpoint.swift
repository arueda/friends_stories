//
//  FriendsStories
//

import Foundation

protocol Endpoint {
    associatedtype Response: Decodable
    var path: String { get }
    var queryItems: [URLQueryItem] { get }
    var method: String { get }
}
