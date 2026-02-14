//
//  FriendsStories
//

import Foundation

struct StoryDTO: Decodable, Sendable {
    let id: Int64
    let imageUrl: String
    let caption: String?
    let createdAt: Date
    // If the story payload includes nested user info, include it:
    let user: UserDTO?

    enum CodingKeys: String, CodingKey {
        case id
        case imageUrl = "image_url"
        case caption
        case createdAt = "created_at"
        case user
    }
}

