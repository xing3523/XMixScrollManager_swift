# XMixScrollManager

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

## Install

### Swift Package Manager Installation
Click Xcode's menu File > Swift Packages > Add Package Dependency, fill in `https://github.com/xing3523/XMixScrollManager_swift`

## Requirements
`iOS 9.0+`

