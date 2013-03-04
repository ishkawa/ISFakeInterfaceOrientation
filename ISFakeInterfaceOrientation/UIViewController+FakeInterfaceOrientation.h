#import <UIKit/UIKit.h>

@interface UIViewController (FakeInterfaceOrientation)

@property (nonatomic) BOOL fakeAutoRotationEnabled;
@property (nonatomic) UIInterfaceOrientation fakeInterfaceOrientation;

- (void)setFakeInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation animated:(BOOL)animated;

@end
