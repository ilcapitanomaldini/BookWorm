//
//  LoginViewController.swift
//  BookWorm
//
//  Created by MetaV on 9/22/17.
//  Copyright © 2017 MV. All rights reserved.
//

import UIKit
import CoreData

class LoginViewController: UIViewController {

    @IBOutlet weak var emailIdTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var keepLoggedInSwitch: UISwitch!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var forgetPasswordButton: UIButton!
    @IBOutlet weak var newUserButton: UIButton!
    @IBOutlet weak var loginAsGuestButton: UIButton!
    
   
    weak var activeField: UITextField?
    
    var seePassword = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        passwordTextField.isSecureTextEntry = true
        keepLoggedInSwitch.isOn = false
        emailIdTextField.delegate = self
        passwordTextField.delegate = self
        loginButton.customRadius()
        forgetPasswordButton.customRadius()
        newUserButton.customRadius()
        //emailIdTextField.becomeFirstResponder()
        
        
        //Ui Edits
        emailIdTextField.customConfigurations()
        passwordTextField.customConfigurations()
        emailIdTextField.placeHolderColor = UIColor.white
        passwordTextField.placeHolderColor = UIColor.white
        emailIdTextField.becomeFirstResponder()
        loginAsGuestButton.customRadius()
        
        self.hideKeyboard()
        
        if UserDefaults.standard.string(forKey: "email") == "guest@bookworm.com"{
            loginAsGuestButton.isHidden = true
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidShow), name: UIResponder.keyboardDidShowNotification, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillBeHidden), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardDidShowNotification, object: nil)
        
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

//MARK: User Interaction Code
extension LoginViewController{
    
    @IBAction func guestLoginTapped(_ sender: Any) {
        //defaults init
        let defaults = UserDefaults.standard
        defaults.set("guest@bookworm.com", forKey: "email")
        defaults.set(true, forKey: "keepLoggedIn")
        
        let managedContext = CoreDataManager.shared.viewContext
        let user = User(entity: NSEntityDescription.entity(forEntityName: "User", in: managedContext)!, insertInto: managedContext)
        user.email = "guest@bookworm.com"
        do{
            try managedContext.save()
        }catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
        
        if let main = self.storyboard?.instantiateViewController(withIdentifier: "main") as? UITabBarController {
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            appDelegate.window?.rootViewController!.present(main, animated: true, completion: nil)
        }
    }
    
    @IBAction func loginTapped(_ sender: Any) {
        //Validation
        guard let email = emailIdTextField.text, validateEmail(id: emailIdTextField.text) else{
            let alert = UIAlertController(title: "Alert" , message: "Invalid Email", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "Okay!", style: UIAlertAction.Style.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            return
        }
        guard let passwordEntered = passwordTextField.text else {
            return
        }
        
        let managedContext = CoreDataManager.shared.persistentContainer.viewContext
        var selfDetails: [User] = []
        let fetchRequest = NSFetchRequest<User>(entityName: "User")
        fetchRequest.predicate = NSPredicate(format: "email == %@", email)
        do {
            selfDetails = try managedContext.fetch(fetchRequest)
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        
        guard selfDetails.count>0 else{
            let alert = UIAlertController(title: "Alert" , message: "Unregistered Email", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "Okay!", style: UIAlertAction.Style.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            return
        }
        //Check password
        do {
            let passwordItem = KeychainPasswordItem(service: KeychainConfiguration.serviceName,
                                                    account: email,
                                                    accessGroup: KeychainConfiguration.accessGroup)
            let keychainPassword = try passwordItem.readPassword()
            guard keychainPassword == passwordEntered else {
                let alert = UIAlertController(title: "Alert" , message: "Incorrect Email/Password", preferredStyle: UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(title: "Okay!", style: UIAlertAction.Style.default, handler: nil))
                self.present(alert, animated: true, completion: nil)
                return
            }
        }
        catch {
            let alert = UIAlertController(title: "Alert" , message: "Error fetching password.", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "Okay!", style: UIAlertAction.Style.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            return
        }
        
        //Can login now, everything is in order
        let defaults = UserDefaults.standard
        if defaults.string(forKey: "email") == "guest@bookworm.com"{
            //Logged in as guest
            if keepLoggedInSwitch.isOn{
                defaults.set(true, forKey: "keepLoggedIn")
            }else{
                defaults.set(false, forKey: "keepLoggedIn")
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
            //add to actual user's cart
            userDetails[0].addToCart((fetchCurrentUser()?.cart)!)
            //delete from guest's cart
            fetchCurrentUser()?.cart = nil
            do {
                try managedContext.save()
            } catch let error as NSError {
                print("Could not save. \(error), \(error.userInfo)")
            }
            defaults.set(email, forKey: "email")
            let userProfileVC = self.storyboard?.instantiateViewController(withIdentifier: "UserProfileViewControllerID")
            self.navigationController?.viewControllers = [userProfileVC!]
        }
        else{
            //Not yet logged in
            defaults.set(email, forKey: "email")
            if keepLoggedInSwitch.isOn{
                defaults.set(true, forKey: "keepLoggedIn")
            }else{
                defaults.set(false, forKey: "keepLoggedIn")
            }
            if let main = self.storyboard?.instantiateViewController(withIdentifier: "main") as? UITabBarController {
                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                appDelegate.window?.rootViewController!.present(main, animated: true, completion: nil)
            }
        }
    }
    
    @IBAction func seePasswordTapped(_ sender: Any) {
        if(seePassword == true){
            passwordTextField.isSecureTextEntry = false
            seePassword = false
        }else{
            passwordTextField.isSecureTextEntry = true
            seePassword = true
        }
    }
    
    @IBAction func rememberSwitchToggled(_ sender: Any) {
        if keepLoggedInSwitch.isOn{
            keepLoggedInSwitch.setOn(false, animated: true)
        }else{
            keepLoggedInSwitch.setOn(true, animated: true)
        }
    }
}

// MARK: - Navigation
//extension LoginViewController{
//    
//    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
//        
//        if identifier == "forgotPasswordSegue"{
//            return true
//        }
//        if identifier == "registerSegue"{
//            return true
//        }
//        //segue to homeUI logic
//        guard validateEmail(id: emailIdTextField.text) else{
//            return false
//        }
//        
//        guard validatePassword(text: passwordTextField.text) else{
//            return false
//        }
//        
//        return true
//    }
//}

//MARK: - Keyboard
extension LoginViewController: UITextFieldDelegate{
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case emailIdTextField:
            passwordTextField.becomeFirstResponder()
        default:
            passwordTextField.resignFirstResponder()
        }
        return true
    }
    
    @objc func keyboardDidShow(notification: NSNotification) {
        if let activeField = self.activeField, let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            let contentInsets = UIEdgeInsets(top: 0.0, left: 0.0, bottom: keyboardSize.height, right: 0.0)
            self.scrollView.contentInset = contentInsets
            self.scrollView.scrollIndicatorInsets = contentInsets
            var aRect = self.view.frame
            aRect.size.height = aRect.size.height - keyboardSize.size.height
            if (!aRect.contains(activeField.frame.origin)) {
                self.scrollView.scrollRectToVisible(activeField.frame, animated: true)
            }
        }
    }
    
    @objc func keyboardWillBeHidden(notification: NSNotification) {
        let contentInsets = UIEdgeInsets.zero
        self.scrollView.contentInset = contentInsets
        self.scrollView.scrollIndicatorInsets = contentInsets
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        self.activeField = nil
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        self.activeField = textField
    }
}

//MARK: - UIViewControllerExtension
//Keyboard Dismissal
extension UIViewController{
    func hideKeyboard()
    {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(
            target: self,
            action: #selector(dismissKeyboard))
        
        self.view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard()
    {
        self.view.endEditing(true)
    }
}
