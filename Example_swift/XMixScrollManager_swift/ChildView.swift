//
//  ChildView.swift
//  XMixScrollManager_swift_Example
//
//  Created by xing on 2021/4/14.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import MJRefresh
import SnapKit
import UIKit

class ChildView: UIView, UIScrollViewDelegate {
    var segment: UISegmentedControl!
    let scrollView = UIScrollView()
    var contentViewArray = [UIScrollView]()

    init() {
        super.init(frame: .zero)
        setUI()
    }

    func setUI() {
        var items = [String]()
        let viewNum = 5
        for i in 0 ..< viewNum {
            items.append("View\(i + 1)")
        }
        backgroundColor = .groupTableViewBackground
        segment = UISegmentedControl(items: items)
        segment.backgroundColor = .groupTableViewBackground
        segment.addTarget(self, action: #selector(segmentValueChange(_:)), for: .valueChanged)
        segment.selectedSegmentIndex = 0
        addSubview(segment)
        segment.snp.makeConstraints { make in
            make.top.equalTo(5)
            make.centerX.equalToSuperview()
        }
        addSubview(scrollView)
        scrollView.isPagingEnabled = true
        scrollView.delegate = self
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(segment.snp.bottom).offset(5)
        }

        let dataArray = Array(repeating: "data", count: 50)
        for i in 0 ..< viewNum {
            let contentView = ChildContentView(dataArray: dataArray)
            scrollView.addSubview(contentView)
            contentView.snp.makeConstraints { make in
                make.top.bottom.equalToSuperview()
                make.width.equalTo(kScreenWidth)
                make.height.equalToSuperview()
                make.left.equalTo(kScreenWidth * CGFloat(i))
                if i == viewNum - 1 {
                    make.right.equalToSuperview()
                }
            }
            contentViewArray.append(contentView.tableView)
        }
    }

    @objc func segmentValueChange(_ segment: UISegmentedControl) {
        scrollView.setContentOffset(CGPoint(x: CGFloat(segment.selectedSegmentIndex) * scrollView.frame.width, y: 0), animated: true)
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let index = scrollView.contentOffset.x / scrollView.frame.width
        segment.selectedSegmentIndex = Int(index)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class ChildContentView: UIView, UITableViewDelegate, UITableViewDataSource {
    let tableView = UITableView()
    var dataArray = [String]()

    init(dataArray: [String]) {
        super.init(frame: .zero)
        self.dataArray = dataArray
        setUI()
    }

    func setUI() {
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.delegate = self
        tableView.dataSource = self
        tableView.mj_header = MJRefreshNormalHeader(refreshingBlock: { [weak self] in
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self?.tableView.mj_header?.endRefreshing()
            }
        })
        tableView.mj_footer = MJRefreshBackStateFooter(refreshingBlock: { [weak self] in
            guard let self = self else {
                return
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.tableView.mj_footer!.endRefreshing()
                self.dataArray.append(contentsOf: ["add", "add", "add", "add", "add"])
                self.tableView.reloadData()
            }
        })
        addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataArray.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell")!
        cell.textLabel?.text = "\(dataArray[indexPath.row])-\(indexPath.row + 1)"
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
