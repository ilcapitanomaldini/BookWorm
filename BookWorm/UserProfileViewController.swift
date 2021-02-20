//
//  UserProfileViewController.swift
//  BookWorm
//
//  Created by MetaV on 9/25/17.
//  Copyright © 2017 MV. All rights reserved.
//

import UIKit
import CoreData
import UserNotifications

class UserProfileViewController: UIViewController {

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var contactNumberLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        //check for guest user.
        if(fetchCurrentUser()?.email == "guest@bookworm.com"){
            let loginViewController = self.storyboard?.instantiateViewController(withIdentifier: "loginView") as? LoginViewController
            self.navigationController?.viewControllers = [loginViewController!]
            self.title = "Login"
        }
        else{
            setUsersData(fetchCurrentUser()!)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func setUsersData(_ userData: User){
        
        let fullName = userData.firstName! + " " + userData.lastName!
        nameLabel.text = fullName
        emailLabel.text = userData.email
        contactNumberLabel.text = String(userData.contactNumber)
        addressLabel.text = userData.address
        
    }
    
    @IBAction func LogoutButton(_ sender: Any) {
        let alert = UIAlertController(title: "Logout", message: "Are you sure you want to logout?", preferredStyle: UIAlertController.Style.actionSheet)
        alert.addAction(UIAlertAction(title: "Yes", style: UIAlertAction.Style.default, handler: {action in
            //Log out
            let defaults = UserDefaults.standard
            defaults.set(nil, forKey: "email")
            defaults.set(false, forKey: "keepLoggedIn")
            //delete previously searched query
            UserDefaults.standard.set(nil, forKey: "currentSearchQuery")
            //disable active notifications
            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
            
            //Navigate to login page
            let viewController = self.storyboard?.instantiateViewController(withIdentifier: "login")
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            guard let login = viewController else {return}
            appDelegate.window?.rootViewController = login
            
        }))
        alert.addAction(UIAlertAction(title: "No", style: UIAlertAction.Style.destructive, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    
    @IBAction func editProfile(_ sender: Any) {
        
        let editProfileController = storyboard?.instantiateViewController(withIdentifier: "RegisterViewControllerID") as! RegisterViewController
        editProfileController.identifier = "editProfile"
        self.navigationController?.pushViewController(editProfileController, animated: true)
        
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
