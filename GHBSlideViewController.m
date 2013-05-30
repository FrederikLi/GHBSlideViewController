/*
 Copyright (c) 2013, Gerhard Bos
 All rights reserved.
 
 Permission is hereby granted, free of charge, to any person
 obtaining a copy of this software and associated documentation
 files (the "Software"), to deal in the Software without
 restriction, including without limitation the rights to use,
 copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the
 Software is furnished to do so, subject to the following
 conditions:
 
 The above copyright notice and this permission notice shall be
 included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 OTHER DEALINGS IN THE SOFTWARE.
 */

/*
 * GHBSlideMenuController.m
 *
 * Created by Gerhard Bos on 29-05-13.
 * http://gerhard.nl
 * Copyright (c) 2013 Gerhard Bos. All rights reserved.
 */

#import "GHBSlideViewController.h"
#import <QuartzCore/QuartzCore.h>

#define MINIMUM_GESTURE_RANGE       50.0f
#define MINIMUM_ALPHA               .10f
#define MINIMUM_SCALE               .85f
#define ANIMATION_DURATION          .20f

#define SLIDE_MENU_WIDTH            260.0f
#define SLIDE_MENU_SHADOW           YES
#define SLIDE_MENU_SHADOW_RADIUS    2.5f
#define SLIDE_MENU_SHADOW_OPACITY   .5f

@interface GHBSlideViewController ()

@end

@implementation GHBSlideViewController
@synthesize leftViewController = _leftViewController;
@synthesize mainViewController = _mainViewController;
@synthesize gestureOrigin = _gestureOrigin;
@synthesize gestureVelocity = _gestureVelocity;
@synthesize currentSlideState = _currentSlideState;
@synthesize currentSlideStateGesture = _currentSlideStateGesture;

- (id) initWithLeftViewController:(id)leftViewController
               mainViewController:(id)mainViewController
{
    self = [super init];
    if(self) {
        
        _leftViewController = leftViewController;
        _mainViewController = mainViewController;

    }
    return self;
}

#pragma mark -
#pragma mark - View Lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;

    // add views to SlideViewController
    if (_leftViewController) {
        
        // frame
        CGRect frame = self.view.bounds;
        frame.size = CGSizeMake(SLIDE_MENU_WIDTH, frame.size.height);
        
        // set bounds
        _leftViewController.view.frame = frame;
        _leftViewController.view.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
        
        // set alpha
        _leftViewController.view.layer.opacity = MINIMUM_ALPHA;
        
        [self.view addSubview:_leftViewController.view];
        
    }
    if (_mainViewController) {
       
        [self addMainViewController:_mainViewController];

        
    }
    
    // setup gestures
    [self addGestureRecognizer];
    
    // default position
    _currentSlideState = SlideStateClosed;
    _currentSlideStateGesture = SlideStateGestureNone;
    _gestureOrigin = CGPointZero;
}

- (void) addMainViewController:(UIViewController *)mainViewController
{
    // add dropshadow
    if (SLIDE_MENU_SHADOW) {
        mainViewController.view.layer.masksToBounds = NO;
        mainViewController.view.layer.shadowOffset = CGSizeMake(-SLIDE_MENU_SHADOW_RADIUS, 0);
        mainViewController.view.layer.shadowRadius = SLIDE_MENU_SHADOW_RADIUS;
        mainViewController.view.layer.shadowOpacity = SLIDE_MENU_SHADOW_OPACITY;
    }
    
    // set bounds
    mainViewController.view.frame = self.view.bounds;
    mainViewController.view.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
    
    [self.view addSubview:mainViewController.view];
    
    // set parentview controller
    [self addChildViewController:mainViewController];
    [self.view addSubview:mainViewController.view];
    
    if ([mainViewController respondsToSelector:@selector(didMoveToParentViewController)])
        [mainViewController didMoveToParentViewController:self];
    
    _mainViewController = mainViewController;
}
- (void) setMainViewController:(UIViewController *)mainViewController
{

    // slide out of view
    __block typeof(self) weakSelf = self;
    [self setSlidePosition:self.view.bounds.size.width
                   animate:YES
                completion:^(BOOL finished) {
                    
                    // clean up 'old' mainViewController
                    if ([weakSelf.mainViewController respondsToSelector:@selector(willMoveToParentViewController)])
                        [weakSelf.mainViewController willMoveToParentViewController:nil];

                    if ([weakSelf.mainViewController respondsToSelector:@selector(removeFromParentViewController)])
                        [weakSelf.mainViewController removeFromParentViewController];
                    
                    [weakSelf.mainViewController.view removeFromSuperview];
                    
                    // add new mainViewController
                    [weakSelf addMainViewController:mainViewController];
                    CGRect frame = mainViewController.view.frame;
                    frame.origin = CGPointMake(weakSelf.view.bounds.size.width, 0);
                    mainViewController.view.frame = frame;
                    
                    // animate to closed position
                    [weakSelf setSlidePosition:0 animate:YES];
                    
                    // set GestureRecognizers
                    [weakSelf addGestureRecognizer];
                    
                }];
    


    

}

#pragma mark - Slide position
- (void) toggleSlideViewController
{
    [self toggleSlideViewController:^(BOOL completed){
    }];
    
}
- (void) toggleSlideViewController:(animationComplete)completion
{
    float position = 0;
    if (_currentSlideState == SlideStateClosed) {
        position = SLIDE_MENU_WIDTH;
    }
    
    [self setSlidePosition:position
                   animate:YES
                completion:^(BOOL completed){
                    completion(completed);
                }];


}

- (void) setSlidePosition:(CGFloat)position animate:(BOOL)animated
{
    [self setSlidePosition:position
                   animate:animated
                completion:^(BOOL completed){
    }];
    
}
- (void) setSlidePosition:(CGFloat)position animate:(BOOL)animated completion:(animationComplete)completion
{
    // make sure position is within bounds
    if (position < 0) {
        position = 0;
    }
    
    if (animated) {
        
        // calculate animation duration
        CGFloat animationDuration = [self animationDurationFromStartPosition:_mainViewController.view.frame.origin.x toEndPosition:position];

        // custom properties if mainViewController moves out of view
        UIColor *backgroundColor = self.view.backgroundColor;
        if (position > SLIDE_MENU_WIDTH) {
            animationDuration = ANIMATION_DURATION/2;
            
            // set backgroundcolor temporarely
            self.view.backgroundColor = _leftViewController.view.backgroundColor;

            
        }
        
        // set new position
        CGRect frame = _mainViewController.view.frame;
        frame.origin.x = position;
        
        // set alpha of leftViewController
        CGFloat perc = ABS(position/SLIDE_MENU_WIDTH);
        CGFloat alpha = (1.f - MINIMUM_ALPHA) * perc + MINIMUM_ALPHA;
        alpha = MIN(1.f,alpha);
        
        // set scale of leftViewController
        CGFloat scale = (1.f - MINIMUM_SCALE) * perc + MINIMUM_SCALE;
        scale = MIN(1.f,scale);
        
        [UIView animateWithDuration:animationDuration
                              delay:0
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^{
                             
                             _mainViewController.view.frame = frame;
                             
                             _leftViewController.view.alpha = alpha;
                             _leftViewController.view.layer.transform = CATransform3DScale(CATransform3DIdentity, scale, scale, 1);

                             
                         }
                         completion:^(BOOL finished) {
                             
                             // reset background color to original
                             self.view.backgroundColor = backgroundColor;
                             
                             // set slideState
                             if (position == 0) {
                                 _currentSlideState = SlideStateClosed;
                             } else {
                                 _currentSlideState = SlideStateOpen;
                             }
                             
                             // return value for completion block
                             completion(YES);
                             
                         }];

    } else {
        // set max slide position
        if (position > SLIDE_MENU_WIDTH) {
            position = SLIDE_MENU_WIDTH;
        }

        // set alpha of leftViewController
        CGFloat perc = ABS(position/SLIDE_MENU_WIDTH);
        CGFloat alpha = (1.f - MINIMUM_ALPHA) * perc + MINIMUM_ALPHA;
        _leftViewController.view.alpha = alpha;
        
        // set scale of leftViewController
        CGFloat scale = (1.f - MINIMUM_SCALE) * perc + MINIMUM_SCALE;
        _leftViewController.view.layer.transform = CATransform3DScale(CATransform3DIdentity, scale, scale, 1);

        
        // jump to slide position
        CGRect frame = _mainViewController.view.frame;
        frame.origin.x = position;
        _mainViewController.view.frame = frame;
        
        // return value for completion block
        completion(YES);

    }
}
- (CGFloat) animationDurationFromStartPosition:(CGFloat)startPosition toEndPosition:(CGFloat)endPosition {
    CGFloat animationPositionDelta = ABS(endPosition - startPosition);
    
    CGFloat duration;
    if(ABS(_gestureVelocity.x) > 1.0) {
        // try to continue the animation at the speed the user was swiping
        duration = animationPositionDelta / ABS(_gestureVelocity.x);
    } else {
        // no swipe was used, user tapped the bar button item
        duration = ANIMATION_DURATION;
    }
    return MIN(duration, ANIMATION_DURATION);
}

#pragma mark - UIInterfaceOrientationDelegate
-(void)willRotateToInterfaceOrientation: (UIInterfaceOrientation)orientation duration:(NSTimeInterval)duration
{
    if (_currentSlideState == SlideStateOpen) {
        [self toggleSlideViewController];
    }
    
    // prevent wrong placing of view when rotation and CATransform3DScale
    _leftViewController.view.layer.transform = CATransform3DScale(CATransform3DIdentity, 1, 1, 1);

}

#pragma mark - Gesture Handlers
- (void) addGestureRecognizer
{
    // pan/slide GestureRecognizer
    UIPanGestureRecognizer *panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panRecognizer:)];
    [panRecognizer setMinimumNumberOfTouches:1];
    [panRecognizer setMaximumNumberOfTouches:1];
    [self.view addGestureRecognizer:panRecognizer];
    
    // tap GestureRecognizer
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapRecognizer:)];
    [tapRecognizer setCancelsTouchesInView:NO];
    [_mainViewController.view addGestureRecognizer:tapRecognizer];
    
}

#pragma mark - UIPanGestureRecognizer Delegate
- (void) panRecognizer:(UIPanGestureRecognizer *)gestureRecognizer
{
    CGPoint touchPoint = [gestureRecognizer translationInView:_mainViewController.view];
    CGPoint velocity = [gestureRecognizer velocityInView:_mainViewController.view];
    
    _gestureVelocity = velocity;
    
    // Starting gesture, save origin
    if (CGPointEqualToPoint(_gestureOrigin, CGPointZero) || gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        _gestureOrigin = touchPoint;
    }
    
    // continued w/ gesture
    bool shouldMoveMainController = NO;
    if (gestureRecognizer.state == UIGestureRecognizerStateChanged) {
        // check direction
        if (velocity.x > 0 && _currentSlideState == SlideStateClosed) {
            
            // slide open
            _currentSlideStateGesture = SlideStateGestureOpen;
            shouldMoveMainController = YES;

        } else if (velocity.x < 0 && _currentSlideState == SlideStateOpen) {
            
            // slide close
            _currentSlideStateGesture = SlideStateGestureClose;
            shouldMoveMainController = YES;
            
        } else if (velocity.x < 0 && _currentSlideState == SlideStateClosed) {

            // slide close
            _currentSlideStateGesture = SlideStateGestureClose;
            shouldMoveMainController = YES;

        }
        else if (velocity.x > 0 && _currentSlideState == SlideStateOpen) {
            
            // slide close
            _currentSlideStateGesture = SlideStateGestureOpen;
            shouldMoveMainController = YES;
            
        }
    
    }
    
    

    // calculate delta
    float delta = 0;
    float deltaOrig = 0;
    if (!CGPointEqualToPoint(_gestureOrigin, CGPointZero)) {
        delta = deltaOrig = _gestureOrigin.x + touchPoint.x;
        
        if (_currentSlideState == SlideStateOpen) {
            delta = SLIDE_MENU_WIDTH + delta;
        }
    }
    
    // gesture ended, animate
    if (gestureRecognizer.state == UIGestureRecognizerStateEnded) {
        _gestureVelocity = CGPointMake(0, 0);
        _gestureOrigin = CGPointZero;

        if (deltaOrig < 0 && deltaOrig*-1 < MINIMUM_GESTURE_RANGE && _currentSlideState == SlideStateOpen) {
            
            // not enough movement, return
            [self setSlidePosition:SLIDE_MENU_WIDTH animate:YES];
            _currentSlideStateGesture = SlideStateGestureNone;
            
        } else if (deltaOrig > 0 && deltaOrig < MINIMUM_GESTURE_RANGE && _currentSlideState == SlideStateClosed) {

            // not enough movement, return
            [self setSlidePosition:0 animate:YES];
            _currentSlideStateGesture = SlideStateGestureNone;
            
        } else if (_currentSlideStateGesture == SlideStateGestureOpen && (_currentSlideState == SlideStateOpen || _currentSlideState == SlideStateClosed)) {

            // released while performing gesture, finish gesture
            [self setSlidePosition:SLIDE_MENU_WIDTH animate:YES];
            _currentSlideStateGesture = SlideStateGestureNone;

        } else if (_currentSlideStateGesture == SlideStateGestureClose && (_currentSlideState == SlideStateOpen || _currentSlideState == SlideStateClosed)) {

            // released while performing gesture, finish gesture
            [self setSlidePosition:0 animate:YES];
            _currentSlideStateGesture = SlideStateGestureNone;

        }
    }
     
    // change position of mainController
    if (shouldMoveMainController) {
        [self setSlidePosition:delta animate:NO];
    }

    
}
- (void) tapRecognizer:(UIPanGestureRecognizer *)gestureRecognizer
{
    // close leftViewController
    if (_currentSlideState == SlideStateOpen) {
        [self setSlidePosition:0 animate:YES];
        
        // save state
        _gestureOrigin = CGPointZero;
        _currentSlideStateGesture = SlideStateGestureNone;
    }
}


@end
