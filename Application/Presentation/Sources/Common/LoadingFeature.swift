//
//  LoadingFeature.swift
//  Presentation
//
//  Created by opfic on 6/11/26.
//

import ComposableArchitecture

@Reducer
struct LoadingFeature {
    @ObservableState
    struct State: Equatable {
        var isLoading = false
        var immediateCountByTarget: [Target: Int] = [:]
        var delayedCountByTarget: [Target: Int] = [:]
        var scheduledDelayedTargets = Set<Target>()
        var visibleDelayedTargets = Set<Target>()
        var visibleTargets = Set<Target>()
    }

    struct Target: Hashable, Sendable {
        static let `default` = Self("default")

        let id: String

        init(_ id: String) {
            self.id = id
        }
    }

    enum Mode: Equatable, Sendable {
        case immediate
        case delayed
    }

    enum Action: Equatable {
        case begin(target: Target, mode: Mode)
        case end(target: Target, mode: Mode)
        case delayedLoadingDidBecomeVisible(target: Target)
    }

    private enum CancelID: Hashable {
        case delayedLoading(Target)
    }

    @Dependency(\.continuousClock) var clock
    private let delay = Duration.seconds(0.3)

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .begin(let target, let mode):
                return begin(target: target, mode: mode, state: &state)
            case .end(let target, let mode):
                return end(target: target, mode: mode, state: &state)
            case .delayedLoadingDidBecomeVisible(let target):
                return delayedLoadingDidBecomeVisible(target: target, state: &state)
            }
        }
    }
}

private extension LoadingFeature {
    func begin(
        target: Target,
        mode: Mode,
        state: inout State
    ) -> Effect<Action> {
        switch mode {
        case .immediate:
            state.immediateCountByTarget[target, default: 0] += 1
            state.setVisibilityIfNeeded(for: target, isVisible: true)
            return .none
        case .delayed:
            state.delayedCountByTarget[target, default: 0] += 1
            return scheduleDelayedLoadingIfNeeded(for: target, state: &state)
        }
    }

    func end(
        target: Target,
        mode: Mode,
        state: inout State
    ) -> Effect<Action> {
        switch mode {
        case .immediate:
            let count = state.immediateCountByTarget[target, default: 0]
            state.immediateCountByTarget[target] = max(0, count - 1)
        case .delayed:
            let count = state.delayedCountByTarget[target, default: 0]
            state.delayedCountByTarget[target] = max(0, count - 1)
        }
        return updateLoadingVisibility(for: target, state: &state)
    }

    func delayedLoadingDidBecomeVisible(
        target: Target,
        state: inout State
    ) -> Effect<Action> {
        state.scheduledDelayedTargets.remove(target)
        guard 0 < state.delayedCountByTarget[target, default: 0] else { return .none }
        state.visibleDelayedTargets.insert(target)
        if state.immediateCountByTarget[target, default: 0] == 0 {
            state.setVisibilityIfNeeded(for: target, isVisible: true)
        }
        return .none
    }

    func scheduleDelayedLoadingIfNeeded(
        for target: Target,
        state: inout State
    ) -> Effect<Action> {
        guard !state.scheduledDelayedTargets.contains(target),
              !state.visibleDelayedTargets.contains(target),
              0 < state.delayedCountByTarget[target, default: 0] else { return .none }
        state.scheduledDelayedTargets.insert(target)
        return .run { [clock, delay] send in
            try await clock.sleep(for: delay)
            await send(.delayedLoadingDidBecomeVisible(target: target))
        }
        .cancellable(id: CancelID.delayedLoading(target), cancelInFlight: true)
    }

    func updateLoadingVisibility(
        for target: Target,
        state: inout State
    ) -> Effect<Action> {
        if 0 < state.immediateCountByTarget[target, default: 0] {
            state.setVisibilityIfNeeded(for: target, isVisible: true)
            return .none
        }
        if state.visibleDelayedTargets.contains(target) {
            if state.delayedCountByTarget[target, default: 0] == 0 {
                state.visibleDelayedTargets.remove(target)
                state.setVisibilityIfNeeded(for: target, isVisible: false)
            } else {
                state.setVisibilityIfNeeded(for: target, isVisible: true)
            }
            return .none
        }
        if 0 < state.delayedCountByTarget[target, default: 0] {
            state.setVisibilityIfNeeded(
                for: target,
                isVisible: state.visibleTargets.contains(target)
            )
            return scheduleDelayedLoadingIfNeeded(for: target, state: &state)
        }
        state.scheduledDelayedTargets.remove(target)
        state.setVisibilityIfNeeded(for: target, isVisible: false)
        return .cancel(id: CancelID.delayedLoading(target))
    }
}

private extension LoadingFeature.State {
    mutating func setVisibilityIfNeeded(
        for target: LoadingFeature.Target,
        isVisible: Bool
    ) {
        if isVisible {
            visibleTargets.insert(target)
        } else {
            visibleTargets.remove(target)
        }

        isLoading = !visibleTargets.isEmpty
    }
}
