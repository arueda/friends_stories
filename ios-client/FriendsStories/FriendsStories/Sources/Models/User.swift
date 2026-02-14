// Model for User

import Foundation
import SwiftData

@Model class User {
    @Attribute(.unique) var id: Int64
    var username: String
    var avatarURL: String?

    @Relationship(deleteRule: .cascade) var stories: [Story] = []

    init(id: Int64, username: String, avatarURL: String? = nil) {
        self.id = id
        self.username = username
        self.avatarURL = avatarURL
    }
}