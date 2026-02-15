//
//  FriendsStories
//

import SwiftUI

@Observable
final class StorySessionViewModel {
    private(set) var currentUserIndex: Int
    private(set) var currentStoryIndex: Int = 0
    private(set) var progress: CGFloat = 0
    private(set) var shouldDismiss = false
    var timerRunning = true

    let users: [User]
    var storyDuration: TimeInterval {
        StorySpeed(rawValue: UserDefaults.standard.string(forKey: "storySpeed") ?? "")?.duration ?? StorySpeed.normal.duration
    }

    var currentUser: User? {
        users.indices.contains(currentUserIndex) ? users[currentUserIndex] : nil
    }

    var stories: [Story] {
        currentUser?.stories.sorted { $0.createdAt < $1.createdAt } ?? []
    }

    var currentStory: Story? {
        stories.indices.contains(currentStoryIndex) ? stories[currentStoryIndex] : nil
    }

    init(users: [User], startingUserIndex: Int = 0, startingStoryIndex: Int = 0) {
        self.users = users
        self.currentUserIndex = min(startingUserIndex, max(users.count - 1, 0))
        let sortedStories = users.indices.contains(currentUserIndex)
            ? users[currentUserIndex].stories.sorted { $0.createdAt < $1.createdAt }
            : []
        self.currentStoryIndex = min(startingStoryIndex, max(sortedStories.count - 1, 0))
    }

    func tick() {
        guard timerRunning else { return }
        let step = 1.0 / (storyDuration * 30)
        if progress + step >= 1.0 {
            progress = 1.0
            goForward()
        } else {
            progress += step
        }
    }

    func startTimer() {
        progress = 0
        timerRunning = true
        markCurrentStorySeen()
    }
    
    func toggleLikeStatus() {
        if currentStory?.isLiked == nil {
            currentStory?.isLiked = true
        } else {
            currentStory?.isLiked?.toggle()
        }
    }

    private func markCurrentStorySeen() {
        guard let story = currentStory, !story.isSeen else { return }
        story.seenAt = Date()
    }

    func goBack() {
        if currentStoryIndex > 0 {
            currentStoryIndex -= 1
            startTimer()
        }
    }

    func goForward() {
        if currentStoryIndex < stories.count - 1 {
            currentStoryIndex += 1
            startTimer()
        } else if currentUserIndex < users.count - 1 {
            currentUserIndex += 1
            currentStoryIndex = 0
            startTimer()
        } else {
            shouldDismiss = true
        }
    }

    func barWidth(for index: Int, totalWidth: CGFloat) -> CGFloat {
        if index < currentStoryIndex {
            return totalWidth
        } else if index == currentStoryIndex {
            return totalWidth * progress
        } else {
            return 0
        }
    }
}
