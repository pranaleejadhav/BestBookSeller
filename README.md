# NYTimes Bestseller App

### Language: Swift v4

## Required Tools

- Alamofire
- SVProgressHUD
- SwiftyJSON

## Features
- Display list of book categories.
- On click of a category, display corresponding list of books.
- List of books can be ordered by rank or weeks on list.
- By selecting a book, it should display details of book like book name, author's name, description.
- In book details, it should also display amazon_product link and review_links if present.

## Extra Features
- Data Caching for list of book categories and list of books for each book category. (Using coredata and relationships to easily update the old data and relate list of books with book category)
- Data can be viewed in offline mode also, if data is available in coredata.
- Search functionality to filter list of book categories.
- Save last sort order in list of books for each book category.

### For Screenshots, please refer Screenshots folder in the same directory.

### Categories list in iOS 11
![Alt text](https://github.com/pranaleejadhav/BestBookSeller/blob/master/BestBookSeller/Screenshots/categories_list_iOS11.png)

### Categories list in iOS 10
![Alt text](https://github.com/pranaleejadhav/BestBookSeller/blob/master/BestBookSeller/Screenshots/categories_list_iOS10.png)

### List of Books
![Alt text](https://github.com/pranaleejadhav/BestBookSeller/blob/master/BestBookSeller/Screenshots/book_list.png)

### Book Details
![Alt text](https://github.com/pranaleejadhav/BestBookSeller/blob/master/BestBookSeller/Screenshots/book_details_1.png)

### Book Details
![Alt text](https://github.com/pranaleejadhav/BestBookSeller/blob/master/BestBookSeller/Screenshots/book_details_2.png)

## Coredata Schema
### Two Entities : BookCategory & Book
BookCategory is in one to many relationship with Book.

### Entity: BookCategory

- id : to order data as fetched from web api
- display_name : display name of book category
- list_name_encoded : encoded name of book category
- modified_date : to remove old data which is no longer needed
- order: sort order of book list
- last_saved : last date of saved list of books

### Entity: Book

- rank : rank of book
- book_title : name of book
- author : name of author
- book_description: description of book
- modified_date : to remove old data which is no longer needed
- weeks_on_list : weeks on list
- review_link : review links of book
- amazon_product_link : amazon product link of book

## Files

ListViewController: 
- Last date of saving data is saved in userdefaults.
- If stored data is one week old, fetch list of book categories from 'https://api.nytimes.com/svc/books/v3/lists/names.json' and simultaneously, save the list in coredata entity 'Book Category'. Update the last date of stored data in userdefsults.
- Else, fetch the list from coredata entity 'Book Category'.
- Update Tableview.
- On click of a cell, pass the object of entity 'Book Category' and redirect to BookListViewController.

## BookListViewController
- The passed object stores the last date of saving list of books.
- If stored data is one week old, fetch list of book categories from 'https://api.nytimes.com/svc/books/v3/lists.json' and simultaneously, save the list in coredata entity 'Book'. Update the last date of 'Book Category' object.
- Else, fetch the list from coredata entity 'Book Category'.
- Update Tableview.
- On click of a cell, redirect to BookDetailsViewController.

## BookDetailsViewController
- It will show all the details of book.
