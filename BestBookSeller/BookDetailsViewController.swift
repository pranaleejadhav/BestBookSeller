//
//  BookDetailsViewController.swift
//  BestBookSeller
//
//  Created by Pranalee Jadhav on 10/23/18.
//  Copyright © 2018 Pranalee Jadhav. All rights reserved.
//

import UIKit


class BookDetailsViewController: UIViewController {

    @IBOutlet weak var book_title: UILabel!
    @IBOutlet weak var author: UILabel!
    @IBOutlet weak var desc: UILabel!
    var bookDict = Dictionary<String,Any>()
    
    @IBOutlet weak var amazon_link: UITextView!
    @IBOutlet weak var review_link: UITextView!
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Book Details"
        //navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)

        book_title.text = bookDict["book_name"] as? String
        author.text = bookDict["author"] as? String
        desc.text = bookDict["book_description"] as? String
        review_link.text = (bookDict["review_link"] as? String)?.trimmingCharacters(in: .newlines)
        amazon_link.text = bookDict["amazon_product_url"] as? String
        
    }


}
