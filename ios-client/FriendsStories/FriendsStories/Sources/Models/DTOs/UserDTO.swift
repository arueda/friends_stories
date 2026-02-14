//
//  FriendsStories
//

import Foundation

struct UserDTO: Decodable, Sendable {
    let id: Int64
    let username: String
    let avatarURL: String?
 
    enum CodingKeys: String, CodingKey {
        case id
        case username
        case avatarURL = "avatar_url"
    }
}

