#import <UIKit/UIKit.h>

@interface UIViewController (FakeInterfaceOrientation)

@property (nonatomic) BOOL fakeAutoRotationEnabled;
@property (nonatomic) UIInterfaceOrientation fakeInterfaceOrientation;
@property (nonatomic) UIInterfaceOrientation preventedFakeInterfaceOrientation;

- (void)setFakeInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation animated:(BOOL)animated;
- (void)willRotateToFakeInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration;

@end
