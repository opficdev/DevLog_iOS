//
//  AppAssembler.swift
//  DevLog
//
//  Created by 최윤진 on 12/7/25.
//

import Core
import Data
import Domain
import Infra
import Persistence
import Widget

final class AppAssembler: Assembler {
    private let assemblers: [Assembler] = [
        PersistenceAssembler(),
        InfraAssembler(),
        WidgetAssembler(),
        DataAssembler(),
        DomainAssembler(),
        AppLayerAssembler()
    ]

    func assemble(_ container: any DIContainer) {
        assemblers.forEach { $0.assemble(container) }
    }
}
