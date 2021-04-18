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

## 系统要求
`iOS 9.0+`
