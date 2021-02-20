//
//  CustomTextField.swift
//  BookWorm
//
//  Created by MetaV on 9/29/17.
//  Copyright © 2017 MV. All rights reserved.
//

import UIKit

extension UITextField {

    func customConfigurations() {
        self.layer.borderWidth = 1
        self.layer.borderColor = UIColor.white.cgColor
        self.layer.cornerRadius = 15
    }
    
    func labelDisabled(){
        self.layer.borderWidth = 1
        self.layer.borderColor = UIColor.gray.cgColor
        self.textColor = UIColor.gray
        self.layer.cornerRadius = 15
        self.placeHolderColor = UIColor.gray
    }
    
    @IBInspectable var placeHolderColor: UIColor? {
        get {
            return self.placeHolderColor
        }
        set {
            self.attributedPlaceholder = NSAttributedString(string:self.placeholder != nil ? self.placeholder! : "", attributes:convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): newValue!]))
        }
    }


}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToOptionalNSAttributedStringKeyDictionary(_ input: [String: Any]?) -> [NSAttributedString.Key: Any]? {
	guard let input = input else { return nil }
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (NSAttributedString.Key(rawValue: key), value)})
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromNSAttributedStringKey(_ input: NSAttributedString.Key) -> String {
	return input.rawValue
}
