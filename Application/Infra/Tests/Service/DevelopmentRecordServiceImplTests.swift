//
//  DevelopmentRecordServiceImplTests.swift
//  InfraTests
//
//  Created by opfic on 8/28/26.
//

import Foundation
import Testing
import FirebaseFirestore
import Data
@testable import Infra

struct DevelopmentRecordServiceImplTests {
    @Test("최초 확정은 첫 버전과 초안 내용을 만든다")
    func 최초_확정은_첫_버전과_초안_내용을_만든다() {
        let mutation = DevelopmentRecordServiceImpl.makeConfirmationMutation(
            recordData: makeRecordData(draftBaseVersionId: nil),
            request: .init(versionId: "version-1", kind: "initial", sourceVersionId: nil)
        )

        #expect(mutation?.number == 1)
        #expect(mutation?.kind == "initial")
        #expect(mutation?.sourceVersionId == nil)
    }

    @Test("정정은 현재 버전과 초안 기준 버전이 일치할 때만 새 버전을 만든다")
    func 정정은_현재_버전과_초안_기준_버전이_일치할_때만_새_버전을_만든다() {
        let mutation = DevelopmentRecordServiceImpl.makeConfirmationMutation(
            recordData: makeRecordData(
                currentVersionId: "version-1",
                currentVersionNumber: 1,
                draftBaseVersionId: "version-1"
            ),
            request: .init(
                versionId: "version-2",
                kind: "correction",
                sourceVersionId: "version-1"
            )
        )

        #expect(mutation?.number == 2)
        #expect(mutation?.sourceVersionId == "version-1")
    }

    @Test("되돌리기는 현재 버전보다 앞선 원본으로 새 rollback 버전을 만든다")
    func 되돌리기는_현재_버전보다_앞선_원본으로_새_rollback_버전을_만든다() {
        let mutation = DevelopmentRecordServiceImpl.makeRestoreMutation(
            recordId: "record-1",
            recordData: makeRecordData(
                currentVersionId: "version-2",
                currentVersionNumber: 2,
                draftBaseVersionId: nil,
                includesDraft: false
            ),
            sourceVersionId: "version-1",
            sourceData: makeVersionData(number: 1)
        )

        #expect(mutation?.number == 3)
        #expect(mutation?.kind == "rollback")
        #expect(mutation?.sourceVersionId == "version-1")
    }

    @Test("이미 현재인 버전은 되돌리기 원본으로 사용할 수 없다")
    func 이미_현재인_버전은_되돌리기_원본으로_사용할_수_없다() {
        let mutation = DevelopmentRecordServiceImpl.makeRestoreMutation(
            recordId: "record-1",
            recordData: makeRecordData(
                currentVersionId: "version-2",
                currentVersionNumber: 2,
                draftBaseVersionId: nil,
                includesDraft: false
            ),
            sourceVersionId: "version-2",
            sourceData: makeVersionData(number: 2)
        )

        #expect(mutation?.number == nil)
    }

    private func makeRecordData(
        currentVersionId: String? = nil,
        currentVersionNumber: Int? = nil,
        draftBaseVersionId: String?,
        includesDraft: Bool = true
    ) -> [String: Any] {
        var data: [String: Any] = [
            DevelopmentRecordFieldKey.createdAt.rawValue: Timestamp(date: .distantPast)
        ]
        if let currentVersionId, let currentVersionNumber {
            data[DevelopmentRecordFieldKey.currentVersionId.rawValue] = currentVersionId
            data[DevelopmentRecordFieldKey.currentVersionNumber.rawValue] = currentVersionNumber
        }
        if includesDraft {
            var draft: [String: Any] = [
                DevelopmentRecordDraftFieldKey.title.rawValue: "기록",
                DevelopmentRecordDraftFieldKey.markdownContent.rawValue: "본문",
                DevelopmentRecordDraftFieldKey.updatedAt.rawValue: Timestamp(date: .distantPast)
            ]
            if let draftBaseVersionId {
                draft[DevelopmentRecordDraftFieldKey.baseVersionId.rawValue] = draftBaseVersionId
            }
            data[DevelopmentRecordFieldKey.draft.rawValue] = draft
        }
        return data
    }

    private func makeVersionData(number: Int) -> [String: Any] {
        [
            DevelopmentRecordVersionFieldKey.versionNumber.rawValue: number,
            DevelopmentRecordVersionFieldKey.title.rawValue: "기록",
            DevelopmentRecordVersionFieldKey.markdownContent.rawValue: "본문",
            DevelopmentRecordVersionFieldKey.changeKind.rawValue: "initial",
            DevelopmentRecordVersionFieldKey.confirmedAt.rawValue: Timestamp(date: .distantPast)
        ]
    }
}
