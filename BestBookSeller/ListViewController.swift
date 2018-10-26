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

class ListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    @IBOutlet weak var tableView: UITableView!
    var tableArr = [Dictionary<String,String>]()
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    var context:NSManagedObjectContext!
    let dateFormatter = DateFormatter()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.tableFooterView = UIView()
        context = self.appDelegate.persistentContainer.viewContext
        dateFormatter.dateFormat = "yyyy-mm-dd"
        fetchList()
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
    
    func getDataFromApi() {
        print("getDataFromApi")
        getData(server_api: "lists/names.json", parameters: "", onSuccess: {(result) in
            SVProgressHUD.dismiss()
            self.tableArr.removeAll()
            let json = JSON(result!)
            if json["results"].exists(){
                //print(json["results"])
                
                for row in json["results"].array!{
                    let category: BookCategory = BookCategory(context: self.context)
                    let disp_name = row["display_name"].stringValue
                    let disp_ename = row["list_name_encoded"].stringValue
                    let published_date_str = row["newest_published_date"].stringValue
                    
                    let date = self.dateFormatter.date(from: published_date_str)
                    
                    category.display_name = disp_name
                    category.list_name_encoded = disp_ename
                    category.published_date = date
                    
                    self.tableArr.append(["display_name": disp_name, "list_name_encoded": disp_ename, "last_saved": ""])
                 }
                do {
                    try self.context.save()
                    UserDefaults.standard.set(NSDate(), forKey: "list_saved_date")
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
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "BookCategory")
        request.sortDescriptors = [NSSortDescriptor(key: "published_date", ascending: false)]
        do {
            tableArr.removeAll()
            let result = try context.fetch(request)
            
            for data in result as! [NSManagedObject] {
                var last_saved_str =  ""
                
                if let last_saved = data.value(forKey: "last_saved") {
                    last_saved_str = dateFormatter.string(from: last_saved as! Date)
                }
                tableArr.append(["display_name":data.value(forKey: "display_name") as! String, "list_name_encoded":data.value(forKey: "display_name") as! String, "last_saved": last_saved_str])
            }
            self.tableView.reloadData()
        } catch {
            print("Failed retrieving data")
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
        
        cell.textLabel?.text = tableArr[indexPath.row]["display_name"]
        
        cell.tag = indexPath.row
        return cell
    }
    
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        
        return 60;//Your custom row height
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
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
                let i = tableView.indexPath(for: cell)!.row
                let vc = segue.destination as! BookListViewController
                vc.category = tableArr[i]["list_name_encoded"]
                vc.list_saved_date = tableArr[i]["last_saved"]
                
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
    

}
