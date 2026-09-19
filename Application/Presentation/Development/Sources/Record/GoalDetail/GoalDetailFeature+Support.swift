//
//  GoalDetailFeature+Support.swift
//  Development
//
//  Created by opfic on 9/15/26.
//

import Domain
import Foundation
import PresentationShared

extension GoalDetailFeature {
    static func precedes(_ lhs: DevelopmentRecord, _ rhs: DevelopmentRecord) -> Bool {
        if lhs.createdAt == rhs.createdAt { return lhs.id < rhs.id }
        return rhs.createdAt < lhs.createdAt
    }

    static func canTransition(
        from currentStatus: DevelopmentGoal.Status,
        to status: DevelopmentGoal.Status
    ) -> Bool {
        switch (currentStatus, status) {
        case (.inProgress, .completed),
             (.inProgress, .archived),
             (.completed, .inProgress),
             (.archived, .inProgress):
            true
        default:
            false
        }
    }

    static func completionBlockingAlert(
        items: [RecordTimelineItem]
    ) -> AlertState<Action.Alert>? {
        guard !items.isEmpty else {
            return informationAlert(
                titleKey: "development_goal_completion_record_required_title",
                messageKey: "development_goal_completion_record_required_message"
            )
        }
        guard items.first?.isUnconfirmed == false else {
            return informationAlert(
                titleKey: "development_goal_completion_version_required_title",
                messageKey: "development_goal_completion_version_required_message"
            )
        }
        guard !items.contains(where: \.hasDraft) else {
            return informationAlert(
                titleKey: "development_goal_completion_draft_title",
                messageKey: "development_goal_completion_draft_message"
            )
        }
        return nil
    }

    static func transitionConfirmationAlert(
        _ status: DevelopmentGoal.Status
    ) -> AlertState<Action.Alert> {
        let keys: (title: String.LocalizationValue, message: String.LocalizationValue)
        switch status {
        case .inProgress:
            keys = (
                "development_goal_resume_alert_title",
                "development_goal_resume_alert_message"
            )
        case .completed:
            keys = (
                "development_goal_complete_alert_title",
                "development_goal_complete_alert_message"
            )
        case .archived:
            keys = (
                "development_goal_archive_alert_title",
                "development_goal_archive_alert_message"
            )
        }

        return AlertState {
            TextState(String(localized: keys.title, bundle: PresentationResources.bundle))
        } actions: {
            ButtonState(role: .cancel) {
                TextState(String(localized: "common_cancel", bundle: PresentationResources.bundle))
            }
            ButtonState(action: .confirmTransition(status)) {
                TextState(String(
                    localized: transitionActionKey(status),
                    bundle: PresentationResources.bundle
                ))
            }
        } message: {
            TextState(String(localized: keys.message, bundle: PresentationResources.bundle))
        }
    }

    static var errorAlert: AlertState<Action.Alert> {
        AlertState {
            TextState(String(localized: "common_error_title", bundle: PresentationResources.bundle))
        } actions: {
            ButtonState(role: .cancel) {
                TextState(String(localized: "common_close", bundle: PresentationResources.bundle))
            }
        } message: {
            TextState(String(
                localized: "development_record_timeline_error_message",
                bundle: PresentationResources.bundle
            ))
        }
    }

    static var transitionErrorAlert: AlertState<Action.Alert> {
        informationAlert(
            titleKey: "common_error_title",
            messageKey: "development_goal_transition_error_message"
        )
    }

    static func transitionActionKey(
        _ status: DevelopmentGoal.Status
    ) -> String.LocalizationValue {
        switch status {
        case .inProgress:
            "development_goal_resume"
        case .completed:
            "development_goal_complete"
        case .archived:
            "development_goal_archive"
        }
    }

    static func informationAlert(
        titleKey: String.LocalizationValue,
        messageKey: String.LocalizationValue
    ) -> AlertState<Action.Alert> {
        AlertState {
            TextState(String(localized: titleKey, bundle: PresentationResources.bundle))
        } actions: {
            ButtonState(role: .cancel) {
                TextState(String(localized: "common_close", bundle: PresentationResources.bundle))
            }
        } message: {
            TextState(String(localized: messageKey, bundle: PresentationResources.bundle))
        }
    }
}
