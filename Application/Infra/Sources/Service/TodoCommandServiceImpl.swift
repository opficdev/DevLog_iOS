//
//  TodoCommandServiceImpl.swift
//  Infra
//
//  Created by opfic on 8/28/26.
//

import FirebaseAuth
import FirebaseFirestore
import Core
import Data

final class TodoCommandServiceImpl: TodoCommandService {
    private enum CrashlyticsError {
        static let domain = "DevLogInfra.TodoServiceImpl"

        enum Code: Int {
            case upsertTodo = 2
            case deleteTodo = 3
            case undoDeleteTodo = 4
        }
    }

    private enum CounterFieldKey: String {
        case nextNumber
        case updatedAt
    }

    private let store = FirebaseConfiguration.firestore
    private let encoder = Firestore.Encoder()
    private let logger = Logger(category: "TodoServiceImpl")

    func upsertTodo(request: TodoRequest) async throws {
        guard let uid = Auth.auth().currentUser?.uid else { throw DataLayerError.notAuthenticated }

        logger.info("Upserting todo")
        do {
            let reference = store.collection(FirestorePath.todos(uid)).document(request.id)
            let data = try TodoDocumentMapper.makeDocumentData(from: request, encoder: encoder)
            try await upsertTodoWithNumberOnCreate(
                data,
                for: reference,
                counterReference: store.document(FirestorePath.counter(uid, document: .todo))
            )
            logger.info("Successfully upserted todo")
        } catch {
            logger.error("Failed to upsert todo", error: error)
            record(error, code: .upsertTodo)
            throw error
        }
    }

    func deleteTodo(todoId: String) async throws {
        guard Auth.auth().currentUser?.uid != nil else { throw DataLayerError.notAuthenticated }

        logger.info("Requesting todo deletion")
        do {
            try await FunctionAPIClient.shared.send(.requestTodoDeletion(todoId))
            logger.info("Successfully requested todo deletion")
        } catch {
            logger.error("Failed to request todo deletion", error: error)
            record(error, code: .deleteTodo)
            throw error
        }
    }

    func undoDeleteTodo(todoId: String) async throws {
        guard Auth.auth().currentUser?.uid != nil else { throw DataLayerError.notAuthenticated }

        logger.info("Undoing todo deletion")
        do {
            try await FunctionAPIClient.shared.send(.undoTodoDeletion(todoId))
            logger.info("Successfully undone todo deletion")
        } catch {
            logger.error("Failed to undo todo deletion", error: error)
            record(error, code: .undoDeleteTodo)
            throw error
        }
    }

    private func upsertTodoWithNumberOnCreate(
        _ data: [String: Any],
        for todoReference: DocumentReference,
        counterReference: DocumentReference
    ) async throws {
        _ = try await store.runTransaction { transaction, errorPointer in
            do {
                let todoSnapshot = try transaction.getDocument(todoReference)
                var todoData = data

                if !todoSnapshot.exists {
                    let counterSnapshot = try transaction.getDocument(counterReference)
                    let nextNumber: Int
                    if let storedNumber = counterSnapshot.data()?[CounterFieldKey.nextNumber.rawValue] as? Int {
                        nextNumber = storedNumber
                    } else if counterSnapshot.exists {
                        errorPointer?.pointee = NSError(
                            domain: "TodoServiceImpl",
                            code: 1,
                            userInfo: [NSLocalizedDescriptionKey: "Todo counter is invalid."]
                        )
                        return nil
                    } else {
                        nextNumber = 1
                    }

                    todoData[TodoDocumentFieldKey.number.rawValue] = nextNumber
                    transaction.setData(
                        [
                            CounterFieldKey.nextNumber.rawValue: nextNumber + 1,
                            CounterFieldKey.updatedAt.rawValue: FieldValue.serverTimestamp()
                        ],
                        forDocument: counterReference,
                        merge: true
                    )
                }

                transaction.setData(todoData, forDocument: todoReference, merge: true)
                return nil
            } catch let error as NSError {
                errorPointer?.pointee = error
                return nil
            }
        }
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
}
