//
//  DevelopmentGoalServiceImpl.swift
//  Infra
//
//  Created by opfic on 8/28/26.
//

import FirebaseAuth
import FirebaseFirestore
import Core
import Data

final class DevelopmentGoalServiceImpl: DevelopmentGoalService {
    private enum CrashlyticsError {
        static let domain = "DevLogInfra.DevelopmentGoalServiceImpl"

        enum Code: Int {
            case createGoal = 1
            case fetchGoal
            case fetchGoals
            case fetchCompletionSnapshot
            case transitionGoalStatus
        }
    }

    private let store = FirebaseConfiguration.firestore
    private let encoder = Firestore.Encoder()
    private let logger = Logger(category: "DevelopmentGoalServiceImpl")
    private let recordMapper = DevelopmentRecordDocumentMapper()

    func createGoal(
        goalId: String,
        request: DevelopmentGoalCreateRequest
    ) async throws -> DevelopmentGoalResponse {
        guard let uid = Auth.auth().currentUser?.uid else { throw DataLayerError.notAuthenticated }

        do {
            let reference = store.document(FirestorePath.developmentGoal(uid, goalId: goalId))
            var data = try encoder.encode(request)
            data[DevelopmentGoalFieldKey.status.rawValue] = "inProgress"
            data[DevelopmentGoalFieldKey.createdAt.rawValue] = FieldValue.serverTimestamp()
            data[DevelopmentGoalFieldKey.updatedAt.rawValue] = FieldValue.serverTimestamp()
            try await reference.setData(data)
            return try await fetchGoal(uid: uid, goalId: goalId)
        } catch {
            logger.error("Failed to create development goal", error: error)
            record(error, code: .createGoal)
            throw error
        }
    }

    func fetchGoal(goalId: String) async throws -> DevelopmentGoalResponse {
        guard let uid = Auth.auth().currentUser?.uid else { throw DataLayerError.notAuthenticated }

        do {
            return try await fetchGoal(uid: uid, goalId: goalId)
        } catch {
            logger.error("Failed to fetch development goal", error: error)
            record(error, code: .fetchGoal)
            throw error
        }
    }

    func fetchGoals(_ query: DevelopmentGoalQuery) async throws -> [DevelopmentGoalResponse] {
        guard let uid = Auth.auth().currentUser?.uid else { throw DataLayerError.notAuthenticated }

        do {
            var reference: Query = store.collection(FirestorePath.developmentGoals(uid))
            if let status = query.status {
                reference = reference.whereField(
                    DevelopmentGoalFieldKey.status.rawValue,
                    isEqualTo: status
                )
            }
            let snapshot = try await reference
                .order(by: DevelopmentGoalFieldKey.createdAt.rawValue)
                .order(by: FieldPath.documentID())
                .getDocuments()
            return try snapshot.documents.map { document in
                guard let response = Self.makeResponse(
                    documentId: document.documentID,
                    data: document.data()
                ) else {
                    throw DataLayerError.invalidData("developmentGoal")
                }
                return response
            }
        } catch {
            logger.error("Failed to fetch development goals", error: error)
            record(error, code: .fetchGoals)
            throw error
        }
    }

    func fetchCompletionSnapshot(
        goalId: String
    ) async throws -> DevelopmentGoalCompletionResponse {
        guard let uid = Auth.auth().currentUser?.uid else { throw DataLayerError.notAuthenticated }

        do {
            let goal = try await fetchGoal(uid: uid, goalId: goalId)
            let snapshot = try await store.collection(
                FirestorePath.developmentRecords(uid, goalId: goalId)
            )
            .order(by: DevelopmentRecordFieldKey.createdAt.rawValue)
            .getDocuments()
            let records = try snapshot.documents.map { document in
                guard let response = recordMapper.map(
                    goalId: goalId,
                    documentId: document.documentID,
                    data: document.data()
                ) else {
                    throw DataLayerError.invalidData("developmentRecord")
                }
                return response
            }
            return .init(goal: goal, records: records)
        } catch {
            logger.error("Failed to fetch development goal completion snapshot", error: error)
            record(error, code: .fetchCompletionSnapshot)
            throw error
        }
    }

    func transitionGoalStatus(
        goalId: String,
        request: DevelopmentGoalStatusRequest
    ) async throws {
        guard let uid = Auth.auth().currentUser?.uid else { throw DataLayerError.notAuthenticated }

        do {
            let reference = store.document(
                FirestorePath.developmentGoal(uid, goalId: goalId)
            )
            _ = try await store.runTransaction { transaction, errorPointer in
                do {
                    let snapshot = try transaction.getDocument(reference)
                    guard
                        let recordData = snapshot.data(),
                        let data = Self.makeTransitionData(
                            recordData: recordData,
                            request: request
                        ) else {
                        errorPointer?.pointee = Self.transactionError("developmentGoalTransition")
                        return nil
                    }
                    transaction.updateData(data, forDocument: reference)
                    return nil
                } catch let error as NSError {
                    errorPointer?.pointee = error
                    return nil
                }
            }
        } catch {
            logger.error("Failed to transition development goal status", error: error)
            record(error, code: .transitionGoalStatus)
            throw error
        }
    }
}

extension DevelopmentGoalServiceImpl {
    static func makeTransitionData(
        recordData: [String: Any],
        request: DevelopmentGoalStatusRequest
    ) -> [String: Any]? {
        guard
            let currentStatus = recordData[DevelopmentGoalFieldKey.status.rawValue] as? String,
            (currentStatus == "inProgress" && request.status == "archived") ||
            (currentStatus == "archived" && request.status == "inProgress") else {
            return nil
        }
        return [
            DevelopmentGoalFieldKey.status.rawValue: request.status,
            DevelopmentGoalFieldKey.updatedAt.rawValue: FieldValue.serverTimestamp()
        ]
    }

    static func makeResponse(
        documentId: String,
        data: [String: Any]
    ) -> DevelopmentGoalResponse? {
        guard
            let title = data[DevelopmentGoalFieldKey.title.rawValue] as? String,
            let markdownDescription = data[DevelopmentGoalFieldKey.markdownDescription.rawValue] as? String,
            let status = data[DevelopmentGoalFieldKey.status.rawValue] as? String,
            let createdAt = data[DevelopmentGoalFieldKey.createdAt.rawValue] as? Timestamp,
            let updatedAt = data[DevelopmentGoalFieldKey.updatedAt.rawValue] as? Timestamp else {
            return nil
        }
        return DevelopmentGoalResponse(
            id: documentId,
            title: title,
            markdownDescription: markdownDescription,
            status: status,
            createdAt: createdAt.dateValue(),
            updatedAt: updatedAt.dateValue(),
            completedAt: (data[DevelopmentGoalFieldKey.completedAt.rawValue] as? Timestamp)?.dateValue()
        )
    }
}

private extension DevelopmentGoalServiceImpl {
    private static func transactionError(_ context: String) -> NSError {
        NSError(
            domain: "DevelopmentGoalServiceImpl",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: context]
        )
    }

    private static func record(_ error: Error, code: CrashlyticsError.Code) {
        FirebaseCrashlyticsHelper.record(
            error,
            domain: "\(CrashlyticsError.domain).\(code)",
            code: code.rawValue
        )
    }

    private func record(_ error: Error, code: CrashlyticsError.Code) {
        Self.record(error, code: code)
    }

    private func fetchGoal(uid: String, goalId: String) async throws -> DevelopmentGoalResponse {
        let snapshot = try await store.document(
            FirestorePath.developmentGoal(uid, goalId: goalId)
        )
        .getDocument()
        guard let data = snapshot.data(), let response = Self.makeResponse(
            documentId: snapshot.documentID,
            data: data
        ) else {
            throw FirestoreError.dataNotFound("developmentGoal")
        }
        return response
    }
}

private enum DevelopmentGoalFieldKey: String {
    case title
    case markdownDescription
    case status
    case createdAt
    case updatedAt
    case completedAt
}
