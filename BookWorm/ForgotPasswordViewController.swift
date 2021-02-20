//
//  ForgotPasswordViewController.swift
//  BookWorm
//
//  Created by MetaV on 9/22/17.
//  Copyright © 2017 MV. All rights reserved.
//

import UIKit
import CoreData
class ForgotPasswordViewController: UIViewController {

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var interactionButton: UIButton!
    
    weak var activeField: UITextField?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.hideKeyboard()
        
        //UIsetup
        emailTextField.customConfigurations()
        passwordTextField.labelDisabled()
        interactionButton.customRadius()
        emailTextField.becomeFirstResponder()
        
        //Delegates
        emailTextField.delegate = self
        passwordTextField.delegate = self
        
        //Changes to accomodate recovering password
        passwordTextField.isUserInteractionEnabled = false
        interactionButton.setTitle("Recover Password",for: .normal)
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
    
    @IBAction func buttonAction(_ sender: Any) {
       let email = emailTextField.text
        if validateEmail(id: email) {
            let managedContext = CoreDataManager.shared.persistentContainer.viewContext
            var selfDetails: [User] = []
            let fetchRequest = NSFetchRequest<User>(entityName: "User")
            fetchRequest.predicate = NSPredicate(format: "email == %@", email!)
            do {
                selfDetails = try managedContext.fetch(fetchRequest)
            } catch let error as NSError {
                print("Could not fetch. \(error), \(error.userInfo)")
                
            }
            guard selfDetails.count > 0 else {
                let alert = UIAlertController(title: "Alert" , message: "Incorrect/Unregistered Email", preferredStyle: UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(title: "Okay!", style: UIAlertAction.Style.default, handler: nil))
                self.present(alert, animated: true, completion: nil)
                return
            }
            
            //Changes for recovering
            do {
                let passwordItem = KeychainPasswordItem(service: KeychainConfiguration.serviceName,
                                                        account: email!,
                                                        accessGroup: KeychainConfiguration.accessGroup)
                let keychainPassword = try passwordItem.readPassword()
                passwordTextField.text = keychainPassword
            }
            catch {
                let alert = UIAlertController(title: "Alert" , message: "Error fetching password.", preferredStyle: UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(title: "Okay!", style: UIAlertAction.Style.default, handler: nil))
                self.present(alert, animated: true, completion: nil)
                return
            }
            
//            guard let password = passwordTextField.text,validatePassword(text: passwordTextField.text) else {
//                let alert = UIAlertController(title: "Alert" , message: "Invalid Password", preferredStyle: UIAlertControllerStyle.alert)
//                alert.addAction(UIAlertAction(title: "Okay!", style: UIAlertActionStyle.default, handler: nil))
//                self.present(alert, animated: true, completion: nil)
//                return
//            }
//            selfDetails[0].password = password
//            do {
//                try managedContext.save()
//                
//            } catch let error as NSError {
//                print("Could not save. \(error), \(error.userInfo)")
//                }
            
            //self.navigationController?.popViewController(animated: true)

        } else{
            let alert = UIAlertController(title: "Alert" , message: "Incorrect Email", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "Okay!", style: UIAlertAction.Style.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            return
        }
        
    }
}



// MARK: - Navigation
extension ForgotPasswordViewController{
    /*
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */

}

//MARK: - Keyboard
extension ForgotPasswordViewController: UITextFieldDelegate{
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case emailTextField:
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
