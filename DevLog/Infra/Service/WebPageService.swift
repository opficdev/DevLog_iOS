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

    /// 저장한 웹페이지를 모두 불러옴
    func fetchWebPages() async throws -> [WebPageResponse] {
        guard let uid = Auth.auth().currentUser?.uid else {
            throw AuthError.notAuthenticated
        }

        let webPageInfoRef = store.document("users/\(uid)/userData/webPageInfos")
        let doc = try await webPageInfoRef.getDocument()

        if doc.exists, let data = doc.data() {
            if let webPageInfos = data["webPageInfos"] as? [String] {
                return webPageInfos.map { WebPageResponse(urlString: $0) }
            }
        }
        throw URLError(.badServerResponse)
    }

    /// 웹페이지를 추가 또는 업데이트
    func upsertWebPage(_ urlString: String) async throws {
        guard let uid = Auth.auth().currentUser?.uid else {
            throw AuthError.notAuthenticated
        }

        let infosRef = store.document("users/\(uid)/userData/webPageInfos")
        try await infosRef.setData(
            ["WebPageInfos": FieldValue.arrayUnion([urlString])],
            merge: true
        )
    }

    func deleteWebPage(_ urlString: String) async throws {
        guard let uid = Auth.auth().currentUser?.uid else {
            throw AuthError.notAuthenticated
        }

        let infosRef = store.document("users/\(uid)/userData/webPageInfos")
        try await infosRef.updateData(["WebPageInfos": FieldValue.arrayRemove([urlString])])
    }
}
