//
//  RegisterViewController.swift
//  BookWorm
//
//  Created by MetaV on 9/22/17.
//  Copyright © 2017 MV. All rights reserved.
//

import UIKit
import CoreData

class RegisterViewController: UIViewController {

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var firstNameTextField: UITextField!
    @IBOutlet weak var lastNameTextField: UITextField!
    @IBOutlet weak var contactNumberTextField: UITextField!
    @IBOutlet weak var emailIdTextField: UITextField!
    @IBOutlet weak var addressTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var retypedPasswordTextField: UITextField!
    @IBOutlet weak var RegisterButton: UIButton!
    @IBOutlet weak var passwordImageView: UIImageView!
    @IBOutlet weak var retypePasswordImageView: UIImageView!
    @IBOutlet weak var showPasswordImageView: UIButton!
    
    var seePassword = true
    weak var activeField: UITextField?
    var identifier:String?
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.hideKeyboard()
        //UI EDIT
        UiSetUp()
        
        
        //Delegates
        firstNameTextField.delegate = self
        lastNameTextField.delegate = self
        contactNumberTextField.delegate = self
        emailIdTextField.delegate = self
    
        addressTextField.delegate = self
        passwordTextField.delegate = self
        retypedPasswordTextField.delegate = self
        
        if identifier == "editProfile" {
            emailIdTextField.labelDisabled()
            let user = fetchCurrentUser()
            RegisterButton.setTitle("Update",for: .normal)
            firstNameTextField.text = user?.firstName
            lastNameTextField.text = user?.lastName
            addressTextField.text = user?.address
            guard let contactNumber = user?.contactNumber else {return}
            contactNumberTextField.text = String(describing: contactNumber)
            emailIdTextField.text = user?.email
            emailIdTextField.isUserInteractionEnabled = false
            passwordTextField.isHidden = true
            retypedPasswordTextField.isHidden = true
            passwordImageView.isHidden = true
            retypePasswordImageView.isHidden = true
            showPasswordImageView.isHidden = true
            passwordTextField.text = "**"
            retypedPasswordTextField.text = "**"
        }
        
        //Make the password fields secure.
        passwordTextField.isSecureTextEntry = true
        retypedPasswordTextField.isSecureTextEntry = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidShow), name: UIResponder.keyboardDidShowNotification, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillBeHidden), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardDidShowNotification, object: nil)
        
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
}

// MARK: - User Interaction
extension RegisterViewController{
    @IBAction func registerUserTapped(_ sender: Any) {
        
        //Validate all the fields first.
        guard validateNameField(name: firstNameTextField.text) else{
            let alert = UIAlertController(title: "Alert" , message: "Invalid First Name", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "Okay!", style: UIAlertAction.Style.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            return
        }
        guard validateNameField(name: lastNameTextField.text) else{
            let alert = UIAlertController(title: "Alert" , message: "Invalid Last Name", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "Okay!", style: UIAlertAction.Style.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            return
        }
        guard let contactNumber = validateContactNumber(number: contactNumberTextField.text) else{
            let alert = UIAlertController(title: "Alert" , message: "Invalid Contact Number. Should be equal to 10 digits.", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "Okay!", style: UIAlertAction.Style.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            return
        }
        guard validateEmail(id: emailIdTextField.text) else {
            let alert = UIAlertController(title: "Alert" , message: "Invalid Email.", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "Okay!", style: UIAlertAction.Style.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            return
        }
        guard addressTextField.text != nil else{        //NOTE: Address only checked for nil.
            return
        }
        
        if identifier != "editProfile"{
            //Validate Password
            guard validatePassword(text: passwordTextField.text) else {
                let alert = UIAlertController(title: "Alert" , message: "Invalid Password. Should have atleast one special character.", preferredStyle: UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(title: "Okay!", style: UIAlertAction.Style.default, handler: nil))
                self.present(alert, animated: true, completion: nil)
                return
            }
            guard validatePasswordMatch(of:passwordTextField.text, with: retypedPasswordTextField.text) else {
                let alert = UIAlertController(title: "Alert" , message: "Password does not match.", preferredStyle: UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(title: "Okay!", style: UIAlertAction.Style.default, handler: nil))
                self.present(alert, animated: true, completion: nil)
                return
            }
        //Check if the user has already registered
    
            var userDetails: [User] = []
            let managedContext = CoreDataManager.shared.persistentContainer.viewContext
            let fetchRequest = NSFetchRequest<User>(entityName: "User")
            fetchRequest.predicate = NSPredicate(format: "email == %@", emailIdTextField.text!)
            do {
                userDetails = try managedContext.fetch(fetchRequest)
            } catch let error as NSError {
                print("Could not fetch. \(error), \(error.userInfo)")
            }
            guard userDetails.count == 0 else{
                let alert = UIAlertController(title: "Alert" , message: "Email already registered.", preferredStyle: UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(title: "Okay!", style: UIAlertAction.Style.default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            return
            }
            
            //Insert into database.
            let user = User(entity: NSEntityDescription.entity(forEntityName: "User", in: managedContext)!, insertInto: managedContext)
            user.firstName = firstNameTextField.text
            user.lastName = lastNameTextField.text
            user.contactNumber = contactNumber
            user.email = emailIdTextField.text
            user.address = addressTextField.text
            
            //Insert password into keychain
            do {
                
                // This is a new account, create a new keychain item with the account name.
                let passwordItem = KeychainPasswordItem(service: KeychainConfiguration.serviceName,
                                                        account: emailIdTextField.text!,
                                                        accessGroup: KeychainConfiguration.accessGroup)
                
                // Save the password for the new item.
                try passwordItem.savePassword(passwordTextField.text!)
            } catch {
                let alert = UIAlertController(title: "Alert" , message: "Password could not be saved.", preferredStyle: UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(title: "Retry", style: UIAlertAction.Style.default, handler: nil))
                self.present(alert, animated: true, completion: nil)
                return
            }
            
            do{
                try managedContext.save()
            }catch let error as NSError {
                print("Could not save. \(error), \(error.userInfo)")
            }
        
            //Now, return to login screen
            self.navigationController?.popViewController(animated: true)
        } else {
            let user =  fetchCurrentUser()
            user?.firstName = firstNameTextField.text
            user?.lastName = lastNameTextField.text
            user?.address = addressTextField.text
            user?.contactNumber = contactNumber
            
            let managedContext = CoreDataManager.shared.persistentContainer.viewContext
            do{
                try managedContext.save()
            }catch let error as NSError {
                print("Could not save. \(error), \(error.userInfo)")
            }
            
            //Now, return to user profile
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    @IBAction func seePasswordTapped(_ sender: Any) {
        if(seePassword == true){
            passwordTextField.isSecureTextEntry = false
            retypedPasswordTextField.isSecureTextEntry = false
            seePassword = false
        }else{
            passwordTextField.isSecureTextEntry = true
            retypedPasswordTextField.isSecureTextEntry = true
            seePassword = true
        }
    }
}

//MARK: - Keyboard
extension RegisterViewController: UITextFieldDelegate{
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case firstNameTextField:
            lastNameTextField.becomeFirstResponder()
        case lastNameTextField:
            contactNumberTextField.becomeFirstResponder()
        case contactNumberTextField:
            emailIdTextField.becomeFirstResponder()
        case emailIdTextField:
            addressTextField.becomeFirstResponder()
        case addressTextField:
            passwordTextField.becomeFirstResponder()
        case passwordTextField:
            retypedPasswordTextField.becomeFirstResponder()
        default:
            retypedPasswordTextField.resignFirstResponder()
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

 // MARK: - UI

extension RegisterViewController{
    
    func UiSetUp() {
        firstNameTextField.becomeFirstResponder()
        firstNameTextField.customConfigurations()
        lastNameTextField.customConfigurations()
        contactNumberTextField.customConfigurations()
        emailIdTextField.customConfigurations()
        addressTextField.customConfigurations()
        passwordTextField.customConfigurations()
        retypedPasswordTextField.customConfigurations()
        RegisterButton.layer.cornerRadius = 10
        firstNameTextField.placeHolderColor = UIColor.white
        lastNameTextField.placeHolderColor = UIColor.white
        contactNumberTextField.placeHolderColor = UIColor.white
        addressTextField.placeHolderColor = UIColor.white
        emailIdTextField.placeHolderColor = UIColor.white
        passwordTextField.placeHolderColor = UIColor.white
        retypedPasswordTextField.placeHolderColor = UIColor.white
        firstNameTextField.becomeFirstResponder()
    }
}
