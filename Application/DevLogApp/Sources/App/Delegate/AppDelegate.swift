//
//  AppDelegate.swift
//  DevLog
//
//  Created by opfic on 5/7/25.
//

import UIKit
import DevLogCore
import DevLogData
import Firebase
import GoogleSignIn

class AppDelegate: UIResponder, UIApplicationDelegate, MessagingDelegate {
    private let logger = Logger(category: "AppDelegate")
    private let container = AppDIContainer.shared

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
        _ = container.resolve(FCMTokenSyncHandler.self)
        _ = container.resolve(UserTimeZoneSyncHandler.self)
        _ = container.resolve(WidgetSyncEventHandler.self)

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
        NotificationCenter.default.post(name: .didRequestUserTimeZoneSync, object: nil)

        // Firebase Messaging 설정
        Messaging.messaging().delegate = self
        
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

    // FCMToken 갱신
    func messaging(
        _ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?
    ) {
        if let fcmToken = fcmToken {
            logger.info("FCM token: \(fcmToken)")
            NotificationCenter.default.post(
                name: .didRefreshFCMToken,
                object: nil,
                userInfo: ["fcmToken": fcmToken]
            )
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
