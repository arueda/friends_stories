//
//  FriendsStories
//

import SwiftUI

struct CachedAsyncImage<Content: View>: View {
    private let url: URL?
    private let content: (AsyncImagePhase) -> Content

    init(url: URL?, @ViewBuilder content: @escaping (AsyncImagePhase) -> Content) {
        self.url = url
        self.content = content
    }

    var body: some View {
        if let url, let cached = ImageCache.shared[url] {
            content(.success(cached))
        } else {
            AsyncImage(url: url) { phase in
                cacheAndRender(phase)
            }
        }
    }

    private func cacheAndRender(_ phase: AsyncImagePhase) -> some View {
        if case .success(let image) = phase, let url {
            ImageCache.shared[url] = image
        }
        return content(phase)
    }
}

private final class ImageCache {
    static let shared = ImageCache()
    private let cache = NSCache<NSURL, WrappedImage>()

    subscript(url: URL) -> Image? {
        get { cache.object(forKey: url as NSURL)?.image }
        set {
            if let newValue {
                cache.setObject(WrappedImage(newValue), forKey: url as NSURL)
            } else {
                cache.removeObject(forKey: url as NSURL)
            }
        }
    }

    private class WrappedImage {
        let image: Image
        init(_ image: Image) { self.image = image }
    }
}
