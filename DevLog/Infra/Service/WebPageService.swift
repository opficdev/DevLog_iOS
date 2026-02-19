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
    func fetchWebPages() async throws -> [WebPageURLResponse] {
        logger.info("Fetching web pages")
        
        guard let uid = Auth.auth().currentUser?.uid else {
            logger.error("User not authenticated")
            throw AuthError.notAuthenticated
        }

        do {
            let webPageInfoRef = store.document("users/\(uid)/userData/webPageInfos")
            let doc = try await webPageInfoRef.getDocument()

            if doc.exists, let data = doc.data() {
                if let webPageInfos = data["webPageInfos"] as? [String] {
                    logger.info("Successfully fetched \(webPageInfos.count) web pages")
                    return webPageInfos.map { WebPageURLResponse(urlString: $0) }
                }
            }
            logger.error("Web page data not found or invalid")
            throw URLError(.badServerResponse)
        } catch {
            logger.error("Failed to fetch web pages", error: error)
            throw error
        }
    }

    /// 웹페이지를 추가 또는 업데이트
    func upsertWebPage(_ urlString: String) async throws {
        logger.info("Upserting web page: \(urlString)")
        
        guard let uid = Auth.auth().currentUser?.uid else {
            logger.error("User not authenticated")
            throw AuthError.notAuthenticated
        }

        do {
            let infosRef = store.document("users/\(uid)/userData/webPageInfos")
            try await infosRef.setData(
                ["webPageInfos": FieldValue.arrayUnion([urlString])],
                merge: true
            )
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
            let infosRef = store.document("users/\(uid)/userData/webPageInfos")
            try await infosRef.updateData(["webPageInfos": FieldValue.arrayRemove([urlString])])
            logger.info("Successfully deleted web page")
        } catch {
            logger.error("Failed to delete web page", error: error)
            throw error
        }
    }
}
