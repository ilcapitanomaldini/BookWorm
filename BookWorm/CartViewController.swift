//
//  CartViewController.swift
//  BookWorm
//
//  Created by MetaV on 9/28/17.
//  Copyright © 2017 MV. All rights reserved.
//

import UIKit

class CartViewController: UIViewController {

    var bookData: [Book] = []
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //Setup TableView
        tableView.delegate = self
        tableView.dataSource = self
    }

    override func viewWillAppear(_ animated: Bool) {
        let user = fetchCurrentUser()!
        bookData = user.cart?.allObjects as! [Book]
//        if bookData.count == 0 {
//            let alert = UIAlertController(title: "Empty Cart" , message: "Your cart is empty! Please add some books", preferredStyle: UIAlertControllerStyle.alert)
//            alert.addAction(UIAlertAction(title: "Okay!", style: UIAlertActionStyle.default, handler: nil))
//            self.present(alert, animated: true, completion: nil)
//        }
        tableView.reloadData()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func buyButtonTapped(_ sender: Any) {
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
}

//MARK : TableView Implementation

extension CartViewController: UITableViewDelegate, UITableViewDataSource{
    func scrollToTop(){
        let indexPath = IndexPath(row: 0, section: 0)
        if self.tableView.numberOfRows(inSection: 0) > 0 {
            self.tableView.scrollToRow(at: indexPath, at: .top, animated: true)
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int{
        if bookData.count > 0{
            return bookData.count
        }
        else{
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell{
        if bookData.count > 0{
            let cell = tableView.dequeueReusableCell(withIdentifier: "cartCell", for: indexPath) as? CartBookTableViewCell
        
            //needed because of error conditions
            guard bookData.count > indexPath.row else {
                return cell!
            }
        
            cell?.book = bookData[indexPath.row]
            cell?.setData()
            return cell!
        }
        else{
            let cell = tableView.dequeueReusableCell(withIdentifier: "emptyCartCell", for: indexPath)
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        if bookData.count == 0 {
            return .none
        }
        else{
            return .delete
        }
    }
    
 
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        let user = fetchCurrentUser()!
        if (editingStyle == UITableViewCell.EditingStyle.delete) {
            tableView.beginUpdates()
            //remove from cart
            user.removeFromCart(bookData[indexPath.row])
            bookData[indexPath.row].removeFromInCartOf(user)
            //remove from tableView dataSource
            bookData.remove(at: indexPath.row)
            //remove from tableView
            if bookData.count != 0{
                tableView.deleteRows(at: [indexPath], with: .fade)
            }
            else{
                let newIndexPath = IndexPath(row: 0, section: 0)
                tableView.insertRows(at: [newIndexPath], with: .left)
                tableView.deleteRows(at: [indexPath], with: .fade)
            }
            tableView.endUpdates()
            //save changes
            let managedContext = CoreDataManager.shared.viewContext
            do{
                try managedContext.save()
            }catch let error as NSError {
                print("Could not save. \(error), \(error.userInfo)")
            }
        }
    }
    
//    func updateVisibleCells() {
//        //print("Visible Cell COUNT : ",(tableView?.visibleCells.count)!)
//        for cell in (tableView?.visibleCells)!{
//            let usableCell = cell as? BookTableViewCell
//            usableCell?.downloadAndUpdateImage()
//        }
//    }
//    
//    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
//        updateVisibleCells()
//    }
//    
//    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
//        updateVisibleCells()
//    }
    
//    //MARK : testing for cellTapped can delete afterwards
//    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        let bookViewController = storyboard?.instantiateViewController(withIdentifier: "BookDetailViewControllerID") as! BookDetailViewController
//        bookViewController.bookInfo = bookData[indexPath.row]
//        self.navigationController?.pushViewController(bookViewController, animated: true)
//    }
}
