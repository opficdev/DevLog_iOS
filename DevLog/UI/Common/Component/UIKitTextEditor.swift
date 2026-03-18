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
    @Environment(\.uiKitTextEditorFocusBinding) private var focusBinding
    @State private var minHeight = TextEditorMetrics.font.lineHeight
    private let placeholder: String

    init(
        text: Binding<String>,
        placeholder: String = ""
    ) {
        self._text = text
        self.placeholder = placeholder
    }

    var body: some View {
        UIKitTextEditorRepresentable(
            text: $text,
            minHeight: $minHeight,
            focusBinding: focusBinding,
            placeholder: placeholder
        )
        .frame(maxWidth: .infinity, minHeight: minHeight)
    }

    // 각 메서드 내에 있는 `.focused()`의 정체
    // 해당 .focused()는 SwiftUI의 모디파이어
    // 이 뷰를 SwiftUI 포커스 시스템에 실제 포커스 타겟으로 등록해주는 역할을 함

    func focused(_ condition: FocusState<Bool>.Binding) -> some View {
        modifier(TextEditorFocusModifier(
            focusBinding: Binding(condition)
        ))
        .focused(condition)
    }

    func focused<Value>(
        _ binding: FocusState<Value>.Binding,
        equals value: Value
    ) -> some View where Value: Hashable & ExpressibleByNilLiteral {
        modifier(TextEditorFocusModifier(
            focusBinding: Binding(
                binding,
                equals: value
            )
        ))
        .focused(binding, equals: value)
    }
}

private enum TextEditorMetrics {
    static let font = UIFont.preferredFont(forTextStyle: .body)
}

private struct TextEditorFocusModifier: ViewModifier {
    let focusBinding: Binding<Bool>

    func body(content: Content) -> some View {
        content
            .environment(\.uiKitTextEditorFocusBinding, focusBinding)
    }
}

private struct TextEditorFocusBindingKey: EnvironmentKey {
    static let defaultValue: Binding<Bool>? = nil
}

private extension EnvironmentValues {
    var uiKitTextEditorFocusBinding: Binding<Bool>? {
        get { self[TextEditorFocusBindingKey.self] }
        set { self[TextEditorFocusBindingKey.self] = newValue }
    }
}

private struct UIKitTextEditorRepresentable: UIViewRepresentable {
    @Binding var text: String
    @Binding var minHeight: CGFloat
    private let focusBinding: Binding<Bool>?
    private let placeholder: String

    init(
        text: Binding<String>,
        minHeight: Binding<CGFloat>,
        focusBinding: Binding<Bool>?,
        placeholder: String
    ) {
        self._text = text
        self.focusBinding = focusBinding
        self._minHeight = minHeight
        self.placeholder = placeholder
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.font = TextEditorMetrics.font
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
            if let focusBinding {
                if focusBinding.wrappedValue {
                    if !uiView.isFirstResponder {
                        context.coordinator.preserveAncestorScrollOffset(for: uiView)
                        uiView.becomeFirstResponder()
                    }
                } else if uiView.isFirstResponder {
                    uiView.resignFirstResponder()
                }
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

            if let focusBinding = parent.focusBinding, !focusBinding.wrappedValue {
                focusBinding.wrappedValue = true
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
            if let focusBinding = parent.focusBinding, focusBinding.wrappedValue {
                focusBinding.wrappedValue = false
            }

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
            let resolvedHeight = max(nextHeight, TextEditorMetrics.font.lineHeight)

            if parent.minHeight != resolvedHeight {
                DispatchQueue.main.async {
                    self.parent.minHeight = resolvedHeight
                }
            }
        }
    }
}

private extension Binding where Value == Bool {
    init(_ binding: FocusState<Bool>.Binding) {
        self.init(
            get: { binding.wrappedValue },
            set: { binding.wrappedValue = $0 }
        )
    }

    init<FocusedValue>(
        _ binding: FocusState<FocusedValue>.Binding,
        equals value: FocusedValue
    ) where FocusedValue: Hashable & ExpressibleByNilLiteral {
        self.init(
            get: {
                binding.wrappedValue == value
            },
            set: { isFocused in
                if isFocused {
                    binding.wrappedValue = value
                } else if binding.wrappedValue == value {
                    binding.wrappedValue = nil
                }
            }
        )
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
