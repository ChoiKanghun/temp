//
//  ListStoreViewController.swift
//  42restaurants
//
//  Created by 최강훈 on 2021/07/24.
//

import UIKit
import Firebase
import CodableFirebase
import CoreLocation


class ListStoreViewController: UIViewController {

    @IBOutlet weak var storeTableView: UITableView!
    @IBOutlet weak var categoryCollectionView: UICollectionView!
    @IBOutlet weak var titleLabel: UILabel!
    
    var ref: DatabaseReference!
    let storage = Storage.storage()
    var categories: [Category] = []
    
    
    var stores = [Store]()
    var filteredStores = [Store]()
    var countForJustExecuteOnce: Bool = false
    
    let refreshControl = UIRefreshControl()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setCategories()
        LoadingService.showLoading()
        setDelegateDataSource()
        addNotifications()
        self.ref = Database.database(url: "https://restaurants-e62b0-default-rtdb.asia-southeast1.firebasedatabase.app").reference()
        addRefreshControl()
        getStoresInfoFromDatabase()
        setCollectionViewLayout()
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        setUI() // view will appear에 두는 이유는 다음 화면에서 다시 돌아올 때를 대비하기 위해서.
        adaptFilter()
    }
    
    private func setCategories() {
        self.categories = [Category.all,
                           Category.koreanAsian,
                           Category.japaneseCutlet,
                           Category.chinese,
                           Category.western,
                           Category.chickenPizza,
                           Category.bunsik,
                           Category.mexican,
                           Category.fastFood,
                           Category.meat,
                           Category.cafe]
    }
    
    private func setDelegateDataSource() {
        self.storeTableView.delegate = self
        self.storeTableView.dataSource = self
        self.categoryCollectionView.delegate = self
        self.categoryCollectionView.dataSource = self
    }

    private func addNotifications() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.didReceiveCategorySelectedNotification(_:)),
                                               name: Notification.Name("categorySelected"), object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.didReceiveFilterSelectedNotification(_:)),
                                               name: Notification.Name("filterSelected"), object: nil)
    }
    
    @objc func didReceiveCategorySelectedNotification(_ noti: Notification) {
        guard let category = noti.userInfo?["category"] as? String,
              let currentCategory = self.titleLabel?.text
        else { print("can't handle didReceiveCategory Notification"); return; }
        
        if category != currentCategory { executeCategoryFiltering(category) }
        DispatchQueue.main.async { self.titleLabel.text = category }
    }
    
    private func executeCategoryFiltering(_ category: String) {
        switch category {
        case Category.all.rawValue:
            self.filteredStores = self.stores.sorted(by: { $0.storeInfo.createDate < $1.storeInfo.createDate })
        case Category.koreanAsian.rawValue:
            self.filteredStores = self.stores.filter({ $0.storeInfo.category == Category.koreanAsian.rawValue })
        case Category.japaneseCutlet.rawValue:
            self.filteredStores = self.stores.filter({ $0.storeInfo.category == Category.japaneseCutlet.rawValue })
        case Category.chinese.rawValue:
            self.filteredStores = self.stores.filter({ $0.storeInfo.category == Category.chinese.rawValue })
        case Category.western.rawValue:
            self.filteredStores = self.stores.filter({ $0.storeInfo.category == Category.western.rawValue })
        case Category.chickenPizza.rawValue:
            self.filteredStores = self.stores.filter({ $0.storeInfo.category == Category.chickenPizza.rawValue })
        case Category.bunsik.rawValue:
            self.filteredStores = self.stores.filter({ $0.storeInfo.category == Category.bunsik.rawValue })
        case Category.mexican.rawValue:
            self.filteredStores = self.stores.filter({ $0.storeInfo.category == Category.mexican.rawValue })
        case Category.fastFood.rawValue:
            self.filteredStores = self.stores.filter({ $0.storeInfo.category == Category.fastFood.rawValue })
        case Category.meat.rawValue:
            self.filteredStores = self.stores.filter({ $0.storeInfo.category == Category.meat.rawValue })
        case Category.cafe.rawValue:
            self.filteredStores = self.stores.filter({ $0.storeInfo.category == Category.cafe.rawValue })
        default:
            self.filteredStores = self.stores.sorted(by: { $0.storeInfo.createDate < $1.storeInfo.createDate })
            print("in default category filter")
        }
        
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: Notification.Name("categoryDidChange"),
                                            object: nil,
                                            userInfo: nil)
            self.storeTableView.reloadData()
        }
    }
    
    @objc func didReceiveFilterSelectedNotification(_ noti: Notification) {
        guard let filter = noti.userInfo?["filter"] as? String
        else { print("can't handle didReceiveFilter noti"); return }
        
        switch filter {
        case Filter.latest.filterName:
            self.filteredStores = self.filteredStores.sorted(by: { $0.storeInfo.createDate > $1.storeInfo.createDate })
        case Filter.nearest.filterName:
            self.filteredStores = self.filteredStores.sorted(
                by: { self.getDistanceFromCurrentLocation($0.storeInfo.latitude, $0.storeInfo.longtitude) <
                    self.getDistanceFromCurrentLocation($1.storeInfo.latitude, $1.storeInfo.longtitude) })
        case Filter.ratingHigh.filterName:
            self.filteredStores = self.filteredStores.sorted(by: { $0.storeInfo.rating > $1.storeInfo.rating })
        case Filter.reviewCount.filterName:
            self.filteredStores = self.filteredStores.sorted(by: { $0.storeInfo.commentCount > $1.storeInfo.commentCount })
        case Filter.oldest.filterName:
            self.filteredStores = self.filteredStores.sorted(by: { $0.storeInfo.createDate < $1.storeInfo.createDate })
        case Filter.ratingLow.filterName:
            self.filteredStores = self.filteredStores.sorted(by: { $0.storeInfo.rating < $1.storeInfo.rating })
        default:
            self.filteredStores = self.filteredStores.sorted(by: { $0.storeInfo.createDate > $1.storeInfo.createDate })
            print("default filter notification in")
        }
        
        DispatchQueue.main.async { self.storeTableView.reloadData() }
    }

    private func getDistanceFromCurrentLocation(_ targetLatitude: Double, _ targetLongitude: Double) -> CLLocationDistance {
        let currentLocationLatitude = UserDefaults.standard.double(forKey: "currentLocationLatitude")
        let currentLocationLongitude = UserDefaults.standard.double(forKey: "currentLocationLongitude")
        
        let targetLocation = CLLocationCoordinate2D(latitude: targetLatitude, longitude: targetLongitude)
        let currentLocation = CLLocationCoordinate2D(latitude: currentLocationLatitude, longitude: currentLocationLongitude)
        
        return targetLocation.distance(from: currentLocation)
    }
    
    private func addRefreshControl() {
        self.refreshControl.attributedTitle = NSAttributedString(string: "")
        self.refreshControl.addTarget(self, action: #selector(onPullToRefreshFetchDataWhenNoData), for: .valueChanged)
        self.storeTableView.addSubview(refreshControl)
    }
    
    @objc func onPullToRefreshFetchDataWhenNoData() {
        if self.filteredStores.isEmpty == true {
            getStoresInfoFromDatabase()
        }
        DispatchQueue.main.async {
            self.refreshControl.endRefreshing()
        }
    }
    
    private func getStoresInfoFromDatabase() {
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
                    self.filteredStores = self.stores.sorted(by: { $0.storeInfo.createDate < $1.storeInfo.createDate })
                    
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(name: Notification.Name("changeToCurrentFilter"),
                                                        object: nil)
                    }
                } catch let err {
                    print(err.localizedDescription)
                }
            }
        })
        
    }
    
    private func setCollectionViewLayout() {
        if let layout = categoryCollectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            //this value represents the minimum spacing between items in the same column.
            layout.minimumInteritemSpacing = 30
            //this value represents the minimum spacing between successive columns.
            layout.minimumLineSpacing = 30
            layout.sectionInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        }
    }
    
    private func setUI() {
        self.setStatusBarBackgroundColor(color: Config.shared.application30Color)
        self.setNavigationBarBackgroundColor(color: Config.shared.application30Color)
        self.categoryCollectionView.backgroundColor = Config.shared.application60Color
        self.storeTableView.backgroundColor = Config.shared.application60Color
        self.setNavigationBarHidden(isHidden: true)
        
    }
    
    private func adaptFilter() {
        NotificationCenter.default.post(name: Notification.Name("changeToCurrentFilter"),
                                        object: nil)
    }
    
}

extension ListStoreViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.filteredStores.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = self.storeTableView.dequeueReusableCell(withIdentifier: StoreTableViewCell.reuseIdentifier) as? StoreTableViewCell
        else { return UITableViewCell() }
        
        let store = self.filteredStores[indexPath.row]
        
        cell.store = store
        
        // cell 안에 Firebase를 import하면 용량이 훨씬 커지지 않을까..
        let storageRef = storage.reference()
        let reference = storageRef.child("\(store.storeInfo.mainImage)")
        let placeholderImage = UIImage(named: "placeholder.jpg")
        cell.storeImageView.sd_setImage(with: reference, placeholderImage: placeholderImage)
        
        hideLoadingWhenTableViewDidAppear(indexPath)
        return cell
    }
    
    
    
    private func hideLoadingWhenTableViewDidAppear(_ indexPath: IndexPath) {
        if indexPath.row == self.filteredStores.count - 1 { LoadingService.hideLoading() }
    }
    
    
}

extension ListStoreViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        StoreSingleton.shared.store = self.filteredStores[indexPath.row]
        
        guard let viewController = self.storyboard?.instantiateViewController(withIdentifier: "DetailViewController") as? DetailViewController
        else { return }
            
        tableView.deselectRow(at: indexPath, animated: true)
        self.navigationController?.pushViewController(viewController, animated: true)
        
    }
    
}


extension ListStoreViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        self.categories.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = self.categoryCollectionView.dequeueReusableCell(withReuseIdentifier: "categoryCollectionViewCellReuseIdentifier", for: indexPath) as? CategoryCollectionViewCell
        else { return UICollectionViewCell() }
        
        if indexPath.row == 0 { selectFirstCell(cell, indexPath) }
        
        cell.setCellLabelText(self.categories[indexPath.row].rawValue)
        cell.setCategoryCollectionViewCellUI()

        if cell.isSelected == true { cell.onSelected() }
        else { cell.onDeselected() }
        return cell
    }
    
    private func selectFirstCell(_ cell: CategoryCollectionViewCell, _ indexPath: IndexPath) {
        if self.countForJustExecuteOnce == false {
            self.countForJustExecuteOnce = true
            DispatchQueue.main.async {
                self.categoryCollectionView.selectItem(at: indexPath, animated: true, scrollPosition: .init())
                cell.onSelected()
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let cell = self.categoryCollectionView.cellForItem(at: indexPath) as? CategoryCollectionViewCell
        else { print("can't execute didSelectItemAt"); return }
        
        cell.onSelected()
        
    }
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        guard let cell = self.categoryCollectionView.cellForItem(at: indexPath) as? CategoryCollectionViewCell
        else { print("can't execute didSelectItemAt"); return }
        
        cell.onDeselected()
        
    }
   
}

extension ListStoreViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 30, height: 30)
    }
}


