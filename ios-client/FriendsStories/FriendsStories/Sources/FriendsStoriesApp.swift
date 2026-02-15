//
//  FriendsStories
//

import SwiftUI
import SwiftData

@main
struct FriendsStoriesApp: App {
    private let modelContainer: ModelContainer
    private let networkClient: NetworkClient
    private let apiClient: FriendsStoriesAPI
    private let storiesRepository: StoriesRepository
    
    @State private var notificationHandler = NotificationHandler()

    init() {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601 // I wanna make sure the correct decoding strategy is set.
        self.modelContainer = try! ModelContainer(for: User.self, Story.self)
        self.networkClient = NetworkClientImpl(baseURL: URL(string: "http://192.168.100.12:3000")!, decoder: decoder)
        self.apiClient = FriendsStoriesAPIImpl(networkClient: networkClient)
        self.storiesRepository = StoriesRepositoryImpl(api: apiClient, modelContainer: modelContainer)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(notificationHandler)
                .environment(\.storiesRepository, storiesRepository)
        }
        .modelContainer(modelContainer)
    }
}
