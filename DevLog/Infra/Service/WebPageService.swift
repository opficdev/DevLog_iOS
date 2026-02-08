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
    func fetchWebPages() async throws -> [WebPageInfo] {
        guard let uid = Auth.auth().currentUser?.uid else {
            throw AuthError.notAuthenticated
        }

        let webPageInfoRef = store.document("users/\(uid)/userData/webPageInfos")
        let doc = try await webPageInfoRef.getDocument()

        if doc.exists, let data = doc.data() {
            if let webPageInfos = data["webPageInfos"] as? [String] {
                return try await withThrowingTaskGroup(of: WebPageInfo.self, returning: [WebPageInfo].self) { group in
                    for urlString in webPageInfos {
                        group.addTask {
                            let doc = try await WebPageInfo.fetch(from: urlString)
                            return doc
                        }
                    }
         
                    var result = [WebPageInfo]()
                    for try await pageInfo in group {
                        result.append(pageInfo)
                    }

                    return result
                }
            }
        }
        throw URLError(.badServerResponse)
    }

    /// 웹페이지를 추가 또는 업데이트
    func upsertWebPage(_ info: WebPageInfo) async throws {
        guard let uid = Auth.auth().currentUser?.uid else {
            throw AuthError.notAuthenticated
        }

        let infosRef = store.document("users/\(uid)/userData/webPageInfos")
        try await infosRef.setData(
            ["WebPageInfos": FieldValue.arrayUnion([info.url.description])],
            merge: true
        )
    }
    
    func deleteWebPage(_ info: WebPageInfo) async throws {
        guard let uid = Auth.auth().currentUser?.uid else {
            throw AuthError.notAuthenticated
        }

        let infosRef = store.document("users/\(uid)/userData/webPageInfos")
        try await infosRef.updateData(["WebPageInfos": FieldValue.arrayRemove([info.url.description])])
    }
}
