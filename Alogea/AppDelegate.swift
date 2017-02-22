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


let notification_MedRemindersOn = "MedRemindersOn"
let iCloudBackUpsOn = "iCloudBackupsOn"
let notification_MedReminderCategory = "DrugReminderCategory"

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    var tabBarViews: [UIViewController]!
    var mainView: MainViewController!
    
    var reminderNotificationCategoryRegistered = false
    
    var notificationsAuthorised: Bool = false
    var authorisedNotificationSettings: UNNotificationSettings?
    
    var appVersion:String = {
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            return version
        } else { return "Version Number not Available" }
    }()
    
    var appBuild: String = {
        if let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            return build
        } else { return "Build Number not Available" }
    }()
    
    lazy var deviceBasedSizeFactor: CGSize = {
        // relative to iPhone 6 screen dimensions
        let screenSize = UIScreen.main.bounds
        let size = CGSize(width: screenSize.width / 375.0, height: screenSize.height / 667.0)
        return size

    }()
    
    lazy var stack : CoreDataStack = {
        let options  = [NSPersistentStoreUbiquitousContentNameKey: "Alogea", NSMigratePersistentStoresAutomaticallyOption: true, NSInferMappingModelAutomaticallyOption: true, NSPersistentStoreFileProtectionKey: FileProtectionType.completeUnlessOpen] as [String : Any]
        
        return CoreDataStack(modelName: "Alogea", storeName: "Alogea", options: options as NSDictionary?)
        
    }()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        print("Device name \(UIDevice.current.name)")
        tabBarViews = {
            let tBC = self.window!.rootViewController as! UITabBarController
            if let navControllers = tBC.viewControllers { return navControllers }
            else { return [] }
        }()
        if notificationsAuthorised != true {
            requestNotificationAuthorisation()
        }
        registerNotificationCategories()

        // find mainView in hierarchy of StoryBoard ViewControllers
        for navController in tabBarViews {
            for view in navController.childViewControllers {
                if view is MainViewController {
                    mainView = view as! MainViewController
                    UNUserNotificationCenter.current().delegate = mainView
                    break
                }
            }
        }
        
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
            
            self.notificationsAuthorised = granted
            self.updateAuthorisedNotifications()
        }
    }
    
    func updateAuthorisedNotifications() {
        UNUserNotificationCenter.current().getNotificationSettings(completionHandler: {
            (settings) in
            self.authorisedNotificationSettings = settings
            if settings.authorizationStatus == UNAuthorizationStatus.authorized {
                self.notificationsAuthorised = true
            } else {
                self.notificationsAuthorised = false
            }
        })
        
    }
    
    func registerNotificationCategories() {
        
        let center = UNUserNotificationCenter.current()
        center.getNotificationCategories(completionHandler: {
            (categories) in
            
            for category in categories {
                if category.identifier == notification_MedReminderCategory {
                    print("\(notification_MedReminderCategory) found as already registered")
                    self.reminderNotificationCategoryRegistered = true
                    return
                }
            }

        })
        
        // defining actions displayed as buttons with the notifications
        let dismissAction = UNNotificationAction(identifier: "dismissAction", title: "dismiss", options: UNNotificationActionOptions(rawValue: 0))
        
        // defining categories containing one or more actions
        let drugReminderCategory = UNNotificationCategory(identifier: notification_MedReminderCategory, actions: [dismissAction], intentIdentifiers: [], options: .customDismissAction)
        
        center.setNotificationCategories([drugReminderCategory])
    }
    
    // possible option of checking notifications that have been displayed while App in background
    func reviewNotificationsDeliveredInBackground() {
        let center = UNUserNotificationCenter.current()
        center.getDeliveredNotifications(completionHandler: {(notifications: [UNNotification]) in
            for notification in notifications {
                if notification.request.content.categoryIdentifier == notification_MedReminderCategory {
                    
                    // do relevant stuff e.g. check if repeat is 3-daily and re-schedule next repeat manually
                }
            }
            center.removeDeliveredNotifications(withIdentifiers: ["drugID here"])
        })
    }
    
    //removing specific notifications
    func removeSpecificNotifications(withIdentifier: String?, withCategory: String?) {
        
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
    
    //removing all notifications of a category
    func removeCategoryNotifications(withCategory: String?) {
        
        guard withCategory != nil else {
            return
        }
        
        let center = UNUserNotificationCenter.current()
        center.getPendingNotificationRequests(completionHandler: {
            (requests: [UNNotificationRequest]) in
            for request in requests {
                if request.content.categoryIdentifier == withCategory {
                    print("cancelling notification\(request)")
                    center.removePendingNotificationRequests(withIdentifiers: [request.identifier])
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
        if response.notification.request.content.categoryIdentifier == notification_MedReminderCategory {
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
        
    }
    
    // MARK: - Error handling
    

}

public extension UIWindow {
    // used for ErrorManager related function calls to find currently visible VC if class where error occurred is not a VC
    public var visibleViewController: UIViewController? {
        return UIWindow.getVisibleViewControllerFrom(vc: self.rootViewController)
    }
    
    public static func getVisibleViewControllerFrom(vc: UIViewController?) -> UIViewController? {
        if let nc = vc as? UINavigationController {
            return UIWindow.getVisibleViewControllerFrom(vc: nc.visibleViewController)
        } else if let tc = vc as? UITabBarController {
            return UIWindow.getVisibleViewControllerFrom(vc: tc.selectedViewController)
        } else {
            if let pvc = vc?.presentedViewController {
                return UIWindow.getVisibleViewControllerFrom(vc: pvc)
            } else {
                return vc
            }
        }
    }
}

