//
//  BookListViewController.swift
//  BestBookSeller
//
//  Created by Pranalee Jadhav on 10/23/18.
//  Copyright © 2018 Pranalee Jadhav. All rights reserved.
//

import UIKit
import SVProgressHUD

class BookListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    @IBOutlet weak var tableView: UITableView!
    var tableArr = [Dictionary<String,Any>]()
    var category:String! = ""
    var list_saved_date:String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.tableFooterView = UIView()
        fetchList()
    }
    
    
    //fetch data
    func fetchList() -> Void {
        tableArr.removeAll()
        if Connectivity.isConnectedToInternet {
            SVProgressHUD.show()
            print("&list=" + category)
            getData(server_api: "lists.json", parameters: "&list=" + category, onSuccess: {(result) in
                SVProgressHUD.dismiss()
                if let dict = result as? Dictionary<String, Any>{
                    if let arr = dict["results"] as? [Dictionary<String, Any>] {
                        /*for row in arr {
                            //print("each row \(row)")
                            
                            //self.tableArr.append(["rank":(row["rank"] as? Int)!,"book_details":(row["book_details"] as? [Dictionary<String, Any>])![0], "weeks":(row["weeks_on_list"] as? Int)!])
                        }*/
                        self.tableArr = arr
                    }
                }
                print(self.tableArr)
                self.tableView.reloadData()
                
            }, onFail: {(error) in
                SVProgressHUD.dismiss()
                self.showMsg(title: "Error", subTitle: "Please try again")
            })
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
        
        let dict = tableArr[indexPath.row]["book_details"] as? Dictionary<String, Any>
        //print("dict = \(dict)")
        cell.textLabel?.text = dict!["title"] as? String
        return cell
    }
    
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        
        return 60;//Your custom row height
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.performSegue(withIdentifier: "showbookdetails", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showbookdetails" {
            let vc = segue.destination as! BookListViewController
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


}
