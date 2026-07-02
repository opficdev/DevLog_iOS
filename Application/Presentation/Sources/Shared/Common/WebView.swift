//
//  WebView.swift
//  Presentation
//
//  Created by opfic on 5/23/25.
//

import SwiftUI
import WebKit

public struct WebView: UIViewRepresentable {
    let url: URL

    public init(url: URL) {
        self.url = url
    }

    public func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        return webView
    }

    public func updateUIView(_ uiView: WKWebView, context: Context) {
        let request = URLRequest(url: url)
        uiView.load(request)
    }
}
