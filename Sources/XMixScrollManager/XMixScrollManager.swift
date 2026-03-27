//
//  XMixScrollManager.swift
//  XMixScrollManager_swift
//
//  Created by xing on 2021/4/12.
//

import UIKit

// MARK: - Constants

private let XMixScrollUndefinedValue: CGFloat = -999

// MARK: - Enums

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

// MARK: - Protocols

private protocol XDynamicSimulateDelegate: AnyObject {
    func willMoveY(_ movey: CGFloat)
}

// MARK: - Main Class

open class XMixScrollManager: NSObject {
    // MARK: - Public Properties

    /// The movable distance of contentScrollView, generally the relative coordinate Y in mainScrollView, the default XMixScrollUndefinedValue, takes effect immediately, dynamic simulation will not take effect before assigning a valid value
    private var _contentScrollDistance: CGFloat = XMixScrollUndefinedValue

    @objc open var contentScrollDistance: CGFloat {
        get { _contentScrollDistance }
        set { _contentScrollDistance = ceil(newValue) }
    }

    /// The default main can be pulled down
    @objc open var mixScrollPullType: XMixScrollPullType {
        set { _mixScrollPullType = newValue }
        get {
            return enableCustomConfig ? (pullTypeDic[currentIndex] ?? _mixScrollPullType) : _mixScrollPullType
        }
    }

    /// Scroll bar display, automatically switch the display by default
    @objc open var showIndicatorType: XShowIndicatorType = .autoChange {
        didSet {
            mainScrollView.scrollViewProperty.needShowsVerticalScrollIndicator = showIndicatorType == .autoChange
            mainScrollView.showsVerticalScrollIndicator = mainScrollView.scrollViewProperty.needShowsVerticalScrollIndicator
            contentScrollViews.forEach { $0.scrollViewProperty.needShowsVerticalScrollIndicator = showIndicatorType != .none }
        }
    }

    /// Whether to return directly to the top of the mainScrollView when clicking the status bar back to the top
    @objc open var scrollsToMainTop: Bool {
        set { _scrollsToMainTop = newValue }
        get {
            return enableCustomConfig ? (scrollsToMainTopDic[currentIndex] ?? _scrollsToMainTop) : _scrollsToMainTop
        }
    }

    /// Whether to enable dynamic simulation, default NO, in the main scope outside the content scope, pull up has not transition sliding effect, YES, add simulation continuous sliding effect
    @objc open var enableDynamicSimulate: Bool {
        set { _enableDynamicSimulate = newValue }
        get {
            return enableCustomConfig ? (enableDynamicDic[currentIndex] ?? _enableDynamicSimulate) : _enableDynamicSimulate
        }
    }

    /// Rolling resistance, default 2
    @objc open var dynamicResistance: CGFloat = 2 {
        didSet {
            _dynamicSimulate?.resistance = dynamicResistance
        }
    }

    /// Enable independent property setting, default NO
    @objc open var enableCustomConfig = false

    /// The upper height of the main ScrollView, which is used to determine whether dynamic simulation is in the range to be enabled. contentScrollDistance is used by default
    @objc open var mainTopHeight: CGFloat = XMixScrollUndefinedValue

    /// Whether to use all area for touch detection
    @objc open var useAll = false

    // MARK: - Public Read-Only Properties

    @objc public private(set) var mainScrollView = UIScrollView()
    @objc public private(set) var contentScrollViews = [UIScrollView]()

    // MARK: - Public Methods

    /// Method of initialization
    /// - Parameters:
    ///   - scrollView: Main scroll view
    ///   - contentScrollViews: contentScrollViews
    @objc public init(scrollView: UIScrollView, contentScrollViews: [UIScrollView]?) {
        super.init()

        setupMainScrollView(scrollView)

        if let scrollViews = contentScrollViews {
            scrollViews.enumerated().forEach { index, scrollView in
                addContentScrollView(scrollView, withIndex: index)
            }
        }

        showIndicatorType = .autoChange
    }

    deinit {
        mainScrollView.scrollViewProperty.observation = nil
        mainScrollView.scrollViewProperty.markScroll = false
        mainScrollView.scrollViewProperty.isMain = false
        removeTouchObserver(from: mainScrollView)

        for scrollView in contentScrollViews {
            scrollView.scrollViewProperty.observation = nil
            scrollView.scrollViewProperty.markScroll = false
            scrollView.scrollViewProperty.scrollManager = nil
            removeTouchObserver(from: scrollView)
        }

        contentSuperObservation = nil
        _dynamicSimulate?.stop()
    }

    /// Delay setting the contentView
    /// - Parameters:
    ///   - scrollView: content scrollView
    ///   - index: Index of content view, eg: horizontal position from left to right
    @objc open func addContentScrollView(_ scrollView: UIScrollView, withIndex index: Int) {
        let p = scrollView.scrollViewProperty
        p.canScroll = !mainScrollView.scrollViewProperty.canScroll
        p.markScroll = true
        p.index = index
        p.scrollManager = self
        p.needShowsVerticalScrollIndicator = showIndicatorType != .none

        if contentSuperScrollView == nil {
            hasGetContentSuper = false
        }

        addObservation(for: scrollView)
        addTouchObserver(to: scrollView, isMain: false)
        contentScrollViews.append(scrollView)
        checkScrollsToTop()
    }

    /// Remove a content scrollView
    /// - Parameter scrollView: content scrollView to remove
    @objc open func removeContentScrollView(_ scrollView: UIScrollView) {
        scrollView.scrollViewProperty.observation = nil
        scrollView.scrollViewProperty.markScroll = false
        scrollView.scrollViewProperty.scrollManager = nil
        removeTouchObserver(from: scrollView)
        contentScrollViews.removeAll { $0 === scrollView }
        checkScrollsToTop()
    }

    /// Set IndicatorType for a content view, It only works when enableCustomConfig is true
    @objc open func setShowIndicatorType(_ showIndicatorType: XShowIndicatorType, contentScrollView: UIScrollView) {
        let idx = contentScrollView.scrollViewProperty.index
        guard idx < contentScrollViews.count, contentScrollViews[idx] === contentScrollView else { return }
        indicatorTypeDic[idx] = showIndicatorType
    }

    /// Set PullType for a content view, It only works when enableCustomConfig is true
    @objc open func setScrollPullType(_ pullType: XMixScrollPullType, contentScrollView: UIScrollView) {
        let idx = contentScrollView.scrollViewProperty.index
        guard idx < contentScrollViews.count, contentScrollViews[idx] === contentScrollView else { return }
        pullTypeDic[idx] = pullType
    }

    /// Set Whether Scrolls To Main Top for a content view, It only works when enableCustomConfig is true
    @objc open func setScrollsToMainTop(_ scrollsToMainTop: Bool, contentScrollView: UIScrollView) {
        let idx = contentScrollView.scrollViewProperty.index
        guard idx < contentScrollViews.count, contentScrollViews[idx] === contentScrollView else { return }
        scrollsToMainTopDic[idx] = scrollsToMainTop
    }

    /// Set Whether setEnableDynamicSimulate for a content view, It only works when enableCustomConfig is true
    @objc open func setEnableDynamicSimulate(_ enableDynamicSimulate: Bool, contentScrollView: UIScrollView) {
        let idx = contentScrollView.scrollViewProperty.index
        guard idx < contentScrollViews.count, contentScrollViews[idx] === contentScrollView else { return }
        enableDynamicDic[idx] = enableDynamicSimulate
    }

    // MARK: - Private Properties

    private var _mixScrollPullType: XMixScrollPullType = .main
    private var _scrollsToMainTop = true
    private var _enableDynamicSimulate = false

    /// Whether contentSuperScrollView has been retrieved
    private var hasGetContentSuper = false
    /// The horizontal scrollView parent of content views
    private var contentSuperScrollView: UIScrollView?
    /// Whether touch is in the main view area, outside content views
    private var isTouchMain = false

    /// Dynamic simulation
    private var _dynamicSimulate: XDynamicSimulate?
    private var dynamicSimulate: XDynamicSimulate {
        if let simulate = _dynamicSimulate {
            return simulate
        }
        let simulate = XDynamicSimulate()
        simulate.delegate = self
        simulate.resistance = dynamicResistance
        _dynamicSimulate = simulate
        return simulate
    }

    /// Current simulating contentScrollView index
    private var currentSimulateIndex = 0
    /// Current displayed contentScrollView index
    private var currentIndex = 0

    /// Individual property settings
    private var indicatorTypeDic = [Int: XShowIndicatorType]()
    private var pullTypeDic = [Int: XMixScrollPullType]()
    private var scrollsToMainTopDic = [Int: Bool]()
    private var enableDynamicDic = [Int: Bool]()

    /// Block-based KVO observation for contentSuperScrollView
    private var contentSuperObservation: NSKeyValueObservation?
}

// MARK: - Setup & Observation

private extension XMixScrollManager {
    func setupMainScrollView(_ scrollView: UIScrollView) {
        let p = scrollView.scrollViewProperty
        p.isMain = true
        p.canScroll = true
        p.markScroll = true
        p.scrollManager = self
        addObservation(for: scrollView)
        addTouchObserver(to: scrollView, isMain: true)
        mainScrollView = scrollView
    }

    func addObservation(for scrollView: UIScrollView) {
        let p = scrollView.scrollViewProperty
        guard p.observation == nil else { return }

        p.observation = scrollView.observe(\.contentOffset, options: .new) { [weak self, weak scrollView] _, _ in
            guard let self, let scrollView, self.contentScrollDistance != XMixScrollUndefinedValue else { return }
            if scrollView.scrollViewProperty.isMain {
                self.handleMainScroll(scrollView, offsetY: scrollView.contentOffset.y)
            } else {
                self.handleContentScroll(scrollView, offsetY: scrollView.contentOffset.y)
            }
        }
    }

    func observeContentSuperScrollView(_ scrollView: UIScrollView) {
        guard contentSuperObservation == nil else { return }
        contentSuperObservation = scrollView.observe(\.contentOffset, options: .new) { [weak self, weak scrollView] _, _ in
            guard let self, let scrollView else { return }
            self.handleHorizontalScroll(scrollView)
        }
    }

    // MARK: - Touch Observer

    func addTouchObserver(to scrollView: UIScrollView, isMain: Bool) {
        let p = scrollView.scrollViewProperty
        guard p.touchObserver == nil else { return }

        let observer = XTouchObserverGesture()
        observer.cancelsTouchesInView = false
        observer.delaysTouchesBegan = false

        observer.onTouchBegan = { [weak self] point in
            guard let self else { return }
            if self.enableDynamicSimulate {
                self._dynamicSimulate?.stop()
            }
            if isMain {
                if self.useAll {
                    self.isTouchMain = point.y > 0
                } else if self.mainTopHeight > 0, self.contentScrollDistance > 0 {
                    self.isTouchMain = point.y < self.mainTopHeight
                } else {
                    self.isTouchMain = point.y < self.contentScrollDistance
                }
            }
        }

        scrollView.addGestureRecognizer(observer)
        p.touchObserver = observer
    }

    func removeTouchObserver(from scrollView: UIScrollView) {
        if let observer = scrollView.scrollViewProperty.touchObserver {
            scrollView.removeGestureRecognizer(observer)
        }
        scrollView.scrollViewProperty.touchObserver = nil
    }
}

// MARK: - Scroll Status Management

private extension XMixScrollManager {
    /// Check scrollsToTop status
    func checkScrollsToTop() {
        if scrollsToMainTop || contentSuperScrollView == nil {
            mainScrollView.scrollsToTop = true
            return
        }

        guard let superScrollView = contentSuperScrollView else { return }
        let index = superScrollView.scrollViewProperty.index
        guard contentScrollViews.count > index else {
            mainScrollView.scrollsToTop = true
            return
        }

        let contentScrollView = contentScrollViews[index]
        mainScrollView.scrollsToTop = false
        contentScrollView.scrollsToTop = true
        contentScrollView.scrollViewProperty.canScroll = !mainScrollView.scrollViewProperty.canScroll
    }

    /// Update indicator state when custom config changes
    func checkCustomConfig() {
        guard enableCustomConfig else { return }

        let indicatorType = indicatorTypeDic[currentIndex] ?? showIndicatorType
        mainScrollView.scrollViewProperty.needShowsVerticalScrollIndicator = indicatorType == .autoChange

        if mainScrollView.scrollViewProperty.canScroll {
            mainScrollView.showsVerticalScrollIndicator = mainScrollView.scrollViewProperty.needShowsVerticalScrollIndicator
        }
    }

    /// Toggle main scroll view scrollability
    func changeMainScrollStatus(canScroll: Bool) {
        guard mainScrollView.scrollViewProperty.canScroll != canScroll else { return }

        mainScrollView.scrollViewProperty.canScroll = canScroll
        mainScrollView.scrollsToTop = true
        updateScrollIndicatorState(for: mainScrollView)

        contentScrollViews.forEach { scrollView in
            scrollView.scrollViewProperty.canScroll = !canScroll
            updateScrollIndicatorState(for: scrollView)
            if canScroll {
                scrollView.resetContentOffset()
            }
            if !scrollsToMainTop {
                scrollView.scrollsToTop = !canScroll
            }
        }
    }

    /// Update scroll indicator visibility based on current state
    func updateScrollIndicatorState(for scrollView: UIScrollView) {
        let p = scrollView.scrollViewProperty
        if p.needShowsVerticalScrollIndicator {
            scrollView.showsVerticalScrollIndicator = p.canScroll
            if p.canScroll, !scrollView.isTracking, enableDynamicSimulate {
                scrollView.flashScrollIndicators()
            }
        } else {
            scrollView.showsVerticalScrollIndicator = false
        }
    }

    /// Retrieve the parent horizontal scrollView of content scroll views
    func checkContentSuperScrollView() {
        guard !hasGetContentSuper, !contentScrollViews.isEmpty else { return }

        hasGetContentSuper = true
        guard let firstScrollView = contentScrollViews.first, var scrollView = firstScrollView.superview else { return }

        while !scrollView.isKind(of: UIScrollView.self) {
            guard let superview = scrollView.superview else { return }
            scrollView = superview
        }

        guard let superScrollView = scrollView as? UIScrollView else { return }
        contentSuperScrollView = superScrollView
        observeContentSuperScrollView(superScrollView)
    }
}

// MARK: - Scroll Handling

private extension XMixScrollManager {
    func handleHorizontalScroll(_ scrollView: UIScrollView) {
        guard scrollView.frame.size.width > 0 else { return }
        let index = Int(scrollView.contentOffset.x / scrollView.frame.size.width)
        guard index >= 0 else { return }
        if scrollView.scrollViewProperty.index != index {
            scrollView.scrollViewProperty.index = index
            currentIndex = index
            checkScrollsToTop()
            checkCustomConfig()
        }
    }

    func handleMainScroll(_ scrollView: UIScrollView, offsetY: CGFloat) {
        if !scrollView.scrollViewProperty.canScroll {
            handleMainScrollWhenCannotScroll(scrollView, offsetY: offsetY)
            return
        }

        if enableDynamicSimulate, isTouchMain {
            handleDynamicSimulation(scrollView)
        }

        if offsetY > contentScrollDistance || contentScrollDistance == 0 {
            handleMainScrollRange(scrollView, offsetY: offsetY)
        }

        if offsetY < 0 {
            handleMainScrollPull(scrollView)
        }
    }

    func handleMainScrollWhenCannotScroll(_ scrollView: UIScrollView, offsetY: CGFloat) {
        if offsetY == 0, contentScrollDistance != 0 {
            changeMainScrollStatus(canScroll: true)
            return
        }

        if offsetY != contentScrollDistance {
            if !scrollView.isDragging {
                changeMainScrollStatus(canScroll: true)
                return
            }
            scrollView.contentOffset = CGPoint(x: 0, y: contentScrollDistance)
        }
    }

    func handleDynamicSimulation(_ scrollView: UIScrollView) {
        let state = scrollView.panGestureRecognizer.state
        if state == .ended || state == .changed {
            let velocity = scrollView.panGestureRecognizer.velocity(in: scrollView)
            if velocity.y < 0, contentScrollViews.count > currentIndex {
                currentSimulateIndex = currentIndex
                dynamicSimulate.simulateWithVelocityY(velocity.y, dimension: Self.screenHeight(for: scrollView))
            }
        }
    }

    private static func screenHeight(for view: UIView) -> CGFloat {
        if #available(iOS 13.0, *), let windowScene = view.window?.windowScene {
            return windowScene.screen.bounds.height
        }
        return UIScreen.main.bounds.height
    }

    func handleMainScrollRange(_ scrollView: UIScrollView, offsetY: CGFloat) {
        guard !contentScrollViews.isEmpty else {
            changeMainScrollStatus(canScroll: true)
            scrollView.contentOffset = CGPoint(x: 0, y: contentScrollDistance)
            return
        }

        guard currentIndex < contentScrollViews.count else { return }
        let contentScrollView = contentScrollViews[currentIndex]
        let needMainScroll = contentScrollView.contentSize.height <= contentScrollView.frame.size.height

        changeMainScrollStatus(canScroll: needMainScroll)
        scrollView.contentOffset = CGPoint(x: 0, y: contentScrollDistance)
    }

    func handleMainScrollPull(_ scrollView: UIScrollView) {
        if mixScrollPullType == .none || mixScrollPullType == .sub {
            scrollView.resetContentOffset()
        }
    }

    func handleContentScroll(_ scrollView: UIScrollView, offsetY: CGFloat) {
        checkContentSuperScrollView()

        if !scrollView.scrollViewProperty.canScroll {
            handleContentScrollWhenCannotScroll(scrollView, offsetY: offsetY)
            return
        }

        handleContentScrollRange(scrollView, offsetY: offsetY)
        handleContentScrollToTop(scrollView)
    }

    func handleContentScrollWhenCannotScroll(_ scrollView: UIScrollView, offsetY: CGFloat) {
        if offsetY > 0 {
            if !scrollView.isDragging {
                mainScrollView.scrollsToTop = true
                return
            }
            scrollView.resetContentOffset()
        } else if offsetY < 0 {
            if mainScrollView.contentOffset.y > 0 {
                scrollView.resetContentOffset()
            } else if mixScrollPullType == .none || mixScrollPullType == .main {
                scrollView.resetContentOffset()
            }
        }
    }

    func handleContentScrollRange(_ scrollView: UIScrollView, offsetY: CGFloat) {
        if offsetY < 0 {
            scrollView.resetContentOffset()
            changeMainScrollStatus(canScroll: true)
        } else if offsetY == 0 {
            if let superView = contentSuperScrollView, superView.scrollViewProperty.index != scrollView.scrollViewProperty.index {
                // Non-current contentScrollView, no processing needed
            } else {
                changeMainScrollStatus(canScroll: true)
            }
        }
    }

    func handleContentScrollToTop(_ scrollView: UIScrollView) {
        if !scrollsToMainTop {
            if let superView = contentSuperScrollView, superView.scrollViewProperty.index == scrollView.scrollViewProperty.index {
                mainScrollView.scrollsToTop = false
                scrollView.scrollsToTop = true
            }
        }
    }
}

// MARK: - XDynamicSimulateDelegate

extension XMixScrollManager: XDynamicSimulateDelegate {
    func willMoveY(_ movey: CGFloat) {
        handleWithMoveY(movey: -movey)
    }

    private func handleWithMoveY(movey: CGFloat) {
        guard contentScrollDistance != XMixScrollUndefinedValue else { return }

        let distancey = contentScrollDistance - mainScrollView.contentOffset.y
        let d = distancey - movey

        guard d <= 0 || distancey <= 0 else { return }

        guard contentScrollViews.count > currentSimulateIndex else { return }
        let contentScrollView = contentScrollViews[currentSimulateIndex]

        let maxOffset = max(0, contentScrollView.contentSize.height - contentScrollView.frame.size.height)
        guard contentScrollView.contentOffset.y < maxOffset else { return }

        var subContentOffset = contentScrollView.contentOffset
        subContentOffset.y += -d
        subContentOffset.y = min(subContentOffset.y, maxOffset)
        subContentOffset.y = max(0, subContentOffset.y)

        contentScrollView.contentOffset = subContentOffset
        mainScrollView.contentOffset = CGPoint(x: 0, y: contentScrollDistance)
    }
}

// MARK: - XScrollViewProperty

private class XScrollViewProperty {
    var isMain = false
    var canScroll = false
    var needShowsVerticalScrollIndicator = false
    var markScroll = false
    var index = 0
    weak var scrollManager: XMixScrollManager?

    /// Block-based KVO observation token (auto-removed when nilled)
    var observation: NSKeyValueObservation?

    /// Touch observer gesture recognizer reference
    var touchObserver: XTouchObserverGesture?
}

// MARK: - UIScrollView Extension

private var kXScrollViewPropertyKey: UInt8 = 0

extension UIScrollView: UIGestureRecognizerDelegate {
    fileprivate var scrollViewProperty: XScrollViewProperty {
        if let p = objc_getAssociatedObject(self, &kXScrollViewPropertyKey) as? XScrollViewProperty {
            return p
        }

        let p = XScrollViewProperty()
        objc_setAssociatedObject(self, &kXScrollViewPropertyKey, p, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
        return p
    }

    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        guard scrollViewProperty.markScroll else { return false }

        if let otherScrollView = otherGestureRecognizer.view as? UIScrollView, otherScrollView.scrollViewProperty.markScroll {
            return true
        }

        return false
    }

    func resetContentOffset() {
        contentOffset = .zero
    }
}

// MARK: - Touch Observer Gesture

/// Passive gesture recognizer that observes touch events without consuming them.
/// Replaces the global point(inside:with:) swizzling approach — only affects managed scroll views.
private class XTouchObserverGesture: UIGestureRecognizer {
    var onTouchBegan: ((CGPoint) -> Void)?

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesBegan(touches, with: event)
        if let touch = touches.first, let view {
            let point = touch.location(in: view)
            onTouchBegan?(point)
        }
        // Fail immediately — we only observe, never recognize
        state = .failed
    }
}

// MARK: - Dynamic Simulate

private class XDynamicItem: NSObject, UIDynamicItem {
    var transform: CGAffineTransform = .identity
    var bounds: CGRect {
        return CGRect(x: 0, y: 0, width: 1, height: 1)
    }

    var center: CGPoint = .zero
}

private class XDynamicSimulate: NSObject {
    var resistance: CGFloat = 2
    fileprivate weak var delegate: XDynamicSimulateDelegate?
    private let view = UIView()
    private let dynamicItem = XDynamicItem()
    private lazy var animator = UIDynamicAnimator(referenceView: view)
    private var dimension: CGFloat = 0

    fileprivate func simulateWithVelocityY(_ velocityY: CGFloat, dimension: CGFloat) {
        self.dimension = dimension
        animator.removeAllBehaviors()
        dynamicItem.center = view.bounds.origin

        let inertialBehavior = UIDynamicItemBehavior(items: [dynamicItem])
        inertialBehavior.addLinearVelocity(CGPoint(x: 0, y: velocityY), for: dynamicItem)
        inertialBehavior.resistance = resistance
        inertialBehavior.angularResistance = 0

        var lastCenterY: CGFloat = 0
        inertialBehavior.action = { [weak self] in
            guard let self else { return }
            let currentY = self.dynamicItem.center.y - lastCenterY
            guard abs(currentY) > 0.1 else { return }
            self.willMoveY(currentY)
            lastCenterY = self.dynamicItem.center.y
        }

        animator.addBehavior(inertialBehavior)
    }

    fileprivate func stop() {
        animator.removeAllBehaviors()
    }

    private func willMoveY(_ movey: CGFloat) {
        delegate?.willMoveY(Self.rubberBandDistance(offset: movey, dimension: dimension))
    }

    /* f(x, d, c) = (x * d * c) / (d + c * x)
     where,
     x – distance from the edge
     c – constant (UIScrollView uses 0.55)
     d – dimension, either width or height */
    private static func rubberBandDistance(offset: CGFloat, dimension: CGFloat) -> CGFloat {
        let constant: CGFloat = 0.55
        let absOffset = abs(offset)
        let result = (constant * absOffset * dimension) / (dimension + constant * absOffset)
        return offset < 0 ? -result : result
    }
}
