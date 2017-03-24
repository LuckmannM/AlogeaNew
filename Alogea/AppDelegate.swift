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
let notification_ScoreReminderCategory = "ScoreReminderCategory"

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    var window: UIWindow?
    
    var tabBarViews: [UIViewController]!
    var mainView: MainViewController!
    var backups: Backups!
    
    var medReminderNotificationCategoryRegistered = false
    var scoreReminderNotificationCategoryRegistered = false
    
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
        
        return CoreDataStack(modelName: "Alogea", storeName: "AlogeaStore", options: options as NSDictionary?)
        
    }()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
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
                } else if view is Backups {
                    backups = view as! Backups
                }
            }
        }
        
        UNUserNotificationCenter.current().delegate = self
        
// DEBUG
//        print("Checking pending notifications...")
//        UNUserNotificationCenter.current().getPendingNotificationRequests(completionHandler: {
//            (requests: [UNNotificationRequest]) in
//            for request in requests {
//                if request.content.categoryIdentifier == notification_MedReminderCategory {
//                    print("pending notification: \(request)")
//                }
//            }
//        })
// DEBUG
        
        stack.updateContextWithUbiquitousChangesObserver = true

        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
        
        stack.updateContextWithUbiquitousChangesObserver = false

    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        stack.updateContextWithUbiquitousChangesObserver = false
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
        
        stack.updateContextWithUbiquitousChangesObserver = true

        checkDeliveredNotifications()
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        checkDeliveredNotifications()
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        self.saveContext()
        if ErrorManager.sharedInstance().errorLogBook != nil {
            print()
            print("____ ERROR LOG BOOK ____")
            var i = 0
            for logEntry in ErrorManager.sharedInstance().errorLogBook! {
                print(" - Error /(i+1).")
                print("   location:\(logEntry.location)")
                print("   system message:\(logEntry.systemMessage ?? nil)")
                print("   erroInfo:\(logEntry.errorInfo)")
                i += 1
            }
        }
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
        
        // defining actions displayed as buttons with the notifications
        let dismissAction = UNNotificationAction(identifier: "dismissAction", title: "dismiss", options: UNNotificationActionOptions(rawValue: 0))

        let center = UNUserNotificationCenter.current()
        center.getNotificationCategories(completionHandler: {
            (categories) in
            
            var isRegistered = false
            
            // 1. check if medReminderCategory is registered, if not register it
            for category in categories {
                if category.identifier == notification_MedReminderCategory {
                    self.medReminderNotificationCategoryRegistered = true
                    isRegistered = true
                }
            }
            if !isRegistered {
                let drugReminderCategory = UNNotificationCategory(identifier: notification_MedReminderCategory, actions: [dismissAction], intentIdentifiers: [], options: .customDismissAction)
                center.setNotificationCategories([drugReminderCategory])
            }
            
            isRegistered = false
            // 2. check if scoreReminderCategory is registered, if not register it
            for category in categories {
                if category.identifier == notification_ScoreReminderCategory {
                    self.scoreReminderNotificationCategoryRegistered = true
                    isRegistered = true
                }
            }
            if !isRegistered {
                let scoreReminderCategory = UNNotificationCategory(identifier: notification_ScoreReminderCategory, actions: [dismissAction], intentIdentifiers: [], options: .customDismissAction)
                
                center.setNotificationCategories([scoreReminderCategory])
            }
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
                    center.removePendingNotificationRequests(withIdentifiers: [request.identifier])
                }
            }
        })
    }
    
    // handling notification actions received from system
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        if response.notification.request.content.categoryIdentifier == notification_MedReminderCategory {
                if (response.notification.request.content.userInfo["manualRepeat"] as? Bool ?? false) {
                    self.rescheduleMedReminder(drugID: response.notification.request.content.userInfo["drugID"] as! String)
                }
        }
        
        completionHandler()
    }
    
    func userNotificationCenter(_: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        // Displays a notification while App running in the foreground.
        // for displaying a standard system notification pass eg. [.alter, .sound] below
        // to show app internal dialog use [] empty array and use alertView or similar above the below completionHAndler()
        completionHandler([.alert, .sound])
    }

    
    func checkDeliveredNotifications() {
        UNUserNotificationCenter.current().getDeliveredNotifications(completionHandler: {
            (notifications: [UNNotification]) -> Void in
            
            if !UserDefaults.standard.bool(forKey: notification_MedRemindersOn) {
                UNUserNotificationCenter.current().removeAllDeliveredNotifications()
                return
            }
            
            for notification in notifications {
//                print("manual repeat? \(notification.request.content.userInfo["manualRepeat"] as? Bool)")
                if (notification.request.content.userInfo["manualRepeat"] as? Bool ?? false) {
                    self.rescheduleMedReminder(drugID: notification.request.content.userInfo["drugID"] as! String)
                }
            }
        })
    }
    
    func rescheduleMedReminder(drugID: String) {
        
        // this will be called when the content.userInfo for 'manualRepeat' is true.
        // this is set in DrugEpisode.scheduleReminder function only for meds with frequencyVar of >1 day and <1 week
        // this does not allow to use the 'repeat' for notificationRequest.
        // this manually reschedules these meds to their frequency, however, if the App is not run/ in the foreground from triggerDate and the next due time the next drugReminder is NOT scheduled, so there will be no alert.
        // this functionality would require the app to be notified of the notification while in the background when the user does NOT tap on the notification, and being able to run this code while in the background
        
        guard UserDefaults.standard.bool(forKey: notification_MedRemindersOn) else {
            return
        }
        
        let fetchRequest = NSFetchRequest<DrugEpisode>(entityName: "DrugEpisode")
        let predicate = NSPredicate(format: "drugID == %@", argumentArray: [drugID])
        fetchRequest.predicate = predicate
        
        let moc = (UIApplication.shared.delegate as! AppDelegate).stack.context
        
        do {
            let drugs = try moc.fetch(fetchRequest)
            if drugs.count > 0 {
                let drug = drugs[0]
                drug.scheduleReminderNotifications(cancelExisting: true)
            }
        } catch let error as NSError {
            ErrorManager.sharedInstance().errorMessage(message: "AppDelegate Error 2", systemError: error, errorInfo: "error fetching drug in rescheduleMedReminder function")
        }
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

