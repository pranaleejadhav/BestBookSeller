//
//  ServerManager.swift
//  BestBookSeller
//
//  Created by Pranalee Jadhav on 10/23/18.
//  Copyright © 2018 Pranalee Jadhav. All rights reserved.
//

import Foundation
import Alamofire


//check internet connectivity
class Connectivity {
    class var isConnectedToInternet:Bool {
        return NetworkReachabilityManager()!.isReachable
    }
}

let server_url = "https://api.nytimes.com/svc/books/v3/"

// server call to get data
func getData(server_api: String, parameters: String, onSuccess: @escaping (Any?)-> Void, onFail : @escaping (Error?) ->(Void)){
    
    let url = server_url + server_api + "?api-key=1a1f6166121741e5b936cd00d48ace59" + parameters
    
    Alamofire.request(url).responseJSON { (response:DataResponse<Any>) in
        
        switch response.result {
        case .success(let value):
            //print(value)
            onSuccess(value)
            
            break
            
        case .failure(let error):
            onFail(error)
            break
        }
    }
    
    
}
