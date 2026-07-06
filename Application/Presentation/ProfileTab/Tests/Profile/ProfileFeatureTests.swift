//
//  ProfileFeatureTests.swift
//  ProfileTabTests
//
//  Created by opfic on 6/11/26.
//

import Testing
import PresentationShared
import Foundation
import Core
import Domain
@testable import ProfileTab

@MainActor
struct ProfileFeatureTests {
    @Test("ProfileFeature는 같은 아바타 URL을 다시 받아도 프로필 이미지 데이터를 다시 요청한다")
    func ProfileFeature는_같은_아바타_URL을_다시_받아도_프로필_이미지_데이터를_다시_요청한다() async {
        let imageData = Data([1, 2, 3])
        let spy = FetchProfileImageDataUseCaseSpy(data: imageData)
        let adapter = ProfileStoreTestAdapter(fetchProfileImageDataUseCase: spy)
        let avatarURL = URL(string: "https://example.com/avatar.png")!
        let profile = UserProfile(
            name: "opfic",
            email: "opfic@example.com",
            statusMessage: "status",
            avatarURL: avatarURL,
            createdAt: Date(timeIntervalSince1970: 0)
        )

        await adapter.fetchUserData(profile)
        await adapter.fetchUserData(profile)

        #expect(spy.calledURLs == [avatarURL, avatarURL])
        #expect(adapter.avatarImageData?.data == imageData)
    }

    @Test("ProfileFeature는 연결 상태일 때 상태 메시지 저장을 요청한다")
    func ProfileFeature는_연결_상태일_때_상태_메시지_저장을_요청한다() async {
        let spy = UpsertStatusMessageUseCaseSpy()
        let adapter = ProfileStoreTestAdapter(upsertStatusMessageUseCase: spy)

        await adapter.updateStatusMessage("working")
        await adapter.willUpdateStatusMessage()

        #expect(spy.messages == ["working"])
    }

    @Test("ProfileFeature는 마지막 활동 종류를 해제하지 않는다")
    func ProfileFeature는_마지막_활동_종류를_해제하지_않는다() async {
        let spy = UpdateHeatmapActivityTypesUseCaseSpy()
        let fetchSpy = FetchHeatmapActivityTypesUseCaseSpy()
        fetchSpy.activityTypes = ["created"]
        let adapter = ProfileStoreTestAdapter(
            fetchHeatmapActivityTypesUseCase: fetchSpy,
            updateHeatmapActivityTypesUseCase: spy
        )

        await adapter.fetchData()
        await adapter.toggleActivityKind(.created)

        #expect(adapter.selectedActivityKinds == [.created])
        #expect(spy.activityTypes.isEmpty)
    }
}

private final class FetchTodosUseCaseSpy: FetchTodosUseCase {
    var todoPage = TodoPage(items: [], nextCursor: nil)
    private(set) var queries: [TodoQuery] = []

    func execute(_ query: TodoQuery, cursor: TodoCursor?) async throws -> TodoPage {
        queries.append(query)
        return todoPage
    }
}

private final class FetchUserDataUseCaseSpy: FetchUserDataUseCase {
    var profile: UserProfile

    init(profile: UserProfile) {
        self.profile = profile
    }

    func execute() async throws -> UserProfile {
        profile
    }
}

private final class FetchProfileImageDataUseCaseSpy: FetchProfileImageDataUseCase {
    var data: Data
    private(set) var calledURLs: [URL] = []

    init(data: Data) {
        self.data = data
    }

    func execute(from url: URL) async throws -> Data {
        calledURLs.append(url)
        return data
    }
}

private final class UpsertStatusMessageUseCaseSpy: UpsertStatusMessageUseCase {
    private(set) var messages: [String] = []

    func execute(_ message: String) async throws {
        messages.append(message)
    }
}

private final class FetchHeatmapActivityTypesUseCaseSpy: FetchHeatmapActivityTypesUseCase {
    var activityTypes: [String] = []

    func execute() -> [String] {
        activityTypes
    }
}

private final class UpdateHeatmapActivityTypesUseCaseSpy: UpdateHeatmapActivityTypesUseCase {
    private(set) var activityTypes: [[String]] = []

    func execute(_ activityTypes: [String]) {
        self.activityTypes.append(activityTypes)
    }
}

@MainActor
private struct ProfileStoreTestAdapter {
    private let store: TestStoreOf<ProfileFeature>

    var avatarImageData: ProfileAvatarImageData? { store.state.avatarImageData }
    var selectedActivityKinds: Set<ActivityKind> { store.state.selectedActivityKinds }

    init(
        fetchProfileImageDataUseCase: FetchProfileImageDataUseCase = FetchProfileImageDataUseCaseSpy(data: Data()),
        upsertStatusMessageUseCase: UpsertStatusMessageUseCase = UpsertStatusMessageUseCaseSpy(),
        fetchHeatmapActivityTypesUseCase: FetchHeatmapActivityTypesUseCase = FetchHeatmapActivityTypesUseCaseSpy(),
        updateHeatmapActivityTypesUseCase: UpdateHeatmapActivityTypesUseCase = UpdateHeatmapActivityTypesUseCaseSpy()
    ) {
        store = TestStore(initialState: ProfileFeature.State()) {
            ProfileFeature()
        } withDependencies: {
            $0.profileFetchUserDataUseCase = FetchUserDataUseCaseSpy(
                profile: UserProfile(
                    name: "opfic",
                    email: "opfic@example.com",
                    statusMessage: "",
                    avatarURL: nil,
                    createdAt: Date(timeIntervalSince1970: 0)
                )
            )
            $0.profileFetchImageDataUseCase = fetchProfileImageDataUseCase
            $0.profileFetchTodosUseCase = FetchTodosUseCaseSpy()
            $0.profileUpsertStatusMessageUseCase = upsertStatusMessageUseCase
            $0.networkConnectivityUseCase = ObserveNetworkConnectivityUseCaseSpy()
            $0.profileFetchHeatmapActivityTypesUseCase = fetchHeatmapActivityTypesUseCase
            $0.profileUpdateHeatmapActivityTypesUseCase = updateHeatmapActivityTypesUseCase
            $0.continuousClock = ImmediateClock()
        }
        store.exhaustivity = .off(showSkippedAssertions: false)
    }

    func fetchData() async {
        await store.send(.fetchData)
        await drainReceivedActions()
    }

    func fetchUserData(_ profile: UserProfile) async {
        await store.send(.store(.fetchUserData(profile)))
        await drainReceivedActions()
    }

    func updateStatusMessage(_ message: String) async {
        await store.send(.binding(.set(\.statusMessage, message))) {
            $0.statusMessage = message
        }
    }

    func willUpdateStatusMessage() async {
        await store.send(.willUpdateStatusMessage)
        await drainReceivedActions()
    }

    func toggleActivityKind(_ activityKind: ActivityKind) async {
        switch activityKind {
        case .created:
            await store.send(.binding(.set(\.isCreatedActivitySelected, !store.state.isCreatedActivitySelected))) {
                $0.isCreatedActivitySelected.toggle()
            }
        case .completed:
            await store.send(.binding(.set(\.isCompletedActivitySelected, !store.state.isCompletedActivitySelected))) {
                $0.isCompletedActivitySelected.toggle()
            }
        case .deleted:
            await store.send(.binding(.set(\.isDeletedActivitySelected, !store.state.isDeletedActivitySelected))) {
                $0.isDeletedActivitySelected.toggle()
            }
        }
        await drainReceivedActions()
    }

    private func drainReceivedActions() async {
        for _ in 0..<10 {
            await store.skipReceivedActions(strict: false)
        }
    }
}
