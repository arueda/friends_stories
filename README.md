# Setup

## iOS App

- Install mise https://mise.jdx.dev/getting-started.html
- Install tuist using mise https://docs.tuist.dev/en/guides/install-tuist
- Generate the Xcode Project using tuist from the ios-client directory: mise x tuist@latest -- tuist generate

## Backend

- Install npm
- In the backend directory, install the server dependencies: npm install
- Run npm start. The backend should be running by default on port 3000

---

# Design

## Backend

The backend is a basic SQLite database that runs a query to find users with stories and groups them by user.

https://i.pravatar.cc is used to mock users’ profile pics. 

https://picsum.photos is used to mock stories data.

The data is returned as JSON in accordance with industry standards.

## iOS App

The iOS app uses SwiftUI for the presentation, SwiftData for storage, and SwiftTesting for unit tests.

Use of protocols to allow easy testing and mocking.

The heart of the app is the repository, which can transform the data and store it in SwiftData. The models are then injected into the views for easy consumption. Each change to SwiftData models is reflected immediately, reducing the need for boilerplate or large view models. 

The project uses Tuist for project setup. This allows easy Xcode project generation. Xcode conflicts should be avoided when working on distributed teams.

Given that the main goal is to show user stories, the entry point is a feed of stories grouped by users or sorted by publication time.

The user can use known gestures (swiping down) to dismiss the stories viewer or advance to the previous or next stories (tapping on the edge of the screen). 

The app supports basic Push Notification Handling. Receiving a push notification takes the user to the story viewer screen.

# Future work and improvements.

We can add featured or branded content between user stories.

Allow video in stories. 

Flat the user - story relationship to allow for better data consumption. 

# Known issues.

There is an issue with the image cache; some images do not load immediately when fetched from the LazyGrid.

Not all strings are localized or might be inaccurately translated.