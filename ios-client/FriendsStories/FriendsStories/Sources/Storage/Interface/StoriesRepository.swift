//
//  FriendsStories
//

import SwiftUI

@MainActor
protocol StoriesRepository {
    func refreshStories() async throws
}

private struct StoriesRepositoryKey: EnvironmentKey {
    static let defaultValue: (any StoriesRepository)? = nil
}

extension EnvironmentValues {
    var storiesRepository: (any StoriesRepository)? {
        get { self[StoriesRepositoryKey.self] }
        set { self[StoriesRepositoryKey.self] = newValue }
    }
}
