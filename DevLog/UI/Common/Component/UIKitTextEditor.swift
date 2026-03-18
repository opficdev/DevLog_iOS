//
//  UIKitTextEditor.swift
//  DevLog
//
//  Created by opfic on 3/18/26.
//

import SwiftUI
import UIKit

struct UIKitTextEditor: View {
    @Binding var text: String
    @Binding var isFocused: Bool
    private let placeholder: String
    @State private var minHeight = CGFloat(36)

    init(
        text: Binding<String>,
        isFocused: Binding<Bool>,
        placeholder: String = ""
    ) {
        self._text = text
        self._isFocused = isFocused
        self.placeholder = placeholder
    }

    var body: some View {
        UIKitTextEditorRepresentable(
            text: $text,
            minHeight: $minHeight,
            isFocused: isFocused,
            placeholder: placeholder
        )
        .frame(maxWidth: .infinity, minHeight: minHeight)
    }
}

private struct UIKitTextEditorRepresentable: UIViewRepresentable {
    @Binding var text: String
    @Binding var minHeight: CGFloat
    private let isFocused: Bool
    private let placeholder: String

    init(
        text: Binding<String>,
        minHeight: Binding<CGFloat>,
        isFocused: Bool,
        placeholder: String
    ) {
        self._text = text
        self.isFocused = isFocused
        self._minHeight = minHeight
        self.placeholder = placeholder
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.font = UIFont.preferredFont(forTextStyle: .callout)
        textView.backgroundColor = .clear
        textView.textColor = .label
        textView.tintColor = .tintColor
        textView.textContainer.lineFragmentPadding = 0
        textView.textContainer.widthTracksTextView = true
        textView.textContainer.lineBreakMode = .byWordWrapping
        textView.textContainerInset = .zero
        textView.isScrollEnabled = false
        textView.autocorrectionType = .no
        textView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        textView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        context.coordinator.applyPlaceholderIfNeeded(to: textView)
        return textView
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        context.coordinator.parent = self

        if !context.coordinator.isShowingPlaceholder(in: uiView) && uiView.text != text {
            uiView.text = text
        }

        context.coordinator.applyPlaceholderIfNeeded(to: uiView)

        DispatchQueue.main.async {
            if isFocused {
                if !uiView.isFirstResponder {
                    context.coordinator.preserveAncestorScrollOffset(for: uiView)
                    uiView.becomeFirstResponder()
                }
            } else if uiView.isFirstResponder {
                uiView.resignFirstResponder()
            }
            context.coordinator.updateHeight(for: uiView)
        }
    }

    final class Coordinator: NSObject, UITextViewDelegate {
        var parent: UIKitTextEditorRepresentable
        private weak var ancestorScrollView: UIScrollView?
        private var preservedContentOffset: CGPoint?

        init(_ parent: UIKitTextEditorRepresentable) {
            self.parent = parent
        }

        func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
            preserveAncestorScrollOffset(for: textView)
            return true
        }

        func textViewDidBeginEditing(_ textView: UITextView) {
            if isShowingPlaceholder(in: textView) {
                textView.text = nil
                textView.textColor = .label
            }

            restoreAncestorScrollOffsetIfNeeded()

            DispatchQueue.main.async { [weak self] in
                self?.restoreAncestorScrollOffsetIfNeeded()
                self?.updateHeight(for: textView)
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                self?.restoreAncestorScrollOffsetIfNeeded()
                self?.preservedContentOffset = nil
            }
        }

        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text
            updateHeight(for: textView)
        }

        func textViewDidEndEditing(_ textView: UITextView) {
            applyPlaceholderIfNeeded(to: textView)
        }

        func applyPlaceholderIfNeeded(to textView: UITextView) {
            if parent.text.isEmpty && !textView.isFirstResponder {
                textView.text = parent.placeholder
                textView.textColor = .placeholderText
            } else if isShowingPlaceholder(in: textView) {
                textView.text = parent.text
                textView.textColor = .label
            }
        }

        func isShowingPlaceholder(in textView: UITextView) -> Bool {
            textView.textColor == .placeholderText
        }

        func preserveAncestorScrollOffset(for textView: UITextView) {
            ancestorScrollView = textView.enclosingScrollView
            preservedContentOffset = ancestorScrollView?.contentOffset
        }

        func restoreAncestorScrollOffsetIfNeeded() {
            guard let ancestorScrollView, let preservedContentOffset else { return }

            if ancestorScrollView.contentOffset != preservedContentOffset {
                ancestorScrollView.setContentOffset(preservedContentOffset, animated: false)
            }
        }

        func updateHeight(for textView: UITextView) {
            textView.layoutIfNeeded()

            let width = textView.bounds.width
            guard 0 < width else { return }

            let nextHeight = ceil(textView.sizeThatFits(
                CGSize(width: width, height: .greatestFiniteMagnitude)
            ).height)
            let resolvedHeight = max(nextHeight, 36)

            if parent.minHeight != resolvedHeight {
                DispatchQueue.main.async {
                    self.parent.minHeight = resolvedHeight
                }
            }
        }
    }
}

private extension UIView {
    var enclosingScrollView: UIScrollView? {
        var currentSuperview = superview

        while let view = currentSuperview {
            if let scrollView = view as? UIScrollView {
                return scrollView
            }

            currentSuperview = view.superview
        }

        return nil
    }
}
