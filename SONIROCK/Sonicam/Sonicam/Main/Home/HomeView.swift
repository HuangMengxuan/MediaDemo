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
    lazy var homeImageView: UIImageView = {
        let imageView = UIImageView.init()
        let homeImagePath = Bundle.main.path(forResource: "bitmap360", ofType: "jpg")
        if let path = homeImagePath {
            imageView.image = UIImage.init(contentsOfFile: path)
        }
        return imageView
    }()
    
    lazy var logoImageView: UIImageView = {
        let imageView = UIImageView.init()
        imageView.image = UIImage.init(named: "home_logo")
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    lazy var buyButton: UIButton = {
        let button = UIButton.init(type: .custom)
        button.setBackgroundImage(UIImage.init(named: "home_buy"), for: .normal)
        button .setTitle("BUY", for: .normal)
        button.addTarget(self, action: #selector(HomeView.buyButtonClick), for: UIControlEvents.touchUpInside)
        return button
    }()
    
    lazy var connectCameraButton: UIButton = {
        let button = UIButton.init(type: .custom)
        button.setBackgroundImage(UIImage.init(named: "home_btn_bg"), for: .normal)
        button .setTitle("连接相机", for: .normal)
        button.addTarget(self, action: #selector(HomeView.connectCameraButtonClick(sender:)), for: UIControlEvents.touchUpInside)
        return button
    }()
    
    lazy var localResourceButton: UIButton = {
        let button = UIButton.init(type: .custom)
        button.setBackgroundImage(UIImage.init(named: "home_btn_bg"), for: .normal)
        button .setTitle("本地资源", for: .normal)
        button.addTarget(self, action: #selector(HomeView.localResourceButtonClick), for: UIControlEvents.touchUpInside)
        return button
    }()
    
    lazy var webSiteLabel: UILabel = {
        let label = UILabel.init()
        label.font = UIFont.systemFont(ofSize: 13.0)
        label.text = "www.sonicam.co"
        label.textColor = UIColor.white
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.addSubview(homeImageView)
        self.addSubview(logoImageView)
        self.addSubview(buyButton)
        self.addSubview(connectCameraButton)
        self.addSubview(localResourceButton)
        self.addSubview(webSiteLabel)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        homeImageView.snp.makeConstraints { (constraint) in
            constraint.edges.equalToSuperview()
        }
        
        logoImageView.snp.makeConstraints { (constraint) in
            constraint.centerX.equalToSuperview()
            constraint.centerY.equalToSuperview().multipliedBy(1.0 / 2.0)
            constraint.width.equalToSuperview().multipliedBy(2.0 / 3.0)
        }
        
        buyButton.snp.makeConstraints { (constraint) in
            constraint.centerX.equalToSuperview()
            constraint.width.equalTo(60)
            constraint.height.equalTo(30)
            constraint.top.equalTo(logoImageView.snp.bottom).offset(10)
        }
        
        connectCameraButton.snp.makeConstraints { (constraint) in
            constraint.centerX.equalToSuperview()
            constraint.bottom.equalTo(localResourceButton.snp.top).offset(-20)
        }
        
        localResourceButton.snp.makeConstraints { (constraint) in
            constraint.centerX.equalToSuperview()
            constraint.bottom.equalTo(webSiteLabel.snp.top).offset(-30)
        }
        
        webSiteLabel.snp.makeConstraints { (constraint) in
            constraint.centerX.equalToSuperview()
            constraint.bottom.equalToSuperview().offset(-10)
        }
    }
    
    @objc func buyButtonClick() -> Void {
        print("buyButtonClick")
    }
    
    @objc func connectCameraButtonClick(sender: UIButton) -> Void {
        print("connectCameraButtonAction")
    }
    
    @objc func localResourceButtonClick() -> Void {
        print("localResourceButtonClick")
    }
}
