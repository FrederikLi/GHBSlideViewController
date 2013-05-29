Slide ViewController for Objective-C
======================================

This SlideViewController is used for Slide-menus (or Navigation Drawer). 
It has a custom scale animation for the 'menu' viewController

Configuration
-------------

Make sure you include the 'QuartzCore.framework'. Go to your target, and add it by pressing the '+' icon in the 'Linked Frameworks and Libraries' section.

Usage
-------------
Add this code and you're all done.
```objc
UIViewController *leftViewController = [[UIViewController alloc] init];
UIViewController *mainViewController = [[UIViewController alloc] init];

GHBSlideViewController *slideViewController = [[GHBSlideViewController alloc] initWithLeftViewController:leftViewController
                                                                    mainViewController:mainViewController];
```

If you want to reveal the `LeftViewController`, you can use the following code:
```objc
GHBSlideViewController *slideViewController = (GHBSlideViewController *)self.navigationController.parentViewController;
[slideViewController toggleSlideViewController:^(BOOL completed){
    // done sliding
}];

```


Documentation
-------------
Class doc's aren't complete, coming soon!