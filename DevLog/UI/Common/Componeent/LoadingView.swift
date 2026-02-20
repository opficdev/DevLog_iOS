//
//  LoadingView.swift
//  DevLog
//
//  Created by opfic on 5/16/25.
//

import SwiftUI

struct LoadingView: View {
    private let isClear: Bool

    init(isClear: Bool = false) {
        self.isClear = isClear
    }

    var body: some View {
        ZStack {
            Color.black.opacity(isClear ? 0 : 0.25).ignoresSafeArea()
            ProgressView()
        }
        .allowsHitTesting(true)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
