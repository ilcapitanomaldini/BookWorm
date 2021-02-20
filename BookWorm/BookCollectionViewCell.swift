//
//  BookCollectionViewCell.swift
//  BookWorm
//
//  Created by MetaV on 10/3/17.
//  Copyright © 2017 MV. All rights reserved.
//

import UIKit

class BookCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var bookNameLabel: UILabel!
    @IBOutlet weak var authorNameLabel: UILabel!
    @IBOutlet weak var imageActivityIndicator: UIActivityIndicatorView!

    @IBOutlet weak var thumbnailImageView: UIImageView!
    
    weak var book: Book?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
}

extension BookCollectionViewCell{
    func setData() {
        thumbnailImageView.layer.cornerRadius = thumbnailImageView.frame.size.height/2
        bookNameLabel.text = book?.name
        var authorString: String = ""
        guard let authors = book?.author else{
            return
        }
        for case let author as Author in authors{
            authorString.append(author.name!)
            authorString.append(" ")
        }
        authorNameLabel.text = authorString
        //ISBNLabel.text = book?.isbn
        thumbnailImageView.image = nil
        thumbnailImageView.isHidden = true
        imageActivityIndicator.startAnimating()
        
        guard let isbn = book?.isbn else {
            return
        }
        let filePath = documentsURL.appendingPathComponent("\(String(describing: isbn)).png")
        if FileManager.default.fileExists(atPath: filePath.path) {
            if let imageContents = UIImage(contentsOfFile: filePath.path){
                imageActivityIndicator.stopAnimating()
                thumbnailImageView.isHidden = false
                thumbnailImageView.image = imageContents
            }
        }
    }
    
    func downloadAndUpdateImage() {
        guard let isbn = book?.isbn else {
            return
        }
        let filePath = documentsURL.appendingPathComponent("\(String(describing: isbn)).png")
        if let imageContents = UIImage(contentsOfFile: filePath.path){
            imageActivityIndicator.stopAnimating()
            thumbnailImageView.isHidden = false
            thumbnailImageView.image = imageContents
        } else {
            book?.downloadImage(){ [weak self] book in
                if(self?.book?.id == book.id){
                    guard let imageContents = UIImage(contentsOfFile: filePath.path) else{
                        print("Image Unavailable")
                        return
                    }
                    self?.imageActivityIndicator.stopAnimating()
                    self?.thumbnailImageView.image = imageContents
                    self?.thumbnailImageView.isHidden = false
                } else {
                    print("Book ID mismatch. Too late!")
                }
            }
        }
    }
}
