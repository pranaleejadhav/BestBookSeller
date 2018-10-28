//
//  BookListViewController.swift
//  BestBookSeller
//
//  Created by Pranalee Jadhav on 10/23/18.
//  Copyright © 2018 Pranalee Jadhav. All rights reserved.
//

import UIKit
import SVProgressHUD
import SwiftyJSON
import CoreData

class BookListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var segmentedCtrl: UISegmentedControl!
    @IBOutlet weak var tableView: UITableView!
    var tableArr = [Dictionary<String,Any>]()
    var last_saved: Date!
    let dateFormatter = DateFormatter()
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    var context: NSManagedObjectContext!
    var categoryObj: BookCategory!
    var today_date:String!
    var currOrder = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        context = self.appDelegate.persistentContainer.viewContext
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        tableView.tableFooterView = UIView()
        dateFormatter.dateFormat = "yyyy-mm-dd"
        today_date = dateFormatter.string(from: Date())
        let label = UILabel(frame: CGRect(x: 0.0, y: 0.0, width: UIScreen.main.bounds.width, height: 44.0))
        label.backgroundColor = UIColor.clear
        label.numberOfLines = 0
        label.textColor = UIColor.white
        label.font = UIFont.boldSystemFont(ofSize: 17)
        //[infoLabel setFont:[UIFont boldSystemFontOfSize:16]];
        label.textAlignment = NSTextAlignment.center
        label.text = categoryObj.display_name
        self.navigationItem.titleView = label
        //self.title = categoryObj.display_name
        //self.navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: self, action: nil)
        /*if last_saved_str != "" {
            last_saved = self.dateFormatter.date(from: categoryObj.last_saved)
        }*/
        fetchList()
    }
    
    func findDateDifference(old_date: Date)->Int{
        let components = Calendar.current.dateComponents([.weekOfYear], from: old_date, to: Date())
        return components.weekOfYear!
    }
    
    //fetch data
    func fetchList() -> Void {
        //SVProgressHUD.show()
        
        if Connectivity.isConnectedToInternet {
            //let userdefaults = UserDefaults.standard
            last_saved = categoryObj.last_saved
            print("last saved \(last_saved)")
            //getDataFromApi()
            
            if last_saved == nil || ( findDateDifference(old_date: last_saved!) > 0){
                
                getDataFromApi()
                
            } else {
                
                getSavedData()
                
            }
        } else {
            if last_saved == nil {
                SVProgressHUD.dismiss()
                self.showMsg(title: "Oops!", subTitle: "No Internet")
            } else {
                getSavedData()
            }
        }
    }
    
    func getDataFromApi() {
        print("getDataFromApi \(categoryObj.list_name_encoded)")
        getData(server_api: "lists.json", parameters: "&list=" + categoryObj.list_name_encoded!, onSuccess: {(result) in
            SVProgressHUD.dismiss()
            self.tableArr.removeAll()
            let json = JSON(result!)
            if json["results"].exists(){
                print(json["results"])
                
                if self.last_saved != nil {
                    self.deteleOldData()
                }
               for row in json["results"].array!{
                    let book = Book(context: self.context)
                    let rank = row["rank"].intValue
                    let weeks_on_list = row["weeks_on_list"].intValue
                    let book_details = row["book_details"].array![0]
                    let author_name = book_details["author"].stringValue
                    let book_name = book_details["title"].stringValue
                    let desc = book_details["description"].stringValue
                    var amazon_link = row["amazon_product_url"].stringValue
                    let reviews = row["reviews"].array![0]
                    var review_links = ""
                    if reviews["book_review_link"] != "" {
                        review_links += "book_review_link: " + reviews["book_review_link"].stringValue + "\n\n"
                    }
                    if reviews["first_chapter_link"] != "" {
                        review_links += "first_chapter_link: " + reviews["first_chapter_link"].stringValue + "\n\n"
                    }
                    if reviews["sunday_review_link"] != "" {
                        review_links += "sunday_review_link: " + reviews["sunday_review_link"].stringValue + "\n\n"
                    }
                    if reviews["article_chapter_link"] != "" {
                        review_links += "article_chapter_link: " + reviews["article_chapter_link"].stringValue
                    }
                
                if review_links == "" {
                    review_links = "Not Available"
                }
                
                if amazon_link == "" {
                    amazon_link = "Not Available"
                }
                    
                    let date = self.dateFormatter.date(from: row["bestsellers_date"].stringValue)
                    
                    book.book_title = book_name
                    book.rank = Int32(rank)
                    book.weeks_on_list = Int32(weeks_on_list)
                    book.author = author_name
                    book.book_description = desc
                    book.review_link = review_links
                    book.amazon_product_url = amazon_link
                    book.bestsellers_date = date
                    book.modified_date = self.today_date
                    self.categoryObj.addToBooklist(book)
                    self.categoryObj.last_saved = Date()
                    self.categoryObj.order = self.currOrder
                    self.tableArr.append(["book_name": book_name, "rank": rank, "weeks": weeks_on_list, "author": author_name, "book_description": desc, "review_link": review_links, "amazon_product_url": amazon_link])
                }
                do {
                    try self.context.save()
                   print("last saved \(self.categoryObj.last_saved )")
                    self.reorder()
                    self.tableView.reloadData()
                } catch {
                    print("Failed saving")
                }
            }
            
            
        }, onFail: {(error) in
            self.showMsg(title: "Error", subTitle: "Please try again")
        })
    }
    
    func getSavedData() {
        print("getSavedData")
        SVProgressHUD.dismiss()
        var books = categoryObj.booklist?.allObjects as! [Book]
        //books = books.sorted(by: { $0.bestsellers_date! > $1.bestsellers_date! })
        
        do {
            tableArr.removeAll()
            
            for data in books {
                //print(data)
                 self.tableArr.append(["book_name": data.value(forKey: "book_title") as! String, "rank": data.value(forKey: "rank") as! Int, "weeks": data.value(forKey: "weeks_on_list") as! Int, "author": data.value(forKey: "author") as! String, "book_description": data.value(forKey: "book_description") as! String, "review_link": data.value(forKey: "review_link") as! String, "amazon_product_url": data.value(forKey: "amazon_product_url") as! String])
                
            }
            currOrder = categoryObj.order
            reorder()
            self.tableView.reloadData()
        }
        
    }
    func deteleOldData() {
        let books = categoryObj.booklist?.allObjects as! [Book]
        
        let filtered_books = books.filter{ $0.modified_date != today_date }
        
        for book in filtered_books {
             context.delete(book)
        }
        do {
            try context.save()
        } catch {
            print ("There was an error")
        }
       
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return tableArr.count
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cellItem")!
        cell.textLabel?.text = tableArr[indexPath.row]["book_name"] as? String
        cell.textLabel?.numberOfLines = 0
        return cell
    }
    
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        
        return 60;//Your custom row height
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //self.performSegue(withIdentifier: "showbookdetails", sender: self)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showbookdetails" {
            if let cell = sender as? UITableViewCell {
                let i = tableView.indexPath(for: cell)!.row
                let vc = segue.destination as! BookDetailsViewController
                vc.bookDict = tableArr[i]
            }
            /*var temp_user = User(nameStr: helloLb.text!, deptStr: "CS")
             vc.user = temp_user
             vc.nameParam = helloLb.text!*/
        }
        
    }
    
    //show alert box
    func showMsg(title: String, subTitle: String) -> Void {
        DispatchQueue.main.async(execute: {
            let alertController = UIAlertController(title: title, message:
                subTitle, preferredStyle: UIAlertControllerStyle.alert)
            alertController.addAction(UIAlertAction(title: "Okay", style: UIAlertActionStyle.default,handler: nil))
            self.present(alertController, animated: true, completion: nil)
        })
    }

    func reorder() {
        if currOrder {
            segmentedCtrl.selectedSegmentIndex = 0
            tableArr = tableArr.sorted(by: { ($0["rank"] as! Int) < ($1["rank"] as! Int)})
            
        } else {
            segmentedCtrl.selectedSegmentIndex = 1
            tableArr = tableArr.sorted(by: { ($0["weeks"] as! Int) > ($1["weeks"] as! Int)})
        }
        tableView.reloadData()
    }
    
    @IBAction func changeOrder(_ sender: Any) {
        print("change order")
        currOrder = !currOrder
        categoryObj.order = currOrder
        do {
            try context.save()
        } catch {
            print ("There was an error")
        }
        reorder()
        
    }
    

}
