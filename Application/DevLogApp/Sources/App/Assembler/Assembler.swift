//
//  Assembler.swift
//  DevLog
//
//  Created by 최윤진 on 12/7/25.
//

import DevLogCore
import DevLogData
import DevLogDomain

final class AppAssembler: Assembler {
    private let assemblers: [Assembler] = [
        PersistenceAssembler(),
        InfraAssembler(),
        DataAssembler(),
        DomainAssembler(),
        AppLayerAssembler()
    ]

    func assemble(_ container: any DIContainer) {
        assemblers.forEach { $0.assemble(container) }
    }
}
