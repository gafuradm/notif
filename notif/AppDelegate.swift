//
//  AppDelegate.swift
//  notif
//
//  Created by Aleigh Dinara on 14.09.2023.
//

import UIKit
import UserNotifications
@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    let center = UNUserNotificationCenter.current()
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        center.requestAuthorization(options: [.alert, .sound, .badge]) { (success, error) in
            if success {
                print("Разрешение на отправку уведомлений получено")
            } else {
                print("Разрешение на отправку уведомлений отклонено")
            }
        }
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}

