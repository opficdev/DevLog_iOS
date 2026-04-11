//
//  WebItemRow.swift
//  DevLog
//
//  Created by 최윤진 on 2/24/26.
//

import SwiftUI

struct WebItemRow: View {
    @Environment(\.sceneWidth) private var sceneWidth

    let item: WebPageItem
    let showsChevron: Bool

    var body: some View {
        HStack {
            thumbnail
                .frame(width: sceneWidth * 0.08, height: sceneWidth * 0.08)
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading) {
                Text(item.title)
                    .foregroundStyle(Color.primary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                Text(item.displayURL)
                    .foregroundStyle(Color.blue)
                    .underline()
            }
            Spacer()
            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.caption2.bold())
                    .foregroundStyle(.gray)
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var thumbnail: some View {
        if let imageURL = item.imageURL {
            AsyncImage(url: imageURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                case .empty:
                    ProgressView()
                default:
                    placeholderImage
                }
            }
        } else {
            placeholderImage
        }
    }

    private var placeholderImage: some View {
        Image(systemName: "globe")
            .resizable()
            .scaledToFit()
    }
}
