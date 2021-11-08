//
//  ReviewDetailSegmentViewController.swift
//  42restaurants
//
//  Created by 최강훈 on 2021/07/26.
//

import UIKit
import FirebaseDatabase
import FirebaseStorage
import CodableFirebase
import FirebaseUI

class ReviewDetailSegmentViewController: UIViewController {

    @IBOutlet weak var reviewTableView: UITableView!
    
    private var updateJustOnceFlag: Bool = false
    
    private var comments = [Comments]()
    
    
    var ref: DatabaseReference!
    let storageRef = Storage.storage().reference()
    
    let refreshControl = UIRefreshControl()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.reviewTableView.delegate = self
        self.reviewTableView.dataSource = self

        ref = Database.database(url: "https://restaurants-e62b0-default-rtdb.asia-southeast1.firebasedatabase.app").reference()
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(didReceiveReviewFilterSelectedNotification(_:)),
                                               name: Notification.Name("reviewFilterSelected"),
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(didReceiveReviewSubmitDone(_:)),
                                               name: Notification.Name("reviewSubmitDone"), object: nil)
        
        
        refreshControl.addTarget(self, action: #selector(onPullToReloadTableView), for: .valueChanged)
        self.reviewTableView.addSubview(refreshControl)
        
        setUI()
        setTableView()
    }
    
    @objc func onPullToReloadTableView() {
        if self.comments.count == 0 {
            self.setTableView()
        }
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1) {
            self.refreshControl.endRefreshing()
        }
    }
    
    @objc func didReceiveReviewSubmitDone(_ noti: Notification) {
        self.showBasicAlert(title: "제출 완료", message: "리뷰가 성공적으로 등록되었습니다 !")
    }
    
    @objc func didReceiveReviewFilterSelectedNotification(_ noti: Notification) {
        guard let reviewFilter = noti.userInfo?["reviewFilter"] as? String
        else { print("can't get reviewFilter notification"); return }
        
        switch reviewFilter {
        case Filter.latest.filterName:
            self.comments = self.comments.sorted(by: {  $0.comment.createDate > $1.comment.createDate })
        case Filter.ratingHigh.filterName:
            self.comments = self.comments.sorted(by: { $0.comment.rating > $1.comment.rating })
        case Filter.oldest.filterName:
            self.comments = self.comments.sorted(by: { $0.comment.createDate < $1.comment.createDate })
        case Filter.ratingLow.filterName:
            self.comments = self.comments.sorted(by: { $0.comment.rating < $1.comment.rating })
        default:
            self.comments = self.comments.sorted(by: { $0.comment.createDate > $1.comment.createDate })
            print("default filter notification in")
        }
        DispatchQueue.main.async {
            self.reviewTableView.reloadData()
        }
    }
    
    private func setUI() {
        self.reviewTableView.backgroundColor = .white
        
        
    }
    
    private func setTableView() {
        self.reviewTableView.estimatedRowHeight = 270
        self.updateTableView()
    }
    
    private func updateTableView() {
        if let tabBarIndex = self.tabBarController?.selectedIndex,
           let storeKey = tabBarIndex == 0 ? MainTabStoreSingleton.shared.store?.storeKey : StoreSingleton.shared.store?.storeKey {
            self.ref.child("stores/\(storeKey)/comments").observe(DataEventType.value, with: {
                (snapshot) in
                if snapshot.exists() {
                    guard let value = snapshot.value else { return }
                    do {
                        let commentsData = try FirebaseDecoder().decode([String: Comment].self, from: value)
                        self.comments = commentsData.map( { Comments.init(commentKey: $0.key, comment: $0.value) } )
                        self.comments = self.comments.sorted(by: { $0.comment.createDate > $1.comment.createDate })
                        DispatchQueue.main.async {
                            NotificationCenter.default.post(name: Notification.Name("getCurrentReviewFilter"),
                                                            object: nil)
                        }
                    } catch let err {
                        print(err.localizedDescription)
                    }
                    
                }
            })
        }
        
    }
    
}

extension ReviewDetailSegmentViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        self.comments.count
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let cell = self.reviewTableView.dequeueReusableCell(withIdentifier: ReviewTableViewCell.reuseIdentifier, for: indexPath) as? ReviewTableViewCell
        else { return UITableViewCell() }

        cell.reportButton.tag = indexPath.row
        cell.reportButton.addTarget(self, action: #selector(reportButtonTapped(_:)), for: .touchUpInside)
        
        if let images = self.comments[indexPath.row].comment.images?.values.map({ $0 }) {
            cell.images = images
        } else {
            cell.images = [Image]()
        }
        if let userId = self.comments[indexPath.row].comment.userId.components(separatedBy: "@").first {
            cell.setUserIdLabelText(userId: userId)
        }
        cell.setDescriptionLabelText(description: self.comments[indexPath.row].comment.description)
        cell.setRatingLabelText(rating: self.comments[indexPath.row].comment.rating)
        cell.setImage()
        self.reviewTableView.reloadRows(at: [indexPath], with: .none)
        
        return cell
    }
    
    @objc func reportButtonTapped(_ sender: UIButton) {
        let comment = self.comments[sender.tag]
        
        let alertController = UIAlertController(title: nil, message: "신고하기", preferredStyle: .actionSheet)
        let reportAction = UIAlertAction(title: "부적절한 컨텐츠입니다", style: .destructive, handler: {
            (alert: UIAlertAction!) -> Void in
            self.onReport(comment: comment)
        })
        let cancelAction = UIAlertAction(title: "취소", style: .default, handler: {
            (alert: UIAlertAction!) -> Void in
            
        })
        
        alertController.addAction(reportAction)
        alertController.addAction(cancelAction)
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    private func onReport(comment: Comments) {
        self.ref.child("reports/\(comment.commentKey)").getData(completion: { error, snapshot in
            if let error = error {
                print(error.localizedDescription)
            }
            if let value = snapshot.value {
                if type(of: value) == NSNull.self {
                    self.handleWhenNoReport(comment: comment)
                    return
                }
                print(value)
                do {
                    let report = try FirebaseDecoder().decode(Report.self, from: value)
                    self.increaseReportCount(comment, report)
                    
                } catch let e {
                    print(e.localizedDescription)
                }
            }
            
        })
        
    }
    
    private func handleWhenNoReport(comment: Comments) {
        let autoId = self.ref.child("reports/\(comment.commentKey)").childByAutoId().key
        self.ref.child("reports/\(comment.commentKey)").setValue([
            "reportCount" : 1,
            "reportUsers": [
                autoId: comment.comment.userId
            ]
        ]) { (error:Error?, ref:DatabaseReference) in
            if error != nil {
                self.showBasicAlert(title: "로그인이 필요합니다.", message: "로그인 후 이용해주세요")
            } else {
                self.showBasicAlert(title: "신고 완료", message: "접수되었습니다.")
            }
            
        }
    }
    
    private func increaseReportCount(_ comment: Comments,_ report: Report) {
        self.ref.child("reports/\(comment.commentKey)").child("reportCount").setValue(report.reportCount + 1)
        
        guard let autoId = self.ref.child("reports/\(comment.commentKey)/reportUsers").childByAutoId().key
        else { return }
        var reporters = [String: String]()
        for reporter in report.reportUsers {
            reporters[reporter.key] = reporter.value
        }
        reporters[autoId] = comment.comment.userId
        
        self.ref.child("reports/\(comment.commentKey)").child("reportUsers").setValue(reporters)
        { (error:Error?, ref:DatabaseReference) in
            if error != nil {
                self.showBasicAlert(title: "로그인이 필요합니다.", message: "로그인 후 이용해주세요")
            } else {
                ref.parent?.child("reportCount").getData(completion: { (error, snapshot) in
                    if let value = snapshot.value as? Int {
                        if value >= 10 {
                            RealtimeDBService.shared.deleteCommentByCommentKey(commentKey: comment.commentKey)
                        }
                    }
                })
                self.showBasicAlert(title: "신고 완료", message: "접수되었습니다.")
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.reviewTableView.deselectRow(at: indexPath, animated: true)
    }
    
    
    // MARK: - 테이블 뷰 상단 뷰 height를 줄이거나 넓힘.
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // 전제: DetailVC의 view 높이가 140임.
        // segmentView의 높이가 31, top Constraint가 15.
        
        if scrollView == self.reviewTableView {
            let viewHeight = UIScreen.main.bounds.height
            let contentOffset = scrollView.contentOffset.y
            

            if (contentOffset > viewHeight - (140 + 50 + 15)) {
                NotificationCenter.default.post(
                    name: Notification.Name("HideDetailView"),
                    object: nil,
                    userInfo: nil)
            }
            else {
                NotificationCenter.default.post(
                    name: Notification.Name("ShowDetailView"),
                    object: nil,
                    userInfo: nil)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
}
