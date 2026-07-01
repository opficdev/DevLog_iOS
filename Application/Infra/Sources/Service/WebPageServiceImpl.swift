//
//  WebPageServiceImpl.swift
//  Infra
//
//  Created by opfic on 6/3/25.
//

import FirebaseAuth
import FirebaseFirestore
import Core
import Data

final class WebPageServiceImpl: WebPageService {
    private enum CrashlyticsError {
        static let domain = "DevLogInfra.WebPageServiceImpl"

        enum Code: Int {
            case fetchWebPages = 1
            case upsertWebPage
            case deleteWebPage
            case undoDeleteWebPage
        }
    }

    private let store = FirebaseConfiguration.firestore
    private let encoder = Firestore.Encoder()
    private let logger = Logger(category: "WebPageServiceImpl")

    /// 저장한 웹페이지를 모두 불러옴
    func fetchWebPages(_ query: String) async throws -> [WebPageResponse] {
        logger.info("Fetching web pages")
        
        guard let uid = Auth.auth().currentUser?.uid else {
            logger.error("User not authenticated")
            throw DataLayerError.notAuthenticated
        }

        do {
            let collectionRef = store.collection(FirestorePath.webPages(uid))
                .whereField(WebPageFieldKey.isDeleted.rawValue, isEqualTo: false)
            let snapshot = try await collectionRef.getDocuments()
            let items: [WebPageResponse] = snapshot.documents.compactMap { makeResponse(from: $0) }

            let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedQuery.isEmpty else {
                logger.info("Successfully fetched \(items.count) web pages")
                return items
            }

            let filtered = items.filter {
                $0.title.localizedCaseInsensitiveContains(trimmedQuery) ||
                $0.displayURL.localizedCaseInsensitiveContains(trimmedQuery)
            }
            logger.info("Successfully fetched \(filtered.count) web pages with query")
            return filtered
        } catch {
            logger.error("Failed to fetch web pages", error: error)
            record(error, code: .fetchWebPages)
            throw error
        }
    }

    /// 웹페이지를 추가 또는 업데이트
    func upsertWebPage(_ request: WebPageRequest) async throws {
        logger.info("Upserting web page: \(request.url)")
        
        guard let uid = Auth.auth().currentUser?.uid else {
            logger.error("User not authenticated")
            throw DataLayerError.notAuthenticated
        }

        do {
            let docID = documentID(for: request.url)
            let docRef = store.document(FirestorePath.webPage(uid, documentId: docID))
            let data = try encoder.encode(request)
            try await docRef.setData(data, merge: true)
            logger.info("Successfully upserted web page")
        } catch {
            logger.error("Failed to upsert web page", error: error)
            record(error, code: .upsertWebPage)
            throw error
        }
    }

    func deleteWebPage(_ id: String) async throws {
        logger.info("Requesting web page deletion: \(id)")

        guard Auth.auth().currentUser?.uid != nil else {
            logger.error("User not authenticated")
            throw DataLayerError.notAuthenticated
        }

        do {
            try await FunctionAPIClient.shared.send(
                .requestWebPageDeletion(id)
            )
            logger.info("Successfully requested web page deletion")
        } catch {
            logger.error("Failed to request web page deletion", error: error)
            record(error, code: .deleteWebPage)
            throw error
        }
    }

    func undoDeleteWebPage(_ id: String) async throws {
        logger.info("Undoing web page deletion: \(id)")

        guard Auth.auth().currentUser?.uid != nil else {
            logger.error("User not authenticated")
            throw DataLayerError.notAuthenticated
        }

        do {
            try await FunctionAPIClient.shared.send(
                .undoWebPageDeletion(id)
            )
            logger.info("Successfully undone web page deletion")
        } catch {
            logger.error("Failed to undo web page deletion", error: error)
            record(error, code: .undoDeleteWebPage)
            throw error
        }
    }
}

private extension WebPageServiceImpl {
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

    func documentID(for url: String) -> String {
        if let encoded = url.addingPercentEncoding(withAllowedCharacters: .alphanumerics) {
            return encoded
        }
        let base64 = Data(url.utf8).base64EncodedString()
        return base64
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "=", with: "")
    }

    func makeResponse(from snapshot: QueryDocumentSnapshot) -> WebPageResponse? {
        let data = snapshot.data()
        guard
            (data[WebPageFieldKey.isDeleted.rawValue] as? Bool) != true,
            let title = data[WebPageFieldKey.title.rawValue] as? String,
            let url = data[WebPageFieldKey.url.rawValue] as? String,
            let displayURL = data[WebPageFieldKey.displayURL.rawValue] as? String,
            let imageURL = data[WebPageFieldKey.imageURL.rawValue] as? String else {
            return nil
        }

        return WebPageResponse(
            id: snapshot.documentID,
            title: title,
            url: url,
            displayURL: displayURL,
            imageURL: imageURL
        )
    }

    enum WebPageFieldKey: String {
        case title
        case url
        case displayURL
        case imageURL
        case isDeleted  // 삭제 요청으로 서버에서 soft deletion이 된 상태
    }
}
