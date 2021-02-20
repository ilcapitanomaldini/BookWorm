//
//  CartBookTableViewCell.swift
//  BookWorm
//
//  Created by MetaV on 9/28/17.
//  Copyright © 2017 MV. All rights reserved.
//

import UIKit

class CartBookTableViewCell: UITableViewCell {

    @IBOutlet weak var thumbnailImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var authorLabel: UILabel!
    
    weak var book: Book?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
}

extension CartBookTableViewCell{
    
    func setData() {
        titleLabel.text = book?.name
        guard let isbn = book?.isbn else {
            return
        }
        thumbnailImageView.image = UIImage(contentsOfFile: documentsURL.appendingPathComponent("\(String(describing: isbn)).png").path)
       
        var authorString: String = ""
        guard let authors = book?.author else{
            return
        }
        for case let author as Author in authors{
            authorString.append(author.name!)
            authorString.append(" ")
        }
        authorLabel.text = authorString
    
    }
}
