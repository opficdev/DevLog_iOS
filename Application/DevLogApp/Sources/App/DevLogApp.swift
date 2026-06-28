//
//  DevLogApp.swift
//  DevLog
//
//  Created by opfic on 5/2/25.
//

import SwiftUI
import DevLogCore
import DevLogData
import DevLogDomain
import DevLogPresentation
import DevLogWidget

@main
struct DevLogApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @Environment(\.diContainer) var container: DIContainer
    @Environment(\.scenePhase) var scenePhase
    @State private var windowEvent = TodoEditorWindowEvent()
    @State private var syncDate = Date()

    init() {
        AppAssembler().assemble(AppDIContainer.shared)
    }

    var body: some Scene {
        WindowGroup {
            RootView(
                sessionUseCase: container.resolve(ObserveAuthSessionUseCase.self),
                networkConnectivityUseCase: container.resolve(ObserveNetworkConnectivityUseCase.self),
                systemThemeUseCase: container.resolve(ObserveSystemThemeUseCase.self),
                trackAnalyticsEventUseCase: container.resolve(TrackAnalyticsEventUseCase.self),
                widgetURLTab: { MainTab(widgetURL: $0) },
                windowEvent: windowEvent,
                pushNotificationTodoIdPublisher: PushNotificationRoute.shared.observe(),
                clearPushNotificationRoute: { PushNotificationRoute.shared.clear() }
            )
            .autocorrectionDisabled()
            .onChange(of: scenePhase) { _, phase in
                guard phase == .background else { return }
                let now = Date()
                let bus = container.resolve(WidgetSyncEventBus.self)

                // 위젯 갱신은 앱 실행 시 로그인 세션 흐름에서 한 번 요청된다. (WidgetSessionSyncHandler.swift:47)
                // Todo 변경 성공 시에는 즉시 fetch하지 않고 WidgetSyncEventBus에 갱신 요청만 남긴다.
                // 따라서 같은 날의 백그라운드 진입은 저장된 요청이 있을 때만 기존 syncRequested 흐름을 실행한다.
                // 앱이 실행된 상태로 날짜가 넘어간 경우에는 Today widget의 분류 기준일 자체가 바뀌므로,
                // 콘텐츠 변경 여부와 관계없이 기존 syncRequested 흐름을 즉시 허용한다.
                guard Calendar.current.isDate(syncDate, inSameDayAs: now) else {
                    syncDate = now
                    _ = bus.confirmRequest()
                    bus.publish(.syncRequested)
                    return
                }

                guard bus.confirmRequest() else { return }
                bus.publish(.syncRequested)
            }
        }
        WindowGroup(id: TodoEditorWindowValue.sceneId, for: TodoEditorWindowValue.self) { value in
            if let value = value.wrappedValue {
                TodoEditorWindowView(
                    value: value,
                    windowEvent: windowEvent
                )
                .autocorrectionDisabled()
            } else {
                ContentUnavailableView(
                    String(localized: "todo_edit"),
                    systemImage: "square.and.pencil"
                )
            }
        }
    }
}
