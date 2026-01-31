//
//  GoogleAuthenticationService.swift
//  DevLog
//
//  Created by opfic on 6/4/25.
//

import FirebaseAuth
import FirebaseFirestore
import FirebaseFunctions
import FirebaseMessaging
import Foundation
import GoogleSignIn

final class GoogleAuthenticationService: AuthenticationService {
    private let store = Firestore.firestore()
    private let functions = Functions.functions(region: "asia-northeast3")
    private let messaging = Messaging.messaging()
    private var user: User? { Auth.auth().currentUser }
    private let provider = TopViewControllerProvider()

    @MainActor
    func signIn() async throws -> AuthenticationDataResponse {
        guard let topViewController = provider.topViewController() else {
            throw UIError.notFoundTopViewController
        }

        let signIn = try await GIDSignIn.sharedInstance.signIn(withPresenting: topViewController)

        guard let idToken = signIn.user.idToken?.tokenString else {
            throw URLError(.badServerResponse)
        }
        
        let accessToken = signIn.user.accessToken.tokenString
        let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
        
        let result = try await Auth.auth().signIn(with: credential)
        
        if let photoURL = signIn.user.profile?.imageURL(withDimension: 200) {
            let changeRequest = result.user.createProfileChangeRequest()
            changeRequest.photoURL = photoURL
            changeRequest.displayName = signIn.user.profile?.name

            try await changeRequest.commitChanges()
        }

        let fcmToken = try await messaging.token()

        return result.user.toData(providerID: .google, fcmToken: fcmToken)
    }

    func signOut(_ uid: String) async throws {
        let infoRef = store.document("users/\(uid)/userData/tokens")
        let doc = try await infoRef.getDocument()

        if doc.exists {
            try await infoRef.updateData(["fcmToken": FieldValue.delete()])
        }

        GIDSignIn.sharedInstance.signOut()
        try await GIDSignIn.sharedInstance.disconnect()

        try await messaging.deleteToken()

        try Auth.auth().signOut()
    }

    func deleteAuth(_ uid: String) async throws {
        let deleteFunction = functions.httpsCallable("deleteUserFirestoreData")

        _ = try await deleteFunction.call(["uid": uid])

        try await signOut(uid)
        try await Auth.auth().currentUser?.delete()
    }

    func link(uid: String, email: String) async throws {
        let topViewController = await MainActor.run {
            provider.topViewController()
        }
        guard let topViewController = topViewController else {
            throw UIError.notFoundTopViewController
        }

        if GIDSignIn.sharedInstance.hasPreviousSignIn() {
            GIDSignIn.sharedInstance.signOut()
        }

        let signIn = try await GIDSignIn.sharedInstance.signIn(withPresenting: topViewController)

        guard let googleEmail = signIn.user.profile?.email else {
            throw EmailFetchError.emailNotFound
        }

        if googleEmail != email {
            throw EmailFetchError.emailMismatch
        }

        guard let idToken = signIn.user.idToken?.tokenString else {
            throw URLError(.badServerResponse)
        }

        let accessToken = signIn.user.accessToken.tokenString
        let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)

        try await user?.link(with: credential)
    }

    func unlink(_ uid: String) async throws {
        GIDSignIn.sharedInstance.signOut()
        try await GIDSignIn.sharedInstance.disconnect()

        _ = try await user?.unlink(fromProvider: AuthProviderID.google.rawValue)
    }

}

final class TopViewControllerProvider {
    @MainActor
    func topViewController() -> UIViewController? {
        let keyWindow = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }

        let rootController = keyWindow?.rootViewController

        return topViewController(controller: rootController)
    }

    @MainActor
    private func topViewController(controller: UIViewController?) -> UIViewController? {
        if let navigationController = controller as? UINavigationController {
            return topViewController(controller: navigationController.visibleViewController)
        }

        if let tabController = controller as? UITabBarController,
           let selectedController = tabController.selectedViewController {
            return topViewController(controller: selectedController)
        }

        if let presentedController = controller?.presentedViewController {
            return topViewController(controller: presentedController)
        }

        return controller
    }
}
