//
//  GoalDetailFeatureTests.swift
//  DevelopmentTests
//
//  Created by opfic on 9/13/26.
//

import Testing
import Foundation
import PresentationShared
@testable import Development

@MainActor
struct GoalDetailFeatureTests {
    @Test("타임라인은 생성 순서로 기록을 정렬하고 최신 확정 버전을 구성한다")
    func 타임라인은_생성_순서로_기록을_정렬하고_최신_확정_버전을_구성한다() async throws {
        let goal = try makeDevelopmentGoal(title: "개발 목표와 기록 이력 구성")
        let confirmedRecord = try makeConfirmedDevelopmentRecord(id: "confirmed")
        let draftRecord = try makeDevelopmentRecord(
            id: "draft",
            createdAt: Date(timeIntervalSince1970: 1_700_000_300)
        )
        let version = try makeDevelopmentRecordVersion(recordId: confirmedRecord.id)
        let items = [
            RecordTimelineItem(record: confirmedRecord, currentVersion: version),
            RecordTimelineItem(record: draftRecord, currentVersion: nil)
        ]
        let store = TestStore(
            initialState: GoalDetailFeature.State(goalId: goal.id)
        ) {
            GoalDetailFeature()
        } withDependencies: {
            $0.developmentFetchGoalUseCase = FetchDevelopmentGoalUseCaseStub(result: .success(goal))
            $0.developmentFetchRecordsUseCase = FetchDevelopmentRecordsUseCaseStub(
                result: .success([draftRecord, confirmedRecord])
            )
            $0.developmentFetchRecordVersionUseCase = FetchDevelopmentRecordVersionUseCaseStub(
                resultByRecordId: [confirmedRecord.id: .success(version)]
            )
        }

        await store.send(.view(.fetch)) {
            $0.isLoading = true
        }
        await store.receive(.store(.loaded(goalTitle: goal.title, items: items))) {
            $0.goalTitle = goal.title
            $0.items = items
            $0.isLoading = false
            $0.hasLoaded = true
        }
    }

    @Test("타임라인 새로고침은 변경된 현재 버전을 반영한다")
    func 타임라인_새로고침은_변경된_현재_버전을_반영한다() async throws {
        let goal = try makeDevelopmentGoal()
        let previousVersion = try makeDevelopmentRecordVersion(id: "version-1")
        let currentVersion = try makeDevelopmentRecordVersion(
            id: "version-2",
            number: 2,
            title: "변경된 기록",
            kind: .correction,
            sourceVersionId: previousVersion.id
        )
        let previousRecord = try makeConfirmedDevelopmentRecord(versionId: previousVersion.id)
        let currentRecord = try makeConfirmedDevelopmentRecord(
            versionId: currentVersion.id,
            versionNumber: currentVersion.number
        )
        let previousItem = RecordTimelineItem(
            record: previousRecord,
            currentVersion: previousVersion
        )
        let currentItem = RecordTimelineItem(
            record: currentRecord,
            currentVersion: currentVersion
        )
        var state = GoalDetailFeature.State(goalId: goal.id)
        state.goalTitle = goal.title
        state.items = [previousItem]
        state.hasLoaded = true
        let store = TestStore(initialState: state) {
            GoalDetailFeature()
        } withDependencies: {
            $0.developmentFetchGoalUseCase = FetchDevelopmentGoalUseCaseStub(result: .success(goal))
            $0.developmentFetchRecordsUseCase = FetchDevelopmentRecordsUseCaseStub(
                result: .success([currentRecord])
            )
            $0.developmentFetchRecordVersionUseCase = FetchDevelopmentRecordVersionUseCaseStub(
                resultByRecordId: [currentRecord.id: .success(currentVersion)]
            )
        }

        await store.send(.view(.refresh)) {
            $0.isLoading = true
        }
        await store.receive(.store(.loaded(goalTitle: goal.title, items: [currentItem]))) {
            $0.items = [currentItem]
            $0.isLoading = false
        }
    }

    @Test("타임라인 조회 실패는 입력 가능한 재조회 상태를 유지한다")
    func 타임라인_조회_실패는_입력_가능한_재조회_상태를_유지한다() async throws {
        let goal = try makeDevelopmentGoal()
        let store = TestStore(
            initialState: GoalDetailFeature.State(goalId: goal.id)
        ) {
            GoalDetailFeature()
        } withDependencies: {
            $0.developmentFetchGoalUseCase = FetchDevelopmentGoalUseCaseStub(result: .success(goal))
            $0.developmentFetchRecordsUseCase = FetchDevelopmentRecordsUseCaseStub(
                result: .failure(RecordTestError.failed)
            )
            $0.developmentFetchRecordVersionUseCase = FetchDevelopmentRecordVersionUseCaseStub(
                resultByRecordId: [:]
            )
        }

        await store.send(.view(.fetch)) {
            $0.isLoading = true
        }
        await store.receive(.store(.failed)) {
            $0.isLoading = false
            $0.hasLoadFailure = true
            $0.alert = makeRecordErrorAlert("development_record_timeline_error_message")
        }
        await store.send(.view(.refresh)) {
            $0.isLoading = true
            $0.hasLoadFailure = false
        }
        await store.receive(.store(.failed)) {
            $0.isLoading = false
            $0.hasLoadFailure = true
        }
    }
}
