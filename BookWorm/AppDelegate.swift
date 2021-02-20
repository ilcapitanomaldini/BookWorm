//
//  AppDelegate.swift
//  BookWorm
//
//  Created by MetaV on 9/22/17.
//  Copyright © 2017 MV. All rights reserved.
//

import UIKit
import CoreData
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var storyboard:UIStoryboard?

    func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
//        //DELETE: 
//        
//        do {
//            let files = try FileManager.default.contentsOfDirectory(atPath: documentPath)
//            for file in files {
//                try FileManager.default.removeItem(atPath: "\(documentPath)/\(file)")
//                print("Image Data Deleted at init!")
//            }
//        } catch {
//            print("Could not clear cache.")
//        }
//        
//        //Till here
        
        window =  UIWindow(frame: UIScreen.main.bounds)
        window?.makeKeyAndVisible()
        
        let keepLoggedIn = UserDefaults.standard.bool(forKey: "keepLoggedIn")
        
        if keepLoggedIn  {
            //Show main screen
            storyboard = UIStoryboard(name: "Main", bundle: nil)
            let rootController = storyboard!.instantiateViewController(withIdentifier: "main")
            if let window = self.window {
                window.rootViewController = rootController
            }
            
        }
        else {
            //Open login.
            storyboard = UIStoryboard(name: "Main", bundle: nil)
            let rootController = storyboard!.instantiateViewController(withIdentifier: "login")
            if let window = self.window {
                window.rootViewController = rootController
            }
        }
        requestNotificationPermission()
        return true
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        //Network connectivity.
        do {
            Network.reachability = try Reachability(hostname: "www.google.com")
            do {
                try Network.reachability?.start()
            } catch let error as Network.Error {
                print(error)
            } catch {
                print(error)
            }
        } catch {
            print(error)
        }
        
        UNUserNotificationCenter.current().delegate = self
        //Notificaiton code.
        
        guard fetchCurrentUser() != nil else{
            //User isn't logged in
            return true
        }
        
        generateNotification()
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        
        //Remove the emailId set if user hasn't opted to remian logged in.
        let keepLoggedIn = UserDefaults.standard.bool(forKey: "keepLoggedIn")
        if !keepLoggedIn {
            UserDefaults.standard.set(nil, forKey: "email")
        }
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        self.saveContext()
        let managedContext = CoreDataManager.shared.viewContext
        do{
            try managedContext.save()
        }catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
        
        //Remove the emailId set if user hasn't opted to remian logged in.
        let keepLoggedIn = UserDefaults.standard.bool(forKey: "keepLoggedIn")
        if !keepLoggedIn {
            UserDefaults.standard.set(nil, forKey: "email")
        }
    }

    // MARK: - Core Data stack

    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
        */
        let container = NSPersistentContainer(name: "BookWorm")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                 
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()

    // MARK: - Core Data Saving support

    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }

}

//MARK: - Notifications
extension AppDelegate: UNUserNotificationCenterDelegate{
    func requestNotificationPermission(){
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { (granted, error) in
            print("In the request's handler.")
        }
    }
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
            completionHandler([.alert,.sound])
        }
}
