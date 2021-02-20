//
//  Utility.swift
//  BookWorm
//
//  Created by MetaV on 9/22/17.
//  Copyright © 2017 MV. All rights reserved.
//

import Foundation
import CoreData
import UserNotifications

//MARK: File Path
let fileManager = FileManager.default
let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
let documentPath = documentsURL.path

//MARK: Keychain
// Keychain Configuration
struct KeychainConfiguration {
    static let serviceName = "BookWorm"
    static let accessGroup: String? = nil
}

//MARK: URL
let searchURL = "https://www.googleapis.com/books/v1/volumes"
enum JSONParams: String{
    case items
    case volumeInfo
    case id
    case title
    case subtitle
    case publisher
    case publishedDate
    case description
    case industryIdentifiers
    case identifier
    case pageCount
    case imageLinks
    case smallThumbnail
    case authors
    case accessInfo
    case pdf
    case epub
    case isAvailable
}

enum URLParams: String{
    case filter
    case langRestrict
    case maxResults
    case orderBy
    case printType
    case q
    case startIndex
    case key
}

enum filterOptions: String{
    case partial
    case full
    case freeEbooks = "free-ebooks"
    case paidEbooks = "paid-ebooks"
    case ebooks
}

enum orderByOptions: String{
    case relevance
    case newest
}

enum printTypeOptions: String{
    case all
    case books
    case magazines
}

enum qOptions: String{
    case intitle
    case inauthor
    case inpublisher
    case subject
    case isbn
}

//MARK: Validation
func validateEmail(id: String?) -> Bool {
    guard let emailId = id else{
        return false
    }
    
    let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
    let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
    return emailTest.evaluate(with: emailId)
}

func validatePassword(text: String?) -> Bool {
    guard let password = text else{
        return false
    }
    
    let passwordRegEx = "^(?=.*[!@#$&*]).{8,}$"
    let passwordTest = NSPredicate(format: "SELF MATCHES %@", passwordRegEx)
    return passwordTest.evaluate(with: password)
}

func validateNameField(name: String?) -> Bool {
    guard let nameText = name else{
        return false
    }
    
    let nameRegEx = "[A-Za-z]+"
    let nameTest = NSPredicate(format: "SELF MATCHES %@", nameRegEx)
    return nameTest.evaluate(with: nameText)
}

func validateContactNumber(number: String?) -> Int64?{
    guard let numberText = number else{
        return nil
    }
    
    let numberRegEx = "^(?=.*[0-9]).{10}$"
    let numberTest = NSPredicate(format: "SELF MATCHES %@", numberRegEx)
    guard numberTest.evaluate(with: numberText) else{
        return nil
    }
    
    return Int64(numberText)
}

func validatePasswordMatch(of: String?, with: String?) ->Bool {
    guard of != nil else{
        return false
    }
    guard with != nil else{
        return false
    }
    
    if of == with {
        return true
    }else{
        return false
    }
}

func fetchCurrentUser() -> User?{
    //fetch current logged in user
    let defaults = UserDefaults.standard
    guard let email = defaults.string(forKey: "email") else {
        return nil
    }
    
    var userDetails: [User] = []
    let managedContext = CoreDataManager.shared.persistentContainer.viewContext
    let fetchRequest = NSFetchRequest<User>(entityName: "User")
    fetchRequest.predicate = NSPredicate(format: "email == %@", email)
    do {
        userDetails = try managedContext.fetch(fetchRequest)
    } catch let error as NSError {
        print("Could not fetch. \(error), \(error.userInfo)")
    }
    return userDetails[0]
}

func generateNotification(){
    let notification = UNMutableNotificationContent()
    let currentUser = fetchCurrentUser()
    if let cart = currentUser?.cart{
        if cart.count>0{
            //has books in cart
            notification.title = "BookWorm Cart"
            notification.subtitle = "Please checkout!"
            notification.body = "You have \(cart.count) books in your cart"
        } else{
            //empty cart
            notification.title = "BookWorm Cart"
            notification.subtitle = "Please add books!"
            notification.body = "You have not selected any books!"
        }
    }
    else{
        //empty cart
        notification.title = "BookWorm Cart"
        notification.subtitle = "Please add books!"
        notification.body = "You have not selected any books!"
    }
    let notifyTrigger = UNTimeIntervalNotificationTrigger(timeInterval: 60.0, repeats: true)
    
    let request = UNNotificationRequest(identifier: "CartNotification", content: notification, trigger: notifyTrigger)
    
    UNUserNotificationCenter.current().add(request, withCompletionHandler: { (error) in
        print("In the notification request's completion handler.")
    })
}
