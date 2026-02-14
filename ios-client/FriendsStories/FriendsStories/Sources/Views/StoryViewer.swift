//
//  FriendsStories
//

import SwiftUI

struct StoryViewerView: View {
    let user: User
    @State private var currentIndex: Int = 0
    @Environment(\.dismiss) private var dismiss

    private var stories: [Story] {
        user.stories.sorted { $0.createdAt < $1.createdAt }
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let story = stories[safe: currentIndex] {
                GeometryReader { geo in
                    AsyncImage(url: URL(string: story.imageUrl)) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: geo.size.width, height: geo.size.height)
                                .clipped()
                        case .failure:
                            Image(systemName: "photo")
                                .font(.largeTitle)
                                .foregroundStyle(.white.opacity(0.5))
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        default:
                            ProgressView()
                                .tint(.white)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                    }
                }
                .ignoresSafeArea()
            }

            HStack(spacing: 0) {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture { goBack() }
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture { goForward() }
            }
            .ignoresSafeArea()

            VStack {
                progressBars
                    .padding(.horizontal, 8)
                    .padding(.top, 8)

                HStack(spacing: 10) {
                    AsyncImage(url: URL(string: user.avatarURL ?? "")) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        Circle().fill(.gray.opacity(0.5))
                    }
                    .frame(width: 32, height: 32)
                    .clipShape(Circle())

                    Text(user.username)
                        .font(.subheadline.bold())
                        .foregroundStyle(.white)

                    if let story = stories[safe: currentIndex] {
                        Text(story.createdAt, style: .relative)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.7))
                    }

                    Spacer()

                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.body.bold())
                            .foregroundStyle(.white)
                    }
                }
                .padding(.horizontal, 12)

                Spacer()

                if let caption = stories[safe: currentIndex]?.caption {
                    Text(caption)
                        .font(.body)
                        .foregroundStyle(.white)
                        .shadow(radius: 4)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .statusBarHidden()
        .gesture(
            DragGesture(minimumDistance: 50)
                .onEnded { value in
                    if value.translation.height > 100 {
                        dismiss()
                    }
                }
        )
    }
    
    

    // MARK: - Progress bars

    private var progressBars: some View {
        HStack(spacing: 4) {
            ForEach(stories.indices, id: \.self) { index in
                Capsule()
                    .fill(index <= currentIndex ? Color.white : Color.white.opacity(0.35))
                    .frame(height: 2.5)
            }
        }
    }

    // MARK: - Navigation

    private func goBack() {
        if currentIndex > 0 {
            withAnimation { currentIndex -= 1 }
        }
    }

    private func goForward() {
        if currentIndex < stories.count - 1 {
            withAnimation { currentIndex += 1 }
        } else {
            dismiss()
        }
    }
}

// MARK: - Safe subscript

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
