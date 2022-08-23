//
//  PageVC1.swift
//  XMixScrollManager_swift_Example
//
//  Created by xing on 2021/4/14.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import MJRefresh
import UIKit
//import XMixScrollManager_swift
import XMixScrollManager

class PageVC: UIViewController {
    let scrollView = UIScrollView()
    let childView = ChildView()
    lazy var scrollManager = XMixScrollManager(scrollView: scrollView, contentScrollViews: childView.contentViewArray)
    lazy var settingView: SettingView = {
        let view = SettingView()
        view.hideBlock = { [weak self] in
            self?.reloadSetting()
        }
        return view
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 13.0, *) {
            let apperance = UINavigationBarAppearance()
            apperance.backgroundColor = .white
            apperance.shadowImage = UIImage()
            apperance.shadowColor = nil
            navigationController?.navigationBar.standardAppearance = apperance
            navigationController?.navigationBar.scrollEdgeAppearance = apperance
        }
        navigationController?.navigationBar.isTranslucent = false
        setUI()
    }

    func setUI() {
        navigationItem.title = "Demo"
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Settings", style: .plain, target: self, action: #selector(settingClick))
        view.backgroundColor = .white
        if #available(iOS 11.0, *) {
            scrollView.contentInsetAdjustmentBehavior = .never
        }
        scrollView.mj_header = MJRefreshNormalHeader(refreshingBlock: { [weak self] in
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self?.scrollView.mj_header?.endRefreshing()
            }
        })
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        addContentView()
    }

    func addContentView() {
        let topHeight = 300
        let headButton = UIButton()
        headButton.titleLabel?.textAlignment = .center
        headButton.setTitle("height:\(topHeight)\nClick to change height", for: .normal)
        headButton.titleLabel?.numberOfLines = 0
        headButton.addTarget(self, action: #selector(changeHeadHeightClick(_:)), for: .touchUpInside)
        headButton.backgroundColor = .brown
        let navBottom = navigationController!.navigationBar.frame.maxY
        scrollView.addSubview(headButton)
        headButton.snp.makeConstraints { make in
            make.left.top.equalToSuperview()
            make.width.equalTo(self.view)
            make.height.equalTo(topHeight)
            make.bottom.equalTo(-(view.frame.height - navBottom))
        }
        scrollView.addSubview(childView)
        childView.snp.makeConstraints { make in
            make.left.bottom.equalToSuperview()
            make.width.equalTo(headButton)
            make.top.equalTo(headButton.snp.bottom)
        }
        scrollManager.contentScrollDistance = CGFloat(topHeight)
        reloadSetting()
    }

    @objc func changeHeadHeightClick(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        let topHeight = sender.isSelected ? 1000 : 300
        sender.snp.updateConstraints { make in
            make.height.equalTo(topHeight)
        }
        sender.setTitle("height:\(topHeight)\nClick to change height", for: .normal)
        scrollManager.contentScrollDistance = CGFloat(topHeight)
    }

    @objc func settingClick() {
        settingView.show()
    }

    func reloadSetting() {
        scrollManager.mixScrollPullType = settingView.mixScrollPullType
        scrollManager.scrollsToMainTop = settingView.scrollsToMainTop
        scrollManager.enableDynamicSimulate = settingView.enableDynamicSimulate
        scrollManager.showIndicatorType = settingView.showIndicatorType
        scrollManager.enableCustomConfig = settingView.enableCustomConfig
        /// 分别设置属性
        if scrollManager.enableCustomConfig {
            scrollManager.setScrollPullType(.sub, contentScrollView: childView.contentViewArray[1])
            scrollManager.setEnableDynamicSimulate(true, contentScrollView: childView.contentViewArray[1])
            scrollManager.setScrollPullType(.all, contentScrollView: childView.contentViewArray[2])
        }
    }

    deinit {
        print(NSStringFromClass(self.classForCoder) + "-deinit")
    }
}

class SettingView: UIView {
    var showIndicatorType: XShowIndicatorType {
        return XShowIndicatorType(rawValue: segmengArray[0].selectedSegmentIndex)!
    }

    var mixScrollPullType: XMixScrollPullType {
        return XMixScrollPullType(rawValue: segmengArray[1].selectedSegmentIndex)!
    }

    var scrollsToMainTop: Bool {
        return (segmengArray[2].selectedSegmentIndex == 0)
    }

    var enableDynamicSimulate: Bool {
        return (segmengArray[3].selectedSegmentIndex == 0)
    }

    var enableCustomConfig: Bool {
        return (segmengArray[4].selectedSegmentIndex == 0)
    }

    var hideBlock: os_block_t?
    @objc func hide() {
        hideBlock?()
        removeFromSuperview()
    }

    func show() {
        UIApplication.shared.keyWindow?.addSubview(self)
        snp.makeConstraints { make in
            make.edges.equalTo(UIEdgeInsets.zero)
        }
    }

    private var segmengArray = [UISegmentedControl]()

    init() {
        super.init(frame: .zero)
        setUI()
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(hide)))
    }

    func setUI() {
        backgroundColor = UIColor.black.withAlphaComponent(0.5)
        let titles = ["Scroll bar show:", "Pull down refresh:", "Scroll to top:", "Continuous scrolling:", "Set individually:"]
        let segmentTitles = [["hide", "sub", "change"],
                             ["none", "main", "sub", "all"],
                             ["main", "sub"],
                             ["YES", "NO"],
                             ["YES", "NO"]]

        let contentView = UIView()
        contentView.layer.cornerRadius = 8
        contentView.backgroundColor = .groupTableViewBackground
        addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 20
        for (i, title) in titles.enumerated() {
            let selectView = SelectView(title: title, segmentTitles: segmentTitles[i], index: i)
            segmengArray.append(selectView.segmentControl)
            stackView.addArrangedSubview(selectView)
        }
        contentView.addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.edges.equalTo(UIEdgeInsets(top: 15, left: 8, bottom: 15, right: 8))
        }

        class SelectView: UIView {
            var segmentControl: UISegmentedControl!
            init(title: String, segmentTitles: [String], index: Int) {
                super.init(frame: .zero)
                let label = UILabel()
                label.text = title
                label.adjustsFontSizeToFitWidth = true
                label.minimumScaleFactor = 0.7
                label.textAlignment = .left
                addSubview(label)
                label.snp.makeConstraints { make in
                    make.left.equalToSuperview()
                    make.top.bottom.equalToSuperview()
                }
                segmentControl = UISegmentedControl(items: segmentTitles)
                segmentControl.backgroundColor = .groupTableViewBackground
                addSubview(segmentControl)
                if index == 0 {
                    segmentControl.selectedSegmentIndex = 2
                } else if index == 3 || index == 4 {
                    segmentControl.selectedSegmentIndex = 1
                } else {
                    segmentControl.selectedSegmentIndex = 1
                }
                segmentControl.snp.makeConstraints { make in
                    make.left.equalTo(label.snp.right)
                    make.left.equalTo(150)
                    make.centerY.equalToSuperview()
                    make.right.equalTo(-8)
                }
            }

            required init?(coder: NSCoder) {
                fatalError("init(coder:) has not been implemented")
            }
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
