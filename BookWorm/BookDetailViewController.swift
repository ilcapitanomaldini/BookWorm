//
//  BookDetailViewController.swift
//  BookWorm
//
//  Created by MetaV on 9/26/17.
//  Copyright © 2017 MV. All rights reserved.
//

import UIKit
import CoreData

class BookDetailViewController: UIViewController {

    var bookInfo:Book?
    
    @IBOutlet weak var addToCartButton: UIButton!
    @IBOutlet weak var availabilityLabel: UILabel!
    @IBOutlet weak var bookThumbnailImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var authorNameLabel: UILabel!
    @IBOutlet weak var IsbnLabel: UILabel!
    @IBOutlet weak var publisherLabel: UILabel!
    @IBOutlet weak var pulishedDateLabel: UILabel!
    @IBOutlet weak var coverTextLabel: UILabel!
    
    //var localCart:[Book] = []
    
     override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Details"
        
        addToCartButton.customRadius()
        
        setBookDescriptionView()
        
        //Availability Logic
        var availabilityString = "Available Formats: "
        if(!(bookInfo?.epubIsAvailable)! || !(bookInfo?.pdfIsAvailable)!){      //if both not available
            addToCartButton.setTitle("Out Of Stock!",for: .normal)
            addToCartButton.isUserInteractionEnabled = false
            availabilityString.append("none")
        } else{
            if((bookInfo?.epubIsAvailable)!){       //epub available
                availabilityString.append("epub ")
            }
            if((bookInfo?.epubIsAvailable)!){       //pdf available
                availabilityString.append("pdf ")
            }
        }
        
        availabilityLabel.text = availabilityString
        
        //check if cart already contains particular book
        guard let user = fetchCurrentUser() else{
            return
        }
        guard let info = bookInfo else{
            return
        }
        if (user.cart?.contains(info))! {
            addToCartButton.setTitle("Already added to cart!",for: .normal)
            addToCartButton.isUserInteractionEnabled = false
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func addToCart(_ sender: Any) {
        let user = fetchCurrentUser()
        user?.addToCart(bookInfo!)
        bookInfo?.addToInCartOf(user!)
        let managedContext = CoreDataManager.shared.viewContext
        do{
            try managedContext.save()
        }catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
        let alert = UIAlertController(title: "Good Choice!" , message: "Added to cart successfully!", preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "Okay!", style: UIAlertAction.Style.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
        addToCartButton.setTitle("Already added to cart!",for: .normal)
        addToCartButton.isUserInteractionEnabled = false
    }
}

extension BookDetailViewController{
    
    func setBookDescriptionView(){
        guard let bookInfoObject = bookInfo else{
            return
        }
        
        //TO DO : - Give default image when downloading
        guard let isbn = bookInfoObject.isbn else {
            return
        }
        let filePath = documentsURL.appendingPathComponent("\(String(describing: isbn)).png")
        if let imageContents = UIImage(contentsOfFile: filePath.path){
            self.bookThumbnailImageView.image = imageContents
        }
        else{
            self.bookThumbnailImageView.image = nil
        }
        
        self.titleLabel.text = bookInfoObject.name!
        var authorString:String = ""
        for case let author as Author in bookInfoObject.author!{
            authorString.append(author.name!)
            authorString.append(" ")
        }
        self.authorNameLabel.text = authorString
        self.IsbnLabel.text = bookInfoObject.isbn
        self.publisherLabel.text = bookInfoObject.publisher
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        if let publishedDate = bookInfoObject.publishedDate {
            var dateString = dateFormatter.string(from: publishedDate as Date)
            if  dateString != ""{
                self.pulishedDateLabel.text = dateString
            } else {
                dateFormatter.dateFormat = "yyyy"
                dateString = dateFormatter.string(from: publishedDate as Date)
                if  dateString != "" {
                    self.pulishedDateLabel.text = dateString
                } else {
                    self.pulishedDateLabel.text = "Data Unavailable"
                }
            }
        } else {
            self.pulishedDateLabel.text = "Data not Available"
        }
        self.coverTextLabel.text = bookInfoObject.bookDescription
    }
}
