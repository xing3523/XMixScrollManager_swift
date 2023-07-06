//
//  XMixScrollManager.swift
//  XMixScrollManager_swift
//
//  Created by xing on 2021/4/12.
//

import Foundation
import UIKit

private let XKeyPath = "contentOffset"
private let XMixScrollUndefinedValue: CGFloat = -999
/// Pull type
@objc public enum XMixScrollPullType: Int {
    case none = 0
    case main
    case sub
    case all
}

/// Scroll bar display
@objc public enum XShowIndicatorType: Int {
    case none = 0
    case sub
    case autoChange
}

open class XMixScrollManager: NSObject {
    // MARK: - public properties and methods

    /// The movable distance of contentScrollView, generally the relative coordinate Y in mainScrollView, the default XMixScrollUndefinedValue, takes effect immediately, dynamic simulation will not take effect before assigning a valid value
    /// contentScrollView 可移动的距离 一般为在mainScrollView里的相对坐标Y 默认 XMixScrollUndefinedValue 即时生效  赋值有效值之前动态模拟不会生效
    @objc open var contentScrollDistance: CGFloat = XMixScrollUndefinedValue {
        willSet {
            contentScrollDistance = ceil(newValue)
        }
    }

    /// The default main can be pulled down
    @objc open var mixScrollPullType: XMixScrollPullType {
        set {
            _mixScrollPullType = newValue
        } get {
            if enableCustomConfig {
                return pullTypeDic[currentIndex] ?? _mixScrollPullType
            } else {
                return _mixScrollPullType
            }
        }
    }

    /// Scroll bar display, automatically switch the display by default
    /// 默认切换显示
    @objc open var showIndicatorType: XShowIndicatorType = .autoChange {
        didSet {
            mainScrollView.property.needShowsVerticalScrollIndicator = showIndicatorType == .autoChange
            mainScrollView.showsVerticalScrollIndicator = mainScrollView.property.needShowsVerticalScrollIndicator
            for contentScrollView in contentScrollViews {
                contentScrollView.property.needShowsVerticalScrollIndicator = showIndicatorType != .none
            }
        }
    }

    /// Whether to return directly to the top of the mainScrollView when clicking the status bar back to the top
    /// 点击状态栏回顶部时，是否直接回到mainScrollView顶部，默认Yes
    @objc open var scrollsToMainTop: Bool {
        set {
            _scrollsToMainTop = newValue
        } get {
            if enableCustomConfig {
                return scrollsToMainTopDic[currentIndex] ?? _scrollsToMainTop
            } else {
                return _scrollsToMainTop
            }
        }
    }

    /// Whether to enable dynamic simulation, default NO, in the main scope outside the content scope, pull up has not transition sliding effect, YES, add simulation continuous sliding effect
    /// 是否开启动态模拟，默认 NO，在main范围内content范围外，上拉没有过渡滑动效果，YES则添加模拟连续滑动效果
    @objc open var enableDynamicSimulate: Bool {
        set {
            _enableDynamicSimulate = newValue
        } get {
            if enableCustomConfig {
                return enableDynamicDic[currentIndex] ?? _enableDynamicSimulate
            } else {
                return _enableDynamicSimulate
            }
        }
    }

    /// Rolling resistance, default 2
    /// 动态模拟过度滑动效果 阻力参数 默认 2
    @objc open var dynamicResistance: Float = 2
    /// Enable independent property setting, default NO
    /// 开启独立属性设置，默认NO
    @objc open var enableCustomConfig = false
    /// The upper height of the main ScrollView, which is used to determine whether dynamic simulation is in the range to be enabled. contentScrollDistance is used by default
    /// 主ScrollView头部高度，用于判断是否在需要启用动态模拟的范围，默认使用contentScrollDistance判断
    @objc open var mainTopHeight: CGFloat = XMixScrollUndefinedValue

    /// Method of initialization
    /// - Parameters:
    ///   - scrollView: Main scroll view
    ///   - contentScrollViews: contentScrollViews
    @objc public init(scrollView: UIScrollView, contentScrollViews: [UIScrollView]?) {
        super.init()
        let p = scrollView.property
        p.isMain = true
        p.canScroll = true
        p.markScroll = true
        p.scrollManager = self
        scrollView.addObserver(self, forKeyPath: XKeyPath, options: .new, context: nil)
        mainScrollView = scrollView
        if let array = contentScrollViews {
            self.contentScrollViews.append(contentsOf: array)
        }
        for (index, contentScrollView) in self.contentScrollViews.enumerated() {
            let p = contentScrollView.property
            p.markScroll = true
            p.index = index
            p.scrollManager = self
            contentScrollView.addObserver(self, forKeyPath: XKeyPath, options: .new, context: nil)
        }
        showIndicatorType = .autoChange
    }

    deinit {
        self.mainScrollView.removeObserver(self, forKeyPath: XKeyPath)
        self.contentSuperScrollView?.removeObserver(self, forKeyPath: XKeyPath)
        for contentScrollView in self.contentScrollViews {
            contentScrollView.removeObserver(self, forKeyPath: XKeyPath)
        }
//        print(NSStringFromClass(self.classForCoder) + "deinit")
    }

    /// Delay setting the contentView
    /// - Parameters:
    ///   - scrollView: content scrollView
    ///   - index: Index of content view, eg: horizontal position from left to right
    @objc open func addContentScrollView(_ scrollView: UIScrollView, withIndex index: Int) {
        let p = scrollView.property
        p.canScroll = !mainScrollView.property.canScroll
        p.markScroll = true
        p.index = index
        p.scrollManager = self
        p.needShowsVerticalScrollIndicator = showIndicatorType != .none
        if contentSuperScrollView == nil {
            hasGetContentSuper = false
        }
        scrollView.addObserver(self, forKeyPath: XKeyPath, options: .new, context: nil)
        contentScrollViews.append(scrollView)
        checkScrollsToTop()
    }

    /// Set IndicatorType for a content view, It only works when enableCustomConfig is true
    @objc open func setShowIndicatorType(_ showIndicatorType: XShowIndicatorType, contentScrollView: UIScrollView) {
        if !contentScrollViews.contains(contentScrollView) {
            return
        }
        indicatorTypeDic[contentScrollView.property.index] = showIndicatorType
    }

    /// Set PullType for a content view, It only works when enableCustomConfig is true
    @objc open func setScrollPullType(_ pullType: XMixScrollPullType, contentScrollView: UIScrollView) {
        if !contentScrollViews.contains(contentScrollView) {
            return
        }
        pullTypeDic[contentScrollView.property.index] = pullType
    }

    /// Set Whether Scrolls To Main Top for a content view, It only works when enableCustomConfig is true
    @objc open func setScrollsToMainTop(_ scrollsToMainTop: Bool, contentScrollView: UIScrollView) {
        if !contentScrollViews.contains(contentScrollView) {
            return
        }
        scrollsToMainTopDic[contentScrollView.property.index] = scrollsToMainTop
    }

    /// Set Whether setEnableDynamicSimulate for a content view, It only works when enableCustomConfig is true
    @objc open func setEnableDynamicSimulate(_ EnableDynamicSimulate: Bool, contentScrollView: UIScrollView) {
        if !contentScrollViews.contains(contentScrollView) {
            return
        }
        enableDynamicDic[contentScrollView.property.index] = EnableDynamicSimulate
    }

    // MARK: -

    private var _mixScrollPullType: XMixScrollPullType = .main
    private var _scrollsToMainTop = true
    private var _enableDynamicSimulate = false

    @objc public private(set) var mainScrollView = UIScrollView()
    @objc public private(set) var contentScrollViews = [UIScrollView]()

    /// 是否已获取到contentSuperScrollView
    private var hasGetContentSuper = false
    /// 内容视图的横向scrollView父视图
    private var contentSuperScrollView: UIScrollView?
    /// 是否touch在主视图里 内容视图之外
    fileprivate var isTouchMain = false

    /// 动态模拟
    fileprivate lazy var dynamicSimulate: XDynamicSimulate = {
        let dynamicSimulate = XDynamicSimulate()
        dynamicSimulate.delegate = self
        dynamicSimulate.resistance = self.dynamicResistance
        return dynamicSimulate
    }()

    /// 当前模拟中的contentScrollView index
    private var currentSimulateIndex = 0
    /// 当前展示的contentScrollView index
    private var currentIndex = 0
    /// Ignore it,  not important
    /// 一般用不着  动态模拟判断时 不判断坐标点
    open var useAll = false

    // 单独设置属性相关
    private var indicatorTypeDic = [Int: XShowIndicatorType]()
    private var pullTypeDic = [Int: XMixScrollPullType]()
    private var scrollsToMainTopDic = [Int: Bool]()
    private var enableDynamicDic = [Int: Bool]()
}

// MARK: - XMixScrollManager privite func

private extension XMixScrollManager {
    /// 校准scrollsToTop
    func checkScrollsToTop() {
        if scrollsToMainTop || contentSuperScrollView == nil {
            mainScrollView.scrollsToTop = true
            return
        }
        let index = contentSuperScrollView!.property.index
        if contentScrollViews.count > index {
            let contentScrollView = contentScrollViews[index]
            mainScrollView.scrollsToTop = !mainScrollView.scrollsToTop
            contentScrollView.scrollsToTop = !mainScrollView.scrollsToTop
            contentScrollView.property.canScroll = !mainScrollView.property.canScroll
        } else {
            mainScrollView.scrollsToTop = true
        }
    }

    /// 切换 独立属性更新进度条状态
    func checkCustomConfig() {
        if !enableCustomConfig {
            return
        }
        let indicatorType = indicatorTypeDic[currentIndex] ?? showIndicatorType
        mainScrollView.property.needShowsVerticalScrollIndicator = indicatorType == .autoChange
        if mainScrollView.property.canScroll {
            mainScrollView.showsVerticalScrollIndicator = mainScrollView.property.needShowsVerticalScrollIndicator
        }
    }

    /// check scrollsToTop status
    func changeMainScrollStatus(canScroll: Bool) {
        if mainScrollView.property.canScroll == canScroll {
            return
        }
        mainScrollView.scrollsToTop = true
        mainScrollView.property.canScroll = canScroll
        for contentScrollView in contentScrollViews {
            contentScrollView.property.canScroll = !canScroll
            if canScroll {
                contentScrollView.resetContentOffset()
            }
            if !scrollsToMainTop {
                contentScrollView.scrollsToTop = !canScroll
            }
        }
    }

    /// 获取子scrollView的父scrollView
    func checkContentSuperScrollView() {
        if hasGetContentSuper {
            return
        }
        hasGetContentSuper = true
        var scrollView = contentScrollViews.first!.superview!
        while !scrollView.isKind(of: UIScrollView.self) {
            if let s = scrollView.superview {
                scrollView = s
            } else {
                return
            }
        }
        contentSuperScrollView = scrollView as? UIScrollView
        contentSuperScrollView?.addObserver(self, forKeyPath: XKeyPath, options: .new, context: nil)
    }
}

// MARK: - 动态模拟 delegate

extension XMixScrollManager: XDynamicSimulateDelegate {
    func willMoveY(_ movey: CGFloat) {
        handleWithMoveY(movey: -movey)
    }

    func handleWithMoveY(movey: CGFloat) {
        let distancey = contentScrollDistance - mainScrollView.contentOffset.y
        let d = distancey - movey
        if d > 0, distancey > 0 {
        } else {
            let contentScrollView = contentScrollViews[currentSimulateIndex]
            var subContentOffset = contentScrollView.contentOffset
            let max = contentScrollView.contentSize.height - contentScrollView.frame.size.height
            if contentScrollView.contentOffset.y == max {
                return
            }
            subContentOffset.y += -d
            if subContentOffset.y > max {
                subContentOffset.y = max
            }
            contentScrollView.contentOffset = subContentOffset
            mainScrollView.contentOffset = CGPoint(x: 0, y: contentScrollDistance)
        }
    }
}

// MARK: - XMixScrollManager srollView observer

extension XMixScrollManager {
    override open func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        guard keyPath == XKeyPath, contentScrollDistance != XMixScrollUndefinedValue else {
            return
        }
        let scrollView = object as! UIScrollView
        if !scrollView.property.markScroll {
            // 横向父scrollView滑动处理
            let index = Int(scrollView.contentOffset.x / scrollView.frame.size.width)
            if scrollView.property.index != index {
                scrollView.property.index = index
                currentIndex = index
                checkScrollsToTop()
                checkCustomConfig()
            }
            return
        }
        let offsetY = scrollView.contentOffset.y
        if scrollView.property.isMain {
            if !scrollView.property.canScroll {
                // 特殊情况手动归位时
                if offsetY == 0, contentScrollDistance != 0 {
                    changeMainScrollStatus(canScroll: true)
                    return
                }
                // content scroll滑动时 固定main scroll
                if offsetY != contentScrollDistance {
                    // 点击状态栏触发scrollsToTop事件
                    if !scrollView.isDragging {
                        changeMainScrollStatus(canScroll: true)
                        return
                    }
                    scrollView.contentOffset = CGPoint(x: 0, y: contentScrollDistance)
                }
                return
            }
            if enableDynamicSimulate, isTouchMain {
                if scrollView.panGestureRecognizer.state == .ended || scrollView.panGestureRecognizer.state == .changed {
                    let velocity = scrollView.panGestureRecognizer.velocity(in: scrollView)
                    if velocity.y < 0, contentScrollViews.count > currentIndex {
                        currentSimulateIndex = currentIndex
                        dynamicSimulate.simulateWithVelocityY(velocity.y)
                    }
                }
            }
            // 超出范围content scroll 接手
            if offsetY > contentScrollDistance || contentScrollDistance == 0 {
                var needMainScroll = false
                if contentScrollViews.count == 0 {
                    needMainScroll = true
                } else {
                    if contentScrollViews.count == 1 {
                        let contentScrollView = contentScrollViews.first!
                        needMainScroll = contentScrollView.contentSize.height <= contentScrollView.frame.size.height
                    }
                }
                changeMainScrollStatus(canScroll: needMainScroll)
                scrollView.contentOffset = CGPoint(x: 0, y: contentScrollDistance)
            }

            // 是否允许下拉判断
            if offsetY < 0 {
                if mixScrollPullType == .none || mixScrollPullType == .sub {
                    scrollView.resetContentOffset()
                }
            }
        } else {
            checkContentSuperScrollView()
            if !scrollView.property.canScroll {
                // main scroll滑动时 固定content scroll
                if offsetY > 0 {
                    if !scrollView.isDragging {
                        mainScrollView.scrollsToTop = true
                        return
                    }
                    scrollView.resetContentOffset()
                } else if offsetY < 0 {
                    if mainScrollView.contentOffset.y > 0 {
                        scrollView.resetContentOffset()
                    } else {
                        // 是否允许下拉判断
                        if mixScrollPullType == .none || mixScrollPullType == .main {
                            scrollView.resetContentOffset()
                        }
                    }
                }
                return
            }
            // 超出范围main scroll 接手
            if offsetY < 0 {
                scrollView.resetContentOffset()
                changeMainScrollStatus(canScroll: true)
            } else if offsetY == 0 {
                if let superView = contentSuperScrollView, superView.property.index != scrollView.property.index {
                    // 非当前contentScrollView无需处理
                } else {
                    changeMainScrollStatus(canScroll: true)
                }
            } else {
                if !scrollsToMainTop {
                    if let superView = contentSuperScrollView, superView.property.index == scrollView.property.index {
                        mainScrollView.scrollsToTop = false
                        scrollView.scrollsToTop = true
                    }
                }
            }
        }
    }
}

private class XScrollViewProperty {
    var isMain = false
    var canScroll = false {
        didSet {
            if needShowsVerticalScrollIndicator {
                if canScroll {
                    if !scrollView.isTracking, scrollManager.enableDynamicSimulate {
                        scrollView.flashScrollIndicators()
                    }
                }
                scrollView.showsVerticalScrollIndicator = canScroll
            } else {
                scrollView.showsVerticalScrollIndicator = false
            }
        }
    }

    var needShowsVerticalScrollIndicator = false
    var markScroll = false
    var index = 0
    weak var scrollView: UIScrollView!
    weak var scrollManager: XMixScrollManager!
}

// MARK: - UIScrollView category

private var kXScrollViewPropertyKey: UInt8 = 0
extension UIScrollView: UIGestureRecognizerDelegate {
    fileprivate var property: XScrollViewProperty {
        var p = (objc_getAssociatedObject(self, &kXScrollViewPropertyKey) as? XScrollViewProperty)
        if p == nil {
            p = XScrollViewProperty()
            objc_setAssociatedObject(self, &kXScrollViewPropertyKey, p, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
            p!.scrollView = self
        }
        return p!
    }

    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if property.markScroll {
            if let scrollView = otherGestureRecognizer.view as? UIScrollView, scrollView.property.markScroll {
                return true
            }
        }
        return false
    }

    func resetContentOffset() {
        contentOffset = .zero
    }

    override open func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        if let scrollManager = property.scrollManager {
            if scrollManager.enableDynamicSimulate {
                scrollManager.dynamicSimulate.stop()
            }
            if property.isMain {
                if scrollManager.useAll {
                    scrollManager.isTouchMain = point.y > 0
                } else {
                    if scrollManager.mainTopHeight > 0, scrollManager.contentScrollDistance > 0 {
                        scrollManager.isTouchMain = point.y < scrollManager.mainTopHeight
                    } else {
                        scrollManager.isTouchMain = point.y < scrollManager.contentScrollDistance
                    }
                }
            }
        }
        return super.point(inside: point, with: event)
    }
}

// MARK: - Dynamic Simulate 动态模拟

private protocol XDynamicSimulateDelegate: NSObjectProtocol {
    func willMoveY(_ movey: CGFloat)
}

private class XDynamicItem: NSObject, UIDynamicItem {
    var transform: CGAffineTransform = .identity
    lazy var bounds = {
        CGRect(x: 0, y: 0, width: 1, height: 1)
    }()

    var center: CGPoint = .zero
}

private class XDynamicSimulate: NSObject {
    open var resistance: Float = 2
    fileprivate weak var delegate: XDynamicSimulateDelegate?
    private var view: UIView!
    private var animator: UIDynamicAnimator!
    private var dynamicItem: XDynamicItem!

    override init() {
        super.init()
        view = UIView()
        dynamicItem = XDynamicItem()
        animator = UIDynamicAnimator(referenceView: view)
    }

    fileprivate func simulateWithVelocityY(_ velocityY: CGFloat) {
        animator.removeAllBehaviors()
        dynamicItem.center = view.bounds.origin
        let inertialBehavior = UIDynamicItemBehavior(items: [dynamicItem])
        inertialBehavior.addLinearVelocity(CGPoint(x: 0, y: velocityY), for: dynamicItem)
        inertialBehavior.resistance = CGFloat(resistance)
        var lastCenterY: CGFloat = 0
        inertialBehavior.action = { [weak self] in
            guard let self = self else {
                return
            }
            let currentY = self.dynamicItem.center.y - lastCenterY
            self.willMoveY(currentY)
            lastCenterY = self.dynamicItem.center.y
        }
        animator.addBehavior(inertialBehavior)
    }

    fileprivate func stop() {
        animator.removeAllBehaviors()
    }

    private func willMoveY(_ movey: CGFloat) {
        let height: CGFloat = UIScreen.main.bounds.height
        delegate?.willMoveY(rubberBandDistance(offset: movey, dimension: height))
    }

    /* f(x, d, c) = (x * d * c) / (d + c * x)
     where,
     x – distance from the edge
     c – constant (UIScrollView uses 0.55)
     d – dimension, either width or height */
    private func rubberBandDistance(offset: CGFloat, dimension: CGFloat) -> CGFloat {
        let constant: CGFloat = 0.55
        let absOffset = abs(offset)
        var result: CGFloat = (constant * absOffset * dimension) / (dimension + constant * absOffset)
        result = offset < 0 ? -result : result
        return result
    }
}
