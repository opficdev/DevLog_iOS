//
//  WebItemRow.swift
//  Presentation
//
//  Created by 최윤진 on 2/24/26.
//

import SwiftUI

public struct WebItemRow: View {
    @ScaledMetric(relativeTo: .largeTitle) private var labelWidth = CGFloat(34)
    let item: WebPageItem
    let showsChevron: Bool

    public init(
        item: WebPageItem,
        showsChevron: Bool
    ) {
        self.item = item
        self.showsChevron = showsChevron
    }

    public var body: some View {
        HStack {
            thumbnail
                .frame(width: labelWidth, height: labelWidth)
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
