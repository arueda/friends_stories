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
    let storyFilter: ((Story) -> Bool)?
    private let orderedStories: [(user: User, story: Story)]?

    var storyDuration: TimeInterval {
        StorySpeed(rawValue: UserDefaults.standard.string(forKey: "storySpeed") ?? "")?.duration ?? StorySpeed.normal.duration
    }

    var currentUser: User? {
        if let orderedStories {
            return orderedStories.indices.contains(currentUserIndex) ? orderedStories[currentUserIndex].user : nil
        }
        return users.indices.contains(currentUserIndex) ? users[currentUserIndex] : nil
    }

    var stories: [Story] {
        if let orderedStories {
            guard orderedStories.indices.contains(currentUserIndex) else { return [] }
            return [orderedStories[currentUserIndex].story]
        }
        let sorted = currentUser?.stories.sorted { $0.createdAt < $1.createdAt } ?? []
        if let storyFilter {
            return sorted.filter(storyFilter)
        }
        return sorted
    }

    var currentStory: Story? {
        stories.indices.contains(currentStoryIndex) ? stories[currentStoryIndex] : nil
    }

    init(users: [User], startingUserIndex: Int = 0, startingStoryIndex: Int = 0, storyFilter: ((Story) -> Bool)? = nil, orderedStories: [(user: User, story: Story)]? = nil) {
        self.users = users
        self.storyFilter = storyFilter
        self.orderedStories = orderedStories
        if let orderedStories {
            self.currentUserIndex = min(startingUserIndex, max(orderedStories.count - 1, 0))
            self.currentStoryIndex = 0
        } else {
            self.currentUserIndex = min(startingUserIndex, max(users.count - 1, 0))
            var sortedStories = users.indices.contains(currentUserIndex)
                ? users[currentUserIndex].stories.sorted { $0.createdAt < $1.createdAt }
                : []
            if let storyFilter {
                sortedStories = sortedStories.filter(storyFilter)
            }
            self.currentStoryIndex = min(startingStoryIndex, max(sortedStories.count - 1, 0))
        }
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
        if orderedStories != nil {
            if currentUserIndex > 0 {
                currentUserIndex -= 1
                startTimer()
            }
            return
        }
        if currentStoryIndex > 0 {
            currentStoryIndex -= 1
            startTimer()
        }
    }

    func goForward() {
        if let orderedStories {
            if currentUserIndex < orderedStories.count - 1 {
                currentUserIndex += 1
                startTimer()
            } else {
                shouldDismiss = true
            }
            return
        }
        if currentStoryIndex < stories.count - 1 {
            currentStoryIndex += 1
            startTimer()
        } else if let nextIndex = nextUserIndex(after: currentUserIndex) {
            currentUserIndex = nextIndex
            currentStoryIndex = 0
            startTimer()
        } else {
            shouldDismiss = true
        }
    }

    private func nextUserIndex(after index: Int) -> Int? {
        for i in (index + 1)..<users.count {
            if storiesForUser(at: i).isEmpty == false {
                return i
            }
        }
        return nil
    }

    private func storiesForUser(at index: Int) -> [Story] {
        guard users.indices.contains(index) else { return [] }
        let sorted = users[index].stories.sorted { $0.createdAt < $1.createdAt }
        if let storyFilter {
            return sorted.filter(storyFilter)
        }
        return sorted
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
