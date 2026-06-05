//
//  StorePattern.swift
//  DevLogPresentation
//
//  Created by 최윤진 on 11/22/25.
//

import Foundation
import DevLogDomain

@MainActor
public protocol StorePattern: AnyObject {
    associatedtype State
    associatedtype Action
    associatedtype SideEffect

    var state: State { get }
    func send(_ action: Action)
    func reduce(with action: Action) -> [SideEffect]
    func run(_ effect: SideEffect)
}

extension StorePattern {
    func send(_ action: Action) {
        let sideEffects = reduce(with: action)
        sideEffects.forEach(run)
    }

    func reduce(with action: Action) -> [SideEffect] {
        return []
    }

    func run(_ effect: SideEffect) { }
}
