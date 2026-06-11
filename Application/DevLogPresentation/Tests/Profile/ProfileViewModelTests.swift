//
//  ProfileViewModelTests.swift
//  DevLogPresentationTests
//
//  Created by opfic on 6/11/26.
//

import Testing
import Foundation
import DevLogDomain
@testable import DevLogPresentation

@MainActor
struct ProfileViewModelTests {
    @Test("같은 아바타 URL을 다시 받아도 프로필 이미지 데이터를 다시 요청한다")
    func 같은_아바타_URL을_다시_받아도_프로필_이미지_데이터를_다시_요청한다() async {
        let imageData = Data([1, 2, 3])
        let spy = FetchProfileImageDataUseCaseSpy(data: imageData)
        let viewModel = makeProfileViewModel(fetchProfileImageDataUseCase: spy)
        let avatarURL = URL(string: "https://example.com/avatar.png")!
        let profile = UserProfile(
            name: "opfic",
            email: "opfic@example.com",
            statusMessage: "status",
            avatarURL: avatarURL,
            createdAt: Date(timeIntervalSince1970: 0)
        )

        viewModel.send(.fetchUserData(profile))
        await waitUntil {
            spy.calledURLs == [avatarURL]
        }

        viewModel.send(.fetchUserData(profile))
        await waitUntil {
            spy.calledURLs == [avatarURL, avatarURL]
        }

        #expect(spy.calledURLs == [avatarURL, avatarURL])
        #expect(viewModel.state.avatarImageData?.data == imageData)
    }
}

@MainActor
private func makeProfileViewModel(
    fetchProfileImageDataUseCase: FetchProfileImageDataUseCase
) -> ProfileViewModel {
    ProfileViewModel(
        fetchUserDataUseCase: FetchUserDataUseCaseSpy(
            profile: UserProfile(
                name: "opfic",
                email: "opfic@example.com",
                statusMessage: "",
                avatarURL: nil,
                createdAt: Date(timeIntervalSince1970: 0)
            )
        ),
        fetchProfileImageDataUseCase: fetchProfileImageDataUseCase,
        fetchTodosUseCase: FetchTodosUseCaseSpy(),
        upsertStatusMessageUseCase: UpsertStatusMessageUseCaseSpy(),
        networkConnectivityUseCase: ObserveNetworkConnectivityUseCaseSpy(),
        fetchHeatmapActivityTypesUseCase: FetchHeatmapActivityTypesUseCaseSpy(),
        updateHeatmapActivityTypesUseCase: UpdateHeatmapActivityTypesUseCaseSpy()
    )
}
