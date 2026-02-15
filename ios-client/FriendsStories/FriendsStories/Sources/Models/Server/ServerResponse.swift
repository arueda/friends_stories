//
//  FriendsStories
//

struct StoryResponse: Decodable {
    let data: [UserResponse]
    let page: Int
    let limit: Int
    let hasMore: Bool
}

struct UserResponse: Decodable {
    let user: UserDTO
    let stories: [StoryDTO]
}
