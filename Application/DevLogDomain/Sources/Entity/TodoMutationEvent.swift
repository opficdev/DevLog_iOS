//
//  TodoMutationEvent.swift
//  DevLogDomain
//
//  Created by opfic on 6/6/26.
//

public enum TodoMutationEvent: Equatable, Sendable {
    case updated(String)
    case deleted(String)
    case restored(String)
}
