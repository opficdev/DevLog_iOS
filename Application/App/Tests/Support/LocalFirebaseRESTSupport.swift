//
//  LocalFirebaseRESTSupport.swift
//  AppTests
//
//  Created by opfic on 4/6/26.
//

import Foundation

final class LocalFirebaseRESTSupport {
    struct AuthSession {
        let userId: String
        let idToken: String
    }

    struct SeededWebPage {
        let documentId: String
        let urlString: String
    }

    static let shared = LocalFirebaseRESTSupport()

    private let authBaseURL = URL(string: "http://127.0.0.1:9298")!
    private let firestoreBaseURL = URL(string: "http://127.0.0.1:8280")!
    private let functionsBaseURL = URL(string: "http://127.0.0.1:5201")!

    private init() { }

    func anonymousSignIn() async throws -> AuthSession {
        let googleServiceInfo = try loadGoogleServiceInfo()
        var request = URLRequest(
            url: authBaseURL.appending(
                path: "identitytoolkit.googleapis.com/v1/accounts:signUp",
                directoryHint: .notDirectory
            ).appending(queryItems: [
                URLQueryItem(name: "key", value: googleServiceInfo.apiKey)
            ])
        )
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(
            withJSONObject: ["returnSecureToken": true]
        )

        let payload = try await sendJSON(request)
        guard
            let userId = payload["localId"] as? String,
            let idToken = payload["idToken"] as? String
        else {
            throw RESTError.invalidResponse
        }

        return AuthSession(
            userId: userId,
            idToken: idToken
        )
    }

    func seedPushNotification(
        userId: String,
        notificationId: String = UUID().uuidString
    ) async throws -> String {
        let fields = [
            "title": stringValue("테스트 알림"),
            "body": stringValue("undo 통합 테스트"),
            "receivedAt": timestampValue(Date()),
            "isRead": booleanValue(false),
            "todoId": stringValue("todo-\(notificationId)"),
            "todoCategory": stringValue("feature"),
            "isDeleted": booleanValue(false)
        ]

        try await upsertDocument(
            documentPath: "users/\(userId)/notifications/\(notificationId)",
            fields: fields
        )

        return notificationId
    }

    func seedWebPage(
        userId: String,
        documentId: String = UUID().uuidString,
        urlString: String = "https://example.com/\(UUID().uuidString)"
    ) async throws -> SeededWebPage {
        let fields = [
            "title": stringValue("Example"),
            "url": stringValue(urlString),
            "displayURL": stringValue(urlString),
            "imageURL": stringValue(""),
            "isDeleted": booleanValue(false)
        ]

        try await upsertDocument(
            documentPath: "users/\(userId)/webPages/\(documentId)",
            fields: fields
        )

        return SeededWebPage(
            documentId: documentId,
            urlString: urlString
        )
    }

    func requestPushNotificationDeletion(
        notificationId: String,
        idToken: String
    ) async throws {
        _ = try await callFunction(
            name: "requestPushNotificationDeletion",
            idToken: idToken,
            data: ["notificationId": notificationId]
        )
    }

    func undoPushNotificationDeletion(
        notificationId: String,
        idToken: String
    ) async throws {
        _ = try await callFunction(
            name: "undoPushNotificationDeletion",
            idToken: idToken,
            data: ["notificationId": notificationId]
        )
    }

    func requestWebPageDeletion(
        urlString: String,
        idToken: String
    ) async throws {
        _ = try await callFunction(
            name: "requestWebPageDeletion",
            idToken: idToken,
            data: ["urlString": urlString]
        )
    }

    func undoWebPageDeletion(
        urlString: String,
        idToken: String
    ) async throws {
        _ = try await callFunction(
            name: "undoWebPageDeletion",
            idToken: idToken,
            data: ["urlString": urlString]
        )
    }

    func fetchPushNotificationIDs(userId: String) async throws -> [String] {
        let googleServiceInfo = try loadGoogleServiceInfo()
        let url = firestoreBaseURL.appending(
            path: "v1/projects/\(googleServiceInfo.projectId)/databases/\(databaseID())/documents/users/" +
                "\(userId)/notifications",
            directoryHint: .notDirectory
        )
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw RESTError.invalidResponse
        }
        guard 200 ..< 300 ~= httpResponse.statusCode else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw RESTError.unsuccessfulStatusCode(httpResponse.statusCode, body)
        }

        let payload = try decodeJSON(data)
        let documents = payload["documents"] as? [[String: Any]] ?? []

        return documents.compactMap { document in
            guard
                let name = document["name"] as? String,
                let fields = document["fields"] as? [String: [String: Any]],
                boolValue(for: "isDeleted", in: fields) != true
            else {
                return nil
            }

            return name.split(separator: "/").last.map(String.init)
        }
    }

    func fetchWebPageURLs(userId: String) async throws -> [String] {
        let googleServiceInfo = try loadGoogleServiceInfo()
        let url = firestoreBaseURL.appending(
            path: "v1/projects/\(googleServiceInfo.projectId)/databases/\(databaseID())" +
                "/documents/users/\(userId)/webPages",
            directoryHint: .notDirectory
        )
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw RESTError.invalidResponse
        }
        guard 200 ..< 300 ~= httpResponse.statusCode else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw RESTError.unsuccessfulStatusCode(httpResponse.statusCode, body)
        }

        let payload = try decodeJSON(data)
        let documents = payload["documents"] as? [[String: Any]] ?? []

        return documents.compactMap { document in
            guard
                let fields = document["fields"] as? [String: [String: Any]],
                boolValue(for: "isDeleted", in: fields) != true
            else {
                return nil
            }

            return fields["url"]?["stringValue"] as? String
        }
    }

    func waitUntil(
        timeout: Duration = .seconds(3),
        pollInterval: Duration = .milliseconds(100),
        _ condition: @escaping () async throws -> Bool
    ) async throws {
        let continuousClock = ContinuousClock()
        let deadline = continuousClock.now + timeout

        while continuousClock.now < deadline {
            if try await condition() {
                return
            }
            try await Task.sleep(for: pollInterval)
        }

        throw RESTError.timedOut
    }
}

private extension LocalFirebaseRESTSupport {
    struct GoogleServiceInfo {
        let apiKey: String
        let projectId: String
    }

    enum RESTError: Error {
        case invalidResponse
        case unsuccessfulStatusCode(Int, String)
        case missingConfiguration
        case timedOut
    }

    func loadGoogleServiceInfo() throws -> GoogleServiceInfo {
        var fileURL = URL(fileURLWithPath: #filePath)

        while fileURL.lastPathComponent != "DevLog_iOS" {
            let nextURL = fileURL.deletingLastPathComponent()
            if nextURL == fileURL {
                throw RESTError.missingConfiguration
            }
            fileURL = nextURL
        }

        let plistURL = fileURL
            .appending(path: "DevLog")
            .appending(path: "Resource")
            .appending(path: "GoogleService-Info.plist")
        let data = try Data(contentsOf: plistURL)
        guard
            let payload = try PropertyListSerialization.propertyList(
                from: data,
                options: [],
                format: nil
            ) as? [String: Any],
            let apiKey = payload["API_KEY"] as? String,
            let projectId = payload["PROJECT_ID"] as? String
        else {
            throw RESTError.missingConfiguration
        }

        return GoogleServiceInfo(
            apiKey: apiKey,
            projectId: projectId
        )
    }

    func callFunction(
        name: String,
        idToken: String,
        data: [String: Any]
    ) async throws -> [String: Any] {
        let googleServiceInfo = try loadGoogleServiceInfo()
        var request = URLRequest(
            url: functionsBaseURL.appending(
                path: "\(googleServiceInfo.projectId)/asia-northeast3/\(name)",
                directoryHint: .notDirectory
            )
        )
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: ["data": data])
        return try await sendJSON(request)
    }

    func upsertDocument(
        documentPath: String,
        fields: [String: [String: Any]]
    ) async throws {
        let googleServiceInfo = try loadGoogleServiceInfo()
        let encodedPath = encode(documentPath)
        var request = URLRequest(
            url: firestoreBaseURL.appending(
                path: "v1/projects/\(googleServiceInfo.projectId)/databases/\(databaseID())" +
                    "/documents/\(encodedPath)",
                directoryHint: .notDirectory
            )
        )
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: ["fields": fields])
        _ = try await sendJSON(request)
    }

    func sendJSON(_ request: URLRequest) async throws -> [String: Any] {
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw RESTError.invalidResponse
        }
        guard 200 ..< 300 ~= httpResponse.statusCode else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw RESTError.unsuccessfulStatusCode(httpResponse.statusCode, body)
        }
        return try decodeJSON(data)
    }

    func decodeJSON(_ data: Data) throws -> [String: Any] {
        guard let payload = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw RESTError.invalidResponse
        }
        return payload
    }

    func encode(_ path: String) -> String {
        path.split(separator: "/").map {
            String($0).addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? String($0)
        }.joined(separator: "/")
    }

    func databaseID() -> String {
        let environmentValue = ProcessInfo.processInfo.environment["FIRESTORE_DATABASE_ID"]?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if let environmentValue, !environmentValue.isEmpty {
            return environmentValue
        }

        let bundleValue = Bundle.main.object(forInfoDictionaryKey: "FIRESTORE_DATABASE_ID") as? String
        let databaseID = bundleValue?.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let databaseID, !databaseID.isEmpty, !databaseID.hasPrefix("$(") else {
            return "staging"
        }

        return databaseID
    }

    func stringValue(_ value: String) -> [String: Any] {
        ["stringValue": value]
    }

    func booleanValue(_ value: Bool) -> [String: Any] {
        ["booleanValue": value]
    }

    func timestampValue(_ value: Date) -> [String: Any] {
        ["timestampValue": value.formatted(.iso8601)]
    }

    func boolValue(
        for field: String,
        in fields: [String: [String: Any]]?
    ) -> Bool? {
        fields?[field]?["booleanValue"] as? Bool
    }

}
