//
//  LoginButton.swift
//  DevLogPresentation
//
//  Created by opfic on 4/25/25.
//

import SwiftUI
import DevLogDomain

struct LoginButton: View {
    @State private var logo: Image?
    @State private var text = ""
    @ScaledMetric(relativeTo: .body) private var height = CGFloat(22)
    private let action: () -> Void

    init(
        logo: Image? = nil,
        text: String = "",
        action: @escaping () -> Void = {}
    ) {
        self._logo = State(initialValue: logo)
        self._text = State(initialValue: text)
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            action()
        }) {
            Text(text)
                .foregroundStyle(Color.primary)
                .font(.system(.body))
        }
        .frame(width: 300, height: height + 16)
        .contentShape(.capsule)
        .overlay {
            ZStack(alignment: .leading) {
                Capsule()
                    .stroke(Color.gray, lineWidth: 1)
                if let logo = logo {
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
