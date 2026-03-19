//
//  AppLayerAssembler.swift
//  DevLog
//
//  Created by opfic on 3/19/26.
//

final class AppLayerAssembler: Assembler {
    func assemble(_ container: any DIContainer) {
        container.register(FCMTokenSyncHandler.self) {
            FCMTokenSyncHandler(
                repository: container.resolve(UserDataRepository.self)
            )
        }
        container.register(UserTimeZoneSyncHandler.self) {
            UserTimeZoneSyncHandler(
                repository: container.resolve(UserDataRepository.self)
            )
        }
    }
}
