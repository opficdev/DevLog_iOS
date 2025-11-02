//
//  GoogleSignInService.swift
//  DevLog
//
//  Created by opfic on 6/4/25.
//

import FirebaseAuth
import FirebaseFirestore
import FirebaseMessaging
import Foundation
import GoogleSignIn

class GoogleSignInService: SignInServicing {
    private let store = Firestore.firestore()
    private let messaging = Messaging.messaging()

    func signIn() async throws -> AuthenticationData {
        guard let topVC = topViewController() else {
            throw URLError(.cannotFindHost)
        }
        
        let gidSignIn = try await GIDSignIn.sharedInstance.signIn(withPresenting: topVC)
        
        guard let idToken = gidSignIn.user.idToken?.tokenString else {
            throw URLError(.badServerResponse)
        }
        
        let accessToken = gidSignIn.user.accessToken.tokenString
        let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
        
        let result = try await Auth.auth().signIn(with: credential)
        
        if let photoURL = gidSignIn.user.profile?.imageURL(withDimension: 200) {
            let changeRequest = result.user.createProfileChangeRequest()
            changeRequest.photoURL = photoURL
            changeRequest.displayName = gidSignIn.user.profile?.name
            
            try await changeRequest.commitChanges()
        }

        let fcmToken = try await messaging.token()

        return result.user.toData(providerID: .google, fcmToken: fcmToken)
    }
}

extension GoogleSignInService {
    func topViewController(controller: UIViewController? = nil) -> UIViewController? {
        let keyWindow = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }

        let controller = controller ?? keyWindow?.rootViewController
        
        if let navigationController = controller as? UINavigationController {
            return topViewController(controller: navigationController.visibleViewController)
        }
        
        if let tabController = controller as? UITabBarController, let selected = tabController.selectedViewController {
            return topViewController(controller: selected)
        }
        
        if let presented = controller?.presentedViewController {
            return topViewController(controller: presented)
        }
        
        return controller
    }
}
