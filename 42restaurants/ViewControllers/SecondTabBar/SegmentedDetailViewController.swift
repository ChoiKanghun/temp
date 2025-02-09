//
//  SegmentedDetailViewController.swift
//  42restaurants
//
//  Created by 최강훈 on 2021/07/26.
//

import UIKit

class SegmentedDetailViewController: UIViewController {

    @IBOutlet weak var segmentedControl: UISegmentedControl!
    
    lazy var photosViewController: PhotosDetailSegmentViewController = {
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        guard let viewController = storyboard.instantiateViewController(withIdentifier: "PhotosVC") as? PhotosDetailSegmentViewController
        else {return PhotosDetailSegmentViewController()}
        
        self.addViewControllerAsChildViewController(viewController)
        
        return viewController
    }()
    
    lazy var reviewViewController: ReviewDetailSegmentViewController = {
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        guard let viewController = storyboard.instantiateViewController(withIdentifier: "ReviewVC") as? ReviewDetailSegmentViewController
        else {return ReviewDetailSegmentViewController()}
        
        self.addViewControllerAsChildViewController(viewController)
        
        return viewController
    }()
    
    lazy var detailMapViewController: DetailMapViewController = {
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        guard let viewController = storyboard.instantiateViewController(withIdentifier: "detailMapVC") as? DetailMapViewController
        else { return DetailMapViewController() }
        
        self.addViewControllerAsChildViewController(viewController)
        
        return viewController
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setUpChildViews()
    }
    
    private func setUpChildViews() {
        self.segmentedControl.removeAllSegments()
        self.segmentedControl.insertSegment(withTitle: "사진", at: 0, animated: true)
        self.segmentedControl.insertSegment(withTitle: "리뷰", at: 1, animated: true)
        self.segmentedControl.insertSegment(withTitle: "지도", at: 2, animated: true)
        segmentedControl.addTarget(self, action: #selector(selectionDidChange(sender:)), for: .valueChanged)
        
        segmentedControl.selectedSegmentIndex = 0
        updateView()
    }
    
    @objc func selectionDidChange(sender: UISegmentedControl) {
        updateView()
    }
    
    private func updateView() {
        photosViewController.view.isHidden = !(segmentedControl.selectedSegmentIndex == 0)
        reviewViewController.view.isHidden = !(segmentedControl.selectedSegmentIndex == 1)
        detailMapViewController.view.isHidden = !(segmentedControl.selectedSegmentIndex == 2)
    }
    
    private func addViewControllerAsChildViewController(_ childViewController: UIViewController) {
        self.addChild(childViewController)
        
        self.view.addSubview(childViewController.view)
        
        childViewController.view.frame = view.bounds
        childViewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        childViewController.didMove(toParent: self)
        
    }

}
