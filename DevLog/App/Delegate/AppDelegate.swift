//
//  AppDelegate.swift
//  DevLog
//
//  Created by opfic on 5/7/25.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseFirestore
import FirebaseMessaging
import GoogleSignIn
import Combine
import UserNotifications

class AppDelegate: UIResponder, UIApplicationDelegate, MessagingDelegate {
    private let logger = Logger(category: "AppDelegate")
    private var store: Firestore { Firestore.firestore() }
    private var authStateListenerHandle: AuthStateDidChangeListenerHandle?
    private var cancellable: AnyCancellable?

    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        return GIDSignIn.sharedInstance.handle(url)
    }

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        FirebaseApp.configure()
        
        // 알림 권한 요청
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if let error = error {
                self.logger.error("Notification authorization error", error: error)
            } else {
                self.logger.info("Notification permission granted: \(granted)")
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }

        // 앱이 온그라운드로 되었을 때, 로그인 세션이 존재한다면 현재 유저의 timeZone 저장
        updateUserTimeZone()

        // Firebase Messaging 설정
        Messaging.messaging().delegate = self
        observeAuthState()
        
        // 앱이 완전 종료되어도, 알림을 통해 앱이 시작된 경우 처리
        if let remoteNotification = launchOptions?[.remoteNotification] as? [AnyHashable: Any] {
            Task { @MainActor in
                PushNotificationRoute.shared.handlePushTap(userInfo: remoteNotification)
            }
        }
        
        return true
    }
    
    // APNs 등록 성공
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        logger.info("APNs token: \(deviceToken.map { String(format: "%02.2hhx", $0) }.joined())")
        Messaging.messaging().apnsToken = deviceToken
    }

    // APNs 등록 실패
    func application(
        _ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        logger.error("Failed to register APNs token", error: error)
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        syncBadgeCount()
    }
    
    // FCMToken 갱신
    func messaging(
        _ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?
    ) {
        if let fcmToken = fcmToken {
            logger.info("FCM token: \(fcmToken)")
            NotificationCenter.default.post(name: .fcmToken, object: nil, userInfo: ["fcmToken": fcmToken])
        }
    }
}

private extension AppDelegate {
    func updateUserTimeZone() {
        Task {
            do {
                guard let uid = Auth.auth().currentUser?.uid else { return }
                let settingsRef = Firestore.firestore().document("users/\(uid)/userData/settings")

                try await settingsRef.setData(["timeZone": TimeZone.autoupdatingCurrent.identifier], merge: true)
            } catch {
                logger.error("Failed to update timeZone", error: error)
            }
        }
    }

    func observeAuthState() {
        authStateListenerHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self else { return }

            self.cancellable?.cancel()

            guard user != nil else {
                self.updateBadgeCount(0)
                return
            }

            self.startObservingBadgeCount()
            self.syncBadgeCount()
        }
    }

    func syncBadgeCount() {
        Task { @MainActor [weak self] in
            guard let self else { return }
            guard Auth.auth().currentUser != nil else {
                self.updateBadgeCount(0)
                return
            }

            do {
                let unreadNotificationCount = try await self.fetchUnreadNotificationCount()
                self.updateBadgeCount(unreadNotificationCount)
            } catch {
                self.logger.error("Failed to fetch unread notification count", error: error)
            }
        }
    }

    private func startObservingBadgeCount() {
        do {
            cancellable = try observeUnreadNotificationCount()
                .receive(on: DispatchQueue.main)
                .sink(
                    receiveCompletion: { [weak self] completion in
                        guard let self else { return }

                        if case .failure(let error) = completion {
                            self.logger.error("Failed to observe unread notification count", error: error)
                        }
                    },
                    receiveValue: { [weak self] count in
                        self?.updateBadgeCount(count)
                    }
                )
        } catch {
            logger.error("Failed to start observing badge count", error: error)
        }
    }

    private func fetchUnreadNotificationCount() async throws -> Int {
        logger.info("Fetching unread notification count")

        guard let uid = Auth.auth().currentUser?.uid else {
            logger.error("User not authenticated")
            throw AuthError.notAuthenticated
        }

        do {
            let snapshot = try await store.collection("users/\(uid)/notifications")
                .whereField("isRead", isEqualTo: false)
                .getDocuments()

            let unreadNotificationCount = snapshot.documents.count
            logger.info("Unread notification count: \(unreadNotificationCount)")
            return unreadNotificationCount
        } catch {
            logger.error("Failed to fetch unread notification count", error: error)
            throw error
        }
    }

    private func observeUnreadNotificationCount() throws -> AnyPublisher<Int, Error> {
        logger.info("Observing unread notification count")

        guard let uid = Auth.auth().currentUser?.uid else {
            logger.error("User not authenticated")
            throw AuthError.notAuthenticated
        }

        let subject = PassthroughSubject<Int, Error>()
        let listener = store.collection("users/\(uid)/notifications")
            .whereField("isRead", isEqualTo: false)
            .addSnapshotListener { [weak self] snapshot, error in
                if let error {
                    self?.logger.error("Failed to observe unread notification count", error: error)
                    subject.send(completion: .failure(error))
                    return
                }

                guard let snapshot else { return }

                let unreadNotificationCount = snapshot.documents.count
                self?.logger.info("Observed unread notification count: \(unreadNotificationCount)")
                subject.send(unreadNotificationCount)
            }

        return subject
            .handleEvents(receiveCancel: { listener.remove() })
            .eraseToAnyPublisher()
    }

    @MainActor
    private func updateBadgeCount(_ count: Int) {
        UNUserNotificationCenter.current().setBadgeCount(count) { [weak self] error in
            if let error {
                self?.logger.error("Failed to update badge count", error: error)
            }
        }
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    // 앱이 포그라운드에 있을 때 알림 표시
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        logger.info("Foreground notification: \(notification.request.content.userInfo)")
        completionHandler([.banner, .sound, .badge])
    }

    // 알림 클릭 처리
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        logger.info("Tapped notification: \(response.notification.request.content.userInfo)")
        let userInfo = response.notification.request.content.userInfo
        Task { @MainActor in
            PushNotificationRoute.shared.handlePushTap(userInfo: userInfo)
        }
        completionHandler()
    }
}

extension Notification.Name {
    static let fcmToken = Notification.Name("fcmToken")
}
