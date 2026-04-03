//
//  DailyActivityService.swift
//  DevLog
//
//  Created by opfic on 4/4/26.
//

import FirebaseAuth
import FirebaseFirestore

final class DailyActivityService {
    private enum FieldKey: String {
        case dayKey
        case createdCount
        case completedCount
        case deletedCount
        case kind
        case occurredAt
        case todoId
        case todoTitle
        case todoNumber
        case todoCategory
    }

    private let store = Firestore.firestore()
    private let logger = Logger(category: "DailyActivityService")

    func fetchActivities(
        from startDayKey: String,
        to endDayKey: String
    ) async throws -> [DailyActivityResponse] {
        guard let uid = Auth.auth().currentUser?.uid else { throw AuthError.notAuthenticated }

        logger.info("Fetching activity dailies from \(startDayKey) to \(endDayKey)")

        do {
            let snapshot = try await store.collection(FirestorePath.activity(uid))
                .whereField(FieldKey.dayKey.rawValue, isGreaterThanOrEqualTo: startDayKey)
                .whereField(FieldKey.dayKey.rawValue, isLessThanOrEqualTo: endDayKey)
                .order(by: FieldKey.dayKey.rawValue)
                .getDocuments()

            return snapshot.documents.compactMap(makeDailyActivityResponse)
        } catch {
            logger.error("Failed to fetch daily activities", error: error)
            throw error
        }
    }

    func fetchActivityEvents(dayKey: String) async throws -> [DailyActivityEventResponse] {
        guard let uid = Auth.auth().currentUser?.uid else { throw AuthError.notAuthenticated }

        logger.info("Fetching activity events for \(dayKey)")

        do {
            let snapshot = try await store.collection(FirestorePath.activityEvents(uid))
                .whereField(FieldKey.dayKey.rawValue, isEqualTo: dayKey)
                .order(by: FieldKey.occurredAt.rawValue, descending: true)
                .getDocuments()

            return snapshot.documents.compactMap(makeDailyActivityEventResponse)
        } catch {
            logger.error("Failed to fetch daily activity events", error: error)
            throw error
        }
    }
}

private extension DailyActivityService {
    func makeDailyActivityResponse(from snapshot: QueryDocumentSnapshot) -> DailyActivityResponse? {
        let data = snapshot.data()

        guard
            let dayKey = data[FieldKey.dayKey.rawValue] as? String,
            let createdCount = data[FieldKey.createdCount.rawValue] as? Int,
            let completedCount = data[FieldKey.completedCount.rawValue] as? Int,
            let deletedCount = data[FieldKey.deletedCount.rawValue] as? Int
        else { return nil }

        return DailyActivityResponse(
            dayKey: dayKey,
            createdCount: createdCount,
            completedCount: completedCount,
            deletedCount: deletedCount
        )
    }

    func makeDailyActivityEventResponse(from snapshot: QueryDocumentSnapshot) -> DailyActivityEventResponse? {
        let data = snapshot.data()

        guard
            let dayKey = data[FieldKey.dayKey.rawValue] as? String,
            let kind = data[FieldKey.kind.rawValue] as? String,
            let occurredAtTimestamp = data[FieldKey.occurredAt.rawValue] as? Timestamp,
            let todoId = data[FieldKey.todoId.rawValue] as? String,
            let todoTitle = data[FieldKey.todoTitle.rawValue] as? String,
            let todoCategoryID = data[FieldKey.todoCategory.rawValue] as? String
        else {
            return nil
        }

        return DailyActivityEventResponse(
            id: snapshot.documentID,
            dayKey: dayKey,
            kind: kind,
            occurredAt: occurredAtTimestamp.dateValue(),
            todoId: todoId,
            todoTitle: todoTitle,
            todoNumber: data[FieldKey.todoNumber.rawValue] as? Int,
            todoCategoryID: todoCategoryID
        )
    }
}
