//
//  ListStoreViewController.swift
//  42restaurants
//
//  Created by 최강훈 on 2021/07/24.
//

import UIKit
import Firebase
import CodableFirebase

class ListStoreViewController: UIViewController {

    @IBOutlet weak var storeTableView: UITableView!
    
    var ref: DatabaseReference!
    let storage = Storage.storage()
    
    
    var stores = [Store]()

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.storeTableView.delegate = self
        self.storeTableView.dataSource = self
        

        ref = Database.database(url: "https://restaurants-e62b0-default-rtdb.asia-southeast1.firebasedatabase.app").reference()
        
        getStoresInfoFromDatabase()
    }
    

    func getStoresInfoFromDatabase() {
        self.ref.child("stores").observe(DataEventType.value, with: { (snapshot) in
            
            if snapshot.exists() {
                self.stores = []
                guard let value = snapshot.value else {return}
                do {
                    let storesData = try FirebaseDecoder().decode([String: StoreInfo].self, from: value)
                    
                    for storeData in storesData {
                        let store: Store = Store(storeKey: storeData.key, storeInfo: storeData.value)
                        self.stores.append(store)
                    }
                    self.stores = self.stores.sorted(by: { $0.storeInfo.createDate < $1.storeInfo.createDate })
                    
                    DispatchQueue.main.async {
                        self.storeTableView.reloadData()
                    }
                } catch let err {
                    print(err.localizedDescription)
                }
            }
        })
        
    }
    
   
}

extension ListStoreViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.stores.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = self.storeTableView.dequeueReusableCell(withIdentifier: StoreTableViewCell.reuseIdentifier) as? StoreTableViewCell
        else { return UITableViewCell() }
        
        let store = self.stores[indexPath.row]
        
        cell.nameLabel?.text = store.storeInfo.name
        cell.addressLabel?.text = store.storeInfo.address
        cell.rateLabel?.text = "\(store.storeInfo.rating)"
        cell.categoryLabel?.text = store.storeInfo.category
        
        
        let storageRef = storage.reference()
        let reference = storageRef.child("\(store.storeInfo.mainImage)")
        let placeholderImage = UIImage(named: "placeholder.jpg")
        cell.storeImageView.sd_setImage(with: reference, placeholderImage: placeholderImage)
        
        return cell
    }
    
    
    
}

extension ListStoreViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        StoreSingleton.shared.store = self.stores[indexPath.row]
        guard let viewController = self.storyboard?.instantiateViewController(withIdentifier: "DetailViewController") as? DetailViewController
        else { return }

        self.navigationController?.pushViewController(viewController, animated: true)
        
    }
}
