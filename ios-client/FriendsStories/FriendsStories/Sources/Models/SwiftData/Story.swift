//
//  FriendsStories
//

import Foundation
import SwiftData

@Model class Story {
    @Attribute(.unique) var id: Int64
    var imageUrl: String
    var caption: String?
    var createdAt: Date
    var seenAt: Date?
    var isLiked: Bool?
    @Relationship(inverse: \User.stories) var user: User?

    var isSeen: Bool { seenAt != nil }

    init(id: Int64, imageUrl: String, caption: String? = nil, createdAt: Date) {
        self.id = id
        self.imageUrl = imageUrl
        self.caption = caption
        self.createdAt = createdAt
    }
}
