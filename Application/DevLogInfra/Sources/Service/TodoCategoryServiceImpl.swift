//
//  TodoCategoryServiceImpl.swift
//  DevLog
//
//  Created by opfic on 3/30/26.
//

import FirebaseAuth
import FirebaseFirestore
import DevLogDomain
import DevLogData

final class TodoCategoryServiceImpl: TodoCategoryService {
    private enum Field: String {
        case items
        case kind
        case id
        case systemCategory
        case name
        case colorHex
        case isVisible
    }

    private enum Kind: String {
        case system
        case user
    }

    private let store = Firestore.firestore()
    private let logger = Logger(category: "TodoCategoryServiceImpl")

    func fetchPreferences() async throws -> [TodoCategoryPreference] {
        guard let uid = Auth.auth().currentUser?.uid else {
            logger.error("User not authenticated")
            throw AuthError.notAuthenticated
        }

        logger.info("Fetching todo category preferences")

        do {
            let snapshot = try await store.document(
                FirestorePath.userData(uid, document: .categories)
            ).getDocument()

            guard let items = snapshot.data()?[Field.items.rawValue] as? [[String: Any]] else {
                logger.info("Todo category preferences not found, using defaults")
                return SystemTodoCategory.allCases.map {
                    TodoCategoryPreference(category: .system($0), isVisible: true)
                }
            }

            let preferences = items.compactMap { makePreference($0) }
            if preferences.isEmpty {
                logger.info("Todo category preferences empty, using defaults")
                return SystemTodoCategory.allCases.map {
                    TodoCategoryPreference(category: .system($0), isVisible: true)
                }
            }

            let mergedPreferences = mergedPreferences(preferences)
            logger.info("Successfully fetched todo category preferences")
            return mergedPreferences
        } catch {
            logger.error("Failed to fetch todo category preferences", error: error)
            throw error
        }
    }

    func updatePreferences(_ preferences: [TodoCategoryPreference]) async throws {
        guard let uid = Auth.auth().currentUser?.uid else {
            logger.error("User not authenticated")
            throw AuthError.notAuthenticated
        }

        logger.info("Updating todo category preferences")

        do {
            try await store.document(
                FirestorePath.userData(uid, document: .categories)
            ).setData(
                [Field.items.rawValue: preferences.map(toDictionary)],
                merge: true
            )
            logger.info("Successfully updated todo category preferences")
        } catch {
            logger.error("Failed to update todo category preferences", error: error)
            throw error
        }
    }
}

private extension TodoCategoryServiceImpl {
    func mergedPreferences(
        _ preferences: [TodoCategoryPreference]
    ) -> [TodoCategoryPreference] {
        var mergedPreferences = preferences

        for systemTodoCategory in SystemTodoCategory.allCases {
            let containsSystemTodoCategory = preferences.contains { preference in
                guard case .system(let currentSystemTodoCategory) = preference.category else {
                    return false
                }

                return currentSystemTodoCategory == systemTodoCategory
            }

            if containsSystemTodoCategory { continue }

            mergedPreferences.append(
                TodoCategoryPreference(
                    category: .system(systemTodoCategory),
                    isVisible: true
                )
            )
        }

        return mergedPreferences
    }

    func makePreference(_ items: [String: Any]) -> TodoCategoryPreference? {
        guard
            let kindString = items[Field.kind.rawValue] as? String,
            let kind = Kind(rawValue: kindString),
            let isVisible = items[Field.isVisible.rawValue] as? Bool
        else {
            return nil
        }

        switch kind {
        case .system:
            guard
                let systemCategoryString = items[Field.systemCategory.rawValue] as? String,
                let systemTodoCategory = SystemTodoCategory(rawValue: systemCategoryString)
            else {
                return nil
            }

            return TodoCategoryPreference(
                category: .system(systemTodoCategory),
                isVisible: isVisible
            )
        case .user:
            guard
                let id = items[Field.id.rawValue] as? String,
                let name = items[Field.name.rawValue] as? String,
                let colorHex = items[Field.colorHex.rawValue] as? String
            else {
                return nil
            }

            return TodoCategoryPreference(
                category: .user(
                    UserTodoCategory(
                        id: id,
                        name: name,
                        colorHex: colorHex
                    )
                ),
                isVisible: isVisible
            )
        }
    }

    func toDictionary(_ preference: TodoCategoryPreference) -> [String: Any] {
        switch preference.category {
        case .system(let systemTodoCategory):
            return [
                Field.kind.rawValue: Kind.system.rawValue,
                Field.systemCategory.rawValue: systemTodoCategory.rawValue,
                Field.isVisible.rawValue: preference.isVisible
            ]
        case .user(let userTodoCategory):
            return [
                Field.kind.rawValue: Kind.user.rawValue,
                Field.id.rawValue: userTodoCategory.id,
                Field.name.rawValue: userTodoCategory.name,
                Field.colorHex.rawValue: userTodoCategory.colorHex,
                Field.isVisible.rawValue: preference.isVisible
            ]
        }
    }
}
