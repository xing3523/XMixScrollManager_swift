# XMixScrollManager_swift

## 介绍
管理UIScrollView嵌套滑动的一个小组件Swift版。
通过KVO实现，无UI布局，低耦合。

Objective-C版本->[XMixScrollManager](https://github.com/xing3523/XMixScrollManager)

[简书相关文章](https://www.jianshu.com/p/146e42ec7dc8)
## 主要功能
- 支持滑动进度条可选择是否显示；
- 支持嵌套主次UIScrollView可选择是否允许下拉；
- 支持点击状态栏可选择主次UIScrollView回到顶部；
- 支持主次UIScrollView滑动过渡可选择惯性模拟移动。


## 使用方法
简单使用
``` 
scrollManager = XMixScrollManager(scrollView: scrollView, contentScrollViews: [contentScrollView1,contentScrollView2])
scrollManager.contentScrollDistance = CGFloat(300)
```

XMixScrollManager不关注UI布局，contentScrollDistance需要传入准确的值。
其他可选属性的使用可见demo。

## 部分效果图
![](https://github.com/xing3523/XMixScrollManager/raw/master/Images/效果图1.gif)
![](https://github.com/xing3523/XMixScrollManager/raw/master/Images/效果图2.gif)
## 安装

### CocoaPods

1. 在 Podfile 中添加 `pod 'XMixScrollManager_swift'`。
2. 执行 `pod install` 或 `pod update`。

### Swift Package Manager 安装
依次点击 Xcode 的菜单 File > Swift Packages > Add Package Dependency，填入 `https://github.com/xing3523/XMixScrollManager_swift`

## 系统要求
`iOS 9.0+`


## introduce
A widget Swift version that manages nested sliding of UIScrollView.
Implemented through KVO, no UI layout, low coupling.

## Main function
- Support sliding progress bar to choose whether to display or not;
- Support nested primary and secondary UIScrollView to choose whether to allow drop-down;
- Support clicking on the status bar to select the primary and secondary UIScrollView back to the top;
- Support primary and secondary UIScrollView sliding transition to select inertial simulation movement.


## How to use
Simple to use
``` 
scrollManager = XMixScrollManager(scrollView: scrollView, contentScrollViews: [contentScrollView1,contentScrollView2])
scrollManager.contentScrollDistance = CGFloat(300)
```

XMixScrollManager does not pay attention to UI layout, contentScrollDistance needs to pass in accurate values.
The use of other optional properties can be seen in the demo.

## Some renderings
![](https://github.com/xing3523/XMixScrollManager/raw/master/Images/效果图1.gif)
![](https://github.com/xing3523/XMixScrollManager/raw/master/Images/效果图2.gif)
## Install

### CocoaPods

1. Add `pod 'XMixScrollManager_swift'` to the Podfile.
2. Execute `pod install` or `pod update`.

### Swift Package Manager Installation
Click Xcode's menu File > Swift Packages > Add Package Dependency, fill in `https://github.com/xing3523/XMixScrollManager_swift`

## Requirements
`iOS 9.0+`
