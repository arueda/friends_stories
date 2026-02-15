//
//  FriendsStories
//

import SwiftUI
import Combine

struct StoryViewerView: View {
    @State private var viewModel: StorySessionViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    private let timer = Timer.publish(every: 1.0 / 30, on: .main, in: .common).autoconnect()

    init(users: [User], startingUserIndex: Int = 0, startingStoryIndex: Int = 0) {
        self._viewModel = State(initialValue: StorySessionViewModel(
            users: users,
            startingUserIndex: startingUserIndex,
            startingStoryIndex: startingStoryIndex
        ))
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let story = viewModel.currentStory {
                GeometryReader { geo in
                    CachedAsyncImage(url: URL(string: story.imageUrl)) { phase in
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
                    .onTapGesture { viewModel.goBack() }
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture { viewModel.goForward() }
            }
            .ignoresSafeArea()

            VStack {
                progressBars
                    .padding([.horizontal, .top], 8)

                if let user = viewModel.currentUser {
                    HStack(spacing: 10) {
                        CachedAsyncImage(url: URL(string: user.avatarURL ?? "")) { phase in
                            switch phase {
                            case .success(let image):
                                image.resizable().scaledToFill()
                            default:
                                Circle().fill(.gray.opacity(0.5))
                            }
                        }
                        .frame(width: 32, height: 32)
                        .clipShape(Circle())

                        Text(user.username)
                            .font(.subheadline.bold())
                            .foregroundStyle(.white)

                        if let story = viewModel.currentStory {
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
                }

                Spacer()

                HStack {
                    if let caption = viewModel.currentStory?.caption {
                        Text(caption)
                            .font(.body)
                            .foregroundStyle(.white)
                            .shadow(radius: 4)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    Spacer()
                        
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                            viewModel.toggleLikeStatus()
                            try? modelContext.save()
                        }
                    } label: {
                        Image(systemName: viewModel.currentStory?.isLiked ?? false ? "heart.fill" : "heart")
                            .font(.body.bold())
                            .foregroundStyle(viewModel.currentStory?.isLiked ?? false ? .red : .white)
                            .scaleEffect(viewModel.currentStory?.isLiked ?? false ? 1.2 : 1.0)
                            .padding()
                    }
                    .sensoryFeedback(.impact(flexibility: .soft), trigger: viewModel.currentStory?.isLiked)
                }
                
            }
        }
        .statusBarHidden()
        .onAppear { viewModel.startTimer() }
        .onReceive(timer) { _ in viewModel.tick() }
        .onChange(of: viewModel.shouldDismiss) { _, shouldDismiss in
            if shouldDismiss { dismiss() }
        }
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
            ForEach(viewModel.stories.indices, id: \.self) { index in
                GeometryReader { geo in
                    Capsule()
                        .fill(Color.white.opacity(0.35))
                        .overlay(alignment: .leading) {
                            Capsule()
                                .fill(Color.white)
                                .frame(width: viewModel.barWidth(for: index, totalWidth: geo.size.width))
                        }
                        .clipShape(Capsule())
                }
                .frame(height: 2.5)
            }
        }
    }
}
