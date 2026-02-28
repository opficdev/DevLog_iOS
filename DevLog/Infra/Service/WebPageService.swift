//
//  WebPageService.swift
//  DevLog
//
//  Created by opfic on 6/3/25.
//

import FirebaseAuth
import FirebaseFirestore

final class WebPageService {
    private let store = Firestore.firestore()
    private let logger = Logger(category: "WebPageService")

    /// 저장한 웹페이지를 모두 불러옴
    func fetchWebPages(_ query: String) async throws -> [WebPageResponse] {
        logger.info("Fetching web pages")
        
        guard let uid = Auth.auth().currentUser?.uid else {
            logger.error("User not authenticated")
            throw AuthError.notAuthenticated
        }

        do {
            let collectionRef = store.collection("users/\(uid)/webPages")
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
            throw error
        }
    }

    /// 웹페이지를 추가 또는 업데이트
    func upsertWebPage(_ request: WebPageRequest) async throws {
        logger.info("Upserting web page: \(request.url)")
        
        guard let uid = Auth.auth().currentUser?.uid else {
            logger.error("User not authenticated")
            throw AuthError.notAuthenticated
        }

        do {
            let documentID = documentID(for: request.url)
            let docRef = store.document("users/\(uid)/webPages/\(documentID)")
            let data = try Firestore.Encoder().encode(request)
            try await docRef.setData(data, merge: true)
            logger.info("Successfully upserted web page")
        } catch {
            logger.error("Failed to upsert web page", error: error)
            throw error
        }
    }

    func deleteWebPage(_ urlString: String) async throws {
        logger.info("Deleting web page: \(urlString)")

        guard let uid = Auth.auth().currentUser?.uid else {
            logger.error("User not authenticated")
            throw AuthError.notAuthenticated
        }

        do {
            let documentID = documentID(for: urlString)
            let docRef = store
                .document("users/\(uid)/webPages/\(documentID)")
            try await docRef.delete()
            logger.info("Successfully deleted web page")
        } catch {
            logger.error("Failed to delete web page", error: error)
            throw error
        }
    }

    private func documentID(for url: String) -> String {
        if let encoded = url.addingPercentEncoding(withAllowedCharacters: .alphanumerics) {
            return encoded
        }
        let base64 = Data(url.utf8).base64EncodedString()
        return base64
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "=", with: "")
    }
}

private extension WebPageService {
    func makeResponse(from snapshot: QueryDocumentSnapshot) -> WebPageResponse? {
        let data = snapshot.data()
        guard
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
    }
}
