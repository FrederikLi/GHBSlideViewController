Slide ViewController for Objective-C
======================================

This SlideViewController is used for Slide-menus (or Navigation Drawer). 
It has a custom scale animation for the 'menu' viewController

Configuration
-------------

Make sure you include the 'QuartzCore.framework'. Go to your target, and add it by pressing the '+' icon in the 'Linked Frameworks and Libraries' section.
The `LeftViewController` fades out when the `MainViewController` slides in, to prevent different alpha values of subviews, set `UIViewGroupOpacity` to `YES` in the `AppName-Info.plist` file.

Usage
-------------
Add this code and you're all done.
```objective-c
UIViewController *leftViewController = [[UIViewController alloc] init];
UIViewController *mainViewController = [[UIViewController alloc] init];

GHBSlideViewController *slideViewController = [[GHBSlideViewController alloc] initWithLeftViewController:leftViewController
                                                                    mainViewController:mainViewController];
```

If you want to reveal the `LeftViewController`, you can use the following code:
```objective-c
GHBSlideViewController *slideViewController = (GHBSlideViewController *)self.navigationController.parentViewController;
[slideViewController toggleSlideViewController:^(BOOL completed){
    // done sliding
}];

```


Documentation
-------------
Class doc's aren't complete, coming soon!