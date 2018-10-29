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

// MARK: - Delegate UISearchResultsUpdating
extension ListViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        filterListForSearchText(searchController.searchBar.text!)
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
        context = self.appDelegate.persistentContainer.viewContext
        //tableView.tableFooterView = UIView()
        tableView.keyboardDismissMode = .onDrag // dismiss keyboard on scroll
        
        // configure navigation bar
        navigationController?.navigationBar.barTintColor = #colorLiteral(red: 0.1765674055, green: 0.4210852385, blue: 0.8841049075, alpha: 1)
        navigationController?.navigationBar.titleTextAttributes = [NSAttributedStringKey.foregroundColor: UIColor.white]
        navigationController?.navigationBar.tintColor = UIColor.white
        
        // configure search controller
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        definesPresentationContext = true
        if #available(iOS 11.0, *) {
            searchController.searchBar.tintColor = .white
            UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).defaultTextAttributes = [NSAttributedStringKey.foregroundColor.rawValue: UIColor.white]
            UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).attributedPlaceholder = NSAttributedString(string: "Search Categories", attributes: [NSAttributedStringKey.foregroundColor: UIColor.white])

            navigationItem.searchController = searchController
            navigationItem.hidesSearchBarWhenScrolling = false
        } else {
            tableView.tableHeaderView = searchController.searchBar
            searchController.searchBar.placeholder = "Search Categories"
        }
        
        // fetch data
        fetchList()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        self.title = "List of Book Categories"
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        self.title = ""
    }
    
    // MARK: - TableView Functions
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isFiltering() { // if using search bar
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
        return 60;
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if tableArr.count == 0 {
        
        let footerView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: 80))
        
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: 80))
        label.text = "List not found"
        label.textAlignment = .center
        label.textColor = #colorLiteral(red: 0.1765674055, green: 0.4210852385, blue: 0.8841049075, alpha: 1)
        footerView.addSubview(label)
        return footerView
        } else {
            return nil
        }
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
       if tableArr.count == 0 {
        return 80
       } else {
        return 0
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showbooklist" {
            if let cell = sender as? UITableViewCell {
                let i = cell.tag
                let vc = segue.destination as! BookListViewController
                vc.categoryObj = self.categoryItems[i] // pass book category object
            }
        }
    }
    
    
    // MARK: - Show Alert Box
    
    func showMsg(title: String, subTitle: String) -> Void {
        DispatchQueue.main.async(execute: {
            let alertController = UIAlertController(title: title, message:
                subTitle, preferredStyle: UIAlertControllerStyle.alert)
            alertController.addAction(UIAlertAction(title: "Okay", style: UIAlertActionStyle.default,handler: nil))
            self.present(alertController, animated: true, completion: nil)
        })
    }
    

    // MARK: - Search Bar Functions
    
    func searchBarIsEmpty() -> Bool {
        return searchController.searchBar.text?.isEmpty ?? true // Returns true if search text is nil or empty
    }
    
    func filterListForSearchText(_ searchText: String) {
        filteredList = tableArr.filter ({ (dict: Dictionary<String, Any>) -> Bool in
            return (dict["display_name"] as! String).lowercased().contains(searchText.lowercased())
        })
        tableView.reloadData()
    }
    
    func isFiltering() -> Bool {
        return searchController.isActive && !searchBarIsEmpty()
    }
    
    // MARK: - Fetch Data
    
    func fetchList() -> Void {
        dateFormatter.dateFormat = "yyyy-mm-dd HH:mm:ss"
        today_date = dateFormatter.string(from: Date())
        
        SVProgressHUD.show()
        
        let list_saved_date = UserDefaults.standard.object(forKey: "list_saved_date") // get stored date of list
        
        if Connectivity.isConnectedToInternet {
            if list_saved_date == nil || ( findDateDifference(old_date: (list_saved_date as? Date)!) > 0){
                getDataFromApi()
            } else {
                getSavedData()
            }
        } else {
            SVProgressHUD.dismiss()
            if list_saved_date == nil {
                SVProgressHUD.dismiss()
                self.showMsg(title: "Oops!", subTitle: "No Internet")
            } else {
                getSavedData()
            }
        }
    }
    
    func getDataFromApi() {
        print("Get List From Api")
        getData(server_api: "lists/names.json", parameters: "", onSuccess: {(result) in
            SVProgressHUD.dismiss()
            self.tableArr.removeAll()
            let json = JSON(result!)
            if json["results"].exists(){
                self.getBookItems()
                var i = 0
                // save data in table array
                for row in json["results"].array!{
                    let disp_ename = row["list_name_encoded"].stringValue
                    let disp_name = row["display_name"].stringValue
                    // return same object if already present in coredata or else new object
                    let category =  self.getEntityObj(list_name: disp_ename)
                    
                    category.list_name_encoded = disp_ename
                    category.display_name = disp_name
                    category.modified_date = self.today_date
                    category.id = Int32(i)
                    
                    self.tableArr.append(["display_name": disp_name, "id": i])
                    i += 1
                }
                
                do {
                    // save data in coredata
                    try self.context.save()
                    UserDefaults.standard.set(Date(), forKey: "list_saved_date")
                    self.getBookItems()
                    self.deteleOldData()
                    // reload tableview
                    self.tableView.reloadData()
                } catch let error as NSError {
                    print("Failed saving \(error)")
                }
            }
            
        }, onFail: {(error) in
            SVProgressHUD.dismiss()
            self.showMsg(title: "Error", subTitle: "Please try again")
        })
    }
    
    func getSavedData() {
        print("Get List From Coredata")
        SVProgressHUD.dismiss()
        
        getBookItems()
        tableArr.removeAll()
            // save data in table array
            for data in categoryItems  {
                tableArr.append(["id":data.value(forKey: "id") as! Int, "display_name":data.value(forKey: "display_name") as! String])
            }
            self.tableView.reloadData()
        
    }
    
    func getBookItems() {
        // fetch data from coredata
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "BookCategory")
        request.sortDescriptors = [NSSortDescriptor(key: "id", ascending: true)]
        do {
            let result = try self.context.fetch(request)
            categoryItems = result as! [BookCategory]
        } catch {
            self.showMsg(title: "Error", subTitle: "Please try again")
        }
    }
    
    func getEntityObj(list_name: String) -> BookCategory{
        if categoryItems.count == 0 {
            return BookCategory(context: self.context) // return new BookCategory object
        } else {
            let filtered_book = categoryItems.filter{ $0.list_name_encoded == list_name }[0]
            return filtered_book // return BookCategory object which is already present in coredata
            
        }
    }
    
    func findDateDifference(old_date: Date)->Int{
        // to find the difference between two dates
        let components = Calendar.current.dateComponents([.weekOfYear], from: old_date, to: Date())
        return components.weekOfYear!
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

}
