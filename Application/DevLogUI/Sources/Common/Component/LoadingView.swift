//
//  LoadingView.swift
//  DevLogUI
//
//  Created by opfic on 5/16/25.
//

import SwiftUI
import DevLogPresentation

struct LoadingView: View {
    var body: some View {
        ZStack {
            Color.gray.opacity(0.001).ignoresSafeArea()
            ProgressView()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
