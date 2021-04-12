//
//  PageVC1.swift
//  XMixScrollManager_swift_Example
//
//  Created by xing on 2021/4/14.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import MJRefresh
import UIKit
import XMixScrollManager_swift

class PageVC: UIViewController {
    let scrollView = UIScrollView()
    let childView = ChildView()
    var scrollManager: XMixScrollManager!
    lazy var settingView: SettingView = {
        let view = SettingView()
        view.hideBlock = { [weak self] in
            self?.reloadSetting()
        }
        return view
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setUI()
    }

    func setUI() {
        navigationItem.title = "ScrollView嵌套"
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "设置", style: .plain, target: self, action: #selector(settingClick))
        view.backgroundColor = .white
        scrollView.contentInsetAdjustmentBehavior = .never
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
        headButton.setTitle("height:\(topHeight):点击改变高度", for: .normal)
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
        scrollManager = XMixScrollManager(scrollView: scrollView, contentScrollViews: childView.contentViewArray)
        scrollManager.contentScrollDistance = CGFloat(topHeight)
        reloadSetting()
    }

    @objc func changeHeadHeightClick(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        let topHeight = sender.isSelected ? 1000 : 300
        sender.snp.updateConstraints { make in
            make.height.equalTo(topHeight)
        }
        sender.setTitle("height:\(topHeight):点击改变高度", for: .normal)
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
        let titles = ["进度条显示:", "支持下拉:", "回到顶部:", "动态模拟:", "单独设置属性:"]
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
            make.edges.equalTo(UIEdgeInsets(top: 15, left: 15, bottom: 15, right: 15))
        }

        class SelectView: UIView {
            var segmentControl: UISegmentedControl!
            init(title: String, segmentTitles: [String], index: Int) {
                super.init(frame: .zero)
                let label = UILabel()
                label.text = title
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
                    make.left.equalTo(120)
                    make.centerY.equalToSuperview()
                    make.right.equalTo(-10)
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
