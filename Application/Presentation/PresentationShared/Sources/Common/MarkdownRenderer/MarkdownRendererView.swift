//
//  MarkdownRendererView.swift
//  PresentationShared
//
//  Created by opfic on 7/25/26.
//

import SwiftUI
import WebKit

struct MarkdownRendererView: UIViewRepresentable {
    let markdown: String
    let references: [Int: MarkdownRendererReference]
    let colorScheme: ColorScheme
    let fontSize: CGFloat
    let obscuredBottomInset: CGFloat
    var onOpenTodoID: ((String) -> Void)?
    var onOpenURL: ((URL) -> Void)?

    func makeCoordinator() -> Coordinator {
        Coordinator(view: self)
    }

    func makeUIView(context: Context) -> WKWebView {
        let contentController = WKUserContentController()

        for name in MarkdownRendererBridge.JavaScriptMessage.Name.allCases {
            contentController.add(
                context.coordinator,
                name: name.rawValue
            )
        }

        let configuration = WKWebViewConfiguration()
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        configuration.userContentController = contentController
        configuration.websiteDataStore = .nonPersistent()

        let webView = WKWebView(
            frame: .zero,
            configuration: configuration
        )
        webView.backgroundColor = .clear
        webView.isOpaque = false
        webView.navigationDelegate = context.coordinator
        webView.scrollView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = true
        webView.scrollView.showsHorizontalScrollIndicator = false
        webView.scrollView.showsVerticalScrollIndicator = true

        context.coordinator.loadRenderer(in: webView)

        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        context.coordinator.update(
            view: self,
            webView: webView
        )
    }

    static func dismantleUIView(
        _ webView: WKWebView,
        coordinator: Coordinator
    ) {
        for name in MarkdownRendererBridge.JavaScriptMessage.Name.allCases {
            webView.configuration.userContentController
                .removeScriptMessageHandler(forName: name.rawValue)
        }

        coordinator.dismantle()
        webView.navigationDelegate = nil
        webView.stopLoading()
    }

    final class Coordinator: NSObject {
        fileprivate let indexURL = MarkdownRendererBundle.indexURL

        private var view: MarkdownRendererView
        private var isRendererLoaded = false
        private var pendingPayload: MarkdownRendererBridge.RenderPayload?
        private var inFlightPayload: MarkdownRendererBridge.RenderPayload?
        private var renderedPayload: MarkdownRendererBridge.RenderPayload?

        init(view: MarkdownRendererView) {
            self.view = view
        }

        fileprivate func loadRenderer(in webView: WKWebView) {
            guard let indexURL else { return }

            webView.loadFileURL(
                indexURL,
                allowingReadAccessTo: indexURL.deletingLastPathComponent()
            )
        }

        fileprivate func update(
            view: MarkdownRendererView,
            webView: WKWebView
        ) {
            self.view = view
            updateObscuredContentInsets(in: webView)
            pendingPayload = MarkdownRendererBridge.RenderPayload(view: view)
            renderIfNeeded(in: webView)
        }

        fileprivate func dismantle() {
            isRendererLoaded = false
            pendingPayload = nil
        }

        private func updateObscuredContentInsets(in webView: WKWebView) {
            guard #available(iOS 26.0, *) else { return }

            var insets = webView.obscuredContentInsets
            insets.bottom = view.obscuredBottomInset
            webView.obscuredContentInsets = insets
        }

        private func renderIfNeeded(in webView: WKWebView) {
            guard
                isRendererLoaded,
                inFlightPayload == nil,
                let payload = pendingPayload
            else {
                return
            }

            guard payload != renderedPayload else {
                pendingPayload = nil
                return
            }

            pendingPayload = nil
            inFlightPayload = payload

            webView.callAsyncJavaScript(
                "window.renderMarkdown(payload)",
                arguments: ["payload": payload.javaScriptValue],
                in: nil,
                in: .page,
                completionHandler: { [weak self, weak webView] result in
                    guard let self else {
                        return
                    }

                    inFlightPayload = nil

                    if case .success = result {
                        renderedPayload = payload
                    }

                    if let webView {
                        renderIfNeeded(in: webView)
                    }
                }
            )
        }

        private func receive(
            _ message: MarkdownRendererBridge.JavaScriptMessage
        ) {
            switch message {
            case .todoReference(let number):
                guard let reference = view.references[number] else {
                    return
                }

                view.onOpenTodoID?(reference.todoID)

            case .externalLink(let value):
                guard let url = MarkdownRendererURLPolicy.externalURL(from: value) else {
                    return
                }

                view.onOpenURL?(url)
            }
        }
    }
}

private extension MarkdownRendererBridge.RenderPayload {
    init(view: MarkdownRendererView) {
        self.init(
            markdown: view.markdown,
            references: view.references,
            colorScheme: view.colorScheme == .dark ? "dark" : "light",
            fontSize: view.fontSize
        )
    }
}

extension MarkdownRendererView.Coordinator: WKScriptMessageHandler {
    func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        guard let javaScriptMessage = MarkdownRendererBridge.JavaScriptMessage(
            name: message.name,
            body: message.body
        ) else {
            return
        }

        receive(javaScriptMessage)
    }
}

extension MarkdownRendererView.Coordinator: WKNavigationDelegate {
    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        isRendererLoaded = false
        pendingPayload = MarkdownRendererBridge.RenderPayload(view: view)
        inFlightPayload = nil
        renderedPayload = nil
        loadRenderer(in: webView)
    }

    func webView(
        _ webView: WKWebView,
        didFinish navigation: WKNavigation?
    ) {
        guard !isRendererLoaded else {
            return
        }

        isRendererLoaded = true
        renderedPayload = nil
        pendingPayload = MarkdownRendererBridge.RenderPayload(view: view)
        renderIfNeeded(in: webView)
    }

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.cancel)
            return
        }

        if let indexURL,
           MarkdownRendererURLPolicy.allowsRendererNavigation(
               url,
               indexURL: indexURL
           ) {
            decisionHandler(.allow)
            return
        }

        if navigationAction.navigationType == .linkActivated,
           let url = MarkdownRendererURLPolicy.externalURL(
               from: url.absoluteString
           ) {
            view.onOpenURL?(url)
        }

        decisionHandler(.cancel)
    }
}
