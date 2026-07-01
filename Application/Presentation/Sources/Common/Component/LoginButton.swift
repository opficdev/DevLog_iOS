//
//  LoginButton.swift
//  Presentation
//
//  Created by opfic on 4/25/25.
//

import SwiftUI
import Domain

struct LoginButton: View {
    @State private var logo: Image?
    @State private var text = ""
    @ScaledMetric(relativeTo: .body) private var height = CGFloat(22)
    private let showsProgressView: Bool
    private let action: () -> Void

    init(
        logo: Image? = nil,
        text: String = "",
        showsProgressView: Bool = false,
        action: @escaping () -> Void = {}
    ) {
        self._logo = State(initialValue: logo)
        self._text = State(initialValue: text)
        self.showsProgressView = showsProgressView
        self.action = action
    }
    
    var body: some View {
        Button {
            action()
        } label: {
            ZStack {
                Text(text)
                    .opacity(showsProgressView ? 0 : 1)
                if showsProgressView {
                    ProgressView()
                }
            }
            .foregroundStyle(Color.primary)
            .font(.system(.body))
            .contentShape(.capsule)
            .frame(width: 300, height: height + 16)
            .overlay {
                ZStack(alignment: .leading) {
                    Capsule()
                        .stroke(Color.gray, lineWidth: 1)
                    if let logo, !showsProgressView {
                        logo
                            .resizable()
                            .scaledToFit()
                            .frame(width: height, height: height)
                            .padding(.leading)
                    }
                }
            }
        }
    }
}
