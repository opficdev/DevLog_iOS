//
//  TodoCategoryServiceImpl.swift
//  DevLogInfra
//
//  Created by opfic on 3/30/26.
//

import FirebaseAuth
import FirebaseFirestore
import DevLogCore
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

    func fetchCategoryPreferences() async throws -> [TodoCategoryPreferenceResponse] {
        guard let uid = Auth.auth().currentUser?.uid else {
            logger.error("User not authenticated")
            throw DataLayerError.notAuthenticated
        }

        logger.info("Fetching todo category preferences")

        do {
            let snapshot = try await store.document(
                FirestorePath.userData(uid, document: .categories)
            ).getDocument()

            guard let items = snapshot.data()?[Field.items.rawValue] as? [[String: Any]] else {
                logger.info("Todo category preferences not found, using defaults")
                return []
            }

            let preferences = items.compactMap { makePreference($0) }
            if preferences.isEmpty {
                logger.info("Todo category preferences empty, using defaults")
                return []
            }

            logger.info("Successfully fetched todo category preferences")
            return preferences
        } catch {
            logger.error("Failed to fetch todo category preferences", error: error)
            throw error
        }
    }

    func updateCategoryPreferences(_ preferences: [TodoCategoryPreferenceResponse]) async throws {
        guard let uid = Auth.auth().currentUser?.uid else {
            logger.error("User not authenticated")
            throw DataLayerError.notAuthenticated
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
    func makePreference(_ items: [String: Any]) -> TodoCategoryPreferenceResponse? {
        guard
            let kindString = items[Field.kind.rawValue] as? String,
            let kind = Kind(rawValue: kindString),
            let isVisible = items[Field.isVisible.rawValue] as? Bool
        else {
            return nil
        }

        switch kind {
        case .system:
            guard let systemCategoryString = items[Field.systemCategory.rawValue] as? String else {
                return nil
            }

            return TodoCategoryPreferenceResponse(
                category: .system(systemCategoryString),
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

            return TodoCategoryPreferenceResponse(
                category: .user(
                    TodoCategoryPreferenceResponse.UserCategory(
                        id: id,
                        name: name,
                        colorHex: colorHex
                    )
                ),
                isVisible: isVisible
            )
        }
    }

    func toDictionary(_ preference: TodoCategoryPreferenceResponse) -> [String: Any] {
        switch preference.category {
        case .system(let rawValue):
            return [
                Field.kind.rawValue: Kind.system.rawValue,
                Field.systemCategory.rawValue: rawValue,
                Field.isVisible.rawValue: preference.isVisible
            ]
        case .user(let userCategory):
            return [
                Field.kind.rawValue: Kind.user.rawValue,
                Field.id.rawValue: userCategory.id,
                Field.name.rawValue: userCategory.name,
                Field.colorHex.rawValue: userCategory.colorHex,
                Field.isVisible.rawValue: preference.isVisible
            ]
        }
    }
}
