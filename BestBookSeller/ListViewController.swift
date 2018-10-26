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
    var tableArr = [JSON]()
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    let context:NSManagedObjectContext!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.tableFooterView = UIView()
        context = self.appDelegate.persistentContainer.viewContext
        fetchList()
    }
    
    func findDateDifference(old_date: Date)->Int{
        let components = Calendar.current.dateComponents([.weekOfYear], from: old_date, to: Date())
        return components.weekOfYear!
    }
    
    //fetch data
    func fetchList() -> Void {
        if Connectivity.isConnectedToInternet {
            SVProgressHUD.show()
            
            let userdefaults = UserDefaults.standard
            let list_saved_date = userdefaults.object(forKey: "list_saved_date")
            if list_saved_date == nil || ( findDateDifference(old_date: (list_saved_date as? Date)!) < 0){
                UserDefaults.standard.set(NSDate(), forKey: "list_saved_date")
            getData(server_api: "lists/names.json", parameters: "", onSuccess: {(result) in
                SVProgressHUD.dismiss()
                let json = JSON(result)
                print("ANSWER")
                if json["results"].exists(){
                    print(json["results"])
                    
            
                    for row in json["results"].array!{
                        let category: BookCategory = BookCategory(context: self.context)
                        category.display_name = row["display_name"].stringValue
                        category.list_name_encoded = row["list_name_encoded"].stringValue
                        //category.last_saved = Date()
                    }
                    do {
                        try self.context.save()
                    } catch {
                        print("Failed saving")
                    }
                    self.tableArr = json["results"].array!
                }
               
                
                /*if let dict = result as? Dictionary<String, Any>{
                    if let arr = dict["results"] as? [Dictionary<String, Any>] {
                        self.tableArr = arr
                    }
                }*/
                //print(self.tableArr)
                self.tableView.reloadData()
                
            }, onFail: {(error) in
                SVProgressHUD.dismiss()
                self.showMsg(title: "Error", subTitle: "Please try again")
            })
        } else {
                let request = NSFetchRequest<NSFetchRequestResult>(entityName: "BookCategory")
                //request.sortDescriptors = [NSSortDescriptor(key: "id", ascending: true)]
                
                
                
            }
        } else {
            self.showMsg(title: "Oops!", subTitle: "No Internet")
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
        
        cell.textLabel?.text = tableArr[indexPath.row]["display_name"].stringValue
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
                vc.category = tableArr[i]["list_name_encoded"].stringValue
                print(vc.category)
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
