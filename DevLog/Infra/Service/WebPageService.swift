//
//  WebPageService.swift
//  DevLog
//
//  Created by opfic on 6/3/25.
//

import FirebaseAuth
import FirebaseFirestore
import FirebaseFunctions

final class WebPageService {
    private enum FunctionName: String {
        case requestWebPageDeletion
        case undoWebPageDeletion
    }

    private let store = Firestore.firestore()
    private let functions = Functions.functions(region: "asia-northeast3")
    private let encoder = Firestore.Encoder()
    private let logger = Logger(category: "WebPageService")

    /// 저장한 웹페이지를 모두 불러옴
    func fetchWebPages(_ query: String) async throws -> [WebPageResponse] {
        logger.info("Fetching web pages")
        
        guard let uid = Auth.auth().currentUser?.uid else {
            logger.error("User not authenticated")
            throw AuthError.notAuthenticated
        }

        do {
            let collectionRef = store.collection(FirestorePath.webPages(uid))
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
            let docRef = store.document(FirestorePath.webPage(uid, documentId: documentID))
            let data = try encoder.encode(request)
            try await docRef.setData(data, merge: true)
            logger.info("Successfully upserted web page")
        } catch {
            logger.error("Failed to upsert web page", error: error)
            throw error
        }
    }

    func deleteWebPage(_ urlString: String) async throws {
        logger.info("Requesting web page deletion: \(urlString)")

        guard Auth.auth().currentUser?.uid != nil else {
            logger.error("User not authenticated")
            throw AuthError.notAuthenticated
        }

        do {
            let function = functions.httpsCallable(FunctionName.requestWebPageDeletion)
            _ = try await function.call(["urlString": urlString])
            logger.info("Successfully requested web page deletion")
        } catch {
            logger.error("Failed to request web page deletion", error: error)
            throw error
        }
    }

    func undoDeleteWebPage(_ urlString: String) async throws {
        logger.info("Undoing web page deletion: \(urlString)")

        guard Auth.auth().currentUser?.uid != nil else {
            logger.error("User not authenticated")
            throw AuthError.notAuthenticated
        }

        do {
            let function = functions.httpsCallable(FunctionName.undoWebPageDeletion)
            _ = try await function.call(["urlString": urlString])
            logger.info("Successfully undone web page deletion")
        } catch {
            logger.error("Failed to undo web page deletion", error: error)
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
        if data[WebPageFieldKey.deletingAt.rawValue] is Timestamp {
            return nil
        }
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
        case deletingAt // 삭제 요청은 되었지만, 5초 유예 후 최종 삭제되기 전 상태
    }
}
