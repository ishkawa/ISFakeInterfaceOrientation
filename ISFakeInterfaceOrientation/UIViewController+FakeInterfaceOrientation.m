#import "UIViewController+FakeInterfaceOrientation.h"
#import <CoreMotion/CoreMotion.h>
#import <objc/runtime.h>

static double const ISGravityThreshold = 0.7;

static char *const ISFakeInterfaceOrientationKey = "fakeInterfaceOrientation";
static char *const ISIsActiveKey                 = "isActive";
static char *const ISFakeAutoRotationEnabledKey  = "fakeAutoRotationEnabled";
static char *const ISMotionManagerKey            = "motionManager";

static void ISSwizzleInstanceMethod(Class c, SEL original, SEL alternative)
{
    Method orgMethod = class_getInstanceMethod(c, original);
    Method altMethod = class_getInstanceMethod(c, alternative);
    
    if(class_addMethod(c, original, method_getImplementation(altMethod), method_getTypeEncoding(altMethod))) {
        class_replaceMethod(c, alternative, method_getImplementation(orgMethod), method_getTypeEncoding(orgMethod));
    } else {
        method_exchangeImplementations(orgMethod, altMethod);
    }
}

@interface UIViewController ()

@property (nonatomic, getter = isActive) BOOL active;
@property (nonatomic, strong) CMMotionManager *motionManager;

@end

@implementation UIViewController (FakeInterfaceOrientation)

+ (void)load
{
    @autoreleasepool {
        ISSwizzleInstanceMethod([self class], @selector(viewDidAppear:), @selector(_viewDidAppear:));
        ISSwizzleInstanceMethod([self class], @selector(viewWillDisappear:), @selector(_viewWillDisappear:));
    }
}

#pragma mark - accessor

- (BOOL)fakeAutoRotationEnabled
{
    return [objc_getAssociatedObject(self, ISFakeAutoRotationEnabledKey) boolValue];
}

- (void)setFakeAutoRotationEnabled:(BOOL)fakeAutoRotationEnabled
{
    if (self.isActive && self.fakeAutoRotationEnabled) {
        [self beginAutoRotation];
    }
    objc_setAssociatedObject(self, ISFakeAutoRotationEnabledKey, @(fakeAutoRotationEnabled), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)isActive
{
    return [objc_getAssociatedObject(self, ISIsActiveKey) boolValue];
}

- (void)setActive:(BOOL)active
{
    objc_setAssociatedObject(self, ISIsActiveKey, @(active), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIInterfaceOrientation)fakeInterfaceOrientation
{
    NSNumber *number = objc_getAssociatedObject(self, ISFakeInterfaceOrientationKey);
    if (!number) {
        number = @(UIInterfaceOrientationPortrait);
    }
    
    return [number integerValue];
}

- (void)setFakeInterfaceOrientation:(UIInterfaceOrientation)fakeInterfaceOrientation
{
    objc_setAssociatedObject(self, ISFakeInterfaceOrientationKey, @(fakeInterfaceOrientation), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (CMMotionManager *)motionManager
{
    return objc_getAssociatedObject(self, ISMotionManagerKey);
}

- (void)setMotionManager:(CMMotionManager *)motionManager
{
    objc_setAssociatedObject(self, ISMotionManagerKey, motionManager, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

#pragma mark - UIViewController events

- (void)_viewDidAppear:(BOOL)animated
{
    [self _viewDidAppear:animated];
    
    self.active = YES;
    
    if (self.fakeAutoRotationEnabled) {
        [self beginAutoRotation];
    }
}

- (void)_viewWillDisappear:(BOOL)animated
{
    self.active = NO;
    
    [self endAutoRotation];
    [self _viewWillDisappear:animated];
}

#pragma mark -

- (void)beginAutoRotation
{
    self.motionManager = [[CMMotionManager alloc] init];
    
    __unsafe_unretained typeof(self) wself = self;
    [self.motionManager startDeviceMotionUpdatesToQueue:[NSOperationQueue mainQueue]
                                            withHandler:^(CMDeviceMotion *motion, NSError *error) {
                                                if (error) {
                                                    NSLog(@"unresolved error occurred");
                                                    return;
                                                }
                                                [wself handleMotion:motion];
                                            }];
}

- (void)endAutoRotation
{
    [self.motionManager stopDeviceMotionUpdates];
    self.motionManager = nil;
}

- (void)handleMotion:(CMDeviceMotion *)motion
{
    CMAcceleration gravity = motion.gravity;
    if (ABS(gravity.y) < ABS(gravity.x)) {
        if (gravity.x < -ISGravityThreshold) {
            [self setFakeInterfaceOrientation:UIInterfaceOrientationLandscapeRight animated:YES];
        }
        if (gravity.x > ISGravityThreshold) {
            [self setFakeInterfaceOrientation:UIInterfaceOrientationLandscapeLeft animated:YES];
        }
    } else {
        if (gravity.y < -ISGravityThreshold) {
            [self setFakeInterfaceOrientation:UIInterfaceOrientationPortrait animated:YES];
        }
    }
}

- (void)setFakeInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation animated:(BOOL)animated
{
    if (!self.isViewLoaded) {
        return;
    }
    if (self.fakeInterfaceOrientation == interfaceOrientation) {
        return;
    }
    
    UIApplication *application = [UIApplication sharedApplication];
    NSTimeInterval duration = application.statusBarOrientationAnimationDuration;
    
    BOOL isLandscapeToLandscape = YES;
    isLandscapeToLandscape &= UIInterfaceOrientationIsLandscape(self.fakeInterfaceOrientation);
    isLandscapeToLandscape &= UIInterfaceOrientationIsLandscape(interfaceOrientation);
    
    if (isLandscapeToLandscape) {
        duration *= 2;
    }
    
    CGFloat statusBarHeight;
    if (self.wantsFullScreenLayout) {
        statusBarHeight = 0;
    } else {
        if (UIInterfaceOrientationIsLandscape(application.statusBarOrientation)) {
            statusBarHeight = application.statusBarFrame.size.width;
        } else {
            statusBarHeight = application.statusBarFrame.size.height;
        }
    }
    
    [UIView animateWithDuration:duration
                     animations:^{
                         [self willRotateToFakeInterfaceOrientation:interfaceOrientation duration:duration];
                         
                         application.statusBarOrientation = interfaceOrientation;
                         
                         CGRect frame = [UIScreen mainScreen].bounds;
                         switch (interfaceOrientation) {
                             case UIInterfaceOrientationPortrait:
                                 self.view.transform = CGAffineTransformIdentity;
                                 frame.origin.y += statusBarHeight;
                                 frame.size.height -= statusBarHeight;
                                 break;
                                 
                             case UIInterfaceOrientationLandscapeLeft:
                                 self.view.transform = CGAffineTransformMakeRotation(-M_PI_2);
                                 frame.origin.x += statusBarHeight;
                                 frame.size.width -= statusBarHeight;
                                 break;
                                 
                             case UIInterfaceOrientationLandscapeRight:
                                 self.view.transform = CGAffineTransformMakeRotation(M_PI_2);
                                 frame.size.width -= statusBarHeight;
                                 
                                 break;
                                 
                             case UIInterfaceOrientationPortraitUpsideDown:
                                 self.view.transform = CGAffineTransformMakeRotation(M_PI);
                                 frame.size.height -= statusBarHeight;
                                 break;
                                 
                             default: break;
                         }
                         self.view.frame = frame;
                     }
                     completion:^(BOOL finished) {
                         self.fakeInterfaceOrientation = interfaceOrientation;
                     }];
}

- (void)willRotateToFakeInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
}

@end
