//
//  ListViewController.swift
//  BestBookSeller
//
//  Created by Pranalee Jadhav on 10/23/18.
//  Copyright © 2018 Pranalee Jadhav. All rights reserved.
//

import UIKit
import SVProgressHUD
import SwiftyJSON
import CoreData


extension ListViewController: UISearchResultsUpdating {
    // MARK: - UISearchResultsUpdating Delegate
    func updateSearchResults(for searchController: UISearchController) {
        filterContentForSearchText(searchController.searchBar.text!)
        

    }
}



class ListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    @IBOutlet weak var tableView: UITableView!
    
    var tableArr = [Dictionary<String,Any>]()
    var filteredList = [Dictionary<String,Any>]()
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    var context:NSManagedObjectContext!
    let dateFormatter = DateFormatter()
    var categoryItems = [BookCategory]()
    var today_date:String!
    let searchController = UISearchController(searchResultsController: nil)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.tableFooterView = UIView()
        tableView.keyboardDismissMode = .onDrag
        context = self.appDelegate.persistentContainer.viewContext
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        dateFormatter.dateFormat = "yyyy-mm-dd"
        let fullDateFormatter = DateFormatter()
        fullDateFormatter.dateFormat = "yyyy-mm-dd HH:mm:ss"
        today_date = dateFormatter.string(from: Date())
        
        navigationController?.navigationBar.barTintColor = #colorLiteral(red: 0.1765674055, green: 0.4210852385, blue: 0.8841049075, alpha: 1)
        navigationController?.navigationBar.titleTextAttributes = [NSAttributedStringKey.foregroundColor: UIColor.white]
        navigationController?.navigationBar.tintColor = UIColor.white
        
        
        // Setup the Search Controller
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        //searchController.searchBar.placeholder = "Search Categories"
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true
        searchController.searchBar.tintColor = .white
        UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).defaultTextAttributes = [NSAttributedStringKey.foregroundColor.rawValue: UIColor.white]
        UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).attributedPlaceholder = NSAttributedString(string: "Search Categories", attributes: [NSAttributedStringKey.foregroundColor: UIColor.white])

        
        fetchList()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        //searchController.isActive = true
        self.title = "List of Book Categories"
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        self.title = ""
    }
    
    func findDateDifference(old_date: Date)->Int{
        let components = Calendar.current.dateComponents([.weekOfYear], from: old_date, to: Date())
        return components.weekOfYear!
    }
    
    //fetch data
    func fetchList() -> Void {
        SVProgressHUD.show()
        
        let userdefaults = UserDefaults.standard
        let list_saved_date = userdefaults.object(forKey: "list_saved_date")
        
        if Connectivity.isConnectedToInternet {
            
            
            if list_saved_date == nil || ( findDateDifference(old_date: (list_saved_date as? Date)!) > 0){
                
                getDataFromApi()
                
            } else {
                
                getSavedData()
                
            }
        } else {
            if list_saved_date == nil {
                SVProgressHUD.dismiss()
                self.showMsg(title: "Oops!", subTitle: "No Internet")
            } else {
                getSavedData()
            }
        }
    }
    
    func getBookItems() {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "BookCategory")
        request.sortDescriptors = [NSSortDescriptor(key: "id", ascending: true)]
        do {
            let result = try self.context.fetch(request)
            categoryItems = result as! [BookCategory]
        } catch {
            
        }
    }
    
    func getEntityObj(list_name: String) -> BookCategory{
        if categoryItems.count == 0 {
            print("inside")
            return BookCategory(context: self.context)
        } else {
            print("inside else")
            let filtered_book = categoryItems.filter{ $0.list_name_encoded == list_name }[0]
            return filtered_book
            
        }
    }
    
    func getDataFromApi() {
        print("getDataFromApi")
        getData(server_api: "lists/names.json", parameters: "", onSuccess: {(result) in
            SVProgressHUD.dismiss()
            self.tableArr.removeAll()
            let json = JSON(result!)
            if json["results"].exists(){
                //print(json["results"])
               
                //self.deteleOldData()
                self.getBookItems()
                var i = 0
                for row in json["results"].array!{
                   
                    let disp_ename = row["list_name_encoded"].stringValue
                    let category =  self.getEntityObj(list_name: disp_ename)
                    let disp_name = row["display_name"].stringValue
                    let published_date_str = row["newest_published_date"].stringValue
                    
                    category.list_name_encoded = disp_ename
                    category.display_name = disp_name
                    category.modified_date = self.today_date
                    category.id = Int32(i)
                    
                    //category.last_saved = date
                    //category.booklist = nil
                    //print("category \(category)")
                    
                    self.tableArr.append(["display_name": disp_name, "id": i])
                    i += 1
                 }
               
                
                do {
                    try self.context.save()
                    self.getBookItems()
                    
                    //print(self.categoryItems)
                    self.deteleOldData()
                    //let request = NSFetchRequest<NSFetchRequestResult>(entityName: "BookCategory")
                   // let result = try self.context.fetch(request)
                //self.categoryItems = result as! [BookCategory]
                 //   UserDefaults.standard.set(Date(), forKey: "list_saved_date")
                    
                   //self.tableArr = self.tableArr.sorted { $0["published_date"]! >  $1["published_date"]!}
                    self.tableView.reloadData()
                } catch let error as NSError {
                    print("Failed saving \(error)")
                }
            }
            
        }, onFail: {(error) in
            self.showMsg(title: "Error", subTitle: "Please try again")
        })
    }
    
    func getSavedData() {
        print("getSavedData")
        SVProgressHUD.dismiss()
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "BookCategory")
        request.sortDescriptors = [NSSortDescriptor(key: "id", ascending: true)]
        do {
            tableArr.removeAll()
            
            let result = try context.fetch(request)
            categoryItems = result as! [BookCategory]
            
            for data in result as! [NSManagedObject] {
                var last_saved_str =  ""
                
                if let last_saved = data.value(forKey: "last_saved") {
                    last_saved_str = dateFormatter.string(from: last_saved as! Date)
                }
                tableArr.append(["id":data.value(forKey: "id") as! Int, "display_name":data.value(forKey: "display_name") as! String])
            }
            self.tableView.reloadData()
        } catch {
            print("Failed retrieving data")
        }
        
    }
    
    func deteleOldData() {
        let deleteFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "BookCategory")
        let predicate = NSPredicate(format: "modified_date != %@", today_date)
        deleteFetch.predicate = predicate
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: deleteFetch)
        
        do {
            try context.execute(deleteRequest)
            try context.save()
        } catch {
            print ("There was an error")
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isFiltering() {
            return filteredList.count
        }
        return tableArr.count
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cellItem")!
        var item: Dictionary<String, Any>
        
        if isFiltering() {
            item = filteredList[indexPath.row] as Dictionary<String, Any>
        } else {
            item = tableArr[indexPath.row] as Dictionary<String, Any>
            
        }
        
        cell.textLabel?.text = item["display_name"] as? String
        cell.textLabel?.numberOfLines = 0
        cell.tag = (item["id"] as! Int)
        return cell
    }
    
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        
        return 60;//Your custom row height
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        //self.performSegue(withIdentifier: "showbooklist", sender: self)
        /*let bundle = Bundle.main
        let storyboard = UIStoryboard(name: "Main", bundle: bundle)
        let newViewController: DetailsViewController = storyboard.instantiateViewController(withIdentifier: "DetailsViewController") as! DetailsViewController
        newViewController.dict = item[indexPath.row]
        self.navigationController?.pushViewController(newViewController, animated: true)
        */
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showbooklist" {
            if let cell = sender as? UITableViewCell {
                let i = cell.tag//tableView.indexPath(for: cell)!.row
                let vc = segue.destination as! BookListViewController
                vc.categoryObj = self.categoryItems[i]
            }
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
    

    // MARK: - Private instance methods
    
    func searchBarIsEmpty() -> Bool {
        // Returns true if the text is empty or nil
        return searchController.searchBar.text?.isEmpty ?? true
    }
    
    func filterContentForSearchText(_ searchText: String, scope: String = "All") {
        filteredList = tableArr.filter ({ (dict: Dictionary<String, Any>) -> Bool in
            return (dict["display_name"] as! String).lowercased().contains(searchText.lowercased())
        })
        tableView.reloadData()
    }
    
    func isFiltering() -> Bool {
        return searchController.isActive && !searchBarIsEmpty()
    }

}
