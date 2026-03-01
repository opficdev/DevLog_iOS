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
            CacheableImage(url: item.imageURL) {
                Image(systemName: "globe")
                    .resizable()
                    .scaledToFit()
            }
            .frame(width: sceneWidth / 10, height: sceneWidth / 10)
            .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading) {
                Text(item.title)
                    .foregroundStyle(Color.primary)
                    .bold()
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
}
