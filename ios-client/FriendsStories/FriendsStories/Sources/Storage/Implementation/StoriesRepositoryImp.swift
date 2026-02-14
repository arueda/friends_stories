//
//  FriendsStories
//

import Foundation
import SwiftData

class StoriesRepositoryImpl: StoriesRepository {
    private var api: FriendsStoriesAPI
    private var modelContainer: ModelContainer
    
    init(api: FriendsStoriesAPI, modelContainer: ModelContainer) {
        self.api = api
        self.modelContainer = modelContainer
    }
    
    func refreshStories() async throws {
        let stories = try await api.getStories()
    }
}
