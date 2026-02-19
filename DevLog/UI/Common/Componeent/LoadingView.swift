//
//  LoadingView.swift
//  DevLog
//
//  Created by opfic on 5/16/25.
//

import SwiftUI

struct LoadingView: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.25).ignoresSafeArea()
            ProgressView()
        }
        .allowsHitTesting(true)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
