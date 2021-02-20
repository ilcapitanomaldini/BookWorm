//
//  BookListViewController.swift
//  BookWorm
//
//  Created by MetaV on 9/25/17.
//  Copyright © 2017 MV. All rights reserved.
//

import UIKit
import CoreData

class BookGridViewController: UIViewController {
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var collectionView: UICollectionView!
    
    var bookData: [Book] = []
    var cartBooks: [Book] = []
    var urlComponents = URLComponents(string: searchURL)
    let defaultSession = URLSession(configuration: .default)
    var dataTask: URLSessionDataTask?
    var currentSearchQuery = "lordoftherings"
    var callCount = 0
    var furtherDataCalled = false
    
    fileprivate let itemsPerRow: CGFloat = 3
    fileprivate let sectionInsets = UIEdgeInsets(top: 20.0, left: 10.0, bottom: 20.0, right: 10.0)
    
    override func viewWillAppear(_ animated: Bool) {
        guard UserDefaults.standard.string(forKey: "currentSearchQuery") != nil else {
            return
        }
        
        callCount = UserDefaults.standard.integer(forKey: "callCount")
        currentSearchQuery = UserDefaults.standard.string(forKey: "currentSearchQuery")!
        generateNotification()
        
        //Fetch cart books for duplicate checking
        cartBooks = []
        let fetchedBooks = Book.fetchBooksFromCoreData()
        for book in fetchedBooks {
            if book.inCartOf != nil || book.inCartOf != [] {
                cartBooks.append(book)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Setup SearchBar
        searchBar.delegate = self
        
        //Setup TableView
        collectionView.delegate = self
        collectionView.dataSource = self
        
        //Check for previously fetched data
        let fetchedBooks = Book.fetchBooksFromCoreData()
        
        if fetchedBooks.count == 0 {
            urlComponents?.queryItems = [URLQueryItem(name: URLParams.q.rawValue, value: currentSearchQuery)]
            fetchBooksData(start: "0", maxResults: "20")
        }
        else{
            bookData = fetchedBooks
            callCount = fetchedBooks.count
            collectionView.reloadData()
            updateVisibleCells()
        }
        scrollToTop()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        UserDefaults.standard.set(currentSearchQuery, forKey: "currentSearchQuery")
        let managedContext = CoreDataManager.shared.viewContext
        do{
            try managedContext.save()
        }catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
    }
}

//MARK: Book Data Fetching
extension BookGridViewController{
    
    func fetchBooksData(start: String, maxResults: String){
        
        //Update necessary elements in URL
        
        urlComponents?.queryItems?.append(URLQueryItem(name: URLParams.startIndex.rawValue, value: start))
        urlComponents?.queryItems?.append(URLQueryItem(name: URLParams.maxResults.rawValue, value: maxResults))
        urlComponents?.queryItems?.append(URLQueryItem(name: URLParams.key.rawValue, value: "APIKEY"))
        
        dataTask?.cancel()
        
        //Get Data
        dataTask = defaultSession.dataTask(with: (urlComponents?.url!)!){[weak self] data, response, error in
            defer { self?.dataTask = nil }
            var books: [(id: String, name: String, publisher: String, bookDescription: String, publishedDate: NSDate?, imageURL: String, isbn: String, authors: [Author], epubIsAvailable: Bool, pdfisAvailable: Bool)] = []
            if let data = data,
                let json = ((try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]) as [String : Any]??) {
                //Check for error caused by exceeding api limits
                guard json?["error"] == nil else{
                    DispatchQueue.main.async {
                        let alert = UIAlertController(title: "Alert" , message: "Wait a while! API Limits exceeded.", preferredStyle: UIAlertController.Style.alert)
                        alert.addAction(UIAlertAction(title: "Okay!", style: UIAlertAction.Style.default, handler: nil))
                        
                        //Done to avoid already loading cells getting nil data
                        self?.scrollToTop()
                        self?.present(alert, animated: true, completion: nil)
                    }
                    return
                }
                //Check whether query returns zero items
                guard json?["totalItems"] as! Int > 0 else {
                    DispatchQueue.main.async {
                        let alert = UIAlertController(title: "Alert" , message: "Query hasn't yielded more results!", preferredStyle: UIAlertController.Style.alert)
                        alert.addAction(UIAlertAction(title: "Okay!", style: UIAlertAction.Style.default, handler: nil))
                        
                        //Done to avoid already loading cells getting nil data
                        self?.scrollToTop()
                        self?.present(alert, animated: true, completion: nil)
                    }
                    return
                }
                
                guard json?[JSONParams.items.rawValue] as? [Dictionary<String, Any>] != nil else {
                    return
                }
                
                for case let jsonBook in json?[JSONParams.items.rawValue] as! [Dictionary<String, Any>]{
//                    guard let id = jsonBook[JSONParams.id.rawValue] as? String else {
//                        continue
//                    }
                    
                    guard let bookData = Book.parseJSONForBook(json: jsonBook) else {
                        continue
                    }
                    
                    books.append(bookData)
                    //print("Appended New:  \(book.name!)")
                }
            }
            DispatchQueue.main.async {
                
                var foundInCart: Bool = false
                for book in books {
                    //Check for possible duplicates that could arise due to cart/owned books
                    if self?.cartBooks != nil {
                        for cartedBook in (self?.cartBooks)! {
                            if cartedBook.id == book.id {
                                self?.bookData.append(cartedBook)
                                foundInCart = true
                                break
                            }
                        }
                        if !foundInCart {
                            self?.bookData.append(Book(data: book))
                        }
                    } else {
                        self?.bookData.append(Book(data: book))
                    }
                }
                
                self?.furtherDataCalled = false
                self?.collectionView.reloadData()
                self?.updateVisibleCells()
            }
        }
        dataTask?.resume()
    }
}

//MARK: CollectionView Implementation

extension BookGridViewController: UICollectionViewDelegate, UICollectionViewDataSource{
    func scrollToTop(){
        let indexPath = IndexPath(row: 0, section: 0)
        if self.collectionView.numberOfItems(inSection: 0) > 0 {
            self.collectionView.scrollToItem(at: indexPath, at: .top, animated: true)
        }
    }
    
    //Done to dismiss keyboard
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        searchBar.resignFirstResponder()
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int{
        return bookData.count
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if(indexPath.row == bookData.count - 5){
            if !furtherDataCalled {
                furtherDataCalled = true
                callCount = bookData.count
                UserDefaults.standard.set(callCount, forKey: "callCount")
                urlComponents?.queryItems = [URLQueryItem(name: URLParams.q.rawValue, value: currentSearchQuery)]
                fetchBooksData(start: String(callCount), maxResults: String("20"))
                print("Fetching after: \(bookData.count)")
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell{
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "bookGridCell", for: indexPath) as? BookCollectionViewCell
        //needed because of error conditions
        guard bookData.count > indexPath.row else {
            return cell!
        }
        cell?.book = bookData[indexPath.row]
        cell?.setData()
        return cell!
    }
    
    func updateVisibleCells() {
        //print("Visible Cell COUNT : ",(tableView?.visibleCells.count)!)
        for cell in (collectionView?.visibleCells)!{
            let usableCell = cell as? BookCollectionViewCell
            usableCell?.downloadAndUpdateImage()
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        updateVisibleCells()
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        updateVisibleCells()
    }
    
    //MARK : testing for cellTapped can delete afterwards
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        //print("Did select Row At: \(indexPath.row)")
        let bookViewController = storyboard?.instantiateViewController(withIdentifier: "BookDetailViewControllerID") as! BookDetailViewController
        bookViewController.bookInfo = bookData[indexPath.row]
        self.navigationController?.pushViewController(bookViewController, animated: true)
        
    }
}


// MARK: - Search
extension BookGridViewController:UISearchBarDelegate{
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar){
        guard let searchQuery = searchBar.text else{
            return
        }
        UserDefaults.standard.set(callCount, forKey: "callCount")
        searchBar.resignFirstResponder()
        //TO DO : - DELETE THE BOOKS FROM COREDATA: -       DONE
        
        Book.deleteBooksFromCoreData()
        bookData = []
        currentSearchQuery = searchQuery
        UserDefaults.standard.set(currentSearchQuery, forKey: "currentSearchQuery")
        
        scrollToTop()
        urlComponents?.queryItems = [URLQueryItem(name: URLParams.q.rawValue, value: currentSearchQuery)]
        fetchBooksData(start: "0", maxResults: "20")
    }
    
//    func searchBarTextDidEndEditing(_ searchBar: UISearchBar){
//        guard let searchQuery = searchBar.text else{
//            return
//        }
//        guard searchQuery.characters.count>=5 else{
//            return
//        }
//        //TO DO : - DELETE THE BOOKS FROM COREDATA
//        bookData = []
//        currentSearchQuery = searchQuery
//        
//        scrollToTop()
//        fetchBooksData(query: currentSearchQuery, start: "0", maxResults: "20")
//    }
}

//MARK: - Filters
extension BookGridViewController{
    
    @IBAction func filterButtonTapped(_ sender: Any) {
        let filterViewController = self.storyboard?.instantiateViewController(withIdentifier: "FilterViewController") as! FilterViewController
        filterViewController.completionHandler = { [weak self] (_ filterItems:(filter: String?, langRestrict: String?, orderBy: String?, printType: String?), _ queryString: String) -> Void in
            
            self?.currentSearchQuery.append(queryString)
            
            self?.scrollToTop()
            Book.deleteBooksFromCoreData()
            self?.bookData = []
            self?.urlComponents?.queryItems = [URLQueryItem(name: URLParams.q.rawValue, value: self?.currentSearchQuery)]
            if filterItems.filter != nil{
                self?.urlComponents?.queryItems?.append(URLQueryItem(name: URLParams.filter.rawValue, value: filterItems.filter))
            }
            if filterItems.langRestrict != nil{
                self?.urlComponents?.queryItems?.append(URLQueryItem(name: URLParams.langRestrict.rawValue, value: filterItems.langRestrict))
            }
            if filterItems.orderBy != nil{
                self?.urlComponents?.queryItems?.append(URLQueryItem(name: URLParams.orderBy.rawValue, value: filterItems.orderBy))
            }
            if filterItems.printType != nil{
                self?.urlComponents?.queryItems?.append(URLQueryItem(name: URLParams.printType.rawValue, value: filterItems.printType))
            }
            
            self?.fetchBooksData(start: "0", maxResults: "20")
        }
        filterViewController.resetCompletionHandler = { [weak self] in
            self?.scrollToTop()
            Book.deleteBooksFromCoreData()
            self?.bookData = []
            
            //get first index of + and then get the substring upto that index
            self?.currentSearchQuery = (self?.currentSearchQuery.substring(to: (self?.currentSearchQuery.index(of: "+"))!))!
            
            self?.urlComponents?.queryItems = [URLQueryItem(name: URLParams.q.rawValue, value: self?.currentSearchQuery)]
            self?.fetchBooksData(start: "0", maxResults: "20")
        }
        self.navigationController?.pushViewController(filterViewController, animated: true)
    }
}

// MARK: - Navigation
extension BookGridViewController{
    /*
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    @IBAction func changeViewTapped(_ sender: Any) {
        let listViewController = self.storyboard?.instantiateViewController(withIdentifier: "BookListViewController") as! BookListViewController
        self.navigationController?.viewControllers = [listViewController]
    }
}

extension BookGridViewController : UICollectionViewDelegateFlowLayout {
    //1
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        //2
        let paddingSpace = sectionInsets.left * (itemsPerRow + 1)
        let availableWidth = view.frame.width - paddingSpace
        let widthPerItem = availableWidth / itemsPerRow
        
        return CGSize(width: widthPerItem, height: widthPerItem + 50)
    }
    
    //3
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        return sectionInsets
    }
    
    // 4
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return sectionInsets.left
    }
}
