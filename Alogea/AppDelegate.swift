//
//  AppDelegate.swift
//  Alogea
//
//  Created by mikeMBP on 02/10/2016.
//  Copyright © 2016 AppToolFactory. All rights reserved.
//

import UIKit
import CoreData
import UserNotifications

var notificationsAuthorised: Bool = false

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    var tabBarViews: [UIViewController]!
    
    lazy var stack : CoreDataStack = {
        let options  = [NSPersistentStoreUbiquitousContentNameKey: "Alogea", NSMigratePersistentStoresAutomaticallyOption: true, NSInferMappingModelAutomaticallyOption: true] as [String : Any]
        
        return CoreDataStack(modelName: "Alogea", storeName: "Alogea", options: options as NSDictionary?)
        
    }()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        tabBarViews = {
            let tBC = (UIApplication.shared.delegate as! AppDelegate).window!.rootViewController as! UITabBarController
            if let controllers = tBC.viewControllers { return controllers }
            else { return [] }
        }()
        
        if notificationsAuthorised != true {
            requestNotificationAuthorisation()
        }
        registerNotificationCategories()
        
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
        
        reviewNotificationsDeliveredInBackground()
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        self.saveContext()
    }
    
    // MARK: - Notifications
    
    func requestNotificationAuthorisation() {
        
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { (granted, error) in
            
            notificationsAuthorised = granted
        }
    }
    
    func registerNotificationCategories() {
        
        let center = UNUserNotificationCenter.current()
        center.getNotificationCategories(completionHandler: {
            (categories) in
            
            for category in categories {
                if category.identifier == "drugReminderCategory" { return }
            }

        })
        
        // defining actions displayed as buttons with the notifications
        let dismissAction = UNNotificationAction(identifier: "dismissAction", title: "dismiss", options: UNNotificationActionOptions(rawValue: 0))
        
        // defining categories containing one or more actions
        let drugReminderCategory = UNNotificationCategory(identifier: "drugReminderCategory", actions: [dismissAction], intentIdentifiers: [], options: .customDismissAction)
        
        center.setNotificationCategories([drugReminderCategory])
    }
    
    // possible option of checking notifications that have been displayed while App in background
    func reviewNotificationsDeliveredInBackground() {
        let center = UNUserNotificationCenter.current()
        center.getDeliveredNotifications(completionHandler: {(notifications: [UNNotification]) in
            for notification in notifications {
                if notification.request.content.categoryIdentifier == "drugReminderCategory" {
                    
                    // do relevant stuff e.g. check if repeat is 3-daily and re-schedule next repeat manually
                }
            }
            center.removeDeliveredNotifications(withIdentifiers: ["drugID here"])
        })
    }
    
    //removing specific notifications
    func removeNotifications(withIdentifier: String?, withCategory: String?) {
        
        guard withIdentifier != nil || withCategory != nil else {
            return
        }
        
        let center = UNUserNotificationCenter.current()
        center.getPendingNotificationRequests(completionHandler: {
            (requests: [UNNotificationRequest]) in
            for request in requests {
                if request.identifier == withIdentifier || request.content.categoryIdentifier == withCategory {
                    center.removePendingNotificationRequests(withIdentifiers: [withIdentifier!])
                }
            }
        })
    }
    
    // handling notification actions received from system
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        
        // handling non-specific/non-action user actions e.g. deleting notification in NotificationCenter
        if response.actionIdentifier == UNNotificationDismissActionIdentifier {
            // The user dismissed the notification without taking action
            print("user deleted action in NotificatioCenter")
        }
        else if response.actionIdentifier == UNNotificationDefaultActionIdentifier {
            // The user launched the app
            print("user launched app on notification")
        }
        
        // handling category specific notification actions from the user
        if response.notification.request.content.categoryIdentifier == "drugReminderCategory" {
            // Handle the actions for the expired timer.
            if response.actionIdentifier == "dismiss" {
                // Invalidate the old timer and create a new one. . .
                print("action dismiss received in notification")
            }
            else if response.actionIdentifier == "any other action" {
                // Invalidate the timer. . .
            }
        }
        
        // Else handle actions for other notification types. . .
    }




    // MARK: - Core Data stack

//    lazy var persistentContainer: NSPersistentContainer = {
//        /*
//         The persistent container for the application. This implementation
//         creates and returns a container, having loaded the store for the
//         application to it. This property is optional since there are legitimate
//         error conditions that could cause the creation of the store to fail.
//        */
//        let container = NSPersistentContainer(name: "Alogea")
//        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
//            if let error = error as NSError? {
//                // Replace this implementation with code to handle the error appropriately.
//                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
//                 
//                /*
//                 Typical reasons for an error here include:
//                 * The parent directory does not exist, cannot be created, or disallows writing.
//                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
//                 * The device is out of space.
//                 * The store could not be migrated to the current model version.
//                 Check the error message to determine what the actual problem was.
//                 */
//                fatalError("Unresolved error \(error), \(error.userInfo)")
//            }
//        })
//        return container
//    }()

    // MARK: - Core Data Saving support

    func saveContext () {
        
        if stack.context.hasChanges {
            do {
                try stack.context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("An error occurred when saving the CoreDataStack.context: \(nserror), \(nserror.userInfo)")
            }
            
        }
        
//        let context = persistentContainer.viewContext
//        if context.hasChanges {
//            do {
//                try context.save()
//            } catch {
//                // Replace this implementation with code to handle the error appropriately.
//                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
//                let nserror = error as NSError
//                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
//            }
//        }
    }

}

