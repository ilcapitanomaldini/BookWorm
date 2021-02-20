//
//  FilterViewController.swift
//  BookWorm
//
//  Created by MetaV on 9/26/17.
//  Copyright © 2017 MV. All rights reserved.
//

import UIKit

class FilterViewController: UIViewController {

    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var maxResultsTextField: UITextField!
    @IBOutlet weak var filterTextField: UITextField!
    @IBOutlet weak var langRestrictTextField: UITextField!
    @IBOutlet weak var orderByTextField: UITextField!
    @IBOutlet weak var printTypeTextField: UITextField!
    @IBOutlet weak var inTitleTextField: UITextField!
    @IBOutlet weak var inAuthorTextField: UITextField!
    @IBOutlet weak var inPublisherTextField: UITextField!
    @IBOutlet weak var isbnTextField: UITextField!
    @IBOutlet weak var addFilterButton: UIButton!
    @IBOutlet weak var resetFilterButton: UIButton!
    
    weak var activeField: UITextField?
    
    var completionHandler: ((_ filterItems:(filter: String?, langRestrict: String?, orderBy: String?, printType: String?), _ queryString: String) -> Void)?
    var resetCompletionHandler: (() -> Void)?
    
    var pickerData: [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.hideKeyboard()
        
        //Delegates
        maxResultsTextField.delegate = self
        langRestrictTextField.delegate = self
        inTitleTextField.delegate = self
        inAuthorTextField.delegate = self
        inPublisherTextField.delegate = self
        isbnTextField.delegate = self
        
        filterTextField.delegate = self
        orderByTextField.delegate = self
        printTypeTextField.delegate = self
        
        //ui setup
        addFilterButton.customRadius()
        resetFilterButton.customRadius()
    }

    func appendQueryValueToString( string: inout String, key: String, value: String){
        string.append("+\(key):\(value)")
    }
    
    @IBAction func resetFilterTapped(_ sender: Any) {
        DispatchQueue.main.async {[weak self] in
            guard let end = self?.resetCompletionHandler else{
                return
            }
            end()
        }
        //Dismissal
        self.navigationController?.popViewController(animated: true)
    }
    @IBAction func addFilterTapped(_ sender: Any) {
        var filterItems:(filter: String?, langRestrict: String?, orderBy: String?, printType: String?)
        var queryParamsString = ""
        //Create Query
        guard let filter = filterTextField.text else{
            return
        }
        if filterTextField.text != "" {
            filterItems.filter = filter
        }
        
        guard let langRestrict = langRestrictTextField.text else{
            return
        }
        if langRestrictTextField.text != "" {
            filterItems.langRestrict = langRestrict
        }
        
        guard let orderBy = orderByTextField.text else{
            return
        }
        if orderByTextField.text != "" {
            filterItems.orderBy = orderBy
        }
        
        guard let printType = printTypeTextField.text else{
            return
        }
        if printTypeTextField.text != "" {
            filterItems.printType = printType
        }
        
        //In query items
        
        guard let inAuthor = inAuthorTextField.text else{
            return
        }
        if inAuthorTextField.text != "" {
            appendQueryValueToString(string: &queryParamsString, key: qOptions.inauthor.rawValue, value: inAuthor)
        }
        
        guard let inTitle = inTitleTextField.text else{
            return
        }
        if inTitleTextField.text != "" {
            appendQueryValueToString(string: &queryParamsString, key: qOptions.intitle.rawValue, value: inTitle)
        }
        
        guard let inPublisher = inPublisherTextField.text else{
            return
        }
        if inPublisherTextField.text != "" {
            appendQueryValueToString(string: &queryParamsString, key: qOptions.inpublisher.rawValue, value: inPublisher)
        }
        
        guard let inisbn = isbnTextField.text else{
            return
        }
        if isbnTextField.text != "" {
            appendQueryValueToString(string: &queryParamsString, key: qOptions.isbn.rawValue, value: inisbn)
        }
        
        DispatchQueue.main.async {[weak self] in
            guard let end = self?.completionHandler else{
                return
            }
            end(filterItems, queryParamsString)
        }
        
        //Dismissal
        self.navigationController?.popViewController(animated: true)
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
    
    @IBAction func filterTapped(_ sender: UITextView) {
        let pickerView = UIPickerView()
        pickerData = [filterOptions.ebooks.rawValue,filterOptions.full.rawValue,filterOptions.partial.rawValue,filterOptions.freeEbooks.rawValue,filterOptions.paidEbooks.rawValue]
        pickerView.delegate = self
        pickerView.dataSource = self
        sender.inputView = pickerView
    }
    @IBAction func orderByTapped(_ sender: UITextView) {
        let pickerView = UIPickerView()
        pickerData = [orderByOptions.newest.rawValue,orderByOptions.relevance.rawValue]
        pickerView.delegate = self
        pickerView.dataSource = self
        sender.inputView = pickerView
    }
    @IBAction func printTypeTapped(_ sender: UITextView) {
        let pickerView = UIPickerView()
        pickerData = [printTypeOptions.all.rawValue,printTypeOptions.books.rawValue,printTypeOptions.magazines.rawValue]
        pickerView.delegate = self
        pickerView.dataSource = self
        sender.inputView = pickerView
    }
}

extension FilterViewController: UIPickerViewDelegate, UIPickerViewDataSource{
    func numberOfComponents(in pickerView: UIPickerView) -> Int{
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int{
        return pickerData.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String?{
        return pickerData[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int){
        activeField?.text = pickerData[row]
        activeField?.resignFirstResponder()
    }
}

// MARK: - Keyboard
extension FilterViewController: UITextFieldDelegate{
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

// MARK: - Navigation
extension FilterViewController{
    /*
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
}

//MARK: String

//String extensions
extension String {
    func index(of string: String, options: CompareOptions = .literal) -> Index? {
        return range(of: string, options: options)?.lowerBound
    }
    func endIndex(of string: String, options: CompareOptions = .literal) -> Index? {
        return range(of: string, options: options)?.upperBound
    }
    func indexes(of string: String, options: CompareOptions = .literal) -> [Index] {
        var result: [Index] = []
        var start = startIndex
        while let range = range(of: string, options: options, range: start..<endIndex) {
            result.append(range.lowerBound)
            start = range.upperBound
        }
        return result
    }
    func ranges(of string: String, options: CompareOptions = .literal) -> [Range<Index>] {
        var result: [Range<Index>] = []
        var start = startIndex
        while let range = range(of: string, options: options, range: start..<endIndex) {
            result.append(range)
            start = range.upperBound
        }
        return result
    }
}
