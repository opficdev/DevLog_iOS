//
//  View+SwipeViews.swift
//  PresentationShared
//
//  Created by opfic on 9/23/26.
//

import SwiftUI
import ComposableArchitecture

public extension View {
    func swipeViews<Views: View>(@ViewBuilder content: () -> Views) -> some View {
        modifier(SwipeViewsModifier(views: content()))
    }
}

private struct SwipeViewsModifier<Views: View>: ViewModifier {
    @State private var store = Store(initialState: SwipeViewsFeature.State()) {
        SwipeViewsFeature()
    }
    let views: Views

    func body(content: Content) -> some View {
        let trayWidth = store.trayWidth

        ZStack(alignment: .trailing) {
            Group(subviews: views) { subviews in
                HStack(spacing: 8) {
                    ForEach(subviews) { subview in
                        subview
                            .background {
                                GeometryReader { geometry in
                                    Color.clear.preference(
                                        key: SwipeViewWidthsPreferenceKey.self,
                                        value: [geometry.size.width]
                                    )
                                }
                            }
                    }
                }
            }
            .buttonStyle(SwipeViewButtonStyle())
            .padding(.leading, 12)
            .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { width in
                store.send(.view(.setTrayWidth(width)))
            }
            .onPreferenceChange(SwipeViewWidthsPreferenceKey.self) { widths in
                store.send(.view(.setViewWidths(widths)))
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            .allowsHitTesting(store.isRevealed && !store.isDragging)
            .simultaneousGesture(TapGesture().onEnded {
                withAnimation(.snappy) {
                    store.send(.view(.close))
                }
            })

            content
                .offset(x: max(
                    -trayWidth,
                    min(0, (store.isRevealed ? -trayWidth : 0) + store.dragTranslation)
                ))
                .highPriorityGesture(
                    TapGesture().onEnded {
                        withAnimation(.snappy) {
                            store.send(.view(.close))
                        }
                    },
                    including: store.isRevealed ? .all : .none
                )
                .simultaneousGesture(
                    DragGesture(minimumDistance: 12)
                        .onChanged { value in
                            store.send(.view(.changed(value.translation)))
                        }
                        .onEnded { value in
                            withAnimation(.snappy) {
                                store.send(.view(.ended(value.translation.width)))
                            }
                        }
                )
        }
        .clipped()
    }
}

private struct SwipeViewButtonStyle: ButtonStyle {
    @ScaledMetric(relativeTo: .body) private var width = 88
    @ScaledMetric(relativeTo: .body) private var height = 44

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.callout)
            .foregroundStyle(Color.white)
            .frame(width: width, height: height)
            .background(
                configuration.role == .destructive ? Color.red : Color.accent,
                in: Capsule()
            )
    }
}

private struct SwipeViewWidthsPreferenceKey: PreferenceKey {
    static var defaultValue = [CGFloat]()

    static func reduce(value: inout [CGFloat], nextValue: () -> [CGFloat]) {
        value.append(contentsOf: nextValue())
    }
}

@Reducer
private struct SwipeViewsFeature {
    @ObservableState
    struct State: Equatable {
        var trayWidth = CGFloat.zero
        var viewWidths = [CGFloat]()
        var isRevealed = false
        var isDragging = false
        var isScrolling = false
        var dragTranslation = CGFloat.zero
    }

    enum Action {
        case view(ViewAction)

        enum ViewAction {
            case setTrayWidth(CGFloat)
            case setViewWidths([CGFloat])
            case changed(CGSize)
            case ended(CGFloat)
            case close
        }
    }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .view(.setTrayWidth(let width)):
                state.trayWidth = width
            case .view(.setViewWidths(let widths)):
                state.viewWidths = widths
            case .view(.changed(let translation)):
                guard !state.isScrolling else { return .none }
                if !state.isDragging {
                    if abs(translation.width) <= abs(translation.height) {
                        state.isScrolling = true
                        return .none
                    }
                    state.isDragging = true
                }
                state.dragTranslation = translation.width
            case .view(.ended(let translation)):
                if state.isScrolling {
                    state.isScrolling = false
                    return .none
                }
                guard state.isDragging else { return .none }
                let wasRevealed = state.isRevealed
                let base = wasRevealed ? -state.trayWidth : 0
                let releasedOffset = max(-state.trayWidth, min(0, base + translation))
                let revealedWidth = -releasedOffset
                if wasRevealed {
                    var fullyHiddenCount = 0
                    var trailingDistance = CGFloat.zero
                    for width in state.viewWidths.reversed() {
                        if revealedWidth <= trailingDistance {
                            fullyHiddenCount += 1
                        }
                        trailingDistance += width + 8
                    }
                    let requiredHiddenCount = (state.viewWidths.count + 1) / 2
                    state.isRevealed = !state.viewWidths.isEmpty
                        && fullyHiddenCount < requiredHiddenCount
                } else {
                    let firstVisibleWidth = state.viewWidths.last ?? 0
                    state.isRevealed = 0 < firstVisibleWidth
                        && firstVisibleWidth / 2 <= revealedWidth
                }
                state.isDragging = false
                state.dragTranslation = 0
            case .view(.close):
                state.isRevealed = false
            }
            return .none
        }
    }
}
