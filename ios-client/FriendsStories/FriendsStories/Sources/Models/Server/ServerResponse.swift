//
//  FriendsStories
//

struct StoryResponse: Decodable {
    let data: [UserResponse]
}

struct UserResponse: Decodable {
    let user: UserDTO
    let stories: [StoryDTO]
}
