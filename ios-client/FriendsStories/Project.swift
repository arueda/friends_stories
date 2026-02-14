import ProjectDescription

let project = Project(
    name: "FriendsStories",
    targets: [
        .target(
            name: "FriendsStories",
            destinations: .iOS,
            product: .app,
            bundleId: "dev.tuist.Friends-Stories",
            infoPlist: .extendingDefault(
                with: [
                    "UILaunchScreen": [
                        "UIColorName": "",
                        "UIImageName": "",
                    ],
                ]
            ),
            buildableFolders: [
                "FriendsStories/Sources",
                "FriendsStories/Resources",
            ],
            dependencies: []
        ),
        .target(
            name: "FriendsStoriesTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "dev.tuist.FriendsStoriesTests",
            infoPlist: .default,
            buildableFolders: [
                "FriendsStories/Tests"
            ],
            dependencies: [.target(name: "FriendsStories")]
        ),
    ]
)
