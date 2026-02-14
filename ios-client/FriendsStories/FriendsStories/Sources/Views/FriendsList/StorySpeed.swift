//
//  StorySpeed.swift
//  FriendsStories
//
//  Created by Angel Rueda Mejia on 14/02/26.
//

import Foundation

enum StorySpeed: String, CaseIterable, Identifiable {
    case fast
    case normal
    case slow

    var id: String { rawValue }

    var duration: TimeInterval {
        switch self {
        case .fast: 2
        case .normal: 5
        case .slow: 10
        }
    }

    var label: String {
        switch self {
        case .fast: String(localized: "speed.fast")
        case .normal: String(localized: "speed.normal")
        case .slow: String(localized: "speed.slow")
        }
    }
}
