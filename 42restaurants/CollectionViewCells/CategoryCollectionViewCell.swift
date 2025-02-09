//
//  CategoryCollectionViewCell.swift
//  42restaurants
//
//  Created by 최강훈 on 2021/10/22.
//

import UIKit

class CategoryCollectionViewCell: UICollectionViewCell {
    static let reuseIdentifer: String = "categoryCollectionViewCellReuseIdentifier"
    
    @IBOutlet weak var categoryLabel: UILabel!
    
    var isInitialSetupPerformed: Bool = false
    
    var isCellSelected: Bool = false
    
    
    override func layoutSubviews() {
        super.layoutSubviews()

    }

    func setCategoryCollectionViewCellUI() {
        self.categoryLabel?.font = UIFont.systemFont(ofSize: 16.0, weight: .regular)
        self.categoryLabel?.textColor = Config.shared.applicationFontLightColor
    }
    

    
    func setCellLabelText(_ text: String) {
        self.categoryLabel?.text = text
    }
    
    func onSelected() {
        self.categoryLabel.font = UIFont.systemFont(ofSize: 16.0, weight: .bold)
        self.categoryLabel.textColor = Config.shared.applicationFontDefaultColor
        if self.isCellSelected == false,
           let category = self.categoryLabel.text {
            

            NotificationCenter.default.post(name: Notification.Name("categorySelected"),
                                            object: nil,
                                            userInfo: ["category": category])
        } else {
            print("can't get categoryLabel's title")
        }
        isCellSelected = true
    }
    
    func onDeselected() {
        self.categoryLabel.font = UIFont.systemFont(ofSize: 16.0, weight: .regular)
        self.categoryLabel.textColor = Config.shared.applicationFontLightColor
        isCellSelected = false
    }
    
    
    
    

}
