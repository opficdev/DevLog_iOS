//
//  InfraAssembler.swift
//  DevLog
//
//  Created by 최윤진 on 12/7/25.
//

final class InfraAssembler: Assembler {
    func assemble(_ container: any DIContainer) {
        container.register(AuthService.self) {
            AuthService()
        }

        container.register(TodoService.self) {
            TodoService()
        }
    }
}
