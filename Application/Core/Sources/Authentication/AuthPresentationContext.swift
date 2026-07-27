//
//  AuthPresentationContext.swift
//  Core
//
//  Created by opfic on 7/27/26.
//

public struct AuthPresentationContext: Equatable, Sendable {
    public let identifier: String

    // 인증 호출 경로에서 같은 key로 접근하되 실제 값은 각 Task에 격리하기 위한 정적 변수
    @TaskLocal public static var current: Self?

    public init(identifier: String) {
        self.identifier = identifier
    }
}
