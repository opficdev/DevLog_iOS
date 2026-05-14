//
//  CacheableImage.swift
//  DevLog
//
//  Created by 최윤진 on 11/30/25.
//

import SwiftUI
import DevLogDomain
import DevLogPresentation

struct CacheableImage<Content: View>: View {
    @State private var loadedUIImage: UIImage?
    @State private var isInvalid: Bool = false
    private let url: URL?
    private let request: URLRequest
    @ViewBuilder private var content: () -> Content

    init(
        url: URL?,
        @ViewBuilder content: @escaping () -> Content = {
            Image(systemName: "photo")
                .foregroundColor(.gray)
                .font(.largeTitle)
                .scaledToFill()
        }
    ) {
        self.url = url
        self.content = content
        if let url {
            var request = URLRequest(url: url)
            request.cachePolicy = .returnCacheDataElseLoad
            request.timeoutInterval = 10
            self.request = request
        } else {
            self.request = URLRequest(url: URL(string: "about:blank")!)
            self.isInvalid = true
        }
    }

    var body: some View {
        Group {
            if let loadedUIImage {
                Image(uiImage: loadedUIImage)
                    .resizable()
                    .scaledToFill()
            } else if isInvalid {
                content()
            } else {
                ProgressView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task(id: url) {
            self.isInvalid = (self.url == nil)
            await loadImageWithCache()
        }
    }

    @MainActor
    private func loadImageWithCache() async {
        guard let url = self.url else { return }

        if url.isFileURL {
            await loadLocalImage(from: url)
            return
        }

        if let cachedResponse = URLCache.imageCached.cachedResponse(for: request) {
            if let uiImage = UIImage(data: cachedResponse.data) {
                self.loadedUIImage = uiImage
                return
            }
        }

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode
            else { return }

            let cachedURLResponse = CachedURLResponse(response: httpResponse, data: data)
            URLCache.imageCached.storeCachedResponse(cachedURLResponse, for: request)

            if let uiImage = UIImage(data: data) {
                self.loadedUIImage = uiImage
            }
        } catch {
            isInvalid = true
        }
    }

    @MainActor
    private func loadLocalImage(from url: URL) async {
        do {
            let data = try await Task.detached {
                try Data(contentsOf: url)
            }.value

            if let uiImage = UIImage(data: data) {
                self.loadedUIImage = uiImage
            } else {
                isInvalid = true
            }
        } catch {
            isInvalid = true
        }
    }
}

extension URLCache {
    static let imageCached: URLCache = {
        let diskCapacity = 300 * 1024 * 1024    // 300MB
        let cache = URLCache(memoryCapacity: 10, diskCapacity: diskCapacity, diskPath: "imageCache")
        return cache
    }()
}
