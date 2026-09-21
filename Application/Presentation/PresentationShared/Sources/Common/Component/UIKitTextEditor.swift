//
//  UIKitTextEditor.swift
//  PresentationShared
//
//  Created by opfic on 3/18/26.
//

import SwiftUI
import UIComposable

final class UIKitTextEditor: UITextView, UICoordinatedComposable {
    var textBinding: Binding<String>?
    var isEditorFocused = false
    var onFocusChange: ((Bool) -> Void)?
    var placeholder = ""

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func connect(coordinator: Coordinator) {
        delegate = coordinator
        coordinator.textView = self
        configureAppearance()
    }

    func update(coordinator: Coordinator) {
        coordinator.update()
    }

    func disconnect(coordinator: Coordinator) {
        if delegate === coordinator {
            delegate = nil
        }
        coordinator.disconnect()
    }

    func updateInput(
        text: Binding<String>,
        isFocused: Bool,
        onFocusChange: @escaping (Bool) -> Void,
        placeholder: String
    ) {
        textBinding = text
        isEditorFocused = isFocused
        self.onFocusChange = onFocusChange
        self.placeholder = placeholder
    }

    static func fittingSize(
        proposal: ProposedViewSize,
        textEditor: UIKitTextEditor
    ) -> CGSize? {
        guard let width = proposal.width else { return nil }

        let size = textEditor.sizeThatFits(
            CGSize(width: width, height: .greatestFiniteMagnitude)
        )
        return CGSize(width: width, height: size.height)
    }

    private func configureAppearance() {
        font = UIFont.preferredFont(forTextStyle: .body)
        backgroundColor = .clear
        textColor = .label
        tintColor = .tintColor
        textContainer.lineFragmentPadding = 0
        textContainer.widthTracksTextView = true
        textContainer.lineBreakMode = .byWordWrapping
        textContainerInset = .zero
        isScrollEnabled = false
        autocorrectionType = .no
        setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        setContentHuggingPriority(.defaultLow, for: .horizontal)
    }

    final class Coordinator: NSObject, UITextViewDelegate {
        weak var textView: UIKitTextEditor?
        private weak var scrollView: UIScrollView?
        private var offsetObservation: NSKeyValueObservation?
        private var trackedOffset: CGPoint?
        private var isRestoringOffset = false

        func update() {
            guard let textView, let textBinding = textView.textBinding else { return }

            if !isShowingPlaceholder(in: textView) && textView.text != textBinding.wrappedValue {
                textView.text = textBinding.wrappedValue
            }

            applyPlaceholderIfNeeded(to: textView)

            DispatchQueue.main.async { [weak self, weak textView] in
                guard let self, let textView else { return }

                if textView.isEditorFocused {
                    if !textView.isFirstResponder {
                        self.startTrackingOffset(for: textView)
                        textView.becomeFirstResponder()
                    }
                } else if textView.isFirstResponder {
                    textView.resignFirstResponder()
                }
            }
        }

        func disconnect() {
            stopTrackingOffset()
            textView = nil
        }

        func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
            startTrackingOffset(for: textView)
            return true
        }

        func textViewDidBeginEditing(_ textView: UITextView) {
            guard let textView = textView as? UIKitTextEditor else { return }

            if isShowingPlaceholder(in: textView) {
                textView.text = nil
                textView.textColor = .label
            }

            if !textView.isEditorFocused {
                textView.isEditorFocused = true
                textView.onFocusChange?(true)
            }

            restoreOffsetIfNeeded()

            DispatchQueue.main.async { [weak self] in
                self?.restoreOffsetIfNeeded()
            }
        }

        func textViewDidChange(_ textView: UITextView) {
            guard let textView = textView as? UIKitTextEditor else { return }

            stopTrackingOffset()
            textView.textBinding?.wrappedValue = textView.text
        }

        func textViewDidEndEditing(_ textView: UITextView) {
            guard let textView = textView as? UIKitTextEditor else { return }

            if textView.isEditorFocused {
                textView.isEditorFocused = false
                textView.onFocusChange?(false)
            }

            stopTrackingOffset()
            applyPlaceholderIfNeeded(to: textView)
        }

        func applyPlaceholderIfNeeded(to textView: UIKitTextEditor) {
            guard let textBinding = textView.textBinding else { return }

            if textBinding.wrappedValue.isEmpty && !textView.isFirstResponder {
                textView.text = textView.placeholder
                textView.textColor = .placeholderText
            } else if isShowingPlaceholder(in: textView) {
                textView.text = textBinding.wrappedValue
                textView.textColor = .label
            }
        }

        func isShowingPlaceholder(in textView: UITextView) -> Bool {
            textView.textColor == .placeholderText
        }

        func startTrackingOffset(for textView: UITextView) {
            stopObservingOffset()
            scrollView = textView.enclosingScrollView
            trackedOffset = scrollView?.contentOffset
            observeOffsetIfNeeded()
        }

        func restoreOffsetIfNeeded() {
            guard let scrollView, let trackedOffset else { return }

            if scrollView.contentOffset != trackedOffset {
                isRestoringOffset = true
                scrollView.setContentOffset(trackedOffset, animated: false)
                isRestoringOffset = false
            }
        }

        func observeOffsetIfNeeded() {
            guard let scrollView else { return }

            offsetObservation = scrollView.observe(
                \.contentOffset,
                options: [.new]
            ) { [weak self] scrollView, _ in
                self?.handleOffsetChange(in: scrollView)
            }
        }

        func handleOffsetChange(in scrollView: UIScrollView) {
            guard let trackedOffset else {
                stopObservingOffset()
                return
            }

            if scrollView.isTracking || scrollView.isDragging || scrollView.isDecelerating {
                stopTrackingOffset()
                return
            }

            if isRestoringOffset {
                return
            }

            if scrollView.contentOffset != trackedOffset {
                restoreOffsetIfNeeded()
            }
        }

        func stopObservingOffset() {
            offsetObservation?.invalidate()
            offsetObservation = nil
        }

        func stopTrackingOffset() {
            stopObservingOffset()
            scrollView = nil
            trackedOffset = nil
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
