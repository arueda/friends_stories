//
//  FriendsStories
//

import SwiftUI

@Observable
final class StorySessionViewModel {
    private(set) var currentIndex: Int = 0
    private(set) var progress: CGFloat = 0
    private(set) var shouldDismiss = false
    var timerRunning = true

    let stories: [Story]
    let storyDuration: TimeInterval = 10.0

    var currentStory: Story? {
        stories.indices.contains(currentIndex) ? stories[currentIndex] : nil
    }

    init(user: User, startingIndex: Int = 0) {
        self.stories = user.stories.sorted { $0.createdAt < $1.createdAt }
        self.currentIndex = min(startingIndex, max(stories.count - 1, 0))
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

    private func markCurrentStorySeen() {
        guard let story = currentStory, !story.isSeen else { return }
        story.seenAt = Date()
    }

    func goBack() {
        if currentIndex > 0 {
            currentIndex -= 1
            startTimer()
        }
    }

    func goForward() {
        if currentIndex < stories.count - 1 {
            currentIndex += 1
            startTimer()
        } else {
            shouldDismiss = true
        }
    }

    func barWidth(for index: Int, totalWidth: CGFloat) -> CGFloat {
        if index < currentIndex {
            return totalWidth
        } else if index == currentIndex {
            return totalWidth * progress
        } else {
            return 0
        }
    }
}
