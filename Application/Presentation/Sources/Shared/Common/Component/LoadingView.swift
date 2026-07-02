//
//  LoadingView.swift
//  PresentationShared
//
//  Created by opfic on 5/16/25.
//

import SwiftUI

public struct LoadingView: View {
    public init() {}

    public var body: some View {
        ZStack {
            Color.gray.opacity(0.001).ignoresSafeArea()
            ProgressView()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
