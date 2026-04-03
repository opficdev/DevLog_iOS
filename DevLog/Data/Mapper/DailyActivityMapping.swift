//
//  DailyActivityMapping.swift
//  DevLog
//
//  Created by opfic on 4/4/26.
//

extension DailyActivityResponse {
    func toDomain() -> DailyActivity {
        DailyActivity(
            dayKey: dayKey,
            createdCount: createdCount,
            completedCount: completedCount,
            deletedCount: deletedCount
        )
    }
}

extension DailyActivityEventResponse {
    func toDomain() throws -> DailyActivityEvent {
        guard let activityKind = ActivityKind(rawValue: kind) else {
            throw DataError.invalidData("DailyActivityEventResponse.kind is invalid: \(kind)")
        }

        return DailyActivityEvent(
            id: id,
            dayKey: dayKey,
            kind: activityKind,
            occurredAt: occurredAt,
            todoID: todoID,
            todoTitle: todoTitle,
            todoNumber: todoNumber,
            todoCategoryID: todoCategoryID
        )
    }
}
