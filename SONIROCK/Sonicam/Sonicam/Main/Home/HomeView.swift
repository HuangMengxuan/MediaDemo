//
//  HomeView.swift
//  Sonicam
//
//  Created by lsyy on 2017/11/23.
//  Copyright © 2017年 sonirock. All rights reserved.
//

import UIKit
import SnapKit

class HomeView: UIView {
    lazy var homeImageView = UIImageView.init()
    lazy var logoImageView = UIImageView.init()
    lazy var buyButton = UIButton.init(type: .custom)
    lazy var connectCameraButton = UIButton.init()
    lazy var localRzesourceButton = UIButton.init()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let homeImagePath = Bundle.main.path(forResource: "bitmap360", ofType: "jpg")
        if let path = homeImagePath {
            homeImageView.image = UIImage.init(contentsOfFile: path)
        }
        self.addSubview(homeImageView)
        logoImageView.image = UIImage.init(named: "home_logo")
        self.addSubview(logoImageView)
        buyButton.setBackgroundImage(UIImage.init(named: "home_buy"), for: .normal)
        buyButton.titleLabel?.text = "BUY"
        self.addSubview(buyButton)
        
        
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func layoutSubviews() {
        homeImageView.snp.makeConstraints { (constraint) in
            constraint.edges.equalToSuperview()
        }
        
        logoImageView.snp.makeConstraints { (constraint) in
            constraint.centerX.equalToSuperview()
            constraint.centerY.equalToSuperview().multipliedBy(2.0 / 3.0)
        }
        
        buyButton.snp.makeConstraints { (constraint) in
            constraint.centerX.equalToSuperview()
            constraint.width.equalTo(60)
            constraint.height.equalTo(30)
            constraint.top.equalTo(logoImageView.snp.bottom).offset(10)
        }
    }
}
