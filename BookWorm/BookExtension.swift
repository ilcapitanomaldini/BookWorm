//
//  BookExtension.swift
//  BookWorm
//
//  Created by MetaV on 9/25/17.
//  Copyright © 2017 MV. All rights reserved.
//

import UIKit
import CoreData

extension Book{
    convenience init(data: (id: String, name: String, publisher: String, bookDescription: String, publishedDate: NSDate?, imageURL: String, isbn: String, authors: [Author], epubIsAvailable: Bool, pdfisAvailable: Bool)) {
        
        self.init(entity: NSEntityDescription.entity(forEntityName: "Book", in: CoreDataManager.shared.viewContext)!, insertInto: CoreDataManager.shared.viewContext)
        
        self.id = data.id
        
        self.name = data.name
        self.publisher = data.publisher
        self.bookDescription = data.bookDescription
        
        self.publishedDate = data.publishedDate as Date?
        
        self.imageURL = data.imageURL
        
        self.isbn = data.isbn
       
        for author in data.authors{
            //TO DO : Check for already existing
            author.addToWrote(self)
            self.addToAuthor(author)
        }
        
        self.epubIsAvailable = data.epubIsAvailable
        
        self.pdfIsAvailable = data.pdfisAvailable
    }
    
    func downloadImage(completedTask: @escaping (Book) -> Void) {
        //print(#function," : ID : ",id ?? -1)
        URLSession.shared.dataTask(with: URL(string:self.imageURL!)!) {
            (data, response, error) -> Void in
            guard error == nil else{
                print("Image could not be downloaded ",error.debugDescription)
                return
            }
            DispatchQueue.main.async { [weak self] in
                guard let isbn = self?.isbn else {
                    return
                }
                let filePath = documentsURL.appendingPathComponent("\(String(describing: isbn)).png")
                do{
                    if let pngImageData = UIImage(data: data! as Data)!.pngData() {
                        try pngImageData.write(to: filePath, options: .atomic)
                    }
                } catch{
                    print("Could Not Write Image")
                }
                completedTask(self!)
            }
            }.resume()
    }
    
    //MARK: - Class functions
    
    class func parseJSONForBook(json: [String: Any]) -> ((id: String, name: String, publisher: String, bookDescription: String, publishedDate: NSDate?, imageURL: String, isbn: String, authors: [Author], epubIsAvailable: Bool, pdfisAvailable: Bool)?) {
        //Null checks
        var resultDict : (id: String, name: String, publisher: String, bookDescription: String, publishedDate: NSDate?, imageURL: String, isbn: String, authors: [Author], epubIsAvailable: Bool, pdfisAvailable: Bool)
        guard let id = json[JSONParams.id.rawValue] as? String,
            let volumeInfo = json[JSONParams.volumeInfo.rawValue] as? [String: Any],
            let accessInfo = json[JSONParams.accessInfo.rawValue] as? [String:Any]
            else {
                return nil
        }
        
        resultDict.id = id
        
        //Null checks   volumeInfo
        guard let name = volumeInfo[JSONParams.title.rawValue] as? String else{
            print("Returned in name,publisher,bookdesc, or date")
            return nil
        }
        
        resultDict.name = name
        
        if let publisher = volumeInfo[JSONParams.publisher.rawValue] as? String {
            resultDict.publisher = publisher
        } else {
            resultDict.publisher = "Data not available."
        }
        
        if let bookDescription = volumeInfo[JSONParams.description.rawValue] as? String {
            resultDict.bookDescription = bookDescription
        } else {
            resultDict.bookDescription = "Data not available"
        }
        if let date = volumeInfo[JSONParams.publishedDate.rawValue] as? String{
        
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            if let dateObject = dateFormatter.date(from: date){
                resultDict.publishedDate = dateObject as NSDate
            } else {
                dateFormatter.dateFormat = "yyyy"
                if let dateObject = dateFormatter.date(from: date){
                    resultDict.publishedDate = dateObject as NSDate
                } else {
                    resultDict.publishedDate = nil
                }
            }
        } else {
            resultDict.publishedDate = nil
        }
        
        //Null checks   ImageLinks
        guard let imageDict = volumeInfo[JSONParams.imageLinks.rawValue] as? [String: String] else {
            print("Returned in upper image")
            return nil
        }
        guard let imageURL = imageDict[JSONParams.smallThumbnail.rawValue] else {
            print("Returned in image")
            return nil
        }
        
        resultDict.imageURL = imageURL
        
        //Null checks   ISBN
        guard let isbnID = volumeInfo[JSONParams.industryIdentifiers.rawValue] as? [[String: String]] else {
            print("Returned in upper isbn")
            return nil
        }
        guard let isbn = isbnID[0][JSONParams.identifier.rawValue] else {
            print("Returned in isbn")
            return nil
        }
        resultDict.isbn = isbn
        
        //Null checks   Authors
        if let authors = volumeInfo[JSONParams.authors.rawValue] as? [String] {
            resultDict.authors = []
            for author in authors{
            //TO DO : Check for already existing
                let authorObject = Author(entity: NSEntityDescription.entity(forEntityName: "Author", in: CoreDataManager.shared.viewContext)!, insertInto: CoreDataManager.shared.viewContext)
                authorObject.name = author
                resultDict.authors.append(authorObject)
            }
        } else {
            let authorObject = Author(entity: NSEntityDescription.entity(forEntityName: "Author", in: CoreDataManager.shared.viewContext)!, insertInto: CoreDataManager.shared.viewContext)
            authorObject.name = "Data not Found"
            resultDict.authors = [authorObject]
        }
        //Null checks   epub and pdf
        guard let epub = accessInfo[JSONParams.epub.rawValue] as? [String:Any] else {
            return nil
        }
        guard let epubisAvailable = epub[JSONParams.isAvailable.rawValue] as? Bool else {
            return nil
        }
        resultDict.epubIsAvailable = epubisAvailable
        guard let pdf = accessInfo[JSONParams.pdf.rawValue] as? [String:Any] else {
            return nil
        }
        guard let pdfisAvailable = pdf[JSONParams.isAvailable.rawValue] as? Bool else {
            return nil
        }
        resultDict.pdfisAvailable = pdfisAvailable
        
        return resultDict
    }
    
    class func fetchBooksFromCoreData() -> [Book]{
        var fetchedBooks: [Book] = []
        let managedContext = CoreDataManager.shared.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<Book>(entityName: "Book")
        
        do {
            fetchedBooks = try managedContext.fetch(fetchRequest)
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        return fetchedBooks
    }
    
    class func deleteBooksFromCoreData(){
        let managedContext = CoreDataManager.shared.viewContext
        let fetchRequest = NSFetchRequest<Book>(entityName: "Book")
        if let result = try? managedContext.fetch(fetchRequest) {
            for book in result {
                //check if the book is in the cart of someone or is owned by someone.
                //if yes, keep it in the database, else delete it.
                if (book.inCartOf == nil || book.inCartOf == []) && (book.ownedBy == nil || book.ownedBy == []) {
                    //delete book image
                    do {
                        guard let isbn = book.isbn else {
                            return
                        }
                        let filePath = documentsURL.appendingPathComponent("\(String(describing: isbn)).png")
                        try FileManager.default.removeItem(atPath: filePath.path)
                    } catch {
                        print("Could not delete book image.")
                    }
                    //delete book object
                    managedContext.delete(book)
                }
            }
        }
    }
    
    
}
