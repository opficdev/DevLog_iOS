//
//  DevelopmentRecordServiceImpl.swift
//  Infra
//
//  Created by opfic on 8/28/26.
//

import FirebaseAuth
import FirebaseFirestore
import Core
import Data

final class DevelopmentRecordServiceImpl: DevelopmentRecordService {
    private enum CrashlyticsError {
        static let domain = "DevLogInfra.DevelopmentRecordServiceImpl"

        enum Code: Int {
            case createRecord = 1
            case fetchRecords
            case fetchRecord
            case fetchVersions
            case saveDraft
            case confirmDraft
            case restoreVersion
        }
    }

    private let store = FirebaseConfiguration.firestore
    private let logger = Logger(category: "DevelopmentRecordServiceImpl")
    private let mapper = DevelopmentRecordDocumentMapper()

    func createRecord(
        goalId: String,
        recordId: String,
        request: DevelopmentRecordCreateRequest
    ) async throws -> DevelopmentRecordResponse {
        guard let uid = Auth.auth().currentUser?.uid else { throw DataLayerError.notAuthenticated }

        do {
            try await store.document(
                FirestorePath.developmentRecord(uid, goalId: goalId, recordId: recordId)
            )
            .setData([
                DevelopmentRecordFieldKey.draft.rawValue: Self.makeDraftData(request.draft),
                DevelopmentRecordFieldKey.createdAt.rawValue: FieldValue.serverTimestamp()
            ])
            return try await fetchRecord(uid: uid, goalId: goalId, recordId: recordId)
        } catch {
            logger.error("Failed to create development record", error: error)
            record(error, code: .createRecord)
            throw error
        }
    }

    func fetchRecords(goalId: String) async throws -> [DevelopmentRecordResponse] {
        guard let uid = Auth.auth().currentUser?.uid else { throw DataLayerError.notAuthenticated }

        do {
            let snapshot = try await store.collection(
                FirestorePath.developmentRecords(uid, goalId: goalId)
            )
            .order(by: DevelopmentRecordFieldKey.createdAt.rawValue)
            .order(by: FieldPath.documentID())
            .getDocuments()
            return try snapshot.documents.map { document in
                guard let response = mapper.map(
                    goalId: goalId,
                    documentId: document.documentID,
                    data: document.data()
                ) else {
                    throw DataLayerError.invalidData("developmentRecord")
                }
                return response
            }
        } catch {
            logger.error("Failed to fetch development records", error: error)
            record(error, code: .fetchRecords)
            throw error
        }
    }

    func fetchRecord(
        goalId: String,
        recordId: String
    ) async throws -> DevelopmentRecordResponse {
        guard let uid = Auth.auth().currentUser?.uid else { throw DataLayerError.notAuthenticated }

        do {
            return try await fetchRecord(uid: uid, goalId: goalId, recordId: recordId)
        } catch {
            logger.error("Failed to fetch development record", error: error)
            record(error, code: .fetchRecord)
            throw error
        }
    }

    func fetchVersions(
        goalId: String,
        recordId: String
    ) async throws -> [DevelopmentRecordVersionResponse] {
        guard let uid = Auth.auth().currentUser?.uid else { throw DataLayerError.notAuthenticated }

        do {
            let snapshot = try await store.collection(
                FirestorePath.developmentRecordVersions(
                    uid,
                    goalId: goalId,
                    recordId: recordId
                )
            )
            .order(by: DevelopmentRecordVersionFieldKey.versionNumber.rawValue)
            .getDocuments()
            return try snapshot.documents.map { document in
                guard let response = mapper.mapVersion(
                    recordId: recordId,
                    documentId: document.documentID,
                    data: document.data()
                ) else {
                    throw DataLayerError.invalidData("developmentRecordVersion")
                }
                return response
            }
        } catch {
            logger.error("Failed to fetch development record versions", error: error)
            record(error, code: .fetchVersions)
            throw error
        }
    }

    func saveDraft(
        goalId: String,
        recordId: String,
        request: DevelopmentRecordDraftRequest
    ) async throws -> DevelopmentRecordResponse {
        guard let uid = Auth.auth().currentUser?.uid else { throw DataLayerError.notAuthenticated }

        do {
            try await store.document(
                FirestorePath.developmentRecord(uid, goalId: goalId, recordId: recordId)
            )
            .updateData([
                DevelopmentRecordFieldKey.draft.rawValue: Self.makeDraftData(request)
            ])
            return try await fetchRecord(uid: uid, goalId: goalId, recordId: recordId)
        } catch {
            logger.error("Failed to save development record draft", error: error)
            record(error, code: .saveDraft)
            throw error
        }
    }

    func confirmDraft(
        goalId: String,
        recordId: String,
        request: DevelopmentRecordConfirmationRequest
    ) async throws -> DevelopmentRecordVersionResponse {
        guard let uid = Auth.auth().currentUser?.uid else { throw DataLayerError.notAuthenticated }

        do {
            let recordReference = store.document(
                FirestorePath.developmentRecord(uid, goalId: goalId, recordId: recordId)
            )
            let versionReference = store.document(
                FirestorePath.developmentRecordVersion(
                    uid,
                    goalId: goalId,
                    recordId: recordId,
                    versionId: request.versionId
                )
            )
            _ = try await store.runTransaction { transaction, errorPointer in
                do {
                    let recordSnapshot = try transaction.getDocument(recordReference)
                    let versionSnapshot = try transaction.getDocument(versionReference)
                    guard
                        !versionSnapshot.exists,
                        let recordData = recordSnapshot.data(),
                        let mutation = Self.makeConfirmationMutation(
                            recordData: recordData,
                            request: request
                        ) else {
                        errorPointer?.pointee = Self.transactionError("developmentRecordConfirmation")
                        return nil
                    }

                    if let sourceVersionId = mutation.sourceVersionId {
                        let sourceSnapshot = try transaction.getDocument(
                            store.document(
                                FirestorePath.developmentRecordVersion(
                                    uid,
                                    goalId: goalId,
                                    recordId: recordId,
                                    versionId: sourceVersionId
                                )
                            )
                        )
                        guard sourceSnapshot.exists else {
                            errorPointer?.pointee = Self.transactionError("sourceVersion")
                            return nil
                        }
                    }

                    transaction.setData(mutation.documentData(), forDocument: versionReference)
                    transaction.updateData(
                        [
                            DevelopmentRecordFieldKey.currentVersionId.rawValue: request.versionId,
                            DevelopmentRecordFieldKey.currentVersionNumber.rawValue: mutation.number,
                            DevelopmentRecordFieldKey.draft.rawValue: FieldValue.delete()
                        ],
                        forDocument: recordReference
                    )
                    return nil
                } catch let error as NSError {
                    errorPointer?.pointee = error
                    return nil
                }
            }
            return try await fetchVersion(
                uid: uid,
                goalId: goalId,
                recordId: recordId,
                versionId: request.versionId
            )
        } catch {
            logger.error("Failed to confirm development record draft", error: error)
            record(error, code: .confirmDraft)
            throw error
        }
    }

    func restoreVersion(
        goalId: String,
        recordId: String,
        request: DevelopmentRecordRestoreRequest
    ) async throws -> DevelopmentRecordVersionResponse {
        guard let uid = Auth.auth().currentUser?.uid else { throw DataLayerError.notAuthenticated }

        do {
            let recordReference = store.document(
                FirestorePath.developmentRecord(uid, goalId: goalId, recordId: recordId)
            )
            let sourceReference = store.document(
                FirestorePath.developmentRecordVersion(
                    uid,
                    goalId: goalId,
                    recordId: recordId,
                    versionId: request.sourceVersionId
                )
            )
            let versionReference = store.document(
                FirestorePath.developmentRecordVersion(
                    uid,
                    goalId: goalId,
                    recordId: recordId,
                    versionId: request.versionId
                )
            )
            _ = try await store.runTransaction { transaction, errorPointer in
                do {
                    let recordSnapshot = try transaction.getDocument(recordReference)
                    let sourceSnapshot = try transaction.getDocument(sourceReference)
                    let versionSnapshot = try transaction.getDocument(versionReference)
                    guard
                        !versionSnapshot.exists,
                        let recordData = recordSnapshot.data(),
                        let sourceData = sourceSnapshot.data(),
                        let mutation = Self.makeRestoreMutation(
                            recordId: recordId,
                            recordData: recordData,
                            sourceVersionId: request.sourceVersionId,
                            sourceData: sourceData
                        ) else {
                        errorPointer?.pointee = Self.transactionError("developmentRecordRestore")
                        return nil
                    }

                    transaction.setData(mutation.documentData(), forDocument: versionReference)
                    transaction.updateData(
                        [
                            DevelopmentRecordFieldKey.currentVersionId.rawValue: request.versionId,
                            DevelopmentRecordFieldKey.currentVersionNumber.rawValue: mutation.number
                        ],
                        forDocument: recordReference
                    )
                    return nil
                } catch let error as NSError {
                    errorPointer?.pointee = error
                    return nil
                }
            }
            return try await fetchVersion(
                uid: uid,
                goalId: goalId,
                recordId: recordId,
                versionId: request.versionId
            )
        } catch {
            logger.error("Failed to restore development record version", error: error)
            record(error, code: .restoreVersion)
            throw error
        }
    }
}

private extension DevelopmentRecordServiceImpl {
    static func record(_ error: Error, code: CrashlyticsError.Code) {
        FirebaseCrashlyticsHelper.record(
            error,
            domain: "\(CrashlyticsError.domain).\(code)",
            code: code.rawValue
        )
    }

    static func transactionError(_ context: String) -> NSError {
        NSError(
            domain: "DevelopmentRecordServiceImpl",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: context]
        )
    }

    func record(_ error: Error, code: CrashlyticsError.Code) {
        Self.record(error, code: code)
    }

    func fetchRecord(
        uid: String,
        goalId: String,
        recordId: String
    ) async throws -> DevelopmentRecordResponse {
        let snapshot = try await store.document(
            FirestorePath.developmentRecord(uid, goalId: goalId, recordId: recordId)
        )
        .getDocument()
        guard let data = snapshot.data(), let response = mapper.map(
            goalId: goalId,
            documentId: snapshot.documentID,
            data: data
        ) else {
            throw FirestoreError.dataNotFound("developmentRecord")
        }
        return response
    }

    func fetchVersion(
        uid: String,
        goalId: String,
        recordId: String,
        versionId: String
    ) async throws -> DevelopmentRecordVersionResponse {
        let snapshot = try await store.document(
            FirestorePath.developmentRecordVersion(
                uid,
                goalId: goalId,
                recordId: recordId,
                versionId: versionId
            )
        )
        .getDocument()
        guard let data = snapshot.data(), let response = mapper.mapVersion(
            recordId: recordId,
            documentId: snapshot.documentID,
            data: data
        ) else {
            throw FirestoreError.dataNotFound("developmentRecordVersion")
        }
        return response
    }
}
