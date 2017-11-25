//
//  HMXHomeViewController.swift
//  Sonicam
//
//  Created by lsyy on 2017/11/23.
//  Copyright © 2017年 sonirock. All rights reserved.
//

import UIKit
import SnapKit

class HomeViewController: UIViewController {
    lazy var homeView = HomeView.init()

    override func viewDidLoad() {
        super.viewDidLoad()

        view .addSubview(homeView)
        
        title = "HomePage"
        
        navigationController?.isNavigationBarHidden = true
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        homeView.snp.makeConstraints { (constraint) in
            constraint.edges.equalToSuperview()
        }
    }
}
