//
//  LoadingState.swift
//  PresentationShared
//
//  Created by opfic on 3/16/26.
//

import Foundation

@MainActor
public final class LoadingState {
    private enum DefaultTarget: Hashable {
        case value
    }

    public enum Mode {
        case immediate
        case delayed
    }

    private let delay: Duration
    private var immediateCountByTarget: [AnyHashable: Int] = [:]
    private var delayedCountByTarget: [AnyHashable: Int] = [:]
    private var delayedTaskByTarget: [AnyHashable: Task<Void, Never>] = [:]
    private var visibleDelayedTargets = Set<AnyHashable>()
    private var visibleTargets = Set<AnyHashable>()

    public nonisolated init(delay: Duration = .seconds(0.3)) {
        self.delay = delay
    }

    public func begin(
        mode: Mode,
        update: @escaping @MainActor (Bool) -> Void
    ) {
        begin(target: DefaultTarget.value, mode: mode) { _, isLoading in
            update(isLoading)
        }
    }

    public func begin<T: Hashable>(
        target: T,
        mode: Mode,
        update: @escaping @MainActor (T, Bool) -> Void
    ) {
        let hashableTarget = AnyHashable(target)
        begin(target: hashableTarget, mode: mode) { isLoading in
            update(target, isLoading)
        }
    }

    public func end(
        mode: Mode,
        update: @escaping @MainActor (Bool) -> Void
    ) {
        end(target: DefaultTarget.value, mode: mode) { _, isLoading in
            update(isLoading)
        }
    }

    public func end<T: Hashable>(
        target: T,
        mode: Mode,
        update: @escaping @MainActor (T, Bool) -> Void
    ) {
        let hashableTarget = AnyHashable(target)
        end(target: hashableTarget, mode: mode) { isLoading in
            update(target, isLoading)
        }
    }

    private func begin(
        target: AnyHashable,
        mode: Mode,
        update: @escaping @MainActor (Bool) -> Void
    ) {
        switch mode {
        case .immediate:
            immediateCountByTarget[target, default: 0] += 1
            setVisibilityIfNeeded(for: target, isVisible: true, update: update)
        case .delayed:
            delayedCountByTarget[target, default: 0] += 1
            scheduleDelayedLoadingIfNeeded(for: target, update: update)
        }
    }

    private func end(
        target: AnyHashable,
        mode: Mode,
        update: @escaping @MainActor (Bool) -> Void
    ) {
        switch mode {
        case .immediate:
            let count = immediateCountByTarget[target, default: 0]
            immediateCountByTarget[target] = max(0, count - 1)
        case .delayed:
            let count = delayedCountByTarget[target, default: 0]
            delayedCountByTarget[target] = max(0, count - 1)
        }
        updateLoadingVisibility(for: target, update: update)
    }

    private func scheduleDelayedLoadingIfNeeded(
        for target: AnyHashable,
        update: @escaping @MainActor (Bool) -> Void
    ) {
        guard delayedTaskByTarget[target] == nil,
              !visibleDelayedTargets.contains(target),
              0 < delayedCountByTarget[target, default: 0] else { return }
        delayedTaskByTarget[target] = Task { [weak self] in
            guard let self else { return }
            try? await Task.sleep(for: delay)
            if Task.isCancelled { return }
            await MainActor.run {
                self.delayedTaskByTarget[target] = nil
                guard 0 < self.delayedCountByTarget[target, default: 0] else { return }
                self.visibleDelayedTargets.insert(target)
                if self.immediateCountByTarget[target, default: 0] == 0 {
                    self.setVisibilityIfNeeded(for: target, isVisible: true, update: update)
                }
            }
        }
    }

    private func updateLoadingVisibility(
        for target: AnyHashable,
        update: @escaping @MainActor (Bool) -> Void
    ) {
        if 0 < immediateCountByTarget[target, default: 0] {
            setVisibilityIfNeeded(for: target, isVisible: true, update: update)
            return
        }
        if visibleDelayedTargets.contains(target) {
            if delayedCountByTarget[target, default: 0] == 0 {
                visibleDelayedTargets.remove(target)
                setVisibilityIfNeeded(for: target, isVisible: false, update: update)
            } else {
                setVisibilityIfNeeded(for: target, isVisible: true, update: update)
            }
            return
        }
        if 0 < delayedCountByTarget[target, default: 0] {
            if visibleTargets.contains(target) {
                setVisibilityIfNeeded(for: target, isVisible: true, update: update)
            } else {
                setVisibilityIfNeeded(for: target, isVisible: false, update: update)
            }
            scheduleDelayedLoadingIfNeeded(for: target, update: update)
            return
        }
        delayedTaskByTarget[target]?.cancel()
        delayedTaskByTarget[target] = nil
        setVisibilityIfNeeded(for: target, isVisible: false, update: update)
    }

    private func setVisibilityIfNeeded(
        for target: AnyHashable,
        isVisible: Bool,
        update: @escaping @MainActor (Bool) -> Void
    ) {
        let wasVisible = visibleTargets.contains(target)

        if isVisible {
            visibleTargets.insert(target)
        } else {
            visibleTargets.remove(target)
        }

        if wasVisible != isVisible {
            update(isVisible)
        }
    }
}
