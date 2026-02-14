//
//  FriendsStories
//

import SwiftUI
import SwiftData

@main
struct FriendsStoriesApp: App {
    private let modelContainer: ModelContainer
    private let networkClient: NetworkClient

    init() {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601 // I wanna make sure the correct decoding strategy is set.
        self.modelContainer = try! ModelContainer(for: User.self, Story.self)
        self.networkClient = NetworkClientImpl(
            baseURL: URL(string: "http://localhost:3000")!,
            decoder: decoder
        )
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(
                    \.storiesRepository,
                    StoriesRepositoryImpl(
                        api: FriendsStoriesAPIImpl(networkClient: networkClient),
                        modelContainer: modelContainer
                    )
                )
        }
        .modelContainer(modelContainer)
    }
}
